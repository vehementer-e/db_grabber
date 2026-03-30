from __future__ import annotations

import asyncio
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path

from docsgen.async_db import AsyncODBCExecutor
from docsgen.config import JOB_SOURCES_DIR


@dataclass(frozen=True)
class JobRef:
    job_id: str
    name: str


@dataclass(frozen=True)
class JobStep:
    step_id: int
    step_name: str
    subsystem: str
    database_name: str | None
    command: str


@dataclass(frozen=True)
class JobSource:
    ref: JobRef
    enabled: bool
    owner_login_name: str
    description: str | None
    steps: list[JobStep]


class JobCatalogRepository:
    """Repository: reads SQL Agent Jobs and their steps from msdb."""

    @staticmethod
    def list_jobs(conn) -> list[JobRef]:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT CONVERT(varchar(36), j.job_id) AS job_id, j.name
            FROM dbo.sysjobs j
            ORDER BY j.name;
            """
        )
        return [JobRef(job_id=r.job_id, name=r.name) for r in cur.fetchall()]

    @staticmethod
    def fetch_job_source(conn, ref: JobRef) -> JobSource:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT
                j.name,
                j.enabled,
                SUSER_SNAME(j.owner_sid) AS owner_login_name,
                j.description
            FROM dbo.sysjobs j
            WHERE CONVERT(varchar(36), j.job_id) = ?;
            """,
            (ref.job_id,),
        )
        job_row = cur.fetchone()
        if job_row is None:
            raise RuntimeError(f"Job not found: {ref.name} ({ref.job_id})")

        cur.execute(
            """
            SELECT
                s.step_id,
                s.step_name,
                s.subsystem,
                s.database_name,
                s.command
            FROM dbo.sysjobsteps s
            INNER JOIN dbo.sysjobs j ON j.job_id = s.job_id
            WHERE CONVERT(varchar(36), j.job_id) = ?
            ORDER BY s.step_id;
            """,
            (ref.job_id,),
        )

        steps = [
            JobStep(
                step_id=r.step_id,
                step_name=r.step_name,
                subsystem=r.subsystem,
                database_name=r.database_name,
                command=r.command or "",
            )
            for r in cur.fetchall()
        ]

        return JobSource(
            ref=ref,
            enabled=bool(job_row.enabled),
            owner_login_name=job_row.owner_login_name or "",
            description=job_row.description,
            steps=steps,
        )


class JobSourceFileWriter:
    """Writes job step commands to files and saves per-job metadata."""

    INVALID_FILENAME_CHARS = re.compile(r'[<>:"/\\|?*]')

    def __init__(self, *, base_dir: str | Path = JOB_SOURCES_DIR):
        self.base_dir = Path(base_dir)

    @classmethod
    def _safe_name(cls, raw_name: str) -> str:
        cleaned = cls.INVALID_FILENAME_CHARS.sub("_", raw_name).strip()
        return cleaned or "unnamed"

    @staticmethod
    def _ext_for_step(step: JobStep) -> str:
        if step.subsystem.upper() in {"TSQL", "SQL"}:
            return "sql"
        if step.subsystem.upper() in {"POWERSHELL", "CMDEXEC"}:
            return "ps1" if step.subsystem.upper() == "POWERSHELL" else "cmd"
        return "txt"

    def write(self, catalog_name: str, source: JobSource) -> Path:
        job_dir = self.base_dir / catalog_name / self._safe_name(source.ref.name)
        job_dir.mkdir(parents=True, exist_ok=True)

        metadata = {
            "job_id": source.ref.job_id,
            "job_name": source.ref.name,
            "enabled": source.enabled,
            "owner_login_name": source.owner_login_name,
            "description": source.description,
            "steps": [asdict(s) for s in source.steps],
        }
        (job_dir / "job.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")

        for step in source.steps:
            ext = self._ext_for_step(step)
            step_name = self._safe_name(step.step_name)
            step_path = job_dir / f"{step.step_id:02d}_{step_name}.{ext}"
            step_path.write_text(step.command, encoding="utf-8")

        return job_dir


async def export_all_job_sources(
    *,
    msdb_name: str = "msdb",
    name_filter: str | None = None,
    limit: int | None = None,
    max_conns: int = 10,
    out_dir: str | Path | None = None,
    fail_log: str | None = None,
) -> None:
    executor = AsyncODBCExecutor(max_connections=max_conns)
    repository = JobCatalogRepository()
    writer = JobSourceFileWriter(base_dir=out_dir or JOB_SOURCES_DIR)

    items = await executor.run(msdb_name, repository.list_jobs)

    if name_filter:
        nf = name_filter.lower()
        items = [x for x in items if nf in x.name.lower()]
    if limit:
        items = items[:limit]

    total = len(items)
    print(f"jobs in {msdb_name}: {total} (max_conns={max_conns})")

    q: asyncio.Queue[JobRef] = asyncio.Queue()
    for item in items:
        q.put_nowait(item)

    done = 0
    failed: list[str] = []
    lock = asyncio.Lock()

    async def worker() -> None:
        nonlocal done
        while True:
            try:
                ref = q.get_nowait()
            except asyncio.QueueEmpty:
                return

            try:
                source = await executor.run(msdb_name, repository.fetch_job_source, ref)
                writer.write(msdb_name, source)
            except Exception as e:
                failed.append(f"{ref.name}\t{repr(e)}")
            finally:
                q.task_done()
                async with lock:
                    done += 1
                    if done % 100 == 0 or done == total:
                        print(f"[{done}/{total}] done")

    workers = [asyncio.create_task(worker()) for _ in range(max_conns)]
    await asyncio.gather(*workers)

    executor.close()

    if failed:
        p = Path(fail_log or f"logs/docsgen_failed_{msdb_name}_jobs.txt")
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("\n".join(failed), encoding="utf-8")
        raise SystemExit(f"FAILED={len(failed)}. See {p}")

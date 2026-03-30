from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass
from pathlib import Path

from docsgen.async_db import AsyncODBCExecutor
from docsgen.config import DEFAULT_DATABASE, PROCEDURE_SOURCES_DIR


@dataclass(frozen=True)
class ProcedureRef:
    schema: str
    name: str


@dataclass(frozen=True)
class ProcedureSource:
    ref: ProcedureRef
    definition: str


class ProcedureCatalogRepository:
    """Repository for loading procedure identifiers and source texts from MSSQL."""

    @staticmethod
    def list_procedures(conn) -> list[ProcedureRef]:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT s.name AS schema_name, p.name AS procedure_name
            FROM sys.procedures p
            JOIN sys.schemas s ON s.schema_id = p.schema_id
            WHERE p.is_ms_shipped = 0
            ORDER BY s.name, p.name;
            """
        )
        return [ProcedureRef(schema=r.schema_name, name=r.procedure_name) for r in cur.fetchall()]

    @staticmethod
    def fetch_source(conn, ref: ProcedureRef) -> ProcedureSource:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT sm.definition
            FROM sys.procedures p
            JOIN sys.schemas s ON s.schema_id = p.schema_id
            LEFT JOIN sys.sql_modules sm ON sm.object_id = p.object_id
            WHERE s.name = ? AND p.name = ?;
            """,
            (ref.schema, ref.name),
        )
        row = cur.fetchone()
        if row is None:
            raise RuntimeError(f"Procedure not found: {ref.schema}.{ref.name}")
        definition = row[0] or ""
        return ProcedureSource(ref=ref, definition=definition)


class ProcedureSourceFileWriter:
    """Writes procedure SQL text to <db>/<schema>/<procedure>.sql hierarchy."""

    INVALID_FILENAME_CHARS = re.compile(r'[<>:"/\\|?*]')

    def __init__(self, *, base_dir: str | Path = PROCEDURE_SOURCES_DIR):
        self.base_dir = Path(base_dir)

    @classmethod
    def _safe_name(cls, raw_name: str) -> str:
        cleaned = cls.INVALID_FILENAME_CHARS.sub("_", raw_name).strip()
        return cleaned or "unnamed_procedure"

    def write(self, db: str, source: ProcedureSource) -> Path:
        schema = self._safe_name(source.ref.schema)
        proc_name = self._safe_name(source.ref.name)
        out_path = self.base_dir / db / schema / f"{proc_name}.sql"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(source.definition, encoding="utf-8")
        return out_path


async def export_all_procedure_sources(
    *,
    db: str | None,
    schema_filter: str | None = None,
    limit: int | None = None,
    max_conns: int = 10,
    out_dir: str | Path | None = None,
    fail_log: str | None = None,
) -> None:
    db = db or DEFAULT_DATABASE
    executor = AsyncODBCExecutor(max_connections=max_conns)
    repository = ProcedureCatalogRepository()
    writer = ProcedureSourceFileWriter(base_dir=out_dir or PROCEDURE_SOURCES_DIR)

    items = await executor.run(db, repository.list_procedures)

    if schema_filter:
        sf = schema_filter.lower()
        items = [x for x in items if x.schema.lower() == sf]
    if limit:
        items = items[:limit]

    total = len(items)
    print(f"procedures in {db}: {total} (max_conns={max_conns})")

    q: asyncio.Queue[ProcedureRef] = asyncio.Queue()
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
                source = await executor.run(db, repository.fetch_source, ref)
                writer.write(db, source)
            except Exception as e:
                failed.append(f"{ref.schema}.{ref.name}\t{repr(e)}")
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
        p = Path(fail_log or f"logs/docsgen_failed_{db}_procedure_sources.txt")
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("\n".join(failed), encoding="utf-8")
        raise SystemExit(f"FAILED={len(failed)}. See {p}")

from __future__ import annotations

import asyncio
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

from docsgen.async_db import AsyncODBCExecutor
from docsgen.config import OUT_DIR, DEFAULT_DATABASE
from docsgen.io import save_json, save_md
from docsgen.render.md import render_md

from docsgen.jgen.procedure import get_procedure_metadata
from docsgen.jgen.function import get_function_metadata
from docsgen.jgen.table import get_table_metadata

ObjType = Literal["procedure", "function", "table"]


@dataclass(frozen=True)
class ObjRef:
    schema: str
    name: str


def _list_objects(conn, obj_type: ObjType) -> list[ObjRef]:
    cur = conn.cursor()

    if obj_type == "procedure":
        cur.execute(
            """
            SELECT s.name AS schema_name, p.name AS object_name
            FROM sys.procedures p
            JOIN sys.schemas s ON s.schema_id = p.schema_id
            WHERE p.is_ms_shipped = 0
            ORDER BY s.name, p.name;
            """
        )
    elif obj_type == "function":
        cur.execute(
            """
            SELECT s.name AS schema_name, o.name AS object_name
            FROM sys.objects o
            JOIN sys.schemas s ON s.schema_id = o.schema_id
            WHERE o.type IN ('FN','FS','TF','IF','FT')
              AND o.is_ms_shipped = 0
            ORDER BY s.name, o.name;
            """
        )
    elif obj_type == "table":
        cur.execute(
            """
            SELECT s.name AS schema_name, t.name AS object_name
            FROM sys.tables t
            JOIN sys.schemas s ON s.schema_id = t.schema_id
            WHERE t.is_ms_shipped = 0
            ORDER BY s.name, t.name;
            """
        )
    else:
        raise ValueError(f"Unknown obj_type: {obj_type}")

    return [ObjRef(r.schema_name, r.object_name) for r in cur.fetchall()]


def _build_one(conn, db: str, obj_type: ObjType, ref: ObjRef) -> dict:
    if obj_type == "procedure":
        doc = get_procedure_metadata(conn, ref.schema, ref.name, database=db)
    elif obj_type == "function":
        doc = get_function_metadata(conn, ref.schema, ref.name, database=db)
    elif obj_type == "table":
        doc = get_table_metadata(conn, ref.schema, ref.name, database=db)
    else:
        raise ValueError(f"Unknown obj_type: {obj_type}")

    doc["database"] = db
    return doc


def _paths(db: str, obj_type: ObjType, ref: ObjRef) -> tuple[Path, Path]:
    jpath = Path("build/json") / db / obj_type / ref.schema / f"{ref.name}.json"
    mpath = Path(OUT_DIR) / db / obj_type / ref.schema / f"{ref.name}.md"
    return jpath, mpath


async def build_all(
    *,
    db: str | None,
    obj_type: ObjType,
    schema_filter: str | None = None,
    limit: int | None = None,
    max_conns: int = 10,
    fail_log: str | None = None,
) -> None:
    db = db or DEFAULT_DATABASE
    exec_ = AsyncODBCExecutor(max_connections=max_conns)

    items = await exec_.run(db, _list_objects, obj_type)

    if schema_filter:
        sf = schema_filter.lower()
        items = [x for x in items if x.schema.lower() == sf]
    if limit:
        items = items[:limit]

    total = len(items)
    print(f"{obj_type}s in {db}: {total} (max_conns={max_conns})")

    q: asyncio.Queue[ObjRef] = asyncio.Queue()
    for it in items:
        q.put_nowait(it)

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
                doc = await exec_.run(db, _build_one, db, obj_type, ref)
                md = render_md(doc)
                jpath, mpath = _paths(db, obj_type, ref)
                save_json(jpath, doc)
                save_md(mpath, md)
            except Exception as e:
                failed.append(f"{ref.schema}.{ref.name}\t{repr(e)}")
            finally:
                q.task_done()
                async with lock:
                    done += 1
                    if done % 50 == 0 or done == total:
                        print(f"[{done}/{total}] done")

    workers = [asyncio.create_task(worker()) for _ in range(max_conns)]
    await asyncio.gather(*workers)

    exec_.close()

    if failed:
        p = Path(fail_log or f"logs/docsgen_failed_{db}_{obj_type}.txt")
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("\n".join(failed), encoding="utf-8")
        raise SystemExit(f"FAILED={len(failed)}. See {p}")

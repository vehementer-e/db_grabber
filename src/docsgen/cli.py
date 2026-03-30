import argparse
import asyncio
from pathlib import Path

from docsgen.db import get_connection
from docsgen.config import OUT_DIR, DEFAULT_DATABASE
from docsgen.io import save_json, load_json, save_md
from docsgen.render.md import render_md

from docsgen.jgen.procedure import get_procedure_metadata
from docsgen.jgen.function import get_function_metadata
from docsgen.jgen.table import get_table_metadata

from docsgen.batch import build_all
from docsgen.procedure_source import export_all_procedure_sources
from docsgen.job_source import export_all_job_sources


def parse_object_ref(ref: str):
    if "." not in ref:
        raise SystemExit("Object must be in form: schema.name")
    return ref.split(".", 1)


def json_path(db: str, obj_type: str, schema: str, name: str) -> Path:
    return Path("build/json") / db / obj_type / schema / f"{name}.json"


def md_path(db: str, obj_type: str, schema: str, name: str) -> Path:
    return Path(OUT_DIR) / db / obj_type / schema / f"{name}.md"


def generate_json(db: str | None, obj_type: str, schema: str, name: str) -> dict:
    with get_connection(db) as conn:
        if obj_type == "procedure":
            return get_procedure_metadata(conn, schema, name, database=(db or DEFAULT_DATABASE))
        if obj_type == "function":
            return get_function_metadata(conn, schema, name, database=(db or DEFAULT_DATABASE))
        if obj_type == "table":
            return get_table_metadata(conn, schema, name, database=(db or DEFAULT_DATABASE))
    raise SystemExit(f"Unknown object type: {obj_type}")


def cmd_json(args):
    schema, name = parse_object_ref(args.object)
    db = args.db or DEFAULT_DATABASE
    doc = generate_json(db, args.type, schema, name)
    path = json_path(db, args.type, schema, name)
    save_json(path, doc)
    print(f"JSON written to {path}")


def cmd_md(args):
    schema, name = parse_object_ref(args.object)
    db = args.db or DEFAULT_DATABASE

    jpath = json_path(db, args.type, schema, name)
    if not jpath.exists():
        raise SystemExit(f"JSON not found: {jpath}")

    doc = load_json(jpath)
    md = render_md(doc)

    mpath = md_path(db, args.type, schema, name)
    save_md(mpath, md)

    print(f"MD written to {mpath}")


def cmd_build(args):
    schema, name = parse_object_ref(args.object)
    db = args.db or DEFAULT_DATABASE

    doc = generate_json(db, args.type, schema, name)
    doc["database"] = db

    jpath = json_path(db, args.type, schema, name)
    save_json(jpath, doc)
    print(f"JSON written to {jpath}")

    md = render_md(doc)
    mpath = md_path(db, args.type, schema, name)
    save_md(mpath, md)
    print(f"MD written to {mpath}")


def cmd_build_all(args):
    asyncio.run(
        build_all(
            db=(args.db or DEFAULT_DATABASE),
            obj_type=args.type,
            schema_filter=args.schema,
            limit=args.limit,
            max_conns=args.max_conns,
            fail_log=args.fail_log,
        )
    )



def cmd_export_procedure_sources(args):
    asyncio.run(
        export_all_procedure_sources(
            db=(args.db or DEFAULT_DATABASE),
            schema_filter=args.schema,
            limit=args.limit,
            max_conns=args.max_conns,
            out_dir=args.out_dir,
            fail_log=args.fail_log,
        )
    )


def cmd_export_job_sources(args):
    asyncio.run(
        export_all_job_sources(
            msdb_name=(args.msdb or "msdb"),
            name_filter=args.name_filter,
            limit=args.limit,
            max_conns=args.max_conns,
            out_dir=args.out_dir,
            fail_log=args.fail_log,
        )
    )

def main():
    p = argparse.ArgumentParser("docsgen")
    sub = p.add_subparsers(dest="cmd", required=True)

    def add_common(sp):
        sp.add_argument("--db", default=None, help="Название БД")
        sp.add_argument("type", choices=["procedure", "function", "table"])
        sp.add_argument("object", help="schema.name")

    p_json = sub.add_parser("json", help="Generate JSON from DB")
    add_common(p_json)
    p_json.set_defaults(func=cmd_json)

    p_md = sub.add_parser("md", help="Generate MD from existing JSON")
    add_common(p_md)
    p_md.set_defaults(func=cmd_md)

    p_build = sub.add_parser("build", help="Generate JSON + MD for single object")
    add_common(p_build)
    p_build.set_defaults(func=cmd_build)

    p_all = sub.add_parser("build-all", help="Generate docs for ALL objects of a type (async, pooled)")
    p_all.add_argument("--db", default=None, help="Название БД")
    p_all.add_argument("--schema", default=None, help="Optional schema filter")
    p_all.add_argument("--limit", type=int, default=None, help="Optional limit")
    p_all.add_argument("--max-conns", type=int, default=10, help="Max DB connections")
    p_all.add_argument("--fail-log", default=None, help="Optional path to failure log")
    p_all.add_argument("type", choices=["procedure", "function", "table"])
    p_all.set_defaults(func=cmd_build_all)

    p_export = sub.add_parser(
        "export-procedure-sources",
        help="Export ALL procedure SQL texts to <db>/<schema>/<procedure>.sql",
    )
    p_export.add_argument("--db", default=None, help="Название БД")
    p_export.add_argument("--schema", default=None, help="Optional schema filter")
    p_export.add_argument("--limit", type=int, default=None, help="Optional limit")
    p_export.add_argument("--max-conns", type=int, default=10, help="Max DB connections")
    p_export.add_argument("--out-dir", default=None, help="Output dir (default build/sql/procedures)")
    p_export.add_argument("--fail-log", default=None, help="Optional path to failure log")
    p_export.set_defaults(func=cmd_export_procedure_sources)

    p_jobs = sub.add_parser(
        "export-job-sources",
        help="Export SQL Agent jobs and their steps from msdb",
    )
    p_jobs.add_argument("--msdb", default="msdb", help="Jobs catalog DB (default: msdb)")
    p_jobs.add_argument("--name-filter", default=None, help="Substring filter for job name")
    p_jobs.add_argument("--limit", type=int, default=None, help="Optional limit")
    p_jobs.add_argument("--max-conns", type=int, default=10, help="Max DB connections")
    p_jobs.add_argument("--out-dir", default=None, help="Output dir (default build/sql/jobs)")
    p_jobs.add_argument("--fail-log", default=None, help="Optional path to failure log")
    p_jobs.set_defaults(func=cmd_export_job_sources)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

from __future__ import annotations

import argparse
import asyncio
import sys

from docsgen.procedure_source import export_all_procedure_sources


def main():
    ap = argparse.ArgumentParser(
        description="Export SQL source for all procedures into <db>/<schema>/<procedure>.sql"
    )
    ap.add_argument("--db", required=True)
    ap.add_argument("--schema", default=None)
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--max-conns", type=int, default=10)
    ap.add_argument("--out-dir", default=None)
    ap.add_argument("--fail-log", default=None)
    args = ap.parse_args()

    try:
        asyncio.run(
            export_all_procedure_sources(
                db=args.db,
                schema_filter=args.schema,
                limit=args.limit,
                max_conns=args.max_conns,
                out_dir=args.out_dir,
                fail_log=args.fail_log,
            )
        )
    except SystemExit:
        raise
    except Exception as e:
        print(f"FATAL: {e!r}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

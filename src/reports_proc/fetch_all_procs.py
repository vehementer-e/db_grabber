from __future__ import annotations

import argparse
import sys

from docsgen.batch import build_all


def main():
    ap = argparse.ArgumentParser(description="Generate docs for all procedures in a DB (in-process, async pooled).")
    ap.add_argument("--db", required=True)
    ap.add_argument("--schema", default=None)
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--max-conns", type=int, default=10)
    ap.add_argument("--fail-log", default=None)
    args = ap.parse_args()

    try:
        import asyncio
        asyncio.run(
            build_all(
                db=args.db,
                obj_type="procedure",
                schema_filter=args.schema,
                limit=args.limit,
                max_conns=args.max_conns,
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

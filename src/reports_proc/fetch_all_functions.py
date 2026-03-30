from __future__ import annotations

import argparse
import sys

from docsgen.batch import build_all


def main():
    ap = argparse.ArgumentParser(description="Generate docs for all functions in a DB (in-process, async pooled).")
    ap.add_argument("--db", required=True, help="Database name, e.g. Reports")
    ap.add_argument("--schema", default=None, help="Optional schema filter (exact match), e.g. dbo")
    ap.add_argument("--limit", type=int, default=None, help="Optional limit for smoke runs")
    ap.add_argument("--max-conns", type=int, default=10, help="Max DB connections (default: 10)")
    ap.add_argument("--fail-log", default=None, help="Path to failure log (txt)")
    args = ap.parse_args()

    try:
        import asyncio
        asyncio.run(
            build_all(
                db=args.db,
                obj_type="function",
                schema_filter=args.schema,
                limit=args.limit,
                max_conns=args.max_conns,
                fail_log=args.fail_log,
            )
        )
    except SystemExit as e:
        raise
    except Exception as e:
        print(f"FATAL: {e!r}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

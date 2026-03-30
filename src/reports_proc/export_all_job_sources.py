from __future__ import annotations

import argparse
import asyncio
import sys

from docsgen.job_source import export_all_job_sources


def main():
    ap = argparse.ArgumentParser(description="Export SQL Agent jobs and step commands from msdb")
    ap.add_argument("--msdb", default="msdb")
    ap.add_argument("--name-filter", default=None)
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--max-conns", type=int, default=10)
    ap.add_argument("--out-dir", default=None)
    ap.add_argument("--fail-log", default=None)
    args = ap.parse_args()

    try:
        asyncio.run(
            export_all_job_sources(
                msdb_name=args.msdb,
                name_filter=args.name_filter,
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

from pathlib import Path

from docsgen.config import DATABASE
from docsgen.db import get_connection
from docsgen.io import save_json, save_md, load_json
from docsgen.jgen.table import get_table_metadata
from docsgen.render.md import render_md

import traceback

BATCH_SIZE = 100


def fetch_table_list_and_save(index_path: Path) -> None:
    """
    Conn #1: Получаем список таблиц и сохраняем его в JSON:
    [
      {"db": "Reports", "schema": "dbo", "name": "TableName"},
      ...
    ]
    """
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT s.name AS schema_name, t.name AS table_name
            FROM sys.tables t
            JOIN sys.schemas s ON s.schema_id = t.schema_id
            WHERE t.is_ms_shipped = 0
            ORDER BY s.name, t.name;
            """
        )

        items = [{"db": DATABASE, "schema": r.schema_name, "name": r.table_name} for r in cur.fetchall()]

    index_path.parent.mkdir(parents=True, exist_ok=True)
    save_json(index_path, items)
    print(f"Saved tables index: {index_path} (count={len(items)})")


def chunks(lst, size):
    for i in range(0, len(lst), size):
        yield lst[i : i + size]


def build_from_index(index_path: Path, out_base: Path) -> None:
    """
    Conn #2: Батчами по 100 таблиц открываем коннект и генерим json+md.
    Пишем по пути: <type>/<schema>/<name>/<name>.(json|md)
    """
    items = load_json(index_path)
    if not isinstance(items, list) or not items:
        raise RuntimeError(f"Index file is empty or invalid: {index_path}")

    obj_type = "table"
    out_md_base = out_base / "docs" / obj_type
    out_json_base = out_base / "json" / obj_type

    failed = []
    total = len(items)
    batch_num = 0

    for batch in chunks(items, BATCH_SIZE):
        batch_num += 1
        print(f"\n=== Batch {batch_num}: {len(batch)} items ===")

        with get_connection() as conn:
            for item in batch:
                schema = item["schema"]
                name = item["name"]
                ref = f"{schema}.{name}"

                try:
                    doc = get_table_metadata(conn, schema, name)

                    # JSON: build/<DB>/json/table/<schema>/<name>/<name>.json
                    jpath = out_json_base / schema / f"{name}.json"
                    save_json(jpath, doc)

                    # MD: build/<DB>/docs/table/<schema>/<name>/<name>.md
                    md = render_md(doc)
                    mpath = out_md_base / schema / f"{name}.md"
                    save_md(mpath, md)

                except Exception as e:
                    failed.append((ref, str(e)))
                    failed.append((ref, traceback.format_exc()))
                    print(f"FAILED: {ref} -> {e}")

        done = min(batch_num * BATCH_SIZE, total)
        print(f"Progress: {done}/{total}")

    if failed:
        failed_path = out_base / "_failed_tables.txt"
        failed_path.write_text("\n".join([f"{ref}\t{msg}" for ref, msg in failed]), encoding="utf-8")
        print(f"\nFAILED count={len(failed)}. See: {failed_path}")
    else:
        print("\nAll tables generated successfully.")


def main():
    out_base = Path("build") / DATABASE  # build/Reports
    index_path = out_base / "_tables_index.json"

    # 1) Conn #1: index
    fetch_table_list_and_save(index_path)

    # 2) Conn #2: batched generation
    build_from_index(index_path, out_base)


if __name__ == "__main__":
    main()
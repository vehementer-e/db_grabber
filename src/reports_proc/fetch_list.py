from pathlib import Path

from docsgen.config import DATABASE
from docsgen.db import get_connection
from docsgen.io import save_json, save_md, load_json
from docsgen.jgen.procedure import get_procedure_metadata
from docsgen.render.md import render_md


BATCH_SIZE = 100


def fetch_procedure_list_and_save(index_path: Path) -> None:
    """
    Conn #1: Получаем список процедур и сохраняем его в JSON:
    [
      {"db": "Reports", "schema": "dbo", "name": "ProcName"},
      ...
    ]
    """
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT s.name AS schema_name, p.name AS proc_name
            FROM sys.procedures p
            JOIN sys.schemas s ON s.schema_id = p.schema_id
            WHERE p.is_ms_shipped = 0
            ORDER BY s.name, p.name;
            """
        )

        items = [{"db": DATABASE, "schema": r.schema_name, "name": r.proc_name} for r in cur.fetchall()]

    index_path.parent.mkdir(parents=True, exist_ok=True)
    save_json(index_path, items)
    print(f"Saved procedures index: {index_path} (count={len(items)})")


def chunks(lst, size):
    for i in range(0, len(lst), size):
        yield lst[i : i + size]


def build_from_index(index_path: Path, out_base: Path) -> None:
    """
    Conn #2: Батчами по 100 процедур открываем коннект и генерим json+md.
    """
    items = load_json(index_path)
    if not isinstance(items, list) or not items:
        raise RuntimeError(f"Index file is empty or invalid: {index_path}")

    out_md_dir = out_base / "procedures"
    out_json_dir = out_base / "json" / "procedures"
    out_md_dir.mkdir(parents=True, exist_ok=True)
    out_json_dir.mkdir(parents=True, exist_ok=True)

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
                    doc = get_procedure_metadata(conn, schema, name)

                    # JSON
                    jpath = out_json_dir / schema / f"{name}.json"
                    save_json(jpath, doc)

                    # MD
                    md = render_md(doc)
                    mpath = out_md_dir / schema / f"{name}.md"
                    save_md(mpath, md)

                except Exception as e:
                    failed.append((ref, str(e)))
                    print(f"FAILED: {ref} -> {e}")

        done = min(batch_num * BATCH_SIZE, total)
        print(f"Progress: {done}/{total}")

    if failed:
        failed_path = out_base / "_failed_procedures.txt"
        failed_path.write_text("\n".join([f"{ref}\t{msg}" for ref, msg in failed]), encoding="utf-8")
        print(f"\nFAILED count={len(failed)}. See: {failed_path}")
    else:
        print("\nAll procedures generated successfully.")


def main():
    out_base = Path("build") / DATABASE  # build/Reports
    index_path = out_base / "_procedures_index.json"

    # 1) Conn #1: index
    fetch_procedure_list_and_save(index_path)

    # 2) Conn #2: batched generation
    build_from_index(index_path, out_base)


if __name__ == "__main__":
    main()
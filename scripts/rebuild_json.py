from pathlib import Path
import json

from docsgen.db import get_connection
from docsgen.jgen.procedure import get_procedure_metadata
from docsgen.jgen.function import get_function_metadata
from docsgen.jgen.table import get_table_metadata


# =============================
# НАСТРОЙКИ: объекты для сборки
# =============================

PROCEDURES = [
    ("collection", "reportCollectionNonPaymentReason"),
]

FUNCTIONS = [
    ("dbo", "tvf_getBranchByCode"),
]

TABLES = [
    ("collection", "CollectionNonPaymentReasonFullDetail"),
]

OUT_BASE = Path("build/json")


# =============================
# ВСПОМОГАТЕЛЬНОЕ
# =============================

def save_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# =============================
# ОСНОВНОЙ ПРОГОН
# =============================

def main():
    with get_connection() as conn:

        # -------- procedures --------
        for schema, name in PROCEDURES:
            print(f"[procedure] {schema}.{name}")
            doc = get_procedure_metadata(conn, schema, name)

            out = OUT_BASE / "procedures" / f"{schema}.{name}.json"
            save_json(out, doc)

        # -------- functions --------
        for schema, name in FUNCTIONS:
            print(f"[function] {schema}.{name}")
            doc = get_function_metadata(conn, schema, name)

            out = OUT_BASE / "functions" / f"{schema}.{name}.json"
            save_json(out, doc)

        # -------- tables --------
        for schema, name in TABLES:
            print(f"[table] {schema}.{name}")
            doc = get_table_metadata(conn, schema, name)

            out = OUT_BASE / "tables" / f"{schema}.{name}.json"
            save_json(out, doc)

    print("DONE")


if __name__ == "__main__":
    main()
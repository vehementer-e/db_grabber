import json
from collections import defaultdict

import pyodbc

from docsgen.config import DEFAULT_DATABASE
from docsgen.db import get_connection


# ---------- генератор JSON по таблице ----------
def get_table_metadata(conn, schema: str, table: str, database: str | None = None) -> dict:
    """
    Генерация JSON-описания таблицы.
    ВАЖНО: conn передаётся снаружи, подключение тут НЕ создаём.
    """
    db_name_cfg = database or DEFAULT_DATABASE

    # полезно для unicode иногда
    try:
        conn.add_output_converter(pyodbc.SQL_WCHAR, lambda x: x)
    except Exception:
        pass

    cur = conn.cursor()

    # STEP 0. База и object_id
    full_name = f"[{schema.replace(']', ']]')}].[{table.replace(']', ']]')}]"

    cur.execute("SELECT OBJECT_ID(?);", (full_name,))
    row = cur.fetchone()
    if not row or row[0] is None:
        raise ValueError(f"Table {full_name} not found in database {db_name_cfg}")
    obj_id = int(row[0])

    cur.execute("SELECT DB_NAME();")
    db_name = cur.fetchone()[0] or db_name_cfg

    schema_name = schema
    table_name = table

    # STEP 1. Колонки
    cur.execute(
        """
        SELECT
          c.column_id,
          c.name AS column_name,
          t.name AS type_name,
          c.max_length,
          c.[precision],
          c.[scale],
          CAST(c.is_nullable AS bit) AS is_nullable,
          CAST(c.is_identity AS bit) AS is_identity,
          c.collation_name,
          dc.definition AS default_definition
        FROM sys.columns c
        JOIN sys.types t
          ON t.user_type_id = c.user_type_id
        LEFT JOIN sys.default_constraints dc
          ON dc.parent_object_id = c.object_id
         AND dc.parent_column_id = c.column_id
        WHERE c.object_id = ?
        ORDER BY c.column_id;
        """,
        (obj_id,),
    )

    columns = []
    for r in cur:
        tname = r.type_name
        type_suffix = ""

        max_length = r.max_length
        precision = r.precision
        scale = r.scale

        if tname in ("varchar", "nvarchar", "varbinary") and max_length and max_length > 0:
            length = max_length // 2 if tname.startswith("nvar") else max_length
            type_suffix = f"({length})"
        elif tname in ("decimal", "numeric"):
            type_suffix = f"({precision},{scale})"
        elif tname in ("datetime2", "time") and scale and scale > 0:
            type_suffix = f"({scale})"

        columns.append(
            {
                "ordinal": int(r.column_id),
                "name": r.column_name,
                "type": f"{tname}{type_suffix}",
                "is_nullable": bool(r.is_nullable),
                "is_identity": bool(r.is_identity),
                "collation": r.collation_name,
                "default": r.default_definition,
                "description": None,  # руками потом
            }
        )

    # STEP 2. PK
    cur.execute(
        """
        SELECT
          kc.name AS constraint_name,
          ic.key_ordinal,
          c.name AS column_name
        FROM sys.key_constraints kc
        JOIN sys.indexes i
          ON i.object_id = kc.parent_object_id
         AND i.index_id  = kc.unique_index_id
        JOIN sys.index_columns ic
          ON ic.object_id = i.object_id
         AND ic.index_id  = i.index_id
        JOIN sys.columns c
          ON c.object_id = ic.object_id
         AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = ?
          AND kc.[type] = 'PK'
        ORDER BY ic.key_ordinal;
        """,
        (obj_id,),
    )

    pk_rows = cur.fetchall()
    primary_key = None
    if pk_rows:
        primary_key = {
            "name": pk_rows[0].constraint_name,
            "columns": [r.column_name for r in pk_rows],
        }

    # STEP 3. Unique constraints
    cur.execute(
        """
        SELECT
          kc.name AS constraint_name,
          ic.key_ordinal,
          c.name AS column_name
        FROM sys.key_constraints kc
        JOIN sys.indexes i
          ON i.object_id = kc.parent_object_id
         AND i.index_id  = kc.unique_index_id
        JOIN sys.index_columns ic
          ON ic.object_id = i.object_id
         AND ic.index_id  = i.index_id
        JOIN sys.columns c
          ON c.object_id = ic.object_id
         AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = ?
          AND kc.[type] = 'UQ'
        ORDER BY kc.name, ic.key_ordinal;
        """,
        (obj_id,),
    )

    uq_rows = cur.fetchall()
    uq_map = defaultdict(list)
    for r in uq_rows:
        uq_map[r.constraint_name].append(r.column_name)

    unique_constraints = [{"name": k, "columns": v} for k, v in uq_map.items()]

    # STEP 4. Foreign keys
    cur.execute(
        """
        SELECT
          fk.name AS fk_name,
          s2.name AS ref_schema,
          t2.name AS ref_table,
          c1.name AS parent_column,
          c2.name AS ref_column,
          fkc.constraint_column_id
        FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fkc
          ON fkc.constraint_object_id = fk.object_id
        JOIN sys.tables t1
          ON t1.object_id = fk.parent_object_id
        JOIN sys.schemas s1
          ON s1.schema_id = t1.schema_id
        JOIN sys.tables t2
          ON t2.object_id = fk.referenced_object_id
        JOIN sys.schemas s2
          ON s2.schema_id = t2.schema_id
        JOIN sys.columns c1
          ON c1.object_id = t1.object_id
         AND c1.column_id = fkc.parent_column_id
        JOIN sys.columns c2
          ON c2.object_id = t2.object_id
         AND c2.column_id = fkc.referenced_column_id
        WHERE fk.parent_object_id = ?
        ORDER BY fk.name, fkc.constraint_column_id;
        """,
        (obj_id,),
    )

    fk_rows = cur.fetchall()
    fk_map = defaultdict(lambda: {"ref_schema": None, "ref_table": None, "mapping": []})
    for r in fk_rows:
        slot = fk_map[r.fk_name]
        slot["ref_schema"] = r.ref_schema
        slot["ref_table"] = r.ref_table
        slot["mapping"].append({"parent_column": r.parent_column, "ref_column": r.ref_column})

    foreign_keys = []
    for fk_name, data in fk_map.items():
        foreign_keys.append(
            {
                "name": fk_name,
                "ref_schema": data["ref_schema"],
                "ref_table": data["ref_table"],
                "columns": data["mapping"],
            }
        )

    # STEP 5. Check constraints
    cur.execute(
        """
        SELECT
          cc.name AS constraint_name,
          cc.definition
        FROM sys.check_constraints cc
        WHERE cc.parent_object_id = ?
        ORDER BY cc.name;
        """,
        (obj_id,),
    )
    check_constraints = [{"name": r.constraint_name, "definition": r.definition} for r in cur.fetchall()]

    # STEP 6. Indexes (не PK/UQ)
    cur.execute(
        """
        SELECT
          i.name AS index_name,
          i.type_desc,
          i.is_unique,
          i.is_primary_key,
          i.is_unique_constraint,
          ic.key_ordinal,
          ic.is_included_column,
          c.name AS column_name
        FROM sys.indexes i
        JOIN sys.index_columns ic
          ON ic.object_id = i.object_id
         AND ic.index_id  = i.index_id
        JOIN sys.columns c
          ON c.object_id = ic.object_id
         AND c.column_id = ic.column_id
        WHERE i.object_id = ?
          AND i.name IS NOT NULL
        ORDER BY i.name, ic.key_ordinal, ic.index_column_id;
        """,
        (obj_id,),
    )

    idx_rows = cur.fetchall()
    idx_map = defaultdict(lambda: {"type_desc": None, "is_unique": False, "keys": [], "includes": []})
    for r in idx_rows:
        if r.is_primary_key or r.is_unique_constraint:
            continue
        slot = idx_map[r.index_name]
        slot["type_desc"] = r.type_desc
        slot["is_unique"] = bool(r.is_unique)
        if r.is_included_column:
            slot["includes"].append(r.column_name)
        else:
            slot["keys"].append(r.column_name)

    indexes = []
    for idx_name, data in idx_map.items():
        indexes.append(
            {
                "name": idx_name,
                "type": data["type_desc"],
                "is_unique": data["is_unique"],
                "keys": data["keys"],
                "includes": data["includes"],
            }
        )

    # STEP 7. Triggers
    cur.execute(
        """
        SELECT
          tr.name AS trigger_name,
          CAST(tr.is_disabled AS bit) AS is_disabled
        FROM sys.triggers tr
        WHERE tr.parent_id = ?
        ORDER BY tr.name;
        """,
        (obj_id,),
    )
    triggers = [{"name": r.trigger_name, "is_disabled": bool(r.is_disabled)} for r in cur.fetchall()]

    # STEP 8. depends_on (для таблицы — обычно пусто)
    depends_on = []

    # STEP 9. required_by (кто зависит от таблицы)
    cur.execute(
        """
        SELECT
          o.type       AS obj_type,
          s.name       AS [schema],
          o.name       AS [name]
        FROM sys.sql_expression_dependencies sed
        JOIN sys.objects o ON o.object_id = sed.referencing_id
        JOIN sys.schemas s ON s.schema_id = o.schema_id
        WHERE sed.referenced_id = ?
        ORDER BY s.name, o.name;
        """,
        (obj_id,),
    )

    required_by = []
    for r in cur.fetchall():
        # в “простом” варианте не заморачиваемся:
        required_by.append({"objType": "object", "db": db_name, "schema": r.schema, "name": r.name, "relation": "other"})

    doc = {
        "object_type": "table",
        "db": db_name,
        "schema": schema_name,
        "name": table_name,
        "columns": columns,
        "constraints": {
            "primary_key": primary_key,
            "unique_constraints": unique_constraints,
            "foreign_keys": foreign_keys,
            "check_constraints": check_constraints,
        },
        "indexes": indexes,
        "triggers": triggers,
        "dependencies": {
            "depends_on": depends_on,
            "required_by": required_by,
        },
    }
    return doc


# if __name__ == "__main__":
#     schema = "collection"
#     table = "CollectionNonPaymentReasonFullDetail"

#     with get_connection() as conn:
#         meta = get_table_metadata(conn, schema, table)
#         print(json.dumps(meta, ensure_ascii=False, indent=2))

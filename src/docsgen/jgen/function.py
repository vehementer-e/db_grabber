import json
from collections import defaultdict

import pyodbc

from docsgen.config import DEFAULT_DATABASE
from docsgen.db import get_connection


def map_objtype_from_code(class_desc, ref_type):
    if class_desc == "OBJECT":
        if ref_type in ("U", "S"):
            return "table"
        if ref_type == "V":
            return "view"
        if ref_type in ("P", "PC"):
            return "procedure"
        if ref_type in ("FN", "FS", "FT", "IF", "TF"):
            return "function"
        if ref_type is None:
            return "object"
        return "object"
    return class_desc or "object"


def map_required_by_objtype(o_type):
    if o_type in ("U", "S"):
        return "table"
    if o_type == "V":
        return "view"
    if o_type in ("P", "PC"):
        return "procedure"
    if o_type in ("FN", "FS", "FT", "IF", "TF"):
        return "function"
    return "object"


def map_required_by_relation(o_type):
    if o_type == "V":
        return "selectsFrom"
    if o_type in ("P", "PC"):
        return "executes"
    if o_type in ("FN", "FS", "FT", "IF", "TF"):
        return "calls"
    return "other"


def get_function_metadata(conn, schema: str, func: str, database: str | None = None) -> dict:
    """
    Генерация JSON-описания табличной функции (IF/TF/FT).
    ВАЖНО: conn передаётся снаружи, подключение тут НЕ создаём.
    """
    db_name_cfg = database or DEFAULT_DATABASE

    # полезно для unicode иногда (как в твоих jgen)
    try:
        conn.add_output_converter(pyodbc.SQL_WCHAR, lambda x: x)
    except Exception:
        pass

    cur = conn.cursor()

    # ---------- Шаг 0. Найти object_id и проверить, что это TVF ----------
    full_name = f"[{schema.replace(']', ']]')}].[{func.replace(']', ']]')}]"

    cur.execute("SELECT OBJECT_ID(?)", (full_name,))
    row = cur.fetchone()
    if not row or row[0] is None:
        raise ValueError(f"Object {full_name} not found in database {db_name_cfg}")
    obj_id = int(row[0])

    cur.execute("SELECT DB_NAME();")
    db_name = cur.fetchone()[0] or db_name_cfg

    cur.execute(
        """
        SELECT o.[type]
        FROM sys.objects o
        WHERE o.object_id = ?
          AND o.[type] IN ('FN', 'FS', 'IF','TF','FT');  -- только табличные функции
        """,
        obj_id,
    )
    trow = cur.fetchone()
    if not trow:
        raise ValueError(f"Object {full_name} is not a function")
    
    func_type = trow[0]

    # ---------- Шаг 1. Параметры ----------
    cur.execute(
        """
        SELECT
            prm.parameter_id AS param_id,
            prm.name         AS param_name,
            t.name           AS type_name,
            prm.max_length,
            prm.[precision],
            prm.[scale],
            CAST(prm.is_output AS bit) AS is_output
        FROM sys.parameters AS prm
        JOIN sys.types      AS t ON t.user_type_id = prm.user_type_id
        WHERE prm.object_id = ?
          AND prm.parameter_id > 0
        ORDER BY prm.parameter_id;
        """,
        (obj_id,),
    )

    params = []
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

        params.append(
            {
                "name": r.param_name,
                "type": f"{tname}{type_suffix}",
                "is_output": bool(r.is_output),
            }
        )

    # ---------- Шаг 2. Результирующий набор ----------
    if func_type in ("IF", "TF", "FT"):
        cur.execute(
            """
            SELECT
                column_ordinal,
                name,
                system_type_name,
                CAST(is_nullable AS bit) AS is_nullable
            FROM sys.dm_exec_describe_first_result_set_for_object(?, NULL)
            WHERE error_number IS NULL
            ORDER BY column_ordinal;
            """,
            (obj_id,),
        )

        result_dataset = []
        for r in cur:
            result_dataset.append(
                {
                    "name": r.name,
                    "type": r.system_type_name,
                    "is_nullable": bool(r.is_nullable),
                }
            )
        if not result_dataset:
            result_dataset = None
    else:
        result_dataset = None
    
    return_value = None
    if func_type in ("FN", "FS"):
        cur.execute(
            """
            SELECT
                t.name AS type_name,
                p.max_length,
                p.[precision],
                p.[scale],
                CAST(p.is_nullable AS bit) AS is_nullable
            FROM sys.parameters p
            JOIN sys.types t ON t.user_type_id = p.user_type_id
            WHERE p.object_id = ?
            AND p.parameter_id = 0;
            """,
            (obj_id,),
        )
        rr = cur.fetchone()
        if rr:
            tname = rr.type_name
            print(f"-------------------------------------------{tname}")
            type_suffix = ""

            max_length = rr.max_length
            precision = rr.precision
            scale = rr.scale

            if tname in ("varchar", "nvarchar", "varbinary") and max_length and max_length > 0:
                length = max_length // 2 if tname.startswith("nvar") else max_length
                type_suffix = f"({length})"
            elif tname in ("decimal", "numeric"):
                type_suffix = f"({precision},{scale})"
            elif tname in ("datetime2", "time") and scale and scale > 0:
                type_suffix = f"({scale})"

            return_value = {
                "type": f"{tname}{type_suffix}",
                "is_nullable": bool(rr.is_nullable),
            }
            print(return_value)

        result_dataset = None

    # ---------- Шаг 3. depends_on (dm_sql_referenced_entities + sql_expression_dependencies) ----------
    cur.execute(
        """
        SELECT
          COALESCE(r.referenced_database_name, DB_NAME()) AS db,
          r.referenced_schema_name                        AS [schema],
          r.referenced_entity_name                        AS [name],
          r.referenced_id                                 AS referenced_id,
          r.referenced_class_desc                         AS class_desc,
          r.is_selected                                   AS is_selected,
          r.is_updated                                    AS is_updated
        FROM sys.dm_sql_referenced_entities(?, N'OBJECT') AS r;
        """,
        (full_name,),
    )
    dme_rows = cur.fetchall()

    cur.execute(
        """
        SELECT
          COALESCE(sed.referenced_database_name, DB_NAME()) AS db,
          sed.referenced_schema_name                        AS [schema],
          sed.referenced_entity_name                        AS [name],
          sed.referenced_id                                 AS referenced_id,
          sed.referenced_class_desc                         AS class_desc
        FROM sys.sql_expression_dependencies AS sed
        WHERE sed.referencing_id = ?
          AND sed.referenced_entity_name IS NOT NULL;
        """,
        (obj_id,),
    )
    sed_rows = cur.fetchall()

    allrefs = defaultdict(lambda: {"referenced_id": None, "class_desc": None, "any_select": False, "any_update": False})

    for r in dme_rows:
        key = (r.db, r.schema, r.name)
        slot = allrefs[key]
        if r.referenced_id is not None:
            slot["referenced_id"] = r.referenced_id
        if r.class_desc is not None:
            slot["class_desc"] = r.class_desc
        if getattr(r, "is_selected", False):
            slot["any_select"] = True
        if getattr(r, "is_updated", False):
            slot["any_update"] = True

    for r in sed_rows:
        key = (r.db, r.schema, r.name)
        slot = allrefs[key]
        if r.referenced_id is not None:
            slot["referenced_id"] = r.referenced_id
        if r.class_desc is not None:
            slot["class_desc"] = r.class_desc

    # ---------- Шаг 4. типы объектов (локальные + внешние) ----------
    cur.execute(
        """
        SELECT
          DB_NAME()   AS db,
          s.name      AS [schema],
          o.name      AS [name],
          o.type      AS ref_type
        FROM sys.objects o
        JOIN sys.schemas s ON s.schema_id = o.schema_id;
        """
    )
    x_types = {}
    for r in cur:
        x_types[(r.db, r.schema, r.name)] = r.ref_type

    # внешние БД — запросы "в лоб"
    external_refs = defaultdict(set)
    current_db = db_name

    for (db, sch, name), info in allrefs.items():
        if db and db != current_db and (info["class_desc"] == "OBJECT"):
            external_refs[db].add((sch, name))

    for db_name_ext, refs in external_refs.items():
        for sch, name in refs:
            sql = f"""
            SELECT
              N'{db_name_ext}' AS db,
              s.name       AS [schema],
              o.name       AS [name],
              o.type       AS ref_type
            FROM [{db_name_ext}].sys.objects o
            JOIN [{db_name_ext}].sys.schemas s ON s.schema_id = o.schema_id
            WHERE s.name = ? AND o.name = ?;
            """
            cur.execute(sql, (sch, name))
            rr = cur.fetchone()
            if rr:
                x_types[(rr.db, rr.schema, rr.name)] = rr.ref_type

    depends_on = []
    for (db, sch, name), info in sorted(allrefs.items(), key=lambda x: (x[0][0] or "", x[0][1] or "", x[0][2] or "")):
        ref_type = x_types.get((db, sch, name))
        obj_type = map_objtype_from_code(info["class_desc"], ref_type) or "object"
        relation = "updates" if info["any_update"] else ("selectsFrom" if info["any_select"] else "other")
        depends_on.append({"objType": obj_type, "db": db, "schema": sch, "name": name, "relation": relation})

    # ---------- Шаг 5. required_by ----------
    cur.execute(
        """
        SELECT
          o.type       AS obj_type,
          s.name       AS [schema],
          o.name       AS [name]
        FROM sys.dm_sql_referencing_entities(?, N'OBJECT') AS r
        JOIN sys.objects o ON o.object_id = r.referencing_id
        JOIN sys.schemas s ON s.schema_id = o.schema_id;
        """,
        (full_name,),
    )
    rb_rows = cur.fetchall()

    required_by = []
    for r in rb_rows:
        obj_type = map_required_by_objtype(r.obj_type)
        relation = map_required_by_relation(r.obj_type)
        required_by.append(
            {"objType": obj_type, "db": db_name, "schema": r.schema, "name": r.name, "relation": relation}
        )

    # ---------- Шаг 6. description (extended properties) ----------
    cur.execute(
        """
        SELECT CAST(ep.value AS nvarchar(4000))
        FROM sys.extended_properties ep
        WHERE ep.major_id = ?
          AND ep.minor_id = 0
          AND ep.name = N'MS_Description';
        """,
        (obj_id,),
    )
    row = cur.fetchone()
    description = row[0] if row else None

    # ---------- Шаг 7. Финальный JSON ----------
    doc = {
        "object_type": "function",
        "function_kind": "table-valued" if func_type in ("IF", "TF", "FT") else "scalar-valued",
        "return_value": return_value,
        "db": db_name,
        "schema": schema,
        "name": func,
        "title": f"{schema}.{func}",
        "description": description,
        "parameters": params,
        "result_dataset": result_dataset,
        "dependencies": {
            "depends_on": depends_on,
            "required_by": required_by,
        },
    }
    return doc


# if __name__ == "__main__":
#     schema = "dbo"
#     func = "tvf_getBranchByCode"

#     with get_connection() as conn:
#         meta = get_function_metadata(conn, schema, func)
#         print(json.dumps(meta, ensure_ascii=False, indent=2))


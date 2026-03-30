import pyodbc
import json

# ---------- настройки подключения ----------

SERVER = r"C3-DWH-DB01.carm.corp"
DATABASE = "dwh2"


conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

tsql = r"""
DECLARE @schema sysname = ?;
DECLARE @proc   sysname = ?;

DECLARE @full   sysname = CONCAT(QUOTENAME(@schema), N'.', QUOTENAME(@proc));
DECLARE @obj_id int     = OBJECT_ID(@full);

IF @obj_id IS NULL
BEGIN
    RAISERROR(N'Object %s not found in current DB', 16, 1, @full);
    RETURN;
END;

-- тут идёт весь ТВОЙ код:
--   - #t_params
--   - @json_params
--   - @json_rs
--   - @json_dependsOn
--   - @json_required_by
--   и т.п.
-- НИЧЕГО не меняем, кроме самого хвоста!

-------------------------------------------------------------------------------
-- финальный SELECT: отдаем куски как строки
-------------------------------------------------------------------------------
SELECT
    DB_NAME()                            AS [db],
    s.name                               AS [schema],
    p.name                               AS [name],
    CONCAT(s.name, N'.', p.name)         AS [title],
    CAST(ep.value AS nvarchar(4000))     AS [description],

    @json_params                         AS [json_params],
    @json_rs                             AS [json_rs],
    @json_dependsOn                      AS [json_dependsOn],
    @json_required_by                    AS [json_required_by]
FROM sys.procedures p
JOIN sys.schemas   s ON s.schema_id = p.schema_id
LEFT JOIN sys.extended_properties ep
       ON ep.major_id = p.object_id 
      AND ep.minor_id = 0 
      AND ep.name = N'MS_Description'
WHERE p.object_id = @obj_id;
"""

schema = "collection"
proc   = "reportCollectionNonPaymentReason"

with pyodbc.connect(conn_str, timeout=5) as conn:
    with conn.cursor() as cur:
        cur.execute(tsql, (schema, proc))
        row = cur.fetchone()

params       = json.loads(row.json_params)       if row.json_params       else []
result_set   = json.loads(row.json_rs)           if row.json_rs           else None
depends_on   = json.loads(row.json_dependsOn)    if row.json_dependsOn    else []
required_by  = json.loads(row.json_required_by)  if row.json_required_by  else []

doc = {
    "object_type": "procedure",
    "db": row.db,
    "schema": row.schema,
    "name": row.name,
    "title": row.title,
    "description": row.description,
    "parameters": params,
    "result_dataset": result_set,
    "dependencies": {
        "depends_on": depends_on,
        "required_by": required_by
    }
}

print(json.dumps(doc, ensure_ascii=False, indent=2))
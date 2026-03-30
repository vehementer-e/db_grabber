use dwh2
go
DECLARE @schema sysname = N'hub';
DECLARE @table  sysname = N'Клиенты';

SET NOCOUNT ON;

DECLARE @object_id int = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table));

IF @object_id IS NULL
BEGIN
    RAISERROR(N'Table %s.%s not found in database %s', 16, 1, @schema, @table);
    RETURN;
END;

---------------------------------------------------
-- БАЗА
---------------------------------------------------
DROP TABLE IF EXISTS #t_table;

SELECT
    DB_NAME()   AS db_name,
    s.name      AS schema_name,
    t.name      AS table_name,
    t.object_id AS object_id
INTO #t_table
FROM sys.tables  t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.object_id = @object_id;

---------------------------------------------------
-- КОЛОНКИ
---------------------------------------------------
DROP TABLE IF EXISTS #t_columns;

SELECT
    c.name                          AS [name],
    c.column_id                     AS [order],
    ty.name                         AS [system_type],
    c.max_length                    AS [max_length],
    c.collation_name                AS [collation],
    c.is_nullable                   AS [is_nullable],
    IIF(ic.column_id IS NULL, 0, 1) AS [is_identity]
INTO #t_columns
FROM sys.columns c
JOIN sys.types   ty
     ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.identity_columns ic
     ON c.object_id = ic.object_id
    AND c.column_id = ic.column_id
WHERE c.object_id = @object_id
ORDER BY c.column_id;

---------------------------------------------------
-- ОГРАНИЧЕНИЯ: PRIMARY KEY
---------------------------------------------------
DROP TABLE IF EXISTS #t_pk;

SELECT
    kc.name               AS constraint_name,
    IIF(i.type_desc = 'CLUSTERED', 1, 0) AS is_clustered,
    c.name                AS column_name,
    ic.key_ordinal        AS key_ordinal,
    ic.is_descending_key  AS is_descending
INTO #t_pk
FROM sys.key_constraints kc
JOIN sys.indexes i
  ON kc.parent_object_id = i.object_id
 AND kc.unique_index_id = i.index_id
JOIN sys.index_columns ic
  ON ic.object_id = i.object_id
 AND ic.index_id  = i.index_id
JOIN sys.columns c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE kc.parent_object_id = @object_id
  AND kc.[type] = 'PK'
ORDER BY kc.name, ic.key_ordinal;

---------------------------------------------------
-- ОГРАНИЧЕНИЯ: UNIQUE
---------------------------------------------------
DROP TABLE IF EXISTS #t_uq;

SELECT
    kc.name               AS constraint_name,
    c.name                AS column_name,
    ic.key_ordinal        AS key_ordinal,
    ic.is_descending_key  AS is_descending
INTO #t_uq
FROM sys.key_constraints kc
JOIN sys.indexes i
  ON kc.parent_object_id = i.object_id
 AND kc.unique_index_id = i.index_id
JOIN sys.index_columns ic
  ON ic.object_id = i.object_id
 AND ic.index_id  = i.index_id
JOIN sys.columns c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE kc.parent_object_id = @object_id
  AND kc.[type] = 'UQ'
ORDER BY kc.name, ic.key_ordinal;

---------------------------------------------------
-- ОГРАНИЧЕНИЯ: FOREIGN KEY
---------------------------------------------------
DROP TABLE IF EXISTS #t_fk;

SELECT
    fk.object_id                      AS fk_id,
    fk.name                           AS fk_name,
    c.name                            AS column_name,
    fkc.constraint_column_id          AS key_ordinal,
    s_ref.name                        AS ref_schema,
    t_ref.name                        AS ref_table,
    c_ref.name                        AS ref_column_name,
    fk.delete_referential_action_desc AS on_delete,
    fk.update_referential_action_desc AS on_update,
    IIF(fk.is_not_trusted = 1, 0, 1)  AS is_trusted
INTO #t_fk
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
  ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c
  ON c.object_id = fkc.parent_object_id
 AND c.column_id = fkc.parent_column_id
JOIN sys.tables t_ref
  ON fkc.referenced_object_id = t_ref.object_id
JOIN sys.schemas s_ref
  ON t_ref.schema_id = s_ref.schema_id
JOIN sys.columns c_ref
  ON c_ref.object_id = fkc.referenced_object_id
 AND c_ref.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = @object_id
ORDER BY fk.name, fkc.constraint_column_id;

---------------------------------------------------
-- ОГРАНИЧЕНИЯ: CHECK
---------------------------------------------------
DROP TABLE IF EXISTS #t_check;

SELECT
    cc.name                      AS constraint_name,
    cc.[definition]              AS [definition],
    IIF(cc.is_not_trusted = 1, 0, 1) AS is_trusted
INTO #t_check
FROM sys.check_constraints cc
WHERE cc.parent_object_id = @object_id
ORDER BY cc.name;

---------------------------------------------------
-- ИНДЕКСЫ
---------------------------------------------------
DROP TABLE IF EXISTS #t_indexes;

SELECT
    i.object_id,
    i.index_id,
    i.name                AS index_name,
    i.type_desc           AS type_desc,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    i.fill_factor,
    i.has_filter,
    i.filter_definition,
    c.name                AS column_name,
    ic.key_ordinal        AS key_ordinal,
    ic.is_included_column AS is_included,
    ic.is_descending_key  AS is_descending
INTO #t_indexes
FROM sys.indexes i
LEFT JOIN sys.index_columns ic
  ON i.object_id = ic.object_id
 AND i.index_id  = ic.index_id
LEFT JOIN sys.columns c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE i.object_id = @object_id
  AND i.type <> 0          -- не heap
  AND i.is_hypothetical = 0
ORDER BY i.index_id, ic.key_ordinal, ic.column_id;

---------------------------------------------------
-- ТРИГГЕРЫ
---------------------------------------------------
DROP TABLE IF EXISTS #t_triggers;

SELECT
    tr.object_id   AS trigger_id,
    tr.name        AS trigger_name,
    tr.is_disabled AS is_disabled,
    te.type_desc   AS event_type,
    te.type        AS event_code
INTO #t_triggers
FROM sys.triggers tr
JOIN sys.trigger_events te
  ON tr.object_id = te.object_id
WHERE tr.parent_id = @object_id
ORDER BY tr.name;

---------------------------------------------------
-- ЗАВИСИМОСТИ: depends_on (родители по FK)
---------------------------------------------------
DROP TABLE IF EXISTS #t_dependsOn;

SELECT DISTINCT
    objType     = 'table',
    db_name     = DB_NAME(),
    schema_name = s_ref.name,
    object_name = t_ref.name,
    relation    = 'foreignKey'
INTO #t_dependsOn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
  ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables t_ref
  ON fkc.referenced_object_id = t_ref.object_id
JOIN sys.schemas s_ref
  ON t_ref.schema_id = s_ref.schema_id
WHERE fk.parent_object_id = @object_id;

---------------------------------------------------
-- ЗАВИСИМОСТИ: required_by (дети + код)
---------------------------------------------------
DROP TABLE IF EXISTS #t_requiredBy;

-- (1) таблицы с FK на текущую
SELECT DISTINCT
    objType     = cast('table' as nvarchar(50)),
    db_name     = cast(DB_NAME() as sysname),
    schema_name = cast(s_p.name as sysname),
    object_name = cast(t_p.name as sysname),
    relation    = cast('foreignKey' as nvarchar(50))
INTO #t_requiredBy
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
  ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables t_p
  ON fk.parent_object_id = t_p.object_id
JOIN sys.schemas s_p
  ON t_p.schema_id = s_p.schema_id
WHERE fkc.referenced_object_id = @object_id;

-- (2) объекты кода, которые зависят от таблицы (dm_sql_referencing_entities)
INSERT INTO #t_requiredBy (objType, db_name, schema_name, object_name, relation)
--drop table if exists t_requiredBy
SELECT DISTINCT
    objType = CASE o.[type]
                 WHEN 'P'  THEN 'procedure'
                 WHEN 'PC' THEN 'procedure'
                 WHEN 'V'  THEN 'view'
                 WHEN 'FN' THEN 'function'
                 WHEN 'FS' THEN 'function'
                 WHEN 'FT' THEN 'function'
                 WHEN 'IF' THEN 'function'
                 WHEN 'TF' THEN 'function'
                 WHEN 'TR' THEN 'trigger'
                 WHEN 'U'  THEN 'table'
                 WHEN 'S'  THEN 'table'
                 ELSE 'OBJECT_OR_COLUMN'
              END,
    db_name     = DB_NAME(),
    schema_name = s.name,
    object_name = o.name,
    relation    = CASE o.[type]
                      WHEN 'V'  THEN 'selectsFrom'
                      WHEN 'P'  THEN 'executes'
                      WHEN 'PC' THEN 'executes'
                      WHEN 'FN' THEN 'calls'
                      WHEN 'FS' THEN 'calls'
                      WHEN 'FT' THEN 'calls'
                      WHEN 'IF' THEN 'calls'
                      WHEN 'TF' THEN 'calls'
                      ELSE 'other'
                  END
--INTO #t_reqiredBy
FROM sys.dm_sql_referencing_entities(
        QUOTENAME(@schema) + N'.' + QUOTENAME(@table),
        N'OBJECT'
     ) AS r
JOIN sys.objects o ON o.object_id = r.referencing_id
JOIN sys.schemas s ON s.schema_id = o.schema_id;

---------------------------------------------------
-- JSON-ФРАГМЕНТЫ
---------------------------------------------------
DECLARE
    @json_columns       nvarchar(max),
    @json_pk            nvarchar(max),
    @json_uq            nvarchar(max),
    @json_fk            nvarchar(max),
    @json_check         nvarchar(max),
    @json_indexes       nvarchar(max),
    @json_triggers      nvarchar(max),
    @json_dependsOn     nvarchar(max),
    @json_requiredBy    nvarchar(max);

-- Колонки
SELECT @json_columns =
(
    SELECT *
    FROM #t_columns
    ORDER BY [order]
    FOR JSON PATH
);

-- PK
SELECT @json_pk =
(
    SELECT TOP (1)
        constraint_name AS [name],
        is_clustered    AS [is_clustered],
        (
            SELECT
                column_name  AS [name],
                key_ordinal  AS [key_ordinal],
                is_descending AS [is_descending]
            FROM #t_pk pk2
            WHERE pk2.constraint_name = pk.constraint_name
            ORDER BY key_ordinal
            FOR JSON PATH
        ) AS [columns]
    FROM #t_pk pk
    ORDER BY constraint_name
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
);

-- UQ
SELECT @json_uq =
(
    SELECT
        constraint_name AS [name],
        (
            SELECT
                column_name  AS [name],
                key_ordinal  AS [key_ordinal],
                is_descending AS [is_descending]
            FROM #t_uq uq2
            WHERE uq2.constraint_name = uq.constraint_name
            ORDER BY key_ordinal
            FOR JSON PATH
        ) AS [columns]
    FROM #t_uq uq
    GROUP BY constraint_name
    ORDER BY constraint_name
    FOR JSON PATH
);

-- FK
SELECT @json_fk =
(
    SELECT
        fk_id,
        fk_name AS [name],
        (
            SELECT
                column_name AS [name],
                key_ordinal AS [key_ordinal]
            FROM #t_fk fk2
            WHERE fk2.fk_id = fk.fk_id
            ORDER BY key_ordinal
            FOR JSON PATH
        ) AS [columns],
        (
            SELECT
                DB_NAME()     AS [db],
                ref_schema    AS [schema],
                ref_table     AS [name]
            FROM #t_fk fk3
            WHERE fk3.fk_id = fk.fk_id
            GROUP BY ref_schema, ref_table
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS [referenced_table],
        (
            SELECT
                ref_column_name AS [name],
                key_ordinal     AS [key_ordinal]
            FROM #t_fk fk4
            WHERE fk4.fk_id = fk.fk_id
            ORDER BY key_ordinal
            FOR JSON PATH
        ) AS [referenced_columns],
        MAX(on_delete)   AS [on_delete],
        MAX(on_update)   AS [on_update],
        MAX(is_trusted)  AS [is_trusted]
    FROM #t_fk fk
    GROUP BY fk_id, fk_name
    ORDER BY fk_name
    FOR JSON PATH
);

-- CHECK
SELECT @json_check =
(
    SELECT *
    FROM #t_check
    ORDER BY constraint_name
    FOR JSON PATH
);

-- Индексы
SELECT @json_indexes =
(
    SELECT
        i.object_id,
        i.index_id,
        i.index_name        AS [name],
        i.type_desc         AS [type],
        i.is_unique,
        i.is_primary_key,
        i.is_unique_constraint,
        i.fill_factor,
        i.has_filter,
        i.filter_definition,
        (
            SELECT
                column_name   AS [name],
                key_ordinal   AS [key_ordinal],
                is_descending AS [is_descending]
            FROM #t_indexes i2
            WHERE i2.object_id = i.object_id
              AND i2.index_id  = i.index_id
              AND i2.is_included = 0
            ORDER BY key_ordinal
            FOR JSON PATH
        ) AS [columns],
        (
            SELECT
                column_name AS [name]
            FROM #t_indexes i3
            WHERE i3.object_id = i.object_id
              AND i3.index_id  = i.index_id
              AND i3.is_included = 1
            ORDER BY column_name
            FOR JSON PATH
        ) AS [included_columns]
    FROM #t_indexes i
    GROUP BY
        i.object_id, i.index_id,
        i.index_name, i.type_desc,
        i.is_unique, i.is_primary_key, i.is_unique_constraint,
        i.fill_factor, i.has_filter, i.filter_definition
    ORDER BY i.index_id
    FOR JSON PATH
);

-- Триггеры
SELECT @json_triggers =
(
    SELECT
        trigger_id,
        trigger_name AS [name],
        is_disabled,
        (
            SELECT
                event_type AS [event_type],
                event_code AS [event_code]
            FROM #t_triggers t2
            WHERE t2.trigger_id = t.trigger_id
            FOR JSON PATH
        ) AS [events]
    FROM #t_triggers t
    GROUP BY trigger_id, trigger_name, is_disabled
    ORDER BY trigger_name
    FOR JSON PATH
);

-- DEPENDENCIES
SELECT @json_dependsOn =
(
    SELECT
        objType     AS [objType],
        db_name     AS [db],
        schema_name AS [schema],
        object_name AS [name],
        relation    AS [relation]
    FROM #t_dependsOn
    FOR JSON PATH
);

SELECT @json_requiredBy =
(
    SELECT
        objType     AS [objType],
        db_name     AS [db],
        schema_name AS [schema],
        object_name AS [name],
        relation    AS [relation]
    FROM #t_requiredBy
    FOR JSON PATH
);

---------------------------------------------------
-- Пустые массивы вместо NULL
---------------------------------------------------
SET @json_columns     = ISNULL(@json_columns,    N'[]');
SET @json_uq          = ISNULL(@json_uq,         N'[]');
SET @json_fk          = ISNULL(@json_fk,         N'[]');
SET @json_check       = ISNULL(@json_check,      N'[]');
SET @json_indexes     = ISNULL(@json_indexes,    N'[]');
SET @json_triggers    = ISNULL(@json_triggers,   N'[]');
SET @json_dependsOn   = ISNULL(@json_dependsOn,  N'[]');
SET @json_requiredBy  = ISNULL(@json_requiredBy, N'[]');

---------------------------------------------------
-- ФИНАЛЬНЫЙ JSON-ДОКУМЕНТ
---------------------------------------------------
SELECT
    object_type = 'table',
    db          = tt.db_name,
    [schema]    = tt.schema_name,
    [name]      = tt.table_name,

    columns = JSON_QUERY(@json_columns),

    constraints = JSON_QUERY(
        (
            SELECT
                JSON_QUERY(@json_pk)    AS [primary_key],
                JSON_QUERY(@json_uq)    AS [unique_constraints],
                JSON_QUERY(@json_fk)    AS [foreign_keys],
                JSON_QUERY(@json_check) AS [check_constraints]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ),

    indexes = JSON_QUERY(@json_indexes),

    triggers = JSON_QUERY(@json_triggers),

    dependencies = JSON_QUERY(
        (
            SELECT
                JSON_QUERY(@json_dependsOn)  AS [depends_on],
                JSON_QUERY(@json_requiredBy) AS [required_by]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    )
FROM #t_table tt
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;

-- =======================================================
-- Create: 25.10.2023. А.Никитин
-- Description:	DWH-2291 сверочный отчет по кол занимаемого места
-- =======================================================
CREATE   PROC dbo.fill_archive_table_statistics
	--@calc_metric nvarchar(100) = '',
	--@in_dt_stat_from datetime2(0) = NULL,
	--@mode int = 1, -- 0 - full, 1 - increment
	--@isDebug int = 0
AS
BEGIN

SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @dt_stat_from datetime2(0), @dt_stat_to datetime2(0)
DECLARE @metric nvarchar(100), @dwh_created_at datetime
DECLARE @calendar TABLE(dt date, partition_number int)
DECLARE @calendar_time TABLE(dt_time_from datetime2(0), dt_time_to datetime2(0))

--DROP TABLE IF EXISTS #t_archive_table_statistics
--CREATE TABLE #t_archive_table_statistics(
--	dt_stat date NOT NULL,
--	database_name varchar(127) NOT NULL,
--	table_name varchar(127) NOT NULL,
--	row_count int NOT NULL
--)

DROP TABLE IF EXISTS #t_NaumenDBReportArch

;with cte as (
SELECT
	s.name as schema_name,
     tbl.name tbl_name,
      idx.type_desc idx_type,
      idx.name idx_name,
      dts.name + ISNULL('-> ' + dts2.name, '') dts_name,
      dts.type_desc + ISNULL('-> ' + dts2.type_desc, '') dts_type,
      prt.partition_number,
      prt.rows,
	  sum(prt.rows) over(partition by tbl.name , idx.type_desc, idx.name) as TotalRows,
      prv.value low_boundary,
	  
      prs.name part_scheme_name,
      pfs.name part_func_name
	  ,a.TotalSpaceKB / 1024 as TotalSpaceMB
	  ,a.UnusedSpaceKB / 1024 as UnusedSpaceMB
	  ,a.UsedSpaceKB / 1024 as UsedSpaceMB
FROM NaumenDBReportArch.sys.tables tbl with(nolock)
join NaumenDBReportArch.sys.schemas s with(nolock) on s.schema_id = tbl.schema_id
JOIN NaumenDBReportArch.sys.indexes idx with(nolock) ON idx.object_id = tbl.object_id
JOIN NaumenDBReportArch.sys.data_spaces dts with(nolock) ON dts.data_space_id = idx.data_space_id
JOIN NaumenDBReportArch.sys.partitions prt with(nolock) ON prt.object_id = tbl.object_id AND prt.index_id =idx.index_id
LEFT JOIN NaumenDBReportArch.sys.partition_schemes prs with(nolock) ON prs.data_space_id = dts.data_space_id
LEFT JOIN NaumenDBReportArch.sys.partition_functions pfs with(nolock) ON pfs.function_id = prs.function_id
LEFT JOIN NaumenDBReportArch.sys.partition_range_values prv with(nolock) ON
      prv.function_id = pfs.function_id AND prv.boundary_id =prt.partition_number - 1
LEFT JOIN NaumenDBReportArch.sys.destination_data_spaces dds with(nolock) ON
      dds.partition_scheme_id = prs.data_space_id    AND dds.destination_id =prt.partition_number
LEFT JOIN NaumenDBReportArch.sys.data_spaces dts2 with(nolock) ON dts2.data_space_id = dds.data_space_id
LEFT JOIN (select 
			a.container_id, 
			SUM(a.total_pages) * 8 AS TotalSpaceKB,
			SUM(a.used_pages) * 8 AS UsedSpaceKB,
			(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
		FROM NaumenDBReportArch.sys.allocation_units a  with(nolock)
		group by a.container_id
	) a ON prt.partition_id =  a.container_id
where /* dts.name + ISNULL('-> ' + dts2.name, '') = 'PRIMARY'*/
	1=1
	--and prt.rows!=0
	--AND s.name  ='_lcrm'
	--and tbl.name like '%mv_call_case%'

	--and idx.type_desc = 'HEAP'
	--and dts.name + ISNULL('-> ' + dts2.name, '') !='PRIMARY'
)
select *
INTO #t_NaumenDBReportArch
FROM cte 
where 1=1
	AND dts_name NOT IN ('PRIMARY')
	AND schema_name NOT IN (N'tmp')
	AND tbl_name NOT LIKE '%_upd'
--and schema_name = '_lcrm'
--and tbl_name like '%lcrm_leads_full_csv_today_NEW%'
--and idx_type = 'CLUSTERED COLUMNSTORE'
--drop table dbo.call_params_new
--where TotalRows > 70000000
--and dts_name not like '%>%'
--and idx.type_desc ='CLUSTERED'
--and prt.rows 
--where tbl.object_id = object_id('fct_compensation')
--order by TotalRows desc, tbl_name, partition_number desc



DROP TABLE IF EXISTS #t_LcrmLeadArchive

;with cte as (
SELECT
	s.name as schema_name,
     tbl.name tbl_name,
      idx.type_desc idx_type,
      idx.name idx_name,
      dts.name + ISNULL('-> ' + dts2.name, '') dts_name,
      dts.type_desc + ISNULL('-> ' + dts2.type_desc, '') dts_type,
      prt.partition_number,
      prt.rows,
	  sum(prt.rows) over(partition by tbl.name , idx.type_desc, idx.name) as TotalRows,
      prv.value low_boundary,
	  
      prs.name part_scheme_name,
      pfs.name part_func_name
	  ,a.TotalSpaceKB / 1024 as TotalSpaceMB
	  ,a.UnusedSpaceKB / 1024 as UnusedSpaceMB
	  ,a.UsedSpaceKB / 1024 as UsedSpaceMB
FROM LcrmLeadArchive.sys.tables tbl with(nolock)
join LcrmLeadArchive.sys.schemas s with(nolock) on s.schema_id = tbl.schema_id
JOIN LcrmLeadArchive.sys.indexes idx with(nolock) ON idx.object_id = tbl.object_id
JOIN LcrmLeadArchive.sys.data_spaces dts with(nolock) ON dts.data_space_id = idx.data_space_id
JOIN LcrmLeadArchive.sys.partitions prt with(nolock) ON prt.object_id = tbl.object_id AND prt.index_id =idx.index_id
LEFT JOIN LcrmLeadArchive.sys.partition_schemes prs with(nolock) ON prs.data_space_id = dts.data_space_id
LEFT JOIN LcrmLeadArchive.sys.partition_functions pfs with(nolock) ON pfs.function_id = prs.function_id
LEFT JOIN LcrmLeadArchive.sys.partition_range_values prv with(nolock) ON
      prv.function_id = pfs.function_id AND prv.boundary_id =prt.partition_number - 1
LEFT JOIN LcrmLeadArchive.sys.destination_data_spaces dds with(nolock) ON
      dds.partition_scheme_id = prs.data_space_id    AND dds.destination_id =prt.partition_number
LEFT JOIN LcrmLeadArchive.sys.data_spaces dts2 with(nolock) ON dts2.data_space_id = dds.data_space_id
LEFT JOIN (select 
			a.container_id, 
			SUM(a.total_pages) * 8 AS TotalSpaceKB,
			SUM(a.used_pages) * 8 AS UsedSpaceKB,
			(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
		FROM LcrmLeadArchive.sys.allocation_units a  with(nolock)
		group by a.container_id
	) a ON prt.partition_id =  a.container_id
where /* dts.name + ISNULL('-> ' + dts2.name, '') = 'PRIMARY'*/
	1=1
	--and prt.rows!=0
	--AND s.name  ='_lcrm'
	--and tbl.name like '%mv_call_case%'

	--and idx.type_desc = 'HEAP'
	--and dts.name + ISNULL('-> ' + dts2.name, '') !='PRIMARY'
)
select *
INTO #t_LcrmLeadArchive
FROM cte 
where 1=1
	AND dts_name NOT IN ('PRIMARY')
	AND schema_name NOT IN (N'tmp')
	AND tbl_name NOT LIKE '%_upd'



--------------------------------------------
DROP TABLE IF EXISTS #t_tables

SELECT DISTINCT T.schema_name, T.tbl_name
INTO #t_tables
FROM #t_NaumenDBReportArch AS T
UNION
SELECT DISTINCT T.schema_name, T.tbl_name
FROM #t_LcrmLeadArchive AS T
--------------------------------------------


DROP TABLE IF EXISTS #t_Stg

;with cte as (
SELECT
	s.name as schema_name,
     tbl.name tbl_name,
      idx.type_desc idx_type,
      idx.name idx_name,
      dts.name + ISNULL('-> ' + dts2.name, '') dts_name,
      dts.type_desc + ISNULL('-> ' + dts2.type_desc, '') dts_type,
      prt.partition_number,
      prt.rows,
	  sum(prt.rows) over(partition by tbl.name , idx.type_desc, idx.name) as TotalRows,
      prv.value low_boundary,
	  
      prs.name part_scheme_name,
      pfs.name part_func_name
	  ,a.TotalSpaceKB / 1024 as TotalSpaceMB
	  ,a.UnusedSpaceKB / 1024 as UnusedSpaceMB
	  ,a.UsedSpaceKB / 1024 as UsedSpaceMB
FROM Stg.sys.tables tbl with(nolock)
join Stg.sys.schemas s with(nolock) on s.schema_id = tbl.schema_id
JOIN Stg.sys.indexes idx with(nolock) ON idx.object_id = tbl.object_id
JOIN Stg.sys.data_spaces dts with(nolock) ON dts.data_space_id = idx.data_space_id
JOIN Stg.sys.partitions prt with(nolock) ON prt.object_id = tbl.object_id AND prt.index_id =idx.index_id
LEFT JOIN Stg.sys.partition_schemes prs with(nolock) ON prs.data_space_id = dts.data_space_id
LEFT JOIN Stg.sys.partition_functions pfs with(nolock) ON pfs.function_id = prs.function_id
LEFT JOIN Stg.sys.partition_range_values prv with(nolock) ON
      prv.function_id = pfs.function_id AND prv.boundary_id =prt.partition_number - 1
LEFT JOIN Stg.sys.destination_data_spaces dds with(nolock) ON
      dds.partition_scheme_id = prs.data_space_id    AND dds.destination_id =prt.partition_number
LEFT JOIN Stg.sys.data_spaces dts2 with(nolock) ON dts2.data_space_id = dds.data_space_id
LEFT JOIN (select 
			a.container_id, 
			SUM(a.total_pages) * 8 AS TotalSpaceKB,
			SUM(a.used_pages) * 8 AS UsedSpaceKB,
			(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
		FROM Stg.sys.allocation_units a  with(nolock)
		group by a.container_id
	) a ON prt.partition_id =  a.container_id

INNER JOIN #t_tables AS T
	ON T.schema_name = s.name
	AND T.tbl_name = tbl.name

WHERE /* dts.name + ISNULL('-> ' + dts2.name, '') = 'PRIMARY'*/
	1=1
	--and prt.rows!=0
	--AND s.name  ='_lcrm'
	--and tbl.name like '%mv_call_case%'

	--and idx.type_desc = 'HEAP'
	--and dts.name + ISNULL('-> ' + dts2.name, '') !='PRIMARY'
)
select *
INTO #t_Stg
FROM cte 
where 1=1
	AND idx_type NOT IN ('NONCLUSTERED')



DROP TABLE IF EXISTS #t_NaumenDbReport

;with cte as (
SELECT
	s.name as schema_name,
     tbl.name tbl_name,
      idx.type_desc idx_type,
      idx.name idx_name,
      dts.name + ISNULL('-> ' + dts2.name, '') dts_name,
      dts.type_desc + ISNULL('-> ' + dts2.type_desc, '') dts_type,
      prt.partition_number,
      prt.rows,
	  sum(prt.rows) over(partition by tbl.name , idx.type_desc, idx.name) as TotalRows,
      prv.value low_boundary,
	  
      prs.name part_scheme_name,
      pfs.name part_func_name
	  ,a.TotalSpaceKB / 1024 as TotalSpaceMB
	  ,a.UnusedSpaceKB / 1024 as UnusedSpaceMB
	  ,a.UsedSpaceKB / 1024 as UsedSpaceMB
FROM NaumenDbReport.sys.tables tbl with(nolock)
join NaumenDbReport.sys.schemas s with(nolock) on s.schema_id = tbl.schema_id
JOIN NaumenDbReport.sys.indexes idx with(nolock) ON idx.object_id = tbl.object_id
JOIN NaumenDbReport.sys.data_spaces dts with(nolock) ON dts.data_space_id = idx.data_space_id
JOIN NaumenDbReport.sys.partitions prt with(nolock) ON prt.object_id = tbl.object_id AND prt.index_id =idx.index_id
LEFT JOIN NaumenDbReport.sys.partition_schemes prs with(nolock) ON prs.data_space_id = dts.data_space_id
LEFT JOIN NaumenDbReport.sys.partition_functions pfs with(nolock) ON pfs.function_id = prs.function_id
LEFT JOIN NaumenDbReport.sys.partition_range_values prv with(nolock) ON
      prv.function_id = pfs.function_id AND prv.boundary_id =prt.partition_number - 1
LEFT JOIN NaumenDbReport.sys.destination_data_spaces dds with(nolock) ON
      dds.partition_scheme_id = prs.data_space_id    AND dds.destination_id =prt.partition_number
LEFT JOIN NaumenDbReport.sys.data_spaces dts2 with(nolock) ON dts2.data_space_id = dds.data_space_id
LEFT JOIN (select 
			a.container_id, 
			SUM(a.total_pages) * 8 AS TotalSpaceKB,
			SUM(a.used_pages) * 8 AS UsedSpaceKB,
			(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
		FROM NaumenDbReport.sys.allocation_units a  with(nolock)
		group by a.container_id
	) a ON prt.partition_id =  a.container_id
INNER JOIN #t_tables AS T
	ON T.schema_name = s.name
	AND T.tbl_name = tbl.name
where /* dts.name + ISNULL('-> ' + dts2.name, '') = 'PRIMARY'*/
	1=1
	--and prt.rows!=0
	--AND s.name  ='_lcrm'
	--and tbl.name like '%mv_call_case%'

	--and idx.type_desc = 'HEAP'
	--and dts.name + ISNULL('-> ' + dts2.name, '') !='PRIMARY'
)
select *
INTO #t_NaumenDbReport
FROM cte 
where 1=1
	AND idx_type NOT IN ('NONCLUSTERED')





DROP TABLE IF EXISTS #t_archive_table_statistics


SELECT 
	T.schema_name,
	T.tbl_name,
	--T.idx_type,
	--T.idx_name,
	--T.dts_name,
	--T.dts_type,
	--T.partition_number,
	--month_year = isnull(T.low_boundary, '2000-01-01'),
	month_year = format(cast(isnull(T.low_boundary, '2000-01-01') AS date), 'yyyy-MM'),

	arc_db_name = 'LcrmLeadArchive',
	arc_db_rows = A.rows,
	arc_db_total_rows = A.TotalRows,

	main_db_name = 'Stg',
	main_db_rows = T.rows,
	main_db_total_rows = T.TotalRows
	--T.part_scheme_name,
	--T.part_func_name,
	--T.TotalSpaceMB,
	--T.UnusedSpaceMB,
	--T.UsedSpaceMB
INTO #t_archive_table_statistics
FROM #t_Stg AS T
	LEFT JOIN #t_LcrmLeadArchive AS A
		ON A.schema_name = T.schema_name
		AND A.tbl_name = T.tbl_name
		AND isnull(A.low_boundary, N'') = isnull(T.low_boundary, N'')
UNION

SELECT 
	T.schema_name,
	T.tbl_name,
	--T.idx_type,
	--T.idx_name,
	--T.dts_name,
	--T.dts_type,
	--T.partition_number,
	--month_year = isnull(T.low_boundary, '2000-01-01'),
	month_year = format(cast(isnull(T.low_boundary, '2000-01-01') AS date), 'yyyy-MM'),

	arc_db_name = 'NaumenDBReportArch',
	arc_db_rows = A.rows,
	arc_db_total_rows = A.TotalRows,

	main_db_name = 'Stg',
	main_db_rows = T.rows,
	main_db_total_rows = T.TotalRows
	--T.part_scheme_name,
	--T.part_func_name,
	--T.TotalSpaceMB,
	--T.UnusedSpaceMB,
	--T.UsedSpaceMB
FROM #t_NaumenDbReport AS T
	LEFT JOIN #t_NaumenDBReportArch AS A
		ON A.schema_name = T.schema_name
		AND A.tbl_name = T.tbl_name
		AND isnull(A.low_boundary, N'') = isnull(T.low_boundary, N'')


--test
--SELECT * FROM #t_tables AS T ORDER BY T.schema_name, T.tbl_name

--SELECT * FROM #t_NaumenDBReportArch AS T ORDER BY T.schema_name, T.tbl_name, T.low_boundary
--SELECT * FROM #t_NaumenDbReport AS T ORDER BY T.schema_name, T.tbl_name, T.low_boundary

--SELECT * FROM #t_LcrmLeadArchive AS T ORDER BY T.schema_name, T.tbl_name, T.low_boundary
--SELECT * FROM #t_Stg AS T ORDER BY T.schema_name, T.tbl_name, T.low_boundary
--//test

IF object_id('dbo.archive_table_statistics') IS NULL
BEGIN
	SELECT R.*
	INTO dbo.archive_table_statistics
	FROM #t_archive_table_statistics AS R
END

TRUNCATE TABLE dbo.archive_table_statistics

INSERT dbo.archive_table_statistics
SELECT R.* 
FROM #t_archive_table_statistics AS R
WHERE R.month_year <= format(getdate(), 'yyyy-MM')
ORDER BY R.schema_name, R.tbl_name, R.month_year



END


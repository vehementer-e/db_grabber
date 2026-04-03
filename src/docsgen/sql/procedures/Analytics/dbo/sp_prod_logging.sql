CREATE procedure sp_prod_logging
as


drop table if exists #prod_log
select *, getdate() created  into #prod_log from prod


drop table if exists #prod_log_insert

select *, getdate() created  into #prod_log_insert from (
select   a.[source]
, a.[db]
, a.[table_schema]
, a.[table_name]
, a.[column_name]
, a.[sample]
, a.[table_full_name]
, a.[table & column names]
, a.[is_crm]
, a.[is_mfo]
, a.[is_umfo]
, a.[is_cmr]
, a.[is_feodor]
, a.[is_integration]
, a.[is_collection]
--, a.[created]
from #prod_log a

except 

select   a.[source]
, a.[db]
, a.[table_schema]
, a.[table_name]
, a.[column_name]
, a.[sample]
, a.[table_full_name]
, a.[table & column names]
, a.[is_crm]
, a.[is_mfo]
, a.[is_umfo]
, a.[is_cmr]
, a.[is_feodor]
, a.[is_integration]
, a.[is_collection]
--, a.[created]
from prod_log a

)  x

insert into prod_log
select * from #prod_log_insert

if exists (select top 1 * from #prod_log_insert)
exec log_email 'new rows prod_log'



CREATE       PROC [dbo].[sp_find_definition_fast]
    @table NVARCHAR(MAX)
AS 




exec sp_create_table @table
if @@ROWCOUNT >0 return 



		select top 100 name2, sql, created, updated, row_created from  analytics.dbo.objects_history_view  with(nolock) where name2  like '%' + @table + '%'
		order by name2, row_created desc
		-- and type in ('p', 'v')
		select * from  analytics.dbo.dwh_objects_analytics  with(nolock) where name like '%' + @table + '%' and type in ('p', 'v')                  union all
		select * from  analytics.dbo.dwh_objects_reports    with(nolock) where name like '%' + @table + '%' and type in ('p', 'v')					union all
		select * from  analytics.dbo.dwh_objects_feodor     with(nolock) where name like '%' + @table + '%' and type in ('p', 'v')					union all
		select * from  analytics.dbo.dwh_objects_stg        with(nolock) where name like '%' + @table + '%' and type in ('p', 'v')					union all
		select * from  analytics.dbo.[dwh_objects_naumendbreport]        with(nolock) where name like '%' + @table + '%'  and type in ('p', 'v')	--union all


 
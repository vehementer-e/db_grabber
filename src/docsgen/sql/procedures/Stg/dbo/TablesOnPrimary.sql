
CREATE   procedure [dbo].[TablesOnPrimary]
as
begin
	drop table if exists #t_TablesOnPrimary

	select  ROW_NUMBER() over(order by s.name ASC) as RowNumber
		,t.name as TableName
		,i.type_desc as TableType
		,s.name as SchemaName 
		,p.RowsCount
	into #t_TablesOnPrimary
	from sys.tables t
	join sys.indexes i ON  t.object_id=i.object_id
	join sys.schemas s ON s.schema_id=t.schema_id
	JOIN sys.data_spaces ds ON i.data_space_id = ds.data_space_id
	join (select distinct object_id, max(rows) over (partition by object_id) as rowscount from sys.partitions group by object_id,rows) p ON p.object_id = t.object_id
	where ds.name = 'PRIMARY'
		and s.name NOT IN ('tmp', 'files')
	order by s.name

			DECLARE @tableHTML NVARCHAR(MAX) ;
			SET @tableHTML =

			N'<H1>Таблицы в Stg PRIMARY на c2-vsr-dwh2</H1>' +
			N'<table border="1">' +
			N'<tr><th>RowNumber</th><th>TableName</th><th>TableType</th><th>SchemaName</th><th>RowsCount</th></tr>' +
			CAST ( ( SELECT td = RowNumber           
			,               ''                                      
			,               td = TableName                     
			,               ''                                      
			,               td = TableType   
			,               ''                                      
			,               td = SchemaName 
			,               ''   
			,               td = RowsCount 

			from #t_TablesOnPrimary
			FOR XML PATH('tr'), TYPE
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;

				  EXEC msdb.dbo.sp_send_dbmail @recipients   = 'dwh112@carmoney.ru'
				  ,                             @profile_name = 'Default'
				  ,                            @subject      = 'Таблицы в Stg PRIMARY на c2-vsr-dwh2'
				  ,                            @body         = @tableHTML
				  ,                            @body_format  = 'HTML';
end

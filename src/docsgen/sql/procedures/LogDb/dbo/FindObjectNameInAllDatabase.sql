--exec logdb.dbo.FindObjectNameInAllDatabase 'backup'
--exec logdb.dbo.FindObjectNameInAllDatabase 'удал'
CREATE PROCEDURE [dbo].[FindObjectNameInAllDatabase]
@TableName NVARCHAR(256) = 'удал'
AS
DECLARE @DBName NVARCHAR(256)
DECLARE @varSQL NVARCHAR(512)
DECLARE @getDBName CURSOR

SET @getDBName = CURSOR FOR
SELECT name
FROM sys.databases

CREATE TABLE #TmpTable (DBName NVARCHAR(256),
SchemaName NVARCHAR(256),
TableName NVARCHAR(256),
TypeName NVARCHAR(256),
sql_text NVARCHAR(max) null) 

OPEN @getDBName

FETCH NEXT
FROM @getDBName INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
	
	If (@DBName not in ('tempdb','master','model','msdb'))
	begin

		SET @varSQL = 'USE ' + @DBName + ';
		INSERT INTO #TmpTable
		SELECT '''+ @DBName + ''' AS DBName,
		SCHEMA_NAME(schema_id) AS SchemaName,
		name AS TableName,
		o.type_desc TypeName,
		null as sql_text
		FROM sys.objects o
		WHERE name LIKE ''%' + @TableName + '%'''
	
		EXEC (@varSQL)

	end

	FETCH NEXT
	FROM @getDBName INTO @DBName

END

CLOSE @getDBName
DEALLOCATE @getDBName

update #TmpTable
set sql_text = 'USE ' + DBName + '; '+ char(10) + char(13) +' GO' + char(10) + char(13) 
               + case  TypeName
			       when	'USER_TABLE' then  'drop table if exists [' + SchemaName + '].[' +TableName + ']'
				   when	'SQL_STORED_PROCEDURE' then  'drop procedure if exists [' + SchemaName + '].[' +TableName + ']'
				   when	'VIEW' then  'drop view if exists [' + SchemaName + '].[' +TableName + ']'
				end


SELECT *
FROM #TmpTable
order by dbname, TypeName,SchemaName, TableName


declare @tableHTML nvarchar(max)

  SET @tableHTML =  
    N'<H1>Объекты со словом ['+ @TableName +'] в названии </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>dbname</th>' +  
	N'<th>TypeName</th>' + 
	N'<th>SchemaName</th>' + 
	N'<th>TableName</th>' + 
    N'<th>sql_text</th></tr>' +  
   
    CAST ( ( SELECT 
                    td = dbname, '',  
					td = TypeName, '', 
					td = SchemaName, '', 
					td = TableName, '', 
                    td = sql_text 
              from #TmpTable

order by dbname, TypeName,SchemaName, TableName
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  


  select @tableHTML

  declare @sbj nvarchar(255) = 'Объекты со словом ['+ @TableName +'] в названии   '


EXEC msdb.dbo.sp_send_dbmail @recipients='dwh112@techmoney.ru',
    @subject = @sbj,  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  

DROP TABLE #TmpTable

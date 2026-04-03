
/*
drop table if exists #mySourceTable
create table #mySourceTable(
    id int identity(1,1), 
    aValue nvarchar(200), 
    bValue nvarchar(10),
    common_col1 nvarchar(100),
    common_col2 nvarchar(100),
    source_specific_col nvarchar(50)  -- Поле, которого нет в myTargetTable
)

insert into #mySourceTable (aValue, bValue, common_col1, common_col2, source_specific_col)
values
    ('Value S1', 'B1', 'Common1_S1', 'Common2_S1', 'SourceSpecific_1'),
    ('Value S2', 'B2', 'Common1_S2', 'Common2_S2', 'SourceSpecific_2'),
    ('Value S3', 'B3', 'Common1_S3', 'Common2_S3', 'SourceSpecific_3'),
    ('Duplicate A1', 'B1', 'Common1_Dup1', 'Common2_Dup1', 'SourceSpecific_Dup1'),
    ('Duplicate A2', 'B2', 'Common1_Dup2', 'Common2_Dup2', 'SourceSpecific_Dup2'),
    ('Duplicate A3', 'B3', 'Common1_Dup3', 'Common2_Dup3', 'SourceSpecific_Dup3')

declare @SQLQuery NVARCHAR(3000) = 'select * from #mySourceTable',
	@title nvarchar(255) ='Тест Title',
	@subject nvarchar(255) = 'Тест subject',
	@isDebug bit = 0,
	@html_result NVARCHAR(max)
exec dbo.ConvertQuery2HTMLTable  
	@SQLQuery = @SQLQuery
	,@title = @title
	,@subject = @subject
	,@isDebug = @isDebug
	,@html_result = @html_result out
select @html_result
*/

CREATE   procedure [dbo].[ConvertQuery2HTMLTable] 
	@SQLQuery NVARCHAR(3000) ,
	@title nvarchar(255) ,
	@tableSubject nvarchar(255) ,
	@isDebug bit = 0,
	@html_result NVARCHAR(max) = '' out
as
begin
begin try
	set @html_result = isnull(@html_result,'')
	if isnull(len(@SQLQuery),0) = 0 
	begin
		;throw 51000, 'строка запроса строка не задана', 16
	end
	if isnull(len(@title),0)	= 0 
	begin
		;throw 51000, 'Значение для title не задано', 16
	end
	if isnull(len(@tableSubject),0)	= 0
	begin
		;throw 51000, 'Значение для subject не задано', 16
	end
	
	DECLARE @restOfQuery NVARCHAR (2000) = ''
		,@DynTSQL NVARCHAR (3000)
		,@FROMPOS INT
		
		,@DynTSQLResult NVARCHAR(max)
		,@queryColumnsList NVARCHAR (1024)
		,@thColumnsList NVARCHAR (1024)
		,@tdColumnsList NVARCHAR (1024)
	select @queryColumnsList = STRING_AGG(concat('ISNULL','(', NAME, ',', QUOTENAME(' ', ''''), ')'), ',')
		 ,@thColumnsList =  STRING_AGG(NAME, ',')
		 
	FROM sys.dm_exec_describe_first_result_set(@SQLQuery, NULL, 0)
	
	if isnull(len(@thColumnsList),0)=0
	begin
		;throw 51000, 'список полей запрос не определен', 16
	end

    SET @FROMPOS = CHARINDEX ('FROM', @SQLQuery, 1)
    SET @restOfQuery = SUBSTRING(@SQLQuery, @FROMPOS, LEN(@SQLQuery) - @FROMPOS + 1)
    set  @tdColumnsList = Replace (@queryColumnsList, '),', ') as TD,')
    SET @tdColumnsList += ' as TD'
    SET @DynTSQL = CONCAT (
        'SET @tempResult = (SELECT (SELECT '
        , @tdColumnsList
        ,' '
        , @restOfQuery
        ,' FOR XML RAW (''TR''), ELEMENTS, TYPE) AS ''TBODY'''
        ,' FOR XML PATH (''''))'
    )
	
    EXEC sp_executesql @DynTSQL, N'@tempResult NVARCHAR(MAX) out', @DynTSQLResult out
	
    select @html_result = CONCAT_WS(' '
        ,'<!DOCTYPE html>'
        ,'<html lang="ru">'
        ,'<head>'
        ,'<meta charset="UTF-8">'
        ,'<meta name="viewport" content="width=device-width, initial-scale=1.0">'
        ,'<title>',@title, '</title>'
        ,'<style>'
        ,'table { border-collapse: collapse; width: 100%; }'
        ,'table, th, td { border: 1px solid black; }'
        ,'th, td { padding: 10px; text-align: left; }'
        ,'h2 { color: #333; }'
        ,'</style>'
        ,'</head>'
        ,'<body>'
        ,'<h2>', @tableSubject, '</h2>'
        ,    '<table cellspacing="0" border="1.2" cellpadding="5">'
        ,'<tr>'
        ,(SELECT STRING_AGG(CONCAT('<th>', value, '</th>'), '')
          FROM STRING_SPLIT(@thColumnsList, ','))
        ,'</tr>'
        ,@DynTSQLResult
        ,'</table>'
        ,'</body>'
        ,'</html>'
    )
	if  @isDebug = 1
	begin
		select @DynTSQLResult as DynTSQLResult
		select @thColumnsList as thColumnsList
		select @DynTSQL as DynTSQL
	end
	

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end

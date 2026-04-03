CREATE PROC [dbo].[spQueryToCsv] 
(
  @query nvarchar(MAX), --A query to turn into CSV format. It should not include an ORDER BY clause.
  @orderBy nvarchar(MAX) = NULL, --An optional ORDER BY clause. It should contain the words 'ORDER BY'.
  @csv nvarchar(MAX) = NULL OUTPUT --The CSV output of the procedure.
)
AS
BEGIN   
  SET NOCOUNT ON;

  IF @orderBy IS NULL BEGIN
    SET @orderBy = '';
  END

  SET @orderBy = REPLACE(@orderBy, '''', '''''');  

  DECLARE @realQuery nvarchar(MAX) = '
    DECLARE @headerRow nvarchar(MAX);
    DECLARE @cols nvarchar(MAX);

    SELECT * INTO #dynSql FROM (' + @query + ') sub;    

    SELECT @cols = ISNULL(@cols + '' + '''','''' + '', '''') + ''''''"'''' + ISNULL(REPLACE(CAST(['' + name + ''] AS nvarchar(max)), ''''"'''', ''''""''''), '''''''') + ''''"''''''
    FROM tempdb.sys.columns 
    WHERE object_id = object_id(''tempdb..#dynSql'')
    ORDER BY column_id;        

    SET @cols = ''
      SET @csv = (SELECT '' + @cols + '' FROM #dynSql ' + @orderBy + ' FOR XML PATH(''''m_m''''));
      ''
    EXEC sys.sp_executesql @cols, N''@csv nvarchar(MAX) OUTPUT'', @csv=@csv OUTPUT    

    SELECT @headerRow = ISNULL(@headerRow + '','', '''') + ''"'' + REPLACE(name, ''"'', ''""'') + ''"''
    FROM tempdb.sys.columns 
    WHERE object_id = object_id(''tempdb..#dynSql'')
    ORDER BY column_id;

    SET @headerRow = @headerRow + CHAR(13) + CHAR(10);

    SET @csv = @headerRow + @csv;    
    ';

  EXEC sys.sp_executesql @realQuery, N'@csv nvarchar(MAX) OUTPUT', @csv=@csv OUTPUT
  SET @csv = REPLACE(REPLACE(@csv, '<m_m>', ''), '</m_m>', CHAR(13) + CHAR(10))
END


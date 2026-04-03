
CREATE PROC [dbo].[CheckTablesSize]
	@db_name_list varchar(2048) = NULL,
	@except_db_name_list varchar(2048) = 'devDB,master,model,msdb,tempdb'
as
SET NOCOUNT ON
DECLARE @qry nvarchar(max)
DECLARE @DBname nvarchar(100)
DECLARE @FullTableName nvarchar(1000)
DECLARE @TableName nvarchar(1000), @SchemaName nvarchar(100)
DECLARE @t_db_name table(dbname varchar(255))
DECLARE @t_except_db_name_list table(dbname varchar(255))
declare @error nvarchar(1024)

drop table if exists #t_size
CREATE TABLE #t_size (
			name varchar(100)
			,rows varchar(100)
			,reserved varchar(50)
			,data varchar(50)
			,index_size varchar(50)
			,unused varchar(50)
			)
drop table if exists #t_sizeofalltables
select top(0) 
	[DBname]
	, [TableName]
	, [SchemaName]
	, [RowCounts]
	, [TotalSpaceKB]
	, [UsedSpaceKB]
	, [UnusedSpaceKB]
	, [InsertDate]
	, [IndexSize]
	, [error]
	, [id]

into #t_sizeofalltables from LogDB.dbo.SizeOfAllTables
drop table if exists #t_tables
 SELECT top (0) DBname = DB_name(), TABLE_SCHEMA ,  TABLE_NAME 
	 into #t_tables FROM INFORMATION_SCHEMA.TABLES


INSERT @t_db_name(dbname)
SELECT trim(S.value )
FROM string_split(@db_name_list,',') AS S

IF nullif(@db_name_list,'') IS NULL BEGIN
	INSERT @t_db_name(dbname)
	
	SELECT D.name FROM sys.databases AS D
	where state_desc = 'ONLINE'
END

INSERT @t_except_db_name_list(dbname)
SELECT trim(S.value )
FROM string_split(@except_db_name_list,',') AS S



DECLARE  Cur_DBnames CURSOR FOR
select name = D.dbname
from @t_db_name AS D
where 1=1
	AND D.dbname NOT IN (SELECT dbname FROM @t_except_db_name_list)
ORDER BY name
--select 
--	  name 
--from sys.databases 
--where name NOT IN ('devDB','master', 'model', 'msdb', 'tempdb')

OPEN Cur_DBnames
FETCH NEXT FROM Cur_DBnames INTO @DBname
WHILE @@FETCH_STATUS = 0
begin

	 TRUNCATE TABLE #t_tables
	 DECLARE @cmd nvarchar(1024) = 'USE ['+@Dbname+'];
	 SELECT DBname = DB_name(), TABLE_SCHEMA ,  TABLE_NAME 
	 FROM INFORMATION_SCHEMA.TABLES
	 WHERE TABLE_SCHEMA not in (''tmp'')'
	 INSERT INTO #t_tables 
	 
	 exec(@cmd)
	DECLARE Cur_SpaceUsed CURSOR FOR
	select CONCAT('[',TABLE_SCHEMA,'].[',TABLE_NAME,']') as FullTableName, TABLE_SCHEMA, TABLE_NAME FROM #t_tables
	OPEN Cur_SpaceUsed
	FETCH NEXT FROM Cur_SpaceUsed INTO @FullTableName, @SchemaName, @TableName
	WHILE @@FETCH_STATUS = 0
	begin
			TRUNCATE TABLE #t_size

			--SET @qry = 'USE ['+@dbname+'];
			--exec sp_spaceused '''+@FullTableName+''''
			SET @qry = 'USE ['+@dbname+'];
			exec sp_spaceused ''' + replace(@FullTableName, '''', '''''') + ''''

			SELECT @error = NULL

			begin try 
			 INSERT INTO #t_size
			exec(@qry) 
			end try
			begin catch
				print @qry
				set @error =  ERROR_MESSAGE ()
				print @error 
			end catch
			insert into #t_sizeofalltables (id, [DBname], [TableName], [SchemaName], [RowCounts], [TotalSpaceKB], [UsedSpaceKB], [UnusedSpaceKB], [InsertDate], [IndexSize], error)
			SELECT newid() as id
			
			,p.DBname 
			,p.TableName
			,p.SchemaName 
			,RowCounts = isnull(s.rows,0) 
			,TotalSpaceKB =  isnull(TRY_CAST(TRIM(' KB' from s.reserved) as bigint),0)
			,UsedSpaceKB = isnull(TRY_CAST(TRIM(' KB' from s.data) as bigint),0) 
			,UnusedSpaceKB = isnull(TRY_CAST(TRIM(' KB' from s.unused) as bigint),0)
			,InsertDate = getdate()	
			,IndexSize = isnull(TRY_CAST(TRIM(' KB' from s.index_size) as bigint),0)
			,error = @error
			FROM (
			values (@DBname, @TableName, @SchemaName ) 
				)p (DBname, TableName, SchemaName)
			left join #t_size s on 1=1

			FETCH NEXT FROM Cur_SpaceUsed INTO @FullTableName, @SchemaName, @TableName
	end
	CLOSE Cur_SpaceUsed
	DEALLOCATE Cur_SpaceUsed

FETCH NEXT FROM Cur_DBnames INTO @DBname

 end

 CLOSE Cur_DBnames
 DEALLOCATE Cur_DBnames

 insert into dbo.SizeOfAllTables (id, [DBname], [TableName], [SchemaName], [RowCounts], [TotalSpaceKB], [UsedSpaceKB], [UnusedSpaceKB], [InsertDate], [IndexSize], error)
 select id , [DBname], [TableName], [SchemaName], [RowCounts], [TotalSpaceKB], [UsedSpaceKB], [UnusedSpaceKB], [InsertDate], [IndexSize], error from #t_sizeofalltables s
 where not exists(select top(1) 1 from LogDB.dbo.SizeOfAllTables t where s.DBname = t.DBname
	and s.TableName = t.TableName
	and s.SchemaName = t.SchemaName
	and cast(s.InsertDate as date) = cast(t.InsertDate as date)
	)
 



-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[ShrinkDataFiles] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE     procedure [dbo].[ShrinkDataFiles]
as
begin
	insert into ShrinkFilesInfo
				(
					DBname		
					,q			
					,FileType	
					,DBFileName 
					,Size		
					,FreeSpace	
					,percents	
				)
	select  top (5) 
		db.name as DBname
		, 'USE [' + db.name + N']' 
		+ 'DBCC SHRINKFILE (N''' + mf.name + N''' , ' + cast(FLOOR(dfs.Size*0.97) as nvarchar(100))  + ')' q 
		,mf.type_desc as FileType
		,dfs.name as DBFileName
		,dfs.Size 
		,dfs.FreeSpace
		,cast(dfs.freespace as money)/cast(dfs.Size as money)as percents	
	from sys.master_files mf
	join sys.databases db on db.database_id = mf.database_id
	join (
			SELECT 
				(Size - SpaceUsed)/128 as freespace
				, Size/128 as Size
				,t.name
			FROM (SELECT 	 
						SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT))  as SpaceUsed
						,SUM(size) as Size
						,name
					from sys.database_files
					WHERE type_desc = 'ROWS'
					group by name
					) t
			) dfs on dfs.name = mf.name
	where mf.type_desc = 'ROWS' and 
	db.name NOT IN('master','tempdb','model','msdb')
	and dfs.size> 3072
	and cast(dfs.freespace as money)/cast(dfs.Size as money) > 0.2
	order by freespace desc






/*
select * from ShrinkFilesInfo

		Create table dbo.ShrinkFilesInfo
				(
					DBname		nvarchar(50)
					,q			nvarchar(255)
					,FileType	nvarchar(10)
					,DBFileName nvarchar(100)
					,Size		int
					,FreeSpace	int
					,percents	money
				)
*/
end

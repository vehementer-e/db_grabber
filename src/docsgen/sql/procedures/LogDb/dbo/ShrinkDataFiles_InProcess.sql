



CREATE        procedure [dbo].[ShrinkDataFiles_InProcess]
as
begin



DECLARE @DBname nvarchar(100) 
		,@Qry	nvarchar(4000)
		,@q		nvarchar(255) =   '''USE [''' + '+ db.name +' + 'N'']''' + ' + '+ '''DBCC SHRINKFILE (N''''''' + '+ mf.name +' + 'N'''''' , ''' + ' + cast(FLOOR(dfs.Size*0.77) as nvarchar(100)) + '  + ''')'''
		
DECLARE ShrinkFilesList CURSOR FOR

 select name from sys.databases
where name not in ('master','tempdb','model','msdb', 'SSISDB')
and is_read_only = 0
and state_desc = 'ONLINE'

OPEN ShrinkFilesList
FETCH NEXT FROM ShrinkFilesList INTO @DBname
WHILE @@FETCH_STATUS = 0
	begin
			SET @Qry = 'USE [' + @DBname + '] 
			insert into LogDb.dbo.Shrink_Data_Files_InProcess
						(
							[DBname]
							, [q]
							, [FileType]
							, [DBFileName]
							, [Size]
							, [FreeSpace]
						)
			select  
				db.name			 as DBname
				, '+@q+'		 as q
				,mf.type_desc	 as FileType
				,dfs.name		 as DBFileName
				,dfs.Size		 as Size
				,dfs.FreeSpace   as FreeSpace
			from sys.master_files mf
			join sys.databases db on db.database_id = mf.database_id
			join (
					SELECT 
						(Size - SpaceUsed)/128 as freespace
						, Size/128 as Size
						,t.name
					FROM (SELECT 	 
								SUM(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))  as SpaceUsed
								,SUM(size) as Size
								,name
							from sys.database_files
							WHERE type_desc = ''ROWS''
							group by name
							) t
					) dfs on dfs.name = mf.name
			where mf.type_desc = ''ROWS'' 
			and db.name = ''' +@DBname+ '''
			and dfs.size> 3072
			and cast(dfs.freespace as money)/cast(dfs.Size as money) > 0.2
			order by freespace desc'

			exec (@Qry)
			FETCH NEXT FROM ShrinkFilesList INTO @DBname
	end
CLOSE ShrinkFilesList
DEALLOCATE ShrinkFilesList

end

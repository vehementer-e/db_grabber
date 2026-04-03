

CREATE PROCEDURE [dbo].[Fill_SizeOfDBFiles] 
as
INSERT  INTO [LogDB].[dbo].[SizeOfDBFiles] ([DBname], [file_name], [file_type], [size_kb], [InsertDate])
select   db.name as DBname
				,file_name = mf.name  
				,file_type = type_desc
				,size_kb = CAST(SUM(size) * 8. / 1024 AS DECIMAL(18,2))
				,InsertDate = getdate()
			from sys.master_files mf WITH(NOWAIT)
			join sys.databases db ON db.database_id = mf.database_id 
			where db.name NOT IN ('devDB','master', 'model', 'msdb', 'tempdb')
		group by  db.name, mf.name, type_desc



-- Usage: запуск процедуры с параметрами
-- EXEC etl.set_isLoaded_Need2LoadFiles @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create procedure etl.set_isLoaded_Need2LoadFiles
as
begin try
	update t
		set isLoaded = 1
			,isNeed2Load = 0
			,[LoadDate] = getdate()
	from etl.Need2LoadFileFromFS t  with(index = ix_isLoaded)
	where [isLoaded] = 0
		and exists(select top(1) 1 from _fileservice.Files  f where f._id = t.lk_file_mongo_guid)
			
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch

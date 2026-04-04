
-- Usage: запуск процедуры с параметрами
-- EXEC etl.set_deactived_Need2LoadFiles;
-- Параметры соответствуют объявлению процедуры ниже.
create   procedure etl.set_deactived_Need2LoadFiles
as
begin
begin try
	update t
		set isNeed2Load = 0
	from etl.Need2LoadFileFromFS t  with(index = ix_isNeed2Load)
	where exists(select top(1) 1 from etl.Need2LoadFileFromFS_stage s
		where s.lk_file_mongo_guid = t.lk_file_mongo_guid)
		and isNeed2Load = 1
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end

-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[fill_Need2LoadFileFromFS_stage] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [etl].[fill_Need2LoadFileFromFS_stage]
as
begin try
begin tran
	truncate table etl.Need2LoadFileFromFS_stage
	insert into etl.Need2LoadFileFromFS_stage(
		[lk_file_mongo_guid]
	)
	select top(100)
		lk_file_mongo_guid
	from (
		select lk_file_mongo_created_at
			, lk_file_mongo_guid
			, 0 priority
			,lk_file_bind
		from etl.Need2LoadFileFromFS s with(index = [ix_isNeed2Load])
		where isNeed2Load = 1
		and (exists(select top(1) 1 from  reports.collection.dm_SuspicionFraud t
			where t.НомерДоговора = s.lk_1c_num)
			or s.lk_file_bind in ('foto_pts')
			)
		union
		select lk_file_mongo_created_at
			, lk_file_mongo_guid
			, 1 priority
			, lk_file_bind
		from etl.Need2LoadFileFromFS s with(index = [ix_isNeed2Load])
		where isNeed2Load = 1
		and not exists(select top(1) 1 from  reports.collection.dm_SuspicionFraud t
			where t.НомерДоговора = s.lk_1c_num)
	) t
	order by priority, lk_file_mongo_created_at
commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch

--create index ix_isNeed2Load on etl.Need2LoadFileFromFS(isNeed2Load) include (lk_file_mongo_created_at, lk_file_id) 
--where isNeed2Load = 1

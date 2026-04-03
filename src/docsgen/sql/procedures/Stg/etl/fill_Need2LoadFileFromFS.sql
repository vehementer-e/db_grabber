
-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[fill_Need2LoadFileFromFS];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   procedure [etl].[fill_Need2LoadFileFromFS]
as
begin
begin try
	
	--alter table [etl].[Need2LoadFileFromFS]
	--	add file_bind nvarchar(255)
	declare @dtLastFile datetime =isnull((select max(lk_file_mongo_created_at) from etl.Need2LoadFileFromFS), '2000-01-01')

	drop table if exists #t
select [lk_requests_guid] = cast(try_cast(r.guid as uniqueidentifier) as nvarchar(36))
	,lk_1c_num = r.num_1c
	,lk_file_mongo_guid = cast(try_cast(fs.guid as uniqueidentifier) as nvarchar(36))
	,lk_file_id = fs.file_id
	,lk_file_mongo_created_at = fs.created_at
	,lk_file_bind = rf.file_bind
	into #t
from _lk.requests r 
inner join _lk.request_file rf on rf.request_id  = r.id 
	and (charindex('foto_client', rf.file_bind)>0 
		or  charindex('foto_pts', rf.file_bind)>0 
		)
INNER  join _lk.file_storage fs on fs.file_id = rf.file_id
where fs.created_at>=dateadd(hh,-1, @dtLastFile)
and not exists(select top(1) 1 from etl.Need2LoadFileFromFS t
	where t.lk_file_mongo_guid =  fs.guid)
	begin tran
		insert into [etl].[Need2LoadFileFromFS](
			[lk_file_mongo_guid]
			, lk_file_mongo_created_at
			, [isNeed2Load]
			, [Need2LoadDate]
			, [lk_requests_guid]
			, [lk_1c_num]
			, [lk_file_id]
			, lk_file_bind
		)
		select distinct 
			[lk_file_mongo_guid]
			, lk_file_mongo_created_at
			, [isNeed2Load] = 1
			, [Need2LoadDate] = getdate()
			, [lk_requests_guid]
			, [lk_1c_num]
			, [lk_file_id]
			,lk_file_bind
		from #t

	commit tran


end try
begin catch
	if @@TRANCOUNT >0 
		rollback tran
	;throw	
end catch
end
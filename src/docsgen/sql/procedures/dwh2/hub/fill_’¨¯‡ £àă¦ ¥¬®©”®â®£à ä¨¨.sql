--exec hub.fill_ТипЗагружаемойФотографии
--exec hub.fill_ТипЗагружаемойФотографии @mode = 0
create   PROC hub.fill_ТипЗагружаемойФотографии
	@mode int = 1
as
begin
	--truncate table hub.ТипЗагружаемойФотографии
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @request_file_updated_at datetime = '2000-01-01'

	drop table if exists #t_ТипЗагружаемойФотографии

	if OBJECT_ID ('hub.ТипЗагружаемойФотографии') is not NULL
		AND @mode = 1
	begin
		select @request_file_updated_at = isnull(
				(
					select dateadd(day, -10, max(s.request_file_updated_at))
					from hub.ТипЗагружаемойФотографии as s
				), 
				'2020-01-01'
			)
	end


	select distinct 
		GuidТипЗагружаемойФотографии = 
			try_cast(
				hashbytes('SHA2_256', t.file_bind)
				as uniqueidentifier
			)
		,t.file_bind
		,file_bind_name = cast(null as nvarchar(255))
		,request_file_updated_at = cast(t.max_updated_at as datetime2(0))
		,created_at	= CURRENT_TIMESTAMP
		,updated_at	= CURRENT_TIMESTAMP
		,spFillName	= @spName
	into #t_ТипЗагружаемойФотографии
	from (
		select 
			rf.file_bind,
			max_updated_at = max(rf.updated_at)
		from Stg._LK.request_file as rf
		where 1=1
			and rf.updated_at > @request_file_updated_at
			and charindex('foto_', rf.file_bind) > 0
		group by rf.file_bind
		union
		select 
			rf.file_bind,
			max_updated_at = max(rf.updated_at)
		from Stg._LK.request_file as rf
		where 1=1
			and rf.updated_at > @request_file_updated_at
			and charindex('pass', rf.file_bind) > 0
		group by rf.file_bind
	) as t


	drop table if exists #t_file_bind_name

	select t.file_bind, t.file_bind_name
	into #t_file_bind_name
	from (
		VALUES 
		('foto_act_pts', 'фото ПТС'), -- дубль названия foto_pts
		('foto_auto', 'фото авто'),
		('foto_client', 'фото клиента'),
		('foto_extra', 'фото кредитной карты'),
		('foto_finance_state', 'фото справки о доходах'),
		('foto_income', 'фото справки клиента'),
		('foto_notification', 'фото кредитной карты'), --дубль названия foto_extra
		('foto_passport', 'фото паспорта'),
		('foto_passport_approved', ''), -- ! нет названия
		('foto_pts', 'фото ПТС'),
		('foto_pts_approved', ''), -- ! нет названия
		('foto_sts', 'фото СТС'),
		('foto_sts_approved', ''), -- ! нет названия
		('pass14_15', 'фото Паспорта стр. 14-15'),
		('pass2_3', 'фото Паспорта стр. 2-3'),
		('pass4_5', 'фото Паспорта стр. 4-5'),
		('passActuallyRegistration', 'фото Паспорта стр. с пропиской с последней печатью')
	) as t (file_bind, file_bind_name)

	update t 
	set file_bind_name = b.file_bind_name
	from #t_ТипЗагружаемойФотографии as t
		inner join #t_file_bind_name as b
			on b.file_bind = t.file_bind


	if OBJECT_ID('hub.ТипЗагружаемойФотографии') is null
	begin
		select top(0)
			GuidТипЗагружаемойФотографии,
			file_bind,
			file_bind_name,
			request_file_updated_at,
			created_at,
			updated_at,
			spFillName
		into hub.ТипЗагружаемойФотографии
		from #t_ТипЗагружаемойФотографии

		alter table hub.ТипЗагружаемойФотографии
			alter column GuidТипЗагружаемойФотографии uniqueidentifier not null

		ALTER TABLE hub.ТипЗагружаемойФотографии
			ADD CONSTRAINT PK_ТипЗагружаемойФотографии PRIMARY KEY CLUSTERED (GuidТипЗагружаемойФотографии)
	end
	
	begin tran
		if @mode = 0 begin
			delete t
			from hub.ТипЗагружаемойФотографии t
		end

		merge hub.ТипЗагружаемойФотографии t
		using #t_ТипЗагружаемойФотографии s
			on t.GuidТипЗагружаемойФотографии = s.GuidТипЗагружаемойФотографии
		when not matched then insert
		(
			GuidТипЗагружаемойФотографии,
			file_bind,
			file_bind_name,
			request_file_updated_at,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidТипЗагружаемойФотографии,
			s.file_bind,
			s.file_bind_name,
			s.request_file_updated_at,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
			t.request_file_updated_at <> s.request_file_updated_at
			or isnull(t.file_bind_name, '***') <> isnull(s.file_bind_name, '***')
			OR @mode = 0
		)
		then update SET
			--t.GuidТипЗагружаемойФотографии = s.GuidТипЗагружаемойФотографии,
			t.file_bind_name = s.file_bind_name,
			t.request_file_updated_at = s.request_file_updated_at,
			--t.created_at = s.created_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			;
	commit tran

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

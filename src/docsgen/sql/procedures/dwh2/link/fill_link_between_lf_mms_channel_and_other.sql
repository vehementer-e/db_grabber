--
/*
exec link.fill_link_between_lf_mms_channel_and_other

*/
--
CREATE   PROC link.fill_link_between_lf_mms_channel_and_other
	 @LinkName nvarchar(255)
as
begin
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @tableName nvarchar(255) = @LinkName
	declare @msg_error nvarchar(255)
	if OBJECT_ID(@tableName) is null
	begin
		set @msg_error = concat('таблица ', @tableName, ' не найдена')
		;throw 51000, @msg_error, 16
	end

	drop table if exists #t_2Insert
	select top(0)
		Id					
		,guid_mms_channel
		,updated_at_time
		,LinkGuid
		,TargetColName
		,created_at
	into #t_2Insert
	from link.lf_mms_channel_stage

	insert into #t_2Insert
	(
		Id
		,guid_mms_channel
		,updated_at_time
		,LinkGuid
		,TargetColName
		,created_at
	)
	select 
		Id
		,guid_mms_channel
		,updated_at_time
		,LinkGuid
		,TargetColName
		,created_at
	from link.lf_mms_channel_stage
	where LinkName = @LinkName
	
	
	if exists(Select top(1) 1 from #t_2Insert)
	begin
		declare @TargetColName nvarchar(255) =( select top(1) trim(TargetColName) from #t_2Insert)
		if nullif(@TargetColName,'') is null
		begin
			set @msg_error = 'Название колонки для связи не определено'
			;throw 51000, @msg_error, 16
		end
		declare @cmd_merge nvarchar(max) =
			concat('merge ', @tableName, ' t '
			,char(10) + char(13)
			,' using (
			select 
				guid_mms_channel,
				LinkGuid
			from (
					select distinct
						guid_mms_channel,
						LinkGuid,
						nRow = ROW_NUMBER() over(partition by guid_mms_channel order by created_at desc)
					from #t_2Insert
					) s
				where s.nRow = 1
			) s
			on	s.guid_mms_channel =  t.guid_mms_channel
			when not matched then insert (
				guid_mms_channel
				,', @TargetColName, ')
			values
			(
				s.guid_mms_channel,
				s.LinkGuid
			)
			when matched and t.' , @TargetColName, '<> s.LinkGuid
				then update 
				set ', @TargetColName, ' = s.LinkGuid
					,updated_at = getdate()
			;')
		print @cmd_merge
		begin tran
			exec (@cmd_merge)
		commit tran

		delete t from link.lf_mms_channel_stage t
		where exists(select top(1) 1 from #t_2Insert s where s.Id = t.Id)
	end
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

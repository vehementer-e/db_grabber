--exec sat.fill_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
create   PROC sat.fill_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @CreatedOn_PaymentAttempt datetime = '2000-01-01'
	declare @CreatedOn_SbpPayoutAttempt datetime = '2000-01-01'

	declare @ВерсияДанных_ВыдачаДенежныхСредств binary(8) = 0x0
	--declare @RowVersion_ClientRequest binary(8) = 0x0

	if OBJECT_ID ('sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП') is not null
		and @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		--select 
		--	@rowVersion = isnull(cast(max(cast(s.ВерсияДанных as bigint)) - 100000 as binary(8)), 0x0),
		--	@ДатаСтатусаДействует = isnull(dateadd(day, -30, max(s.ДатаСтатусаДействует)), '2000-01-01'),
		--	@ДатаВыдачиДенежныхСредств = isnull(dateadd(day, -30, max(s.ДатаВыдачиДенежныхСредств)), '2000-01-01')
		--from sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП as s

		select 
			--@rowVersion = isnull(max(s.ВерсияДанных) - 100, 0x0),
			@ВерсияДанных_ВыдачаДенежныхСредств = isnull(cast(max(cast(s.ВерсияДанных_ВыдачаДенежныхСредств as bigint)) - 100000 as binary(8)), 0x0),
			@CreatedOn_PaymentAttempt = isnull(dateadd(day, -3, max(s.CreatedOn_PaymentAttempt)), '2000-01-01'),
			@CreatedOn_SbpPayoutAttempt = isnull(dateadd(day, -3, max(s.CreatedOn_SbpPayoutAttempt)), '2000-01-01')
		from sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП as s
	end

	--список договоров, у которых появились/обновились доп продукты
	drop table if exists #t_ДоговорЗайма
	create table #t_ДоговорЗайма
	(
		СсылкаДоговораЗайма binary(16),
		GuidДоговораЗайма uniqueidentifier,
		КодДоговораЗайма nvarchar(14)
	)

	insert #t_ДоговорЗайма
	(
		СсылкаДоговораЗайма,
		GuidДоговораЗайма,
		КодДоговораЗайма
	)
	select distinct
		d.СсылкаДоговораЗайма,
		d.GuidДоговораЗайма,
		d.КодДоговораЗайма
	from hub.ДоговорЗайма as d
		inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
			on l.КодДоговораЗайма = d.КодДоговораЗайма
		inner join hub.ВыдачаДенежныхСредств as v
			on v.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		inner join link.ВыдачаДенежныхСредств_БанкиСБП as lvb
			on lvb.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		--
		inner join link.ДоговорЗайма_Заявка as ldr
			on ldr.КодДоговораЗайма = d.КодДоговораЗайма
		--
		inner join Stg._fedor.core_PaymentAttempt as pa
			on pa.ClientRequestId = ldr.GuidЗаявки
		--inner join Stg._fedor.core_ClientRequest as cr on cr.ID = pa.ClientRequestId
		inner join Stg._fedor.dictionary_MethodOfIssuance as mi
			on mi.id = pa.MethodOfIssuanceId
			and mi.code	= 'ЧерезECommPayСБП'
		inner join Stg._fedor.core_SbpPayoutAttempt as sbp_pa
			on sbp_pa.Id = pa.Id
		inner join Stg._fedor.dictionary_SBPBank as SBPBank
			on SBPBank.Id = sbp_pa.SBPBankId
			and SBPBank.IdExternal = lvb.GuidБанкиСБП
	where 1=1
		--
		and (
			--1 появились/обновились записи в hub.ВыдачаДенежныхСредств
			v.ВерсияДанных > @ВерсияДанных_ВыдачаДенежныхСредств
			--2 появились/обновились записи в PaymentAttempt
			or pa.CreatedOn > @CreatedOn_PaymentAttempt
			--2 появились/обновились записи в SbpPayoutAttempt
			or sbp_pa.CreatedOn > @CreatedOn_SbpPayoutAttempt
		)
		and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
		and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

	if @isDebug = 1
	begin
		drop table if exists ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
	end


	drop table if exists #t_sat_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП



	select distinct
		lvb.GuidLink_ВыдачаДенежныхСредств_БанкиСБП,
		--
		GuidSbpPayoutAttempt = try_cast(sbp_pa.Id as varchar(50)),
		--
		PaymentAttempt_IsActive = pa.IsActive,
		PaymentAttempt_PaymentAttemptType = pa.PaymentAttemptType,
		PaymentAttempt_IsDeleted = pa.IsDeleted,
		--
		SbpPayoutAttempt_Phone = sbp_pa.Phone,
		SbpPayoutAttempt_IsPhoneNumberFromRequest = sbp_pa.IsPhoneNumberFromRequest,
		SbpPayoutAttempt_FioReductionInternal = sbp_pa.FioReductionInternal,
		SbpPayoutAttempt_FioReductionSbp = sbp_pa.FioReductionSbp,
		SbpPayoutAttempt_IsOwner = sbp_pa.IsOwner,
		SbpPayoutAttempt_RejectReason = sbp_pa.RejectReason,
		SbpPayoutAttempt_ExternalId = sbp_pa.ExternalId,
		SbpPayoutAttempt_IsDeleted = sbp_pa.IsDeleted,
		--
		ВерсияДанных_ВыдачаДенежныхСредств = v.ВерсияДанных,
		CreatedOn_PaymentAttempt = pa.CreatedOn,
		CreatedOn_SbpPayoutAttempt = sbp_pa.CreatedOn,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_sat_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
	from #t_ДоговорЗайма as d
		inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
			on l.КодДоговораЗайма = d.КодДоговораЗайма
		inner join hub.ВыдачаДенежныхСредств as v
			on v.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		inner join link.ВыдачаДенежныхСредств_БанкиСБП as lvb
			on lvb.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		--
		inner join link.ДоговорЗайма_Заявка as ldr
			on ldr.КодДоговораЗайма = d.КодДоговораЗайма
		--
		inner join Stg._fedor.core_PaymentAttempt as pa
			on pa.ClientRequestId = ldr.GuidЗаявки
		--inner join Stg._fedor.core_ClientRequest as cr on cr.ID = pa.ClientRequestId
		inner join Stg._fedor.dictionary_MethodOfIssuance as mi
			on mi.id = pa.MethodOfIssuanceId
			and mi.code	= 'ЧерезECommPayСБП'
		inner join Stg._fedor.core_SbpPayoutAttempt as sbp_pa
			on sbp_pa.Id = pa.Id
		inner join Stg._fedor.dictionary_SBPBank as SBPBank
			on SBPBank.Id = sbp_pa.SBPBankId
			and SBPBank.IdExternal = lvb.GuidБанкиСБП
	where 1=1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
		SELECT * INTO ##t_sat_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП FROM #t_sat_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
		--RETURN 0
	END


	if OBJECT_ID('sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП') is null
	begin
		select top(0)
			GuidLink_ВыдачаДенежныхСредств_БанкиСБП,
			GuidSbpPayoutAttempt,
			--
			PaymentAttempt_IsActive,
			PaymentAttempt_PaymentAttemptType,
			PaymentAttempt_IsDeleted,
			--
			SbpPayoutAttempt_Phone,
			SbpPayoutAttempt_IsPhoneNumberFromRequest,
			SbpPayoutAttempt_FioReductionInternal,
			SbpPayoutAttempt_FioReductionSbp,
			SbpPayoutAttempt_IsOwner,
			SbpPayoutAttempt_RejectReason,
			SbpPayoutAttempt_ExternalId,
			SbpPayoutAttempt_IsDeleted,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			CreatedOn_PaymentAttempt,
			CreatedOn_SbpPayoutAttempt,
            created_at,
            updated_at,
            spFillName
		into sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
		from #t_sat_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП

		alter table sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
		alter column GuidLink_ВыдачаДенежныхСредств_БанкиСБП uniqueidentifier not null

		alter table sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
		alter column GuidSbpPayoutAttempt varchar(50) not null

		ALTER TABLE sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
		ADD CONSTRAINT PK_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП 
		PRIMARY KEY CLUSTERED (
			GuidLink_ВыдачаДенежныхСредств_БанкиСБП,
			GuidSbpPayoutAttempt
		)
	end

	begin tran
		if @mode = 0 begin
			delete s
			from sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП as s
		end

		--удалить/вставить все для списка договоров
		delete s
		from #t_ДоговорЗайма as d
			inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
				on l.КодДоговораЗайма = d.КодДоговораЗайма
			inner join link.ВыдачаДенежныхСредств_БанкиСБП as lvb
				on lvb.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
			inner join sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП as s
				on s.GuidLink_ВыдачаДенежныхСредств_БанкиСБП = lvb.GuidLink_ВыдачаДенежныхСредств_БанкиСБП

		insert sat.link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
		(
			GuidLink_ВыдачаДенежныхСредств_БанкиСБП,
			GuidSbpPayoutAttempt,
			--
			PaymentAttempt_IsActive,
			PaymentAttempt_PaymentAttemptType,
			PaymentAttempt_IsDeleted,
			--
			SbpPayoutAttempt_Phone,
			SbpPayoutAttempt_IsPhoneNumberFromRequest,
			SbpPayoutAttempt_FioReductionInternal,
			SbpPayoutAttempt_FioReductionSbp,
			SbpPayoutAttempt_IsOwner,
			SbpPayoutAttempt_RejectReason,
			SbpPayoutAttempt_ExternalId,
			SbpPayoutAttempt_IsDeleted,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			CreatedOn_PaymentAttempt,
			CreatedOn_SbpPayoutAttempt,
            created_at,
            updated_at,
            spFillName
		)
		select 
			GuidLink_ВыдачаДенежныхСредств_БанкиСБП,
			GuidSbpPayoutAttempt,
			--
			PaymentAttempt_IsActive,
			PaymentAttempt_PaymentAttemptType,
			PaymentAttempt_IsDeleted,
			--
			SbpPayoutAttempt_Phone,
			SbpPayoutAttempt_IsPhoneNumberFromRequest,
			SbpPayoutAttempt_FioReductionInternal,
			SbpPayoutAttempt_FioReductionSbp,
			SbpPayoutAttempt_IsOwner,
			SbpPayoutAttempt_RejectReason,
			SbpPayoutAttempt_ExternalId,
			SbpPayoutAttempt_IsDeleted,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			CreatedOn_PaymentAttempt,
			CreatedOn_SbpPayoutAttempt,
            created_at,
            updated_at,
            spFillName
		from #t_sat_link_ВыдачаДенежныхСредств_БанкиСБП_ЧерезECommPayСБП
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


/*
exec sat.fill_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка @mode = 0
exec sat.fill_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка @mode = 1, @isDebug = 1
*/
CREATE   PROC sat.fill_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка
	@mode int = 1,
	@days int = 1, --количество дней для пересчета
	@RequestGuid nvarchar(100) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @days = isnull(@days, 1)
	declare @spName nvarchar(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	--declare @updated_at datetime = '1900-01-01'
	declare @request_updated_at bigint = 0

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			--@updated_at = isnull(dateadd(HOUR, -2, max(S.lk_updated_at)), '1900-01-01')
			@request_updated_at = isnull(max(request_updated_at) - @days*3600*24, 0)
		FROM sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка AS S
	end
	if @isDebug = 1
	begin
		select request_updated_at = @request_updated_at
	end
	--1
	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(GuidЗаявки nvarchar(100)) -- uniqueidentifier)

	INSERT #t_Заявки(GuidЗаявки)
	SELECT R.id
	FROM Stg._LF.request AS R
	WHERE R.updated_at >= @request_updated_at
		and (R.id = @RequestGuid OR @RequestGuid IS NULL)

	CREATE INDEX IX1
	ON #t_Заявки(GuidЗаявки)

	select distinct
		СсылкаЗаявки		= Заявка.СсылкаЗаявки,
		GuidЗаявки			= Заявка.GuidЗаявки,
		original_lead_id	= R.original_lead_id,
		marketing_lead_id	= R.marketing_lead_id,
		request_updated_at	= R.updated_at,
		created_at			= CURRENT_TIMESTAMP,
		updated_at			= CURRENT_TIMESTAMP,
		spFillName			= @spName
		--ВерсияДанных = cast(LK_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка
	FROM #t_Заявки AS T
		INNER JOIN Stg._LF.request AS R
			ON R.id = T.GuidЗаявки
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.GuidЗаявки = T.GuidЗаявки
	if @isDebug = 1
	begin
		select  *
		from #t_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка
	end
	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			original_lead_id,
			marketing_lead_id,
			request_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка
		from #t_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка

		alter table sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran
		DECLARE @MergeResults TABLE (
		MergeAction VARCHAR(50),
		deleted_GuidЗаявки nvarchar(36),
		inserted_GuidЗаявки nvarchar(36)
		
		 )

		merge sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка t
		using (select *
		from #t_ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка s
		where 1=1) s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched 
		and (s.original_lead_id IS NOT NULL
				OR s.marketing_lead_id IS NOT NULL
				) 
		THEN insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			original_lead_id,
			marketing_lead_id,
			request_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.original_lead_id,
			s.marketing_lead_id,
			s.request_updated_at,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (
				isnull(t.original_lead_id,'') <> isnull(s.original_lead_id,'')
				OR isnull(t.marketing_lead_id,'') <> isnull(s.marketing_lead_id,'')
				OR t.request_updated_at <> s.request_updated_at
			)
			and (s.original_lead_id IS NOT NULL
				OR s.marketing_lead_id IS NOT NULL
				) 
		then update SET
			t.original_lead_id = s.original_lead_id,
			t.marketing_lead_id = s.marketing_lead_id,
			t.request_updated_at = s.request_updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
		WHEN MATCHED
			AND s.original_lead_id IS NULL
			AND s.marketing_lead_id IS NULL
		then DELETE
		OUTPUT $action as MergeAction, deleted.GuidЗаявки, inserted.GuidЗаявки
		 INTO @MergeResults;

		;
	--commit tran
	if @isDebug = 1
	begin
		select * from @MergeResults

		INSERT LogDb.dbo.DataVault_MergeResults_log
		(
			DataVault_object,
			MergeAction,
			deleted_GuidЗаявки,
			inserted_GuidЗаявки
		)
		select  
			DataVault_object = 'sat.ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка',
			MergeAction,
			deleted_GuidЗаявки,
			inserted_GuidЗаявки
		FROM @MergeResults
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

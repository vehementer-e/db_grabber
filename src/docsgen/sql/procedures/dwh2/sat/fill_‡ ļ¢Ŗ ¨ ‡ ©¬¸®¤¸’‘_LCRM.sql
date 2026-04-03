CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_LCRM
	@mode int = 1
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_LCRM
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	SELECT @mode = isnull(@mode, 1)

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_LCRM

	if object_id('sat.ЗаявкаНаЗаймПодПТС_LCRM') is not NULL
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_LCRM), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(DAY, -2, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_LCRM AS S
	end

	-- заявки, у которых могли поменяться атрибуты LCRM
	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(
		НомерЗаявки nvarchar(20), 
		LCRM_ID numeric(10,0)
	)

	--Берем из LCRM c ранним id если дубли по номеру заявки в ЛСРМ
	INSERT #t_Заявки(НомерЗаявки, LCRM_ID)
	SELECT 
		B.UF_ROW_ID,
		LCRM_ID = min(B.ID)
	FROM (
			SELECT DISTINCT R.UF_ROW_ID
			FROM Stg._LCRM.lcrm_leads_full_channel_request AS R
			WHERE R.DWHInsertedDate >= @updated_at
		) AS A
		INNER JOIN Stg._LCRM.lcrm_leads_full_channel_request AS B
			ON B.UF_ROW_ID = A.UF_ROW_ID
	GROUP BY B.UF_ROW_ID

	select distinct
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.GuidЗаявки,

		LcrmID = LCRM.ID,
		КаналОтИсточникаLCRM = LCRM.[Канал от источника],
		ТипТрафикаLCRM = LCRM.UF_TYPE,
		ПриоритетОбзвонаLCRM = LCRM.UF_LOGINOM_PRIORITY,
		ВебмастерLCRM = LCRM.UF_PARTNER_ID,
		ТипРекламыLCRM = LCRM.UF_STAT_AD_TYPE,
		КампанияLCRM = LCRM.UF_STAT_CAMPAIGN,
		ТрекерАппметрикаLCRM = LCRM.UF_APPMECA_TRACKER,

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_LCRM
	--SELECT *
	FROM #t_Заявки AS Заявки
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.НомерЗаявки = Заявки.НомерЗаявки
		INNER JOIN Stg._LCRM.lcrm_leads_full_channel_request AS LCRM
			ON LCRM.ID = Заявки.LCRM_ID


	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_LCRM') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
            LcrmID,
            КаналОтИсточникаLCRM,
            ТипТрафикаLCRM,
            ПриоритетОбзвонаLCRM,
            ВебмастерLCRM,
            ТипРекламыLCRM,
            КампанияLCRM,
            ТрекерАппметрикаLCRM,
            created_at,
            updated_at,
            spFillName
		into sat.ЗаявкаНаЗаймПодПТС_LCRM
		from #t_ЗаявкаНаЗаймПодПТС_LCRM

		alter table sat.ЗаявкаНаЗаймПодПТС_LCRM
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_LCRM
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_LCRM PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_LCRM t
		using #t_ЗаявкаНаЗаймПодПТС_LCRM s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
            LcrmID,
            КаналОтИсточникаLCRM,
            ТипТрафикаLCRM,
            ПриоритетОбзвонаLCRM,
            ВебмастерLCRM,
            ТипРекламыLCRM,
            КампанияLCRM,
            ТрекерАппметрикаLCRM,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
            s.LcrmID,
            s.КаналОтИсточникаLCRM,
            s.ТипТрафикаLCRM,
            s.ПриоритетОбзвонаLCRM,
            s.ВебмастерLCRM,
            s.ТипРекламыLCRM,
            s.КампанияLCRM,
            s.ТрекерАппметрикаLCRM,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (
				   isnull(t.LcrmID, 0) != isnull(s.LcrmID, 0)
				OR isnull(t.КаналОтИсточникаLCRM, '') != isnull(s.КаналОтИсточникаLCRM, '')
				OR isnull(t.ТипТрафикаLCRM, '') != isnull(s.ТипТрафикаLCRM, '')
				OR isnull(t.ПриоритетОбзвонаLCRM, '') != isnull(s.ПриоритетОбзвонаLCRM, '')
				OR isnull(t.ВебмастерLCRM, '') != isnull(s.ВебмастерLCRM, '')
				OR isnull(t.ТипРекламыLCRM, '') != isnull(s.ТипРекламыLCRM, '')
				OR isnull(t.КампанияLCRM, '') != isnull(s.КампанияLCRM, '')
				OR isnull(t.ТрекерАппметрикаLCRM, '') != isnull(s.ТрекерАппметрикаLCRM, '')
				--OR t.ВерсияДанных != s.ВерсияДанных
			)
		then update SET
            t.LcrmID = s.LcrmID,
            t.КаналОтИсточникаLCRM = s.КаналОтИсточникаLCRM,
            t.ТипТрафикаLCRM = s.ТипТрафикаLCRM,
            t.ПриоритетОбзвонаLCRM = s.ПриоритетОбзвонаLCRM,
            t.ВебмастерLCRM = s.ВебмастерLCRM,
            t.ТипРекламыLCRM = s.ТипРекламыLCRM,
            t.КампанияLCRM = s.КампанияLCRM,
            t.ТрекерАппметрикаLCRM = s.ТрекерАппметрикаLCRM,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
			;
	--commit tran

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

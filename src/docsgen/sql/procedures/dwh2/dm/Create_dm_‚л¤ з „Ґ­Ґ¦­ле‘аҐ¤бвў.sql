--drop table dm.ВыдачаДенежныхСредств
-- =======================================================
-- Create: 18.02.2026. А.Никитин
-- Description:	
-- =======================================================
create   PROC dm.Create_dm_ВыдачаДенежныхСредств
	@mode int = 1, -- 1-increment, 0-full
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
as
begin
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)

	DECLARE @DurationSec int, @StartDate datetime = getdate()
	DECLARE @DeleteRows int, @InsertRows int

	SELECT @eventName = 'dwh2.dm.Create_dm_ВыдачаДенежныхСредств', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.ВыдачаДенежныхСредств') is null
		BEGIN
		    SELECT TOP(0) *
			INTO dm.ВыдачаДенежныхСредств
			FROM dm.v_ВыдачаДенежныхСредств

			alter table dm.ВыдачаДенежныхСредств
				alter COLUMN СсылкаДоговораЗайма binary(16) not null

			alter table dm.ВыдачаДенежныхСредств
				alter column КодДоговораЗайма nvarchar(14) not null

			alter table dm.ВыдачаДенежныхСредств
				alter column GuidДоговораЗайма uniqueidentifier not null

			--ALTER TABLE dm.ВыдачаДенежныхСредств
			--	ADD CONSTRAINT PK_dm_ВыдачаДенежныхСредств 
			--	PRIMARY KEY CLUSTERED (
			--		КодДоговораЗайма,
			--		...
			--		)

			CREATE NONCLUSTERED INDEX ix_КодДоговораЗайма
				ON dm.ВыдачаДенежныхСредств(КодДоговораЗайма, GuidДоговораЗайма)

			CREATE NONCLUSTERED INDEX ix_GuidДоговораЗайма
				ON dm.ВыдачаДенежныхСредств(GuidДоговораЗайма, КодДоговораЗайма)
		END

		DROP TABLE IF EXISTS #t_change

		SELECT C.КодДоговораЗайма, id
		INTO #t_change
		FROM link.ВыдачаДенежныхСредств_change AS C

		create clustered index cix_id on #t_change(id)
		create index cix_КодДоговораЗайма on #t_change(КодДоговораЗайма)

		DROP TABLE IF EXISTS #t_ВыдачаДенежныхСредств

		SELECT TOP(0) *
		INTO #t_ВыдачаДенежныхСредств
		FROM dm.v_ВыдачаДенежныхСредств

		IF @mode = 0
		BEGIN
			INSERT #t_ВыдачаДенежныхСредств
			SELECT R.* 
			FROM dm.v_ВыдачаДенежныхСредств AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_ВыдачаДенежныхСредств
			SELECT distinct R.* 
			FROM dm.v_ВыдачаДенежныхСредств AS R
			where exists(select top(1) 1 FROM #t_change AS T
			where R.КодДоговораЗайма = T.КодДоговораЗайма)
		END


		BEGIN TRAN

			IF @mode = 0
			BEGIN
				DELETE R 
				FROM dm.ВыдачаДенежныхСредств AS R
			END
			else begin
				DELETE R 
				FROM dm.ВыдачаДенежныхСредств AS R
					INNER JOIN #t_ВыдачаДенежныхСредств AS T
						ON T.КодДоговораЗайма = R.КодДоговораЗайма
			END

			SELECT @DeleteRows = @@ROWCOUNT
			/*
			Alter table  dm.ВыдачаДенежныхСредств

				add КодТипКредитногоПродукта nvarchar(250)
				,КодПодТипКредитногоПродукта nvarchar(250)	 

			alter table  dm.ВыдачаДенежныхСредств
				add [eqxScoreGroupUnsecured]     nvarchar(50)
					,eqxScoreGroupUnsecured_date datetime
	*/
	
			INSERT dm.ВыдачаДенежныхСредств
			(
				created_at,

				СсылкаДоговораЗайма, 
				GuidДоговораЗайма, 
				КодДоговораЗайма, 

				СпособВыдачи_Код, 
				СпособВыдачи_Наименование, 

				Выдача_isDelete,
				Выдача_Дата,
				Выдача_Номер,
				Выдача_Проведен,
				Выдача_Сумма,
				Выдача_ПервичныйДокумент,
				Выдача_ДатаВыдачи,
				Выдача_ВерсияДанных,

				Платежи_НомерСтроки,
				Платежи_ДатаПлатежа,
				Платежи_НомерПлатежа,
				Платежи_СуммаПлатежа,
				Платежи_ИдентификаторПлатежа,
				Платежи_ИдентификаторПлатежнойСистемы,
				Платежи_ПлатежныйПроект,
				Платежи_КлючЗаписи,

				Банк_БИК,
				Банк_Наименование,
				Банк_КоррСчет,

				НаСчетДилера_НомерСчетаЗаемщика,
				НаСчетДилера_Проведен,
				НаСчетДилера_Дата,
				НаСчетДилера_СуммаДокумента,
				НаСчетДилера_СуммаНДС,
				НаСчетДилера_НазначениеПлатежа,

				НаКартуЧерезТокен_IssuanceCardToken,

				БанкиСБП_ИдентификаторEcomPay,
				БанкиСБП_Аббревиатура,
				БанкиСБП_НациональноеНаименование,
				БанкиСБП_ИдентификаторУчастникаСБП,

				ЧерезECommPayСБП_PaymentAttempt_IsActive,
				ЧерезECommPayСБП_PaymentAttempt_PaymentAttemptType,
				ЧерезECommPayСБП_PaymentAttempt_IsDeleted,

				ЧерезECommPayСБП_Phone,
				ЧерезECommPayСБП_IsPhoneNumberFromRequest,
				ЧерезECommPayСБП_FioReductionInternal,
				ЧерезECommPayСБП_FioReductionSbp,
				ЧерезECommPayСБП_IsOwner,
				ЧерезECommPayСБП_RejectReason,
				ЧерезECommPayСБП_ExternalId,
				ЧерезECommPayСБП_IsDeleted,

				НомерСчетаПлательщика,
				БИКбанкаПлательщика,
				ИННплательщика,

				GuidВыдачаДенежныхСредств,

				GuidLink_ВыдачаДенежныхСредств_Банки,
				GuidПлатежноеПоручение,

				GuidLink_ВыдачаДенежныхСредств_БанкиСБП,
				GuidSbpPayoutAttempt
			)
			SELECT distinct 
				created_at,

				СсылкаДоговораЗайма, 
				GuidДоговораЗайма, 
				КодДоговораЗайма, 

				СпособВыдачи_Код, 
				СпособВыдачи_Наименование, 

				Выдача_isDelete,
				Выдача_Дата,
				Выдача_Номер,
				Выдача_Проведен,
				Выдача_Сумма,
				Выдача_ПервичныйДокумент,
				Выдача_ДатаВыдачи,
				Выдача_ВерсияДанных,

				Платежи_НомерСтроки,
				Платежи_ДатаПлатежа,
				Платежи_НомерПлатежа,
				Платежи_СуммаПлатежа,
				Платежи_ИдентификаторПлатежа,
				Платежи_ИдентификаторПлатежнойСистемы,
				Платежи_ПлатежныйПроект,
				Платежи_КлючЗаписи,

				Банк_БИК,
				Банк_Наименование,
				Банк_КоррСчет,

				НаСчетДилера_НомерСчетаЗаемщика,
				НаСчетДилера_Проведен,
				НаСчетДилера_Дата,
				НаСчетДилера_СуммаДокумента,
				НаСчетДилера_СуммаНДС,
				НаСчетДилера_НазначениеПлатежа,

				НаКартуЧерезТокен_IssuanceCardToken,

				БанкиСБП_ИдентификаторEcomPay,
				БанкиСБП_Аббревиатура,
				БанкиСБП_НациональноеНаименование,
				БанкиСБП_ИдентификаторУчастникаСБП,

				ЧерезECommPayСБП_PaymentAttempt_IsActive,
				ЧерезECommPayСБП_PaymentAttempt_PaymentAttemptType,
				ЧерезECommPayСБП_PaymentAttempt_IsDeleted,

				ЧерезECommPayСБП_Phone,
				ЧерезECommPayСБП_IsPhoneNumberFromRequest,
				ЧерезECommPayСБП_FioReductionInternal,
				ЧерезECommPayСБП_FioReductionSbp,
				ЧерезECommPayСБП_IsOwner,
				ЧерезECommPayСБП_RejectReason,
				ЧерезECommPayСБП_ExternalId,
				ЧерезECommPayСБП_IsDeleted,

				НомерСчетаПлательщика,
				БИКбанкаПлательщика,
				ИННплательщика,

				GuidВыдачаДенежныхСредств,

				GuidLink_ВыдачаДенежныхСредств_Банки,
				GuidПлатежноеПоручение,

				GuidLink_ВыдачаДенежныхСредств_БанкиСБП,
				GuidSbpPayoutAttempt
			FROM #t_ВыдачаДенежныхСредств AS T

			SELECT @InsertRows = @@ROWCOUNT

			insert tmp.log_link_ВыдачаДенежныхСредств_change(spFillName, row_count)
			select C.spFillName, row_count = count(*)
			FROM link.ВыдачаДенежныхСредств_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
			group by C.spFillName

			DELETE C
			FROM link.ВыдачаДенежныхСредств_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
		COMMIT

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Заполнение dwh2.dm.ВыдачаДенежныхСредств. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		IF @isDebug = 1 BEGIN
			SELECT @message
			EXEC LogDb.dbo.LogAndSendMailToAdmin 
				@eventName = @eventName, 
				@eventType = @eventType, 
				@message = @message, 
				@SendEmail = @SendEmail, 
				@ProcessGUID = @ProcessGUID
		END
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Ошибка заполнения dwh2.dm.ВыдачаДенежныхСредств. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END

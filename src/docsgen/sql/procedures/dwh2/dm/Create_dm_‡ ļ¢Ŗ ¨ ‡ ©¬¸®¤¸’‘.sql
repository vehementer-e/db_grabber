-- =======================================================
-- Create: 25.04.2023. А.Никитин
-- Description:	
-- =======================================================
CREATE PROC dm.Create_dm_ЗаявкаНаЗаймПодПТС
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

	SELECT @eventName = 'dwh2.dm.Create_dm_ЗаявкаНаЗаймПодПТС', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.ЗаявкаНаЗаймПодПТС') is null
		BEGIN
		    SELECT TOP(0) *
			INTO dm.ЗаявкаНаЗаймПодПТС
			FROM dm.v_ЗаявкаНаЗаймПодПТС

			alter table dm.ЗаявкаНаЗаймПодПТС
				alter COLUMN СсылкаЗаявки binary(16) not null

			alter table dm.ЗаявкаНаЗаймПодПТС
				alter column НомерЗаявки nvarchar(14) not null

			alter table dm.ЗаявкаНаЗаймПодПТС
				alter column GuidЗаявки uniqueidentifier not null

			ALTER TABLE dm.ЗаявкаНаЗаймПодПТС
				ADD CONSTRAINT PK_dm_ЗаявкаНаЗаймПодПТС PRIMARY KEY CLUSTERED (GuidЗаявки)

			CREATE NONCLUSTERED INDEX ix_НомерЗаявки 
				ON dm.ЗаявкаНаЗаймПодПТС(НомерЗаявки, GuidЗаявки)
		END

		DROP TABLE IF EXISTS #t_change

		SELECT C.GuidЗаявки, id
		INTO #t_change
		FROM link.ЗаявкаНаЗаймПодПТС_change AS C

		create clustered index cix_id on #t_change(id)
		create index cix_GuidЗаявки on #t_change(GuidЗаявки)


		DROP TABLE IF EXISTS #t_ЗаявкаНаЗаймПодПТС

		SELECT TOP(0) *
		INTO #t_ЗаявкаНаЗаймПодПТС
		FROM dm.v_ЗаявкаНаЗаймПодПТС

		IF @mode = 0
		BEGIN
			INSERT #t_ЗаявкаНаЗаймПодПТС
			SELECT R.* 
			FROM dm.v_ЗаявкаНаЗаймПодПТС AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_ЗаявкаНаЗаймПодПТС
			SELECT distinct R.* 
			FROM dm.v_ЗаявкаНаЗаймПодПТС AS R
			where exists(select top(1) 1 FROM #t_change AS T
			where R.GuidЗаявки = T.GuidЗаявки)
				
		END


		--select * from #t_ЗаявкаНаЗаймПодПТС
		--where НомерЗаявки  = '23102321329106'
		--group by НомерЗаявки 
		--having count(1) >1
		

		BEGIN TRAN
			DELETE R 
			FROM dm.ЗаявкаНаЗаймПодПТС AS R
				INNER JOIN #t_ЗаявкаНаЗаймПодПТС AS T
					ON T.GuidЗаявки = R.GuidЗаявки

			SELECT @DeleteRows = @@ROWCOUNT
			/*
			Alter table  dm.ЗаявкаНаЗаймПодПТС

				add КодТипКредитногоПродукта nvarchar(250)
				,КодПодТипКредитногоПродукта nvarchar(250)	 

			alter table  dm.ЗаявкаНаЗаймПодПТС
				add [eqxScoreGroupUnsecured]     nvarchar(50)
					,eqxScoreGroupUnsecured_date datetime
	*/
	
			INSERT dm.ЗаявкаНаЗаймПодПТС
			(
				 [created_at]
				, [СсылкаЗаявки]
				, [GuidЗаявки]
				, [НомерЗаявки]
				, [Продукт]
				, [МестоСоздания]
				, [МестоСоздания2]
				, [ВидЗаполнения]
				, [СрокЗайма]
				, [ВариантПредложенияСтавки]
				, [ВидЗайма]
				, [МаркаТС]
				, [МодельТС]
				, [ГодТС]
				, [СуммаЗаявки]
				, [ОценочнаяСтоимостьТС]
				, [РекомендованнаяСтавка]
				, [ОдобреннаяСумма]
				, [ВыданнаяСумма]
				, [ДатаЗаявки]
				, [isInstallment]
				, [isSmartInstallment]
				, [GuidСтатусЗаявки]
				, [СтатусЗаявки]
				, [ДатаСтатуса]
				, [Офис]
				, [АвторЗаявки]
				, [GuidКлиента]
				, [СсылкаНаКлиента]
				, [Телефон]
				, [Фамилия]
				, [Имя]
				, [Отчество]
				, [ФИО]
				, [ДатаРождения]
				, [Пол]
				, [ПричинаОтказа]
				, [ПризнакРефинансирование]
				, [ПризнакИспытательныйСрок]
				, [RBP]
				, [РегионПроживания]
				, [GMTпроживания]
				, [ПартнерCRM]
				, [НомерПартнераCRM]
				, [СуммарныйМесячныйДоход]
				, [ВозрастНаДатуЗаявки]
				, [РегионРегистрации]
				, [НомерТочкиПриСоздании]
				, [ЮрлицоПриСоздании]
				, [ДвижениеПоТочкам]
				, [КодДоговораЗайма]
				, [ПризнакТестоваяЗаявка]
				, [ПерезаведенаПослеЗаявки]
				, [ПерезаведенаНаЗаявку]
				, [LcrmID]
				, [КаналОтИсточникаLCRM]
				, [ТипТрафикаLCRM]
				, [ПриоритетОбзвонаLCRM]
				, [ВебмастерLCRM]
				, [ТипРекламыLCRM]
				, [КампанияLCRM]
				, [ТрекерАппметрикаLCRM]
				, [ПризнакP2P]
				, [СсылкаНаЛидCRM]
				, [GuidЛидCRM]
				, [feodor_lead_id]
				, [feodor_request_id]
				, [lk_request_id]
				, [lk_request_code]
				, [lk_promocode]
				, [lk_created_at]
				, isPts
				, isPdl
				, [GuidТипКредитныйПродукт]
				, ТипКредитногоПродукта
				, КодТипКредитногоПродукта
				, [GuidПодТипКредитногоПродукта]
				, ПодТипКредитногоПродукта
				, КодПодТипКредитногоПродукта
				, VIN
				, ЗабираемПТС
				, [Сумма Первичная]
				, [Наличие Залога]
				, [Серия Паспорта]
				, [Номер Паспорта]
				, [Признак ПЭП3]
				, ВидЗаймаВРамкахПродукта
				, ТипПродуктаПервоначальный

				, RBP_GR
				, СемейноеПоложение
				, Должность
				, ТипЗанятости
				, ИсточникLCRM
				, UTMИсточникLCRM
				, СтоимостьТС
				, СрокЗаймаВднях

				, СсылкаОфис
				, GuidОфис

				, СсылкаОфисПервоначальный
				, GuidОфисПервоначальный
				, ОфисПервоначальный

				, СпособВыдачиЗайма
				, original_lead_id
				, marketing_lead_id

				, РегионПроживанияКакВЗаявке
				, РегионПроживанияКлиента
				, РегионРегистрацииКлиента

				, NeedBki
				, loginomClassificationReason4Refusal
				, eqxScoreGroupUnsecured
				, eqxScoreGroupUnsecured_date 

				, РегионПроживания_НовыйРегион
				, РегионРегистрации_НовыйРегион

			)
			SELECT distinct 
				  [created_at]
				, [СсылкаЗаявки]
				, [GuidЗаявки]
				, [НомерЗаявки]
				, [Продукт]
				, [МестоСоздания]
				, [МестоСоздания2]
				, [ВидЗаполнения]
				, [СрокЗайма]
				, [ВариантПредложенияСтавки]
				, [ВидЗайма]
				, [МаркаТС]
				, [МодельТС]
				, [ГодТС]
				, [СуммаЗаявки]
				, [ОценочнаяСтоимостьТС]
				, [РекомендованнаяСтавка]
				, [ОдобреннаяСумма]
				, [ВыданнаяСумма]
				, [ДатаЗаявки]
				, [isInstallment]
				, [isSmartInstallment]
				, [GuidСтатусЗаявки]
				, [СтатусЗаявки]
				, [ДатаСтатуса]
				, [Офис]
				, [АвторЗаявки]
				, [GuidКлиента]
				, [СсылкаНаКлиента]
				, [Телефон]
				, [Фамилия]
				, [Имя]
				, [Отчество]
				, [ФИО]
				, [ДатаРождения]
				, [Пол]
				, [ПричинаОтказа]
				, [ПризнакРефинансирование]
				, [ПризнакИспытательныйСрок]
				, [RBP]
				, [РегионПроживания]
				, [GMTпроживания]
				, [ПартнерCRM]
				, [НомерПартнераCRM]
				, [СуммарныйМесячныйДоход]
				, [ВозрастНаДатуЗаявки]
				, [РегионРегистрации]
				, [НомерТочкиПриСоздании]
				, [ЮрлицоПриСоздании]
				, [ДвижениеПоТочкам]
				, [КодДоговораЗайма]
				, [ПризнакТестоваяЗаявка]
				, [ПерезаведенаПослеЗаявки]
				, [ПерезаведенаНаЗаявку]
				, [LcrmID]
				, [КаналОтИсточникаLCRM]
				, [ТипТрафикаLCRM]
				, [ПриоритетОбзвонаLCRM]
				, [ВебмастерLCRM]
				, [ТипРекламыLCRM]
				, [КампанияLCRM]
				, [ТрекерАппметрикаLCRM]
				, [ПризнакP2P]
				, [СсылкаНаЛидCRM]
				, [GuidЛидCRM]
				, [feodor_lead_id]
				, [feodor_request_id]
				, [lk_request_id]
				, [lk_request_code]
				, [lk_promocode]
				, [lk_created_at]
				, isPts
				, isPdl
				, [GuidТипКредитныйПродукт]
				, ТипКредитногоПродукта
				, КодТипКредитногоПродукта
				, [GuidПодТипКредитногоПродукта]
				, ПодТипКредитногоПродукта
				, КодПодТипКредитногоПродукта
				, VIN
				, ЗабираемПТС
				, [Сумма Первичная]
				, [Наличие Залога]
				, [Серия Паспорта]
				, [Номер Паспорта]
				, [Признак ПЭП3]
				, ВидЗаймаВРамкахПродукта
				, ТипПродуктаПервоначальный

				, RBP_GR
				, СемейноеПоложение
				, Должность
				, ТипЗанятости
				, ИсточникLCRM
				, UTMИсточникLCRM
				, СтоимостьТС
				, СрокЗаймаВднях

				, СсылкаОфис
				, GuidОфис

				, СсылкаОфисПервоначальный
				, GuidОфисПервоначальный
				, ОфисПервоначальный

				, СпособВыдачиЗайма
				, original_lead_id
				, marketing_lead_id

				, РегионПроживанияКакВЗаявке
				, РегионПроживанияКлиента
				, РегионРегистрацииКлиента

				, NeedBki
				, loginomClassificationReason4Refusal
				, eqxScoreGroupUnsecured
				, eqxScoreGroupUnsecured_date

				, РегионПроживания_НовыйРегион
				, РегионРегистрации_НовыйРегион
			FROM #t_ЗаявкаНаЗаймПодПТС AS T

			SELECT @InsertRows = @@ROWCOUNT


			insert tmp.log_link_ЗаявкаНаЗаймПодПТС_change(spFillName, row_count)
			select C.spFillName, row_count = count(*)
			FROM link.ЗаявкаНаЗаймПодПТС_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
			group by C.spFillName

			DELETE C
			FROM link.ЗаявкаНаЗаймПодПТС_change AS C
				INNER JOIN #t_change AS T
				--INNER JOIN #t_ЗаявкаНаЗаймПодПТС AS T
					--ON T.GuidЗаявки = C.GuidЗаявки
					ON T.id = C.id
		COMMIT

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Заполнение dwh2.dm.ЗаявкаНаЗаймПодПТС. ',
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
				'Ошибка заполнения dwh2.dm.ЗаявкаНаЗаймПодПТС. ',
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

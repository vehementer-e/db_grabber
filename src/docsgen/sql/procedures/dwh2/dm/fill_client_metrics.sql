-- =======================================================
-- Create: 23.11.2024. А.Никитин
-- Description:	DWH-2649 Отчеты на birs по клиентским метрикам
-- exec dm.[fill_client_metrics]  @mode = 0
--	 select * from dm.client_metrics_calls
-- =======================================================
create     PROC [dm].[fill_client_metrics]
	@days int = 2, -- актуализация витрины за последние @days дней
	@mode int = 1, -- 
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@request_number nvarchar(20) = NULL,
	@isDebug int = 0
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @mode = isnull(@mode, 1)

	--DECLARE @rowVersion binary(8) = 0x0
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	--DECLARE @InsertRows int = 0, @DeleteRows int = 0
	DECLARE @call_date date = '2024-11-01'
	DECLARE @created_at datetime = getdate()
	
	SELECT @eventName = 'dwh2.dm.fill_client_metrics', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID ('dm.client_metrics_calls') is not null
			AND @mode = 1
		begin
			--set @rowVersion = isnull((select max(rowVersion) from dm.client_metrics_calls), 0x0)
			SELECT @call_date = isnull(dateadd(DAY, -@days, max(D.ОбзвонДата)), '2000-01-01')
			from dm.client_metrics_calls AS D
		end
		select @call_date
		-- 1 обзвоны
		DROP TABLE IF EXISTS #t_client_metrics_calls

		SELECT
			created_at = @created_at,
			ОбзвонСсылка = Документ_Обзвон.Ссылка,
			ОбзвонДата = dateadd(YEAR, -2000, Документ_Обзвон.Дата),
			ОбзвонВид = ВидыОбзвонов.Наименование,

			БизнесПроцессСсылка = CRM_БизнесПроцесс.Ссылка,

			--ОбзвонОписание = Задача.ПредметСтрокой,
			ОбзвонОписание = cast(NULL AS nvarchar(500)),

			ФИО_Клиента = concat_ws(' ', Документ_Обзвон.Фамилия, Документ_Обзвон.Имя, Документ_Обзвон.Отчество),
			Документ_Обзвон.Телефон,

			РегионРегистрации = cast(NULL AS nvarchar(255)),

			НомерЗаявки	= ЗаявкаНаЗаймПодПТС.Номер,
			GuidЗаявки = cast(dbo.getGUIDFrom1C_IDRREF(ЗаявкаНаЗаймПодПТС.Ссылка) as uniqueidentifier),
			GuidСтатусЗаявки= cast(NULL AS uniqueidentifier),
			СтатусЗаявки = cast(NULL AS nvarchar(100)),
			ДатаСтатуса = cast(NULL AS datetime2(0)),

			ДатаДоговораЗайма  = cast(NULL AS datetime2(0)),-- из договора Займа
			СуммаВыдачи = cast(NULL AS money), -- из договора Займа
			GuidТипКредитныйПродукт = cast(NULL AS uniqueidentifier),
			ТипКредитногоПродукта = cast(NULL AS nvarchar(100)),
			GuidПодТипКредитногоПродукта = cast(NULL AS uniqueidentifier),
			ПодТипКредитногоПродукта = cast(NULL AS nvarchar(100)),
			
			КредитныйПродукт = cast(NULL AS nvarchar(255)),

			GuidКлиента = cast(NULL AS uniqueidentifier),
			Email = cast(NULL AS nvarchar(255)),

			ДатаПоследнегоЗвонка = cast(NULL AS datetime),
			Попытки = cast(NULL AS smallint),

			--Результат = Задача.CRM_ВариантВыполненияСтрокой,
			Результат = cast(NULL AS nvarchar(500))

		INTO #t_client_metrics_calls
		FROM stg._1cCRM.Документ_Обзвон Документ_Обзвон
			INNER join stg._1cCRM.Справочник_ВидыОбзвонов ВидыОбзвонов 
				ON Документ_Обзвон.ВидДокумента = ВидыОбзвонов.Ссылка
				-- лежат кампании
				AND ВидыОбзвонов.Наименование in ('Welcome!', 'Заем погашен')
			LEFT JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
				ON ЗаявкаНаЗаймПодПТС.Ссылка = Документ_Обзвон.ЗаявкаОснование
			LEFT JOIN Stg._1cCRM.БизнесПроцесс_CRM_БизнесПроцесс AS CRM_БизнесПроцесс
				ON CRM_БизнесПроцесс.Предмет_Ссылка = Документ_Обзвон.Ссылка
			--LEFT JOIN Stg._1cCRM.Задача_ЗадачаИсполнителя AS Задача 
			--	on Задача.БизнесПроцесс_Ссылка = CRM_БизнесПроцесс.Ссылка
		WHERE 1=1
			AND ((Документ_Обзвон.Дата >= dateadd(YEAR, 2000, @call_date)
					AND @request_number IS NULL)
				OR 	(@request_number IS NOT NULL
					AND ЗаявкаНаЗаймПодПТС.Номер  = @request_number
					)
			)

		CREATE INDEX ix_ОбзвонСсылка ON #t_client_metrics_calls(ОбзвонСсылка)
		CREATE INDEX ix_GuidЗаявки ON #t_client_metrics_calls(GuidЗаявки)
		CREATE INDEX ix_НомерЗаявки ON #t_client_metrics_calls(НомерЗаявки)
		CREATE INDEX ix_БизнесПроцессСсылка ON #t_client_metrics_calls(БизнесПроцессСсылка)


		-- ответы на вопросы анкеты
		DROP TABLE IF EXISTS #t_client_metrics_answers

		;with cte as (
		select 
			Справочник_Анкетирование.Наименование,
			Справочник_Анкетирование.ТекстВопроса,
			Справочник_Анкетирование.МаксимальныйБалл,
			Документ_Обзвон_Ссылка = ОтветыАнкетирования.Ссылка,
			ОтветыАнкетирования.НомерСтроки,
			АнкетаСсылка = ОтветыАнкетирования.Анкета,
			ОтветыАнкетирования.Ответ_Тип,
			ОтветыАнкетирования.Ответ_Булево,
			ОтветыАнкетирования.Ответ_Число,
			ОтветыАнкетирования.Ответ_Строка,
			ОтветыАнкетирования.ДополнительныйОтвет
			--ОтветыАнкетирования.ОбластьДанныхОсновныеДанные,
			--ОтветыАнкетирования.КлючЗаписи
		from Stg._1cCRM.Документ_Обзвон_ОтветыАнкетирования ОтветыАнкетирования --лежат ответы на вопросы
			INNER join stg._1cCRM.Справочник_АнкетированиеКлиентовПриОбзвонах AS Справочник_Анкетирование
				ON Справочник_Анкетирование.Ссылка = ОтветыАнкетирования.Анкета
		)
		select
			created_at = @created_at,
			ОбзвонСсылка = Обзвон.ОбзвонСсылка,
			--
			НаименованиеВопроса = ОтветыАнкетирования.Наименование,
			ОтветыАнкетирования.ТекстВопроса,
			ОтветыАнкетирования.МаксимальныйБалл,
			--ОтветыАнкетирования.КлючЗаписи,
			--ОтветыАнкетирования.ОбластьДанныхОсновныеДанные,
			ОтветыАнкетирования.ДополнительныйОтвет,
			ОтветыАнкетирования.Ответ_Строка,
			ОтветыАнкетирования.Ответ_Число,
			ОтветыАнкетирования.Ответ_Булево,
			ОтветыАнкетирования.Ответ_Тип,
			ОтветыАнкетирования.АнкетаСсылка,
			ОтветыАнкетирования.НомерСтроки
		INTO #t_client_metrics_answers
		FROM #t_client_metrics_calls AS Обзвон
			inner join cte AS ОтветыАнкетирования 
				on ОтветыАнкетирования.Документ_Обзвон_Ссылка = Обзвон.ОбзвонСсылка


		--из задачи
		SELECT Задача.* 
		INTO #t_Задача
		FROM Stg._1cCRM.Задача_ЗадачаИсполнителя AS Задача
			INNER JOIN #t_client_metrics_calls AS M
				ON M.БизнесПроцессСсылка = Задача.БизнесПроцесс_Ссылка

		;WITH task AS (
			SELECT 
				T.*,
				rn = row_number() OVER(
					PARTITION BY T.БизнесПроцесс_Ссылка
					ORDER BY T.CRM_Итерация DESC, T.ПринятаКИсполнению DESC, T.Дата DESC) 
			FROM #t_Задача AS T
			)
		DELETE T FROM task AS T WHERE T.rn <> 1
		
		UPDATE M
		SET ОбзвонОписание = T.ПредметСтрокой,
			Результат = T.CRM_ВариантВыполненияСтрокой,
			ДатаПоследнегоЗвонка = dateadd(YEAR, -2000, T.Дата),
			Попытки = T.CRM_Итерация
		FROM #t_client_metrics_calls AS M
			INNER JOIN #t_Задача AS T
				ON T.БизнесПроцесс_Ссылка = M.БизнесПроцессСсылка

		--из заявки
		UPDATE M
		SET РегионРегистрации = D.РегионРегистрации,
			GuidСтатусЗаявки = d.GuidСтатусЗаявки,
			СтатусЗаявки = D.СтатусЗаявки,
			ДатаСтатуса = D.ДатаСтатуса,
			GuidТипКредитныйПродукт = d.[GuidТипКредитныйПродукт],
			ТипКредитногоПродукта = D.ТипКредитногоПродукта,
			GuidПодТипКредитногоПродукта = d.GuidПодТипКредитногоПродукта,
			ПодТипКредитногоПродукта = D.ПодТипКредитногоПродукта,
			
			КредитныйПродукт = D.Продукт,
			GuidКлиента = D.GuidКлиента
		FROM #t_client_metrics_calls AS M
			INNER JOIN dwh2.dm.ЗаявкаНаЗаймПодПТС AS D
				ON D.GuidЗаявки = M.GuidЗаявки
				
		--из клиента
		UPDATE M
		SET Email = E.Email
		FROM #t_client_metrics_calls AS M
			INNER JOIN dwh2.sat.Клиент_Email AS E
				ON E.GuidКлиент = M.GuidКлиента
				AND E.nRow = 1

		-- из договора Займа
		UPDATE M
		SET ДатаДоговораЗайма = D.ДатаДоговораЗайма,
			СуммаВыдачи = D.СуммаВыдачи
		FROM #t_client_metrics_calls AS M
			INNER JOIN dwh2.hub.ДоговорЗайма AS D
				ON D.КодДоговораЗайма = M.НомерЗаявки

		IF object_id('dm.client_metrics_calls') IS NULL
		BEGIN
			SELECT TOP(0)
				created_at,
				ОбзвонСсылка,
				ОбзвонДата,
				ОбзвонВид,
				--БизнесПроцессСсылка,
				ОбзвонОписание,
				ФИО_Клиента,
				Телефон,
				РегионРегистрации,
				НомерЗаявки,
				GuidЗаявки,
				GuidСтатусЗаявки,
				СтатусЗаявки,
				ДатаСтатуса,
				ДатаДоговораЗайма,
				СуммаВыдачи,
				GuidТипКредитныйПродукт,
				ТипКредитногоПродукта,
				GuidПодТипКредитногоПродукта,
				ПодТипКредитногоПродукта,
				КредитныйПродукт,
				GuidКлиента,
				Email,
				ДатаПоследнегоЗвонка,
				Попытки,
				Результат
			INTO dm.client_metrics_calls
			FROM #t_client_metrics_calls

			

			--ALTER TABLE dm.client_metrics_calls
			--	ADD CONSTRAINT PK_* PRIMARY KEY CLUSTERED (GuidЗаявки, Этап)

			CREATE INDEX ix_ОбзвонСсылка ON dm.client_metrics_calls(ОбзвонСсылка)
		END

		IF object_id('dm.client_metrics_answers') IS NULL
		BEGIN
			SELECT TOP(0)
				created_at,
				ОбзвонСсылка,
				НаименованиеВопроса,
				ТекстВопроса,
				МаксимальныйБалл,
				--КлючЗаписи,
				--ОбластьДанныхОсновныеДанные,
				ДополнительныйОтвет,
				Ответ_Строка,
				Ответ_Число,
				Ответ_Булево,
				Ответ_Тип,
				АнкетаСсылка,
				НомерСтроки
			INTO dm.client_metrics_answers
			FROM #t_client_metrics_answers

			--alter table dm.client_metrics_answers
			--	alter column response_Id bigint not null

			--ALTER TABLE dm.client_metrics_answers
			--	ADD CONSTRAINT PK_* PRIMARY KEY CLUSTERED (GuidЗаявки, Этап)

			CREATE INDEX ix_ОбзвонСсылка_НомерСтроки ON dm.client_metrics_answers(ОбзвонСсылка, НомерСтроки)
		END


		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_client_metrics_answers
			SELECT * INTO ##t_client_metrics_answers FROM #t_client_metrics_answers
		END


		BEGIN TRAN

			DELETE C
			FROM dm.client_metrics_calls AS C
			WHERE EXISTS(
					SELECT TOP(1) 1
					FROM #t_client_metrics_calls AS R
					WHERE R.ОбзвонСсылка = C.ОбзвонСсылка
				)

			DELETE A
			FROM dm.client_metrics_answers AS A
			WHERE EXISTS(
					SELECT TOP(1) 1
					FROM #t_client_metrics_calls AS R
					WHERE R.ОбзвонСсылка = A.ОбзвонСсылка
				)
		
			INSERT dm.client_metrics_calls
			(
				created_at,
				ОбзвонСсылка,
				ОбзвонДата,
				ОбзвонВид,
				--БизнесПроцессСсылка,
				ОбзвонОписание,
				ФИО_Клиента,
				Телефон,
				РегионРегистрации,
				НомерЗаявки,
				GuidЗаявки,
				GuidСтатусЗаявки,
				СтатусЗаявки,
				ДатаСтатуса,
				ДатаДоговораЗайма,
				СуммаВыдачи,
				GuidТипКредитныйПродукт,
				ТипКредитногоПродукта,
				GuidПодТипКредитногоПродукта,
				ПодТипКредитногоПродукта,
				
				КредитныйПродукт,
				GuidКлиента,
				Email,
				ДатаПоследнегоЗвонка,
				Попытки,
				Результат
			)
			SELECT
				created_at,
				ОбзвонСсылка,
				ОбзвонДата,
				ОбзвонВид,
				--БизнесПроцессСсылка,
				ОбзвонОписание,
				ФИО_Клиента,
				Телефон,
				РегионРегистрации,
				НомерЗаявки,
				GuidЗаявки,
				GuidСтатусЗаявки,
				СтатусЗаявки,
				ДатаСтатуса,
				ДатаДоговораЗайма,
				СуммаВыдачи,
				GuidТипКредитныйПродукт,
				ТипКредитногоПродукта,
				GuidПодТипКредитногоПродукта,
				ПодТипКредитногоПродукта,
				КредитныйПродукт,

				GuidКлиента,
				Email,
				ДатаПоследнегоЗвонка,
				Попытки,
				Результат
			FROM #t_client_metrics_calls AS T


			INSERT dm.client_metrics_answers
			(
				created_at,
				ОбзвонСсылка,
				НаименованиеВопроса,
				ТекстВопроса,
				МаксимальныйБалл,
				--КлючЗаписи,
				--ОбластьДанныхОсновныеДанные,
				ДополнительныйОтвет,
				Ответ_Строка,
				Ответ_Число,
				Ответ_Булево,
				Ответ_Тип,
				АнкетаСсылка,
				НомерСтроки
			)
			SELECT
				created_at,
				ОбзвонСсылка,
				НаименованиеВопроса,
				ТекстВопроса,
				МаксимальныйБалл,
				--КлючЗаписи,
				--ОбластьДанныхОсновныеДанные,
				ДополнительныйОтвет,
				Ответ_Строка,
				Ответ_Число,
				Ответ_Булево,
				Ответ_Тип,
				АнкетаСсылка,
				НомерСтроки
			FROM #t_client_metrics_answers AS T
		COMMIT

		--EXEC LogDb.dbo.LogAndSendMailToAdmin 
		--	@eventName = @eventName, 
		--	@eventType = @eventType, 
		--	@message = @message, 
		--	@SendEmail = @SendEmail, 
		--	@ProcessGUID = @ProcessGUID

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка заполнения dwh2.dm.client_metrics_calls, dwh2.dm.client_metrics_answers'

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

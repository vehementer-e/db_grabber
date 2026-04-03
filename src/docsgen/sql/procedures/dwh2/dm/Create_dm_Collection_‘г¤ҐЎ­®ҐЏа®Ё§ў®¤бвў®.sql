-- =======================================================
-- Create: 23.07.2027. А.Никитин
-- Description:	
-- =======================================================
create   PROC dm.Create_dm_Collection_СудебноеПроизводство
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

	SELECT @eventName = 'dwh2.dm.Create_dm_Collection_СудебноеПроизводство', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.Collection_СудебноеПроизводство') is null
		BEGIN
		    SELECT TOP(0) *
			INTO dm.Collection_СудебноеПроизводство
			FROM dm.v_Collection_СудебноеПроизводство

			alter table dm.Collection_СудебноеПроизводство
				alter COLUMN СсылкаДоговораЗайма binary(16) not null

			alter table dm.Collection_СудебноеПроизводство
				alter column КодДоговораЗайма nvarchar(14) not null

			alter table dm.Collection_СудебноеПроизводство
				alter column GuidДоговораЗайма uniqueidentifier not null

			alter table dm.Collection_СудебноеПроизводство
				alter column GuidCollection_TaskAction uniqueidentifier not null

			alter table dm.Collection_СудебноеПроизводство
				alter column GuidCollection_JudicialProceeding uniqueidentifier not null

			alter table dm.Collection_СудебноеПроизводство
				alter column GuidCollection_EnforcementOrders uniqueidentifier not null

			ALTER TABLE dm.Collection_СудебноеПроизводство
				ADD CONSTRAINT PK_dm_Collection_СудебноеПроизводство 
				PRIMARY KEY CLUSTERED (
					GuidCollection_TaskAction,
					GuidCollection_JudicialProceeding,
					GuidCollection_EnforcementOrders
				)

			CREATE NONCLUSTERED INDEX ix_КодДоговораЗайма
			ON dm.Collection_СудебноеПроизводство(КодДоговораЗайма)

			CREATE NONCLUSTERED INDEX ix_GuidКлиент
			ON dm.Collection_СудебноеПроизводство(GuidКлиент)
		END

		DROP TABLE IF EXISTS #t_change

		SELECT C.id, C.КодДоговораЗайма
		INTO #t_change
		FROM link.Collection_СудебноеПроизводство_change AS C

		create index ix1 on #t_change(id)
		create index ix2 on #t_change(КодДоговораЗайма)


		DROP TABLE IF EXISTS #t_Collection_СудебноеПроизводство

		SELECT TOP(0) *
		INTO #t_Collection_СудебноеПроизводство
		FROM dm.v_Collection_СудебноеПроизводство

		IF @mode = 0
		BEGIN
			INSERT #t_Collection_СудебноеПроизводство
			SELECT R.* 
			FROM dm.v_Collection_СудебноеПроизводство AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_Collection_СудебноеПроизводство
			SELECT distinct R.* 
			FROM dm.v_Collection_СудебноеПроизводство AS R
				INNER JOIN (
						SELECT DISTINCT T.КодДоговораЗайма FROM #t_change AS T
					) AS C
					ON R.КодДоговораЗайма = C.КодДоговораЗайма
		END

		CREATE NONCLUSTERED INDEX ix_КодДоговораЗайма
		ON #t_Collection_СудебноеПроизводство(КодДоговораЗайма)

		BEGIN TRAN
			DELETE R 
			FROM dm.Collection_СудебноеПроизводство AS R
				INNER JOIN #t_Collection_СудебноеПроизводство AS T
					ON T.КодДоговораЗайма = R.КодДоговораЗайма

			SELECT @DeleteRows = @@ROWCOUNT

			INSERT dm.Collection_СудебноеПроизводство
			(
				[created_at],
				[КодДоговораЗайма],
				[GuidДоговораЗайма],
				[СсылкаДоговораЗайма],
				[Дата договора],
				[customersId],
				[GuidКлиент],
				[ФИО],
				[Тип продукта],
				[DealsId],
				[Сумма займа],
				[Процентная ставка],
				[Срок договора],
				[Сумма ПДП],
				[Сумма задолженности на текущую дату],
				[Количество дней просрочки],
				[Дата возникновения просрочки],
				[Сумма последнего платежа],
				[Дата последнего платежа],
				[Стадия коллектинга договора],
				[Дата перехода на стадию договора],
				[Стадия коллектинга клиента],
				[Задача СП из очередей Спейс],
				[GuidCollection_TaskAction],
				[TaskActionId],
				[Комментарий к задаче СП из очередей Спейс],
				[Дубли (нахождение договора в нескольких очередях)],
				[Статус клиента из Спейс],
				[Алерты],
				[Ответственный взыскатель],
				[Куратор СП],
				[Дата погашения],
				[Количество требований],
				[GuidCollection_JudicialProceeding],
				[JudicialProceedingId],
				[Дата отправки требования клиенту],
				[Сумма требования],
				[GuidCollection_JudicialClaims],
				[JudicialClaimsId],
				[Дата отправки иска в суд],
				[Флаг Ручная подача],
				[Способ подачи],
				[Форма требования],
				[Наименование суда],
				[Регион суда],
				[Номер дела в суде],
				[Общая сумма иска],
				[ОД (иск)],
				[%% (иск)],
				[Неустойка (иск)],
				[ГП (иск)],
				[Иные требования (иск)],
				[Дата принятия к производству],
				[Дата судебного решения],
				[Дата получения решения],
				[Дата вступления в законную силу решения суда],
				[Расхождение сумм иска от решения],
				[Сумма по судебному решению],
				[ОД по судебному решению],
				[%% по судебному решению],
				[Неустойка по судебному решению],
				[ГП по судебному решению],
				[Иные требования по судебному решению],
				[% для погашения],
				[Рез-т рассм. иска по решению суда],
				[Вид решения суда],
				[Результат мониторинга],
				[Дальнейшие действия],
				[Причина возврата],
				[Причина отзыва иска],
				[Дата отзыва иска],
				[Апеллянт],
				[Результат обжалования],
				[Дата отправки заявления на выдачу ИЛ],
				[Количество ИЛ],
				[GuidCollection_EnforcementOrders],
				[EnforcementOrdersId],
				[Номер ИЛ],
				[Тип ИЛ],
				[Дата ИЛ],
				[Дата получения ИЛ],
				[Сумма ИЛ],
				[Начальная стоимость залога по ИЛ],
				[ИЛ принят],
				[Новый собственник],
				[Адрес нового собственника],
				[Дата рождения нового собственника],
				[Дата передачи в ИП],
				[Дата возврата ИЛ на доработку]
			)
			SELECT distinct 
				[created_at],
				[КодДоговораЗайма],
				[GuidДоговораЗайма],
				[СсылкаДоговораЗайма],
				[Дата договора],
				[customersId],
				[GuidКлиент],
				[ФИО],
				[Тип продукта],
				[DealsId],
				[Сумма займа],
				[Процентная ставка],
				[Срок договора],
				[Сумма ПДП],
				[Сумма задолженности на текущую дату],
				[Количество дней просрочки],
				[Дата возникновения просрочки],
				[Сумма последнего платежа],
				[Дата последнего платежа],
				[Стадия коллектинга договора],
				[Дата перехода на стадию договора],
				[Стадия коллектинга клиента],
				[Задача СП из очередей Спейс],
				[GuidCollection_TaskAction],
				[TaskActionId],
				[Комментарий к задаче СП из очередей Спейс],
				[Дубли (нахождение договора в нескольких очередях)],
				[Статус клиента из Спейс],
				[Алерты],
				[Ответственный взыскатель],
				[Куратор СП],
				[Дата погашения],
				[Количество требований],
				[GuidCollection_JudicialProceeding],
				[JudicialProceedingId],
				[Дата отправки требования клиенту],
				[Сумма требования],
				[GuidCollection_JudicialClaims],
				[JudicialClaimsId],
				[Дата отправки иска в суд],
				[Флаг Ручная подача],
				[Способ подачи],
				[Форма требования],
				[Наименование суда],
				[Регион суда],
				[Номер дела в суде],
				[Общая сумма иска],
				[ОД (иск)],
				[%% (иск)],
				[Неустойка (иск)],
				[ГП (иск)],
				[Иные требования (иск)],
				[Дата принятия к производству],
				[Дата судебного решения],
				[Дата получения решения],
				[Дата вступления в законную силу решения суда],
				[Расхождение сумм иска от решения],
				[Сумма по судебному решению],
				[ОД по судебному решению],
				[%% по судебному решению],
				[Неустойка по судебному решению],
				[ГП по судебному решению],
				[Иные требования по судебному решению],
				[% для погашения],
				[Рез-т рассм. иска по решению суда],
				[Вид решения суда],
				[Результат мониторинга],
				[Дальнейшие действия],
				[Причина возврата],
				[Причина отзыва иска],
				[Дата отзыва иска],
				[Апеллянт],
				[Результат обжалования],
				[Дата отправки заявления на выдачу ИЛ],
				[Количество ИЛ],
				[GuidCollection_EnforcementOrders],
				[EnforcementOrdersId],
				[Номер ИЛ],
				[Тип ИЛ],
				[Дата ИЛ],
				[Дата получения ИЛ],
				[Сумма ИЛ],
				[Начальная стоимость залога по ИЛ],
				[ИЛ принят],
				[Новый собственник],
				[Адрес нового собственника],
				[Дата рождения нового собственника],
				[Дата передачи в ИП],
				[Дата возврата ИЛ на доработку]
			FROM #t_Collection_СудебноеПроизводство AS T

			SELECT @InsertRows = @@ROWCOUNT

			DELETE C
			FROM link.Collection_СудебноеПроизводство_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
		COMMIT

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Заполнение dwh2.dm.Collection_СудебноеПроизводство. ',
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
				'Ошибка заполнения dwh2.dm.Collection_СудебноеПроизводство. ',
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
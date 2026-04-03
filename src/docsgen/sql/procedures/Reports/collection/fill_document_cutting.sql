-- =======================================================
-- Description:	DWH-2851 Реализовать отчет по результатам нарезки документов
-- EXEC collection.fill_document_cutting @isDebug = 1, @binaryID = 0xB86100505683FDCB11EF9C4908F138AF
-- =======================================================
CREATE PROC collection.fill_document_cutting
	--@days int = 20, -- актуализация витрины за последние @days дней
	@mode int = 1, -- 
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0,
	@binaryID binary(16) = NULL
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @InsertRows int = 0, @DeleteRows int = 0
	DECLARE @maxBalanceDate date
	DECLARE @rowVersion binary(8) = 0x0, @dateAdd datetime2(0) = '2000-01-01', @dateFile datetime2(0) = '2000-01-01'

	SELECT @eventName = 'dwh2.collection.fill_document_cutting', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID ('collection.document_cutting') is not null
			AND @mode = 1
			AND @binaryID IS NULL
		begin
			SELECT 
				@rowVersion = isnull(max(D.ВходящиеДокументы_ВерсияДанных) - 1000, 0x0),
				@dateAdd = isnull(dateadd(DAY, -2, max(D.ЗаданияНарезкиЕдиныйСкан_ДатаДобавления)), '2000-01-01'),
				@dateFile = isnull(dateadd(DAY, -2, max(D.ФайлыРаспознавание_Дата)), '2000-01-01')
			from collection.document_cutting AS D
		end

		DROP TABLE IF EXISTS #t_Ссылка
		CREATE TABLE #t_Ссылка(Ссылка binary(16))

		IF @binaryID IS NOT NULL BEGIN
			INSERT #t_Ссылка(Ссылка)
			VALUES (@binaryID)
		END
		ELSE BEGIN
			DROP TABLE IF EXISTS #t_Ссылка_1
			CREATE TABLE #t_Ссылка_1(Ссылка binary(16))

			INSERT #t_Ссылка_1(Ссылка)
			SELECT вд.Ссылка
			FROM Stg._1cDCMNT.Справочник_ВходящиеДокументы AS вд
			WHERE вд.ВерсияДанных >= @rowVersion

			DROP TABLE IF EXISTS #t_Ссылка_2
			CREATE TABLE #t_Ссылка_2(Ссылка binary(16))

			INSERT #t_Ссылка_2(Ссылка)
			SELECT Задания.ВходящийДокумент
			FROM Stg._1cDCMNT.РегистрСведений_КМ_ЗаданияНарезкиЕдиныйСкан AS Задания
			WHERE Задания.ДатаДобавления >= dateadd(year, 2000, @dateAdd)

			DROP TABLE IF EXISTS #t_Ссылка_3
			CREATE TABLE #t_Ссылка_3(Ссылка binary(16))

			INSERT #t_Ссылка_3(Ссылка)
			SELECT км_ФайлыРаспознавание.Ссылка
			FROM Stg._1cDCMNT.Справочник_ВходящиеДокументы_КМ_ФайлыРаспознавание AS км_ФайлыРаспознавание
			WHERE км_ФайлыРаспознавание.Дата >= dateadd(year,2000, @dateFile)


			INSERT #t_Ссылка(Ссылка)
			SELECT T.Ссылка FROM #t_Ссылка_1 AS T
			UNION
			SELECT T.Ссылка FROM #t_Ссылка_2 AS T
			UNION
			SELECT T.Ссылка FROM #t_Ссылка_3 AS T

			CREATE INDEX ix_Ссылка ON #t_Ссылка(Ссылка)
		END	

		IF @isDebug = 1 BEGIN
			select rowVersion = @rowVersion

			DROP TABLE IF EXISTS ##t_Ссылка
			SELECT * INTO ##t_Ссылка FROM #t_Ссылка
		END


		DROP TABLE IF EXISTS #t_document_cutting

		select 
			created_at = getdate()
			,ВходящиеДокументы_Ссылка = вд.Ссылка
			,Номер_Вх_Документа = вд.[РегистрационныйНомер] --документ, где "Вид корреспонденции" = Единый скан СП/ИП
			,Вид_Корреспонденции = ВидКорреспонденции.Наименование
			,Дата_Вх_Документа = dateadd(year,-2000, вд.[ДатаРегистрации])--документ, где "Вид корреспонденции" = Единый скан СП/ИП
			,ВнутренниеДокументы_Наименование = ВнутренниеДокументы.Наименование
			,Номер_Договора = cast(NULL AS nvarchar(20)) --заполняется только в случае заполненности поля в карточке вх. документа где "Видкорреспонденции" = Единый скан СП/ИП в ЭДО 
			,ФИО_клиента = Контрагенты.НаименованиеПолное
			,Количество_документов = вд.КМ_КоличествоДокументовЕдиныйСкан --Указывается кол-во входящих документов в карточке вх. документа где "Вид корреспонденции" = Единый скан СП/ИП в ЭДО 
			,Список_документов = документы_на_нарезку.Документы --Что отмечено галочками в  карточке вх. документа где "Вид корреспонденции" = Единый скан СП/ИП в ЭДО 
			,Всего_документов = isnull(ЗаданияНарезкиЕдиныйСкан.[распознано успешно],0) + isnull(км_ФайлыРаспознавание.[Кол.Документов],0)
			,Через_сервис = isnull(ЗаданияНарезкиЕдиныйСкан.[распознано успешно] ,0)
			,Вручную = isnull(км_ФайлыРаспознавание.[Кол.Документов],0)
			,Из_них_не_разрезано =isnull(ЗаданияНарезкиЕдиныйСкан.[В очереди],0)
			--
			,ВходящиеДокументы_ВерсияДанных = вд.ВерсияДанных
			,ЗаданияНарезкиЕдиныйСкан_ДатаДобавления = dateadd(year,-2000, ЗаданияНарезкиЕдиныйСкан.ДатаДобавления)
			,ФайлыРаспознавание_Дата = dateadd(year,-2000, км_ФайлыРаспознавание.Дата)

		INTO #t_document_cutting
		FROM #t_Ссылка AS T
			INNER JOIN Stg._1cDCMNT.Справочник_ВходящиеДокументы AS вд
				ON вд.Ссылка = T.Ссылка
			inner join Stg._1cDCMNT.Справочник_КМ_ВидыКорреспонденции AS ВидКорреспонденции
				ON ВидКорреспонденции.Ссылка = вд.КМ_ВидКорреспонденции
			left join (
				select 
					pvt.ВходящийДокумент
					,pvt.ДатаДобавления
					,[В очереди] =			 isnull(sum([В очереди]),0)
					,[распознано успешно] = isnull(sum([Распознано успешно]),0)
					,[не распознано] =		 isnull(sum([Не распознано]),0)
				from (
					SELECT 
						задание.ВходящийДокумент
						,Результат = case Результат 
							when 0 then 'В очереди'
							when 1 then 'распознано успешно'
							when 2 then 'не распознано'
						end
						,[Кол.Документов] = count(1)
						,ДатаДобавления = max(ДатаДобавления)
					from Stg._1cDCMNT.РегистрСведений_КМ_ЗаданияНарезкиЕдиныйСкан AS задание
						INNER JOIN #t_Ссылка AS T2
							ON T2.Ссылка = задание.ВходящийДокумент
					group by ВходящийДокумент, Результат
					) t
				pivot (
					SUM([Кол.Документов]) FOR Результат IN ([В очереди], [Распознано успешно], [Не распознано])
					) pvt
				group by pvt.ВходящийДокумент, pvt.ДатаДобавления
			) AS ЗаданияНарезкиЕдиныйСкан 
			ON ЗаданияНарезкиЕдиныйСкан.ВходящийДокумент = вд.Ссылка

			left join (
				SELECT 
					ВходящиеДокументы_Ссылка = ФайлыРаспознавание.Ссылка
					,[Кол.Документов] = count(1)
					,Дата = max(ФайлыРаспознавание.Дата)
				from Stg._1cDCMNT.Справочник_ВходящиеДокументы_КМ_ФайлыРаспознавание AS ФайлыРаспознавание
					INNER join Stg._1cDCMNT.Справочник_КМ_ВидыКорреспонденции AS ВидыКорреспонденции
						ON ВидыКорреспонденции.Ссылка = ФайлыРаспознавание.ВидКорреспонденции
					INNER JOIN #t_Ссылка AS T3
						ON T3.Ссылка = ФайлыРаспознавание.Ссылка
				group by ФайлыРаспознавание.Ссылка
			) AS км_ФайлыРаспознавание
			ON км_ФайлыРаспознавание.ВходящиеДокументы_Ссылка = вд.Ссылка
	
			left join 
			(
				select 
					ВходящиеДокумент = вд2.Ссылка
					,[Кол.Документов] = count(1)
					,Документы = string_agg(вк.Наименование,';')
				from Stg._1cDCMNT.Справочник_ВходящиеДокументы_КМ_ВидыКорреспонденции AS вд2
					INNER join Stg._1cDCMNT.Справочник_КМ_ВидыКорреспонденции AS вк
						ON вк.Ссылка = вд2.ВидКорреспонденции
					INNER JOIN #t_Ссылка AS T4
						ON T4.Ссылка = вд2.Ссылка
				where Использование = 0x01
				group by вд2.Ссылка
			) AS документы_на_нарезку
			ON документы_на_нарезку.ВходящиеДокумент = вд.Ссылка

			LEFT JOIN Stg._1cDCMNT.Справочник_ВнутренниеДокументы AS ВнутренниеДокументы
				ON ВнутренниеДокументы.Ссылка = вд.КМ_Договор

			LEFT JOIN Stg._1cDCMNT.Справочник_Контрагенты AS Контрагенты
				ON Контрагенты.Ссылка = вд.КМ_Контрагент

		where 1=1-- документ, где "Вид корреспонденции" = Единый скан СП/ИП
			AND ВидКорреспонденции.Наименование in ('Единый скан СП/ИП'
			, 'Единый скан СП/ИП_разреза'
			, 'Единый скан СП/ИП_разрезанный'
			)
			

		UPDATE D 
		SET D.Номер_Договора = cast(G.value AS nvarchar(20))
		FROM #t_document_cutting AS D
			INNER JOIN (
				SELECT T.ВходящиеДокументы_Ссылка, A.value, A.rn
				FROM #t_document_cutting AS T
					OUTER APPLY (
						SELECT F.*, rn = row_number() OVER(ORDER BY getdate()) 
						FROM string_split(T.ВнутренниеДокументы_Наименование, '|') AS F
					) AS A
				) AS G
				ON G.ВходящиеДокументы_Ссылка = D.ВходящиеДокументы_Ссылка
				AND G.rn = 2

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_document_cutting
			SELECT * INTO ##t_document_cutting FROM #t_document_cutting
		END

		CREATE INDEX ix_Ссылка ON #t_document_cutting(ВходящиеДокументы_Ссылка)

		
		IF object_id('collection.document_cutting') IS NULL
		BEGIN
			SELECT TOP(0)
				created_at,
				ВходящиеДокументы_Ссылка,
				Номер_Вх_Документа,
				Вид_Корреспонденции,
				Дата_Вх_Документа,
				--ВнутренниеДокументы_Наименование,
				Номер_Договора,
				ФИО_клиента,
				Количество_документов,
				Список_документов,
				Всего_документов,
				Через_сервис,
				Вручную,
				Из_них_не_разрезано,
				ВходящиеДокументы_ВерсияДанных,
				ЗаданияНарезкиЕдиныйСкан_ДатаДобавления,
				ФайлыРаспознавание_Дата
			INTO collection.document_cutting
			FROM #t_document_cutting

			--alter table collection.document_cutting
			--	alter column response_Id bigint not null

			--ALTER TABLE collection.document_cutting
			--	ADD CONSTRAINT PK_dm_pravoRuBankruptcy PRIMARY KEY CLUSTERED (GuidЗаявки, Этап)

			CREATE INDEX ix_Ссылка ON collection.document_cutting(ВходящиеДокументы_Ссылка)
			CREATE INDEX ix_ВерсияДанных ON collection.document_cutting(ВходящиеДокументы_ВерсияДанных)
			CREATE INDEX ix_ДатаДобавления ON collection.document_cutting(ЗаданияНарезкиЕдиныйСкан_ДатаДобавления)
			CREATE INDEX ix_ФайлыРаспознавание_Дата ON collection.document_cutting(ФайлыРаспознавание_Дата)
		END

		BEGIN TRAN
			DELETE C
			FROM collection.document_cutting AS C
			WHERE EXISTS(
					SELECT TOP(1) 1
					FROM #t_document_cutting AS R
					WHERE R.ВходящиеДокументы_Ссылка = C.ВходящиеДокументы_Ссылка
				)

			INSERT collection.document_cutting
			(
				created_at,
				ВходящиеДокументы_Ссылка,
				Номер_Вх_Документа,
				Вид_Корреспонденции,
				Дата_Вх_Документа,
				--ВнутренниеДокументы_Наименование,
				Номер_Договора,
				ФИО_клиента,
				Количество_документов,
				Список_документов,
				Всего_документов,
				Через_сервис,
				Вручную,
				Из_них_не_разрезано,
				ВходящиеДокументы_ВерсияДанных,
				ЗаданияНарезкиЕдиныйСкан_ДатаДобавления,
				ФайлыРаспознавание_Дата
			)
			SELECT
				created_at,
				ВходящиеДокументы_Ссылка,
				Номер_Вх_Документа,
				Вид_Корреспонденции,
				Дата_Вх_Документа,
				--ВнутренниеДокументы_Наименование,
				Номер_Договора,
				ФИО_клиента,
				Количество_документов,
				Список_документов,
				Всего_документов,
				Через_сервис,
				Вручную,
				Из_них_не_разрезано,
				ВходящиеДокументы_ВерсияДанных,
				ЗаданияНарезкиЕдиныйСкан_ДатаДобавления,
				ФайлыРаспознавание_Дата
			FROM #t_document_cutting
		COMMIT

		/*
		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName, 
			@eventType = @eventType, 
			@message = @message, 
			@SendEmail = @SendEmail, 
			@ProcessGUID = @ProcessGUID
		*/
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка заполнения dwh2.collection.document_cutting'

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

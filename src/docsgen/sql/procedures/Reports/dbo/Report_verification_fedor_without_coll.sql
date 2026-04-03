/*
exec Reports.dbo.Report_verification_fedor_without_coll 
	@Page = 'KD.Detail'
	 ,@dtFrom  = '2024-09-01'
	,@dtTo = '2024-09-10' 
	,@isDebug = 1
	 , date =  null --'2021-04-26'
	 ,@ProcessGUID varchar(36) = NULL -- guid процесса
	 ,c int = 0
	with recompile

exec Reports.dbo.Report_verification_fedor_without_coll 'KD.Monthly.ALL'
exec Reports.dbo.Report_verification_fedor_without_coll 'KD.Daily.ALL'

exec Reports.dbo.Report_verification_fedor_without_coll 'KD.Detail'

exec Reports.dbo.Report_verification_fedor_without_coll 'KD.Daily.Common'
exec Reports.dbo.Report_verification_fedor_without_coll 'KD.Monthly.Common'

exec Reports.dbo.Report_verification_fedor_without_coll 'PSV.Monthly.ALL'
exec Reports.dbo.Report_verification_fedor_without_coll 'PSV.Daily.ALL'

exec Reports.dbo.Report_verification_fedor_without_coll 'PSV.Detail'

exec Reports.dbo.Report_verification_fedor_without_coll 'PSV.Daily.Common'
exec Reports.dbo.Report_verification_fedor_without_coll 'PSV.Monthly.Common'

exec Reports.dbo.Report_verification_fedor_without_coll 'KD.HoursGroupMonth'
exec Reports.dbo.Report_verification_fedor_without_coll 'KD.HoursGroupMonthUnique'
exec Reports.dbo.Report_verification_fedor_without_coll 'KD.HoursGroupDays'
exec Reports.dbo.Report_verification_fedor_without_coll 'KD.HoursGroupDaysUnique'

*/

CREATE PROC dbo.Report_verification_fedor_without_coll
--declare
  @Page nvarchar(100) = 'KD.Monthly.Common'
  ,@dtFrom date = null -- '2021-04-01'
  ,@dtTo date =  null --'2021-04-26'
  ,@ProcessGUID varchar(36) = NULL -- guid процесса
  --,@ProductTypeCode varchar(1000) = 'installment,pdl' --bigInstallment
	----DWH-410 Теперь параметр @ProductTypeCode - означает ГРУППУ продуктов 
  ,@ProductTypeCode varchar(1000) = 'Installment' --bigInstallment
  ,@isDebug int = 0
AS
BEGIN

	SET NOCOUNT ON;

BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @ProductTypeCode = isnull(@ProductTypeCode, 'Installment')

	--DWH-410 Теперь в таблицу @t_ProductTypeCode пишем ПодТип продукта (было - Тип продукта)
	DECLARE @t_ProductTypeCode table(ProductTypeCode varchar(55))

	IF @ProductTypeCode IS NOT NULL BEGIN
		INSERT @t_ProductTypeCode(ProductTypeCode)
		--select ProductTypeCode = trim(value) 
		--FROM string_split(@ProductTypeCode, ',')
		select v.ПодтипПродуктd_Code
		from dwh2.hub.v_hub_ГруппаПродуктов as v
		where v.ГруппаПродуктов_Code = @ProductTypeCode
			--хардкод 
			and v.ПодтипПродуктd_Code not in ('smart-installment')
	END

	IF @Page = 'empty' BEGIN
		--SELECT ProcessGUID = @ProcessGUID
		RETURN 0
	END

	DECLARE @EventDateTime datetime
	DECLARE @delay varchar(12)
	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @isFill_All_Tables bit = 0
	declare @localProcessGUID varchar(36)

	IF @ProcessGUID IS NOT NULL
		AND @Page = 'Fill_All_Tables'
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--идет процесс заполнения или выборки таблиц
			RETURN 0
		END
		ELSE BEGIN
			BEGIN TRY
				--BEGIN TRAN

				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), @Page, @ProcessGUID

				--COMMIT
			END TRY
			BEGIN CATCH
				SELECT @error_number = ERROR_NUMBER()
				SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
					+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
					+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

				IF @error_number = 2601 --Cannot insert duplicate key row in object
				BEGIN
					-- параллельный процесс уже начал заполнение
					RETURN 0
				END
				ELSE BEGIN
					;THROW 51000, @description, 1
				END
			END CATCH
		END
	END


	IF @ProcessGUID IS NOT NULL
		AND @Page NOT IN ('Fill_All_Tables', 'Clear_All_Tables')
	BEGIN
		IF NOT EXISTS(
			SELECT TOP 1 1
			FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--таблица для @Page НЕ заполнена
			--вызвать заполнение всех таблиц и ждать

			SELECT @delay = '00:00:00.' + convert(varchar(3), round(1000 * rand(), 0))
			WAITFOR DELAY @delay


		    EXEC dbo.Report_verification_fedor_without_coll
				@Page = 'Fill_All_Tables', 
				@dtFrom = @dtFrom,
				@dtTo = @dtTo,
				@ProcessGUID = @ProcessGUID,
				@ProductTypeCode = @ProductTypeCode


			SELECT @EventDateTime = getdate()

			WHILE 
				-- НЕ появились данные для @Page
				NOT EXISTS(
					SELECT TOP 1 1
					FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F
					WHERE F.ReportPage = @Page
						AND F.ProcessGUID = @ProcessGUID
				)
				-- И не превышено время ожидания
				AND datediff(SECOND, @EventDateTime, getdate()) < 1800 --600 30min
			BEGIN
				WAITFOR DELAY '00:00:10'
			END

			-- превышено время ожидания
			IF datediff(SECOND, @EventDateTime, getdate()) >= 1800 --600 30min
			BEGIN
				--вернуть ошибку
				;THROW 51000, 'Превышено время ожидания заполнения всех таблиц (30 минут).', 1
			END
		END

		--вернуть данные
	END


	SELECT @message = concat(
		'EXEC dbo.Report_verification_fedor_without_coll ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@ProductTypeCode=', iif(@ProductTypeCode IS NULL, 'NULL', ''''+@ProductTypeCode+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @description =
		(
		SELECT
			'@Page' = @Page,
			'@dtFrom' = @dtFrom,
			'@dtTo' = @dtTo,
			'@ProcessGUID' = @ProcessGUID
			--'@isDebug' = @isDebug,
			--'suser_sname' = suser_sname(),
			--'app_name' = app_name()
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
		)

	SELECT @eventType = concat(@Page, ' START') 

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_fedor_without_coll',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID

	IF @ProcessGUID IS NULL BEGIN
		IF @Page = 'Fill_All_Tables' BEGIN
			--SELECT ProcessGUID = @ProcessGUID
			RETURN 0
		END

		IF @Page = 'Clear_All_Tables' BEGIN
			--SELECT ProcessGUID = @ProcessGUID
			RETURN 0
		END
	END
	-- @ProcessGUID IS NOT NULL 
	ELSE BEGIN

		IF @Page = 'Fill_All_Tables' BEGIN
			SELECT @isFill_All_Tables = 1
		END

		IF @Page = 'KD.Monthly.Common' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END
	
		IF @Page = 'KD.Daily.Common' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END

		IF @Page = 'KD.Detail' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Detail AS T
			WHERE T.ProcessGUID = @ProcessGUID
			ORDER BY T.[ФИО сотрудника верификации/чекер] asc, T.[Дата заведения заявки] desc, T.[Время заведения] desc
		END


		IF @Page = 'KD.HoursGroupDays' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END
		IF @Page = 'KD.HoursGroupMonth' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END
		IF @Page = 'KD.HoursGroupDaysUnique' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDaysUnique AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END
		IF @Page = 'KD.HoursGroupMonthUnique' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonthUnique AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END

		--
		IF @Page = 'PSV.Daily.Common' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END

		IF @Page = 'PSV.Monthly.Common' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END

		IF @Page = 'PSV.Detail' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Detail AS T
			WHERE T.ProcessGUID = @ProcessGUID
			ORDER BY T.[ФИО сотрудника верификации/чекер] asc, T.[Дата заведения заявки] desc, T.[Время заведения] desc
		END
		--

		IF @Page = 'KD.Monthly.ALL' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END

		IF @Page = 'PSV.Monthly.ALL' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END


		IF @Page = 'KD.Daily.ALL' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END

		IF @Page = 'PSV.Daily.ALL' BEGIN
			SELECT T.*
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID
		END


		IF @Page NOT IN ('Fill_All_Tables', 'Clear_All_Tables')
		BEGIN
			IF EXISTS(
				SELECT TOP 1 1
				FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F
				WHERE F.ReportPage = @Page
					AND F.ProcessGUID = @ProcessGUID
				)
			BEGIN
				--таблица для @Page заполнена
				--почистить Fill
				--BEGIN TRAN

				DELETE F
				FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F 
				WHERE F.ReportPage = @Page AND F.ProcessGUID = @ProcessGUID

				-- если это последний вызов (нет больше записей, кроме 'Fill_All_Tables'),
				-- удалить запись 'Fill_All_Tables'
				IF NOT EXISTS(
					SELECT TOP 1 1
					FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F
					WHERE F.ReportPage <> 'Fill_All_Tables'
						AND F.ProcessGUID = @ProcessGUID
				)
				AND EXISTS(
					SELECT TOP 1 1
					FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F
					WHERE F.ReportPage = 'Fill_All_Tables'
						AND F.ProcessGUID = @ProcessGUID
						AND F.EndDateTime IS NOT NULL
				)
				--EndDateTime
				BEGIN
					DELETE F
					FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F 
					WHERE F.ReportPage = 'Fill_All_Tables' AND F.ProcessGUID = @ProcessGUID

					--очистить все таблицы
					EXEC dbo.Report_verification_fedor_without_coll
						@Page = 'Clear_All_Tables', 
						@dtFrom = @dtFrom,
						@dtTo = @dtTo,
						@ProcessGUID = @ProcessGUID,
						@ProductTypeCode = @ProductTypeCode
				END

				--COMMIT
			END

			RETURN 0
		END


		--------------------------------------------------------------
		IF @Page = 'Clear_All_Tables' BEGIN
			-- очистить все таблицы
			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Detail AS T
			WHERE T.ProcessGUID = @ProcessGUID


			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDaysUnique AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonthUnique AS T
			WHERE T.ProcessGUID = @ProcessGUID


			--
			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_Common AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Detail AS T
			WHERE T.ProcessGUID = @ProcessGUID


			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID


			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID

			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID


			--SELECT ProcessGUID = @ProcessGUID

			RETURN 0
		END
	END




	declare @dt_from date
	if @dtFrom is not null
		set @dt_from=@dtFrom
	else set @dt_from=format(getdate(),'yyyyMM01')

	declare @dt_to date
	if @dtTo is not null
		set @dt_to=dateadd(day,1,@dtTo)
	else set @dt_to=dateadd(day,1,cast(getdate() as date))

    declare @dt_from_hours datetime = @dt_from
	declare @dt_to_hours datetime = @dt_to

	DROP TABLE IF EXISTS #t_ProductType
	CREATE TABLE #t_ProductType(
		ProductType_Code varchar(100),
		ProductType_Name varchar(100),
		ProductType_Order int
	)

	/*
	if @ProductTypeCode = 'installment,pdl'
	begin
		INSERT #t_ProductType
		(
			ProductType_Code,
			ProductType_Name,
			ProductType_Order
		)
		VALUES 
			('ALL', 'БЕЗЗАЛОГ', 1),
			('installment', 'ИНСТОЛМЕНТ', 2),
			('pdl', 'PDL', 3)
	end
	else begin
		INSERT #t_ProductType
		(
			ProductType_Code,
			ProductType_Name,
			ProductType_Order
		)
		select 
			ProductType_Code = t.ProductTypeCode,
			ProductType_Name = pt.Name collate Cyrillic_General_CI_AS,
			ProductType_Order = 1 + row_number() over(order by t.ProductTypeCode)
		from @t_ProductTypeCode as t
			inner join Stg._fedor.dictionary_ProductType AS pt
				on pt.Code collate Cyrillic_General_CI_AS = t.ProductTypeCode
	end
	*/

	INSERT #t_ProductType
	(
		ProductType_Code,
		ProductType_Name,
		ProductType_Order
	)
	--select 
	--	ProductType_Code = t.ProductTypeCode,
	--	ProductType_Name = pt.Name collate Cyrillic_General_CI_AS,
	--	ProductType_Order = 1 + row_number() over(order by t.ProductTypeCode)
	--from @t_ProductTypeCode as t
	--	inner join Stg._fedor.dictionary_ProductType AS pt
	--		on pt.Code collate Cyrillic_General_CI_AS = t.ProductTypeCode
	--DWH-410 разбивка показателей по ПодТипу продукта
	select 
		ProductType_Code = t.ProductTypeCode,
		ProductType_Name = pst.Name collate Cyrillic_General_CI_AS,
		ProductType_Order = 1 + row_number() over(order by t.ProductTypeCode)
	from @t_ProductTypeCode as t
		inner join Stg._fedor.dictionary_ProductSubType AS pst
			on pst.Code collate Cyrillic_General_CI_AS = t.ProductTypeCode

	--заменить ВсёПро100 на ИНСТОЛМЕНТ
	update pt 
	set ProductType_Name = 'ИНСТОЛМЕНТ'
	from #t_ProductType as pt
	where pt.ProductType_Name = 'ВсёПро100'

	--заменить 'Big Installment' на 'Big Installment ПСБ'
	update pt 
	set ProductType_Name = 'Big Installment ПСБ'
	from #t_ProductType as pt
	where pt.ProductType_Name = 'Big Installment'


	DROP TABLE IF EXISTS #t_check_type_result
	CREATE TABLE #t_check_type_result
	(
		check_type_name varchar(255),
		result_name varchar(255),
		isSuccess int
	)

	INSERT #t_check_type_result
	(
	    check_type_name,
	    result_name,
	    isSuccess
	)
	SELECT DISTINCT
		check_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS,
		result_name = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS,
		isSuccess = 
			CASE CheckListItemType.Name
				WHEN 'Проверка дохода'
				THEN 
					CASE 
						WHEN CheckListItemStatus.Name IN (
							'Данные из справки о доходе перенесены в Федор',
							'Данные из документа подтверждающего доход перенесены в Федор'
							--'Документ не приложен или плохое качество',
							--'Документ не соответствует требованиям', 
							--'Документы не приложены или имеют плохое (нечитаемое) качество',
							--'Подозрение в мошенничестве: поддельная информация о доходе',
							--'Проверка не проводилась (системная)'
						)
						THEN 1
						ELSE 0
					END
				--
				ELSE 0
			END
	FROM Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
		INNER JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
			ON CH_IT_IS.IdType = CheckListItemType.Id
		INNER JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
			ON CheckListItemStatus.Id = CH_IT_IS.IdCheckListItemStatus
	WHERE CheckListItemType.Name IN ('Проверка дохода')
	-- проверка назначена, но еще не выполнена
	UNION SELECT 'Проверка дохода','назначен', 0


	drop table if exists #t_dm_FedorVerificationRequests_without_coll
	CREATE TABLE #t_dm_FedorVerificationRequests_without_coll
	(
		[ProductType_Code] [varchar](100) NULL,
		IdClientRequest uniqueidentifier,
		[Дата заведения заявки] [date] NULL,
		[Время заведения] [time](7) NULL,
		[Номер заявки] [nvarchar](50) NULL,
		[ФИО клиента] [nvarchar](255) NULL,
		[Статус] [nvarchar](100) NULL,
		[Задача] [nvarchar](100) NULL,
		[Состояние заявки] [nvarchar](50) NULL,
		[Дата статуса] [datetime2](7) NULL,
		[Дата след.статуса] [datetime2](7) NULL,
		[ФИО сотрудника верификации/чекер] [nvarchar](255) NOT NULL,
		[ВремяЗатрачено] [decimal](16, 10) NULL,
		[Время, час:мин:сек] [datetime] NULL,
		[Статус следующий] [nvarchar](100) NULL,
		[Задача следующая] [nvarchar](100) NULL,
		[Состояние заявки следующая] [nvarchar](50) NULL,
		[ПричинаНаим_Исх] [int] NULL,
		[ПричинаНаим_След] [int] NULL,
		[Последнее состояние заявки на дату по сотруднику] [nvarchar](50) NULL,
		[Последний статус заявки на дату по сотруднику] [nvarchar](100) NULL,
		[Последний статус заявки на дату] [nvarchar](100) NULL,
		[СотрудникПоследнегоСтатуса] [nvarchar](100) NULL,
		[ШагЗаявки] [bigint] NULL,
		[ПоследнийШаг] [bigint] NULL,
		[Последний статус заявки] [nvarchar](100) NULL,
		[Время в последнем статусе] [decimal](16, 10) NULL,
		[Время в последнем статусе, hh:mm:ss] [nvarchar](100) NULL,
		[ВремяЗатраченоОжиданиеВерификацииКлиента] [decimal](16, 10) NULL,
		[ПризнакИсключенияСотрудника] [int] NOT NULL,
		[Работник] [nvarchar](100) NOT NULL,
		[Назначен] [nvarchar](100) NOT NULL,
		[Работник_Пред] [nvarchar](100) NULL,
		[Назначен_Пред] [nvarchar](100) NULL,
		[Работник_След] [nvarchar](100) NULL,
		[Назначен_След] [nvarchar](100) NULL,
		ТипКлиента varchar(30) NULL,
		isSkipped bit NULL,
		Партнер varchar(50),
		ПроверкаДохода int NULL,
		[Тип документа подтверждающего доход] varchar(500),
		КодТипКредитногоПродукта varchar(100),
		КодПодТипКредитногоПродукта varchar(100),
		РегионПроживания varchar(255),
		РегионПроживания_НовыйРегион int,
		РегионРегистрации varchar(255),
		РегионРегистрации_НовыйРегион int
	)

	--v.2
	INSERT #t_dm_FedorVerificationRequests_without_coll
	(
		[ProductType_Code],
		IdClientRequest,
	    [Дата заведения заявки],
	    [Время заведения],
	    [Номер заявки],
	    [ФИО клиента],
	    Статус,
	    Задача,
	    [Состояние заявки],
	    [Дата статуса],
	    [Дата след.статуса],
	    [ФИО сотрудника верификации/чекер],
	    ВремяЗатрачено,
	    [Время, час:мин:сек],
	    [Статус следующий],
	    [Задача следующая],
	    [Состояние заявки следующая],
	    ПричинаНаим_Исх,
	    ПричинаНаим_След,
	    [Последнее состояние заявки на дату по сотруднику],
	    [Последний статус заявки на дату по сотруднику],
	    [Последний статус заявки на дату],
	    СотрудникПоследнегоСтатуса,
	    ШагЗаявки,
	    ПоследнийШаг,
	    [Последний статус заявки],
	    [Время в последнем статусе],
	    [Время в последнем статусе, hh:mm:ss],
	    ВремяЗатраченоОжиданиеВерификацииКлиента,
	    ПризнакИсключенияСотрудника,
	    Работник,
	    Назначен,
	    Работник_Пред,
	    Назначен_Пред,
	    Работник_След,
	    Назначен_След,
		ТипКлиента,
		isSkipped,
		Партнер,
		ПроверкаДохода,
		[Тип документа подтверждающего доход],
		КодТипКредитногоПродукта,
		КодПодТипКредитногоПродукта,
		РегионПроживания,
		РегионПроживания_НовыйРегион,
		РегионРегистрации,
		РегионРегистрации_НовыйРегион
	)
	SELECT
		--R.ProductType_Code,
		--DWH-410
		ProductType_Code = isnull(R.КодПодТипКредитногоПродукта, R.КодТипКредитногоПродукта),
		R.IdClientRequest,
		R.[Дата заведения заявки],
        R.[Время заведения],
        R.[Номер заявки],
        R.[ФИО клиента],
        R.Статус,
        R.Задача,
        R.[Состояние заявки],
        R.[Дата статуса],
        R.[Дата след.статуса],
        R.[ФИО сотрудника верификации/чекер],
        R.ВремяЗатрачено,
        R.[Время, час:мин:сек],
        R.[Статус следующий],
        R.[Задача следующая],
        R.[Состояние заявки следующая],
        R.ПричинаНаим_Исх,
        R.ПричинаНаим_След,
        R.[Последнее состояние заявки на дату по сотруднику],
        R.[Последний статус заявки на дату по сотруднику],
        R.[Последний статус заявки на дату],
        R.СотрудникПоследнегоСтатуса,
        R.ШагЗаявки,
        R.ПоследнийШаг,
        R.[Последний статус заявки],
        R.[Время в последнем статусе],
        R.[Время в последнем статусе, hh:mm:ss],
        R.ВремяЗатраченоОжиданиеВерификацииКлиента,
        R.ПризнакИсключенияСотрудника,
        R.Работник,
        R.Назначен,
        R.Работник_Пред,
        R.Назначен_Пред,
        R.Работник_След,
        R.Назначен_След,
		R.ТипКлиента,
		R.isSkipped,
		R.Партнер,
		--ПроверкаДохода = chtr.isSuccess,
		ПроверкаДохода = case when R.ПроверкаДохода is not null then 1 else null end,
		R.[Тип документа подтверждающего доход],
		R.КодТипКредитногоПродукта,
		R.КодПодТипКредитногоПродукта,
		R.РегионПроживания,
		R.РегионПроживания_НовыйРегион,
		R.РегионРегистрации,
		R.РегионРегистрации_НовыйРегион
	FROM Reports.dbo.dm_FedorVerificationRequests_without_coll AS R --(NOLOCK)
		LEFT JOIN #t_check_type_result AS chtr
			ON chtr.check_type_name = 'Проверка дохода'
			AND chtr.result_name = R.ПроверкаДохода
	WHERE 1=1
		AND R.[Дата статуса] >= @dt_from
		AND R.[Дата статуса] < @dt_to
		--and isnull(R.КодТипКредитногоПродукта, '') IN (SELECT ProductTypeCode FROM @t_ProductTypeCode)
		--DWH-410
		and isnull(R.КодПодТипКредитногоПродукта, R.КодТипКредитногоПродукта) IN (
			SELECT ProductTypeCode FROM @t_ProductTypeCode
			)

	--удалить из справочника типы, которых нет в данных
	delete pt
	from #t_ProductType as pt
		left join (
			select distinct d.ProductType_Code
			from #t_dm_FedorVerificationRequests_without_coll as d
		) as x
		on x.ProductType_Code = pt.ProductType_Code
	where x.ProductType_Code is null

	-- если отчет строится по нескольким типам продукта
	-- добавить суммарные показатели
	if (select count(*) from @t_ProductTypeCode as t) > 1
	begin
		INSERT #t_ProductType
		(
			ProductType_Code,
			ProductType_Name,
			ProductType_Order
		)
		--VALUES ('ALL', 'БЕЗЗАЛОГ', 1)
		select 
			ProductType_Code = 'ALL', 
			ProductType_Name = concat(
				'БЕЗЗАЛОГ', 
				case 
					when @ProductTypeCode not in ('Installment')
					then concat(' ', upper(substring(@ProductTypeCode,1,6)))
					else ''
				end
			),
			ProductType_Order = 1
	end

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ProductType
		SELECT * INTO ##t_ProductType FROM #t_ProductType
	END


	/*
	Корнеева Вероника Игоревна
	сменила фамилию на
	Столица Вероника Игоревна
	*/
	UPDATE T
	SET 
		[ФИО сотрудника верификации/чекер] = replace([ФИО сотрудника верификации/чекер], 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
		СотрудникПоследнегоСтатуса = replace(СотрудникПоследнегоСтатуса, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
		Работник = replace(Работник, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
		Назначен = replace(Назначен, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
		Работник_Пред = replace(Работник_Пред, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
		Назначен_Пред = replace(Назначен_Пред, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
		Работник_След = replace(Работник_След, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
		Назначен_След = replace(Назначен_След, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна')
	FROM #t_dm_FedorVerificationRequests_without_coll AS T

	CREATE INDEX ix1 ON #t_dm_FedorVerificationRequests_without_coll([Номер заявки], [Дата статуса]) INCLUDE([Статус следующий], ProductType_Code)
	CREATE INDEX ix2 ON #t_dm_FedorVerificationRequests_without_coll(ProductType_Code, [Номер заявки])

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_dm_FedorVerificationRequests_without_coll
		SELECT * INTO ##t_dm_FedorVerificationRequests_without_coll FROM #t_dm_FedorVerificationRequests_without_coll
	END

	SELECT top(0) * 
	INTO #t_dm_FedorVerificationRequests_without_coll_ALL
	FROM #t_dm_FedorVerificationRequests_without_coll

	--Все типы продуктов
	--if @ProductTypeCode = 'installment,pdl' 
	-- если отчет строится по нескольким типам продукта
	-- добавить суммарные показатели
	if (select count(*) from @t_ProductTypeCode as t) > 1
	begin
		INSERT #t_dm_FedorVerificationRequests_without_coll_ALL
		SELECT * 
		FROM #t_dm_FedorVerificationRequests_without_coll

		UPDATE D
		SET D.ProductType_Code = 'ALL'
		FROM #t_dm_FedorVerificationRequests_without_coll_ALL AS D
	end

	INSERT #t_dm_FedorVerificationRequests_without_coll_ALL
	SELECT * 
	FROM #t_dm_FedorVerificationRequests_without_coll

	CREATE INDEX ix1 ON #t_dm_FedorVerificationRequests_without_coll_ALL([Номер заявки], [Дата статуса]) 
	INCLUDE([Статус следующий], ProductType_Code)

	CREATE INDEX ix2 ON #t_dm_FedorVerificationRequests_without_coll_ALL([Дата статуса])
	INCLUDE ([ProductType_Code],[Дата заведения заявки],[Номер заявки])

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_dm_FedorVerificationRequests_without_coll_ALL
		SELECT * INTO ##t_dm_FedorVerificationRequests_without_coll_ALL FROM #t_dm_FedorVerificationRequests_without_coll_ALL
	END
	--//Все типы продуктов


	drop table if exists #curr_employee_test
	create table #curr_employee_test([Employee] nvarchar(255))

	INSERT #curr_employee_test(Employee)
	--select *
	--select substring(trim(U.DisplayName), 1, 255)
	--FROM [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers] AS U
	--where U.Department ='Отдел тестирования'
	--and u.DomainAccount !='r.mekshinev' -- перешел в отдел тестирование из отдела верификации
	--UNION
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
	WHERE U.IsQAUser = 1

	DELETE R
	FROM #t_dm_FedorVerificationRequests_without_coll AS R
	WHERE 1=1
		AND R.Работник IN (SELECT Employee FROM #curr_employee_test)


	DELETE R
	FROM #t_dm_FedorVerificationRequests_without_coll AS R
	WHERE 1=1
		AND R.[ФИО сотрудника верификации/чекер] IN (SELECT Employee FROM #curr_employee_test)


	CREATE CLUSTERED INDEX clix1 
	ON #t_dm_FedorVerificationRequests_without_coll([Номер заявки], [Дата статуса], ProductType_Code)

	-- получим список часов и дней в интревале
	drop table if exists #HoursDays
	;WITH cte
	AS (select @dt_from_hours AS Today

	UNION ALL

	SELECT dateadd(hour, 1, Today) AS Today
	FROM cte
	WHERE dateadd(hour, 1,Today) < @dt_to_hours 
	)
	SELECT datepart(hour,Today ) Интервал, cast(Today  as date) Дата, datepart(hour,dateadd(hour, 1,Today )) ИнтервалPlus, '00:00 - 01:               ' ИнтервалСтрока
	into #HoursDays
	FROM cte
	--OPTION (MAXRECURSION 2210)
	OPTION (MAXRECURSION 0)

	update #HoursDays Set ИнтервалСтрока = Format(Интервал ,'00') + ':00 - ' + Format(ИнтервалPlus,'00')  + ':00'

	insert into #HoursDays
	select 25 as Интервал,  Дата, '' as Интервал,  'Итого:' ИнтервалСтрока
	from #HoursDays 
	group by Дата


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##HoursDays
		SELECT * INTO ##HoursDays FROM #HoursDays
	END

	-- статические справочники
	--select  distinct [ФИО сотрудника верификации/чекер] from #t_dm_FedorVerificationRequests_without_coll
	--insert into  feodor.dbo.KDEmployees select 'Силаева Татьяна Владимировна',getdate()
	-- сотрудники КД
	drop table if exists #curr_employee_cd
	create table #curr_employee_cd([Employee] nvarchar(255))
  
	--DWH-1988
	INSERT #curr_employee_cd(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
			and (
				(isnull(UR.deleted_at, '2100-01-01') >= @dt_from and UR.IsDeleted = 1)
				or isnull(UR.IsDeleted, 0) = 0
			)
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
	--AND UR.IsDeleted = 0
		AND R.Name IN ('Чекер','Чекер аутсорс','Супервизор аутсорс')
		AND concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			NOT IN (SELECT Employee FROM #curr_employee_test)
	and 
		(
			(U.DeleteDate >= @dt_from and U.IsDeleted = 1)
			or (u.DeleteDate is null and U.IsDeleted = 0)
		)
	union 
	select Employee 
	from (
		select Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			,DeleteDate = case id
				when '244F6B46-49D8-4E11-B68D-05C5D7A9C8BC' then '2023-03-31'
				when '6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' then '2024-04-23'
			end
		from Stg._fedor.core_user u
		where Id in(
			'244F6B46-49D8-4E11-B68D-05C5D7A9C8BC', --Жарких Марина Павловна
			'6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' --Короткова Евгения Игоревна --обращение #prod 25 апреля 2024 г. a.zaharov 11:22
			)
	) u
	where U.DeleteDate >= @dt_from


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##curr_employee_cd
		SELECT * INTO ##curr_employee_cd FROM #curr_employee_cd
	END
   
	---- Верификаторы
	drop table if exists #curr_employee_vr
	create table #curr_employee_vr([Employee] nvarchar(255))

	--DWH-1988
	INSERT #curr_employee_vr(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
			and (
				(isnull(UR.deleted_at, '2100-01-01') >= @dt_from and UR.IsDeleted = 1)
				or isnull(UR.IsDeleted, 0) = 0
			)
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND R.Name IN ('Верификатор'
			--Валерия Манина @v.manina 31 мая 2024 г. 10:39
			--Вчера у сотрудников группы верификации Беззалоговых продуктов убрали роль верификатор.
			--Сегодня все данные, в отчете по контактности, по этим сотрудникам исчезли с листов Общие данные месяц и Общие данные по дням.
			,'Чекер','Чекер аутсорс','Супервизор аутсорс'
			)
		AND concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			NOT IN (SELECT Employee FROM #curr_employee_test)
		and 
		(
			(U.DeleteDate >= @dt_from and U.IsDeleted = 1)
			or (u.DeleteDate is null and U.IsDeleted = 0)
		)
	--обращение #production Екатерина Панина @eka.panina 14:42
	union 
	select Employee 
	from (
			select Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
				,DeleteDate = case id
					when '89EAED68-E616-415C-BE92-0C2D4C084899' then '2023-12-31'
					when '6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' then '2024-04-23'
					ELSE u.DeleteDate
				end
			from Stg._fedor.core_user u
			where Id in(
				'89EAED68-E616-415C-BE92-0C2D4C084899', --Столица Вероника Игоревна
				'6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' --Короткова Евгения Игоревна --обращение #prod 25 апреля 2024 г. a.zaharov 11:22
				)
	) u
	where U.DeleteDate >= @dt_from


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##curr_employee_vr
		SELECT * INTO ##curr_employee_vr FROM #curr_employee_vr
	END

  
	DROP TABLE IF EXISTS #t_request_number
	CREATE TABLE #t_request_number(IdClientRequest uniqueidentifier, [Номер заявки] nvarchar(255))
	CREATE INDEX ix1 ON #t_request_number(IdClientRequest)
	CREATE INDEX ix2 ON #t_request_number([Номер заявки])

	DROP TABLE IF EXISTS #t_approved
	CREATE TABLE #t_approved([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))
	CREATE UNIQUE INDEX ix1 ON #t_approved([Номер заявки])

	DROP TABLE IF EXISTS #t_denied
	CREATE TABLE #t_denied([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))
	CREATE UNIQUE INDEX ix1 ON #t_denied([Номер заявки])

	DROP TABLE IF EXISTS #t_canceled
	CREATE TABLE #t_canceled([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))
	CREATE UNIQUE INDEX ix1 ON #t_canceled([Номер заявки])

	DROP TABLE IF EXISTS #t_customer_rejection
	CREATE TABLE #t_customer_rejection([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))
	CREATE UNIQUE INDEX ix1 ON #t_customer_rejection([Номер заявки])

	DROP TABLE IF EXISTS #t_final_approved
	CREATE TABLE #t_final_approved([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))
	CREATE UNIQUE INDEX ix1 ON #t_final_approved([Номер заявки])

	DROP TABLE IF EXISTS #t_checklists_rejects
	CREATE TABLE #t_checklists_rejects
	(
		IdClientRequest uniqueidentifier,
		Number nvarchar(255),
		CheckListItemTypeName nvarchar(255),
		CheckListItemStatusName nvarchar(255)
	)
	CREATE INDEX ix_IdClientRequest ON #t_checklists_rejects(IdClientRequest)

	--DELETE #t_request_number
	--DELETE #t_approved
	--DELETE #t_denied
	--DELETE #t_canceled
	--DELETE #t_customer_rejection

	--request numbers
	INSERT #t_request_number(IdClientRequest, [Номер заявки])
	SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
	FROM #t_dm_FedorVerificationRequests_without_coll AS R
	WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС',
		'Проверка способа выдачи')
		AND R.[Дата статуса] >= @dt_from
		AND R.[Дата статуса] < @dt_to

	--одобрено
	INSERT #t_approved([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] >= @dt_from
		AND R.[Дата статуса] < @dt_to
		AND (
			R.Статус IN ('Верификация Call 1.5', 'Переподписание первого пакета') AND R.[Статус следующий] IN ('Верификация Call 2')
			OR R.Статус IN ('Верификация ТС','Верификация Call 4') AND R.[Статус следующий] IN ('Одобрено')
			--OR R.Статус IN ('Верификация Call 3') AND R.[Статус следующий] IN ('Одобрено')
			--DWH-2361
			OR (R.Статус IN ('Верификация Call 3') 
				AND EXISTS(
						SELECT TOP(1) 1
						FROM #t_dm_FedorVerificationRequests_without_coll AS N
						WHERE R.[Номер заявки] = N.[Номер заявки]
							AND N.[Дата статуса] >= R.[Дата статуса]
							AND N.[Статус следующий] IN ('Одобрено', 'Предодобр перед Call 5')
					)
			)
			OR (R.Статус IN ('Проверка способа выдачи') AND R.[Статус следующий] IN ('Одобрено'))
		)
	GROUP BY R.[Номер заявки]

	--финальное одобрение
	INSERT #t_final_approved([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата след.статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Статус следующий] = 'Одобрено' 
		-- есть заявки, у кот. нет записи Статус = 'Одобрено', но есть [Статус следующий] = 'Одобрено'
		--напр. '23121221532517','23121921568650','23121521547100'
	GROUP BY R.[Номер заявки]

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_final_approved
		SELECT * INTO ##t_final_approved FROM #t_final_approved
	END

	--отказано
	INSERT #t_denied([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] >= @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5','Верификация ТС','Верификация Call 3','Верификация Call 4',
			'Проверка способа выдачи')
		AND R.[Статус следующий] IN ('Отказано')
	GROUP BY R.[Номер заявки]

	--анулировано
	INSERT #t_canceled([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] >= @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Контроль данных','Верификация клиента','Верификация ТС','Верификация Call 3','Верификация Call 4',
			'Проверка способа выдачи') 
		AND R.[Статус следующий] IN ('Аннулировано')
	GROUP BY R.[Номер заявки]

	--Отказ клиента
	INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] >= @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказ клиента')
	GROUP BY R.[Номер заявки]




	DROP TABLE IF EXISTS #t_Autoapprove
	CREATE TABLE #t_Autoapprove(
		[Номер заявки] nvarchar(255),
		Статус nvarchar(260),
		[Дата статуса] datetime2(7)
	)

	INSERT #t_Autoapprove
	(
		[Номер заявки],
		Статус,
		[Дата статуса]
	)
	SELECT 
		R.[Номер заявки], 
		R.Статус,
		[Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.isSkipped = 1
	GROUP BY R.[Номер заявки], R.Статус

	CREATE CLUSTERED INDEX clix1 ON #t_Autoapprove([Номер заявки])

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Autoapprove
		SELECT * INTO ##t_Autoapprove FROM #t_Autoapprove
	END


	-- Лист "КД. Детализация"
	IF @Page = 'KD.Detail' OR @isFill_All_Tables = 1 --241
	BEGIN
		DELETE #t_request_number
		DELETE #t_approved
		DELETE #t_denied
		DELETE #t_canceled
		DELETE #t_customer_rejection
		DELETE #t_checklists_rejects

		--request numbers
		INSERT #t_request_number(IdClientRequest, [Номер заявки])
		SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
		FROM #t_dm_FedorVerificationRequests_without_coll AS R
		WHERE R.[Статус] in ('Контроль данных')
			AND R.[Дата статуса] >= @dt_from
			AND R.[Дата статуса] < @dt_to

		--Отказы Логинома --DWH-2429
		;with loginom_checklists_rejects AS(
			SELECT 
				min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
				cli.IdClientRequest
			FROM
				[Stg].[_fedor].[core_CheckListItem] cli 
				inner JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
					--and cis.[IdBehavior] =2 --	Статус - хард-код, по которому откажет логином
					and cis.[IdBehavior] IN (2, 3) -- 3. В информацию по Check* выводим информацию если по заявке был отказа, не важно кем системой или верификатором
			WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)
			GROUP BY cli.IdClientRequest
		)
		INSERT #t_checklists_rejects
		(
			IdClientRequest,
			Number,
			CheckListItemTypeName,
			CheckListItemStatusName
		)
		SELECT 
			cli.IdClientRequest,
			CR.Number COLLATE Cyrillic_General_CI_AS,
			cit.[Name] CheckListItemTypeName,
			cis.[Name] CheckListItemStatusName
		FROM [Stg].[_fedor].[core_CheckListItem] cli
			JOIN [Stg].[_fedor].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
			JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
			JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
				AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
			INNER JOIN Stg._fedor.core_ClientRequest AS CR
				ON CR.Id = cli.IdClientRequest
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)

		--IF @isDebug = 1 BEGIN
		--	DROP TABLE IF EXISTS ##t_checklists_rejects
		--	SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
		--END

		--одобрено
		INSERT #t_approved([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			AND R.[Дата статуса] >= @dt_from
			AND R.[Дата статуса] < @dt_to
			--AND R.Статус IN ('Верификация Call 1.5', 'Переподписание первого пакета')
			--AND R.[Статус следующий] IN ('Верификация Call 2')
			--DWH-2677
			AND R.Статус IN ('Верификация Call 1.5')
			AND EXISTS(
					SELECT TOP(1) 1
					FROM #t_dm_FedorVerificationRequests_without_coll AS N
					WHERE R.[Номер заявки] = N.[Номер заявки]
						AND N.[Дата статуса] >= R.[Дата статуса]
						AND N.[Статус следующий] in (
							'Переподписание первого пакета',
							'Верификация Call 2'
						)
				)
		GROUP BY R.[Номер заявки]

		--2 одобрено сотрудником, но отказано автоматически
		INSERT #t_approved([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			LEFT JOIN #t_approved AS X
				ON X.[Номер заявки] = R.[Номер заявки]
		WHERE 1=1
			AND X.[Номер заявки] IS NULL
			AND R.[Дата статуса] >= @dt_from
			AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Верификация Call 1.5')
			--AND R.[Статус следующий] IN ('Отказано')
			--DWH-2677
			AND EXISTS(
					SELECT TOP(1) 1
					FROM #t_dm_FedorVerificationRequests_without_coll AS N
					WHERE R.[Номер заявки] = N.[Номер заявки]
						AND N.[Дата статуса] >= R.[Дата статуса]
						AND N.[Статус следующий] in (
							'Отказано'
						)
				)
			AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
		GROUP BY R.[Номер заявки]

		--отказано сотрудником
		INSERT #t_denied([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			AND R.[Дата статуса] >= @dt_from
			AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Верификация Call 1.5')
			--AND R.[Статус следующий] IN ('Отказано')
			--DWH-2677
			AND EXISTS(
					SELECT TOP(1) 1
					FROM #t_dm_FedorVerificationRequests_without_coll AS N
					WHERE R.[Номер заявки] = N.[Номер заявки]
						AND N.[Дата статуса] >= R.[Дата статуса]
						AND N.[Статус следующий] in (
							'Отказано'
						)
				)
			AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
		GROUP BY R.[Номер заявки]

		--анулировано
		INSERT #t_canceled([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			AND R.[Дата статуса] >= @dt_from
			AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Контроль данных')
			AND R.[Статус следующий] IN ('Аннулировано')
		GROUP BY R.[Номер заявки]

		--Отказ клиента
		INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			AND R.[Дата статуса] >= @dt_from
			AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Верификация Call 1.5')
			AND R.[Статус следующий] IN ('Отказ клиента')
		GROUP BY R.[Номер заявки]


		IF @isFill_All_Tables = 1
		BEGIN
			--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_KD_Detail
			DELETE T
			FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Detail AS T
			WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Detail
			SELECT distinct
				ProcessGUID = @ProcessGUID
				, R.[ProductType_Code]
				, R.[Дата заведения заявки]
				 , R.[Время заведения]
				 , R.[Номер заявки]
				 , R.[ФИО клиента]
				 , R.[Статус]
				 , R.[Задача]
				 , R.[Состояние заявки]
				 , R.[Дата статуса]
				  -- 20210326
				 , [ФИО сотрудника верификации/чекер] = R.Работник
				 , R.Назначен
				 , R.[ВремяЗатрачено]
			   , R.[Время, час:мин:сек]
				 , R.[Статус следующий]
				 , R.[Задача следующая]
				 , R.[Состояние заявки следующая]
				 --, R.[Офис заведения заявки]
				 --DWH-1720
				 , [Решение по заявке] = trim(
						concat(
							iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
							iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
							iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
							iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
							)
					)
				, R.ТипКлиента
				, IsSkipped = cast(R.IsSkipped AS int)
				, R.Партнер
				, [Проверка дохода] = case when isnull(R.ПроверкаДохода,0) = 1 then 'Да' else 'Нет' end
				, R.[Тип документа подтверждающего доход]
				, R.РегионПроживания
				, R.РегионРегистрации
				, НовыйРегион = iif(
						isnull(R.РегионПроживания_НовыйРегион, 0) = 1 
						or isnull(R.РегионРегистрации_НовыйРегион, 0) = 1
						, 'Да', 'Нет'
					)
			--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_Detail
			FROM #t_request_number AS N
				INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			WHERE R.[Статус] in ('Контроль данных')
				AND R.[Дата статуса] >= @dt_from 
				AND R.[Дата статуса] < @dt_to
			ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc

			INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'KD.Detail', @ProcessGUID
		END
		ELSE BEGIN
			SELECT --distinct
				R.[ProductType_Code]
				, R.[Дата заведения заявки]
				 , R.[Время заведения]
				 , R.[Номер заявки]
				 , R.[ФИО клиента]
				 , R.[Статус]
				 , R.[Задача]
				 , R.[Состояние заявки]
				 , R.[Дата статуса]
				  -- 20210326
				 , [ФИО сотрудника верификации/чекер] = R.Работник
				 , R.Назначен
				 , R.[ВремяЗатрачено]
			   , R.[Время, час:мин:сек]
				 , R.[Статус следующий]
				 , R.[Задача следующая]
				 , R.[Состояние заявки следующая]
				 --, R.[Офис заведения заявки]
				 --DWH-1720
				 , [Решение по заявке] = trim(
						concat(
							iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
							iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
							iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
							iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
							)
					)
				, R.ТипКлиента
				, IsSkipped = cast(R.IsSkipped AS int)
				, R.Партнер
				, [Проверка дохода] = case when isnull(R.ПроверкаДохода,0) = 1 then 'Да' else 'Нет' end
				, R.[Тип документа подтверждающего доход]
				, R.РегионПроживания
				, R.РегионРегистрации
				, НовыйРегион = iif(
						isnull(R.РегионПроживания_НовыйРегион, 0) = 1 
						or isnull(R.РегионРегистрации_НовыйРегион, 0) = 1
						, 'Да', 'Нет'
					)
			FROM #t_request_number AS N
				INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			WHERE R.[Статус] in ('Контроль данных')
				AND R.[Дата статуса] >= @dt_from 
				AND R.[Дата статуса] < @dt_to
			ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc

			RETURN 0
		END
	END
	--// 'KD.Detail'


	-- Лист "Пр-ка способа выдачи. Детализация"
	IF @Page = 'PSV.Detail' OR @isFill_All_Tables = 1 --241
	BEGIN
		DELETE #t_request_number
		DELETE #t_approved
		DELETE #t_denied
		DELETE #t_canceled
		DELETE #t_customer_rejection
		--DELETE #t_checklists_rejects

		--request numbers
		INSERT #t_request_number(IdClientRequest, [Номер заявки])
		SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
		FROM #t_dm_FedorVerificationRequests_without_coll AS R
		WHERE R.[Статус] in ('Проверка способа выдачи')
			--AND R.[Дата статуса] >= @dt_from
			--AND R.[Дата статуса] < @dt_to

		--одобрено
		INSERT #t_approved([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			--AND R.[Дата статуса] >= @dt_from
			--AND R.[Дата статуса] < @dt_to
			and R.[Статус] in ('Проверка способа выдачи')
			AND R.[Статус следующий] IN ('Одобрено')
		GROUP BY R.[Номер заявки]

		/*
		--2 одобрено сотрудником, но отказано автоматически
		INSERT #t_approved([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			AND R.[Дата статуса] >= @dt_from
			AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Верификация Call 1.5')
			AND R.[Статус следующий] IN ('Отказано')
			AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
		GROUP BY R.[Номер заявки]
		*/

		--отказано сотрудником
		INSERT #t_denied([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			--AND R.[Дата статуса] >= @dt_from
			--AND R.[Дата статуса] < @dt_to
			and R.[Статус] in ('Проверка способа выдачи')
			AND R.[Статус следующий] IN ('Отказано')
			--AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
		GROUP BY R.[Номер заявки]

		--анулировано
		INSERT #t_canceled([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			--AND R.[Дата статуса] >= @dt_from
			--AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Проверка способа выдачи')
			AND R.[Статус следующий] IN ('Аннулировано')
		GROUP BY R.[Номер заявки]

		--Отказ клиента
		INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			--AND R.[Дата статуса] >= @dt_from
			--AND R.[Дата статуса] < @dt_to
			and R.[Статус] in ('Проверка способа выдачи')
			AND R.[Статус следующий] IN ('Отказ клиента')
		GROUP BY R.[Номер заявки]


		IF @isFill_All_Tables = 1
		BEGIN
			--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_PSV_Detail
			DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Detail AS T WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Detail
			SELECT 
				ProcessGUID = @ProcessGUID
				, R.[ProductType_Code]
				, R.[Дата заведения заявки]
				 , R.[Время заведения]
				 , R.[Номер заявки]
				 , R.[ФИО клиента]
				 , R.[Статус]
				 , R.[Задача]
				 , R.[Состояние заявки]
				 , R.[Дата статуса]
				  -- 20210326
				 , [ФИО сотрудника верификации/чекер] = R.Работник
				 , R.Назначен
				 , R.[ВремяЗатрачено]
			   , R.[Время, час:мин:сек]
				 , R.[Статус следующий]
				 , R.[Задача следующая]
				 , R.[Состояние заявки следующая]
				 --, R.[Офис заведения заявки]
				 --DWH-1720
				 , [Решение по заявке] = trim(
						concat(
							iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
							iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
							iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
							iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
							)
					)
				, R.ТипКлиента
				, IsSkipped = cast(R.IsSkipped AS int)
				, R.Партнер
			--INTO tmp.TMP_Report_verification_fedor_without_coll_PSV_Detail
			FROM #t_request_number AS N
				INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			WHERE R.[Статус] in ('Проверка способа выдачи')
				--AND R.[Дата статуса] >= @dt_from 
				--AND R.[Дата статуса] < @dt_to
			ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc

			INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'PSV.Detail', @ProcessGUID
		END
		ELSE BEGIN
			SELECT 
				R.[ProductType_Code]
				, R.[Дата заведения заявки]
				 , R.[Время заведения]
				 , R.[Номер заявки]
				 , R.[ФИО клиента]
				 , R.[Статус]
				 , R.[Задача]
				 , R.[Состояние заявки]
				 , R.[Дата статуса]
				  -- 20210326
				 , [ФИО сотрудника верификации/чекер] = R.Работник
				 , R.Назначен
				 , R.[ВремяЗатрачено]
				 , R.[Время, час:мин:сек]
				 , R.[Статус следующий]
				 , R.[Задача следующая]
				 , R.[Состояние заявки следующая]
				 --, R.[Офис заведения заявки]
				 --DWH-1720
				 , [Решение по заявке] = trim(
						concat(
							iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
							iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
							iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
							iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
							)
					)
				, R.ТипКлиента
				, IsSkipped = cast(R.IsSkipped AS int)
				, R.Партнер
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			WHERE R.[Статус] in ('Проверка способа выдачи')
				--AND R.[Дата статуса] >= @dt_from 
				--AND R.[Дата статуса] < @dt_to
			ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc
      
			RETURN 0
		END
	END
	--// 'PSV.Detail'


	---------------------------------------------
	--- общие таблицы для аггрегации по дням
	---------------------------------------------
 
	drop table if exists #calendar
	--select cast(created as date) as dt_day
	--		, cast(dateadd(month,datediff(month,0,created),0) as date) as dt_month
	--into #calendar
	--from dwh_new.[dbo].calendar
	--where created >=@dt_from and created<@dt_to
        
	select 
		dt_day = c.DT,
		dt_month = c.Month_Value
	into #calendar
	from dwh2.Dictionary.calendar as c
	where c.DT >= @dt_from and c.DT < @dt_to
        
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##calendar
		SELECT * INTO ##calendar FROM #calendar
	END

	------- всп.таблица список выводимых статусов
	drop table if exists #table_status
        
	select distinct Status='Верификация КЦ' 
	into #table_status
	union all select 'Контроль данных' 
	union all select 'Верификация Call 2' 
	union all select 'Верификация клиента' 
	union all select 'Верификация ТС'
	union all select 'Верификация'
	union all select 'Проверка способа выдачи'
        
        
	drop table if exists #structure_firstTable
	create table #structure_firstTable (
				[num_rows] int null 
				, [name_indicator] nvarchar(250) null
				)
	insert into #structure_firstTable([num_rows] ,[name_indicator])
	values (1             ,'Общее кол-во заведенных заявок')
		, (1             ,'Общее кол-во заведенных заявок Call2')
		, (2             ,'Кол-во автоматических отказов Логином')
		, (2             ,'Кол-во автоматических отказов Call2')
		, (3             ,'%  автоматических отказов Логином')
		, (3             ,'%  автоматических отказов Call2')
		, (4             ,'Общее кол-во уникальных заявок на этапе')
		, (5             ,'Общее кол-во заявок на этапе')
		, (7             ,'TTY  - % заявок рассмотренных в течение 7 минут на этапе')
		, (8             ,'TTY  - % заявок рассмотренных в течение 30 минут на этапе')
		, (9             ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')
		, (10            ,'Среднее время заявки в ожидании очереди на этапе')
		, (12            ,'Средний Processing time на этапе (время обработки заявки)')
		, (15            ,'Кол-во одобренных заявок после этапа')
		, (18            ,'Кол-во отказов со стороны сотрудников')
		, (21            ,'Approval rate - % одобренных после этапа')
		, (24            ,'Approval rate % Логином')
		, (25            ,'Общее кол-во отложенных заявок на этапе')
		, (26            ,'Уникальное кол-во отложенных заявок на этапе')
		, (28            ,'Кол-во заявок на этапе, отправленных на доработку')
		, (31            ,'Take rate Уровень выдачи, выраженный через одобрения')
		, (32            ,'Кол-во заявок в статусе "Займ выдан",шт.')
		, (48            , 'Среднее время по заявке (общие)')
		, (49            ,'Кол-во заявок на доработку')
		, (51            ,'Кол-во заявок в работе')
		, (52            ,'Кол-во заявок в ожидании на этапе')
		, (53            ,'Кол-во заявок на перерыве на этапе')
        
        
          
	-- сотрудники
	drop table if exists #employee_rows
	select row_number() over ( order by Employee) as [empl_id]
			, Employee
	into #employee_rows
	from (select distinct Работник Employee from #t_dm_FedorVerificationRequests_without_coll) e
        
        
	drop table if exists #employee_rows_d
	select c.dt_day as acc_period 
			, s.[num_rows] 
		, [name_indicator]
			, e.empl_id
			, e.Employee
			, t.[Status]
	into #employee_rows_d
	from (select dt_day from #calendar) c 
	cross join #employee_rows e
	cross join #structure_firstTable s
	cross join #table_status t
	/*   where c.dt_day >= case when datepart(dd,getdate()) between 1 and 10 
        								then dateadd(month,-1,dateadd(month,datediff(month,0,Getdate()),0)) 
        								else dateadd(month,datediff(month,0,Getdate()),0) 
        						end
        
	-- select * from #employee_rows_d
	*/
	CREATE NONCLUSTERED INDEX ix_status on #employee_rows_d([Status])
	INCLUDE ([acc_period],[empl_id],[Employee])


	drop table if exists #employee_rows_m
	select c.dt_month as acc_period
		,s.*
		,e.empl_id 
		,e.Employee
		,t.[Status]
          
	into #employee_rows_m
	from (select distinct dt_month from #calendar) c 
	cross join #employee_rows e
	cross join #structure_firstTable s
	cross join #table_status t

	--select * from #employee_rows_m
	CREATE NONCLUSTERED INDEX ix_Status
	ON [#employee_rows_m]([Status])
	INCLUDE ([acc_period],[empl_id],[Employee])


	-- KD.%
	IF @Page IN (
		'KD.Daily.Common'
		,'KD.Monthly.Common'
		,'KD.HoursGroupMonth'
		, 'KD.HoursGroupMonthUnique'
		, 'KD.HoursGroupDays'
		, 'KD.HoursGroupDaysUnique'
		,'KD.Monthly.ALL'
		,'KD.Daily.ALL'
	) OR @isFill_All_Tables = 1
	BEGIN

			drop table if exists #fedor_verificator_report
        
			drop table if exists #details_KD
        
			select * 
			  into #details_KD 
			  from #t_dm_FedorVerificationRequests_without_coll  --where [Номер заявки]='20092400036174'
			 where 1=1
				AND (Работник not in (select * from #curr_employee_vr) 
					OR Работник IN (select Employee from #curr_employee_cd) --DWH-1787
					)
				--AND Работник IN (select Employee from #curr_employee_cd) --DWH-1988
			   and [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
         
			 create INDEX ix_Статус_Задача
				ON #details_KD([Статус] ,[Статус следующий], [Задача],[Задача следующая],[Состояние заявки], [Состояние заявки следующая])
				INCLUDE ([Номер заявки],[ФИО клиента],[Дата статуса],[ВремяЗатрачено],[ШагЗаявки],[ПоследнийШаг], [Работник],[Работник_Пред],[Работник_След])
		
			 create INDEX ix_Номер_заявки
				ON #details_KD([Номер заявки],[Дата статуса])
				INCLUDE ([Статус следующий])

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##details_KD
				SELECT * INTO ##details_KD FROM #details_KD
			END

			--Отказы Логинома --DWH-2429
			DELETE #t_request_number
			DELETE #t_checklists_rejects

			INSERT #t_request_number(IdClientRequest, [Номер заявки])
			SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
			FROM #details_KD AS R

			;with loginom_checklists_rejects AS(
				SELECT 
					min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
					cli.IdClientRequest
				FROM
					[Stg].[_fedor].[core_CheckListItem] cli 
					inner JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
						--and cis.[IdBehavior] =2 --	Статус - хард-код, по которому откажет логином
						and cis.[IdBehavior] IN (2, 3) -- 3. В информацию по Check* выводим информацию если по заявке был отказа, не важно кем системой или верификатором
				WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)
				GROUP BY cli.IdClientRequest
			)
			INSERT #t_checklists_rejects
			(
				IdClientRequest,
				Number,
				CheckListItemTypeName,
				CheckListItemStatusName
			)
			SELECT 
				cli.IdClientRequest,
				CR.Number COLLATE Cyrillic_General_CI_AS,
				cit.[Name] CheckListItemTypeName,
				cis.[Name] CheckListItemStatusName
			FROM [Stg].[_fedor].[core_CheckListItem] cli
				JOIN [Stg].[_fedor].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
				JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
				JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
					AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
				INNER JOIN Stg._fedor.core_ClientRequest AS CR
					ON CR.Id = cli.IdClientRequest
			WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##t_checklists_rejects
				SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
			END


			 ;
			 with 
			  rework as (
          
			  select 'Доработка' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса]
				   , [ФИО клиента]
				   , [Номер заявки] 
				  --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено
					,ТипКлиента
				from #details_KD
			   where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных') 
          
			  )
			  ,rework1 as 
			  (
          
			  select 'Доработка' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса]
				   , [ФИО клиента]
				   , [Номер заявки] 
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_След -- Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено
					,ТипКлиента
				from #details_KD
			   where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
          
			  )
			  ,postpone as (
			select 'Отложена' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса] ДатаИВремяСтатуса
				   , [ФИО клиента]
				   , [Номер заявки]  
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено
					,ТипКлиента
				from #details_KD
			   where Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Контроль данных')
			   )
			   ,postpone1 as (
			select 'Отложена' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса] ДатаИВремяСтатуса
				   , [ФИО клиента]
				   , [Номер заявки]  
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_След --Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено
					,ТипКлиента
				from #details_KD
			   where [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
			   )

        
        
			--отказано сотрудником
			 select 'Отказано' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса] ДатаИВремяСтатуса
				   , [ФИО клиента]
				   , [Номер заявки]  
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено
					,ТипКлиента
				into #fedor_verificator_report
				from #details_KD AS A
				WHERE A.Статус IN ('Верификация Call 1.5')
					AND EXISTS(
							SELECT TOP(1) 1
							FROM #details_KD AS N
							WHERE A.[Номер заявки] = N.[Номер заявки]
								AND N.[Дата статуса] >= A.[Дата статуса]
								AND N.[Статус следующий] in (
									'Отказано'
								)
						)
					AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = A.IdClientRequest)


			   -- 
			   union all
			   select * from postpone
			   union all 
			   select * from postpone1

           
			   union 
			   -- доработка
			   select * from rework
			   union all 
			   select * from rework1
			   /*
			  select 'Доработка' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса]
				   , [ФИО клиента]
				   , [Номер заявки] 
				   , Сотрудник=СотрудникПоследнегоСтатуса
				   , [ФИО сотрудника верификации/чекер]
				   , ВремяЗатрачено
				from details_KD
			   where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных')
			  */

			  /*
			  --v.1
			   union 
			  select 'ВК' [status]
				   , cast(A.[Дата статуса] as date) Дата
				   , A.[Дата статуса] ДатаИВремяСтатуса
				   , A.[ФИО клиента]
				   , A.[Номер заявки] 
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=A.Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = A.Работник
				   , A.ВремяЗатрачено 
					,A.ТипКлиента
				from #details_KD AS A
					LEFT JOIN #details_KD AS B --следующая заявка
						ON A.[Номер заявки] = B.[Номер заявки]
						AND A.ШагЗаявки = B.ШагЗаявки - 1
			   where (
						A.Статус IN ('Верификация Call 1.5') 
						--[Статус следующий]='Ожидание подписи документов EDO' 
						AND A.[Статус следующий] = 'Верификация Call 2' --согласовано с Промётовым 22.12.2021
					)
					OR (
						B.Статус IN ('Переподписание первого пакета')
						AND B.[Статус следующий] = 'Верификация Call 2'
					)
					--DWH-2429 --одобрено сотрудником, но отказано автоматически
					OR (
						A.[Статус следующий]='Отказано' and A.Статус in('Верификация Call 1.5')
						AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = A.IdClientRequest)
					)
				*/
				-- исправлено по письму: Матвей Бережков 2024-08-15 14:11
				--v.2
				--DWH-2677
				UNION 
				SELECT 'ВК' [status]
				   , cast(A.[Дата статуса] as date) Дата
				   , A.[Дата статуса] ДатаИВремяСтатуса
				   , A.[ФИО клиента]
				   , A.[Номер заявки] 
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=A.Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = A.Работник
				   , A.ВремяЗатрачено 
					,A.ТипКлиента
				FROM #details_KD AS A
				WHERE (
						A.Статус IN ('Верификация Call 1.5') 
						AND EXISTS(
								SELECT TOP(1) 1
								FROM #details_KD AS N
								WHERE A.[Номер заявки] = N.[Номер заявки]
									AND N.[Дата статуса] >= A.[Дата статуса]
									AND N.[Статус следующий] in (
										'Переподписание первого пакета',
										'Верификация Call 2'
									)
							)
					)
					--DWH-2429 --одобрено сотрудником, но отказано автоматически
					OR (
						A.Статус IN ('Верификация Call 1.5') 
						AND EXISTS(
								SELECT TOP(1) 1
								FROM #details_KD AS N
								WHERE A.[Номер заявки] = N.[Номер заявки]
									AND N.[Дата статуса] >= A.[Дата статуса]
									AND N.[Статус следующий] in (
										'Отказано'
									)
							)
						AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = A.IdClientRequest)
					)

			union
			  select 'Новая' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса] ДатаИВремяСтатуса
				   , [ФИО клиента]
				   , [Номер заявки] 
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено 
					,ТипКлиента
				from #details_KD
			   where Задача='task:Новая' and Статус in('Контроль данных')

			UNION
				--DWH-2021
			  select 'Новая_Уникальная' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса] ДатаИВремяСтатуса
				   , [ФИО клиента]
				   , [Номер заявки] 
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено 
					,ТипКлиента
				from #details_KD
			   where Задача='task:Новая' and Статус in('Контроль данных')
					AND [Задача следующая] <> 'task:Автоматически отложено'

			--DWH-563
			UNION ALL
			  select 'Новая_Уникальная_НовыйРегион' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса] ДатаИВремяСтатуса
				   , [ФИО клиента]
				   , [Номер заявки] 
				   --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]
				   , Сотрудник=Работник_Пред --Работник_След
				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено 
					,ТипКлиента
				from #details_KD
			   where Задача='task:Новая' and Статус in('Контроль данных')
					AND [Задача следующая] <> 'task:Автоматически отложено'
					and (isnull(РегионПроживания_НовыйРегион, 0) = 1 
						or isnull(РегионРегистрации_НовыйРегион, 0) = 1)
         
			 UNION ALL
			  select 'task:В работе' [status]
				   , cast([Дата статуса] as date) Дата
				   , [Дата статуса] ДатаИВремяСтатуса
				   , [ФИО клиента]
				   , [Номер заявки] 
				  --, Сотрудник=СотрудникПоследнегоСтатуса
				   --, [ФИО сотрудника верификации/чекер]

				   --, Сотрудник=Работник_Пред --Работник_След
				   -- исправлено DWH-2457
				   , Сотрудник=Работник

				   , [ФИО сотрудника верификации/чекер] = Работник
				   , ВремяЗатрачено
					,ТипКлиента
				from #details_KD
				 where Задача='task:В работе'  and Статус in('Контроль данных')
        
				UNION ALL
				SELECT 
					'Не вернувшиеся с доработки' AS [status]
					, Дата = cast(A.[Дата статуса] as date)
					, ДатаИВремяСтатуса = A.[Дата статуса]
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = A.Работник_Пред --A.Работник_След
					, [ФИО сотрудника верификации/чекер] = A.Работник
					, A.ВремяЗатрачено
					, A.ТипКлиента
				FROM (
						SELECT 
							K.[Дата статуса]
							,K.[ФИО клиента]
							,K.[Номер заявки] 
							,K.Работник_Пред --K.Работник_След
							,K.Работник
							,K.ВремяЗатрачено
							,[След Дата статуса] = lead(K.[Дата статуса],1,'2100-01-01') OVER(PARTITION BY K.[Номер заявки] ORDER BY K.[Дата статуса])
							,K.ТипКлиента
						from #details_KD AS K
						where K.Задача = 'task:Требуется доработка' 
					) AS A
					INNER JOIN 
					(
						SELECT 
							L.[Дата статуса]
							,L.[Номер заявки] 
						from #details_KD AS L
						where L.[Задача следующая] = 'task:Отменена'
					) AS B
					ON B.[Номер заявки] = A.[Номер заявки]
					AND A.[Дата статуса] < B.[Дата статуса] AND B.[Дата статуса] < A.[След Дата статуса]

				--UNION 
				--SELECT 
				--	[status] = 'ПроверкаДохода'
				--	, Дата = min(cast(A.[Дата статуса] as date))
				--	, ДатаИВремяСтатуса = min(A.[Дата статуса])
				--	, A.[ФИО клиента]
				--	, A.[Номер заявки] 
				--	, Сотрудник = max(A.Работник_Пред) --Работник_След
				--	, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				--	, ВремяЗатрачено = max(A.ВремяЗатрачено)
				--	,A.ТипКлиента
				--FROM #details_KD AS A
				--WHERE 1=1
				--	AND A.ПроверкаДохода = 1
				--	and A.Статус in ('Контроль данных')
				--GROUP BY
				--	A.[ФИО клиента]
				--	,A.[Номер заявки] 
				--	,A.ТипКлиента

				--UNION 
				--DWH-2209
				--SELECT 'Autoapprove' [status]
				--	, cast(A.[Дата статуса] as date) Дата
				--	, A.[Дата статуса] ДатаИВремяСтатуса
				--	, A.[ФИО клиента]
				--	, A.[Номер заявки] 
				--	--, Сотрудник=СотрудникПоследнегоСтатуса
				--	--, [ФИО сотрудника верификации/чекер]
				--	, Сотрудник=A.Работник_Пред --Работник_След
				--	, [ФИО сотрудника верификации/чекер] = A.Работник
				--	, A.ВремяЗатрачено 
				--	,A.ТипКлиента
				--FROM #details_KD AS A
				--WHERE (A.Статус IN ('Верификация Call 2') AND A.[Статус следующий] = 'Одобрено')

				--DWH-2374
				UNION 
				--Уникальное количество заявок autoapprove КД
				--заявки, по которым только на статусе КД был флаг skipped
				SELECT 
					[status] = 'Autoapprove_KD' 
					, Дата = cast(U.[Дата статуса] as date) 
					, ДатаИВремяСтатуса = U.[Дата статуса] 
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					INNER JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
				WHERE 1=1
					AND NOT EXISTS(
						SELECT TOP(1) 1 FROM #t_Autoapprove AS U
						WHERE U.[Номер заявки] = A.[Номер заявки]
							AND U.Статус = 'Верификация клиента'
					)
				GROUP BY
					cast(U.[Дата статуса] as date)
					, U.[Дата статуса]
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента

				UNION 
				--Уникальное количество заявок autoapprove КД, получивших финальное одобрение
				--заявки, по которым только на статусе КД был флаг skipped И которые получили финальное одобрение
				SELECT 
					[status] = 'Autoapprove_KD_fin_appr' 
					, Дата = cast(U.[Дата статуса] as date) 
					, ДатаИВремяСтатуса = U.[Дата статуса] 
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					--финальное одобрение
					INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
					--
					INNER JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
				WHERE 1=1
					AND NOT EXISTS(
						SELECT TOP(1) 1 FROM #t_Autoapprove AS U
						WHERE U.[Номер заявки] = A.[Номер заявки]
							AND U.Статус = 'Верификация клиента'
					)
				GROUP BY
					cast(U.[Дата статуса] as date)
					, U.[Дата статуса]
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента


				UNION 
				--Уникальное количество заявок autoapprove ВК
				--заявки, по которым только на статусе ВК был флаг skipped
				SELECT 
					[status] = 'Autoapprove_VK' 
					, Дата = cast(U.[Дата статуса] as date) 
					, ДатаИВремяСтатуса = U.[Дата статуса] 
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					INNER JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Верификация клиента'
				WHERE 1=1
					AND NOT EXISTS(
						SELECT TOP(1) 1 FROM #t_Autoapprove AS U
						WHERE U.[Номер заявки] = A.[Номер заявки]
							AND U.Статус = 'Контроль данных'
					)
				GROUP BY
					cast(U.[Дата статуса] as date)
					, U.[Дата статуса]
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента

				UNION 
				--Уникальное количество заявок autoapprove ВК, получивших финальное одобрение
				--заявки, по которым только на статусе ВК был флаг skipped И которые получили финальное одобрение
				SELECT 
					[status] = 'Autoapprove_VK_fin_appr' 
					, Дата = cast(U.[Дата статуса] as date) 
					, ДатаИВремяСтатуса = U.[Дата статуса] 
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					--финальное одобрение
					INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
					--
					INNER JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Верификация клиента'
				WHERE 1=1
					AND NOT EXISTS(
						SELECT TOP(1) 1 FROM #t_Autoapprove AS U
						WHERE U.[Номер заявки] = A.[Номер заявки]
							AND U.Статус = 'Контроль данных'
					)
				GROUP BY
					cast(U.[Дата статуса] as date)
					, U.[Дата статуса]
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента


				UNION 
				--Уникальное количество заявок autoapprove КД + ВК
				--заявки, по которым и на статусе КД, и на статусе ВК был флаг skipped
				SELECT 
					[status] = 'Autoapprove_KD_VK' 
					, Дата = cast(U.[Дата статуса] as date) 
					, ДатаИВремяСтатуса = U.[Дата статуса] 
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					INNER JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
					--
					INNER JOIN #t_Autoapprove AS U2
						ON U2.[Номер заявки] = A.[Номер заявки]
						AND U2.Статус = 'Верификация клиента'
				WHERE 1=1
				GROUP BY
					cast(U.[Дата статуса] as date)
					, U.[Дата статуса]
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента

				UNION 
				--Уникальное количество заявок autoapprove КД + ВК, получивших финальное одобрение
				--заявки, по которым и на статусе КД, и на статусе ВК был флаг skipped И которые получили финальное одобрение
				SELECT 
					[status] = 'Autoapprove_KD_VK_fin_appr' 
					, Дата = cast(U.[Дата статуса] as date) 
					, ДатаИВремяСтатуса = U.[Дата статуса] 
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					--финальное одобрение
					INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
					--
					INNER JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
					--
					INNER JOIN #t_Autoapprove AS U2
						ON U2.[Номер заявки] = A.[Номер заявки]
						AND U2.Статус = 'Верификация клиента'
				WHERE 1=1
				GROUP BY
					cast(U.[Дата статуса] as date)
					, U.[Дата статуса]
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента



				UNION 
				--Уникальное количество заявок autoapprove (всего)
				--= (Уникальное количество заявок autoapprove КД + Уникальное количество заявок autoapprove ВК + Уникальное количество заявок autoapprove КД + ВК). 
				SELECT 
					[status] = 'Autoapprove_KD_VK_total' 
					, Дата = cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
					, ДатаИВремяСтатуса = isnull(U.[Дата статуса], U2.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					LEFT JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
					--
					LEFT JOIN #t_Autoapprove AS U2
						ON U2.[Номер заявки] = A.[Номер заявки]
						AND U2.Статус = 'Верификация клиента'
				WHERE 1=1
					AND isnull(U.[Номер заявки], U2.[Номер заявки]) IS NOT NULL
				GROUP BY
					cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
					, isnull(U.[Дата статуса], U2.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента

				UNION 
				--Уникальное количество заявок autoapprove (всего), получивших финальное одобрение
				--= (Уникальное количество заявок autoapprove КД + Уникальное количество заявок autoapprove ВК + Уникальное количество заявок autoapprove КД + ВК). Считать только заявки, получившие финальное одобрение
				SELECT 
					[status] = 'Autoapprove_KD_VK_total_fin_appr' 
					, Дата = cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
					, ДатаИВремяСтатуса = isnull(U.[Дата статуса], U2.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					--финальное одобрение
					INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
					--
					LEFT JOIN #t_Autoapprove AS U
						ON U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
					--
					LEFT JOIN #t_Autoapprove AS U2
						ON U2.[Номер заявки] = A.[Номер заявки]
						AND U2.Статус = 'Верификация клиента'
				WHERE 1=1
					AND isnull(U.[Номер заявки], U2.[Номер заявки]) IS NOT NULL
				GROUP BY
					cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
					, isnull(U.[Дата статуса], U2.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента
				------
				------
				UNION 
				--Уникальное количество заявок, поступивших на КД
				SELECT 
					[status] = 'KD_IN'
					, Дата = min(cast(A.[Дата статуса] as date))
					, ДатаИВремяСтатуса = min(A.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
				WHERE 1=1
					AND A.Статус = 'Контроль данных'
				GROUP BY
					A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента

				UNION 
				--Уникальное количество заявок, поступивших на КД, получивших финальное одобрение
				SELECT 
					[status] = 'KD_IN_fin_appr'
					, Дата = min(cast(A.[Дата статуса] as date))
					, ДатаИВремяСтатуса = min(A.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					--финальное одобрение
					INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
				WHERE 1=1
					AND A.Статус = 'Контроль данных'
				GROUP BY
					A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента
				-----

				UNION 
				--Уникальное количество заявок, поступивших на ВК
				SELECT 
					[status] = 'VK_IN'
					, Дата = min(cast(A.[Дата статуса] as date))
					, ДатаИВремяСтатуса = min(A.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
				WHERE 1=1
					AND A.Статус = 'Верификация клиента'
				GROUP BY
					A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента

				UNION 
				--Уникальное количество заявок, поступивших на ВК, получивших финальное одобрение
				SELECT 
					[status] = 'VK_IN_fin_appr'
					, Дата = min(cast(A.[Дата статуса] as date))
					, ДатаИВремяСтатуса = min(A.[Дата статуса])
					, A.[ФИО клиента]
					, A.[Номер заявки] 
					, Сотрудник = max(A.Работник_Пред) --Работник_След
					, [ФИО сотрудника верификации/чекер] = max(A.Работник)
					, ВремяЗатрачено = max(A.ВремяЗатрачено)
					,A.ТипКлиента
				FROM #details_KD AS A
					--финальное одобрение
					INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
				WHERE 1=1
					AND A.Статус = 'Верификация клиента'
				GROUP BY
					A.[ФИО клиента]
					, A.[Номер заявки] 
					,A.ТипКлиента

		ALTER TABLE #fedor_verificator_report
		ADD ProductType_Code varchar(100) NULL

		UPDATE F
		SET ProductType_Code = R.ProductType_Code
		FROM #fedor_verificator_report AS F
			INNER JOIN (
					SELECT DISTINCT D.ProductType_Code, D.[Номер заявки] 
					FROM #t_dm_FedorVerificationRequests_without_coll AS D
				) AS R
				ON R.[Номер заявки] = F.[Номер заявки]


		--if @ProductTypeCode = 'installment,pdl' 
		-- если отчет строится по нескольким типам продукта
		-- добавить суммарные показатели
		if (select count(*) from @t_ProductTypeCode as t) > 1
		begin
			--!?
			--сумма по всем Типам продукта
			INSERT #fedor_verificator_report(
				status,
				Дата,
				ДатаИВремяСтатуса,
				[ФИО клиента],
				[Номер заявки],
				Сотрудник,
				[ФИО сотрудника верификации/чекер],
				ВремяЗатрачено,
				ТипКлиента,
				ProductType_Code
			)
			SELECT 
				F.status,
				F.Дата,
				F.ДатаИВремяСтатуса,
				F.[ФИО клиента],
				F.[Номер заявки],
				F.Сотрудник,
				F.[ФИО сотрудника верификации/чекер],
				F.ВремяЗатрачено,
				F.ТипКлиента,
				ProductType_Code = 'ALL'
			FROM #fedor_verificator_report AS F
		end
        
			--select * from  #fedor_verificator_report where дата='20200922' and status like 'до%'
		CREATE NONCLUSTERED INDEX ix_ДатаИВремяСтатуса
			ON #fedor_verificator_report([ДатаИВремяСтатуса])
		INCLUDE ([status],[Дата],[Номер заявки],[Сотрудник], ProductType_Code)

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##fedor_verificator_report
				SELECT * INTO ##fedor_verificator_report FROM #fedor_verificator_report
			END



			drop table if exists #ReportByEmployeeAgg
			;
			with c1 as (
			  select 
					ProductType_Code
					, Дата
				   , Сотрудник
				   , isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2021

				   --DWH-563
				   , isnull(sum(
						case when status in ('Новая_Уникальная_НовыйРегион') then 1 else 0 end),0) 
					as Новая_Уникальная_НовыйРегион

					--DWH-2286
				   , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Первичный' then 1 else 0 end),0) [Новая_Уникальная Первичный]
				   , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Повторный' then 1 else 0 end),0) [Новая_Уникальная Повторный]
				   , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Докредитование' then 1 else 0 end),0) [Новая_Уникальная Докредитование]
				   , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента IS NULL then 1 else 0 end),0) [Новая_Уникальная Не определен]

				   , isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая

				   , isnull(sum(case when status in ('ВК','Отказано','Не вернувшиеся с доработки') then 1 else 0 end),0) [ИтогоПоСотруднику]

				   , isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]

				   , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]

				   , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]

				   , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
				   , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end), 0) [Отложено уникальных]
				   , isnull(count( distinct case when status='Доработка' then [Номер заявки] end), 0) [Доработка уникальных]

				   , isnull(sum(case when status='Не вернувшиеся с доработки' then 1 else 0 end ),0) [Не вернувшиеся с доработки]
				   --DWH-2209
				   --, isnull(sum(case when status='Autoapprove' then 1 else 0 end),0) AS Autoapprove
				   --DWH-2374
				   , isnull(sum(case when status='Autoapprove_KD' then 1 else 0 end),0) AS Autoapprove_KD
				   , isnull(sum(case when status='Autoapprove_KD_fin_appr' then 1 else 0 end),0) AS Autoapprove_KD_fin_appr

				   , isnull(sum(case when status='Autoapprove_VK' then 1 else 0 end),0) AS Autoapprove_VK
				   , isnull(sum(case when status='Autoapprove_VK_fin_appr' then 1 else 0 end),0) AS Autoapprove_VK_fin_appr

				   , isnull(sum(case when status='Autoapprove_KD_VK' then 1 else 0 end),0) AS Autoapprove_KD_VK
				   , isnull(sum(case when status='Autoapprove_KD_VK_fin_appr' then 1 else 0 end),0) AS Autoapprove_KD_VK_fin_appr

				   , isnull(sum(case when status='Autoapprove_KD_VK_total' then 1 else 0 end),0) AS Autoapprove_KD_VK_total
				   , isnull(sum(case when status='Autoapprove_KD_VK_total_fin_appr' then 1 else 0 end),0) AS Autoapprove_KD_VK_total_fin_appr

				   , isnull(sum(case when status='KD_IN' then 1 else 0 end),0) AS KD_IN
				   , isnull(sum(case when status='KD_IN_fin_appr' then 1 else 0 end),0) AS KD_IN_fin_appr

				   , isnull(sum(case when status='VK_IN' then 1 else 0 end),0) AS VK_IN
				   , isnull(sum(case when status='VK_IN_fin_appr' then 1 else 0 end),0) AS VK_IN_fin_appr

				   --, isnull(sum(case when status in ('ПроверкаДохода') then 1 else 0 end),0) ПроверкаДохода

				from #fedor_verificator_report
			   group by ProductType_Code, Дата, Сотрудник
			)
			,c2 as (
           
			   select 
					ProductType_Code
					, [ФИО сотрудника верификации/чекер]
					, дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 

					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end) ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end) avgВремяЗатрачено 
			   from  #fedor_verificator_report
			   group by ProductType_Code, [ФИО сотрудника верификации/чекер], дата
			)
			  select c1.*
				   , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
				   , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
				   , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				into #ReportByEmployeeAgg
				from c1 
				left join c2 
					ON c1.ProductType_Code = c2.ProductType_Code
					AND c1.Дата=c2.Дата 
					AND c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##ReportByEmployeeAgg
				SELECT * INTO ##ReportByEmployeeAgg FROM #ReportByEmployeeAgg
			END

			-- аггрегация за месяц       
			drop table if exists #ReportByEmployeeAgg_m

			;
			with c1 as (
			  select 
					ProductType_Code
					, format(Дата,'yyyyMM01') Дата
				   , Сотрудник
				   , isnull(sum(case when status in ('ВК','Отказано','Не вернувшиеся с доработки') then 1 else 0 end),0) ИтогоПоСотруднику
				   , isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]
				   , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
				   , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
				   , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
				   , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
				   , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]

				   --, isnull(sum(case when status in ('ПроверкаДохода') then 1 else 0 end),0) ПроверкаДохода
				from #fedor_verificator_report
			   group by ProductType_Code, format(Дата,'yyyyMM01'), Сотрудник
			)
			,c2 as (
           
			   select ProductType_Code
					, [ФИО сотрудника верификации/чекер]
					, format(Дата,'yyyyMM01') дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
			   from  #fedor_verificator_report
			   group by ProductType_Code, [ФИО сотрудника верификации/чекер],format(Дата,'yyyyMM01')
			)
			  select c1.*
				   , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
				   , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
				   , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				into #ReportByEmployeeAgg_m
				from c1 
					LEFT JOIN c2 
						ON c1.ProductType_Code = c2.ProductType_Code
						AND c1.Дата=c2.Дата 
						AND c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
        
			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##ReportByEmployeeAgg_m
				SELECT * INTO ##ReportByEmployeeAgg_m FROM #ReportByEmployeeAgg_m
			END
                
			--
			-- Аггрегированные данные
			--
        
			-- подневная аггрегация        
			drop table if exists #KDEmployees

			--var 2
			select distinct 
				PT.ProductType_Code
				, acc_period 
				, empl_id 
				, Employee 
				, [Status] 
			into #KDEmployees
			from #employee_rows_d AS E
				INNER JOIN #t_ProductType AS PT
					ON 1=1
			where [Status] in ('Контроль данных') 
			and Employee in (select * from #curr_employee_cd)

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##KDEmployees
				SELECT * INTO ##KDEmployees FROM #KDEmployees
			END

			--помесячная аггрегация             
			drop table if exists #KDEmployees_m

			--var 2
			select DISTINCT
				PT.ProductType_Code	
				, acc_period 
				, empl_id 
				, Employee 
				, [Status] 
			into #KDEmployees_m
			from #employee_rows_m
				INNER JOIN #t_ProductType AS PT
					ON 1=1
			where [Status] in ('Контроль данных') 
				and Employee in (select * from #curr_employee_cd)

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##KDEmployees_m
				SELECT * INTO ##KDEmployees_m FROM #KDEmployees_m
			END

		--DWH-242
		--отображение единого матричного отчета по месяцам (показатели - в столбцах)
		IF @Page = 'KD.Monthly.ALL' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1 BEGIN
				select @localProcessGUID = @ProcessGUID
			END
			ELSE BEGIN
				select @localProcessGUID = newid()
			END
			
			drop table if exists #ReportByEmployeeAgg_KD_m_Unique2
			select 
				ProductType_Code
				, Дата = cast(format(Дата,'yyyyMM01') as date)
				, Сотрудник             
				, Отложена = isnull(count(distinct case when status='Отложена' then [Номер заявки]  end), 0)
			into #ReportByEmployeeAgg_KD_m_Unique2
			from #fedor_verificator_report
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date), Сотрудник

			DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL AS T WHERE T.ProcessGUID = @localProcessGUID

			;with agg as (
				--'KD.Monthly.Total'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '1. Кол-во заявок'
					, Сумма = isnull(a.КоличествоЗаявок, 0)
				from #KDEmployees_m e
					left join #ReportByEmployeeAgg_m a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Monthly.Unic'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '2. Кол-во уникальных заявок'
					, Сумма = isnull(a.ИтогоПоСотруднику, 0)
				from #KDEmployees_m as e
					left join #ReportByEmployeeAgg_m as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Monthly.Approved'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '4. Кол-во одобренных заявок'
					, Сумма = isnull(a.ВК, 0)
				from #KDEmployees_m as e
					left join #ReportByEmployeeAgg_m as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Monthly.Postpone'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '6. Кол-во отложенных заявок'
					, Сумма = isnull(a.Отложена, 0)
				from #KDEmployees_m as e
					left join #ReportByEmployeeAgg_m as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Monthly.PostponeUnique'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '7. Кол-во уникальных отложенных заявок' 
					, Сумма = isnull(a.Отложена, 0)
				from #KDEmployees_m as e
					left join #ReportByEmployeeAgg_KD_m_Unique2 as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Monthly.Rework'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '8. Кол-во заявок, отправленных на доработку'
					, Сумма = isnull(a.Доработка, 0)
				from #KDEmployees_m as e
					left join #ReportByEmployeeAgg_m as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(A.Сумма, '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			UNION ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee ='ИТОГО'
				, A.dt 
				, A.indicator
				, Сумма = format(sum(A.Сумма), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'KD.Monthly.AvgTime'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, a.ВремяЗатрачено
					, a.КоличествоЗаявок
					, Indicator = '3. Ср. время обработки одной заявки'
					, Сумма = case when a.КоличествоЗаявок<>0 then a.ВремяЗатрачено/a.КоличествоЗаявок else 0 end 
				from #KDEmployees_m as e
					left join #ReportByEmployeeAgg_m as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = isnull(convert(nvarchar, cast(A.Сумма as datetime),8), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee = 'ИТОГО' 
				, A.dt 
				, A.indicator 
				, Сумма = 
					CASE 
						WHEN sum(A.КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8), '0')
						ELSE '0'
					END
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'KD.Monthly.AR'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, Indicator = '5. Approval Rate (%)'
					, a.ВК
					, a.ИтогоПоСотруднику
					, Сумма = case when a.ИтогоПоСотруднику<>0 then a.ВК*1.0/a.ИтогоПоСотруднику else 0 end
				from #KDEmployees_m as e
					left join #ReportByEmployeeAgg_m as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(isnull(Сумма,0) * 100, '0.00')
			--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_AR
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee		='ИТОГО' 
				, A.dt 
				, A.indicator
				, Сумма = format(isnull(
							case 
								when sum(A.ИтогоПоСотруднику)<>0 
									then sum(A.ВК*1.0)/sum(A.ИтогоПоСотруднику)
								else 0 
							end, 0)
							* 100, '0.00')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			IF @isFill_All_Tables = 1
			BEGIN
				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.ALL', @localProcessGUID
			END
			ELSE BEGIN
				select T.empl_id, T.Employee, T.dt, T.indicator, T.Сумма
				from tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL as T

				DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_ALL AS T WHERE T.ProcessGUID = @localProcessGUID

				RETURN 0
			END
		end
		--// 'KD.Monthly.ALL'

		--отображение единого матричного отчета по дням (показатели - в столбцах)
		IF @Page = 'KD.Daily.ALL' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1 BEGIN
				select @localProcessGUID = @ProcessGUID
			END
			ELSE BEGIN
				select @localProcessGUID = newid()
			END

			drop table if exists #fedor_verificator_report_KD_Unique2
			select 
				ProductType_Code
				, Дата
				, Сотрудник             
				, ОтложенаУникальные = isnull(count(distinct case when status='Отложена' then [Номер заявки]  end), 0)
			into #fedor_verificator_report_KD_Unique2
			from #fedor_verificator_report
			group by ProductType_Code, Дата, Сотрудник

			DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL AS T WHERE T.ProcessGUID = @localProcessGUID

			;with agg as (
				--'KD.Daily.Total'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '1. Кол-во заявок'
					, Сумма = isnull(a.КоличествоЗаявок, 0)
				from #KDEmployees e
					left join #ReportByEmployeeAgg a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Daily.Unic'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '2. Кол-во уникальных заявок'
					, Сумма = isnull(a.ИтогоПоСотруднику, 0)
				from #KDEmployees as e
					left join #ReportByEmployeeAgg as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Daily.Approved'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '4. Кол-во одобренных заявок'
					, Сумма = isnull(a.ВК, 0)
				from #KDEmployees as e
					left join #ReportByEmployeeAgg as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Daily.Postpone'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '6. Кол-во отложенных заявок'
					, Сумма = isnull(a.Отложена, 0)
				from #KDEmployees as e
					left join #ReportByEmployeeAgg as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Daily.PostponeUnique'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '7. Кол-во уникальных отложенных заявок' 
					, Сумма = isnull(a.ОтложенаУникальные, 0)
				from #KDEmployees as e
					left join #fedor_verificator_report_KD_Unique2 as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'KD.Daily.Rework'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '8. Кол-во заявок, отправленных на доработку'
					, Сумма = isnull(a.Доработка, 0)
				from #KDEmployees as e
					left join #ReportByEmployeeAgg as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(A.Сумма, '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			UNION ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee ='ИТОГО'
				, A.dt 
				, A.indicator
				, Сумма = format(sum(A.Сумма), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'KD.Daily.AvgTime'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, a.ВремяЗатрачено
					, a.КоличествоЗаявок
					, Indicator = '3. Ср. время обработки одной заявки'
					, Сумма = case when a.КоличествоЗаявок<>0 then a.ВремяЗатрачено/a.КоличествоЗаявок else 0 end 
				from #KDEmployees as e
					left join #ReportByEmployeeAgg as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = isnull(convert(nvarchar, cast(A.Сумма as datetime),8), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee = 'ИТОГО' 
				, A.dt 
				, A.indicator 
				, Сумма = 
					CASE 
						WHEN sum(A.КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8), '0')
						ELSE '0'
					END
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'KD.Daily.AR'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, Indicator = '5. Approval Rate (%)'
					, a.ВК
					, a.ИтогоПоСотруднику
					, Сумма = case when a.ИтогоПоСотруднику<>0 then a.ВК*1.0/a.ИтогоПоСотруднику else 0 end
				from #KDEmployees as e
					left join #ReportByEmployeeAgg as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(isnull(Сумма,0) * 100, '0.00')
			--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_AR
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee		='ИТОГО' 
				, A.dt 
				, A.indicator
				, Сумма = format(isnull(
							case 
								when sum(A.ИтогоПоСотруднику)<>0 
									then sum(A.ВК*1.0)/sum(A.ИтогоПоСотруднику)
								else 0 
							end, 0)
							* 100, '0.00')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			IF @isFill_All_Tables = 1
			BEGIN
				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.ALL', @localProcessGUID
			END
			ELSE BEGIN
				select T.empl_id, T.Employee, T.dt, T.indicator, T.Сумма
				from tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL as T

				DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_ALL AS T WHERE T.ProcessGUID = @localProcessGUID

				RETURN 0
			END
		end
		--// 'KD.Daily.ALL'

	END
	--// KD.%

	------------------------------
	--- Проверка способа выдачи PSV.%
	------------------------------
	if @Page in (
		'PSV.Monthly.ALL',
		'PSV.Daily.ALL',
		'PSV.Daily.Common',
		'PSV.Monthly.Common'
	) OR @isFill_All_Tables = 1
	begin
		drop table if exists #fedor_verificator_report_PSV
		drop table if exists #details_PSV

		select * 
		into #details_PSV
		from #t_dm_FedorVerificationRequests_without_coll
		where 1=1
			AND Статус in ('Проверка способа выдачи')
			--AND (Работник not in (select * from #curr_employee_vr) 
			--	OR Работник IN (select Employee from #curr_employee_vr)
			--)
			--and [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
         
		create INDEX ix_Статус_Задача
		ON #details_PSV([Статус] ,[Статус следующий], [Задача],[Задача следующая],[Состояние заявки], [Состояние заявки следующая])
		INCLUDE ([Номер заявки],[ФИО клиента],[Дата статуса],[ВремяЗатрачено],[ШагЗаявки],[ПоследнийШаг], [Работник],[Работник_Пред],[Работник_След])
		
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##details_PSV
			SELECT * INTO ##details_PSV FROM #details_PSV
		END

		;with rework as (
			select 'Доработка' [status]
				, cast([Дата статуса] as date) Дата
				, [Дата статуса]
				, [ФИО клиента]
				, [Номер заявки] 
				--, Сотрудник=СотрудникПоследнегоСтатуса
				--, [ФИО сотрудника верификации/чекер]
				, Сотрудник=Работник_Пред --Работник_След
				--, [ФИО сотрудника верификации/чекер] = Работник
				, [ФИО сотрудника верификации/чекер]
				, ВремяЗатрачено
				,ТипКлиента
			from #details_PSV
			where Задача='task:Требуется доработка' 
				and [Состояние заявки]='Отложена' 
				--and Статус in('Контроль данных') 
			)
		,rework1 as (
			select 'Доработка' [status]
				, cast([Дата статуса] as date) Дата
				, [Дата статуса]
				, [ФИО клиента]
				, [Номер заявки] 
				--, Сотрудник=СотрудникПоследнегоСтатуса
				--, [ФИО сотрудника верификации/чекер]
				, Сотрудник=Работник_След -- Работник_Пред --Работник_След
				--, [ФИО сотрудника верификации/чекер] = Работник
				, [ФИО сотрудника верификации/чекер]
				, ВремяЗатрачено
				,ТипКлиента
			from #details_PSV
			where [Задача следующая]='task:Требуется доработка' 
			and [Состояние заявки следующая]='Отложена' 
			--and Статус in('Контроль данных') 
			and ШагЗаявки= ПоследнийШаг
		)
		,postpone as (
			select 'Отложена' [status]
				, cast([Дата статуса] as date) Дата
				, [Дата статуса] ДатаИВремяСтатуса
				, [ФИО клиента]
				, [Номер заявки]  
				--, Сотрудник=СотрудникПоследнегоСтатуса
				--, [ФИО сотрудника верификации/чекер]
				, Сотрудник=Работник_Пред --Работник_След
				--, [ФИО сотрудника верификации/чекер] = Работник
				, [ФИО сотрудника верификации/чекер]
				, ВремяЗатрачено
				,ТипКлиента
			from #details_PSV
			where Задача='task:Отложена' 
				and [Состояние заявки] in('Отложена') 
				--and Статус in('Контроль данных')
		)
		,postpone1 as (
			select 'Отложена' [status]
				, cast([Дата статуса] as date) Дата
				, [Дата статуса] ДатаИВремяСтатуса
				, [ФИО клиента]
				, [Номер заявки]  
				--, Сотрудник=СотрудникПоследнегоСтатуса
				--, [ФИО сотрудника верификации/чекер]
				, Сотрудник=Работник_Пред --Работник_След --2023-11-20
				--, [ФИО сотрудника верификации/чекер] = Работник
				, [ФИО сотрудника верификации/чекер]
				, ВремяЗатрачено
				,ТипКлиента
			from #details_PSV
			where [Задача следующая]='task:Отложена' 
				and [Состояние заявки следующая] in('Отложена') 
				--and Статус in('Контроль данных') 
				and ШагЗаявки= ПоследнийШаг
		)
		--отказано сотрудником
		select 'Отказано' [status]
			, cast([Дата статуса] as date) Дата
			, [Дата статуса] ДатаИВремяСтатуса
			, [ФИО клиента]
			, [Номер заявки]  
			--, Сотрудник=СотрудникПоследнегоСтатуса
			--, [ФИО сотрудника верификации/чекер]
			, Сотрудник=Работник_Пред --Работник_След
			--, [ФИО сотрудника верификации/чекер] = Работник
			, [ФИО сотрудника верификации/чекер]
			, ВремяЗатрачено
			,ТипКлиента
		into #fedor_verificator_report_PSV
		from #details_PSV AS N
		where [Статус следующий]='Отказано' 
			--and Статус in('Верификация Call 1.5')
			--AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects_PSV AS J WHERE J.IdClientRequest = N.IdClientRequest)
		-- 
		union all
		select * from postpone
		union all 
		select * from postpone1
          

		-- доработка
		union 
		select * from rework
		union all 
		select * from rework1

		union 
		select 'ВК' [status]
			, cast([Дата статуса] as date) Дата
			, [Дата статуса] ДатаИВремяСтатуса
			, [ФИО клиента]
			, [Номер заявки] 
			--, Сотрудник=СотрудникПоследнегоСтатуса
			--, [ФИО сотрудника верификации/чекер]
			, Сотрудник=Работник_Пред --Работник_След
			--, [ФИО сотрудника верификации/чекер] = Работник
			, [ФИО сотрудника верификации/чекер]
			, ВремяЗатрачено 
			,ТипКлиента
		from #details_PSV AS R
		where 1=1
			and R.[Статус следующий] IN ('Одобрено')
			--and (R.Статус IN ('Верификация Call 1.5') 
			--AND R.[Статус следующий] IN ('Ожидание подписи документов EDO', 'Переподписание первого пакета', 'Верификация Call 2'))
			----DWH-2429 --одобрено сотрудником, но отказано автоматически
			--OR (
			--	R.[Статус следующий]='Отказано' and R.Статус in('Верификация Call 1.5')
			--	AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects_PSV AS J WHERE J.IdClientRequest = R.IdClientRequest)
			--)
			 
		union
		select 'Новая' [status]
			, cast([Дата статуса] as date) Дата
			, [Дата статуса] ДатаИВремяСтатуса
			, [ФИО клиента]
			, [Номер заявки] 
			--, Сотрудник=СотрудникПоследнегоСтатуса
			--, [ФИО сотрудника верификации/чекер]
			, Сотрудник=Работник_Пред --Работник_След
			--, [ФИО сотрудника верификации/чекер] = Работник
			, [ФИО сотрудника верификации/чекер]
			, ВремяЗатрачено 
			,ТипКлиента
		from #details_PSV
		where Задача='task:Новая' 
			--and Статус in('Контроль данных')

		UNION
		--DWH-2020
		select 'Новая_Уникальная' [status]
			, cast([Дата статуса] as date) Дата
			, [Дата статуса] ДатаИВремяСтатуса
			, [ФИО клиента]
			, [Номер заявки] 
			--, Сотрудник=СотрудникПоследнегоСтатуса
			--, [ФИО сотрудника верификации/чекер]
			, Сотрудник=Работник_Пред --Работник_След
			--, [ФИО сотрудника верификации/чекер] = Работник
			, [ФИО сотрудника верификации/чекер]
			, ВремяЗатрачено 
			,ТипКлиента
		from #details_PSV
		where Задача='task:Новая' 
			--and Статус in('Контроль данных')
			AND [Задача следующая] <> 'task:Автоматически отложено'

		union 
		select 'task:В работе' [status]
			, cast([Дата статуса] as date) Дата
			, [Дата статуса] ДатаИВремяСтатуса
			, [ФИО клиента]
			, [Номер заявки] 
			--, Сотрудник=СотрудникПоследнегоСтатуса
			--, [ФИО сотрудника верификации/чекер]
			, Сотрудник=Работник_Пред --Работник_След
			--, [ФИО сотрудника верификации/чекер] = Работник
			, [ФИО сотрудника верификации/чекер]
			, ВремяЗатрачено
			,ТипКлиента
		from #details_PSV
		where Задача='task:В работе' 
			--and Статус in('Контроль данных')
        
        
		--select * from  #fedor_verificator_report_PSV where дата='20200922' and status like 'до%'
		CREATE NONCLUSTERED INDEX ix_ДатаИВремяСтатуса
		ON #fedor_verificator_report_PSV([ДатаИВремяСтатуса])
		INCLUDE ([status],[Дата],[Номер заявки],[Сотрудник])

		ALTER TABLE #fedor_verificator_report_PSV
		ADD ProductType_Code varchar(100) NULL

		UPDATE F
		SET ProductType_Code = R.ProductType_Code
		FROM #fedor_verificator_report_PSV AS F
			INNER JOIN (
					SELECT DISTINCT D.ProductType_Code, D.[Номер заявки] 
					FROM #t_dm_FedorVerificationRequests_without_coll AS D
				) AS R
				ON R.[Номер заявки] = F.[Номер заявки]

		--сумма по всем Типам продукта
		--if @ProductTypeCode = 'installment,pdl' 
		-- если отчет строится по нескольким типам продукта
		-- добавить суммарные показатели
		if (select count(*) from @t_ProductTypeCode as t) > 1
		begin
			INSERT #fedor_verificator_report_PSV
			(
				status,
				Дата,
				ДатаИВремяСтатуса,
				[ФИО клиента],
				[Номер заявки],
				Сотрудник,
				[ФИО сотрудника верификации/чекер],
				ВремяЗатрачено,
				ТипКлиента,
				ProductType_Code
			)
			SELECT 
				F.status,
				F.Дата,
				F.ДатаИВремяСтатуса,
				F.[ФИО клиента],
				F.[Номер заявки],
				F.Сотрудник,
				F.[ФИО сотрудника верификации/чекер],
				F.ВремяЗатрачено,
				F.ТипКлиента,
				ProductType_Code = 'ALL'
			FROM #fedor_verificator_report_PSV AS F
		end

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##fedor_verificator_report_PSV
			SELECT * INTO ##fedor_verificator_report_PSV FROM #fedor_verificator_report_PSV
		END

		drop table if exists #ReportByEmployeeAgg_PSV

		;with c1 as (
			select 
				ProductType_Code
				, Дата
				--, Сотрудник
				, Сотрудник = [ФИО сотрудника верификации/чекер]
				, isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2020

				--DWH-2286
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Первичный' then 1 else 0 end),0) [Новая_Уникальная Первичный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Повторный' then 1 else 0 end),0) [Новая_Уникальная Повторный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Докредитование' then 1 else 0 end),0) [Новая_Уникальная Докредитование]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Параллельный' then 1 else 0 end),0) [Новая_Уникальная Параллельный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента IS NULL then 1 else 0 end),0) [Новая_Уникальная Не определен]

				, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
				, isnull(sum(case when status in ('ВК','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
				, isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]
				, isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
				, isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
				, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
				, isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
				, isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
			from #fedor_verificator_report_PSV
			group by ProductType_Code, Дата, 
				--Сотрудник
				[ФИО сотрудника верификации/чекер]
		)
		,c2 as (
			select 
				ProductType_Code
				, [ФИО сотрудника верификации/чекер]
				, дата
				, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
				, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
				, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
			from  #fedor_verificator_report_PSV
			group by ProductType_Code, [ФИО сотрудника верификации/чекер], дата
		)
		select 
			c1.*
			, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
			, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
			, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
		into #ReportByEmployeeAgg_PSV
		from c1 
			left join c2 
				on c1.ProductType_Code=c2.ProductType_Code
				and c1.Дата=c2.Дата 
				and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg_PSV
			SELECT * INTO ##ReportByEmployeeAgg_PSV FROM #ReportByEmployeeAgg_PSV
		END

       
		-- аггрегация за месяц       
		drop table if exists #ReportByEmployeeAgg_m_PSV

		;with c1 as (
			select
				ProductType_Code
				, format(Дата,'yyyyMM01') Дата
				--, Сотрудник
				, Сотрудник = [ФИО сотрудника верификации/чекер]
				, isnull(sum(case when status in ('ВК','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
				, isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]
				, isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
				, isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
				, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
				, isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
				, isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
			from #fedor_verificator_report_PSV
			group by ProductType_Code, format(Дата,'yyyyMM01'), 
				--Сотрудник
				[ФИО сотрудника верификации/чекер]
		)
		,c2 as (
			select
				ProductType_Code
				, [ФИО сотрудника верификации/чекер]
				, format(Дата,'yyyyMM01') дата
				, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
				, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
				, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
			from  #fedor_verificator_report_PSV
			group by ProductType_Code, [ФИО сотрудника верификации/чекер],format(Дата,'yyyyMM01')
		)
		select 
			c1.*
			, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
			, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
			, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
		into #ReportByEmployeeAgg_m_PSV
		from c1 
			left join c2 
				on c1.ProductType_Code=c2.ProductType_Code
				and c1.Дата=c2.Дата 
				and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg_m_PSV
			SELECT * INTO ##ReportByEmployeeAgg_m_PSV FROM #ReportByEmployeeAgg_m_PSV
		END
	

		-- подневная аггрегация        
		drop table if exists #PSVEmployees
         
		select distinct 
			PT.ProductType_Code
			, acc_period 
			, empl_id 
			, Employee 
			, [Status] 
		into #PSVEmployees
		from #employee_rows_d AS E
			INNER JOIN #t_ProductType AS PT
				ON 1=1
		where [Status] in ('Проверка способа выдачи') 
			and Employee in (select * from #curr_employee_vr)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##PSVEmployees
			SELECT * INTO ##PSVEmployees FROM #PSVEmployees
		END

		--помесячная аггрегация             
		drop table if exists #PSVEmployees_m
         
		select distinct 
			PT.ProductType_Code	
			, acc_period 
			, empl_id 
			, Employee 
			, [Status] 
		into #PSVEmployees_m
		from #employee_rows_m
			INNER JOIN #t_ProductType AS PT
				ON 1=1
		where [Status] in ('Проверка способа выдачи') 
			and Employee in (select * from #curr_employee_vr)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##PSVEmployees_m
			SELECT * INTO ##PSVEmployees_m FROM #PSVEmployees_m
		END


		--DWH-242
		--отображение единого матричного отчета по месяцам (показатели - в столбцах)
		IF @Page = 'PSV.Monthly.ALL' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1 BEGIN
				select @localProcessGUID = @ProcessGUID
			END
			ELSE BEGIN
				select @localProcessGUID = newid()
			END
			
			drop table if exists #ReportByEmployeeAgg_PSV_m_Unique2
			select 
				ProductType_Code
				, Дата = cast(format(Дата,'yyyyMM01') as date)
				, Сотрудник             
				, Отложена = isnull(count(distinct case when status='Отложена' then [Номер заявки]  end), 0)
			into #ReportByEmployeeAgg_PSV_m_Unique2
			from #fedor_verificator_report_PSV
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date), Сотрудник

			DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL AS T WHERE T.ProcessGUID = @localProcessGUID

			;with agg as (
				--'PSV.Monthly.Total'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '1. Кол-во заявок'
					, Сумма = isnull(a.КоличествоЗаявок, 0)
				from #PSVEmployees_m e
					left join #ReportByEmployeeAgg_m_PSV a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Monthly.Unic'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '2. Кол-во уникальных заявок'
					, Сумма = isnull(a.ИтогоПоСотруднику, 0)
				from #PSVEmployees_m as e
					left join #ReportByEmployeeAgg_m_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Monthly.Approved'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '4. Кол-во одобренных заявок'
					, Сумма = isnull(a.ВК, 0)
				from #PSVEmployees_m as e
					left join #ReportByEmployeeAgg_m_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Monthly.Postpone'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '6. Кол-во отложенных заявок'
					, Сумма = isnull(a.Отложена, 0)
				from #PSVEmployees_m as e
					left join #ReportByEmployeeAgg_m_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Monthly.PostponeUnique'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '7. Кол-во уникальных отложенных заявок' 
					, Сумма = isnull(a.Отложена, 0)
				from #PSVEmployees_m as e
					left join #ReportByEmployeeAgg_PSV_m_Unique2 as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Monthly.Rework'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '8. Кол-во заявок, отправленных на доработку'
					, Сумма = isnull(a.Доработка, 0)
				from #PSVEmployees_m as e
					left join #ReportByEmployeeAgg_m_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(A.Сумма, '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			UNION ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee ='ИТОГО'
				, A.dt 
				, A.indicator
				, Сумма = format(sum(A.Сумма), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'PSV.Monthly.AvgTime'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, a.ВремяЗатрачено
					, a.КоличествоЗаявок
					, Indicator = '3. Ср. время обработки одной заявки'
					, Сумма = case when a.КоличествоЗаявок<>0 then a.ВремяЗатрачено/a.КоличествоЗаявок else 0 end 
				from #PSVEmployees_m as e
					left join #ReportByEmployeeAgg_m_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = isnull(convert(nvarchar, cast(A.Сумма as datetime),8), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee = 'ИТОГО' 
				, A.dt 
				, A.indicator 
				, Сумма = 
					CASE 
						WHEN sum(A.КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8), '0')
						ELSE '0'
					END
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'PSV.Monthly.AR'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, Indicator = '5. Approval Rate (%)'
					, a.ВК
					, a.ИтогоПоСотруднику
					, Сумма = case when a.ИтогоПоСотруднику<>0 then a.ВК*1.0/a.ИтогоПоСотруднику else 0 end
				from #PSVEmployees_m as e
					left join #ReportByEmployeeAgg_m_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(isnull(Сумма,0) * 100, '0.00')
			--INTO tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_AR
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee		='ИТОГО' 
				, A.dt 
				, A.indicator
				, Сумма = format(isnull(
							case 
								when sum(A.ИтогоПоСотруднику)<>0 
									then sum(A.ВК*1.0)/sum(A.ИтогоПоСотруднику)
								else 0 
							end, 0)
							* 100, '0.00')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			IF @isFill_All_Tables = 1
			BEGIN
				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'PSV.Monthly.ALL', @localProcessGUID
			END
			ELSE BEGIN
				select T.empl_id, T.Employee, T.dt, T.indicator, T.Сумма
				from tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL as T

				--if @isDebug = 0 begin
				DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_ALL AS T 
				WHERE T.ProcessGUID = @localProcessGUID
				--end

				RETURN 0
			END
		end
		--// 'PSV.Monthly.ALL'

		--отображение единого матричного отчета по дням (показатели - в столбцах)
		IF @Page = 'PSV.Daily.ALL' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1 BEGIN
				select @localProcessGUID = @ProcessGUID
			END
			ELSE BEGIN
				select @localProcessGUID = newid()
			END

			drop table if exists #fedor_verificator_report_PSV_Unique2
			select 
				ProductType_Code
				, Дата
				, Сотрудник             
				, ОтложенаУникальные = isnull(count(distinct case when status='Отложена' then [Номер заявки]  end), 0)
			into #fedor_verificator_report_PSV_Unique2
			from #fedor_verificator_report_PSV
			group by ProductType_Code, Дата, Сотрудник

			DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL AS T WHERE T.ProcessGUID = @localProcessGUID

			;with agg as (
				--'PSV.Daily.Total'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '1. Кол-во заявок'
					, Сумма = isnull(a.КоличествоЗаявок, 0)
				from #PSVEmployees e
					left join #ReportByEmployeeAgg_PSV a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Daily.Unic'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '2. Кол-во уникальных заявок'
					, Сумма = isnull(a.ИтогоПоСотруднику, 0)
				from #PSVEmployees as e
					left join #ReportByEmployeeAgg_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Daily.Approved'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '4. Кол-во одобренных заявок'
					, Сумма = isnull(a.ВК, 0)
				from #PSVEmployees as e
					left join #ReportByEmployeeAgg_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Daily.Postpone'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '6. Кол-во отложенных заявок'
					, Сумма = isnull(a.Отложена, 0)
				from #PSVEmployees as e
					left join #ReportByEmployeeAgg_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Daily.PostponeUnique'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '7. Кол-во уникальных отложенных заявок' 
					, Сумма = isnull(a.ОтложенаУникальные, 0)
				from #PSVEmployees as e
					left join #fedor_verificator_report_PSV_Unique2 as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code

				UNION ALL
				--'PSV.Daily.Rework'
				select 
					e.ProductType_Code
					, empl_id
					, e.Employee		
					, dt = e.acc_period  
					, Indicator = '8. Кол-во заявок, отправленных на доработку'
					, Сумма = isnull(a.Доработка, 0)
				from #PSVEmployees as e
					left join #ReportByEmployeeAgg_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(A.Сумма, '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			UNION ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee ='ИТОГО'
				, A.dt 
				, A.indicator
				, Сумма = format(sum(A.Сумма), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'PSV.Daily.AvgTime'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, a.ВремяЗатрачено
					, a.КоличествоЗаявок
					, Indicator = '3. Ср. время обработки одной заявки'
					, Сумма = case when a.КоличествоЗаявок<>0 then a.ВремяЗатрачено/a.КоличествоЗаявок else 0 end 
				from #PSVEmployees as e
					left join #ReportByEmployeeAgg_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = isnull(convert(nvarchar, cast(A.Сумма as datetime),8), '0')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee = 'ИТОГО' 
				, A.dt 
				, A.indicator 
				, Сумма = 
					CASE 
						WHEN sum(A.КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8), '0')
						ELSE '0'
					END
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			--'PSV.Daily.AR'
			;with agg as (
				select 
					e.ProductType_Code
					, e.empl_id
					, e.Employee		
					, dt = e.acc_period
					, Indicator = '5. Approval Rate (%)'
					, a.ВК
					, a.ИтогоПоСотруднику
					, Сумма = case when a.ИтогоПоСотруднику<>0 then a.ВК*1.0/a.ИтогоПоСотруднику else 0 end
				from #PSVEmployees as e
					left join #ReportByEmployeeAgg_PSV as a 
						on e.acc_period=a.Дата 
						and e.Employee=a.Сотрудник
						and e.ProductType_Code = a.ProductType_Code
			)
			INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = A.empl_id + 100 * PT.ProductType_Order
				, A.Employee
				, A.dt
				, A.Indicator
				, Сумма = format(isnull(Сумма,0) * 100, '0.00')
			--INTO tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_AR
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			union all
			select 
				ProcessGUID = @localProcessGUID,
				empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
				, Employee		='ИТОГО' 
				, A.dt 
				, A.indicator
				, Сумма = format(isnull(
							case 
								when sum(A.ИтогоПоСотруднику)<>0 
									then sum(A.ВК*1.0)/sum(A.ИтогоПоСотруднику)
								else 0 
							end, 0)
							* 100, '0.00')
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code
			group by A.ProductType_Code, A.dt, A.indicator
			UNION ALL
			SELECT DISTINCT
				ProcessGUID = @localProcessGUID,
				empl_id = 100 * PT.ProductType_Order
				, Employee = PT.ProductType_Name
				, A.dt 
				, A.indicator
				, Сумма = NULL
			from agg AS A
				INNER JOIN #t_ProductType AS PT
					ON PT.ProductType_Code = A.ProductType_Code


			IF @isFill_All_Tables = 1
			BEGIN
				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'PSV.Daily.ALL', @localProcessGUID
			END
			ELSE BEGIN
				select T.empl_id, T.Employee, T.dt, T.indicator, T.Сумма
				from tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL as T

				DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_ALL AS T WHERE T.ProcessGUID = @localProcessGUID

				RETURN 0
			END
		end
		--// 'PSV.Daily.ALL'

	END
	--// PSV.%

	------------------------------
	-- Общий отчет KD.%
	------------------------------
	IF @Page IN (
		'KD.Monthly.Common'
		,'KD.Daily.Common'
		,'KD.HoursGroupMonth'
		,'KD.HoursGroupMonthUnique'
		,'KD.HoursGroupDays'
		,'KD.HoursGroupDaysUnique'
		,'KD.Monthly.Autoapprove'
		,'KD.Daily.Autoapprove'
	) OR @isFill_All_Tables = 1
	BEGIN
		drop table if exists #indicator_for_controldata
		create table #indicator_for_controldata(
				[num_rows] numeric(6,2) --int null 
			, [name_indicator] nvarchar(250) null
		)

		insert into #indicator_for_controldata([num_rows] ,[name_indicator])
		values
			 (1 ,'Общее кол-во заведенных заявок')
		   , (2 ,'Кол-во автоматических отказов Логином')
		   , (3 ,'%  автоматических отказов Логином')

		   , (4 ,'Общее кол-во уникальных заявок на этапе')
		   , (4.01 ,'Первичный')
		   , (4.02 ,'Повторный')
		   , (4.03 ,'Докредитование')
		   , (4.04 ,'Не определен')

		   --, (5 ,'Общее кол-во уникальных заявок на этапе (Новые регионы)')

		   , (6 ,'Общее кол-во заявок на этапе')

		   , (7, 'TTY  - количество заявок рассмотренных в течение 10 минут на этапе')
		   , (8 ,'TTY  - % заявок рассмотренных в течение 10 минут на этапе')
		   , (10 ,'Среднее время заявки в ожидании очереди на этапе')
		   , (12 ,'Средний Processing time на этапе (время обработки заявки)')

		   , (15 ,'Кол-во одобренных заявок после этапа')

		   , (18 ,'Кол-во отказов со стороны сотрудников')

		   , (21 ,'Approval rate - % одобренных после этапа')

		   , (25 ,'Общее кол-во отложенных заявок на этапе')
		   , (26 ,'Уникальное кол-во отложенных заявок на этапе')

		   , (28 ,'Кол-во заявок на этапе, отправленных на доработку')
        
		   , (31 ,'Кол-во заявок, не вернувшихся с доработки')

		   , (33 ,'% заявок, не вернувшихся с доработки')

		   --, (35 ,'Количество заявок без проверки дохода')
		   --, (37 ,'Количество заявок с проверкой дохода')

		if @ProductTypeCode in ('bigInstallment')
		begin
			insert into #indicator_for_controldata([num_rows] ,[name_indicator])
			values
				(5 ,'Общее кол-во уникальных заявок на этапе (Новые регионы)')
		end


		if @ProductTypeCode <> 'installment,pdl'
		begin
			/*
			1.	"Количество заявок без проверки дохода" 
			(считаем заявку сюда, если по чек-листу НЕ была назначена проверка дохода)
			2.	"Количество заявок с проверкой дохода" 
			(считаем заявку сюда, если по чек-листу была назначена проверка дохода)
			2.1. Из них проверка 2-НДФЛ - количество заявок, по которым по чек-листу была назначена проверка дохода, и чекер на этапе проверки добавил документ указанного типа (справка 2-НДФЛ)
			2.2. Из них выписка по счету банка - количество заявок, по которым по чек-листу была назначена проверка дохода, и чекер на этапе проверки добавил документ указанного типа
			2.3. Справка по форме кредитной организации или по форме работодателя - количество заявок, по которым по чек-листу была назначена проверка дохода, и чекер на этапе проверки добавил документ указанного типа
			2.4. Выписка со счета, на который зачисляются официальные выплаты (пенсии, алименты, дивиденды, соц.пособия) - количество заявок, по которым по чек-листу была назначена проверка дохода, и чекер на этапе проверки добавил документ указанного типа
			2.5. Справка из ПФР / СФР о размере установленной пенсии - количество заявок, по которым по чек-листу была назначена проверка дохода, и чекер на этапе проверки добавил документ указанного типа
			2.6. Пенсионное удостоверение с указанием размера выплаты - количество заявок, по которым по чек-листу была назначена проверка дохода, и чекер на этапе проверки добавил документ указанного типа
			2.7. Справка по налогу на профессиональный доход - количество заявок, по которым по чек-листу была назначена проверка дохода, и чекер на этапе проверки добавил документ указанного типа
			--
			1
			Справка 2-НДФЛ

			2
			Выписка по счету из банка бумажный или эл. вид

			3
			Справка по форме банка/работодателя

			4

			5
			Справка из ПФР/СФР о размере устан. пенсии

			6
			Пенсионное удостоверение / Справка о размере пенсии

			7
			*/

			insert into #indicator_for_controldata([num_rows] ,[name_indicator])
			values
			(35 ,'Количество заявок без проверки дохода')
			, (37 ,'Количество заявок с проверкой дохода')

			--1
			--, (41 ,'Справка 2-НДФЛ')
			, (41 ,'Из них проверка 2-НДФЛ')
			--2
			--, (42 ,'Выписка по счету из банка бумажный или эл. вид')
			, (42 ,'Из них выписка по счету банка')
			--3
			--, (43 ,'Справка по форме банка/работодателя')
			, (43 ,'Справка по форме кредитной организации или по форме работодателя')
			--4 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
			, (44 ,'Выписка со счета, на который зачисляются официальные выплаты')
			--5
			--, (45 ,'Справка из ПФР/СФР о размере устан. пенсии')
			, (45 ,'Справка из ПФР / СФР о размере установленной пенсии')
			--6
			--, (46 ,'Пенсионное удостоверение / Справка о размере пенсии')
			, (46 ,'Пенсионное удостоверение с указанием размера выплаты')
			--7 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
			, (47 ,'Справка по налогу на профессиональный доход')
		end

		drop table if exists #indicator_for_Autoapprove
		create table #indicator_for_Autoapprove(
			[num_rows] numeric(5,1) --int null 
			, [name_indicator] nvarchar(250) null
		)
		insert into #indicator_for_Autoapprove([num_rows] ,[name_indicator])
		values
		   --  (1 ,'Уникальное количество заявок autoapprove')
		   --, (2 ,'% заявок autoapprove от одобренных КД')

			--  (1 ,'Уникальное количество заявок autoapprove КД')
			--, (2 ,'Уникальное количество заявок autoapprove КД, финальное одобрение')

			  (3 ,'Уникальное количество заявок autoapprove ВК')
			, (4 ,'Уникальное количество заявок autoapprove ВК, финальное одобрение')

			--, (5 ,'Уникальное количество заявок autoapprove КД + ВК')
			--, (6 ,'Уникальное количество заявок autoapprove КД + ВК, финальное одобрение')

			--, (7 ,'Уникальное количество заявок autoapprove (всего)')
			--, (8 ,'Уникальное количество заявок autoapprove (всего), финальное одобрение')

			--, (9 ,'% заявок autoapprove пропустивших этап КД (не назначался КД)')
			--, (10 ,'% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение')

			, (11 ,'% заявок autoapprove от поступивших ВК (не назначался ВК)')
			, (12 ,'% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение')

			--, (13 ,'% заявок autoapprove КД + ВК (от поступивших на КД)')
			--, (14 ,'% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение')

		------- всп.таблица показатели для статусов (Общий лист)
		drop table if exists #indicator_for_vc_va
		create table #indicator_for_vc_va (
			   [num_rows] numeric(6,2) --int null 
			 , [name_indicator] nvarchar(250) null
			 )
		--OLD
		/*
		insert into #indicator_for_vc_va([num_rows] ,[name_indicator])
		values (1 ,'Общее кол-во заведенных заявок Call2')
			, (2 ,'Кол-во автоматических отказов Call2')
			, (3 ,'%  автоматических отказов Call2')
			, (4 ,'Общее кол-во уникальных заявок на этапе')
			, (5 ,'Общее кол-во заявок на этапе')
			, (8 ,'TTY  - % заявок рассмотренных в течение 30 минут на этапе')
			, (9 ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')
			, (10 ,'Среднее время заявки в ожидании очереди на этапе')
			, (12 ,'Средний Processing time на этапе (время обработки заявки)')
			, (15 ,'Кол-во одобренных заявок после этапа')
			, (18 ,'Кол-во отказов со стороны сотрудников')
			, (21 ,'Approval rate - % одобренных после этапа')
			, (24 ,'Approval rate % Логином')

		   , (25 ,'Контактность общая')
		   , (26 ,'Контактность по одобренным')
		   , (27 ,'Контактность по отказным')

		   , (28 ,'Общее кол-во отложенных заявок на этапе')
		   , (29 ,'Уникальное кол-во отложенных заявок на этапе')
		   , (30 ,'Кол-во заявок на этапе, отправленных на доработку')
			, (31 ,'Take rate Уровень выдачи, выраженный через одобрения')
			, (32 ,'Кол-во заявок в статусе "Займ выдан",шт.')
		*/

		--NEW
		insert into #indicator_for_vc_va([num_rows] ,[name_indicator])
		values (1 ,'Общее кол-во заведенных заявок Call2')
		, (2 ,'Кол-во автоматических отказов Call2')
		, (3 ,'%  автоматических отказов Call2')
		, (4 ,'Общее кол-во уникальных заявок на этапе ВК')
		, (4.01 ,'Первичный')
		, (4.02 ,'Повторный')
		, (4.03 ,'Докредитование')
		, (4.04 ,'Не определен')

		, (5 ,'Общее кол-во заявок на этапе ВК')

		-- только БЕЗЗАЛОГ
		, (7.01, 'TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК')
		, (7.02, 'TTY - % заявок рассмотренных в течение 8 минут на этапе ВК')

		-- только ИНСТОЛМЕНТ
		, (9.01, 'TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК')
		, (9.02, 'TTY - % заявок рассмотренных в течение 9 минут на этапе ВК')

		-- только PDL
		, (11.01 ,'TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК')
		, (11.02 ,'TTY - % заявок рассмотренных в течение 6 минут на этапе ВК')

		--, (9 ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')

		, (17 ,'Среднее время заявки в ожидании очереди на этапе ВК')
		, (18 ,'Средний Processing time на этапе (время обработки заявки) ВК')
		, (19 ,'Кол-во одобренных заявок после этапа ВК')
		, (20 ,'Кол-во отказов со стороны сотрудников ВК')
		, (21 ,'Approval rate - % одобренных после этапа ВК')
		--, (24 ,'Approval rate % Логином')

		--, (22 ,'Контактность общая')
		--, (23 ,'Контактность по одобренным')
		--, (24 ,'Контактность по отказным')

		, (25 ,'Общее кол-во отложенных заявок на этапе ВК')
		, (26 ,'Уникальное кол-во отложенных заявок на этапе ВК')
		, (28 ,'Кол-во заявок на этапе, отправленных на доработку ВК')
		--, (31 ,'Take rate Уровень выдачи, выраженный через одобрения')
		, (31 ,'Take up Количество выданных заявок')
		--, (32 ,'Кол-во заявок в статусе "Займ выдан",шт.')
		, (33 ,'Take up % выданных заявок от одобренных на Call3')
		--DWH-2309
		, (35, 'Кол-во уникальных заявок в статусе Договор подписан')

		-- только БЕЗЗАЛОГ
		, (41.01, 'TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК')
		, (41.02 ,'TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК')

		-- только ИНСТОЛМЕНТ
		, (43.01 ,'TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК')
		, (43.02 ,'TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК')

		-- только PDL
		, (45.01, 'TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК')
		, (45.02, 'TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК')



		IF @Page = 'KD.HoursGroupDaysUnique' OR @isFill_All_Tables = 1 --241
		BEGIN
				IF @isFill_All_Tables = 1
				BEGIN
					--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDaysUnique
					DELETE T
					FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDaysUnique AS T
					WHERE T.ProcessGUID = @ProcessGUID

					;with c2 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, 25 as Интервал
							, cast(Дата as date)  as дата
							, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date)  
					),
					c3 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, datepart(hour, ДатаИВремяСтатуса) Интервал
							, cast(Дата as date) as дата
							, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
					)
					INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDaysUnique
					SELECT
						ProcessGUID = @ProcessGUID,
						isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
					--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDaysUnique
					FROM (
						SELECT DISTINCT 
							--Интервал,
							Интервал = Интервал + 100 * PT.ProductType_Order,
							cast(Дата as date) Дата,
							ИнтервалСтрока 
						FROM #HoursDays
							INNER JOIN #t_ProductType AS PT
								ON 1=1
					) AS hd
					LEFT join (
						select 
							c2.ProductType_Code
							--, c2.Интервал
							, Интервал = c2.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c2.Новая,0) КоличествоЗаявок 
							, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c2 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c2.ProductType_Code
						union all
						select 
							c3.ProductType_Code
							--, c3.Интервал
							, Интервал = c3.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c3.Новая,0) КоличествоЗаявок 
							, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c3 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c3.ProductType_Code
						) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
					UNION ALL
					SELECT DISTINCT 
						ProcessGUID = @ProcessGUID,
						КоличествоЗаявок = NULL,
						Интервал = 100 * PT.ProductType_Order - 1,
						Дата = cast(Дата as date),
						ИнтервалСтрока = PT.ProductType_Name
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1

					INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
					SELECT getdate(), 'KD.HoursGroupDaysUnique', @ProcessGUID
				END
				ELSE BEGIN
					/*
					--var 1
					;with c2 as (
           
						select null as [ФИО сотрудника верификации/чекер]
							, 25 as Интервал
							, cast(Дата as date)  as дата
							, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						--group by  [ФИО сотрудника верификации/чекер],дата
						group by cast(Дата as date)  
					),
					c3 as (
           
						select null as [ФИО сотрудника верификации/чекер]
							, datepart(hour, ДатаИВремяСтатуса) Интервал
							, cast(Дата as date) as дата
							, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						--group by  [ФИО сотрудника верификации/чекер],дата
						group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
					)
					SELECT  isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
					FROM (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
					LEFT join (
						select c2.Интервал
							, дата
							, isnull(c2.Новая,0) КоличествоЗаявок 
							, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c2 
						union all
						select c3.Интервал
							, дата
							, isnull(c3.Новая,0) КоличествоЗаявок 
							, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c3 
						) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
					*/

					;with c2 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, 25 as Интервал
							, cast(Дата as date)  as дата
							, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date)  
					),
					c3 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, datepart(hour, ДатаИВремяСтатуса) Интервал
							, cast(Дата as date) as дата
							, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
					)
					SELECT
						isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
					FROM (
						SELECT DISTINCT 
							--Интервал,
							Интервал = Интервал + 100 * PT.ProductType_Order,
							cast(Дата as date) Дата,
							ИнтервалСтрока 
						FROM #HoursDays
							INNER JOIN #t_ProductType AS PT
								ON 1=1
					) AS hd
					LEFT join (
						select 
							c2.ProductType_Code
							--, c2.Интервал
							, Интервал = c2.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c2.Новая,0) КоличествоЗаявок 
							, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c2 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c2.ProductType_Code
						union all
						select 
							c3.ProductType_Code
							--, c3.Интервал
							, Интервал = c3.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c3.Новая,0) КоличествоЗаявок 
							, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c3 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c3.ProductType_Code
						) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
					UNION ALL
					SELECT DISTINCT 
						КоличествоЗаявок = NULL,
						Интервал = 100 * PT.ProductType_Order - 1,
						Дата = cast(Дата as date),
						ИнтервалСтрока = PT.ProductType_Name
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1

					RETURN 0
				END
		END
		--// 'KD.HoursGroupDaysUnique'

		IF @Page = 'KD.HoursGroupDays' OR @isFill_All_Tables = 1 --241
		BEGIN
				IF @isFill_All_Tables = 1
				BEGIN
					--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays
					DELETE T
					FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays AS T
					WHERE T.ProcessGUID = @ProcessGUID
					/*
					--var 1
					;with c2 as (
						select null as [ФИО сотрудника верификации/чекер]
							, 25 as Интервал
							, cast(Дата as date)  as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						--group by  [ФИО сотрудника верификации/чекер],дата
						group by cast(Дата as date)  
					),
					c3 as (
						select null as [ФИО сотрудника верификации/чекер]
							, datepart(hour, ДатаИВремяСтатуса) Интервал
							, cast(Дата as date) as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						--group by  [ФИО сотрудника верификации/чекер],дата
						group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
					)
					INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays
					SELECT
						ProcessGUID = @ProcessGUID,
						isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
					--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays
					FROM (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
					LEFT join (
						select c2.Интервал
							, дата
							, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c2 
						union all
						select c3.Интервал
							, дата
							, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c3 
						) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
					*/

					--var 2
					;with c2 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, 25 as Интервал
							, cast(Дата as date)  as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date)  
					),
					c3 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, datepart(hour, ДатаИВремяСтатуса) Интервал
							, cast(Дата as date) as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
					)
					INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays
					SELECT
						ProcessGUID = @ProcessGUID,
						isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
					--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupDays
					FROM (
						SELECT DISTINCT 
							--Интервал,
							Интервал = Интервал + 100 * PT.ProductType_Order,
							cast(Дата as date) Дата,
							ИнтервалСтрока 
						FROM #HoursDays
							INNER JOIN #t_ProductType AS PT
								ON 1=1
					) AS hd
					LEFT join (
						select 
							c2.ProductType_Code
							--, c2.Интервал
							, Интервал = c2.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c2 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c2.ProductType_Code
						union all
						select 
							c3.ProductType_Code
							--, c3.Интервал
							, Интервал = c3.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c3 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c3.ProductType_Code
						) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
					UNION ALL
					SELECT DISTINCT 
						ProcessGUID = @ProcessGUID,
						КоличествоЗаявок = NULL,
						Интервал = 100 * PT.ProductType_Order - 1,
						Дата = cast(Дата as date),
						ИнтервалСтрока = PT.ProductType_Name
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1

					INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
					SELECT getdate(), 'KD.HoursGroupDays', @ProcessGUID
				END
				ELSE BEGIN
					/*
					--var 1
					;with c2 as (
						select null as [ФИО сотрудника верификации/чекер]
							, 25 as Интервал
							, cast(Дата as date)  as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						--group by  [ФИО сотрудника верификации/чекер],дата
						group by cast(Дата as date)  
					),
					c3 as (
           
						select null as [ФИО сотрудника верификации/чекер]
							, datepart(hour, ДатаИВремяСтатуса) Интервал
							, cast(Дата as date) as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from  #fedor_verificator_report
						--group by  [ФИО сотрудника верификации/чекер],дата
						group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
					)
					SELECT
						isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
					FROM (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
					LEFT join (
						select c2.Интервал
							, дата
							, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c2 
						union all
						select c3.Интервал
							, дата
							, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c3 
						) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
					*/

					--var 2
					;with c2 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, 25 as Интервал
							, cast(Дата as date)  as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date)  
					),
					c3 as (
						SELECT
							ProductType_Code
							, NULL as [ФИО сотрудника верификации/чекер]
							, datepart(hour, ДатаИВремяСтатуса) Интервал
							, cast(Дата as date) as дата
							, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
							, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
							, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
						from #fedor_verificator_report
						group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
					)
					SELECT
						isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
					FROM (
						SELECT DISTINCT 
							--Интервал,
							Интервал = Интервал + 100 * PT.ProductType_Order,
							cast(Дата as date) Дата,
							ИнтервалСтрока 
						FROM #HoursDays
							INNER JOIN #t_ProductType AS PT
								ON 1=1
					) AS hd
					LEFT join (
						select 
							c2.ProductType_Code
							--, c2.Интервал
							, Интервал = c2.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c2 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c2.ProductType_Code
						union all
						select 
							c3.ProductType_Code
							--, c3.Интервал
							, Интервал = c3.Интервал + 100 * PT.ProductType_Order
							, дата
							, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
							, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
							, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						from c3 
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = c3.ProductType_Code
						) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
					UNION ALL
					SELECT DISTINCT 
						КоличествоЗаявок = NULL,
						Интервал = 100 * PT.ProductType_Order - 1,
						Дата = cast(Дата as date),
						ИнтервалСтрока = PT.ProductType_Name
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1

					RETURN 0
				END
		END
		--// 'KD.HoursGroupDays'


		IF @Page = 'KD.HoursGroupMonthUnique' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonthUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonthUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
			
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonthUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonthUnique
				FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
					select c2.Интервал
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
					union all
					select c3.Интервал
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
					) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
					select 
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					select 
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonthUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupMonthUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
				
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
				FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
					select c2.Интервал
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
					union all
					select c3.Интервал
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
					) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
					select 
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
				
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					select 
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
		END
		--// 'KD.HoursGroupMonthUnique'


		-- Лист "КД. Общее количество по часам"
		IF @Page = 'KD.HoursGroupMonth' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth
				DELETE T
				FROM tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth
				FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
					select c2.Интервал
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
					union all
					select c3.Интервал
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
					) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
					select 
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_HoursGroupMonth
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupMonth', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
					select c2.Интервал
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
					union all
					select c3.Интервал
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
					) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
					select 
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
		END
		--// 'KD.HoursGroupMonth'

		IF @Page IN ('KD.Daily.Common', 'KD.Daily.Autoapprove') OR @isFill_All_Tables = 1
		BEGIN

			DROP table if exists #waitTime

			;with r AS (
				select 
				r.ProductType_Code
				, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
				, [Дата статуса]
				, [Дата след.статуса]
				,Работник [ФИО сотрудника верификации/чекер]
				, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику],  [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

				from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
				where [Состояние заявки]='Ожидание'
				and r.Статус='Контроль данных'
				--DWH-2019
				AND NOT (
					r.Задача='task:Новая'
					AND r.[Задача следующая] = 'task:Автоматически отложено'
				)

				and [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to 
				and 
				(Работник in (select e.Employee from #KDEmployees e)
				-- для учета, когда ожидание назначено на сотрудника
				or Назначен in (select e.Employee from #KDEmployees e)
				)
			)
			select 
				r.ProductType_Code
				, [Дата статуса]=cast([Дата статуса] as date) 
				,  avg( datediff(second,[Дата статуса], [Дата след.статуса]))   duration
			into #waitTime
			from r
			where  datediff(second,[Дата статуса], [Дата след.статуса])>0
			group by r.ProductType_Code, cast([Дата статуса] as date)
 

			DROP table if exists #verif_KC

			select 
				r.ProductType_Code
				, [Дата статуса]=cast([Дата статуса] as date) 
				, count(distinct [Номер заявки]) cnt
			into #verif_KC
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
			WHERE [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
				AND  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
			group by r.ProductType_Code, cast([Дата статуса] as date) 
 
			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##verif_KC
				SELECT * INTO ##verif_KC FROM #verif_KC
			END

			-- считаем уникальных отложенных по КД
			drop table if exists #ReportByEmployeeAgg_KD_UniquePostone

			;with c1 as (
			  select ProductType_Code
					, Дата
				  -- , Сотрудник   
				   --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
					, isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеKD]
               
				from #fedor_verificator_report
			   group by ProductType_Code, Дата
				  -- , Сотрудник
			)        
			  select c1.*              
				into #ReportByEmployeeAgg_KD_UniquePostone
				from c1 
            

			-- посчитаем количество уникальных отложенных КД теперь и по дням
			DROP table if exists #postpone_unique_kd_daily
 
			SELECT 
				ProductType_Code,
				[Дата статуса]=cast(([Дата]) as date),
				sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
			into #postpone_unique_kd_daily
			from #ReportByEmployeeAgg_KD_UniquePostone p
			GROUP by ProductType_Code, cast(([Дата]) as date)



			DROP table if exists #all_requests
  
			SELECT 
				D.ProductType_Code
				, D.[Дата заведения заявки] 
				, count(distinct D.[Номер заявки]) as Qty 
				--, count(distinct case when D.ПроверкаДохода = 1 then D.[Номер заявки] else null end) as ПроверкаДохода
				----1
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка 2-НДФЛ'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка 2-НДФЛ]
				----2
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Выписка по счету из банка бумажный или эл. вид'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Выписка по счету из банка бумажный или эл. вид]
				----3
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка по форме банка/работодателя'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка по форме банка/работодателя]
				----4 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Выписка со счета, на который зачисляются официальные выплаты'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Выписка со счета, на который зачисляются официальные выплаты]
				----5
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка из ПФР/СФР о размере устан. пенсии'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка из ПФР/СФР о размере устан. пенсии]
				----6
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Пенсионное удостоверение / Справка о размере пенсии'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Пенсионное удостоверение / Справка о размере пенсии]
				----7 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка по налогу на профессиональный доход'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка по налогу на профессиональный доход]

			into #all_requests
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
				join #calendar c 
					on c.dt_day=D.[Дата заведения заявки]
			where  D.[Дата статуса]>= @dt_from and  D.[Дата статуса]<@dt_to
			group by D.ProductType_Code, D.[Дата заведения заявки] 

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##all_requests
				SELECT * INTO ##all_requests FROM #all_requests
			END


			--ПроверкаДохода
			DROP table if exists #t_income_verification
  
			SELECT 
				D.ProductType_Code
				, D.Дата
				, count(distinct D.[Номер заявки]) as Qty 
				, count(distinct case when D.ПроверкаДохода = 1 then D.[Номер заявки] else null end) as ПроверкаДохода
				--1 Справка 2-НДФЛ
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка 2-НДФЛ'
						then D.[Номер заявки] 
					else null 
					end) as [Справка 2-НДФЛ]
				--2 Выписка по счету из банка бумажный или эл. вид
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Выписка по счету из банка бумажный или эл. вид'
						then D.[Номер заявки] 
					else null 
					end) as [Выписка по счету из банка бумажный или эл. вид]
				--3 Справка по форме банка/работодателя
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка по форме банка/работодателя'
						then D.[Номер заявки] 
					else null 
					end) as [Справка по форме банка/работодателя]
				--4 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Выписка со счета, на который зачисляются официальные выплаты'
						then D.[Номер заявки] 
					else null 
					end) as [Выписка со счета, на который зачисляются официальные выплаты]
				--5
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка из ПФР/СФР о размере устан. пенсии'
						then D.[Номер заявки] 
					else null 
					end) as [Справка из ПФР/СФР о размере устан. пенсии]
				--6
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Пенсионное удостоверение / Справка о размере пенсии'
						then D.[Номер заявки] 
					else null 
					end) as [Пенсионное удостоверение / Справка о размере пенсии]
				--7 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка по налогу на профессиональный доход'
						then D.[Номер заявки] 
					else null 
					end) as [Справка по налогу на профессиональный доход]

			into #t_income_verification
			from (
				select 
					A.ProductType_Code,
					A.[Номер заявки],
					A.ПроверкаДохода,
					A.[Тип документа подтверждающего доход],
					Дата = min(cast(A.[Дата статуса] as date))
				from #t_dm_FedorVerificationRequests_without_coll_ALL AS A
				where 1=1
					--and A.[Дата статуса] >= @dt_from and A.[Дата статуса] < @dt_to
					--AND A.ПроверкаДохода = 1
					and A.Статус in ('Контроль данных')
				group by
					A.ProductType_Code,
					A.[Номер заявки],
					A.ПроверкаДохода,
					A.[Тип документа подтверждающего доход]
				) as D
			where 1=1
				and D.Дата >= @dt_from and D.Дата < @dt_to
			group by D.ProductType_Code, D.Дата

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##t_income_verification
				SELECT * INTO ##t_income_verification FROM #t_income_verification
			END
   
			-- TTY
			DROP table if exists #tty_kd
			/*
			--var 1
			select ProductType_Code
				, Дата
				, [Номер заявки]
				, Сотрудник
				, [ФИО сотрудника верификации/чекер]
				--, ВремяЗатрачено
				, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
				--, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:07:00' then '-' else 'tty' end tty_flag
				, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:02:00' then '-' else 'tty' end tty_flag
			into #tty_kd
			from #fedor_verificator_report where status='task:В работе'
			*/
			/*
			--var 2
			select 
				A.ProductType_Code
				, A.Дата
				, A.[Номер заявки]
				, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
				, tty_flag = CASE when cast(cast(A.ВремяЗатрачено as datetime) as time)>'00:10:00' then '-' else 'tty' end
			into #tty_kd
			FROM #fedor_verificator_report AS A
			WHERE A.status='task:В работе'
			--FROM (
			--		SELECT 
			--			R.ProductType_Code,
			--			R.[Номер заявки],
			--			Дата = max(R.Дата),
			--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
			--		FROM #fedor_verificator_report AS R
			--		WHERE R.status='task:В работе'
			--		GROUP BY R.ProductType_Code, R.[Номер заявки]
			--	) AS A
			*/

			--var.3  DWH-2681
			--перед 'task:В работе' есть Новая_Уникальная
			--и между ними нет статусов 'Доработка' или 'Отложена'
			select 
				A.ProductType_Code
				, A.Дата
				, A.[Номер заявки]
				, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено + isnull(B.ВремяЗатрачено, 0) as datetime) as time)
				, tty_flag = CASE when cast(cast(A.ВремяЗатрачено + isnull(B.ВремяЗатрачено, 0) as datetime) as time)>'00:10:00' then '-' else 'tty' end
			into #tty_kd
			FROM #fedor_verificator_report AS A --'task:В работе'
				LEFT JOIN #fedor_verificator_report AS B --Новая_Уникальная
					ON B.ProductType_Code = A.ProductType_Code
					AND B.[Номер заявки] = A.[Номер заявки]
					AND B.Дата = A.Дата
					AND B.status = 'Новая_Уникальная'
					AND B.ДатаИВремяСтатуса <= A.ДатаИВремяСтатуса
					--и между ними нет статусов 'Доработка' или 'Отложена'
					AND NOT EXISTS(
						SELECT TOP(1) 1
						FROM #fedor_verificator_report AS X
						WHERE X.ProductType_Code = A.ProductType_Code
							AND X.[Номер заявки] = A.[Номер заявки]
							AND X.status IN ('Доработка', 'Отложена')
							AND X.ДатаИВремяСтатуса BETWEEN B.ДатаИВремяСтатуса AND A.ДатаИВремяСтатуса
					)
			WHERE A.status='task:В работе'

			UNION

			--есть 'Новая_Уникальная', но после нее нет 'task:В работе'
			--так, чтобы между ними не было статусов 'Доработка' или 'Отложена'
			SELECT 
				A.ProductType_Code
				, A.Дата
				, A.[Номер заявки]
				, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
				, tty_flag = CASE when cast(cast(A.ВремяЗатрачено as datetime) as time)>'00:10:00' then '-' else 'tty' end
			FROM #fedor_verificator_report AS A --есть 'Новая_Уникальная', но нет 'task:В работе'
				LEFT JOIN #fedor_verificator_report AS B --'task:В работе'
					ON B.ProductType_Code = A.ProductType_Code
					AND B.[Номер заявки] = A.[Номер заявки]
					AND B.Дата = A.Дата
					AND B.status = 'task:В работе'
					AND B.ДатаИВремяСтатуса >= A.ДатаИВремяСтатуса
					--и между ними нет статусов 'Доработка' или 'Отложена'
					AND NOT EXISTS(
						SELECT TOP(1) 1
						FROM #fedor_verificator_report AS X
						WHERE X.ProductType_Code = A.ProductType_Code
							AND X.[Номер заявки] = A.[Номер заявки]
							AND X.status IN ('Доработка', 'Отложена')
							AND X.ДатаИВремяСтатуса BETWEEN A.ДатаИВремяСтатуса AND B.ДатаИВремяСтатуса
					)
			WHERE A.status = 'Новая_Уникальная'
				AND B.[Номер заявки] IS NULL --нет 'task:В работе'




			DROP table if exists #p 

			select 
				r.ProductType_Code
				, Дата = r.[Дата заведения заявки]

				--d.*
				, [Общее кол-во заявок на этапе] = isnull(d.[Общее кол-во заявок на этапе], '0')
				, [Кол-во одобренных заявок после этапа] = isnull(d.[Кол-во одобренных заявок после этапа], '0')
				, [Общее кол-во отложенных заявок на этапе] = isnull(d.[Общее кол-во отложенных заявок на этапе], '0')
				, [Кол-во заявок на этапе, отправленных на доработку] = isnull(d.[Кол-во заявок на этапе, отправленных на доработку], '0')
				, [Approval rate - % одобренных после этапа] = isnull(d.[Approval rate - % одобренных после этапа], '0')
				, [Кол-во отказов со стороны сотрудников] = isnull(d.[Кол-во отказов со стороны сотрудников], '0')
				, [Средний Processing time на этапе (время обработки заявки)] = isnull(d.[Средний Processing time на этапе (время обработки заявки)], '0')
				, [Кол-во заявок, не вернувшихся с доработки] = isnull(d.[Кол-во заявок, не вернувшихся с доработки], '0')

				, cast(format(r.Qty,'0') as nvarchar(50))[Общее кол-во заведенных заявок]
				, [Среднее время заявки в ожидании очереди на этапе] = 
					cast(
						isnull(
							format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (w.duration/60)),'00'),
							'00:00:00'
							)
						as nvarchar(50)
					) 
				,[Общее кол-во уникальных заявок на этапе] = isnull(new.[Общее кол-во уникальных заявок на этапе],0)

				,[Первичный] = isnull(new.[Первичный],0)
				,[Повторный] = isnull(new.[Повторный],0)
				,[Докредитование] = isnull(new.[Докредитование],0)
				,[Не определен] = isnull(new.[Не определен],0)

				,[Общее кол-во уникальных заявок на этапе (Новые регионы)] = 
					isnull(new.[Общее кол-во уникальных заявок на этапе (Новые регионы)],0)


				, cast(tty.cnt as nvarchar(50)) [TTY  - количество заявок рассмотренных в течение 10 минут на этапе]
				, cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50))
					as [TTY  - % заявок рассмотренных в течение 10 минут на этапе]
  
				, cast(isnull(kc.cnt,0) as nvarchar(50)) as [Кол-во автоматических отказов Логином]
				, cast(
					isnull(case when r.Qty<>0 then format(100.0*kc.cnt/r.Qty,'0') else '0' end,'0') +N'%' as nvarchar(50))
					as [%  автоматических отказов Логином]
				, [Уникальное кол-во отложенных заявок на этапе] = cast(format((isnull(u.ОтложенаУникальныеKD,0)),'0') as nvarchar(50))
         
				--, cast(case when r.Qty<>0 then format(100.0*d.[Кол-во заявок, не вернувшихся с доработки]/r.Qty,'0.0') else '0' end +N'%' as nvarchar(50))
				--	AS [% заявок, не вернувшихся с доработки]
				--DWH-2702
				, cast(case when d.[Кол-во заявок на этапе, отправленных на доработку]<>0 then format(100.0*d.[Кол-во заявок, не вернувшихся с доработки]/d.[Кол-во заявок на этапе, отправленных на доработку],'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок, не вернувшихся с доработки]

				--var 1
				--, cast(format(new.[Общее кол-во уникальных заявок на этапе] - new.ПроверкаДохода,'0') as nvarchar(50)) 
				--	AS [Количество заявок без проверки дохода]
				--, cast(format(new.ПроверкаДохода,'0') as nvarchar(50))
				--	AS [Количество заявок с проверкой дохода]

				--var 2
				--, cast(format(new.[Общее кол-во уникальных заявок на этапе] - r.ПроверкаДохода,'0') as nvarchar(50)) 
				--	AS [Количество заявок без проверки дохода]
				--, cast(format(r.ПроверкаДохода,'0') as nvarchar(50)) 
				--	AS [Количество заявок с проверкой дохода]

				--var 3
				, cast(format(isnull(new.[Общее кол-во уникальных заявок на этапе] - iv.ПроверкаДохода,0),'0') as nvarchar(50)) 
					AS [Количество заявок без проверки дохода]
				, cast(format(isnull(iv.ПроверкаДохода,0),'0') as nvarchar(50))
					AS [Количество заявок с проверкой дохода]

				--1
				, cast(format(isnull(iv.[Справка 2-НДФЛ],0),'0') as nvarchar(50)) 
					AS [Из них проверка 2-НДФЛ]
				--2
				, cast(format(isnull(iv.[Выписка по счету из банка бумажный или эл. вид],0),'0') as nvarchar(50)) 
					AS [Из них выписка по счету банка]
				--3
				, cast(format(isnull(iv.[Справка по форме банка/работодателя],0),'0') as nvarchar(50)) 
					AS [Справка по форме кредитной организации или по форме работодателя]
				--4 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, cast(format(isnull(iv.[Выписка со счета, на который зачисляются официальные выплаты],0),'0') as nvarchar(50)) 
					AS [Выписка со счета, на который зачисляются официальные выплаты]
				--5
				, cast(format(isnull(iv.[Справка из ПФР/СФР о размере устан. пенсии],0),'0') as nvarchar(50)) 
					AS [Справка из ПФР / СФР о размере установленной пенсии]
				--6
				, cast(format(isnull(iv.[Пенсионное удостоверение / Справка о размере пенсии],0),'0') as nvarchar(50)) 
					AS [Пенсионное удостоверение с указанием размера выплаты]
				--7 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, cast(format(isnull(iv.[Справка по налогу на профессиональный доход],0),'0') as nvarchar(50)) 
					AS [Справка по налогу на профессиональный доход]


				, cast(format(Autoappr.Autoapprove_KD,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД]
				, cast(format(Autoappr.Autoapprove_KD_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД, финальное одобрение]

				, cast(format(Autoappr.Autoapprove_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК]
				, cast(format(Autoappr.Autoapprove_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК, финальное одобрение]

				, cast(format(Autoappr.Autoapprove_KD_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК]
				, cast(format(Autoappr.Autoapprove_KD_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

				, cast(format(Autoappr.Autoapprove_KD_VK_total,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего)]
				, cast(format(Autoappr.Autoapprove_KD_VK_total_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего), финальное одобрение]
				--
				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove пропустивших этап КД (не назначался КД)]
				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

				, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove от поступивших ВК (не назначался ВК)]
				, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK_fin_appr / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove КД + ВК (от поступивших на КД)]
				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
			INTO #p
			from #all_requests as r
			left join (
				SELECT
					a.ProductType_Code
					, Дата
					 , cast(format(isnull(sum(a.КоличествоЗаявок),0),'0') as nvarchar(50)) [Общее кол-во заявок на этапе]

					 , cast(format(isnull(sum([ВК]),0),'0')as nvarchar(50)) [Кол-во одобренных заявок после этапа] 

					 , cast(format(isnull(sum(Отложена),0),'0') as nvarchar(50)) [Общее кол-во отложенных заявок на этапе]

					 , cast(format(isnull(sum(Доработка),0),'0') as nvarchar(50)) [Кол-во заявок на этапе, отправленных на доработку]

					 , cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) [Approval rate - % одобренных после этапа]

					 , cast(format(isnull(sum([Отказано]),0),'0')as nvarchar(50)) [Кол-во отказов со стороны сотрудников]

				  --   , cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))[Средний Processing time на этапе (время обработки заявки)]
				   , cast(isnull(convert(nvarchar,cast((case when sum(КоличествоЗаявок)<>0 then  sum(ВремяЗатрачено)/sum(КоличествоЗаявок) else 0 end) as datetime),8)  ,0) as nvarchar(50))[Средний Processing time на этапе (время обработки заявки)]

					, cast(format(isnull(sum([Не вернувшиеся с доработки]),0),'0') as nvarchar(50)) AS [Кол-во заявок, не вернувшихся с доработки]
      
				  from #ReportByEmployeeAgg a
				  where Сотрудник in (select * from #curr_employee_cd)
				 group by a.ProductType_Code, Дата
			) d
			on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки]=d.Дата

			LEFT JOIN (
				SELECT a.ProductType_Code
					, Дата
					 , cast(format(isnull(sum(Новая_Уникальная),0),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе]
					 --DWH-2286
					 , cast(format(isnull(sum([Новая_Уникальная Первичный]),0),'0')as nvarchar(50)) [Первичный]
					 , cast(format(isnull(sum([Новая_Уникальная Повторный]),0),'0')as nvarchar(50)) [Повторный]
					 , cast(format(isnull(sum([Новая_Уникальная Докредитование]),0),'0')as nvarchar(50)) [Докредитование]
					 , cast(format(isnull(sum([Новая_Уникальная Не определен]),0),'0')as nvarchar(50)) [Не определен]

					--DWH-563
					 , cast(format(isnull(sum(Новая_Уникальная_НовыйРегион),0),'0') as nvarchar(50))
						as [Общее кол-во уникальных заявок на этапе (Новые регионы)]

					 --, sum(ПроверкаДохода) AS ПроверкаДохода
				  from #ReportByEmployeeAgg a
				  GROUP BY a.ProductType_Code, Дата

				--DWH-1884 закомментарил
				--SELECT Дата
				--	 , cast(format(sum([ИтогоПоСотруднику]),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе]
				--  from #ReportByEmployeeAgg a
				--  --Только по сотрудникам, иначе в отчете будут учитываться данные от системых пользователей.
				--  WHERE a.Сотрудник in (select * from #curr_employee_cd)
				--  GROUP BY Дата
			) new 
			ON new.ProductType_Code = d.ProductType_Code 
			AND new.Дата=d.Дата

			left join #t_income_verification as iv
				on iv.ProductType_Code = d.ProductType_Code
				AND iv.Дата = d.Дата

			--join #all_requests r on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки]=d.Дата

			left join #waitTime w on w.ProductType_Code = d.ProductType_Code AND w.[Дата статуса]=d.Дата
			left join #postpone_unique_kd_daily AS u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
			left join (
				SELECT
					ProductType_Code
					, дата
					, count([Номер заявки]) cnt
				  -- , ВремяЗатрачено 
				  from #tty_kd
				where tty_flag='tty'
				group by ProductType_Code, дата 

			) tty on tty.ProductType_Code = d.ProductType_Code AND tty.Дата=d.Дата
			left join #verif_KC kc on kc.ProductType_Code = d.ProductType_Code AND kc.[Дата статуса]=d.Дата
			--select * from #p

			--DWH-2374
			LEFT JOIN (
				SELECT
					a.ProductType_Code
					, Дата
					, sum(Autoapprove_KD) AS Autoapprove_KD
					, sum(Autoapprove_KD_fin_appr) AS Autoapprove_KD_fin_appr

					, sum(Autoapprove_VK) AS Autoapprove_VK
					, sum(Autoapprove_VK_fin_appr) AS Autoapprove_VK_fin_appr

					, sum(Autoapprove_KD_VK) AS Autoapprove_KD_VK
					, sum(Autoapprove_KD_VK_fin_appr) AS Autoapprove_KD_VK_fin_appr

					, sum(Autoapprove_KD_VK_total) AS Autoapprove_KD_VK_total
					, sum(Autoapprove_KD_VK_total_fin_appr) AS Autoapprove_KD_VK_total_fin_appr

					, sum(KD_IN) AS KD_IN
					, sum(KD_IN_fin_appr) AS KD_IN_fin_appr

					, sum(VK_IN) AS VK_IN
					, sum(VK_IN_fin_appr) AS VK_IN_fin_appr
				  from #ReportByEmployeeAgg AS a
				  --01.01 не рабочий день, данные за этот день не учитываем
				  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
				  GROUP BY a.ProductType_Code, Дата
			) Autoappr on Autoappr.ProductType_Code = d.ProductType_Code AND Autoappr.Дата = d.Дата


			DROP table if exists #unp

			IF @Page IN ('KD.Daily.Common') OR @isFill_All_Tables = 1
			BEGIN
				SELECT ProductType_Code, Дата, indicator, Qty 
				into #unp
				from 
				(
				select
					PT.ProductType_Code
					, Дата = c.dt_day
					 ,[Общее кол-во заведенных заявок] = isnull(v.[Общее кол-во заведенных заявок], '0')
					 ,[Кол-во автоматических отказов Логином] = isnull(v.[Кол-во автоматических отказов Логином], '0')
					 ,[%  автоматических отказов Логином] = isnull(v.[%  автоматических отказов Логином], '0')
					 ,[Общее кол-во уникальных заявок на этапе] = isnull(v.[Общее кол-во уникальных заявок на этапе], '0')

					,[Первичный] = isnull(v.[Первичный], '0')
					,[Повторный] = isnull(v.[Повторный], '0')
					,[Докредитование] = isnull(v.[Докредитование], '0')
					,[Не определен] = isnull(v.[Не определен], '0')

					 ,[Общее кол-во уникальных заявок на этапе (Новые регионы)] = isnull(v.[Общее кол-во уникальных заявок на этапе (Новые регионы)], '0')

					 ,[Общее кол-во заявок на этапе] = isnull(v.[Общее кол-во заявок на этапе], '0')
					 ,[TTY  - количество заявок рассмотренных в течение 10 минут на этапе] = isnull(v.[TTY  - количество заявок рассмотренных в течение 10 минут на этапе], '0')
					 ,[TTY  - % заявок рассмотренных в течение 10 минут на этапе] = isnull(v.[TTY  - % заявок рассмотренных в течение 10 минут на этапе], '0')
					 ,[Среднее время заявки в ожидании очереди на этапе] = isnull(v.[Среднее время заявки в ожидании очереди на этапе], '0')
					 ,[Средний Processing time на этапе (время обработки заявки)] = isnull(v.[Средний Processing time на этапе (время обработки заявки)], '0')
					 ,[Кол-во одобренных заявок после этапа] = isnull(v.[Кол-во одобренных заявок после этапа], '0')
					 ,[Кол-во отказов со стороны сотрудников] = isnull(v.[Кол-во отказов со стороны сотрудников], '0')
					 ,[Approval rate - % одобренных после этапа] = isnull(v.[Approval rate - % одобренных после этапа], '0')
					 ,[Общее кол-во отложенных заявок на этапе] = isnull(v.[Общее кол-во отложенных заявок на этапе], '0')  
					 ,[Уникальное кол-во отложенных заявок на этапе] = isnull(v.[Уникальное кол-во отложенных заявок на этапе], '0')
					 ,[Кол-во заявок на этапе, отправленных на доработку] = isnull(v.[Кол-во заявок на этапе, отправленных на доработку], '0')
					 ,[Кол-во заявок, не вернувшихся с доработки] = isnull(v.[Кол-во заявок, не вернувшихся с доработки], '0')
					 ,[% заявок, не вернувшихся с доработки] = isnull(v.[% заявок, не вернувшихся с доработки], '0')
					 ,[Количество заявок без проверки дохода] = isnull(v.[Количество заявок без проверки дохода], '0')
					 ,[Количество заявок с проверкой дохода] = isnull(v.[Количество заявок с проверкой дохода], '0')
					,[Из них проверка 2-НДФЛ] = isnull(v.[Из них проверка 2-НДФЛ], '0')
					,[Из них выписка по счету банка] = isnull(v.[Из них выписка по счету банка], '0')
					,[Справка по форме кредитной организации или по форме работодателя] = isnull(v.[Справка по форме кредитной организации или по форме работодателя], '0')
					,[Выписка со счета, на который зачисляются официальные выплаты] = isnull(v.[Выписка со счета, на который зачисляются официальные выплаты], '0')
					,[Справка из ПФР / СФР о размере установленной пенсии] = isnull(v.[Справка из ПФР / СФР о размере установленной пенсии], '0')
					,[Пенсионное удостоверение с указанием размера выплаты] = isnull(v.[Пенсионное удостоверение с указанием размера выплаты], '0')
					,[Справка по налогу на профессиональный доход] = isnull(v.[Справка по налогу на профессиональный доход], '0')
				  --from #p
				from #calendar as c
					inner join #t_ProductType AS PT
						ON 1=1
					left join #p as v
						on v.Дата = c.dt_day
						and v.ProductType_Code = PT.ProductType_Code
				) p
				UNPIVOT
				(Qty for indicator in (
									  [Общее кол-во заведенных заявок]
									 ,[Кол-во автоматических отказов Логином]
									 ,[%  автоматических отказов Логином]
									 ,[Общее кол-во уникальных заявок на этапе]
									, [Первичный]
									, [Повторный]
									, [Докредитование]
									, [Не определен]
									 ,[Общее кол-во уникальных заявок на этапе (Новые регионы)]
									 ,[Общее кол-во заявок на этапе]
									 ,[TTY  - количество заявок рассмотренных в течение 10 минут на этапе]
									 ,[TTY  - % заявок рассмотренных в течение 10 минут на этапе]
									 ,[Среднее время заявки в ожидании очереди на этапе]
									 ,[Средний Processing time на этапе (время обработки заявки)]
									 ,[Кол-во одобренных заявок после этапа]
									 ,[Кол-во отказов со стороны сотрудников]
									 ,[Approval rate - % одобренных после этапа]
									 ,[Общее кол-во отложенных заявок на этапе]
									 ,[Уникальное кол-во отложенных заявок на этапе]
									 ,[Кол-во заявок на этапе, отправленных на доработку]
									 ,[Кол-во заявок, не вернувшихся с доработки]
									 ,[% заявок, не вернувшихся с доработки]
									 , [Количество заявок без проверки дохода]
									 , [Количество заявок с проверкой дохода]
									, [Из них проверка 2-НДФЛ]
									, [Из них выписка по счету банка]
									, [Справка по форме кредитной организации или по форме работодателя]
									, [Выписка со счета, на который зачисляются официальные выплаты]
									, [Справка из ПФР / СФР о размере установленной пенсии]
									, [Пенсионное удостоверение с указанием размера выплаты]
									, [Справка по налогу на профессиональный доход]
									)
			   ) as unpvt

				IF @isFill_All_Tables = 1
				BEGIN
					--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_Common
					DELETE T
					FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_Common AS T
					WHERE T.ProcessGUID = @ProcessGUID

					INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_Common
					SELECT
						ProcessGUID = @ProcessGUID,
						--i.num_rows 
						num_rows = i.num_rows + 0.1 * PT.ProductType_Order
						--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
						, empl_id =null
						, Employee =null
						, acc_period =Дата
						--,indicator =name_indicator
						,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
						, [Сумма] =null
						, Qty
						, Qty_dist=null
						, Tm_Qty =null--isnull(Tm_Qty,0.00)
					--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_Common
					from #unp u 
						JOIN #indicator_for_controldata i on u.indicator=i.name_indicator
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = u.ProductType_Code
					--ORDER BY i.num_rows

					INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
					SELECT getdate(), 'KD.Daily.Common', @ProcessGUID

				END
				ELSE BEGIN
					SELECT
						--i.num_rows 
						num_rows = i.num_rows + 0.1 * PT.ProductType_Order
						--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
						, empl_id =null
						, Employee =null
						, acc_period =Дата
						--,indicator =name_indicator
						,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
						, [Сумма] =null
						, Qty
						, Qty_dist=null
						, Tm_Qty =null--isnull(Tm_Qty,0.00)
					--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_Daily_Common
					from #unp u 
						JOIN #indicator_for_controldata i on u.indicator=i.name_indicator
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = u.ProductType_Code
					--ORDER BY i.num_rows

					RETURN 0
				END
			END --'KD.Daily.Common'

		END
		--// 'KD.Daily.Common', 'KD.Daily.Autoapprove'


		IF @Page IN ('KD.Monthly.Common', 'KD.Monthly.Autoapprove') OR @isFill_All_Tables = 1
		BEGIN
 
			DROP table if exists #verif_KC_m

			SELECT
				r.ProductType_Code
				, [Дата статуса] = cast(format([Дата статуса],'yyyyMM01') as date)
				, cnt = count(distinct [Номер заявки])
			into #verif_KC_m
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS r 
			WHERE [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
				AND  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
			group by r.ProductType_Code, cast(format([Дата статуса],'yyyyMM01') as date) 
 
			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##verif_KC_m
				SELECT * INTO ##verif_KC_m FROM #verif_KC_m
			END

			-- TTY
   
			drop table if exists #tty_kd_m
			/*
			--var 1
			select ProductType_Code
				, Дата
				, [Номер заявки]
				, Сотрудник
				, [ФИО сотрудника верификации/чекер]
				--, ВремяЗатрачено
				, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
				--, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:07:00' then '-' else 'tty' end tty_flag
				, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:02:00' then '-' else 'tty' end tty_flag
			into #tty_kd_m
			from #fedor_verificator_report where status='task:В работе'
			*/
			/*
			--var 2
			select 
				A.ProductType_Code
				, A.Дата
				, A.[Номер заявки]
				, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
				, tty_flag = CASE when cast(cast(A.ВремяЗатрачено as datetime) as time)>'00:10:00' then '-' else 'tty' end
			into #tty_kd_m
			FROM #fedor_verificator_report AS A
			WHERE A.status='task:В работе'
			--FROM (
			--		SELECT 
			--			R.ProductType_Code,
			--			R.[Номер заявки],
			--			Дата = max(R.Дата),
			--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
			--		FROM #fedor_verificator_report AS R
			--		WHERE R.status='task:В работе'
			--		GROUP BY R.ProductType_Code, R.[Номер заявки]
			--	) AS A
			*/

			--var.3  DWH-2681
			--перед 'task:В работе' есть Новая_Уникальная
			--и между ними нет статусов 'Доработка' или 'Отложена'
			select 
				A.ProductType_Code
				, A.Дата
				, A.[Номер заявки]
				, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено + isnull(B.ВремяЗатрачено, 0) as datetime) as time)
				, tty_flag = CASE when cast(cast(A.ВремяЗатрачено + isnull(B.ВремяЗатрачено, 0) as datetime) as time)>'00:10:00' then '-' else 'tty' end
			into #tty_kd_m
			FROM #fedor_verificator_report AS A --'task:В работе'
				LEFT JOIN #fedor_verificator_report AS B --Новая_Уникальная
					ON B.ProductType_Code = A.ProductType_Code
					AND B.[Номер заявки] = A.[Номер заявки]
					AND B.Дата = A.Дата
					AND B.status = 'Новая_Уникальная'
					AND B.ДатаИВремяСтатуса <= A.ДатаИВремяСтатуса
					--и между ними нет статусов 'Доработка' или 'Отложена'
					AND NOT EXISTS(
						SELECT TOP(1) 1
						FROM #fedor_verificator_report AS X
						WHERE X.ProductType_Code = A.ProductType_Code
							AND X.[Номер заявки] = A.[Номер заявки]
							AND X.status IN ('Доработка', 'Отложена')
							AND X.ДатаИВремяСтатуса BETWEEN B.ДатаИВремяСтатуса AND A.ДатаИВремяСтатуса
					)
			WHERE A.status='task:В работе'

			UNION

			--есть 'Новая_Уникальная', но после нее нет 'task:В работе'
			--так, чтобы между ними не было статусов 'Доработка' или 'Отложена'
			SELECT 
				A.ProductType_Code
				, A.Дата
				, A.[Номер заявки]
				, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
				, tty_flag = CASE when cast(cast(A.ВремяЗатрачено as datetime) as time)>'00:10:00' then '-' else 'tty' end
			FROM #fedor_verificator_report AS A --есть 'Новая_Уникальная', но нет 'task:В работе'
				LEFT JOIN #fedor_verificator_report AS B --'task:В работе'
					ON B.ProductType_Code = A.ProductType_Code
					AND B.[Номер заявки] = A.[Номер заявки]
					AND B.Дата = A.Дата
					AND B.status = 'task:В работе'
					AND B.ДатаИВремяСтатуса >= A.ДатаИВремяСтатуса
					--и между ними нет статусов 'Доработка' или 'Отложена'
					AND NOT EXISTS(
						SELECT TOP(1) 1
						FROM #fedor_verificator_report AS X
						WHERE X.ProductType_Code = A.ProductType_Code
							AND X.[Номер заявки] = A.[Номер заявки]
							AND X.status IN ('Доработка', 'Отложена')
							AND X.ДатаИВремяСтатуса BETWEEN A.ДатаИВремяСтатуса AND B.ДатаИВремяСтатуса
					)
			WHERE A.status = 'Новая_Уникальная'
				AND B.[Номер заявки] IS NULL --нет 'task:В работе'








			DROP table if exists #waitTime_m

			;with r as
			(
			select 
			r.ProductType_Code
			, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
			, [Дата статуса]
			, [Дата след.статуса]
			, Работник [ФИО сотрудника верификации/чекер]
			, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
			 from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
			 where [Состояние заявки]='Ожидание' 
				and r.Статус='Контроль данных' 
				--DWH-2019
				AND NOT (
					r.Задача='task:Новая'
					AND r.[Задача следующая] = 'task:Автоматически отложено'
				)

				and [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
			 and (Работник in (select e.Employee from #KDEmployees e)
			 or Назначен in (select e.Employee from #KDEmployees e))
			)

			select 
				r.ProductType_Code
				, [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date) 
				 , duration = avg( datediff(second,[Дата статуса], [Дата след.статуса]))
			  into #waitTime_m
			from  r
			where  datediff(second,[Дата статуса], [Дата след.статуса])>0
			group by r.ProductType_Code, cast(format([Дата статуса],'yyyyMM01') as date) 
 

			DROP table if exists #all_requests_m
  
			select 
				D.ProductType_Code
				,[Дата заведения заявки] = cast(format(D.[Дата заведения заявки] ,'yyyyMM01') as date)
				,Qty = count(distinct D.[Номер заявки])
				--,ПроверкаДохода = count(distinct case when D.ПроверкаДохода = 1 then D.[Номер заявки] else null end)
				----1
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка 2-НДФЛ'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка 2-НДФЛ]
				----2
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Выписка по счету из банка бумажный или эл. вид'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Выписка по счету из банка бумажный или эл. вид]
				----3
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка по форме банка/работодателя'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка по форме банка/работодателя]
				----4 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Выписка со счета, на который зачисляются официальные выплаты'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Выписка со счета, на который зачисляются официальные выплаты]
				----5
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка из ПФР/СФР о размере устан. пенсии'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка из ПФР/СФР о размере устан. пенсии]
				----6
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Пенсионное удостоверение / Справка о размере пенсии'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Пенсионное удостоверение / Справка о размере пенсии]
				----7 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				--, count(distinct 
				--	case 
				--		when D.ПроверкаДохода = 1 
				--		and D.[Тип документа подтверждающего доход] = 'Справка по налогу на профессиональный доход'
				--		then D.[Номер заявки] 
				--	else null 
				--	end) as [Справка по налогу на профессиональный доход]
			into #all_requests_m
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
			join #calendar c on c.dt_day=D.[Дата заведения заявки]
			where  D.[Дата статуса]>= @dt_from and  D.[Дата статуса]<@dt_to
			group by D.ProductType_Code, cast(format(D.[Дата заведения заявки] ,'yyyyMM01') as date)

			--#all_requests_m
			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##all_requests_m
				SELECT * INTO ##all_requests_m FROM #all_requests_m
			END

			--ПроверкаДохода
			DROP table if exists #t_income_verification_m
  
			SELECT 
				D.ProductType_Code
				, Дата = cast(format(D.Дата ,'yyyyMM01') as date)
				, count(distinct D.[Номер заявки]) as Qty 
				, count(distinct case when D.ПроверкаДохода = 1 then D.[Номер заявки] else null end) as ПроверкаДохода
				--1 Справка 2-НДФЛ
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка 2-НДФЛ'
						then D.[Номер заявки] 
					else null 
					end) as [Справка 2-НДФЛ]
				--2 Выписка по счету из банка бумажный или эл. вид
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Выписка по счету из банка бумажный или эл. вид'
						then D.[Номер заявки] 
					else null 
					end) as [Выписка по счету из банка бумажный или эл. вид]
				--3 Справка по форме банка/работодателя
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка по форме банка/работодателя'
						then D.[Номер заявки] 
					else null 
					end) as [Справка по форме банка/работодателя]
				--4 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Выписка со счета, на который зачисляются официальные выплаты'
						then D.[Номер заявки] 
					else null 
					end) as [Выписка со счета, на который зачисляются официальные выплаты]
				--5
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка из ПФР/СФР о размере устан. пенсии'
						then D.[Номер заявки] 
					else null 
					end) as [Справка из ПФР/СФР о размере устан. пенсии]
				--6
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Пенсионное удостоверение / Справка о размере пенсии'
						then D.[Номер заявки] 
					else null 
					end) as [Пенсионное удостоверение / Справка о размере пенсии]
				--7 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, count(distinct 
					case 
						when D.ПроверкаДохода = 1 
						and D.[Тип документа подтверждающего доход] = 'Справка по налогу на профессиональный доход'
						then D.[Номер заявки] 
					else null 
					end) as [Справка по налогу на профессиональный доход]

			into #t_income_verification_m
			from (
				select 
					A.ProductType_Code,
					A.[Номер заявки],
					A.ПроверкаДохода,
					A.[Тип документа подтверждающего доход],
					Дата = min(cast(A.[Дата статуса] as date))
				from #t_dm_FedorVerificationRequests_without_coll_ALL AS A
				where 1=1
					--and A.[Дата статуса] >= @dt_from and A.[Дата статуса] < @dt_to
					--AND A.ПроверкаДохода = 1
					and A.Статус in ('Контроль данных')
				group by
					A.ProductType_Code,
					A.[Номер заявки],
					A.ПроверкаДохода,
					A.[Тип документа подтверждающего доход]
				) as D
			where 1=1
				and D.Дата >= @dt_from and D.Дата < @dt_to
			group by D.ProductType_Code, cast(format(D.Дата ,'yyyyMM01') as date)


			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##t_income_verification_m
				SELECT * INTO ##t_income_verification_m FROM #t_income_verification_m
			END

			---
			-- посчитаем количество уникальных отложенных КД
			-- считаем уникальных отложенных по КД
			drop table if exists #ReportByEmployeeAgg_KD_UniquePostone_m

			;with c1 as (
			  select 
					ProductType_Code
					, Дата = cast(format([Дата],'yyyyMM01') as date)
				  -- , Сотрудник   
				   --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
					, isnull(count(distinct case when status='Отложена' then [Номер заявки] end), 0) [ОтложенаУникальныеKD]
               
				from #fedor_verificator_report
				--DWH-1806
				where Сотрудник in (select * from #curr_employee_cd)
				--01.01 не рабочий день, данные за этот день не учитываем
				and Дата != datefromparts(year(Дата), 1,1)
			   group by ProductType_Code, cast(format([Дата],'yyyyMM01') as date) --Дата
				  -- , Сотрудник
			)        
			  select c1.*              
				into #ReportByEmployeeAgg_KD_UniquePostone_m
				from c1 

			drop table if exists #postpone_unique_kd_m
			select 
				ProductType_Code,
				[Дата статуса]=cast(format([Дата],'yyyyMM01') as date),
				sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
			into #postpone_unique_kd_m
			from #ReportByEmployeeAgg_KD_UniquePostone_m p
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)


			DROP table if exists #p_m 

			SELECT 
				r.ProductType_Code
				, Дата = r.[Дата заведения заявки]

				--d.* 
				, [Общее кол-во заявок на этапе] = isnull(d.[Общее кол-во заявок на этапе], '0')
				, [Кол-во одобренных заявок после этапа] = isnull(d.[Кол-во одобренных заявок после этапа], '0')
				, [Общее кол-во отложенных заявок на этапе] = isnull(d.[Общее кол-во отложенных заявок на этапе], '0')
				, [Кол-во заявок на этапе, отправленных на доработку] = isnull(d.[Кол-во заявок на этапе, отправленных на доработку], '0')
				, [Approval rate - % одобренных после этапа] = isnull(d.[Approval rate - % одобренных после этапа], '0')
				, [Кол-во отказов со стороны сотрудников] = isnull(d.[Кол-во отказов со стороны сотрудников], '0')
				, [Средний Processing time на этапе (время обработки заявки)] = isnull(d.[Средний Processing time на этапе (время обработки заявки)], '0')
				, [Кол-во заявок, не вернувшихся с доработки] = isnull(d.[Кол-во заявок, не вернувшихся с доработки], '0')

				, cast(format(r.Qty,'0') as nvarchar(50)) [Общее кол-во заведенных заявок] 
				, [Среднее время заявки в ожидании очереди на этапе] = 
					cast(
						isnull(
							format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (w.duration/60)),'00'),
							'00:00:00'
							)
						as nvarchar(50)
					) 
				,[Общее кол-во уникальных заявок на этапе] = isnull(new.[Общее кол-во уникальных заявок на этапе],0)

				,[Первичный] = isnull(new.[Первичный],0)
				,[Повторный] = isnull(new.[Повторный],0)
				,[Докредитование] = isnull(new.[Докредитование],0)
				,[Не определен] = isnull(new.[Не определен],0)

				,[Общее кол-во уникальных заявок на этапе (Новые регионы)] = 
					isnull(new.[Общее кол-во уникальных заявок на этапе (Новые регионы)],0)

				, cast(tty.cnt as nvarchar(50)) AS [TTY  - количество заявок рассмотренных в течение 10 минут на этапе]
				, cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50)) 
					AS [TTY  - % заявок рассмотренных в течение 10 минут на этапе]

				, cast(isnull(kc.cnt,0) as nvarchar(50)) as [Кол-во автоматических отказов Логином]

				, cast(
					isnull(case when r.Qty<>0 then format(100.0*kc.cnt/r.Qty,'0') else '0' end,'0') +N'%' as nvarchar(50))
					as [%  автоматических отказов Логином]

				, [Уникальное кол-во отложенных заявок на этапе] = cast(format((isnull(u.ОтложенаУникальныеKD,0)),'0') as nvarchar(50))

				--, cast(case when r.Qty<>0 then format(100.0*d.[Кол-во заявок, не вернувшихся с доработки]/r.Qty,'0.0') else '0' end +N'%' as nvarchar(50))
				--	AS [% заявок, не вернувшихся с доработки]
				--DWH-2702
				, cast(case when d.[Кол-во заявок на этапе, отправленных на доработку]<>0 then format(100.0*d.[Кол-во заявок, не вернувшихся с доработки]/d.[Кол-во заявок на этапе, отправленных на доработку],'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок, не вернувшихся с доработки]

				--var 1
				--, cast(format(new.[Общее кол-во уникальных заявок на этапе] - new.ПроверкаДохода,'0') as nvarchar(50)) 
				--	AS [Количество заявок без проверки дохода]
				--, cast(format(new.ПроверкаДохода,'0') as nvarchar(50)) 
				--	AS [Количество заявок с проверкой дохода]

				--var 2
				--, cast(format(new.[Общее кол-во уникальных заявок на этапе] - r.ПроверкаДохода,'0') as nvarchar(50)) 
				--	AS [Количество заявок без проверки дохода]
				--, cast(format(r.ПроверкаДохода,'0') as nvarchar(50)) 
				--	AS [Количество заявок с проверкой дохода]

				--var 3
				, cast(format(isnull(new.[Общее кол-во уникальных заявок на этапе] - iv.ПроверкаДохода,0),'0') as nvarchar(50)) 
					AS [Количество заявок без проверки дохода]
				, cast(format(isnull(iv.ПроверкаДохода,0),'0') as nvarchar(50))
					AS [Количество заявок с проверкой дохода]

				--1
				, cast(format(isnull(iv.[Справка 2-НДФЛ],0),'0') as nvarchar(50)) 
					AS [Из них проверка 2-НДФЛ]
				--2
				, cast(format(isnull(iv.[Выписка по счету из банка бумажный или эл. вид],0),'0') as nvarchar(50)) 
					AS [Из них выписка по счету банка]
				--3
				, cast(format(isnull(iv.[Справка по форме банка/работодателя],0),'0') as nvarchar(50)) 
					AS [Справка по форме кредитной организации или по форме работодателя]
				--4 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, cast(format(isnull(iv.[Выписка со счета, на который зачисляются официальные выплаты],0),'0') as nvarchar(50)) 
					AS [Выписка со счета, на который зачисляются официальные выплаты]
				--5
				, cast(format(isnull(iv.[Справка из ПФР/СФР о размере устан. пенсии],0),'0') as nvarchar(50)) 
					AS [Справка из ПФР / СФР о размере установленной пенсии]
				--6
				, cast(format(isnull(iv.[Пенсионное удостоверение / Справка о размере пенсии],0),'0') as nvarchar(50)) 
					AS [Пенсионное удостоверение с указанием размера выплаты]
				--7 нет документа в Stg._fedor.dictionary_IncomeVerificationSource ?
				, cast(format(isnull(iv.[Справка по налогу на профессиональный доход],0),'0') as nvarchar(50)) 
					AS [Справка по налогу на профессиональный доход]


				, cast(format(Autoappr.Autoapprove_KD,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД]
				, cast(format(Autoappr.Autoapprove_KD_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД, финальное одобрение]

				, cast(format(Autoappr.Autoapprove_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК]
				, cast(format(Autoappr.Autoapprove_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК, финальное одобрение]

				, cast(format(Autoappr.Autoapprove_KD_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК]
				, cast(format(Autoappr.Autoapprove_KD_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

				, cast(format(Autoappr.Autoapprove_KD_VK_total,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего)]
				, cast(format(Autoappr.Autoapprove_KD_VK_total_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего), финальное одобрение]
				--
				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove пропустивших этап КД (не назначался КД)]
				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

				, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove от поступивших ВК (не назначался ВК)]
				, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK_fin_appr / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove КД + ВК (от поступивших на КД)]
				, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
					AS [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
			into #p_m
			from #all_requests_m AS r 
			left join (
				select 
					a.ProductType_Code
					, Дата=cast(format(Дата,'yyyyMM01') as date)
					 , cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50)) [Общее кол-во заявок на этапе]
         
					 , cast(format(sum([ВК]),'0')as nvarchar(50)) [Кол-во одобренных заявок после этапа] 

					 , cast(format(sum(Отложена),'0') as nvarchar(50)) [Общее кол-во отложенных заявок на этапе]

					 , cast(format(sum(Доработка),'0') as nvarchar(50))[Кол-во заявок на этапе, отправленных на доработку]

					 , case when  sum(  ИтогоПоСотруднику)<>0 then 
						cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) 
						else '0'
					   end
						[Approval rate - % одобренных после этапа]

					 , cast(format(sum([Отказано]),'0')as nvarchar(50)) [Кол-во отказов со стороны сотрудников]      
      
					 , case when sum(КоличествоЗаявок)<>0 then 
						cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
					  else '0' end
					   [Средний Processing time на этапе (время обработки заявки)]
         
					, cast(format(sum([Не вернувшиеся с доработки]),'0') as nvarchar(50)) AS [Кол-во заявок, не вернувшихся с доработки]

				  from #ReportByEmployeeAgg a 
				  where сотрудник in (select * from #curr_employee_cd)
				 --01.01 не рабочий день, данные за этот день не учитываем
					and Дата != DATEFROMPARTS(year(Дата), 1,1)
				 group by a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
			) AS d  
			on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки]=d.Дата

			LEFT JOIN (
				SELECT
					a.ProductType_Code
					, Дата=cast(format(Дата,'yyyyMM01') as date)
					 , cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе] --DWH-2021

					 --DWH-2286
					 , cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50)) [Первичный]
					 , cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50)) [Повторный]
					 , cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50)) [Докредитование]
					 , cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50)) [Не определен]

					--DWH-563
					 , cast(format(isnull(sum(Новая_Уникальная_НовыйРегион),0),'0') as nvarchar(50))
						as [Общее кол-во уникальных заявок на этапе (Новые регионы)]

					--, sum(ПроверкаДохода) AS ПроверкаДохода
				  from #ReportByEmployeeAgg a
				  --01.01 не рабочий день, данные за этот день не учитываем
				  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
				  GROUP BY a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)

				--DWH-1884 закомментарил
				--SELECT Дата=cast(format(Дата,'yyyyMM01') as date)
				--	 , cast(format(sum([ИтогоПоСотруднику]),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе]
				--  from #ReportByEmployeeAgg a
				--  --01.01 не рабочий день, данные за этот день не учитываем
				--  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
				--	--Только по сотрудникам, иначе в отчете будут учитываться данные от системых пользователей.
				--	AND a.Сотрудник in (select * from #curr_employee_cd)
				--  GROUP BY cast(format(Дата,'yyyyMM01') as date)

			) new 
			ON new.ProductType_Code = d.ProductType_Code 
			AND new.Дата=d.Дата

			--join #all_requests_m AS r 
			--on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки]=d.Дата

			left join #t_income_verification_m as iv
				on iv.ProductType_Code = d.ProductType_Code
				AND iv.Дата = d.Дата

			left join #waitTime_m AS w on w.ProductType_Code = d.ProductType_Code AND w.[Дата статуса]=d.Дата
			left join #postpone_unique_kd_m AS u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
			left join (
				select 
					ProductType_Code
					, дата=cast(format(Дата,'yyyyMM01') as date)
					, count([Номер заявки]) cnt
				  -- , ВремяЗатрачено 
				  from #tty_kd_m
				where tty_flag='tty'
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 

			) tty on tty.ProductType_Code = d.ProductType_Code AND tty.Дата=d.Дата

			LEFT join #verif_KC_m AS kc on kc.ProductType_Code = d.ProductType_Code AND kc.[Дата статуса]=d.Дата


			--DWH-2374
			LEFT JOIN (
				select 
					a.ProductType_Code
					, Дата=cast(format(Дата,'yyyyMM01') as date)
					, sum(Autoapprove_KD) AS Autoapprove_KD
					, sum(Autoapprove_KD_fin_appr) AS Autoapprove_KD_fin_appr

					, sum(Autoapprove_VK) AS Autoapprove_VK
					, sum(Autoapprove_VK_fin_appr) AS Autoapprove_VK_fin_appr

					, sum(Autoapprove_KD_VK) AS Autoapprove_KD_VK
					, sum(Autoapprove_KD_VK_fin_appr) AS Autoapprove_KD_VK_fin_appr

					, sum(Autoapprove_KD_VK_total) AS Autoapprove_KD_VK_total
					, sum(Autoapprove_KD_VK_total_fin_appr) AS Autoapprove_KD_VK_total_fin_appr

					, sum(KD_IN) AS KD_IN
					, sum(KD_IN_fin_appr) AS KD_IN_fin_appr

					, sum(VK_IN) AS VK_IN
					, sum(VK_IN_fin_appr) AS VK_IN_fin_appr
				  from #ReportByEmployeeAgg AS a
				  --01.01 не рабочий день, данные за этот день не учитываем
				  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
				  GROUP BY a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
			) Autoappr on Autoappr.ProductType_Code = d.ProductType_Code AND Autoappr.Дата = d.Дата

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##p_m
				SELECT * INTO ##p_m FROM #p_m
			END

			 /*
			 use devdb
			 go
			 drop table if exists devdb.dbo.p_
			 select * into devdb.dbo.p_ from #p 
			 */
			DROP table if exists #unp_m

			IF @Page IN ('KD.Monthly.Common') OR @isFill_All_Tables = 1
			BEGIN
				select ProductType_Code, Дата, indicator, Qty 
				into #unp_m
				from 
				(
					select 
						ProductType_Code
						, Дата
						 , [Общее кол-во заведенных заявок]
						 , [Кол-во автоматических отказов Логином]
						 , [%  автоматических отказов Логином]
						 , [Общее кол-во уникальных заявок на этапе]

						, [Первичный]
						, [Повторный]
						, [Докредитование]
						, [Не определен]

						 ,[Общее кол-во уникальных заявок на этапе (Новые регионы)]

						 , [Общее кол-во заявок на этапе]
						 , [TTY  - количество заявок рассмотренных в течение 10 минут на этапе]
						 , [TTY  - % заявок рассмотренных в течение 10 минут на этапе]
						 , [Среднее время заявки в ожидании очереди на этапе]
						 , [Средний Processing time на этапе (время обработки заявки)]
						 , [Кол-во одобренных заявок после этапа]
						 , [Кол-во отказов со стороны сотрудников]
						 , [Approval rate - % одобренных после этапа]
						 , [Общее кол-во отложенных заявок на этапе]
						 , [Уникальное кол-во отложенных заявок на этапе]
						 , [Кол-во заявок на этапе, отправленных на доработку]
						 , [Кол-во заявок, не вернувшихся с доработки]
						 , [% заявок, не вернувшихся с доработки]
						 , [Количество заявок без проверки дохода]
						 , [Количество заявок с проверкой дохода]
						, [Из них проверка 2-НДФЛ]
						, [Из них выписка по счету банка]
						, [Справка по форме кредитной организации или по форме работодателя]
						, [Выписка со счета, на который зачисляются официальные выплаты]
						, [Справка из ПФР / СФР о размере установленной пенсии]
						, [Пенсионное удостоверение с указанием размера выплаты]
						, [Справка по налогу на профессиональный доход]
					  from #p_m
     
					) p
				unpivot
				  (Qty for indicator in (
										  [Общее кол-во заведенных заявок]
										 ,[Кол-во автоматических отказов Логином]
										 ,[%  автоматических отказов Логином]
										 ,[Общее кол-во уникальных заявок на этапе]
										, [Первичный]
										, [Повторный]
										, [Докредитование]
										, [Не определен]
										 ,[Общее кол-во уникальных заявок на этапе (Новые регионы)]
										 ,[Общее кол-во заявок на этапе]
										 ,[TTY  - количество заявок рассмотренных в течение 10 минут на этапе]
										 ,[TTY  - % заявок рассмотренных в течение 10 минут на этапе]
										 ,[Среднее время заявки в ожидании очереди на этапе]
										 ,[Средний Processing time на этапе (время обработки заявки)]
										 ,[Кол-во одобренных заявок после этапа]
										 ,[Кол-во отказов со стороны сотрудников]
										 ,[Approval rate - % одобренных после этапа]
										 ,[Общее кол-во отложенных заявок на этапе]
										 ,[Уникальное кол-во отложенных заявок на этапе]
										 ,[Кол-во заявок на этапе, отправленных на доработку]
										 ,[Кол-во заявок, не вернувшихся с доработки]
										 ,[% заявок, не вернувшихся с доработки]
										 , [Количество заявок без проверки дохода]
										 , [Количество заявок с проверкой дохода]
										, [Из них проверка 2-НДФЛ]
										, [Из них выписка по счету банка]
										, [Справка по форме кредитной организации или по форме работодателя]
										, [Выписка со счета, на который зачисляются официальные выплаты]
										, [Справка из ПФР / СФР о размере установленной пенсии]
										, [Пенсионное удостоверение с указанием размера выплаты]
										, [Справка по налогу на профессиональный доход]
										)
				   ) as unpvt

					IF @isFill_All_Tables = 1
					BEGIN
						--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_Common
						DELETE T
						FROM tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_Common AS T
						WHERE T.ProcessGUID = @ProcessGUID

						INSERT tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_Common
						SELECT
							ProcessGUID = @ProcessGUID,
							--i.num_rows 
							num_rows = i.num_rows + 0.1 * PT.ProductType_Order
							--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
							,empl_id =null
							,Employee =null
							,acc_period =Дата
							--,indicator =name_indicator
							,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
							,[Сумма] =null
							,Qty
							,Qty_dist=null
							,Tm_Qty =null--isnull(Tm_Qty,0.00)
						--INTO tmp.TMP_Report_verification_fedor_without_coll_KD_Monthly_Common
						FROM #unp_m u join #indicator_for_controldata i on u.indicator=i.name_indicator
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = u.ProductType_Code
						--ORDER BY i.num_rows

						INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
						SELECT getdate(), 'KD.Monthly.Common', @ProcessGUID

					END
					ELSE BEGIN
					   select 
						--i.num_rows 
						num_rows = i.num_rows + 0.1 * PT.ProductType_Order
						--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
						,empl_id =null
						   ,Employee =null
						 ,acc_period =Дата
						  --,indicator =name_indicator
						  ,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
						 ,[Сумма] =null
						   , Qty
						   ,Qty_dist=null
						   , Tm_Qty =null--isnull(Tm_Qty,0.00)
						from #unp_m AS u join #indicator_for_controldata AS i on u.indicator=i.name_indicator
							INNER JOIN #t_ProductType AS PT
								ON PT.ProductType_Code = u.ProductType_Code
						--ORDER BY i.num_rows

						RETURN 0
					END
			END --'KD.Monthly.Common'

		END
		--// 'KD.Monthly.Common', 'KD.Monthly.Autoapprove'

	END -- общий лист по  дням
	--// Общий отчет KD.%


	--Общий отчет PSV.%
	IF @Page IN (
		'PSV.Daily.Common'
		,'PSV.Monthly.Common'
	) OR @isFill_All_Tables = 1
	begin
		drop table if exists #indicator_for_PSV
		create table #indicator_for_PSV(
				[num_rows] numeric(6,2) NULL --int null 
			, [name_indicator] nvarchar(250) null
		)
		insert into #indicator_for_PSV([num_rows] ,[name_indicator])
		values
		--  (1 ,'Общее кол-во заведенных заявок')
		--, (2 ,'Кол-во автоматических отказов Логином')
		--, (3 ,'%  автоматических отказов Логином')
		(4 ,'Общее кол-во заявок на этапе')
		--, (4.01 ,'Первичный')
		--, (4.02 ,'Повторный')
		--, (4.03 ,'Докредитование')
		--, (4.04 ,'Параллельный')
		--, (4.05 ,'Не определен')
		, (5 ,'Общее кол-во уникальных заявок на этапе')
		--, (6, 'TTY  - количество заявок рассмотренных в течение 6 минут на этапе')
		--, (7 ,'TTY  - % заявок рассмотренных в течение 6 минут на этапе')
		, (10 ,'Среднее время заявки в ожидании очереди на этапе')
		, (12 ,'Средний Processing time на этапе (время обработки заявки)')
		, (15 ,'Кол-во одобренных заявок после этапа')
		--, (18 ,'Кол-во отказов со стороны сотрудников')
		, (21 ,'Approval rate - % одобренных после этапа')
		, (25 ,'Общее кол-во отложенных заявок на этапе')
		, (26 ,'Уникальное кол-во отложенных заявок на этапе')
		, (28 ,'Кол-во заявок на этапе, отправленных на доработку')
		, (29 ,'Уникальное количество доработок на этапе')
        

		IF @Page = 'PSV.Daily.Common' OR @isFill_All_Tables = 1
		BEGIN

			DROP table if exists #waitTime_PSV

			;with r AS (
				select 
					r.ProductType_Code
					, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
					, [Дата статуса]
					, [Дата след.статуса]
					,Работник [ФИО сотрудника верификации/чекер]
					, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику],  [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
				from #t_dm_FedorVerificationRequests_without_coll_ALL r
				where [Состояние заявки]='Ожидание' 
					AND r.Статус='Проверка способа выдачи' 
					AND NOT (
						r.Задача='task:Новая'
						AND r.[Задача следующая] = 'task:Автоматически отложено'
					)
					--AND [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to 
					AND 
						(Работник in (select e.Employee from #PSVEmployees e)
						-- для учета, когда ожидание назначено на сотрудника
						OR Назначен in (select e.Employee from #PSVEmployees e)
						)
			)
			select 
				r.ProductType_Code
				, [Дата статуса]=cast([Дата статуса] as date) 
				--  , [Номер заявки]
				, avg( datediff(second,[Дата статуса], [Дата след.статуса]))   duration
			into #waitTime_PSV
			from r
			where datediff(second,[Дата статуса], [Дата след.статуса])>0
			group by r.ProductType_Code, cast([Дата статуса] as date) -- ,[Номер заявки]
 
			--select * from #waitTime_PSV

			--drop table if exists #verif_KC

			--select [Дата статуса]=cast([Дата статуса] as date) 
			--	, count(distinct [Номер заявки]) cnt
			--into #verif_KC
			--from #t_dm_FedorVerificationRequests_without_coll_ALL r where [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
			--	and  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
			--group by cast([Дата статуса] as date) 
 

			-- считаем уникальных отложенных по ПД
			drop table if exists #ReportByEmployeeAgg_PSV_UniquePostone

			;with c1 as (
				select 
					ProductType_Code
					, Дата
					-- , Сотрудник   
					--, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
					, isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеKD]
				from #fedor_verificator_report_PSV
				--DWH-1806
				where Сотрудник in (select * from #curr_employee_vr)
					--01.01 не рабочий день, данные за этот день не учитываем
					and Дата != datefromparts(year(Дата), 1,1)
				group by ProductType_Code, Дата
					-- , Сотрудник
			)        
			select c1.*              
			into #ReportByEmployeeAgg_PSV_UniquePostone
			from c1 
            

			-- посчитаем количество уникальных отложенных ПД теперь и по дням
			drop table if exists #postpone_unique_PSV_daily
 
			select 
				ProductType_Code,
				[Дата статуса]=cast(([Дата]) as date),
				sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
			into #postpone_unique_PSV_daily
			from #ReportByEmployeeAgg_PSV_UniquePostone p
			group by ProductType_Code, cast(([Дата]) as date)

  
			drop table if exists #all_requests_PSV
  
			select 
				D.ProductType_Code
				, D.[Дата заведения заявки] 
				, count(distinct D.[Номер заявки]) Qty
			into #all_requests_PSV
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
				join #calendar c on c.dt_day=D.[Дата заведения заявки]
			where 1=1
				--and [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
			group by D.ProductType_Code, D.[Дата заведения заявки] 

			--select * from #all_requests_PSV
			-- TTY
			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##all_requests_PSV
				SELECT * INTO ##all_requests_PSV FROM #all_requests_PSV
			END
   
			drop table if exists #tty_PSV

			select 
				ProductType_Code
				, Дата
				, [Номер заявки]
				, Сотрудник
				, [ФИО сотрудника верификации/чекер]
				--, ВремяЗатрачено
				, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
				, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end tty_flag
			into #tty_PSV
			from #fedor_verificator_report_PSV where status='task:В работе'

			drop table if exists #PSV
  
			select 
				d.ProductType_Code
				, d.Дата
				, new.[Общее кол-во уникальных заявок на этапе]
				, d.[Общее кол-во заявок на этапе]								
				, [Среднее время заявки в ожидании очереди на этапе] = cast(
						format(w.duration/60/60 ,'00')+N':'+format( (duration/60 -  60* (duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
					as nvarchar(50)) 
				, d.[Средний Processing time на этапе (время обработки заявки)]
				, d.[Кол-во одобренных заявок после этапа]

				, d.[Кол-во отказов со стороны сотрудников]
				, d.[Approval rate - % одобренных после этапа]
				, d.[Общее кол-во отложенных заявок на этапе]
				, [Уникальное кол-во отложенных заявок на этапе] = cast(format((u.ОтложенаУникальныеKD),'0') as nvarchar(50))
				, d.[Кол-во заявок на этапе, отправленных на доработку]
				, d.[Уникальное количество доработок на этапе]

				--, [Общее кол-во заведенных заявок] = cast(format(r.Qty,'0') as nvarchar(50))
				--, new.[Первичный]
				--, new.[Повторный]
				--, new.[Докредитование]
				--, new.[Параллельный]
				--, new.[Не определен]

				--, [TTY  - количество заявок рассмотренных в течение 6 минут на этапе] = cast(tty.cnt as nvarchar(50))
				--, [TTY  - % заявок рассмотренных в течение 6 минут на этапе] = cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50))
				--, [Кол-во автоматических отказов Логином] = cast(kc.cnt as nvarchar(50))
				--, [%  автоматических отказов Логином] = cast(case when r.Qty<>0 then  format(100.0*kc.cnt/r.Qty,'0') else '0' end +N'%' as nvarchar(50))
			into #PSV
			from (
				select 
					a.ProductType_Code
					, Дата
					, [Общее кол-во заявок на этапе]								= cast(format(sum(a.КоличествоЗаявок),'0') as nvarchar(50))
					, [Средний Processing time на этапе (время обработки заявки)] = cast(isnull(convert(nvarchar,cast((case when sum(КоличествоЗаявок)<>0 then  sum(ВремяЗатрачено)/sum(КоличествоЗаявок) else 0 end) as datetime),8)  ,0) as nvarchar(50))
					, [Кол-во одобренных заявок после этапа]						= cast(format(sum([ВК]),'0')as nvarchar(50))
					, [Кол-во отказов со стороны сотрудников]						= cast(format(sum([Отказано]),'0')as nvarchar(50))       
					, [Approval rate - % одобренных после этапа]					= cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) 
					, [Общее кол-во отложенных заявок на этапе]					= cast(format(sum(Отложена),'0') as nvarchar(50))
					, [Кол-во заявок на этапе, отправленных на доработку]			= cast(format(sum(Доработка),'0') as nvarchar(50))
					, [Уникальное количество доработок на этапе] = cast(format(sum([Доработка уникальных]),'0') as nvarchar(50))
				from #ReportByEmployeeAgg_PSV a
				where Сотрудник in (select * from #curr_employee_vr)
					--01.01 не рабочий день, данные за этот день не учитываем
					and Дата != DATEFROMPARTS(year(Дата), 1,1)
				group by a.ProductType_Code, Дата
				) d 
				left join (
					select
						a.ProductType_Code
						, Дата
						, cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе] --DWH-2020
						--DWH-2286
						--, cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50)) [Первичный]
						--, cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50)) [Повторный]
						--, cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50)) [Докредитование]
						--, cast(format(sum([Новая_Уникальная Параллельный]),'0')as nvarchar(50)) [Параллельный]
						--, cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50)) [Не определен]
					from #ReportByEmployeeAgg_PSV a
						--01.01 не рабочий день, данные за этот день не учитываем
					where Дата != DATEFROMPARTS(year(Дата), 1,1)
					group by a.ProductType_Code, Дата
				) new 
					on new.ProductType_Code = d.ProductType_Code 
					AND new.Дата=d.Дата
				join #all_requests_PSV r on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки] = d.Дата
				left join #waitTime_PSV w on w.ProductType_Code = d.ProductType_Code and w.[Дата статуса]=d.Дата
				left join #postpone_unique_PSV_daily u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
				left join (
					select 
						ProductType_Code
						, дата
						, count([Номер заявки]) cnt
					-- , ВремяЗатрачено 
					from #tty_PSV
					where tty_flag='tty'
					group by ProductType_Code, дата
				) tty on tty.ProductType_Code = d.ProductType_Code AND tty.Дата=d.Дата
				--left join #verif_KC as kc on kc.[Дата статуса]=d.Дата

			--select * from #PSV
			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##PSV
				SELECT * INTO ##PSV FROM #PSV
			END

			drop table if exists #unp_PSV

			select ProductType_Code, Дата, indicator, Qty 
			into #unp_PSV
			from (
				select 
					ProductType_Code = isnull(v.ProductType_Code, 'ALL')
					, Дата = c.dt_day
					, [Общее кол-во уникальных заявок на этапе] = isnull(v.[Общее кол-во уникальных заявок на этапе], '0')
					, [Общее кол-во заявок на этапе] = isnull(v.[Общее кол-во заявок на этапе], '0')
					, [Среднее время заявки в ожидании очереди на этапе] = isnull(v.[Среднее время заявки в ожидании очереди на этапе], '0')
					, [Средний Processing time на этапе (время обработки заявки)] = isnull(v.[Средний Processing time на этапе (время обработки заявки)], '0')
					, [Кол-во одобренных заявок после этапа] = isnull(v.[Кол-во одобренных заявок после этапа], '0')

					, [Кол-во отказов со стороны сотрудников] = isnull(v.[Кол-во отказов со стороны сотрудников], '0')
					, [Approval rate - % одобренных после этапа] = isnull(v.[Approval rate - % одобренных после этапа], '0')
					, [Общее кол-во отложенных заявок на этапе] = isnull(v.[Общее кол-во отложенных заявок на этапе], '0')
					, [Уникальное кол-во отложенных заявок на этапе] = isnull(v.[Уникальное кол-во отложенных заявок на этапе], '0')
					, [Кол-во заявок на этапе, отправленных на доработку] = isnull(v.[Кол-во заявок на этапе, отправленных на доработку], '0')
					, [Уникальное количество доработок на этапе] = isnull(v.[Уникальное количество доработок на этапе], '0')

					--, [Общее кол-во заведенных заявок]
					--, [Кол-во автоматических отказов Логином]
					--, [%  автоматических отказов Логином]
					--, [Первичный]
					--, [Повторный]
					--, [Докредитование]
					--, [Параллельный]
					--, [Не определен]
					--, [TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
					--, [TTY  - % заявок рассмотренных в течение 6 минут на этапе]
				--from #PSV
				from #calendar as c
					left join #PSV as v
						on v.Дата = c.dt_day
				) p
				unpivot	(
					Qty for indicator in (
						[Общее кол-во уникальных заявок на этапе]
						, [Общее кол-во заявок на этапе]
						, [Среднее время заявки в ожидании очереди на этапе]
						, [Средний Processing time на этапе (время обработки заявки)]
						, [Кол-во одобренных заявок после этапа]

						, [Кол-во отказов со стороны сотрудников]
						, [Approval rate - % одобренных после этапа]
						, [Общее кол-во отложенных заявок на этапе]		  
						, [Уникальное кол-во отложенных заявок на этапе]
						, [Кол-во заявок на этапе, отправленных на доработку]
						, [Уникальное количество доработок на этапе]

						--, [Общее кол-во заведенных заявок]
						--, [Кол-во автоматических отказов Логином]
						--, [%  автоматических отказов Логином]
						--, [Первичный]
						--, [Повторный]
						--, [Докредитование]
						--, [Параллельный]
						--, [Не определен]
						--, [TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
						--, [TTY  - % заявок рассмотренных в течение 6 минут на этапе]
					)
				) as unpvt

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##unp_PSV
				SELECT * INTO ##unp_PSV FROM #unp_PSV
			END


			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_Common
				DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_Common AS T WHERE T.ProcessGUID = @ProcessGUID

				INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_Common
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--, indicator =name_indicator
					, indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
					--INTO tmp.TMP_Report_verification_fedor_without_coll_PSV_Daily_Common
				from #unp_PSV u 
					join #indicator_for_PSV i on u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows

				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'PSV.Daily.Common', @ProcessGUID
			END
			ELSE BEGIN
				SELECT
					--i.num_rows 
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--, indicator =name_indicator
					, indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				from #unp_PSV u 
				join #indicator_for_PSV i on u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows

				RETURN 0
			END
		END
		--// 'PSV.Daily.Common'


		IF @Page= 'PSV.Monthly.Common' OR @isFill_All_Tables = 1
		BEGIN
			--drop table if exists #verif_KC_m

			--select [Дата статуса]= cast(format([Дата статуса],'yyyyMM01') as date) 
			--	, count(distinct [Номер заявки]) cnt
			--into #verif_KC_m
			--	from #t_dm_FedorVerificationRequests_without_coll_ALL r where [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
			--	and  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
			--group by cast(format([Дата статуса],'yyyyMM01') as date) 
 
			-- TTY
			drop table if exists #tty_PSV_m

			select 
				ProductType_Code
				, Дата
				, [Номер заявки]
				, Сотрудник
				, [ФИО сотрудника верификации/чекер]
				--, ВремяЗатрачено
				, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
				, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end tty_flag
			into #tty_PSV_m
			from #fedor_verificator_report_PSV
			where status='task:В работе'

			drop table if exists #waitTime_PSV_m

			;with r as (
				select 
					r.ProductType_Code
					, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
					, [Дата статуса]
					, [Дата след.статуса]
					, Работник [ФИО сотрудника верификации/чекер]
					, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
				from #t_dm_FedorVerificationRequests_without_coll_ALL r
				where [Состояние заявки]='Ожидание'
					AND r.Статус='Проверка способа выдачи'
					--DWH-2019
					AND NOT (
						r.Задача='task:Новая'
						AND r.[Задача следующая] = 'task:Автоматически отложено'
					)
					--AND [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
					and (Работник in (select e.Employee from #PSVEmployees e)
						or Назначен in (select e.Employee from #PSVEmployees e)
					)
			)
			select 
				r.ProductType_Code
				, [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date)
				--  , [Номер заявки]
				, avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
			into #waitTime_PSV_m
			from r
			where datediff(second,[Дата статуса], [Дата след.статуса])>0
			group by r.ProductType_Code, cast(format([Дата статуса],'yyyyMM01') as date)
 
			drop table if exists #all_requests_PSV_m
  
			select 
				D.ProductType_Code
				, [Дата заведения заявки] =format(D.[Дата заведения заявки] ,'yyyyMM01')
				, count(distinct D.[Номер заявки]) Qty 
			into #all_requests_PSV_m
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
				join #calendar c on c.dt_day=D.[Дата заведения заявки]
			where 1=1
				--and [Дата статуса]>= @dt_from and  [Дата статуса]<@dt_to
			group by D.ProductType_Code, format(D.[Дата заведения заявки] ,'yyyyMM01')

			--#all_requests_PSV_m
			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##all_requests_PSV_m
				SELECT * INTO ##all_requests_PSV_m FROM #all_requests_PSV_m

				--DROP TABLE IF EXISTS ##calendar
				--SELECT * INTO ##calendar FROM #calendar
			END

			---
			-- посчитаем количество уникальных отложенных КД
			-- считаем уникальных отложенных по КД
			drop table if exists #ReportByEmployeeAgg_PSV_UniquePostone_m

			;with c1 as (
				select 
					ProductType_Code
					, Дата = cast(format([Дата],'yyyyMM01') as date)
					-- , Сотрудник   
					--, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
					, isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеKD]
				from #fedor_verificator_report_PSV
				--DWH-1806
				where Сотрудник in (select * from #curr_employee_vr)
					--01.01 не рабочий день, данные за этот день не учитываем
					and Дата != datefromparts(year(Дата), 1,1)
				group by ProductType_Code, cast(format([Дата],'yyyyMM01') as date) --Дата
					-- , Сотрудник
			)
			select c1.*              
			into #ReportByEmployeeAgg_PSV_UniquePostone_m
			from c1 

			drop table if exists #postpone_unique_PSV_m
			select 
				ProductType_Code,
				[Дата статуса]=cast(format([Дата],'yyyyMM01') as date),
				sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
			into #postpone_unique_PSV_m
			from #ReportByEmployeeAgg_PSV_UniquePostone_m p
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)


			drop table if exists #PSV_m

			select 
				d.ProductType_Code
				, d.Дата
				, new.[Общее кол-во уникальных заявок на этапе]
				, d.[Общее кол-во заявок на этапе]
				, cast(
						format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
					as nvarchar(50)) [Среднее время заявки в ожидании очереди на этапе]
				, d.[Средний Processing time на этапе (время обработки заявки)]
				, d.[Кол-во одобренных заявок после этапа] 

				, d.[Кол-во отказов со стороны сотрудников]      
				, d.[Approval rate - % одобренных после этапа]
				, d.[Общее кол-во отложенных заявок на этапе]
				, [Уникальное кол-во отложенных заявок на этапе] = cast(format((u.ОтложенаУникальныеKD),'0') as nvarchar(50))
				, d.[Кол-во заявок на этапе, отправленных на доработку]
				, d.[Уникальное количество доработок на этапе]

				--, cast(format(r.Qty,'0') as nvarchar(50))[Общее кол-во заведенных заявок] 
				--, new.[Первичный]
				--, new.[Повторный]
				--, new.[Докредитование]
				--, new.[Параллельный]
				--, new.[Не определен]

				--, cast(tty.cnt as nvarchar(50))[TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
				--, cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50))[TTY  - % заявок рассмотренных в течение 6 минут на этапе]
				--, cast(kc.cnt as nvarchar(50))[Кол-во автоматических отказов Логином]
				--, cast(case when r.Qty<>0 then  format(100.0*kc.cnt/r.Qty,'0') else '0' end +N'%' as nvarchar(50))[%  автоматических отказов Логином]
			into #PSV_m 
			from (
				select 
					a.ProductType_Code
					, Дата=cast(format(Дата,'yyyyMM01') as date)
					, cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50)) [Общее кол-во заявок на этапе]
					, cast(format(sum([ВК]),'0')as nvarchar(50)) [Кол-во одобренных заявок после этапа] 
					, cast(format(sum(Отложена),'0') as nvarchar(50)) [Общее кол-во отложенных заявок на этапе]
					, cast(format(sum(Доработка),'0') as nvarchar(50)) as [Кол-во заявок на этапе, отправленных на доработку]
					, cast(format(sum([Доработка уникальных]),'0') as nvarchar(50)) as [Уникальное количество доработок на этапе]
					, case when  sum(  ИтогоПоСотруднику)<>0 then 
						cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) 
						else '0'
						end
					[Approval rate - % одобренных после этапа]
					, cast(format(sum([Отказано]),'0')as nvarchar(50)) [Кол-во отказов со стороны сотрудников]      
					, case when sum(КоличествоЗаявок)<>0 then 
						cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						else '0' end
					[Средний Processing time на этапе (время обработки заявки)]
				from #ReportByEmployeeAgg_PSV a 
				where a.сотрудник in (select * from #curr_employee_vr)
					--01.01 не рабочий день, данные за этот день не учитываем
					and Дата != DATEFROMPARTS(year(Дата), 1,1)
				group by a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
			) as d  
			join (
				select
					a.ProductType_Code
					, Дата=cast(format(Дата,'yyyyMM01') as date)
					, cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе] --DWH-2020
					--DWH-2286
					--, cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50)) [Первичный]
					--, cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50)) [Повторный]
					--, cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50)) [Докредитование]
					--, cast(format(sum([Новая_Уникальная Параллельный]),'0')as nvarchar(50)) [Параллельный]
					--, cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50)) [Не определен]
				from #ReportByEmployeeAgg_PSV a
				--01.01 не рабочий день, данные за этот день не учитываем
				where Дата != DATEFROMPARTS(year(Дата), 1,1)
				group by a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
			) new
			on new.ProductType_Code = d.ProductType_Code 
				AND new.Дата=d.Дата
			join #all_requests_PSV_m r on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки]=d.Дата
			left join #waitTime_PSV_m w on w.ProductType_Code = d.ProductType_Code AND w.[Дата статуса]=d.Дата
			left join #postpone_unique_PSV_m u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
			left join (
				select
					ProductType_Code
					, дата=cast(format(Дата,'yyyyMM01') as date)
					, count([Номер заявки]) cnt
					-- , ВремяЗатрачено 
				from #tty_PSV_m
				where tty_flag='tty'
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
			) tty on tty.ProductType_Code = d.ProductType_Code AND tty.Дата=d.Дата
			--left join #verif_KC_m kc on kc.[Дата статуса]=d.Дата

			drop table if exists #unp_PSV_m

			select ProductType_Code, Дата, indicator, Qty 
			into #unp_PSV_m
			from (
				select
					ProductType_Code
					, Дата
					, [Общее кол-во уникальных заявок на этапе]
					, [Общее кол-во заявок на этапе]
					, [Среднее время заявки в ожидании очереди на этапе]
					, [Средний Processing time на этапе (время обработки заявки)]
					, [Кол-во одобренных заявок после этапа]

					, [Кол-во отказов со стороны сотрудников]
					, [Approval rate - % одобренных после этапа]
					, [Общее кол-во отложенных заявок на этапе]		  
					, [Уникальное кол-во отложенных заявок на этапе]
					, [Кол-во заявок на этапе, отправленных на доработку]
					, [Уникальное количество доработок на этапе]

					--, [Общее кол-во заведенных заявок]
					--, [Кол-во автоматических отказов Логином]
					--, [%  автоматических отказов Логином]
					--, [Первичный]
					--, [Повторный]
					--, [Докредитование]
					--, [Параллельный]
					--, [Не определен]
					--, [TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
					--, [TTY  - % заявок рассмотренных в течение 6 минут на этапе]
				from #PSV_m
			) p
			unpivot	(
				Qty for indicator in (
					[Общее кол-во уникальных заявок на этапе]
					, [Общее кол-во заявок на этапе]
					, [Среднее время заявки в ожидании очереди на этапе]
					, [Средний Processing time на этапе (время обработки заявки)]
					, [Кол-во одобренных заявок после этапа]

					, [Кол-во отказов со стороны сотрудников]
					, [Approval rate - % одобренных после этапа]
					, [Общее кол-во отложенных заявок на этапе]		  
					, [Уникальное кол-во отложенных заявок на этапе]
					, [Кол-во заявок на этапе, отправленных на доработку]
					, [Уникальное количество доработок на этапе]

					--, [Общее кол-во заведенных заявок]
					--, [Кол-во автоматических отказов Логином]
					--, [%  автоматических отказов Логином]
					--, [Первичный]
					--, [Повторный]
					--, [Докредитование]
					--, [Параллельный]
					--, [Не определен]
					--, [TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
					--, [TTY  - % заявок рассмотренных в течение 6 минут на этапе]
				)
			) as unpvt

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_Common
				DELETE T FROM tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_Common AS T WHERE T.ProcessGUID = @ProcessGUID

				INSERT tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_Common
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					,[Сумма] =null
					,Qty
					,Qty_dist=null
					,Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedor_without_coll_PSV_Monthly_Common
				FROM #unp_PSV_m u join #indicator_for_PSV i on u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows

				INSERT LogDb.dbo.Fill_Report_verification_fedor_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'PSV.Monthly.Common', @ProcessGUID
			END
			ELSE BEGIN
				SELECT 
					--i.num_rows 
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					,[Сумма] =null
					, Qty
					,Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				from #unp_PSV_m u join #indicator_for_PSV i on u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows

				RETURN 0
			END
		END
		--// 'PSV.Monthly.Common'

	END -- общий лист по  дням
	--// Общий отчет PSV.%


	IF @Page = 'Fill_All_Tables' BEGIN
		SELECT @eventType = concat(@Page, ' FINISH')

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Report_verification_fedor_without_coll',
			@eventType = @eventType, --'Info',
			@message = @message,
			@description = @description,
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID

		--BEGIN TRAN

		UPDATE F
		SET EndDateTime = getdate()
		FROM LogDb.dbo.Fill_Report_verification_fedor_without_coll AS F
		WHERE F.ReportPage = @Page AND F.ProcessGUID = @ProcessGUID

		--COMMIT

		--SELECT ProcessGUID = @ProcessGUID
		RETURN 0
	END

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_verification_fedor_without_coll ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@ProductTypeCode=', iif(@ProductTypeCode IS NULL, 'NULL', ''''+@ProductTypeCode+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_fedor_without_coll',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
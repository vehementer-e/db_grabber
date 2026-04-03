-- =============================================
-- Author:		Shubkin Aleksandr
-- Description:	Процедура для вывода отчета Welcome
--exec [dbo].[Report_client_metrics_calls] @StartDate ='2024-11-01',  @EndDate = '2024-11-27', @callingType = 'Welcome!', @subCreditTypeName = 'ВсёПро100, PDL, ПТС', @hasEmail = 'Нет'
-- =============================================
CREATE   PROCEDURE [dbo].[Report_client_metrics_calls]
	@StartDate DATETIME
	, @EndDate DATETIME
	, @callingType NVARCHAR(255)
	, @subCreditTypeName NVARCHAR(1024) = null
	, @hasEmail NVARCHAR(255) = null
	, @requestStatus nvarchar(1024) = null
	, @callResult nvarchar(1024) = null
AS
BEGIN
	set @EndDate = dateadd(MILLISECOND, -10, dateadd(day, 1, @EndDate))
	;with dsReport as ( 
	SELECT C.[ОбзвонОписание]						AS Обзвон
		, C.ОбзвонДата
		, C.ФИО_Клиента								AS ФИО_клиента
		, C.Телефон									AS Телефон
		, C.РегионРегистрации						AS РегионРегистрации
		, C.НомерЗаявки								AS НомерЗаявки
		, c.[GuidСтатусЗаявки]
		, C.СтатусЗаявки 
		,CASE
			WHEN @callingType = 'Заем погашен'
			THEN C.ДатаСтатуса	
			ELSE NULL
		  END										as ДатаСтатуса -- here
		, C.СуммаВыдачи								AS СуммаЗайма
		, c.[GuidПодТипКредитногоПродукта]
		, C.ПодТипКредитногоПродукта				AS ПодтипПродукта
		, C.КредитныйПродукт						AS КредитныйПродукт
		, CASE										
	        WHEN C.email IS NOT NULL				
			THEN 'Да'								
	        ELSE 'Нет'								
	      END										AS ЗаполненАдресЭлПочты
		, C.Email									AS Адрес_ЭП
		, C.ДатаПоследнегоЗвонка					AS ДатаПоследнегоЗвонка
		, C.Попытки									AS Попытки
		, C.Результат								AS Результат
		, A.НаименованиеВопроса						as НаименованиеВопроса
		, A.ТекстВопроса							as ТекстВопроса
		, CASE
			WHEN A.Ответ_Строка IS NOT NULL
			AND LTRIM(RTRIM(A.Ответ_Строка)) <> ''
				THEN A.Ответ_Строка
			WHEN A.Ответ_Число IS NOT NULL
			AND A.Ответ_Число != 0
				THEN CAST(A.Ответ_Число AS NVARCHAR)
			ELSE NULL
		  END										AS Ответ
		, CASE
			WHEN @callingType = 'Заем погашен'
			THEN 
				CASE
					WHEN A.ДополнительныйОтвет IS NOT NULL
					AND LTRIM(RTRIM(A.ДополнительныйОтвет)) <> ''
						THEN A.ДополнительныйОтвет
					ELSE NULL
				END
			ELSE NULL
		  END AS ДополнительныйОтвет -- here
		  ,C.ОбзвонСсылка
	     ,ОбзвонGuid = [dbo].[getGUIDFrom1C_IDRREF](C.ОбзвонСсылка)
		FROM dwh2.dm.client_metrics_calls AS C
		LEFT JOIN dwh2.dm.client_metrics_answers AS A
		    ON A.ОбзвонСсылка = C.ОбзвонСсылка
		WHERE C.ОбзвонВид = @callingType
			AND C.ОбзвонДата BETWEEN  @StartDate and @EndDate
		)

		SELECT *
		FROM dsReport ds 
		WHERE (
				ds.[GuidПодТипКредитногоПродукта] IN (
					SELECT trim(value)
					FROM string_split(@subCreditTypeName, ',')
				)
				OR @subCreditTypeName IS NULL
			) 
			AND (
				ds.ЗаполненАдресЭлПочты IN (
					SELECT trim(value)
					FROM string_split(@hasEmail, ',')
				)
				OR @hasEmail IS NULL
			)
			AND (
				ds.[GuidСтатусЗаявки] IN (
					SELECT trim(value)
					FROM string_split(@requestStatus, ',')
				)
				OR @RequestStatus IS NULL
			)
			AND (
				isnull(nullif(trim(ds.Результат),''), '<Пусто>') IN (
					SELECT trim(value)
					FROM string_split(@callResult, ',')
				)
				OR @callResult IS NULL
			)
		
END 



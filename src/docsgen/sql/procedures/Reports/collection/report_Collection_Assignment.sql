-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 29.01.2026
-- Description:	Новая версия процедуры report_Collection_Assignment 
--				реализованная в рамках dwh-444
-- =============================================
CREATE PROCEDURE collection.report_Collection_Assignment
	  @dtfrom DATE = NULL --'2021-08-26'
	, @dtto	  DATE = NULL
	, @contragent	   NVARCHAR(MAX) = NULL -- 
	, @loan_assignment NVARCHAR(MAX) = NULL --
AS
BEGIN
	SET NOCOUNT ON;
	IF @contragent IS NULL 
	BEGIN
		SET @contragent = 'Не указано'
	END
	
	IF @dtfrom IS NULL 
	BEGIN
		SET @dtfrom = dateadd(year, -20,GetDate())
	END
	
	IF @dtto IS NULL 
	BEGIN
		SET @dtto = GetDate()
	END
	
	DROP TABLE IF EXISTS #t_content_from_view
	SELECT 
		  external_id			= dz.КодДоговораЗайма
		, [ДатаДоговора]		= dz.ДатаДоговораЗайма
		, [ФИО]					= CONCAT_WS(' '
										  , ISNULL(dz.Фамилия, '')
										  , ISNULL(dz.Имя, '')
										  , ISNULL(dz.Отчество, '')
								)
		, [ДатаПродажаДоговора] = CAST(IIF(
										YEAR(Детали.Дата) > 3000
									  , DATEADD(year, -2000, Детали.Дата)
									  , Детали.Дата
									) AS DATE)
		, [ПервичныйДокумент]	= Детали.ПервичныйДокумент
		, [СуммаОД]				= Договора.СуммаОД
		, [СуммаПродажи]		= Договора.СуммаПродажи
		, [overdue]				= balance.overdue
		, [остаток од]			= balance.[остаток од]
		, [остаток %]			= balance.[остаток %]
		, [остаток пени]		= balance.[остаток пени] - balance.[ПениГрейсПериода начислено]
		, balance.[остаток иное (комиссии, пошлины и тд)]
		, balance.[остаток всего]
		, balance.[основной долг начислено]
		, balance.[основной долг уплачено]
		, balance.[Проценты начислено]
		, balance.[Проценты уплачено]
		, balance.[ПениНачислено]
		, balance.[ПениУплачено]
		, balance.[ГосПошлинаНачислено]
		, balance.[ГосПошлинаУплачено]
		, balance.[ПереплатаНачислено]
		, balance.[ПереплатаУплачено]
		, balance.ContractEndDate
		, [Контрагент]			= isnull(agnt.Наименование, 'Не указано')
		, sdk.Номер
		, sdk.Дата
		, [Комментарий] =
							IIF(sdk.Номер is null
								  , ''
								  , concat_ws(' '
											, 'Договор цессии №'
											, sdk.Номер
											, 'от'
											, Format(dateadd(year, -2000,sdk.Дата),'dd.MM.yyyy')
									)
							)
	INTO #t_content_from_view 
	FROM stg.[_1cCMR].[Документ_ПродажаДоговоров]		AS Детали
	JOIN stg._1cCMR.Документ_ПродажаДоговоров_Договоры  AS Договора
		ON Договора.[Ссылка] = Детали.Ссылка
	JOIN dwh2.[dm].[ДоговорЗайма] AS dz
		ON dz.СсылкаДоговораЗайма = Договора.Ссылка
	LEFT JOIN dwh2.[dbo].[dm_CMRStatBalance] AS balance
		ON balance.external_id = dz.КодДоговораЗайма
	   AND balance.d = DATEADD(DAY, -1,
							   CAST(IIF(
										YEAR(Детали.Дата) > 3000
									  , DATEADD(year, -2000, Детали.Дата)
									  , Детали.Дата
									) AS DATE)
							  )
	LEFT JOIN [Stg].[_1cCMR].[Справочник_Контрагенты] AS agnt
		ON agnt.Ссылка = детали.Контрагент
	LEFT JOIN [Stg].[_1cCMR].[Справочник_ДоговорыКонтрагентов] sdk
		ON sdk.Владелец = agnt.Ссылка
	WHERE детали.ПометкаУдаления != 0x01
	
	SELECT external_id
		 , [ДатаДоговора]
		 , [ФИО]
		 , [ДатаПродажаДоговора]
		 , [ПервичныйДокумент]	
		 , [СуммаОД]				
		 , [СуммаПродажи]		
		 , [overdue]				
		 , [остаток од]			
		 , [остаток %]			
		 , [остаток пени]
		 , [остаток иное (комиссии, пошлины и тд)]
		 , [остаток всего]
		 , [основной долг начислено]
		 , [основной долг уплачено]
		 , [Проценты начислено]
		 , [Проценты уплачено]
		 , [ПениНачислено]
		 , [ПениУплачено]
		 , [ГосПошлинаНачислено]
		 , [ГосПошлинаУплачено]
		 , [ПереплатаНачислено]
		 , [ПереплатаУплачено]
		 , ContractEndDate
		 , [Контрагент]
		 , Номер
		 , Дата
		 , [Комментарий]
	FROM #t_content_from_view 
	WHERE 1 = 1
	  AND Контрагент in (Select value from string_split(@contragent,','))
	  AND cast(ДатаПродажаДоговора as date) >= @dtfrom
	  AND cast(ДатаПродажаДоговора as date) <= @dtto
	  AND Комментарий like concat('%',isnull(@loan_assignment,''),'%')
END

-- =============================================
-- Author: А. Никитин
-- Create date: 25.10.2022
-- Description: DWH-1784 Отчет Договора для архива
-- @changelog  =================================
-- Change Author:		Shubkin Aleksandr
-- Change date:			28.01.2025
-- Change Description: Замена источников данных:
--						stg._1ccmr.Справочник_Договоры
--						на
--						dwh2.[dm].[ДоговорЗайма]
-- =============================================
CREATE PROCEDURE service.[report_loan_for_archive] 
	@issue_date_from date = NULL,
	@issue_date_to date	= NULL,
	@product_type_list varchar(2048) = ''
AS
BEGIN
	SET NOCOUNT ON;
	set @issue_date_from = cast(isnull(@issue_date_from, dateadd(DAY, 1, eomonth(getdate(),-2))) as date)
	set @issue_date_to = cast(isnull(@issue_date_to, getdate()) AS date)

	DECLARE @issue_date_from_2000 date, @issue_date_to_2000 date

	SELECT @issue_date_from_2000 = dateadd(YEAR, 2000, @issue_date_from)
	SELECT @issue_date_to_2000 = dateadd(DAY, 1, dateadd(YEAR, 2000, @issue_date_to))

	--DWH-300
	DECLARE @t_ДоговорЗайма_ТипПродукта table(id int, ТипПродукта varchar(128))
	insert @t_ДоговорЗайма_ТипПродукта(id, ТипПродукта)
	select 
		id = row_number() over(order by t.ТипПродукта),
		t.ТипПродукта
	from (
		select ТипПродукта = v.ПодтипПродуктd_Наименование
		from dwh2.hub.v_hub_ГруппаПродуктов as v
		) as t
	order by id 

	DECLARE @t_product_type_list table(product_type varchar(128))

	IF @product_type_list = ''
	BEGIN
		INSERT @t_product_type_list(product_type)
		select product_type = t.ТипПродукта
		from @t_ДоговорЗайма_ТипПродукта as t
	END
	ELSE BEGIN
		INSERT @t_product_type_list(product_type)
		SELECT S.value
		FROM string_split(@product_type_list, ',') AS S
	END

	DROP TABLE IF EXISTS #t_loan_for_archive
	SELECT
		[Ссылка]		= dz.СсылкаДоговораЗайма,
		external_id		= dz.КодДоговораЗайма,
		loan_date		= dz.ДатаДоговораЗайма,
		issue_date		= dateadd(YEAR, -2000, V.ДатаВыдачи),
		client_fio		= concat(dz.фамилия, ' ', dz.Имя, ' ', dz.Отчество),
		product_type	= isnull(dz.ПодТипПродукта, 'ПТС')
	--Статус договора (на дату отчета)
	INTO #t_loan_for_archive
	FROM dwh2.[dm].[ДоговорЗайма] dz
	INNER JOIN Stg._1cCMR.Документ_ВыдачаДенежныхСредств AS V
		ON V.Договор = dz.СсылкаДоговораЗайма
	   AND V.Проведен = 1
	   AND V.ПометкаУдаления = 0
	INNER JOIN  @t_product_type_list AS PT_t
		ON PT_t.product_type = isnull(dz.ПодТипПродукта, 'ПТС')
	WHERE 1=1
		AND dz.isDelete <> 1
		AND @issue_date_from_2000 <= V.ДатаВыдачи AND V.ДатаВыдачи <= @issue_date_to_2000

	CREATE CLUSTERED INDEX clix_link ON #t_loan_for_archive(Ссылка)

	DROP TABLE IF EXISTS #t_ПоследнийСтатус
	SELECT DISTINCT
		D.Ссылка,
		ПоследнийСтатус = first_value(SD.Статус) OVER(PARTITION BY SD.Договор ORDER BY SD.Период DESC)
	INTO #t_ПоследнийСтатус
	FROM #t_loan_for_archive AS D
		INNER JOIN Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS SD
			ON D.Ссылка = SD.Договор

	CREATE CLUSTERED INDEX clix_id ON #t_ПоследнийСтатус(Ссылка)

	SELECT 
		--D.Ссылка,
		D.external_id,
		D.loan_date,
		D.issue_date,
		D.client_fio,
		D.product_type,
		--Статус договора (на дату отчета)
		loan_last_status = convert(nvarchar(100), SSD.Наименование)
	FROM #t_loan_for_archive AS D
		--INNER JOIN @t_product_type_list AS PT
		--	ON PT.product_type = D.product_type
		LEFT JOIN #t_ПоследнийСтатус AS S
			ON S.Ссылка = D.Ссылка
		LEFT JOIN Stg._1ccmr.Справочник_СтатусыДоговоров AS SSD
			ON SSD.Ссылка = S.ПоследнийСтатус
	ORDER BY D.issue_date
END

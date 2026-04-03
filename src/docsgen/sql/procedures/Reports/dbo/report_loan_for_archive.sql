-- ============================================= 
-- Author: А. Никитин
-- Create date: 25.10.2022
-- Description: DWH-1784 Отчет Договора для архива
-- ============================================= 
CREATE PROC dbo.report_loan_for_archive
	@issue_date_from date = NULL,
	@issue_date_to date	= NULL,
	@product_type_list varchar(2048) = ''
AS 
BEGIN
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
		--select distinct d.ТипПродукта
		--from dwh2.hub.ДоговорЗайма as d
		select ТипПродукта = v.ПодтипПродуктd_Наименование
		from dwh2.hub.v_hub_ГруппаПродуктов as v
		) as t
	order by id
	--test
	--select * from @t_ДоговорЗайма_ТипПродукта 

	DECLARE @t_product_type_list table(product_type varchar(128))

	/*
	--var 1
	IF @product_type_list = ''
	BEGIN
		INSERT @t_product_type_list(product_type)
		SELECT T.product_type
		FROM (
			SELECT id = 1, product_type = convert(varchar(30), 'Смарт-инстоллмент')
			UNION SELECT id = 2, product_type = 'Инстоллмент'
			UNION SELECT id = 3, product_type = 'ПТС31'
			UNION SELECT id = 4, product_type = 'ПТС'
			) AS T
	END
	ELSE BEGIN
		INSERT @t_product_type_list(product_type)
		SELECT S.value
		FROM string_split(@product_type_list, ',') AS S
	END
	*/

	--var 2 
	--DWH-300
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
		D.Ссылка,
		--Номер договора
		external_id = D.Код,
		--CMRContractGUID = dwh_new.dbo.getGUIDFrom1C_IDRREF(D.Ссылка),
		--CRMClientGUID =  dwh_new.dbo.getGUIDFrom1C_IDRREF(D.Клиент),
		--Дата договора
		loan_date = dateadd(YEAR, -2000, D.Дата),
		--Дата выдачи по договору
		issue_date = dateadd(YEAR, -2000, V.ДатаВыдачи),
		--ФИО клиента
		client_fio = concat(D.фамилия, ' ', D.Имя, ' ', D.Отчество),

		--Продукт
		--product_type = CP.Наименование

		--Если isSmartInstallment = Истина - 'Смартинстолмент'
		--иначеесли isInstallment = Истина - 'Инстоллмент'
		--иначеесли Заявка.ИспытательныйСрок = Истина - 'ПТС31'
		--Иначе 'ПТС'

		--pt.product_type
		--product_type = ДоговорЗайма.ТипПродукта
		product_type = isnull(ДоговорЗайма.ПодТипПродукта, 'ПТС')

		--Статус договора (на дату отчета)
	INTO #t_loan_for_archive
	FROM Stg._1cCMR.Справочник_Договоры AS D
		--LEFT JOIN Stg._1cCMR.Справочник_КредитныеПродукты AS CP
		--	ON CP.Ссылка = D.КредитныйПродукт
		INNER JOIN Stg._1cCMR.Документ_ВыдачаДенежныхСредств AS V
			ON V.Договор = D.Ссылка
			AND V.Проведен = 1
			AND V.ПометкаУдаления = 0
		INNER JOIN Stg._1cCMR.Справочник_Заявка AS R
			ON D.Заявка = R.Ссылка
		--var 1
		--outer apply 
		--(
		--	select product_type = 
		--	CASE 
		--		WHEN isnull(D.isSmartInstallment,0) = 1 THEN 'Смарт-инстоллмент'
		--		WHEN isnull(D.isInstallment,0)= 1 THEN 'Инстоллмент'
		--		WHEN isnull(R.ИспытательныйСрок,0) = 1 THEN 'ПТС31'
		--		ELSE 'ПТС'
		--	END
		--) pt
		--inner join @t_product_type_list AS PT_t
		--	ON PT_t.product_type = pt.product_type

		--var 2 
		--DWH-300
		inner join dwh2.hub.ДоговорЗайма as ДоговорЗайма
			on ДоговорЗайма.СсылкаДоговораЗайма = D.Ссылка
		inner join @t_product_type_list AS PT_t
			--ON PT_t.product_type = ДоговорЗайма.ТипПродукта
			ON PT_t.product_type = isnull(ДоговорЗайма.ПодТипПродукта, 'ПТС')
	WHERE 1=1
		AND D.ПометкаУдаления <> 0x01
		AND @issue_date_from_2000 <= V.ДатаВыдачи AND V.ДатаВыдачи <= @issue_date_to_2000

	--фильтр по Продукту
	--CREATE INDEX ix_product_type ON #t_loan_for_archive(product_type)

	--DELETE D
	--FROM #t_loan_for_archive AS D
	--	LEFT JOIN @t_product_type_list AS PT
	--		ON PT.product_type = D.product_type
	--WHERE PT.product_type IS NULL


	CREATE CLUSTERED INDEX clix_id ON #t_loan_for_archive(Ссылка)

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
	--ORDER BY D.external_id
	ORDER BY D.issue_date
    
END
 

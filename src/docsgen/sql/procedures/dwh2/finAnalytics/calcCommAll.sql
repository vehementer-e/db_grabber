

CREATE PROC [finAnalytics].[calcCommAll] 
    @repmonth date
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = 'Выполнение процедуры расчета данных по Комиссиям'
    
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc
	
    begin try

	DROP TABLE IF EXISTS #commAll

	select
	a.repMonth
	, a.acc2order
	, a.accNum
	, a.accName
	, a.subconto1
	, a.subconto1UID
	, a.subconto2
	, a.subconto3
	, a.subconto2UID
	, a.branch
	, a.restIN_BU
	, a.sumDT_BU
	, a.sumKT_BU
	, a.restOUT_BU

	into #commAll

	from finAnalytics.OSV_MONTHLY a

	where a.repMonth = @repmonth
	and (
	
	(
	a.acc2order='71702'
	and a.subconto1 in (
					'Услуги платежных систем по выдаче и возврату займов (невключаемые в расчет ЭСП) (53103, сч.71702)'
					,'53102 банковские услуги (РКО-выдача займов)'
					)
	)
	or
	(
	a.acc2order='71802'
	and a.subconto1 in (
					'Расходы на страхование клиентов-заемщиков (55412, сч. 71802)'
					)
	)
	or
	
	(
	a.acc2order='71601'
	and a.subconto1 in (
					'Другие комиссионные доходы (71601 символ 51402)'
					,'Другие комиссионные доходы(за снижение % ставки) (71601 символ 51402)'
					,'Другие комиссионные доходы(за фин.помощь) (71601 символ 51402)'
					,'Другие комиссионные доходы(КАСКО)(71601 символ 51402)'
					,'Другие комиссионные доходы(нс)(71601 символ 51402)'
					,'Другие комиссионные доходы(потеря работы) (71601 символ 51402)'
					,'Другие комиссионные доходы(страхование квартиры (71601 символ 51402)'
					,'Другие комиссионные доходы(телемедицина) (71601 символ 51402)'
					,'Другие комиссионные доходы (комиссия по тарифам за СМС-информир. о залоге) (71601 символ 51402)'
					,'Другие комиссионные доходы (комиссия по тарифам за срочное снятие залога) (71601 символ 51402)'
					,'Другие комиссионные доходы (Другие комиссионные доходы (Безопасность семьи 71601 символ 51402)'
					,'Другие комиссионные доходы (Консультационные услуги по снятию запрета с автомобиля) (71601 символ 51402)'
					,'Другие комиссионные доходы (Комиссия в счет возмещения расходов по договору залога (50 000,00)) (71601 символ 51402)'
					,'Другие комиссионные доходы (Комиссия за справку "Электронный Стандарт") (71601 символ 51402)'
					,'Другие комиссионные доходы (Комиссия за услугу "Оценка рыночной стоимости авто") (71601 символ 51402)'
					,'Другие комиссионные доходы (Комиссия в счет возмещения расходов по договору залога (5 000,00 возврат ТС)) (71601 символ 51402)'
					,'Прочие доходы от операций с юридическими лицами  (71601 символ 51402)'
					,'Другие комиссионные доходы (Комиссия за справку "Бумажный Стандарт") (71601 символ 51402)'
					)
	)
	
	)

	--select * from #commAll

	DROP TABLE IF EXISTS #commPS

	select
	l1.ACC2
	,l1.Kt
	,l1.DtKt
	,l1.subconto1
	,l1.acc
	,client = l1.Наименование
	,summa = l1.Сумма
	,nazn = l1.Содержание

	into #commPS

	from(

	SELECT 
	ACC2 = Dt.Код
	,Kt = Kt.Код
	,DtKt = 'DT'
	,subconto1 = sprDT.Наименование
	,acc = accDT.Наименование
	,clkt.Наименование
	,a.Сумма
	,a.Содержание
	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0

	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета accDT on a.СчетАналитическогоУчетаДт=accDT.Ссылка

	left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы sprDT on a.СубконтоDt1_Ссылка=sprDT.Ссылка
	left join stg._1cUMFO.Справочник_Контрагенты clkt on a.СубконтоCt1_Ссылка=clkt.Ссылка

	where a.Период between cast(dateadd(year,2000,@repmonth) as datetime) and DATETIMEFROMPARTS(year(@repmonth)+2000,month(@repmonth),DAY(EOMONTH(@repmonth)),23,59,59,0)
	and a.Активность=01
	and ((
	Dt.Код = '71702'
	and sprDT.Наименование='Услуги платежных систем по выдаче и возврату займов (невключаемые в расчет ЭСП) (53103, сч.71702)'
	)
	or
	(
	Dt.Код = '71701'
	and sprDT.Наименование='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
	and upper(clkt.Наименование) = UPPER('EcommPay')
	))



	union all

	SELECT 
	Kt.Код
	,Dt.Код
	,DtKt = 'KT'
	,sprKT.Наименование
	,accKT.Наименование
	,cldt.Наименование

	,a.Сумма
	,a.Содержание
	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0

	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета acckT on a.СчетАналитическогоУчетаДт=accKT.Ссылка

	left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы sprKT on a.СубконтоCt1_Ссылка=sprKT.Ссылка
	left join stg._1cUMFO.Справочник_Контрагенты cldt on a.СубконтоDt1_Ссылка=cldt.Ссылка

	where a.Период between cast(dateadd(year,2000,@repmonth) as datetime) and DATETIMEFROMPARTS(year(@repmonth)+2000,month(@repmonth),DAY(EOMONTH(@repmonth)),23,59,59,0)
	and a.Активность=01
	and ((
	Kt.Код='71702'
	and sprKT.Наименование='Услуги платежных систем по выдаче и возврату займов (невключаемые в расчет ЭСП) (53103, сч.71702)'
	)
	or
	(
	Kt.Код = '71701'
	and sprKT.Наименование='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
	and upper(cldt.Наименование) = UPPER('EcommPay')
	))
	) l1

    begin tran  
    
		--ПС. Расш

		delete from finanalytics.commPS where repmonth = @repmonth

		--t1p1
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 1
		, rowName = '1'--'ПС_10'
		, acc = '71702'
		, OSVName = '53102 банковские услуги (РКО-выдача займов)'
		, platSys = ''
		, platType = ''
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(sumDT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
					from #commAll
					where acc2order = '71702'
					and subconto1='53102 банковские услуги (РКО-выдача займов)'
					) l1
					)

		--t1p2
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 2
		, rowName = '2'--'ПС_20'
		, acc = ''
		, OSVName = ''
		, platSys = 'БРС'
		, platType = 'по выдаче займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='БРС'
					)

		--t1p3
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 3
		, rowName = '3'--'ПС_30'
		, acc = ''
		, OSVName = ''
		, platSys = 'Cloud paymemts (Тинькоф)'
		, platType = 'по выдаче займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='Cloud paymemts (Тинькоф)'
					)

		--t1p4
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 4
		, rowName = '4'--'ПС_40'
		, acc = '71702'
		, OSVName = 'Услуги платежных систем по выдаче и возврату займов (невключаемые в расчет ЭСП) (53103, сч.71702)'
		, platSys = ''
		, platType = ''
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(sumDT_BU,0)*-1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
					from #commAll
					where acc2order = '71702'
					and subconto1='Услуги платежных систем по выдаче и возврату займов (невключаемые в расчет ЭСП) (53103, сч.71702)'
					) l1
					)

		--t1p5.1
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 6
		, rowName = '5.1'--'ПС_50'
		, acc = ''
		, OSVName = ''
		, platSys = 'ECommPay'
		, platType = 'по выдаче займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='EcommPay'
					)
		
		--t1p5.2
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 7
		, rowName = '5.2'--'ПС_50'
		, acc = ''
		, OSVName = ''
		, platSys = 'ECommPay'
		, platType = 'по возврату займов'
		, platAmount = 0

		--t1p5.3
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 8
		, rowName = '5.3'--'ПС_50'
		, acc = ''
		, OSVName = ''
		, platSys = 'ECommPay'
		, platType = 'другие услуги'
		, platAmount = 0

		
		--t1p6
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 9
		, rowName = '6'--'ПС_60'
		, acc = ''
		, OSVName = ''
		, platSys = 'CONTACT'
		, platType = 'по выдаче займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='CONTACT (выдачи)'
					)

		--t1p7
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 10
		, rowName = '7'--'ПС_70'
		, acc = ''
		, OSVName = ''
		, platSys = 'CONTACT'
		, platType = 'по возврату займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='CONTACT (возврат)'
					)

		--t1p8
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 11
		, rowName = '8'--'ПС_80'
		, acc = ''
		, OSVName = ''
		, platSys = 'CONTACT'
		, platType = 'другие услуги'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='CONTACT (прочее)'
					)

		--t1p9
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 12
		, rowName = '9'--'ПС_90'
		, acc = ''
		, OSVName = ''
		, platSys = 'Cloud paymemts'
		, platType = 'по возврату займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='Cloud payments'
					)

		--t1p10
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 13
		, rowName = '10'--'ПС_100'
		, acc = ''
		, OSVName = ''
		, platSys = 'СБП'
		, platType = 'по выдаче займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='СБП'
					)

		--t1p11
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 14
		, rowName = '11'--'ПС_110'
		, acc = ''
		, OSVName = ''
		, platSys = 'Биллинговый центр'
		, platType = 'по возврату займов'
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					,summa = case when DtKt='DT' then summa	* -1
							when month(@repmonth) = 1 and DtKt='KT' then 0
							else summa
							end
					,nazn
					from #commPS
					where acc2='71702'
					) l1

					where client='Биллинговый центр'
					)

		--t1p12
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 15
		, rowName = '12'--'ПС_120'
		, acc = ''
		, OSVName = ''
		, platSys = 'Корректировки / балансировки выдачи / возвраты'
		, platType = 'Корректировки / балансировки'
		, platAmount = 0

		--t1p12.1
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 16
		, rowName = '12.1'--'ПС_120'
		, acc = ''
		, OSVName = ''
		, platSys = '  выдачи / возвраты'
		, platType = 'Корректировки / балансировки'
		, platAmount = 0

		--t1p12.2
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 17
		, rowName = '12.2'--'ПС_120'
		, acc = ''
		, OSVName = ''
		, platSys = '  сторно'
		, platType = 'Корректировки / балансировки'
		, platAmount = 0

		--t1p12.3
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 18
		, rowName = '12.3'--'ПС_120'
		, acc = ''
		, OSVName = ''
		, platSys = '  другие услуги'
		, platType = 'Корректировки / балансировки'
		, platAmount = 0

		--t1p13
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 19
		, rowName = '13'--'ПС_120'
		, acc = ''
		, OSVName = ''
		, platSys = 'Корректировки / балансировки EcommPay (доходы)'
		, platType = 'Корректировки / балансировки'
		, platAmount = 0

		--t1p13.1
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 20
		, rowName = '13.1'--'ПС_120'
		, acc = ''
		, OSVName = ''
		, platSys = 'Корректировки / балансировки СБП'
		, platType = 'Корректировки / балансировки'
		, platAmount = 0

		--t1p14
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 21
		, rowName = '14'--'ПС_120'
		, acc = ''
		, OSVName = ''
		, platSys = 'Балансировка ECommPay "другие услуги" (БУ)'
		, platType = 'Корректировки / балансировки'
		, platAmount = 0

		--t1p14
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 22
		, rowName = '15'--'ПС_130'
		, acc = 'Проверка'
		, OSVName = ''
		, platSys = ''
		, platType = ''
		, platAmount = (
					select
					SUM(platAmount)
					from(
					select
					platAmount = case when rowName IN ('2','3') then platAmount * -1 else platAmount end
					from finAnalytics.commPS 
					where rowName in ('1','2','3')--('ПС_10','ПС_20','ПС_30')
					and repmonth = @repmonth
					) l1
					)

		-------------Корректировки по статьям
		merge into finAnalytics.commPS t1
		using(
		SELECT 
			[rowName]
		   ,[sheetName]
		   ,[correctionAmount] = [correctionAmount]/* * -1*/
        FROM [dwh2].[finAnalytics].[SPR_comm_correction]
        where repmonth = @repmonth
        and sheetName = 'ПС'
		) t2 on (t1.repmonth=@repmonth and upper(t1.rowName)=upper(t2.[rowName]))
		WHEN MATCHED THEN UPDATE
		SET t1.platAmount = t1.platAmount + isnull(t2.[correctionAmount],0);

		-------------Корректировки 12 Итого
		merge into finAnalytics.commPS t1
		using(
		select
		platAmount = SUM(platAmount /** -1*/)
		from finAnalytics.commPS
		where repmonth = @repmonth
		and rowName in ('12.1','12.2','12.3')		
		) t2 on (t1.repmonth=@repmonth and upper(t1.rowName)='12')
		WHEN MATCHED THEN UPDATE
		SET t1.platAmount = isnull(t2.platAmount,0);
		
		--t1p5
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 5
		, rowName = '5'--'ПС_50'
		, acc = ''
		, OSVName = ''
		, platSys = 'ECommPay'
		, platType = ''
		, platAmount = (select 
							sum(isnull(case when rowName in ('12.1','12.3') then platAmount * -1 else platAmount end,0)) 
							from finanalytics.commPS 
							where repmonth = @repmonth 
							and rowName in ('5.1','5.2','5.3','12.1','12.3')
						)

		--t1p5.1 корректировка 
		merge into finanalytics.commPS t1
		using(
		select 
		platAmount = sum(isnull(platAmount,0)) 
		from finanalytics.commPS 
		where repmonth = @repmonth 
		and rowName in ('12.1','14')
		) t2 on (t1.repmonth = @repmonth and t1.rowName = '5.1')
		when matched then update
		set t1.platAmount = t1.platAmount - t2.platAmount;

		--t1p5.3 корректировка 
		merge into finanalytics.commPS t1
		using(
		select 
		platAmount = sum(isnull(case when rowName = '12.3' then platAmount *-1 else platAmount end,0)) 
		from finanalytics.commPS 
		where repmonth = @repmonth 
		and rowName in ('14','12.3')
		) t2 on (t1.repmonth = @repmonth and t1.rowName = '5.3')
		when matched then update
		set t1.platAmount = t2.platAmount;

		--t1p15
		insert into finanalytics.commPS 
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 23
		, rowName = '16'--'ПС_140'
		, acc = 'Проверка'
		, OSVName = ''
		, platSys = ''
		, platType = ''
		, platAmount = (
					select
					SUM(platAmount)
					from(
					select
					platAmount = case when rowName IN ('5','6','7','8','9','10','11','12') then platAmount * -1 else platAmount end
					from finAnalytics.commPS 
					where rowName in ('4','5','6','7','8','9','10','11','12')
					and repmonth = @repmonth
					) l1
					)


		--t1p16
		insert into finanalytics.commPS
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 24
		, rowName = '17'--'ПС_150'
		, acc = ''
		, OSVName = ''
		, platSys = 'EcommPay (доходы)'
		, platType = ''
		, platAmount = (
					select
					platAmount = isnull(SUM(isnull(summa,0)),0)
					from(
					select
					ACC2	
					,DtKt	
					,kt
					,subconto1	
					,acc	
					,client = case 
									when upper(client) = UPPER('EcommPay') then 'EcommPay'
									when upper(client) = UPPER('Cloud payments') then 'Cloud payments'
									when upper(client) = UPPER('СНГБ АО БАНК') then 'СБП'
									when upper(client) = UPPER('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО') then 'Биллинговый центр'
									when upper(client) = UPPER('АО "БАНК РУССКИЙ СТАНДАРТ"') then 'БРС'
									when upper(client) = UPPER('АО "ТБанк"') then 'Cloud paymemts (Тинькоф)'
									when Kt='20501' and nazn like '%SZDV%' then 'CONTACT (выдачи)'
									when Kt='20501' and nazn like '%SZDR%' then 'CONTACT (возврат)'
									when Kt='20501' and nazn not like '%SZDR%' and nazn not like '%SZDV%' then 'CONTACT (прочее)'
								end 
					
					,summa = case when DtKt='DT' then summa	* -1
								  when DtKt='KT' then summa
							end
					
					--,summa
					,nazn
					from #commPS
					where acc2='71701' and Kt='47423' --and DtKt='KT'
					) l1
					)

		--t1p17
		insert into finanalytics.commPS
		(repmonth, rowNum, rowName, acc, OSVName, platSys, platType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 25
		, rowName = '18'--'ПС_160'
		, acc = ''
		, OSVName = ''
		, platSys = 'EcommPay (доходы) (с НДС)'
		, platType = ''
		, platAmount = 0

		-----------EcomPay(Доходы) с НДС
		merge into finAnalytics.commPS t1
		using(
		select
		repmonth, 
		platAmount = SUM(platAmount * 1.2)
		from finAnalytics.commPS
		where 1=1
		and repmonth = @repmonth
		and rowName = '17'
		group by repmonth
		) t2 on (t1.repmonth=@repmonth and upper(t1.rowName)='18')
		WHEN MATCHED THEN UPDATE
		SET t1.platAmount = isnull(t2.platAmount,0);

		--t1p10 корректировка 
		merge into finanalytics.commPS t1
		using(
		select 
		platAmount = sum(case when rowName ='13.1' then isnull(platAmount,0) * -1 else isnull(platAmount,0) end) 
		from finanalytics.commPS 
		where repmonth = @repmonth 
		and rowName in ('13.1','10')
		) t2 on (t1.repmonth = @repmonth and t1.rowName = '10')
		when matched then update
		set t1.platAmount = t2.platAmount;
					
		DELETE from finAnalytics.commAll where repmonth = @repmonth

		--t2p1
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)
		select
		repmonth = @repmonth
		,rowNum = 1
		, rowName = '1.1'--'КП_10'
		, acc = '71802'
		, OSVName = 'Расходы на страхование клиентов-заемщиков (55412, сч. 71802)'
		, platType = 'Страхование заемщиков (расходы)'
		, isPSK = ''
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Расходы на страхование клиентов-заемщиков (55412, сч. 71802)'
					) l1
					)

		--t2p2
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 2
		, rowName = '2.1'--'КП_20'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (71601 символ 51402)'
		, platType = 'Прочие (коробки)'
		, isPSK = ''
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (71601 символ 51402)'
					) l1
					)

		--t2p3
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 3
		, rowName = '2.2'--'КП_30'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы(за снижение % ставки) (71601 символ 51402)'
		, platType = 'КарМани. Снижение % и финпомощь'
		, isPSK = 'ПСК'
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы(за снижение % ставки) (71601 символ 51402)'
					) l1
					)

		--t2p4
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 4
		, rowName = '2.3'--'КП_40'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы(за фин.помощь) (71601 символ 51402)'
		, platType = 'КарМани. Снижение % и финпомощь'
		, isPSK = 'ПСК'
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы(за фин.помощь) (71601 символ 51402)'
					) l1
					)

		--t2p5
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 5
		, rowName = '2.4'--'КП_50'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы(КАСКО)(71601 символ 51402)'
		, platType = 'Каско (1%)'
		, isPSK = 'ПСК'
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы(КАСКО)(71601 символ 51402)'
					) l1
					)

		--t2p6
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 6
		, rowName = '2.5'--'КП_60'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы(нс)(71601 символ 51402)'
		, platType = 'НС (0,5%)'
		, isPSK = 'ПСК'
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы(нс)(71601 символ 51402)'
					) l1
					)

		--t2p7
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 7
		, rowName = '2.6'--'КП_70'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы(потеря работы) (71601 символ 51402)'
		, platType = 'Потеря работы (3-й пакет "Спокойная жизнь")'
		, isPSK = 'ПСК'
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы(потеря работы) (71601 символ 51402)'
					) l1
					)

		--t2p8
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 8
		, rowName = '2.7'--'КП_80'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы(страхование квартиры (71601 символ 51402)'
		, platType = 'Страхование квартиры (3-й пакет "Спокойная жизнь")'
		, isPSK = 'ПСК'
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы(страхование квартиры (71601 символ 51402)'
					) l1
					)

		--t2p9
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 9
		, rowName = '2.8'--'КП_90'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы(телемедицина) (71601 символ 51402)'
		, platType = 'Телемедицина (3-й пакет "Спокойная жизнь")'
		, isPSK = 'ПСК'
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы(телемедицина) (71601 символ 51402)'
					) l1
					)

		--t2p10
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 10
		, rowName = '2.9'--'КП_100'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (комиссия по тарифам за СМС-информир. о залоге) (71601 символ 51402)'
		, platType = 'СМС-информирование  о залоге'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (комиссия по тарифам за СМС-информир. о залоге) (71601 символ 51402)'
					) l1
					)

		--t2p11
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 11
		, rowName = '2.10'--'КП_110'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (комиссия по тарифам за срочное снятие залога) (71601 символ 51402)'
		, platType = 'Cрочное снятие залога'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (комиссия по тарифам за срочное снятие залога) (71601 символ 51402)'
					) l1
					)

		--t2p12
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 12
		, rowName = '2.11'--'КП_112'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (Консультационные услуги по снятию запрета с автомобиля) (71601 символ 51402)'
		, platType = 'Снятие запрета с автомобиля'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (Консультационные услуги по снятию запрета с автомобиля) (71601 символ 51402)'
					) l1
					)

		--t2p13
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 13
		, rowName = '2.12'--'КП_111'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (Безопасность семьи 71601 символ 51402)'
		, platType = 'Прочие (коробки)'
		, isPSK = ''
		, commType = 'КП при выдаче'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (Другие комиссионные доходы (Безопасность семьи 71601 символ 51402)'
					) l1
					)
		
		--t2p14
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 14
		, rowName = '2.13'--'КП_120'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (Комиссия в счет возмещения расходов по договору залога (50 000,00)) (71601 символ 51402)'
		, platType = 'Возмещения по договору залога'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (Комиссия в счет возмещения расходов по договору залога (50 000,00)) (71601 символ 51402)'
					) l1
					)
		--t2p15
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 15
		, rowName = '2.14'--'КП_120'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (Комиссия за справку "Электронный Стандарт") (71601 символ 51402)'
		, platType = 'Комиссии за справки'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (Комиссия за справку "Электронный Стандарт") (71601 символ 51402)'
					) l1
					)

		--t2p16
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 16
		, rowName = '2.15'--'КП_120'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (Комиссия за услугу "Оценка рыночной стоимости авто") (71601 символ 51402)'
		, platType = 'Оценка рыночной стоимости авто'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (Комиссия за услугу "Оценка рыночной стоимости авто") (71601 символ 51402)'
					) l1
					)
		--t2p17
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 17
		, rowName = '2.16'--'КП_120'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (Комиссия в счет возмещения расходов по договору залога (5 000,00 возврат ТС)) (71601 символ 51402)'
		, platType = 'Возмещение расходов по договору залога (возврат ТС)'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (Комиссия в счет возмещения расходов по договору залога (5 000,00 возврат ТС)) (71601 символ 51402)'
					) l1
					)

		--t2p18
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 18
		, rowName = '2.17'--'КП_120'
		, acc = '71601'
		, OSVName = 'Прочие доходы от операций с юридическими лицами  (71601 символ 51402)'
		, platType = 'Вознаграждение по партнерским договорам с ЮЛ'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Прочие доходы от операций с юридическими лицами  (71601 символ 51402)'
					) l1
					)

		--t2p19
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 19
		, rowName = '2.18'--'КП_120'
		, acc = '71601'
		, OSVName = 'Другие комиссионные доходы (Комиссия за справку "Бумажный Стандарт") (71601 символ 51402)'
		, platType = 'Комиссии за справки'
		, isPSK = ''
		, commType = 'Другие КП'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные доходы (Комиссия за справку "Бумажный Стандарт") (71601 символ 51402)'
					) l1
					)

		--t2p20
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 20
		, rowName = '3.1'--'КП_120'
		, acc = '71702'
		, OSVName = 'Другие комиссионные расходы (71702 символ 53106)'
		, platType = 'Возврат при отказе от услуг (расходы)'
		, isPSK = ''
		, commType = 'Возвраты'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Другие комиссионные расходы (71702 символ 53106)'
					) l1
					)

		--t2p21
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 21
		, rowName = '3.2'--'КП_130'
		, acc = '71702'
		, OSVName = 'Расходы по возврату(компенсации) услуг, оказанных ФЛ(заемщикам) (53803 сч. 71702)'
		, platType = 'Возврат при отказе от услуг (расходы)'
		, isPSK = ''
		, commType = 'Возвраты'
		, platAmount = (select
					platAmount = ISNULL(SUM(platAmount),0)
					from(
					select
					platAmount = case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end
				
					from #commAll
					where subconto1='Расходы по возврату(компенсации) услуг, оказанных ФЛ(заемщикам) (53803 сч. 71702)'
					) l1
					)

		--t2p22
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 22
		, rowName = '4'--'КП_140'
		, acc = ''
		, OSVName = 'Корректировки / балансировки'
		, platType = 'Корректировки / балансировки'
		, isPSK = ''
		, commType = 'Корректировки / балансировки'
		, platAmount = 0

		--t2p23
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 23
		, rowName = '5'--'КП_150'
		, acc = ''
		, OSVName = 'проверка 71601'
		, platType = ''
		, isPSK = ''
		, commType = ''
		, platAmount = 0

		--t2p0
		INSERT INTO finAnalytics.commAll 
		(repmonth, rowNum, rowName, acc, OSVName, platType, isPSK, commType, platAmount)

		select
		repmonth = @repmonth
		,rowNum = 0
		, rowName = '0'
		, acc = ''
		, OSVName = ''
		, platType = 'ИТОГО'
		, isPSK = ''
		, commType = ''
		, platAmount = (
					select platAmount = SUM(platAmount) from finAnalytics.commAll where repmonth = @repmonth
					)
		

		-----------Проверка 70601
		merge into finAnalytics.commAll t1
		using(
		select
				amountDiff = l1.amountRep - l1.amountOSV
				from(
				select
				[amountRep] = (select
								platAmount = SUM(platAmount)
								from finAnalytics.commAll
								where 1=1
								and repmonth = @repmonth
								and rowName in ('2.1','2.2','2.3','2.4','2.5','2.6','2.7','2.8','2.9','2.10','2.11','2.12','2.13','2.14','2.15','2.16','2.17','2.18')
								)
				,[amountOSV] = (select
								sum(case when MONTH(repMonth) = 1 then ISNULL(restOUT_BU,0) * -1 else isnull(sumKT_BU,0) - ISNULL(sumDT_BU,0) end)
								--sum(sumKT_BU) - sum(sumDT_BU)
								from finAnalytics.OSV_MONTHLY a
								where repmonth = @repmonth
								and acc2order = '71601'
								)
				) l1
		) t2 on (t1.repmonth=@repmonth and upper(t1.rowName)='5')
		WHEN MATCHED THEN UPDATE
		SET t1.platAmount = isnull(t2.amountDiff,0);

	commit tran
    
	--order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.commAll) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 6

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры расчета комиссий за '
				,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
                ,'Время начала выполнения: '
                ,@procStartTime
                ,char(10)
                ,char(13)
                ,'Время окончания выполнения: '
                ,@procEndTime
                ,char(10)
                ,char(13)
                ,'Время выполнения: '
                ,@timeDuration
                ,char(10)
                ,char(13)
                ,'Максимальная отчетная дата: '
                ,@maxDateRest
				)
	
	declare @emailList varchar(255)=''
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END

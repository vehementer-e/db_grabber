CREATE proc --exec

[dbo].[create_dm_factor_analysis]

@reCreateTable bit =  0
as
begin
	begin try


	--составление справочника регионов
	--select distinct [Регион проживания] from  dbo.dm_Factor_Analysis_001
	--select distinct [РегионПроживания] from  dbo.dm_Factor_Analysis
	drop table if exists #regions
	select '' РегионДляПоиская, 'unknown' Регион into #regions union all
	select ',' РегионДляПоиская, 'unknown' Регион union all
	select '1211' РегионДляПоиская, 'unknown' Регион union all
	select '3' РегионДляПоиская, 'unknown' Регион union all
	select 'Адыгея Респ' РегионДляПоиская, 'Адыгея' Регион union all
	select 'Алтай Респ' РегионДляПоиская, 'Алтай' Регион union all
	select 'Алтайский край' РегионДляПоиская, 'Алтай' Регион union all
	select 'Амурская обл' РегионДляПоиская, 'Амурская' Регион union all
	select 'Архангельская обл' РегионДляПоиская, 'Архангельская' Регион union all
	select 'Астраханская обл' РегионДляПоиская, 'Астраханская' Регион union all
	select 'Байконур г' РегионДляПоиская, 'Байконур' Регион union all
	select 'Башкортостан' РегионДляПоиская, 'Башкортостан' Регион union all
	select 'Башкортостан Респ' РегионДляПоиская, 'Башкортостан' Регион union all
	select 'Белгородская обл' РегионДляПоиская, 'Белгородская' Регион union all
	select 'Брянская обл' РегионДляПоиская, 'Брянская' Регион union all
	select 'Бурятия Респ' РегионДляПоиская, 'Бурятия' Регион union all
	select 'Владимирская обл' РегионДляПоиская, 'Владимирская' Регион union all
	select 'Волгоградская обл' РегионДляПоиская, 'Волгоградская' Регион union all
	select 'Вологодская обл' РегионДляПоиская, 'Вологодская' Регион union all
	select 'Воронежская обл' РегионДляПоиская, 'Воронежская' Регион union all
	select 'Дагестан Респ' РегионДляПоиская, 'Дагестан' Регион union all
	select 'Ё' РегионДляПоиская, 'unknown' Регион union all
	select 'Еврейская Аобл' РегионДляПоиская, 'Еврейская' Регион union all
	select 'Забайкальский край' РегионДляПоиская, 'Забайкальский' Регион union all
	select 'Ивановская обл' РегионДляПоиская, 'Ивановская' Регион union all
	select 'Ингушетия Респ' РегионДляПоиская, 'Ингушетия' Регион union all
	select 'Иркутская обл' РегионДляПоиская, 'Иркутская' Регион union all
	select 'Кабардино-Балкарская Респ' РегионДляПоиская, 'Кабардино-Балкарская' Регион union all
	select 'Калининградская обл' РегионДляПоиская, 'Калининградская' Регион union all
	select 'Калмыкия Респ' РегионДляПоиская, 'Калмыкия' Регион union all
	select 'Калужская обл' РегионДляПоиская, 'Калужская' Регион union all
	select 'Камчатский край' РегионДляПоиская, 'Камчатский' Регион union all
	select 'Карачаево-Черкесская Респ' РегионДляПоиская, 'Карачаево-Черкесская' Регион union all
	select 'Карелия Респ' РегионДляПоиская, 'Карелия' Регион union all
	select 'Кемеровская обл' РегионДляПоиская, 'Кемеровская' Регион union all
	select 'Кировская обл' РегионДляПоиская, 'Кировская' Регион union all
	select 'Коми Респ' РегионДляПоиская, 'Коми' Регион union all
	select 'Костромская обл' РегионДляПоиская, 'Костромская' Регион union all
	select 'Краснодарский край' РегионДляПоиская, 'Краснодарский' Регион union all
	select 'Красноярский край' РегионДляПоиская, 'Красноярский' Регион union all
	select 'Крым Респ' РегионДляПоиская, 'Крым' Регион union all
	select 'Курганская обл' РегионДляПоиская, 'Курганская' Регион union all
	select 'Курская обл' РегионДляПоиская, 'Курская' Регион union all
	select 'Ленинградская обл' РегионДляПоиская, 'Ленинградская' Регион union all
	select 'Липецкая обл' РегионДляПоиская, 'Липецкая' Регион union all
	select 'Липецкая обл.' РегионДляПоиская, 'Липецкая' Регион union all
	select 'Магаданская обл' РегионДляПоиская, 'Магаданская' Регион union all
	select 'Марий Эл Респ' РегионДляПоиская, 'Марий Эл' Регион union all
	select 'Мордовия Респ' РегионДляПоиская, 'Мордовия' Регион union all
	select 'Москва г' РегионДляПоиская, 'Москва' Регион union all
	select 'Московская обл' РегионДляПоиская, 'Московская' Регион union all
	select 'Московская область' РегионДляПоиская, 'Московская' Регион union all
	select 'Мурманская обл' РегионДляПоиская, 'Мурманская' Регион union all
	select 'Ненецкий АО' РегионДляПоиская, 'Ненецкий' Регион union all
	select 'Нижегородская обл' РегионДляПоиская, 'Нижегородская' Регион union all
	select 'Новгородская обл' РегионДляПоиская, 'Новгородская' Регион union all
	select 'Новосибирская обл' РегионДляПоиская, 'Новосибирская' Регион union all
	select 'Омская обл' РегионДляПоиская, 'Омская' Регион union all
	select 'Оренбургская обл' РегионДляПоиская, 'Оренбургская' Регион union all
	select 'Оренбурская обл' РегионДляПоиская, 'Оренбургская' Регион union all
	select 'Орловская обл' РегионДляПоиская, 'Орловская' Регион union all
	select 'ПЕНЗЕНСКАЯ' РегионДляПоиская, 'Пензенская' Регион union all
	select 'Пензенская обл' РегионДляПоиская, 'Пензенская' Регион union all
	select 'Пермский край' РегионДляПоиская, 'Пермский' Регион union all
	select 'Приморский край' РегионДляПоиская, 'Приморский' Регион union all
	select 'Псковская обл' РегионДляПоиская, 'Псковская' Регион union all
	select 'Псковская область' РегионДляПоиская, 'Псковская' Регион union all
	select 'респ Башкортостан' РегионДляПоиская, 'Башкортостан' Регион union all
	select 'респ Коми' РегионДляПоиская, 'Коми' Регион union all
	select 'Ростовская обл' РегионДляПоиская, 'Ростовская' Регион union all
	select 'Рязанская обл' РегионДляПоиская, 'Рязанская' Регион union all
	select 'Самарская обл' РегионДляПоиская, 'Самарская' Регион union all
	select 'Санкт-Петербург г' РегионДляПоиская, 'Санкт-Петербург' Регион union all
	select 'Саратовская обл' РегионДляПоиская, 'Саратовская' Регион union all
	select 'Саратовская обл.' РегионДляПоиская, 'Саратовская' Регион union all
	select 'Саратовскую область' РегионДляПоиская, 'Саратовская' Регион union all
	select 'Саха /Якутия/ Респ' РегионДляПоиская, 'Якутия' Регион union all
	select 'Сахалинская обл' РегионДляПоиская, 'Сахалинская' Регион union all
	select 'Свердловская обл' РегионДляПоиская, 'Свердловская' Регион union all
	select 'Севастополь г' РегионДляПоиская, 'Севастополь' Регион union all
	select 'Северная Осетия - Алания Респ' РегионДляПоиская, 'Северная Осетия' Регион union all
	select 'Смоленская обл' РегионДляПоиская, 'Смоленская' Регион union all
	select 'Ставропольский край' РегионДляПоиская, 'Ставропольский' Регион union all
	select 'Тамбовская обл' РегионДляПоиская, 'Тамбовская' Регион union all
	select 'Татарстан Респ' РегионДляПоиская, 'Татарстан' Регион union all
	select 'Тверская обл' РегионДляПоиская, 'Тверская' Регион union all
	select 'Томская обл' РегионДляПоиская, 'Томская' Регион union all
	select 'Тульская обл' РегионДляПоиская, 'Тульская' Регион union all
	select 'Тыва Респ' РегионДляПоиская, 'Тыва' Регион union all
	select 'Тюменская обл' РегионДляПоиская, 'Тюменская' Регион union all
	select 'Удмуртская Респ' РегионДляПоиская, 'Удмуртская' Регион union all
	select 'Ульяновская обл' РегионДляПоиская, 'Ульяновская' Регион union all
	select 'Хабаровский край' РегионДляПоиская, 'Хабаровский' Регион union all
	select 'Хакасия Респ' РегионДляПоиская, 'Хакасия' Регион union all
	select 'Ханты Мансийский АО' РегионДляПоиская, 'Ханты-Мансийский' Регион union all
	select 'Ханты-Мансийский Автономный округ - Югра АО' РегионДляПоиская, 'Ханты-Мансийский' Регион union all
	select 'Челябинская обл' РегионДляПоиская, 'Челябинская' Регион union all
	select 'Чеченская Респ' РегионДляПоиская, 'Чеченская' Регион union all
	select 'Чувашская Республика - Чувашия' РегионДляПоиская, 'Чувашская' Регион union all
	select 'Чукотский АО' РегионДляПоиская, 'Чукотский' Регион union all
	select 'Ямало-Ненецкий АО' РегионДляПоиская, 'Ямало-Ненецкий' Регион union all
	select 'Ярославская обл' РегионДляПоиская, 'Ярославская' Регион --union all





	drop table if exists #t1, #fa, #v_dm_factor_analysis_001_channels, #v_dm_place_of_creation_2


	drop table if exists #fa
	select 
	Номер,
	Дубль,
	[Канал от источника],
	[Группа каналов],
	ДатаЗаявкиПолная,
	[Вид займа],
	[Место cоздания],
	[Место создания 2],
	Партнер,
	[Верификация КЦ], 
	[Предварительное одобрение], 
	[Встреча назначена], 
	[Контроль данных], 
	[Верификация документов клиента], 
	[Одобрены документы клиента],
	[Верификация документов], 
	[Одобрено],
	Отказано,
	[Отказ документов клиента],
	[Отказ клиента],
	Аннулировано,
	[Заем аннулирован],
	Забраковано,
	[Договор зарегистрирован],
	[Договор подписан],
	[Заем выдан],
	[Заем погашен],
	[Выданная сумма],
	[Сумма одобренная],
	[Первичная сумма],
	[Сумма заявки],
	[Регион проживания],
	[Дата отчета],
	[Ссылка заявка],
	[Ссылка клиент],
	ФИО,
	Телефон,
	[Причина отказа],
	isInstallment,
	isSmartInstallment,
	isPts,
	isPdl,
	[Признак Коробочный Продукт] ПризнакКП,
	[Признак Страховка] ПризнакСтраховка,
	[Сумма Дополнительных Услуг Carmoney Net] СуммаДопУслугCarmoneyNet,
	[Сумма Дополнительных Услуг Carmoney] СуммаДопУслугCarmoney,
	[Сумма Дополнительных Услуг] СуммаДопУслуг,
	[Признак Каско] ПризнакКаско,
	[Признак Страхование Жизни] ПризнакСтрахованиеЖизни,
	[Признак РАТ] ПризнакРАТ,

	[Признак Помощь Бизнесу]  ПризнакПомощьБизнесу,
	[Признак Телемедицина]  ПризнакТелемедицина, 
	[Признак Защита от потери работы]  [Признак Защита от потери работы],
	[Признак Фарма]  ПризнакФарма,
	[Признак Спокойная Жизнь]  ПризнакСпокойнаяЖизнь,
	[Признак РАТ Юруслуги] [Признак РАТ Юруслуги],
	 [Сумма КАСКО] [SumKasko],
	 [Сумма КАСКО Carmoney] [SumKaskoCarmoney],
	 [Сумма КАСКО Carmoney Net] [SumKaskoCarmoneyNet],
	 [Сумма страхование жизни] [SumEnsur],
	 [Сумма страхование жизни Carmoney] [SumEnsurCarmoney],
	 [Сумма страхование жизни Carmoney Net] [SumEnsurCarmoneyNet],
	 [Сумма РАТ] [SumRat],
	 [Сумма РАТ Carmoney] [SumRatCarmoney],
	 [Сумма РАТ Carmoney Net] [SumRatCarmoneyNet],
	 -- [SumPositiveMood],
	 -- [SumPositiveMoodCarmoney],
	 --agr.[SumPositiveMoodCarmoneyNet],
	 [Сумма Помощь бизнесу] [SumHelpBusiness],
	 [Сумма Помощь бизнесу Carmoney] [SumHelpBusinessCarmoney],
	 [Сумма Помощь бизнесу Carmoney Net] [SumHelpBusinessCarmoneyNet],
	 [Сумма Телемедицина] [SumTeleMedic],
	 [Сумма Телемедицина Carmoney] [SumTeleMedicCarmoney],
	 [Сумма Телемедицина Carmoney Net] [SumTeleMedicCarmoneyNet],
	 [Сумма Защита от потери работы] [SumCushion],
	 [Сумма Защита от потери работы Carmoney] [SumCushionCarmoney],
	 [Сумма Защита от потери работы Carmoney Net] [SumCushionCarmoneyNet],
	 [Сумма Фарма] [SumPharma],
	 [Сумма Фарма Carmoney] [SumPharmaCarmoney],
	 [Сумма Фарма Carmoney Net] [SumPharmaCarmoneyNet],
	 [Сумма Спокойная Жизнь] SumQuietLife,
	 [Сумма Спокойная Жизнь Carmoney] SumQuietLifeCarmoney,
	 [Сумма Спокойная Жизнь Carmoney Net] SumQuietLifeCarmoneyNet,
	[Сумма РАТ Юруслуги],
	[Сумма РАТ Юруслуги Carmoney],
	[Сумма РАТ Юруслуги Carmoney Net],
	 [Срок займа] Срок,
	 [Процентная ставка] ПроцСтавкаКредит,
	 [Признак Рефинансирование]
	 , [офис ссылка]
	 , РП
	 , РО_регион
	 , Источник
	 , [Тип трафика]
	into #fa from dbo.dm_Factor_Analysis_001


--	drop table if exists #dm_FillingTypeChangesInRequests
--	select [Номер заявки]
--		  ,[Дата изменения]
--		  ,[Статус]
--		  ,[Вид заполнения]   into #dm_FillingTypeChangesInRequests 
--
--	FROM [dbo].[dm_FillingTypeChangesInRequests] s1

	--create clustered index номер_cl_index  on #fa
	--(Номер desc)
	;

	--
	--with v as (
	--
	-- SELECT [Номер]
	--,b.[Группа каналов]
	--,b.[Канал от источника]
	--,[ПризнакОформленияНовойЗаявки]
	--,ROW_NUMBER() over(partition by [ПризнакОформленияНовойЗаявки] order by [Номер]) rn
	--
	--FROM [Stg].[_1cMFO].[Отчет_ВсеЗаявкиДляАналитика] a
	--left join stg.[_LCRM].[lcrm_tbl_short_w_channel] b on a.Номер=b.UF_ROW_ID
	--where isnumeric([ПризнакОформленияНовойЗаявки])=1 
	--
	--)
	--


	-- select 
	-- a.Номер
	--, isnull(true_chanel.[Канал от источника], a.[Канал от источника]) [Канал от источника]
	--, isnull(true_chanel.[Группа каналов], a.[Группа каналов]) [Группа каналов]
	--into #v_dm_factor_analysis_001_channels
	--from #fa a
	--left join v true_chanel on true_chanel.ПризнакОформленияНовойЗаявки=a.Номер and rn=1
	--
	--;
	--


--	SELECT 
--	f1.Номер
--	,ДатаЗаявкиПолная,
--
--	iif (f1.[Место cоздания]='Оформление в мобильном приложении' or s5.[Вид заполнения]='Заполняется в мобильном приложении' or 
--	f1.[Место cоздания]='Оформление на клиентском сайте' ,'МП'
--	,iif (f1.[Место cоздания]='Ввод операторами КЦ' or f1.[Место cоздания]='Ввод операторами LCRM' or f1.[Место cоздания]='Ввод операторами FEDOR' or f1.[Место cоздания]='Ввод операторами стороннего КЦ','КЦ'
--	,iif (f1.[Место cоздания]='Оформление на партнерском сайте','Партнеры',f1.[Место cоздания]))) as 'Место_создания_2'
--
--	into #v_dm_place_of_creation_2
--	FROM
--	(
--	SELECT *
--	FROM
--	(
--	SELECT 
--
--		   a0.[Номер]
--		  ,a0.[Место cоздания] as 'Место cоздания'
--		  ,ДатаЗаявкиПолная
--      
--	  FROM #fa a0
--  
-- 
--	) as c1
--
--	) as f1
--
--	left join
--	(
--	SELECT
--	 [Номер заявки]
--	,[Вид заполнения]
--	FROM
--	(
--	SELECT *
--	,ROW_NUMBER () over (partition by [Номер заявки] order by [Дата изменения] DESC) as RN
--	FROM
--	(
--	SELECT
--	[Номер заявки]
--	,iif (Статус='Контроль данных' or DATEDIFF (mi,dateadd(year,-2000,[Дата изменения]),[Контроль данных])>=0 or [Контроль данных] is null,1,null) 'Флаг'
--	,[Вид заполнения]
--	,[Дата изменения]
--	,[Контроль данных]
--	,DATEDIFF (mi,dateadd(year,-2000,[Дата изменения]),[Контроль данных]) RN1
--	,Статус
--	FROM #dm_FillingTypeChangesInRequests s1
--	left join #fa s2  
--	on s1.[Номер заявки]=s2.Номер
--	) s3
--	where Флаг=1
--	) s4
--	where RN = 1
--	) 
--	as s5
--	on f1.Номер=s5.[Номер заявки]


	drop table if exists #precheckers
	select  request_code, isnull(sum(manual_check),0) ЧислоРучныхПроверокПредчекерами, isnull(sum(case when mark=0 then manual_check end), 0) ЧислоДоработокПредЧекеры  into #precheckers 
	from stg._lk.precheck_action 
	where manual_check=1 
	group by request_code

	drop table if exists #requests_steps
	;

	with request_steps as (	
	select request_id      request_id	
	,      event_id        event_id	
	,      min(created_at) min_created_at	
	from stg.[_LK].[requests_events]--	with(nolock)  --select * from openquery(lkprod, 'select * from events')
	where event_id between 24 and 45
	group by request_id	
	,        event_id	
	
	 )	
	--select distinct 'left join request_steps a'+id+' on a.request_id=a'+id+'.request_id and a'+id+'.event_id='+id
	--, ',a'+id+'.min_created_at as ['+name+']'
	--from 	
	--(
	--select cast(id as nvarchar(4000)) id, name
	--from openquery(lkprod, 'select * from events where id between 33 and 45')
	--) x
	--order by 1

	 select 
	 a.request_id
	 ,a24.min_created_at as [Переход в МП с шага 1 на 2 шаг]	
	 ,a25.min_created_at as [Переход в МП с шага 2 на 2.5 шаг (ПЭП)]	
	 ,a26.min_created_at as [Переход в МП с шага 3 на 4 шаг]	
	 ,a27.min_created_at as [Переход в МП с шага 4 на 5 шаг]	
	 ,a28.min_created_at as [Переход в МП с шага 5 на 6 шаг]	
	 ,a29.min_created_at as [Переход в МП с шага 6 на 7 шаг]	
	 ,a30.min_created_at as [Переход в МП с шага 7 на 8 шаг]	
	 ,a31.min_created_at as [Переход в МП с шага 8 на 9 шаг]	
	 ,a32.min_created_at as [Переход в МП с шага 9 на сводную информацию по заявке]	

	,cast(a33.min_created_at as datetime2) as [Переход в МП с основного калькулятора на калькулятор ПТС]
	,cast(a34.min_created_at as datetime2) as [Переход в МП с основного калькулятора на шаг короткой анкеты Installment]
	,cast(a35.min_created_at as datetime2) as [Переход в МП с шага короткой анкеты на шаг первого пакета док-ов]
	,cast(a36.min_created_at as datetime2) as [Переход в МП с шага подписания пакета документов на шаг заполнения полной анкеты 1]
	,cast(a37.min_created_at as datetime2) as [Переход в МП с шага заполнения полной анкеты 1 на шаг заполнения полной анкеты 2]
	,cast(a38.min_created_at as datetime2) as [Переход в МП с шага заполнения полной анкеты 2 на шаг заполнения полной анкеты 3]
	,cast(a39.min_created_at as datetime2) as [Переход в МП с шага заполнения полной анкеты 3 на шаг заполнения полной анкеты 4]
	,cast(a40.min_created_at as datetime2) as [Переход в МП с шага заполнения полной анкеты 4 на шаг заполнения полной анкеты 5]
	,cast(a41.min_created_at as datetime2) as [Переход в МП с шага заполнения полной анкеты 5 на шаг способ получения ДС]
	,cast(a42.min_created_at as datetime2) as [Переход в МП с шага ожидания одобрения на шаг выбор предложения]
	,cast(a43.min_created_at as datetime2) as [Переход в МП с шага выбор предложения на шаг подписания 2-го пакета док-тов]
	,cast(a44.min_created_at as datetime2) as [Переход в МП с шага подписания 2-го пакета документов на шаг ожидания дс]
	,cast(a45.min_created_at as datetime2) as [Запрос подписания данных для проверки карты SDK]

	 ,isnull(isnull(isnull(isnull(isnull(isnull(isnull(isnull(a24.min_created_at, a25.min_created_at), a26.min_created_at),a27.min_created_at), a28.min_created_at), a29.min_created_at), a30.min_created_at), a31.min_created_at), a32.min_created_at) as [Переход в МП с шага 1 на 2 шаг_аналитический]	
	 ,isnull(isnull(isnull(isnull(isnull(isnull(isnull( a25.min_created_at, a26.min_created_at),a27.min_created_at), a28.min_created_at), a29.min_created_at), a30.min_created_at), a31.min_created_at), a32.min_created_at) as [Переход в МП с шага 2 на 2.5 шаг (ПЭП)_аналитический]	
	 ,isnull(isnull(isnull(isnull(isnull(isnull( a26.min_created_at,a27.min_created_at), a28.min_created_at), a29.min_created_at), a30.min_created_at), a31.min_created_at), a32.min_created_at) as [Переход в МП с шага 3 на 4 шаг_аналитический]	
	 ,isnull(isnull(isnull(isnull(isnull(a27.min_created_at, a28.min_created_at), a29.min_created_at), a30.min_created_at), a31.min_created_at), a32.min_created_at) as [Переход в МП с шага 4 на 5 шаг_аналитический]	
	 ,isnull(isnull(isnull(isnull( a28.min_created_at, a29.min_created_at), a30.min_created_at), a31.min_created_at), a32.min_created_at) as [Переход в МП с шага 5 на 6 шаг_аналитический]	
	 ,isnull(isnull(isnull(a29.min_created_at, a30.min_created_at), a31.min_created_at), a32.min_created_at) as [Переход в МП с шага 6 на 7 шаг_аналитический]	
	 ,isnull(isnull(a30.min_created_at, a31.min_created_at), a32.min_created_at) as [Переход в МП с шага 7 на 8 шаг_аналитический]	
	 ,isnull(a31.min_created_at, a32.min_created_at) as [Переход в МП с шага 8 на 9 шаг_аналитический]	
	 ,a32.min_created_at as [Переход в МП с шага 9 на сводную информацию по заявке_аналитический]	
	
	
 	
	 into #requests_steps	
	  from (select distinct request_id from 	request_steps) a

	 left join request_steps a24 on a.request_id=a24.request_id and a24.event_id=24	
	 left join request_steps a25 on a.request_id=a25.request_id and a25.event_id=25	
	 left join request_steps a26 on a.request_id=a26.request_id and a26.event_id=26	
	 left join request_steps a27 on a.request_id=a27.request_id and a27.event_id=27	
	 left join request_steps a28 on a.request_id=a28.request_id and a28.event_id=28	
	 left join request_steps a29 on a.request_id=a29.request_id and a29.event_id=29	
	 left join request_steps a30 on a.request_id=a30.request_id and a30.event_id=30	
	 left join request_steps a31 on a.request_id=a31.request_id and a31.event_id=31	
	 left join request_steps a32 on a.request_id=a32.request_id and a32.event_id=32	

	left join request_steps a33 on a.request_id=a33.request_id and a33.event_id=33
	left join request_steps a34 on a.request_id=a34.request_id and a34.event_id=34
	left join request_steps a35 on a.request_id=a35.request_id and a35.event_id=35
	left join request_steps a36 on a.request_id=a36.request_id and a36.event_id=36
	left join request_steps a37 on a.request_id=a37.request_id and a37.event_id=37
	left join request_steps a38 on a.request_id=a38.request_id and a38.event_id=38
	left join request_steps a39 on a.request_id=a39.request_id and a39.event_id=39
	left join request_steps a40 on a.request_id=a40.request_id and a40.event_id=40
	left join request_steps a41 on a.request_id=a41.request_id and a41.event_id=41
	left join request_steps a42 on a.request_id=a42.request_id and a42.event_id=42
	left join request_steps a43 on a.request_id=a43.request_id and a43.event_id=43
	left join request_steps a44 on a.request_id=a44.request_id and a44.event_id=44
	left join request_steps a45 on a.request_id=a45.request_id and a45.event_id=45

	drop table if exists #lk

	
		select id, num_1c, code, client_id , created_at
		into #lk from stg._LK.requests-- with(nolock)


	drop table if exists #os_on_user
	SELECT 
		  u.id
		  ,min(left(reg.os, charindex (' ', reg.os)-1)) user_os
		 into #os_on_user
	  FROM stg.[_LK].users u
	  join stg.[_LK].[register_mp] reg on reg.user_id=u.id
	  group by 
	  u.id

	drop table if exists #os_on_request

	SELECT request_id, case 
	when [service_info] like 'android%' then 'Android'
	when [service_info] like 'ios%' then 'iOS'
	end request_os
		 into #os_on_request
    
	  FROM [Stg].[_LK].[request_mp]


	  drop table if exists #core_ClientRequest
	  select Number collate Cyrillic_General_CI_AS Number, AprRecommended, PercentApproved into #core_ClientRequest from stg._fedor.core_ClientRequest

	--  select * from #core_ClientRequest

	--select ДоговорНомер
	--,      ДатаВыдачи
	--,      СуммаВыдачи
	--,      СуммаДопУслуг
	--,      ПризнакКП
	--,      ПризнакКаско
	--,      ПризнакСтрахованиеЖизни
	--,      ПризнакРАТ
	--,      ПризнакПозитивНастр
	--,      ПризнакПомощьБизнесу
	--,      ПризнакТелемедицина
	--,      [Признак Защита от потери работы]
	--,      [SumKasko]
	--,      [SumEnsur]
	--,      [SumRat]
	--,      [SumPositiveMood]
	--,      [SumHelpBusiness]
	--,      [SumTeleMedic]
	--,      [SumCushion] 
	--,      ПроцСтавкаКредит 
	--,      ПоследняяПроцСтавкаДо14Дней 
	--
	--into #agr
	--from dbo.report_Agreement_InterestRate

	/*
	--------------------------------------
	--------------------------------------
	--------------------------------------


	drop table if exists #dm_sales

	select 
	  код
	, [SumKasko]        =                               nullif(cast(КАСКО                                                                                                                                                         as float) ,0)   
	, [SumEnsur]        =                               nullif(cast([Страхование жизни]																																			  as float) ,0)
	, [SumRat]          =                               nullif(cast(РАТ+		[РАТ 2.0]																																					  as float) ,0)
	, [SumPositiveMood] =                               nullif(cast(null																																						  as float) ,0)
	, [SumHelpBusiness] =                               nullif(cast([Помощь бизнесу]																																			  as float) ,0)
	, [SumTeleMedic]    =                               nullif(cast(телемедицина																																				  as float) ,0)
	, [SumCushion]      =                               nullif(cast([Защита от потери работы]+[От потери работы. «Максимум»]+[От потери работы. «Стандарт»]																		  as float) ,0)
	, [SumPharma]       =                               nullif(cast([Фарм страхование]																																			  as float) ,0)
	, SumQuietLife      =                               nullif(cast([Спокойная жизнь]																																			  as float) ,0)
	, [SumKaskoCarmoney]        =                       nullif(cast(КАСКО_without_partner_bounty																																  as float) ,0)
	, [SumEnsurCarmoney]        =                       nullif(cast([Страхование жизни_without_partner_bounty]																													  as float) ,0)
	, [SumRatCarmoney]          =                       nullif(cast(РАТ_without_partner_bounty + 	[РАТ 2.0_without_partner_bounty]																																  as float) ,0)
	, [SumPositiveMoodCarmoney] =                       nullif(cast(null																																						  as float) ,0)
	, [SumHelpBusinessCarmoney] =                       nullif(cast([Помощь бизнесу_without_partner_bounty]																														  as float) ,0)
	, [SumTeleMedicCarmoney]    =                       nullif(cast(Телемедицина_without_partner_bounty																															  as float) ,0)
	, [SumCushionCarmoney]      =                       nullif(cast([Защита от потери работы_without_partner_bounty]+[От потери работы. «Максимум»_without_partner_bounty]+[От потери работы. «Стандарт»_without_partner_bounty]  as float) ,0)
	, [SumPharmaCarmoney]       =                       nullif(cast([Фарм страхование_without_partner_bounty]																													  as float) ,0)
	, SumQuietLifeCarmoney      =                       nullif(cast([Спокойная жизнь_without_partner_bounty]																													  as float) ,0)
	, [SumKaskoCarmoneyNet]        =                    nullif(cast([КАСКО NET]																																					  as float) ,0)
	, [SumEnsurCarmoneyNet]        =                    nullif(cast([Страхование жизни NET]																																		  as float) ,0)
	, [SumRatCarmoneyNet]          =                    nullif(cast([РАТ NET]			+ 		[РАТ 2.0 NET]																																  as float) ,0)
	, [SumPositiveMoodCarmoneyNet] =                    nullif(cast(null																																						  as float) ,0)
	, [SumHelpBusinessCarmoneyNet] =                    nullif(cast([Помощь бизнесу NET]																																		  as float) ,0)
	, [SumTeleMedicCarmoneyNet]    =                    nullif(cast([Телемедицина NET]																																			  as float) ,0)
	, [SumCushionCarmoneyNet]      =                    nullif(cast([Защита от потери работы NET]+[От потери работы. «Максимум» NET]+[От потери работы. «Стандарт» NET]															  as float) ,0)
	, [SumPharmaCarmoneyNet]       =                    nullif(cast([Фарм страхование NET]																																		  as float) ,0)
	, [SumQuietLifeCarmoneyNet]          =              nullif(cast([Спокойная жизнь NET]																																		  as float) ,0)
	into #dm_sales
	from dbo.dm_Sales
	 where ishistory=0


	drop table if exists #d
	select d.Код                                     
	,      d.Ссылка                                  
	,      d.Сумма СуммаВыдачи                                  
	,      dateadd(year, -2000, vds.ДатаВыдачи) ДатаВыдачи                                  
	,      dateadd(year, -2000, cast(d.Дата as date)) ДатаДоговора
	,      СуммаДопПродуктов     
	,      Срок     

	into #d
	from stg._1ccmr.[Справочник_Договоры]          d  
	left join stg._1cCMR.Документ_ВыдачаДенежныхСредств vds on d.Ссылка=vds.Договор and vds.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F --Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
	and vds.Проведен=1
	and vds.ПометкаУдаления=0



	drop table if exists #current_percent
	; with r as (select pd.Договор 
					  , max(Период) max_p
				   from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
				   join #d d on  d.Ссылка=pd.Договор
				  group by  pd.Договор--,Код
				)
		select pd.договор
			 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПроцСтавкаКредит
		  into #current_percent
		  from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
		  join r on r.Договор=pd. Договор and r.max_p=pd.Период


	drop table if exists #percent_14days
	;with r as (select pd.Договор 
					  , max(Период) max_p
				   from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
				   join #d d on  d.Ссылка=pd.Договор and cast(dateadd(year, -2000, pd.Период) as date) between cast(d.ДатаДоговора as date) and dateadd(day, 13,cast( d.ДатаДоговора as date))
				  group by  pd.Договор--,Код
				)
		select pd.договор
			 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПоследняяПроцСтавкаДо14Дней
		  into #percent_14days
		  from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
		  join r on r.Договор=pd. Договор and r.max_p=pd.Период

	--
	--
	--
	--drop table if exists #dp
	--select d.Ссылка
	--,      dd.Сумма  Сумма
	--,      
	--       case when spdd.Код='000000001' then dd.Сумма*0.95 --Страхование жизни
	--            when spdd.Код='000000002' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210531' then 0.75 --Рат
	--                                                         when ДатаДоговора >= '20210601'  then 0.81 --Рат
	--												    end
	--            when spdd.Код='000000003' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210304' then 0.86 --Каско
	--                                                         when ДатаДоговора >= '20210305' then 0.9                      --Каско
	--												    end
	--			when spdd.Код='000000004' then dd.Сумма*0.8 --От потери работы. «Максимум»
	--			when spdd.Код='000000005' then dd.Сумма*0.75 --От потери работы. «Стандарт»
	--			when spdd.Код='000000006' then dd.Сумма*0.73 --Помощь бизнесу
	--			when spdd.Код='000000007' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210304' then 0.86 --Каско
	--                                                         when ДатаДоговора >= '20210305' then 0.9                      --Каско
	--												    end
	--			when spdd.Код='000000008' then dd.Сумма*0.95 --Страхование жизни
	--			when spdd.Код='000000009' then dd.Сумма*0.67 --Телемедицина
	--			when spdd.Код='000000010' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210322' then 0.4 --Защита от потери работы
	--			                                             when ДатаДоговора between '20210323' and '20210531' then 0.75 --Защита от потери работы
	--			                                             when ДатаДоговора between '20190601' and '20210630' then 0.67 --Защита от потери работы
	--                                                         when ДатаДоговора >= '20210323' then 0.75                      --Защита от потери работы
	--												    end
	--			when spdd.Код='000000011' then dd.Сумма*case when ДатаДоговора >='20211119' then (1-0.625) else (1-0.5) end  --Фарм страхование
	--			when spdd.Код='000000012' then dd.Сумма-1650  --спокойная жизнь
	--
	--		end as 
	--		
	--		СуммаCarmoney
	--,      spdd.Наименование
	--,      spdd.Код
	--,      d.ДатаДоговора
	--
	--into #dp
	--from      #d                                                      d   
	--join      stg._1ccmr.[Справочник_Договоры_ДополнительныеПродукты] dd   on dd.ссылка=d.ссылка
	--join  stg._1ccmr.[Справочник_ДополнительныеПродукты]          spdd on spdd.ссылка=dd.ДополнительныйПродукт and spdd.код not in ('000000013','000000014','000000015')

	--select [Дата выдачи],* from stg._1ccmr.[Справочник_Договоры_ДополнительныеПродукты] a
	--join  stg._1ccmr.[Справочник_ДополнительныеПродукты]    b on a.ДополнительныйПродукт=b.Ссылка and b.Код='000000014'
	--join Analytics.dbo.mv_loans c on c.[Ссылка договор CMR]=a.Ссылка
	--order by 1
	--select * from #dp
	--where ссылка=0xA2CC005056839FE911EBE3C9912A8E65
	--	order by СуммаCarmoney ,1


		--select * from stg._1ccmr.[Справочник_ДополнительныеПродукты]
		--order by Код


		--select * from prodsql02.cmr.dbo.[Справочник_ДополнительныеПродукты]
		--order by Код
		drop table if exists #agr


		;

		with v as (
		select d.Код 
		, d.ДатаДоговора
		, d.ДатаВыдачи
		, d.Срок
		, d.СуммаВыдачи
		, current_percent.ПроцСтавкаКредит
		, percent_14days.ПоследняяПроцСтавкаДо14Дней
		, [SumKasko]                     [SumKasko]                                
		, [SumEnsur]                     [SumEnsur]                    
		, [SumRat]                       [SumRat]                      
		, [SumPositiveMood]              [SumPositiveMood]             
		, [SumHelpBusiness]              [SumHelpBusiness]             
		, [SumTeleMedic]                 [SumTeleMedic]                
		, [SumCushion]                   [SumCushion]                  
		, [SumPharma]                    [SumPharma]                   
		, SumQuietLife                   SumQuietLife                  
		, [SumKaskoCarmoney]             [SumKaskoCarmoney]            
		, [SumEnsurCarmoney]             [SumEnsurCarmoney]            
		, [SumRatCarmoney]               [SumRatCarmoney]              
		, [SumPositiveMoodCarmoney]      [SumPositiveMoodCarmoney]     
		, [SumHelpBusinessCarmoney]      [SumHelpBusinessCarmoney]     
		, [SumTeleMedicCarmoney]         [SumTeleMedicCarmoney]        
		, [SumCushionCarmoney]           [SumCushionCarmoney]          
		, [SumPharmaCarmoney]            [SumPharmaCarmoney]           
		, SumQuietLifeCarmoney           SumQuietLifeCarmoney          
		, [SumKaskoCarmoneyNet]          [SumKaskoCarmoneyNet]         
		, [SumEnsurCarmoneyNet]          [SumEnsurCarmoneyNet]         
		, [SumRatCarmoneyNet]            [SumRatCarmoneyNet]           
		, [SumPositiveMoodCarmoneyNet]   [SumPositiveMoodCarmoneyNet]  
		, [SumHelpBusinessCarmoneyNet]   [SumHelpBusinessCarmoneyNet]  
		, [SumTeleMedicCarmoneyNet]      [SumTeleMedicCarmoneyNet]     
		, [SumCushionCarmoneyNet]        [SumCushionCarmoneyNet]       
		, [SumPharmaCarmoneyNet]         [SumPharmaCarmoneyNet]        
		, [SumQuietLifeCarmoneyNet]      [SumQuietLifeCarmoneyNet]     
		--,cast( nullif(isnull([dp_000000007].Сумма, 0) + isnull([dp_000000003].Сумма , 0), 0)                                    as float) [SumKasko]
		--,cast( nullif(isnull([dp_000000001].Сумма, 0) + isnull([dp_000000008].Сумма , 0), 0)                                    as float) [SumEnsur]
		--,cast( [dp_000000002].Сумма                                                                                             as float) [SumRat]
		--,cast( null                                                                                                             as float) [SumPositiveMood]
		--,cast( [dp_000000006].Сумма                                                                                             as float) [SumHelpBusiness]
		--,cast( [dp_000000009].Сумма                                                                                             as float) [SumTeleMedic]
		--,cast( nullif(isnull([dp_000000004].Сумма, 0) + isnull([dp_000000005].Сумма , 0) + isnull([dp_000000010].Сумма , 0), 0) as float) [SumCushion]
		--,cast( [dp_000000011].Сумма                                                                                             as float) [SumPharma]
		--,cast( [dp_000000012].Сумма                                                                                             as float) [SumQuietLife]
		--
	   ------------------------
	   ------------------------
	   ------------------------
		--,cast( nullif(isnull([dp_000000007].СуммаCarmoney, 0) + isnull([dp_000000003].СуммаCarmoney , 0), 0)                                            as float) [SumKaskoCarmoney]
		--,cast( nullif(isnull([dp_000000007].СуммаCarmoney, 0) + isnull([dp_000000003].СуммаCarmoney , 0), 0)                                            as float)*case when d.ДатаДоговора>='20210201' then 1 else (1-0.2/1.2) end - case when d.ДатаДоговора>='20210201' then cast( nullif(isnull([dp_000000007].Сумма, 0) + isnull([dp_000000003].Сумма , 0), 0) as float)-cast( nullif(isnull([dp_000000007].СуммаCarmoney, 0) + isnull([dp_000000003].СуммаCarmoney , 0), 0) as float) else 0 end*(1/6.0)  [SumKaskoCarmoneyNet]
		--,cast( nullif(isnull([dp_000000001].СуммаCarmoney, 0) + isnull([dp_000000008].СуммаCarmoney , 0), 0)                                            as float) [SumEnsurCarmoney]
		--,cast( nullif(isnull([dp_000000001].СуммаCarmoney, 0) + isnull([dp_000000008].СуммаCarmoney , 0), 0)                                            as float)*case when d.ДатаДоговора>='20210201' then 1 else (1-0.2/1.2) end - case when d.ДатаДоговора>='20210201' then cast( nullif(isnull([dp_000000001].Сумма, 0) + isnull([dp_000000008].Сумма , 0), 0) as float)-cast( nullif(isnull([dp_000000001].СуммаCarmoney, 0) + isnull([dp_000000008].СуммаCarmoney , 0), 0) as float) else 0 end*(1/6.0)  [SumEnsurCarmoneyNet]
		--,cast( [dp_000000002].СуммаCarmoney                                                                                                             as float) [SumRatCarmoney]
		--,cast( [dp_000000002].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumRatCarmoneyNet]
		--,cast( null                                                                                                                                     as float) [SumPositiveMoodCarmoney]
		--,cast( [dp_000000006].СуммаCarmoney                                                                                                             as float) [SumHelpBusinessCarmoney]
		--,cast( [dp_000000006].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumHelpBusinessCarmoneyNet]
		--,cast( [dp_000000009].СуммаCarmoney                                                                                                             as float) [SumTeleMedicCarmoney]
		--,cast( [dp_000000009].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumTeleMedicCarmoneyNet]
		--,cast( nullif(isnull([dp_000000004].СуммаCarmoney, 0) + isnull([dp_000000005].СуммаCarmoney , 0) + isnull([dp_000000010].СуммаCarmoney , 0), 0) as float) [SumCushionCarmoney]
		--,cast( nullif(isnull([dp_000000004].СуммаCarmoney, 0) + isnull([dp_000000005].СуммаCarmoney , 0) + isnull([dp_000000010].СуммаCarmoney , 0), 0) as float)*(1-0.2/1.2) [SumCushionCarmoneyNet]
		--,cast( [dp_000000011].СуммаCarmoney                                                                                                             as float) [SumPharmaCarmoney]
		--,cast( [dp_000000011].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumPharmaCarmoneyNet]
		--,cast( [dp_000000012].СуммаCarmoney                                                                                                             as float) [SumQuietLifeCarmoney]
		--,cast( [dp_000000012].СуммаCarmoney                                                                                                             as float)*case when d.ДатаДоговора>='20210201' then 1 else (1-0.2/1.2) end - case when d.ДатаДоговора>='20210201' then cast( [dp_000000012].Сумма as float)-cast( [dp_000000012].СуммаCarmoney as float) else 0 end*(1/6.0) [SumQuietLifeCarmoneyNet]

	
		from #d d
		--left join #dp [dp_000000001] on [dp_000000001].Ссылка=d.Ссылка and [dp_000000001].Код='000000001' --Страхование жизни
		--left join #dp [dp_000000002] on [dp_000000002].Ссылка=d.Ссылка and [dp_000000002].Код='000000002' --РАТ
		--left join #dp [dp_000000003] on [dp_000000003].Ссылка=d.Ссылка and [dp_000000003].Код='000000003' --КАСКО
		--left join #dp [dp_000000004] on [dp_000000004].Ссылка=d.Ссылка and [dp_000000004].Код='000000004' --От потери работы. «Максимум»
		--left join #dp [dp_000000005] on [dp_000000005].Ссылка=d.Ссылка and [dp_000000005].Код='000000005' --От потери работы. «Стандарт»
		--left join #dp [dp_000000006] on [dp_000000006].Ссылка=d.Ссылка and [dp_000000006].Код='000000006' --Помощь бизнесу
		--left join #dp [dp_000000007] on [dp_000000007].Ссылка=d.Ссылка and [dp_000000007].Код='000000007' --КАСКО
		--left join #dp [dp_000000008] on [dp_000000008].Ссылка=d.Ссылка and [dp_000000008].Код='000000008' --Страхование жизни
		--left join #dp [dp_000000009] on [dp_000000009].Ссылка=d.Ссылка and [dp_000000009].Код='000000009' --Телемедицина
		--left join #dp [dp_000000010] on [dp_000000010].Ссылка=d.Ссылка and [dp_000000010].Код='000000010' --Защита от потери работы
		--left join #dp [dp_000000011] on [dp_000000011].Ссылка=d.Ссылка and [dp_000000011].Код='000000011' --Фарм страхование
		--left join #dp [dp_000000012] on [dp_000000012].Ссылка=d.Ссылка and [dp_000000012].Код='000000012' --Спокойная жизнь
		left join #dm_sales dm_sales on dm_sales.Код=d.Код
		left join #current_percent current_percent on current_percent.Договор=d.Ссылка
		left join #percent_14days percent_14days on percent_14days.Договор=d.Ссылка

		)
		, v_v as (

		select v.Код
		, ДатаВыдачи
		, Срок
		, ДатаДоговора
		, СуммаВыдачи
		, cast(ПроцСтавкаКредит as float) ПроцСтавкаКредит
		, isnull(cast(ПоследняяПроцСтавкаДо14Дней as float), cast(ПроцСтавкаКредит as float)) ПоследняяПроцСтавкаДо14Дней
		, v.[SumKasko]
		, v.[SumEnsur]
		, v.[SumRat]
		, v.[SumPositiveMood]
		, v.[SumHelpBusiness]
		, v.[SumTeleMedic]
		, v.[SumCushion]
		, v.[SumPharma]
		, v.SumQuietLife
		, case when v.[SumKasko]          is not null then 1 else 0 end as ПризнакКаско
		, case when v.[SumEnsur]		  is not null then 1 else 0 end as ПризнакСтрахованиеЖизни
		, case when v.[SumRat]			  is not null then 1 else 0 end as ПризнакРАТ
		, case when v.[SumPositiveMood]	  is not null then 1 else 0 end as ПризнакПозитивНастр
		, case when v.[SumHelpBusiness]	  is not null then 1 else 0 end as ПризнакПомощьБизнесу
		, case when v.[SumTeleMedic]	  is not null then 1 else 0 end as ПризнакТелемедицина
		, case when v.[SumCushion]		  is not null then 1 else 0 end as [Признак Защита от потери работы]
		, case when v.[SumPharma]		  is not null then 1 else 0 end as ПризнакФарма
		, case when v.[SumQuietLife]		  is not null then 1 else 0 end as ПризнакСпокойнаяЖизнь
		, v.[SumKaskoCarmoney]
		, v.[SumEnsurCarmoney]
		, v.[SumRatCarmoney]
		, v.[SumPositiveMoodCarmoney]
		, v.[SumHelpBusinessCarmoney]
		, v.[SumTeleMedicCarmoney]
		, v.[SumCushionCarmoney]
		, v.[SumPharmaCarmoney]
		, v.SumQuietLifeCarmoney
		, v.[SumKaskoCarmoneyNet]
		, v.[SumEnsurCarmoneyNet]
		, v.[SumRatCarmoneyNet]
		--, v.[SumPositiveMoodCarmoneyNet]
		, v.[SumHelpBusinessCarmoneyNet]
		, v.[SumTeleMedicCarmoneyNet]
		, v.[SumCushionCarmoneyNet]
		, v.[SumPharmaCarmoneyNet]
		, v.SumQuietLifeCarmoneyNet
		,
		  isnull(v.[SumKasko]            ,0)+
		  isnull(v.[SumEnsur]			 ,0)+
		  isnull(v.[SumRat]				 ,0)+
		  isnull(v.[SumPositiveMood]	 ,0)+
		  isnull(v.[SumHelpBusiness]	 ,0)+
		  isnull(v.[SumTeleMedic]		 ,0)+
		  isnull(v.[SumCushion]			 ,0)+
		  isnull(v.SumPharma			 ,0)+
		  isnull(v.SumQuietLife			 ,0)
		   СуммаДопУслуг	
		,
		  isnull(v.[SumKaskoCarmoney]            ,0)+
		  isnull(v.[SumEnsurCarmoney]			 ,0)+
		  isnull(v.[SumRatCarmoney]				 ,0)+
		  isnull(v.[SumPositiveMoodCarmoney]	 ,0)+
		  isnull(v.[SumHelpBusinessCarmoney]	 ,0)+
		  isnull(v.[SumTeleMedicCarmoney]		 ,0)+
		  isnull(v.[SumCushionCarmoney]			 ,0)+
		  isnull(v.SumPharmaCarmoney			 ,0)+
		  isnull(v.SumQuietLifeCarmoney			 ,0)
		   СуммаДопУслугCarmoney	,
		  isnull(v.[SumKaskoCarmoneyNet]            ,0)+
		  isnull(v.[SumEnsurCarmoneyNet]			 ,0)+
		  isnull(v.[SumRatCarmoneyNet]				 ,0)+
		 -- isnull(v.[SumPositiveMoodCarmoneyNet]	 ,0)+
		  isnull(v.[SumHelpBusinessCarmoneyNet]	 ,0)+
		  isnull(v.[SumTeleMedicCarmoneyNet]		 ,0)+
		  isnull(v.[SumCushionCarmoneyNet]			 ,0)+
		  isnull(v.SumPharmaCarmoneyNet			 ,0)+
		  isnull(v.SumQuietLifeCarmoneyNet			 ,0)
		   СуммаДопУслугCarmoneyNet
		, case when 
			nullif(
		  isnull(v.[SumKasko]            ,0)+
		  isnull(v.[SumEnsur]			 ,0)+
		  isnull(v.[SumRat]				 ,0)+
		  isnull(v.[SumPositiveMood]	 ,0)+
		  isnull(v.[SumHelpBusiness]	 ,0)+
		  isnull(v.[SumTeleMedic]		 ,0)+
		  isnull(v.[SumCushion]			 ,0)+
		  isnull(v.SumPharma			 ,0)+
		  isnull(v.SumQuietLife			 ,0)
		  , 0)>0 then 1 else 0 end as ПризнакКП
		  , case when 
			nullif(
		  isnull(v.[SumKasko]            ,0)+
		  isnull(v.[SumEnsur]			 ,0)+
		  isnull(v.SumQuietLife			 ,0)
		  , 0)>0 then 1 else 0 end as ПризнакСтраховка
		
		from v
		)

		select * into #agr from v_v
	*/

		drop table if exists  #ol_call2
		--create ta
		select cast(Number as varchar(20)) Number, Call_date [Call2], case when Decision='accept' then Call_date end [Call2 accept]  into #ol_call2 from stg.[_loginom].[Originationlog]  where stage='call 2' 
		;
		--with v as (select *, count(*) over(partition by Number ) rn from #ol_call2 ) select * from v where rn>1
		with v as (select *, ROW_NUMBER() over(partition by Number order by [Call2 accept], [Call2] ) rn from #ol_call2 ) delete from v where rn>1


		drop table if exists #Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС
		select * into #Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС from 
		[Stg].[_1cCRM].[Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС] vidz

		--select * from #Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС
	
		--drop table if exists #crm_r
		--
		--select Номер, Статус, ВидЗаполнения, Фамилия, имя, Отчество, ВариантПредложенияСтавки, Пол, ДатаРождения , Дата, СуммарныйМесячныйДоход, ИспытательныйСрок, ЭлектроннаяПочта into #crm_r from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС crm_r 


		drop table if exists #t1

	select 
	fa.Номер, 
	fa.Дубль,
	fa.[Вид займа],
	fa.isPts,
	fa.isPdl,
	fa.isInstallment,
	--fa.isInstallment,
	fa.isSmartInstallment,
	fa.[Причина отказа],
	case when fa.[Вид займа]='Первичный' then 'Первичный' else 'Повторный' end [Вид займа_2],
	fa.ДатаЗаявкиПолная, 
	status_name.Наименование ТекущийСтатус, 
	isnull(fa.[Место cоздания], 'unknown') [Место cоздания],
	isnull(fa.[Место создания 2], 'unknown') Место_создания_2, 
	isnull(fa.[Группа каналов],  'unknown') [Группа каналов],
	isnull(fa.[Канал от источника],  'unknown') [Канал от источника],
	isnull(fa.[Группа каналов], 'unknown') [Группа каналов_перезаведение], 
	isnull(fa.[Канал от источника], 'unknown') [Канал от источника_перезаведение], 
	fa.Партнер,
	[Верификация КЦ], 
	[Предварительное одобрение], 
	[Встреча назначена], 
	[Контроль данных], 
	ol.[Call2]  [Call2],
	ol.[Call2 accept]  [Call2 accept],
	[Верификация документов клиента], 
	fa.[Одобрены документы клиента],
	[Верификация документов], 
	Одобрено [Одобрено],
	Отказано,
	[Отказ документов клиента],
	[Отказ клиента],
	Аннулировано,
	Забраковано,
	[Заем аннулирован],
	[Договор зарегистрирован],
	[Договор подписан],
	cast( [Договор зарегистрирован] as date) ДатаДоговора,
	[Заем выдан] [Заем выдан],
	[Заем выдан] [Заем выдан_agreement],
	[Заем погашен],
	[Выданная сумма]  [Выданная сумма],

	[Сумма одобренная],
	[Первичная сумма],
	[Сумма заявки],
	[Выданная сумма]-isnull(СуммаДопУслуг, 0) СуммаВыдачиБезКП ,
	ПризнакКП,
	ПризнакСтраховка,
	СуммаДопУслугCarmoneyNet,
	СуммаДопУслугCarmoney,
	СуммаДопУслуг,
	ПризнакКаско,
	ПризнакСтрахованиеЖизни,
	ПризнакРАТ,
	cast(null as int) ПризнакПозитивНастр,
	fa.ПризнакПомощьБизнесу,
	fa.ПризнакТелемедицина, 
	fa.[Признак Защита от потери работы],
	fa.ПризнакФарма,
	fa.ПризнакСпокойнаяЖизнь,
	fa.[Признак РАТ Юруслуги],
	fa.[SumKasko],
	fa.[SumKaskoCarmoney],
	fa.[SumKaskoCarmoneyNet],
	fa.[SumEnsur],
	fa.[SumEnsurCarmoney],
	fa.[SumEnsurCarmoneyNet],
	fa.[SumRat],
	fa.[SumRatCarmoney],
	fa.[SumRatCarmoneyNet],
	cast(null as float) [SumPositiveMood],
	cast(null as float) [SumPositiveMoodCarmoney],
	 --agr.[SumPositiveMoodCarmoneyNet],
	fa.[SumHelpBusiness],
	fa.[SumHelpBusinessCarmoney],
	fa.[SumHelpBusinessCarmoneyNet],
	fa.[SumTeleMedic],
	fa.[SumTeleMedicCarmoney],
	fa.[SumTeleMedicCarmoneyNet],
	fa.[SumCushion],
	fa.[SumCushionCarmoney],
	fa.[SumCushionCarmoneyNet],
	fa.[SumPharma],
	fa.[SumPharmaCarmoney],
	fa.[SumPharmaCarmoneyNet],
	fa.SumQuietLife,
	fa.SumQuietLifeCarmoney,
	fa.SumQuietLifeCarmoneyNet,
	fa.[Сумма РАТ Юруслуги],
	fa.[Сумма РАТ Юруслуги Carmoney],
	fa.[Сумма РАТ Юруслуги Carmoney Net],
	fa.Срок Срок,
	fa.ПроцСтавкаКредит ПроцСтавкаКредит,
	cast(null as float) ПоследняяПроцСтавкаДо14Дней,
	 row_number() over(partition by fa.Номер order by (select null) ) rn,
	 tvc.fpd0,
	 tvc.fpd4,
	 tvc.fpd7,
	 tvc.fpd30,
	 tvc.fpd60,
	 tvc.HR30@4 HR30_4,
	 tvc.HR90@12 HR90_12,
	 tvc.HR90@6 HR90_6,
	 tvc.[full_prepayment_30] ,
	 tvc.[full_prepayment_60] ,
	 tvc.[full_prepayment_90] ,
	 tvc.[full_prepayment_180],
	 gr.fin_gr [Группа риска],
	 isnull(cast(gr.fin_gr as varchar(10)), 'unknown') [Группа риска_varchar]
	 ,null as reject_reason
	 , isnull( try_cast(DATEDIFF(d, crm_r.ДатаРождения, crm_r.Дата)/365.25   as numeric(3,0)) , try_cast(mfo_r.ПолныхЛет as numeric(3,0))) ВозрастНаДатуЗаявки

	 ,isnull(cast(cast(crm_r.СуммарныйМесячныйДоход as bigint) as varchar(10)), 'unknown') СуммарныйМесячныйДоход_CRM
	 ,
	 --------------------------------------------
	 ------Регион проживания
	 --------------------------------------------
 
	regions.Регион РегионПроживания
	 ,
	 --------------------------------------------
	 ------Пол клиента
	 --------------------------------------------
	--Перечисление_ПолФизическогоЛица CRM
	--0xA5BA88039F4BFE3C463072DC5545798F	Мужской
	--0x90B3BFE98C983A0F4C9791EDF293AC4B	Женский
	case when crm_r.[Пол] = 0xA5BA88039F4BFE3C463072DC5545798F then 'Мужской'
		 when crm_r.[Пол] = 0x90B3BFE98C983A0F4C9791EDF293AC4B then 'Женский'
		 when mfo_r.[Пол] = 0xAFCEBF868D4361344851E8606D20B3F9 then 'Мужской'
		 when mfo_r.[Пол] = 0x80F4B5DF34A06D224981658CB1273444 then 'Женский' 
		 when right(replace(crm_r.Отчество, ' ', ''), 1)='ч' then  'Мужской'
		 when right(replace(crm_r.Отчество, ' ', ''), 1)='а' then  'Женский'
		 when crm_r.Отчество like '%оглы%' then  'Мужской'
		 when crm_r.Отчество like '%кызы%' then  'Женский'
		 else 'unknown'
	end
	as [ПолКлиента]


	,getdate() as created
	,fa.[Дата отчета] fa_created
	,fa.[Ссылка заявка]
	,fa.[Ссылка клиент]
	,fa.[ФИО]
	,fa.Телефон
	,case when precheckers.request_code is not null then 1 else 0 end as [ПризнакПредчекер]
	,precheckers.ЧислоДоработокПредЧекеры
	,precheckers.ЧислоРучныхПроверокПредчекерами
	,case when ltrim(rtrim(crm_r.ЭлектроннаяПочта)) like '%@%.%' then ltrim(rtrim(crm_r.ЭлектроннаяПочта)) end ЭлектроннаяПочта
	,null [Время в отложенных ВД_сек]
	,null [Время в отложенных КД_сек]
	,null [Время в отложенных ВДК_сек]

		  --select *  from stg._1ccrm.Справочник_ВариантыПредложенияСтавки order by КОд
		--  select *  from prodsql01.crm.dbo.Справочник_ВариантыПредложенияСтавки order by КОд
	,case 
	when isInstallment=1 then 'non-RBP'
	when ispdl=1 then 'non-RBP'
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 3' then 'RBP - 66'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 4' then 'RBP - 86'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 2' then 'RBP - 56'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 1' then 'RBP - 40'  
		  when ВариантПредложенияСтавки=  0xB83300505683CF4D11ED40333CBCED81 then 'RBP - 86' --Предложение21

		  when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95252 then 'RBP - 86' --Предложение13
		  when ВариантПредложенияСтавки=  0xB82D00505683CF4D11EC426681C6F03B then 'RBP - 66' --Предложение20
		  when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95253 then 'RBP - 56' --Предложение14
		  when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95254 then 'RBP - 40' --Предложение15
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBAEAE5ABFA6A0 then 'RBP - 40' --Предложение16
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A8 then 'RBP - 40' --Предложение17
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A7 then 'RBP - 40' --Предложение18
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A9 then 'RBP - 56' --Предложение19
		  when gr.fin_gr=50 then 'RBP - 40' --Июль 2020 запуск проекта
		  when [Вид займа]='Первичный' and fa.ДатаЗаявкиПолная >='20210604'   then 'RBP - 86' --После 2021 4 июля все первичные RBP по умолчанию

		  when risk_segments.[APR_SEGMENT]=  'GR_86/96' then 'non-RBP - 86'
		  when risk_segments.[APR_SEGMENT]=  'GR_56/66' then 'non-RBP - 56'
		  when risk_segments.[APR_SEGMENT]=  'GR_40/50' then 'non-RBP - 40'
		  else 'non-RBP' end as offer_details

	,case 
	when isInstallment=1 then 'non-RBP'
	when ispdl=1 then 'non-RBP'

			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 3' then 'RBP - 66'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 4' then 'RBP - 86'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 2' then 'RBP - 56'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 1' then 'RBP - 40'  
		  when ВариантПредложенияСтавки=  0xB83300505683CF4D11ED40333CBCED81 then 'RBP - 86' --Предложение21
		  when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95252 then 'RBP - 86' --Предложение13
		  when ВариантПредложенияСтавки=  0xB82D00505683CF4D11EC426681C6F03B then 'RBP - 66' --Предложение20
		  when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95253 then 'RBP - 56' --Предложение14
		  when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95254 then 'RBP - 40' --Предложение15
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBAEAE5ABFA6A0 then 'RBP - 40' --Предложение16
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A8 then 'RBP - 40' --Предложение17
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A7 then 'RBP - 40' --Предложение18
		  when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A9 then 'RBP - 56' --Предложение19
		  when gr.fin_gr=50 then 'RBP - 40'                                                  --Июль 2020 запуск проекта
		  when [Вид займа]='Первичный' and fa.ДатаЗаявкиПолная >='20210604'   then 'RBP - 86' --После 2021 4 июля все первичные RBP по умолчанию
		  when risk_segments.[APR_SEGMENT]=  'GR_86/96' then 'non-RBP - 86'
		  when risk_segments.[APR_SEGMENT]=  'GR_56/66' then 'non-RBP - 56'
		  when risk_segments.[APR_SEGMENT]=  'GR_40/50' then 'non-RBP - 40'
		  else 'non-RBP' end 
	  
	  
		  as offer,
		  case when crm_r.ИспытательныйСрок = 0 then 0 else 1 end as ИспытательныйСрок

	, case
	when isInstallment=1 then 'non-RBP'
	when ispdl=1 then 'non-RBP'

			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 3' then 'RBP - 66'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 4' then 'RBP - 86'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 2' then 'RBP - 56'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 1' then 'RBP - 40'  
		  when ВариантПредложенияСтавки=  0xB83300505683CF4D11ED40333CBCED81 then 'RBP - 86' --Предложение21

		   when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95252 then 'RBP - 86' --Предложение13
		   when ВариантПредложенияСтавки=  0xB82D00505683CF4D11EC426681C6F03B then 'RBP - 66' --Предложение20
		   when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95253 then 'RBP - 56' --Предложение14
		   when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95254 then 'RBP - 40' --Предложение15
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBAEAE5ABFA6A0 then 'RBP - 40' --Предложение16
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A8 then 'RBP - 40' --Предложение17
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A7 then 'RBP - 40' --Предложение18
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A9 then 'RBP - 56' --Предложение19
		   when gr.fin_gr=50 then 'RBP - 40' 												  --Июль 2020 запуск проекта
		   when [Вид займа]='Первичный' and fa.ДатаЗаявкиПолная >='20210604' then 'RBP - 86' --После 2021 4 июля все первичные RBP по умолчанию

		   else 'non-RBP' end RBP
	, case  


			when ispdl=1 and [Вид займа]='Первичный'  then 'Первичный займ: PDL'
			when ispdl=1 and [Вид займа]<>'Первичный' then 'Повторный займ: PDL'

					  when isInstallment=1 and [Вид займа]='Первичный'  then 'Первичный займ: installment'
			when isInstallment=1 and [Вид займа]<>'Первичный' then 'Повторный займ: installment'


			when crm_r.ИспытательныйСрок=1 then 'Исп. срок'
			when ras.rbp_gr='NotRBP_PROBATION' then 'Исп. срок'

			when fa.[Признак Рефинансирование]=1 then 'Рефинансирование'

			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 3' then 'Первичные: RBP - 66'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 4' then 'Первичные: RBP - 86'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 2' then 'Первичные: RBP - 56'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 1' then 'Первичные: RBP - 40'  
			when [Вид займа]='Повторный' then 'Повторный займ'
			when [Вид займа] in ('Докредитование' ,'Параллельный')  then 'Докредитование'




			when ВариантПредложенияСтавки in (  0xB81400155DFABA2A11E9F8551BC95254, 0xB82800505683CF4D11EBAEAE5ABFA6A0, 0xB82800505683CF4D11EBC4A9F0F286A8, 0xB82800505683CF4D11EBC4A9F0F286A7) or gr.fin_gr=50 then 'Первичные: RBP - 40'
			when [Вид займа]='Первичный' and ВариантПредложенияСтавки in ( 0xB81400155DFABA2A11E9F8551BC95252 , 0xB83300505683CF4D11ED40333CBCED81) then 'Первичные: RBP - 86'
			when [Вид займа]='Первичный' and ВариантПредложенияСтавки = 0xB82D00505683CF4D11EC426681C6F03B  then 'Первичные: RBP - 66'
			when [Вид займа]='Первичный' and ВариантПредложенияСтавки in (0xB81400155DFABA2A11E9F8551BC95253  , 0xB82800505683CF4D11EBC4A9F0F286A9) then 'Первичные: RBP - 56'
			when [Вид займа]='Первичный' and fa.ДатаЗаявкиПолная >='20210604' then 'Первичные: RBP - 86'
			when [Вид займа]='Первичный' then 'Первичные: non-RBP'
			when [Вид займа]='Повторный' then 'Повторный займ'
			when [Вид займа] in ('Докредитование' ,'Параллельный')  then 'Докредитование'
			end as product


	,case when fa.[Признак Рефинансирование]=1  then 1 else 0 end as [ПризнакРефинансирование]
	,isnull(f_req.AprRecommended, f_req.PercentApproved) РекомендованнаяСтавка
	,case when requests_steps.request_id is not null then 1 else 0 end as [ПризнакШагиЧерезМП]
	,requests_steps.[Переход в МП с шага 1 на 2 шаг]	
	,requests_steps.[Переход в МП с шага 2 на 2.5 шаг (ПЭП)]	
	,requests_steps.[Переход в МП с шага 3 на 4 шаг]	
	,requests_steps.[Переход в МП с шага 4 на 5 шаг]	
	,requests_steps.[Переход в МП с шага 5 на 6 шаг]	
	,requests_steps.[Переход в МП с шага 6 на 7 шаг]	
	,requests_steps.[Переход в МП с шага 7 на 8 шаг]	
	,requests_steps.[Переход в МП с шага 8 на 9 шаг]	
	,requests_steps.[Переход в МП с шага 9 на сводную информацию по заявке]	
	,requests_steps.[Переход в МП с основного калькулятора на калькулятор ПТС]
	,requests_steps.[Переход в МП с основного калькулятора на шаг короткой анкеты Installment]
	,requests_steps.[Переход в МП с шага короткой анкеты на шаг первого пакета док-ов]
	,requests_steps.[Переход в МП с шага подписания пакета документов на шаг заполнения полной анкеты 1]
	,requests_steps.[Переход в МП с шага заполнения полной анкеты 1 на шаг заполнения полной анкеты 2]
	,requests_steps.[Переход в МП с шага заполнения полной анкеты 2 на шаг заполнения полной анкеты 3]
	,requests_steps.[Переход в МП с шага заполнения полной анкеты 3 на шаг заполнения полной анкеты 4]
	,requests_steps.[Переход в МП с шага заполнения полной анкеты 4 на шаг заполнения полной анкеты 5]
	,requests_steps.[Переход в МП с шага заполнения полной анкеты 5 на шаг способ получения ДС]
	,requests_steps.[Переход в МП с шага ожидания одобрения на шаг выбор предложения]
	,requests_steps.[Переход в МП с шага выбор предложения на шаг подписания 2-го пакета док-тов]
	,requests_steps.[Переход в МП с шага подписания 2-го пакета документов на шаг ожидания дс]
	,requests_steps.[Запрос подписания данных для проверки карты SDK]

	,requests_steps.[Переход в МП с шага 1 на 2 шаг_аналитический]	
	,requests_steps.[Переход в МП с шага 2 на 2.5 шаг (ПЭП)_аналитический]	
	,requests_steps.[Переход в МП с шага 3 на 4 шаг_аналитический]	
	,requests_steps.[Переход в МП с шага 4 на 5 шаг_аналитический]	
	,requests_steps.[Переход в МП с шага 5 на 6 шаг_аналитический]	
	,requests_steps.[Переход в МП с шага 6 на 7 шаг_аналитический]	
	,requests_steps.[Переход в МП с шага 7 на 8 шаг_аналитический]	
	,requests_steps.[Переход в МП с шага 8 на 9 шаг_аналитический]	
	,requests_steps.[Переход в МП с шага 9 на сводную информацию по заявке_аналитический]	
	,isnull(isnull(os_on_request.request_os, os_on_user.user_os), 'unknown') user_os
	,lk_requests.id as request_id
	,lk_requests.code as request_code
	,lk_requests.created_at as created_at_lk
	,vz.Наименование [Вид заполнения]
	,crm_r.Фамилия
	,crm_r.Имя
	,crm_r.Отчество
	, ps.Наименование [Вариант предложения ставки]
	--, fa.Партнер
	, fa.[офис ссылка]
	, fa.РП
	, fa.РО_регион
	, fa.Источник
	, fa.[Тип трафика]
	 into --drop table if exists
	 #t1--
 

	from #fa fa
	--left join #v_dm_place_of_creation_2 poc2 on poc2.Номер=fa.Номер
	--left join #v_dm_factor_analysis_001_channels chanels on chanels.Номер=fa.Номер
	left join STG._loginom.Dm_risk_groups gr with(nolock) on fa.Номер=cast(gr.number as nvarchar(20))
	left join #ol_call2 ol with(nolock) on fa.Номер=ol.number

	--left join #agr agr on agr.Код=fa.Номер and fa.[Заем выдан] is not null
	left join dwh_new.dbo.tmp_v_credits tvc on tvc.external_id=fa.Номер
	--left join dbo.dm_MainData md1 on md1.external_id=fa.Номер
	left join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС crm_r   on crm_r.ссылка=fa.[Ссылка заявка]
	left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] status_name on status_name.Ссылка=crm_r.Статус
	left join stg._1cMFO.Документ_ГП_Заявка mfo_r on mfo_r.Номер=fa.Номер
	left join #lk lk_requests on lk_requests.num_1c=fa.Номер
	left join #precheckers precheckers on lk_requests.code=precheckers.request_code
	left join #requests_steps requests_steps on lk_requests.id=requests_steps.request_id
	left join #os_on_user os_on_user on os_on_user.id=lk_requests.client_id
	left join #os_on_request os_on_request on os_on_request.request_id=lk_requests.id
	left join [dwh_new].[dbo].[risk_apr_segment] risk_segments on risk_segments.Number=fa.Номер
	left join #regions regions on fa.[Регион проживания]=regions.РегионДляПоиская
	left join #core_ClientRequest f_req on f_req.Number=fa.Номер
	left join #Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС vz on vz.Ссылка=crm_r.ВидЗаполнения
	left join stg.[_1cCRM].[Справочник_ВариантыПредложенияСтавки] ps on ps.Ссылка=crm_r.ВариантПредложенияСтавки
	left join dwh2.dbo.v_risk_apr_segment ras on ras.number=fa.Номер
	delete from #t1 where rn>1





	--select a.Номер,  a.СуммаДопУслугCarmoneyNet , b.СуммаДопУслугCarmoneyNet, isnull(b.СуммаДопУслугCarmoneyNet, 0) - isnull(a.СуммаДопУслугCarmoneyNet, 0), CP_info from #t1 a
	--left join dbo.dm_factor_analysis b on a.Номер=b.Номер
	--left join Analytics.dbo.mv_loans f on f.код=a.Номер
	--order by 4

	--EXEC tempdb.dbo.sp_help @objname = N'#t1'

	--select * from #t1
	--where номер='21071200121015'

	if @reCreateTable = 1
	begin
		drop table if exists  dbo.dm_Factor_Analysis
		select top(0) * 
			into  dbo.dm_Factor_Analysis
		from #t1

		drop table if exists  dbo.dm_Factor_Analysis_staging
		select top(0) * 
			into  dbo.dm_Factor_Analysis_staging
		from #t1


		drop table if exists  dbo.dm_Factor_Analysis_to_del
		select top(0) * 
			into  dbo.dm_Factor_Analysis_to_del
		from #t1





	end




	if exists(select top(1) 1 from #t1)
	begin
		--Отчистим таблицу - хотя после пред операции она и так будет пустая
		truncate table dm_Factor_Analysis_to_del
		truncate table dm_Factor_Analysis_staging 
		insert into [dbo].dm_Factor_Analysis_staging  with(tablockx)
		SELECT * 
		from #t1

		begin tran
			alter table [dbo].[dm_Factor_Analysis]
				switch to dm_Factor_Analysis_to_del
				with (WAIT_AT_LOW_PRIORITY  ( MAX_DURATION = 1 minutes, ABORT_AFTER_WAIT = SELF ))
			alter table dm_Factor_Analysis_staging 
				switch  to [dm_Factor_Analysis]
				with (WAIT_AT_LOW_PRIORITY  ( MAX_DURATION = 1 minutes, ABORT_AFTER_WAIT = SELF ))
		commit tran
	end

	end try

	begin catch
		if @@TRANCOUNT>0
			rollback tran
	end catch

end

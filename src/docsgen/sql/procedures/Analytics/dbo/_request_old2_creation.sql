CREATE   proc --exec

[dbo].[_request_old2_creation]

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
	[Место создания] [Место cоздания],
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
	 , CALL2
	 , [call2 accept]
	 , productType
	into #fa from v_fa


 


	drop table if exists #precheckers
	select  request_code, isnull(sum(manual_check),0) ЧислоРучныхПроверокПредчекерами, isnull(sum(case when mark=0 then manual_check end), 0) ЧислоДоработокПредЧекеры  into #precheckers 
	from stg._lk.precheck_action 
	where manual_check=1 
	and 1=0
	group by request_code

	drop table if exists #requests_steps
	;

	with request_steps as (	
	select request_id      request_id	
	,      event_id        event_id	
	,      min(created_at) min_created_at	
	from stg.[_LK].[requests_events]--	with(nolock)  --select * from openquery(lkprod, 'select * from events')
	where event_id between 24 and 45
	and 1=0

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

	;
		--with v as (select *, count(*) over(partition by Number ) rn from #ol_call2 ) select * from v where rn>1
		--with v as (select *, ROW_NUMBER() over(partition by Number order by [Call2 accept], [Call2] ) rn from #ol_call2 ) delete from v where rn>1


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
	[Call2]  [Call2],
	[Call2 accept]  [Call2 accept],
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
	 1 rn,
	 l.fpd0,
	 l.fpd4,
	 l.fpd7,
	 l.fpd30,
	 l.fpd60,
	 l._30_4_CMR HR30_4,
	 l._90_12_CMR HR90_12,
	 l._90_6_CMR HR90_6,
	 case when fa.[Заем выдан] is not null then case when datediff(day,fa.[Заем выдан] ,fa.[Заем погашен] )<=30  then 1  else 0 end end [full_prepayment_30] ,
	 case when fa.[Заем выдан] is not null then case when datediff(day,fa.[Заем выдан] ,fa.[Заем погашен] )<=60  then 1  else 0 end end [full_prepayment_60] ,
	 case when fa.[Заем выдан] is not null then case when datediff(day,fa.[Заем выдан] ,fa.[Заем погашен] )<=90  then 1  else 0 end end [full_prepayment_90] ,
	 case when fa.[Заем выдан] is not null then case when datediff(day,fa.[Заем выдан] ,fa.[Заем погашен] )<=180 then 1  else 0 end end [full_prepayment_180],
	 cast(null as float) [Группа риска],
	 isnull(cast(null as varchar(10)), 'unknown') [Группа риска_varchar]
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
		  --when gr.fin_gr=50 then 'RBP - 40' --Июль 2020 запуск проекта
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
		  --when gr.fin_gr=50 then 'RBP - 40'                                                  --Июль 2020 запуск проекта
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
		 --  when gr.fin_gr=50 then 'RBP - 40' 												  --Июль 2020 запуск проекта
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




			when ВариантПредложенияСтавки in (  0xB81400155DFABA2A11E9F8551BC95254, 0xB82800505683CF4D11EBAEAE5ABFA6A0, 0xB82800505683CF4D11EBC4A9F0F286A8, 0xB82800505683CF4D11EBC4A9F0F286A7) 
			--or gr.fin_gr=50 
			then 'Первичные: RBP - 40'
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
	, fa.productType
	 into --drop table if exists
	 #t1--
 

	from #fa fa
	--left join #v_dm_place_of_creation_2 poc2 on poc2.Номер=fa.Номер
	--left join #v_dm_factor_analysis_001_channels chanels on chanels.Номер=fa.Номер
	--left join STG._loginom.Dm_risk_groups gr with(nolock) on fa.Номер=cast(gr.number as nvarchar(20))
	--left join #ol_call2 ol with(nolock) on fa.Номер=ol.number

	--left join #agr agr on agr.Код=fa.Номер and fa.[Заем выдан] is not null
	--left join dwh_new.dbo.tmp_v_credits tvc on tvc.external_id=fa.Номер
	left join v_loan_overdue l on l.Number=fa.Номер
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
	
	
	;
with v as (select *, ROW_NUMBER() over(partition by Номер order by (select 1 )) rnn from #t1 )	delete from v where rnn>1

--alter table dm_Factor_Analysis add productType varchar(10)
--alter table dm_Factor_Analysis_staging add productType varchar(10)
--alter table dm_Factor_Analysis_to_del add productType varchar(10)

 

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

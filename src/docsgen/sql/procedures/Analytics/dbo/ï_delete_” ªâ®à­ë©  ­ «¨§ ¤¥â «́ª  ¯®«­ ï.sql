
CREATE   proc dbo.[Факторный анализ деталька полная]

@datefrom_ date , 
@dateto_  date 

as
begin




select Номер,[Заем выдан], [Ссылка клиент], case when  ROW_NUMBER() over(partition by  [Ссылка клиент] order by [Заем выдан])=1 then
'Первичный'
else 'Повторный'
end [Видзайма в рамках продукта инстиоллмент]
into #vid
from reports.dbo.dm_Factor_Analysis_001
where isInstallment=1 and [Заем выдан] is not null



declare @datefrom date = @datefrom_ -- cast(format( getdate()-1  , 'yyyy-MM-01') as date)  
declare @dateto date   = @dateto_ --getdate()-1


;with gmt as (

select 'Адыгея' r , 'GMT+03:00' gmt union all
select 'Алтай' r , 'GMT+07:00' gmt union all
--select 'Алтай' r , 'GMT+07:00' gmt union all
select 'Амурская' r , 'GMT+09:00' gmt union all
select 'Архангельская' r , 'GMT+03:00' gmt union all
select 'Астраханская' r , 'GMT+04:00' gmt union all
select 'Байконур' r , 'GMT+06:00' gmt union all
--select 'Башкортостан' r , 'GMT+05:00' gmt union all
--select 'Башкортостан' r , 'GMT+05:00' gmt union all
select 'Белгородская' r , 'GMT+03:00' gmt union all
select 'Брянская' r , 'GMT+03:00' gmt union all
select 'Бурятия' r , 'GMT+08:00' gmt union all
select 'Владимирская' r , 'GMT+03:00' gmt union all
select 'Волгоградская' r , 'GMT+03:00' gmt union all
select 'Вологодская' r , 'GMT+03:00' gmt union all
select 'Воронежская' r , 'GMT+03:00' gmt union all
select 'Дагестан' r , 'GMT+03:00' gmt union all
select 'Еврейская' r , 'GMT+10:00' gmt union all
select 'Забайкальский' r , 'GMT+09:00' gmt union all
select 'Ивановская' r , 'GMT+03:00' gmt union all
select 'Ингушетия' r , 'GMT+03:00' gmt union all
select 'Иркутская' r , 'GMT+08:00' gmt union all
select 'Кабардино-Балкарская' r , 'GMT+03:00' gmt union all
select 'Калининградская' r , 'GMT+02:00' gmt union all
select 'Калмыкия' r , 'GMT+03:00' gmt union all
select 'Калужская' r , 'GMT+03:00' gmt union all
select 'Камчатский' r , 'GMT+12:00' gmt union all
select 'Карачаево-Черкесская' r , 'GMT+03:00' gmt union all
select 'Карелия' r , 'GMT+03:00' gmt union all
select 'Кемеровская' r , 'GMT+07:00' gmt union all
select 'Кировская' r , 'GMT+03:00' gmt union all
--select 'Коми' r , 'GMT+03:00' gmt union all
select 'Костромская' r , 'GMT+03:00' gmt union all
select 'Краснодарский' r , 'GMT+03:00' gmt union all
select 'Красноярский' r , 'GMT+07:00' gmt union all
select 'Крым' r , 'GMT+03:00' gmt union all
select 'Курганская' r , 'GMT+05:00' gmt union all
select 'Курская' r , 'GMT+03:00' gmt union all
select 'Ленинградская' r , 'GMT+03:00' gmt union all
select 'Липецкая' r , 'GMT+03:00' gmt union all
--select 'Липецкая' r , 'GMT+03:00' gmt union all
select 'Магаданская' r , 'GMT+10:00' gmt union all
select 'Марий Эл' r , 'GMT+03:00' gmt union all
select 'Мордовия' r , 'GMT+03:00' gmt union all
select 'Москва' r , 'GMT+03:00' gmt union all
--select 'Московская' r , 'GMT+03:00' gmt union all
select 'Московская' r , 'GMT+03:00' gmt union all
select 'Мурманская' r , 'GMT+03:00' gmt union all
select 'Ненецкий' r , 'GMT+03:00' gmt union all
select 'Нижегородская' r , 'GMT+03:00' gmt union all
select 'Новгородская' r , 'GMT+03:00' gmt union all
select 'Новосибирская' r , 'GMT+06:00' gmt union all
select 'Омская' r , 'GMT+06:00' gmt union all
--	select 'Оренбургская' r , 'GMT+05:00' gmt union all
select 'Оренбургская' r , 'GMT+05:00' gmt union all
select 'Орловская' r , 'GMT+03:00' gmt union all
select 'Пензенская' r , 'GMT+03:00' gmt union all
--select 'Пензенская' r , 'GMT+03:00' gmt union all
select 'Пермский' r , 'GMT+05:00' gmt union all
select 'Приморский' r , 'GMT+10:00' gmt union all
select 'Псковская' r , 'GMT+03:00' gmt union all
--select 'Псковская' r , 'GMT+03:00' gmt union all
select 'Башкортостан' r , 'GMT+05:00' gmt union all
select 'Коми' r , 'GMT+03:00' gmt union all
select 'Ростовская' r , 'GMT+03:00' gmt union all
select 'Рязанская' r , 'GMT+03:00' gmt union all
select 'Самарская' r , 'GMT+04:00' gmt union all
select 'Санкт-Петербург' r , 'GMT+03:00' gmt union all
select 'Саратовская' r , 'GMT+03:00' gmt union all
--select 'Саратовская' r , 'GMT+03:00' gmt union all
--select 'Саратовская' r , 'GMT+03:00' gmt union all
select 'Якутия' r , 'GMT+09:00' gmt union all
select 'Сахалинская' r , 'GMT+11:00' gmt union all
select 'Свердловская' r , 'GMT+05:00' gmt union all
select 'Севастополь' r , 'GMT+03:00' gmt union all
select 'Северная Осетия' r , 'GMT+03:00' gmt union all
select 'Смоленская' r , 'GMT+03:00' gmt union all
select 'Ставропольский' r , 'GMT+03:00' gmt union all
select 'Тамбовская' r , 'GMT+03:00' gmt union all
select 'Татарстан' r , 'GMT+03:00' gmt union all
select 'Тверская' r , 'GMT+03:00' gmt union all
select 'Томская' r , 'GMT+06:00' gmt union all
select 'Тульская' r , 'GMT+03:00' gmt union all
select 'Тыва' r , 'GMT+07:00' gmt union all
select 'Тюменская' r , 'GMT+05:00' gmt union all
select 'Удмуртская' r , 'GMT+04:00' gmt union all
select 'Ульяновская' r , 'GMT+04:00' gmt union all
select 'Хабаровский' r , 'GMT+10:00' gmt union all
select 'Хакасия' r , 'GMT+07:00' gmt union all
select 'Ханты-Мансийский' r , 'GMT+05:00' gmt union all
--select 'Ханты-Мансийский' r , 'GMT+05:00' gmt union all
select 'Челябинская' r , 'GMT+05:00' gmt union all
select 'Чеченская' r , 'GMT+03:00' gmt union all
select 'Чувашская' r , 'GMT+03:00' gmt union all
select 'Чукотский' r , 'GMT+12:00' gmt union all
select 'Ямало-Ненецкий' r , 'GMT+05:00' gmt union all
select 'Ярославская' r , 'GMT+03:00' gmt --union all
--order by 1

)

select
	fa1.[Дата],
	fa1.[Время],
	fa1.[Номер],
	fa1.[Текущий статус],
	fa1.[Место cоздания],
	fa1.[Место создания 2] [Место_создания_2],
	fa1.[Автор],
	case when isnull(left(fa1.[Причина отказа], 3), '') in ('UW.', 'CH.', 'СH.', 'СН.') then left(fa1.[Причина отказа] , 3) else fa1.[Причина отказа] end [Причина отказа],
	fa1.[РП],
	fa1.[Регион],
	fa1.[Партнер],
	fa1.[Номер партнера],
	gmt.gmt,
	fa1.[Регион Проживания],
	fa1.[Вид займа],
	fa1.[Категория повторного клиента],
	fa1.[Продукт],
	fa1.[Срок займа],
	fa1.[Первичная сумма],
	fa1.[Стоимость ТС],
	fa1.[Сумма одобренная],
	fa1.[Выданная сумма],
	fa1.[Сумма заявки],
	fa1.[Способ выдачи],
	fa1.[LCRM ID],
	fa1.[Верификация КЦ],
	fa1.[Предварительное одобрение],
	fa1.[Встреча назначена],
	fa1.[Контроль данных],
	fa.[Call2],
	fa1.[Верификация документов клиента],	
	fa1.[Одобрены документы клиента],
	fa1.[Верификация документов],
	fa1.[Одобрено],
	fa1.[Договор зарегистрирован],
	fa1.[Договор подписан],
	fa1.[Заем выдан],
	fa1.[Заем погашен],
	fa1.[Заем аннулирован],
	fa1.[Аннулировано],
	fa1.[Отказ документов клиента],
	fa1.[Отказано],
	fa1.[Отказ клиента],
	fa1.[Забраковано],
	fa1.[ПризнакЗаявка],
	fa1.[ПризнакПредварительноеОдобрение],
	fa1.[ПризнакВстречаНазначена],
	fa1.[ПризнакКонтрольДанных],
	fa1.[ПризнакКонтрольДанныхИзФактическихВстреч],
	fa1.[ПризнакВерификацияДокументовКлиента],
	fa1.[ПризнакОдобреныДокументовКлиента],
	fa1.[ПризнакВерификацияДокументов],
	fa1.[ПризнакОдобрено],
	fa1.[ПризнакДоговорЗарегистрирован],
	fa1.[ПризнакДоговорПодписан],
	fa1.[ПризнакЗайм],
	fa1.[ПризнакОтказано],
	fa1.[ПризнакОтказКлиента],
	fa1.[ПризнакЗаймДеньВДень],
	fa1.[ПризнакЗаймНеДеньВДень],
	fa1.[ПризнакЗабраковано],
	fa1.[Признак Отказ документов клиента],
	fa1.[НеПрошлиКД],
	fa1.[ОдобреноНоЗаймНеВыдан],
	fa1.[ВремяОтВерификацияКЦДоВыдачиЧасы],
	fa1.[НеделяЗаявки],
	fa1.[МесяцЗаявки],
	fa1.[ГодЗаявки],
	fa1.[НеделяЗайма] as [НеделяВыдач],
	fa1.[МесяцВыдач],
	fa1.[ГодВыдачи],
	fa1.[Канал от источника],
	fa1.[Группа каналов],	
	fa1.[Телефон],
	fa1.[TTC_number],
	fa1.[TTC],
	fa1.[ДатаЗаявкиПолная],
	fa1.[Дубль],	
	fa1.[ФИО],
	fa1.[P2P],
	fa1.[ПризнакP2P],
	fa1.[Ссылка заявка],
	fa1.[Ссылка клиент],
	fa1.[Дата отчета],	
	fa.[СуммаВыдачиБезКП],
	fa.[ПризнакКП],
	fa.[СуммаДопУслуг],
	fa.[ПризнакКаско],
	fa.[ПризнакСтрахованиеЖизни],
	fa.[ПризнакРАТ],
	fa.[ПризнакПозитивНастр],
	fa.[ПризнакПомощьБизнесу],
	fa.[ПризнакТелемедицина],
	fa.[Признак Защита от потери работы],
	fa.[ПризнакФарма],
	fa.[ПризнакСпокойнаяЖизнь],
	fa1.[Признак Рат Юруслуги],
	fa.[SumKasko],
	fa.[SumEnsur],
	fa.[SumRat],
	fa.[SumPositiveMood],
	fa.[SumHelpBusiness],
	fa.[SumTeleMedic],
	fa.[SumCushion],
	fa.[SumPharma],
    fa.SumQuietLife,
    fa1.[Сумма Рат Юруслуги],
	fa.СуммаДопУслугCarmoney as [СуммаДопУслугЗаВычетомПартнерскойКомиссии],
	fa.СуммаДопУслугCarmoneyNet as [СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net],
	fa.[ПроцСтавкаКредит],
	fa.[Группа риска],
	fa.[Группа риска_varchar],
	fa.[reject_reason],
	fa.[ВозрастНаДатуЗаявки],
	fa.[СуммарныйМесячныйДоход_CRM],
	fa.[РегионПроживания],
	fa.[ПолКлиента],
	fa.[ПризнакПредчекер],
	fa.[ЧислоДоработокПредЧекеры],
	fa.[ЧислоРучныхПроверокПредчекерами],
	fa.[ЭлектроннаяПочта],
	null [Время в отложенных ВД_сек],--fa.[Время в отложенных ВД_сек],
	null [Время в отложенных КД_сек],--fa.[Время в отложенных КД_сек],
	null [Время в отложенных ВДК_сек],--fa.[Время в отложенных ВДК_сек],
	fa.[offer_details],
	fa.[offer],
	fa.[ИспытательныйСрок],
	fa1.RBP RBP,
	fa1.product [product],
	fa1.[Признак Рефинансирование] [ПризнакРефинансирование],
fa1.Источник,
fa1.Вебмастер,
fa1.[Приоритет обзвона],
fa1.[Юрлицо при создании],
fa1.[Номер точки при создании],
fa1.issmartinstallment issmartinstallment,
#vid.[Видзайма в рамках продукта инстиоллмент]
from
	Reports.[dbo].[dm_Factor_Analysis_001] fa1 (nolock)
	inner join Reports.[dbo].[dm_Factor_Analysis] fa (nolock) on fa.Номер = fa1.Номер
	left join gmt on gmt.r=fa.РегионПроживания
	left join #vid on #vid.Номер=fa1.Номер
Where
	cast(fa1.[Верификация КЦ] as date) between @datefrom and @dateto
--order by
	--fa1.ДатаЗаявкиПолная

	end
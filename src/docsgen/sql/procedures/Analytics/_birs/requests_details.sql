

CREATE   proc    [_birs].[requests_details]


@date_from date = null,
@date_to date = null,
@all_columns int  = 1 ,
@pts int  = -1,
@login   varchar(100) = null
as

begin
 
--grant insert on dbo.requests_details_order to reportviewer
----drop table dbo.requests_details_order (
--create table dbo.requests_details_order (
--row_id uniqueidentifier,
--start_date date,
--end_date date,
--created datetime,
--status nvarchar(20) )

--insert into  dbo.requests_details_order 
--select newid(), @date_from, @date_to, getdate(), 'created'



declare @datefrom date = @date_from 
declare @dateto date = @date_to	


--declare @datefrom date = getdate()	 declare @dateto date = getdate() , @all_columns int=0, @pts int =1


drop table if exists #request_new
select number, carBrand, carModel, carYear, cast( null as nvarchar(100)) as vin, 
hasLeadInfoseti hasLeadInfoseti

into #request_new from _request with(nolock) where 1=0




--declare @datefrom date = getdate()	 declare @dateto date = getdate() declare @all_columns int=0



  drop table if exists #t1
  select 	fa.Номер,		  

	fa.СуммаДопУслугCarmoney,
	fa.СуммаДопУслугCarmoneyNet,
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
	fa.[SumKasko],
	fa.[SumEnsur],
	fa.[SumRat],
	fa.[SumPositiveMood],
	fa.[SumHelpBusiness],
	fa.[SumTeleMedic],
	fa.[SumCushion],
	fa.[SumPharma],
    fa.SumQuietLife,		    
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
	fa.[Время в отложенных ВД_сек],
	fa.[Время в отложенных КД_сек],
	fa.[Время в отложенных ВДК_сек],
	fa.[offer_details],
	fa.[offer],
	fa.[ИспытательныйСрок],
	fa.[RBP],
	fa.[product],
	fa.[ПризнакРефинансирование],
	fa.[Вариант предложения ставки]
	
	into #t1 from Reports.[dbo].[dm_Factor_Analysis]	 fa
	
Where
	cast(fa.[Верификация КЦ] as date) between @datefrom and @dateto	  --	  and 1=0
	and case when @pts>=0 and fa.isPts=@pts then 1
	  when @pts=-1 then 1  end =1
	
	
	drop table if exists #f1
  select 	fa1.[Дата],
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
	fa1.[Call2],
	fa1.[Call2 accept],
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
 
	fa1.[Признак Рат Юруслуги],
 
    fa1.[Сумма Рат Юруслуги],
 
fa1.Источник,
fa1.Вебмастер,
fa1.[Приоритет обзвона],
fa1.[Юрлицо при создании],
fa1.[Номер точки при создании],
fa1.issmartinstallment issmartinstallment,
fa1.СрокЛьготногоПериода
	
	into #f1 from Reports.[dbo].[dm_Factor_Analysis_001]	 fa1
	
Where
	cast(fa1.[Верификация КЦ] as date) between @datefrom and @dateto		-- and 1=0

		and case when @pts>=0 and fa1.isPts=@pts then 1
	  when @pts=-1 then 1  end =1


if @all_columns=1 begin
insert into #request_new
select a.number, a.carBrand, a.carModel, a.carYear,  null as vin, a.hasLeadInfoseti hasLeadInfoseti from _request a with(nolock)  join #f1 b on a.number=b.Номер

;with v  as (select *, row_number() over(partition by number order by (select null)) rn from #request_new ) delete from v where rn>1


 

end


	

drop table if exists #vid
select  Номер,[Заем выдан], [Ссылка клиент], case when  ROW_NUMBER() over(partition by  [Ссылка клиент] order by [Заем выдан])=1 then
'Первичный'
else 'Повторный'
end [Видзайма в рамках продукта инстиоллмент]
into #vid
from reports.dbo.dm_Factor_Analysis_001
where isPts=0 and [Заем выдан] is not null
and @pts in (-1, 0)

;
with v as (


select
	fa1.[Дата],
	fa1.[Время],
	fa1.[Номер],
	fa1.[Текущий статус],
	fa1.[Место cоздания],
	fa1.[Место_создания_2],
	fa1.[Автор],
	 fa1.[Причина отказа]  [Причина отказа],
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
	fa1.[Call2],
	fa1.[Call2 accept],
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
	fa1.[НеделяВыдач] as [НеделяВыдач],
	fa1.[МесяцВыдач],
	fa1.[ГодВыдачи],
	fa1.[Канал от источника],
	fa1.[Группа каналов],	
	fa1.[Телефон]  as [Телефон],
	--''  as [Телефон],
	fa1.[TTC_number],
	fa1.[TTC],
	fa1.[ДатаЗаявкиПолная],
	fa1.[Дубль],	
	fa1.[ФИО]  as [ФИО],
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
	fa.[Время в отложенных ВД_сек],
	fa.[Время в отложенных КД_сек],
	fa.[Время в отложенных ВДК_сек],
	fa.[offer_details],
	fa.[offer],
	fa.[ИспытательныйСрок],
	fa.[RBP],
	fa.[product],
	fa.[ПризнакРефинансирование],
	fa.[Вариант предложения ставки],
fa1.Источник,
fa1.Вебмастер,
fa1.[Приоритет обзвона],
fa1.[Юрлицо при создании],
fa1.[Номер точки при создании],
fa1.issmartinstallment issmartinstallment,
#vid.[Видзайма в рамках продукта инстиоллмент] ,
fa1.СрокЛьготногоПериода,
#request_new.carBrand,
#request_new.carModel,
#request_new.carYear,
#request_new.vin ,
#request_new.hasLeadInfoseti 

--into #ttttt
from
	#f1  fa1 (nolock)
	inner join #t1 fa (nolock) on fa.Номер = fa1.Номер
	left join v_gmt gmt on gmt.region=fa.РегионПроживания
	left join #vid on #vid.Номер=fa1.Номер
	left join #request_new on #request_new.number=fa1.Номер
	)


select 
    a.[Дата] 
,   a.[Время] 
,   a.[Номер] 
,   a.[Текущий статус] 
,   a.[Место cоздания] 
,   case when @all_columns=1 then a.[Место_создания_2] end as [Место_создания_2] 
,   case when @all_columns=1 then a.[Автор] end as [Автор] 
,   case when @all_columns=1 then a.[Причина отказа] end as [Причина отказа] 
,   case when @all_columns=1 then a.[РП] end as [РП] 
,   case when @all_columns=1 then a.[Регион] end as [Регион] 
,   case when @all_columns=1 then a.[Партнер] end as [Партнер] 
,   case when @all_columns=1 then a.[Номер партнера] end as [Номер партнера] 
,   case when @all_columns=1 then a.[gmt] end as [gmt] 
,   case when @all_columns=1 then a.[Регион Проживания] end as [Регион Проживания] 
,   a.[Вид займа] 
,   case when @all_columns=1 then a.[Категория повторного клиента] end as [Категория повторного клиента] 
,   case when @all_columns=1 then a.[Продукт] end as [Продукт] 

,   case when @all_columns=1 then a.[Срок займа] end as [Срок займа] 
,   a.[Первичная сумма] 
,   case when @all_columns=1 then a.[Стоимость ТС] end as [Стоимость ТС] 
,   a.[Сумма одобренная] 
,   a.[Выданная сумма] 
,   a.[Сумма заявки] 
,   case when @all_columns=1 then a.[Способ выдачи] end as [Способ выдачи] 
,   case when @all_columns=1 then a.[LCRM ID] end as [LCRM ID] 
,   a.[Верификация КЦ] 
,   a.[Предварительное одобрение] 
,   a.[Встреча назначена] 
,   a.[Контроль данных] 
,   a.[Call2] 
,   a.[Call2 accept]  
,   a.[Верификация документов клиента] 
,   a.[Одобрены документы клиента] 
,   a.[Верификация документов] 
,   a.[Одобрено] 
,   a.[Договор зарегистрирован] 
,   a.[Договор подписан] 
,   a.[Заем выдан] 
,   case when @all_columns=1 then a.[Заем погашен] end as [Заем погашен] 
,   case when @all_columns=1 then a.[Заем аннулирован] end as [Заем аннулирован] 
,   case when @all_columns=1 then a.[Аннулировано] end as [Аннулировано] 
,   case when @all_columns=1 then a.[Отказ документов клиента] end as [Отказ документов клиента] 
,   case when @all_columns=1 then a.[Отказано] end as [Отказано] 
,   case when @all_columns=1 then a.[Отказ клиента] end as [Отказ клиента] 
,   case when @all_columns=1 then a.[Забраковано] end as [Забраковано] 
,   case when @all_columns=1 then a.[ПризнакЗаявка] end as [ПризнакЗаявка] 
,   case when @all_columns=1 then a.[ПризнакПредварительноеОдобрение] end as [ПризнакПредварительноеОдобрение] 
,   case when @all_columns=1 then a.[ПризнакВстречаНазначена] end as [ПризнакВстречаНазначена] 
,   case when @all_columns=1 then a.[ПризнакКонтрольДанных] end as [ПризнакКонтрольДанных] 
,   case when @all_columns=1 then a.[ПризнакКонтрольДанныхИзФактическихВстреч] end as [ПризнакКонтрольДанныхИзФактическихВстреч] 
,   case when @all_columns=1 then a.[ПризнакВерификацияДокументовКлиента] end as [ПризнакВерификацияДокументовКлиента] 
,   case when @all_columns=1 then a.[ПризнакОдобреныДокументовКлиента] end as [ПризнакОдобреныДокументовКлиента] 
,   case when @all_columns=1 then a.[ПризнакВерификацияДокументов] end as [ПризнакВерификацияДокументов] 
,   case when @all_columns=1 then a.[ПризнакОдобрено] end as [ПризнакОдобрено] 
,   case when @all_columns=1 then a.[ПризнакДоговорЗарегистрирован] end as [ПризнакДоговорЗарегистрирован] 
,   case when @all_columns=1 then a.[ПризнакДоговорПодписан] end as [ПризнакДоговорПодписан] 
,   case when @all_columns=1 then a.[ПризнакЗайм] end as [ПризнакЗайм] 
,   case when @all_columns=1 then a.[ПризнакОтказано] end as [ПризнакОтказано] 
,   case when @all_columns=1 then a.[ПризнакОтказКлиента] end as [ПризнакОтказКлиента] 
,   case when @all_columns=1 then a.[ПризнакЗаймДеньВДень] end as [ПризнакЗаймДеньВДень] 
,   case when @all_columns=1 then a.[ПризнакЗаймНеДеньВДень] end as [ПризнакЗаймНеДеньВДень] 
,   case when @all_columns=1 then a.[ПризнакЗабраковано] end as [ПризнакЗабраковано] 
,   case when @all_columns=1 then a.[Признак Отказ документов клиента] end as [Признак Отказ документов клиента] 
,   case when @all_columns=1 then a.[НеПрошлиКД] end as [НеПрошлиКД] 
,   case when @all_columns=1 then a.[ОдобреноНоЗаймНеВыдан] end as [ОдобреноНоЗаймНеВыдан] 
,   case when @all_columns=1 then a.[ВремяОтВерификацияКЦДоВыдачиЧасы] end as [ВремяОтВерификацияКЦДоВыдачиЧасы] 
,   case when @all_columns=1 then a.[НеделяЗаявки] end as [НеделяЗаявки] 
,   case when @all_columns=1 then a.[МесяцЗаявки] end as [МесяцЗаявки] 
,   case when @all_columns=1 then a.[ГодЗаявки] end as [ГодЗаявки] 
,   case when @all_columns=1 then a.[НеделяВыдач] end as [НеделяВыдач] 
,   case when @all_columns=1 then a.[МесяцВыдач] end as [МесяцВыдач] 
,   case when @all_columns=1 then a.[ГодВыдачи] end as [ГодВыдачи] 
,   a.[Канал от источника] 
,   a.[Группа каналов] 
,   a.[Телефон] 
,   case when @all_columns=1 then a.[TTC_number] end as [TTC_number] 
,   case when @all_columns=1 then a.[TTC] end as [TTC] 
,   case when @all_columns=1 then a.[ДатаЗаявкиПолная] end as [ДатаЗаявкиПолная] 
,   case when @all_columns=1 then a.[Дубль] end as [Дубль] 
,   a.фио  [ФИО] 
--,   case when @login  in ( select login from  employees where [доступ к пд]=1 and login is not null) and  a.[Одобрено]  is not null  then a.фио else '' end [ФИО] 
,   case when @all_columns=1 then a.[P2P] end as [P2P] 
,   case when @all_columns=1 then a.[ПризнакP2P] end as [ПризнакP2P] 
,   case when @all_columns=1 then a.[Ссылка заявка] end as [Ссылка заявка] 
,   case when @all_columns=1 then a.[Ссылка клиент] end as [Ссылка клиент] 
,   case when @all_columns=1 then a.[Дата отчета] end as [Дата отчета] 
,   case when @all_columns=1 then a.[СуммаВыдачиБезКП] end as [СуммаВыдачиБезКП] 
,   case when @all_columns=1 then a.[ПризнакКП] end as [ПризнакКП] 
,   case when @all_columns=1 then a.[СуммаДопУслуг] end as [СуммаДопУслуг] 
,   case when @all_columns=1 then a.[ПризнакКаско] end as [ПризнакКаско] 
,   case when @all_columns=1 then a.[ПризнакСтрахованиеЖизни] end as [ПризнакСтрахованиеЖизни] 
,   case when @all_columns=1 then a.[ПризнакРАТ] end as [ПризнакРАТ] 
,   case when @all_columns=1 then a.[ПризнакПозитивНастр] end as [ПризнакПозитивНастр] 
,   case when @all_columns=1 then a.[ПризнакПомощьБизнесу] end as [ПризнакПомощьБизнесу] 
,   case when @all_columns=1 then a.[ПризнакТелемедицина] end as [ПризнакТелемедицина] 
,   case when @all_columns=1 then a.[Признак Защита от потери работы] end as [Признак Защита от потери работы] 
,   case when @all_columns=1 then a.[ПризнакФарма] end as [ПризнакФарма] 
,   case when @all_columns=1 then a.[ПризнакСпокойнаяЖизнь] end as [ПризнакСпокойнаяЖизнь] 
,   case when @all_columns=1 then a.[Признак Рат Юруслуги] end as [Признак Рат Юруслуги] 
,   case when @all_columns=1 then a.[SumKasko] end as [SumKasko] 
,   case when @all_columns=1 then a.[SumEnsur] end as [SumEnsur] 
,   case when @all_columns=1 then a.[SumRat] end as [SumRat] 
,   case when @all_columns=1 then a.[SumPositiveMood] end as [SumPositiveMood] 
,   case when @all_columns=1 then a.[SumHelpBusiness] end as [SumHelpBusiness] 
,   case when @all_columns=1 then a.[SumTeleMedic] end as [SumTeleMedic] 
,   case when @all_columns=1 then a.[SumCushion] end as [SumCushion] 
,   case when @all_columns=1 then a.[SumPharma] end as [SumPharma] 
,   case when @all_columns=1 then a.[SumQuietLife] end as [SumQuietLife] 
,   case when @all_columns=1 then a.[Сумма Рат Юруслуги] end as [Сумма Рат Юруслуги] 
,   case when @all_columns=1 then a.[СуммаДопУслугЗаВычетомПартнерскойКомиссии] end as [СуммаДопУслугЗаВычетомПартнерскойКомиссии] 
,   case when @all_columns=1 then a.[СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net] end as [СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net] 
,   case when @all_columns=1 then a.[ПроцСтавкаКредит] end as [ПроцСтавкаКредит] 
,   case when @all_columns=1 then a.[Группа риска] end as [Группа риска] 
,   case when @all_columns=1 then a.[Группа риска_varchar] end as [Группа риска_varchar] 
,   case when @all_columns=1 then a.[reject_reason] end as [reject_reason] 
,   case when @all_columns=1 then a.[ВозрастНаДатуЗаявки] end as [ВозрастНаДатуЗаявки] 
,   case when @all_columns=1 then a.[СуммарныйМесячныйДоход_CRM] end as [СуммарныйМесячныйДоход_CRM] 
,   case when @all_columns=1 then a.[РегионПроживания] end as [РегионПроживания] 
,   case when @all_columns=1 then a.[ПолКлиента] end as [ПолКлиента] 
,   case when @all_columns=1 then a.[ПризнакПредчекер] end as [ПризнакПредчекер] 
,   case when @all_columns=1 then a.[ЧислоДоработокПредЧекеры] end as [ЧислоДоработокПредЧекеры] 
,   case when @all_columns=1 then a.[ЧислоРучныхПроверокПредчекерами] end as [ЧислоРучныхПроверокПредчекерами] 
,   case when @all_columns=1 then a.[ЭлектроннаяПочта] end as [ЭлектроннаяПочта] 
,   case when @all_columns=1 then a.[Время в отложенных ВД_сек] end as [Время в отложенных ВД_сек] 
,   case when @all_columns=1 then a.[Время в отложенных КД_сек] end as [Время в отложенных КД_сек] 
,   case when @all_columns=1 then a.[Время в отложенных ВДК_сек] end as [Время в отложенных ВДК_сек] 
,   case when @all_columns=1 then a.[offer_details] end as [offer_details] 
,   case when @all_columns=1 then a.[offer] end as [offer] 
,   case when @all_columns=1 then a.[ИспытательныйСрок] end as [ИспытательныйСрок] 
,   case when @all_columns=1 then a.[RBP] end as [RBP] 
,    a.[product]     
,   case when @all_columns=1 then a.[ПризнакРефинансирование] end as [ПризнакРефинансирование] 
,   case when @all_columns=1 then a.[Вариант предложения ставки] end as [Вариант предложения ставки] 
,   a.[Источник] 
,   case when @all_columns=1 then a.[Вебмастер] end as [Вебмастер] 
,   case when @all_columns=1 then a.[Приоритет обзвона] end as [Приоритет обзвона] 
,   case when @all_columns=1 then a.[Юрлицо при создании] end as [Юрлицо при создании] 
,   case when @all_columns=1 then a.[Номер точки при создании] end as [Номер точки при создании] 
,   case when @all_columns=1 then a.[issmartinstallment] end as [issmartinstallment] 
,   case when @all_columns=1 then a.[Видзайма в рамках продукта инстиоллмент] end as [Видзайма в рамках продукта инстиоллмент] 
,   case when @all_columns=1 then a.[СрокЛьготногоПериода] end as [СрокЛьготногоПериода] 

,   case when @all_columns=1 then a.carBrand end as carBrand 
,   case when @all_columns=1 then a.carModel end as carModel 
,   case when @all_columns=1 then a.carYear end as carYear 
,   case when @all_columns=1 then a.vin end as vin  
,   case when @all_columns=1 then a.hasLeadInfoseti end as hasLeadInfoseti  
from 

v a
 



--order by
	--fa1.ДатаЗаявкиПолная

--	exec select_table '#ttttt'


--use tempdb	
--select 'select 
-- '+STRING_AGG(cast(''+'   '+case when x.n is  null then 'case when @all_columns=1 then '+'a.['+ c.name +'] end as '+'['+ c.name +'] '  else 'a.['+ c.name +'] ' end as varchar(max)), '
--,')
--+'

--from 

--'+'#ttttt' +' a'

--from sys.columns c left join
--(
--  select 'Дата' n
--union all select 'Время'
--union all select 'Номер'
--union all select 'Текущий статус'
--union all select 'Место cоздания'
--union all select 'Вид займа'
--union all select 'Первичная сумма'
--union all select 'Сумма одобренная'
--union all select 'Выданная сумма'
--union all select 'Сумма заявки'
--union all select 'Верификация КЦ'
--union all select 'Предварительное одобрение'
--union all select 'Встреча назначена'
--union all select 'Контроль данных'
--union all select 'Call2'
--union all select 'Call2 accept'
--union all select 'Верификация документов клиента'
--union all select 'Одобрены документы клиента'
--union all select 'Верификация документов'
--union all select 'Одобрено'
--union all select 'Договор зарегистрирован'
--union all select 'Договор подписан'
--union all select 'Заем выдан'
--union all select 'Канал от источника'
--union all select 'Группа каналов'
--union all select 'product'
--union all select 'Дубль'
--union all select 'ФИО'
--union all select 'Источник' ) x on c.name=x.n
--where [object_id]=object_id('#ttttt')


end
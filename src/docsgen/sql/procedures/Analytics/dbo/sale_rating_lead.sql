
CREATE PROCEDURE [dbo].[sale_rating_lead] AS

begin


drop table if exists #t1

;
--with st_zv as 
--(
--select [Заявка]                         
--,      Статус                           
--,      min(dateadd(year, -2000, Период)) Дата
--from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] --with(nolock)
--where Статус=0xA81400155D94190011E80784923C60A2--	Верификация КЦ
--group by [Заявка]
--,        Статус
--)

select z.номер                                                                         
,      dateadd(year, -2000, z.Дата)                                                   ДатаЗаявки
,      p.adLogin Оператор
,      trim(replace(replace(p.Наименование, ' (создано при обмене с FEDOR)' ,''), 'ё','е')) ФИОоператора
,      МобильныйТелефон                                                              
,      st_zv_5 .call1                                                                  'Верификация КЦ'
	into #t1
from      stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС    z      
left join stg.[_1cCRM].[Справочник_Пользователи]    p       on z.CRM_Автор=p.Ссылка
join v_request                                   as st_zv_5 on st_zv_5 .link=z.ссылка 
  where dateadd(year, -2000, z.Дата) >= '20220101' and st_zv_5.ispts=1


drop table if exists #chanals
select 'CPA'      [Группа каналов] , 'CPA нецелевой'							   [Для отчета] , 'CPA нецелевой'                       [Канал от источника] into #chanals union all 
select 'CPA'      [Группа каналов] , 'CPA полуцелевой'							   [Для отчета] , 'CPA полуцелевой'                     [Канал от источника] union all 
select 'CPA'      [Группа каналов] , 'CPA целевой'								   [Для отчета] , 'CPA целевой'                         [Канал от источника] union all 
select 'CPC'      [Группа каналов] , 'CPC'										   [Для отчета] , 'CPC Бренд'                           [Канал от источника] union all 
select 'CPC'      [Группа каналов] , 'CPC'										   [Для отчета] , 'CPC Платный'                         [Канал от источника] union all 
select 'Органика' [Группа каналов] , 'Органика'									   [Для отчета] , 'Сайт орган.трафик'                   [Канал от источника] union all 
select 'Органика' [Группа каналов] , 'Органика'									   [Для отчета] , 'Канал привлечения не определен - КЦ' [Канал от источника] union all 
select 'Органика' [Группа каналов] , 'Органика'									   [Для отчета] , 'Канал привлечения не определен - МП' [Канал от источника] union all 
select 'Партнеры' [Группа каналов] , 'Партнеры'									   [Для отчета] , 'Оформление на партнерском сайте'     [Канал от источника] union all 
select 'Партнеры' [Группа каналов] , 'Партнеры'									   [Для отчета] , 'Партнеры (лиды)'                     [Канал от источника] union all 
select 'Тест'     [Группа каналов] , 'Тест'										   [Для отчета] , 'Тест'                                [Канал от источника] union all 
select 'Другое'   [Группа каналов] , 'Другое'									   [Для отчета] , 'Другое'                              [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'Триггеры'									   [Для отчета] , 'Триггеры LCRM'                       [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'Триггеры'									   [Для отчета] , 'Внутренние триггеры'                 [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'Триггеры'									   [Для отчета] , 'Эквифакс'                            [Канал от источника] union all 
select 'CPC'      [Группа каналов] , 'CPC'										   [Для отчета] , 'Медийная реклама'                    [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'Триггеры'									   [Для отчета] , 'НБКИ'                                [Канал от источника] 

  drop table if exists #zayavki

  select 
  distinct Номер, 
  ДатаЗаявкиПолная, 
  cast(format(ДатаЗаявкиПолная , 'yyyy-MM-01') as date) МесяцЗаявки,  
  trim(replace(replace(fa.Автор, ' (создано при обмене с FEDOR)' ,''), 'ё','е')) Автор, 
  Телефон, 
	[Верификация КЦ],
  isnull([Для отчета], case when fa.[Группа каналов]='cpa' then fa.[Канал от источника] else fa.[Группа каналов] end) [Для отчета]
  
,  [Проект] = cast(  null as nvarchar(150)) 
,  Длительность = cast( null as bigint) 
,  [Причина отказа] =  cast(null as nvarchar(150))
  into #zayavki
  from  v_fa fa
  left join #chanals                    rating_chanals  on fa.[Канал от источника]=rating_chanals.[Канал от источника]
  where ispts = 1 and ДатаЗаявкиПолная >= '20220101'


drop table if exists  #CRM_communications_on_requests

select zayav.ссылка                                     СсылкаЗаявка
,      zayav.Номер                                      НомерЗаявки
,      dateadd(year, -2000, zayav.Дата)                 ДатаЗаявки
,      dateadd(year, -2000, zvonki.дата)                ДатаЗвонка
,      zvonki.Ссылка                                    СсылкаЗвонок
,      case when zvonki.Входящий=1 then 'Входящий'
                                   else 'Исходящий' end НаправлениеЗвонкаСтрокой
into #CRM_communications_on_requests
from      [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] zayav with(nolock) 
left join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие] vzaim with(nolock)  on zayav.ссылка = vzaim.[Заявка_Ссылка]
left join [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок]   zvonki with(nolock) on vzaim.Ссылка = zvonki.ВзаимодействиеОснование_Ссылка
where dateadd(year, -2000, zayav.Дата)>='20220101'


drop table if exists #t2

SELECT [СсылкаЗаявка]
      ,[НомерЗаявки]
      ,[ДатаЗаявки]
      ,[СсылкаЗвонок]
     ,[НаправлениеЗвонкаСтрокой]                               
	  ,row_number() over(partition by [СсылкаЗаявка] order by (select null)) rn
	  into #t2
  FROM #CRM_communications_on_requests
  where [СсылкаЗвонок] is not null and  ISNUMERIC([НомерЗаявки])<>1 
  and ДатаЗаявки>= '20220101' and ДатаЗвонка<[ДатаЗаявки] 

delete from #t2 where rn<>1 or [НаправлениеЗвонкаСтрокой]='Исходящий'

drop table if exists #zayavki_otkazi
select Номер                                              
,      #t1.ДатаЗаявки                                     
,      cast(format(#t1.ДатаЗаявки , 'yyyy-MM-01') as date) МесяцЗаявки
,      Оператор                                           
,      ФИОоператора                                       
,      МобильныйТелефон                                   
,      [Верификация КЦ]                                   
,      'CPC' [Канал для отчета] --CPC указан просто потому что
,  [Проект] = cast(  null as nvarchar(150)) 
,  Длительность = cast( null as bigint) 
,  [Причина отказа] =  cast(null as nvarchar(150))
into #zayavki_otkazi
from #t1
join #t2 on #t1.Номер=#t2.НомерЗаявки
where [Верификация КЦ] is null


 drop table if exists #LeadCommunication, #core_user
SELECT dateadd(hour, 3,[CreatedOn]) [CreatedOn]
,      a.id                    
,      [IdLead]                    
,      idowner  
, datediff(SECOND, [CreatedOn], CommunicationEnd) [Длительность]
, b.Name  collate Cyrillic_General_CI_AS  [Причина отказа]
	into #LeadCommunication --select *
FROM [Stg].[_fedor].[core_LeadCommunication] a
left join stg._fedor.dictionary_LeadRejectReason b on a.IdLeadRejectReason=b.Id
where [IdLeadCommunicationResult] in (4 , 16)
	and [CreatedOn] >= dateadd(hour, -3, cast('20220101' as datetime))

	drop table if exists #NaumenProjectId
select a.id
, max(c.Name)   NaumenProject 
into #NaumenProjectId
from
--Feodor.dbo.dm_Lead
--select * from
stg._fedor.core_LeadCommunicationCall a 
join (select distinct id from #LeadCommunication)  b on b.id=a.id
left join Feodor.dbo.dm_feodor_project2 c on a.NaumenProjectId  collate Cyrillic_General_CI_AS =c.IdExternal  collate Cyrillic_General_CI_AS
group by a.id

	--select * from stg._fedor.dictionary_LeadCommunicationResult
	--select * from 	 #LeadCommunication 
	--select *



select * into #core_user from  [Stg].[_fedor].[core_user] #core_user


drop table if exists #dm_lead
select a.lead_id [ID LCRM], Телефон [Номер  телефона], id_feodor [ID лида Fedor], [Кампания наумен] into #dm_lead from v_feodor_leads a
join #LeadCommunication l on a.id_feodor=l.IdLead
where  IsInstallment = 0 
  
  
  
  
drop table if exists #otkazi_leads
  
  
select cast(format( lc.CreatedOn , 'yyyy-MM-01') as date)    МесяцЛида
,      lc.CreatedOn                                          ДатаЛида
,     isnull(st2.phone,  isnull(  st.UF_PHONE , [Номер  телефона])    )            [Номер  телефона]
,      DomainLogin collate Cyrillic_General_CI_AS            Оператор
,       ltrim(rtrim(replace(core_user.LastName+' '+core_user.FirstName +' '+core_user.MiddleName, 'ё', 'е'))) collate  Cyrillic_General_CI_AS             ФИОоператора
,      'отказ по лиду '+cast(dl.[ID LCRM] as varchar(36)) as TypeRefuse
,       isnull(rating_chanals.[Для отчета], 

case
when st.[Группа каналов]='cpa' then st.[Канал от источника] 
when st.[Группа каналов]<>'cpa' then   st.[Группа каналов]  
when st2.channel_group='cpa' then st2.channel else st2.channel_group end



) [Для отчета]
,       [Проект] = cast( isnull(dl.[Кампания наумен],'?')+' ('+  isnull(np.NaumenProject,'?') +')' as nvarchar(150)) 
,       Длительность = cast(lc.Длительность as bigint) 
,       [Причина отказа] =  cast( lc.[Причина отказа] as nvarchar(150))
	into #otkazi_leads
from      #LeadCommunication                 lc             
join      #dm_lead                 dl              on lc.[IdLead]=dl.[ID лида Fedor]
left join stg._LCRM.lcrm_leads_full_calculated st with(nolock) on try_cast(dl.[ID LCRM] as numeric)=st.id
left join v_lead st2 with(nolock) on st2.id=dl.[ID LCRM]
--left join stg._LCRM.lcrm_tbl_short_w_channel st with(nolock) on try_cast(dl.[ID LCRM] as numeric)=st.id /*a.kotelevec 28.08.2022*/
left join #core_user                         core_user       on core_user.id=lc.idowner
left join #chanals                    rating_chanals  on st.[Канал от источника]=rating_chanals.[Канал от источника]  or st2.channel=rating_chanals.[Канал от источника]
	--	and st.[Канал от источника]=rating_chanals.[Канал от источника]
	left join #NaumenProjectId np on np.Id=lc.Id

--	select * from #otkazi_leads

insert into #otkazi_leads
select МесяцЗаявки                                     МесяцЛида
,      ДатаЗаявки                                      ДатаЛида
,      мобильныйтелефон                                [Номер  телефона]
,      Оператор                                        Оператор
,      ФИОоператора                                    ФИОоператора
,      cast('отказ черновик '+Номер as varchar(30)) as TypeRefuse
,      [Канал для отчета]
,  [Проект] = cast(  null as nvarchar(150)) 
,  Длительность = cast( null as bigint) 
,  [Причина отказа] =  cast(null as nvarchar(150))

from #zayavki_otkazi

--select * from #zayavki_otkazi

--drop table if exists #sotr
--
--select Сотрудник, РГ, Направление, adLogin 
--into #sotr
--FROM 
--	[Stg].[files].[сотрудники sales] s
--	join stg.[_1cCRM].[Справочник_Пользователи] p on s.Сотрудник = p.Наименование
--where adLogin is not null 
--order by 1


	;
with v
as
(
	select *                                                                             
	,      row_number() over(partition by [Номер  телефона], МесяцЛида order by ДатаЛида) rn
	from #otkazi_leads
)
delete from v
where rn<>1

drop table if exists #t5

select getdate()                                    as created
,      Номер                                           Номер
,      ДатаЗаявкиПолная                                      Дата
,      МесяцЗаявки                                     Месяц
,      Автор                                        Оператор
,      Автор                                        ФИОоператора
,      Телефон                                МобильныйТелефон
,      [Верификация КЦ]                                [Верификация КЦ]
,        [Для отчета] [Канал для отчета]
, '1' ПризнакЗаявка
,  [Проект]
,  Длительность
,  [Причина отказа]

into #t5
from #zayavki
union all
select getdate()                                      as created
,      TypeRefuse                                     as номер
,      ДатаЛида                                          Дата
,      cast(МесяцЛида as date)                           Месяц
,      a.Оператор                         Оператор
,      a.ФИОоператора                         ФИОоператора
,      [Номер  телефона]                                 МобильныйТелефон
,      null                                           as [Верификация КЦ]
,      a.[Для отчета]   [Канал для отчета]
, '0'
,  a.[Проект]
,  a.Длительность
,  a.[Причина отказа]
from        #otkazi_leads              a left join #zayavki b on a.[Номер  телефона]=b.телефон and a.МесяцЛида=b.МесяцЗаявки
where b.[Верификация КЦ] is null

--select * from #t5
drop table if exists #itog
select Номер,
	Дата,
	Месяц,
	upper(ФИОоператора) ФИОоператора,
	МобильныйТелефон,
	[Канал для отчета],
	case
		when cast(Месяц as varchar(10)) = format(getdate(),'yyyy-MM-01') then 'Текущий месяц' else cast(Месяц as varchar(10))
	end 'Месяц текст',
	РГ,
	Направление,
	ПризнакЗаявка
	,  [Проект]
,  Длительность
,  [Причина отказа]

 into #itog
from #t5 t
left join employee e on t.ФИОоператора = e.Сотрудник
--left join #chanals c on c.[Канал от источника] = [Канал для отчета] 
--
--
--
--declare @report_date date = cast('20221001' as date)
--
--drop table if exists #detalka
--
--SELECT isnull(t.[НомерАналитическойЗаявки],t.[Номер]) Номер
--      ,replace(t.[CRM_АвторНаименование],'Гришина Полина Артемовна','Гришина Полина Артёмовна') [CRM_АвторНаименование]
--      ,t.[ИтоговаяСуммаВыдачиАналитическая]
--	  ,РГ
--	  ,Направление
--	  ,isnull(t.[аналитический_Заем выдан],t.[Заем выдан]) ДатаЗайма
--	  ,isnull(t.ДатаАналитическойЗаявки,t.ДатаЗаявки) ДатаЗаявки
--	  ,isnull(t.[аналитический_Заем аннулирован],t.[Заем аннулирован]) ДатаАннуляции,t.[Заем аннулирован],t.[аналитический_Заем аннулирован]
--  into #detalka
--  FROM [Reports].[dbo].[dm_report_requests_after_month_with_doubles] t
----  left join Reports.dbo.dm_Factor_Analysis fa on t.Номер = fa.Номер
----  left join Reports.dbo.dm_Factor_Analysis fa1 on t.[НомерАналитическойЗаявки] = fa1.Номер
--  	left join [Analytics].[dbo].[employees] e on t.[CRM_АвторНаименование] = e.Сотрудник
--  WHERE МесяцЗаявки>=@report_date and РГ is not null 
--
--drop table if exists #заявки
--
--select 
--	t.Номер
--      ,t.[CRM_АвторНаименование] Оператор
--      ,iif((ДатаАннуляции is not null or ДатаЗайма is null), 0,t.[ИтоговаяСуммаВыдачиАналитическая]) [ИтоговаяСуммаВыдачиАналитическая]
--	  ,t.РГ
--	  ,t.Направление
--	--  ,fa.isInstallment
--	  ,cast(t.ДатаЗаявки as date) ДатаЗаявки
--	  ,t.ДатаЗайма
--	  ,iif(format(t.ДатаЗайма, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗайма, 'yyyy-MM-01')) 'Месяц текст займ выдан'
--	  ,iif(format(t.ДатаЗаявки, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗаявки, 'yyyy-MM-01')) 'Месяц текст заявка'
--into #заявки
--from #detalka t
--	join Reports.dbo.dm_Factor_Analysis fa on t.Номер = fa.Номер
--where fa.isInstallment = 0 
--
--drop table if exists #result
--
--select Оператор,
--	РГ,
--	Направление,
----	isInstallment,
--	[Месяц текст заявка],
--	cast(ДатаЗаявки as date) ДатаЗаявки,
----	count(Номер) Заявок
--	sum(ИтоговаяСуммаВыдачиАналитическая) Выдач
--into #result
--from #заявки
--group by Оператор,
--	РГ,
--	Направление,
--	--isInstallment,
--	[Месяц текст заявка]
--		  ,cast(ДатаЗаявки as date)
--order by [Месяц текст заявка]
--
--drop table if exists #vremy
--
--select d,title
--	,(SUm(Постобработка) + SUm(Готов) + SUm([Время диалога]))*24 ВремяОператор
--into #vremy
--from analytics.dbo._birs_report_naumen_activity_by_login_day t
--	 join [Analytics].[dbo].[employees] e on t. title = e.Сотрудник
--where d >= '20221101'
--group by title,d
--
--drop table if exists #detal_ch
--
--select Оператор, РГ, Направление, [Месяц текст заявка], Выдач,ВремяОператор, ДатаЗаявки, 'Для рублей' Показатель 
--into #detal_ch
--from #result i
--	left join #vremy v  on cast(i.ДатаЗаявки as date) = cast(v.d as date) and i.Оператор = v.title
--	order by Оператор,[Месяц текст заявка]
--
--
--drop table if exists #заявки2
--
--select 
--	t.Номер
--      ,t.[CRM_АвторНаименование] Оператор
--     -- ,iif(ДатаАннуляции is not null,0,t.[ИтоговаяСуммаВыдачиАналитическая]) [ИтоговаяСуммаВыдачиАналитическая]
--	  ,t.РГ
--	  ,t.Направление
--	--  ,fa.isInstallment
--	  ,cast(t.ДатаЗаявки as date) ДатаЗаявки
--	--  ,t.ДатаЗайма
--	--  ,iif(format(t.ДатаЗайма, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗайма, 'yyyy-MM-01')) 'Месяц текст займ выдан'
--	  ,iif(format(t.ДатаЗаявки, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗаявки, 'yyyy-MM-01')) 'Месяц текст заявка'
--into #заявки2
--from #detalka t
--	join Reports.dbo.dm_Factor_Analysis fa on t.Номер = fa.Номер
--where fa.isInstallment = 0 
--
--drop table if exists #result2
--
--select Оператор,
--	РГ,
--	Направление,
----	isInstallment,
----	[Месяц текст займ выдан],
--	[Месяц текст заявка],
--	cast(ДатаЗаявки as date) ДатаЗаявки,
----	cast(ДатаЗайма as date) ДатаЗайма,
--	count(Номер) Заявок
----	sum(ИтоговаяСуммаВыдачиАналитическая) Выдач
--into #result2
--from #заявки2
--group by Оператор,
--	РГ,
--	Направление,
--	--isInstallment,
----	[Месяц текст займ выдан],
--	[Месяц текст заявка]
--		  ,cast(ДатаЗаявки as date)
----	  ,cast(ДатаЗайма as date)
--order by [Месяц текст заявка]
--
--drop table if exists #vremy2
--
--select d,title
--	,(SUm(Постобработка) + SUm(Готов) + SUm([Время диалога]))*24 ВремяОператор
--into #vremy2
--from analytics.dbo._birs_report_naumen_activity_by_login_day t
--	 join [Analytics].[dbo].[employees] e on t. title = e.Сотрудник
--where d >= '20221101'
--group by title,d
--
--drop table if exists #detal_ch2
--
--select Оператор, РГ, Направление, [Месяц текст заявка], Заявок,ВремяОператор, ДатаЗаявки,'Для заявок' Показатель
--into #detal_ch2
--from #result2 i
--	join #vremy v on cast(i.ДатаЗаявки as date) = cast(v.d as date) and i.Оператор = v.title
--	order by Оператор, ДатаЗаявки
--
--drop table if exists #itog2
--select *,'ПТС' Продукт into #itog2 from #detal_ch
--union all 
--select *,'ПТС' Продукт from #detal_ch2
--
--drop table if exists #заявки3
--
--select 
--	t.Номер
--      ,t.[CRM_АвторНаименование] Оператор
--      ,iif((ДатаАннуляции is not null or ДатаЗайма is null), 0,t.[ИтоговаяСуммаВыдачиАналитическая]) [ИтоговаяСуммаВыдачиАналитическая]
--	  ,t.РГ
--	  ,t.Направление
--	--  ,fa.isInstallment
--	  ,cast(t.ДатаЗаявки as date) ДатаЗаявки
--	  ,t.ДатаЗайма
--	  ,iif(format(t.ДатаЗайма, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗайма, 'yyyy-MM-01')) 'Месяц текст займ выдан'
--	  ,iif(format(t.ДатаЗаявки, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗаявки, 'yyyy-MM-01')) 'Месяц текст заявка'
--into #заявки3
--from #detalka t
--	join Reports.dbo.dm_Factor_Analysis fa on t.Номер = fa.Номер
--where fa.isInstallment = 1 
--
--drop table if exists #result3
--
--select Оператор,
--	РГ,
--	Направление,
----	isInstallment,
--	[Месяц текст заявка],
--	cast(ДатаЗаявки as date) ДатаЗаявки,
----	count(Номер) Заявок
--	sum(ИтоговаяСуммаВыдачиАналитическая) Выдач
--into #result3
--from #заявки3
--group by Оператор,
--	РГ,
--	Направление,
--	--isInstallment,
--	[Месяц текст заявка]
--		  ,cast(ДатаЗаявки as date)
--order by [Месяц текст заявка]
--
--drop table if exists #vremy3
--
--select d,title
--	,(SUm(Постобработка) + SUm(Готов) + SUm([Время диалога]))*24 ВремяОператор
--into #vremy3
--from analytics.dbo._birs_report_naumen_activity_by_login_day t
--	 join [Analytics].[dbo].[employees] e on t. title = e.Сотрудник
--where d >= '20221101'
--group by title,d
--
--drop table if exists #detal_ch3
--
--select Оператор, РГ, Направление, [Месяц текст заявка], Выдач,ВремяОператор, ДатаЗаявки, 'Для рублей' Показатель 
--into #detal_ch3
--from #result3 i
--	left join #vremy v  on cast(i.ДатаЗаявки as date) = cast(v.d as date) and i.Оператор = v.title
--	order by Оператор,[Месяц текст заявка]
--
--
--drop table if exists #заявки4
--
--select 
--	t.Номер
--      ,t.[CRM_АвторНаименование] Оператор
--     -- ,iif(ДатаАннуляции is not null,0,t.[ИтоговаяСуммаВыдачиАналитическая]) [ИтоговаяСуммаВыдачиАналитическая]
--	  ,t.РГ
--	  ,t.Направление
--	--  ,fa.isInstallment
--	  ,cast(t.ДатаЗаявки as date) ДатаЗаявки
--	--  ,t.ДатаЗайма
--	--  ,iif(format(t.ДатаЗайма, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗайма, 'yyyy-MM-01')) 'Месяц текст займ выдан'
--	  ,iif(format(t.ДатаЗаявки, 'yyyy-MM-01') = format(getdate(), 'yyyy-MM-01'),'Текущий месяц',format(t.ДатаЗаявки, 'yyyy-MM-01')) 'Месяц текст заявка'
--into #заявки4
--from #detalka t
--	join Reports.dbo.dm_Factor_Analysis fa on t.Номер = fa.Номер
--where fa.isInstallment = 1 
--
--drop table if exists #result4
--
--select Оператор,
--	РГ,
--	Направление,
----	isInstallment,
----	[Месяц текст займ выдан],
--	[Месяц текст заявка],
--	cast(ДатаЗаявки as date) ДатаЗаявки,
----	cast(ДатаЗайма as date) ДатаЗайма,
--	count(Номер) Заявок
----	sum(ИтоговаяСуммаВыдачиАналитическая) Выдач
--into #result4
--from #заявки4
--group by Оператор,
--	РГ,
--	Направление,
--	--isInstallment,
----	[Месяц текст займ выдан],
--	[Месяц текст заявка]
--		  ,cast(ДатаЗаявки as date)
----	  ,cast(ДатаЗайма as date)
--order by [Месяц текст заявка]
--
--drop table if exists #vremy4
--
--select d,title
--	,(SUm(Постобработка) + SUm(Готов) + SUm([Время диалога]))*24 ВремяОператор
--into #vremy4
--from analytics.dbo._birs_report_naumen_activity_by_login_day t
--	 join [Analytics].[dbo].[employees] e on t. title = e.Сотрудник
--where d >= '20221101'
--group by title,d
--
--drop table if exists #detal_ch4
--
--select Оператор, РГ, Направление, [Месяц текст заявка], Заявок,ВремяОператор, ДатаЗаявки,'Для заявок' Показатель
--into #detal_ch4
--from #result4 i
--	join #vremy v on cast(i.ДатаЗаявки as date) = cast(v.d as date) and i.Оператор = v.title
--	order by Оператор, ДатаЗаявки
--
--drop table if exists #itog3
--select *,'Инст' Продукт into #itog3 from #detal_ch3
--union all 
--select *,'Инст' Продукт from #detal_ch4
--
--drop table if exists #itog4
--
--select * into #itog4 from #itog2
--union all 
--select * from #itog3


begin tran
--drop table if exists Analytics.[dbo].[Профильный лид - заявка]
--select * into Analytics.[dbo].[Профильный лид - заявка]
--from #itog


delete from Analytics.[dbo].[Профильный лид - заявка]
insert into Analytics.[dbo].[Профильный лид - заявка]
select * 
from #itog

--delete from Analytics.[dbo].[Профильный лид - заявка_руб в час]
--insert into Analytics.[dbo].[Профильный лид - заявка_руб в час]
--select * from #itog4
----select * from  Analytics.[dbo].[Профильный лид - заявка_руб в час]

commit tran

--select *
--from #itog
--where [Канал для отчета] is null

--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '8818D47B-D208-4D15-A340-10DFAD4139CC'


end
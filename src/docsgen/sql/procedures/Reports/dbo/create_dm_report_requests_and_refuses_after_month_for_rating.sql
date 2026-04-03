
CREATE   proc--exec
[dbo].[create_dm_report_requests_and_refuses_after_month_for_rating]
as
begin
declare @start_date date = dateadd(month, -2 , cast(format(getdate(), 'yyyy-MM-01') as date))

drop table if exists #t1
;
with st_zv as 
(
select [Заявка]                         
,      Статус                           
,      min(dateadd(year, -2000, Период)) Дата
from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] --with(nolock)
where Статус=0xA81400155D94190011E80784923C60A2--	Верификация КЦ
group by [Заявка]
,        Статус
)

select номер                                                                         
,      dateadd(year, -2000, z.Дата)                                                   ДатаЗаявки
,      p.adLogin Оператор
,      replace(replace(p.Наименование, ' (создано при обмене с FEDOR)' ,''), 'ё','е') ФИОоператора
,      МобильныйТелефон                                                              
,      st_zv_5 .дата                                                                  'Верификация КЦ'
	into #t1
from      stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС    z      
left join stg.[_1cCRM].[Справочник_Пользователи]    p       on z.CRM_Автор=p.Ссылка
left join st_zv                                  as st_zv_5 on st_zv_5 .заявка=z.ссылка 
  where dateadd(year, -2000, z.Дата) >= @start_date


drop table if exists #rating_chanals
select 'CPA'      [Группа каналов] , 'CPA new'      [Для рейтинга] , 'CPA нецелевой'                       [Канал от источника] into #rating_chanals union all 
select 'CPA'      [Группа каналов] , 'CPA new'      [Для рейтинга] , 'CPA полуцелевой'                     [Канал от источника] union all 
select 'CPA'      [Группа каналов] , 'CPA standart' [Для рейтинга] , 'CPA целевой'                         [Канал от источника] union all 
select 'CPA'      [Группа каналов] , 'Триггеры'     [Для рейтинга] , 'Триггеры'                            [Канал от источника] union all 
select 'CPC'      [Группа каналов] , 'CPC'          [Для рейтинга] , 'CPC Бренд'                           [Канал от источника] union all 
select 'CPC'      [Группа каналов] , 'CPC'          [Для рейтинга] , 'СPС Платный'                         [Канал от источника] union all 
select 'Органика' [Группа каналов] , 'CPC'          [Для рейтинга] , 'Сайт орган.трафик'                   [Канал от источника] union all 
select 'Органика' [Группа каналов] , 'CPC'          [Для рейтинга] , 'Канал привлечения не определен - КЦ' [Канал от источника] union all 
select 'Органика' [Группа каналов] , 'CPC'          [Для рейтинга] , 'Канал привлечения не определен - МП' [Канал от источника] union all 
select 'Партнеры' [Группа каналов] , 'Партнеры'     [Для рейтинга] , 'Оформление на партнерском сайте'     [Канал от источника] union all 
select 'Партнеры' [Группа каналов] , 'CPA standart' [Для рейтинга] , 'Партнеры (лиды)'                     [Канал от источника] union all 
select 'Тест'     [Группа каналов] , 'Тест'         [Для рейтинга] , 'Тест'                                [Канал от источника] union all 
select 'Другое'   [Группа каналов] , 'Другое'       [Для рейтинга] , 'Другое'                              [Канал от источника] union all 
select 'CPC'      [Группа каналов] , 'CPC'          [Для рейтинга] , 'CPC Платный'                         [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'CPC'          [Для рейтинга] , 'Триггеры LCRM'                       [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'CPC'          [Для рейтинга] , 'Внутренние триггеры'                 [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'CPC'          [Для рейтинга] , 'Эквифакс'                            [Канал от источника] union all 
select 'CPC'      [Группа каналов] , 'CPC'          [Для рейтинга] , 'Медийная реклама'                    [Канал от источника] union all 
select 'Триггеры' [Группа каналов] , 'CPC'          [Для рейтинга] , 'НБКИ'                                [Канал от источника] 



  drop table if exists #zayavki
  select 
  t1.Номер, 
  t1.ДатаЗаявки, 
  cast(format(t1.ДатаЗаявки , 'yyyy-MM-01') as date) МесяцЗаявки,  
  t1.Оператор, 
  t1.ФИОоператора, 
  t1.МобильныйТелефон, 
  t1.[Верификация КЦ],
  isnull(rating_chanals.[Для рейтинга], 'cpc') [Канал для рейтинга_с_учетом_перезаведенных]
  
  into #zayavki
  from #t1 t1
  left join dbo.dm_Factor_Analysis st on st.Номер=t1.Номер 
  left join #rating_chanals rating_chanals  on st.[Группа каналов_перезаведение]=rating_chanals.[Группа каналов]  and st.[Канал от источника_перезаведение]=rating_chanals.[Канал от источника]
  where t1.[Верификация КЦ] is not null

--declare @start_date date = dateadd(month, -2 , cast(format(getdate(), 'yyyy-MM-01') as date))

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
where dateadd(year, -2000, zayav.Дата)>=@start_date




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
  and ДатаЗаявки>= @start_date and ДатаЗвонка<[ДатаЗаявки] 

  delete from #t2 where rn<>1 or [НаправлениеЗвонкаСтрокой]='Исходящий'
  
 drop table if exists #zayavki_otkazi
select Номер                                              
,      #t1.ДатаЗаявки                                     
,      cast(format(#t1.ДатаЗаявки , 'yyyy-MM-01') as date) МесяцЗаявки
,      Оператор                                           
,      ФИОоператора                                       
,      МобильныйТелефон                                   
,      [Верификация КЦ]                                   
,      'cpc'                                               [Канал для рейтинга_с_учетом_перезаведенных] into #zayavki_otkazi
from #t1
join #t2 on #t1.Номер=#t2.НомерЗаявки
where [Верификация КЦ] is null


--declare @start_date date = dateadd(month, -2 , cast(format(getdate(), 'yyyy-MM-01') as date))


 drop table if exists #LeadCommunication, #core_user
SELECT dateadd(hour, 3,[CreatedOn]) [CreatedOn]
,      [IdLead]                    
,      idowner                     

	into #LeadCommunication
FROM [Stg].[_fedor].[core_LeadCommunication]
where [IdLeadCommunicationResult]=4
	and [CreatedOn] >= dateadd(hour, -3, cast(@start_date as datetime))

select * into #core_user from  [Stg].[_fedor].[core_user] #core_user


drop table if exists #dm_lead
select [ID LCRM] [ID LCRM], [Номер  телефона], [ID лида Fedor] into #dm_lead from Feodor.dbo.dm_Lead
where ISNUMERIC([ID LCRM])=1
  drop table if exists #otkazi_leads
  

select cast(format( lc.CreatedOn , 'yyyy-MM-01') as date)    МесяцЛида
,      lc.CreatedOn                                          ДатаЛида
,      isnull([Номер  телефона], st.UF_PHONE)                [Номер  телефона]
,      DomainLogin collate Cyrillic_General_CI_AS            Оператор
,       ltrim(rtrim(replace(core_user.LastName+' '+core_user.FirstName +' '+core_user.MiddleName, 'ё', 'е'))) collate  Cyrillic_General_CI_AS             ФИОоператора
,      cast('отказ по лиду '+dl.[ID LCRM] as varchar(30)) as TypeRefuse
,      [Для рейтинга]                                        [Канал для рейтинга_с_учетом_перезаведенных]
	into #otkazi_leads
from      #LeadCommunication                 lc             
join      #dm_lead                 dl              on lc.[IdLead]=dl.[ID лида Fedor]
left join stg._LCRM.lcrm_leads_full_calculated st with(nolock) on try_cast(dl.[ID LCRM] as numeric)=st.id
--left join stg._LCRM.lcrm_tbl_short_w_channel st with(nolock) on try_cast(dl.[ID LCRM] as numeric)=st.id /*a.kotelevec 28.08.2022*/
left join #core_user                         core_user       on core_user.id=lc.idowner
left join #rating_chanals                    rating_chanals  on st.[Группа каналов]=rating_chanals.[Группа каналов]
		and st.[Канал от источника]=rating_chanals.[Канал от источника]



insert into #otkazi_leads
select МесяцЗаявки                                     МесяцЛида
,      ДатаЗаявки                                      ДатаЛида
,      мобильныйтелефон                                [Номер  телефона]
,      Оператор                                        Оператор
,      ФИОоператора                                    ФИОоператора
,      cast('отказ черновик '+Номер as varchar(30)) as TypeRefuse
,      [Канал для рейтинга_с_учетом_перезаведенных]
from #zayavki_otkazi


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

delete from dbo.[dm_report_requests_and_refuses_after_month_for_rating]

insert into dbo.[dm_report_requests_and_refuses_after_month_for_rating]
select getdate()                                    as created
,      Номер                                           Номер
,      ДатаЗаявки                                      Дата
,      МесяцЗаявки                                     Месяц
,      Оператор                                        Оператор
,      ФИОоператора                                        ФИОоператора
,      МобильныйТелефон                                МобильныйТелефон
,      [Верификация КЦ]                                [Верификация КЦ]
,      [Канал для рейтинга_с_учетом_перезаведенных]    [Канал для рейтинга_с_учетом_перезаведенных]

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
,      a.[Канал для рейтинга_с_учетом_перезаведенных]    [Канал для рейтинга_с_учетом_перезаведенных]
from        #otkazi_leads              a left join #zayavki b on a.[Номер  телефона]=b.МобильныйТелефон and a.МесяцЛида=b.МесяцЗаявки
where b.[Верификация КЦ] is null



end

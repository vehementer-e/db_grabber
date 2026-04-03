-- =============================================
-- exec [sale_report_quality_call_current_month ]   1
-- Author:		Petr Ilin
-- alter date: 28-01-2020
-- Description:	Отчёт для ОКК, звонки из наумена+фёдора и звонки срм+задачи+взаимодействия
--exec msdb.dbo.sp_stop_job  @job_name= 'Analytics._sale_report_quality_call_current_month at 8:30 each 3 hours'--STOP 
--		
-- =============================================
CREATE   PROCEDURE [dbo].[sale_report_quality_call_current_month]
@recreate_table bit = 0
 
AS 

	SET NOCOUNT ON;
	drop table
if exists #mv_employee

	select max([title])  as [ФИО оператора]
	,      [login] as [operator login]
	into #mv_employee
	from NaumenDbReport.dbo.mv_employee
	--from [Reports].[dbo].[mv_NaumenEmployee]

	group by [login]

	--select * from #mv_employee where [ФИО оператора] like '%клок%'

drop table
if exists #Справочник_Пользователи


	select Ссылка, Наименование
	into #Справочник_Пользователи
	from [Stg].[_1cCRM].[Справочник_Пользователи]


	drop table
if exists #Справочник_CRM_ВидыВзаимодействий

	select *
	into #Справочник_CRM_ВидыВзаимодействий
	from 	[Stg].[_1cCRM].[Справочник_CRM_ВидыВзаимодействий] 


		drop table
if exists #Справочник_СтатусыЗаявокПодЗалогПТС

	select *
	into #Справочник_СтатусыЗаявокПодЗалогПТС
	from 	[Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС]



				drop table
if exists #Перечисление_СпособыОформленияЗаявок

	select *
	into #Перечисление_СпособыОформленияЗаявок
	from 	[Stg].[_1cCRM].[Перечисление_СпособыОформленияЗаявок]



					drop table
if exists #Справочник_CRM_ПричиныОтказов

	select *
	into #Справочник_CRM_ПричиныОтказов
	from 	[Stg].[_1cCRM].[Справочник_CRM_ПричиныОтказов]





drop table if exists #agreement
select 
Номер ДоговорНомер, 
ПроцСтавкаКредит, 
ПризнакКаско,
ПризнакСтрахованиеЖизни,
ПризнакРАТ,
ПризнакПозитивНастр,
ПризнакПомощьБизнесу,
ПризнакТелемедицина, 
[Признак Защита от потери работы]--,
into #agreement
from  dbo.dm_factor_analysis
where [Заем выдан] is not null



drop table if exists #dm_calls_history_temp
select ISNULL(lead_id, cast( lcrm_id as nvarchar(36)))	  lcrm_id
,      projecttitle
,      attempt_result
,      speaking_time
,      attempt_start attempt_start
,      phonenumbers
,      title
,      login
,      session_id as id_звонка

	into #dm_calls_history_temp

from [Feodor].[dbo].[dm_calls_history_lf] as nau
where   [speaking_time] is not null
	and [attempt_result] is not null
	and attempt_start>= cast(getdate()-30  as date) --dateadd(month, -1, cast(format(getdate(), 'yyyy-MM-01') as date))



drop table
if exists #dm_lead

select [ID LCRM]
,      [ID лида Fedor]
,      [Номер заявки (договор)]
,      [Статус лида]
,      [Причина непрофильности]
,      Комментарий
,      IsInstallment
,      isPdl
into #dm_lead 
from [Feodor].[dbo].[dm_Lead] with(nolock)



--Берем все лиды которые относятся к этим звонкам

drop table
if exists #dm_Lead_temp
select [ID LCRM]
,      [ID лида Fedor]
,      [Номер заявки (договор)]
,      [Статус лида]
,      [Причина непрофильности]
,      Комментарий
,      IsInstallment
,      isPdl


	into #dm_Lead_temp

from #dm_lead [dm_Lead]
join (select distinct lcrm_id from #dm_calls_history_temp) distinct_lcrm_id on cast(distinct_lcrm_id.lcrm_id as varchar(36))= [dm_Lead].[ID LCRM] 

drop table if exists #LeadCommunicationResult
select id id , name collate Cyrillic_General_CI_AS name  into #LeadCommunicationResult from [Stg].[_fedor].[dictionary_LeadCommunicationResult]

drop table if exists #core_LeadCommunication
select   lc.created CreatedOn
,              try_cast(l.[ID LCRM]                   as nvarchar(36)) [ID LCRM]
,              lc.CommentsLead collate Cyrillic_General_CI_AS Comment
,              lcr.name      LeadCommunicationResultName
,  lc.NaumenCallId	  NaumenCallId
into #core_LeadCommunication
from     v_communication_feodor lc 
join      #dm_Lead_temp                         l   on lc.IdExternal=l.[ID LCRM]
left join #LeadCommunicationResult              lcr on lc.IdLeadCommunicationResult=lcr.id

create clustered index clus_indname on #core_LeadCommunication
(
[ID LCRM]
)


drop table if exists #РезультатКоммуникацииФедор
select id_звонка

, isnull( x0.LeadCommunicationResultName ,  isnull( x.LeadCommunicationResultName , x1.LeadCommunicationResultName) ) РезультатКоммуникацииФедор
, isnull( x0.Comment                     ,  isnull( x.Comment                     , x1.Comment) 				) 		  Comment
		    
into #РезультатКоммуникацииФедор 
from #dm_calls_history_temp ch 
outer apply (select top 1 isnull(LeadCommunicationResultName, '') LeadCommunicationResultName , isnull(Comment, '') Comment, NaumenCallId NaumenCallId from #core_LeadCommunication lc where lc.NaumenCallId=ch.id_звонка  ) x0
outer apply (select top 1 isnull(LeadCommunicationResultName, '') LeadCommunicationResultName , isnull(Comment, '') Comment from #core_LeadCommunication lc where x0.NaumenCallId is null and lc.[ID LCRM]=ch.lcrm_id and lc.CreatedOn<=ch.attempt_start order by lc.CreatedOn desc) x
outer apply (select top 1 LeadCommunicationResultName, Comment from #core_LeadCommunication lc where  x0.NaumenCallId is null and  lc.[ID LCRM]=ch.lcrm_id and lc.CreatedOn>ch.attempt_start order by lc.CreatedOn ) x1


--select * from  	  #РезультатКоммуникацииФедор
--where 	id_звонка = 'node_0_domain_2_nauss_0_1708544491_10617938'


drop table if exists #projects_on_requests
select [Номер заявки (договор)], CompanyNaumen	CompanyNaumen
into #projects_on_requests
from #dm_lead dl
join feodor.dbo.dm_leads_history lh on try_cast(dl.[ID LCRM] as numeric)=lh.ID
where [Номер заявки (договор)] is not null


drop table
if exists #lcrm
select cast(id as nvarchar(36)) id, [Канал от источника]
into #lcrm

from stg._LCRM.lcrm_leads_full_calculated st with(nolock)
--stg._LCRM.lcrm_tbl_short_w_channel st with(nolock) /*a.kotelevec 28.02.2022*/
join #dm_Lead_temp on try_cast(#dm_Lead_temp.[ID LCRM] as numeric)=st.id
insert into  #lcrm

select cast(st.id as nvarchar(36)) id, mch.name [Канал от источника]

from stg._lf.lead st with(nolock)
--stg._LCRM.lcrm_tbl_short_w_channel st with(nolock) /*a.kotelevec 28.02.2022*/
join #dm_Lead_temp on try_cast(#dm_Lead_temp.[ID LCRM] as nvarchar(36))=st.id
left join stg._lf.mms_channel mch on mch.id=st.mms_channel_id



drop table if exists #Документ_ТелефонныйЗвонок_temp

select АбонентКакСвязаться
,      [сфпДлительностьЗвонка]
,      ВзаимодействиеОснование_Ссылка
,      [АбонентПредставление]
,      [Автор]
,      dateadd(year, -2000, [Дата]) [Дата]
,      [Входящий]
,      isnull(zvonki.session_id,  cast('crm - звонок' as nvarchar(64))) as id_звонка

	into #Документ_ТелефонныйЗвонок_temp

from [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] zvonki
where zvonki.[Дата]>=

dateadd(year, 2000,cast(getdate()-30  as date))

--dateadd(year, 2000, dateadd(month, -1, cast(format(getdate(), 'yyyy-MM-01') as date)))
	and zvonki.[сфпДлительностьЗвонка]>0
	and zvonki.Тема not in ('Коллекшн Исходящее', 'Звонок Collection Исходящее')-- and zvonki.Тема not like '%Лидогенератор%' and zvonki.Тема not like '%Телесейлз%'


	insert into #Документ_ТелефонныйЗвонок_temp

	select isnull(phone, '') , isnull( ДлительностьЗвонка, 0) ДлительностьЗвонка , ВзаимодействиеПрикрепленное_Ссылка, isnull( ФИО_клиента , '') 
	--, ФИО_оператора
	,  isnull(b.Ссылка, 0) автор , created, case  Направление  when 'Входящее' then 1 else 0 end, isnull( Session_id, '') Session_id from v_communication_crm a
	left join (select Наименование, max(Ссылка) Ссылка from  #Справочник_Пользователи  group by Наименование ) b on b.Наименование = a.ФИО_оператора
	where created>=cast(getdate()-30  as date) and Звонок_Ссылка is   null
	and  isnull(b.Ссылка, 0) <>0
 
	--select * from dm_okk_calls_currentmonth
	--where [Номер клиента] like '%9012892615%'


	
	--select * from [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] zvonki
	--where АбонентКакСвязаться like '%9012892615%'
	--order by 3 


	--select * from v_communication_crm
	--where phone like '%9012892615%'
	--order by created



drop table if exists #Документ_CRM_Взаимодействие

select Ссылка, Заявка_Ссылка, Содержание, Результат, Комментарий, СтатусЗаявки, Задача, ВидВзаимодействия
into #Документ_CRM_Взаимодействие
from [Stg].[_1cCRM].[Документ_CRM_Взаимодействие]
join (select distinct ВзаимодействиеОснование_Ссылка from #Документ_ТелефонныйЗвонок_temp) dist_vz on dist_vz.ВзаимодействиеОснование_Ссылка=[Документ_CRM_Взаимодействие].Ссылка

--select * from stg._1ccrm. Справочник_тмТипыКредитногоПродукта

drop table if exists #Документ_ЗаявкаНаЗаймПодПТС
select 
[Документ_ЗаявкаНаЗаймПодПТС].Ссылка, 
[Документ_ЗаявкаНаЗаймПодПТС].Лид, 
[Документ_ЗаявкаНаЗаймПодПТС].НомерЗаявки, 
[Документ_ЗаявкаНаЗаймПодПТС].ПричинаОтказа, 
[Документ_ЗаявкаНаЗаймПодПТС].Номер, 
[Документ_ЗаявкаНаЗаймПодПТС].СпособОформления, 
[Документ_ЗаявкаНаЗаймПодПТС].ВариантПредложенияСтавки, 
[Документ_ЗаявкаНаЗаймПодПТС].ПроцентнаяСтавкаПоПродукту, 
[Документ_ЗаявкаНаЗаймПодПТС].ИспытательныйСрок, 
cast(       case when ТипКредитногоПродукта=0xB82B00505683F1EC11EE4E5200BD1088 then 1 else 0 end   as bit) [Признак заявка Инстоллмент], 
cast(case when ТипКредитногоПродукта=0xB82B00505683F1EC11EE4E51B133AA86 then 1 else 0 end  as bit) [Признак заявка ПДЛ], 
cast(case when ТипКредитногоПродукта  in (0xB377FCBE5CD0EB7011F0326D4CA15320, 0xB37CAAC48ED8B6A211F0921A83846AC5)  then 1 else 0 end  as bit) [Признак заявка Большой инстоллмент], 
[Документ_ЗаявкаНаЗаймПодПТС].Статус--,  

into #Документ_ЗаявкаНаЗаймПодПТС from
[Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] [Документ_ЗаявкаНаЗаймПодПТС]

drop table if exists #Документ_CRM_Заявка
drop table if exists #distinct_Заявка_Ссылка
drop table if exists #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
drop table if exists #Документ_ЗаявкаНаЗаймПодПТС_temp


select distinct Заявка_Ссылка into #distinct_Заявка_Ссылка from #Документ_CRM_Взаимодействие

select
[Документ_CRM_Заявка].КаналПривлеченияСтрокой, 
[Документ_CRM_Заявка].Ссылка--, 
into #Документ_CRM_Заявка
from [Stg].[_1cCRM].[Документ_CRM_Заявка]
join #distinct_Заявка_Ссылка v on v.Заявка_Ссылка=[Документ_CRM_Заявка].Ссылка



select 
[Документ_ЗаявкаНаЗаймПодПТС].Ссылка, 
[Документ_ЗаявкаНаЗаймПодПТС].Лид, 
[Документ_ЗаявкаНаЗаймПодПТС].НомерЗаявки, 
[Документ_ЗаявкаНаЗаймПодПТС].ПричинаОтказа, 
[Документ_ЗаявкаНаЗаймПодПТС].СпособОформления, 
[Документ_ЗаявкаНаЗаймПодПТС].Статус, 
[Документ_ЗаявкаНаЗаймПодПТС].ПроцентнаяСтавкаПоПродукту, 
msozdz.[Представление] [Место создания заявки],
naimst.Наименование [Статус заявки],
protk.НаименованиеПолное [Причина отказа/непрофильности],
fa.RBP RBP,
[Признак заявка Инстоллмент],
[Признак заявка ПДЛ],
[Признак заявка Большой инстоллмент], 
case when [Документ_ЗаявкаНаЗаймПодПТС].ИспытательныйСрок=1 then 1 end as ИспытательныйСрок,
[Контроль данных],
Место_создания_2

into #Документ_ЗаявкаНаЗаймПодПТС_temp
from #Документ_ЗаявкаНаЗаймПодПТС [Документ_ЗаявкаНаЗаймПодПТС]
left join #distinct_Заявка_Ссылка v on v.Заявка_Ссылка=[Документ_ЗаявкаНаЗаймПодПТС].Ссылка
left join  #Документ_CRM_Заявка  v1 on v1.Ссылка=[Документ_ЗаявкаНаЗаймПодПТС].Лид
left join (select distinct [Номер заявки (договор)] from #dm_Lead_temp) distinct_requests_from_dm_lead on distinct_requests_from_dm_lead.[Номер заявки (договор)]=[Документ_ЗаявкаНаЗаймПодПТС].Номер
left join  #Справочник_СтатусыЗаявокПодЗалогПТС     naimst        on [Документ_ЗаявкаНаЗаймПодПТС].[Статус]=naimst.[Ссылка]
left join  #Перечисление_СпособыОформленияЗаявок    msozdz        on [Документ_ЗаявкаНаЗаймПодПТС].[СпособОформления]=msozdz.[Ссылка]
left join  #Справочник_CRM_ПричиныОтказов        as protk         on protk.[Ссылка]=[Документ_ЗаявкаНаЗаймПодПТС].[ПричинаОтказа]
left join  dm_Factor_Analysis fa on fa.[Ссылка заявка]=[Документ_ЗаявкаНаЗаймПодПТС].Ссылка

 where v.Заявка_Ссылка is not null or v1.Ссылка is not null or distinct_requests_from_dm_lead.[Номер заявки (договор)] is not null



 select 

 #Документ_ЗаявкаНаЗаймПодПТС.НомерЗаявки
,#Справочник_СтатусыЗаявокПодЗалогПТС.Наименование НазваниеСтатуса
,dateadd(year, -2000, РегистрСведений_СтатусыЗаявокНаЗаймПодПТС.Период) Период
 into #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
 from stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
 join #Документ_ЗаявкаНаЗаймПодПТС on РегистрСведений_СтатусыЗаявокНаЗаймПодПТС.Заявка=#Документ_ЗаявкаНаЗаймПодПТС.Ссылка
 join #Справочник_СтатусыЗаявокПодЗалогПТС on #Справочник_СтатусыЗаявокПодЗалогПТС.Ссылка=РегистрСведений_СтатусыЗаявокНаЗаймПодПТС.Статус


 create index i on #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС (НомерЗаявки, Период)

 --select 1
drop table if exists #crm_part

select [Дата и время звонка]                                           = zvonki.Дата                                                                     
,      [Название проекта]                                              = typevz.[Наименование]                                                                                                       
,      [Название задачи]                                               = vzaim.[Содержание]                                                                                                                                      
,      [Канал привлечения лида]                                        = leads.[КаналПривлеченияСтрокой]                                                                                       
,      [ФИО оператора]                                                 = users.[Наименование]                                                                                                           
,      [Направление звонка (вход/исход)]                               = case when typevz.[Наименование] like '%Входящий%' then 'Входящий'
                                                                                             else case when zvonki.[Входящий]=1 then 'Входящий'
	                                                                                                   when zvonki.[Входящий]=0 then 'Исходящий' end end
,      [Длительность звонка]                                           = zvonki.[сфпДлительностьЗвонка]                                                                                           
,      [Номер клиента]                                                 = zvonki.АбонентКакСвязаться                                                                                                     
,      [ФИО клиента]                                                   = zvonki.[АбонентПредставление]                                                                                                    
,      [Результат взаимодействия]                                      = vzaim.[Результат]--+zad.[CRM_ВариантВыполненияСтрокой]                                                              
,      [Причина отказа/непрофильности]                                 = zayav.[Причина отказа/непрофильности]                                                                                     
,      [Комментарий]                                                   = vzaim.[Комментарий]                                                                                                              
,      [Номер заявки]                                                  = isnull(zayav.[НомерЗаявки], zayav_on_lead.[НомерЗаявки])                                                                        
,      [Кампания наумен]                                               = projects_on_requests.CompanyNaumen                                                                     
,      [Текущий статус заявки]                                         = zayav.[Статус заявки]                                                                                                          
,      [Статус заявки перед звонком]                                   = x.НазваниеСтатуса                                                                                                          
,      [Дата статуса заявки перед звонком]                             = x.Период                                                                                                          
,      [Место создания заявки]                                         = zayav.[Место создания заявки]               
,      RBP                                                             = zayav.RBP
,      ИспытательныйСрок                                               = zayav.ИспытательныйСрок
,      ПроцентнаяСтавка                                                = zayav.ПроцентнаяСтавкаПоПродукту                           
,      ПроцентнаяСтавкаВыдачи                                          = ПроцСтавкаКредит                           
,      ПризнакКаско                                                    = ПризнакКаско
,      ПризнакСтрахованиеЖизни                                         = ПризнакСтрахованиеЖизни
,      ПризнакРАТ                                                      = ПризнакРАТ
,      ПризнакПозитивНастр                                             = ПризнакПозитивНастр
,      ПризнакПомощьБизнесу                                            = ПризнакПомощьБизнесу
,      ПризнакТелемедицина                                             = ПризнакТелемедицина 
,      [Признак Защита от потери работы]                               = [Признак Защита от потери работы]
,      КД = [Контроль данных]
,      Место_создания_2 = Место_создания_2
,      [Признак заявка Инстоллмент]                                   = isnull(zayav.[Признак заявка Инстоллмент], zayav_on_lead.[Признак заявка Инстоллмент])
,      [Признак заявка ПДЛ]                                   = isnull(zayav.[Признак заявка ПДЛ], zayav_on_lead.[Признак заявка ПДЛ])
,      [Признак заявка Большой инстоллмент]                                   = isnull(zayav.[Признак заявка Большой инстоллмент], zayav_on_lead.[Признак заявка Большой инстоллмент])
,      id_звонка =  id_звонка


	into #crm_part

from       #Документ_ТелефонныйЗвонок_temp                          zvonki       
left join #Документ_CRM_Взаимодействие            vzaim         on vzaim.Ссылка=zvonki.ВзаимодействиеОснование_Ссылка
left join  #Документ_ЗаявкаНаЗаймПодПТС_temp             zayav         on zayav.Ссылка=vzaim.[Заявка_Ссылка]
left join  #agreement             agreement          on agreement.ДоговорНомер=zayav.НомерЗаявки
left join  #projects_on_requests             projects_on_requests          on zayav.НомерЗаявки=projects_on_requests.[Номер заявки (договор)]
left join  #Документ_CRM_Заявка                    leads         on leads.Ссылка=vzaim.[Заявка_Ссылка]
left join  #Документ_ЗаявкаНаЗаймПодПТС             zayav_on_lead on zayav_on_lead.Лид=leads.Ссылка
left join  #Справочник_Пользователи              as users         on zvonki.[Автор]=users.[Ссылка]
left join  #Справочник_CRM_ВидыВзаимодействий    as typevz        on typevz.[Ссылка]=vzaim.[ВидВзаимодействия]
outer apply (select top 1 Период, НазваниеСтатуса from #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС st where st.НомерЗаявки=zayav.НомерЗаявки and Период<= zvonki.Дата order by  Период desc) x




drop table if exists #feodor_part


select [Дата и время звонка]                                          = [attempt_start]          
,      [Название проекта]                                             = [projecttitle]                                         
,      [Название задачи]                                              = 'Лидген'                                                
,      [Канал привлечения лида]                                       = [Канал от источника]                                 
,      [ФИО оператора]                                                = [ФИО оператора]                                           
,      [Направление звонка (вход/исход)]                              = 'Исходящий'                             
,      [Длительность звонка]                                          = [speaking_time]                                     
,      [Номер клиента]                                                = [phonenumbers]                                            
,      [ФИО клиента]                                                  = [title]                                                     
,      [Результат взаимодействия]                                     = isnull (#РезультатКоммуникацииФедор.РезультатКоммуникацииФедор ,
                                                                        case when [attempt_result]='amd'                  then 'Автоответчик'
                                                                             when [attempt_result]='CallDisconnect'       then 'Звонок Разъеденился'
                                                                             when [attempt_result]='ClientRefuse'         then 'Отказ клиента'
                                                                             when [attempt_result]='complaint'            then 'Жалоба'
                                                                             when [attempt_result]='connected'            then Feodor.[Статус лида]
                                                                             when [attempt_result]='Consent'              then 'Заявка'
                                                                             when [attempt_result]='consultation'         then 'Консультация'
                                                                             when [attempt_result]='CRR_DISCONNECT'       then Feodor.[Статус лида]
                                                                             when [attempt_result]='CRR_UNAVAILABLE'      then Feodor.[Статус лида]
                                                                             when [attempt_result]='MP'                   then 'Отправлен в МП'
                                                                             when [attempt_result]='nonTarget'            then 'Нецелевой'
                                                                             when [attempt_result]='recallRequest'        then 'Просьба перезвонить'
                                                                             when [attempt_result]='refuseClient'         then 'Отказ клиента'
                                                                             when [attempt_result]='temporaryUnavaliable' then 'Временно недоступен'
                                                                             when [attempt_result]='Thinking'             then 'Думает'
                                                                             when [attempt_result]='UNKNOWN_ERROR'        then Feodor.[Статус лида]
                                                                             when [attempt_result]='wrongPhoneOwner'      then 'Не тот владелец номера' end )
,      [Причина отказа/непрофильности]                                 = [Причина непрофильности]                  
,      [Комментарий]                                                   = Comment                                                 
,      [Номер заявки]                                                  = feodor.[Номер заявки (договор)]            
,      [Кампания наумен]                                               = projects_on_requests.CompanyNaumen                                                                     
,      [Текущий статус заявки]                                         = z_crm.[Статус заявки]   
,      [Статус заявки перед звонком]                                   = x.НазваниеСтатуса                                                                                                          
,      [Дата статуса заявки перед звонком]                             = x.Период    
,      [Место создания заявки]                                         = z_crm.[Место создания заявки]                                 
,      RBP                                                             = z_crm.RBP
,      ИспытательныйСрок                                                             = z_crm.ИспытательныйСрок

,      ПроцентнаяСтавка                                                = z_crm.ПроцентнаяСтавкаПоПродукту                           
,      ПроцентнаяСтавкаВыдачи                                          = ПроцСтавкаКредит     

,      ПризнакКаско                                                    = ПризнакКаско
,      ПризнакСтрахованиеЖизни                                         = ПризнакСтрахованиеЖизни
,      ПризнакРАТ                                                      = ПризнакРАТ
,      ПризнакПозитивНастр                                             = ПризнакПозитивНастр
,      ПризнакПомощьБизнесу                                            = ПризнакПомощьБизнесу
,      ПризнакТелемедицина                                             = ПризнакТелемедицина 
,      [Признак Защита от потери работы]                               = [Признак Защита от потери работы]
, КД = [Контроль данных]
, Место_создания_2 = Место_создания_2
, [Признак заявка Инстоллмент] = isnull(feodor.IsInstallment , [Признак заявка Инстоллмент])
, [Признак заявка ПДЛ] = isnull(feodor.isPdl , [Признак заявка ПДЛ]) 
, [Признак заявка Большой инстоллмент] = [Признак заявка Большой инстоллмент]
, id_звонка =  nau.id_звонка
	into #feodor_part
from      #dm_calls_history_temp as nau      
left join #mv_employee as imena     on nau.[login]=imena.[operator login]
-------------------ФИО сотрудников
left join #dm_Lead_temp as feodor    on cast(nau.lcrm_id as nvarchar(36))=feodor.[ID LCRM]
left join #Документ_ЗаявкаНаЗаймПодПТС_temp z_crm on z_crm.НомерЗаявки=feodor.[Номер заявки (договор)]
left join  #agreement             agreement          on agreement.ДоговорНомер=feodor.[Номер заявки (договор)]

left join  #projects_on_requests             projects_on_requests          on feodor.[Номер заявки (договор)]=projects_on_requests.[Номер заявки (договор)]

--------------------Получение каналов
left join #lcrm lcrm      on lcrm.ID=  nau.lcrm_id  
left join #РезультатКоммуникацииФедор       on #РезультатКоммуникацииФедор.id_звонка=nau.id_звонка
outer apply (select top 1 Период, НазваниеСтатуса from #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС st where st.НомерЗаявки=feodor.[Номер заявки (договор)] and st.Период<= nau.attempt_start order by  st.Период desc) x






--select * from (
--select * from  #crm_part union all
--select * from #feodor_part
--) a
--where 	 a.[Номер клиента]  like '%9082000828%'
--where [Признак заявка ПДЛ]=1       and    [Номер заявки] is null

--check													  
--select top 0 * into #tttt from 	reports.dbo.dm_okk_calls_currentmonth
--insert into #tttt
--select * from  #crm_part union all
--select * from #feodor_part
--select * from  #tttt


begin tran

if @recreate_table = 1
begin
begin tran
drop table if exists analytics.dbo.dm_okk_calls_currentmonth
select top 0 * 
into analytics.dbo.dm_okk_calls_currentmonth
          from --drop table 
		  #crm_part
union all
select *  
          from --drop table 
		  #feodor_part
commit tran
end


delete from analytics.dbo.dm_okk_calls_currentmonth
insert into analytics.dbo.dm_okk_calls_currentmonth
select * from  #crm_part union all
select * from #feodor_part

commit tran

exec python 'get_refreshed_excel(r"G:\Общие диски\Commercial Team\Product\Аналитика\Отчеты\OKK Звонки\ОКК. Звонки за два последних месяца (с подключением) ver.2025.xlsx"
, rf"G:\Общие диски\Commercial Team\Product\Аналитика\Отчеты\OKK Звонки\{get_current_dt_str()}_ОКК. Звонки за два последних месяца (с подключением) ver.2025.xlsx" )'



 

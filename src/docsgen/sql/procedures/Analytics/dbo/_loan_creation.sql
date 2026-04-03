

CREATE   proc --exec
 [dbo].[_loan_creation]
 as

begin

set nocount off;

drop table if exists #docredy_history
select код, [Дата первого предложения докредитования],  [Лимит первого предложения докредитования]  into #docredy_history 
from (
select  external_id код,  cdate [Дата первого предложения докредитования], main_limit [Лимит первого предложения докредитования], ROW_NUMBER() over(partition by external_id order by cdate) rn

from dwh2. [marketing].[docredy_pts]  
--from dwh2.dbo.v_risk_docredy_history 
--dwh_new.dbo.docredy_history изменил котелевец А.В.
where  category<>'Красный' and main_limit>0 

) a where rn=1
--select * from #docredy_history
--order by 1 desc

drop table if exists #povt_history
select код, [Дата первого предложения повторного займа],  [Лимит первого предложения повторного займа]  into #povt_history 
from (
select  external_id код,  cdate [Дата первого предложения повторного займа], main_limit [Лимит первого предложения повторного займа], ROW_NUMBER() over(partition by external_id order by cdate) rn
from dwh_new.dbo.povt_history
where  category<>'Красный' and main_limit>0 

) a where rn=1
--select * from #docredy_history
--order by 1 desc

drop table if exists #Справочник_Договоры

select [Ссылка договор CMR]    [Ссылка договор CMR]
,      [Код]				   [Код]
,      [Номер заявки]		   [Номер заявки]
,      [Дата договора]		   [Дата договора]
,      cast([Дата договора]		   as date) [Дата договора день]
,      cast(format( [Дата договора]  , 'yyyy-MM-01') as date) [Дата договора месяц]
,      [Дата заявки]		   [Дата заявки]
,      [Сумма]				   [Сумма]
,      Срок					   Срок
,      [Телефон договор CMR]   [Телефон договор CMR]
,      CRMClientGUID		   CRMClientGUID
,      isInstallment           isInstallment

, [Зарегистрирован]            [Зарегистрирован]
, [Действует] 				   [Действует]
, [Дата выдачи] 				=   [Действует]
, [Дата выдачи день] 				=   cast([Действует] as date)
, [Дата выдачи месяц] 				=   cast(format( [Действует]  , 'yyyy-MM-01') as date)  
, [Погашен]					  = isnull([Погашен]	, [Продан])
, [Дата погашения] =					   isnull([Погашен]	, [Продан])
, [Дата погашения день] =					   cast(isnull([Погашен]	, [Продан]) as date)
, [Дата погашения месяц] =					   cast(format( isnull([Погашен]	, [Продан])  , 'yyyy-MM-01') as date)  
, [Legal]					   [Legal]
, [Аннулирован]				   [Аннулирован]
, [Решение Суда]			   [Решение Суда]
, [Приостановка Начислений]	   [Приостановка Начислений]
, [Продан]					   [Продан]
, [Проблемный]				   [Проблемный]
, [ПлатежОпаздывает]		   [ПлатежОпаздывает]
, [Просрочен]				   [Просрочен]
, [Внебаланс]				   [Внебаланс]


, [Дата документа выдача денежных средств]   [Дата документа выдача денежных средств]
, [Дата выдачи ДС]							 [Дата выдачи ДС]
, [Платежная система]						 [Платежная система]
, [Сумма клиенту на руки]					 [Сумма клиенту на руки]
, [Способ выдачи ДС]						 [Способ выдачи ДС]
, [Ссылка на выдачу ДС]						 [Ссылка на выдачу ДС]
, регион

, trim(фамилия)  фамилия
,trim( имя) имя
, trim(Отчество ) Отчество
, ДатаРождения
, СерияНомерПаспорта СерияНомерПаспорта
, productType





	into #Справочник_Договоры
from v_Справочник_Договоры
--where Действует is not null
delete from #Справочник_Договоры
where Действует is  null

--drop table if exists #statuses
--
--select Договор                           Договор
--,      Статус                            Статус
--,      dateadd(year, -2000, min(Период)) Период
--
--	into #statuses
--from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
--group by Договор
--,        Статус



  drop table if exists #pep_3_loans
  select Номер 
  into #pep_3_loans
  from reports.dbo.dm_report_pep3_loans_sales_info
  
  

  drop table if exists #mfo_loans
  select Номер , cl.Наименование [Агент партнер]
  into #mfo_loans
  from stg._1cMFO.Документ_ГП_Договор d
  left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o with (nolock) on d.[Точка]=o.[Ссылка]
  left join [Stg].[_1cMFO].[Справочник_Контрагенты] cl with (nolock) on o.[Партнер]=cl.[Ссылка]
  

drop table if exists #feodor_requests
SELECT Number collate Cyrillic_General_CI_AS Number, Position collate Cyrillic_General_CI_AS Position, IdLoanPurpose
into #feodor_requests
  FROM [Stg].[_fedor].[core_ClientRequest]


drop table if exists #mfo_requests
  select Номер , Должность, РыночнаяСтоимостьАвтоНаМоментОценки   , ТранспортноеСредство , VIN , МаркаАвто , МодельАвто  , ГодАвто, ЦельЗайма, Регион
  into #mfo_requests
  from stg._1cMFO.Документ_ГП_Заявка 
  


  drop table if exists [#Цели займов]		
		
CREATE TABLE [#Цели займов]		
(       [Номер] [NVARCHAR](14)   		
, [Цель займа] [NVARCHAR](250) 		
, priority_source int		
		
);		
		
		
insert into [#Цели займов]		
  		
select  r.Number collate Cyrillic_General_CI_AS Number		
      , Name collate Cyrillic_General_CI_AS  [Цель займа]		
	  , 1 as priority_source	
		
from Stg._fedor.core_CheckListItem  a 		
join (		
select  id from Stg._fedor.dictionary_CheckListItemType		
where name = 'Цель займа'		
) b 		
on a.IdType=b.Id		
join Stg._fedor.dictionary_CheckListItemStatus c on c.id=a.IdStatus		
left join Stg._fedor.core_ClientRequest r on r.id=a.IdClientRequest		
		
		
		
drop table if exists #LoanPurpose		
--select top 1000 * into #LoanPurpose from [PRODSQL02].[fedor.core].dictionary.LoanPurpose		
select  0 id, '' name into #LoanPurpose --from [PRODSQL02].[fedor.core].dictionary.LoanPurpose		
		
insert into [#Цели займов]		
select r.Number collate Cyrillic_General_CI_AS Number		
, lp.name  [Цель займа]		
, 2 as priority_source		
		
from  #feodor_requests r join #LoanPurpose lp on r.IdLoanPurpose=lp.id		
		
		
insert into [#Цели займов]		
		
select Номер		
, cz.Наименование		
, 3 as priority_source		
		
from  #mfo_requests z join stg._1cmfo.Справочник_ГП_ЦелиЗаймов cz on cz.Ссылка=z.ЦельЗайма		



		
insert into [#Цели займов]		
		
select [Номер заявки]		
, null
, 4 as priority_source		
		
from  #Справочник_Договоры	






		
;		
with v as (		
select *, ROW_NUMBER() over(partition by Номер order by priority_source) rn from [#Цели займов]		
) delete from v where rn>1		
;

drop table if exists [#Цели займов аналитические]
		
select a.*, isnull(b.[Цель займа аналитическая], 'Другое') [Цель займа аналитическая] into [#Цели займов аналитические] 
from [#Цели займов] a left join stg.files.[цели займов_stg] b on a.[Цель займа]=b.[Цель займа]

--select * from [#Цели займов аналитические]
		;





drop table if exists #crm_requests
  select Номер , АдресПроживания, year(ГодВыпуска)-2000 ГодВыпускаАвто
  
  into #crm_requests
  from stg._1ccrm.[Документ_ЗаявкаНаЗаймПодПТС] 
  

drop table if exists #deals
select number     [Номер договора Спейс]
,      idcustomer [id клиента Спейс]
,      cs.Name    [Стадия договора Спейс]
,      ds.Name    [Статус договора Спейс]

into #deals
from      stg._Collection.Deals           d 
left join stg._Collection.collectingStage cs on cs.id=d.StageId
left join stg._Collection.DealStatus      ds on ds.id=d.IdStatus
  ;with v  as (select *, row_number() over(partition by [Номер договора Спейс] order by (select null)) rn from #deals ) delete from v where rn>1


  


drop table if exists #customers
select c.id [id клиента Спейс]
,      c.MobilePhone [Телефон клиента Спейс]
,      CrmCustomerId  [CRMClientGUID Спейс]
,      cs.Name   [Стадия клиента Спейс]
into #customers
from      stg._Collection.customers       c 
left join stg._Collection.collectingStage cs on cs.id=c.IdCollectingStage
--select * from  stg._Collection.customers d


  
drop table if exists #current_percent
; with r as (select pd.Договор 
                  , max(Период) max_p
               from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
               join #Справочник_Договоры d on  d.[Ссылка договор CMR]=pd.Договор
              group by  pd.Договор--,Код
            )
    select pd.договор
		 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end [Текущая процентная ставка]
      into #current_percent
      from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
      join r on r.Договор=pd. Договор and r.max_p=pd.Период


drop table if exists #percent_14days
;with r as (select pd.Договор 
                  , max(Период) max_p
               from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
               join #Справочник_Договоры d on  d.[Ссылка договор CMR]=pd.Договор and cast(dateadd(year, -2000, pd.Период) as date) between [Дата договора день] and dateadd(day, 13,[Дата договора день])
              group by  pd.Договор--,Код
            )
    select pd.договор
		 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end [Последняя процентная ставка 14 дней]
      into #percent_14days
      from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
      join r on r.Договор=pd. Договор and r.max_p=pd.Период


  
drop table if exists #first_percent
; with r as (select pd.Договор 
                  , min(Период) min_p
               from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
               join #Справочник_Договоры d on  d.[Ссылка договор CMR]=pd.Договор
              group by  pd.Договор--,Код
            )
    select pd.договор
		 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end [Первая процентная ставка]
      into #first_percent
      from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
      join r on r.Договор=pd. Договор and r.min_p=pd.Период


drop table if exists #tvr
select external_id, return_type into #tvr from dwh_new.dbo.tmp_v_requests
;with v  as (select *, row_number() over(partition by external_id order by (select null)) rn from #tvr ) delete from v where rn>1

drop table if exists #loginom_return_type
select try_cast(number as nvarchar(20)) number, return_type into #loginom_return_type from dwh_new.dbo.risk_apr_segment
;with v  as (select *, row_number() over(partition by number order by (select null)) rn from #loginom_return_type ) delete from v where rn>1

drop table if exists #fa
select Номер                                                     
,      [Вид займа]                                                   
,      product                                                   
,      [Сумма комиссионных продуктов]                        =   [Сумма Дополнительных Услуг]                                             
,      [Сумма комиссионных продуктов Carmoney]               =   [Сумма Дополнительных Услуг Carmoney]                                     
,      [Сумма комиссионных продуктов Carmoney Net]           =   [Сумма Дополнительных Услуг Carmoney Net]  
,      [Признак каско]                                       =   [Признак Каско]
,      [Признак страхование жизни]                           =   [Признак Страхование Жизни]
,      [Признак РАТ]                                         =   [Признак РАТ]
,      [Признак помощь бизнесу]                              =   [Признак Помощь Бизнесу]
,      [Признак телемедицина]                                =   [Признак Телемедицина]
,      [Признак защита от потери работы]                     =   [Признак Защита от потери работы]
,      [Признак фарма]                                       =   [Признак Фарма]
,      [Признак cпокойная жизнь]                             =   [Признак Спокойная Жизнь]
,      [Сумма каско]                                         =   [Сумма КАСКО]
,      [Сумма каско Carmoney]                                =   [Сумма КАСКО Carmoney]
,      [Сумма каско Carmoney Net]                            =   [Сумма КАСКО Carmoney Net]
,      [Сумма страхование жизни]                             =   [Сумма страхование жизни]
,      [Сумма страхование жизни Carmoney]                    =   [Сумма страхование жизни Carmoney]
,      [Сумма страхование жизни Carmoney Net]                =   [Сумма страхование жизни Carmoney Net]
,      [Сумма РАТ]                                           =   [Сумма РАТ]
,      [Сумма РАТ Carmoney]                                  =   [Сумма РАТ Carmoney]
,      [Сумма РАТ Carmoney Net]                              =   [Сумма РАТ Carmoney Net]
,      [Сумма помощь бизнесу]                                =   [Сумма Помощь бизнесу]
,      [Сумма помощь бизнесу Carmoney]                       =   [Сумма Помощь бизнесу Carmoney]
,      [Сумма помощь бизнесу Carmoney Net]                   =   [Сумма Помощь бизнесу Carmoney Net]
,      [Сумма телемедицина]                                  =   [Сумма Телемедицина]
,      [Сумма телемедицина Carmoney]                         =   [Сумма Телемедицина Carmoney]
,      [Сумма телемедицина Carmoney Net]                     =   [Сумма Телемедицина Carmoney Net]
,      [Сумма защита от потери работы]                       =   [Сумма Защита от потери работы]
,      [Сумма защита от потери работы Carmoney]              =   [Сумма Защита от потери работы Carmoney]
,      [Сумма защита от потери работы Carmoney Net]          =   [Сумма Защита от потери работы Carmoney Net]
,      [Сумма фарма]                                         =   [Сумма Фарма]
,      [Сумма фарма Carmoney]                                =   [Сумма Фарма Carmoney]
,      [Сумма фарма Carmoney Net]                            =   [Сумма Фарма Carmoney Net]
,      [Сумма спокойная жизнь]                               =   [Сумма Спокойная Жизнь]
,      [Сумма спокойная жизнь Carmoney]                      =   [Сумма Спокойная Жизнь Carmoney]
,      [Сумма спокойная жизнь Carmoney Net]                  =   [Сумма Спокойная Жизнь Carmoney Net]
,      finChannel Канал
,      [Признак КП снижающий ставку] = [Признак Страховка] 
,      [Способ оформления займа] = origin2
, ispdl = 	ispdl
into #fa
from  v_fa fa;

drop table if exists #loan_cost
select Номер
, [Расходы на выдачу конкретного займа]                             = [Расходы] 
, [Расходы на выдачу конкретного займа: CPA]                        = [Расходы на CPA] 
, [Расходы на выдачу конкретного займа: CPC]                        = [Расходы на CPC (на первичные займы CPC)] 
, [Расходы на выдачу конкретного займа: Медийка и Прочие расходы]   = [Расходы на Медийку и Прочие маркетинговые (на первичный займ)] 
, [Расходы на выдачу конкретного займа: Риск-сервисы и верификация] = [Расходы на риск-сервисы и верификацию] 
, [Расходы на выдачу конкретного займа: КЦ]                         = [Расходы на КЦ] 
, [Расходы на выдачу конкретного займа: Партнеры оформление]        = [Расходы на Партнеров: оформление] 
, [Расходы на выдачу конкретного займа: Партнеры привлечение]       = [Расходы на Партнеров: привлечение]  
, [Расходы на выдачу конкретного займа: ПШ]                         = [Расходы на ПШ (выдача)]  
, [Расходы на выдачу конкретного займа: CPA затраты на заявки без займа]                         = [Расходы на CPA: затраты на заявки без займа аллоцированные на займы]  
, [Расходы на выдачу конкретного займа: Риск-сервисы и верификация затраты на заявки без займа]                         = [Расходы на риск-сервисы и верификацию: затраты на заявки без займа аллоцированные на займы]  


into #loan_cost

from Analytics.dbo.request_cost
where [Расходы]>0


drop table if exists #lcrm
--select  uf_row_id, uf_source Источник, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end Канал into #lcrm from stg.[_LCRM].[lcrm_tbl_short_w_channel] nolock where nullif(uf_row_id , '') is not null
select uf_row_id = uf_row_id                                                 
,      Источник = uf_source                                                  
,      Канал = Analytics.[dbo].[get_channel]([Группа каналов], [Канал от источника]) 

into #lcrm
from [Stg].[_LCRM].lcrm_leads_full_channel_request nolock
--where uf_row_id  is not null 
--where nullif(uf_row_id , '') is not null
;with v  as (select *, row_number() over(partition by uf_row_id order by (select null)) rn from #lcrm ) delete from v where rn>1
--

drop table if exists #refuses_CP
select Код = cast(cast(number as numeric) as nvarchar(20)) ,
[Сумма расторжений по КП] =        [сумма коммиссии],
[Дата расторжения КП] = cast([Дата расторжения] as date)
into #refuses_CP
FROM add_product_refuse_view

;



update r
set r.[Дата расторжения КП] = case when  cast(Погашен as date) <= r.[Дата расторжения КП] then cast(Погашен as date)
								          when  cast(Действует as date) >= r.[Дата расторжения КП] then cast(Действует as date)
								          when   r.[Дата расторжения КП] between cast(Действует as date) and isnull(cast(Погашен as date), r.[Дата расторжения КП]) then  r.[Дата расторжения КП] end

from #refuses_CP r 
join #Справочник_Договоры d on d.код=r.Код


--select * from #refuses_CP
--where [Дата расторжения КП]<>[Дата расторжения КП_изнач]

--select * from #refuses_CP



drop table if exists #refuses_CP_by_loan
select код,     [Сумма расторжений по КП] =  sum([Сумма расторжений по КП])                           
into #refuses_CP_by_loan
FROM #refuses_CP
group by код





------------
drop table if exists #comissions_repayment
select Код,
[Прибыль комиссия при платеже] = ПрибыльБезНДС,
Дата = cast(Дата as date)
into #comissions_repayment
FROM Analytics.dbo.v_repayments


;

------------
drop table if exists #comissions_additional
select Код = [Код договора "Комиссии"],
[Прибыль от дополнительных комиссий] = [Комиссия "СМС информирование": cумма услуги net],
Дата = cast([Комиссия "СМС информирование": дата оплаты] as date)
into #comissions_additional
FROM Analytics.dbo.v_comissions
where [Комиссия "СМС информирование": дата оплаты] is not null
union all
select Код = [Код договора "Комиссии"],
[Прибыль от дополнительных комиссий] = [Комиссия "Срочное снятие с залога": cумма услуги net],
Дата = cast([Комиссия "СМС информирование": дата оплаты] as date)

FROM Analytics.dbo.v_comissions
where [Комиссия "Срочное снятие с залога": дата оплаты] is not null



;



update r
set r.Дата = case when  cast(Погашен as date) <= r.Дата then cast(Погашен as date)
								          when  cast(Действует as date) >= r.Дата then cast(Действует as date)
								          when   r.Дата between cast(Действует as date) and isnull(cast(Погашен as date), r.Дата) then  r.Дата end

from #comissions_repayment r 
join #Справочник_Договоры d on d.код=r.Код




update r
set r.Дата = case when  cast(Погашен as date) <= r.Дата then cast(Погашен as date)
								          when  cast(Действует as date) >= r.Дата then cast(Действует as date)
								          when   r.Дата between cast(Действует as date) and isnull(cast(Погашен as date), r.Дата) then  r.Дата end

from #comissions_additional r 
join #Справочник_Договоры d on d.код=r.Код


--select * from #refuses_CP
--where [Дата расторжения КП]<>[Дата расторжения КП_изнач]

--select * from #refuses_CP



drop table if exists #comissions_repayment_by_loan
select код,     [Прибыль комиссия при платеже] =  sum([Прибыль комиссия при платеже])                           
into #comissions_repayment_by_loan
FROM #comissions_repayment
group by код


drop table if exists #comissions_additional_by_loan
select код,     [Прибыль от дополнительных комиссий] =  sum([Прибыль от дополнительных комиссий])                           
into #comissions_additional_by_loan
FROM #comissions_additional
group by код

--
drop table if exists #reg_analytics
select '' РегионДляПоиска, 'unknown' Регион into #reg_analytics union all
select ',' , 'unknown' union all
select '1211' , 'unknown' union all
select '3' , 'unknown' union all
select 'Адыгея Респ' , 'Адыгея' union all
select 'Алтай Респ' , 'Алтай' union all
select 'Алтайский край' , 'Алтай' union all
select 'Амурская обл' , 'Амурская' union all
select 'Архангельская обл' , 'Архангельская' union all
select 'Астраханская обл' , 'Астраханская' union all
select 'Байконур г' , 'Байконур' union all
select 'Башкортостан' , 'Башкортостан' union all
select 'Башкортостан Респ' , 'Башкортостан' union all
select 'Белгородская обл' , 'Белгородская' union all
select 'Брянская обл' , 'Брянская' union all
select 'Бурятия Респ' , 'Бурятия' union all
select 'Владимирская обл' , 'Владимирская' union all
select 'Волгоградская обл' , 'Волгоградская' union all
select 'Вологодская обл' , 'Вологодская' union all
select 'Воронежская обл' , 'Воронежская' union all
select 'Дагестан Респ' , 'Дагестан' union all
select 'Ё' , 'unknown' union all
select 'Еврейская Аобл' , 'Еврейская' union all
select 'Забайкальский край' , 'Забайкальский' union all
select 'Ивановская обл' , 'Ивановская' union all
select 'Ингушетия Респ' , 'Ингушетия' union all
select 'Иркутская обл' , 'Иркутская' union all
select 'Кабардино-Балкарская Респ' , 'Кабардино-Балкарская' union all
select 'Калининградская обл' , 'Калининградская' union all
select 'Калмыкия Респ' , 'Калмыкия' union all
select 'Калужская обл' , 'Калужская' union all
select 'Камчатский край' , 'Камчатский' union all
select 'Карачаево-Черкесская Респ' , 'Карачаево-Черкесская' union all
select 'Карелия Респ' , 'Карелия' union all
select 'Кемеровская обл' , 'Кемеровская' union all
select 'Кировская обл' , 'Кировская' union all
select 'Коми Респ' , 'Коми' union all
select 'Костромская обл' , 'Костромская' union all
select 'Краснодарский край' , 'Краснодарский' union all
select 'Красноярский край' , 'Красноярский' union all
select 'Крым Респ' , 'Крым' union all
select 'Курганская обл' , 'Курганская' union all
select 'Курская обл' , 'Курская' union all
select 'Ленинградская обл' , 'Ленинградская' union all
select 'Липецкая обл' , 'Липецкая' union all
select 'Липецкая обл.' , 'Липецкая' union all
select 'Магаданская обл' , 'Магаданская' union all
select 'Марий Эл Респ' , 'Марий Эл' union all
select 'Мордовия Респ' , 'Мордовия' union all
select 'Москва г' , 'Москва' union all
select 'Московская обл' , 'Московская' union all
select 'Московская область' , 'Московская' union all
select 'Мурманская обл' , 'Мурманская' union all
select 'Ненецкий АО' , 'Ненецкий' union all
select 'Нижегородская обл' , 'Нижегородская' union all
select 'Новгородская обл' , 'Новгородская' union all
select 'Новосибирская обл' , 'Новосибирская' union all
select 'Омская обл' , 'Омская' union all
select 'Оренбургская обл' , 'Оренбургская' union all
select 'Оренбурская обл' , 'Оренбургская' union all
select 'Орловская обл' , 'Орловская' union all
select 'ПЕНЗЕНСКАЯ' , 'Пензенская' union all
select 'Пензенская обл' , 'Пензенская' union all
select 'Пермский край' , 'Пермский' union all
select 'Приморский край' , 'Приморский' union all
select 'Псковская обл' , 'Псковская' union all
select 'Псковская область' , 'Псковская' union all
select 'респ Башкортостан' , 'Башкортостан' union all
select 'респ Коми' , 'Коми' union all
select 'Ростовская обл' , 'Ростовская' union all
select 'Рязанская обл' , 'Рязанская' union all
select 'Самарская обл' , 'Самарская' union all
select 'Санкт-Петербург г' , 'Санкт-Петербург' union all
select 'Саратовская обл' , 'Саратовская' union all
select 'Саратовская обл.' , 'Саратовская' union all
select 'Саратовскую область' , 'Саратовская' union all
select 'Саха /Якутия/ Респ' , 'Якутия' union all
select 'Сахалинская обл' , 'Сахалинская' union all
select 'Свердловская обл' , 'Свердловская' union all
select 'Севастополь г' , 'Севастополь' union all
select 'Северная Осетия - Алания Респ' , 'Северная Осетия' union all
select 'Смоленская обл' , 'Смоленская' union all
select 'Ставропольский край' , 'Ставропольский' union all
select 'Тамбовская обл' , 'Тамбовская' union all
select 'Татарстан Респ' , 'Татарстан' union all
select 'Тверская обл' , 'Тверская' union all
select 'Томская обл' , 'Томская' union all
select 'Тульская обл' , 'Тульская' union all
select 'Тыва Респ' , 'Тыва' union all
select 'Тюменская обл' , 'Тюменская' union all
select 'Удмуртская Респ' , 'Удмуртская' union all
select 'Ульяновская обл' , 'Ульяновская' union all
select 'Хабаровский край' , 'Хабаровский' union all
select 'Хакасия Респ' , 'Хакасия' union all
select 'Ханты Мансийский АО' , 'Ханты-Мансийский' union all
select 'Ханты-Мансийский Автономный округ - Югра АО' , 'Ханты-Мансийский' union all
select 'Челябинская обл' , 'Челябинская' union all
select 'Чеченская Респ' , 'Чеченская' union all
select 'Чувашская Республика - Чувашия' , 'Чувашская' union all
select 'Чукотский АО' , 'Чукотский' union all
select 'Ямало-Ненецкий АО' , 'Ямало-Ненецкий' union all
select 'Ярославская обл' , 'Ярославская' union all
select '' , '' union all
select 'Самарская' , 'Самарская' union all
select 'Марий Эл' , 'Марий Эл' union all
select 'яро' , 'Ярославская' union all
select 'Челябинская' , 'Челябинская' union all
select 'Омская' , 'Омская' union all
select 'Саратовская' , 'Саратовская' union all
select 'Крым' , 'Крым' union all
select 'Кировская' , 'Кировская' union all
select 'Ставропольский' , 'Ставропольский' union all
select 'РОССИЯ,,Алтайский край,,Барнаул г,,Балтийская ул,дом 105,,кв. 227' , 'Алтай' union all
select 'Брянская область' , 'Брянская' union all
select 'Забугорск' , 'unknown' union all
select 'Белгородская' , 'Белгородская' union all
select 'Нижегородская' , 'Нижегородская' union all
select 'РОССИЯ,111396,Москва г,,,,Фрязевская ул,дом 3,корпус 2,кв. 8' , 'Москва' union all
select 'РОССИЯ,442258,Пензенская обл,Белинский р-н,,Пушанино с,ПМК мкр,дом 5,,кв. 1' , 'Пензенская' union all
select 'Липецкая' , 'Липецкая' union all
select 'Томская' , 'Томская' union all
select 'Тамбовская' , 'Тамбовская' union all
select 'Воронеж' , 'Воронежская' union all
select 'Кабардино-Балкарская' , 'Кабардино-Балкарская' union all
select 'Ямало-Ненецкий' , 'Ямало-Ненецкий' union all
select '1571' , 'unknown' union all
select 'Костромская область' , 'Костромская' union all
select 'Московская' , 'Московская' union all
select 'Архангельская' , 'Архангельская' union all
select 'Новгородская' , 'Новгородская' union all
select 'Мордовия' , 'Мордовия' union all
select 'Смоленская' , 'Смоленская' union all
select 'Владимирская' , 'Владимирская' union all
select 'Удмуртская' , 'Удмуртская' union all
select 'Тульская' , 'Тульская' union all
select 'Ленинградская' , 'Ленинградская' union all
select 'Свердловская' , 'Свердловская' union all
select 'Тверская' , 'Тверская' union all
select 'Ульяновская' , 'Ульяновская' union all
select 'Калининградская' , 'Калининградская' union all
select 'Севастополь' , 'Севастополь' union all
select 'Воронежская область' , 'Воронежская' union all
select 'самара' , 'Самарская' union all
select 'Воронежская' , 'Воронежская' union all
select 'Рязанская' , 'Рязанская' union all
select 'Орловская' , 'Орловская' union all
select 'Структура' , 'Нижегородская' union all
select 'Нижегородская область' , 'Нижегородская' union all
select 'Мурманская' , 'Мурманская' union all
select 'Ростов на Дону' , 'Ростовская' union all
select 'Новосибирская' , 'Новосибирская' union all
select 'Алтай' , 'Алтай' union all
select 'Чувашская - Чувашия Респ        ' , 'Чувашская' union all
select 'РОССИЯ,656012,Алтайский край,,Барнаул г,,Рубцовская ул,дом 28,,' , 'Алтай' union all
select 'Калужская' , 'Калужская' union all
select 'Ростовская' , 'Ростовская' union all
select 'Псковская' , 'Псковская' union all
select 'Оренбургская обл.' , 'Оренбургская' union all
select 'Вологодская' , 'Вологодская' union all
select 'Костромская' , 'Костромская' union all
select 'Алтайский' , 'Алтай' union all
select 'чел' , 'Челябинская' union all
select 'Северная Осетия - Алания' , 'Северная Осетия' union all
select 'Ленинградская область' , 'Ленинградская' union all
select 'Татарстан' , 'Татарстан' union all
select 'Астраханская' , 'Астраханская' union all
select 'Тюменская' , 'Тюменская' union all
select 'Брянская' , 'Брянская' union all
select 'Чувашская Республика -' , 'Чувашская' union all
select 'Адыгея' , 'Адыгея' union all
select 'Нижегородская, обл' , 'Нижегородская' union all
select 'Иркутская' , 'Иркутская' union all
select 'Магаданская' , 'Магаданская' union all
select 'РОССИЯ,105037,Москва г,,,,Парковая 1-я ул,дом 4,,кв. 49' , 'Москва' union all
select 'МО' , 'Московская' union all
select 'Кемеровская' , 'Кемеровская' union all
select 'волгоград' , 'Волгоградская' union all
select 'Ярославская' , 'Ярославская' union all
select 'Курская' , 'Курская' union all
select 'Санкт-Петербург' , 'Санкт-Петербург' union all
select 'Курганская' , 'Курганская' union all
select 'Волгоградская' , 'Волгоградская' union all
select 'Приморский' , 'Приморский' union all
select 'Красноярский' , 'Красноярский' union all
select 'сам' , 'Самарская' union all
select '455731' , 'unknown' union all
select 'Москва г. ' , 'Москва' union all
select 'Краснодарский' , 'Краснодарский' union all
select 'Москва' , 'Москва' union all
select 'Оренбургская' , 'Оренбургская' union all
select 'Ивановская' , 'Ивановская' union all
select 'Ханты-Мансийский Автономный округ - Югра' , 'Ханты-Мансийский' union all
select 'Пермский' , 'Пермский' union all
select 'Карелия' , 'Карелия' union all
select 'Амурская' , 'Амурская' union all
select 'Байконур' , 'Байконур' union all
select 'Бурятия' , 'Бурятия' union all
select 'Дагестан' , 'Дагестан' union all
select 'Еврейская' , 'Еврейская' union all
select 'Забайкальский' , 'Забайкальский' union all
select 'Ингушетия' , 'Ингушетия' union all
select 'Калмыкия' , 'Калмыкия' union all
select 'Камчатский' , 'Камчатский' union all
select 'Карачаево-Черкесская' , 'Карачаево-Черкесская' union all
select 'Коми' , 'Коми' union all
select 'Ненецкий' , 'Ненецкий' union all
select 'Саха /Якутия/' , 'Якутия' union all
select 'Сахалинская' , 'Сахалинская' union all
select 'Тыва' , 'Тыва' union all
select 'Хабаровский' , 'Хабаровский' union all
select 'Хакасия' , 'Хакасия' union all
select 'Ханты-Мансийский Автономн' , 'Ханты-Мансийский' union all
select 'Чеченская' , 'Чеченская' union all
select 'Чувашская' , 'Чувашская' union all
select 'Чувашская Республика - Чу' , 'Чувашская' union all
select 'Чукотский' , 'Чукотский' union all
select 'Россия, 660064, Красноярский край, Свердловский р-н, Красноярск г, , Королева ул, дом 12, , кв. 241' , 'Красноярский' union all
select 'Россия, 188514, Ленинградская обл, , , Сергеевка тер. ДНП, Дружная ул, дом 1, ,' , 'Ленинградская' union all
select 'Россия, 141280, Московская обл, , Ивантеевка г, , Задорожная ул, дом 23Б, , кв. 39' , 'Московская' union all
select 'Россия, 433321, Ульяновская обл, , Ульяновск г, им.Карамзина п, Верхняя площадка ул, дом 1, , кв. 45' , 'Ульяновская' union all
select 'Россия, 394000, Воронежская обл, , Воронеж г, , , , ,' , 'Воронежская' union all
select 'Россия, 141407, Московская обл, , Химки г, , Молодежная ул, дом 78, , кв. 669' , 'Московская' union all
select 'Россия, , Липецкая обл, , Липецк г, , Бехтеева С.С. ул, , ,' , 'Липецкая' union all
select 'Россия, 398059, Липецкая обл, , Липецк г, , Им. Мичурина ул, дом 38А, , кв. 88' , 'Липецкая' union all
select 'Россия, 238210, Калининградская обл, Гвардейский р-н, Гвардейск г, , , , ,' , 'Калининградская' union all
select 'Иркутская обл Усть-Ордынский Бурятский округ' , 'Иркутская' union all
select 'г Москва Ул Борисовские Пруды 16 Кор 4 Кв 199' , 'Москва' union all
select 'Россия, 143402, Московская обл, , Красногорск г, , Жуковского ул, дом 4, , кв. 16' , 'Московская' union all
select 'Россия, 618400, Пермский край, , Березники г, , Миндовского ул, дом 6, , кв. 171' , 'Пермский' union all
select 'Коми-Пермяцкий АО' , 'Коми' union all
select 'Россия, 101000, Москва г, , Москва г, , , , ,' , 'Москва' union all
select 'Россия, 170008, Тверская обл, , Тверь г, , Резинстроя ул, дом 3, , кв. 16' , 'Тверская' union all
select 'РОССИЯ,353810,КраснодарскиТрудобеликовский х,Краснодарская ул,дом 8' , 'Краснодарский' union all
select 'РОССИЯ,385000,Адыгея Респ,Тахтамукайский р-н,,Тахтамукай аул,Красноармейская ул,дом 86,,' , 'Адыгея' union all
select 'Россия, 460004, Оренбургская обл, Промышленный р-н, Оренбург г, , Маловская ул, дом 76, ,' , 'Оренбургская' union all
select 'Россия, 141103, Московская обл, , Щелково г, , Аэродромная ул, дом 2, стр 1,' , 'Московская' union all
select 'Россия, 153021, Ивановская обл, , Иваново г, , Лебедева-Кумача ул, дом 10, , кв. 51' , 'Ивановская' union all
select 'Россия, 460060, Оренбургская обл, , Оренбург г, , Салмышская ул, дом 74, , кв. 12' , 'Оренбургская' union all
select 'Россия, 185000, Карелия Респ, , Петрозаводск г, , , , ,' , 'Карелия' union all
select 'Россия, , Алтайский край, , , , , , ,' , 'Алтай' union all
select 'Забайкальский край Агинский Бурятский округ' , 'Забайкальский' union all
select 'Россия, 192177, Санкт-Петербург г, Невский р-н, Санкт-Петербург г, , Обуховской Обороны пр-кт, дом 144, , кв. 270' , 'Санкт-Петербург' union all
select 'Россия, 626050, Тюменская обл, , , Ярково с, Панфиловцев ул, дом 13, ,' , 'Тюменская' union all
select 'Россия, 242220, Брянская обл, , Трубчевск г, , , , ,' , 'Брянская' union all
select 'Россия, 394042, Воронежская обл, , Воронеж г, , Минская ул, дом 3, , кв. 32' , 'Воронежская' union all
select 'Россия, 184410, Мурманская обл, , , Печенга пгт, Печенгское ш, дом 11, , кв. 32' , 'Мурманская' union all
select 'Россия, 410038, Саратовская обл, Волжский р-н, Саратов г, , Бакинская ул, дом 8, , кв. 22' , 'Саратовская' union all
select 'Россия, 153015, Ивановская обл, , Иваново г, , Силикатный пер, дом 44, , кв. 19' , 'Ивановская' union all
select 'Россия, 624262, Свердловская обл, , Асбест г, , Чапаева ул, дом 25, , кв. 19' , 'Свердловская' union all
select 'Россия, 660132, Красноярский край, Советский р-н, Красноярск г, , 40 лет Победы ул, дом 35, , кв. 2' , 'Красноярский' union all
select 'Россия, 344011, Ростовская обл, , Ростов-на-Дону г, , Лермонтовская ул, дом 44, , кв. 5' , 'Ростовская' union all
select 'Россия, 192281, Санкт-Петербург г, Фрунзенский р-н, Санкт-Петербург г, , Купчинская ул, дом 12, ,' , 'Санкт-Петербург' union all
select 'Россия, 396433, Воронежская обл, , , Ерышевка с, Революции пр-кт, дом 35, ,' , 'Воронежская' union all
select ',, , , , , , , ,. ' , 'unknown' union all
select 'г Нижний Новгород, ул Ильинская, д 74, кв 25' , 'Нижегородская' union all
select 'Россия, 423570, Татарстан Респ, Нижнекамский р-н, Нижнекамск г, , , , ,' , 'Татарстан' union all
select 'Россия, 450017, Башкортостан Респ, , Уфа г, , Малая Береговая ул, дом 92, ,' , 'Башкортостан' union all
select 'Россия, , Ростовская обл, , , , , , ,' , 'Ростовская' union all
select 'Россия, 160031, Вологодская обл, , Вологда г, , Кирова ул, дом 36, , кв. 18' , 'Вологодская' union all
select 'Россия, 125368, Москва г, Митино р-н, Москва г, , Дубравная ул, дом 40, , кв. 41' , 'Москва' union all
select 'Россия, 628403, Ханты-Мансийский Автономный округ - Югра АО, , Сургут г, , Университетская ул, дом 9, , кв. 1' , 'Ханты-Мансийский' union all
select 'Россия, 301305, Тульская обл, , , Козловка с, Новая ул, дом 17, , кв. 2' , 'Тульская' union all
select 'Россия, 454076, Челябинская обл, , Челябинск г, , Бейвеля ул, дом 46А, , кв. 134' , 'Челябинская' union all
select 'Россия, 663020, Красноярский край, Емельяновский р-н, , Емельяново пгт, Саянская ул, , ,' , 'Красноярский' union all
select 'Россия, 125363, Москва г, Южное Тушино р-н, Москва г, , Фабрициуса ул, дом 23, к 1,' , 'Москва' union all
select 'РОССИЯ,410039,Саратовская обл,,Саратов г,,пос. Шарковка ул.,дом 4,,кв. 46' , 'Саратовская' union all
select 'Россия, 353925, Краснодарский край, , Новороссийск г, , Пионерская ул, дом 39, , кв. 53' , 'Краснодарский' union all
select 'Москва Фруктовая Д.9 Ка Кв 237' , 'Москва' union all
select 'Россия, 188365, Ленинградская обл, Гатчинский р-н, , Красницы д, , дом 79Б, ,' , 'Ленинградская' union all
select 'Россия, 249039, Калужская обл, , Обнинск г, , Калужская ул, дом 13, ,' , 'Калужская' union all
select 'Россия, 300021, Тульская обл, , Тула г, , Поленова ул, дом 25, ,' , 'Тульская' union all
select 'Россия, 109012, Москва г, Тверской р-н, Москва г, , Москворецкая наб, дом 15, , кв. 25' , 'Москва' union all
select 'Россия, 355026, Ставропольский край, , Ставрополь г, гаражного кооператива Металлист-2 тер, , дом 34, ,' , 'Ставропольский' union all
select 'Россия, 398001, Липецкая обл, , Липецк г, , 8 Марта ул, дом 13, , кв. 206' , 'Липецкая' union all
select 'Город Подольск Электромонтажный Проезд 7 Кв 85' , 'Московская' union all
select 'Россия, 410080, Саратовская обл, Ленинский р-н, Саратов г, Латухино мкр, , , ,' , 'Саратовская' union all
select 'Россия, 410035, Саратовская обл, , Саратов г, , Мамонтовой ул, дом 3, , кв. 98' , 'Саратовская' union all
select 'Россия, 606030, Нижегородская обл, , Дзержинск г, , Окская наб, дом 19А, , кв. 37' , 'Нижегородская' union all
select 'Россия, 143900, Московская обл, , Балашиха г, , Ленина пр-кт, дом 82, к 2, кв. 73' , 'Московская' union all
select 'Россия,614113,Пермский край,Кировский р-н,Пермь г, ,Автозаводская ул,дом 44А, ,кв. 80' , 'Пермский' union all
select 'москва тест' , 'Москва' union all
select 'Россия, 350087, Краснодарский край, , Краснодар г, , им. Комарова В.М. ул, дом 21/1, , кв. 60' , 'Краснодарский' union all
select 'Россия, 446104, Самарская обл, , Чапаевск г, , Котовского ул, дом 15, , кв. 54' , 'Самарская' union all
select 'Россия, 354066, Краснодарский край, Хостинский р-н, Сочи г, , Искры ул, дом 50, , кв. 93' , 'Краснодарский' union all
select 'Россия, 620110, Свердловская обл, , Екатеринбург г, , Чкалова ул, дом 231, , кв. 481' , 'Свердловская' union all
select 'Россия, 410052, Саратовская обл, , Саратов г, , Одесская ул, дом 7А, , кв. 115' , 'Саратовская' union all
select 'Коми Проезд Строителей Д.8 Кв 150' , 'Коми' union all
select 'Россия, 153011, Ивановская обл, , Иваново г, , 3-я Нарвская ул, дом 4, ,' , 'Ивановская' union all
select 'Россия, 400002, Волгоградская обл, Советский р-н, Волгоград г, , Шефская ул, дом 82, , кв. 22' , 'Волгоградская' union all
select 'РОССИЯ, Московская обл, Балашиха г,Никольско-Архангельский мкр,Энтузиастов ш,дом вл. 2/4' , 'Московская' union all
select 'Россия, 397842, Воронежская обл, , , Веретье с, Центральная ул, дом 95, ,' , 'Воронежская' union all
select 'Московская обл, г Подольск' , 'Московская' union all
select 'Россия, 633131, Новосибирская обл, , , Мошково рп, Пушкина ул, дом 5А, , кв. 22' , 'Новосибирская' union all
select 'Россия, 129128, Москва г, , Москва г, , Малахитовая ул, дом 1, , кв. 184' , 'Москва' union all
select 'Россия, 152900, Ярославская обл, , Рыбинск г, , Ухтомского ул, дом 3, , кв. 83' , 'Ярославская' union all
select 'Россия, 692527, Приморский край, , Уссурийск г, , Сергея Ушакова ул, дом 13, стр 1, кв. 22' , 'Приморский' union all
select 'Россия, 170039, Тверская обл, , Тверь г, , Хромова ул, дом 25, ,' , 'Тверская' union all
select 'Россия, 446253, Самарская обл, , , Безенчук пгт, Советская ул, дом 99, , кв. 15' , 'Самарская' union all
select 'г Санкт-Петербург, пр-кт Солидарности 9 ' , 'Санкт-Петербург' union all
select 'Россия, 623955, Свердловская обл, , Тавда г, , 4-я Пятилетка ул, дом 43, , кв. 30' , 'Свердловская' union all
select 'Россия, 300041, Тульская обл, , Тула г, , Демонстрации ул, дом 1А, ,' , 'Тульская' union all
select 'Россия, 614067, Пермский край, Дзержинский р-н, Пермь г, , Хабаровская ул, дом 62, , кв. 61' , 'Пермский' union all
select 'Россия, 610926, Кировская обл, , Киров г, Чистые Пруды п, Советская ул, дом 70Е, ,' , 'Кировская' union all
select 'Россия, 620100, Свердловская обл, , Екатеринбург г, , Куйбышева ул, дом 159А, , кв. 165' , 'Свердловская' union all
select 'Адрес места прибывания' , 'unknown' union all
select 'г Тула, ул Пролетарская, д 2' , 'Тульская' union all
select ', , , , , , , , ,' , 'unknown' union all
select 'Уральский ФО' , 'unknown' union all
select 'Россия, 453505, Башкортостан Респ, Белорецкий р-н, Белорецк г, , Электрификации ул, дом 2, ,' , 'Башкортостан' union all
select 'Таймырский АО' , 'Красноярский' union all
select 'москва нагатинская набережная дом 46 кор 3 кв 8' , 'Москва' union all
select 'Россия, 344064, Ростовская обл, , Ростов-на-Дону г, , Вавилова ул, дом 1Б, , кв. 17' , 'Ростовская' union all
select 'Россия, 353445, Краснодарский край, Анапский р-н, Анапа г, , Осенний проезд, дом 23, ,' , 'Краснодарский' --union all

--select * from #reg_analytics
-- select * from #refuses_CP
  
  drop table if exists #chdp

select Договор 
,      [Заявлений на ЧДП] = count(*) 
,      [Дата последнего заявления на ЧДП] = max(dateadd(year, -2000, Дата)) 
,      [Дата первого заявления на ЧДП] = min(dateadd(year, -2000, Дата)) 
into #chdp
from stg.[_1cCMR].[Документ_ЗаявлениеНаЧДП]
where ПометкаУдаления=0
	and Проведен=1
group by Договор

--

--select * from #products

drop table if exists #loan_params;


select v.код    
,      v.[Ссылка договор CMR]
,      v.[Номер заявки]
,      loan_cost.[Расходы на выдачу конкретного займа]                                                                     
,      loan_cost.[Расходы на выдачу конкретного займа: CPA]                                                                     
,      loan_cost.[Расходы на выдачу конкретного займа: CPC]                                             
,      loan_cost.[Расходы на выдачу конкретного займа: Партнеры привлечение]                                                        
,      loan_cost.[Расходы на выдачу конкретного займа: Партнеры оформление]                                    
,      loan_cost.[Расходы на выдачу конкретного займа: Медийка и Прочие расходы]                                      
,      loan_cost.[Расходы на выдачу конкретного займа: КЦ]                   
,      loan_cost.[Расходы на выдачу конкретного займа: ПШ]                                         
,      loan_cost.[Расходы на выдачу конкретного займа: Риск-сервисы и верификация]                                           
,      loan_cost.[Расходы на выдачу конкретного займа: Риск-сервисы и верификация затраты на заявки без займа]                                           
,      loan_cost.[Расходы на выдачу конкретного займа: CPA затраты на заявки без займа]                                           
,      Источник                                                                     
,      isnull([Сумма комиссионных продуктов]                         , 0) [Сумма комиссионных продуктов]                                                       
,      isnull([Сумма комиссионных продуктов Carmoney]                                 , 0) [Сумма комиссионных продуктов Carmoney]                                                                                
,      isnull([Сумма комиссионных продуктов Carmoney Net]                             , 0) [Сумма комиссионных продуктов Carmoney Net]                             
,      isnull([Признак каско]                                        , 0) [Признак каско]                                          
,      isnull([Признак страхование жизни]                            , 0) [Признак страхование жизни]                            
,      isnull([Признак РАТ]                                          , 0) [Признак РАТ]                                          
,      isnull([Признак помощь бизнесу]                               , 0) [Признак помощь бизнесу]                               	
,      isnull([Признак телемедицина]                                 , 0) [Признак телемедицина]                                 
,      isnull([Признак защита от потери работы]                      , 0) [Признак защита от потери работы]                      	
,      isnull([Признак фарма]                                        , 0) [Признак фарма]                                        	
,      isnull([Признак cпокойная жизнь]                              , 0) [Признак cпокойная жизнь]                              
,      isnull([Сумма каско]                                          , 0) [Сумма каско]                                          
,      isnull([Сумма каско Carmoney]                                 , 0) [Сумма каско Carmoney]                                 
,      isnull([Сумма каско Carmoney Net]                             , 0) [Сумма каско Carmoney Net]                             
,      isnull([Сумма страхование жизни]                              , 0) [Сумма страхование жизни]                              
,      isnull([Сумма страхование жизни Carmoney]                     , 0) [Сумма страхование жизни Carmoney]                     
,      isnull([Сумма страхование жизни Carmoney Net]                 , 0) [Сумма страхование жизни Carmoney Net]                 
,      isnull([Сумма РАТ]                                            , 0) [Сумма РАТ]                                            
,      isnull([Сумма РАТ Carmoney]                                   , 0) [Сумма РАТ Carmoney]                                   
,      isnull([Сумма РАТ Carmoney Net]                               , 0) [Сумма РАТ Carmoney Net]                               
,      isnull([Сумма помощь бизнесу]                                 , 0) [Сумма помощь бизнесу]                                 
,      isnull([Сумма помощь бизнесу Carmoney]                        , 0) [Сумма помощь бизнесу Carmoney]                        
,      isnull([Сумма помощь бизнесу Carmoney Net]                    , 0) [Сумма помощь бизнесу Carmoney Net]                    
,      isnull([Сумма телемедицина]                                   , 0) [Сумма телемедицина]                                   
,      isnull([Сумма телемедицина Carmoney]                          , 0) [Сумма телемедицина Carmoney]                          
,      isnull([Сумма телемедицина Carmoney Net]                      , 0) [Сумма телемедицина Carmoney Net]                      
,      isnull([Сумма защита от потери работы]                        , 0) [Сумма защита от потери работы]                        
,      isnull([Сумма защита от потери работы Carmoney]               , 0) [Сумма защита от потери работы Carmoney]               
,      isnull([Сумма защита от потери работы Carmoney Net]           , 0) [Сумма защита от потери работы Carmoney Net]           
,      isnull([Сумма фарма]                                          , 0) [Сумма фарма]                                          
,      isnull([Сумма фарма Carmoney]                                 , 0) [Сумма фарма Carmoney]                                 
,      isnull([Сумма фарма Carmoney Net]                             , 0) [Сумма фарма Carmoney Net]                             
,      isnull([Сумма спокойная жизнь]                                , 0) [Сумма спокойная жизнь]                                
,      isnull([Сумма спокойная жизнь Carmoney]                       , 0) [Сумма спокойная жизнь Carmoney]                       
,      isnull([Сумма спокойная жизнь Carmoney Net]                   , 0) [Сумма спокойная жизнь Carmoney Net]                   
,      isnull(fa.Канал , lcrm.Канал) Канал
,      [Способ оформления займа]  
,      isnull([Признак КП снижающий ставку], 0)    [Признак КП снижающий ставку]                                                                  
,      isnull(isnull(isnull(fa.[Вид займа], loginom_return_type.return_type),  tvr.return_type ), 'Первичный') [Вид займа]

,      isnull(fa.product,
case when isnull(isnull(isnull(fa.[Вид займа], loginom_return_type.return_type),  tvr.return_type ), 'Первичный') ='Первичный'                           then 'Первичные: non-RBP'
     when isnull(isnull(isnull(fa.[Вид займа], loginom_return_type.return_type),  tvr.return_type ), 'Первичный') ='Повторный'                           then 'Повторный займ'
     when isnull(isnull(isnull(fa.[Вид займа], loginom_return_type.return_type),  tvr.return_type ), 'Первичный')  in ('Докредитование' ,'Параллельный') then 'Докредитование' end ) product



, case when isnull(feodor_requests.Position, '')<>'' then feodor_requests.Position
       when isnull(mfo_requests.Должность, '')<>'' then mfo_requests.Должность
	   else isnull(feodor_requests.Position, mfo_requests.Должность) end Должность
, [#Цели займов аналитические].[Цель займа]
, [#Цели займов аналитические].[Цель займа аналитическая]
, mfo_loans.[Агент партнер]
, case when pep_3_loans.Номер is not null then 1 else 0 end as [Признак ПЭП3]
, deals.[Номер договора Спейс]
, deals.[id клиента Спейс]
, deals.[Стадия договора Спейс]
, deals.[Статус договора Спейс]
, customers.[Телефон клиента Спейс]
, customers.[CRMClientGUID Спейс]
, customers.[Стадия клиента Спейс]

, [Телефон договор CMR]

, [Стоимость ТС] = mfo_requests.РыночнаяСтоимостьАвтоНаМоментОценки
, [Guid тс]      = dwh_new.dbo.getGUIDFrom1C_IDRREF(mfo_requests.ТранспортноеСредство)
, VIN            = mfo_requests.VIN
, [Марка тс]     = mfo_requests.МаркаАвто
, [Модель тс]    = mfo_requests.МодельАвто
, [Год тс]    = case when mfo_requests.ГодАвто>1 then mfo_requests.ГодАвто else crm_requests.ГодВыпускаАвто end
, [Адрес Проживания CRM] = АдресПроживания
, [Текущая процентная ставка]
, first_percent.[Первая процентная ставка] [Первая процентная ставка]
, isnull([Последняя процентная ставка 14 дней] , [Текущая процентная ставка]) [Последняя процентная ставка 14 дней]
, isnull(refuses_CP_by_loan.[Сумма расторжений по КП], 0) [Сумма расторжений по КП]
--, isnull(refuses_CP_by_loan.[Сумма расторжений], 0) ВозвратПоСтраховкеNet
, case when refuses_CP_by_loan.[Сумма расторжений по КП] is not null then 1 else 0 end [Признак расторжение КП]


, isnull(comissions_repayment_by_loan.[Прибыль комиссия при платеже], 0) [Прибыль комиссия при платеже]
, isnull(comissions_additional_by_loan.[Прибыль от дополнительных комиссий], 0) [Прибыль от дополнительных комиссий]


, chdp.[Заявлений на ЧДП]
, chdp.[Дата первого заявления на ЧДП]
, chdp.[Дата последнего заявления на ЧДП]

, docredy_history.[Дата первого предложения докредитования]
, docredy_history.[Лимит первого предложения докредитования]


, povt_history.[Дата первого предложения повторного займа]
, povt_history.[Лимит первого предложения повторного займа]

, isnull(reg_analytics.Регион, 'unknown') Регион
, fa.ispdl
, replace( replace( replace(v.фамилия, 'ё', 'е' ) , '-', '' ) , ' ', '' ) + ' '+  replace( replace( replace( v.Имя ,  'ё', 'е' ) , '-', '' ) , ' ', '' ) + ' '+  replace( replace( replace(v.Отчество ,  'ё', 'е' ) , '-', '' ) , ' ', '' ) + ' '+ CONVERT(nvarchar , ДатаРождения, 102) fioBirthday
, v.СерияНомерПаспорта passportSerialNumber
, v.productType
	 into #loan_params

from      #Справочник_Договоры v       
--select top 1000 * into [C3-VSR-SQL01.cmr.dbo.Справочник_Регионы] from [C3-VSR-SQL01].[cmr].dbo.Справочник_Регионы
left join [C3-VSR-SQL01.cmr.dbo.Справочник_Регионы] regs on regs.ссылка=v.Регион
left join #fa fa on v.[Номер заявки]=fa.Номер
left join #deals deals on v.код=deals.[Номер договора Спейс]
left join #customers customers on customers.[id клиента Спейс]=deals.[id клиента Спейс]
left join #mfo_requests mfo_requests on v.[Номер заявки]=mfo_requests.Номер
left join #mfo_loans mfo_loans on v.Код=mfo_loans.Номер
left join #pep_3_loans pep_3_loans on v.[Номер заявки]=pep_3_loans.Номер
left join #crm_requests crm_requests on v.[Номер заявки]=crm_requests.Номер
left join #reg_analytics reg_analytics on reg_analytics.РегионДляПоиска=isnull(isnull(crm_requests.АдресПроживания, regs.Наименование), mfo_requests.Регион)
left join #feodor_requests feodor_requests on v.[Номер заявки]=feodor_requests.Number
left join #current_percent current_percent on current_percent.Договор=v.[Ссылка договор CMR]
left join #percent_14days percent_14days on percent_14days.Договор=v.[Ссылка договор CMR]
left join #first_percent first_percent on first_percent.Договор=v.[Ссылка договор CMR]
left join #loan_cost loan_cost on loan_cost.Номер=v.[Номер заявки]
left join #lcrm lcrm on lcrm.uf_row_id=v.[Номер заявки]
left join #refuses_CP_by_loan refuses_CP_by_loan on refuses_CP_by_loan.Код=v.код
left join #comissions_repayment_by_loan comissions_repayment_by_loan on comissions_repayment_by_loan.Код=v.код
left join #comissions_additional_by_loan comissions_additional_by_loan on comissions_additional_by_loan.Код=v.код
left join #chdp chdp on chdp.Договор=v.[Ссылка договор CMR]
left join #tvr                 tvr                 on tvr.external_id=v.[Номер заявки]
left join #loginom_return_type loginom_return_type on loginom_return_type.number=v.[Номер заявки]
left join #docredy_history     docredy_history  on docredy_history.код=v.Код
left join #povt_history     povt_history  on povt_history.код=v.Код
left join [#Цели займов аналитические]     [#Цели займов аналитические]  on [#Цели займов аналитические].Номер=v.[Номер заявки]

--select * from #loan_params
--where код='21090900135078'

--select * from #statuses

--update  a
--set a.Регион=b.Регион
--from report_loans a
--join #loan_params b on a.[Ссылка договор CMR]=b.[Ссылка договор CMR]

--select Регион from v_loans

--drop table if exists #payments
--
--select         dateadd(year, -2000, v.Дата)       [Дата документа выдача денежных средств]
--,              dateadd(year, -2000, v.ДатаВыдачи) [Дата выдачи ДС]
--,              ps.Наименование                    [Платежная система]
--,              v.Сумма                            [Сумма клиенту на руки]
--,              v.СпособВыдачи                     [Способ выдачи ДС]
--,              v.ссылка                     [Ссылка на выдачу ДС]
--,              v.Договор                     Договор
--
--
--into #payments
--
--from      [Stg]._1cCMR.Документ_ВыдачаДенежныхСредств v 
--left join [Stg]._1cCMR.Справочник_Договоры            d  on v.Договор=d.Ссылка
--left join [Stg]._1cCMR.Справочник_ПлатежныеСистемы    ps on ps.Ссылка=v.ПлатежнаяСистема
--where v.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F --Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
--	and v.Проведен=1
--	and v.ПометкаУдаления=0


--select * from  [Stg]._1cCMR.Документ_ВыдачаДенежныхСредств v 
--where Ссылка=0x814A00155D01BF0711E79D38967BBFAE


drop table if exists #perenos;

with v as (


select Ссылка                                                       
,      cast(dateadd(year, -2000, Дата )                    as date)               [Дата переноса платежа]
,      cast(dateadd(year, -2000, НоваяДатаПлатежа )        as date)               [Новая дата платежа при переносе]
,      cast(dateadd(year, -2000, СледующаяДатаПлатежа )    as date)               [Следующая дата платежа при переносе]
,      cast(dateadd(year, -2000, МаксимальнаяДатаПлатежа ) as date)               [Максимальная дата платежа при переносе]
,      Договор                                                      
from [Stg]._1cCMR.Документ_ОбращениеКлиента
where ВидОперации=0x9CB79B770BF013014F3165845D8CE72C
	and Проведен=1
)


select  Ссылка Ссылка
,       [Дата переноса платежа]
,       [Новая дата платежа при переносе]
,       [Следующая дата платежа при переносе]
,       [Максимальная дата платежа при переносе]


,      Договор Договор
 into #perenos
from v
;with v  as (select *, row_number() over(partition by Договор order by [Дата переноса платежа] desc) rn from #perenos ) delete from v where rn>1




--select * from prodsql02.cmr.dbo.Перечисление_ВидыОперацийОбращениеКлиента
drop table if exists #kk;
--with v as (																									
--select Договор                                                           									
--,      cast(dateadd(year, -2000, ДатаОкончанияКредитныхКаникул ) as date) ДатаОкончанияКредитныхКаникул		
--,      cast(dateadd(year, -2000, Дата ) as date)                          Дата								
--from [Stg]._1cCMR.Документ_ОбращениеКлиента																	
--where ВидОперации=0xB7DCDAEEBB3606B645BABE3167B3379A														
--	and ПометкаУдаления=0																					
--	and Проведен=1																							
--)																											
		with v as (
		select Договор                                                           
		,      period_end ДатаОкончанияКредитныхКаникул
		,      period_start                          Дата
		from dwh2.dbo.dm_restructurings
		)
		
select Договор                                                                                    
,      1                                                                                              [Предоставлены КК]
,      case when cast(getdate() as date) between Дата and isnull(ДатаОкончанияКредитныхКаникул, cast(getdate() as date)) then 1 end as [Текущие КК]
,      ДатаОкончанияКредитныхКаникул                                                                  [Дата окончания КК]
,      Дата                                                                  [Дата начала КК]
into #kk
from v


;with v  as (select *, row_number() over(partition by Договор order by [Дата начала КК] desc) rn from #kk ) delete from v where rn>1



--select * from [dbo].[_v_information_schema_linked] where is_cmr=1 and table_name like '%обращ%'
--select top 1000 * from [PRODSQL02].[cmr].dbo.Перечисление_ВидыОперацийОбращениеКлиента
--select * from #kk

drop table if exists #Документ_ГрафикПлатежей_первый_платеж
;
with v as (select g.Ссылка ,g.Договор, g.СуммаПСК, g.ПСК, dg.СуммаПлатежа, ROW_NUMBER() over(partition by g.[Договор] order by g.Дата,  [ДатаПлатежа] ) rn from [Stg].[_1cCMR].[Документ_ГрафикПлатежей] g join stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей]  dg on g.Ссылка=dg.регистратор_ссылка where g.Проведен=1 and g.ПометкаУдаления=0 )
select [Договор], [ПСК первоначальная] =  ПСК , [Сумма ПСК первоначальная] = СуммаПСК, [Размер платежа первоначальный] = СуммаПлатежа, Ссылка into #Документ_ГрафикПлатежей_первый_платеж from v where rn=1

drop table if exists #Документ_ГрафикПлатежей_последний
;
with v as (select g.Ссылка ,g.Договор, g.СуммаПСК, g.ПСК, ROW_NUMBER() over(partition by g.[Договор] order by g.Дата desc ) rn from [Stg].[_1cCMR].[Документ_ГрафикПлатежей] g  where g.Проведен=1 and g.ПометкаУдаления=0 )
select [Договор], [ПСК текущая] =  ПСК , [Сумма ПСК текущая] = СуммаПСК, Ссылка into #Документ_ГрафикПлатежей_последний from v where rn=1

--balance



drop table if exists #first_repayment
;
with v as (
select ДатаПлатежа [Дата первого платежа], СуммаПлатежа [Сумма первого платежа], Код, ROW_NUMBER() over (partition by Код order by ДатаПлатежа) rn from DWH2.dm.CMRExpectedRepayments
where СуммаПлатежа>0 

)
select *  into #first_repayment  from v
where rn=1

drop table if exists #refuses_CP_by_day
select код
,     [Дата расторжения КП]
,     [Сумма расторжений по КП] =  sum([Сумма расторжений по КП])                           
into #refuses_CP_by_day
FROM #refuses_CP
group by код, [Дата расторжения КП]



drop table if exists #comissions_repayment_by_day
select код
,     Дата
,     [Прибыль комиссия при платеже] =  sum([Прибыль комиссия при платеже])                           
into #comissions_repayment_by_day
FROM #comissions_repayment
group by код, Дата


drop table if exists #comissions_additional_by_day
select код
,     Дата
,     [Прибыль от дополнительных комиссий] =  sum([Прибыль от дополнительных комиссий])                           
into #comissions_additional_by_day
FROM #comissions_additional
group by код, Дата


--select * from stg.files.refuses_CP_buffer

drop table if exists #balance;

--drop table if exists #cmr_date
--select max(d) cmr_date into #cmr_date from reports.dbo.dm_CMRStatBalance_2 
declare @cmr_date date = (select max(d) from reports.dbo.dm_CMRStatBalance_2 )
;
--select @cmr_date from @cmr_date



drop table if exists #cmr

select Код = external_id          
,      Сумма    = Сумма                                                                                                                   
,      [Проценты уплачено]    = [Проценты уплачено]                                                                                                    
,      [Основной долг уплачено]        = [Основной долг уплачено]                                                                                           
,      [основной долг уплачено нарастающим итогом]        = [основной долг уплачено нарастающим итогом]                                                                                           
,      [сумма поступлений]         = [сумма поступлений]                                                                                                
,      [Проценты уплачено  нарастающим итогом]      = isnull([Проценты уплачено  нарастающим итогом] , 0)
,      contractenddate        = contractenddate                                                                                                     
,      ContractStartDate  = ContractStartDate        
,      [Сумма комиссионных продуктов уплачено] = case when isnull([основной долг уплачено нарастающим итогом], 0)<=[Сумма комиссионных продуктов] then isnull([основной долг уплачено нарастающим итогом], 0) else [Сумма комиссионных продуктов] end 
,      dpd    = dpd                                                                                                                     
,      dpd_begin_day    = dpd_begin_day
                                                                                                                 
,      d   = d                                                                                                                       
,      [остаток од] = [остаток од]                                                                                                  
,      Фондирование = [остаток од]* 15/100.0/365                                                                                                  
,      [Фондирование нарастающим итогом] = sum([остаток од]* 15/100.0/365) over (partition by external_id order by d rows between unbounded preceding and current row) 
,      [Последний день в портфеле]  = isnull(contractenddate, @cmr_date)
,      [Дата первого платежа] = fr.[Дата первого платежа] 
,      [Дата актуальности портфеля] = @cmr_date
,      [Прибыль комиссия при платеже] = isnull(c_rep.[Прибыль комиссия при платеже], 0) 
,      [Прибыль комиссия при платеже нарастающим итогом] = sum(isnull(c_rep.[Прибыль комиссия при платеже], 0) ) over (partition by external_id order by d rows between unbounded preceding and current row)

,      [Прибыль от дополнительных комиссий] = isnull(c_add.[Прибыль от дополнительных комиссий], 0) 
,      [Прибыль от дополнительных комиссий нарастающим итогом] = sum(isnull(c_add.[Прибыль от дополнительных комиссий], 0) ) over (partition by external_id order by d rows between unbounded preceding and current row)

,      [Сумма расторжений по КП] = isnull(r_cp.[Сумма расторжений по КП], 0) 
,      [Сумма расторжений по КП нарастающим итогом] = sum(isnull(r_cp.[Сумма расторжений по КП], 0) ) over (partition by external_id order by d rows between unbounded preceding and current row)
,      [Сумма комиссионных продуктов]
,      [Сумма комиссионных продуктов Carmoney Net]
,      [Расходы на комиссионные продукты] = [Сумма комиссионных продуктов] - [Сумма комиссионных продуктов Carmoney Net]  
,      [Расходы на выдачу конкретного займа]
into #cmr	  --select top 100 *
from reports.dbo.dm_CMRStatBalance_2 a
left join #first_repayment fr on fr.Код=a.external_id 
left join #refuses_CP_by_day r_cp on r_cp.Код=a.external_id  and r_cp.[Дата расторжения КП]=a.d
left join #comissions_repayment_by_day c_rep on c_rep.Код=a.external_id  and c_rep.Дата=a.d
left join #comissions_additional_by_day c_add on c_add.Код=a.external_id  and c_add.Дата=a.d
join #loan_params lp on lp.код=a.external_id 



--declare @cmr_date date = (select max(d) from reports.dbo.dm_CMRStatBalance_2 )

;
with cmr_costs
 as

 (
select 
Код,
Сумма,
[Проценты уплачено],
[Основной долг уплачено],
[сумма поступлений],
[Проценты уплачено  нарастающим итогом],
contractenddate,
ContractStartDate,
dpd,
dpd_begin_day,
d,
Фондирование,
[Фондирование нарастающим итогом],
[Последний день в портфеле],
[Расходы на комиссионные продукты],
[Сумма комиссионных продуктов уплачено],
[Прибыль комиссия при платеже нарастающим итогом],
[Прибыль от дополнительных комиссий нарастающим итогом],
--Прибыль = -[Фондирование нарастающим итогом]-[Расходы на выдачу конкретного займа] + [Проценты уплачено  нарастающим итогом] - [Сумма расторжений по КП нарастающим итогом] + [Сумма комиссионных продуктов Carmoney Net] ,
--[Прибыль 2] = -[Фондирование нарастающим итогом]-[Расходы на выдачу конкретного займа] + [Проценты уплачено  нарастающим итогом] - [Сумма расторжений по КП нарастающим итогом] - [Расходы на комиссионные продукты]+[Сумма комиссионных продуктов уплачено] ,
[Прибыль] = -[Фондирование нарастающим итогом]-[Расходы на выдачу конкретного займа] + [Проценты уплачено  нарастающим итогом] - [Сумма расторжений по КП нарастающим итогом] - [Расходы на комиссионные продукты]+[Сумма комиссионных продуктов уплачено] + [Прибыль комиссия при платеже нарастающим итогом]+ [Прибыль от дополнительных комиссий нарастающим итогом],
[Расходы на выдачу конкретного займа],
[Дата первого платежа]
,      case when d=[Дата первого платежа] then 1 else 0 end as [First_repayment_date]
,      case when d=dateadd(day, 1, [Дата первого платежа]) then 1 else 0 end as [fpd0_d]
,     dateadd(day, 1, [Дата первого платежа])  [fpd0_date]
,      case when d=dateadd(day, 31, [Дата первого платежа]) then 1 else 0 end as [fpd30_d]
,     dateadd(day, 31, [Дата первого платежа])  [fpd30_date]

, [Дата актуальности портфеля]
from #cmr            
--where Код='21030300085101'
--order by d
 )

-- select * from cmr_costs where external_id='21051900107162' order by d
 
--19051925340002
select Код              

,      [Фондирование итого] = isnull(sum(Фондирование)      , 0)    
,      [Проценты уплачено итого] = isnull(sum([Проценты уплачено])      , 0)    
,      [Основной долг уплачено итого] = isnull(sum([Основной долг уплачено]) , 0)    
,      [Сумма поступлений итого] = isnull(sum([сумма поступлений]) , 0)           

,      [Дата займ впервые прибыльный] = min(case when Прибыль >= 0 then d end ) 


,      [Текущая прибыль] = min(case when d=          [Последний день в портфеле] then  Прибыль  end ) 
,      [Прибыль комиссия при платеже] = min(case when d=          [Последний день в портфеле] then  [Прибыль комиссия при платеже нарастающим итогом]  end ) 
,      [Прибыль от дополнительных комиссий] = min(case when d=          [Последний день в портфеле] then  [Прибыль от дополнительных комиссий нарастающим итогом]  end ) 
,      [Сумма комиссионных продуктов Carmoney Net cash] = min(case when d=          [Последний день в портфеле] then  - [Расходы на комиссионные продукты]+[Сумма комиссионных продуктов уплачено]  end ) 


,      [Прибыль через 1 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 1 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  1 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 2 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 2 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  2 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 3 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 3 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  3 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 4 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 4 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  4 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 5 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 5 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  5 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 6 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 6 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  6 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 7 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 7 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  7 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 8 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 8 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  8 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 9 мес]  =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 9 ,  cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  9 , cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 10 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 10 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  10, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 11 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 11 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  11, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 12 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 12 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  12, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 13 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 13 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  13, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 14 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 14 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  14, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 15 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 15 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  15, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 16 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 16 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  16, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 17 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 17 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  17, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 18 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 18 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  18, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 19 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 19 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  19, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 20 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 20 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  20, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 21 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 21 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  21, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 22 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 22 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  22, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 23 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 23 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  23, cmr.ContractStartDate) end then  Прибыль  end ) 
,      [Прибыль через 24 мес] =  min(case when d=case when [Последний день в портфеле] <=dateadd(month, 24 , cmr.ContractStartDate) then  [Последний день в портфеле] else dateadd(month,  24, cmr.ContractStartDate) end then  Прибыль  end ) 


,      [Максимальная просрочка] = isnull(max(dpd_begin_day), 0) 
,      [Текущая просрочка] = case when max(case when d=@cmr_date then dpd end)>=1 then max(case when d=@cmr_date then dpd end) else 0 end 
,      [Просрока 91+ текущая] = case when max(case when d=@cmr_date then dpd end)>=91 then 1 else 0 end 
,      [Просрока 91+ историческая] = max(case when dpd>=91 then 1 end) 

,      [fpd0] = case 
              when min([Дата актуальности портфеля])<min([fpd0_date]) then null
			  when max([fpd0_d]) = 1 then  
											case when max(case when [fpd0_d]=1 then dpd end) >0 then 1
											     else 0 end
              when min(contractenddate) < max([fpd0_date])  then  0
			  end
			  
--, fpd30 = case 
--              when min([Дата актуальности портфеля])<min([fpd30_date]) then null
--			  when max([fpd30_d]) = 1 then  
--											case when max(case when [fpd30_d]=1 then dpd end) >27 then 1
--											     else 0 end
--              when min(contractenddate) < max([fpd30_date])  then  0
--			  end


into #balance
from  cmr_costs cmr
group by Код



drop table if exists #next_repayment
;
with v as (
select ДатаПлатежа [Дата следующего платежа], СуммаПлатежа [Сумма следующего платежа], Договор, ROW_NUMBER() over (partition by Договор order by ДатаПлатежа) rn from DWH2.dm.CMRExpectedRepayments
where СуммаПлатежа>0 and ДатаПлатежа>=cast(getdate() as date)

)
select *  into #next_repayment  from v
where rn=1
--select * from #balance


drop table if exists #first_repayment_fact
;
with v as(
select Дата [Дата первого платежа факт],Сумма [Сумма первого платежа факт], Код , ROW_NUMBER() over(partition by Код order by Дата) rn 
from Analytics.dbo.v_repayments
)

select * into #first_repayment_fact  from v
where rn=1
--order by 


drop table if exists #last_repayment_fact
;
with v as(
select Дата [Дата последнего платежа факт],Сумма [Сумма последнего платежа факт],ссылка [Последний платеж факт ссылка], Код , ROW_NUMBER() over(partition by Код order by Дата desc) rn , [Платежная система последнего платежа] = ПлатежнаяСистема
from Analytics.dbo.v_repayments
)

select * into #last_repayment_fact  from v
where rn=1
--order by 


drop table if exists #loans_final
--	with v as (

select 
 d.[Ссылка договор CMR]
,d.код
,d.[Номер заявки]
,d.[Дата заявки]
,cast(d.[Дата заявки] as date) [Дата заявки день]
,cast(format( [Дата заявки]  , 'yyyy-MM-01') as date)   [Дата заявки месяц]
,d.isInstallment  
,d.CRMClientGUID
,d.[Дата договора]
,d.[Дата договора день]
,d.[Дата договора месяц]
,d.Сумма
,d.Срок

---------------------------
---------------------------
,loan_params.product
,loan_params.[Вид займа]
,case when loan_params.[Вид займа]='Параллельный' then 'Докредитование' else loan_params.[Вид займа] end as [Повторность займа]
,case when loan_params.[Вид займа]='Первичный' then 'Первичный' else 'Повторный' end as [Признак первичный займ]
,loan_params.Канал
,loan_params.[Способ оформления займа]
,loan_params.Источник
,loan_params.Должность
,loan_params.[Цель займа]
,loan_params.[Цель займа аналитическая]
,loan_params.[Агент партнер]
,loan_params.[Признак ПЭП3]

,loan_params.[Номер договора Спейс] 
,loan_params.[Стадия договора Спейс]
,loan_params.[Статус договора Спейс]
,loan_params.[id клиента Спейс] 
,loan_params.[Телефон клиента Спейс]
,loan_params.[CRMClientGUID Спейс]
,loan_params.[Телефон договор CMR]

, loan_params.[Стоимость ТС] 
, loan_params.[Guid тс]      
, loan_params.[VIN]            
, loan_params.[Год тс]     
, loan_params.[Марка тс]     
, loan_params.[Модель тс]    

, loan_params.[Адрес Проживания CRM]    


,loan_params.[Текущая процентная ставка]
,loan_params.[Первая процентная ставка]
,loan_params.[Последняя процентная ставка 14 дней]
,loan_params.[Признак КП снижающий ставку]
,loan_params.[Сумма комиссионных продуктов]                   
,loan_params.[Сумма комиссионных продуктов Carmoney]        
,loan_params.[Сумма комиссионных продуктов Carmoney Net]        

,loan_params.[Признак каско]                                       
,loan_params.[Признак страхование жизни]                           
,loan_params.[Признак РАТ]                                         
,loan_params.[Признак помощь бизнесу]                              
,loan_params.[Признак телемедицина]                                
,loan_params.[Признак защита от потери работы]                     
,loan_params.[Признак фарма]                                       
,loan_params.[Признак cпокойная жизнь]                             
,loan_params.[Сумма каско]                                         
,loan_params.[Сумма каско Carmoney]                                
,loan_params.[Сумма каско Carmoney Net]                            
,loan_params.[Сумма страхование жизни]                             
,loan_params.[Сумма страхование жизни Carmoney]                    
,loan_params.[Сумма страхование жизни Carmoney Net]                
,loan_params.[Сумма РАТ]                                           
,loan_params.[Сумма РАТ Carmoney]                                  
,loan_params.[Сумма РАТ Carmoney Net]                              
,loan_params.[Сумма помощь бизнесу]                                
,loan_params.[Сумма помощь бизнесу Carmoney]                       
,loan_params.[Сумма помощь бизнесу Carmoney Net]                   
,loan_params.[Сумма телемедицина]                                  
,loan_params.[Сумма телемедицина Carmoney]                         
,loan_params.[Сумма телемедицина Carmoney Net]                     
,loan_params.[Сумма защита от потери работы]                       
,loan_params.[Сумма защита от потери работы Carmoney]              
,loan_params.[Сумма защита от потери работы Carmoney Net]          
,loan_params.[Сумма фарма]                                         
,loan_params.[Сумма фарма Carmoney]                                
,loan_params.[Сумма фарма Carmoney Net]                            
,loan_params.[Сумма спокойная жизнь]                               
,loan_params.[Сумма спокойная жизнь Carmoney]                      
,loan_params.[Сумма спокойная жизнь Carmoney Net]     


,loan_params.[Расходы на выдачу конкретного займа]                         
,loan_params.[Расходы на выдачу конкретного займа: CPA]
,loan_params.[Расходы на выдачу конкретного займа: CPC]
,loan_params.[Расходы на выдачу конкретного займа: Партнеры привлечение]
,loan_params.[Расходы на выдачу конкретного займа: Партнеры оформление]
,loan_params.[Расходы на выдачу конкретного займа: Медийка и Прочие расходы]
,loan_params.[Расходы на выдачу конкретного займа: КЦ]
,loan_params.[Расходы на выдачу конкретного займа: ПШ]
,loan_params.[Расходы на выдачу конкретного займа: Риск-сервисы и верификация]
,loan_params.[Расходы на выдачу конкретного займа: CPA затраты на заявки без займа]
,loan_params.[Расходы на выдачу конкретного займа: Риск-сервисы и верификация затраты на заявки без займа]
,case when loan_params.[Расходы на выдачу конкретного займа]>0 then 1 else 0 end [Признак стоимость займа]
,loan_params.[Сумма расторжений по КП]
,loan_params.[Прибыль комиссия при платеже]
,loan_params.[Прибыль от дополнительных комиссий]

,loan_params.[Признак расторжение КП]

---------------------------
---------------------------
,loan_params.[Дата первого заявления на ЧДП]
,loan_params.[Дата последнего заявления на ЧДП]
,isnull(loan_params.[Заявлений на ЧДП], 0) [Заявлений на ЧДП]

---------------------------
---------------------------
---------------------------
---------------------------
, datediff(day, [Дата выдачи день] , loan_params.[Дата первого предложения докредитования] ) [Дней до первого предложения докредитования]
, loan_params.[Дата первого предложения докредитования]
, loan_params.[Лимит первого предложения докредитования]

---------------------------
---------------------------
, datediff(day, [Погашен] , loan_params.[Дата первого предложения повторного займа] ) [Дней до первого предложения повторного займа]
, loan_params.[Дата первого предложения повторного займа]
, loan_params.[Лимит первого предложения повторного займа]

---------------------------
---------------------------
,[Фондирование итого] = b.[Фондирование итого] 
,[Проценты уплачено итого] = b.[Проценты уплачено итого] 
,[Основной долг уплачено итого] = b.[Основной долг уплачено итого] 
,[Сумма поступлений итого]= b.[Сумма поступлений итого]


,b.[Текущая прибыль]
,b.[Сумма комиссионных продуктов Carmoney Net cash]
,b.[Дата займ впервые прибыльный]
,      b.[Прибыль через 1 мес]  
,      b.[Прибыль через 2 мес]  
,      b.[Прибыль через 3 мес]  
,      b.[Прибыль через 4 мес]  
,      b.[Прибыль через 5 мес]  
,      b.[Прибыль через 6 мес]  
,      b.[Прибыль через 7 мес]  
,      b.[Прибыль через 8 мес]  
,      b.[Прибыль через 9 мес]  
,      b.[Прибыль через 10 мес] 
,      b.[Прибыль через 11 мес] 
,      b.[Прибыль через 12 мес] 
,      b.[Прибыль через 13 мес] 
,      b.[Прибыль через 14 мес] 
,      b.[Прибыль через 15 мес] 
,      b.[Прибыль через 16 мес] 
,      b.[Прибыль через 17 мес] 
,      b.[Прибыль через 18 мес] 
,      b.[Прибыль через 19 мес] 
,      b.[Прибыль через 20 мес] 
,      b.[Прибыль через 21 мес] 
,      b.[Прибыль через 22 мес] 
,      b.[Прибыль через 23 мес] 
,      b.[Прибыль через 24 мес] 


,      [Максимальная просрочка] 
,      [Текущая просрочка]
,      [Просрока 91+ текущая] 
,      [Просрока 91+ историческая] 

,      [fpd0]


---------------------------


---------------------------
---------------------------
--,d.СуммаДопПродуктов

,d.[Дата выдачи]
,d.[Дата выдачи день]
,d.[Дата выдачи месяц]
,d.[Дата документа выдача денежных средств]
,d.[Сумма клиенту на руки]
,d.[Ссылка на выдачу ДС]
,d.[Платежная система]
,d.[Способ выдачи ДС]

---------------------------
---------------------------
,Зарегистрирован as [Дата статуса Зарегистрирован]
,Действует as [Дата статуса Действует]
,Погашен as [Дата погашения]
,[Дата погашения день] 
,[Дата погашения месяц]
,case when Погашен is not null then 1 else 0 end as [Признак погашен]
,Legal as [Дата статуса Legal]
,Аннулирован as [Дата статуса Аннулирован]
,[Решение Суда] as [Дата статуса Решение Суда]
,[Приостановка Начислений] as [Дата статуса Приостановка Начислений]
,[Продан] as [Дата статуса Продан]
,[Проблемный] as [Дата статуса Проблемный]
,[ПлатежОпаздывает] as [Дата статуса ПлатежОпаздывает]
,[Просрочен] as [Дата статуса Просрочен]
,[Внебаланс] as [Дата статуса Внебаланс]

---------------------------
---------------------------
, case when Погашен is null then nr.[Дата следующего платежа] end [Дата следующего платежа]
, case when Погашен is null then nr.[Сумма следующего платежа] end [Сумма следующего платежа]
,datediff(day, Действует, isnull(Погашен, getdate())) [Срок жизни займа]
,Analytics.dbo.FullMonthsSeparation(Действует, isnull(Погашен, getdate())) [Срок жизни займа полные месяцы]

---------------------------
---------------------------
,per.[Дата переноса платежа] [Дата переноса платежа]
,case when per.[Дата переноса платежа] is not null then 1 else 0 end [Признак перенос даты платежа]
,per.[Следующая дата платежа при переносе] [Следующая дата платежа при переносе]
,per.[Новая дата платежа при переносе]    [Новая дата платежа при переносе]
,per.[Максимальная дата платежа при переносе] [Максимальная дата платежа при переносе]

---------------------------
---------------------------
, kk.[Дата начала КК]
, kk.[Дата окончания КК]
, isnull(kk.[Текущие КК]	   , 0) [Текущие КК]	   
, isnull(kk.[Предоставлены КК] , 0) [Предоставлены КК] 

---------------------------
,fr.[Дата первого платежа] [Дата первого платежа]
,fr_fact.[Дата первого платежа факт] [Дата первого платежа факт]
,fr_fact.[Сумма первого платежа факт] [Сумма первого платежа факт]
,lr_fact.[Дата последнего платежа факт] [Дата последнего платежа факт]
,lr_fact.[Сумма последнего платежа факт] [Сумма последнего платежа факт]
,lr_fact.[Последний платеж факт ссылка] [Последний платеж факт ссылка]
,lr_fact.[Платежная система последнего платежа] [Платежная система последнего платежа]


---------------------------
, case when datediff(day, Действует, Погашен)<=30 then 1 else 0 end [ПДП 30 дней]
, case when datediff(day, Действует, Погашен)<=60 then 1 else 0 end [ПДП 60 дней]
, case when datediff(day, Действует, Погашен)<=90 then 1 else 0 end [ПДП 90 дней]

---------------------------
---------------------------
, dgp.[ПСК первоначальная]
, dgp.[Сумма ПСК первоначальная] 
, [Размер платежа первоначальный] = fr.[Сумма первого платежа]
--, [Размер платежа первоначальный] = dgp.[Размер платежа первоначальный]
, [Ссылка на первый график] = dgp.Ссылка

---------------------------
---------------------------
, dg_last.[ПСК текущая]
, dg_last.[Сумма ПСК текущая]
--, [Размер платежа первоначальный] = dgp.[Размер платежа первоначальный]
, [Ссылка на текущий график] = dg_last.Ссылка

---------------------------
---------------------------


, case when loan_params.product = 'Рефинансирование' then case when loan_params.[Текущая процентная ставка] < loan_params.[Первая процентная ставка] then 1 else 0 end end as [Признак снижение ставки по рефинансированию]
---------------------------
---------------------------
, getdate() as [Дата обновления записи по займу]

---------------------------
---------------------------
, row_number() over(partition by d.CRMClientGUID order by Действует) [Порядковый номер займа]
, row_number() over(partition by d.CRMClientGUID, case when loan_params.[Вид займа]='Параллельный' then 'Докредитование' else loan_params.[Вид займа] end order by Действует) [Порядковый номер займа по виду займа]
, cast(loan_params.Регион as nvarchar(50)) Регион
, isnull(loan_params.ispdl, 0)	ispdl
, loan_params.fioBirthday 
, loan_params.passportSerialNumber 
, loan_params.productType
--alter table report_loans --alter table report_loans			   --alter table report_loans
--add   Регион nvarchar(50)--add   fioBirthday nvarchar(150)	   --add   passportSerialNumber nvarchar(10)

--alter table report_loans
--add   productType  varchar(15)

 
into #loans_final
from #Справочник_Договоры  d

--	select * from stg._1cCMR.Справочник_СтатусыДоговоров
--	order by Код
--left join #statuses v000000001 on v000000001.Статус=0x80D900155D64100111E78663D3A87B82 and v000000001.Договор=d.[Ссылка договор CMR]
--     join #statuses v000000002 on v000000002.Статус=0x80D900155D64100111E78663D3A87B80 and v000000002.Договор=d.[Ссылка договор CMR] and v000000002.Период >='20160301'
--left join #statuses v000000003 on v000000003.Статус=0x80D900155D64100111E78663D3A87B81 and v000000003.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000004 on v000000004.Статус=0x80E400155D64100111E7C5361FF4393C and v000000004.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000005 on v000000005.Статус=0x80E400155D64100111E7C5361FF4393D and v000000005.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000006 on v000000006.Статус=0x80E400155D64100111E7C5361FF4393B and v000000006.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000007 on v000000007.Статус=0x80E400155D64100111E7C5361FF4393E and v000000007.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000008 on v000000008.Статус=0x814E00155D01BF0711E83DC81768DD68 and v000000008.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000009 on v000000009.Статус=0xB81600155D4D0B5211E983FB9CB8EE60 and v000000009.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000010 on v000000010.Статус=0xB81600155D4D0B5211E983FB9CB8EE5F and v000000010.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000011 on v000000011.Статус=0xB81600155D4D0B5211E983FB9CB8EE61 and v000000011.Договор=d.[Ссылка договор CMR]
--left join #statuses v000000012 on v000000012.Статус=0xB81700155D4D0B5211E9F50AF09A29DF and v000000012.Договор=d.[Ссылка договор CMR]
--
--left join #payments p on p.Договор=d.[Ссылка договор CMR]

left join #next_repayment nr on nr.Договор=d.[Ссылка договор CMR]
left join #first_repayment fr on fr.Код=d.код
left join #first_repayment_fact fr_fact on fr_fact.Код=d.код
left join #last_repayment_fact lr_fact on lr_fact.Код=d.код


left join #balance b on b.Код=d.код


left join #Документ_ГрафикПлатежей_первый_платеж dgp on dgp.Договор=d.[Ссылка договор CMR]
left join #Документ_ГрафикПлатежей_последний dg_last on dg_last.Договор=d.[Ссылка договор CMR]

left join #perenos per on per.Договор=d.[Ссылка договор CMR]
left join #kk kk on kk.Договор=d.[Ссылка договор CMR]
left join #loan_params loan_params on loan_params.код=d.код
;with v  as (select *, row_number() over(partition by [Ссылка договор CMR] order by (select null)) rn_delete from #loans_final ) delete from v where rn_delete>1

--select * from #loans_final
--where код='21090900135078'

drop table if exists #mp_users
 select * into #mp_users from (
 select cast(cd.user_id as nvarchar(10)) username , 4 n from stg._lk.[mp_collection_devices] cd  union all
 select cast(u.username as nvarchar(10)) username , 2 n from stg._lk.requests r  join stg._lk.users u on u.id=r.client_id where requests_origin_id=1  union all
 select cast(u.username as nvarchar(10)) username , 3 n from stg._lk.requests r  join stg._LK.requests_events re on re.request_id=r.id and re.event_id  between 24 and 32 join stg._lk.users u on u.id=r.client_id  union all
 select cast(u.username as nvarchar(10)) username , 1 n from stg._lk.users u     join stg._lk.register_mp r_mp  on u.id=r_mp.user_id 
 )  x

 ;with v  as (select *, row_number() over(partition by username order by (select null)) rn from #mp_users ) delete from v where rn>1 or len(username)<>10 
 --select * from  stg._lk.users u 

drop table if exists #clients
select CRMClientGUID [GUID]
,      [Дата выдачи первого займа]                     = max(case when [Порядковый номер займа]=1 then [Дата выдачи]  end)                                                              
,      [Дата выдачи последнего займа]                  = max([Дата выдачи]  )                                                                                                         
,      [Месяц выдачи первого займа]                    = max(case when [Порядковый номер займа]=1 then [Дата выдачи месяц] end)                                                              
,      [Код первого займа]                             = max(case when [Порядковый номер займа]=1 then Код         end)                                                                      
,      [Канал первого займа]                           = max(case when [Порядковый номер займа]=1 then Канал         end)                                                                    
,      [Расторгал договоры КП]                         = max( [Признак расторжение КП]         )                                                                                             
,      [ПДП 30 дней первый займ]                       = max(case when [Порядковый номер займа]=1 then [ПДП 30 дней]         end)                                                            
,      [Совершал ПДП 30 дней]                          = max( [ПДП 30 дней]      )                                                                                                           
,      [Оформлял страховку]                            = max( [Признак КП снижающий ставку]      )                                                                                                     
,      [Признак текущий клиент]                        = max(case when [Признак погашен] =0 then 1 else 0        end)                                                                        
,      [Признак есть займы без учтенных расходов на выдачу]      = case when min(case when  [Признак стоимость займа] =1 then 1    else 0     end) =0 then 1 else 0 end                                
,      [Признак есть учтенные расходы по клиенту на выдачу]      = case when max(case when [Порядковый номер займа]=1 and [Признак стоимость займа] =1 then 1         end)    =1 then 1 else 0 end     
,      [Займов всего]                                  = max([Порядковый номер займа])                                                                                                       
,      [Повторных займов всего]                        = max(case when [Повторность займа] = 'Повторный' then [Порядковый номер займа по виду займа] end)                                    
,      [Средний срок жизни займа]                      = avg(case when [Признак погашен]=1 then [Срок жизни займа] end)                                                                      
,      [Список договоров клиента]                      = STRING_AGG(код, '/') WITHIN GROUP (ORDER BY [Дата выдачи])                                                                               
,      [Список транспортных средств клиента]           = isnull((select  STRING_AGG(VIN, '/') WITHIN GROUP (ORDER BY [Дата выдачи])  from (select  CRMClientGUID , VIN, min([Дата выдачи])[Дата выдачи]          from  #loans_final l where l.CRMClientGUID = lh.CRMClientGUID group by CRMClientGUID , VIN) z), '')                                                                      
,      [Список транспортных средств клиента в залоге]           = isnull((select  STRING_AGG(VIN, '/') WITHIN GROUP (ORDER BY [Дата выдачи])  from (select  CRMClientGUID , VIN, min([Дата выдачи])[Дата выдачи] from  #loans_final l where l.CRMClientGUID = lh.CRMClientGUID and [Признак погашен]=0 group by CRMClientGUID , VIN) z), '')                                                                      
,      [Список открытых договоров клиента]             = STRING_AGG(case when [Признак погашен]=0 then код end, '/') WITHIN GROUP (ORDER BY [Дата выдачи])                                            
into #clients
from #loans_final lh
--from report_loans lh
group by CRMClientGUID


--select * from #clients

drop table if exists #Справочник_Партнеры
SELECT CRMClientGUID=  dwh_new.[dbo].[getGUIDFrom1C_IDRREF]( [Ссылка]) 
      ,[Ссылка] [Ссылка партнер CRM]
      ,cast(dateadd(year, -2000, ДатаРождения) as date) [Дата рождения]
      ,[CRM_Фамилия] Фамилия 
      ,[CRM_Отчество] Отчество
      ,[CRM_Имя] Имя
	  ,[Пол] = case when [Пол] = 0xAFCEBF868D4361344851E8606D20B3F9 then 'Мужской'
                    when [Пол] = 0x80F4B5DF34A06D224981658CB1273444 then 'Женский' 
	                when right(replace([CRM_Отчество], ' ', ''), 1)='ч' then  'Мужской'
	                when right(replace([CRM_Отчество], ' ', ''), 1)='а' then  'Женский'
	                when [CRM_Отчество] like '%оглы%' then  'Мужской'
	                when [CRM_Отчество]like '%кызы%' then  'Женский'
	                else 'Мужской' end

into    #Справочник_Партнеры
  FROM [Stg].[_1cCRM].[Справочник_Партнеры]


  drop table if exists #crm_mobile
select b.CRMClientGUID          ,    [Основной телефон клиента CRM]  =  a.НомерТелефонаБезКодов
into #crm_mobile
from (select ссылка                  ссылка
,            [НомерТелефонаБезКодов] [НомерТелефонаБезКодов]
from stg.[_1cCRM].[Справочник_Партнеры_КонтактнаяИнформация] where [CRM_ОсновнойДляСвязи]=1 and Тип=0xA873CB4AD71D17B2459F9A70D4E2DA66 ) a
join #Справочник_Партнеры b on a.ссылка=b.[Ссылка партнер CRM] 
;with v  as (select *, row_number() over(partition by CRMClientGUID order by [Основной телефон клиента CRM] desc) rn from #crm_mobile ) delete from v where rn>1


--select a.GUID, [Список договоров клиента], a.[Основной телефон клиента CRM], b.[Основной телефон клиента CRM] from mv_clients a left join #crm_mobile b on a.GUID=b.CRMClientGUID 
--where isnull(a.[Основной телефон клиента CRM] , '') <>isnull(b.[Основной телефон клиента CRM], '')
--19112710000171/21052500108871/21110800150232
--21070500119331/21100800142438

drop table if exists #crm_email
select b.CRMClientGUID          ,    email  =  a.email
into #crm_email
from (select ссылка                  ссылка
,            АдресЭП email
from stg.[_1cCRM].[Справочник_Партнеры_КонтактнаяИнформация] where АдресЭП<>'' ) a
join #Справочник_Партнеры b on a.ссылка=b.[Ссылка партнер CRM] 

delete from  #crm_email where Analytics.dbo.validate_email(email, 1) is null


;with v  as (select *, row_number() over(partition by CRMClientGUID order by (select 1 ) desc) rn from #crm_email ) delete from v where rn>1

--select * from stg.[_1cCRM].[Справочник_Партнеры_КонтактнаяИнформация] where АдресЭП<>'' and Analytics.dbo.validate_email(АдресЭП, 1) is not null

drop table if exists #dip_dos
select [client_number] [Номер клиента с 8]
, [Предложение очередного займа: дата последней попытки] = max(attempt_start) 
, [Предложение очередного займа: дата последнего дозвона] = max(case when login is not null then attempt_start end)  
into #dip_dos
from reports.[dbo].[dm_report_DIP_detail_outbound_sessions]
group by [client_number]
--order by 

--select * from [Stg].[_1cCRM].[Справочник_Партнеры]


--Если номер в ЧС
drop table if exists #Номера_в_ЧС 
select cast(Phone as nvarchar(10)) [Телефон из ЧС без 8], max(create_at) [Дата внесения в ЧС] into #Номера_в_ЧС from stg._1cCRM.BlackPhoneList group by cast(Phone as nvarchar(10))
--select cast(UF_PHONE as nvarchar(10)) [Телефон из ЧС без 8], max(uf_created_at) [Дата внесения в ЧС] into #Номера_в_ЧС from stg._loginom.crib_proxy_black_phones group by cast(UF_PHONE as nvarchar(10))
;with v  as (select *, row_number() over(partition by [Телефон из ЧС без 8] order by (select null)) rn from #Номера_в_ЧС ) delete from v where rn>1

--select * from  stg._loginom.crib_proxy_black_phones


drop table if exists  #РегистрСведений_СогласияНаЭлектронноеВзаимодействие
SELECT  [Период]
      ,[Клиент]
      , dwh_new.dbo.getGUIDFrom1C_IDRREF(Клиент) CRMClientGUID
      ,dateadd(year, -2000, [ДатаПодписания]) [Дата подписания действующего ПЭП]
	  into #РегистрСведений_СогласияНаЭлектронноеВзаимодействие
  FROM [Stg].[_1cCRM].[РегистрСведений_СогласияНаЭлектронноеВзаимодействие]
  where 
  nullif([ДатаПодписания], '2001-01-01 00:00:00') is not null and
  nullif([ДатаАннулирования], '2001-01-01 00:00:00') is  null --and
--  order by [ДатаПодписания] desc

  drop table if exists #ДатыПодписанияПЭП
  select CRMClientGUID, min([Дата подписания действующего ПЭП]) [Дата подписания действующего ПЭП] into #ДатыПодписанияПЭП from #РегистрСведений_СогласияНаЭлектронноеВзаимодействие
  group by CRMClientGUID

  drop table if exists #clients_final
  select 
  c.*,
  pep.[Дата подписания действующего ПЭП] ,
  sp.[Пол],
  sp.[Дата рождения],
  sp.Фамилия,
  sp.Имя,
  sp.Отчество
  
  
  ,crm_mobile.[Основной телефон клиента CRM]  
  ,crm_email.[email] [email CRM]  
  ,Номера_в_ЧС.[Дата внесения в ЧС]
  ,case when mp_users.username is not null then 1 else 0 end as [Пользовался МП]

  ,[Предложение очередного займа: дата последней попытки]
  ,[Предложение очередного займа: дата последнего дозвона]

 , getdate() as [Дата обновления записи по клиенту]
  into #clients_final
  from #clients c
  left join #ДатыПодписанияПЭП pep on pep.CRMClientGUID=c.GUID
  left join #Справочник_Партнеры sp on sp.CRMClientGUID=c.GUID
  left join #crm_mobile crm_mobile on crm_mobile.CRMClientGUID=c.GUID
  left join #crm_email crm_email on crm_email.CRMClientGUID=c.GUID
  left join #mp_users mp_users on mp_users.username=crm_mobile.[Основной телефон клиента CRM]
  left join #dip_dos dip_dos on dip_dos.[Номер клиента с 8]='8'+crm_mobile.[Основной телефон клиента CRM]
  left join #Номера_в_ЧС Номера_в_ЧС on Номера_в_ЧС.[Телефон из ЧС без 8]=crm_mobile.[Основной телефон клиента CRM]
  
 -- select * from #clients_final
 -- order by МесяцВыдачиПервогоДоговора

  

  --------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
  

drop table if exists #t1
;

with cmr as 

(

select cmr.Код                                                                                                                
,      cmr.Сумма                                                                                                                      
,      lh.[Сумма клиенту на руки]                                                                                                                      
,      lh.CRMClientGUID                                                                                                                      
,      cmr.[Проценты уплачено]                                                                                                        
,      cmr.[Основной долг уплачено]                                                                                                   
,      cmr.[основной долг уплачено нарастающим итогом]                                                                                
,      cmr.[сумма поступлений]                                                                                                        
,      cmr.[Проценты уплачено  нарастающим итогом]                                                                                    
,      cmr.contractenddate                                                                                                            
,      cmr.ContractStartDate                                                                                                          
,      cmr.dpd                                                                                                                        
,      cmr.dpd_begin_day                                                                                                                        
,      cmr.d                                                                                                                          
,      cmr.Фондирование
,      cmr.[Фондирование нарастающим итогом]
,      cmr.[Расходы на комиссионные продукты]
,      cmr.[Расходы на выдачу конкретного займа]
,      cmr.[Сумма комиссионных продуктов Carmoney Net]
,      cmr.[Сумма комиссионных продуктов уплачено]
,      cmr.[Прибыль комиссия при платеже нарастающим итогом]
,      cmr.[Прибыль от дополнительных комиссий нарастающим итогом]
,      cmr.[Сумма расторжений по КП нарастающим итогом]
,      ch. [Признак есть займы без учтенных расходов на выдачу]
,      ch. [Признак есть учтенные расходы по клиенту на выдачу]
,      ch. [Дата выдачи первого займа]


from #cmr cmr
join #loans_final  lh  on lh.код=cmr.Код and lh.[Признак стоимость займа] =1
left join #clients_final ch  on ch.GUID=lh.CRMClientGUID and ch.[Признак есть учтенные расходы по клиенту на выдачу]=1

)


select d = d                                                                                                                                                                                                                                                       
,      ContractStartDate = ContractStartDate                                                                                                                                                                                                                       
,      ContractEndDate = ContractEndDate                                                                                                                                                                                                                           
,      Код = cmr.код                                                                                                                                                                                                                                               
,      [Проценты уплачено  нарастающим итогом] = [Проценты уплачено  нарастающим итогом]                                                                                                                                                                           
,      [основной долг уплачено нарастающим итогом] = [основной долг уплачено нарастающим итогом]                                                                                                                                                                   
,      Сумма = Сумма                                                                                                                                                                                                                                               
,      [Сумма клиенту на руки] = [Сумма клиенту на руки]                                                                                                                                                                                                           
,      [Сумма комиссионных продуктов Carmoney Net] = [Сумма комиссионных продуктов Carmoney Net]                                                                                                                                                                   
,      [Расходы на выдачу конкретного займа] =[Расходы на выдачу конкретного займа]                                                                                                                                                                                
,      CRMClientGUID = CRMClientGUID                                                                                                                                                                                                                               
,      [Признак есть займы без учтенных расходов на выдачу] = [Признак есть займы без учтенных расходов на выдачу]                                                                                                                                                 
,      [Признак есть учтенные расходы по клиенту на выдачу] = [Признак есть учтенные расходы по клиенту на выдачу]                                                                                                                                                 
,      [Дата выдачи первого займа день] = cast([Дата выдачи первого займа] as date)                                                                                                                                                                             

,      [Прибыль 2] = -[Фондирование нарастающим итогом]-[Расходы на выдачу конкретного займа] + [Проценты уплачено  нарастающим итогом] - [Сумма расторжений по КП нарастающим итогом] + [Сумма комиссионных продуктов Carmoney Net]                                   
,      [Прибыль] = -[Фондирование нарастающим итогом]-[Расходы на выдачу конкретного займа] + [Проценты уплачено  нарастающим итогом] - [Сумма расторжений по КП нарастающим итогом] - [Расходы на комиссионные продукты]+[Сумма комиссионных продуктов уплачено]+[Прибыль комиссия при платеже нарастающим итогом]+[Прибыль от дополнительных комиссий нарастающим итогом]

	into #t1

from  cmr


		create clustered index clus_indname on #t1
		(
		код
		)

		create nonclustered index noncl_indname on #t1
		(
		CRMClientGUID
		)



drop table if exists #a
select distinct d into #a from #t1 where [Признак есть учтенные расходы по клиенту на выдачу]=1

drop table if exists #b
select distinct CRMClientGUID,  [Дата выдачи первого займа день]  into #b from #t1 where [Признак есть учтенные расходы по клиенту на выдачу]=1


drop table if exists #e
select  Код,  CRMClientGUID, min(d) min_d, max(d) max_d, min(Сумма ) Сумма into #e from #t1 where [Признак есть учтенные расходы по клиенту на выдачу]=1
group by  Код,  CRMClientGUID

drop table if exists #t11

select * into #t11 from 
#a a join  #b b  on b.[Дата выдачи первого займа день]<=a.d
outer apply (select distinct Код, max_d, Сумма from #e e where e.CRMClientGUID=b.CRMClientGUID and e.min_d<=a.d) x

drop table if exists #cl_balance;

with v as (
select a.*, b.Прибыль, b.ContractEndDate from #t11 a left join #t1 b on case when a.max_d>=a.d then a.d else   a.max_d end = b.d and a.Код=b.Код

)

select d
, CRMClientGUID GUID
, min([Дата выдачи первого займа день]) [Дата выдачи первого займа день]
, max([Дата выдачи первого займа день]) [Дата выдачи последнего займа к отчетной дате]
--, max(max_d) max_d
, sum(Прибыль) Прибыль
, sum(Сумма) [Выдано клиенту нарастающим итогом]
, STRING_AGG(Код, ',') [Займы к отчетной дате]
, STRING_AGG(case when ContractEndDate<= d then null else Код end, ',') [Открытые займы к отчетной дате]

into #cl_balance 

from v
--where CRMClientGUID='ABDA03C6-08B6-11E8-A814-00155D941900'

group by d, CRMClientGUID


--select * from #cl_balance
--order by d


--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------


drop table if exists #v_repayments
SELECT [Дата]
      ,[ДеньПлатежа]
      ,[МесяцПлатежа]
      ,[ДатаОтражения]
      ,[ДатаСозданияДокумента]
      ,[Сумма]
      ,[ссылка]
      ,[Договор]
      ,[Код]
      ,[ПлатежнаяСистема]
      ,[Проведен]
      ,[ПометкаУдаления]
      ,[НомерПлатежа]
      ,[CRMClientGUID]
      ,[КомиссияCКлиента]
      ,[ДоходСКлиента]
      ,[КомиссияПШ]
      ,[Платеж через еком с комиссией для клиента]
      ,[Вид платежа]
      ,[created]
      ,[Прибыль]
	  into #v_repayments
  FROM Analytics.[dbo].[v_repayments]


  drop table if exists #repayments_final
  select 
  
         a.[Дата]
        ,[Дата платежа день] = a.[ДеньПлатежа]
        ,[Дата платежа месяц] = a.[МесяцПлатежа]
        ,[Дата платежа месяц номер] = datepart(month, [ДеньПлатежа])
        ,[Дата платежа год номер] = datepart(year, [ДеньПлатежа])
		,[Срок жизни займа к платежу] = datediff(month, l.[Дата выдачи месяц], [МесяцПлатежа]) 
        ,[Дата выдачи месяц номер] = datepart(month, [Дата выдачи месяц])
        ,[Дата выдачи год номер] = datepart(year, [Дата выдачи месяц])
        ,[Дата выдачи месяц] = [Дата выдачи месяц]
        ,[Сумма платежа] = a.[Сумма]
        ,[ссылка] = a.[ссылка]
        ,[Договор] = a.[Договор]
        ,[Код] = a.[Код]
        ,[Платежная система] = a.[ПлатежнаяСистема]
        ,[Номер платежа] = a.[НомерПлатежа]
        ,[CRMClientGUID] = a.[CRMClientGUID]
        ,[Комиссия с клиента] = a.[КомиссияCКлиента]
        ,[Доход с клиента] = a.[ДоходСКлиента]
        ,[Комиссия ПШ] = a.[КомиссияПШ]
        ,[Платеж онлайн с комиссией для клиента] = a.[Платеж через еком с комиссией для клиента]
        ,[Вид платежа] = a.[Вид платежа]
        ,[Прибыль] = a.[Прибыль]
		,[Дата погашения] = l.[Дата погашения]
		,case when a.[ДеньПлатежа] >=l.[Дата погашения день] then 1 else 0 end [Платеж в день погашения]
		
	    ,b.d
	    ,case when b.[dpd day-1] is null or b.[dpd day-1] = 0 then 0 else 1 end as [Платеж просрочка]
		into #repayments_final
	  from #v_repayments a 

  left join #loans_final l on a.Код=l.Код
  left join reports.dbo.dm_cmrstatbalance_2 b on a.Код=b.external_id and b.d =  case when a.[ДеньПлатежа] >=l.[Дата погашения день] then [Дата погашения день] else [ДеньПлатежа] end



  
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------

begin try
begin tran

truncate table Analytics.dbo.report_loans
insert into Analytics.dbo.report_loans
select * from  #loans_final
--drop index clus_indname on Analytics.dbo.report_loans
--create clustered index clus_indname on Analytics.dbo.report_loans
--(
--CRMClientGUID,
--код, 
--[Дата выдачи]
--)

commit tran
end try
	--alter table  Analytics.dbo.report_loans  add   ispdl tinyint

begin catch
	select @@TRANCOUNT
	if @@TRANCOUNT>0
		rollback transaction
	
	;throw
end catch




--begin tran
--
--truncate table Analytics.dbo.report_loans
--drop index clus_indname on Analytics.dbo.report_loans
--insert into Analytics.dbo.report_loans
--select * from  #loans_final
--create clustered index clus_indname on Analytics.dbo.report_loans
--(
--CRMClientGUID,
--код, 
--[Дата выдачи]
--)
----drop table if exists Analytics.dbo.report_loans
----select * into Analytics.dbo.report_loans from #loans_final
----create clustered index clus_indname on Analytics.dbo.report_loans
----(
----CRMClientGUID,
----код, 
----[Дата выдачи]
----)
----EXEC sp_refreshview 'v_loans'
----select top 100 код, [цель займа аналитическая] from #loans_final
----select top 100 код, [цель займа аналитическая] from v_loans
----select top 100 код, [цель займа] from v_loans
----select top 100000 * from [#Цели займов]
--
--
--commit tran


begin try
begin tran

--drop table if exists Analytics.dbo.report_clients
--select * into Analytics.dbo.report_clients from #clients_final
delete from Analytics.dbo.report_clients
insert into Analytics.dbo.report_clients
select * from  #clients_final

commit tran
end try


begin catch
	select @@TRANCOUNT
	if @@TRANCOUNT>0
		rollback transaction
	
	;throw
end catch




  --begin tran
  --
  ----drop table if exists Analytics.dbo.report_clients
  ----select * into Analytics.dbo.report_clients from #clients_final
  --delete from Analytics.dbo.report_clients
  --insert into Analytics.dbo.report_clients
  --select * from  #clients_final
  --
  --commit tran

  
--drop table if exists   #mv_loans
--select * into          #mv_loans
--                  from   v_loans
--		
--drop table if exists    mv_loans
--select top 0 * into     mv_loans  
--                  from #mv_loans
--
--delete from             mv_loans
--insert into             mv_loans
--select * from          #mv_loans
--drop table if exists   #mv_loans

  --EXEC sp_refreshview 'v_clients'
  --select top 1 * from v_clients
  

--  begin tran
--
----drop table if exists  Analytics.dbo.report_clients_day
----select * into Analytics.dbo.report_clients_day from #cl_balance
----
----create clustered index clus_indname on  Analytics.dbo.report_clients_day
----(
----d, GUID
----)
--truncate table Analytics.dbo.report_clients_day
--drop index clus_indname on  Analytics.dbo.report_clients_day
--insert into Analytics.dbo.report_clients_day
--select * from  #cl_balance
--create clustered index clus_indname on  Analytics.dbo.report_clients_day
--(
--d, GUID
--)
--commit tran 
--
--  begin tran
--
----drop table if exists  Analytics.dbo.report_loans_day
----select * into Analytics.dbo.report_loans_day from #cmr
----
----create clustered index clus_indname on  Analytics.dbo.report_loans_day
----(
----d, код
----)
--
--truncate table Analytics.dbo.report_loans_day
--drop index clus_indname on  Analytics.dbo.report_loans_day
--insert into Analytics.dbo.report_loans_day
--select * from  #cmr
--create clustered index clus_indname on  Analytics.dbo.report_loans_day
--(
--d, код
--)

--commit tran 



begin try
begin tran

 
  --drop table if exists Analytics.dbo.report_repayments
  --select * into Analytics.dbo.report_repayments  from #repayments_final
delete from Analytics.dbo.report_repayments
insert into Analytics.dbo.report_repayments
select * from  #repayments_final

commit tran
end try


begin catch
	select @@TRANCOUNT
	if @@TRANCOUNT>0
		rollback transaction
	
	;throw
end catch


if cast(getdate() as date) = '20250128'
begin exec _mv 'day'  , 1

exec log_email 'etl loan ok!'
end 

else 

begin exec _mv 'day' 

end



--update   a set a.productType = b.productType from report_loans a join v_loan_cmr b on a.код = b.number   

--exec _mv 'day' , 1



--  begin tran
--  
----  --drop table if exists Analytics.dbo.report_repayments
----  --select * into Analytics.dbo.report_repayments  from #repayments_final
----delete from Analytics.dbo.report_repayments
----insert into Analytics.dbo.report_repayments
----select * from  #repayments_final
--
--commit tran



end



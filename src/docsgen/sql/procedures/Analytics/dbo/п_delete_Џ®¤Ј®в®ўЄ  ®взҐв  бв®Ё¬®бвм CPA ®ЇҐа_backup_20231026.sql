
CREATE PROC [dbo].[Подготовка отчета стоимость CPA опер_backup_20231026]
as
begin

exec analytics.dbo.log_email 'Стоимость CPA опер started', 'p.ilin@techmoney.ru'

drop table if exists #z


select Номер, Инстолмент, Дата into #z from  stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС 

drop table if exists #fa
select  Номер, [Заем выдан], [Выданная сумма], isInstallment, [Признак Рефинансирование] [ПризнакРефинансирование]  , [Канал от источника] into #fa 
from reports.dbo.dm_Factor_Analysis_001

--select top 0 *, getdate() created into dbo.[стоимость займа #fa логирование] from #fa delete from dbo.[стоимость займа #fa логирование]
--insert into dbo.[стоимость займа #fa логирование]

--select *, getdate() created  from #fa

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] numeric(10,0),
	[UF_REGISTERED_AT] [datetime2] NULL,
	[UF_REGISTERED_AT_date] [date] NULL,
	[UF_ACTUALIZE_AT] [datetime2] NULL,
	[UF_SOURCE] [VARCHAR](128),
	[UF_ROW_ID] [VARCHAR](128),
	UF_CLB_TYPE [VARCHAR](128),
	UF_PARTNER_ID [VARCHAR](256),
	UF_SOURCE_SHADOW [VARCHAR](128),
	UF_TYPE_SHADOW [VARCHAR](128),
	[UF_LOGINOM_DECLINE] [VARCHAR](128),
	UF_STEP int,
	[UF_FULL_FORM_LEAD] int,
	[UF_REGIONS_COMPOSITE] [nvarchar] (128) NULL,
	[UF_TYPE] [VARCHAR](128),
	[UF_TARGET] [int] NULL,
	[Канал от источника] [NVARCHAR](255),
	[Группа каналов] [NVARCHAR](255),
  [UF_APPMECA_TRACKER] [varchar](128) NULL,
	[UF_LOGINOM_STATUS] [VARCHAR](128)
)

-- 
/*
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = getdate()-90, @End_Registered = getdate()-1
--SELECT @End_Registered = getdate()
--SELECT @Begin_Registered = dateadd(DAY, -100, @End_Registered)

SELECT @Begin_Registered, @End_Registered

TRUNCATE TABLE #TMP_leads

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message
*/

--DWH-1987
INSERT #TMP_leads
(
    ID,
    UF_REGISTERED_AT,
    UF_REGISTERED_AT_date,
    UF_ACTUALIZE_AT,
    UF_SOURCE,
    UF_ROW_ID,
    UF_CLB_TYPE,
    UF_PARTNER_ID,
    UF_SOURCE_SHADOW,
    UF_TYPE_SHADOW,
    UF_LOGINOM_DECLINE,
    UF_STEP,
    UF_FULL_FORM_LEAD,
    UF_REGIONS_COMPOSITE,
    UF_TYPE,
    UF_TARGET,
    [Канал от источника],
    [Группа каналов],
    UF_APPMECA_TRACKER,
    UF_LOGINOM_STATUS
)
SELECT 
	D.ID,
    D.UF_REGISTERED_AT,
    D.UF_REGISTERED_AT_date,
    D.UF_ACTUALIZE_AT,
    D.UF_SOURCE,
    D.UF_ROW_ID,
    D.UF_CLB_TYPE,
    D.UF_PARTNER_ID,
    UF_SOURCE_SHADOW = NULL,
    UF_TYPE_SHADOW = NULL,
    D.UF_LOGINOM_DECLINE,
    D.UF_STEP,
    D.UF_FULL_FORM_LEAD,
    D.UF_REGIONS_COMPOSITE,
    D.UF_TYPE,
    D.UF_TARGET,
    D.[Канал от источника],
    D.[Группа каналов],
    D.UF_APPMECA_TRACKER,
    D.UF_LOGINOM_STATUS 
FROM dbo.dm_lcrm_leads_for_report AS D


--select * into dbo.TMP_leads_90_d from  #TMP_leads
--drop table dbo.TMP_leads_90_d
--truncate table dbo.TMP_leads_90_d
--insert into  dbo.TMP_leads_90_d
--select *  from  #TMP_leads

--exec msdb.dbo.sp_start_job N'Analytics. Мониторинг наличия лидов от лидогенераторов в 9:00'


--exec select_table 'analytics.dbo.[стоимость займа #TMP_leads логирование]'


insert into #TMP_leads

select      
    [ID]   
,   [UF_REGISTERED_AT]   
,   [UF_REGISTERED_AT_date]   
,   [UF_ACTUALIZE_AT]   
,   [UF_SOURCE]   
,   [UF_ROW_ID]   
,   [UF_CLB_TYPE]   
,   [UF_PARTNER_ID]   
,   [UF_SOURCE_SHADOW]   
,   [UF_TYPE_SHADOW]   
,   [UF_LOGINOM_DECLINE]   
,   [UF_STEP]   
,   [UF_FULL_FORM_LEAD]   
,   [UF_REGIONS_COMPOSITE]   
,   [UF_TYPE]   
,   [UF_TARGET]   
,   [Канал от источника]   
,   [Группа каналов]   
,   [UF_APPMECA_TRACKER]   
,   [UF_LOGINOM_STATUS]   

from     stg._LCRM.lcrm_leads_full_channel_request
where [UF_ACTUALIZE_AT]>=getdate()-90



CREATE INDEX ix_1
ON #TMP_leads(UF_ROW_ID, ID)
WHERE UF_ROW_ID IS NOT NULL


;with v as (
	SELECT * , ROW_NUMBER() over(partition by UF_ROW_ID order by ID) rn
	FROM #TMP_leads
)
DELETE
FROM v 
WHERE rn>1 
	AND UF_ROW_ID is not null












--select *, getdate() created into dbo.[стоимость займа #TMP_leads логирование] from #TMP_leads
--insert into dbo.[стоимость займа #TMP_leads логирование]
--
--select *, getdate() created  from #TMP_leads
--select 
--	[ID] 
--	,[UF_REGISTERED_AT] 
--	,[UF_ACTUALIZE_AT]
--	,[UF_SOURCE]
--	,[UF_ROW_ID]
--	,UF_CLB_TYPE
--	,UF_PARTNER_ID            
--	,UF_SOURCE_SHADOW         
--	,UF_TYPE_SHADOW           
--	,[UF_LOGINOM_DECLINE]     
--	,UF_STEP                  
--	,[UF_FULL_FORM_LEAD]      
--	,[UF_REGIONS_COMPOSITE]   
--	,[UF_TYPE]                
--	,[UF_TARGET]              
--	,[Канал от источника]     
--	,[Группа каналов]         
--
--	into #TMP_leads
--
--from  dbo.[стоимость займа #TMP_leads логирование]
--where created='2022-08-05 09:39:14.980'


--select * from  analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
--order by ДеньЛида desc

drop table if exists #stg_table ;
--drop table if exists analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs ;

with ft  as (
select id
, UF_SOURCE UF_SOURCE
, nullif(UF_ROW_ID, '') UF_ROW_ID 
, UF_REGISTERED_AT
, [Заем выдан] UF_ISSUED_AT
, [Выданная сумма] UF_SUM_ACCEPTED 
, UF_REGIONS_COMPOSITE
, UF_STEP
, UF_TYPE  UF_TYPE
, UF_LOGINOM_DECLINE
, dateadd(year, -2000, z.Дата) UF_ACTUALIZE_AT
, isnull(b.[Канал от источника] , a.[Канал от источника]) [Канал от источника]
, UF_FULL_FORM_LEAD 
, UF_PARTNER_ID 
, case when z.Инстолмент=1 then 1 else 0 end isInstallment 
, [ПризнакРефинансирование] [ПризнакРефинансирование]
from #TMP_leads         a
left join #fa b on a.UF_ROW_ID=b.Номер
left join #z z on z.Номер=a.UF_ROW_ID
)

select ft.id                                                                         
,      ft.[Канал от источника]                                                                     
,      ft.UF_SOURCE                                                           
,      nullif(UF_ROW_ID, '') UF_ROW_ID                                                                    
,      cast(ft.UF_REGISTERED_AT  as date)                                        as ДеньЛида
,      cast(format(ft.UF_REGISTERED_AT, 'yyyy-MM-01')  as date)                                        as МесяцЛида
,      format(ft.UF_REGISTERED_AT, 'yyyy-MM-01')                                        as МесяцЛидаТекст
,      case when ft.UF_ROW_ID is not null then cast(ft.UF_ACTUALIZE_AT as date) end as ДеньЗаявки
,      case when ft.UF_ROW_ID is not null then cast(format(ft.UF_ACTUALIZE_AT, 'yyyy-MM-01') as date) end as МесяцЗаявки
,      case when ft.UF_ROW_ID is not null then format(ft.UF_ACTUALIZE_AT, 'yyyy-MM-01') end as МесяцЗаявкиТекст
,      case when ft.UF_ISSUED_AT is not null then cast(ft.UF_ISSUED_AT as date) end as ДеньЗайма
,      case when ft.UF_ISSUED_AT is not null then cast(format(ft.UF_ISSUED_AT, 'yyyy-MM-01') as date) end as МесяцЗайма
,      case when ft.UF_ISSUED_AT is not null then format(ft.UF_ISSUED_AT, 'yyyy-MM-01') end as МесяцЗаймаТекст
,      case when ft.UF_ISSUED_AT is not null then ft.UF_SUM_ACCEPTED end                    as СуммаЗайма
,        UF_TYPE                                                                        
,      ft.UF_REGIONS_COMPOSITE                                                              Регион
,      case when ft.UF_ROW_ID is not null and ft.UF_FULL_FORM_LEAD  = 1 then 1 else 0 end                                                             ПолнаяЗаявка
,      case when ft.UF_ROW_ID is not null and ft.UF_TYPE like 'api%' then 1 else 0 end                                                             ЗаявкаAPI_или_API2
,      case when  ft.UF_TYPE like 'api%' then 1 else 0 end                                                             ЛидAPI_или_API2
,      case when  ft.UF_LOGINOM_DECLINE like '%дубль%' then 1 else 0 end                                                             Лид_Дубль
,      case when ft.UF_ROW_ID is not null and ft.UF_TYPE = 'Api' then 1 else 0 end                                                             ЗаявкаAPI
,      case when ft.UF_ROW_ID is not null and ft.UF_TYPE like 'api2%' then 1 else 0 end                                                             ЗаявкаAPI2
,      UF_STEP UF_STEP
,      isInstallment
,      UF_PARTNER_ID
,      ПризнакРефинансирование
	into #stg_table
from ft with(nolock)
--join devdb.dbo.dm_report_lcrm_cpa_cpc_with_potential_payment l          on l.id=ft.id
--left join devdb.dbo.dm_report_lcrm_cpa_cpc_with_potential_payment_full_form ff          on ff.id=ft.id
--left join #st st          on st.id=ft.id
where  (( [Канал от источника]='CPA нецелевой' and UF_ROW_ID is not null) or ([Канал от источника] in ('CPA целевой', 'CPA полуцелевой') ))  


;
with v as (select *, ROW_NUMBER() over(partition by id order by (select 1 )) rn from #stg_table) delete from v where rn>1
;
--select top 0 * into  analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs   from #stg_table
delete from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs 
insert into analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
select * from #stg_table
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

drop table if exists #Справочник_лсрм

select
'Средний чек у creditors24 / creditors24_msk / creditors24_parkov_apart' Тип, МесяцЗайма ОтчетнаяДата , avg(СуммаЗайма) Метрика
into #Справочник_лсрм
from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('creditors24', 'creditors24_msk', 'creditors24_parkov_apart') and МесяцЗайма is not null and isInstallment=0
group by МесяцЗайма
union all
select
'Количество заявок у kokoc' Тип, МесяцЗаявки ОтчетнаяДата , count(*) Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('creditors24', 'creditors24_msk', 'creditors24_parkov_apart') and МесяцЗаявки is not null and isInstallment=0
group by МесяцЗаявки
union all
select
'Конверсия лид - займ у justlombard' Тип, МесяцЛида ОтчетнаяДата , count(case when  isInstallment=0 then ДеньЗайма end )/cast(COUNT(*) as float) Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE = 'justlombard'  
group by МесяцЛида
union all
select
'Число лидов у justlombard' Тип, МесяцЛида ОтчетнаяДата , COUNT(*)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE = 'justlombard' 
group by МесяцЛида

union all
select
'Количество заявок у leadgid2' Тип, МесяцЗаявки ОтчетнаяДата , COUNT(*)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE = 'leadgid2'  and МесяцЗаявки is not null  and isInstallment=0
group by МесяцЗаявки
union all
select
'Конверсия лид - заявка у leadgid2' Тип, МесяцЛида ОтчетнаяДата , count(case when  isInstallment=0 then ДеньЗаявки end)/cast(COUNT(*) as float)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE = 'leadgid2'  and МесяцЛида is not null 
group by МесяцЛида

union all
select
'Средний чек у dengipodzalog' Тип, МесяцЗайма ОтчетнаяДата , avg(СуммаЗайма)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE = 'leadgid2'  and МесяцЗайма is not null and isInstallment=0
group by МесяцЗайма

union all
select

'Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref' Тип, МесяцЗаявки ОтчетнаяДата , count(case when ЗаявкаAPI_или_API2=0 and isInstallment=0 then 1 end)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ( 'bankiru', 'bankiru_25', 'bankiru-ref')  and МесяцЗаявки is not null 
group by МесяцЗаявки


union all
select

'Выданная сумма у avtolombard-credit' Тип, МесяцЗайма ОтчетнаяДата , sum(СуммаЗайма)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE ='avtolombard-credit'  and МесяцЗайма is not null  and isInstallment=0
group by МесяцЗайма

 union all
select

'Количество займов у avtolombard-credit' Тип, МесяцЗайма ОтчетнаяДата , count(СуммаЗайма)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE ='avtolombard-credit'  and МесяцЗайма is not null  and isInstallment=0
group by МесяцЗайма



union all
select

'Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru' Тип, МесяцЗайма ОтчетнаяДата , sum(СуммаЗайма)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('avtolombard24ru', 'avtolombardsru', 'alfalombardru', 'alfalombardru', 'andrey', 'centerzalogru', 'avtolombardzalogru')  and МесяцЗайма is not null  and isInstallment=0
group by МесяцЗайма

union all
select

'Множитель займов pod-pts 20221001' Тип, МесяцЗайма ОтчетнаяДата , 1+count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('pod-pts')  and МесяцЗайма ='20221001'  and isInstallment=0
group by МесяцЗайма
union all
select

'Множитель займов ptsoff-leads 20221001' Тип, МесяцЗайма ОтчетнаяДата , 1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('ptsoff-leads')  and МесяцЗайма ='20221001'  and isInstallment=0
group by МесяцЗайма
union all
select

'Множитель займов workie-installment-ref, workie-ref 20221001' Тип, МесяцЗайма ОтчетнаяДата , 1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('workie-installment-ref', 'workie-ref')  and МесяцЗайма ='20221001' and ЗаявкаAPI_или_API2=0 and isInstallment=0
group by МесяцЗайма


union all
select

'Множитель займов click2 20221001' Тип, МесяцЗайма ОтчетнаяДата , 1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('click2')  and МесяцЗайма ='20221001' and ЗаявкаAPI_или_API2=0 and isInstallment=0
group by МесяцЗайма

union all
select

'Множитель займов mastertarget 20221001' Тип, МесяцЗайма ОтчетнаяДата , 1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('mastertarget')  and МесяцЗайма ='20221001' and ЗаявкаAPI_или_API2=0 and isInstallment=0
group by МесяцЗайма

union all
select

'Множитель займов likemoney / likemoney-ref 20221001' Тип, МесяцЗайма ОтчетнаяДата , case when sum(СуммаЗайма)<=560000 then 1.0 else 560000.0/sum(СуммаЗайма) end  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('likemoney', 'likemoney-ref')  and МесяцЗайма ='20221001' and isInstallment=0
group by МесяцЗайма

union all
select

'Множитель займов creditpts-api / crditpts 20221001' Тип, МесяцЗайма ОтчетнаяДата ,  1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('creditpts-api', 'crditpts')  and МесяцЗайма ='20221001' and isInstallment=0
group by МесяцЗайма
union all
select

'Множитель займов liknot 20221001' Тип, МесяцЗайма ОтчетнаяДата ,  1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ( 'liknot')  and МесяцЗайма ='20221001' and ЗаявкаAPI_или_API2=1 and isInstallment=0
group by МесяцЗайма

union all
select

'Множитель займов unicom24r / unicom24  20221001' Тип, МесяцЗайма ОтчетнаяДата ,  1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ( 'unicom24r', 'unicom24')  and МесяцЗайма ='20221001' and ЗаявкаAPI_или_API2=1 and isInstallment=0
group by МесяцЗайма




union all
select

'Множитель займов cityads / Refflection-api  20221001' Тип, МесяцЗайма ОтчетнаяДата ,  1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ( 'cityads', 'Refflection-api')  and МесяцЗайма ='20221001' and ЗаявкаAPI_или_API2=0 and isInstallment=0
group by МесяцЗайма

union all
select

'Множитель займов finuslugi 20221001' Тип, МесяцЗайма ОтчетнаяДата ,  1+ count(МесяцЗайма)*0.05  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ( 'finuslugi')  and МесяцЗайма ='20221001' and ЗаявкаAPI_или_API2=0 and isInstallment=0
group by МесяцЗайма



--select * from #Справочник_лсрм
--Первые 100 заявок ablead
drop table if exists #Первые100заявокablead
select top 100  UF_ROW_ID, case when count(*) over(partition by UF_SOURCE) >=100 then 1 else 0 end as ПодлежатОплате , format(max(МесяцЗаявки) over(partition by UF_SOURCE), 'yyyy-MM-dd') МесяцОплаты into #Первые100заявокablead
from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE='ablead' and UF_ROW_ID is not null
order by UF_ROW_ID desc


--select * from  Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
--where id=324115851


drop table if exists #stg_table_result

;

with v as (
--'{"cost":"'+________+'", "for":"'+'___________'+'", "month":"'+____________+'", "since":"'+'____________'+'", "till":"'+'____________'+'", "condition":"'+'____________'+'", "extra":"'+'____________'+'"}'
select a.*,
case 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE='mezentsevis' then
									   case when ДеньЗайма>='20220301' and isInstallment=0  then    
									        							   case when Регион = 'Москва'  then '{"cost":"'+format(25000 ,'0.00'          ) +'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20191014'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Регион Москва' +'"}'    
																		        when СуммаЗайма<=200000 then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00') +'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20191014'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Сумма <=200000'+'"}'   
																				                        else '{"cost":"'+format(СуммаЗайма*0.04 ,'0.00') +'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20191014'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Сумма <=200000'+'"}'   end
																		   
																				   end
									        

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE in ( 'creditors24', 'creditors24_msk', 'creditors24_parkov_apart') 


then
		case 
		
		
		when  ДеньЗайма between '20230801' and '21230430' and isInstallment=0 and Регион = 'Москва' then '{"cost":"'+format(25000 ,'0.00'          )+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Москва'+'"}'   
		when  ДеньЗайма between '20230801' and '21230430' and isInstallment=0 and UF_SOURCE = 'creditors24_parkov_apart' then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Недвижимость'+'"}'   
		when  ДеньЗайма between '20230801' and '21230430' and isInstallment=0     then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не москва'+'"}'    
        
		
		when  ДеньЗайма between '20230701' and '20230731' and isInstallment=0 and Регион = 'Москва' then '{"cost":"'+format(25000 ,'0.00'          )+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Москва'+'"}'   
		when  ДеньЗайма between '20230701' and '20230731' and isInstallment=0 and UF_SOURCE = 'creditors24_parkov_apart' then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Недвижимость'+'"}'   
		when  ДеньЗайма between '20230701' and '20230731' and isInstallment=0     then '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не москва'+'"}'    




												   				
		when  ДеньЗайма between '20230501' and '20230630' and isInstallment=0 then

											case when UF_SOURCE = 'creditors24_parkov_apart' then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Недвижимость'+'"}'   
											                                                 else '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не москва'+'"}'   end

		 when  ДеньЗайма between '20230420' and '20230430' and isInstallment=0 then

											case when Регион = 'Москва'                      then '{"cost":"'+format(25000 ,'0.00'          )+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Москва'+'"}'   
											     when UF_SOURCE = 'creditors24_parkov_apart' then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Недвижимость'+'"}'   
											                                                 else '{"cost":"'+format(СуммаЗайма*0.06 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не москва'+'"}'   end

		
		when  ДеньЗайма between '20220301' and '20230419' and isInstallment=0 then

											case when Регион = 'Москва'                      then '{"cost":"'+format(25000 ,'0.00'          )+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Москва'+'"}'   
											     when UF_SOURCE = 'creditors24_parkov_apart' then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Недвижимость'+'"}'   
											                                                 else '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не москва'+'"}'   end

										end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE = 'kokoc'  then
										case when  ДеньЗаявки>='20220301' and isInstallment=0 then
																			'{"cost":"'+format(1000 ,'0.00') +'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200801'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'1000 за заявку'+'"}' 
														
										    

										end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE = 'justlombard'  then
										case when  ДеньЗаявки>='20220301' and isInstallment=0 then
																			case when ПолнаяЗаявка=1 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'Заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210201'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Полная заявка'   +'"}'  
																			                         else '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'Заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210201'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не полная заявка'+'"}'   
																									 end
																			 end
												

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE = 'leadgid2'  then
 case 
  
      when  ДеньЗаявки between  '20230701' and '21240701' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
      when  ДеньЗаявки between  '20230701' and '21240701' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}' 
      when  ДеньЗайма  between  '20230701' and '21240701' and isInstallment=1  then                         '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'inst'+       '"}' 
	  
	  when  ДеньЗаявки between  '20230501' and '20230630' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
      when  ДеньЗаявки between  '20230501' and '20230630' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}' 
      when  ДеньЗайма  between  '20230501' and '20230630' and isInstallment=1  then                         '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'inst'+       '"}' 
											               
      when  ДеньЗаявки between  '20220301' and '20230430' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then'{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
      when  ДеньЗаявки between  '20220301' and '20230430' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}' 
      when  ДеньЗайма  between  '20220301' and '20230430' and isInstallment=1  then                          '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'inst'+       '"}' 
											               
    																																
																																					
										
	end																				

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('leadgid-installment-ref') then 
											case 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                            

											  
											end	

				
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE in ('leadcraft-installment-ref') then 
											case 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

				
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											


when UF_SOURCE='dengipodzalog' then 
											case when ДеньЗайма>='20220301' and isinstallment=0 then
															                         case when [Средний чек у dengipodzalog].Метрика<=200000 then  '{"cost":"'+format(СуммаЗайма*0.015 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20171026'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 26.10.2017г:         Средний чек < =  200 000  - 1,5% Средний чек => 200 001 <= 250 000 - 2% Средний чек => 250 001 - 2,5% '+'", "extra":"'+'[Средний чек у dengipodzalog].Метрика<=200000'+'"}'  
															                              when [Средний чек у dengipodzalog].Метрика<=250000 then  '{"cost":"'+format(СуммаЗайма*0.02  ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20171026'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 26.10.2017г:         Средний чек < =  200 000  - 1,5% Средний чек => 200 001 <= 250 000 - 2% Средний чек => 250 001 - 2,5% '+'", "extra":"'+'[Средний чек у dengipodzalog].Метрика<=250000'+'"}'  
															                              when [Средний чек у dengipodzalog].Метрика>250000 then   '{"cost":"'+format(СуммаЗайма*0.025 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20171026'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 26.10.2017г:         Средний чек < =  200 000  - 1,5% Средний чек => 200 001 <= 250 000 - 2% Средний чек => 250 001 - 2,5% '+'", "extra":"'+'[Средний чек у dengipodzalog].Метрика>250000 '+'"}'  
															                              when [Средний чек у dengipodzalog].Метрика is null then  '{"cost":"'+format(СуммаЗайма*0.015 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20171026'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 26.10.2017г:         Средний чек < =  200 000  - 1,5% Средний чек => 200 001 <= 250 000 - 2% Средний чек => 250 001 - 2,5% '+'", "extra":"'+'[Средний чек у dengipodzalog].Метрика is null'+'"}'  
																					end
																					end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('bankiros','bankiros_ru','bankiros_ru_2','mainfin_ru' ) then 
											case 
											
											when ДеньЗаявки between '20230801' and '21230801' and isInstallment=0 and ЗаявкаAPI_или_API2=1  then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
											when ДеньЗаявки between '20230801' and '21230801' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											when ДеньЗайма  between '20230801' and '21230801'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
											
											when ДеньЗаявки between '20230701' and '20230731' and isInstallment=0 and ЗаявкаAPI_или_API2=1  then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
											when ДеньЗаявки between '20230701' and '20230731' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											when ДеньЗайма  between '20230701' and '20230731'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            
											when ДеньЗаявки between '20220301' and '20230630' and isInstallment=0 and ЗаявкаAPI_или_API2=1  then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
											when ДеньЗаявки between '20220301' and '20230630' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											when ДеньЗайма  between '20220301' and '20230630'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('cityads' ) then 
case 


	 
   
when ДеньЗаявки  >= '20230801'  and isInstallment=0 then
				                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
				                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											 end

  when ДеньЗайма >= '20230801'   and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
		

   
when ДеньЗаявки between '20230427' and '20230731' and isInstallment=0 then
				                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
				                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											 end

  when ДеньЗайма between '20230427' and '20230731' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
				                            


when ДеньЗаявки between '20221101' and '20230426' and isInstallment=0 then
				                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
				                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											 end

  when ДеньЗайма between '20221101' and '20230426' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
				                            


-------------------------------
-------------------------------
											
when ДеньЗаявки between '20221001' and '20221031' and isInstallment=0 then
				                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 *ISNULL([Множитель займов cityads / Refflection-api  20221001 по заявкам].Метрика, 1)  ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
				                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 *ISNULL([Множитель займов cityads / Refflection-api  20221001 по заявкам].Метрика, 1)  ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											 end

  when ДеньЗайма between '20221001' and '20221031' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(500 *ISNULL([Множитель займов cityads / Refflection-api  20221001].Метрика, 1)  ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
				                            


-------------------------------
-------------------------------
when ДеньЗаявки between '20220301' and '20220930' and isInstallment=0 then
				                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
				                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
											 end

  when ДеньЗайма between '20220301' and '20220930' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
				                            

  
end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('cityads-installment-ref' ) then 
											case 
 when ДеньЗайма >= '20230620' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
													
										
											  
											end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('Refflection-api' ) then 
											case 
											
											
											when ДеньЗаявки >='20221101' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
																						 end
                                           
											when ДеньЗаявки between '20221001' and '20221031' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(650 *ISNULL([Множитель займов cityads / Refflection-api  20221001 по заявкам].Метрика, 1) ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
																						 end
                                            when ДеньЗаявки between '20220420' and '20220930' and isInstallment=0 then
                                                                                     case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
																						 end

							
											  
											end	
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('cpahub-installment-ref' ) then 
											case 
 when ДеньЗайма between '20230523' and '21230522' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
 when ДеньЗайма between '20230523' and '21230522' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
 
 when ДеньЗайма between '20230418' and '20230522' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(2000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
 when ДеньЗайма between '20230418' and '20230522' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
											end	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('liknot' ) then 
											case 
											
											
											
											when ДеньЗаявки>='20221101' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма>='20221101' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            
-----------------------------
											
											
											when ДеньЗаявки between '20221001' and '20221031' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300*isnull([Множитель займов liknot 20221001 по заявкам].Метрика , 1) ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700*isnull([Множитель займов liknot 20221001 по заявкам].Метрика , 1) ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма between '20221001' and '20221031' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500*isnull([Множитель займов liknot 20221001].Метрика , 1) ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            
-----------------------------
-----------------------------
											  
											
											
											when ДеньЗаявки between '20220301' and '20220930' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма between '20220301' and '20220930' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('mastertarget' ) then 
											case 

when ДеньЗаявки between'20230801' and '21230801' and isInstallment=0 and ЗаявкаAPI_или_API2=0   then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗаявки between'20230801' and '21230801' and isInstallment=0 and ЗаявкаAPI_или_API2=1 and isnull(uf_partner_id,'') not in ('8569', 'credfinyou', 'jonnic', 'kreditagregator' ) then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230801' and '21230801' and isInstallment=0 and  ЗаявкаAPI_или_API2=1  and isnull(uf_partner_id,'')   in ('8569', 'credfinyou', 'jonnic', 'kreditagregator' )  then    '{"cost":"'+format(СуммаЗайма*0.04 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230801' and '21230801' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then    '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 

												
when ДеньЗаявки between '20230701' and '20230731' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗаявки between '20230701' and '20230731' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
 when ДеньЗайма between '20230701' and '20230731' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then    '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
	 
												
when ДеньЗаявки between '20230417' and '20230630' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230417' and '20230630' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then    '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230417' and '20230630' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
	 
										                            
											-----------------------------------
											-----------------------------------
											
												when ДеньЗаявки between '20230410' and '20230416' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then
															                        
																					'{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
																						 

											  when ДеньЗайма between '20230410' and '20230416' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  when ДеньЗайма between '20230410' and '20230416' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            
											-----------------------------------
											-----------------------------------
											 	when ДеньЗаявки between '20221101' and '20230409' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then
															                        
																					'{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
																						 

											  when ДеньЗайма between '20221101' and '20230409' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  when ДеньЗайма between '20221101' and '20230409' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											
											--------------------
												--------------------
												--------------------
												
												when ДеньЗаявки between '20221001' and '20221031' and isInstallment=0 then
															                        '{"cost":"'+format(500*isnull([Множитель займов mastertarget 20221001 по заявкам].Метрика, 1) ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
																						

											  when ДеньЗайма between '20221001' and '20221031' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500*isnull([Множитель займов mastertarget 20221001].Метрика ,1) ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
												
											when ДеньЗайма between '20221001' and '20221031' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(СуммаЗайма*0.05*isnull([Множитель займов mastertarget 20221001].Метрика ,1) ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
												
												-------------------------
												-------------------------
												-------------------------
												when ДеньЗаявки between '20220901' and '20220930' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then
															                        
																					'{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
																						 

											  when ДеньЗайма between '20220901' and '20220930' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  when ДеньЗайма between '20220901' and '20220930' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											
											
											
											
											when ДеньЗаявки between '20220801' and '20220831' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then
															                            '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+''+       '"}' 
																						 

											when ДеньЗайма between '20220801' and '20220831' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then
															                            '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+''+       '"}' 
																						 

											  when ДеньЗайма between '20220801' and '20220831' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											when ДеньЗаявки between '20220301' and '20220731' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма between '20220301' and '20220731' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																
when UF_SOURCE in ('bankiros-installment-ref') then 
											case 

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																
when UF_SOURCE in ('odobrim', 'odobrimru') then 
										case when ДеньЗаявки>='20220301' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  
											end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																				
when UF_SOURCE='vbr-installment-ref' then 
                           case 


when ДеньЗайма between '20230801' and '21230801' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230525' and '20230731' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(3500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20221222' and '20230524' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            
											 
											end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																
when UF_SOURCE='vbr' then 
											case 
											   when ДеньЗаявки >= '20230801'   and isInstallment=0 then
															                        case  when ЗаявкаAPI_или_API2=0  then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'UF_STEP=3 не по api и не по api2'+'"}'
																						 end
											 
											  when ДеньЗаявки between '20230427' and '20230731'  and isInstallment=0 then
															                        case  when ЗаявкаAPI_или_API2=0  then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'UF_STEP=3 не по api и не по api2'+'"}'
																						 end
											 
											 when ДеньЗаявки between '20220601' and '20230426'  and isInstallment=0 then
															                        case  when ЗаявкаAPI_или_API2=0  then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'UF_STEP=3 не по api и не по api2'+'"}'
																						 end
											when ДеньЗаявки between '20220301'  and '20220531'  and isInstallment=0 then
															                        case  when ЗаявкаAPI_или_API2=0 and UF_STEP=3 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'UF_STEP=3 не по api и не по api2'+'"}'
																						 end
											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																				
when UF_SOURCE='leadssu' then 
                           case 						    

when ДеньЗаявки between '20230901' and '21230426' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
--when ДеньЗаявки between '20230901' and '21230426' and isInstallment=0 and ЗаявкаAPI_или_API2=0  then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
when ДеньЗаявки between '20230901' and '21230426' and isInstallment=0 and ЗаявкаAPI_или_API2=0  then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'

 when ДеньЗайма between '20230901' and '21230426' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 


when ДеньЗаявки between '20230801' and '20230831' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗаявки between '20230801' and '20230831' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'

 when ДеньЗайма between '20230801' and '20230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				               							               
										   	   
										   
when ДеньЗаявки between '20230701' and '20230731' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗаявки between '20230701' and '20230731' and day(ДеньЗаявки)<=2 and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
when ДеньЗаявки between '20230701' and '20230731' and day(ДеньЗаявки)>3  and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
when ДеньЗайма  between '20230701' and '20230731' and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                            
	

when ДеньЗаявки between '20230427' and '20230630' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗаявки between '20230427' and '20230630' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
when ДеньЗайма  between '20230427' and '20230630' and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                            


when ДеньЗаявки between '20230126' and '20230426' and isInstallment=0 then
				                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                             when ЗаявкаAPI_или_API2=0 and isnull(UF_PARTNER_ID,'')='23038' then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
				                             when ЗаявкаAPI_или_API2=0 and isnull(UF_PARTNER_ID,'')!='23038' then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
											 end

  when ДеньЗайма between '20230126' and '20230426' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                            

  
when ДеньЗаявки between '20220301' and '20230125' and isInstallment=0 then
				                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
											 end

  when ДеньЗайма between '20220301' and '20230125' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                            

  
end	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																				
when UF_SOURCE='leadssu-installment-ref' then 
                           case 

when ДеньЗайма between '20230908' and '21230907' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(3500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230908' and '21230907' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
   
when ДеньЗайма between '20230825' and '20230907' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(3000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230825' and '20230907' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

when ДеньЗайма between '20230801' and '20230824' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(3900 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230801' and '20230824' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 


when ДеньЗайма between '20230701' and '20230731' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 and UF_PARTNER_ID='6578' then  '{"cost":"'+format(5000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230701' and '20230731' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(3900 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230701' and '20230731' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

when ДеньЗайма between  '20230526'  and '20230606'  and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

when ДеньЗайма between '20230607' and '20230630' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(3900 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230607' and '20230630' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 




when ДеньЗайма between '20230501' and '20230525'  and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then                    '{"cost":"'+format(3900 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230501' and '20230525'  and isInstallment=0  then                                             '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20220301' and '20230430' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between'20220301' and '20230430' and isInstallment=0                            then  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                            

											  
											end	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																				
when UF_SOURCE='devtek' then 
                          case         
						                   when ДеньЗайма >='20220701'  and isInstallment=0 and 
										   UF_PARTNER_ID in ('112', '114', '118', '215', '217', '239', '258', '259',  '324', '326', '327', '328' ) then

                                                                                      '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
																						 
                                           when ДеньЗаявки >='20220701'  and isInstallment=0 and isnull(UF_PARTNER_ID , '') not in ('112', '114', '118', '215', '217', '239', '258', '259',  '324', '326', '327', '328' ) then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(750 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											when ДеньЗайма >='20220701'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											 when ДеньЗайма between '20220601' and '20220630'  and isInstallment=0 and 
										   UF_PARTNER_ID in ('112', '114', '118', '215', '217', '239', '258', '259',  '324', '326', '327', '328' ) then

                                                                                      '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
																						 
                                           when ДеньЗаявки between '20220601' and '20220630'  and isInstallment=0 and isnull(UF_PARTNER_ID , '') not in ('112', '114', '118', '215', '217', '239', '258', '259',  '324', '326', '327', '328' ) then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											when ДеньЗайма  between '20220601' and '20220630'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											 when ДеньЗайма between '20220301' and '20220531'  and isInstallment=0 and 
										   UF_PARTNER_ID in ('112', '114', '118', '215', '217', '239', '258', '259' ) then

                                                                                      '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
																						 
                                           when ДеньЗаявки between '20220301' and '20220531'  and isInstallment=0 and isnull(UF_PARTNER_ID , '') not in ('112', '114', '118', '215', '217', '239', '258', '259' ) then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											when ДеньЗайма between '20220301' and '20220531'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																
when UF_SOURCE in ('devtek-installment-ref') then 
											case 

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																	
when UF_SOURCE in ('leadtarget-installment-ref') then 
											case 
											    when ДеньЗайма>='20230525' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then   '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 
											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																	
when UF_SOURCE='teleport' then 
                           case when ДеньЗаявки>='20220301' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																															
when UF_SOURCE='pod-pts' then 
											case 
											
											when ДеньЗайма between  '20230701' and '21230501'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
											when ДеньЗайма between  '20230420' and '20230630'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
											
											when ДеньЗайма between  '20221101' and '20230419'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

											when ДеньЗайма between '20221001' and '20221031'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.05*isnull([Множитель займов pod-pts 20221001].Метрика, 1) ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

											when ДеньЗайма between '20220301' and '20220930'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

											 
											end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																															
when UF_SOURCE='finya-ref' then 
											case when ДеньЗайма>='20220801' and isInstallment=0 then
															                        '{"cost":"'+format(СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

											 
											end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																															
when UF_SOURCE='zaym-me' then 
											case when ДеньЗайма>='20220301'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020 г: 3% от суммы выданных займов '+'", "extra":"'+'3%'+'"}'  	

											    
											end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																								
when UF_SOURCE='filkos' then 
											case 
											
											       when ДеньЗайма>='20220701' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											
										     	 when ДеньЗайма>='20220701' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											
											
											
											
											
											      when ДеньЗаявки between '20220301' and '20220630' and isnull(UF_TYPE, '')<> 'site3_installment' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2 =1 and ПолнаяЗаявка=0 then '{"cost":"'+format(400 ,'0.00')+'", "for":"'+'Заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210501'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.05.2021г: по API: 1) 400 руб. - За заявку по лиду, переданному с минимальным набором полей: https://carmoney.ru/api/docs/#api-2_Leads-PostApiV1PublicLeadsCreate 2) 700 руб. -  За заявку по лиду, переданному с расширенным набором полей: https://carmoney.ru/api/docs/#api-3_Requests-PostApiV1PrivateRequestsCreate по Реферальной ссылке: 3) 700 руб. - За заявку'+'", "extra":"'+' ЗаявкаAPI_или_API2=1 and ПолнаяЗаявка=0 '+'"}' 
															                             else                                               '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'Заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210501'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.05.2021г: по API: 1) 400 руб. - За заявку по лиду, переданному с минимальным набором полей: https://carmoney.ru/api/docs/#api-2_Leads-PostApiV1PublicLeadsCreate 2) 700 руб. -  За заявку по лиду, переданному с расширенным набором полей: https://carmoney.ru/api/docs/#api-3_Requests-PostApiV1PrivateRequestsCreate по Реферальной ссылке: 3) 700 руб. - За заявку'+'", "extra":"'+' ЗаявкаAPI_или_API2API =0 or ПолнаяЗаявка=1  '+'"}'  
																						 end

												  when ДеньЗайма  between '20220301' and '20220630'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										
										          when ДеньЗайма  between '20220301' and '20220630'  and isInstallment=1 and   isnull(UF_TYPE, '')= 'site3_installment' then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										

											   
											end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																																			

when UF_SOURCE in ('filkos_apiinst') then 
											case 

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма>='20220301' and isInstallment=1  and isnull(UF_TYPE, '')= 'site3_installment'  then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																	


when UF_SOURCE='ipvasiliev' then 
											case when ДеньЗайма>='20220301'  and isInstallment=0  then 
											
											
											'{"cost":"'+format( СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20190301'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 01.03.2019г:             3% от суммы выданных займов  '+'", "extra":"'+'3%'+'"}' 
															                       

											   
											end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																																											
when UF_SOURCE in ('bankiru', 'bankiru_25', 'bankiru-ref') then 
											case 

--when ДеньЗаявки between '20230901' and '21221130' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                   then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
--when ДеньЗаявки between '20230901' and '21221130' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and[Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
--when ДеньЗаявки between '20230901' and '21221130' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and[Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
--when ДеньЗаявки between '20230901' and '21221130' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and[Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'




when ДеньЛида   between '20230902' and '20230930' and ЛидAPI_или_API2=1 and Лид_Дубль=0									                                                                    then '{"cost":"'+ format(1020 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
when ДеньЛида   between '20230901' and '20230901' and ЛидAPI_или_API2=1 and Лид_Дубль=0									                                                                    then '{"cost":"'+ format(1400 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  


when ДеньЗайма  between '20230801' and '20230930'  and ЗаявкаAPI_или_API2=0 and isInstallment=0                                                                                             then  '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  												  
when ДеньЛида   between '20230801' and '20230831'  and ЛидAPI_или_API2=1 and Лид_Дубль=0                                                                                                    then      '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
when ДеньЛида   between '20230711' and '20230731'  and ЛидAPI_или_API2=1 and Лид_Дубль=0                                                                                                    then      '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
when ДеньЛида   between '20230601' and '20230710'  and ЛидAPI_или_API2=1 and Лид_Дубль=0                                                                                                    then      '{"cost":"'+format(550 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
when ДеньЗайма  between '20230601' and '20230731'  and ЗаявкаAPI_или_API2=0 and isInstallment=0                                                                                             then  '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

  
when ДеньЛида between '20230501' and '20230531'  and ЛидAPI_или_API2=1 and Лид_Дубль=0 and datepart(day, ДеньЛида) between 1 and 2 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
when ДеньЛида between '20230501' and '20230531'  and ЛидAPI_или_API2=1 and Лид_Дубль=0 and datepart(day, ДеньЛида) between 3 and 10 then '{"cost":"'+format(550 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
when ДеньЛида between '20230501' and '20230531'  and ЛидAPI_или_API2=1 and Лид_Дубль=0 and datepart(day, ДеньЛида) between 11 and 18 then '{"cost":"'+format(1080 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
when ДеньЛида between '20230501' and '20230531'  and ЛидAPI_или_API2=1 and Лид_Дубль=0 and datepart(day, ДеньЛида) between 19 and 31 then '{"cost":"'+format(550 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											  																   
when ДеньЗаявки between '20230501' and '20230502' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
when ДеньЗаявки between '20230501' and '20230502' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
when ДеньЗаявки between '20230501' and '20230502' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
when ДеньЗаявки between '20230501' and '20230502' and ЗаявкаAPI_или_API2=0 and isInstallment=0 and  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
when ДеньЗайма  between '20230503' and '20230531' and ЗаявкаAPI_или_API2=0 and isInstallment=0	then null


											  		when ДеньЛида between '20230417' and '20230430'  and ЛидAPI_или_API2=1 and Лид_Дубль=0
																															then '{"cost":"'+format(550 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
											  
											  
											  when ДеньЗаявки between '20230401' and '20230416' and ЗаявкаAPI_или_API2=0 and isInstallment=0
																						then case 
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																								  end

													when ДеньЛида between '20230401' and '20230416'  and ЛидAPI_или_API2=1 and Лид_Дубль=0
																															then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
								    
									
								  
											  when ДеньЗаявки between '20230301' and '20230331' and ЗаявкаAPI_или_API2=0 and isInstallment=0
																						then case 
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																								  end

													when    ДеньЛида between '20230301' and '20230331'  and ЛидAPI_или_API2=1 and Лид_Дубль=0
																															then '{"cost":"'+format(535 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
								    
									
												
									when ДеньЗаявки between '20230215' and '20230228' and ЗаявкаAPI_или_API2=0 and isInstallment=0
																						then case 
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																								  end
									when ДеньЛида between '20230215' and '20230228' and ЛидAPI_или_API2=1 and Лид_Дубль=0

																															then '{"cost":"'+format(950 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+''+'"}'  

													--when ДеньЛида  between '20230201' and '20230214' and ЛидAPI_или_API2=1 and Лид_Дубль=0
													--																		then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
											
									
									
									
									when ДеньЗаявки between '20230201' and '20230214' and ЗаявкаAPI_или_API2=0 and isInstallment=0
																						then case 
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(1000 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																								  end

													when ДеньЛида  between '20230201' and '20230214' and ЛидAPI_или_API2=1 and Лид_Дубль=0
																															then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
											
									when ДеньЗаявки between '20221201' and '20230131' and ЗаявкаAPI_или_API2=0 and isInstallment=0
																						then case 
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(1000 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																								  end

													when ДеньЛида  between '20221201' and '20230131' and ЛидAPI_или_API2=1 and Лид_Дубль=0
																															then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
									  when ДеньЗаявки between '20220301' and '20221130' and ЗаявкаAPI_или_API2=0 and isInstallment=0
																						then case 
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																								  end

													when ДеньЛида  between '20220301' and '20221130' and ЛидAPI_или_API2=1 and Лид_Дубль=0
																															then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
											   
											end		
										
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																																											
when UF_SOURCE in ('bankiru-installment', 'bankiru-installment-ref', 'bankiru-installment-context') then 
											
											
case								

when uf_source= 'bankiru-installment-context' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'rkbr'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20231001' and '21231001' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(2400 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

when ДеньЗайма between '20230901' and '20230930' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then	  '{"cost":"'+format(3600 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230908' and '20230930' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(4800 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230901' and '20230907' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(3720 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
--when ДеньЗайма between '20230901' and '21230430'  and isInstallment=0   then						     '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
  

when ДеньЗайма between '20230701' and '20230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then	  '{"cost":"'+format(4800 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230825' and '20230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	  '{"cost":"'+format(3720 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
when ДеньЗайма between '20230701' and '20230824' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	  '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

when ДеньЗайма between '20230601' and '20230630' and day(ДеньЗайма) between 1 and 20 and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then   '{"cost":"'+format(4200 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230601' and '20230630' and day(ДеньЗайма) between 21 and 30 and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then   '{"cost":"'+format(4800 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

when ДеньЗайма between '20230601' and '20230630' and day(ДеньЗайма) between 1 and 23 and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
when ДеньЗайма between '20230601' and '20230630' and day(ДеньЗайма) between 24 and 24 and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then   '{"cost":"'+format(4000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230601' and '20230630' and day(ДеньЗайма) between 25 and 30 and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then   '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

 
when ДеньЗайма between '20230526' and '20230531' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then  '{"cost":"'+format(4200 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230503' and '20230531' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then   '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  								 
when ДеньЗайма between '20230501' and '20230502' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	 '{"cost":"'+format(2400 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

when ДеньЗайма between '20230208' and '20230430' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(2400 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230208' and '20230430'  and isInstallment=0   then						     '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230118' and '20230207' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then    '{"cost":"'+format(5000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230118' and '20230207'  and isInstallment=0   then		  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
				                            




		                                      when ДеньЗайма between '20221227' and '20230117' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between '20221227' and '20230117' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(3000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма  between '20221227' and '20230117'  and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            






											  when ДеньЗайма between '20221223' and '20221226' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗаявки between '20221223' and '20221226' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(720 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма  between '20221223' and '20221226'  and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  when ДеньЗайма between '20220301' and '20221222' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between '20220301' and '20221222' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(3000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма  between '20220301' and '20221222'  and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				
when UF_SOURCE='sravniru' then 
											case 
											     when ДеньЗаявки between '20230801' and '21230701' and ЗаявкаAPI_или_API2=0   and isInstallment=0           then  '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
											     when ДеньЗаявки between '20230701' and '20230731' and ЗаявкаAPI_или_API2=0   and isInstallment=0           then  '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
											     when ДеньЗаявки between '20220301' and '20230630' and ЗаявкаAPI_или_API2=0   and isInstallment=0           then  '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
																	                            
															                       

											   
											end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE='avtolombard-credit' then 
											case 

--when ДеньЗайма between '20230901' and '21230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика<5000000  then  '{"cost":"'+format(СуммаЗайма*0.07               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
--when ДеньЗайма between '20230901' and '21230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика <8000000  then  '{"cost":"'+format(СуммаЗайма*0.08               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"' +''+'", "extra":"' +''+''+'"}' 
--when ДеньЗайма between '20230901' and '21230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика <11000000  then  '{"cost":"'+format(СуммаЗайма*0.09               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
--when ДеньЗайма between '20230901' and '21230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика <17000000  then  '{"cost":"'+format(СуммаЗайма*0.10               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
--when ДеньЗайма between '20230901' and '21230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика >=17000000  then  '{"cost":"'+format(СуммаЗайма*0.11               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+''+'"}' 
  											
when ДеньЗайма between '20231201' and '20231231'  and isInstallment=0  then  '{"cost":"'+format(2300000.0/nullif([Количество займов у avtolombard-credit].Метрика+0.0 ,0)              ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20231101' and '20231130'  and isInstallment=0  then  '{"cost":"'+format(2300000.0/nullif([Количество займов у avtolombard-credit].Метрика+0.0 ,0)              ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20231001' and '20231031'  and isInstallment=0  then  '{"cost":"'+format(2300000.0/nullif([Количество займов у avtolombard-credit].Метрика+0.0 ,0)              ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20230901' and '20230930'  and isInstallment=0  then  '{"cost":"'+format(2300000.0/nullif([Количество займов у avtolombard-credit].Метрика+0.0 ,0)              ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20230801' and '20230831'  and isInstallment=0  then  '{"cost":"'+format(2300000.0/nullif([Количество займов у avtolombard-credit].Метрика+0.0 ,0)              ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20230701' and '20230731'  and isInstallment=0  then  '{"cost":"'+format(2800000.0/nullif([Количество займов у avtolombard-credit].Метрика+0.0 ,0)              ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 

when ДеньЗайма between '20220401' and '20230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика<5000000  then  '{"cost":"'+format(СуммаЗайма*0.07               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20220401' and '20230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика <8000000  then  '{"cost":"'+format(СуммаЗайма*0.08               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"' +''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20220401' and '20230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика <11000000  then  '{"cost":"'+format(СуммаЗайма*0.09               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20220401' and '20230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика <17000000  then  '{"cost":"'+format(СуммаЗайма*0.10               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
when ДеньЗайма between '20220401' and '20230630'  and isInstallment=0 and [Выданная сумма у avtolombard-credit].Метрика >=17000000  then  '{"cost":"'+format(СуммаЗайма*0.11               ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+''+'"}' 

											
											when ДеньЗайма  between '20240301' and '20230331' and isInstallment=0 then 
																					case when [Выданная сумма у avtolombard-credit].Метрика<5000000  then  '{"cost":"'+format(СуммаЗайма*0.07                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика <8000000  then  '{"cost":"'+format(СуммаЗайма*0.08                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"' +''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика <11000000  then  '{"cost":"'+format(СуммаЗайма*0.09                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика <15000000  then  '{"cost":"'+format(СуммаЗайма*0.10                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика >=15000000  then  '{"cost":"'+format(СуммаЗайма*0.11                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+''+'"}' 
																					     --when [Выданная сумма у avtolombard-credit].Метрика>=8000000 then  '{"cost":"'+format((8000000*0.07 + ([Выданная сумма у avtolombard-credit].Метрика-8000000)*0.08)/([Выданная сумма у avtolombard-credit].Метрика)*СуммаЗайма ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.03.2021г: Общая сумма выданных займов в отчетном периоде: до 5 млн.р. - 6% от 5 млн.р. до 8 млн.р. - 7% если от 8 млн.р. и выше: -  все, что до 8 млн р. - 7%, -  все, что от 8 млн.р. и выше - 8%'+'", "extra":"'+'[Выданная сумма у avtolombard-credit].Метрика>=8000000 c фактическим процентом = '+format((8000000*0.07 + ([Выданная сумма у avtolombard-credit].Метрика-8000000)*0.08)/([Выданная сумма у avtolombard-credit].Метрика), '0.00%')+'"}'  
																						 end
											
											   
											
											when ДеньЗайма between '20220301' and '20230228' and isInstallment=0 then 
																					case when [Выданная сумма у avtolombard-credit].Метрика<5000000  then  '{"cost":"'+format(СуммаЗайма*0.07                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'  +''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика <8000000  then  '{"cost":"'+format(СуммаЗайма*0.08                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"' +''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика <11000000  then  '{"cost":"'+format(СуммаЗайма*0.09                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика <17000000  then  '{"cost":"'+format(СуммаЗайма*0.10                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"' +''+''+'"}' 
																					     when [Выданная сумма у avtolombard-credit].Метрика >=17000000  then  '{"cost":"'+format(СуммаЗайма*0.11                                                                                                                          ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+''+'"}' 
																					     --when [Выданная сумма у avtolombard-credit].Метрика>=8000000 then  '{"cost":"'+format((8000000*0.07 + ([Выданная сумма у avtolombard-credit].Метрика-8000000)*0.08)/([Выданная сумма у avtolombard-credit].Метрика)*СуммаЗайма ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210301'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.03.2021г: Общая сумма выданных займов в отчетном периоде: до 5 млн.р. - 6% от 5 млн.р. до 8 млн.р. - 7% если от 8 млн.р. и выше: -  все, что до 8 млн р. - 7%, -  все, что от 8 млн.р. и выше - 8%'+'", "extra":"'+'[Выданная сумма у avtolombard-credit].Метрика>=8000000 c фактическим процентом = '+format((8000000*0.07 + ([Выданная сумма у avtolombard-credit].Метрика-8000000)*0.08)/([Выданная сумма у avtolombard-credit].Метрика), '0.00%')+'"}'  
																						 end
											
											   
											end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
											
when UF_SOURCE='MarketPull'               then 
													case when ДеньЗаявки>='20220301' and ЗаявкаAPI_или_API2=1  and isInstallment=0 
													
													then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20190531'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 31.05.2019г.: по API - 700 руб. за Заявку'+'", "extra":"'+' ЗаявкаAPI_или_API2=1  700р'+'"}'  
													
													end 
											

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
								
when UF_SOURCE in ('avtolombard24ru', 'avtolombardsru', 'alfalombardru', 'alfalombardru', 'andrey', 'centerzalogru', 'avtolombardzalogru' )
                                                then 
													case 
															
when ДеньЗайма between  '20230904' and '21230501'  and isInstallment=0  then  '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
when ДеньЗайма between  '20230601' and '20230903'  and isInstallment=0  then  '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
											                  
															  when ДеньЗайма between  '20230501' and '20230531'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
											                  
															  
															  when ДеньЗайма between  '20230420' and '20230430'  and isInstallment=0  then
															                        '{"cost":"'+format(СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
											
											
															
															when ДеньЗайма between '20230101' and  '20230419' and isInstallment=0  then
															                             '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20200710'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
														
														
														when ДеньЗайма between '20221201' and '20221231' and isInstallment=0  then
														
														
														case when 
														[Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru].Метрика>=2500000 
														then  '{"cost":"'+format( СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20200710'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
														else '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20200710'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
														end
														
														
														when ДеньЗайма between '20220301' and '20221130' and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20200710'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 

											         end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
											
when UF_SOURCE='Leasingu-api'               then 
case 
when ДеньЗайма between '20230904' and '21230823' and isInstallment=0	 then  '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20191201'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 01.12.2019г: 3% от суммы выданных займов'+'", "extra":"'+'3% за займ'+'"}'   
when ДеньЗайма between '20230824' and '20230903' and isInstallment=0	 then  '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20191201'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 01.12.2019г: 3% от суммы выданных займов'+'", "extra":"'+'3% за займ'+'"}'   
when ДеньЗайма between '20220301' and '20230823' and isInstallment=0	 then  '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20191201'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 01.12.2019г: 3% от суммы выданных займов'+'", "extra":"'+'3% за займ'+'"}'   


end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
											
when UF_SOURCE='Zayaffka'               then 
													case when ДеньЗайма>='20220301' and isInstallment=0
													
													then  
															
															'{"cost":"'+format( СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20191201'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 01.12.2019г: 3% от суммы выданных займов'+'", "extra":"'+'3% за займ'+'"}'   
													
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																							
when UF_SOURCE='rosavtozaim'               then 
													case when ДеньЗайма>='20220301'  and isInstallment=0

													then  
													
														'{"cost":"'+format(СуммаЗайма*0.03 ,'0.00') +'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20200218'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 18.02.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3% за займ'+'"}' 
													
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																															
when UF_SOURCE='guruleads'               then 
													case 
													
													
  when ДеньЗаявки between '20230801' and '21230701' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
  when ДеньЗаявки between '20230801' and '21230701' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
  when ДеньЗайма  between '20230801' and '21230701'  and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
  
  
  when ДеньЗаявки between '20230501' and '20230731' and isInstallment=0 and  ЗаявкаAPI_или_API2=1 then  '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
  when ДеньЗаявки between '20230501' and '20230731' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
  when ДеньЗайма between '20230501' and '20230731'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then   '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
	   
	   
	   
	   when ДеньЗаявки between '20220301' and '20230430' and isInstallment=0 then
		                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
		                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
									 end

     when ДеньЗайма between '20220301' and '20230430'  and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
		                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE in ('guruleads-installment-ref') then 
											case 
											  
											  
											  when ДеньЗайма between'20230801' and '21230701' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between'20230801'and '21230701'  and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between'20230801' and '21230701' and isInstallment=0  and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										    when ДеньЗайма between '20230801' and '21230701' and isInstallment=0 and  ЗаявкаAPI_или_API2=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										

											  when ДеньЗайма between'20230523' and '20230731' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between'20230523'and '20230731'  and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(3000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between'20230523' and '20230731' and isInstallment=0  and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										    when ДеньЗайма between '20230523' and '20230731' and isInstallment=0 and  ЗаявкаAPI_или_API2=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										
											  when ДеньЗайма between'20220801' and '20230522' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between'20220801'and '20230522'  and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between'20220801' and '20230522' and isInstallment=0  and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										    when ДеньЗайма between '20220801' and '20230522' and isInstallment=0 and  ЗаявкаAPI_или_API2=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										
											  when ДеньЗайма between '20220301' and '20220731' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between '20220301' and '20220731' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between '20220301' and '20220731' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

				
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																						
when UF_SOURCE='sbokiru'               then 
													case when ДеньЗайма >='20220301'  and isInstallment=0

													then '{"cost":"'+format( СуммаЗайма*0.03  ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+'3%'+'"}' 
													
													end
														
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																							
when UF_SOURCE in ('greenking-ref')               then 
													case when ДеньЗайма >='20230307'  and isInstallment=0

													then '{"cost":"'+format( СуммаЗайма*0.08  ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+'3%'+'"}' 
													
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																							
when UF_SOURCE in ('berkalieva-ref', 'berkalieva-leads')               then 
													case when ДеньЗайма >='20230306'  and isInstallment=0

													then '{"cost":"'+format( СуммаЗайма*0.08  ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+'3%'+'"}' 
													
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																							
when UF_SOURCE='pampadu-ref'               then 
													case when ДеньЗайма >='20220301'  and isInstallment=0

													then '{"cost":"'+format( СуммаЗайма*0.08  ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+'3%'+'"}' 
													
													end
														
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																	
when UF_SOURCE='autolombardzalogru_avtolombardzajmru'               then 
																			case 
																			
when ДеньЗайма between  '20230801' and '21230501'  and isInstallment=0  and Регион in ('Москва', 'Санкт-Петербург', 'Московская область') then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+''+'"}'  
when ДеньЗайма between  '20230801' and '21230501'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+'' +'"}'  
																			   
when ДеньЗайма between  '20230420' and '20230731'  and isInstallment=0  then   '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

when ДеньЗайма between  '20220301' and '20230419' and isInstallment=0  and Регион in ('Москва', 'Санкт-Петербург', 'Московская область') then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between  '20220301' and '20230419' and isInstallment=0    then '{"cost":"'+format( СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+'' +'"}'  


end
																														 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																		
when UF_SOURCE='zaimpodpts_ru'               then 
													case 
													
													when ДеньЗайма >='20220901'  and isInstallment=0
													
													then 
													
															'{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201110'+'", "till":"'+'now'+'", "condition":"'+' '+'", "extra":"'+'5%'+'"}'  
													
													when ДеньЗайма between '20220301' and '20220831'  and isInstallment=0
													
													then 
													
															'{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201110'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 10.11.2020г: 5% от суммы выданных займов'+'", "extra":"'+'5%'+'"}'  
													
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
--																																													
--when UF_SOURCE='metaru'               then 
--													case when ДеньЗайма >='20220301'  and isInstallment=0
--													
--													then 
--													
--																'{"cost":"'+format( СуммаЗайма*0.03,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
--													
--													end		
--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																																													
when UF_SOURCE='sksbank'               then 
													case when ДеньЗайма >='20220301'  and isInstallment=0
													
													then 
													
																'{"cost":"'+format( СуммаЗайма*0.03,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
													
													end		

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																																													
when UF_SOURCE in ('finspin', 'finspin-api')  



then 
													case 
													
													
													when ДеньЗайма between '20220401' and '21230331'   and isInstallment=1 and ЗаявкаAPI_или_API2=1
													
													                    then 
													                    
													                    			'{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
													when ДеньЗайма between '20220401' and '21230331'   and isInstallment=0
													
													                    then 
													                    
													                    			'{"cost":"'+format( СуммаЗайма*0.07,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
													
													
													when ДеньЗайма between '20220301' and '20230331'   and isInstallment=0
													
													                    then 
													                    
													                    			'{"cost":"'+format( СуммаЗайма*0.07,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
													
													end		

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
													
when UF_SOURCE='ablead'               then 
													case 
													when ДеньЗаявки >='20220301' and Первые100заявокablead.UF_ROW_ID is not null and Первые100заявокablead.ПодлежатОплате=1
													then 
													
																'{"cost":"'+format( 300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+Первые100заявокablead.МесяцОплаты+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'3%'+'"}'  
													
													when ДеньЗайма >='20220301' and Первые100заявокablead.UF_ROW_ID is null  and isInstallment=0 
													then 
													
																'{"cost":"'+format(  СуммаЗайма*0.03,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'3%'+'"}'  
													
														

													
													end	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																					
when UF_SOURCE in ('gidfinance')


                                        then 
													case 
													
													
													
													
													
													
													--when ДеньЗайма >='20220701' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then 
													--
													--		'{"cost":"'+format( СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  
													--											
													--
													--when ДеньЗаявки  >='20220701' and isInstallment=0 and ЗаявкаAPI_или_API2=0  then 
													--
													--											case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													--											    --  when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--													--											                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
													--																		   end
													--	
													--
													--when ДеньЗайма  >='20220701' and isInstallment=1 then 
													--
													--											case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													--																		   end
													--
													--
													--
													--
													when ДеньЗаявки >= '20220601' and isInstallment=0 then 
													--when ДеньЗаявки between '20220601' and '20220630' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																								      when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													when ДеньЗайма  >= '20220601' and isInstallment=1 then 
													--when ДеньЗайма  between '20220601' and '20220630' and isInstallment=1 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   end
													
													
													
													
													
													when ДеньЗаявки between '20220301' and '20220531' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													when ДеньЗайма  between '20220301' and '20220531' and isInstallment=1 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   end
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE in ('gidfinance-installment', 'gidfinance-installment-ref', 'gidfinance-target', 'gidfinance-installment-click', 'gidfinance-celevoy-installment') then 
											case 
--клики
when ДеньЗайма between '20220518' and '20230531' and isInstallment=1 and  UF_SOURCE='gidfinance-installment-click' then	  '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
when ДеньЗайма between '20220622' and '20230630' and isInstallment=1 and  UF_SOURCE='gidfinance-installment-click' then	  '{"cost":"'+format(0 ,'0.00')+'", "for":"'+'Клик'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	
--



when ДеньЗайма between '20230904' and '21230831' and isInstallment=1 and uf_source ='gidfinance-celevoy-installment' and  ЗаявкаAPI_или_API2=1 then	 '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230904' and '21230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then	 '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230904' and '21230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	 '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230904' and '21230831' and isInstallment=0   then    '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 

when ДеньЗайма between '20230901' and '20230903' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then	 '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230901' and '20230903' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	 '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230901' and '20230903' and isInstallment=0   then    '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 



when ДеньЗайма between '20230824' and '20230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then	 '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230824' and '20230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	 '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230824' and '20230831' and isInstallment=0   then    '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 


when ДеньЗайма between '20230601' and '20230823' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then	 '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230601' and '20230823' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	 '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20230601' and '20230823' and isInstallment=0   then    '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
		
when ДеньЗайма between '20220518' and '20230531' and isInstallment=1 and  ЗаявкаAPI_или_API2=1                     then	  '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20220518' and '20230531' and isInstallment=1 and  ЗаявкаAPI_или_API2=0                     then	    '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗайма between '20220518' and '20230531' and isInstallment=0                                               then	    '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 



	when ДеньЗайма between '20220301' and '20230517' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
				                                       '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
  when ДеньЗайма between '20220301' and '20230517' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
				                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
 when ДеньЗайма between '20220301'  and '20230517' and isInstallment=0   then
				                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
				                            

  
end	

				
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE in ('saleads-ref') then 
											case 

											  when ДеньЗаявки>='20221025' and isInstallment=0 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
											  when ДеньЗаявки>='20221025' and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
											 when ДеньЗайма>='20221025' and isInstallment=1   then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                            

											  
											end	

				
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
when UF_SOURCE in ('saleads-installment-ref') then 
											case 

											  when ДеньЗайма>='20221025' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
											  when ДеньЗайма>='20221025' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
											 when ДеньЗайма>='20221025' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                            

											  
											end	

				
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
														
when UF_SOURCE='selliot'               then 
													case when ДеньЗайма >='20220301'  and isInstallment=0
													
													then 
													
															'{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  
													
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE='zalogcars'               then 

case 
when ДеньЗайма  between '20230904' and '21230831'  and isInstallment=0 then  '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  
when ДеньЗайма  between '20230824' and '20230903'  and isInstallment=0 then  '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  
when ДеньЗайма  between '20230203' and '20230823'  and isInstallment=0 then  '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  
													
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE in ('credeo' , 'credeo-ref')               then 
case  

when ДеньЗайма between '20230901' and '21230823'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'8%'+'"}'  
when ДеньЗайма between '20230824' and '20230831'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'8%'+'"}'  
when ДеньЗайма between '20220501' and '20230823'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'8%'+'"}'  
when ДеньЗайма between '20220301' and '20220430'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  

end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE='admitad'               then 
													case when ДеньЗаявки >='20230125' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 1440,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													when ДеньЗаявки between '20220301' and '20230124' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 800,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
																		
when UF_SOURCE='xLAB'               then 
													case when ДеньЗаявки >='20220301' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
																		
when UF_SOURCE='el-polis'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
													
																								'{"cost":"'+format( 10000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
																		
when UF_SOURCE='rafinad'               then 
case

when ДеньЗаявки  between '20230901' and '21230731' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗаявки  between '20230701' and '20230831' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 1300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
											                             
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE='rafinad-installment-ref'              
then 

case when ДеньЗайма between '20230816' and '21230816'  and isInstallment=1 then  '{"cost":"'+format( 3000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
																		
when UF_SOURCE='zalogural-leads'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
													
																								'{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
																		
when UF_SOURCE='pobedalizing'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
													
																								'{"cost":"'+format( СуммаЗайма*0.06,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE in ('finkort-api' , 'finkort-installment-ref'  )            then 
													case 
when ДеньЗайма between '20230901' and '21230620' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( СуммаЗайма*0.06,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230901' and '21230620' and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230901' and '21230620' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 3000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
 
when ДеньЗайма between '20230824' and '20230831' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230825' and '20230831' and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230825' and '20230831' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 3000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   

when ДеньЗайма between '20230824' and '20230824' and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230824' and '20230824' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 3500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   

 
when ДеньЗайма between '20230621' and '20230823' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( СуммаЗайма*0.06,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230621' and '20230823' and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230621' and '20230823' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 3500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   

when ДеньЗайма between '20230207' and '20230620' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( СуммаЗайма*0.06,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230207' and '20230620' and isInstallment=1 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='finanso'               then 
													case when ДеньЗаявки >='20220301' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													when ДеньЗайма >='20220301' and isInstallment=1 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   end
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
																			
when UF_SOURCE='popovaa'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
													
																								'{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
																			
when UF_SOURCE in ('caltat' , 'caltat-new')     then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.06,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='click2'               then 
													case 
													when ДеньЗаявки  between '20230801' and '21230831'  and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													when ДеньЗаявки  between '20230701' and '20230731'  and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 1200,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													when ДеньЗаявки  between '20221101' and '20230630'  and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
 													when ДеньЗаявки  between '20221001' and '20221031'  and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 1200*isnull([Множитель займов click2 20221001].Метрика, 1),'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
 													when ДеньЗаявки  between '20220801' and '20220930'  and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
 													when ДеньЗаявки  between '20220301' and '20220731'  and isInstallment=0 and  ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                             
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='zalogural'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE in ('unicom24r',  'unicom24' )             then 
													case 
when ДеньЗаявки between '20230901' and '21230901' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
when ДеньЗаявки between '20230901' and '21230901' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
 when ДеньЗайма between '20230901' and '21230901' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 

											
													
														
													    when ДеньЗаявки between'20230427' and '20230831' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
																						 end

											             when ДеньЗайма between '20230427' and '20230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 

													
													
													    when ДеньЗаявки between'20221101' and '20230426' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
																						 end

											             when ДеньЗайма between '20221101' and '20230426' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 

											
													------------------------------------------------
													------------------------------------------------
													  
													    when ДеньЗаявки between '20221001' and '20221031' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300*isnull([Множитель займов unicom24r / unicom24  20221001 по заявкам].метрика, 1) ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700*isnull([Множитель займов unicom24r / unicom24  20221001 по заявкам].метрика, 1)  ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
																						 end

											             when ДеньЗайма between '20221001' and '20221031' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 * isnull([Множитель займов unicom24r / unicom24  20221001].Метрика , 1),'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 

											
													------------------------------------------------
													------------------------------------------------
													    when ДеньЗаявки between '20220301' and '20220930' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
																						 end

											             when ДеньЗайма between '20220301' and '20220930' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 

											end	



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE in ('unicom24-installment-ref') then 
											case 

 when ДеньЗайма between'20230901' and '21230701' and  isInstallment=1 and  ЗаявкаAPI_или_API2=1 then   '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
 when ДеньЗайма between'20230901' and '21230701' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then	   '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230901' and '21230701' and isInstallment=0   then	 '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            
											   when ДеньЗайма between'20230525' and '20230831' and  isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between'20230525' and '20230831'    and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(3000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between'20230525' and '20230731'    and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            
											   when ДеньЗайма between'20220401' and '20230524' and  isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between'20220401' and '20230524'    and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between'20220401' and '20230524'    and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

					
											  when ДеньЗайма between '20220301' and '20220331' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма between '20220301' and '20220331' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

				
----------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE='okb-ref'               then 
													case when ДеньЗаявки >='20220301' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 1200,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	



when UF_SOURCE='admitad-installment-ref'               then 
													case when ДеньЗайма >='20230125' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then 
																								'{"cost":"'+format(3000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	




when UF_SOURCE='pampadu-installment-ref'               then 
													case when ДеньЗайма >='20230301' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then 
																								'{"cost":"'+format(2500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	



when UF_SOURCE='click2-installment-ref  '               then 
													case when ДеньЗайма >='20230101' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then 
																								'{"cost":"'+format(2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	



when UF_SOURCE='okb-installment-ref'               then 
													case 
													
													when ДеньЗайма between '20230801' and '21230731' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(3000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													when ДеньЗайма between '20230529' and '20230731' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(4200,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   		
													when ДеньЗайма between '20220301' and '20230528' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then 	 '{"cost":"'+format(3000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE='finuslugi'               then 
													case 
													
													
													when ДеньЗаявки >='20221101' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													
													when ДеньЗаявки between '20221001' and '20221031' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700 * isnull([Множитель займов finuslugi 20221001].метрика , 1),'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													
													when ДеньЗаявки between '20220301' and '20220930' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	



when UF_SOURCE='mastertarget-installment-ref'               then 
													case 
													
													when ДеньЗайма >='20230101' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then 
																								'{"cost":"'+format(2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													when ДеньЗайма between '20211216'and '20221231' and isInstallment=1 and ЗаявкаAPI_или_API2=0 then 
																								'{"cost":"'+format(2500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='sravniru-installment-ref'              
then 
case 

when ДеньЗайма between  '20230825'  and '21230824'  and isInstallment=1 and ЗаявкаAPI_или_API2=0 then   '{"cost":"'+format(3600,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between  '20230622'  and '20230824'  and isInstallment=1 and ЗаявкаAPI_или_API2=0 then   '{"cost":"'+format(4000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма between '20230607' and '20230621'    and isInstallment=1 and ЗаявкаAPI_или_API2=0 then 	 '{"cost":"'+format(3500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
when ДеньЗайма  between '20230125' and '20230606'   and isInstallment=1 and ЗаявкаAPI_или_API2=0 then  '{"cost":"'+format(2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																		   

end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	



when UF_SOURCE='finuslugi-installment-ref'               then 
													case when ДеньЗайма >='20220301' and isInstallment=1 then 
																								'{"cost":"'+format(2500,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

--&&&&&&&&

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='workie-ref'               then 
													case 
													
													when ДеньЗайма >='20221101'  and isInstallment=0 then 
																								'{"cost":"'+format( 6000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													when ДеньЗайма between '20221001' and '20221031'  and isInstallment=0 then 
																								'{"cost":"'+format( 6000 * isnull([Множитель займов workie-installment-ref, workie-ref 20221001].Метрика , 1),'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													when ДеньЗайма between '20220301' and '20220930'  and isInstallment=0 then 
																								'{"cost":"'+format( 6000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE in ('workie-installment-ref') then 
											case 
											  when ДеньЗайма >='20221101' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма >='20221101' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  when ДеньЗайма between '20221001' and '20221031' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500* isnull([Множитель займов workie-installment-ref, workie-ref 20221001].Метрика , 1) ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between '20221001' and '20221031' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07* isnull([Множитель займов workie-installment-ref, workie-ref 20221001].Метрика , 1) ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  when ДеньЗайма between '20220301' and '20220930' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма between '20220301' and '20220930' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

				
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
  


when UF_SOURCE='bibikrp-ref'               then 
													case when ДеньЗайма between '20230523' and '21230523'   and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
  


when UF_SOURCE='sputnik-api'               then 
													case when ДеньЗайма >='20230504' and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.07,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	




when UF_SOURCE='finasset'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='bistrodengi-pts'                  then 
case  

when ДеньЗайма between '20230901' and '21230823'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'8%'+'"}'  
when ДеньЗайма between '20230824' and '20230831'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'8%'+'"}'  
when ДеньЗайма between '20220701' and '20230823'  and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'8%'+'"}'  

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='kreditrf'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='finardi-ref'               then 
													case when ДеньЗайма >='20220322'   and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='AremiGroup'               then 
													case when ДеньЗайма >='20220314'  and isInstallment=0  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='ptsoff-leads'               then 
													case when ДеньЗайма >='20221101'  and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.09,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													     when ДеньЗайма between '20221001' and '20221031'  and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.09*isnull([Множитель займов ptsoff-leads 20221001].Метрика, 1),'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													     when ДеньЗайма between '20220301' and '20220930'  and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.09,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='garantmoneyapi'               then 
case 
 

when ДеньЗайма between '20230901' and '21230823'   and isInstallment=1 and ЗаявкаAPI_или_API2=1	 then   '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
when ДеньЗайма between '20230901' and '21230823'   and isInstallment=0                           then   '{"cost":"'+format( СуммаЗайма*0.09,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   

when ДеньЗайма between '20230824' and '20230831'   and isInstallment=1 and ЗаявкаAPI_или_API2=1	 then   '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
when ДеньЗайма between '20230824' and '20230831'   and isInstallment=0                           then   '{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   

when ДеньЗайма between '20220401' and '20230823'   and isInstallment=1 and ЗаявкаAPI_или_API2=1	 then   '{"cost":"'+format( 2000,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
when ДеньЗайма between '20230401' and '20230823'   and isInstallment=0                           then   '{"cost":"'+format( СуммаЗайма*0.09,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   



when ДеньЗайма between '20220301' and '20230331'   and isInstallment=0                           then   '{"cost":"'+format( СуммаЗайма*0.09,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																		   
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--
--when UF_SOURCE='crditpts'               then 
--													case when ДеньЗайма >='20220525'  and isInstallment=0  then 
--																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																															   
--													end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='zayman-ref'               then 
													case when ДеньЗайма >='20220420'  and isInstallment=0  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE in ('creditpts-api', 'creditpts')
                                                   then 
													case 
													when ДеньЗайма >='20221101'  and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													
													
													when ДеньЗайма between '20221001' and '20221031'  and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.08*isnull([Множитель займов creditpts-api / crditpts 20221001].Метрика, 1),'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													   when ДеньЗайма between '20220527' and '20220930'  and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE='metaru'               then 
													case when ДеньЗайма >='20220301'  and isInstallment=0  then 
																								'{"cost":"'+format( СуммаЗайма*0.03,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE='inter-ural-ref'               then 
													case when ДеньЗайма >='20220324'  and isInstallment=0  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE in ('likemoney', 'likemoney-ref')               then 
													
													case 
													


													when ДеньЗаявки >='20221101' and isInstallment=0
													
																	then 
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end



														
													when ДеньЗайма between '20221001' and '20221031'  and isInstallment=0
													
																	then 
																								'{"cost":"'+format( СуммаЗайма*0.08*ISNULL([Множитель займов likemoney / likemoney-ref 20221001].Метрика, 1.0),'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													
													
													
													
													when ДеньЗаявки between '20220901' and '20220930' and isInstallment=0
													
																	then 
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end



														when ДеньЗайма between '20220527' and '20220831' and isInstallment=0
													
																	then 
																								'{"cost":"'+format( СуммаЗайма*0.1,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE in ('vzaimno-api', 'vzaimno-ref')               then 
													case when ДеньЗайма >='20220301'  and isInstallment=0 then 
																							case 
																							     when ПризнакРефинансирование=1 then	'{"cost":"'+format( СуммаЗайма*0.07,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																							     else 	'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																								end							   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE in ('leadcraft-ref' , 'leadcraft-api-pts')
                                                      then 
													case 
													   
													 when ДеньЗаявки >='20221001' and isInstallment=0  then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																								                               else '{"cost":"'+format( 500,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end

													 when ДеньЗайма  between '20220701' and '20220930' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( СуммаЗайма*0.07,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													  
													 when ДеньЗаявки between '20220701' and '20220930' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													  when ДеньЗаявки  between '20220601' and '20220630' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE in ('zapravlyaem-dengami' )
then 
case 
when ДеньЗайма between '20230901' and '21230901' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(2500            , '0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230901' and '21230901' and isInstallment=0   then                          '{"cost":"'+format(СуммаЗайма*0.08 , '0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
    
when ДеньЗайма between '20230824' and '20230831' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(2500            , '0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20230824' and '20230831' and isInstallment=0   then                          '{"cost":"'+format(СуммаЗайма*0.05 , '0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

when ДеньЗайма between '20221201' and '20230823' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(2500            , '0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
when ДеньЗайма between '20221201' and '20230823' and isInstallment=0   then                          '{"cost":"'+format(СуммаЗайма*0.08 , '0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

end json_cost_params



--into devdb.dbo.dm_report_lcrm_cpa_cpc_costs
from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs a
left join #Справочник_лсрм as [Средний чек у creditors24 / creditors24_msk / creditors24_parkov_apart] on [Средний чек у creditors24 / creditors24_msk / creditors24_parkov_apart].Тип='Средний чек у creditors24 / creditors24_msk / creditors24_parkov_apart' and 
																										  [Средний чек у creditors24 / creditors24_msk / creditors24_parkov_apart].ОтчетнаяДата=a.МесяцЗайма and
																										  a.UF_SOURCE in ('creditors24', 'creditors24_msk', 'creditors24_parkov_apart')
left join #Справочник_лсрм as [Количество заявок у kokoc по дате заявки] on [Количество заявок у kokoc по дате заявки].Тип='Количество заявок у kokoc' and 
																										  [Количество заявок у kokoc по дате заявки].ОтчетнаяДата=a.МесяцЗаявки and
																										  a.UF_SOURCE ='kokoc'
left join #Справочник_лсрм as [Количество заявок у kokoc по дате займа] on [Количество заявок у kokoc по дате займа].Тип='Количество заявок у kokoc' and 
																										  [Количество заявок у kokoc по дате займа].ОтчетнаяДата=a.МесяцЗайма and
																										  a.UF_SOURCE ='kokoc'
left join #Справочник_лсрм as [Конверсия лид - займ у justlombard] on [Конверсия лид - займ у justlombard].Тип='Конверсия лид - займ у justlombard' and 
																										  [Конверсия лид - займ у justlombard].ОтчетнаяДата=a.МесяцЗаявки and
																										  a.UF_SOURCE ='justlombard'
left join #Справочник_лсрм as [Число лидов у justlombard] on [Число лидов у justlombard].Тип='Число лидов у justlombard' and 
																										  [Число лидов у justlombard].ОтчетнаяДата=a.МесяцЗаявки and
																										  a.UF_SOURCE ='justlombard'
left join #Справочник_лсрм as [Количество заявок у leadgid2]  on [Количество заявок у leadgid2].Тип='Количество заявок у leadgid2' and 
																										  [Количество заявок у leadgid2].ОтчетнаяДата=a.МесяцЗаявки and
																										  a.UF_SOURCE ='leadgid2'
left join #Справочник_лсрм as [Конверсия лид - заявка у leadgid2]  on [Конверсия лид - заявка у leadgid2].Тип='Конверсия лид - заявка у leadgid2' and 
																										  [Конверсия лид - заявка у leadgid2].ОтчетнаяДата=a.МесяцЗаявки and
																										  a.UF_SOURCE ='leadgid2'
left join #Справочник_лсрм as [Средний чек у dengipodzalog]  on [Средний чек у dengipodzalog].Тип='Средний чек у dengipodzalog' and 
																										  [Средний чек у dengipodzalog].ОтчетнаяДата=a.МесяцЗайма and
																										  a.UF_SOURCE ='dengipodzalog'

left join #Справочник_лсрм as [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref]  on [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Тип='Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref' and 
																										  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].ОтчетнаяДата=a.МесяцЗаявки and
																										  a.UF_SOURCE in ('bankiru' , 'bankiru_25', 'bankiru-ref')

left join #Справочник_лсрм as [Выданная сумма у avtolombard-credit]  on [Выданная сумма у avtolombard-credit].Тип='Выданная сумма у avtolombard-credit' and 
																										  [Выданная сумма у avtolombard-credit].ОтчетнаяДата=a.МесяцЗайма and
																										  a.UF_SOURCE ='avtolombard-credit'
left join #Справочник_лсрм as [Количество займов у avtolombard-credit]  on [Количество займов у avtolombard-credit].Тип='Количество займов у avtolombard-credit' and 
																										  [Количество займов у avtolombard-credit].ОтчетнаяДата=a.МесяцЗайма and
																										  a.UF_SOURCE ='avtolombard-credit'
																										  
left join #Справочник_лсрм as [Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru]  on [Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru].Тип='Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru' and 
																										  [Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru].ОтчетнаяДата=a.МесяцЗайма and
																										  a.UF_SOURCE  in ('avtolombard24ru', 'avtolombardsru', 'alfalombardru', 'alfalombardru', 'andrey', 'centerzalogru', 'avtolombardzalogru')
left join #Справочник_лсрм as [Множитель займов pod-pts 20221001]                             on [Множитель займов pod-pts 20221001]                           .Тип='Множитель займов pod-pts 20221001'                            and  [Множитель займов pod-pts 20221001]                           .ОтчетнаяДата=a.МесяцЗайма  and a.UF_SOURCE  in ('pod-pts')
left join #Справочник_лсрм as [Множитель займов ptsoff-leads 20221001]                        on [Множитель займов ptsoff-leads 20221001]                      .Тип='Множитель займов ptsoff-leads 20221001'                       and  [Множитель займов ptsoff-leads 20221001]                      .ОтчетнаяДата=a.МесяцЗайма  and a.UF_SOURCE  in ('ptsoff-leads')
left join #Справочник_лсрм as [Множитель займов workie-installment-ref, workie-ref 20221001]  on [Множитель займов workie-installment-ref, workie-ref 20221001].Тип='Множитель займов workie-installment-ref, workie-ref 20221001' and  [Множитель займов workie-installment-ref, workie-ref 20221001].ОтчетнаяДата=a.МесяцЗайма  and a.UF_SOURCE  in ('workie-installment-ref', 'workie-ref')
left join #Справочник_лсрм as [Множитель займов click2 20221001]                              on [Множитель займов click2 20221001]                            .Тип='Множитель займов click2 20221001'                             and  [Множитель займов click2 20221001]                            .ОтчетнаяДата=a.МесяцЗайма  and a.UF_SOURCE  in ('click2')
left join #Справочник_лсрм as [Множитель займов mastertarget 20221001]                        on [Множитель займов mastertarget 20221001]                      .Тип='Множитель займов mastertarget 20221001'                       and  [Множитель займов mastertarget 20221001]                      .ОтчетнаяДата=a.МесяцЗайма  and a.UF_SOURCE  in ('mastertarget')
left join #Справочник_лсрм as [Множитель займов mastertarget 20221001 по заявкам]             on [Множитель займов mastertarget 20221001 по заявкам]           .Тип='Множитель займов mastertarget 20221001'                       and  [Множитель займов mastertarget 20221001 по заявкам]           .ОтчетнаяДата=a.МесяцЗаявки and a.UF_SOURCE  in ('mastertarget')

left join #Справочник_лсрм as [Множитель займов likemoney / likemoney-ref 20221001]              on [Множитель займов likemoney / likemoney-ref 20221001]            .Тип='Множитель займов likemoney / likemoney-ref 20221001'   and  [Множитель займов likemoney / likemoney-ref 20221001]             .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('likemoney' , 'likemoney-ref')
left join #Справочник_лсрм as [Множитель займов creditpts-api / crditpts 20221001]               on [Множитель займов creditpts-api / crditpts 20221001]             .Тип='Множитель займов creditpts-api / crditpts 20221001'    and  [Множитель займов creditpts-api / crditpts 20221001]              .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('creditpts-api' , 'crditpts')
left join #Справочник_лсрм as [Множитель займов liknot 20221001 по заявкам]                      on [Множитель займов liknot 20221001 по заявкам]                    .Тип='Множитель займов liknot 20221001'                      and  [Множитель займов liknot 20221001 по заявкам]                     .ОтчетнаяДата=a.МесяцЗаявки and a.UF_SOURCE  in ('liknot' )
left join #Справочник_лсрм as [Множитель займов liknot 20221001]                                 on [Множитель займов liknot 20221001]                    .Тип='Множитель займов liknot 20221001'                      and  [Множитель займов liknot 20221001]                     .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('liknot' )
left join #Справочник_лсрм as [Множитель займов unicom24r / unicom24  20221001]                  on [Множитель займов unicom24r / unicom24  20221001]                .Тип='Множитель займов unicom24r / unicom24  20221001'       and  [Множитель займов unicom24r / unicom24  20221001]                 .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('unicom24r' , 'unicom24')
left join #Справочник_лсрм as [Множитель займов unicom24r / unicom24  20221001 по заявкам]                  on [Множитель займов unicom24r / unicom24  20221001 по заявкам]                .Тип='Множитель займов unicom24r / unicom24  20221001'       and  [Множитель займов unicom24r / unicom24  20221001 по заявкам]                 .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('unicom24r' , 'unicom24')
left join #Справочник_лсрм as [Множитель займов cityads / Refflection-api  20221001]             on [Множитель займов cityads / Refflection-api  20221001]           .Тип='Множитель займов cityads / Refflection-api  20221001'  and  [Множитель займов cityads / Refflection-api  20221001]            .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('cityads' , 'Refflection-api')
left join #Справочник_лсрм as [Множитель займов cityads / Refflection-api  20221001 по заявкам]             on [Множитель займов cityads / Refflection-api  20221001 по заявкам]           .Тип='Множитель займов cityads / Refflection-api  20221001'  and  [Множитель займов cityads / Refflection-api  20221001 по заявкам]            .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('cityads' , 'Refflection-api')
left join #Справочник_лсрм as [Множитель займов finuslugi 20221001]                              on [Множитель займов finuslugi 20221001]                            .Тип='Множитель займов finuslugi 20221001'                   and  [Множитель займов finuslugi 20221001]                             .ОтчетнаяДата=a.МесяцЗайма and a.UF_SOURCE  in ('finuslugi')







left join #Первые100заявокablead Первые100заявокablead on Первые100заявокablead.UF_ROW_ID=a.UF_ROW_ID

						)
						


select id                                          
,      [Канал от источника]                        
,      UF_SOURCE                                   
,      UF_TYPE                                     
,      UF_ROW_ID                                   
,      isInstallment                                   
,      ПолнаяЗаявка                                
,      ЗаявкаAPI                                   
,      ЗаявкаAPI_или_API2                          
,      ЗаявкаAPI2         
,      ЛидAPI_или_API2
,      Лид_Дубль
,      ДеньЛида                                    
,      МесяцЛида                                   
,      ДеньЗаявки                                  
,      МесяцЗаявки                                 
,      ДеньЗайма                                   
,      МесяцЗайма                                  
,      СуммаЗайма                                  
,      Регион                                      
,      json_cost_params                            
,      cast(JSON_VALUE( json_cost_params, '$.cost') as float)         Стоимость
,      JSON_VALUE( json_cost_params, '$.for')                         ЗаЧтоПлатим
,      cast(JSON_VALUE( json_cost_params, '$.month')  as date)                      МесяцОплаты
,      JSON_VALUE( json_cost_params, '$.since')                       ПериодСКоторогоПлатимПоДаннойМетодологии
,      JSON_VALUE( json_cost_params, '$.till')                        ПериодДоКоторогоПлатимПоДаннойМетодологии
,      JSON_VALUE( json_cost_params, '$.condition')                   УсловияОплаты
,      JSON_VALUE( json_cost_params, '$.extra')                       ДопИнформация
,      getdate()                                    as                created
,      case when cast(JSON_VALUE( json_cost_params, '$.cost') as float) is not null then 1 else 0 end as ПодлежитОплате
,      UF_PARTNER_ID
	into #stg_table_result
from v
--where cast(JSON_VALUE( json_cost_params, '$.cost') as float) is not null

;
with v as (select * , ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn from #stg_table_result ) delete from v where rn>1 and UF_ROW_ID is not null


--select id, UF_ROW_ID, ДеньЛида, ДеньЗаявки, uf_source, uf_type, Стоимость from #stg_table_result
--where cast(JSON_VALUE( json_cost_params, '$.cost') as float) is not null
--	   except 
--select id, UF_ROW_ID, ДеньЛида, ДеньЗаявки, uf_source, uf_type, Стоимость from Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
--	 order by 5
--

delete from Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
insert into Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
select * from #stg_table_result
where Стоимость is not  null	 -- and ЗаЧтоПлатим='Клик'
or UF_ROW_ID is not null -- and uf_type not in ('', 'api')	  --and ЗаЧтоПлатим='Клик'
--6187
--create nonclustered index t on Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
--(
--МесяцОплаты, Стоимость, uf_row_id
--)

--select * from #stg_table_result
--where UF_SOURCE like  '%bankiru%'
--order by id

exec analytics.dbo.log_email 'Стоимость CPA опер finished', 'p.ilin@techmoney.ru'
--
--select * from analytics.dbo.dm_report_lcrm_cpa_cpc_costs
--where --UF_SOURCE <>'' and 
--Стоимость is not null and UF_ROW_ID is null
--order by UF_SOURCE --desc
--
--
	 --exec [Распределение расходов CPA]
	 --exec [Подготовка отчета стоимость займа]
end

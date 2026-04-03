
create   proc [dbo].[Подготовка отчета стоимость CPA опер 12.10.2022]
as
begin

drop table if exists #z


select Номер, Инстолмент, Дата into #z from  stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС 

drop table if exists #fa
select  Номер, [Заем выдан], [Выданная сумма], isInstallment, case when Партнер='Партнер № 3645 Рефинансирование '  then 1 else 0 end as [ПризнакРефинансирование]  , [Канал от источника] into #fa 
from reports.dbo.dm_Factor_Analysis_001

--select top 0 *, getdate() created into dbo.[стоимость займа #fa логирование] from #fa delete from dbo.[стоимость займа #fa логирование]
insert into dbo.[стоимость займа #fa логирование]

select *, getdate() created  from #fa

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] numeric(10,0),
	[UF_REGISTERED_AT] [datetime2] NULL,
	[UF_ACTUALIZE_AT] [datetime2] NULL,
	[UF_SOURCE] [VARCHAR](128),
	[UF_ROW_ID] [VARCHAR](128),
	UF_CLB_TYPE [VARCHAR](128),
	UF_PARTNER_ID [VARCHAR](128),
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
)

-- 
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

--exec select_table 'analytics.dbo.[стоимость займа #TMP_leads логирование]'


insert into #TMP_leads

select      
    [ID]   
,   [UF_REGISTERED_AT]   
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

from     stg._LCRM.lcrm_leads_full_channel_request
where [UF_ACTUALIZE_AT]>=getdate()-90
;

with v as (select * , ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn from #TMP_leads ) delete from v where rn>1 and UF_ROW_ID is not null












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

drop table if exists analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs ;

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
	into analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
from ft with(nolock)
--join devdb.dbo.dm_report_lcrm_cpa_cpc_with_potential_payment l          on l.id=ft.id
--left join devdb.dbo.dm_report_lcrm_cpa_cpc_with_potential_payment_full_form ff          on ff.id=ft.id
--left join #st st          on st.id=ft.id
where  (( [Канал от источника]='CPA нецелевой' and UF_ROW_ID is not null) or ([Канал от источника] in ('CPA целевой', 'CPA полуцелевой') ))  


;
with v as (select *, ROW_NUMBER() over(partition by id order by (select 1 )) rn from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs) delete from v where rn>1

drop table if exists #Справочник_лсрм

select
'Средний чек у creditors24 / creditors24_msk / creditors24_parkov_apart' Тип, МесяцЗайма ОтчетнаяДата , avg(СуммаЗайма) Метрика
into #Справочник_лсрм
from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('creditors24', 'creditors24_msk', 'creditors24_parkov_apart') and МесяцЗайма is not null
group by МесяцЗайма
union all
select
'Количество заявок у kokoc' Тип, МесяцЗаявки ОтчетнаяДата , count(*) Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('creditors24', 'creditors24_msk', 'creditors24_parkov_apart') and МесяцЗаявки is not null
group by МесяцЗаявки
union all
select
'Конверсия лид - займ у justlombard' Тип, МесяцЛида ОтчетнаяДата , count(ДеньЗайма)/cast(COUNT(*) as float) Метрика

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
where UF_SOURCE = 'leadgid2'  and МесяцЗаявки is not null
group by МесяцЗаявки
union all
select
'Конверсия лид - заявка у leadgid2' Тип, МесяцЛида ОтчетнаяДата , count(ДеньЗаявки)/cast(COUNT(*) as float)  Метрика

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
where UF_SOURCE ='avtolombard-credit'  and МесяцЗайма is not null 
group by МесяцЗайма



union all
select

'Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru' Тип, МесяцЗайма ОтчетнаяДата , sum(СуммаЗайма)  Метрика

from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE in ('avtolombard24ru', 'avtolombardsru', 'alfalombardru', 'alfalombardru', 'andrey', 'centerzalogru', 'avtolombardzalogru')  and МесяцЗайма is not null 
group by МесяцЗайма


--Первые 100 заявок ablead
drop table if exists #Первые100заявокablead
select top 100  UF_ROW_ID, case when count(*) over(partition by UF_SOURCE) >=100 then 1 else 0 end as ПодлежатОплате , format(max(МесяцЗаявки) over(partition by UF_SOURCE), 'yyyy-MM-dd') МесяцОплаты into #Первые100заявокablead
from analytics.dbo.dm_report_lcrm_cpa_cpc_for_costs
where UF_SOURCE='ablead' and UF_ROW_ID is not null
order by UF_ROW_ID desc


--select * from  Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
--where id=324115851


drop table if exists Analytics.dbo.dm_report_lcrm_cpa_cpc_costs

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
when UF_SOURCE = 'creditors24'  then
										case when  ДеньЗайма>='20220301' and isInstallment=0 then

																			case when Регион = 'Москва'                      then '{"cost":"'+format(25000 ,'0.00'          )+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Москва'+'"}'   
																			     when UF_SOURCE = 'creditors24_parkov_apart' then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Недвижимость'+'"}'   
																			                                                 else '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не москва'+'"}'   end

										end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE = 'creditors24_msk'  then
										case when  ДеньЗайма>='20220301' and isInstallment=0 then

																			case when Регион = 'Москва'                      then '{"cost":"'+format(25000 ,'0.00'          )+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Москва'+'"}'   
																			     when UF_SOURCE = 'creditors24_parkov_apart' then '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Недвижимость'+'"}'   
																			                                                 else '{"cost":"'+format(СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201005'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'Не москва'+'"}'   end

										     
										end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------												  
when UF_SOURCE = 'creditors24_parkov_apart'  then
															case when  ДеньЗайма>='20220301' and isInstallment=0  then

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
										   case when  ДеньЗаявки >= '20220301' and isInstallment=0  then 
																					
																					case 
																						when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
																						                          else '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}' 
																												  end
											    																																
												when  ДеньЗайма >= '20220301' and isInstallment=1  then 
																					
																					                    '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20201101'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'inst'+       '"}' 
																						               
											    																																
																																																
																					
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
when UF_SOURCE in ('bankiros','bankiros_ru','bankiros_ru_2','mainfin_ru', 'cityads', 'liknot' ) then 
											case when ДеньЗаявки>='20220301' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE in ('mastertarget' ) then 
											case 
											
											when ДеньЗаявки>='20220901' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма>='20220901' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'по API за займ Инстолмент '+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											
											
											
											
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
when UF_SOURCE in ('Refflection-api' ) then 
											case when ДеньЗаявки>='20220420' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
																						 end

							
											  
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
when UF_SOURCE='vbr' then 
											case when ДеньЗаявки>='20220601'  and isInstallment=0 then
															                        case  when ЗаявкаAPI_или_API2=0  then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'UF_STEP=3 не по api и не по api2'+'"}'
																						 end
											when ДеньЗаявки>='20220301'  and isInstallment=0 then
															                        case  when ЗаявкаAPI_или_API2=0 and UF_STEP=3 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+'Изменения действуют с 01.04.2020г:  1.  по API - 300 руб. за Заявку. 2.  по Реферальной ссылке - 700 руб. за Заявку.'+'", "extra":"'+'UF_STEP=3 не по api и не по api2'+'"}'
																						 end
											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																				
when UF_SOURCE='leadssu' then 
                           case when ДеньЗаявки>='20220301' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																				
when UF_SOURCE='leadssu-installment-ref' then 
                           case 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            
											 when ДеньЗайма>='20220301' and isInstallment=0  then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
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
											case when ДеньЗайма>='20220301' then
															                        '{"cost":"'+format(СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

											 
											end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																															
when UF_SOURCE='finya-ref' then 
											case when ДеньЗайма>='20220801' then
															                        '{"cost":"'+format(СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'Займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200110'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  	

											 
											end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																															
when UF_SOURCE='zaym-me' then 
											case when ДеньЗайма>='20220301' then
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
											case when ДеньЗайма>='20220301' then 
											
											
											'{"cost":"'+format( СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20190301'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 01.03.2019г:             3% от суммы выданных займов  '+'", "extra":"'+'3%'+'"}' 
															                       

											   
											end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																																											
when UF_SOURCE in ('bankiru', 'bankiru_25', 'bankiru-ref') then 
											case 
								                 when ДеньЗаявки >='20220301' and ЗаявкаAPI_или_API2=0 and isInstallment=0
																						then case 
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика<=50                    then '{"cost":"'+ format(450 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 51 and 100     then '{"cost":"'+ format(550 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика between 101 and 150    then '{"cost":"'+ format(650 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																						         when  [Заявок по реф ссылке у bankiru / bankiru_25/ bankiru-ref].Метрика >=151                  then '{"cost":"'+ format(800 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210101'+'", "till":"'+'20211231'+'", "condition":"' +''+'", "extra":"'+''+'"}'
																								  end

													when ДеньЛида  >='20220301' and ЛидAPI_или_API2=1 and Лид_Дубль=0
																															then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'лид'+'", "month":"'+МесяцЛидаТекст+'", "since":"'+'20201201'+'", "till":"'+'20211231'+'", "condition":"'+''+'", "extra":"'+'ЛидAPI_или_API2=1  and Лид_Дубль=0'+'"}'  
											 
											   
											end		
										
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																																											
when UF_SOURCE in ('bankiru-installment', 'bankiru-installment-ref') then 
											case 

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1200 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(3000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
											end	


											
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				
when UF_SOURCE='sravniru' then 
											case 
											     when ДеньЗаявки >='20220301' and ЗаявкаAPI_или_API2=0   and isInstallment=0           then
												 
												 
												 '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 
																	                            
															                       

											   
											end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE='avtolombard-credit' then 
											case when ДеньЗайма>='20220301' and isInstallment=0 then 
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
													case when ДеньЗаявки>='20220301' and ЗаявкаAPI_или_API2=1 
													
													then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20190531'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 31.05.2019г.: по API - 700 руб. за Заявку'+'", "extra":"'+' ЗаявкаAPI_или_API2=1  700р'+'"}'  
													
													end 
											

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
								
when UF_SOURCE in ('avtolombard24ru', 'avtolombardsru', 'alfalombardru', 'alfalombardru', 'andrey', 'centerzalogru', 'avtolombardzalogru' )
                                                then 
													case 
															when ДеньЗайма>='20220301' and isInstallment=0  then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20200710'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}' 

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
													case when ДеньЗаявки>='20220301' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'не по api и не по api2'+'"}'
																						 end

											             when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 

											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
when UF_SOURCE in ('guruleads-installment-ref') then 
											case 

											  when ДеньЗайма >='20220801' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма>='20220801'  and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма >='20220801' and isInstallment=0  and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
										    when ДеньЗайма >='20220801' and isInstallment=0 and  ЗаявкаAPI_или_API2=0   then
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
																	
when UF_SOURCE='autolombardzalogru_avtolombardzajmru'               then 
																			case 
																			
																			     when ДеньЗайма >= '20220301' and isInstallment=0 then 
																														case  when Регион in ('Москва', 'Санкт-Петербург') then '{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+''+'"}'  
																														                                                   else '{"cost":"'+format( СуммаЗайма*0.03 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+''+'", "condition":"'+''+'", "extra":"'+'' +'"}'  
																																										   end
																				
																				end
																														 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																		
when UF_SOURCE='zaimpodpts_ru'               then 
													case 
													
													when ДеньЗайма >='20220901'  --and isInstallment=0
													
													then 
													
															'{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201110'+'", "till":"'+'now'+'", "condition":"'+' '+'", "extra":"'+'5%'+'"}'  
													
													when ДеньЗайма between '20220301' and '20220831' -- and isInstallment=0
													
													then 
													
															'{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201110'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 10.11.2020г: 5% от суммы выданных займов'+'", "extra":"'+'5%'+'"}'  
													
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
																																													
when UF_SOURCE='meta_ru'               then 
													case when ДеньЗайма >='20220301'  and isInstallment=0
													
													then 
													
																'{"cost":"'+format( СуммаЗайма*0.03,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+'20201109'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 09.11.2020г: 3% от суммы выданных займов'+'", "extra":"'+'3%'+'"}'   
													
													end		

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------											
													
when UF_SOURCE='ablead'               then 
													case 
													when ДеньЗаявки >='20220301' and Первые100заявокablead.UF_ROW_ID is not null and Первые100заявокablead.ПодлежатОплате=1
													then 
													
																'{"cost":"'+format( 300,'0.00')+'", "for":"'+'заявку'+'", "month":"'+Первые100заявокablead.МесяцОплаты+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'3%'+'"}'  
													
													when ДеньЗайма >='20220301' and Первые100заявокablead.UF_ROW_ID is null
													then 
													
																'{"cost":"'+format(  СуммаЗайма*0.03,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'3%'+'"}'  
													
														

													
													end	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																					
when UF_SOURCE in ('gidfinance', 'gidfinance-target')


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
when UF_SOURCE in ('gidfinance-installment', 'gidfinance-installment-ref') then 
											case 

											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                            

											  
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
														
when UF_SOURCE in ('credeo' , 'credeo-ref')               then 
													case 
													
													
													when ДеньЗайма >='20220501'  and isInstallment=0
													
													then 
													
															'{"cost":"'+format( СуммаЗайма*0.08 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'8%'+'"}'  
													
													
													when ДеньЗайма >='20220301'  and isInstallment=0
													
													then 
													
															'{"cost":"'+format( СуммаЗайма*0.05 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+месяцзайматекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'5%'+'"}'  
													
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																			
when UF_SOURCE='admitad'               then 
													case when ДеньЗаявки >='20220301' and isInstallment=0 then 
													
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
													case when ДеньЗаявки  between '20220301' and '20220331' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 1200,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													when ДеньЗаявки  > '20220401' and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
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
													
													when ДеньЗаявки  >= '20220801'   and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													
													
													
													
													--when ДеньЗайма  between '20220801' and '20220831'  and isInstallment=0 then 
													--
													--											case when ЗаявкаAPI_или_API2=0 then
													--
													--											'{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
													--											end	
													--												
													when ДеньЗаявки  between '20220301' and '20220731'  and isInstallment=0 then 
													
																								case when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
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
													case when ДеньЗаявки>='20220301' and isInstallment=0 then
															                        case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format(300 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 
															                             when ЗаявкаAPI_или_API2=0 then '{"cost":"'+format(700 ,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
																						 end

											             when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+       '"}' 

											end	


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE in ('unicom24-installment-ref') then 
											case 

											  when ДеньЗайма>='20220401' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма>='20220401' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма>='20220401' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

					
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=1 then
															                                       '{"cost":"'+format(1000 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
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

--&&&&&&&&

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='workie-ref'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
																								'{"cost":"'+format( 6000,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
when UF_SOURCE in ('workie-installment-ref') then 
											case 
											  when ДеньЗайма>='20220301' and isInstallment=1 and  ЗаявкаAPI_или_API2=0 then
															                                       '{"cost":"'+format(2500 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
											 when ДеньЗайма>='20220301' and isInstallment=0   then
															                                       '{"cost":"'+format(СуммаЗайма*0.07 ,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20200401'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+'по api или api2'+       '"}' 
															                            

											  
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
when UF_SOURCE='kreditrf'               then 
													case when ДеньЗайма >='20220301' and isInstallment=0 then 
																								'{"cost":"'+format( СуммаЗайма*0.05,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='finardi-ref'               then 
													case when ДеньЗайма >='20220322'  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
when UF_SOURCE='AremiGroup'               then 
													case when ДеньЗайма >='20220314'  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='ptsoff-leads'               then 
													case when ДеньЗайма >='20220301'  then 
																								'{"cost":"'+format( СуммаЗайма*0.09,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='garantmoneyapi'               then 
													case when ДеньЗайма >='20220301'  then 
																								'{"cost":"'+format( СуммаЗайма*0.09,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='crditpts'               then 
													case when ДеньЗайма >='20220525'  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

when UF_SOURCE='zayman-ref'               then 
													case when ДеньЗайма >='20220420'  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE in ('creditpts-api', 'creditpts')
                                                   then 
													case when ДеньЗайма >='20220527'  then 
																								'{"cost":"'+format( СуммаЗайма*0.08,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE='metaru'               then 
													case when ДеньЗайма >='20220301'  then 
																								'{"cost":"'+format( СуммаЗайма*0.03,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE='likemoney'               then 
													case when ДеньЗаявки >='20220901'
													
																	then 
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+''+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end



														when ДеньЗайма between '20220527' and '20220831'
													
																	then 
																								'{"cost":"'+format( СуммаЗайма*0.1,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'   
																															   
													end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	


when UF_SOURCE in ('vzaimno-api', 'vzaimno-ref')               then 
													case when ДеньЗайма >='20220301'  then 
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
													 
													 
													 when ДеньЗайма >='20220701' and isInstallment=0 and ЗаявкаAPI_или_API2=1 then 
													
																								case when ЗаявкаAPI_или_API2=1 then '{"cost":"'+format( СуммаЗайма*0.07,'0.00')+'", "for":"'+'займ'+'", "month":"'+МесяцЗаймаТекст+'", "since":"'+'now'+'", "till":"'+'now'+'", "condition":"'+''+'", "extra":"'+''+'"}'
--																								                               else '{"cost":"'+format( 700,'0.00')+'", "for":"'+'заявку'+'", "month":"'+МесяцЗаявкиТекст+'", "since":"'+'20210319'+'", "till":"'+'now'+'", "condition":"'+'Условия действуют с 19.03.2021 г.: по API - 300 руб. за Заявку по Реферальной ссылке - 700 руб. за Заявку'+'", "extra":"'+'ЗаявкаAPI_или_API2=0'+'"}'   
																															   end
													  
													 when ДеньЗаявки >='20220701' and isInstallment=0 and ЗаявкаAPI_или_API2=0 then 
													
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
																										  
left join #Справочник_лсрм as [Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru]  on [Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru].Тип='Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru' and 
																										  [Выданная сумма у avtolombard24ru / avtolombardsru / alfalombardru / andrey / centerzalogru / avtolombardzalogru].ОтчетнаяДата=a.МесяцЗайма and
																										  a.UF_SOURCE  in ('avtolombard24ru', 'avtolombardsru', 'alfalombardru', 'alfalombardru', 'andrey', 'centerzalogru', 'avtolombardzalogru')
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
	into Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
from v
where cast(JSON_VALUE( json_cost_params, '$.cost') as float) is not null

;
with v as (select * , ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn from Analytics.dbo.dm_report_lcrm_cpa_cpc_costs ) delete from v where rn>1 and UF_ROW_ID is not null



create nonclustered index t on Analytics.dbo.dm_report_lcrm_cpa_cpc_costs
(
МесяцОплаты, Стоимость, uf_row_id
)

--
--select * from analytics.dbo.dm_report_lcrm_cpa_cpc_costs
--where --UF_SOURCE <>'' and 
--Стоимость is not null and UF_ROW_ID is null
--order by UF_SOURCE --desc
--
--

end


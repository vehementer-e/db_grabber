
  /*
  update 	 product_report_debug_mode set is_debug = 1
 update 	 product_report_debug_mode set is_debug = 0  
 */--


CREATE     proc  [dbo].[_product_report] @mode nvarchar(max) = 'select' , @recreate int =0
as
  
if @mode  = 'prep' 
begin

exec _product_report_retention_creation
exec _product_report_prolongation_creation
exec _product_report_balance_creation 
end



if @mode  = 'request_external' and (select is_debug from product_report_debug_mode)=1 select top 0   * from  v_request_external2  
if @mode  = 'request_external' and (select is_debug from product_report_debug_mode)=0 select  top 0   *        from  v_request_external2 


if @mode  = 'request' and (select is_debug from product_report_debug_mode)=1 select    *  from  lead_request_bi with(nolock)  where  created>=getdate()-60
if @mode  = 'request' and (select is_debug from product_report_debug_mode)=0 select   * from  lead_request_bi  where created>=   cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, getdate()-730), 0) as date)


--if @mode  = 'request2' and (select is_debug from product_report_debug_mode)=1 select    *  from  lead_request_bi2 with(nolock)  where  created>='20250730'
--if @mode  = 'request2' and (select is_debug from product_report_debug_mode)=0 select   * from  lead_request_bi2  where created>='20230101'


if @mode  = 'plan' and (select is_debug from product_report_debug_mode)=1 select top 0   *  from  sale_plan_budget_view  
if @mode  = 'plan' and (select is_debug from product_report_debug_mode)=0 select  * from  sale_plan_budget_view  --where case when is_Pts=0 and format(date, 'yyyyMM')='202503' then 1 else 0 end <>1


if @mode  = 'plan2' and (select is_debug from product_report_debug_mode)=1 select top 0   *  from  [sale_plan_budget_oper_view]  
if @mode  = 'plan2' and (select is_debug from product_report_debug_mode)=0 select  * from  [sale_plan_budget_oper_view]  --where case when is_Pts=0 and format(date, 'yyyyMM')='202503' then 1 else 0 end <>1



if @mode  = 'balance20' and (select is_debug from product_report_debug_mode)=1 select top 0   *  from product_report_balance_bi
if @mode  = 'balance20' and (select is_debug from product_report_debug_mode)=0 select    * from  product_report_balance_bi
if @mode  = 'balance_for_plan_fact' and (select is_debug from product_report_debug_mode)=1 select   top 0    date, returntype, productType, sum(percentsPaid) percentsPaid  from  product_report_balance where percentsPaid <> 0  group by  date, returntype, productType
if @mode  = 'balance_for_plan_fact' and (select is_debug from product_report_debug_mode)=0 select  date, returntype, productType, sum(percentsPaid) percentsPaid  from  product_report_balance where percentsPaid <> 0  group by  date, returntype, productType

if @mode  = 'prolongation' and (select is_debug from product_report_debug_mode)=1 select top 0 
           a.[week] ,   a.[date] ,   a.[prolongation_number] ,   a.[dpd_begin_day] ,   a.[Проценты уплачено] , /* a.[number] ,   */a.[issued] ,   a.[closed] ,   a.[is_dpd_begin_day] ,   a.[prolongation_percents] ,   a.[Прошло дней с выдачи] ,   a.[has_prolo] ,   a.[Дата пятой пролонгации] ,   a.[chisl] ,   a.[znamen] ,   a.[freeTermDays] ,   a.[firstLoanProductType] ,   a.[returnType] , a.loyalty
 , a.loyaltyBezzalog FROM Analytics.dbo.product_report_prolongation a 
if @mode  = 'prolongation' and (select is_debug from product_report_debug_mode)=0 SELECT 
           a.[week] ,   a.[date] ,   a.[prolongation_number] ,   a.[dpd_begin_day] ,   a.[Проценты уплачено] ,  /* a.[number] ,   */  a.[issued] ,   a.[closed] ,   a.[is_dpd_begin_day] ,   a.[prolongation_percents] ,   a.[Прошло дней с выдачи] ,   a.[has_prolo] ,   a.[Дата пятой пролонгации] ,   a.[chisl] ,   a.[znamen] ,   a.[freeTermDays] ,   a.[firstLoanProductType] ,   a.[returnType] ,  a.loyalty
 , a.loyaltyBezzalog FROM Analytics.dbo.product_report_prolongation a 


if @mode  = 'loan_overdue' and (select is_debug from product_report_debug_mode)=1 select top 0 number, statusContract,	[fpd10],[fpd0],	[fpd4], 	[fpd7],	[fpd30],	[fpd15]   from v_loan_overdue
if @mode  = 'loan_overdue' and (select is_debug from product_report_debug_mode)=0 select  top 0      number, statusContract,	[fpd10], [fpd0],	[fpd4], 	[fpd7],	[fpd30],	[fpd15]   from v_loan_overdue


if @mode  = 'closed' and (select is_debug from product_report_debug_mode)=1   SELECT top 0 
 a.[action] ,   a.[type] ,   a.[type2] ,   a.[date_type] ,   a.[product] ,   a.[closed] 
 ,   a.[ispts] ,   a.[request_0_d] ,   a.[request_5_d] ,   a.[request_14_d] ,   a.[request_30_d] 
 ,   a.[request_90_d] ,   a.[request_180_d] ,   a.[request_12_m] ,   a.[request_18_m] ,   a.[request_24_m] 
 ,   a.[free_term_days] ,   a.[Вид займа любой продукт] ,   a.[closed_dpd_begin_day] ,   a.[product_type]
 ,   a.[loyalty_pts] ,   a.[loyalty_nopts] ,   a.[Тип первого займа] ,   a.[isClosed] ,a. totalPay ,a.scheduleTotalPay , a.channel, a.source  FROM Analytics.dbo.[product_report_retention] a

if @mode  = 'closed' and (select is_debug from product_report_debug_mode)=0   SELECT 
           a.[action] ,   a.[type] ,   a.[type2] ,   a.[date_type] ,   a.[product] ,   a.[closed] 
		   ,   a.[ispts] ,   a.[request_0_d] ,   a.[request_5_d] ,   a.[request_14_d] ,   a.[request_30_d] 
		   ,   a.[request_90_d] ,   a.[request_180_d] ,   a.[request_12_m] ,   a.[request_18_m] ,   a.[request_24_m] 
		   ,   a.[free_term_days] ,   a.[Вид займа любой продукт] ,   a.[closed_dpd_begin_day] ,   a.[product_type] 
 ,   a.[loyalty_pts] ,   a.[loyalty_nopts] ,   a.[Тип первого займа] ,   a.[isClosed] ,a. totalPay ,a.scheduleTotalPay, a.channel, a.source  FROM Analytics.dbo.[product_report_retention] a




if @mode  = 'prod/dev' select case when  is_debug = 1 then N'💤 💤 💤 ОТЧЕТ В РЕЖИМЕ ОБНОВЛЕНИЯ 💤 💤 💤
Попробуйте обновить в ->'+format(dateadd(minute,  15 , getdate()) , 'HH:mm') else '' end is_debug from product_report_debug_mode
 
 
--if @mode  = 'balance' and (select is_debug from product_report_debug_mode)=1 select top 0 newid() row_id , *  from  _birs.[product_report_balance_percents]
--if @mode  = 'balance' and (select is_debug from product_report_debug_mode)=0 select newid() row_id,* from  _birs.[product_report_balance_percents]
--if @mode  = 'balance' and (select is_debug from product_report_debug_mode)=1 select top 0 newid() row_id , *  from productReportBalance
--if @mode  = 'balance' and (select is_debug from product_report_debug_mode)=0 select newid() row_id,* from  productReportBalance
 /*
 if @mode  = 'update'  
begin

if 1=1

begin
drop table if exists #help_id

SELECT id
	,ДатаЛидаЛСРМ
	,UF_TYPE
	,UF_PHONE
	,UF_LOGINOM_STATUS
	,ВремяПервойПопытки
	,UF_REGISTERED_AT
	,ВремяПервогоДозвона
	into  #help_id
FROM _birs.[product_report_lead_request]
WHERE UF_TYPE <> 'api'
	AND ДатаЛидаЛСРМ >= '20230511'
	and 1=0
	--and [product_report_lead_request]

drop table if exists  #lk_help_lead
SELECT 
     a.id	id_lk
    ,a.created_at
	,x.id lcrm_id
	,x.uf_type
	into #lk_help_lead
FROM _birs.[product_report_request] a
cross APPLY (
	SELECT TOP 1 *
	FROM #help_id b
	WHERE b.UF_PHONE = a.client_mobile_phone
		AND a.created_at_date = b.ДатаЛидаЛСРМ
		AND a.created_at  < b.UF_REGISTERED_AT
		and isnull(try_cast(a.lcrm_id as numeric), 0)<>try_cast(b.id		as numeric)
		order by   UF_REGISTERED_AT
	) x
	where 1=0

drop table if exists  #lk_help_lead2
SELECT 
     a.id	id_lk
   	,x.id lcrm_id
	,x.uf_type
	,x.ВремяПервойПопытки
	,x.ВремяПервогоДозвона
	into #lk_help_lead2
FROM _birs.[product_report_request] a
cross APPLY (
	SELECT TOP 1 *
	FROM #help_id b
	WHERE b.UF_PHONE = a.client_mobile_phone
		AND  b.ДатаЛидаЛСРМ between a.created_at_date and dateadd(day, 1,  a.created_at_date  )
		AND a.created_at  < b.UF_REGISTERED_AT
		and isnull(try_cast(a.lcrm_id as numeric), 0)<>try_cast(b.id		as numeric)
		order by   ВремяПервогоДозвона desc ) x
	where 1=0

  drop table if exists #calls_inst 
  select attempt_start, project_id, client_number, attempt_start_login  into #calls_inst 
from _birs.installment_calls_on_abandoned_requests_and_drafts
where 1=0
  
drop table if exists  #lk_help_lead3
SELECT 
     a.id	                id_lk
	,x.attempt_start        attempt_start
	,x.attempt_start_login  attempt_start_login
	into #lk_help_lead3
FROM _birs.[product_report_request] a
cross APPLY (
	SELECT TOP 1 *
	FROM #calls_inst b
	WHERE b.client_number = '8'+a.client_mobile_phone
		AND  cast(b.attempt_start as date) between a.created_at_date and dateadd(day, 1,  a.created_at_date  )
		AND a.created_at  < b.attempt_start
						  order by attempt_start_login desc
	) x
	where 1=0
	drop table if exists #green
select distinct cdate
, phone 
into #green 
from dwh2.[marketing].[povt_inst]
where  	market_proposal_category_code = 'green' 
union 
select distinct cdate
, phone 	 
from dwh2.[marketing].[povt_pdl]
where  	market_proposal_category_code = 'green' 

end



drop table if exists #voronka_inst

select 
  День = isnull(  b.created_at_date,  a.ДатаЛидаЛСРМ) 
, NEWID() row_id
, HASHBYTES('SHA2_256',   a.id+'|'+isnull(cast(a.request_id as nvarchar(20)), 'null') )   lead_request_hash

, [Как создан] = 
					case 
					when a.ДатаЛидаЛСРМ  is null then 'REF' 
					when a.uf_type in ('trigger_T25', 'trigger_T8', 'loginom')  then  'triggers'
					when a.uf_type like 'api%'   then  'api'
					when a.uf_type like 'uni_api%'   then  'REF'
					when a.uf_type  in ('loginom', 'import')   then a.uf_type  
					when a.uf_type  = ('market_proposal')   then	'docr&povt' 
					else 'REF' end 
, is_pts = isnull(a.is_pts, b.ispts)
, is_inst_lead                  = isnull( a.is_inst_lead, 1) 
, uf_source                     = case when  a.ДатаЛидаЛСРМ is null then 'Без привязки к лиду' else  a.uf_source end   
, entrypoint                       = case when  a.entrypoint is null and b.created_at>='20240425' then 'Без привязки к LF'	else  a.entrypoint end 
, ПричинаНепрофильности                       = a.ПричинаНепрофильности
, uf_type                       = case when  a.uf_type is null then 'Без привязки к лиду' else  a.uf_type end   
, [UF_PARTNER_ID аналитический] = a.[UF_PARTNER_ID аналитический] 
, UF_STAT_AD_TYPE               = a.UF_STAT_AD_TYPE 
, Телефон                       = cast( isnull(b.[client_mobile_phone] , a.UF_PHONE)	  as nvarchar(10)) 
, id_lead_request               = a.id 	  
, uf_registered_at              = a.uf_registered_at 
, isnull(a.uf_registered_at , b.created_at )	ДеньВремя
, isnull( b.created_at , a.uf_registered_at   )	ДеньВремяЗаявки

, is_accepted                   = a.is_accepted 	  
, a.[Группа каналов]
, a.[Канал от источника]




 ,[Лидов]            = case when b.id is not null then 1 else [Лидов] end             
 ,[Лидов accepted]   = case when b.id is not null then 1 else [Лидов accepted] end    
 ,[Лидов с попыткой] = case when b.id is not null then 1 else [Лидов с попыткой] end  
 ,[Лидов с дозвоном] = case when b.id is not null then 1 else [Лидов с дозвоном] end  
 ,[Лидов профильных] = case when b.id is not null then 1 else [Лидов профильных] end  

 ,     b.id
 ,     b.number
 ,     b.[Выдача денег]
 ,     b.current_status
 ,     b.created_at
 ,     b.[Вид займа]
 ,     b.[Вид займа любой продукт]
 ,     b.[Дубль_8_дней факторный анализ]
 ,     b.Дубль


 , [Тип лида после заявки]=	 c.UF_TYPE            
 , [Время попытки после заявки]	= isnull(c.ВремяПервойПопытки,  c1.attempt_start)       
 , [Время дозвона после заявки]	= isnull(c.ВремяПервогоДозвона, c1.attempt_start_login) 
 ,a.has_pts_request
 ,a.has_bz_request
 ,[Наличие зеленого предложения] = case when pinst.cdate is not null    then 'Зеленый' when  isnull(b.[client_mobile_phone] , a.UF_PHONE)	 is not null then  'Красный' end	 
, isnull( b.browser         , a.browser        ) browser
, isnull( b.browserVersion  , a.browserVersion ) browserVersion
,  a.requestGuid requestGuid
into #voronka_inst
		 --select  top 1 *
from  _birs.[product_report_lead_request] a
full outer join --select  top 1 * from
_birs.[product_report_request] b on a.request_id = b.id and a.is_pts=b.ispts

left join #lk_help_lead2	 c on c.id_lk=b.id
left join #lk_help_lead3	  c1 on c1.id_lk=b.id


  left join #green	pinst on pinst.[cdate] =isnull(  b.created_at_date,  a.ДатаЛидаЛСРМ)  and pinst.phone= isnull(b.[client_mobile_phone] , a.UF_PHONE)	 
where isnull(  b.created_at_date,  a.ДатаЛидаЛСРМ) >= dateadd(day, -45,  '20230511' ) --and getdate()-1
--where isnull( a.ДатаЛидаЛСРМ, b.created_at_date)<getdate()-1

drop table if exists #loans
select [Заем выдан]  ,   [Заем погашен],    Телефон, Номер, isPts, isPdl into #loans 	  
from mv_dm_Factor_Analysis 
where [Заем выдан] is not null	

insert into 	 #loans
select [Дата выдачи], [Дата погашения], [Телефон договор CMR], [Номер заявки], 1- isInstallment  isPts	, 0 
from mv_loans 
where [Номер заявки] not in (select Номер from #loans)


--drop index t on #voronka_inst
create index t on #voronka_inst
(ДеньВремяЗаявки, телефон, is_pts, день, current_status, row_id, lead_request_hash)

select ДеньВремяЗаявки, телефон, is_pts, день, current_status, row_id, lead_request_hash into #for_dedublication_tbl from #voronka_inst
where Телефон <>''

select LcrmID, number, original_lead_id, marketing_lead_id , фио   , ПризнакТестоваяЗаявка 		 , Офис   into #tests
from v_request
where ПризнакТестоваяЗаявка=1	  or фио like '%тестовая%'	  or ПартнерCRM like '%Партнер №0200 Москва%'
order by 2 desc

select distinct original_lead_id into #tests2 from  #tests union 
select distinct marketing_lead_id from  #tests union 
select distinct cast(lcrmID as nvarchar(36)) from  #tests union 
select distinct number from  #tests  

drop table if exists #voronka_inst2 

  select a.*, 
  Дубль2 = case when 1=1 then null   else 0 end	
  ,Дубль20 = case 
  when a.[Выдача денег] is not null then 0
  when t.original_lead_id is not null then 1
  when t1.original_lead_id is not null then 1
  when  a.Телефон is not null and a.День is not null and  row_number() over(partition by a.is_pts,   a.День, a.Телефон order by a.current_status desc, [Лидов профильных] desc, [Лидов с дозвоном] desc,  [Лидов с попыткой] desc,  [Лидов accepted] desc,  a.uf_registered_at desc) <> 1 then 1  
  when a.[Как создан]='api' and  a.Телефон is  null and is_accepted=0 then 1
  else 0 end	
  , 	 case 
  when a.[Выдача денег] is not null then 0
  
  when t.original_lead_id is not null then 1
  when t1.original_lead_id is not null then 1

  when  a.Телефон is not null and  лучшая_или_равная_после.dubl8=1  then 1
  when  a.Телефон is not null and  лучшая_до.dubl8=1  then 1
  when  a.Телефон is not null and  ROW_NUMBER() over(partition by  ДеньВремяЗаявки, is_pts, Телефон order by  isnull( a.current_status,-1) desc, number desc)>1 	  then 1 
 when  a.Телефон is  null and 	is_accepted=0 then 1
  else 0 end [Дубль_8_дней]	    
  , 	 case when 1=1 then null  else 0 end [Дубль_30_дней]


    , 	 case 
  when [Дубль_8_дней факторный анализ] is not null then [Дубль_8_дней факторный анализ]
  when a.[Выдача денег] is not null then 0
  
  when t.original_lead_id is not null then 1
  when t1.original_lead_id is not null then 1

  when  a.Телефон is not null and  лучшая_до_любой_продукт.dubl8=1  then 1
  when  a.Телефон is not null and  лучшая_или_равная_после_любой_продукт.dubl8=1  then 1
  when  a.Телефон is not null and  ROW_NUMBER() over(partition by  ДеньВремяЗаявки, is_pts, Телефон order by  isnull( a.current_status,-1) desc, number desc)>1 	  then 1 
 when  a.Телефон is  null and 	is_accepted=0 then 1
  else 0 end [Дубль_8_дней любой продукт]	 

  , [Вид займа лид] =  ISNULL(a.[Вид займа],
  case 
  when  [docr_tel].cnt_docr>0  then 'Докредитование'
  when  [povt_tel].cnt_povt>0 then 'Повторный'
  when  Телефон is not null and a.uf_registered_at is not null then 'Первичный'
  else 'Первичный' end ) 
 ,previous_closed_dt = [povt_tel].previous_closed_dt
					
 , [Лояльность]        = isnull([povt_tel_any_product].cnt_povt,0)+1
 , [Тип первого займа] =  case when first_loan_any_product.isPdl =1  then 'pdl'  when first_loan_any_product.isPts =1  then 'pts ' when first_loan_any_product.isPdl =0 then 'inst' end    --case first_loan.isPdl when '1' then 'pdl' when '0' then 'inst' end
-- , [Тип первого займа любой продукт] = case when first_loan_any_product.isPdl =1  then 'pdl'  when first_loan_any_product.isPts =1  then 'pts ' when first_loan_any_product.isPdl =0 then 'inst' end   
 , [Вид займа лид любой продукт] =  ISNULL(a.[Вид займа любой продукт],
  case 
  when  [docr_tel_any_product].cnt_docr>0  then 'Докредитование'
  when  [povt_tel_any_product].cnt_povt>0 then 'Повторный'
  when  Телефон is not null and a.uf_registered_at is not null then 'Первичный'
  else 'Первичный' end ) 

   into #voronka_inst2
  from #voronka_inst	a
  outer apply (select count(*) cnt_povt, max([Заем погашен]) previous_closed_dt
  
  from #loans b where b.isPts=a.is_pts and   (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.uf_registered_at  	 )  [povt_tel]
  outer apply (select top 1 isPdl
  
  from #loans b where b.isPts=a.is_pts and   (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.uf_registered_at  order by b.[Заем выдан]	 )  first_loan
  outer apply (select count(*) cnt_docr

  
  from #loans b where b.isPts=a.is_pts and (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/  a.Телефон=b.Телефон) and b.[Заем выдан]<=a.uf_registered_at and isnull(b.[Заем погашен], GETDATE() ) > a.uf_registered_at  )    [docr_tel]	 
  


    outer apply (select count(*) cnt_povt, max([Заем погашен]) previous_closed_dt
  
  from #loans b where    (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.uf_registered_at  	 )  [povt_tel_any_product]
  outer apply (select top 1 isPdl, ispts
  
  from #loans b where    (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.uf_registered_at  order by b.[Заем выдан]	 )  first_loan_any_product
  outer apply (select count(*) cnt_docr

  
  from #loans b where  (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/  a.Телефон=b.Телефон) and b.[Заем выдан]<=a.uf_registered_at and isnull(b.[Заем погашен], GETDATE() ) > a.uf_registered_at  )    [docr_tel_any_product]	 


  outer apply (select top 1 1 dubl8 from #for_dedublication_tbl b where b.is_Pts=a.is_pts and    a.Телефон=b.Телефон and a.row_id<>b.row_id 
  and b.ДеньВремяЗаявки >= dateadd(day, -7, cast(a.ДеньВремяЗаявки as date))   
  and b.ДеньВремяЗаявки < a.ДеньВремяЗаявки 
  and isnull(a.current_status, -1)<isnull(b.current_status, -1) )   	лучшая_до	  
  outer apply (select top 1 1 dubl8 from #for_dedublication_tbl b where b.is_Pts=a.is_pts and    a.Телефон=b.Телефон and a.row_id<>b.row_id 
  and b.ДеньВремяЗаявки <= dateadd(day, 8, cast(a.ДеньВремяЗаявки as date) )   
  and b.ДеньВремяЗаявки > a.ДеньВремяЗаявки 
  and isnull(a.current_status, -1)<=isnull(b.current_status, -1) )   	лучшая_или_равная_после

  outer apply (select top 1 1 dubl8 from #for_dedublication_tbl b where     a.Телефон=b.Телефон and a.lead_request_hash<>b.lead_request_hash 
  and b.ДеньВремяЗаявки >= dateadd(day, -7, cast(a.ДеньВремяЗаявки as date))   
  and b.ДеньВремяЗаявки < a.ДеньВремяЗаявки 
  and isnull(a.current_status, -1)<isnull(b.current_status, -1) )   	лучшая_до_любой_продукт	  
  outer apply (select top 1 1 dubl8 from #for_dedublication_tbl b where  a.Телефон=b.Телефон and a.lead_request_hash<>b.lead_request_hash 
  and b.ДеньВремяЗаявки <= dateadd(day, 8, cast(a.ДеньВремяЗаявки as date) )   
  and b.ДеньВремяЗаявки > a.ДеньВремяЗаявки 
  and isnull(a.current_status, -1)<=isnull(b.current_status, -1) )   	лучшая_или_равная_после_любой_продукт


left join #tests2 t on t.original_lead_id=a.id_lead_request	
left join #tests2 t1 on t.original_lead_id=a.number	
  drop table if exists _birs.[product_report_conversions]
    select * into        _birs.[product_report_conversions] from #voronka_inst2					    
return



	if @recreate = 1
	begin
    drop table if exists _birs.[product_report_conversions]
    select * into        _birs.[product_report_conversions] from #voronka_inst2					    

	 
	end

	 else begin		 
truncate table _birs.[product_report_conversions]
insert into _birs.[product_report_conversions]
select * from #voronka_inst2		  
																							    

end  

return



end 
*/


--if (select * from product_report_debug_mode ) =-1

/*
if @mode = 'update2'
Begin


							    


drop table if exists #segment_0

select distinct   b.phone [Телефон договор CMR] into #segment_0 from client_segment_risk b


drop table if exists #stg_voronka

	;

select    a.[День] 
,   cast(format(a.[День], 'yyyy-MM-01') as date) month
,   a.[Как создан] 
,   a.[is_pts] 
,   a.[is_inst_lead] 
,   a.[uf_source] 
,   a.[uf_type] 
,   a.[UF_PARTNER_ID аналитический]   	  
,   a.[UF_STAT_AD_TYPE] 
, case when [Вид займа лид]='Повторный' then [Телефон] else '' end  [Телефон] 
, case when a.[id]  is not null or [Вид займа лид]='Повторный' or  a.entrypoint='UNI_API'  then id_lead_request  else '' end  [id_lead_request] 
, case when a.[id]  is not null or [Вид займа лид]='Повторный' or  a.entrypoint='UNI_API'  then a.[uf_registered_at] else  cast( a.[uf_registered_at] as date)  end [uf_registered_at] 
, case when a.[id]  is not null or [Вид займа лид]='Повторный' or  a.entrypoint='UNI_API'  then a.[ДеньВремя] else  cast( a.[ДеньВремя] as date)  end [ДеньВремя] 
, case when a.[id]  is not null or [Вид займа лид]='Повторный' or  a.entrypoint='UNI_API'   then a.[ДеньВремяЗаявки] else  cast( a.[ДеньВремяЗаявки] as date)  end [ДеньВремяЗаявки] 
,   a.[is_accepted] 
,   a.[Группа каналов] 
,   a.[Канал от источника] 
,   a.id [id]  
,   a.[Дубль]  																							 
,   a.[Дубль2] 
,   a.Дубль20 
,   a.[Дубль_8_дней] 
,   a.[Дубль_8_дней любой продукт] 

,   a.[Дубль_30_дней] 
,   a.[Вид займа лид] 
,   a.[Вид займа лид любой продукт] 
,   a.[Наличие зеленого предложения] 
,   ПричинаНепрофильности
,   a.[previous_closed_dt] 
,   a.entrypoint 

,  sum( a.[Лидов] 					)  [Лидов] 			
,  sum( a.[Лидов accepted] 			)  [Лидов accepted] 	
,  sum( a.[Лидов с попыткой] 		)  [Лидов с попыткой] 
,  sum( a.[Лидов с дозвоном] 		)  [Лидов с дозвоном] 
,  sum( a.[Лидов профильных] 		)  [Лидов профильных] 
,a.has_pts_request
,a.has_bz_request
, a.Лояльность
, a.[Тип первого займа]
 , case when b.[Телефон договор CMR] is not null then 'TOP_BZ' else '' end  	  segment
, a.browser
, a.browserVersion
, a.requestGuid

 into #stg_voronka22
 from _birs.product_report_conversions a
 left join #segment_0 b on a.Телефон =b.[Телефон договор CMR]

 --from #voronka_inst2 a

 group by   a.[День] 
,   cast(format(a.[День], 'yyyy-MM-01') as date)  
,   a.[Как создан] 
,   a.[is_pts] 
,   a.[is_inst_lead] 
,   a.[uf_source] 
,   a.[uf_type] 
,   a.[UF_PARTNER_ID аналитический]   	  
,   a.[UF_STAT_AD_TYPE] 
, case when [Вид займа лид]='Повторный' then [Телефон] else '' end    
, case when a.[id]  is not null or [Вид займа лид]='Повторный'  or  a.entrypoint='UNI_API'  then id_lead_request  else '' end    
, case when a.[id]  is not null or [Вид займа лид]='Повторный' or  a.entrypoint='UNI_API'  then a.[uf_registered_at] else  cast( a.[uf_registered_at] as date)  end   
, case when a.[id]  is not null or [Вид займа лид]='Повторный' or  a.entrypoint='UNI_API' then a.[ДеньВремя] else  cast( a.[ДеньВремя] as date)  end   
, case when a.[id]  is not null or [Вид займа лид]='Повторный' or  a.entrypoint='UNI_API' then a.[ДеньВремяЗаявки] else  cast( a.[ДеньВремяЗаявки] as date)  end   
,   a.[is_accepted] 
,   a.[Группа каналов] 
,   a.[Канал от источника] 
,   a.id   
,   a.[Дубль] 																							 
,   a.[Дубль2] 
,   a.Дубль20 
,   a.[Дубль_8_дней] 
,   a.[Дубль_8_дней любой продукт] 
 ,  a.[Дубль_30_дней] 
 
,   a.[Вид займа лид] 
,   a.[Вид займа лид любой продукт] 
,   a.[Наличие зеленого предложения] 
,   ПричинаНепрофильности
,   a.[previous_closed_dt] 
,   a.entrypoint 
,a.has_pts_request
,a.has_bz_request
, a.Лояльность
, a.[Тип первого займа]

  , case when b.[Телефон договор CMR] is not null then 'TOP_BZ' else '' end  	
  , a.browser
, a.browserVersion
, a.requestGuid



  
drop table if exists #prolongations
select  top 0 * into #prolongations from  _birs.product_report_prolongation_conversions 

select a.*, b.[Вид займа любой продукт] , b.[Вид займа], b.[Тип первого займа], Лояльность  into #prolongations2 from #prolongations a left join 
_birs.product_report_request b on a.number=b.number

--экранам 
--exec msdb.dbo.sp_start_job  @job_name= 'Analytics. !!Воронка по экранам!! $Daily at 07:00$', @step_name = 'exec [_birs].[product_report]    update2'

 
select top 0 * into #balance_percents from  _birs.[product_report_balance_percents] 
--select * into #balance_percents from  select * from _birs.[product_report_balance_percents] 
 



  
  ---------------------------
---------------------------
---------------------------
---------------------------
--------------------------- -second-
---------------------------
---------------------------
---------------------------
---------------------------
---------------------------
---------------------------
---------------------------
---------------------------
---------------------------
---------------------------

drop table if exists #stg_voronka223



select * into #stg_voronka223 from (
select День2 = isnull( isnull(  isnull( isnull( isnull(b.created    , a.День           )  , c.cdate)        , prolo.date)    , balance_percents.date)       , v_plan_budget_risk_xlsx.date)                          
,   a.[День] 

,Источник2 =  isnull(b.stat_source, a.uf_source      )                                         
,   a.[uf_source] 

, UF_STAT_AD_TYPE2 = isnull(b.stat_type  , a.UF_STAT_AD_TYPE)                                         
, case 
when v_plan_budget_risk_xlsx.date is not null then '$budget' 
when balance_percents.date is not null then '$balance_fact' 
when prolo.date is not null then '$prolo' when	b.created  is not null then 'REF'  when  [Как создан] is not null then [Как создан] when c.month is not null then 'green' end           [Как создан2]
, case 
when v_plan_budget_risk_xlsx.date is not null then v_plan_budget_risk_xlsx.[Вид займа любой продукт]
when balance_percents.date is not null then balance_percents.[Вид займа любой продукт]
when prolo.date is not null then prolo.[Вид займа]  when	b.created  is not null then 'Первичный' when [Вид займа лид] is not null then [Вид займа лид] when c.month is not null then 'Повторный'   end  [Вид займа лид2]
, case 
when  v_plan_budget_risk_xlsx.date is not null then 0
when  balance_percents.date is not null then 0

when  prolo.date is not null then 0
when	isnull(	isnull(b.created,  c.month)  , prolo.date)  is not null   then 0  else Дубль20 end                     Дубль3
, b.visits                                                                         visits
, b.unique_visits                                                                  unique_visits 
, a.[Как создан] 
, isnull(  a.[is_pts] , case when c.month is not null then 0 
when  v_plan_budget_risk_xlsx.date is not null then v_plan_budget_risk_xlsx.is_pts 
when prolo.date is not null then 0 
when balance_percents.ispts is not null then  balance_percents.ispts 
end) [is_pts]
,   a.[is_inst_lead] 
,   a.[uf_type] 
,   isnull( a.[UF_PARTNER_ID аналитический] ,  b.stat_info) 	 [UF_PARTNER_ID аналитический]
,   a.[UF_STAT_AD_TYPE] 
,   a.[id_lead_request] 
,   a.[uf_registered_at] 
,   a.[ДеньВремя] 
,   a.[ДеньВремяЗаявки] 
,   a.[is_accepted] 
,   a.[Группа каналов] 
,   a.[Канал от источника] 
,   a.[Лидов] 
,   a.[Лидов accepted] 
,   a.[Лидов с попыткой] 
,   a.[Лидов с дозвоном] 
,   a.[Лидов профильных] 
,   a.[id] 		 

,   a.[Дубль] 
,   a.[Дубль2] 
, case 
when   v_plan_budget_risk_xlsx.date is not null then 0 
when  balance_percents.date is not null then 0 
when prolo.date is not null then 0 when b.created is not null then 0  else   a.Дубль20  end Дубль20
,   a.[Дубль_8_дней] 
, case
when  v_plan_budget_risk_xlsx.date  is not null then 0
when  balance_percents.date is not null then 0
when prolo.date is not null then 0 when b.created is not null then 0 else   a.[Дубль_8_дней любой продукт]  end [Дубль_8_дней любой продукт]
,   a.[Дубль_30_дней] 

,  case 
when v_plan_budget_risk_xlsx.date is not null then v_plan_budget_risk_xlsx.[Вид займа любой продукт] 
when balance_percents.date is not null then balance_percents.[Вид займа любой продукт] 
when prolo.date is not null then prolo.[Вид займа] else  a.[Вид займа лид]  end [Вид займа лид]
,  case
when v_plan_budget_risk_xlsx.date is not null then v_plan_budget_risk_xlsx.[Вид займа любой продукт] 
when prolo.date is not null then prolo.[Вид займа любой продукт] 
when balance_percents.date is not null then balance_percents.[Вид займа любой продукт] else  a.[Вид займа лид любой продукт]  end [Вид займа лид любой продукт]
 
,  isnull( a.[Наличие зеленого предложения] , c.market_proposal_category_name)		 [Наличие зеленого предложения]
,  isnull(  a.[previous_closed_dt] 	  , c.last_closed)	  [previous_closed_dt] 	
,   isnull(datediff(day,    a.[previous_closed_dt] 	  ,  a.День  ) ,  datediff(day , c.last_closed,   c.cdate  ) )               days_since_previous_closed
,   a.entrypoint    entrypoint
,   a.ПричинаНепрофильности
, case when  a.[Вид займа лид]='Повторный' or  a.[Вид займа лид любой продукт]='Повторный' or  c.last_closed is not null  then 1 when c.month is not null then 1 end is_repeated_potential
, case when День is not null then 'r' else '' end+
+case when b.created  is not null then 'v' else '' end 
+case when c.cdate  is not null then 'c' else '' end   
+case when prolo.date is not null then '|prolo|' else '' end   
+case when balance_percents.date is not null then '|balance_fact|' else '' end   
+case when v_plan_budget_risk_xlsx.date is not null then '|budget|' else '' end   
row_type
,a.has_pts_request
,a.has_bz_request
, isnull(balance_percents.Лояльность,isnull(prolo.Лояльность,  a.Лояльность) ) Лояльность
, isnull(balance_percents.[Тип первого займа], isnull(prolo.[Тип первого займа],  a.[Тип первого займа]) ) [Тип первого займа]
, a.segment
, prolo.date [prolongation_date]
, prolo.[prolongation_percents] [prolongation_percents]
, prolo.[prolongation_number] prolongation_number
, prolo.dpd_begin_day prolongation_dpd_begin_day
, prolo.znamen is_prolongation_potential
,  case
when v_plan_budget_risk_xlsx.date is not null   then v_plan_budget_risk_xlsx.product_type
when balance_percents.date is not null   then balance_percents.product_type
when  prolo.date is not null  then 'PDL'    
end	[product_type]																				
,  balance_percents.dpd_begin_day_0_1_45 
,  balance_percents.is_legal 
,  balance_percents.paid 
,  balance_percents.percentsPaid 
,  balance_percents.issuedMonth issuedMonthBalance 
, cntRequest_budget =   v_plan_budget_risk_xlsx. cntRequest_budget  
, cntLoan_budgetc   =     v_plan_budget_risk_xlsx.    cntLoan_budget 
, sumLoan_budgetc   =      v_plan_budget_risk_xlsx.  sumLoan_budget
, a.browser browser
, a.browserVersion browserVersion
, a.requestGuid
 
from #stg_voronka22 a

full outer join _birs.visits_stat  b on 1=0
full outer join _birs.product_report_client_category   c  on c.month = a.month and a.Телефон=c.phone  and a.[Вид займа лид]='Повторный'	and rn_month=1 and c.cdate<=a.День
full outer join  #prolongations2  prolo on 1=0
full outer join  #balance_percents  balance_percents on 1=0
full outer join  v_plan_budget_risk_xlsx  v_plan_budget_risk_xlsx on 1=0

) x 

where День2  between '20230511' and GETDATE()
		
drop table if exists #stg_voronka33

 select        День2
,   a.[День] 

,           Источник2 
,   a.[uf_source] 

, UF_STAT_AD_TYPE2 
, [Как создан2]
, [Вид займа лид2]
,       Дубль3
, a.visits                                                                         visits
, a.unique_visits                                                                  unique_visits 
, a.[Как создан] 
,   [is_pts]
,   a.[is_inst_lead] 
,   a.[uf_type] 
,  	 [UF_PARTNER_ID аналитический]
,   a.[UF_STAT_AD_TYPE] 
,   a.[id_lead_request] 
,   a.[uf_registered_at] 
,   a.[ДеньВремя] 
,   a.[ДеньВремяЗаявки] 
,   a.[is_accepted] 
,   a.[Группа каналов] 
,   a.[Канал от источника] 
,   a.[Лидов] 
,   a.[Лидов accepted] 
,   a.[Лидов с попыткой] 
,   a.[Лидов с дозвоном] 
,   a.[Лидов профильных] 
,   a.[id] 		 

,   a.[Дубль] 
,   a.[Дубль2] 
,   a.Дубль20 
,   a.[Дубль_8_дней] 
,   a.[Дубль_8_дней любой продукт] 

  , a.[Дубль_30_дней] 
,   a.[Вид займа лид] 
,   a.[Вид займа лид любой продукт] 
,  [Наличие зеленого предложения]
,    [previous_closed_dt] 	
,            days_since_previous_closed
,       entrypoint
,   a.ПричинаНепрофильности
,   is_repeated_potential
,    row_type
,a.has_pts_request
,a.has_bz_request
--, a.Лояльность
--, a.[Тип первого займа]
  
 , case when DATEDIFF(DAY, b.[Выдача денег], b.[Заем погашен])<=7 then 1 else 0 end  [ПДП 7 дней]
, dateadd(day, datediff(day, '1900-01-01', День2) / 7 * 7, '1900-01-01')  Неделя
, cast(format(a.День2, 'yyyy-MM-01') as date) Месяц  
,   b.[created_at_date] 																				
,   b.[created_at]       																				
,   b.[Вид займа] 																						
,   b.[Кол-во закрытых займов в рамках продукта] 														
,   b.[Верификация кц] 																					
,   b.[Предварительное одобрение] 																		
,   b.[Контроль данных] 																				
,   b.[Одобрено] 																						
,   b.[Договор подписан] 																				
,   b.[Выдача денег] 																					
,   b.[Запрошенная сумма] 																				
,   b.[Выданная сумма] 																					
,   b.[Процентная ставка] 																				
,   b.[Срок займа] 																						
,   b.[Заем погашен] 																					
,   b.[Отказано] 																						
,   b.[Признак Отказано] 																				
,   b.[is_installment] 																					
,   b.[ispts] 																							
,   b.[prolongations_cnt] 																				
,  ISNULL(b.[product_type] , a.product_type ) [product_type]																				
,   b.[product_type_initial] 																			
,   b.[client_total_monthly_income] 																	
,   b.is_automatic_approve 																	
,   b.[Верификация документов клиента] 																					
,   b.[СтатусЗаявки] 																					
,   b.number 				number																			
,   b.[origin_name_1c] 																					
,   b.[client_mobile_phone] 																			
,   b.[client_mobile_phone_md5] 																		
,   b.[request_id_status] 																				
,   b.[created_at - Договор подписан] 																	
,   b.[Договор подписан - Выдача денег] 																
,   b.[created_at - Анкета] 																			
,   b.[Анкета] 																							
,   b.[Анкета - Паспорт] 																				
,   b.[Паспорт] 																						
,   b.[Паспорт - Фотографии] 																			
,   b.[Фотографии] 																						
,   b.[Фотографии - Подписание первого пакета] 															
,   b.[Подписание первого пакета] 																		
,   b.[Подписание первого пакета - О работе и доходе] 													
,   b.[Подписание первого пакета - ВКЦ] 																
,   b.[Подписание первого пакета - Предварительное одобрение] 											
,   b.[ВКЦ - Предварительное одобрение] 																
,   b.[Call 1] 																							
,   b.[О работе и доходе] 																				
,   b.[О работе и доходе - Добавление карты] 															
,   b.[Добавление карты] 																				
,   b.[Добавление карты - Одобрение] 																	
,   b.[Одобрение] 																						
,   b.[Одобрение - Выбор предложения] 																	
,   b.[Выбор предложения] 																				
,   b.[Выбор предложения - Подписание договора] 														
,   b.[Подписание договора] 																			
,   b.[Подписание договора - Выдача денег] 																
,   b.[Выдача] 																							
,   b.[lkk_or_mp] 																						
,   b.[is_repeated_lk] 																					
,   b.[has_fake_status] 																				
,   b.[current_status] 																					
,   b.[Переход на калькулятор ПТС] 																		
,   b.[Переход на калькулятор ПТС - Переход на Анкету ПТС] 												
,   b.[Переход на Анкету ПТС] 																			
,   b.[Переход на Анкету ПТС - Открытие слота 2-3 стр паспорта ПТС] 									
,   b.[Открытие слота 2-3 стр паспорта ПТС] 															
,   b.[Открытие слота 2-3 стр паспорта ПТС - Загрузка 2-3 стр паспорта ПТС] 							
,   b.[Загрузка 2-3 стр паспорта ПТС] 																	
,   b.[Загрузка 2-3 стр паспорта ПТС - Переход на 1 пакет ПТС] 											
,   b.[Переход на 1 пакет ПТС] 																			
,   b.[Переход на 1 пакет ПТС - Подписание 1 пакета ПТС] 												
,   b.[Подписание 1 пакета ПТС] 																		
,   b.[Подписание 1 пакета ПТС - Переход на экран Фото паспорта ПТС] 									
,   b.[Переход на экран Фото паспорта ПТС] 																
,   b.[Переход на экран Фото паспорта ПТС - Переход на экран с дополнительной информацией ПТС] 			
,   b.[Переход на экран с дополнительной информацией ПТС] 												
,   b.[Переход на экран с дополнительной информацией ПТС - Переход на экран с фото документов авто ПТС] 
,   b.[Переход на экран с фото документов авто ПТС] 													
,   b.[Переход на экран с фото документов авто ПТС - Переход на экран Способ выдачи ПТС] 				
,   b.[Переход на экран Способ выдачи ПТС] 																
,   b.[Переход на экран Способ выдачи ПТС - Карта привязана ПТС] 										
,   b.[Карта привязана ПТС] 													 
,   b.[Карта привязана ПТС - Переход на фото авто ПТС] 							 
,   b.[Переход на фото авто ПТС] 												 
,   b.[Переход на фото авто ПТС - Отправлена полная заявка ПТС] 				 
,   b.[Отправлена полная заявка ПТС] 											 
,   b.[Отправлена полная заявка ПТС - Финальное одобрение ПТС] 					 
,   b.[Финальное одобрение ПТС] 												 
,   b.[Финальное одобрение ПТС - Переход на второй пакет ПТС] 					 
,   b.[Переход на второй пакет ПТС] 											 
,   b.[Переход на второй пакет ПТС - Подписание второго пакета ПТС] 			 
,   b.[Подписание второго пакета ПТС] 											 
,   b.[Подписание второго пакета ПТС - Выдача денег] 							 
,   b.[Дубль_8_дней факторный анализ] 											 
,   b.[Признак Предварительное одобрение] 										 
,   b.[Признак застрял] 														 
,   b.[created] 																 
,   b.[Признак ручное доведение на TU] 											 
,   b.[Маркетинговые расходы] 													 
,   b.[Повторный займ] 															 
,   b.[Повторный займ сумма] 													 
,   b.[Повторный займ Маркетинговые расходы] 									 
,   b.[УПРИД_запрос] 															 
,   b.[УПРИД_Есть] 																 
,   b.[УПРИД_Нет] 																 
,   b.[next_request_product_dt] 												 
,   b.[Заявка 90 дней после закрытия] 											 
									 

,   isnull(a.entrypoint , origin_name_1c)  entrypoint2
,   b.final_step 	
, Isnull(b.[Лояльность]       	, a.[Лояльность]       	 )	  [Лояльность]       	
, Isnull(b.[Тип первого займа]	, a.[Тип первого займа]	 )	  [Тип первого займа]	

, a.segment
, a.[prolongation_date]
, a.[prolongation_percents]
, a.prolongation_number
, a.prolongation_dpd_begin_day
, a.is_prolongation_potential

, b.closed_date_plan   closed_date_plan                          
, b.term_days          term_days     
, b.free_term_days          free_term_days  
, a.dpd_begin_day_0_1_45
, a.is_legal
, a.paid
, a.percentsPaid
, a.issuedMonthBalance
, a.cntRequest_budget 
, a.cntLoan_budgetc   
, a.sumLoan_budgetc   
, b.closed_dpd_begin_day
, NEWID() row_id
, a.browser  browser
, a.browserVersion  browserVersion
, b.DpdDays
, isnull(a.requestGuid, b.guid) requestGuid


 	into #strhovochnaya
 from #stg_voronka223 a
 left join _birs.product_report_request b on a.id=b.id	and a.is_pts=b.ispts

 --экранам 
    drop table if exists _birs.[product_report_all_actions]
    select * into        _birs.[product_report_all_actions] from #strhovochnaya
	--update 	 product_report_debug_mode set is_debug = 0

	--select * from  product_report_debug_mode where 1=1 and 1=1 --group by --order by 1

return

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'BEBD9382-4332-4CA8-B572-FBE02423347C'	

	 
end

*/


/*

if @mode = 'select'  -- update 	 product_report_debug_mode set is_debug = 0
begin


-- update 	 product_report_debug_mode set is_debug = -1
-- update 	 product_report_debug_mode set is_debug = 1

-- select * from #stg_voronka2


--create table product_report_debug_mode (is_debug int) 
--insert into product_report_debug_mode select 1  update 	 product_report_debug_mode set is_debug = 1
-- update 	 product_report_debug_mode set is_debug = 0
-- update 	 product_report_debug_mode set is_debug =-1
if (select * from product_report_debug_mode ) =1


select top 0
* from  lead_bi
else 


select top 0----top 1000
* from lead_bi
--where День2>='20240901' 
--or [Выдача денег]>='20240901'
--or [Верификация кц]>='20240901'
--or [Как создан2] = '$balance_fact'

return
;

 --drop table if exists ##t1	

return																				 
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'BEBD9382-4332-4CA8-B572-FBE02423347C'	 , 1

end

 
	
if @mode  = 'visits'
begin  

drop table if exists #visits

;
with v as (
select created, stat_source, stat_type, client_google_id, stat_info  from   stg._crib.visits   with(nolock)
union all
select created_at_time, stat_source, stat_type, client_google_id, stat_info from  stg._lf.referral_visit 
--select * from  stg._lf.referral_visit 
--select * from  stg._lf.referral_visit 
 ) 


select-- top 0
  created = cast(created as date) 
, stat_source =  stat_source
, stat_type =   stat_type 
, visits = count(*) 
, unique_visits = count(distinct client_google_id)  
, stat_info
into #visits  --select top 100 *

from v --  with(nolock)
where cast(created as date)>= cast(getdate()-10 as date)
group by 
  cast(created as date)  
, stat_source	    
, stat_type
, stat_info


--select * into _birs.visits_stat
--from #visits

delete a from _birs.visits_stat  a join #visits b on  a.created = b.created  
insert into   _birs.visits_stat 
select * from #visits

 -- alter table  _birs.visits_stat add   stat_info nvarchar(255)


end
      
if @mode  = 'calls_inst'
begin  

drop table if exists #calls_inst_stg 
select --top 0 
attempt_start, project_id, client_number,case when  login is not null then attempt_start end attempt_start_login  into #calls_inst_stg from NaumenDbReport.dbo.detail_outbound_sessions
where project_id in (
'corebo00000000000ogs9ci91h86tk38', 
'corebo00000000000nr8tj5chijbg124', 
'corebo00000000000ogthe6vlmtgegak', 
'corebo00000000000ntveeltm4rn8h3c', 
'corebo00000000000o850i7n9g4sb1io', 
'corebo00000000000o852j2fm4a48cj4', 
'corebo00000000000ntveaeqb47pg1q0', 
'corebo00000000000nqvsc5jtklnqd70'
) and attempt_start>=cast(getdate()-10 as date) --'20230511'


--select * into _birs.installment_calls_on_abandoned_requests_and_drafts
--from #calls_inst_stg

delete a from   _birs.installment_calls_on_abandoned_requests_and_drafts  a join #calls_inst_stg b on cast(a.attempt_start as date) =  cast(b.attempt_start as date)
insert into   _birs.installment_calls_on_abandoned_requests_and_drafts 
select * from #calls_inst_stg


end
   
if @mode  = 'update_lead_request'
begin
			  
drop table if exists #requests
/*
select id, try_cast(lcrm_id as numeric) lcrm_id,case when is_installment=1	   or product_types_id in (2,3) then 0 else 1 end as ispts into #requests
from   stg._LK.requests
--where is_installment=1	   or product_types_id in (2,3)
  */
select   lk.id id, lk.created, isnull(isnull( r.marketing_lead_id  , LcrmID), lk.lead_id) lcrm_id, isnull( a.ispts, lk.ispts)ispts , a.guid  guid into #requests from
v_request_lk lk 
left join  v_request a	on lk.id=a.lk_request_id
left join stg._lf.request 	r on r.number=a.НомерЗаявки

drop table if exists #leads_with_requests

select 	lcrm_id
, max(case when ispts=1 then 1 end)	 has_pts_request
, max(case when ispts=0 then 1 end)	 has_bz_request
	   into #leads_with_requests
from #requests
group by lcrm_id

--select * from 	   #requests
--order by 1			  desc
if 1=1
begin

drop table if exists #leads_legacy
drop table if exists #leads_flow
 select ДатаЛидаЛСРМ
 , is_inst_lead
 , UF_PHONE
 , UF_SOURCE
 , UF_TYPE
 , cast(id as nvarchar(36))   id
 , ВремяПервойПопытки
 , ВремяПервогоДозвона
 , UF_LOGINOM_STATUS
 , ФлагПрофильныйИтог
 , uf_stat_ad_type
 , UF_REGISTERED_AT
 , [UF_PARTNER_ID аналитический]
 , [Группа каналов]
 , [Канал от источника]
 , UF_TYPE Entrypoint
 , ПричинаНепрофильности  
 , system = 'lcrm'
 , cast(null as nvarchar(255)) userAgent

 into #leads_legacy
 from Feodor.dbo.dm_leads_history a  
 where 1=0
 select cast(UF_REGISTERED_AT as date)	ДатаЛидаЛСРМ
 , is_inst_lead
 , UF_PHONE
 , UF_SOURCE
 , UF_TYPE
 , cast(id as nvarchar(50))   id
 , ВремяПервойПопытки
 , ВремяПервогоДозвона
 , UF_LOGINOM_STATUS
 , ФлагПрофильныйИтог
 , uf_stat_ad_type
 , UF_REGISTERED_AT
 , [UF_PARTNER_ID аналитический]
 , [Группа каналов]
 , [Канал от источника] 
 , Entrypoint Entrypoint
 , ПричинаНепрофильности ПричинаНепрофильности	
 , system = 'lf'
 , userAgent

 into   #leads_flow
 from Feodor.dbo.lead a with(nolock)
 where 1=0


end



drop table if exists #installment_lead_request

--select * from config
;
with v_ as (

 --select ДатаЛидаЛСРМ
 --, is_inst_lead
 --, UF_PHONE
 --, UF_SOURCE
 --, UF_TYPE
 --, cast(id as nvarchar(36))   id
 --, ВремяПервойПопытки
 --, ВремяПервогоДозвона
 --, UF_LOGINOM_STATUS
 --, ФлагПрофильныйИтог
 --, uf_stat_ad_type
 --, UF_REGISTERED_AT
 --, [UF_PARTNER_ID аналитический]
 --, [Группа каналов]
 --, [Канал от источника]
 --, UF_TYPE Entrypoint
 --, ПричинаНепрофильности  
 --, system = 'lcrm'
 --, cast(null as nvarchar(255)) userAgent
  
 --from Feodor.dbo.dm_leads_history a   union all
 --select 1 d-- cast(UF_REGISTERED_AT as date)	ДатаЛидаЛСРМ
 select cast(UF_REGISTERED_AT as date)	ДатаЛидаЛСРМ
 , is_inst_lead
 , UF_PHONE
 , UF_SOURCE
 , UF_TYPE
 , cast(id as nvarchar(50))   id
 , ВремяПервойПопытки
 , ВремяПервогоДозвона
 , UF_LOGINOM_STATUS
 , ФлагПрофильныйИтог
 , uf_stat_ad_type
 , UF_REGISTERED_AT
 , [UF_PARTNER_ID аналитический]
 , [Группа каналов]
 , [Канал от источника] 
 , Entrypoint Entrypoint
 , ПричинаНепрофильности ПричинаНепрофильности	
 , system = 'lf' 
 , userAgent
 from Feodor.dbo.lead a with(nolock)



)
, v as (

select * from #leads_flow union all 
select * from #leads_legacy 



)

select
  a.ДатаЛидаЛСРМ                                                                                             [ДатаЛидаЛСРМ]
, a.is_inst_lead                                                                                             [is_inst_lead]
, a.UF_SOURCE	                                                                                             [UF_SOURCE]
, a.UF_TYPE		                                                                                             [UF_TYPE]
, case when isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then a.id end                               [id]
, products.ispts is_pts
,  r.id                                                                                                      [request_id]
, count(a.id)                                                                                                [Лидов]
, count(ВремяПервойПопытки)                                                                                  [Лидов с попыткой] 
, count(ВремяПервогоДозвона)                                   	                                             [Лидов с дозвоном]
, count(case when UF_LOGINOM_STATUS='accepted' then a.id end)                                                [Лидов accepted]
, count(case when ФлагПрофильныйИтог=1 then a.id end) 	                                                     [Лидов профильных]
, a.uf_stat_ad_type		                                                                                     [uf_stat_ad_type]
, try_cast(case when   isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV')or r.lcrm_id  is not null then UF_PHONE end as nvarchar(10)) [UF_PHONE]
, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then UF_REGISTERED_AT end                   [UF_REGISTERED_AT]
, case when UF_LOGINOM_STATUS='accepted' then 1 else 0 end                                                   [is_accepted] 
,  case when  a.[Канал от источника]<>'CPA нецелевой' then [UF_PARTNER_ID аналитический]   	   end     	 [UF_PARTNER_ID аналитический]
, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [UF_LOGINOM_STATUS]   end    	         [UF_LOGINOM_STATUS]  
, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервойПопытки]  end    	         [ВремяПервойПопытки] 
, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервогоДозвона] end    	         [ВремяПервогоДозвона]
, a.[Группа каналов]	                                                                                             [Группа каналов]
, a.[Канал от источника]	                                                                                             [Канал от источника]
, a.Entrypoint	                                                                                             Entrypoint
, a.ПричинаНепрофильности	
ПричинаНепрофильности
 
 ,b.has_pts_request
 ,b.has_bz_request
 ,a.system
 , ub.browser_name    browser
 , ub.browser_version browserVersion
 , max(r.guid)  requestGuid

into #installment_lead_request

from v_ a
left join useragent_browser ub on ub.useragent=a.userAgent
left join (select 0 ispts union all select 1 ispts ) products	 on 1=1--r1.id is not null
left join #requests r on a.id= r.lcrm_id  and r.ispts=products.ispts
left join #leads_with_requests b on a.id=b.lcrm_id


 --select * from v_visit
 --where type='mp'
 


--where  a.ДатаЛидаЛСРМ >='20230511'-
--where  a.ДатаЛидаЛСРМ >=cast(getdate()-40 as date)
group by
 a.ДатаЛидаЛСРМ
,a.is_inst_lead
,a.UF_SOURCE
,a.UF_TYPE
,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then a.id end  	 
,r.id
,a.uf_stat_ad_type
,try_cast(case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV')  or r.lcrm_id  is not null then UF_PHONE end as nvarchar(10))
,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then UF_REGISTERED_AT end  		 
,case when UF_LOGINOM_STATUS='accepted' then 1 else 0 end   
, case when  a.[Канал от источника]<>'CPA нецелевой' then [UF_PARTNER_ID аналитический]   	   end 
,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [UF_LOGINOM_STATUS]   end    
,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервойПопытки]  end    
,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервогоДозвона] end    
, products.ispts
, a.[Группа каналов]	
, a.[Канал от источника]
, a.Entrypoint
, a.ПричинаНепрофильности
 ,b.has_pts_request
 ,b.has_bz_request	
 ,a.system
  , ub.browser_name
 , ub.browser_version
 
 
--drop table if exists _birs.[product_report_lead_request]
--select * into 	_birs.[product_report_lead_request] from #installment_lead_request
------
--from 	  #installment_lead_request
--
--select * from _birs.[product_report_lead_request]  a 
delete a from _birs.[product_report_lead_request]  a 
join   #installment_lead_request b on a.ДатаЛидаЛСРМ=b.ДатаЛидаЛСРМ and a.system=b.system
insert into 	_birs.[product_report_lead_request]    
select * from  #installment_lead_request

--alter table _birs.[product_report_lead_request]	  add   ПричинаНепрофильности nvarchar(100)	   
--alter table _birs.[product_report_conversions]	  add   ПричинаНепрофильности nvarchar(100)

--alter table _birs.[product_report_lead_request]	  add   has_pts_request  tinyint	   
--alter table _birs.[product_report_conversions]	  add   has_pts_request  tinyint

--alter table _birs.[product_report_lead_request]	  add   has_bz_request tinyint
--alter table _birs.[product_report_conversions]	  add   has_bz_request tinyint

--where UF_PHONE='9829166875'
--order by 1

--select top 100 *
--from _birs.[installment_lead_request]  a
																					   
--alter table  _birs.[installment_lead_request] add uf_stat_ad_type  varchar(128) 
--alter table  _birs.[installment_lead_request] add UF_PHONE  nvarchar(10) 
--alter table  _birs.[installment_lead_request] add UF_REGISTERED_AT  datetime2(0) 
--alter table  _birs.[installment_lead_request] add is_accepted tinyint
--alter table  _birs.[installment_lead_request] add is_accepted tinyint								   
--alter table  _birs.[installment_lead_request] add [UF_PARTNER_ID аналитический] varchar(256) 
--alter table  _birs.[installment_lead_request] add [UF_LOGINOM_STATUS] varchar(128) 
--alter table  _birs.[installment_lead_request] add [ВремяПервойПопытки] datetime2 
--alter table  _birs.[installment_lead_request] add [ВремяПервогоДозвона] datetime2
--alter table  _birs.[installment_lead_request] add Entrypoint  varchar(128) 
--alter table  _birs.[product_report_lead_request] add Entrypoint  varchar(128) 
--alter table  _birs.[product_report_lead_request] add browser_name    varchar(256) 
--alter table  _birs.[product_report_lead_request] add browser_version  varchar(256) 
--alter table  _birs.[product_report_lead_request] add requestGuid  varchar(36) 
 --, ub.browser_name
 --, ub.browser_version
end



 

 */

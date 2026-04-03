



CREATE       proc [dbo].[_request_fill_column] as


BEGIN TRY
    -- Ваш код



declare @dt  datetime2 = getdate()
declare @hourly  bigint 


set @hourly = 1


if eXISTS (
select top 1 * from jobh where command like '%request_fill_column%' and step_id=1 and succeeded>= format( getdate()   , 'yyyy-MM-dd HH:00:00')  ) 
set @hourly=0



if datepart(minute, getdate()) >=30
begin
set @hourly = 1

if eXISTS (
select top 1 * from jobh where  command like '%request_fill_column%' and step_id=1 and succeeded>= format( getdate()   , 'yyyy-MM-dd HH:30:00')  ) 
set @hourly=0
end  



--declare @hourly  bigint = case when datepart(minute, getdate()) <=5 then 1 end
declare @dayly  bigint = 0
if not exists (
select  top 1 * from jobh where command like '%' + 'request_fill_column' + '%' and succeeded>=cast(getdate() as date) ) set @dayly=1




if  @dayly = 0

begin


update aa set aa.leadId = coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id) 
, aa.originalLeadId = coalesce(a.original_lead_id,  lk.lead_Id ,  cast(a.lcrmID as nvarchar(36))  ) 
from request aa 
join  v_request a	on aa.guid=a.guid    
left join v_request_lk lk on lk.id=aa.id 
where 
(
coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id)  <> isnull(aa.leadId, '-1') 
)
  
and aa.created2>=getdate()-30 


update aa set  aa.entrypoint = r.entrypoint
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid 
where 
(isnull(aa.entrypoint , '')<> r.entrypoint )
and aa.created2>=getdate()-30 


update aa set   aa.source =  r.source 
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid and aa.channelConfirmed is null
where 
(  
  isnull(aa.source, '')<> r.source
)
  
and aa.created2>=getdate()-30 

update aa set   aa.channel =  r.channel 
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid and aa.channelConfirmed is null
where 
(  
  isnull(aa.channel, '')<> r.channel
)
  
and aa.created2>=getdate()-30 



update aa set  aa.partnerId = r.partnerId
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid 
where 
(isnull(aa.partnerId , '')<> r.partnerId )
and aa.created2>=getdate()-30 



 


if @hourly =1 begin

 update aa set 
aa.originaLentrypoint = a.entrypoint
from request aa 
join  v_lead2  a	with(nolock) on aa.originalLeadid=a.id  and aa.originaLentrypoint is null   and aa.created2>=getdate()-30 

 update aa set 
  aa.source = case when aa.channelConfirmed is not null  then aa.source else   a.source end
, aa.partnerId= a.partner_Id 

from _request aa 
join  v_lead2  a	with(nolock) on aa.leadid=a.id  and aa.source is null  and a.source is not null  and aa.created>=getdate()-30

 update aa set     aa.channel = b.channel  , aa.channelConfirmed = getdate() from _request aa  join   v_fa b on  b.number=aa.number 
 and isnull(aa.channel, '' )<> b.channel

  update aa set     aa.source = b.source , aa.channelConfirmed = getdate() from _request aa  join   v_fa b on  b.number=aa.number 
 and isnull(aa.source, '' )<> b.source

  ;
  with v as (
SELECT 
    
    JSON_VALUE(inc.value, '$.attributes.applicationNumber') number, min(updated) updated    
	--into #t2
FROM v_callback v
CROSS APPLY OPENJSON(v.payload, '$.included') AS inc
WHERE eventId = 'lf.event.8108.1.1'
  AND JSON_VALUE(inc.value, '$.type') = 'requestDatas'
  and isjson (inc.value) = 1
  and isjson (v.payload) = 1
  and v.created>= getdate()-10
  group by JSON_VALUE(inc.value, '$.attributes.applicationNumber')

  )
  update a set a.callbackPsbCall1Approved = updated from _request a join v on a.number=v.number and a.callbackPsbCall1Approved is null


update fa1 set fa1.isManualTakeUp =1  
from
v_communication_crm communication
join  _request fa1 on communication.number=fa1.number and fa1.approved is not null  and isSuccessfull=1  and communication.created >=approved and  communication.created <=isnull(fa1.issued, dateadd(day, 10, fa1.approved)) 
join employee   o on communication.seller  =  o.сотрудник
 where fa1.isManualTakeUp is null and fa1.approved>=getdate()-30


 update b set b.rbp = a.rbp_gr
 from 
 [dwh2].[dbo].[v_risk_apr_segment]  a join _request b on a.number=b.number and b.rbp  is null and  a.rbp_gr is not null and b.call1>=getdate()-30

 

 --drop table if exists #offerProofOfIncomeType
 --select a.number,
 
 --case 
 --when count(case when b.ПодтверждениеДохода = 1 then 1 end)>0 and  count(case when b.ПодтверждениеДохода = 0 then 1 end) >0 then 'С или Без'
 --when count(case when b.ПодтверждениеДохода = 1 then 1 end)>0 and  count(case when b.ПодтверждениеДохода = 0 then 1 end) =0 then 'С'
 --when count(case when b.ПодтверждениеДохода = 1 then 1 end)=0 and  count(case when b.ПодтверждениеДохода = 0 then 1 end) >0 then 'Без'
 --end offerProofOfIncomeType, min(case when b.РекомендуемыйДоход>0 and b.ПодтверждениеДохода=1 then  b.РекомендуемыйДоход end ) incomeRecommended
 --into #offerProofOfIncomeType
 --from _request a join   stg._1cCRM.РегистрСведений_ВариантыСуммЛогином b on a.link = b.Заявка  and a.call1approved>='20250701'
 -- group by a.number

   drop table if exists #offerProofOfIncomeType
 select a.number,
 
 case 
 when count(case when b.limitGroup = 'С подтверждением дохода' then 1 end)>0 and  count(case when  b.limitGroup  = 'Без подтверждения дохода' then 1 end) >0 then 'С/Без'
 when count(case when b.limitGroup = 'С подтверждением дохода'  then 1 end)>0 and  count(case when b.limitGroup  = 'Без подтверждения дохода' then 1 end) =0 then 'С'
 when count(case when b.limitGroup = 'С подтверждением дохода'  then 1 end)=0 and  count(case when b.limitGroup  = 'Без подтверждения дохода' then 1 end) >0 then 'Без'
 when count(case when b.limitGroup = 'С подтверждением дохода'  then 1 end)=0 and  count(case when b.limitGroup  = 'Без подтверждения дохода' then 1 end) =0 then ''
 end
 +
 case 
 when (count(case when b.limitGroup = 'С подтверждением дохода'  then 1 end)>0 or count(case when b.limitGroup  = 'Без подтверждения дохода' then 1 end) >0) and
 count(case when b.limitGroup = 'Самозанятый' then 1 end)>0  
 then '/'
 else ''
 end
 +
  case 
 when count(case when b.limitGroup = 'Самозанятый' then 1 end)>0   then 'СЗ' else '' end 
  
 offerProofOfIncomeType, min(case when b.[incomeRecommended]>0 and b.limitGroup = 'С подтверждением дохода' then  b.[incomeRecommended] end ) incomeRecommended
 , max(case when b.limitGroup = 'Без подтверждения дохода' then cast(b.sum as int) end )   sumNoProofOfIncome
 , max(case when b.limitGroup = 'С подтверждением дохода'  then cast(b.sum as int) end )   sumProofOfIncome
 , max(case when b.limitGroup = 'Самозанятый'  then cast(b.sum as int) end )   sumSelfemployed
 into #offerProofOfIncomeType
 from _request a with(nolock) join   v_request_loginom_sum2 b on a.link = b.link  and a.call1approved>='20250701'
  group by a.number

  
  --select   a.offerProofOfIncomeType, b.offerProofOfIncomeType, min(a.created) cr, count(*) cnt  from _request a left join #offerProofOfIncomeType b on a.number=b.number
  --group by  a.offerProofOfIncomeType, b.offerProofOfIncomeType
  --select distinct limitgroup from v_request_loginom_sum


  --EXEC sp_rename 'Analytics.dbo._request.offerProofOfIncomeType', '_______'
  --alter table Analytics.dbo._request alter column offerProofOfIncomeType varchar(20)
  --exec sp_rename 'dbo._request', '_________'
 
 update b set b.offerProofOfIncomeType =  a.offerProofOfIncomeType   
 , b.incomeRecommended = a.incomeRecommended
 , b.sumNoProofOfIncome  = a.sumNoProofOfIncome 
 , b.sumProofOfIncome	 = a.sumProofOfIncome	
 , b.sumSelfemployed	 = a.sumSelfemployed	
  

 from #offerProofOfIncomeType a join _request b on a.number=b.number  


 drop table if exists #add_product
  select a.ссылка
  , sum(case when Включена=1 then СуммаДопУслуги else 0 end)                       addProductSumRequest
  , sum(case when Включена=1  and СнижаетСтавку=1 then СуммаДопУслуги else 0 end)  addProductInsurSumRequest
  , sum(case when Включена=1  and СнижаетСтавку=0 then СуммаДопУслуги else 0 end)  addProductBoxSumRequest
 
  into #add_product from stg._1ccrm.Документ_ЗаявкаНаЗаймПодПТС_ДопУслуги a
   join stg._1ccrm.Справочник_ДополнительныеУслуги b on a.ДопУслуга=b.Ссылка
   join _request c on c.link=a.Ссылка and c.created>=getdate()-90
 group by  a.ссылка

 update _request set
 _request.addProductSumRequest = b.addProductSumRequest , 
 _request.addProductInsurSumRequest = b.addProductInsurSumRequest , 
 _request.addProductBoxSumRequest = b.addProductBoxSumRequest   
 from _request a join #add_product b on a.link= b.Ссылка
 

 update b set b.pdn =  a.pdn   
 from dwh2.sat.ДоговорЗайма_ПДН a join _request b on a.[КодДоговораЗайма]=b.loannumber   and  a.система  = 'CMR'
 
 
 --update b set b.IncomeVerificationSource =  a.IncomeVerificationSource   , incomeVerified = isnull( MonthlyPension, 0) + ISNULL(AverageMonthlyIncomeSum, 0)
 --from v_request_income a join _request b on a.number=b.number    
 ;
 WITH LastIncome AS (
    -- Выбираем последнюю запись для каждого номера заявки
    SELECT 
        number,
        IncomeVerificationSource,
        -- Считаем потенциальный новый подтвержденный доход заранее
        NULLIF(ISNULL(MonthlyPension, 0) + ISNULL(AverageMonthlyIncomeSum, 0), 0) AS CalculatedIncome
    FROM (
        SELECT *, 
               ROW_NUMBER() OVER (PARTITION BY number ORDER BY created DESC) as rn
        FROM v_request_income
    ) t
    WHERE rn = 1
)
UPDATE b
SET 
    b.IncomeVerificationSource = src.IncomeVerificationSource,
    b.incomeVerified = src.CalculatedIncome
FROM _request b
INNER JOIN LastIncome src ON b.number = src.number
WHERE 
    -- Условие на обновление только различий (с учетом NULL)
    ISNULL(b.IncomeVerificationSource, '') <> ISNULL(src.IncomeVerificationSource, '')
    OR ISNULL(b.incomeVerified, 0) <> ISNULL(src.CalculatedIncome, 0);

 ;

 with v as (
 select guid, count(*) cnt   
 from v_request_required_attachment a
 where isphoto=1
 group by guid
 )
 
 
 update b set b.requiredPhotoCnt =  a.cnt    
 from v  a
 join _request b on a.guid=b.guid



update a set a.proposalLimitChoise = case 

when b. LoginomAmmountLimitsGroupsId = 2 then 'withoutIncomeConfirm'  
when b. LoginomAmmountLimitsGroupsId = 4 then 'selfEmployed'
when b. LoginomAmmountLimitsGroupsId = 1 then 'withIncomeConfirm'
when b. LoginomAmmountLimitsGroupsId is not null then 'error'
end ,
proposalLimitChoiseCreated =  isnull(proposalLimitChoiseCreated,   getdate())

from _request a 
  join Stg._fedor.core_Proposal   b on a.guid =  cast(b.ClientRequestId as nvarchar(36)) and b.Selected=1 and 
  
 isnull( a.proposalLimitChoise, '') <> case 

when b. LoginomAmmountLimitsGroupsId = 2 then 'withoutIncomeConfirm'  
when b. LoginomAmmountLimitsGroupsId = 4 then 'selfEmployed'
when b. LoginomAmmountLimitsGroupsId = 1 then 'withIncomeConfirm'
when b. LoginomAmmountLimitsGroupsId is not null then 'error'
end


 

 --select * from request_income a 
 --left join _request b on a.number=b.number
 --order by a.created desc

 --alter table Analytics.dbo._request alter column pdn numeric(10,5)
 
 

 --  update b set b.checkOfIncome = 1
 --from 
 --[dwh2].[dbo].[v_risk_apr_segment]  a join _request b on a.number=b.number and b.rbp  is null and  a.rbp_gr is not null and b.call1>=getdate()-30

 --select * from stg._1cCRM.РегистрСведений_ВариантыСуммЛогином 
 --where заявка = 

 --0x9CF471C88D8F535F4FE6817DC755EFF8

 update b set b.productTypeExternal = a.productTypeExternal
 from 
 v_fa  a join _request b on a.number=b.number and isnull(b.productTypeExternal, '-1')<>   a.productTypeExternal 



 update b set b.productTypeExternal = a.productType
 from 
 v_request_external  a join _request b on a.id=b.leadId and  b.productTypeExternal is null and a.productType is not null



 /*

drop table if exists #thikhit
select   guid, THICK_HIT, call_date, userName
into #thikhit
 from stg._loginom.Originationlog with(nolock)
 where THICK_HIT is not null --and call_date>=getdate()-3


 ;with v  as (select *, row_number() over(partition by guid order by call_date desc) rn from #thikhit ) delete from v where rn>1


  update r set r.thikHit = THICK_HIT from _request r join #thikhit b on r.guid=b.guid

  

drop table if exists #eqxScoreGroupUnsecured
select   guid, eqxScoreGroupUnsecured, call_date--, userName
into #eqxScoreGroupUnsecured
 from stg._loginom.Originationlog with(nolock)
 where eqxScoreGroupUnsecured is not null --and call_date>=getdate()-3


 ;with v  as (select *, row_number() over(partition by guid order by call_date desc) rn from #eqxScoreGroupUnsecured ) delete from v where rn>1


  update r set r.eqxScoreGroupUnsecured = b.eqxScoreGroupUnsecured from _request r join #eqxScoreGroupUnsecured b on r.guid=b.guid

  */

  update r set r.eqxScoreGroupUnsecured = b.eqxScoreGroupUnsecured from _request r join dwh2.[sat].[ЗаявкаНаЗаймПодПТС_eqxScoreGroup] b on r.guid=b.GuidЗаявки 
  and ( r.eqxScoreGroupUnsecured is null or r.eqxScoreGroupUnsecured <> b.eqxScoreGroupUnsecured)



  if  (select count(distinct type) from _client_history where date = cast( getdate()  as date) )<>5

exec _client_history_creation

  update r set r.InitialEndDate = b.InitialEndDate from _request r join v_loan_overdue b on r.number=b.number and r.InitialEndDate  is null
  update r set r.InitialEndDate = b.InitialEndDate from _request r join v_loan_overdue b on cast(try_cast( r.number as bigint) as nvarchar(30))=b.number and r.InitialEndDate  is null


 exec marketing_source_Intersection

 --select * from [dwh2].[dbo].[v_risk_apr_segment]  where number='23032220808264'
  

 /*
drop table if exists #t2788282392 
select * into #t2788282392 from openquery (lkprod , 'select id,  request_source_guid from requests where request_source_guid is not null' ) 
update b set b.parentGuid = a.[request_source_guid]
from 
 #t2788282392 a join _request b on a.id=b.id  and b.parentguid is null and  a.[request_source_guid] is not null



--SELECT 
--           a.[id] ,   a.[num_1c] ,   a.[created_at] ,   a.[request_source_guid] ,   a.[lead_request_guid] ,   a.[request_source_lead_request_guid] ,   a.[request_source_product_type_guid] ,   a.[request_source_product_sub_type_guid] ,   a.[uprid_date] ,   a.[request_source_is_consents_received] ,   a.[is_ready_to_deposit] FROM Analytics.dbo.[lk_request_uniapi] a
*/

end



end 


else 


begin 


update _request set _request.isSelfEmployedManual = 1 from _request a join  _request_selfemployed_manual b on a.number = cast(b.[Номер заявки] as varchar(14))
 and isSelfEmployedManual is null

; with v as (
select number
, sum(case when Продукт = 'Снижение %% ставки' then cast( [сумма коммиссии]  as float) end)  addProductInsuranceCancellSum
--, sum(case when isnull(Продукт, '') <> 'Снижение %% ставки' then [сумма коммиссии] end)   addProductCancellSum
, sum(cast( [сумма коммиссии]  as float))   addProductCancellSum
from v_loan_add_product_refuse
group by number
)

 update a set a.addProductInsuranceCancellSum =  b.addProductInsuranceCancellSum , 
                       a. addProductCancellSum = b.addProductCancellSum
				--	 select * 
from _request a  join  v  b on a.number= b.number   
where 
   abs(isnull(a.addProductInsuranceCancellSum, 0) - isnull(b.addProductInsuranceCancellSum, 0)) > 0.00001
or abs(isnull(a.addProductCancellSum, 0) - isnull(b.addProductCancellSum, 0)) > 0.00001



 


exec _client_history_creation




exec [dbo].[_request_fill_row]
 


update aa set aa.leadId = coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id) 
, aa.originalLeadId = coalesce(a.original_lead_id,  lk.lead_Id ,  cast(a.lcrmID as nvarchar(36))  ) 
from request aa 
join  v_request a	on aa.guid=a.guid    
left join v_request_lk lk on lk.id=aa.id 
where 
(
coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id)  <> isnull(aa.leadId, '-1') 
)
  
and aa.created2>='20250301'


update aa set  aa.entrypoint = r.entrypoint
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid 
where 
(isnull(aa.entrypoint , '')<> r.entrypoint )
and aa.created2>=getdate()-30 


update aa set   aa.source =  r.source 
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid and aa.channelConfirmed is null
where 
(  
  isnull(aa.source, '')<> r.source
)
  
and aa.created2>='20250301'

update aa set   aa.channel =  r.channel 
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid and aa.channelConfirmed is null
where 
(  
  isnull(aa.channel, '')<> r.channel
)
  
and aa.created2>='20250301'



update aa set  aa.partnerId = r.partnerId
from request aa 
  join v_request_lf2 	r on r.guid=aa.guid 
where 
(isnull(aa.partnerId , '')<> r.partnerId )
and aa.created2>='20250301'



 update b set b.abPhotoUprid = c.name
 from 
Stg._LK.[requests_test_branches] a 
join _request b on a.request_id=b.id and b.abPhotoUprid is null and a.ab_test_id=6
join [Stg].[_LK].[ab_cases] c on c.id=a.ab_case_id  
 
--[Stg].[_LK].[ab_tests] 
 
 
--select c.name from 
--Stg._LK.[requests_test_branches] a 
--join _request b on a.request_id=b.id and b.abAddProductInsuranceDraft is null and a.ab_test_id=4
--join [Stg].[_LK].[ab_cases] c on c.id=a.ab_case_id  




;
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! вернуть
with comm as (
select phone, created, 'crm' type   from v_communication_crm  where isSuccessfull =1 union all  select phone, created, 'feodor' type from v_communication_feodor where isSuccessfull =1
)  , req as ( select guid,   cast( max(b.created)  as datetime2(0))     lastCommunicationCreated
from 
_request  a left join comm b on
a.phone=b.phone and b.created between dateadd(day, -90 , isnull( a.call1 , a.created) )  and isnull( a.call1 , a.created)
 --and  isnull( a.call1 , a.created)>=getdate()-30 
 group by a.guid 
)
 update _request set _request.lastCommunicationCreated= req.lastCommunicationCreated from _request join req on _request.guid=req.guid 
 and isnull(_request.lastCommunicationCreated, getdate())<>   isnull(req.lastCommunicationCreated, getdate())

 ;

with comm as (
select  right(client_number, 10) phone, attempt_start  created  from reports.dbo.dm_report_DIP_detail_outbound_sessions
where login is not null
)  , req as ( select guid, cast( max(b.created)  as datetime2(0))  lastLoyalCommunicationCreated
from 
_request  a left join comm b on
a.phone=b.phone and b.created between dateadd(day, -90 , isnull( a.call1 , a.created) )  and isnull( a.call1 , a.created)
 --and  isnull( a.call1 , a.created)>=getdate()-30 
 group by a.guid 
)
 update _request set _request.lastLoyalCommunicationCreated= req.lastLoyalCommunicationCreated from _request join req on _request.guid=req.guid
 and isnull(_request.lastLoyalCommunicationCreated, getdate())<>   isnull(req.lastLoyalCommunicationCreated, getdate())


 exec marketing_calc_cost_cpa

-- select * from dwh where column_name = 'lastLoaylCommunicationCreated'
-- EXEC sp_rename 'Analytics.dbo._request_log.lastLoaylCommunicationCreated', 'lastLoyalCommunicationCreated'
--EXEC sp_rename 'Analytics.dbo._request.lastLoaylCommunicationCreated', 'lastLoyalCommunicationCreated'
 --select * from _request
 --order by created desc

 --drop table if exists #calls
 --select attempt_start,   client_number into 	#calls from reports.dbo.dm_report_DIP_detail_outbound_sessions
 --where login is not null

 if not  exists (select top 1 * from v_balance where date = cast( getdate()  as date)  and dpd>0 ) begin exec log_email '!!! CRITICAL ERROR balance not calculated' --select 1/0 
 
 --return 
 end
	drop table if exists #dpd_closed
	select number number
	, max(case when date=cast( getdate() as date)  then dpd_begin_day end ) DpdBeginDay  
	, max(case when date=closed then dpdBeginDay end ) closedDpdBeginDay  
	, max(   dpdBeginDay   ) DpdMaxBeginDay  
 
	into #dpd_closed from v_balance a --where date=closed
	group by number

	select a.number, datediff( day,  max(case when a.dpd_begin_day =0 then date end) , getdate()) dpdDays into #dpd from v_balance a join  #dpd_closed b on a.number=b.number
where b.DpdBeginDay>0
group by  a.number

drop table if exists #dpd_closed1
select a.number , max(a.DpdBeginDay )  DpdBeginDay,  max(a.closedDpdBeginDay   ) closedDpdBeginDay ,   max(a.DpdMaxBeginDay  )  DpdMaxBeginDay , datediff( day,  max(case when b.dpdBeginDay =0 then date end) , getdate()) dpdDays 
into #dpd_closed1

from #dpd_closed a left join  v_balance b   on a.number=b.number and a.DpdBeginDay>0
group by  a.number


--select * from #dpd_closed1


	drop table if exists #dpd_closed0
	select * into #dpd_closed0 from #dpd_closed1  where 1=0

	--exec sp_select_except '#dpd_closed', '_request', 'number', '#dpd_closed'
	
    INSERT INTO #dpd_closed0 ([closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [number], dpdDays)
    SELECT [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [number], dpdDays
    FROM  #dpd_closed1
    EXCEPT
    SELECT [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [number], dpdDays
    FROM _request
    WHERE _request.number IN (
        SELECT number
        FROM   #dpd_closed1
    );
	update _request set  

	  _request.[closedDpdBeginDay]  =  d.[closedDpdBeginDay]
	, _request.[DpdBeginDay] 	   =   d.[DpdBeginDay] 	  
	, _request.[DpdMaxBeginDay]    =   d.[DpdMaxBeginDay]   
	, _request.dpdDays             =   d.dpdDays   
	 --, _request.row_updated = @dt
	from _request join #dpd_closed1 d	  on d.number = _request.number

	
	update _request set  

	  _request.[closedDpdBeginDay]  = null
	, _request.[DpdBeginDay] 	   =  null
	, _request.[DpdMaxBeginDay]    =  null
	, _request.dpdDays    =  null
	--, _request.row_updated = @dt
	from _request left join #dpd_closed1 d	  on d.number = _request.number
	where d.number  is null and isnull(isnull(isnull(   _request.[closedDpdBeginDay] 
		, _request.[DpdBeginDay] 	 )   
		, _request.[DpdMaxBeginDay]    )
		, _request.dpdDays    )
		is not null 

		 

drop table if exists #reqCLientHistPts
		select a.guid, b.category, b.limit,   b.date, b.type, datediff(day, b.date,  isnull(a.call1, a.created) ) dif into #reqCLientHistPts from  _request a 
		join  client_history b on a.clientId=b.clientId
		and b.date between cast( dateadd(day, -10,   isnull(a.call1, a.created)  ) as date)  and  cast( isnull(a.call1, a.created)    as date)
		and 1=b.ispts
		and a.returnType=b.returnType

		;with v  as (select *, row_number() over(partition by guid order by dif , limit desc) rn from #reqCLientHistPts ) delete from v where rn>1
		 
drop table if exists #reqCLientHistBezzalog
		select a.guid, b.category, b.limit,   b.date, b.type, datediff(day, b.date,  isnull(a.call1, a.created) ) dif into #reqCLientHistBezzalog from  _request a 
		join  client_history b on a.clientId=b.clientId
		and b.date between cast( dateadd(day, -10,   isnull(a.call1, a.created)  )  as date) and  cast( isnull(a.call1, a.created)    as date)
		and 0=b.ispts
		and a.returnType=b.returnType

		;with v  as (select *, row_number() over(partition by guid order by dif , limit desc) rn from #reqCLientHistBezzalog ) delete from v where rn>1
		 
		--select distinct returnType from _request
		--select distinct returnType from client_history


		--select * from #reqCLientHist
update a set a.clientCategoryPts = b.category,  a.clientLimitPts = b.limit   from  _request a   join  #reqCLientHistPts b  on a.guid=b.guid  
update a set a.clientCategoryBezzalog = b.category,  a.clientLimitBezzalog = b.limit   from  _request a   join  #reqCLientHistBezzalog b  on a.guid=b.guid  

drop table if exists #reqCLientDpd

select a.guid
, max(case when  b.ispts=1 then c.dpdBeginDay end   ) clientMaxDpdPts
, max(case when   b.ispts=0 then c.dpdBeginDay end  ) clientMaxDpdBezzalog
into #reqCLientDpd
from  _request a  
join _request b on a.clientId=b.clientId and a.guid<>b.guid
join v_balance c on c.number=b.number and  c.date<cast( isnull(a.call1, a.created)   as date) 
group by  a.guid

update a set a.clientMaxDpdPts = b.clientMaxDpdPts,  a.clientMaxDpdBezzalog = b.clientMaxDpdBezzalog   from  _request a   join  #reqCLientDpd b  on a.guid=b.guid  


drop table if exists #loan_schedule

select loanNumber, sum(paySum) scheduleTotalPay into #loan_schedule from loan_schedule
group by loanNumber

update a set a.scheduleTotalPay = b.scheduleTotalPay   from  _request a   join  #loan_schedule b  on a.loanNumber=b.loanNumber  


drop table if exists #loan_pay

select number loanNumber, sum(Сумма) TotalPay into #loan_pay from v_repayments
group by number

update a set a.TotalPay = b.TotalPay   from  _request a   join  #loan_pay b  on a.loanNumber=b.loanNumber  





--update a set a.checkingSla = null  from  _request a   join  #checkingSla b  on a.number=b.number  
--drop table if exists #checkingSla
--select number, sum(time) checkingSla into #checkingSla from v_verification where  status='контроль данных' and type   in ('В работе', 'Ожидание',  'Отложено')
--group by number
--update a set a.checkingSla = b.checkingSla   from  _request a   join  #checkingSla b  on a.number=b.number  


drop table if exists #checkingSla
select number
, sum(case when  type   in ('В работе', 'Ожидание',  'Отложено') then time end) checkingSla
, sum(case when  type   in ('В работе', 'Ожидание' ) then time end) checkingSlaNet
, sum(case when type = 'На доработках' then 1 end) checkingRefinement
, sum(case when type = 'На доработках' then time end) checkingRefinementSLA
into #checkingSla 


from v_verification where 
status='контроль данных'  and  requestDate>=getdate()-30 
group by number
update a set a.checkingSla = b.checkingSla 
, a.checkingSlaNet = b.checkingSlaNet 

, a.checkingRefinement = b.checkingRefinement , a.checkingRefinementSLA = b.checkingRefinementSLA from  _request a   join  #checkingSla b  on a.number=b.number  
 

drop table if exists #tmpRefinementRequest
select link ,id , guid, number,status_crm,checking, isnull( isnull(call2, declined), cancelled) checkingEnd into #tmpRefinementRequest from _request where-- checking >=getdate()-30 and
ispts=1  

drop table if exists #t234727920239

select  a.guid, max(case 
when comment like '%' + 'ПТС' + '%'   then 1
when comment like '%' + 'СТС' + '%'   then 1
 
end) ptsSts, max(case  
when comment like '%' + 'паспорт' + '%'   then 1

end ) passport

into #tmpRefinement
from #tmpRefinementRequest a  left  join v_request_comment b on a.link=b.link
and b.created between checking and checkingEnd and  case 
when comment like '%' + 'чет' + '%'  then '1'
when comment like '%' + 'чит' + '%'  then '1'
when  comment like '%' + 'блик' + '%'          then '1'
when  comment like '%' + 'засвет' + '%'          then '1'
when  comment like '%' + 'полностью%попад' + '%' then '1'  
when  comment like  '%' + 'должны%быть%в%кадре' + '%'  then '1' end =1
group by 
 a.guid



 


-- select *   
--from #t328378328727837823 a  left  join v_comment b on a.link=b.link
--and b.created between checking and checkingEnd and  case 
--when comment like '%' + 'четк' + '%'  then '1'
--when comment like '%' + 'читаем' + '%'  then '1'
--when  comment like '%' + 'блик' + '%'          then '1'
--when  comment like '%' + 'засвет' + '%'          then '1'
----when  comment like '%' + 'полностью%попад' + '%' then '1'  
--when  comment like  '%' + 'должны%быть%в%кадре' + '%'  then '1'
--end =1
 



 --select * from #t234727920239

 update a set  
 a.checkingRefinementPhotoQualityPtsSts = b. ptsSts , 
 a.checkingRefinementPhotoQualityPassport = b. passport 
 
 from _request a join #tmpRefinement  b on a.guid=b.guid
 
 
 update _Request set _Request.ptsType =   cc.name 
 from
 _request  join v_request_feodor a on a.Number=_request.number
join stg.[_fedor].[core_ClientAssetTs] b on a.idasset=b.id 
left join stg.[_fedor].core_PersonDocumentPts с     on с.id = b.IdDocumentPts
 join  Stg._fedor.[dictionary_PtsType] cc on cc.Id = с.IdType


 
 update a set a.purpose =   b.status 
 from
 _request a  join v_request_checklist b on a.number=b.number and b. type = 'Цель займа'		
 and b.created>=getdate()-90


  update _Request set _Request.inn =   a.inn 
   
 from
 _request  join
 (select clientId, inn, row_number() over(partition by clientId order by created desc) rn from
 v_client_inn a where inn is not null) a on a.clientId=_request.clientId and   ( a.inn <> _Request.inn   or   _Request.inn  is null )  
 and a.rn=1


 --select * from v_client_inn where inn='623301847282'

   update _Request set _Request.inn =  a.inn
 from
 _request  join
 ( select id, isnull(InnFromService ,  InnFromLeadGen) inn, row_number()over ( partition by id order by createdOn desc ) rn  from Stg._fedor.core_ClientRequestClientInfo a
 where  isnull(InnFromService ,  InnFromLeadGen)  <>''
 ) a on a.id= _request.guid and _request.inn is  null and a.rn=1


  

  update _Request set _Request.isSelfEmployed =   a.isSelfEmployed 
 from
 _request  join  Stg._fedor.core_ClientRequestClientInfo a on a.id=_request.guid and  a.isSelfEmployed  is not null
 and _request.created>=getdate()-30 


  


 
drop table if exists #carVerificationSla
select number
,  sum(case when status = 'Верификация ТС' and type   in ('В работе', 'Ожидание',  'Отложено') then time end)carVerificationSla
,  sum(case when status = 'Верификация ТС' and type = 'На доработках' then 1 end) carVerificationRefinement
,  sum(case when status = 'Верификация клиента'  and type   in ('В работе', 'Ожидание',  'Отложено') then time end)verificationSla
,  sum(case when status = 'Верификация клиента'  and type   in ('В работе', 'Ожидание' ) then time end)verificationSlaNet
,  sum(case when status = 'Верификация клиента'  and type = 'На доработках' then 1 end) verificationRefinement




into #carVerificationSla 

--select distinct status
from v_verification where 
status in ('Верификация ТС', 'Верификация клиента') and  requestDate>=getdate()-30 
group by number

update a set
a.carVerificationSla = b.carVerificationSla , a.carVerificationRefinement = b.carVerificationRefinement ,
a.verificationSla = b.verificationSla , a.verificationRefinement = b.verificationRefinement 
, a.verificationSlaNet = b.verificationSlaNet



from  _request a   join  #carVerificationSla b  on a.number=b.number  
 





 
 --update a set a.employmentType =   b.employmentType 
 --from
 --_request a join v_request  b on a.guid=b.guid and b.employmentType is not null
 --and  a.employmentType is null

 --select employmentType into #twueiuewuew1 from v_request 

--update a set a.previousRequestCreated =null, a.previousRequestStatus=null from _request a join #t3287832823812 b on a.guid=b.guid

 drop table if exists #tmpPrevRequest
select a.guid, a.created,  isnull( b.call1, b.created) previousRequestCreated
, case 
  when b.issued is not null then 'Заем выдан' 
  when b.approved is not null then 'Одобрено' 
  when b.declined is not null then 'Отказано' 
 when  isnull( b.call1, b.created) is not null then 'Аннулировано' 
  end
 previousRequestStatus
 into #tmpPrevRequest
from _request a
left join _request b on (  a.fiobirthday=b.fiobirthday  ) and b.isDubl=0 and b.guid<>a.guid and   b.call1  < isnull( a.call1, a.created) 
and a.isPts=b.isPts
and iSNULL(a.loanOrder, 1) =isnull(b.loanOrder, 1)

insert into #tmpPrevRequest
select a.guid, a.created,  isnull( b.call1, b.created) previousRequestCreated
, case 
  when b.issued is not null then 'Заем выдан' 
  when b.approved is not null then 'Одобрено' 
  when b.declined is not null then 'Отказано' 
 when  isnull( b.call1, b.created) is not null then 'Аннулировано' 
  end
 previousRequestStatus
 
from _request a
left join _request b on (  a.passportSerialNumber=b.passportSerialNumber ) and b.isDubl=0 and b.guid<>a.guid and   b.call1  < isnull( a.call1, a.created) 
and a.isPts=b.isPts
and iSNULL(a.loanOrder, 1) =isnull(b.loanOrder, 1)

insert into #tmpPrevRequest
select a.guid, a.created,  isnull( b.call1, b.created) previousRequestCreated
, case 
  when b.issued is not null then 'Заем выдан' 
  when b.approved is not null then 'Одобрено' 
  when b.declined is not null then 'Отказано' 
 when  isnull( b.call1, b.created) is not null then 'Аннулировано' 
  end
 previousRequestStatus
 
from _request a
left join _request b on (  a.phone=b.phone ) and b.isDubl=0 and b.guid<>a.guid and   b.call1  < isnull( a.call1, a.created) 
and a.isPts=b.isPts
and iSNULL(a.loanOrder, 1) =isnull(b.loanOrder, 1)

;with v  as (select *, row_number() over(partition by guid order by  previousRequestCreated desc) rn from #tmpPrevRequest ) delete from v where rn>1

update a set a.previousRequestCreated = b.previousRequestCreated, a.previousRequestStatus=b.previousRequestStatus from _request a join #tmpPrevRequest b on a.guid=b.guid


--drop table if exists #cession
--select [Номер заявки] number, Продан cession,  [Ссылка договор CMR] link  into  #cession from v_Справочник_Договоры where Продан is not null
 
----update a set a.cession = b.cession, a.cessionSum = (c.СуммаПродажи)*(1-0.2/1.2)  from _request a 
----   join #cession b on a.number=b.number 
----   join Stg._1cCMR.Документ_ПродажаДоговоров_Договоры c on c.Договор = b.link
---- where    a.cession is null


  
--update a set a.cession = b.cession, a.cessionSum = t.Сумма  from _request a 
-- left  join #cession b on a.number=b.number 
 
-- left  join (
 
-- select t2.НомерДоговора loanNumber , t1.Сумма 
-- from      [Stg].[_1cUMFO].[Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного_Займы] t1  
--    join   [Stg].[_1cUMFO].[Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного] t on t.Ссылка = t1.Ссылка and  t.ПометкаУдаления=0 and t1.Сумма>0
--	join   [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] t2 on t2.Ссылка=t1.Займ

--	) t on t.loanNumber=a.loanNumber
--  where  isnull( a.cession, getdate())  != isnull(cast(b.cession as date), getdate()) or isnull( a.cessionSum, -1) !=  isnull(t.Сумма , -1)



  drop table if exists #cession;
select 
    [Номер заявки] as number, 
    cast(Продан as date) as cession_date
into #cession 
from v_Справочник_Договоры 
where Продан is not null;

-- 2. Подготовка сумм
drop table if exists #cession_sums;
select 
    t2.НомерДоговора as loanNumber, 
    sum(t1.Сумма) as total_sum
into #cession_sums
from [Stg].[_1cUMFO].[Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного_Займы] t1  
join [Stg].[_1cUMFO].[Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного] t on t.Ссылка = t1.Ссылка 
join [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] t2 on t2.Ссылка = t1.Займ 
 
where t.ПометкаУдаления = 0 and t1.Сумма > 0
group by t2.НомерДоговора;


update a 
set 
    -- Дату берем, только если есть сумма И (дата из справочника ИЛИ дата закрытия)
    a.cession = case 
        when s.total_sum > 0 and (b.cession_date is not null or a.closed is not null) 
        then isnull(b.cession_date, a.closed) 
    end, 
    
    -- Сумму берем, только если удалось определить дату
    a.cessionSum = case 
        when s.total_sum > 0 and (b.cession_date is not null or a.closed is not null) 
        then s.total_sum 
    end 
from _request a 
left join #cession b on a.number = b.number 
left join #cession_sums s on a.loanNumber = s.loanNumber
where 
    -- Условие 1: Исправляем текущие аномалии (сумма есть, даты нет)
    (a.cessionSum > 0 and a.cession is null)
    
    -- Условие 2: Проверка изменения даты
    or isnull(cast(a.cession as date), '1900-01-01') != 
       isnull(cast(case when s.total_sum > 0 and (b.cession_date is not null or a.closed is not null) then isnull(b.cession_date, a.closed) end as date), '1900-01-01')
    
    -- Условие 3: Проверка изменения суммы
    or isnull(a.cessionSum, -1) != 
       isnull(case when s.total_sum > 0 and (b.cession_date is not null or a.closed is not null) then s.total_sum end, -1);


  
--sp_create_job 'Analytics._etl_request_product_report', 'exec _product_report ''prep''', '0'
--exec _product_report 'prep'
EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._etl_request_product_report'





--sp_create_job 'Analytics._etl_request_add_product', '_request_add_product', '0'
--exec _request_add_product
EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._etl_request_add_product'


 --_etl_request
 

end


 
END TRY
BEGIN CATCH
    DECLARE 
        @errorMessage NVARCHAR(4000),
        @errorSeverity INT,
        @errorState INT,
        @errorLine INT;

    -- Получаем данные об ошибке
    SELECT 
        @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE(),
        @errorLine = ERROR_LINE();

	set	@errorMessage =   CONCAT('Ошибка на строке: ', @errorLine, ' — ', @errorMessage)

    -- Можно вернуть строку ошибки
    PRINT @errorMessage;

    -- Или вернуть через SELECT, если нужно в DataFrame
    SELECT 
        ErrorLine = @errorLine,
        ErrorMessage = @errorMessage;

    -- Повторно выбрасываем ошибку с уточнением строки
    THROW 50000, @errorMessage, 1;
END CATCH;















/*
IncomeVerificationSource
checkingRefinement
 carVerificationSla  [decimal](38, 10)
 carVerificationRefinement
 isSelfEmployed
 sumNoProofOfIncome 
 sumProofOfIncome	
 sumSelfemployed	
 inn	
purpose 
isSelfEmployedManual
addProductSumRequest
addProductInsurSumRequest
addProductBoxSumRequest
verificationRefinement
verificationSla 

proposalLimitChoise
proposalLimitChoiseCreated
 
 addProductInsuranceCancellSum , 
 addProductCancellSum
 incomeVerified
 callbackPsbCall1Approved


 
 declare @lastIssued    varchar(max) =   '[callbackPsbCall1Approved] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 
 declare @lastIssued    varchar(max) =   '[incomeVerified] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 
 declare @lastIssued    varchar(max) =   '[addProductInsuranceCancellSum] float '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[addProductCancellSum] float '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 
 declare @lastIssued    varchar(max) =   '[proposalLimitChoiseCreated] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[proposalLimitChoise] varchar(50) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[requiredPhotoCnt] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[requiredPhotoCnt] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



 declare @lastIssued    varchar(max) =   '[verificationRefinement] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[verificationSla]  [decimal](38, 10) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[addProductSumRequest] numeric(15,2) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[addProductInsurSumRequest] numeric(15,2)  '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[addProductBoxSumRequest] numeric(15,2) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )





 declare @lastIssued    varchar(max) =   '[isSelfEmployedManual] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[purpose] varchar(255) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


  
 declare @lastIssued    varchar(max) =   '[innIpStatus] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

  
 declare @lastIssued    varchar(max) =   '[innIpJson] varchar(1000) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[innIpProccessed] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 
 declare @lastIssued    varchar(max) =   '[inn] varchar(12) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[sumNoProofOfIncome] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[sumProofOfIncome] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[sumSelfemployed] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 
 declare @lastIssued    varchar(max) =   '[isSelfEmployed] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[carVerificationRefinement] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[carVerificationSla]  [decimal](38, 10) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



 declare @lastIssued    varchar(max) =   '[checkingRefinement] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[incomeRecommended] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )




 declare @lastIssued    varchar(max) =   '[pdn] numeric  '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

		  
 declare @lastIssued    varchar(max) =   '[IncomeVerificationSource] varchar(100)  '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



*/


 --declare @lastIssued    varchar(max) =   '[abPhotoUprid] varchar(255) '
 --exec ( 'alter table _request add '+@lastIssued+' 
	--	  alter table _request_log add '+@lastIssued )


	
--alter table _request     add checkingRefinementSLA  [decimal](38, 10)
--alter table _request_log add checkingRefinementSLA  [decimal](38, 10)

--alter table _request add  originalLeadId nvarchar(36)
--alter table _request_log add  originalLeadId nvarchar(36)

--select * from dwh where table_name=   '_request'  
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN source nvarchar(50)
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN source nvarchar(50)
--alter table _request add entrypoint nvarchar(10)
--alter table _request_log add entrypoint nvarchar(10)
--alter table _request add source nvarchar(10)
--alter table _request_log add source nvarchar(10)

 --update aa set     aa.source = b.uf_source   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.id=aa.leadId  and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and len( b.uf_source ) <=40
 --update aa set     aa.source = b.uf_source   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.uf_row_id=aa.number and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and len( b.uf_source ) <=40 and  aa.source  is null
 
 --update aa set aa.entrypoint = a.entrypoint  from _request aa  join  v_lead2  a	with(nolock) on aa.leadid=a.id  and aa.entrypoint is null  and aa.created>='20240425'   
 --update aa set    aa.source =  a.source from _request aa  join  v_lead2   a  with(nolock)	on aa.leadid=a.id  and aa.source is null  and a.source is not null  and aa.created>='20240425'  
 
 --alter table _request add lastCommunicationCreated datetime2(0)
 --alter table _request_log add lastCommunicationCreated datetime2(0)


 --alter table _request add parentGuid nvarchar(36)
 --alter table _request_log add  parentGuid nvarchar(36)

--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN closedDpdBeginDay smallint null
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN DpdBeginDay smallint		 null
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN DpdMaxBeginDay smallint	 null
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN closedDpdBeginDay smallint null
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN DpdBeginDay smallint		 null
--ALTER TABLE Analytics.dbo.[	] ALTER COLUMN DpdMaxBeginDay smallint	 null

--alter table _request     add lastLoaylCommunicationCreated datetime2(0)
--alter table _request_log add lastLoaylCommunicationCreated datetime2(0)


--alter table _request     add rbp nvarchar(50)
--alter table _request_log add rbp nvarchar(50)



--alter table _request     add dpdDays int
--alter table _request_log add dpdDays int



--alter table _request     add channel nvarchar(30)
--alter table _request_log add channel nvarchar(30)

--alter table _request     add channelConfirmed datetime2(0)
--alter table _request_log add channelConfirmed datetime2(0)


 --update aa set     aa.channel = b.[канал от источника]   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.id=aa.leadId  and b.[канал от источника]<>'' and isnumeric(aa.leadid)=1-- and len( b.uf_source ) <=40
 --update aa set     aa.channel = b.[канал от источника]   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on  b.uf_row_id=aa.number  and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and aa.channel is null
 --update aa set     aa.channel = b.channel   from _request aa  join   v_lead2 b on  b.id=aa.leadId  and aa.channel is null
 --update aa set     aa.channel = b.channel  , aa.channelConfirmed = getdate() from _request aa  join   v_fa b on  b.number=aa.number 

 --update aa set     aa.partnerId = b.partner_Id   from _request aa  join   v_lead2 b on  b.id=aa.leadId  and aa.[partnerId] is null

 
--alter table _request add originaLentrypoint nvarchar(36)
--alter table _request_log add originaLentrypoint nvarchar(36)

 
--alter table _request add clientCategoryPts nvarchar(36)
--alter table _request_log add clientCategoryPts nvarchar(36)
--alter table _request add clientLimitPts int
--alter table _request_log add clientLimitPts int

--alter table _request add clientMaxDpdPts tinyint
--alter table _request_log add clientMaxDpdPts tinyint


 

--alter table _request add clientMaxDpdBezzalog smallint
--alter table _request_log add clientMaxDpdBezzalog smallint
--alter table _request add clientMaxDpdPts smallint
--alter table _request_log add clientMaxDpdPts smallint




 
--alter table _request add clientCategoryBezzalog nvarchar(36)
--alter table _request_log add clientCategoryBezzalog nvarchar(36)
--alter table _request add clientLimitBezzalog int
--alter table _request_log add clientLimitBezzalog  int

--alter table _request add thikHit int
--alter table _request_log add thikHit  int



--alter table _request     add firstLoanRbp nvarchar(50)
--alter table _request_log add firstLoanRbp nvarchar(50)

--alter table _request     add firstLoanNumber nvarchar(30)
--alter table _request_log add firstLoanNumber nvarchar(30)



--alter table _request     add checkingSla  [decimal](38, 10)
--alter table _request_log add checkingSla  [decimal](38, 10)


--alter table _request     add partnerId nvarchar(255)
--alter table _request_log add partnerId nvarchar(255)

--alter table _request     add previousRequestCreated datetime2(0)
--alter table _request_log add previousRequestCreated datetime2(0)


--alter table _request     add previousRequestStatus nvarchar(50)
--alter table _request_log add previousRequestStatus nvarchar(50)


--alter table _request     add checkingRefinementPhotoQualityPtsSts tinyint
--alter table _request_log add checkingRefinementPhotoQualityPtsSts tinyint
--alter table _request     add checkingRefinementPhotoQualityPassport tinyint
--alter table _request_log add checkingRefinementPhotoQualityPassport tinyint




--alter table _request     drop column checkingRefinementPtsSts  --tinyint
--alter table _request_log drop column checkingRefinementPtsSts  --tinyint
--alter table _request     drop column checkingRefinementPassport--tinyint
--alter table _request_log drop column checkingRefinementPassport--tinyint


--alter table _request add sourceRedefined nvarchar(100)
--alter table _request_log add sourceRedefined nvarchar(100)


--alter table _request add channelRedefined nvarchar(100)
--alter table _request_log add channelRedefined nvarchar(100)
--alter table _request add ptsType nvarchar(20)
--alter table _request_log add ptsType nvarchar(20)
--alter table _request add employmentType nvarchar(50)
--alter table _request_log add employmentType nvarchar(50)


--alter table _request add  originalLeadId nvarchar(36)
--alter table _request_log add  originalLeadId nvarchar(36)

--select * from dwh where table_name=   '_request'  
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN source nvarchar(50)
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN source nvarchar(50)
--alter table _request add entrypoint nvarchar(10)
--alter table _request_log add entrypoint nvarchar(10)
--alter table _request add source nvarchar(10)
--alter table _request_log add source nvarchar(10)

 --update aa set     aa.source = b.uf_source   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.id=aa.leadId  and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and len( b.uf_source ) <=40
 --update aa set     aa.source = b.uf_source   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.uf_row_id=aa.number and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and len( b.uf_source ) <=40 and  aa.source  is null
 
 --update aa set aa.entrypoint = a.entrypoint  from _request aa  join  v_lead2  a	with(nolock) on aa.leadid=a.id  and aa.entrypoint is null  and aa.created>='20240425'   
 --update aa set    aa.source =  a.source from _request aa  join  v_lead2   a  with(nolock)	on aa.leadid=a.id  and aa.source is null  and a.source is not null  and aa.created>='20240425'  
 
 --alter table _request add lastCommunicationCreated datetime2(0)
 --alter table _request_log add lastCommunicationCreated datetime2(0)


 --alter table _request add parentGuid nvarchar(36)
 --alter table _request_log add  parentGuid nvarchar(36)

--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN closedDpdBeginDay smallint null
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN DpdBeginDay smallint		 null
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN DpdMaxBeginDay smallint	 null
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN closedDpdBeginDay smallint null
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN DpdBeginDay smallint		 null
--ALTER TABLE Analytics.dbo.[	] ALTER COLUMN DpdMaxBeginDay smallint	 null

--alter table _request     add lastLoaylCommunicationCreated datetime2(0)
--alter table _request_log add lastLoaylCommunicationCreated datetime2(0)


--alter table _request     add rbp nvarchar(50)
--alter table _request_log add rbp nvarchar(50)



--alter table _request     add dpdDays int
--alter table _request_log add dpdDays int



--alter table _request     add channel nvarchar(30)
--alter table _request_log add channel nvarchar(30)

--alter table _request     add channelConfirmed datetime2(0)
--alter table _request_log add channelConfirmed datetime2(0)


 --update aa set     aa.channel = b.[канал от источника]   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.id=aa.leadId  and b.[канал от источника]<>'' and isnumeric(aa.leadid)=1-- and len( b.uf_source ) <=40
 --update aa set     aa.channel = b.[канал от источника]   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on  b.uf_row_id=aa.number  and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and aa.channel is null
 --update aa set     aa.channel = b.channel   from _request aa  join   v_lead2 b on  b.id=aa.leadId  and aa.channel is null
 --update aa set     aa.channel = b.channel  , aa.channelConfirmed = getdate() from _request aa  join   v_fa b on  b.number=aa.number 

 --update aa set     aa.partnerId = b.partner_Id   from _request aa  join   v_lead2 b on  b.id=aa.leadId  and aa.[partnerId] is null

 
--alter table _request add originaLentrypoint nvarchar(36)
--alter table _request_log add originaLentrypoint nvarchar(36)

 
--alter table _request add clientCategoryPts nvarchar(36)
--alter table _request_log add clientCategoryPts nvarchar(36)
--alter table _request add clientLimitPts int
--alter table _request_log add clientLimitPts int

--alter table _request add clientMaxDpdPts tinyint
--alter table _request_log add clientMaxDpdPts tinyint


 

--alter table _request add clientMaxDpdBezzalog smallint
--alter table _request_log add clientMaxDpdBezzalog smallint
--alter table _request add clientMaxDpdPts smallint
--alter table _request_log add clientMaxDpdPts smallint




 
--alter table _request add clientCategoryBezzalog nvarchar(36)
--alter table _request_log add clientCategoryBezzalog nvarchar(36)
--alter table _request add clientLimitBezzalog int
--alter table _request_log add clientLimitBezzalog  int

--alter table _request add thikHit int
--alter table _request_log add thikHit  int



--alter table _request     add firstLoanRbp nvarchar(50)
--alter table _request_log add firstLoanRbp nvarchar(50)

--alter table _request     add firstLoanNumber nvarchar(30)
--alter table _request_log add firstLoanNumber nvarchar(30)



--alter table _request     add checkingSla  [decimal](38, 10)
--alter table _request_log add checkingSla  [decimal](38, 10)


--alter table _request     add partnerId nvarchar(255)
--alter table _request_log add partnerId nvarchar(255)

--alter table _request     add previousRequestCreated datetime2(0)
--alter table _request_log add previousRequestCreated datetime2(0)


--alter table _request     add previousRequestStatus nvarchar(50)
--alter table _request_log add previousRequestStatus nvarchar(50)


--alter table _request     add checkingRefinementPhotoQualityPtsSts tinyint
--alter table _request_log add checkingRefinementPhotoQualityPtsSts tinyint
--alter table _request     add checkingRefinementPhotoQualityPassport tinyint
--alter table _request_log add checkingRefinementPhotoQualityPassport tinyint




--alter table _request     drop column checkingRefinementPtsSts  --tinyint
--alter table _request_log drop column checkingRefinementPtsSts  --tinyint
--alter table _request     drop column checkingRefinementPassport--tinyint
--alter table _request_log drop column checkingRefinementPassport--tinyint


--alter table _request add sourceRedefined nvarchar(100)
--alter table _request_log add sourceRedefined nvarchar(100)


--alter table _request add channelRedefined nvarchar(100)
--alter table _request_log add channelRedefined nvarchar(100)
--alter table _request add ptsType nvarchar(20)
--alter table _request_log add ptsType nvarchar(20)
--alter table _request add employmentType nvarchar(50)
--alter table _request_log add employmentType nvarchar(50)





--alter table _request add  abAddProductInsuranceDraft tinyint
--alter table _request_log add  abAddProductInsuranceDraft tinyint

 
 
--alter table _request_log add addProductInsuranceDraft               
--alter table _request_log add addProductInsuranceCall1             
--alter table _request_log add addProductInsuranceCall2         
--alter table _request_log add addProductInsuranceCall3
--alter table _request_log add addProductInsuranceFinal nvarchar(50)
--alter table _request_log add addProductInsuranceFinalSeller nvarchar(50)
--alter table _request_log add addProductInsuranceOffDesc  varchar(8000)


--alter table _request add addProductInsuranceDraft
--alter table _request add addProductInsuranceCall1
--alter table _request add addProductInsuranceCall2
--alter table _request add addProductInsuranceCall3
--alter table _request add addProductInsuranceFinal nvarchar(50)
--alter table _request add addProductInsuranceFinalSeller nvarchar(50)
--alter table _request add addProductInsuranceOffDesc  varchar(8000)
--alter table _request add eqxScoreGroupUnsecured   varchar(10)
--alter table _request_log add eqxScoreGroupUnsecured   varchar(10)

--alter table _request add InitialEndDate   date
--alter table _request_log add InitialEndDate   date



--alter table _request add assignmentCreated   date
--alter table _request_log add assignmentCreated   date




--alter table _request add scheduleTotalPay   int
--alter table _request_log add scheduleTotalPay   int



--alter table _request add totalPay   int
--alter table _request_log add totalPay   int

-------------------------------------------------------------------------
--alter table _request     add checkingSlaNet  [decimal](38, 10)
--alter table _request_log add checkingSlaNet  [decimal](38, 10)

--alter table _request     add verificationSlaNet  [decimal](38, 10)
--alter table _request_log add verificationSlaNet  [decimal](38, 10)
 
 
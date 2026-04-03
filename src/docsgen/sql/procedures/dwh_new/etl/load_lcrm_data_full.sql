--  exec  [etl].[load_lcrm_data_full]
CREATE procedure [etl].[load_lcrm_data_full]
as
begin 


   
  set nocount on
exec [log].[LogAndSendMailToAdmin] ' etl.load_lcrm_data_full','Info','procedure Started ',''

  
  
  declare @dt datetime
  --set @dt=(select max(UF_updated_AT) from staging.lcrm_tbl_full)
  set @dt=dateadd(day,-2,cast(getdate() as date))

  --select @dt
  declare @query nvarchar(max)=N''
  declare @tsql  nvarchar(max)=N''
   
   --fullTABLE
   /*
drop table if exists ##lcrm_ids

    set @query='select  ID
     from  carmoney_light_crm
       where UF_UPDATED_AT>'''''+format(@dt,'yyyy-MM-ddTHH:mm:ss')+'''''
               ' 
set @tsql='select * into ##lcrm_ids from OPENQUERY(LCRM,'''+@query+''')'
select @tsql

exec (@tsql)
     */


    delete from staging.lcrm_tbl_full where UF_UPDATED_AT>@dt

--truncate table staging.lcrm_tbl_full
     
declare @ii bigint=0
      , @prev_i bigint =-1

--set @ii=cast(isnull((select min(id) from staging.lcrm_tbl_full  where UF_UPDATED_AT>@dt ),'0') as bigint)
--set @ii=cast(isnull((select max(id) from staging.lcrm_tbl_full ),'0') as bigint)
select @ii

while @ii<>@prev_i
begin
begin try
set @prev_i=@ii
       begin tran
    set @query='select 
     c1.ID
    ,c1.UF_NAME
    ,c1.UF_PHONE
    ,c1.UF_FROM_SITE
    ,c1.UF_VIEWED
    ,c1.UF_STATUS_S1
    ,c1.UF_STATUS_S2
    ,c1.UF_REGISTERED_AT
    ,c1.UF_UPDATED_AT
    ,c1.UF_ISSUED_AT
    ,c1.UF_ROW_ID
    ,c1.UF_LEAD_ID
    ,c1.UF_SUM_LOAN
    ,c1.UF_SUM_ACCEPTED
    ,c1.UF_REJECTED_COMMENT
    ,c1.UF_REGION_NAME
    ,c1.UF_AGENT_NAME
    ,c1.UF_AGENT_TYPE
    ,c1.UF_DOC_CITY
    ,c1.UF_REGION_REF_ID
    ,c1.UF_LOAN_MONTH_COUNT
    ,c1.UF_STAT_SOURCE
    ,c1.UF_STAT_AD_TYPE
    ,c1.UF_STAT_CAMPAIGN
    ,c1.UF_STAT_DETAIL_INFO
    ,c1.UF_STAT_TERM
    ,c1.UF_STAT_SYSTEM
    ,c1.UF_STAT_FIRST_PAGE
    ,c1.UF_STAT_INT_PAGE
    ,c1.UF_STAT_CLIENT_ID_YA
    ,c1.UF_STAT_CLIENT_ID_GA
    ,c1.UF_TYPE
    ,c1.UF_MANAGER_TAXI
    ,c1.UF_CC_OPERATOR_ID
    ,c1.UF_CC_STATUS
    ,c1.UF_SOURCE
    ,c1.UF_STAT_CLICK_ID_YA
    ,c1.UF_STAT_CLICK_ID_GA
    ,c1.UF_STAT_REFERRER
    ,c1.UF_CC_DEFERRED_TO
    ,c1.UF_CC_CANCEL_ID
    ,c1.UF_CC_TYPE_ID
    ,c1.UF_CC_SOURCE_ID
    ,c1.UF_CC_DEFER_COUNT
    ,c1.UF_CC_COMMENT
    ,c1.UF_STATUS_DEB
    ,c1.UF_ACTUALIZE_AT
    ,c1.UF_LOAN_STATUS
    ,c1.UF_REASON_FOR_CANCEL
    ,c1.UF_CLT_ORG_NAME
    ,c1.UF_CLT_JOB
    ,c1.UF_CLT_PASS_CITY
    ,c1.UF_CLT_BIRTH_DAY
    ,c1.UF_CLT_MARITAL_STATE
    ,c1.UF_CLT_PASS_ID
    ,c1.UF_CLT_AVG_INCOME
    ,c1.UF_CLT_FIO
    ,c1.UF_CLT_EMAIL
    ,c1.UF_CAR_ISSUE_YEAR
    ,c1.UF_CAR_MARK
    ,c1.UF_CAR_MODEL
    ,c1.UF_CAR_COST_RUB
    ,c1.UF_PHONE_ADD
    ,c1.UF_REGION_FROM_TITLE
    ,c1.UF_COMMENT
    ,c1.UF_PRODUCT
    ,c1.UF_PARTNER_OFFICE
    ,c1.UF_COMAGIC_ID
    ,c1.UF_COMAGIC_PHONE_VRT
    ,c1.UF_CC_COMPLAINT_ID
    ,c1.UF_PARENT_ID
    ,c1.UF_COMAGIC_CAMP_ID
    ,c1.UF_CC_API_ERROR_TEXT
    ,c1.UF_CLT_NAME_FIRST
    ,c1.UF_CLT_NAME_SECOND
    ,c1.UF_CLT_NAME_LAST
    ,c1.UF_CLB_CHANNEL
    ,c1.UF_CLB_TYPE
    ,c1.UF_DOUBLICATE
    ,c1.UF_REPEAT_CUSTOMER
    ,c1.UF_PAUSED
    ,c1.UF_LOAN_CREDIT_TYPE
    ,c1.UF_PARTNER_ID
    ,c1.UF_GROUP_ID
    ,c1.UF_PRIORITY
    ,c1.UF_COMAGIC_REGION
    ,c1.UF_RARUS_ID
    ,c1.UF_RC_CALL_TYPE
    ,c1.UF_RC_CALL_SOURCE
    ,c1.UF_RC_CALL_SERVICE
    ,c1.UF_RC_CALL_RESULT
    ,c1.UF_RC_REJECT_CLIENT
    ,c1.UF_RC_REJECT_CM
    ,c1.UF_REGIONS_COMPOSITE
    ,c1.UF_CLT_FIRST_VISIT
    ,c1.UF_STAT_CID_YA_INH
    ,c1.UF_STAT_CID_GA_INH
    ,c1.UF_USER_IP
    ,c1.UF_TYPE_SHADOW
    ,c1.UF_SOURCE_SHADOW
    ,c1.UF_CLIENT_ID
    ,c1.UF_COMAGIC_DURATION
    ,c1.UF_SIM_REGION
    ,c1.UF_SIM_OPERATOR
    ,c1.UF_MFO_CREATED_IN
    ,c1.UF_MFO_CREATED_IN_SH
    ,c1.UF_DOC_CITY_NORM
    ,c1.UF_MATCH_ALGORITHM
    ,c1.UF_RO_CITY_COMPOSITE
    ,c1.UF_VISITOR_ID
    ,c1.UF_COMAGIC_VID
    ,c1.UF_IS_DUPLICATE
    ,c1.UF_RATE_PERCENT
    ,c1.UF_RATE_MAX_PERCENT
    ,c1.UF_RATE_MIN_PERCENT
    ,c1.UF_RATE_MAX_MNT_CNT
    ,c1.UF_TARIFF_OR_PRODUCT
    ,c1.UF_LOAN_PAID_AT
    ,c1.UF_LOAN_METHOD
    ,c1.UF_PARTNER_CLICK_ID
    ,c1.UF_TARGET
    ,c1.UF_OUTGOING_TYPE
    ,c1.UF_BUSINESS_VALUE
    ,c1.UF_DEFERRED
    ,c1.UF_STEP
    ,c1.UF_CLID
    ,c1.UF_ADRIVER_POST_VIEW
    ,c1.UF_APPMECA_TRACKER
    ,c1.UF_CRM_LAST_STATUS
     from  carmoney_light_crm   c1
     join     (select id from carmoney_light_crm   c2

       where 
        c2.id> '''''+format(@ii,'0')+'''''                
        and UF_UPDATED_AT>'''''+format(@dt,'yyyy-MM-ddTHH:mm:ss')+'''''
order by c2.id
limit 10000
) c2 
      on c2.id=c1.id
               ' 
set @tsql='INSERT INTO staging.lcrm_tbl_full with(tablockx)  select *  from OPENQUERY(LCRM,'''+@query+''')'
--  select @tsql

exec (@tsql)
/*
 
*/
set @ii=cast(isnull((select max(id) from staging.lcrm_tbl_full  where UF_UPDATED_AT>@dt ),'0') as bigint)
--set @ii=cast(isnull((select max(id) from staging.lcrm_tbl_full),'0') as bigint)
select @ii
commit tran


end try
begin catch
select 'catch error!'
if @@TRANCOUNT>0 commit tran
set @prev_i=-1
end catch

end

--exec [etl].[Data_Quality_lcrm]

--exec stg._lcrm.leads2dwh_postloader

exec [log].[LogAndSendMailToAdmin] ' etl.load_lcrm_data_full','Info','procedure finished',''
 
end


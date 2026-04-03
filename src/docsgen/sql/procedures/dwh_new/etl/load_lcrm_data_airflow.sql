-- exec [etl].[load_lcrm_data]
create   procedure [etl].[load_lcrm_data_airflow]
as
begin    
  set nocount on
  /*
exec [log].[LogAndSendMailToAdmin] ' etl.load_lcrm_data','Info','procedure Started ',''

  declare @i int
  
  set @i=0

  declare @dt datetime
  --set @dt=(select max(UF_REGISTERED_AT) from staging.lcrm_tbl)
  set @dt=dateadd(day,-8,cast(getdate() as date))

  --select @dt
  declare @query nvarchar(max)=N''
  declare @tsql  nvarchar(max)=N''


  delete from staging.lcrm_tbl where UF_REGISTERED_AT>@dt

  
  set @query='select  id ,
                      UF_REGISTERED_AT ,
                      UF_CLIENT_ID,
                      UF_NAME,
                      UF_PHONE ,
                      UF_ROW_ID ,
                      UF_LEAD_ID,
                      UF_SUM_LOAN ,
                      UF_CLB_CHANNEL,
                      UF_STAT_SOURCE ,
                      UF_STAT_AD_TYPE ,
                      UF_STAT_CAMPAIGN ,
                      UF_CLB_TYPE,
											UF_PRIORITY,
											UF_COMAGIC_DURATION,
											UF_ACTUALIZE_AT,
											UF_TYPE
                from  carmoney_light_crm
               where UF_REGISTERED_AT>'''''+format(@dt,'yyyy-MM-ddTHH:mm:ss')+'''''
               '
--  select @query
  set @tsql='INSERT INTO staging.lcrm_tbl with(tablock) select * from OPENQUERY(LCRM,'''+@query+''')'
--  select @tsql
  while @i<3 --количество попыток
    begin 
      begin try
        exec (@tsql)
        set @i=3
      end try
      begin catch
      select 'error'
        select @i
        set @i=@i+1
        WAITFOR DELAY '00:01';  -- задержка в одну минуту
      end catch
    end--while
    */
   /*
   --fullTABLE

     delete from staging.lcrm_tbl_full where UF_REGISTERED_AT>@dt
    set @query='select 
     ID
    ,UF_NAME
    ,UF_PHONE
    ,UF_FROM_SITE
    ,UF_VIEWED
    ,UF_STATUS_S1
    ,UF_STATUS_S2
    ,UF_REGISTERED_AT
    ,UF_UPDATED_AT
    ,UF_ISSUED_AT
    ,UF_ROW_ID
    ,UF_LEAD_ID
    ,UF_SUM_LOAN
    ,UF_SUM_ACCEPTED
    ,UF_REJECTED_COMMENT
    ,UF_REGION_NAME
    ,UF_AGENT_NAME
    ,UF_AGENT_TYPE
    ,UF_DOC_CITY
    ,UF_REGION_REF_ID
    ,UF_LOAN_MONTH_COUNT
    ,UF_STAT_SOURCE
    ,UF_STAT_AD_TYPE
    ,UF_STAT_CAMPAIGN
    ,UF_STAT_DETAIL_INFO
    ,UF_STAT_TERM
    ,UF_STAT_SYSTEM
    ,UF_STAT_FIRST_PAGE
    ,UF_STAT_INT_PAGE
    ,UF_STAT_CLIENT_ID_YA
    ,UF_STAT_CLIENT_ID_GA
    ,UF_TYPE
    ,UF_MANAGER_TAXI
    ,UF_CC_OPERATOR_ID
    ,UF_CC_STATUS
    ,UF_SOURCE
    ,UF_STAT_CLICK_ID_YA
    ,UF_STAT_CLICK_ID_GA
    ,UF_STAT_REFERRER
    ,UF_CC_DEFERRED_TO
    ,UF_CC_CANCEL_ID
    ,UF_CC_TYPE_ID
    ,UF_CC_SOURCE_ID
    ,UF_CC_DEFER_COUNT
    ,UF_CC_COMMENT
    ,UF_STATUS_DEB
    ,UF_ACTUALIZE_AT
    ,UF_LOAN_STATUS
    ,UF_REASON_FOR_CANCEL
    ,UF_CLT_ORG_NAME
    ,UF_CLT_JOB
    ,UF_CLT_PASS_CITY
    ,UF_CLT_BIRTH_DAY
    ,UF_CLT_MARITAL_STATE
    ,UF_CLT_PASS_ID
    ,UF_CLT_AVG_INCOME
    ,UF_CLT_FIO
    ,UF_CLT_EMAIL
    ,UF_CAR_ISSUE_YEAR
    ,UF_CAR_MARK
    ,UF_CAR_MODEL
    ,UF_CAR_COST_RUB
    ,UF_PHONE_ADD
    ,UF_REGION_FROM_TITLE
    ,UF_COMMENT
    ,UF_PRODUCT
    ,UF_PARTNER_OFFICE
    ,UF_COMAGIC_ID
    ,UF_COMAGIC_PHONE_VRT
    ,UF_CC_COMPLAINT_ID
    ,UF_PARENT_ID
    ,UF_COMAGIC_CAMP_ID
    ,UF_CC_API_ERROR_TEXT
    ,UF_CLT_NAME_FIRST
    ,UF_CLT_NAME_SECOND
    ,UF_CLT_NAME_LAST
    ,UF_CLB_CHANNEL
    ,UF_CLB_TYPE
    ,UF_DOUBLICATE
    ,UF_REPEAT_CUSTOMER
    ,UF_PAUSED
    ,UF_LOAN_CREDIT_TYPE
    ,UF_PARTNER_ID
    ,UF_GROUP_ID
    ,UF_PRIORITY
    ,UF_COMAGIC_REGION
    ,UF_RARUS_ID
    ,UF_RC_CALL_TYPE
    ,UF_RC_CALL_SOURCE
    ,UF_RC_CALL_SERVICE
    ,UF_RC_CALL_RESULT
    ,UF_RC_REJECT_CLIENT
    ,UF_RC_REJECT_CM
    ,UF_REGIONS_COMPOSITE
    ,UF_CLT_FIRST_VISIT
    ,UF_STAT_CID_YA_INH
    ,UF_STAT_CID_GA_INH
    ,UF_USER_IP
    ,UF_TYPE_SHADOW
    ,UF_SOURCE_SHADOW
    ,UF_CLIENT_ID
    ,UF_COMAGIC_DURATION
    ,UF_SIM_REGION
    ,UF_SIM_OPERATOR
    ,UF_MFO_CREATED_IN
    ,UF_MFO_CREATED_IN_SH
    ,UF_DOC_CITY_NORM
    ,UF_MATCH_ALGORITHM
    ,UF_RO_CITY_COMPOSITE
    ,UF_VISITOR_ID
    ,UF_COMAGIC_VID
    ,UF_IS_DUPLICATE
    ,UF_RATE_PERCENT
    ,UF_RATE_MAX_PERCENT
    ,UF_RATE_MIN_PERCENT
    ,UF_RATE_MAX_MNT_CNT
    ,UF_TARIFF_OR_PRODUCT
    ,UF_LOAN_PAID_AT
    ,UF_LOAN_METHOD
    ,UF_PARTNER_CLICK_ID
    ,UF_TARGET
    ,UF_OUTGOING_TYPE
    ,UF_BUSINESS_VALUE
    ,UF_DEFERRED
    ,UF_STEP
    ,UF_CLID
    ,UF_ADRIVER_POST_VIEW
    ,UF_APPMECA_TRACKER
    ,UF_CRM_LAST_STATUS
     from  carmoney_light_crm
       where UF_REGISTERED_AT>'''''+format(@dt,'yyyy-MM-ddTHH:mm:ss')+'''''
               

               ' 
set @tsql='INSERT INTO staging.lcrm_tbl_full with(tablock)  select *  from OPENQUERY(LCRM,'''+@query+''')'
--  select @tsql

exec (@tsql)

*/




exec [log].[LogAndSendMailToAdmin] ' etl.load_lcrm_data','Info','procedure finished',''
  /*

  while @i<3 --количество попыток
    begin 
          begin try
         

    truncate table staging.lcrm_tbl
    
    INSERT INTO staging.lcrm_tbl
	  --original
      --select * from OPENQUERY(LCRM,'select  id ,
      --                                      UF_REGISTERED_AT ,
      --                                      UF_CLIENT_ID,
      --                                      UF_NAME,
      --                                      UF_PHONE ,
      --                                      UF_ROW_ID ,
      --                                      UF_LEAD_ID,
      --                                      UF_SUM_LOAN ,
      --                                      UF_CLB_CHANNEL,
      --                                      UF_STAT_SOURCE ,
      --                                      UF_STAT_AD_TYPE ,
      --                                      UF_STAT_CAMPAIGN ,
      --                                      UF_CLB_TYPE
      --                                from  carmoney_light_crm
      --                             '
      --                      )

	  -- turabov 230419
	  --alter table  staging.lcrm_tbl add [UF_PRIORITY] int, [UF_COMAGIC_DURATION] int, [UF_ACTUALIZE_AT] datetime2(7)
	  --alter table  staging.lcrm_tbl add UF_TYPE ntext
	        select * from OPENQUERY(LCRM,'select  id ,
                                            UF_REGISTERED_AT ,
                                            UF_CLIENT_ID,
                                            UF_NAME,
                                            UF_PHONE ,
                                            UF_ROW_ID ,
                                            UF_LEAD_ID,
                                            UF_SUM_LOAN ,
                                            UF_CLB_CHANNEL,
                                            UF_STAT_SOURCE ,
                                            UF_STAT_AD_TYPE ,
                                            UF_STAT_CAMPAIGN ,
                                            UF_CLB_TYPE,
											UF_PRIORITY,
											UF_COMAGIC_DURATION,
											UF_ACTUALIZE_AT,
											UF_TYPE
                                      from  carmoney_light_crm
                                   '
                            )




   
            set @i=3
          end try

          begin catch
           
            select @i
            set @i=@i+1
            -- задержка в одну минуту
            WAITFOR DELAY '00:01';  

          end catch

    end
    */
end


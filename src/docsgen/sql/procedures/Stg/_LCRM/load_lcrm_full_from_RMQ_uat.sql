-- Usage: запуск процедуры с параметрами
-- EXEC [_LCRM].[load_lcrm_full_from_RMQ_uat] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [_LCRM].[load_lcrm_full_from_RMQ_uat]
	@mode int = 0
	,@debug bit = 1
as 
begin try
	
    DECLARE @StartDate datetime, @row_count int
	DECLARE @text varchar(max)

	SET @mode = isnull(@mode,1)
		-- из stg таблицы
	DECLARE @dt datetime = getdate()

	-- утром грузим с вечера 
	IF @mode = 0
	BEGIN
		SELECT @dt = dateadd(HOUR, 21, cast(dateadd(DAY,-1,cast(@dt AS date)) AS datetime2) ) 
		SELECT @dt

		--SELECT @text= '_LCRM.load_lcrm_full_from_RMQ @mode = 0. Started at :  '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		--EXEC [LogDb].[dbo].[SendToSlack_lcrm-backup-restore-dwh-monitoring] @text
	END

	--if ( datepart(hour,getdate()) > 6)
	IF @mode = 1
	BEGIN
		SELECT @dt= dateadd(MINUTE, -10, isnull(max(receivedate),@dt))  FROM _LCRM.RMQ_Read_Logs
		WHERE queue_name = 'CSV'
		SELECT @dt
	END 

		
	IF object_id('tempdb.dbo.#rmq') IS NOT NULL
		DROP TABLE #rmq

	SELECT
		ReceiveDate
		,ReceivedMessage	
		,guid_id
		INTO #rmq
	--FROM [RMQ].[ReceivedMessages] RM WITH(NOLOCK)
	FROM RMQ.ReceivedMessages_LCRM_LeadRows_uat RM WITH(NOLOCK)
	WHERE RM.[ReceiveDate] >= @dt 
		  AND FromQueue = 'dwh.LCRM.LeadData.1.1'
		  and isDeleted = 0
	
	drop table if exists #rmq_data
	select top(0) 
		--  ReceivedMessages_guid_id =  newid()
		--, message_guid = newid()
		--, publishTime_utc = GETUTCDATE()
		--, eventType = cast(null as nvarchar(36))
		 [ID]
		, [UF_NAME]
		, [UF_PHONE]
		, [UF_REGISTERED_AT]
		, [UF_UPDATED_AT]
		, [UF_ROW_ID]
		, [UF_AGENT_NAME]
		, [UF_STAT_CAMPAIGN]
		, [UF_STAT_CLIENT_ID_YA]
		, [UF_STAT_CLIENT_ID_GA]
		, [UF_TYPE]
		, [UF_SOURCE]
		, [UF_STAT_AD_TYPE]
		, [UF_ACTUALIZE_AT]
		, [UF_CAR_MARK]
		, [UF_CAR_MODEL]
		, [UF_PHONE_ADD]
		, [UF_PARENT_ID]
		, [UF_GROUP_ID]
		, [UF_PRIORITY]
		, [UF_RC_REJECT_CM]
		, [UF_APPMECA_TRACKER]
		, [UF_LOGINOM_CHANNEL]
		, [UF_LOGINOM_GROUP]
		, [UF_LOGINOM_PRIORITY]
		, [UF_LOGINOM_STATUS]
		, [UF_LOGINOM_DECLINE]
		, [UF_STAT_SOURCE]
		, [UF_FROM_SITE]
		, [UF_VIEWED]
		, [UF_PARTNER_ID]
		, [UF_SUM_ACCEPTED]
		, [UF_SUM_LOAN]
		, [UF_REGIONS_COMPOSITE]
		, [UF_ISSUED_AT]
		, [UF_TARGET]
		, [UF_FULL_FORM_LEAD]
		, [UF_STEP]
		, [UF_SOURCE_SHADOW]
		, [UF_TYPE_SHADOW]
		, [UF_CLB_TYPE]
		, [UF_CLID]
		, [UF_MATCH_ALGORITHM]
		, [UF_CLB_CHANNEL]
		, [UF_LOAN_MONTH_COUNT]
		, [UF_STAT_SYSTEM]
		, [UF_STAT_DETAIL_INFO]
		, [UF_STAT_TERM]
		, [UF_STAT_FIRST_PAGE]
		, [UF_STAT_INT_PAGE]
		, [UF_CLT_NAME_FIRST]
		, [UF_CLT_BIRTH_DAY]
		, [UF_CLT_EMAIL]
		, [UF_CLT_AVG_INCOME]
		, [UF_CAR_COST_RUB]
		, [UF_CAR_ISSUE_YEAR]
		, [UF_CLIENT_ID]
	into #rmq_data
	from [_LCRM].[lcrm_leads_full_uat] t
	
	insert into #rmq_data
		(
		--  ReceivedMessages_guid_id
		--, message_guid
		--, publishTime_utc
		--, eventType
		 [ID]
		, [UF_NAME]
		, [UF_PHONE]
		, [UF_REGISTERED_AT]
		, [UF_UPDATED_AT]
		, [UF_ROW_ID]
		, [UF_AGENT_NAME]
		, [UF_STAT_CAMPAIGN]
		, [UF_STAT_CLIENT_ID_YA]
		, [UF_STAT_CLIENT_ID_GA]
		, [UF_TYPE]
		, [UF_SOURCE]
		, [UF_STAT_AD_TYPE]
		, [UF_ACTUALIZE_AT]
		, [UF_CAR_MARK]
		, [UF_CAR_MODEL]
		, [UF_PHONE_ADD]
		, [UF_PARENT_ID]
		, [UF_GROUP_ID]
		, [UF_PRIORITY]
		, [UF_RC_REJECT_CM]
		, [UF_APPMECA_TRACKER]
		, [UF_LOGINOM_CHANNEL]
		, [UF_LOGINOM_GROUP]
		, [UF_LOGINOM_PRIORITY]
		, [UF_LOGINOM_STATUS]
		, [UF_LOGINOM_DECLINE]
		, [UF_STAT_SOURCE]
		, [UF_FROM_SITE]
		, [UF_VIEWED]
		, [UF_PARTNER_ID]
		, [UF_SUM_ACCEPTED]
		, [UF_SUM_LOAN]
		, [UF_REGIONS_COMPOSITE]
		, [UF_ISSUED_AT]
		, [UF_TARGET]
		, [UF_FULL_FORM_LEAD]
		, [UF_STEP]
		, [UF_SOURCE_SHADOW]
		, [UF_TYPE_SHADOW]
		, [UF_CLB_TYPE]
		, [UF_CLID]
		, [UF_MATCH_ALGORITHM]
		, [UF_CLB_CHANNEL]
		, [UF_LOAN_MONTH_COUNT]
		, [UF_STAT_SYSTEM]
		, [UF_STAT_DETAIL_INFO]
		, [UF_STAT_TERM]
		, [UF_STAT_FIRST_PAGE]
		, [UF_STAT_INT_PAGE]
		, [UF_CLT_NAME_FIRST]
		, [UF_CLT_BIRTH_DAY]
		, [UF_CLT_EMAIL]
		, [UF_CLT_AVG_INCOME]
		, [UF_CAR_COST_RUB]
		, [UF_CAR_ISSUE_YEAR]
		, [UF_CLIENT_ID]
		)
	select --ReceivedMessages_guid_id = guid_id
			--,t_meta.message_guid
			--,publishTime_utc = DATEADD(s, t_meta.publishTime, '1970-01-01')
			--,eventType  =t_data.[event]
			 t_data.[ID]
			, t_data.[UF_NAME]
			, t_data.[UF_PHONE]
			, t_data.[UF_REGISTERED_AT]
			, t_data.[UF_UPDATED_AT]
			, t_data.[UF_ROW_ID]
			, t_data.[UF_AGENT_NAME]
			, t_data.[UF_STAT_CAMPAIGN]
			, t_data.[UF_STAT_CLIENT_ID_YA]
			, t_data.[UF_STAT_CLIENT_ID_GA]
			, t_data.[UF_TYPE]
			, t_data.[UF_SOURCE]
			, t_data.[UF_STAT_AD_TYPE]
			, t_data.[UF_ACTUALIZE_AT]
			, t_data.[UF_CAR_MARK]
			, t_data.[UF_CAR_MODEL]
			, t_data.[UF_PHONE_ADD]
			, t_data.[UF_PARENT_ID]
			, t_data.[UF_GROUP_ID]
			, t_data.[UF_PRIORITY]
			, t_data.[UF_RC_REJECT_CM]
			, t_data.[UF_APPMECA_TRACKER]
			, t_data.[UF_LOGINOM_CHANNEL]
			, t_data.[UF_LOGINOM_GROUP]
			, t_data.[UF_LOGINOM_PRIORITY]
			, t_data.[UF_LOGINOM_STATUS]
			, t_data.[UF_LOGINOM_DECLINE]
			, t_data.[UF_STAT_SOURCE]
			, t_data.[UF_FROM_SITE]
			, t_data.[UF_VIEWED]
			, t_data.[UF_PARTNER_ID]
			, t_data.[UF_SUM_ACCEPTED]
			, t_data.[UF_SUM_LOAN]
			, t_data.[UF_REGIONS_COMPOSITE]
			, t_data.[UF_ISSUED_AT]
			, t_data.[UF_TARGET]
			, t_data.[UF_FULL_FORM_LEAD]
			, t_data.[UF_STEP]
			, t_data.[UF_SOURCE_SHADOW]
			, t_data.[UF_TYPE_SHADOW]
			, t_data.[UF_CLB_TYPE]
			, t_data.[UF_CLID]
			, t_data.[UF_MATCH_ALGORITHM]
			, t_data.[UF_CLB_CHANNEL]
			, t_data.[UF_LOAN_MONTH_COUNT]
			, t_data.[UF_STAT_SYSTEM]
			, t_data.[UF_STAT_DETAIL_INFO]
			, t_data.[UF_STAT_TERM]
			, t_data.[UF_STAT_FIRST_PAGE]
			, t_data.[UF_STAT_INT_PAGE]
			, t_data.[UF_CLT_NAME_FIRST]
			, t_data.[UF_CLT_BIRTH_DAY]
			, t_data.[UF_CLT_EMAIL]
			, t_data.[UF_CLT_AVG_INCOME]
			, t_data.[UF_CAR_COST_RUB]
			, t_data.[UF_CAR_ISSUE_YEAR]
			, t_data.[UF_CLIENT_ID]
			--Этих полей нет в DWH
			-- ,t_data.UF_FEDOR_ID
			--,t_data.UF_VISITOR_ID
			--,t_data.UF_BUSINESS_VALUE
            --,t_data.UF_IS_DUPLICATE
			--,t_data.UF_PARKING_FLAG
			--,t_data.UF_CLT_FIRST_VISIT
			--,t_data.UF_MFO_CREATED_IN
			--,t_data.UF_MFO_CREATED_IN_SH
			--,t_data.UF_PARTNER_CLICK_ID
			--,t_data.UF_MANAGER_TAXI
			--,t_data.UF_SOLD_OUT
			--,t_data.UF_JUSTLOMB_ID
			--,t_data.UF_JUSTLOMB_STATUS
			--,t_data.UF_JUSTLOMB_AMOUNT
			--,t_data.UF_LEADGID_ID
			--,t_data.UF_LEADGID_STATUS
			--,t_data.UF_CALLCASE_UUID
			--,t_data.UF_CALLCASE_RESULT
			--,t_data.UF_CALLCASE_COUNT
			--,t_data.UF_LEAD_STATUS
			--,t_data.UF_LEAD_REJECT_RSN
			--,t_data.UF_STATUS_S1
			--,t_data.UF_STATUS_S2
			--,t_data.UF_TARIFF_OR_PRODUCT
			--,t_data.UF_LOAN_PAID_AT
			
			--,t_data.UF_LOAN_CREDIT_TYPE
			--,t_data.UF_REPEAT_CUSTOMER
			--,t_data.UF_PRODUCT
			--,t_data.UF_REJECTED_COMMENT
			--,t_data.UF_ADRIVER_POST_VIEW
			--,t_data.UF_STAT_REFERRER
			--,t_data.UF_STAT_CID_YA_INH
			--,t_data.UF_STAT_CID_GA_INH
			--,t_data.UF_STAT_CLICK_ID_YA
			--,t_data.UF_STAT_CLICK_ID_GA
			--,t_data.UF_REGION_NAME
			--,t_data.UF_REGION_FROM_TITLE
			--,t_data.UF_COMAGIC_REGION
			--,t_data.UF_REGION_REF_ID
			--,t_data.UF_SIM_REGION
			--,t_data.UF_DOC_CITY
			--,t_data.UF_DOC_CITY_NORM
            --,t_data.UF_COMAGIC_ID
            --,t_data.UF_COMAGIC_VID
            --,t_data.UF_COMAGIC_PHONE_VRT
			--,t_data.UF_COMAGIC_CAMP_ID
			--,t_data.UF_COMAGIC_DURATION
			--,t_data.UF_RC_REJECT_CLIENT
			--,t_data.UF_CRM_LAST_STATUS
			--,t_data.UF_AGENT_TYPE
			--,t_data.UF_PARTNER_OFFICE
			--,t_data.UF_CLT_PASS_ID
			--,t_data.UF_CLT_PASS_CITY
			--,t_data.UF_CLT_NAME_SECOND
			--,t_data.UF_CLT_NAME_LAST
			--,t_data.UF_CLT_FIO
			--,t_data.UF_CLT_JOB
			--,t_data.UF_CLT_ORG_NAME
			--,t_data.UF_CLT_MARITAL_STATE
			--,t_data.UF_COMMENT
		    --,t_data.UF_OUTGOING_TYPE
			--,t_data.UF_DEFERRED      
	from #rmq t
	--outer apply OPENJSON(t.ReceivedMessage, '$.meta')
	--	with (
	--	message_guid nvarchar(128) '$.guid'
	--	,publishTime bigint '$.time.publish'
	--	) t_meta
	outer apply OPENJSON(t.ReceivedMessage, '$.data')
	with (
			[id]					bigint '$.id' 
			,[event]				nvarchar(128)	'$.event'
			,UF_NAME				varchar(512)	'$.attributes.UF_NAME'		
			,UF_PHONE				varchar(128)	'$.attributes.UF_PHONE'
			,UF_REGISTERED_AT		datetime2(1)	'$.attributes.UF_REGISTERED_AT'
			,UF_UPDATED_AT			datetime2(1)	'$.attributes.UF_UPDATED_AT'
			,UF_ROW_ID				varchar(128)	'$.attributes.UF_ROW_ID'
			,UF_AGENT_NAME			varchar(128)	'$.attributes.UF_AGENT_NAME'
			,UF_STAT_CAMPAIGN		varchar(512)	'$.attributes.UF_STAT_CAMPAIGN'
			,UF_STAT_CLIENT_ID_YA	varchar(128)	'$.attributes.UF_STAT_CLIENT_ID_YA'
			,UF_STAT_CLIENT_ID_GA	varchar(128)	'$.attributes.UF_STAT_CLIENT_ID_GA'
			,UF_TYPE				varchar(128)	'$.attributes.UF_TYPE'
			,UF_SOURCE				varchar(128)	'$.attributes.UF_SOURCE'
			,UF_STAT_AD_TYPE		varchar(128)	'$.attributes.UF_STAT_AD_TYPE'
			,UF_ACTUALIZE_AT		datetime2(1)	'$.attributes.UF_ACTUALIZE_AT'
			,UF_CAR_MARK			varchar(128)	'$.attributes.UF_CAR_MARK'
			,UF_CAR_MODEL			varchar(128)	'$.attributes.UF_CAR_MODEL'
			,UF_PHONE_ADD			varchar(128)	'$.attributes.UF_PHONE_ADD'
			,UF_PARENT_ID			int				'$.attributes.UF_PARENT_ID'
			,UF_GROUP_ID			varchar(128)	'$.attributes.UF_GROUP_ID'
			,UF_PRIORITY			int				'$.attributes.UF_PRIORITY'
			,UF_RC_REJECT_CM		varchar(512)	'$.attributes.UF_RC_REJECT_CM'
			,UF_APPMECA_TRACKER		varchar(128)	'$.attributes.UF_APPMECA_TRACKER'
			,UF_LOGINOM_CHANNEL		varchar(128)	'$.attributes.UF_LOGINOM_CHANNEL'
			,UF_LOGINOM_GROUP		varchar(128)	'$.attributes.UF_LOGINOM_GROUP'
			,UF_LOGINOM_PRIORITY	int				'$.attributes.UF_LOGINOM_PRIORITY'
			,UF_LOGINOM_STATUS		varchar(128)	'$.attributes.UF_LOGINOM_STATUS'
			,UF_LOGINOM_DECLINE		varchar(128)	'$.attributes.UF_LOGINOM_DECLINE'
			,UF_STAT_SOURCE			varchar(128)	'$.attributes.UF_STAT_SOURCE'
			,UF_FROM_SITE			bit				'$.attributes.UF_FROM_SITE'
			,UF_VIEWED				bit				'$.attributes.UF_VIEWED'
			,UF_PARTNER_ID			nvarchar(256)	'$.attributes.UF_PARTNER_ID'
			,UF_SUM_ACCEPTED		float			'$.attributes.UF_SUM_ACCEPTED'
			,UF_SUM_LOAN			float			'$.attributes.UF_SUM_LOAN'
			,UF_REGIONS_COMPOSITE	nvarchar(256)	'$.attributes.UF_REGIONS_COMPOSITE'
			,UF_ISSUED_AT			datetime2(1)	'$.attributes.UF_ISSUED_AT'
			,UF_TARGET				int				'$.attributes.UF_TARGET'
			,UF_FULL_FORM_LEAD		bit				'$.attributes.UF_FULL_FORM_LEAD'
			,UF_STEP				int				'$.attributes.UF_STEP'
			,UF_SOURCE_SHADOW		nvarchar(256)	'$.attributes.UF_SOURCE_SHADOW'
			,UF_TYPE_SHADOW			nvarchar(256)	'$.attributes.UF_TYPE_SHADOW'
			,UF_CLB_TYPE			nvarchar(256)	'$.attributes.UF_CLB_TYPE'
			,UF_CLID				nvarchar(144)	'$.attributes.UF_CLID'
			,UF_MATCH_ALGORITHM		nvarchar(256)	'$.attributes.UF_MATCH_ALGORITHM'
			,UF_CLB_CHANNEL			nvarchar(100)	'$.attributes.UF_CLB_CHANNEL'
			,UF_LOAN_MONTH_COUNT	int				'$.attributes.UF_LOAN_MONTH_COUNT'
			,UF_STAT_SYSTEM			nvarchar(32)	'$.attributes.UF_STAT_SYSTEM'
			,UF_STAT_DETAIL_INFO	nvarchar(2472)	'$.attributes.UF_STAT_DETAIL_INFO'
			,UF_STAT_TERM			nvarchar(2140)	'$.attributes.UF_STAT_TERM'
			,UF_STAT_FIRST_PAGE		nvarchar(max)	'$.attributes.UF_STAT_FIRST_PAGE'
			,UF_STAT_INT_PAGE		nvarchar(2536)	'$.attributes.UF_STAT_INT_PAGE'
			,UF_CLT_NAME_FIRST		nvarchar(256)	'$.attributes.UF_CLT_NAME_FIRST'
			,UF_CLT_BIRTH_DAY		date			'$.attributes.UF_CLT_BIRTH_DAY'
			,UF_CLT_EMAIL			nvarchar(256)	'$.attributes.UF_CLT_EMAIL'
			,UF_CLT_AVG_INCOME		int				'$.attributes.UF_CLT_AVG_INCOME'
			,UF_CAR_COST_RUB		int				'$.attributes.UF_CAR_COST_RUB'
			,UF_CAR_ISSUE_YEAR		float			'$.attributes.UF_CAR_ISSUE_YEAR'
			,UF_CLIENT_ID			nvarchar(510)	'$.attributes.UF_CLIENT_ID'
		) t_data					 

	
	create clustered index cix_id on #rmq_data(id)
	;with cte as (
			select 
			nRow = ROW_NUMBER() over(partition by Id order by UF_UPDATED_AT desc)
			, t.*
			from #rmq_data t
	
		)
	delete from cte
	where nRow>1

	select count(1) from #rmq_data
	--create index ix_ReceivedMessages_guid_id on #rmq_data(ReceivedMessages_guid_id)

	--select * from #rmq_data
	--where [eventType] = 'onCreated'

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch

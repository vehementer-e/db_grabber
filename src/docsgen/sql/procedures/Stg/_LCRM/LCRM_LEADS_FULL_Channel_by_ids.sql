-- =======================================================
-- Modified: 14.02.2022. А.Никитин
-- Description:	DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
-- =======================================================
CREATE PROC _LCRM.LCRM_LEADS_FULL_Channel_by_ids
	@Debug int = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ID_List_table_name varchar(100) = NULL, -- название врем. табл. с о списком ID
	@PartitionId int = NULL, -- id секции
	@Insert_Into_lcrm_leads_full int = 0 -- 1 - добавление записей в _LCRM.lcrm_leads_full	@Debug
AS
BEGIN
	SET XACT_ABORT ON
	SET NOCOUNT ON

    DECLARE @StartDate datetime, @row_count int
	DECLARE @Sql varchar(MAX)

	SELECT @Debug = isnull(@Debug, 0)
	SELECT @Insert_Into_lcrm_leads_full = isnull(@Insert_Into_lcrm_leads_full, 0)

	-- LCRM load leads started log
	EXEC _LCRM.LCRMLeads_logging 
		@action = 0,
		@message = 'LCRM calculate leads started',
		@process = 'Started calculate LCRM leads stg'

	DROP TABLE IF EXISTS #tmp2BE338B9_lcrm_leads_channel

	CREATE TABLE #tmp2BE338B9_lcrm_leads_channel(
		ID numeric(10, 0) NULL,
		DWHInsertedDate datetime NOT NULL, -- timestamp начала импорта из источника
		-- поля для расчета вычисляемых полей и для заполнения таблицы lcrm_leads_full_channel_request
		UF_NAME varchar (512) NULL,
		UF_PHONE varchar (128) NULL,
		UF_REGISTERED_AT datetime2 NULL,
		UF_UPDATED_AT datetime2 NULL,
		UF_ROW_ID varchar (128) NULL,
		UF_AGENT_NAME varchar (128) NULL,
		UF_STAT_CAMPAIGN varchar (512) NULL,
		UF_STAT_CLIENT_ID_YA varchar (128) NULL,
		UF_STAT_CLIENT_ID_GA varchar (128) NULL,
		UF_TYPE varchar (128) NULL,
		UF_SOURCE varchar (128) NULL,
		UF_STAT_AD_TYPE varchar (128) NULL,
		UF_ACTUALIZE_AT datetime2 NULL,
		UF_CAR_MARK varchar (128) NULL,
		UF_CAR_MODEL varchar (128) NULL,
		UF_PHONE_ADD varchar (128) NULL,
		UF_PARENT_ID int NULL,
		UF_GROUP_ID varchar (128) NULL,
		UF_PRIORITY int NULL,
		UF_RC_REJECT_CM varchar (512) NULL,
		UF_APPMECA_TRACKER varchar (128) NULL,
		UF_LOGINOM_CHANNEL varchar (128) NULL,
		UF_LOGINOM_GROUP varchar (128) NULL,
		UF_LOGINOM_PRIORITY int NULL,
		UF_LOGINOM_STATUS varchar (128) NULL,
		UF_LOGINOM_DECLINE varchar (128) NULL,
		UF_CLID nvarchar (72) NULL,
		UF_MATCH_ALGORITHM nvarchar (26) NULL,
		UF_CLB_CHANNEL nvarchar (50) NULL,
		UF_LOAN_MONTH_COUNT int NULL,
		UF_STAT_SYSTEM nvarchar (16) NULL,
		UF_STAT_DETAIL_INFO nvarchar (1236) NULL,
		UF_STAT_TERM nvarchar (1070) NULL,
		UF_STAT_FIRST_PAGE nvarchar (2032) NULL,
		UF_STAT_INT_PAGE nvarchar (1268) NULL,
		UF_CLT_NAME_FIRST nvarchar (128) NULL,
		UF_CLT_BIRTH_DAY date NULL,
		UF_CLT_EMAIL nvarchar (60) NULL,
		UF_CLT_AVG_INCOME int NULL,
		UF_CAR_COST_RUB int NULL,
		UF_CAR_ISSUE_YEAR float NULL,
		--
		UF_STAT_SOURCE varchar(128) NULL,
		--
		UF_FROM_SITE int NULL,
		UF_VIEWED int NULL,
		UF_PARTNER_ID nvarchar (256) NULL,
		UF_SUM_ACCEPTED float NULL,
		UF_SUM_LOAN float NULL,
		UF_REGIONS_COMPOSITE nvarchar (128) NULL,
		UF_ISSUED_AT datetime2 NULL,
		UF_TARGET int NULL,
		UF_FULL_FORM_LEAD int NULL,
		UF_STEP int NULL,
		UF_SOURCE_SHADOW nvarchar (128) NULL,
		UF_TYPE_SHADOW nvarchar (128) NULL,
		UF_CLB_TYPE nvarchar (128) NULL,
		UF_CLIENT_ID nvarchar (128) NULL
	)
	--CREATE CLUSTERED COLUMNSTORE INDEX CS_IX ON #tmp2BE338B9_lcrm_leads_channel

	CREATE TABLE #ID_List(ID numeric(10, 0) NULL)

	--передано название врем. табл. со списком ID
	IF @ID_List_table_name IS NOT NULL
	BEGIN
		SELECT @Sql = 'INSERT #ID_List(ID) SELECT DISTINCT ID FROM ' + @ID_List_table_name
		EXEC(@Sql)
		CREATE UNIQUE NONCLUSTERED INDEX [id] ON #ID_List(ID)
	END


	SELECT @StartDate = getdate(), @row_count = 0

	IF @ID_List_table_name IS NULL
	BEGIN
		INSERT #tmp2BE338B9_lcrm_leads_channel
		WITH(TABLOCKX) 
		(
			ID,
			DWHInsertedDate,
			--
			UF_NAME,
			UF_PHONE,
			UF_REGISTERED_AT,
			UF_UPDATED_AT,
			UF_ROW_ID,
			UF_AGENT_NAME,
			UF_STAT_CAMPAIGN,
			UF_STAT_CLIENT_ID_YA,
			UF_STAT_CLIENT_ID_GA,
			UF_TYPE,
			UF_SOURCE,
			UF_STAT_AD_TYPE,
			UF_ACTUALIZE_AT,
			UF_CAR_MARK,
			UF_CAR_MODEL,
			UF_PHONE_ADD,
			UF_PARENT_ID,
			UF_GROUP_ID,
			UF_PRIORITY,
			UF_RC_REJECT_CM,
			UF_APPMECA_TRACKER,
			UF_LOGINOM_CHANNEL,
			UF_LOGINOM_GROUP,
			UF_LOGINOM_PRIORITY,
			UF_LOGINOM_STATUS,
			UF_LOGINOM_DECLINE,
			UF_CLID,
			UF_MATCH_ALGORITHM,
			UF_CLB_CHANNEL,
			UF_LOAN_MONTH_COUNT,
			UF_STAT_SYSTEM,
			UF_STAT_DETAIL_INFO,
			UF_STAT_TERM,
			UF_STAT_FIRST_PAGE,
			UF_STAT_INT_PAGE,
			UF_CLT_NAME_FIRST,
			UF_CLT_BIRTH_DAY,
			UF_CLT_EMAIL,
			UF_CLT_AVG_INCOME,
			UF_CAR_COST_RUB,
			UF_CAR_ISSUE_YEAR,
			UF_STAT_SOURCE,
			--
			UF_FROM_SITE,
			UF_VIEWED,
			UF_PARTNER_ID,
			UF_SUM_ACCEPTED,
			UF_SUM_LOAN,
			UF_REGIONS_COMPOSITE,
			UF_ISSUED_AT,
			UF_TARGET,
			UF_FULL_FORM_LEAD,
			UF_STEP,
			UF_SOURCE_SHADOW,
			UF_TYPE_SHADOW,
			UF_CLB_TYPE,
			UF_CLIENT_ID
		)
		SELECT 
			T.ID,
			DWHInsertedDate = getdate(),
			--
			T.UF_NAME,
			T.UF_PHONE,
			T.UF_REGISTERED_AT,
			T.UF_UPDATED_AT,
			T.UF_ROW_ID,
			T.UF_AGENT_NAME,
			T.UF_STAT_CAMPAIGN,
			T.UF_STAT_CLIENT_ID_YA,
			T.UF_STAT_CLIENT_ID_GA,
			T.UF_TYPE,
			T.UF_SOURCE,
			T.UF_STAT_AD_TYPE,
			T.UF_ACTUALIZE_AT,
			T.UF_CAR_MARK,
			T.UF_CAR_MODEL,
			T.UF_PHONE_ADD,
			T.UF_PARENT_ID,
			T.UF_GROUP_ID,
			T.UF_PRIORITY,
			T.UF_RC_REJECT_CM,
			T.UF_APPMECA_TRACKER,
			T.UF_LOGINOM_CHANNEL,
			T.UF_LOGINOM_GROUP,
			T.UF_LOGINOM_PRIORITY,
			T.UF_LOGINOM_STATUS,
			T.UF_LOGINOM_DECLINE,
			T.UF_CLID,
			T.UF_MATCH_ALGORITHM,
			T.UF_CLB_CHANNEL,
			T.UF_LOAN_MONTH_COUNT,
			T.UF_STAT_SYSTEM,
			T.UF_STAT_DETAIL_INFO,
			T.UF_STAT_TERM,
			T.UF_STAT_FIRST_PAGE,
			T.UF_STAT_INT_PAGE,
			T.UF_CLT_NAME_FIRST,
			T.UF_CLT_BIRTH_DAY,
			T.UF_CLT_EMAIL,
			T.UF_CLT_AVG_INCOME,
			T.UF_CAR_COST_RUB,
			T.UF_CAR_ISSUE_YEAR,
			T.UF_STAT_SOURCE,
			--
			T.UF_FROM_SITE,
			T.UF_VIEWED,
			T.UF_PARTNER_ID,
			T.UF_SUM_ACCEPTED,
			T.UF_SUM_LOAN,
			T.UF_REGIONS_COMPOSITE,
			T.UF_ISSUED_AT,
			T.UF_TARGET,
			T.UF_FULL_FORM_LEAD,
			T.UF_STEP,
			T.UF_SOURCE_SHADOW,
			T.UF_TYPE_SHADOW,
			T.UF_CLB_TYPE,
			t.UF_CLIENT_ID
		--var.1
		FROM _LCRM.lcrm_leads_full_csv_today AS T
		WHERE EXISTS(SELECT TOP(1) 1 FROM _lcrm.dm_CSV_Change_list AS S WHERE S.id = T.Id)
		--var.2
		--FROM _LCRM.lcrm_leads_full_csv_today AS T
		--	INNER JOIN (
		--		SELECT DISTINCT C.id
		--		FROM _LCRM.dm_CSV_Change_list AS C
		--	) AS S
		--	ON S.id = T.ID
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
	END
	ELSE BEGIN 
		--передано название врем. табл. со списком ID
		IF @PartitionId IS NULL
		BEGIN
			INSERT #tmp2BE338B9_lcrm_leads_channel
			WITH(TABLOCKX) 
			(
				ID,
				DWHInsertedDate,
				--
				UF_NAME,
				UF_PHONE,
				UF_REGISTERED_AT,
				UF_UPDATED_AT,
				UF_ROW_ID,
				UF_AGENT_NAME,
				UF_STAT_CAMPAIGN,
				UF_STAT_CLIENT_ID_YA,
				UF_STAT_CLIENT_ID_GA,
				UF_TYPE,
				UF_SOURCE,
				UF_STAT_AD_TYPE,
				UF_ACTUALIZE_AT,
				UF_CAR_MARK,
				UF_CAR_MODEL,
				UF_PHONE_ADD,
				UF_PARENT_ID,
				UF_GROUP_ID,
				UF_PRIORITY,
				UF_RC_REJECT_CM,
				UF_APPMECA_TRACKER,
				UF_LOGINOM_CHANNEL,
				UF_LOGINOM_GROUP,
				UF_LOGINOM_PRIORITY,
				UF_LOGINOM_STATUS,
				UF_LOGINOM_DECLINE,
				UF_CLID,
				UF_MATCH_ALGORITHM,
				UF_CLB_CHANNEL,
				UF_LOAN_MONTH_COUNT,
				UF_STAT_SYSTEM,
				UF_STAT_DETAIL_INFO,
				UF_STAT_TERM,
				UF_STAT_FIRST_PAGE,
				UF_STAT_INT_PAGE,
				UF_CLT_NAME_FIRST,
				UF_CLT_BIRTH_DAY,
				UF_CLT_EMAIL,
				UF_CLT_AVG_INCOME,
				UF_CAR_COST_RUB,
				UF_CAR_ISSUE_YEAR,
				UF_STAT_SOURCE,
				--
				UF_FROM_SITE,
				UF_VIEWED,
				UF_PARTNER_ID,
				UF_SUM_ACCEPTED,
				UF_SUM_LOAN,
				UF_REGIONS_COMPOSITE,
				UF_ISSUED_AT,
				UF_TARGET,
				UF_FULL_FORM_LEAD,
				UF_STEP,
				UF_SOURCE_SHADOW,
				UF_TYPE_SHADOW,
				UF_CLB_TYPE,
				UF_CLIENT_ID
			)
			SELECT 
				T.ID,
				DWHInsertedDate = getdate(),
				--
				T.UF_NAME,
				T.UF_PHONE,
				T.UF_REGISTERED_AT,
				T.UF_UPDATED_AT,
				T.UF_ROW_ID,
				T.UF_AGENT_NAME,
				T.UF_STAT_CAMPAIGN,
				T.UF_STAT_CLIENT_ID_YA,
				T.UF_STAT_CLIENT_ID_GA,
				T.UF_TYPE,
				T.UF_SOURCE,
				T.UF_STAT_AD_TYPE,
				T.UF_ACTUALIZE_AT,
				T.UF_CAR_MARK,
				T.UF_CAR_MODEL,
				T.UF_PHONE_ADD,
				T.UF_PARENT_ID,
				T.UF_GROUP_ID,
				T.UF_PRIORITY,
				T.UF_RC_REJECT_CM,
				T.UF_APPMECA_TRACKER,
				T.UF_LOGINOM_CHANNEL,
				T.UF_LOGINOM_GROUP,
				T.UF_LOGINOM_PRIORITY,
				T.UF_LOGINOM_STATUS,
				T.UF_LOGINOM_DECLINE,
				T.UF_CLID,
				T.UF_MATCH_ALGORITHM,
				T.UF_CLB_CHANNEL,
				T.UF_LOAN_MONTH_COUNT,
				T.UF_STAT_SYSTEM,
				T.UF_STAT_DETAIL_INFO,
				T.UF_STAT_TERM,
				T.UF_STAT_FIRST_PAGE,
				T.UF_STAT_INT_PAGE,
				T.UF_CLT_NAME_FIRST,
				T.UF_CLT_BIRTH_DAY,
				T.UF_CLT_EMAIL,
				T.UF_CLT_AVG_INCOME,
				T.UF_CAR_COST_RUB,
				T.UF_CAR_ISSUE_YEAR,
				T.UF_STAT_SOURCE,
				--
				T.UF_FROM_SITE,
				T.UF_VIEWED,
				T.UF_PARTNER_ID,
				T.UF_SUM_ACCEPTED,
				T.UF_SUM_LOAN,
				T.UF_REGIONS_COMPOSITE,
				T.UF_ISSUED_AT,
				T.UF_TARGET,
				T.UF_FULL_FORM_LEAD,
				T.UF_STEP,
				T.UF_SOURCE_SHADOW,
				T.UF_TYPE_SHADOW,
				T.UF_CLB_TYPE,
				T.UF_CLIENT_ID
			FROM #ID_List AS L
				INNER JOIN _LCRM.lcrm_leads_full AS T
					ON T.ID = L.ID
			OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
		END
		ELSE BEGIN
			INSERT #tmp2BE338B9_lcrm_leads_channel
			WITH(TABLOCKX) 
			(
				ID,
				DWHInsertedDate,
				--
				UF_NAME,
				UF_PHONE,
				UF_REGISTERED_AT,
				UF_UPDATED_AT,
				UF_ROW_ID,
				UF_AGENT_NAME,
				UF_STAT_CAMPAIGN,
				UF_STAT_CLIENT_ID_YA,
				UF_STAT_CLIENT_ID_GA,
				UF_TYPE,
				UF_SOURCE,
				UF_STAT_AD_TYPE,
				UF_ACTUALIZE_AT,
				UF_CAR_MARK,
				UF_CAR_MODEL,
				UF_PHONE_ADD,
				UF_PARENT_ID,
				UF_GROUP_ID,
				UF_PRIORITY,
				UF_RC_REJECT_CM,
				UF_APPMECA_TRACKER,
				UF_LOGINOM_CHANNEL,
				UF_LOGINOM_GROUP,
				UF_LOGINOM_PRIORITY,
				UF_LOGINOM_STATUS,
				UF_LOGINOM_DECLINE,
				UF_CLID,
				UF_MATCH_ALGORITHM,
				UF_CLB_CHANNEL,
				UF_LOAN_MONTH_COUNT,
				UF_STAT_SYSTEM,
				UF_STAT_DETAIL_INFO,
				UF_STAT_TERM,
				UF_STAT_FIRST_PAGE,
				UF_STAT_INT_PAGE,
				UF_CLT_NAME_FIRST,
				UF_CLT_BIRTH_DAY,
				UF_CLT_EMAIL,
				UF_CLT_AVG_INCOME,
				UF_CAR_COST_RUB,
				UF_CAR_ISSUE_YEAR,
				UF_STAT_SOURCE,
				--
				UF_FROM_SITE,
				UF_VIEWED,
				UF_PARTNER_ID,
				UF_SUM_ACCEPTED,
				UF_SUM_LOAN,
				UF_REGIONS_COMPOSITE,
				UF_ISSUED_AT,
				UF_TARGET,
				UF_FULL_FORM_LEAD,
				UF_STEP,
				UF_SOURCE_SHADOW,
				UF_TYPE_SHADOW,
				UF_CLB_TYPE,
				UF_CLIENT_ID
			)
			SELECT 
				T.ID,
				DWHInsertedDate = getdate(),
				--
				T.UF_NAME,
				T.UF_PHONE,
				T.UF_REGISTERED_AT,
				T.UF_UPDATED_AT,
				T.UF_ROW_ID,
				T.UF_AGENT_NAME,
				T.UF_STAT_CAMPAIGN,
				T.UF_STAT_CLIENT_ID_YA,
				T.UF_STAT_CLIENT_ID_GA,
				T.UF_TYPE,
				T.UF_SOURCE,
				T.UF_STAT_AD_TYPE,
				T.UF_ACTUALIZE_AT,
				T.UF_CAR_MARK,
				T.UF_CAR_MODEL,
				T.UF_PHONE_ADD,
				T.UF_PARENT_ID,
				T.UF_GROUP_ID,
				T.UF_PRIORITY,
				T.UF_RC_REJECT_CM,
				T.UF_APPMECA_TRACKER,
				T.UF_LOGINOM_CHANNEL,
				T.UF_LOGINOM_GROUP,
				T.UF_LOGINOM_PRIORITY,
				T.UF_LOGINOM_STATUS,
				T.UF_LOGINOM_DECLINE,
				T.UF_CLID,
				T.UF_MATCH_ALGORITHM,
				T.UF_CLB_CHANNEL,
				T.UF_LOAN_MONTH_COUNT,
				T.UF_STAT_SYSTEM,
				T.UF_STAT_DETAIL_INFO,
				T.UF_STAT_TERM,
				T.UF_STAT_FIRST_PAGE,
				T.UF_STAT_INT_PAGE,
				T.UF_CLT_NAME_FIRST,
				T.UF_CLT_BIRTH_DAY,
				T.UF_CLT_EMAIL,
				T.UF_CLT_AVG_INCOME,
				T.UF_CAR_COST_RUB,
				T.UF_CAR_ISSUE_YEAR,
				T.UF_STAT_SOURCE,
				--
				T.UF_FROM_SITE,
				T.UF_VIEWED,
				T.UF_PARTNER_ID,
				T.UF_SUM_ACCEPTED,
				T.UF_SUM_LOAN,
				T.UF_REGIONS_COMPOSITE,
				T.UF_ISSUED_AT,
				T.UF_TARGET,
				T.UF_FULL_FORM_LEAD,
				T.UF_STEP,
				T.UF_SOURCE_SHADOW,
				T.UF_TYPE_SHADOW,
				T.UF_CLB_TYPE,
				T.UF_CLIENT_ID
			FROM #ID_List AS L
				INNER JOIN _LCRM.lcrm_leads_full AS T
					ON T.ID = L.ID
			WHERE $PARTITION.pfn_range_right_date_part_lcrm_leads_full(T.UF_REGISTERED_AT) = @PartitionId
			OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
		END
	END

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #tmp2BE338B9_lcrm_leads_channel', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	-- расчет вычисляемых полей и заполнение таблицы _LCRM.lcrm_leads_full_calculated
	EXEC _LCRM.Calculation_lcrm_leads_fields
		@Debug = @Debug, -- 0 - штатное выполнение, 1 - отладочный режим
		@Insert_Into_lcrm_leads_full = @Insert_Into_lcrm_leads_full -- 1 - добавление записей в _LCRM.lcrm_leads_full

	-- LCRM load leads finished log
	EXEC _LCRM.LCRMLeads_logging 
		@action = 0,
		@message = 'LCRM calculate leads finished',
		@process = 'Finished calculate LCRM leads stg'
END



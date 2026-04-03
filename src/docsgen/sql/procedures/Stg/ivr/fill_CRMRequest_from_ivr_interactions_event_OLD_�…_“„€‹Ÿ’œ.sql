--DROP PROC ivr.fill_CRMRequest_from_ivr_interactions_event
-- Usage: запуск процедуры с параметрами
-- EXEC ivr.fill_CRMRequest_from_ivr_interactions_event @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROC ivr.fill_CRMRequest_from_ivr_interactions_event
	@t_ivr_interactions_event ivr.utt_ivr_interactions_event READONLY,
	@isDebug bit = 0
as
begin
SET XACT_ABORT ON
begin try
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @StartDate datetime, @row_count int
	DECLARE @IVR_Data_json_array nvarchar(max)

	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_ЗаявкаНаЗаймПодПТС

	SELECT DISTINCT
		salesstageTime = dateadd(HOUR, 3, dateadd(SECOND, R.publishTime, convert(datetime, '1970-01-01 00:00:00', 120)))
		, CRMRequestGUID = lower(R.requestGuid)
		, CRMRequestID = R.requestNumber
		, МобильныйТелефон = cast(NULL AS varchar(10))
		, Caller = cast(NULL AS varchar(10))
		, fio = cast(NULL AS varchar(10))
		, Cmclient = cast(NULL AS varchar(10))
		, CRMRequestDate = cast(NULL AS varchar(10))
		, isActive = cast(NULL AS varchar(10))
		, CRMRequest_RowVersion = cast(NULL AS binary(8))
		, hasContract = cast(NULL AS varchar(10))
		, hasRejection = cast(NULL AS varchar(10))
		, RequestType = cast(NULL AS varchar(10))
		, CRMRequestsLastStatus = cast(NULL AS varchar(10))
		, CRMClientGUID = cast(NULL AS varchar(10))
		, [Type] = 'CRM_Requests'
		, IVRDate = getdate()  
		, created = getdate() 
		, updated = getdate()
		, isHistory = 0
		, Legal = 0
		, ExecutionOrder = 0
		, productType = cast(NULL AS varchar(10))
		, salesstage = ivr.get_salesstage_from_eventCode(R.eventCode)
	into #t_ЗаявкаНаЗаймПодПТС
	from @t_ivr_interactions_event AS R

	SELECT @row_count = @@ROWCOUNT

	--IF @isDebug = 1 BEGIN
	--	SELECT 'INSERT #t_ЗаявкаНаЗаймПодПТС', @row_count, cast(getdate() - @StartDate as time(2)) as duration 
	--END

	delete from #t_ЗаявкаНаЗаймПодПТС
	where 1=1
		--AND nullif(МобильныйТелефон,'') is NULL
        AND nullif(CRMRequestGUID,'') is null

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС FROM #t_ЗаявкаНаЗаймПодПТС
	END

	BEGIN TRAN
		select @StartDate= getdate() , @row_count = 0

		merge ivr.IVR_Data t
		using #t_ЗаявкаНаЗаймПодПТС s
			--on t.[Caller] = s.[Caller]
			on t.CRMRequestGUID = s.CRMRequestGUID
			and  t.[Type] = 'CRM_Requests'
		when not matched 
		THEN INSERT (
			  [Caller]
			, МобильныйТелефон
			, [Cmclient]
			, [CRMClientGUID] 
			, [CRMRequestGUID]
			, [CRMRequestID]
			, [fio]
			, [RequestType]
			, [CRMRequestDate]
			, [isActive]
			, [hasContract]
			, [hasRejection]
			, [CRMRequestsLastStatus]
			, [CRMRequest_RowVersion]
			, Legal
			, ExecutionOrder
			, [Type]
			, [IVRDate] 
			, [created] 
			, [updated]
			, [isHistory]
			, productType
			, salesstage
			, salesstageTime
		)
		values(
			  s.[Caller]
			, s.МобильныйТелефон
			, s.[Cmclient]
			, s.[CRMClientGUID]
			, s.[CRMRequestGUID]
			, s.[CRMRequestID]
			, s.[fio]
			, s.[RequestType]
			, s.[CRMRequestDate]
			, s.[isActive]
			, s.[hasContract] 
			, s.[hasRejection]
			, s.[CRMRequestsLastStatus]
			, s.[CRMRequest_RowVersion]
			, s.Legal
			, s.ExecutionOrder
			, s.[Type]
			, s.[IVRDate] 
			, s.[created] 
			, s.[updated]
			, s.[isHistory]
			, s.productType
			, s.salesstage
			, s.salesstageTime
		)
		when  matched  
			AND isnull(t.salesstageTime, '2000-01-01') <= s.salesstageTime
			--and isnull(t.[CRMRequest_RowVersion], 0) != s.[CRMRequest_RowVersion]
			--or isnull(t.[CRMClientGUID], cast(null as uniqueidentifier )) != isnull(s.[CRMClientGUID], cast(null as uniqueidentifier ))
			--OR isnull(t.[CRMRequestGUID], cast(null as uniqueidentifier )) !=isnull(s.[CRMRequestGUID], cast(null as uniqueidentifier ))
		THEN UPDATE 
		SET
			--[Caller] = s.[Caller]
			--, МобильныйТелефон = s.МобильныйТелефон
			--, [Cmclient] = s.[Cmclient]
			--, [CRMClientGUID] = s. [CRMClientGUID]
					--, [CRMRequestGUID] = s.[CRMRequestGUID]
			--, [CRMRequestID] = s.[CRMRequestID]
			--, [fio] = s.[fio]
			--, [RequestType] = s.[RequestType]
			--, [CRMRequestDate] = s.[CRMRequestDate]
			--, [isActive] = s.[isActive]
			--, [hasContract] = s.[hasContract]
			--, [hasRejection] = s.[hasRejection]
			--, [CRMRequestsLastStatus] = s.[CRMRequestsLastStatus]
			--, [CRMRequest_RowVersion] = s.[CRMRequest_RowVersion]
			--, Legal = s.Legal
			--, ExecutionOrder = s.ExecutionOrder
					--, [Type]
			--, [IVRDate] = s.[IVRDate]
				--, [created] = s.[created]
			[updated] = s.[updated]
			--, [isHistory] = s.[isHistory]
			--, productType = s.productType
			, salesstage = s.salesstage
			, salesstageTime = s.salesstageTime
			;

		SELECT @row_count = @@ROWCOUNT

		IF @isDebug = 1 BEGIN
			SELECT 'merge ivr.IVR_Data', @row_count, cast(getdate() - @StartDate as time(2)) as duration
		END

	COMMIT TRAN	

	SELECT @IVR_Data_json_array = (
		SELECT 
			[Caller], 
			[Cmclient], 
			[CRMClientGUID], 
			[Dpd] = NULL, 
			[Legal], 
			[ExecutionOrder], 
			[ProblemClient] = NULL, 
			[CRMRequestGUID], 
			[CRMRequestID], 
			[fio], 
			[IVRDate], 
			[created], 
			[updated], 
			[isHistory], 
			[ClientStage] = NULL, 
			[RequestType], 
			[CRMRequestDate], 
			[isActive], 
			[ClaimantFio] = NULL, 
			[ClaimantCorporatePhone] = NULL, 
			
			[hasContract], 
			[hasRejection], 
			[CRMRequestsLastStatus], 
			[claimantStage] = NULL, 
			[Type], 
			--[МобильныйТелефон],
			mobilePhone = МобильныйТелефон,
			[channellid] = NULL,
			productType,
			salesstage,
			salesstageTime = convert(varchar(19), salesstageTime, 120)
		FROM #t_ЗаявкаНаЗаймПодПТС AS S
		FOR JSON PATH, INCLUDE_NULL_VALUES --, WITHOUT_ARRAY_WRAPPER
	)

	IF @isDebug = 1 BEGIN
		SELECT @IVR_Data_json_array 
		--RETURN 0
	END

	EXEC [DWH-EX].Dialer.dbo.ImportIVRFromDWH_by_interactions_event
		@IVR_Data_json_array = @IVR_Data_json_array,
		@isDebug = @isDebug
	
end try
begin catch
	if @@TRANCOUNT>1
		rollback tran;
	;throw
end catch
end

--select * from dbo.IVR
--where IVRDate = cast(getdate() as date)	
--truncate table ivr.IVR_Data
--select * from ivr.IVR_Data
--drop PROC ivr.fill_CRMRequest_from_ivr_crm_requests
CREATE   PROC [ivr].[fill_CRMRequest_from_ivr_crm_requests]
	@t_request ivr.utt_ivr_data READONLY,
	@isDebug bit = 0
as
begin
SET XACT_ABORT ON
begin try
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @StartDate datetime, @row_count int
	--DECLARE @IVR_Data_json_array nvarchar(max)

	SELECT @StartDate = getdate(), @row_count = 0

	declare @mobilePhone varchar(10), @hasContract bit = 0, @hasRejection bit = 0
	drop table if exists #t_hasContract
	select distinct
		t.CRMRequestGUID
		,hasContract = 1
	into #t_hasContract
	from @t_request t
	inner join 
	(
		select t.НомерТелефонаБезКодов
		from dwh2.sat.Клиент_Телефон as t
			inner join dwh2.link.v_Клиент_ДоговорЗайма as l
				on l.GuidКлиент = t.GuidКлиент
		group by НомерТелефонаБезКодов
	) t_hasContract on t_hasContract.НомерТелефонаБезКодов = t.МобильныйТелефон
	drop table if exists #t_hasRejection
	select distinct 
		t.CRMRequestGUID
		,hasRejection = 1
	into #t_hasRejection
	from @t_request t
	inner join (
		select t.НомерТелефонаБезКодов
		from dwh2.sat.Клиент_Телефон as t
			inner join dwh2.link.v_Клиент_Заявка as l
				on l.GuidКлиент = t.GuidКлиент
			inner join dwh2.sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов as s
				on s.GuidЗаявки = l.GuidЗаявки
				and s.Отказано >= dateadd(DAY, -3, cast(getdate() as date))
		group by t.НомерТелефонаБезКодов
	) t_hasRejection on t_hasRejection.НомерТелефонаБезКодов = t.МобильныйТелефон
	
	
	--BEGIN TRAN
		select @StartDate= getdate() , @row_count = 0

		merge  Stg.ivr.IVR_Data as t
		using 
		(
		select 
			  t.[Caller]
			, t.МобильныйТелефон
			, t.[Cmclient]
			, t.[CRMClientGUID]
			, t.[CRMRequestGUID]
			, t.[CRMRequestID]
			, t.[fio]
			, t.[RequestType]
			, t.[CRMRequestDate]
			, t.[isActive]
			, [hasContract]  = isnull(t_hasContract.hasContract,0)
			, [hasRejection] = isnull(t_hasRejection.hasRejection,0)
			, t.[CRMRequestsLastStatus]
			, t.[CRMRequest_RowVersion]
			, t.Legal
			, t.ExecutionOrder
			, t.[Type]
			, t.[IVRDate] 
			, t.[created] 
			, t.[updated]
			, t.[isHistory]
			, t.productType
			, t.requestLastStatusCode

			from @t_request t
			left join #t_hasContract  t_hasContract on t_hasContract.CRMRequestGUID  = t.CRMRequestGUID
			left join #t_hasRejection t_hasRejection on t_hasRejection.CRMRequestGUID  = t.CRMRequestGUID
		) as s
			on t.[Caller] = s.[Caller]
			and t.[CRMRequestGUID] = s.[CRMRequestGUID]
			and  t.[Type] = 'CRM_Requests'
		when not matched then insert (
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
			, requestLastStatusCode
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
			, s.requestLastStatusCode
		)
		when  matched  
				--and isnull(t.[CRMRequest_RowVersion], 0) != s.[CRMRequest_RowVersion]
				--or isnull(t.[CRMClientGUID], cast(null as uniqueidentifier )) != isnull(s.[CRMClientGUID], cast(null as uniqueidentifier ))
				--OR isnull(t.[CRMRequestGUID], cast(null as uniqueidentifier )) !=isnull(s.[CRMRequestGUID], cast(null as uniqueidentifier ))
			then update set
			t.[fio] = isnull(s.[fio], t.[fio])
			,t.Cmclient	= isnull(s.Cmclient, t.Cmclient)
			,t.[CRMRequestDate] = isnull(s.[CRMRequestDate], t.[CRMRequestDate])
			,t.[CRMClientGUID] = isnull(s.[CRMClientGUID], t.[CRMClientGUID])
			,t.CRMRequestGUID = isnull(s.CRMRequestGUID, t.CRMRequestGUID)
			,t.CRMRequestID = isnull(s.CRMRequestID, t.CRMRequestID)
			,t.[isActive] = isnull(s.[isActive], t.[isActive])
			,t.[CRMRequestsLastStatus] = isnull(s.[CRMRequestsLastStatus], t.[CRMRequestsLastStatus])
			,t.[CRMRequest_RowVersion] = isnull(s.[CRMRequest_RowVersion], t.[CRMRequest_RowVersion])
			,t.МобильныйТелефон = isnull(s.МобильныйТелефон, t.МобильныйТелефон)
			,t.[updated] = isnull(s.updated, t.[updated])
			,t.productType = isnull(s.productType, t.productType)
			,t.requestLastStatusCode = isnull(s.requestLastStatusCode, t.requestLastStatusCode)
			;

	--COMMIT TRAN	
	
end try
begin catch
	if @@TRANCOUNT>1
		rollback tran;
	;throw
end catch
end

--drop PROC ivr.fill_CRMRequest_from_ivr_interaction_event
CREATE   PROC [ivr].[fill_CRMRequest_from_ivr_interaction_event]
	@t_request ivr.utt_ivr_data READONLY,
	@isDebug bit = 0
as
begin
SET XACT_ABORT ON
begin try
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @StartDate datetime= getdate(), @row_count int= 0

	--BEGIN TRAN

		merge  Stg.ivr.IVR_Data as t
		using 
		(
		select 
				t.CRMRequestGUID
				,t.CRMRequestID
				,t.interactionEventGuid
				,t.interactionEventCode
				,t.interactionEventName
			from @t_request as t
		) as s
			--on t.[Caller] = s.[Caller]
			on t.[CRMRequestGUID] = s.[CRMRequestGUID]
			and  t.[Type] = 'CRM_Requests'
		when matched  
				--and isnull(t.[CRMRequest_RowVersion], 0) != s.[CRMRequest_RowVersion]
				--or isnull(t.[CRMClientGUID], cast(null as uniqueidentifier )) != isnull(s.[CRMClientGUID], cast(null as uniqueidentifier ))
				--OR isnull(t.[CRMRequestGUID], cast(null as uniqueidentifier )) !=isnull(s.[CRMRequestGUID], cast(null as uniqueidentifier ))
			then update set
				t.interactionEventGuid = s.interactionEventGuid
				,t.interactionEventCode = s.interactionEventCode
				,t.interactionEventName = s.interactionEventName
			;

	--COMMIT TRAN	
	
end try
begin catch
	if @@TRANCOUNT>1
		rollback tran;
	;throw
end catch
end

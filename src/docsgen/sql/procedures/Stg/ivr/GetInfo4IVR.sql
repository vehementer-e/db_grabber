
--exec [ivr].[GetInfo4IVR] @caller = '89186740022'
-- Usage: запуск процедуры с параметрами
-- EXEC [ivr].[GetInfo4IVR]
--      @caller = <value>,
--      @sourceCompany = 'carmoney'
	WITH EXECUTE AS OWNER;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE     procedure [ivr].[GetInfo4IVR]
	@caller nvarchar(11)
	,@sourceCompany nvarchar(255) = 'carmoney'
	WITH EXECUTE AS OWNER
as

	  
	  set @caller = concat('8', RIGHT(@caller,10))
begin
select 
  [Caller]
		, [Cmclient] 
		, [CRMclientID]
		, [Dpd]
		, [Legal]
		, [ExecutionOrder]
		, [ProblemClient] 
		, [CRMrequestID] 
		, [FIO]
		, [ClientStage]
		, [RequestType] 
		, [System]
		, [ord]
		, [isActive]
		, [ClaimantFio]
		, [ClaimantCorporatePhone]
		, [hasContract]
		, [hasRejection] 
		, [CRMRequestsLastStatus]
		, [claimantStage]
		, channellid
		, [route]
		, productType
		, salesStage
		,naumenCase4MarketProposal
		, [requestLastStatusCode]
		, [interactionEventGuid]
		, [interactionEventCode]
		, [interactionEventName]
		, requestGuid
		, contractGuid
from (
	select 
		  [Caller]
		, [Cmclient] 
		, [CRMclientID]
		, [Dpd]
		, [Legal]
		, [ExecutionOrder]
		, [ProblemClient] 
		, [CRMrequestID] 
		, [FIO]
		, [ClientStage]
		, [RequestType] 
		, [System]
		, [ord]
		, [isActive]
		, [ClaimantFio]
		, [ClaimantCorporatePhone]
		, [hasContract]
		, [hasRejection] 
		, [CRMRequestsLastStatus]
		, [claimantStage]
		, channellid
		, [route]
		, productType
		, salesStage
		, naumenCase4MarketProposal
		, [requestLastStatusCode]
		, [interactionEventGuid]
		, [interactionEventCode]
		, [interactionEventName]
		, requestGuid
		, contractGuid
	from (
		SELECT  
			  [Caller] 
			, [Cmclient]=format(isnull([Cmclient],'1'),'0')
			, [CRMclientID]=isnull([CRMclientGUID],'')
			, [Dpd]=format(isnull([Dpd],0),'0')
			, [Legal]=format(isnull([Legal],0),'0')
			, [ExecutionOrder]=format(isnull([ExecutionOrder],0),'0')
			, [ProblemClient]=format(isnull([ProblemClient],0),'0')
			, [CRMrequestID] = isnull(isnull(CRMrequestID,'0'),'0')
			, [FIO] =isnull(FIO,'')
			, ClientStage = isnull(ClientStage,'')
			, RequestType = isnull(RequestType,'')
			, System = [Type]
			, ord = 1 
			, isActive
			, ClaimantFio = isnull(ClaimantFio, '')
			, ClaimantCorporatePhone = isnull(ClaimantCorporatePhone, '')
			, hasContract = cast(isnull(hasContract, 0) as bit)
			, hasRejection = cast(isnull(hasRejection, 0) as bit)
			, CRMRequestsLastStatus  = isnull(CRMRequestsLastStatus,'')
			, claimantStage   = isnull(claimantStage ,'')
			, nRow = ROW_NUMBER() over(partition by [Caller] order by isnull([Dpd],0) desc, isActive desc, CRMRequestDate desc)
			, channellid 
			, [route] = 'false'
			, productType
			, salesStage
			, naumenCase4MarketProposal = isnull(naumenCase4MarketProposal,'false')
			, [requestLastStatusCode]
			, [interactionEventGuid]
			, [interactionEventCode]
			, [interactionEventName]
			, requestGuid = [CRMRequestGUID]
			, contractGuid = [CMRContractGuid]
			 FROM ivr.IVR_Data  t with (nolock) 
			 left join ivr.ProductAndCompanyMapping p on p.productCode = t.productType
			 where [Type] in ('CRM_Requests', 'CMR_contract')
			 and Caller is not null
			 and Caller = @caller
			 and isnull(p.companyCode, 'carmoney') = @sourceCompany
			 
		
	) t
	where  nRow = 1
        /*
        union all 
		 select 
         Caller 
		 ,Cmclient = isnull(Cmclient,'0')
        ,CRMclientID = isnull([CRMclientGUID],'')
        ,Dpd = isnull(dpd,'0')
        ,Legal = isnull(Legal,'0')
        ,ExecutionOrder = isnull(ExecutionOrder,'0')
        ,ProblemClient	= isnull(ProblemClient,'0')
        ,CRMrequestID	= isnull(CRMrequestID,'0')
        ,FIO = isnull(FIO,'')
        ,ClientStage =isnull(ClientStage, '')
        ,RequestType =isnull(RequestType, '')
        ,System ='LCRM_LEAD'
        ,ord = 2 
		,isActive =isActive
		, ClaimantFio = isnull(ClaimantFio, '')
		, ClaimantCorporatePhone = isnull(ClaimantCorporatePhone,'')
		, hasContract = cast(isnull(null, 0) as bit)
		, hasRejection = cast(isnull(null, 0) as bit)
		, CRMRequestsLastStatus = isnull(CRMRequestsLastStatus, '')
		, claimantStage  	    = isnull(claimantStage, '')
		, channellid
		, [route] = cast(datediff(dd, created, getdate()) as nvarchar(25))
        , productType
		, salesStage = null
		,naumenCase4MarketProposal = 'false'
		 from ivr.IVR_Data with (nolock) 
		 where [Type] = 'LCRM_LEAD'
		 and Caller = @caller
		 */
		 ) t
	
end

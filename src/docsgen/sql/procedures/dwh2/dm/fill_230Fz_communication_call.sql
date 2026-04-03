CREATE   procedure [dm].[fill_230Fz_communication_call]
	@ddReload smallint = 3
	,@isReloadAll bit = 0
	,@isDebug bit = 0
as
begin
begin try
	declare @startReloadDate date = '2024-11-01'
	if OBJECT_ID('dm.230Fz_communication_call') is null or @isReloadAll =1
		set @startReloadDate  = '2024-11-01'
	else if exists(select top(1) 1 from dm.[230Fz_communication_call])
	begin
		set @startReloadDate = dateadd(dd, -@ddReload, (select 
			max(communicationDate)
			from dm.[230Fz_communication_call]
		))
	end
	select @startReloadDate

	drop  table if exists #t_CommunicationTypeCall_with_CommunicationResult_take230FZ
		--Отбираем коммуникации типа звонки и и результат относится к 230ФЗ
	select id =  newid()
		, CommunicationTypeId = ct.ID
		, CommunicationTypeName =ct.Name
		, CommunicationTypeDateFrom = acts.DateFrom
		, CommunicationResultId = cr.Id
		, CommunicationResultName = cr.Name
		, CommunicationResultDateFrom = arcts.DateFrom
		into #t_CommunicationTypeCall_with_CommunicationResult_take230FZ
		from stg._Collection.ContactTypeCounterSmds Contact_tc
	inner join stg._collection.CommunicationTypeCounterSmds Communication_tc on 
		Communication_tc.ContactTypeCounterId = Contact_tc.Id
	inner join stg._Collection.AccountingCommunicationTypeSpace acts	on 
		acts.CommunicationTypeCounterSmdsId = Communication_tc.Id
	inner join stg._Collection.CommunicationType ct on ct.Id = acts.CommunicationTypeId
	left join stg._Collection.CommunicationTypeCounterSmds Communication_tc_230fz
		on Communication_tc_230fz.Code = 'take230FZ'
	left join stg._Collection.AccountingResultCommunicationTypeSpace arcts
		on arcts.CommunicationTypeCounterSmdsId = Communication_tc_230fz.Id
	left join stg._Collection.CommunicationResult cr on cr.Id =arcts.CommunicationResultId
	where Contact_tc.Code = 'calls'
	create clustered index cix on #t_CommunicationTypeCall_with_CommunicationResult_take230FZ(id)
--собираем коммуникации 
select 
	 communicationId			= c.Id
	,communicationDate			= c.Date
	,communicationPhoneNumber	= c.PhoneNumber
	,communicationCommentary	= nullif(trim(c.Commentary),'')
	,contactTypeId				= c.ContactTypeId
	,contactTypeName			= ct.Name
	,contactPersonTypeId		= c.ContactPersonType
	,contactPersonTypeName		= pt.Name
	,collectionCustomerId		= c.CustomerId
	,collectionDealId			= c.IdDeal
	,contractGuid				= d.CmrId
	,clientGuid					= cust.CrmCustomerId
	,collectionEmployeeId		= c.EmployeeId
	,collectionEmployeeName		= concat_ws(' ', e.LastName, e.FirstName, e.MiddleName)
	,take230FZ.CommunicationResultId
	,take230FZ.CommunicationResultName
	,take230FZ.CommunicationTypeId
	,take230FZ.CommunicationTypeName

	,[NaumenCaseUuid]
	,[SessionId]
	,created_at					= getdate()
	,updated_at					= cast(null as datetime)

	into #tResult
from #t_CommunicationTypeCall_with_CommunicationResult_take230FZ take230FZ
inner join stg._Collection.Communications c on c.CommunicationType	 = take230FZ.CommunicationTypeId
		and c.Date>= take230FZ.CommunicationTypeDateFrom
	and c.CommunicationResultId = take230FZ.CommunicationResultId
		and c.Date>=take230FZ.CommunicationResultDateFrom
	left join [Stg].[_Collection].[Deals]  d			   on d.Id = c.IdDeal
   LEFT JOIN [Stg].[_Collection].[customers] cust          ON cust.id=isnull(c.CustomerId, d.IdCustomer)
    LEFT JOIN [Stg].[_Collection].[ContactPersonType] pt   ON pt.[Id]=c.[ContactPersonType]
    LEFT JOIN [Stg].[_Collection].[Employee] e             ON e.Id = c.EmployeeId
	left join stg._Collection.ContactType ct			   on ct.Id	= c.ContactTypeId
	
where c.Date >= @startReloadDate

create clustered index cix_communicationId on #tResult(communicationId)  


if exists(select top(1) 1 from #tResult)
	begin
		if OBJECT_ID('dm.230Fz_communication_call') is null
		begin
			--drop table if exists dm.[230Fz_communication_call]
			select top(0)
				 communicationId			
				,communicationDate			
				,communicationPhoneNumber	
				,communicationCommentary
				,contactTypeId				
				,contactTypeName			
				,contactPersonTypeId		
				,contactPersonTypeName		
				,collectionCustomerId		
				,collectionDealId			
				,contractGuid				
				,clientGuid					
				,collectionEmployeeId		
				,collectionEmployeeName		
				,communicationResultId
				,communicationResultName
				,communicationTypeId
				,communicationTypeName
				,[NaumenCaseUuid]
				,[SessionId]
				,created_at					
				,updated_at					
			into dm.[230Fz_communication_call]
			from #tResult
			create clustered index cix_communication_id on dm.[230Fz_communication_call](communicationId)
			create index ix_communicationDate on dm.[230Fz_communication_call](communicationDate)
				
		end

		begin tran
			if @isReloadAll = 1
				begin
					truncate  table dm.[230Fz_communication_call]
				end

			merge dm.[230Fz_communication_call] t
			using #tResult s on s.communicationId = t.communicationId

			when not matched then insert
			(
				 communicationId			
				,communicationDate			
				,communicationPhoneNumber	
				,communicationCommentary
				,contactTypeId				
				,contactTypeName			
				,contactPersonTypeId		
				,contactPersonTypeName		
				,collectionCustomerId		
				,collectionDealId			
				,contractGuid				
				,clientGuid					
				,collectionEmployeeId		
				,collectionEmployeeName		
				,communicationResultId
				,communicationResultName
				,communicationTypeId
				,communicationTypeName
				,[NaumenCaseUuid]
				,[SessionId]
				,created_at					
				,updated_at					
			)
			values
			(
				 communicationId			
				,communicationDate			
				,communicationPhoneNumber	
				,communicationCommentary
				,contactTypeId				
				,contactTypeName			
				,contactPersonTypeId		
				,contactPersonTypeName		
				,collectionCustomerId		
				,collectionDealId			
				,contractGuid				
				,clientGuid					
				,collectionEmployeeId		
				,collectionEmployeeName	
				,communicationResultId
				,communicationResultName
				,communicationTypeId
				,communicationTypeName
				,[NaumenCaseUuid]
				,[SessionId]
				,created_at					
				,updated_at			
			)
			when matched  
			then update
				set 
					communicationDate			= s.communicationDate			
					,communicationPhoneNumber	= s.communicationPhoneNumber	
					,communicationCommentary	= s.communicationCommentary
					,contactTypeId				= s.contactTypeId				
					,contactTypeName			= s.contactTypeName			
					,contactPersonTypeId		= s.contactPersonTypeId		
					,contactPersonTypeName		= s.contactPersonTypeName		
					,collectionCustomerId		= s.collectionCustomerId		
					,collectionDealId			= s.collectionDealId			
					,contractGuid				= s.contractGuid				
					,clientGuid					= s.clientGuid					
					,collectionEmployeeId		= s.collectionEmployeeId		
					,collectionEmployeeName		= s.collectionEmployeeName	
					,communicationResultId		= s.communicationResultId	
					,communicationResultName	= s.communicationResultName
					,communicationTypeId		= s.communicationTypeId	
					,communicationTypeName		= s.communicationTypeName	
					,[NaumenCaseUuid]			= s.[NaumenCaseUuid]			
					,[SessionId]				= s.[SessionId]				
					,updated_at					= getdate()
			;
		commit tran
	end
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end



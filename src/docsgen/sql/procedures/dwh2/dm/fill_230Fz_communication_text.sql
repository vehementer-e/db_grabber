--dm.fill_230Fz_communication_text @isReloadAll = 1
CREATE   procedure [dm].[fill_230Fz_communication_text]
	@ddReload smallint = 1
	,@isReloadAll bit = 0
	,@isDebug bit = 0
as
begin
begin try
	declare @startReloadDate date
	if OBJECT_ID('dm.230Fz_communication_text') is null or @isReloadAll =1
		set @startReloadDate  = '2024-11-01'
	else if exists(select top(1) 1 from dm.[230Fz_communication_text])
	begin
		set @startReloadDate = dateadd(dd, -@ddReload, (select 
			max(communication_updated_at)
			from dm.[230Fz_communication_text]
		))
	end
	--Отбираем те шаблоны для которых был проставлен флаг take230FZ
	drop table if exists #t_230Fz_communication_template
	select 
		template_Guid				= t.guid 
		,template_code				= t.code
		,template_name				= t.name
		,take230FZ_active_from		= cast(ct.active_from  as datetime2(7))
		,take230FZ_cancelled_from	= cast(isnull(ct.cancelled_from, getdate()) as datetime2(7))
		,method_guid				= m.guid
		,method_name				= m.name
		,method_code				= m.code
	into #t_230Fz_communication_template
	from stg.[_COMCENTER].[templates] t
		inner join stg.[_COMCENTER].communication_types  ct
		on ct.template_guid = t.guid
		inner join stg.[_COMCENTER].[methods] m 
			on m.guid = t.method_guid
			and  m.code in ('sms', 'email', 'push')
	 where exists (select top(1) 1 from stg.[_COMCENTER].[ref_communication_types] rct
		where rct.guid = ct.communication_type_guid
		and rct.code = 'take230FZ'
		)
	create clustered index ix on #t_230Fz_communication_template(template_guid, method_guid)
	

	--собираем коммуникации 
	select 
		communication_guid			= c.guid
		,external_communication_id	= c.communication_id
	    ,external_communication_id_int	= try_cast(SUBSTRING(c.communication_id, 0, charindex('_', c.communication_id,0))	 as int)
		,external_communication_id_guid	= try_cast( c.communication_id		 as uniqueidentifier)
		,ct.method_code				
		,ct.template_code
		,clientGuid					= cast(null as nvarchar(36))
		,contractGuid				= cast(null as nvarchar(36))
		,contact_value				= cm.value
		,system_code				= sc.code
		,communication_createAt		= c.created_at
		,communication_updated_at	= c.updated_at
		,created_at = getdate()
		,updated_at = cast(null as datetime)
		
	into #tResult
	from stg.[_COMCENTER].communications  c
	inner join #t_230Fz_communication_template ct on 
			ct.template_Guid  = c.template_guid
		and ct.method_guid = c.method_guid
		and c.created_at between ct.take230FZ_active_from and ct.take230FZ_cancelled_from	--коммуникация должна быть за период когда шаблон относился к 230фз
	inner join stg._COMCENTER.contacts_methods cm
		on cm.guid = c.contact_method_guid
	inner join stg._COMCENTER.system_codes sc
		on sc.guid = c.system_code_guid
	where c.updated_at >=  @startReloadDate
	and c.communication_status_guid not in (
		'b62c74b4-5921-11eb-bd83-0242ac130006'--Черновик	draft
		) --
		and isnull(planned_at, getdate()) <=  getdate()   -- не берем запланированные отправкия
	
	create clustered index cix_communication_guid on #tResult(communication_guid) 
	create index ix_method_code on #tResult(method_code)  include(contact_value,clientGuid, contractGuid) 
	
	create index ix_system_code on #tResult(system_code)  include(external_communication_id,clientGuid, contractGuid) 

	create index ix_clientGuid on #tResult(clientGuid)  include(contractGuid) 
	
	update t
		set clientGuid = email.GuidКлиент
	from #tResult t
		inner join sat.Клиент_Email email  
			on email.Email = t.contact_value
		and t.method_code in ('email')
	
	update t
		set clientGuid = Телефон.GuidКлиент
	from #tResult t
		inner join [sat].[Клиент_Телефон] Телефон 
			on Телефон.НомерТелефонаБезКодов = t.contact_value
		and t.method_code in ('sms', 'push')
		
	declare @minCommunicationdDate date = (select min(communication_createAt)
		from #tResult)
	 print  @minCommunicationdDate
		select 
			d.CmrId
			,cus.CrmCustomerId
			,external_communication_id
		    , external_communication_id_int = try_cast(SUBSTRING(external_communication_id, 0
			, isnull(nullif(
				charindex('_', external_communication_id,0),0)
				, len(external_communication_id)+1)
				) as int)
			,external_communication_id_guid = try_cast(external_communication_id as uniqueidentifier)
		into #t_space_Communication
		from (
		select 
			CommunicationId = c.Id
			,c.IdDeal
			,c.CustomerId
			,external_communication_id = coalesce(
				nullif(m.ExternalId, '')
				,cast(c.Id as nvarchar(36)))
					
			,external_communication_id_guid = try_cast(coalesce(
				nullif(m.ExternalId, '')
				,cast(c.Id as nvarchar(36)))
				as uniqueidentifier )
		from stg.[_Collection].[Communications] c
		 left join stg._Collection.Message m on m.CommunicationId = c.Id
		 where c.CommunicationType in (
			5 --Смс
			,6 --E-mail
			,8 --push
			)
			and c.Date>=@minCommunicationdDate
		) c
		left join stg.[_Collection].Deals d on	d.Id = c.IdDeal
		left join stg.[_Collection].customers  cus on	cus.Id = isnull(
		d.IdCustomer, c.CustomerId)
		create index #t_external_communication_id_int on #t_space_Communication(
			external_communication_id_int) include(CmrId,  CrmCustomerId)
		create index #t_external_communication_id_guid on #t_space_Communication(
			external_communication_id_guid) include(CmrId,  CrmCustomerId)

	/*		
	update  t
		set 
		contractGuid = 	c.CmrId
		,clientGuid = isnull(clientGuid, c.CrmCustomerId)
	from #tResult t 
	inner join #t_space_Communication c on c.external_communication_id = case 
	when TRY_CAST(c.external_communication_id  as int) is not null  then  SUBSTRING(t.external_communication_id, 0, charindex('_', t.external_communication_id,0))
		when TRY_CAST(c.external_communication_id as uniqueidentifier) is not null then t.external_communication_id end
	  */

	
	update t
		  set 
		 contractGuid = 	c.CmrId
		,clientGuid = isnull(clientGuid, c.CrmCustomerId)
	from #tResult t
	inner join #t_space_Communication c 
		on c.external_communication_id_guid = t.external_communication_id_guid

	update  t
		set 
		contractGuid = 	c.CmrId
		,clientGuid = isnull(clientGuid, c.CrmCustomerId)
	from #tResult t 
	inner join #t_space_Communication c on 
		c.external_communication_id_int =  t.external_communication_id_int
	where t.system_code = 'Space'

	;with cte_balance_contractGUID as (
	select 
		communication_guid
		,contractGUID = b.CMRContractsGUID
		,b.dpd_begin_day
		,nRow  = ROW_NUMBER() over(partition by communication_guid order by b.dpd_begin_day desc)
	from #tResult  t
	inner join dbo.dm_CMRStatBalance b
		on b.d= cast(t.communication_createAt as date)
			and b.CMRClientGUID = t.clientGuid
	where t.contractGuid is null
	and t.template_code in ('freePlaneText230fz', '')
	)
	
	update  t
		set t.contractGuid = s.contractGUID
	from #tResult t
	inner join cte_balance_contractGUID s 
		on s.communication_guid = t.communication_guid
		and s.nRow =1 

	/*коммуникации через соц сети*/
	drop table if exists #t_CommunicationTypeText_with_CommunicationResult_take230FZ
	select id =  newid()
		, CommunicationTypeId = ct.ID
		, CommunicationTypeName =ct.Name
		
		, CommunicationTypeDateFrom = acts.DateFrom
		/*
		, CommunicationResultId = cr.Id
		, CommunicationResultName = cr.Name
		, CommunicationResultDateFrom = arcts.DateFrom
		*/
		into #t_CommunicationTypeText_with_CommunicationResult_take230FZ
		from stg._Collection.ContactTypeCounterSmds Contact_tc
	inner join stg._collection.CommunicationTypeCounterSmds Communication_tc on 
		Communication_tc.ContactTypeCounterId = Contact_tc.Id
	inner join stg._Collection.AccountingCommunicationTypeSpace acts	on 
		acts.CommunicationTypeCounterSmdsId = Communication_tc.Id
	inner join stg._Collection.CommunicationType ct on ct.Id = acts.CommunicationTypeId
	left join stg._Collection.CommunicationTypeCounterSmds Communication_tc_230fz
		on Communication_tc_230fz.Code = 'take230FZ'
	/*
	left join stg._Collection.AccountingResultCommunicationTypeSpace arcts
		on arcts.CommunicationTypeCounterSmdsId = Communication_tc_230fz.Id
	left join stg._Collection.CommunicationResult cr on cr.Id =arcts.CommunicationResultId
	*/
	where Contact_tc.Code = 'textMessages'
		and ct.Name not in ('Смс', 'E-mail', 'push') -- их считаем через COMC т.е выше
		and ct.Name not in ('Автоинформатор pre-del', 'Автоинформатор Pre-legal', 'Воздействие на мобильный телефон клиента - Push') --по согласованию с М.Блинческой
	create clustered index cix on #t_CommunicationTypeText_with_CommunicationResult_take230FZ(id)
	--собираем коммуникации 
	insert into #tResult
	(
		communication_guid			
		,external_communication_id	
		,method_code
		,template_code
		,contact_value		
		,clientGuid
		,contractGuid
		,system_code
		,communication_createAt		
		,communication_updated_at
		,created_at
		,updated_at	
	)
	select 
		communication_guid			= cast(CONVERT(UNIQUEIDENTIFIER, HASHBYTES('MD5',  cast(c.Id as varchar(20)))) as nvarchar(36))
		,external_communication_id = c.Id
		,method_code				= take230FZ.CommunicationTypeName
		,template_code				= 'N/A'
		,contact_value				= c.PhoneNumber
		,clientGuid					= cust.CrmCustomerId
		,contractGuid				= d.CmrId
		,system_code				= 'SPACE'
		,communication_createAt		= c.Date
		,communication_updated_at	= c.Date
--		,communicationCommentary	= nullif(trim(c.Commentary),'')
		,created_at					= getdate()
		,updated_at					= cast(null as datetime)
from #t_CommunicationTypeText_with_CommunicationResult_take230FZ take230FZ
inner join stg._Collection.Communications c on c.CommunicationType	 = take230FZ.CommunicationTypeId
		and c.Date>= take230FZ.CommunicationTypeDateFrom
		/*Результат коммуникации не учитываем 18-12-2025 по требованию https://tracker.yandex.ru/BP-406*/
	--and c.CommunicationResultId = take230FZ.CommunicationResultId
	--	and c.Date>=take230FZ.CommunicationResultDateFrom
	left join [Stg].[_Collection].[Deals]  d			   on d.Id = c.IdDeal
   LEFT JOIN [Stg].[_Collection].[customers] cust          ON cust.id=isnull(c.CustomerId, d.IdCustomer)
where c.Date >= @startReloadDate


	if exists(select top(1) 1 from #tResult)
	begin
		if OBJECT_ID('dm.230Fz_communication_text') is null
		begin
			select top(0)
				communication_guid			
				,external_communication_id	
				,method_code
				,template_code
				,contact_value		
				,clientGuid
				,contractGuid
				,system_code
				,communication_createAt		
				,communication_updated_at		
				,created_at
				,updated_at	
			into dm.[230Fz_communication_text]
			from #tResult
			create clustered index cix_communication_guid on dm.[230Fz_communication_text](communication_guid)
			create index ix_communication_updated_at on dm.[230Fz_communication_text](communication_updated_at)
				
		end
		begin tran
			if @isReloadAll = 1
				begin
					truncate  table dm.[230Fz_communication_text]
				end

			merge dm.[230Fz_communication_text] t
			using #tResult s on s.communication_guid = t.communication_guid

			when not matched then insert
			(
				 communication_guid			
				,external_communication_id	
				,method_code
				,template_code
				,clientGuid
				,contractGuid
				,contact_value		
				,system_code
				,communication_createAt		
				,communication_updated_at		
				,created_at
				,updated_at		
			)
			values
			(
				communication_guid			
				,external_communication_id	
				,method_code
				,template_code
				,clientGuid
				,contractGuid
				,contact_value
				,system_code
				,communication_createAt		
				,communication_updated_at		
				,created_at
				,updated_at		
			)
			when matched  
			then update
				set 
					 external_communication_id	= s.external_communication_id	 
					,method_code				= s.method_code			
					,clientGuid					= s.clientGuid
					,contractGuid				= s.contractGuid
					,template_code				= s.template_code				
					,contact_value				= s.contact_value		
					,system_code				= s.system_code
					,communication_createAt		= s.communication_createAt		
					,communication_updated_at	= s.communication_updated_at		
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

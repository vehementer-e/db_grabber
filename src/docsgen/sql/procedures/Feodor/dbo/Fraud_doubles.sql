--select * from dbo.dm_FeodorRequests_test where ClientRequestNumber = '23103021354883'
--exec feodor.dbo.Fraud_doubles_test 'C3F95852-BF2F-47D3-AD74-2BFF43C18A5B'
-- c3f95852-bf2f-47d3-ad74-2bff43c18a5b
-- exec  [dbo].[Fraud_doubles] '67811236-a3db-4e9c-9985-da82f0297989'



CREATE PROC [dbo].[Fraud_doubles] @ClientRequestId  uniqueidentifier
	,@isDebug int = 0
as
begin
--declare @ClientRequestId uniqueidentifier =  '9A9F470A-D5CA-11EA-A2EE-00505683924B'
	--set @ClientRequestId =  'AADD513F-6463-436F-B1AD-0DB62C5B39DB'
--	set @ClientRequestId =  '4CC0F964-CFE9-4E15-BCA2-A00221015C30'
	
	
	--set statistics time off
	set nocount ON
    
	SELECT @isDebug = isnull(@isDebug, 0)

	Declare @isLogging int = 1

	Declare @ExecutingTimeBegin datetime2 = GetDate()

	Declare @strMessage nvarchar(300) = 'Starting Fraud_doubles id: ' + cast(@ClientRequestId as nvarchar(64))
	--select @strMessage
	--drop table if exists #FeodorRequests

	--if @isLogging = 1
	--begin
	--	exec [LogAndSendMailToAdmin] 'Fraud_doubles'
	--	,                            'Info'
	--	,                            'Starting Fraud_doubles'
	--	,                            @strMessage
	--end

	--if @isLogging = 1
	--begin
	--	exec [LogAndSendMailToAdmin] 'Fraud_doubles','Info','Start load from Feodor by timestamp','Starting load new data from Feodor'
	--end
	-- загрузим актуальные данные федор в витрину
	--exec stg.[_fedor].[fedor2DWHLoader_timestamp]


	--print '0'

	drop table if exists #resultTable

	create table #resultTable ( searchRule                    nvarchar(100)
	,                           ClientRequestId               uniqueidentifier
	,                           OriginalField                 nvarchar(150)
	,                           DuplicateField                nvarchar(150)
	,                           FieldValue                    nvarchar(4000)
	-- 11-08-2020
	,                           ClientName                    nvarchar(304)
	,                           ClientBirthDay                date
	,                           ClientRequestNumber           nvarchar(255)
	,                           ClientRequestCreatedOn        datetime
	--BP-1632
	,							StatusName nvarchar(255)
	,							TableSource nvarchar(255)
	,							isNotView int
)



	declare @ReturnClientRequestId uniqueidentifier
	declare @ReturnDuplicateField nvarchar(50)
	declare @ReturnOriginalField nvarchar(50)
	declare @ReturnFieldValue nvarchar(255)
	
	declare @ClientName                          nvarchar(255)
	,		@ClientFIO                           nvarchar(255)
	,       @ClientContactPersonName             nvarchar(255)
	,       @ClientBirthDay                      date
	,       @ClientAddressRegistrationPostalCode nvarchar(255)   
	,       @ClientAddressRegistrationStreet     nvarchar(255)   
	,       @ClientWorkplaceAddressPostalCode    nvarchar(255)   
	,       @ClientWorkplaceAddressStreet        nvarchar(255)   
	,       @ClientAddressStayPostalCode         nvarchar(255)   
	,       @ClientAddressStayStreet             nvarchar(255)   
	,       @AuthorAddressStayPostalCode         nvarchar(255)   
	,       @AuthorAddressStayStreet             nvarchar(255)   
	,       @AuthorAddressRegistrationPostalCode nvarchar(255)   
	,       @AuthorAddressRegistrationStreet     nvarchar(255)   
	,       @ClientWorkPlacePhone                nvarchar(10)    
	,       @ClientPhoneMobile                   nvarchar(10)    
	,       @ClientPhoneHome                     nvarchar(10)    
	,       @ClientContactPersonPhone            nvarchar(10)    
	,       @AuthorPhone                         nvarchar(10)    
	,       @ClientPassport                      nvarchar(20)    
	,       @AuthorPassport                      nvarchar(20)    
	,       @VIN                                 nvarchar(50)    
	,       @ClientAddressRegistrationHouse      nvarchar(50)    
	,       @ClientWorkplaceAddressHouse         nvarchar(50)    
	,       @ClientAddressStayHouse              nvarchar(50)    
	,       @AuthorAddressStayHouse              nvarchar(50)    
	,       @AuthorAddressRegistrationHouse      nvarchar(50)    
	-- 11-08-2020
	,       @ClientRequestNumber                 nvarchar(255)   
	,       @ClientRequestCreatedOn              datetime        
	,		@StatusName	 nvarchar(255)
	,		@RowVersion binary(8)

	select 
		@ClientName=ClientName
	,	@ClientFIO = ClientFIO
	,   @ClientBirthDay = ClientBirthDay
	,	@vin =VIN
	,	@ClientContactPersonName=ClientContactPersonName
	,	@ClientAddressRegistrationPostalCode =ClientAddressRegistrationPostalCode
	,	@ClientAddressRegistrationStreet =ClientAddressRegistrationStreet
	,	@ClientAddressRegistrationHouse = ClientAddressRegistrationHouse
	,	@ClientWorkplaceAddressPostalCode =ClientWorkplaceAddressPostalCode
	,	@ClientWorkplaceAddressStreet =ClientWorkplaceAddressStreet
	,	@ClientWorkplaceAddressHouse =ClientWorkplaceAddressHouse
	,	@ClientAddressStayPostalCode =ClientAddressStayPostalCode
	,	@ClientAddressStayStreet =ClientAddressStayStreet
	,	@ClientAddressStayHouse =ClientAddressStayHouse
	,	@AuthorAddressStayPostalCode =AuthorAddressStayPostalCode
	,	@AuthorAddressStayStreet =AuthorAddressStayStreet
	,	@AuthorAddressStayHouse =AuthorAddressStayHouse
	,	@AuthorAddressRegistrationPostalCode =AuthorAddressRegistrationPostalCode
	,	@AuthorAddressRegistrationStreet =AuthorAddressRegistrationStreet
	,	@AuthorAddressRegistrationHouse =AuthorAddressRegistrationHouse
	,	@ClientWorkPlacePhone =ClientWorkPlacePhone
	,	@ClientPhoneMobile =ClientPhoneMobile
	,	@ClientPhoneHome =ClientPhoneHome
	,	@ClientContactPersonPhone =ClientContactPersonPhone
	,	@AuthorPhone =AuthorPhone
	,	@ClientPassport =ClientPassport
	,	@AuthorPassport =AuthorPassport
	-- 11-08-2020
	,  @ClientRequestNumber =ClientRequestNumber
	,  @ClientRequestCreatedOn =ClientRequestCreatedOn
	,  @StatusName= ClientRequestStatusName
	,  @RowVersion = RowVersion
	
	from dbo.v_dm_FeodorRequests
	where ClientRequestId = @ClientRequestId
	--берем данные с феди
	order by TableSource desc


	--select 
	-- ClientName                          = @ClientName                          
	--,ClientContactPersonName             = @ClientContactPersonName             
	--,ClientBirthDay                      = @ClientBirthDay                      
	--,ClientAddressRegistrationPostalCode = @ClientAddressRegistrationPostalCode 
	--,ClientAddressRegistrationStreet     = @ClientAddressRegistrationStreet     
	--,ClientWorkplaceAddressPostalCode    = @ClientWorkplaceAddressPostalCode    
	--,ClientWorkplaceAddressStreet        = @ClientWorkplaceAddressStreet        
	--,ClientAddressStayPostalCode         = @ClientAddressStayPostalCode         
	--,ClientAddressStayStreet             = @ClientAddressStayStreet             
	--,AuthorAddressStayPostalCode         = @AuthorAddressStayPostalCode         
	--,AuthorAddressStayStreet             = @AuthorAddressStayStreet             
	--,AuthorAddressRegistrationPostalCode = @AuthorAddressRegistrationPostalCode 
	--,AuthorAddressRegistrationStreet     = @AuthorAddressRegistrationStreet     
	--,ClientWorkPlacePhone                = @ClientWorkPlacePhone                
	--,ClientPhoneMobile                   = @ClientPhoneMobile                   
	--,ClientPhoneHome                     = @ClientPhoneHome                     
	--,ClientContactPersonPhone            = @ClientContactPersonPhone            
	--,AuthorPhone                         = @AuthorPhone                         
	--,ClientPassport                      = @ClientPassport                      
	--,AuthorPassport                      = @AuthorPassport                      
	--,VIN                                 = @VIN                                 
	--,ClientAddressRegistrationHouse      = @ClientAddressRegistrationHouse      
	--,ClientWorkplaceAddressHouse         = @ClientWorkplaceAddressHouse         
	--,ClientAddressStayHouse              = @ClientAddressStayHouse              
	--,AuthorAddressStayHouse              = @AuthorAddressStayHouse              
	--,AuthorAddressRegistrationHouse      = @AuthorAddressRegistrationHouse      

	
	----
	---- выводим в дубли завяки этого же клиента
	----
	--set statistics io ON
    /*
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, StatusName)
	select searchRule = 'FindDuplicateRule00'
	,      t.ClientRequestId
	,      OriginalField = 'ClientName'
	,      DuplicateField = 'ClientName'
	,      FieldValue = [ContactPersonName]
	,      t.ClientName
	,      t.ClientBirthDay
	,      t.ClientRequestNumber
	,      t.ClientRequestCreatedOn
	,	   t.ClientRequestStatusName 
	from [dbo].[v_dm_FeodorRequests_ClientContactPersons] t
	where t.ClientRequestId != @ClientRequestId
		and t.ClientName=@ClientName
		and t.ClientBirthDay=@ClientBirthDay
	*/
	--DWH-1454
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, StatusName, TableSource)
	select searchRule = 'FindDuplicateRule00'
	,      t.ClientRequestId
	,      OriginalField = 'ClientName'
	,      DuplicateField = 'ClientName'
	,      FieldValue = t.ClientName --[ContactPersonName]
	,      t.ClientName
	,      t.ClientBirthDay
	,      t.ClientRequestNumber
	,      t.ClientRequestCreatedOn
	,	   t.ClientRequestStatusName 
	,	   t.TableSource
	--from [dbo].[v_dm_FeodorRequests_ClientContactPersons] t
	FROM dbo.dm_FeodorRequests_test  AS t with(nolock)
	where t.ClientRequestId != @ClientRequestId
		and (t.ClientName=@ClientName OR t.ClientFIO = @ClientFIO)
		and t.ClientBirthDay=@ClientBirthDay
		AND nullif(@ClientBirthDay, '0001-01-01') IS NOT NULL
	
	--select * from  Feodor.dbo.dm_FeodorRequests_test where ClientRequestNumber='20090800031701'

	--print '2'

	if nullif(@ClientName,'') is not null
		and @ClientName=isnull(@ClientContactPersonName,'')
	begin

		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, StatusName, TableSource)
		select 'FindDuplicateRule01'
		,      @ClientRequestId
		,      'ClientName'
		,      'ContactPersonName'
		,      @ClientName
		--11-08-2020
		,      @ClientName
		,      @ClientBirthDay
		,      @ClientRequestNumber
		,      @ClientRequestCreatedOn
		,	   @StatusName
		,	   TableSource = 'F' --??
		
	end
	
	
	--
	-- FindDuplicateRule02
	--

	--    /// <summary>
	--    /// Ищем по ФИО клиента заявки, в которых он указан КЛ и/или 3м лицом
	--    /// </summary>
	--    public class FindDuplicateRule02 : IFraudRule
	--declare @ClientContactPersonName nvarchar(255)
	if @ClientName<>''
	begin
		with cte_t as
		(
			select 
				 t.ClientRequestId
				,t.ClientName
				,t.ClientBirthDay
				,t.ClientRequestNumber
				,t.ClientRequestCreatedOn
				,t.ClientRequestStatusName 
				,t.ContactPersonName
				,t.ClientContactPersonType
				,t.TableSource
			from dbo.[v_dm_FeodorRequests_ClientContactPersons] t
				where t.ClientRequestId!=@ClientRequestId
		), cte_FindDuplicateRule02 as
		(
			select *
			, original= 'ClientName' 
			, dublicate = 'ContactPersonName' 
			, d_value = ContactPersonName  
			from cte_t t
			where ContactPersonName=@ClientName
				OR ContactPersonName = @ClientFIO
			and ClientContactPersonType = 'ClientContactPerson'
			union
			select 
				*
				, original = 'ClientName' 
				, dublicate = 'ThirdPersonName' 
				, d_value = ContactPersonName 
			from cte_t t
			where ContactPersonName=@ClientName
				OR ContactPersonName = @ClientFIO
			and ClientContactPersonType = 'ThirdPersonName'
		)
		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, StatusName, TableSource)
		select 'FindDuplicateRule02'
			,      ClientRequestId
			,      original
			,      dublicate
			,      d_value
			,      ClientName
			,      ClientBirthDay
			,      ClientRequestNumber
			,      ClientRequestCreatedOn
			,	   ClientRequestStatusName
			,	   TableSource
			from cte_FindDuplicateRule02
	end
	
	
	; with t
	as
	(
		select	
			 t.ClientRequestId
			,t.ClientName
			,t.ClientBirthDay
			,t.ClientRequestNumber
			,t.ClientRequestCreatedOn
			,t.ClientRequestStatusName 
			,t.ClientAddressType
			,t.PostalCode
			,t.Address	
			,t.Street	
			,t.House
			,t.TableSource
		from dbo.[v_dm_FeodorRequests_ClientAddress] t
		where t.ClientRequestId!=@ClientRequestId
			--and not(
			--	t.ClientName=@ClientName
			--	and t.ClientBirthDay=@ClientBirthDay)
	)
	,      t1
	as
	(
		select distinct *                          
		,      'ClientAddressRegistration' original
		,      'ClientAddressRegistration' dublicate
		,      t.Address   d_value
		
		from t
		where 
			t.ClientAddressType = 'ClientAddressRegistration'
			and (t.PostalCode=@ClientAddressRegistrationPostalCode and @ClientAddressRegistrationPostalCode<>'')
			and (t.Street= @ClientAddressRegistrationStreet and @ClientAddressRegistrationStreet<>'')
			and (isnull(t.House,'') = isnull(@ClientAddressRegistrationHouse,''))
		
		union
		select *
		,      'ClientWorkplaceAddress'
		,      'ClientWorkplaceAddress'
		,      t.Address
		from t
		where t.ClientAddressType = 'ClientWorkplaceAddress'
			and (t.PostalCode=@ClientWorkplaceAddressPostalCode and @ClientWorkplaceAddressPostalCode<>'')
			and (t.Street=@ClientWorkplaceAddressStreet and @ClientWorkplaceAddressStreet<>'')
			and (isnull(t.House,'') = isnull(@ClientWorkplaceAddressHouse,''))
			
		union
		select distinct *
		,      'ClientAddressStay'
		,      'ClientAddressStay'
		,      t.Address
		from t
		where t.ClientAddressType  = 'ClientAddressStay'
			and (t.PostalCode =@ClientAddressStayPostalCode and @ClientAddressStayPostalCode<>'')
			and (t.Street =  @ClientAddressStayStreet and @ClientAddressStayStreet<>'')
			and (isnull(t.House,'') = isnull(@ClientAddressStayHouse,''))
			
		union
		select *
		,      'AuthorAddressRegistration'
		,      'ClientAddressRegistration'
		,      Address
		from t
		where t.ClientAddressType = 'ClientAddressRegistration'
			and (t.PostalCode	=  @AuthorAddressRegistrationPostalCode and @AuthorAddressRegistrationPostalCode<>'')
			and (t.Street		= @AuthorAddressRegistrationStreet and @AuthorAddressRegistrationStreet<>'')
			and (isnull(t.House,'')	= isnull(@AuthorAddressRegistrationHouse,''))
			
		union
		select *
		,      'AuthorAddressRegistration'
		,      'ClientWorkplaceAddress'
		,      t.Address
		from t
		where t.ClientAddressType = 'ClientWorkplaceAddress'
			and (t.PostalCode	= @AuthorAddressRegistrationPostalCode and @AuthorAddressRegistrationPostalCode<>'')
			and (t.Street		= @AuthorAddressRegistrationStreet and @AuthorAddressRegistrationStreet<>'')
			and (isnull(t.House,'')	= isnull(@AuthorAddressRegistrationHouse,''))
			
		union
		select *
		,      'AuthorAddressRegistration'
		,      'ClientAddressStay'
		,      Address
		from t
		where 
			t.ClientAddressType = 'ClientAddressStay'
			and (t.PostalCode	= @AuthorAddressRegistrationPostalCode and @AuthorAddressRegistrationPostalCode<>'')
			and (t.Street		= @AuthorAddressRegistrationStreet and @AuthorAddressRegistrationStreet<>'')
			and (isnull(t.House,'')	= isnull(@AuthorAddressRegistrationHouse,''))
		
		
		union
		select *
		,      'AuthorAddressStay'
		,      'ClientAddressRegistration'
		,      Address
		from t
		where 
			t.ClientAddressType = 'ClientAddressRegistration'
			and (t.PostalCode	= @AuthorAddressStayPostalCode and @AuthorAddressStayPostalCode<>'')
			and (t.Street		= @AuthorAddressStayStreet and @AuthorAddressStayStreet<>'')
			and (isnull(t.House,'')	= isnull(@AuthorAddressStayHouse,''))
			
		union
		select *
		,      'AuthorAddressStay'
		,      'ClientWorkplaceAddress'
		,      Address
		from t
		where 
			t.ClientAddressType = 'ClientWorkplaceAddress'
			and (t.PostalCode	= @AuthorAddressStayPostalCode and @AuthorAddressStayPostalCode<>'')
			and (t.Street		= @AuthorAddressStayStreet and @AuthorAddressStayStreet <>'')
			and (isnull(t.House,'')	= isnull(@AuthorAddressStayHouse,''))
			
		union
		select *
		,      'AuthorAddressStay'
		,      'ClientAddressStay'
		,      Address
		from t
		where 
			t.ClientAddressType = 'ClientAddressStay'
			and (t.PostalCode	= @AuthorAddressStayPostalCode and @AuthorAddressStayPostalCode<>'')
			and (t.Street		= @AuthorAddressStayStreet and @AuthorAddressStayStreet <>'')
			and (isnull(t.House,'')	= isnull(@AuthorAddressStayHouse,''))
	)
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn,  StatusName, TableSource)
	select distinct 'FindDuplicateRule04'
	,      ClientRequestId
	,      original
	,      dublicate
	,      d_value
	,      ClientName
	,      ClientBirthDay
	,      ClientRequestNumber
	,      ClientRequestCreatedOn
	,	  ClientRequestStatusName
	,	 TableSource

	from t1
	
	
	; with t
	as
	(
		select 
			[ClientRequestId], 
			[ClientName], 
			[ClientBirthDay], 
			[ClientRequestNumber], 
			[ClientRequestCreatedOn], 
			[ClientRequestStatusName], 
			[ClientPhoneType], 
			[Phone],
			TableSource
		from dbo.v_dm_FeodorRequests_ClientPhones t
		where ClientRequestId!=@ClientRequestId
		
		--union
		--select 
		--	[ClientRequestId], 
		--	[ClientName], 
		--	[ClientBirthDay], 
		--	[ClientRequestNumber], 
		--	[ClientRequestCreatedOn], 
		--	[ClientRequestStatusName], 
		--	[ClientPhoneType], 
		--	[Phone],
		--	TableSource			
		--from dbo.v_dm_FeodorRequests_ClientPhones
		--where ClientRequestId!=@ClientRequestId

			--and not(
			--	ClientName=@ClientName
			--	and ClientBirthDay=@ClientBirthDay)
	)
	,      t1
	as
	(
		select *                     
		,      'ClientWorkPlacePhone' original
		,      'ClientWorkPlacePhone' doublicate
		,      [Phone]   d_value
		from t 
		where (Phone = @ClientWorkPlacePhone and @ClientWorkPlacePhone<>'')
			and [ClientPhoneType] = 'ClientWorkPlacePhone'
		union
		select *
		,      'ClientWorkPlacePhone'
		,      'ClientPhoneMobile'
		,      [Phone]
		from t 
		where 
			(Phone = @ClientWorkPlacePhone and @ClientWorkPlacePhone<>'')
			and [ClientPhoneType] = 'ClientPhoneMobile'
		union
		select *
		,      'ClientWorkPlacePhone'
		,      'ClientPhoneHome'
		,      Phone
		from t 
		where 
			(Phone = @ClientWorkPlacePhone and @ClientWorkPlacePhone<>'')
			and [ClientPhoneType] = 'ClientPhoneHome'
		union
		select *
		,      'ClientWorkPlacePhone'
		,      'ClientContactPersonPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where 
		(Phone = @ClientWorkPlacePhone and @ClientWorkPlacePhone<>'')
			and [ClientPhoneType] = 'ClientContactPersonPhone'
		union
		select *
		,      'ClientWorkPlacePhone'
		,      'AuthorPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientWorkPlacePhone and @ClientWorkPlacePhone<>'')
			and [ClientPhoneType] = 'AuthorPhone'
		union
		select *
		,      'ClientPhoneMobile'
		,      'ClientPhoneMobile'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientPhoneMobile and @ClientPhoneMobile<>'')
			and [ClientPhoneType] = 'ClientPhoneMobile'
		union
		select *
		,      'ClientPhoneMobile'
		,      'ClientPhoneHome'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientPhoneMobile and @ClientPhoneMobile<>'')
			and [ClientPhoneType] = 'ClientPhoneHome'
		union
		select *
		,      'ClientPhoneMobile'
		,      'ClientContactPersonPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientPhoneMobile and @ClientPhoneMobile<>'')
			and [ClientPhoneType] = 'ClientContactPersonPhone'
		union
		select *
		,      'ClientPhoneMobile'
		,      'AuthorPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientPhoneMobile and @ClientPhoneMobile<>'')
			and [ClientPhoneType] = 'AuthorPhone'
		union
		select *
		,      'ClientPhoneHome'
		,      'ClientPhoneHome'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientPhoneHome and @ClientPhoneHome<>'')
			and [ClientPhoneType] = 'ClientPhoneHome'
		union
		select *
		,      'ClientPhoneHome'
		,      'ClientContactPersonPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientPhoneHome and @ClientPhoneHome<>'')
			and [ClientPhoneType] = 'ClientContactPersonPhone'
		union
		select *
		,      'ClientPhoneHome'
		,      'AuthorPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientPhoneHome and @ClientPhoneHome<>'')
			and [ClientPhoneType] = 'AuthorPhone'

		union
		select *
		,      'ClientContactPersonPhone'
		,      'ClientContactPersonPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientContactPersonPhone and @ClientContactPersonPhone<>'')
			and [ClientPhoneType] = 'ClientContactPersonPhone'
		
		union
		select *
		,      'ClientContactPersonPhone'
		,      'AuthorPhone'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where (Phone = @ClientContactPersonPhone and @ClientContactPersonPhone<>'')
			and [ClientPhoneType] = 'AuthorPhone'
		
		union 
		select *
		,      'ClientContactPersonPhone'
		,      'ClientPhoneMobile'
		,      Phone
		from t /*from Feodor.dbo.dm_FeodorRequests_test */
		where 
		 (Phone = @ClientContactPersonPhone and @ClientContactPersonPhone<>'')
			and [ClientPhoneType] = 'ClientPhoneMobile'
		
		union 
		select *
		,      'ClientContactPersonPhone'
		,      'ClientWorkPlacePhone'
		,      Phone
		from t 
		where (Phone = @ClientContactPersonPhone and @ClientContactPersonPhone<>'')
			and [ClientPhoneType] = 'ClientWorkPlacePhone'
		
	)
	
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, StatusName, TableSource)
	select 'FindDuplicateRule05'
	,      ClientRequestId
	,      original
	,      doublicate
	,      d_value
	,      ClientName
	,      ClientBirthDay
	,      ClientRequestNumber
	,      ClientRequestCreatedOn
	,	   ClientRequestStatusName
	,	   TableSource
	from t1
	
	
	;with t
	as
	(
		select *
		from dbo.v_dm_FeodorRequests_ClientPassports
		where ClientRequestId!=@ClientRequestId
			--and not(
			--	ClientName=@ClientName
			--	and ClientBirthDay=@ClientBirthDay)
		
	), cte_rule as
	(
		select searchRule = 'FindDuplicateRule06'
		,      ClientRequestId
		,      OriginalField = 'ClientPassport'
		,      DuplicateField = 'ClientPassport'
		,      FieldValue = Passport
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,	   StatusName = ClientRequestStatusName
		,	   t.TableSource
		from t
		where Passport = @ClientPassport
		and PassportType = 'ClientPassport'

		union 
		select searchRule = 'FindDuplicateRule10'
		,      ClientRequestId
		,      OriginalField = 'AuthorPassport'
		,      DuplicateField =  'ClientPassport'
		,      FieldValue = Passport
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,	   StatusName = ClientRequestStatusName
		,	   t.TableSource

		from t
		where  (Passport = @AuthorPassport and @AuthorPassport<>'')
		and PassportType = 'ClientPassport' --'AuthorPassport'
	)
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn,  StatusName, TableSource)
	
	select 
		searchRule, 
		ClientRequestId, 
		OriginalField, 
		DuplicateField, 
		FieldValue, 
		ClientName, 
		ClientBirthDay, 
		ClientRequestNumber, 
		ClientRequestCreatedOn, 
		StatusName,
		TableSource
	from cte_rule
	
	
	--    /// <summary>
	--    /// Ищем фио клиента и фио КЛ в списке сотрудников и сотрудников Партнёра
	--    /// </summary>
	
		;with t as
		(
			select * 
				from [dbo].[v_dm_FeodorRequests_ClientContactPersons]
			where @ClientRequestId <> ClientRequestId
		),cte_FindDuplicateRule07 as 
		(
			select 
			*
				, OriginalField = 'ClientName'
				, DuplicateField = 'AuthorName'
				, d_value = [ContactPersonName]
			from t 
			where ([ContactPersonName] = @ClientName and @ClientName <> '')
				and [ClientContactPersonType] = 'AuthorName'
			union

			select 
			*
				, OriginalField = 'ContactPersonName'
				, DuplicateField = 'AuthorName'
				, d_value = [ContactPersonName]
			from t 
			where ([ContactPersonName] = @ClientContactPersonName and @ClientContactPersonName<> '')
			and [ClientContactPersonType] = 'AuthorName'
		)

		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn,  StatusName, TableSource)
		select 'FindDuplicateRule07'
			, ClientRequestId
			, OriginalField
			, DuplicateField
			, d_value
			, ClientName
			, ClientBirthDay
			, ClientRequestNumber
			, ClientRequestCreatedOn
			, ClientRequestStatusName
			, TableSource
		from cte_FindDuplicateRule07


	

	--print '8'
	--
	-- FindDuplicateRule10
	--

	--    /// <summary>
	--    /// Ищем серию+номер паспорта пользователя-автора в заявках, исключаем заявки текущего клиента
	--    /// </summary>
	
	

	
	--
	-- FindDuplicateRule11
	--

	--     /// <summary>
	--    /// Ищем VIN из текущей заявки в заявках ДРУГИХ клиентов
	--    /// </summary>
	
		;with cte as
		(
			select * from [v_dm_FeodorRequests_vin]
			where  ClientRequestId != @ClientRequestId
			
			--and not(
			--	ClientName=@ClientName
			--	and ClientBirthDay=@ClientBirthDay)	
		),cte_FindDuplicateRule11 as
		(
			select *
				,searchRule = 'FindDuplicateRule11'
				, OriginalField = 'VIN'
				, DuplicateField = 'VIN'
				, FieldValue = VIN
				, StatusName = ClientRequestStatusName
		from cte r
		where [Vin] = @vin
		)


		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, StatusName, TableSource)
		
		select 
			searchRule, 
			ClientRequestId, 
			OriginalField, 
			DuplicateField, 
			FieldValue,
			ClientName, 
			ClientBirthDay, 
			ClientRequestNumber, 
			ClientRequestCreatedOn, 
			StatusName,
			TableSource
		from cte_FindDuplicateRule11

	-- не выводить найденные записи из 'M' если есть точно такие же из 'F'
	UPDATE M SET isNotView = 1
	FROM #resultTable AS M
		INNER JOIN #resultTable AS F
			ON M.TableSource = 'M'
			AND F.TableSource = 'F'
			AND M.searchRule = F.searchRule
			AND M.ClientRequestId = F.ClientRequestId
			AND M.OriginalField = F.OriginalField
			AND M.DuplicateField = F.DuplicateField
			AND M.ClientRequestNumber = F.ClientRequestNumber
			AND M.FieldValue = F.FieldValue
			AND M.ClientName = F.ClientName
			and M.StatusName = f.StatusName

	DELETE M
	FROM #resultTable AS M
	WHERE isNotView = 1
	--// не выводить найденные записи из 'M' если есть точно такие же из 'F'


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##resultTable
		SELECT * INTO ##resultTable FROM #resultTable
	END
	
	/*
	--set statistics time off

	DECLARE @tableHTML NVARCHAR(MAX) ;

	SET @tableHTML =
	N'<H1>Ответ федору</H1>' +
	N'<table border="1">' +
	N'<tr><th>searchRule</th><th>ClientRequestId</th>' +
	N'<th>OriginalField</th><th>DuplicateField</th><th>FieldValue</th>' +
	N'<th>ClientName</th><th> ClientBirthDay</th><th>ClientRequestNumber </th>' +
	N'<th>OClientRequestCreatedOn</th>' +
	N'<th>StatusName</th>'+
	N'</tr>' +
	CAST ( ( SELECT td = searchRule                   
	,               ''                                
	,               td = ClientRequestId              
	,               ''                                
	,               td = OriginalField                
	,               ''                                
	,               td = DuplicateField               
	,               ''                                
	,               td = FieldValue                   
	,               ''                                
	,               td = ClientName                   
	,               ''                                
	,               td = ClientBirthDay               
	,               ''                                
	,               td = ClientRequestNumber          
	,               ''                                
	,               td = ClientRequestCreatedOn       
	,               ''                                
	,				td = StatusName
	from #resultTable


	FOR XML PATH('tr'), TYPE
	) AS NVARCHAR(MAX) ) +
	N'</table>' ;

	--  select @tableHTML
	
	declare @subject1 nvarchar(1000) = 'Ответ федору по заявке '+ cast(@ClientRequestId as nvarchar(64))
  /*
EXEC msdb.dbo.sp_send_dbmail @recipients='dwh112@carmoney.ru',  
    @profile_name = 'Default',  
    @subject = @subject1,  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  
    */
	*/
	select 
	 searchRule                    
		,ClientRequestId               
		,OriginalField                 
		,DuplicateField                
		,FieldValue                    
		,ClientName                    
		,ClientBirthDay = nullif(ClientBirthDay, '0001-01-01')
		,ClientRequestNumber           
		,ClientRequestCreatedOn        
		,StatusName
	--	,TableSource
	from #resultTable

	--Declare @ExecutingTimeBegin datetime2 = GetDate()
	Declare @ExecutingTimeEnd datetime2 = GetDate()
	Declare @ExecutionTime int
	Declare @strExecutionTime nvarchar(200) = 'Finished. Time execution: '

	Set @ExecutionTime = DATEDIFF(second,@ExecutingTimeBegin,@ExecutingTimeEnd)
	Set @strExecutionTime = @strExecutionTime + cast(@ExecutionTime as nvarchar(10))

	--Select @strExecutionTime

	--if @isLogging = 1
	--begin
	--	exec [LogAndSendMailToAdmin] 'Fraud_doubles'
	--	,                            'Info'
	--	,                            'Fraud_doubles procedure finished'
	--	,                            @strExecutionTime
	--	exec [LogAndSendMailToAdmin] 'Fraud_doubles'
	--	,                            'Info'
	--	,                            @subject1
	--	,                            @tableHTML
	--end

end

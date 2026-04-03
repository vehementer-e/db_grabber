
--select * from dbo.dm_FeodorRequests where ClientRequestNumber = '1604192160001'
--exec feodor.dbo.Fraud_doubles_test '9A9F470A-D5CA-11EA-A2EE-00505683924B'
-- exec  [dbo].[Fraud_doubles] '03D7D22F-B631-4D30-86D7-7A51C254FFF0'
CREATE procedure [dbo].[Fraud_doubles] @ClientRequestId uniqueidentifier
as
begin
	--set statistics time off
	set nocount on

	--declare @ClientRequestId uniqueidentifier = '961f8a18-da60-4645-a69b-72f83d0e1784'
	--select '1-' + cast(@ClientRequestId as nvarchar(64))
	Declare @isLogging int = 1

	Declare @ExecutingTimeBegin datetime2 = GetDate()

	Declare @strMessage nvarchar(300) = 'Starting Fraud_doubles id: ' + cast(@ClientRequestId as nvarchar(64))
	--select @strMessage
	--drop table if exists #FeodorRequests

	if @isLogging = 1
	begin
		exec [LogAndSendMailToAdmin] 'Fraud_doubles'
		,                            'Info'
		,                            'Starting Fraud_doubles'
		,                            @strMessage
	end

	--if @isLogging = 1
	--begin
	--	exec [LogAndSendMailToAdmin] 'Fraud_doubles','Info','Start load from Feodor by timestamp','Starting load new data from Feodor'
	--end
	-- загрузим актуальные данные федор в витрину
	exec stg.[_fedor].[fedor2DWHLoader_timestamp]


	--print '0'

	drop table if exists #resultTable

	create table #resultTable ( searchRule                    nvarchar(100)
	,                           ClientRequestId               uniqueidentifier
	,                           OriginalField                 nvarchar(150)
	,                           DuplicateField                nvarchar(150)
	,                           FieldValue                    nvarchar(max)
	-- 11-08-2020
	,                           ClientName                    nvarchar(304)
	,                           ClientBirthDay                date
	,                           ClientRequestNumber           nvarchar(255)
	,                           ClientRequestCreatedOn        datetime
	,                           ClientRequestExternalStatusId uniqueidentifier
	--BP-1632
	,							StatusName nvarchar(255)
)



	declare @ReturnClientRequestId uniqueidentifier
	declare @ReturnDuplicateField nvarchar(50)
	declare @ReturnOriginalField nvarchar(50)
	declare @ReturnFieldValue nvarchar(255)

	--
	-- FindDuplicateRule01
	--

	--     /// <summary>
	--    /// Ищем ФИО клиента из текущей заявки в ФИО контактного лица.
	--    /// </summary>
	--    public class FindDuplicateRule01

	--print '1'

	--declare  @ClientRequestId uniqueidentifier

	--select @ClientRequestId=ClientRequestId from #FeodorRequests where ClientRequestCreatedOn=(select max(ClientRequestCreatedOn)  from #FeodorRequests where ClientRequestCreatedOn<cast(getdate() as date))
	--select @ClientRequestId
	declare @ClientName                          nvarchar(255)   =''
	,       @ClientContactPersonName             nvarchar(255)   =''
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
	,       @ClientRequestExternalStatusId       uniqueidentifier
	,		@StatusName	 nvarchar(255)

	select @ClientName=ClientName
	,      @ClientContactPersonName=ClientContactPersonName
	,      @ClientBirthDay = ClientBirthDay
	,      @ClientAddressRegistrationPostalCode =ClientAddressRegistrationPostalCode
	,      @ClientAddressRegistrationStreet =ClientAddressRegistrationStreet
	,      @ClientAddressRegistrationHouse =feodor.dbo.AddressPart([ClientAddressRegistration], 8)
	,      @ClientWorkplaceAddressPostalCode =ClientWorkplaceAddressPostalCode
	,      @ClientWorkplaceAddressStreet =ClientWorkplaceAddressStreet
	,      @ClientWorkplaceAddressHouse =feodor.dbo.AddressPart([ClientWorkplaceAddress], 8)
	,      @ClientAddressStayPostalCode =ClientAddressStayPostalCode
	,      @ClientAddressStayStreet =ClientAddressStayStreet
	,      @ClientAddressStayHouse =feodor.dbo.AddressPart([ClientAddressStay], 8)
	,      @AuthorAddressStayPostalCode =AuthorAddressStayPostalCode
	,      @AuthorAddressStayStreet =AuthorAddressStayStreet
	,      @AuthorAddressStayHouse =feodor.dbo.AddressPart([AuthorAddressStay], 8)
	,      @AuthorAddressRegistrationPostalCode =AuthorAddressRegistrationPostalCode
	,      @AuthorAddressRegistrationStreet =AuthorAddressRegistrationStreet
	,      @AuthorAddressRegistrationHouse =feodor.dbo.AddressPart([AuthorAddressRegistration], 8)
	,      @ClientWorkPlacePhone =ClientWorkPlacePhone
	,      @ClientPhoneMobile =ClientPhoneMobile
	,      @ClientPhoneHome =ClientPhoneHome
	,      @ClientContactPersonPhone =ClientContactPersonPhone
	,      @AuthorPhone =AuthorPhone
	,      @ClientPassport =ClientPassport
	,      @AuthorPassport =AuthorPassport
	,      @vin =VIN
	-- 11-08-2020
	,      @ClientRequestNumber =ClientRequestNumber
	,      @ClientRequestCreatedOn =ClientRequestCreatedOn
	,      @ClientRequestExternalStatusId =ClientRequestExternalStatusId
	,	   @StatusName= ClientRequestExternalStatusName
	from Feodor.dbo.dm_FeodorRequests
	where @ClientRequestId=ClientRequestId
	--берем данные с феди
	order by TableSource desc
	----
	---- выводим в дубли завяки этого же клиента
	----
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId,
		StatusName)
	select 'FindDuplicateRule00'
	,      ClientRequestId
	,      'ClientName'
	,      'ClientName'
	,      ClientName --ClientContactPersonName
	--11-08-2020
	--, @ClientName
	--, @ClientBirthDay
	--, @ClientRequestNumber
	--, @ClientRequestCreatedOn
	--, @ClientRequestExternalStatusId
	--04_09_2020
	,      ClientName
	,      ClientBirthDay
	,      ClientRequestNumber
	,      ClientRequestCreatedOn
	,      ClientRequestExternalStatusId
	,	   ClientRequestExternalStatusName
	from Feodor.dbo.dm_FeodorRequests
	where @ClientRequestId<>ClientRequestId
		and ClientName=@ClientName
		and ClientBirthDay=@ClientBirthDay
		AND nullif(@ClientBirthDay, '0001-01-01') IS NOT NULL

	--select * from  Feodor.dbo.dm_FeodorRequests where ClientRequestNumber='20090800031701'

	--print '2'

	if nullif(@ClientName,'') is not null
		and @ClientName=isnull(@ClientContactPersonName,'')
	begin

		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
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
		,      @ClientRequestExternalStatusId
		,	   @StatusName


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

		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
		select 'FindDuplicateRule02'
		,      ClientRequestId
		,      'ClientName'
		,      'ContactPersonName'
		,      ClientContactPersonName
		--11-08-2020
		--, @ClientName
		--, @ClientBirthDay
		--, @ClientRequestNumber
		--, @ClientRequestCreatedOn
		--, @ClientRequestExternalStatusId
		--04_09_2020
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,      ClientRequestExternalStatusId
		,	   ClientRequestExternalStatusName
		from Feodor.dbo.dm_FeodorRequests
		where @ClientRequestId<>ClientRequestId
			and ClientContactPersonName=@ClientName

		union
		select 'FindDuplicateRule02'
		,      ClientRequestId
		,      'ClientName'
		,      'ThirdPersonName'
		,      ThirdPersonName
		--11-08-2020
		--, @ClientName
		--, @ClientBirthDay
		--, @ClientRequestNumber
		--, @ClientRequestCreatedOn
		--, @ClientRequestExternalStatusId
		--04_09_2020
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,      ClientRequestExternalStatusId
		,	   ClientRequestExternalStatusName
		from Feodor.dbo.dm_FeodorRequests
		where @ClientRequestId<>ClientRequestId
			and ThirdPersonName=@ClientName
	end
	--
	-- FindDuplicateRule03
	--
	--    /// <summary>
	--    /// Ищем по ФИО КЛ заявки, в которых оно указано как КЛ и/или 3е лицо (исключаем текущую заявку)
	--    /// </summary>

	--print '3'
/*
if  @ClientContactPersonName<>''
begin
 insert into #resultTable(
    searchRule     
  , ClientRequestId
  , OriginalField  
  , DuplicateField 
  , FieldValue     
    --11-08-2020
  , ClientName
  , ClientBirthDay
  , ClientRequestNumber
  , ClientRequestCreatedOn
  , ClientRequestExternalStatusId
  )
   select    'FindDuplicateRule03'
           , ClientRequestId
           , 'ContactPersonName'
           , 'ContactPersonName'
           , ClientContactPersonName 
		   		     --11-08-2020
		  --, @ClientName
		  --, @ClientBirthDay
		  --, @ClientRequestNumber
		  --, @ClientRequestCreatedOn
		  --, @ClientRequestExternalStatusId
					--04_09_2020
		  , ClientName
		  , ClientBirthDay
		  , ClientRequestNumber
		  , ClientRequestCreatedOn
		  , ClientRequestExternalStatusId
      from Feodor.dbo.dm_FeodorRequests  where @ClientRequestId<>ClientRequestId and ClientContactPersonName=@ClientContactPersonName 
union 
  select    'FindDuplicateRule03'
           , ClientRequestId
           , 'ContactPersonName'
           , 'ThirdPersonName'
           , ThirdPersonName 
		   		     --11-08-2020
		  --, @ClientName
		  --, @ClientBirthDay
		  --, @ClientRequestNumber
		  --, @ClientRequestCreatedOn
		  --, @ClientRequestExternalStatusId
					--04_09_2020
		  , ClientName
		  , ClientBirthDay
		  , ClientRequestNumber
		  , ClientRequestCreatedOn
		  , ClientRequestExternalStatusId
      from Feodor.dbo.dm_FeodorRequests  where @ClientRequestId<>ClientRequestId and ThirdPersonName=@ClientContactPersonName 
end
*/
	--
	--  FindDuplicateRule04
	--

	--print '4'

	--  /// <summary>
	--  /// Ищем адреса текущей заявки в других заяввках (исключаем заявки текущего клиента)
	--  /// Ищем адрес регистрации и адрес проживания пользователя-автора заявки в заявках, исключаем заявки текущего клиента
	--  /// </summary>

	; with t
	as
	(
		select *
		from Feodor.dbo.dm_FeodorRequests
		where @ClientRequestId<>ClientRequestId
			and not(
				ClientName=@ClientName
				and ClientBirthDay=@ClientBirthDay)
	)
	,      t1
	as
	(
		select *                          
		,      'ClientAddressRegistration' original
		,      'ClientAddressRegistration' dublicate
		,      ClientAddressRegistration   d_value
		
		from t
		where [ClientAddressRegistrationPostalCode]=@ClientAddressRegistrationPostalCode
			and @ClientAddressRegistrationPostalCode<>''
			and ClientAddressRegistrationStreet = @ClientAddressRegistrationStreet
			and @ClientAddressRegistrationStreet<>''
			and feodor.dbo.AddressPart([ClientAddressRegistration], 8)=@ClientAddressRegistrationHouse
		union
		select *
		,      'ClientWorkplaceAddress'
		,      'ClientWorkplaceAddress'
		,      ClientWorkplaceAddress
		from t
		where ClientWorkplaceAddressPostalCode=@ClientWorkplaceAddressPostalCode
			and @ClientWorkplaceAddressPostalCode<>''
			and ClientWorkplaceAddressStreet =@ClientWorkplaceAddressStreet
			and @ClientWorkplaceAddressStreet<>''
			and feodor.dbo.AddressPart( ClientWorkplaceAddress, 8)=@ClientWorkplaceAddressHouse
		union
		select *
		,      'ClientAddressStay'
		,      'ClientAddressStay'
		,      ClientAddressStay
		from t
		where @ClientAddressStayPostalCode=ClientAddressStayPostalCode
			and @ClientAddressStayPostalCode<>''
			and @ClientAddressStayStreet=ClientAddressStayStreet
			and @ClientAddressStayStreet<>''
			and feodor.dbo.AddressPart( ClientAddressStay, 8)=@ClientAddressStayHouse

		--union select *,'AuthorAddressRegistration','AuthorAddressRegistration',AuthorAddressRegistration from t
		--where @AuthorAddressRegistrationPostalCode<>'' and  @AuthorAddressRegistrationPostalCode=AuthorAddressRegistrationPostalCode and @AuthorAddressRegistrationStreet=AuthorAddressRegistrationStreet and  @AuthorAddressRegistrationStreet<>''

		union
		select *
		,      'AuthorAddressRegistration'
		,      'ClientAddressRegistration'
		,      ClientAddressRegistration
		from t
		where @AuthorAddressRegistrationPostalCode<>''
			and @AuthorAddressRegistrationPostalCode=ClientAddressRegistrationPostalCode
			and @AuthorAddressRegistrationStreet=ClientAddressRegistrationStreet
			and @AuthorAddressRegistrationStreet<>''
			and feodor.dbo.AddressPart( ClientAddressRegistration, 8)=@AuthorAddressRegistrationHouse

		union
		select *
		,      'AuthorAddressRegistration'
		,      'ClientWorkplaceAddress'
		,      ClientWorkplaceAddress
		from t
		where @AuthorAddressRegistrationPostalCode<>''
			and @AuthorAddressRegistrationPostalCode=ClientWorkplaceAddressPostalCode
			and @AuthorAddressRegistrationStreet=ClientWorkplaceAddressStreet
			and @AuthorAddressRegistrationStreet<>''
			and feodor.dbo.AddressPart(ClientWorkplaceAddress, 8)=@AuthorAddressRegistrationHouse
		union
		select *
		,      'AuthorAddressRegistration'
		,      'ClientAddressStay'
		,      ClientAddressStay
		from t
		where @AuthorAddressRegistrationPostalCode<>''
			and @AuthorAddressRegistrationPostalCode=ClientAddressStayPostalCode
			and @AuthorAddressRegistrationStreet=ClientAddressStayStreet
			and @AuthorAddressRegistrationStreet<>''
			and feodor.dbo.AddressPart(ClientAddressStay, 8)=@AuthorAddressRegistrationHouse

		--union select *,'AuthorAddressStay','AuthorAddressStay',AuthorAddressStay from t
		--where @AuthorAddressStayPostalCode<>'' and @AuthorAddressStayPostalCode=AuthorAddressStayPostalCode and @AuthorAddressStayStreet=AuthorAddressStayStreet  and @AuthorAddressStayStreet<>''
		union
		select *
		,      'AuthorAddressStay'
		,      'ClientAddressRegistration'
		,      ClientAddressRegistration
		from t
		where @AuthorAddressStayPostalCode<>''
			and @AuthorAddressStayPostalCode=ClientAddressRegistrationPostalCode
			and @AuthorAddressStayStreet=ClientAddressRegistrationStreet
			and @AuthorAddressStayStreet<>''
			--and feodor.dbo.AddressPart(AuthorAddressStay, 8)=@ClientAddressRegistrationHouse
			and feodor.dbo.AddressPart(ClientAddressRegistration, 8)=@AuthorAddressStayHouse --DWH-1454

		union
		select *
		,      'AuthorAddressStay'
		,      'ClientWorkplaceAddress'
		,      ClientWorkplaceAddress
		from t
		where @AuthorAddressStayPostalCode<>''
			and @AuthorAddressStayPostalCode=ClientWorkplaceAddressPostalCode
			and @AuthorAddressStayStreet=ClientWorkplaceAddressStreet
			and @AuthorAddressStayStreet<>''
			--and feodor.dbo.AddressPart(AuthorAddressStay, 8)=@ClientWorkplaceAddressHouse
			and feodor.dbo.AddressPart(ClientWorkplaceAddress, 8)=@AuthorAddressStayHouse --DWH-1454

		union
		select *
		,      'AuthorAddressStay'
		,      'ClientAddressStay'
		,      ClientAddressStay
		from t
		where @AuthorAddressStayPostalCode<>''
			and @AuthorAddressStayPostalCode=ClientAddressStayPostalCode
			and @AuthorAddressStayStreet=ClientAddressStayStreet
			and @AuthorAddressStayStreet<>''
			--and feodor.dbo.AddressPart(AuthorAddressStay, 8)=@ClientAddressStayHouse
			and feodor.dbo.AddressPart(ClientAddressStay, 8)=@AuthorAddressStayHouse --DWH-1454

	)
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
	select 'FindDuplicateRule04'
	,      ClientRequestId
	,      original
	,      dublicate
	,      d_value
	--11-08-2020
	--, @ClientName
	--, @ClientBirthDay
	--, @ClientRequestNumber
	--, @ClientRequestCreatedOn
	--, @ClientRequestExternalStatusId
	--04_09_2020
	,      ClientName
	,      ClientBirthDay
	,      ClientRequestNumber
	,      ClientRequestCreatedOn
	,      ClientRequestExternalStatusId
	,	  ClientRequestExternalStatusName

	from t1

	--set statistics time off
	-- print '5'
	--
	--
	--

	--    /// <summary>
	--    /// Ищем телефоны (необходимо очистить номера от лишних символов) из текущей заявки в других заявках (исключаем заявки текущего клиента)
	--    /// Ищем телефоны пользователя-автора заявки в заявках, исключаем заявки текущего клиента
	--    /// </summary>
	--select * from Feodor.dbo.dm_FeodorRequests  where ClientRequestId='BC6B6875-3B5D-4C94-8436-A7595DDCE029'
	--select * from #resultTable  where ClientRequestId='BC6B6875-3B5D-4C94-8436-A7595DDCE029'
	--select * from Feodor.dbo.dm_FeodorRequests  where AuthorPhone ='9023938223'


	; with t
	as
	(
		select *
		from Feodor.dbo.dm_FeodorRequests
		where @ClientRequestId<>ClientRequestId
			and not(
				ClientName=@ClientName
				and ClientBirthDay=@ClientBirthDay)
	)
	,      t1
	as
	(
		select *                     
		,      'ClientWorkPlacePhone' original
		,      'ClientWorkPlacePhone' doublicate
		,      ClientWorkPlacePhone   d_value
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientWorkPlacePhone=ClientWorkPlacePhone
			and @ClientWorkPlacePhone<>''
		union
		select *
		,      'ClientWorkPlacePhone'
		,      'ClientPhoneMobile'
		,      ClientPhoneMobile
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientWorkPlacePhone=ClientPhoneMobile
			and @ClientWorkPlacePhone<>''

		union
		select *
		,      'ClientWorkPlacePhone'
		,      'ClientPhoneHome'
		,      ClientPhoneHome
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientWorkPlacePhone=ClientPhoneHome
			and @ClientWorkPlacePhone<>''
		union
		select *
		,      'ClientWorkPlacePhone'
		,      'ClientContactPersonPhone'
		,      ClientContactPersonPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientWorkPlacePhone=ClientContactPersonPhone
			and @ClientWorkPlacePhone<>''

		union
		select *
		,      'ClientWorkPlacePhone'
		,      'AuthorPhone'
		,      AuthorPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientWorkPlacePhone=AuthorPhone
			and @ClientWorkPlacePhone<>''

		union
		select *
		,      'ClientPhoneMobile'
		,      'ClientPhoneMobile'
		,      ClientPhoneMobile
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientPhoneMobile=ClientPhoneMobile
			and @ClientPhoneMobile<>''
		union
		select *
		,      'ClientPhoneMobile'
		,      'ClientPhoneHome'
		,      ClientPhoneHome
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientPhoneMobile=ClientPhoneHome
			and @ClientPhoneMobile<>''
		union
		select *
		,      'ClientPhoneMobile'
		,      'ClientContactPersonPhone'
		,      ClientContactPersonPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientPhoneMobile=ClientContactPersonPhone
			and @ClientPhoneMobile<>''
		union
		select *
		,      'ClientPhoneMobile'
		,      'AuthorPhone'
		,      AuthorPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientPhoneMobile=AuthorPhone
			and @ClientPhoneMobile<>''

		union
		select *
		,      'ClientPhoneHome'
		,      'ClientPhoneHome'
		,      ClientPhoneHome
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientPhoneHome=ClientPhoneHome
			and @ClientPhoneHome<>''
		union
		select *
		,      'ClientPhoneHome'
		,      'ClientContactPersonPhone'
		,      ClientContactPersonPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientPhoneHome=ClientContactPersonPhone
			and @ClientPhoneHome<>''
		union
		select *
		,      'ClientPhoneHome'
		,      'AuthorPhone'
		,      AuthorPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientPhoneHome=AuthorPhone
			and @ClientPhoneHome<>''

		union
		select *
		,      'ClientContactPersonPhone'
		,      'ClientContactPersonPhone'
		,      ClientContactPersonPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientContactPersonPhone=ClientContactPersonPhone
			and @ClientContactPersonPhone<>''
		union
		select *
		,      'ClientContactPersonPhone'
		,      'AuthorPhone'
		,      AuthorPhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientContactPersonPhone=AuthorPhone
			and @ClientContactPersonPhone<>''
		union
		select *
		,      'ClientContactPersonPhone'
		,      'ClientPhoneMobile'
		,      ClientPhoneMobile
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientContactPersonPhone=ClientPhoneMobile
			and @ClientContactPersonPhone<>''
		union 
		select *
		,      'ClientContactPersonPhone'
		,      'ClientWorkPlacePhone'
		,      ClientWorkPlacePhone
		from t /*from Feodor.dbo.dm_FeodorRequests */
		where @ClientContactPersonPhone=ClientWorkPlacePhone
			and @ClientContactPersonPhone<>''

	--union select *,'AuthorPhone','AuthorPhone',AuthorPhone from t /*from Feodor.dbo.dm_FeodorRequests */ where @AuthorPhone =AuthorPhone and @AuthorPhone <>''


	)

	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
	select 'FindDuplicateRule05'
	,      ClientRequestId
	,      original
	,      doublicate
	,      d_value
	--11-08-2020
	--, @ClientName
	--, @ClientBirthDay
	--, @ClientRequestNumber
	--, @ClientRequestCreatedOn
	--, @ClientRequestExternalStatusId
	--04_09_2020
	,      ClientName
	,      ClientBirthDay
	,      ClientRequestNumber
	,      ClientRequestCreatedOn
	,      ClientRequestExternalStatusId
	,	   ClientRequestExternalStatusName

	from t1


	--print '6'

	-- set statistics time on
	--
	-- FindDuplicateRule06
	--
	--    /// <summary>
	--   /// Ищем серию + номер паспорта в заявках (исключаем заявки текущего пользователя)
	--   /// </summary>

	;with t
	as
	(
		select *
		from Feodor.dbo.dm_FeodorRequests r
		where @ClientRequestId <> ClientRequestId
			and not(
				ClientName=@ClientName
				and ClientBirthDay=@ClientBirthDay)
			and @ClientPassport = ClientPassport
			AND @ClientPassport <> ''
	)
	insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
	--11-08-2020
	, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
	select 'FindDuplicateRule06'
	,      ClientRequestId
	,      'ClientPassport'
	,      'ClientPassport'
	,      ClientPassport
	--11-08-2020
	--, @ClientName
	--, @ClientBirthDay
	--, @ClientRequestNumber
	--, @ClientRequestCreatedOn
	--, @ClientRequestExternalStatusId
	--04_09_2020
	,      ClientName
	,      ClientBirthDay
	,      ClientRequestNumber
	,      ClientRequestCreatedOn
	,      ClientRequestExternalStatusId
	,	  ClientRequestExternalStatusName

	from t

	--print '6.1'
	--
	-- FindDuplicateRule07
	--

	--    /// <summary>
	--    /// Ищем фио клиента и фио КЛ в списке сотрудников и сотрудников Партнёра
	--    /// </summary>
	if @ClientName<>''
	begin
		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
		select 'FindDuplicateRule07'
		,      ClientRequestId
		,      'ClientName'
		,      'AuthorName'
		,      AuthorName
		--11-08-2020
		--, @ClientName
		--, @ClientBirthDay
		--, @ClientRequestNumber
		--, @ClientRequestCreatedOn
		--, @ClientRequestExternalStatusId
		--04_09_2020
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,      ClientRequestExternalStatusId
		,	   ClientRequestExternalStatusName
		from Feodor.dbo.dm_FeodorRequests r
		where @ClientRequestId <> ClientRequestId
			and @ClientName =AuthorName
	end


	--print '7'

	if @ClientContactPersonName<>''
	begin
		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)

		select 'FindDuplicateRule07'
		,      ClientRequestId
		,      'ContactPersonName'
		,      'AuthorName'
		,      AuthorName
		--11-08-2020
		--, @ClientName
		--, @ClientBirthDay
		--, @ClientRequestNumber
		--, @ClientRequestCreatedOn
		--, @ClientRequestExternalStatusId
		--04_09_2020
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,      ClientRequestExternalStatusId
		,	   ClientRequestExternalStatusName

		from Feodor.dbo.dm_FeodorRequests r
		where @ClientRequestId <> ClientRequestId
			and @ClientContactPersonName =AuthorName
	end


	--print '8'
	--
	-- FindDuplicateRule10
	--

	--    /// <summary>
	--    /// Ищем серию+номер паспорта пользователя-автора в заявках, исключаем заявки текущего клиента
	--    /// </summary>
	if @AuthorPassport<>''
	begin
		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
		select 'FindDuplicateRule10'
		,      ClientRequestId
		,      'AuthorPassport'
		,      'ClientPassport'
		,      ClientPassport
		--11-08-2020
		--, @ClientName
		--, @ClientBirthDay
		--, @ClientRequestNumber
		--, @ClientRequestCreatedOn
		--, @ClientRequestExternalStatusId
		--04_09_2020
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,      ClientRequestExternalStatusId
		,	  ClientRequestExternalStatusName

		from Feodor.dbo.dm_FeodorRequests r
		where @ClientRequestId <> ClientRequestId
			and not(
				ClientName=@ClientName
				and ClientBirthDay=@ClientBirthDay)
			and @AuthorPassport = ClientPassport
	end

	--
	-- FindDuplicateRule11
	--

	--     /// <summary>
	--    /// Ищем VIN из текущей заявки в заявках ДРУГИХ клиентов
	--    /// </summary>
	if @VIN<>''
	begin
		insert into #resultTable ( searchRule, ClientRequestId, OriginalField, DuplicateField, FieldValue
		--11-08-2020
		, ClientName, ClientBirthDay, ClientRequestNumber, ClientRequestCreatedOn, ClientRequestExternalStatusId, StatusName)
		select 'FindDuplicateRule11'
		,      ClientRequestId
		,      'VIN'
		,      'VIN'
		,      VIN
		--11-08-2020
		--, @ClientName
		--, @ClientBirthDay
		--, @ClientRequestNumber
		--, @ClientRequestCreatedOn
		--, @ClientRequestExternalStatusId
		--04_09_2020
		,      ClientName
		,      ClientBirthDay
		,      ClientRequestNumber
		,      ClientRequestCreatedOn
		,      ClientRequestExternalStatusId
		,    ClientRequestExternalStatusName

		from Feodor.dbo.dm_FeodorRequests r
		where @ClientRequestId <> ClientRequestId
			and not(
				ClientName=@ClientName
				and ClientBirthDay=@ClientBirthDay)
			and @vin=VIN


	end

	--set statistics time off

	DECLARE @tableHTML NVARCHAR(MAX) ;

	SET @tableHTML =
	N'<H1>Ответ федору</H1>' +
	N'<table border="1">' +
	N'<tr><th>searchRule</th><th>ClientRequestId</th>' +
	N'<th>OriginalField</th><th>DuplicateField</th><th>FieldValue</th>' +
	N'<th>ClientName</th><th> ClientBirthDay</th><th>ClientRequestNumber </th>' +
	N'<th>OClientRequestCreatedOn</th>' +
	N'<th>ClientRequestExternalStatusId</th>'+
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
	,               td = ClientRequestExternalStatusId
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
	--,ClientRequestExternalStatusId 
	,StatusName
	from #resultTable

	--Declare @ExecutingTimeBegin datetime2 = GetDate()
	Declare @ExecutingTimeEnd datetime2 = GetDate()
	Declare @ExecutionTime int
	Declare @strExecutionTime nvarchar(200) = 'Finished. Time execution: '

	Set @ExecutionTime = DATEDIFF(second,@ExecutingTimeBegin,@ExecutingTimeEnd)
	Set @strExecutionTime = @strExecutionTime + cast(@ExecutionTime as nvarchar(10))

	--Select @strExecutionTime

	if @isLogging = 1
	begin
		exec [LogAndSendMailToAdmin] 'Fraud_doubles'
		,                            'Info'
		,                            'Fraud_doubles procedure finished'
		,                            @strExecutionTime
		exec [LogAndSendMailToAdmin] 'Fraud_doubles'
		,                            'Info'
		,                            @subject1
		,                            @tableHTML
	end

end

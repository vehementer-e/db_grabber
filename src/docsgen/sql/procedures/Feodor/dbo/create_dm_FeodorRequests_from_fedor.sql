 --exec [dbo].[create_dm_FeodorRequests_from_fedor] 1
CREATE PROC dbo.create_dm_FeodorRequests_from_fedor
	@isReloadAll bit= 0
	,@ClientRequestId uniqueidentifier = null
	,@isDebug int = 0
as
begin
	SELECT @isDebug = isnull(@isDebug, 0)

	begin try
	--drop table if exists dbo.dm_FeodorRequests_test
	--drop table if exists dbo.dm_FeodorRequests_vin
	--drop table if exists dbo.dm_FeodorRequests_ClientPhone
	--drop table if exists dbo.dm_FeodorRequests_ClientPassport
	--drop table if exists dbo.dm_FeodorRequests_ClientAddress
	--drop table if exists dbo.dm_FeodorRequests_ClientContactPerson
	--truncate table dbo.dm_FeodorRequests_test
	declare @rowVerson binary(8) = 0
	declare @ClientRequestClientInfoRowVersion binary(8) = 0
	
	if OBJECT_ID('dm_FeodorRequests_test') is not null
		and @ClientRequestId is null
	begin
		--
		--set @rowVerson =  ISNULL(
		--	(select max(RowVersion) from dbo.dm_FeodorRequests_test
		--		where TableSource = 'F') -100
		--	, 0)
		select 
			@rowVerson = isnull(max(RowVersion) - 1000, 0x0),
			@ClientRequestClientInfoRowVersion = isnull(max(ClientRequestClientInfoRowVersion) - 1000, 0x0)
		from dbo.dm_FeodorRequests_test
		where TableSource = 'F'
	end

	if @isReloadAll = 1
	begin
		select @rowVerson = 0x0, @ClientRequestClientInfoRowVersion = 0x0
	end
	
	drop table if exists #t_ClientRequest
	create table #t_ClientRequest(
		ClientRequestId uniqueidentifier
	)

	if @ClientRequestId is not null begin
		insert #t_ClientRequest(ClientRequestId)
		select ClientRequestId = @ClientRequestId
	end 
	else begin
		insert #t_ClientRequest(ClientRequestId)
		select distinct ClientRequestId = cr.id
		from Stg._fedor.core_ClientRequest as cr 
		where cr.RowVersion > @rowVerson
		union
		select distinct ClientRequestId = cr_ci.id
		from Stg._fedor.core_ClientRequestClientInfo as cr_ci
		where cr_ci.RowVersion > @ClientRequestClientInfoRowVersion
	end

	if @isDebug = 1 begin
		drop table if exists ##t_ClientRequest
		select * into ##t_ClientRequest from #t_ClientRequest
	end
	
	drop table if exists #dm_FeodorRequests
	--drop table dm_FeodorRequests_test

	SELECT TableSource = 'F'                                                                            
	,      [ClientRequestId]		= cr.[Id]                                                                          -- ID заявки (Guid)
	,      [ClientRequestNumber]	= cr.[Number] collate Cyrillic_General_CI_AS                                     -- Номер заявки
	,      [ClientRequestCreatedOn] = ISNULL([CreatedRequestDate], cr.[CreatedOn])                                   -- Дата создания заявки
	,      [IsDeleted]				= cr.[IsDeleted] -- флаг удаленной записи                                       
	,      [ClientId]				= cr.[IdClient]                                                                                  -- ID клиента
	,      [Vin] = nullif(TRIM([Vin]),'') collate Cyrillic_General_CI_AS												   -- VIN
	,      [ClientWorkplaceAddress]	= nullif([ClientWorkplaceAddress],'') collate Cyrillic_General_CI_AS                                     -- Адрес работы клиента
	,      [ClientWorkPlacePhone]	= TRIM(nullif([ClientWorkPlacePhone],'')) collate Cyrillic_General_CI_AS              -- Телефон организации
	,      [ClientName]				= Left(CONCAT_ws(' '
											, TRIM(isnull(cr.[ClientFirstName]	, cr_ci.FirstName	))
											, TRIM(isnull(cr.[ClientMiddleName]	, cr_ci.MiddleName	))
											, TRIM(isnull(cr.[ClientLastName]	, cr_ci.LastName	))
											)
											,250) 	collate Cyrillic_General_CI_AS -- ИОФ клиента
	,      [ClientFIO]				= 
									LEFT(CONCAT_WS(' '
										, TRIM(isnull(nullif(cr.[ClientLastName]	,''), cr_ci.LastName))
										, trim(isnull(nullif(cr.[ClientFirstName]	,''), cr_ci.FirstName))
										, TRIM(isnull(nullif(cr.[ClientMiddleName]	,''), cr_ci.MiddleName))
									),250) 	collate Cyrillic_General_CI_AS -- ФИО клиента
	,      [ClientBirthDay] =isnull(cr.[ClientBirthDay], cr_ci.BirthDay)-- Дата рождения клиента                                                  
	,      [ClientPhoneMobile]		= Left(TRIM(nullif([ClientPhoneMobile],'')),25) collate Cyrillic_General_CI_AS        -- Контактный телефон
	,      [ClientPassport]			= nullIF(Left(CONCAT_ws(' '
					,TRIM(isnull(nullif(cr.[ClientPassportSerial],''), cr_ci.PassportSerial))
					,TRIM(isnull(nullif(cr.[ClientPassportNumber],''), cr_ci.PassportNumber))
					), 25),'')	collate Cyrillic_General_CI_AS                                                                     -- Серия и номер паспорта клиента
	,      ClientAddressRegistration	= isnull(nullif(cr.ClientAddressRegistration,''),cr_ci.AddressRegistration)  collate Cyrillic_General_CI_AS                                    -- Адрес регистрации клиента
	,      [ClientPhoneHome]			= Left(TRIM(nullif([ClientPhoneHome],'')),25) collate Cyrillic_General_CI_AS          -- Домашний телефон клиента
	,      [ClientContactPersonName]	= TRIM(nullif([ClientContactPersonName],'')) collate Cyrillic_General_CI_AS           -- ФИО контактного лица
	,      [ClientContactPersonPhone]	= Left(TRIM(nullif([ClientContactPersonPhone],'')),25) collate Cyrillic_General_CI_AS -- Телефон контактного лица
	,      ClientAddressStay			= COALESCE(
				trim(nullif(cr.[ClientAddressStay],''))
				,trim(nullif(cr_ci.AddressResidential, ''))
				,null
			)collate Cyrillic_General_CI_AS                                          -- Адрес фактического проживания клиента
	
	,      ClientRequestStatusName = concat(N'Статус федор - ', [ClientRequestStatus].Name) collate Cyrillic_General_CI_AS      
	,	   cr.RowVersion
	,	   LoadDate = CURRENT_TIMESTAMP
	,		ClientRequestClientInfoRowVersion = cr_ci.RowVersion
	
	into  #dm_FeodorRequests
	FROM #t_ClientRequest as t
		inner join Stg._fedor.core_ClientRequest as cr 
			on cr.Id = t.ClientRequestId
		inner join Stg._fedor.dictionary_ClientRequestStatus as ClientRequestStatus
			on cr.IdStatus = ClientRequestStatus.Id
		left join Stg._fedor.core_ClientRequestClientInfo as cr_ci
			on cr_ci.id = cr.id
	where 1=1
		--and (
		--	cr.RowVersion > @rowVerson
		--	or cr_ci.RowVersion > @ClientRequestClientInfoRowVersion
		--	or cr_ci.RowVersion is null
		--)
		--and (cr.id = @ClientRequestId or @ClientRequestId is null)

	create clustered index cli on #dm_FeodorRequests(ClientRequestId)

	if @isDebug = 1 begin
		drop table if exists ##dm_FeodorRequests
		select * into ##dm_FeodorRequests from #dm_FeodorRequests
	end

	if OBJECT_ID('dbo.dm_FeodorRequests_test') is null
	begin
		select top(0) 
			[TableSource], 
			[ClientRequestId], 
			[ClientRequestNumber], 
			[ClientRequestCreatedOn], 
			[IsDeleted], 
			ClientRequestStatusName, 
			[ClientId], 
			[ClientName], 
			[ClientFIO],
			[ClientBirthDay], 
			[ClientPassport], 
			[RowVersion],
			LoadDate,
			ClientRequestClientInfoRowVersion
		into dbo.dm_FeodorRequests_test
		from #dm_FeodorRequests
		create clustered index cli_ClientRequestId on dm_FeodorRequests_test([ClientRequestId], TableSource)
		
		CREATE NONCLUSTERED INDEX ix_ClientName_ClientBirthDay ON [dbo].[dm_FeodorRequests_test] ([ClientName],[ClientBirthDay])
	end
	--Основная витрина dm_FeodorRequests_test
	
	if exists(select top(1) 1 from #dm_FeodorRequests )
	begin
		--удалил то что уже есть в dm_FeodorRequests_test, но таких записей не должно быть. но удалим
		if @isReloadAll =0
			and @ClientRequestId is null
		begin
			delete t from #dm_FeodorRequests t
			where exists(
				select top(1) 1 
				from dbo.dm_FeodorRequests_test s
					where s.[ClientRequestId] = t.[ClientRequestId]
						and s.TableSource = t.TableSource
						and s.RowVersion = t.RowVersion
						and isnull(s.ClientRequestClientInfoRowVersion, 0x0) = isnull(t.ClientRequestClientInfoRowVersion, 0x0)
				)
		end
			
		begin tran
			delete t from dbo.dm_FeodorRequests_test t
			where 
			 t.TableSource = 'F'    
			and exists (select top(1) 1 from #dm_FeodorRequests  s
				where s.[ClientRequestId] = t.[ClientRequestId]
				)
			
			insert into dbo.dm_FeodorRequests_test (
				[TableSource], 
				[ClientRequestId], 
				[ClientRequestNumber], 
				[ClientRequestCreatedOn], 
				[IsDeleted], 
				ClientRequestStatusName, 
				[ClientId], 
				[ClientName], 
				[ClientFIO],
				[ClientBirthDay], 
				[ClientPassport], 
				
				[RowVersion],
				LoadDate,
				ClientRequestClientInfoRowVersion
			)
			select  
				[TableSource], 
				[ClientRequestId], 
				[ClientRequestNumber], 
				[ClientRequestCreatedOn], 
				[IsDeleted], 
				ClientRequestStatusName, 
				[ClientId], 
				[ClientName], 
				[ClientFIO],
				[ClientBirthDay], 
				[ClientPassport], 
				[RowVersion],
				LoadDate,
				ClientRequestClientInfoRowVersion
			from #dm_FeodorRequests
			
		commit tran
		
	end
	--dm_FeodorRequests_ClientContactPerson
	if exists(select top(1) 1 from #dm_FeodorRequests where nullif([ClientContactPersonName],'') is not null)
	begin
		drop table if exists #ClientContactPerson
		select distinct
			 t.TableSource	
			,t.ClientRequestId	
			,t.ClientRequestNumber
			,ContactPersonName = t.ClientContactPersonName
			,ContactPersonPhone = t.ClientContactPersonPhone
			,ClientContactPersonType = 'ClientContactPerson' 
			,t.RowVersion
			,t.LoadDate
			,t.ClientRequestClientInfoRowVersion
		into #ClientContactPerson
		from #dm_FeodorRequests as t
		where nullif([ClientContactPersonName],'') is not null

		if @isDebug = 1 begin
			drop table if exists ##ClientContactPerson
			select * into ##ClientContactPerson from #ClientContactPerson
		end

		if object_id('dm_FeodorRequests_ClientContactPerson') is null
		begin
			select top(0)
				 t.TableSource	
				,t.ClientRequestId	
				,t.ClientRequestNumber
				,t.ContactPersonName
				,t.ContactPersonPhone
				,t.ClientContactPersonType
				,t.RowVersion
				,t.LoadDate
				,t.ClientRequestClientInfoRowVersion
			into dbo.dm_FeodorRequests_ClientContactPerson
			from #ClientContactPerson as t

			create clustered index cli_ClientRequestId_PassportType 
			on dbo.dm_FeodorRequests_ClientContactPerson(ClientRequestId, ClientContactPersonType)
		end
			 if @isReloadAll=0
				and @ClientRequestId is null
			 begin
				delete t from #ClientContactPerson t
				where exists(
					select top(1) 1 
					from dbo.dm_FeodorRequests_ClientContactPerson s 
					where s.ClientRequestId = t.ClientRequestId
						and s.ClientContactPersonType = t.ClientContactPersonType
						and s.TableSource = t.TableSource
						and s.RowVersion = t.RowVersion
						and isnull(s.ClientRequestClientInfoRowVersion, 0x0) = isnull(t.ClientRequestClientInfoRowVersion, 0x0)
				)
			  end
			if exists(select top(1) 1 from #ClientContactPerson)
			begin
				begin tran ClientContactPerson
					delete t from dbo.dm_FeodorRequests_ClientContactPerson t
					where exists(
						select top(1) 1 
						from #ClientContactPerson s 
						where s.ClientRequestId = t.ClientRequestId
							and s.TableSource = t.TableSource
							and s.ClientContactPersonType = t.ClientContactPersonType
					)

					insert into dbo.dm_FeodorRequests_ClientContactPerson
					(
						 TableSource	
						,ClientRequestId	
						,ClientRequestNumber
						,ContactPersonName
						,ContactPersonPhone
						,ClientContactPersonType
						,RowVersion
						,LoadDate
						,ClientRequestClientInfoRowVersion
					)
					select
						 TableSource	
						,ClientRequestId	
						,ClientRequestNumber
						,ContactPersonName
						,ContactPersonPhone
						,ClientContactPersonType
						,RowVersion
						,LoadDate
						,ClientRequestClientInfoRowVersion
					from #ClientContactPerson
				commit tran
			end
	end
	
	--dm_FeodorRequests_vin
	if exists(select top(1) 1 from #dm_FeodorRequests where nullif(Vin,'') is not null)
	begin
	--VIN
		drop table if exists #vin
		select distinct
			 t.TableSource	
			,t.ClientRequestId	
			,t.ClientRequestNumber
			,t.VIN
			,t.RowVersion
			,t.LoadDate
			,t.ClientRequestClientInfoRowVersion
		into #vin
		from #dm_FeodorRequests t
		where nullif(Vin,'') is not null

		if @isDebug = 1 begin
			drop table if exists ##vin
			select * into ##vin from #vin
		end

		if OBJECT_ID('dbo.dm_FeodorRequests_vin') is null
		begin
			select top(0) 
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,VIN
				,RowVersion
				,LoadDate
				,ClientRequestClientInfoRowVersion
			into dbo.dm_FeodorRequests_vin
			from #vin

			create clustered index cli_ClientRequestId 
			on dbo.dm_FeodorRequests_vin(ClientRequestId, TableSource)
		end
		if @isReloadAll=0
			and @ClientRequestId is null
		 begin
			delete t from #vin t
			where exists(
				select top(1) 1 
				from dbo.dm_FeodorRequests_vin s 
				where s.ClientRequestId = t.ClientRequestId
					and s.TableSource = t.TableSource
					and s.RowVersion = t.RowVersion
					and isnull(s.ClientRequestClientInfoRowVersion, 0x0) = isnull(t.ClientRequestClientInfoRowVersion, 0x0)
			)
		end
		if exists (select top(1) 1 from #vin)
		begin
			begin tran vin
		
				delete t from dbo.dm_FeodorRequests_vin t
				where exists(select top(1) 1 from #vin s where s.ClientRequestId = t.ClientRequestId
					and s.TableSource = t.TableSource)
				insert into dbo.dm_FeodorRequests_vin
				(
					TableSource	
					,ClientRequestId	
					,ClientRequestNumber
					,VIN
					,RowVersion
					,LoadDate
					,ClientRequestClientInfoRowVersion
				)
				select
					TableSource	
					,ClientRequestId	
					,ClientRequestNumber
					,VIN
					,RowVersion
					,LoadDate
					,ClientRequestClientInfoRowVersion
				from #vin
			
			commit tran
		end
		
	end

	--dm_FeodorRequests_ClientPassport
	if exists(select top(1) 1 from #dm_FeodorRequests where nullif(ClientPassport,'') is not null)
	begin
		drop table if exists #ClientPassport
		select distinct
			 t.TableSource	
			,t.ClientRequestId	
			,t.ClientRequestNumber
			,Passport = t.ClientPassport
			,PassportType = 'ClientPassport' 
			,t.RowVersion
			,t.LoadDate
			,t.ClientRequestClientInfoRowVersion
		into #ClientPassport
		from #dm_FeodorRequests t
		where nullif(ClientPassport,'') is not null

		if @isDebug = 1 begin
			drop table if exists ##ClientPassport
			select * into ##ClientPassport from #ClientPassport
		end


		if object_id('dm_FeodorRequests_ClientPassport') is null
		begin
			select top(0)
				 t.TableSource	
				,t.ClientRequestId	
				,t.ClientRequestNumber
				,t.Passport
				,t.PassportType
				,t.RowVersion
				,t.LoadDate
				,t.ClientRequestClientInfoRowVersion
			into dbo.dm_FeodorRequests_ClientPassport
			from #ClientPassport as t

			create clustered index cli_ClientRequestId_PassportType on dbo.dm_FeodorRequests_ClientPassport(ClientRequestId, PassportType)
		end
		if @isReloadAll=0
			and @ClientRequestId is null
		begin
			delete t from #ClientPassport t
			where exists(
				select top(1) 1 
				from dbo.dm_FeodorRequests_ClientPassport s 
				where s.ClientRequestId = t.ClientRequestId
					and s.PassportType = t.PassportType
					and s.TableSource = t.TableSource
					and s.RowVersion = t.RowVersion
					and isnull(s.ClientRequestClientInfoRowVersion, 0x0) = isnull(t.ClientRequestClientInfoRowVersion, 0x0)
			)
		end
			if exists(select top(1) 1 from #ClientPassport)
			begin
				begin tran ClientPassport
					delete t from dbo.dm_FeodorRequests_ClientPassport t
					where exists(select top(1) 1 from #ClientPassport s where s.ClientRequestId = t.ClientRequestId
					and s.TableSource = t.TableSource
					and s.PassportType = t.PassportType)

					insert into dbo.dm_FeodorRequests_ClientPassport
					(
						 TableSource	
						,ClientRequestId	
						,ClientRequestNumber
						,Passport
						,PassportType
						,RowVersion
						,LoadDate
						,ClientRequestClientInfoRowVersion
					)
					select 
						 TableSource	
						,ClientRequestId	
						,ClientRequestNumber
						,Passport
						,PassportType
						,RowVersion
						,LoadDate
						,ClientRequestClientInfoRowVersion
					from #ClientPassport
				commit tran
			end
	end

	--dm_FeodorRequests_ClientPhone
	if exists(select top(1) 1 from #dm_FeodorRequests where nullif(coalesce(
		ClientPhoneHome, 
		ClientContactPersonPhone, 
		ClientPhoneMobile, 
		ClientWorkPlacePhone
		, ''),'') is not null)
	begin
		drop table if exists #dm_FeodorRequests_ClientPhone
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientPhoneType = 'ClientPhoneHome'
			,Phone = ClientPhoneHome
			,RowVersion
			,LoadDate
			,ClientRequestClientInfoRowVersion
		into #dm_FeodorRequests_ClientPhone
		from #dm_FeodorRequests
		where nullif(ClientPhoneHome,'') is not null
		union
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientPhoneType = 'ClientContactPersonPhone'
			,Phone = ClientContactPersonPhone
			,RowVersion
			,LoadDate
			,ClientRequestClientInfoRowVersion
		from #dm_FeodorRequests
		where nullif(ClientContactPersonPhone,'') is not null
		union
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientPhoneType = 'ClientPhoneMobile'
			,Phone = ClientPhoneMobile
			,RowVersion
			,LoadDate
			,ClientRequestClientInfoRowVersion		
		from #dm_FeodorRequests
		where nullif(ClientPhoneMobile,'') is not null

		union
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientPhoneType = 'ClientWorkPlacePhone'
			,Phone = ClientWorkPlacePhone
			,RowVersion
			,LoadDate
			,ClientRequestClientInfoRowVersion		
		from #dm_FeodorRequests
		where nullif(ClientWorkPlacePhone,'') is not null

		if @isDebug = 1 begin
			drop table if exists ##dm_FeodorRequests_ClientPhone
			select * into ##dm_FeodorRequests_ClientPhone from #dm_FeodorRequests_ClientPhone
		end

		if object_id('dbo.dm_FeodorRequests_ClientPhone') is null
		begin
			select top(0)
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,ClientPhoneType
				,Phone
				,RowVersion
				,LoadDate
				,ClientRequestClientInfoRowVersion		
			into dbo.dm_FeodorRequests_ClientPhone
			from #dm_FeodorRequests_ClientPhone
			create clustered index cli_ClientRequestId on dbo.dm_FeodorRequests_ClientPhone(ClientRequestId, TableSource)
		end

		if @isReloadAll=0
			and @ClientRequestId is null
		begin
			delete t from #dm_FeodorRequests_ClientPhone t
			where exists(
				select top(1) 1 
				from dbo.dm_FeodorRequests_ClientPhone s 
				where s.ClientRequestId = t.ClientRequestId
					and s.TableSource = t.TableSource
					and s.RowVersion = t.RowVersion
					and s.ClientPhoneType = t.ClientPhoneType
					and isnull(s.ClientRequestClientInfoRowVersion, 0x0) = isnull(t.ClientRequestClientInfoRowVersion, 0x0)
			)
		end
		if exists (select top(1) 1 from #dm_FeodorRequests_ClientPhone)
		begin
			begin tran ClientPhoneType
				delete t from dbo.dm_FeodorRequests_ClientPhone t
				where exists(
					select top(1) 1 
					from #dm_FeodorRequests_ClientPhone s 
					where s.ClientRequestId = t.ClientRequestId
						and s.TableSource = t.TableSource
						and s.ClientPhoneType = t.ClientPhoneType
						--and s.RowVersion != t.RowVersion
					)

				insert into dbo.dm_FeodorRequests_ClientPhone
				(
					TableSource	
					,ClientRequestId	
					,ClientRequestNumber
					,ClientPhoneType
					,Phone
					,RowVersion
					,LoadDate
					,ClientRequestClientInfoRowVersion		
				)
				select 
					TableSource	
					,ClientRequestId	
					,ClientRequestNumber
					,ClientPhoneType
					,Phone
					,RowVersion
					,LoadDate
					,ClientRequestClientInfoRowVersion		
				from #dm_FeodorRequests_ClientPhone
			commit tran
		end
	end

	--dm_FeodorRequests_ClientAddress
	if exists(select top(1) 1 from #dm_FeodorRequests
		where nullif(coalesce(
		ClientAddressRegistration
		,ClientWorkplaceAddress
		,ClientAddressStay
		
		, ''),'') is not null)
	begin
		drop table if exists #dm_FeodorRequests_ClientAddress
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientAddressType = 'ClientAddressRegistration'
			,PostalCode = dbo.AddressPart_test(ClientAddressRegistration, 2) collate Cyrillic_General_CI_AS       -- Адрес регистрации клиента. Почтовый индекс
			,Address = ClientAddressRegistration
			,Street = dbo.AddressPart_test(ClientAddressRegistration, 7) collate Cyrillic_General_CI_AS       -- Адрес регистрации клиента. Улица
			,House = dbo.AddressPart_test([ClientAddressRegistration], 8)
			,RowVersion
			,LoadDate
			,ClientRequestClientInfoRowVersion
		into #dm_FeodorRequests_ClientAddress
		from #dm_FeodorRequests
		where nullif(ClientAddressRegistration,'') is not null
		union
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientAddressType = 'ClientWorkplaceAddress'
			,PostalCode = dbo.AddressPart_test(ClientWorkplaceAddress, 2) collate Cyrillic_General_CI_AS          -- Адрес работы клиента. Почтовый индекс
			,Address =ClientWorkplaceAddress
			,Street = dbo.AddressPart_test(ClientWorkplaceAddress, 7) collate Cyrillic_General_CI_AS          -- Адрес работы клиента. Улица
			,House = dbo.AddressPart_test(ClientWorkplaceAddress, 8)
			,RowVersion
			,LoadDate
			,ClientRequestClientInfoRowVersion
		from #dm_FeodorRequests
		where nullif(ClientWorkplaceAddress ,'') is not null
		union
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientAddressType = 'ClientAddressStay'
			,PostalCode = dbo.AddressPart_test([ClientAddressStay], 2) collate Cyrillic_General_CI_AS               -- Адрес фактического проживания клиента. Почтовый индекс
			,Address = [ClientAddressStay]
			,Street = dbo.AddressPart_test([ClientAddressStay], 7) collate Cyrillic_General_CI_AS               -- Адрес фактического проживания клиента. Улица
			,House = dbo.AddressPart_test(ClientAddressStay, 8)
			,RowVersion
			,LoadDate
			,ClientRequestClientInfoRowVersion
		from #dm_FeodorRequests
		where nullif(ClientAddressStay ,'') is not null
		
		if @isDebug = 1 begin
			drop table if exists ##dm_FeodorRequests_ClientAddress
			select * into ##dm_FeodorRequests_ClientAddress from #dm_FeodorRequests_ClientAddress
		end

		if OBJECT_ID('dbo.dm_FeodorRequests_ClientAddress') is null
		begin
			select top(0)
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,ClientAddressType
				,PostalCode
				,Address
				,Street
				,House
				,RowVersion
				,LoadDate
				,ClientRequestClientInfoRowVersion
			into dbo.dm_FeodorRequests_ClientAddress
			from #dm_FeodorRequests_ClientAddress
			create clustered index cli on dbo.dm_FeodorRequests_ClientAddress(ClientRequestId, TableSource)
		end
		if @isReloadAll=0
			and @ClientRequestId is null
		begin
			delete t from #dm_FeodorRequests_ClientAddress t
			where exists(
				select top(1) 1 
				from dbo.dm_FeodorRequests_ClientAddress s
				where s.ClientRequestId =t.ClientRequestId
					and s.TableSource = t.TableSource
					and s.ClientAddressType = t.ClientAddressType
					and s.RowVersion = t.RowVersion
					and isnull(s.ClientRequestClientInfoRowVersion, 0x0) = isnull(t.ClientRequestClientInfoRowVersion, 0x0)
			)
		end

		if exists(select top(1) 1 from #dm_FeodorRequests_ClientAddress)
		begin
		begin tran ClientAddress
			delete t from dbo.dm_FeodorRequests_ClientAddress t
			where exists(select top(1) 1 from #dm_FeodorRequests_ClientAddress s
			where s.ClientRequestId =t.ClientRequestId
				and s.TableSource = t.TableSource
				and s.ClientAddressType = t.ClientAddressType
				)
			insert into dm_FeodorRequests_ClientAddress
			(
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,ClientAddressType
				,PostalCode
				,Address
				,Street
				,House
				,RowVersion
				,LoadDate
				,ClientRequestClientInfoRowVersion
			)
			select
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,ClientAddressType
				,PostalCode
				,Address
				,Street
				,House
				,RowVersion
				,LoadDate
				,ClientRequestClientInfoRowVersion
			from #dm_FeodorRequests_ClientAddress
		commit tran
		end
			
			
		
	end

end try
begin catch
	
	if @@TRANCOUNT<>0
		rollback tran
	;throw
end catch
end
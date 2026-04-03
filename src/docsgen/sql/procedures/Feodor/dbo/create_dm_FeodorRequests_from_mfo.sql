CREATE PROC dbo.create_dm_FeodorRequests_from_mfo
	@days int = 3
AS
begin
	begin try
		declare @rowVerson binary(8)  = 0
		declare @last_LoadDate date = '2000-01-01'
		set @days = ISNULL(@days, 3)
		--delete from dm_FeodorRequests_test where TableSource = 'M'
		if cast(getdate() as time) between '06:00' and '08:00'
		begin
			set @days = 365
		end

		declare @fromLoadDate  date = dateadd(year,2000,dateadd(dd, -@days,cast(getdate() as date)))

		if OBJECT_ID('dm_FeodorRequests_test') is not null
		begin
		--
			select @rowVerson = isnull(max(RowVersion), 0),
				@last_LoadDate = isnull(max(LoadDate), '2000-01-01')
			FROM dbo.dm_FeodorRequests_test
			where TableSource = 'M' 
		
			set @fromLoadDate =dateadd(year,2000,dateadd(dd, -@days,@last_LoadDate))
		end 
		
		--select @rowVerson, @fromLoadDate

		drop table if exists #mfo_statuses
		drop table if exists #mfo_request_statuses
		drop table if exists #t_contracts
		drop table if exists #dm_FeodorRequests
		;with cte_заявка_последний_статус
		as
		(
			SELECT [Заявка]     
			,      max( Период ) Период
			FROM [Stg].[_1cMFO].[РегистрСведений_ГП_СписокЗаявок]
		--	WHERE Период >= @fromLoadDate
			group by [Заявка]
		)
		select s.Заявка       
		,      s.Статус       
		,      sp.Наименование статусНаименование
		,	   cte.Период
			into #mfo_request_statuses
		FROM cte_заявка_последний_статус AS cte
			JOIN [Stg].[_1cMFO].[РегистрСведений_ГП_СписокЗаявок] AS s on s.Заявка=cte.Заявка
				and s.Период=cte.Период
			JOIN Stg.[_1cMFO].[Справочник_ГП_СтатусыЗаявок] AS sp on s.Статус=sp.Ссылка
		WHERE 1=1

		create clustered index ix on #mfo_request_statuses (Заявка)

		;with cte_договор_последний_статус
		as
		(
			select Договор             
			,      Период = max(Период)
			from stg.[_1cMFO].[РегистрСведений_ГП_СписокДоговоров]
			group by Договор
		)
		select s.Договор      
		,      Договор.Заявка 
		,      s.Статус       
		,      sp.Наименование статусНаименование
		,	   cte.Период
			into #t_contracts
		from       cte_договор_последний_статус                      cte    
		inner join stg.[_1cMFO].[РегистрСведений_ГП_СписокДоговоров] s       on s.Договор = cte.Договор
				and s.Период = cte.Период
		join       Stg.[_1cMFO].[Справочник_ГП_СтатусыДоговоров]     sp      on s.Статус=sp.Ссылка
		inner join stg.[_1cMFO].[Документ_ГП_Договор]                Договор on Договор.Ссылка = s.Договор
		--	where sp.Наименование = 'Продан'
		

		create clustered index ix on #t_contracts (Заявка)

		select
			TableSource = 'M'
		,	ClientRequestId = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(r.Ссылка) as uniqueidentifier)                                                                                                                                                                                    
		,  ClientRequestNumber = Номер                                                                                                                                                                                                                                               
		--, дата
		,  ClientRequestCreatedOn = dateadd(year,-2000, Дата)
		,  ClientRequestStatusName = iif(
					nullif(contracts.Договор, 0x) is not null
					,concat('Статус (МФО) договора - ', contracts.статусНаименование)
					,concat('Статус (МФО) заявки - ', s.статусНаименование)
				)       
		, ClientRequestDateStatusChanges = COALESCE(
				iif(year(contracts.Период)>3000, dateadd(year, -2000, contracts.Период), null)
					,iif(year(s.Период)>3000,  dateadd(year, -2000,s.Период), s.Период))
		, ClientId = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(КонтрагентКлиент) as uniqueidentifier)                                                                                                                                                                                   
		, ClientName = NULLIF(TRIM(Left(CONCAT(trim (r.Имя),' ',trim(r.отчество), ' ', trim(r.фамилия)), 250)), '')
		, ClientFIO = NULLIF(TRIM(Left(CONCAT(trim(r.фамилия),' ', trim(r.Имя),' ',trim(r.отчество)), 250)), '')
		, ClientBirthDay = case when r.ДатаРождения>'38010101'
					and r.ДатаРождения<'41010101' then dateadd(year,-2000,r.ДатаРождения)
										  else r.ДатаРождения end                                                                                                                                                                                                                        
		, ClientContactPersonName = NULLIF(TRIM(ФИОКонтактногоЛица),'')
		, ClientPassport = NULLIF(TRIM(concat(TRIM(replace(СерияПаспорта,'-','')),' ',TRIM(replace(НомерПаспорта,'-','')))),'')
		, VIN = NULLIF(TRIM([Vin]),'')                                                                                                                                                                                                                                                                 
		, ClientAddressRegistration = NULLIF(TRIM(cast(r.АдресРегистрации as nvarchar(255))),'')
		, ClientAddressStay = NULLIF(TRIM(cast(r.АдресПроживания as nvarchar(255))),'')
		, ClientWorkplaceAddress = NULLIF(TRIM(cast(АдресРаботы as nvarchar(255))),'')
		, ClientPhoneHome = NULLIF(Trim(replace(replace(replace(ТелефонАдресаПроживания,'-',''),'(',''),')','')),'')
		, ClientPhoneMobile = NULLIF(Trim(replace(replace(replace(ТелефонМобильный ,'-',''),'(',''),')','')),'')
		, ClientContactPersonPhone = NULLIF(Trim(replace(replace(replace(КЛТелМобильный ,'-',''),'(',''),')','')),'')
		, ClientWorkPlacePhone = NULLIF(Trim(replace(replace(replace(ТелРабочийРуководителя ,'-',''),'(',''),')','')),'')
		--, ThirdPersonName = NULLIF(TRIM(concat(TRIM(ФамилияСупруги),' ',TRIM(ИмяСупруги),' ',TRIM(ОтчествоСупруги))), '')
		, ThirdPersonName = NULLIF(TRIM(concat(trim(ИмяСупруги),' ',trim(ОтчествоСупруги),' ',trim(ФамилияСупруги))), '')
		, AuthorName = NULLIF(TRIM(m.Наименование),'')
		, AuthorAddressRegistration = NULLIF(TRIM(cast(m.АдресРегистрации as nvarchar(255))),'')
		, AuthorAddressStay = NULLIF(TRIM(cast(m.АдресПроживания as nvarchar(255))),'')
		, AuthorPassport = NULLIF(TRIM(concat(trim(replace(m.СерияДокумента,'-','')),' ',trim(replace(m.НомерДокумента,'-','')),' ')),'')
		, AuthorPhone = NULLIF(Trim(replace(replace(replace(m.[МобильныйТелефон],'-',''),'(',''),')','')),'')                                                                                                                                                                                 
		, RowVersion = r.ВерсияДанных
		, LoadDate = CURRENT_TIMESTAMP
		, [IsDeleted] =  cast(r.ПометкаУдаления as bit)

		into #dm_FeodorRequests
		from      stg._1cmfo.Документ_ГП_Заявка            r        
		left join #mfo_request_statuses                    s         on s.Заявка=r.Ссылка
		left join [Stg].[_1cMFO].[Справочник_Пользователи] m         on m.Ссылка=r.Менеджер
		left join #t_contracts                             contracts on contracts.Заявка = r.Ссылка
		where 1=1
			and (r.ВерсияДанных >@rowVerson
				OR s.Период >=@fromLoadDate
				--r.дата>@d
				--or contracts.Период >= @fromLoadDate
				or isnull(contracts.Период,'4100-01-01') >= @fromLoadDate
				)
	print @fromLoadDate
	create clustered index cli on #dm_FeodorRequests(ClientRequestId)
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
			ClientRequestClientInfoRowVersion = cast(null as binary(8))
		into dbo.dm_FeodorRequests_test
		from #dm_FeodorRequests
		create clustered index cli_ClientRequestId on dm_FeodorRequests_test([ClientRequestId], TableSource)
		
		CREATE NONCLUSTERED INDEX ix_ClientName_ClientBirthDay ON [dbo].[dm_FeodorRequests_test] ([ClientName],[ClientBirthDay])
	end
	--Основная витрина dm_FeodorRequests_test
	if exists(select top(1) 1 from #dm_FeodorRequests )
	begin
		--удалил то что уже есть в dm_FeodorRequests_test, но таких записей не должно быть. но удалим
		delete t from #dm_FeodorRequests t
		where exists(select top(1) 1 from dbo.dm_FeodorRequests_test s
		where s.[ClientRequestId] = t.[ClientRequestId]
			and s.TableSource = t.TableSource
			and s.RowVersion = t.RowVersion
			and s.ClientRequestStatusName =t.ClientRequestStatusName--статусы могут быть разные и они не зависят от RowVersion
			)
			
		begin tran dm_FeodorRequests
			delete t from dbo.dm_FeodorRequests_test t
			where 
			 t.TableSource = 'M'
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
				LoadDate
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
				LoadDate
			from #dm_FeodorRequests
			
		commit tran
		
	end
	
	--dm_FeodorRequests_ClientContactPerson
	if exists(select top(1) 1 from #dm_FeodorRequests 
		where nullif(ClientContactPersonName,'') is not NULL
			OR nullif(ThirdPersonName,'') is not NULL
		)
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
		into #ClientContactPerson
		from #dm_FeodorRequests t
		where nullif(t.[ClientContactPersonName],'') is not null
		UNION ALL
		select distinct
			 t.TableSource	
			,t.ClientRequestId	
			,t.ClientRequestNumber
			,ContactPersonName = t.ThirdPersonName
			,ContactPersonPhone = NULL
			,ClientContactPersonType = 'ThirdPersonName' 
			,t.RowVersion
			,t.LoadDate
		from #dm_FeodorRequests t
		where nullif(t.ThirdPersonName,'') is not null


		if object_id('dm_FeodorRequests_ClientContactPerson') is null
		begin
			select top(0)
				 t.TableSource	
				,t.ClientRequestId	
				,t.ClientRequestNumber
				,ContactPersonName = t.ThirdPersonName
				,ContactPersonPhone = NULL
				,ClientContactPersonType = 'ThirdPersonName' 
				,t.RowVersion
				,t.LoadDate
				,ClientRequestClientInfoRowVersion = cast(null as binary(8))
			into dbo.dm_FeodorRequests_ClientContactPerson
			from #ClientContactPerson as t

			create clustered index cli_ClientRequestId_PassportType on dbo.dm_FeodorRequests_ClientContactPerson(ClientRequestId, ClientContactPersonType)

			
		end
			delete t from #ClientContactPerson t
			where exists(select top(1) 1 from dbo.dm_FeodorRequests_ClientContactPerson s where s.ClientRequestId = t.ClientRequestId
				and s.ClientContactPersonType = t.ClientContactPersonType
				and s.TableSource = t.TableSource
				and s.RowVersion =t.RowVersion
				)
			if exists(select top(1) 1 from #ClientContactPerson)
			begin
				begin tran ClientContactPerson
					delete t from dbo.dm_FeodorRequests_ClientContactPerson t
					where exists(select top(1) 1 from #ClientContactPerson s where s.ClientRequestId = t.ClientRequestId
					and s.TableSource = t.TableSource
					and s.ClientContactPersonType = t.ClientContactPersonType)

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
					from #ClientContactPerson
				commit tran
			end
	end
	
	--dm_FeodorRequests_vin
	if exists(select top(1) 1 from #dm_FeodorRequests 
		where nullif(Vin,'') is not null)
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
		into #vin
		from #dm_FeodorRequests t
		where nullif(Vin,'') is not null

		if OBJECT_ID('dbo.dm_FeodorRequests_vin') is null
		begin
			select top(0) 
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,VIN
				,RowVersion
				,LoadDate
				,ClientRequestClientInfoRowVersion = cast(null as binary(8))
			into dbo.dm_FeodorRequests_vin
			from #vin

			create clustered index cli_ClientRequestId on dbo.dm_FeodorRequests_vin(ClientRequestId, TableSource)
		end
		delete t from #vin t
		where exists(select top(1) 1 from dbo.dm_FeodorRequests_vin s where s.ClientRequestId = t.ClientRequestId
			and s.TableSource = t.TableSource
			and s.RowVersion =t.RowVersion)
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
				)
				select
					TableSource	
					,ClientRequestId	
					,ClientRequestNumber
					,VIN
					,RowVersion
					,LoadDate
				from #vin
			
			commit tran
		end
		
	end
	--dm_FeodorRequests_ClientPassport
	if exists(select top(1) 1 from #dm_FeodorRequests 
		where nullif(ClientPassport,'') is not null)
	begin
		drop table if exists #ClientPassport
		/*
		select distinct
			 t.TableSource	
			,t.ClientRequestId	
			,t.ClientRequestNumber
			,Passport = t.ClientPassport
			,PassportType = 'ClientPassport' 
			,t.RowVersion
			,t.LoadDate
			into #ClientPassport
		from #dm_FeodorRequests t
		where nullif(ClientPassport,'') is not null
		*/
		SELECT 
			A.TableSource,
            A.ClientRequestId,
            A.ClientRequestNumber,
            A.Passport,
            A.PassportType,
            A.RowVersion,
            A.LoadDate
		INTO #ClientPassport
		FROM (
			select distinct
				 t.TableSource	
				,t.ClientRequestId	
				,t.ClientRequestNumber
				,Passport = t.ClientPassport
				,PassportType = 'ClientPassport' 
				,t.RowVersion
				,t.LoadDate
				--into #ClientPassport
			from #dm_FeodorRequests t
			where nullif(ClientPassport,'') is not null
			UNION ALL
			select distinct
				 t.TableSource	
				,t.ClientRequestId	
				,t.ClientRequestNumber
				,Passport = t.AuthorPassport
				,PassportType = 'AuthorPassport' 
				,t.RowVersion
				,t.LoadDate
				--into #ClientPassport
			from #dm_FeodorRequests t
			where nullif(AuthorPassport,'') is not null
		) AS A

		if object_id('dm_FeodorRequests_ClientPassport') is null
		begin
			select top(0)
				TableSource,
				ClientRequestId,
				ClientRequestNumber,
				Passport,
				PassportType,
				RowVersion,
				LoadDate,
				ClientRequestClientInfoRowVersion = cast(null as binary(8))
			into dbo.dm_FeodorRequests_ClientPassport
			from #ClientPassport
			create clustered index cli_ClientRequestId_PassportType on dbo.dm_FeodorRequests_ClientPassport(ClientRequestId, PassportType)
		end
			delete t from #ClientPassport t
			where exists(select top(1) 1 from dbo.dm_FeodorRequests_ClientPassport s where s.ClientRequestId = t.ClientRequestId
				and s.PassportType = t.PassportType
				and s.TableSource = t.TableSource
				and s.RowVersion =t.RowVersion
				)
			if exists(select top(1) 1 from #ClientPassport)
			begin
				begin tran ClientPassport
					delete t from dbo.dm_FeodorRequests_ClientPassport t
					where exists(select top(1) 1 from #ClientPassport s where s.ClientRequestId = t.ClientRequestId
					and s.TableSource = t.TableSource
					and s.PassportType = t.PassportType)

					insert into dbo.dm_FeodorRequests_ClientPassport
					(
						TableSource,
						ClientRequestId,
						ClientRequestNumber,
						Passport,
						PassportType,
						RowVersion,
						LoadDate
					)
					select 
						TableSource,
						ClientRequestId,
						ClientRequestNumber,
						Passport,
						PassportType,
						RowVersion,
						LoadDate
					from #ClientPassport
				commit tran
			end
	end
	--dm_FeodorRequests_ClientPhone
	if exists(select top(1) 1 from #dm_FeodorRequests 
		where nullif(coalesce(
		ClientPhoneHome, 
		ClientContactPersonPhone, 
		ClientPhoneMobile, 
		ClientWorkPlacePhone,
		AuthorPhone
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
		
		from #dm_FeodorRequests
		where nullif(ClientWorkPlacePhone,'') is not null

		union
		select 
			TableSource	
			,ClientRequestId	
			,ClientRequestNumber
			,ClientPhoneType = 'AuthorPhone'
			,Phone = AuthorPhone
			,RowVersion
			,LoadDate
		from #dm_FeodorRequests
		where nullif(AuthorPhone,'') is not null

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
				,ClientRequestClientInfoRowVersion = cast(null as binary(8))
			into dbo.dm_FeodorRequests_ClientPhone
			from #dm_FeodorRequests_ClientPhone
			create clustered index cli_ClientRequestId on dbo.dm_FeodorRequests_ClientPhone(ClientRequestId, TableSource)
		end
		delete t from #dm_FeodorRequests_ClientPhone t
		where exists(select top(1) 1 from dbo.dm_FeodorRequests_ClientPhone s where s.ClientRequestId = t.ClientRequestId
			and s.TableSource = t.TableSource
			and s.RowVersion =t.RowVersion
			and s.ClientPhoneType = t.ClientPhoneType)
		if exists (select top(1) 1 from #dm_FeodorRequests_ClientPhone)
		begin
			begin tran ClientPhoneType
				delete t from dbo.dm_FeodorRequests_ClientPhone t
				where exists(select top(1) 1 from #dm_FeodorRequests_ClientPhone s where s.ClientRequestId = t.ClientRequestId
				and s.TableSource = t.TableSource
				and s.ClientPhoneType = t.ClientPhoneType
				and s.RowVersion != t.RowVersion)

				insert into dbo.dm_FeodorRequests_ClientPhone
				(
					TableSource	
					,ClientRequestId	
					,ClientRequestNumber
					,ClientPhoneType
					,Phone
					,RowVersion
					,LoadDate
				)
				select 
					TableSource	
					,ClientRequestId	
					,ClientRequestNumber
					,ClientPhoneType
					,Phone
					,RowVersion
					,LoadDate
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
		from #dm_FeodorRequests
		where nullif(ClientAddressStay ,'') is not null
		--DWH-1454
		union
		select 
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,ClientAddressType = 'AuthorAddressRegistration'
				,PostalCode = dbo.AddressPart_test(AuthorAddressRegistration, 2) collate Cyrillic_General_CI_AS               -- Адрес фактического проживания клиента. Почтовый индекс
				,Address = AuthorAddressRegistration
				,Street = dbo.AddressPart_test(AuthorAddressRegistration, 7) collate Cyrillic_General_CI_AS               -- Адрес фактического проживания клиента. Улица
				,House = dbo.AddressPart_test(AuthorAddressRegistration, 8)
				,RowVersion
				,LoadDate
		from #dm_FeodorRequests
		where nullif(AuthorAddressRegistration,'') is not null
		union
		select 
				TableSource	
				,ClientRequestId	
				,ClientRequestNumber
				,ClientAddressType = 'AuthorAddressStay'
				,PostalCode = dbo.AddressPart_test(AuthorAddressStay, 2) collate Cyrillic_General_CI_AS               -- Адрес фактического проживания клиента. Почтовый индекс
				,Address = AuthorAddressStay
				,Street = dbo.AddressPart_test(AuthorAddressStay, 7) collate Cyrillic_General_CI_AS               -- Адрес фактического проживания клиента. Улица
				,House = dbo.AddressPart_test(AuthorAddressStay, 8)
				,RowVersion
				,LoadDate
		from #dm_FeodorRequests
		where nullif(AuthorAddressStay,'') is not null

		
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
				,ClientRequestClientInfoRowVersion = cast(null as binary(8))
			into dbo.dm_FeodorRequests_ClientAddress
			from #dm_FeodorRequests_ClientAddress
			create clustered index cli on dbo.dm_FeodorRequests_ClientAddress(ClientRequestId, TableSource)
		end
		delete t from #dm_FeodorRequests_ClientAddress t
		where exists(select top(1) 1 from dbo.dm_FeodorRequests_ClientAddress s
			where s.ClientRequestId =t.ClientRequestId
				and s.TableSource = t.TableSource
				and s.ClientAddressType = t.ClientAddressType
				and s.RowVersion = t.RowVersion)
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
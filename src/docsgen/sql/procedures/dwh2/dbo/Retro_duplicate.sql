/*
exec dbo.Retro_duplicate
	--@dtFrom = null,
	--@dtTo = null,
	--@ClientRequestId = null
	@ProcessGUID = '08BB0BE1-6B3B-4EE0-845E-FEEFB5916275'
	,@isDebug = 1
*/
create   PROC dbo.Retro_duplicate
	@dtFrom date = null,
	@dtTo date = null,
	@ClientRequestId uniqueidentifier = null
	,@ProcessGUID uniqueidentifier = null
	,@isDebug int = 0
as
begin
begin TRY
	set nocount ON
	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())

	--Заявка, поступившая в период  с 01.01.2024 по 10.02.2025.
	if @dtFrom is null begin
		select @dtFrom = '2024-01-01'
	end 
	if @dtTo is null begin
		select @dtTo = '2025-02-10'
	end

	select @dtTo = dateadd(day, 1, @dtTo)

	drop table if exists #t_Заявка

	select --top 100
		r.СсылкаЗаявки,
		r.GuidЗаявки,
		r.НомерЗаявки,
		r.ДатаЗаявки
	--select top 10 *
	into #t_Заявка
	from dwh2.dm.v_ЗаявкаНаЗаймПодПТС_и_СтатусыИСобытия as r
	where 1=1
		--Заявка, поступившая в период
		and r.ДатаЗаявки >= @dtFrom and r.ДатаЗаявки < @dtTo
		--Заявка дошла до Call 2
		and r.Call2 is not null
		--test
		and (r.GuidЗаявки = @ClientRequestId or @ClientRequestId is null)
		--Заявка не является тестовой
		-- ?
	
	create index ix1 on #t_Заявка(GuidЗаявки)


	if @isDebug = 1 begin
		drop table if exists ##t_Заявка
		select * into ##t_Заявка from #t_Заявка
	end


	drop table if exists #t_atributes

	select distinct
		r.СсылкаЗаявки,
		r.GuidЗаявки,
		r.НомерЗаявки,
		r.ДатаЗаявки,
		--ФИО Клиента
		ClientName = nullif(trim(d.ClientName), ''), -- СВЕТЛАНА ИВАНОВНА СИДОРКИНА
		ClientFIO = nullif(trim(d.ClientFIO), ''), -- СИДОРКИНА СВЕТЛАНА ИВАНОВНА
		--Телефон организации
		ClientWorkPlacePhone = nullif(trim(d.ClientWorkPlacePhone), ''),
		--Серия и номер паспорта клиента
		ClientPassport = nullif(trim(d.ClientPassport), ''),
		--Мобильный телефон клиента
		ClientPhoneMobile = nullif(trim(d.ClientPhoneMobile), ''),
		--Дополнительный телефон
		ClientContactPersonPhone = nullif(trim(d.ClientContactPersonPhone), ''),
		--Домашний телефон клиента
		ClientPhoneHome = nullif(trim(d.ClientPhoneHome), ''),
		--VIN
		VIN = nullif(trim(d.VIN), '')
	into #t_atributes
	FROM #t_Заявка as r
		inner join Feodor.dbo.v_dm_FeodorRequests as d
			on d.ClientRequestId = r.GuidЗаявки
			and d.TableSource = 'F'

	create index ix1 on #t_atributes(GuidЗаявки)  include(ДатаЗаявки)
	create index ix2 on #t_atributes(ClientFIO, ClientName) include (GuidЗаявки, ДатаЗаявки)
	create index ix3 on #t_atributes(ClientWorkPlacePhone) include (GuidЗаявки, ДатаЗаявки)
	create index ix4 on #t_atributes(ClientPassport) include (GuidЗаявки, ДатаЗаявки)
	create index ix5 on #t_atributes(ClientPhoneMobile) include (GuidЗаявки, ДатаЗаявки)
	create index ix6 on #t_atributes(ClientContactPersonPhone) include (GuidЗаявки, ДатаЗаявки)
	create index ix7 on #t_atributes(ClientPhoneHome) include (GuidЗаявки, ДатаЗаявки)
	create index ix8 on #t_atributes(VIN) include (GuidЗаявки, ДатаЗаявки)


	if @isDebug = 1 begin
		drop table if exists ##t_atributes
		select * into ##t_atributes from #t_atributes
	end

	--select top 10 * from Feodor.dbo.v_dm_FeodorRequests as d

	drop table if exists #t_result
	create table #t_result
	(
		[Номер основной заявки] varchar(30),
		[Guid основной заявки] uniqueidentifier,
		[Дата основной заявки] datetime,

		[Номер дублирующей заявки] varchar(30),
		[Guid дублирующей заявки] uniqueidentifier,
		[Дата дублирующей заявки] datetime,

		[Поле основной заявки] varchar(100),
		[Поле дублирующей заявки] varchar(100),
		[Совпадающее значение поля] nvarchar(500)
	)

	--1a ФИО Клиента = ФИО Клиента
	/*
	--var 1
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'ФИО Клиента',
		[Поле дублирующей заявки] = 'ФИО Клиента',
		[Совпадающее значение поля] = 
			case 
				when t.ClientFIO = a.ClientFIO then a.ClientFIO
				when t.ClientName = a.ClientName then a.ClientName
				else ''
			end
	FROM #t_atributes as a
		inner join Feodor.dbo.dm_FeodorRequests_test AS t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and (t.ClientFIO = a.ClientFIO or t.ClientName = a.ClientName)
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки
	*/

	--var 2
	--1a.1 t.ClientFIO = a.ClientFIO
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'ФИО Клиента',
		[Поле дублирующей заявки] = 'ФИО Клиента',
		[Совпадающее значение поля] = a.ClientFIO
	FROM #t_atributes as a
		inner join Feodor.dbo.dm_FeodorRequests_test AS t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientFIO = a.ClientFIO --t.ClientName = a.ClientName
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--1a.2 t.ClientName = a.ClientName and t.ClientFIO <> a.ClientFIO 
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Имя Отчество Фамилия Клиента',
		[Поле дублирующей заявки] = 'Имя Отчество Фамилия Клиента',
		[Совпадающее значение поля] = a.ClientName
	FROM #t_atributes as a
		inner join Feodor.dbo.dm_FeodorRequests_test AS t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientName = a.ClientName
			and t.ClientFIO <> a.ClientFIO
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки


	--1b ФИО Клиента	 = ФИО третьего лица
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'ФИО Клиента',
		[Поле дублирующей заявки] = 'ФИО третьего лица',
		[Совпадающее значение поля] = t.ContactPersonName
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientContactPersons as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientContactPersonType = 'ThirdPersonName'
			and (t.ContactPersonName = a.ClientFIO or t.ContactPersonName = a.ClientName)
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--1c	ФИО Клиента	 = ФИО Контактного лица
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'ФИО Клиента',
		[Поле дублирующей заявки] = 'ФИО Контактного лица',
		[Совпадающее значение поля] = t.ContactPersonName
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientContactPersons as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientContactPersonType = 'ClientContactPerson'
			and (t.ContactPersonName = a.ClientFIO or t.ContactPersonName = a.ClientName)
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки


	--2 Телефон организации = Телефон организации
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Телефон организации',
		[Поле дублирующей заявки] = 'Телефон организации',
		[Совпадающее значение поля] = a.ClientWorkPlacePhone
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientWorkPlacePhone'
			and t.Phone = a.ClientWorkPlacePhone
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки


	-- 3 Серия и номер паспорта клиента = Серия и номер паспорта клиента
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Серия и номер паспорта клиента',
		[Поле дублирующей заявки] = 'Серия и номер паспорта клиента',
		[Совпадающее значение поля] = a.ClientPassport
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPassports as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.PassportType = 'ClientPassport'
			and t.Passport = a.ClientPassport
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки



	--------------------------------------------------------------------------------
	--4.1. Мобильный телефон клиента = Мобильный телефон клиента
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Мобильный телефон клиента',
		[Поле дублирующей заявки] = 'Мобильный телефон клиента',
		[Совпадающее значение поля] = a.ClientPhoneMobile
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientPhoneMobile'
			and t.Phone = a.ClientPhoneMobile
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--4.2. Мобильный телефон клиента = Дополнительный телефон
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Мобильный телефон клиента',
		[Поле дублирующей заявки] = 'Дополнительный телефон',
		[Совпадающее значение поля] = a.ClientPhoneMobile
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientContactPersonPhone'
			and t.Phone = a.ClientPhoneMobile
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--4.3. Мобильный телефон клиента = Домашний телефон клиента
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Мобильный телефон клиента',
		[Поле дублирующей заявки] = 'Домашний телефон клиента',
		[Совпадающее значение поля] = a.ClientPhoneMobile
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientPhoneHome'
			and t.Phone = a.ClientPhoneMobile
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки
	--------------------------------------------------------------------------------

	--5.1. Дополнительный телефон = Мобильный телефон клиента
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Дополнительный телефон',
		[Поле дублирующей заявки] = 'Мобильный телефон клиента',
		[Совпадающее значение поля] = a.ClientContactPersonPhone
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientPhoneMobile'
			and t.Phone = a.ClientContactPersonPhone
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--5.2. Дополнительный телефон = Дополнительный телефон
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Дополнительный телефон',
		[Поле дублирующей заявки] = 'Дополнительный телефон',
		[Совпадающее значение поля] = a.ClientContactPersonPhone
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientContactPersonPhone'
			and t.Phone = a.ClientContactPersonPhone
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--5.3. Дополнительный телефон = Домашний телефон клиента
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Дополнительный телефон',
		[Поле дублирующей заявки] = 'Домашний телефон клиента',
		[Совпадающее значение поля] = a.ClientContactPersonPhone
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientPhoneHome'
			and t.Phone = a.ClientContactPersonPhone
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки
	--------------------------------------------------------------------------------
	--6.1. Домашний телефон клиента = Мобильный телефон клиента
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Домашний телефон клиента',
		[Поле дублирующей заявки] = 'Мобильный телефон клиента',
		[Совпадающее значение поля] = a.ClientPhoneHome
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientPhoneMobile'
			and t.Phone = a.ClientPhoneHome
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--6.2. Домашний телефон клиента = Дополнительный телефон
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Домашний телефон клиента',
		[Поле дублирующей заявки] = 'Дополнительный телефон',
		[Совпадающее значение поля] = a.ClientPhoneHome
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientContactPersonPhone'
			and t.Phone = a.ClientPhoneHome
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	--6.3. Домашний телефон клиента = Домашний телефон клиента
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'Домашний телефон клиента',
		[Поле дублирующей заявки] = 'Домашний телефон клиента',
		[Совпадающее значение поля] = a.ClientPhoneHome
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_ClientPhones as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.ClientPhoneType = 'ClientPhoneHome'
			and t.Phone = a.ClientPhoneHome
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки

	-----------------------------------------------------------------------------------
	--7 VIN = VIN
	insert #t_result
	(
		[Номер основной заявки], [Guid основной заявки], [Дата основной заявки],
		[Номер дублирующей заявки], [Guid дублирующей заявки], [Дата дублирующей заявки],
		[Поле основной заявки], [Поле дублирующей заявки], [Совпадающее значение поля]
	)
	select distinct
		[Номер основной заявки] = a.НомерЗаявки,
		[Guid основной заявки] = a.GuidЗаявки,
		[Дата основной заявки] = a.ДатаЗаявки,

		[Номер дублирующей заявки] = h.НомерЗаявки,
		[Guid дублирующей заявки] = h.GuidЗаявки,
		[Дата дублирующей заявки] = h.ДатаЗаявки,

		[Поле основной заявки] = 'VIN',
		[Поле дублирующей заявки] = 'VIN',
		[Совпадающее значение поля] = a.Vin
	FROM #t_atributes as a
		inner join Feodor.dbo.v_dm_FeodorRequests_vin as t
			on t.ClientRequestId <> a.GuidЗаявки
			and t.TableSource = 'F'
			and t.Vin = a.Vin
		inner join dwh2.hub.Заявка as h
			on h.GuidЗаявки = t.ClientRequestId
			and h.ДатаЗаявки < a.ДатаЗаявки


	if @isDebug = 1 begin
		drop table if exists ##t_result
		select * into ##t_result from #t_result
	end

	if OBJECT_ID('dbo.Retro_duplicate_result') is null
	begin
		create table dbo.Retro_duplicate_result
		(
			created_at datetime not null, --CURRENT_TIMESTAMP
			ProcessGUID uniqueidentifier not null,

			[Номер основной заявки] varchar(30),
			[Guid основной заявки] uniqueidentifier,
			[Дата основной заявки] datetime,
			[Источник основной заявки] varchar(1),

			[Номер дублирующей заявки] varchar(30),
			[Guid дублирующей заявки] uniqueidentifier,
			[Дата дублирующей заявки] datetime,
			[Источник дублирующей заявки] varchar(1),

			[Поле основной заявки] varchar(100),
			[Поле дублирующей заявки] varchar(100),
			[Совпадающее значение поля] nvarchar(500)
		)

		create index ix1_Retro_duplicate_result
		on dbo.Retro_duplicate_result([Номер основной заявки], [Номер дублирующей заявки])
		include ([Guid основной заявки],[Guid дублирующей заявки])

		create index ix2_Retro_duplicate_result
		on dbo.Retro_duplicate_result(ProcessGUID, [Номер основной заявки], [Номер дублирующей заявки])
		include ([Guid основной заявки],[Guid дублирующей заявки])
	end

	begin tran

		delete r
		from dbo.Retro_duplicate_result as r
		where r.ProcessGUID = @ProcessGUID

		insert into dbo.Retro_duplicate_result
		(
			created_at,
			ProcessGUID,

			[Номер основной заявки],
			[Guid основной заявки],
			[Дата основной заявки],
			[Источник основной заявки],

			[Номер дублирующей заявки],
			[Guid дублирующей заявки],
			[Дата дублирующей заявки],
			[Источник дублирующей заявки],

			[Поле основной заявки],
			[Поле дублирующей заявки],
			[Совпадающее значение поля]
		)
		select 
			created_at = CURRENT_TIMESTAMP,
			ProcessGUID = @ProcessGUID,
			r.[Номер основной заявки],
			r.[Guid основной заявки],
			r.[Дата основной заявки],
			[Источник основной заявки] = 'F',

			r.[Номер дублирующей заявки],
			r.[Guid дублирующей заявки],
			r.[Дата дублирующей заявки],
			[Источник дублирующей заявки] = 'F',

			r.[Поле основной заявки],
			r.[Поле дублирующей заявки],
			r.[Совпадающее значение поля]

		from #t_result as r

	commit tran 

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch
end

create   PROC sat.fill_ДоговорЗайма_КоличествоДнейПросрочки_SCD2
	@mode int = 2, 
	-- 0 - полный пересчет, 
	-- 1 - пересчет по действующим за все время жизни договора 
	-- 2 - пересчет по действующим с небольшой глубиной
	-- 3 - пересчет по договорам из sat.ДоговорЗайма_КоличествоДнейПросрочки_change за все время жизни договора 
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @date_from date = '2000-01-01'

	if object_id('sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2') is not null
		and @mode in (1, 2)
		--test
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		select @date_from = isnull(dateadd(day,-30, max(date_from)), '2000-01-01')
		from sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
	end

	IF @isDebug = 1 BEGIN
		select date_from = @date_from
	end

	--Договора
	drop table if exists #t_ДоговорЗайма
	create table #t_ДоговорЗайма
	(
		КодДоговораЗайма nvarchar(21),
		СсылкаДоговораЗайма binary(16),
		ДатаДоговораЗайма date,
		ДатаЗакрытияДоговора date
	)

	DROP TABLE IF EXISTS #t_change
	CREATE TABLE #t_change
	(
		КодДоговораЗайма nvarchar(14) NOT NULL,
		id uniqueidentifier NOT NULL
	)

	-- 3 - пересчет по договорам из sat.ДоговорЗайма_КоличествоДнейПросрочки_change за все время жизни договора 
	if @mode in (3) begin
		insert #t_change(КодДоговораЗайма, id)
		SELECT C.КодДоговораЗайма, id
		FROM sat.ДоговорЗайма_КоличествоДнейПросрочки_change AS C

		create clustered index cix_id on #t_change(id)
		create index cix_КодДоговораЗайма on #t_change(КодДоговораЗайма)

		insert #t_ДоговорЗайма
		(
			КодДоговораЗайма,
			СсылкаДоговораЗайма,
			ДатаДоговораЗайма,
			ДатаЗакрытияДоговора
		)
		select distinct
			h.КодДоговораЗайма,
			h.СсылкаДоговораЗайма,
			ДатаДоговораЗайма = cast(h.ДатаДоговораЗайма as date),
			ДатаЗакрытияДоговора = cast(h.ДатаЗакрытияДоговора as date)
		from #t_change as t
			inner join hub.ДоговорЗайма as h
				on h.КодДоговораЗайма = t.КодДоговораЗайма
	end
	else begin
		insert #t_ДоговорЗайма
		(
			КодДоговораЗайма,
			СсылкаДоговораЗайма,
			ДатаДоговораЗайма,
			ДатаЗакрытияДоговора
		)
		select distinct
			h.КодДоговораЗайма,
			h.СсылкаДоговораЗайма,
			ДатаДоговораЗайма = cast(h.ДатаДоговораЗайма as date),
			ДатаЗакрытияДоговора = cast(h.ДатаЗакрытияДоговора as date)
		from hub.ДоговорЗайма as h
			inner join Stg.dbo._1cАналитическиеПоказатели as ap
				on ap.Договор = h.СсылкаДоговораЗайма
				and ap.Период >= @date_from
			--только те договора у которых был статус Действует
			--inner join sat.ДоговорЗайма_Статусы as s
			--	on s.КодДоговораЗайма = h.КодДоговораЗайма
			--	and s.СтатусДоговора = 'Действует'
		where 1=1
			and (h.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
			and (h.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
			and (h.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

		--Договора которые были погашены за последние ... дней
		union
		select
			h.КодДоговораЗайма,
			h.СсылкаДоговораЗайма,
			ДатаДоговораЗайма = cast(h.ДатаДоговораЗайма as date),
			ДатаЗакрытияДоговора = cast(h.ДатаЗакрытияДоговора as date)
		from hub.ДоговорЗайма as h
		where h.ДатаЗакрытияДоговора >= @date_from
			and (h.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
			and (h.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
			and (h.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)
	end

	create index ix1 on #t_ДоговорЗайма(СсылкаДоговораЗайма)

	IF @isDebug = 1 BEGIN
		drop table if exists ##t_ДоговорЗайма
		select * into ##t_ДоговорЗайма from #t_ДоговорЗайма
	end


	drop table if exists #t_ДоговорЗайма_Календарь

	create table #t_ДоговорЗайма_Календарь
	(
		КодДоговораЗайма nvarchar(21), 
		СсылкаДоговораЗайма binary(16), 
		date_from date
	)


	-- 0 - полный пересчет, 
	-- 1 - пересчет по действующим за все время жизни договора 
	-- или пересчет по конкретному договору
	if  @mode in (0, 1, 3)
		--test
		or @СсылкаДоговораЗайма is not null
		or @GuidДоговораЗайма is not null
		or @КодДоговораЗайма is not null
	begin
		insert #t_ДоговорЗайма_Календарь
		(
			КодДоговораЗайма, 
			СсылкаДоговораЗайма, 
			date_from
		)
		select distinct
			d.КодДоговораЗайма, 
			d.СсылкаДоговораЗайма, 
			date_from = calendar.DT
		from #t_ДоговорЗайма as d
			inner join Dictionary.calendar as calendar
				on calendar.DT between 
					d.ДатаДоговораЗайма 
					and isnull(d.ДатаЗакрытияДоговора, getdate())
	end

	-- 2 - пересчет по действующим с небольшой глубиной
	if  @mode in (2)
		--test
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		insert #t_ДоговорЗайма_Календарь
		(
			КодДоговораЗайма, 
			СсылкаДоговораЗайма, 
			date_from
		)
		select distinct
			d.КодДоговораЗайма, 
			d.СсылкаДоговораЗайма, 
			date_from = calendar.DT
		from #t_ДоговорЗайма as d
			inner join Dictionary.calendar as calendar
				-- глубина - не больше @date_from
				on calendar.DT >= @date_from
				and calendar.DT >= d.ДатаДоговораЗайма
				and calendar.DT <= isnull(d.ДатаЗакрытияДоговора, getdate())
	end


	create index ix1 on #t_ДоговорЗайма_Календарь(СсылкаДоговораЗайма, date_from)

	IF @isDebug = 1 BEGIN
		drop table if exists ##t_ДоговорЗайма_Календарь
		select * into ##t_ДоговорЗайма_Календарь from #t_ДоговорЗайма_Календарь
	end

	drop table if exists #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1

	create table #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1
	(
		id int identity(1,1),
		КодДоговораЗайма nvarchar(14), 
		date_from_prev date,
		date_from date,
		КоличествоДнейПросрочкиНаНачалоДня int,
		КоличествоДнейПросрочкиНаКонецДня int
	)

	insert #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1
	(
		КодДоговораЗайма, 
		date_from_prev,
		date_from,
		КоличествоДнейПросрочкиНаНачалоДня,
		КоличествоДнейПросрочкиНаКонецДня
	)
	select
		dc.КодДоговораЗайма, 
		--dc.СсылкаДоговораЗайма, 
		--dc.ДатаДоговораЗайма,
		--dc.ДатаЗакрытияДоговора,
		date_from_prev = dateadd(day, -1, dc.date_from),
		dc.date_from,

		--данные на начало дня
		КоличествоДнейПросрочкиНаНачалоДня = isnull(iif(dc.date_from = d.ДатаДоговораЗайма, 0, t_min.КоличествоПолныхДнейПросрочкиУМФО),0),
		--ДатаВозникновенияПросрочки = cast(t_min.ДатаВозникновенияПросрочкиУМФО as date),
		--,[КоличествоПолныхДнейПросрочкиУМФО_begin_day]	= iif(dc.date_from = d.ДатаДоговораЗайма, 0, t_min.КоличествоПолныхДнейПросрочкиУМФО	)
		--,[КоличествоПолныхДнейПросрочки_begin_day]		= iif(dc.date_from = d.ДатаДоговораЗайма, 0, t_min.КоличествоПолныхДнейПросрочки		)
		--,ПросроченнаяЗадолженность_begin_day 			= iif(dc.date_from = d.ДатаДоговораЗайма, isnull(t_min.ПросроченнаяЗадолженность,0), t_min.ПросроченнаяЗадолженность)

		--данные на конец дня
		КоличествоДнейПросрочкиНаКонецДня = isnull(iif(dc.date_from = d.ДатаДоговораЗайма, 0, t_max.КоличествоПолныхДнейПросрочкиУМФО),0)
		--ДатаВозникновенияПросрочкиНаКонецДня = t_max.ДатаВозникновенияПросрочкиУМФО
		--,КоличествоПолныхДнейПросрочкиУМФО = iif(dc.date_from = d.ДатаДоговораЗайма, 0, t_max.КоличествоПолныхДнейПросрочкиУМФО	)
		--,КоличествоПолныхДнейПросрочки = iif(dc.date_from = d.ДатаДоговораЗайма, 0, t_max.КоличествоПолныхДнейПросрочки		)
		--,ПросроченнаяЗадолженность = iif(dc.date_from = d.ДатаДоговораЗайма, isnull(t_max.ПросроченнаяЗадолженность,0), t_max.ПросроченнаяЗадолженность)

	--into #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2
	from #t_ДоговорЗайма as d
		inner join #t_ДоговорЗайма_Календарь as dc
			on dc.СсылкаДоговораЗайма = d.СсылкаДоговораЗайма
		--данные на начало дня
		left join (
			select
				t.Договор
				,Период_dt = cast(t.Период as date)
				,t.Период
				,nRow = row_number() over(
					partition by t.Договор, cast(t.Период as date) 
					order by t.Период
				) -- только первая запись в рамках дня
				,t.КоличествоПолныхДнейПросрочкиУМФО
				--,t.КоличествоПолныхДнейПросрочки
				--,t.ПросроченнаяЗадолженность
				--,t.ДатаВозникновенияПросрочкиУМФО
			from Stg.dbo._1cАналитическиеПоказатели as t
				where 1=1
				and exists(
					select top(1) 1 
					from #t_ДоговорЗайма as d
					where t.Договор = d.СсылкаДоговораЗайма
				)
		) as t_min
		on t_min.Договор = dc.СсылкаДоговораЗайма
			and t_min.Период_dt = dc.date_from
			--and t_min.Период = ap.min_Период
			and t_min.nRow = 1 --интересует только первая запись
		--данные на конец дня
		left join (
			select t.Договор
				,Период_dt = cast(t.Период as date)
				,t.Период
				,nRow = row_number() over(
					partition by t.Договор,	cast(t.Период as date)
					order by t.Период desc,	t.Регистратор_Ссылка desc
				) -- только крайня запись в рамках дня
				,t.КоличествоПолныхДнейПросрочкиУМФО
				--,t.КоличествоПолныхДнейПросрочки
				--,t.ПросроченнаяЗадолженность
				--,t.ДатаВозникновенияПросрочкиУМФО
			from Stg.dbo._1cАналитическиеПоказатели as t
			where 1=1
				and exists(
					select top(1) 1 
					from #t_ДоговорЗайма as d
					where t.Договор = d.СсылкаДоговораЗайма
				)
		) as t_max 
		on t_max.Договор = dc.СсылкаДоговораЗайма
			and t_max.Период_dt = dc.date_from
			--and t_max.Период	= ap.max_Период
			and t_max.nRow = 1 --интересует только первая запись


	create index ix0
	on #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1(id)

	create index ix1
	on #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1(КодДоговораЗайма, date_from)
	include (id, КоличествоДнейПросрочкиНаНачалоДня, КоличествоДнейПросрочкиНаКонецДня)

	create index ix2
	on #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1(КодДоговораЗайма, date_from_prev)
	include (id, КоличествоДнейПросрочкиНаНачалоДня, КоличествоДнейПросрочкиНаКонецДня)

	IF @isDebug = 1 BEGIN
		drop table if exists ##t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1
		select * into ##t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1 from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1
	end


	/*
	--удалить дубли
	--var 1
	delete b
	from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1 as b
	--есть предыдущее значение с теми же показателями
	where exists(
			select top(1) 1
			from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1 as a
			where 1=1
				and a.КодДоговораЗайма = b.КодДоговораЗайма
				and a.date_from = b.date_from_prev
				and a.КоличествоДнейПросрочкиНаНачалоДня = b.КоличествоДнейПросрочкиНаНачалоДня
				and a.КоличествоДнейПросрочкиНаКонецДня = b.КоличествоДнейПросрочкиНаКонецДня
		)
	*/

	--удалить дубли
	drop table if exists #t_id
	create table #t_id(id int)

	insert #t_id(id)
	--все
	select t.id from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1 as t
	except
	--дубли
	select b.id
	from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1 as b
	--есть предыдущее значение с теми же показателями
		inner join #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1 as a
			on a.КодДоговораЗайма = b.КодДоговораЗайма
			and a.date_from = b.date_from_prev
			and a.КоличествоДнейПросрочкиНаНачалоДня = b.КоличествоДнейПросрочкиНаНачалоДня
			and a.КоличествоДнейПросрочкиНаКонецДня = b.КоличествоДнейПросрочкиНаКонецДня

	create index ix0 on #t_id(id)

	drop table if exists #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2

	select
		a.КодДоговораЗайма, 
		a.date_from,
		a.КоличествоДнейПросрочкиНаНачалоДня,
		a.КоличествоДнейПросрочкиНаКонецДня
	into #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2
	from #t_id as t
		inner join #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2_1 as a
			on t.id = a.id

	create index ix1
	on #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2(КодДоговораЗайма, date_from)
	include (КоличествоДнейПросрочкиНаНачалоДня, КоличествоДнейПросрочкиНаКонецДня)

	IF @isDebug = 1 BEGIN
		drop table if exists ##t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2
		select * into ##t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2 from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2
	end


	if OBJECT_ID('sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2') is null
	begin
		select top(0)
			КодДоговораЗайма,
			date_from,
			date_to = cast(null as date),
			КоличествоДнейПросрочкиНаНачалоДня,
			КоличествоДнейПросрочкиНаКонецДня,
            created_at = cast(null as datetime),
            updated_at = cast(null as datetime),
            spFillName = cast(null as nvarchar(255))
		into sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
		from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2

		alter table sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			alter column КодДоговораЗайма nvarchar(14) not null

		alter table sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			alter column date_from date not null

		alter table sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			alter column date_to date not null

		alter table sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			alter column КоличествоДнейПросрочкиНаНачалоДня int not null
		
		alter table sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			alter column КоличествоДнейПросрочкиНаКонецДня int not null

		ALTER TABLE sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			ADD CONSTRAINT PK_ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			PRIMARY KEY CLUSTERED (КодДоговораЗайма, date_from, date_to)

		--create unique index ix_КодДоговораЗайма_date_from
		--on sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2(КодДоговораЗайма, date_from)
		--include(date_to, КоличествоДнейПросрочкиНаНачалоДня, КоличествоДнейПросрочкиНаКонецДня)

		create unique index ix_КодДоговораЗайма_date_from
		on sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2(КодДоговораЗайма, date_from)
	end

	-- удалить то, что не изменилось
	--DELETE s
	--FROM #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2 AS s
	--	INNER JOIN sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2 AS t
	--		ON t.КодДоговораЗайма = s.КодДоговораЗайма
	--		AND s.date_from BETWEEN t.date_from AND t.date_to
	--		AND t.КоличествоДнейПросрочкиНаНачалоДня = s.КоличествоДнейПросрочкиНаНачалоДня
	--		AND t.КоличествоДнейПросрочкиНаКонецДня = s.КоличествоДнейПросрочкиНаКонецДня

	-- удалить существующие показатели для t.date_from >= s.date_from
	DELETE t
	FROM #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2 AS s
		INNER JOIN sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2 AS t
			ON t.КодДоговораЗайма = s.КодДоговораЗайма
			AND t.date_from >= s.date_from

	if exists(select top(1) 1 from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2)
	begin
		begin tran
			if @mode = 0 begin
				truncate table sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2
			end

			merge sat.ДоговорЗайма_КоличествоДнейПросрочки_SCD2 AS t
			using #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2 AS s
				on t.КодДоговораЗайма = s.КодДоговораЗайма
				AND t.date_from = s.date_from
			when not matched then insert
			(
				КодДоговораЗайма,
				date_from,
				date_to,
				КоличествоДнейПросрочкиНаНачалоДня,
				КоличествоДнейПросрочкиНаКонецДня,

				created_at,
				updated_at,
				spFillName
			) values
			(
				s.КодДоговораЗайма,
				s.date_from,
				s.date_from,
				s.КоличествоДнейПросрочкиНаНачалоДня,
				s.КоличествоДнейПросрочкиНаКонецДня,
				CURRENT_TIMESTAMP,
				CURRENT_TIMESTAMP,
				@spName
			)
			when matched and (
				t.КоличествоДнейПросрочкиНаНачалоДня <> s.КоличествоДнейПросрочкиНаНачалоДня
				or t.КоличествоДнейПросрочкиНаКонецДня <> s.КоличествоДнейПросрочкиНаКонецДня
				)
			then update SET
				t.КоличествоДнейПросрочкиНаНачалоДня = s.КоличествоДнейПросрочкиНаНачалоДня,
				t.КоличествоДнейПросрочкиНаКонецДня = s.КоличествоДнейПросрочкиНаКонецДня,
				t.updated_at = CURRENT_TIMESTAMP,
				t.spFillName = @spName
			;

			DELETE C
			FROM sat.ДоговорЗайма_КоличествоДнейПросрочки_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
		commit tran
	end 
	--//exists(select top(1) 1 from #t_ДоговорЗайма_КоличествоДнейПросрочки_SCD2)

END try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

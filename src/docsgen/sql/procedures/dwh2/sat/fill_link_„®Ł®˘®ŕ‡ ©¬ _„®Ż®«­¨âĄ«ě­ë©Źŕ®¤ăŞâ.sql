--exec sat.fill_link_ДоговорЗайма_ДополнительныйПродукт
create   PROC sat.fill_link_ДоговорЗайма_ДополнительныйПродукт
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.link_ДоговорЗайма_ДополнительныйПродукт
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @ДатаСтатусаДействует datetime2(0) = '2000-01-01'
	declare @ДатаВыдачиДенежныхСредств datetime2(0) = '2000-01-01'

	if OBJECT_ID ('sat.link_ДоговорЗайма_ДополнительныйПродукт') is not null
		and @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		select 
			--@rowVersion = isnull(max(s.ВерсияДанных) - 100, 0x0),
			@rowVersion = isnull(cast(max(cast(s.ВерсияДанных as bigint)) - 100000 as binary(8)), 0x0),
			@ДатаСтатусаДействует = isnull(dateadd(day, -30, max(s.ДатаСтатусаДействует)), '2000-01-01'),
			@ДатаВыдачиДенежныхСредств = isnull(dateadd(day, -30, max(s.ДатаВыдачиДенежныхСредств)), '2000-01-01')
		from sat.link_ДоговорЗайма_ДополнительныйПродукт as s
	end

	--список договоров, у которых появились/обновились доп продукты
	drop table if exists #t_ДоговорЗайма
	create table #t_ДоговорЗайма
	(
		СсылкаДоговораЗайма binary(16),
		GuidДоговораЗайма uniqueidentifier,
		КодДоговораЗайма nvarchar(14),

		ДатаДоговораЗайма datetime2(0),
		ДатаСтатусаДействует datetime2(0),
		ДатаВыдачиДенежныхСредств datetime2(0)
	)

	insert #t_ДоговорЗайма(
		СсылкаДоговораЗайма,
		GuidДоговораЗайма,
		КодДоговораЗайма,

		ДатаДоговораЗайма,
		ДатаСтатусаДействует,
		ДатаВыдачиДенежныхСредств
	)
	select 
		d.СсылкаДоговораЗайма,
		d.GuidДоговораЗайма,
		d.КодДоговораЗайма,
		d.ДатаДоговораЗайма,
		--ДатаСтатусаДействует = ds.ДатаСтатуса,
		ДатаСтатусаДействует = max(ds.ДатаСтатуса),
		--ДатаВыдачиДенежныхСредств = dateadd(year, -2000, dvds.ДатаВыдачи)
		ДатаВыдачиДенежныхСредств = max(dateadd(year, -2000, dvds.ДатаВыдачи))
	FROM link.ДоговорЗайма_ДополнительныйПродукт as link
		inner join hub.ДоговорЗайма as d
			on d.КодДоговораЗайма = link.КодДоговораЗайма
		inner join sat.ДоговорЗайма_Статусы as ds
			on ds.КодДоговораЗайма = d.КодДоговораЗайма
			and ds.СтатусДоговора = 'Действует'
		inner join Stg._1cCMR.Документ_выдачаДенежныхСредств as dvds
			on dvds.Договор = d.СсылкаДоговораЗайма
			and dvds.Проведен = 0x01
			and dvds.ПометкаУдаления = 0x00
	where 1=1
		and (
			--1 появились/обновились доп продукты
			link.ВерсияДанных > @rowVersion
			--2 появился статус 'Действует'
			or ds.ДатаСтатуса > dateadd(year, 2000, @ДатаСтатусаДействует)
			--3 произошла выдача ДенежныхСредств
			or dvds.ДатаВыдачи > dateadd(year, 2000, @ДатаВыдачиДенежныхСредств)
			)
		and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
		and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)
	group by
		d.СсылкаДоговораЗайма,
		d.GuidДоговораЗайма,
		d.КодДоговораЗайма,
		d.ДатаДоговораЗайма

	if @isDebug = 1
	begin
		drop table if exists ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
	end

	drop table if exists #t_sat_link_1

	select --top 10 
		link.GuidLink_ДоговорЗайма_ДополнительныйПродукт,
		--
		t.СсылкаДоговораЗайма,
		t.GuidДоговораЗайма,
		t.КодДоговораЗайма,
		--
		ДатаДоговораЗайма = cast(t.ДатаДоговораЗайма as date),
		t.ДатаСтатусаДействует,
		t.ДатаВыдачиДенежныхСредств,
		--
		p.GuidДополнительныйПродукт,
		p.СсылкаДополнительныйПродукт,
		--
		dp.КлючЗаписи,
		dp.НомерСтроки,
		dp.ДоговорДопПродукта,
		Сумма = cast(dp.Сумма as money),
		dp.ВключатьВСуммуЗайма,
		--
		link.ВерсияДанных,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_sat_link_1
	FROM #t_ДоговорЗайма as t
		inner join link.ДоговорЗайма_ДополнительныйПродукт as link
			on link.КодДоговораЗайма = t.КодДоговораЗайма
		inner join hub.ДополнительныйПродукт as p
			on p.GuidДополнительныйПродукт = link.GuidДополнительныйПродукт
		inner join Stg._1cCMR.Справочник_Договоры_ДополнительныеПродукты AS dp
			on dp.Ссылка = t.СсылкаДоговораЗайма
			and dp.ДополнительныйПродукт = p.СсылкаДополнительныйПродукт

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_1
		SELECT * INTO ##t_sat_link_1 FROM #t_sat_link_1
		--RETURN 0
	END

	drop table if exists #t_sat_link_ДоговорЗайма_ДополнительныйПродукт

	;with Commiss as (
		select 
			v.*
			,cp.ProductName
			,cp.Commission
			,FixedСommission = cast(cp.FixedСommission as money)

			--var 1
			--логика из PROC dbo.CalculateOnlineDashBoard
			--для доп. продукта "Помощь бизнесу" VAT считается в зависимости от значения поля ДатаВыдачи
			--для остальных доп. продуктов - в зависимости от поля ДатаДоговора
			--,VAT = 
			--	case 
			--		when cp.ProductName = 'Помощь бизнесу'
			--		then
			--			case 
			--				when v.ДатаВыдачиДенежныхСредств between cp.VATAccountingFrom and cp.VATAccountingTo
			--					and cp.Commission > 0
			--				then 20
			--				else null
			--			end
			--		else
			--			case 
			--				when v.ДатаДоговораЗайма between cp.VATAccountingFrom and cp.VATAccountingTo
			--					and cp.Commission > 0
			--				then 20
			--				else null
			--			end
			--	end

			--var 2
			--Делаем однотипно - по ДатаДоговораЗайма
			,VAT = 
				case 
					when v.ДатаДоговораЗайма between cp.VATAccountingFrom and cp.VATAccountingTo
						and cp.Commission > 0
					then 20.0
					else null
				end
			--,cp.*
		from #t_sat_link_1 as v
			left join (
				select  
					cp.ProductId,
					ProductName = cp.ProductName,
					--Commission = isnull(cp.Commission,  cp.FixedСommission), 
					cp.Commission,
					cp.FixedСommission, 
					DateStart =  cast(cp.DateStart as date), 
					DateEnd  = cast(isnull(cp.DateEnd, getdate()) as date),
					VATAccountingFrom,
					VATAccountingTo	
				from stg._mds.hdbkPartnerFeeCP as cp
			) as cp
			on cp.ProductId = v.GuidДополнительныйПродукт
			and v.ДатаДоговораЗайма between cp.DateStart and cp.DateEnd
	)
	--select * from Commiss as c
	, Commiss_2 as (
		select 
			c.* 
			--,without_partner_bounty = 
			,СуммаБезВознагражденияПартнера = 
			cast(
				case
					-- комиссия в %%
					when c.Commission is not null 
						then c.Сумма * (1.0 - c.Commission / 100.0)
					-- фикс. комиссия
					else c.Сумма - isnull(c.FixedСommission, 0)
				end
			as money)
		from Commiss as c
	)
	--select * from Commiss_2
	select 
		c.*
		,NET = 
			round(
			cast(

			--var 1
			--логика из PROC dbo.CalculateOnlineDashBoard
			--case
			--	when c.VAT is not null
			--		then c.СуммаБезВознагражденияПартнера * (1-0.2/1.2)
			--	else c.СуммаБезВознагражденияПартнера - (c.Сумма - c.СуммаБезВознагражденияПартнера)/6.0
			--end

			--var 2
			--та же логика с использованием значения VAT из cte Commiss
			case
				when c.VAT is not null
					then c.СуммаБезВознагражденияПартнера * (1.0 - c.VAT / (100.0 + c.VAT) )
					--then cast(c.СуммаБезВознагражденияПартнера as float) * 
					--	(1.0 - cast(c.VAT as float) / (100.0 + cast(c.VAT as float)) )
				-- откуда этот алгоритм расчета NET для случая, когда по доп. продукту нет НДС ?
				else c.СуммаБезВознагражденияПартнера - (c.Сумма - c.СуммаБезВознагражденияПартнера)/6.0
			end
		as money)
		, 2)

	into #t_sat_link_ДоговорЗайма_ДополнительныйПродукт
	from Commiss_2 as c

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_ДоговорЗайма_ДополнительныйПродукт
		SELECT * INTO ##t_sat_link_ДоговорЗайма_ДополнительныйПродукт FROM #t_sat_link_ДоговорЗайма_ДополнительныйПродукт
		--RETURN 0
	END


	if OBJECT_ID('sat.link_ДоговорЗайма_ДополнительныйПродукт') is null
	begin
		select top(0)
			GuidLink_ДоговорЗайма_ДополнительныйПродукт,
			--
			--СсылкаДоговораЗайма,
			--GuidДоговораЗайма,
			--КодДоговораЗайма,
			--
			--ДатаДоговораЗайма,
			ДатаСтатусаДействует,
			ДатаВыдачиДенежныхСредств,
			--
			КлючЗаписи,
			НомерСтроки,
			ДоговорДопПродукта,
			ВключатьВСуммуЗайма,
			--
			Сумма,
			Commission,
			FixedСommission,
			VAT,
			СуммаБезВознагражденияПартнера,
			NET,
			--
			ВерсияДанных,
            created_at,
            updated_at,
            spFillName
		into sat.link_ДоговорЗайма_ДополнительныйПродукт
		from #t_sat_link_ДоговорЗайма_ДополнительныйПродукт

		alter table sat.link_ДоговорЗайма_ДополнительныйПродукт
			alter column GuidLink_ДоговорЗайма_ДополнительныйПродукт uniqueidentifier not null

		ALTER TABLE sat.link_ДоговорЗайма_ДополнительныйПродукт
			ADD CONSTRAINT PK_Link_ДоговорЗайма_ДополнительныйПродукт PRIMARY KEY CLUSTERED (GuidLink_ДоговорЗайма_ДополнительныйПродукт)
	end

	begin tran
		--удалить/вставить все доп продукты для списка договоров
		delete s
		FROM #t_ДоговорЗайма as t
			inner join link.ДоговорЗайма_ДополнительныйПродукт as link
				on link.КодДоговораЗайма = t.КодДоговораЗайма
			inner join sat.link_ДоговорЗайма_ДополнительныйПродукт as s
				on s.GuidLink_ДоговорЗайма_ДополнительныйПродукт = link.GuidLink_ДоговорЗайма_ДополнительныйПродукт

		insert sat.link_ДоговорЗайма_ДополнительныйПродукт
		(
			GuidLink_ДоговорЗайма_ДополнительныйПродукт,
			--
			--СсылкаДоговораЗайма,
			--GuidДоговораЗайма,
			--КодДоговораЗайма,
			--
			--ДатаДоговораЗайма,
			ДатаСтатусаДействует,
			ДатаВыдачиДенежныхСредств,
			--
			КлючЗаписи,
			НомерСтроки,
			ДоговорДопПродукта,
			ВключатьВСуммуЗайма,
			--
			Сумма,
			Commission,
			FixedСommission,
			VAT,
			СуммаБезВознагражденияПартнера,
			NET,
			--
			ВерсияДанных,
            created_at,
            updated_at,
            spFillName
		)
		select 
			GuidLink_ДоговорЗайма_ДополнительныйПродукт,
			--
			--СсылкаДоговораЗайма,
			--GuidДоговораЗайма,
			--КодДоговораЗайма,
			--
			--ДатаДоговораЗайма,
			ДатаСтатусаДействует,
			ДатаВыдачиДенежныхСредств,
			--
			КлючЗаписи,
			НомерСтроки,
			ДоговорДопПродукта,
			ВключатьВСуммуЗайма,
			--
			Сумма,
			Commission,
			FixedСommission,
			VAT,
			СуммаБезВознагражденияПартнера,
			NET,
			--
			ВерсияДанных,
            created_at,
            updated_at,
            spFillName
		from #t_sat_link_ДоговорЗайма_ДополнительныйПродукт
	commit tran

end try
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

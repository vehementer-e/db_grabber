--DWH-1190
--drop table dm_CMRExpectedRepayments

--[dbo].[Create_dm_CMRExpectedRepayments] 
CREATE PROC dm.fill_CMRExpectedRepayments
	 @mode int = 1
	 ,@reCreateTable bit =  0
	 ,@GuidДоговораЗайма nvarchar(36) = null
	 ,@isDebug int = null
as
begin
/*BP-1915
	добавили поля ОД, Процент, [ПризнакПоследнийПлатежИспытательныйСрок]

	DWH-1597 - 
	Добавили ДатаСледующегоПлатежа
	alter table dm_CMRExpectedRepayments
		add ДатаСледПлатежа date
*/

select @isDebug = isnull(@isDebug, 0)
select @mode = isnull(@mode, 1)

declare @rowVersion binary(8) = 0x0

if object_id('dm.CMRExpectedRepayments') is not null
	AND @mode = 1
	and @GuidДоговораЗайма is NULL
begin
	SELECT 
		@rowVersion = isnull(max(S.ВерсияДанных), 0x0)
	FROM dm.CMRExpectedRepayments AS S

	if @rowVersion <> 0x0 begin
		select @rowVersion = @rowVersion - 100
	end
end

drop table if exists #t_СписокДоговоров
create table #t_СписокДоговоров(Договор binary(16))

if @GuidДоговораЗайма is not NULL
begin
	insert #t_СписокДоговоров(Договор)
	select Договор = stg.dbo.get1CIDRREF_FromGUID(@GuidДоговораЗайма)
end
else begin
	insert #t_СписокДоговоров(Договор)
	select distinct s.Договор
	from stg._1cCMR.Документ_ГрафикПлатежей s with(nolock)
	where s.ВерсияДанных >= @rowVersion
end

create index ix1 on #t_СписокДоговоров(Договор)

if @isDebug = 1 begin
	drop table if exists ##t_СписокДоговоров
	select * into ##t_СписокДоговоров from #t_СписокДоговоров
end


drop table if exists #t_ResultДанныеГрафикаПлатежей
select 
	  g.Договор 
	, Регистратор = g.Регистратор_Ссылка
	, ДатаПлатежа = cast(iif(year(g.ДатаПлатежа)>3000, dateadd(year, -2000, g.ДатаПлатежа), g.ДатаПлатежа) as date)
	, g.СуммаПлатежа
	, g.ОД
	, g.Процент
	, Период = cast(iif(year(g.Период)>3000, dateadd(year, -2000, g.Период), g.Период) as date)
	, ПоследняДатаПлатежа = cast(max(
				iif(year(g.Период)>3000, dateadd(year, -2000, g.ДатаПлатежа), g.ДатаПлатежа)
			)  over(partition by g.Договор,  g.Регистратор_Ссылка) as date)
	into #t_ResultДанныеГрафикаПлатежей
	from stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей] as g with(nolock)
		inner join #t_СписокДоговоров as t
			on t.Договор = g.Договор
	where   1=1
          and g.Действует = 0x01
		  and (g.Договор = stg.dbo.get1CIDRREF_FromGUID(@GuidДоговораЗайма) or @GuidДоговораЗайма is null)

		 --  and Договор = 0x814A00155D01BF0711E793B830F29C2D
	
	create clustered index ci_ix on #t_ResultДанныеГрафикаПлатежей(Договор,Регистратор)
	
	drop table if exists #t_ResultГрафикПлатежей
	select 
		nRow = ROW_NUMBER() over(partition by d.Ссылка order by t.ДатаСоставленияГрафикаПлатежей),
		Регистратор = t.Ссылка, 
		Договор = d.Ссылка,
		d.Код,
		t.ДатаСоставленияГрафикаПлатежей,
		t.ДействуетС,
		t.НоваяДатаПлатежа,
		
		ДатаОкончанияГрафикаПлатежей = lead(
		t.ДействуетС, 1, null)over(partition by d.Ссылка order by t.ДатаСоставленияГрафикаПлатежей),--старый Договор действует до составляения графика платежа включительно
		ИспытательныйСрок= cast(iif(ПараметрыДоговора.ИспытательныйСрок = 0x01, 1, 0) as bit),
		t.ВерсияДанных
	into  #t_ResultГрафикПлатежей
	from (
	select 
		s.Ссылка
		, s.Договор
		, НоваяДатаПлатежа = cast(iif(year(НоваяДатаПлатежа)>3000, dateadd(year, -2000, НоваяДатаПлатежа), null) as date)
		, ДействуетС= cast(
			COALESCE(
				iif(year(Дата)>3000, dateadd(year, -2000, Дата), null),
				Дата) as date)
		, ДатаСоставленияГрафикаПлатежей= cast(iif(year(Дата)>3000, dateadd(year, -2000, Дата), Дата) as date)
		
		, row_number() over(partition by s.Договор, cast(Дата as date) order by Дата desc) nRow
		, s.ВерсияДанных	
	from stg._1cCMR.Документ_ГрафикПлатежей s with(nolock)
		inner join #t_СписокДоговоров as x
			on x.Договор = s.Договор
	where 1=1
	and s.ПометкаУдаления != 0x01
	and s.Проведен = 0x01
	and s.Основание_Ссылка != 0x00000000000000000000000000000000
		and exists(select top(1) 1 from  #t_ResultДанныеГрафикаПлатежей t
			where t.Договор = s.Договор
				and t.Регистратор = s.Ссылка
				)
	) t
	 join stg._1cCMR.Справочник_Договоры d with(nolock) on d.Ссылка = t.Договор
		and d.ПометкаУдаления !=0x01
	join STG.[_1Ccmr].[РегистрСведений_ПараметрыДоговора] ПараметрыДоговора 
		on ПараметрыДоговора.Договор = d.Ссылка
		and ПараметрыДоговора.Регистратор_Ссылка = t.Ссылка
		and ПараметрыДоговора.Регистратор_ТипСсылки = 0x0000005E
	--left join stg._1cCMR.Справочник_Заявка z with(nolock) on z.Ссылка = d.Заявка
	where nRow = 1 --Если договоров за  день несколько берем последний
	--and Договор = 0x814A00155D01BF0711E793B830F29C2D
	order by t.ДатаСоставленияГрафикаПлатежей


	create clustered index cix on #t_ResultГрафикПлатежей(Договор, Регистратор, ДействуетС )
	drop table if exists #t_Result
	select *
	into #t_Result
	from (	
		select 
		гп.Код,
		гп.Договор,
		гп.Регистратор,
		гп.ДатаСоставленияГрафикаПлатежей,
		дгп.ДатаПлатежа,
		дгп.СуммаПлатежа,
		дгп.ОД,
		дгп.Процент,
		count(1) over(partition by гп.Договор, дгп.ДатаПлатежа) cnt,
		ИспытательныйСрок,
		гп.ВерсияДанных
		from #t_ResultГрафикПлатежей as гп
			inner join #t_ResultДанныеГрафикаПлатежей as дгп on дгп.Договор = гп.Договор
				and дгп.Регистратор = гп.Регистратор
				where дгп.ДатаПлатежа between 
						Dateadd(dd, 1, гп.ДействуетС) 
					and isnull(гп.ДатаОкончанияГрафикаПлатежей, дгп.ПоследняДатаПлатежа)
	
	 ) t

	order by ДатаПлатежа
	/*
		Если испытаетльный срок, удаляем платежи в одном месяце, за исключением последнего платежа.
	*/
	;with cte_испытаетльный_срок as
	(
		select * 
		,ПоследнийНомерПлатежа =max(НомерПлатежа) over(partition by Код)
		from 
		(select НомерПлатежа= ROW_NUMBER() over(partition by Код order by ДатаПлатежа), 
			*
		from #t_Result
		where ИспытательныйСрок = 1
		) t
	), cte_на_удаление as (
		select * from 
		(
			select 
				ROW_NUMBER() over(partition by Код, FORMAT(ДатаПлатежа, 'yyyyMM') order by ДатаПлатежа) nRow,
			*
		from cte_испытаетльный_срок t
		) t
		--Не учитываем 2 последних платежа,такие условия по ИС
		where НомерПлатежа <= ПоследнийНомерПлатежа - 2
		
	)
	delete from cte_на_удаление
	where nRow > 1
	

	drop table if exists #t_final

	select 
		Код,
		Договор,
		Регистратор,
		ДатаСоставленияГрафикаПлатежей,
		НомерПлатежа					= ROW_NUMBER() over(partition by Договор order by ДатаПлатежа),
		ДатаПлатежа,
		ДатаСледПлатежа					= lead(ДатаПлатежа, 1, '4000-01-01') over(partition by Договор order by ДатаПлатежа),
		СуммаПлатежа,
		ОД,
		Процент,
		ИспытательныйСрок,
		[ПризнакПоследнийПлатежИспытательныйСрок]  = cast(case when lag(ДатаПлатежа) 
			over(partition by Код order by ДатаПлатежа) =  dateadd(day, -1, ДатаПлатежа)  
				and [ИспытательныйСрок] =1 then 1 else 0 end  as bit),
		create_at = getdate()
		,ГрафикПлатежей_ССылка = Регистратор
		,ВерсияДанных
	into #t_final
	From #t_Result

	if @isDebug = 1 begin
		select 
			count(*) as cnt,
			count(distinct Договор) as cnt_Договор
		from #t_final

		drop table if exists ##t_final
		select * into ##t_final from #t_final
	end

	if OBJECT_ID('dm.CMRExpectedRepayments') is null or @reCreateTable = 1
	begin
		--if @reCreateTable = 1 
		--begin
		drop table if exists dm.CMRExpectedRepayments
		select top(0)
			Код,
			Договор,
			Регистратор,
			ДатаСоставленияГрафикаПлатежей,
			НомерПлатежа,
			ДатаПлатежа,
			ДатаСледПлатежа,
			СуммаПлатежа,
			ОД,
			Процент,
			ИспытательныйСрок,
			ПризнакПоследнийПлатежИспытательныйСрок,
			create_at = getdate(),
			ГрафикПлатежей_ССылка,
			ВерсияДанных
		into dm.CMRExpectedRepayments
		from #t_final
		--end
	end


	/*
	alter table  dm.CMRExpectedRepayments
		add ГрафикПлатежей_ССылка binary(16)
	*/

	if exists(select top(1) 1 from #t_final)
	begin
		drop table if exists #t_Договор
		create table #t_Договор(Договор binary(16))

		--пересчет по одному договору
		--if @GuidДоговораЗайма is not null
		--begin
		--	insert #t_Договор(Договор)
		--	select distinct a.Договор
		--	from #t_final as a
		--end
		----пересчет по списку договоров
		--else begin

		insert #t_Договор(Договор)
		select distinct a.Договор
		from (
			--новые записи: они есть в #t_final и нет в целевой таблице
			select
				u.Код,
				u.Договор,
				u.Регистратор,
				u.ДатаСоставленияГрафикаПлатежей,
				u.НомерПлатежа,
				u.ДатаПлатежа,
				u.ДатаСледПлатежа,
				u.СуммаПлатежа,
				u.ОД,
				u.Процент,
				u.ИспытательныйСрок,
				u.ПризнакПоследнийПлатежИспытательныйСрок,
				u.ГрафикПлатежей_ССылка,
				u.ВерсияДанных
			from #t_final as u
			except
			select
				t.Код,
				t.Договор,
				t.Регистратор,
				t.ДатаСоставленияГрафикаПлатежей,
				t.НомерПлатежа,
				t.ДатаПлатежа,
				t.ДатаСледПлатежа,
				t.СуммаПлатежа,
				t.ОД,
				t.Процент,
				t.ИспытательныйСрок,
				t.ПризнакПоследнийПлатежИспытательныйСрок,
				t.ГрафикПлатежей_ССылка,
				t.ВерсияДанных
			from dm.CMRExpectedRepayments as t
				inner join #t_СписокДоговоров as d
					on t.Договор = d.Договор
		) a
		union
		select distinct b.Договор
		from (
			--записи, отсутствующие в #t_final
			select
				t.Код,
				t.Договор,
				t.Регистратор,
				t.ДатаСоставленияГрафикаПлатежей,
				t.НомерПлатежа,
				t.ДатаПлатежа,
				t.ДатаСледПлатежа,
				t.СуммаПлатежа,
				t.ОД,
				t.Процент,
				t.ИспытательныйСрок,
				t.ПризнакПоследнийПлатежИспытательныйСрок,
				t.ГрафикПлатежей_ССылка,
				t.ВерсияДанных
			from dm.CMRExpectedRepayments as t
				inner join #t_СписокДоговоров as d
					on t.Договор = d.Договор
			except
			select
				u.Код,
				u.Договор,
				u.Регистратор,
				u.ДатаСоставленияГрафикаПлатежей,
				u.НомерПлатежа,
				u.ДатаПлатежа,
				u.ДатаСледПлатежа,
				u.СуммаПлатежа,
				u.ОД,
				u.Процент,
				u.ИспытательныйСрок,
				u.ПризнакПоследнийПлатежИспытательныйСрок,
				u.ГрафикПлатежей_ССылка,
				u.ВерсияДанных
			from #t_final as u
		) b

		--end
		----//пересчет по всем договорам

		if @isDebug = 1 begin
			drop table if exists ##t_Договор
			select * into ##t_Договор from #t_Договор
		end

		if exists(select top(1) 1 from #t_Договор)
		begin
			create unique index ix1 on #t_Договор(Договор)

			begin tran

				delete d
				from dm.CMRExpectedRepayments as d
					inner join #t_Договор as t 
						on t.Договор = d.Договор

				insert into dm.CMRExpectedRepayments
				(
					Код,
					Договор,
					Регистратор,
					ДатаСоставленияГрафикаПлатежей,
					НомерПлатежа,
					ДатаПлатежа,
					ДатаСледПлатежа,
					СуммаПлатежа,
					ОД,
					Процент,
					ИспытательныйСрок,
					ПризнакПоследнийПлатежИспытательныйСрок,
					create_at,
					ГрафикПлатежей_ССылка,
					ВерсияДанных
				)
				select 
					a.Код,
					a.Договор,
					a.Регистратор,
					a.ДатаСоставленияГрафикаПлатежей,
					a.НомерПлатежа,
					a.ДатаПлатежа,
					a.ДатаСледПлатежа,
					a.СуммаПлатежа,
					a.ОД,
					a.Процент,
					a.ИспытательныйСрок,
					a.ПризнакПоследнийПлатежИспытательныйСрок,
					create_at = getdate(),
					a.ГрафикПлатежей_ССылка,
					a.ВерсияДанных
				From #t_final as a
					inner join #t_Договор as t 
						on t.Договор = a.Договор
			commit tran
		end
		--//if exists(select top(1) 1 from #t_Договор)
	end
	--//if exists(select top(1) 1 from #t_final)

end


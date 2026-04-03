/*
DWH-1184

select * from dbo.dm_OverdueIndicators
where Number = '23122021573163'
select a.startdate, a.FactEndDate, a.fpd0, a.fpd4, a.fpd7 from dbo.dm_overdueindicators a
where number='23122021573163';

--exec [dbo].[create_dm_OverdueIndicators] @Number = '23121321538265'
*/
CREATE PROC [dbo].[create_dm_OverdueIndicators]
	@isDebug int = 0,
	@Number varchar(20) = NULL -- номер договора
as
begin
	SELECT @isDebug = isnull(@isDebug, 0)
    DECLARE @StartDate datetime, @row_count int
	DECLARE @Deal_binary_id binary(16)

	IF @Number IS NOT NULL BEGIN
		SELECT @Deal_binary_id = Договор.Ссылка
		FROM Stg._1ccmr.Справочник_Договоры AS Договор
		WHERE Договор.Код = @Number

		IF @Deal_binary_id IS NULL BEGIN
		    ;THROW 51000, 'Несуществующий номер договора', 1
			RETURN 1
		END
	END


	declare @curDate date = cast(getdate() as date)

	--замена dbo.dm_CMRStatBalance на #tmp
	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_dm_CMRStatBalance
	CREATE TABLE #t_dm_CMRStatBalance
	(
		d date,
		external_id nvarchar(21),
		dpd_begin_day numeric(10, 0),
		dpd numeric(10, 0),
		dpdMFO numeric(10, 0),
		[основной долг уплачено] numeric(38, 2),
		[Проценты уплачено] numeric(38, 2),
		[остаток од] numeric(38, 2)
	)
	INSERT #t_dm_CMRStatBalance
	(
	    d,
	    external_id,
		dpd_begin_day,
	    dpd,
	    dpdMFO,
	    [основной долг уплачено],
	    [Проценты уплачено],
	    [остаток од]
	)
	SELECT
	    B.d,
	    B.external_id,
		B.dpd_begin_day,
	    B.dpd,
	    B.dpdMFO,
	    B.[основной долг уплачено],
	    B.[Проценты уплачено],
	    B.[остаток од]
	FROM dbo.dm_CMRStatBalance AS B
	WHERE (@Number IS NULL OR B.external_id = @Number)

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_dm_CMRStatBalance', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	SELECT @StartDate = getdate(), @row_count = 0
	CREATE CLUSTERED INDEX Cl_Idx_external_id_cdate ON #t_dm_CMRStatBalance(external_id, d)
	IF @isDebug = 1 BEGIN
		SELECT 'CREATE INDEX Cl_Idx_external_id_cdate', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	SELECT @StartDate = getdate(), @row_count = 0
	CREATE INDEX Idx_dpdMFO ON #t_dm_CMRStatBalance(dpdMFO) WHERE dpdMFO IS NOT NULL
	IF @isDebug = 1 BEGIN
		SELECT 'CREATE INDEX Idx_dpdMFO', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	--CREATE INDEX Idx_dpd ON #t_dm_CMRStatBalance(dpd) WHERE dpd IS NOT NULL

	SELECT @StartDate = getdate(), @row_count = 0
	CREATE INDEX Idx_dpd_dpdMFO ON #t_dm_CMRStatBalance(dpd, dpdMFO)
	IF @isDebug = 1 BEGIN
		SELECT 'CREATE INDEX Idx_dpd_dpdMFO', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	drop table if exists #tCurrentCMRStatBalance

	SELECT @StartDate = getdate(), @row_count = 0

	select [Current].external_id,
		[Current].[остаток од],
		[Current].dpdMFO,
		[Current].dpd,
		t_last.Count_overdue
	into #tCurrentCMRStatBalance
		from 
		(
			SELECT 
				external_id, 
				max(d) AS d,
				--DWH-2395 количеством выходов на просроченную задолженность
				--сколько раз договор выходил на просрочку, считаем по показателю dpd_begin_day=1
				count(CASE dpd_begin_day WHEN 1 THEN 1 ELSE NULL END) AS Count_overdue
			from #t_dm_CMRStatBalance
			GROUP by external_id
		) AS t_last
		inner join #t_dm_CMRStatBalance AS [Current] on [Current].external_id = t_last.external_id
			and [Current].d =t_last.d

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #tCurrentCMRStatBalance', @row_count, datediff(SECOND, @StartDate, getdate())
	END
	
	drop table if exists #tГрафикПлатежей

	SELECT @StartDate = getdate(), @row_count = 0

	select 
		Регистратор = t.Ссылка, 
		Договор,
		ДатаСоставленияГрафикаПлатежей,
		ПерваяДатаПлатежа,
		НомерГрафика= ROW_NUMBER() over(partition by Договор order by t.ДатаСоставленияГрафикаПлатежей) 
		
	into  #tГрафикПлатежей
	from (
	select s.Ссылка, 
		s.Договор, 
		ДатаСоставленияГрафикаПлатежей = cast(iif(year(Дата)>3000, dateadd(year, -2000, Дата), Дата) as date),
		ПерваяДатаПлатежа = iif(year(ПерваяДатаПлатежа)>3000, dateadd(year, -2000, ПерваяДатаПлатежа), ПерваяДатаПлатежа),
		row_number() over(partition by s.Договор, cast(s.Дата as date) order by s.Дата desc) nRow
	from stg._1cCMR.Документ_ГрафикПлатежей s with(nolock)
	inner join 
	(
		select 
			Договор, 
			Регистратор_Ссылка, 
			ПерваяДатаПлатежа = min(cast(ДатаПлатежа as date))
			from stg._1cCMR.РегистрСведений_ДанныеГрафикаПлатежей t
		where Действует = 0x01
			AND (@Deal_binary_id IS NULL OR t.Договор = @Deal_binary_id)
		group by Договор, Регистратор_Ссылка
	) t on t.Договор = s.Договор
		and t.Регистратор_Ссылка = s.Ссылка

	where 1=1
	and s.ПометкаУдаления != 0x01
	and s.Проведен = 0x01
	and s.Основание_Ссылка !=0x00000000000000000000000000000000
	AND (@Deal_binary_id IS NULL OR s.Договор = @Deal_binary_id)
	) t
	where nRow = 1 --Если договоров за  день несколько берем последний
	
	order by t.ДатаСоставленияГрафикаПлатежей

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #tГрафикПлатежей', @row_count, datediff(SECOND, @StartDate, getdate())
	END



	
	drop table if exists #tГрафикПлатежей_первый_и_последний

	SELECT @StartDate = getdate(), @row_count = 0

	select t.Договор, 
		t_min.Регистратор as FirstГрафикПлатежей,  
		t_min.ПерваяДатаПлатежа as ПерваяДатаПлатежа,
		t_max.Регистратор as LastГрафикПлатежей
		into #tГрафикПлатежей_первый_и_последний
		from 
		(select max(НомерГрафика) as LastNumber,
			min(НомерГрафика) as FirstNumber,
			Договор
			from #tГрафикПлатежей t
		group by Договор
			) t
			left join #tГрафикПлатежей t_min
				on t_min.Договор = t.Договор
					and t_min.НомерГрафика = t.FirstNumber
			left join #tГрафикПлатежей t_max
				on t_max.Договор = t.Договор
					and t_max.НомерГрафика = t.LastNumber

	SELECT @row_count = @@ROWCOUNT
	--IF @isDebug = 1 BEGIN
	--	SELECT 'INSERT #tГрафикПлатежей_первый_и_последний', @row_count, datediff(SECOND, @StartDate, getdate())
	--END


	/*Для ис расчитываем график платежей*/
	drop table if exists #испытательный_срок_первый_график_платежей

	SELECT @StartDate = getdate(), @row_count = 0

	;with cte_испытательный_срок as (
	select графикПлатежей.Договор, 
		параметрыДоговора.Срок,
		графикПлатежей.FirstГрафикПлатежей,
		ПерваяДатаПлатежа = графикПлатежей.ПерваяДатаПлатежа,
		ДатаОкончания = dateadd(mm, параметрыДоговора.Срок, графикПлатежей.ПерваяДатаПлатежа)
		From #tГрафикПлатежей_первый_и_последний графикПлатежей
	inner join STG.[_1Ccmr].[РегистрСведений_ПараметрыДоговора] параметрыДоговора
		on параметрыДоговора.Договор = графикПлатежей.Договор
			and параметрыДоговора.Регистратор_Ссылка = графикПлатежей.FirstГрафикПлатежей
			and Регистратор_ТипСсылки = 0x0000005E
			and ИспытательныйСрок = 0x01
	--where графикПлатежей.Договор = 0xA2C8005056839FE911EB54CE550B0AC6
	
	), cte_испытательный_срок_график as 
	(
		select 
			Договор	
			,Срок	
			,FirstГрафикПлатежей
			,ПерваяДатаПлатежа
			,ДатаПлатежа = ПерваяДатаПлатежа 
			,ДатаОкончания
		from cte_испытательный_срок
		union all
		select Договор	
			,Срок	
			,FirstГрафикПлатежей
			,ПерваяДатаПлатежа
			,ДатаПлатежа = dateadd(mm,1,ДатаПлатежа)
			,ДатаОкончания
			from cte_испытательный_срок_график
			where ДатаОкончания>=ДатаПлатежа
			--datediff(mm, ПерваяДатаПлатежа, ДатаПлатежа)<Срок
	)
	select Договор, 
		Срок, 
		ДатаПлатежа,
		ГрафикПлатежей = FirstГрафикПлатежей,
		nRow = Row_Number() over(partition by Договор order by ДатаПлатежа)
into #испытательный_срок_первый_график_платежей
		from cte_испытательный_срок_график

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #испытательный_срок_первый_график_платежей', @row_count, datediff(SECOND, @StartDate, getdate())

		DROP TABLE IF EXISTS ##испытательный_срок_первый_график_платежей
		SELECT * INTO ##испытательный_срок_первый_график_платежей FROM #испытательный_срок_первый_график_платежей
	END


drop table if exists #tДанныеГрафикаПлатежей


	--var. 1
	SELECT @StartDate = getdate(), @row_count = 0

	select 
		Код
		,Договор
		,ДатаПлатежа
		,СуммаПлатежа
		,Процент
		,ИспытательныйСрок
		,ПрошедшийПлатеж
		,AllПрошедшийПлатеж
		,TotalPaymentOnToday
		,AllTotalPaymentOnToday = sum(t.AllПрошедшийПлатеж) over(partition by Договор)
		,АктуальныйНомерПлатеж
		,AllАктуальныйНомерПлатеж = iif(СуммаПлатежа != 0.00, 
			sum(AllПлатеж) over(partition by Договор order by ДатаПлатежа rows between unbounded preceding and current row ), null)
		,nextPaymentDate
	into	#tДанныеГрафикаПлатежей
	from (
		select 
			Код
			,Договор
			,ДатаПлатежа
			,СуммаПлатежа
			,Процент
			,ИспытательныйСрок
			,TotalPaymentOnToday
			,ПрошедшийПлатеж
			,АктуальныйНомерПлатеж
			,AllПрошедшийПлатеж = iif(ДатаПлатежа<=@curDate
					and СуммаПлатежа != 0.00, 1, 0) 
			,AllПлатеж
			,nextPaymentDate
		from (
			select 
				 nRow			
				,ПрошедшийПлатеж	
				,Платеж			
				,AllПлатеж			
				,Код
				,Договор
				,ДатаПлатежа = 
					iif(ИспытательныйСрок = 1 and CMRExpectedRepayments = 0, 
						dateadd(mm, nRow - TotalPaymentOnToday, lastDateByGrafic), 
					ДатаПлатежа)
				,СуммаПлатежа
				,Процент
				,ИспытательныйСрок
				,АктуальныйНомерПлатеж = iif(СуммаПлатежа > 0.01, 
					sum(Платеж) over(partition by Договор order by ДатаПлатежа rows between unbounded preceding and current row ), 0)
			
				,TotalPaymentOnToday
				,nextPaymentDate
			from (
				select  
					  nRow				= ROW_NUMBER() over(partition by Договор order by ДатаПлатежа)
					, lastDateByGrafic		
					, ПрошедшийПлатеж		
					, Платеж				
					, AllПлатеж				
					, Код
					, Договор
					, ДатаПлатежа
					, СуммаПлатежа
					, Процент
					, ИспытательныйСрок
					, TotalPaymentOnToday = sum(t.ПрошедшийПлатеж) over(partition by Договор)
					, CMRExpectedRepayments
					, nextPaymentDate
				from 
					(
					--Объединяем 2 графика платежей основной + испыт срок
						select 
						  --Для определение более актуального графика
						  nRow					= ROW_NUMBER() over(partition by Договор,   
							iif(ИспытательныйСрок = 1, FORMAT(ДатаПлатежа, 'yyyyMM'), FORMAT(ДатаПлатежа, 'yyyyMMdd')) order by Код desc, ДатаПлатежа) 
						, nextPayment			= LEAD(СуммаПлатежа)over(partition by Договор order by ДатаПлатежа)
						, lastDateByGrafic		= max(iif(CMRExpectedRepayments =1, ДатаПлатежа, '1900-01-01')) over(partition by Договор)
						, ПрошедшийПлатеж		= iif(ДатаПлатежа<=@curDate and СуммаПлатежа > 0.01, 1, 0)			 
						, Платеж				= iif(СуммаПлатежа > 0.01, 1, 0)
						, AllПлатеж				= iif(СуммаПлатежа != 0.00, 1, 0)
						
						, Код
						, Договор
						, ДатаПлатежа
						, СуммаПлатежа
						, Процент
						, ИспытательныйСрок
						, CMRExpectedRepayments
						, nextPaymentDate
						from 
						(select Код, Договор
							--Если есть платеж в теч. след. 2дней, то берем дату пред платежа, это для договоров с ИС
							, ДатаПлатежа = iif(datediff(dd, prevPaymentDate, ДатаПлатежа) <2, 
									dateadd(minute, 1, cast(prevPaymentDate as datetime)), ДатаПлатежа)
							, СуммаПлатежа
							, Процент
							,ИспытательныйСрок
							,CMRExpectedRepayments = 1
							,nextPaymentDate
							from 
								(select 
									  er.Код
									, er.Договор
									, er.ДатаПлатежа
									--Если есть Пролонгация PDL в период даты платежа, то берем % в противном случае всю сумма платежа
									--По согласованию с А.Кузнецовым 15.02.2024
									, СуммаПлатежа = er.СуммаПлатежа
									--iif(r.Договор is not null
									--	,Процент --DWH-2444 
									--	,СуммаПлатежа), 
									,er.Процент
									,nextPaymentDate = er.ДатаСледПлатежа
									,prevPaymentDate = lag(er.ДатаПлатежа) over(partition by er.Договор order by er.ДатаПлатежа) 
									,er.ИспытательныйСрок
								from dm.CMRExpectedRepayments er
							

									 
						) t
						union
						--Добавляем график по ИС будущих платежей
						select Код = null, 
							Договор, 
							ДатаПлатежа, 
							СуммаПлатежа = 0.01, 
							Процент = 0.0,
							ИспытательныйСрок = 1,
							CMRExpectedRepayments = 0,
							nextPaymentDate = '4000-01-01'
							from #испытательный_срок_первый_график_платежей t
						)  t

					) t
					where nRow = 1
					and not(СуммаПлатежа =0.01 and nextPayment>0.01)
				) t

			) t
		) t
		order by ДатаПлатежа

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #tДанныеГрафикаПлатежей', @row_count, datediff(SECOND, @StartDate, getdate())
	END

		create clustered index ix on #tДанныеГрафикаПлатежей (Код, Договор)
		create index ix_ДатаПлатежа_АктуальныйНомерПлатеж on #tДанныеГрафикаПлатежей(ДатаПлатежа, АктуальныйНомерПлатеж, TotalPaymentOnToday) 
			include(СуммаПлатежа )

		CREATE INDEX IX_Код_ДатаПлатежа
		ON #tДанныеГрафикаПлатежей(Код, ДатаПлатежа)
		INCLUDE (ИспытательныйСрок, AllАктуальныйНомерПлатеж, АктуальныйНомерПлатеж)


		update t
		set код = Договор.Код
			from #tДанныеГрафикаПлатежей t
			inner join stg._1ccmr.Справочник_Договоры Договор on Договор.Ссылка = t.Договор
		where t.код is null
	
		update t
			set  t.ИспытательныйСрок =  1
		from #tДанныеГрафикаПлатежей t
		where exists(select top(1) 1 from #испытательный_срок_первый_график_платежей t1 
			where t.Договор = t1.Договор)

			
	

	drop table if exists #tОбращениеКлиента

	SELECT @StartDate = getdate(), @row_count = 0

	select 
		Договор
		,ОбращениеКлиента
		,Дата = iif(year(Дата)>3000, dateadd(year, -2000, Дата), Дата)
		,ВидОбращенияКлиента
		,КолОбращений
		,СледующаяДатаПлатежа = iif(year(СледующаяДатаПлатежа)>3000, dateadd(year, -2000, СледующаяДатаПлатежа), СледующаяДатаПлатежа)
		,МаксимальнаяДатаПлатежа = iif(year(МаксимальнаяДатаПлатежа)>3000, dateadd(year, -2000, МаксимальнаяДатаПлатежа), МаксимальнаяДатаПлатежа)
		,НоваяДатаПлатежа = iif(year(НоваяДатаПлатежа)>3000, dateadd(year, -2000, НоваяДатаПлатежа), НоваяДатаПлатежа)
	into #tОбращениеКлиента
	from (
		select  Договор
				,ОбращениеКлиента = л.Ссылка 
				,ВидОбращенияКлиента = t.Имя 
				,Row_NUMBER() OVER(PARTITION BY Договор, ВидОперации order by Дата) nRow
				,КолОбращений = count(1) over(PARTITION BY Договор, ВидОперации) 
				,л.СледующаяДатаПлатежа
				,л.МаксимальнаяДатаПлатежа
				,л.ДатаПоГрафикуКредитныхКаникул
				,л.ДатаОкончанияКредитныхКаникул
				,л.ПроцентнаяСтавкаКредитныхКаникул
				,л.НоваяДатаПлатежа
				,л.Дата

			from Stg.[_1cCMR].[Документ_ОбращениеКлиента] л
				inner join stg._1cCMR.Перечисление_ВидыОперацийОбращениеКлиента t on t.Ссылка = л.ВидОперации
			--where л.ПометкаУдаления = 0x00
				and Проведен = 0x01
			WHERE (@Deal_binary_id IS NULL OR л.Договор = @Deal_binary_id)
			) t
		where nRow = 1
		--Берем только СменаДатыПлатежа 
		--КК берем из другой таблицы
		and ВидОбращенияКлиента = 'СменаДатыПлатежа'

	SELECT @row_count = @@ROWCOUNT
	--IF @isDebug = 1 BEGIN
	--	SELECT 'INSERT #tОбращениеКлиента', @row_count, datediff(SECOND, @StartDate, getdate())
	--END

	drop table if exists #dm_restructurings
	select 
		Договор
		,number
		,operation_type
		,period_start= min(period_start)		--
		,period_end	= max(period_end)		--
		,Cnt	= count(1) 					-- количество кредитных каникул
		,Days = isnull(datediff(dd, min(period_start), max(period_end)) + 1,0) --суммарное количество дней кредитных каникул
	into 	#dm_restructurings
		from dbo.dm_restructurings t
		where operation_type in('Кредитные каникулы', 'Заморозка 1.0')
		group by Договор,
			number,
			operation_type
	
	drop table if exists #tMOB_overdue
	drop table if exists #tMOB_overdue_result

	--var. 1
	/*
	select 
		t.external_id,
		MOB_overdue_type,
		MOB_overdue_Date,
		s.[остаток од],
		НомерПлатежа =НомерПлатежа.АктуальныйНомерПлатеж
	into #tMOB_overdue
		from (
		select 
			external_id,
			MOB_overdue_type = 'MOB_overdue30_MFO',
			MOB_overdue_Date = min(d)  
		from dbo.dm_CMRStatBalance
		where dpdMFO >=30 and dpdMFO < 60
		group by external_id
		union
		select 
			external_id,
			MOB_overdue_type = 'MOB_overdue30_CMR',
			MOB_overdue_Date = min(d)  
		from dbo.dm_CMRStatBalance
		where dpd >=30 and dpd < 60
		group by external_id

		union 
		select 
			external_id,
			MOB_overdue_type = 'MOB_overdue60_MFO',
			MOB_overdue_Date = min(d)
		from dbo.dm_CMRStatBalance
		where dpdMFO >=60 and dpdMFO < 90
		group by external_id
		
		union
		select 
			external_id,
			MOB_overdue_type = 'MOB_overdue60_CMR',
			MOB_overdue_Date = min(d)
		from dbo.dm_CMRStatBalance
		where dpd >=60 and dpd < 90
		group by external_id

		union 
		select 
			external_id,
			MOB_overdue_type = 'MOB_overdue90_MFO',
			MOB_overdue_Date = min(d)
		from dbo.dm_CMRStatBalance
		where dpdMFO >=90
		group by external_id
		union

		select 
			external_id,
			MOB_overdue_type = 'MOB_overdue90_CMR',
			MOB_overdue_Date = min(d)
		from dbo.dm_CMRStatBalance
		where dpdMFO >=90
		group by external_id

	) t
	left join dbo.dm_CMRStatBalance s
		on s.external_id = t.external_id
		and s.d = MOB_overdue_Date
	outer apply
		(
			select TOP(1) АктуальныйНомерПлатеж =iif(ИспытательныйСрок = 1, AllАктуальныйНомерПлатеж, АктуальныйНомерПлатеж)
			from #tДанныеГрафикаПлатежей ГрафикаПлатежей 
			where Код =  t.external_id
				and ДатаПлатежа <=MOB_overdue_Date
				ORDER BY АктуальныйНомерПлатеж DESC
		) НомерПлатежа
	*/


	--var. 2
	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_MOB_overdue30_MFO
	select 
		external_id,
		MOB_overdue_type = 'MOB_overdue30_MFO',
		MOB_overdue_Date = min(d)
	INTO #t_MOB_overdue30_MFO
	from #t_dm_CMRStatBalance
	where dpdMFO >=30 and dpdMFO < 60
	group by external_id

	DROP TABLE IF EXISTS #t_MOB_overdue30_CMR
	select 
		external_id,
		MOB_overdue_type = 'MOB_overdue30_CMR',
		MOB_overdue_Date = min(d)
	INTO #t_MOB_overdue30_CMR
	from #t_dm_CMRStatBalance
	where dpd >=30 and dpd < 60
	group by external_id

	DROP TABLE IF EXISTS #t_MOB_overdue60_MFO
	select 
		external_id,
		MOB_overdue_type = 'MOB_overdue60_MFO',
		MOB_overdue_Date = min(d)
	INTO #t_MOB_overdue60_MFO
	from #t_dm_CMRStatBalance
	where dpdMFO >=60 and dpdMFO < 90
	group by external_id
		
	DROP TABLE IF EXISTS #t_MOB_overdue60_CMR
	select 
		external_id,
		MOB_overdue_type = 'MOB_overdue60_CMR',
		MOB_overdue_Date = min(d)
	INTO #t_MOB_overdue60_CMR
	from #t_dm_CMRStatBalance
	where dpd >=60 and dpd < 90
	group by external_id

	DROP TABLE IF EXISTS #t_MOB_overdue90_MFO
	select 
		external_id,
		MOB_overdue_type = 'MOB_overdue90_MFO',
		MOB_overdue_Date = min(d)
	INTO #t_MOB_overdue90_MFO
	from #t_dm_CMRStatBalance
	where dpdMFO >=90
	group by external_id

	DROP TABLE IF EXISTS #t_MOB_overdue90_CMR
	select 
		external_id,
		MOB_overdue_type = 'MOB_overdue90_CMR',
		MOB_overdue_Date = min(d)
	INTO #t_MOB_overdue90_CMR
	from #t_dm_CMRStatBalance
	where dpdMFO >=90
	group by external_id


	DROP TABLE IF EXISTS #t_MOB
	SELECT 
		M.external_id,
		M.MOB_overdue_type,
		M.MOB_overdue_Date
	INTO #t_MOB
	FROM (
		SELECT external_id, MOB_overdue_type, MOB_overdue_Date FROM #t_MOB_overdue30_MFO
		UNION
		SELECT external_id, MOB_overdue_type, MOB_overdue_Date FROM #t_MOB_overdue30_CMR
		UNION
		SELECT external_id, MOB_overdue_type, MOB_overdue_Date FROM #t_MOB_overdue60_MFO
		UNION
		SELECT external_id, MOB_overdue_type, MOB_overdue_Date FROM #t_MOB_overdue60_CMR
		UNION
		SELECT external_id, MOB_overdue_type, MOB_overdue_Date FROM #t_MOB_overdue90_MFO
		UNION
		SELECT external_id, MOB_overdue_type, MOB_overdue_Date FROM #t_MOB_overdue90_CMR
	) AS M

	CREATE CLUSTERED INDEX Cl_ix_1 ON #t_MOB(external_id, MOB_overdue_Date)


	SELECT
		t.external_id,
		t.MOB_overdue_type,
		t.MOB_overdue_Date,
		s.[остаток од],
		НомерПлатежа = n.АктуальныйНомерПлатеж
	INTO #tMOB_overdue
	FROM #t_MOB AS t
		LEFT JOIN #t_dm_CMRStatBalance AS s
			ON s.external_id = t.external_id
			AND s.d = t.MOB_overdue_Date
		OUTER APPLY
			(
				SELECT TOP(1) АктуальныйНомерПлатеж =iif(g.ИспытательныйСрок = 1, g.AllАктуальныйНомерПлатеж, g.АктуальныйНомерПлатеж)
				FROM #tДанныеГрафикаПлатежей AS g
				WHERE g.Код = t.external_id
					and g.ДатаПлатежа <= t.MOB_overdue_Date
				ORDER BY g.АктуальныйНомерПлатеж DESC
			) AS n

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #tMOB_overdue', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	create clustered index ix on #tMOB_overdue(external_id, MOB_overdue_type)

	SELECT @StartDate = getdate(), @row_count = 0

	select 
		t.external_id,
		[MOB_overdue30_MFO_date] = [MOB_overdue30_MFO].MOB_overdue_Date,
		MOB_overdue30_MFO_остаток_од = [MOB_overdue30_MFO].[остаток од],
		MOB_overdue30_MFO_НомерПлатежа = [MOB_overdue30_MFO].[НомерПлатежа],


		[MOB_overdue60_MFO_date] = [MOB_overdue60_MFO].MOB_overdue_Date, 
		[MOB_overdue60_MFO_остаток_од] =	 [MOB_overdue60_MFO].[остаток од],
		[MOB_overdue60_MFO_НомерПлатежа] = [MOB_overdue60_MFO].[НомерПлатежа],

		[MOB_overdue90_MFO_date] = [MOB_overdue90_MFO].MOB_overdue_Date, 
		[MOB_overdue90_MFO_остаток_од] =	 [MOB_overdue90_MFO].[остаток од],
		[MOB_overdue90_MFO_НомерПлатежа] = [MOB_overdue90_MFO].[НомерПлатежа],

		
		[MOB_overdue30_CMR_date] = [MOB_overdue30_CMR].MOB_overdue_Date, 
		MOB_overdue30_CMR_остаток_од = MOB_overdue30_CMR.[остаток од],
		MOB_overdue30_CMR_НомерПлатежа = MOB_overdue30_CMR.[НомерПлатежа],
		
		[MOB_overdue60_CMR_date] = [MOB_overdue60_CMR].MOB_overdue_Date,
		MOB_overdue60_CMR_остаток_од = [MOB_overdue60_CMR].[остаток од],
		MOB_overdue60_CMR_НомерПлатежа = [MOB_overdue60_CMR].[НомерПлатежа],
		
		[MOB_overdue90_CMR_date] = [MOB_overdue90_CMR].MOB_overdue_Date, 
		MOB_overdue90_CMR_остаток_од = [MOB_overdue90_CMR].[остаток од],
		MOB_overdue90_CMR_НомерПлатежа = [MOB_overdue90_CMR].[НомерПлатежа]
into #tMOB_overdue_result
	 from 
	 (select distinct external_id from #tMOB_overdue t) t
	left join #tMOB_overdue MOB_overdue30_CMR
		on MOB_overdue30_CMR.external_id = t.external_id
			and MOB_overdue30_CMR.MOB_overdue_type = 'MOB_overdue30_CMR'
	left join #tMOB_overdue [MOB_overdue60_CMR]
		on [MOB_overdue60_CMR].external_id = t.external_id
			and [MOB_overdue60_CMR].MOB_overdue_type = 'MOB_overdue60_CMR'
	left join #tMOB_overdue [MOB_overdue90_CMR]
		on [MOB_overdue90_CMR].external_id = t.external_id
			and [MOB_overdue90_CMR].MOB_overdue_type = 'MOB_overdue90_CMR'
	left join #tMOB_overdue [MOB_overdue30_MFO]
		on MOB_overdue30_MFO.external_id = t.external_id
			and MOB_overdue30_MFO.MOB_overdue_type = 'MOB_overdue30_MFO'
			
	left join #tMOB_overdue [MOB_overdue60_MFO]
		on MOB_overdue60_MFO.external_id = t.external_id
			and MOB_overdue60_MFO.MOB_overdue_type = 'MOB_overdue60_MFO'
	
	left join #tMOB_overdue [MOB_overdue90_MFO]
		on [MOB_overdue90_MFO].external_id = t.external_id
			and [MOB_overdue90_MFO].MOB_overdue_type = 'MOB_overdue90_MFO'

	SELECT @row_count = @@ROWCOUNT
	--IF @isDebug = 1 BEGIN
	--	SELECT 'INSERT #tMOB_overdue_result', @row_count, datediff(SECOND, @StartDate, getdate())
	--END

	create clustered index ix on #tMOB_overdue_result(external_id)


	drop table if exists #tCustomerState

	SELECT @StartDate = getdate(), @row_count = 0

	SELECT distinct 
		deals.Number as external_id,
		c_state.[Name] as CustomerState
	
	into #tCustomerState
FROM [Stg].[_Collection].[CustomerStatus] c_status
join [Stg].[_Collection].[CustomerState] c_state on c_state.[Id] = c_status.[CustomerStateId]
	and c_state.[Name] in ('HardFraud', 'Fraud подтвержденный', 'Fraud неподтвержденный') 
inner join stg._Collection.Deals deals on c_status.CustomerId = deals.IdCustomer
where c_status.[IsActive] = 1 
	AND (@Number IS NULL OR deals.Number = @Number)

	SELECT @row_count = @@ROWCOUNT
	--IF @isDebug = 1 BEGIN
	--	SELECT 'INSERT #tCustomerState', @row_count, datediff(SECOND, @StartDate, getdate())
	--END


drop table if exists #tLatePayment

	SELECT @StartDate = getdate(), @row_count = 0

 select ГрафикПлатежей.Код as external_id
	--просрочка более 30 дней (по методологии МФО) в течение первых 4 платежей:
	,_15_4_MFO =  max(iif(ГрафикПлатежей.TotalPaymentOnToday>=4, iif(_15_4_MFO.external_id  is not null, 1, 0), null))
	,_15_4_CMR =  max(iif(ГрафикПлатежей.TotalPaymentOnToday>=4, iif(_15_4_CMR.external_id  is not null, 1, 0), null))
	,_30_4_MFO =  max(iif(ГрафикПлатежей.TotalPaymentOnToday>=4, iif(_30_4_MFO.external_id  is not null, 1, 0), null))
	,_30_4_CMR =  max(iif(ГрафикПлатежей.TotalPaymentOnToday>=4, iif(_30_4_CMR.external_id  is not null, 1, 0), null))
	,_90_6_MFO =  max(iif(ГрафикПлатежей.TotalPaymentOnToday>=6, iif(_90_6_MFO.external_id  is not null, 1, 0), null))
	,_90_6_CMR =  max(iif(ГрафикПлатежей.TotalPaymentOnToday>=6, iif(_90_6_CMR.external_id  is not null, 1, 0), null))
	,_90_12_MFO = max(iif(ГрафикПлатежей.TotalPaymentOnToday>=12, iif(_90_12_MFO.external_id is not null, 1, 0), null)) 
	,_90_12_CMR = max(iif(ГрафикПлатежей.TotalPaymentOnToday>=12, iif(_90_12_CMR.external_id is not null, 1, 0), null)) 
	
	into #tLatePayment
	from (
	select 
		Код
		,TotalPaymentOnToday = max(iif(t.ИспытательныйСрок = 1,AllTotalPaymentOnToday, TotalPaymentOnToday))
		,Первая_ДатаПлатежа = min(t.ДатаПлатежа) 
		,АктуальныйНомерПлатеж = max(iif(t.ИспытательныйСрок = 1,  AllАктуальныйНомерПлатеж, АктуальныйНомерПлатеж))
		,ДатаПлатежа_4 = max(
		case 
			when t.ИспытательныйСрок = 1 and AllАктуальныйНомерПлатеж = 4 and AllПрошедшийПлатеж = 1 then ДатаПлатежа 
			when t.ИспытательныйСрок = 0 and АктуальныйНомерПлатеж = 4 and ПрошедшийПлатеж = 1 then ДатаПлатежа 
		end)
		,ДатаПлатежа_6 = max(
		case 
			when t.ИспытательныйСрок = 1 and AllАктуальныйНомерПлатеж = 6 and AllПрошедшийПлатеж = 1 then ДатаПлатежа 
			when t.ИспытательныйСрок = 0 and АктуальныйНомерПлатеж = 6 and ПрошедшийПлатеж = 1 then ДатаПлатежа 
		end)
		,ДатаПлатежа_12 = max(
		case 
			when t.ИспытательныйСрок = 1 and AllАктуальныйНомерПлатеж = 12 and AllПрошедшийПлатеж = 1 then ДатаПлатежа 
			when t.ИспытательныйСрок = 0 and АктуальныйНомерПлатеж = 12 and ПрошедшийПлатеж = 1 then ДатаПлатежа 
		end)
	 from #tДанныеГрафикаПлатежей  t
	where iif(t.ИспытательныйСрок = 1, t.AllПрошедшийПлатеж,	t.ПрошедшийПлатеж) = 1
	group by Код
	) ГрафикПлатежей
	left join (
		 select d = min(d), external_id from #t_dm_CMRStatBalance CMRStatBalance 
		 where dpdMFO>=15
			group by external_id
	 ) _15_4_MFO on _15_4_MFO.external_id = Код
		and _15_4_MFO.d between Первая_ДатаПлатежа and ДатаПлатежа_4
	 left join (
		 select d = min(d), external_id from #t_dm_CMRStatBalance CMRStatBalance where 
			dpd>=15
			group by external_id
	 ) _15_4_CMR on _15_4_CMR.external_id = Код
		and _15_4_CMR.d between Первая_ДатаПлатежа and ДатаПлатежа_4
	left join 
	(
		 select d = min(d), external_id from #t_dm_CMRStatBalance CMRStatBalance 
		 where dpdMFO>=30
			group by external_id
	 ) _30_4_MFO on _30_4_MFO.external_id = Код
		and _30_4_MFO.d between Первая_ДатаПлатежа and ДатаПлатежа_4
	 left join 
	 (
		 select d = min(d), external_id from #t_dm_CMRStatBalance CMRStatBalance where 
			dpd>=30
			group by external_id
	 ) _30_4_CMR on _30_4_CMR.external_id = Код
		and _30_4_CMR.d between Первая_ДатаПлатежа and ДатаПлатежа_4

	 left join 
	 (
		 select d = min(d), external_id from #t_dm_CMRStatBalance CMRStatBalance where 
			dpdMFO>=90
			group by external_id
	 ) _90_6_MFO on _90_6_MFO.external_id = код
	 and _90_6_MFO.d between Первая_ДатаПлатежа and ДатаПлатежа_6
	  left join 
	 (
		 select  d = min(d), external_id  from #t_dm_CMRStatBalance CMRStatBalance where 
			dpd>=90
			group by external_id
	 ) _90_6_CMR on _90_6_CMR.external_id = код
	 and _90_6_CMR.d between Первая_ДатаПлатежа and ДатаПлатежа_6
	 left join
	 (
		 select  d = min(d), external_id from #t_dm_CMRStatBalance CMRStatBalance where 
			 dpdMFO>=90
			 group by external_id
	 ) _90_12_MFO on _90_12_MFO.external_id = код
			and _90_12_MFO.d between Первая_ДатаПлатежа and ДатаПлатежа_12
	left join
	(
		 select d = min(d), external_id from #t_dm_CMRStatBalance CMRStatBalance where 
			dpd>=90
			group by external_id
	 ) _90_12_CMR on _90_12_CMR.external_id = код
	 and _90_12_CMR.d between Первая_ДатаПлатежа and ДатаПлатежа_12
 
 group by ГрафикПлатежей.Код

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #tLatePayment', @row_count, datediff(SECOND, @StartDate, getdate())
	END

 create clustered index ix on #tLatePayment(external_id)

 

 /*
fpd0 / 4 / 7 / 30 - FPD в день платежа / по 4ый / 7ой / 30ый день:
0 – >=90% начисленного первого платежа внесено в срок / в течение первых 4 / 7 / 30 дней;
1 – <90% начисленного первого платежа внесено в срок (или полностью не внесен) / в течение первых 4 / 7 / 30 дней;
NULL – договор не дожил до первого платежа / 4го / 7го / 30го дня после первого 
платежа.
 */

 --Добавили новые поля DWH-1578
	 drop table if exists #fpd
	 
	SELECT @StartDate = getdate(), @row_count = 0

	 --данные для fpd
	SELECT  
		external_id = G.Код
		,g.СуммаПлатежа
		,СуммаПлатежа_0	=  iif(r_0.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,СуммаПлатежа_4	=  iif(r_4.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,СуммаПлатежа_7	=  iif(r_7.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,СуммаПлатежа_30=  iif(r_30.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,СуммаПлатежа_60 = iif(r_60.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,СуммаПлатежа_10 = iif(r_10.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,СуммаПлатежа_15 = iif(r_15.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,fpdDate =  min(G.ДатаПлатежа)
		,fpd0_SUMM  = SUM(iif(G.TotalPaymentOnToday>=1 
		--Считаем только если с даты оплаты прошло более N дней, и птаже о
				and @curDate>=dateadd(dd, 0, G.ДатаПлатежа) 
		--И платежи до ДатаПлатежа+
				and  B.d <=dateadd(dd, 0, G.ДатаПлатежа)
				, (B.[основной долг уплачено] + B.[Проценты уплачено]), null))
		--Внесли изменения согласно DWH-1488  dateadd(dd, 3, ДатаПлатежа) стало dateadd(dd, 4, ДатаПлатежа)
		,fpd4_SUMM  = SUM(iif(G.TotalPaymentOnToday>=1 
					and @curDate>=dateadd(dd, 4, G.ДатаПлатежа) and 
					B.d <=dateadd(dd, 4, G.ДатаПлатежа)
					, (B.[основной долг уплачено] + B.[Проценты уплачено]), null))
		,fpd7_SUMM	= SUM(iif(G.TotalPaymentOnToday>=1 
							and @curDate>=dateadd(dd, 6, G.ДатаПлатежа) 
							and  B.d <=dateadd(dd, 6, G.ДатаПлатежа)
						, (B.[основной долг уплачено] + B.[Проценты уплачено]), null))
		,fpd10_SUMM = sum(iif(G.TotalPaymentOnToday>=1 and @curDate>=dateadd(dd, 9, G.ДатаПлатежа) 
								and  B.d <=dateadd(dd, 9, G.ДатаПлатежа)
								,(B.[основной долг уплачено] + B.[Проценты уплачено]), null)) --DWH-2481
		,fpd15_SUMM = sum(iif(G.TotalPaymentOnToday>=1 and @curDate>=dateadd(dd, 14, G.ДатаПлатежа) 
								and  B.d <=dateadd(dd, 14, G.ДатаПлатежа)
								,(B.[основной долг уплачено] + B.[Проценты уплачено]), null)) --DWH-2481

		,fpd30_SUMM = SUM(iif(G.TotalPaymentOnToday>=1 
							and @curDate>=dateadd(dd, 29, G.ДатаПлатежа) 
							and  B.d <=dateadd(dd, 29, G.ДатаПлатежа)
							,(B.[основной долг уплачено] + B.[Проценты уплачено]), null))
		,fpd60_SUMM = SUM(iif(G.TotalPaymentOnToday>=1 and @curDate>=dateadd(dd, 59, G.ДатаПлатежа) 
								and  B.d <=dateadd(dd, 59, G.ДатаПлатежа)
								,(B.[основной долг уплачено] + B.[Проценты уплачено]), null))
		
		,fpd_SUMM	= SUM(iif(G.TotalPaymentOnToday>=1 and
			--Берем все платежи до след платежа
			B.d <G.nextPaymentDate,(B.[основной долг уплачено] + B.[Проценты уплачено]), null))
	into #fpd
	from #tДанныеГрафикаПлатежей AS G
	left join #t_dm_CMRStatBalance AS B
		on G.Код =  B.external_id
		--берем данные по балансу за первые 60 дней после даты платежа
		and B.d <= dateadd(dd, 60, G.ДатаПлатежа)
		outer apply(
				select top(1) r.Договор
				from dbo.dm_restructurings r
					where r.Договор  = g.Договор
					and dateadd(dd, 0, G.ДатаПлатежа) between r.period_start and r.period_end
					and r.reason_credit_vacation = 'Пролонгация PDL'
					) r_0
		outer apply(
				select top(1) r.Договор
				from dbo.dm_restructurings r
					where r.Договор  = g.Договор
					and dateadd(dd, 4, G.ДатаПлатежа) between r.period_start and r.period_end
					and r.reason_credit_vacation = 'Пролонгация PDL'
					) r_4
		outer apply(
				select top(1) r.Договор
				from dbo.dm_restructurings r
					where r.Договор  = g.Договор
					and dateadd(dd, 6, G.ДатаПлатежа) between r.period_start and r.period_end
					and r.reason_credit_vacation = 'Пролонгация PDL'
					) r_7
		outer apply(
			select top(1) r.Договор
			from dbo.dm_restructurings r
				where r.Договор  = g.Договор
				and dateadd(dd, 9, G.ДатаПлатежа) between r.period_start and r.period_end
				and r.reason_credit_vacation = 'Пролонгация PDL'
				) AS r_10
		outer apply(
				select top(1) r.Договор
				from dbo.dm_restructurings r
					where r.Договор  = g.Договор
					and dateadd(dd, 14, G.ДатаПлатежа) between r.period_start and r.period_end
					and r.reason_credit_vacation = 'Пролонгация PDL'
					) AS r_15
		outer apply(
				select top(1) r.Договор
				from dbo.dm_restructurings r
					where r.Договор  = g.Договор
					and dateadd(dd, 29, G.ДатаПлатежа) between r.period_start and r.period_end
					and r.reason_credit_vacation = 'Пролонгация PDL'
					) r_30
		outer apply(
				select top(1) r.Договор
				from dbo.dm_restructurings r
					where r.Договор  = g.Договор
					and dateadd(dd, 59, G.ДатаПлатежа) between r.period_start and r.period_end
					and r.reason_credit_vacation = 'Пролонгация PDL'
					) r_60
	


	where  G.АктуальныйНомерПлатеж = 1

		and G.ДатаПлатежа<@curDate
		group by G.Код
		,g.СуммаПлатежа
		,iif(r_0.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,iif(r_4.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,iif(r_7.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,iif(r_10.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,iif(r_15.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,iif(r_30.Договор  is not null, g.Процент, G.СуммаПлатежа)
		,iif(r_60.Договор  is not null, g.Процент, G.СуммаПлатежа)
		
		--,G.СуммаПлатежа

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #fpd', @row_count, datediff(SECOND, @StartDate, getdate())
	END
			
	--данные для spd	
	drop table if exists #spd

	SELECT @StartDate = getdate(), @row_count = 0

	select  
		external_id = ГрафикПлатежей.Код
		,ГрафикПлатежей.СуммаПлатежа
		,spdDate = min(ГрафикПлатежей.ДатаПлатежа)
		,spd0_SUMM  = SUM(iif(ГрафикПлатежей.TotalPaymentOnToday>=2 
		--Считаем только если с даты оплаты прошло более N дней, и птаже о
		and @curDate>=dateadd(dd, 0, ГрафикПлатежей.ДатаПлатежа) 
		--И платежи до ДатаПлатежа+
		and  d <=dateadd(dd, 0, ГрафикПлатежей.ДатаПлатежа), ([основной долг уплачено] + [Проценты уплачено]), null))

		,spd_SUMM = SUM(iif(ГрафикПлатежей.TotalPaymentOnToday>=2 
				--Берем все платежи до след плда
				and d >=ГрафикПлатежей.ДатаПлатежа  and d <ГрафикПлатежей.nextPaymentDate, 
				([основной долг уплачено] + [Проценты уплачено]), null))
	into #spd
	from #tДанныеГрафикаПлатежей ГрафикПлатежей 
	left join #t_dm_CMRStatBalance CMRStatBalance
		on ГрафикПлатежей.Код =  CMRStatBalance.external_id
		--берем данные за период платежа
		and d >=ГрафикПлатежей.ДатаПлатежа  and d <ГрафикПлатежей.nextPaymentDate
	 where  АктуальныйНомерПлатеж = 2
	  and ГрафикПлатежей.ДатаПлатежа<@curDate
	  
	 group by ГрафикПлатежей.Код
		,ГрафикПлатежей.СуммаПлатежа

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #spd', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	--данные для tpd
	drop table if exists #tpd

	SELECT @StartDate = getdate(), @row_count = 0

	select  
		external_id = ГрафикПлатежей.Код
		,ГрафикПлатежей.СуммаПлатежа
		,tpdDate = min(ГрафикПлатежей.ДатаПлатежа)
		,tpd0_SUMM  = SUM(iif(ГрафикПлатежей.TotalPaymentOnToday>=3 
		--Считаем только если с даты оплаты прошло более N дней, и птаже о
		and @curDate>=dateadd(dd, 0, ГрафикПлатежей.ДатаПлатежа) 
		--И платежи до ДатаПлатежа+
		and  d <=dateadd(dd, 0, ГрафикПлатежей.ДатаПлатежа), ([основной долг уплачено] + [Проценты уплачено]), null))

		--,spd_SUMM = SUM(iif(ГрафикПлатежей.TotalPaymentOnToday>=2 
		--		--Берем все платежи до след плда
		--		and d >=ГрафикПлатежей.ДатаПлатежа  and d <ГрафикПлатежей.nextPaymentDate, 
		--		([основной долг уплачено] + [Проценты уплачено]), null))

	into #tpd
	from #tДанныеГрафикаПлатежей ГрафикПлатежей  
	left join #t_dm_CMRStatBalance CMRStatBalance
		on ГрафикПлатежей.Код =  CMRStatBalance.external_id
		--берем данные по балансу за первые 30 дней после даты платежа
		and d = ГрафикПлатежей.ДатаПлатежа
	 where  АктуальныйНомерПлатеж = 3
	  and ГрафикПлатежей.ДатаПлатежа<@curDate
	  
	 group by ГрафикПлатежей.Код
		,ГрафикПлатежей.СуммаПлатежа

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #tpd', @row_count, datediff(SECOND, @StartDate, getdate())
	END
		
	drop table if exists #t_pd

	SELECT @StartDate = getdate(), @row_count = 0

--считаем для pd
	select 
		Договора.external_id
		,fpd0	= case when fpd0_SUMM is not null then iif(fpd0_SUMM /  nullif(fpd.СуммаПлатежа_0,0) *100 >=90, 0, 1)  end
		,fpd4	= case when fpd4_SUMM is not null then iif(fpd4_SUMM /  nullif(fpd.СуммаПлатежа_4,0) *100 >=90, 0, 1)  end
		,fpd7	= case when fpd7_SUMM is not null then iif(fpd7_SUMM /  nullif(fpd.СуммаПлатежа_7,0) *100 >=90, 0, 1)  end
		,fpd10  = case when fpd10_SUMM is not null then iif(fpd10_SUMM / nullif(fpd.СуммаПлатежа_10,0) *100 >=90, 0, 1) end
		,fpd15  = case when fpd15_SUMM is not null then iif(fpd15_SUMM / nullif(fpd.СуммаПлатежа_15,0) *100 >=90, 0, 1) end

		,fpd30	= case when fpd30_SUMM is not null then iif(fpd30_SUMM / nullif(fpd.СуммаПлатежа_30,0) *100 >=90, 0, 1) end

		,fpd60  = case when fpd60_SUMM is not null then iif(fpd60_SUMM / nullif(fpd.СуммаПлатежа_60,0) *100 >=90, 0, 1) end

		

		,spd0	= case 
				when spd0_SUMM is not null 
					then iif(spd0_SUMM / nullif(spd.СуммаПлатежа,0) *100 >=90, 0, 1) end
		,tpd0	= case when tpd0_SUMM is not null then iif(tpd0_SUMM / nullif(tpd.СуммаПлатежа,0) *100 >=90, 0, 1) end
		
		,fpd	= case when fpd.fpd_SUMM is not null 
					then iif(fpd.fpd_SUMM / nullif(fpd.СуммаПлатежа,0) *100 >=90, 0, 1) end
		
		,spd	= case when spd.spd_SUMM is not null 
					then iif(spd.spd_SUMM / nullif(spd.СуммаПлатежа,0) *100 >=90, 0, 1) end
		,fpdDate = fpd.fpdDate
		,fpd4Date = dateadd(dd, 3, fpd.fpdDate)
		,fpd7Date = dateadd(dd, 6, fpd.fpdDate)
		,fpd10Date = dateadd(dd, 9, fpd.fpdDate)
		,fpd15Date = dateadd(dd, 14, fpd.fpdDate)
		,fpd30Date = dateadd(dd, 29, fpd.fpdDate)
		,fpd60Date = dateadd(dd, 59, fpd.fpdDate)
		,spdDate = spd.spdDate
		,tpdDate = tpd.tpdDate
	into #t_pd
	from (
	select distinct Код as external_id
		from #tДанныеГрафикаПлатежей
	) Договора
	left join #fpd fpd on fpd.external_id = Договора.external_id
	
	left join #spd spd on spd.external_id = Договора.external_id
	left join #tpd tpd on tpd.external_id = Договора.external_id

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_pd', @row_count, datediff(SECOND, @StartDate, getdate())
		DROP TABLE IF EXISTS ##t_pd
		select * into ##t_pd from #t_pd
	END

 create clustered index ix on #t_pd(external_id)

	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_MaxOverdue
	select 
		t.external_id,
		max_dpdMFO = max(t.dpdMFO),
		max_dpdCMR = max(t.dpd)
	INTO #t_MaxOverdue
	FROM #t_dm_CMRStatBalance AS t
	group by external_id

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_MaxOverdue', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	CREATE CLUSTERED INDEX CL_IX ON #t_MaxOverdue(external_id)



drop table if exists #result

	SELECT @StartDate = getdate(), @row_count = 0

  select distinct
   Договор				= Договор.ССылка
  ,Number				= Договор.Код	-- - номер договора
  ,Amount				= Договор.Сумма -- сумма выдачи 
  ,InitialRate			= first_param.ПроцентнаяСтавка -- первоначальная ставка % 
  ,InitialCollateralValue  =  coalesce(
								nullif(fedor_cr.[TsMarketPrice], 0.00),
								nullif(mfo_заявка.РыночнаяСтоимостьАвтоНаМоментОценки, 0.00),
								0.00
								
								)
								-- первоначальная стоимость залога, рыночная стоимость авто
  ,StartDate			= ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств  -- дата выдачи 
  ,InitialEndDate		= cast(first_ДанныеГрафикаПлатежей.max_ДатаПлатежа as date) -- первоначальная плановая дата погашения
  ,FactEndDate			= СтатусДоговора.FactEndDate -- фактическая дата погашения /*только для Погашен*/
  ,IsActive				= СтатусДоговора.IsActive --флаг активного кредита
  ,StatusContract 		= СтатусДоговора.Наименование

  ,CurrentPrincipalDebt	= [Current].[остаток од] --9.  CurrentPrincipalDebt	- текущий основной долг (ОД)
  ,CurrentMOB_initial	= first_ДанныеГрафикаПлатежей.TotalPaymentOnToday		--10. СurrentMOB_initial		- текущий RISK MOB. Количество прошедших платежных дат согласно первоначальному графику. Соответственно, для не активных – максимальный RISK MOB до полного погашения.
  ,CurrentMOB			 = ГрафикПлатежей.АктуальныйНомерПлатеж --DWH-1894
  ,CurrentMOB_accrual	= iif(СтатусДоговора.IsEnded=1, isnull(ГрафикПлатежей_Погашен.TotalPaymentOnEnd,0), last_ГрафикПлатежей.TotalPaymentOnToday)				--11. CurrentMOB_accrual		- текущий RISK MOB. Количество фактически прошедших платежных дат (можно рассчитать через фактические начисления ОД). Соответственно, для не активных – максимальный RISK MOB до полного погашения.
  ,StartCreditVacation	= КредитныеКаникулы.period_start		--12. StartCreditVacation		- дата начала кредитных каникул
  ,EndCreditVacation	= КредитныеКаникулы.period_end		--13. EndCreditVacation		- дата окончания кредитных каникул
  ,CntCreditVacation	= isnull(КредитныеКаникулы.Cnt,0)					-- количество кредитных каникул
  ,DaysCreditVacation   = isnull(КредитныеКаникулы.Days,0) --суммарное количество дней кредитных каникул

  ,StartFreezing 		= Заморозка.period_start		--дата начала первой заморозки
  ,EndFreezing 			= Заморозка.period_end		--дата окончания последней заморозки
  ,CntFreezing 			= isnull(Заморозка.Cnt,0)		--количество заморозок
  ,DaysFreezing			= isnull(Заморозка.Days,0) --количество дней между EndFreezing и StartFreezing

  
  ,DeferredPaymentFlag	= iif(СменаДатыПлатежа.ОбращениеКлиента is not null, 1,0)--14. DeferredPaymentFlag		- флаг отсрочки платежа
  ,DeferredInMOB		= isnull(MOB_СменаДатыПлатежа.АктуальныйНомерПлатеж, 
	iif(СменаДатыПлатежа.ОбращениеКлиента is not null, 0, null) ) 	--если смена даты платежа была до первого платежа пишем 0 Risk MOB, на котором предоставлена отсрочка платежа
  ,CntDeferredPmnts		= isnull(СменаДатыПлатежа.КолОбращений,0)
  --iif(СтатусДоговора.IsActive = 0 and _pd.fpd0	is null, 0, _pd.fpd0) 
  ,fpd0		=	case 
				when 		СтатусДоговора.IsActive = 0 and _pd.fpd0	is null 
					then 0 --если договор не активный и  _pd не расчитан
				when 		СтатусДоговора.IsEnded = 1 and
					СтатусДоговора.FactEndDate 
					between ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств and 
						dateadd(dd,Договор.ПериодЛьготногоПогашения, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств)
					then 0 --если договор погашен и был погашен в льготный период
				when СтатусДоговора.IsEnded = 1 and СтатусДоговора.FactEndDate<	_pd.fpdDate 
					then 0 --если договор зарытили раньше чем наступила дата pd
				else _pd.fpd0
				end
	--iif(СтатусДоговора.IsActive = 0 and _pd.fpd4	is null, 0, _pd.fpd4)	
  ,fpd4		=	case 
				when СтатусДоговора.IsActive = 0 and _pd.fpd4	is null then 0 --если договор не активный и  _pd не расчитан
				when СтатусДоговора.IsEnded = 1 and
					СтатусДоговора.FactEndDate 
					between ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств and 
						dateadd(dd,Договор.ПериодЛьготногоПогашения, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств)
					then 0 --если договор погашен и был погашен в льготный период
				when СтатусДоговора.IsEnded = 1 and СтатусДоговора.FactEndDate<	_pd.fpd4Date 
					then 0 --если договор зарытили раньше чем наступила дата pd
				else _pd.fpd4
				end
  --iif(СтатусДоговора.IsActive = 0 and _pd.fpd7	is null, 0, _pd.fpd7)
  ,fpd7		= case 
				when СтатусДоговора.IsActive = 0 and _pd.fpd7	is null then 0 --если договор не активный и  _pd не расчитан
				when СтатусДоговора.IsEnded = 1 and
					СтатусДоговора.FactEndDate 
					between ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств and 
						dateadd(dd,Договор.ПериодЛьготногоПогашения, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств)
					then 0 --если договор погашен и был погашен в льготный период
				when СтатусДоговора.IsEnded = 1 and СтатусДоговора.FactEndDate<	_pd.fpd7Date 
					then 0 --если договор зарытили раньше чем наступила дата pd
				else _pd.fpd7
				end
	,fpd10	= case 
			when СтатусДоговора.IsActive = 0 and _pd.fpd10	is null then 0 --если договор не активный и  _pd не расчитан
			when СтатусДоговора.IsEnded = 1 and
				СтатусДоговора.FactEndDate 
				between ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств and 
					dateadd(dd,Договор.ПериодЛьготногоПогашения, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств)
				then 0 --если договор погашен и был погашен в льготный период
			when СтатусДоговора.IsEnded = 1 and СтатусДоговора.FactEndDate<	_pd.fpd10Date 
				then 0 --если договор зарытили раньше чем наступила дата pd
			else _pd.fpd10
			end
				
  --iif(СтатусДоговора.IsActive = 0 and _pd.fpd15 is null, 0, _pd.fpd15)
  ,fpd15	= case 
				when СтатусДоговора.IsActive = 0 and _pd.fpd15	is null then 0 --если договор не активный и  _pd не расчитан
				when СтатусДоговора.IsEnded = 1 and
					СтатусДоговора.FactEndDate 
					between ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств and 
						dateadd(dd, cast(Договор.ПериодЛьготногоПогашения as int), ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств)
					then 0 --если договор погашен и был погашен в льготный период
				when СтатусДоговора.IsEnded = 1 and СтатусДоговора.FactEndDate<	_pd.fpd15Date 
					then 0 --если договор зарытили раньше чем наступила дата pd
				else _pd.fpd15

				end
  --iif(СтатусДоговора.IsActive = 0 and _pd.fpd30 is null, 0, _pd.fpd30)
  ,fpd30	= case 
				when СтатусДоговора.IsActive = 0 and _pd.fpd30	is null then 0 --если договор не активный и  _pd не расчитан
				when СтатусДоговора.IsEnded = 1 and
					СтатусДоговора.FactEndDate 
					between ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств and 
						dateadd(dd,Договор.ПериодЛьготногоПогашения, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств)
					then 0 --если договор погашен и был погашен в льготный период
				when СтатусДоговора.IsEnded = 1 and СтатусДоговора.FactEndDate<	_pd.fpd30Date 
					then 0 --если договор зарытили раньше чем наступила дата pd
				else _pd.fpd30
				end

  --iif(СтатусДоговора.IsActive = 0 and _pd.fpd60 is null, 0, _pd.fpd60)
  ,fpd60	= case 
				when СтатусДоговора.IsActive = 0 and _pd.fpd60	is null then 0 --если договор не активный и  _pd не расчитан
				when СтатусДоговора.IsEnded = 1 and
					СтатусДоговора.FactEndDate 
					between ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств and 
						dateadd(dd,Договор.ПериодЛьготногоПогашения, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств)
					then 0 --если договор погашен и был погашен в льготный период
				when СтатусДоговора.IsEnded = 1 and СтатусДоговора.FactEndDate<	_pd.fpd60Date 
					then 0 --если договор зарытили раньше чем наступила дата pd
				else _pd.fpd60
				end
  --iif(СтатусДоговора.IsActive = 0 and _pd.fpd10 is null, 0, _pd.fpd10)
  
  ,spd0		= case 
				--Если договор закрылся, до даты 2го платежа
				when lower(cmr_ТипыПродуктов.Наименование) = 'pdl' then null --по Согласованию с А.Кузнецовым
				when СтатусДоговора.IsActive = 0
					and _pd.spd0 is null then 0
				--Если нет информации по платежу на spdDate, т.е. дата еще не наступила 
				--и договор еще ранее небыл погашен 
				
				when _pd.spd0 is null  then null
					--and  isnull(_pd.spdDate, cast(getdate() as date))<=isnull(СтатусДоговора.FactEndDate, cast(getdate() as date)) then null  излишнее
				--1 к дате второго платежа первый платеж погашен менее чем на 90% и второй платеж в дату второго платежа погашен менее чем на 90%
				when _pd.spd0 = 1 and _pd.fpd = 1  then 1
				else 0
			end 
  ,tpd0		= case
				when lower(cmr_ТипыПродуктов.Наименование) = 'pdl' then null

				when СтатусДоговора.IsActive = 0
					and _pd.tpd0 is null then 0
			  --Если нет информации по платежу на tpdDate, т.е. дата еще не наступила 
				--и договор еще ранее небыл погашен 
				when _pd.tpd0  is null then null
					--and isnull(_pd.tpdDate, cast(getdate() as date))=isnull(СтатусДоговора.FactEndDate, cast(getdate() as date)) then null излишнее
				when _pd.tpd0 = 1 and _pd.fpd = 1 and _pd.spd = 1  then 1
				else 0
			end
  ,spd0_not_fpd0  = case
			when lower(cmr_ТипыПродуктов.Наименование) = 'pdl' then null --по Согласованию с А.Кузнецовым
			when _pd.spd0 is null and  isnull(_pd.spdDate, cast(getdate() as date))<=isnull(СтатусДоговора.FactEndDate, cast(getdate() as date)) then null 
			when _pd.fpd0 = 0 and _pd.spd0 = 1 then 1
			when _pd.fpd0 = 0 and _pd.spd0 = 0 then 0 else 0
		end
  /*
  = case
			when _pd.spd0 is null then null
			when _pd.fpd0 = 0 and _pd.spd0 = 1 then 1
			--when _pd.fpd0 = 0 and _pd.spd0 = 0 then 0
			else 0 
		end
  */
  --DWH-1942
  ,_15_4_MFO				= LatePayment._15_4_MFO
  ,_15_4_CMR				= LatePayment._15_4_CMR
  --27. – 29. 30@4_CMR / 90@6_CMR / 90@12_CMR - индикаторы по методологии ЦМР, аналогичные пунктам 24. – 26.
  ,_30_4_MFO				= LatePayment._30_4_MFO  
  ,_30_4_CMR				= LatePayment._30_4_CMR/*
	24. 30@4_MFO – просрочка более 30 дней (по методологии МФО) в течение первых 4 платежей:
		1 – была просрочка >30 дней;
		0 – не было просрочки >30 дней;
		NULL – не дожил до 4го RISK MOB.
	*/
 ,_90_6_MFO					= LatePayment._90_6_MFO 
 ,_90_6_CMR					= LatePayment._90_6_CMR
 /*
		25. 90@6_MFO – просрочка более 90 дней (по методологии МФО) в течение первых 6 платежей:
		1 – была просрочка >90 дней;
		0 – не было просрочки >90 дней;
		NULL – не дожил до 6го RISK MOB. */
  ,_90_12_MFO				= LatePayment._90_12_MFO 
  ,_90_12_CMR				= LatePayment._90_12_CMR
  /*
	26. 90@12_MFO – просрочка более 90 дней (по методологии МФО) в течение первых 12 платежей:
		1 – была просрочка >90 дней;
		0 – не было просрочки >90 дней;
		NULL – не дожил до 12го RISK MOB.*/

  ,MOB_overdue.MOB_overdue30_MFO_date--30. MOB_overdue30_MFO - первый Risk MOB выхода в просрочку более 30 дней (по методологии МФО)
  ,MOB_overdue30_MFO		= MOB_overdue.MOB_overdue30_MFO_НомерПлатежа --30. MOB_overdue30_MFO - первый Risk MOB выхода в просрочку более 30 дней (по методологии МФО)
  ,Pdebt_overdue30_MFO		= MOB_overdue.MOB_overdue30_MFO_остаток_од --33. Pdebt_overdue30_MFO - ОД первого выхода в просрочку более 30 дней (по методологии МФО)
  
  ,MOB_overdue60_MFO_date	 --31. MOB_overdue60_MFO - первый Risk MOB выхода в просрочку более 60 дней (по методологии МФО)
  ,MOB_overdue60_MFO		= MOB_overdue.MOB_overdue60_MFO_НомерПлатежа --31. MOB_overdue60_MFO - первый Risk MOB выхода в просрочку более 60 дней (по методологии МФО)
  ,Pdebt_overdue60_MFO		= MOB_overdue.MOB_overdue60_MFO_остаток_од  --34. Pdebt_overdue60_MFO - ОД первого выхода в просрочку более 60 дней (по методологии МФО)
  ,MOB_overdue90_MFO_date	 --32. MOB_overdue90_MFO - первый Risk MOB выхода в просрочку более 90 дней (по методологии МФО)
  ,MOB_overdue90_MFO		= MOB_overdue.MOB_overdue90_MFO_НомерПлатежа--32. MOB_overdue90_MFO - первый Risk MOB выхода в просрочку более 90 дней (по методологии МФО)
  ,Pdebt_overdue90_MFO		= MOB_overdue.MOB_overdue90_MFO_остаток_од --35. Pdebt_overdue90_MFO - ОД первого выхода в просрочку более 90 дней (по методологии МФО)
  ,MOB_overdue30_CMR_date	
  ,MOB_overdue30_CMR		= MOB_overdue30_CMR_НомерПлатежа
  ,Pdebt_overdue30_CMR 		= MOB_overdue30_CMR_остаток_од
  ,MOB_overdue60_CMR_date 	
  ,MOB_overdue60_CMR 		= MOB_overdue60_CMR_НомерПлатежа
  ,Pdebt_overdue60_CMR		= MOB_overdue60_CMR_остаток_од
  ,MOB_overdue90_CMR_date 	 
  ,MOB_overdue90_CMR 		= MOB_overdue90_CMR_НомерПлатежа
  ,Pdebt_overdue90_CMR		= MOB_overdue90_CMR_остаток_од
  ,CurrentOverdue_MFO		= [Current].dpdMFO				--42. CurrentOverdue_MFO - текущее количество дней просрочки (по методологии МФО)	
  ,MaxOverdue_MFO			= MaxOverdue.max_dpdMFO				--43. MaxOverdue_MFO - максимальное количество дней просрочки за историю договора (по методологии МФО)	
  ,CurrentOverdue_CMR		= [Current].dpd
  ,MaxOverdue_CMR			= MaxOverdue.max_dpdCMR
  ,HardFraud  = iif(CustomerState_HardFraud.external_id is not null, 1,0) --46. HardFraud– флаг 'HardFraud' 
  ,ConfirmedFraud = iif(CustomerState_ConfirmedFraud.external_id is not null, 1,0) --47. ConfimedFraud – флаг 'Fraud подтвержденный' 
  ,UnconfirmedFraud = iif(CustomerState_UnconfirmedFraud.external_id is not null, 1,0)  --48. UnconfirmedFraud – флаг 'Fraud неподтвержденный'
  ,Count_overdue --DWH-2395 количеством выходов на просроченную задолженность
  ,ProductType = 
				CASE lower(cmr_ТипыПродуктов.ИдентификаторMDS)
					when 'pts'			then 'ПТС'
					when 'installment'	then 'Инстоллмент'
					when 'pdl'			then 'PDL'
					else 'ПТС' end 
	--, d.*

	--DWH-2475
    ,full_prepayment_30 = 
		CASE 
		WHEN СтатусДоговора.IsEnded = 1 
			AND datediff(DAY, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств, 
				СтатусДоговора.FactEndDate) <= 30 
			THEN 1 
		ELSE 0 
		END
    ,full_prepayment_60 = 
		CASE 
		WHEN СтатусДоговора.IsEnded = 1 
			AND datediff(DAY, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств, 
				СтатусДоговора.FactEndDate) <= 60 
			THEN 1 
		ELSE 0 
		END
    ,full_prepayment_90 = 
		CASE 
		WHEN СтатусДоговора.IsEnded = 1 
			AND datediff(DAY, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств, 
				СтатусДоговора.FactEndDate) <= 90 
			THEN 1 
		ELSE 0 
		END
    ,full_prepayment_180 = 
		CASE 
		WHEN СтатусДоговора.IsEnded = 1 
			AND datediff(DAY, ВыдачаДенежныхСредств.дата_ВыдачаДенежныхСредств, 
				СтатусДоговора.FactEndDate) <= 180
			THEN 1 
		ELSE 0 
		END
	,initialTerm_MM = Договор.Срок /*Первональный срок в месяцах*/

	into #result
		from stg._1ccmr.Справочник_Договоры Договор
		left join [Stg].[_1cCMR].[Справочник_типыПродуктов] cmr_ТипыПродуктов
			on Договор.ТипПродукта = cmr_ТипыПродуктов.ссылка	

		inner JOIN 
		(
			select 
				дата_ВыдачаДенежныхСредств = cast(dateadd(year,-2000, min(ДатаВыдачи))  as date)
				, ВыдачаДенежныхСредств.Договор 
			from stg._1ccmr.Документ_ВыдачаДенежныхСредств  ВыдачаДенежныхСредств 
			where ВыдачаДенежныхСредств.Проведен = 0x01
			and ВыдачаДенежныхСредств.ПометкаУдаления = 0x00 
			and ВыдачаДенежныхСредств.Статус =  0xBB0F3EC282AA989A421CBFE2808BEB5F ----Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
			AND (@Deal_binary_id IS NULL OR ВыдачаДенежныхСредств.Договор = @Deal_binary_id)
			group by ВыдачаДенежныхСредств.Договор 
		) ВыдачаДенежныхСредств on ВыдачаДенежныхСредств.Договор =Договор.Ссылка
		left join 
		(
			select t.Договор
				,АктуальныйНомерПлатеж = max(t.АктуальныйНомерПлатеж)
				,ДатаПлатежа = max(t.ДатаПлатежа)
			from #tДанныеГрафикаПлатежей t
			where t.ДатаПлатежа <=cast(getdate() as date)
			group by Договор

		) ГрафикПлатежей on ГрафикПлатежей.Договор  =  Договор.Ссылка
		
		outer apply
		(
			select top(1) 
				sd.Статус,
				Период=dateadd(year,-2000,sd.Период)	
				from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
			where sd.Договор = Договор.Ссылка
			order by Период desc
		) sd
		--cross т.к надо вычислить FactEndDate
		cross apply (select  СтатусДоговора.Ссылка,
				Наименование,
				IsActive = iif(СтатусДоговора.Наименование in 
				(	'Действует', 'Просрочен', 'Проблемный', 'Платеж опаздывает', 'Legal', 'Решение суда', 'Внебаланс') 
					, 1, 0),
				IsEnded = iif(СтатусДоговора.Наименование in('Погашен', 'Продан'),1,0),
				FactEndDate =   iif(СтатусДоговора.Наименование in('Погашен', 'Продан'),cast(sd.Период as date), null)
			from stg._1ccmr.Справочник_СтатусыДоговоров  СтатусДоговора 
			where СтатусДоговора.Наименование not in ('Аннулирован', 'Зарегистрирован') 
			and СтатусДоговора.Ссылка = sd.Статус
		) СтатусДоговора 
		
		
		outer apply 
		(
			select top(1) ПроцентнаяСтавка = iif(cast(param.[ПроцентнаяСтавка] as int)=0, 
				[НачисляемыеПроценты], 
				param.[ПроцентнаяСтавка]),
				ИспытательныйСрок = cast(iif(ИспытательныйСрок = 0x01, 1, 0) as bit)
				from STG.[_1Ccmr].[РегистрСведений_ПараметрыДоговора] [param]
			where [param].Договор = Договор.Ссылка
			order by Период asc
		) first_param
	left join Stg._fedor.core_ClientRequest AS fedor_cr
		ON fedor_cr.Number COLLATE Cyrillic_General_CI_AS = Договор.Код 
		and fedor_cr.IsNewProcess = 1
		and fedor_cr.CreatedRequestDate >= '2020-09-01'
	left join stg._1cMFO.Документ_ГП_Заявка mfo_заявка on mfo_заявка.Номер = Договор.Код 
		and mfo_заявка.Дата < dateadd(year, 2000, '2021-11-01')
	
	
	left join #tГрафикПлатежей_первый_и_последний ГрафикПлатежей_первый_и_последний  on ГрафикПлатежей_первый_и_последний.Договор = Договор.Ссылка
	
	outer apply 
		(
			select
				max_ДатаПлатежа = max(ДатаПлатежа),
				TotalPaymentOnToday=  
				sum(
					iif(ДатаПлатежа<=dd,1,0))
			from 
			(select Договор, ГрафикПлатежей = Регистратор_ССылка, 
				ДатаПлатежа = iif(year(ДатаПлатежа)>3000, dateadd(year,-2000, ДатаПлатежа), ДатаПлатежа) 
				from stg._1cCMR.РегистрСведений_ДанныеГрафикаПлатежей first_ДанныеГрафикаПлатежей
			where Действует = 0x01
			and first_param.ИспытательныйСрок = 0
			--
			AND first_ДанныеГрафикаПлатежей.Договор = Договор.Ссылка
			AND first_ДанныеГрафикаПлатежей.Регистратор_Ссылка = ГрафикПлатежей_первый_и_последний.FirstГрафикПлатежей
				
			union 
			select Договор, ГрафикПлатежей, ДатаПлатежа from #испытательный_срок_первый_график_платежей  гп
			where first_param.ИспытательныйСрок = 1
			--
			AND гп.Договор = Договор.Ссылка
			AND гп.ГрафикПлатежей = ГрафикПлатежей_первый_и_последний.FirstГрафикПлатежей
			) first_ДанныеГрафикаПлатежей
			outer apply(select isnull(СтатусДоговора.FactEndDate, @curDate) dd) t
			where first_ДанныеГрафикаПлатежей.Договор = Договор.Ссылка
				and first_ДанныеГрафикаПлатежей.ГрафикПлатежей = ГрафикПлатежей_первый_и_последний.FirstГрафикПлатежей
				
		) first_ДанныеГрафикаПлатежей
	outer apply
	(
			select sum(ПрошедшийПлатеж) as TotalPaymentOnEnd
				from #tДанныеГрафикаПлатежей t
			where t.Договор  =  Договор.Ссылка
				and t.ДатаПлатежа <=СтатусДоговора.FactEndDate
				--and t.ДатаПлатежа <=sd.Период
				--	and СтатусДоговора.IsEnded=1
	) ГрафикПлатежей_Погашен 
			
	left join (
			select max(t.ДатаПлатежа ) max_ДатаПлатежа
				, max(TotalPaymentOnToday)  as TotalPaymentOnToday
				, Договор from #tДанныеГрафикаПлатежей t
			group by  Договор
		) last_ГрафикПлатежей on last_ГрафикПлатежей.Договор = Договор.Ссылка
			

	left join #dm_restructurings КредитныеКаникулы
		on КредитныеКаникулы.Договор = Договор.Ссылка
		and КредитныеКаникулы.operation_type = 'Кредитные Каникулы'
	
	left join #dm_restructurings Заморозка
		on Заморозка.Договор = Договор.Ссылка
		and Заморозка.operation_type = 'Заморозка 1.0'
	
	left join #tОбращениеКлиента СменаДатыПлатежа
		on СменаДатыПлатежа.Договор = Договор.Ссылка
		and СменаДатыПлатежа.ВидОбращенияКлиента = 'СменаДатыПлатежа'
		and СменаДатыПлатежа.НоваяДатаПлатежа!='2001-01-01 00:00:00'	
	outer apply
	(
		select max(АктуальныйНомерПлатеж) as  АктуальныйНомерПлатеж 
			from #tДанныеГрафикаПлатежей t
		where t.Код = Договор.Код
		and t.ДатаПлатежа <= СменаДатыПлатежа.Дата
	) as MOB_СменаДатыПлатежа
	left join #tMOB_overdue_result MOB_overdue on MOB_overdue.external_id =Договор.Код
	left join #t_pd _pd on _pd.external_id = Договор.Код
	left join #tLatePayment LatePayment on LatePayment.external_id =Договор.Код 
	left join #tCurrentCMRStatBalance [Current] on [Current].external_id = Договор.Код
		
	--left join 
	--(
	--	select external_id, 
	--	max_dpdMFO = max(dpdMFO) 
	--	,max_dpdCMR = max(dpd)
	--	from #t_dm_CMRStatBalance t
	--	group by external_id

	--) MaxOverdue on MaxOverdue.external_id = Договор.Код
	LEFT JOIN #t_MaxOverdue AS MaxOverdue
		ON MaxOverdue.external_id = Договор.Код

	left join #tCustomerState CustomerState_HardFraud on CustomerState_HardFraud.external_id = Договор.Код
		and CustomerState_HardFraud.CustomerState = 'HardFraud'
	left join #tCustomerState CustomerState_ConfirmedFraud  on CustomerState_ConfirmedFraud.external_id = Договор.Код
		and CustomerState_ConfirmedFraud.CustomerState = 'Fraud подтвержденный'
	left join #tCustomerState CustomerState_UnconfirmedFraud   on CustomerState_UnconfirmedFraud.external_id = Договор.Код
		and CustomerState_UnconfirmedFraud.CustomerState = 'Fraud неподтвержденный'
	
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #result', @row_count, datediff(SECOND, @StartDate, getdate())
	END
	

	if OBJECT_ID('dm_OverdueIndicators') is null
	begin
	 --drop table dbo.dm_OverdueIndicators
		select top(0) * 
		,create_at = @curDate
		into dbo.dm_OverdueIndicators
		from #result
	end
	if exists(select top(1) 1 from #result)
	begin
		--SELECT @StartDate = getdate(), @row_count = 0

		--delete from dbo.dm_OverdueIndicators where 1=1
		IF @Number IS NOT NULL BEGIN
			delete D
			FROM dbo.dm_OverdueIndicators D
			WHERE Number = @Number
		END
		ELSE BEGIN
			TRUNCATE TABLE dbo.dm_OverdueIndicators
		END


		--SELECT @row_count = @@ROWCOUNT
		--IF @isDebug = 1 BEGIN
		--	SELECT 'DELETE dbo.dm_OverdueIndicators', @row_count, datediff(SECOND, @StartDate, getdate())
		--END
		/*
			alter table dbo.dm_OverdueIndicators
				add CurrentMOB int 
		*/
		--Временно пока в CMR не будет наведен порядок в расчетах по займам
		--ждем решения BP-1734
		update #result
			set CurrentPrincipalDebt = 0.00
		where FactEndDate is not null
		and StatusContract in ('Погашен', 'Продан')
		and CurrentPrincipalDebt <> 0

		SELECT @StartDate = getdate(), @row_count = 0

		/*
			alter table dbo.dm_OverdueIndicators
				add [_15_4_MFO] smallint
					,[_15_4_CMR] smallint
			alter table  dbo.dm_OverdueIndicators
				add [fpd60] smallint
			alter table dbo.dm_OverdueIndicators
				add ProductType nvarchar(255)
			alter table dbo.dm_OverdueIndicators
				add initialTerm_MM smallint
		*/
		insert into dbo.dm_OverdueIndicators(
			[Договор], 
			[Number], 
			[Amount], 
			[InitialRate], 
			[InitialCollateralValue], 
			[StartDate], 
			[InitialEndDate], 
			[FactEndDate], 
			[IsActive], 
			[StatusContract], 
			[CurrentPrincipalDebt], 
			[CurrentMOB_initial], 
			[CurrentMOB_accrual], 
			[StartCreditVacation], 
			[EndCreditVacation], 
			[CntCreditVacation], 
			[DaysCreditVacation], 
			[StartFreezing], 
			[EndFreezing], 
			[CntFreezing], 
			[DaysFreezing], 
			[DeferredPaymentFlag], 
			[DeferredInMOB], 
			[CntDeferredPmnts], 
			[fpd0], 
			[fpd4], 
			[fpd7], 
			[fpd30],
			[fpd60],
			fpd10,
			fpd15,
			spd0, 
			tpd0, 
			spd0_not_fpd0, 
			
			[_15_4_MFO],		
			[_15_4_CMR],		
			[_30_4_MFO],		
			[_30_4_CMR],		
			[_90_6_MFO],		
			[_90_6_CMR],		
			[_90_12_MFO],	
			[_90_12_CMR],	
			[MOB_overdue30_MFO_date], 
			[MOB_overdue30_MFO], 
			[Pdebt_overdue30_MFO], 
			[MOB_overdue60_MFO_date], 
			[MOB_overdue60_MFO], 
			[Pdebt_overdue60_MFO], 
			[MOB_overdue90_MFO_date], 
			[MOB_overdue90_MFO], 
			[Pdebt_overdue90_MFO], 
			[MOB_overdue30_CMR_date], 
			[MOB_overdue30_CMR], 
			[Pdebt_overdue30_CMR], 
			[MOB_overdue60_CMR_date], 
			[MOB_overdue60_CMR], 
			[Pdebt_overdue60_CMR], 
			[MOB_overdue90_CMR_date], 
			[MOB_overdue90_CMR], 
			[Pdebt_overdue90_CMR], 
			[CurrentOverdue_MFO], 
			[MaxOverdue_MFO], 
			[CurrentOverdue_CMR], 
			[MaxOverdue_CMR], 
			[HardFraud], 
			[ConfirmedFraud], 
			[UnconfirmedFraud], 
			CurrentMOB,
			Count_overdue,
			ProductType,
			full_prepayment_30,
			full_prepayment_60,
			full_prepayment_90,
			full_prepayment_180,
			initialTerm_MM,
			create_at
		)
		select 
			[Договор], 
			[Number], 
			[Amount], 
			[InitialRate], 
			[InitialCollateralValue], 
			[StartDate], 
			[InitialEndDate], 
			[FactEndDate], 
			[IsActive], 
			[StatusContract], 
			[CurrentPrincipalDebt], 
			[CurrentMOB_initial], 
			[CurrentMOB_accrual], 
			[StartCreditVacation], 
			[EndCreditVacation], 
			[CntCreditVacation], 
			[DaysCreditVacation], 
			[StartFreezing], 
			[EndFreezing], 
			[CntFreezing], 
			[DaysFreezing], 
			[DeferredPaymentFlag], 
			[DeferredInMOB], 
			[CntDeferredPmnts], 
			[fpd0], 
			[fpd4], 
			[fpd7], 
			[fpd30],
			fpd60,
			fpd10,
			fpd15,
			spd0, 
			tpd0, 
			spd0_not_fpd0,
			/*если договор не активен,
			and  длительность договора больше чем месяц расчета показателя, 
			 показатель не расчитан -Null то пишем 0, иначе значе показателья - для догоров меньше 4/6/12м будет null
			 DWH-420*/
			[_15_4_MFO]  = iif([IsActive] = 0 and initialTerm_MM>=4,  isnull([_15_4_MFO], 0), [_15_4_MFO]	),
			[_15_4_CMR]  = iif([IsActive] = 0 and initialTerm_MM>=4, isnull([_15_4_CMR], 0), [_15_4_CMR]	),
			[_30_4_MFO]  = iif([IsActive] = 0 and initialTerm_MM>=4, isnull([_30_4_MFO], 0), [_30_4_MFO]	), 
			[_30_4_CMR]  = iif([IsActive] = 0 and initialTerm_MM>=4, isnull([_30_4_CMR], 0), [_30_4_CMR]	), 
			[_90_6_MFO]  = iif([IsActive] = 0 and initialTerm_MM>=6, isnull([_90_6_MFO], 0), [_90_6_MFO]	), 
			[_90_6_CMR]  = iif([IsActive] = 0 and initialTerm_MM>=6, isnull([_90_6_CMR], 0), [_90_6_CMR]	), 
			[_90_12_MFO] = iif([IsActive] = 0 and initialTerm_MM>=12, isnull([_90_12_MFO],0), [_90_12_MFO] 	), 
			[_90_12_CMR] = iif([IsActive] = 0 and initialTerm_MM>=12, isnull([_90_12_CMR],0), [_90_12_CMR] 	), 
			[MOB_overdue30_MFO_date], 
			[MOB_overdue30_MFO], 
			[Pdebt_overdue30_MFO], 
			[MOB_overdue60_MFO_date], 
			[MOB_overdue60_MFO], 
			[Pdebt_overdue60_MFO], 
			[MOB_overdue90_MFO_date], 
			[MOB_overdue90_MFO], 
			[Pdebt_overdue90_MFO], 
			[MOB_overdue30_CMR_date], 
			[MOB_overdue30_CMR], 
			[Pdebt_overdue30_CMR], 
			[MOB_overdue60_CMR_date], 
			[MOB_overdue60_CMR], 
			[Pdebt_overdue60_CMR], 
			[MOB_overdue90_CMR_date], 
			[MOB_overdue90_CMR], 
			[Pdebt_overdue90_CMR], 
			[CurrentOverdue_MFO], 
			[MaxOverdue_MFO], 
			[CurrentOverdue_CMR], 
			[MaxOverdue_CMR], 
			[HardFraud], 
			[ConfirmedFraud], 
			[UnconfirmedFraud],
			CurrentMOB,
			Count_overdue,
			ProductType,
			full_prepayment_30,
			full_prepayment_60,
			full_prepayment_90,
			full_prepayment_180,
			initialTerm_MM,
			create_at = @curDate
			
		from #result

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT dbo.dm_OverdueIndicators', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		
	end
	
end

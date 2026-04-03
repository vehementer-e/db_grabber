






CREATE PROC [finAnalytics].[calcRepPublic_40_8] 
    @repmonth date
AS
BEGIN
	
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc
	
    begin try
	
	drop table if exists #OSV
		create table #OSV (
			[acc2order] nvarchar(10) not null,
			[restOUT_BU] float not null
		)

		insert into #OSV
		select
		acc2order
		,[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		from dwh2.finAnalytics.OSV_MONTHLY a
		where repmonth = @repmonth
		---and acc2order not in ('47423','47425')
		group by acc2order
		

		drop table if exists #depo

		select
		[accOD]
		,[accPRC]
		,[srokType] = case	
						when l1.[daysToEnd] between 0 and 30 then 'col3'
						when l1.[daysToEnd] between 31 and 90 then 'col4'
						when l1.[daysToEnd] between 91 and 365 then 'col5'
						when l1.[daysToEnd] between 366 and 1825 then 'col6'
						when l1.[daysToEnd] > 1825 then 'col7'
						when l1.[daysToEnd] < 0 then 'col8'
					else '-' end
		,[restOD] = sum(isnull(l1.restOD,0))
		,[restPRC] = sum(isnull(l1.restPRC,0))

		into #depo

		from(
		select

		[accOD] = substring(accOD,1,5)
		,[accPRC] = substring(accPRC,1,5)
		,restOD
		,restPRC
		,dogState
		,dogEndDate
		,[daysToEnd] = DATEDIFF(day,eomonth(@Repmonth),dogEndDate)

		from dwh2.finAnalytics.DEPO_MONTHLY
		where 1=1
		and repmonth = @repmonth
		and upper(dogState) = upper('Действует')
		) l1

		group by
		[accOD]
		,[accPRC]
		,case	
						when l1.[daysToEnd] between 0 and 30 then 'col3'
						when l1.[daysToEnd] between 31 and 90 then 'col4'
						when l1.[daysToEnd] between 91 and 365 then 'col5'
						when l1.[daysToEnd] between 366 and 1825 then 'col6'
						when l1.[daysToEnd] > 1825 then 'col7'
						when l1.[daysToEnd] < 0 then 'col8'
					else '-' end

		drop table if exists #rep
		create table #rep(
			repmonth date not null,
			[RowNum] [int] NOT NULL,
			[Razdel] [nvarchar](10) NULL,
			[RowName] [nvarchar](10) NULL,
			[Pokazatel] [nvarchar](255) NULL,
			[Acc2] [nvarchar](max) NULL,
			[Aplicator] [int] NULL,
			[isBold] [int] NULL,
			[sumAmountCol3] float null,
			[sumAmountCol4] float null,
			[sumAmountCol5] float null,
			[sumAmountCol6] float null,
			[sumAmountCol7] float null,
			[sumAmountCol8] float null,
			[sumAmountCol9] float null
		)


		/*Данные из ОСВ*/
		insert into #rep

		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = case when [RowName] = '15.1' then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = 0
		, [sumAmountCol5] = 0
		, [sumAmountCol6] = 0
		, [sumAmountCol7] = 0
		, [sumAmountCol8] = 0
		, [sumAmountCol9] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_8] a
		left join #OSV osv on a.[Acc2] = osv.acc2order

		/*не стандартные из ОСВ*/
		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol9] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_8] a
		left join #OSV osv on osv.acc2order = '43108'
		where rowName = '11.27'
		) t2 on (t1.rowName = '11.27')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol9] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_8] a
		left join #OSV osv on osv.acc2order = '43109'
		where rowName = '11.28'
		) t2 on (t1.rowName = '11.28')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol9] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_8] a
		left join #OSV osv on osv.acc2order = '43808'
		where rowName = '11.69'
		) t2 on (t1.rowName = '11.69')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol9] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_8] a
		left join #OSV osv on osv.acc2order = '43809'
		where rowName = '11.70'
		) t2 on (t1.rowName = '11.70')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol9] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_8] a
		left join #OSV osv on osv.acc2order = '42316'
		where rowName = '11.87'
		) t2 on (t1.rowName = '11.87')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol9] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_8] a
		left join #OSV osv on osv.acc2order = '42317'
		where rowName = '11.88'
		) t2 on (t1.rowName = '11.88')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9];

		/*Данные из отчета по привлечению*/
		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(depo3.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(depo6.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol7] = cast(isnull(depo7.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol8] = cast(isnull(depo8.restOD * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43108' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43108' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43108' and depo5.srokType = 'col5'
		left join #depo depo6 on depo6.accOD = '43108' and depo6.srokType = 'col6'
		left join #depo depo7 on depo7.accOD = '43108' and depo7.srokType = 'col7'
		left join #depo depo8 on depo8.accOD = '43108' and depo8.srokType = 'col8'
		where rowName = '11.27'
		) t2 on (t1.rowName = '11.27')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(depo3.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(depo6.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol7] = cast(isnull(depo7.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol8] = cast(isnull(depo8.restPRC * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43108' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43108' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43108' and depo5.srokType = 'col5'
		left join #depo depo6 on depo6.accOD = '43108' and depo6.srokType = 'col6'
		left join #depo depo7 on depo7.accOD = '43108' and depo7.srokType = 'col7'
		left join #depo depo8 on depo8.accOD = '43108' and depo8.srokType = 'col8'
		where rowName = '11.28'
		) t2 on (t1.rowName = '11.28')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8];


		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(depo3.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(depo6.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol7] = cast(isnull(depo7.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol8] = cast(isnull(depo8.restOD * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43808' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43808' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43808' and depo5.srokType = 'col5'
		left join #depo depo6 on depo6.accOD = '43808' and depo6.srokType = 'col6'
		left join #depo depo7 on depo7.accOD = '43808' and depo7.srokType = 'col7'
		left join #depo depo8 on depo8.accOD = '43808' and depo8.srokType = 'col8'
		where rowName = '11.69'
		) t2 on (t1.rowName = '11.69')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(depo3.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(depo6.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol7] = cast(isnull(depo7.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol8] = cast(isnull(depo8.restPRC * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43808' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43808' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43808' and depo5.srokType = 'col5'
		left join #depo depo6 on depo6.accOD = '43808' and depo6.srokType = 'col6'
		left join #depo depo7 on depo7.accOD = '43808' and depo7.srokType = 'col7'
		left join #depo depo8 on depo8.accOD = '43808' and depo8.srokType = 'col8'
		where rowName = '11.70'
		) t2 on (t1.rowName = '11.70')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8];


		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(depo3.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(depo6.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol7] = cast(isnull(depo7.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol8] = cast(isnull(depo8.restOD * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '42316' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '42316' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '42316' and depo5.srokType = 'col5'
		left join #depo depo6 on depo6.accOD = '42316' and depo6.srokType = 'col6'
		left join #depo depo7 on depo7.accOD = '42316' and depo7.srokType = 'col7'
		left join #depo depo8 on depo8.accOD = '42316' and depo8.srokType = 'col8'
		where rowName = '11.87'
		) t2 on (t1.rowName = '11.87')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(depo3.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(depo6.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol7] = cast(isnull(depo7.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol8] = cast(isnull(depo8.restPRC * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '42316' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '42316' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '42316' and depo5.srokType = 'col5'
		left join #depo depo6 on depo6.accOD = '42316' and depo6.srokType = 'col6'
		left join #depo depo7 on depo7.accOD = '42316' and depo7.srokType = 'col7'
		left join #depo depo8 on depo8.accOD = '42316' and depo8.srokType = 'col8'
		where rowName = '11.88'
		) t2 on (t1.rowName = '11.88')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8];


		/*Расчет итогов*/

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		, [sumAmountCol7] = sum([sumAmountCol7])
		, [sumAmountCol8] = sum([sumAmountCol8])
		, [sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where razdel = 11
		) t2 on (t1.rowName = '11')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		, [sumAmountCol7] = sum([sumAmountCol7])
		, [sumAmountCol8] = sum([sumAmountCol8])
		, [sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where razdel = 13
		) t2 on (t1.rowName = '13')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		, [sumAmountCol7] = sum([sumAmountCol7])
		, [sumAmountCol8] = sum([sumAmountCol8])
		, [sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where razdel = 15
		) t2 on (t1.rowName = '15')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		, [sumAmountCol7] = sum([sumAmountCol7])
		, [sumAmountCol8] = sum([sumAmountCol8])
		, [sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where rowName in ('11','12','13','14','15')
		) t2 on (t1.rowName = '10')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9];

		
		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		, [sumAmountCol7] = sum([sumAmountCol7])
		, [sumAmountCol8] = sum([sumAmountCol8])
		, [sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where rowName in ('1','6','10','16')
		) t2 on (t1.rowName = '17')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9];


		
		
		delete from dwh2.[finAnalytics].[repPublicPL_40_8] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_40_8]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Aplicator], [isBold], [sumAmountCol3], [sumAmountCol4], [sumAmountCol5], [sumAmountCol6], [sumAmountCol7], [sumAmountCol8], [sumAmountCol9])
		
		select * from #rep
	
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 40.8'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 40.8 для Публикуемой'
	declare @emailList nvarchar(200)
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients =''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch

END

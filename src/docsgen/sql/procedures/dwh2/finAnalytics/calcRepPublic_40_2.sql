





CREATE PROC [finAnalytics].[calcRepPublic_40_2] 
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
		
		drop table if exists #OSV2
		create table #OSV2 (
			[acc2order] nvarchar(10) not null,
			[restOUT_BU] float not null
		)
		
		insert into #OSV2
		select
		acc2order
		,[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		from dwh2.finAnalytics.OSV_MONTHLY a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		where repmonth = @repmonth
		and acc2order in ('47423','47425')
		and upper(cl2.Наименование) = UPPER('Платежные системы')
		group by acc2order

		drop table if exists #PBR
		create table #PBR (
			[restPenya_GP] float not null,
			[reservPenya_GP] float not null,
			[srokType] nvarchar(100) null
		)

		insert into #PBR
		select
		[restPenya_GP] = isnull(sum(isnull(l1.[restPenya_GP],0)),0)
		,[reservPenya_GP] = isnull(sum(isnull(l1.[reservPenya_GP],0)),0)
		,[srokType] = case 
							when l1.srok < 0 then 'col5'
							when l1.srok between 0 and 90 then 'col3'
							when l1.srok between 91 and 365 then 'col4'
							when l1.srok > 365 then 'col5'
						else '-'
						end

		from (
		select
		[restPenya_GP] = isnull(penyaSum,0) + isnull(gosposhlSum,0)
		,[reservPenya_GP] = isnull(reservBUPenyaSum,0)
		--,[srok] = DATEDIFF(DAY,Isnull(pogashenieDateDS,pogashenieDate),eomonth(@repmonth))
		,[srok] = DATEDIFF(DAY,eomonth(@repmonth),Isnull(pogashenieDateDS,pogashenieDate))
		from dwh2.finAnalytics.PBR_MONTHLY
		where REPMONTH = @repmonth
		) l1
		group by case 
							when l1.srok <0 then 'col5'
							when l1.srok between 0 and 90 then 'col3'
							when l1.srok between 91 and 365 then 'col4'
							when l1.srok > 365 then 'col5'
						else '-'
						end

		--select * from #pbr

		drop table if exists #term

		select
		l1.acc2order
		,[ODcol3] = sum(isnull(
						l1.[returnOD_1]
					+	l1.[returnOD_30]
					+	l1.[returnOD_90]
						,0))
		,[ODcol4] = sum(isnull([returnOD_360],0))
		,[ODcol5] = sum(isnull(
						l1.[returnOD_1800]
					+	l1.[returnOD_1801]
					+	l1.[returnOD_pros]
						,0))

		,[PRCcol3] = sum(isnull(
						l1.[returnPRC_1]
					+	l1.[returnPRC_30]
					+	l1.[returnPRC_90]
						,0))
		,[PRCcol4] = sum(isnull([returnPRC_360],0))
		,[PRCcol5] = sum(isnull(
						l1.[returnPRC_1800]
					+	l1.[returnPRC_1801]
					+	l1.[returnPRC_pros]
						,0))

		,[Reservcol3] = sum(isnull(
						l1.[reservOD_BU_1]
					+	l1.[reservOD_BU_30]
					+	l1.[reservOD_BU_90]
					+	l1.[reservPRC_BU_1]
					+	l1.[reservPRC_BU_30]
					+	l1.[reservPRC_BU_90]
						,0))
		,[Reservcol4] = sum(isnull(
						l1.[reservOD_BU_360]
					+	l1.[reservPRC_BU_360]
						,0))
		,[Reservcol5] = sum(isnull(
						l1.[reservOD_BU_1800]
					+	l1.[reservOD_BU_1801]
					+	l1.[reservOD_BU_pros]
					+	l1.[reservPRC_BU_1800]
					+	l1.[reservPRC_BU_1801]
					+	l1.[reservPRC_BU_pros]
						,0))
		
		into #term

		from(
		select
		acc2order = substring(accNum,1,5)
		,[returnOD_1] --Суммы погашения ОД До востребования или на 1 день
		,[returnOD_30] --Суммы погашения ОД До 30 дней
		,[returnOD_90] --Суммы погашения ОД От 30 дней ≤ 90 дней
		,[returnOD_360] --Суммы погашения ОД От 90 дней ≤ 360 дней
		,[returnOD_1800] --Суммы погашения ОД От 360 дней ≤ 1800 дней
		,[returnOD_1801] --Суммы погашения ОД От > 1800 дней
		,[returnOD_pros] --Суммы погашения ОД Просроченная часть

		,[returnPRC_1] --Сумма погашения процентов До востребования или на 1 день
		,[returnPRC_30] --Сумма погашения процентов До 30 дней
		,[returnPRC_90] --Сумма погашения процентов От 30 дней ≤ 90 дней
		,[returnPRC_360] --Сумма погашения процентов От 90 дней ≤ 360 дней
		,[returnPRC_1800] --Сумма погашения процентов От 360 дней ≤ 1800 дней
		,[returnPRC_1801] --Сумма погашения процентов От > 1800 дней
		,[returnPRC_pros] --Сумма погашения процентов Просроченная часть

		,[reservOD_BU_1] --Сумма резерва БУ по суммам ОД До востребования или на 1 день
		,[reservOD_BU_30] --Сумма резерва БУ по суммам ОД До 30 дней
		,[reservOD_BU_90] --Сумма резерва БУ по суммам ОД От 30 дней ≤ 90 дней
		,[reservOD_BU_360] --Сумма резерва БУ по суммам ОД От 90 дней ≤ 360 дней
		,[reservOD_BU_1800] --Сумма резерва БУ по суммам ОД От 360 дней ≤ 1800 дней
		,[reservOD_BU_1801] --Сумма резерва БУ по суммам ОД От > 1800 дней
		,[reservOD_BU_pros] --Сумма резерва БУ по суммам ОД Просроченная часть
		,[reservPRC_BU_1] --Сумма резерва БУ по суммам процентов До востребования или на 1 день
		,[reservPRC_BU_30] --Сумма резерва БУ по суммам процентов До 30 дней
		,[reservPRC_BU_90] --Сумма резерва БУ по суммам процентов От 30 дней ≤ 90 дней
		,[reservPRC_BU_360] --Сумма резерва БУ по суммам процентов От 90 дней ≤ 360 дней
		,[reservPRC_BU_1800] --Сумма резерва БУ по суммам процентов От 360 дней ≤ 1800 дней
		,[reservPRC_BU_1801] --Сумма резерва БУ по суммам процентов От > 1800 дней
		,[reservPRC_BU_pros] --Сумма резерва БУ по суммам процентов Просроченная часть
		from dwh2.[finAnalytics].[termpayment_MONTHLY]
		where repmonth = @repmonth
		and accNum is not null
		) l1

		group by l1.acc2order

		drop table if exists #depo

		select
		[accOD]
		,[accPRC]
		,[srokType] = case	
						when l1.[daysToEnd] between 0 and 90 then 'col3'
						when l1.[daysToEnd] between 91 and 365 then 'col4'
						when l1.[daysToEnd] > 365 then 'col5'
						when l1.[daysToEnd] < 0 then 'col5'
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
						when l1.[daysToEnd] between 0 and 90 then 'col3'
						when l1.[daysToEnd] between 91 and 365 then 'col4'
						when l1.[daysToEnd] > 365 then 'col5'
						when l1.[daysToEnd] < 0 then 'col5'
					else '-' end

		drop table if exists #rep
		create table #rep(
			repmonth date not null,
			[group] int null,
			[RowNum] [int] NOT NULL,
			[Razdel] [nvarchar](10) NULL,
			[RowName] [nvarchar](10) NULL,
			[Pokazatel] [nvarchar](255) NULL,
			[Acc2] [nvarchar](max) NULL,
			[Aplicator] [int] NULL,
			[isBold] [int] NULL,
			[is3] int null,
			[is4] int null,
			[is5] int null,
			[is6] int null,
			[sumAmountCol3] float null,
			[sumAmountCol4] float null,
			[sumAmountCol5] float null,
			[sumAmountCol6] float null
		)


		/*Данные из ОСВ*/
		insert into #rep

		select
		repmonth = @repmonth
		, [group]
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol5] = case when is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol6] = case when is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #OSV osv on a.[Acc2] = osv.acc2order

		/*Не стандартные ОСВ*/

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol5] = case when is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol6] = case when is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #OSV2 osv on osv.acc2order = '47423'
		where rowName = '1.17'
		) t2 on (t1.rowName = '1.17')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];
		
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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol5] = case when is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol6] = case when is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) else 0 end
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #OSV2 osv on osv.acc2order = '47425'
		where rowName = '1.20'
		) t2 on (t1.rowName = '1.20')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];

		/*Данные из ПБР*/
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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(pbr3.restPenya_GP * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(pbr4.restPenya_GP * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(pbr5.restPenya_GP * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(pbr3.restPenya_GP * a.[Aplicator],0) as float)
						+   cast(isnull(pbr4.restPenya_GP * a.[Aplicator],0) as float)
						+   cast(isnull(pbr5.restPenya_GP * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #PBR pbr3 on pbr3.srokType='col3'
		left join #PBR pbr4 on pbr4.srokType='col4'
		left join #PBR pbr5 on pbr5.srokType='col5'
		where rowName = '4.275'
		) t2 on (t1.rowName = '4.275')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];
		

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(pbr3.reservPenya_GP * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(pbr4.reservPenya_GP * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(pbr5.reservPenya_GP * a.[Aplicator],0) as float)
		, [sumAmountCol6] = cast(isnull(pbr3.reservPenya_GP * a.[Aplicator],0) as float)
						+   cast(isnull(pbr4.reservPenya_GP * a.[Aplicator],0) as float)
						+   cast(isnull(pbr5.reservPenya_GP * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #PBR pbr3 on pbr3.srokType='col3'
		left join #PBR pbr4 on pbr4.srokType='col4'
		left join #PBR pbr5 on pbr5.srokType='col5'
		where rowName = '4.277'
		) t2 on (t1.rowName = '4.277')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];
		
		/*Данные из отчета по срокам погашения*/
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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.ODCol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.ODCol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.ODCol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #term term on term.acc2order = '48701'
		where rowName = '4.280'
		) t2 on (t1.rowName = '4.280')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.PRCCol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.PRCCol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.PRCCol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #term term on term.acc2order = '48701'
		where rowName = '4.281'
		) t2 on (t1.rowName = '4.281')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.ODCol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.ODCol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.ODCol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #term term on term.acc2order = '48801'
		where rowName = '4.289'
		) t2 on (t1.rowName = '4.289')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.PRCCol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.PRCCol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.PRCCol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join (
		select
			PRCCol3 = sum(PRCCol3)
			,PRCCol4 = sum(PRCCol4)
			,PRCCol5 = sum(PRCCol5)
		from #term
		where acc2order in ('48801','48802')
		) term on 1=1
		where rowName = '4.290'
		) t2 on (t1.rowName = '4.290')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.ODCol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.ODCol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.ODCol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #term term on term.acc2order = '49401'
		where rowName = '4.316'
		) t2 on (t1.rowName = '4.316')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.PRCCol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.PRCCol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.PRCCol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #term term on term.acc2order = '49401'
		where rowName = '4.317'
		) t2 on (t1.rowName = '4.317')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.Reservcol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.Reservcol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.Reservcol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #term term on term.acc2order = '48701'
		where rowName = '4.325'
		) t2 on (t1.rowName = '4.325')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.Reservcol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.Reservcol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.Reservcol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join (
		select
		Reservcol3 = sum(Reservcol3)
		,Reservcol4 = sum(Reservcol4)
		,Reservcol5 = sum(Reservcol5)
		from #term
		where acc2order in ('48801','48802')
		) term on 1=1
		where rowName = '4.326'
		) t2 on (t1.rowName = '4.326')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(term.Reservcol3 * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(term.Reservcol4 * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(term.Reservcol5 * a.[Aplicator],0) as float)

		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #term term on term.acc2order = '49401'
		where rowName = '4.329'
		) t2 on (t1.rowName = '4.329')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

		--merge into #rep t1
		--using(
		--select
		----repmonth = @repmonth
		--[RowNum]
		--, [Razdel]
		--, [RowName]
		--, [Pokazatel]
		--, [Acc2]
		--, [Aplicator]
		--, [isBold]
		--, [is3]
		--, [is4]
		--, [is5]
		--, [is6]
		--, [sumAmountCol3] = case when is3=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) 
		--										    - isnull(osv2.restOUT_BU * a.[Aplicator],0)
		--										as float) else 0 end
		--, [sumAmountCol4] = case when is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) 
		--										    - isnull(osv2.restOUT_BU * a.[Aplicator],0)
		--										as float) else 0 end
		--, [sumAmountCol5] = case when is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) 
		--										    - isnull(osv2.restOUT_BU * a.[Aplicator],0)
		--										as float) else 0 end
		--, [sumAmountCol6] = case when is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) 
		--										    - isnull(osv2.restOUT_BU * a.[Aplicator],0)
		--										as float) else 0 end
		--from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		--left join #OSV osv on osv.acc2order = '47423'
		--left join #OSV2 osv2 on osv2.acc2order = '47423'
		--where rowName = '4.273'
		--) t2 on (t1.rowName = '4.273')
		--when matched then update
		--set t1.[sumAmountCol3] = t2.[sumAmountCol3],
		--	t1.[sumAmountCol4] = t2.[sumAmountCol4],
		--	t1.[sumAmountCol5] = t2.[sumAmountCol5],
		--	t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		a.[RowNum]
		, a.[Razdel]
		, a.[RowName]
		, a.[Pokazatel]
		, a.[Acc2]
		, a.[Aplicator]
		, a.[isBold]
		, a.[is3]
		, a.[is4]
		, a.[is5]
		, a.[is6]
		, [sumAmountCol3] = case when a.is3=1 then 
												cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol4] = case when a.is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol5] = case when a.is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol6] = case when a.is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #OSV osv on osv.acc2order = '60323'
		left join #rep rep on rep.rowName = '4.275'
		where a.rowName = '8.2'
		) t2 on (t1.rowName = '8.2')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];
		
		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		a.[RowNum]
		, a.[Razdel]
		, a.[RowName]
		, a.[Pokazatel]
		, a.[Acc2]
		, a.[Aplicator]
		, a.[isBold]
		, a.[is3]
		, a.[is4]
		, a.[is5]
		, a.[is6]
		, [sumAmountCol3] = case when a.is3=1 then 
												cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol4] = case when a.is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol5] = case when a.is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol6] = case when a.is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #OSV osv on osv.acc2order = '60324'
		left join #rep rep on rep.rowName = '4.277'
		where a.rowName = '8.41'
		) t2 on (t1.rowName = '8.41')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		a.[RowNum]
		, a.[Razdel]
		, a.[RowName]
		, a.[Pokazatel]
		, a.[Acc2]
		, a.[Aplicator]
		, a.[isBold]
		, a.[is3]
		, a.[is4]
		, a.[is5]
		, a.[is6]
		, [sumAmountCol3] = case when a.is3=1 then 
												cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol4] = case when a.is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol5] = case when a.is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol6] = case when a.is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #OSV osv on osv.acc2order = '47425'
		left join (
		select
		[sumAmountCol6] = sum([sumAmountCol6])
		from #rep 
		where rowName in ('1.20','4.269')
		) rep on 1=1
		where a.rowName = '8.43'
		) t2 on (t1.rowName = '8.43')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		a.[RowNum]
		, a.[Razdel]
		, a.[RowName]
		, a.[Pokazatel]
		, a.[Acc2]
		, a.[Aplicator]
		, a.[isBold]
		, a.[is3]
		, a.[is4]
		, a.[is5]
		, a.[is6]
		, [sumAmountCol3] = case when a.is3=1 then 
												cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol4] = case when a.is4=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol5] = case when a.is5=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		, [sumAmountCol6] = case when a.is6=1 then cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float) 
											-	rep.[sumAmountCol6]
												else 0 end
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #OSV osv on osv.acc2order = '47423'
		left join (
		select
		[sumAmountCol6] = sum([sumAmountCol6])
		from #rep 
		where rowName in ('1.17','4.273')
		) rep on 1=1
		where a.rowName = '8.52'
		) t2 on (t1.rowName = '8.52')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6];


		

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(depo3.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restOD * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43108' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43108' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43108' and depo5.srokType = 'col5'
		where rowName = '11.27'
		) t2 on (t1.rowName = '11.27')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(depo3.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restPRC * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43108' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43108' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43108' and depo5.srokType = 'col5'
		where rowName = '11.28'
		) t2 on (t1.rowName = '11.28')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(depo3.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restOD * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43808' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43808' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43808' and depo5.srokType = 'col5'
		where rowName = '11.69'
		) t2 on (t1.rowName = '11.69')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(depo3.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restPRC * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '43808' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '43808' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '43808' and depo5.srokType = 'col5'
		where rowName = '11.70'
		) t2 on (t1.rowName = '11.70')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(depo3.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restOD * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restOD * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '42316' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '42316' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '42316' and depo5.srokType = 'col5'
		where rowName = '11.87'
		) t2 on (t1.rowName = '11.87')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];

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
		, [is3]
		, [is4]
		, [is5]
		, [is6]
		, [sumAmountCol3] = cast(isnull(depo3.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol4] = cast(isnull(depo4.restPRC * a.[Aplicator],0) as float)
		, [sumAmountCol5] = cast(isnull(depo5.restPRC * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_40_2] a
		left join #depo depo3 on depo3.accOD = '42316' and depo3.srokType = 'col3'
		left join #depo depo4 on depo4.accOD = '42316' and depo4.srokType = 'col4'
		left join #depo depo5 on depo5.accOD = '42316' and depo5.srokType = 'col5'
		where rowName = '11.88'
		) t2 on (t1.rowName = '11.88')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5];
		
		--select * from #term
		/*Расчет итогов*/

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		from #rep
		where razdel = 1
		) t2 on (t1.rowName = '1')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		from #rep
		where razdel = 4
		) t2 on (t1.rowName = '4')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		from #rep
		where razdel = 8
		) t2 on (t1.rowName = '8')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		from #rep
		where rowName in ('1','2','3','4','5','6','7','8')
		) t2 on (t1.rowName = '9')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		from #rep
		where razdel = 11
		) t2 on (t1.rowName = '11')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		from #rep
		where razdel = 13
		) t2 on (t1.rowName = '13')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		, [sumAmountCol4] = sum([sumAmountCol4])
		, [sumAmountCol5] = sum([sumAmountCol5])
		, [sumAmountCol6] = sum([sumAmountCol6])
		from #rep
		where rowName in ('10','11','12','13')
		) t2 on (t1.rowName = '14')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum(case when rowName = '14' then [sumAmountCol3] * -1 else [sumAmountCol3] end)
		, [sumAmountCol4] = sum(case when rowName = '14' then [sumAmountCol4] * -1 else [sumAmountCol4] end)
		, [sumAmountCol5] = sum(case when rowName = '14' then [sumAmountCol5] * -1 else [sumAmountCol5] end)
		, [sumAmountCol6] = sum(case when rowName = '14' then [sumAmountCol6] * -1 else [sumAmountCol6] end)
		from #rep
		where rowName in ('9','14')
		) t2 on (t1.rowName = '15')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6];

		
		
		delete from dwh2.[finAnalytics].[repPublicPL_40_2] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_40_2]
		([repmonth], [group], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Aplicator], [isBold], [is3], [is4], [is5], [is6], [sumAmountCol3], [sumAmountCol4], [sumAmountCol5], [sumAmountCol6])
		
		select * from #rep
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 40.2'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 40.2 для Публикуемой'
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

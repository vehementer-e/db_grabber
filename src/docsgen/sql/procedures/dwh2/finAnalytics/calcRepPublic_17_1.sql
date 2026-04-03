





CREATE PROC [finAnalytics].[calcRepPublic_17_1] 
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
			[restOUT_BU] float not null,
			[groupFinRec] nvarchar(500) null,
			[client] nvarchar(300) null,
			[isOPS] int null
		)

		insert into #OSV 
		select
		a.acc2order
		,[restOUT_BU] = sum(isnull(a.restOUT_BU,0))
		,[groupFinRec] = g.Наименование
		,[client] = a.[subconto1]
		,[isOPS] = case when upper(cl2.Наименование) = UPPER('Платежные системы') then 1 else 0 end
		from dwh2.finAnalytics.OSV_MONTHLY a
		left join stg.[_1cUMFO].[Справочник_ДоговорыКонтрагентов] d on a.subconto2UID = d.ссылка
		left join stg.[_1cUMFO].[Справочник_БНФОГруппыФинансовогоУчетаРасчетов] g on d.БНФОГруппаФинансовогоУчета=g.ссылка
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 

		where repmonth = @repmonth
		group by acc2order,[subconto1],g.Наименование,case when upper(cl2.Наименование) = UPPER('Платежные системы') then 1 else 0 end

		drop table if exists #PBR
		create table #PBR (
			[restPenya_GP] float not null,
			[reservPenya_GP] float not null
		)

		insert into #PBR
		select
		[restPenya_GP] = sum(isnull(penyaSum,0) + isnull(gosposhlSum,0))
		,[reservPenya_GP] = sum(isnull(reservBUPenyaSum,0))

		from dwh2.finAnalytics.PBR_MONTHLY
		where REPMONTH = @repmonth


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
			[is3] [int] NULL,
			[is4] [int] NULL,
			[sumAmountCol3] float null,
			[sumAmountCol4] float null,
			[sumAmountItog] float null
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
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(select acc2order, restOUT_BU = sum(isnull(restOUT_BU,0)) from #OSV group by acc2order
		) osv on a.[Acc2] = osv.acc2order

		/*Не стандартная выборка из ОСВ*/
		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(	
			select acc2order
				, restOUT_BU = sum(isnull(restOUT_BU,0)) 
				from #OSV 
				where upper([client]) = upper('МИР СРО')
				group by acc2order
		) osv on '60323' = osv.acc2order
		where a.rowName = '1.1'
		) t2 on (t1.rowName = '1.1')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(	
			select acc2order
				, restOUT_BU = sum(isnull(restOUT_BU,0)) 
				from #OSV 
				where upper([client]) = upper('МИР СРО')
				group by acc2order
		) osv on '60324' = osv.acc2order
		where a.rowName = '1.2'
		) t2 on (t1.rowName = '1.2')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(	
			select acc2order
				, restOUT_BU = sum(isnull(restOUT_BU,0)) 
				from #OSV 
				where 
				acc2order = '60324'
				and upper([groupFinRec]) = upper('60311,60312_Расчеты с поставщиками и подрядчиками')
				group by acc2order
		) osv on 1=1
		where a.rowName = '8.4'
		) t2 on (t1.rowName = '8.4')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(	
			select acc2order
				, restOUT_BU = sum(isnull(restOUT_BU,0)) 
				from #OSV 
				where 
				acc2order = '47423'
				and [isOPS] = 0
				group by acc2order
		) osv on 1=1
		where a.rowName = '12.24'
		) t2 on (t1.rowName = '12.24')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) - pbr.[restPenya_GP] else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) - pbr.[restPenya_GP] else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(	
			select acc2order
				, restOUT_BU = sum(isnull(restOUT_BU,0)) 
				from #OSV 
				where 
				acc2order = '60323'
				and upper([client]) != upper('МИР СРО')
				group by acc2order
		) osv on 1=1
		left join #pbr pbr on 1=1
		where a.rowName = '12.25'
		) t2 on (t1.rowName = '12.25')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(	
			select acc2order
				, restOUT_BU = sum(isnull(restOUT_BU,0)) 
				from #OSV 
				where 
				acc2order = '47425'
				and [isOPS] = 0
				group by acc2order
		) osv on 1=1
		where a.rowName = '12.28'
		) t2 on (t1.rowName = '12.28')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [is3]
		, [is4]
		, [sumAmountCol3] = case when is3=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountCol4] = case when is4=1 then cast(isnull(abs(osv.restOUT_BU) * a.[Aplicator],0) as float) else 0 end
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_1] a
		left join 
		(	
			select acc2order
				, restOUT_BU = sum(isnull(restOUT_BU,0)) 
				from #OSV 
				where 
				acc2order = '60324'
				and upper([groupFinRec]) in (
											upper('60322,60323_Расчеты с прочими дебиторами и кредиторами')
											,upper('60324_Резервы под обесценение')
											)
				group by acc2order
		) osv on 1=1
		where a.rowName = '12.29'
		) t2 on (t1.rowName = '12.29')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];
			
		
		/*Расчет итогов*/

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 1
		) t2 on (t1.rowName = '1')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 2
		) t2 on (t1.rowName = '2')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 3
		) t2 on (t1.rowName = '3')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 4
		) t2 on (t1.rowName = '4')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		
		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 5
		) t2 on (t1.rowName = '5')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];
		
		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 6
		) t2 on (t1.rowName = '6')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];
		

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 7
		) t2 on (t1.rowName = '7')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 8
		) t2 on (t1.rowName = '8')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];
		
		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 9
		) t2 on (t1.rowName = '9')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 10
		) t2 on (t1.rowName = '10')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];
		
		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 11
		) t2 on (t1.rowName = '11')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];
		
		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where razdel = 12
		) t2 on (t1.rowName = '12')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];


		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		from #rep
		where rowName in ('1','2','3','4','5','6','7','8','9','10','11','12')
		) t2 on (t1.rowName = '13')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4];

		/*Итого между графой 4 и 4*/
		merge into #rep t1
		using(
		select
		[sumAmountItog] = [sumAmountCol3] -[sumAmountCol4]
		,rowName
		from #rep
		where rowName in ('1','2','3','4','5','6','7','8','9','10','11','12','13')
		) t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];
		

		--select * from #rep order by rowNum
		
		delete from dwh2.[finAnalytics].[repPublicPL_17_1] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_17_1]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Aplicator], [isBold], [is3], [is4], [sumAmountCol3], [sumAmountCol4], [sumAmountItog])
		select * from #rep order by rowNum
	
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 8.1'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 8.1 для Публикуемой'
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

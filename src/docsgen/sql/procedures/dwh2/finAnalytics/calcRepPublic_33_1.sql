

CREATE PROC [finAnalytics].[calcRepPublic_33_1] 
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
			[Symbol] nvarchar(100) not null,
			[restOUT_BU] float not null,
			[subconto1] nvarchar(300) null
		)


		insert into #OSV
		select
		acc2order
		,[Symbol] = SUBSTRING(accNum,11,5)
		,[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		,[subconto1] = a.[subconto1]
		from dwh2.finAnalytics.OSV_MONTHLY a
		where repmonth = @repmonth
		and acc2order like '7%'
		group by acc2order,SUBSTRING(accNum,11,5),a.[subconto1]

		--select * from #OSV
		drop table if exists #OSV_19_2
		create table #OSV_19_2 (
			[acc2order] nvarchar(10) not null,
			[Symbol] nvarchar(100) not null,
			[restOUT_BU] float not null,
			[accName] nvarchar(300) null
		)

		insert into #OSV_19_2
		select
		acc2order
		,[Symbol] = SUBSTRING(accNum,11,5)
		,[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		,[accName] = a.[accName]
		from dwh2.finAnalytics.OSV_MONTHLY a
		where repmonth = @repmonth
		and a.[accName] like '%55416%' 
		and acc2order like '7%'
		group by acc2order,SUBSTRING(accNum,11,5),a.[accName]
		
		--select * from #OSV_19_2

		drop table if exists #rep
		create table #rep(
			repmonth date not null,
			[RowNum] [int] NOT NULL,
			[Razdel] [nvarchar](10) NULL,
			[RowName] [nvarchar](10) NULL,
			[Pokazatel] [nvarchar](255) NULL,
			[Acc2] [nvarchar](max) NULL,
			[Symbol] nvarchar(100) not null,
			[Aplicator] [int] NULL,
			[isBold] [int] NULL,
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
		, [Symbol] = a.[Symbol]
		, [Aplicator]
		, [isBold]
		, [sumAmountItog] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_33_1] a
		left join (
		select
		acc2order
		,[Symbol]
		,[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		from #OSV 
		group by acc2order,[Symbol]
		) osv on a.[Acc2] = osv.acc2order and a.[Symbol] = osv.Symbol

		
		/*Не стандартные расчеты*/
		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		 [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Symbol] = a.[Symbol]
		, [Aplicator]
		, [isBold]
		, [sumAmountItog] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_33_1] a
		left join (
		select
		[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		from #OSV 
		where acc2order = '71802' and subconto1 = 'Прочие юридические услуги (55415, сч.71802)'
		) osv on 1=1
		where a.rowName = '9.3'
		) t2 on (t1.rowName = '9.3')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		 a.[RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Symbol] = a.[Symbol]
		, [Aplicator]
		, [isBold]
		, [sumAmountItog] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_33_1] a
		left join (
		select
		[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		from #OSV 
		where acc2order = '71802' and subconto1  like '%55415%' and subconto1 != 'Прочие юридические услуги (55415, сч.71802)'
		) osv on 1=1
		where a.rowName = '17.3'
		) t2 on (t1.rowName = '17.3')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		 [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Symbol] = a.[Symbol]
		, [Aplicator]
		, [isBold]
		, [sumAmountItog] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_33_1] a
		left join (
		select
		[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		from #OSV 
		where acc2order = '71802' and subconto1 in (
													'Услуги коллекторских агенств (55416, сч. 71802)'
												,	'Услуги кадровых агентств (55416, сч.71802)'
													)
		) osv on 1=1
		where a.rowName = '17.4'
		) t2 on (t1.rowName = '17.4')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		--repmonth = @repmonth
		 [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Symbol] = a.[Symbol]
		, [Aplicator]
		, [isBold]
		, [sumAmountItog] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_33_1] a
		left join (
		select
		[restOUT_BU] = abs(sum(isnull(restOUT_BU,0)))
		from #OSV_19_2
		where accName not in (
													'Услуги коллекторских агенств (55416, сч. 71802)'
												,	'Услуги кадровых агентств (55416, сч.71802)'
													)
		) osv on 1=1
		where a.rowName = '19.2'
		) t2 on (t1.rowName = '19.2')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];
		
		--select * from #OSV where subconto1 like '%55416%'

		/*Расчет итогов*/

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '1'
		) t2 on (t1.rowName = '1')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '2'
		) t2 on (t1.rowName = '2')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '3'
		) t2 on (t1.rowName = '3')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '4'
		) t2 on (t1.rowName = '4')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '5'
		) t2 on (t1.rowName = '5')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '6'
		) t2 on (t1.rowName = '6')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '7'
		) t2 on (t1.rowName = '7')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '8'
		) t2 on (t1.rowName = '8')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '9'
		) t2 on (t1.rowName = '9')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '10'
		) t2 on (t1.rowName = '10')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '11'
		) t2 on (t1.rowName = '11')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '12'
		) t2 on (t1.rowName = '12')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '13'
		) t2 on (t1.rowName = '13')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '14'
		) t2 on (t1.rowName = '14')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '15'
		) t2 on (t1.rowName = '15')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '16'
		) t2 on (t1.rowName = '16')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '17'
		) t2 on (t1.rowName = '17')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '18'
		) t2 on (t1.rowName = '18')
		when matched then update
		set t1.[sumAmountItog] = case when t2.[sumAmountItog]>0 then t2.[sumAmountItog] *-1 else 0 end;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = '19'
		) t2 on (t1.rowName = '19')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog] *-1;

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where rowName in ('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19')
		) t2 on (t1.rowName = '20')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		delete from dwh2.[finAnalytics].[repPublicPL_33_1] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_33_1]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Symbol], [Aplicator], [isBold], [sumAmountItog])

		select * from #rep
	
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 33.1'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 33.1 для Публикуемой'
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

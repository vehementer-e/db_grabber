







CREATE PROC [finAnalytics].[calcRepPublic_21_1] 
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
		group by acc2order

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
		, [sumAmountItog] = cast(isnull(osv.restOUT_BU * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_21_1] a
		left join #OSV osv on a.[Acc2] = osv.acc2order

		/*Расчет итогов*/

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 1
		) t2 on (t1.rowName = '1')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 2
		) t2 on (t1.rowName = '2')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 3
		) t2 on (t1.rowName = '3')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 4
		) t2 on (t1.rowName = '4')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 5
		) t2 on (t1.rowName = '5')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 6
		) t2 on (t1.rowName = '6')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 7
		) t2 on (t1.rowName = '7')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where razdel = 8
		) t2 on (t1.rowName = '8')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];


		merge into #rep t1
		using(
		select
		[sumAmountItog] = sum([sumAmountItog])
		from #rep
		where rowName in ('1','2','3','4','5','6','7','8')
		) t2 on (t1.rowName = '9')
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		
		delete from dwh2.[finAnalytics].[repPublicPL_21_1] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_21_1]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Aplicator], [isBold], [sumAmountItog])

		select * from #rep
	    
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 5.2'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 5.2 для Публикуемой'
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

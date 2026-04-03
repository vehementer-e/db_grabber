
CREATE PROC [finAnalytics].[calcRepPublic_8_6] 
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
	

	 
		drop table if exists #PBR
		create table #PBR (
			[Состояние] nvarchar(50) not null,
			[Признак заемщика] nvarchar(50) not null,
			[Счет учета основного долга] nvarchar(50) not null,
			[Счет 2 порядка] nvarchar(10) not null,
			[Ставка на дату формирования отчета] float null,
			[Срок договора в днях] int null
		)

		insert into #PBR
		select
		[Состояние] = a.dogStatus
		,[Признак заемщика] = a.isZaemshik
		,[Счет учета основного долга] = a.AccODNum
		,[Счет 2 порядка] = substring(a.AccODNum,1,5)
		,[Ставка на дату формирования отчета] = a.stavaOnRepDate
		,[Срок договора в днях] = a.dogPeriodDays

		from dwh2.finAnalytics.PBR_MONTHLY a
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
			[sumAmountCol3_1] float null,
			[sumAmountCol3_2] float null,
			[sumAmountCol4_1] float null,
			[sumAmountCol4_2] float null
		)


		/*Данные из справочника*/
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
		, [sumAmountCol3_1] = null
		, [sumAmountCol3_2] = null
		, [sumAmountCol4_1] = null
		, [sumAmountCol4_2] = null
		from dwh2.[finAnalytics].[SPR_repPublicPL_8_6] a


		merge into #rep t1
		using(
			select 
			[Счет 2 порядка]
			,[minStavka] = min(isnull([Ставка на дату формирования отчета],99999999))
			,[maxStavka] = max(isnull([Ставка на дату формирования отчета],0))
			,[minInterval] = min(isnull([Срок договора в днях],99999999))
			,[maxInterval] = max(isnull([Срок договора в днях],0))
			from #PBR
			where [Состояние] = 'Действует'
			group by [Счет 2 порядка]
		) t2 on (t1.[Acc2] = t2.[Счет 2 порядка])
		when matched then update
		set t1.[sumAmountCol3_1] = t2.[minStavka],
			t1.[sumAmountCol3_2] = t2.[maxStavka],
			t1.[sumAmountCol4_1] = t2.[minInterval],
			t1.[sumAmountCol4_2] = t2.[maxInterval];


		/*Расчет итогов*/

		merge into #rep t1
		using(
		select
		[sumAmountCol3_1] = min([sumAmountCol3_1])
		,[sumAmountCol3_2] = max([sumAmountCol3_2])
		,[sumAmountCol4_1] = min([sumAmountCol4_1])
		,[sumAmountCol4_2] = max([sumAmountCol4_2])
		from #rep
		where razdel in (4,5,6,7,8)
		) t2 on (t1.rowName = '3')
		when matched then update
		set t1.[sumAmountCol3_1] = t2.[sumAmountCol3_1],
			t1.[sumAmountCol3_2] = t2.[sumAmountCol3_2],
			t1.[sumAmountCol4_1] = t2.[sumAmountCol4_1],
			t1.[sumAmountCol4_2] = t2.[sumAmountCol4_2];

		merge into #rep t1
		using(
		select
		[sumAmountCol3_1] = min([sumAmountCol3_1])
		,[sumAmountCol3_2] = max([sumAmountCol3_2])
		,[sumAmountCol4_1] = min([sumAmountCol4_1])
		,[sumAmountCol4_2] = max([sumAmountCol4_2])
		from #rep
		where razdel in (10,11,12,13,14)
		) t2 on (t1.rowName = '9')
		when matched then update
		set t1.[sumAmountCol3_1] = t2.[sumAmountCol3_1],
			t1.[sumAmountCol3_2] = t2.[sumAmountCol3_2],
			t1.[sumAmountCol4_1] = t2.[sumAmountCol4_1],
			t1.[sumAmountCol4_2] = t2.[sumAmountCol4_2];

		delete from dwh2.[finAnalytics].[repPublicPL_8_6] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_8_6]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Aplicator], [isBold], [sumAmountCol3_1], [sumAmountCol3_2], [sumAmountCol4_1], [sumAmountCol4_2])
		select * from #rep

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 8.6'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 8.6 для Публикуемой'
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

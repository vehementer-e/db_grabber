






CREATE PROC [finAnalytics].[calcRepPublic_19_2] 
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
	
	drop table if exists #DEPO
		create table #DEPO (
			[Состояние] nvarchar(50) not null,
			[Признак заемщика] nvarchar(50) not null,
			[Ставка на дату формирования отчета] float null,
			[Срок договора в днях] int null
		)

		insert into #DEPO
		select
		[Состояние] = a.[dogState]
		,[Признак заемщика] = a.[clientType]
		,[Ставка на дату формирования отчета] = a.[StavkaRepDate]
		,[Срок договора в днях] = a.[daysDog]
		from dwh2.finAnalytics.DEPO_MONTHLY a
		where a.repmonth = @repmonth

		
		drop table if exists #rep
		create table #rep(
			repmonth date not null,
			[RowNum] [int] NOT NULL,
			[Razdel] [nvarchar](10) NULL,
			[RowName] [nvarchar](10) NULL,
			[Pokazatel] [nvarchar](255) NULL,
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
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3_1] = null
		, [sumAmountCol3_2] = null
		, [sumAmountCol4_1] = null
		, [sumAmountCol4_2] = null
		from dwh2.[finAnalytics].[SPR_repPublicPL_19_2] a


		/*Расчет данных КО*/
		merge into #rep t1
		using(
			select 
			[minStavka] = min(isnull([Ставка на дату формирования отчета],99999999))
			,[maxStavka] = max(isnull([Ставка на дату формирования отчета],0))
			,[minInterval] = min(isnull([Срок договора в днях],99999999))
			,[maxInterval] = max(isnull([Срок договора в днях],0))
			from #DEPO
			where [Состояние] = 'Действует'
			and [Признак заемщика] = 'КО'

		) t2 on (t1.rowname = '2')
		when matched then update
		set t1.[sumAmountCol3_1] = t2.[minStavka],
			t1.[sumAmountCol3_2] = t2.[maxStavka],
			t1.[sumAmountCol4_1] = t2.[minInterval],
			t1.[sumAmountCol4_2] = t2.[maxInterval];

		/*Расчет данных ЮЛ*/
		merge into #rep t1
		using(
			select 
			[minStavka] = min(isnull([Ставка на дату формирования отчета],99999999))
			,[maxStavka] = max(isnull([Ставка на дату формирования отчета],0))
			,[minInterval] = min(isnull([Срок договора в днях],99999999))
			,[maxInterval] = max(isnull([Срок договора в днях],0))
			from #DEPO
			where [Состояние] = 'Действует'
			and [Признак заемщика] = 'ЮЛ'

		) t2 on (t1.rowname = '3')
		when matched then update
		set t1.[sumAmountCol3_1] = t2.[minStavka],
			t1.[sumAmountCol3_2] = t2.[maxStavka],
			t1.[sumAmountCol4_1] = t2.[minInterval],
			t1.[sumAmountCol4_2] = t2.[maxInterval];

		/*Расчет данных ЮЛ*/
		merge into #rep t1
		using(
			select 
			[minStavka] = min(isnull([Ставка на дату формирования отчета],99999999))
			,[maxStavka] = max(isnull([Ставка на дату формирования отчета],0))
			,[minInterval] = min(isnull([Срок договора в днях],99999999))
			,[maxInterval] = max(isnull([Срок договора в днях],0))
			from #DEPO
			where [Состояние] = 'Действует'
			and [Признак заемщика] = 'ФЛ'

		) t2 on (t1.rowname = '4')
		when matched then update
		set t1.[sumAmountCol3_1] = t2.[minStavka],
			t1.[sumAmountCol3_2] = t2.[maxStavka],
			t1.[sumAmountCol4_1] = t2.[minInterval],
			t1.[sumAmountCol4_2] = t2.[maxInterval];

		/*Расчет данных ИП*/
		merge into #rep t1
		using(
			select 
			[minStavka] = min(isnull([Ставка на дату формирования отчета],99999999))
			,[maxStavka] = max(isnull([Ставка на дату формирования отчета],0))
			,[minInterval] = min(isnull([Срок договора в днях],99999999))
			,[maxInterval] = max(isnull([Срок договора в днях],0))
			from #DEPO
			where [Состояние] = 'Действует'
			and [Признак заемщика] = 'ИП'

		) t2 on (t1.rowname = '5')
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
		where razdel in (2,3,4,5)
		) t2 on (t1.rowName = '1')
		when matched then update
		set t1.[sumAmountCol3_1] = t2.[sumAmountCol3_1],
			t1.[sumAmountCol3_2] = t2.[sumAmountCol3_2],
			t1.[sumAmountCol4_1] = t2.[sumAmountCol4_1],
			t1.[sumAmountCol4_2] = t2.[sumAmountCol4_2];

		/*Расчет данных сроков облигаций*/
		merge into #rep t1
		using(
		select 
		[minInterval] = min(isnull([Срок облигаций],99999999))
		,[maxInterval] = max(isnull([Срок облигаций],0))
		from(
		select
		[Срок облигаций] = DATEDIFF(day,issueDate,returnDate)
		from dwh2.[finAnalytics].[SPR_ObligacGrafic] a
		where a.repmonth = @repmonth
		) l1
		) t2 on (t1.rowName = '7')
		when matched then update
		set t1.[sumAmountCol4_1] = t2.[minInterval],
			t1.[sumAmountCol4_2] = t2.[maxInterval];
		
		
		delete from dwh2.[finAnalytics].[repPublicPL_19_2] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_19_2]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Aplicator], [isBold], [sumAmountCol3_1], [sumAmountCol3_2], [sumAmountCol4_1], [sumAmountCol4_2])
		
		select * from #rep
	
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 19.2'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 19.2 для Публикуемой'
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

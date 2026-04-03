


CREATE PROC [finAnalytics].[calcRepPL] 
    @repmonth date
AS
BEGIN
	
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для отчета PL для публикуемой'
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

  begin try
	
	exec [finAnalytics].[calcRepPLAccRests] @repmonth
	declare @msgAcc nvarchar(255) = 'Данные по остаткам на счетах расчитаны'

	exec [finAnalytics].[calcRepPL843_part1] @repmonth
	declare @msgPart1 nvarchar(255) = 'Данные для ф843 часть 1 расчитаны'

	EXEC [finAnalytics].[calcRepPL843_part2]  @repmonth
	declare @msgPart2 nvarchar(255) = 'Данные для ф843 часть 2 расчитаны'

	EXEC [finAnalytics].[calcRepPL843_part3]  @repmonth
	declare @msgPart3 nvarchar(255) = 'Данные для ф843 часть 3 расчитаны'

	exec dwh2.[finAnalytics].[calcRepPL843_SPOD] @repmonth
	EXEC dwh2.[finAnalytics].[calcRepPL843_SPODTable] @repmonth
	declare @msgSPOD nvarchar(255) = 'Данные для ф843 СПОДы расчитаны'

	exec dwh2.[finAnalytics].[calcRepPL_declaraciaMonthly] @repmonth
	declare @msgDeclaraciaM nvarchar(255) = 'Данные для месячной декларации расчитаны'

	exec dwh2.[finAnalytics].[calcRepPL843_summary] @repmonth
	declare @msgSummary nvarchar(255) = 'Данные для Summary расчитаны'

	EXEC [finAnalytics].[calcRepPL_MSFO]  @repmonth
	declare @msgMSFO nvarchar(255) = 'Данные для МСФО расчитаны'

	EXEC [finAnalytics].[calcRepPL_ONOONA] @repmonth
	declare @msgONOONA nvarchar(255) = 'Данные для ОНО/ОНА расчитаны'

	EXEC [finAnalytics].[calcRepPL_declaraciaIvanova] @repmonth
	declare @msgDeclaraciaIvanova nvarchar(255) = 'Данные для декларации по формату Ивановой расчитаны'

	DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from [finAnalytics].[repPLf843]) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 44

	declare @repLink  nvarchar(max) = (select link from dwh2.[finAnalytics].[SYS_SPR_linkReport] where repName ='Отчет PL для публикуемой')
	
	DECLARE @msg_calcAll NVARCHAR(2048) = CONCAT (
				'Расчет данных для отчета PL для публикуемой'
                ,char(10)
                ,char(13)
				,'за отчетный месяц: '
				,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
				,char(10)
                ,char(13)
				,@msgAcc
				,char(10)
                ,char(13)
				,@msgPart1
				,char(10)
                ,char(13)
				,@msgPart2
				,char(10)
                ,char(13)
				,@msgPart3
				,char(10)
                ,char(13)
				,@msgSPOD
				,char(10)
                ,char(13)
				,@msgDeclaraciaM
				,char(10)
                ,char(13)
				,@msgDeclaraciaIvanova
				,char(10)
                ,char(13)
				,@msgSummary
				,char(10)
                ,char(13)
				,@msgMSFO
				,char(10)
                ,char(13)
				,@msgONOONA
				,char(10)
                ,char(13)
				,'Ссылка на отчет: '
				,@repLink
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_calcAll
			,@body_format = 'TEXT'
			,@subject = @subject;


	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета PL для публикуемой '
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
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

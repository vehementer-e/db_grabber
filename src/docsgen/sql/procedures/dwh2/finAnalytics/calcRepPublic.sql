



CREATE PROC [finAnalytics].[calcRepPublic] 
    @repmonth date
AS
BEGIN
	
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для публикуемой отчетности'
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	if month(@repmonth) in (3,6,9,12) 
	begin

  begin try
	
	/*Расчет данных*/
	exec [finAnalytics].[calcRepPublic_5_1]  @repmonth
	declare @msg5_1 nvarchar(255) = 'Данные для таблицы 5.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_5_2] @repmonth
	declare @msg5_2 nvarchar(255) = 'Данные для таблицы 5.2 расчитаны'

	exec [finAnalytics].[calcRepPublic_8_1] @repmonth
	declare @msg8_1 nvarchar(255) = 'Данные для таблицы 8.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_8_2] @repmonth
	declare @msg8_2 nvarchar(255) = 'Данные для таблицы 8.2 расчитаны'

	exec [finAnalytics].[calcRepPublic_8_3] @repmonth
	declare @msg8_3 nvarchar(255) = 'Данные для таблицы 8.3 расчитаны'

	exec [finAnalytics].[calcRepPublic_8_4] @repmonth
	declare @msg8_4 nvarchar(255) = 'Данные для таблицы 8.4 расчитаны'

	exec [finAnalytics].[calcRepPublic_17_1] @repmonth
	declare @msg17_1 nvarchar(255) = 'Данные для таблицы 17.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_17_3] @repmonth
	declare @msg17_3 nvarchar(255) = 'Данные для таблицы 17.3 расчитаны'

	exec [finAnalytics].[calcRepPublic_19_1] @repmonth
	declare @msg19_1 nvarchar(255) = 'Данные для таблицы 19.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_19_2] @repmonth
	declare @msg19_2 nvarchar(255) = 'Данные для таблицы 19.2 расчитаны'

	exec [finAnalytics].[calcRepPublic_19_4] @repmonth
	declare @msg19_4 nvarchar(255) = 'Данные для таблицы 19.4 расчитаны'

	exec [finAnalytics].[calcRepPublic_21_1] @repmonth
	declare @msg21_1 nvarchar(255) = 'Данные для таблицы 21.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_25_1] @repmonth
	declare @msg25_1 nvarchar(255) = 'Данные для таблицы 25.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_26_1] @repmonth
	declare @msg26_1 nvarchar(255) = 'Данные для таблицы 26.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_31_1] @repmonth
	declare @msg31_1 nvarchar(255) = 'Данные для таблицы 31.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_33_1] @repmonth
	declare @msg33_1 nvarchar(255) = 'Данные для таблицы 33.1 расчитаны'

	exec [finAnalytics].[calcRepPublic_40_2] @repmonth
	declare @msg40_2 nvarchar(255) = 'Данные для таблицы 40.2 расчитаны'

	exec [finAnalytics].[calcRepPublic_40_8] @repmonth
	declare @msg40_8 nvarchar(255) = 'Данные для таблицы 40.2 расчитаны'

	/*Проверка данных*/
	exec [finAnalytics].[checkRepPublic] @repmonth
	declare @msgCheck nvarchar(255) = 'Расчет контролей произведен'

	/*Определение наличия данных*/
    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from [finAnalytics].[repPublicPL_8_1]) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID] in (58)

	declare @repLink  nvarchar(max) = (select link from dwh2.[finAnalytics].[SYS_SPR_linkReport] where repName ='Публикуемая отчетность')
	
	declare @qName nvarchar(100) = (select 
									Year_Quartal_Name
									from dwh2.Dictionary.calendar
									where dt = @repmonth)

	DECLARE @msg_calcAll NVARCHAR(2048) = CONCAT (
				'Расчет данных для публикуемой отчетности'
                ,char(10)
                ,char(13)
				,'за отчетный квартал: '
				,@qname
				,char(10)
                ,char(13)
				,@msg5_1
				,char(10)
                ,char(13)
				,@msg5_2
				,char(10)
                ,char(13)
				,@msg8_1
				,char(10)
                ,char(13)
				,@msg8_2
				,char(10)
                ,char(13)
				,@msg8_3
				,char(10)
                ,char(13)
				,@msg8_4
				,char(10)
                ,char(13)
				,@msg17_1
				,char(10)
                ,char(13)
				,@msg17_3
				,char(10)
                ,char(13)
				,@msg19_1
				,char(10)
                ,char(13)
				,@msg19_2
				,char(10)
                ,char(13)
				,@msg19_4
				,char(10)
                ,char(13)
				,@msg21_1
				,char(10)
                ,char(13)
				,@msg25_1
				,char(10)
                ,char(13)
				,@msg26_1
				,char(10)
                ,char(13)
				,@msg31_1
				,char(10)
                ,char(13)
				,@msg33_1
				,char(10)
                ,char(13)
				,@msg40_2
				,char(10)
                ,char(13)
				,@msg40_8
				,char(10)
                ,char(13)
				,@msgCheck
				,char(10)
                ,char(13)
				,char(10)
                ,char(13)
				,'Ссылка на отчет: '
				,@repLink
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,21,5))
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
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности'
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
	end

END

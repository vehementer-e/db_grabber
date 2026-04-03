

CREATE   PROCEDURE [finAnalytics].[loadPA] 
		@repmonth date
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = 'Процедура сбора данных для Продуктовой аналитики'
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
	declare @emailList varchar(255)=''

   begin try
   begin tran  

   

	/*Этап 1. Добавление договоров*/
	declare @dogInserted int = 0
	exec [finAnalytics].[loadPA_step1] @repmonth, @dogInserted output
	
	/*Этап 2. Добавление статичных параметров договоров*/

	/*Этап 3. Добавление остатков*/
	declare @restsInserted int = 0
	exec [finAnalytics].[loadPA_step3] @repmonth, @restsInserted output

	/*Этап 4. Добавление резервов*/
	declare @reservInserted int = 0
	exec [finAnalytics].[loadPA_step4] @repmonth, @reservInserted output

	/*Этап 6. Добавление доп параметров*/
	declare @dopParamInserted int = 0
	exec [finAnalytics].[loadPA_step6] @repmonth, @dopParamInserted output

	/*Этап 7. Расчет данных по процентным доходам и Акциям Коллекшн*/
	declare @prcIncomrInserted int = 0
	declare @aciaCollectInserted int = 0
	exec [finAnalytics].[loadPA_step7] @repmonth, @prcIncomrInserted output , @aciaCollectInserted output


	----DECLARE @maxDateRest NVARCHAR(30)
 ----   set @maxDateRest = cast((select max(repmonth) from finAnalytics.PBR_MONTHLY ) as varchar)

	----/*Фиксация времени расчета*/
	----update dwh2.[finAnalytics].[reportReglament]
	----set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	----where [reportUID]  in (5,14,9,10)
    
   commit tran
    
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - сбор данных для Продуктовой аналитики за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
                --,'Время начала выполнения: '
                --,@procStartTime
                --,char(10)
                --,char(13)
                --,'Время окончания выполнения: '
                --,@procEndTime
                --,char(10)
                --,char(13)
                ,'Время выполнения: '
                ,@timeDuration
				,char(10)
                ,char(13)
				,'[Кол-во новых договоров] = ',@dogInserted
				,char(10)
                ,char(13)
			    ,'[Кол-во договоров с остатками] = ',@restsInserted
				,char(10)
                ,char(13)
			    ,'[Кол-во договоров с резервами] = ',@reservInserted
				,char(10)
                ,char(13)
			    ,'[Кол-во договоров с доп параметрами] = ',@dopParamInserted
				,char(10)
                ,char(13)
			    ,'[Кол-во договоров с Процентными доходами] = ',@prcIncomrInserted
				,char(10)
                ,char(13)
			    ,'[Кол-во договоров с Акциями Collection] = ',@aciaCollectInserted
                --,char(10)
                --,char(13)
                --,'Максимальная дата остатков: '
                --,@maxDateRest
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,34))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;


    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END

CREATE   PROCEDURE [finAnalytics].[loadSPR_affilage] 
    
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
    SELECT 1
       
    begin try

    --declare @repmonthtemp date = (select min(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[SPR_affilage])
    --declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth
    --select * from stg.[files].[SPR_affilage]

    delete from finAnalytics.SPR_Affilage --where REPMONTH=@repmonth

  begin tran  
    
    INSERT INTO finAnalytics.SPR_Affilage
	(
	repMonth, INN, client, affilType, affilName, affilBeginDate, affilEndDate, dataLoadDate
	 )
     

	select
   REPMONTH = DATEfromparts(year(a.[Отчетная дата]), month(a.[Отчетная дата]),1)--@REPMONTH
 , INN = a.[ИНН]
 , client = a.[Наименование заемщика]
 , affilType = a.[Характер взаимоотношений с МФО]
 , affilName =  a.[КОД 1С]
 , affilBeginDate = a.[Дата начала связанности]
 , affilEndDate = a.[Дата окончания связанности]
 , dataLoadDate = created
 
 from stg.[files].[SPR_affilage] a
 
    commit tran
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.SPR_Affilage) as varchar)
    

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Справочника аффилированных лиц.'
                --,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
                ,'Время начала выполнения: '
                ,@procStartTime
                ,char(10)
                ,char(13)
                ,'Время окончания выполнения: '
                ,@procEndTime
                ,char(10)
                ,char(13)
                ,'Время выполнения: '
                ,@timeDuration
                ,char(10)
                ,char(13)
                ,'Максимальная дата справочника: '
                ,@maxDateRest
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,5))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	--финиш
     exec dwh2.finAnalytics.sys_log @sp_name,1, @sp_name

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	--кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2))
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

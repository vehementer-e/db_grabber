


CREATE PROCEDURE [finAnalytics].[loadINCOMMING_BALANCE_MONTHLY] 
    
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

	-- проверка на соответвие полей таблиц из схемы STG и справочника STG ФинДеп
	exec finAnalytics.sys_checkSprStg @procName =@sp_name

    declare @repmonthtemp date = (select min([Дата периода]) from stg.[files].[INCOMING_BALANCE])
	declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    
	--select @repmonth
	declare @emailList varchar(255)=''

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)

  begin try

  
	
	declare @repMonthCountCheck int = 0
	set @repMonthCountCheck = (select
								[monthCount] = count(*)
								from(
								select 
								distinct 
								[month] = DATEFROMPARTS(DATEPART(year,[Дата периода]),datepart(month,[Дата периода]),1)
								from stg.[files].[INCOMING_BALANCE]
								) l1)

	if @repMonthCountCheck = 1 
	begin
	--select @repmonth
	begin tran  

	delete from dwh2.finanalytics.INCOMING_BALANCE where DATEFROMPARTS(DATEPART(year,[repDate]),datepart(month,[repDate]),1) = @repmonth

	insert into dwh2.finanalytics.INCOMING_BALANCE
	([repDate], [acc2order], [accGUID], [restIN_BU], [restOUT_BU], [created])

	select
	[repDate], [acc2order], [accGUID], [restIN_BU], [restOUT_BU], [created]
	from(
	select
	[repDate] = [Дата периода]
	,[acc2order] = [Счет]
	,[accGUID] = [dbo].[get1CIDRREF_FromGUID]([УИДСчет])
	,[restIN_BU] = [Сумма Начальный остаток]
	,[restOUT_BU] = [Сумма Конечный остаток]
	,created

	from stg.[files].[INCOMING_BALANCE]
	) l1


	commit tran

	DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

	/*Определение наличия данных*/
    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max([repDate]) from dwh2.finanalytics.INCOMING_BALANCE) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID] in (60)

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Отчета по ежедневным остаткам на счетах 2-го порядка ПСБ ФИНАНС за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
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
                ,'Максимальная дата остатков: '
                ,@maxDateRest
				)

	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1/*,2,3*/))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	end

	else
	begin
	DECLARE @msg_monthCount NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Кол-во загружаемых дат более 1 месяца!'
				)

	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_monthCount
			,@body_format = 'TEXT'
			,@subject = @subject;
	end

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

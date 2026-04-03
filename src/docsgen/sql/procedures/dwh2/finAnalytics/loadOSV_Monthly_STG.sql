

CREATE   PROCEDURE [finAnalytics].[loadOSV_Monthly_STG] 
    
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
    
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
       
    begin try

    declare @repmonthtemp date = (select min(CONVERT (date, [Отчетный месяц], 104)) from stg.[files].[OSV_MONTHLY_stg])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth

    delete from finAnalytics.OSV_MONTHLY_stg where REPMONTH=@repmonth

  begin tran  
    
    INSERT INTO finAnalytics.OSV_MONTHLY_stg
	(
	 repMonth, acc2order, acc2orderName, subconto1, subconto1UID, subconto2, subconto2UID, 
     subconto3, subconto3UID, branch, restIN_BU, restIN_NU, sumDT_BU, sumDT_NU, sumKT_BU, sumKT_NU, 
     restOUT_BU, restOUT_NU, dataLoadDate
	 )
     

	select
   REPMONTH = @REPMONTH
 , acc2order = a.[Счет2порядка]
 , acc2orderName = a.[Счет2порядкаНаименование]
 , subconto1 = a.[Субконто1]
 , subconto1UID = dbo.get1CIDRREF_FromGUID(a.[Субконто1 УИД])
 , subconto2 = a.[Субконто2]
 , subconto2UID = dbo.get1CIDRREF_FromGUID(a.[Субконто2 УИД])
 , subconto3 = a.[Субконто3]
 , subconto3UID = dbo.get1CIDRREF_FromGUID(a.[Субконто3 УИД])
 , branch = a.[Подразделение]
  , restIN_BU = a.[ОстатокНаНачалоПериодаБУ]
 , restIN_NU = a.[ОстатокНаНачалоПериодаНУ]
 , sumDT_BU = a.[ОборотДТ_БУ]
 , sumDT_NU = a.[ОборотДТ_НУ]
 , sumKT_BU = a.[ОборотКТ_БУ]
 , sumKT_NU = a.[ОборотКТ_НУ]
 , restOUT_BU = a.[ОстатокНаКонецПериодаБУ]
 , restOUT_NU = a.[ОстатокНаКонецПериодаНУ]
 , dataLoadDate = created

 from stg.[files].[OSV_MONTHLY_stg] a
 

 --/*Расчет данных для отчета по комиссиям*/
 --exec dwh2.finAnalytics.calcCommAll @repmonth

 --/*Расчет данных для отчета PL для публикуемой*/
 --exec dwh2.[finAnalytics].[calcRepPL] @repmonth

    commit tran
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.OSV_MONTHLY_stg) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDateSTG] = @maxDateRest
	where [reportUID]= 20

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка ОСВ СТГ за '
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

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1/*,2,31*/))
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

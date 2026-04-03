
CREATE PROCEDURE [finAnalytics].[loadReservBY_Monthly] 
    
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

    declare @repmonthtemp date = (select max(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[ReservBU_MONTHLY])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth

    delete from [finAnalytics].Reserv_BU where REPMONTH=@repmonth

  begin tran  
    
    INSERT INTO [finAnalytics].Reserv_BU
	(
	 REPMONTH, dogNum, isRestrukt, isBunkrupt, clientType, zaymType, client, nomenklGroup, 
     isAkcia0, restAll, restOD, restPRC, restOther, srokDolg, historicPros, allPros, 
     zaymGroup, diskount, reservAll, reservAllnextDay, reservOD, reservODnextDay, reservPRC, 
     reservPRCnextDay, reservOther, reservOthernextDay, reservAdd, reservBack, spisOKU12, spisOKUall, dataLoadDate
	 )
     

	select
   REPMONTH = @REPMONTH
 , dogNum = a.[Номер договора]
 , isRestrukt = a.[ Признак  реструктуризации договора]
 , isBunkrupt = isnull(b.isBankrupt,'Нет')
 , clientType = isnull(b.isZaemshik,'ФЛ')
 , zaymType = case when substring(b.AccODNum,1,5) = '48501' THEN 'Займ' else 'Микрозайм' end 
 , client = a.[Наименование заемщика]
 , nomenklGroup = a.[Номенклатурная группа]
 , isAkcia0 = a.[Акция 0%]
 , restAll = isnull(a.[Сумма задолженности по микрозайму, всего (руб#коп#)],0)
 , restOD = isnull(a.[Сумма  на отчетную дату_(руб#коп#) Сумма основного долга],0)
 , restPRC = isnull(a.[Сумма  на отчетную дату_(руб#коп#) Сумма требований по начисленн],0)
 , restOther = isnull(a.[Сумма  на отчетную дату (руб#коп#) Сумма прочей задолженности],0)
 , srokDolg = isnull(a.[Срок просроченной задолженности_ (дней)],0)
 , historicPros = cast(isnull(a.[Историческая просрочка_ (дней)],0) as int)
 , allPros = case when isnull(a.[Сумма  на отчетную дату_(руб#коп#) Сумма основного долга],0)=0 
                   and isnull(a.[Сумма  на отчетную дату_(руб#коп#) Сумма требований по начисленн],0)=0 
                   and isnull(a.[Сумма  на отчетную дату (руб#коп#) Сумма прочей задолженности],0)!=0 
                   and isnull(a.[Итого дней просрочки__],0)=0 
                  then abs(DATEDIFF(day,EOMONTH(@repmonth),r60323.prosDateBegin))
                  else isnull(a.[Итого дней просрочки__],0) end
 --, allPros = isnull(a.[Итого дней просрочки__],0)
 , zaymGroup = a.[Признак кредитно-обесценности займа на последнюю отчетную дату]
 , diskount = isnull(a.[Коэффициент дисконтирования],0)
 , reservAll = isnull(a.[Сумма резерва под обесценение (руб#коп#) Всего# По состоянию на ],0)
 , reservAllnextDay = isnull(a.[Сумма резерва под обесценение (руб#коп#) Всего# По состоянию на1],0)
 , reservOD = isnull(a.[Сумма резерва под обесценение (руб#коп#) Основной долг# По состо],0)
 , reservODnextDay = isnull(a.[Сумма резерва под обесценение (руб#коп#) Основной долг# По сост1],0)
 , reservPRC = isnull(a.[Сумма резерва под обесценение (руб#коп#) Проценты начисленные# П],0)
 , reservPRCnextDay = isnull(a.[Сумма резерва под обесценение (руб#коп#) Проценты начисленные# 1],0)
 , reservOther = isnull(a.[Сумма резерва под обесценение (руб#коп#) Прочая задолженность# П],0)
 , reservOthernextDay = isnull(a.[Сумма резерва под обесценение (руб#коп#) Прочая задолженность# 1],0)
 , reservAdd = cast(isnull(a.[Сумма резервов под обесценение_за отчетный период по основному д],0) as money)
 , reservBack = cast(isnull(a.[Сумма резервов под обесценение_за отчетный период по основному 1],0) as money)
 , spisOKU12 = cast(isnull(a.[Списание со счета по учету резерва под обесценение в сумме, равн],0) as money)
 , spisOKUall = cast(isnull(a.[Списание со счета по учету резерва под обесценение в сумме, рав1],0) as money)
 , dataLoadDate = created
 
 from stg.[files].[ReservBU_MONTHLY] a
 left join (
 select
    a.dogNum
    ,a.isZaemshik
    ,a.isBankrupt
    ,AccODNum
    ,row_number() over (Partition by a.dogNum order by a.repmonth desc) rn
 from finAnalytics.PBR_MONTHLY a
 ) b on a.[Номер договора]=b.dogNum and b.rn=1
 
  left join (
        select
        a.repMonth
        ,a.dogNum
        ,prosDateBegin = min(a.prosDateBegin)
        from finAnalytics.rests60323 a
        --where dogNum='17102010380001'
        group by a.repMonth
        ,a.dogNum
    ) r60323 on a.[Номер договора]=r60323.dogNum and r60323.repmonth=@repmonth

    commit tran
    
    --order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.Reserv_BU) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 18

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Резервы БУ за '
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
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2))
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

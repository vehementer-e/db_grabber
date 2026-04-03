

CREATE PROCEDURE [finAnalytics].[loadRepDinamikaPortfData]
        @historyDaysCount int   ---Параметр кол-ва последних дней для пересчета, если -1  считает всю историю
AS
BEGIN

    declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

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

    DROP TABLE IF EXISTS [finAnalytics].#DT
    Create table #DT(
    [DT] date NOT NULL,
	DT1 date,
    [DayNum] int NOT NULL,
    [Тип данных] varchar(50) not null
    )
	
	create index ix on #dt(DT1) include(DayNum, [Тип данных])

    --Заполнение временной таблицы дат всем диапазоном
    if @historyDaysCount = -1

    insert into #DT
    select
    convert(datetime,dateadd(year,2000,DT),20) as DT
	,DT as DT1
    ,DayNum = id_weekday
    ,[Тип данных] = case when dt=EOMONTH(dt) then 'Итого по месяцу' else 'Промежуточные результаты' end 
    from Dictionary.calendar
    where DT between cast('2018-06-01' as date) and dateadd(day,-1,cast(GETDATE() as date))
    and (
        id_weekday=7
        or
        dt=EOMONTH(dt)
        )

    --Заполнение временной таблицы дат кол-вом последних дней из параметра
    else 

    insert into #DT
    select
    convert(datetime,dateadd(year,2000,DT),20) as DT
	, DT as DT1
    ,DayNum = id_weekday
    ,[Тип данных] = case when dt=EOMONTH(dt) then 'Итого по месяцу' else 'Промежуточные результаты' end 
    from Dictionary.calendar
    where DT between getdate()-@historyDaysCount and dateadd(day,-1,cast(GETDATE() as date))
    and (
        id_weekday=7
        or
        dt=EOMONTH(dt)
        );
    
    begin try
    
    begin tran
    --Очистка таблицы результата по выбранному перечню дат
    
	drop table if exists #registr
	
	select
    [REPDATE] = l1.Дата
    ,[dayWeekNum] = l1.[ДЕНЬ НЕД.]
    ,[repType] = l1.[Тип отчета]
    ,[restODfull] = cast(sum(l1.[ПОРТФЕЛЬ ОД]) as money)
    ,[restODwork] = cast(sum(l1.[РАБОТАЮЩИЙ ПОРТФЕЛЬ]) as money)
    ,[restODnotWork] = cast(sum(l1.[НЕРАБОТАЮЩИЙ ПОРТФЕЛЬ (90+)]) as money)
    ,[restODnotWorkPart] = cast(sum(l1.[НЕРАБОТАЮЩИЙ ПОРТФЕЛЬ (90+)]) as money) / cast(sum(l1.[ПОРТФЕЛЬ ОД]) as money)
    --,rn = row_number () over (order by l1.Дата desc) 

	into #registr

    from(
    select  
    [Дата] = dateadd(year,-2000,a.ДатаОтчета) 
    ,[ДЕНЬ НЕД.] = #DT.DayNum
    ,[Тип отчета] = #DT.[Тип данных]
    ,[ПОРТФЕЛЬ ОД] = a.ОстатокОДвсего
    ,[РАБОТАЮЩИЙ ПОРТФЕЛЬ] = case when a.ДнейПросрочкиДляРезервов <=90 then a.ОстатокОДвсего else 0 end
    ,[НЕРАБОТАЮЩИЙ ПОРТФЕЛЬ (90+)] = case when a.ДнейПросрочкиДляРезервов >90 then a.ОстатокОДвсего else 0 end
    ,[ДОЛЯ НЕРАБОТАЮЩЕГО  ПОРТФЕЛЯ] = null
    ,[КОЛ_ВО ДНЕЙ ПРОСРОЧКИ] = a.ДнейПросрочкиДляРезервов
    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
    inner join #DT on a.ОтчетнаяДата = #dt.DT1
    where 
    1=1
    and substring(a.СчетОД,1,5) in ('48801','48701','49401')
    ) l1

    group by l1.Дата,l1.[ДЕНЬ НЕД.],l1.[Тип отчета]
    order by l1.Дата desc

	
	DELETE FROM finAnalytics.repDinamikaPortf
    where repdate in (SELECT DT1 FROM #DT)

    INSERT INTO finAnalytics.repDinamikaPortf
    (REPDATE, dayWeekNum, repType, restODfull, restODwork, restODnotWork, restODnotWorkPart)

	select * from #registr
    

	--/*Автоматическое обновление BI*/
	--EXEC [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
	--@subscription_id = 'f53b44f6-2584-47d1-b1c6-b263d155efba',
	--@await_success = 0
	
	
	commit tran

	/*Вызов процедуры не выданных Автокредитов для расчета фондирования*/
	exec dwh2.[finAnalytics].[calcFondegAutocredit]

    
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(REPDATE) from finAnalytics.repDinamikaPortf where restODfull !=0) as varchar)
    
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 2

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - '
				,@sp_name
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
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
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

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem

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

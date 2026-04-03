
CREATE PROC [finAnalytics].[loadRepMicrozaimData] 
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
       
    begin try

    --Удаление темповой таблицы
    --IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[finAnalytics].#DT') AND type in (N'U'))
    DROP TABLE IF EXISTS [finAnalytics].#DT

    --Временная таблица для хранения списка нужных дат для расчета
    Create table #DT(
    [DT] date NOT NULL,
    [DT1] date NOT NULL,
    [DayNum] int NOT NULL,
    [Тип данных] varchar(50) not null
    )

    --Заполнение временной таблицы дат всем диапазоном
    if @historyDaysCount = -1

    insert into #DT
    select
    convert(datetime,dateadd(year,2000,DT),20) as DT
	,DT as DT1
    ,DayNum = id_weekday
    ,[Тип данных] = case when dt=EOMONTH(dt) then 'Итого по месяцу' else 'Промежуточные результаты' end 
    from Dictionary.calendar
    where DT between cast('2022-07-01' as date) and cast(dateadd(day,-1,getdate()) as date)

    --Заполнение временной таблицы дат кол-вом последних дней из параметра
    else 

    insert into #DT
    select
    convert(datetime,dateadd(year,2000,DT),20) as DT
	, DT as DT1
    ,DayNum = id_weekday
    ,[Тип данных] = case when dt=EOMONTH(dt) then 'Итого по месяцу' else 'Промежуточные результаты' end 
    from Dictionary.calendar
    where DT between dateadd(day,-@historyDaysCount,cast(getdate() as date)) and cast(dateadd(day,-1,getdate()) as date)
    ;
  begin tran  
    --Очистка таблицы результата по выбранному перечню дат
    DELETE FROM finAnalytics.repMicrozaim
    where repdate >= (SELECT min(DT1) FROM #DT)

    --Сохранение результата
    INSERT INTO finAnalytics.repMicrozaim
    (REPMONTH, REPDATE, dataType, restOD, sales, pogashenia, cessia,banRez,pogasheniaRR,salesRR)
    select
    [Отчетный месяц] = l2.[Отчетный месяц]
    ,[Отчетная дата] = cast(l2.[Отчетная дата] as date)
    ,[Тип отчета] = l2.[Тип отчета]
    ,[Остаток ОД на конец дня] = cast(sum(l2.[Остаток ОД на конец дня]) as money)
    ,[Выдачи] = cast(sum(l2.Выдачи) as money)
    ,[Погашения / Списания] = cast(sum(l2.[Погашения / Списания]) as money)
    ,[Цессия] =cast(sum(l2.[Цессия]) as money)
	,[Погашение мошенники и резервы]=cast(sum(l2.[Погашение мошенники и резервы]) as money)
	,[RR погашения]=l2.[RR погашения]
	,[RR выдачи]=l2.[RR выдачи]
    from(

		select
		[Отчетный месяц] = eomonth(l1.Дата)
		,[Отчетная дата] = l1.Дата
		,l1.[Тип отчета]
		,[Остаток ОД на конец дня] = cast(sum(l1.[ПОРТФЕЛЬ ОД]) as money)
		,[Выдачи] = 0
		,[Погашения / Списания] = 0
        ,[Цессия] = 0
		,[Погашение мошенники и резервы]=0
		,[RR погашения]=0.0
		,[RR выдачи]=0.0
		from(
		select  
		[Дата] = dateadd(year,-2000,a.ДатаОтчета) 
		,[Тип отчета] = #DT.[Тип данных]
		,[ПОРТФЕЛЬ ОД] = a.ОстатокОДвсего
		from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
		inner join #DT on a.ОтчетнаяДата=#DT.DT1
		where 
		1=1
		and substring(a.СчетОД,1,5) in ('48801','48701','49401')
    ) l1

    group by l1.Дата,eomonth(l1.Дата),l1.[Тип отчета]

    union all

    select  
    [Отчетный месяц] = eomonth(l1.[ДатаОперации])
    ,[Отчетная дата] = l1.[ДатаОперации]
    ,l1.[Тип отчета]
    ,[Остаток ОД на конец дня] = 0
    ,[Выдачи] = cast(sum(l1.Выдачи) as money)
    ,[Погашения] = cast(sum(l1.Погашения) as money)
    ,[Цессия] = cast(sum(l1.Цессия) as money)
	,[Погашение мошенники и резервы]=cast(sum(l1.[Погашение мошенники и резервы]) as money)
	,[RR погашения]=l1.[RR погашения]
	,[RR выдачи]=l1.[RR выдачи]
    from(

	    SELECT 
            [ДатаОперации] = cast(dateadd(year,-2000,a.Период) as date)
	        ,[Выдачи] = case when b1.Код in ('48801','48701','49401') then a.Сумма else 0 end 
	        ,[Погашения] = case 
                            when b2.Код in ('48801','48701','49401') and (
                                upper(ces.Представление) not like upper('%передача прав требований%')
                                or
                                ces.Представление is null
                                )
                            then isnull(a.Сумма,0) else 0 end 
	        ,[Тип отчета] = #DT.[Тип данных]
            ,[Цессия] = case 
                            when b2.Код in ('48801','48701','49401') and upper(ces.Представление) like upper('%передача прав требований%')
                            then isnull(a.Сумма,0) else 0 end
			,[Погашение мошенники и резервы]= case 
												when 
													((b1.Код in('48710','48810','49410')and	b2.Код in ('48701','48801','49401') and a.Содержание like '%резерв%'))
													or
													(b1.Код in('60323','47423')and b2.Код in ('48701','48801','49401') and acc.Наименование like '%мошенни%')
												then isnull(a.Сумма,0) else 0 end
			,[RR погашения]=0.0
			,[RR выдачи]=0.0
        from Stg.[_1cUMFO].РегистрБухгалтерии_БНФОБанковский a
        left join Stg.[_1cUMFO].ПланСчетов_БНФОБанковский b1 on a.СчетДт=b1.ссылка
        left join Stg.[_1cUMFO].ПланСчетов_БНФОБанковский b2 on a.СчетКт=b2.ссылка
        left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
        left join Stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета acc on a.СчетАналитическогоУчетаДт=acc.Ссылка
		inner join #DT on cast(a.Период as date) =#DT.DT
        where 1=1--cast(Период as date) = dateadd(year,2000,cast('2024-04-27' as date))
        and (b1.Код in ('48801','48701','49401') or b2.Код in ('48801','48701','49401'))
        and a.Активность = 0x01
    ) l1
		group by 
		eomonth(l1.[ДатаОперации])
		,l1.[ДатаОперации]
		,l1.[Тип отчета]
		,l1.[RR погашения]
		,l1.[RR выдачи]
    ) l2

    group by
    l2.[Отчетный месяц]
    ,l2.[Отчетная дата]
    ,l2.[Тип отчета]
	,l2.[RR погашения]
	,l2.[RR выдачи]


---- 
	drop table if exists #RRsales
	CREATE TABLE #RRsales (

	[Месяц] date
	,[Дата] date
	,[Сумма_ПТС] float
	,[Доля для RR ПТС] float
	,[Доля для RR инстоллмент] float
	,[Сумма_инстоллмент] float
	,[Выданная сумма Big] float
	,[Выданная сумма AC] float
	,[Заявок ПТС] float
	,[Заявок CPA ПТС] float
	,[Заявок CPA нецелевой ПТС] float
	,[Заявок CPA полуцелевой ПТС] float
	,[Заявок CPA целевой ПТС] float
	,[Заявок Триггеры ПТС] float
	,[Заявок CPC ПТС] float
	,[Заявок Банки ПТС] float
	,[Заявок Партнеры ПТС] float
	,[Заявок Органика ПТС] float
	,[Заявок Канал привлечения не определен - КЦ ПТС] float
	,[Заявок Канал привлечения не определен - МП ПТС] float
	,[Заявок Сайт орган.трафик ПТС] float
	,[Заем выдан ПТС] float
	,[Выданная сумма новые ПТС] float
	,[Заявок ПТС накоп] float
	,[Заем выдан ПТС накоп] float
	,[Выданная сумма ПТС накоп] float
	,[Выданная сумма новые ПТС накоп] float
	)

	INSERT INTO #RRsales EXEC Analytics.[_birs].[rr]
	delete from #RRsales where Дата<(select min(dateadd(year,-2000,dt)) from #dt)

	--наполенение расчетными RR погашения за выбранный период.
	declare @startDate date=(select min(dateadd(year,-2000,dt)) from #dt)
	declare @endDate date =(select max(dateadd(year,-2000,dt)) from #dt)
	declare @numDay int = datediff(day,'19000101',@endDate)-datediff(day,'19000101',@startDate)
	declare @rrDate date, @RRpoga float, @kfRRsales float, @RRsales float

	while @numDay>0
		begin
			set @rrDate= dateadd(day,@numDay,@startDate)
			if 1=1 --@rrDate=EOMONTH(@rrDate)
				begin
					exec finAnalytics.calcMicrozaimRR @rrDate,@RRpoga out
					set @kfRRsales=isnull((select [Доля для RR ПТС] from #RRsales where Дата=@rrDate),0)
					set @RRsales=(select sum(sales) from finAnalytics.repMicrozaim where repdate between dateadd(day,-(day(@rrDate)-1),@rrdate) and @rrDate)
					set @RRsales=iif(@kfRRsales<>0,@RRsales/@kfRRsales,0)
					
					update finAnalytics.repMicrozaim
						set pogasheniaRR=@RRpoga
						, salesRR=@RRsales
					where repdate=@rrDate 
				end
			set @numDay=@numDay-1
		end

	

	commit tran
---
    --order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(REPDATE) from finAnalytics.repMicrozaim where restOD !=0) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 3

	/*Расчет выдачи по продуктам*/
	 exec dwh2.finAnalytics.loadRepMicrozaimData_Produkt  @historyDaysCount

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

	
	--/*Автоматическое обновление BI*/
	--EXEC [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
	--@subscription_id = '9300ce6b-af89-4019-8f66-34e1a1320d6',
	--@await_success = 0
	
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


CREATE PROCEDURE [finAnalytics].[checkSourceData]
	
    @fromDate date,
    @shellCheckSourceName varchar(100)
	
AS
BEGIN
    if @fromDate = null
    set @fromDate = dateadd(day,-10,cast(getdate() as date));
	/*
    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
    DECLARE @Result TABLE (
        [Календарная дата] date not null,
        [Дата отчета] date not null,
        [Кол-во записей] bigint
    );
    */


    --Удаление темповой таблицы
    --IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[finAnalytics].#DT') AND type in (N'U'))
    DROP TABLE IF  EXISTS[finAnalytics].#DT

    --Временная таблица для хранения списка нужных дат для расчета
    Create table #DT(
		[DT] date NOT NULL,
		[Календарная дата] date NOT NULL
    )

    insert into #DT
    select 
		[DT] = dateadd(year,2000,DT)
		,[Календарная дата] = DT
    from 
		dwh2.Dictionary.calendar
    where 
		DT between @fromDate and dateadd(day,-1,cast(getdate() as date))


    ---------------Проврека витрины УМФО с остатками
    if (upper(@shellCheckSourceName) = upper('all') or upper(@shellCheckSourceName) = upper('rests'))

    select 
		t1.[Календарная дата]
		,t2.[Дата отчета]
		,t2.[Кол-во записей]
    from 
		#dt t1
		left join 
		(
			select
				[Дата отчета] = a.ОтчетнаяДата
				,[Кол-во записей] = count(*)
			from
				stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
				inner join 
				#DT on a.ОтчетнаяДата = #DT.КалендарнаяДата
			group by 
				a.ОтчетнаяДата
		) t2 on t1.[Календарная дата]=t2.[Дата отчета]
    order by 
		t1.dt desc;

    ---------------Проврека витрины УМФО с оборотами
    if (upper(@shellCheckSourceName) = upper('all') or upper(@shellCheckSourceName) = upper('prov'))

    select 
		t1.[Календарная дата]
		,t2.[Дата отчета]
		,t2.[Кол-во записей]
    from 
		#dt t1
		left join 
		(
		    select 
				[Дата отчета] = cast(DateAdd(year,-2000,a.Период) as date)
				,[Кол-во записей] = count(*)
			from 
				stg._1cUMFO.РегистрНакопления_АЭ_ВзаиморасчетыПоЗаймамПредоставленным a
				inner join 
				#DT on cast(a.Период as date)=#DT.DT
			group by 
				cast(DateAdd(year,-2000,a.Период) as date)
        ) t2 on t1.[Календарная дата]=t2.[Дата отчета]
    order by 
		t1.dt desc


    ---------------Проврека витрины Резервы НУ
    if (upper(@shellCheckSourceName) = upper('all') or upper(@shellCheckSourceName) = upper('reserv'))

    select 
		t1.[Календарная дата]
		,t2.[Дата отчета]
		,t2.[Кол-во записей]
    from 
		#dt t1
		left join 
		(
			select 
				[Дата отчета] = eomonth(a.REPMONTH)
				,[Кол-во записей] = count(*)
			from 
				dwh2.finAnalytics.Reserv_NU a
				inner join 
				#DT on eomonth(a.REPMONTH)=dateadd(year,-2000,#DT.DT) 
			group by 
				eomonth(a.REPMONTH)
        ) t2 on t1.[Календарная дата]=t2.[Дата отчета]
    where 
		t1.[Календарная дата]=EOMONTH(t1.[Календарная дата])
    order by 
		t1.dt desc

    ---------------Проврека витрины ПБР
    if (upper(@shellCheckSourceName) = upper('all') or upper(@shellCheckSourceName) = upper('pbr'))

    select 
    t1.[Календарная дата]
    ,t2.[Дата отчета]
    ,t2.[Кол-во записей]
    
    from #dt t1

    left join (
    select 
    [Дата отчета] = eomonth(a.REPMONTH)
    ,[Кол-во записей] = count(*)
    --,a.*
    from dwh2.finAnalytics.PBR_MONTHLY a
    inner join #DT on eomonth(a.REPMONTH)=dateadd(year,-2000,#DT.DT) --and a.REPDATE=EOMONTH(a.REPMONTH)
    group by eomonth(a.REPMONTH)
        ) t2 on t1.[Календарная дата]=t2.[Дата отчета]

    where t1.[Календарная дата]=EOMONTH(t1.[Календарная дата])

    order by t1.dt desc


    /*
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    
    --set @maxDateRest = cast((select max(REPDATE) from dwh2.finAnalytics.repMicrozaim where restOD !=0) as varchar)
    

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
                ,'Результат проверки: '
                --,@result
				)

    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'd.detkin@techmoney.ru'
			,@copy_recipients = ''--'dwh112@carmoney.ru'
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
    */
END

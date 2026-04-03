

CREATE PROCEDURE [finAnalytics].[calcSalesRepData_Monthly] 
    @repmonth date

AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,'Данные для отчета по Продажам'
				)
       
    begin try
        declaRE @dateFrom date = @repmonth
        declaRE @dateTo date = eomonth(@repmonth)

        drop table if exists #loans
        CREATE TABLE #loans (
        [код] nvarchar(28)	
        ,[CRMClientGUID] char(36)
        ,[Дата договора]datetime2
        ,[Сумма] numeric
        ,[Адрес проживания CRM] nvarchar(300)	
        ,[Срок] numeric
        ,[Агент партнер] nvarchar(200)	
        ,[product] varchar(27)
        ,[Сумма комиссионных продуктов снижающих ставку] float
        ,[Вид займа] nvarchar(max)
        ,[Дата выдачи] datetime2
        ,[Сумма расторжений по КП] float
        ,[ПСК текущая] numeric
        ,[ПСК первоначальная] numeric
        ,[Текущая процентная ставка] numeric
        ,[Первая процентная ставка] numeric
        ,[канал] nvarchar(510)
        ,[Признак КП снижающий ставку] int
        ,[Сумма комиссионных продуктов] float
        ,[Сумма комиссионных продуктов Carmoney] float
        ,[Сумма комиссионных продуктов Carmoney Net] float
        ,[CP_info] nvarchar(4000)	
        ,[Дата обновления записи по займу] datetime
        ,[Дистанционная выдача] int
        )

        INSERT INTO #loans EXEC Analytics._birs.loans_for_finance @dateFrom, @dateTo


        drop table if exists #RR
        CREATE TABLE #RR (

        [Месяц] date
        ,[Дата] date
        ,[Сумма_ПТС] float
        ,[Доля для RR ПТС] float
        ,[Доля для RR инстоллмент] float
        ,[Сумма_инстоллмент] float
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

        INSERT INTO #RR EXEC Analytics.[_birs].[rr]

        drop table if exists #PBR
        create table #PBR(
        client varchar(300) null,
        dogNum varchar(100) not null,
        saleDate date not null,
        saleType varchar(100) null,
        dogPeriodMonth int not null,
        dogPeriodDays int not null,
        dogSum money not null,
        finProd varchar(100) null,
        nomenkGroup varchar(100) null,
        PDNOnSaleDate float null,
        stavaOnSaleDate float null, 
        spr1 varchar(100) null,
        spr2 varchar(100) null,
        spr3 varchar(100) null,
        spr4 varchar(100) null,
        spr5 varchar(100) null,
        spr6 varchar(100) null
        )


        INSERT INTO #PBR
        (client, dogNum, saleDate, saleType, dogPeriodMonth, dogPeriodDays, dogSum, finProd, nomenkGroup, PDNOnSaleDate, stavaOnSaleDate)
        select
        [client] = a.client
        ,[dogNum] = a.dogNum
        ,[saleDate] = a.saleDate
        ,[saleType] = a.saleType
        ,[dogPeriodMonth] = a.dogPeriodMonth
        ,[dogPeriodDays] = a.dogPeriodDays
        ,[dogSum] = a.dogSum
        ,[finProd] = a.finProd
        ,[nomenkGroup] = a.nomenkGroup
        ,[PDNOnSaleDate] = a.PDNOnSaleDate
        ,[stavaOnSaleDate] = a.stavaOnSaleDate

        from finAnalytics.PBR_MONTHLY a

        where a.REPMONTH = @repmonth
        and a.saleDate between @repmonth and EOMONTH(@repmonth)


        UPDATE #PBR 
        set spr1 = case when upper(finProd) not like upper('%installment%')
                    and upper(finProd) not like upper('%pdl%')
                    and upper(finProd) not like upper('%бизнес%') then 'ПТС'
                    when upper(nomenkGroup) like upper('%installment%') then 'Installment'
                    when upper(nomenkGroup) like upper('%PDL%') then 'PDL'
                    when upper(finProd) like upper('%бизнес%') then 'Бизнес-займ'
                    else '-'
                    end


        merge into #PBR t1
        using (
        select 
        код
        ,[Вид займа] = case when upper([Вид займа]) = upper('Параллельный') then 'Докреды'
                    when upper([Вид займа]) = upper('докредитование') then 'Докреды'
                    when upper([Вид займа]) = upper('первичный') then 'Новые'
                    when upper([Вид займа]) = upper('повторный') then 'Повторники'
                    else [Вид займа] end
        from #loans
        ) t2 on (t1.dogNum=t2.код)
        when matched then update
        set spr2=t2.[Вид займа];


        merge into #PBR t1
        using (
        select 
        a.dogNum
        ,a.spr1
        ,a.spr2
        ,b.product
        ,[spr3] = case when upper(a.spr1) = upper('ПТС')
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP - 40%') then 'RBP - 40'

                when upper(a.spr1) = upper('ПТС')
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP - 56%') then 'RBP-56'

                when upper(a.spr1) = upper('ПТС')
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP - 66%') then 'RBP-66'

                when upper(a.spr1) = upper('ПТС')
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP - 86%') then 'RBP-86'

                when upper(a.spr1) = upper('ПТС')
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%non - RBP%') then 'non-RBP'

                when upper(a.spr1) = upper('ПТС')
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%Исп. срок%') then 'Исп. срок'

                when upper(a.spr1) = upper('ПТС')
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%Рефинансирование%') then 'Рефинанс.'

                else null end
            
        from #PBR a
        left join #loans b on a.dogNum=b.код
        ) t2 on (t1.dogNum=t2.dogNum)
        when matched then update
        set t1.spr3=t1.spr3;


        UPDATE #PBR 
        set spr4 = case when upper(client) like upper('%техмани%') then 'Компании Группы'
                when upper(client) like upper('%айоти%') then 'Компании Группы'
                when upper(client) like upper('%смарт горизонт%') then 'Компании Группы'
                when upper(client) like upper('%смарттехгрупп%') then 'Компании Группы'
                when upper(client) like upper('%пао стг%') then 'Компании Группы'
                when upper(client) like upper('%стг пао%') then 'Компании Группы'
                when upper(client) like upper('%кармани%') then 'Компании Группы'
                when upper(client) like upper('%запросто%') then 'Компании Группы'
                else null end


        UPDATE #PBR 
        set spr6 = case when PDNOnSaleDate <=0.5 then 'ПДН <=50'
                when PDNOnSaleDate >0.5 and PDNOnSaleDate <=0.8 then 'ПДН >50% и <=80%'
                when PDNOnSaleDate >0.8 then 'ПДН >80%'
                when PDNOnSaleDate =0 then 'Без ПДН (до 10 т.р.)'
                else '-' end

    

    begin tran  
    
        delete from finAnalytics.repSales where repmonth = @repmonth

        --------------------Таблица 1--------------------
        --t1p1
        insert into finAnalytics.repSales 
        select
        [repmonth] = @repmonth
        ,l1.tabNum
        ,l1.tabName
        ,l1.pokazatelNum
        ,l1.pokazatel
        ,pAmount = b.planValue
        ,l1.fAmount
        ,c.[Доля для RR ПТС]
        from(
        select
        [tabNum] = 1
        ,[tabName] = 'Всего продажи'
        ,[pokazatelNum] = 1
        ,[pokazatel] = 'Объём продаж, млн р.'
        ,[pAmount] = 0
        ,[fAmount] = sum(a.dogSum)

        from #PBR a
        where a.spr4 is null
        ) l1
        left join finAnalytics.SPR_repSalesPlan b on b.repmonth=EOMONTH(@repmonth) and upper(b.pokazatel)=upper('Объём, руб.') and upper(b.product)=upper('Всего продажи')
        left join #RR c on c.Дата = EOMONTH(@repmonth)

        --t1p2
        insert into finAnalytics.repSales 
        select
        [repmonth] = @repmonth
        ,l1.tabNum
        ,l1.tabName
        ,l1.pokazatelNum
        ,l1.pokazatel
        ,pAmount = b.planValue
        ,l1.fAmount
        ,c.[Доля для RR ПТС]
        from(
        select
        [tabNum] = 1
        ,[tabName] = 'Всего продажи'
        ,[pokazatelNum] = 2
        ,[pokazatel] = 'Количество, шт.'
        ,[pAmount] = 0
        ,[fAmount] = count(distinct a.dogNum)

        from #PBR a
        where a.spr4 is null
        ) l1
        left join finAnalytics.SPR_repSalesPlan b on b.repmonth=EOMONTH(@repmonth) and upper(b.pokazatel)=upper('Количество, шт.') and upper(b.product)=upper('Всего продажи')
        left join #RR c on c.Дата = EOMONTH(@repmonth)

        --t1p4
        insert into finAnalytics.repSales 
        select
        [repmonth] = @repmonth
        ,l1.tabNum
        ,l1.tabName
        ,l1.pokazatelNum
        ,l1.pokazatel
        ,pAmount = b.planValue
        ,l1.fAmount
        ,c.[Доля для RR ПТС]
        from(
        select
        [tabNum] = 1
        ,[tabName] = 'Всего продажи'
        ,[pokazatelNum] = 4
        ,[pokazatel] = 'Средняя ставка'
        ,[pAmount] = 0
        ,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / sum(a.dogSum) / 100

        from #PBR a
        where a.spr4 is null
        ) l1
        left join finAnalytics.SPR_repSalesPlan b on b.repmonth=EOMONTH(@repmonth) and upper(b.pokazatel)=upper('Средняя ставка, %') and upper(b.product)=upper('Всего продажи')
        left join #RR c on c.Дата = EOMONTH(@repmonth)


        --------------------Таблица 2--------------------
        --t2p1
        insert into finAnalytics.repSales 
        select
        [repmonth] = @repmonth
        ,l1.tabNum
        ,l1.tabName
        ,l1.pokazatelNum
        ,l1.pokazatel
        ,pAmount = null
        ,l1.fAmount
        ,c.[Доля для RR ПТС]
        from(
        select
        [tabNum] = 2
        ,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
        ,[pokazatelNum] = 1
        ,[pokazatel] = 'Объём выдач онлайн, млн р.'
        ,[pAmount] = 0
        ,[fAmount] = sum(a.dogSum)

        from #PBR a
        where upper(a.saleType) = upper('онлайн')
        ) l1
        --left join finAnalytics.SPR_repSalesPlan b on b.repmonth=EOMONTH(@repmonth) and upper(b.pokazatel)=upper('Объём, руб.') and upper(b.product)=upper('Всего продажи')
        left join #RR c on c.Дата = EOMONTH(@repmonth)

        --t2p2
        insert into finAnalytics.repSales 
        select
        [repmonth] = @repmonth
        ,l1.tabNum
        ,l1.tabName
        ,l1.pokazatelNum
        ,l1.pokazatel
        ,pAmount = null
        ,l1.fAmount
        ,c.[Доля для RR ПТС]
        from(
        select
        [tabNum] = 2
        ,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
        ,[pokazatelNum] = 2
        ,[pokazatel] = 'Объём выдач офлайн, млн р.'
        ,[pAmount] = 0
        ,[fAmount] = sum(a.dogSum)

        from #PBR a
        where upper(a.saleType) = upper('дистанционный')
        ) l1
        --left join finAnalytics.SPR_repSalesPlan b on b.repmonth=EOMONTH(@repmonth) and upper(b.pokazatel)=upper('Объём, руб.') and upper(b.product)=upper('Всего продажи')
        left join #RR c on c.Дата = EOMONTH(@repmonth)

        --t2p3
        insert into finAnalytics.repSales 
        select
        [repmonth] = @repmonth
        ,l1.tabNum
        ,l1.tabName
        ,l1.pokazatelNum
        ,l1.pokazatel
        ,pAmount = Null
        ,l1.fAmount
        ,c.[Доля для RR ПТС]
        from(
        select
        [tabNum] = 2
        ,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
        ,[pokazatelNum] = 3
        ,[pokazatel] = 'Кол-во выдач онлайн, шт.'
        ,[pAmount] = 0
        ,[fAmount] = count(distinct a.dogNum)

        from #PBR a
        where upper(a.saleType) = upper('онлайн')
        ) l1
        --left join finAnalytics.SPR_repSalesPlan b on b.repmonth=EOMONTH(@repmonth) and upper(b.pokazatel)=upper('Количество, шт.') and upper(b.product)=upper('Всего продажи')
        left join #RR c on c.Дата = EOMONTH(@repmonth)

        --t2p4
        insert into finAnalytics.repSales 
        select
        [repmonth] = @repmonth
        ,l1.tabNum
        ,l1.tabName
        ,l1.pokazatelNum
        ,l1.pokazatel
        ,pAmount = Null
        ,l1.fAmount
        ,c.[Доля для RR ПТС]
        from(
        select
        [tabNum] = 2
        ,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
        ,[pokazatelNum] = 4
        ,[pokazatel] = 'Кол-во выдач офлайн, шт.'
        ,[pAmount] = 0
        ,[fAmount] = count(distinct a.dogNum)

        from #PBR a
        where upper(a.saleType) = upper('дистанционный')
        ) l1
        --left join finAnalytics.SPR_repSalesPlan b on b.repmonth=EOMONTH(@repmonth) and upper(b.pokazatel)=upper('Количество, шт.') and upper(b.product)=upper('Всего продажи')
        left join #RR c on c.Дата = EOMONTH(@repmonth)

        
        
    commit tran
    
    /*
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(CalcDATE) from finAnalytics.repPDN ) as varchar)
    

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Расчет месячных данных для отчета по Продажам за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
				--,@sp_name
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
                --,'Максимальная дата остатков: '
                --,@maxDateRest
				)

    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'd.detkin@techmoney.ru' --'a.zherdev@techmoney.ru; d.detkin@techmoney.ru'
			,@copy_recipients = ''--'dwh112@carmoney.ru'
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
    */
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
	
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'd.detkin@techmoney.ru'--'a.zherdev@techmoney.ru; d.detkin@techmoney.ru'
			,@copy_recipients = ''--'dwh112@carmoney.ru'
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    end catch
END




CREATE   PROCEDURE [finAnalytics].[calcAcia0prcRetro]
		@repmonth date
    
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
   begin try

	declare @emailList varchar(255)=''

  begin tran  

  declare @repmonthFrom date = @repmonth
	declare @repmonthTo date = eomonth(@repmonth)

	--Получаем данные Пети о займах
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
	,[checkDouble] int
	)

	INSERT INTO #loans 
	(код,CRMClientGUID,[Дата договора],[Сумма],[Адрес проживания CRM],[Срок],[Агент партнер],[product],[Сумма комиссионных продуктов снижающих ставку],
	[Вид займа],[Дата выдачи],[Сумма расторжений по КП],[ПСК текущая],[ПСК первоначальная],[Текущая процентная ставка],[Первая процентная ставка],[канал]
	,[Признак КП снижающий ставку],[Сумма комиссионных продуктов],[Сумма комиссионных продуктов Carmoney],[Сумма комиссионных продуктов Carmoney Net]
	,[CP_info],[Дата обновления записи по займу],[Дистанционная выдача])

	EXEC Analytics._birs.loans_for_finance @repmonthFrom, @repmonthTo

	merge into #loans t1
	using(
	select
	код
	,[rn] = ROW_NUMBER() over (Partition by код order by код)
	from #loans
	) t2 on (t1.код=t2.код)
	when matched then update
	set t1.[checkDouble] = t2.rn;

	delete from #loans where cast([Дата выдачи] as date) not between @repmonthFrom and @repmonthTo

	--select * from #loans

	--Получаем данные о проводках сработавшей акции
	drop table if exists #prov

	SELECT 

	[Дата операции] = cast(dateadd(year,-2000,a.Период) as date)
	,[СчетДтКод] = Dt.Код
	,[СчетКтКод] = Kt.Код
	,[КлиентКТ] = clkt.Наименование
	,[КлиентКТ_ИНН] = clkt.ИНН
	,[Сумма БУ] = sum(isnull(a.Сумма,0))
	,[СуммаНУ_Дт] = a.СуммаНУДт
	,[СуммаНУ_Кт] = a.СуммаНУКт
	,[СуммаПР_Дт] = a.СуммаПРДт
	,[СуммаПР_Кт] = a.СуммаПРКт
	,[СуммаВР_Дт] = a.СуммаВРДт
	,[СуммаВР_Кт] = a.СуммаВРКт
	,[Содержание] = a.Содержание
	,[НомерМемориальногоОрдера] = a.НомерМемориальногоОрдера
	,[Номер договора КТ] = isnull(crkt.Номер,crdt.Номер)
	,[НоменклатурнаяГруппаКТ] = nomKT.Наименование
	,[Тип операции] = case when Kt.Код ='48802' and Dt.Код = '71001' then 'Сторно'
						   when Kt.Код ='47422' and Dt.Код = '47423' then 'ЧДП'	
						   else '-' end
	into #prov

	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
	left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0
	left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов crdt on a.СубконтоCt2_Ссылка=crdt.Ссылка --and crdt.ПометкаУдаления=0
	left join stg._1cUMFO.Справочник_Контрагенты clkt on a.СубконтоCt1_Ссылка=clkt.Ссылка
	left join stg._1cUMFO.Справочник_НоменклатурныеГруппы nomKT on crkt.АЭ_НоменклатурнаяГруппа=nomkT.Ссылка and nomKT.ПометкаУдаления=0x00
	inner join (
			select a.dogNum
			from dwh2.finAnalytics.pbr_monthly a
			where a.REPMONTH = @repmonth
			and a.saleDate between @repmonth and EOMONTH(@repmonth)
			and upper(a.nomenkGroup) like '%PDL%'
			and upper(a.isAkcia) = 'ДА'
	) pbr on isnull(crkt.Номер,crdt.Номер)=pbr.dogNum
	where 1=1
	and cast(dateadd(year,-2000,a.Период) as date) between @repmonthFrom and dateadd(day,21,@repmonthTo)
	and a.Активность=01
	and (
			((Kt.Код ='48802' and Dt.Код = '71001')
			and upper(a.Содержание)=upper('Сторно ранее начисленных процентов в промо период')
			and upper(nomKT.Наименование) = 'PDL'
			)
			or
			((Kt.Код ='47422' and Dt.Код = '47423')
			and upper(a.Содержание) = upper('Поступление на текущий счет расчетов')
			)
		)
	

	group by
	cast(dateadd(year,-2000,a.Период) as date)
	,Dt.Код
	,Kt.Код
	,clkt.Наименование
	,clkt.ИНН
	,a.СуммаНУДт
	,a.СуммаНУКт
	,a.СуммаПРДт
	,a.СуммаПРКт
	,a.СуммаВРДт
	,a.СуммаВРКт
	,a.Содержание
	,a.НомерМемориальногоОрдера
	,isnull(crkt.Номер,crdt.Номер)
	,nomKT.Наименование

	drop table if exists #rep

	select
	[REPMONTH] = a.[REPMONTH]
	,[Client] = a.[Client]
	,[isZaemshik] = a.[isZaemshik]
	,[isBankrupt] = a.[isBankrupt]
	,[finProd] = a.[finProd]
	,[dogNum] = a.[dogNum]
	,[isAkcia] = a.[isAkcia]
	,[dogDate] = a.[dogDate]
	,[saleDate] = a.[saleDate]
	,[saleType] = a.[saleType]
	,[isRefinance] = a.[isRefinance]
	,[isFirstFromSales] = isnull(b.[Вид займа],'Первичный')
	,[dogSum] = a.dogSum
	,[stavaOnSaleDate] = a.[stavaOnSaleDate]
	,[dogPeriodDays] = a.[dogPeriodDays]
	,[isRestruk_1] = a.[isRestruk]
	,[prosDaysTotal_1] = a.[prosDaysTotal]
	,[dogStatus_1] = a.[dogStatus]
	,[dogEndDate_1] = a.[pogashenieDate]
	,[dogCloseDate_1] = a.[CloseDate]
	,[dogEndDsDate_1] = a.[pogashenieDateDS]
	,[isRestruk_2] = null
	,[prosDaysTotal_2] = null
	,[dogStatus_2] = null
	,[dogEndDate_2] = null 
	,[dogCloseDate_2] = null 
	,[dogEndDsDate_2] =  null 
	,[isAciaResult] = case 
								--Сработала Акция
								when 
								upper(a.[isAkcia]) = 'ДА' 
								and c.[Номер договора КТ] is not null 
								then 'Сработала Акция' 
								
								--Не сработала из-за просрочки
								when 
								upper(a.[isAkcia]) = 'ДА'
								and c.[Номер договора КТ] is null
								and a.pogashenieDate = a.pogashenieDateDS
								and (
								
									(upper(a.dogStatus) = upper('Закрыт')
									and a.[CloseDate] > a.[pogashenieDate])
									or
									(upper(a.dogStatus) = upper('Действует'))
									) 
									then 'Просрочка'
								
								--Не сработала из-за пролонгации
								when 
								upper(a.[isAkcia]) = 'ДА'
								and c.[Номер договора КТ] is null
								and a.pogashenieDate < a.pogashenieDateDS
								then 'Пролонгация'

								--Не сработала из-за быстрого пагашения
								when 
								upper(a.[isAkcia]) = 'ДА' 
								and a.saleDate = a.CloseDate 
								and c.[Номер договора КТ] is null 
								then 'Погашение в день выдачи' 

								--Не в акции
								when 
								upper(a.[isAkcia]) != 'ДА' 
								then 'Не в Акции' 

								--ЧДП
								when 
								upper(a.[isAkcia]) = 'ДА'
								and c1.[Сумма БУ] < a.[dogSum]
								and c1.[Дата операции] < a.pogashenieDate
								and a.isRestruk = 'Нет'
								and a.prosDaysTotal = 0
								then 'ЧДП'

								--Погашение без сторно %%
								when 
								upper(a.[isAkcia]) = 'ДА'
								and c.[Номер договора КТ] is null
								and DATEDIFF(day,a.saleDate,a.CloseDate) between 1 and 5
								then 'Погашение без сторно %%'

								else '-' end

	,[prcStornoSumm] = c.[Сумма БУ]
	into #rep

	from dwh2.finAnalytics.pbr_monthly a
	left join #loans b on a.dogNum=b.код
	left join #prov c on a.dogNum=c.[Номер договора КТ] and c.[Тип операции] = 'Сторно'
	left join (
		select
		[Дата операции]
		,[Номер договора КТ]
		,[Сумма БУ]
		,[rn] = ROW_NUMBER() over (Partition by [Номер договора КТ] order by  [Дата операции])
		from #prov
		where [Тип операции] = 'ЧДП'
			) c1 on a.dogNum=c1.[Номер договора КТ] and c1.rn=1

	where a.REPMONTH = @repmonth
	and a.saleDate between @repmonth and EOMONTH(@repmonth)
	and upper(a.nomenkGroup) like '%PDL%'

	delete from dwh2.[finAnalytics].[PBR_AKCIA0] where REPMONTH = @repmonth

	insert into dwh2.[finAnalytics].[PBR_AKCIA0]
	([REPMONTH], [Client], [isZaemshik], [isBankrupt], [finProd], [dogNum], [isAkcia], [dogDate], [saleDate], [saleType], [isRefinance], [isFirstFromSales], [dogSum], [stavaOnSaleDate], [dogPeriodDays], [isRestruk_1], [prosDaysTotal_1], [dogStatus_1], [dogEndDate_1], [dogCloseDate_1], [dogEndDsDate_1], [isAciaResult], [prcStornoSumm])
	select 
	[REPMONTH]
	, [Client]
	, [isZaemshik]
	, [isBankrupt]
	, [finProd]
	, [dogNum]
	, [isAkcia]
	, [dogDate]
	, [saleDate]
	, [saleType]
	, [isRefinance]
	, [isFirstFromSales]
	, [dogSum]
	, [stavaOnSaleDate]
	, [dogPeriodDays]
	, [isRestruk_1]
	, [prosDaysTotal_1]
	, [dogStatus_1]
	, [dogEndDate_1]
	, [dogCloseDate_1]
	, [dogEndDsDate_1]
	, [isAciaResult]
	, [prcStornoSumm]
	from #rep

   commit tran

	declare @zaym1DayCount int = 0
	declare @zaym1DayList nvarchar(255) = null

	set @zaym1DayCount = 
	(select count(*) from #rep where upper(isAciaResult) in (upper('Погашение без сторно %%')))
    
	set @zaym1DayList =
	(select string_agg([dogNum],' , ') from #rep where upper(isAciaResult) in (upper('Погашение без сторно %%')))

	Declare @zaym1DayString nvarchar(255) = null
	if @zaym1DayCount = 0
	set @zaym1DayString = 'Отсутствуют займы, соответствующие условиям акции, погашенные в течение 5-ти дней от даты выдачи и у которых отсутствует сторнирующая проводка по списанию %% по акции'
	
	if @zaym1DayCount > 0
	set @zaym1DayString = concat(
							'ВНИМАНИЕ!'
							,char(10)
							,char(13)
							,'Обнаружены займы, соответствующие условиям акции, но не попавшие не в одну из категорий!'
							,'Список договоров займа: '
							,@zaym1DayList
							)

	DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from [finAnalytics].[PBR_AKCIA0]) as varchar)

    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Расчет данных для отчета по Акции 0% '
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
                ,'Максимальная дата данных: '
				,@maxDateRest
				,char(10)
                ,char(13)
				,@zaym1DayString
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
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

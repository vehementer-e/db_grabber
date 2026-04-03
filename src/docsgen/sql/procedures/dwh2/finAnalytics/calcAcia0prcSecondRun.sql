

CREATE   PROCEDURE [finAnalytics].[calcAcia0prcSecondRun]
    
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
   begin try

    declare @repmonthtemp date = dateadd(month,-1,(select max(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[PBR_ACIA]))
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
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

	--select * from #prov 

	drop table if exists #rep

	select
	[REPMONTH] = @repmonth
	,[Client] = a.Контрагент
	,[isZaemshik] = a.[Признак заемщика]
	,[isBankrupt] = a.[Банкротство]
	,[finProd] = a.[Финансовый продукт]
	,[dogNum] = a.[Номер договора]
	,[isAkcia] = a.[Акция 0%]
	,[dogDate] = convert(date,a.[Дата договора],104)
	,[saleDate] = convert(date,a.[Дата выдачи],104)
	,[saleType] = a.[Способ выдачи займа]
	,[isRefinance] = a.[Рефинансирование]
	,[isFirstFromSales] = isnull(b.[Вид займа],'Первичный')
	,[dogSum] = a.[Сумма займа]
	,[stavaOnSaleDate] = a.[Ставка на дату выдачи]
	,[dogPeriodDays] = a.[Срок договора в днях]
	,[isRestruk_1] = a.[Реструктуризирован]
	,[prosDaysTotal_1] = a.[Итого дней просрочки общая]
	,[dogStatus_1] = a.[Состояние]
	,[dogEndDate_1] = convert(date,a.[Дата погашения],104)
	,[dogCloseDate_1] = convert(date,a.[Дата закрыт],104)
	,[dogEndDsDate_1] = convert(date,a.[Дата погашения с учетом ДС],104)
	,nomenkGroup = a.[Номенклатурная группа]
	,[isRestruk_2] = null
	,[prosDaysTotal_2] = null
	,[dogStatus_2] = null
	,[dogEndDate_2] = null 
	,[dogCloseDate_2] = null 
	,[dogEndDsDate_2] =  null 
	,[isAciaResult] = case 
								--Сработала Акция
								when 
								upper(a.[Акция 0%]) = 'ДА' 
								and c.[Номер договора КТ] is not null 
								then 'Сработала Акция' 
								
								--Не сработала из-за просрочки
								when 
								upper(a.[Акция 0%]) = 'ДА'
								and c.[Номер договора КТ] is null
								and convert(date,a.[Дата погашения],104) = convert(date,a.[Дата погашения с учетом ДС],104)
								and (
								
									(upper(a.[Состояние]) = upper('Закрыт')
									and convert(date,a.[Дата закрыт],104) > convert(date,a.[Дата погашения],104))
									or
									(upper(a.[Состояние]) = upper('Действует'))
									) 
									then 'Просрочка'
								
								--Не сработала из-за пролонгации
								when 
								upper(a.[Акция 0%]) = 'ДА'
								and c.[Номер договора КТ] is null
								and convert(date,a.[Дата погашения],104) < convert(date,a.[Дата погашения с учетом ДС],104)
								then 'Пролонгация'

								--Не сработала из-за быстрого пагашения
								when 
								upper(a.[Акция 0%]) = 'ДА' 
								and convert(date,a.[Дата выдачи],104) = convert(date,a.[Дата закрыт],104)
								and c.[Номер договора КТ] is null 
								then 'Погашение в день выдачи' 

								--Не в акции
								when 
								upper(a.[Акция 0%]) != 'ДА' 
								then 'Не в Акции' 

								--ЧДП
								when 
								upper(a.[Акция 0%]) = 'ДА'
								 and c1.[Сумма БУ] < a.[Сумма займа]
								and c1.[Дата операции] < convert(date,a.[Дата погашения],104)
								and a.[Реструктуризирован] = 'Нет'
								and a.[Итого дней просрочки общая] = 0
								then 'ЧДП'

								--Погашение без сторно %%
								when 
								upper(a.[Акция 0%]) = 'ДА'
								and c.[Номер договора КТ] is null
								and DATEDIFF(day,convert(date,a.[Дата выдачи],104),convert(date,a.[Дата закрыт],104)) between 1 and 5
								then 'Погашение без сторно %%'

								else '-' end

	,[prcStornoSumm] = c.[Сумма БУ]
	into #rep

	from stg.[files].[PBR_ACIA] a -- select * from stg.[files].[PBR_ACIA]
	left join #loans b on a.[Номер договора]=b.код
	left join #prov c on a.[Номер договора]=c.[Номер договора КТ] and c.[Тип операции] = 'Сторно'
	left join (
		select
		[Дата операции]
		,[Номер договора КТ]
		,[Сумма БУ]
		,[rn] = ROW_NUMBER() over (Partition by [Номер договора КТ] order by  [Дата операции])
		from #prov
		where [Тип операции] = 'ЧДП'
			) c1 on a.[Номер договора]=c1.[Номер договора КТ] and c1.rn=1

	where 1=1--a.REPMONTH = @repmonth
	and convert(date,a.[Дата выдачи],104) between @repmonth and EOMONTH(@repmonth)
	and upper(a.[Номенклатурная группа]) like '%PDL%'
	--and upper(a.isAkcia) = 'ДА'

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

	

	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID] in (34)
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')
	
	DECLARE @repLink varchar (300) = CONCAT(
											'Ссылка на отчет:'
											,(SELECT [link] FROM [dwh2].[finAnalytics].[SYS_SPR_linkReport] where upper(repName) = upper('Отчет по Акции 0 процентов'))
											)
    
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
				,char(10)
                ,char(13)
				,@repLink
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
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

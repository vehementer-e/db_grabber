

-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-04-10
-- Description:	 Третья часть. Сохраненый баланс витрина
--             exec [dbo].[ReportDashboard_Collection_v02_part3]   --1
-- =============================================
CREATE PROC [dbo].[ReportDashboard_Collection_v02_part3]
	
	-- Add the parameters for the stored procedure here
	@DateCalculate date
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- part 3


----- найдем договора, которые ушли и вернулись из просрочки в течении дня
--declare  @DateCalculate date = cast(dateadd(day,0, dateadd(year,2000,getdate())) as date)
declare  @dt_begin_of_month date = cast(format(@DateCalculate,'yyyyMM01') as date)
declare  @dt_next_month date = cast(dateadd(month,1, @dt_begin_of_month) as date)

declare @firstday date = dateadd(year,-2000,@dt_begin_of_month)

--- найдем договора, которые ушли и вернулись из просрочки в течении дня
declare  @dt_today_away2000 date = cast(dateadd(day,0, dateadd(year,-2000,@DateCalculate)) as date)
declare  @dt_begin_of_month2000 date = cast(format(@dt_today_away2000,'yyyyMM01') as date)
declare  @dt_next_month2000 date = cast(dateadd(month,1, @dt_begin_of_month2000) as date)

--- для сторонних дашбоардов
delete from [dbo].[dm_CollectionSavedBalance]
where Период = Format(dateadd(year,-2000,@dt_begin_of_month),'yyyy-MM')

--dateadd(year,2000,[Дата входа в стадию]) >= @dt_begin_of_month and [Дата входа в стадию]<dateadd(day,1,@dt_begin_of_month )
----


--- получим баланс по всем договорам 
  if object_id('tempdb.dbo.#balance_30plus2') is not null drop table #balance_30plus2
select external_id, d, [остаток од], dpd, [dpd day-1] 

, [BucketEnd]=
					case when dpd > 0   and dpd <= 30  --and tmax_dpd.max_dpd <= 90 
							then 1
								when dpd >= 31  and dpd <= 60 -- and tmax_dpd.max_dpd <= 90 
							then 2
								when dpd >= 61  and dpd <= 90  --and tmax_dpd.max_dpd <= 90 
							then 3
								when dpd >= 91  and dpd <= 360                   
							then 4
								when dpd >= 360                                    
							then 5
							when dpd = 0
							then 0
							else null 
					end
		, [BucketBegin]=
	case when [dpd day-1]  > 0   and [dpd day-1]  <= 30  --and tmax_[dpd day-1] .max_[dpd day-1]  <= 90 
			then 1
				when [dpd day-1]  >= 31  and [dpd day-1]  <= 60 -- and tmax_[dpd day-1] .max_[dpd day-1]  <= 90 
			then 2
				when [dpd day-1]  >= 61  and [dpd day-1]  <= 90  --and tmax_[dpd day-1] .max_[dpd day-1]  <= 90 
			then 3
				when [dpd day-1]  >= 91  and [dpd day-1]  <= 360                   
			then 4
				when [dpd day-1]  >= 360                                    
			then 5
			when [dpd day-1]  = 0
			then 0
			else null 
    end
	into #balance_30plus2
from dwh2.[dbo].dm_CMRStatBalance b 
where b.d >= dateadd(day,-31,@dt_begin_of_month2000 ) and b.d < @dt_next_month2000
and b.[Тип Продукта] = 'ПТС'

--select * 
--from #balance_30plus2 
--where ([BucketEnd] > [BucketBegin] or [BucketEnd] < [BucketBegin]) and-- dpd>1 and
--external_id='18110390000001'
--order by d 


-- оставим только те балансы, которые имеют переход в бакетах 
  if object_id('tempdb.dbo.#balance_30plus3') is not null drop table #balance_30plus3
select * 
into #balance_30plus3
from #balance_30plus2 
where ([BucketEnd] > [BucketBegin] or [BucketEnd] < [BucketBegin])  --and dpd>1
order by d 

------------------------------
--- список договоров ---------
------------------------------
	if object_id('tempdb.dbo.#deals') is not null drop table #deals

	select    d.Код as external_id , d.ссылка 
	into #deals
	--select count(*)
	from  stg._1cCMR.Справочник_Договоры d (nolock)
	inner join [Stg].[_1cCMR].[Справочник_типыПродуктов] cmr_ТипыПродуктов
			on d.ТипПродукта = cmr_ТипыПродуктов.ссылка	
	where lower(cmr_ТипыПродуктов.ИдентификаторMDS) = 'pts'
	--lower(cmr_ТипыПродуктов.ИдентификаторMDS)
	-- основной отбор договоров, у которых есть переход в течение дня в выбранном месяце
	--
  if object_id('tempdb.dbo.#ap_new_baket') is not null drop table #ap_new_baket

  /*
  --var 1
  select 
	  dateadd(year,-2000, cast(ap.Период as date)) период
	, max(ap.КоличествоПолныхДнейПросрочкиУМФО) mmax
	, min(ap.КоличествоПолныхДнейПросрочкиУМФО)  mmin
	, dpdDateMin= min(ap.ДатаВозникновенияПросрочкиУМФО)
	, dpdDateMax= max(ap.ДатаВозникновенияПросрочкиУМФО)
	, external_id=de.external_id
	, dateadd(year,-2000, max(ap.Период) ) ДатаВремяОплатыПоследняяПериод
	into #ap_new_baket
   from  [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] ap 
   join #deals de on de.ссылка=ap.договор 
  where   ap.Период >= dateadd(day,0,@dt_begin_of_month ) and ap.Период < @dt_next_month
  group by cast(ap.Период as date), de.external_id 
  having max(ap.КоличествоПолныхДнейПросрочкиУМФО)<>min(ap.КоличествоПолныхДнейПросрочкиУМФО)
  --and ap.КоличествоПолныхДнейПросрочкиУМФО in (1,31,61,91,361)
  */

	--var 2
	select 
		--dateadd(year,-2000, cast(ap.Период as date)) период
		B.Период as период

		--, max(ap.КоличествоПолныхДнейПросрочкиУМФО) mmax
		, B.dpd_begin_day AS mmax

		--, min(ap.КоличествоПолныхДнейПросрочкиУМФО)  mmin
		, B.dpd AS mmin

		--, dpdDateMin= min(ap.ДатаВозникновенияПросрочкиУМФО)
		--, dpdDateMin = dateadd(year, 2000, S.ДатаВозникновенияПросрочкиУМФО)
		, dpdDateMin = 	iif(isnull(B.dpdMFO,0) = 0, '2001-01-01', dateadd(YEAR, 2000, dateadd(DAY, -B.dpdMFO, B.d)))


		--, dpdDateMax= max(ap.ДатаВозникновенияПросрочкиУМФО)
		--, dpdDateMax = dateadd(year, 2000, S.ДатаВозникновенияПросрочкиУМФО)
		, dpdDateMax = iif(isnull(B.dpdMFO,0) = 0, '2001-01-01', dateadd(YEAR, 2000, dateadd(DAY, -B.dpdMFO, B.d)))


		, external_id = B.external_id

		--, dateadd(year,-2000, max(ap.Период) ) ДатаВремяОплатыПоследняяПериод
		, B.Период AS ДатаВремяОплатыПоследняяПериод
	into #ap_new_baket
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
		INNER JOIN Stg._1cCMR.Справочник_Договоры AS D (nolock)
			ON D.Код = B.external_id
		INNER JOIN #deals AS de
			ON de.ссылка = D.Ссылка
		--OUTER APPLY (
		--	SELECT ДатаВозникновенияПросрочкиУМФО = max(F.d)
		--	FROM dwh2.dbo.dm_CMRStatBalance AS F (NOLOCK)
		--	WHERE 1=1
		--		AND F.external_id = B.external_id
		--		and F.d < B.d
		--		AND F.dpdMFO = 0
		--	) AS S
	--where ap.Период >= dateadd(day,0,@dt_begin_of_month ) and ap.Период < @dt_next_month
	--group by B.Период, B.external_id
	--having max(ap.КоличествоПолныхДнейПросрочкиУМФО)<>min(ap.КоличествоПолныхДнейПросрочкиУМФО)
	WHERE B.Период >= dateadd(YEAR, -2000, @dt_begin_of_month) and B.Период < dateadd(YEAR, -2000, @dt_next_month)
		AND isnull(B.dpd_begin_day, 0) <> isnull(B.dpd, 0)



  -- найдем бакет и его номер для последующего сравнения
 if object_id('tempdb.dbo.#ap_new_baket2') is not null drop table #ap_new_baket2
SELECT 
	  ap.*
	, rn=row_number() over (partition by ap.external_id order by ap.Период)
	, dateadd(year,-2000,cast(iif(ap.dpdDateMin = '2001-01-01',ap.dpdDateMax,ap.dpdDateMin) as date)) ДатаВходаВПросрочку
	, ap.период ДатаСниженияПросрочки
	, [BucketFirst]=
					case when ap.mmax > 0   and ap.mmax <= 30  --and tmax_mmax.max_mmax <= 90 
							then '(1)_1_30'
								when ap.mmax >= 31  and ap.mmax <= 60 -- and tmax_mmax.max_mmax <= 90 
							then '(2)_31_60'
								when ap.mmax >= 61  and ap.mmax <= 90  --and tmax_mmax.max_mmax <= 90 
							then '(3)_61_90'
								when ap.mmax >= 91  and ap.mmax <= 360                   
							then '(4)_91_360'
								when ap.mmax >= 360                                    
							then '(5)_361+'
							when ap.mmax = 0
							then 'PreDel'
							else '(7)_Other' 
					end
		, [BucketLast]=
					case when ap.mmin > 0   and ap.mmin <= 30  --and tmax_mmin.max_mmin <= 90 
							then '(1)_1_30'
								when ap.mmin >= 31  and ap.mmin <= 60 -- and tmax_mmin.max_mmin <= 90 
							then '(2)_31_60'
								when ap.mmin >= 61  and ap.mmin <= 90  --and tmax_mmin.max_mmin <= 90 
							then '(3)_61_90'
								when ap.mmin >= 91  and ap.mmin <= 360                   
							then '(4)_91_360'
								when ap.mmin >= 360                                    
							then '(5)_361+'
							when ap.mmin = 0
							then 'PreDel'
							else '(7)_Other' 
					end
	, [BucketFirstNumber]=
					case when ap.mmax > 0   and ap.mmax <= 30  --and tmax_mmax.max_mmax <= 90 
							then 1
								when ap.mmax >= 31  and ap.mmax <= 60 -- and tmax_mmax.max_mmax <= 90 
							then 2
								when ap.mmax >= 61  and ap.mmax <= 90  --and tmax_mmax.max_mmax <= 90 
							then 3
								when ap.mmax >= 91  and ap.mmax <= 360                   
							then 4
								when ap.mmax >= 360                                    
							then 5
							when ap.mmax = 0
							then 0
							else null 
					end
		, [BucketLastNumber]=
	case when ap.mmin > 0   and ap.mmin <= 30  --and tmax_mmin.max_mmin <= 90 
			then 1
				when ap.mmin >= 31  and ap.mmin <= 60 -- and tmax_mmin.max_mmin <= 90 
			then 2
				when ap.mmin >= 61  and ap.mmin <= 90  --and tmax_mmin.max_mmin <= 90 
			then 3
				when ap.mmin >= 91  and ap.mmin <= 360                   
			then 4
				when ap.mmin >= 360                                    
			then 5
			when ap.mmin = 0
			then 0
			else null 
    end
into #ap_new_baket2
FROM #ap_new_baket ap
--left join [dbo].[dm_CMRStatBalance_2] b on ap.external_id = b.external_id and b.d = ap.период
--where  b.dpd<b.[dpd day-1] and 
--b.d='2020-04-16'

---
-- само сравнение 
-- отбираем только те, у которых есть переход с бакета на бакет
-- добавим данные по балансу, если был переход по основной таблице баланса
---

if object_id('tempdb.dbo.#current_1') is not null drop table #current_1
select a1.*, a2.d, a2.[остаток од]
, rn2=ROW_NUMBER() over(partition by a1.external_id, ДатаСниженияПросрочки order by d desc)
into #current_1
from #ap_new_baket2 a1
--left join #balance_30plus3 a2 on a1.external_id=a2.external_id and a1.ДатаСниженияПросрочки>a2.d
left join #balance_30plus3 a2 on a1.external_id=a2.external_id and cast(a1.ДатаСниженияПросрочки as date) = cast(a2.d as date)
where 
a1.BucketFirstNumber>a1.BucketLastNumber

--select * from #current_1 where -- rn2=1
--external_id='18110390000001'

--select ap.*, b.d, b.[остаток од], dateadd(day,-1,ДатаВходаВПросрочку) from #ap_new_baket2 ap
--left join [dbo].[dm_CMRStatBalance_2] b on ap.external_id = b.external_id and b.d = dateadd(day,-1,ДатаВходаВПросрочку)
--where ap.external_id='18110390000001'

-- найдем даты перехода 30->31, 60->61, 90->91, 360->361

--- вывод данных
-- но должны учесть переход с бакета на бакет в течение дня также
-- если есть переход через баланс - берем его день
-- Если не выше, но есть дата просрочки больше первого дня месяца, то пишем её
-- иначе пишем первый день месяца
if object_id('tempdb.dbo.#current_day_balance_away') is not null drop table #current_day_balance_away

--select distinct iif(isnull(ap.d,@firstday)<@firstday, @firstday, isnull(ap.d,@firstday) )[Дата входа в стадию]
select distinct iif(isnull(ap.d,ap.ДатаВходаВПросрочку)<@firstday, @firstday, isnull(ap.d,ДатаВходаВПросрочку) )[Дата входа в стадию]
      ,BucketFirst [Корзина Просрочки]
      ,ДатаСниженияПросрочки [Дата выхода из стадии]
      ,BucketLast [Корзина Возвращения]
      ,ap.external_id [Номер договора]
      ,mmax [Дней просрочки]
      ,isnull( b.[остаток од],ap.[остаток од]) [ОД]
	 -- , iif( balance_change_bucket.d<ДатаСниженияПросрочки, balance_change_bucket.d, NULL) НоваяДатаВходаВПросрочку
	 -- , balance_change_bucket.*
      , rn [повторная стадия в течение месяца]
	  , Format(dateadd(year,-2000,@dt_begin_of_month),'yyyy-MM') Период
	  , ap.ДатаВремяОплатыПоследняяПериод ДатаОплаты
	 -- , ap.d, @firstday
	  --,iif(ap.d<@firstday,1,0) aa
	  --,ДатаВходаВПросрочку
	  --,@firstday
	  --,balance_change_bucket.d
	  --, b.*
	  , BucketFirstNumber
	  , BucketLastNumber
	  , iif(ap.d is null, 0,1) as IsDataCMR
into #current_day_balance_away
from #current_1 ap
--left join [dbo].[dm_CMRStatBalance_2] b on ap.external_id = b.external_id and b.d = dateadd(day,-1,iif(isnull(ap.d,@firstday)<@firstday, @firstday, isnull(ap.d,@firstday) ))
left join [dbo].[dm_CMRStatBalance_2] b on ap.external_id = b.external_id and b.d = dateadd(day,-1,iif(isnull(ap.d,ap.ДатаВходаВПросрочку)<@firstday, @firstday, isnull(ap.d, dateadd(day,1,ДатаВходаВПросрочку)) ))
--left join #balance_30plus3 balance_change_bucket on balance_change_bucket.external_id = ap.external_id
where --ap.external_id='18110390000001' and
ap.BucketFirstNumber>ap.BucketLastNumber
and rn2=1

 --- 28.04.2020 добавим приведенный баланс
-- По алгоритму перехода от сохраненного баланса к приведенному:
--1. Для переходов 1-30 -> 0, 31-60 -> 0, 61-90 - > 0: приведенный баланс (ПБ) = сохраненный баланс (СБ)
--2. Для перехода 31-60 –> 1-30: ПБ = (7%-1,5%)/7%*СБ
--3. Для перехода 61-90 -> 1-30: ПБ = (15%-1,5%)/15%*СБ
--4. Для перехода 61-90 -> 31-60: ПБ = (15%-7%)/15%*СБ

-- 19_05_2020 - оставим только данные из CMR stat balance и данные за сегодня (с учетом перехода 1-0)
 ----- для сторонних дашбоардов
 insert into [dbo].[dm_CollectionSavedBalance]
 ([Дата входа в стадию]
      ,[Корзина Просрочки]
      ,[Дата выхода из стадии]
      ,[Корзина Возвращения]
      ,[Номер договора]
      ,[Дней просрочки]
      ,[ОД]
      ,[повторная стадия в течение месяца]
	  ,Период
	  ,ДатаОплаты
	, СохрБалансПриведен)
 select  [Дата входа в стадию]
      ,[Корзина Просрочки]
      ,[Дата выхода из стадии]
      ,[Корзина Возвращения]
      ,[Номер договора]
      ,[Дней просрочки]
      ,[ОД]
      ,[повторная стадия в течение месяца]
	  , Format(dateadd(year,-2000,@dt_begin_of_month),'yyyy-MM') Период
	  ,ДатаОплаты
	  , СохрБалансПриведен = case 
			when BucketLastNumber = 0 then
						case 
						    when BucketFirstNumber = 1 then ОД
							when BucketFirstNumber = 2 then ОД
							when BucketFirstNumber = 3 then ОД
							else 0 --ОД
						end
			when BucketLastNumber = 1 then 
						case 
							when BucketFirstNumber = 2 then ОД*((7.0-1.5)/7.0)
							when BucketFirstNumber = 3 then ОД*((15.0-1.5)/15.0)
							else 0 --ОД
						end
			when BucketLastNumber = 2 then 
						case 							
							when BucketFirstNumber = 3 then ОД*((15.0-7.0)/15.0)
							else 0 --ОД
						end
			else 0 --ОД
			end
--into [dbo].[dm_CollectionSavedBalance_test_2020_05_19]
 from #current_day_balance_away
 where IsDataCMR = 1 or (IsDataCMR = 0 and BucketLastNumber <> 0)
 union all
  select  [Дата входа в стадию]
      ,[Корзина Просрочки]
      ,[Дата выхода из стадии]
      ,[Корзина Возвращения]
      ,[Номер договора]
      ,[Дней просрочки]
      ,[ОД]
      ,[повторная стадия в течение месяца]
	  , Format(dateadd(year,-2000,@dt_begin_of_month),'yyyy-MM') Период
	  ,ДатаОплаты
	  , СохрБалансПриведен = case 
			when BucketLastNumber = 0 then
						case 
						    when BucketFirstNumber = 1 then ОД
							when BucketFirstNumber = 2 then ОД
							when BucketFirstNumber = 3 then ОД
							else 0 --ОД
						end
			when BucketLastNumber = 1 then 
						case 
							when BucketFirstNumber = 2 then ОД*((7.0-1.5)/7.0)
							when BucketFirstNumber = 3 then ОД*((15.0-1.5)/15.0)
							else 0 --ОД
						end
			when BucketLastNumber = 2 then 
						case 							
							when BucketFirstNumber = 3 then ОД*((15.0-7.0)/15.0)
							else 0 --ОД
						end
			else 0 --ОД
			end
--into [dbo].[dm_CollectionSavedBalance_test_2020_05_19]
 from #current_day_balance_away
 where IsDataCMR = 0 and BucketLastNumber = 0 and cast([Дата выхода из стадии] as date) = cast(Getdate() as date)
 

 Declare @currentDate datetime = GetDAte()

  insert into [dbo].[dm_CollectionSavedBalance_Monitoring]
 ([Тип таблицы],
 [Время записи],
 [Дата входа в стадию]
      ,[Корзина Просрочки]
      ,[Дата выхода из стадии]
      ,[Корзина Возвращения]
      ,[Номер договора]
      ,[Дней просрочки]
      ,[ОД]
      ,[повторная стадия в течение месяца]
	  ,Период
	  ,ДатаОплаты
	, СохрБалансПриведен)
 select  
 0 as [Тип таблицы],
@currentDate as [Время записи]
 ,[Дата входа в стадию]
      ,[Корзина Просрочки]
      ,[Дата выхода из стадии]
      ,[Корзина Возвращения]
      ,[Номер договора]
      ,[Дней просрочки]
      ,[ОД]
      ,[повторная стадия в течение месяца]
	  , Format(dateadd(year,-2000,@dt_begin_of_month),'yyyy-MM') Период
	  ,ДатаОплаты
	  , СохрБалансПриведен = case 
			when BucketLastNumber = 0 then
						case 
						    when BucketFirstNumber = 1 then ОД
							when BucketFirstNumber = 2 then ОД
							when BucketFirstNumber = 3 then ОД
							else 0 --ОД
						end
			when BucketLastNumber = 1 then 
						case 
							when BucketFirstNumber = 2 then ОД*((7.0-1.5)/7.0)
							when BucketFirstNumber = 3 then ОД*((15.0-1.5)/15.0)
							else 0 --ОД
						end
			when BucketLastNumber = 2 then 
						case 							
							when BucketFirstNumber = 3 then ОД*((15.0-7.0)/15.0)
							else 0 --ОД
						end
			else 0 --ОД
			end
--into [dbo].[dm_CollectionSavedBalance_test_2020_05_19]
 from #current_day_balance_away
 where IsDataCMR = 1 or (IsDataCMR = 0 and BucketLastNumber <> 0)
 union all
  select   1 as [Тип таблицы],
@currentDate as [Время записи]
 ,[Дата входа в стадию]
      ,[Корзина Просрочки]
      ,[Дата выхода из стадии]
      ,[Корзина Возвращения]
      ,[Номер договора]
      ,[Дней просрочки]
      ,[ОД]
      ,[повторная стадия в течение месяца]
	  , Format(dateadd(year,-2000,@dt_begin_of_month),'yyyy-MM') Период
	  ,ДатаОплаты
	  , СохрБалансПриведен = case 
			when BucketLastNumber = 0 then
						case 
						    when BucketFirstNumber = 1 then ОД
							when BucketFirstNumber = 2 then ОД
							when BucketFirstNumber = 3 then ОД
							else 0 --ОД
						end
			when BucketLastNumber = 1 then 
						case 
							when BucketFirstNumber = 2 then ОД*((7.0-1.5)/7.0)
							when BucketFirstNumber = 3 then ОД*((15.0-1.5)/15.0)
							else 0 --ОД
						end
			when BucketLastNumber = 2 then 
						case 							
							when BucketFirstNumber = 3 then ОД*((15.0-7.0)/15.0)
							else 0 --ОД
						end
			else 0 --ОД
			end
--into [dbo].[dm_CollectionSavedBalance_test_2020_05_19]
 from #current_day_balance_away
 where IsDataCMR = 0 and BucketLastNumber = 0 and cast([Дата выхода из стадии] as date) = cast(Getdate() as date)

END

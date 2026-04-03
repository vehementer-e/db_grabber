
create   proc  [dbo].[Агрегирование оперативной статистики по каналам_backup_2022-11-08]
as
begin


set datefirst 1;
set language russian;
--declare @report_date date = '20220302'
declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
declare @report_week date = cast(DATEADD(DD, 1 - DATEPART(DW, @report_date ), @report_date ) as date)
declare @report_yesterday date = dateadd(day, -1, @report_date)
declare @report_month date = cast(format(@report_date   , 'yyyy-MM-01') as date)
declare @report_last_month date = dateadd(month, -1, cast(format(@report_date   , 'yyyy-MM-01') as date))
declare @report_quarter date = cast(DATEADD(qq, DATEDIFF(qq, 0, @report_date), 0) as date)


drop table if exists #chpl
drop table if exists #tmp_plans
drop table if exists #r
;



with cpl as (

select cast(format(Дата, 'yyyy-MM-01') as date) Месяц, cast(Дата as date) Дата
, [Займы руб]
, [Займы руб]/(sum([Займы руб]) over(partition by cast(format(Дата, 'yyyy-MM-01') as date))+0.0) [weight of day] 
from stg.files.contactcenterplans_buffer_stg a 


)


select cpl.Месяц
, cpl.Дата
, case when b.[Группа каналов]='cpa' then b.[Канал от источника] else b.[Группа каналов] end [Канал]
, b.[Канал от источника]
, b.[Тип продукта]
, [Выданная сумма]*[weight of day] [Выданная сумма]
, case when Дата=@report_date then 1 else 0 end as Today
, case when Дата=@report_yesterday then 1 else 0 end as Yesterday
, case when cast(DATEADD(DD, 1 - DATEPART(DW, Дата ), Дата ) as date) = @report_week then 1 else 0 end as Week
, case when cast(format(Дата   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
, case when cast(format(Дата   , 'yyyy-MM-01') as date)  = @report_last_month then 1 else 0 end as  LastMonth
, case when cast(format(Дата   , 'yyyy-MM-01') as date)  = @report_month and Дата<=@report_yesterday then 1 else 0 end as  [month but today]
into #chpl
from cpl 

join 

stg.files.[план по каналам_stg] b on cpl.Месяц=b.Месяц


--select * from #chpl


;



	
with plans as (
  select * from (
  SELECT 
       [День]
      ,[Месяц]
      ,[Год]
      ,[Неделя]
      ,[Квартал]
      ,[Сумма] [Сумма]
      ,[Сумма инстоллмент] [Сумма инстоллмент]
	  ,[Сумма Бизнес инвест] [Сумма Бизнес инвест]
    , case when [День]=@report_date then 1 else 0 end as Today
	, case when [День]=@report_yesterday then 1 else 0 end as Yesterday
	, case when cast(DATEADD(DD, 1 - DATEPART(DW, [День] ), [День] ) as date) = @report_week then 1 else 0 end as Week
	, case when cast(format([День]   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
	, case when cast(format([День]   , 'yyyy-MM-01') as date)  = @report_last_month then 1 else 0 end as  LastMonth
	, case when cast(format([День]   , 'yyyy-MM-01') as date)  = @report_month and [День]<=@report_yesterday then 1 else 0 end as  [month but today]

	, case when cast(DATEADD(qq, DATEDIFF(qq, 0, [День]), 0) as date)  = @report_quarter then 1 else 0 end as  Quarter
	from v_plans

  )pl
   where 1=1  
)
select * into #tmp_plans from plans

;

with t1 as (
    SELECT [ДатаВыдачи]
    ,Код
	, case when ДатаВыдачи=@report_date then 1 else 0 end as Today
	, case when ДатаВыдачи=@report_yesterday then 1 else 0 end as Yesterday
	, case when cast(DATEADD(DD, 1 - DATEPART(DW, ДатаВыдачи ), ДатаВыдачи ) as date) = @report_week then 1 else 0 end as Week
	, case when cast(format(ДатаВыдачи   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
	, case when cast(format(ДатаВыдачи   , 'yyyy-MM-01') as date)  = @report_last_month then 1 else 0 end as  LastMonth
	, case when cast(format(ДатаВыдачи   , 'yyyy-MM-01') as date)  = @report_month and ДатаВыдачи<=@report_yesterday then 1 else 0 end as  [month but today]
	, case when cast(DATEADD(qq, DATEDIFF(qq, 0, ДатаВыдачи), 0) as date)  = @report_quarter then 1 else 0 end as  Quarter
	,cast([Сумма] as bigint)  [Сумма]
	,СтавкаНаСумму

  --  ,СпособОформления
    ,Канал
	,case when IsInstallment=1 then 'Инстоллмент'
	      else  'ПТС'
	end
	
	product
      FROM [оперативная витрина с выдачами и каналами] --with(nolock)
--where ishistory=0
union all
    SELECT [Дата выдачи]
    ,Номер
	, case when [Дата выдачи]=@report_date then 1 else 0 end as Today
	, case when [Дата выдачи]=@report_yesterday then 1 else 0 end as Yesterday
	, case when cast(DATEADD(DD, 1 - DATEPART(DW, [Дата выдачи] ), [Дата выдачи] ) as date) = @report_week then 1 else 0 end as Week
	, case when cast(format([Дата выдачи]   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
	, case when cast(format([Дата выдачи]   , 'yyyy-MM-01') as date)  = @report_last_month then 1 else 0 end as  LastMonth
	, case when cast(format([Дата выдачи]   , 'yyyy-MM-01') as date)  = @report_month and [Дата выдачи]<=@report_yesterday then 1 else 0 end as  [month but today]
	, case when cast(DATEADD(qq, DATEDIFF(qq, 0, [Дата выдачи]), 0) as date)  = @report_quarter then 1 else 0 end as  Quarter
	,cast([Выданная сумма] as bigint)  [Сумма]
	, СтавкаНаСумму
   -- ,null СпособОформления
    ,null Канал
	,'Бизнес инвест' product

      FROM [Analytics].[dbo].[Бизнес инвест] --with(nolock)




	  )
	  ,
	  nums as (

	  select 'today' p, product ,Канал     ,   sum(Сумма) Сумма, count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where today=1 group by  product ,Канал     union all
	  select 'today' , product ,'Всего'    , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where today=1 group by  product            union all
	  select 'Yesterday' , product ,Канал  , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Yesterday=1 group by  product ,Канал union all
	  select 'Yesterday' , product ,'Всего', sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Yesterday=1 group by  product         union all
	  select 'Week' , product ,Канал       , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Week=1 group by  product ,Канал       union all
	  select 'Week' , product ,'Всего'     , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Week=1 group by  product  union all
	  select 'LastMonth' , product ,Канал       , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where LastMonth=1 group by  product ,Канал       union all
	  select 'LastMonth' , product ,'Всего'     , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where LastMonth=1 group by  product  union all
	  select 'Month' , product ,Канал      , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, sum(case when [month but today]=1 then Сумма end) СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Month=1 group by  product ,Канал union all
	  select 'Month' , product ,'Всего'    , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, sum(case when [month but today]=1 then Сумма end) СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Month=1 group by  product  union all
	  select 'Quarter' , product ,Канал    , sum(Сумма) Сумма  , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Quarter=1 group by  product ,Канал union all
	  select 'Quarter' , product ,'Всего' , sum(Сумма) Сумма   , count(*) Количество, avg(Сумма) Чек, null                                              СуммаRR, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка from t1 a where Quarter=1 group by  product  --union all
	  )
	  ,
	  rr as 
	  (
	  select 'Month' p, [Тип продукта],         [Канал], sum([Выданная сумма]) [Выданная сумма], sum(case when [month but today]=1 then [Выданная сумма] end ) [Выданная сумма план по вчера] from #chpl where Month=1 group by [Тип продукта], [Канал] union all
	  select 'Month' p, [Тип продукта], 'Всего' [Канал], sum([Выданная сумма]) [Выданная сумма], sum(case when [month but today]=1 then [Выданная сумма] end ) [Выданная сумма план по вчера] from #chpl where Month=1 group by [Тип продукта] --union all

	  ),
	  
	  plans as 
	  (
	  select 'today' p, 'ПТС' [Тип продукта],  'Всего'       [Канал], sum([Сумма])      [Сумма] from #tmp_plans where today=1 union all
	  select 'yesterday' p, 'ПТС' [Тип продукта],  'Всего'       [Канал], sum([Сумма])  [Сумма] from #tmp_plans where yesterday=1 union all
	  select 'week' p, 'ПТС' [Тип продукта],  'Всего'       [Канал], sum([Сумма])       [Сумма] from #tmp_plans where week=1 union all
	  select 'month' p, 'ПТС' [Тип продукта],  'Всего'       [Канал], sum([Сумма])      [Сумма] from #tmp_plans where month=1 union all
	  select 'LastMonth' p, 'ПТС' [Тип продукта],  'Всего'       [Канал], sum([Сумма])      [Сумма] from #tmp_plans where LastMonth=1 union all
	  select 'Quarter' p, 'ПТС' [Тип продукта],  'Всего'       [Канал], sum([Сумма])    [Сумма] from #tmp_plans where Quarter=1 union all

	  select 'today' p, 'инстоллмент' [Тип продукта]    ,  'Всего'       [Канал], sum([Сумма инстоллмент])      [Сумма] from #tmp_plans where today=1 union all
	  select 'yesterday' p, 'инстоллмент' [Тип продукта],  'Всего'       [Канал], sum([Сумма инстоллмент])  [Сумма] from #tmp_plans where yesterday=1 union all
	  select 'week' p, 'инстоллмент' [Тип продукта],  'Всего'       [Канал], sum([Сумма инстоллмент])       [Сумма] from #tmp_plans where week=1 union all
	  select 'month' p, 'инстоллмент' [Тип продукта],  'Всего'       [Канал], sum([Сумма инстоллмент])      [Сумма] from #tmp_plans where month=1 union all
	  select 'LastMonth' p, 'инстоллмент' [Тип продукта],  'Всего'       [Канал], sum([Сумма инстоллмент])      [Сумма] from #tmp_plans where LastMonth=1 union all
	  select 'Quarter' p, 'инстоллмент' [Тип продукта],  'Всего'       [Канал], sum([Сумма инстоллмент])    [Сумма] from #tmp_plans where Quarter=1 union all

	  select 'today' p, 'Бизнес инвест' [Тип продукта],  'Всего'       [Канал], sum([Сумма Бизнес инвест])      [Сумма] from #tmp_plans where today=1 union all
	  select 'yesterday' p, 'Бизнес инвест' [Тип продукта],  'Всего'       [Канал], sum([Сумма Бизнес инвест])  [Сумма] from #tmp_plans where yesterday=1 union all
	  select 'week' p, 'Бизнес инвест' [Тип продукта],  'Всего'       [Канал], sum([Сумма Бизнес инвест])       [Сумма] from #tmp_plans where week=1 union all
	  select 'month' p, 'Бизнес инвест' [Тип продукта],  'Всего'       [Канал], sum([Сумма Бизнес инвест])      [Сумма] from #tmp_plans where month=1 union all
	  select 'LastMonth' p, 'Бизнес инвест' [Тип продукта],  'Всего'       [Канал], sum([Сумма Бизнес инвест])      [Сумма] from #tmp_plans where LastMonth=1 union all
	  select 'Quarter' p, 'Бизнес инвест' [Тип продукта],  'Всего'       [Канал], sum([Сумма Бизнес инвест])    [Сумма] from #tmp_plans where Quarter=1 --union all
	  ),
	  nums_rr as 
	  (
	  --select * from rr
	 select a.p
	 , a.product
	 , a.Канал
	 , format(a.Ставка , '0.0', 'en-US')+'%'+char(10) Ставка_текст
	 , format(a.Сумма , '#,0', 'en-US')+ ' руб.'+char(10)   Сумма_текст
	 , format(a.Количество , '#,0', 'en-US')+ ' шт.'+char(10) Количество_текст
	 , format(a.Чек , '#,0', 'en-US')+ ' руб.'+char(10) Чек_текст
	 , isnull(format(rr.[Выданная сумма]*a.СуммаRR/nullif(rr.[Выданная сумма план по вчера], 0), '#,0', 'en-US')+' ('+format(100*a.СуммаRR/nullif(rr.[Выданная сумма план по вчера], 0) , '0.0', 'en-US')+'%)'+char(10), char(10))  rr
	 , format(plans.Сумма, '#,0', 'en-US')+' руб.'+char(10)+'% выполнения: '+isnull( format(a.Сумма/nullif(plans.Сумма, 0), '0.0%', 'en-US') , '0%')  +char(10) [Сумма план всего]
	 , format(rr.[Выданная сумма], '#,0', 'en-US')+' руб.'+char(10) [Сумма план канал]
	 	   
	 
	 from
	
	 nums a --on x.a=a.Канал and x.b=a.product
	 left join rr on rr.Канал=a.Канал and rr.[Тип продукта]=a.product and a.p='Month' --and rr.month=1
	 left join plans on plans.p=a.p and a.product=plans.[Тип продукта] and a.Канал='Всего'

)
--select * from nums_rr
, for_text as (
select * , 

'<b>'+Канал+': ' +Количество_текст+'</b>'
+'<b>'+'Выдано: '+Сумма_текст +'</b>'
+case when product = 'ПТС' and p='month' and Канал<>'Всего' then '<b>'+'RR: '+rr +'</b>' +'План: '+ [Сумма план канал]  else '' end
+case when Канал ='Всего' then 'План: '+ [Сумма план всего] else '' end 
+case when p='month' and Канал ='Всего' then '<b>'+'RR: '+rr+'</b>' else '' end 
+'Чек: '+Чек_текст 
+case when Канал='Всего' then 'Ставка: '+Ставка_текст else '' end [text]

from 
 (    select 'CPA нецелевой' a, 'ПТС' b union all
	  select 'CPA полуцелевой' a, 'ПТС' b union all
	  select 'CPA целевой' a, 'ПТС' b union all
	  select 'CPC' a, 'ПТС' b union all
	  select 'Партнеры' a, 'ПТС' b union all
	  select 'Органика' a, 'ПТС' b union all
	  select 'Триггеры' a, 'ПТС' b union all
	  select 'Всего' a, 'ПТС' b union all

	  select 'CPA нецелевой' a, 'Инстоллмент' b union all
	  select 'CPA полуцелевой' a, 'Инстоллмент' b union all
	  select 'CPA целевой' a, 'Инстоллмент' b union all
	  select 'CPC' a, 'Инстоллмент' b union all
	  select 'Партнеры' a, 'Инстоллмент' b union all
	  select 'Органика' a, 'Инстоллмент' b union all
	  select 'Триггеры' a, 'Инстоллмент' b union all
	  select 'Всего' a, 'Инстоллмент' b union all

	  select 'Всего' a, 'Бизнес инвест' b 
	 ) x 
	 join (select 'today' periods union all select 'week' union all select 'LastMonth' union all select 'yesterday' union all select 'month' union all select 'quarter' 
	 
	 ) pps on 1=1
	 left join 

nums_rr on nums_rr.product=x.b and x.a=nums_rr.Канал and  pps.periods=nums_rr.p

)

--select * from for_text

select periods, b, 'Today is: '+format(@report_date, 'dd-MMM')+char(10)+ b+char(10)+'_________'+char(10)+isnull(STRING_AGG(text, char(10)) within group (order by case when Канал ='Всего' then 1 end , Канал), 'Нет данных.' + isnull((select top 1 ' План: '+format(Сумма , '#,0')+' руб.'  from plans where plans.p=periods and plans.[Тип продукта]=b and plans.Канал='Всего' ), '') ) text into #r from for_text
group by periods, b 

begin tran
truncate table  [оперативная витрина с выдачами и каналами агрегаты]
--drop table if exists [оперативная витрина с выдачами и каналами агрегаты]
insert  into  [оперативная витрина с выдачами и каналами агрегаты] 
select * from #r
commit tran

--select * from [оперативная витрина с выдачами и каналами агрегаты]

--declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end


-----------------------------------------
-----------------------------------------

drop table if exists #gr
select 'chart_sales_month' command , 
text = 

(select (


select format(ws.[Дата выдачи месяц], 'MMM-yy') [Дата выдачи месяц], '#000000'  as [x font color], isnull([Выдано первичные], 0) [Выдано первичные] , isnull([Выдано повторные], 0) [Выдано повторные], isnull([Выдано всего], 0)  [Выдано всего]  from 
(
select cast(                       DATEADD(month, DATEDIFF(month,0, @report_date), 0)   as date)    [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -1 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -2 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -3 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -4 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -5 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -6 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -7 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -8 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month ,  -9 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month , -10 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month , -11 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month , -12 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] union all
select cast( DATEADD(month , -13 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] --union all
--select cast( DATEADD(month , -14 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] --union all
) ws
left join (


select DATEADD(month, DATEDIFF(month,0, [ДатаВыдачи]), 0)   [Дата выдачи месяц] 
, sum(case when [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when 1=1 then Сумма end) [Выдано всего]


from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and IsInstallment=0
group by DATEADD(month, DATEDIFF(month,0, [ДатаВыдачи]), 0) 

) d on ws.[Дата выдачи месяц]=d.[Дата выдачи месяц]
--where ws.[Дата выдачи месяц]>='20220501'
order by ws.[Дата выдачи месяц]
for json auto ) )
into #gr
union all
-----------------------------------------
-----------------------------------------
-- declare @today date = getdate()
select 'chart_sales_week' command , 
text = 

(select (


select format(ws.[Дата выдачи неделя], 'dd.MMM')+' - '+format(dateadd(day, 6 ,ws.[Дата выдачи неделя]), 'dd.MMM') [Дата выдачи неделя], '#000000'  as [x font color] , isnull([Выдано первичные], 0) [Выдано первичные] , isnull([Выдано повторные], 0) [Выдано повторные], isnull([Выдано всего], 0)  [Выдано всего]  from 
(
--set datefirst 1
--set datefirst 1 declare @today date = getdate()
--select  DATEADD(DD, 2 - DATEPART(DW, DATEADD(DD, -1, @today)), DATEADD(DD, -1, @today))
select cast(                    dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01')       as DATE) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -1 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -2 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -3 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -4 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -5 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -6 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -7 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -8 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk ,  -9 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk , -10 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk , -11 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk , -12 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk , -13 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] union all
select cast( DATEADD(wk , -14 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date) [Дата выдачи неделя] --union all
) ws
left join (


select  dateadd(day, datediff(day, '1900-01-01', [ДатаВыдачи]) / 7 * 7, '1900-01-01')   [Дата выдачи неделя] 
, sum(case when [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when 1=1 then Сумма end) [Выдано всего]


from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and IsInstallment=0
group by dateadd(day, datediff(day, '1900-01-01', [ДатаВыдачи]) / 7 * 7, '1900-01-01')
--order by cast(DATEADD(wk, DATEDIFF(wk,0, [Дата выдачи день]), 0) as date)
) d on ws.[Дата выдачи неделя]=d.[Дата выдачи неделя]
order by ws.[Дата выдачи неделя]
for json auto ) )
union all
-----------------------------------------
-----------------------------------------
select 'chart_sales_day' command , 
text = 

(select (


select format(ws.[Дата выдачи день], 'dd.MMM')  [Дата выдачи день] , case when datepart(dw, ws.[Дата выдачи день]) in (6,7) then '#FF0303' else '#000000'  end [x font color] , isnull([Выдано первичные], 0) [Выдано первичные] , isnull([Выдано повторные], 0) [Выдано повторные], isnull([Выдано всего], 0)  [Выдано всего]  from 
(
select                     @report_date  [Дата выдачи день] union all
select DATEADD(day ,  -1 , @report_date) [Дата выдачи день] union all
select DATEADD(day ,  -2 , @report_date) [Дата выдачи день] union all 
select DATEADD(day ,  -3 , @report_date) [Дата выдачи день] union all
select DATEADD(day ,  -4 , @report_date) [Дата выдачи день] union all
select DATEADD(day ,  -5 , @report_date) [Дата выдачи день] union all
select DATEADD(day ,  -6 , @report_date) [Дата выдачи день] union all
select DATEADD(day ,  -7 , @report_date) [Дата выдачи день] union all
select DATEADD(day ,  -8 , @report_date) [Дата выдачи день] union all
select DATEADD(day ,  -9 , @report_date) [Дата выдачи день] union all
select DATEADD(day , -10 , @report_date) [Дата выдачи день] union all
select DATEADD(day , -11 , @report_date) [Дата выдачи день] union all
select DATEADD(day , -12 , @report_date) [Дата выдачи день] union all
select DATEADD(day , -13 , @report_date) [Дата выдачи день] union all
select DATEADD(day , -14 , @report_date) [Дата выдачи день] --union all
) ws
left join (


select [ДатаВыдачи] [Дата выдачи день] 
, sum(case when [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when 1=1 then Сумма end) [Выдано всего]


from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and IsInstallment=0
group by [ДатаВыдачи]
--order by cast(DATEADD(wk, DATEDIFF(wk,0, [Дата выдачи день]), 0) as date)
) d on ws.[Дата выдачи день]=d.[Дата выдачи день]
order by ws.[Дата выдачи день]
for json auto ) )

begin tran
truncate table  [оперативная витрина графики для ТГ бота]
--drop table if exists [оперативная витрина графики для ТГ бота]
--select * into [оперативная витрина графики для ТГ бота] from #gr
insert  into  [оперативная витрина графики для ТГ бота] 
select * from #gr
commit tran

--select * from [оперативная витрина графики для ТГ бота]
end

--exec [Агрегирование оперативной статистики по каналам]

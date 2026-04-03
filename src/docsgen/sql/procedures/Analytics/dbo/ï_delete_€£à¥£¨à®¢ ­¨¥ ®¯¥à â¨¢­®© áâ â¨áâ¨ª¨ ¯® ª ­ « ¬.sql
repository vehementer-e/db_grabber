
CREATE proc  [dbo].[Агрегирование оперативной статистики по каналам]
as
begin



set datefirst 1;
set language russian;
--declare @report_date date = '20220302'
declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
--declare @report_week date = cast(DATEADD(DD, 1 - DATEPART(DW, @report_date ), @report_date ) as date)
--declare @report_yesterday date = dateadd(day, -1, @report_date)
--declare @report_month date = cast(format(@report_date   , 'yyyy-MM-01') as date)
--declare @report_lastmonth date = dateadd(month, -1, cast(format(@report_date   , 'yyyy-MM-01') as date))
--declare @report_quarter date = cast(DATEADD(qq, DATEDIFF(qq, 0, @report_date), 0) as date)


drop table if exists #r
drop table if exists #tmp_plans
drop table if exists #chpl
CREATE TABLE [dbo].[#chpl]
(
      [Месяц] [DATE]
    , [Дата] [DATE]
    , [Канал] [NVARCHAR](255)
    , [Канал от источника] [NVARCHAR](255)
    , [Тип продукта] [NVARCHAR](255)
    , [Выданная сумма] [FLOAT]
);
;



with cpl as (

select cast(format(Дата, 'yyyy-MM-01') as date) Месяц, cast(Дата as date) Дата
, [Займы руб]
, [Займы руб]/(sum([Займы руб]) over(partition by cast(format(Дата, 'yyyy-MM-01') as date))+0.0) [weight of day] 
from stg.files.contactcenterplans_buffer_stg a 


)


 insert into #chpl 
select cpl.Месяц
, cpl.Дата
, case when b.[Группа каналов]='cpa' then b.[Канал от источника] else b.[Группа каналов] end [Канал]
, b.[Канал от источника]
, b.[Тип продукта]
, cast( [Выданная сумма]*[weight of day] as float) [Выданная сумма]
--, case when Дата=@report_date then 1 else 0 end as Today
--, case when Дата=@report_yesterday then 1 else 0 end as Yesterday
--, case when cast(DATEADD(DD, 1 - DATEPART(DW, Дата ), Дата ) as date) = @report_week then 1 else 0 end as Week
--, case when cast(format(Дата   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
--, case when cast(format(Дата   , 'yyyy-MM-01') as date)  = @report_lastmonth then 1 else 0 end as  LastMonth
--, case when cast(format(Дата   , 'yyyy-MM-01') as date)  = @report_month and Дата<=@report_yesterday then 1 else 0 end as  [month but today]
from cpl 

join 

stg.files.[план по каналам_stg] b on cpl.Месяц=b.Месяц

where 1=0

insert into  #chpl
select Месяц, Дата, case when b.[Группа каналов]='cpa' then b.[Канал от источника] else b.[Группа каналов] end [Канал] , b.[Канал от источника], [Тип продукта], [Выданная сумма ПТС] from [v_План по каналам] b
--exec create_table '#chpl'

--select * from #chpl


insert into  #chpl

select Месяц, Дата, [Вид займа],[Вид займа], 'Инстоллмент', [Выданная сумма Инст] from [v_План по каналам_инст]
where year(Месяц)<=	year(getdate())


--select * from #chpl

--select Месяц, sum([Выданная сумма Инст]) from [v_План по каналам_инст]
--group by Месяц
-- order by 1
--order by Дата

;



	
with plans as (
  select * from (
  SELECT 
       [День]
     ,product = 'ПТС'
      ,cast([Сумма]  as float) [Сумма]

	from v_plans
	union all  
	SELECT 
       [День]
     ,product = 'Инстоллмент'
      ,cast([Сумма инстоллмент] as float)  [Сумма]
	from v_plans

	union all  
	SELECT 
       [День]
     ,product = 'Бизнес инвест'
      ,cast([Сумма Бизнес инвест]  as float) [Сумма]

	from v_plans

  )pl
   where 1=1  
)
select * into #tmp_plans from plans



drop table if exists #facts


    SELECT [ДатаВыдачи]
    ,Код
	,cast([Сумма] as float)  [Сумма]
	,СтавкаНаСумму
    ,case when IsInstallment=1 then case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end  else Канал end Канал
	,product = case when IsInstallment=1 then 'Инстоллмент'
	      else  'ПТС'
	end
	
	
	into #facts
      FROM [оперативная витрина с выдачами и каналами] 
	  union all
    SELECT [Дата выдачи]
    ,Номер
	,cast([Выданная сумма] as float)  [Сумма]
	, СтавкаНаСумму
    ,null Канал
	,product = 'Бизнес инвест' 

      FROM [Analytics].[dbo].[Бизнес инвест] --with(nolock)




;


with dates as (
select 'channels_today'   command , @report_date since, @report_date till union all
select 'channels_yesterday'    , dateadd(day, -1, @report_date), dateadd(day, -1, @report_date) union all
select 'channels_week'         ,  dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01')  , dateadd(day, 6, dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01') ) union all
select 'channels_month'        , cast(format(@report_date, 'yyyy-MM-01') as date), dateadd(day, -1, dateadd(month, 1, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'channels_lastmonth'        , dateadd(month, -1 , cast(format(@report_date, 'yyyy-MM-01') as date)) , dateadd(day, -1, dateadd(month, 0, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'channels_quarter'        , cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date),  dateadd(day , -1, dateadd(qq, 1, cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date)) )

)
,
channels as (

select 'CPA нецелевой'    channel, 1 channel_order_num, product_of_channel = 'ПТС' union all
select 'CPA полуцелевой'  channel, 2 channel_order_num, product = 'ПТС' union all
select 'CPA целевой'      channel, 3 channel_order_num, product = 'ПТС' union all
select 'CPC'              channel, 4 channel_order_num, product = 'ПТС' union all
select 'Партнеры'         channel, 5 channel_order_num, product = 'ПТС' union all
select 'Органика'         channel, 6 channel_order_num, product = 'ПТС' union all
select 'Триггеры'         channel, 7 channel_order_num, product = 'ПТС' union all
select 'Банки'            channel, 8 channel_order_num, product = 'ПТС' union all
select 'Всего'            channel, 9 channel_order_num, product = 'ПТС' union all
select 'Первичный'            channel, 1 channel_order_num, product = 'Инстоллмент' union all
select 'Повторный'            channel, 2 channel_order_num, product = 'Инстоллмент' union all
select 'Всего'            channel, 9 channel_order_num, product = 'Инстоллмент' union all
select 'Всего'            channel, 9 channel_order_num, product = null --union all

)
, products as 
(

select 'ПТС'          product, 1 product_order_num union all
select 'Инстоллмент'  product, 2 product_order_num union all
select 'Всего'        product, 3 product_order_num --union all


)
,
facts as (

select f.* from #facts f join products p on p.product=f.product
)
,
plans as (

select pl.* from #tmp_plans pl join products p on (p.product=pl.product)
)

, nums as (
select dates.command, dates.since, dates.till, products.*, channels.*, isnull(Сумма , 0) Сумма, isnull(Количество  , 0) Количество ,isnull(Чек  , 0)   Чек, isnull(Ставка, 0) Ставка, isnull(Сумма_План_По_Каналам, 0) Сумма_План_По_Каналам, isnull(Сумма_План, 0)  Сумма_План
, rr__проценты = case when command in ('channels_month', 'channels_lastmonth') and channel<>'Всего' /*and product='ПТС'*/  then x_facts.СуммаRR / nullif(x_plans_ch.СуммаRR_План_По_Каналам  , 0)
                      when command in ('channels_month', 'channels_lastmonth') and channel = 'Всего'  then x_facts.СуммаRR /  nullif( x_plans.Сумма_План_RR , 0)  end

, rr__рубли    = case when command in ('channels_month', 'channels_lastmonth') and channel<>'Всего' /*and product='ПТС'*/  then x_plans_ch.Сумма_План_По_Каналам* x_facts.СуммаRR / x_plans_ch.СуммаRR_План_По_Каналам  
                      when command in ('channels_month', 'channels_lastmonth') and channel = 'Всего'  then x_plans.Сумма_План* x_facts.СуммаRR / nullif( x_plans.Сумма_План_RR , 0)  end 

, процент_выполнения = case when channel<>'Всего' /*and product='ПТС'*/ then x_facts.Сумма / nullif(x_plans_ch.Сумма_План_По_Каналам  , 0)  
                            when channel='Всего'   then x_facts.Сумма / nullif(x_plans.Сумма_План  , 0)   end
from dates
cross join products 															    
 join channels	  on channels.product_of_channel=products.product or  (product='Всего'  and channels.product_of_channel is null	)
outer apply (

select sum(Сумма) Сумма, count(*) Количество, avg(Сумма) Чек, sum(case when ДатаВыдачи<@report_date then Сумма end ) СуммаRR 
, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка
from facts f 
where 
    case when f.product=products.product then 1 when products.product = 'Всего'   then 1 end=1 
and case when f.Канал=channels.channel   then 1 when channels.channel = 'Всего'   then 1 end=1 
and f.ДатаВыдачи between dates.since and dates.till
) x_facts
outer apply (

select sum(chpl.[Выданная сумма]) Сумма_План_По_Каналам , sum(case when chpl.Дата<@report_date then chpl.[Выданная сумма] end ) СуммаRR_План_По_Каналам  from #chpl chpl
where 
    chpl.Канал = channels.channel
	and chpl.[Тип продукта]=products.product
	and chpl.Дата between dates.since and dates.till
	and chpl.[Тип продукта] in ('ПТС', 'Инстоллмент')
	and channels.channel <>'Всего'
) x_plans_ch
outer apply (

select sum(tpl.Сумма) Сумма_План, sum(case when tpl.День<@report_date then  tpl.Сумма end) Сумма_План_RR  

from plans tpl
where 
    
	tpl.День between dates.since and dates.till
	and channels.channel='Всего'
	and case when products.product='Всего' then 1 when products.product=tpl.product then 1 end=1
) x_plans
--where command='channels_month'
--order by dates.command, products.order_num, channels.order_num

)
, nums_text as (

select 
command,
since,
till,
product, product_order_num,
channel, channel_order_num,
Сумма, Количество, Чек, Ставка, Сумма_План_По_Каналам, Сумма_План, rr__проценты, rr__рубли, процент_выполнения
	 , 'Ставка: '+ format(Ставка , '0.0', 'en-US')+'%'+char(10) Ставка_текст
	 , '<b>'+'Выдано: '+format(Сумма , '#,0', 'en-US')+ ' руб.'+'</b>'+char(10)   Сумма_текст
	 , '<b>'+channel +': '+ format(Количество , '#,0', 'en-US')+ ' шт.' +'</b>'+char(10) Количество_текст
	 , 'Чек: '+format(Чек , '#,0', 'en-US')+ ' руб.'+char(10) Чек_текст
	 , '<b>'+ 'RR: '+ isnull(format(rr__рубли , '#,0', 'en-US')+' ('+format(100*rr__проценты , '0.0', 'en-US')+'%)'+char(10), char(10)) +'</b>' rr_текст
	 , 'План: ' +format(Сумма_План, '#,0', 'en-US')+' руб.'+char(10)+'% выполнения: '+isnull( format(процент_выполнения, '0.0%', 'en-US') , '0%')  +char(10) [Сумма план всего_текст]
	 , 'План: ' +format(Сумма_План_По_Каналам, '#,0', 'en-US')+' руб.'+char(10) [Сумма план канал_текст]
	 	   



from nums

)

,
texts as (
select 

  Количество_текст
+ Сумма_текст
+ case when command  in ('channels_month', 'channels_lastmonth') and ( product='ПТС'  or  (product='Инстоллмент' /*and channel='Всего'*/) ) then rr_текст else '' end 


+case when command  in ('channels_month', 'channels_lastmonth') then 
                                       case when channel='Всего' then [Сумма план всего_текст] when channel<>'Всего' and ( product='ПТС' or  (product='Инстоллмент'))  then [Сумма план канал_текст] else '' end 
									   
		when command not in ('channels_month', 'channels_lastmonth') then 
                                       case when channel='Всего' then [Сумма план всего_текст]  else '' end 
									   
									   
									   else '' end
+Чек_текст
+case when channel='Всего' then Ставка_текст else '' end text_row
,
*
from nums_text

)

--select * from texts

select command,
text = max(case when since<>till then N'📆' else N'📅' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+'—————————————'+char(10))
+
N'🚗 ПТС:'+char(10)+ STRING_AGG(case when product='ПТС' and (channel='Всего' or Количество>0 ) then text_row end , char(10)) within group(order by channel_order_num) +'—————————————'+char(10)+
+
N'💸 Инстоллмент:'+char(10)+ STRING_AGG(case when product='Инстоллмент' and (channel='Всего' or Количество>0 ) then text_row end , char(10)) within group(order by channel_order_num) +'—————————————'+char(10)+
--+
--N'💸 Инстоллмент:'+char(10)+ max(case when channel='Всего' and product='Инстоллмент' then text_row else '' end) +'—————————————'+char(10)+

+
N'🚗 ПТС + 💸 Инст:'+char(10)+ max(case when channel='Всего' and product='Всего' then text_row else '' end)  
 --+char(10)+'/'+max(command)
into #r
from texts
group by command

--select * from #r


begin tran
truncate table  [оперативная витрина с выдачами и каналами агрегаты]
--drop table if exists [оперативная витрина с выдачами и каналами агрегаты]
--select * into [оперативная витрина с выдачами и каналами агрегаты] from  #r
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


select format(ws.[Дата выдачи месяц], 'MMM-yy') [Дата выдачи месяц], '#000000'  as [x font color]
, isnull([Выдано первичные], 0) [Выдано первичные] 
, isnull([Выдано повторные], 0) [Выдано повторные]
, isnull([Выдано всего], 0)  [Выдано всего]
, isnull([Выдано первичные инст], 0) [Выдано первичные инст] 
, isnull([Выдано повторные инст], 0) [Выдано повторные инст]
, isnull([Выдано всего инст], 0)  [Выдано всего инст]

from 
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
, sum(case when IsInstallment=0 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0 and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1 and 1=1 then Сумма end) [Выдано всего инст]

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null-- and IsInstallment=0
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


select format(ws.[Дата выдачи неделя], 'dd.MMM')+' - '+format(dateadd(day, 6 ,ws.[Дата выдачи неделя]), 'dd.MMM') [Дата выдачи неделя], '#000000'  as [x font color] 
, isnull([Выдано первичные], 0) [Выдано первичные] 
, isnull([Выдано повторные], 0) [Выдано повторные]
, isnull([Выдано всего], 0)  [Выдано всего]
, isnull([Выдано первичные инст], 0) [Выдано первичные инст] 
, isnull([Выдано повторные инст], 0) [Выдано повторные инст]
, isnull([Выдано всего инст], 0)  [Выдано всего инст]
from 
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
, sum(case when IsInstallment=0 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0 and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1 and 1=1 then Сумма end) [Выдано всего инст]

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null --and IsInstallment=0
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


select format(ws.[Дата выдачи день], 'dd.MMM')  [Дата выдачи день] , case when datepart(dw, ws.[Дата выдачи день]) in (6,7) then '#FF0303' else '#000000'  end [x font color] 
, isnull([Выдано первичные], 0) [Выдано первичные] 
, isnull([Выдано повторные], 0) [Выдано повторные]
, isnull([Выдано всего], 0)  [Выдано всего]
, isnull([Выдано первичные инст], 0) [Выдано первичные инст] 
, isnull([Выдано повторные инст], 0) [Выдано повторные инст]
, isnull([Выдано всего инст], 0)  [Выдано всего инст]
from 
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
, sum(case when IsInstallment=0 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0 and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1 and 1=1 then Сумма end) [Выдано всего инст]


from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null --and IsInstallment=0
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

--select * from [оперативная витрина графики для ТГ бота2]
--select * from [оперативная витрина графики для ТГ бота]
end

--exec [Агрегирование оперативной статистики по каналам]

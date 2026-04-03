
CREATE   proc  [_tg].[AnalyticsBot]

@mode nvarchar(max) = 'update'

as
begin


if @mode = 'update_kp'
begin



drop table if exists #kp
 select
Прибыль = isnull(sum([СуммаДопУслуг_without_partner_bounty_net] ), 0),
Сумма = isnull(sum(Сумма ), 0),
Количество = null, 
день =    ДатаВыдачи,
Продукт = 'КП',
Тип = 'КП'
into #kp
from [оперативная витрина с выдачами и каналами]
where ДатаВыдачи>getdate()-200						and isinstallment=0
 group by ДатаВыдачи



drop table if exists #sms
select

Прибыль = [Комиссия "СМС информирование": cумма услуги net],
Сумма = null,

Количество = 1, 
день = [Комиссия "СМС информирование": дата оплаты день],
Продукт = 'СМС-инфо', 
Тип = 'comissions'
into #sms
from v_comissions
where [Комиссия "СМС информирование": cумма услуги] is not null
and [Комиссия "СМС информирование": дата оплаты день]>getdate()-200

drop table if exists #sroch
select 

Прибыль    = [Комиссия "Срочное снятие с залога": cумма услуги net],
Сумма = null,
Количество = 1, 
день       =    [Комиссия "Срочное снятие с залога": дата оплаты день],
Продукт = 'Срочное снятие залога', 
Тип = 'comissions'

into #sroch

from v_comissions
where [Комиссия "Срочное снятие с залога": cумма услуги] is not null
and [Комиссия "Срочное снятие с залога": дата оплаты день]>getdate()-200


drop table if exists #pg

select 

Прибыль = isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0),
Сумма = Сумма,
Количество = 1, 
день =    [ДеньПлатежа],
Продукт = case when [ПлатежнаяСистема]='Киви' then 'Contact' else [ПлатежнаяСистема] end,
Тип = 'ПШ'
into #pg
from v_repayments
where Дата>getdate()-200

union all
select 

Прибыль = isnull(  [Прибыль расчетная екомм без НДС] , 0),
Сумма = Сумма,
Количество = 1, 
день =    [ДеньПлатежа],
Продукт = case when isinstallment=0 then 'ECommPay ПТС' else 'ECommPay ИНСТ' end,
Тип = 'ECommPay продукт'
 
from v_repayments

where Дата>getdate()-200   and [ПлатежнаяСистема]= 'ECommPay'


drop table if exists #un

select * into #un from #sms union all
select * from #kp union all
select * from #sroch union all
select * from #pg

--select sum(Прибыль) from #un where день between '20221101' and '20221121'

select * from #un

create clustered index t on #un (День, Тип, Продукт)

set datefirst 1;
set language russian;
--declare @report_date date = '20220302'
declare @report_date_kp date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end



drop table if exists #final_kp
;

with dates as (
select 'comissions_today'   command , @report_date_kp since, @report_date_kp till union all
select 'comissions_yesterday'    , dateadd(day, -1, @report_date_kp), dateadd(day, -1, @report_date_kp) union all
select 'comissions_week'         ,  dateadd(day, datediff(day, '1900-01-01', @report_date_kp) / 7 * 7, '1900-01-01')  , dateadd(day, 6, dateadd(day, datediff(day, '1900-01-01', @report_date_kp) / 7 * 7, '1900-01-01') ) union all
select 'comissions_month'        , cast(format(@report_date_kp, 'yyyy-MM-01') as date), dateadd(day, -1, dateadd(month, 1, cast(format(@report_date_kp, 'yyyy-MM-01') as date) )) union all
select 'comissions_lastmonth'        , dateadd(month, -1 , cast(format(@report_date_kp, 'yyyy-MM-01') as date)) , dateadd(day, -1, dateadd(month, 0, cast(format(@report_date_kp, 'yyyy-MM-01') as date) )) union all
select 'comissions_quarter'        , cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date_kp), 0) as date),  dateadd(day , -1, dateadd(qq, 1, cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date_kp), 0) as date)) )

)
,

products as (
select 1 num_order_by,0 is_total, 'СМС-инфо' Продукт , Тип = 'comissions' union all
select 2 num_order_by,0 is_total, 'Срочное снятие залога' product , type = 'comissions' union all
select 3 num_order_by,0 is_total, 'Contact' product , type = 'ПШ' union all
select 4 num_order_by,0 is_total, 'ECommPay' product , type = 'ПШ' union all
select 4.5 num_order_by,0 is_total, 'ECommPay ПТС' product , type = 'ECommPay продукт' union all
select 4.5 num_order_by,0 is_total, 'ECommPay ИНСТ' product , type = 'ECommPay продукт' union all
select 5 num_order_by,0 is_total, 'Расчетный счет' product , type = 'ПШ' union all
select 6 num_order_by,1 is_total, 'Итого ПШ' product , type = 'ПШ' union all
select 7 num_order_by,0 is_total, 'КП' product , type = 'КП' union all
select 8 num_order_by,1 is_total, 'Итого' product , type = 'Итого' --union all

)
,
 plans as
 (

select День, [План комиссии PNL] , Продукт = 'Итого', Тип = 'Итого' from v_plans

 )

, un as (
select * from #un
)
, nums aS
(
select * 
from 
dates  cross join products
outer apply (
select isnull(sum(Сумма), 0) Сумма_Продукт, isnull(sum(Прибыль), 0) Прибыль_Продукт from un
where un.день between dates.since and dates.till and un.Продукт=products.Продукт ) x1
outer apply (
select sum(Сумма) Сумма_Тип, sum(Прибыль) Прибыль_Тип from un
where un.день between dates.since and dates.till and 
case when 
un.Тип=products.Тип then 1 
when products.Продукт='Итого ПШ' and un.Тип='ПШ' then 1
when products.Продукт='Итого' and un.Тип<>'Ecommpay продукт'  then 1 end = 1
) x2
outer apply (
select sum([План комиссии PNL])   План from plans
where plans.день between dates.since and dates.till and products.Продукт=plans.Продукт
and products.Тип=plans.Тип
) x3

)

, nums_perc as (
select *
, Доля = case when Тип in ( 'ПШ') then isnull(Сумма_Продукт/nullif(Сумма_Тип, 0), 0) end 
, Доля_прибыль = case when Тип in ( 'ECommPay продукт') then isnull(Прибыль_Продукт/nullif(Прибыль_Тип, 0), 0) end 
, Доля_КП_net = case when Тип in ( 'КП') then isnull(Прибыль_Продукт/nullif(Сумма_Продукт, 0), 0) end 
, Процент_выполнения =   isnull(Прибыль_Тип/nullif(план, 0), 0)  

from nums
)

,
for_texts as (
select * 
, Сумма_текст = '<b>'+'Сумма: '+format(case when is_total=0 then Сумма_Продукт else Сумма_Тип end , '#,0', 'en-US')+ ' руб.'+'</b>'
, Прибыль_текст = '<b>'+'Доход net: '+format(case when is_total=0 then Прибыль_Продукт else Прибыль_Тип end , '#,0', 'en-US')+ ' руб.'+'</b>'
, Доля_Текст =  case 
when  Тип = 'ПШ' then  'Доля: '+format(Доля , '0.0%', 'en-US') 
when  Тип='КП'   then  'Доля КП net: '+format(Доля_КП_net , '0.00%', 'en-US')    
when  Тип='ECommPay продукт'   then  'Доля прибыли: '+format(Доля_прибыль , '0.00%', 'en-US')  else '' end
, Процент_выполнения_Текст =  '% выполнения: '+format(isnull(Процент_выполнения , 0), '0.0%', 'en-US')
, План_Текст =  'План: '+format(isnull(План, 0) , '#,0', 'en-US')
from nums_perc 

)
, texts as (
select *, case
when Тип='comissions' then Продукт+': '+char(10)+Прибыль_текст +char(10)
when Тип='ПШ' and is_total=0 then Продукт+': '+char(10)+Сумма_текст+char(10) +Доля_Текст+char(10)+Прибыль_текст+char(10)
when Тип='ПШ' and is_total=1 then Продукт+': '+char(10)+Сумма_текст +char(10)+Прибыль_текст+char(10)
when Тип='ECommPay продукт' and is_total=0 then Продукт+': '+char(10)+Сумма_текст +char(10)+Прибыль_текст+char(10)+Доля_Текст+char(10)
when Тип='КП' then Продукт+': '+char(10)+Прибыль_текст +char(10)+Доля_Текст+char(10)
when Тип='Итого' then Продукт+': '+char(10)+Прибыль_текст +char(10) + case when command in ('comissions_month', 'comissions_lastmonth') then  План_Текст+char(10) + Процент_выполнения_Текст+char(10) else '' end
end row_text
from for_texts


)
 --select * from texts
 --order by 1,4

select command,
--text = max(case when since<>till then N'🎄' else N'🎄' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+'—————————————'+char(10))
text = max(case when since<>till then N'📆' else N'📅' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+'—————————————'+char(10))
+
string_agg( row_text , char(10)) within group (order by num_order_by)
 --+char(10)+'/'+max(command)
into #final_kp
from texts
group by command


begin tran

--drop table if exists [dbo].[оперативная витрина с комиссиями агрегаты]
--select * into [dbo].[оперативная витрина с комиссиями агрегаты]
--from #final_kp 

delete from [dbo].[оперативная витрина с комиссиями агрегаты]
insert into [dbo].[оперативная витрина с комиссиями агрегаты]
select * from #final_kp

commit tran


	 end

	if @mode=  'load_loans'
	begin

	
drop table if exists #fa
select Номер, case when [Группа каналов] ='cpa' then [Канал от источника] else [Группа каналов] end Канал
, case when b.[Группа каналов] ='cpa' then  b.[Группа каналов]  else b.[Канал от источника] end	  Канал2
, [Вид займа]  into #fa from reports.dbo.dm_Factor_Analysis_001		b
where cast([Заем выдан]   as date ) between '20180101' and getdate()  or ДатаЗаявкиПолная >=getdate()-10

drop table if exists #t1
select ДатаВыдачи, Сумма, СтавкаНаСумму, код, Канал, IsInstallment, [Вид займа], [СуммаДопУслуг_without_partner_bounty_net] into #t1 from [Reports].[dbo].[dm_Sales] 
where ДатаВыдачи between '20180101' and getdate()
and ishistory=0



;
with v as (select *, ROW_NUMBER() over(partition by код order by [СуммаДопУслуг_without_partner_bounty_net] desc) rn from  #t1 ) delete from v where rn>1

drop table if exists #re

select a.[Номер заявки], a.[Канал от источника]
, case when b.[Группа каналов] ='cpa' then b.[Канал от источника] else b.[Группа каналов] end Канал
, case when b.[Группа каналов] ='cpa' then  b.[Группа каналов]  else b.[Канал от источника] end Канал2
into #re
from stg.files.channelrequestexceptions_buffer_stg a  join stg.files.leadRef1_buffer b on a.[Канал от источника]=b.[Канал от источника]


drop table if exists #f


select ДатаВыдачи                                               
,      cast(Сумма as bigint)                                     Сумма
,      СтавкаНаСумму                                            
,      код                                                      
,      isnull(isnull(b.канал, f.Канал), a.Канал)                 Канал
,      isnull(b.канал2, f.Канал2)                   Канал2
,      IsInstallment                                            
,      ISNULL(ISNULL(f.[Вид займа], a.[Вид займа]), 'Первичный') [Вид займа]
,      [СуммаДопУслуг_without_partner_bounty_net]                into #f
from      #t1 a
left join #re b on a.Код=b.[Номер заявки]
left join #fa f on a.Код=f.Номер




--drop table if exists [оперативная витрина с выдачами и каналами]
--select * into [оперативная витрина с выдачами и каналами]
--from #f




--if 1 = 1
--begin
--	drop table if exists  [оперативная витрина с выдачами и каналами]
--	select top(0) * 
--		into  [оперативная витрина с выдачами и каналами]
--	from #f
--
--	drop table if exists  [оперативная витрина с выдачами и каналами_staging]
--	select top(0) * 
--		into  [оперативная витрина с выдачами и каналами_staging]
--	from #f
--
--
--	drop table if exists  [оперативная витрина с выдачами и каналами_to_del]
--	select top(0) * 
--		into  [оперативная витрина с выдачами и каналами_to_del]
--	from #f
--
--end




if exists(select top(1) 1 from #f)
begin
	--Отчистим таблицу - хотя после пред операции она и так будет пустая
	delete from [оперативная витрина с выдачами и каналами_to_del] with(tablockx)
	delete from [оперативная витрина с выдачами и каналами_staging] with(tablockx)
	insert into [оперативная витрина с выдачами и каналами_staging]  with(tablockx)
	SELECT * 
	from #f

	begin tran
		alter table [оперативная витрина с выдачами и каналами]
			switch to [оперативная витрина с выдачами и каналами_to_del]

		alter table [оперативная витрина с выдачами и каналами_staging] 
			switch  to [оперативная витрина с выдачами и каналами]
	commit tran
end


	end








	if @mode=  'update'
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
drop table if exists #final_text
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
    ,  Канал2 Канал2
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
    ,null Канал2
	,product = 'Бизнес инвест' 

      FROM [Analytics].[dbo].[Бизнес инвест] --with(nolock)

	--  select * from #facts
	--  where product<>'ПТС'
	--  order by 1 desc



--declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
drop table if exists #final_text

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

select 'CPA нецелевой'        channel, '' sub_channel, 1.0 channel_order_num, product_of_channel = 'ПТС' union all
select 'CPA полуцелевой'      channel, '' sub_channel, 2.0 channel_order_num, product = 'ПТС' union all
select 'CPA целевой'          channel, '' sub_channel, 3.0 channel_order_num, product = 'ПТС' union all
select 'CPC'                  channel, '' sub_channel, 4.0 channel_order_num, product = 'ПТС' union all
select 'Партнеры'             channel, '' sub_channel, 5.0 channel_order_num, product = 'ПТС' union all
select 'Органика'             channel, '' sub_channel, 6.0 channel_order_num, product = 'ПТС' union all
select 'Триггеры'             channel, '' sub_channel, 9.5 channel_order_num, product = 'ПТС' union all
select 'Банки'                channel, '' sub_channel, 8.0 channel_order_num, product = 'ПТС' union all
select '(ВТБ)'                    channel, 'ВТБ' sub_channel, 8.1 channel_order_num, product = 'ПТС' union all
select '(Газпром)'                    channel, 'Газпром' sub_channel, 8.2 channel_order_num, product = 'ПТС' union all
select '(Модуль)'                    channel, 'Модуль' sub_channel, 8.3 channel_order_num, product = 'ПТС' union all
select '(МТС)'                    channel, 'МТС' sub_channel, 8.4 channel_order_num, product = 'ПТС' union all
select '(ПСБ)'                    channel, 'ПСБ' sub_channel, 8.5 channel_order_num, product = 'ПТС' union all
select '(Союз)'                  channel, 'Союз' sub_channel, 8.6 channel_order_num, product = 'ПТС' union all
select '(Точка)'                  channel, 'Точка' sub_channel, 8.7 channel_order_num, product = 'ПТС' union all
select 'Телеком'              channel, '' sub_channel, 9.0 channel_order_num, product = 'ПТС' union all
select 'Всего'                channel, '' sub_channel, 10.0 channel_order_num, product = 'ПТС' union all
select 'Первичный'            channel, '' sub_channel, 1.0 channel_order_num, product = 'Инстоллмент' union all
select 'Повторный'            channel, '' sub_channel, 2.0 channel_order_num, product = 'Инстоллмент' union all

select '(ВТБ)'                  channel, 'ВТБ' sub_channel, 8.1 channel_order_num, product = 'Инстоллмент' union all
select '(Газпром)'                  channel, 'Газпром' sub_channel, 8.2 channel_order_num, product = 'Инстоллмент' union all
select '(Модуль)'                  channel, 'Модуль' sub_channel, 8.3 channel_order_num, product = 'Инстоллмент' union all
select '(МТС)'                  channel, 'МТС' sub_channel, 8.4 channel_order_num, product = 'Инстоллмент' union all
select '(ПСБ)'                  channel, 'ПСБ' sub_channel, 8.5 channel_order_num, product = 'Инстоллмент' union all
select '(Союз)'                channel, 'Союз' sub_channel, 8.6 channel_order_num, product = 'Инстоллмент' union all
select '(Точка)'                channel, 'Точка' sub_channel, 8.7 channel_order_num, product = 'Инстоллмент' union all


select 'Всего'                channel, '' sub_channel, 10.0 channel_order_num, product = 'Инстоллмент' union all
select 'Всего'                channel, '' sub_channel, 10.0 channel_order_num, product = null --union all
   



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

, rr__рубли    = case when command in ('channels_month', 'channels_lastmonth') and channel<>'Всего' /*and product='ПТС'*/  then x_plans_ch.Сумма_План_По_Каналам* x_facts.СуммаRR / nullif(x_plans_ch.СуммаRR_План_По_Каналам  ,0)
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
and case when f.Канал=channels.channel   and channels.sub_channel='' then 1
         when channels.channel = 'Всего'   then 1 
         when channels.sub_channel = f.Канал2  then 1 
		 
		 
		 end=1 
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
	 , case when  isnull( rr__рубли,0) >0 then  '<b>'+ 'RR: '+ isnull(format(rr__рубли , '#,0', 'en-US')+' ('+format(100*rr__проценты , '0.0', 'en-US')+'%)'+char(10), char(10)) +'</b>' else '' end rr_текст
	 ,  case when isnull( Сумма_План,0)>0 then 'План: ' +format(Сумма_План, '#,0', 'en-US')+' руб.'+char(10)+'% выполнения: '+isnull( format(процент_выполнения, '0.0%', 'en-US') , '0%')  +char(10)  else '' end [Сумма план всего_текст]
	 ,  case when isnull( Сумма_План_По_Каналам,0)>0 then  'План: ' +format(Сумма_План_По_Каналам, '#,0', 'en-US')+' руб.'+char(10)  else '' end [Сумма план канал_текст]
	 	   



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
--text = max(case when since<>till then N'🎄' else N'🎄' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+'—————————————'+char(10))
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
into #final_text
from texts
group by command

--select * from #r
--select * from  #final_text


begin tran
truncate table  [оперативная витрина с выдачами и каналами агрегаты]
--drop table if exists [оперативная витрина с выдачами и каналами агрегаты]
--select * into [оперативная витрина с выдачами и каналами агрегаты] from  #r
insert  into  [оперативная витрина с выдачами и каналами агрегаты] 
select * from #final_text
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


select 'chart_sales_quarter' command , 
text = 

(select (


select CAST(year(ws.[Дата выдачи квартал]) AS char(4)) + '-Q' + 
CAST(CEILING(CAST(month(ws.[Дата выдачи квартал]) AS decimal(9,2)) / 3) AS char(1)) [Дата выдачи квартал]
, '#000000'  as [x font color]
, isnull([Выдано первичные], 0) [Выдано первичные] 
, isnull([Выдано повторные], 0) [Выдано повторные]
, isnull([Выдано всего], 0)  [Выдано всего]
, isnull([Выдано первичные инст], 0) [Выдано первичные инст] 
, isnull([Выдано повторные инст], 0) [Выдано повторные инст]
, isnull([Выдано всего инст], 0)  [Выдано всего инст]
, isnull([Выдано всего ПТС инст], 0)  [Выдано всего ПТС инст]

from 
(
select cast(                       DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0)    as date)[Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -1 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -2 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -3 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -4 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -5 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -6 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -7 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -8 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq ,  -9 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -10 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -11 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -12 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -13 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -14 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -15 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -16 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -17 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -18 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -19 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -20 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -21 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -22 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] union all
select cast( DATEADD(qq , -23 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] --union all
--select cast( DATEADD(qq , -24 , DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) ) as date) [Дата выдачи квартал] --union all
--select cast( DATEADD(month , -14 , DATEADD(month, DATEDIFF(month,0, @report_date), 0) ) as date) [Дата выдачи месяц] --union all
) ws
left join (


select cast(DATEADD(qq   , DATEDIFF(qq   , 0, [ДатаВыдачи]), 0) as date)   [Дата выдачи квартал] 
, sum(case when IsInstallment=0 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0 and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1 and 1=1 then Сумма end) [Выдано всего инст]
, sum(case when   1=1 then Сумма end) [Выдано всего ПТС инст]

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null-- and IsInstallment=0
group by cast(DATEADD(qq   , DATEDIFF(qq   , 0, [ДатаВыдачи]), 0) as date) 

) d on ws.[Дата выдачи квартал]=d.[Дата выдачи квартал]
--where ws.[Дата выдачи месяц]>='20220501'
order by ws.[Дата выдачи квартал]
for json auto ) )
 
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
						 union all
-----------------------------------------
-----------------------------------------
select 'chart_sales_year' command , 
text = 

(select (


select format(ws.[Дата выдачи день], 'yyyy')  [Дата выдачи год] 
, '#000000'  as [x font color] 
, isnull([Выдано первичные], 0) [Выдано первичные] 
, isnull([Выдано повторные], 0) [Выдано повторные]
, isnull([Выдано всего], 0)  [Выдано всего]
, isnull([Выдано первичные инст], 0) [Выдано первичные инст] 
, isnull([Выдано повторные инст], 0) [Выдано повторные инст]
, isnull([Выдано всего инст], 0)  [Выдано всего инст]
, isnull([Выдано всего ПТС инст], 0)  [Выдано всего ПТС инст]

from 
(
select                      cast(format(@report_date, 'yyyy-01-01') as date)   [Дата выдачи день] union all
select DATEADD(year ,  -1 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year ,  -2 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all 
select DATEADD(year ,  -3 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year ,  -4 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year ,  -5 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year ,  -6 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year ,  -7 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year ,  -8 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year ,  -9 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year , -10 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year , -11 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year , -12 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year , -13 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] union all
select DATEADD(year , -14 , cast(format(@report_date, 'yyyy-01-01') as date) ) [Дата выдачи день] --union all
) ws
left join (


select cast(format([ДатаВыдачи], 'yyyy-01-01') as date) [Дата выдачи день] 
, sum(case when IsInstallment=0 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0 and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1 and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1 and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1 and 1=1 then Сумма end) [Выдано всего инст]
, sum(case when  1=1 then Сумма end) [Выдано всего ПТС инст]


from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null --and IsInstallment=0
group by cast(format([ДатаВыдачи], 'yyyy-01-01') as date)
--order by cast(DATEADD(wk, DATEDIFF(wk,0, [Дата выдачи день]), 0) as date)
) d on ws.[Дата выдачи день]=d.[Дата выдачи день]
where year(ws.[Дата выдачи день])>=2018
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


--alter table [оперативная витрина графики для ТГ бота]
--alter column command nvarchar(20)



end

--exec [Агрегирование оперативной статистики по каналам]

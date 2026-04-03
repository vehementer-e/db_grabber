
CREATE   proc [dbo].[Агрегирование оперативной статистики по комиссиям]
as begin



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
where ДатаВыдачи>getdate()-200
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
declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
declare @report_week date = cast(DATEADD(DD, 1 - DATEPART(DW, @report_date ), @report_date ) as date)
declare @report_yesterday date = dateadd(day, -1, @report_date)
declare @report_month date = cast(format(@report_date   , 'yyyy-MM-01') as date)
declare @report_lastmonth date = dateadd(month, -1, cast(format(@report_date   , 'yyyy-MM-01') as date))
declare @report_quarter date = cast(DATEADD(qq, DATEDIFF(qq, 0, @report_date), 0) as date)


drop table if exists #r
;

with dates as (
select 'comissions_today'   command , @report_date since, @report_date till union all
select 'comissions_yesterday'    , dateadd(day, -1, @report_date), dateadd(day, -1, @report_date) union all
select 'comissions_week'         ,  dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01')  , dateadd(day, 6, dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01') ) union all
select 'comissions_month'        , cast(format(@report_date, 'yyyy-MM-01') as date), dateadd(day, -1, dateadd(month, 1, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'comissions_lastmonth'        , dateadd(month, -1 , cast(format(@report_date, 'yyyy-MM-01') as date)) , dateadd(day, -1, dateadd(month, 0, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'comissions_quarter'        , cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date),  dateadd(day , -1, dateadd(qq, 1, cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date)) )

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
text = max(case when since<>till then N'📆' else N'📅' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+'—————————————'+char(10))
+
string_agg( row_text , char(10)) within group (order by num_order_by)
 --+char(10)+'/'+max(command)
into #r
from texts
group by command


begin tran

--drop table if exists [dbo].[оперативная витрина с комиссиями агрегаты]
--select * into [dbo].[оперативная витрина с комиссиями агрегаты]
--from #r

delete from [dbo].[оперативная витрина с комиссиями агрегаты]
insert into [dbo].[оперативная витрина с комиссиями агрегаты]
select * from #r

commit tran


--drop table if exists dbo.[тест комиссии тг]
--select * into dbo.[тест комиссии тг] from 
--#r



end
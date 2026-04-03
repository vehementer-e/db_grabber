
CREATE    proc  [dbo].[bot_analytics]

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
Продукт = 'КП ПТС',
Тип = 'КП'
into #kp
from [оперативная витрина с выдачами и каналами]
where ДатаВыдачи>getdate()-200 and isinstallment=0 and productType <>'AUTOCREDIT'
 group by ДатаВыдачи

 
drop table if exists #kp_bezzalog
 select
Прибыль = isnull(sum([СуммаДопУслуг_without_partner_bounty_net] ), 0),
Сумма = isnull(sum(Сумма ), 0),
Количество = null, 
день =    ДатаВыдачи,
Продукт = 'КП Беззалог',
Тип = 'КП'
into #kp_bezzalog
from [оперативная витрина с выдачами и каналами]
where ДатаВыдачи>getdate()-200						and isinstallment=1   and productType <>'AUTOCREDIT'
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
select * from #kp_bezzalog union all
select * from #sroch union all
select * from #pg

--select sum(Прибыль) from #un where день between '20221101' and '20221121'

--select * from #un

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
select 7.1 num_order_by,0 is_total, 'КП ПТС' product , type = 'КП' union all
select 7.2 num_order_by,0 is_total, 'КП Беззалог' product , type = 'КП' union all
select 8 num_order_by,1 is_total, 'Итого' product , type = 'Итого' --union all

)
,
 plans as
 (

select День, [План комиссии PNL]   , null sum         , Продукт = 'Итого', Тип = 'Итого' from v_plans

union all

select date, ptsAddProductSum      , ptsSum sum       ,  Продукт = 'КП ПТС', Тип = 'КП' from sale_plan
union all
select date, bezzalogAddProductSum , bezzalogSum sum  , Продукт = 'КП Беззалог', Тип = 'КП' from sale_plan
 
 --select top 100 * from sale_plan

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
select sum([План комиссии PNL])   План, sum(sum) План_Сумма from plans
where plans.день between dates.since and dates.till and products.Продукт=plans.Продукт
and products.Тип=plans.Тип
) x3

)

, nums_perc as (
select *
, Доля = case when Тип in ( 'ПШ') then isnull(Сумма_Продукт/nullif(Сумма_Тип, 0), 0) end 
, Доля_прибыль = case when Тип in ( 'ECommPay продукт') then isnull(Прибыль_Продукт/nullif(Прибыль_Тип, 0), 0) end 
, Доля_КП_net = case when Тип in ( 'КП') then isnull(Прибыль_Продукт/nullif(Сумма_Продукт, 0), 0) end 
, Доля_КП_net_план = case when Тип in ( 'КП') then isnull(План/nullif(План_Сумма, 0), 0) end 
, Процент_выполнения =   isnull(Прибыль_Тип/nullif(план, 0), 0)  
, Процент_выполнения_продукт =   isnull(Прибыль_Продукт/nullif(план, 0), 0)  

from nums
)

,
for_texts as (
select * 
, Сумма_текст = '<b>'+'Сумма: '+format(case when is_total=0 then Сумма_Продукт else Сумма_Тип end , '#,0', 'en-US')+ ' руб.'+'</b>'
, Прибыль_текст = '<b>'+'Доход net: '+format(case when is_total=0 then Прибыль_Продукт else Прибыль_Тип end , '#,0', 'en-US')+ ' руб.'+'</b>'
, Доля_Текст =  case 
when  Тип = 'ПШ' then  'Доля: '+format(Доля , '0.0%', 'en-US') 
when  Тип='КП'   then  
'Доля КП net (план): '+format(Доля_КП_net_план , '0.00%', 'en-US')     +char(10)+
'Доля КП net (факт): '+format(Доля_КП_net , '0.00%', 'en-US')    

when  Тип='ECommPay продукт'   then  'Доля прибыли: '+format(Доля_прибыль , '0.00%', 'en-US')  else '' end
, Процент_выполнения_Текст =  '% выполнения: '+format(isnull(Процент_выполнения , 0), '0.0%', 'en-US')
, Процент_выполнения_продукт_текст =  '% выполнения: '+format(isnull(Процент_выполнения_продукт , 0), '0.0%', 'en-US')

, План_Текст =  'План: '+format(isnull(План, 0) , '#,0', 'en-US')
from nums_perc 

)
, texts as (
select *, case
when Тип='comissions' then Продукт+': '+char(10)+Прибыль_текст +char(10)
when Тип='ПШ' and is_total=0 then Продукт+': '+char(10)+Сумма_текст+char(10) +Доля_Текст+char(10)+Прибыль_текст+char(10)
when Тип='ПШ' and is_total=1 then Продукт+': '+char(10)+Сумма_текст +char(10)+Прибыль_текст+char(10)
when Тип='ECommPay продукт' and is_total=0 then Продукт+': '+char(10)+Сумма_текст +char(10)+Прибыль_текст+char(10)+Доля_Текст+char(10)
when Тип='КП' then Продукт+': '+char(10)+Прибыль_текст +char(10)+Доля_Текст+char(10) + Процент_выполнения_продукт_текст+char(10)
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
, [Вид займа]  
, b.источник
, b.productType
, b.contractSum contractSum
, b.contractInterestRate contractInterestRate
, b.contractSigned
, b.regionRegistration
into #fa


from v_fa		b 
where (cast([Заем выдан]   as date ) between '20180101' and getdate()  or ДатаЗаявкиПолная >=getdate()-10 or approved>=getdate()-10 or (b.productType = 'AUTOCREDIT' and b.contractSigned is not null and b.contractSum is not null)
) and status <> 'Заем аннулирован' 

--select * from #fa  a
--order by a.Номер desc

drop table if exists #t1
select ДатаВыдачи, Сумма, СтавкаНаСумму, код, Канал, IsInstallment, [Вид займа], [СуммаДопУслуг_without_partner_bounty_net]  into #t1 from v_loan_report 
where ДатаВыдачи between '20180101' and getdate()
and ishistory=0



;
with v as (select *, ROW_NUMBER() over(partition by код order by [СуммаДопУслуг_without_partner_bounty_net] desc) rn from  #t1 ) delete from v where rn>1

drop table if exists #re

select a.[Номер заявки], a.[Канал от источника]
, case when b.[Группа каналов] ='cpa' then b.[Канал от источника] else b.[Группа каналов] end Канал
, case  when  b.[Группа каналов] ='cpa' then  b.[Группа каналов]  else b.[Канал от источника] end Канал2
into #re
from stg.files.channelrequestexceptions_buffer_stg a  join stg.files.leadRef1_buffer b on a.[Канал от источника]=b.[Канал от источника]


drop table if exists #f


select
       case when f.productType = 'AUTOCREDIT'    and  f.contractSum is not null and f.contractSigned is not null then f.contractSigned else  ДатаВыдачи end ДатаВыдачи                                               
,       case when f.productType = 'AUTOCREDIT'    and  f.contractSum is not null and f.contractSigned is not null then f.contractSum else   cast(Сумма as bigint)        end Сумма                                               
--,     cast(Сумма as bigint)                                 Сумма
,     case when f.productType = 'AUTOCREDIT'    and  f.contractSum is not null and f.contractSigned is not null then f.contractSum * f.contractInterestRate  else  СтавкаНаСумму      end     СтавкаНаСумму                                            
,     isnull( код     ,  f.Номер  ) Код
, case 
when f.источник  like 'infoseti%' then 'Банки' when f.Источник like 'vtb-lkd%' then 'ПСБ Финанс' 
when f.Источник = 'eCredit' then f.Источник

   else     isnull( f.Канал , a.Канал)    

end             Канал
, case  when f.источник  like 'infoseti%' then 'Инфосети'  

when f.Источник like  'sravniru%'  and  f.productType='BIG INST'  then 'SRAVNIRU'
when f.Источник like  'bankiru%'  and  f.productType='BIG INST'  then 'BANKIRU'

else    f.Канал2        end            Канал2
,   isnull(   IsInstallment                                            , case when f.productType='AUTOCREDIT' then 0 end) IsInstallment
,      ISNULL(ISNULL(f.[Вид займа], a.[Вид займа]), 'Первичный') [Вид займа]
,     isnull( [СуммаДопУслуг_without_partner_bounty_net]        , 0) [СуммаДопУслуг_without_partner_bounty_net]
,     isnull( f.productType, '') productType
, f.regionRegistration

into #f
from      #t1 a
--left join #re b on a.Код=b.[Номер заявки]
full outer join #fa f on a.Код=f.Номер
where a.ДатаВыдачи is not null or (f.contractSigned is not null and f.productType='AUTOCREDIT' and  f.contractSum is not null )

--select * from #f except 
--select * from [оперативная витрина с выдачами и каналами]
--SELECT * 
--	from #f
--	where Канал2 like '%' + 'инфо' + '%'
--	order by 1 desc

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



	--select * into [оперативная витрина с выдачами и каналами backup] from [оперативная витрина с выдачами и каналами]

	--select *  from [оперативная витрина с выдачами и каналами] a
	----left join [оперативная витрина с выдачами и каналами backup] b on a.код=b.код
	--order by a.код desc
	
	--select *  from [оперативная витрина с выдачами и каналами backup] a
	----left join [оперативная витрина с выдачами и каналами backup] b on a.код=b.код
	--order by a.код desc


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
	, Канал3 varchar(100)
);
;


 

insert into  #chpl

select * ,  Канал3 = case when [Канал от источника]  in ('ПСБ', 'Т-Банк', 'Инфосети') then [Канал от источника] else 'Кармани' end  from (
select Месяц, Дата, case when b.[Канал от источника] = 'Инфосети' then 'Банки' when b.[Группа каналов]='cpa' then b.[Канал от источника] else b.[Группа каналов] end [Канал] , b.[Канал от источника], [Тип продукта], [Выданная сумма ПТС] from sale_plan_channel_view b
 
  union all
select Месяц, Дата, [Вид займа],[Вид займа], 'Беззалог', [Выданная сумма Инст] from [v_План по каналам_инст]
where year(Месяц)<=	year(getdate())

)
x
--insert into  #chpl

--select   [Месяц]  
--    , [Дата]  
--    , null [Канал]  
--    , 'Инфосети' [Канал от источника] 
--    , [Тип продукта] 
--    , [Выданная сумма]  *( 60000000 /  69792311.00 ) 

	
--	from #chpl 
--where Месяц='20250401' and [Канал от источника] = 'CPA целевой'



 
;



	
with plans as (
  select * from (
  SELECT 
       [День] день
     ,product = 'ПТС'
      ,cast([Сумма]  as float) [Сумма]

	from sale_plan_view
	union all  
	SELECT 
       [День]
     ,product = 'Беззалог'
      ,cast([Сумма инстоллмент] as float)  [Сумма]
	from sale_plan_view
	
	union all  
	SELECT 
       [День]
     ,product = 'Бизнес инвест'
      ,cast([Сумма Бизнес инвест]  as float) [Сумма]

	from sale_plan_view
	union all  
	SELECT 
       [День]
     ,product = 'Автокредит'
      ,cast([Сумма автокредит]  as float) [Сумма]

	from sale_plan_view
	union all  
	SELECT 
       [День]
     ,product = 'Большой инст'
      ,cast([Сумма Большой инст]  as float) [Сумма]

	from sale_plan_view

	 
--	union
--select '12.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*7.17   UNION
--select '13.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*6.07	UNION
--select '14.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*9.33	UNION
--select '15.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*7.92	UNION
--select '16.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*7.79	UNION
--select '17.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*11.77	UNION
--select '18.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*12.1	UNION
--select '19.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*13.12	UNION
--select '20.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*12.98	UNION
--select '21.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*12.33	UNION
--select '22.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*7.92	UNION
--select '23.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*7.79	UNION
--select '24.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*12.37	UNION
--select '25.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*12.72	UNION
--select '26.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*13.79	UNION
--select '27.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*13.64	UNION
--select '28.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*12.96	UNION
--select '29.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*8.32	UNION
--select '30.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*8.18	UNION
--select '31.03.2025' date, 'ПТС' PRODUCT, СУММА = 1000000*13		--UNION

  )pl
   where 1=1  
)
select * into #tmp_plans from plans



drop table if exists #facts


--select * from #facts
--where канал = 'ecredit'
--order by 1 desc


    SELECT cast([ДатаВыдачи] as date) [ДатаВыдачи]
    ,Код
	,cast([Сумма] as float)  [Сумма]
	,СтавкаНаСумму
    ,case when IsInstallment=1 then case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end  else Канал end Канал
    ,  Канал2 Канал2
	,product = case
	when productType='BIG INST' then 'Большой инст'
	when productType='AUTOCREDIT' then 'Автокредит'
	
	when IsInstallment=1 then 'Беззалог'
	      else  'ПТС'
	end
	, case when Канал2  in ('Инфосети', 'ПСБ' , 'Т-Банк') then Канал2 else 'Кармани' end Канал3
	
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
	, null

      FROM [Analytics].[dbo].[Бизнес инвест] --with(nolock)

	--  select * from #facts
	--  where product<>'ПТС'
	--  order by 1 desc

	--select * from [оперативная витрина с выдачами и каналами]
	--order by 1 desc


--declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
drop table if exists #final_text

;


with dates_base as (
select 'channels_today'   command , @report_date since, @report_date till union all
select 'channels_yesterday'    , dateadd(day, -1, @report_date), dateadd(day, -1, @report_date) union all
select 'channels_week'         ,  dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01')  , dateadd(day, 6, dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01') ) union all
select 'channels_month'        , cast(format(@report_date, 'yyyy-MM-01') as date), dateadd(day, -1, dateadd(month, 1, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'channels_lastmonth'        , dateadd(month, -1 , cast(format(@report_date, 'yyyy-MM-01') as date)) , dateadd(day, -1, dateadd(month, 0, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'channels_quarter'        , cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date),  dateadd(day , -1, dateadd(qq, 1, cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date)) )

)
, dates as (


select command ,  since , till, 1 isFull from dates_base union all
select command+'_short' ,  since , till , 0 isFull from dates_base --union all

)
,
channels as (
select 0 isFull,  '(ПСБ Финанс)'              channel, '' sub_channel, 'Кармани' group_channel3, 0.99 channel_order_num, product_of_channel = 'ПТС' union all
select 1 isFull,  'CPA нецелевой'        channel, '' sub_channel, '' group_channel3, 1.0 channel_order_num, product_of_channel = 'ПТС' union all
select 1 isFull,  'CPA полуцелевой'      channel, '' sub_channel, '' group_channel3, 2.0 channel_order_num, product = 'ПТС' union all
select 1 isFull,  'CPA целевой'          channel, '' sub_channel, '' group_channel3, 3.0 channel_order_num, product = 'ПТС' union all
select 1 isFull,  'CPC'                  channel, '' sub_channel, '' group_channel3, 4.0 channel_order_num, product = 'ПТС' union all
select 1 isFull,  'Партнеры'             channel, '' sub_channel, '' group_channel3, 5.0 channel_order_num, product = 'ПТС' union all
select 1 isFull,  'Органика'             channel, '' sub_channel, '' group_channel3, 6.0 channel_order_num, product = 'ПТС' union all
select 1 isFull,  'Триггеры'             channel, '' sub_channel, '' group_channel3, 6.5 channel_order_num, product = 'ПТС' union all
select 1 isFull,  'Телеком'              channel, '' sub_channel, '' group_channel3, 7.0 channel_order_num, product = 'ПТС' union all
select 1 isFull,  'Банки'                channel, '' sub_channel, '' group_channel3, 8.0 channel_order_num, product = 'ПТС' union all
--select '(ВТБ)'                    channel, 'ВТБ' sub_channel, '' group_channel3, 8.1 channel_order_num, product = 'ПТС' union all
--select '(Газпром)'                    channel, 'Газпром' sub_channel, '' group_channel3, 8.2 channel_order_num, product = 'ПТС' union all
--select '(Модуль)'                    channel, 'Модуль' sub_channel, '' group_channel3, 8.3 channel_order_num, product = 'ПТС' union all
--select '(МТС)'                    channel, 'МТС' sub_channel, '' group_channel3, 8.4 channel_order_num, product = 'ПТС' union all
--select '(Союз)'                  channel, 'Союз' sub_channel, '' group_channel3, 8.5 channel_order_num, product = 'ПТС' union all
--select '(Точка)'                  channel, 'Точка' sub_channel, '' group_channel3, 8.6 channel_order_num, product = 'ПТС' union all
--select '(Левобережный)'                  channel, 'Левобережный' sub_channel, '' group_channel3, 8.7 channel_order_num, product = 'ПТС' union all
select 0 isFull, '(ПСБ)'                    channel, 'ПСБ' sub_channel, '' group_channel3, 8.8 channel_order_num, product = 'ПТС' union all
select 0 isFull, '(Инфосети)'                    channel, 'Инфосети' sub_channel, '' group_channel3, 8.9 channel_order_num, product = 'ПТС' union all
select 0 isFull, '(Т-Банк)'                    channel, 'Т-Банк' sub_channel, '' group_channel3, 8.91 channel_order_num, product = 'ПТС' union all
select 0 isFull, 'Всего'                channel, '' sub_channel, '' group_channel3, 10.0 channel_order_num, product = 'ПТС' union all

select  0 isFull, 'ПСБ Финанс'                    channel, '' sub_channel, '' group_channel3, 0.8 channel_order_num, product = 'Автокредит' union all
select  0 isFull, 'eCredit'                    channel, '' sub_channel, '' group_channel3, 0.9 channel_order_num, product = 'Автокредит' union all

select  0 isFull, 'Всего'                channel, '' sub_channel, '' group_channel3, 1.0 channel_order_num, product = 'Автокредит' union all


select  1 isFull, 'Первичный'            channel, '' sub_channel, '' group_channel3, 1.0 channel_order_num, product = 'Беззалог' union all
select  1 isFull, 'Повторный'            channel, '' sub_channel, '' group_channel3, 2.0 channel_order_num, product = 'Беззалог' union all
 
--select '(ВТБ)'                  channel, 'ВТБ' sub_channel, '' group_channel3, 8.1 channel_order_num, product = 'Беззалог' union all
--select '(Газпром)'                  channel, 'Газпром' sub_channel, '' group_channel3, 8.2 channel_order_num, product = 'Беззалог' union all
--select '(Модуль)'                  channel, 'Модуль' sub_channel, '' group_channel3, 8.3 channel_order_num, product = 'Беззалог' union all
--select '(МТС)'                  channel, 'МТС' sub_channel, '' group_channel3, 8.4 channel_order_num, product = 'Беззалог' union all
--select '(Союз)'                channel, 'Союз' sub_channel, '' group_channel3, 8.5 channel_order_num, product = 'Беззалог' union all
--select '(Точка)'                channel, 'Точка' sub_channel, '' group_channel3, 8.6 channel_order_num, product = 'Беззалог' union all
--select '(Левобережный)'                channel, 'Левобережный' sub_channel, '' group_channel3, 8.7 channel_order_num, product = 'Беззалог' union all
select 1 isFull, '(ПСБ)'                  channel, 'ПСБ' sub_channel, '' group_channel3, 8.8 channel_order_num, product = 'Беззалог' union all
select 1 isFull, '(Инфосети)'                    channel, 'Инфосети' sub_channel, '' group_channel3, 8.9 channel_order_num, product = 'Беззалог' union all
select 1 isFull, '(Т-Банк)'                    channel, 'Т-Банк' sub_channel, '' group_channel3, 8.91 channel_order_num, product = 'Беззалог' union all


select  0 isFull, 'Всего'                channel, '' sub_channel, '' group_channel3, 10.0 channel_order_num, product = 'Беззалог' union all
select  0 isFull, 'ПСБ Финанс'                channel, '' sub_channel, 'Кармани' group_channel3, 10.4 channel_order_num, product = 'Большой инст' union all
select  1 isFull,'(BANKIRU)'                channel, 'BANKIRU' sub_channel, '' group_channel3, 10.45 channel_order_num, product = 'Большой инст' union all
select  1 isFull,'(SRAVNIRU)'                channel, 'SRAVNIRU' sub_channel, '' group_channel3, 10.46 channel_order_num, product = 'Большой инст' union all
select  0 isFull, 'ПСБ'                channel, 'ПСБ' sub_channel, '' group_channel3, 10.5 channel_order_num, product = 'Большой инст' union all
select  0 isFull, 'Инфосети'                channel, 'Инфосети' sub_channel, '' group_channel3, 10.6 channel_order_num, product = 'Большой инст' union all
select  0 isFull, 'Т-Банк'                channel, 'Т-Банк' sub_channel, '' group_channel3, 10.7 channel_order_num, product = 'Большой инст' union all
select  0 isFull, 'Всего'                channel, '' sub_channel, '' group_channel3, 11.0 channel_order_num, product = 'Большой инст' union all

select  0 isFull, 'Всего'                channel, '' sub_channel, '' group_channel3, 12.0 channel_order_num, product = null --union all
   



)
, products as 
(

select 'ПТС'          product, 1 product_order_num union all
select 'Автокредит'          product, 2 product_order_num union all

select 'Беззалог'  product, 3 product_order_num union all
select 'Большой инст'  product, 4 product_order_num union all
select 'Всего'        product, 5 product_order_num --union all


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
, rr__проценты = case when command in ('channels_month', 'channels_lastmonth','channels_month_short', 'channels_lastmonth_short' ) and channel<>'Всего' /*and product='ПТС'*/  then x_facts.СуммаRR / nullif(x_plans_ch.СуммаRR_План_По_Каналам  , 0)
                      when command in ('channels_month', 'channels_lastmonth','channels_month_short', 'channels_lastmonth_short' ) and channel = 'Всего'  then x_facts.СуммаRR /  nullif( x_plans.Сумма_План_RR , 0)  end

, rr__рубли    = case when command in ('channels_month', 'channels_lastmonth','channels_month_short', 'channels_lastmonth_short') and channel<>'Всего' /*and product='ПТС'*/  then x_plans_ch.Сумма_План_По_Каналам* x_facts.СуммаRR / nullif(x_plans_ch.СуммаRR_План_По_Каналам  ,0)
                      when command in ('channels_month', 'channels_lastmonth','channels_month_short', 'channels_lastmonth_short') and channel = 'Всего'  then x_plans.Сумма_План* x_facts.СуммаRR / nullif( x_plans.Сумма_План_RR , 0)  end 

, процент_выполнения = case when channel<>'Всего' /*and product='ПТС'*/ then x_facts.Сумма / nullif(x_plans_ch.Сумма_План_По_Каналам  , 0)  
                            when channel='Всего'   then x_facts.Сумма / nullif(x_plans.Сумма_План  , 0)   end
from dates
cross join products 															    
 join channels	  on ( channels.product_of_channel=products.product or  (product='Всего'  and channels.product_of_channel is null	)) and channels.isFull<=dates.isFull 
outer apply (

select sum(Сумма) Сумма, count(*) Количество, avg(Сумма) Чек, sum(case when ДатаВыдачи<@report_date then Сумма end ) СуммаRR 
, isnull(sum(СтавкаНаСумму)/nullif(sum([Сумма]), 0), 0) Ставка
from facts f 
where 
    case when f.product=products.product then 1 when products.product = 'Всего'   then 1 end=1 
and case when f.Канал=channels.channel   and channels.sub_channel='' then 1
         when channels.channel = 'Всего'   then 1 
         when channels.sub_channel = f.Канал2  then 1 
         when channels.group_channel3 = f.Канал3  then 1 
		 
		 
		 end=1 
and f.ДатаВыдачи between dates.since and dates.till
) x_facts
outer apply (

select sum(chpl.[Выданная сумма]) Сумма_План_По_Каналам , sum(case when chpl.Дата<@report_date then chpl.[Выданная сумма] end ) СуммаRR_План_По_Каналам  from #chpl chpl
where 
   ( chpl.Канал = channels.channel or chpl.[Канал от источника] = channels.sub_channel or channels.group_channel3=chpl.Канал3 )
	and chpl.[Тип продукта]=products.product
	and chpl.Дата between dates.since and dates.till
	and chpl.[Тип продукта] in ('ПТС', 'Беззалог')
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
	 , case when  Количество>0 and isnull(product, '') <>  'Автокредит' then  'Ставка: '+ format(Ставка , '0.0', 'en-US')+'%'+char(10) else '' end Ставка_текст
	 , case when Сумма>0 then  '<b>'+'Выдано: '+format(Сумма , '#,0', 'en-US')+ ' руб.'+'</b>'+char(10) else '' end   Сумма_текст
	 , '<b>'+channel +': '+ format(Количество , '#,0', 'en-US')+ ' шт.' +'</b>'+char(10) Количество_текст
	 , case when  Количество>1  then 'Чек: '+format(Чек , '#,0', 'en-US')+ ' руб.'+char(10) else '' end Чек_текст
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
+ case when command  in ('channels_month', 'channels_lastmonth','channels_month_short', 'channels_lastmonth_short' ) and ( product in ('ПТС' , 'Беззалог', 'Автокредит' , 'Большой инст') ) then rr_текст else '' end 


+case when command  in ('channels_month', 'channels_lastmonth','channels_month_short', 'channels_lastmonth_short' ) then 
                                       case when channel='Всего' then [Сумма план всего_текст] when channel<>'Всего' and ( product in ('ПТС' , 'Беззалог', 'Автокредит', 'Большой инст'))  then [Сумма план канал_текст] else '' end 
									   
		when command not in ('channels_month', 'channels_lastmonth','channels_month_short', 'channels_lastmonth_short' ) then 
                                       case when channel='Всего' then [Сумма план всего_текст]  else '' end 
									   
									   
									   else '' end
+case when   product ='Всего' then  ''  else Чек_текст end 
+case when channel='Всего' and product <>'Всего' then Ставка_текст else '' end text_row
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
N'🚗💳 Автокредит:'+char(10)+ STRING_AGG(case when product='Автокредит' and (channel='Всего' or Количество>0 ) then text_row end , char(10)) within group(order by channel_order_num) +'—————————————'+char(10)+
+
N'💸 Беззалог:'+char(10)+ STRING_AGG(case when product='Беззалог' and (channel='Всего' or Количество>0 ) then text_row end , char(10)) within group(order by channel_order_num) +'—————————————'+char(10)+
+
N'💸 Большой инст:'+char(10)+ STRING_AGG(case when product='Большой инст' and (channel='Всего' or Количество>0 ) then text_row end , char(10)) within group(order by channel_order_num) +'—————————————'+char(10)+

+
N'💰 Все продукты:'+char(10)+ max(case when channel='Всего' and product='Всего' then text_row else '' end)  
 --+char(10)+'/'+max(command)
into #final_text
from texts
group by command

--select * from #r
--select * from  #final_text

update a set a.text = REPLACE(a.text, 'Инфосети' , 'РП Платформ') from #final_text a


--#final_text

 


DECLARE @dt DATETIME = getdate()-- DATEADD(HOUR, DATEDIFF(HOUR, 0, GETDATE()), 0); -- 11:00 срез

;WITH cte AS (
    SELECT 
        d.issuedSum AS approvedsum,
        ISNULL(d.productType, 'Прочее') as productType,
        CAST(a.end_time AS DATE) AS coolingDate
    FROM stg._lk.requests_cooling_off_info a
    LEFT JOIN v_request r ON a.request_id = r.lk_request_id
    JOIN v_loan_cmr d ON d.number = r.number
    WHERE r.status NOT IN ('Заем выдан', 'Заем аннулирован', 'Заем погашен')
      AND a.end_time > @dt
),
agg AS (
    SELECT 
        productType,
        coolingDate,
        COUNT(*) AS totalClients,
        SUM(approvedsum) AS totalSum,
        GROUPING(productType) AS is_total_prod,
        GROUPING(coolingDate) AS is_total_date
    FROM cte
    GROUP BY GROUPING SETS (
        (productType, coolingDate), -- Данные по продуктам
        (coolingDate),              -- Итого по дням (весь портфель)
        ()                          -- Абсолютно общий итог
    )
)
INSERT INTO #final_text
SELECT 'cooling',
    'На ' + CONVERT(CHAR(5), @dt, 108) + CHAR(13)+CHAR(10) +
    STRING_AGG(line, CHAR(13)+CHAR(10)) WITHIN GROUP (ORDER BY sort_order, productType, coolingDate)
FROM (
    SELECT 
        CASE 
            -- 1. Блок продуктов
            WHEN is_total_prod = 0 AND is_total_date = 0 THEN
                (CASE WHEN ROW_NUMBER() OVER(PARTITION BY productType ORDER BY coolingDate) = 1 
                      THEN CHAR(13)+CHAR(10) + UPPER(productType) + ':' + CHAR(13)+CHAR(10) ELSE '' END) +
                FORMAT(coolingDate, 'd MMM', 'ru-RU') + ' - ' + CAST(totalClients AS VARCHAR(10)) + ' кл. на сумму ' + FORMAT(totalSum, '#,0', 'en-US') + ' руб.'
            
            -- 2. Блок Итого по дням
            WHEN is_total_prod = 1 AND is_total_date = 0 THEN
                (CASE WHEN ROW_NUMBER() OVER(PARTITION BY is_total_prod, is_total_date ORDER BY coolingDate) = 1 
                      THEN CHAR(13)+CHAR(10) + 'ИТОГО:' + CHAR(13)+CHAR(10) ELSE '' END) +
                FORMAT(coolingDate, 'd MMM', 'ru-RU') + ' - ' + CAST(totalClients AS VARCHAR(10)) + ' кл. на сумму ' + FORMAT(totalSum, '#,0', 'en-US') + ' руб.'
            
            -- 3. Финальная строка
            WHEN is_total_prod = 1 AND is_total_date = 1 THEN
                CHAR(13)+CHAR(10) + 'На общую сумму: ' + FORMAT(totalSum, '#,0', 'en-US') + ' руб.'
        END as line,
        -- Техническая сортировка: сначала продукты (0), потом Итого (1), потом Финал (2)
        CASE 
            WHEN is_total_prod = 0 AND is_total_date = 0 THEN 0 
            WHEN is_total_prod = 1 AND is_total_date = 0 THEN 1
            ELSE 2 
        END as sort_order,
        productType,
        coolingDate
    FROM agg
) sub
WHERE line IS NOT NULL;


--SELECT 'cooling' ,
--    'На ' + CONVERT(CHAR(5), @dt, 108) + CHAR(13)+CHAR(10) +
--    STRING_AGG(
--        'Период охлаждения ' + CAST(p.period AS VARCHAR(10)) + ' ч.: ' +
--        CAST(ISNULL(a.totalClients,0) AS VARCHAR(10)) + ' кл. на сумму ' +
--        format(ISNULL(a.totalSum,0)  , '#,0', 'en-US') +' руб.' +
--        CASE WHEN a.totalClients>0 
--             THEN ', в т.ч. сегодня ' + CAST(ISNULL(a.todayClients,0) AS VARCHAR(10)) + 
--                  ' кл.'+ case when todaySum>0 then  ' на сумму ' + format(ISNULL(a.todaySum,0)  , '#,0', 'en-US') +' руб.' else '' end
--             ELSE '' END
--    , CHAR(13)+CHAR(10)) within group(order by period)
--FROM periods p
--LEFT JOIN agg a ON p.period = a.coolingPeriod;

 
 
  
insert into  #final_text


SELECT 'budget' ,
    isnull( (select fullTextTelegram from Analytics.dbo.[sale_report_budget_plan_fact]), 'Нет данных' )


insert into  #final_text

SELECT 'get_psb_stat' ,
    isnull( (select fullTextPsbTelegram from Analytics.dbo.[sale_report_budget_plan_fact]), 'Нет данных' )
	 
--declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end DECLARE @dt DATETIME = getdate()
drop table if exists #psb
 
 drop table if exists #cooling_psb
 SELECT 
       sum( d.issuedSum)  AS  sum ,
	   count(*) cnt ,
	    sum( case when cast(a.end_time as date) = cast(getdate() as date) then  d.issuedSum else 0 end)  AS  sumToday ,
	    sum( case when cast(a.end_time as date) = cast(getdate() as date) then 1 else 0  end)  AS  cntToday 
 	   into #cooling_psb
    FROM stg._lk.requests_cooling_off_info a
      JOIN v_fa r ON a.request_id = r.id
    JOIN v_loan_cmr d ON d.number = r.number --and 1=0
    WHERE r.status NOT IN ('Заем выдан', 'Заем аннулирован', 'Заем погашен')
      AND a.end_time > @dt
	  and r.productType = 'big inst'
	  and r.channel='ПСБ'



drop table if exists #lead_psb
select cast(created as date) date, cast( count(*) as float) cntLead  into #lead_psb from _lead_request where isBigInstallmentLead=1 and isnull(rn, 1) =1
--and 1=0

 group by  cast(created as date)
 --select * from #lead_psb order by 1

drop table if exists #request_psb
select cast(call1 as date) date, cast( count(*) as float) cntRequest,cast(  count(call1approved)  as float)cntCall1Approved, cast( count(approved) as float) cntApproved , count(call15approved) call15approved



into #request_psb from request  with(nolock) where productType='big inst' and source like 'psb%'
--and 1=0
group by  cast(call1 as date)
 


declare @rr float = isnull((select rr_pts from sale_plan_run_rate), 0)
 ;

 

with dates as (
select 'psb_bi_today'   command , @report_date since, @report_date till union all
select 'psb_bi_week'         ,  dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01')  , dateadd(day, 6, dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01') ) union all
select 'psb_bi_month'        , cast(format(@report_date, 'yyyy-MM-01') as date), dateadd(day, -1, dateadd(month, 1, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'psb_bi_year'        , cast(DATEADD(YEAR   , DATEDIFF(YEAR   , 0, @report_date), 0) as date),  dateadd(day , -1, dateadd(YEAR, 1, cast(DATEADD(YEAR   , DATEDIFF(YEAR   , 0, @report_date), 0) as date)) ) union all
select 'psb_bi_yesterday'    , dateadd(day, -1, @report_date), dateadd(day, -1, @report_date) union all
select 'psb_bi_lastmonth'        , dateadd(month, -1 , cast(format(@report_date, 'yyyy-MM-01') as date)) , dateadd(day, -1, dateadd(month, 0, cast(format(@report_date, 'yyyy-MM-01') as date) )) union all
select 'psb_bi_quarter'        , cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date),  dateadd(day , -1, dateadd(qq, 1, cast(DATEADD(qq   , DATEDIFF(qq   , 0, @report_date), 0) as date)) )

)
, dates_fact  as (
select a.command, a.since, a.till, sum( isnull(Сумма, 0) ) sumLoanFact, sum(isnull(СуммаДопУслуг_without_partner_bounty_net, 0) ) addProductSumNetFact, isnull(sum(СтавкаНаСумму/100.0) / nullif((sum(Сумма)+0.0) ,0) , 0) interestRateFact 
, sum(case when b.regionRegistration in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ') then Сумма else 0 end) sumLoanNewRegionFact
, avg(isnull(Сумма, 0) ) avgLoanFact
, count(Сумма) cntLoanFact
, isnull(x.cntLead            , 0) cntLeadFact
, isnull(x1.cntRequest        , 0) cntRequestFact
, isnull(x1.cntApproved       , 0) cntApprovedFact 
, isnull(x1.cntCall1Approved  , 0) cntCall1ApprovedFact


--'Севастополь г', 'Крым Респ' ,
from dates a
outer apply (select sum( cntLead ) cntLead from #lead_psb c where c.date Between a.since and a.till  ) x
outer apply (select sum( cntRequest ) cntRequest, sum( cntApproved  ) cntApproved, sum( cntCall1Approved ) cntCall1Approved from #request_psb c1 where c1.date Between a.since and a.till  ) x1
left join [оперативная витрина с выдачами и каналами] b on b.ДатаВыдачи Between a.since and a.till and b.productType='big inst' and b.Канал2 = 'ПСБ'-- and 1=0
group by a.command, a.since, a.till , x.cntLead, x1.cntRequest, x1.cntApproved, x1.cntCall1Approved
)

, v_final as (
select a.command, a.since, a.till
,     sumLoanFact
,     sumLoanFact/@rr sumLoanRR
, addProductSumNetFact,  interestRateFact     
, sumLoanNewRegionFact
, avgLoanFact
, cntLoanFact
, cntRequestFact
, cntApprovedFact
, cntCall1ApprovedFact
, cntLeadFact
, sum(sumLoan)    sumLoanPlan,  sum(addProductSumNet)  addProductSumNetPlan,  isnull( sum(interestRateSum) /nullif((sum(sumLoan)+0.0) ,0) , 0) interestRatePlan  
,   isnull( sum(sumLoan) /nullif((sum(cntLoan)+0.0) ,0) , 0) avgLoanPlan  
, sum(cntLoan)  cntLoanPlan 
, sum(cntRequest)  cntRequestPlan  
, sum(cntCall1Approved)  cntCall1ApprovedPlan  
, sum(cntApproved)  cntApprovedPlan  
, sum(cntLead)  cntLeadPlan   
from dates_fact a
left join [sale_plan_channel_budget_view_new] b on b.date Between a.since and a.till and b.productType='big inst' and b.channel  = 'ПСБ'

group by  a.command, a.since, a.till,     sumLoanFact, addProductSumNetFact,  interestRateFact , sumLoanNewRegionFact ,  avgLoanFact
, cntLoanFact
, cntRequestFact
, cntApprovedFact
, cntCall1ApprovedFact
,cntLeadFact

)
--select * from v_final


select  command , 
   max(case when since<>till then N'📆' else N'📅' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' ) +
    CHAR(10) + CHAR(10) +
      STRING_AGG( 
      case when since <> cast(getdate() as date)  then 'Заявки: факт <b>' + format(cntRequestFact, 'N0') + '</b> | план <b>' + format(cntRequestPlan, 'N0') + '</b>'  + ' (<code>' + format(cntRequestFact / cntRequestPlan, 'P1') + '</code>)'  + CHAR(10) else '' end +  
        'Сумма факт: <b>' + format(sumLoanFact, 'N0') +'</b>' + CHAR(10) +
        'Сумма план: <b>' + format(sumLoanPlan, 'N0') + '</b>'    + ' (<code>' + format(sumLoanFact * 1.0 / sumLoanPlan, 'P1') +'</code>)' + CHAR(10) +
     case when command = 'psb_bi_month' and since <> cast(getdate() as date) then   'RR: <b>' + format(sumLoanRR, 'N0') + '</b> (<code>' + format(sumLoanRR / sumLoanPlan, 'P1') + '</code>)' + CHAR(10)    else '' end +
		'Доля НС: <code>' + format( isnull( sumLoanNewRegionFact / nullif( sumLoanFact , 0), 0 )  , 'P1') + '</code>' + CHAR(10) +
        'Кол-во: факт <b>' + format(cntLoanFact, 'N0') + '</b> | план <b>' + format(cntLoanPlan, 'N0') + '</b>'  + ' (<code>' + format(cntLoanFact / cntLoanPlan, 'P1') + '</code>)'  + CHAR(10) +  
        'Ср. чек: факт <b>' + format(avgLoanFact, 'N0') + '</b> | план <b>' + format(avgLoanPlan, 'N0') + '</b>' + CHAR(10) +  
      case when since <> cast(getdate() as date) then    '%AR пр.одобр.: факт <code>' + format( isnull(cntCall1ApprovedFact / nullif( cntRequestFact ,0) ,0) , 'P1') + '</code> | план <code>' + format(cntCall1ApprovedPlan / cntRequestPlan , 'P1') + '</code>' + CHAR(10)  else '' end +  
      case when since <> cast(getdate() as date) then    '%CR из лида: факт <code>' + format( isnull(cntLoanFact / nullif( cntLeadFact, 0) ,0) , 'P1') + '</code> | план <code>' + format(cntLoanPlan / cntLeadPlan , 'P1') + '</code>' + CHAR(10)  else '' end +  

        'КП net факт: <b>' + format(addproductSumNetFact, 'N0') + '</b>'   + CHAR(10) +
        'КП net план: <b>' + format(addProductSumNetPlan, 'N0') + '</b>'  + '<code> (' + format(isnull(addproductSumNetFact * 1.0 / nullif(addProductSumNetPlan, 0), 0), 'P1') + ')</code>' + CHAR(10) +
        'Доля КП net: факт <code>' + format(isnull( addproductSumNetFact / nullif( sumLoanFact, 0) ,0) , 'P1') + '</code> | план <code>' + format(addProductSumNetPlan / sumLoanPlan, 'P1') + '</code>' + CHAR(10) +  
        'Ставка: факт <code>' + format(interestRateFact, 'P1') + '</code> | план <code>' + format(interestRatePlan, 'P1') + '</code>' + CHAR(10)  
   
  , CHAR(10))

  
  +
  max( case when cp.sum >0 then N'
❄️Охлаждение: <b>'+ format( cp.sum , 'N0')  + ' руб.</b> <b>('+ format( cp.cnt , 'N0')+' кл.)</b>' +case when cp.sumToday >0 then '
В т.ч. сегодня: <b>'+ format( cp.sumToday , 'N0')  + 'руб.</b> <b>('+ format( cp.cntToday , 'N0')+' кл.)</b>'  else '' end   else '' end) 
  
  as fullTextPsbTelegram 
  into #psb
  from v_final a join #cooling_psb cp on 1=1
  group by a.command

insert  into  #final_text
select * from #psb




begin tran
truncate table  [оперативная витрина с выдачами и каналами агрегаты]
--drop table if exists [оперативная витрина с выдачами и каналами агрегаты]
--select * into [оперативная витрина с выдачами и каналами агрегаты] from  #r
insert  into  [оперативная витрина с выдачами и каналами агрегаты] 
select * from #final_text
commit tran

--select * from [оперативная витрина с выдачами и каналами агрегаты]

--declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end

--exec msdb.dbo.sp_stop_job  @job_name= 'Analytics._bot_analytics upd cache $Daily at 07:05 till 23:59  every 3 Minutes$'--STOP 
--exec msdb.dbo.sp_start_job  @job_name= 'Analytics._bot_analytics upd cache $Daily at 07:05 till 23:59  every 3 Minutes$', @step_name = 'Шаг 1. Подготовка витрины'

--bot_anal
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
, isnull([Выдано всего автокредит], 0)  [Выдано всего автокредит]
, isnull([Выдано всего БИ], 0)  [Выдано всего БИ]
, isnull([Выдано всего всего], 0)  [Выдано всего всего]

 

from 
(
select cast(                       DATEADD(month, DATEDIFF(month,0, @report_date), 0)   as date) [Дата выдачи месяц] union all
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
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего инст]
, sum(case when  1=1 and producttype not in ('AUTOCREDIT', 'BIG INST') then Сумма end) [Выдано всего ПТС инст]
, sum(case when   producttype   in ('AUTOCREDIT') and 1=1 then Сумма end) [Выдано всего автокредит]	
, sum(case when   producttype   in ('BIG INST') and 1=1 then Сумма end) [Выдано всего БИ]	
, sum(case when  1=1  then Сумма end) [Выдано всего всего]

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null --and producttype not in ('AUTOCREDIT', 'BIG INST')
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
, isnull([Выдано всего автокредит], 0)  [Выдано всего автокредит]
, isnull([Выдано всего БИ], 0)  [Выдано всего БИ]
, isnull([Выдано всего всего], 0)  [Выдано всего всего]

 

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
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего инст]
, sum(case when  1=1 and producttype not in ('AUTOCREDIT', 'BIG INST') then Сумма end) [Выдано всего ПТС инст]
, sum(case when   producttype   in ('AUTOCREDIT') and 1=1 then Сумма end) [Выдано всего автокредит]	
, sum(case when   producttype   in ('BIG INST') and 1=1 then Сумма end) [Выдано всего БИ]	
, sum(case when  1=1  then Сумма end) [Выдано всего всего]

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null --and producttype not in ('AUTOCREDIT', 'BIG INST')
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
, isnull([Выдано всего автокредит], 0)  [Выдано всего автокредит]
, isnull([Выдано всего БИ], 0)  [Выдано всего БИ]
, isnull([Выдано всего всего], 0)  [Выдано всего всего]

 
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
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего инст]
, sum(case when  1=1 and producttype not in ('AUTOCREDIT', 'BIG INST') then Сумма end) [Выдано всего ПТС инст]
, sum(case when   producttype   in ('AUTOCREDIT') and 1=1 then Сумма end) [Выдано всего автокредит]	
, sum(case when   producttype   in ('BIG INST') and 1=1 then Сумма end) [Выдано всего БИ]	
, sum(case when  1=1  then Сумма end) [Выдано всего всего]

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null-- and producttype not in ('AUTOCREDIT', 'BIG INST')
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
, isnull([Выдано всего автокредит], 0)  [Выдано всего автокредит]
, isnull([Выдано всего БИ], 0)  [Выдано всего БИ]
, isnull([Выдано всего всего], 0)  [Выдано всего всего]

 
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


select cast([ДатаВыдачи] as date) [Дата выдачи день] 
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего инст]
, sum(case when  1=1 and producttype not in ('AUTOCREDIT', 'BIG INST') then Сумма end) [Выдано всего ПТС инст]
, sum(case when   producttype   in ('AUTOCREDIT') and 1=1 then Сумма end) [Выдано всего автокредит]	
, sum(case when   producttype   in ('BIG INST') and 1=1 then Сумма end) [Выдано всего БИ]	
, sum(case when  1=1  then Сумма end) [Выдано всего всего]

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null
group by  cast([ДатаВыдачи] as date)
--Order by 1 desc
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
, isnull([Выдано всего автокредит], 0)  [Выдано всего автокредит]
, isnull([Выдано всего БИ], 0)  [Выдано всего БИ]
, isnull([Выдано всего всего], 0)  [Выдано всего всего]

 

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
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные]
, sum(case when IsInstallment=0  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего]	
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]='Первичный'  then Сумма end)  [Выдано первичные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and [вид займа]<>'Первичный' then Сумма end) [Выдано повторные инст]
, sum(case when IsInstallment=1  and producttype not in ('AUTOCREDIT', 'BIG INST') and 1=1 then Сумма end) [Выдано всего инст]
, sum(case when  1=1 and producttype not in ('AUTOCREDIT', 'BIG INST') then Сумма end) [Выдано всего ПТС инст]
, sum(case when   producttype   in ('AUTOCREDIT') and 1=1 then Сумма end)              [Выдано всего автокредит]	
, sum(case when   producttype   in ('BIG INST') and 1=1 then Сумма end)                [Выдано всего БИ]	
, sum(case when  1=1  then Сумма end) [Выдано всего всего]



from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null --and producttype not in ('AUTOCREDIT', 'BIG INST')
group by cast(format([ДатаВыдачи], 'yyyy-01-01') as date)
--order by cast(DATEADD(wk, DATEDIFF(wk,0, [Дата выдачи день]), 0) as date)
) d on ws.[Дата выдачи день]=d.[Дата выдачи день]
where year(ws.[Дата выдачи день])>=2018
order by ws.[Дата выдачи день]
for json auto ) ) 

union all


select 'chart_psb_bi_month' command , 
text = 

(select (


select format(ws.[Дата выдачи месяц], 'MMM-yy') [Дата выдачи месяц], '#000000'  as [x font color]
, isnull([Выдано НС], 0) [Выдано НС] 
, isnull([Выдано прочие регионы], 0) [Выдано прочие регионы]
, isnull([Выдано всего], 0)  [Выдано всего] 
, [Выдано НС] / nullif([Выдано всего], 0) [Доля НС]

, isnull([Шт НС], 0) [Шт НС] 
, isnull([Шт прочие регионы], 0) [Шт прочие регионы]
, isnull([Шт всего], 0)  [Шт всего]


, [Чек НС] /1000.0 [Чек НС] 
, [Чек прочие регионы] /1000.0  [Чек прочие регионы]
, [Чек всего]/1000.0   [Чек всего]

from 
(
select cast(                       DATEADD(month, DATEDIFF(month,0, @report_date), 0)   as date) [Дата выдачи месяц] union all
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
, sum(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Выдано НС]
, sum(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Выдано прочие регионы]
, sum(case when 1=1 then Сумма end) [Выдано всего]	 


, count(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Шт НС]
, count(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Шт прочие регионы]
, count(case when 1=1 then Сумма end) [ШТ всего]	 
	 
, avg(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Чек НС]
, avg(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Чек прочие регионы]
, avg(case when 1=1 then Сумма end) [Чек всего]	  

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and producttype   in (  'BIG INST') and Канал2 = 'ПСБ'
group by DATEADD(month, DATEDIFF(month,0, [ДатаВыдачи]), 0) 

) d on ws.[Дата выдачи месяц]=d.[Дата выдачи месяц]
--where ws.[Дата выдачи месяц]>='20220501'
order by ws.[Дата выдачи месяц]
for json auto ) )
 
union all				


select 'chart_psb_bi_quarter' command , 
text = 

(select (


select CAST(year(ws.[Дата выдачи квартал]) AS char(4)) + '-Q' + 
CAST(CEILING(CAST(month(ws.[Дата выдачи квартал]) AS decimal(9,2)) / 3) AS char(1)) [Дата выдачи квартал]
, '#000000'  as [x font color]
, isnull([Выдано НС], 0) [Выдано НС] 
, isnull([Выдано прочие регионы], 0) [Выдано прочие регионы]
, isnull([Выдано всего], 0)  [Выдано всего] 
, [Выдано НС] / nullif([Выдано всего], 0) [Доля НС]

, isnull([Шт НС], 0) [Шт НС] 
, isnull([Шт прочие регионы], 0) [Шт прочие регионы]
, isnull([Шт всего], 0)  [Шт всего]


, [Чек НС] /1000.0 [Чек НС] 
, [Чек прочие регионы] /1000.0  [Чек прочие регионы]
, [Чек всего]/1000.0   [Чек всего]

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
, sum(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Выдано НС]
, sum(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Выдано прочие регионы]
, sum(case when 1=1 then Сумма end) [Выдано всего]	 

, count(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Шт НС]
, count(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Шт прочие регионы]
, count(case when 1=1 then Сумма end) [ШТ всего]	 
	 
, avg(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Чек НС]
, avg(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Чек прочие регионы]
, avg(case when 1=1 then Сумма end) [Чек всего]	 

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and producttype   in (  'BIG INST') and Канал2 = 'ПСБ'
group by cast(DATEADD(qq   , DATEDIFF(qq   , 0, [ДатаВыдачи]), 0) as date) 

) d on ws.[Дата выдачи квартал]=d.[Дата выдачи квартал]
--where ws.[Дата выдачи месяц]>='20220501'
order by ws.[Дата выдачи квартал]
for json auto ) )
 
union all
-----------------------------------------
-----------------------------------------
-- declare @today date = getdate()
select 'chart_psb_bi_week' command , 
text = 

(select (


select format(ws.[Дата выдачи неделя], 'dd.MMM')+' - '+format(dateadd(day, 6 ,ws.[Дата выдачи неделя]), 'dd.MMM') [Дата выдачи неделя], '#000000'  as [x font color] 
, isnull([Выдано НС], 0) [Выдано НС] 
, isnull([Выдано прочие регионы], 0) [Выдано прочие регионы]
, isnull([Выдано всего], 0)  [Выдано всего] 
, [Выдано НС] / nullif([Выдано всего], 0) [Доля НС]

, isnull([Шт НС], 0) [Шт НС] 
, isnull([Шт прочие регионы], 0) [Шт прочие регионы]
, isnull([Шт всего], 0)  [Шт всего]


, [Чек НС] /1000.0 [Чек НС] 
, [Чек прочие регионы] /1000.0  [Чек прочие регионы]
, [Чек всего]/1000.0   [Чек всего]
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
, sum(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Выдано НС]
, sum(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Выдано прочие регионы]
, sum(case when 1=1 then Сумма end) [Выдано всего]	 
, count(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Шт НС]
, count(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Шт прочие регионы]
, count(case when 1=1 then Сумма end) [ШТ всего]	 
, avg(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Чек НС]
, avg(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Чек прочие регионы]
, avg(case when 1=1 then Сумма end) [Чек всего]	 

from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and producttype   in (  'BIG INST') and Канал2 = 'ПСБ'
group by dateadd(day, datediff(day, '1900-01-01', [ДатаВыдачи]) / 7 * 7, '1900-01-01')
--order by cast(DATEADD(wk, DATEDIFF(wk,0, [Дата выдачи день]), 0) as date)
) d on ws.[Дата выдачи неделя]=d.[Дата выдачи неделя]
order by ws.[Дата выдачи неделя]
for json auto ) )
union all
-----------------------------------------
-----------------------------------------
select 'chart_psb_bi_day' command , 
text = 

(select (


select format(ws.[Дата выдачи день], 'dd.MMM')  [Дата выдачи день] , case when datepart(dw, ws.[Дата выдачи день]) in (6,7) then '#FF0303' else '#000000'  end [x font color] 
, isnull([Выдано НС], 0) [Выдано НС] 
, isnull([Выдано прочие регионы], 0) [Выдано прочие регионы]
, isnull([Выдано всего], 0)  [Выдано всего] 
, [Выдано НС] / nullif([Выдано всего], 0) [Доля НС]

, isnull([Шт НС], 0) [Шт НС] 
, isnull([Шт прочие регионы], 0) [Шт прочие регионы]
, isnull([Шт всего], 0)  [Шт всего]

, [Чек НС] /1000.0 [Чек НС] 
, [Чек прочие регионы] /1000.0  [Чек прочие регионы]
, [Чек всего]/1000.0   [Чек всего]
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
, sum(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Выдано НС]
, sum(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Выдано прочие регионы]
, sum(case when 1=1 then Сумма end) [Выдано всего]	 


, count(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Шт НС]
, count(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Шт прочие регионы]
, count(case when 1=1 then Сумма end) [ШТ всего]	 
, avg(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Чек НС]
, avg(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Чек прочие регионы]
, avg(case when 1=1 then Сумма end) [Чек всего]	 



from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and producttype   in (  'BIG INST') and Канал2 = 'ПСБ'
group by [ДатаВыдачи]
--order by cast(DATEADD(wk, DATEDIFF(wk,0, [Дата выдачи день]), 0) as date)
) d on ws.[Дата выдачи день]=d.[Дата выдачи день]
order by ws.[Дата выдачи день]
for json auto ) )
						 union all
-----------------------------------------
-----------------------------------------
select 'chart_psb_bi_year' command , 
text = 

(select (


select format(ws.[Дата выдачи день], 'yyyy')  [Дата выдачи год] 
, '#000000'  as [x font color] 
, isnull([Выдано НС], 0) [Выдано НС] 
, isnull([Выдано прочие регионы], 0) [Выдано прочие регионы]
, isnull([Выдано всего], 0)  [Выдано всего] 
, [Выдано НС] / nullif([Выдано всего], 0) [Доля НС]

, isnull([Шт НС], 0) [Шт НС] 
, isnull([Шт прочие регионы], 0) [Шт прочие регионы]
, isnull([Шт всего], 0)  [Шт всего]



, [Чек НС] /1000.0 [Чек НС] 
, [Чек прочие регионы] /1000.0  [Чек прочие регионы]
, [Чек всего]/1000.0   [Чек всего]
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
, sum(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Выдано НС]
, sum(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Выдано прочие регионы]
, sum(case when 1=1 then Сумма end) [Выдано всего]	 

, count(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Шт НС]
, count(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Шт прочие регионы]
, count(case when 1=1 then Сумма end) [ШТ всего]	 	 
, avg(case when     isnull(regionRegistration, '')  in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')   then Сумма end) [Чек НС]
, avg(case when    isnull(regionRegistration, '') not in ('Херсонская обл',  'Донецкая Народная Респ' , 'Запорожская обл' ,  'Луганская Народная Респ')  then Сумма end) [Чек прочие регионы]
, avg(case when 1=1 then Сумма end) [Чек всего]	 



from [оперативная витрина с выдачами и каналами]
where [ДатаВыдачи] is not null and producttype   in (  'BIG INST') and Канал2 = 'ПСБ'
group by cast(format([ДатаВыдачи], 'yyyy-01-01') as date)
--order by cast(DATEADD(wk, DATEDIFF(wk,0, [Дата выдачи день]), 0) as date)
) d on ws.[Дата выдачи день]=d.[Дата выдачи день]
where year(ws.[Дата выдачи день])>=2018
order by ws.[Дата выдачи день]
for json auto ) ) 


---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------




alter table #gr alter column command varchar(100)

insert into  #gr 
-- declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
select 'chart_portfolio_month' command , 
text = 

(select (


select format(d.date, 'dd-MMM-yy') month, '#000000'  as [x font color]
, isnull([Портфель ПТС]       , 0) [Портфель ПТС]
, isnull([Портфель Автокредит], 0)     [Портфель Автокредит]
, isnull([Портфель беззалог]  , 0) [Портфель Беззалог]
, isnull(Портфель, 0)     Портфель
, isnull(shareActive, 0)     shareActive
, format(shareActive, '0.0%')+'
'+ format(sumActive/1000000, '0')  shareActiveDescr

from 
(
select cast(                       DATEADD(month, DATEDIFF(month,0, @report_date), 0)   as date)    month union all
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
  join (


select month      

, sum(case when Продукт = 'Инстоллмент' then [остаток од млн] end)  [Портфель беззалог]
, sum(case when Продукт = 'ПТС' then [остаток од млн] end)          [Портфель ПТС]
, sum(case when Продукт = 'AUTOCREDIT' then [остаток од млн] end)   [Портфель Автокредит]
, sum(case when 1=1 then [остаток од млн] end) Портфель	
, max(date) date
, sum(case when 1=1 then [остаток од активный млн] end)/ sum(case when 1=1 then [остаток од млн] end)    shareActive
, sum(case when 1=1 then [остаток од активный млн] end)     sumActive

from report_portfolio_month

group by month

) d on ws.month=d.month
--where ws.[Дата выдачи месяц]>='20220501'
order by ws.month
for json auto ) )


insert into  #gr 
-- declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
select 'chart_portfolio_week' command , 
text = 

(select (


select format(d.week_end, 'dd-MMM') week, '#000000'  as [x font color]
, isnull([Портфель ПТС]       , 0) [Портфель ПТС]
, isnull([Портфель Автокредит], 0)     [Портфель Автокредит]
, isnull([Портфель беззалог]  , 0) [Портфель Беззалог]
, isnull(Портфель, 0)     Портфель
, isnull(shareActive, 0)     shareActive
, format(shareActive, '0.0%')+'
'+ format(sumActive/1000000, '0')  shareActiveDescr

from 
(
select cast(                    dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01')       as DATE) week union all
select cast( DATEADD(wk ,  -1 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -2 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -3 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -4 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -5 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -6 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -7 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -8 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk ,  -9 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk , -10 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk , -11 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk , -12 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk , -13 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   union all
select cast( DATEADD(wk , -14 , dateadd(day, datediff(day, '1900-01-01', @report_date) / 7 * 7, '1900-01-01'))      as date)   --union all
) ws
  join (


select week      
, max(date) week_end
, sum(case when Продукт = 'Инстоллмент' then [остаток од млн] end)  [Портфель беззалог]
, sum(case when Продукт = 'ПТС' then [остаток од млн] end)          [Портфель ПТС]
, sum(case when Продукт = 'AUTOCREDIT' then [остаток од млн] end)   [Портфель Автокредит]
, sum(case when 1=1 then [остаток од млн] end) Портфель	
, sum(case when 1=1 then [остаток од активный млн] end)/ sum(case when 1=1 then [остаток од млн] end)    shareActive
, sum(case when 1=1 then [остаток од активный млн] end)     sumActive
from report_portfolio_week

group by week

) d on ws.week=d.week
--where ws.[Дата выдачи месяц]>='20220501'
order by ws.week
for json auto ) )



/*



drop table if exists #t1

select Месяц month, max(Дата) date into #t1 from v_Calendar where  Дата between dateadd(month, -15, getdate()) and getdate()
group by Месяц

drop table if exists #report_portfolio_month

select a.month  ,   a.date   , case when c.productType2='autocredit' then c.productType2 else  b.[Тип Продукта]  end Продукт, sum([остаток од])  [остаток од млн] 
into #report_portfolio_month from #t1 a
left join v_balance b on b.d=  a.date 
left join request c on c.number=b.number 
group by  a.month  ,   a.date  , case when c.productType2='autocredit' then c.productType2 else  b.[Тип Продукта]  end
order by 1 desc

drop table if exists  report_portfolio_month
select * into report_portfolio_month from #report_portfolio_month





drop table if exists #t2

select week week, max(date) date into #t2 from calendar_view where  date between dateadd(month, -5, getdate()) and getdate()
group by week

drop table if exists #report_portfolio_week

select a.week  ,   a.date   , case when c.productType2='autocredit' then c.productType2 else  b.[Тип Продукта]  end Продукт, sum([остаток од])  [остаток од млн] 
into #report_portfolio_week from #t2 a
left join v_balance b on b.d=  a.date 
left join request c on c.number=b.number 
group by  a.week  ,   a.date  , case when c.productType2='autocredit' then c.productType2 else  b.[Тип Продукта]  end
order by 1 desc

drop table if exists  report_portfolio_week
select * into report_portfolio_week from #report_portfolio_week





 
*/


 


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

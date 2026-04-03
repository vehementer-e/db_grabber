
create   proc [_loan_full_prepayment_creation]	 @mode nvarchar(max)='update'
as 


if @mode='update'
begin

drop table if exists 	#gr

  select 
    a.[Код]  
,   a.[НомерПлатежа] 
,   a.[ДатаПлатежа]  
,   a.[СуммаПлатежа] 
,   a.[ОД] 
,   a.[Процент]  
	 into #gr
from 

dwh2.dm.CMRExpectedRepayments a
where a.[ПризнакПоследнийПлатежИспытательныйСрок] <>1


drop table if exists 	#chdp

 select     Код, [Дата заявления на ЧДП день] into #chdp from [dbo].[v_Документ_ЗаявлениеНаЧДП]
group by   Код, [Дата заявления на ЧДП день] 

drop table if exists 	#t1

select  
  a.Код
, a.[Стоимость ТС]
, a.сумма
, a.product
, a.канал
--кп снижающее ставку
, a.[Вид займа]
, a.[Максимальная просрочка]
, a.[Дата выдачи]
, a.[Дата погашения]
, c.d
, [ДатаПлатежа]
, case when [ДатаПлатежа] is not null then isnull(lag([ДатаПлатежа]) over(partition by a.Код   order by   b.[ДатаПлатежа] )	, [Дата выдачи день]) end  [ДатаПлатежаПред]
, isnull(max(case when c.d<= b.[ДатаПлатежа] then b.[НомерПлатежа]  end ) over(partition by 	a.Код order by  c.d  ), 0)+case when [ДатаПлатежа] is null then 1 else 0 end 	 [Сколько платежей прошло]
, case when c1.[dpd начало дня] >=55 then c1.[dpd начало дня] end [Просрочка]
, sum(b.[Процент]  ) over(partition by 	a.Код order by   b.[ДатаПлатежа]  ) 	 [Проценты по графику нарастающим итогом]
, case when c.[Дата закрытия]>=b.[ДатаПлатежа] then '=>' end [Закрыт]
, c.[Проценты уплачено  нарастающим итогом]  

, c.[dpd начало дня]
into #t1
 from mv_loans 	 a
 left join v_balance c on c.Код=a.Код 
 left join	  #gr b on a.[Код]=b.[Код]	   and c.d=b.[ДатаПлатежа]
 left join v_balance c1 on c1.Код=a.Код 	  and c1.d=dateadd(day, 1, b.[ДатаПлатежа])

where a.ispts=1	  and product<>'Исп. срок' and a.[Дата выдачи]>='20230101'
order by  a.Код, c.d



drop table if exists 	#t2


select a.*, chdp.[Дата заявления на ЧДП день] into #t2 from #t1	  a
outer apply (
select top 1 * 
from	  #chdp chdp 
where a.[Код]=chdp.[Код]	   
and chdp.[Дата заявления на ЧДП день] between dateadd(day, 1, [ДатаПлатежаПред] 
) and [ДатаПлатежа] ) chdp  
order by   a.Код, d




drop table if exists 	#last_num_payment
	   
select [Код], max([НомерПлатежа]) [НомерПлатежа] into #last_num_payment from  #gr
where [ДатаПлатежа]<=getdate()
group by [Код]


drop table if exists 	#t3

select a.Код
,max( [Стоимость ТС])	[Стоимость ТС]
, product
, [Вид займа]
, max( cast([Дата выдачи] as date))    [Дата выдачи]
, max( cast([Дата погашения] as date))    [Дата погашения]
, max(b.НомерПлатежа)    [Сколько платежей прошло]
, max(case when ДатаПлатежа is not null then [Сколько платежей прошло] end)    [Сколько платежей прожил]
, min(case when ДатаПлатежа is not null and Просрочка>0 then [Сколько платежей прошло] end)    [На какой платеж ушел в просрочку]
, min([Дата заявления на ЧДП день])    [Дата заявления на ЧДП день]
, min(case when ДатаПлатежа is not null and [Дата заявления на ЧДП день] is not null then [Сколько платежей прошло] end)    [К какому платежу ЧДП]
, isnull( min(case when ДатаПлатежа is not null and (/*[Дата заявления на ЧДП день] is not null or */ Просрочка>0 ) then [Сколько платежей прошло] end) , max(b.НомерПлатежа)+1)   [Не по графику]
   into #t3
from #t2		a
left join #last_num_payment b on a.код=b.Код

group by a.Код
, product
, [Вид займа]


 drop table if exists  _loan_full_prepayment

select a.*
,1 [для знаменателя]
, f.[Признак страховка]
, f0.ПолКлиента
,case
when  case when f0.СуммарныйМесячныйДоход_CRM>1000 then  f0.СуммарныйМесячныйДоход_CRM end <=100000	 then '1) 0 .. 100000'
when  case when f0.СуммарныйМесячныйДоход_CRM>1000 then  f0.СуммарныйМесячныйДоход_CRM end <=200000	 then '2) 100000 .. 200000'
when  case when f0.СуммарныйМесячныйДоход_CRM>1000 then  f0.СуммарныйМесячныйДоход_CRM end <=300000	 then '3) 200000 .. 300000'
when  case when f0.СуммарныйМесячныйДоход_CRM>1000 then  f0.СуммарныйМесячныйДоход_CRM end <=400000	 then '4) 300000 .. 400000'
when  case when f0.СуммарныйМесячныйДоход_CRM>1000 then  f0.СуммарныйМесячныйДоход_CRM end >400000	 then '5) 400000 .. 10000000'
end [Доход бакет]
, case when f.[сумма Одобренная]<f.[Первичная сумма] then 'Порезанная сумма' else 'Одобрено больше запроса' end	 [Признак порезан]
, case when f.[сумма Одобренная]<f.[Первичная сумма] then f.[Первичная сумма]-f.[сумма Одобренная]  end	 [Порезанная сумма]
, case when f0.СуммарныйМесячныйДоход_CRM>1000 then  f0.СуммарныйМесячныйДоход_CRM end	 Доход

,case
when   f.[выданная сумма]<=200000  then '1) 0 .. 200000'
when   f.[выданная сумма]<=500000  then '2) 200000 .. 500000'
when   f.[выданная сумма]<=2000000 then '3) 500000 .. 1000000'	  
end [выданная сумма бакет]
, f0.[Первичная сумма]

, case
when   f.[Первичная сумма]<=200000  then '1) 0 .. 200000'
when   f.[Первичная сумма]<=500000  then '2) 200000 .. 500000'
when   f.[Первичная сумма]<=2000000 then '3) 500000 .. 1000000'	  
end    [Первичная сумма бакет]	  
, case
when   f.[сумма Одобренная]<=200000  then '1) 0 .. 200000'
when   f.[сумма Одобренная]<=500000  then '2) 200000 .. 500000'
when   f.[сумма Одобренная]<=2000000 then '3) 500000 .. 1000000'	  
end    [Одобренная сумма бакет]	 	  
, case
when   a.[Стоимость ТС]<=400000  then '1) 0 .. 400000'
when   a.[Стоимость ТС]<=1000000  then '2) 400000 .. 1000000'
when   a.[Стоимость ТС]<=2000000 then '3) 1000000 .. 2000000'	  
when   a.[Стоимость ТС]>2000000 then '4) 2000000+'	  
end    [Стоимость ТС бакет]
, f0.[сумма Одобренная]
, f0.[выданная сумма]
, f0.full_prepayment_30
, f0.РегионПроживания
, f0.Срок
, num
, case when [Сколько платежей прожил]>=num then 1 else 0 end [Прожил] 
, case when isnull([Не по графику], num-1)>num and [Сколько платежей прожил]>=num then 1 else 0 end [Не ушел в просрочку] 
,case when f.[Группа каналов]='cpa' then f.[Канал от источника] else f.[Группа каналов] end [Канал]
INTO _loan_full_prepayment
from #t3	a
left join  v_fa f on f.Номер=a.Код
left join  dm_Factor_Analysis f0 on f0.Номер=a.Код
join (
select datediff(day, Месяц, Дата ) num from v_Calendar
where Месяц='20230101' and Дата<='20230114'
) nums on 1=1
order by 1,  num

   end


   if @mode='select'
   begin
select *, format([Дата выдачи] ,'yyyy-MM-01' )   [Месяц выдачи] from _loan_full_prepayment

   end
    
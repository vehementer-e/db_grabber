
CREATE  		proc [dbo].[План факт инстоллмент]
@t nvarchar(max) = 'z'

as 
begin

if @t = 'z'

begin



--drop table if exists ##t2
select a.Номер
, datediff(month , b.[Заем выдан] , a.[Дата следующего займа в рамках продукта]) [Месяцев до следующего займа]	 
, 'L'+cast(case when  isnull( a.[Кол-во закрытых займов в рамках продукта], 0) +1 >5 then 5 else  isnull( a.[Кол-во закрытых займов в рамках продукта], 0) +1 end as nvarchar(10)) [l]
, b.Срок
, b.[Выданная сумма]
,  a.[Дата следующего займа в рамках продукта]
, b.ПроцСтавкаКредит
, b.[Заем выдан]
, b.[Признак заявки]
, b.[Признак Предварительное одобрение]
, b.[Признак Контроль данных]
, b.[Признак Заем выдан]
, d.[_90_12_CMR]
, c.marketingCosts [Маркетинговые расходы]
, case 
when  a.Отчетная_Дата>='20221101' then 'Новый портфель'
when  a.Отчетная_Дата>='20211101' then 'Старый портфель'	   end [Портфель]	
, case 
when  isnull(b.[Выданная сумма], b.[Первичная сумма] )>=15000 then  'Чек больше 15к'
else 'Чек меньше 15к' end [Чек]
	--   into ##t2
from return_types		    a
join mv_dm_Factor_Analysis b on a.Номер=b.Номер
left join [v_request_costs] c on c.number	=a.Номер
 left join [dwh2].[dbo].[dm_OverdueIndicators] d on d.Number=a.Номер
where b.isPts=0
   and Дубль=0

   end
   
if @t = 'b'

begin


drop table if exists #t1

select 

 datediff(month, [Дата выдачи Месяц],  [d Месяц]   )		 mob
, sum(case
when b.dpd between 1 and 90 then [остаток од] end)/ sum(b.Сумма) [доля 1..90]	  
, sum(case
when b.dpd >= 91 then [остаток од] end)/ sum(b.Сумма)	  [доля 91+]
, case 
when  a.Отчетная_Дата>='20221101' then 'Новый портфель'
when  a.Отчетная_Дата>='20211101' then 'Старый портфель'	   end [Портфель]	
, 
isnull(
case 
when   a.[Выданная сумма]  >=15000 then 'Чек больше 15к'
else 'Чек меньше 15к' end, 'Чек' ) [Чек]

into #t1	 --select top 1 *
from return_types	 a
join v_balance b  on a.Номер=b.Код and  EOMONTH(d)=d

where [Кол-во закрытых займов в рамках продукта]   is null	 
and [Признак заем выдан]=1
and b.isPts=0				    
 
 
group by 
   
 datediff(month, [Дата выдачи Месяц],  [d Месяц]   )	
 ,case 
when  a.Отчетная_Дата>='20221101' then 'Новый портфель'
when  a.Отчетная_Дата>='20211101' then 'Старый портфель'	   end
, case 
when   a.[Выданная сумма]  >=15000 then 'Чек больше 15к'
else 'Чек меньше 15к' end

with rollup 







 select * from #t1


   end



 end
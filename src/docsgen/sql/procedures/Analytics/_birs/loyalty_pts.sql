
CREATE     proc [_birs].[loyalty_pts]
  @mode nvarchar(max) = 'update'
as
begin

if @mode = 'update'

begin

 drop table if exists #calls
 select attempt_start,   '8'+right(client_number, 10) client_number into 	#calls from reports.dbo.dm_report_DIP_detail_outbound_sessions
 where login is not null


 
 drop table if exists #costs

select number, marketingCosts marketingCosts into #costs from v_request_costs


 drop table if exists #percents

select number , sum(percentsPaid) percentsPaid  into #percents from v_balance
group by number



drop table if exists  #t1
select a.*				 
, b.[Место создания 2] 
, b.product 
, b.[Верификация КЦ] 
, b.[Группа каналов] 
, b.[Канал от источника] 
, b.[Категория повторного клиента] 
,c.marketingCosts [Маркетинговые расходы]
,p.percentsPaid [Проценты уплачено]
into #t1
from return_types	a
join  reports.dbo.dm_Factor_Analysis_001 b on a.Номер=b.Номер
join  #costs c on a.Номер=c.number
join  #percents p on a.Номер=p.number
where  b.isPts=1
and [Признак заем выдан]=1

--select * from 	#t1


 drop table if exists #loyalty_pts


select a.Номер
, a.next_docr_product [Следующий докред]

, datediff(day,    a.[Заем выдан]  , b2.[Дата выдачи] )	[Следующий докред дней]  
, a.next_povt_product 	 [Следующий повторный]
, datediff(day,    a.[Заем выдан]  , b1.[Дата выдачи] )	[Следующий повторный дней]  
, datediff(day,   a.[Заем погашен] , b1.[Дата выдачи] )	[Следующий повторный дней с закрытия]		 
, isnull(a.[Кол-во закрытых займов в рамках продукта], 0)+1   [Лояльность]
, a.[Выданная сумма]
, case 
when a.[Выданная сумма]<=200000 then '1) чек 0..200k'
when a.[Выданная сумма]<=400000 then '2) чек 200k..400k'
when a.[Выданная сумма]>400000 then  '3) чек 400k..1kk'
end [Выданная сумма бакет]
, a.[Заем выдан]
, a.[Заем погашен]
, datediff(day,  a.[Заем выдан], a.[Заем погашен]) [Срок жизни]				  
, case 
when datediff(day,  a.[Заем выдан], a.[Заем погашен]) <=7  then '0..7' 
when datediff(day,  a.[Заем выдан], a.[Заем погашен]) <=14 then '8..14' 
when datediff(day,  a.[Заем выдан], a.[Заем погашен]) <=21 then '15..21' 
when datediff(day,  a.[Заем выдан], a.[Заем погашен]) <=30 then '21..30' 
when datediff(day,  a.[Заем выдан], a.[Заем погашен]) <=60 then '31..60' 
when datediff(day,  a.[Заем выдан], a.[Заем погашен]) <=90 then '61..90' 
when datediff(day,  a.[Заем выдан], a.[Заем погашен]) >90 then '90+' 
 
end [Срок жизни бакет]		
,a.[Проценты уплачено]
,a.[Маркетинговые расходы]
,a.product
, a.[Категория повторного клиента]	 
, a.[Вид займа в рамках продукта]
, a.[Группа каналов]
, a.[Канал от источника]
, a.[Место создания 2]
,  isnull(a.povt_parent_product	  , a.docred_parent_product)  [Предыдущий займ]  
,  b.[Дата погашения] 	[Предыдущий займ Дата погашения] 
, case when b.[Дата погашения]< a.[Заем выдан] then datediff(day,  b.[Дата погашения], a.[Заем выдан]) end	[Предыдущий займ дней с закрытия] 
, case when b.[Дата погашения]< a.[Заем выдан] then datediff(month,  b.[Дата погашения], a.[Заем выдан]) end	[Предыдущий займ месяцев с закрытия] 
, case when b.[Дата погашения]< a.[Заем выдан] then dbo.FullMonthsSeparation(  b.[Дата погашения], a.[Заем выдан]) end	[Предыдущий займ полных месяцев с закрытия] 
, datediff(day, b.[Дата выдачи], a.[Заем выдан])	 [Предыдущий займ дней с выдачи] 
, datediff(month, b.[Дата выдачи], a.[Заем выдан])	 [Предыдущий займ месяцев с выдачи] 
, b.[Текущая процентная ставка]	 [Предыдущий займ ставка]
, b.[Признак КП снижающий ставку]	[Предыдущий займ ставка КП снижающий ставку]
, b.[Срок жизни займа]  [Предыдущий займ Срок жизни]
, b.Канал	[Предыдущий займ Канал] 
, b.[Способ оформления займа]	  [Предыдущий займ Место создания 2]
, c.attempt_start [Дозвон докреды и повторники]
, datediff(day, c.attempt_start, a.[Верификация КЦ]   )[Дней с дозвона докреды и повторники]
, GETDATE() created

   into #loyalty_pts
from 	#t1	a
left join mv_loans b on b.Код=isnull(a.povt_parent_product	  , a.docred_parent_product)
left join mv_loans b1 on b1.Код=a.next_povt_product
left join mv_loans b2 on b2.Код=a.next_docr_product		 
left join #calls c on c.client_number='8'+a.Телефон and c.attempt_start <= a.[Верификация КЦ]  	  and 	c.attempt_start>=b.[Дата выдачи]
 
-- where a.Номер='19011023470001'

;with v  as (select *, row_number() over(partition by  Номер order by [Дозвон докреды и повторники] desc ) rn from #loyalty_pts ) delete from v where rn>1

 drop table if exists _birs.[loyalty_pts_stat]
 select * into _birs.[loyalty_pts_stat] from #loyalty_pts

--select * from #loyalty_pts

--drop table if exists _birs.[loyalty_pts_stat]
--select * into _birs.[loyalty_pts_stat] from #loyalty_pts
delete from _birs.[loyalty_pts_stat]
insert into _birs.[loyalty_pts_stat]
select * from #loyalty_pts
 

  --select * into  loyalty_pts from  ##loyalty_pts

  end

  if @mode= 'select'
   select * from _birs.[loyalty_pts_stat]
   where [Заем выдан]>='20220101'


 end


 CREATE proc  dbo.[Создание витрины со ставками по Платежным системам]

as
begin



drop table if exists #t1, #t2, #t3


select МесяцПлатежа, Сумма, case when ПлатежнаяСистема in ( 'Contact', 'QIWI') then 'Киви' else ПлатежнаяСистема end ПлатежнаяСистема  into #t1 from v_repayments
where МесяцПлатежа>='20200101'

--select * from stg.files.[расходы и доходы от пш_stg]
;
with b
as
(


SELECT 
       [Месяц]                         [Месяц]
      ,[Cloud payments выдачи]		  [Cloud payments выдачи]
      ,[Cloud payments погашения]	  [Cloud payments погашения]
      ,[КИВИ БАНК (АО) выдачи]		  [КИВИ БАНК (АО) выдачи]
      ,[КИВИ БАНК (АО) погашения]	  [КИВИ БАНК (АО) погашения]
      ,[БРС выдачи]					  [БРС выдачи]
      ,[БРС погашения]				  [БРС погашения]
      ,[ECommPay выдачи]			  [ECommPay выдачи]
      ,[ECommPay погашения]			  [ECommPay погашения]
      ,[created]					  [created]
  FROM [Stg].[files].[расходы и доходы от пш_stg]
  )

select a.*
,
perc 
= 
case 
when a.ПлатежнаяСистема = 'Cloud payments' then [Cloud payments погашения]/Сумма 
when a.ПлатежнаяСистема = 'Киви' then [КИВИ БАНК (АО) погашения]/Сумма 
when a.ПлатежнаяСистема = 'ECommPay' then [ECommPay погашения]/Сумма 


end
into #t2
from (
select МесяцПлатежа,ПлатежнаяСистема, sum(Сумма) Сумма
from #t1 a
where МесяцПлатежа>='20200101'
group by  МесяцПлатежа,ПлатежнаяСистема
) a 
join  b on a.МесяцПлатежа=b.Месяц
order by  МесяцПлатежа,ПлатежнаяСистема






select c.Месяц ,a.ПлатежнаяСистема, a.perc
into #T3
from #t2 a
join v_Calendar c on c.Дата>a.МесяцПлатежа

where МесяцПлатежа = (
select max(МесяцПлатежа) from #t2 )
and c.Дата=c.Месяц
union all
select МесяцПлатежа, ПлатежнаяСистема, perc from #t2
order by 2, 1

--drop table if exists dbo.repayments_rates
--select *, GETDATE() as created into  dbo.repayments_rates
--from #T3


--drop table if exists _____
--select * into _____ from ########
delete from dbo.repayments_rates
insert into dbo.repayments_rates
select *, GETDATE() as created  from #T3



exec log_email 'Ставки ПШ сохранены',  'p.ilin@techmoney.ru'

select * from  dbo.repayments_rates
order by 1, 2
exec _mv 'mv_repayments', 1

end
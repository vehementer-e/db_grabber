CREATE proc   [dbo].[sale_kpi_kp] as


drop table if exists #profit_week	
	
select 	
 МесяцПлатежа Месяц	
,[Расчетная прибыль net] = sum(isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0))	
,[Расчетная прибыль] = sum(isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм] else [Прибыль] end, 0))	
, IsInstallment	
into #profit_week	
from v_repayments	
group by МесяцПлатежа  , IsInstallment	
	
--select top 100  * from mv_repayments	
	
drop table if exists #sms	
	
select [дата оплаты месяц] Месяц,	
       sum([cумма услуги net]) [cумма услуги net смс]	 ,
       sum([cумма услуги]) [cумма услуги смс]	 ,
	   0   IsInstallment
into #sms	
from v_comissions_sales	
where оплачено = 'СМС информирование'	
group by [дата оплаты месяц]	
	
drop table if exists #sroch	
	
select [дата оплаты месяц] Неделя,	
       sum([cумма услуги net]) [cумма услуги net доср] ,	
       sum([cумма услуги]) [cумма услуги доср]	 ,

	   0   IsInstallment
into #sroch	
from v_comissions_sales	
where оплачено = 'Срочное снятие с залога'	
group by [дата оплаты месяц]	

 
drop table if exists #payments1	


select 
   a.month Месяц
,   sum(  a.[pts_net] ) 	[Поступление (без НДС)]
,   sum(  a.[pts_net] )  /(1-0.2/1.2) [Поступление _(с НДС)]
 
, 0  IsInstallment
  into #payments1  --select *
from 

marketing_sell_agr a
where  a.month  <getdate()

group by  a.month  		

--select * from #payments


drop table if exists #payments2	


select 
   a.month Месяц
,   sum( a.[bezzalog_net]  ) 	[Поступление (без НДС)]
,   sum( a.[bezzalog_net]  )  /(1-0.2/1.2) [Поступление _(с НДС)]
 
, 1  IsInstallment
  into #payments2  --select *
from 

marketing_sell_agr a
where  a.month  <getdate()

group by  a.month  		

drop table if exists #kp


select 
   [Заем выдан месяц] Месяц
,   sum( a.СуммаДопУслугCarmoneyNet )  СуммаДопУслугCarmoneyNet
,   sum( a.СуммаДопУслуг  )  СуммаДопУслуг

, 1-ispts  IsInstallment
  into #kp
from 

mv_dm_Factor_Analysis a
group by  [Заем выдан месяц] ,  1-ispts 

	



select *, 'Платежи'  t-- into #t3737734
from #profit_week union all	
select *, 'СМС' from #sms union all	
select *, 'Срочное снятие залога' from #sroch union all 	
select *, 'КП'  from #kp union all 	
select *, 'Продажа трафика' from #payments1 union all 	
select *, 'Продажа трафика' from #payments2


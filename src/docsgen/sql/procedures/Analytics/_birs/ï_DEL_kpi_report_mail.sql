CREATE   proc [_birs].[kpi_report_mail] @mode nvarchar(max) = 'update'
--ass
as
begin
if @mode = 'update'
begin
DECLARE @exists int = 0
DECLARE @exists1 int = 0
DECLARE @exists2 int = 0
DECLARE @exists3 int = 0
DECLARE @exists4 int = 0


;
while @exists=0 
begin
SELECT TOP 1 @exists1 = 1 FROM reports.dbo.dm_Factor_Analysis_001 WHERE cast([Дата отчета] as date) = cast(getdate() as date)
SELECT TOP 1 @exists2 = 1 FROM [dbo].[report_comissions] WHERE cast([Дата обновления записи по договору с комиссией] as date) = cast(getdate() as date)
SELECT TOP 1 @exists3 = 1 FROM [_birs].[product_report_conversions] WHERE cast([created] as date) = cast(getdate() as date)
SELECT TOP 1 @exists4 = 1 FROM [dbo].[mv_repayments] WHERE cast([created] as date) = cast(getdate() as date)


IF @exists1+@exists2+@exists3+@exists4<>4
begin
waitfor delay '00:00:30'
end


else 
begin

set @exists=1

end


end

					  
drop table if exists #fa
select 
dateadd(day, datediff(day, '1900-01-01', f.[Верификация КЦ]) / 7 * 7, '1900-01-01')   [Неделя Заявка]
, dateadd(day, datediff(day, '1900-01-01', f.[Заем выдан]) / 7 * 7, '1900-01-01')   [Неделя Заем выдан]
, cast(f.[Заем выдан] as date)  [День Заем выдан]
, f.ispts
, f.[Вид займа]
, f.[Верификация КЦ]
, f.[Номер]
, case when f.[Группа каналов] = 'CPA' then f.[Канал от источника] else f.[Группа каналов]  end [Группа каналов_2]
, f.[Сумма Дополнительных Услуг Carmoney Net] Сумма
,case when f.RBP in('RBP - 40', 'RBP - 56', 'RBP - 66', 'RBP - 86') and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP
,case when f.RBP = 'RBP - 40' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP1
,case when f.RBP = 'RBP - 56' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP2
,case when f.RBP = 'RBP - 66' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP3
,case when f.RBP = 'RBP - 86' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP4
,case when f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end [Новых займов]
,case when f.[Вид займа] = 'Повторный' and f.[Заем выдан] is not null then 1 else 0 end [Повторных займов]
,case when f.[Вид займа] = 'Докредитование' or f.[Вид займа] = 'Параллельный' and f.[Заем выдан] is not null then 1 else 0 end [Докред займов]
,case when f.[Вид займа] is not null and f.[Заем выдан] is not null then 1 else 0 end [Займов]
,case when f.[Вид займа] = 'Первичный' then 'Новые' 
      when f.[Вид займа] = 'Повторный' then 'Повторные' 
	  when f.[Вид займа] = 'Докредитование' or f.[Вид займа] = 'Параллельный' then 'Докреды' end [Вид]
,f.[Процентная ставка] Ставка
,f.[Первичная сумма] Запрошенная
,f.[Сумма одобренная] Одобренная
,f.[Выданная сумма] Выданная
,fa.[full_prepayment_30]
,f.[Предварительное одобрение]
,f.[Контроль данных]
,f.[Одобрено]
,f.[Отказ документов клиента]
,f.[Отказано]
,f.[Заем выдан]
,f.[Место cоздания]
,case when f.ispts = 1 then 'ПТС' when f.ispts = 0 then 'Беззалог' end ПТС
,case when f.[Место cоздания] = 'Оформление в мобильном приложении' then 'Воронка ПТС МП' 
      when f.[Место cоздания] = 'Ввод операторами LCRM' then 'Воронка ПТС сайт' end Воронка
into  #fa
from reports.dbo.dm_Factor_Analysis_001 f
left join reports.dbo.dm_Factor_Analysis fa on fa.Номер = f.Номер
where f.Дубль=0 and f.[Верификация КЦ] >='20231001'


drop table if exists #weeks
select Неделя, [Неделя окончание] into  #weeks
from v_Calendar
where Дата=	Неделя and Дата>='20231001'

drop table if exists #plans 

select dateadd(day, datediff(day, '1900-01-01', Дата) / 7 * 7, '1900-01-01')   Неделя
, [План ПТС] = sum([Займы руб]  )
, [План Беззалог] = sum([Сумма займов инстоллмент план]  )
	 into #plans 
from stg.files.ContactCenterPlans_buffer
group by dateadd(day, datediff(day, '1900-01-01', Дата) / 7 * 7, '1900-01-01') 

drop table if exists #facts 

select [Неделя Заем выдан]   Неделя
 
, sum(case when ispts=0 then Выданная end)  [Выданная сумма Беззалог]
, sum(case when ispts=1 then Выданная end)  [Выданная сумма ПТС]
, [RBP1%] = cast(sum(RBP1) as dec)/nullif(sum(RBP), 0)
, [RBP2%] = cast(sum(RBP2) as dec)/nullif(sum(RBP), 0)
, [RBP3%] = cast(sum(RBP3) as dec)/nullif(sum(RBP), 0)
, [RBP4%] = cast(sum(RBP4) as dec)/nullif(sum(RBP), 0)
, [Новые% шт] = cast(sum([Новых займов]) as dec)/sum([Займов])
, [Повторные% шт] = cast(sum([Повторных займов]) as dec)/sum([Займов])
, [Докреды% шт] = cast(sum([Докред займов]) as dec)/sum([Займов])
, [Новые% руб] = cast(sum(case when Вид = 'Новые' then Выданная end) as dec)/sum(Выданная) 
, [Повторные% руб] = cast(sum(case when Вид = 'Повторные' then Выданная end) as dec)/sum(Выданная) 
, [Докреды% руб] = cast(sum(case when Вид = 'Докреды' then Выданная end) as dec)/sum(Выданная)
into #facts 
from #fa
where [Неделя Заем выдан] is not null
 group by 
 [Неделя Заем выдан]    


 
drop table if exists #weeks_rr 

select Неделя
, min(Месяц) Месяц
,  max(case when Дата<getdate()-1 and month(Неделя)=month(Дата) then Дата end) ДатаRR
into #weeks_rr
from v_Calendar a
--left join   stg.files.ContactCenterPlans_buffer b
where Неделя<getdate()-1
group by	Неделя


drop table if exists #rr_weeks 

select Неделя
,Месяц
,ДатаRR	 
, sum(case when b.isPts=1 then b.Выданная end)	/max([Доля месяца ПТС])	        [RR_По_Неделям_ПТС] 	      
, sum(case when b.isPts=0 then b.Выданная end)	/max([Доля месяца Инстоллмент])	[RR_По_Неделям_Инстоллмент]
into #rr_weeks
from (
select 
    a.Неделя 

,a.Месяц 
,a.ДатаRR 
,   sum(try_cast(b.[Доля месяца ПТС] 		 as float) ) [Доля месяца ПТС]
,   sum(try_cast(b.[Доля месяца Инстоллмент] as float)  ) [Доля месяца Инстоллмент]
 from 	#weeks_rr a left join 
 stg.files.ContactCenterPlans_buffer_stg b on b.Дата between a.Месяц and a.ДатаRR
group by 
a.Неделя 

,a.Месяц 
,a.ДатаRR 	)
a left join   #fa b on b.[День Заем выдан] between a.Месяц and a.ДатаRR
group by Неделя
,Месяц
,ДатаRR


drop table if exists #source_week

select [Неделя Заем выдан] Неделя
      ,[CPA нец] = cast(sum(case when [Группа каналов_2] = 'CPA нецелевой' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'CPA нецелевой' then Выданная end)
      ,[CPA пол] = cast(sum(case when [Группа каналов_2] = 'CPA полуцелевой' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'CPA полуцелевой' then Выданная end)
	  ,[CPA цел] = cast(sum(case when [Группа каналов_2] = 'CPA целевой' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'CPA целевой' then Выданная end)
	  ,[CPC] = cast(sum(case when [Группа каналов_2] = 'CPC' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'CPC' then Выданная end)
	  ,[Органика] = cast(sum(case when [Группа каналов_2] = 'Органика' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'Органика' then Выданная end)
	  ,[Телеком] = cast(sum(case when [Группа каналов_2] = 'Телеком' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'Телеком' then Выданная end)
	  ,[Партнеры] = cast(sum(case when [Группа каналов_2] = 'Партнеры' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'Партнеры' then Выданная end)
	  ,[Банки] = cast(sum(case when [Группа каналов_2] = 'Банки' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'Банки' then Выданная end)
	  ,[Триггеры] = cast(sum(case when [Группа каналов_2] = 'Триггеры' then Сумма end) as dec)/sum(case when [Группа каналов_2] = 'Триггеры' then Выданная end)
	  ,[Тотал] = cast(sum(Сумма) as dec)/sum(Выданная)
into #source_week
from #fa
group by [Неделя Заем выдан]


drop table if exists #cost_loan_week
;
with v as
(select case when o.[Заем выдан день] is null then [Верификация КЦ] else o.[Заем выдан день] end Дата,
		case when isinstallment=1 then o.[Маркетинговые расходы] end [Маркетинговые расходы Инст],
		case when isinstallment=0 then o.[Маркетинговые расходы] end [Маркетинговые расходы ПТС],
		case when isinstallment=1 and o.[Заем выдан день] is not null then 1 end [Количество займов Инст],
		case when isinstallment=0 and o.[Заем выдан день] is not null then 1 end [Количество займов ПТС]
from [dbo].[v_Отчет стоимость займа опер] o
left join #fa f on f.[Номер] = o.Номер
where [Верификация КЦ]>='20231001'
)
select cast(sum([Маркетинговые расходы Инст]) as dec)/sum([Количество займов Инст])[Стоимость займа инст],
	   cast(sum([Маркетинговые расходы ПТС]) as dec)/sum([Количество займов ПТС]) [Стоимость займа птс],
	   dateadd(day, datediff(day, '1900-01-01', [Дата]) / 7 * 7, '1900-01-01') [Неделя]
into #cost_loan_week
from v
group by dateadd(day, datediff(day, '1900-01-01', [Дата]) / 7 * 7, '1900-01-01')
;

drop table if exists #profit_week

select 
 dateadd(day, datediff(day, '1900-01-01', [ДеньПлатежа]) / 7 * 7, '1900-01-01') Неделя
,[Расчетная прибыль net] = sum(isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0))		
into #profit_week
from mv_repayments
group by dateadd(day, datediff(day, '1900-01-01', [ДеньПлатежа]) / 7 * 7, '1900-01-01')

drop table if exists #sms

select [дата оплаты неделя] Неделя,
       sum([cумма услуги net]) [cумма услуги net смс]
into #sms
from v_comissions_sales
where оплачено = 'СМС информирование'
group by [дата оплаты неделя]

drop table if exists #sroch	

select [дата оплаты неделя] Неделя,
       sum([cумма услуги net]) [cумма услуги net доср]
into #sroch
from v_comissions_sales
where оплачено = 'Срочное снятие с залога'
group by [дата оплаты неделя]

drop table if exists #conversion
select case when [Группа каналов] = 'CPA' then [Канал от источника] else [Группа каналов]  end [Группа каналов_2]
,dateadd(day, datediff(day, '1900-01-01', День) / 7 * 7, '1900-01-01')   Неделя
,is_pts
,c.[Верификация КЦ]
,Лидов
into #conversion   --select top 100 *
from [_birs].[product_report_conversions] c
--left join reports.[dbo].[dm_Factor_Analysis] fa on c.num_1c=fa.Номер
where День>='20231001' and Дубль2 = 0 and [Как создан] = 'REF'

drop table if exists #conversions
select Неделя
,sum(case when is_pts=1 then 1 else 0 end) [Лиды ПТС]
,cast(sum(case when [Верификация кц] is not null and is_pts=1 then 1 else 0 end) as dec) /nullif(sum(case when is_pts=1 then 1 else 0 end),0) [Конверсия ПТС]
,sum(case when is_pts=0 then 1 end) [Лиды Беззалог]
,cast(sum(case when [Верификация кц] is not null and is_pts=0 then 1 else 0 end) as dec) /nullif(sum(case when is_pts=0 then 1 else 0 end),0) [Конверсия Беззалог]
into #conversions
from #conversion 
group by Неделя


drop table if exists #connect
select dateadd(day, datediff(day, '1900-01-01', attempt_start_date) / 7 * 7, '1900-01-01')   [Неделя] 
, sum(Стоимость) [Расходы на связь]
into #connect
from _birs.cost_of_calls
where attempt_start_date>='20231001'
group by dateadd(day, datediff(day, '1900-01-01', attempt_start_date) / 7 * 7, '1900-01-01')
--select * from  #cost_loan_week
--select * from	 #rr_weeks
--select * from	 #facts
--select * from	 #plans
--stg.files.ContactCenterPlans_buffer_stg 

--exec select_table 'stg.files.ContactCenterPlans_buffer_stg'



-- select * from #plans p          
-- select * from #facts f          
-- select * from #rr_weeks rr      
-- select * from #cost_loan_week cl
-- select * from #source_week sw   
-- select * from #profit_week pw   
-- select * from #sms ss           
-- select * from #sroch sr         
--drop table if exists #weeks_by_columns
--drop table if exists #weeks_by_rows

drop table if exists #weeks_by_columns



select a.Неделя
, [План факт ПТС] = f.[Выданная сумма ПТС]/ p.[План ПТС]
, [План факт Беззалог] = f.[Выданная сумма Беззалог]/ p.[План Беззалог]
 ,  rr.RR_По_Неделям_Инстоллмент
 ,  rr.RR_По_Неделям_ПТС
 ,  f.[Выданная сумма ПТС] [Продажи ПТС]
 ,  f.[Выданная сумма Беззалог] [Продажи Беззалог]
 ,  cl.[Стоимость займа инст]
 ,  cl.[Стоимость займа птс]
 ,  f.[RBP1%]
 ,  f.[RBP2%]
 ,  f.[RBP3%]
 ,  f.[RBP4%]
 , f.[Новые% шт]
 , f.[Повторные% шт]
 , f.[Докреды% шт]
 , f.[Новые% руб]
 , f.[Повторные% руб]
 , f.[Докреды% руб]
 , pw.[Расчетная прибыль net]
 , ss.[cумма услуги net смс]+sr.[cумма услуги net доср] [Прибыль net]
 , c.[Лиды ПТС]
 , c.[Конверсия ПТС]
 , c.[Лиды Беззалог]
 , c.[Конверсия Беззалог]
 , cc.[Расходы на связь]
 , sw.[CPA нец]
 , sw.[CPA пол]
 , sw.[CPA цел]
 , sw.[CPC]
 , sw.[Органика]
 , sw.[Телеком]
 , sw.[Партнеры]
 , sw.[Банки]
 , sw.[Триггеры]
 , sw.[Тотал]
into #weeks_by_columns
from #weeks a
left join #plans p            on p.Неделя=a.Неделя
left join #facts f            on f.Неделя=a.Неделя
left join #rr_weeks rr        on rr.Неделя=cast(a.Неделя as date)
left join #cost_loan_week cl  on cl.Неделя=a.Неделя
left join #profit_week pw     on pw.Неделя=a.Неделя
left join #sms ss             on ss.Неделя=cast(a.Неделя as date)
left join #sroch sr           on sr.Неделя=cast(a.Неделя as date)
left join #conversions c      on c.Неделя=a.Неделя
left join #connect cc         on cc.Неделя=a.Неделя
left join #source_week sw     on sw.Неделя=a.Неделя
 

drop table if exists #weeks_by_rows


 select * into #weeks_by_rows
 from (
 select Неделя, [Тип] = 'План факт', группа = 'ПТС', Значение = [План факт ПТС] 			      from 	#weeks_by_columns				     union all
 select Неделя, [Тип] = 'План факт', группа = 'Беззалог', Значение = [План факт Беззалог]  from 	#weeks_by_columns								 union all
 select Неделя, [Тип] = 'RR по неделям', группа = 'Беззалог', Значение = [RR_По_Неделям_Инстоллмент]  from 	#weeks_by_columns					 union all
 select Неделя, [Тип] = 'RR по неделям', группа = 'ПТС', Значение = [RR_По_Неделям_ПТС]  from 	#weeks_by_columns							 union all
 select Неделя, [Тип] = 'Продажи руб', группа = 'ПТС', Значение = [Продажи ПТС]  from 	#weeks_by_columns									 union all
 select Неделя, [Тип] = 'Продажи руб', группа = 'Беззалог', Значение = [Продажи Беззалог]  from 	#weeks_by_columns								 union all
 select Неделя, [Тип] = 'Стоимость займа', группа = 'Беззалог', Значение = [Стоимость займа инст]  from 	#weeks_by_columns							 union all
 select Неделя, [Тип] = 'Стоимость займа', группа = 'ПТС', Значение = [Стоимость займа птс]  from 	#weeks_by_columns							 union all
 select Неделя, [Тип] = '% ПТС RBP шт', группа = 'RBP1', Значение = [RBP1%]  from 	#weeks_by_columns							 union all
 select Неделя, [Тип] = '% ПТС RBP шт', группа = 'RBP2', Значение = [RBP2%]  from 	#weeks_by_columns							 union all
 select Неделя, [Тип] = '% ПТС RBP шт', группа = 'RBP3', Значение = [RBP3%]  from 	#weeks_by_columns							 union all
 select Неделя, [Тип] = '% ПТС RBP шт', группа = 'RBP4', Значение = [RBP4%]  from 	#weeks_by_columns  							 union all
 select Неделя, [Тип] = '% ПТС вид займа шт', группа = 'Новые', Значение = [Новые% шт]  from 	#weeks_by_columns		 union all 
 select Неделя, [Тип] = '% ПТС вид займа шт', группа = 'Повторные', Значение = [Повторные% шт]  from 	#weeks_by_columns	 union all
 select Неделя, [Тип] = '% ПТС вид займа шт', группа = 'Докреды', Значение = [Докреды% шт]  from 	#weeks_by_columns	 union all
 select Неделя, [Тип] = '% ПТС вид займа руб', группа = 'Новые', Значение = [Новые% руб]  from 	#weeks_by_columns	 union all
 select Неделя, [Тип] = '% ПТС вид займа руб', группа = 'Повторные', Значение = [Повторные% руб]  from 	#weeks_by_columns union all
 select Неделя, [Тип] = '% ПТС вид займа руб', группа = 'Докреды', Значение = [Докреды% руб]  from 	#weeks_by_columns	 union all
 select Неделя, [Тип] = 'Комиссия платежи', группа = 'Тотал', Значение = [Расчетная прибыль net]  from 	#weeks_by_columns		 union all
 select Неделя, [Тип] = 'Комиссии ПДП и СМС', группа = 'Тотал', Значение = [Прибыль net]  from 	#weeks_by_columns	 			 union all
 select Неделя, [Тип] = 'Лиды ref трафик', группа = 'ПТС', Значение = [Лиды ПТС]  from 	#weeks_by_columns	 			 union all
 select Неделя, [Тип] = 'Лид заявка ref', группа = 'ПТС', Значение = [Конверсия ПТС]  from 	#weeks_by_columns	 			 union all
 select Неделя, [Тип] = 'Лиды ref трафик', группа = 'Беззалог', Значение = [Лиды Беззалог]  from 	#weeks_by_columns	 			 union all
 select Неделя, [Тип] = 'Лид заявка ref', группа = 'Беззалог', Значение = [Конверсия Беззалог]  from 	#weeks_by_columns	 			 union all
 select Неделя, [Тип] = 'Расходы на связь', группа = 'Тотал', Значение = [Расходы на связь]  from 	#weeks_by_columns	 			 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'CPA нецелевой', Значение = [CPA нец]  from 	#weeks_by_columns		 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'CPA полуцелевой', Значение = [CPA пол]  from 	#weeks_by_columns		 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'CPA целевой', Значение = [CPA цел]  from 	#weeks_by_columns			 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'CPC', Значение = [CPC]  from 	#weeks_by_columns						 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'Органика', Значение = [Органика]  from 	#weeks_by_columns			 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'Телеком', Значение = [Телеком]  from 	#weeks_by_columns				 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'Партнеры', Значение = [Партнеры]  from 	#weeks_by_columns			 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'Банки', Значение = [Банки]  from 	#weeks_by_columns					 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'Триггеры', Значение = [Триггеры]  from 	#weeks_by_columns			 union all
 select Неделя, [Тип] = 'тест', группа = 'Предв. одобрение', Значение = [Триггеры]  from 	#weeks_by_columns			 union all
 select Неделя, [Тип] = 'Доля КП net', группа = 'Тотал', Значение = [Тотал]  from 	#weeks_by_columns						 --union all
) x





--select * from #weeks_by_rows where группа is null

Insert into #weeks_by_rows
select Неделя = [Неделя],
       Тип = 'Реф. лиды',
       группа = [Группа каналов_2] ,
       Значение= nullif(sum(Лидов),0)
	   from #conversion
	   where [Группа каналов_2] is not null	 and is_pts=1
	   group by [Неделя], [Группа каналов_2]
union all	   
select Неделя = [Неделя],
       Тип = 'Реф. лиды',
       группа = 'Тотал' ,
       Значение= nullif(sum(Лидов),0) 
	   from #conversion
	   where [Группа каналов_2] is not null	  and is_pts=1  
	   group by [Неделя]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заявка],
       Тип = 'Пр. одобрение ПТС',
       группа = [Группа каналов_2] ,
       Значение= cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заявка],
       Тип = 'Пр. одобрение ПТС',
       группа = 'Тотал' ,
       Значение= cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заявка],
       Тип = 'Доезд ПТС',
       группа = [Группа каналов_2] ,
       Значение= cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заявка],
       Тип = 'Доезд ПТС',
       группа = 'Тотал' ,
       Значение= cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заявка],
       Тип = 'AR ПТС',
       группа = [Группа каналов_2] ,
       Значение= cast(sum(case when [Одобрено] is not null then 1 else 0 end)as dec)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заявка],
       Тип = 'AR ПТС',
       группа = 'Тотал' ,
       Значение= cast(sum(case when [Одобрено] is not null then 1 else 0 end)as dec)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заявка],
       Тип = 'TU шт ПТС',
       группа = [Группа каналов_2] ,
       Значение= cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заявка],
       Тип = 'TU шт ПТС',
       группа = 'Тотал' ,
       Значение= cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заявка],
       Тип = 'Заявка займ ПТС',
       группа = [Группа каналов_2] ,
       Значение= cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заявка],
       Тип = 'Заявка займ ПТС',
       группа = 'Тотал' ,
       Значение= cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as dec)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from #fa
	   where [Группа каналов_2] is not null and ispts=1
	   group by [Неделя Заявка]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'Чек ПТС',
       группа = [Группа каналов_2] ,
       Значение= avg(Выданная) 
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заем выдан],
       Тип = 'Чек ПТС',
       группа = 'Тотал' ,
       Значение= avg(Выданная) 
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан]--, [Группа каналов_2]
union all	   
select Неделя = [Неделя Заем выдан],
       Тип = 'Ставка ПТС',
       группа = [Группа каналов_2] ,
       Значение= (try_cast(sum(case when Ставка>0 then Выданная*Ставка else 0 end)as float) /nullif((sum(case when Ставка>0 then Выданная else 0 end)*100),0))*100
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заем выдан],
       Тип = 'Ставка ПТС',
       группа = 'Тотал' ,
       Значение= (try_cast(sum(case when Ставка>0 then Выданная*Ставка else 0 end)as float) /nullif((sum(case when Ставка>0 then Выданная else 0 end)*100),0))*100 
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'Запрош. сумма ПТС',
       группа = [Группа каналов_2] ,
       Значение= avg(Запрошенная) 
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заем выдан],
       Тип = 'Запрош. сумма ПТС',
       группа = 'Тотал' ,
       Значение= avg(Запрошенная) 
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'Одобр. сумма ПТС',
       группа = [Группа каналов_2] ,
       Значение= avg(Одобренная) 
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заем выдан],
       Тип = 'Одобр. сумма ПТС',
       группа = 'Тотал' ,
       Значение= avg(Одобренная) 
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заем выдан],
       Тип ='UpSale деньги ПТС',
       группа = [Группа каналов_2] ,
       Значение = cast(sum(Выданная)as dec)/nullif(sum(Запрошенная),0) 
	   from #fa
	   where isPts=1 and Запрошенная>0
	   group by [Неделя Заем выдан], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заем выдан],
       Тип = 'UpSale деньги ПТС',
       группа = 'Тотал' ,
       Значение = cast(sum(Выданная)as dec)/nullif(sum(Запрошенная),0) 
	   from #fa
	   where isPts=1 and Запрошенная>0
	   group by [Неделя Заем выдан]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'TU в деньгах ПТС',
       группа = [Группа каналов_2] ,
       Значение = cast(sum(Выданная)as dec)/nullif(sum(Одобренная),0)
	   from #fa
	   where isPts=1 and Одобренная>0
	   group by [Неделя Заем выдан], [Группа каналов_2]
union all	   
select Неделя = [Неделя Заем выдан],
       Тип = 'TU в деньгах ПТС',
       группа = 'Тотал' ,
       Значение = cast(sum(Выданная)as dec)/nullif(sum(Одобренная),0)
	   from #fa
	   where isPts=1 and Одобренная>0
	   group by [Неделя Заем выдан]--, [Группа каналов_2]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'Ставка ПТС',
       группа = [Вид],
       Значение = (try_cast(sum(case when Ставка>0 then Выданная*Ставка else 0 end)as float) /nullif((sum(case when Ставка>0 then Выданная else 0 end)*100),0))*100
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'Запрош. сумма ПТС',
       группа = [Вид],
       Значение = avg(Запрошенная)
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'Одобр. сумма ПТС',
       группа = [Вид],
       Значение = avg(Одобренная)
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'Чек ПТС',
       группа = [Вид],
       Значение = avg(Выданная)
	   from #fa
	   where isPts=1
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'UpSale деньги ПТС',
       группа = [Вид],
       Значение = cast(sum(Выданная)as dec)/nullif(sum(Запрошенная),0) 
	   from #fa
	   where isPts=1 and Запрошенная>0
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = 'TU в деньгах ПТС',
       группа = [Вид],
       Значение = cast(sum(Выданная)as dec)/nullif(sum(Одобренная),0)
	   from #fa
	   where isPts=1 and Одобренная>0
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = '% ПДП 30д. ПТС шт',
       группа = [Вид],
       Значение = cast(sum([full_prepayment_30])as dec)/nullif(count([full_prepayment_30]),0)
	   from #fa
	   where ispts=1 and [full_prepayment_30] is not null
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = '% ПДП 30д. ПТС шт',
       группа = 'Тотал',
       Значение = cast(sum([full_prepayment_30])as dec)/nullif(count([full_prepayment_30]),0)
	   from #fa
	   where ispts=1 and [full_prepayment_30] is not null
	   group by [Неделя Заем выдан]--, [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = '% ПДП 30д. ПТС руб',
       группа = [Вид],
       Значение = cast(sum(case when full_prepayment_30=1 then Выданная end)as dec)/nullif(sum(Выданная),0)
	   from #fa
	   where ispts=1 and [full_prepayment_30] is not null
	   group by [Неделя Заем выдан], [Вид]
union all
select Неделя = [Неделя Заем выдан],
       Тип = '% ПДП 30д. ПТС руб',
       группа = 'Тотал',
       Значение = cast(sum(case when full_prepayment_30=1 then Выданная end)as dec)/nullif(sum(Выданная),0)
	   from #fa
	   where ispts=1 and [full_prepayment_30] is not null
	   group by [Неделя Заем выдан]--, [Вид]
union all
select Неделя = [Неделя Заявка],
       Тип = 'Предв. одобрение',
       группа = ПТС,
       Значение= try_cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0) 
	   from #fa
	   where ПТС is not null
	   group by [Неделя Заявка], ПТС
union all
select Неделя = [Неделя Заявка],
       Тип = 'Доезд',
       группа = ПТС,
       Значение= try_cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as float)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0) 
	   from #fa
	   where ПТС is not null
	   group by [Неделя Заявка], ПТС
union all
select Неделя = [Неделя Заявка],
       Тип = 'AR',
       группа = ПТС,
       Значение= try_cast(sum(case when [Одобрено] is not null then 1 else 0 end)as float)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0) 
	   from #fa
	   where ПТС is not null
	   group by [Неделя Заявка], ПТС
union all
select Неделя = [Неделя Заявка],
       Тип = 'TU',
       группа = ПТС,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from #fa
	   where ПТС is not null
	   group by [Неделя Заявка], ПТС
union all
select Неделя = [Неделя Заявка],
       Тип = 'Заявка займ',
       группа = ПТС,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from #fa
	   where ПТС is not null
	   group by [Неделя Заявка], ПТС
union all
select Неделя = [Неделя Заявка],
       Тип = Воронка,
       группа = 'Предв. одобрение',
       Значение= try_cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0) 
	   from #fa
	   where Воронка is not null and isPts=1
	   group by [Неделя Заявка], Воронка
union all
select Неделя = [Неделя Заявка],
       Тип = Воронка,
       группа = 'Доезд',
       Значение= try_cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as float)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0) 
	   from #fa
	   where Воронка is not null and isPts=1
	   group by [Неделя Заявка], Воронка
union all
select Неделя = [Неделя Заявка],
       Тип = Воронка,
       группа = 'AR',
       Значение= try_cast(sum(case when [Одобрено] is not null then 1 else 0 end)as float)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0) 
	   from #fa
	   where Воронка is not null and isPts=1
	   group by [Неделя Заявка], Воронка
union all
select Неделя = [Неделя Заявка],
       Тип = Воронка,
       группа = 'TU',
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from #fa
	   where Воронка is not null and isPts=1
	   group by [Неделя Заявка], Воронка
union all
select Неделя = [Неделя Заявка],
       Тип = Воронка,
       группа = 'Заявка займ',
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from #fa
	   where Воронка is not null and isPts=1
	   group by [Неделя Заявка], Воронка





	   drop table if exists _birs.kpi_report_weekly
select * into _birs.kpi_report_weekly from #weeks_by_rows


exec exec_python 'weekly_report_mail()' , 1


end

if @mode = 'select'
begin


select * from _birs.kpi_report_weekly
end

end

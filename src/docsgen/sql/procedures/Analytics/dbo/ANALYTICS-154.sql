CREATE   proc [dbo].[ANALYTICS-154]
as
begin
   
drop table if exists 	#t1

select 
  a.[Текущая процентная ставка] 
, a.[Ссылка договор CMR]  [Ссылка договор CMR]
, b.ДатаЗаявкиПолная
, b.[Вид займа]
, b.[Заем выдан] 	    
, cast(format(b.[Заем выдан] 	    , 'yyyy-MM-01') as date)  [Заем выдан месяц]
, b.[Заем погашен] 	   
, datediff(day, b.[Заем выдан],  b.[Заем погашен] 	    ) [Заем выдан - погашен дни]  
, a.Сумма 
, a.[Максимальная просрочка]
, a.код
, b.Телефон
, b.ФИО
, b.product
, case when dateadd(second, 24*60*60,  ДатаЗаявкиПолная	)>=[Заем выдан]		then 1 else 0 end    [24 часа]
into #t1 
from mv_loans	a
join reports.dbo.dm_Factor_Analysis_001 b on a.код=b.Номер
where a.isInstallment=0 and b.[Заем выдан] between '20230101' and '20230701' 
 


drop table if exists 	#t2

select
  a.*
, b.НомерПлатежа
, b.ДатаПлатежа
, c.d
, c.[dpd начало дня]
, c.[остаток од]
, c1.[остаток %] +c1.[Проценты начислено  нарастающим итогом]   [остаток % 5 дней]
into #t2

from #t1	   a
left join dwh2.dm.CMRExpectedRepayments b on a.[Ссылка договор CMR]=b.Договор and b.НомерПлатежа<=3	   and ПризнакПоследнийПлатежИспытательныйСрок=0
left join v_balance c on c.Код=b.Код and c.d=dateadd(day, 1,  b.ДатаПлатежа)
left join v_balance c1 on c1.Код=b.Код and 	c1.[Прошло дней с выдачи]=5

drop table if exists 	#t3

select код код
, count(case when [dpd начало дня]>0 then 1 end)  [dpd начало дня >0]
, count(case when [dpd начало дня]=0 then 1 end)  [dpd начало дня =0]
, count(  [dpd начало дня] )  [dpd начало дня]
, max(case when НомерПлатежа=3 then ДатаПлатежа end)  ДатаПлатежа
, min(case when [dpd начало дня]>0 then НомерПлатежа end)  НомерПлатежаПросрочка
, max([остаток % 5 дней])  [остаток % 5 дней]
, dateadd(day, 1, max(case when НомерПлатежа=3 then ДатаПлатежа end) )  ДатаУчета
into #t3
from 	#t2
group by код




drop table if exists 	#t4
select
  a.*
, b.НомерПлатежаПросрочка
,  case  when isnull([Заем выдан - погашен дни], 92)<92 then 'ПДП' else 'Остальные'	end [ПДП]
, case when [dpd начало дня >0]=0 and 	 [dpd начало дня =0]=3	 and 	 [dpd начало дня]=3 then 1 else 0 end [Внёс 3 платежа]  
, b.[dpd начало дня >0]
, b.[dpd начало дня =0]
, b.[dpd начало дня]
, b.ДатаПлатежа
, b.ДатаУчета
, b.[остаток % 5 дней]
,  ( Сумма*5*	[Текущая процентная ставка])/36500  Экстра_2
		 into #t4
from #t1 a
left join  #t3 b on a.код=b.код


--select *
--, case 
--when [24 часа]<>1 then '1) Не 24 часа'	
--when [ПДП]='ПДП' then '2) ПДП'	
--when НомерПлатежаПросрочка>0 then '3) Просрочил платеж ' + 	 format(НомерПлатежаПросрочка, '0')
--end
--
--from  #t4					   


drop table if exists 	 #f

select a.ДатаЗаявкиПолная
, a.[Заем выдан]
, a.ФИО
, a.код
, a.Телефон

, [ИНН (при наличии)] = 	  r.client_inn 
, [СНИЛС (при наличии)] = 	  r.client_snils 
, [Дата рождения] = 		  r.client_birthday 
, [Место рождения] = 		  r.client_birth_place 
, [Серия паспорта] = 		  r.client_passport_serial_number
, [Номер паспорта] = 		  r.client_passport_number 
, [Дата выдачи] = 			  r.passport_issue_date 
, [Кем выдан] = 			  r.passport_issued_by 
, [Код подразделения] = 	  r.passport_issued_code 
, [Адрес регистрации] = 	  r.registration_address
, a.ДатаУчета	ДатаУчета
, a.ДатаПлатежа	ДатаПлатежа
, a.[остаток % 5 дней]	[остаток % 5 дней]
 , getdate() dt
 into #f
from #t4	   a   
left join stg._LK.requests r on r.num_1c=a.код
where 
    [24 часа]=1	 
and [dpd начало дня >0]=0
and [dpd начало дня =0]=3
--and ДатаУчета=cast(getdate() as date)
and isnull( [Максимальная просрочка], 0)=0
and [Заем выдан месяц] in ('20230601', '20230501')
order by [Максимальная просрочка] desc, [Заем выдан]
	
--select sum([остаток % 5 дней]) [остаток % 5 дней] from #t4
--where 	[24 часа]=1	 
--and [dpd начало дня >0]=0	
--and isnull( [Максимальная просрочка], 0)=0
--and isnull([Заем выдан - погашен дни], 92)>=92
--group by month([Заем выдан])
--order by month([Заем выдан])



--
--select * from #t4
--where 	[24 часа]=1	 
--and [dpd начало дня >0]=0	
--and isnull( [Максимальная просрочка], 0)=0
--and isnull([Заем выдан - погашен дни], 92)>=92
--
--order by 3




--delete from [ANALYTICS-154_log]
				
				
 
--select * 
--from  #f a   join 	[ANALYTICS-154_log] b on a.код=b.код
--and a.[остаток % 5 дней]<>b.[остаток % 5 дней]



delete a 
from  #f a   join 	[ANALYTICS-154_log] b on a.код=b.код

	   

insert into  [ANALYTICS-154_log] 
--select * from [ANALYTICS-154_log]
select * from #f
--order by 1

exec log_email 'insert [ANALYTICS-154_log] ok' , 'e.kotova@techmoney.ru; p.ilin@techmoney.ru' , 'select * from [ANALYTICS-154_log] order by dt desc'



--select * from v_balance
--where код='23050500907154'


end
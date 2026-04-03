CREATE   proc [dbo].[sale_rating_main_prep]


as




declare @report_date date =  (select rating_date_from from config)--cast('20230301' as date)




drop table if exists #Коммуникации_t1

;

select idlead, lc.CreatedOn, (cu.LastName  + ' ' + cu.FirstName + ' '+ cu.MiddleName) collate Cyrillic_General_CI_AS ФИО, lc.Id
into #Коммуникации_t1
from stg._fedor.core_LeadCommunication lc
join stg._fedor.core_user cu on lc.idowner = cu.Id
where IdLeadCommunicationResult in ( 11, 17)
and  cast(format( DATEADD(hour,3, lc.createdon) , 'yyyy-MM-01' ) as date)= @report_date  

 
drop table if exists #communication_cache



select   f.id,  max(iif(b.Номер is null,0,1))  ПризнакЗаявка, [Статус лида], DATEADD(hour,3,t.createdon) ДатаСтатуса, f.[Дата лида], t.ФИО ,  max( b.Номер  ) 	Номер  , max(f.Телефон)	 Телефон, max( e.РГ) РГ

into #communication_cache
from Analytics.dbo.v_feodor_leads f
join #Коммуникации_t1 t on f.id_feodor = t.IdLead
left join v_fa b on b.Телефон=f.Телефон and b.[Верификация КЦ] between  DATEADD(hour,3,t.createdon) and dateadd(day, 5, DATEADD(hour,3,t.createdon))
left join employee e on e.seller = t.ФИО
--where [Результат коммуникации]  in ('Отправлен в ЛКК', 'Отправлен в МП'	)
  group by 	  f.id,    [Статус лида], DATEADD(hour,3,t.createdon)  , f.[Дата лида], t.ФИО
--where  cast(format([Дата лида] , 'yyyy-MM-01' ) as date) 




drop table if exists sale_rating_communication_cache
select * into sale_rating_communication_cache from #communication_cache













drop table if exists #f1

select fa.Номер, fa.[Канал от источника] [Канал от источника_перезаведение],fa.[Группа каналов] [Группа каналов_перезаведение],  1-fa.ispts isInstallment
into #f1
from v_fa fa
where fa.ДатаЗаявкиПолная>=@report_date  and  fa.productType='pts'


drop table if exists #prof_lead_request_cache



select
	t.Дата,
	t.Номер,
	t.ФИОоператора
	,ISNULL(IIF(fa.[Группа каналов_перезаведение]='CPA',fa.[Канал от источника_перезаведение],fa.[Группа каналов_перезаведение]),'Другое') as [Канал для рейтинга_с_учетом_перезаведенных Новый]
	--отказы по черновикам получат канал другое
	,t.МобильныйТелефон
	, t.[Проект] 
	, t.Длительность 
	, t.[Причина отказа] 
	into #prof_lead_request_cache
from
	analytics.dbo.[Профильный лид - заявка] t (nolock)
	left join #f1 fa on t.Номер = fa.Номер
where
	LEFT(t.Номер,14)!='отказ по лиду ' and месяц=@report_date  --and fa.isInstallment=0 в витрине и так только инст
union all
select
	t.Дата,
	t.Номер,
	t.ФИОоператора
	--, IIF( st.[Группа каналов]= 'unknown' or st.[Группа каналов] is NULL,'Другое', IIF(st.[Группа каналов]='CPA',st.[Канал от источника],st.[Группа каналов]))
	, IIF(t.[Канал для отчета] is NULL, 'Другое', t.[Канал для отчета])
	--отказы по лидам по которым канал не определился (сегодняшние) получат канал другое
	,t.МобильныйТелефон
	, t.[Проект] 
	, t.Длительность 
	, t.[Причина отказа] 
from
	 analytics.dbo.[Профильный лид - заявка] t  (nolock)
	 --[Reports].[dbo].[dm_report_requests_and_refuses_after_month_for_rating] t  (nolock)
	--left join #f2 st with(nolock) on TRY_CAST(SUBSTRING(t.Номер,15,len(t.Номер) -14) AS INT)=st.id
where
	LEFT(t.Номер,14)='отказ по лиду ' and месяц=@report_date  -- and st.IsInstallment=0 там и так только инст
--	order by 4

drop table if exists sale_rating_prof_lead_request_cache
select * into sale_rating_prof_lead_request_cache from #prof_lead_request_cache



drop table if exists #stat_cache

select 'Выданная сумма Инст' Показатель,
sum([Выданная сумма]) 'Выдано'
into #stat_cache
FROM v_fa (nolock)
WHERE cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = @report_date
and isPts=0
and cast( [Заем выдан]  as date) <= dateadd(d,-1,cast(getdate() as date))


union
select 'Выданная сумма ПТС' Показатель,
sum([Выданная сумма]) 'Выдано'
FROM v_fa (nolock)
WHERE cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = @report_date
and isPts=1
   and cast( [Заем выдан]  as date) <= dateadd(d,-1,cast(getdate() as date))


union
select 'Выданная сумма ПТС + ИНСТ' Показатель,
sum([Выданная сумма]) 'Выдано'
FROM v_fa (nolock)
WHERE cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = @report_date
   and cast( [Заем выдан]  as date) <= dateadd(d,-1,cast(getdate() as date))

--and isInstallment=0

union

select 
 'КП NET' Показатель,
SUM([сумма дополнительных услуг carmoney net]) 'КП NET'
FROM v_fa (nolock)
WHERE cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = @report_date
and ispts=1
   and cast( [Заем выдан]  as date) <= dateadd(d,-1,cast(getdate() as date))

union 

select 'План ПТС RR' Показатель,
sum(ptsSum) 'План'
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
   and date <= dateadd(d,-1,cast(getdate() as date))

union 

select 'План Инст RR' Показатель,
sum(bezzalogSum) 'План'
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
   and date <= dateadd(d,-1,cast(getdate() as date))


union 

select 'План КП RR' Показатель,
sum(ptsAddProductSum) 'План'
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
   and date <= dateadd(d,-1,cast(getdate() as date))
union 

select 'План ПТС' Показатель,
sum(ptsSum) 'План'
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
 --  and Дата <= dateadd(d,-1,cast(getdate() as date))	  union 
union 

select 'План Инст' Показатель,
sum(bezzalogSum) 'План'
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
 --  and Дата <= dateadd(d,-1,cast(getdate() as date))
union 

select 'План КП' Показатель,
sum(ptsAddProductSum) 'План'
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
  -- and Дата <= dateadd(d,-1,cast(getdate() as date))

union

SELECT 'Факт ставка' Значение,
	sum(cast(d.[Выданная сумма] * d.[Процентная ставка] as real)/100)/sum(d.[Выданная сумма])*100 Факт
 FROM v_fa  d
where   cast(format(d.[Заем выдан] , 'yyyy-MM-01' ) as date) = @report_date
and ispts=1

union

SELECT 'Ставка повторные' Значение,
	sum(cast(d.[Выданная сумма] * d.[Процентная ставка] as real)/100)/sum(d.[Выданная сумма])*100 Факт
 FROM v_fa  d
where cast(format(d.[Заем выдан] , 'yyyy-MM-01' ) as date) = @report_date
and ispts=1
	and [Вид займа] != 'Первичный'

union 

SELECT 'Заявок' Значение,
	count(Номер) Факт
 FROM v_fa  d
where 

cast(format(d.[ДатаЗаявкиПолная] , 'yyyy-MM-01' ) as date) = @report_date
	and ispts=1
	and Дубль = 0 
	
union 

SELECT 'План ставка' Значение,
	avg(ptsInterestRate) Месяц
 FROM sale_plan d
 where cast(format(date , 'yyyy-MM-01' ) as date) =  @report_date 


 union 

select 'План ПТС+ИНСТ' Показатель,
isnull(sum(ptsSum), 0)+isnull(sum(bezzalogSum), 0) 'План'	--select *
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
   and date <= dateadd(d,-1,cast(getdate() as date))
  union 

select 'План ПТС+ИНСТ месяц' Показатель,
isnull(sum(ptsSum), 0)+isnull(sum(bezzalogSum), 0) 'План'	--select *
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
 --  and Дата <= dateadd(d,-1,cast(getdate() as date))

  union 

select 'План ПТС+ИНСТ по вчера' Показатель,
isnull(sum(ptsSum), 0)+isnull(sum(bezzalogSum), 0) 'План'	--select *
from sale_plan
where cast(format(date , 'yyyy-MM-01' ) as date) = @report_date
   and date <= dateadd(d,-1,cast(getdate() as date))



   
drop table if exists sale_rating_stat_cache
select * into sale_rating_stat_cache from #stat_cache


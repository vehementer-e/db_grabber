
CREATE proc [_birs].[Регулярные обзвоны Докреды и повторники ПТС]

as

begin


drop table if exists #t1

SELECT mobile_fin phone
	,fio fio
	,a.crmclientguid 
	,[Рекомендованная Ставка] 
	,category 
	,main_limit 
	,case when type = 'Докредитование' then 'Докредитование' else 'Повторный' end [Type]
	, birth_date
	, [Паспорт серия]
	, [Паспорт номер]
	into #t1				--	  select *
FROM dwh_new.dbo.CRM_loyals_buffer_for_sales a
left join (select CRMClientGUID, max([Ставка %]) [Рекомендованная Ставка] from dwh_new.dbo.povt_buffer 
group by CRMClientGUID
--order by 
)				  s on s.CRMClientGUID=a.CRMClientGuid
WHERE category <> 'Красный'	and main_limit>0

			    
drop table if exists  #bl


select cast(Phone  as nvarchar(10)) phone into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 


drop table if exists #cont_90d
select right(client_number, 10)  phone into #cont_90d from reports.dbo.dm_report_DIP_detail_outbound_sessions
where login is not null and attempt_start>=dateadd(day, -90, getdate())
  group by client_number 
  
  drop table if exists #cont_180d
select   right(client_number, 10) phone into #cont_180d from reports.dbo.dm_report_DIP_detail_outbound_sessions
where login is not null and attempt_start>=dateadd(day, -180, getdate())
  group by client_number
 
  drop table if exists #mv_loans

  select crmclientguid, [Дата выдачи], [Текущая процентная ставка], closed  into #mv_loans from 	 mv_loans where isinstallment=0
 
  drop table if exists #closed

  select crmclientguid, max(closed) lastClosed, max([Дата выдачи]) lastIssued into #closed from #mv_loans
  group by crmclientguid


  ;with v  as (select *, row_number() over(partition by crmclientguid order by [Дата выдачи] desc) rn from #mv_loans ) delete from v where rn>1





DROP TABLE

IF EXISTS #t3
	SELECT a.phone phone
		,[Текущая процентная ставка]
		,[Дата выдачи]
		,a.category
		,a.main_limit
		,a.[Рекомендованная Ставка]
		,a.Type
		,case when b.phone  is not null then 1 else 0 end 	[Телефон в чс]
		,birth_date [Дата рождения]
			, [Паспорт серия]
	, [Паспорт номер]
		,CASE 
			WHEN c90.phone IS NOT NULL
				THEN 1
			ELSE 0
			END AS [Дозвон 90 дней]	 
		,CASE 
			WHEN c180.phone IS NOT NULL
				THEN 1
			ELSE 0
			END AS [Дозвон 180 дней]
			, closed.lastClosed [Дата закрытия]
	INTO #t3
	FROM #t1 a
	LEFT JOIN #bl b ON a.phone = b.phone
	LEFT JOIN #cont_90d c90 ON  a.phone = c90.phone
	LEFT JOIN #cont_180d c180 ON  a.phone = c180.phone
	LEFT JOIN #mv_loans l ON l.crmclientguid = a.crmclientguid
	LEFT JOIN #closed closed ON closed.CRMClientGUID= a.crmclientguid


--where b.UF_PHONE is null


;with v  as (select *, row_number() over(partition by phone order by [Дата выдачи] desc) rn from #t3 ) delete from v where rn>1  --or [Телефон в чс] is not null


SELECT *
FROM #t3 a 


end
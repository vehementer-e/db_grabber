CREATE   proc [_birs].[Регулярные обзвоны Активные клиенты без просрочки]

as
begin

drop table if exists #t1

SELECT CRMClientGUID
	,max([Текущая просрочка]) max_dpd
	,count(CASE 
			WHEN [Дата погашения] IS NULL and [Статус договора Спейс]='Действует'
				THEN 1
			END) cnt_active
			into #t1
FROM mv_loans
--where 1=0
group by   CRMClientGUID
--order by 

--select  [Статус договора Спейс], count(case when [Дата погашения] is null and [Текущая просрочка] =0 then 1 end) cnt from mv_loans
--group by  [Статус договора Спейс]
--order by 
	   drop table if exists #t2

SELECT 
     a.Пол
	,a.код
	,a.[Дата выдачи]
	,a.isInstallment
	,a.CRMClientGUID
	,a.[Основной телефон клиента CRM]
	,a.[Дата рождения]
	,a.Регион
	into #t2
FROM mv_loans a
JOIN #t1 b ON a.CRMClientGUID = b.CRMClientGUID
	AND cnt_active > 0
	AND max_dpd = 0


drop table if exists #t3

SELECT 
     a.Пол
	,a.Регион
	,b.СуммарныйМесячныйДоход СуммарныйМесячныйДоход_CRM
	,a.код
	,a.[Дата выдачи]
	,a.isInstallment
	,a.[Основной телефон клиента CRM]
	,dbo.get_age(a.[Дата рождения], getdate())  Возраст
	,c.dpd
	,c.[Дата закрытия]

   into #t3
	
FROM #t2 a
left join reports.dbo.dm_factor_analysis_001 b on a.код=b.Номер
left join v_balance c on c.код=a.код   and c.d=cast(getdate() as date)

	;with v  as (select *, count(case when [Дата закрытия] is  null then 1 end) over(partition by [Основной телефон клиента CRM]) cnt_active , max(dpd)over(partition by [Основной телефон клиента CRM])  max_dpd, row_number() over(partition by [Основной телефон клиента CRM] order by [Дата закрытия], [Дата выдачи] desc) rn from #t3 ) delete from v where rn>1
	or max_dpd>0
or cnt_active=0





drop table if exists  #bl


select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 




SELECT 
     Пол
	,Возраст
	,Регион
	,[Основной телефон клиента CRM]
	,СуммарныйМесячныйДоход_CRM
	,код
	,[Дата выдачи]	 [Дата выдачи последний займ]
	,case when isInstallment=1 then 'Инст' else 'ПТС' end [Продукт последний займ]
FROM #t3						a
left join #bl b on a.[Основной телефон клиента CRM]=b.UF_PHONE
where b.UF_PHONE is null




end
CREATE proc [dbo].[Дозвон заявка докреды и повторники создание]
as
begin

drop table if exists #t1
select 
     cast(format(a.attempt_start, 'yyyy-MM-01') as date) [Месяц звонка]
	,max(a.attempt_start) [Дата звонка]
	,a.client_number [Телефон клиента]
	,a.login [login оператора]
	,e.title [ФИО оператора]
into #t1
from Reports.dbo.dm_report_DIP_detail_outbound_sessions a (NOLOCK)
inner join [NaumenDbReport].[dbo].[mv_employee] e (NOLOCK) on a.login = e.login
where a.login is not null
and cast(format(a.attempt_start, 'yyyy-MM-dd') as date) >= dateadd(mm, -2, cast(format(getdate(), 'yyyy-MM-01') as date))
group by cast(format(a.attempt_start, 'yyyy-MM-01') as date),a.client_number,a.login,e.title





drop table if exists #t2
select 
        #t1.[Месяц звонка]
	  , max(#t1.[Дата звонка]) [Дата звонка]
	  , #t1.[Телефон клиента]
	  , #t1.[login оператора]
	  , #t1.[ФИО оператора]
	  , case when max(f.Номер) is null then 0 else 1 end [Признак заявки]
	  , max(f.Номер) [Номер заявки]
into #t2
from #t1
left join Reports.dbo.dm_factor_analysis_001 f (NOLOCK) on SUBSTRING(#t1.[Телефон клиента],2,11) = f.Телефон
and [Верификация КЦ] between (#t1.[Дата звонка]) and dateadd(day, 5, #t1.[Дата звонка])
and f.ispts = 1
group by #t1.[Месяц звонка], #t1.[Телефон клиента], #t1.[login оператора], #t1.[ФИО оператора]


delete from dbo.[Дозвон заявка докреды и повторники]
insert into dbo.[Дозвон заявка докреды и повторники]
select * from #t2

end
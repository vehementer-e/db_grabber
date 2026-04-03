

CREATE   proc [_birs].[Регулярные обзвоны Клиенты с регистрацией но без заявки]

@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin


declare @start_date date = @start_date_ssrs--getdate()-1
declare @end_date date = @end_date_ssrs--getdate()

select a.created_at, u.username, u.id into #reg
from stg._LK.register_mp a
join stg._LK.users u on a.user_id=u.id and ISNUMERIC(u.username)=1 and len(u.username)=10
where cast(a.created_at as date ) between @start_date and @end_date

drop table if exists #_LKrequests
select client_id, id into #_LKrequests
from stg._LK.requests

drop table if exists #dm_Factor_Analysis_001
select Телефон, Номер into #dm_Factor_Analysis_001
from reports.dbo.dm_Factor_Analysis_001

drop table if exists #bl
select cast(Phone  as nvarchar(10)) UF_PHONE into #bl
from stg._1ccrm.BlackPhoneList

drop table if exists #mv_loans
select [Основной телефон клиента CRM] телефон into #mv_loans from Analytics.dbo.mv_loans union
select [Телефон договор CMR]  from Analytics.dbo.mv_loans --union

select min(a.created_at) created_at , a.username from #reg a
left join #_LKrequests b on a.id=b.client_id
left join #dm_Factor_Analysis_001 f on a.username=f.Телефон
left join #bl on #bl.UF_PHONE=a.username
left join #mv_loans on #mv_loans.телефон=a.username
where b.id is null and 
f.Номер is null and #bl.UF_PHONE is null and #mv_loans.телефон is null
group by  a.username
order by 1

end
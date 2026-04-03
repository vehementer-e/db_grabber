-- exec [dbo].[Create_dm_ReportCollection_Agent_KA]
CREATE PROC dbo.Create_dm_ReportCollection_Agent_KA 
AS
BEGIN
	SET NOCOUNT ON;

	--создаем витрину для куба
	  SET DATEFIRST 1
      drop table if exists ##tmp_agent_payments
	           select r_month, r_day, dpd_bucket,r_date, a.external_id, r_week, concat(z.Фамилия, ' ', z.Имя, ' ', Отчество) ФИО, (case when isnull(b.agent_name, 'CarMoney') in ('ACB','CarMoney') then 'CarMoney'
                                    else isnull(b.agent_name, 'CarMoney') end) as agent_name,r_year,
                                    (case when isnull(b.agent_name, 'CarMoney') in ('ACB','CarMoney') then 0
                                    else isnull(b.reestr, 0) end) as agent_reestr,z.Регион,
                                    pay_total pay_total,overdue_days,overdue_days_p,principal_rest,percents_rest,fines_rest,otherpayments_rest,total_rest,total_wo,  perc_wo, perc_wo2 into ##tmp_agent_payments
                       from (select cdate        as r_date,																								
                            year(cdate)  as r_year,																										 
                            month(cdate) as r_month,
                            day(cdate)   as r_day,
							DATEPART(WEEK,cdate) as r_week,
                                          external_id,
                                               (case when isnull(overdue_days_p,0) <= 360 then '(1)_91-360'
                                                     else '(2)_361+' end)				  as dpd_bucket,
                                          isnull(overdue_days,0)						  as overdue_days,
                                          isnull(overdue_days_p,0)						  as overdue_days_p,
                                          cast(isnull(principal_rest,   0) as float)	  as principal_rest,
										  cast(isnull(percents_rest,   0) as float)		  as percents_rest,
										  cast(isnull(fines_rest,   0) as float)		  as fines_rest,
										  cast(isnull(total_rest_wo,   0) as float)		  as total_wo,
										  cast(isnull(percents_wo,   0) as float)		  as perc_wo,
										  cast(isnull(percents_rest_wo,   0) as float)	  as perc_wo2,
										  cast(isnull(other_payments_rest,   0) as float) as otherpayments_rest,
                                          cast(isnull(principal_rest,   0) as float) +
                                          cast(isnull(percents_rest,    0) as float) +
										  cast(isnull(fines_rest,   0) as float)     +
										  cast(isnull(other_payments_rest,   0) as float) as total_rest,
                                          cast(isnull(principal_cnl,    0) as float) +
                                          cast(isnull(percents_cnl,     0) as float) +
                                          cast(isnull(fines_cnl,        0) as float) +
                                          cast(isnull(otherpayments_cnl,0) as float) +
                                          cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
                                          row_number() over (partition by cdate, external_id order by cast(isnull(total_rest,0) as float) desc) as rn
                     from dwh_new.dbo.stat_v_balance2
                             where cdate >= cast(credit_date as date)
									 and cdate>='20191201'
                                     and isnull(overdue_days_p,0) >= 91) a
						left join (
							select
								agent_name = a.AgentName
								,reestr = RegistryNumber
								,external_id = d.Number
								,st_date  = cat.TransferDate
								,fact_end_date = cat.ReturnDate
								,plan_end_date = cat.PlannedReviewDate
								,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
							from Stg._collection.CollectingAgencyTransfer as cat
								inner join Stg._collection.Deals as d
									on d.Id = cat.DealId
								inner join Stg._collection.CollectorAgencies as a
									on a.Id = cat.CollectorAgencyId
							) as b
							on a.external_id = b.external_id 
							and a.r_date >= b.st_date and a.r_date <= b.end_date
					   left join stg._1cmfo.документ_ГП_заявка z on a.external_id=z.номер
                       where a.rn = 1
--					   and b.external_id is not null
                     
                       order by r_month, r_day, dpd_bucket, (case when isnull(b.agent_name, 'CarMoney') in ('ACB','CarMoney') then 'CarMoney'
                                      else isnull(b.agent_name, 'CarMoney') end),
                                      (case when isnull(b.agent_name, 'CarMoney') in ('ACB','CarMoney') then 0
                                      else isnull(b.reestr, 0) end)


------------------------------------!!!!!!!!!!ИСХОДНАЯ (ПЕРВАЯ) ТАБЛИЦА!!!!!!!!!!!!-------------------------------------------
delete from dbo.dm_ReportCollection_Agent_KA_FirstTable where r_date >=dateadd(day ,-2,cast(getdate() as date))
insert into dbo.dm_ReportCollection_Agent_KA_FirstTable
select * 
--into dbo.dm_ReportCollection_Agent_KA_FirstTable
from ##tmp_agent_payments
where r_date >=dateadd(day ,-2,cast(getdate() as date))

--------------


declare @dt date =getDate()
truncate table dbo.dm_ReportCollection_Agent_KA
------------------------------------!!!!!!!!!!!!!!!!!МЕСЯЦЫ!!!!!!!!!!!!!!!!!!!-------------------------------------------
insert into dbo.dm_ReportCollection_Agent_KA
select @dt as date_created, 1 table_num, a.*,  isnull(payers,0) as cnt_payers, isnull(pays,0) as pays,isnull(b.cash,0) as recovery, isnull(total_wo,0) as total_wo 

from (
select r_year,r_month, agent_name, 
agent_reestr, Регион, count(*) cnt_cred, sum(principal_rest)/1000000 principal_rest

from ##tmp_agent_payments
where r_date=EOMONTH(r_date)
group by r_year,r_month,agent_name, 
agent_reestr, Регион
) a
left join 
(
select  r_year,r_month, agent_name, 
agent_reestr, Регион,  sum(pay_total)/1000000 cash, count(*) as pays,count(distinct external_id) payers, sum(total_wo) /1000000 total_wo
from ##tmp_agent_payments
where pay_total>0
group by r_year,r_month,agent_name, 
agent_reestr, Регион) b on a.r_year=b.r_year and a.r_month=b.r_month and a.agent_name=b.agent_name and a.Регион=b.Регион and a.agent_reestr=b.agent_reestr
order by 1,2,5



------------------------------------!!!!!!!!!!!!!!!!!НЕДЕЛИ!!!!!!!!!!!!!!!!!!!-------------------------------------------
insert into dbo.dm_ReportCollection_Agent_KA
select @dt as date_created, 2 table_num, a.*, isnull(payers,0) as cnt_payers, isnull(pays,0) as pays,isnull(b.cash,0) as recovery, isnull(total_wo,0) as total_wo from (
select r_year,r_week, agent_name, 
agent_reestr, Регион, count(*) cnt_cred, sum(principal_rest)/1000000 principal_rest
from ##tmp_agent_payments
where r_date=DATEADD(dd, 7-(DATEPART(WEEKDAY, r_date)), r_date)
group by r_year,r_week,agent_name, 
agent_reestr, Регион
) a
left join 
(
select r_year,r_week, agent_name, 
agent_reestr, Регион,  sum(pay_total)/1000000 cash, count(*) as pays,count(distinct external_id) payers, sum(total_wo) /1000000 total_wo
from ##tmp_agent_payments
where pay_total>0 
group by r_year,r_week,agent_name, 
agent_reestr, Регион) b on a.r_year=b.r_year and a.r_week=b.r_week and a.agent_name=b.agent_name and a.Регион=b.Регион and a.agent_reestr=b.agent_reestr
order by 1,2,5



END

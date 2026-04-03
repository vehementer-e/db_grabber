
CREATE   proc-- exec
[dbo].[create_report_outsource_cost_of_loan]

as begin
return
--Отчет по стоимости займа Аутсорс
--
--Granat список сотрудников
--S.Kvitko
--E.Grigoreva
--E.Podbornaya
--Ya.Frolova
--D.Pavlij
--N.Pogosyan
--
--
--
--TDirect список сотрудников
--V.Skyteva
--E.Cyraeva
--
--
--Кедров список сотрудников
--D.Pomogajbo
--A.Logunova
--bocharov.s
--
drop table if exists #dates

select cast(PK_Date as date) d
into #dates
from reports.dbo.Календарь
where cast(PK_Date as date) between '20200915'  and cast(getdate() as date)



drop table if exists #employees

select 'S.Kvitko'          [login], 'Гранат'    [group], cast('2020-10-26' as date)  first_day       into #employees    union all
select 'E.Grigoreva'	   [login], 'Гранат'    [group], cast('2020-10-27' as date)  first_day       				    union all
select 'E.Podbornaya'	   [login], 'Гранат'    [group], cast('2020-09-30' as date)  first_day       				    union all
select 'Ya.Frolova'		   [login], 'Гранат'    [group], cast('2020-09-30' as date)  first_day       				    union all
select 'D.Pavlij'		   [login], 'Гранат'    [group], cast('2020-10-01' as date)  first_day       				    union all
select 'N.Pogosyan'		   [login], 'Гранат'    [group], cast('2020-10-27' as date)  first_day       				    union all
select 'E.Gracheva'		   [login], 'Гранат'    [group], cast('2020-11-03' as date)  first_day       				    union all
select 'V.Skyteva'		   [login], 'Т директ'  [group], cast('2020-09-15' as date)  first_day	                        union all
select 'E.Cyraeva'		   [login], 'Т директ'  [group], cast('2020-09-15' as date)  first_day	                        union all
select 'D.Pomogajbo'	   [login], 'ИП Кедров' [group], cast('2020-10-23' as date)  first_day	                        union all
select 'A.Logunova'		   [login], 'ИП Кедров' [group], cast('2020-10-29' as date)  first_day	  -- union all

;

drop table if exists #dm_Lead

select [Номер заявки] [Номер заявки (договор)], id lcrm_id into #dm_Lead  from v_feodor_leads
where [Номер заявки] is not null and isnumeric([Номер заявки])=1

drop table if exists #final_for_group


select 
dl.[Номер заявки (договор)],
dl.lcrm_id,
cast(dateadd(year, -2000, z.Дата) as date) Дата,
login,
cast(КонтрольДанных as date) КонтрольДанных,
cast(ЗаемВыдан as date) ЗаемВыдан,
ВыданнаяСумма
into #final_for_group
from #dm_Lead dl 
join stg.[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z on z.Номер=dl.[Номер заявки (договор)]
left join Feodor.dbo.dm_leads_history l on l.id=dl.lcrm_id

;


--drop table if exists analytics.dbo.report_outsource_cost_of_loan
drop table if exists #t1

select 
d.d,
emp.login,
emp.[group],
emp.first_day,
1+datediff(DAY, first_day, d.d) WorkedDaysInt,
isnull(ЧислоЗаявок                  ,0) ЧислоЗаявок                  ,        
isnull(ЧислоКД                      ,0) ЧислоКД                      ,
isnull(ЧислоЗаймов                  ,0) ЧислоЗаймов                  ,
isnull(СуммаВыдач                   ,0) СуммаВыдач                   ,
isnull([report_naumen_activity_by_login_day].int_speaking_duration ,0) int_speaking_duration ,
isnull([report_naumen_activity_by_login_day].int_normal_duration	,0) int_normal_duration	 ,
isnull([report_naumen_activity_by_login_day].int_wrapup_duration   ,0) int_wrapup_duration   ,
getdate() as created
into #t1
from 
#employees emp
cross join
#dates d --on d.d>=emp.first_day
left join
(
select login, Дата, isnull(count([Номер заявки (договор)]), 0) ЧислоЗаявок
from #final_for_group
group by login, Дата
) z_on_dates on z_on_dates.login=emp.login and z_on_dates.Дата=d.d
left join
(
select login, КонтрольДанных,  isnull(count([Номер заявки (договор)]),0) ЧислоКД
from #final_for_group
group by login, КонтрольДанных
) kd_on_dates on kd_on_dates.login=emp.login and kd_on_dates.КонтрольДанных=d.d
left join
(
select login, ЗаемВыдан,  isnull(count([Номер заявки (договор)]),0) ЧислоЗаймов, sum(ВыданнаяСумма) СуммаВыдач

from #final_for_group
group by login, ЗаемВыдан
) loans_on_dates on loans_on_dates.login=emp.login and loans_on_dates.ЗаемВыдан=d.d

left join 
(
select login
      ,d
	  , cast(isnull(sum([Время диалога]*24*60*60  ),0) as bigint) int_speaking_duration
	  , cast(isnull(sum(Готов*24*60*60 	  ),0)  as bigint) int_normal_duration	
	  , cast(isnull(sum(Постобработка*24*60*60     ),0) as bigint) int_wrapup_duration 
	 -- select *
	 from Analytics.[dbo].[report_naumen_activity_by_login_day] dwh471
	  group by 
	  login
      ,d
) [report_naumen_activity_by_login_day]


on [report_naumen_activity_by_login_day].d=d.d and [report_naumen_activity_by_login_day].login=emp.login
where d.d>=first_day

begin tran

delete from analytics.dbo.report_outsource_cost_of_loan
insert into analytics.dbo.report_outsource_cost_of_loan
select * from #t1
commit tran


end

CREATE proc [dbo].[create_dm_robo_ivr_leads_history]
as
begin


declare @start_date_update date = cast(getdate() -4 as date)

drop table if exists #ch_robo_ivr
select * into #ch_robo_ivr from         Feodor.dbo.dm_calls_history ch with(nolock, index=[NonClusteredIndex_attempt_start])
where ch.projectuuid = 'corebo00000000000n8i9hcja56hji2o' and attempt_start>=@start_date_update

drop table if exists #t3

select ch.[uuid]
      ,ch.[creationdate]
      ,ch.[timezone]
      ,ch.[phonenumbers]
      ,ch.[casecomment]
      ,ch.[statetitle]
      ,ch.[projecttitle]
      ,ch.[projectuuid]
      ,null [title]
      ,ch.[channel]
      ,ch.[lcrm_id]
      ,ch.[attempt_start]
      ,ch.[attempt_end]
      ,ch.[number_type]
      ,ch.[pickup_time]
      ,ch.[queue_time]
      ,ch.[operator_pickup_time]
      ,ch.[speaking_time]
      ,ch.[wrapup_time]
      ,ch.[login]
      ,ch.[attempt_result]
      ,ch.[hangup_initiator]
      ,ch.[attempt_number]
      ,ch.[session_id]
      ,ch.[calldispositiontitle]
      ,ch.[unblocked_time]
,      cl.connected                  call_legs_connected
,      cl.ended                      call_legs_ended
, getdate() as created
	into #t3
from        #ch_robo_ivr ch with(nolock)
left join   NaumenDbReport.dbo.call_legs                cl   with(nolock)   on cl.session_id = ch.session_id and cl.leg_id = 1
               
--where ch.projectuuid = 'corebo00000000000n8i9hcja56hji2o' and attempt_start>='20200901'
;

with v as (select *, ROW_NUMBER() over(partition by session_id order by (select 1)) rn from #t3) delete from v where rn>1





--drop table if exists feodor.dbo.dm_robo_ivr_calls_history 
--select * into feodor.dbo.dm_robo_ivr_calls_history from #t3


--CREATE CLUSTERED INDEX [Cl_Idx_lcrm_id] ON feodor.dbo.dm_robo_ivr_calls_history 
--(
--	[lcrm_id] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
--
--
--
--
--CREATE NONCLUSTERED INDEX [NonClusteredIndex_attempt_start] ON feodor.dbo.dm_robo_ivr_calls_history 
--(
--	[attempt_start] DESC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

--declare @start_date_update date = cast(getdate() -4 as date)

begin tran

delete from feodor.dbo.dm_robo_ivr_calls_history where attempt_start>=@start_date_update
insert into feodor.dbo.dm_robo_ivr_calls_history
select * from #t3

commit tran


drop table if exists #count_dist_case_over_cost_period

;
with sess as (
select case 
	when day(attempt_start)>=9 then cast(format(attempt_start, 'yyyy-MM-09') as datetime)
	when day(attempt_start)<9  then dateadd(month, -1, cast(format(attempt_start, 'yyyy-MM-09') as datetime))
	end attempt_start_period, uuid
	from feodor.dbo.dm_robo_ivr_calls_history  sess
	where call_legs_ended is not null
	)

select 
	attempt_start_period
	, COUNT(distinct uuid) cases_robo_ivr
	, getdate() as created
			into #count_dist_case_over_cost_period
	from  sess
	group by 
	attempt_start_period

	select 1

delete from feodor.dbo.dm_robo_ivr_cost_history where attempt_start_period in (select attempt_start_period from #count_dist_case_over_cost_period)
insert into feodor.dbo.dm_robo_ivr_cost_history

select attempt_start_period                   
,      dateadd(month, 1, attempt_start_period) attempt_start_period_end
,      cases_robo_ivr                         
,      created                  
,case 
            when cases_robo_ivr <= 1600000 then 5.5
            when cases_robo_ivr >  1600000 and cases_robo_ivr <= 4000000 then 5.0
            when cases_robo_ivr >  4000000 and cases_robo_ivr <= 8000000 then 4.66
            when cases_robo_ivr >  8000000 then 4.15
            else 0
        end as cost      
		
--		into  feodor.dbo.dm_robo_ivr_cost_history

from #count_dist_case_over_cost_period

--select * from feodor.dbo.dm_robo_ivr_cost_history
--order by 1

--select * from feodor.dbo.dm_robo_ivr_cost_history
drop table if exists #dm_robo_ivr_leads_history_cube
;
with v as  (
select ДатаЛидаЛСРМ, 
isnull(lh.creationdate, r_ch.creationdate) creationdate , 
[Группа каналов], 
[Канал от источника] ,
id
, r_ch.attempt_start
, r_ch.call_legs_connected
, case when r_ch.attempt_result='abandoned' and queue_time >0 and r_ch.[login] is null then r_ch.attempt_start end abandoned, r_ch.attempt_result, r_ch.login
, case when r_ch.call_legs_connected is not null then 1 else 0 end robo_dialog
, case when datediff(second, r_ch.call_legs_connected, r_ch.call_legs_ended) is not null then datediff(second, r_ch.call_legs_connected, r_ch.call_legs_ended) else 0 end robo_dialog_duration
, case when datediff(second, r_ch.call_legs_connected, r_ch.call_legs_ended) <=10 then 1 else 0 end robo_short_dialog 
, case when datediff(second, r_ch.call_legs_connected, r_ch.call_legs_ended) >10 then datediff(second, r_ch.call_legs_connected, r_ch.call_legs_ended) else 0 end robo_long_dialog_duration 
, ФлагЗаявка
, IsInstallment
, ЗаемВыдан
, ВыданнаяСумма
, ФлагПрофильныйИтог
from Feodor.dbo.dm_leads_history lh  with(nolock)
left join  feodor.dbo.dm_robo_ivr_calls_history r_ch on lh.id=r_ch.lcrm_id
where CompanyNaumen='Отп. FEDOR ROBO IVR'

)
, v_cost as (
select ДатаЛидаЛСРМ
,      cast(creationdate as date) creationdate_date
,      [Группа каналов]
,      [Канал от источника]
,      id
,      attempt_start
,      call_legs_connected
,      abandoned
,      attempt_result
,      login
,      robo_dialog
,      robo_dialog_duration
,      robo_short_dialog
,      robo_long_dialog_duration
, (robo_dialog*15 + (robo_long_dialog_duration - (robo_dialog - robo_short_dialog)*10)*isnull(costs.cost, 5.5))/100 one_call_cost

, case when attempt_result in ( 'busy' , 'no_answer', 'amd', 'abandoned', 'not_found', 'declined') then attempt_result else 'Другая прчина' end attempt_result_bucket
, case when login is not null then 1 end as ПризнакДозвон
, case when attempt_start is not null then 1 end as ПризнакОбработан
, ФлагЗаявка
, IsInstallment
, ЗаемВыдан
, ВыданнаяСумма
, ФлагПрофильныйИтог

from v
left join Feodor.dbo.dm_robo_ivr_cost_history costs on v.attempt_start between costs.attempt_start_period and costs.attempt_start_period_end



),
 v_window as (
 select 
	   ДатаЛидаЛСРМ
,      creationdate_date
,      [Группа каналов]
,      [Канал от источника]
,      ФлагЗаявка
,      IsInstallment
,      ЗаемВыдан
,      ВыданнаяСумма
,      id
,      call_legs_connected
,      abandoned
,      login
,      robo_dialog
,      attempt_start
,      robo_dialog_duration
,      robo_short_dialog
,      robo_long_dialog_duration
,      one_call_cost
,      ФлагПрофильныйИтог
,      attempt_result_bucket
,	ROW_NUMBER() over(partition by id order by attempt_start  desc) rn
,	sum(one_call_cost) over(partition by id   ) sum_one_call_cost_over_id
,	sum(robo_dialog              ) over(partition by id   ) sum_robo_dialog_over_id
,	sum(robo_dialog_duration     ) over(partition by id   ) sum_robo_dialog_duration_over_id
,	sum(robo_short_dialog        ) over(partition by id   ) sum_robo_short_dialog_over_id
,	sum(robo_long_dialog_duration) over(partition by id   ) sum_robo_long_dialog_duration_cost_over_id
,	sum(ПризнакДозвон) over(partition by id   ) sum_ПризнакДозвон_over_id
,	sum(ПризнакОбработан) over(partition by id) sum_ПризнакОбработан_over_id
 from v_cost

 )

select ДатаЛидаЛСРМ
,      creationdate_date
,      [Группа каналов]
,      [Канал от источника]
,      IsInstallment
,      count(*) as Лидов
,      sum(ФлагЗаявка) as Заявок
,      count(ЗаемВыдан) as Выдач
,      sum(ВыданнаяСумма) as ВыданнаяСумма
,      count(creationdate_date) as ЛидовСозданоНаумен
,      count(call_legs_connected) as Соединено
,      count(abandoned) as ПотерянныйВызов
,      count(sum_ПризнакДозвон_over_id) as Дозвон
,      sum(ФлагПрофильныйИтог) as ПрофильныхЛидов
,      count(sum_ПризнакОбработан_over_id) as Обработано
,      sum(sum_ПризнакОбработан_over_id) as ЧислоПопыток
,      sum(sum_robo_dialog_over_id) as sum_sum_robo_dialog_over_id
,      sum(sum_robo_short_dialog_over_id) as sum_sum_robo_short_dialog_over_id
,      sum(sum_robo_dialog_duration_over_id) as sum_sum_robo_dialog_duration_over_id
,      sum(sum_robo_long_dialog_duration_cost_over_id) as sum_sum_robo_long_dialog_duration_cost_over_id
,      count(case when attempt_result_bucket = 'busy' then 1 end) as Занято
,      count(case when attempt_result_bucket = 'no_answer' then 1 end) as НетОтвета
,      count(case when attempt_result_bucket = 'amd' then 1 end) as Автоотвечтик
,      count(case when attempt_result_bucket = 'abandoned' then 1 end) as Отклонен
,      count(case when attempt_result_bucket = 'not_found' then 1 end) as НеНайдено
,      count(case when attempt_result_bucket = 'Другая прчина' then 1 end) as ДругаяПрчина
,      sum(sum_one_call_cost_over_id) as Стоимость
,      GETDATE() as created
into #dm_robo_ivr_leads_history_cube
from v_window
where rn=1
group by ДатаЛидаЛСРМ
,      creationdate_date
,      [Группа каналов]
,      [Канал от источника]
,      [Канал от источника]
,      IsInstallment

begin tran
truncate table feodor.dbo.dm_robo_ivr_leads_history_cube
--drop table if exists feodor.dbo.dm_robo_ivr_leads_history_cube
insert into feodor.dbo.dm_robo_ivr_leads_history_cube
select * -- into feodor.dbo.dm_robo_ivr_leads_history_cube
from  #dm_robo_ivr_leads_history_cube

commit tran


--select * from Feodor.dbo.dm_robo_ivr_leads_history_cube
--order by 1,2


-- select case 
--	when day(attempt_start)>=9 then cast(format(attempt_start, 'yyyy-MM-09') as datetime)
--	when day(attempt_start)<9  then dateadd(month, -1, cast(format(attempt_start, 'yyyy-MM-09') as datetime))
--	end attempt_start_period, sum(one_call_cost) from  v_window
--	group by case 
--	when day(attempt_start)>=9 then cast(format(attempt_start, 'yyyy-MM-09') as datetime)
--	when day(attempt_start)<9  then dateadd(month, -1, cast(format(attempt_start, 'yyyy-MM-09') as datetime))
--	end 
end
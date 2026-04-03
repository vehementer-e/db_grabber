
CREATE   PROCEDURE [dbo].[Подготовка детализации для отчета по входящим_тест] AS

begin



declare @report_date date = '20221019'  --getdate()-1
--declare @report_date date = '20230301'
drop table if exists #stg

select
	 que.session_id as session_id1,
	 que.enqueued_time,
	--(row_number() over(partition by que.session_id order by que.enqueued_time)) rn,
	cast(que.enqueued_time as date) Дата,
	cast(que.enqueued_time as time) Время,
		case
		when que.project_id = 'corebo00000000000mo7h48lkhskddq0' then '602'
		when que.project_id = 'corebo00000000000nf1gr88mis7g0h8' then '6015'
		when que.project_id = 'corebo00000000000mo7h32d3ncokg5s' then '606'
		when que.project_id = 'corebo00000000000mo7h3vl0ndnfdls' then '601' 
		when que.project_id = 'corebo00000000000nr6bbt5anb49tqg' then '6016'
		when que.project_id = 'corebo00000000000o3btdr1akgbovcs' then '6021'
		when que.project_id = 'corebo00000000000ohm3b0kt0538108' then '6025'
		when que.project_id = 'corebo00000000000o7pjf9oc3oeon68' then '6023'
		when que.project_id = 'corebo00000000000o9i1oee06gi0du8' then '6024'
		--else '6021'
	end Проект,
	coalesce(clOp.dst_abonent,case when clNum.dst_abonent_type = 'SP' then clNum.dst_abonent else clNum.dst_id end) as 'Номер абонента, принявшего вызов',
	case when clFirst.src_abonent_type = 'SP' then clFirst.src_abonent else clFirst.src_id end as abonent,
	-- que.unblocked_time as unblocked_time,
	-- case when que.unblocked_time is not NULL then datediff(ss,que.enqueued_time,que.unblocked_time) else datediff(ss,que.enqueued_time,que.dequeued_time) end as ivrtime,
	que.final_stage as 'Время принудительного ролика',
	case when que.unblocked_time is not NULL then datediff(ss,que.unblocked_time,que.dequeued_time) else 0 end as  'Время ожидания в очереди',
	-- ph.calldispositiontitle as callresult,
	--coalesce(clOp.created,clNum.created) as nextCreated,
	--coalesce(clOp.connected,clNum.connected) as nextConnected,
	--coalesce(clOp.ended,clNum.ended) as nextEnded,
	--coalesce(datediff(ss,clOp.created,clOp.connected),datediff(ss,clNum.created,clNum.connected)) as pickupTime,
	coalesce(datediff(ss,clOp.connected,clOp.ended),datediff(ss,clNum.connected,clNum.ended)) as speakingTime,
	coalesce(ph.wrapuptime,0) as wrapuptime


into #stg
from
	NaumenDbReport.dbo.queued_calls que
	join NaumenDbReport.dbo.call_legs clFirst on (clFirst.session_id = que.session_id and clFirst.leg_id = que.first_leg_id)
	left join NaumenDbReport.dbo.call_legs clOp on (clOp.session_id = que.session_id and clOp.leg_id = que.next_leg_id and que.final_stage = 'operator')
	left join NaumenDbReport.dbo.call_legs clNum on (clNum.session_id = que.session_id and clNum.leg_id = que.next_leg_id and que.final_stage = 'redirect')
	left join NaumenDbReport.dbo.mv_employee emp on (emp.login = clOp.dst_abonent or emp.login = clNum.dst_abonent)
	left join NaumenDbReport.dbo.mv_incoming_call_project inc on (inc.uuid = que.change_call_project and que.final_stage = 'changecallproject')
	left join NaumenDbReport.dbo.mv_phone_call ph on (ph.projectuuid = que.project_id and ph.sessionid = que.session_id and ph.operatoruuid = emp.uuid)
	--left join "V_ALL_OPERATOR_CALLS" op on que.session_id=op."SESSION_ID"
where
cast(que.enqueued_time as date) between @report_date and cast(getdate()-1 as date)  --and cast(getdate() as date)
--que.enqueued_time between '20220906' and '20220908'
and que.project_id in 
	('corebo00000000000mo7h48lkhskddq0',	--602
	'corebo00000000000nf1gr88mis7g0h8',		--6015
	'corebo00000000000mo7h32d3ncokg5s',		--6003
	'corebo00000000000mo7h3vl0ndnfdls',		--6001
	'corebo00000000000o3btdr1akgbovcs',     --6021
	'corebo00000000000ohm3b0kt0538108',     --6025
	'corebo00000000000nr6bbt5anb49tqg',     --6016
	'corebo00000000000o7pjf9oc3oeon68',     --6023
	'corebo00000000000o9i1oee06gi0du8')		--6024

	--select * from NaumenDbReport.dbo.mv_incoming_call_project

drop table if exists #602

select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #602
from #stg
where   Проект = '602' and 
case 
when   cast(format( Дата  , 'yyyy-MM-01') as date) >='20230301' and  Время  between '08:00:00.000000' and  '20:00:00.000000' then 1
when  cast(format( Дата  , 'yyyy-MM-01') as date) <'20230301' and  Время  between '10:00:00.000000' and  '19:00:00.000000' then 1
end = 1
order by Проект, Дата,Время




drop table if exists #6015
select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #6015
from #stg
where  Проект in ('6015')  
and 
case 
when   cast(format( Дата  , 'yyyy-MM-01') as date) >='20230301' and  Время  between '08:00:00.000000' and  '20:00:00.000000' then 1
when   cast(format( Дата  , 'yyyy-MM-01') as date) <'20230301' and  Время   between '09:00:00.000000' and  '18:00:00.000000' then 1
end = 1	 
order by Проект, Дата,Время


drop table if exists #6025
select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #6025
from #stg
where  Проект in ('6025')  
and 
case 
when   cast(format( Дата  , 'yyyy-MM-01') as date) >='20230301' and  Время  between '08:00:00.000000' and  '20:00:00.000000' then 1
when   cast(format( Дата  , 'yyyy-MM-01') as date) <'20230301' and  Время   between '09:00:00.000000' and  '18:00:00.000000' then 1
end = 1


order by Проект, Дата,Время



drop table if exists #6021
select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #6021
from #stg
where  Проект in ('6021') and Время  between '09:00:00.000000' and  '18:00:00.000000'
order by Проект, Дата,Время


drop table if exists #601

select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #601
from #stg
where   Проект in ('601') and Время  between '07:00:00.000000' and  '22:00:00.000000'
order by Проект, Дата,Время

drop table if exists #606

select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #606
from #stg
where   Проект in ('606') and Время  between '08:00:00.000000' and  '22:00:00.000000'
order by Проект, Дата,Время

set datefirst 1

drop table if exists #6016

select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #6016
from #stg
where   Проект in ('6016') and Время  between '07:00:00.000000' and  '21:00:00.000000' and datepart(w,Дата) in (1,2,3,4,5)
union		 all
select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
from #stg
where   Проект in ('6016') and Время  between '08:00:00.000000' and  '21:00:00.000000' and datepart(w,Дата) in (6,7)
order by Проект, Дата,Время

drop table if exists #6023

select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #6023
from #stg
where   Проект in ('6023') and Время  between '08:00:00.000000' and  '20:00:00.000000'
order by Проект, Дата,Время


drop table if exists #6024

select (row_number() over(partition by Дата,session_id1 order by enqueued_time)) rn,
	enqueued_time,
	Дата,
	Время,
	Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди]/3600.0/24.0 [Время ожидания в очереди],
	speakingTime/3600.0/24.0  'Время разговора',
	wrapuptime/3600.0/24.00 'Время постобработки'
into #6024
from #stg
where   Проект in ('6024') and Время  between '08:00:00.000000' and  '20:00:00.000000'
order by Проект, Дата,Время


drop table if exists #itog

select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки]
into #itog
from #602
where rn = 1
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #606
where rn = 1
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #601
where rn = 1
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #6015
where rn = 1
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #6021
where rn = 1
union all	select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #6025
where rn = 1
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #6016
where rn = 1
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #6023
where rn = 1
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #6024
where rn = 1
order by Проект, Дата, Время



begin tran
delete from Analytics.dbo.[Отчет по входящим] where Дата >= @report_date
insert into Analytics.dbo.[Отчет по входящим]
select *  from #itog
--order by 1, 2



commit tran

--begin tran
--delete from Analytics.dbo.[Отчет по входящим] where Дата >= '20230301'
--insert into Analytics.dbo.[Отчет по входящим]
--select *  from #itog
--commit tran


end
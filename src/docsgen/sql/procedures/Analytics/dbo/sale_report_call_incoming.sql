
CREATE   PROCEDURE [dbo].sale_report_call_incoming 
	
	@mode nvarchar(max) = 'update'
	,	@reloadDay smallint = 1
	AS
   

if @mode = 'select'
begin

select * from Analytics.dbo.[Отчет по входящим]

end


if @mode like 'update%'
begin


	
--declare @reloadDay  smallint = 150 , @mode nvarchar(max) = 'update'
declare @report_date date = dateadd(dd, -@reloadDay, getdate())
--declare @report_date date = '20250201'  , @mode nvarchar(max) = 'update'
--declare @report_date date = '20190101'  , @mode nvarchar(max) = 'update_old'

drop table if exists #stg

CREATE TABLE [dbo].[#stg](      [session_id1] [NVARCHAR](64)    , [enqueued_time] [DATETIME]    , [Дата] [DATE]    , [Время] [TIME]    , [Проект] [NVARCHAR](4000)    , [Номер абонента, принявшего вызов] [NVARCHAR](200)    , [abonent] [NVARCHAR](200)    , [Время принудительного ролика] [NVARCHAR](18)    , [Время ожидания в очереди] [INT]    , [speakingTime] [INT]    , [wrapuptime] [BIGINT]);



if @mode = 'update_old'
begin
insert 
into #stg

select
	 que.session_id as session_id1,
	 que.enqueued_time,
	--(row_number() over(partition by que.session_id order by que.enqueued_time)) rn,
	cast(que.enqueued_time as date) Дата,
	cast(que.enqueued_time as time) Время,
		case
		when  cp.dnis is not null then cp.dnis
		when que.project_id in('corebo00000000000mo7h48lkhskddq0', 'corebo00000000000pb04imt1kphohls')  then '602'
		when que.project_id in('corebo00000000000nf1gr88mis7g0h8')  then '6015'
		when que.project_id in('corebo00000000000mo7h32d3ncokg5s', 'corebo00000000000pb05dubs1j8mafk')  then '606'
		when que.project_id in('corebo00000000000mo7h3vl0ndnfdls', 'corebo00000000000pb05tu1f2p11a5k')  then '601' 
		when que.project_id in('corebo00000000000nr6bbt5anb49tqg','corebo00000000000pb05v4s02fleblo')  then '6016'
		when que.project_id in('corebo00000000000o3btdr1akgbovcs')  then '6021'
		when que.project_id in('corebo00000000000ohm3b0kt0538108','corebo00000000000pb04r4icjacpjtg')  then '6025'
		when que.project_id in('corebo00000000000o7pjf9oc3oeon68','corebo00000000000pb04u7kcn3oele0')  then '6023'
		when que.project_id in('corebo00000000000o9i1oee06gi0du8','corebo00000000000pb04vaasm147sb0')  then '6024'
		when que.project_id in('corebo00000000000mo7h2qdjl8l10jk','corebo00000000000pb07dt29l2t4c4s')  then '6008'
		when que.project_id in('corebo00000000000oip294qpjplppmo','corebo00000000000pb07cjuikrmb97k')  then '6029'
		when que.project_id in('corebo00000000000oiovstaolqp0bao','corebo00000000000pb07embu63k77j4')  then '6028'
		when que.project_id in('corebo00000000000mo7h2jc9jdocohc','corebo00000000000pb0674hr5fvokcc')  then '6006'
		when que.project_id in('corebo00000000000orhat02mho9gfqk','corebo00000000000pb04sjimm26f4po')  then '6031'
		
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


from
	NaumenDbReports_old.dbo.queued_calls que
	join NaumenDbReports_old.dbo.call_legs clFirst on (clFirst.session_id = que.session_id and clFirst.leg_id = que.first_leg_id)
	left join NaumenDbReports_old.dbo.call_legs clOp on (clOp.session_id = que.session_id and clOp.leg_id = que.next_leg_id and que.final_stage = 'operator')
	left join NaumenDbReports_old.dbo.call_legs clNum on (clNum.session_id = que.session_id and clNum.leg_id = que.next_leg_id and que.final_stage = 'redirect')
	left join NaumenDbReports_old.dbo.mv_employee emp on (emp.login = clOp.dst_abonent or emp.login = clNum.dst_abonent)
	left join NaumenDbReports_old.dbo.mv_incoming_call_project inc on (inc.uuid = que.change_call_project and que.final_stage = 'changecallproject')
	left join NaumenDbReport.dbo.mv_phone_call ph on (ph.projectuuid = que.project_id and ph.sessionid = que.session_id and ph.operatoruuid = emp.uuid)
	--left join "V_ALL_OPERATOR_CALLS" op on que.session_id=op."SESSION_ID"
join NaumenDbReports_old.dbo.mv_incoming_call_project cp on cp.uuid=que.project_id 
where
cast(que.enqueued_time as date) between @report_date and cast(getdate()-1 as date)  --and cast(getdate() as date)
--que.enqueued_time between '20220906' and '20220908'
--and que.project_id in 
--	('corebo00000000000mo7h48lkhskddq0',	--602
--	'corebo00000000000nf1gr88mis7g0h8',		--6015
--	'corebo00000000000mo7h32d3ncokg5s',		--6003
--	'corebo00000000000mo7h3vl0ndnfdls',		--6001
--	'corebo00000000000o3btdr1akgbovcs',     --6021
--	'corebo00000000000ohm3b0kt0538108',     --6025
--	'corebo00000000000nr6bbt5anb49tqg',     --6016
--	'corebo00000000000o7pjf9oc3oeon68',     --6023
--	'corebo00000000000o9i1oee06gi0du8',     --6024
--	'corebo00000000000mo7h2qdjl8l10jk',     --6008
--	'corebo00000000000oip294qpjplppmo',     --6029
--	'corebo00000000000oiovstaolqp0bao',		--6028
--	'corebo00000000000mo7h2jc9jdocohc',     --6006
--	'corebo00000000000orhat02mho9gfqk',   --6031
--	'corebo00000000000pb04imt1kphohls',  -- '602'
--    'corebo00000000000pb05dubs1j8mafk',  -- '606'
--    'corebo00000000000pb05tu1f2p11a5k',  -- '601' 
--    'corebo00000000000pb05v4s02fleblo',  -- '6016'
--    'corebo00000000000pb04r4icjacpjtg',  -- '6025'
--    'corebo00000000000pb04u7kcn3oele0',  -- '6023'
--    'corebo00000000000pb04vaasm147sb0',  -- '6024'
--    'corebo00000000000pb07dt29l2t4c4s',  -- '6008'
--    'corebo00000000000pb07cjuikrmb97k',  -- '6029'
--    'corebo00000000000pb07embu63k77j4',  -- '6028'
--    'corebo00000000000pb0674hr5fvokcc',  -- '6006'
--    'corebo00000000000pb04sjimm26f4po'  -- '6031'
--	
--	)		--6031
and cp.dnis in (


'6024', 
'6023', 
'6003', 
'6016', 
'6025', 
'6028', 
'6001', 
'6002', 
'6029', 
'6031', 
'6008', 
'6006', 
'6021', 
'6015'

)



end




if @mode = 'update'

begin
insert 
into #stg


select
	 que.session_id as session_id1,
	 que.enqueued_time,
	cast(que.enqueued_time as date) Дата,
	cast(que.enqueued_time as time) Время,
		case
		--when cp.dnis in ('6002', '6006', '6001' ) then replace( cp.dnis , '00', '0')
		when  cp.dnis is not null then cp.dnis
		when que.project_id in('corebo00000000000mo7h48lkhskddq0', 'corebo00000000000pb04imt1kphohls')  then '602'
		when que.project_id in('corebo00000000000nf1gr88mis7g0h8')  then '6015'
		when que.project_id in('corebo00000000000mo7h32d3ncokg5s', 'corebo00000000000pb05dubs1j8mafk')  then '606'
		when que.project_id in('corebo00000000000mo7h3vl0ndnfdls', 'corebo00000000000pb05tu1f2p11a5k')  then '601' 
		when que.project_id in('corebo00000000000nr6bbt5anb49tqg','corebo00000000000pb05v4s02fleblo')  then '6016'
		when que.project_id in('corebo00000000000o3btdr1akgbovcs')  then '6021'
		when que.project_id in('corebo00000000000ohm3b0kt0538108','corebo00000000000pb04r4icjacpjtg')  then '6025'
		when que.project_id in('corebo00000000000o7pjf9oc3oeon68','corebo00000000000pb04u7kcn3oele0')  then '6023'
		when que.project_id in('corebo00000000000o9i1oee06gi0du8','corebo00000000000pb04vaasm147sb0')  then '6024'
		when que.project_id in('corebo00000000000mo7h2qdjl8l10jk','corebo00000000000pb07dt29l2t4c4s')  then '6008'
		when que.project_id in('corebo00000000000oip294qpjplppmo','corebo00000000000pb07cjuikrmb97k')  then '6029'
		when que.project_id in('corebo00000000000oiovstaolqp0bao','corebo00000000000pb07embu63k77j4')  then '6028'
		when que.project_id in('corebo00000000000mo7h2jc9jdocohc','corebo00000000000pb0674hr5fvokcc')  then '6006'
		when que.project_id in('corebo00000000000orhat02mho9gfqk','corebo00000000000pb04sjimm26f4po')  then '6031'
	end Проект,
	coalesce(clOp.dst_abonent,case when clNum.dst_abonent_type = 'SP' then clNum.dst_abonent else clNum.dst_id end) as 'Номер абонента, принявшего вызов',
	case when clFirst.src_abonent_type = 'SP' then clFirst.src_abonent else clFirst.src_id end as abonent,
	que.final_stage as 'Время принудительного ролика',
	case when que.unblocked_time is not NULL then datediff(ss,que.unblocked_time,que.dequeued_time) else 0 end as  'Время ожидания в очереди',
	coalesce(datediff(ss,clOp.connected,clOp.ended),datediff(ss,clNum.connected,clNum.ended)) as speakingTime,
	coalesce(ph.wrapuptime,0) as wrapuptime
	 
from
	NaumenDbReport.dbo.queued_calls que
	join NaumenDbReport.dbo.call_legs clFirst on (clFirst.session_id = que.session_id and clFirst.leg_id = que.first_leg_id)
	left join NaumenDbReport.dbo.call_legs clOp on (clOp.session_id = que.session_id and clOp.leg_id = que.next_leg_id and que.final_stage = 'operator')
	left join NaumenDbReport.dbo.call_legs clNum on (clNum.session_id = que.session_id and clNum.leg_id = que.next_leg_id and que.final_stage = 'redirect')
	left join NaumenDbReport.dbo.mv_employee emp on (emp.login = clOp.dst_abonent or emp.login = clNum.dst_abonent)
	left join NaumenDbReport.dbo.mv_incoming_call_project inc on (inc.uuid = que.change_call_project and que.final_stage = 'changecallproject')
	left join NaumenDbReport.dbo.mv_phone_call ph on (ph.projectuuid = que.project_id and ph.sessionid = que.session_id and ph.operatoruuid = emp.uuid)
	--left join "V_ALL_OPERATOR_CALLS" op on que.session_id=op."SESSION_ID"
join NaumenDbReport.dbo.mv_incoming_call_project cp on cp.uuid=que.project_id 
where
cast(que.enqueued_time as date) between @report_date and cast(getdate()-1 as date) 
and cp.dnis in (


'6024', 
'6023', 
'6003', 
'6016', 
'6025', 
'6028', 
'6001', 
'6002', 
'6029', 
'6031', 
'6008', 
'6006',
'6021', 
'6015')
 
end


--select * from #stg
--select * from NaumenDbReport.dbo.mv_incoming_call_project where dnis = '606'
--select * from NaumenDbReport.dbo.mv_incoming_call_project where uuid = 'corebo00000000000pb05dubs1j8mafk'
--select * from NaumenDbReports_old.dbo.mv_incoming_call_project where uuid = 'corebo00000000000mo7h32d3ncokg5s'
 


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
where   Проект = '6002' and 
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
where   Проект in ('6001') and Время  between '06:00:00.000000' and  '22:00:00.000000'
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
where   Проект in ('6003') and Время  between '08:00:00.000000' and  '22:00:00.000000'
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


drop table if exists #6008

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
into #6008
from #stg
where   Проект in ('6008') and Время  between '09:00:00.000000' and  '18:00:00.000000'
order by Проект, Дата,Время


drop table if exists #6029

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
into #6029
from #stg
where   Проект in ('6029') and Время  between '09:00:00.000000' and  '18:00:00.000000'
order by Проект, Дата,Время


drop table if exists #6028

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
into #6028
from #stg
where   Проект in ('6028') and Время  between '09:00:00.000000' and  '18:00:00.000000'
order by Проект, Дата,Время


drop table if exists #6006

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
into #6006
from #stg
where   Проект in ('6006') and Время  between '10:00:00.000000' and  '19:00:00.000000'
order by Проект, Дата,Время


drop table if exists #6031

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
into #6031
from #stg
where   Проект in ('6031') and Время  between '08:00:00.000000' and  '20:00:00.000000'
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
union all
select Дата,
Время,
Проект,
	[Номер абонента, принявшего вызов],
	abonent,
	[Время принудительного ролика],
	[Время ожидания в очереди],
	[Время разговора],
	[Время постобработки] from #6008
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
	[Время постобработки] from #6029
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
	[Время постобработки] from #6028
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
	[Время постобработки] from #6006
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
	[Время постобработки] from #6031
where rn = 1
order by Проект, Дата, Время


--select * from  #itog
--where  проект in (6023, 6024)
--	order by 1, 2
--declare @report_date date = '20221019'
begin tran
delete a from Analytics.dbo.[Отчет по входящим_] a join #itog b on a.Дата=b.Дата
insert into Analytics.dbo.[Отчет по входящим_]
select *  from #itog 
--order by 1, 2

			 -- select * into Analytics.dbo.[Отчет по входящим_]  from Analytics.dbo.[Отчет по входящим]

commit tran

--begin tran
--delete from Analytics.dbo.[Отчет по входящим] where Дата >= '20230301'
--insert into Analytics.dbo.[Отчет по входящим]
--select *  from #itog
--commit tran


end
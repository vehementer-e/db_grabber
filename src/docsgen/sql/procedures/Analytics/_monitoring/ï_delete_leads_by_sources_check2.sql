
CREATE         proc [_monitoring].[leads_by_sources_check2]
@mode nvarchar(max) = 'update'			 
as
begin


if @mode = 	  'update'
begin

set datefirst 1

drop table if exists #TMP_leads	

declare @run_start0 datetime = getdate()
if  datepart(hour,@run_start0) between 1 and 8 return
declare @run_start datetime = case when    datepart(hour,@run_start0)=0 then dateadd(second, -1, cast(cast(@run_start0 as date) as datetime)) else @run_start0 end
declare @report_d date = @run_start
declare @report_h int = case when    datepart(hour,@run_start0)=0 then 23 else  datepart(hour, @run_start )-1	end
declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end

	


select id cnt, uf_source uf_source
, [UF_APPMECA_TRACKER]  [UF_APPMECA_TRACKER]
, [Группа каналов]  [Группа каналов]
--, UF_PARTNER_ID  UF_PARTNER_ID
, [UF_REGISTERED_AT_date]  [UF_REGISTERED_AT_date]
, UF_LOGINOM_STATUS  UF_LOGINOM_STATUS
, [Канал от источника]  [Канал от источника]
, UF_TYPE  UF_TYPE
into #t from dbo.dm_lcrm_leads_for_report where
1=0--[UF_REGISTERED_AT_date]>=@last_month_start

--insert into #t
--select count(checksum(id)) cnt, source , appmetrica , channel_group ,   date , marketing_status,channel , type    from v_lead
--  where
-- cast(created_at_time as date)>=@last_month_start
--							   
-- and datepart(hour, created ) <=		  datepart(hour, getdate() )
-- group by 	source , appmetrica , channel_group ,  date , marketing_status,channel , type 


drop table if exists #tm1	

select 1 cnt,id, phone, source , appmetrica , channel_group ,   date [UF_REGISTERED_AT_date] ,   channel    into #tm1   from v_lead
   where
 cast(created_at_time as date)>=@last_month_start
							   
 and datepart(hour, created ) <=		 @report_h




 --select * from 	  #TMP_leads
 --where uf_source='devtek'
 --order by 5 desc



--select  dateadd(day, -31, @report_d)
--select  dateadd(day, -8, @report_d)
--select  dateadd(day, -1, @report_d)
--;

--drop table if exists #t0
--select *, dbo.lcrm_source_of_cpa_trafic_mp([UF_APPMECA_TRACKER]) [Трафик в МП источник] into #t0
--from #t

/*
declare @report_d date = getdate()-1
declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end
set datefirst 1
*/

--declare @report_d date = getdate()	  declare @report_h int =  datepart(hour, getdate() )-1	   declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date)) declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end

drop table if exists #t1
drop table if exists #agr
--select datepart(dw, @report_d)
;

with  

leads as (
       
	   
	   select 1 as order_num,  type = '' , gr = source , *  from #tm1  a            where      source <>''
union all	   select 1 as order_num,  type = '' , gr = 'cpc all' , *  from #tm1  a            where       channel_group='CPC'
--union all select 2 as order_num,  type = 'Вебмастер (> 1 з. 30д.)' , gr = UF_SOURCE+' - '+UF_PARTNER_ID, * from #t  a  where isnull(UF_SOURCE, '')  <>'' and isnull(UF_PARTNER_ID, '')  <>''
--union all select 3 as order_num,  type = 'Партнерские лиды по лендингами' , gr = 'Партнерские лиды'+' - '+UF_TYPE, * from #t  a  where [Канал от источника]='Партнерские лиды'
union all select 4 as order_num,  type = '' , gr = 'партнерские лиды', * from #tm1  a  where channel='Партнерские лиды'
--union all select 5 as order_num,  type = 'CPC итого' , gr = 'CPC итого', * from #t  a  where [Группа каналов]='CPC'
union all select 6 as order_num,  type = '' , gr = channel , * from #tm1  a  where channel_group='CPC'
union all select 6 as order_num,  type = '' , gr = channel , * from #tm1  a  where channel_group='CPA'
--union all select 7 as order_num,  type = '' , gr = [Трафик в МП источник] , * from #t  a  where  [Трафик в МП источник] is not null


)
,  tmp_leads as (

select *
, [type_group] = cast( 'leads ' as nvarchar(100))
--, case when isnull(UF_LOGINOM_STATUS, '') <> 'declined' then 1 else 0 end as [Признак одобренный лид]
, case when datepart(dw, [UF_REGISTERED_AT_date]) <=5 then 1 else 0 end lead_work_day
from leads a 
--union all
--select *
--, [type_group] = 'accepted'
----, case when isnull(UF_LOGINOM_STATUS, '') <> 'declined' then 1 else 0 end as [Признак одобренный лид]
--, case when datepart(dw, [UF_REGISTERED_AT_date]) <=5 then 1 else 0 end lead_work_day
--from leads a 
--where isnull(UF_LOGINOM_STATUS, '') = 'accepted'
)

select 
b.type ,
b.gr,
b.order_num,
'КОЛ-ВО'   [type_group],
b.[UF_REGISTERED_AT_date],			
  cast(sum(case when 1=1 then cnt end)   as float)             МЕТРИКА,
 cast(sum(case when 1=1 then cnt end)   as float)        [Лидов ВСЕГО]--,
--cast(sum(case when 1=1 and lead_work_day=1 then cnt end) as float) [Лидов рабочие дни], 
--cast(sum(case when 1=1 and lead_work_day=0 then cnt end) as float) [Лидов выходные]
into #agr
from tmp_leads b
where [type_group] = 'leads '
group by
b.type ,
b.gr,
b.order_num,
 [type_group],
b.[UF_REGISTERED_AT_date]
union all
select 
b.type ,
b.gr,
b.order_num,
'% УНИКАЛЬНЫХ'   [type_group],
b.[UF_REGISTERED_AT_date],
100*count(distinct phone ) / nullif((0.0+cast(sum(case when 1=1 then cnt end)   as float)     )   ,0)           МЕТРИКА,
 cast(sum(case when 1=1 then cnt end)   as float)        [Лидов ВСЕГО]--,
--cast(sum(case when 1=1 and lead_work_day=1 then cnt end) as float) [Лидов рабочие дни], 
--cast(sum(case when 1=1 and lead_work_day=0 then cnt end) as float) [Лидов выходные]
 from tmp_leads b
where [type_group] = 'leads '
group by
b.type ,
b.gr,
b.order_num,
b.[type_group],
b.[UF_REGISTERED_AT_date]
--select * from #agr

--declare @report_d date = getdate()	  declare @report_h int =  datepart(hour, getdate() )-1	   declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date)) declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end

;

with
tmp_leads_sum as (
--declare @report_d date = getdate()	  declare @report_h int =  datepart(hour, getdate() )-1	   declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date)) declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end

select 
a.type ,
a.gr,
a.order_num,
t.[type_group],
c.Дата [UF_REGISTERED_AT_date],
1-c.[Признак выходной] work_day,
CASE WHEN t.[type_group] = 'КОЛ-ВО' THEN isnull(cast(МЕТРИКА              as float) , 0) ELSE cast(МЕТРИКА              as float) END МЕТРИКА,
isnull(cast([Лидов ВСЕГО]              as float) , 0) [Лидов ВСЕГО]--,
--isnull(cast([Лидов рабочие дни]  as float) , 0) [Лидов рабочие дни],
--isnull(cast([Лидов выходные]     as float) , 0) [Лидов выходные]
from 
(select distinct 
type ,
gr,
order_num
from 
#agr ) a
cross join (select distinct [type_group]  from 
#agr ) t
join v_Calendar c on c.Дата between @last_month_start and @report_d
left join #agr b on a.gr=b.gr and a.order_num=b.order_num and a.type=b.type and t.type_group=b.type_group and b.UF_REGISTERED_AT_date=c.Дата
)

, v as (
select gr
, type
, order_num
, [type_group]
, isnull(avg(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) and work_day=1 then МЕТРИКА end), null) [Лидов будние среднее с начала прошлого месяца] 
, isnull(avg(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) and work_day=0 then МЕТРИКА end)   , null) [Лидов выходные среднее с начала прошлого месяца] 
, isnull(avg(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) then МЕТРИКА end)   , null) [Лидов среднее с начала прошлого месяца] 
, isnull(stdev(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) then МЕТРИКА end)   , null) [Лидов среднее отклонение с начала прошлого месяца] 
,  (
   isnull(sum(case when  [UF_REGISTERED_AT_date] = @report_d  then МЕТРИКА end)  , null)
-  isnull(avg(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d)  then МЕТРИКА end)   , null)
  )/ nullif(stdev(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) then МЕТРИКА end)   , 0)  [Отклонение] 

 , isnull(stdev(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d)  and work_day=1 then МЕТРИКА end)   , null) [Лидов рабочие дни среднее отклонение с начала прошлого месяца] 
,  (
   isnull(sum(case when  [UF_REGISTERED_AT_date] = @report_d and work_day=1  then МЕТРИКА end)  , null)
-  isnull(avg(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) and work_day=1  then МЕТРИКА end)   , null)
  )/ nullif(stdev(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d)  and work_day=1 then МЕТРИКА end)   , 0) [Отклонение рабочие дни] 

	   
 , isnull(stdev(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d)  and work_day=0 then МЕТРИКА end)   , null) [Лидов выходные среднее отклонение с начала прошлого месяца] 
,  (
   isnull(sum(case when  [UF_REGISTERED_AT_date] = @report_d  and work_day=0  then МЕТРИКА end)  , null)
-  isnull(avg(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d)  and work_day=0  then МЕТРИКА end)   , null)
  )/ nullif(stdev(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d)   and work_day=0 then МЕТРИКА end)   , 0)  [Отклонение выходные] 



, isnull(sum(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) then [Лидов ВСЕГО] end) , 0) [Лидов 30 дней] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] between dateadd(day, -7, @report_d) and dateadd(day, -1, @report_d)  then МЕТРИКА end) , 0) [Лидов 7 дней] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -1 ,@report_d  ) then МЕТРИКА end)                                      , 0) [Лидов t-1] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -2 ,@report_d  ) then МЕТРИКА end)                                      , 0) [Лидов t-2] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -3 ,@report_d  ) then МЕТРИКА end)                                      , 0) [Лидов t-3] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -4 ,@report_d  ) then МЕТРИКА end)                                      , 0) [Лидов t-4] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -5 ,@report_d  ) then МЕТРИКА end)                                      , 0) [Лидов t-5] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -6 ,@report_d  ) then МЕТРИКА end)                                      , 0) [Лидов t-6] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -7 ,@report_d  ) then МЕТРИКА end)                                      , 0) [Лидов t-7] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = @report_d  then МЕТРИКА end)                                                         , 0) [Лидов вчера] 

from tmp_leads_sum a

group by gr
, type
, order_num
, [type_group]
)

select *
, 
case 
when @report_d_work_day=1 then [Лидов рабочие дни среднее отклонение с начала прошлого месяца] --else 
when @report_d_work_day=0 then [Лидов выходные среднее отклонение с начала прошлого месяца] --else 
end
[Лидов рабочие/выходные среднее отклонение]	
, 
case 
when @report_d_work_day=1 then [Отклонение рабочие дни] --else 
when @report_d_work_day=0 then [Отклонение выходные] --else 
end
[Отклонение рабочие/выходные]	 
, 
case 
when @report_d_work_day=1 then ([Лидов вчера]-[Лидов будние среднее с начала прошлого месяца])/  nullif([Лидов будние среднее с начала прошлого месяца]  , 0) --else 
when @report_d_work_day=0 then ([Лидов вчера]-[Лидов выходные среднее с начала прошлого месяца])/nullif([Лидов выходные среднее с начала прошлого месяца], 0) --else 
end
[Дельта %]
, @report_d_work_day [Признак рабочий день]
, case when @report_d_work_day = 1 then [Лидов будние среднее с начала прошлого месяца] else [Лидов выходные среднее с начала прошлого месяца] end [Лидов будние/выходные среднее с начала прошлого месяца]
into #t1 
from v 
--where [Лидов accepted 30 дней]>100
order by [Лидов 30 дней] desc

drop table if exists #stat
select Источник, Вебмастер, [Заем выдан], isinstallment  into #stat from reports.dbo.dm_Factor_Analysis_001
where cast([Заем выдан] as date) between  dateadd(day, -31, @report_d)	  and dateadd(day, -1, @report_d)
and 1=0
drop table if exists #f



select *,  
important_decreading =  
 
 case when ([Дельта %]<=0 or [Дельта %] is null)	  then 1 else 0 end
   into #f 

from (
select a.*
, @run_start as created
,x.cnt0 
,x1.cnt1 
,x.cnt0_inst 
,x1.cnt1_inst 
,x.cnt0_pts 
,x1.cnt1_pts
from #t1 a
outer apply (select count(*)  cnt0

,  count(case when isinstallment=1 then 	[Заем выдан] end ) cnt0_inst
,  count(case when isinstallment=0 then 	[Заем выдан] end ) cnt0_pts
from   
#stat b where 
b.Источник  = a.gr 
and a.type='Источник (> 1 з. 30д.)'
) x
outer apply (
select count(*)  cnt1
,  count(case when isinstallment=1 then 	[Заем выдан] end ) cnt1_inst
,  count(case when isinstallment=0 then 	[Заем выдан] end ) cnt1_pts
from   
#stat b where 
b.Источник+' - '+b.Вебмастер  = a.gr 
and a.type= 'Вебмастер (> 1 з. 30д.)'
) x1
) x2


--declare @report_d date = getdate()	  declare @report_h int =  datepart(hour, getdate() )-1	   declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date)) declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end


ALTER 	TABLE #f ALTER COLUMN 	 type_group NVARCHAR(100)
update a set a.type_group = [type_group]+' на ' +format(@report_h , '0') +':59' from #f	 a


--drop table if exists [_monitoring].[leads_by_sources2]
--select * into  [_monitoring].[leads_by_sources2] from  #f

--order by [Лидов accepted 30 дней] desc
 --  order by 2, 1  , 4
if (select count(*) from #f)=0
begin

exec log_email 'Мониторинг наличия лидов от лидгенов - нет записей в таблице для вставки'
select 1/0

end

begin tran
--drop table if exists  [_monitoring].[leads_by_sources]
--select * into [_monitoring].[leads_by_sources]
--from #f
--where 
--case
--when type = 'Вебмастер' then case when cnt1>0 then 1 else 0 end 
--when type = 'Источник' then case when cnt0>0 then 1 else 0 end 
--else 1 end =1
--order by order_num, type_group, [Лидов 30 дней] desc
delete from  [_monitoring].[leads_by_sources2]
--drop table dbo.[Отчет мониторинг наличия лидов от лидгенов2]
insert into  [_monitoring].[leads_by_sources2]
select *  
from #f


--order by order_num, type_group, [Лидов 30 дней] desc

commit tran
--select * from Analytics.dbo.[Отчет мониторинг наличия лидов от лидгенов2]
--order by 2, 1

--drop table if exists dbo.[Отчет мониторинг поступления лидов статус]
--select getdate()dt into  dbo.[Отчет мониторинг поступления лидов статус]
--select * into dbo.[Отчет мониторинг наличия лидов от лидгенов2]

	
exec exec_python 'send_report_leads_monitoring2()', 1


end

if @mode = 'select'
begin


select 
  a.[gr]
 ,a.[type]
 ,a.[order_num]
 ,a.[type_group]
 ,a.[Лидов будние среднее с начала прошлого месяца]
 ,a.[Лидов выходные среднее с начала прошлого месяца]
 ,a.[Лидов среднее с начала прошлого месяца]
 ,a.[Лидов среднее отклонение с начала прошлого месяца]
 ,a.[Отклонение]
 ,a.[Лидов рабочие дни среднее отклонение с начала прошлого месяца]
 ,a.[Отклонение рабочие дни]
 ,a.[Лидов выходные среднее отклонение с начала прошлого месяца]
 ,a.[Отклонение выходные]
 ,a.[Отклонение рабочие/выходные]
 ,a.[Лидов рабочие/выходные среднее отклонение]
,   a.[Лидов 30 дней] 
,   a.[Лидов 7 дней] 
,   a.[Лидов t-1] 
,   a.[Лидов t-2] 
,   a.[Лидов t-3] 
,   a.[Лидов t-4] 
,   a.[Лидов t-5] 
,   a.[Лидов t-6] 
,   a.[Лидов t-7] 
,   a.[Лидов вчера] 
,   a.[Дельта %] 
,   a.[Признак рабочий день] 
,   a.[Лидов будние/выходные среднее с начала прошлого месяца] 
,   a.[created] 
,   a.[cnt0] 
,   a.[cnt1] 
,   a.[cnt0_inst] 
,   a.[cnt1_inst] 
,   a.[cnt0_pts] 
,   a.[cnt1_pts] 

from 

analytics._monitoring.leads_by_sources2 a
where	  (
type_group LIKE 'КОЛ-ВО%' AND
[Лидов среднее с начала прошлого месяца]>3 and abs([Отклонение рабочие/выходные])>1	 )

OR  (	 1=1 and
type_group LIKE '%УНИК%' AND
[Лидов среднее с начала прошлого месяца]>3  and [Лидов 30 дней]>90 AND [Лидов вчера]>0 and abs([Отклонение рабочие/выходные])>1  AND  ([Лидов вчера]-[Лидов будние/выходные среднее с начала прошлого месяца])<-40	 )
--where   a.[important_decreading] =1


--exec select_table 'analytics.[_monitoring].[leads_by_sources2]'

end
--if cast(getdate() as time) < '10:00'
--	WAITFOR TIME '10:00';  
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'D775BEE3-C836-4B8C-BD65-CC0E38FAFD2F'
end
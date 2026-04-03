
create   proc dbo.[_create_loginom_stat]
as
begin


drop table if exists #t1

select 	 
         cast(a.[sentAt]  as date) dt
, 	 count(   case when [isSuccess]=1 then [receivedAt_float]-	[sentAt_float] end)	 success_cnt
, 	 avg(   case when [isSuccess]=1 then [receivedAt_float]-	[sentAt_float] end)	 success_avg_time
, 	 max(   case when [isSuccess]=1 then [receivedAt_float]-	[sentAt_float] end)	 success_max_time
, 	 min(   case when [isSuccess]=1 then [receivedAt_float]-	[sentAt_float] end)	 success_min_time
, 	 stdevp(case when [isSuccess]=1 then [receivedAt_float]-	[sentAt_float] end)	 success_stdevp_time 
, 	 count(   case when [isSuccess]=0 then [receivedAt_float]-	[sentAt_float] end)	 fail_cnt
, 	 avg(   case when [isSuccess]=0 then [receivedAt_float]-	[sentAt_float] end)	 fail_avg_time
, 	 max(   case when [isSuccess]=0 then [receivedAt_float]-	[sentAt_float] end)	 fail_max_time
, 	 min(   case when [isSuccess]=0 then [receivedAt_float]-	[sentAt_float] end)	 fail_min_time
, 	 stdevp(case when [isSuccess]=0 then [receivedAt_float]-	[sentAt_float] end)	 fail_stdevp_time
,    count(*) cnt

into #t1

from 

Stg._LCRM.lcrm_TackingLoginom a
where	   cast(a.[sentAt]  as date)>=getdate()-4
group by cast( a.[sentAt]  as date)


--select * into _loginom_stat from #t1


begin tran

delete a from   _loginom_stat a join #t1 b on a.dt=b.dt
insert into  _loginom_stat
select * from  #t1


commit tran


end
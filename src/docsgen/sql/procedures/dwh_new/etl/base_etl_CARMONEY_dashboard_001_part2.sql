
-------------------------------------------------
--Вторая часть показателей для дашборда 001 CARMONEY
--
--
-------------------------------------------------
-- exec [etl].[base_etl_mt_requests_transition_mfo]

create PROCEDURE [etl].[base_etl_CARMONEY_dashboard_001_part2]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @month_days int;
set @month_days = day(eomonth(dateadd(dd,-1,cast(getdate() as date))));
--stat_v_balance2
			   select r_year,
                      r_month,
					  r_day,
					  r_date,
					  external_id,
					  overdue_days,
					  overdue_days_p,
					  lag(overdue_days)    over (partition by external_id order by r_date) as last_dpd,
					  lag(principal_rest)  over (partition by external_id order by r_date) as last_principal_rest,
                      (case when a.overdue_days <= 0   then '(1)_0'
	                        when a.overdue_days <= 30  then '(2)_1_30'
	                        when a.overdue_days <= 60  then '(3)_31_60'
	                        when a.overdue_days <= 90  then '(4)_61_90'
	                        when a.overdue_days <= 360 then '(5)_91_360'
	                        else '(6)_361+' end) as dpd_bucket,
                      (case when a.overdue_days_p <= 0   then '(1)_0'
	                        when a.overdue_days_p <= 30  then '(2)_1_30'
	                        when a.overdue_days_p <= 60  then '(3)_31_60'
	                        when a.overdue_days_p <= 90  then '(4)_61_90'
	                        when a.overdue_days_p <= 360 then '(5)_91_360'
	                        else '(6)_361+' end) as dpd_bucket_p,
                      (case when lag(overdue_days)    over (partition by external_id order by r_date) <= 0   then '(1)_0'
	                        when lag(overdue_days)    over (partition by external_id order by r_date) <= 30  then '(2)_1_30'
	                        when lag(overdue_days)    over (partition by external_id order by r_date) <= 60  then '(3)_31_60'
	                        when lag(overdue_days)    over (partition by external_id order by r_date) <= 90  then '(4)_61_90'
	                        when lag(overdue_days)    over (partition by external_id order by r_date) <= 360 then '(5)_91_360'
	                        else '(6)_361+' end) as dpd_bucket_last,
					  principal_rest,
					  principal_percents_rest,
					  pay_total
               into #t0
			   from (select cdate        as r_date,
                            year(cdate)  as r_year,
                            month(cdate) as r_month,
                            day(cdate)   as r_day,
					        external_id,
					        isnull(overdue_days,0)                     as overdue_days,
					        isnull(overdue_days_p,0)                   as overdue_days_p,
					        cast(isnull(principal_rest,   0) as float) as principal_rest,
					        cast(isnull(principal_rest,   0) as float) +
					        cast(isnull(percents_rest,    0) as float) as principal_percents_rest,
					        cast(isnull(principal_cnl,    0) as float) +
					        cast(isnull(percents_cnl,     0) as float) +
					        cast(isnull(fines_cnl,        0) as float) +
					        cast(isnull(otherpayments_cnl,0) as float) +
					        cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
					        row_number() over (partition by cdate, external_id order by cast(isnull(total_rest,0) as float) desc) as rn
                     from dwh_new.dbo.stat_v_balance2
			         where cdate >= cast(credit_date as date) and cdate <= dateadd(dd,-1,cast(getdate() as date))) a
			   where rn = 1;
      
	 select * into #t01
	 from #t0
	 where r_date >= '2018-01-01';
	  
	 update #t01 set last_principal_rest = 0       where last_dpd is null;
	 update #t01 set dpd_bucket_last     = '(1)_0' where last_dpd is null;
	 update #t01 set last_dpd            = 0       where last_dpd is null;

	 select *  into #tt
	 from (select a.*, b.r_day_n, @month_days as max_r_day_n -- update as per num days in month
	       from #t01 a
		   join (select r_date, row_number() over (order by r_date) as r_day_n
		         from (select distinct r_date from #t01 where r_date >= dateadd(dd,-31,cast(getdate() as date))) a) b on a.r_date = b.r_date
		   where a.r_date >= dateadd(dd,-@month_days,cast(getdate() as date))) a;

     drop table #t0;
	 
	                select r_year,
					       r_month,
						   r_day,
						   r_date,
						   external_id,
						   overdue_days,
						   principal_rest,
						   dpd_bucket,
						   seg1,
						   seg3,
					       (case when dpd_bucket <> next_dpd_bucket
						          and overdue_days > next_overdue_days then 'Improve'
						         when dpd_bucket <> next_dpd_bucket and overdue_days < next_overdue_days then 'Worse'
								 when dpd_bucket = next_dpd_bucket
								  and next_r_day - r_day + overdue_days > next_overdue_days then 'Improve'
								 else 'Same' end) as seg_rr
					into #t1
					from (
					select a.r_year,
                           a.r_month,
	                       a.r_day,
	                       a.r_date,
	                       a.external_id,
	                       a.overdue_days,
	                       a.principal_rest,
						   a.dpd_bucket,
						   a.seg1,
						   a.seg3,
						   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						          and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
								 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
								 else b.dpd_bucket end) as next_dpd_bucket,
						   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						          and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
								 then lead(a.overdue_days) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
								 else b.overdue_days end) as next_overdue_days,
						   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						          and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
								 then lead(a.r_day) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
								 else b.r_day end) as next_r_day
					from (select r_year,
                                 r_month,
	                             r_day,
	                             r_date,
	                             external_id,
	                             overdue_days,
	                             principal_rest,
	                             (case when overdue_days <= 0   then '(1)_0'
	                                   when overdue_days <= 30  then '(2)_1_30'
		                          	   when overdue_days <= 60  then '(3)_31_60'
		                          	   when overdue_days <= 90  then '(4)_61_90'
			                           when overdue_days <= 360 then '(5)_91_360'
			                           else '(6)_361+' end) as dpd_bucket,
	                             'som-old'  as seg1,
	                             ''         as seg2,
						         'ALL'      as seg3
                          from #t01 a
                          where r_day = 1
					        and overdue_days >= 1

                          union

                          select a.r_year,
                                 a.r_month,
	                             a.r_day,
	                             a.r_date,
	                             a.external_id,
	                             a.overdue_days,
	                             a.principal_rest,
	                             (case when a.overdue_days <= 0   then '(1)_0'
	                                   when a.overdue_days <= 30  then '(2)_1_30'
		                    	       when a.overdue_days <= 60  then '(3)_31_60'
		                    	       when a.overdue_days <= 90  then '(4)_61_90'
		                    	       when a.overdue_days <= 360 then '(5)_91_360'
		                    	       else '(6)_361+' end) as dpd_bucket,
	                             'new-old' as seg1,
	                             ''        as seg2,
						         'ALL'     as seg3
                          from #t01 a
                          where r_day > 1
					        and overdue_days in (1,31,61,91,361)) a
					      left join #t01 b on a.external_id = b.external_id
					                      and a.r_year      = b.r_year
								          and a.r_month     = b.r_month
								          and b.r_day       = (case when  year(dateadd(dd,-1,getdate())) = a.r_year
										                             and month(dateadd(dd,-1,getdate())) = a.r_month
																	then day(dateadd(dd,-1,getdate()))
																	else day(eomonth(a.r_date)) end)) a;
                      
                    select r_year,
					       r_month,
						   r_day,
						   r_date,
						   external_id,
						   overdue_days,
						   principal_rest,
						   dpd_bucket,
						   seg1,
						   seg3,
						   seg2 as seg_rr
	                into #t11
					from (select r_year,
                                 r_month,
	                             r_day,
	                             r_date,
	                             external_id,
	                             overdue_days_p      as overdue_days,
	                             last_principal_rest as principal_rest,
	                             (case when overdue_days_p <= 0   then '(1)_0'
	                                   when overdue_days_p <= 30  then '(2)_1_30'
		                          	   when overdue_days_p <= 60  then '(3)_31_60'
		                          	   when overdue_days_p <= 90  then '(4)_61_90'
		                          	   when overdue_days_p <= 360 then '(5)_91_360'
		                          	   else '(6)_361+' end) as dpd_bucket,
	                             'som-new' as seg1,
	                             'Improve' as seg2,
						         'ALL'    as seg3
                          from #t01 a
                          where r_day = 1 
					        and overdue_days_p >= 1
					        and overdue_days = 0
                      --and r_year = 2019 and r_month = 8 

                          union

                          select r_year,
                                 r_month,
	                             r_day,
	                             r_date,
	                             external_id,
	                             overdue_days_p      as overdue_days,
	                             last_principal_rest as principal_rest,
	                             (case when overdue_days_p <= 0   then '(1)_0'
	                                   when overdue_days_p <= 30  then '(2)_1_30'
		                          	 when overdue_days_p <= 60  then '(3)_31_60'
		                          	 when overdue_days_p <= 90  then '(4)_61_90'
		                          	 when overdue_days_p <= 360 then '(5)_91_360'
		                          	 else '(6)_361+' end) as dpd_bucket,
	                             'new-new' as seg1,
	                             'Improve' as seg2,
						         'ALL'     as seg3
                          from #t01 a
                          where r_day > 1
					        and overdue_days_p in (1,31,61,91,361)
					        and overdue_days = 0) a;

select *
into #t_all
from (select * from #t1
      union
	  select * from #t11) a;

drop table #t1;
drop table #t11;

	  select a.*,
             (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
			        and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
			       then (case when a.seg1 in ('som-new','new-new') then a.r_date
				              else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
		           else (case when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(2)_1_30'
						      then (case when dateadd(dd,30 - a.overdue_days,a.r_date) >= eomonth(a.r_date) then eomonth(a.r_date) else dateadd(dd,30 - a.overdue_days,a.r_date) end)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(3)_31_60'
						      then (case when dateadd(dd,60 - a.overdue_days,a.r_date) >= eomonth(a.r_date) then eomonth(a.r_date) else dateadd(dd,60 - a.overdue_days,a.r_date) end)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(4)_61_90'
						      then (case when dateadd(dd,90 - a.overdue_days,a.r_date) >= eomonth(a.r_date) then eomonth(a.r_date) else dateadd(dd,90 - a.overdue_days,a.r_date) end)
							  when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(5)_91_360'
						      then (case when dateadd(dd,360 - a.overdue_days,a.r_date) >= eomonth(a.r_date) then eomonth(a.r_date) else dateadd(dd,360 - a.overdue_days,a.r_date) end)
			                  else (case when dateadd(dd,-1,cast(getdate() as date)) <= eomonth(a.r_date)
							             then dateadd(dd,-1,cast(getdate() as date))
										 else eomonth(a.r_date) end) end) end) as r_end_date
	  into #all
      from #t_all a;

	  drop table #t_all;

	  merge into #all a
	  using (select b.external_id, b.r_date, dateadd(dd,-1,min(a.r_date)) as min_r
	         from #t01 a
	         join #all b on a.external_id = b.external_id 
	         where        b.seg1 in ('new-old','som-old')
			          and b.seg_rr = 'Improve'
			          and a.r_year  = b.r_year
			          and a.r_month = b.r_month
			          and a.r_day  >= b.r_day
			          and a.overdue_days_p < b.overdue_days
	         group by b.external_id, b.r_date) b
	  on a.external_id = b.external_id and a.r_date = b.r_date
	  when matched then update set a.r_end_date = b.min_r;

	  update #all  set r_end_date  = r_date  where seg1 in ('som-new','new-new');

select a.r_year,
       a.r_month,
	   a.r_day,
	   a.r_date,
	   a.r_end_date,
	   a.external_id,
	   a.overdue_days,
	   a.principal_rest,
	   a.dpd_bucket,
	   a.seg1,
	   a.seg3,
	   a.seg_rr,
	   sum(isnull(b.pay_total,0)) as pay_total
into #t000
from #all a
left join #t01           b on a.external_id = b.external_id and b.r_date >= a.r_date and b.r_date <= a.r_end_date
group by a.r_year,
         a.r_month,
	     a.r_day,
	     a.r_date,
	     a.r_end_date,
	     a.external_id,
	     a.overdue_days,
	     a.principal_rest,
	     a.dpd_bucket,
	     a.seg1,
		 a.seg3,
	     a.seg_rr;
		 
drop table #all;
drop table #t01;
drop table #tt;

drop table if exists #final_statistics
select a.r_year,
       a.r_month,
	   a.r_day,
	   a.dpd_bucket,
	   a.total_balance,
	   a.pay_total,
	   sum(isnull(b.principal_rest,0)) as improve_balance
into #final_statistics
from (select a.r_year,
             a.r_month,
	         a.r_day,
	         a.dpd_bucket,
	         sum(a.principal_rest)           as total_balance,
	         sum(a.pay_total)                as pay_total
      from #t000      a
	  group by a.r_year,
               a.r_month,
	           a.r_day,
	           a.dpd_bucket) a
left join #t000              b on a.r_year  =  year(b.r_end_date)
                              and a.r_month = month(b.r_end_date)
							  and a.r_day   =   day(b.r_end_date)
							  and a.dpd_bucket = b.dpd_bucket
							  and b.seg_rr  = 'Improve'
group by a.r_year,
         a.r_month,
	     a.r_day,
	     a.dpd_bucket,
	     a.total_balance,
	     a.pay_total;

drop table #t000;

select r_day, dpd_bucket, improve_balance, total_balance, pay_total
from #final_statistics
where r_year  =  year(eomonth(dateadd(dd,-1,cast(getdate() as date))))
  and r_month = month(eomonth(dateadd(dd,-1,cast(getdate() as date))))
order by r_day, dpd_bucket, improve_balance, total_balance, pay_total;


-----------------------------------------------------------
----------- Загрузка информации от рисковиков

if OBJECT_ID('tempdb.dbo.#collection_kpi') is not null drop table #collection_kpi

select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,getdate()),0) as date) as [Период] 
	   ,N'День' as [Периодичность]
	   ,N'Факт' [ПланФакт] 
	   ,cast(getdate() as date) as [ДатаУчета] 
	   , N'Коллекшн KPI' as [Показатель]
	   , r_day, dpd_bucket, improve_balance, total_balance, pay_total
into #collection_kpi 
from #final_statistics
--where r_year  =  year(eomonth(dateadd(dd,-1,cast(getdate() as date))))
--  and r_month = month(eomonth(dateadd(dd,-1,cast(getdate() as date))))
--order by r_day, dpd_bucket, improve_balance, total_balance, pay_total


select * 
into [dwh_new].[dbo].[CARMONEY_dashboard_001_part2_v01]
from #collection_kpi

--drop table if exists [dwh_new].[dbo].[CARMONEY_dashboard_001_part2_v01]

--select * from [dwh_new].[dbo].[CARMONEY_dashboard_001_part2_v01]
/*
insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[date]),0) as date) as [Период] 
	   ,N'Год' as [Периодичность] ,[ru_name] as [Показатель]
	   ,case when [type]=N'fact' then N'Факт' when [type]=N'plan' then N'План' else [type] end [ПланФакт] 
	   ,[value] as [Значение] ,cast(getdate() as date) as [ДатаУчета] 
--select *
from #dwh_new_dbo_dashboard_kpi where [rank_t]=1
*/



--end

/*
-- 2019-12-04
if OBJECT_ID('tempdb.dbo.#report_kpi') is not null drop table #report_kpi

select distinct *
into #report_kpi 
from reports.dbo.report_kpi
--where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО' ,N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням')
--group by [ПериодУчета] ,[НаименованиеЛиста]
--select * from #report_kpi

if OBJECT_ID('tempdb.dbo.#report_kpi2') is not null drop table #report_kpi2
select [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,sum([Колво]) as [Колво] 
into #report_kpi2 
from #report_kpi 
where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО' ,N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням')
group by [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста]

--select [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеПараметра] ,sum([Сумма]) as [Сумма] from #report_kpi 
--where [НаименованиеЛиста] in (N'KPI кредитный портфель') -- , N'KPI кредитный портфель_УМФО') 
--group by [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеПараметра] order by 1 desc
--select * from #report_kpi2 

--if not isnull(select * from #report_kpi2 where cast([ПериодУчета]-2 as date)=cast(dateadd(day,-1,getdate()) as date),0)=0

insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'KPI кредитный портфель' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)


insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Поступление процентов и пени' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'Платежи по процентам' ,N'Платежи по пеням')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)


insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Погашение ОД' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'Платежи по ОД')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)


--alter table [dwh_new].[dbo].[CARMONEY_dashboard_001v01] add [ДатаУчета] datetime null

-----------------------------------------------------------
----------- Загрузка оперативной информации по выдачам

if OBJECT_ID('tempdb.dbo.#dm_dashboard_CallCentr_actual') is not null drop table #dm_dashboard_CallCentr_actual

select distinct * into #dm_dashboard_CallCentr_actual from reports.dbo.dm_dashboard_CallCentr_actual
select * from #dm_dashboard_CallCentr_actual

insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы план руб Месяц' [Показатель] ,N'План' as [ПланФакт] 
		,([ОстДоЦели]+[СуммаФактМес]) as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы факт руб Месяц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[СуммаФактМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы факт колво Месяц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[Ф_КолвоЗаймовМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual
union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Ср.взвешенная ставка проц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[СрВзвешСтавкаМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

*/

/*
begin tran

delete from [dwh_new].[dbo].[mt_requests_transition_mfo] 
where [Период_Исх] >= @DateStartCurr; --@DateStartCurr;	--dateadd(day,datediff(day,0,Getdate()),0); -- @DateStart; --dateadd(day,datediff(day,0,Getdate()),0); --

insert into [dwh_new].[dbo].[mt_requests_transition_mfo] (
							[ЗаявкаСсылка_Исх],[Период_Исх] --,[НомерСтроки_Исх]
							,[ЗаявкаНомер_Исх],[ЗаявкаДата_Исх],[СтатусСсылка_Исх],[СтатусНаим_Исх]
							,[ИсполнительСсылка_Исх],[ИсполнительНаим_Исх],[ПричинаСсылка_Исх],[ПричинаНаим_Исх]
							,[ЗаявкаСсылка_След],[Период_След],[Период_След_2] --,[НомерСтроки_След],[ЗаявкаНомер_След],[ЗаявкаДата_След]
							,[СтатусСсылка_След],[СтатусНаим_След]
							,[ИсполнительСсылка_След],[ИсполнительНаим_След],[ПричинаСсылка_След],[ПричинаНаим_След]

							,[СостояниеЗаявки] ,[СтатусДляСостояния]
							)
select * from #tmp

commit tran
*/
END


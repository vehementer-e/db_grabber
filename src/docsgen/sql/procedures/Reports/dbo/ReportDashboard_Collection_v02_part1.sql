-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-04-10
-- Description:	 Первая часть. Расчеты от рисков
--             exec [dbo].[ReportDashboard_Collection_v01_part1]   --1
-- =============================================
CREATE PROC dbo.ReportDashboard_Collection_v02_part1
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- проверим что данных за вчера уже посчитали

declare @is_new bigint
set @is_new=cast(isnull(
		(
			SELECT (iif(cast([ДатаОбновления] as date) = cast(Getdate() as date),1,0)) as is_new  
			FROM [dbo].[stage_dashboard_Collection_v02]
		),
		'0'
	) as bigint)
--Select @is_new



--declare @GetFilterDate4000 datetime
--set @GetFilterDate4000=dateadd(year,2000,getdate());


---- Запрос--
declare @month_days int;

--- Если уже считали планы и историю за месяц, то не считаем
-- part 1
if (@is_new=0)
begin

-----------------------------------------------
-- удаляем данные из витрины. Обновляем дату
-----------------------------------------------
begin
delete from [dbo].[stage_dashboard_Collection_v02]
insert into [dbo].[stage_dashboard_Collection_v02] ([ДатаОбновления] , id) select GETDATE() as [ДатаОбновления], 1 as id
end

/*
set @month_days = day(eomonth(dateadd(dd,-1,cast(getdate() as date))));

begin
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
                     from dwh_new.[dbo].stat_v_balance2
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
		   where a.r_date >= dateadd(dd,-(@month_days+1),cast(getdate() as date))) a;

     drop table #t0;

	                select r_day_n,
					       max_r_day_n,
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
								  and next_r_day - r_day_n + overdue_days > next_overdue_days then 'Improve'
								 else 'Same' end) as seg_rr
					into #tt1
					from (
					select a.r_day_n,
					       a.max_r_day_n,
	                       a.external_id,
	                       a.overdue_days,
	                       a.principal_rest,
						   a.dpd_bucket,
						   a.seg1,
						   a.seg3,
						   (case when count(a.external_id) over (partition by a.external_id) <> 1
						          and row_number() over (partition by a.external_id order by a.r_day_n desc) <> 1
								 then lead(a.dpd_bucket) over (partition by a.external_id order by a.r_day_n)
								 else b.dpd_bucket end) as next_dpd_bucket,
						   (case when count(a.external_id) over (partition by a.external_id) <> 1
						          and row_number() over (partition by a.external_id order by a.r_day_n desc) <> 1
								 then lead(a.overdue_days) over (partition by a.external_id order by a.r_day_n)
								 else b.overdue_days end) as next_overdue_days,
						   (case when count(a.external_id) over (partition by a.external_id) <> 1
						          and row_number() over (partition by a.external_id order by a.r_day_n desc) <> 1
								 then lead(a.r_day_n) over (partition by a.external_id order by a.r_day_n)
								 else b.max_r_day_n end) as next_r_day
					from (select r_day_n,
	                             max_r_day_n,
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
						         'RunRate'  as seg3
                          from #tt a
                          where r_day_n = 1
					        and overdue_days >= 1

                          union

                          select r_day_n,
	                             max_r_day_n,
	                             external_id,
	                             overdue_days,
	                             principal_rest,
	                             (case when overdue_days <= 0   then '(1)_0'
	                                   when overdue_days <= 30  then '(2)_1_30'
		                    	       when overdue_days <= 60  then '(3)_31_60'
		                    	       when overdue_days <= 90  then '(4)_61_90'
		                    	       when overdue_days <= 360 then '(5)_91_360'
		                    	       else '(6)_361+' end) as dpd_bucket,
	                             'new-old' as seg1,
	                             ''        as seg2,
						         'RunRate' as seg3
                          from #tt a
                          where r_day_n > 1
					        and overdue_days in (1,31,61,91,361)) a
					      left join #tt b on a.external_id = b.external_id
								         and b.r_day_n     = b.max_r_day_n) a;
                      
                    select r_day_n,
	                       max_r_day_n,
						   external_id,
						   overdue_days,
						   principal_rest,
						   dpd_bucket,
						   seg1,
						   seg3,
						   seg2 as seg_rr
	                into #tt11
					from (select r_day_n,
	                             max_r_day_n,
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
						         'RunRate'    as seg3
                          from #tt a
                          where r_day_n = 1 
					        and overdue_days_p >= 1
					        and overdue_days = 0
                      --and r_year = 2019 and r_month = 8 

                          union

                          select r_day_n,
	                             max_r_day_n,
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
						         'RunRate'     as seg3
                          from #tt a
                          where r_day_n > 1
					        and overdue_days_p in (1,31,61,91,361)
					        and overdue_days = 0) a;

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
					into #t2
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
						         'LYSD'     as seg3
                          from #t01 a
                          where r_day = 1
					        and overdue_days >= 1
					        and r_year  = year(dateadd(yy,-1,dateadd(dd,-1,getdate())))
					        and r_month = month(dateadd(dd,-1,getdate()))

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
						         'LYSD'    as seg3
                          from #t01 a
                          where r_day > 1 
					        and r_day < day(dateadd(dd,-1,cast(getdate() as date)))
					        and overdue_days in (1,31,61,91,361)
					        and r_year  = year(dateadd(yy,-1,dateadd(dd,-1,getdate())))
					        and r_month = month(dateadd(dd,-1,getdate()))) a
					      left join #t01 b on a.external_id = b.external_id
					                      and a.r_year      = b.r_year
								          and a.r_month     = b.r_month
								          and b.r_day       = day(dateadd(dd,-1,cast(getdate() as date)))) a;
                      
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
	                into #t22
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
						         'LYSD'    as seg3
                          from #t01 a
                          where r_day = 1 
					        and overdue_days_p >= 1
					        and overdue_days = 0
					        and r_year  = year(dateadd(yy,-1,dateadd(dd,-1,getdate())))
					        and r_month = month(dateadd(dd,-1,getdate()))
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
						         'LYSD'    as seg3
                          from #t01 a
                          where r_day > 1 and r_day < day(dateadd(dd,-1,cast(getdate() as date)))
					        and overdue_days_p in (1,31,61,91,361)
					        and overdue_days = 0
					        and r_year  = year(dateadd(yy,-1,dateadd(dd,-1,getdate())))
					        and r_month = month(dateadd(dd,-1,getdate()))) a;

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
					into #t3
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
						         'CM'       as seg3
                          from #t01 a
                          where r_day = 1
					        and overdue_days >= 1
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(dd,-1,getdate()))

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
						         'CM'      as seg3
                          from #t01 a
                          where r_day > 1 
					        and r_day < day(dateadd(dd,-1,cast(getdate() as date)))
					        and overdue_days in (1,31,61,91,361)
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(dd,-1,getdate()))) a
					      left join #t01 b on a.external_id = b.external_id
					                      and a.r_year      = b.r_year
								          and a.r_month     = b.r_month
								          and b.r_day       = day(dateadd(dd,-1,cast(getdate() as date)))) a;
                      
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
	                into #t33
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
						         'CM'    as seg3
                          from #t01 a
                          where r_day = 1 
					        and overdue_days_p >= 1
					        and overdue_days = 0
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(dd,-1,getdate()))
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
						         'CM'    as seg3
                          from #t01 a
                          where r_day > 1 and r_day < day(dateadd(dd,-1,cast(getdate() as date)))
					        and overdue_days_p in (1,31,61,91,361)
					        and overdue_days = 0
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(dd,-1,getdate()))) a;

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
					into #t4
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
						         'LMSD'     as seg3
                          from #t01 a
                          where r_day = 1
					        and overdue_days >= 1
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))

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
						         'LMSD'    as seg3
                          from #t01 a
                          where r_day > 1 
					        and r_day < day(dateadd(dd,-1,cast(getdate() as date)))
					        and overdue_days in (1,31,61,91,361)
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))) a
					      left join #t01 b on a.external_id = b.external_id
					                      and a.r_year      = b.r_year
								          and a.r_month     = b.r_month
								          and b.r_day       = day(dateadd(dd,-1,cast(getdate() as date)))) a;
                      
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
	                into #t44
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
						         'LMSD'    as seg3
                          from #t01 a
                          where r_day = 1 
					        and overdue_days_p >= 1
					        and overdue_days = 0
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))
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
						         'LMSD'    as seg3
                          from #t01 a
                          where r_day > 1 and r_day < day(dateadd(dd,-1,cast(getdate() as date)))
					        and overdue_days_p in (1,31,61,91,361)
					        and overdue_days = 0
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))) a;

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
					into #t5
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
						         'LM'       as seg3
                          from #t01 a
                          where r_day = 1
					        and overdue_days >= 1
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))

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
						         'LM'    as seg3
                          from #t01 a
                          where r_day > 1 
					        and overdue_days in (1,31,61,91,361)
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))) a
					      left join #t01 b on a.external_id = b.external_id
					                      and a.r_year      = b.r_year
								          and a.r_month     = b.r_month
								          and b.r_day       = day(eomonth(a.r_date))) a;
                      
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
	                into #t55
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
						         'LM'    as seg3
                          from #t01 a
                          where r_day = 1 
					        and overdue_days_p >= 1
					        and overdue_days = 0
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))
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
						         'LM'      as seg3
                          from #t01 a
                          where r_day > 1
					        and overdue_days_p in (1,31,61,91,361)
					        and overdue_days = 0
					        and r_year  = year(dateadd(dd,-1,getdate()))
					        and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))) a;

select *
into #t_rr
from (select * from #tt1
      union
	  select * from #tt11) a;

select *
into #t_all
from (select * from #t1
      union
	  select * from #t11) a;

select *
into #t_lysd
from (select * from #t2
      union
	  select * from #t22) a;

select *
into #t_cm
from (select * from #t3
      union
	  select * from #t33) a;

select *
into #t_lmsd
from (select * from #t4
      union
	  select * from #t44) a;

select *
into #t_lm
from (select * from #t5
      union
	  select * from #t55) a;

drop table #tt1;
drop table #tt11;
drop table #t1;
drop table #t11;
drop table #t2;
drop table #t22;
drop table #t3;
drop table #t33;
drop table #t4;
drop table #t44;
drop table #t5;
drop table #t55;

	  select a.*,
             (case when count(a.external_id) over (partition by a.external_id) <> 1
			        and row_number() over (partition by a.external_id order by a.r_day_n desc) <> 1
			       then (case when a.seg1 in ('som-new','new-new') then a.r_day_n
				              else lead(a.r_day_n) over (partition by a.external_id order by a.r_day_n) - 1 end)
		           else (case when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(2)_1_30'
						      then 30 - a.overdue_days + a.r_day_n
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(3)_31_60'
						      then 60 - a.overdue_days + a.r_day_n
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(4)_61_90'
						      then 90 - a.overdue_days + a.r_day_n
							  when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(5)_91_360'
						      then 360 - a.overdue_days + a.r_day_n
			                  else a.max_r_day_n end) end) as r_day_n_end
	  into #rr
      from #t_rr a;

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

	  select a.*,
             (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
			        and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
			       then (case when a.seg1 in ('som-new','new-new') then a.r_date
				              else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
		           else (case when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(2)_1_30'
						      then dateadd(dd,30 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(3)_31_60'
						      then dateadd(dd,60 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(4)_61_90'
						      then dateadd(dd,90 - a.overdue_days,a.r_date)
							  when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(5)_91_360'
						      then dateadd(dd,360 - a.overdue_days,a.r_date)
			                  else (case when day(dateadd(dd,-1,cast(getdate() as date))) <= day(eomonth(a.r_date))
							             then dateadd(yy,-1,dateadd(dd,-1,cast(getdate() as date)))
										 else eomonth(a.r_date) end) end) end) as r_end_date
	  into #lysd
      from #t_lysd a;

	  select a.*,
             (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
			        and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
			       then (case when a.seg1 in ('som-new','new-new') then a.r_date
				              else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
		           else (case when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(2)_1_30'
						      then dateadd(dd,30 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(3)_31_60'
						      then dateadd(dd,60 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(4)_61_90'
						      then dateadd(dd,90 - a.overdue_days,a.r_date)
							  when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(5)_91_360'
						      then dateadd(dd,360 - a.overdue_days,a.r_date)
			                  else (case when day(dateadd(dd,-1,cast(getdate() as date))) <= day(eomonth(a.r_date))
							             then dateadd(mm,-1,dateadd(dd,-1,cast(getdate() as date)))
										 else eomonth(a.r_date) end) end) end) as r_end_date
	  into #lmsd
      from #t_lmsd a;

	  select a.*,
             (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
			        and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
			       then (case when a.seg1 in ('som-new','new-new') then a.r_date
				              else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
		           else (case when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(2)_1_30'
						      then dateadd(dd,30 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(3)_31_60'
						      then dateadd(dd,60 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(4)_61_90'
						      then dateadd(dd,90 - a.overdue_days,a.r_date)
							  when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(5)_91_360'
						      then dateadd(dd,360 - a.overdue_days,a.r_date)
			                  else (case when day(dateadd(dd,-1,cast(getdate() as date))) <= day(eomonth(a.r_date))
							             then dateadd(dd,-1,cast(getdate() as date))
										 else eomonth(a.r_date) end) end) end) as r_end_date
	  into #cm
      from #t_cm a;

	  select a.*,
             (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
			        and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
			       then (case when a.seg1 in ('som-new','new-new') then a.r_date
				              else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
		           else (case when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(2)_1_30'
						      then dateadd(dd,30 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(3)_31_60'
						      then dateadd(dd,60 - a.overdue_days,a.r_date)
				              when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(4)_61_90'
						      then dateadd(dd,90 - a.overdue_days,a.r_date)
							  when a.seg_rr = 'Worse'
						       and a.dpd_bucket = '(5)_91_360'
						      then dateadd(dd,360 - a.overdue_days,a.r_date)
			                  else eomonth(a.r_date) end) end) as r_end_date
	  into #lm
      from #t_lm a;

	  drop table #t_all;
	  drop table #t_rr;
	  drop table #t_lysd;
	  drop table #t_lmsd;
	  drop table #t_cm;
	  drop table #t_lm;

	  merge into #rr a
	  using (select b.external_id, b.r_day_n, min(a.r_day_n-1) as min_r
	         from #tt a
	         join #rr b on a.external_id = b.external_id 
	         where        b.seg1 in ('new-old','som-old')
			          and b.seg_rr = 'Improve'
			          and a.r_day_n  >= b.r_day_n
			          and a.overdue_days_p < b.overdue_days
	         group by b.external_id, b.r_day_n) b
	  on a.external_id = b.external_id and a.r_day_n = b.r_day_n
	  when matched then update set a.r_day_n_end = b.min_r;

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

	  merge into #lysd a
	  using (select b.external_id, b.r_date, dateadd(dd,-1,min(a.r_date)) as min_r
	         from #t01 a
	         join #lysd b on a.external_id = b.external_id 
	         where        b.seg1 in ('new-old','som-old')
			          and b.seg_rr = 'Improve'
			          and a.r_year  = b.r_year
			          and a.r_month = b.r_month
			          and a.r_day  >= b.r_day
					  and a.r_day  <= day(dateadd(dd,-1,cast(getdate() as date)))
			          and a.overdue_days_p < b.overdue_days
	         group by b.external_id, b.r_date) b
	  on a.external_id = b.external_id and a.r_date = b.r_date
	  when matched then update set a.r_end_date = b.min_r;

	  merge into #lmsd a
	  using (select b.external_id, b.r_date, dateadd(dd,-1,min(a.r_date)) as min_r
	         from #t01 a
	         join #lmsd b on a.external_id = b.external_id 
	         where        b.seg1 in ('new-old','som-old')
			          and b.seg_rr = 'Improve'
			          and a.r_year  = b.r_year
			          and a.r_month = b.r_month
			          and a.r_day  >= b.r_day
					  and a.r_day  <= day(dateadd(dd,-1,cast(getdate() as date)))
			          and a.overdue_days_p < b.overdue_days
	         group by b.external_id, b.r_date) b
	  on a.external_id = b.external_id and a.r_date = b.r_date
	  when matched then update set a.r_end_date = b.min_r;

	  merge into #cm a
	  using (select b.external_id, b.r_date, dateadd(dd,-1,min(a.r_date)) as min_r
	         from #t01 a
	         join #cm b on a.external_id = b.external_id 
	         where        b.seg1 in ('new-old','som-old')
			          and b.seg_rr = 'Improve'
			          and a.r_year  = b.r_year
			          and a.r_month = b.r_month
			          and a.r_day  >= b.r_day
					  and a.r_day  <= day(dateadd(dd,-1,cast(getdate() as date)))
			          and a.overdue_days_p < b.overdue_days
	         group by b.external_id, b.r_date) b
	  on a.external_id = b.external_id and a.r_date = b.r_date
	  when matched then update set a.r_end_date = b.min_r;

	  merge into #lm a
	  using (select b.external_id, b.r_date, dateadd(dd,-1,min(a.r_date)) as min_r
	         from #t01 a
	         join #lm b on a.external_id = b.external_id 
	         where        b.seg1 in ('new-old','som-old')
			          and b.seg_rr = 'Improve'
			          and a.r_year  = b.r_year
			          and a.r_month = b.r_month
			          and a.r_day  >= b.r_day
					  and a.r_day  <= day(eomonth(a.r_date))
			          and a.overdue_days_p < b.overdue_days
	         group by b.external_id, b.r_date) b
	  on a.external_id = b.external_id and a.r_date = b.r_date
	  when matched then update set a.r_end_date = b.min_r;

	  update #rr   set r_day_n_end = r_day_n where seg1 in ('som-new','new-new');
	  update #all  set r_end_date  = r_date  where seg1 in ('som-new','new-new');
	  update #lysd set r_end_date  = r_date  where seg1 in ('som-new','new-new');
	  update #lmsd set r_end_date  = r_date  where seg1 in ('som-new','new-new');
	  update #cm   set r_end_date  = r_date  where seg1 in ('som-new','new-new');
	  update #lm   set r_end_date  = r_date  where seg1 in ('som-new','new-new');

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
into #t00
from (select * from #lysd
      union
	  select * from #lmsd
      union
	  select * from #cm
      union
	  select * from #lm) a
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

select a.r_day_n,
	   a.r_day_n_end,
	   a.external_id,
	   a.overdue_days,
	   a.principal_rest,
	   a.dpd_bucket,
	   a.seg1,
	   a.seg3,
	   a.seg_rr,
	   sum(isnull(b.pay_total,0)) as pay_total
into #t0000
from #rr a
left join #tt           b on a.external_id = b.external_id and b.r_day_n >= a.r_day_n and b.r_day_n <= a.r_day_n_end
group by a.r_day_n,
	     a.r_day_n_end,
	     a.external_id,
	     a.overdue_days,
	     a.principal_rest,
	     a.dpd_bucket,
	     a.seg1,
		 a.seg3,
	     a.seg_rr;

select (case when r_month = month(dateadd(dd,-1,getdate())) then 'CM' else 'LMSD' end) as seg,
       a.dpd_bucket_p,
	   a.pay_total
into #t00000
from (
select r_year,
       r_month,
       dpd_bucket_p,
	   sum(pay_total) as pay_total
from #t01 a
where r_year = year(dateadd(mm,-1,dateadd(dd,-1,getdate()))) and r_month = month(dateadd(mm,-1,dateadd(dd,-1,getdate())))
  and r_day <= day(dateadd(dd,-1,getdate()))
group by r_year,
         r_month,
         dpd_bucket_p

union

select r_year,
       r_month,
       dpd_bucket_p,
	   sum(pay_total) as pay_total
from #t01 a
where r_year = year(dateadd(dd,-1,getdate())) and r_month = month(dateadd(dd,-1,getdate()))
  and r_day <= day(dateadd(dd,-1,getdate()))
group by r_year,
         r_month,
         dpd_bucket_p) a
where dpd_bucket_p <> '(1)_0';

/*
drop table #rr;
drop table #all;
drop table #lysd;
drop table #lmsd;
drop table #cm;
drop table #lm;
drop table #t01;
drop table #tt;

select dpd_bucket,
	   seg3 as roll_rate_seg,
	   sum(case when seg_rr = 'Improve' then principal_rest else 0 end) / sum(principal_rest) as improve_rate, 
	   sum(case when seg_rr = 'Worse'   then principal_rest else 0 end) / sum(principal_rest) as worse_rate, 
	   sum(case when seg_rr = 'Same'    then principal_rest else 0 end) / sum(principal_rest) as same_rate
into #final_roll_rates
from #t00
group by dpd_bucket,
	     seg3
order by dpd_bucket,
	     seg3;

select r_year,
       r_month,
	   r_day,
	   seg1,
	   seg3 as roll_rate_seg, 
	   dpd_bucket,
	   sum(case when seg_rr = 'Improve' then principal_rest else 0 end) as improve_balance, 
	   sum(case when seg_rr = 'Worse'   then principal_rest else 0 end) as worse_balance, 
	   sum(case when seg_rr = 'Same'    then principal_rest else 0 end) as same_balance,
	   sum(principal_rest)                                              as total_balance,
	   sum(case when seg_rr = 'Improve' then pay_total      else 0 end) as improve_payments, 
	   sum(case when seg_rr = 'Worse'   then pay_total      else 0 end) as worse_payments, 
	   sum(case when seg_rr = 'Same'    then pay_total      else 0 end) as same_payments,
	   sum(pay_total)                                                   as total_payments
into #final_statistics
from #t000
group by r_year, r_month, r_day, seg1, seg3, dpd_bucket
order by r_year, r_month, r_day, seg1, seg3, dpd_bucket;

select sum(case when dpd_bucket = '(2)_1_30'  and seg_rr = 'Improve'          then principal_rest else 0 end) / sum(case when dpd_bucket = '(2)_1_30'  then principal_rest else 0 end) as kpi_1_rr_1_30,
	   sum(case when dpd_bucket = '(3)_31_60' and seg_rr = 'Improve'          then principal_rest else 0 end) / sum(case when dpd_bucket = '(3)_31_60' then principal_rest else 0 end) as kpi_1_rr_31_60,
	   sum(case when dpd_bucket = '(4)_61_90' and seg_rr = 'Improve'          then principal_rest else 0 end) / sum(case when dpd_bucket = '(4)_61_90' then principal_rest else 0 end) as kpi_1_rr_61_90,
	   sum(case when dpd_bucket = '(5)_91_360'                                then pay_total      else 0 end) / sum(case when dpd_bucket = '(5)_91_360' and seg1 in ('som-old','som-new') then principal_rest else 0 end) as kpi_1_rr_91_360,
	   sum(case when dpd_bucket = '(6)_361+'                                  then pay_total      else 0 end) / sum(case when dpd_bucket = '(6)_361+'   and seg1 in ('som-old','som-new') then principal_rest else 0 end) as kpi_1_rr_361p,
	   sum(case when dpd_bucket = '(2)_1_30'  and seg_rr in ('Same', 'Worse') then pay_total      else 0 end) / sum(case when dpd_bucket = '(2)_1_30'   and seg_rr in ('Same', 'Worse') then principal_rest else 0 end) as kpi_2_rr_1_30,
	   sum(case when dpd_bucket = '(3)_31_60' and seg_rr in ('Same', 'Worse') then pay_total      else 0 end) / sum(case when dpd_bucket = '(3)_31_60'  and seg_rr in ('Same', 'Worse') then principal_rest else 0 end) as kpi_2_rr_31_60,
	   sum(case when dpd_bucket = '(4)_61_90' and seg_rr in ('Same', 'Worse') then pay_total      else 0 end) / sum(case when dpd_bucket = '(4)_61_90'  and seg_rr in ('Same', 'Worse') then principal_rest else 0 end) as kpi_2_rr_61_90
into #final_run_rates
from #t0000;

*/
drop table #t00;
drop table #t000;
drop table #t0000;

/*
select * from #final_statistics;
select * from #final_roll_rates;
select * from #final_run_rates;
select * from #t00000;
*/
--drop table #final_roll_rates;
--drop table #final_statistics;
--drop table #final_run_rates;
--drop table #t00000;

-------------
end
begin
--- второй запрос для расчета

--declare @month_days int;
set @month_days = day(eomonth(dateadd(dd,-1,cast(getdate() as date))));

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
               into #t_t0
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
      
	 select * into #t_t01
	 from #t_t0
	 where r_date >= '2018-01-01';
	  
	 update #t_t01 set last_principal_rest = 0       where last_dpd is null;
	 update #t_t01 set dpd_bucket_last     = '(1)_0' where last_dpd is null;
	 update #t_t01 set last_dpd            = 0       where last_dpd is null;

	 select *  into #t_tt
	 from (select a.*, b.r_day_n, @month_days as max_r_day_n -- update as per num days in month
	       from #t_t01 a
		   join (select r_date, row_number() over (order by r_date) as r_day_n
		         from (select distinct r_date from #t_t01 where r_date >= dateadd(dd,-31,cast(getdate() as date))) a) b on a.r_date = b.r_date
		   where a.r_date >= dateadd(dd,-@month_days,cast(getdate() as date))) a;

     drop table #t_t0;
	 
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
					into #t_t1
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
                          from #t_t01 a
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
                          from #t_t01 a
                          where r_day > 1
					        and overdue_days in (1,31,61,91,361)) a
					      left join #t_t01 b on a.external_id = b.external_id
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
	                into #t_t11
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
                          from #t_t01 a
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
                          from #t_t01 a
                          where r_day > 1
					        and overdue_days_p in (1,31,61,91,361)
					        and overdue_days = 0) a;

select *
into #t_t_all
from (select * from #t_t1
      union
	  select * from #t_t11) a;

drop table #t_t1;
drop table #t_t11;

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
	  into #t_all2
      from #t_t_all a;

	  drop table #t_t_all;

	  merge into #t_all2 a
	  using (select b.external_id, b.r_date, dateadd(dd,-1,min(a.r_date)) as min_r
	         from #t_t01 a
	         join #t_all2 b on a.external_id = b.external_id 
	         where        b.seg1 in ('new-old','som-old')
			          and b.seg_rr = 'Improve'
			          and a.r_year  = b.r_year
			          and a.r_month = b.r_month
			          and a.r_day  >= b.r_day
			          and a.overdue_days_p < b.overdue_days
	         group by b.external_id, b.r_date) b
	  on a.external_id = b.external_id and a.r_date = b.r_date
	  when matched then update set a.r_end_date = b.min_r;

	  update #t_all2  set r_end_date  = r_date  where seg1 in ('som-new','new-new');

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
into #t_t000
from #t_all2 a
left join #t_t01           b on a.external_id = b.external_id and b.r_date >= a.r_date and b.r_date <= a.r_end_date
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
		 
drop table #t_all2;
drop table #t_t01;
drop table #t_tt;

select a.r_year,
       a.r_month,
	   a.r_day,
	   a.dpd_bucket,
	   a.total_balance,
	   a.pay_total,
	   sum(isnull(b.principal_rest,0)) as improve_balance
into #t_final_statistics
from (select a.r_year,
             a.r_month,
	         a.r_day,
	         a.dpd_bucket,
	         sum(a.principal_rest)           as total_balance,
	         sum(a.pay_total)                as pay_total
      from #t_t000      a
	  group by a.r_year,
               a.r_month,
	           a.r_day,
	           a.dpd_bucket) a
left join #t_t000              b on a.r_year  =  year(b.r_end_date)
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

drop table #t_t000;

end


---------------------------------------------
--- расчет окончен. Вставим данные в таблицу
--- 1. Данные по таблице 2
---------------------------------------------







-----------------------------------------
----- обновим данные во второй таблице
----- Таблица 2
-----------------------------------------
--Declare @summa numeric (15,2) 

--begin

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'LMSD' and dpd_bucket_p =N'(2)_1_30'),0)
--update [dbo].[stage_dashboard_Collection_v02] SET [t2_1_1] =  @summa where id = 1 

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'CM' and dpd_bucket_p =N'(2)_1_30'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_1_2] =  @summa where id = 1 	

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'LMSD' and dpd_bucket_p =N'(3)_31_60'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_2_1] =  @summa where id = 1 	

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'CM' and dpd_bucket_p =N'(3)_31_60'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_2_2] = @summa where id = 1 

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'LMSD' and dpd_bucket_p =N'(4)_61_90'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_3_1] = @summa where id = 1 

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'CM' and dpd_bucket_p =N'(4)_61_90'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_3_2] = @summa where id = 1 

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'LMSD' and dpd_bucket_p =N'(5)_91_360'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_4_1] = @summa where id = 1 

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'CM' and dpd_bucket_p =N'(5)_91_360'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_4_2] = @summa where id = 1 

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'LMSD' and dpd_bucket_p =N'(6)_361+'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_5_1] = @summa where id = 1 

--Set @summa = isnull((select max(pay_total) from #t00000 as table_2 where seg=N'CM' and dpd_bucket_p =N'(6)_361+'),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_5_2] = @summa where id = 1 


---- сборы таблицы 2
----1-30
--Set @summa = isnull((select SUM(pay_total) from #t00000 as table_2 where seg=N'LMSD' and (dpd_bucket_p =N'(2)_1_30' OR dpd_bucket_p =N'(3)_31_60' OR dpd_bucket_p =N'(4)_61_90')),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_6_1] = @summa where id = 1 

--Set @summa = isnull((select SUM(pay_total) from #t00000 as table_2 where seg=N'CM' and (dpd_bucket_p =N'(2)_1_30' OR dpd_bucket_p =N'(3)_31_60' OR dpd_bucket_p =N'(4)_61_90')),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_6_2] = @summa where id = 1 

----91+
--Set @summa = isnull((select SUM(pay_total) from #t00000 as table_2 where seg=N'LMSD' and (dpd_bucket_p =N'(5)_91_360' OR dpd_bucket_p =N'(6)_361+' )),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_7_1] = @summa where id = 1 

--Set @summa = isnull((select SUM(pay_total) from #t00000 as table_2 where seg=N'CM' and (dpd_bucket_p =N'(5)_91_360' OR dpd_bucket_p =N'(6)_361+' )),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_7_2] = @summa where id = 1 

----1+
--Set @summa = isnull((select SUM(pay_total) from #t00000 as table_2 where seg=N'LMSD' and (dpd_bucket_p =N'(2)_1_30' OR dpd_bucket_p =N'(3)_31_60' OR dpd_bucket_p =N'(4)_61_90' OR dpd_bucket_p =N'(5)_91_360' OR dpd_bucket_p =N'(6)_361+' )),0)
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_8_1] = @summa where id = 1 

----declare @summa numeric (15,2) 
--Set @summa = isnull((select SUM(pay_total) from #t00000 as table_2 where seg=N'CM' and (dpd_bucket_p =N'(2)_1_30' OR dpd_bucket_p =N'(3)_31_60' OR dpd_bucket_p =N'(4)_61_90' OR dpd_bucket_p =N'(5)_91_360' OR dpd_bucket_p =N'(6)_361+' )),0)
----Select @summa
--update [dbo].[stage_dashboard_Collection_v02] 
--SET  [t2_8_2] = @summa where id = 1 

end



*/
end


END

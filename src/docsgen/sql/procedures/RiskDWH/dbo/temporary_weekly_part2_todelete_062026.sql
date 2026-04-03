


--exec [dbo].[prc$update_rep_coll_weekly_part2] 
--ALTER
create procedure [dbo].[temporary_weekly_part2] 
-- 0 - бакеты просрочки as-is из ЦМР, 1 - фиксируем бакет просрочки на момент начала КК только в месяц начала КК
@excludecredholid bit = 0,
-- 0 - бакеты просрочки as-is из ЦМР, 1 - исключаем полностью кредиты, которые когда-либо были на КК
@flag_kk_total bit = 0
as 

declare @src_name nvarchar(100) = 'Roll rates for weekly report (new buckets)';
declare @rdt date = dateadd(dd,-1, cast(RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)) as date));
declare @lw_from date; set @lw_from  = dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt)) ;
declare @lw_to date; set @lw_to = dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt)) ;
declare @cw_from date; set @cw_from = RiskDWH.dbo.date_trunc('wk',@rdt);


set datefirst 1; 

	declare @vinfo varchar(1000) = concat('START rep_dt = ', format(@rdt, 'dd.MM.yyyy'),
									', excludecredholid = ', cast(@excludecredholid as varchar(1)), 
									', flag_kk_total = ', cast(@flag_kk_total as varchar(1))
									);

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = @vinfo;


	drop table if exists #CMR;

	select a.d as r_date, 
	a.external_id, 
	a.r_day, a.r_month, a.r_year,
	a.dpd_coll as overdue_days, 
	a.dpd_p_coll as overdue_days_p, 
	a.dpd_last_coll as last_dpd,
	a.bucket_coll as dpd_bucket, 
	a.bucket_p_coll as dpd_bucket_p, 
	a.bucket_last_coll as dpd_bucket_last,
	cast(isnull(a.[остаток од],0) as float) as principal_rest,
	a.prev_dpd_coll as lag_overdue_days, 
	a.prev_dpd_p_coll as lag_overdue_days_p,
	a.prev_od as last_principal_rest,
	cast(isnull(principal_cnl,    0) as float) +
	cast(isnull(percents_cnl,     0) as float) +
	cast(isnull(fines_cnl,        0) as float) +
	cast(isnull(otherpayments_cnl,0) as float) +
	cast(isnull(overpayments_cnl, 0) as float) - 
	cast(isnull(overpayments_acc, 0) as float) as pay_total,
	isnull([сумма поступлений], 0) as pay_total_calc
	into #CMR
	from dwh2.dbo.dm_CMRStatBalance a
	where a.d >= '2024-11-01' and a.d <= @rdt;
	
	--Бизнес-займы
	insert into #CMR
	select  a.r_date, 
	a.external_id, 
	a.r_day, a.r_month, a.r_year,
	a.overdue_days,
	a.overdue_days_p,
	a.last_dpd,
	a.dpd_bucket,
	a.dpd_bucket_p,
	a.dpd_bucket_last,
	a.principal_rest,
	a.overdue_days,
	a.overdue_days_p,
	a.last_principal_rest,
	a.pay_total,
	a.pay_total
	from RiskDWH.dbo.det_business_loans a;

	drop index if exists tmp_cmr_idx on #CMR;
	create clustered index tmp_cmr_idx on #CMR (external_id, r_date);


	/******************************************/

	
                     
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T2';


						drop table if exists #t2;
						select r_year,
							   r_month,
							   r_day,
							   r_date,
							   external_id,
							   overdue_days,
							   -- overdue_days_p,
							   principal_rest,
							   last_principal_rest,
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
							   a.overdue_days_p,
							   a.principal_rest,
							   a.last_principal_rest,
							   a.dpd_bucket,
							   a.seg1,
							   a.seg3,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else /*b.dpd_bucket*/
									 RiskDWH.dbo.get_bucket_coll_2(b.overdue_days)
									 end) as next_dpd_bucket,
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
									 overdue_days_p,
									 principal_rest,
									 last_principal_rest,
									 /*(case when overdue_days <= 0   then '(1)_0'
										   when overdue_days <= 30  then '(2)_1_30'
		                          		   when overdue_days <= 60  then '(3)_31_60'
		                          		   when overdue_days <= 90  then '(4)_61_90'
										   when overdue_days <= 360 then '(5)_91_360'
										   else '(6)_361+' end) as dpd_bucket,*/
									 RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'LYSD'     as seg3
							  from #CMR a
							--отчетная дата - 1 год, первый день месяца
							  where r_day = 1
								-- and overdue_days >= 1
								and r_year  = year(dateadd(yy,-1, @rdt ))
								and r_month = month(dateadd(yy,-1, @rdt ))
								-- and not (overdue_days_p <> 0 and overdue_days = 0)

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.r_date,
									 a.external_id,
									 a.overdue_days,
									 a.overdue_days_p,
									 a.principal_rest,
									 a.last_principal_rest,
									 --(case when a.overdue_days <= 0   then '(1)_0'
										--   when a.overdue_days <= 30  then '(2)_1_30'
		        --            			   when a.overdue_days <= 60  then '(3)_31_60'
		        --            			   when a.overdue_days <= 90  then '(4)_61_90'
		        --            			   when a.overdue_days <= 360 then '(5)_91_360'
		        --            			   else '(6)_361+' end) as dpd_bucket,
									 RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'LYSD'    as seg3
							  from #CMR a
							--остальные дни месяца (меньше, чем день отчетной даты), кроме первого числа от (отчетная дата - 1 год) с переходами по бакетам
							  where ((r_day > 1 and overdue_days_p in (1,31,61,91,361, 121,151,181))
								or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_day <> 1)
								--Для учета переходов из  91+ в низшие бакеты--								
								or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_day <> 1)
								or (lag_overdue_days_p between 121 and 150 and lag_overdue_days <= 120 and r_day <> 1)
								or (lag_overdue_days_p between 151 and 180 and lag_overdue_days <= 150 and r_day <> 1)
								or (lag_overdue_days_p between 181 and 360 and lag_overdue_days <= 180 and r_day <> 1)
								or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_day <> 1)
								)

								and r_year  = year(dateadd(yy,-1, @rdt ))
								and r_month = month(dateadd(yy,-1, @rdt ))
								and r_day < day( @rdt )
								 ) a
					      
							  left join #CMR b on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day( @rdt )  ) a;

				exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T3';



			drop table if exists #t3
						select r_year,
							   r_month,
							   r_day,
							   r_date,
							   external_id,
							   overdue_days,
							   principal_rest,
							   last_principal_rest,
							   dpd_bucket,
							   seg1,
							   seg3,
							   (case when dpd_bucket <> next_dpd_bucket
									  and overdue_days > next_overdue_days then 'Improve'
									 when dpd_bucket <> next_dpd_bucket and overdue_days < next_overdue_days then 'Worse'
									 when dpd_bucket = next_dpd_bucket
									  and next_r_day - r_day + overdue_days > next_overdue_days then 'Improve'
									 else 'Same' end) as seg_rr,
								'Not worse' as flag
						into #t3
						from (
						select a.r_year,
							   a.r_month,
							   a.r_day,
							   a.r_date,
							   a.external_id,
							   a.overdue_days,
								 a.overdue_days_p, 
							   a.principal_rest,
							   a.last_principal_rest,
							   a.dpd_bucket,
							   a.seg1,
							   a.seg3,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else /*b.dpd_bucket*/
									 RiskDWH.dbo.get_bucket_coll_2(b.overdue_days)
									 end) as next_dpd_bucket,
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
									   overdue_days_p,
									 principal_rest,
									 last_principal_rest,
									 /*(case when overdue_days <= 0   then '(1)_0'
										   when overdue_days <= 30  then '(2)_1_30'
		                          		 when overdue_days <= 60  then '(3)_31_60'
		                          		 when overdue_days <= 90  then '(4)_61_90'
										   when overdue_days <= 360 then '(5)_91_360'
										   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'CM'       as seg3
							  from #CMR a
							--первый день месяца отчетной даты
							  where r_day = 1
								--  and overdue_days >= 1
								and r_year  = year( @rdt )
								and r_month = month( @rdt )
								-- and not (overdue_days_p <> 0 and overdue_days = 0)

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.r_date,
									 a.external_id,
									 a.overdue_days,
									   a.overdue_days_p,
									 a.principal_rest,
									 a.last_principal_rest,
									 /*(case when a.overdue_days <= 0   then '(1)_0'
										   when a.overdue_days <= 30  then '(2)_1_30'
		                    			   when a.overdue_days <= 60  then '(3)_31_60'
		                    			   when a.overdue_days <= 90  then '(4)_61_90'
		                    			   when a.overdue_days <= 360 then '(5)_91_360'
		                    			   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'CM'      as seg3
							  from  #CMR a
							--остальные дни месяца, кроме первого числа в месяце отчетной даты
							  where ((r_day > 1 and overdue_days_p in (1,31,61,91,361, 121,151,181))
								or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_day <> 1)
								--Для учета переходов из  91+ в низшие бакеты--								
								or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_day <> 1)
								or (lag_overdue_days_p between 121 and 150 and lag_overdue_days <= 120 and r_day <> 1)
								or (lag_overdue_days_p between 151 and 180 and lag_overdue_days <= 150 and r_day <> 1)
								or (lag_overdue_days_p between 181 and 360 and lag_overdue_days <= 180 and r_day <> 1)
								or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_day <> 1)
								)
								and r_year  = year( @rdt )
								and r_month = month( @rdt )
								and r_date <= @rdt
									 ) a
							  left join #CMR b on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day( @rdt ) ) a;

				exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T4';
                    

								drop table if exists #t4
						select r_year,
							   r_month,
							   r_day,
							   r_date,
							   external_id,
							   overdue_days,
							   principal_rest,
							   last_principal_rest,
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
							   a.last_principal_rest,
							   a.dpd_bucket,
							   a.seg1,
							   a.seg3,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else /*b.dpd_bucket */
									 RiskDWH.dbo.get_bucket_coll_2(b.overdue_days)
									 end) as next_dpd_bucket,
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
									 last_principal_rest,
									 /*(case when overdue_days <= 0   then '(1)_0'
										   when overdue_days <= 30  then '(2)_1_30'
		                          		   when overdue_days <= 60  then '(3)_31_60'
		                          		   when overdue_days <= 90  then '(4)_61_90'
										   when overdue_days <= 360 then '(5)_91_360'
										   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'LMSD'     as seg3
							  from #CMR a
							  where r_day = 1
								-- and overdue_days >= 1
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))
								--and r_day <= day( @rdt )
								-- and not (overdue_days_p <> 0 and overdue_days = 0)

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.r_date,
									 a.external_id,
									 a.overdue_days,
									 a.principal_rest,
									 a.last_principal_rest,
									 /*(case when a.overdue_days <= 0   then '(1)_0'
										   when a.overdue_days <= 30  then '(2)_1_30'
		                    			   when a.overdue_days <= 60  then '(3)_31_60'
		                    			   when a.overdue_days <= 90  then '(4)_61_90'
		                    			   when a.overdue_days <= 360 then '(5)_91_360'
		                    			   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'LMSD'    as seg3
							  from  #CMR a
							  where ((r_day > 1
								and overdue_days_p in (1,31,61,91,361, 121,151,181))
								or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_day <> 1)
								--Для учета переходов из  91+ в низшие бакеты--								
								or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_day <> 1)
								or (lag_overdue_days_p between 121 and 150 and lag_overdue_days <= 120 and r_day <> 1)
								or (lag_overdue_days_p between 151 and 180 and lag_overdue_days <= 150 and r_day <> 1)
								or (lag_overdue_days_p between 181 and 360 and lag_overdue_days <= 180 and r_day <> 1)
								or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_day <> 1)
								)
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))
								and r_day < day( @rdt )
								) a
							  left join #CMR b on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day( @rdt )) a;
                      
						
				exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T5';


								drop table if exists #t5
						select r_year,
							   r_month,
							   r_day,
							   r_date,
							   external_id,
							   overdue_days,
							   principal_rest,
							   last_principal_rest,
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
							   a.last_principal_rest,
							   a.dpd_bucket,
							   a.seg1,
							   a.seg3,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else /*b.dpd_bucket */
									 RiskDWH.dbo.get_bucket_coll_2(b.overdue_days)
									 end) as next_dpd_bucket,
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
									 last_principal_rest,
									 /*(case when overdue_days <= 0   then '(1)_0'
										   when overdue_days <= 30  then '(2)_1_30'
		                           		   when overdue_days <= 60  then '(3)_31_60'
		                          		   when overdue_days <= 90  then '(4)_61_90'
										   when overdue_days <= 360 then '(5)_91_360'
										   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'LM'       as seg3
							  from #CMR a
							  where r_day = 1
								-- and overdue_days >= 1
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))
								-- and not (overdue_days_p <> 0 and overdue_days = 0)

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.r_date,
									 a.external_id,
									 a.overdue_days,
									 a.principal_rest,
									 a.last_principal_rest,
									 /*(case when a.overdue_days <= 0   then '(1)_0'
										   when a.overdue_days <= 30  then '(2)_1_30'
		                    			   when a.overdue_days <= 60  then '(3)_31_60'
		                    			   when a.overdue_days <= 90  then '(4)_61_90'
		                    			   when a.overdue_days <= 360 then '(5)_91_360'
		                    			   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'LM'    as seg3
							  from  #CMR a
							  where ((r_day > 1 and overdue_days_p in (1,31,61,91,361, 121,151,181))
								or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_day <> 1)
								--Для учета переходов из  91+ в низшие бакеты--								
								or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_day <> 1)
								or (lag_overdue_days_p between 121 and 150 and lag_overdue_days <= 120 and r_day <> 1)
								or (lag_overdue_days_p between 151 and 180 and lag_overdue_days <= 150 and r_day <> 1)
								or (lag_overdue_days_p between 181 and 360 and lag_overdue_days <= 180 and r_day <> 1)
								or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_day <> 1)
								)
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))
								 ) a
							  left join #CMR b on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day(eomonth(a.r_date))) a;
                    

/****************************************************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T6';


								drop table if exists #t6
						select r_year,
							   r_month,
							   r_day,
							   r_date,
							   external_id,
							   overdue_days,
							   principal_rest,
							   last_principal_rest,
							   dpd_bucket,
							   seg1,
							   seg3,
							   (case when dpd_bucket <> next_dpd_bucket
									  and overdue_days > next_overdue_days then 'Improve'
									 when dpd_bucket <> next_dpd_bucket and overdue_days < next_overdue_days then 'Worse'
									 when dpd_bucket = next_dpd_bucket
									  and next_r_day - r_day + overdue_days > next_overdue_days then 'Improve'
									 else 'Same' end) as seg_rr
						into #t6
						from (
						select a.r_year,
							   a.r_month,
							   a.r_day,
							   a.r_date,
							   a.external_id,
							   a.overdue_days,
							   a.principal_rest,
							   a.last_principal_rest,
							   a.dpd_bucket,
							   a.seg1,
							   a.seg3,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else /*b.dpd_bucket*/
									 RiskDWH.dbo.get_bucket_coll_2(b.overdue_days)
									 end) as next_dpd_bucket,
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
									 last_principal_rest,
									 /*(case when overdue_days <= 0   then '(1)_0'
										   when overdue_days <= 30  then '(2)_1_30'
		                           		   when overdue_days <= 60  then '(3)_31_60'
		                          		   when overdue_days <= 90  then '(4)_61_90'
										   when overdue_days <= 360 then '(5)_91_360'
										   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'LW'       as seg3
							  from #CMR a
							  where r_date = @lw_from --dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt)) 
								-- and overdue_days >= 1
								--and r_date between dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt)) 
								--			   and dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))
								-- and not (overdue_days_p <> 0 and overdue_days = 0)

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.r_date,
									 a.external_id,
									 a.overdue_days,
									 a.principal_rest,
									 a.last_principal_rest,
									 /*(case when a.overdue_days <= 0   then '(1)_0'
										   when a.overdue_days <= 30  then '(2)_1_30'
		                    			   when a.overdue_days <= 60  then '(3)_31_60'
		                    			   when a.overdue_days <= 90  then '(4)_61_90'
		                    			   when a.overdue_days <= 360 then '(5)_91_360'
		                    			   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'LW'    as seg3
							  from #CMR a
							  where ((r_date > @lw_from /*dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt))*/ and overdue_days_p in (1,31,61,91,361, 121,151,181))
								or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_date <> @lw_from)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_date <> @lw_from)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_date <> @lw_from)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_date <> @lw_from)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_date <> @lw_from)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_date <> @lw_from)
								--Для учета переходов из  91+ в низшие бакеты--								
								or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_date <> @lw_from )
								or (lag_overdue_days_p between 121 and 150 and lag_overdue_days <= 120 and r_date <> @lw_from )
								or (lag_overdue_days_p between 151 and 180 and lag_overdue_days <= 150 and r_date <> @lw_from )
								or (lag_overdue_days_p between 181 and 360 and lag_overdue_days <= 180 and r_date <> @lw_from )
								or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_date <> @lw_from )
								)
								and r_date between @lw_from 
											   and @lw_to
								 ) a
							  left join #CMR b on a.external_id = b.external_id
											  and b.r_date = @lw_to ) a;
                    


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T7';


								drop table if exists #t7
						select r_year,
							   r_month,
							   r_day,
							   r_date,
							   external_id,
							   overdue_days,
							   principal_rest,
							   last_principal_rest,
							   dpd_bucket,
							   seg1,
							   seg3,
							   (case when dpd_bucket <> next_dpd_bucket
									  and overdue_days > next_overdue_days then 'Improve'
									 when dpd_bucket <> next_dpd_bucket and overdue_days < next_overdue_days then 'Worse'
									 when dpd_bucket = next_dpd_bucket
									  and next_r_day - r_day + overdue_days > next_overdue_days then 'Improve'
									 else 'Same' end) as seg_rr
						into #t7
						from (
						select a.r_year,
							   a.r_month,
							   a.r_day,
							   a.r_date,
							   a.external_id,
							   a.overdue_days,
							   a.principal_rest,
							   a.last_principal_rest,
							   a.dpd_bucket,
							   a.seg1,
							   a.seg3,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else /*b.dpd_bucket*/
									 RiskDWH.dbo.get_bucket_coll_2(b.overdue_days)
									 end) as next_dpd_bucket,
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
									 last_principal_rest,
									 /*(case when overdue_days <= 0   then '(1)_0'
										   when overdue_days <= 30  then '(2)_1_30'
		                           		   when overdue_days <= 60  then '(3)_31_60'
		                          		   when overdue_days <= 90  then '(4)_61_90'
										   when overdue_days <= 360 then '(5)_91_360'
										   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'CW'       as seg3
							  from #CMR a
							  where r_date = @cw_from --RiskDWH.dbo.date_trunc('wk',@rdt)
								-- and overdue_days >= 1
								--and r_date between RiskDWH.dbo.date_trunc('wk',@rdt) and @rdt
								-- and not (overdue_days_p <> 0 and overdue_days = 0)

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.r_date,
									 a.external_id,
									 a.overdue_days,
									 a.principal_rest,
									 a.last_principal_rest,
									 /*(case when a.overdue_days <= 0   then '(1)_0'
										   when a.overdue_days <= 30  then '(2)_1_30'
		                    			   when a.overdue_days <= 60  then '(3)_31_60'
		                    			   when a.overdue_days <= 90  then '(4)_61_90'
		                    			   when a.overdue_days <= 360 then '(5)_91_360'
		                    			   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'CW'    as seg3
							  from  #CMR a
							  where ((r_date > @cw_from and overdue_days_p in (1,31,61,91,361, 121,151,181))
								or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_date <> @cw_from)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_date <> @cw_from)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_date <> @cw_from)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_date <> @cw_from)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_date <> @cw_from)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_date <> @cw_from)
								--Для учета переходов из  91+ в низшие бакеты--								
								or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_date <> @cw_from )
								or (lag_overdue_days_p between 121 and 150 and lag_overdue_days <= 120 and r_date <> @cw_from )
								or (lag_overdue_days_p between 151 and 180 and lag_overdue_days <= 150 and r_date <> @cw_from )
								or (lag_overdue_days_p between 181 and 360 and lag_overdue_days <= 180 and r_date <> @cw_from )
								or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_date <> @cw_from )
								)
								
								and r_date between @cw_from and @rdt
								 ) a
							  left join #CMR b on a.external_id = b.external_id
											  and b.r_date = @rdt
											  ) a;


/****************************************************************************/
---Март 2020

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T8';


								drop table if exists #t8
						select r_year,
							   r_month,
							   r_day,
							   r_date,
							   external_id,
							   overdue_days,
							   principal_rest,
							   last_principal_rest,
							   dpd_bucket,
							   seg1,
							   seg3,
							   (case when dpd_bucket <> next_dpd_bucket
									  and overdue_days > next_overdue_days then 'Improve'
									 when dpd_bucket <> next_dpd_bucket and overdue_days < next_overdue_days then 'Worse'
									 when dpd_bucket = next_dpd_bucket
									  and next_r_day - r_day + overdue_days > next_overdue_days then 'Improve'
									 else 'Same' end) as seg_rr
						into #t8
						from (
						select a.r_year,
							   a.r_month,
							   a.r_day,
							   a.r_date,
							   a.external_id,
							   a.overdue_days,
							   a.principal_rest,
							   a.last_principal_rest,
							   a.dpd_bucket,
							   a.seg1,
							   a.seg3,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else /*b.dpd_bucket */
									 RiskDWH.dbo.get_bucket_coll_2(b.overdue_days)
									 end) as next_dpd_bucket,
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
									 last_principal_rest,
									 /*(case when overdue_days <= 0   then '(1)_0'
										   when overdue_days <= 30  then '(2)_1_30'
		                           		   when overdue_days <= 60  then '(3)_31_60'
		                          		   when overdue_days <= 90  then '(4)_61_90'
										   when overdue_days <= 360 then '(5)_91_360'
										   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'MAR20'       as seg3
							  from #CMR a
							  where r_day = 1
								-- and overdue_days >= 1
								and r_year  = 2020
								and r_month = 3
								-- and not (overdue_days_p <> 0 and overdue_days = 0)

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.r_date,
									 a.external_id,
									 a.overdue_days,
									 a.principal_rest,
									 a.last_principal_rest,
									 /*(case when a.overdue_days <= 0   then '(1)_0'
										   when a.overdue_days <= 30  then '(2)_1_30'
		                    			   when a.overdue_days <= 60  then '(3)_31_60'
		                    			   when a.overdue_days <= 90  then '(4)_61_90'
		                    			   when a.overdue_days <= 360 then '(5)_91_360'
		                    			   else '(6)_361+' end) as dpd_bucket,*/
									RiskDWH.dbo.get_bucket_coll_2(a.overdue_days) as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'MAR20'    as seg3
							  from  #CMR a
							  where ((r_day > 1 and overdue_days_p in (1,31,61,91,361, 121,151,181))
								or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_day <> 1)
								or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_day <> 1)
								--Для учета переходов из  91+ в низшие бакеты--								
								or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_day <> 1)
								or (lag_overdue_days_p between 121 and 150 and lag_overdue_days <= 120 and r_day <> 1)
								or (lag_overdue_days_p between 151 and 180 and lag_overdue_days <= 150 and r_day <> 1)
								or (lag_overdue_days_p between 181 and 360 and lag_overdue_days <= 180 and r_day <> 1)
								or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_day <> 1)
								)
								and r_year  = 2020
								and r_month = 3
								 ) a
							  left join #CMR b on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day(eomonth(a.r_date))) a;


/******************************************************************************/


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'rearrange tables';


		drop table if exists #t_lysd
	select *
	into #t_lysd
	from #t2


		  drop table if exists #t_cm
	select *
	into #t_cm
	from  #t3

		  drop table if exists #t_lmsd
	select *
	into #t_lmsd
	from #t4

		  drop table if exists #t_lm
	select *
	into #t_lm
	from #t5
	
		  drop table if exists #t_lw
	select *
	into #t_lw
	from #t6
		  
		  drop table if exists #t_cw
	select *
	into #t_cw
	from #t7
	
		  drop table if exists #t_mar20
	select *
	into #t_mar20
	from #t8;

	
	drop table if exists #total_kk;
	create table #total_kk (external_id varchar(100), dt_from date, dt_to date);


	if @excludecredholid = 1 
	begin 
		--исключаем кредитные каникулы
		exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'CredVacations';

		
		insert into #total_kk
		select external_id, dt_from, dt_to
		from RiskDWH.dbo.det_kk_cmr_and_space
		;
		
	end;



	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd_pre';


		  drop table if exists #lysd_pre;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lysd_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lysd) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where		((t.overdue_days_p > a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  ))
													or
		  (t.overdue_days < a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  or (t.overdue_days = 0 and t.overdue_days_p=0)
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  )))
						and t.r_date < (case when l_r_date is not null then l_r_date else dateadd(yy,-1, @rdt ) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd';


		  drop table if exists #lysd;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
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
								  and a.dpd_bucket = '(5)_91_120'
								  then dateadd(dd,120 - a.overdue_days, a.r_date)

								  when a.seg_rr = 'Worse'
								  and a.dpd_bucket = '(6)_121_150'
								  then dateadd(dd,150 - a.overdue_days, a.r_date)

								  when a.seg_rr = 'Worse'
								  and a.dpd_bucket = '(7)_151_180'
								  then dateadd(dd,180 - a.overdue_days, a.r_date)

								  when a.seg_rr = 'Worse'
								  and a.dpd_bucket = '(8)_181_360'
								  then dateadd(dd,360 - a.overdue_days, a.r_date)

								  else (case when p.r_date is not null 
											then alt_r_end_date
								  else (case when day( @rdt ) <= day(eomonth(a.r_date))
											 then dateadd(yy,-1, @rdt )
											 else eomonth(a.r_date) end) end) end) end) as r_end_date
		  into #lysd
		  from #t_lysd a
				left join #lysd_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd_pre_w';

		  drop table if exists #lysd_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lysd_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lysd) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where	  -- t.overdue_days_p in (1,31,61,91,361, 121,151,181)
		   (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 151 and a.overdue_days between 121 and 150
		  or t.overdue_days_p = 181 and a.overdue_days between 151 and 180
		  or t.overdue_days_p = 361 and a.overdue_days between 181 and 360
		  )
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 151	and t.last_dpd between 121 and 150
		  or t.overdue_days = 181	and t.last_dpd between 151 and 180
		  or t.overdue_days = 361	and t.last_dpd between 181 and 360		  
		  ))
		  )
		  and t.r_date <= (case when l_r_date is not null then l_r_date else dateadd(yy,-1, @rdt ) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd_w';

		  drop table if exists #lysd_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else (case when day( @rdt ) <= day(eomonth(a.r_date))
											 then dateadd(yy,-1, @rdt )
											 else eomonth(a.r_date) end) end) end) as r_end_date
		  into #lysd_w
		  from #t_lysd a
				left join #lysd_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd_pre';

		  drop table if exists #lmsd_pre;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lmsd_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lmsd) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where		((t.overdue_days_p > a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  ))
													or
		  (t.overdue_days < a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  or (t.overdue_days = 0 and t.overdue_days_p=0)
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  )))
						and t.r_date < (case when l_r_date is not null then l_r_date else dateadd(mm,-1, @rdt ) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd';


		   drop table if exists #lmsd;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								  -- when lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date) = dateadd(dd,1,a.r_date) and overdue_days = 0 then dateadd(dd,1,a.r_date)
								   when  p.r_date is not null 
											then alt_r_end_date
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
								   and a.dpd_bucket = '(5)_91_120'
								  then dateadd(dd,120 - a.overdue_days,a.r_date)

								  when a.seg_rr = 'Worse'
								   and a.dpd_bucket = '(6)_121_150'
								  then dateadd(dd,150 - a.overdue_days,a.r_date)

								  when a.seg_rr = 'Worse'
								   and a.dpd_bucket = '(7)_151_180'
								  then dateadd(dd,180 - a.overdue_days,a.r_date)

								  when a.seg_rr = 'Worse'
								   and a.dpd_bucket = '(8)_181_360'
								  then dateadd(dd,360 - a.overdue_days,a.r_date)

								  else (case when p.r_date is not null 
											then alt_r_end_date
								  else (case when day( @rdt ) <= day(eomonth(a.r_date))
											 then dateadd(mm,-1, @rdt )
											 else eomonth(a.r_date) end) end) end) end) as r_end_date
		  into #lmsd
		  from #t_lmsd a
				left join #lmsd_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd_pre_w';


		 drop table if exists #lmsd_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lmsd_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lmsd) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where	   --t.overdue_days_p in (1,31,61,91,361, 121,151,181)
		   (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 151 and a.overdue_days between 121 and 150
		  or t.overdue_days_p = 181 and a.overdue_days between 151 and 180
		  or t.overdue_days_p = 361 and a.overdue_days between 181 and 360
		  )
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 151	and t.last_dpd between 121 and 150
		  or t.overdue_days = 181	and t.last_dpd between 151 and 180
		  or t.overdue_days = 361	and t.last_dpd between 181 and 360		  
		  ))
		  )
		  and t.r_date <= (case when l_r_date is not null then l_r_date else dateadd(mm,-1, @rdt ) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd_w';


		  drop table if exists #lmsd_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else (case when day( @rdt ) <= day(eomonth(a.r_date))
											 then dateadd(mm,-1, @rdt )
											 else eomonth(a.r_date) end) end) end) as r_end_date
		  into #lmsd_w
		  from #t_lmsd a
				left join #lmsd_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;


		  /*  select * from #lmsd 
		  where overdue_days = 0 
		  order by external_id, r_date  */

		  -- select * from #t_cm

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cm_pre';


		  drop table if exists #cm_pre;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #cm_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_cm) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) 
			and t.r_date <= @rdt
			and a.external_id=t.external_id
		  -- where t.overdue_days < a.overdue_days and not ((t.overdue_days_p-t.overdue_days)%29 > 0 and (t.overdue_days_p-t.overdue_days)%30 > 0 and (t.overdue_days_p-t.overdue_days)%31 > 0  and t.overdue_days<>0 and 
		  where		((t.overdue_days_p > a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  ))
													or
		  (t.overdue_days < a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  or (t.overdue_days = 0 and t.overdue_days_p=0)
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  )))
						and t.r_date < (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cm';

		  drop table if exists #cm;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case  when p.r_date is not null 
											then alt_r_end_date
								  else (case when day( @rdt ) <= day(eomonth(a.r_date))
											 then @rdt
											 else eomonth(a.r_date) end) end) end) as r_end_date
		  into #cm
		  from #t_cm a
				left join #cm_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

				--  select * from #t_cm
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cm_pre_w';
			
		  drop table if exists #cm_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #cm_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_cm) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) 
			and t.r_date <= @rdt
			and a.external_id=t.external_id
		  where	   --t.overdue_days_p in (1,31,61,91,361, 121,151,181)
		   (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 151 and a.overdue_days between 121 and 150
		  or t.overdue_days_p = 181 and a.overdue_days between 151 and 180
		  or t.overdue_days_p = 361 and a.overdue_days between 181 and 360
		  )
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 151	and t.last_dpd between 121 and 150
		  or t.overdue_days = 181	and t.last_dpd between 151 and 180
		  or t.overdue_days = 361	and t.last_dpd between 181 and 360		  
		  ))
		  )	
		  and t.r_date <= (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cm_w';

		  drop table if exists #cm_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else (case when day( @rdt ) <= day(eomonth(a.r_date))
											 then @rdt
											 else eomonth(a.r_date) end) end) end) as r_end_date
		  into #cm_w
		  from #t_cm a
				left join #cm_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm_pre';

		  drop table if exists #lm_pre;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lm_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lm) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where		((t.overdue_days_p > a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  ))
													or
		  (t.overdue_days < a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  or (t.overdue_days = 0 and t.overdue_days_p=0)
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  )))
						and t.r_date < (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
		  group by a.external_id, a.r_date


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm';

		  drop table if exists #lm;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else eomonth(a.r_date) end) end) as r_end_date
		  into #lm
		  from #t_lm a
				left join #lm_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm_pre_w';

		 drop table if exists #lm_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lm_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lm) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where	   --t.overdue_days_p in (1,31,61,91,361, 121,151,181)
		   (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 151 and a.overdue_days between 121 and 150
		  or t.overdue_days_p = 181 and a.overdue_days between 151 and 180
		  or t.overdue_days_p = 361 and a.overdue_days between 181 and 360
		  )
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 151	and t.last_dpd between 121 and 150
		  or t.overdue_days = 181	and t.last_dpd between 151 and 180
		  or t.overdue_days = 361	and t.last_dpd between 181 and 360		  
		  ))
		  )
		  and t.r_date <= (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm_w';

		  drop table if exists #lm_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else eomonth(a.r_date) end) end) as r_end_date
		  into #lm_w
		  from #t_lm a
				left join #lm_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;

/******************************************************************/

exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lw_pre';


		  drop table if exists #lw_pre;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lw_pre
		  from (select *,  LEAD(r_date) over (partition by external_id /*, r_month, r_year*/ order by /*r_day*/ r_date) l_r_date from #t_lw) a
			left join #CMR t 
			on a.r_date<=t.r_date 
			and t.r_date<= @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/
			and a.external_id=t.external_id
		  -- where t.overdue_days < a.overdue_days and not ((t.overdue_days_p-t.overdue_days)%29 > 0 and (t.overdue_days_p-t.overdue_days)%30 > 0 and (t.overdue_days_p-t.overdue_days)%31 > 0  and t.overdue_days<>0 and 
		  where		((t.overdue_days_p > a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  ))
													or
		  (t.overdue_days < a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  or (t.overdue_days = 0 and t.overdue_days_p=0)
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  )))
						and t.r_date < (case when l_r_date is not null then l_r_date else @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/ end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lw';

		  drop table if exists #lw;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id /*, a.r_year, a.r_month*/) <> 1
						and row_number() over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date)) end)
					   else (case  when p.r_date is not null 
											then alt_r_end_date
								  else @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/ end) end) as r_end_date
		  into #lw
		  from #t_lw a
				left join #lw_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

				--  select * from #t_cm
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lw_pre_w';
			
		  drop table if exists #lw_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #lw_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id /*, r_month, r_year*/ order by /*r_day*/ r_date) l_r_date from #t_lw) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<= @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/ and a.external_id=t.external_id
		  where	  -- t.overdue_days_p in (1,31,61,91,361, 121,151,181)
		   (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 151 and a.overdue_days between 121 and 150
		  or t.overdue_days_p = 181 and a.overdue_days between 151 and 180
		  or t.overdue_days_p = 361 and a.overdue_days between 181 and 360
		  )
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 151	and t.last_dpd between 121 and 150
		  or t.overdue_days = 181	and t.last_dpd between 151 and 180
		  or t.overdue_days = 361	and t.last_dpd between 181 and 360		  
		  ))
		  )
		  and t.r_date <= (case when l_r_date is not null then l_r_date else @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/ end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lw_w';

		  drop table if exists #lw_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id /*, a.r_year, a.r_month*/) <> 1
						and row_number() over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/ end) end) as r_end_date
		  into #lw_w
		  from #t_lw a
				left join #lw_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;


/******************************************************************/

exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cw_pre';


		  drop table if exists #cw_pre;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #cw_pre
		  from (select *,  LEAD(r_date) over (partition by external_id /*, r_month, r_year*/ order by /*r_day*/ r_date) l_r_date from #t_cw) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=@rdt and a.external_id=t.external_id
		  -- where t.overdue_days < a.overdue_days and not ((t.overdue_days_p-t.overdue_days)%29 > 0 and (t.overdue_days_p-t.overdue_days)%30 > 0 and (t.overdue_days_p-t.overdue_days)%31 > 0  and t.overdue_days<>0 and 
		  where		((t.overdue_days_p > a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  ))
													or
		  (t.overdue_days < a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  or (t.overdue_days = 0 and t.overdue_days_p=0)
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  )))
						and t.r_date < (case when l_r_date is not null then l_r_date else @rdt end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cw';

		  drop table if exists #cw;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id /*, a.r_year, a.r_month*/) <> 1
						and row_number() over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date)) end)
					   else (case  when p.r_date is not null 
											then alt_r_end_date
								  else @rdt end) end) as r_end_date
		  into #cw
		  from #t_cw a
				left join #cw_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

				--  select * from #t_cm
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cw_pre_w';
			
		  drop table if exists #cw_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #cw_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id /*, r_month, r_year*/ order by /*r_day*/ r_date) l_r_date from #t_cw) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=@rdt and a.external_id=t.external_id
		  where	   --t.overdue_days_p in (1,31,61,91,361, 121,151,181)
		   (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 151 and a.overdue_days between 121 and 150
		  or t.overdue_days_p = 181 and a.overdue_days between 151 and 180
		  or t.overdue_days_p = 361 and a.overdue_days between 181 and 360
		  )
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 151	and t.last_dpd between 121 and 150
		  or t.overdue_days = 181	and t.last_dpd between 151 and 180
		  or t.overdue_days = 361	and t.last_dpd between 181 and 360		  
		  ))
		  )
		  and t.r_date <= (case when l_r_date is not null then l_r_date else @rdt end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cw_w';

		  drop table if exists #cw_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id /*, a.r_year, a.r_month*/) <> 1
						and row_number() over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id /*, a.r_year, a.r_month*/ order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else @rdt end) end) as r_end_date
		  into #cw_w
		  from #t_cw a
				left join #cw_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;

/******************************************************************/
--март 2020

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mar20_pre';

		  drop table if exists #mar20_pre;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #mar20_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_mar20) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where		((t.overdue_days_p > a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  ))
													or
					(t.overdue_days < a.overdue_days and 
		  ((t.overdue_days = 0 and (t.overdue_days_p  between 1 and 30)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p  between 31 and 60))  
		  or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
		  or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
		  or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
	      or (t.overdue_days = 0 and t.overdue_days_p=0)
		  --Для учета переходов из  91+ в низшие бакеты
		  or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
		  or (t.overdue_days_p between 121 and 150 and t.overdue_days <= 120)
		  or (t.overdue_days_p between 151 and 180 and t.overdue_days <= 150)
		  or (t.overdue_days_p between 181 and 360 and t.overdue_days <= 180)
		  or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
		  )))
						and t.r_date < (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mar20';

		  drop table if exists #mar20;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else eomonth(a.r_date) end) end) as r_end_date
		  into #mar20
		  from #t_mar20 a
				left join #mar20_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mar20_pre_w';

		 drop table if exists #mar20_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #mar20_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_mar20) a
			left join #CMR t on a.r_date<=t.r_date and t.r_date<=eomonth(a.r_date) and a.external_id=t.external_id
		  where	  -- t.overdue_days_p in (1,31,61,91,361, 121,151,181)
			 (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 151 and a.overdue_days between 121 and 150
		  or t.overdue_days_p = 181 and a.overdue_days between 151 and 180
		  or t.overdue_days_p = 361 and a.overdue_days between 181 and 360
		  )
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 151	and t.last_dpd between 121 and 150
		  or t.overdue_days = 181	and t.last_dpd between 151 and 180
		  or t.overdue_days = 361	and t.last_dpd between 181 and 360		  
		  ))
		  )			
		  and t.r_date <= (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
		  group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mar20_w';

		  drop table if exists #mar20_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else eomonth(a.r_date) end) end) as r_end_date
		  into #mar20_w
		  from #t_mar20 a
				left join #mar20_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;


/*****************************************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd_new';
			 ----------------------------- part "new" --------------------------------------

			drop table if exists #lysd_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--Для учета переходов из  91+ в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 150 and b.overdue_days <= 120)
							or (b.overdue_days_p between 151 and 180 and b.overdue_days <= 150)
							or (b.overdue_days_p between 181 and 360 and b.overdue_days <= 180)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then /*b.dpd_bucket_p*/
					RiskDWH.dbo.get_bucket_coll_2(b.overdue_days_p)
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  
				  isnull(b.overdue_days,0) as overdue_days_end,			
				
				isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days) ,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lysd_new
		  from #lysd      a
		  left join #CMR b on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd_new_w';
			drop table if exists #lysd_new_w;			 
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 a.principal_rest,
				 --a.overdue_days,
			     --a.dpd_bucket,
			     case when a.r_date = a.r_end_date
			     then c.last_dpd 
			     else 
			     a.overdue_days end overdue_days,
			     
			     case when a.r_date = a.r_end_date
			     then RiskDWH.dbo.get_bucket_coll_2(c.last_dpd) --c.dpd_bucket_last 
			     else 
			     a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days) ,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lysd_new_w
		  from #lysd_w     a
		  left join #CMR b 
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.r_date
		  left join #CMR c
			on a.external_id = c.external_id
			and a.r_date = c.r_date
			;
				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd_new_full';
		
		drop table if exists #lysd_new_full;	
			select *
			into #lysd_new_full
			from		 
		   ( select *
		  from #lysd_new 
		  where dpd_bucket <> dpd_bucket_end
				or r_end_date = dateadd(yy,-1, @rdt )
		  UNION 
		  ( select *
		  from #lysd_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_150')
								or (dpd_bucket = '(6)_121_150' and dpd_bucket_end = '(7)_151_180')
								or (dpd_bucket = '(7)_151_180' and dpd_bucket_end = '(8)_181_360')
								or (dpd_bucket = '(8)_181_360' and dpd_bucket_end = '(9)_361+') 
								) ) u


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd_new';			
				drop table if exists #lmsd_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--Для учета переходов из  91+ в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 150 and b.overdue_days <= 120)
							or (b.overdue_days_p between 151 and 180 and b.overdue_days <= 150)
							or (b.overdue_days_p between 181 and 360 and b.overdue_days <= 180)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then /*b.dpd_bucket_p*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days_p)
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.overdue_days,0) as overdue_days_end,			
				isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lmsd_new
		  from #lmsd      a
		  left join #CMR b on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd_new_w';			

			drop table if exists #lmsd_new_w;			 
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 a.principal_rest,
				  --a.overdue_days,
			     --a.dpd_bucket,
			     case when a.r_date = a.r_end_date
			     then c.last_dpd 
			     else 
			     a.overdue_days end overdue_days,
			     
			     case when a.r_date = a.r_end_date
			     then RiskDWH.dbo.get_bucket_coll_2(c.last_dpd) --c.dpd_bucket_last 
			     else 
			     a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lmsd_new_w
		  from #lmsd_w     a
		  left join #CMR b 
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.r_date
		  left join #CMR c
			on a.external_id = c.external_id
			and a.r_date = c.r_date
			;
				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd_new_full';			


			drop table if exists #lmsd_new_full;	
			select *
			into #lmsd_new_full
			from		 
		   ( select *
		  from #lmsd_new 
		  where dpd_bucket <> dpd_bucket_end
				or r_end_date = dateadd(mm,-1, @rdt )
		  UNION 
		  ( select *
		  from #lmsd_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_150')
								or (dpd_bucket = '(6)_121_150' and dpd_bucket_end = '(7)_151_180')
								or (dpd_bucket = '(7)_151_180' and dpd_bucket_end = '(8)_181_360')
								or (dpd_bucket = '(8)_181_360' and dpd_bucket_end = '(9)_361+') 
								) ) u

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cm_new';			

		
			 drop table if exists #cm_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 -- case when dpd_bucket = '(2)_1_30' and dpd_bucket_end
				 case  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--Для учета переходов из  91+ в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 150 and b.overdue_days <= 120)
							or (b.overdue_days_p between 151 and 180 and b.overdue_days <= 150)
							or (b.overdue_days_p between 181 and 360 and b.overdue_days <= 180)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then /*b.dpd_bucket_p*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days_p)
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.overdue_days,0) as overdue_days_end,
				
			
				isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #cm_new
		  from #cm      a
		  left join #CMR b on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cm_new_w';			


			drop table if exists #cm_new_w;			 
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 a.principal_rest,
				  --a.overdue_days,
			     --a.dpd_bucket,
			     case when a.r_date = a.r_end_date
			     then c.last_dpd 
			     else 
			     a.overdue_days end overdue_days,
			     
			     case when a.r_date = a.r_end_date
			     then RiskDWH.dbo.get_bucket_coll_2(c.last_dpd) --c.dpd_bucket_last 
			     else 
			     a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #cm_new_w
		  from #cm_w     a
		  left join #CMR b 
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.r_date
		  left join #CMR c
			on a.external_id = c.external_id
			and a.r_date = c.r_date;
				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cm_new_full';			


			drop table if exists #cm_new_full;	
			select *
			into #cm_new_full
			from		 
		  --  ( select *, 'Not worse' migr_seg 
		   ( select *
		  from #cm_new 
		  where dpd_bucket <> dpd_bucket_end or r_end_date = @rdt
		  UNION 
		  --  ( select *, 'Worse' as migr_seg
		  ( select *
		  from #cm_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_150')
								or (dpd_bucket = '(6)_121_150' and dpd_bucket_end = '(7)_151_180')
								or (dpd_bucket = '(7)_151_180' and dpd_bucket_end = '(8)_181_360')
								or (dpd_bucket = '(8)_181_360' and dpd_bucket_end = '(9)_361+') 
								) ) u

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm_new';			


				drop table if exists #lm_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--Для учета переходов из  91+ в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 150 and b.overdue_days <= 120)
							or (b.overdue_days_p between 151 and 180 and b.overdue_days <= 150)
							or (b.overdue_days_p between 181 and 360 and b.overdue_days <= 180)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then /*b.dpd_bucket_p*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days_p)
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.overdue_days,0) as overdue_days_end,			
				isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lm_new
		  from #lm      a
		  left join #CMR b on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm_new_w';			


			drop table if exists #lm_new_w;			 
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 a.principal_rest,
				  --a.overdue_days,
			     --a.dpd_bucket,
			     case when a.r_date = a.r_end_date
			     then c.last_dpd 
			     else 
			     a.overdue_days end overdue_days,
			     
			     case when a.r_date = a.r_end_date
			     then RiskDWH.dbo.get_bucket_coll_2(c.last_dpd) --c.dpd_bucket_last 
			     else 
			     a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lm_new_w
		  from #lm_w     a
		  left join #CMR b 
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.r_date
		  left join #CMR c
			on a.external_id = c.external_id
			and a.r_date = c.r_date
			;
				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm_new_full';			


			drop table if exists #lm_new_full;	
			select *
			into #lm_new_full
			from		 
		   ( select *
		  from #lm_new 
		  where dpd_bucket <> dpd_bucket_end
				or r_end_date = eomonth(dateadd(mm,-1, @rdt ))
		  UNION 
		  ( select *
		  from #lm_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_150')
								or (dpd_bucket = '(6)_121_150' and dpd_bucket_end = '(7)_151_180')
								or (dpd_bucket = '(7)_151_180' and dpd_bucket_end = '(8)_181_360')
								or (dpd_bucket = '(8)_181_360' and dpd_bucket_end = '(9)_361+') 
								) ) u


/**************************************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lw_new';			

		
			 drop table if exists #lw_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 -- case when dpd_bucket = '(2)_1_30' and dpd_bucket_end
				 case  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--Для учета переходов из  91+ в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 150 and b.overdue_days <= 120)
							or (b.overdue_days_p between 151 and 180 and b.overdue_days <= 150)
							or (b.overdue_days_p between 181 and 360 and b.overdue_days <= 180)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							else a.principal_rest
						end principal_rest, 
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then /*b.dpd_bucket_p*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days_p)
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.overdue_days,0) as overdue_days_end,
				
			
				isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lw_new
		  from #lw      a
		  left join #CMR b on a.external_id  = b.external_id
						 --and a.r_year        = b.r_year
						 --and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lw_new_w';			


			drop table if exists #lw_new_w;			 
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 a.principal_rest,
				  --a.overdue_days,
			     --a.dpd_bucket,
			     case when a.r_date = a.r_end_date
			     then c.last_dpd 
			     else 
			     a.overdue_days end overdue_days,
			     
			     case when a.r_date = a.r_end_date
			     then RiskDWH.dbo.get_bucket_coll_2(c.last_dpd) --c.dpd_bucket_last 
			     else 
			     a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lw_new_w
		  from #lw_w     a
		  left join #CMR b 
		  on a.external_id  = b.external_id
			--and a.r_year        = b.r_year
			--and a.r_month       = b.r_month
			and a.r_end_date    = b.r_date
		  left join #CMR c
			on a.external_id = c.external_id
			and a.r_date = c.r_date
			;
				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lw_new_full';			


			drop table if exists #lw_new_full;	
			select *
			into #lw_new_full
			from		 
		  --  ( select *, 'Not worse' migr_seg 
		   ( select *
		  from #lw_new 
		  where dpd_bucket <> dpd_bucket_end or r_end_date = @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/
		  UNION 
		  --  ( select *, 'Worse' as migr_seg
		  ( select *
		  from #lw_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_150')
								or (dpd_bucket = '(6)_121_150' and dpd_bucket_end = '(7)_151_180')
								or (dpd_bucket = '(7)_151_180' and dpd_bucket_end = '(8)_181_360')
								or (dpd_bucket = '(8)_181_360' and dpd_bucket_end = '(9)_361+') 
								) ) u

/*************************************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cw_new';			

		
			 drop table if exists #cw_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 -- case when dpd_bucket = '(2)_1_30' and dpd_bucket_end
				 case  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--Для учета переходов из  91+ в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 150 and b.overdue_days <= 120)
							or (b.overdue_days_p between 151 and 180 and b.overdue_days <= 150)
							or (b.overdue_days_p between 181 and 360 and b.overdue_days <= 180)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then /*b.dpd_bucket_p*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days_p)
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.overdue_days,0) as overdue_days_end,
				
			
				isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #cw_new
		  from #cw      a
		  left join #CMR b on a.external_id  = b.external_id
						 --and a.r_year        = b.r_year
						 --and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cw_new_w';			


			drop table if exists #cw_new_w;			 
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 a.principal_rest,
				  --a.overdue_days,
			     --a.dpd_bucket,
			     case when a.r_date = a.r_end_date
			     then c.last_dpd 
			     else 
			     a.overdue_days end overdue_days,
			     
			     case when a.r_date = a.r_end_date
			     then RiskDWH.dbo.get_bucket_coll_2(c.last_dpd) --c.dpd_bucket_last 
			     else 
			     a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #cw_new_w
		  from #cw_w     a
		  left join #CMR b 
		  on a.external_id  = b.external_id
			--and a.r_year        = b.r_year
			--and a.r_month       = b.r_month
			and a.r_end_date    = b.r_date
		  left join #CMR c
			on a.external_id = c.external_id
			and a.r_date = c.r_date
			;
				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cw_new_full';			


			drop table if exists #cw_new_full;	
			select *
			into #cw_new_full
			from		 
		  --  ( select *, 'Not worse' migr_seg 
		   ( select *
		  from #cw_new 
		  where dpd_bucket <> dpd_bucket_end or r_end_date = @rdt
		  UNION 
		  --  ( select *, 'Worse' as migr_seg
		  ( select *
		  from #cw_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')

								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_150')
								or (dpd_bucket = '(6)_121_150' and dpd_bucket_end = '(7)_151_180')
								or (dpd_bucket = '(7)_151_180' and dpd_bucket_end = '(8)_181_360')
								or (dpd_bucket = '(8)_181_360' and dpd_bucket_end = '(9)_361+') 
								
								) ) u

/**************************************************************/
--март 2020

exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mar20_new';			


				drop table if exists #mar20_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--Для учета переходов из  91+ в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 150 and b.overdue_days <= 120)
							or (b.overdue_days_p between 151 and 180 and b.overdue_days <= 150)
							or (b.overdue_days_p between 181 and 360 and b.overdue_days <= 180)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then /*b.dpd_bucket_p*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days_p)
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.overdue_days,0) as overdue_days_end,			
				isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #mar20_new
		  from #mar20      a
		  left join #CMR b on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mar20_new_w';			


			drop table if exists #mar20_new_w;			 
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 a.principal_rest,
				  --a.overdue_days,
			     --a.dpd_bucket,
			     case when a.r_date = a.r_end_date
			     then c.last_dpd 
			     else 
			     a.overdue_days end overdue_days,
			     
			     case when a.r_date = a.r_end_date
			     then RiskDWH.dbo.get_bucket_coll_2(c.last_dpd) --c.dpd_bucket_last 
			     else 
			     a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(/*b.dpd_bucket*/ RiskDWH.dbo.get_bucket_coll_2(b.overdue_days),'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #mar20_new_w
		  from #mar20_w     a
		  left join #CMR b 
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.r_date
		  left join #CMR c
			on a.external_id = c.external_id
			and a.r_date = c.r_date
			;
				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mar20_new_full';			


			drop table if exists #mar20_new_full;	
			select *
			into #mar20_new_full
			from		 
		   ( select *
		  from #mar20_new 
		  where dpd_bucket <> dpd_bucket_end
				or r_end_date = cast('2020-03-31' as date)
		  UNION 
		  ( select *
		  from #mar20_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_150')
								or (dpd_bucket = '(6)_121_150' and dpd_bucket_end = '(7)_151_180')
								or (dpd_bucket = '(7)_151_180' and dpd_bucket_end = '(8)_181_360')
								or (dpd_bucket = '(8)_181_360' and dpd_bucket_end = '(9)_361+') 
								) ) u



/***************************************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_product';



	drop table if exists #stg_product;
		select a.Код as external_id, 
			case when cmr_ПодтипыПродуктов.Наименование = 'Pdl' THEN 'INSTALLMENT'
				 when a.IsInstallment = 1 then 'INSTALLMENT'
			else 'PTS' end as product
		into #stg_product
		from stg._1cCMR.Справочник_Договоры a
		LEFT JOIN Stg._1cCMR.Справочник_Заявка cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
		LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка;




	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#t00';

		drop table if exists #t00
	select a.r_year,
		   a.r_month,
		   a.r_day,
		   a.r_date,
		   a.r_end_date,
		   a.external_id,
		   a.principal_rest,
		   a.overdue_days,
		   a.dpd_bucket,
		   a.overdue_days_end,
		   a.dpd_bucket_end,
		   a.seg3,
		   a.seg_rr,
		   sum(isnull(b.pay_total,0)) as pay_total,
		   coalesce(pr.product, 'PTS') as product --15.02.2022


	into #t00
	from (select * from #lysd_new_full
		  union
		  select * from #lmsd_new_full
		  union
		  select * from #cm_new_full
		  union
		  select * from #lm_new_full
		  union
		  select * from #lw_new_full
		  union
		  select * from #cw_new_full	
		  union 
		  select * from #mar20_new_full
		  ) a
	left join #CMR  b -- [RiskDWH].[dbo].[stg_coll_bal_mfo]
	on a.external_id = b.external_id 
	and b.r_date >= a.r_date 
	and b.r_date <= a.r_end_date

	left join #stg_product pr --15.02.2022
	on a.external_id = pr.external_id

	group by a.r_year,
			 a.r_month,
			 a.r_day,
			 a.r_date,
			 a.r_end_date,
			 a.external_id,
			 a.principal_rest,
			 a.overdue_days,
			 a.dpd_bucket,
			 a.overdue_days_end,
			 a.dpd_bucket_end,
			 a.seg3,
			 a.seg_rr,
			 coalesce(pr.product, 'PTS') 
			 ;

		 		 
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#t00_new';


	-- select * from #t00_new
	drop table if exists #t00_new;
	  		select * 
		into #t00_new
	 from #t00
	where 
	not (	(dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'  
							and r_end_date <> @rdt
							and seg3 in ('CM','CW'))
			or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'  
							and r_end_date <> dateadd(yy,-1, @rdt )
							and seg3 in ('LYSD'))
			or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'  
							and r_end_date <> dateadd(mm,-1, @rdt )
							and seg3 in ('LMSD'))
			or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'  
							and r_end_date <> eomonth(@rdt , -1 )
							and r_date = r_end_date
							and seg3 in ('LM'))
			or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'  
							and r_end_date <>  cast('2020-03-31' as date)
							and r_date = r_end_date
							and seg3 in ('MAR20'))
			or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'  
							and r_end_date <>  @lw_to /*dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))*/
							and r_date = r_end_date
							and seg3 in ('LW'))							  
						);


	with dst as (select * from #t00_new)
	delete from dst 
	where exists (
		select 1 from #t00_new b
		inner join (
			select a.seg3, a.external_id, a.r_end_date, a.dpd_bucket, a.dpd_bucket_end
			from #t00_new a
			group by a.seg3, a.external_id, a.r_end_date, a.dpd_bucket, a.dpd_bucket_end
			having count(*)>1
		) aa
		on b.external_id = aa.external_id		
		and b.r_end_date = aa.r_end_date
		and b.dpd_bucket = aa.dpd_bucket
		and b.dpd_bucket_end = aa.dpd_bucket_end
		and b.seg3 = aa.seg3

		where 1=1
		and b.r_date = b.r_end_date

		and dst.external_id = b.external_id
		and dst.r_date = b.r_date
		and dst.r_end_date = b.r_end_date
		and dst.dpd_bucket = b.dpd_bucket
		and dst.dpd_bucket_end = b.dpd_bucket_end
		and dst.seg3 = b.seg3
	);

	--учет КК 
	with a as (select * from #t00_new)
	update a set 
	a.overdue_days_end = a.overdue_days,
	a.dpd_bucket_end = a.dpd_bucket,
	a.seg_rr = 'Same'
	where exists (select 1 from #total_kk b
	where a.external_id = b.external_id
	and eomonth(a.r_date) = eomonth(dateadd(dd,1,b.dt_from))
	and a.r_date between b.dt_from and b.dt_to
	)
	--and a.r_date between '2020-10-01' and '2020-10-31'
	and a.overdue_days > a.overdue_days_end;



	--09/03/21 Полное исключение каникул
	if @flag_kk_total = 1
	begin

		with a as (select * from #t00_new)
		delete from a 
		where exists (select 1 from RiskDWH.dbo.det_kk_cmr_and_space b
						where a.external_id = b.external_id);

		delete from #t00_new where product in ('INSTALLMENT', 'PDL'); --15.02.2022


	end;


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'rep_coll_weekly_migr';


--declare @rdt date = dateadd(dd,-1, cast(RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)) as date));


delete from dbo.rep_coll_weekly_migr
where rep_dt = @rdt
and flag_exclude_kk = @flag_kk_total;

if @flag_kk_total = 0 --15.02.2022
begin

	delete from dbo.rep_coll_weekly_migr
	where rep_dt = @rdt
	and flag_exclude_kk = 2;

end;



with znam as (
	select a.seg3, a.dpd_bucket, sum(a.principal_rest) as principal_rest, a.product /*15.02.2022*/
	from #t00_new a
	group by a.seg3, a.dpd_bucket, a.product /*15.02.2022*/
union all
	select a.seg3, '(4#)_1_90' as dpd_bucket, sum(a.principal_rest) as principal_rest, a.product /*15.02.2022*/
	from #t00_new a
	where a.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90')
	group by a.seg3, a.product /*15.02.2022*/

),
chisl as (
	select a.seg3, 
		a.dpd_bucket, 
		case when 
		(a.dpd_bucket = '(5)_91_120' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90'))
		or (a.dpd_bucket = '(6)_121_150' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120'))
		or (a.dpd_bucket = '(7)_151_180' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_150'))
		or (a.dpd_bucket = '(8)_181_360' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_150','(7)_151_180'))
		or (a.dpd_bucket = '(9)_361+' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_150','(7)_151_180','(8)_181_360'))
		then '' else a.dpd_bucket_end
		end as dpd_bucket_end, 
		   sum(a.principal_rest) as principal_rest,
		   a.product /*15.02.2022*/
	from #t00_new a
	group by a.seg3, a.dpd_bucket, case when 
		(a.dpd_bucket = '(5)_91_120' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90'))
		or (a.dpd_bucket = '(6)_121_150' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120'))
		or (a.dpd_bucket = '(7)_151_180' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_150'))
		or (a.dpd_bucket = '(8)_181_360' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_150','(7)_151_180'))
		or (a.dpd_bucket = '(9)_361+' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_150','(7)_151_180','(8)_181_360'))
		then '' else a.dpd_bucket_end
		end,
		a.product /*15.02.2022*/

union all

	select a.seg3, 
		'(4#)_1_90' as dpd_bucket,
		a.dpd_bucket_end, 
		sum(a.principal_rest) as principal_rest,
		a.product /*15.02.2022*/
	from #t00_new a 
	where a.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90')
	and a.dpd_bucket_end = '(1)_0'
	group by a.seg3, a.dpd_bucket_end, a.product /*15.02.2022*/
)

/*insert into dbo.rep_coll_weekly_migr

select 
@rdt as rep_dt,
cast(sysdatetime() as datetime) as dt_dml,
concat(c.seg3,'#',c.dpd_bucket,'#',c.dpd_bucket_end) as metric,
c.seg3, c.dpd_bucket, c.dpd_bucket_end, c.principal_rest, 

case when z.principal_rest = 0 then 0 else
c.principal_rest / z.principal_rest
end as principal_rest_rate,

case when c.product in ('INSTALLMENT', 'PDL') then 2 else @flag_kk_total end as flag_exclude_kk

from chisl c
left join znam z
on c.seg3 = z.seg3
and c.dpd_bucket = z.dpd_bucket
and c.product = z.product
;*/

--exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'rep_coll_weekly_recov_alt';


--Рекавери по методу месячной презентации (на переходах)
delete from dbo.rep_coll_weekly_recov_alt
where rep_dt = @rdt
and flag_exclude_kk = @flag_kk_total;


if @flag_kk_total = 0 /*15.02.2022*/
begin
	delete from dbo.rep_coll_weekly_recov_alt
	where rep_dt = @rdt
	and flag_exclude_kk = 2;
end;


--insert into dbo.rep_coll_weekly_recov_alt
drop table if exists #rep_coll_weekly_recov_alt;
select *
into #rep_coll_weekly_recov_alt
from 

(
	select a.external_id,
	a.seg3, 
	replace(a.dpd_bucket, ')', '##)') as dpd_bucket,
	a.principal_rest, 
	a.pay_total, 
	a.product /*15.02.2022*/

	from #t00_new a
	where a.dpd_bucket <> '(1)_0'

union all

	select a.external_id,
	a.seg3, 
	case when a.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90') then '(4###)_1_90'
	when a.dpd_bucket in ('(5)_91_120','(6)_121_150','(7)_151_180','(8)_181_360','(9)_361+') then '(9###)_91+'
	end as dpd_bucket,
	a.principal_rest, 
	a.pay_total, 
	a.product /*15.02.2022*/

	from #t00_new a
	where a.dpd_bucket <> '(1)_0'


) aa;


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'rep_coll_weekly_svd_bal';


--финальная таблица для сохр.привед. баланса

drop table if exists #stg_svd_bal;

with base as (
	select a.product, /*15.02.2022*/ a.seg3, a.dpd_bucket, a.dpd_bucket_end, sum(a.principal_rest) as total_bal 
	from #t00_new a
	where (a.dpd_bucket = '(2)_1_30' and a.dpd_bucket_end = '(1)_0'
					  or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(1)_0'
					  or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(2)_1_30'
					  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(1)_0'
					  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(2)_1_30'
					  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(3)_31_60')
	group by a.product, /*15.02.2022*/ a.seg3, a.dpd_bucket, a.dpd_bucket_end
)
select 

b.product, b.seg3, b.dpd_bucket, b.dpd_bucket_end, b.total_bal,
b.total_bal * (isnull(c.k1,1)-isnull(c.k2,0))/isnull(c.k1,1)  as total_bal_adj

into #stg_svd_bal

from base b
 --коэффициенты для расчета приведенного баланса
left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef c
	on b.dpd_bucket = c.bucket_from
	and b.dpd_bucket_end = c.bucket_to;




delete from dbo.rep_coll_weekly_svd_bal
where rep_dt = @rdt
and flag_exclude_kk = @flag_kk_total;


if @flag_kk_total = 0 /*15.02.2022*/
begin
	delete from dbo.rep_coll_weekly_svd_bal
	where rep_dt = @rdt
	and flag_exclude_kk = 2;
end;

/*
with base as (
	select a.seg3, a.dpd_bucket, a.dpd_bucket_end, a.total_bal, a.total_bal_adj, a.product /*15.02.2022*/
	from #stg_svd_bal a
union all
	select aa.seg3, aa.dpd_bucket+'_ttl' as dpd_bucket , '' as dpd_bucket_end, 
	sum(aa.total_bal) as total_bal, sum(aa.total_bal_adj) as total_bal_adj, 
	aa.product /*15.02.2022*/
	from #stg_svd_bal aa
	group by aa.seg3, aa.dpd_bucket, aa.product /*15.02.2022*/
)*/
/*insert into dbo.rep_coll_weekly_svd_bal

select 
@rdt as rep_date,
cast(sysdatetime() as datetime) as dt_dml,
concat(b.seg3, '#', b.dpd_bucket, '#', b.dpd_bucket_end) as metric,
b.seg3, b.dpd_bucket, b.dpd_bucket_end, b.total_bal, b.total_bal_adj,
case when b.product in ('INSTALLMENT', 'PDL') then 2 else @flag_kk_total end as flag_exclude_kk /*15.02.2022*/

from base b;*/


if OBJECT_ID('RiskDWH.[CM\a.kurikalov].[sndbx_rep_coll_weekly_recov_alt2]') is null
begin
	select  top(0) * into RiskDWH.[CM\a.kurikalov].[sndbx_rep_coll_weekly_recov_alt2]
	from #rep_coll_weekly_recov_alt
end;

truncate table RiskDWH.[CM\a.kurikalov].[sndbx_stg_ip_0_90];
INSERT INTO RiskDWH.[CM\a.kurikalov].[sndbx_rep_coll_weekly_recov_alt2]
SELECT * FROM #rep_coll_weekly_recov_alt;



exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'drop temp (#) tables';


--Удаление временных таблиц
drop table #t2;
drop table #t3;
drop table #t4;
drop table #t5;
drop table #t6;
drop table #t7;
drop table #t8;

drop table #t_cm;
drop table #t_lm;
drop table #t_cw;
drop table #t_lmsd;
drop table #t_lw;
drop table #t_lysd;
drop table #t_mar20;

drop table #cm;
drop table #cm_new;
drop table #cm_new_full;
drop table #cm_new_w;
drop table #cm_pre;
drop table #cm_pre_w;
drop table #cm_w;

drop table #cw;
drop table #cw_new;
drop table #cw_new_full;
drop table #cw_new_w;
drop table #cw_pre;
drop table #cw_pre_w;
drop table #cw_w;

drop table #lm;
drop table #lm_new;
drop table #lm_new_full;
drop table #lm_new_w;
drop table #lm_pre;
drop table #lm_pre_w;
drop table #lm_w;

drop table #lmsd;
drop table #lmsd_new;
drop table #lmsd_new_full;
drop table #lmsd_new_w;
drop table #lmsd_pre;
drop table #lmsd_pre_w;
drop table #lmsd_w;

drop table #lw;
drop table #lw_new;
drop table #lw_new_full;
drop table #lw_new_w;
drop table #lw_pre;
drop table #lw_pre_w;
drop table #lw_w;

drop table #lysd;
drop table #lysd_new;
drop table #lysd_new_full;
drop table #lysd_new_w;
drop table #lysd_pre;
drop table #lysd_pre_w;
drop table #lysd_w;

drop table #mar20;
drop table #mar20_new;
drop table #mar20_new_full;
drop table #mar20_new_w;
drop table #mar20_pre;
drop table #mar20_pre_w;
drop table #mar20_w;

drop table #t00;
drop table #t00_new;

drop table #stg_svd_bal;
drop table #total_kk;

drop table #CMR;


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'FINISH';





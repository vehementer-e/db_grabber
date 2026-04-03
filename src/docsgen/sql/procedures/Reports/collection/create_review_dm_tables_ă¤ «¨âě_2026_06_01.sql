-- exec  [collection].[create_review_dm_tables]
CREATE PROC collection.create_review_dm_tables
AS
BEGIN
begin try
	declare @dt_st date = cast('2024-01-01' as date);
	declare @dt_end date = cast('2025-10-31' as date);

/*******************************************************************************/

	drop table if exists #stg_client_stage;
	
	select 
		*
	into #stg_client_stage
	from 
		RiskDWH.dbo.stg_client_stage
	where 
		cdate >= @dt_st;

/******************* Для учета КК - апрель-июнь.20 собран из отдельной таблицы, с правильным сроком просрочки ***********************/

	-- select * from  #stg_coll_bal_cmr_kk where external_id = '1709184570002' and eomonth(r_date) = '2020-06-30' order by r_date
	
	drop table if exists #stg_coll_bal_cmr_kk;
	
	select 
		a.r_year, 
		a.r_month, 
		a.r_day, 
		a.d as r_date,
		a.external_id, 
		case when a.ContractEndDate is null then 1 else 0 end as active_credit, 
		a.dpd_coll as overdue_days, 
		a.dpd_p_coll as overdue_days_p, 
		a.dpd_last_coll as last_dpd,
		a.prev_od as last_principal_rest, 
		dpd_bucket = (case  when dpd_coll <= 0 then '(1)_0'
							when dpd_coll between 1 and 30 then '(2)_1_30'
							when dpd_coll between 31 and 60 then '(3)_31_60'
							when dpd_coll between 61 and 90 then '(4)_61_90'
							when dpd_coll between 91 and 120 then '(5)_91_120'
							when dpd_coll between 121 and 360 then '(6)_121_360'
							when dpd_coll >= 360 then '(7)_361+' 
							end
		),
		dpd_bucket_p = (case when dpd_p_coll <= 0 then '(1)_0'
							when dpd_p_coll between 1 and 30 then '(2)_1_30'
							when dpd_p_coll between 31 and 60 then '(3)_31_60'
							when dpd_p_coll between 61 and 90 then '(4)_61_90'
							when dpd_p_coll between 91 and 120 then '(5)_91_120'
							when dpd_p_coll between 121 and 360 then '(6)_121_360'
							when dpd_p_coll >= 360 then '(7)_361+' 
							end
		),
		dpd_bucket_last = (case when dpd_last_coll <= 0 then '(1)_0'
								when dpd_last_coll between 1 and 30 then '(2)_1_30'
								when dpd_last_coll between 31 and 60 then '(3)_31_60'
								when dpd_last_coll between 61 and 90 then '(4)_61_90'
								when dpd_last_coll between 91 and 120 then '(5)_91_120'
								when dpd_last_coll between 121 and 360 then '(6)_121_360'
								when dpd_last_coll >= 360 then '(7)_361+' 
								end
		),
		[остаток од] as principal_rest, 
		a.[остаток %] as principal_percents_rest, 
		a.[сумма поступлений] as pay_total, 
		0 as total_wo
	into #stg_coll_bal_cmr_kk
	from 
		dwh2.dbo.dm_cmrstatbalance a
	where 
		a.d between @dt_st  and @dt_end
		and 
		[Тип Продукта] not in ('Инстоллмент','PDL')

	drop table if exists #t_all;
	select 
		r_year,
		r_month,
		r_day,
		r_date,
		external_id,
		overdue_days,
		overdue_days_p, 
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
	into #t_all
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
			(case when 
						count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and 
						row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
				  then 
						lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
				  else 
						b.dpd_bucket end
			) as next_dpd_bucket,
			(case when 
						count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and 
						row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
				  then 
						lead(a.overdue_days) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
				  else 
						b.overdue_days end
			) as next_overdue_days,
			(case when 
						count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and 
						row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
				  then 
						lead(a.r_day) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
				  else 
						b.r_day end
			) as next_r_day
		from (
			select 
				r_year,
				r_month,
				r_day,
				r_date,
				external_id,
				overdue_days,
				overdue_days_p, 
				principal_rest,
				last_principal_rest,
				(case 
					when overdue_days <= 0   then '(1)_0'
					when overdue_days <= 30  then '(2)_1_30'
		            when overdue_days <= 60  then '(3)_31_60'
		            when overdue_days <= 90  then '(4)_61_90'
					when overdue_days <= 120 then '(5)_91_120'
					when overdue_days <= 360 then '(6)_121_360'
					else '(7)_361+' 
					end
				) as dpd_bucket,
				'som-old'  as seg1,
				''         as seg2,
				'ALL'      as seg3
				from 
					#stg_coll_bal_cmr_kk a 
				where 
					r_day = 1
				union
				select 
					a.r_year,
					a.r_month,
					a.r_day,
					a.r_date,
					a.external_id,
					a.overdue_days,
					a.overdue_days_p, 
					a.principal_rest,
					a.last_principal_rest,
					(case 
						when a.overdue_days <= 0   then '(1)_0'
						when a.overdue_days <= 30  then '(2)_1_30'
		                when a.overdue_days <= 60  then '(3)_31_60'
		                when a.overdue_days <= 90  then '(4)_61_90'
						when a.overdue_days <= 120 then '(5)_91_120'
						when a.overdue_days <= 360 then '(6)_121_360'
						else '(7)_361+' 
						end
					) as dpd_bucket,
					'new-old' as seg1,
					''        as seg2,
					'ALL'     as seg3
			from (
				select 
					*, 
					LAG(overdue_days) over (partition by external_id order by r_date) as lag_overdue_days, 
					LAG(overdue_days_p) over (partition by external_id order by r_date) as lag_overdue_days_p 
				from 
					#stg_coll_bal_cmr_kk
			) a
			where 
				(r_day > 1	and overdue_days_p in (1,31,61,91,121,361))
				or ((lag_overdue_days_p between 1 and 30) and (lag_overdue_days = 0) and  r_day <> 1)
				or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days = 0) and r_day <> 1)
				or ((lag_overdue_days_p between 31 and 60) and (lag_overdue_days between 1 and 30) and r_day <> 1)
				or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days = 0) and r_day <> 1)
				or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 1 and 30) and r_day <> 1)
				or ((lag_overdue_days_p between 61 and 90) and (lag_overdue_days between 31 and 60) and r_day <> 1)
				or (lag_overdue_days_p between 91 and 120 and lag_overdue_days <= 90 and r_day <> 1)
				or (lag_overdue_days_p between 121 and 360 and lag_overdue_days <= 120 and r_day <> 1)
				or (lag_overdue_days_p >= 361 and lag_overdue_days <= 360 and r_day <> 1)
		) a
				left join #stg_coll_bal_cmr_kk b 
							on a.external_id = b.external_id
								and a.r_year      = b.r_year
								and a.r_month     = b.r_month
								and b.r_day       = day(eomonth(a.r_date))
								) a
																		
			group by r_year,
				r_month,
				r_day,
				r_date,
				external_id,
				overdue_days,
				overdue_days_p, 
				-- lag_overdue_days_p, lag_overdue_days,
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
						else 'Same' end)
							;

select top(10) * from #t_all;
/**********************************/	
	drop table if exists #all_pre;
	select 
		a.external_id, 
		a.r_date, 
		min(t.r_date) alt_r_end_date
	into #all_pre
	from 
		(select 
			*,  
			LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date 
		 from #t_all
		 ) a
	left join 
		#stg_coll_bal_cmr_kk t on a.r_date<=t.r_date 
								and t.r_date<=eomonth(a.r_date) 
								and a.external_id=t.external_id
	where		
		(
			(
				t.overdue_days_p > a.overdue_days 
				and
				(
					(t.overdue_days = 0 and t.overdue_days_p  between 1 and 30) 
					or (t.overdue_days between 1 and 30 and t.overdue_days_p  between 31 and 60)  
					or (t.overdue_days = 0 and t.overdue_days_p between 31 and 60)
					or (t.overdue_days = 0 and t.overdue_days_p between 61 and 90) 
					or (t.overdue_days between 1 and 30 and t.overdue_days_p between 61 and 90) 
					or (t.overdue_days between 31 and 60 and t.overdue_days_p between 61 and 90)
					or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
					or (t.overdue_days_p between 121 and 360 and t.overdue_days <= 120)
					or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
				)
			)
			or
			(
				t.overdue_days < a.overdue_days 
				and 
				(
					(t.overdue_days = 0 and t.overdue_days_p  between 1 and 30) 
					or (t.overdue_days between 1 and 30 and t.overdue_days_p  between 31 and 60)  
					or (t.overdue_days = 0 and (t.overdue_days_p between 31 and 60))
					or (t.overdue_days = 0 and (t.overdue_days_p between 61 and 90)) 
					or ((t.overdue_days between 1 and 30) and (t.overdue_days_p between 61 and 90)) 
					or ((t.overdue_days between 31 and 60) and (t.overdue_days_p between 61 and 90))
					or (t.overdue_days = 0 and t.overdue_days_p=0)
					or (t.overdue_days_p between 91 and 120 and t.overdue_days <= 90)
					or (t.overdue_days_p between 121 and 360 and t.overdue_days <= 120)
					or (t.overdue_days_p >= 361 and t.overdue_days <= 360)
				)
			)
		)
		and 
		t.r_date < (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
	group by 
		a.external_id, a.r_date;




drop table if exists #all;
	select a.*,
		   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
				and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
			   then (case when a.seg1 in ('som-new','new-new') then a.r_date
						  when  p.r_date is not null 
									then alt_r_end_date
						  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
			   else (case when p.r_date is not null 
									then alt_r_end_date
							   else (case when @dt_end <= eomonth(a.r_date)
									 then EOMONTH(a.r_date) --@rdt
									 else eomonth(a.r_date) end) end) end) r_end_date
	into #all 
	 from #t_all a
		left join #all_pre p on a.r_date=p.r_date and a.external_id=p.external_id;



drop table if exists #all_pre_w;
		  select a.external_id, a.r_date, min(t.r_date) alt_r_end_date
		  into #all_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_all) a
			left join #stg_coll_bal_cmr_kk t --#stg_coll_bal_cmr t 
			on a.r_date<=t.r_date 
			and t.r_date<=eomonth(a.r_date) 
			and a.external_id=t.external_id
			and t.r_date >= @dt_st
		  where	   --t.overdue_days_p in (1,31,61,91,361)
		    (
		  (t.overdue_days_p = 1 and a.overdue_days = 0
		  or t.overdue_days_p = 31 and a.overdue_days between 1 and 30
		  or t.overdue_days_p = 61 and a.overdue_days between 31 and 60
		  or t.overdue_days_p = 91 and a.overdue_days between 61 and 90
		  or t.overdue_days_p = 121 and a.overdue_days between 91 and 120
		  or t.overdue_days_p = 361 and a.overdue_days between 121 and 360)
		or 
		 (
		 (t.overdue_days = 1		and t.last_dpd = 0
		  or t.overdue_days = 31	and t.last_dpd between 1 and 30
		  or t.overdue_days = 61	and t.last_dpd between 31 and 60
		  or t.overdue_days = 91	and t.last_dpd between 61 and 90
		  or t.overdue_days = 121	and t.last_dpd between 91 and 120
		  or t.overdue_days = 361	and t.last_dpd between 121 and 360))
		  )
						and t.r_date <= (case when l_r_date is not null then l_r_date else eomonth(t.r_date) end)
		  group by a.external_id, a.r_date;


		   drop table if exists #all_w;
		  select a.*,
				 (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
						and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
					   then (case when a.seg1 in ('som-new','new-new') then a.r_date
								   when  p.r_date is not null 
											then alt_r_end_date
								  else dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)) end)
					   else (case when p.r_date is not null 
											then alt_r_end_date
								  else (case when @dt_end <= eomonth(a.r_date)
											 then eomonth(a.r_date)--@rdt
											 else eomonth(a.r_date) end) end) end) as r_end_date
		  into #all_w
		  from #t_all a
				left join #all_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;
-----------------------------------------------------
drop table if exists #all_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case 
					  when (a.r_date = r_end_date
					  and ((b.overdue_days_p between 1 and 30 and b.overdue_days = 0) 
							or (b.overdue_days_p between 31 and 60 and b.overdue_days = 0)
							or (b.overdue_days_p between 31 and 60 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days = 0)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days between 1 and 30)
							or (b.overdue_days_p between 61 and 90 and b.overdue_days  between 31 and 60)
							--переходы из [91-360] и [361+] в низшие бакеты
							or (b.overdue_days_p between 91 and 120 and b.overdue_days <= 90)
							or (b.overdue_days_p between 121 and 360 and b.overdue_days <= 120)
							or (b.overdue_days_p >= 361 and b.overdue_days <= 360)
							)) 
							
							then a.last_principal_rest
							
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.overdue_days_p
					else isnull(a.overdue_days,0) end as overdue_days,
				 
				case when a.r_date = r_end_date then b.dpd_bucket_p
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,

					isnull(b.overdue_days,0) as overdue_days_end,

				isnull(b.dpd_bucket,'(1)_0') as dpd_bucket_end,
				 format(a.r_date, 'MMMyy') as seg3, --a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #all_new
		  from #all      a
		  left join #stg_coll_bal_cmr_kk b --#stg_coll_bal_cmr b 
					on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date
						 and b.r_date >= @dt_st;



		drop table if exists #all_new_w;			 
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
				 then c.dpd_bucket_last 
				 else 
				 a.dpd_bucket end as dpd_bucket,

				 isnull(b.overdue_days_p,0) as overdue_days_end,
				 isnull(b.dpd_bucket,'(1)_0') as dpd_bucket_end,
				 format(a.r_date, 'MMMyy') as seg3,  --a.seg3,
				 (case when b.dpd_bucket is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #all_new_w
		  from #all_w     a
		  left join #stg_coll_bal_cmr_kk b --#stg_coll_bal_cmr b 
				on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.r_date
						 and b.r_date >= @dt_st
			left join #stg_coll_bal_cmr_kk c
			on a.external_id = c.external_id
			and a.r_date = c.r_date
						 ;

	drop table if exists #all_new_full;	
			select *
			into #all_new_full
			from		 
		   ( select *
		  from #all_new 
		  where dpd_bucket <> dpd_bucket_end or r_end_date = eomonth(r_date) --@rdt
		  UNION 
		  ( select *
		  from #all_new_w 
		 where (dpd_bucket = '(1)_0' and dpd_bucket_end = '(2)_1_30')
								or (dpd_bucket = '(2)_1_30' and dpd_bucket_end = '(3)_31_60')
								or (dpd_bucket = '(3)_31_60' and dpd_bucket_end = '(4)_61_90')
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_120')
								or (dpd_bucket = '(5)_91_120' and dpd_bucket_end = '(6)_121_360')
								or (dpd_bucket = '(6)_121_360' and dpd_bucket_end = '(7)_361+') ) ) u;


/**********************************/
	drop table if exists #_t00
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
		   --sum(isnull(b.pay_total,0)) as pay_total,
		   sum(isnull(b.total_wo,0)) as total_wo
	into #_t00
	from (
		  select * from  #all_new_full              -----#all_new_full_2
		  ) a
	left join #stg_coll_bal_cmr_kk b -- #stg_coll_bal_cmr_base b --заменил временную мфо
	on a.external_id = b.external_id 
	and b.r_date >= a.r_date 
	and b.r_date <= a.r_end_date
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
			 a.seg_rr;


	-- select * from #_t00_new where eomonth(r_date) = '2020-05-31'

	drop table if exists #_t00_new;
	  		select t.* 
		into #_t00_new
	 from #_t00 t
	where not (
				(t.dpd_bucket = '(1)_0' and t.dpd_bucket_end = '(1)_0'  
							and t.r_end_date <>  @dt_end
							and t.seg3 in ('CM'))

			or (t.dpd_bucket = '(1)_0' and t.dpd_bucket_end = '(1)_0'  
							and t.r_end_date <> eomonth(dateadd(yy,-1,@dt_end))
							and t.seg3 in ('LYSD'))
			
			or (t.dpd_bucket = '(1)_0' and t.dpd_bucket_end = '(1)_0'  
							and t.r_end_date <> eomonth(dateadd(mm,-1,@dt_end))
							and t.r_date = t.r_end_date
							and t.seg3 in ('LM'))

			or (t.dpd_bucket = '(1)_0' and t.dpd_bucket_end = '(1)_0'  
							and t.r_end_date <>  eomonth(dateadd(mm,-2,@dt_end))
							and t.r_date = t.r_end_date
							and t.seg3 in ('JAN20+'))		  
						);

	with dst as (select * from #_t00_new)
	delete from dst 
	where exists (
		select 1 from #_t00_new b
		inner join (
			select a.seg3, a.external_id, a.r_end_date, a.dpd_bucket, a.dpd_bucket_end
			from #_t00_new a
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

select top(10) * from #_t00_new;

	drop table if exists #stg_portf_wrt_offs;

	select 

	concat(aa.seg3, '#', aa.dpd_bucket) as metric,
	aa.seg3,
	aa.dpd_bucket,
	aa.principal_rest,
	aa.total_wo,
	aa.principal_count
	
	into #stg_portf_wrt_offs

	from 

	(
		select a.seg3, 
		a.dpd_bucket,
		sum(a.principal_rest) as principal_rest,
		sum(a.total_wo) as total_wo,
		cast(sum(1) as float) as principal_count  --say_210120

		from #_t00_new a
		where a.dpd_bucket <> '(1)_0'
		group by a.seg3, a.dpd_bucket

		union all

		select a.seg3, 
		case when a.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90') then '(4#)_1_90'
		when a.dpd_bucket in ('(5)_91_120','(6)_121_360','(7)_361+') then '(6#)_91+'
		end as dpd_bucket,
		sum(a.principal_rest) as principal_rest,
		sum(a.total_wo) as total_wo,
		cast(sum(1) as float) as principal_count  --say_210120
		from #_t00_new a
		where a.dpd_bucket <> '(1)_0'
		group by a.seg3, 
		case when a.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90') then '(4#)_1_90'
		when a.dpd_bucket in ('(5)_91_120','(6)_121_360','(7)_361+') then '(6#)_91+'
		end 
	) aa;

	--IMPROVE, WORSE

	/* select * from #stg_migrations */

	drop table if exists #pre_migrations;

	with znam as (
		select 
			a.seg3, 
			a.dpd_bucket,
			sum(a.principal_rest) as principal_rest,
			cast(sum(1) as float) as principal_count   -- say_210120
		from 
			#_t00_new a
		group by 
			a.seg3, a.dpd_bucket
	),
	chisl as (
		select a.seg3, 
			a.dpd_bucket,
			case when 
			(a.dpd_bucket = '(5)_91_120' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90'))
			or (a.dpd_bucket = '(6)_121_360' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120'))
			or (a.dpd_bucket = '(7)_361+' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_360'))
			then '' else a.dpd_bucket_end
			end as dpd_bucket_end, 
			   sum(a.principal_rest) as principal_rest,
			   cast(sum(1) as float) as principal_count   -- say_210120
		from #_t00_new a
		group by a.seg3, 
		a.dpd_bucket,
		case when 
			(a.dpd_bucket = '(5)_91_120' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90'))
			or (a.dpd_bucket = '(6)_121_360' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120'))
			or (a.dpd_bucket = '(7)_361+' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_360'))
			then '' else a.dpd_bucket_end
			end
	)
	select 
		concat(c.seg3,'#',c.dpd_bucket,'#',c.dpd_bucket_end) as metric,
		c.seg3, c.dpd_bucket, c.dpd_bucket_end, c.principal_rest, 
		case 
			when z.principal_rest = 0 then 0 
			else c.principal_rest / z.principal_rest
		end as principal_rest_rate,
	c.principal_count,
	case
		when z.principal_count = 0
		then 0
		else c.principal_count / z.principal_count 
	end as principal_count_rate

	into #pre_migrations

	from chisl c
	left join znam z
	on c.seg3 = z.seg3
	and c.dpd_bucket = z.dpd_bucket;

	drop table if exists #stg_migrations;
	
	with chisl as (
		select 
			a.seg3, '(6#)_91+' as dpd_bucket, '' as dpd_bucket_end, sum(principal_rest) as total_od 
			,cast(sum(1) as float) as total_count  -- say_210120
		from 
			#_t00_new a
		where 
			(a.dpd_bucket = '(5)_91_120' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90'))
			or (a.dpd_bucket = '(6)_121_360' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120'))
			or (a.dpd_bucket = '(7)_361+' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_120','(6)_121_360'))
		group by 
			a.seg3
		union all
		select 
			b.seg3, '(6#)_91+' as dpd_bucket, b.dpd_bucket_end,  sum(principal_rest) as total_od 
			,cast(sum(1) as float) as total_count  -- say_210120
		from 
			#_t00_new b
		where 
			b.dpd_bucket = '(6)_121_360' and b.dpd_bucket_end = '(7)_361+'
		group by 
			b.seg3, b.dpd_bucket_end
	),
	znam as (
	select a.seg3, '(6#)_91+' as dpd_bucket, sum(principal_rest) as total_od  
	,cast(sum(1) as float) as total_count  -- say_210120
	from #_t00_new a
	where a.dpd_bucket in ('(5)_91_120','(6)_121_360','(7)_361+')
	group by a.seg3
	),
	total_91_over as (
	select 
	concat( z.seg3, '#' ,z.dpd_bucket, '#', c.dpd_bucket_end) as metric,
	z.seg3, z.dpd_bucket, c.dpd_bucket_end,
	c.total_od as principal_rest, 
	case
		when z.total_od = 0
		then 0
		else c.total_od / z.total_od 
	end as principal_rest_rate,
	c.total_count,
	case 
		when z.total_count = 0
		then 0
		else c.total_count / z.total_count 
	end as principal_count_rate

	from znam z 
	left join chisl c
	on z.seg3 = c.seg3
	and z.dpd_bucket = c.dpd_bucket)

	select * 
	into #stg_migrations
	from (
	select * from #pre_migrations 
	union all
	select * from total_91_over
	) aa 
	;

/****************** CASH, ACTIVATION, AVG_PMT ****************************/
	
	drop table if exists #base_cmr_mfo;
	select a.r_date, a.external_id, a.dpd_bucket_p, a.overdue_days_p, a.pay_total, a.principal_rest   --a.pay_total поменял b.pay_total
	into #base_cmr_mfo
	from #stg_coll_bal_cmr_kk a

	drop table if exists #stg_sb_0_90;
	
	select distinct a.external_id, a.r_date
	into #stg_sb_0_90
	from #base_cmr_mfo a
	inner join #stg_client_stage b
	on a.external_id = b.external_id
	and a.r_date = b.cdate
	left join #stg_client_stage bb
	on a.external_id = bb.external_id
	and a.r_date = dateadd(dd,1,bb.cdate)
	inner join Stg._Collection.Deals_history c
	on a.external_id = c.Number
	and a.r_date = c.r_date
	inner join stg._Collection.DealStatus d
	on c.IdStatus = d.Id
	where 1=1
	--стадия СБ
	and (b.CRMClientStage = 'СБ' or /*10/12/2020*/ bb.CRMClientStage = 'СБ' and b.CRMClientStage = 'Closed')
	--был платеж
	and a.pay_total > 0
	--кроме бакетов, которые и так учитываются в 91+ 
	and a.dpd_bucket_p not in ('(5)_91_120','(6)_121_360','(7)_361+')
	--статус договора на момент платежа Legal
	and d.[Name] = 'Legal'
	--была просрочка более 90 дней (соответственно стадия Legal)
	and exists (select 1 from #stg_coll_bal_cmr_kk e
		where a.external_id = e.external_id
		and a.r_date > e.r_date
		and e.overdue_days_p > 90)
	--в день платежа не был у агента
	and not exists (
		select 2 
		--DWH-257
		from (
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
		) as f
		where a.external_id = f.external_id
		and a.r_date between f.st_date and f.end_date
	)
	;

	merge into #base_cmr_mfo dst
	using #stg_sb_0_90 src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set 
	dst.dpd_bucket_p = '(0-90)Hard'
	;

	--отсечение 0-90 Hard

	drop table if exists #reestr_0_90_hard;
	select distinct
		a.external_id, a.r_date, a.dpd_bucket_p, a.pay_total,
		b.CRMClientStage, 
		case 
			when isnull(c.agent_name,'CarMoney') <> 'CarMoney' 
			then 'KA'
			else 'CarMoney' end as agent_gr

	into #reestr_0_90_hard

	from #base_cmr_mfo a
	left join #stg_client_stage b
	on a.external_id = b.external_id
	and a.r_date = b.cdate
	--DWH-257
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
		) as c

	on a.external_id = c.external_id
	and a.r_date between c.st_date and c.end_date
	where a.pay_total > 0
	and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	and (
		b.CRMClientStage = 'Legal' and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
		or b.CRMClientStage = 'Hard' and a.dpd_bucket_p in ('(2)_1_30','(3)_31_60','(4)_61_90')
		or isnull(c.agent_name,'CarMoney') not in ('CarMoney','ACB') and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	)
	;

	merge into #base_cmr_mfo dst
	using #reestr_0_90_hard src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set dst.dpd_bucket_p = '(0-90)Hard';

	-------------------------------------------------------------------

	-- select * from #portf_base where dpd_buck = '(3)_31_60' and seg_high = 'Sep20'
	-- select * from #base_cmr_mfo where external_id = '1709184570002' order by r_date

	drop table if exists #portf_base;
	--база для портфеля и платежей
	select c.seg_high, c.external_id, c.r_date, 	
	
	c.dpd_bucket_p as dpd_buck, 

	case when c.dpd_bucket_p in ('(2)_1_30','(3)_31_60','(4)_61_90') then '(4#)_1_90'
		 when c.dpd_bucket_p in ('(5)_91_120', '(6)_121_360', '(7)_361+') then '(6#)_91+' end as dpd_buck_agg,

	c.pay_total, c.principal_rest
	into #portf_base 
	from (
		select format(a.r_date, 'MMMyy') as seg_high,
	a.external_id, a.r_date, a.dpd_bucket_p, a.pay_total, a.principal_rest
	from #base_cmr_mfo a
	where a.r_date between @dt_st and @dt_end
	and a.dpd_bucket_p <> '(1)_0'
	) c
	;

	
	drop table if exists #stg_rep;

	with daily_portf as (
		select a.seg_high, a.r_date, a.dpd_buck, 
			sum(a.principal_rest) as total_od
		from #portf_base a
		group by a.seg_high, a.r_date, a.dpd_buck
	),
	avg_portf as (
		select d.seg_high, d.dpd_buck, 
			avg(d.total_od) as total_od
		from daily_portf d
		group by d.seg_high, d.dpd_buck
	),
	pmt_base as (
		select a.seg_high, a.r_date, a.dpd_buck, a.external_id,
			sum(a.pay_total) as pay_total,
			count(*) as cnt_pmt
		from #portf_base a
		where a.pay_total > 0
		group by a.seg_high, a.r_date, a.dpd_buck, a.external_id
	),
	pmt as (
		select dd.seg_high, dd.dpd_buck, 
				sum(dd.pay_total) as pay_total, 
				count(distinct dd.external_id) as total_dist_pmt,
				sum(cnt_pmt) as total_pmt
		from pmt_base dd
		group by dd.seg_high, dd.dpd_buck
	),
	creds as (
	select bs.seg_high, 
			bs.dpd_buck, 
			count(distinct bs.external_id) as cnt_cred
	from #portf_base bs
	group by bs.seg_high, bs.dpd_buck
	)
	select 
	ap.seg_high,
	ap.dpd_buck, 
	ap.total_od,
	p.pay_total,
	case 
		when ap.total_od = 0 
		then 0 
		else p.pay_total / ap.total_od 
	end as recov,
	p.total_dist_pmt,
	p.total_pmt,
	case
		when cast(p.total_pmt as float) = 0.0
		then 0.0
		else p.pay_total / cast(p.total_pmt as float) 
	end as avg_check,
	cr.cnt_cred,
	case
		when cast(cr.cnt_cred as float) = 0.0
		then 0.0
		else cast(p.total_dist_pmt as float) / cast(cr.cnt_cred as float) 
	end as activ

	into #stg_rep

	from avg_portf ap
	left join pmt p
	on ap.dpd_buck = p.dpd_buck
	and ap.seg_high = p.seg_high
	left join creds cr
	on ap.dpd_buck = cr.dpd_buck
	and ap.seg_high = cr.seg_high;

-------------------------------------------------------------------
	----агрегат 1-90 и 91+
	drop table if exists #stg_rep_agg;

	with daily_portf as (
		select a.seg_high, a.r_date, a.dpd_buck_agg, 
			sum(a.principal_rest) as total_od
		from #portf_base a
		group by a.seg_high, a.r_date, a.dpd_buck_agg
	),
	avg_portf as (
		select d.seg_high, d.dpd_buck_agg, 
			avg(d.total_od) as total_od
		from daily_portf d
		group by d.seg_high, d.dpd_buck_agg
	),
	pmt_base as (
		select a.seg_high, a.r_date, a.dpd_buck_agg, a.external_id,
			sum(a.pay_total) as pay_total,
			count(*) as cnt_pmt
		from #portf_base a
		where a.pay_total > 0
		group by a.seg_high, a.r_date, a.dpd_buck_agg, a.external_id
	),
	pmt as (
		select dd.seg_high, dd.dpd_buck_agg, 
				sum(dd.pay_total) as pay_total, 
				count(distinct dd.external_id) as total_dist_pmt,
				sum(cnt_pmt) as total_pmt
		from pmt_base dd
		group by dd.seg_high, dd.dpd_buck_agg
	),
	creds as (
	select bs.seg_high, 
			bs.dpd_buck_agg, 
			count(distinct bs.external_id) as cnt_cred
	from #portf_base bs
	group by bs.seg_high, bs.dpd_buck_agg
	)
	select 
	ap.seg_high,
	ap.dpd_buck_agg, 
	ap.total_od,
	p.pay_total,
	case 
		when ap.total_od = 0
		then 0
		else p.pay_total / ap.total_od 
	end as recov,
	p.total_dist_pmt,
	p.total_pmt,
	case
		when cast(p.total_pmt as float) = 0.0
		then 0.0
		else p.pay_total / cast(p.total_pmt as float) 
	end as avg_check,
	cr.cnt_cred,
	case
		when cast(cr.cnt_cred as float) = 0.0
		then 0.0
		else cast(p.total_dist_pmt as float) / cast(cr.cnt_cred as float)
	end as activ

	into #stg_rep_agg

	from avg_portf ap
	left join pmt p
	on ap.dpd_buck_agg = p.dpd_buck_agg
	and ap.seg_high = p.seg_high
	left join creds cr
	on ap.dpd_buck_agg = cr.dpd_buck_agg
	and ap.seg_high = cr.seg_high;

	drop table if exists #stg_pmt_activ;

	select t.seg_high, 
			t.dpd_buck, 
			t.total_od, 
			t.pay_total,
			t.recov,
			t.total_dist_pmt, 
			t.total_pmt,
			t.avg_check,
			t.cnt_cred,
			t.activ

	into #stg_pmt_activ

	from (
	select * from #stg_rep
	union all
	select * from #stg_rep_agg
	) t
	;

	-- select * from #stg_rep where dpd_buck = '(2)_1_30' and seg_high = 'Jun20'

	/*********************** 0-90 Hard ****************************/

	drop table if exists #base_0_90_hard;
	
	select a.external_id, a.r_date, a.pay_total,
	isnull(a.dpd_bucket_p,a.dpd_bucket_p) as dpd_bucket_p -- b.dpd_bucket_p поменял на c.dpd_bucket_p
	into #base_0_90_hard
	from #stg_coll_bal_cmr_kk a --#stg_coll_bal_cmr_base a --заменил временную мфо

	drop table if exists #pre_0_90_hard;

	select a.external_id, a.r_date, a.dpd_bucket_p, a.pay_total, cst.CRMClientStage
	into #pre_0_90_hard
	
	from #base_0_90_hard a
	
	left join #stg_client_stage cst 
	on a.external_id=cst.external_id 
	and a.r_date= cst.cdate

	--DWH-257
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
		) as vag
	on a.external_id = vag.external_id
	and a.r_date between vag.st_date and vag.end_date

	left join #stg_sb_0_90 sb --27/11/20
	on a.external_id = sb.external_id
	and a.r_date = sb.r_date

	where 1=1
	and ((cst.CRMClientStage = 'Hard' and a.dpd_bucket_p in ('(2)_1_30','(3)_31_60','(4)_61_90'))
		or (cst.CRMClientStage = 'Legal' and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90'))
		or isnull(vag.agent_name ,'Carmoney') not in ('Carmoney','ACB') and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
		or sb.external_id is not null
		)	
	;

		drop table if exists #stg_0_90_hard;

		select aa.seg_high, aa.pmt_0_90_hard
		into #stg_0_90_hard
	from (
		select format(a.r_date,'MMMyy') as seg_high, sum(pay_total) as pmt_0_90_hard
		from #pre_0_90_hard a
		where a.r_date between @dt_st and @dt_end
		group by format(a.r_date,'MMMyy')
	) aa
	where aa.pmt_0_90_hard is not null
	;

/********************** 0-90 Isp Proiz *****************************/

	--обрабатываем исполнительные листы для поиска даты начала/заявки/передачи производства
	drop table if exists #stg_isp_proiz;
	select
	deals.Number as external_id,
	eo.Accepted, 
	cast(eo.AcceptanceDate as date) as accept_dt,

	eo.Id as enf_ord_id,
	cast(eo.CreateDate as date) as enf_ord_create_dt,
	cast(eo.UpdateDate as date) as enf_ord_upd_dt,
	replace(replace(eo.Number,' ',''),'№','') as enf_ord_number,
	
	ep.Id as enf_proc_id,
	cast(ep.CreateDate as date) as enf_proc_create_dt,
	cast(ep.UpdateDate as date) as enf_proc_upd_dt,
	null as EndDate, --ep.EndDate,
	ep.CaseNumberInFSSP,

	jc.id as jud_claim_id,
	cast(jc.CreateDate as date) as jud_claim_cr_dt,
	cast(jc.UpdateDate as date) as jud_claim_upd_dt,

	jp.id as jud_proc_id,
	cast(jp.CreateDate as date) as jud_proc_cr_dt,
	cast(jp.UpdateDate as date) as jud_proc_upd_dt,

	cast(eo.Date as date) as isp_list_dt,
	cast(eo.ReceiptDate as date) as receipt_dt,
	cast(ep.ExcitationDate as date) as excitation_dt,
	
	null as adopt_bal_dt, --cast(ep.AdoptionBalanceDate as date) as adopt_bal_dt,
	cast(ep.ApplicationDeliveryDate as date) as app_delivery_dt,
	null as arest_car_dt --cast(ep.ArestCarDate as date) as arest_car_dt

	into #stg_isp_proiz

	FROM [Stg].[_Collection].[EnforcementOrders]  eo
	left join [Stg].[_Collection].JudicialClaims jc
	On jc.id = eo.JudicialClaimId
	left join [Stg].[_Collection].JudicialProceeding jp
	on jp.Id = jc.JudicialProceedingId
	left join [Stg].[_Collection].Deals 
	on Deals.Id = jp.DealId
	left join [Stg].[_Collection].EnforcementProceeding ep 
	on eo.id=ep.EnforcementOrderId
	--where
	--	Deals.Number = '1708304560002';

	--выбираем дату начала исп. производства
	drop table if exists #isp_proiz;

	select aa.external_id, min(aa.total_dt_from) as dt_from

	into #isp_proiz

	from (
		select a.external_id,
		coalesce(  a.isp_list_dt, a.receipt_dt, a.app_delivery_dt, a.excitation_dt, a.accept_dt,
		a.jud_proc_cr_dt, a.jud_claim_cr_dt, a.enf_proc_create_dt, a.enf_ord_create_dt,
		a.jud_claim_upd_dt, a.jud_proc_upd_dt) as total_dt_from
		from #stg_isp_proiz a
		where 1=1
		and a.Accepted = 1
		) aa
	group by aa.external_id
		;

	--если статус по клиенту "ИП", то включаем все договоры в "ИП"
	drop table if exists #cli_con_stages;

WITH RankedStages AS (
    SELECT
        CMRContractGUID = ISNULL(
            es.CRMContractGuid,
            CAST(dbo.getGUIDFrom1C_IDRREF(cr.Ссылка) AS NVARCHAR(64))
        ),
        external_id      = es.external_id,
        cs.CRMClientGUID,
        date_on          = CAST(cs.call_dt AS DATE),
        CMRContractStage = es.External_Stage,
        CRMClientStage   = cs.Client_Stage,
        ROW_NUMBER() OVER(
            PARTITION BY es.external_id, CAST(cs.call_dt AS DATE)
            ORDER BY cs.call_dt DESC
        ) AS rn
    FROM
        Stg._loginom.Collection_Client_Stage_history cs WITH (INDEX = ix_call_dt_CRMClientGUID)
    INNER JOIN
        Stg._loginom.Collection_External_Stage_history es WITH (INDEX = ix_call_dt_CRMClientGUID)
        ON cs.CRMClientGUID = es.CRMClientGUID
       AND cs.call_dt      = es.call_dt
    LEFT JOIN
        Stg._1cCMR.Справочник_Договоры cr
        ON cr.Код = es.external_id
    WHERE
        cs.Client_Stage = 'ИП'
      AND CAST(cs.call_dt AS DATE) BETWEEN @dt_st AND @dt_end
      AND EXISTS (
          SELECT 1 
          FROM #all a 
          WHERE a.external_id = es.external_id
      )
)
SELECT
    external_id,
    date_on,
    CMRContractGUID,
    CMRContractStage,
    CRMClientGUID,
    CRMClientStage
INTO #cli_con_stages
FROM RankedStages
WHERE rn = 1;

drop table if exists #pre_ip_0_90;

	select a.r_date, a.external_id, 
	isnull(b.dpd_bucket_p, b.dpd_bucket_p) as dpd_bucket_p, -- d.dpd_bucket_p поменял на b.dpd_bucket_p
	isnull(b.overdue_days_p, b.overdue_days_p) as overdue_days_p, -- d.dpd_bucket_p поменял на b.dpd_bucket_p
	a.pay_total,
	format(a.r_date, 'MMMyy') as seg_rest,
	case when isnull(c.agent_name, 'CarMoney') in ('ACB','CarMoney') 
			then 0
		else 1
		end as flag_agent,
	s.CRMClientStage as con_stage

	into #pre_ip_0_90

	from #stg_coll_bal_cmr_kk a    --#stg_coll_bal_cmr_base a --заменил временную мфо
	inner join #stg_coll_bal_cmr_kk b
	on a.external_id = b.external_id 
	and a.r_date = b.r_date
	--DWH-257
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
		) as c
	on a.external_id = c.external_id
	and a.r_date between c.st_date and c.end_date

	left join #stg_client_stage s
	on a.external_id = s.external_id
	and a.r_date = s.cdate

		drop table if exists #pre2_ip_0_90;

	select a.r_date, a.external_id, a.dpd_bucket_p, a.overdue_days_p, a.pay_total,
	a.seg_rest,
	case when i.external_id is not null and a.flag_agent = 0 then 'ИП'
	when ccs.external_id is not null and a.flag_agent = 0 then 'ИП'
	when a.flag_agent = 1 then 'Агент'
	else 'Хард' end as seg_ip_hard_agent

	into #pre2_ip_0_90

	from #pre_ip_0_90 a
	left join #isp_proiz i
	on a.external_id = i.external_id
	and a.r_date >= i.dt_from

	left join #cli_con_stages ccs
	on a.external_id = ccs.external_id
	and a.r_date = ccs.date_on

	where (a.overdue_days_p >= 91 
	or (a.con_stage = 'ИП' or i.external_id is not null or ccs.external_id is not null) and a.flag_agent = 0
	)
	;

	drop table if exists #stg_ip_0_90;

	select aa.seg, aa.pmt_0_90_ip

	into #stg_ip_0_90
	
	from (
	select a.seg_rest as seg, isnull(sum(a.pay_total),0) as pmt_0_90_ip
	from #pre2_ip_0_90 a
	where a.seg_ip_hard_agent = 'ИП'
	and a.dpd_bucket_p not in ('(5)_91_120','(6)_121_360','(7)_361+')
	group by a.seg_rest

	) aa
	;

	if OBJECT_ID('collection.dm_review_portf_wrt_offs') is null
		begin
			select top(0)
				*
			into collection.dm_review_portf_wrt_offs
			from #stg_portf_wrt_offs;
	end

	if OBJECT_ID('collection.dm_review_migrations') is null
		begin
			select top(0)
				*
			into collection.dm_review_migrations
			from #stg_migrations;
	end

	if OBJECT_ID('collection.dm_review_pmt_activ') is null
		begin
			select top(0)
				*
			into collection.dm_review_pmt_activ
			from  #stg_pmt_activ;
	end

	if OBJECT_ID('collection.dm_review_0_90_hard') is null
		begin
			select top(0)
				*
			into collection.dm_review_0_90_hard
			from #stg_0_90_hard;
	end

	if OBJECT_ID('collection.dm_review_ip_0_90') is null
		begin
			select top(0)
				*
			into collection.dm_review_ip_0_90
			from #stg_ip_0_90;
	end

	begin tran
			delete from collection.dm_review_portf_wrt_offs;
			insert into collection.dm_review_portf_wrt_offs
			select
				*				
			from #stg_portf_wrt_offs;

			delete from  collection.dm_review_migrations;
			insert into  collection.dm_review_migrations 
			select 
				* 
			from #stg_migrations;

			delete from  collection.dm_review_pmt_activ;
			insert into  collection.dm_review_pmt_activ 
			select 
				* 
			from #stg_pmt_activ;

			delete from  collection.dm_review_0_90_hard;
			insert into  collection.dm_review_0_90_hard 
			select 
				* 
			from #stg_0_90_hard;

			delete from  collection.dm_review_ip_0_90;
			insert into  reports.collection.dm_review_ip_0_90 
			select 
				* 
			from #stg_ip_0_90;
		
	commit tran

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
		
END;

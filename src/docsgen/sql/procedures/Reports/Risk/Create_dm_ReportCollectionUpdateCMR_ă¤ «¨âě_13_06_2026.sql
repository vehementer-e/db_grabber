





CREATE procedure [Risk].[Create_dm_ReportCollectionUpdateCMR]
as


SET NOCOUNT ON
SET XACT_ABORT ON

SET DATEFIRST 1	  



declare @month_days int, 
@src_name nvarchar(100),
@rdt date
;

set @month_days = day(eomonth(dateadd(dd,-1,cast(getdate() as date))));
set @src_name = 'UPDATE_REP_COLL_CMR';
set @rdt = cast(dateadd(dd,-1,sysdatetime()) as date);

declare @days_in_month tinyint = day(eomonth(@rdt));


begin try

	
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY CMR - START';

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'START';


	drop table if exists #CMR;

	select a.d, a.external_id, a.r_day, a.r_month, a.r_year,
	a.dpd_coll, a.dpd_p_coll, a.dpd_last_coll,
	a.bucket_coll, a.bucket_p_coll, a.bucket_last_coll,
	a.[остаток од],
	a.prev_dpd_coll, 
	a.prev_dpd_p_coll,
	a.prev_od,
	cast(isnull(a.[основной долг уплачено]   ,0) as float) +
	cast(isnull(a.[Проценты уплачено]		 ,0) as float) +
	cast(isnull(a.[ПениУплачено]			 ,0) as float) +
	cast(isnull(a.[ГосПошлинаУплачено]		 ,0) as float) +
	cast(isnull(a.[ПереплатаУплачено]*(-1)	 ,0) as float) -
	cast(isnull(a.[ПереплатаНачислено]*(-1)	 ,0) as float) as pay_total
	into #CMR
	from dwh2.dbo.dm_CMRStatBalance a
	where a.d >= '2023-01-01' and a.d <= @rdt;
	

	--Бизнес-займы
	insert into #CMR
	select  a.r_date as d, a.external_id, a.r_day, a.r_month, a.r_year,
	a.overdue_days as dpd_coll, 
	a.overdue_days_p as dpd_p_coll, 
	a.last_dpd as dpd_last_coll,
	a.dpd_bucket as bucket_coll, 
	a.dpd_bucket_p as bucket_p_coll, 
	a.dpd_bucket_last as bucket_last_coll,
	a.principal_rest as [остаток од],
	a.overdue_days as prev_dpd_coll, 
	a.overdue_days_p as prev_dpd_p_coll,
	a.last_principal_rest as prev_od,
	a.pay_total
	from RiskDWH.dbo.det_business_loans a;


	drop index if exists tmp_cmr_idx on #CMR;
	create clustered index tmp_cmr_idx on #CMR (external_id, d);

		/******************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#TTT1';

						drop table if exists #t_all;
						select distinct
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
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.dpd_bucket) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else isnull(b.bucket_coll,'(1)_0') end) as next_dpd_bucket,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.overdue_days) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else isnull(b.dpd_coll,0) end) as next_overdue_days,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.r_day) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else b.r_day end) as next_r_day
						from (select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 a.external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									 isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									 cast(isnull(a.[остаток од],0) as float) as principal_rest,
									 a.prev_od as last_principal_rest,
									 isnull(a.bucket_coll,'(1)_0') as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'ALL'      as seg3
							  --from [RiskDWH].[dbo].[stg_coll_bal_cmr] a
							  from #CMR a
						--первый день месяца с просрочкой
							  where r_day = 1

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 a.external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									 isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									 cast(isnull(a.[остаток од],0) as float) as principal_rest,
									 a.prev_od as last_principal_rest,
									 isnull(a.bucket_coll,'(1)_0') as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'ALL'     as seg3
							  from #CMR a
							  --остальные дни месяцев, кроме первого + прозошли переходы по бакетам
							  where (r_day > 1
								and dpd_p_coll in (1,31,61,91,361))
								or ((prev_dpd_p_coll between 1 and 30) and (prev_dpd_coll = 0) and  r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 31 and 60) and r_day <> 1)
								--переходы из [91-360] и [361+] в низшие бакеты
								or (prev_dpd_p_coll between 91 and 360 and prev_dpd_coll <= 90 and r_day <> 1)
								or (prev_dpd_p_coll >= 361 and prev_dpd_coll <= 360 and r_day <> 1)

															) a
							  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
							  left join #CMR b
								on a.external_id = b.external_id
								and a.r_year      = b.r_year
								and a.r_month     = b.r_month
								and b.r_day       = (case when  year(@rdt) = a.r_year
															and month(@rdt) = a.r_month
														then day(@rdt)
														else day(eomonth(a.r_date)) end)) a;
                     
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T2';


						drop table if exists #t_lysd;
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
						into #t_lysd
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
									 else isnull(b.bucket_coll,'(1)_0') end) as next_dpd_bucket,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.overdue_days) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else isnull(b.dpd_coll,0) end) as next_overdue_days,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.r_day) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else b.r_day end) as next_r_day
						from (select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 a.external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									 isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									 cast(isnull(a.[остаток од],0) as float) as principal_rest,
									 a.prev_od as last_principal_rest,
									 isnull(a.bucket_coll,'(1)_0') as dpd_bucket,									
									 'som-old'  as seg1,
									 ''         as seg2,
									 'LYSD'     as seg3
							  --from [RiskDWH].[dbo].[stg_coll_bal_cmr] a
							  from #CMR a
							--отчетная дата - 1 год, первый день месяца
							  where r_day = 1
								and r_year  = year(dateadd(yy,-1, @rdt ))
								and r_month = month(dateadd(yy,-1, @rdt ))

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 a.external_id,
									isnull(a.dpd_coll,0) as overdue_days,
									isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									cast(isnull(a.[остаток од],0) as float) as principal_rest,
									a.prev_od as last_principal_rest,
									isnull(a.bucket_coll,'(1)_0') as dpd_bucket,	
									 'new-old' as seg1,
									 ''        as seg2,
									 'LYSD'    as seg3
							  from #CMR a
							--остальные дни месяца (меньше, чем день отчетной даты), кроме первого числа от (отчетная дата - 1 год) с переходами по бакетам
							  where ((r_day > 1 and dpd_p_coll in (1,31,61,91,361))
								or ((prev_dpd_p_coll between 1 and 30) and (prev_dpd_coll = 0) and  r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 31 and 60) and r_day <> 1)
								--переходы из [91-360] и [361+] в низшие бакеты
								or (prev_dpd_p_coll between 91 and 360 and prev_dpd_coll <= 90 and r_day <> 1)
								or (prev_dpd_p_coll >= 361 and prev_dpd_coll <= 360 and r_day <> 1)
								
								)
								and r_year  = year(dateadd(yy,-1, @rdt ))
								and r_month = month(dateadd(yy,-1, @rdt ))
								and r_day < day( @rdt )
								 ) a
					      
							  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b
							  left join #CMR b
								on a.external_id = b.external_id
								and a.r_year      = b.r_year
								and a.r_month     = b.r_month
								and b.r_day       = day( @rdt )  ) a;

				exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T3';


			drop table if exists #t_cm
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
						into #t_cm
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
									 else isnull(b.bucket_coll,'(1)_0') end) as next_dpd_bucket,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.overdue_days) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else isnull(b.dpd_coll,0) end) as next_overdue_days,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.r_day) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else b.r_day end) as next_r_day
						from (select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									cast(isnull(a.[остаток од],0) as float) as principal_rest,
									a.prev_od as last_principal_rest,
									isnull(a.bucket_coll,'(1)_0') as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'CM'       as seg3
							  --from [RiskDWH].[dbo].[stg_coll_bal_cmr] a
							  from #CMR a
							--первый день месяца отчетной даты
							  where r_day = 1
								and r_year  = year( @rdt )
								and r_month = month( @rdt )

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 a.external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									cast(isnull(a.[остаток од],0) as float) as principal_rest,
									a.prev_od as last_principal_rest,
									isnull(a.bucket_coll,'(1)_0') as dpd_bucket,	
									 'new-old' as seg1,
									 ''        as seg2,
									 'CM'      as seg3
							  from  #CMR a
							--остальные дни месяца, кроме первого числа в месяце отчетной даты
							  where ((r_day > 1 and dpd_p_coll in (1,31,61,91,361))
								or ((prev_dpd_p_coll between 1 and 30) and (prev_dpd_coll = 0) and  r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 31 and 60) and r_day <> 1)
								--переходы из [91-360] и [361+] в низшие бакеты
								or (prev_dpd_p_coll between 91 and 360 and prev_dpd_coll <= 90 and r_day <> 1)
								or (prev_dpd_p_coll >= 361 and prev_dpd_coll <= 360 and r_day <> 1)								
								)
								and r_year  = year( @rdt )
								and r_month = month( @rdt )
									 ) a
							  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
							  left join #CMR b
							  on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day( @rdt ) ) a;

				exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T4';
                    

								drop table if exists #t_lmsd
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
						into #t_lmsd
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
									 else isnull(b.bucket_coll,'(1)_0') end) as next_dpd_bucket,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.overdue_days) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else isnull(b.dpd_coll,0) end) as next_overdue_days,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.r_day) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else b.r_day end) as next_r_day
						from (select r_year,
									 r_month,
									 r_day,
									 a.d as r_date,
									 external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									cast(isnull(a.[остаток од],0) as float) as principal_rest,
									a.prev_od as last_principal_rest,
									isnull(a.bucket_coll,'(1)_0') as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'LMSD'     as seg3
							  --from [RiskDWH].[dbo].[stg_coll_bal_cmr] a
							  from #CMR a
							  where r_day = 1
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 a.external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									cast(isnull(a.[остаток од],0) as float) as principal_rest,
									a.prev_od as last_principal_rest,
									isnull(a.bucket_coll,'(1)_0') as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'LMSD'    as seg3
							  from  #CMR a
							  where ((r_day > 1
								and dpd_p_coll in (1,31,61,91,361))
								or ((prev_dpd_p_coll between 1 and 30) and (prev_dpd_coll = 0) and  r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 31 and 60) and r_day <> 1)
								--переходы из [91-360] и [361+] в низшие бакеты
								or (prev_dpd_p_coll between 91 and 360 and prev_dpd_coll <= 90 and r_day <> 1)
								or (prev_dpd_p_coll >= 361 and prev_dpd_coll <= 360 and r_day <> 1)
								)
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))
								and r_day < day( @rdt )
								) a
							  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
							  left join #CMR b
							  on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day( @rdt )) a;
                      


				exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#T5';


								drop table if exists #t_lm;
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
						into #t_lm
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
									 else isnull(b.bucket_coll,'(1)_0') end) as next_dpd_bucket,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.overdue_days) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else isnull(b.dpd_coll,0) end) as next_overdue_days,
							   (case when count(a.external_id) over (partition by a.external_id, a.r_year, a.r_month) <> 1
									  and row_number() over (partition by a.external_id, a.r_year, a.r_month order by a.r_date desc) <> 1
									 then lead(a.r_day) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date)
									 else b.r_day end) as next_r_day
						from (select r_year,
									 r_month,
									 r_day,
									 a.d as r_date,
									 external_id,
									isnull(a.dpd_coll,0) as overdue_days,
									isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									cast(isnull(a.[остаток од],0) as float) as principal_rest,
									a.prev_od as last_principal_rest,
									isnull(a.bucket_coll,'(1)_0') as dpd_bucket,
									 'som-old'  as seg1,
									 ''         as seg2,
									 'LM'       as seg3
							  --from [RiskDWH].[dbo].[stg_coll_bal_cmr] a
							  from #CMR a
							  where r_day = 1
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))

							  union

							  select a.r_year,
									 a.r_month,
									 a.r_day,
									 a.d as r_date,
									 a.external_id,
									 isnull(a.dpd_coll,0) as overdue_days,
									isnull(a.dpd_p_coll,0) as overdue_days_p, 									 
									cast(isnull(a.[остаток од],0) as float) as principal_rest,
									a.prev_od as last_principal_rest,
									isnull(a.bucket_coll,'(1)_0') as dpd_bucket,
									 'new-old' as seg1,
									 ''        as seg2,
									 'LM'    as seg3
							  from #CMR a
							  where ((r_day > 1 and dpd_p_coll in (1,31,61,91,361))
								or ((prev_dpd_p_coll between 1 and 30) and (prev_dpd_coll = 0) and  r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 31 and 60) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll = 0) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 1 and 30) and r_day <> 1)
								or ((prev_dpd_p_coll between 61 and 90) and (prev_dpd_coll between 31 and 60) and r_day <> 1)
								--переходы из [91-360] и [361+] в низшие бакеты
								or (prev_dpd_p_coll between 91 and 360 and prev_dpd_coll <= 90 and r_day <> 1)
								or (prev_dpd_p_coll >= 361 and prev_dpd_coll <= 360 and r_day <> 1)
								)
								and r_year  = year(dateadd(mm,-1, @rdt ))
								and r_month = month(dateadd(mm,-1, @rdt ))
								 ) a
							  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
							  left join #CMR b
							  on a.external_id = b.external_id
											  and a.r_year      = b.r_year
											  and a.r_month     = b.r_month
											  and b.r_day       = day(eomonth(a.r_date))) a;
                    

-----------------------	--------------------------------------------------------------------------------------------


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#all_pre';


	drop table if exists #all_pre;
	select a.external_id, a.r_date, 
	min(t.d) alt_r_end_date
	into #all_pre
	from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_all) a
	--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
	left join #CMR t
	on a.r_date<=t.d 
	and t.d<=eomonth(a.r_date) 
	and a.external_id=t.external_id
	where		((isnull(t.dpd_p_coll,0) > a.overdue_days and
	((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
	or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
	or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
	or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
	or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
	or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
	--переходы из [91-360] и [361+] в низшие бакеты
	or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
	or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
	))
											or
	(isnull(t.dpd_coll,0) < a.overdue_days and 
	((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
	or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
	or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
	or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
	or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
	or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
	or (isnull(t.dpd_coll,0) = 0 and isnull(t.dpd_p_coll,0)=0)
	--переходы из [91-360] и [361+] в низшие бакеты
	or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
	or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
	)))
				and t.d < (case when l_r_date is not null then l_r_date else eomonth(t.d) end)
	group by a.external_id, a.r_date

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#all';


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
							   else (case when @rdt <= eomonth(a.r_date)
									 then @rdt
									 else eomonth(a.r_date) end) end) end) r_end_date
	into #all 
	 from #t_all a
		left join #all_pre p on a.r_date=p.r_date and a.external_id=p.external_id;

			  

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lysd_pre';


		  drop table if exists #lysd_pre;
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #lysd_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lysd) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d<=eomonth(a.r_date) 
			and a.external_id=t.external_id
		  where		((isnull(t.dpd_p_coll,0) > a.overdue_days and 
		  ((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		  --переходы из [91-360] и [361+] в низшие бакеты
			or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
			or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		  ))
													or
		(isnull(t.dpd_coll,0) < a.overdue_days and 
		((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		or (isnull(t.dpd_coll,0) = 0 and isnull(t.dpd_p_coll,0)=0)
		--переходы из [91-360] и [361+] в низшие бакеты
		or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
		or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		)))
						and t.d < (case when l_r_date is not null then l_r_date else dateadd(yy,-1, @rdt ) end)
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
								   and a.dpd_bucket = '(5)_91_360'
								  then dateadd(dd,360 - a.overdue_days,a.r_date)
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
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #lysd_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lysd) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d<=eomonth(a.r_date) 
			and a.external_id=t.external_id
		  where	  -- isnull(t.dpd_p_coll,0) in (1,31,61,91,361)
		   (
		  (isnull(t.dpd_p_coll,0) = 1 and a.overdue_days = 0
		  or isnull(t.dpd_p_coll,0) = 31 and a.overdue_days between 1 and 30
		  or isnull(t.dpd_p_coll,0) = 61 and a.overdue_days between 31 and 60
		  or isnull(t.dpd_p_coll,0) = 91 and a.overdue_days between 61 and 90
		  or isnull(t.dpd_p_coll,0) = 361 and a.overdue_days between 91 and 360)
		or 		 
		 (   isnull(t.dpd_coll,0) = 1		and isnull(t.dpd_last_coll,0) = 0
		  or isnull(t.dpd_coll,0) = 31		and isnull(t.dpd_last_coll,0) between 1 and 30
		  or isnull(t.dpd_coll,0) = 61		and isnull(t.dpd_last_coll,0) between 31 and 60
		  or isnull(t.dpd_coll,0) = 91		and isnull(t.dpd_last_coll,0) between 61 and 90
		  or isnull(t.dpd_coll,0) = 361		and isnull(t.dpd_last_coll,0) between 91 and 360)
		  )		  
		  and t.d <= (case when l_r_date is not null then l_r_date else dateadd(yy,-1, @rdt ) end)
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
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #lmsd_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lmsd) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d <= eomonth(a.r_date) 
			and a.external_id=t.external_id
		  where		((isnull(t.dpd_p_coll,0) > a.overdue_days and 
		  ((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		  --переходы из [91-360] и [361+] в низшие бакеты
			or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
			or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		  ))
													or
		  (isnull(t.dpd_coll,0) < a.overdue_days and 
		  ((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		  or (isnull(t.dpd_coll,0) = 0 and isnull(t.dpd_p_coll,0)=0)
		  --переходы из [91-360] и [361+] в низшие бакеты
			or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
			or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		  )))
						and t.d < (case when l_r_date is not null then l_r_date else dateadd(mm,-1, @rdt ) end)
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
								   and a.dpd_bucket = '(5)_91_360'
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
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #lmsd_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lmsd) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d<=eomonth(a.r_date) 
			and a.external_id=t.external_id
		  where	  -- isnull(t.dpd_p_coll,0) in (1,31,61,91,361)
		   (
		  (isnull(t.dpd_p_coll,0) = 1 and a.overdue_days = 0
		  or isnull(t.dpd_p_coll,0) = 31 and a.overdue_days between 1 and 30
		  or isnull(t.dpd_p_coll,0) = 61 and a.overdue_days between 31 and 60
		  or isnull(t.dpd_p_coll,0) = 91 and a.overdue_days between 61 and 90
		  or isnull(t.dpd_p_coll,0) = 361 and a.overdue_days between 91 and 360)
		or 		 
		 (isnull(t.dpd_coll,0) = 1		and isnull(t.dpd_last_coll,0) = 0
		  or isnull(t.dpd_coll,0) = 31	and isnull(t.dpd_last_coll,0) between 1 and 30
		  or isnull(t.dpd_coll,0) = 61	and isnull(t.dpd_last_coll,0) between 31 and 60
		  or isnull(t.dpd_coll,0) = 91	and isnull(t.dpd_last_coll,0) between 61 and 90
		  or isnull(t.dpd_coll,0) = 361	and isnull(t.dpd_last_coll,0) between 91 and 360)
		  )	
		  and t.d <= (case when l_r_date is not null then l_r_date else dateadd(mm,-1, @rdt ) end)
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
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #cm_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_cm) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d<=eomonth(a.r_date) 
			and a.external_id=t.external_id
		  -- where t.overdue_days < a.overdue_days and not ((t.overdue_days_p-t.overdue_days)%29 > 0 and (t.overdue_days_p-t.overdue_days)%30 > 0 and (t.overdue_days_p-t.overdue_days)%31 > 0  and t.overdue_days<>0 and 
		  where		((isnull(t.dpd_p_coll,0) > a.overdue_days and 
		  ((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		  --переходы из [91-360] и [361+] в низшие бакеты
			or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
			or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		  ))
													or
		(isnull(t.dpd_coll,0) < a.overdue_days and 
		((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		or (isnull(t.dpd_coll,0) = 0 and isnull(t.dpd_p_coll,0)=0)
		--переходы из [91-360] и [361+] в низшие бакеты
		or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
		or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		)))
						and t.d < (case when l_r_date is not null then l_r_date else eomonth(t.d) end)
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
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #cm_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_cm) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d<=eomonth(a.r_date) 
			and a.external_id=t.external_id
		  where	  -- t.overdue_days_p in (1,31,61,91,361)
		   (
		  (isnull(t.dpd_p_coll,0) = 1 and a.overdue_days = 0
		  or isnull(t.dpd_p_coll,0) = 31 and a.overdue_days between 1 and 30
		  or isnull(t.dpd_p_coll,0) = 61 and a.overdue_days between 31 and 60
		  or isnull(t.dpd_p_coll,0) = 91 and a.overdue_days between 61 and 90
		  or isnull(t.dpd_p_coll,0) = 361 and a.overdue_days between 91 and 360)
		or 		 
		 (isnull(t.dpd_coll,0) = 1		and isnull(t.dpd_last_coll,0) = 0
		  or isnull(t.dpd_coll,0) = 31	and isnull(t.dpd_last_coll,0) between 1 and 30
		  or isnull(t.dpd_coll,0) = 61	and isnull(t.dpd_last_coll,0) between 31 and 60
		  or isnull(t.dpd_coll,0) = 91	and isnull(t.dpd_last_coll,0) between 61 and 90
		  or isnull(t.dpd_coll,0) = 361	and isnull(t.dpd_last_coll,0) between 91 and 360)
		  )	
		  and t.d <= (case when l_r_date is not null then l_r_date else eomonth(t.d) end)
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
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #lm_pre
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lm) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d<=eomonth(a.r_date) 
			and a.external_id=t.external_id
		  where		((isnull(t.dpd_p_coll,0) > a.overdue_days and 
		  ((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		  --переходы из [91-360] и [361+] в низшие бакеты
			or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
			or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		  ))
													or
		  (isnull(t.dpd_coll,0) < a.overdue_days and 
		  ((isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0)  between 1 and 30)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0)  between 31 and 60))  
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 31 and 60))
		  or (isnull(t.dpd_coll,0) = 0 and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 1 and 30) and (isnull(t.dpd_p_coll,0) between 61 and 90)) 
		  or ((isnull(t.dpd_coll,0) between 31 and 60) and (isnull(t.dpd_p_coll,0) between 61 and 90))
		  or (isnull(t.dpd_coll,0) = 0 and isnull(t.dpd_p_coll,0)=0)
		  --переходы из [91-360] и [361+] в низшие бакеты
			or (isnull(t.dpd_p_coll,0) between 91 and 360 and isnull(t.dpd_coll,0) <= 90)
			or (isnull(t.dpd_p_coll,0) >= 361 and isnull(t.dpd_coll,0) <= 360)
		  )))
						and t.d < (case when l_r_date is not null then l_r_date else eomonth(t.d) end)
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
		  select a.external_id, a.r_date, min(t.d) alt_r_end_date
		  into #lm_pre_w
		  from (select *,  LEAD(r_date) over (partition by external_id, r_month, r_year order by r_day) l_r_date from #t_lm) a
			--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] t 
			left join #CMR t
			on a.r_date<=t.d 
			and t.d<=eomonth(a.r_date) 
			and a.external_id=t.external_id
		  where	   --isnull(t.dpd_p_coll,0) in (1,31,61,91,361)
		   (
		  (isnull(t.dpd_p_coll,0) = 1 and a.overdue_days = 0
		  or isnull(t.dpd_p_coll,0) = 31 and a.overdue_days between 1 and 30
		  or isnull(t.dpd_p_coll,0) = 61 and a.overdue_days between 31 and 60
		  or isnull(t.dpd_p_coll,0) = 91 and a.overdue_days between 61 and 90
		  or isnull(t.dpd_p_coll,0) = 361 and a.overdue_days between 91 and 360)
		or 		 
		 (isnull(t.dpd_coll,0) = 1		and isnull(t.dpd_last_coll,0) = 0
		  or isnull(t.dpd_coll,0) = 31	and isnull(t.dpd_last_coll,0) between 1 and 30
		  or isnull(t.dpd_coll,0) = 61	and isnull(t.dpd_last_coll,0) between 31 and 60
		  or isnull(t.dpd_coll,0) = 91	and isnull(t.dpd_last_coll,0) between 61 and 90
		  or isnull(t.dpd_coll,0) = 361	and isnull(t.dpd_last_coll,0) between 91 and 360)
		  )	
		  and t.d <= (case when l_r_date is not null then l_r_date else eomonth(t.d) end)
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
								  else (eomonth(a.r_date) ) end) end) as r_end_date
		  into #lm_w
		  from #t_lm a
				left join #lm_pre_w p on a.r_date=p.r_date and a.external_id=p.external_id;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#all_new';

		 drop table if exists #all_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case /*  when (case when a.r_date = r_end_date then b.overdue_days_p
								else isnull(a.overdue_days,0) end)   in (1,31,61) then a.principal_rest  */
					  when (a.r_date = r_end_date
					  and ((isnull(b.dpd_p_coll,0) between 1 and 30 and isnull(b.dpd_coll,0) = 0) 
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0)  between 31 and 60)
							--переходы из [91-360] и [361+] в низшие бакеты
							or (isnull(b.dpd_p_coll,0) between 91 and 360 and isnull(b.dpd_coll,0) <= 90)
							or (isnull(b.dpd_p_coll,0) >= 361 and isnull(b.dpd_coll,0) <= 360)
							)) 
							
							then a.last_principal_rest
							
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then b.dpd_p_coll
					else isnull(a.overdue_days,0) end as overdue_days,
				 isnull(b.dpd_coll,0) as overdue_days_end,
				 /*case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.overdue_days_p
					  else isnull(b.overdue_days,0) end as overdue_days_end,
				 case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.dpd_bucket_p
					  else isnull(b.dpd_bucket,'(1)_0') end as dpd_bucket_end,*/
				case when a.r_date = r_end_date then isnull(b.bucket_p_coll,'(1)_0')
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #all_new
		  from #all      a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
		  left join #CMR b
		  on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.d;

	--20/11/20
	delete from #all_new 
	where not(dpd_bucket <> dpd_bucket_end or r_end_date = eomonth(r_date) or r_end_date = @rdt )
	;


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
					  and ((isnull(b.dpd_p_coll,0) between 1 and 30 and isnull(b.dpd_coll,0) = 0) 
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0)  between 31 and 60)
							--переходы из [91-360] и [361+] в низшие бакеты
							or (isnull(b.dpd_p_coll,0) between 91 and 360 and isnull(b.dpd_coll,0) <= 90)
							or (isnull(b.dpd_p_coll,0) >= 361 and isnull(b.dpd_coll,0) <= 360)
							)) 
							
							then a.last_principal_rest
							
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then isnull(b.dpd_p_coll,0)
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then isnull(b.bucket_p_coll,'(1)_0')
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.dpd_coll,0) as overdue_days_end,			
				isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lysd_new
		  from #lysd      a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b
		  left join #CMR b
					on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.d;

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
				 case when a.r_date = a.r_end_date --and a.r_day = 1
				 then isnull(c.dpd_last_coll,0)
				 else 
				 a.overdue_days end overdue_days,

				 case when a.r_date = a.r_end_date --and a.r_day = 1
				 then isnull(c.bucket_last_coll,'(1)_0')
				 else 
				 a.dpd_bucket end as dpd_bucket,

				 isnull(b.dpd_p_coll,0) as overdue_days_end,
				 isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lysd_new_w
		  from #lysd_w     a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b
		  left join #CMR b
		  on a.external_id  = b.external_id
		  and a.r_year        = b.r_year
		  and a.r_month       = b.r_month
		  and a.r_end_date    = b.d
		  --left join RiskDWH.dbo.stg_coll_bal_cmr c
		  left join #CMR c
		  on a.external_id = c.external_id
		  and a.r_date = c.d
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
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_360')
								or (dpd_bucket = '(5)_91_360' and dpd_bucket_end = '(6)_361+') ) ) u


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lmsd_new';			
				drop table if exists #lmsd_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case  when (a.r_date = r_end_date
					  and ((isnull(b.dpd_p_coll,0) between 1 and 30 and isnull(b.dpd_coll,0) = 0) 
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0)  between 31 and 60)
							--переходы из [91-360] и [361+] в низшие бакеты
							or (isnull(b.dpd_p_coll,0) between 91 and 360 and isnull(b.dpd_coll,0) <= 90)
							or (isnull(b.dpd_p_coll,0) >= 361 and isnull(b.dpd_coll,0) <= 360)
							)) 
							
							then a.last_principal_rest
							
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then isnull(b.dpd_p_coll,0)
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then isnull(b.bucket_p_coll,'(1)_0')
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.dpd_coll,0) as overdue_days_end,			
				isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lmsd_new
		  from #lmsd      a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
		  left join #CMR b
		  on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.d;

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
				 then isnull(c.dpd_last_coll ,0)
				 else 
				 a.overdue_days end overdue_days,

				 case when a.r_date = a.r_end_date
				 then isnull(c.bucket_last_coll , '(1)_0')
				 else 
				 a.dpd_bucket end as dpd_bucket,

				 isnull(b.dpd_p_coll,0) as overdue_days_end,
				 isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lmsd_new_w
		  from #lmsd_w     a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
		  left join #CMR b
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.d
		  --left join RiskDWH.dbo.stg_coll_bal_cmr c
		  left join #CMR c
		  on a.external_id = c.external_id 
		  and a.r_date = c.d
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
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_360')
								or (dpd_bucket = '(5)_91_360' and dpd_bucket_end = '(6)_361+') ) ) u

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
					  and ((isnull(b.dpd_p_coll,0) between 1 and 30 and isnull(b.dpd_coll,0) = 0) 
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0)  between 31 and 60)
							--переходы из [91-360] и [361+] в низшие бакеты
							or (isnull(b.dpd_p_coll,0) between 91 and 360 and isnull(b.dpd_coll,0) <= 90)
							or (isnull(b.dpd_p_coll,0) >= 361 and isnull(b.dpd_coll,0) <= 360)
							)) 
							
							then a.last_principal_rest
							
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then isnull(b.dpd_p_coll,0)
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then isnull(b.bucket_p_coll,'(1)_0')
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.dpd_coll,0) as overdue_days_end,
				 /*case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.overdue_days_p
					  else isnull(b.overdue_days,0) end as overdue_days_end,
				 case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.dpd_bucket_p
					  else isnull(b.dpd_bucket,'(1)_0') end as dpd_bucket_end,*/
			
				isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #cm_new
		  from #cm      a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
		  left join #CMR b
		  on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.d;

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
				 then isnull(c.dpd_last_coll ,0)
				 else 
				 a.overdue_days end overdue_days,

				 case when a.r_date = a.r_end_date
				 then isnull(c.bucket_last_coll,'(1)_0')
				 else 
				 a.dpd_bucket end as dpd_bucket,

				 isnull(b.dpd_p_coll,0) as overdue_days_end,
				 isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #cm_new_w
		  from #cm_w     a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
		  left join #CMR b
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.d
		  --left join RiskDWH.dbo.stg_coll_bal_cmr c
		  left join #CMR c
		  on a.external_id = c.external_id 
		  and a.r_date = c.d
		  ;
				
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
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_360')
								or (dpd_bucket = '(5)_91_360' and dpd_bucket_end = '(6)_361+') ) ) u

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#lm_new';			


				drop table if exists #lm_new;
		  select a.r_year,
				 a.r_month,
				 a.r_day,
				 a.r_date,
				 a.r_end_date,
				 a.external_id,
				 case  when (a.r_date = r_end_date
					  and ((isnull(b.dpd_p_coll,0) between 1 and 30 and isnull(b.dpd_coll,0) = 0) 
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 31 and 60 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) = 0)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0) between 1 and 30)
							or (isnull(b.dpd_p_coll,0) between 61 and 90 and isnull(b.dpd_coll,0)  between 31 and 60)
							--переходы из [91-360] и [361+] в низшие бакеты
							or (isnull(b.dpd_p_coll,0) between 91 and 360 and isnull(b.dpd_coll,0) <= 90)
							or (isnull(b.dpd_p_coll,0) >= 361 and isnull(b.dpd_coll,0) <= 360)
							)) 
							
							then a.last_principal_rest
							
							else a.principal_rest
						end principal_rest, 
					-- a.principal_rest,
				 case when a.r_date = r_end_date then isnull(b.dpd_p_coll,0)
					else isnull(a.overdue_days,0) end as overdue_days,
			
				 case when a.r_date = r_end_date then isnull(b.bucket_p_coll,'(1)_0')
					else isnull(a.dpd_bucket,'(1)_0') end as dpd_bucket,
				  isnull(b.dpd_p_coll,0) as overdue_days_end,			
				isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lm_new
		  from #lm      a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
		  left join #CMR b
		  on a.external_id  = b.external_id
						 and a.r_year        = b.r_year
						 and a.r_month       = b.r_month
						 and a.r_end_date    = b.d;

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
				 then isnull(c.dpd_last_coll,0)
				 else 
				 a.overdue_days end overdue_days,

				 case when a.r_date = a.r_end_date
				 then isnull(c.bucket_last_coll,'(1)_0')
				 else 
				 a.dpd_bucket end as dpd_bucket,

				 isnull(b.dpd_p_coll,0) as overdue_days_end,
				 isnull(b.bucket_coll,'(1)_0') as dpd_bucket_end,
				 a.seg3,
				 (case when b.bucket_coll is null then 'Improve' else a.seg_rr end) as seg_rr
		  into #lm_new_w
		  from #lm_w     a
		  --left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
		  left join #CMR b
		  on a.external_id  = b.external_id
			and a.r_year        = b.r_year
			and a.r_month       = b.r_month
			and a.r_end_date    = b.d
		  --left join  RiskDWH.dbo.stg_coll_bal_cmr c
		  left join #CMR c
		  on a.external_id = c.external_id 
		  and a.r_date = c.d
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
								or (dpd_bucket = '(4)_61_90' and dpd_bucket_end = '(5)_91_360')
								or (dpd_bucket = '(5)_91_360' and dpd_bucket_end = '(6)_361+') ) ) u


------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_product';
---------обновленный справочник продуктов 01.11.2024--------------
	drop table if exists #stg_product;
	/*select a.Код as external_id, 
	case when a.IsInstallment = 1 then 'INSTALLMENT' else 'PTS' end as product
	into #stg_product
	from stg._1cCMR.Справочник_Договоры a*/
	select a.Код as external_id, 
	case when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) like ('%installment%') then 'Installment'
	when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) like ('%pdl%') then 'Pdl'
	else 'PTS' end product
	into #stg_product
	from stg._1cCMR.Справочник_Договоры a
	LEFT JOIN Stg._1cCMR.Справочник_Заявка cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
	LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка;
	;

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
		   sum(b.pay_total) as pay_total,
		   coalesce(c.product,'PTS') as product

	into #t00
	from (select * from #lysd_new_full
		  union
		  select * from #lmsd_new_full
		  union
		  select * from #cm_new_full
		  union
		  select * from #lm_new_full) a
	--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b 
	left join #CMR b
	on a.external_id = b.external_id 
	and b.d >= a.r_date 
	and b.d <= a.r_end_date
	left join #stg_product c --2022-02-09
	on a.external_id = c.external_id

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
			 coalesce(c.product,'PTS')
			 ;



		 		 
			 exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#t000';

	drop table if exists #t000;
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
		   c.dpd_bucket_start,
		   a.seg3,
		   a.seg_rr,
		   sum(b.pay_total) as pay_total,
		   --sum(isnull(b.total_wo,0))  as total_wo,
		   cast(0 as float) as total_wo,
		   row_number() over (partition by a.external_id, a.r_year, a.r_month order by r_end_date) rn_t000,
		   coalesce(d.product,'PTS') as product

	into #t000
	from #all_new a

	--left join [RiskDWH].[dbo].[stg_coll_bal_cmr] b
	left join #CMR b
	on a.external_id = b.external_id 
	and b.d >= a.r_date 
	and b.d <= a.r_end_date

	--22/05/2020: поле dpd_bucket_start, Пт 22.05.2020 11:08 from Тимофеев Никита Сергеевич
	left join (select aa.external_id, isnull(aa.bucket_p_coll,'(1)_0') as dpd_bucket_start, aa.r_year, aa.r_month
	--from RiskDWH.dbo.stg_coll_bal_cmr_base aa
	from #CMR aa
	where aa.d = CONVERT(DATE, CONVERT(VARCHAR(7), @rdt, 120) + '-01' , 120)  
	) c
	on a.external_id = c.external_id
	and a.r_year = c.r_year
	and a.r_month = c.r_month

	left join #stg_product d --2022-02-09
	on a.external_id = d.external_id

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
			 c.dpd_bucket_start,
			 a.seg3,
			 a.seg_rr,
			 coalesce(d.product,'PTS')
			 ;
			 


	/***** 28/10/2020 - учет каникул c октября 2020 *****/
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'CredVacations';
	   
	with a as (select * from #t000)
	update a set 
	a.overdue_days_end = a.overdue_days,
	a.dpd_bucket_end = a.dpd_bucket,
	a.seg_rr = 'Same'
	where 1=1
	--and a.r_date between '2020-10-01' and '2020-10-31'
	and a.overdue_days_end < a.overdue_days
	and exists (select 1 from RiskDWH.dbo.det_kk_cmr_and_space b
		where a.external_id = b.external_id
		and eomonth(a.r_date) = eomonth(dateadd(dd,1,b.dt_from))
		and a.r_date between b.dt_from and b.dt_to
		);


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#galina';


	drop table if exists #galina;
	select a.r_year,
		   a.r_month,
		   a.r_day,
		   a.dpd_bucket_start,
		   a.dpd_bucket,
		   a.dpd_bucket_end,
		   r_end_day,
		   a.total_balance,
		   a.pay_total,
		   sum(isnull(b.principal_rest,0)) as improve_balance,
		   case when a.dpd_bucket     = '(2)_1_30'
				 and a.dpd_bucket_end = '(1)_0'
					then  'Improve 1-30 -> 0'
				 when a.dpd_bucket     = '(3)_31_60' 
				 and a.dpd_bucket_end = '(1)_0'
					then  'Improve 31-60 -> 0'
				when a.dpd_bucket     = '(3)_31_60' 
				 and a.dpd_bucket_end = '(2)_1_30'
					then 'Improve 31-60 -> 1-30' 
				when a.dpd_bucket     = '(4)_61_90' 
				 and a.dpd_bucket_end = '(1)_0'
					then  'Improve 61-90 -> 0' 
				when a.dpd_bucket     = '(4)_61_90'
				 and a.dpd_bucket_end = '(2)_1_30'
					then 'Improve 61-90 -> 1-30' 
				when a.dpd_bucket     = '(4)_61_90'
				 and a.dpd_bucket_end = '(3)_31_60' 
					then 'Improve 61-90 -> 31-60'
					else 'other'
			end [migration bucket],
			week_num,
			a.product
	into #galina
	from (select a.r_year,
				 a.r_month,
				 a.r_day,
				 datepart(week,a.r_end_date) week_num,
				 day(a.r_end_date) as r_end_day,
				 a.dpd_bucket,
				 a.dpd_bucket_end,
				 a.dpd_bucket_start,
				 sum(a.principal_rest)    as total_balance,
				 sum(a.pay_total)         as pay_total,
				 a.product

		  from #t000      a
		  group by a.r_year,
				   a.r_month,
				   a.r_day,
				   day(a.r_end_date),
				   a.dpd_bucket,
				   a.dpd_bucket_end,
				   a.dpd_bucket_start,
				   datepart(week,a.r_end_date),
				   a.product
				   ) a
	left join #t000              b on a.r_year  =  year(b.r_end_date)
								  and a.r_month = month(b.r_end_date)
								  and a.r_day   =   day(b.r_end_date)
								  and a.dpd_bucket     = b.dpd_bucket
								  and a.dpd_bucket_end = b.dpd_bucket_end
								  and b.seg_rr  = 'Improve'
								  and a.product = b.product
	group by a.r_year,
			 a.r_month,
			 a.r_day,
			 r_end_day,
			 a.dpd_bucket_start,
			 a.dpd_bucket,
			 a.dpd_bucket_end,
			 a.total_balance,
			 a.pay_total,
			 week_num,
			 a.product;




	--drop table if exists #final_run_rates;

	-- select * from #t00_new
	drop table if exists #t00_new;
	  		select * 
		into #t00_new
	 from #t00
	where --external_id = '18112002880002'
	--and
	not (
		(dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'
					and seg3 = 'LYSD' and r_end_date <> dateadd(yy,-1, @rdt ))
		or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'
					and seg3 = 'LMSD' and r_end_date <> dateadd(mm,-1, @rdt ))
		or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'
					and seg3 = 'LM' and r_end_date <> EOMONTH(@rdt,-1))
		or (dpd_bucket = '(1)_0' and dpd_bucket_end = '(1)_0'
					and seg3 = 'CM' and r_end_date <> @rdt)		
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



	--28/10/2020 - учет каникул с октября
	with a as (select * from #t00_new)
	update a set 
	a.overdue_days_end = a.overdue_days,
	a.dpd_bucket_end = a.dpd_bucket,
	a.seg_rr = 'Same'
	where exists (select 1 from RiskDWH.dbo.det_kk_cmr_and_space b
	where a.external_id = b.external_id
	and eomonth(a.r_date) = eomonth(dateadd(dd,1,b.dt_from))
	and a.r_date between b.dt_from and b.dt_to
	)
	--and a.r_date between '2020-10-01' and '2020-10-31'
	and a.overdue_days > a.overdue_days_end;




	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#final_roll_rates';


	drop table if exists #final_roll_rates;
	select seg3,
			 sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(1)_0'
					then principal_rest else 0 end) [Improve 1-30 -> 0 abs],
			 sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(1)_0'
					then principal_rest else 0 end) [Improve 31-60 -> 0 abs] ,
			 sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) [Improve 31-60 -> 1-30 abs],
			 sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(1)_0'
					then principal_rest else 0 end) [Improve 61-90 -> 0 abs],
			 sum(case when dpd_bucket     = '(4)_61_90'
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) [Improve 61-90 -> 1-30 abs],
			 sum(case when dpd_bucket     = '(4)_61_90'
					 and dpd_bucket_end = '(3)_31_60' 
					then principal_rest else 0 end) [Improve 61-90 -> 31-60 abs],
			 sum(case when dpd_bucket     = '(5)_91_360'
					 -- and seg_rr = 'Improve' then principal_rest else 0 end) [Improve 91_360 abs],
					 and  (dpd_bucket_end =  '(1)_0' or dpd_bucket_end = '(2)_1_30' or dpd_bucket_end = '(3)_31_60' or dpd_bucket_end = '(4)_61_90') then principal_rest else 0 end) [Improve 91_360 abs],
			 sum(case when dpd_bucket     = '(6)_361+'
					 -- and seg_rr = 'Improve' then principal_rest else 0 end) [Improve 361+ abs],
					 and  (dpd_bucket_end =  '(1)_0' or dpd_bucket_end = '(2)_1_30' or dpd_bucket_end = '(3)_31_60' or dpd_bucket_end = '(4)_61_90' or dpd_bucket_end = '(5)_91_360') then principal_rest else 0 end) [Improve 361+ abs],
				 
					 sum(case when dpd_bucket     = '(1)_0'
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) [Worse 0 -> 1-30 abs],

					 sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(3)_31_60'
					then principal_rest else 0 end) [Worse 1-30 -> 31-60 abs],
					 sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(4)_61_90'
					then principal_rest else 0 end) [Worse 31-60 -> 61-90 abs],
					sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(5)_91_360'
					then principal_rest else 0 end) [Worse 61-90 -> 91-360 abs],
					sum(case when dpd_bucket     = '(5)_91_360'
					 and dpd_bucket_end = '(6)_361+'
					then principal_rest else 0 end) [Worse 91-360 abs],
					0 as [Worse 361+ abs],
		 

case when sum(case when dpd_bucket = '(2)_1_30' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(1)_0'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(2)_1_30'
					then principal_rest else 0 end) end as [Improve 1-30 -> 0], 
case when sum(case when dpd_bucket = '(3)_31_60' then principal_rest else 0 end) = 0 then 0 else
		   sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(1)_0'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(3)_31_60' 
					then principal_rest else 0 end) end as [Improve 31-60 -> 0], 
case when sum(case when dpd_bucket = '(3)_31_60' then principal_rest else 0 end) = 0 then 0 else
		   sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(3)_31_60' 
					then principal_rest else 0 end) end as [Improve 31-60 -> 1-30], 

case when sum(case when dpd_bucket = '(4)_61_90' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(1)_0'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(4)_61_90' 
					then principal_rest else 0 end)  end as [Improve 61-90 -> 0], 

case when sum(case when dpd_bucket = '(4)_61_90' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(4)_61_90'
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(4)_61_90'
					then principal_rest else 0 end) end as [Improve 61-90 -> 1-30],
					
case when sum(case when dpd_bucket = '(4)_61_90' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(4)_61_90'
					 and dpd_bucket_end = '(3)_31_60' 
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(4)_61_90'
					then principal_rest else 0 end) end as [Improve 61-90 -> 31-60],

case when sum(case when dpd_bucket = '(5)_91_360' then principal_rest else 0 end) = 0  then  0 else 
		   sum(case when dpd_bucket     = '(5)_91_360'
					 -- and seg_rr = 'Improve' then principal_rest else 0 end) /
					 and  (dpd_bucket_end =  '(1)_0' or dpd_bucket_end = '(2)_1_30' or dpd_bucket_end = '(3)_31_60' or dpd_bucket_end = '(4)_61_90') then principal_rest else 0 end) /
		   sum(case when dpd_bucket     = '(5)_91_360'
					then principal_rest else 0 end) end as [Improve 91-360],

case when sum(case when dpd_bucket = '(6)_361+' then principal_rest else 0 end) = 0 then 0 else
		   sum(case when dpd_bucket     = '(6)_361+'
					 -- and seg_rr = 'Improve' then principal_rest else 0 end) / 
					 and  (dpd_bucket_end =  '(1)_0' or dpd_bucket_end = '(2)_1_30' or dpd_bucket_end = '(3)_31_60' or dpd_bucket_end = '(4)_61_90' or dpd_bucket_end = '(5)_91_360') then principal_rest else 0 end) /
		   sum(case when dpd_bucket     = '(6)_361+'
					then principal_rest else 0 end) end as [Improve 361+],
       
case when sum(case when dpd_bucket = '(1)_0' then principal_rest else 0 end) = 0 then 0 else
		   sum(case when dpd_bucket     = '(1)_0'
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) / 
		   sum(case when -- (dpd_bucket     = '(1)_0' and dpd_bucket_end = '(2)_1_30') or (dpd_bucket = '(1)_0' and dpd_bucket_end= '(1)_0' )
								dpd_bucket     = '(1)_0'
						 /*(and r_end_date = dateadd(dd,-1,CONVERT(date, SYSDATETIME()))
							or  r_end_date = dateadd(yy,-1,dateadd(dd,-1,cast(getdate() as date)))
							or  r_end_date = eomonth(CONVERT(date, SYSDATETIME()),-1)
							or  r_end_date = dateadd(mm,-1,dateadd(dd,-1,cast(getdate() as date)))))*/
					then principal_rest else 0 end) end as [Worse 0 -> 1-30],
	   
		   -- select * from #t00 where seg3 = 'CM' and dpd_bucket     = '(4)_61_90'

case when sum(case when dpd_bucket = '(2)_1_30' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(3)_31_60'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(2)_1_30'
					then principal_rest else 0 end) end as [Worse 1-30 -> 31-60], 
case when sum(case when dpd_bucket = '(3)_31_60' then principal_rest else 0 end) = 0 then 0 else
		   sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(4)_61_90'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(3)_31_60' 
					then principal_rest else 0 end) end as [Worse 31-60 -> 61-90], 
case when sum(case when dpd_bucket = '(4)_61_90' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(5)_91_360'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(4)_61_90' 
					then principal_rest else 0 end) end as [Worse 61-90 -> 91-360], 
case when sum(case when dpd_bucket = '(5)_91_360' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(5)_91_360'
					 and dpd_bucket_end = '(6)_361+'
					then principal_rest else 0 end) / 
		   sum(case when dpd_bucket     = '(5)_91_360'
					then principal_rest else 0 end) end as [Worse 91-360],
		   0                                        as [Worse 361+],


		   sum(case when dpd_bucket     = '(1)_0'
					 and dpd_bucket_end = '(1)_0' 
					  /*and  (r_end_date = dateadd(dd,-1,CONVERT(date, SYSDATETIME()))
							or  r_end_date = dateadd(yy,-1,dateadd(dd,-1,cast(getdate() as date)))
							or  r_end_date = eomonth(CONVERT(date, SYSDATETIME()),-1)
							or  r_end_date = dateadd(mm,-1,dateadd(dd,-1,cast(getdate() as date))))*/
					then principal_rest else 0 end) as [Same 0 abs],

		   sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) as [Same 1-30 abs],
				sum(case when dpd_bucket     = '(3)_31_60'
					 and dpd_bucket_end = '(3)_31_60'
					then principal_rest else 0 end) as [Same 31-60 abs],
				sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(4)_61_90' 
					then principal_rest else 0 end) as [Same 61-90 abs],
				sum(case when dpd_bucket     = '(5)_91_360'
					 and dpd_bucket_end = '(5)_91_360'
					then principal_rest else 0 end) as [Same 91-360 abs],

case when sum(case when dpd_bucket = '(1)_0' then principal_rest else 0 end) = 0 then 0 else 
				sum(case when dpd_bucket     = '(1)_0'
					 and dpd_bucket_end = '(1)_0' /*and  (r_end_date = dateadd(dd,-1,CONVERT(date, SYSDATETIME()))
							or  r_end_date = dateadd(yy,-1,dateadd(dd,-1,cast(getdate() as date)))
							or  r_end_date = eomonth(CONVERT(date, SYSDATETIME()),-1)
							or  r_end_date = dateadd(mm,-1,dateadd(dd,-1,cast(getdate() as date))))*/
					then principal_rest else 0 end) / 
				  sum(case when dpd_bucket     = '(1)_0'
							/*and (r_end_date = dateadd(dd,-1,CONVERT(date, SYSDATETIME()))
							or  r_end_date = dateadd(yy,-1,dateadd(dd,-1,cast(getdate() as date)))
							or  r_end_date = eomonth(CONVERT(date, SYSDATETIME()),-1)
							or  r_end_date = dateadd(mm,-1,dateadd(dd,-1,cast(getdate() as date)))))*/
					then principal_rest else 0 end) end as [Same 0 -> 1-30],
		
case when sum(case when dpd_bucket = '(2)_1_30' then principal_rest else 0 end) = 0 then 0 else 
		   sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(2)_1_30'
					then principal_rest else 0 end) /
				sum(case when dpd_bucket     = '(2)_1_30'
					 then principal_rest else 0 end) end as [Same 1-30],
case when sum(case when dpd_bucket = '(3)_31_60' then principal_rest else 0 end) = 0 then 0 else 
				sum(case when dpd_bucket     = '(3)_31_60'
					 and dpd_bucket_end = '(3)_31_60'
					then principal_rest else 0 end) /
					sum(case when dpd_bucket     = '(3)_31_60'
						 then principal_rest else 0 end) end as [Same 31-60],
case when sum(case when dpd_bucket = '(4)_61_90' then principal_rest else 0 end) = 0 then 0 else 
				sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(4)_61_90' 
					then principal_rest else 0 end) /
					sum(case when dpd_bucket     = '(4)_61_90' 
						 then principal_rest else 0 end) end as [Same 61-90],
case when sum(case when dpd_bucket = '(5)_91_360' then principal_rest else 0 end) = 0 then 0 else 
				sum(case when dpd_bucket     = '(5)_91_360'
					 and dpd_bucket_end = '(5)_91_360'
					then principal_rest else 0 end) /
					sum(case when dpd_bucket     = '(5)_91_360' 
						 then principal_rest else 0 end) end as [Same 91-360],

	--20/11/2020 datsyplakov: добавлены штуки - mail 18 нояб. 2020 г., 13:42 from Елена Яшина <yashina_e_b@carmoney.ru>

	 sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(1)_0' and principal_rest > 0
					then 1 else 0 end) [Improve 1-30 -> 0 pcs],
			 sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(1)_0' and principal_rest > 0
					then 1 else 0 end) [Improve 31-60 -> 0 pcs] ,
			 sum(case when dpd_bucket     = '(3)_31_60' 
					 and dpd_bucket_end = '(2)_1_30' and principal_rest > 0
					then 1 else 0 end) [Improve 31-60 -> 1-30 pcs],
			 sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(1)_0' and principal_rest > 0
					then 1 else 0 end) [Improve 61-90 -> 0 pcs],
			 sum(case when dpd_bucket     = '(4)_61_90'
					 and dpd_bucket_end = '(2)_1_30' and principal_rest > 0
					then 1 else 0 end) [Improve 61-90 -> 1-30 pcs],
			 sum(case when dpd_bucket     = '(4)_61_90'
					 and dpd_bucket_end = '(3)_31_60'  and principal_rest > 0
					then 1 else 0 end) [Improve 61-90 -> 31-60 pcs],
			 sum(case when dpd_bucket     = '(5)_91_360' and principal_rest > 0
					 and dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90') then 1 else 0 end) [Improve 91_360 pcs],
			 sum(case when dpd_bucket     = '(6)_361+' and principal_rest > 0
					 and dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_360') then 1 else 0 end) [Improve 361+ pcs],
				 
			sum(case when dpd_bucket     = '(1)_0'
			and dpd_bucket_end = '(2)_1_30' and principal_rest > 0
			then 1 else 0 end) [Worse 0 -> 1-30 pcs],

			sum(case when dpd_bucket     = '(2)_1_30'
			and dpd_bucket_end = '(3)_31_60' and principal_rest > 0
			then 1 else 0 end) [Worse 1-30 -> 31-60 pcs],
			sum(case when dpd_bucket     = '(3)_31_60' 
			and dpd_bucket_end = '(4)_61_90' and principal_rest > 0
			then 1 else 0 end) [Worse 31-60 -> 61-90 pcs],
			sum(case when dpd_bucket     = '(4)_61_90' 
			and dpd_bucket_end = '(5)_91_360' and principal_rest > 0
			then 1 else 0 end) [Worse 61-90 -> 91-360 pcs],
			sum(case when dpd_bucket     = '(5)_91_360'
			and dpd_bucket_end = '(6)_361+' and principal_rest > 0
			then 1 else 0 end) [Worse 91-360 pcs],
			0 as [Worse 361+ pcs],

			sum(case when dpd_bucket     = '(1)_0'
					 and dpd_bucket_end = '(1)_0' and principal_rest > 0 					 
					then 1 else 0 end) as [Same 0 pcs],
		   sum(case when dpd_bucket     = '(2)_1_30'
					 and dpd_bucket_end = '(2)_1_30' and principal_rest > 0
					then 1 else 0 end) as [Same 1-30 pcs],
				sum(case when dpd_bucket     = '(3)_31_60'
					 and dpd_bucket_end = '(3)_31_60' and principal_rest > 0
					then 1 else 0 end) as [Same 31-60 pcs],
				sum(case when dpd_bucket     = '(4)_61_90' 
					 and dpd_bucket_end = '(4)_61_90'  and principal_rest > 0
					then 1 else 0 end) as [Same 61-90 pcs],
				sum(case when dpd_bucket     = '(5)_91_360'
					 and dpd_bucket_end = '(5)_91_360' and principal_rest > 0
					then 1 else 0 end) as [Same 91-360 pcs],

				product

	into #final_roll_rates

	from #t00_new 
	group by seg3, product
	;




	--28/06/2021 - движение по бакетам - для BI


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_buck_moves';


	drop table if exists #stg_buck_moves;

	with base as (
		select 
		a.product,
		a.seg3, 
		a.dpd_bucket, 
		a.dpd_bucket_end, 
		case when cast(SUBSTRING(a.dpd_bucket,2,1) as int) > cast(SUBSTRING(a.dpd_bucket_end,2,1) as int) then 'IMPROVE'
		when cast(SUBSTRING(a.dpd_bucket,2,1) as int) < cast(SUBSTRING(a.dpd_bucket_end,2,1) as int) then 'WORSE'
		else 'SAME' end as migr_type,
		sum(a.principal_rest) as principal_rest,
		count(*) as cnt
		from #t00_new a
		where a.principal_rest > 0
		group by a.product, a.seg3, a.dpd_bucket, a.dpd_bucket_end, 
			case when cast(SUBSTRING(a.dpd_bucket,2,1) as int) > cast(SUBSTRING(a.dpd_bucket_end,2,1) as int) then 'IMPROVE'
			when cast(SUBSTRING(a.dpd_bucket,2,1) as int) < cast(SUBSTRING(a.dpd_bucket_end,2,1) as int) then 'WORSE'
			else 'SAME' end
	), znam as (
		select a.product, a.seg3, a.dpd_bucket, sum(a.principal_rest) as principal_rest from #t00_new a
		group by a.product, a.seg3, a.dpd_bucket
	)
	select 
	b.seg3, 
	b.dpd_bucket, 
	iif(b.dpd_bucket in ('(5)_91_360','(6)_361+') and b.migr_type = 'IMPROVE', '' ,b.dpd_bucket_end) as dpd_bucket_end,
	b.migr_type,
	sum(b.principal_rest) as principal_rest,
	sum(b.cnt) as cnt,
	sum(b.principal_rest) / z.principal_rest as principal_ratio,
	b.product

	into #stg_buck_moves
	from base b
	left join znam z
	on b.seg3 = z.seg3
	and b.dpd_bucket = z.dpd_bucket
	and b.product = z.product
	group by b.product, b.seg3, b.dpd_bucket, iif(b.dpd_bucket in ('(5)_91_360','(6)_361+') and b.migr_type = 'IMPROVE', '' ,b.dpd_bucket_end), b.migr_type, z.principal_rest

	;



	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_predel_soft';

	drop table if exists #stg_predel_soft;
	select a.seg3, a.r_end_date, day(a.r_end_date) as r_day,
	sum(a.principal_rest) as principal_rest,
	count(*) as cnt_credit,
	a.product
	into #stg_predel_soft
	from #t00_new a
	where a.dpd_bucket = '(1)_0'
	and a.dpd_bucket_end = '(2)_1_30'
	and a.seg3 in ('CM', 'LM')
	and a.principal_rest > 0 
	group by a.product, a.seg3, a.r_end_date;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#credits_with_saved_balance';


	drop table if exists #credits_with_saved_balance;
	select distinct t.external_id, r_date, r_day, r_month, r_year, r_end_date, day(r_end_date) r_end_day, dpd_bucket, dpd_bucket_end, principal_rest, pay_total,
	t.product
	--, principal_rest, last_name, first_name, middle_name
	into #credits_with_saved_balance
	from #t000 t 
	--#galina t
	--left join (select distinct * from [dbo].[dm_Maindata]) m on t.external_id=m.external_id
	where principal_rest>0
	--and ((last_name = 'ЧЕРНИКОВ' and first_name = 'АНТОН' and middle_name = 'ВЛАДИМИРОВИЧ') or last_name = 'СМЫСЛОВ')
	and r_year = year(@rdt)
	and r_month = month(@rdt)



--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------




	/*REPORTS*/
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'REP';
	
	
	--Факт Predel -> Soft
	begin transaction;

		delete from risk.dm_ReportCollectionPlanPredelSoft --RiskDWH.dbo.rep_coll_plan_predel_soft
		where rep_dt = @rdt;

		insert into risk.dm_ReportCollectionPlanPredelSoft --RiskDWH.dbo.rep_coll_plan_predel_soft

		select a.seg3, a.r_end_date, a.r_day, a.principal_rest, a.cnt_credit,
		@rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.product
		from #stg_predel_soft a;

	commit transaction;

	--Отчет по движению по бакетам
	begin transaction

	delete from  risk.dm_ReportCollectionRollRates --- RiskDWH.dbo.rep_coll_roll_rates 
	where rep_dt = @rdt

	insert into risk.dm_ReportCollectionRollRates --RiskDWH.dbo.rep_coll_roll_rates
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from #final_roll_rates a

	commit transaction;


	---28/06/2021
	--Отчет по движению по бакетам для PowerBI


	

	begin transaction

	--DWH-1594
	/*
	delete from Risk.dm_ReportCollectionBucketMigrations
	where rep_dt = @rdt;
	*/
	
	/*
	--18.02.2022
	;with migr as (
		select a.dpd_bucket, a.dpd_bucket_end, a.migr_type
		from (values
		('(1)_0','(1)_0','SAME'),
		('(1)_0','(2)_1_30','WORSE'),
		('(2)_1_30','(1)_0','IMPROVE'),
		('(2)_1_30','(2)_1_30','SAME'),
		('(2)_1_30','(3)_31_60','WORSE'),
		('(3)_31_60','(1)_0','IMPROVE'),
		('(3)_31_60','(2)_1_30','IMPROVE'),
		('(3)_31_60','(3)_31_60','SAME'),
		('(3)_31_60','(4)_61_90','WORSE'),
		('(4)_61_90','(1)_0','IMPROVE'),
		('(4)_61_90','(2)_1_30','IMPROVE'),
		('(4)_61_90','(3)_31_60','IMPROVE'),
		('(4)_61_90','(4)_61_90','SAME'),
		('(4)_61_90','(5)_91_360','WORSE'),
		('(5)_91_360','','IMPROVE'),
		('(5)_91_360','(5)_91_360','SAME'),
		('(5)_91_360','(6)_361+','WORSE'),
		('(6)_361+','','IMPROVE')
		) a (dpd_bucket, dpd_bucket_end,migr_type)
	), product as (
		select cast('PTS' as varchar(1000)) as product
		union all
		select cast('INSTALLMENT' as varchar(1000)) as product
	), segment as (
		select cast('LYSD' as varchar(100)) as seg3
		union all
		select cast('LMSD' as varchar(100)) as seg3
		union all
		select cast('LM' as varchar(100)) as seg3
		union all
		select cast('CM' as varchar(100)) as seg3
	), base as (
		select p.product, s.seg3, m.dpd_bucket, m.dpd_bucket_end, m.migr_type 
		from product as p, segment as s, migr as m
	), fact as (
		select a.seg3, a.dpd_bucket, a.dpd_bucket_end, a.migr_type, 
		isnull(b.principal_rest,0) as principal_rest,
		isnull(b.cnt,0) as cnt,
		isnull(b.principal_ratio,0) as principal_ratio,
		a.product
		from base a
		left join #stg_buck_moves b
		on a.product = b.product
		and a.seg3 = b.seg3
		and a.dpd_bucket = b.dpd_bucket
		and a.dpd_bucket_end = b.dpd_bucket_end
	)

	insert into Risk.dm_ReportCollectionBucketMigrations


	select 
	@rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml,
	a.seg3, a.dpd_bucket, a.dpd_bucket_end, a.migr_type,
	a.principal_rest, a.cnt, a.principal_ratio,
	a.product,

	a.principal_ratio - b.principal_ratio as delta_ratio,
	a.principal_rest - b.principal_rest as delta_rest,
	a.cnt - b.cnt as delta_cnt
	
	from fact a
	left join fact b
	on a.product = b.product
	and a.dpd_bucket = b.dpd_bucket
	and a.dpd_bucket_end = b.dpd_bucket_end
	and a.seg3 = 'CM'
	and b.seg3 = 'LMSD'
	;
	*/
	   	  
	commit transaction;



	--Отчет по выполнению мотивационных планов и по сборам, лист "galina"
	begin transaction

	delete from risk.dm_ReportCollectionPlanRollBalance --RiskDWH.dbo.rep_coll_plan_galina 
	where rep_dt = @rdt

	insert into risk.dm_ReportCollectionPlanRollBalance --RiskDWH.dbo.rep_coll_plan_galina
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from #galina a

	commit transaction;


	--Отчет по выполнению мотивационных планов и по сборам, лист "credits" - saved balance, столбцы B:L
	begin transaction 

	delete from risk.dm_ReportCollectionPlanCMRCred --RiskDWH.dbo.rep_coll_plan_cmr_cred
	where rep_dt = @rdt

	insert into  risk.dm_ReportCollectionPlanCMRCred -- RiskDWH.dbo.rep_coll_plan_cmr_cred
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from #credits_with_saved_balance a

	commit transaction;


	--22/05/2020 разбивка сохраненного баланса по бакетам
	begin transaction

	delete from  risk.dm_ReportCollectionPlanDetBucket -- RiskDWH.dbo.rep_coll_plan_det_bucket
	where rep_dt = @rdt

	insert into risk.dm_ReportCollectionPlanDetBucket  --RiskDWH.dbo.rep_coll_plan_det_bucket
	select  @rdt as rep_dt, cast(SYSDATETIME() as datetime) as dt_dml,
	a.dpd_bucket+'#'+a.dpd_bucket_end+'#'+a.dpd_bucket_start as metric,
	a.dpd_bucket, a.dpd_bucket_end, a.dpd_bucket_start, 
	sum(a.total_balance) as total_balance,
	a.product
	from risk.dm_ReportCollectionPlanRollBalance a --RiskDWH.dbo.rep_coll_plan_galina a
	where a.rep_dt = @rdt
	and a.r_year = year(@rdt)
	and a.r_month = month(@rdt)
	group by a.dpd_bucket, a.dpd_bucket_end, a.dpd_bucket_start, a.product

	commit transaction;


	/**********************************************************************************/

	--22/05/2020 прогноз (среднее в динамике с апреля)
	--20/07/2020 ПРОГНОЗ v2
	--суммарный сохр. баланс за каждый день месяца
	drop table if exists #fact_bal_by_day;

	select 
	a.product,
	a.dpd_bucket, 
	a.dpd_bucket_end,
	a.r_end_day,
	sum(a.total_balance) as total_bal
	
	into #fact_bal_by_day
	
	from Risk.dm_ReportCollectionPlanRollBalance a
	inner join RiskDWH.dbo.det_coll_forecast_basis b
	on 1=1
	and EOMONTH(a.rep_dt) = b.fcst_month
	and a.dpd_bucket = b.dpd_bucket
	and a.dpd_bucket_end = b.dpd_bucket_end
	and a.r_year = b.r_year
	and a.r_month = b.r_month

	where a.rep_dt = @rdt
	
	group by a.dpd_bucket, a.dpd_bucket_end, a.r_end_day, a.product
	order by 1,2;

	--накопленный сохр. баланс за каждый день месяца
	drop table if exists #fact_bal_acc;

	select a.product, a.dpd_bucket, a.dpd_bucket_end,
	a.r_end_day, a.total_bal,
	sum(a.total_bal) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end
							order by a.r_end_day
							rows between unbounded preceding and current row
							) as total_bal_acc,
	sum(a.total_bal) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end) as total_bal_sum,
	max(a.r_end_day) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end) as mx_end_day,
	
	case when sum(a.total_bal) over (partition by product, dpd_bucket, dpd_bucket_end) = 0 then 0 else 
	(sum(a.total_bal) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end
							order by a.r_end_day
							rows between unbounded preceding and current row)) / 
	(sum(a.total_bal) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end)) end fcst_rate
	
	/*
	(sum(a.total_bal) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end
							order by a.r_end_day
							rows between unbounded preceding and current row)) / 
	(sum(a.total_bal) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end)) as fcst_rate*/

	into #fact_bal_acc
	from #fact_bal_by_day a
	order by 1,2,3;


	--устраняем пропуски 
	drop table if exists #fact_bal_wo_gaps;

	with conbylvl as (
		select 1 as num
		union all
		select num + 1 
		from conbylvl 
		where num < 31
	),
	--дополняем недостающие дни по бакетам для факта
	base as (
		select  
		aa.product, aa.dpd_bucket, aa.dpd_bucket_end, l.num, aa.mx_end_day
		from (
			select distinct 
			a.product, a.dpd_bucket, a.dpd_bucket_end, a.mx_end_day
			from #fact_bal_acc a
		) aa
		cross join conbylvl l
	--on aa.mx_end_day >= l.num
	)

	select bs.product, bs.dpd_bucket, bs.dpd_bucket_end,
	bs.num as r_end_day,
	isnull(max(f.fcst_rate) over (partition by bs.product, bs.dpd_bucket, bs.dpd_bucket_end 
						   order by bs.num
						   rows between unbounded preceding and current row), 0) as fsct_rate,
	@days_in_month as fcst_month_days,
	bs.mx_end_day

	into #fact_bal_wo_gaps

	from base bs
	left join #fact_bal_acc f
	on bs.dpd_bucket = f.dpd_bucket
	and bs.dpd_bucket_end = f.dpd_bucket_end
	and bs.num = f.r_end_day
	and bs.product = f.product

	order by 1,2,3,4;

	--Финальный прогноз

	drop table if exists #final_forecast;

	select a.product, a.dpd_bucket, a.dpd_bucket_end, a.r_end_day,
	a.fcst_month_days, a.mx_end_day, a.fsct_rate,

	--если в прогнозируемом месяце на k дней больше, берем среднее k предыдущих дней
	case when a.mx_end_day < a.fcst_month_days then 
		case a.fcst_month_days - a.mx_end_day
			when 1 then 
			avg(a.fsct_rate) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end 
								   order by a.r_end_day 
								   rows between 1 preceding and current row) 
			when 2 then 
			avg(a.fsct_rate) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end 
								   order by a.r_end_day 
								   rows between 2 preceding and current row) 
			when 3 then 
			avg(a.fsct_rate) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end 
								   order by a.r_end_day 
								   rows between 3 preceding and current row) 
			else @month_days/DAY(@rdt)---1 заменил минус 1 
		end
	--если в прогнозируемом месяце на k дней меньше, берем среднее k следующих дней
	  when a.mx_end_day > a.fcst_month_days and a.r_end_day = a.fcst_month_days then 
		1
	  when a.mx_end_day > a.fcst_month_days and a.r_end_day < a.fcst_month_days then 
		case a.mx_end_day - a.fcst_month_days
			when 1 then 
			avg(a.fsct_rate) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end 
								   order by a.r_end_day 
								   rows between current row and 1 following) 
			when 2 then 
			avg(a.fsct_rate) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end 
								   order by a.r_end_day 
								   rows between current row and 2 following) 
			when 3 then 
			avg(a.fsct_rate) over (partition by a.product, a.dpd_bucket, a.dpd_bucket_end 
								   order by a.r_end_day 
								   rows between current row and 3 following) 
			else @month_days/DAY(@rdt) ---2  заменил минус 2 
		end
	--если в прогнозируемом месяце столько же дней
	  when a.mx_end_day = a.fcst_month_days then
	   a.fsct_rate
	  else -3
	end as fsct_rate_final
	into #final_forecast
	from #fact_bal_wo_gaps a
	--where a.fcst_month_days >= a.r_end_day
	order by 1,2,3


	--2022-02-09 installment - до накполения статистики используем данные по ПТС
	if @rdt <= cast('2022-05-31' as date)
	
	begin


		delete from #final_forecast where product = 'INSTALLMENT'

		insert into #final_forecast 
		select cast('INSTALLMENT' as varchar(100)) as product, a.dpd_bucket, a.dpd_bucket_end, a.r_end_day,
		a.fcst_month_days, a.mx_end_day, a.fsct_rate, a.fsct_rate_final
		from #final_forecast a 
		where product = 'PTS' 


	end



	begin transaction
		--обновляем прогнозные коэффициенты в таблице-справочнике
		delete from RiskDWH.dbo.det_coll_forecast
		where date_on = @rdt

		insert into RiskDWH.dbo.det_coll_forecast
		select @rdt as date_on, cast(SYSDATETIME() as datetime) as dt_dml,
		DATEFROMPARTS( year(@rdt), month(@rdt), ff.r_end_day) as rep_dt,
		ff.dpd_bucket, ff.dpd_bucket_end, ff.r_end_day, ff.fsct_rate_final, ff.product
		from #final_forecast ff
		where ff.r_end_day <= ff.fcst_month_days
		order by 3,4,2

	commit transaction;



	begin transaction

	delete from risk.dm_ReportCollectionPlanForecast  -- RiskDWH.dbo.rep_coll_plan_forecast
	where rep_dt = @rdt

	insert into risk.dm_ReportCollectionPlanForecast  -- RiskDWH.dbo.rep_coll_plan_forecast

	select fct.dpd_bucket+'#'+fct.dpd_bucket_end as metric,
	fct.dpd_bucket, fct.dpd_bucket_end, 
	case when d.fsct_rate_final = 0 then null else fct.total_balance/d.fsct_rate_final end as total_balance_fcst, 
	@rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, fct.product

	from (
		--фактический баланс за месяц отчетной даты
			select a.product, a.dpd_bucket, a.dpd_bucket_end, sum(a.total_balance) as total_balance 
			from risk.dm_ReportCollectionPlanRollBalance a --RiskDWH.dbo.rep_coll_plan_galina a
			where a.rep_dt = @rdt
				and a.r_year = year(@rdt)
				and a.r_month = month(@rdt)
			group by a.product, a.dpd_bucket, a.dpd_bucket_end
		) fct
		--доля сбора к отчетной дате на основе прошедших месяцев
	left join RiskDWH.dbo.det_coll_forecast d
	on fct.dpd_bucket = d.dpd_bucket
	and fct.dpd_bucket_end = d.dpd_bucket_end
	and d.date_on = @rdt
	and d.rep_dt = @rdt
	and d.product = fct.product

	commit transaction;

	/*********************************************************************************/
	--Прогноз для Predel -> Soft

	drop table if exists #fact_predel_wo_gaps;

	with conbylvl as (
		select 1 as num
		union all
		select num + 1 
		from conbylvl 
		where num < 31
		),
	base as (
		select 
		a.product,
		a.seg3, 
		a.r_end_date, 
		a.r_day,

		case when sum(a.principal_rest) over (partition by a.product) = 0 then 0
		else 
		sum(a.principal_rest) over 
		(partition by a.product order by a.r_end_date rows between unbounded preceding and current row) /
		sum(a.principal_rest) over (partition by a.product) end as fcst_rate
		from #stg_predel_soft a
		where a.seg3 = 'LM'
	)

	select c.num as r_end_day, 
	isnull(max(b.fcst_rate) over (partition by b.product order by c.num rows between unbounded preceding and current row), 0) as fcst_rate,
	@days_in_month as fcst_month_days,
	dd.mx_end_day,
	b.product

	into #fact_predel_wo_gaps

	from conbylvl c
	left join base b
	on c.num = b.r_day
	left join (
		select d.product, max(r_day) as mx_end_day 
		from #stg_predel_soft d
		where d.seg3 ='LM'
		group by d.product
	) dd
	on 1=1;




	drop table if exists #final_predel_forecast;

	select a.r_end_day,
	a.fcst_month_days, a.mx_end_day, a.fcst_rate,

	--если в прогнозируемом месяце на k дней больше, берем среднее k предыдущих дней
	case when a.mx_end_day < a.fcst_month_days then 
		case a.fcst_month_days - a.mx_end_day
			when 1 then 
			avg(a.fcst_rate) over (partition by a.product order by a.r_end_day 
								   rows between 1 preceding and current row) 
			when 2 then 
			avg(a.fcst_rate) over (partition by a.product order by a.r_end_day 
								   rows between 2 preceding and current row) 
			when 3 then 
			avg(a.fcst_rate) over (partition by a.product order by a.r_end_day 
								   rows between 3 preceding and current row) 
			else -1 
		end
	--если в прогнозируемом месяце на k дней меньше, берем среднее k следующих дней
	  when a.mx_end_day > a.fcst_month_days and a.r_end_day = a.fcst_month_days then 
		1
	  when a.mx_end_day > a.fcst_month_days and a.r_end_day < a.fcst_month_days then 
		case a.mx_end_day - a.fcst_month_days
			when 1 then 
			avg(a.fcst_rate) over (partition by a.product order by a.r_end_day 
								   rows between current row and 1 following) 
			when 2 then 
			avg(a.fcst_rate) over (partition by a.product order by a.r_end_day 
								   rows between current row and 2 following) 
			when 3 then 
			avg(a.fcst_rate) over (partition by a.product order by a.r_end_day 
								   rows between current row and 3 following) 
			else -2
		end
	--если в прогнозируемом месяце столько же дней
	  when a.mx_end_day = a.fcst_month_days then
	   a.fcst_rate
	  else -3
	end as fsct_rate_final,

	a.product

	into #final_predel_forecast
	from #fact_predel_wo_gaps a
	order by 1,2,3;

	--очищаем от лишних дней
	delete from #final_predel_forecast 
	where r_end_day > fcst_month_days;





	begin transaction;

		delete from risk.dm_ReportCollectionPlanForecast -- RiskDWH.dbo.rep_coll_plan_forecast
		where rep_dt = @rdt 
		and metric = '(1)_0#(2)_1_30';

		insert into risk.dm_ReportCollectionPlanForecast  -- RiskDWH.dbo.rep_coll_plan_forecast

		select 
		'(1)_0#(2)_1_30' as metric,
		'(1)_0' as dpd_bucket,
		'(2)_1_30' as dpd_bucket_end,
		aa.principal_rest_acc / b.fsct_rate_final as total_balance_fcst,
		@rdt as rep_dt, 
		cast(sysdatetime() as datetime) as dt_dml,
		aa.product

		from (
			select a.product, a.r_end_date, a.r_day, a.principal_rest, 
			sum(a.principal_rest) over (partition by a.product order by a.r_end_date
			rows between unbounded preceding and current row) as principal_rest_acc
			from #stg_predel_soft a
			where a.seg3 = 'CM'
		) aa
		left join #final_predel_forecast b
		on aa.r_day = b.r_end_day
		and aa.product = b.product

		where aa.r_end_date = @rdt
		;

	commit transaction;




	/**********************************************************************************/

	----Пересчет дневных планов
	--exec RiskDWH.dbo.prc$update_coll_daily_plan;
	exec [Risk].[Create_dm_CollectionUpdateDailyPlan]

		--подневной сохраненный баланс
	begin transaction

		delete from risk.dm_ReportCollectionPlanDaily -- RiskDWH.dbo.rep_coll_plan_daily
		where rep_dt = @rdt;

		with 
		--отчетные даты: все дни текущего месяца до вчера включительно
		cte as (
			select 1 as num
			union all
			select num + 1 
			from cte 
			where num < day( @rdt )
		),
		repdates as (
			select dateadd(dd,-num,cast(getdate() as date)) as rdt from cte
		), 
		--бакеты для отчета
		base as (
			select * from repdates rr
			cross join (
				select N'(2)_1_30' as dpd_bucket, N'(1)_0' as dpd_bucket_end
				union all
				select N'(3)_31_60' as dpd_bucket, N'(1)_0' as dpd_bucket_end
				union all
				select N'(3)_31_60' as dpd_bucket, N'(2)_1_30' as dpd_bucket_end
				union all
				select N'(4)_61_90' as dpd_bucket, N'(1)_0' as dpd_bucket_end
				union all
				select N'(4)_61_90' as dpd_bucket, N'(2)_1_30' as dpd_bucket_end
				union all
				select N'(4)_61_90' as dpd_bucket, N'(3)_31_60' as dpd_bucket_end
				) bkt
			cross join (
				select N'PTS' as product
				union all
				select N'INSTALLMENT' as product
				union all
				select N'Pdl' as product
				) p ---------обновленный справочник продуктов 01.11.2024--------------
				
		),
		--сохраненный баланс
		fact as (
			  select  
				  a.product, cast(concat(a.r_year,'-') + right(concat('0',a.r_month),2) + '-' + right(concat('0',a.r_end_day),2) as date) as r_end_date,  
				  a.dpd_bucket, a.dpd_bucket_end, 
				  sum(a.total_balance) as total_balance
			  from  risk.dm_ReportCollectionPlanRollBalance a --  RiskDWH.dbo.rep_coll_plan_galina a
			  where a.rep_dt = @rdt
				  and a.r_year = year( @rdt )
				  and a.r_month = month( @rdt )
				  --and a.r_end_day = 6
				  and (a.dpd_bucket = '(2)_1_30' and a.dpd_bucket_end = '(1)_0'
				  or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(1)_0'
				  or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(2)_1_30'
				  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(1)_0'
				  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(2)_1_30'
				  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(3)_31_60')
			  group by a.product, a.r_year, a.r_month, a.r_end_day, a.dpd_bucket, a.dpd_bucket_end
		  ),
		--приведенный баланс
		factadj as (
			  select f.product, f.r_end_date, f.dpd_bucket, f.dpd_bucket_end, 
				  f.total_balance,
				  f.total_balance*(isnull(c.k1,1)-isnull(c.k2,0))/isnull(c.k1,1) as total_balance_adj
			  from fact f
			   --коэффициенты для расчета приведенного баланса
			  left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef c
				  on f.dpd_bucket = c.bucket_from
				  and f.dpd_bucket_end = c.bucket_to
				  and @rdt between c.dt_from and c.dt_to
		  ),
		--план по дням
		dplan as (
		 select bs.rdt, bs.product, bs.dpd_bucket, bs.dpd_bucket_end,
		 sum(pl.total_balance * (isnull(cc.k1,1)-isnull(cc.k2,0))/isnull(cc.k1,1) )
		 over (partition by bs.product, bs.rdt, bs.dpd_bucket) * dcf.coefficient as day_plan,
		 sum(pl.total_balance * (isnull(cc.k1,1)-isnull(cc.k2,0))/isnull(cc.k1,1) )
		 over (partition by bs.product, bs.rdt, bs.dpd_bucket) * dcf.coefficient_adj as day_plan_adj

		  from base bs
		  --план на месяц
		  left join RiskDWH.dbo.det_coll_plan pl
			  on RiskDWH.dbo.date_trunc('mm', bs.rdt) = RiskDWH.dbo.date_trunc('mm', pl.rep_month)
			  and pl.plan_version = (select max(plan_version) from RiskDWH.dbo.det_coll_plan 
									where rep_month =  eomonth(@rdt)
									)
			  and bs.dpd_bucket = pl.bucket_from
			  and bs.dpd_bucket_end = pl.bucket_to
			  and bs.product = pl.product
		  --коэффициенты для расчета дневного плана (доли в месячном плане по дням)
		  left join RiskDWH.dbo.det_coll_daily_plan dcf
			  on bs.rdt = dcf.rep_dt
			  and bs.dpd_bucket = dcf.bucket_from
			  and bs.product = dcf.product
		  --коэффициенты для расчета приведенного баланса
		  left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef cc
			on bs.dpd_bucket = cc.bucket_from
			and bs.dpd_bucket_end = cc.bucket_to
			and @rdt between cc.dt_from and cc.dt_to
		)

		insert into risk.dm_ReportCollectionPlanDaily -- RiskDWH.dbo.rep_coll_plan_daily

		select 
		convert(varchar,dplan.rdt,120)+'#'+dplan.dpd_bucket+'#'+dplan.dpd_bucket_end as metric,
		dplan.rdt, dplan.dpd_bucket, dplan.dpd_bucket_end, 
		isnull(f.total_balance, 0) as total_balance,
		isnull(f.total_balance_adj, 0) as total_balance_adj,
		isnull(dplan.day_plan, 0) as day_plan,
		isnull(dplan.day_plan_adj, 0) as day_plan_adj,

		@rdt as rep_dt,
		cast(sysdatetime() as datetime) as dt_dml,
		dplan.product

		from dplan 
		left join factadj f
			on dplan.rdt = f.r_end_date
			and dplan.dpd_bucket = f.dpd_bucket
			and dplan.dpd_bucket_end = f.dpd_bucket_end
			and dplan.product = f.product
			;

	commit transaction;

	--Predel -> Soft факт по дням

	begin transaction;

		delete from risk.dm_ReportCollectionPlanDaily -- RiskDWH.dbo.rep_coll_plan_daily
		where dpd_bucket = '(1)_0'
		and dpd_bucket_end = '(2)_1_30'
		and rep_dt = @rdt;

		insert into risk.dm_ReportCollectionPlanDaily -- RiskDWH.dbo.rep_coll_plan_daily

		select 
		concat(convert(varchar,a.r_end_date,120),'#(1)_0#(2)_1_30') as metric,
		a.r_end_date as rdt,
		'(1)_0' as dpd_bucket,
		'(2)_1_30' as dpd_bucket_end,
		a.principal_rest as total_balance,
		a.principal_rest as total_balance_adj,
		0 as day_plan,
		0 as day_plan_adj,
		@rdt as rep_dt,
		cast(sysdatetime() as datetime) as dt_dml,
		a.product
		from #stg_predel_soft a
		where a.seg3 = 'CM';

	commit transaction;



	--лист "подн. сохр. баланс" - недельный баланс
	begin transaction

		delete from risk.dm_ReportCollectionPlanWeekly --RiskDWH.dbo.rep_coll_plan_weekly
		where rep_dt = @rdt;

		with 
		--отчетные даты: все дни текущего месяца до вчера включительно
		cte as (
			select 1 as num
			union all
			select num + 1 
			from cte 
			where num < day( @rdt )
		),
		repdates as (
			select distinct datepart(week,dateadd(dd,-num,cast(getdate() as date))) as rdt from cte
		), 
		--бакеты для отчета
		base as (
			select * from repdates rr
			cross join (
				select N'(2)_1_30' as dpd_bucket, N'(1)_0' as dpd_bucket_end
				union all
				select N'(3)_31_60' as dpd_bucket, N'(1)_0' as dpd_bucket_end
				union all
				select N'(3)_31_60' as dpd_bucket, N'(2)_1_30' as dpd_bucket_end
				union all
				select N'(4)_61_90' as dpd_bucket, N'(1)_0' as dpd_bucket_end
				union all
				select N'(4)_61_90' as dpd_bucket, N'(2)_1_30' as dpd_bucket_end
				union all
				select N'(4)_61_90' as dpd_bucket, N'(3)_31_60' as dpd_bucket_end
				) bkt
			cross join (
				select N'PTS' as product 
				union all
				select N'INSTALLMENT' as product
				) p
		),
		--сохраненный баланс
		fact as (
			  select  
				  a.product,
				  cast(concat(a.r_year,'-') + right(concat('0',a.r_month),2) + '-' + right(concat('0',a.r_end_day),2) as date) as r_end_date,  
				  a.dpd_bucket, a.dpd_bucket_end, 
				  sum(a.total_balance) as total_balance
			  from risk.dm_ReportCollectionPlanRollBalance a --RiskDWH.dbo.rep_coll_plan_galina a
			  where a.rep_dt = @rdt
				  and a.r_year = year( @rdt )
				  and a.r_month = month( @rdt )
				  --and a.r_end_day = 6		  
				  and (a.dpd_bucket = '(2)_1_30' and a.dpd_bucket_end = '(1)_0'
				  or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(1)_0'
				  or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(2)_1_30'
				  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(1)_0'
				  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(2)_1_30'
				  or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(3)_31_60')
			  group by a.r_year, a.r_month, a.r_end_day, a.dpd_bucket, a.dpd_bucket_end, a.product
		  ),
		--факт по неделям
		fact_week as (
			select f.product, datepart(week, f.r_end_date) as rep_week, f.dpd_bucket, f.dpd_bucket_end, 
				sum(f.total_balance) as total_balance
			from fact f
			group by f.product, datepart(week, f.r_end_date), f.dpd_bucket, f.dpd_bucket_end
		),
		--приведенный баланс
		factadj as (
			select fw.product, fw.rep_week, fw.dpd_bucket, fw.dpd_bucket_end,  
				fw.total_balance,
				fw.total_balance*(isnull(cc.k1,1)-isnull(cc.k2,0))/isnull(cc.k1,1) as total_balance_adj
			from fact_week fw
			--коэффициенты для расчета приведенного баланса
			left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef cc
				on fw.dpd_bucket = cc.bucket_from
				and fw.dpd_bucket_end = cc.bucket_to
				and @rdt between cc.dt_from and cc.dt_to
		)
		insert into risk.dm_ReportCollectionPlanWeekly -- RiskDWH.dbo.rep_coll_plan_weekly
	
		select 
			convert(varchar,bs.rdt,120)+'#'+bs.dpd_bucket+'#'+bs.dpd_bucket_end as metric,
			bs.rdt, bs.dpd_bucket, bs.dpd_bucket_end, 
			isnull(fa.total_balance, 0) as total_balance, isnull(fa.total_balance_adj, 0) as total_balance_adj,
			@rdt as rep_dt,
			cast(sysdatetime() as datetime) as dt_dml,
			bs.product

		from base bs
		left join factadj fa
			on bs.rdt = fa.rep_week
			and bs.dpd_bucket = fa.dpd_bucket
			and bs.dpd_bucket_end = fa.dpd_bucket_end
			and bs.product = fa.product
			;

	commit transaction;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'drop temp (#) tables';

	drop table #all;
	drop table #all_new;
	drop table #all_pre;
	drop table #cm;
	drop table #cm_new;
	drop table #cm_new_full;
	drop table #cm_new_w;
	drop table #cm_pre;
	drop table #cm_pre_w;
	drop table #cm_w;
	drop table #credits_with_saved_balance;
	drop table #final_roll_rates;
	drop table #galina;
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
	drop table #lysd;
	drop table #lysd_new;
	drop table #lysd_new_full;
	drop table #lysd_new_w;
	drop table #lysd_pre;
	drop table #lysd_pre_w;
	drop table #lysd_w;
	drop table #t_all;
	drop table #t_cm;
	drop table #t_lm;
	drop table #t_lmsd;
	drop table #t_lysd;
	drop table #t00;
	drop table #t00_new;
	drop table #t000;
	drop table #fact_bal_acc;
	drop table #fact_bal_by_day;
	drop table #fact_bal_wo_gaps;
	drop table #final_forecast;
	drop table #fact_predel_wo_gaps;
	drop table #final_predel_forecast;
	drop table #stg_predel_soft;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'FINISH';

	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY CMR - FINISH';

end try

begin catch

if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name ,@info = @errmsg;
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY CMR - ERROR';
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555


end catch

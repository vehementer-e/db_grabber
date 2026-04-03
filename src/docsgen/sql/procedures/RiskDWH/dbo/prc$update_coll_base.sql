


CREATE procedure [dbo].[prc$update_coll_base] 
@dpd_analyt tinyint = 1

as

SET NOCOUNT ON
SET XACT_ABORT ON

declare 
@srcname nvarchar(100);
set @srcname = 'UPDATE_COLL_BAL';

begin try

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = 'START';


	--Статус договора (soft/hard/legal/predelinquent и другие)
	exec RiskDWH.dbo.prc$client_stage;

	--витрина с платежными датами (для исправления DPD)
	--exec RiskDWH.dbo.prc$pmt_days;

	--exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'stg_coll_bal_mfo (FULL)';

	--truncate table RiskDWH.dbo.stg_coll_bal_mfo;

	--	begin transaction;

	--	 insert into RiskDWH.dbo.stg_coll_bal_mfo with (TABLOCK)
	--				select r_year,
	--					  r_month,
	--					  r_day,
	--					  r_date,
	--					  external_id,
	--					  overdue_days,
	--					  overdue_days_p,
	--					  lag_overdue_days as last_dpd,
	--					  lag_principal_rest as last_principal_rest,

	--					  (case when a.overdue_days <= 0   then '(1)_0'
	--							when a.overdue_days <= 30  then '(2)_1_30'
	--							when a.overdue_days <= 60  then '(3)_31_60'
	--							when a.overdue_days <= 90  then '(4)_61_90'
	--							when a.overdue_days <= 360 then '(5)_91_360'
	--							else '(6)_361+' end) as dpd_bucket,
	--					  (case when a.overdue_days_p <= 0   then '(1)_0'
	--							when a.overdue_days_p <= 30  then '(2)_1_30'
	--							when a.overdue_days_p <= 60  then '(3)_31_60'
	--							when a.overdue_days_p <= 90  then '(4)_61_90'
	--							when a.overdue_days_p <= 360 then '(5)_91_360'
	--							else '(6)_361+' end) as dpd_bucket_p,
	--					  (case when lag_overdue_days <= 0   then '(1)_0'
	--							when lag_overdue_days <= 30  then '(2)_1_30'
	--							when lag_overdue_days <= 60  then '(3)_31_60'
	--							when lag_overdue_days <= 90  then '(4)_61_90'
	--							when lag_overdue_days <= 360 then '(5)_91_360'
	--							else '(6)_361+' end) as dpd_bucket_last,
	--					  principal_rest,
	--					  principal_percents_rest,
	--					  pay_total,
	--					  total_wo
	--			   from (select cdate        as r_date,
	--							year(cdate)  as r_year,
	--							month(cdate) as r_month,
	--							day(cdate)   as r_day,
	--							external_id,
	--							isnull(overdue_days,0)                     as overdue_days,
	--							isnull(overdue_days_p,0)                   as overdue_days_p,
	--							cast(isnull(principal_rest,   0) as float) as principal_rest,
	--							cast(isnull(principal_rest,   0) as float) +
	--							cast(isnull(percents_rest,    0) as float) as principal_percents_rest,
	--							cast(isnull(principal_cnl,    0) as float) +
	--							cast(isnull(percents_cnl,     0) as float) +
	--							cast(isnull(fines_cnl,        0) as float) +
	--							cast(isnull(otherpayments_cnl,0) as float) +
	--							cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
	--							cast(isnull(principal_wo,0) as float)           +
	--							cast(isnull(percents_wo,0)  as float)           +
	--							cast(isnull(fines_wo,0)     as float)           +
	--							cast(isnull(otherpayments_wo,0) as float)       as total_wo,

	--							lag(overdue_days) over (partition by external_id order by cdate) as lag_overdue_days,
	--							lag(principal_rest) over (partition by external_id order by cdate) as lag_principal_rest

	--						from dwh_new.dbo.stat_v_balance2
	--					 where cdate >= cast(credit_date as date) 
	--					   and cdate <= dateadd(dd,-1,cast(getdate() as date))
	--					   and cdate >= cast('2018-01-01' as date)
	--					   --19.09.2022 - костыль
	--					   --and not (external_id = '19052308790001' and cdate = '2022-09-15' and agent_pool = '9')
	--					 ) a
	--	;

	--	commit transaction;



	--begin transaction
	--	 update RiskDWH.dbo.stg_coll_bal_mfo set last_principal_rest = 0       where last_dpd is null;
	--	 update RiskDWH.dbo.stg_coll_bal_mfo set dpd_bucket_last     = '(1)_0' where last_dpd is null;
	--	 update RiskDWH.dbo.stg_coll_bal_mfo set last_dpd            = 0       where last_dpd is null;
	--	 update RiskDWH.dbo.stg_coll_bal_mfo set pay_total			 = 0	   where pay_total < 0;
	--	 update RiskDWH.dbo.stg_coll_bal_mfo set principal_rest		 = 0	   where principal_rest < 0;
	--	 update RiskDWH.dbo.stg_coll_bal_mfo set last_principal_rest = 0	   where last_principal_rest < 0;
	--	 update RiskDWH.dbo.stg_coll_bal_mfo set total_wo			 = 0	   where total_wo < 0;
	--commit transaction;


	--exec RiskDWH.dbo.prc$set_debug_info @src = @srcname , @info = '#fix_for_mfo';


	--14/01/21 - fix для МФО - не попадают в таблицу STAT_V_BALANCE из-за CREDIT_ID
	----разобраться с stat_v_balance - balance, credit, credit_history
	--drop table if exists #fix_for_mfo;
	--select * 
	--into #fix_for_mfo
	--from (values
	--('19020515000002', cast('2020-12-16' as date), 2020, 12, 16,  
	--	652, 652, 651, 230000, 
	--	'(6)_361+', '(6)_361+', '(6)_361+', 
	--	209310.46, 212565.3, 218500, 0)
	----,('19011428090001', cast('2020-12-11' as date), 2020, 12, 11,  
	----	0, 666, 665, 80000, 
	----	'(1)_0', '(6)_361+', '(6)_361+', 
	----	0, 21451.36, 240030.17, 0)
	--) a 
	--(external_id, r_date, r_year, r_month, r_day, 
	--overdue_days, overdue_days_p, last_dpd, last_principal_rest,
	--dpd_bucket, dpd_bucket_p, dpd_bucket_last, 
	--principal_rest, principal_percents_rest, pay_total, total_wo)

	--begin transaction;
	
	--	merge into RiskDWH.dbo.stg_coll_bal_mfo dst
	--	using #fix_for_mfo src
	--	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	--	when not matched then 
	--	insert 
	--	  ( r_year					,
	--		r_month					,
	--		r_day					,
	--		r_date					,
	--		external_id				,
	--		overdue_days			,
	--		overdue_days_p			,
	--		last_dpd				,
	--		last_principal_rest		,
	--		dpd_bucket				,
	--		dpd_bucket_p			,
	--		dpd_bucket_last			,
	--		principal_rest			,
	--		principal_percents_rest	,
	--		pay_total				,
	--		total_wo				
	--		)
	--	values (
	--		src.r_year					,
	--		src.r_month					,
	--		src.r_day					,
	--		src.r_date					,
	--		src.external_id				,
	--		src.overdue_days			,
	--		src.overdue_days_p			,
	--		src.last_dpd				,
	--		src.last_principal_rest		,
	--		src.dpd_bucket				,
	--		src.dpd_bucket_p			,
	--		src.dpd_bucket_last			,
	--		src.principal_rest			,
	--		src.principal_percents_rest	,
	--		src.pay_total				,
	--		src.total_wo				
	--	)
	--	;
	--commit transaction;



	--exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FIX for Business Loans';

	
	--begin tran
	--merge into RiskDWH.dbo.stg_coll_bal_mfo dst
	--using RiskDWH.dbo.det_business_loans src
	--on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	--when not matched then insert 
	-- (r_year				   ,      r_month				   ,      r_day					   ,      r_date				   ,
 --     external_id			   ,      overdue_days			   ,      overdue_days_p		   ,      last_dpd				   ,
 --     last_principal_rest	   ,      dpd_bucket			   ,      dpd_bucket_p			   ,      dpd_bucket_last		   ,
 --     principal_rest		   ,      principal_percents_rest  ,      pay_total				   ,      total_wo
	--  ) values
	-- (src.r_year				   ,      src.r_month				   ,      src.r_day					   ,      src.r_date				   ,
 --     src.external_id			   ,      src.overdue_days			   ,      src.overdue_days_p		   ,      src.last_dpd				   ,
 --     src.last_principal_rest	   ,      src.dpd_bucket			   ,      src.dpd_bucket_p			   ,      src.dpd_bucket_last		   ,
 --     src.principal_rest		   ,      src.principal_percents_rest  ,      src.pay_total				   ,      src.total_wo
	--  );
 --  commit tran;


 --  exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FIX cession payments';


 --  begin tran;

 --  with a as (select * from RiskDWH.dbo.stg_coll_bal_mfo)
	--update a set a.pay_total = 0
	--where exists (select 1 from dwh2.risk.REG_CRM_REDZONE b --RiskDWH.dbo.det_cession_aug2021 b
	--				where a.external_id = b.external_id
	--				and b.action_type like '%цесс%'
	--				and a.r_date >= dateadd(dd,-3,b.action_date));
	
	--commit tran;

	-------------------------------------------------------------------------
	-------------------------------------------------------------------------
	-------------------------------------------------------------------------
	-------------------------------------------------------------------------


	--Реестр КК (с 30.09.2020)
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'det_kk_cmr_and_space';

	begin transaction;

	delete from RiskDWH.dbo.det_kk_cmr_and_space;	
	
	with kk_space as (
		select a.Number as external_id, 
		isnull(cast(a.CreditVacationDateBegin as date), cast(b.Период as date)) as dt_from, 
		cast(a.CreditVacationDateEnd	  as date) as dt_to
		from stg._Collection.Deals a
		left join Reports.dbo.DWH_694_credit_vacation_cmr b
		on a.Number = b.Договор
		where 1=1
		and a.CreditVacationDateEnd is not null
	), base as (
		select k.external_id, k.dt_from, k.dt_to
		from kk_space k
		union all
		select c.Договор as external_id, c.Период as dt_from, c.ДатаОкончания as dt_to
		from Reports.dbo.DWH_694_credit_vacation_cmr c
		where not exists (select 1 from kk_space kk
					where c.Договор = kk.external_id)
	) 
	insert into RiskDWH.dbo.det_kk_cmr_and_space
	select b.external_id, b.dt_from, b.dt_to from base b
	where b.dt_from is not null
	

	commit transaction;



	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Drop temp (#) tables';

	--drop table if #fix_for_mfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try

begin catch

if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

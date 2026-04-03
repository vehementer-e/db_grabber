


CREATE procedure [Risk].[Create_dm_ReportUpdateFpdSpdTpd] as 

SET NOCOUNT ON
SET XACT_ABORT ON

SET DATEFIRST 1	  

declare @srcname nvarchar(100);

set @srcname = 'UPDATE_REP_FPD_SPD_TPD';

begin try

	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY FPD - START';

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'START';

	--FPD0
	drop table if exists #stg_fpd0;
	select distinct 
	b.external_id, 
	a.creation_date as dt_from 
	into  #stg_fpd0
	from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,1) a
	left join dwh_new.dbo.tmp_v_credits b
	on a.credit_id= b.id
	--where a.fpd_state = 1;
	where a.creation_date < cast(getdate() as date);


	--FPD30
	drop table if exists #stg_fpd30;
	select distinct 
	b.external_id, 
	a.creation_date as dt_from 
	into  #stg_fpd30
	from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,30) a
	left join dwh_new.dbo.tmp_v_credits b
	on a.credit_id= b.id
	--where a.fpd_state = 1;
	where a.creation_date < cast(getdate() as date);

	--FPD60
	drop table if exists #stg_fpd60;
	select distinct 
	b.external_id, 
	a.creation_date as dt_from 
	into  #stg_fpd60
	from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,60) a
	left join dwh_new.dbo.tmp_v_credits b
	on a.credit_id= b.id
	--where a.fpd_state = 1;
	where a.creation_date < cast(getdate() as date);

	
	
	declare @i date = dateadd(dd,-7,cast(getdate() as date));

	
	while @i <= dateadd(dd,-1,cast(getdate() as date))

		begin

		delete from risk.dm_ReportCollectionFpdSpdTpd --RiskDWH.dbo.rep_fpd_spd_tpd 
		where cdate = @i;

		with base as (
		select a.cdate, 
		a.overdue_days,
		cast(isnull(a.principal_rest, 0) as float) as principal_rest,
		cast(isnull(a.total_rest, 0) as float) as total_rest,
		a.external_id, 
		iif(fpd0.external_id is not null,1,0) as fpd0,
		iif(fpd30.external_id is not null,1,0) as fpd30,
		iif(fpd60.external_id is not null,1,0) as fpd60,

		a.end_date

		from dwh_new.dbo.stat_v_balance2 a
		left join #stg_fpd0 fpd0
		on a.external_id = fpd0.external_id
		and a.cdate >= fpd0.dt_from
		left join #stg_fpd30 fpd30
		on a.external_id = fpd30.external_id
		and a.cdate >= fpd30.dt_from
		left join #stg_fpd60 fpd60
		on a.external_id = fpd60.external_id
		and a.cdate >= fpd60.dt_from

		where a.cdate = @i
		and isnull(cast(a.end_date as date), cast('2999-01-01' as date)) >= @i
		and cast(isnull(a.total_rest,0) as float) >= 100

		)
		insert into risk.dm_ReportCollectionFpdSpdTpd --RiskDWH.dbo.rep_fpd_spd_tpd

		select b.cdate, b.overdue_days,b.principal_rest, b.total_rest, b.external_id, 
		case when b.fpd60 = 1 or b.fpd30 = 1 then 1 else b.fpd0 end as fpd,
		case when b.fpd60 = 1 then 1 else b.fpd30 end as spd,
		b.fpd60 as tpd,
		cast(sysdatetime() as datetime) as dt_dml

		from base b;

		set @i = dateadd(dd,1,@i);

	end;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Drop temp (#) tables';

	drop table #stg_fpd0;
	drop table #stg_fpd30;
	drop table #stg_fpd60;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY FPD - FINISH';

end try

begin catch

if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY FPD - ERROR';
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
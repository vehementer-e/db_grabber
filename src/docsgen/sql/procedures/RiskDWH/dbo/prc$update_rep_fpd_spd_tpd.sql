CREATE procedure [dbo].[prc$update_rep_fpd_spd_tpd] as 

SET NOCOUNT ON
SET XACT_ABORT ON

declare 
@cnt_check int,
@srcname nvarchar(100);

set @srcname = 'UPDATE_REP_FPD_SPD_TPD';

begin try

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'START';

	set @cnt_check  = (select count(*) from RiskDWH.dbo.rep_fpd_spd_tpd
	where cdate = dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date)));

	if @cnt_check = 0 

	begin

		insert into RiskDWH.dbo.rep_fpd_spd_tpd
		select distinct cdate, overdue_days, principal_rest, total_rest, b.external_id,
		case when fpd60 = 1 or fpd30 = 1 then 1 else fpd0 end as fpd,
		case when fpd60 = 1 then 1 else fpd30 end spd,
		fpd60 tpd,
		cast(SYSDATETIME() as datetime) as dt_dml
		from dwh_new.dbo.stat_v_balance2 b
		left join Reports.dbo.dm_maindata2 m on b.external_id=m.external_id
		where cdate= dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date)) --вчера
		and total_rest>=100
		and b.end_date is null;

		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'INSERT COMPLETE';


	end;

	else

	begin
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'THERE IS DATA FOR YESTERDAY IN TABLE';
	end;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try

begin catch

if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
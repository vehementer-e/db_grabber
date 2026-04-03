
/******************************************************************************************************
Цепочка процедур для расчета резервов по методике IFRS9


Revisions:
dt			user				version		description
03/10/24	datsyplakov			v1.0		Создание процедуры

*****************************************************************************************************/

CREATE procedure [Risk].[prc$proc_chain_for_IFRS9] @rdt date 
as

declare @srcname varchar(250) = 'MONTH PROC CHAIN FOR IFRS9';
declare @info varchar(1000);

begin try

	set @info = concat('START rdt = ',format(@rdt,'dd.MM.yyyy'))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @info; 


	declare @pd_check int = 0;
	select @pd_check = iif(count(*)=0,0,1) from risk.stg_IFRS9_PDL_PD a where a.r_date = @rdt;

	if @pd_check = 0 begin

		set @info = concat('THERE IS NO DATA IN stg_IFRS9_PDL_PD for ',format(@rdt,'dd.MM.yyyy') )
		exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	end

	if @pd_check = 1 begin

		exec dbo.prc$set_debug_info @src = @srcname, @info = 'LGD for PTS';
		exec risk.prc$calc_lgd_recov_gross_cond @dt_upper_bound = @rdt

		exec dbo.prc$set_debug_info @src = @srcname, @info = 'PTS';
		exec risk.prc$calc_IFRS9_PTS @rdt = @rdt;

		exec dbo.prc$set_debug_info @src = @srcname, @info = 'INSTALLMENT';
		exec risk.prc$calc_IFRS9_INST @rdt = @rdt;

		exec dbo.prc$set_debug_info @src = @srcname, @info = 'PDL';
		exec risk.prc$calc_IFRS9_PDL @rdt = @rdt;

		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'DONT FORGET TO UPDATE risk.det_IFRS_proper_vers VIEW'; 

	end




exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH'; 

end try 

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

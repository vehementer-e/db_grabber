


/**************************************************************************
Процедура для обновления объектов, содержащих фактические показатели, 
необходимые для прогнозной модели

Необходимые объекты для процедуры:
срез на @rdt в risk.prov_BU_cred_rates
срез на @rdt в dbo.nu_rates_calc_history_regs

Revisions:
dt			user				version		description
12/09/24	datsyplakov			v1.0		Создание процедуры
20/11/2025	aygolicyn			v1.1		Обновление поставили на 1 месяц. Для risk.prc$update_cmrmfo_portfs

*************************************************************************/


CREATE procedure [Risk].[prc$proc_chain_for_forecast_model] @rdt date 
as 

declare @srcname varchar(250) = 'Month proc chain for forecast model';
declare @vinfo varchar(1000);
declare @bu_vers int = null;
declare @nu_vers int = null;

declare @v_dt_from date = dateadd(dd, 1, eomonth(@rdt, -1));
declare @v_dt_to date = eomonth(@rdt, 0);

begin try


set @vinfo = concat('START rdt = ',format(@rdt,'dd.MM.yyyy'))
exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo; 


select @bu_vers = max(vers) from risk.prov_BU_cred_rates where r_date = @rdt;
select @nu_vers = max(vers) from dbo.nu_rates_calc_history_regs where r_date = @rdt;

if @bu_vers is null begin 
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'BU(IFRS) SLICE FOR RDT IS EMPTY'; 
end
else begin
	set @vinfo = CONCAT('BU_VERS = ',@bu_vers)
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;
end


if @nu_vers is null begin 
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'NU(RAS) SLICE FOR RDT IS EMPTY'; 
end
else begin
	set @vinfo = CONCAT('NU_VERS = ',@nu_vers)
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;
end


if @bu_vers is not null and @nu_vers is not null begin

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'CMR and MFO portfs'; 
	--	Используется в Сборке БУ резервов
	--	Обновление поставили на 1 месяц вместо по умолчанию на 3 месяца от даты запуска. Это ускорят работу
	exec risk.prc$update_cmrmfo_portfs  @dt_from = @v_dt_from, @dt_to = @v_dt_to;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'STG_FCST_* objects'; 	
	exec risk.prc$update_umfo_fact_for_model @rdt = @rdt;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'LGD FROM OCT 2022'; 
	--Используется в Сборке БУ резервов, но с другими датами
	exec risk.prc$calc_lgd_recov_vint_method @dt_lower_bound = '2022-10-01', @dt_upper_bound = @rdt, @modcnt = 48;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'LGD FROM AUG 2023'; 	
	--Используется в Сборке БУ резервов, но с другими датами
	exec risk.prc$calc_lgd_recov_vint_method @dt_lower_bound = '2023-08-01', @dt_upper_bound = @rdt, @modcnt = 48;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'UMFO PRODUCTION SLICE'; 	
	exec risk.prc$update_umfo_portf @repmonth = @rdt;
	
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'APPLY BU(IFRS) AND NU(RAS) RATES TO STG_FCST_UMFO'; 
	begin transaction;

		update a set 
		a.prov_BU_od = a.total_od * isnull(b.BU_RATE,0),
		a.prov_BU_int = a.total_int * isnull(b.BU_RATE,0),
		a.prov_BU_fee = a.total_fee * isnull(b.BU_RATE,0),
		a.prov_BU_gross = a.total_gross * isnull(b.BU_RATE,0),

		a.prov_NU_od = a.total_od * isnull(c.prov_rate_nu_new,0),
		a.prov_NU_int = a.total_int * isnull(c.prov_rate_nu_new,0),
		a.prov_NU_fee = a.total_fee * isnull(c.prov_rate_nu_new,0),
		a.prov_NU_gross = a.total_gross * isnull(c.prov_rate_nu_new,0)

		--select a.external_id, a.total_od * isnull(b.BU_RATE,0) as od_bu,a.total_int * isnull(b.BU_RATE,0) as int_bu,isnull(b.BU_RATE,0) as BU_RATE,a.total_od * isnull(c.prov_rate_nu_new,0) as od_nu,a.total_int * isnull(c.prov_rate_nu_new,0) as int_nu, isnull(c.prov_rate_nu_new,0) as NU_RATE

		from risk.stg_fcst_umfo a
		left join risk.prov_BU_cred_rates b
		on a.external_id = b.external_id
		and a.r_date = b.r_date
		and b.vers = @bu_vers
		left join dbo.nu_rates_calc_history_regs c
		on a.external_id = c.external_id
		and a.r_date = c.r_date
		and c.vers = @nu_vers

		where a.r_date = @rdt

	commit transaction;


end



exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH'; 


EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
	,@recipients =  'Александр Голицын <a.golicyn@carmoney.ru>; Тимур Сулейманов <t.sulejmanov@carmoney.ru>'
	,@body = 'Процедура [Risk].[prc$proc_chain_for_forecast_model] отработала. Можно запускать Прогноз'
	,@body_format = 'TEXT'
	,@subject = 'База для Прогноза обновлена';

end try 

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
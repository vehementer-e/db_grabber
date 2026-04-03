CREATE    procedure [dbo].[monitoring_car_colors] 
as
begin
	declare @srcname varchar(100) = 'MONITORING DET_CAR_COLOR_MAPPING';
	declare @vinfo varchar(1000);
	declare @cnt int;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'START';


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Loginom';


	drop table if exists #stg_app_car_color_loginom;
	select distinct a.history_color
	into #stg_app_car_color_loginom
	--from [c2-vsr-lsql].[LoginomDB].[dbo].[OriginationLog] a with (nolock)
	FROM Stg._loginom.Originationlog a with (nolock)
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'GIBDD';

	drop table if exists #stg_app_car_color_gibdd;
	select distinct a.history_color
	into #stg_app_car_color_gibdd
	--from LoginomDB.dbo.gibdd_response a
	from stg._loginom.gibdd_response a with (nolock)
	where 1=1
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'MFO';

	drop table if exists #det_mfo_color;
	select 
		a.Ссылка as Ссылка,
		a.Наименование as color
	into #det_mfo_color 
	from stg._1cMFO.[Справочник_ГП_ЦветТС] a
	--[PRODSQL02].[mfo].[dbo].[Справочник_ГП_ЦветТС] a
	;

	drop table if exists #stg_app_car_color_mfo;
	select distinct b.color
	into #stg_app_car_color_mfo
	from Stg._1cMFO.Документ_ГП_Заявка a
	left join #det_mfo_color b
	on a.Цвет = b.Ссылка
	;



	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#new_colors';

	drop table if exists #new_colors;
	with un as (
		select a.history_color as color from #stg_app_car_color_gibdd a
		union 
		select a.history_color as color from #stg_app_car_color_loginom a
		union
		select a.color from #stg_app_car_color_mfo a
	)
	select distinct un.color 
	into #new_colors
	from un 
	where not exists (select 1 from RiskDWH.dbo.det_car_color_mapping b
					where isnull(un.color,'n') = isnull(b.original_color,'n'))
	;


	select @cnt = count(*) from #new_colors;
	select @vinfo = case when @cnt = 0 then 'No new colors' else concat('New colors cnt = ', @cnt) end;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


	if @cnt > 0 
	begin

		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'MERGE Into DET';

		begin transaction;

			merge into RiskDWH.dbo.det_car_color_mapping dst
			using #new_colors src
			on (dst.original_color = src.color)
			when not matched then insert (original_color) values (src.color)
			;

		commit transaction;


	--Оповещение по Email d.cyplakov@carmoney.ru 
	/**Появились новые записи в справочнике DET_CAR_COLOR_MAPPING**/
	declare @subject nvarchar(255) = 'Появились новые записи в справочнике DET_CAR_COLOR_MAPPING'
	declare @body nvarchar(1024) = 'Появились новые записи в справочнике DET_CAR_COLOR_MAPPING - ' + cast(@cnt as nvarchar(255))
	EXEC msdb.dbo.sp_send_dbmail  
			@profile_name = 'Default',  
			@recipients = 'd.cyplakov@carmoney.ru',  
			@body = @body,  
			@body_format='HTML', 
			@subject = '@subject' 
	end


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';
end

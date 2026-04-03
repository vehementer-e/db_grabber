





/**************************************************************************
Процедура для сборки основы из портфеля УМФО для резервов

Revisions:
dt			user				version		description
24/08/20	datsyplakov			v1.0		Создание процедуры
21/01/21	datsyplakov			v1.1		добавлено поле "тип клиента"
											добавлен параметр @data_source:
											P - данные с прода (по умолчанию)
											R - данные из реплик STG._1cUMFO
											группировка по r_date и external_id 
											+ подсчет дублей

*************************************************************************/

CREATE procedure [Risk].[prc$update_umfo_portf] @repmonth date = null, @data_source varchar(1) = null
as 

	declare @srcname varchar(250) = 'UPDATE UMFO PORTF for RiskAnalytics';
	declare @vinfo varchar(1000);
	declare @doubles_cnt int;
	declare @doubles_list varchar(4000);

begin try

	if @repmonth is null set @repmonth = eomonth(cast(getdate() as date),-1);
	if (@data_source is null or @data_source not in ('P','R') ) set @data_source = 'R';
	

	set @vinfo = 'START repmonth = ' + convert(varchar, eomonth(@repmonth), 120) + 
				 ' datasource = ' + case when @data_source = 'P' then 'prod' else 'replica' end
	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'delete from Risk.portf_umfo';

	begin transaction

		delete from Risk.portf_umfo
		where r_date = eomonth(@repmonth);

	set @vinfo = concat('Rowcount = ',@@ROWCOUNT)

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @srcname, @vinfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'insert into Risk.portf_umfo';

	if @data_source = 'R' 
	begin

		begin transaction
	
			insert into Risk.portf_umfo

			select cast(dateadd(yy,-2000,r_date) as date)                    as r_date,
					НомерДоговора as external_id,
					case when НомерДоговора in ('150323890001','150519890003','1512161130001') then 1 else 0 end as tz_flag,

					min(cast(isnull(ДнейПросрочки,0) as int)) as dpd,
		  
					sum(cast(isnull([СуммаОД],0)                as float))        as due_od,
					sum(cast(isnull([СуммаПроценты],0)          as float))        as due_int,
					
					sum(cast(isnull([СуммаОД],0)                as float)         +
					cast(isnull([СуммаПроценты],0)          as float))       as due_gross,
					
					avg(cast(ЭффективнаяСтавкаПроцента/100.0 as float)) as eps,
					типклиентов as cli_type

				from (select dr.дата as r_date,dr.Комментарий,dr.типклиентов,d.НомерДоговора,d.Дата,d.суммазайма,r.*
						from stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ dr 						
						inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ r 						
						on r.ссылка=dr.ссылка						
						inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный d 						
						on r.Займ=d.ссылка
						where cast(dateadd(yy,-2000,dr.дата) as date) = eomonth(@repmonth)
						) a
				where a.ДнейПросрочки < 10000
				group by cast(dateadd(yy,-2000,r_date) as date), 
						НомерДоговора,
						case when НомерДоговора in ('150323890001','150519890003','1512161130001') then 1 else 0 end,
						--cast(isnull(ДнейПросрочки,0) as int),
						типклиентов

		set @vinfo = concat('Rowcount = ', @@ROWCOUNT)

		commit transaction;

		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


		--проверка на дубли
		select 
		@doubles_list = STRING_AGG(aa.НомерДоговора , ', '), 
		@doubles_cnt = count(*) 
		from (

		select d.НомерДоговора
		from stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ dr 						
		inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ r 						
		on r.ссылка=dr.ссылка						
		inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный d 						
		on r.Займ=d.ссылка
		where cast(dateadd(yy,-2000,dr.дата) as date) = eomonth(@repmonth)
		group by d.НомерДоговора
		having count(*)>1
		) aa;

		if @doubles_cnt = 0 
		begin 
			exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'No doubles - OK';
		end
		else begin
			set @vinfo = concat('Doubles cnt = ' , @doubles_cnt, ' cred list: ', @doubles_list);
			
			exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;
		end


	end

	if @data_source = 'P' 
	begin 

		begin transaction
	
			insert into Risk.portf_umfo

			select cast(dateadd(yy,-2000,r_date) as date)                    as r_date,
					НомерДоговора as external_id,
					case when НомерДоговора in ('150323890001','150519890003','1512161130001') then 1 else 0 end as tz_flag,

					min(cast(isnull(ДнейПросрочки,0) as int)) as dpd,
		  
					sum(cast(isnull([СуммаОД],0)                as float))        as due_od,
					sum(cast(isnull([СуммаПроценты],0)          as float))        as due_int,
					
					sum(cast(isnull([СуммаОД],0)                as float)         +
					cast(isnull([СуммаПроценты],0)          as float))         as due_gross,
					avg(cast(ЭффективнаяСтавкаПроцента/100.0 as float)) as eps,
					
					типклиентов as cli_type

				from (select dr.дата as r_date,dr.Комментарий,dr.типклиентов,d.НомерДоговора,d.Дата,d.суммазайма,r.*
						from stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ dr with (nolock) --заглушка
						--[c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr with (nolock)
						--[prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr 
						inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ r with (nolock) --заглушка
						--[c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r with (nolock) 
						--[prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r 
						on r.ссылка=dr.ссылка 						
						inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный d with (nolock) --заглушка
						--[c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный] d with (nolock) 
						--[prodsql01].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный]  d 
						on r.Займ=d.ссылка
						where cast(dateadd(yy,-2000,dr.дата) as date) = eomonth(@repmonth)
						) a
				where a.ДнейПросрочки < 10000
				group by cast(dateadd(yy,-2000,r_date) as date), 
						НомерДоговора,
						case when НомерДоговора in ('150323890001','150519890003','1512161130001') then 1 else 0 end,
						--cast(isnull(ДнейПросрочки,0) as int),
						типклиентов

		set @vinfo = concat('Rowcount = ', @@ROWCOUNT)

		commit transaction;

		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'check for doubles';


		--проверка на дубли
		select 
		@doubles_list = STRING_AGG(aa.НомерДоговора , ', '), 
		@doubles_cnt = count(*) 
		from (

		select d.НомерДоговора
		from stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ dr with (nolock) --заглушка
		--[c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr with (nolock)  
		--[prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr 
		inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ  r with (nolock)  --заглушка
		--[c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r with (nolock) 
		--[prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r 
		on r.ссылка=dr.ссылка 						
		inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный d with (nolock) --заглушка
		--[c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный]  d with (nolock) 
		--[prodsql01].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный]  d 
		on r.Займ=d.ссылка
		where cast(dateadd(yy,-2000,dr.дата) as date) = eomonth(@repmonth)		
		group by d.НомерДоговора
		having count(*)>1
		) aa;

		if @doubles_cnt = 0 
		begin 
			exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'No doubles - OK';
		end
		else begin
			set @vinfo = concat('Doubles cnt = ' , @doubles_cnt, ' cred list: ', @doubles_list);
			
			exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;
		end


	end

	/*
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'balance corrections';


	--обнуляем остаток, если он отрицательный
	begin transaction;

	update Risk.portf_umfo set due_gross = 0 where due_gross < 0 and r_date = @repmonth;
	set @vinfo = concat('DUE_GROSS < 0 cnt = ', @@ROWCOUNT);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


	update Risk.portf_umfo set due_od = 0 where due_od < 0 and r_date = @repmonth;
	set @vinfo = concat('DUE_OD < 0 cnt = ', @@ROWCOUNT);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	update Risk.portf_umfo set due_int = 0 where due_int < 0 and r_date = @repmonth;
	set @vinfo = concat('DUE_INT < 0 cnt = ', @@ROWCOUNT);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	commit transaction;
	*/

	select @vinfo = concat('DUE_OD < 0 cnt = ', count(*))
	from Risk.portf_umfo a
	where a.r_date = @repmonth
	and a.due_od < 0;
	
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;
	
	select @vinfo = concat('DUE_INT < 0 cnt = ', count(*))
	from Risk.portf_umfo a
	where a.r_date = @repmonth
	and a.due_int < 0;
	
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	select @vinfo = concat('DUE_GROSS < 0 cnt = ', count(*))
	from Risk.portf_umfo a
	where a.r_date = @repmonth
	and a.due_gross < 0;
	
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

 	  
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

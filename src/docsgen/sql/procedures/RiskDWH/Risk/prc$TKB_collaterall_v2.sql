CREATE procedure [Risk].[prc$TKB_collaterall_v2] @rdt date, @target_fair_sum float 
as

declare @srcname varchar(250) = 'COLLATERAL FOR TransKapitalBank';
declare @info varchar(1000);

begin try 


	set @info = concat('START rdt = ',format(@rdt,'dd.MM.yyyy'),' target fair sum = ', format(@target_fair_sum,'### ### ### ###'))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @info; 



	declare @nu_vers int;
	select @nu_vers = max(vers) from dbo.nu_rates_calc_history_regs where r_date = @rdt;

	--set @nu_vers = 999;

	if @nu_vers is null begin

	set @info = concat('THERE IS NO DATA in dbo.nu_rates_calc_history_regs for ',format(@rdt,'dd.MM.yyyy'))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @info;

	end 

	if @nu_vers is not null begin


		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'NBKI scores';

		--nbch PV2 score
		drop table if exists #stg_nbki_sc;

		select 
		b.person_id as external_id, b.request_date,
		try_cast(replace(SUBSTRING(b.json, CHARINDEX('"NBKIScoring": "',b.json)+16, 3),'"','') as float) as nbki_b902_score
		--,b.JSON
		into #stg_nbki_sc
		from stg._loginom.Original_response b
		where b.source = 'nbch PV2 score'
		;



		drop table if exists #nbki_sc;
		with base as (
			select a.external_id, ROW_NUMBER() over (partition by a.external_id order by request_date desc) as rown, a.nbki_b902_score 
			from #stg_nbki_sc a
			where a.nbki_b902_score is not null
		)
		select a.external_id, a.nbki_b902_score 
		into #nbki_sc
		from base a
		where a.rown = 1
		;

		insert into #nbki_sc
		select a.id, a.score
		from dbo.bki_resp_nbki_B902_030822 a
		where a.score is not null
		and not exists (select 1 from #nbki_sc b where a.id = b.external_id)
		;


		insert into #nbki_sc
		select a.id, a.score
		from dbo.bki_resp_nbki_B902_080622 a
		where a.score is not null
		and not exists (select 1 from #nbki_sc b where a.id = b.external_id)
		;



		drop table if exists #det_spr_kontragenty;
		select * 
		into #det_spr_kontragenty
		from stg.[_1cUMFO].Справочник_Контрагенты with (nolock)
		;




		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_kp';

		drop table if exists #stg_kp;

		select DISTINCT 
		 cast(dateadd(yy,-2000,a.ДатаОтчета) as date) as r_date
		, concat(format(cast(dateadd(yy,-2000,a.ДатаДоговора) as date),'dd.MM.yyyy'),' ',a.НомерДоговора) as cred_num_date
		, ka.НаименованиеПолное as fio
		, concat(format(ps.birth_date,'dd.MM.yyyy') ,iif(clr.PlaceOfBirth is null,'',' '+clr.PlaceOfBirth)) as birth_place_date
		, cast(a.СуммаЗайма AS FLOAT) as amount
		, cast(a.СтавкаПоДоговору AS FLOAT) doc_rate
		, case 
		when ПризнакРеструктуризации = 1 then 1
		when nu.flag_restruct = 1 then 1 
		else 0 end as flag_restruct
		, cast(dateadd(yy,-2000,a.ДатаДоговора) as date) as doc_issue_date
		, cast(dateadd(yy,-2000,dateadd(MONTH,c.term,a.ДатаДоговора)) as date) as doc_end_date
		, isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) as dpd
		, isnull(cast(a.ОстатокОДвсего AS FLOAT),0) as total_od
		, isnull(cast(a.ОстатокПроцентовВсего AS FLOAT),0) as total_int
		--справедливая стоимость
		, isnull(cast(a.ОстатокОДвсего AS FLOAT),0) * (1.0 - case 
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) > 90 then 1.0
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) > 0 then 0.6
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) = 0 and a.ПризнакРеструктуризации = 1 then 0.4
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) = 0 and nu.flag_restruct = 1 then 0.4
		else 0.3 end) as fair_total_od
		, isnull(cast(a.ОстатокПроцентовВсего AS FLOAT),0) * (1.0 - case 
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) > 90 then 1.0
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) > 0 then 0.6
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) = 0 and a.ПризнакРеструктуризации = 1 then 0.4
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) = 0 and nu.flag_restruct = 1 then 0.4
		else 0.3 end) as fair_total_int

		--, ROW_NUMBER() over (order by a.НомерДоговора desc) as r_n
		--, ROW_NUMBER() over (order by nbk.nbki_b902_score) as r_n --по скору
		, row_number() over(order by 
			case when cast(dateadd(yy,-2000,a.ДатаДоговора) as date) >= '2024-01-01' then 0 else 1 end, --свежие, с 2024
			isnull(cast(a.ОстатокОДвсего AS FLOAT),0) + isnull(cast(a.ОстатокПроцентовВсего AS FLOAT),0) desc --с большей суммой
			) 
			as r_n
		, cast(case 
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) > 90 then 1.0
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) > 0 then 0.6
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) = 0 and a.ПризнакРеструктуризации = 1 then 0.4
		when isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) = 0 and nu.flag_restruct = 1 then 0.4
		else 0.3 end as float) as discount

		into #stg_kp
			--select *
		from
		[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]  as a (nolock)
		left join dwh2.dbo.dm_CMRStatBalance as cmr
		on cmr.d =cast(dateadd(yy,-2000,a.ДатаОтчета) as date) 
		and cmr.external_id = a.НомерДоговора

		inner join dwh2.risk.credits c 
		on c.external_id = a.НомерДоговора
		left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный z
		on a.Займ = z.Ссылка
		--left join stg._1cUMFO.Справочник_Контрагенты ka
		left join #det_spr_kontragenty ka
		on z.Контрагент = ka.Ссылка
		left join dwh2.risk.person ps
		on c.person_id = ps.person_id
		left join stg._fedor.core_ClientRequest clr
		on c.external_id = clr.Number collate SQL_Latin1_General_CP1_CI_AS
		left join RiskDWH.dbo.nu_rates_calc_history_regs nu
		on c.external_id = nu.external_id
		and nu.r_date = @rdt
		and nu.vers = @nu_vers
		left join #nbki_sc nbk
		on c.external_id = nbk.external_id

		where a.ДатаОтчета = dateadd(yy,2000,@rdt)
		and isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) <5
		and cmr.dpd<5
		and (cast(dateadd(yy,-2000,a.ДатаДоговора) as date) <'2022-02-25'
			or cast(dateadd(yy,-2000,a.ДатаДоговора) as date) >'2022-12-28'
		) -- в этот период не было согласий на передачу прав требования
		and isnull(cast(a.ДнейПросрочкиДляРезервов as float),0) = isnull(cast(a.ДнейПросрочки as float),0)
		and c.credit_type = 'PTS'
		and term>=12
		;



		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Cycle';


		drop table if exists #stg_kp2;
		select top 0 * 
		into #stg_kp2
		from #stg_kp a
		;



		declare @fair_sum float = 0;
		declare @i int = 1;


		while @fair_sum < @target_fair_sum begin

			insert into #stg_kp2 
			select * from #stg_kp a
			where 1=1
			and a.r_n = @i
			and len(a.birth_place_date) > 10
			and a.total_od > 0

			select @fair_sum = sum(a.fair_total_od + a.fair_total_int) from #stg_kp2 a




			if @i % 10 = 0 or @i = 1 begin
				set @info = concat('Current fair sum = ',format(@fair_sum, '### ### ### ###'),' iter = ',@i)
				exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @info;
			end

		set @i = @i + 1
		end;


		set @info = concat('Final fair sum = ',format(@fair_sum, '### ### ### ###'),' iter = ',@i)
		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @info;



		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'insert into TKB_collateral';

		begin transaction;

			delete from risk.TKB_collateral where r_date = @rdt;
			insert into risk.TKB_collateral
			select 
			r_date	
			,cast(getdate() as datetime) as dt_dml
			,cred_num_date	
			,fio	
			,birth_place_date	
			,amount	
			,doc_rate	
			,flag_restruct	
			,doc_issue_date	
			,doc_end_date	
			,dpd	
			,total_od	
			,total_int	
			,fair_total_od	
			,fair_total_int	
			,r_n	
			,discount
			from #stg_kp2 a
			;

		commit transaction;

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
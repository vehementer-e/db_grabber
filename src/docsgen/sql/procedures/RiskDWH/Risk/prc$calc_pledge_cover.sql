CREATE procedure [Risk].[prc$calc_pledge_cover] @repdate date

/**************************************************************************
Процедура для сборки промежуточных данных, которые используются при
расчете коэффициента залогового покрытия (по арестованным авто)

Revisions:
dt			user				version		description
19/02/21	datsyplakov			v1.0		Создание процедуры


*************************************************************************/

as

begin try

	declare @srcname varchar(100) = 'Update pledge cover data';
	declare @vinfo varchar(100);


	set @vinfo = concat('START rdt =',format(@repdate,'dd.MM.yyyy'));
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


		--исторические данные по арестам авто
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#arrest_old';

		drop table if exists #arrest_old;
		select 
		cast(format(a.externalid,'#') as varchar(100)) as external_id,
		cast(a.mobonarest as int) as mob_on_arest,
		cast(a.dpdonarest as int) as dpd_on_arest,
		a.gross as gross,
		a.estprice as est_price
		into #arrest_old
		from RiskDWH.risk.for_pledge_cover_coef_history a
		;

		--Дата ареста
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_arrest_new';

		drop table if exists #stg_arrest_new;	
		select deal.Number as external_id,
		min(cast(epmbt.[ArestCarDate] as date)) as ArestCarDate

		into #stg_arrest_new
		FROM  Stg._Collection.Deals AS Deal 
		LEFT JOIN Stg._Collection.customers AS c 
		ON c.Id = Deal.IdCustomer 
		LEFT JOIN Stg._Collection.JudicialProceeding AS jp 
		ON Deal.Id = jp.DealId 
		LEFT JOIN Stg._Collection.JudicialClaims AS jc 
		ON jp.Id = jc.JudicialProceedingId 
		LEFT JOIN Stg._Collection.EnforcementOrders AS eo 
		ON jc.Id = eo.JudicialClaimId 
		LEFT JOIN Stg._Collection.EnforcementProceeding AS ep 
		ON eo.Id = ep.EnforcementOrderId 
		LEFT JOIN Stg._Collection.collectingStage AS cst_deals 
		ON Deal.StageId = cst_deals.Id 
		LEFT JOIN Stg._Collection.collectingStage AS cst_client 
		ON c.IdCollectingStage = cst_client.Id 
		LEFT JOIN Stg._Collection.CustomerPersonalData AS cpd 
		ON cpd.IdCustomer = c.Id 
		LEFT JOIN Stg._Collection.[DadataCleanFIO] AS dcfio 
		ON dcfio.Surname = c.LastName 
		AND dcfio.Name = c.Name 
		AND dcfio.Patronymic = c.MiddleName 
		LEFT JOIN Stg._Collection.Courts AS court 
		ON court.Id = jp.CourtId 
		LEFT JOIN Stg._Collection.DepartamentFSSP AS fssp 
		ON ep.DepartamentFSSPId = fssp.Id 
		LEFT JOIN Stg._Collection.EnforcementProceedingMonitoring AS monitoring 
		ON ep.Id = monitoring.EnforcementProceedingId
		left join Stg._Collection.EnforcementProceedingMonitoringBeforeTrades as epmbt
		on epmbt.EnforcementProceedingMonitoringId = monitoring.id


		--where monitoring.[ArestCarDate] is not null
		where epmbt.ArestCarDate is not null
		group by deal.Number
		;


		--рыночная и оценосная стоимость
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_market_price';

		drop table if exists #stg_market_price;
		select distinct 
		a.external_id
		, a.market_price
		, a.market_price*a.koef_liquidity/100 as est_price
		into #stg_market_price
		from reports.dbo.dm_MainData2 as a
		where a.market_price >0 and  a.koef_liquidity >0
		;


		/*Дополнение для реестра арсетованных авто*/
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#arrest_new';

		drop table if exists #arrest_new;
		select a.external_id 
		, a.ArestCarDate as arest_dt
		, round(cast(DATEDIFF(dd, c.start_date, a.arestcardate) as float)/31,0) as mob_on_arest
		, mfo.overdue_days as dpd_on_arest
		, cast(isnull(mfo.total_rest,0) as float) as gross
		, cast(d.est_price as float) as est_price
		into #arrest_new
		from #stg_arrest_new as a
		left join dwh_new.dbo.tmp_v_credits as c 
		on c.external_id = a.external_id
		left join dwh_new.dbo.stat_v_balance2 as mfo
		on a.external_id = mfo.external_id 
		and mfo.cdate = a.arestcardate
		left join #stg_market_price as d 
		on d.external_id = a.external_id
		where not exists (select 1 from #arrest_old s where a.external_id = s.external_id) -- исключаем исторический срез 
		and mfo.external_id is not null -- наличие данных в мфо
		and d.external_id is not null -- наличие данных по стоимости
		and mfo.total_rest > 0 --остаток Гросс (од+%%+штрафы+пени) не равен нулю
		and a.ArestCarDate <= @repdate
		;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Insert into prov_stg_pledge_cover';

	begin transaction;

	delete from RiskDWH.risk.prov_stg_pledge_cover where rep_dt = @repdate;
	set @vinfo = concat('deleted cnt = ', @@ROWCOUNT);

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	
	begin transaction;

		with base as (
		select a.external_id, a.arest_dt, cast(a.mob_on_arest as int) as mob_on_arest, a.gross, a.est_price from #arrest_new a
		union all
		select a.external_id, cast(null as date) as arest_dt, a.mob_on_arest, a.gross, a.est_price from #arrest_old a
		)
		insert into RiskDWH.risk.prov_stg_pledge_cover

		select 
		@repdate as rep_dt,
		cast(SYSDATETIME() as datetime) as dt_dml,
		b.external_id,
		b.arest_dt,
		b.mob_on_arest, 
		b.gross, 
		b.est_price,  
		case when b.est_price * POWER(cast(0.9 as float), b.mob_on_arest / 12.0) - 45000 < 0
		then 0 
		else b.est_price * POWER(cast(0.9 as float), b.mob_on_arest / 12.0) - 45000 
		end as cf_est_price
		from base b;

		set @vinfo = concat('inserted cnt = ', @@ROWCOUNT);

	commit transaction;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



	--записываем в лог значение коэффициента залогового покрытия
	declare @pledge_cover float;

	select @pledge_cover = ceiling(sum(a.cf_est_price) / sum(a.gross_due)*1000)/1000
	from RiskDWH.risk.prov_stg_pledge_cover a
	where a.rep_dt = @repdate
	;

	set @vinfo = concat('PLEDGE COVER = ', cast(@pledge_cover as varchar(5)) );

	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try


begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

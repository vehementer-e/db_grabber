


/**************************************************************************
Скрипт в агент SQL для расчёта прогноза

Revisions:
dt			user				version		description
12/11/2025	golicyn				v1.0		Создание процедуры


*************************************************************************/

CREATE procedure [Risk].[prc$calc_Test]

@rdt date = null,
@bu_disc float = 0.054,
@LGD_vers int = 3

AS

begin try

	declare @srcname varchar(100) = '[Risk].[prc$calc_Test]';

	declare @vinfo varchar(1000) = '[Risk].[prc$calc_Test]';

	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	drop table if exists Temp_TTT2;

	select @rdt as rdt
	into Temp_TTT2
	;

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- FIX2 для ПТС - БУ-резерв - сценарий по ставкам
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	--ставки и дисконты для БУ в 2025 году
	drop table if exists Temp_Test;
	with base as (
		select 
		cast(a.dt_from as date) as dt_from, 
		cast(a.dt_to as date) as dt_to, 
		cast(a.disc as float) as disc,
		cast(a.korr as float) as korr
		from (values


			('2025-10-31' , '2025-10-31' , @bu_disc	, 1.00),
			('2025-11-30' , '2025-11-30' , @bu_disc	, 1.00),
			('2025-12-31' , '2025-12-31' , @bu_disc	, 1.00),
			('2026-01-31' , '2026-01-31' , @bu_disc	, 1.00),
			('2026-02-28' , '2026-02-28' , @bu_disc	, 1.00),
			('2026-03-31' , '2026-03-31' , @bu_disc	, 1.00),
			('2026-04-30' , '2026-04-30' , @bu_disc	, 1.00),
			('2026-05-31' , '2026-05-31' , @bu_disc	, 1.00),
			('2026-06-30' , '2026-06-30' , @bu_disc	, 1.00),
			('2026-07-31' , '2026-07-31' , @bu_disc	, 1.00),
			('2026-08-31' , '2026-08-31' , @bu_disc	, 1.00),
			('2026-09-30' , '2026-09-30' , @bu_disc	, 1.00),
			('2026-10-31' , '2026-10-31' , @bu_disc	, 1.00),
			('2026-11-30' , '2026-11-30' , @bu_disc	, 1.00),
			('2026-12-31' , '2026-12-31' , @bu_disc	, 1.00),
			('2027-01-31' , '2027-01-31' , @bu_disc	, 1.00),
			('2027-02-28' , '2027-02-28' , @bu_disc	, 1.00),
			('2027-03-31' , '2027-03-31' , @bu_disc	, 1.00),
			('2027-04-30' , '2027-04-30' , @bu_disc	, 1.00),
			('2027-05-31' , '2027-05-31' , @bu_disc	, 1.00),
			('2027-06-30' , '2027-06-30' , @bu_disc	, 1.00),
			('2027-07-31' , '2027-07-31' , @bu_disc	, 1.00),
			('2027-08-31' , '2027-08-31' , @bu_disc	, 1.00),
			('2027-09-30' , '2027-09-30' , @bu_disc	, 1.00),
			('2027-10-31' , '2027-10-31' , @bu_disc	, 1.00),
			('2027-11-30' , '2027-11-30' , @bu_disc	, 1.00),
			('2027-12-31' , '2027-12-31' , @bu_disc	, 1.00),
			('2028-01-31' , '2028-01-31' , @bu_disc	, 1.00),
			('2028-02-29' , '2028-02-29' , @bu_disc	, 1.00),
			('2028-03-31' , '2028-03-31' , @bu_disc	, 1.00),
			('2028-04-30' , '2028-04-30' , @bu_disc	, 1.00),
			('2028-05-31' , '2028-05-31' , @bu_disc	, 1.00),
			('2028-06-30' , '2028-06-30' , @bu_disc	, 1.00),
			('2028-07-31' , '2028-07-31' , @bu_disc	, 1.00),
			('2028-08-31' , '2028-08-31' , @bu_disc	, 1.00),
			('2028-09-30' , '2028-09-30' , @bu_disc	, 1.00),
			('2028-10-31' , '2028-10-31' , @bu_disc	, 1.00),
			('2028-11-30' , '2028-11-30' , @bu_disc	, 1.00),
			('2028-12-31' , '2028-12-31' , @bu_disc	, 1.00),
							   
			('2029-01-31' , '2029-01-31' , @bu_disc	, 1.00),
			('2029-02-28' , '2029-02-28' , @bu_disc	, 1.00),
			('2029-03-31' , '2029-03-31' , @bu_disc	, 1.00),
			('2029-04-30' , '2029-04-30' , @bu_disc	, 1.00),
			('2029-05-31' , '2029-05-31' , @bu_disc	, 1.00),
			('2029-06-30' , '2029-06-30' , @bu_disc	, 1.00),
			('2029-07-31' , '2029-07-31' , @bu_disc	, 1.00),
			('2029-08-31' , '2029-08-31' , @bu_disc	, 1.00),
			('2029-09-30' , '2029-09-30' , @bu_disc	, 1.00),
			('2029-10-31' , '2029-10-31' , @bu_disc	, 1.00),
			('2029-11-30' , '2029-11-30' , @bu_disc	, 1.00),
			('2029-12-31' , '2029-12-31' , @bu_disc	, 1.00),
			('2030-01-31' , '2030-01-31' , @bu_disc	, 1.00),
			('2030-02-28' , '2030-02-28' , @bu_disc	, 1.00),
			('2030-03-31' , '2030-03-31' , @bu_disc	, 1.00),
			('2030-04-30' , '2030-04-30' , @bu_disc	, 1.00),
			('2030-05-31' , '2030-05-31' , @bu_disc	, 1.00),
			('2030-06-30' , '2030-06-30' , @bu_disc	, 1.00),
			('2030-07-31' , '2030-07-31' , @bu_disc	, 1.00),
			('2030-08-31' , '2030-08-31' , @bu_disc	, 1.00),
			('2030-09-30' , '2030-09-30' , @bu_disc	, 1.00),
			('2030-10-31' , '2030-10-31' , @bu_disc	, 1.00),
			('2030-11-30' , '2030-11-30' , @bu_disc	, 1.00),
			('2030-12-31' , '2030-12-31' , @bu_disc	, 1.00)
		) a (dt_from, dt_to, disc, korr)
	)
	, rates as (

		select b.discount
			, a.dpd_bucket as bucket
			, null as mod_num
			, --a.PD_EAD * b.LGD_WO
			--set provision rates
			case when a.dpd_bucket = '[01] 0' then 0.05
				when a.dpd_bucket = '[02] 1-30' then 0.08
				when a.dpd_bucket = '[03] 31-60' then 0.2
				when a.dpd_bucket = '[04] 61-90' then 0.22 else 0 end
			as prov_rate				
			from (	
				select a.dpd_bucket, 
					--sum(a.prov_IFRS_PIT / a.LGD) / sum(a.gross) as PD_EAD
					sum(a.prov_IFRS_PIT) / sum(a.gross * a.LGD) as PD_EAD--select max(r_date)
				from risk.IFRS9_vitr a
				where a.r_date = '2024-08-31' and a.vers = 1
					and a.product = 'PTS'		
					and a.dpd_bucket <> '[05] 90+'
				group by a.dpd_bucket
			) a			
			left join risk.prov2_lgd b			
			on b.rep_dt = @rdt and b.vers = @LGD_vers
			and b.mod_num = 1

		union all

		select a.discount, '[05] 90+' as bucket, a.mod_num - 1 as mod_num, a.LGD_WO as prov_rate			
		from risk.prov2_lgd a			
		where a.rep_dt = @rdt and a.vers = @LGD_vers

	)

	select
		--a.dt_from, a.dt_to, a.disc, b.bucket, b.mod_num, 
		b.prov_rate * a.korr as prov_rate_upd
		,
		a.*
		, ' ---> ' as sep1
		, b.*
	into Temp_Test
	from base a
	left join rates b on a.disc = b.discount
	;

	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



	----------------------------------------------------------------------------------------------------------------------------------

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch




/**************************************************************************
Процедура для сборки основы портфелей из ЦМР и МФО

Revisions:
dt			user				version		description
24/08/20	datsyplakov			v1.0		Создание процедуры
05/10/20	datsyplakov			v1.1		Для ЦМР источник заменен на Reports.dbo.dm_CMRStatBalance_2
29/08/24	datsyplakov			v1.2		Добавлено обновление risk.bezz_cess_reestr - реестр проданных займов беззалог
16/04/2025	agolicyn			v2.1		Новый источник для RiskDWH.Risk.portf_mfo - dwh2.dbo.dm_CMRStatBalance
06/03/2026	agolicyn			v2.2		+цессия на залог
*************************************************************************/


CREATE procedure [Risk].[prc$update_cmrmfo_portfs] 
@dt_from date = null,
@dt_to date = null

as 

declare @v_dt_from date;
declare @v_dt_to date;

begin try

	select @v_dt_from	= coalesce(@dt_from , dateadd(dd,1,eomonth(cast(getdate() as date),-3)));
	select @v_dt_to		= coalesce(@dt_to , dateadd(dd,-1,cast(getdate() as date)));

	--if @dt_from is null set @dt_from = dateadd(dd,1,eomonth(cast(getdate() as date),-3));
	--if @dt_to	is null set @dt_to	 = dateadd(dd,-1,cast(getdate() as date));

	declare @srcname varchar(250) = 'UPDATE CMR and MFO PORTFs for RiskAnalytics';
	declare @vinfo varchar(1000);

	set @vinfo = 'START dt_from = ' + convert(varchar,@v_dt_from,120) + ' , dt_to = ' + convert(varchar,@v_dt_to,120);

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	/****************** ЦМР *******************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'delete from Risk.portf_cmr';

	begin transaction
	
		delete from Risk.portf_cmr
		where r_date between @v_dt_from and @v_dt_to;

	set @vinfo = concat('Rowcount = ',@@ROWCOUNT)

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @srcname, @vinfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'insert into Risk.portf_cmr';

	begin transaction
			   
		insert into Risk.portf_cmr
		
		-- в ноябре задвоились 18053114150001, 18082021180003, 19083000000160, 20052310000042 с отрицательными ПениНачислены
		select r_date, external_id, credit_date, closed, dpd_bucket_360, dpd_bucket_720, dpd_bucket_360_p, dpd_bucket_720_p, overdue_days, overdue_days_p
				, principal_rest, percents_rest, fines_rest, other_rest, overdue_amount, total_rest, pay_total, end_date
		from (
				select 
				ROW_NUMBER() over(partition by a.external_id, a.d order by ПениНачислено) as row_nn,
				a.d as r_date, 
				a.external_id,
				a.ContractStartDate as credit_date,
				iif( a.d >= a.ContractEndDate, 1, 0) as closed,

				RiskDWH.dbo.get_bucket_360(a.dpd) as dpd_bucket_360,
				RiskDWH.dbo.get_bucket_720(a.dpd) as dpd_bucket_720,

				RiskDWH.dbo.get_bucket_360(case when (isnull(a.dpd,0) < isnull(a.[dpd day-1],0)
				and isnull(a.[dpd day-1],0) > 0)
				Then isnull(a.[dpd day-1],0) + 1
				else isnull(a.dpd,0)
				end) as dpd_bucket_360_p,

				RiskDWH.dbo.get_bucket_720(case when (isnull(a.dpd,0) < isnull(a.[dpd day-1],0)
				and isnull(a.[dpd day-1],0) > 0)
				Then isnull(a.[dpd day-1],0) + 1
				else isnull(a.dpd,0)
				end) as dpd_bucket_720_p,

				isnull(a.dpd,0) as overdue_days,

				case when (isnull(a.dpd,0) < isnull(a.[dpd day-1],0)
				and isnull(a.[dpd day-1],0) > 0)
				Then isnull(a.[dpd day-1],0) + 1
				else isnull(a.dpd,0)
				end as overdue_days_p,

				cast(isnull(a.[остаток од],0) as float) as principal_rest,
				cast(isnull(a.[остаток %],0) as float) as percents_rest,
				cast(isnull(a.[остаток пени],0) as float) as fines_rest,
				cast(isnull(a.[остаток иное (комиссии, пошлины и тд)],0) as float) as other_rest,
				cast(isnull(a.overdue,0) as float) as overdue_amount,
				cast(0 as float) as total_rest,

				cast(isnull(a.[основной долг уплачено], 0) as float) +
				cast(isnull(a.[Проценты уплачено],		0) as float) +
				cast(isnull(a.ПениУплачено,				0) as float) +
				cast(isnull(a.ГосПошлинаУплачено,		0) as float) -
				cast(isnull(a.ПереплатаУплачено,		0) as float) +
				cast(isnull(a.ПереплатаНачислено,		0) as float) as pay_total,

				a.ContractEndDate as end_date

				from Reports.dbo.dm_CMRStatBalance_2 a

				where a.d <= @v_dt_to
				and a.d >= cast(a.ContractStartDate as date) 
				and a.d >= @v_dt_from
				and a.external_id is not null
			) cmr where row_nn = 1


	set @vinfo = concat('Rowcount = ',@@ROWCOUNT)

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @srcname, @vinfo;
			

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'update Risk.portf_cmr';

	begin transaction

		update Risk.portf_cmr set principal_rest = 0 where principal_rest < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set principal_rest = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set percents_rest  = 0 where percents_rest  < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set percents_rest  = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set fines_rest     = 0 where fines_rest     < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set fines_rest     = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set other_rest     = 0 where other_rest     < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set other_rest     = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set total_rest = principal_rest + percents_rest + fines_rest + other_rest where r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set overdue_amount = 0 where overdue_amount < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr set overdue_amount = (case when overdue_amount > total_rest then total_rest else overdue_amount end) where r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_cmr 
		set overdue_days = 0, 
			dpd_bucket_360 = '[01] 0',
			dpd_bucket_720 = '[01] 0'
		where r_date >= end_date
		and end_date is not null
		and r_date between @v_dt_from and @v_dt_to
		;


	commit transaction;

	/****************** МФО *******************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'delete from Risk.portf_mfo';

	begin transaction

		delete from RiskDWH.Risk.portf_mfo
		where r_date between @v_dt_from and @v_dt_to
		;

	set @vinfo = concat('Rowcount = ',@@ROWCOUNT)

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @srcname, @vinfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'insert into Risk.portf_mfo';
	
	begin transaction

		insert into RiskDWH.Risk.portf_mfo
		select r_date, external_id, closed, dpd_bucket_360, dpd_bucket_720, dpd_bucket_720_p, overdue_days, overdue_days_p
			, principal_rest, percents_rest, fines_rest, other_rest, overdue_amount, total_rest, pay_total, pay_total_alt, end_date
		from (
			select
				ROW_NUMBER() over(partition by a.external_id, a.d order by ПениНачислено) as row_nn,
				d as r_date,
				external_id,
				0 as closed,
				RiskDWH.dbo.get_bucket_360(dpd_coll) as dpd_bucket_360,
				RiskDWH.dbo.get_bucket_720(dpd_coll) as dpd_bucket_720,
				RiskDWH.dbo.get_bucket_720(dpd_p_coll) as dpd_bucket_720_p,                     
				isnull(dpd_coll,  0)                        as overdue_days,
				isnull(dpd_p_coll,0)                        as overdue_days_p,

				cast(isnull([остаток од], 0) as float) as principal_rest,
				cast(isnull([остаток %], 0) as float)         as percents_rest,
				cast(isnull([остаток пени], 0) as float)            as fines_rest,
				cast(isnull([остаток иное (комиссии, пошлины и тд)], 0) as float)   as other_rest,
				cast(isnull(overdue, 0) as float)               as overdue_amount,
				cast(0 as float) as total_rest,
				pay_total,          
				cast(isnull(principal_cnl,    0) as float) + cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total_alt,
				cast(NULL as date) as end_date 
			from dwh2.dbo.dm_CMRStatBalance a
			where d <= @v_dt_to
				and a.d >= cast(a.ContractStartDate as date)	   
				and d >= @v_dt_from
			) p where row_nn = 1

	set @vinfo = concat('Rowcount = ', @@ROWCOUNT)

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @srcname, @vinfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_mfo_principal_wo';

		
		drop table if exists #stg_mfo_principal_wo;

		select external_id, d as cdate,  cast(([основной долг уплачено] - [ОД уплачено без Сторно по акции]) as float) as principal_wo
		into #stg_mfo_principal_wo
		from dwh2.dbo.dm_CMRStatBalance a
		where a.d <= @v_dt_to
			and a.d >= cast(a.ContractStartDate as date)
			and cast(([основной долг уплачено] - [ОД уплачено без Сторно по акции]) as float) > 0		
		;
		
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_mfo_principal_rest';


		drop table if exists #stg_mfo_principal_rest;

		select a.r_date, a.external_id, a.principal_rest - sum(isnull(b.principal_wo,0)) as principal_rest
		into #stg_mfo_principal_rest
		from Risk.portf_mfo a
		left join #stg_mfo_principal_wo b
		on a.external_id = b.external_id
		and a.r_date >= b.cdate

		where exists (select 1 from #stg_mfo_principal_wo c
			where a.external_id = c.external_id)
		and a.closed = 0
		and a.r_date >= @v_dt_from
		and a.r_date <= @v_dt_to
		group by a.r_date, a.external_id, a.principal_rest;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'merge into Risk.portf_mfo';

	begin transaction

		merge into Risk.portf_mfo dst 
		using #stg_mfo_principal_rest src
		on (dst.external_id = src.external_id and dst.r_date = src.r_date)
		when matched then update set
		dst.principal_rest = src.principal_rest;

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'update Risk.portf_mfo';

	begin transaction

		update Risk.portf_mfo set principal_rest = 0 where principal_rest < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set principal_rest = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set percents_rest  = 0 where percents_rest  < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set percents_rest  = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set fines_rest     = 0 where fines_rest     < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set fines_rest     = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set other_rest     = 0 where other_rest     < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set other_rest     = 0 where closed = 1			 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set total_rest = principal_rest + percents_rest + fines_rest + other_rest where r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set overdue_amount = 0 where overdue_amount < 0.01 and r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo set overdue_amount = (case when overdue_amount > total_rest then total_rest else overdue_amount end) where r_date between @v_dt_from and @v_dt_to;
		update Risk.portf_mfo
		set overdue_days = 0, 
			dpd_bucket_360 = '[01] 0',
			dpd_bucket_720 = '[01] 0'
		where r_date >= end_date
		and end_date is not null
		and r_date between @v_dt_from and @v_dt_to
		;


	commit transaction;




	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'update risk.bezz_cess_reestr';



		--реестр цессий беззалога
		-- +цессия на залог
	drop table if exists #bezz_cess_reestr;
	with base as (
		select b.Код as external_id, 
		b.Клиент as client_cmr_id,
		b.IsInstallment,
		dateadd(yy,-2000,a.Период) as dt_status,  
		c.Наименование as cred_status,
		ROW_NUMBER() over (partition by b.Код order by a.Период desc) as rown
		from stg._1cCMR.РегистрСведений_СтатусыДоговоров a
		inner join stg._1cCMR.Справочник_Договоры b
		on a.Договор = b.Ссылка
		inner join stg._1cCMR.Справочник_СтатусыДоговоров c
		on a.Статус = c.Ссылка
	)
	select a.external_id, cast(a.dt_status as date) as cess_dt
	into #bezz_cess_reestr
	from base a
	where a.rown = 1
	/*updated 06.03.2026*/
	--and a.IsInstallment = 1
	--and a.dt_status >= '2024-04-01'
	and a.cred_status = 'Продан'
	and a.external_id not in ('22010620190436') --косяк
	;



	begin transaction

	delete from risk.bezz_cess_reestr;
	with base as (
		select 
		a.external_id, a.cess_dt, 
		cast(isnull(b.principal_cnl,0) as float) + cast(isnull(b.percents_cnl,0) as float) + cast(isnull(b.fines_cnl,0) as float) as cess_rev_total,
		cast(isnull(c.[остаток од],0) as float) as od,
		cast(isnull(c.[остаток %],0) as float) as interest,
		cast(isnull(c.[остаток пени],0) as float) as fines,
		cast(isnull(c.[остаток од],0) as float) + cast(isnull(c.[остаток %],0) as float) + cast(isnull(c.[остаток пени],0) as float) as gross
		from #bezz_cess_reestr a
		left join dwh2.dbo.dm_CMRStatBalance b with (nolock)
		on a.external_id = b.external_id
		and a.cess_dt = b.d
		left join dwh2.dbo.dm_CMRStatBalance c with (nolock)
		on a.external_id = c.external_id
		and a.cess_dt = dateadd(dd,1,c.d)
	)
	insert into risk.bezz_cess_reestr
	select a.external_id, a.cess_dt, 
	a.cess_rev_total,
	a.od,
	a.interest,
	a.fines,
	a.gross,
	round(a.cess_rev_total / a.gross,3) as cess_price,
	round(a.od * (a.cess_rev_total / a.gross),2) as cess_rev_od,
	round(a.interest * (a.cess_rev_total / a.gross),2) as cess_rev_int,
	round(a.fines * (a.cess_rev_total / a.gross),2) as cess_rev_fines,
	round(a.od * (1.0 - (a.cess_rev_total / a.gross)),2) as cess_wo_od,
	round(a.interest * (1.0 - (a.cess_rev_total / a.gross)),2) as cess_wo_int,
	round(a.fines * (1.0 - (a.cess_rev_total / a.gross)),2) as cess_wo_fines
	from base a
	;


	--выручка от цессии беззалог
	--+залог
	update b set 
	b.pay_total = case when a.cess_dt = b.r_date then a.cess_rev_od + a.cess_rev_int + a.cess_rev_fines else 0 end, 
	b.pay_total_alt = case when a.cess_dt = b.r_date then a.cess_rev_od else 0 end
	from risk.bezz_cess_reestr a
	inner join risk.portf_mfo b
	on a.external_id = b.external_id
	and a.cess_dt <= b.r_date;






	commit transaction;










	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Drop temp (#) tables';

	drop table #stg_mfo_principal_rest;
	drop table #stg_mfo_principal_wo;
	drop table #bezz_cess_reestr;
	   	  

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

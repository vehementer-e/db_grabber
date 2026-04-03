/******************************************************************************************************
Расчет основы для PD для продукта беззалог

Revisions:
dt			user				version		description
20/09/24	datsyplakov			v1.0		Создание процедуры. ТОЛЬКО installment, без PDL

*****************************************************************************************************/



CREATE procedure [Risk].[prc$calc_PD_base_bezzalog] 
--дата резервов
@repdate date,


--реестр кредитных каникул
----0: НЕ исключаем кк
----1: исключаем по реестру от 14/07/2020 (dbo.det_cred_hol_140720_v3)
----2: исключаем по реестру от 19/08/2020 (dbo.det_cred_hol_190820)
----3: исключаем по реестру от 18/09/2020 (dbo.det_cred_holid_180920)
----4: исключаем по реестру reports.dbo.DWH_694_credit_vacation_cmr
----5: исключаем по реестру из Space + reports.dbo.DWH_694_credit_vacation_cmr
@flagkk smallint = null,

--дополнительая информация
@addinfo varchar(100) = null


as

begin try

	declare @srcname varchar(100) = 'Calc PD base for BEZZALOG';


	if @flagkk is null set @flagkk = 5;


	/******************* ОПЦИИ *******************/

	--дата, с которой брать ЦМР
	declare @cmr_point date = cast('2020-02-01' as date);

	--коэффициент залогового покрытия
	declare @pledge_cover float;

	

	declare @v int;

	set @v = isnull((select max(vers) + 1 from risk.prov_stg_bezz_PD
			where rep_dt = @repdate
			and vers > 0			
			) , 1);


	--для логирования

	declare @vinfo varchar(500) = 'START REPDT = ' 
							+ convert(varchar(10),@repdate, 120) 
							+ ', VERS = ' + cast(@v as varchar(2))
							+ ', FLAGKK = ' + cast(@flagkk as varchar(1))
							+ case when @addinfo is not null then ', ADDINFO = ' + @addinfo else '' end;

	exec dbo.prc$set_debug_info @src = @srcname, 
						@info = @vinfo;


	/*** PART 0 (credit holidays) ***/

	exec dbo.prc$set_debug_info @src = @srcname, 
						@info = 'PART 0 Credit Holidays';

	--кредитные каникулы

	drop table if exists #stg_kk;

	create table #stg_kk (external_id varchar(255));

	if @flagkk = 1 
	begin 
	insert into #stg_kk
	select a.external_id
	from dbo.det_cred_hol_140720_v3 a
	end

	if @flagkk = 2
	begin
	insert into #stg_kk
	select a.external_id
	from dbo.det_cred_hol_190820 a
	end

	if @flagkk = 3
	begin 
	insert into #stg_kk
	select a.Договор
	from dbo.det_cred_holid_180920 a
	where @repdate between a.Период and a.ДатаОкончания
	end 

	if @flagkk = 4
	begin
	insert into #stg_kk
	select a.Договор
	from reports.dbo.DWH_694_credit_vacation_cmr a
	where @repdate between a.Период and a.ДатаОкончания
	end

	if @flagkk = 5
	begin

	with kk_space as (
	select a.Number as external_id, 
	isnull(cast(a.CreditVacationDateBegin as date), cast(b.Период as date)) as dt_from, 
	cast(a.CreditVacationDateEnd	  as date) as dt_to
	from stg._Collection.Deals a
	left join Reports.dbo.DWH_694_credit_vacation_cmr b
	on a.Number = b.Договор
	where 1=1
	and a.CreditVacationDateEnd is not null
	), base as (
	select k.external_id, k.dt_from, k.dt_to
	from kk_space k
	union all
	select c.Договор as external_id, c.Период as dt_from, c.ДатаОкончания as dt_to
	from Reports.dbo.DWH_694_credit_vacation_cmr c
	where not exists (select 1 from kk_space kk
			where c.Договор = kk.external_id)
	) 
	insert into #stg_kk 
	select b.external_id
	from base b
	where @repdate between b.dt_from and b.dt_to

	end






	/*** PART 2 (0-90)***/

	exec dbo.prc$set_debug_info @src = @srcname, 
						@info = 'ROLL RATES';

	/****************** портфели на конец месяца ******************/

	begin transaction;


		delete from risk.prov_stg_bezz_PD where rep_dt = @repdate and vers = @v;

		with base as (
			select a.r_date as date_on, a.dpd_bucket_360 as bucket, sum(a.principal_rest) as portf 
			from Risk.portf_mfo a
			where a.r_date < @cmr_point
			and a.r_date = EOMONTH(a.r_date)
			and a.r_date <= @repdate
			and a.dpd_bucket_360 in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90','[05] 91-120')
			--удаляем кредитные каникулы
			and not exists (select 1 from #stg_kk kk where a.external_id = kk.external_id)
			-- Installment
			and exists (select 1 from dwh2.risk.credits cr where a.external_id = cr.external_id and cr.IsInstallment = 1 and cr.credit_type_init <> 'PDL')
			group by a.r_date, a.dpd_bucket_360
		union all	
			select a.d as date_on, RiskDWH.dbo.get_bucket_360(a.dpd) as bucket, sum(a.[остаток од]) as portf 
			from dwh2.dbo.dm_cmrstatbalance a
			where a.d >= @cmr_point
			and a.d = EOMONTH(a.d)
			and a.d <= @repdate
			and RiskDWH.dbo.get_bucket_360(a.dpd) in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90','[05] 91-120')
			--удаляем кредитные каникулы
			and not exists (select 1 from #stg_kk kk where a.external_id = kk.external_id)
			-- Installment
			and exists (select 1 from dwh2.risk.credits cr where a.external_id = cr.external_id and cr.IsInstallment = 1 and cr.credit_type_init <> 'PDL')
			group by a.d, RiskDWH.dbo.get_bucket_360(a.dpd)
		)
		insert into risk.prov_stg_bezz_PD
		select @repdate as rep_dt, @v as vers, cast(sysdatetime() as datetime) as dt_dml, b.date_on, b.bucket, b.portf
		from base b
		;


	commit transaction;

	
	exec dbo.prc$set_debug_info @src = @srcname, 
						@info = 'FINISH';



end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

/**************************************************************************
Скрипт для расчёта всех денежных потоков по клиенту

Revisions:
dt				user				version		description
2026.02.26		golicyn				v1.0		Создание процедуры

*************************************************************************/

CREATE procedure [Risk].[prc$calc_Client_LTV]

--@input_gen_mm date = '2012-11-30',
@input_gen_mm date = '2012-11-30',
@input_gen_to date = '2026-02-28'

AS

begin try

	declare @srcname varchar(100) = '[Risk].[prc$calc_Client_LTV]';
	declare @vinfo varchar(1000) = 'START';
	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	-------------------------------------------------------------------------------------------------------
	------------------------------------- BEGIN -----------------------------------------------------------
	
	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Start. truncate table RiskDWH.Risk.Temp_Client_CF_stg1';

	truncate table RiskDWH.Risk.Temp_Client_CF_stg1;

	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Finish. truncate table RiskDWH.Risk.Temp_Client_CF_stg1';

	declare @gen_mm date
			, @gen_to date
			, @rdt date

	set @gen_mm = EOMONTH(@input_gen_mm, 0)
	set @gen_to = EOMONTH(@input_gen_to, 0)
	set @rdt = EOMONTH(@input_gen_to, 0)
	;
	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Start. drop table if exists RiskDWH.Risk.Temp_Persons_stg1';
	drop table if exists RiskDWH.Risk.Temp_Persons_stg1
	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Finish. drop table if exists RiskDWH.Risk.Temp_Persons_stg1';
	;

	--187,838 --> 130,881
	select *
	into RiskDWH.Risk.Temp_Persons_stg1--select distinct credit_type
	from (
		select external_id, credit_id, person_id, cast(amount as float) as amount, term
			, EOMONTH(generation, 0) as gen
			, cast(factenddate as date) as factenddate
			, credit_type, rbp_gr
			, startdate
			, case when upper(credit_type) like 'PTS%' then 'PTS'
					when upper(credit_type) like 'AUTO%' then 'AC'
					when upper(credit_type) like 'BIGINST%' then 'Big Inst'
					when upper(credit_type) like 'PDL%' then 'PDL'
					when upper(credit_type) like 'INST%' then 'INST' else credit_type end
				as Prod_L2
			, case when upper(credit_type) like 'PTS%' then 'Залог'
					when upper(credit_type) like 'AUTO%' then 'Залог'
					when upper(credit_type) like 'BIGINST%' then 'Беззалог'
					when upper(credit_type) like 'PDL%' then 'Беззалог'
					when upper(credit_type) like 'INST%' then 'Беззалог' else credit_type end
				as Prod_L1
			, ROW_NUMBER() over(partition by person_id order by startdate) as row_nn
			, count(*) over(partition by person_id) as cnt
			--select top 100 *
		from dwh2.risk.credits cr
		) t where 1 = 1
	;
	--select top 100 * from RiskDWH.Risk.Temp_Persons_stg1


	WHILE @gen_mm <= @gen_to

	BEGIN

		----------------------------------------------------------------------------------
		-- 1. Deal List by 1st issues
		----------------------------------------------------------------------------------
		
		exec dbo.prc$set_debug_info @src = @srcname, @info = 'Start. drop table if exists RiskDWH.Risk.Temp_Person_Deals_stg1';
		drop table if exists RiskDWH.Risk.Temp_Person_Deals_stg1
		exec dbo.prc$set_debug_info @src = @srcname, @info = 'Finish. drop table if exists RiskDWH.Risk.Temp_Person_Deals_stg1';
		;
		select t2.external_id as fst_external_id
			, t2.credit_id as fst_credit_id
			, t2.amount as fst_amount
			, t2.term as fst_term
			, t2.gen as fst_gen
			, t2.factenddate as fst_factenddate
			, t2.credit_type as fst_credit_type
			, t2.rbp_gr as fst_rbp_gr
			, t2.startdate as fst_startdate
			, t2.Prod_L2 as fst_Prod_L2
			, t2.Prod_L1 as fst_Prod_L1
			, t1.*

		into RiskDWH.Risk.Temp_Person_Deals_stg1--select top 100 *

		from RiskDWH.Risk.Temp_Persons_stg1 t1
		join (
			select *
			from RiskDWH.Risk.Temp_Persons_stg1 r where 1 = 1
				and eomonth(gen, 0) = EOMONTH(@gen_mm, 0)
				--and r.person_id = 0x8009DB68E0E286F4485B85495BEA1287
				and row_nn = 1
			) t2 on t1.person_id = t2.person_id
		;
		--select * from RiskDWH.Risk.Temp_Person_Deals_stg1
		--;

		----------------------------------------------------------------------------------
		-- 3.1. Write offs (Collection actions)
		----------------------------------------------------------------------------------
		exec dbo.prc$set_debug_info @src = @srcname, @info = 'Start. drop table if exists RiskDWH.Risk.Temp_Person_woffs_stg1';
		drop table if exists RiskDWH.Risk.Temp_Person_woffs_stg1
		exec dbo.prc$set_debug_info @src = @srcname, @info = 'Finish. drop table if exists RiskDWH.Risk.Temp_Person_woffs_stg1';
		;
		select r.person_id
			, woff.external_id, woff.r_date, woff.od_wo, woff.int_wo
		into RiskDWH.Risk.Temp_Person_woffs_stg1
		--select *
		from RiskDWH.Risk.stg_fcst_writeoff woff
		join RiskDWH.Risk.Temp_Person_Deals_stg1 r on woff.external_id = r.external_id
		where 1 = 1
			and woff.r_date <= @rdt
		;
		--select * from RiskDWH.Risk.Temp_Person_woffs_stg1
		--;
		----------------------------------------------------------------------------------
		-- 4.1. CF by MoBs
		----------------------------------------------------------------------------------
		--drop table if exists RiskDWH.Risk.Temp_Client_CF_stg1;

		--truncate table RiskDWH.Risk.Temp_Client_CF_stg1;

		set @vinfo = 'Insert for gen = ' + cast(@gen_mm as nvarchar(15))
		;
		exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo
		;
		--select top 100 * from RiskDWH.Risk.Temp_Client_CF_stg1

		insert into RiskDWH.Risk.Temp_Client_CF_stg1

		select 
				--person_id,
				fst_rbp_gr
				, fst_credit_type
				, EOMONTH(fst_startdate, 0) as First_Gen
				--, startdate, factenddate, r_date
				--, eom_r_date
				, Client_DoB, Client_MoB		
				, PMT_CODE, PMT_DESC

				, sum(CF_RUB) as Cash_Flow
				, getdate() as dt_dml
				, count(distinct person_id) as CNT_Clients
				, count(distinct external_id) as CNT_Deals
	
		--into RiskDWH.Risk.Temp_Client_CF_stg1
	
		from (
		select
			r.person_id
			, r.fst_startdate
			, r.fst_rbp_gr
			, r.fst_credit_type
			, r.external_id
			, EOMONTH(r.startdate, 0) as eom_r_date
			, DATEDIFF(DD, r.fst_startdate, r.startdate) as Client_DoB
			, DATEDIFF(MM, r.fst_startdate, r.startdate) as Client_MoB
		
			, 1 as PMT_CODE
			, 'amt_issue' as PMT_DESC
			, - amount as CF_RUB

		from RiskDWH.Risk.Temp_Person_Deals_stg1 r
	
		union all

		select
			r.person_id
			, r.fst_startdate
			, r.fst_rbp_gr
			, r.fst_credit_type
			, r.external_id
			, EOMONTH(b.d, 0) as eom_r_date
			, DATEDIFF(DD, r.fst_startdate, b.d) as Client_DoB
			, DATEDIFF(MM, r.fst_startdate, b.d) as Client_MoB
		
			, 2 as PMT_CODE
			, 'Доп.продукты' as PMT_DESC
			, СуммаДопПродуктов as CF_RUB

		from dwh2.dbo.dm_cmrstatbalance b (nolock)
		join RiskDWH.Risk.Temp_Person_Deals_stg1 r on b.external_id = r.external_id
		where b.d = b.ContractStartDate
			and СуммаДопПродуктов > 0
			and b.d <= @rdt
	
		union all

		select
			r.person_id
			, r.fst_startdate
			, r.fst_rbp_gr
			, r.fst_credit_type
			, r.external_id
			, EOMONTH(b.d, 0)
			, DATEDIFF(DD, r.fst_startdate, b.d)
			, DATEDIFF(MM, r.fst_startdate, b.d)
		
			, 3 as PMT_CODE
			, 'ОД' as PMT_DESC
			, principal_cnl as CF_RUB

		from dwh2.dbo.dm_cmrstatbalance b (nolock)
		join RiskDWH.Risk.Temp_Person_Deals_stg1 r on b.external_id = r.external_id
			and principal_cnl > 0
			and b.d <= @rdt
	
		union all

		select
			r.person_id
			, r.fst_startdate
			, r.fst_rbp_gr
			, r.fst_credit_type
			, r.external_id
			, EOMONTH(b.d, 0) as eom_r_date
			, DATEDIFF(DD, r.fst_startdate, b.d) as Client_DoB
			, DATEDIFF(MM, r.fst_startdate, b.d) as Client_MoB
		
			, 4 as PMT_CODE
			, '%%' as PMT_DESC
			, percents_cnl as CF_RUB

		from dwh2.dbo.dm_cmrstatbalance b (nolock)
		join RiskDWH.Risk.Temp_Person_Deals_stg1 r on b.external_id = r.external_id
			and percents_cnl > 0
			and b.d <= @rdt
	
		union all

		select
			r.person_id
			, r.fst_startdate
			, r.fst_rbp_gr
			, r.fst_credit_type
			, r.external_id
			, EOMONTH(b.d, 0) as eom_r_date
			, DATEDIFF(DD, r.fst_startdate, b.d) as Client_DoB
			, DATEDIFF(MM, r.fst_startdate, b.d) as Client_MoB
		
			, 5 as PMT_CODE
			, 'Пени' as PMT_DESC
			, fines_cnl as CF_RUB

		from dwh2.dbo.dm_cmrstatbalance b (nolock)
		join RiskDWH.Risk.Temp_Person_Deals_stg1 r on b.external_id = r.external_id
			and fines_cnl > 0
			and b.d <= @rdt
	
		union all

		select
			r.person_id
			, r.fst_startdate
			, r.fst_rbp_gr
			, r.fst_credit_type
			, r.external_id
			, EOMONTH(b.d, 0) as eom_r_date
			, DATEDIFF(DD, r.fst_startdate, b.d) as Client_DoB
			, DATEDIFF(MM, r.fst_startdate, b.d) as Client_MoB
		
			, 6 as PMT_CODE
			, 'Комиссии, пошлины и тд' as PMT_DESC
			, otherpayments_cnl as CF_RUB

		from dwh2.dbo.dm_cmrstatbalance b (nolock)
		join RiskDWH.Risk.Temp_Person_Deals_stg1 r on b.external_id = r.external_id
			and otherpayments_cnl > 0
			and b.d <= @rdt

			) p1
		where 1 = 1
		group by
				--person_id,
				fst_rbp_gr
				, fst_credit_type
				, EOMONTH(fst_startdate, 0)
				, Client_DoB, Client_MoB		
				, PMT_CODE, PMT_DESC
		;

		set @gen_mm = eomonth(@gen_mm, 1)
		;
		exec dbo.prc$set_debug_info @src = @srcname, @info = 'Next iteration';
	END
	;
	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Cycle is finished';

-------------------------------------  END  ---------------------------------------------
-----------------------------------------------------------------------------------------


end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

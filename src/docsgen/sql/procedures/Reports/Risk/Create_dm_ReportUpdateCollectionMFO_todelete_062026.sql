


--exec [Risk].[Create_dm_ReportUpdateCollectionMFO]


CREATE PROC [Risk].[Create_dm_ReportUpdateCollectionMFO] as

--SET NOCOUNT ON
SET XACT_ABORT ON

SET DATEFIRST 1	  


declare 
@month_days int, 
@src_name nvarchar(100),
@rdt date;

set @month_days = day(eomonth(dateadd(dd,-1,cast(getdate() as date))));
set @src_name = 'UPDATE_REP_COLL_MFO';
set @rdt = cast(dateadd(dd,-1,sysdatetime()) as date);

begin try 

	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY MFO/CMR - START';

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'START';

	

	drop table if exists #CMR;

	select 
		a.d as r_date, 
		a.r_day,
		a.r_month,
		a.r_year,
		a.external_id,
		a.dpd_coll as overdue_days, 
		a.dpd_p_coll as overdue_days_p, 
		a.dpd_last_coll as last_dpd,
		a.bucket_coll as dpd_bucket,
		a.bucket_p_coll as dpd_bucket_p,
		a.[остаток од] as principal_rest,
		cast(isnull(a.principal_cnl,    0) as float) +
    	cast(isnull(a.percents_cnl,     0) as float) +
    	cast(isnull(a.fines_cnl,        0) as float) +
    	cast(isnull(a.otherpayments_cnl,0) as float) +
    	cast(isnull(a.overpayments_cnl, 0) as float) - 
		cast(isnull(overpayments_acc, 0) as float) as pay_total,
		isnull([сумма поступлений], 0) as pay_total_calc
		into #CMR
	from dwh2.dbo.dm_CMRStatBalance a
	where a.d >= '2023-01-01' and a.d <= @rdt;

--Бизнес-займы
	insert into #CMR
	select  a.r_date, 
			null as r_day,
			null as r_month,
			null as r_year,
			a.external_id,
			a.overdue_days, 
			a.overdue_days_p, 
			a.last_dpd,
			a.dpd_bucket,
			a.dpd_bucket_p,
			a.principal_rest,
			null,
			0
	from RiskDWH.dbo.det_business_loans a;

	drop index if exists tmp_cmr_idx on #CMR;
	create clustered index tmp_cmr_idx on #CMR (external_id, r_date);


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_hard90_1';
	
	--1) отбираем входы и выходы в 91+
	drop table if exists #stg_hard90_1;

	select aa.external_id, aa.r_date , aa.stage
	into #stg_hard90_1
	from (
		select b.external_id, b.r_date, 'OUT_91+' as stage
		from #CMR b
		where b.overdue_days_p >= 91 and b.overdue_days < 91 
		and b.r_date <= @rdt

		union all

		select b.external_id, b.r_date, 'IN_91+' as stage
		from #CMR b
		where b.overdue_days >= 91 and b.last_dpd < 91
		and b.r_date <= @rdt
	) aa

	;
	--1min

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_hard90_2';


	--2) отбираем даты нахождения между 91+
	drop table if exists #stg_hard90_2;

	with base as (
	select a.external_id, a.r_date, a.stage,
	case when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) = 'IN_91+' 
	then dateadd(dd,1,a.r_date)
	when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) is null 
	then dateadd(dd,1,a.r_date)
	end as dt_from,

	case when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) = 'IN_91+' 
	then dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id order by a.r_date))
	when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) is null 
	then @rdt
	end as dt_to

	from #stg_hard90_1 a
	)

	select bs.external_id, bs.dt_from, bs.dt_to 

	into #stg_hard90_2

	from base bs
	where bs.stage = 'OUT_91+'
	and bs.dt_from is not null
	and bs.dt_to is not null;


	--0min

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_hard90_31';


	--3) проверяем, что во время периодов между 91+ не было выхода в нулевой бакет
	----3.1) находим периоды, кодга был нулевой бакет
	drop table if exists #stg_hard90_31;

	select distinct a.external_id, a.dt_from, a.dt_to

	into #stg_hard90_31

	from #stg_hard90_2 a

	left join #CMR b
	on a.external_id = b.external_id
	and b.r_date between a.dt_from and a.dt_to
	where b.overdue_days = 0;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_hard90_32';

	----3.2) исключаем периоды с нулевым бакетом
	drop table if exists #stg_hard90_32;

	select a.external_id, a.dt_from, a.dt_to

	into #stg_hard90_32

	from #stg_hard90_2 a
	where not exists (
	select 1 from #stg_hard90_31 b
	where a.external_id = b.external_id
	and a.dt_from = b.dt_from
	and a.dt_to = b.dt_to
	)


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_hard90_4';

	--4) проверяем, чтобы были платежи во время периодов между 91+
	--собираем все платежи в данные периоды
	drop table if exists #stg_hard90_4;

	select a.external_id, a.dt_from, a.dt_to, b.r_date, b.pay_total
	into #stg_hard90_4
	from #stg_hard90_32 a
	left join #CMR b
	on a.external_id = b.external_id
	and b.r_date between a.dt_from and a.dt_to
	and b.pay_total > 0;

	
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_hard90_5';


	--5) финальный реестр 0-90 hard
	drop table if exists #stg_hard90_5;

	select a.external_id, a.dt_from, a.dt_to

	into #stg_hard90_5

	from #stg_hard90_32 a
	where exists (select 1 
	from #stg_hard90_4 b
	where a.external_id = b.external_id
	and a.dt_from = b.dt_from
	and a.dt_to = b.dt_to
	and b.pay_total > 0);




	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_product';

---------обновленный справочник продуктов 01.11.2024--------------
	drop table if exists #stg_product;
	select a.Код as external_id, 
		case 
		when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) like ('%installment%') then 'Installment'
		when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) like ('%pdl%') then 'Pdl'
		else 'PTS' end product
		--case when cmr_ПодтипыПродуктов.Наименование = 'Pdl' THEN 'INSTALLMENT'
		--	 when a.IsInstallment = 1 then 'INSTALLMENT'
		--else 'PTS' end as product
	into #stg_product
	from stg._1cCMR.Справочник_Договоры a
	LEFT JOIN Stg._1cCMR.Справочник_Заявка cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
	LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка;



	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#mfo_base';


	--основа для построения отчетов
	drop table if exists #mfo_base;

		select aa.external_id, aa.r_date, 
		aa.dpd_bucket_p_alt as dpd_bucket_p_,
		aa.dpd_bucket_alt as dpd_bucket_to_,
		aa.pay_total, aa.dpd_bucket_p_cmr,
		aa.r_day, aa.r_month, aa.r_year, aa.overdue_days_p as overdue_days_p_cmr,
		aa.dpd_bucket_cmr,
		aa.product

		into #mfo_base
		from (

		select b.external_id, b.r_date, b.pay_total, 

		case when c.external_id is not null and b.overdue_days_p <= 90
		then '[09] 0-90 hard' 
		else b.dpd_bucket_p end as dpd_bucket_p_alt,

		case when c.external_id is not null and b.overdue_days <= 90 		
		then '[09] 0-90 hard' 
		else b.dpd_bucket end as dpd_bucket_alt,
		
		isnull(b.overdue_days_p,0) as overdue_days_p,
		b.dpd_bucket_p as dpd_bucket_p_cmr,
		b.dpd_bucket as dpd_bucket_cmr,
		b.r_day, b.r_month, b.r_year,
		isnull(d.product, 'PTS') as product
		
		from #CMR b
		
		left join #stg_hard90_5 c
		on b.external_id = c.external_id
		and b.r_date between dateadd(dd,-1,c.dt_from) and c.dt_to

		left join #stg_product d
		on b.external_id = d.external_id

		where b.r_date between  dateadd(yy,-1,dateadd(dd,1,eomonth(@rdt,-1))) and EOMONTH(@rdt,-12)

		union all
		
		select b.external_id, b.r_date, b.pay_total, 
		
		case when c.external_id is not null and b.overdue_days_p <= 90
		then '[09] 0-90 hard' 
		else b.dpd_bucket_p end as dpd_bucket_p_alt,

		case when c.external_id is not null and b.overdue_days <= 90 		
		then '[09] 0-90 hard' 
		else b.dpd_bucket end as dpd_bucket_alt,

		isnull(b.overdue_days_p,0) as overdue_days_p,
		b.dpd_bucket_p as dpd_bucket_p_cmr,
		b.dpd_bucket as dpd_bucket_cmr,
		b.r_day, b.r_month, b.r_year,

		isnull(d.product,'PTS') as product

		from #CMR b

		left join #stg_hard90_5 c
		on b.external_id = c.external_id
		and b.r_date between dateadd(dd,-1,c.dt_from) and c.dt_to

		left join #stg_product d
		on b.external_id = d.external_id

		where b.r_date between dateadd(dd,1,EOMONTH(@rdt,-2)) and @rdt
		)  aa

		;


	--30/10/2020 - учет каникул с октября 2020
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'CredVacations';

	merge into #mfo_base dst 
	using (
		select a.external_id, a.r_date, c.dpd_bucket_p as dpd_bucket, c.overdue_days_p as dpd
		from #mfo_base a
		inner join RiskDWH.dbo.det_kk_cmr_and_space b
		on a.external_id = b.external_id
		and a.r_date between b.dt_from and b.dt_to
		left join #CMR c
		on a.external_id = c.external_id
		and b.dt_from = c.r_date
		where 1=1
		--and a.r_date between '2020-10-01' and '2020-10-31'
		and EOMONTH(a.r_date) = EOMONTH(dateadd(dd,1,b.dt_from))		
		and a.pay_total > 0
	) src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set 
		dst.dpd_bucket_p_ = src.dpd_bucket,
		dst.dpd_bucket_to_ = src.dpd_bucket,
		dst.dpd_bucket_p_cmr = src.dpd_bucket,
		dst.dpd_bucket_cmr = src.dpd_bucket,
		dst.overdue_days_p_cmr = src.dpd
		;


	--26/11/20 Для учета платежей на стадии СБ (служба безопасности) в бакетах до 90+, которые в работе у Hard/Legal
	--10/12/20 Платежи из стадии Closed, перед закрытием была стадия СБ
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_sb_0_90';


	drop table if exists #stg_sb_0_90;
	
	select a.external_id, a.r_date
	into #stg_sb_0_90
	from #mfo_base a
	inner join RiskDWH.dbo.stg_client_stage b
	on a.external_id = b.external_id
	and a.r_date = b.cdate
	left join RiskDWH.dbo.stg_client_stage bb
	on a.external_id = bb.external_id
	and a.r_date = dateadd(dd,1,bb.cdate)
	inner join Stg._Collection.Deals_history c
	on a.external_id = c.Number
	and a.r_date = c.r_date
	inner join stg._Collection.DealStatus d
	on c.IdStatus = d.Id
	where 1=1
	--стадия СБ
	and (b.CRMClientStage = 'СБ' or /*10/12/2020*/ bb.CRMClientStage = 'СБ' and b.CRMClientStage = 'Closed')
	--был платеж
	and a.pay_total > 0
	--кроме бакетов, которые и так учитываются в 91+ или 0-90 Hard
	and a.dpd_bucket_p_ not in ('(5)_91_360','(6)_361+','[09] 0-90 hard')
	--статус договора на момент платежа Legal
	and d.[Name] = 'Legal'
	--была просрочка более 90 дней (соответственно стадия Legal)
	and exists (select 1 from #CMR e 
		where a.external_id = e.external_id
		and a.r_date > e.r_date
		and e.overdue_days_p > 90)
	--в день платежа не был у агента
	and not exists (select 2 from dwh_new.dbo.v_agent_credits f
		where a.external_id = f.external_id
		and a.r_date between f.st_date and f.end_date)
		;


	merge into #mfo_base dst
	using #stg_sb_0_90 src 
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set 
	dst.dpd_bucket_p_ = '[09] 0-90 hard';


	--отсечение 0-90 Hard
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#reestr_0_90_hard';


	drop table if exists #reestr_0_90_hard;
	select a.external_id, a.r_date, a.dpd_bucket_p_cmr, a.pay_total,
	b.CRMClientStage, 
	case when isnull(c.agent_name,'CarMoney') <> 'CarMoney' then 'KA'
	else 'CarMoney' end as agent_gr

	into #reestr_0_90_hard

	from #mfo_base a
	left join RiskDWH.dbo.stg_client_stage b
	on a.external_id = b.external_id
	and a.r_date = b.cdate
	left join dwh_new.dbo.v_agent_credits c
	on a.external_id = c.external_id
	and a.r_date between c.st_date and c.end_date
	where a.pay_total > 0
	and a.dpd_bucket_p_cmr in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	and (
		b.CRMClientStage = 'Legal' and a.dpd_bucket_p_cmr in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
		or b.CRMClientStage = 'Hard' and a.dpd_bucket_p_cmr in ('(2)_1_30','(3)_31_60','(4)_61_90')
		or isnull(c.agent_name,'CarMoney') not in ('CarMoney','ACB') /*in ('Povoljie','Alfa','Prime Collection','Ilma','MBA') */
				and a.dpd_bucket_p_cmr in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	)
	;


	merge into #mfo_base dst
	using #reestr_0_90_hard src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set dst.dpd_bucket_p_ = '[09] 0-90 hard';


		
	   	 	
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_isp_proiz';
	
	
	drop table if exists #stg_isp_proiz;
	select
	deals.Number as external_id,
	eo.Accepted, 
	cast(eo.AcceptanceDate as date) as accept_dt,


	eo.Id as enf_ord_id,
	cast(eo.CreateDate as date) as enf_ord_create_dt,
	cast(eo.UpdateDate as date) as enf_ord_upd_dt,
	replace(replace(eo.Number,' ',''),'№','') as enf_ord_number,
	
	
	ep.Id as enf_proc_id,
	cast(ep.CreateDate as date) as enf_proc_create_dt,
	cast(ep.UpdateDate as date) as enf_proc_upd_dt,
	null as EndDate, -- ep.EndDate,
	ep.CaseNumberInFSSP,

	jc.id as jud_claim_id,
	cast(jc.CreateDate as date) as jud_claim_cr_dt,
	cast(jc.UpdateDate as date) as jud_claim_upd_dt,

	jp.id as jud_proc_id,
	cast(jp.CreateDate as date) as jud_proc_cr_dt,
	cast(jp.UpdateDate as date) as jud_proc_upd_dt,


	cast(eo.Date as date) as isp_list_dt,
	cast(eo.ReceiptDate as date) as receipt_dt,
	cast(ep.ExcitationDate as date) as excitation_dt,
	
	null as adopt_bal_dt, -- cast(ep.AdoptionBalanceDate as date) as adopt_bal_dt,
	cast(ep.ApplicationDeliveryDate as date) as app_delivery_dt,
	null as arest_car_dt --cast(ep.ArestCarDate as date) as arest_car_dt

	into #stg_isp_proiz

	FROM [Stg].[_Collection].[EnforcementOrders]  eo
	left join [Stg].[_Collection].JudicialClaims jc
	On jc.id = eo.JudicialClaimId
	left join [Stg].[_Collection].JudicialProceeding jp
	on jp.Id = jc.JudicialProceedingId
	left join [Stg].[_Collection].Deals 
	on Deals.Id = jp.DealId
	left join [Stg].[_Collection].EnforcementProceeding ep 
	on eo.id=ep.EnforcementOrderId  ;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#isp_proiz';

	drop table if exists #isp_proiz;


	select aa.external_id, min(aa.total_dt_from) as dt_from

	into #isp_proiz

	from (
		select a.external_id,
		coalesce(  a.isp_list_dt, a.receipt_dt, a.app_delivery_dt, a.excitation_dt, a.accept_dt,
		a.jud_proc_cr_dt, a.jud_claim_cr_dt, a.enf_proc_create_dt, a.enf_ord_create_dt,
		a.jud_claim_upd_dt, a.jud_proc_upd_dt) as total_dt_from
		from #stg_isp_proiz a
		where 1=1
		and a.Accepted = 1
		) aa
	group by aa.external_id
		;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cli_con_stages';

	drop table if exists #stg1_cli_con_stages;
	
	select r.CMRContractNumber as external_id, r.CMRContractGUID, r.CRMClientGUID
	into #stg1_cli_con_stages
	from dwh_new.staging.CRMClient_references r
	where r.CMRContractNumber is not null
	and r.CRMClientGUID is not null
	;

	/*
	--OLD
	drop table if exists #stg2_cli_con_stages;
	select *
	into #stg2_cli_con_stages
	from dwh_new.Dialer.ClientContractStage cc
	where Cast(cc.created as DATE) between dateadd(dd,1,EOMONTH(@rdt,-2)) and @rdt	
	and cc.CRMClientStage = 'ИП'
  union all
	select *
	from dwh_new.Dialer.ClientContractStage cc
	where Cast(cc.created as DATE) between dateadd(yy,-1,dateadd(dd,1,eomonth(@rdt,-1))) and EOMONTH(@rdt,-12)
	and cc.CRMClientStage = 'ИП'
	;
	*/

	--DWH-2442
	drop table if exists #stg2_cli_con_stages;
	select *
	into #stg2_cli_con_stages
	from Stg._loginom.v_ClientContractStage_simple AS cc
	where cc.created between dateadd(dd,1,EOMONTH(@rdt,-2)) and @rdt	
	and cc.CRMClientStage = 'ИП'
  union all
	select *
	from Stg._loginom.v_ClientContractStage_simple AS cc
	where cc.created between dateadd(yy,-1,dateadd(dd,1,eomonth(@rdt,-1))) and EOMONTH(@rdt,-12)
	and cc.CRMClientStage = 'ИП'
	;


	drop table if exists #stg3_cli_con_stages;
	select bs.*, cast(cc.created as date) as date_on, cc.CMRContractStage, cc.CRMClientStage, 
	ROW_NUMBER() over (partition by bs.external_id,Cast(cc.created as DATE) order by cc.created desc) as rown
	
	into #stg3_cli_con_stages
	from #stg1_cli_con_stages bs
	inner join #stg2_cli_con_stages cc
	on bs.CMRContractGUID = cc.CMRContractGUID
	and bs.CRMClientGUID = cc.CRMClientGUID
	;

	drop table if exists #cli_con_stages;
	
	select s.external_id, s.date_on, s.CMRContractGUID, s.CMRContractStage, s.CRMClientGUID, s.CRMClientStage
	into #cli_con_stages 
	from #stg3_cli_con_stages s
	where rown = 1;




	
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#t00000';

	drop table if exists #t00000;

	create table #t00000 (
	seg varchar(100),
	dpd_bucket_p_ varchar(100),
	CRMClientStage varchar(100),
	dpd_bucket_p_cmr varchar(100),
	pay_total float,
	product varchar(100)
	);

	insert into #t00000
	select seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, sum(pay_total) as pay_total, a.product
	from 
	(select '(2)_LMSD' as seg,
				 dpd_bucket_p_,				 
				 case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/					
					else cst.CRMClientStage end as CRMClientStage,				 
				 dpd_bucket_p_cmr,
				 pay_total,
				 a.product
				 
		  from #mfo_base a
				left join RiskDWH.dbo.stg_client_stage cst 
				 on a.external_id=cst.external_id 
				 and a.r_date= cst.cdate
				left join dwh_new.dbo.v_agent_credits v
				on a.external_id = v.external_id
				and a.r_date between v.st_date and v.end_date
				left join #stg_sb_0_90 sb
				on a.external_id = sb.external_id
				and a.r_date = sb.r_date
				
				left join #cli_con_stages ccs
				on a.external_id = ccs.external_id
				and a.r_date= ccs.date_on
				left join #isp_proiz isp
				on a.external_id = isp.external_id
				and a.r_date >= isp.dt_from

		  where pay_total>0 and r_year  = year(dateadd(mm,-1, @rdt ))
			and r_month = month(dateadd(mm,-1, @rdt ))
			and r_day <= day( @rdt )
			--and dpd_bucket_p_ <> '(1)_0'
			--26/06/20 - добавлены платежи в нулевом бакете Legal
			--28/09/20 - добавлены платежи в нулевом бакете Агенты
			and (dpd_bucket_p_ <> '(1)_0' 
			or (case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/
					else cst.CRMClientStage end) in ('Legal') and a.dpd_bucket_p_ in
			('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_360', '(6)_361+', '[09] 0-90 hard')
			or 
			isnull(v.agent_name, 'CarMoney') not in ('ACB','CarMoney') 
			 )
			) a
	group by seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, a.product
	;

	insert into #t00000
	select seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, sum(pay_total) as pay_total, a.product
	from (select '(1)_LYSD' as seg,
				 dpd_bucket_p_,
				  case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/
					else cst.CRMClientStage end as CRMClientStage,				 
				 dpd_bucket_p_cmr,
				 pay_total,
				 a.product
		  from #mfo_base a
				left join RiskDWH.dbo.stg_client_stage cst 
				 on a.external_id=cst.external_id 
				 and a.r_date= cst.cdate
				left join dwh_new.dbo.v_agent_credits v
				on a.external_id = v.external_id
				and a.r_date between v.st_date and v.end_date
				left join #stg_sb_0_90 sb
				on a.external_id = sb.external_id
				and a.r_date = sb.r_date

				left join #cli_con_stages ccs
				on a.external_id = ccs.external_id
				and a.r_date= ccs.date_on
				left join #isp_proiz isp
				on a.external_id = isp.external_id
				and a.r_date >= isp.dt_from

		  where pay_total>0 and r_year  = year(dateadd(yy,-1, @rdt ))
			and r_month = month(dateadd(yy,-1, @rdt ))
			and r_day <= day( @rdt )
			--and dpd_bucket_p_ <> '(1)_0'
			--26/06/20 - добавлены платежи в нулевом бакете Legal
			--28/09/20 - добавлены платежи в нулевом бакете Агенты
			and (dpd_bucket_p_ <> '(1)_0' 
			or (case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/
					else cst.CRMClientStage end) in ('Legal') and a.dpd_bucket_p_ in
			('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_360', '(6)_361+', '[09] 0-90 hard')
			or 
			isnull(v.agent_name, 'CarMoney') not in ('ACB','CarMoney') 
			)
			) a
	group by seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, a.product
	;

	insert into #t00000
	select seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, sum(pay_total) as pay_total, a.product
	from (select '(3)_CM' as seg,
				 dpd_bucket_p_,
				  case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/
					else cst.CRMClientStage end as CRMClientStage,				 
				 dpd_bucket_p_cmr,
				 pay_total,
				 a.product
		  from #mfo_base a
				left join RiskDWH.dbo.stg_client_stage cst 
				 on a.external_id=cst.external_id 
				 and a.r_date= cst.cdate
				left join dwh_new.dbo.v_agent_credits v
				on a.external_id = v.external_id
				and a.r_date between v.st_date and v.end_date
				left join #stg_sb_0_90 sb
				on a.external_id = sb.external_id
				and a.r_date = sb.r_date

				left join #cli_con_stages ccs
				on a.external_id = ccs.external_id
				and a.r_date= ccs.date_on
				left join #isp_proiz isp
				on a.external_id = isp.external_id
				and a.r_date >= isp.dt_from

		  where pay_total>0 and r_year  = year( @rdt )
			and r_month = month( @rdt )
			and r_day <= day( @rdt )
			--and dpd_bucket_p_ <> '(1)_0'
			--26/06/20 - добавлены платежи в нулевом бакете Legal
			--28/09/20 - добавлены платежи в нулевом бакете Агенты
			and (dpd_bucket_p_ <> '(1)_0' 
			or (case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/
					else cst.CRMClientStage end) in ('Legal') and a.dpd_bucket_p_ in
			('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_360', '(6)_361+', '[09] 0-90 hard')
			or 
			isnull(v.agent_name, 'CarMoney') not in ('ACB','CarMoney') 	
			)
			) a
	group by seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, a.product
	;

	insert into #t00000
	select seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, sum(pay_total) as pay_total, a.product
	from (select '(4)_LM' as seg,
				 dpd_bucket_p_,
				  case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/
					else cst.CRMClientStage end as CRMClientStage,				 
				 dpd_bucket_p_cmr,
				 pay_total,
				 a.product
		  from #mfo_base a
				left join RiskDWH.dbo.stg_client_stage cst 
				 on a.external_id=cst.external_id 
				 and a.r_date= cst.cdate
				left join dwh_new.dbo.v_agent_credits v
				on a.external_id = v.external_id
				and a.r_date between v.st_date and v.end_date
				left join #stg_sb_0_90 sb
				on a.external_id = sb.external_id
				and a.r_date = sb.r_date

				left join #cli_con_stages ccs
				on a.external_id = ccs.external_id
				and a.r_date= ccs.date_on
				left join #isp_proiz isp
				on a.external_id = isp.external_id
				and a.r_date >= isp.dt_from

		  where pay_total>0 and r_year  = year(dateadd(mm,-1, @rdt ))
			and r_month = month(dateadd(mm,-1, @rdt ))
			-- and r_day <= dateadd(day(dateadd(dd,-1,getdate()))
			--and dpd_bucket_p_ <> '(1)_0'
			--26/06/20 - добавлены платежи в нулевом бакете Legal
			--28/09/20 - добавлены платежи в нулевом бакете Агенты
			and (dpd_bucket_p_ <> '(1)_0' 
			or (case when isnull(v.agent_name,'CarMoney') not in ('CarMoney', 'ACB') then 'КА'
					when ccs.external_id is not null then 'ИП'
					when isp.external_id is not null then 'ИП'
					when sb.external_id is not null then 'Legal' /*26/11/20*/
					else cst.CRMClientStage end) in ('Legal') and a.dpd_bucket_p_ in
			('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_360', '(6)_361+', '[09] 0-90 hard')
			or 
			isnull(v.agent_name, 'CarMoney') not in ('ACB','CarMoney') 	
			)
			) a
	group by seg, dpd_bucket_p_, CRMClientStage, dpd_bucket_p_cmr, a.product
	;





	

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#bankrupts_deals';

	--база договоров-банкротов (статус = Банкрот подтвержденный)
	drop table if exists #bankrupts_deals;

	SELECT deals.Number as external_id,
	cust_status.CustomerId as customer_id,
	cast(min([ChangeDate]) as date) as dt_from,
	min(isnull(cast(f.[BankruptcyFinishDate] as date), cast('4444-01-01' as date))) as dt_to

	into #bankrupts_deals
	from stg._Collection.BankruptConfirmedHistory Bank_confirmed
	--[C2-VSR-SQL04].[collection_night00].[dbo].[BankruptconfirmedHistory] Bank_confirmed
	inner join [Stg].[_Collection].[CustomerStatus] cust_status 
	on cust_status.Id = Bank_confirmed.[ObjectId]
	inner join stg._Collection.deals deals 
	on deals.IdCustomer = cust_status.CustomerId
	left join stg._Collection.CustomerBankruptcy f
	--[C2-VSR-SQL04].[collection_night00].[dbo].CustomerBankruptcy f
	on cust_status.CustomerId = f.customerid
	where [Field] = 'Статус назначен'
	and [NewValue] = 'True'
	group by deals.Number, cust_status.CustomerId

	--удаляем, где дата окончания банкротства меньше даты назначения статуса
	delete from #bankrupts_deals where dt_from > dt_to;




	--Принятые на баланс (с указанной датой)
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#dealpledge';

	--договор-залог
	drop table if exists #dealpledge

	select distinct b.Number as external_id,
	concat(c.LastName, ' ', c.Name, ' ', c.MiddleName) as client_fio,
	a.PledgeItemId
	into #dealpledge
	from stg._Collection.DealPledgeItem a
	left join stg._Collection.Deals b
	on a.DealId = b.Id
	left join stg._Collection.customers c
	on b.IdCustomer = c.id
	where 1=1
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#pledgeadoption';

	--дата принятия на баланс
	drop table if exists #stg_pledgeadoption;
	select distinct a.*, 
	cast(c.AdoptionBalanceDate as date) as AdoptionBalanceDate, 
	cast(c.AmountDepositToBalance as float) as AmountDepositToBalance
	into #stg_pledgeadoption
	from #dealpledge a
	inner join stg._Collection.EnforcementProceedingMonitoring b
	on a.PledgeItemId = b.PledgeItemId
	inner join stg._Collection.EnforcementProceedingMonitoringImplementation c
	on b.Id = c.EnforcementProceedingMonitoringId
	where c.AdoptionBalanceDate is not null
	and c.DecisionDepositToBalance = 1;


	--флаги по совпадению даты и сумм принятия на баланс и платежей 
	drop table if exists #stg2_pledgeadoption;

	select 
	b.PledgeItemId,
	a.external_id, 
	a.r_date,
	a.pay_total,
	b.AmountDepositToBalance,
	round(a.pay_total / b.AmountDepositToBalance,4) * 100 - 100 as deltaprc_pmt_bal,
	abs(datediff(dd,a.r_date, b.AdoptionBalanceDate)) as delta_dt,

	--погрешность в дне принятия и платежа не более 7 дней
	case when abs(datediff(dd,a.r_date, b.AdoptionBalanceDate)) <= 7
	then 1 
	else 0 
	end as flag_match_dates,

	--погрешность в сумме принятия и платежа не более 3%
	case when round(a.pay_total / b.AmountDepositToBalance,4) * 100 - 100 between -3 and 3
	then 1
	 --если для одного залога несколько договоров
	when round( sum(a.pay_total) over (partition by b.PledgeItemId, a.r_date) 
	/ b.AmountDepositToBalance,4) * 100 - 100 between -3 and 3
	then 1
	else 0 
	end as flag_match_sums	
	
	into #stg2_pledgeadoption

	from #CMR a
	inner join #stg_pledgeadoption b
	on a.external_id = b.external_id
	and datediff(dd, a.r_date, b.AdoptionBalanceDate) between -30 and 30
	where a.pay_total > 0;


	drop table if exists #pledgeadoption;
	select a.external_id, a.r_date,
	ROW_NUMBER() over (partition by a.external_id, a.r_date
	order by a.deltaprc_pmt_bal , a.delta_dt) as rown

	into #pledgeadoption
	from #stg2_pledgeadoption a
	where ( (a.flag_match_dates = 1 and a.flag_match_sums = 1)
	--сумма принятия на баланс отличается больше, чем на 3%. Адамян Рачик попросил учесть
	--or (a.external_id = '18082115680003' and a.r_date = cast('2020-09-07' as date)) 
	--or (a.external_id = '1708132210001'and a.r_date = cast('2020-10-16' as date))
	---поместил в таблицу fix
	or exists (select 1 from RiskDWH.dbo.det_fix_pledgeadoption f
		where a.external_id = f.external_id and a.r_date = f.r_date )
	)
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_agents_pays';

	drop table if exists #stg_agents_pays;	 
	 
	with base as (
		select r_month, r_day, r_year, r_date, dpd_bucket_cmr, dpd_bucket_p_cmr, 
		a.external_id,
		(case when isnull(b.agent_name, 'CarMoney') in ('ACB','CarMoney') 
			then 'CarMoney'
		else isnull(b.agent_name, 'CarMoney') 
		end) as agent_name,
		(case when isnull(b.agent_name, 'CarMoney') in ('ACB','CarMoney') 
			then 0
			else isnull(b.reestr, 0)
		end) as agent_reestr,
		a.pay_total,
		a.seg,
		a.flag_isp_prz,
		a.con_stage,
		a.overdue_days_p_cmr,
		a.flag_bankrupt,
		a.flag_pledge_adoption,

		concat (md.last_name,' ',md.first_name,' ',md.middle_name) as fio,
		a.product
				
		from (select m.*,

			case 
			when m.r_date between dateadd(dd,1,eomonth(@rdt,-2)) and eomonth(@rdt,-1) then 'LMSD' 
			when m.r_date between dateadd(dd,1,eomonth(@rdt,-13)) and eomonth(@rdt,-12) then 'LYSD' 
			else 'other' end seg,

			st.CRMClientStage as con_stage,
			
			--iif(pr.external_id is not null,1,0) as flag_isp_prz
			case when pr.external_id is not null then 1
			when ccs.external_id is not null then 1 
			else 0 end as flag_isp_prz,
			iif(d.external_id is not null, 1, 0) as flag_bankrupt,
			iif(p.external_id is not null, 1, 0) as flag_pledge_adoption

				from #mfo_base m --#mfo_with_cmr_buckets
				
				left join RiskDWH.dbo.stg_client_stage st
				on m.external_id = st.external_id
				and m.r_date = st.cdate
				
				left join #isp_proiz pr
				on m.external_id = pr.external_id
				and m.r_date >= pr.dt_from

				left join #cli_con_stages ccs
				on m.external_id = ccs.external_id
				and m.r_date = ccs.date_on

				left join #bankrupts_deals d
				on m.external_id = d.external_id
				and m.r_date between d.dt_from and d.dt_to

				left join #pledgeadoption p
				on m.external_id = p.external_id
				and m.r_date = p.r_date
				and p.rown = 1


				where 1=1 
				--year(m.r_date)  =   year( @rdt )
				--and month(m.r_date) in (month( @rdt ),
				--						month(dateadd(mm,-1, @rdt )))
				--and day(m.r_date) <= day( @rdt )

				--02/01/21
				--and m.r_date between dateadd(dd,1,EOMONTH(@rdt,-2)) and @rdt
				--and m.r_day <= day(@rdt)
				--01/02/22
				and (m.r_date between dateadd(dd,1,EOMONTH(@rdt,-2)) and @rdt or m.r_date between dateadd(dd,1,EOMONTH(@rdt,-13)) and EOMONTH(@rdt,-12))
				and m.r_day <= day(@rdt)


				/*
				and (	
				--isnull(overdue_days_p_cmr,0) >= 91 				
				--для учета ИП (в любых бакетах)
				st.CRMClientStage = 'ИП' 
				or pr.external_id is not null 
				or ccs.external_id is not null
				--банкроты
				or d.external_id is not null
				--баланс
				or p.external_id is not null
				)
				*/
					) a
			left join dwh_new.dbo.v_agent_credits b 
			on a.external_id = b.external_id 
			and a.r_date >= b.st_date 
			and a.r_date <= b.end_date

			left join (
			--select distinct external_id,
			--	last_name,
			--	first_name,
			--	middle_name
			--from [dbo].[dm_Maindata]
			select a.Number as external_id, 
				b.LastName  as last_name,
				b.[Name] as first_name,
				b.MiddleName as middle_name	
			from stg._Collection.Deals a
			left join stg._Collection.customers b
			on a.IdCustomer = b.Id
			) md
			on a.external_id = md.external_id
			)

	select bs.external_id, bs.r_year, bs.r_month, bs.r_day, bs.dpd_bucket_cmr, bs.dpd_bucket_p_cmr,
	bs.agent_name, bs.agent_reestr, bs.pay_total,
	bs.seg,
	case 
		 when bs.agent_reestr = 0 and bs.flag_isp_prz = 1 then 'ИП'
		 when bs.agent_reestr = 0 and bs.con_stage = 'ИП' then 'ИП'
		 when bs.agent_reestr = 0 then 'Hard' 
		 when bs.agent_reestr <> 0 /*and bs.overdue_days_p_cmr >= 91*/ then 'Агент'
	else 'rest' end as stage,

	case 
		 when bs.flag_pledge_adoption = 1 then 'Баланс'
		 when bs.flag_bankrupt = 1 then 'Банкрот'
	else 'Платеж' end as stage2,
	bs.fio,
	bs.product
	into #stg_agents_pays
	from base bs	

	where (bs.overdue_days_p_cmr >= 91 and bs.agent_reestr = 0)
	or (bs.overdue_days_p_cmr >= 0 and bs.agent_reestr <> 0)
	or ( (bs.flag_isp_prz = 1 or bs.con_stage = 'ИП') and bs.agent_reestr = 0)
	or bs.flag_bankrupt = 1
	or bs.flag_pledge_adoption = 1
	;


				
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#agents_pays';	

	drop table if exists #agents_pays;

	select 
	a.r_month, a.r_day, a.dpd_bucket_p_cmr as dpd_bucket_cmr, a.agent_name, a.agent_reestr, 
	sum(a.pay_total) as pay_total, a.seg, a.stage, a.stage2, a.product

	into #agents_pays

	from #stg_agents_pays a
	group by a.r_month, a.r_day, a.dpd_bucket_p_cmr, a.agent_name, a.agent_reestr, 
	a.seg, a.stage, a.stage2, a.product;
				

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cred_region';

	drop table if exists #cred_region;
	select  
	a.Номер as external_id, 
	max(case when a.Регион = '' then null 
	when a.Регион in (',','1211','1571','3','455731','Ё','Забугорск') then null
	else a.Регион end) as region	
	into #cred_region
	from stg._1cMFO.Документ_ГП_Заявка a
	group by a.Номер;
	--< 1sec

	/*28.05.2021*/
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_claimants_hist';

	drop table if exists #stg_claimants_hist;
	with base as (
	select 
	a.CustomerId,
	a.[date] as rep_datetime, 
	cast(a.[date] as date) as rep_dt,
	a.OldClaimantId,
	a.NewClaimantId,
	iif(a.OldClaimantId is null, null, concat(b.LastName, ' ', b.FirstName, ' ', b.MiddleName)) as old_claim_fio,
	iif(a.NewClaimantId is null, null, concat(c.LastName, ' ', c.FirstName, ' ', c.MiddleName)) as new_claim_fio,
	ROW_NUMBER() over (partition by a.CustomerId, cast(a.[date] as date) order by a.[date] asc) as rown_asc,
	ROW_NUMBER() over (partition by a.CustomerId, cast(a.[date] as date) order by a.[date] desc) as rown_desc
	from stg._Collection.ClaimantCustomersHistory a
	left join stg._Collection.Employee b
	on a.OldClaimantId = b.Id
	left join stg._Collection.Employee c
	on a.NewClaimantId = c.Id
	--where a.CustomerId = 45109--46011--26057--45109
	), stg as (
	select a.CustomerId, a.rep_dt, a.OldClaimantId, a.old_claim_fio, b.NewClaimantId, b.new_claim_fio
	from base a
	left join base b
	on a.CustomerId = b.CustomerId
	and a.rep_dt = b.rep_dt
	and b.rown_desc = 1
	where a.rown_asc = 1
	)
	select a.CustomerId, 
	dateadd(dd,1,a.rep_dt) as dt_from, 
	lead(a.rep_dt,1,cast('4444-01-01' as date)) over (partition by a.CustomerId order by a.rep_dt) as dt_to, 
	a.new_claim_fio as claimant_fio
	into #stg_claimants_hist
	from stg a
	;

	/*28.05.2021*/
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#ispol_lists';
	
	drop table if exists #ispol_lists;
	select 
	a.number,
	case when sum(iif(eo.Number is not null, 1, 0)) > 0 then 1 else 0 end as flag_IL,
	case when sum(iif(eo.Number is not null, 1, 0)) > 0 then min(cast(coalesce(eo.[Date], eo.ReceiptDate, eo.CreateDate) as date)) end as dt_from
	into #ispol_lists
	from stg._Collection.deals a 
	left join Stg._Collection.JudicialProceeding AS jp 
	ON a.Id = jp.DealId
	left join Stg._Collection.JudicialClaims AS jc 
	ON jp.Id = jc.JudicialProceedingId
	left join Stg._Collection.EnforcementOrders AS eo 
	ON jc.Id = eo.JudicialClaimId
	group by a.Number
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#cnt_credits_paid';
	--from Тимофеев Никита Сергеевич Чт 21.05.2020 21:33: dpd_bucket_from, dpd_bucket_to 
	drop table if exists #cnt_credits_paid;
		select distinct 
			f.seg,
			f.external_id,
			f.r_date,
			f.dpd_bucket_to,
			f.dpd_bucket_from,
			f.pay_total,
			f.CRMClientStage,

			concat (last_name,' ',first_name,' ',middle_name) fio,
			case 
				when isnull(f.x_agent_name, 'CarMoney') in (
						'ACB',
						'CarMoney'
						)
					then 'CarMoney'
				else isnull(f.x_agent_name, 'CarMoney')
				end as agent_name,

			clh.claimant_fio, --m.claimant_fio, /*28.05.2021*/
			m.claimant_ip_fio,
			reg.region,
			isnull(il.flag_IL, 0) as flag_isp_list /*28.05.2021*/
			,f.product
		into #cnt_credits_paid
		from (
			select '(3)_CM' as seg,
				a.external_id,
				a.r_date,
				a.dpd_bucket_to_ as dpd_bucket_to,
				a.dpd_bucket_p_ as dpd_bucket_from,
				sum(a.pay_total) pay_total,
				case 
				when ccs.external_id is not null then 'ИП'
				when isp.external_id is not null then 'ИП'
				when sb.external_id is not null then 'Legal' /*26/11/20*/
				else cst.CRMClientStage end as CRMClientStage,
				b.agent_name as x_agent_name,
				a.product

			from #mfo_base a
			left join RiskDWH.dbo.stg_client_stage cst 
				 on a.external_id=cst.external_id 
				 and a.r_date= cst.cdate
			left join dwh_new.dbo.v_agent_credits b
				on a.external_id = b.external_id
				and a.r_date >= b.st_date
				and a.r_date <= b.end_date
			left join #stg_sb_0_90 sb
				on a.external_id = sb.external_id
				and a.r_date = sb.r_date

			left join #cli_con_stages ccs
				on a.external_id = ccs.external_id
				and a.r_date= ccs.date_on
			left join #isp_proiz isp
				on a.external_id = isp.external_id
				and a.r_date >= isp.dt_from

			where r_year = year( @rdt )
				and r_month = month( @rdt )
				and r_day <= day( @rdt )
					--and dpd_bucket_p_ <> '(1)_0'
				--26/06/20 - добавлены платежи в нулевом бакете Legal
				--28/09/20 - добавлены платежи в нулевом бакете Агенты
			and (dpd_bucket_p_ <> '(1)_0' 
			or (case 
			when ccs.external_id is not null then 'ИП'
			when isp.external_id is not null then 'ИП'
			when sb.external_id is not null then 'Legal' /*26/11/20*/
				else cst.CRMClientStage end) in ('Legal') and a.dpd_bucket_p_ in
			('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90','(5)_91_360', '(6)_361+', '[09] 0-90 hard')
			or isnull(b.agent_name, 'CarMoney') in ('ACB','CarMoney')
				)
			and round(pay_total,2) > 0

			group by a.external_id,
				a.r_date,
				a.dpd_bucket_p_,
				case 
				when ccs.external_id is not null then 'ИП'
				when isp.external_id is not null then 'ИП'
				when sb.external_id is not null then 'Legal' /*26/11/20*/
				else cst.CRMClientStage end,
				a.dpd_bucket_to_,
				b.agent_name,
				a.product
				
			) f
		left join (
			--select distinct external_id,
			--	last_name,
			--	first_name,
			--	middle_name
			--from [dbo].[dm_Maindata]
			select a.Number as external_id, 
				b.LastName  as last_name,
				b.[Name] as first_name,
				b.MiddleName as middle_name,
				iif( b.ClaimantId is null, null, concat(e.LastName,' ',e.FirstName,' ',e.MiddleName)) as claimant_fio,
				iif( b.ClaimantExecutiveProceedingId is null, null, concat(ee.LastName,' ',ee.FirstName,' ',ee.MiddleName)) as claimant_ip_fio,
				a.IdCustomer

			from stg._Collection.Deals a
			left join stg._Collection.customers b
			on a.IdCustomer = b.Id
			left join stg._Collection.Employee e
			on b.ClaimantId = e.Id
			left join stg._Collection.Employee ee
			on b.ClaimantExecutiveProceedingId = ee.Id
			) m
			on m.external_id = f.external_id

		left join #cred_region reg
		on f.external_id = reg.external_id

		left join #stg_claimants_hist clh
		on m.IdCustomer = clh.CustomerId
		and f.r_date between clh.dt_from and clh.dt_to

		left join #ispol_lists il
		on il.Number = f.external_id
		and il.dt_from <= f.r_date
		;


 
	 exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#payments_today';


	drop table if exists #payments_today
	select '(3)_CM' as seg,
				  dpd_bucket_p_,
				 sum(pay_total) sum_pay_total,
				 a.product
				into #payments_today
		  from #mfo_base a
		  where r_year  = year( @rdt )
			and r_month = month( @rdt )
			and r_day = day( @rdt )
			and dpd_bucket_p_ <> '(1)_0'
		group by dpd_bucket_p_, product

		

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#payments_week';


	drop table if exists #payments_week;
	select '(3)_CM' as seg,
			  dpd_bucket_p_,
			 sum(pay_total) sum_pay_total,
			 a.product
			into #payments_week
	  from #mfo_base a
	  where r_year  = year( @rdt )
		and r_month = month( @rdt )
		and (r_date between dateadd(dd,-6, @rdt) and @rdt)
		and dpd_bucket_p_ <> '(1)_0'
	group by dpd_bucket_p_, a.product

	
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_fssp_pmt';


	drop table if exists #stg_fssp_pmt;
		select b.Number as external_id, 
		a.PaymentDt,
		cast(a.PaymentDt as date) as r_date,
		cast(a.Amount as float) as amount,
		case when cast(a.PaymentDt as date) between dateadd(dd,1,eomonth(@rdt,-2)) and dateadd(MM,-1,@rdt) --eomonth(@rdt,-1)
		then 'LMSD'
		when cast(a.PaymentDt as date) between dateadd(dd,1,eomonth(@rdt,-1)) and @rdt
		then 'CM'
		end as seg,
		case when c.ClaimantExecutiveProceedingId is not null
		then 
		concat(d.LastName, ' ', d.FirstName, ' ', d.MiddleName) 
		end as curator_fio,
		case when isnull(v.agent_name, 'CarMoney') in ('ACB', 'CarMoney') 
		then 'CarMoney'
		else v.agent_name end as agent_name,
		isnull(pr.product,'PTS') as product


		into #stg_fssp_pmt
		from stg._Collection.Payment a
		inner join stg._Collection.Deals b
		on a.IdDeal = b.Id
		left join stg._Collection.customers c
		on b.IdCustomer = c.id
		left join stg._Collection.Employee d
		on c.ClaimantExecutiveProceedingId = d.Id

		left join dwh_new.dbo.v_agent_credits v
		on b.Number = v.external_id 
		and cast(a.PaymentDt as date) between v.st_date and v.end_date

		left join #stg_product pr
		on b.Number = pr.external_id

		where a.Payer = 'ФССП'
		and a.IsActive = 1
		and ( cast(a.PaymentDt as date) between dateadd(dd,1,eomonth(@rdt,-2)) and dateadd(MM,-1,@rdt) --eomonth(@rdt,-1)
		or cast(a.PaymentDt as date) between dateadd(dd,1,eomonth(@rdt,-1)) and @rdt);		
		
		
	drop table if exists #stg_fssp_pmt_by_day;
		select a.seg, a.external_id, a.r_date, sum(a.Amount) as pay_total, count(*) as cnt_pmt_in_day, a.curator_fio, a.agent_name, a.product
		into #stg_fssp_pmt_by_day
		from #stg_fssp_pmt a
		group by a.seg, a.external_id, a.r_date, a.curator_fio, a.agent_name, a.product;


------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'REP';



	begin transaction 

	delete from risk.dm_ReportCollectionPlanMFOCred --  RiskDWH.dbo.rep_coll_plan_mfo_cred 
	where rep_dt = @rdt

	insert into   risk.dm_ReportCollectionPlanMFOCred -- RiskDWH.dbo.rep_coll_plan_mfo_cred
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from  #cnt_credits_paid a

	-----------------------------------------------------------------------
	delete from  risk.dm_ReportCollectionPlanMFOPmtDay  --  RiskDWH.dbo.rep_coll_plan_mfo_pmt_day
	where rep_dt = @rdt

	insert into  risk.dm_ReportCollectionPlanMFOPmtDay
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from #payments_today a

	-----------------------------------------------------------------------
	delete from risk.dm_ReportCollectionPlanMFOPmtWeek  --  RiskDWH.dbo.rep_coll_plan_mfo_pmt_week
	where rep_dt = @rdt

	insert into risk.dm_ReportCollectionPlanMFOPmtWeek
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from #payments_week a

	-----------------------------------------------------------------------
	delete from  risk.dm_ReportCollectionPlanMFOPmtAll --  RiskDWH.dbo.rep_coll_plan_mfo_pmt_all
	where rep_dt = @rdt

	insert into risk.dm_ReportCollectionPlanMFOPmtAll
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from #t00000 a

	-----------------------------------------------------------------------
	delete from risk.dm_ReportCollectionPlanAgentsPays  --   RiskDWH.dbo.rep_coll_plan_agents_pays
	where rep_dt = @rdt

	insert into  risk.dm_ReportCollectionPlanAgentsPays 
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, a.* 
	from #agents_pays a

	-----------------------------------------------------------------------

	--детализация ИП/Хард + агенты для текущего месяца
	delete from Risk.dm_ReportCollectionPlanIspHard -- RiskDWH.dbo.rep_coll_plan_isp_hard
	where rep_dt = @rdt


	insert into Risk.dm_ReportCollectionPlanIspHard -- RiskDWH.dbo.rep_coll_plan_isp_hard 

	select 
	@rdt as rep_dt,	cast(sysdatetime() as datetime) as dt_dml,
	a.external_id, a.r_year, a.r_month, a.r_day, a.dpd_bucket_p_cmr as dpd_bucket_cmr, 
	a.stage, a.pay_total, a.agent_name, a.stage2, a.fio, a.product

	from #stg_agents_pays a
	where a.pay_total > 0
	and a.seg = 'other'
	--and a.stage in ('ИП','Hard')
	order by a.stage, a.r_day

	-----------------------------------------------------------------------

	--Платежи ФССП
	delete from Risk.dm_ReportCollectionPlanFSSPPmt --RiskDWH.dbo.rep_coll_plan_fssp_pmt
	where rep_dt = @rdt;

	insert into Risk.dm_ReportCollectionPlanFSSPPmt --RiskDWH.dbo.rep_coll_plan_fssp_pmt

	select 
	@rdt as rep_dt,
	cast(SYSDATETIME() as datetime) as dt_dml,
	a.seg, a.r_date, a.external_id, 
	b.dpd_bucket_p as dpd_bucket_from,
	b.dpd_bucket as dpd_bucket_to, 
	a.pay_total,
	a.curator_fio,
	a.agent_name,
	a.product
	
	from #stg_fssp_pmt_by_day a
	left join #CMR b
	on a.external_id = b.external_id
	and a.r_date = b.r_date

	;

	-----------------------------------------------------------------------
	--2021-11-03 - пилот 91-150


	delete from [Risk].[dm_ReportCollectionPilot90150]
	where rep_dt = @rdt;


	insert into [Risk].[dm_ReportCollectionPilot90150]
	
	select
	@rdt as rep_dt,
	cast(getdate() as datetime) as dt_dml,
	cast(a.date_in as date) as pilot_date,
	eomonth(a.date_in) as report_month,
	a.external_id,
	a.external_stage as pilot_group,
	c.dpd,
	c.[остаток од] as total_od,
	sum(isnull(v.[сумма поступлений], 0)) as pay_total,
	trim(replace(replace(replace(replace(replace(lower(d.[регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) as region,
	h.dpd as dpd_today,
	k2.new_claim_fio,
	coalesce(pr.product,'PTS') as product

	from stg._loginom.External_pilot_Hard_Prelegal a

	left join stg.[_1cMFO].[Документ_ГП_Заявка] d 
	on cast(a.external_id as nvarchar(2000))=cast(d.Номер as nvarchar(2000))
	left join [dwh2].[dbo].[dm_CMRStatBalance] c 
	on a.external_id=c.external_id 
	and c.d=a.date_in
	left join [dwh2].[dbo].[dm_CMRStatBalance] h 
	on a.external_id=h.external_id 
	and h.d=cast(getdate() as date)
	left join [dwh2].[dbo].[dm_CMRStatBalance] v 
	on a.external_id=v.external_id
	and v.d>=a.date_in
	and v.d < cast(getdate() as date)
	left join #stg_product pr
	on a.external_id = pr.external_id

	left join (--k2
		select k.* from (--k
			select distinct
			a.CustomerId,
			d.Number,
			a.date,
			a.OldClaimantId,
			a.NewClaimantId,
			iif(a.OldClaimantId is null, null, concat(b.LastName, ' ', b.FirstName, ' ', b.MiddleName)) as old_claim_fio,
			iif(a.NewClaimantId is null, null, concat(c.LastName, ' ', c.FirstName, ' ', c.MiddleName)) as new_claim_fio,
			ROW_NUMBER() over (partition by d.number order by a.date desc) as rn
			from stg._Collection.ClaimantCustomersHistory a
			left join stg._Collection.Employee b 
			on a.OldClaimantId = b.Id
			left join stg._Collection.Employee c 
			on a.NewClaimantId = c.Id
			inner join stg._Collection.deals d 
			on d.IdCustomer = a.CustomerId
		)k
		where k.rn=1
	)k2 
	on a.external_id=k2.number
	group by
	cast(a.date_in as date),
	eomonth(a.date_in),
	a.external_id,
	a.external_stage,
	c.dpd,
	c.[остаток од],
	d.[регион],
	h.dpd,
	k2.new_claim_fio,
	coalesce(pr.product,'PTS')
	;

	-----------------------------------------------------------------------

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'drop temp (#) tables';

	drop table #agents_pays;	
	drop table #cnt_credits_paid;
	drop table #mfo_base;
	drop table #payments_today;
	drop table #payments_week;
	drop table #stg_hard90_1;
	drop table #stg_hard90_2;
	drop table #stg_hard90_31;
	drop table #stg_hard90_32;
	drop table #stg_hard90_4;
	drop table #stg_hard90_5;
	drop table #t00000;
	drop table #stg_agents_pays;
	drop table #isp_proiz;
	drop table #stg_isp_proiz;
	drop table #bankrupts_deals;
	drop table #cli_con_stages;
	drop table #dealpledge;
	drop table #pledgeadoption;
	drop table #stg_pledgeadoption;
	drop table #stg_fssp_pmt;
	drop table #stg_fssp_pmt_by_day;
	drop table #stg2_pledgeadoption;
	drop table #stg_sb_0_90;
	drop table #reestr_0_90_hard;
	drop table #stg1_cli_con_stages;
	drop table #stg2_cli_con_stages;
	drop table #stg3_cli_con_stages;
	drop table #cred_region;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'FINISH';
	
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY MFO/CMR - FINISH';

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name ,@info = @errmsg;
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'DAILY MFO/CMR - ERROR';
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

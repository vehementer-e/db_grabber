CREATE procedure [Risk].[report_portfolio_fpd_inst_pdl]
as
begin

DECLARE @Date_rep date = '20231201';

--1. соберем кредиты PDL за необходимый период
drop table if exists #credit;
select *
		,row_number() over(partition by cr.external_id order by cr.startdate DESC) as rn
	into #credit
	from dwh2.risk.credits as cr with (nolock)
	where cr.credit_type in ('INST', 'PDL')
	;
--select * from #credit;fl

--2. по кредитам, отобранным на предыдущем шаге, выгрузим просрочку
drop table if exists #overdue;
select *
	into #overdue
	from [dwh2].[dbo].[dm_OverdueIndicators] 
	where number in (select distinct external_id from #credit)
	;
--select * from #overdue;


--4. соберем промежуточный датасет с данными по просрочке и промопериоду.
-- поля избыточны, можно почистить
drop table if exists #data_set;
select 
		cr.external_id
		,cr.client_type
		,cr.credit_type
		,cast(cr.amount as float) as CR_amount
		,cast(1 as int) as flg_count
		,cr.PDLTerm
		,cr.term
		,cr.pdn
		,cr.generation
		,cr.startdate
		,cr.factenddate
		,cr.max_dpd
		,cast(od.CurrentPrincipalDebt as float) as CurrentPrincipalDebt
		,od.CurrentMOB_initial
		,od.CurrentMOB_accrual
		,od.fpd0	
		,od.fpd4	
		,od.fpd7
		,od.fpd10
		,od.fpd15
		,od.fpd30	
		,od.spd0	
		,od.tpd0	
		,od.spd0_not_fpd0	
		,od._30_4_MFO	
		,od._30_4_CMR	
		,od._90_6_MFO	
		,od._90_6_CMR
		,od._90_12_MFO	
		,od._90_12_CMR
		,od.MOB_overdue30_MFO_date	
		,od.MOB_overdue30_MFO	
		,cast(od.Pdebt_overdue30_MFO as float) as Pdebt_overdue30_MFO
		,od.MOB_overdue60_MFO_date	
		,od.MOB_overdue60_MFO	
		,cast(od.Pdebt_overdue60_MFO as float) as Pdebt_overdue60_MFO
		,od.MOB_overdue90_MFO_date	
		,od.MOB_overdue90_MFO	
		,cast(od.Pdebt_overdue90_MFO as float) as Pdebt_overdue90_MFO
		,od.MOB_overdue30_CMR_date	
		,od.MOB_overdue30_CMR	
		,cast(od.Pdebt_overdue30_CMR as float) as Pdebt_overdue30_CMR
		,od.MOB_overdue60_CMR_date	
		,od.MOB_overdue60_CMR	
		,cast(od.Pdebt_overdue60_CMR as float) as Pdebt_overdue60_CMR
		,od.MOB_overdue90_CMR_date	
		,od.MOB_overdue90_CMR	
		,cast(od.Pdebt_overdue90_CMR as float) as Pdebt_overdue90_CMR
		,od.CurrentOverdue_MFO	
		,od.MaxOverdue_MFO	
		,od.CurrentOverdue_CMR	
		,od.MaxOverdue_CMR	
		,od.HardFraud	
		,od.ConfirmedFraud	
		,od.UnconfirmedFraud	
		,od.create_at	
		,od.CurrentMOB	
		,od._15_4_MFO	
		,od._15_4_CMR	
		,od.fpd60	
		,od.Count_overdue
		,datepart(ww, cr.startdate) as week_of_year
		,concat(FORMAT( DATEADD(WEEK, DATEDIFF(WEEK, 0, cr.startdate), 0), 'dd.MM') , ' - ' ,-- Начало недели (понедельник)
			FORMAT(DATEADD(WEEK, DATEDIFF(WEEK, 0, cr.startdate), 6),'dd.MM')) AS [week]   -- Конец недели (воскресенье)
	into #data_set
	from  #credit as cr
		left join #overdue od
			on cr.external_id = od.number
		
	where cr.rn = 1
	;

--select * from #data_set;


--9. выделим кредиты с отсутствием исторической просрочки на дату отчета
drop table if exists #without_overdue;
select 
		cr.external_id
		,case
			when max(bal.dpd_begin_day) = 0 
				then 1
			else 0
		end as without_overdue
	into #without_overdue
	from (select distinct external_id from #credit) cr
		left join dwh2.dbo.dm_CMRStatBalance bal
			on cr.external_id = bal.external_id
	group by cr.external_id
;
--select * from #without_overdue;

--10. обогатим договоры данными из заявок
drop table if exists #app_data;
select *
		,case
				when leadsource = 'bankiru-installment-ref' or leadsource = 'bankiru-deepapi' then 1
				else 0
			end as Bankiru
		,case
				when leadsource = 'bankiru-installment-ref' then 'Old'
				when leadsource = 'bankiru-deepapi' then 'API'
				else ''
			end as Bankiru_type
		,row_number() over (partition by number order by Stage_date DESC) as rn_for_drop
	into #app_data
	from Stg._loginom.application with (nolock)
	where number in (select distinct external_id from #credit)
		and Stage = 'Call 1'
	;
--select * from #app_data
--where number in ('24012521698409'
--,'24012521698419');


--11. Выделим признак автоапрува (после CALL2 идет этап CALL5)
drop table if exists #Auto_Approve;
select distinct 
		number
		,okbscore
		,case 
			when okbscore  < 400 then '00. <400'
			when okbscore < 410 then '01. [400-410)'
			when okbscore < 420 then '03. [410-420)'
			when okbscore < 440 then '04. [420-440)'
			when okbscore < 460 then '05. [440-460)'
			when okbscore < 480 then '06. [460-480)'
			when okbscore < 500 then '07. [480-500)'
			when okbscore < 520 then '08. [500-520)'
			when okbscore < 540 then '09. [520-540)'
			when okbscore < 560 then '10. [540-560)'
			when okbscore < 580 then '11. [560-580)'
			when okbscore < 600 then '12. [580-600)'
			when okbscore < 640 then '13. [600-640)'
			when okbscore >= 640 then '14. более 640'
		end as score_bucket
		,case 
			when Decision = 'Accept' and Next_step = 'Call 5' /*and client_type_2 = 'repeated'*/ then 1 
			else 0 
		end as flg_autoapp
		,ROW_NUMBER() OVER(PARTITION BY number ORDER BY call_date DESC) rn
	into #Auto_Approve
	from stg._loginom.Originationlog
	where stage='Call 2'
		and number in (select distinct external_id from #credit)
;
--select * from #Auto_Approve;

drop table if exists #Product;
with tmp as (select number			
					,stage
					,productTypeCode
					,row_number() over(partition by number, stage order by call_date DESC) as rn
				from stg._loginom.originationlog as ol_prod with(nolock)
				where number in (select distinct external_id from #credit)
			)
	select t1.number
			,case 
					when t5.productTypeCode is not null then t5.productTypeCode
					when t2.productTypeCode is not null then t2.productTypeCode
					when t1_5.productTypeCode is not null then t1_5.productTypeCode
					when t1_2.productTypeCode is not null then t1_2.productTypeCode
					else t1.productTypeCode
				end as product
		into #product
		from tmp as t1
			left join tmp as t1_2
				on t1.number = t1_2.number
				and t1_2.stage = 'Call 1.2'
				and t1_2.rn = 1
			left join tmp as t1_5
				on t1.number = t1_5.number
				and t1_5.stage = 'Call 1.5'
				and t1_5.rn = 1
			left join tmp as t2
				on t1.number = t2.number
				and t2.stage = 'Call 2'
				and t2.rn = 1
			left join tmp as t5
				on t1.number = t5.number
				and t5.stage = 'Call 5'
				and t5.rn = 1
		where t1.stage = 'Call 1'
			and t1.rn = 1

--12. подтянем сегмент клиента
drop table if exists #calc_lim_call_1;
select number
		,limit_segment_inst	
		,limit_segment_pdl
		,max_pmt_limit_PDL
		,max_pmt_limit_INST
		,stage
		,row_number() over (partition by number, stage order by call_date DESC) as rn
	into #calc_lim_call_1
	from stg._loginom.calculated_term_and_amount_installment with (nolock) -- LoginomDB.LoginomDB.dbo.calculated_term_and_amount_installment with (nolock)  
	where number in (select distinct external_id from #credit)
		and Stage in ('Call 1', 'Call 2')

drop table if exists #banki_over;
select number 
		,case when declineOverrideCategory = '001_extendedAgressiveApproval' then 1 else 0 end as Override_Banki
		,row_number() over(partition by number order by call_date DESC) as rn
	into #banki_over
	from stg._loginom.Originationlog
	where stage = 'Call 1'
		and declineOverrideCategory = '001_extendedAgressiveApproval'
		and number in (select distinct external_id from #credit)


--13. соберем итоговый датасет с агрегированными данными 
--часть данных/признаков используется для аналитики и анализа причин изменения показателей
drop table if exists #data_res;
select distinct 
		dsp.*
		,aa.flg_autoapp
		,aa.okbscore
		,aa.score_bucket
		,ad.leadSource

		,pr.product
		,ad.clientLoanTermLength
		,ad.clientLoanDaysLength

		,ad.Request_amount

		,ad.Income_amount
		,ad.Years
		,case
			when ad.Request_amount <= 10000
				then '(0; 10000]'
			when ad.Request_amount > 10000 and ad.Request_amount <=20000
				then '(10000; 20000]'
			when ad.Request_amount > 20000 and ad.Request_amount <=30000
				then '(20000; 30000]'
			when ad.Request_amount > 30000 and ad.Request_amount <=50000
				then '(30000; 50000]'
			when ad.Request_amount > 50000 and ad.Request_amount <=100000
				then '(50000; 100000]'
			when ad.Request_amount > 100000
				then '(100000; inf]'
			else 'error'
		end as group_request_amount

		,dsp.fpd0 * CR_amount as sum_fpd0
		,dsp.fpd4 * CR_amount as sum_fpd4
		,dsp.fpd7 * CR_amount as sum_fpd7
		,dsp.fpd10 * CR_amount as sum_fpd10
		,dsp.fpd15 * CR_amount as sum_fpd15
		,dsp.fpd30 * CR_amount as sum_fpd30

		, case
				when dsp.pdn <= 0.5
					then '1. <=0,5]'
				when dsp.pdn > 0.5 and dsp.pdn <= 0.8
					then '2. 0,5 - 0,8]'
				when dsp.pdn > 0.8
					then '3. > 0,8'
				else 'Ошибка'
			end as pdn_fact_bucket
		,case
			when dsp.pdn is null 
				then '00.нд'
			when dsp.pdn < 0.5
				then '01.[0; 0,5)'
			when dsp.pdn >= 0.5
					and dsp.pdn < 0.6
				then '02.[0,5; 0,6)'
			when dsp.pdn >= 0.6
					and dsp.pdn < 0.7
				then '03.[0,6; 0,7)'
			when dsp.pdn >= 0.7
					and dsp.pdn < 0.8
				then '04.[0,7; 0,8)'
			when dsp.pdn >=0.8
					and dsp.pdn < 1
				then '05.[0,8; 1,0)'
			when dsp.pdn >= 1
					and dsp.pdn < 1.25
				then '06.[1,0; 1,25)'
			when dsp.pdn >= 1.25
					and dsp.pdn < 1.5
				then '07.[1,25; 1,5)'
			when dsp.pdn >= 1.5
					and dsp.pdn < 1.75
				then '08.[1,5; 1,75'
			when dsp.pdn >= 1.75
					and dsp.pdn < 2
				then '09.[1,75; 2,0)'
			when dsp.pdn >= 2
					and dsp.pdn < 3.0
				then '10.[2,0; 3,0)'

			when dsp.pdn >= 3.0
					and dsp.pdn < 4.0
				then '11.[3.0; 4.0)'
			when dsp.pdn >= 4.0
					and dsp.pdn < 5.0
				then '12.[4.0; 5.0)'
			when dsp.pdn >= 5.0
				then '13.[5,0; inf)'
				
			else '11.error'
		end as C1_incoming_DTI_group
		
		,case
			when dsp.credit_type = 'PDL' and dateadd(dd, PDLTerm, dsp.startdate) <= cast(SYSDATETIME() as date)
				then 1
			when dsp.credit_type = 'INST' and dateadd(dd, 14, dsp.startdate) <= cast(SYSDATETIME() as date)
				then 1
			when FactEndDate is not null 
				then 1
			else 0
		end as flg_calc


		,case
			 when ad.clientLoanDaysLength <= 7
				then '<= 7'
			when ad.clientLoanDaysLength > 7 and ad.clientLoanDaysLength <= 14
				then '(7; 14]'
			when ad.clientLoanDaysLength > 14 and ad.clientLoanDaysLength <= 21
				then '(14; 21]'
			when ad.clientLoanDaysLength > 21 and ad.clientLoanDaysLength <= 30
				then '(21; 30]'
			else 'INST'
		end as group_lenght_day
		,case
			when ad.Years < 21 then '1. below 21'
			when ad.Years < 25 then '2. 21-24 years'
			when ad.years < 30 then '3. 25-29 years'
			when ad.years < 40 then '4. 30-39 years'
			when ad.years < 50 then '5. 40-49 years'
			when ad.years < 60 then '6. 50-59 years'
			when ad.years >=60 then '7. 60+ years'
			end as Age_clients
		,c_l.limit_segment_inst	
		,c_l.limit_segment_pdl
		,case
				when pr.product =  'PDL' then isnull(c_l2.MAX_PMT_LIMIT_PDL, c_l.MAX_PMT_LIMIT_PDL)
				else isnull(c_l2.MAX_PMT_LIMIT_INST, c_l.MAX_PMT_LIMIT_INST)
			end as MAX_LIMIT
		,ad.Bankiru
		,ad.Bankiru_type
		,isnull(bo.Override_Banki, 0) as BankiruOver
	into #data_res
	from #data_set dsp
		left join #Auto_Approve aa
			on dsp.external_id = aa.Number
				and aa.rn = 1
		left join #without_overdue t_o
			on dsp.external_id = t_o.external_id
		left join #app_data as ad
			on dsp.external_id = ad.Number
			and ad.rn_for_drop = 1
		left join #calc_lim_call_1 as c_l 
			on dsp.external_id = c_l.number
			and c_l.rn = 1
			and c_l.stage = 'Call 1'
		left join #calc_lim_call_1 as c_l2
			on dsp.external_id = c_l2.number
			and c_l2.rn = 1
			and c_l2.stage = 'Call 2'
		left join #banki_over as bo
			on dsp.external_id = bo.number
			and bo.rn = 1
		left join #product as pr
			on dsp.external_id = pr.number
	;

drop table if exists [Risk].[v_portfolio_fpd_inst_pdl];

--13. Результа с подоговорными данными. Агрегированная таблица строится в Excel
select * 
		,case 
			when client_type = 'Первичный' then cast(0.5 as float)
			when client_type = 'Повторный' then cast(0.1 as float)
		end as Plan_fpd0
		,case	
			when factenddate is null													then 0
			when credit_type = 'PDL' and datediff(dd, startdate, factenddate) <= 0.75 * PDLTerm	then 1
			when credit_type = 'INST' and datediff(dd, startdate, factenddate) <= 0.75 * 14		then 1
			else 0
		end as FLG_clos_loan
		,(case
			when credit_type = 'PDL' and dateadd(dd, PDLTerm + 15, startdate) <getdate()	then 1
			when credit_type = 'INST' and dateadd(dd, 14 + 15, startdate) < getdate()		then 1
		end) * isnull(fpd15, 0) as FLG_fpd15_cnt
		,(case
			when credit_type = 'PDL' and dateadd(dd, PDLTerm + 15, startdate) <getdate()	then 1
			when credit_type = 'INST' and dateadd(dd, 14 + 15, startdate) < getdate()		then 1
		end) * isnull(sum_fpd15, 0) as FLG_fpd15_sum
				,(case
			when credit_type = 'PDL' and dateadd(dd, PDLTerm + 30, startdate) <getdate()	then 1
			when credit_type = 'INST' and dateadd(dd, 14 + 15, startdate) < getdate()		then 1
		end) * isnull(fpd15, 0) as FLG_fpd30_cnt
		,(case
			when credit_type = 'PDL' and dateadd(dd, PDLTerm + 30, startdate) <getdate()	then 1
			when credit_type = 'INST' and dateadd(dd, 14 + 30, startdate) < getdate()		then 1
		end) * isnull(sum_fpd15, 0) as FLG_fpd30_sum
		,cast(getdate() as date) as date_upd
	into [Risk].[v_portfolio_fpd_inst_pdl]
	from #data_res
	where generation >= '20240101';


end
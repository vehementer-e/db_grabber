CREATE procedure [riskCollection].[create_weekly_report] as
begin
--с 10.07.2025 изменения segment_weekly
--с 22.07.2025 изменения segment_weekly - добавление правила when [Тип продукта] = 'Инстоллмент' and [external_stage] = 'ИП' and [flag_IL] =  1 then 'ИП'
--с 23.07.2025 изменения segment_weekly - исключение and [external_stage] = 'ИП'
declare @rdt date;
set @rdt =(
SELECT
case when day(GETDATE()) > 20 then DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
when day(GETDATE()) <= 20 and MONTH(GETDATE()) = 1 then DATEFROMPARTS(YEAR(dateadd(yy,-1,GETDATE())), MONTH(dateadd(mm,-1,GETDATE())), 1)
else DATEFROMPARTS(YEAR(GETDATE()), MONTH(dateadd(mm,-1,GETDATE())), 1) end rdt)
;

BEGIN TRY
------------------------------добавляем мелкие бакеты и стадии на дату, день недели и номер недели
drop table if exists  #new_stages;
set datefirst 1;
select
*
,datepart(dw, d) as week_day
,datepart(ISO_WEEK, d) as week_num
,case 
	when dpd_p_coll = 0 then '(1)_0'
	when dpd_p_coll < 31 then '(2)_1_30'
	when dpd_p_coll < 61 then '(3)_31_60'
	when dpd_p_coll < 91 then '(4)_61_90'
	when dpd_p_coll < 121 then '(5)_91_120'
	when dpd_p_coll < 151 then '(6)_121_150'
	when dpd_p_coll < 181 then '(7)_151_180'
	when dpd_p_coll < 361 then '(8)_181_360'
	when dpd_p_coll < 1001 then '(9)_361_1000'
	when dpd_p_coll >= 1001 then '(91)_1000+'
	else bucket_p_portf
end bucket_weekly

/*,case
	when BankruptConfirmed = 1 then 'Bankrupt'
	when [external_stage] = 'Agency' or agent_name is not null  then 'Agency'
	when flag_IL = 1 then 'ИП'
	else 'Hard'
end segment_weekly*/ --с 10.07.2025

,case 
	when [BankruptConfirmed] = 1 then 'Bankrupt'
	when [external_stage] = 'Agency' then 'Agency'
	when [ClaimantStage] = 'Hard' and [flag_IL] =  1 then 'ИП'
	when [beznadega_status] = 'Безнадёжное взыскание подтверждено' 
		and [BankruptConfirmed] != 1 
		and [death_flag] !=1 
		and [kk_status] !=1 
		and [flag_IL] = 1 
	then 'ИП'
	when [Тип продукта] in ('Инстоллмент', 'Смарт-инстоллмент', 'PDL','Installment')
		--and [external_stage] = 'ИП' --с 23.07.2025
		and [flag_IL] = 1 
	then 'ИП' ---с 22.07.2025
	when [dpd_p_coll] > 90 then 'Hard' else '-'
end segment_weekly

into #new_stages
from riskCollection.collection_datamart
where d between @rdt and dateadd(dd,-1,cast(getdate() as date))
;
------------------------------входы в мелкие бакеты и в сегменты понедельно и помесячно
drop table if exists #incomes;
select *
,case 
	when week_day = 1 then prev_od
	when week_day > 1 and bucket_weekly != lag(bucket_weekly) over (partition by external_id order by d) then prev_od
	else 0
	end bal_bucket_weekly
,case
	when day(d) = 1 then prev_od
	when day(d) > 1 and bucket_weekly != lag(bucket_weekly) over (partition by external_id order by d) then prev_od
	else 0
	end bal_bucket_monthly

,case
	when day(d) = 1 then prev_od
	when day(d) > 1 and segment_weekly != lag(segment_weekly) over (partition by external_id order by d) then prev_od
	else 0
	end bal_segment_monthly
,case
	when week_day = 1 then prev_od
	when week_day > 1 and segment_weekly != lag(segment_weekly) over (partition by external_id order by d) then prev_od
	else 0
	end bal_segment_weekly

into #incomes
from #new_stages
;
------------------------------вывод только того, что нужно
drop table if exists  #final;
select
[d]
,[external_id]
,[Тип продукта]
,[dpd_coll]
,[dpd_p_coll]
,[dpd_last_coll]
,[bucket_coll]
,[bucket_coll_num]
,[bucket_p_coll]
,[bucket_p_coll_num]
,[bucket_last_coll]
,[bucket_last_coll_num]
,[bucket_last_p_coll]
,[bucket_last_p_coll_num]
,[остаток од]
,[prev_od]
,[prev_dpd_coll]
,[prev_dpd_p_coll]
,[pay_total]
,[ball_in_p1]
,[inflow]
,[inflow_old]
,[Saved_ballance]
,[reduced_balance]
,[ball_in_p]
,[external_stage]
,[ClaimantStage]
,[fio]
,[crmclientstage]
,[agent_name]
,[claimant_fio]
,[ballance_flag]
,[Сумма принятия на баланс]
,[death_flag]
,[fssp_pays]
,[beznadega_status]
,[BankruptConfirmed]
,[kk_status]
,[flag_IL]
,[claimant_ip_fio]
,[restr]
,[bucket_p_portf]
,[week_day]
,[week_num]
,[bucket_weekly]
,[segment_weekly]
,[bal_bucket_weekly]
,[bal_bucket_monthly]
,[bal_segment_weekly]
,[bal_segment_monthly]
,[Наименование продукта]
into #final
from #incomes
where pay_total > 0
	or Saved_ballance > 0
	or bal_bucket_weekly > 0
	or bal_bucket_monthly > 0
	or bal_segment_weekly > 0
	or bal_segment_monthly > 0
;
----------------------------------внесение данных
if OBJECT_ID('riskcollection.weekly_report') is null
begin
	select top(0) * into riskcollection.weekly_report
	from #final
end;

BEGIN TRANSACTION
	delete from riskcollection.weekly_report
	where d between @rdt and dateadd(dd,-1,cast(getdate() as date));

	insert into riskcollection.weekly_report
	select * from #final;
COMMIT TRANSACTION;

drop table if exists #new_stages;
drop table if exists #incomes;
drop table if exists #final;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END;
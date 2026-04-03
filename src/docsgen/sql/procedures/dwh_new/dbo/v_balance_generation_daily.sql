
CREATE procedure [dbo].[v_balance_generation_daily]( @maxdt date)
as

-- создаем новый день для всех займов

--32575

--declare @maxdt date = '20190603'
if object_id('tempdb.dbo.#maket') is not null drop table #maket
select 
 [credit_id] = c.id
,[external_id] = c.external_id
,[request_id] = c.request_id
,[cdate] = @maxdt
,[generation] = c.generation
,[grp] = case when ag.[group] is null then 'Собственный' else 'Агентский' end
,[agent_pool] = ag.[group]
,[credit_date] = c.start_date
,[CreditDays]  = DATEDIFF(day,cast(c.start_date as date),@maxdt)
,[CreditMonths] = DATEDIFF(month,cast(c.start_date as date),@maxdt)
,[default_date] = dc.default_date
,[default_date_year] = year(dc.default_date)
,[default_date_month] = replace(DATENAME(month, dc.default_date),' ','') + ' ' + replace(str(Year(dc.default_date)),' ','')
,[days_from_default] = case when DATEDIFF(day,dc.default_date,@maxdt)<0 then null else DATEDIFF(day,dc.default_date,@maxdt) end
,[amount] = c.amount
,[term] = c.term
,[active_credit] = case when (ch.stage_time IS NULL) or (ch.stage_time >@maxdt)  then 1  else 0 end
,[end_date] = ch.stage_time
,[writeoff_status] = isnull(dr.writeoff_status, 'Не реструктурирован')
into #maket
from tmp_v_credits c
left join (select external_id, [group] = reestr , rn=ROW_NUMBER() over (partition by external_id order by [st_date] desc) from v_agent_credits) ag on ag.External_id=c.external_id and ag.rn =1
left join (select credit_id, stage_time, rn=ROW_NUMBER() over (partition by credit_id order by stage_time desc)	from [dbo].[credits_history] where status=1) ch on ch.credit_id=c.id and ch.rn=1
left join v_default_credits dc on dc.credit_id = c.id
left join [dbo].[debt_isrestructured] dr on dr.external_id=c.external_id
where cast(c.start_date  as date) <=@maxdt

--32602

--select count(*) from tmp_v_credits where cast(start_date  as date) <='20190603'
--select count(distinct external_id) from tmp_v_credits
--32667
--32652 - distinct
--select count(distinct external_id) from #maket

-- добавляем данные по портфелю
-- метериализируем предсставление balance_pivot

if object_id('tempdb.dbo.#balance_pivot') is not null drop table #balance_pivot
select * into #balance_pivot from balance_pivot

if object_id('tempdb.dbo.#result') is not null drop table #result
select
 m.[credit_id] 
,m.[external_id]
,m.[request_id] 
,m.[cdate]
,m.[generation] 
,m.[grp] 
,m.[agent_pool]
,m.[credit_date]
,m.[CreditDays] 
,m.[CreditMonths]
,m.[default_date]
,m.[default_date_year] 
,m.[default_date_month]
,m.[days_from_default]
,m.[amount]
,m.[term]
,m.[active_credit]
,m.[end_date]
,m.[writeoff_status]
,b.[principal_cnl]
,b.[percents_cnl]
,b.[fines_cnl]
,b.[overpayments_cnl]
,b.[otherpayments_cnl]
,b.[principal_acc]
,b.[percents_acc]
,b.[fines_acc]
,b.[overpayments_acc]
,b.[otherpayments_acc]
,b.[principal_wo]
,b.[percents_wo]
,b.[fines_wo]
,b.[overpayments_wo]
,b.[otherpayments_wo]
into #result
from #maket m
left join #balance_pivot b on b.cdate = m.cdate and m.external_id = b.external_id

--32602
-- суммируем с предыдущим днем накопительный остаток
-- добавляем остальные измерения

select 
	   r.[credit_id]
      ,r.[external_id]
      ,r.[request_id]
      ,r.[cdate]
      ,r.[generation]
      ,r.[grp]
      ,r.[agent_pool]
      ,r.[credit_date]
      ,r.[CreditDays]
      ,r.[CreditMonths]
      ,r.[default_date]
      ,r.[default_date_year]
      ,r.[default_date_month]
      ,r.[days_from_default]
      ,r.[amount]
      ,r.[term]
      ,r.[principal_cnl]
      ,r.[percents_cnl]
      ,r.[fines_cnl]
      ,r.[overpayments_cnl]
      ,r.[otherpayments_cnl]
      ,r.[principal_acc]
      ,r.[percents_acc]
      ,r.[fines_acc]
      ,r.[overpayments_acc]
      ,r.[otherpayments_acc]
      ,r.[principal_wo]
      ,r.[percents_wo]
      ,r.[fines_wo]
      ,r.[otherpayments_wo]
      ,[principal_acc_run] = isnull(r.[principal_acc],0) + isnull(p.[principal_acc_run] ,0)
      ,[principal_cnl_run] = isnull(r.[principal_cnl],0) + isnull(p.[principal_cnl_run] ,0)
      ,[percents_acc_run] = isnull(r.[percents_acc],0) + isnull(p.[percents_acc_run] ,0)
      ,[percents_cnl_run] = isnull(r.[percents_cnl],0) + isnull(p.[percents_cnl_run] ,0)
      ,[fines_acc_run] = isnull(r.[fines_acc],0) + isnull(p.[fines_acc_run] ,0)
      ,[fines_cnl_run] = isnull(r.[fines_cnl],0) + isnull(p.[fines_cnl_run] ,0)
      ,[overpayments_acc_run] = isnull(r.[overpayments_acc],0) + isnull(p.[overpayments_acc_run] ,0)
      ,[otherpayments_acc_run] = isnull(r.[otherpayments_acc],0) + isnull(p.[otherpayments_acc_run] ,0)
      ,[overpayments_cnl_run] = isnull(r.[overpayments_cnl],0) + isnull(p.[overpayments_cnl_run] ,0)
      ,[otherpayments_cnl_run] = isnull(r.[otherpayments_cnl],0) + isnull(p.[otherpayments_cnl_run] ,0)
      ,[principal_rest] = p.[principal_rest] - isnull(r.[principal_cnl],0) - isnull(r.[principal_wo],0)
      ,[percents_rest] = p.[percents_rest] - isnull(r.[percents_cnl],0) - isnull(r.[percents_wo],0)
      ,[fines_rest] = p.[fines_rest] - isnull(r.[fines_cnl],0) - isnull(r.[fines_wo],0)
      ,[other_payments_rest] = p.[other_payments_rest] - isnull(r.[otherpayments_cnl],0) - isnull(r.[otherpayments_wo],0)
      ,[total_rest] = p.[total_rest]  - isnull(r.[principal_cnl],0) - isnull(r.[principal_wo],0)  - isnull(r.[percents_cnl],0) - isnull(r.[percents_wo],0) - isnull(r.[fines_cnl],0) - isnull(r.[fines_wo],0) - isnull(r.[otherpayments_cnl],0) - isnull(r.[otherpayments_wo],0)
      ,[principal_rest_wo] = p.[principal_rest] - isnull(r.[principal_cnl],0)
      ,[percents_rest_wo] = p.[percents_rest] - isnull(r.[percents_cnl],0)
      ,[fines_rest_wo] = p.[fines_rest] - isnull(r.[fines_cnl],0)
      ,[total_rest_wo] = p.[total_rest]  - isnull(r.[principal_cnl],0) - isnull(r.[percents_cnl],0) - isnull(r.[fines_cnl],0) - isnull(r.[otherpayments_cnl],0) 
      ,[overdue_days] = isnull(cd.overdue_days,0)
      ,[overdue] = cd.overdue
      ,[overdue_days_p] = isnull(cd2.overdue_days,0)
      ,[PaymentSystems_id] = ps.PaymentSystems_id 
      ,[Priority_PaymentSystem_id] = prs.Priority_PaymentSystem_id
      ,[bucket_id] = case when db.bucket_id = 0 then 99 else db.bucket_id end
      ,[overdue_days_flowrate] = isnull(cd.overdue_days, p.[overdue_days_flowrate] ) 
      ,r.[active_credit]
      ,r.[end_date]
      ,[KOEFF_4054U] = rc.[KOEFF_4054U]
      ,[KOEFF_493P] = rc.[KOEFF_493P]
      ,[reserve_4054U] = rc.[KOEFF_4054U] * (p.[principal_rest] - isnull(r.[principal_cnl],0) - isnull(r.[principal_wo],0))
      ,[reserve_493P] = rc.[KOEFF_493P] * (p.[principal_rest] - isnull(r.[principal_cnl],0) - isnull(r.[principal_wo],0)) 
      ,[reserve_493P_v2] = ru.reserved
      ,[real_paymen_amount] = case when (r.principal_cnl + r.percents_cnl + r.fines_cnl + r.overpaymentS_cnl)>0 then
								case 
									when isnull(cd2.overdue_days,0) >0 and isnull(cd2.overdue_days,0) <91 then
												p.principal_acc_run + p.percents_acc_run + p.fines_acc_run - p.principal_cnl_run - p.percents_cnl_run - p.fines_cnl_run
									when isnull(cd2.overdue_days,0) >90 then 
											isnull(r.principal_cnl,0)+  isnull(r.percents_cnl,0)+  isnull(r.fines_cnl,0)+ isnull(r.overpaymentS_cnl,0)+ isnull(r.otherpayments_cnl,0)- isnull(r.overpayments_acc,0)
									when isnull(cd2.overdue_days,0) =0 then 
										CASE 
											WHEN isnull(cd.overdue_days, p.[overdue_days_flowrate]) >120
											THEN  isnull(r.principal_cnl,0)+  isnull(r.percents_cnl,0)+  isnull(r.fines_cnl,0)+ isnull(r.overpaymentS_cnl,0)+ isnull(r.otherpayments_cnl,0)- isnull(r.overpayments_acc,0)
											ELSE 0
										END
									else 0
								end
								else 0
								end
      ,[total_CF] = isnull(r.principal_cnl,0)+  isnull(r.percents_cnl,0)+  isnull(r.fines_cnl,0)+ isnull(r.overpaymentS_cnl,0)+ isnull(r.otherpayments_cnl,0)- isnull(r.overpayments_acc,0)
      ,[is_hard] = case WHEN isnull(cd.overdue_days, p.[overdue_days_flowrate]) >120 then 1 else 0 end
      ,r.[writeoff_status]
from #result r
left join (select * from stat_v_balance2 where cdate = DATEADD(day,-1,@maxdt)) p  on p.external_id = r.external_id
left join credits_delays cd on cast(cd.creation_date as date)  = r.cdate and cd.credit_id=r.credit_id
left join v_credit_delays cd2 on cast(cd2.creation_date as date)  = r.cdate and cd2.credit_id=r.credit_id
left join (
	   SELECT *, ROW_NUMBER() OVER (PARTITION BY external_id, cast(date as date) ORDER BY Amount DESC) AS rn FROM dbo.PaymentSystems_payments
		  ) ps on ps.external_id=r.external_id and  cast(ps.date as date) = r.cdate and ps.rn=1
left join [dbo].[dim_overdue_buckets] db on db.cdays = isnull(cd.overdue_days,0)
LEFT  JOIN reserve_koef AS rc ON year(rc.CDATE)*100+ month(rc.CDATE) = year(r.CDATE)*100 + month(r.cdate) AND rc.bucket_id = case when db.bucket_id = 0 then 99 else db.bucket_id end
LEFT  JOIN (
		select date, External_id, sum(isnull(reserve,0)) reserved from [dwh_new].[dbo].[reserve_umfo_new] group by date, External_id
		   ) ru ON month(ru.DATE) = month(r.cdate) AND year(ru.DATE) = year(r.cdate) AND ru.External_id = r.external_id
left join v_priority_payment_system prs on prs.external_id =r.external_id
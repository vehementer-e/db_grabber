
CREATE procedure [dbo].[v_balance_generation]
as

if object_id('tempdb.dbo.#ru') is not null drop table #ru
select date, External_id, sum(isnull(reserve,0)) reserved into #ru from [dwh_new].[dbo].[reserve_umfo_new] group by date, External_id

if object_id('tempdb.dbo.#balance_a') is not null drop table #balance_a
SELECT 
			cast(b.moment as date) date,
			b.external_id,
			  sum(isnull(b.principal,0) + isnull(b.percents,0) + isnull(b.fines,0) ) amountsum,
			  p.amount,
			  p.PaymentSystems_id
        into #balance_a
	   FROM balance b left join dbo.PaymentSystems_payments p on p.external_id = b.external_id and cast(b.moment as date) = cast(p.date as date) and b.action_type_id=0 
	   where 
	   --b.external_id='1704186170001' 
		b.action_type_id=0
	   group by cast(b.moment as date),
				b.external_id,
			  p.amount,
			  p.PaymentSystems_id


if object_id('tempdb.dbo.#balance_b') is not null drop table #balance_b
SELECT *,ROW_NUMBER() OVER (PARTITION BY a.external_id ORDER BY date DESC) AS rn
into #balance_b
	FROM 
	#balance_a a

if object_id('tempdb.dbo.#balance_c') is not null drop table #balance_c
  select external_id, PaymentSystems_id  , count(*) qty 
  into #balance_c
  from 	#balance_b B
	WHERE B.rn < 6
	group by  external_id, PaymentSystems_id



  if object_id('tempdb.dbo.#balance_d') is not null drop table #balance_d
  select
	external_id,
	PaymentSystems_id,
	ROW_NUMBER() over (partition by external_id order by qty desc) as rnk
  into  #balance_d
	from  #balance_c C 


  if object_id('tempdb.dbo.#balance_e') is not null drop table #balance_e
select 
	external_id,
	PaymentSystems_id as Priority_PaymentSystem_id
  into #balance_e
	from #balance_d d
	where rnk=1



if object_id('tempdb.dbo.#ps') is not null drop table #ps
SELECT *,
			 ROW_NUMBER() OVER (PARTITION BY external_id, cast(date as date) ORDER BY Amount DESC) AS rn
       into #ps
	   FROM dbo.PaymentSystems_payments


if object_id('tempdb.dbo.#b2') is not null drop table #b2
SELECT 
		sum(principal)*(-1) principal,
		sum(percents)*(-1) percents,
		sum(fines)*(-1) fines,
		sum(overpayment)*(-1) overpayments,
		sum(other_payments)*(-1) other_payments,
		cast(moment as date) CDATE,
		external_id
    into #b2
		FROM balance_wtiteoff 
		GROUP BY 
		cast(moment as date) ,
		external_id


if object_id('tempdb.dbo.#b1') is not null drop table #b1
SELECT 
		sum(isnull(principal,0)) principal,
		sum(isnull(percents,0)) percents,
		sum(isnull(fines,0)) fines,
		sum(isnull(overpayment,0)) overpayments,
		sum(isnull(other_payments,0)) other_payments,
		cast(moment as date) CDATE,
		external_id
    into #b1
		FROM balance WHERE
		action_type_id=1
		--and principal>0 and percents>0 and fines>0 and other_payments>0
		GROUP BY 
		cast(moment as date) ,
		external_id

if object_id('tempdb.dbo.#b0') is not null drop table #b0
SELECT 
		sum(isnull(principal,0)) principal,
		sum(isnull(percents,0)) percents,
		sum(isnull(fines,0)) fines,
		sum(isnull(overpayment,0)) overpayments,
		sum(isnull(other_payments,0)) other_payments,
		cast(b.moment as date) CDATE,
		b.external_id
    into #b0
		FROM balance b 
		WHERE
		action_type_id=0
		GROUP BY 
		cast(b.moment as date) ,
		b.external_id

if object_id('tempdb.dbo.#ac') is not null drop table #ac
select  external_id
,[date] = st_date
, isnull([end_date]
, getdate()) as [end_date]
, max(reestr) [group] 
into #ac
from v_agent_credits 
where External_id is not null 
group by external_id,st_date, isnull([end_date], getdate()) 

if object_id('tempdb.dbo.#tb1') is not null drop table #tb1
select 
		credit_id,
		end_date 
    into #tb1
		from(
		select
		credit_id,
		stage_time as end_date ,
		ROW_NUMBER() over (partition by credit_id order by stage_time desc) rnk
    
    
		from  		[dbo].[credits_history]
		where 
		status=1
    ) tb1 where rnk=1


if object_id('tempdb.dbo.#AAA') is not null drop table #AAA
    select cast(cd1.creation_date as date) as cdate
                            , cd1.credit_id
                            , ROW_NUMBER() over (partition by cd1.credit_id order by cast(cd1.creation_date as date) desc) rnk  
                            into #AAA
                         from v_credit_delays cd1 
                        where cd1.overdue_days =91 


if object_id('tempdb.dbo.#BBB') is not null drop table #BBB
select cdate
     , credit_id
  into #BBB 
  from #AAA AAA 
 where rnk=1


if object_id('tempdb.dbo.#RES') is not null drop table #RES
 		select 
		credit_id = c.id,
		c.external_id,
		c.request_id,
		cdate = cast(cn.created as date),
		
		credit_date = cast(c.start_date as date),
		CreditDays = DATEDIFF(day,cast(c.start_date as date),cast(cn.created as date)),
		CreditMonths = DATEDIFF(month,cast(c.start_date as date),cast(cn.created as date)),
		default_date = BBB.cdate,
		default_date_year = Year(BBB.cdate),
		default_date_month = replace(DATENAME(month, BBB.cdate),' ','') + ' ' + replace(str(Year(BBB.cdate)),' ',''),
		days_from_default = case when DATEDIFF(day,BBB.cdate,cast(cn.created as date))<0 then null else DATEDIFF(day,BBB.cdate,cast(cn.created as date)) end,
		c.amount,
		c.term,
		ch.end_date
    into #RES
		from tmp_v_credits c
		left join #BBB  BBB on BBB.credit_id=c.id
	
		left join  #tb1 ch on ch.credit_id=c.id,
		calendar cn
		--where cn.created>=c.start_date and cn.created<=getdate()
		where cn.created>=cast(c.start_date as date) and cn.created<=getdate()
		-- and cn.created<=isnull(ch.end_date,getdate())
		--and  c.external_id='1708283810001'
		--select count(*) from tmp_v_credits where cast(start_date as date)<=cast('20190603' as date)
		--select count(*) from #res where cdate = '20190603'

		 

--select * from #rset where external_id = '17122703530002' and cdate = '20190430'
--select * from #ac  where External_id = '17122703530002'
--select * from #b0  where External_id = '17122703530002' order by cdate
--select * from #b1  where External_id = '17122703530002' order by cdate
--select * from #b2  where External_id = '17122703530002' order by cdate
--select * from credits_delays  where credit_id=11361 and cast(creation_date as date) = '20190430' 
--select * from staging.credits_delays  where External_id = '17122703530002' and cast(creation_date as date) = '20190430' 


create index idx1 on #rset  (external_id)
create index idx2 on #rset (cdate)








--select count(*) from #rset
--select count(*) from #RES
--select count(*) from dwh_new.dbo.mv_balance_3

--select cdate,external_id,count(*) from #rset group by cdate,external_id order by 3 desc





if object_id('dwh_new.dbo.mv_balance_3') is not null drop table dwh_new.dbo.mv_balance_3
select
rset.credit_id,
rset.external_id,
rset.request_id,
rset.cdate,
rset.generation,
rset.grp,
rset.agent_pool,
rset.credit_date,
rset.CreditDays,
rset.CreditMonths,
rset.default_date,
rset.default_date_year,
rset.default_date_month,
rset.days_from_default,
rset.amount,
rset.term,
rset.principal_cnl,
rset.percents_cnl,
rset.fines_cnl,
rset.overpayments_cnl,
rset.otherpayments_cnl ,
rset.principal_acc,
rset.percents_acc,
rset.fines_acc,
rset.overpayments_acc,
rset.otherpayments_acc,

rset.principal_wo,
rset.percents_wo,
rset.fines_wo,
rset.otherpayments_wo,
--principal_wo = case when rset.principal_acc <0 then  rset.principal_acc *(-1) else 0 end,
--percents_wo = case when rset.percents_acc <0 then  rset.percents_acc *(-1) else 0 end,
--fines_wo = case when rset.fines_acc <0 then  rset.fines_acc *(-1) else 0 end,
--otherpayments_wo = case when rset.otherpayments_acc <0 then  rset.otherpayments_acc *(-1) else 0 end,

rset.principal_acc_run,
rset.principal_cnl_run,
rset.percents_acc_run,
rset.percents_cnl_run,
rset.fines_acc_run,
rset.fines_cnl_run,
rset.overpayments_acc_run,
rset.otherpayments_acc_run ,
rset.overpayments_cnl_run,
rset.otherpayments_cnl_run ,
--rset.principal_rest,
principal_rest= rset.amount-rset.principal_cnl_run,
--rset.percents_rest,
percents_rest= rset.percents_acc_run-rset.percents_cnl_run,
--rset.fines_rest,
fines_rest = rset.fines_acc_run-rset.fines_cnl_run,
--added 290519 by turabov
other_payments_rest = rset.otherpayments_acc_run - rset.otherpayments_cnl_run , 
-- end 
--rset.total_rest,
total_rest = (rset.amount-rset.principal_cnl_run)+(rset.percents_acc_run-rset.percents_cnl_run)+(rset.fines_acc_run-rset.fines_cnl_run) + (rset.otherpayments_acc_run - rset.otherpayments_cnl_run),

principal_rest_wo= rset.amount-rset.principal_cnl_run + rset.principal_wo,
percents_rest_wo= rset.percents_acc_run-rset.percents_cnl_run + rset.percents_wo,
fines_rest_wo = rset.fines_acc_run-rset.fines_cnl_run + rset.fines_wo,
total_rest_wo = (rset.amount-rset.principal_cnl_run  + rset.principal_wo)+
				(rset.percents_acc_run-rset.percents_cnl_run+ rset.percents_wo)+
				(rset.fines_acc_run-rset.fines_cnl_run + rset.fines_wo),
				 

rset.overdue_days,
rset.overdue,
rset.overdue_days_p,
rset.PaymentSystems_id,
rset.Priority_PaymentSystem_id,
rset.bucket_id,
rset.overdue_days_flowrate,
rset.active_credit,
rset.end_date,
rc.KOEFF_4054U, 
rc.KOEFF_493P,
--reserve_4054U=rc.KOEFF_4054U*rset.principal_rest,
--reserve_493P=rc.KOEFF_493P*rset.principal_rest
reserve_4054U=rc.KOEFF_4054U*(rset.amount-rset.principal_cnl_run),
reserve_493P=rc.KOEFF_493P*(rset.amount-rset.principal_cnl_run),
reserve_493P_v2=ru.reserved 
,
	real_paymen_amount = 
	case when (rset.principal_cnl + rset.percents_cnl + rset.fines_cnl + rset.overpaymentS_cnl)>0 then
		case 
			when rset.overdue_days_p >0 and rset.overdue_days_p <91 then
					 --isnull(rset.principal_cnl,0)+  isnull(rset.percents_cnl,0)+	 isnull(rset.fines_cnl,0)
					 LAG (principal_acc_run+percents_acc_run+fines_acc_run-principal_cnl_run-percents_cnl_run-fines_cnl_run, 1, 0) OVER (PARTITION BY rset.external_id ORDER BY rset.cdate )
			when rset.overdue_days_p >90 then 
				 isnull(rset.principal_cnl,0)+  isnull(rset.percents_cnl,0)+  isnull(rset.fines_cnl,0)+ isnull(rset.overpaymentS_cnl,0)+ isnull(rset.otherpayments_cnl,0)- isnull(rset.overpayments_acc,0)
			when isnull(rset.overdue_days_p,0) =0 then 
				CASE 
					WHEN rset.overdue_days_flowrate>120
					THEN  isnull(rset.principal_cnl,0)+  isnull(rset.percents_cnl,0)+  isnull(rset.fines_cnl,0)+ isnull(rset.overpaymentS_cnl,0)+ isnull(rset.otherpayments_cnl,0)- isnull(rset.overpayments_acc,0)
					ELSE 0
				END
			else 0
		end
		else 0
		end
,total_CF = isnull(rset.principal_cnl,0)+  isnull(rset.percents_cnl,0)+  isnull(rset.fines_cnl,0)+ isnull(rset.overpaymentS_cnl,0)+ isnull(rset.otherpayments_cnl,0)- isnull(rset.overpayments_acc,0)
,is_hard = case WHEN rset.overdue_days_flowrate>120 then 1 else 0 end
--added 190519 by turabov
,writeoff_status = isnull(dr.writeoff_status, 'Не реструктурирован')
--,real_paymen_amount_run=	SUM(isnull(rset.real_paymen_amount,0)) OVER(partition by rset.credit_id ORDER BY rset.cdate
--	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
into dwh_new.dbo.mv_balance_3
from #rset rset
LEFT  JOIN reserve_koef AS rc ON month(rc.CDATE) = month(rset.cdate) AND year(rc.CDATE) = year(rset.cdate) AND rc.bucket_id = rset.BUCKET_ID
LEFT  JOIN #ru AS ru ON month(ru.DATE) = month(rset.cdate) AND year(ru.DATE) = year(rset.cdate) AND ru.External_id = rset.external_id
--added by turabov 190519
left join [dbo].[debt_isrestructured] dr on dr.external_id=rset.external_id


CREATE      proc [dbo].[sale_report_kpi_metrics] @mode nvarchar(max) = 'select'
as 
 --return
 


 if @mode = 'select'
select * from kpi_metrics where 1=1 and 1=1 --group by --order by 1
 
 
 if @mode = 'send'
exec python 'kpi_metrics(test=False)', 1


 if @mode = 'update'
 begin





drop table if exists #rr
select * into #rr from  v_rr where 1=1 and 1=1 --group by --order by 1
--and 1=0

if 1=0 begin
delete from #rr
insert into #rr
select cast(DATEADD(MONTH, -1+ DATEDIFF(MONTH, 0,       getdate()    ), 0) as date)  , 1, 1

end

declare @date date = (select month from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
declare @rr float = (select rr_pts from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
drop table if exists #t72891381981201390

select type , MONTH, metric , @rr rr into #t72891381981201390 from (
select 'sums '+ returnType2  + case when ispts=1 then ' ПТС' else ' INST' end type,  @date month, sum(a.issuedSum  ) metric  from v_fa  a
where issued_month = @date and issued<cast(getdate() as date) 
and isnull(a.source , '') not like 'psb%'
and producttype <>'AUTOCREDIT'
group by returnType2, ispts
 

union all


 
select 'sums AUTOCREDIT'   type,  @date month, sum(a.issuedSum  ) metric  from v_fa  a
where issued_month = @date and issued<cast(getdate() as date) 
 
and producttype = 'AUTOCREDIT'
group by returnType2, ispts


union all

 
select 'sums PSB '+ returnType2  + case when ispts=1 then ' ПТС' else ' INST' end type,  @date month, sum(a.issuedSum  ) metric  from v_fa  a
where issued_month = @date and issued<cast(getdate() as date) 
and isnull(a.source , '')   like 'psb%'
and producttype <>'AUTOCREDIT'
group by returnType2, ispts


 
union all

 
select 'sums T-Bank '+ returnType2  + case when ispts=1 then ' ПТС' else ' INST' end type,  @date month, sum(a.issuedSum  ) metric  from v_fa  a
where issued_month = @date and issued<cast(getdate() as date) 
and isnull(a.source , '')   like 'tbank%'
and producttype <>'AUTOCREDIT'
group by returnType2, ispts


union all



select 'kps '+ returnType2  + case when ispts=1 then ' ПТС' else ' INST' end,  @date ,  sum(a.[Сумма Дополнительных Услуг Carmoney Net] ) metric from v_fa  a
where issued_month = @date and issued<cast(getdate() as date)  and isnull(a.source , '') not like 'psb%'
and producttype <>'AUTOCREDIT'
group by returnType2, ispts


union all



select 'kps psb '+ returnType2  + case when ispts=1 then ' ПТС' else ' INST' end,  @date ,  sum(a.[Сумма Дополнительных Услуг Carmoney Net] ) metric from v_fa  a
where issued_month = @date and issued<cast(getdate() as date)  and isnull(a.source , '')   like 'psb%'
and producttype <>'AUTOCREDIT'
group by returnType2, ispts


union all



select 'kps T-Bank '+ returnType2  + case when ispts=1 then ' ПТС' else ' INST' end,  @date ,  sum(a.[Сумма Дополнительных Услуг Carmoney Net] ) metric from v_fa  a
where issued_month = @date and issued<cast(getdate() as date)  and isnull(a.source , '')   like 'tbank%'
and producttype <>'AUTOCREDIT'
group by returnType2, ispts





union all

select 'loans '+ returnType2  + case when ispts=1 then ' ПТС' else ' INST' end,  @date ,  sum(a.isLoan ) metric from v_fa  a
where issued_month = @date and issued<cast(getdate() as date) and isnull(a.source , '') not like 'psb%'
and producttype <>'AUTOCREDIT'
group by returnType2, ispts

  
union all
  

 select 'costs' +' '+   returnType2 + case when ispts=1 then ' ПТС' else ' INST' end  , @date month, sum(a.marketingCost) metric from [v_request_cost]  a
 where  a.month = @date and   a.date<cast(getdate() as date) and isnull(a.source , '') not like 'psb%'
and producttype <>'AUTOCREDIT'
 group by  'costs' +' '+   returnType2 + case when ispts=1 then ' ПТС' else ' INST' end 
 --order by
 
union all
 
 
 select 'sell_traffic' +' '+   returnType2 + case when ispts=1 then ' ПТС' else ' INST' end  , @date month, sum(a.sellTrafficIncomeNet) metric from [v_request_cost]  a
  where a.month = @date and   a.date<cast(getdate() as date) and isnull(a.source , '') not like 'psb%'
and producttype <>'AUTOCREDIT'

 group by   'sell_traffic' +' '+   returnType2 + case when ispts=1 then ' ПТС' else ' INST' end
 --order by

union all
 
--declare @date date = (select month from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
--declare @rr float = (select rr_pts from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
select 'sms' , @date month,  sum(comc)
+@rr* max(aero) metric  from (


 select   a.created,  a.source, isnull( a.parts, 1) parts , isnull( a.parts, 1)*cast(b.cost_of_sms as numeric(15,5)) comc, sms_aero_costs  aero from v_sms  a 
 join marketing_cost_sms b on a.month=b.month
  where a.month= @date and isnull(source, '')<>'SPACE'
  --where a.month=@date and source<>'SPACE'

  ) x 

union all
   


 select 'calls' , a.month, sum(costs ) metric from v_costs_calls  a 
 
 -- where a.month='20240801' 
  where a.month=@date 
  group by a. month
  ) 
  x
  
 --drop table if exists _birs.kpi_monitoring_metrics
 --select * into  _birs.kpi_monitoring_metrics from #t72891381981201390
delete from  kpi_metrics
insert into  kpi_metrics
select * from #t72891381981201390 

/*
exec exec_python 'from REPORTS.CM_reports import kpi_metrics
kpi_metrics(test=True)', 1

*/

--exec exec_python 'kpi_metrics()', 1

--exec [_birs].[kpi_monitoring] 'update'


--exec python 'from REPORTS.CM_reports import psb_out
--psb_out(test=False)', 1



--exec python 'from REPORTS.CM_reports import infoseti
--infoseti(test=False)', 1

--exec python 'from REPORTS.CM_reports import psb_deepapi
--psb_deepapi(test=False)', 1

--exec python 'from REPORTS.CM_reports import kpi_metrics
--kpi_metrics(test=False, add_subject="КОРРЕКТИРОВКА СУММЫ ПТС")', 1

--exec python 'from REPORTS.CM_reports import kpi_metrics
--kpi_metrics(test=True, add_subject="ИТОГ")', 1


end

--План 	Факт 	rr
--сумма птс 	 	 
--сумма беззалог 	 	 
--новые 	 	 
--повторные 	 	 
--стоимость займа птс 	 	 
--стоимость займа беззалог 	 	 
--страховки птс 	 	 
--страховки беззалог 	 	 
--телефония 	 	 
--смс 	 	 
--продажа отказного трафика 	 	 
 

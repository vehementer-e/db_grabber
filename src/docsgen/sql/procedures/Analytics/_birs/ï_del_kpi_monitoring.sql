
CREATE     proc [_birs].[kpi_monitoring] @mode nvarchar(max) = 'select'
as
begin


--exec [_birs].[kpi_monitoring] 'update'
 


 if @mode = 'select'
select * from  _birs.kpi_monitoring_metrics where 1=1 and 1=1 --group by --order by 1




 if @mode = 'update'
 begin

 exec _gs 'costs_sms' 


drop table if exists #rr
select * into #rr from  v_rr where 1=1 and 1=1 --group by --order by 1


declare @date date = (select month from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
declare @rr float = (select rr_pts from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
drop table if exists #t72891381981201390

select type , MONTH, metric , @rr rr into #t72891381981201390 from (
select 'sums '+ loan_type2  + case when ispts=1 then ' ПТС' else ' INST' end type,  @date month, sum(a.issuedSum  ) metric  from v_fa  a
where issued_month = @date and issued<cast(getdate() as date)
group by loan_type2, ispts

--order by

union all

select 'kps '+ loan_type2  + case when ispts=1 then ' ПТС' else ' INST' end,  @date ,  sum(a.[Сумма Дополнительных Услуг Carmoney Net] ) metric from v_fa  a
where issued_month = @date and issued<cast(getdate() as date)
group by loan_type2, ispts


union all

select 'loans '+ loan_type2  + case when ispts=1 then ' ПТС' else ' INST' end,  @date ,  sum(a.is_Loan ) metric from v_fa  a
where issued_month = @date and issued<cast(getdate() as date)
group by loan_type2, ispts

  
union all
  

 select 'costs' +' '+   loan_type2 + case when ispts=1 then ' ПТС' else ' INST' end  , @date month, sum(a.[Маркетинговые расходы]) metric from [v_request_costs]  a
 where  a.month = @date and   a.date<cast(getdate() as date)
 group by  'costs' +' '+   loan_type2 + case when ispts=1 then ' ПТС' else ' INST' end 
 --order by
 
union all
 
 
 select 'sell_traffic' +' '+   loan_type2 + case when ispts=1 then ' ПТС' else ' INST' end  , @date month, sum(a.[Продажа трафика net]) metric from [v_request_costs]  a
  where a.month = @date and   a.date<cast(getdate() as date)

 group by   'sell_traffic' +' '+   loan_type2 + case when ispts=1 then ' ПТС' else ' INST' end
 --order by

union all
 
--declare @date date = (select month from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
--declare @rr float = (select rr_pts from #rr)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
select 'sms' , @date month,  sum(comc)
+@rr* max(aero) metric  from (


 select   a.created,  a.source, isnull( a.parts, 1) parts , isnull( a.parts, 1)*cast(b.cost_of_sms as numeric(15,5)) comc, sms_aero_costs  aero from v_sms  a 
 join _gsheets.dic_costs_sms b on a.month=b.month
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
delete from  _birs.kpi_monitoring_metrics
insert into  _birs.kpi_monitoring_metrics
select * from #t72891381981201390 

/*
exec exec_python 'from REPORTS.CM_reports import kpi_metrics
kpi_metrics(test=True)', 1

*/

--exec exec_python 'kpi_metrics()', 1

--exec [_birs].[kpi_monitoring] 'update'
exec exec_python 'from REPORTS.CM_reports import kpi_metrics
kpi_metrics(test=False)', 1


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



end



CREATE   PROC  [dbo].[sale_report_csi]
@mode nvarchar(max) = 'update'
as
begin

--sp_create_job 'Analytics._sale_report_csi each Q at 2nd day', 'sale_report_csi', '1', '120000'




IF 	@mode =  'archive2'
begin
drop table if exists #t2

select
que.enqueued_time as calltime,
employee.uuid as operator_title,
employee.login as operator_login,
que.project_id as project,
sp.SRC_ID as number_client,
qos.param_value as mark,
que.session_id as recordlink,
b.title	   ,
getdate() created
into #t2
from
NaumenDBReports_old.dbo.queued_calls que
join
NaumenDBReports_old.dbo.call_params_QoS qos
on qos.session_id = que.session_id and qos.param_name = 'QoS'
join
NaumenDBReports_old.dbo.call_legs sp
on sp.session_id = que.session_id

join
NaumenDBReports_old.dbo.mv_employee employee
on employee.login = sp.dst_abonent

left join  (select uuid, title from NaumenDBReports_old.dbo.mv_outcoming_call_project union all select uuid, title from NaumenDBReports_old.dbo.mv_incoming_call_project)		  b on que.project_id=b.uuid

where
not exists (select * from NaumenDBReports_old.dbo.queued_calls where session_id = que.session_id and enqueued_time > que.enqueued_time)
--and
--que.enqueued_time between '20220101' and '20231001'			    

--drop table if exists  _birs.csi
--select *  into _birs.csi
--from #t1
 
--select * into sale_kpi_csi 
--from _birs.csi 

delete a from sale_kpi_csi a join #t2 b on a.recordlink=b.recordlink
insert into 	   sale_kpi_csi
select * from #t2
order by 1 desc


end

 



IF 	@mode =  'archive'
begin
drop table if exists #t1

select
que.enqueued_time as calltime,
employee.uuid as operator_title,
employee.login as operator_login,
que.project_id as project,
sp.SRC_ID as number_client,
qos.param_value as mark,
que.session_id as recordlink,
b.title	   ,
getdate() created
into #t1
from
NaumenDBReportArch.dbo.queued_calls que
join
NaumenDBReport.dbo.call_params_QoS qos
on qos.session_id = que.session_id and qos.param_name = 'QoS'
join
NaumenDBReportArch.dbo.call_legs sp
on sp.session_id = que.session_id

join
NaumenDBReport.dbo.mv_employee employee
on employee.login = sp.dst_abonent

left join  (select uuid, title from NaumenDBReport.dbo.mv_outcoming_call_project union all select uuid, title from NaumenDBReport.dbo.mv_incoming_call_project)		  b on que.project_id=b.uuid

where
not exists (select * from NaumenDBReportArch.dbo.queued_calls where session_id = que.session_id and enqueued_time > que.enqueued_time)
--and
--que.enqueued_time between '20220101' and '20231001'			    

--drop table if exists  _birs.csi
--select *  into _birs.csi
--from #t1



--delete a from _birs.csi a join #stg b on a.recordlink=b.recordlink
--insert into 	   _birs.csi
--select * from #stg


end


IF 	@mode =  'update'

begin

drop table if exists #stg
  select
que.enqueued_time as calltime,
employee.uuid as operator_title,
employee.login as operator_login,
que.project_id as project,
sp.SRC_ID as number_client,
qos.param_value as mark,
que.session_id as recordlink ,
b.title	,
getdate() created
into #stg
from
NaumenDBReport.dbo.queued_calls que
join
NaumenDBReport.dbo.call_params_QoS qos
on qos.session_id = que.session_id and qos.param_name = 'QoS'
join
NaumenDBReport.dbo.call_legs sp
on sp.session_id = que.session_id

join
NaumenDBReport.dbo.mv_employee employee
on employee.login = sp.dst_abonent

left join  (select uuid, title from NaumenDBReport.dbo.mv_outcoming_call_project union all select uuid, title from NaumenDBReport.dbo.mv_incoming_call_project)		  b on que.project_id=b.uuid

where
not exists (select * from NaumenDBReport.dbo.queued_calls where session_id = que.session_id and enqueued_time > que.enqueued_time)
--and
--que.enqueued_time between '20220101' and '20231001'		




delete a from sale_kpi_csi a join #stg b on a.recordlink=b.recordlink
insert into 	 sale_kpi_csi
select * from #stg


 exec  sp_birs_update '0AE6CF15-827D-4FBC-AEB7-F55E07E602C2'
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '0AE6CF15-827D-4FBC-AEB7-F55E07E602C2'


exec log_email 'csi_creation ok'


 end


 if @mode = 'select'
 begin


 ;
 with v as(
 
  select *, ROW_NUMBER() over(partition by recordlink order by calltime ) rn from   sale_kpi_csi
  where isnumeric(mark)=1

 )

  select * from   v
  where rn=1

  order by 1


end

end






--; 
--select top 1000 recordlink, count(distinct mark) cnt, min(calltime) ct from sale_kpi_csi
--  where isnumeric(mark)=1

--group by recordlink
--order by 2 desc


--select * from sale_kpi_csi
--where recordlink = 'node_0_domain_2_nauss_0_1747179378_470491'

CREATE   proc [dbo].[_mv] @l nvarchar(max) = 'day', @recreate_table int = 0

as
begin

if @l='mv_dm_Factor_Analysis'
begin

   

--select top 0 * into mv_dm_Factor_Analysis_to_del   from mv_dm_Factor_Analysis
--select top 0 * into mv_dm_Factor_Analysis_staging  from mv_dm_Factor_Analysis


declare @counter int = 10
while exists(			 
select * from [v_Запущенные джобы] --sp_find_job
where 		  step_name='REPORTS [dbo].[create_dm_factor_analysis]'
--job_name='%____%'
--and job_name like '%____%'
--and current_executed_step_id=1
) and @counter>0
begin

--exec message 'message' 
waitfor delay '00:00:30'
set @counter = @counter-1
end 

if @counter=0
begin
--exec log_email 'awaiting REPORTS [dbo].[create_dm_factor_analysis]/ @counter = 0 => FAIL'
RAISERROR ('awaiting REPORTS [dbo].[create_dm_factor_analysis]/ @counter = 0 => FAIL',16,1)
end

drop table if exists   #mv_dm_Factor_Analysis
select * into          #mv_dm_Factor_Analysis
                  from   v_dm_Factor_Analysis




if @recreate_table=0 
begin 

delete from mv_dm_Factor_Analysis_to_del

delete from mv_dm_Factor_Analysis_staging
insert into mv_dm_Factor_Analysis_staging
SELECT *
from #mv_dm_Factor_Analysis


begin tran
--drop table if exists    mv_dm_Factor_Analysis
--select top 0 * into     mv_dm_Factor_Analysis  
--                  from #mv_dm_Factor_Analysis

--create clustered index t on mv_dm_Factor_Analysis
--(Номер)
--delete from             mv_dm_Factor_Analysis
--insert into             mv_dm_Factor_Analysis
--select * from          #mv_dm_Factor_Analysis

alter table mv_dm_Factor_Analysis
	switch to mv_dm_Factor_Analysis_to_del

alter table mv_dm_Factor_Analysis_staging 
	switch  to mv_dm_Factor_Analysis

commit tran
end 

if @recreate_table=1
begin 
begin tran

drop table if exists    mv_dm_Factor_Analysis_staging
select top 0 * into     mv_dm_Factor_Analysis_staging
                  from #mv_dm_Factor_Analysis
drop table if exists    mv_dm_Factor_Analysis_to_del
select top 0 * into     mv_dm_Factor_Analysis_to_del
                  from #mv_dm_Factor_Analysis

drop table if exists    mv_dm_Factor_Analysis
select top 0 * into     mv_dm_Factor_Analysis  
                  from #mv_dm_Factor_Analysis

delete from             mv_dm_Factor_Analysis
insert into             mv_dm_Factor_Analysis
select * from          #mv_dm_Factor_Analysis
--drop   index t on mv_dm_Factor_Analysis
--create clustered index t on mv_dm_Factor_Analysis
--(Номер)

commit tran
end 


drop table if exists   #mv_dm_Factor_Analysis
end



if @l='mv_COMCENTER_communications'
begin


drop table if exists   #mv_COMCENTER_communications
select * into          #mv_COMCENTER_communications
                  from   v_COMCENTER_communications

if @recreate_table=0 
begin 
begin tran
--drop table if exists    mv_COMCENTER_communications
--select top 0 * into     mv_COMCENTER_communications  
--                  from #mv_COMCENTER_communications
--create clustered index t on mv_COMCENTER_communications
--(Номер)
delete from             mv_COMCENTER_communications
insert into             mv_COMCENTER_communications
select * from          #mv_COMCENTER_communications
commit tran
end 

if @recreate_table=1
begin 
begin tran
drop table if exists    mv_COMCENTER_communications
select top 0 * into     mv_COMCENTER_communications  
                  from #mv_COMCENTER_communications

delete from             mv_COMCENTER_communications
insert into             mv_COMCENTER_communications
select * from          #mv_COMCENTER_communications
create clustered index t on mv_COMCENTER_communications
([Дата коммуникации], [Способ связи])
commit tran
end 


drop table if exists   #mv_COMCENTER_communications
end



if @l='lead_request_bi'
begin


drop table if exists   #lead_request_bi_mat
select * into           #lead_request_bi_mat
                  from  lead_request_bi

if @recreate_table=0 
begin 
begin tran
--drop table if exists    mv_COMCENTER_communications
--select top 0 * into     mv_COMCENTER_communications  
--                  from #mv_COMCENTER_communications
--create clustered index t on mv_COMCENTER_communications
--(Номер)
delete from             lead_request_bi_mat
insert into             lead_request_bi_mat
select * from          #lead_request_bi_mat
commit tran
end 

if @recreate_table=1
begin 
begin tran
drop table if exists    lead_request_bi_mat
select top 0 * into     lead_request_bi_mat  
                  from #lead_request_bi_mat

delete from             lead_request_bi_mat
insert into             lead_request_bi_mat
select * from          #lead_request_bi_mat

commit tran
end 



end





if @l = 'day'
begin

drop table if exists   #mv_loans
select * into          #mv_loans
                  from   v_loans
				  	  
if @recreate_table=1
begin
drop table if exists    mv_loans
select top 0 * into     mv_loans  
                  from #mv_loans
end

delete from             mv_loans
insert into             mv_loans
select * from          #mv_loans
drop table if exists   #mv_loans
  

 exec [dbo].[_mv] 'mv_clients'	   , @recreate_table



 exec [dbo].[_mv] 'mv_repayments'	   , @recreate_table

end




if @l = 'mv_clients'
begin

drop table if exists   #mv_clients
select * into          #mv_clients
                  from   v_clients
if @recreate_table=1
begin
drop table if exists   mv_clients
select top 0 * into     mv_clients
                  from #mv_clients
end

delete from             mv_clients
insert into             mv_clients
select * from          #mv_clients
--drop table if exists   ##mv_repayments
end



if @l = 'mv_repayments'
begin



exec [dbo].[_repayment_card_type_creation]

drop table if exists   ##mv_repayments2
select * into          ##mv_repayments2
                  from   v_repayments

drop table if exists   ##mv_repayments
 
select a.*, b.dpdbeginday into ##mv_repayments from ##mv_repayments2 a left join v_balance b with(nolock) on a.код=b.number and a.ДеньПлатежа=b.date 



if @recreate_table=1
begin
drop table if exists   mv_repayments
select top 0 * into     mv_repayments
                  from ##mv_repayments
end

delete from             mv_repayments
insert into             mv_repayments
select * from         ##mv_repayments
--drop table if exists   ##mv_repayments



exec [dbo].pay_report'repayments_update'
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'E5E9B676-D62C-4B40-B50A-D65EEE04DD40'




end



end



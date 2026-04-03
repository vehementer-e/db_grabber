-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl   process_requests_history_sql
--
--  exec etl.base_etl_process_requests_history_sql '20190224','20190305'
/*
insert into requests_history (external_link, request_id, stage_time, verifier, status, reject_reason, created) 
select r.external_link, r.id as request_id, creation_date as stage_time, v.id as verifier, s.id as status, rr.id as reject_reason, 
CURRENT_TIMESTAMP created  from staging.requests_history rh
join requests r on r.external_link = rh.external_link
left join statuses s  on Lower(s.name) = Lower(rh.status)
left join verifiers v  on Lower(v.name) = Lower(rh.verifier)
left join reject_reasons rr  on Lower(rr.name) = Lower(rh.reject_reason)
where creation_date between '{{params.start_date}}' and '{{params.end_date}}'

*/
-- =============================================
CREATE procedure [etl].[base_etl_process_requests_history_sql] @start_date datetime
,                                                             @end_date datetime
as
begin

	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	set @params= N' start_date='+cast(FORMAT (@start_date, 'dd.MM.yyyy HH:mm:ss ')
	as nvarchar(32))+'<br />'
	+N' end_date='+cast(FORMAT (@end_date, 'dd.MM.yyyy HH:mm:ss ')
	as nvarchar(32))
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      @params
	begin try


	declare @insertedRows int=0
	declare @result nvarchar(max)=''


  
/*
select * into dwh_new_dev.dbo.credit_statuses from dwh_new.dbo.credit_statuses
select * into dwh_new_dev.dbo.credits_history from dwh_new.dbo.credits_history
select *  from dbo.credits_history where created >'20190301' order by external_link,created

*/

	insert into requests_history ( external_link, request_id, stage_time, verifier, status, reject_reason, created )
	select r.external_link  
	,      r.id              as request_id
	,      creation_date     as stage_time
	,      v.id              as verifier
	,      s.id              as status
	,      rr.id             as reject_reason
	,      CURRENT_TIMESTAMP    created
	from      staging.requests_history rh
	join      requests                 r  on r.external_link = rh.external_link
	left join statuses                 s  on Lower(s.name) = Lower(rh.status)
	left join verifiers                v  on Lower(v.name) = Lower(rh.verifier)
	left join reject_reasons           rr on Lower(rr.name) = Lower(rh.reject_reason)
	where creation_date between @start_date and @end_date

	set @insertedRows=@@ROWCOUNT

	set @result=N' Results:<br /><br />'

	set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'






	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	,                                      @result
	end try
	begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+ cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+ cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
	+char(10)+char(13)+' ErrorState: '+ cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
	+char(10)+char(13)+' Error_line: '+ cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Error'
	,                                      'Error'
	,                                      @error_description
	;throw 51000, @error_description, 1
	end catch
end






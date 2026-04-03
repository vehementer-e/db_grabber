-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl process_credits_delays_sql
--
--  exec etl.base_etl_process_credits_delays_sql  '20190224','20190305'
/*
insert into credits_delays(external_link, credit_id, creation_date, overdue_days, overdue, created)
select c.external_link, c.id, creation_date, overdue_days, overdue, CURRENT_TIMESTAMP created from staging.credits_delays cd 
inner join credits c on cd.external_link = c.external_link
where creation_date between '{{params.start_date}}' and '{{params.end_date}}'

*/
-- =============================================
CREATE procedure [etl].[base_etl_process_credits_delays_sql] @start_date datetime
,                                                           @end_date datetime
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
    SELECT * into   DWH_NEW_dev.DBO.credits_delays FROM DWH_NEW.DBO.credits_delays
    */

	delete from credits_delays
	where creation_date between @start_date and @end_date

	insert into credits_delays ( external_link, credit_id, creation_date, overdue_days, overdue, created )
	select c.external_link  
	,      c.id             
	,      creation_date    
	,      overdue_days     
	,      overdue          
	,      CURRENT_TIMESTAMP created
	from       staging.credits_delays cd
	inner join credits                c  on cd.external_link = c.external_link
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






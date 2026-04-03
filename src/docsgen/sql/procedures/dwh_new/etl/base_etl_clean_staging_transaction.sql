-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 27-02-2019
-- Description:	airflow etl clean_staging_transaction
--
-- exec etl.base_etl_clean_staging_transaction 


-- =============================================
CREATE PROCEDURE [etl].[base_etl_clean_staging_transaction]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	--log
	declare @params nvarchar(1024)=''

	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params

	
  

/** etl from airflow*/
begin try
;
with cte as (
        select * , row_number() over( partition by external_id, creation_date, verifier ,
         status  order by creation_date) rn from staging.requests_history
)
delete  from cte
 where rn >1
;
with cte as (
        select * , row_number() over( partition by external_id, creation_date, verifier , status  order by creation_date) rn 
        from staging.credits_history
)
delete   from cte 
where rn >1
;
with cte as (
        select * , row_number() over( partition by external_link, creation_date, overdue_days   order by creation_date) rn 
        from staging.credits_delays
)
delete from cte
where rn >1

declare @result nvarchar(100)
   set @result=N' ROWCOUNT='		 +format(@@ROWCOUNT,'0')
exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
;
/** etl from airflow*/
end try
begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

    exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Error','Error',@error_description
	;throw 51000, @error_description, 1
end catch

--log result
   

END

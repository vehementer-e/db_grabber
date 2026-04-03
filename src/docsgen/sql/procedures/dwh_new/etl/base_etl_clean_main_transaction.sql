-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl clean_main_transaction
--
--  exec etl.base_etl_clean_main_transaction
-- =============================================
CREATE procedure [etl].[base_etl_clean_main_transaction]

as
begin

	SET NOCOUNT ON;
	--log

	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      ''
	begin try

    /*
    SELECT * into   DWH_NEW_dev.DBO.credits_delays FROM DWH_NEW.DBO.credits_delays
    */
	;
	with cte
	as
	(
		select *                                                                                          
		,      row_number() over( partition by request_id, stage_time, verifier , status order by created) rn
		from requests_history
	)
	delete from cte
	where rn >1
	;

	with cte
	as
	(
		select *                                                                                         
		,      row_number() over( partition by credit_id, stage_time, verifier , status order by created) rn
		from credits_history
	)
	delete from cte
	where rn >1
	;

	with cte
	as
	(
		select *                                                                                       
		,      row_number() over( partition by credit_id, creation_date, overdue_days order by created) rn
		from credits_delays
	)
	delete from cte
	where rn >1
	;





	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'

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






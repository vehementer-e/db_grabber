-- exec [etl].[base_etl] '20191130','20200304'
CREATE procedure [etl].[base_etl] @start_date datetime
,                                @end_date datetime
AS
BEGIN

	SET NOCOUNT ON;
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024)
	set @params= N' start_date='+cast(FORMAT (@start_date, 'dd.MM.yyyy HH:mm:ss ')
	as nvarchar(32))+'<br />'
	+N' end_date='+cast(FORMAT (@end_date, 'dd.MM.yyyy HH:mm:ss ')
	as nvarchar(32))
	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      @params

	begin try
	exec dwh_new.[etl].[base_etl_1c_persons_into_staging] @start_date
	,                                                     @end_date
	exec dwh_new.[etl].[base_etl_1c_collaterals_into_staging] @start_date
	,                                                         @end_date
	exec dwh_new.[etl].[base_etl_1c_requests_into_staging] @start_date
	,                                                      @end_date
	exec dwh_new.[etl].[base_etl_1c_credits_into_staging] @start_date
	,                                                     @end_date
	exec dwh_new.[etl].[base_etl_1c_rh_into_staging] @start_date
	,                                                @end_date
	exec dwh_new.[etl].[base_etl_1c_ch_into_staging] @start_date
	,                                                @end_date
	exec dwh_new.[etl].[base_etl_1c_cd_into_staging] @start_date
	,                                                @end_date
	exec dwh_new. [etl].[base_etl_1c_addresses_into_staging] @start_date
	,                                                        @end_date
	exec dwh_new.[etl].[base_etl_1c_leads_into_staging]
	exec dwh_new.[etl].[base_etl_1c_crm_req_into_staging]


	exec dwh_new.[etl].[base_etl_clean_staging_transaction]


	exec etl.base_etl_check_dicts_for_requests_history
	exec etl.base_etl_check_dicts_for_requests
	exec etl.base_etl_check_dicts_for_persons
	exec etl.base_etl_check_dicts_for_crm_requests



	exec etl.base_etl_process_persons @start_date
	,                                 @end_date


	exec etl.base_etl_process_collaterals @start_date
	,                                     @end_date
	exec etl.base_etl_process_requests @start_date
	,                                  @end_date

	exec etl.base_etl_process_credits @start_date
	,                                 @end_date
	exec etl.base_etl_load_credit_percents

	exec etl.base_etl_process_credits_history_sql @start_date
	,                                             @end_date
	exec etl.base_etl_process_requests_history_sql @start_date
	,                                              @end_date

	exec etl.base_etl_process_credits_delays_sql @start_date
	,                                            @end_date

	exec etl.base_etl_clean_main_transaction
	exec etl.base_etl_update_pos
	exec [etl].[base_etl_process_tmp_v_requests_sql]
	exec [etl].[base_etl_process_repeated_algo]

	exec etl.base_etl_process_visualization

	exec etl.base_etl_credit_portfolio
	exec etl.base_etl_insert_balance




	declare @tsql    nvarchar(4000)
	,       @subject nvarchar(1024)
	,       @body    nvarchar(1024)
	declare @recipients nvarchar(1024)=N'Yashina_E_B@carmoney.ru;dwh112@carmoney.ru;Servicedesk@carmoney.ru;E.Miroshnik@carmoney.ru'

	set @subject='Risk DWH ETL process finished.'
	set @body='<br>'+cast( FORMAT (getdate(), 'dd.MM.yyyy HH:mm:ss ') as nvarchar(22))+' '+@subject

	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
	,                            @recipients   = @recipients
	,                            @body         = @body
	,                            @body_format  = 'HTML'
	,                            @subject      = @subject


	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	,                                      'Risk DWH ETL process finished.'
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
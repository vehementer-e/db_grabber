-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[reTryRunProcessContractUpdate] @processGUID = <value>;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROC [etl].[reTryRunProcessContractUpdate]
	@processGUID nvarchar(36)
as
begin
	begin try
		declare @StatusCode nvarchar(255) = 'New'
		,@processType nvarchar(255)
		select @processType = ProcessType  from  etl.ReloadData4Contract where ProcessGUID = @processGUID
		if nullif(@processType,'') is not null
		begin
			if (cast(GETDATE()  as time) between '10:00' and '23:00'
				and @processType in ('contractFullRepayment'))
				or (cast(GETDATE()  as time) between '7:00' and '23:00' 
					and @processType in ('contractIssuance')
				)

				OR (@processType in ('ReloadData4StrategyDatamartByContract', 'contractMove2Archive')
				)
			begin
				declare @execution_id int 
				declare  @Sql nvarchar(max) = 'USE SSISDB
				--EXECUTE AS LOGIN =''carm\sqlservice''
				 EXECUTE AS LOGIN=''CARM\adm_antoshchuk''
				
				EXEC [SSISDB].[catalog].[create_execution] 
					@package_name=N''EtlContractContractUpdate.dtsx''
					, @execution_id=@execution_id OUTPUT
					, @folder_name=N''ETL''
					, @project_name=N''DWH_ETL''
					, @use32bitruntime=False
					, @reference_id=NULL
					, @runinscaleout=False
		
				DECLARE @reloadProcessGUID sql_variant = @processGUID
				EXEC [SSISDB].[catalog].[set_execution_parameter_value] 
					@execution_id
					, @object_type=30
					, @parameter_name=N''reloadProcessGUID''
					, @parameter_value=@reloadProcessGUID
		
				DECLARE @var4 smallint = 1
				EXEC [SSISDB].[catalog].[set_execution_parameter_value] 
					@execution_id
					,  @object_type=50
					, @parameter_name=N''LOGGING_LEVEL''
					, @parameter_value=@var4

				EXEC [SSISDB].[catalog].[start_execution] @execution_id'

				declare  @ParmDefinition nvarchar(max)= '@execution_id bigint OUT, 
					@processGUID nvarchar(36)'
				EXECUTE sp_executesql @Sql, @ParmDefinition, 
					@execution_id = @execution_id OUT,
					@processGUID = @processGUID
			
				DECLARE @status int, @isError int

				update etl.ReloadData4Contract
					set SSISId = @execution_id
						,reTryCount = isnull(reTryCount,0) + 1
						,StatusDesc =  null
						,StatusCode = @StatusCode
				where ProcessGUID = @processGUID 
			end
		end
	end try
	begin catch
		if @@TRANCOUNT>0
		rollback tran
	;throw
	end catch
end

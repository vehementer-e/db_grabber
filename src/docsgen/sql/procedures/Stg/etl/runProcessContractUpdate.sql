/*

select  [dbo].[getGUIDFrom1C_IDRREF](д.Ссылка) from 
inner join _1cCMR.Справочник_Договоры д 
	on д.Код = sd.external_id
where end_date is null
and is_active =0
*/




/*

	declare 
		@contractGuid nvarchar(36) = 'CF653A98-D8C2-11EF-B81B-B1D282F786D6'
		,@clientGuid nvarchar(36)
		,@DateRepayment date = getdate()
		,@ProcessGUID nvarchar(36)
		,@processType  nvarchar(255) = 'contractMove2Archive'
	exec etl.runProcessContractUpdate
		@contractGuid = @contractGuid
		,@clientGuid = @clientGuid
		,@DateRepayment = @DateRepayment
		,@processType  = @processType
		,@ProcessGUID = @ProcessGUID out
select @ProcessGUID
select * from etl.ReloadData4Contract

--where ProcessGUID ='D86BA415-D1DE-4F09-A306-C4FB94D4C09E'
order by createdAt desc
*/
CREATE PROC [etl].[runProcessContractUpdate]
(
	@contractGuid nvarchar(36) --guid договора
	,@clientGuid nvarchar(36) = null--guid клиента
	,@dateRepayment date = null
	,@processType nvarchar(255) =  'contractUpdate'
	,@processGUID nvarchar(36) = null out
)
 WITH EXECUTE AS OWNER
as
begin 
	
begin try
	declare @StatusCode nvarchar(255) = 'New'
	,@error_msg nvarchar(255)
	,@external_id nvarchar(16) 
	,@batchSize  smallint =100
	if @processType not in ('contractUpdate', 'contractFullRepayment', 'contractIssuance',
		'ReloadData4StrategyDatamartByContract'
		,'contractMove2Archive')
	begin
		set @error_msg  =concat_ws(' ', 'Значение processType должен быть:'
			,concat_ws(' или '
			, 'contractUpdate'
			, 'contractFullRepayment'
			, 'contractIssuance'
			, 'contractMove2Archive'
			, 'ReloadData4StrategyDatamartByContract')
			)
		;throw 51000, @error_msg, 16
	end

		
	select @external_id = Код, @clientGuid = isnull(nullif(@clientGuid,''), dbo.getGUIDFrom1C_IDRREF(Клиент) )
		from _1cCMR.Справочник_Договоры д
	--where dbo.getGUIDFrom1C_IDRREF(д.Ссылка) =@contractGuid
	where д.Ссылка = Stg.dbo.get1CIDRREF_FromGUID(@contractGuid)
		
	if nullif(trim(@external_id),'') is null
	begin
		set @error_msg  =concat('Не найден договор с указанным guid: ', @contractGuid)
		;throw 51000, @error_msg, 16
	end

	if not exists(
		select top(1) 1 from _1cCMR.Справочник_Клиенты 
		--where dbo.getGUIDFrom1C_IDRREF(Ссылка) = @clientGuid
		where Ссылка = Stg.dbo.get1CIDRREF_FromGUID(@clientGuid)
		)
	begin
		set @error_msg  =concat('Не найден клиент с указанным guid: ', @clientGuid)
		;throw 51000, @error_msg, 16
	end
	
	if exists(select top(1) 1
	from  etl.ReloadData4Contract t
	where t.external_id = @external_id
		and cast(t.CreatedAt as date) = cast(getdate() as date)
		and t.ProcessType = @processType
		and @processType not in ('contractUpdate')
	)
	begin
		declare @msg nvarchar(255) =  FORMATMESSAGE('Договор уже был ранее добавлен в обработку сегодня. Номер = %s, код = %s', @external_id, @contractGuid)
		;throw 51000, @msg, 1
	end
	select @DateRepayment = isnull(@DateRepayment, getdate())
	declare @Result table([ProcessGUID] uniqueidentifier)
	
	begin tran
		if  @ProcessType in('ReloadData4StrategyDatamartByContract', 'contractIssuance', 'contractUpdate', 'contractMove2Archive')
		begin
			select top(1)
				@ProcessGUID = t.ProcessGUID
				--,count(1)
				from etl.ReloadData4Contract t
				where t.ProcessType = @ProcessType 
				and cast(CreatedAt as date) = cast(getdate() as date)
				and StatusCode = 'New'
				group by ProcessGUID, ProcessType
				having count(1)<@batchSize
				set @ProcessGUID = isnull(@ProcessGUID, newid())
		end	


		merge etl.ReloadData4Contract t
		using (select 
				[ProcessType], 
				[ContractGuid], 
				[external_id], 
				[ClientGuid], 
				[DateRepayment],
				[StatusCode],
				reTryCount,
				ProcessGUID
			from (values
			(	@ProcessType
				,@contractGuid
				,@external_id
				,@clientGuid
				,@DateRepayment
				,@StatusCode
				,0
				,@ProcessGUID
				)
				)
			t([ProcessType]
				, [ContractGuid]
				, [external_id]
				, [ClientGuid]
				, [DateRepayment]
				, [StatusCode]
				, reTryCount
				, ProcessGUID)
		) s on  t.[ProcessType] = s.[ProcessType]
			and t.[ContractGuid] = s.[ContractGuid]
			and t.[StatusCode] = s.[StatusCode]
			and (t.ProcessGUID = s.ProcessGUID  or s.ProcessGUID is null)
			and cast(t.CreatedAt as date) =cast(getdate() as date)
		when not matched then insert 
		(
			 [ProcessType] 
			,[ContractGuid]
			,[external_id] 
			,[ClientGuid] 
			,[DateRepayment]
			,[StatusCode]
			,reTryCount
			,ProcessGUID
		)values
		(
			 s.[ProcessType]
			,s.[ContractGuid]
			,s.[external_id] 
			,s.[ClientGuid] 
			,s.[DateRepayment]
			,s.[StatusCode]
			,s.reTryCount
			,isnull(ProcessGUID, newid())
		)when matched then update
			set [CreatedAt] = getdate()
				,[DateRepayment]  =s.[DateRepayment]
				,SSISId = null
		OUTPUT inserted.[ProcessGUID]  INTO @Result
		;
		select @ProcessGUID = (select top(1)  ProcessGUID from @Result)
	commit tran
	
	if @processGUID is not null
		
	begin
		if (cast(GETDATE()  as time) between '10:00' and '23:00'
			and @processType in ('contractFullRepayment'))
		or (cast(GETDATE()  as time) between '07:00' and '23:00'
			and @processType in ('contractIssuance')
			)
		begin
			declare @execution_id int 
			declare  @Sql nvarchar(max) = 'USE SSISDB
			EXECUTE AS LOGIN =''carm\sqlservice''

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
			where ProcessGUID = @processGUID 
		end
	end
	else
	begin
		;throw 51000, 'Индентификатор процесса не определен', 16
	end

	
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end

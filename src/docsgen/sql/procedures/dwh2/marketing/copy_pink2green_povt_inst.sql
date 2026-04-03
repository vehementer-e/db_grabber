--exec [marketing].[copy_pink2green_povt_inst] @CMRClientGUIDs = '282887f5-9ed5-47a5-86d9-4edeb30c8a4f'
CREATE   procedure [marketing].[copy_pink2green_povt_inst]
	@CMRClientGUID  nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null

as
begin
	declare @error_msg nvarchar(255)
	set @CMRClientGUIDs = CONCAT_WS(',', @CMRClientGUID, @CMRClientGUIDs)
	begin try
		if @CMRClientGUIDs is null
		begin
			set @error_msg = 'значение @CMRClientGUIDs не определено'
			;throw 51000, @error_msg, 16
		end

		declare cur_CMRClientGUID cursor  for 
			select trim(value) from string_split(@CMRClientGUIDs, ',')


		OPEN cur_CMRClientGUID  
		FETCH NEXT FROM cur_CMRClientGUID INTO @CMRClientGUID  
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			
			if exists(select top(1) 1 from  [risk].[povt_inst_buffer]
				where CMRClientGUID = @CMRClientGUID
					and category in ('Розовый')
			)
			begin
				select @CMRClientGUID
				exec [marketing].[fill_povt_inst] @CMRClientGUID =  @CMRClientGUID

				update t
					set days_after_close = 0
				from marketing.povt_inst t
				where t.cdate = cast(getdate() as date)
					and t.CMRClientGUID = @CMRClientGUID
			end
			else begin
				
				set @error_msg = Concat('У клиента GUID:', @CMRClientGUID, 
					' нет доступного маретингового предложения в категории Розовый')
				;throw 51000, @error_msg, 16
			end
	
		FETCH NEXT FROM cur_CMRClientGUID INTO @CMRClientGUID  
		END  
  
		CLOSE cur_CMRClientGUID  
		DEALLOCATE cur_CMRClientGUID  

	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end
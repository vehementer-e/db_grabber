

CREATE    procedure [marketing].[fill_povt_inst_uat]
	@env nvarchar(255) = 'uat',
	@CMRClientGUID nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null
as
begin
	begin try
		if not exists(select top(1) 1 from [marketing].[povt_inst])
		begin 
			;throw 51000, 'Отсутвутют данные в marketing.povt_inst', 16
		end
		

		/*
		if @env = 'uat'
		begin
			delete t from #t_povt_inst t
			where not exists(Select top(1) 1 from stg.[_1cCRM].Документ_ЗаявкаНаЗаймПодПТС_uat uat
					where [dbo].[getGUIDFrom1C_IDRREF](uat.Партнер)  = t.[CMRClientGUID]
					)
		
		end
		*/

	set @CMRClientGUIDs = nullif(CONCAT_WS(','	,@CMRClientGUID, @CMRClientGUIDs), '')
	
	

	begin tran
		truncate table [marketing].[povt_inst_uat]
	
		insert into [marketing].[povt_inst_uat]
		(
			[external_id], 
			[CMRClientGUID], 
			[last_name], 
			[first_name], 
			[patronymic], 
			[birth_date], 
			[passport_series], 
			[passport_number], 
			[market_proposal_category_code], 
			[market_proposal_type_name], 
			[market_proposal_type_code], 
			[phone], 
			[passportNotValid], 
			[cdate], 
			[approved_limit], 
			[lkUserId], 
			[phoneInBlackList], 
			[FIO], 
			[clientTimeZone], 
			[naumenResultCode], 
			[naumenCaseUUID], 
			[naumenPriority], 
			[naumenResultDesc], 
			[market_proposal_category_name], 
			[market_proposal_category_id], 
			[market_proposal_type_id], 
			[naumenLoadDate], 
			[lastNaumen_AttemptDate], 
			[lastNaumen_AttemptResult], 
			[lastNaumen_IsPhoned], 
			[lastCRMЗаявка_Guid], 
			[lastCRMЗаявка_Номер], 
			[lastCRMЗаявка_Дата], 
			[lastCRMЗаявка_СтатусНаименование], 
			[lastCRMЗаявка_ПричиныОтказовНаименование], 
			[lastЗаявкаНаЗаймПодПТС_Guid], 
			[lastЗаявкаНаЗаймПодПТС_Номер], 
			[lastЗаявкаНаЗаймПодПТС_Дата], 
			[lastЗаявкаНаЗаймПодПТС_Лид], 
			[lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование], 
			[lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод], 
			[client_email], 
			[date2SendPush], 
			[interactionTypeCode], 
			[has_pts_market_proposal], 
			[days_after_close], 
			[factenddate],
			marketProposal_ID,		
			[product_type_id],		
			[product_type_name],
			[product_type_code],
			lead_Id
		)
		select 
			[external_id], 
			[CMRClientGUID], 
			[last_name], 
			[first_name], 
			[patronymic], 
			[birth_date], 
			[passport_series], 
			[passport_number], 
			[market_proposal_category_code], 
			[market_proposal_type_name], 
			[market_proposal_type_code], 
			[phone], 
			[passportNotValid], 
			[cdate], 
			[approved_limit], 
			[lkUserId], 
			[phoneInBlackList], 
			[FIO], 
			[clientTimeZone], 
			[naumenResultCode], 
			[naumenCaseUUID], 
			[naumenPriority], 
			[naumenResultDesc], 
			[market_proposal_category_name], 
			[market_proposal_category_id], 
			[market_proposal_type_id], 
			[naumenLoadDate], 
			[lastNaumen_AttemptDate], 
			[lastNaumen_AttemptResult], 
			[lastNaumen_IsPhoned], 
			[lastCRMЗаявка_Guid], 
			[lastCRMЗаявка_Номер], 
			[lastCRMЗаявка_Дата], 
			[lastCRMЗаявка_СтатусНаименование], 
			[lastCRMЗаявка_ПричиныОтказовНаименование], 
			[lastЗаявкаНаЗаймПодПТС_Guid], 
			[lastЗаявкаНаЗаймПодПТС_Номер], 
			[lastЗаявкаНаЗаймПодПТС_Дата], 
			[lastЗаявкаНаЗаймПодПТС_Лид], 
			[lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование], 
			[lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод], 
			[client_email], 
			[date2SendPush], 
			[interactionTypeCode], 
			[has_pts_market_proposal], 
			[days_after_close], 
			[factenddate],
			marketProposal_ID,		
			[product_type_id],		
			[product_type_name],
			[product_type_code],
			lead_Id
		 from [marketing].[povt_inst] povt_inst
			where cdate = cast(getdate() as date)
			and exists(select top(1) 1 from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС_uat
			uat where uat.Номер =povt_inst.external_id
			)
			and (
				(CMRClientGUID in (select trim(value) from string_split(@CMRClientGUIDs, ',')))
			or @CMRClientGUIDs is null)
	commit tran
	

	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end

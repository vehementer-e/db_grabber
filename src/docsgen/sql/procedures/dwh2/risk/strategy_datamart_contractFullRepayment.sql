--Обновление strategy_datamart_hourly убираем активность по договору в 0 т.к договор погасился. в рамкках BP-3258
CREATE   procedure [risk].[strategy_datamart_contractFullRepayment]
	@contractGuid nvarchar(36) = null,
	@contractGuids nvarchar(max) = null  --guids договоров
as
begin
	set @contractGuids = nullif(CONCAT_WS(',', @contractGuid, @contractGuids), '')
	
begin try
	
	if @contractGuids is not null
	begin
		begin tran
			update  risk.strategy_datamart_hourly
				set is_active =0 
					,end_date = getdate()
					,total_rest = 0
					,total_rest_client = total_rest_client - total_rest
					,overdue_days = 0
			where external_id 
			in (Select Код from stg._1cCMR.Справочник_Договоры
			where Ссылка in (
					select [dbo].[get1CIDRREF_FromGUID](trim(value)) from string_split(@contractGuids, ',')
					)
					)
		commit tran
	end
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch
end

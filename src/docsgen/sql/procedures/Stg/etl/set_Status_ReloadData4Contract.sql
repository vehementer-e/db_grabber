-- Usage: запуск процедуры с параметрами
-- EXEC etl.set_Status_ReloadData4Contract @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create procedure etl.set_Status_ReloadData4Contract
	@StatusCode nvarchar(255)
	,@StatusDesc nvarchar(255) = null
as
begin
	begin try
		begin tran
			update etl.ReloadData4Contract
				set StatusCode = @StatusCode
					,StatusDesc = @StatusDesc
					,UpdatedAt = getdate()
			where [ContractGuid] in (select replace(value,'''', '') from string_split([etl].[GetContractList2Load](), ','))
			and StatusCode not in ('New', 'Finished')
			and CreatedAt > ='2024-10-26'
		commit tran
	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end

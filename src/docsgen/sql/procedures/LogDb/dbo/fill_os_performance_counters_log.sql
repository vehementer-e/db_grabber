CREATE   PROC dbo.fill_os_performance_counters_log
	@depth int = 7 --cleaning depth in days
as
begin
	--truncate table sat.Клиент_ПаспортныеДанные
begin TRY
	SELECT @depth = isnull(@depth, 7)

	DELETE L
	FROM LogDb.dbo.os_performance_counters_log AS L
	WHERE L.created_at < cast(dateadd(DAY, -@depth, getdate()) AS date)

	INSERT LogDb.dbo.os_performance_counters_log
	(	
		created_at,
		[object_name],
		[counter_name],
		[instance_name],
		[cntr_value],
		[cntr_type]
	)
	SELECT
		created_at = getdate(),
		D.[object_name],
		D.[counter_name],
		D.[instance_name],
		D.[cntr_value],
		D.[cntr_type]
	FROM sys.dm_os_performance_counters AS D
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

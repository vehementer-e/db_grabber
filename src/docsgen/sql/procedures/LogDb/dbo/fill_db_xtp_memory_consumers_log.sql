CREATE   PROC dbo.fill_db_xtp_memory_consumers_log
	@depth int = 7 --cleaning depth in days
as
begin
	--truncate table sat.Клиент_ПаспортныеДанные
begin TRY
	SELECT @depth = isnull(@depth, 7)

	DELETE L
	FROM LogDb.dbo.db_xtp_memory_consumers_log AS L
	WHERE L.created_at < cast(dateadd(DAY, -@depth, getdate()) AS date)

	INSERT LogDb.dbo.db_xtp_memory_consumers_log
	(	
		created_at,
		dbname,
		--
		[memory_consumer_id],
		[memory_consumer_type],
		[memory_consumer_type_desc],
		[memory_consumer_desc],
		[object_id],
		[xtp_object_id],
		[index_id],
		[allocated_bytes],
		[used_bytes],
		[allocation_count],
		[partition_count],
		[sizeclass_count],
		[min_sizeclass],
		[max_sizeclass],
		[memory_consumer_address]
	)
	SELECT
		created_at = getdate(),
		dbname = 'tempdb',
		--
		D.[memory_consumer_id],
		D.[memory_consumer_type],
		D.[memory_consumer_type_desc],
		D.[memory_consumer_desc],
		D.[object_id],
		D.[xtp_object_id],
		D.[index_id],
		D.[allocated_bytes],
		D.[used_bytes],
		D.[allocation_count],
		D.[partition_count],
		D.[sizeclass_count],
		D.[min_sizeclass],
		D.[max_sizeclass],
		D.[memory_consumer_address]
	FROM tempdb.sys.dm_db_xtp_memory_consumers AS D
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

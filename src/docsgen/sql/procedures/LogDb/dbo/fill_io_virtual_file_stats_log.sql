CREATE   PROC dbo.fill_io_virtual_file_stats_log
	@depth int = 7 --cleaning depth in days
as
begin
begin TRY
	SELECT @depth = isnull(@depth, 7)

	DELETE L
	FROM LogDb.dbo.io_virtual_file_stats_log AS L
	WHERE L.created_at < cast(dateadd(DAY, -@depth, getdate()) AS date)

	INSERT LogDb.dbo.io_virtual_file_stats_log
	(
	    created_at,
	    [Database Name],
	    physical_name,
	    Volume,
	    sample_ms,
	    num_of_reads,
	    num_of_bytes_read,
	    io_stall_read_ms,
	    io_stall_queued_read_ms,
	    num_of_writes,
	    num_of_bytes_written,
	    io_stall_write_ms,
	    io_stall_queued_write_ms,
	    io_stall,
	    size_on_disk_bytes
	)
	SELECT
		created_at = getdate(),
		--
		[Database Name] = DB_NAME(vfs.database_id)
		,physical_name= mf.physical_name
		,Volume = LEFT (mf.physical_name, 2)
		,vfs.sample_ms	
		,vfs.num_of_reads	
		,vfs.num_of_bytes_read	
		,vfs.io_stall_read_ms	
		,vfs.io_stall_queued_read_ms	
		,vfs.num_of_writes	
		,vfs.num_of_bytes_written	
		,vfs.io_stall_write_ms	
		,vfs.io_stall_queued_write_ms	
		,vfs.io_stall	
		,vfs.size_on_disk_bytes
	FROM sys.dm_io_virtual_file_stats(null, null)vfs
		JOIN sys.master_files AS mf ON vfs.database_id = mf.database_id 
			AND vfs.file_id = mf.file_id 
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

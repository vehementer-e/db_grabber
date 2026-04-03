
--checked 12.03.2020
--exec [_LCRM].[leadsRMQClear]
-- Usage: запуск процедуры с параметрами
-- EXEC [RMQ].[Clear_LCRM_LeadRows] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE    procedure [RMQ].[Clear_LCRM_LeadRows]
	@bathSize int = 5000
as

begin
set nocount on 

	declare @dt  date = dateadd(dd, -1, cast(getdate() as date))
--select count(1) FROM RMQ.ReceivedMessages_LCRM_LeadRows   with(nolock)
--	WHERE isDeleted = 1
--		and [TypeRecord] =3
--		and ReceiveDate<@dt
	declare @PARTITIONId int = $PARTITION.[pfn_range_right_ThreadId_part_ReceivedMessages_LCRM_LeadRows](-1)
	select @PARTITIONId
	--TRUNCATE TABLE RMQ.ReceivedMessages_LCRM_LeadRows_byThread
	--	WITH (PARTITIONS (@PARTITIONId));


	DELETE top (@bathSize)
		FROM RMQ.ReceivedMessages_LCRM_LeadRows_byThread   with(readpast)
	WHERE ReceiveDate<@dt
		and $PARTITION.[pfn_range_right_ThreadId_part_ReceivedMessages_LCRM_LeadRows]([ThreadId]) 
				=  @PARTITIONId
	OPTION( Recompile, QUERYTRACEON 610)
	declare @updatedRows  int = @@ROWCOUNT
	print concat('updated rows ', @updatedRows)
	WAITFOR DELAY '00:00:01'; 

	
	--DELETE top (@bathSize)
	--	FROM RMQ.ReceivedMessages_LCRM_LeadRows_byThread   with(readpast)
	--WHERE ThreadId<cast(0 as smallint)
	--	and ReceiveDate<@dt
	--OPTION(QUERYTRACEON 610)
		
	--UPDATE STATISTICS [RMQ].[ReceivedMessages_LCRM_LeadRows_byThread] 
	--	--WITH RESAMPLE ON PARTITIONS(1)

	/*
	
	if @updatedRows>0
	begin
		
		declare @lastStatistics datetime 
		SELECT @lastStatistics = max(last_updated)
		FROM [sys].[dm_db_stats_properties_internal](OBJECT_ID('rmq.ReceivedMessages_LCRM_LeadRows_byThread'),1)
		--select @lastStatistics
		--if  datediff(MINUTE, @lastStatistics, getdate()) >30
		begin
		SET LOCK_TIMEOUT 100
			--UPDATE STATISTICS [RMQ].[ReceivedMessages_LCRM_LeadRows_byThread] 
			declare @cmd nvarchar(1024) 
			= concat('UPDATE STATISTICS [RMQ].[ReceivedMessages_LCRM_LeadRows_byThread]  (cix)   
				WITH RESAMPLE ON PARTITIONS(', @PARTITIONId, ')')
				exec (@Cmd)

			set @cmd = concat('UPDATE STATISTICS [RMQ].[ReceivedMessages_LCRM_LeadRows_byThread]  (ix_ReceiveDate)   
				WITH RESAMPLE ON PARTITIONS(', @PARTITIONId, ')')
				exec (@Cmd)
			set @cmd = concat('UPDATE STATISTICS [RMQ].[ReceivedMessages_LCRM_LeadRows_byThread]  (ix_UpdatedAt)   
				WITH RESAMPLE ON PARTITIONS(', @PARTITIONId, ')')
				exec (@Cmd)

		end
	end 
	*/
end



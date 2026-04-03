-- ============================================= 
-- Author: А. Никитин
-- Create date: 15.08.2023
-- Description: DWH-2161 Загрузка отсутствующих записей в lcrm_leads_full_calculated
-- ============================================= 
-- Usage: запуск процедуры с параметрами
-- EXEC _LCRM.update_lcrm_leads_full_calculated
--      @isDebug = 0,
--      @ProcessGUID = NULL,
--      @SendEmail = 1;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC _LCRM.update_lcrm_leads_full_calculated
	@isDebug int = 0,
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@SendEmail int = 1
AS
BEGIN
SET NOCOUNT ON;
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @eventMessageText nvarchar(max) -- большое сообщение для расширенного логирования
	DECLARE @table_name_1 varchar(256) = '_LCRM.lcrm_leads_full_calculated' 
	DECLARE @count_ID int, @PartitionId int

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)
	SELECT @eventName = 'update_lcrm_leads_full_calculated'

	SELECT @count_ID = count(*)
	FROM LogDb.dbo.DQ_lcrm_leads_full_calculated_ID

	IF @count_ID > 0
	BEGIN
		DROP table if exists #t_DQ_lcrm_leads_full_calculated_ID
		CREATE TABLE #t_DQ_lcrm_leads_full_calculated_ID(ID numeric(10,0))

		DECLARE Cur_Partition CURSOR FOR
		SELECT DISTINCT 
			PartitionId = $PARTITION.pfn_range_right_date_part_lcrm_leads_full(I.UF_REGISTERED_AT)
		FROM LogDb.dbo.DQ_lcrm_leads_full_calculated_ID AS I
		ORDER BY PartitionId

		OPEN Cur_Partition
		FETCH NEXT FROM Cur_Partition INTO @PartitionId
		WHILE @@FETCH_STATUS = 0
		BEGIN
			TRUNCATE TABLE #t_DQ_lcrm_leads_full_calculated_ID

			INSERT #t_DQ_lcrm_leads_full_calculated_ID(ID)
			SELECT I.ID
			FROM LogDb.dbo.DQ_lcrm_leads_full_calculated_ID AS I
			WHERE $PARTITION.pfn_range_right_date_part_lcrm_leads_full(I.UF_REGISTERED_AT) = @PartitionId

			EXEC _LCRM.LCRM_LEADS_FULL_Channel_by_ids
				@Debug = @isDebug ,
				@ID_List_table_name = '#t_DQ_lcrm_leads_full_calculated_ID',
				@PartitionId = @PartitionId

			FETCH NEXT FROM Cur_Partition INTO @PartitionId
		end

		CLOSE Cur_Partition
		DEALLOCATE Cur_Partition


		SELECT @eventType = 'info'
		SELECT @message = concat(
			'В таблицу  ', @table_name_1, 
			' загружено ', cast(@count_ID AS varchar(10)),
			' отсутствующих записей.'
			)

		SELECT @description = 
			(SELECT
				'TableName1' = @table_name_1,
				'Message1' = 'Загружено записей: ' + convert(varchar(10), @count_ID)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = @eventType,
			@message = @message,
			@description = @description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID,
			@eventMessageText = @eventMessageText,
			@loggerName = 'admin_test'
			--@loggerName = 'admin_lcrm_2'
	END
END

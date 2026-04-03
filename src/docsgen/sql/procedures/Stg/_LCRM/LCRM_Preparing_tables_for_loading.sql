-- =======================================================
-- Created: 1.04.2022. А.Никитин
-- Description:	DWH-1475 Переписать шаги job ETL. LCRM CSV FULL at 03 30
-- Подготовка таблицы для загрузки.
-- =======================================================
-- Usage: запуск процедуры с параметрами
-- EXEC [_LCRM].[LCRM_Preparing_tables_for_loading] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROC [_LCRM].[LCRM_Preparing_tables_for_loading]
	@reLoadFullData bit = 0
AS
BEGIN
	SET XACT_ABORT ON
	SET NOCOUNT ON
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	DECLARE @partition_number int
begin try
	EXEC  [_LCRM].[LCRMLeads_logging] 0,'LCRM clear today leads csv table started', 'Start clear LCRM leads today csv storage table'

	--- переключаем таблицы. Делаем таблицу для сегодняшней загрузки. Но перед этим архивируем для сравнения потом

	--2021_12_24 - добавим проверку, что предыдущая загрузка прошла успешно
	declare @cnt_today bigint = (select count_big (1) from _LCRM.[lcrm_leads_full_csv_today])
	
	
	if (@cnt_today >10)  --
	begin
			truncate table  [_lcrm].[lcrm_leads_full_csv_ago]

	-- перед выполнением проверяем наличие индексов
			if not Exists(select * from sysindexes where name = 'NCI_ID_UPDATED' and id = object_id('[_lcrm].[lcrm_leads_full_csv_today]'))
			begin 
				CREATE NONCLUSTERED INDEX [NCI_ID_UPDATED] ON [_LCRM].[lcrm_leads_full_csv_today]
				(
					[ID] ASC,
					[UF_UPDATED_AT] ASC
				)
				WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [leads]
				--ON [pschema_date_part_lcrm_leads_fg_leads]([UF_REGISTERED_AT])
			end

			if not Exists(select * from sysindexes where name = 'NCI_ID_UPDATED' and id = object_id('[_LCRM].[lcrm_leads_full_csv_ago]'))
			begin 
				CREATE NONCLUSTERED INDEX [NCI_ID_UPDATED] ON [_LCRM].[lcrm_leads_full_csv_ago]
				(
					[ID] ASC,
					[UF_UPDATED_AT] ASC
				)
				WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [leads]
				--ON [pschema_date_part_lcrm_leads_fg_leads]([UF_REGISTERED_AT])
			end

	--go
		
	end
	if @reLoadFullData = 0 and @cnt_today >10000
	begin
		alter table [_lcrm].[lcrm_leads_full_csv_today]
			switch to [_lcrm].[lcrm_leads_full_csv_ago]
				
	end 

	if Exists(select * from sysindexes where name = 'NCI_ID_UPDATED' and id = object_id('[_lcrm].[lcrm_leads_full_csv_today]'))
			begin 
				drop index if exists  [NCI_ID_UPDATED] ON [_LCRM].[lcrm_leads_full_csv_today]
				
			end
	-- конец проверки данных
	truncate table [_lcrm].[lcrm_leads_full_csv_today]



	--drop table if exists 

	--select top(0) * 
	--into [_lcrm].[lcrm_leads_full_csv_today] on [leads]
	--from [_lcrm].[lcrm_leads_full_csv_ago]

	exec  [_LCRM].[LCRMLeads_logging] 0,'LCRM clear today leads csv table finished', 'Finished clear LCRM leads today csv storage table'
end try
begin catch
	DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

	;throw 51000, @msg, 1
end catch
END

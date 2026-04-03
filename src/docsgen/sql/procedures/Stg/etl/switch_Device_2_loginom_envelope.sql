
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[switch_Device_2_loginom_envelope] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROCEDURE [etl].[switch_Device_2_loginom_envelope]
	@env nvarchar(100) = 'prod',
	@process_guid uniqueidentifier = NULL
AS
BEGIN
	declare @today date = cast(getdate() as date)
declare @msg nvarchar(255) 
declare @insertRows int =0
DECLARE @msg2 nvarchar(2048),
	@event_description nvarchar(2048), @error_description nvarchar(1024),
	@StartDate datetime = getdate(), @FinishDate datetime

SELECT @process_guid = isnull(@process_guid, newid())

begin try
	--new log start
	set @msg2 = concat('Заливка Device в loginom запущена. ',
		'Время запуска: ', format(@StartDate, 'dd.MM.yyyy HH:mm:ss'), '. '
		)

	SELECT @event_description = 
		(SELECT
			'StartDate' = format(@StartDate, 'dd.MM.yyyy HH:mm:ss')
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

	EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
		--@logger_name = N'risklog',
		@process_guid = @process_guid,
		@event_level = 'info',
		@event_type = 'switch_Device_2_loginom',
		@event_name = 'Заливка Device в loginom',
		@event_step_number = NULL,
		@event_step_type = NULL,
		@event_step_name = NULL,
		@event_status = 'running',
		@event_message = @msg2,
		@event_description = @event_description,
		--@event_message_text = N'большой текст',
		@SendEmail = 1,
		@SendSlack = 1

	if @env = 'prod'
	begin
		exec @insertRows = [LOGINOMDB].[LoginomDB].[dwh].switch_Device
	end
	else
	begin
		exec @insertRows = [C1D-VSR-LSQL.DEV.CARMONEY.RU].[LoginomDB].[dwh].switch_Device
	end
	if nullif(@insertRows,0)!=0
	begin
		-- new log finish
		SELECT @FinishDate = getdate()

		set @msg2 = concat('Заливка Device в loginom завершена. ',
			'Время запуска: ', format(@StartDate, 'dd.MM.yyyy HH:mm:ss'), '. ',
			'Время завершения: ', format(@FinishDate, 'dd.MM.yyyy HH:mm:ss'), '. ',
			'Добавлено: ', isnull(@insertRows, 0)
			)

		SELECT @event_description = 
			(SELECT
				'StartDate' = format(@StartDate, 'dd.MM.yyyy HH:mm:ss'),
				'FinishDate' = format(@FinishDate, 'dd.MM.yyyy HH:mm:ss'),
				'InsertRows' = isnull(@insertRows, 0)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			--@logger_name = N'risklog',
			@process_guid = @process_guid,
			@event_level = 'info',
			@event_type = 'switch_Device_2_loginom',
			@event_name = 'Заливка Device в loginom',
			@event_step_number = NULL,
			@event_step_type = NULL,
			@event_step_name = NULL,
			@event_status = 'succeeded',
			@event_message = @msg2,
			@event_description = @event_description,
			--@event_message_text = N'большой текст',
			@SendEmail = 1,
			@SendSlack = 1

	end
	else begin
		set @msg = 'Данные в Device на сервере Loginom не были добавлены!'
		;throw 51000, @msg, 1
	end
	
end try
begin catch
	--declare @error_description nvarchar(1024)
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
           ROLLBACK TRAN;
	
	--set @msg=':exclamation: Ошибка загрузки данных Origination_StrategyDataMart на сервер Loginom. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
	--exec logDB.[dbo].[SendToSlack_DwhSmartNotifications] @msg

	-- new log
	SELECT @FinishDate = getdate()

	set @msg2 = concat(':exclamation: Ошибка загрузки данных Device на сервер Loginom. ',
		'Время запуска: ', format(@StartDate, 'dd.MM.yyyy HH:mm:ss'), '. ',
		'Время завершения: ', format(@FinishDate, 'dd.MM.yyyy HH:mm:ss'), '. ',
		'Добавлено: ', isnull(@insertRows, 0), '. ',
		isnull(@error_description, '')
		--,', Изменено: ', isnull(@UpdateRows, 0)
		)

	SELECT @event_description = 
		(SELECT
			'StartDate' = format(@StartDate, 'dd.MM.yyyy HH:mm:ss'),
			'FinishDate' = format(@FinishDate, 'dd.MM.yyyy HH:mm:ss'),
			'InsertRows' = isnull(@insertRows, 0)
			--,'UpdateRows' = isnull(@UpdateRows, 0)
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

	EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
		--@logger_name = N'risklog',
		@process_guid = @process_guid,
		@event_level = 'error',
		@event_type = 'switch_Device_2_loginom',
		@event_name = 'Заливка Device в loginom',
		@event_step_number = NULL,
		@event_step_type = NULL,
		@event_step_name = NULL,
		@event_status = 'failed',
		@event_message = @msg2,
		@event_description = @event_description,
		--@event_message_text = N'большой текст',
		@SendEmail = 1,
		@SendSlack = 1

    ;THROW 51000, @error_description, 1
end catch
END

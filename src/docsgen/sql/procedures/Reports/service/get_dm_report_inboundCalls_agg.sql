/****** Object:  StoredProcedure [service].[get_dm_report_inboundCalls_agg]    Script Date: 25.03.2026 ******/
-- =============================================
-- Author:      Konstantin Suslov
-- Create date: 25.03.2026
-- Description: Процедура для вывода всех полей таблицы service.dm_report_inboundCalls_agg
-- USAGE:       exec [service].[get_dm_report_inboundCalls_agg]
-- =============================================
CREATE   PROCEDURE [service].[get_dm_report_inboundCalls_agg]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
			[Дата]
			, [Проект]
			, [Id Проекта]	
			, [Группа проекта]
			, dialed_number
			, call_kind
			, [Набранный номер расшифровка]
			, [SL, %]                                        												
			, [Количество входящих звонков]                  
			, [Звонок завершен на IVR]
			, callbacks_count
			, [Количеcтво уникальных номеров клиентов]
			, [Количество уникальных клиентов]
			, [Вышли в очередь]                              
			, [Звонок переведен с IVR на оператора]          
			, [Количество принятых звонков]                  
			, [Количество повторных обращений]               
			, [Количество переводов]
			, transfer_cnt_internal
			, transfer_cnt_psb
			, [Количество звонков в нерабочее время]         
			, [Время ожидания]                               
			, [Доля потерянных звонков до 20 секунд ожидания]
			, [Доля потерянных звонков после 20 секунд ожидания]
			, [Количество звонков, принятых до 20 секунд ожидания]   
			, [Количество звонков, принятых после 20 секунд ожидания]
			, [FRT]                        
			, [Среднее время разговора]
			, [Количество успешных звонков bigInstallment]
			, [Количество открытых договоров bigInstallment на начало дня]
			, CASE
				WHEN [Количество открытых договоров bigInstallment на начало дня] = 0
					OR [Количество открытых договоров bigInstallment на начало дня] IS NULL
				THEN '-'
				ELSE CONVERT(varchar(32), CAST([Количество успешных звонков bigInstallment] * 100.0 / [Количество открытых договоров bigInstallment на начало дня] AS decimal(18, 2)))
			 END as [Доля активных выданных заявок Big Installment ПСБ] 
    FROM 
		service.dm_report_inboundCalls_agg;
END

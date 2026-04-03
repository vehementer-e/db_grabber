-- =============================================
-- Author:		Шубкин Александр
-- Description:	Процедура для вызова 3 функций подсчета метрик для отчета по клиентским метрикам Welcome.
-- EXEC [dbo].[get_call2ClientMetrics_NPS_CSI_CES] @startDate = '2024-11-01', @endDate = '2024-11-27', @callingType = 'Welcome!'
-- =============================================
create   PROCEDURE dbo.[get_call2ClientMetrics_NPS_CSI_CES]
	@startDate datetime
	, @endDate datetime
	, @callingType nvarchar(255)
AS
BEGIN
	SELECT
	
		 [dbo].[Get_ClientMetric_calculation_NPS] (@startDate, @endDate, @callingType) AS NPS
		, dbo.Get_ClientMetric_calculation_CSI (@startDate, @endDate, @callingType) as CSI
		, dbo.[Get_ClientMetric_calculation_CES] (@startDate, @endDate, @callingType) as CES
END

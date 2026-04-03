-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-05-26
-- Description:	DWH-2582 Реализовать отчет Подозрения FRAUD
-- =============================================
/*
EXEC dbo.Report_SuspicionFraud
*/
CREATE   PROC [collection].[Report_SuspicionFraud]
	--@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	--SELECT @isDebug = isnull(@isDebug, 0)

	SELECT 
		T.created_at,
		RN = row_number() OVER(ORDER BY T.НомерДоговора),
		T.GuidДоговора,
		T.НомерДоговора,
		T.СуммаУщерба,
		T.СуммаПросрочки,
		T.ТипПродукта,
		T.ДатаДоговора,
		T.ФИО,
		T.GuidКлиент,
		T.ДатаИсключенияСрокаДоговора,
		T.СтатусыСпейс
		,photoHasSuspiciousAtribute = iif(photoHasSuspiciousAtribute = 1, 'Да', 'Нет')
		,t.Широта
		,t.Долгота
	FROM collection.dm_SuspicionFraud AS T
	ORDER BY T.НомерДоговора

END TRY
BEGIN CATCH
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
END CATCH


END
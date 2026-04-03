-- =============================================  
-- Author:  А.Никитин
-- Create date: 1.03.2022  
-- Description: Формирование сообщений об ошибке
-- =============================================  
-- Usage: запуск процедуры с параметрами
-- EXEC dbo.CreateError @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE dbo.CreateError
	@sError nvarchar(max) = NULL
AS  
BEGIN
	DECLARE @ErrorMessage  nvarchar(4000), @ErrorSeverity int, @ErrorState int, @ErrorNumber int
	IF @sError IS NULL
	BEGIN
		DECLARE @c1310 varchar(2) = char(13)+char(10)
		SELECT   
			@ErrorNumber = error_number(), 
			@ErrorMessage = isnull(error_message(), 'Сообщение не определенно') + @c1310 +
				'[' + 'Процедура ' + isnull(error_procedure(), 'не определена') + @c1310 +
				'Строка '+isnull(convert(varchar(20), error_line()), 'не определена') + ']',
			@ErrorSeverity = error_severity(),
			@ErrorState  = error_state()
		
			SET @ErrorMessage = 
				CASE 
					WHEN ISNULL(@ErrorNumber, 50000) = 50000 
						THEN @ErrorMessage 
					ELSE @ErrorMessage + ' Код ошибки:' + cast(@ErrorNumber as nvarchar(10)) 
				END
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
	END
	ELSE BEGIN
		RAISERROR(@sError, 16, 1)
	END
END

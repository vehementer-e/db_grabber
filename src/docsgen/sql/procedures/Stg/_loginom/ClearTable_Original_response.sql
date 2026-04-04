-- Usage: запуск процедуры с параметрами
-- EXEC _loginom.ClearTable_Original_response;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROC _loginom.ClearTable_Original_response
	--@batchSize int = 1000000
AS
BEGIN
	SET XACT_ABORT ON
	begin TRY
		UPDATE R
		SET R.JSON = NULL, R.MessageText = NULL, isArchive = 1
		FROM _loginom.Original_response AS R
		WHERE EXISTS(
			SELECT TOP(1) 1 
			FROM stgLoginomArch._loginom.Original_response_upd AS A
			WHERE R.Id = A.Id
			)

		TRUNCATE TABLE stgLoginomArch._loginom.Original_response_upd
	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END

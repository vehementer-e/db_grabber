/*
	exec _1cCRM.Deduplicate_Документ_ЗаявкаНаЗаймПодПТС_upd
*/
CREATE   PROC _1cCRM.Deduplicate_Документ_ЗаявкаНаЗаймПодПТС_upd
as	
BEGIN
	SET XACT_ABORT ON

	BEGIN TRY
		IF EXISTS(
			SELECT cnt = count(U.Ссылка), U.Ссылка 
			FROM _1cCRM.Документ_ЗаявкаНаЗаймПодПТС_upd AS U
			GROUP BY U.Ссылка
			HAVING count(U.Ссылка) > 1
		)
		BEGIN
			;WITH duplicate AS (
				SELECT 
					U.*,
					rn = row_number() OVER(PARTITION BY U.Ссылка ORDER BY getdate())
				FROM _1cCRM.Документ_ЗаявкаНаЗаймПодПТС_upd AS U
			)
			--SELECT D.*
			DELETE D 
			FROM duplicate AS D
			WHERE D.rn > 1
		END
	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
END
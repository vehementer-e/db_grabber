-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 25.07.2025
-- Description:	Обновление таблицы stg._fedor.core_user 
--				без использования АД
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC _fedor.[update_core_user];
-- Параметры соответствуют объявлению процедуры ниже.
create   PROCEDURE _fedor.[update_core_user] 
AS
BEGIN
begin try
begin tran
	 -- Начинаем обновление
	MERGE INTO stg._fedor.core_user        AS tgt
	USING      stg._fedor.core_user_upd    AS src
	       ON  src.Id = tgt.Id
	WHEN MATCHED AND (
			tgt.fRowVersion <>	src.fRowVersion
		OR  src.IsDeleted <> tgt.IsDeleted
	) THEN
		UPDATE SET
			tgt.CreatedOn		= src.CreatedOn,
	        tgt.DomainLogin		= src.DomainLogin,
	        tgt.Description		= src.Description,
	        tgt.FirstName		= src.FirstName,
	        tgt.MiddleName		= src.MiddleName,
	        tgt.LastName		= src.LastName,
			tgt.isDeleted		= src.isDeleted,
			tgt.NaumenLogin		= src.NaumenLogin,
	        tgt.DWHInsertedDate = isnull(src.DWHInsertedDate, getdate()),
			tgt.ProcessGUID		= src.ProcessGUID,
			tgt.fRowVersion		= src.fRowVersion,
	        tgt.UserTypeId		= src.UserTypeId,
	        tgt.IsQAUser		= src.IsQAUser,
			tgt.DeleteDate		=	CASE
										WHEN src.IsDeleted = 1 AND tgt.IsDeleted = 0 THEN cast(getdate() as date)
										WHEN src.IsDeleted = 0 AND tgt.IsDeleted = 1 THEN null
										ELSE tgt.DeleteDate
									END
	
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (Id, CreatedOn, DomainLogin, Description,
				FirstName, MiddleName, LastName, IsDeleted,
				NaumenLogin, DWHInsertedDate, ProcessGUID,
				fRowVersion, DeleteDate, UserTypeId, IsQAUser
		)
		VALUES (src.Id, src.CreatedOn, src.DomainLogin,
				src.Description, src.FirstName, src.MiddleName,
				src.LastName, src.IsDeleted, src.NaumenLogin,
				src.DWHInsertedDate, src.ProcessGUID, src.fRowVersion,
				src.DeleteDate, src.UserTypeId, src.IsQAUser
		);
commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
END
 
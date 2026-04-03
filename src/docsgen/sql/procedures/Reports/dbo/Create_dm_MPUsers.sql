-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 21.01.2020
-- Description:	Create user list from mp  
-- exec stg.dbo.Createdm_MPUsers
-- SELECT * FROM dbo.dm_MPUsers
-- =======================================================
-- Modify: 9.02.2022. А.Никитин
-- Description:	DWH-1497 Переписать процедуру Загрузка пользователей в dm_MPUsers 
--   из бэка мобильного приложения (dwh-267) exec stg.dbo.Createdm_MPUsers
--	1) Процедура должна быть в бд Reports т.к. сохраняет данные в бд Reports
--	2) Процедура должна использовать локальную копию данных, а не данных с LinkedServer
--	3) Учитывать эти моменты при работе задания ETL. from 1C 2 dwh 
-- =======================================================
CREATE PROCEDURE dbo.Create_dm_MPUsers
AS
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #LK_users_requests

	SELECT L.username,
		concat(L.last_name,' ', L.first_name,' ',L.second_name) AS name,
		L.date_active,
		L.num_1c,
		L.agreement_date
	INTO #LK_users_requests
	FROM (
		SELECT 
			R.num_1c,
			U.updated_at AS date_active,
			U.username,
			U.last_name,
			U.first_name,
			U.second_name,
			R.created_at AS agreement_date
		FROM Stg._LK.users AS U
			LEFT JOIN Stg._LK.requests AS R
				ON R.client_id = U.id
		WHERE U.active=1
		) AS L
  
    IF (SELECT COUNT(*) FROM #LK_users_requests) > 1000
	BEGIN
		BEGIN TRAN
			DELETE FROM dbo.dm_MPUsers WHERE 1=1

			INSERT INTO dbo.dm_MPUsers(username, name, date_active, num_1c, agreement_date)
			SELECT T.username, T.name, T.date_active, T.num_1c, T.agreement_date
			FROM #LK_users_requests AS T
		COMMIT TRAN
	END
END

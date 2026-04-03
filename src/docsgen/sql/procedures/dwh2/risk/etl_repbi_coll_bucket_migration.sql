
--exec [dwh2].[risk].[etl_repbi_coll_bucket_migration];
CREATE PROCEDURE [risk].[etl_repbi_coll_bucket_migration]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY

		DROP TABLE

		IF EXISTS #base;
			SELECT d.number
				,CASE 
					WHEN d.OverdueDays = 0
						THEN '[0. 0]'
					WHEN d.OverdueDays < 31
						THEN '[1. 1-30]'
					WHEN d.OverdueDays < 61
						THEN '[2. 31-60]'
					WHEN d.OverdueDays < 91
						THEN '[3. 61-90]'
					WHEN d.OverdueDays < 121
						THEN '[4. 91-120]'
					WHEN d.OverdueDays < 361
						THEN '[5. 121-360]'
					WHEN d.OverdueDays >= 361
						THEN '[6. 361+]'
					ELSE '[0. 0]'
					END AS bucket_td
				,db.[Name] bucket_transit
				,db.[Sum] sum_transit
				,db.[Order]
				,sum(1) OVER (PARTITION BY d.number) cnt
				,cs.Name as Collecting_Stage
				,d.DebtSum as [Тело займа] 
				,CONCAT(c.LastName, ' ',c.Name, ' ', c.MiddleName) as [ФИО Клиента]
				,CONCAT(ee.LastName, ' ',ee.FirstName, ' ', ee.MiddleName) as [Ответственный взыскатель]
				INTO #base
			FROM stg._collection.DebtBucket db
			INNER JOIN stg._collection.deals d
				ON d.id = db.dealid
			INNER JOIN stg._collection.customers c
				ON c.id = d.idcustomer
			INNER JOIN stg._Collection.collectingStage cs
				ON cs.Id = d.stageid
			LEFT JOIN stg._Collection.Employee ee
				ON ee.id=c.ClaimantId
			WHERE 1 = 1
				AND d.OverdueDays >= 61
				AND d.OverdueDays <= 90
				AND d.stageid IN (
					3 --Legal, письмо от Ирина Давидюк 14/03/2023
					,6
					,11
					,12
					)
				AND db.[Name] IN (
					'61-90'
					,'31-60'
					,'1-30'
					);


		TRUNCATE TABLE risk.repbi_coll_bucket_migration;

		INSERT INTO risk.repbi_coll_bucket_migration
		SELECT DISTINCT b_1.number
			,CASE 
				WHEN b_3.sum_transit IS NULL
					THEN b_2.sum_transit
				ELSE b_3.sum_transit
				END AS value
			,cast('sum_transit_61_90_31_60' AS VARCHAR(300)) AS metric
			,b_1.Collecting_Stage
			,b_1.[Тело займа]
			,b_1.[ФИО Клиента]
			,b_1.[Ответственный взыскатель]
		FROM #base b_1
		LEFT JOIN (
			SELECT *
			FROM #base
			WHERE bucket_transit = '31-60'
			) b_2
			ON b_2.number = b_1.number
		LEFT JOIN (
			SELECT *
			FROM #base
			WHERE bucket_transit = '61-90'
			) b_3
			ON b_3.number = b_1.number

		INSERT INTO risk.repbi_coll_bucket_migration
		SELECT DISTINCT b_1.number
			,CASE 
				WHEN b_4.sum_transit IS NULL
					THEN b_3.sum_transit
				ELSE b_4.sum_transit
				END AS value
			,cast('sum_transit_61_90_1_30' AS VARCHAR(300)) AS metric
			,b_1.Collecting_Stage
			,b_1.[Тело займа]
			,b_1.[ФИО Клиента]
			,b_1.[Ответственный взыскатель]
		FROM #base b_1
		LEFT JOIN (
			SELECT *
			FROM #base
			WHERE bucket_transit = '61-90'
			) b_3
			ON b_3.number = b_1.number
		LEFT JOIN (
			SELECT *
			FROM #base
			WHERE bucket_transit = '1-30'
			) b_4
			ON b_4.number = b_1.number;

		DROP TABLE

		IF EXISTS #base1;
			SELECT d.number
				,CASE 
					WHEN d.OverdueDays = 0
						THEN '[0. 0]'
					WHEN d.OverdueDays < 31
						THEN '[1. 1-30]'
					WHEN d.OverdueDays < 61
						THEN '[2. 31-60]'
					WHEN d.OverdueDays < 91
						THEN '[3. 61-90]'
					WHEN d.OverdueDays < 121
						THEN '[4. 91-120]'
					WHEN d.OverdueDays < 361
						THEN '[5. 121-360]'
					WHEN d.OverdueDays >= 361
						THEN '[6. 361+]'
					ELSE '[0. 0]'
					END AS bucket_td
				,db.[Name] bucket_transit
				,db.[Sum] sum_transit
				,db.[Order]
				,sum(1) OVER (PARTITION BY d.number) cnt
				,cs.Name as Collecting_Stage
				,d.DebtSum as [Тело займа] 
				,CONCAT(c.LastName, ' ',c.Name, ' ', c.MiddleName) as [ФИО Клиента]
				,CONCAT(ee.LastName, ' ',ee.FirstName, ' ', ee.MiddleName) as [Ответственный взыскатель]
			INTO #base1
			FROM stg._collection.[DebtBucket] db
			INNER JOIN stg._collection.deals d
				ON d.id = db.dealid
			INNER JOIN stg._collection.customers c
				ON c.id = d.idcustomer
			INNER JOIN stg._Collection.collectingStage cs
				ON cs.Id = d.stageid
			LEFT JOIN stg._Collection.Employee ee
				ON ee.id=c.ClaimantId
			WHERE 1 = 1
				AND d.OverdueDays >= 31
				AND d.OverdueDays <= 60
				AND d.stageid IN (
					6
					,7
					,11
					,12
					)
				AND db.[Name] IN (
					'31-60'
					,'1-30'
					);

		INSERT INTO risk.repbi_coll_bucket_migration
		SELECT DISTINCT b_1.number
			,CASE 
				WHEN b_3.sum_transit IS NULL
					THEN b_2.sum_transit
				ELSE b_3.sum_transit
				END AS value
			,'sum_transit_31_60_1_30' AS metric
			,b_1.Collecting_Stage
			,b_1.[Тело займа]
			,b_1.[ФИО Клиента]
			,b_1.[Ответственный взыскатель]
		FROM #base1 b_1
		LEFT JOIN (
			SELECT *
			FROM #base1
			WHERE bucket_transit = '1-30'
			) b_2
			ON b_2.number = b_1.number
		LEFT JOIN (
			SELECT *
			FROM #base1
			WHERE bucket_transit = '31-60'
			) b_3
			ON b_3.number = b_1.number

		EXEC risk.set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'a.kuznecov@techmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;

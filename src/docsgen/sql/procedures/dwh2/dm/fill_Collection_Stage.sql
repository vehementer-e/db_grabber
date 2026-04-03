/*
drop table if exists dm.Collection_Stage
exec dm.fill_Collection_Stage
*/
-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-06-17
-- Description:	DWH-2594 Разработать витрину по стадиям Collection на данных Спейс
-- =============================================
/*
*/
CREATE   PROC dm.fill_Collection_Stage
	@mode int = 1 -- 0 - full, 1 - increment
	--@days int = 10, --кол-во дней для пересчета
	,@CrmCustomerId varchar(36) = NULL -- расчет по одному клиентук
	,@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @created_at date = '2000-01-01'
	DECLARE @CustomerId int
	DECLARE @start_dt datetime, @row_count int, @duration int

	BEGIN TRY

		if OBJECT_ID ('dm.Collection_Stage') is not NULL
			AND @mode = 1
		begin
			--SELECT @dm_date = isnull((select dateadd(DAY, -1, max(dm_date)) from dm.Collection_Stage), '2000-01-01')
			SELECT @created_at = isnull((select dateadd(DAY, -3, max(created_at)) from dm.Collection_Stage), '2000-01-01')
		end

		IF @CrmCustomerId IS NOT NULL BEGIN
			SELECT @CustomerId = C.Id
			FROM Stg._Collection.customers AS C
			WHERE C.CrmCustomerId = @CrmCustomerId
		END

		DROP TABLE IF EXISTS #t_Customer

		SELECT @start_dt = getdate(), @row_count = 0

		SELECT DISTINCT	st.CustomerId
		INTO #t_Customer
		FROM Stg._Collection.StageTransitions AS st --WITH(INDEX=ix_TransitionDate_CustomerId)
		WHERE 1=1
			AND st.TransitionDate >= @created_at 
			AND (st.CustomerId = @CustomerId OR @CustomerId IS NULL)

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT concat('INSERT #t_Customer: ', @row_count, ', ', datediff(SECOND, @start_dt, getdate()))
			DROP TABLE IF EXISTS ##t_Customer
			SELECT * INTO ##t_Customer FROM #t_Customer AS C
		END

		CREATE INDEX ix1 ON #t_Customer(CustomerId)


		DROP TABLE IF EXISTS #t_Stage

		SELECT @start_dt = getdate(), @row_count = 0

		/*
		в Stg._Collection.StageTransitions  есть полные дубли по дате
		например, CustomerId = 48492
		Id		CustomerId	TransitionDate
		341372	48492		2021-06-30 07:00:31.5803229
		341517	48492		2021-06-30 07:00:31.5803229

		поэтому за каждый день
		вместо min(TransitionDate) и max(TransitionDate)
		берем min(Id) и max(Id)
		*/

		SELECT 
			st.CustomerId,
			Transition_dt = cast(st.TransitionDate AS date),
			--min_TransitionDate = min(st.TransitionDate),
			--max_TransitionDate = max(st.TransitionDate)
			min_id = min(st.Id),
			max_id = max(st.Id)
		INTO #t_Stage
		FROM Stg._Collection.StageTransitions AS st --WITH(INDEX=ix_TransitionDate_CustomerId)
			INNER JOIN #t_Customer AS C
				ON C.CustomerId = st.CustomerId
		GROUP BY st.CustomerId, cast(st.TransitionDate AS date)

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT concat('INSERT #t_Stage: ', @row_count, ', ', datediff(SECOND, @start_dt, getdate()))
			DROP TABLE IF EXISTS ##t_Stage
			SELECT * INTO ##t_Stage FROM #t_Stage AS C
		END

		CREATE INDEX ix1 ON #t_Stage(CustomerId)


		DROP TABLE IF EXISTS #t_dm_Collection_Stage

		SELECT @start_dt = getdate(), @row_count = 0

		SELECT 
			created_at = getdate(),
			A.CustomerId,
			CrmClientGuid = M.CrmCustomerId,
			M.LastName,
			M.Name,
			M.MiddleName,
			dt_from = A.Transition_dt,
			dt_to = cast(NULL AS date),
			--cs_old.name AS old_Client_Stage,
			ClientStage = cs_new.name
		INTO #t_dm_Collection_Stage
		FROM #t_Stage AS A
			INNER JOIN Stg._Collection.StageTransitions AS st_min
				ON st_min.CustomerId = A.CustomerId
				--AND st_min.TransitionDate = A.min_TransitionDate
				AND st_min.Id = A.min_id
			LEFT JOIN Stg._Collection.collectingStage AS cs_old
				ON cs_old.Id = st_min.OldCollectingStageId

			INNER JOIN Stg._Collection.StageTransitions AS st_max
				ON st_max.CustomerId = A.CustomerId
				--AND st_max.TransitionDate = A.max_TransitionDate
				AND st_max.Id = A.max_id
			LEFT JOIN Stg._Collection.collectingStage AS cs_new
				ON cs_new.Id = st_min.NewCollectingStageId
			INNER JOIN Stg._Collection.customers AS M
				ON M.Id = A.CustomerId

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT concat('INSERT #t_dm_Collection_Stage: ', @row_count, ', ', datediff(SECOND, @start_dt, getdate()))
		END

		CREATE INDEX ix_CustomerId_dt_from
		ON #t_dm_Collection_Stage(CustomerId, dt_from)

		SELECT @start_dt = getdate(), @row_count = 0

		-- дата окончания интервала
		UPDATE A
		SET A.dt_to = isnull(dateadd(DAY, -1, B.dt_next), '2100-01-01')
		FROM #t_dm_Collection_Stage AS A
			INNER JOIN (
				SELECT 
					T.CustomerId,
					T.dt_from,
					lead(T.dt_from) OVER (
							PARTITION BY T.CustomerId ORDER BY T.dt_from
						) AS dt_next
				FROM #t_dm_Collection_Stage AS T
			) AS B
			ON B.CustomerId = A.CustomerId
			AND B.dt_from = A.dt_from

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT concat('UPDATE #t_dm_Collection_Stage: ', @row_count, ', ', datediff(SECOND, @start_dt, getdate()))

			DROP TABLE IF EXISTS ##t_dm_Collection_Stage
			SELECT * INTO ##t_dm_Collection_Stage FROM #t_dm_Collection_Stage AS C
		END


		--DROP TABLE IF EXISTS dm.Collection_Stage
		if OBJECT_ID('dm.Collection_Stage') is null
		BEGIN
			SELECT TOP 0 *
			INTO dm.Collection_Stage
			FROM #t_dm_Collection_Stage AS S

			CREATE INDEX ix_CrmClientGuid_dt_from_dt_to
			ON dm.Collection_Stage(CrmClientGuid, dt_from, dt_to)

			CREATE INDEX ix_CustomerId
			ON dm.Collection_Stage(CustomerId)

			CREATE UNIQUE INDEX ix_CrmClientGuid_dt_from
			ON dm.Collection_Stage(CrmClientGuid, dt_from)
        END


		if exists(select top(1) 1 from #t_dm_Collection_Stage)
		BEGIN
			BEGIN TRAN
				SELECT @start_dt = getdate(), @row_count = 0

				DELETE D
				FROM dm.Collection_Stage AS D
					INNER JOIN #t_Customer AS C
						ON C.CustomerId = D.CustomerId

				SELECT @row_count = @@ROWCOUNT
				IF @isDebug = 1 BEGIN
					SELECT concat('DELETE dm.Collection_Stage: ', @row_count, ', ', datediff(SECOND, @start_dt, getdate()))
				END

				SELECT @start_dt = getdate(), @row_count = 0

				INSERT dm.Collection_Stage
				SELECT 
					S.created_at,
					S.CustomerId,
					S.CrmClientGuid,
					S.LastName,
					S.Name,
					S.MiddleName,
					S.dt_from,
					S.dt_to,
					S.ClientStage
				FROM #t_dm_Collection_Stage AS S

				SELECT @row_count = @@ROWCOUNT
				IF @isDebug = 1 BEGIN
					SELECT concat('INSERT dm.Collection_Stage: ', @row_count, ', ', datediff(SECOND, @start_dt, getdate()))
				END
			COMMIT
		END

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END

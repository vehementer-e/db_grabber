-- exec [collection].[fill_dm_climant_portfolio]
CREATE   PROCEDURE [collection].[fill_dm_climant_portfolio]
AS
BEGIN
BEGIN TRY
	------------------ временный сет сотрудник - клиент - дата привязки - дата отвязки -------------
	drop table if exists #claimant_customer_attach_detach;
	WITH Events AS (
		-- События "прикрепления": появился NewClaimantId
		SELECT
			CustomerId,
			ClaimantId   = NewClaimantId,
			EventDate    = [Date],
			EventType    = 'attach',
			RowId        = Id
		FROM  Stg._Collection.ClaimantCustomersHistory
		WHERE NewClaimantId IS NOT NULL

		UNION ALL

		-- События "открепления": был OldClaimantId (в т.ч. при reassignment или когда New=NULL)
		SELECT
			CustomerId,
			ClaimantId   = OldClaimantId,
			EventDate    = [Date],
			EventType    = 'detach',
			RowId        = Id
		FROM  Stg._Collection.ClaimantCustomersHistory
		WHERE OldClaimantId IS NOT NULL
	),
	Attaches AS (
		SELECT
			CustomerId,
			ClaimantId,
			StartDate = EventDate,
			RowId,
			-- нумеруем прикрепления в паре (Customer, Claimant)
			rn = ROW_NUMBER() OVER (
					PARTITION BY CustomerId, ClaimantId
					ORDER BY EventDate, RowId
				)
		FROM Events
		WHERE EventType = 'attach'
	),
	Detaches AS (
		SELECT
			CustomerId,
			ClaimantId,
			EndDate = EventDate,
			RowId,
			rn = ROW_NUMBER() OVER (
					PARTITION BY CustomerId, ClaimantId
					ORDER BY EventDate, RowId
				)
		FROM Events
		WHERE EventType = 'detach'
	),
	-- На случай “неровной” истории (иногда встречаются повторы attach без detach и наоборот)
	-- надёжнее подбирать "следующее" открепление через APPLY
	Pairs AS (
		SELECT
			a.CustomerId,
			a.ClaimantId,
			a.StartDate,
			d_next.EndDate
		FROM Attaches a
		OUTER APPLY (
			SELECT TOP (1) d.EndDate
			FROM Detaches d
			WHERE d.CustomerId = a.CustomerId
			  AND d.ClaimantId = a.ClaimantId
			  AND d.EndDate >= a.StartDate
			ORDER BY d.EndDate, d.RowId
		) d_next
	)
	SELECT
		ClaimantId,
		CustomerId,
		StartDate,
		EndDate,
		ROW_NUMBER() over (order by startDate) as assignmentId
	into #claimant_customer_attach_detach
	FROM 
		Pairs
	ORDER BY 
		ClaimantId, CustomerId, StartDate;


	------------------------------------------ закончили создавать сотрудник - клиент - дата привязки - дата отвязки
--select top(100) * from #claimant_customer_attach_detach where CustomerId=55970 order by StartDate;
	--------------------------------- доста\м все записи для договоров клиента из баланса за периоды закреплений за сотрудником
	drop table if exists #dm_claimant_portfolio_balance;
	select
		cc.*,
		d.Number,
		b.d,
		b.dpd_p_coll as dpd_before,
		b.dpd_coll as dpd_after,
		b.bucket_p_coll as bucket_before,
		b.bucket_coll as bucket_after,
		b.[остаток од] as rest_od,
		b.prev_od,
		b.overdue,
		b.pay_total,
		d.StageId
	into #dm_claimant_portfolio_balance
	from
		#claimant_customer_attach_detach cc
		inner join
		Stg._Collection.Deals d on d.idCustomer = cc.CustomerId
		inner join
		dwh2.dbo.dm_CMRStatBalance  b on b.external_id = d.number and b.d between cast(cc.StartDate as date) and coalesce(cc.EndDate, cast('2099-12-31' as date))
	where 1=1
		--and cc.ClaimantId = 8
	order by
		cc.ClaimantId, cc.StartDate desc

	create clustered index ix_tmp_claimant_portfolio_balance on #dm_claimant_portfolio_balance(ClaimantId);
-- select * into dbo.tmp_claimant_444 from #dm_claimant_portfolio_balance where claimantId=444 order by StartDate;
-- drop table dbo.tmp_claimant_444 -- drop table dbo.claimant_444_1
-- select * from  dbo.tmp_claimant_444 where customerId=99062 order by d desc
-- select * into dbo.claimant_444_1 from #dm_claimant_portfolio
-- select * from dbo.claimant_444_1  where endDate > '2025-11-01 00:00:01' and total_pay>0 order by assignmentId desc
-- select * from dbo.claimant_444_1  where customerId=99062 order by assignmentId desc
	------------------------ схлопываем историю и берем крайние значения балансов и бакетов (на дату закрепления и открепления)
	drop table if exists #dm_claimant_portfolio;
	WITH x AS (
		SELECT
			assignmentId,
			ClaimantId,
			CustomerId,
			Number,
			d,
			dpd_before,
			dpd_after,
			bucket_before,
			bucket_after,
			rest_od,
			prev_od,
			overdue,
			pay_total,
			StartDate,
			EndDate,
			StageId,
			--rn_first = ROW_NUMBER() OVER (
			--		PARTITION BY assignmentId, Number
			--		ORDER BY d
			--),
			--rn_last = ROW_NUMBER() OVER (
			--		PARTITION BY assignmentId, Number
			--		ORDER BY pay_total desc, d desc
			--),
			--CASE 
			--WHEN pay_total > 0 THEN
			SUM(CASE WHEN pay_total > 0 THEN 1 ELSE 0 END)
			OVER (
				PARTITION BY assignmentId, Number
				ORDER BY d
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			) AS payment_num
			--ELSE 0
			--END AS payment_num
		FROM #dm_claimant_portfolio_balance --dbo.tmp_claimant_444
	), x_numered as (
		select
			x.*,
			row_number() over (partition by x.assignmentId, x.Number, x.payment_num order by d) as rn_in_payment_group
		from
			x --where payment_num > 0
	)
	SELECT --x_numered.* from x_numered order by assignmentId desc, number, d desc, rn_in_payment_group desc
		x_numered.assignmentId,
		min(x_numered.ClaimantId) as ClaimantId,
		MIN(concat(emp.LastName, ' ', emp.FirstName)) as ClaimantName,
		min(CustomerId) as CustomerId,
		MIN(concat(cust.LastName, ' ', cust.Name)) as CustomerName,
		Number,
		current_bucket  = (select top(1) bucket from dwh2.dbo.dm_CMRStatBalance where external_id=x_numered.Number and d=CAST(GETDATE() - 1 AS date)),
		startDate       = MIN(startDate), --MIN(case when rn_first = 1 THEN startDate END),
		endDate         = MAX(case when rn_in_payment_group = 1 THEN x_numered.d else endDate END),
		dpd_on_start    = MAX(case when rn_in_payment_group = 1 THEN dpd_before END),
		rest_od_on_start= MAX(CASE WHEN rn_in_payment_group = 1 THEN prev_od END),
		stage_on_start = MAX(CASE WHEN rn_in_payment_group = 1 THEN stage.Name END),
		overdue_on_start= MAX(CASE WHEN rn_in_payment_group = 1 THEN overdue END),
		dpd_on_end      = MAX(CASE WHEN rn_in_payment_group = 1 THEN dpd_after END),
		bucket_on_end   = MAX(CASE WHEN rn_in_payment_group = 1 THEN bucket_after END),
		rest_od_on_end  = MAX(CASE WHEN rn_in_payment_group = 1 THEN rest_od END),
		stage_on_end= MAX(CASE WHEN rn_in_payment_group = 1 THEN stage.Name END),
		overdue_on_end= MAX(CASE WHEN rn_in_payment_group = 1 THEN overdue END),
		total_pay       = SUM(COALESCE(pay_total, 0)),
		payment_num
		--bucket_on_start = MAX(CASE WHEN rn_first = 1 THEN bucket_coll END),
		--rest_od_on_start= MAX(CASE WHEN rn_first = 1 THEN rest_od END),
		--stage_on_start= MAX(CASE WHEN rn_first = 1 THEN stage.Name END),
		--overdue_on_start= MAX(CASE WHEN rn_first = 1 THEN overdue END),
		--dpd_on_end    = MAX(CASE WHEN rn_last = 1 THEN dpd END),
		--bucket_on_end = MAX(CASE WHEN rn_last = 1 THEN bucket_coll END),
		--rest_od_on_end= MAX(CASE WHEN rn_last = 1 THEN rest_od END),
		--stage_on_end= MAX(CASE WHEN rn_last = 1 THEN stage.Name END),
		--overdue_on_end= MAX(CASE WHEN rn_last = 1 THEN overdue END),
		--total_pay       = SUM(COALESCE(pay_total, 0))
	into #dm_claimant_portfolio
	FROM 
		x_numered
		inner join
		Stg._Collection.Employee emp on emp.Id = x_numered.ClaimantId
		inner join
		[Stg].[_Collection].customers cust on cust.Id = x_numered.CustomerId
		left join
		Stg._Collection.collectingStage stage on stage.Id = x_numered.StageId
	--where payment_num > 0
	GROUP BY
		x_numered.assignmentId, Number, payment_num
	;
-- drop table collection.dm_claimant_portfolio
-- select top(100) * from collection.dm_claimant_portfolio where ClaimantId = 444 and payment_num>0 and dpd_on_start>dpd_on_end and endDate>='2025-11-01' and customerId=55970 order by assignmentId desc
		if OBJECT_ID('collection.dm_claimant_portfolio') is null
		begin
			select top(0)
				*
			into collection.dm_claimant_portfolio
			from #dm_claimant_portfolio
			CREATE NONCLUSTERED INDEX IX_dm_claimant_portfolio_start_date 
			ON collection.dm_claimant_portfolio (startDate);

		end

        BEGIN TRAN;
        TRUNCATE TABLE collection.dm_claimant_portfolio;

		insert into collection.dm_claimant_portfolio
			select
				*			
			from #dm_claimant_portfolio

        COMMIT TRAN;

END TRY

BEGIN CATCH
       if @@TRANCOUNT>0
		rollback tran;
		throw
END CATCH

END

-- exec [collection].[fill_dm_dashboard_collection]
CREATE PROCEDURE [collection].[fill_dm_dashboard_collection]
	@rdt date = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @rdt IS NULL
		SET @rdt = (
					SELECT
						case 
							when day(GETDATE()) > 15 then DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
							else DATEFROMPARTS(YEAR(GETDATE()), MONTH(dateadd(mm,-1,GETDATE())), 1) 
						end rdt
					)
	
	BEGIN TRY

		-------------------
		-- за сегодня факт
		------------------- select * from #by_buckets_today order by bucket_coll
		drop table if exists #by_buckets_today;
		select
			bucket_coll,
			cdm.[Тип продукта] as product_type,
			max(gp.ГруппаПродуктов_Наименование) as product_group,
			sum(reduced_balance) as reduced_balance,
			sum(pay_total) as pay_total
		into #by_buckets_today
		from
			dwh2.riskCollection.collection_datamart cdm
			inner join
			dwh2.hub.ДоговорЗайма dog on dog.КодДоговораЗайма = cdm.external_id
			left join
			dwh2.hub.v_hub_ГруппаПродуктов gp on gp.ПодтипПродуктd_Наименование = dog.ПодТипПродукта
		where
			d = cast(getdate() as date)
		group by
			bucket_coll, cdm.[Тип продукта];

		-------------------
		-- за месяц факт
		-------------------
		drop table if exists #by_buckets_month;
		select
			bucket_coll,
			cdm.[Тип продукта] as product_type,
			max(gp.ГруппаПродуктов_Наименование) as product_group,
			sum(reduced_balance) as reduced_balance,
			sum(pay_total) as pay_total
		into #by_buckets_month
		from
			dwh2.riskCollection.collection_datamart cdm
			inner join
			dwh2.hub.ДоговорЗайма dog on dog.КодДоговораЗайма = cdm.external_id
			left join
			dwh2.hub.v_hub_ГруппаПродуктов gp on gp.ПодтипПродуктd_Наименование = dog.ПодТипПродукта
		where
			d >= cast(DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) as date)
		group by
			bucket_coll, cdm.[Тип продукта];

		-------------------
		-- за предыдущий месяц факт
		-------------------
		drop table if exists #by_buckets_prev_month;
		select
			bucket_coll,
			cdm.[Тип продукта] as product_type,
			max(gp.ГруппаПродуктов_Наименование) as product_group,
			sum(reduced_balance) as reduced_balance,
			sum(pay_total) as pay_total
		into #by_buckets_prev_month
		from
			dwh2.riskCollection.collection_datamart cdm
			inner join
			dwh2.hub.ДоговорЗайма dog on dog.КодДоговораЗайма = cdm.external_id
			left join
			dwh2.hub.v_hub_ГруппаПродуктов gp on gp.ПодтипПродуктd_Наименование = dog.ПодТипПродукта
		where d BETWEEN 
				cast(DATEADD(MONTH, -1, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE())) AS date)
				AND cast(DATEADD(MONTH, -1, GETDATE()) AS date)
		group by
			bucket_coll, cdm.[Тип продукта];

	 
	begin tran
	delete t from collection.dm_dashboard_collection t;
	
	insert into collection.dm_dashboard_collection (
		bucket_coll, product_type, product_group, reduced_fact_today, pay_total_today, reduced_fact_month, 
		pay_total_month, reduced_plan, reduced_fact_prev, pay_total_prev_month
	)
	select
		tday.bucket_coll,
		tday.product_type,
		tday.product_group,
		tday.reduced_balance as reduced_fact_today,
		tday.pay_total as pay_total_today,
		mnth.reduced_balance as reduced_fact_month,
		mnth.pay_total as pay_total_month,
		pln.Приведенный as reduced_plan,
		prev.reduced_balance as reduced_fact_prev,
		prev.pay_total as pay_total_prev_month
	from
		#by_buckets_month as mnth
		left join
		#by_buckets_today tday on mnth.bucket_coll = tday.bucket_coll and mnth.product_type = tday.product_type
		left join
		#by_buckets_prev_month prev on prev.bucket_coll = mnth.bucket_coll and prev.product_type = mnth.product_type
		left join
		dwh2.riskcollection.daily_plans_1_90_report pln on pln.bucket_from = mnth.bucket_coll 
															and pln.Product = dwh2.collection.product_eng(mnth.product_type)
															and pln.rep_dt_month = DATEADD(DAY, 1, EOMONTH(GETDATE(), -1));
	commit tran

--select top(100) * from dwh2.riskcollection.daily_plans_1_90_report where rep_dt_month='2025-11-01' order by rep_dt_month desc;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
    END CATCH;
END;

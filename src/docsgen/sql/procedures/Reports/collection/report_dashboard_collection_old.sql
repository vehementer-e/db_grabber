
-- exec [collection].[report_dashboard_collection] 'bigInstallment'
CREATE   PROCEDURE [collection].[report_dashboard_collection_old]
	@product_group varchar(128) = NULL,
	@rdt date = NULL
AS
BEGIN

    IF @rdt IS NULL
		SET @rdt = (
					SELECT
						case 
							when day(GETDATE()) > 15 then DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
							else DATEFROMPARTS(YEAR(GETDATE()), MONTH(dateadd(mm,-1,GETDATE())), 1) 
						end rdt
					)

		-------------------
		-- за сегодня факт
		------------------- 
		drop table if exists #by_buckets_today;
		select
			bucket_p_coll,
			min(cdm.[Тип продукта]) as product_type,
			gp.ГруппаПродуктов_Наименование as product_group,
			gp.ГруппаПродуктов_Code,
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
			and
			pay_total>0
		group by
			bucket_p_coll, gp.ГруппаПродуктов_Наименование, gp.ГруппаПродуктов_Code;

		-------------------
		-- за месяц факт
		-------------------
		drop table if exists #by_buckets_month;
		select
			bucket_p_coll,
			min(cdm.[Тип продукта]) as product_type,
			gp.ГруппаПродуктов_Наименование as product_group,
			gp.ГруппаПродуктов_Code,

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
			--and gp.ГруппаПродуктов_Наименование = 'ПТС'
		group by
			bucket_p_coll, gp.ГруппаПродуктов_Наименование, gp.ГруппаПродуктов_Code;

		-------------------
		-- за предыдущий месяц факт
		-------------------
		drop table if exists #by_buckets_prev_month;
		select
			bucket_p_coll,
			min(cdm.[Тип продукта]) as product_type,
			gp.ГруппаПродуктов_Наименование as product_group,
			gp.ГруппаПродуктов_Code,
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
			bucket_p_coll, gp.ГруппаПродуктов_Наименование, gp.ГруппаПродуктов_Code;

		-------------------
		-- за месяц план
		-------------------
		drop table if exists #by_buckets_plan;
		select
			bucket_from,
			Product,
			sum([Приведенный]) as reduced
		into #by_buckets_plan
		from
		--select * from 
		dwh2.riskcollection.daily_plans_1_90_report 
		where
			rep_dt_month = DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))
		group by
			bucket_from, Product;

		-------------------
		-- всё вместе
		-------------------
--select 
	--bucket_coll, product_type, count(1) q, 
--	sum(pay_total_today) from (	 
		select
			mnth.bucket_p_coll as bucket_coll,
			mnth.product_type,
			mnth.product_group,
			tday.reduced_balance as reduced_fact_today,
			tday.pay_total as pay_total_today,
			mnth.reduced_balance as reduced_fact_month,
			mnth.pay_total as pay_total_month,
			pln.reduced as reduced_plan,
			prev.reduced_balance as reduced_fact_prev,
			prev.pay_total as pay_total_prev_month
		from
			#by_buckets_month as mnth
			left join
			#by_buckets_today tday on mnth.bucket_p_coll = tday.bucket_p_coll 
				and mnth.ГруппаПродуктов_Code = tday.ГруппаПродуктов_Code
			left join
			#by_buckets_prev_month prev on prev.bucket_p_coll = mnth.bucket_p_coll 
				and prev.ГруппаПродуктов_Code = mnth.ГруппаПродуктов_Code
			left join
			#by_buckets_plan pln on pln.bucket_from = mnth.bucket_p_coll
									and lower(pln.Product) = lower(mnth.ГруппаПродуктов_Code)
									--dwh2.collection.product_eng(mnth.product_type)
		where
			mnth.ГруппаПродуктов_Code = @product_group --'BigInstallment'
--		order by    
--			mnth.bucket_p_coll, mnth.product_group
--) t1 group by bucket_coll, product_type order by 1;
END;

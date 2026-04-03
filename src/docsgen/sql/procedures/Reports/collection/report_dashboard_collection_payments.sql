-- exec [collection].[report_dashboard_collection_payments] Installment
CREATE   PROCEDURE [collection].[report_dashboard_collection_payments]
	@product varchar(32) = NULL
AS
BEGIN
	--select * from reports.risk.coll_bucket_migr_adj_coef

	-- select * from dwh2.hub.Клиенты
	-- drop table dbo.tmp_col_payments
--select * from dwh2.dbo.dm_CMRStatBalance where d = cast(getdate() as date) and external_id = '25031503137441';
--	select * from (
	select
		bal.external_id,
		cl.ФИО as client_fio,
		bal.d,
		pay_date.value as pay_date,
		cdm.pay_total,
		bal.bucket_p_coll,
		bal.bucket_coll,
		bal.dpd_begin_day,
		bal.dpd,
		bal.[остаток од] as rest_od,
		--ROUND(bal.[остаток од]*(ac.k1 - ac.k2)/nullif(ac.k1,0), 2) as reduced,
		cdm.reduced_balance as reduced,
		dog.ТипПродукта_Наименование as product_type,
		dog.ПодТипПродукта as product_subtype,
		gp.ГруппаПродуктов_Наименование as product_group
	--into dbo.tmp_col_payments
	from
		dwh2.dbo.dm_CMRStatBalance bal
		inner join
		dwh2.hub.Клиенты cl on cl.GuidКлиент = bal.CMRClientGUID
		outer apply (
				select top(1) DATEADD(YEAR, -2000, pay.Дата) as [value]
				from
					Stg._1cCMR.Документ_Платеж pay
				where
					dwh2.[dbo].[getGUIDFrom1C_IDRREF](pay.Договор) = bal.CMRContractsGUID
										and
										cast(DATEADD(YEAR, -2000, pay.Дата) as date) = bal.d
		) pay_date
		inner join
		dwh2.hub.ДоговорЗайма dog on dog.КодДоговораЗайма = bal.external_id
		left join
		dwh2.hub.v_hub_ГруппаПродуктов gp on gp.ПодтипПродуктd_Наименование = dog.ПодТипПродукта
		inner join
		dwh2.riskCollection.collection_datamart cdm on cdm.external_id = bal.external_id and cdm.d = bal.d
	where
		bal.d = cast(getdate() as date)
		and
		cdm.pay_total > 0
		and
		gp.ГруппаПродуктов_Наименование = @product
--	) red
--	where red.reduced is not null and red.rest_od > red.reduced;

END;

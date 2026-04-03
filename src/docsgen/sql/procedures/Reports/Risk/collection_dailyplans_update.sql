CREATE procedure [Risk].[collection_dailyplans_update] as
begin
	SET XACT_ABORT ON;

begin try
begin tran
	MERGE INTO risk.collection_dailyplans AS target
	USING (select bucket_from,bucket_to,try_cast(Сохраненный as money) as Сохраненный,try_cast(Приведенный as money) as Приведенный
	,Product,rep_dt_month,created from stg.files.risk_daily_plans
) AS source
		on target.bucket_from = source.bucket_from
		and target.bucket_to = source.bucket_to
		and target.Product = source.Product
		and target.rep_dt_month = source.rep_dt_month
	WHEN NOT MATCHED THEN
		INSERT (bucket_from,bucket_to,Сохраненный,Приведенный,Product,rep_dt_month,created) VALUES (
		source.bucket_from,source.bucket_to,source.Сохраненный,source.Приведенный,source.Product,source.rep_dt_month,source.created);
commit tran
end try
begin catch
	if @@TRANCOUNT>0 
		rollback tran
	;throw
end catch
end;

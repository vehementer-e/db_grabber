CREATE procedure [riskCollection].[daily_plans_1_90_postloader] as
begin 

BEGIN TRY
BEGIN TRANSACTION

insert into riskcollection.daily_plans_1_90 
select * from stg.[files].[daily_plans_1_90] b
where not exists (select rep_dt_month from riskcollection.daily_plans_1_90 a where a.rep_dt_month = b.rep_dt_month)

COMMIT TRANSACTION;
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
end;
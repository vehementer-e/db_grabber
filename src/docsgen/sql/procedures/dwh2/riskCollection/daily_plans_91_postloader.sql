CREATE procedure [riskCollection].[daily_plans_91_postloader] as
begin 

BEGIN TRY
BEGIN TRANSACTION

insert into riskcollection.daily_plans_91 
select 
cast(rep_dt_month as date)
,TYPE
,coalesce(TYPE2, '')
,BUCKET
,cast([План] as money)
,product
,created
from stg.[files].[daily_plans_91] b
where not exists (select rep_dt_month from riskcollection.daily_plans_91 a where a.rep_dt_month = b.rep_dt_month)

COMMIT TRANSACTION;
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
end;
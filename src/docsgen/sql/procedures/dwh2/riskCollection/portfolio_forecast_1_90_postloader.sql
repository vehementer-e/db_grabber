create procedure [riskCollection].[portfolio_forecast_1_90_postloader] as
begin 

BEGIN TRY

if OBJECT_ID('riskcollection.portfolio_forecast_1_90') is null
begin
	select top(0) * into riskcollection.portfolio_forecast_1_90
	from stg.[files].[portfolio_forecast_1_90]
end;

BEGIN TRANSACTION

insert into riskcollection.portfolio_forecast_1_90 
select * from stg.[files].[portfolio_forecast_1_90] b
where not exists (select d from riskcollection.portfolio_forecast_1_90 a where a.d = b.d)

COMMIT TRANSACTION;
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
end;
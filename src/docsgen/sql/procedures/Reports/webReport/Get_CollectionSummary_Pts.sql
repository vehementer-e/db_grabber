

CREATE      procedure [webReport].[Get_CollectionSummary_Pts]
 WITH EXECUTE AS 'dbo'
as
begin
SET NOCOUNT ON;
begin try
	
	select 
		dt			= Дата
		,metricName = Стадия
		,fact		= [Факт (млн.руб.)]
		,[plan]		= [План (млн.руб.)]
		,[%completionPlan] = [Факт %%]
		,forecast = [Прогноз (млн.руб.)]
		,[%completionForecast] = [Прогноз %%]
	from stg.dbo.CollectionPlan_4Plazma_PTS
end try
begin catch
	;throw
end catch
end

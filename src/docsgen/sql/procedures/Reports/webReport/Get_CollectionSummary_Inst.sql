

CREATE      procedure [webReport].[Get_CollectionSummary_Inst]
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
		,sortOrder = 
			case Стадия 
				when '1-90' then 1
				when '91+' then 2
				when '1+' then 3
				else 1000 end
	from stg.dbo.CollectionPlan_4Plazma_INST
end try
begin catch
	;throw
end catch
end

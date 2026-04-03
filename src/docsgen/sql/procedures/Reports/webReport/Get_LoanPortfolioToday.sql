CREATE     procedure [webReport].[Get_LoanPortfolioToday]
 WITH EXECUTE AS 'dbo'
as
begin
SET NOCOUNT ON;
begin try
declare @today date = getdate()
	
declare @cur_start_qq_data date = dateadd(qq, datediff(qq, 0,  @today), 0)
	
	declare @plan_month_date date= EOMONTH(@cur_start_qq_data,2)
	

;with cte_mertic as 
(
	select  metricName ='Портфель ОД'
	union all
	select metricName ='Портфель %%'
	union all
	select metricName ='Портфель ОД+%%'
	
)
,cte_prev_year as 
(
	select 
		date			= ДатаОтчета,
		MetricName		= MetricName,
		Value			= Value
	from	(select
		ДатаОтчета
	    ,[Портфель ОД] = isnull([Портфель ОД],0)
		,[Портфель %%] = isnull([Портфель %%],0)
		,[Портфель ОД+%%] = isnull([Портфель ОД],0) + isnull([Портфель %%],0)
		from webReport.LoanPortfolio t
		where Период = 'Прошлый год'
		) prev_year
	
	 UNPIVOT   (Value 
	FOR MetricName IN   (
		 prev_year.[Портфель ОД] 
		,prev_year.[Портфель %%]
		,prev_year.[Портфель ОД+%%]
		)) upvt
	
),cte_prev_day as 
(
	select 
		date		= ДатаОтчета
		,MetricName = MetricName
		,Value		= Value
	from 
		(select 
			ДатаОтчета
			,[Портфель ОД] = isnull([Портфель ОД],0)
			,[Портфель %%] = isnull([Портфель %%],0)
			,[Портфель ОД+%%] = isnull([Портфель ОД],0) + isnull([Портфель %%],0)
				from webReport.LoanPortfolio t
			where Период = 'Последняя дата'
		) prev_day
		UNPIVOT   (Value 
	FOR MetricName IN   (
			prev_day.[Портфель ОД] 
		,prev_day.[Портфель %%]
		,prev_day.[Портфель ОД+%%]
		)) upvt
), cte_prev_month as
(
	select 
		date		 =ДатаОтчета
		,MetricName = MetricName
		,Value		 = Value
	from 
		(select 
			ДатаОтчета
			,[Портфель ОД] = isnull([Портфель ОД],0)
			,[Портфель %%] = isnull([Портфель %%],0)
			,[Портфель ОД+%%] = isnull([Портфель ОД],0) + isnull([Портфель %%],0)
				from webReport.LoanPortfolio t
			where Период = 'Прошлый месяц'
	) prev_month
		UNPIVOT   (Value 
	FOR MetricName IN   (
			prev_month.[Портфель ОД] 
		,prev_month.[Портфель %%]
		,prev_month.[Портфель ОД+%%]
		)) upvt
), cte_plan_month as
(
	select 
		date		 =@plan_month_date
		,MetricName = MetricName
		,Value		 = Value
	from 
		(select 
			[Портфель ОД] = [ОД, руб.]
			,[Портфель %%] = [%%, руб.]
			,[Портфель ОД+%%] = [ОД+%%, руб.]
			from stg.dbo.KPI_4Plazma
				where Месяц =@plan_month_date
	) [plan]
		UNPIVOT   (Value 
	FOR MetricName IN   (
			[plan].[Портфель ОД] 
		,[plan].[Портфель %%]
		,[plan].[Портфель ОД+%%]
		)) upvt
),cte_result as (

select 
	metric.MetricName
	,factPrevYearDate		= prev_year.date
	,factPrevYearValue		= prev_year.Value
	
	,factPrevDayDate		= prev_day.date
	,factPrevDayValue		= prev_day.Value

	,factPrevMonthDate		= prev_month.date
	,factPrevMonthValue		= prev_month.Value
	
	,planMonthDate		= plan_month.date
	,planMonthValue		= plan_month.Value

	

from cte_mertic  metric
LEFT join cte_prev_year prev_year
	on metric.MetricName = prev_year.MetricName
LEFT join cte_prev_day prev_day
	on metric.MetricName = prev_day.MetricName
LEFT join cte_prev_month prev_month
	on metric.MetricName = prev_month.MetricName	
LEFT join cte_plan_month plan_month
	on metric.MetricName = plan_month.MetricName
 
	
	)
	select 
		metricName
		,factPrevYearDate	 
		,factPrevYearValue	= factPrevYearValue
							
		,factPrevDayDate	 	
		,factPrevDayValue	= factPrevDayValue

		,factPrevMonthDate	
		,factPrevMonthValue	= factPrevMonthValue
	
		,planMonthDate	
		,planMonthValue		=  planMonthValue
		,[+/-] = factPrevDayValue - planMonthValue
		,[%] = iif(planMonthValue!=0, factPrevDayValue / planMonthValue-1, 0.0)
		,[Growth from early of the year, %] = iif(factPrevYearValue!=0, (factPrevDayValue/factPrevYearValue-1), 0.0)
		,[Growth from early of the Month, %] = iif(factPrevMonthValue!=0, (factPrevDayValue/factPrevMonthValue)-1, 0.0)
	
	From cte_result
	
end try
begin catch
		;throw
end catch
end
CREATE   procedure [webReport].[Get_CollectionReducedBalanceSummary_PTS]
	WITH EXECUTE AS 'dbo'
as 
begin
	SET NOCOUNT ON;
begin try
	declare @today date = getdate()
	declare @dayInMonth tinyint = DATEDIFF(dd, DATEFROMPARTS(year(@today), month(@today), 1), eomonth(@today)) +1
	;with cte_ReducedBalance_plan  as(
	select
		Стадия = isnull(t.Стадия, '1-90')
		,Value
	from (select 
		
		Стадия = 
			case 
				when bucket_from in ('(2)_1_30') and bucket_to in ('(1)_0')			then '1-30'
				when bucket_from in ('(3)_31_60') and bucket_to in ('(1)_0', '(2)_1_30' ) then '31-60'
				when bucket_from in ('(4)_61_90') and bucket_to in ('(1)_0', '(2)_1_30', '(3)_31_60' ) then '61-90'
				
		end
		,Value = sum(Приведенный)
		from risk.collection_dailyplans t
		where t.Product in ('PTS') 
		and eomonth(t.rep_dt_month) = EOMONTH(@today)
		and t.bucket_from in ('(2)_1_30', '(3)_31_60', '(4)_61_90')
		group by  case 
					when bucket_from in ('(2)_1_30') and bucket_to in ('(1)_0')			then '1-30'
					when bucket_from in ('(3)_31_60') and bucket_to in ('(1)_0', '(2)_1_30' ) then '31-60'
					when bucket_from in ('(4)_61_90') and bucket_to in ('(1)_0', '(2)_1_30', '(3)_31_60' ) then '61-90'
			end WITH ROLLUP
		) t
	
	)
	
	
	, cte_fact as (

	 select * from 
		(select 
		[1-30]			= isnull(cast(t1_1_7_fact_rr_to_end_of_month as money),0) --1-30 [Sum(t2_1_3)]
		,[31-60]		= isnull(cast(t1_2_7_fact_rr_to_end_of_month as money),0) --[Sum(t2_2_3)]
		,[61-90]		= isnull(cast(t1_3_7_fact_rr_to_end_of_month as money),0)-- [Sum(t2_3_3)]
		,[1-90]	= 
			  isnull(cast(t1_1_7_fact_rr_to_end_of_month as money),0) 
			+ isnull(cast(t1_2_7_fact_rr_to_end_of_month as money),0)
			+ isnull(cast(t1_3_7_fact_rr_to_end_of_month as money),0)
	from dbo.dm_dashboard_Collection_v02_new_save_balance
	) t
	UNPIVOT   
		(Value FOR Стадия 
			IN   ([1-30], [31-60], [61-90],[1-90])) 
			as unpvt
	)
	select 
		dt = @today
		,metricName
		,fact
		,[plan]
		,[%completionPlan] = fact / nullif([plan], 0)
		,forecast
		,[%completionForecast] = forecast/ nullif( [plan], 0)
		,sortOrder
	from (
		select  
			
			metricName = t_metricName.Стадия
			,fact		= fact.Value
			,[plan]		= [plan].Value
		
			,forecast = (fact.Value * @dayInMonth)
				/ cast(day(@today) as smallmoney)
				--[Прогноз (млн.руб.)] c * дней в месяце / дата отчета
			,sortOrder = t_metricName.sortOrder
			from ( 
		values 
			 ('1-30', 1)
			,('31-60', 2)
			,('61-90', 3)
			,('1-90', 4)
		) t_metricName	(Стадия, sortOrder)
		left join cte_ReducedBalance_plan [plan] on [plan].Стадия = t_metricName.Стадия
		left join cte_fact fact on fact.Стадия = t_metricName.Стадия
	) t
	order by sortOrder
end try
begin catch
	;throw
end catch

end

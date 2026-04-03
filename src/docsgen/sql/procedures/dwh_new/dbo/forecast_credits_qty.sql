create procedure forecast_credits_qty

as
begin
if OBJECT_ID('tempdb..#all_approved') is not NULL  drop table #all_approved
select Q.request_id, cast (Q.stage_time as date) as approve_date
into #all_approved
from  ( select a.request_id, a.[status], stage_time, row_number() over ( partition by  request_id order by stage_time) as ord 
		from requests_history a ) Q
			left join 	(select a.request_id, a.[status], stage_time, row_number() over ( partition by  request_id order by stage_time  ) as ord
						 from requests_history a ) W
			on Q.request_id = W.request_id
Where Q.[status] = 8
	and W.[status] = 9
	and W.ord - Q.ord = 1  


if OBJECT_ID('tempdb..#data_main') is not NULL  drop table #data_main 
select  a.id, cast(a.request_date as date) as app_date, concat(a.request_year ,'_', a.request_month) as period
	, case when return_type = 'Первичный' then 'первичный' else 'не первичный' end as client_gr
	, case when  d.[name] like '%ВМ №%' then 'ВМ' else 'other' end as POS_name_gr
	, case when d.[name] like '%ВМ №%' then 'ВМ'
		when return_type = 'Первичный' then 'первичный' 
		else 'не первичный' end as [group]
	, c.approve_date
	,  cast(b.credit_date as date) as financed_date
	,  cast(b.[start_date] as date) as [start_date]
	, case when b.credit_date is not NULL  then datediff(d, c.approve_date, b.credit_date) end as delta_financed_approve
	, case when b.[start_date] is not NULL  then datediff(d,c.approve_date,  b.[start_date]) end as delta_start_approve
into #data_main
from tmp_v_requests a left join tmp_v_credits b
					  on a.id = b.request_id
							join #all_approved c 
							on a.id= c.request_id
									left join v_points_of_sale d
									on a.point_of_sale = d.id
where 1=1 


if OBJECT_ID('tempdb..#koeff_new') is not NULL  drop table #koeff_new
select actual_date 
	, cast( sum (case when delta_start_approve = 0 then 1 else 0 end) as real) / count(*) as fin_new_0
	, cast( sum (case when delta_start_approve = 1 then 1 else 0 end) as real) / count(*) as fin_new_1
	, cast( sum (case when delta_start_approve = 2 then 1 else 0 end) as real) / count(*) as fin_new_2
	, cast( sum (case when delta_start_approve = 3 then 1 else 0 end) as real) / count(*) as fin_new_3
	, cast( sum (case when delta_start_approve = 4 then 1 else 0 end) as real) / count(*) as fin_new_4
	, cast( sum (case when delta_start_approve = 5 then 1 else 0 end) as real) / count(*) as fin_new_5
into #koeff_new
from  (Select distinct [start_date] as actual_date from #data_main where financed_date is not NULL) Q
		left join #data_main
		on Q.actual_date >= dateadd(day,6,approve_date)  
		and Q.actual_date < dateadd(day,96,approve_date) 
		and #data_main.[group] = 'первичный'  
Where 1=1 
group by  actual_date


if OBJECT_ID('tempdb..#koeff_repeat') is not NULL  drop table  #koeff_repeat
select actual_date 
	, cast( sum (case when delta_start_approve = 0 then 1 else 0 end) as real) / count(*) as fin_repeat_0
	, cast( sum (case when delta_start_approve = 1 then 1 else 0 end) as real) / count(*) as fin_repeat_1
	, cast( sum (case when delta_start_approve = 2 then 1 else 0 end) as real) / count(*) as fin_repeat_2
	, cast( sum (case when delta_start_approve = 3 then 1 else 0 end) as real) / count(*) as fin_repeat_3
	, cast( sum (case when delta_start_approve = 4 then 1 else 0 end) as real) / count(*) as fin_repeat_4
	, cast( sum (case when delta_start_approve = 5 then 1 else 0 end) as real) / count(*) as fin_repeat_5
into #koeff_repeat
from  (Select distinct [start_date] as actual_date from #data_main where financed_date is not NULL) Q
		left join #data_main
		on Q.actual_date >= dateadd(day,6,approve_date)  
		and Q.actual_date < dateadd(day,96,approve_date) 
		and #data_main.[group] = 'не первичный'  
Where 1=1 
group by  actual_date


if OBJECT_ID('tempdb..#koeff_BM') is not NULL  drop table #koeff_BM
select actual_date 
	, cast( sum (case when delta_start_approve = 0 then 1 else 0 end) as real) / count(*) as fin_BM_0
	, cast( sum (case when delta_start_approve = 1 then 1 else 0 end) as real) / count(*) as fin_BM_1
	, cast( sum (case when delta_start_approve = 2 then 1 else 0 end) as real) / count(*) as fin_BM_2
	, cast( sum (case when delta_start_approve = 3 then 1 else 0 end) as real) / count(*) as fin_BM_3
	, cast( sum (case when delta_start_approve = 4 then 1 else 0 end) as real) / count(*) as fin_BM_4
	, cast( sum (case when delta_start_approve = 5 then 1 else 0 end) as real) / count(*) as fin_BM_5
into #koeff_BM
from  (Select distinct [start_date] as actual_date from #data_main where financed_date is not NULL) Q
		left join #data_main
		on Q.actual_date >= dateadd(day,6,approve_date)  
		and Q.actual_date < dateadd(day,96,approve_date) 
		and #data_main.[group] = 'ВМ'  
Where 1=1 
group by  actual_date

if OBJECT_ID('dbo.forecast_credits') is not NULL  drop table dbo.forecast_credits
select  M.[date]
	, num_financed_fact as fact
	, isnull(num_approve_BM_0,0)*fin_BM_0 + isnull(num_approve_BM_1,0)*fin_BM_1 + isnull(num_approve_BM_2,0)*fin_BM_2 + isnull(num_approve_BM_3,0)*fin_BM_3 
	+ isnull(num_approve_BM_4,0)*fin_BM_4 + isnull(num_approve_BM_5,0)*fin_BM_5 + isnull(num_approve_new_0,0)*fin_new_0 + isnull(num_approve_new_1,0)*fin_new_1 
	+ isnull(num_approve_new_2,0)*fin_new_2 + isnull(num_approve_new_3,0)*fin_new_3 + isnull(num_approve_new_4,0)*fin_new_4 + isnull(num_approve_new_5,0)*fin_new_5 
	+ isnull(num_approve_repeat_0,0)*fin_repeat_0 + isnull(num_approve_repeat_1,0)*fin_repeat_1 + isnull(num_approve_repeat_2,0)*fin_repeat_2 
	+ isnull(num_approve_repeat_3,0)*fin_repeat_3 + isnull(num_approve_repeat_4,0)*fin_repeat_4 + isnull(num_approve_repeat_5,0)*fin_repeat_5
			as forecast
into dbo.forecast_credits
from 	( Select [start_date] as [date], count(*) as num_financed_fact 
		 from #data_main
		 where [start_date] is not NULL
		 group by [start_date] ) M
			   left join 	(select approve_date
						, sum(case when [group] = 'ВМ' then 1 else 0 end ) as num_approve_BM_0
						, sum(case when [group] = 'не первичный' then 1 else 0 end ) as num_approve_repeat_0
						, sum(case when [group] = 'первичный' then 1 else 0 end ) as num_approve_new_0
				from #data_main
				group by approve_date ) A 
				on M.[date] = A.approve_date 
						left join (select approve_date 
								, sum(case when [group] = 'ВМ' then 1 else 0 end ) as num_approve_BM_1
								, sum(case when [group] = 'не первичный' then 1 else 0 end ) as num_approve_repeat_1
								, sum(case when [group] = 'первичный' then 1 else 0 end ) as num_approve_new_1
						from #data_main
						group by approve_date ) B 
						on M.[date] = dateadd(day,1,B.approve_date)
								left join (select approve_date 
										, sum(case when [group] = 'ВМ' then 1 else 0 end ) as num_approve_BM_2
										, sum(case when [group] = 'не первичный' then 1 else 0 end ) as num_approve_repeat_2
										, sum(case when [group] = 'первичный' then 1 else 0 end ) as num_approve_new_2
								from #data_main
								group by approve_date ) C
								on M.[date] = dateadd(day,2,C.approve_date)
										left join (select approve_date 
												, sum(case when [group] = 'ВМ' then 1 else 0 end ) as num_approve_BM_3
												, sum(case when [group] = 'не первичный' then 1 else 0 end ) as num_approve_repeat_3
												, sum(case when [group] = 'первичный' then 1 else 0 end ) as num_approve_new_3
										from #data_main
										group by approve_date ) D
										on M.[date] = dateadd(day,3,D.approve_date)
												left join (select approve_date
														, sum(case when [group] = 'ВМ' then 1 else 0 end ) as num_approve_BM_4
														, sum(case when [group] = 'не первичный' then 1 else 0 end ) as num_approve_repeat_4
														, sum(case when [group] = 'первичный' then 1 else 0 end ) as num_approve_new_4
												from #data_main
												group by approve_date ) E
												on M.[date] = dateadd(day,4,E.approve_date)
														left join (select approve_date 
																, sum(case when [group] = 'ВМ' then 1 else 0 end ) as num_approve_BM_5
																, sum(case when [group] = 'не первичный' then 1 else 0 end ) as num_approve_repeat_5
																, sum(case when [group] = 'первичный' then 1 else 0 end ) as num_approve_new_5
														from #data_main
														group by approve_date ) F
														on M.[date] = dateadd(day,5,F.approve_date)
																left join #koeff_BM on M.[date] = #koeff_BM.actual_date
																left join #koeff_new on M.[date] = #koeff_new.actual_date
																left join #koeff_repeat on M.[date] = #koeff_repeat.actual_date
Where F.approve_date is not NULL 
order by 1 
end




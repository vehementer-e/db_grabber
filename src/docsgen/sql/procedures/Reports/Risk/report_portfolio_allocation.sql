create procedure [Risk].[report_portfolio_allocation]
as
begin

DECLARE @Date_rep date = '20240801';
SET XACT_ABORT  ON;
begin try


drop table if exists #allocation;
with smp as (select -- distinct 
						person_id
						,request_date
						,rn
						,process
						,source
						,cache_flg
						,validReport_flg
						,stage
						,is_installment
				--		,count(*) as cnt_requests
					from 
						(select 
								person_id
								,process
								,source
								,cache_flg
								,validReport_flg
								,stage
								,request_date
								,row_number() over(partition by person_id, SOURCE, stage order by request_date) as rn
							from stg._loginom.Original_response with (nolock) 
							where request_date >= @Date_rep
								and process = 'Origination'
								and source in ('equifax'
												,'JuicyScore'
												,'nbch'
												,'nbch PV2 score'
												,'okbscore'
												,'DBrain'
												,'fincard'
												,'KbkiEqx'
											  )
								and (
									person_id<>'19061300000088' 
									and person_id <> '19061300000089' 
									and person_id <> '20101300041806' 
									and person_id <> '21011900071506' 
									and person_id <> '21011900071507'
									)
								and username = 'service'
							) r 
						left join (select distinct 
											is_installment
											,number 
										from stg._loginom.application with (nolock) 
										where stage_date >= dateadd(dayofyear,-10, @Date_rep)
											and stage = 'Call 1') a	
							on a.number = r.person_id
							and r.rn = 1
					where rn = 1
				)


select format(request_date, 'yyyy-MM') as period_
		,source
		,sum(case when is_installment = 1 then cast(requests_valid_nocache as float) else cast(0 as float) end)
			/sum(cast(requests_valid_nocache as float))
			as _persentage_of_BEZZALOG
					,sum(case when is_installment = 0 then cast(requests_valid_nocache as float) else cast(0 as float) end)
			/sum(cast(requests_valid_nocache as float))
			as _persentage_of_PTS
	into #allocation
	from (
			select request_date
					,source
					,is_installment
					,sum(case when stage = 'Call 1' and (cache_flg is null or cache_flg = 0) and validReport_flg = 1 then 1 else 0 end) 
						+sum(case when stage = 'Call 1.2' and (cache_flg is null or cache_flg = 0) and validReport_flg = 1 then 1 else 0 end) 
						+sum(case when stage = 'Call 2' and (cache_flg is null or cache_flg = 0) and validReport_flg = 1 then 1 else 0 end)
						+sum(case when stage = 'Call 5' and (cache_flg is null or cache_flg = 0) and validReport_flg = 1 then 1 else 0 end) 
						as requests_valid_nocache
				from smp
				where request_date < cast(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) as date)
				group by request_date
					,source
					,is_installment
--				order by 2,3,1

		) as a
	group by format(request_date, 'yyyy-MM')
		,source;


		begin tran
truncate table dwh2.risk.v_portfolio_allocation;

insert into dwh2.risk.v_portfolio_allocation
(
 [period_]
, [source]
, [_persentage_of_BEZZALOG]
, [_persentage_of_PTS]
)
select  
 [period_]
, [source]
, [_persentage_of_BEZZALOG]
, [_persentage_of_PTS]
from  #allocation


commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end

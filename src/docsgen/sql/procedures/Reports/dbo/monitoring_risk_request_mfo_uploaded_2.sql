--exec [dbo].[monitoring_cmr_loan_canceled]

CREATE procedure [dbo].[monitoring_risk_request_mfo_uploaded_2]
as
begin


set nocount on

drop table if exists #staging_requests
select [external_id]
       ,cast([request_date] as date) [request_date]
      --,[amount]
      --,[initial_amount]
      --,[product] --,[term] --,[region] --,[point_of_sale] --,[prelending]
      --,[passport_number] --,[vin] --,[leaving_address] --,[chanel] --,[income]
      --,[LCRM_ID] --,[external_link] --,[method_of_issuing] --,[market_price]
      --,[valuation_price] --,[recommend_price] --,[risk_criteria] --,[risk_visa]
into #staging_requests
from [dwh_new].[staging].[requests]

--select top(1000) * from [dwh_new].[staging].[requests] order by 2 desc

drop table if exists #dbo_requests
select cast([request_date] as date) [request_date]
      ,[external_id]
into #dbo_requests
from [dwh_new].[dbo].[requests]


drop table if exists #_1cMFO_requests
select [Номер] 
	   ,cast(dateadd(year ,-2000 ,cast([Дата] as datetime2)) as date) [Дата]
into #_1cMFO_requests
from Stg.[_1cMFO].[Документ_ГП_Заявка]
where cast([Дата] as date) >='40160301' and cast([Дата] as date) < getdate()

drop table if exists #div_requests
select case when [Дата] is null then [request_date] else [Дата] end dt
	   ,t.* 
into #div_requests
from
(
select [Дата] ,qty_mfo ,[request_date] ,qty_stg ,(qty_mfo - isnull(qty_stg,0)) delta
from (select [request_date] ,count(distinct [external_id]) qty_stg from #staging_requests group by [request_date]) s
inner join (select [Дата] ,count(distinct [Номер]) qty_mfo from #_1cMFO_requests group by [Дата]) m on s.[request_date] = m.[Дата]
) t
where t.delta <> 0
order by 1 desc

drop table if exists #num_requests
select * into #num_requests from
(
select case when [Дата] is null then [request_date] else [Дата] end dt
	   ,[Дата] ,[Номер] ,[request_date] ,[external_id]
from (select [request_date] ,[external_id] from #staging_requests where [request_date] >='20200501') s
full outer join (select [Дата] ,[Номер] from #_1cMFO_requests  where [Дата] >='20200501') m on s.[external_id] = m.[Номер]
) t
where [external_id] is null or [Номер] is null


/*
select 
	   [dt]
	   ,[Номер]
	   ,[external_id] 
from #num_requests

		order by [dt] desc
*/
if isnull((select count(*) from #div_requests where delta > 0 and ([Дата] >='20200501' or [request_date] >= '20200501')),0)<>0

	begin   
		--print 'Работает верно'
		 DECLARE @tableHTML  NVARCHAR(MAX) ;   

		 		SET @tableHTML =  
			N'<H1>Расхождение в кол-ве заявок между МФО и ДВХ </H1>' +  
			N'<table border="1">' +  
			N'<tr><th>дата</th>' +  
			N'<th>Номер МФО</th>' +
			N'<th>Номер ДВХ</th></tr>' +			
			CAST ( ( SELECT 
							td = [dt], '',  
							td = [Номер], '',  
							td = [external_id] 

					  from #num_requests

		order by [dt] desc
 
					  FOR XML PATH('tr'), TYPE   
			) AS NVARCHAR(MAX) ) +  
			N'</table>' ;  

/*
		SET @tableHTML =  
			N'<H1>Расхождение в кол-ве заявок между МФО и ДВХ </H1>' +  
			N'<table border="1">' +  
			N'<tr><th>дата</th>' +  
			N'<th>Кол-во МФО</th>' +
			N'<th>Кол-во ДВХ</th>' +
			N'<th>Расхождение(МФО-ДВХ)</th></tr>' +  
			CAST ( ( SELECT 
							td = [dt], '',  
							td = [qty_mfo], '',  
							td = [qty_stg], '',  
                  
							td = delta 
					  from #div_requests

		order by [dt] desc
 
					  FOR XML PATH('tr'), TYPE   
			) AS NVARCHAR(MAX) ) +  
			N'</table>' ;  
 */ 
		  select @tableHTML


		EXEC msdb.dbo.sp_send_dbmail @recipients= 'dwh112@carmoney.ru;'
			, @subject = 'Риски. Расхождение в кол-ве заявок между МФО и ДВХ' 
			, @body = @tableHTML 
			, @body_format = 'HTML' ;  

	end



end

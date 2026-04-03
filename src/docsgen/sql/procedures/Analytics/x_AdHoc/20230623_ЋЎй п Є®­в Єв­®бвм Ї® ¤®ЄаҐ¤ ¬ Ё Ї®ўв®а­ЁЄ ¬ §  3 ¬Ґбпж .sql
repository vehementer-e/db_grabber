create proc [x_AdHoc].[20230623_Общая контактность по докредам и повторникам за 3 месяца]
as
begin



drop table if exists 	  #t1

select distinct mobile_fin, [Тип предложения] into #t1 from reports.dbo.dm_Report_DIP_to_Naumen
where [Дата среза]>=getdate()-91 --and [Тип предложения]='Повторный заём'



select [Тип предложения], count(*) cnt from 	#t1
				  group by [Тип предложения]
				  --order by 

--	 drop table if exists 	 #t2
--SELECT project_id
--	,count(DISTINCT client_number) client_number
--INTO #t2
--FROM reports.dbo.dm_report_DIP_detail_outbound_sessions
--WHERE LOGIN IS NOT NULL
--	AND attempt_start >= getdate() - 91
--GROUP BY project_id
--	--order by 


	
	 drop table if exists 	 #t2
SELECT distinct client_number
 			  into #t2
FROM reports.dbo.dm_report_DIP_detail_outbound_sessions
 WHERE  LOGIN IS NOT NULL	 AND
	 
	attempt_start >= getdate() - 91
 
	--order by 




		 select isnull([Тип предложения], 'Total') [Тип предложения], count(distinct mobile_fin) База,count(distinct client_number) / (count(distinct mobile_fin)+0.0) Конт  from (
	select * from  #t1	
a
left join #t2 b on a.mobile_fin=b.client_number
		 )	 x

		 group by 	[Тип предложения]
		 with rollup
		 --order by 



end
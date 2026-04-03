






CREATE PROCEDURE [finAnalytics].[repLogs]
	@repDate date
	
AS
BEGIN

drop table if exists #mPrc

select
prc
,rn = ROW_NUMBER() over (order by [reptime])

into #mPrc

FROM [dwh2].[finAnalytics].[SYS_prcLog]
where cast([reptime] as date) = @repdate
and [mainPrc] = [prc]
and step = 0


select
a.rn
,l1.reptime
,l1.workTimeMinute
,l1.prc
,l1.mainPrc
,[step] = case when l1.step = 0 then 'Старт' else 'Финиш' end
,[isError] = case when l1.isError = 0 then 'Нет' else 'Да' end
,l1.mem
,l1.isSucces
,l1.isMain
from #mPrc a
left join (
SELECT 
[reptime]
,[workTimeMinute] = case 
					when step = 0 then
						DATEDIFF(second,[reptime],LEAD([reptime]) over (Partition by [prc] order by [reptime])) / 60
					else null end
      ,[prc]
      ,[step]
      ,[mainPrc]
      ,[isError]
      ,[mem]
	  ,[isMain] = case when [mainPrc] = [prc] then 1 else 0 end
	  ,[isSucces] = case 
					when step = 0 then
						LEAD([mem]) over (Partition by [prc] order by [reptime])
					else null end
FROM [dwh2].[finAnalytics].[SYS_prcLog]
where cast([reptime] as date) = @repdate
) l1 on a.prc = l1.mainPrc

order by a.rn,l1.reptime

END

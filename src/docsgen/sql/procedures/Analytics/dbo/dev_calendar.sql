

CREATE     proc [dbo].[_calendar_]

as

begin


with fa1 as(

select format(cast([Заем выдан] as date), 'yyyy-MM-dd') as [Дата Выдачи]
      ,format(cast([Заем выдан] as date), 'MM-dd') as [День]
      ,[Выданная сумма]
from reports.dbo.dm_factor_analysis_001
where isInstallment = 0 and [Заем выдан] is not null

)

SELECT [Дата Выдачи]
      ,[Неделя]
	  ,DATEPART(ww,[Дата Выдачи]) as [Номер недели]
	  ,CASE
          WHEN День = '01-01' 
		  or День = '01-02'
		  or День = '01-02'
		  or День = '01-03'
		  or День = '01-04'
		  or День = '01-05'
		  or День = '01-06'
		  or День = '01-07'
		  or День = '01-08'
		  or День = '02-23'
		  or День = '03-08'
		  or День = '05-01'
		  or День = '05-09'
		  or День = '06-12'
		  or День = '11-04'
		  THEN 1
          ELSE 0
	   END as [Признак праздник]
	  ,[Выданная сумма]
  FROM fa1
  left join [Analytics].[dbo].[v_Calendar] v on fa1.[Дата Выдачи] = v.Дата



end
--exec [dbo].[monitoring_cmr_loan_canceled]

CREATE procedure [dbo].[monitoring_cmr_loan_canceled]
as
begin


set nocount on

  drop table if exists #loan_status
select 
	  d.[Период]
	  ,d.[Договор] 
	  ,sd.[Код] 
	  ,sd.[Точка]
	  ,o.[Код] [КодТочки] 
	  ,o.[Наименование]  [НаимТочки] 
	  ,d.[Статус]
	  ,s.[Наименование] [НаимСтатус]
into #loan_status
from (select 
			[Период] 
			,[Договор] 
			,[Статус] 
	  from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] 
	  --where [Статус] = 0x80E400155D64100111E7C5361FF4393D -- договор аннулирован
			--and [Период] >= dateadd(month,-2,@dFrom)
	  ) d   
left join [Stg].[_1cCMR].[Справочник_Договоры] sd  with (nolock) on sd.ссылка=d.[Договор]
left join [Stg].[_1cCRM].[Справочник_Офисы] o  with (nolock) on o.ссылка=sd.[Точка]
left join [Stg].[_1cCMR].[Справочник_СтатусыДоговоров] s with (nolock) on s.ссылка=d.[Статус]


  drop table if exists #loan_different_status
select *
into #loan_different_status
from
(
select --*
		[Договор]
		,[Код] as [Номер] 
		,[КодТочки] 
		,[НаимТочки] 

		,lead([Период]) over (partition by [Договор] order by [Период] desc) as [Период_Пред]
		,lead([Статус]) over (partition by [Договор] order by [Период] desc) as [Статус_Пред]
		,lead([НаимСтатус]) over (partition by [Договор] order by [Период] desc) as [НаимСтатус_Пред]

		,[Период] as [Период_Исх]
		,[Статус] as [Статус_Исх]
		,[НаимСтатус] as [НаимСтатус_Исх]

		,lag([Период]) over (partition by [Договор] order by [Период] desc) as [Период_След]
		,lag([Статус]) over (partition by [Договор] order by [Период] desc) as [Статус_След]
		,lag([НаимСтатус]) over (partition by [Договор] order by [Период] desc) as lastStatusName /*[НаимСтатус_След]*/

from #loan_status --#loan_status
) t
where [Статус_Исх] = 0x80E400155D64100111E7C5361FF4393D/*-- договор аннулирован*/ and [Статус_След] <> 0x80E400155D64100111E7C5361FF4393D
		and not [Статус_След] is null
order by 2 desc


if isnull((select count(*) from #loan_different_status),0)<>0

	begin   
		--print 'Работает верно'
		 DECLARE @tableHTML  NVARCHAR(MAX) ;   

		SET @tableHTML =  
			N'<H1>Договора, имеющие иной статус после аннулирования </H1>' +  
			N'<table border="1">' +  
			N'<tr><th>дата</th>' +  
			N'<th>Номер</th>' +  
			N'<th>Последний статус</th></tr>' +  
			CAST ( ( SELECT 
							td = [Период_След], '',  
							td = [Номер], '',  
                  
							td = lastStatusName 
					  from #loan_different_status

		order by [Период_След]
 
					  FOR XML PATH('tr'), TYPE   
			) AS NVARCHAR(MAX) ) +  
			N'</table>' ;  
  
		  select @tableHTML


		EXEC msdb.dbo.sp_send_dbmail @recipients= 'kurdin@carmoney.ru;' --'kosolapov@carmoney.ru; finko@carmoney.ru; dwh112@carmoney.ru'  --; 
			, @profile_name = 'Default' 
			, @subject = 'Договора, имеющие иной статус после аннулирования ' 
			, @body = @tableHTML 
			, @body_format = 'HTML' ;  

	end



end

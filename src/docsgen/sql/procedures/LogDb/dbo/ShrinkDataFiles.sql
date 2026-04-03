CREATE     procedure [dbo].[ShrinkDataFiles]
as
begin
	declare @date datetime = dateadd(hh,-3, cast(cast(getdate() as date) as datetime))
		DECLARE @tableHTML NVARCHAR(MAX) ;
		SET @tableHTML =

		N'<H1>Результат ShrinkDataFiles на c2-vsr-dwh2</H1>' +
		N'<table border="1">' +
		N'<tr><th>DBname</th><th>DBFileName</th><th>Size</th><th>FreeSpace</th><th>ResultSpace</th><th>FinishTime</th><th>DiffSpace</th></tr>' +
		CAST ( ( SELECT td = DBname                  
		,               ''                                      
		,               td = DBFileName                     
		,               ''                                      
		,               td = Size                         
		,               ''                                      
		,               td = FreeSpace
		,				''                                  
		,               td = ResultSpace
		,               ''  
		,				td = FinishTime 
		,               ''                                      
		,               td = DiffSpace                              

		from LogDb.dbo.Shrink_Data_Files_Results
		where FinishTime > @date
		order by DBname, DBFileName
		FOR XML PATH('tr'), TYPE
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;

		      EXEC msdb.dbo.sp_send_dbmail @recipients   = 'dwh112@carmoney.ru'
		      ,                            @subject      = 'Результат ShrinkDataFiles на c2-vsr-dwh2'
		      ,                            @body         = @tableHTML
		      ,                            @body_format  = 'HTML' ;
end	

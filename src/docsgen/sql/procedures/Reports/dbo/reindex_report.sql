--exec reports.dbo.reindex_report
CREATE   procedure [dbo].[reindex_report]
as
begin


set nocount on


DECLARE @tableHTML  NVARCHAR(MAX) = N'' ;  
  


SET @tableHTML =  
    N'<H1>Реорганизация индекса : </H1>' +  
    N'<table border="1">' +  
    N'<tr>' +
	N'<th>База данных</th>'+
	N'<th>SchemaName</th>' +  
    N'<th>ObjectName</th>' +  
	N'<th>IndexName</th>' +  
	N'<th>PartitionNumber</th>' +
	N'<th>StartTime</th>' +
	N'<th>EndTime</th>' +
	N'<th>ErrorNumber</th>' +
	N'<th>ErrorMessage</th>' +
	N'<th>EndMaintenanceTime</th>' +  
    N'</tr>' +  
    CAST ( ( SELECT td = DatabaseName,       '',  
                    td = SchemaName, '',  
                    td = ObjectName , '',  
                    td = IndexName , '',                      
                    td = PartitionNumber , '',
					td = StartTime , '',
					td = EndTime , '',
					td = isnull(nullif(ErrorNumber,0),'') , '',
					td = isnull(ErrorMessage, '') , '',
					td = EndMaintenanceTime , ''
              from [Reports].[dbo].[ReindexLog]

order by DatabaseName
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML

  --select format(rate_bu_rnd,'0.000000') from #t


  begin
		EXEC msdb.dbo.sp_send_dbmail @recipients='dwh112@carmoney.ru',  --; Krivotulov@carmoney.ru
			@profile_name = 'Default',  
			@subject = 'Реиндексация',  
			@body = @tableHTML,  
			@body_format = 'HTML' ;  

  end

end



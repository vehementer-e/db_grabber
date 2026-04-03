

create   procedure etl.CheckDoubles
as
begin
  --dwh-1030
  declare @tableHTML nvarchar(max)

--
-- tmp_v_requests
--
  drop table if exists #tmp_v_requests_dq

  select external_id
       , qty 
    into #tmp_v_requests_dq
    from ( 
          select external_id
               , count(*) qty 
            from tmp_v_requests 
           group by external_id
          ) A 
    where qty > 1




  SET @tableHTML =  
    N'<H1>tmp_v_requests </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>external_id</th>' +  
    N'<th>qty</th></tr>' +  
   
    CAST ( ( SELECT 
                    td = external_id, '',  
                    td = qty 
              from #tmp_v_requests_dq

order by external_id
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML


EXEC msdb.dbo.sp_send_dbmail @recipients='dwh_new_alerts-aaaadm4wd26mjnvvdspshsbvvu@carmoney.slack.com',

    @profile_name = 'Default',  
    @subject = 'Дубли в таблице tmp_v_requests   ',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  


--
-- tmp_v_credits
--
  drop table if exists #tmp_v_credits_dq

  select external_id
       , qty 
    into #tmp_v_credits_dq
    from ( 
          select external_id
               , count(*) qty 
            from tmp_v_credits 
           group by external_id
          ) A 
    where qty > 1




  SET @tableHTML =  
    N'<H1>tmp_v_credits </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>external_id</th>' +  
    N'<th>qty</th></tr>' +  
   
    CAST ( ( SELECT 
                    td = external_id, '',  
                    td = qty 
              from #tmp_v_credits_dq

order by external_id
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML


EXEC msdb.dbo.sp_send_dbmail @recipients='dwh_new_alerts-aaaadm4wd26mjnvvdspshsbvvu@carmoney.slack.com',

    @profile_name = 'Default',  
    @subject = 'Дубли в таблице tmp_v_credits   ',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  



--
-- stat_v_balance2
--

  drop table if exists #stat_v_balance2_dq

  select external_id
       , cdate
       , qty 
    into #stat_v_balance2_dq
    from ( 
          select external_id
               , cdate
               , count(*) qty 
           from stat_v_balance2 
          group by external_id
              , cdate
          
          ) A 
    where qty > 1




  SET @tableHTML =  
    N'<H1>tmp_v_credits </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>external_id</th>' +  
     N'<th>cdate</th>'+
    N'<th>qty</th></tr>' +  
   
    CAST ( ( SELECT 
                    td = external_id, '',  
                    td = cdate, '',  
                    td = qty 
              from #stat_v_balance2_dq

order by external_id,cdate
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML


EXEC msdb.dbo.sp_send_dbmail @recipients='dwh_new_alerts-aaaadm4wd26mjnvvdspshsbvvu@carmoney.slack.com',

    @profile_name = 'Default',  
    @subject = 'Дубли в таблице stat_v_balance2   ',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  




--select * from( select external_id,cdate, count(*) qty from stat_v_balance2 group by external_id,cdate) A where qty > 1

end

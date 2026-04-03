CREATE proc notify_birsCash
as
begin




DROP TABLE IF EXISTS #T1 
SELECT 
      -- [InstanceName]
      --,
	  [ItemPath]
      ,[TimeStart]
      ,[TimeEnd]
      ,[Status]
	 INTO #T1
  FROM  birs_ExecutionLog3_7days
  where		[isbirs]=1		and itemaction='DataRefresh'
  --order by status


DROP TABLE IF EXISTS #T2

  SELECT  
       a.[ItemPath]
      ,max(a.[TimeStart])  [TimeStart]
      ,max(a.[TimeEnd])	    [TimeEnd]
      ,max(a.[Status] )	    [Status]
	  ,count(*) [Quantity]
	  ,DATEDIFF(dd, min(a.[TimeStart]), max(a.[TimeEnd]))+1 [Days]
 	  ,'insert into notify_birsCashIgnoring select '''+ a.[ItemPath]+''''  unsubscribe
	  
	  into #t2
	  FROM #T1 A
  LEFT JOIN   #T1 B ON A.[ItemPath]=B.[ItemPath] AND B.STATUS='rsSuccess' AND B.TIMEEND>A.timeend
  LEFT JOIN   notify_birsCashIgnoring c ON A.[ItemPath] collate Cyrillic_General_CI_AS=c.[ItemPath]
  WHERE B.TIMEEND IS NULL AND 
  a.STATUS<>N'rsSuccess'
  and c.[ItemPath]  like '%' + 'SalesDepartment' + '%'
  group by a.[ItemPath]

  --create table _monitoring.bi_failed_cache_updates_paths_to_ignore ([ItemPath] nvarchar(max))

   
 begin

 declare @html  nvarchar(max)
 exec spQueryToHtmlTable 'select * from #t2' , default,  @html output	   
 if @html is not null

exec msdb.dbo.sp_send_dbmail   
    @profile_name = null,  
    @recipients = 'p.ilin@techmoney.ru',  
    @body = @html,  
    @body_format = 'html',  
    @subject = 'MONITORING_BIRS_FAIL'	

end





end

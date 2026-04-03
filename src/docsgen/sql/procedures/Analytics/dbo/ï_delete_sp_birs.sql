CREATE proc birs
@path nvarchar(max) 
as
begin


select e.Path, a.ScheduleID
,

'exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '''+cast(a.ScheduleID as nvarchar(100))+'''' code
, s.Description
FROM 
[C2-VSR-BIRS].[ReportServer].[dbo].[ReportSchedule] a 
JOIN [C2-VSR-BIRS].[ReportServer].dbo.Catalog e ON a.ReportID = e.itemid
left join [C2-VSR-BIRS].[ReportServer].dbo.[Subscriptions] s on a.SubscriptionID=s.SubscriptionID
where path like '%'+@path+'%' 


end
	    
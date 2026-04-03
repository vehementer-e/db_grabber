

--exec dbo.Create_dm_report_use_app_mpHard null, null
CREATE procedure [dbo].[Create_dm_report_use_app_mpHard]
@from date = null
,@to date = null
as
begin
declare @dtFrom date = dateadd(day, 0, cast(getdate() as date))	
		, @dtTo date = dateadd(day, 0, cast(getdate() as date))	

if @from is null
begin
	set @from = @dtFrom
end

if @to is null
begin
	set @to = @dtTo
end

set @to = dateadd(day, 1, @to )


--select @from, @to
select 
	  u.login
	, AUDT.cnt as connects
	, RESULTS.cnt as communications
from [Stg].[_MPHARD].[app_instance]  ai
join [Stg].[_MPHARD].[users] u ON u.id = ai.[user_id]
left join (
		select aice.app_instance_id, count(aice.app_instance_id) cnt 
		from [Stg].[_MPHARD].app_instance_connection_event aice
		where dateadd(hour,3, aice.when_created) >= @from	
		AND dateadd(hour,3, aice.when_created) < @to	
		AND aice.type ='SYNC_COMPLETE'
		group by aice.app_instance_id) 
	AUDT
	ON AUDT.app_instance_id = ai.id
left join (
		select cr.author, count(*) cnt from [Stg].[_MPHARD].contact_result cr
		where dateadd(hour,3,cr.contact_date)>= @from		
		AND dateadd(hour,3,cr.contact_date) < @to		
		group by cr.author)
	RESULTS 
	on RESULTS.author = ai.[user_id]
order by  connects desc;
end
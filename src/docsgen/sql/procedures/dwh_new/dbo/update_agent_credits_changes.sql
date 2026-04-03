CREATE procedure [dbo].[update_agent_credits_changes]
as
begin
drop table if exists #t_current
select * 
into #t_current
from dbo.v_agent_credits
if OBJECT_ID('agent_credits_changes') is null
begin
	drop table [dbo].agent_credits_changes
	select top(0)*
	, getdate() as Inserted
	, cast(0 as bit) IsChanged
	, cast(null as datetime) DateChanged

	into dbo.agent_credits_changes
	from #t_current
end
--select * from #t_current
merge [dbo].agent_credits_changes t
using #t_current  s
	on s.external_id = t.external_id
	 and s.agent_name = t.agent_name
	 and s.reestr = t.reestr
	 and s.st_date = t.st_date
when matched 
	then update
	set DateChanged = getdate()
		,IsChanged = iif(isnull(t.end_date,'2000-01-01') != isnull(s.end_date, '2000-01-01'), 1, 0)
		,end_date = s.end_date

when not matched then insert ([external_id], [agent_name], [reestr], [st_date], [end_date], [Inserted], [IsChanged], [DateChanged])
	values([external_id], [agent_name], [reestr], [st_date], [end_date], getdate(), 1, getdate())
;
--

end
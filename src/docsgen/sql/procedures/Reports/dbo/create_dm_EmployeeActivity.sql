
CREATE   procedure dbo.create_dm_EmployeeActivity
as
begin

set nocount on

  drop table if exists #diapazon
;
  with hs as (
    select 0 h
  union all  
    select h+1 
   from hs
  where hs.h<23
  )
  select * into #diapazon from hs


--select * from #diapazon
  DELETE   FROM dbo.dm_EmployeeActivity WHERE dATE>CAST(GETDATE() AS DATE)
  insert into dbo.dm_EmployeeActivity
  select cast(date as date) Date
       , format(d.h,'0')+' - '+ format(d.h+1,'0') diapazon
       , e.Id	
       , e.FirstName+' '+e.MiddleName+' '+ e.LastName employee
       , c.id CommunicationId
    --into dbo.dm_EmployeeActivity
    from #diapazon  d
    left join stg._collection.Communications c on d.h=datepart(hour,date) and c.date>cast(getdate() as date)
    left join stg._collection.Employee e  on e.id=c.  EmployeeId
   where e.Id is not null
   --order by diapazon,e.Id

END

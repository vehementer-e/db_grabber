
---exec GetLeadsFromNaumen
CREATE   procedure [dbo].[GetLeadsFromNaumen]
as
begin

set nocount on

declare @projectuuid nvarchar(128)='corebo00000000000mm1tt1cr218d59k'

declare @tsql nvarchar(max)=''

truncate table reports.dbo.dm_LeadsFromNaumen

set @tsql='


SELECT creationdate
     , projectuuid
     , projecttitle
      ,operatortitle
   
   
     , statetitle
   
     , casecomment
   
     , phonenumbers
   
     , stringvalue1
     , stringvalue2
     , uploadeddate
     , modifieddate
     , timezone
FROM report_db.public.mv_call_case
where projectuuid='''''+@projectuuid+'''''
and removaldate is null
'
--select @tsql


set @tsql='
insert into reports.dbo.dm_LeadsFromNaumen
   
   select getdate() dt,t.* from openquery(naumen ,'''+@tsql+''') t
'

exec (@tsql)
   /*
insert into reports.dbo.dm_LeadsFromNaumen    with (tablockx)
    select getdate(),
     creationdate
     , projectuuid
     , projecttitle
      ,operatortitle
   
   
     , statetitle
   
     , casecomment
   
     , phonenumbers
   
     , stringvalue1
     , stringvalue2
     , uploadeddate
     , modifieddate
     , timezone
    
    
     from   reports.dbo.dm_NaumenCases with(nolock) where projectuuid= 'corebo00000000000mm1tt1cr218d59k'
    and [removed] =0
	and [ishistory]=0
     */
  --select * into reports.dbo.dm_LeadsFromNaumen from  dwh_new.dbo.DailyLeadsFromNaumen where 1=0

  end 
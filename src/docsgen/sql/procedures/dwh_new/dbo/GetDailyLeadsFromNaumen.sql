
---exec GetDailyLeadsFromNaumen
create   procedure GetDailyLeadsFromNaumen
as
begin

set nocount on

declare @projectuuid nvarchar(128)='corebo00000000000mm1tt1cr218d59k'

declare @tsql nvarchar(max)=''

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
order by creationdate
desc
'
--select @tsql


set @tsql='
insert into dwh_new.dbo.DailyLeadsFromNaumen
   
   select getdate() dt,t.* from openquery(naumen ,'''+@tsql+''') t
'

exec (@tsql)


  --select * from  dwh_new.dbo.DailyLeadsFromNaumen

  end 
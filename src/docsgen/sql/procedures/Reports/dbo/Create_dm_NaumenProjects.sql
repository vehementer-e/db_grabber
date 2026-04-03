-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 14.02.2020
-- Description:	dwh-382
-- exec [Create_dm_NaumenProjects]
-- =============================================
CREATE   PROCEDURE [dbo].[Create_dm_NaumenProjects]
	
AS
BEGIN
	--  18.03.2020 Изменили на openquery из-за несовместимости полей

	SET NOCOUNT ON;
/*
  select  distinct projectuuid,projecttitle,getdate() created
  into dbo.dm_NaumenProjects
  from  dbo.dm_NaumenCases 
  */
  /*
select distinct uuid,title from naumen.report_db.[public].[mv_outcoming_call_project]
 
select * from naumen.report_db.[public].[mv_incoming_call_project]
*/
/* 18/03/2020
  drop table if exists #new_ref
  
  
  select  distinct uuid=cast(uuid as nvarchar(100)),title=cast(title as nvarchar(100)),getdate() created into #new_ref
  from  naumen.report_db.[public].[mv_outcoming_call_project]
  union 
   select  distinct uuid=cast(uuid as nvarchar(100)),title=cast(title as nvarchar(100)),getdate() created 
  from  naumen.report_db.[public].[mv_incoming_call_project]



  delete from dbo.dm_NaumenProjects  where projectuuid in (select distinct projectuuid from  #new_ref)

  insert into dbo.dm_NaumenProjects
  select distinct uuid,title, created from #new_ref

  --select * from dbo.dm_NaumenProjects

  */


  
declare @tsql nvarchar(max)=''

drop table if exists #t

select top(0) 
* 
into #t
from dbo.dm_NaumenProjects
insert into #t
select distinct uuid=cast(uuid as nvarchar(100)), title=cast(title as nvarchar(100)) , getdate() created
from
(
	SELECT uuid,title
	FROM NaumenDbReport.dbo.mv_outcoming_call_project
	union
	SELECT uuid,title
	FROM NaumenDbReport.dbo.mv_incoming_call_project
)t

begin tran
  delete 
  --select *
  from dbo.dm_NaumenProjects  where projectuuid in (select distinct projectuuid from  #t)

  insert into dbo.dm_NaumenProjects
  select distinct projectuuid, projecttitle , getdate() created from  #t

commit tran

END

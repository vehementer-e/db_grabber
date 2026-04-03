-- exec [dbo].[Create_dm_visit_user_on_site]
CREATE  PROCEDURE  [dbo].[Create_dm_visit_user_on_site] 
AS
BEGIN
	SET NOCOUNT ON;

  declare  @dt date = cast(dateadd(day,0, getdate()) as date)

    -- Временная таблица для исключения блокировки в транзакции
 if object_id('tempdb.dbo.#t') is not null drop table #t
 ;
 with new_visit_user as
 (
 select -- top 100
 --[message_guid]
 --     ,[state]
 --     ,[publishTime]
 --     ,[TypeClientdatacreated]
 --     ,
	  [TypeClientdataguid] id

      --,[TypeClientdataupdated]
      --,[TypeVisit_adriverPostView]
	  ,[TypeVisit_guid] guid
      --,[TypeVisit_clickGoogleId] clickGoogleId
      --,[TypeVisit_clickYandexId] clickYandexId
      ,[TypeVisit_clientGoogleId] clientGoogleId
      ,[TypeVisit_clientYandexId] clientYandexId
      --,[TypeVisit_comagicVid]
      ,[TypeVisit_created] created
      
      --,[TypeVisit_jivoVid]
      --,[TypeVisit_language]
      ,[TypeVisit_page] page
      ,[TypeVisit_platform] platform
      ,[TypeVisit_referer] referer
      ,[TypeVisit_statCampaign] statCampaign
      ,[TypeVisit_statFrom] statFrom
      ,[TypeVisit_statInfo] statInfo
      ,[TypeVisit_statSource] statSource
      ,[TypeVisit_statSystem] statSystem
      ,[TypeVisit_statTerm] statTerm
      ,[TypeVisit_statType] statType
      ,[TypeVisit_updated] updated
      --,[TypeVisit_userAgent]
      --,[TypeVisit_client_type]
      --,[TypeVisit_client_ref_type]
      --,[TypeVisit_client_guid]
	  ,rn = ROW_NUMBER() over (partition by [TypeClientdataguid],[TypeVisit_guid] order by [TypeVisit_updated] desc)
 from  [Stg].[_LCRM].[lcrm_queue_visite_site]
where [TypeClientdataguid] in 
( select [TypeClientdataguid] from  [Stg].[_LCRM].[lcrm_queue_visite_site] where [TypeVisit_updated] >= dateadd(day,-1,getdate()) 
)
 )
--id ='1-eyJpZCI6MTA0NjU5OTZ9-50893bb169'

  select * 
 into #t
 from new_visit_user  where rn=1 order by id

begin tran 
 delete
--select * 
from dbo.dm_Client_visit_site 
where id+guid in(select id+guid from #t)

insert into dbo.dm_Client_visit_site
select * 
from #t where rn=1
commit tran 

 --select * 
 --from dbo.dm_Client_visit_site

-- 
END

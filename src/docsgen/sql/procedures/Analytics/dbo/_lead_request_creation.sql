


CREATE     proc [dbo].[_lead_request_creation]
as

--return

exec ( ' use feodor 

declare @a leadtype 
insert into  @a
select top 10000000 a.id from  analytics.dbo.v_lead a  with(nolock)

left join  analytics.dbo.v_lead2 b on a.id=b.id 
where 
 a.created  >= dateadd(minute, -60, getdate())
 and isnull(a.channel , '''')<>''cpa нецелевой'' 
 and b.id is null
exec lead_creation   @a
' )
--exec _request_product

--exec sp_create_job 'Analytics._lead_request_creation', 'exec _lead_request_creation', '0'

--select top 100 * from  _request
--order by 1 desc

--select top 1000 * from _lead_request where requestguid is null
--order by created desc
--exec msdb.dbo.sp_ADD_jobstep @job_name= 'Analytics._request_product 7:00 each 5 min'
--,  @retry_attempts = 0
--,  @retry_interval = 0
--,  @step_id = 2
--,  @command = '
--EXEC msdb.dbo.sp_start_job @job_name =  ''Analytics._lead_request_creation'' '
--,  @database_name = 'Analytics'
--,  @step_name = '_lead_request_creation'
--,  @on_success_action = 3
--,  @on_fail_action = 3 -- 1  success 2  failure 3  Go to next step 4  Go to step 


	   
-- alter table _request add leadId nvarchar(36)
-- alter table _request_log add leadId nvarchar(36) 




drop table if exists #_request

select 	
  a.leadId    id
, a.created	  requestcreated
, a.ispts	  ispts
, a.guid	  requestGuid
, a.eventLast eventLast
, a.phone     phone
    into #_request
from _request a 
left join _lead_request b on a.guid=b.requestGuid and a.leadid=b.id and b.channel is not null
left join _lead_request b1 on b1.requestGuid=a.guid and b1.id is null and a.leadid is null
where b.requestGuid is null and b1.requestGuid is null


--select * from #_request
--order by 2

 


--group by leadId
--select * from #_request
--where 
--and a.leadId='2B625666-4F9B-4A92-92BA-7804AEB95A87'

--select * from #_request 
--where guid='F677A7F6-2A53-4008-A684-39F2D3BF3C91'
--order by created desc



--select * from _lead_request 
--where requestGuid='F677A7F6-2A53-4008-A684-39F2D3BF3C91'
--order by created desc


--select * from #_request order by created

--;with v  as (select *,    row_number() over(partition by id, ispts order by eventLast desc) rn from #leads_with_requests ) 

--select * into #leads_with_requests2 from v 

 --aac5997f-279d-46c0-af7d-f0c0065cfcac	2024-10-19 09:33:30	0	517F8EA4-2FA6-46CC-ACF8-FAEE76C61099	3	9620066076

 --select * from _lead_request
 --where id = 'aac5997f-279d-46c0-af7d-f0c0065cfcac' or requestGuid='517F8EA4-2FA6-46CC-ACF8-FAEE76C61099'

 --select * from #_request where phone ='9530592818'
 --order by created


 --select * from _lead_request where phone ='9530592818'

 --select * from v_lead2_lcrm
 --where id=581601265


 --select * from stg._lcrm.lcrm_leads_full where id=581601265
 --select * from stg._lcrm.lcrm_leads_full_calculated where id=581601265

drop TABLE if exists [dbo].[#lead_request]
CREATE TABLE [dbo].[#lead_request]
(
      [id] [NVARCHAR](36)
    , [created] [DATETIME2](0)
    , [phone] [NVARCHAR](36)
    , [entrypoint] [NVARCHAR](36)
    , [source] [NVARCHAR](128)
    , [channel] [NVARCHAR](255)
    , [partnerId] [NVARCHAR](256)
    , [utmType] [NVARCHAR](128)
    , [isInstLead] [TINYINT]
    , requestGuid  [NVARCHAR](36)
    , requestCreated  [DATETIME2](0)
    , product   varchar(30)
	, decline  varchar(100)
);



-- insert 
-- into #lead_request

--select 
--  cast(a.id as nvarchar(36))   id
-- , UF_REGISTERED_AT created
-- ,   UF_PHONE phone
-- , UF_TYPE entrypoint
-- , UF_SOURCE source
-- , [Канал от источника] channel
-- , [UF_PARTNER_ID аналитический] partnerId
-- , uf_stat_ad_type utmType
-- ,  is_inst_lead isInstLead
  --, b.requestGuid requestGuid 
  --, b.requestCreated requestCreated
-- from Feodor.dbo.dm_leads_history a  
-- join #_request b on a.id=b.id and try_cast(b.id as bigint) is not null
 
-- insert 
-- into #lead_request

--select 
--   cast(a.id as nvarchar(36))   id
-- , UF_REGISTERED_AT created
-- ,   UF_PHONE phone
-- , UF_TYPE entrypoint
-- , UF_SOURCE source
-- , [Канал от источника] channel
-- , [UF_PARTNER_ID аналитический] partnerId
-- , uf_stat_ad_type utmType
--,  is_inst_lead isInstLead
--  , null 
--  , null 
 
-- from Feodor.dbo.dm_leads_history a  
-- left join _lead_request b on a.id=b.id   and try_cast(b.id as bigint) is not  null


  --where isnull(UF_TYPE, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV')   and b.id is null 


   insert   into #lead_request

select 
   cast(a.id as nvarchar(36))   id
 , UF_REGISTERED_AT created
 ,   UF_PHONE phone
 , entrypoint entrypoint
 , UF_SOURCE source
 , uf_loginom_channel channel
 , [UF_PARTNER_ID аналитический] partnerId
 , uf_stat_ad_type utmType
,  is_inst_lead isInstLead
  , b.requestGuid requestGuid 
  , b.requestCreated requestCreated
  , a.product
  , a.uf_loginom_decline decline 



 from Feodor.dbo.lead  a  with(nolock)
   join #_request b on a.id=b.id  --and try_cast(b.id as bigint) is   null 
 

 
 insert 
 into #lead_request


select 
   cast(a.id as nvarchar(36))   id
 ,      a.UF_REGISTERED_AT created
 ,      a.UF_PHONE phone
 ,      a.entrypoint entrypoint
 ,      a.UF_SOURCE source
 ,      a.uf_loginom_channel channel
 ,      a.[UF_PARTNER_ID аналитический] partnerId
 ,      a.uf_stat_ad_type utmType
 ,       a.is_inst_lead isInstLead
  , null
  , null
  , a.product
  , a.uf_loginom_decline decline 

 
 from Feodor.dbo.lead a    with(nolock)
 left join _lead_request b on a.id=b.id and a.uf_loginom_channel=b.channel
  where  a.entrypoint not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV')  and b.id is null  


  insert into #lead_request (requestGuid, requestCreated, phone)
  select a.requestGuid, a.requestCreated, a.phone from #_request a
  left join #lead_request b on a.requestGuid=b.requestGuid
  where b.requestGuid is null
   select @@ROWCOUNT, 'добавлены непривязанные'


  ;with v  as (select *, row_number() over(partition by id   order by case when requestGuid is not null then 1 end desc ) rn
  from #lead_request ) delete from v where rn>1 and requestGuid is null

  ;with v  as (select *, row_number() over(partition by requestGuid   order by case when id is not null then 1 end desc, created ) rn
  from #lead_request ) delete from v where rn>1 and requestGuid is not null --and requestGuid is null



  --select * from _lead_request

  

   --delete from  _lead_request
    --drop table if exists  _lead_request
    --select getdate() row_created, getdate() row_updated,  * into _lead_request from #lead_request
    --create   index index_1 on  _lead_request
    --(
    --id, requestguid
    --)

--select * from #lead_request
--order by isnull(created, requestcreated)


drop table if exists #for_del

select id, requestGuid into #for_del 
from #lead_request
where requestGuid is not null



   DELETE a
FROM _lead_request a with(index= [rg_i])
WHERE EXISTS (
    SELECT 1
    FROM #for_del b
    WHERE b.requestGuid = a.requestGuid
      AND (
            a.id <> b.id
            OR ( a.id IS NULL AND b.id IS NOT NULL )
            OR ( a.id IS NOT NULL AND b.id IS NULL )
          )
);

--   DELETE a
--FROM _lead_request a with(index= [rg_i])
--WHERE EXISTS (
--    SELECT 1
--    FROM #lead_request b
--    WHERE b.requestGuid = a.requestGuid
--      AND (
--            a.id <> b.id
--            OR ( a.id IS NULL AND b.id IS NOT NULL )
--            OR ( a.id IS NOT NULL AND b.id IS NULL )
--          )
--);



   --delete a from _lead_request a join #lead_request b on  a.requestGuid  = b.requestGuid  and isnull(a.id, '-1')<>isnull(b.id, '-1')

   select @@ROWCOUNT, 'перепривязка'


   delete a from _lead_request a join #lead_request b on a.id=b.id and a.requestGuid is null and b.requestGuid is not null


   select @@ROWCOUNT, 'привязка'

   
   drop table if exists #_lead_stg
   select * into  #_lead_stg from #lead_request 




   drop table if exists #_lead_request2
   select * into  #_lead_request2 from #lead_request where 1=0

--exec sp_select_except '#lead_request', '_lead_request', 'id', '#lead_request'

    INSERT INTO #_lead_request2 ([id], [created], [phone], [entrypoint], [source], [channel], [partnerId], [utmType], [isInstLead], [requestGuid], [requestCreated], product, decline)
    SELECT [id], [created], [phone], [entrypoint], [source], [channel], [partnerId], [utmType], [isInstLead], [requestGuid], [requestCreated], product, decline
    FROM  #lead_request
    EXCEPT
    SELECT [id], [created], [phone], [entrypoint], [source], [channel], [partnerId], [utmType], [isInstLead], [requestGuid], [requestCreated], product , decline
    FROM _lead_request
    --WHERE _lead_request.id IN (
    --    SELECT id
    --    FROM   #lead_request
    --); 

	
--select * from #lead_request 
--where requestGuid='F677A7F6-2A53-4008-A684-39F2D3BF3C91'
--order by created desc



--select * from _lead_request 
--where requestGuid='F677A7F6-2A53-4008-A684-39F2D3BF3C91'
--order by created desc
	
   --delete a from _lead_request a join #lead_request b on a.id=b.id and a.requestGuid is null and b.requestGuid is not null
   --delete a from _lead_request a join #lead_request b on a.id=b.id and a.requestGuid is null and b.requestGuid is not null

   select @@ROWCOUNT, 'updated'


--   select * from v_communication_crm
--where created>=getdate()-30 and (
--ТипУслуги like '%' + 'смен%ном' + '%' or	ТипОбращения like '%' + 'смен%ном' + '%' or	ДеталиОбращения like '%' + 'смен%ном' + '%' or
--ПоддеталиОбращения  like '%' + 'смен%ном' + '%' 	or Описание like '%' + 'смен%ном' + '%' or	Результат like '%' + 'смен%ном' + '%' or	Задача
--like '%' + 'смен%ном' + '%' 
-- )





-- select * from v_communication_crm where ДеталиОбращения = 'Смена номера'


--select 'MERGE _lead_request AS a  USING (SELECT * FROM #_lead_request2 ) AS b      ON a.id = b.id and isnull(a.requestGuid, '''')= isnull(b.requestGuid, '''')  WHEN MATCHED THEN  UPDATE SET 
--a.[row_updated] = getdate()  ' union all
--select * from (
--select top 1000 case when column_name = 'row_updated' then '' else ',' end + 'a.['+column_name+'] = '+case 
--when column_name like 'row_' + '%' then 'getdate() '
--when column_name   in ('') then 'b.['+column_name+']'
-- else 'case when a.['+column_name+'] is not null then a.['+column_name+'] else  b.['+column_name+']  end ' end  t
--from dwh where  table_name='_lead_request' and column_name <>'row_created' and column_name 
--in (select column_name from dwh where db='tempdb' and table_name like '%' + '#_lead_request2'  + '%' ) order by ordinal_position )  x union all
----select * from #t7_changed
--select ' WHEN NOT MATCHED BY TARGET THEN INSERT (' union all
--select '  row_created' union all
--select '  ,row_updated' union all
--select * from (
--select top 1000 ',['+column_name+'] ' t from dwh where  table_name='_lead_request'  and  column_name 
--in (select column_name from dwh where db='tempdb' and table_name like '%' + '#_lead_request2'  + '%' ) order by ordinal_position )  x  union all
--select '  )         VALUES ( ' union all
--select '  getdate()' union all
--select '  ,getdate()' union all
----select ' ,b.['+column_name+'] ' from dwh where  table_name='_request' union all
--select * from (
--select top 1000 ','	 +case when column_name like 'row_' + '%' then 'getdate() ' else 'b.['+column_name+'] ' end t  from dwh where  table_name='_lead_request'  and column_name 
--in (select column_name from dwh where db='tempdb' and table_name like '%' + '#_lead_request2'  + '%' ) order by ordinal_position   ) x union all 
--select '  )'-- union all
   ; 
  --alter table Analytics.dbo._lead_request alter column product nvarchar(30)
 
  
  MERGE _lead_request AS a  USING (SELECT * FROM #_lead_request2 ) AS b      ON isnull( a.id, '') = isnull(b.id, '') and isnull(a.requestGuid, '')= isnull(b.requestGuid, '')  WHEN MATCHED THEN  UPDATE SET 
a.[row_updated] = getdate()  
,a.[id] = case when a.[id] is not null then a.[id] else  b.[id]  end 
,a.[created] = case when a.[created] is not null then a.[created] else  b.[created]  end 
,a.[phone] = case when a.[phone] is not null then a.[phone] else  b.[phone]  end 
,a.[entrypoint] = case when a.[entrypoint] is not null then a.[entrypoint] else  b.[entrypoint]  end 
,a.[source] = case when a.[source] is not null then a.[source] else  b.[source]  end 
,a.[channel] = case when a.[channel] is not null then a.[channel] else  b.[channel]  end 
,a.[partnerId] = case when a.[partnerId] is not null then a.[partnerId] else  b.[partnerId]  end 
,a.[utmType] = case when a.[utmType] is not null then a.[utmType] else  b.[utmType]  end 
,a.[isInstLead] = case when a.[isInstLead] is not null then a.[isInstLead] else  b.[isInstLead]  end 
,a.[requestGuid] = case when a.[requestGuid] is not null then a.[requestGuid] else  b.[requestGuid]  end 
,a.[requestCreated] = case when a.[requestCreated] is not null then a.[requestCreated] else  b.[requestCreated]  end 
,a.product = case when a.product  is not null then a.product  else  b.product   end 
,a.decline = case when a.decline  is not null then a.decline  else  b.decline   end 

 
 WHEN NOT MATCHED BY TARGET THEN INSERT (
  row_created
  ,row_updated
,[id] 
,[created] 
,[phone] 
,[entrypoint] 
,[source] 
,[channel] 
,[partnerId] 
,[utmType] 
,[isInstLead] 
,[requestGuid] 
,[requestCreated] 
,product  
, decline
  )         VALUES ( 
  getdate()
  ,getdate()
,b.[id] 
,b.[created] 
,b.[phone] 
,b.[entrypoint] 
,b.[source] 
,b.[channel] 
,b.[partnerId] 
,b.[utmType] 
,b.[isInstLead] 
,b.[requestGuid] 
,b.[requestCreated] 
,b.product  
, b. decline
  ) ;



  --alter table _lead_request add isAccepted tinyint


  --alter table _lead_request add productTypeExternal varchar(30)


  --alter table _lead_request add linkUrl varchar(255)

  --alter table _lead_request add rn tinyint
  --alter table _lead_request add decline varchar(100)
  
  --alter table _lead_request add isBigInstallmentLead tinyint



 update _lead_request set _lead_request.isAccepted=1 from _lead_request join  v_Postback b1 on _lead_request.id=b1.lead_id and b1.api2Accepted is not null
 where _lead_request.created>=getdate()-60 and _lead_request.isAccepted is null


 


 update _lead_request set _lead_request.isAccepted=1 from _lead_request join  v_lead2 b1 on _lead_request.id=b1.id and  isnull(b1.status, '')  not in ('received' , 'declined')
 where _lead_request.created>=getdate()-60 and 
 _lead_request.isAccepted is null



  --alter table _lead_request add isCLickThrough tinyint
  --alter table _lead_request add linkCreated datetime2(0)
  
 update _lead_request set _lead_request.linkCreated= b1.created from _lead_request 
 join  v_Postback b1 on _lead_request.id=b1.lead_id and b1.isApi2=1
 where _lead_request.created>=getdate()-60 and _lead_request.linkCreated is null

 
 update _lead_request set _lead_request.isCLickThrough= al.active from _lead_request 
 join  v_request_external b1 on _lead_request.id=b1.id
 join  stg._lk.auth_link  al on  'https://login.carmoney.ru/client/v1/user/auth/'+al.hash+'/0' = b1.link_url and al.active=1
 where _lead_request.created>=getdate()-60 and _lead_request.isCLickThrough is null


 
 update a set a.productTypeExternal= b1.productType, a.isBigInstallmentLead = b1.isBigInstallment from _lead_request  a
 join  v_request_external b1 on a.id=b1.id
 where a.created>=getdate()-60  
 
 and  (( a.productTypeExternal is null
 and b1.productType is not null ) or 
( a.isBigInstallmentLead is null and b1.isBigInstallment=1 ))


 
 update _lead_request set _lead_request.linkUrl= b1.link_Url from _lead_request 
 join  v_request_external b1 on _lead_request.id=b1.id
 where _lead_request.created>=getdate()-60  
 
 and _lead_request.linkUrl is null
 and b1.link_Url is not null



 
    ;with v  as (select *, row_number() over(partition by id   order by case when requestGuid is not null then 1 end desc ) rn1
  from _lead_request )-- select * from  v where rn>1 and requestGuid is null
  delete from v where rn1>1 and requestGuid is null


  exec _lead_dubl
  exec _lead_client


  
	--!! exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '615B9902-77A6-4B5E-A7E4-D791D47F4B4B'


  return

  


  ;with v  as (select *, row_number() over(partition by requestGuid   order by case when id is not null then 1 end desc, created ) rn1
  from _lead_request ) select * from  v   where rn1>1 and requestGuid is not null --and requestGuid is null
   --delete from v where rn>1 and requestGuid is not null --and requestGuid is null

   

update a set a.phone=b.phone from lead_request a 
    join request b on b.guid =a.requestGuid and b.phone is not null
  where a.phone is null 

  
  select  top 100 * from lead_request a 
  left join request b on b.guid =a.requestGuid
  where a.phone is null 
  order by a.requestcreated desc



--  go

----select * from 	   #requests
----order by 1			  desc
--if 1=1
--begin

--drop table if exists #lead_request
--drop table if exists #leads_flow
-- select ДатаЛидаЛСРМ
-- , is_inst_lead
-- , UF_PHONE
-- , UF_SOURCE
-- , UF_TYPE
-- , cast(id as nvarchar(36))   id
-- , ВремяПервойПопытки
-- , ВремяПервогоДозвона
-- , UF_LOGINOM_STATUS
-- , ФлагПрофильныйИтог
-- , uf_stat_ad_type
-- , UF_REGISTERED_AT
-- , [UF_PARTNER_ID аналитический]
-- , [Группа каналов]
-- , [Канал от источника]
-- , UF_TYPE Entrypoint
-- , ПричинаНепрофильности  
-- , system = 'lcrm'
-- , cast(null as nvarchar(255)) userAgent

-- into #lead_request
-- from Feodor.dbo.dm_leads_history a  
-- where 1=0
-- select cast(UF_REGISTERED_AT as date)	ДатаЛидаЛСРМ
-- , is_inst_lead
-- , UF_PHONE
-- , UF_SOURCE
-- , UF_TYPE
-- , cast(id as nvarchar(50))   id
-- , ВремяПервойПопытки
-- , ВремяПервогоДозвона
-- , UF_LOGINOM_STATUS
-- , ФлагПрофильныйИтог
-- , uf_stat_ad_type
-- , UF_REGISTERED_AT
-- , [UF_PARTNER_ID аналитический]
-- , [Группа каналов]
-- , [Канал от источника] 
-- , Entrypoint Entrypoint
-- , ПричинаНепрофильности ПричинаНепрофильности	
-- , system = 'lf'
-- , userAgent

-- into   #leads_flow
-- from Feodor.dbo.lead a with(nolock)
-- where 1=0


--end



--drop table if exists #installment_lead_request

----select * from config
--;
--with v_ as (

-- --select ДатаЛидаЛСРМ
-- --, is_inst_lead
-- --, UF_PHONE
-- --, UF_SOURCE
-- --, UF_TYPE
-- --, cast(id as nvarchar(36))   id
-- --, ВремяПервойПопытки
-- --, ВремяПервогоДозвона
-- --, UF_LOGINOM_STATUS
-- --, ФлагПрофильныйИтог
-- --, uf_stat_ad_type
-- --, UF_REGISTERED_AT
-- --, [UF_PARTNER_ID аналитический]
-- --, [Группа каналов]
-- --, [Канал от источника]
-- --, UF_TYPE Entrypoint
-- --, ПричинаНепрофильности  
-- --, system = 'lcrm'
-- --, cast(null as nvarchar(255)) userAgent
  
-- --from Feodor.dbo.dm_leads_history a   union all
-- --select 1 d-- cast(UF_REGISTERED_AT as date)	ДатаЛидаЛСРМ
-- select cast(UF_REGISTERED_AT as date)	ДатаЛидаЛСРМ
-- , is_inst_lead
-- , UF_PHONE
-- , UF_SOURCE
-- , UF_TYPE
-- , cast(id as nvarchar(50))   id
-- , ВремяПервойПопытки
-- , ВремяПервогоДозвона
-- , UF_LOGINOM_STATUS
-- , ФлагПрофильныйИтог
-- , uf_stat_ad_type
-- , UF_REGISTERED_AT
-- , [UF_PARTNER_ID аналитический]
-- , [Группа каналов]
-- , [Канал от источника] 
-- , Entrypoint Entrypoint
-- , ПричинаНепрофильности ПричинаНепрофильности	
-- , system = 'lf' 
-- , userAgent
-- from Feodor.dbo.lead a with(nolock)



--)
--, v as (

--select * from #leads_flow union all 
--select * from #lead_request 



--)

--select
--  a.ДатаЛидаЛСРМ                                                                                             [ДатаЛидаЛСРМ]
--, a.is_inst_lead                                                                                             [is_inst_lead]
--, a.UF_SOURCE	                                                                                             [UF_SOURCE]
--, a.UF_TYPE		                                                                                             [UF_TYPE]
--, case when isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then a.id end                               [id]
--, products.ispts is_pts
--,  r.id                                                                                                      [request_id]
--, count(a.id)                                                                                                [Лидов]
--, count(ВремяПервойПопытки)                                                                                  [Лидов с попыткой] 
--, count(ВремяПервогоДозвона)                                   	                                             [Лидов с дозвоном]
--, count(case when UF_LOGINOM_STATUS='accepted' then a.id end)                                                [Лидов accepted]
--, count(case when ФлагПрофильныйИтог=1 then a.id end) 	                                                     [Лидов профильных]
--, a.uf_stat_ad_type		                                                                                     [uf_stat_ad_type]
--, try_cast(case when   isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV')or r.lcrm_id  is not null then UF_PHONE end as nvarchar(10)) [UF_PHONE]
--, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then UF_REGISTERED_AT end                   [UF_REGISTERED_AT]
--, case when UF_LOGINOM_STATUS='accepted' then 1 else 0 end                                                   [is_accepted] 
--,  case when  a.[Канал от источника]<>'CPA нецелевой' then [UF_PARTNER_ID аналитический]   	   end     	 [UF_PARTNER_ID аналитический]
--, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [UF_LOGINOM_STATUS]   end    	         [UF_LOGINOM_STATUS]  
--, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервойПопытки]  end    	         [ВремяПервойПопытки] 
--, case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервогоДозвона] end    	         [ВремяПервогоДозвона]
--, a.[Группа каналов]	                                                                                             [Группа каналов]
--, a.[Канал от источника]	                                                                                             [Канал от источника]
--, a.Entrypoint	                                                                                             Entrypoint
--, a.ПричинаНепрофильности	
--ПричинаНепрофильности
 
-- ,b.has_pts_request
-- ,b.has_bz_request
-- ,a.system
-- , ub.browser_name    browser
-- , ub.browser_version browserVersion

--into #installment_lead_request

--from v_ a
--left join useragent_browser ub on ub.useragent=a.userAgent
--left join (select 0 ispts union all select 1 ispts ) products	 on 1=1--r1.id is not null
--left join #requests r on a.id= r.lcrm_id  and r.ispts=products.ispts
-- left join #leads_with_requests b on a.id=b.lcrm_id


-- --select * from v_visit
-- --where type='mp'
 


----where  a.ДатаЛидаЛСРМ >='20230511'-
----where  a.ДатаЛидаЛСРМ >=cast(getdate()-40 as date)
--group by
-- a.ДатаЛидаЛСРМ
--,a.is_inst_lead
--,a.UF_SOURCE
--,a.UF_TYPE
--,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then a.id end  	 
--,r.id
--,a.uf_stat_ad_type
--,try_cast(case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV')  or r.lcrm_id  is not null then UF_PHONE end as nvarchar(10))
--,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then UF_REGISTERED_AT end  		 
--,case when UF_LOGINOM_STATUS='accepted' then 1 else 0 end   
--, case when  a.[Канал от источника]<>'CPA нецелевой' then [UF_PARTNER_ID аналитический]   	   end 
--,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [UF_LOGINOM_STATUS]   end    
--,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервойПопытки]  end    
--,case when  isnull(Entrypoint, '')not in ('api', 'import', 'loginom', 'DWH', 'TRIGGER', 'CSV') or r.lcrm_id  is not null then [ВремяПервогоДозвона] end    
--, products.ispts
--, a.[Группа каналов]	
--, a.[Канал от источника]
--, a.Entrypoint
--, a.ПричинаНепрофильности
-- ,b.has_pts_request
-- ,b.has_bz_request	
-- ,a.system
--  , ub.browser_name
-- , ub.browser_version
 

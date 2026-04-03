

CREATE proc [dbo].[woopra_etl] @type nvarchar(max)

as 

begin


if @type= 'mp'
begin


  drop table if exists #t2_mp

  select       
      a.[ВремяСтрокиНаСайте]   
  ,   a.[УИНСтрокиНаСайте]   
  ,   a.[pid]   
  ,   a.[crib_lead_id]   
  ,   a.[Action Name]   
  ,   a.[Action Type]   
  ,   a.[Domain]   
  ,   a.[Browser]   
  ,   a.[Device Type]   
  ,   a.[App/Integration]   
  ,   a.[Platform]   
  ,   a.[Action Duration (seconds)]   
  ,   a.[Campaign Medium]   
  ,   a.[Campaign Source]   
  ,   a.[Campaign Term]   
  ,   a.[Landing Page Path]   
  ,   a.[ВремяЗаписиСтроки]   
  ,   a.[Автор]   
  ,   a.[УИНЗапроса]   
  ,   a.[DWHInsertedDate]   
  ,   a.[ProcessGUID]   
  ,   a.[is_mp]   
  ,   a.[is_www]   
  ,   a.[client_id]     
  into #t2_mp
  from     analytics.dbo.v_woopra a
  where is_mp=1

  drop table if exists #u_by_crib_id
  select crib_client_id, created_at, username, id into #u_by_crib_id
  from stg._lk.users

 ; with v as( select *, ROW_NUMBER() over(partition by crib_client_id order by created_at) rn from #u_by_crib_id ) delete from v where rn>1

  drop table if exists #u_by_username
  select crib_client_id, created_at, username, id into #u_by_username
  from stg._lk.users

 ; with v as( select *, ROW_NUMBER() over(partition by username order by created_at) rn from #u_by_username ) delete from v where rn>1


 --select top 100 * from #lcrm_find_UF_CLIENT_ID
 --select count(*) from #lcrm_find_UF_CLIENT_ID

  drop table if exists #mv_woopra_mp

  select a.*, 
   case when is_mp=1  and c1.username is not null                           then c1.username
        when is_mp=1  and c2.username is not null                           then c2.username
        when is_mp=1  and len(a.client_id)=10 and isnumeric(a.client_id) =1 then a.client_id
   end [Телефон клиента],
      null [lcrm id]
   ,
      case 
        when is_mp=1  and  c1.username is not null                           then c1.id
        when is_mp=1  and  c2.username is not null                           then c2.id
        when is_mp=1  and  len(a.client_id)=10 and isnumeric(a.client_id) =1 then null
   end [user id mp]

   into #mv_woopra_mp
  from #t2_mp a
  left join #u_by_crib_id b on a.client_id=b.crib_client_id
  left join #u_by_username c1 on b.username=c1.username
  left join #u_by_username c2 on c2.username=a.client_id

  begin tran
  --drop table if exists mv_woopra_mp
  --select top 0 * into mv_woopra_mp from #mv_woopra_mp
  --create nonclustered index x on mv_woopra_mp ([ВремяСтрокиНаСайте])

  truncate table mv_woopra_mp
  insert into mv_woopra_mp
  select * from #mv_woopra_mp

  commit tran

  --select * from #mv_woopra
  --where [ВремяСтрокиНаСайте] between getdate()-2 and getdate()-1
  --order by [Телефон клиента]
  --
  --select * from #t2
  --where [ВремяСтрокиНаСайте] between getdate()-2 and getdate()-1

  --select top 10000 * from #lcrm
  --order by id desc

  end

if @type= 'www'
begin


  drop table if exists #t2_www

  select       
      a.[ВремяСтрокиНаСайте]   
  ,   a.[УИНСтрокиНаСайте]   
  ,   a.[pid]   
  ,   a.[crib_lead_id]   
  ,   a.[Action Name]   
  ,   a.[Action Type]   
  ,   a.[Domain]   
  ,   a.[Browser]   
  ,   a.[Device Type]   
  ,   a.[App/Integration]   
  ,   a.[Platform]   
  ,   a.[Action Duration (seconds)]   
  ,   a.[Campaign Medium]   
  ,   a.[Campaign Source]   
  ,   a.[Campaign Term]   
  ,   a.[Landing Page Path]   
  ,   a.[ВремяЗаписиСтроки]   
  ,   a.[Автор]   
  ,   a.[УИНЗапроса]   
  ,   a.[DWHInsertedDate]   
  ,   a.[ProcessGUID]   
  ,   a.[is_mp]   
  ,   a.[is_www]   
  ,   a.[client_id]     
  into #t2_www
  from     analytics.dbo.v_woopra a
  where [is_www]=1


  drop table if exists #lcrm_phone
  select id, PhoneNumber into #lcrm_phone from stg._LCRM.lcrm_leads_full_calculated with(nolock)


  drop table if exists #crib_lead_id
  select distinct crib_lead_id  into #crib_lead_id
  from #t2_www

  drop table if exists #client_id
  select distinct client_id  into #client_id
  from #t2_www

  drop table if exists #lcrm
  select id, uf_clid, UF_REGISTERED_AT, UF_CLIENT_ID into #lcrm from stg._LCRM.lcrm_leads_full with(nolock)
 -- select id, uf_clid, UF_REGISTERED_AT into #lcrm_uf_clid from stg._LCRM.lcrm_leads_full_channel_request
  --with(nolock)

  drop table if exists #lcrm_find_CLID
  select a.ID, a.UF_CLID, a.UF_REGISTERED_AT, b.PhoneNumber into #lcrm_find_CLID
  from #lcrm a
  join #lcrm_phone b on a.id=b.id
  join #crib_lead_id c on c.crib_lead_id=a.UF_CLID

 ; with v as( select *, ROW_NUMBER() over(partition by UF_CLID order by UF_REGISTERED_AT) rn from #lcrm_find_CLID ) delete from v where rn>1
 
 --select top 100 * from #lcrm_find_CLID

  drop table if exists #lcrm_find_UF_CLIENT_ID
  select a.ID, a.UF_CLIENT_ID, a.UF_REGISTERED_AT, b.PhoneNumber into #lcrm_find_UF_CLIENT_ID
  from #lcrm a
  join #lcrm_phone b on a.id=b.id
  join #client_id c on c.client_id=a.UF_CLIENT_ID

 ; with v as( select *, ROW_NUMBER() over(partition by UF_CLIENT_ID order by UF_REGISTERED_AT) rn from #lcrm_find_UF_CLIENT_ID ) delete from v where rn>1

 --select top 100 * from #lcrm_find_UF_CLIENT_ID
 --select count(*) from #lcrm_find_UF_CLIENT_ID

  drop table if exists #mv_woopra_www

  select a.*, 
   case 
        when is_www=1 and l.UF_CLID is not null  then l.PhoneNumber
        when is_www=1 and l1.UF_CLIENT_ID is not null  then l1.PhoneNumber
   end [Телефон клиента],
      case 
		when is_www=1 and  l.UF_CLID is not null  then l.ID
        when is_www=1 and  l1.UF_CLIENT_ID is not null  then l1.ID
   end [lcrm id]
   ,
      null [user id mp]

   into #mv_woopra_www
  from #t2_www a
  left join #lcrm_find_CLID l on l.UF_CLID=a.crib_lead_id
  left join #lcrm_find_UF_CLIENT_ID l1 on l1.UF_CLIENT_ID=a.client_id


  begin tran
  --drop table if exists mv_woopra_www
  --select top 0 * into mv_woopra_www from #mv_woopra
  --create nonclustered index x on mv_woopra_www ([ВремяСтрокиНаСайте])

  truncate table mv_woopra_www
  insert into mv_woopra_www
  select * from #mv_woopra_www

  commit tran

  --select * from #mv_woopra
  --where [ВремяСтрокиНаСайте] between getdate()-2 and getdate()-1
  --order by [Телефон клиента]
  --
  --select * from #t2
  --where [ВремяСтрокиНаСайте] between getdate()-2 and getdate()-1

  --select top 10000 * from #lcrm
  --order by id desc

  end


 end
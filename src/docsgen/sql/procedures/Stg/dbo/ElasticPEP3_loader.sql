  CREATE   procedure [dbo].[ElasticPEP3_loader]
  @guid char(36)='3D0A5ECD-DA58-4F3B-9760-AD20B6DDA12B'
  as
  begin

  set nocount on
  --declare @guid char(36)='c1adfbc7-0132-4b87-bdc3-c52f78c82bbb'

  drop table if exists #t
  
  --begin try
  ;
  with t as(
  select charindex('[Заявка] => ',text)+len('[Заявка] => ')+1 st_pos
       , id
       , _index
       , _id
       , category
       , timestamp
       , created_at
       , received_at
       , user_id
       , text
       , request_num1с =trim(request_num1с)
       , sent_status   =trim(sent_status)
       , dwh_load_guid
       , dwh_created
       , dwh_updated
  from elastic_pep3_buffer where dwh_load_guid=@guid
  )
  select id                 
       , _index
       , _id
       , category
       , timestamp          = try_cast(timestamp as datetime)
       , created_at         = try_cast(created_at as datetime)
       , received_at        = try_cast(received_at as datetime)
       , user_id            = try_cast(user_id as int)
       , text
       , request_num1с      =replace( case when request_num1с='' then substring(text,st_pos,charindex(' ',text,st_pos)-st_pos) else request_num1с end,char(10),'')
       , sent_status        = case when sent_status='' then 'OK' else sent_status end
       , dwh_load_guid
       , dwh_created
       , dwh_updated
    into #t
    from t
    --end try 
    --begin catch 
    --  throw
    --end catch


    delete from elastic_pep3
    insert into elastic_pep3
      select * from #t
/*

drop table if exists elastic_pep3_buffer

create table elastic_pep3_buffer(
id int identity(1,1)
,_index             nvarchar(100)  null
,_id                nvarchar(50)   null
,category           nvarchar(50)   null
,timestamp          nvarchar(50)   null
,created_at         nvarchar(50)   null
,received_at        nvarchar(50)   null
,user_id            nvarchar(50)   null
,text               nvarchar(max)  null
,request_num1с      nvarchar(50)   null
,sent_status        nvarchar(50)   null
,dwh_load_guid      char(36)
,dwh_created datetime default getdate()
,dwh_updated datetime default getdate()
)

--_index,_id,category,timestamp,created_at,received_at,user_id,text,request_num1с,sent_status  
drop table if exists elastic_pep3
create table elastic_pep3(
id int null
,_index             nvarchar(100)  null
,_id                nvarchar(100)   null
,category           nvarchar(50)   null
,timestamp          datetime   null
,created_at         datetime   null
,received_at        datetime   null
,user_id            int   null
,text               nvarchar(max)  null
,request_num1с      nvarchar(50)   null
,sent_status        nvarchar(50)   null
,dwh_load_guid      char(36)
,dwh_created datetime default getdate()
,dwh_updated datetime default getdate()
)



*/
-- Очищаем старые буферные данные
--select * from elastic_pep3_buffer where dwh_load_guid='c1adfbc7-0132-4b87-bdc3-c52f78c82bbb'

delete from elastic_pep3_buffer where dwh_created<dateadd(month,-3,getdate())

end
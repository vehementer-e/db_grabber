
CREATE proc dbo.create_etl_lust_update

as 

begin

declare @a nvarchar(max) 

drop table if exists #v_EtlTables
drop table if exists etl_lust_update

create table etl_lust_update 
(table_name nvarchar(max),
 dwhinserteddate datetime,
 created datetime
 )

 declare @sql nvarchar(max) 


  select TargetDb+'.'+TargetTable table_name --,* 
  
  into #v_EtlTables 
  from stg.etl.v_EtlTables
  where SourceSystem like '%crm%' and SourceSystem not like '%lcrm%'


  while 1=1
  begin

 set @sql = (select top 1 table_name from #v_EtlTables)
 delete from #v_EtlTables where table_name=@sql
 if 
 @sql is null 
 begin
 return
 end


 

waitfor delay '00:00:01'
 set @sql = 'insert into analytics.dbo.etl_lust_update  select '''+@sql+''' , (select max(dwhinserteddate) from ' + @sql +'), getdate() '
 exec (@sql)
 set @a =  format( getdate(), 'yyyy-MM-dd HH:mm:ss')+' '+ @sql
 set @sql=''
 ;

--RAISERROR(@a1,0,0)  waitfor delay '00:00:01'
 RAISERROR(@a,0,0) WITH NOWAIT

 waitfor delay '00:00:00:100'

 end

 end
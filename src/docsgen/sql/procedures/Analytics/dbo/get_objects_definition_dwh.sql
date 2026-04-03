
CREATE             proc [dbo].[get_objects_definition_dwh]
@database   varchar(max),
@search varchar(max)
as
begin
declare @sql varchar(max)

drop table if exists #t1
create table #t1
(
db nvarchar(max) ,
text nvarchar(max) ,
name nvarchar(max) ,
type_desc nvarchar(max) ,
)

drop table if exists #dbs
select *  into #dbs
from [dbo].[_v_databases_dwh]
where case when isnull(@database, '') ='' then 1 else 0 end = 1 or isnull(@database, '')=db

--select * from #dbs
set @database = (select top 1 * from #dbs)
delete from #dbs where db=@database


while @database is not null

begin
set @sql =''


set @sql = 'use ' +@database +'

;
with v as (
select '''+@database+''' db,  isnull(OBJECT_DEFINITION(object_id), object_name(object_id)) text , name, type_desc  from sys.objects with(nolock) where type_desc not in (''SYSTEM_TABLE'', ''INTERNAL_TABLE'')
)

select * from v 
'+case when isnull(@search, '')<>'' then 
'where text like ''%'+@search+'%'' ' else '' end




--select (@sql)
insert into #t1
exec (@sql)

delete from #dbs where db=@database

set @database = (select top 1 * from #dbs)


end

select * from #t1


end
--go
--
--
--exec dbo.get_objects_definition_dwh '', 'factor'


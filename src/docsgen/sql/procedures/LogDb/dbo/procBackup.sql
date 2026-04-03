CREATE PROCEDURE procBackup 
--declare 
    @dbname nvarchar(max)='Logdb'
as

--select 'Начало сохранения скриптов : ' + @dbname + '.'

set nocount on
declare @db_id nvarchar(max) =db_id(@dbname)

declare @sql nvarchar(max)
select @sql =
'if object_id(''logdb.[dbo].[DWH_OBJECT_TEXT]'') is null
begin
    create table  LogDb.dbo.DWH_OBJECT_TEXT (
        ID         int identity(1,1),
        DBNAME    nvarchar(max),
        OBJECTID   int,
        OBJECTNAME varchar(255),
        COLID      int,
        Number int,
        [DATE]     datetime default getdate(),
        [TEXT]     nvarchar(max))
    create unique clustered index PK_DWH_OBJECT_TEXT on DWH_OBJECT_TEXT(id)
end'
--print @sql
exec (@sql)

-- exec sp_drop_table #DWH_OBJECT_TEXT_NOW
-- exec sp_drop_table #DWH_OBJECT_TEXT_OLD
if object_id ('tempdb.dbo.#DWH_OBJECT_TEXT_NOW') is not null  drop table  #DWH_OBJECT_TEXT_NOW
create table #DWH_OBJECT_TEXT_NOW (
    ID         int identity(1,1),
    DBNAME    nvarchar(max),
    OBJECTID   int,
    OBJECTNAME varchar(255),
    COLID      int,
        Number int,
    [DATE]     datetime default getdate(),
    [TEXT]     nvarchar(max))
create unique clustered index PK_#DWH_OBJECT_TEXT_NOW on #DWH_OBJECT_TEXT_NOW(id)


if object_id ('tempdb.dbo.#DWH_OBJECT_TEXT_OLD') is not null  drop table  #DWH_OBJECT_TEXT_OLD
create table #DWH_OBJECT_TEXT_OLD (
    ID         int identity(1,1),
        DBNAME    nvarchar(max),
    OBJECTID   int,
    OBJECTNAME varchar(255),
    COLID      int,
        Number int,
    [DATE]     datetime default getdate(),
    [TEXT]     nvarchar(max))
create unique clustered index PK_#DWH_OBJECT_TEXT_OLD on #DWH_OBJECT_TEXT_OLD(id)

/*Получить ранее сохранённые скрипты, последние версии.*/
select @sql = '
insert into #DWH_OBJECT_TEXT_OLD (dbname,objectid, objectname, colid, number,date, text)
select dbname, objectid, objectname, colid, t.number, date, text
from LogDb.dbo.DWH_OBJECT_TEXT t
where t.objectid in (select distinct id from '+@dbname+'.dbo.syscomments)
    and t.id in (select id
                 from LogDb.dbo.DWH_OBJECT_TEXT t2
                 where t2.date = (select max(t3.date) from LogDb.dbo.DWH_OBJECT_TEXT t3 where t3.objectid = t2.objectid and t2.dbname=t3.dbname))
order by t.objectid'
--print @sql
exec (@sql)

/*Получить изменённые скрипты.*/
select @sql = '
/*Получить системную дату.*/
declare @GetDate datetime select @GetDate = GetDate()

insert into #DWH_OBJECT_TEXT_NOW (dbname,objectid, colid, number, date, text)
select '''+@dbname+''', s.id, s.colid, s.number,@GetDate, s.text



--select * 
from ' + @dbname + '.dbo.syscomments s
join 
 (

select  s.id ,s.number,s.colid,object_name(s.id,'+@db_id+') objName, checksum(ar.text) checksum_old, checksum(s.text)checksum_new,s.text,ar.text t1--,s.*,ar.*
             from ' + @dbname + '.dbo.syscomments s left join #DWH_OBJECT_TEXT_OLD ar
                                    on ar.objectid = s.id
                                    and ar.colid = s.colid
                                    and ar.number = s.number
                                    and ar.dbname='''+@dbname+'''
             where s.encrypted = 0 and s.id > 100/*Системные объекты.*/
                 and checksum(ar.text) <> checksum(s.text)
     and s.text is not null     -- and s.number<>0      
                 ) 
             q
             on q.id=s.id and q.number=s.number and q.colid=s.colid

                 '
--print @sql
exec (@sql)

select @sql = '
update #dwh_object_text_now
set objectname = object_name(objectid, '+ @db_id+')
where objectname = '''' or objectname is null and not object_name(objectid, '+ @db_id+') is null '
--print @sql
exec (@sql)

/*Сохранить в БД новые версии изменённых скриптов.*/
select @sql =
'insert into LogDb.dbo.dwh_object_text (dbname,objectid, objectname, colid, number,date, text)
select '''+@dbname+''', objectid, objectname, colid, number,date, text
from #dwh_object_text_now
where len(text) > 20'
--print @sql
exec (@sql)

--print 'Завершение сохранения скриптов : ' + @dbname + '.' + char(10) + char(10) + char(10) + char(10) + char(10)


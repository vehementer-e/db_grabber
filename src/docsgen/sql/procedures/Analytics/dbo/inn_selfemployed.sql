create   proc inn_selfemployed

as

--sp_create_job 'Analytics._inn_selfemployed at 12', 'inn_selfemployed', '1', '120000'

--select isjson('"{}"')


--EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._inn_selfemployed at 12' 



--create table inn_selfemployed_log
--( rowId varchar(36)
--, created datetime2(0)
--, inn varchar(50)
--, date date
--, checkStarted  datetime2(0)
--, result  varchar(max)
--)




--	select distinct CRMClientGUID, b.ИНН from #t1 a
--	left join dwh2.dm.v_Клиент_ИНН b on a.CRMClientGUID=b.GuidКлиент
--	where [признак залога]= 'Повторный заём с известным залогом' and [дней после закрытия последнего договора] <=730 and [маркетинговое предложение]<>'Красный' and [66+ лет] ='Нет' and [phone In Black List] = 'Нет'   
--	and Инн is not null



--insert into inn_selfemployed_log
--(rowId, created, inn, date )

 
 
--insert into inn_selfemployed_log
--(rowId, created, inn, date )
--	select newid(), getdate(), Инн , getdate() from ##t1



	--select * from inn_selfemployed_log

--insert into inn_selfemployed_log
--(rowId, created, inn, date )
--	select newid(), * from (
-- select distinct   getdate() created,  b.inn , '20260129'  date from  [adhoc_20260202_клиенты для ИНН] a
-- left join v_client_inn b on a.clientId=b.clientId 
-- left join inn_selfemployed_log c on c.inn = b.inn
-- where c.inn is null and b.inn is not null
-- ) x 
 

 declare @id varchar(100)
 declare @command varchar(max)
 declare @date date

 declare @result varchar(max)
 declare @stop int = 


 (select   count(*)+1 from inn_selfemployed_log where checkStarted >=cast(getdate() as date))
 

 ;
 while @stop<=2000
 begin
set @id = ( select top 1 rowId from inn_selfemployed_log where checkStarted is null order by created desc )

if @id is null return

update inn_selfemployed_log set checkStarted = getdate() where rowId=@id




set @command = (select  'declare @res varchar(max)
exec python ''result = check_selfemployed(inn="'+inn+'", dateStr="'+format(isnull(date, getdate()), 'yyyy-MM-dd')+'")  '' , 1, @res output
if @res not like ''%selfEmployed%'' exec log_email ''inn selfEmployed error''
update inn_selfemployed_log set result = @res where rowId='''+rowId+'''' from inn_selfemployed_log
where rowId=@id)

if @command is null return
 
 print (@command)
 exec (@command)
  

 set @stop = @stop+1

end

--update inn_selfemployed_log set checkStarted = null    where rowId='1E3613B7-7B97-4E37-937A-19BB5B7F85BA'
--update inn_selfemployed_log set checkStarted = null    where isnull(result, '') not like '%selfe%'
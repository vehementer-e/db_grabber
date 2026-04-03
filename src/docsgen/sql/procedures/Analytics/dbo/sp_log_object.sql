
CREATE     proc [dbo].[sp_log_object]
as
begin
--exec sp_create_job 'Analytics._sp_log_object at 6:00', 'exec sp_log_object', '1', '60000'

drop table if exists #t1
SELECT 
    o.object_id  object_id ,
    'analytics.'+s.name AS SchemaName,
    o.name AS ObjectName,
	full_name = 'analytics.'+s.name+'.['+o.name+']' ,
    o.type_desc AS type_desc,
    isnull(m.definition, 'null') AS definition,
    o.create_date AS create_date,
    o.modify_date AS modify_date,
	getdate() created
	into #t1

FROM sys.objects o
left JOIN sys.sql_modules m ON o.object_id = m.object_id
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id

left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
--where b.object_id is null
WHERE o.type IN ('P', 'V', 'u') and b.object_id is null
			  --select distinct type, type_desc from sys.objects
--select * from #t1


insert into #t1

SELECT 
    o.object_id  object_id ,
    'stg.'+s.name AS SchemaName,
    o.name AS ObjectName,
	full_name = 'stg.'+''+s.name+'.['+o.name+']' ,
    o.type_desc AS type_desc,
        isnull(m.definition, 'null') AS definition,

    o.create_date AS create_date,
    o.modify_date AS modify_date,
	getdate() created
 	    

FROM stg.sys.objects o
left JOIN stg.sys.sql_modules m ON o.object_id = m.object_id
INNER JOIN stg.sys.schemas s ON s.schema_id = o.schema_id

left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
--where b.object_id is null
WHERE o.type IN ('P', 'V', 'U') and b.object_id is null


--insert into #t1

--SELECT 
--    o.object_id  object_id ,
--    'Mvp_sales_ml.'+s.name AS SchemaName,
--    o.name AS ObjectName,
--	full_name = 'Mvp_sales_ml.'+''+s.name+'.['+o.name+']' ,
--    o.type_desc AS type_desc,
--    isnull(m.definition, 'null') AS definition,
--    o.create_date AS create_date,
--    o.modify_date AS modify_date,
--	getdate() created
 

--FROM Mvp_sales_ml.sys.objects o
--left JOIN Mvp_sales_ml.sys.sql_modules m ON o.object_id = m.object_id
--INNER JOIN Mvp_sales_ml.sys.schemas s ON s.schema_id = o.schema_id

--left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
----where b.object_id is null
--WHERE o.type IN ('P', 'V', 'U') and b.object_id is null



insert into #t1

SELECT 
    o.object_id  object_id ,
    'dwh_new_'+ s.name AS SchemaName,
    o.name AS ObjectName,
	full_name = 'dwh_new.'+''+s.name +'.['+o.name+']' ,
    o.type_desc AS type_desc,
    isnull(m.definition, 'null') AS definition,
    o.create_date AS create_date,
    o.modify_date AS modify_date,
	getdate() created
 

FROM dwh_new.sys.objects o
left JOIN dwh_new.sys.sql_modules m ON o.object_id = m.object_id
INNER JOIN dwh_new.sys.schemas s ON s.schema_id = o.schema_id

left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
--where b.object_id is null
WHERE o.type IN ('P', 'V', 'U') and b.object_id is null


											   
insert into #t1

SELECT 
    o.object_id  object_id ,
    'dwh2_'+s.name AS SchemaName,
    o.name AS ObjectName,
	full_name = 'dwh2.'+''+s.name+'.['+o.name+']' ,
    o.type_desc AS type_desc,
    isnull(m.definition, 'null') AS definition,
    o.create_date AS create_date,
    o.modify_date AS modify_date,
	getdate() created
 

FROM dwh2.sys.objects o
left JOIN dwh2.sys.sql_modules m ON o.object_id = m.object_id
INNER JOIN dwh2.sys.schemas s ON s.schema_id = o.schema_id

left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
--where b.object_id is null
WHERE o.type IN ('P', 'V', 'U') and b.object_id is null

														   									   
insert into #t1

SELECT 
    o.object_id  object_id ,
    'feodor.'+s.name AS SchemaName,
    o.name AS ObjectName,
	full_name = 'feodor.'+''+s.name+'.['+o.name+']' ,
    o.type_desc AS type_desc,
    isnull(m.definition, 'null') AS definition,
    o.create_date AS create_date,
    o.modify_date AS modify_date,
	getdate() created
 

FROM feodor.sys.objects o
left JOIN feodor.sys.sql_modules m ON o.object_id = m.object_id
INNER JOIN feodor.sys.schemas s ON s.schema_id = o.schema_id

left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
--where b.object_id is null
WHERE o.type IN ('P', 'V', 'U') and b.object_id is null


 										   									   
--insert into #t1

--SELECT 
--    o.object_id  object_id ,
--    'NaumenDbReport.'+s.name AS SchemaName,
--    o.name AS ObjectName,
--	full_name = 'NaumenDbReport.'+''+s.name+'.['+o.name+']' ,
--    o.type_desc AS type_desc,
--    isnull(m.definition, 'null') AS definition,
--    o.create_date AS create_date,
--    o.modify_date AS modify_date,
--	getdate() created
 

--FROM NaumenDbReport.sys.objects o
--left JOIN NaumenDbReport.sys.sql_modules m ON o.object_id = m.object_id
--INNER JOIN NaumenDbReport.sys.schemas s ON s.schema_id = o.schema_id

--left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
----where b.object_id is null
--WHERE o.type IN ('P', 'V', 'U') and b.object_id is null


														    										   									   
insert into #t1

SELECT 
    o.object_id  object_id ,
    'reports.'+s.name AS SchemaName,
    o.name AS ObjectName,
	full_name = 'reports.'+''+s.name+'.['+o.name+']' ,
    o.type_desc AS type_desc,
    isnull(m.definition, 'null') AS definition,
    o.create_date AS create_date,
    o.modify_date AS modify_date,
	getdate() created
 

FROM reports.sys.objects o
left JOIN reports.sys.sql_modules m ON o.object_id = m.object_id
INNER JOIN reports.sys.schemas s ON s.schema_id = o.schema_id

left join  dbo.objects_history b on o.object_id=b.object_id and o.modify_date=b.modify_date
--where b.object_id is null
WHERE o.type IN ('P', 'V', 'U') and b.object_id is null


				




insert into #t1

select checksum(job_id), 'msdb', Job_Name, 'msdb.['+Job_Name+']', 'job', Job_Name+'

'
+case when max([job_enabled])=0 then 'DISABLED
' else '' end

+STRING_AGG(
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
'+
format(step_id, '0')+':'+'
'+isnull(command, 'no command'), '
'  ) definition	,
     max(created) create_date ,
     max(updated)  modify_date,
	getdate() created from jobs
	group by checksum(job_id),  Job_Name   



--select * from _v_sysjobs
--select * from #t1
--drop table if exists dbo.objects_history 

--select * into dbo.objects_history 
--from #t1

insert into  dbo.objects_history 
select a.* from #t1 a
left join  dbo.objects_history b on a.object_id=b.object_id and b.modify_date=a.modify_date
where b.object_id is null	 and a.definition is not null



  delete a from	 dbo.objects_history 	a 

  join 
  (select top 555555 * from 
  
  (
select  *,case when 
lag(definition)  over(partition by object_id, schemaname order by modify_date ) = definition and 
lag(full_name)  over(partition by object_id, schemaname order by modify_date ) = full_name  then 1 else 0 end is_double,
count(*)  over(partition by object_id, modify_date )   is_doublee

from  dbo.objects_history 	a
where type_desc='VIEW'
) a where is_double=1		) b on a.object_id=b.object_id and a.modify_date=b.modify_date and a.SchemaName=b.SchemaName and a.type_desc='VIEW'
 
 --exec python 'procs_to_drive()'


  
--delete from dbo.objects_history where type_desc='job'
--select * from dbo.objects_history 
--where ObjectName like '%_mail%'


--,   ltrim( STUFF([definition], CHARINDEX('create', [definition]), LEN('create'), 'create or alter') )
--


end


CREATE proc   [dbo].[notify_BirsLog]

as 



--select * into notify_BirsLogProcessed from _monitoring.birs_failed_executions
--select * into notify_BirsLogIgnoring from _monitoring.ignore_items
--drop table if exists _monitoring.birs_failed_executions
--drop table if exists _monitoring.ignore_items

declare @start_dt datetime = isnull( dateadd(hour, -10 , (select max([TimeEnd]) from notify_BirsLogProcessed )) , '2023-11-29 19:30:00')
--select @start_dt
drop table if exists #t1
drop table if exists #t2
;
select --top 1000
cast([UserName] as nvarchar(max)) COLLATE Cyrillic_General_CI_AS [UserName]
,cast([Format] as nvarchar(max)) COLLATE Cyrillic_General_CI_AS [Format]
,cast(isnull([Parameters], '') as nvarchar(max))COLLATE Cyrillic_General_CI_AS [Parameters]
,cast(ItemPath as nvarchar(max)) COLLATE Cyrillic_General_CI_AS ItemPath
,cast(format([TimeDataRetrieval]/1000.0/60.0, '0') as nvarchar(max))  COLLATE Cyrillic_General_CI_AS [TimeDataRetrieval]
,cast(format([TimeProcessing]/1000.0/60.0   , '0') as nvarchar(max))  COLLATE Cyrillic_General_CI_AS [TimeProcessing]
,cast(format([TimeRendering]/1000.0/60.0    , '0')  as nvarchar(max)) COLLATE Cyrillic_General_CI_AS  [TimeRendering]
,cast(format([RowCount]    , '0')  as nvarchar(max))  COLLATE Cyrillic_General_CI_AS [RowCount]
      ,[ItemAction]	       COLLATE Cyrillic_General_CI_AS [ItemAction]	        
      ,cast(case when Format='pbix' then  format([TimeStart], 'yyyy-MM-dd HH:00:00') else [TimeStart]   end as datetime) [TimeStart]		  -- COLLATE Cyrillic_General_CI_AS [TimeStart]		
      ,cast(case when Format='pbix' then  format([TimeEnd], 'yyyy-MM-dd HH:00:00') else [TimeEnd]     end as datetime) [TimeEnd]		  -- COLLATE Cyrillic_General_CI_AS [TimeStart]		
	  , format([TimeStart], 'yyyy-MM-dd HH:mm:ss')		 COLLATE Cyrillic_General_CI_AS [TimeStart_str]	
	  , format([TimeEnd], 'yyyy-MM-dd HH:mm:ss')		 COLLATE Cyrillic_General_CI_AS [TimeEnd_str]	
      ,[Source]			   COLLATE Cyrillic_General_CI_AS [Source]						  
      ,[Status]			   COLLATE Cyrillic_General_CI_AS [Status]			
      ,[ByteCount]		 --  COLLATE Cyrillic_General_CI_AS [ByteCount]		
      ,case [Status]	when 'rsSuccess'	then N'🆗'  else N'💔'	end   COLLATE Cyrillic_General_CI_AS [Status2]			
   
     -- ,[AdditionalInfo]	   COLLATE Cyrillic_General_CI_AS [AdditionalInfo]	
	  into #t1	--select top 100 *
 FROM  birs_ExecutionLog3_7days
 where  /* isnull( Format, '')<>'PBIX'	and	 Status<>N'rsSuccess'-- and ItemPath like '/Sales%'
  and */ TimeEnd >=@start_dt  
  --and [UserName]  <> ''
and username not in (N'CM\birs')
and case when username ='CM\S.Pischaev' and itempath like '/Collection%' then 1 else 0 end <>1

--)

delete a from #t1 a
join notify_BirsLogProcessed b on a.[UserName]=b.[UserName] 
and a.[TimeStart]=b.[TimeStart]
and a.[TimeEnd]=b.[TimeEnd]
and a.[Status]=b.[Status]
and a.ItemPath=b.ItemPath

 
 delete a from #t1 a
join notify_BirsLogIgnoring b on  
  a.ItemPath=b.ItemPath		 and b.status is null	 
 
 delete a from #t1 a
 join notify_BirsLogIgnoring b on  
 a.ItemPath=b.ItemPath		 and b.status =a.Status

--alter  table _monitoring.ignore_items add status nvarchar(max)

;with v  as (select *, row_number() over(partition by [UserName], [TimeStart]  order by (select null)) rn from #t1 ) delete from v where rn>1

--exec select_table '#t1'
--create table   _monitoring.ignore_items (itempath nvarchar(max))


if (select count(*) from  #t1)=0 return


drop table if exists  #pars

select  [Parameters], max(cast( dbo.urldecode2( [Parameters] ) as  nvarchar(max))) Parameters_decoded into #pars from #t1
where [Parameters]<>''	
group by [Parameters]

								  

select [Текст],  replace( subject, '/SalesDepartment/', N'💲') subject, NEWID() id	   , 	status_del, 	[ItemPath_del]				  , 	[UserName_del]				  , 	TimeStart_del			   , 	TimeEnd_del
  into #t2

from (


SELECT top 10
[Текст] = 

'ItemPath - '+[ItemPath]+' 
'+'username - '+[UserName]+' 
'+'Status - '+Status+status2+' 
'+case when +a.[Parameters] <> '' then 'Parameters - '+a.[Parameters]+' 
'else '' end
+case when b.[Parameters_decoded]  <> '' then 'Parameters decoded - '+isnull(b.[Parameters_decoded] collate Cyrillic_General_CI_AS, '')+' 
'else '' end+'TimeDataRetrieval - '+[TimeDataRetrieval]+' min  
'+'TimeProcessing - '+[TimeProcessing]+' min  
'+'TimeRendering - '+[TimeRendering]+' min  
'+'RowCount - '+[RowCount]+' 
'+'TimeStart - '+TimeStart_str +' 
'+'TimeEnd - '  +TimeEnd_str +' 
'+'Format - '+[Format]+' 
insert into  _monitoring.ignore_items select '''+[ItemPath]+''', '''+Status+ '''' ,
subject =  Status2+[ItemPath]+N'🙎‍'+replace([UserName], 'CM\', '')+ ' '+Status+ N' MONITORING_BIRS_FAIL'
  , [ItemPath] [ItemPath_del]    
  , [UserName] [UserName_del]    
  , TimeStart TimeStart_del  
  , TimeEnd TimeEnd_del  
  , Status status_del  
  FROM #t1	  a
  left join #pars b on a.Parameters=b.Parameters
  order by TimeEnd



) a1 

  --select * from #t2


declare @sql nvarchar(max) =
'
declare @Текст nvarchar(max) 
declare @send_to nvarchar(max) 
declare @subject nvarchar(max) 

' + (
select STRING_AGG( sql, ';')
from (
select top 10000 cast('select @Текст = Текст, @subject=subject from #t2 where id='''+cast(id as nvarchar(max))+''' exec log_email @subject, default, @Текст  ; waitfor delay ''00:00:03.900'' 
' as nvarchar(max)) sql , * from #t2	 order by TimeEnd_del
) x
)

select @sql
exec (@sql)

insert into notify_BirsLogProcessed
select 
    a.[UserName] 
,   a.[Format] 
,   a.[Parameters] 
,   a.[ItemPath] 
,   a.[TimeDataRetrieval] 
,   a.[TimeProcessing] 
,   a.[TimeRendering] 
,   a.[RowCount] 
,   a.[ItemAction] 
,   a.[TimeStart] 
,   a.[TimeEnd] 
,   a.[TimeStart_str] 
,   a.[TimeEnd_str] 
,   a.[Source] 
,   a.[Status] 
,   a.[ByteCount] 

from 

#t1 a
join (select distinct 	[ItemPath_del]				  , 	status_del			 , 	[UserName_del]				  , 	TimeStart_del			   , 	TimeEnd_del from 

#t2 a )	   b on
a.[ItemPath]				= b.[ItemPath_del]				
and a.[UserName]				= b.[UserName_del]				
and a.TimeStart 		= b.TimeStart_del				
and a.TimeEnd 			= b.TimeEnd_del				
and a.[Status] 			= b.status_del				

																						 
	if @@ROWCOUNT=10
	select 1 d
	waitfor delay '00:00:00.900'

 
 
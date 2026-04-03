

CREATE      procedure [dbo].[DiffRows_Between_DWH_and_MasterSystem] 
as
--Процедура выполнена в рамках задачи :  https://jira.carmoney.ru/browse/DWH-1319
drop table if exists #ETLDiffRows_result

drop table if exists #t_log
select Id, 
	EventDateTime, 
	ProcessTableName = REPLACE(REPLACE(ProcessTableName,'[',''),']',''), 
	[ProcessRowsInSrcTableBeforeStart], 
	ProcessRowsInDstTableAfterFinish, 
	EventDescription
into #t_log
from logDb.dbo.EtlLog el  with (nolock) 

	where 
	el.EventDate = cast(getdate() as date)
	and (charindex ('Кол. строк в исходной таблице перед загрузкой', EventDescription)> 0
		or charindex ('Кол. строк в таблице после загрузки', EventDescription)> 0)


CREATE clustered INDEX ix
ON  #t_log
([ID])



;with cte_etlTables as 
(
	select DISTINCT  DbName, 
		SourceTable = REPLACE(REPLACE(SourceTable,'[',''),']',''), 
		TargetTable = --REPLACE( 		
		REPLACE(REPLACE(TargetTable,'[',''),']','')
		--, '_upd', '')
	from stg.etl.EtlTables stg_et with(nolock)
where DBMSType = 'MSSQL'
--and (SourceTable  like '%Документ_Платеж%'
--	or TargetTable like '%Документ_Платеж%')
	
and ( SelectPredicate !='1=1'
	or SourceTable like '%_upd')
and isActive = 1
and not (
			 replace(replace(SourceTable, ']', ''), '[', '') like '%РегистрНакопления_РасчетыПоЗаймам%'
			 or  replace(replace(SourceTable, ']', ''), '[', '') like '%РегистрСведений_CRM_ДокументыВзаимодействия%'
			 or replace(replace(TargetTable , ']', ''), '[', '')  like '%call_params_QoS%'
	)

and (not exists(select top(1) 1 from stg.etl.EtlTables t with(nolock)
where t.isActive = 1
	and REPLACE(REPLACE(t.TargetTable,'[',''),']','')
		= 
		REPLACE(REPLACE(stg_et.TargetTable,'[',''),']','')
	and t.SelectPredicate = '1=1'
	
	)
	or stg_et.SourceTable like '%_upd'
	)
), cte as (

select et.*, 
	
	el_before.ProcessRowsInSrcTableBeforeStart, 
	before_EventDateTime = el_before.EventDateTime , 
	el_after.ProcessRowsInDstTableAfterFinish, 
	after_EventDateTime = el_after.EventDateTime
	--DiffRows = el_before.ProcessRowsInSrcTableBeforeStart - el_after.ProcessRowsInDstTableAfterFinish
	--nRow = row_number() over(partition by el_before.LoaderProcessGUID order by el_after.EventDateTime)
from cte_etlTables et

left join (
	
	select  max(id) last_id
	, ProcessTableName 

	from #t_log el  with (nolock)
	where charindex ('Кол. строк в исходной таблице перед загрузкой', EventDescription)> 0
			group by  ProcessTableName

) last_before on  last_before.ProcessTableName = et.TargetTable
	
left join #t_log el_before with (nolock)
 on el_before.id = last_before.last_id 
 
left join (
	
	select  max(id) last_id
	, ProcessTableName

	from #t_log el  with (nolock)
	where charindex ('Кол. строк в таблице после загрузки', EventDescription)> 0
		
	group by  ProcessTableName

) last_after on  last_after.ProcessTableName = et.TargetTable
	

left join #t_log el_after with (nolock)
 on el_after.id = last_after.last_id 
 )

select * 
,DiffRows=  ProcessRowsInSrcTableBeforeStart - ProcessRowsInDstTableAfterFinish 
into #ETLDiffRows_result
from ( 
 select 
	DbName  = iif(charindex('_upd', SourceTable )>0, null, DbName  )
	,SourceTable = iif(charindex('_upd', SourceTable)>0, null, SourceTable)
	,TargetTable = LEAD(TargetTable, 1, TargetTable)  over(partition by Replace(TargetTable, '_upd', '') order by after_EventDateTime)
	,ProcessRowsInSrcTableBeforeStart = iif(charindex('_upd', SourceTable)>0, null, ProcessRowsInSrcTableBeforeStart)
	,ProcessRowsInDstTableAfterFinish = LEAD(ProcessRowsInDstTableAfterFinish, 1, ProcessRowsInDstTableAfterFinish) over(partition by Replace(TargetTable, '_upd', '') order by after_EventDateTime)
	,before_EventDateTime = iif(charindex('_upd', SourceTable)>0, null, before_EventDateTime)
	,after_EventDateTime = LEAD(after_EventDateTime, 1, after_EventDateTime) over(partition by Replace(TargetTable, '_upd', '') order by after_EventDateTime)
 from cte
  ) t
  where dbNAme is not null


 	begin
		DECLARE @tableHTML NVARCHAR(MAX) ;
		
		SET @tableHTML =

		N'<H1>Сравнение количества записей между DWH и мастер системой</H1>' +
		N'<table border="1">' +
		N'<tr><th>RowNumber</th><th>DbName</th><th>SourceTable</th><th>TargetTable</th><th>ProcessRowsInSrcTableBeforeStart</th><th>before_EventDateTime</th>'+
		N'<th>ProcessRowsInDstTableAfterFinish</th><th>after_EventDateTime</th><th>DiffRows</th>'+
		N'</tr>' +
		CAST ( ( SELECT td = ROW_NUMBER() OVER(order by DbName, ABS(DiffRows) DESC)  
		,               ''   
		,				td = DbName                  
		,               ''                                      
		,               td = SourceTable                     
		,               ''                                      
		,               td = TargetTable                         
		,               ''                                      
		,               td = ProcessRowsInSrcTableBeforeStart
		,				''                                  
		,               td = format(before_EventDateTime, 'dd/MM/yyyy HH:mm')
		,               ''                                      
		,               td = ProcessRowsInDstTableAfterFinish              
		,               ''                                      
		,               td = format(after_EventDateTime, 'dd/MM/yyyy HH:mm')              
		,               ''                                      
		,               td = DiffRows          

		from #ETLDiffRows_result
		where DiffRows != 0

		order by DbName, ABS(DiffRows) DESC 
		FOR XML PATH('tr'), TYPE
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;


    begin	     
		      EXEC msdb.dbo.sp_send_dbmail @recipients   = 'dwh112@carmoney.ru'
		      ,                            @subject      = 'Сравнение количества записей между DWH и мастер системой'
		      ,                            @body         = @tableHTML
		      ,                            @body_format  = 'HTML' ;
	  end
  END
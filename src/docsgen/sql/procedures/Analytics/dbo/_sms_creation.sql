
CREATE   proc  [dbo].[_sms_creation]--_sms_creation 'update' , 4000
  @mode nvarchar(max) = 'update'		, @num_of_days_to_update int = 30
as
begin

if @mode= 'update'
begin

declare @date_start date = cast( getdate()-@num_of_days_to_update as date) 

   drop table if exists #t1	
	
   select 	
         [Способ связи]	
      ,[Имя шаблона]	
      ,[Текст шаблона]	
      ,[Дата коммуникации]	
      ,communication_id	
      ,[Источник коммуникации]	
      ,guid	
	  into #t1
  FROM [Analytics].[dbo].v_communication_comc	
  where [Тип коммуникации]='SMS'	
  and [Дата коммуникации]>=	@date_start
 
drop table if exists 	 #communication_log_data
SELECT a.communication_guid
	,JSON_VALUE(log_data, '$.param."freePlaneText"') freePlaneText
	,JSON_VALUE(log_data, '$.body') body
INTO #communication_log_data
FROM stg._COMCENTER.communication_log_data a
JOIN #t1 b ON a.communication_guid = b.guid
 /* дефект
drop table if exists #t1
  select  cast([Дата коммуникации]	 as date) [День]
      ,count(*) cnt	
      ,max(a.guid)   guid
	  into #t1
  FROM [Analytics].[dbo].[v_COMCENTER_communications] a	 
 left join stg._COMCENTER.communication_log_data b on a.guid=b.communication_guid
   
where b.communication_guid is null	  and [Тип коммуникации]='SMS'	
group by  cast([Дата коммуникации]	 as date) 

*/

DROP TABLE IF EXISTS #crm
	SELECT dateadd(year, - 2000, Дата) Дата
		,ТекстСообщения	  ТекстСообщения
		,SUBSTRING(ТекстСообщения, 17, len(ТекстСообщения)) id			
		INTO #crm
	FROM stg.[_1cCRM].[Документ_СообщениеSMS] a
--	LEFT JOIN stg._1cCRM.Справочник_Пользователи b ON a.Автор = b.Ссылка
	where  cast(dateadd(year, - 2000, Дата) as date)>= @date_start

drop table if exists 	##sms
SELECT cast(isnull(a.[Дата коммуникации], b.Дата) AS DATE) ДатаSMS
	,CASE 
		WHEN a.[Дата коммуникации] IS NULL
			THEN 'Нет в comc'
		WHEN b.Дата IS NULL
			THEN 'Нет в crm'
		ELSE ''
		END [Наличие в системах]
, case
when len(с.body)<=70 then 1
when len(с.body)<=134 then 2
when len(с.body)<=201 then 3
when len(с.body)<=268 then 4
when len(с.body)<=335 then 5
when len(с.body)<=402 then 6
when len(с.body)<=469 then 7
when len(с.body)<=536 then 8
when len(с.body)> 536 then   ceiling( len(с.body) /67.0) end [Частей]
,len(с.body) 	  [Длина]
, с.body
, a.*
, b.*					   
into  #sms
from #t1   a full outer join  #crm b on a.communication_id=b.id

left join #communication_log_data с on a.guid=с.communication_guid



--drop table if exists _birs.sms_details
--select * into _birs.sms_details from ##sms
delete from _birs.sms_details	where ДатаSMS>=@date_start
insert into _birs.sms_details
select * from #sms

--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '96C909D6-4348-4BC9-BC6B-3FCA64C6C3D3'


end


if @mode = 'select' 

--select * from  _birs.sms_details
--order by ДатаSMS


--exec select_table  'analytics._birs.sms_details'

select -- top 1000 
    a.[ДатаSMS] 
,   a.[Наличие в системах] 
,   isnull(a.[Частей] , 1) [Частей]
,   a.[Длина] 
,   a.[body] 
--,   a.[Способ связи] 
,   a.[Имя шаблона] 
,   a.[Текст шаблона] 
,   a.[Дата коммуникации] 
,   a.[communication_id] 
,   a.[Источник коммуникации] 
,   a.[guid] 
,   a.[Дата] 
--,   a.[ТекстСообщения] 
,   a.[id] 
--, getdate() created

from 

analytics._birs.sms_details a



end

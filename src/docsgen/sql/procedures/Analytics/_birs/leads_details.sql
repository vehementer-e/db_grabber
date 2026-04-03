
CREATE     proc [_birs].[leads_details]

as
begin

drop table if exists #t1

select ДатаЛидаЛСРМ 
,UF_REGISTERED_AT 
,creationdate 
,ВремяПервойПопытки 
,cast(ID  as nvarchar(50))   ID
,UF_TYPE 
,UF_SOURCE 
,UF_PHONE 
,[Группа каналов] 
,[Канал от источника]  
, UF_LOGINOM_STATUS
into #t1 
from Feodor.dbo.dm_leads_history_light
where  1=0

insert into #t1 
 
select ДатаЛидаЛСРМ 
,UF_REGISTERED_AT 
,creationdate 
,ВремяПервойПопытки 
,ID 
,UF_TYPE 
,UF_SOURCE 
,UF_PHONE 
,[Группа каналов] 
,[Канал от источника]  
, UF_LOGINOM_STATUS
from Feodor.dbo.lead   with(nolock)
where cast(UF_REGISTERED_AT as date)>getdate()-8 and [Канал от источника] <> 'CPA нецелевой'
--	 and 1=0

select
datediff(minute, UF_REGISTERED_AT, creationdate) [ddif UF_REGISTERED_AT - creationdate] 
,datediff(minute, creationdate, ВремяПервойПопытки) [ddif creationdate - ВремяПервойПопытки] 
,datediff(minute, UF_REGISTERED_AT, ВремяПервойПопытки) [ddif UF_REGISTERED_AT - ВремяПервойПопытки] 
,ДатаЛидаЛСРМ 
,UF_REGISTERED_AT 
,creationdate 
,ВремяПервойПопытки 
,ID 
,UF_TYPE 
,UF_SOURCE 
,'***-**'+right(UF_PHONE , 5) UF_PHONE 
,[Группа каналов] 
,[Канал от источника] 
, UF_LOGINOM_STATUS
from #t1

end

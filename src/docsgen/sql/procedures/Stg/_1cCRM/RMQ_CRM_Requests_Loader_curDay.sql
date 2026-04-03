--exec [_1cCRM].[RMQ_CRM_Loader]


-- Usage: запуск процедуры с параметрами
-- EXEC [_1cCRM].[RMQ_CRM_Requests_Loader_curDay] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE     procedure [_1cCRM].[RMQ_CRM_Requests_Loader_curDay]
	
as
begin 
set nocount on


drop table if exists #t
drop table if exists #t_ReceivedMessages
select * 
into #t_ReceivedMessages
from [RMQ].ReceivedMessages_CRM_Requests  RM with(nolock)
where 
RM.[ReceiveDate] >= cast(cast(getdate() as date) as datetime2)
and FromQueue = 'dwh.crm.CRM.Requests.1.1'

delete from #t_ReceivedMessages
where ISJSON(ReceivedMessage) = 0

select 
	 [ReceiveDate]
	,publishTime
	,guid
	,type
	,version
	,dataguid
	,description
	,code
	,number
	,guidrequest
	,daterequest
	,datestuatusrequest
	,lastName	        
	,firstName 
	,secondName  
	,birthday 
	,mobilePhone  
	,passportSerial   
	,passportNumber 
	,locationOfBirth
	,placeOfIssue
	,dateOfIssue
	,departmentCode
	,registrationAddres
	,residentialAddress
	--, l.data
into #t

from #t_ReceivedMessages
 outer apply  OPENJSON(ReceivedMessage, '$')
 with (
		  publishTime nvarchar(100) '$.publishTime '
		, guid nvarchar(100) '$.guid '
		, data nvarchar(max) '$.data' as JSOn
       ) k
	   outer apply OPENJSON(k.data, '$')
  with (
		
         type  nvarchar(100) '$.type'
        , version  nvarchar(100) '$.version'
        , data nvarchar(max) '$.data' as JSOn
       ) l 
       outer apply OPENJSON(l.data, '$')
with(
         dataguid nvarchar(100) '$.guid'
        ,description  nvarchar(100) '$.description'
        ,code  nvarchar(100) '$.code'
		,number  nvarchar(100) '$.number' 
		, guidrequest nvarchar(100) '$.guid'
		, daterequest nvarchar(100) '$.date'
		, datestuatusrequest nvarchar(100) '$.statusDate'
        ,lastName  nvarchar(100) '$.lastName'  
		,firstName  nvarchar(100) '$.firstName'  
		,secondName  nvarchar(100) '$.secondName'  
		,birthday  nvarchar(100) '$.birthday'  
		,mobilePhone  nvarchar(100) '$.mobilePhone'  
		,passportSerial  nvarchar(100) '$.passportSerial'  
		,passportNumber  nvarchar(100) '$.passportNumber' 
		,locationOfBirth  nvarchar(100) '$.locationOfBirth'
		,placeOfIssue  nvarchar(100) '$.placeOfIssue'
		,dateOfIssue  nvarchar(100) '$.dateOfIssue'
		,departmentCode  nvarchar(100) '$.departmentCode'
		,registrationAddres  nvarchar(100) '$.registrationAddres'
		,residentialAddress  nvarchar(100) '$.residentialAddress'
) m

where (type = 'requestStatus' or type='client' or type='request')



drop table if exists #t_result

select distinct rs.[ReceiveDate], rs.publishTime, rs.guid, rs.description, rs.code, number, guidrequest, daterequest, datestuatusrequest,  lastName	        
	,firstName 
	,secondName  
	,birthday 
	,mobilePhone  
	,passportSerial   
	,passportNumber	
	,locationOfBirth
	,placeOfIssue
	,dateOfIssue
	,departmentCode
	,registrationAddres
	,residentialAddress 
into #t_result
from (select [ReceiveDate], publishTime, guid , description, code  from #t where type = 'requestStatus'
	 
) as rs
inner join (select 	publishTime, guid , number, guidrequest, daterequest, datestuatusrequest,  lastName	        
	,firstName 
	,secondName  
	,birthday 
	,mobilePhone  
	,passportSerial   
	,passportNumber from #t where type = 'request') as request
on rs.publishTime=request.publishTime and rs.guid = request.guid
left join (select 	publishTime, guid 	,locationOfBirth
	,placeOfIssue
	,dateOfIssue
	,departmentCode
	,registrationAddres
	,residentialAddress from #t where type = 'client') as client
on rs.publishTime=client.publishTime and rs.guid = client.guid
--order by guidrequest, rs.publishTime



begin tran


	if OBJECT_ID('_1cCRM.RMQ_CRM_Requests') is null
	begin

		select top(0) * 
		into _1cCRM.RMQ_CRM_Requests
		from 
		#t_result
	end
	delete 
	--select * 
	from [_1cCRM].RMQ_CRM_Requests 
	where guid in (select guid from #t_result)

	insert into [_1cCRM].RMQ_CRM_Requests 
	select * from #t_result

commit tran

end

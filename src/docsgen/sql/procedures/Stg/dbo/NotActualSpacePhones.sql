-- exec NotActualSpacePhones
-- select * from dm_NotActualSpacePhones  where phonesOfClient_phone='9196914139'
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[NotActualSpacePhones] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [dbo].[NotActualSpacePhones]
as
--EXECUTE AS LOGIN = 'sa';
set nocount on
   
declare @tsql nvarchar(max)
--drop table if exists velab.communication_results
--DWH-1764
TRUNCATE TABLE velab.communication_results

INSERT INTO velab.communication_results
(
    CRMClientGUID,
    customer_name,
    fio,
    MobilePhone,
    mobile,
    Home,
    work,
    additional,
    mobile_Contact,
    additional_contact
)
select CRMClientGUID      =       CRMClientGUID
     , customer_name      =       lastName+' '+name+' '+MiddleName 
     , fio                =       fio
     , MobilePhone              -- мобильный телефон клиента
     , mobile             =       case when ct_name in ('Телефон мобильный','Мобильный телефон') and ContactPersonType=1 then phone end --Телефон мобильный (клиента)--
     , Home               =       case when ct_name in ('Телефон домашний','Домашний телефон') and ContactPersonType=1 then phone end --Телефон домашний (клиента)--
     , work               =       case when ct_name in('Рабочий телефон','Телефон рабочий','Телефон руководителя рабочий') and ContactPersonType=1 then phone end --Телефон рабочий (клиента)
     , additional         =       case when ct_name in ('Телефон дополнительный','Телефон','Телефон супруга','Не указано', 'Неизвестный')  then phone end --Телефон дополнительный - клиента илил третьего лица
     , mobile_Contact     =       case when IsConfirmedDataContactPerson= 1 and ct_name in ('Неизвестный','Телефон мобильный','Мобильный телефон','Телефон контактного лица мобильный') and ContactPersonType=2 then phone end
     , additional_contact =       case when IsConfirmedDataContactPerson<>1 and ct_name in ('Неизвестный','Телефон контактного лица домашний','Телефон мобильный','Мобильный телефон','Телефон домашний','Домашний телефон','Рабочий телефон','Телефон рабочий','Телефон дополнительный','Телефон','Телефон супруга','Не указано','Телефон контактного лица мобильный') and ContactPersonType=2 then phone end
--select * 
--into        velab.communication_results
from  
/*
OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL;Trusted_Connection=yes;', '
     
select CRMClientGUID      =       CrmCustomerId
     , c.lastName
     , c.name
     , c.MiddleName 
     , fio                =       cc.fio
     , MobilePhone             
     , ct.name ct_name
     , ContactPersonType
     , cc.phone 
     
     
     , IsConfirmedDataContactPerson
     
     

from [collection].[dbo].customers c 
left join  [collection].[dbo].[CustomerContact] cc on c.id=cc.idcustomer and  IsOperative=1 and cc.Phone<>''''
left join [collection].[dbo].[ContactType] ct on ct.id=cc.IdContactType          ')
*/
(
	select CRMClientGUID      =       CrmCustomerId
		 , c.lastName
		 , c.name
		 , c.MiddleName 
		 , fio                =       cc.fio
		 , MobilePhone             
		 , ct.name ct_name
		 , ContactPersonType
		 , cc.phone 
		 , IsConfirmedDataContactPerson
	from _collection.customers c 
	left join  _collection.CustomerContact cc on c.id=cc.idcustomer and  IsOperative=1 and cc.Phone<>''
	left join _collection.ContactType ct on ct.id=cc.IdContactType
) AS T

drop table if exists ##prod_CustomerContact 

CREATE TABLE ##prod_CustomerContact(
	Phone nvarchar(100)
)


if getdate()>='20191021'
begin

	/*
	set @tsql='
	select * into ##prod_CustomerContact from  

	OPENROWSET(''SQLNCLI'', ''Server=C2-VSR-CL-SQL;Trusted_Connection=yes;'', ''select distinct Phone
	 from [collection].[dbo].[CustomerContact] where  IsOperative=0 
	''
	   ) 
	'
	exec (@tsql)
	*/
	INSERT ##prod_CustomerContact(Phone)
	select distinct Phone
	from _collection.CustomerContact
	WHERE IsOperative=0
end

else 

begin
	--select distinct Phone into ##prod_CustomerContact
	--from _collection.[CustomerContact] where  IsOperative=0 

	INSERT ##prod_CustomerContact(Phone)
	select distinct Phone
	from _collection.CustomerContact
	WHERE IsOperative=0
end



if object_id('tempdb.dbo.#t') is not null drop table #t

select *
  into #t 
  from rmq.ReceivedMessages
 outer apply  OPENJSON(ReceivedMessage, '$')
 with(
       message_docUrl       nvarchar(100) '$.docUrl'
      ,message_data         nvarchar(max) '$.data' as Json
      ,message_publishTime  nvarchar(100) '$.publishTime'
      ,message_publisher    nvarchar(100) '$.publisher'
      ,message_guid         nvarchar(100) '$.guid'
    ) l
outer apply  OPENJSON(l.message_data, '$')
 with (
       data_type nvarchar(100) '$.type'
      ,data_docUrl      nvarchar(100) '$.docUrl'
      ,data_version        nvarchar(100) '$.version'
      ,data_data         nvarchar(max) '$.data' as Json
    ) m
outer apply  OPENJSON(m.data_data, '$')
 with (
       client_CRMClientGuid                    nvarchar(100) '$.CRMClientGuid'
      ,client_description                      nvarchar(100) '$.description'
      ,client_clientStatus                     nvarchar(100) '$.clientStatus'
      ,client_clientCollStage                  nvarchar(100) '$.clientCollStage'
      ,client_registrationAddress              nvarchar(100) '$.registrationAddress'
      ,client_dateOfRegistration               nvarchar(100) '$.dateOfRegistration'
      ,client_residentialAddress               nvarchar(100) '$.residentialAddress'
      ,client_residentSince                    nvarchar(100) '$.residentSince'
      ,client_eMail                            nvarchar(100) '$.eMail'
      ,client_phonesOfClient                   nvarchar(max) '$.phonesOfClient' as Json
      ,client_ContactInformationThirdPersons   nvarchar(max) '$.ContactInformationThirdPersons'  as Json
    ) n
outer apply  OPENJSON(n.client_phonesOfClient)
 with (
      phonesOfClient_phone nvarchar(100) '$.phone'
      ,phonesOfClient_phoneType nvarchar(100) '$.phoneType'
      ,phonesOfClient_mainForCommunication nvarchar(100) '$.mainForCommunication'
      ,phonesOfClient_relevant nvarchar(100) '$.relevant'
      )
outer apply  OPENJSON(n.client_ContactInformationThirdPersons)
 with (
       ContactInformationThirdPersons_phoneNumber nvarchar(100) '$.phonenumber'
      ,ContactInformationThirdPersons_phoneType nvarchar(100) '$.phoneType'
      ,ContactInformationThirdPersons_contactName nvarchar(100) '$.contactName'
      ,ContactInformationThirdPersons_contactType nvarchar(100) '$.contactType'
      ,ContactInformationThirdPersons_relevant nvarchar(100) '$.relevant'
      )
where fromqueue='dwh.ClientUpdateDataFromCollection'
   and ISJSON([ReceivedMessage]) > 0 
   and ISJSON(l.message_data)>0

-- select * from #t
if object_id('tempdb.dbo.#u') is not null drop table #u


select distinct 
       message_publishTime=cast( dateadd(second,cast(message_publishTime as int),'1970-01-01')   as datetime)
     , client_CRMClientGuid
     , client_description	
     , client_clientStatus	
     , client_clientCollStage	
     , client_registrationAddress	
     , client_dateOfRegistration	
     , client_residentialAddress	
     , client_residentSince	
     , client_eMail	
     , client_phonesOfClient	
     , client_ContactInformationThirdPersons	
     , phonesOfClient_phone	
     , phonesOfClient_phoneType	
     , phonesOfClient_mainForCommunication	
     , phonesOfClient_relevant	
     , ContactInformationThirdPersons_phoneNumber	
     , ContactInformationThirdPersons_phoneType	
     , ContactInformationThirdPersons_contactName	
     , ContactInformationThirdPersons_contactType	
     , ContactInformationThirdPersons_relevant
  into #u
  from #t 

/*
if object_id('dbo.dm_NotActualSpacePhones') is not null drop table dbo.dm_NotActualSpacePhones
*/
--DWH-1764
TRUNCATE TABLE dbo.dm_NotActualSpacePhones

;with c as (
select distinct
       client_CRMClientGuid
     , phonesOfClient_phone
     , phonesOfClient_phoneType
     , message_publishTime
     , phonesOfClient_relevant
     , phonesOfClient_relevant_max_date=first_value(phonesOfClient_relevant) over (partition by client_CRMClientGuid,phonesOfClient_phone,phonesOfClient_phoneType order by message_publishTime desc )
  from #u
)
,third as (
select distinct
       client_CRMClientGuid
     , ContactInformationThirdPersons_phoneNumber
     , ContactInformationThirdPersons_phoneType
     , message_publishTime
     , ContactInformationThirdPersons_relevant
      ,ContactInformationThirdPersons_relevant_max_date=first_value(ContactInformationThirdPersons_relevant) over (partition by client_CRMClientGuid,ContactInformationThirdPersons_phoneNumber,ContactInformationThirdPersons_phoneType order by message_publishTime desc )
from #u

)
INSERT dbo.dm_NotActualSpacePhones(phonesOfClient_phone) --DWH-1764
SELECT DISTINCT phonesOfClient_phone 
--into dbo.dm_NotActualSpacePhones
FROM C   WHERE phonesOfClient_relevant_max_date='false'
UNION 
SELECT DISTINCT ContactInformationThirdPersons_phoneNumber FROM third    where ContactInformationThirdPersons_relevant_max_date='false'
union
 select distinct Phone
 from ##prod_CustomerContact

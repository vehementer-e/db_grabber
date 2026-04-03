/*
DWH-1581
Реестр для ручной загрузки в Naumen
*/
--Report_Registry_for_manual_loading_in_Naumen_Hard

create   procedure dbo.Report_Registry_for_manual_loading_in_Naumen_Hard

as
begin
declare @CollectingStage table (ID int, Name nvarchar(255))
insert into @CollectingStage
select Id, Name from stg._Collection.collectingStage
where Name in('Hard', 'Legal', 'ИП')
drop table if exists #tResult

drop table if exists #ClientPhones
select 
	CustomerId,
	ClientMobilePhone,
	ContactPhone,
	ContactPhoneType
into #ClientPhones
from stg._Collection.v_ClientPhones  cp
where ContactPersonType = 1
and exists (
	select top(1) 1 from stg._Collection.customers c
	where c.Id = cp.CustomerId
		and c.IdCollectingStage in (select Id from @CollectingStage)
	)

create clustered index ci_CustomerId on #ClientPhones(CustomerId, ContactPhoneType)

select 
	 distinct 
	   c.Id as CustomerId
	 , CRMClientGUID = CrmCustomerId
	 , [ФИО_клиента] = CONCAT(c.LastName, ' ', c.Name, ' ', c.MiddleName)
	 , [Логин закреплённого специалиста] = e.NaumenUserLogin
	 , [Мобильный телефон клиента] = cp_mobile.ClientMobilePhone
	 , [Дополнительный телефон] = cp_addition.ContactPhone
	 , [Домашний] = cp_home.ContactPhone
	 , UUID = 'corebo00000000000nqcmujc620e9ioc'
	-- Логин закреплённого специалиста "Хард"
	 , [Статус клиента] = cs_Status.CustomerStateName 
     , [Дата_последней_коммуникации] = cast(last_Communications.Date as date) 
	--,[Аллерт] = Deal_Alert.AlertName
	--,d.Number
	--,d.OverdueDays
into #tResult
from stg._Collection.customers c

left join (select distinct CustomerId, ClientMobilePhone  
		from  #ClientPhones cp_mobile 
	where ClientMobilePhone is not null
		union 
	select distinct CustomerId, ContactPhone  
		from  #ClientPhones cp_mobile
	where ClientMobilePhone is null
		and charindex('мобильный', cp_mobile.ContactPhoneType)>0
	) cp_mobile on cp_mobile.CustomerId = c.ID
left join #ClientPhones cp_home on cp_home.CustomerId = c.ID
	and charindex('домашний', cp_home.ContactPhoneType)>0
left join #ClientPhones cp_addition on cp_addition.CustomerId = c.ID
	and charindex('дополнительный', cp_addition.ContactPhoneType)>0

left join 
(
	select CustomerId,  Max(Date) Date from stg._Collection.Communications c
	where CommunicationType in (1) /*Исходящий звонок, Входящий звонок*/
		and ContactPersonType = 1
	group by CustomerId
 ) last_Communications on last_Communications.CustomerId = c.ID
 left join
 (
	select 
		cs.Id,
		cs.CustomerId,
		cs.CustomerStateId,
		CustomerStateName = cs_State.Name  
	from (
		select max(ID) id, CustomerId 
		from stg._Collection.CustomerStatus
		where IsActive = 1
		group by CUstomerID
	) last_CustomerStatus
	inner join stg._Collection.CustomerStatus cs on cs.ID = last_CustomerStatus.id
	inner join stg._Collection.CustomerState cs_State on cs_State.Id = cs.CustomerStateId
 ) cs_Status on cs_Status.CustomerId = c.Id
 --Должен быть закреплен специалист
 left join stg._Collection.Employee e on e.ID = c.ClaimantId
 and exists(select top(1) 1 from stg._Collection.EmployeeCollectingStage ecs 
	where ecs.EmployeeId = e.ID
	and ecs.CollectingStageId in(select Id from @CollectingStage)
	)
	--and e.NaumenUserLogin is not null
where c.IdCollectingStage in (select Id from @CollectingStage)
	and (cs_Status.CustomerStateId not in (
		8, --КА
		3, --Смерть подтвержденная
		16, --Банкрот подтвержденный
		19, --Мошенничество подтверждённое  Fraud подтвержденный
		21 --Отказ от Взаимодействия
		) or cs_Status.CustomerStateId is null)

		

select
	 r.*
	,[Аллерт] = Deal_Alert.AlertName
	,d.Number
	,d.OverdueDays
from #tResult r
inner join stg._Collection.Deals d on d.IdCustomer = r.CustomerId
	and d.IdStatus not in(0, 3, 5) /*Аннулирован, Погашен, Продан*/
left join stg._Collection.Alerts Deal_Alert on Deal_Alert.IdDeal = d.Id
order by CustomerId 

end





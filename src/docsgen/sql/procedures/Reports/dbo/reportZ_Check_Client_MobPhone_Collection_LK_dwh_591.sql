-- =============================================
-- Author:		Kurdin S
-- Create date: 2020-07-06
-- Description:	Отчет о телефонах клиентов в Коллекшн, СРМ и МФО 

-- =============================================

create PROCEDURE [dbo].[reportZ_Check_Client_MobPhone_Collection_LK_dwh_591]
	-- Add the parameters for the stored procedure here

@PageNo int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



drop table if exists #lk_client
select [id]

      ,[num]

      ,[num_1c]
      ,[mode]

      ,[date_return]
      --,[credit_product_id]
      --,[point_id]
      ,[user_id]
      ,[client_id]

	  ,isnull(([client_last_name]+' '+[client_first_name]+' '+[client_patronymic]),'') [fio_client]
      ,[client_birthday]
      ,[client_mobile_phone]

      ,[registration_address]
      --,[client_region_id]
      ,[client_home_phone]
      --,[client_de_facto_region_id]
      ,[client_employment_id]
      ,[client_work_position]

      ,[client_workplace_phone]
      --,[client_total_monthly_income]
      --,[client_total_monthly_outcome]
      ,[client_guarantor_name]

      ,[client_guarantor_phone]

      ,[active]
      ,[sort]
      ,[is_fedor]
      ,[client_workplace_name]

      ,[place_of_stay]
      ,[lcrm_id]

into #lk_client
from [Stg].[_LK].[requests]
where ([client_last_name]+' '+[client_first_name]+' '+[client_patronymic]) is not null or ([client_last_name]+' '+[client_first_name]+' '+[client_patronymic]) <> ''
		and [num_1c] not like 'СЗRC%' or not [num_1c] is null


drop table if exists #collection_client

select [Id]
      ,[Phone]
      ,[Address]
      ,[Comment]
      ,[IsOperative]
      ,[IdContactType]
      ,[IdCustomer]
      ,[CreateDate]
      ,[UpdateDate]
      ,[ContactPersonType]
      ,[Fio]
      ,[CommunicationCustomerTypeId]
      ,[BirthdayDt]
      ,[ForeignPhoneCount]
      ,[LastAutomaticActionDt]
      ,[WasAutoAction]
      ,[IsConfirmedDataContactPerson]
      --,[EmployeeId]
      --,[DeactivationFrom]
      --,[CreatedBy]
      --,[UpdatedBy]

into #collection_client
from [Stg].[_Collection].[CustomerContact]
where [Fio]<>''

drop table if exists #collection_client_v2

select [Id]
      --,[Name]
      --,[LastName]
      --,[MiddleName]
	  ,[LastName]+ ' '+[Name]+' '+[MiddleName] [Fio]
      --,[ExpirationDays]
      --,[FalsePromisesCount]
      --,[IdCollectingAgencyState]
      --,[IdCollectingStage]
      --,[LoansCount]
      --,[IdMoscowBasedTimezone]
      --,[AvatarPath]
      --,[CreateDate]
      ,[CrmCustomerId]
      --,[IdCustomerType]
      --,[UpdateDate]
      --,[ClaimantId]
      ,[MobilePhone]
      --,[CurrentNonPaymentReasonId]
      --,[HasAnyDayOfDelay]
      --,[ClaimantLegalId]
      --,[CreatedBy]
      --,[UpdatedBy]
      --,[StatusNameList]
into #collection_client_v2
from [Stg].[_Collection].[customers]


drop table if exists #collection_lk_v
select distinct
		c.[Fio] [coll_Fio] 
	   ,c.Id [coll_client_id]
	   ,c.[MobilePhone] [coll_MobilePhone]
	   ,l.[fio] [lk_Fio]
	   ,l.[client_id] [lk_client_id]
	   ,l.lk_MobilePhone
into #collection_lk_v
from #collection_client_v2 c
left join (select [client_id] ,[fio_client] [Fio],[client_mobile_phone] [lk_MobilePhone] from #lk_client) l on c.Fio=l.Fio and c.MobilePhone = l.lk_MobilePhone


drop table if exists #lk_collection_v
select c.[Fio] [coll_Fio] 
	   ,c.[MobilePhone] [coll_MobilePhone]
	   ,c.Id [coll_client_id]

	   ,l.[fio] [lk_Fio]
	   ,l.lk_MobilePhone
	   ,l.[lk_client_id]
into #lk_collection_v
from #collection_client_v2 c
right join (select [fio_client] [Fio]
					,[client_mobile_phone] [lk_MobilePhone] 
					,[client_id] [lk_client_id]
			from #lk_client
			where [fio_client]<>'') l on c.Fio=l.Fio and c.MobilePhone = l.lk_MobilePhone

/*
select * from (select * from #collection_lk_v where lk_Fio is null) c
join (select * from #lk_collection_v where coll_Fio is null)
*/
/*
select distinct *
from (select * from #lk_collection_v where [coll_Fio] is null) l
where [lk_Fio] in (select distinct [coll_Fio] from #collection_lk_v)
*/

drop table if exists #res
select distinct
	   c.[Fio] [coll_Fio] 
	   ,c.Id [coll_client_id]
	   ,c.[MobilePhone] [coll_MobilePhone]

	   ,l.[lk_Fio]
	   ,l.lk_MobilePhone
	   ,l.lk_client_id
into #res		
from #collection_client_v2 c
left join (select [lk_Fio] ,lk_MobilePhone ,[lk_client_id] from #lk_collection_v where [coll_Fio] is null) l
on c.Fio = l.lk_Fio
where lk_fio is not null

/*
select l.[id]
      ,[num]
      ,[num_1c]
      ,[user_id]
      ,[client_id]
	  ,[fio_client]
	  ,[client_mobile_phone] lk_mobile_phone
      ,[client_home_phone] lk_home_phone
      ,[client_workplace_phone] lk_workplace_phone
      ,[client_guarantor_phone] lk_guarantor_phone

	  ,[Phone] coll_phone
	  ,[Fio]
	  ,[IdCustomer]
from (select * from #lk_client where [fio_client]<>'' and [num_1c] not like '%СДRC%') l
left join #collection_client c on l.fio_client=c.Fio and l.[client_mobile_phone] <> c.Phone
where [num_1c] not like 'СЗRC-%' --or not [num_1c] is null 
		and [Phone] <> [client_mobile_phone]
*/


if @PageNo = 1

select 
	   [coll_Fio] [ФИО клиента]
	   ,coll_client_id
	   ,lk_client_id
	   
	   ,coll_MobilePhone
	   
	   ,lk_MobilePhone
	   
from #res

END


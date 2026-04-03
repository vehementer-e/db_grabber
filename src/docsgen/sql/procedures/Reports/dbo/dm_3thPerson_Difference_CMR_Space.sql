CREATE   PROCEDURE [dbo].[dm_3thPerson_Difference_CMR_Space] 
AS
BEGIN
	SET NOCOUNT ON;


--declare @GetDate2000 datetime

--set @GetDate2000=dateadd(year,2000,getdate());

--with	t0_collection as 
--(
drop table if exists #u2

select [ИД 3 лица Спейс]=c.[Id] --,[IsOperative] --,[IdContactType]
	  ,[СпособКонтакта 3 лица Спейс]=ct.[Name]
	  
      ,[ИД клиента Спейс] = c.[IdCustomer]
	  ,[ГУИД клиента Спейс]=cust.CrmCustomerId 
	  ,[Клиент ФИО Спейс] = (cust.[LastName]+N' '+cust.[Name]+N' '+cust.[MiddleName]) --,c.[CreateDate] --,c.[UpdateDate]
	  ,[Клиент ДР Спейс] = cast(d.[BirthdayDt] as date)
	  ,[Телефон2 Клиента Спейс] = cust.[MobilePhone]
      --,[ContactPersonType]
	  ,[ТипКонтакта 3 лицо Спейс] = cpt.[Name]
      ,[3-е лицо ФИО Спейс] = [Fio]
	  ,[ГУИД 3 лицо Спейс] = cust2.CrmCustomerId
	  ,[ДР 3 лицо Спейс] = cast(d2.[BirthdayDt] as date)
	  ,[Телефон2 3 лицо Спейс] = cust2.[MobilePhone]  --,[BirthdayDt]
      ,[Телефон 3 лицо Спейс] = [Phone] 

into #u2

from [Stg].[_Collection].[CustomerContact] c with(nolock) 
  left join [Stg].[_Collection].[ContactType] ct with(nolock) on c.[IdContactType]=ct.[Id] 
  left join [Stg].[_Collection].[ContactPersonType] cpt with(nolock) on c.[ContactPersonType]=cpt.[Id]
  left join [Stg].[_Collection].[customers]  cust with(nolock) on c.[IdCustomer]=cust.[id]
  left join [Stg].[_Collection].[customers]  cust2 with(nolock) on c.[Id]=cust2.[id]
  left join [Stg].[_Collection].[CustomerPersonalData] d2 with(nolock) on d2.[IdCustomer]=cust2.[id]
  left join [Stg].[_Collection].[CustomerPersonalData] d with(nolock) on d.[IdCustomer]=cust.[id]
  where c.[ContactPersonType]=2


--)

--,	u as
--(

drop table if exists #u

select distinct
	  [ГУИД клиента Спейс]
	  ,[Клиент ФИО Спейс]
	  ,[Клиент ДР Спейс]

	  ,[ГУИД 3 лицо Спейс]
      ,[3-е лицо ФИО Спейс]
      ,[Телефон 3 лицо Спейс]

--from t0_collection)
into #u
from #u2
--,	t as
--(
drop table if exists #t

select distinct 

		[ГУИД клиента CRM]=dwh_new.dbo.getGUIDFrom1C_IDRREF(s.Ссылка)
		,[ФИО клиента CRM] =s.Наименование
		,[ДР клиента CRM]= case 
								when cast(dateadd(year,-2000,cast(s.ДатаРождения as datetime2)) as date)='0001-01-01' then '1902-01-02' 
								else cast(dateadd(year,-2000,cast(s.ДатаРождения as datetime2)) as date)
						   end
		,[ФИО 3 лица crm]= p1.Наименование
		,[ГУИД 3 лица клиента CRM]=cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(p1.Ссылка) as nvarchar(36))
		,[номер телефона 3 лица crm]=  ки.НомерТелефонаБезКодов
		,[номер телефона 3 лица crm актуальный]=cast(case when ки.Актуальный=0x01 then '1' else '0' end as nvarchar(2))
into #t
from  stg._1cCRM.[Справочник_Партнеры] s  --on s.ссылка=c.CRMClientIDRREF
	join  stg._1cCRM.[Справочник_КонтактныеЛицаПартнеров] p1 with(nolock) on p1.Владелец=s.ссылка and s.CRM_ОсновноеКонтактноеЛицо<>p1.ссылка
	join  stg._1cCRM.Справочник_КонтактныеЛицаПартнеров_КонтактнаяИнформация ки with(nolock) on ки.Ссылка = p1.ссылка
	join  stg._1cCRM.Справочник_ВидыКонтактнойИнформации видыКи  with(nolock)  on видыКи.Ссылка = ки.Вид
	join  stg._1cCRM.[Справочник_РолиКонтактныхЛицПартнеров] rkl on rkl.Ссылка=CRM_РольКонтактногоЛица
             join  stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС r with(nolock) on r.Партнер=s.ссылка
where p1.Наименование<>N''
--)

--drop table if exists [dbo].[dm_3thPersonDifference_GUID_FIO_BirthD_CMR_Space]
truncate table [dbo].[dm_3thPersonDifference_GUID_FIO_BirthD_CMR_Space]

;with t_res as
(
select --t.[ГУИД 3 лица клиента CRM] ,u.[ГУИД 3 лицо Спейс] ,case when t.[ГУИД 3 лица клиента CRM]<>u.[ГУИД 3 лицо Спейс] then 1 else 0 end [differentGUID] 
	   --,t.[ФИО 3 лица crm] ,u.[3-е лицо ФИО Спейс] ,case when t.[ФИО 3 лица crm]<>u.[3-е лицо ФИО Спейс] then 1 else 0 end [differentFIO]
	   --,t.[номер телефона 3 лица crm актуальный] ,u.[Телефон 3 лицо Спейс] ,case when t.[номер телефона 3 лица crm актуальный]<>u.[Телефон 3 лицо Спейс] then 1 else 0 end [differentFIO]
		
	   --,
	   [ФИО 3 лица crm] 
	   ,case when [3-е лицо ФИО Спейс] is null then N'' else [3-е лицо ФИО Спейс] end as [3-е лицо ФИО Спейс]
	   ,[номер телефона 3 лица crm] 
	   ,case when [Телефон 3 лицо Спейс] is null then N'' else [Телефон 3 лицо Спейс] end as [Телефон 3 лицо Спейс]
	   ,t.[ГУИД клиента CRM] 
	   --,case when not u.[ГУИД клиента Спейс] is null then [ГУИД клиента Спейс] else N'00000000-0000-0000-00000-000000000000' end 
	   ,u.[ГУИД клиента Спейс] as  [ГУИД клиента Спейс]
	   ,case when t.[ГУИД клиента CRM]<>u.[ГУИД клиента Спейс] then 1 else 0 end [differentGUID] 
	   ,t.[ФИО клиента CRM] 
	   ,case when u.[Клиент ФИО Спейс] is null then N'' else u.[Клиент ФИО Спейс] end as  [Клиент ФИО Спейс] 
	   ,case when t.[ФИО клиента CRM]<>u.[Клиент ФИО Спейс] then 1 else 0 end [differentFIO]
	   --,t.[ДР клиента CRM] 
	   ,N'' as [ДР клиента CRM]
	   --,case when u.[Клиент ДР Спейс] is null then cast(getdate() as date) else u.[Клиент ДР Спейс] end as [Клиент ДР Спейс] 
	   ,N'' as [Клиент ДР Спейс] 
	   ,case when t.[ДР клиента CRM]<>(case when u.[Клиент ДР Спейс] is null then '1902-01-02' else u.[Клиент ДР Спейс] end) then 1 else 0 end [differentBD]

from #t t left join #u u on t.[ФИО 3 лица crm]=u.[3-е лицо ФИО Спейс] and t.[номер телефона 3 лица crm]=u.[Телефон 3 лицо Спейс]
where [ФИО 3 лица crm]<>N'' or not [ФИО 3 лица crm] is null
and t.[ГУИД клиента CRM]<>u.[ГУИД клиента Спейс] or t.[ФИО клиента CRM]<>u.[Клиент ФИО Спейс] or t.[ДР клиента CRM]<>u.[Клиент ДР Спейс]
)

--drop table if exists [dbo].[dm_3thPersonDifference_GUID_FIO_BirthD_CMR_Space]


  
insert into [dbo].[dm_3thPersonDifference_GUID_FIO_BirthD_CMR_Space] 
select * from t_res where [differentGUID]=1 or [differentFIO]=1 or [differentBD]=1


END

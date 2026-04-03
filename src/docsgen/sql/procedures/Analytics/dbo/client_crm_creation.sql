create proc dbo.client_crm_creation as
begin

drop table if exists #Справочник_Партнеры
SELECT CRMClientGUID=  dwh_new.[dbo].[getGUIDFrom1C_IDRREF]( [Ссылка]) 
      ,[Ссылка] [Ссылка партнер CRM]
      ,cast(dateadd(year, -2000, ДатаРождения) as date) [Дата рождения]
      ,[CRM_Фамилия] Фамилия 
      ,[CRM_Отчество] Отчество
      ,[CRM_Имя] Имя
	  ,[Пол] = case when [Пол] = 0xAFCEBF868D4361344851E8606D20B3F9 then 'Мужской'
                    when [Пол] = 0x80F4B5DF34A06D224981658CB1273444 then 'Женский' 
	                when right(replace([CRM_Отчество], ' ', ''), 1)='ч' then  'Мужской'
	                when right(replace([CRM_Отчество], ' ', ''), 1)='а' then  'Женский'
	                when [CRM_Отчество] like '%оглы%' then  'Мужской'
	                when [CRM_Отчество]like '%кызы%' then  'Женский'
	                else 'Мужской' end

into    #Справочник_Партнеры
  FROM [Stg].[_1cCRM].[Справочник_Партнеры]


  drop table if exists #crm_mobile
select b.CRMClientGUID          ,    [Основной телефон клиента CRM]  =  a.НомерТелефонаБезКодов
into #crm_mobile
from (select ссылка                  ссылка
,            [НомерТелефонаБезКодов] [НомерТелефонаБезКодов]
from stg.[_1cCRM].[Справочник_Партнеры_КонтактнаяИнформация] where [CRM_ОсновнойДляСвязи]=1 and Тип=0xA873CB4AD71D17B2459F9A70D4E2DA66 ) a
join #Справочник_Партнеры b on a.ссылка=b.[Ссылка партнер CRM] 
;with v  as (select *, row_number() over(partition by CRMClientGUID order by [Основной телефон клиента CRM] desc) rn from #crm_mobile ) delete from v where rn>1


--select a.GUID, [Список договоров клиента], a.[Основной телефон клиента CRM], b.[Основной телефон клиента CRM] from mv_clients a left join #crm_mobile b on a.GUID=b.CRMClientGUID 
--where isnull(a.[Основной телефон клиента CRM] , '') <>isnull(b.[Основной телефон клиента CRM], '')
--19112710000171/21052500108871/21110800150232
--21070500119331/21100800142438

drop table if exists #crm_email
select b.CRMClientGUID          ,    email  =  a.email
into #crm_email
from (select ссылка                  ссылка
,            АдресЭП email
from stg.[_1cCRM].[Справочник_Партнеры_КонтактнаяИнформация] where АдресЭП<>'' ) a
join #Справочник_Партнеры b on a.ссылка=b.[Ссылка партнер CRM] 

delete from  #crm_email where Analytics.dbo.validate_email(email, 1) is null


;with v  as (select *, row_number() over(partition by CRMClientGUID order by (select 1 ) desc) rn from #crm_email ) delete from v where rn>1




--Если номер в ЧС
drop table if exists #Номера_в_ЧС 
select cast(Phone as nvarchar(10)) [Телефон из ЧС без 8], max(create_at) [Дата внесения в ЧС] into #Номера_в_ЧС from stg._1cCRM.BlackPhoneList group by cast(Phone as nvarchar(10))
--select cast(UF_PHONE as nvarchar(10)) [Телефон из ЧС без 8], max(uf_created_at) [Дата внесения в ЧС] into #Номера_в_ЧС from stg._loginom.crib_proxy_black_phones group by cast(UF_PHONE as nvarchar(10))
;with v  as (select *, row_number() over(partition by [Телефон из ЧС без 8] order by (select null)) rn from #Номера_в_ЧС ) delete from v where rn>1

--select * from  stg._loginom.crib_proxy_black_phones



  drop table if exists #clients_final
  select 
  	  sp.CRMClientGUID,
  	  sp.[Ссылка партнер CRM],
  sp.[Пол],
  sp.[Дата рождения],
  sp.Фамилия,
  sp.Имя,
  sp.Отчество
  
  
  ,crm_mobile.[Основной телефон клиента CRM]  
  ,crm_email.[email] [email CRM]  
  ,Номера_в_ЧС.[Дата внесения в ЧС]

 into #clients_final
  from  #Справочник_Партнеры sp  
  left join #crm_mobile crm_mobile on crm_mobile.CRMClientGUID=sp.CRMClientGUID
  left join #crm_email crm_email on crm_email.CRMClientGUID=sp.CRMClientGUID
  left join #Номера_в_ЧС Номера_в_ЧС on Номера_в_ЧС.[Телефон из ЧС без 8]=crm_mobile.[Основной телефон клиента CRM]


  drop table if exists 	 client_crm
  select * into client_crm from 	#clients_final


  end
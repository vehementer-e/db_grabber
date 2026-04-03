

CREATE     proc [dbo].[create_marketing_lists_2023-06-26]

as
begin

drop table if exists #marketing_lists_stg
create table         #marketing_lists_stg
(
[Дата] date not null
,[Телефон 7] varchar(100)  not null
,[email] varchar(100)   null
,[external_id] varchar(100)    null
,[Тип] varchar(100)  not null
,[created] datetime2 not null
)

--/*
drop table if exists #dm_lead
select Телефон [Номер  телефона], [Дата лида], [Статус лида] , [Причина непрофильности], [Признак непрофильный] , [Признак профильный], isinstallment into #dm_lead from
Analytics.dbo.v_feodor_leads

delete from #dm_lead
where len([Номер  телефона] )<>10 or [Номер  телефона] is  null

drop table if exists #CustomerPersonalData
select IdCustomer, email, CreateDate  into #CustomerPersonalData from
[Stg].[_Collection].[CustomerPersonalData]
where email is not null--is not null
--select * from #CustomerPersonalData

drop table if exists #Документ_ЗаявкаНаЗаймПодПТС
select номер, МобильныйТелефон, ЭлектроннаяПочта , Ссылка into #Документ_ЗаявкаНаЗаймПодПТС from
stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
where МобильныйТелефон is not null and len(МобильныйТелефон)=10

drop table if exists #customers
select id, MobilePhone , IdCollectingStage into #customers from
stg._Collection.customers


delete from #customers where len(MobilePhone)<>10 or MobilePhone is null



drop table if exists #v_dm_Factor_Analysis
select номер, Телефон, ЭлектроннаяПочта
, [Верификация КЦ] 
, [Отказ Carmoney] 
, [Предварительное одобрение] 
, ДатаЗаявкиПолная 
, [Заем выдан] 
, [Отказ клиента] 
, Одобрено 
, [Ссылка заявка] 
, [Контроль данных день]
, [Контроль данных]
, Дубль
, [Предварительное одобрение день]
, [Заем выдан месяц] 
, isInstallment
, Забраковано


into #v_dm_Factor_Analysis from
Analytics.dbo.mv_dm_Factor_Analysis


delete from #v_dm_Factor_Analysis  where  len(Телефон)<>10 or Телефон is null


drop table if exists #Справочник_корректный_емэйл_по_айди_клиента

 SELECT 
  [IdCustomer] 
 ,cast(analytics.[dbo].[validate_email](Email, 1)  as varchar(100)) email
 ,row_number() over(partition by [IdCustomer] order by createdate desc) rn

	  into #Справочник_корректный_емэйл_по_айди_клиента
  FROM #CustomerPersonalData
  where analytics.[dbo].[validate_email](Email, 1) is not null
  delete from #Справочник_корректный_емэйл_по_айди_клиента where rn<>1

  
drop table if exists #Справочник_корректный_емэйл_по_номеру_заявки

select 
  Номер
, ссылка
, cast(analytics.[dbo].[validate_email](ЭлектроннаяПочта, 1) as varchar(100)) email
 ,row_number() over(partition by Номер order by (select 1) desc) rn

into #Справочник_корректный_емэйл_по_номеру_заявки
from #Документ_ЗаявкаНаЗаймПодПТС
  where analytics.[dbo].[validate_email](ЭлектроннаяПочта, 1) is not null
  delete from #Справочник_корректный_емэйл_по_номеру_заявки where rn<>1

  
drop table if exists #Справочник_корректный_емэйл_по_номеру_договора
SELECT d.Number                                                          
,      cast(analytics.[dbo].[validate_email](Email, 1) as varchar(100)) email
,row_number() over(partition by d.Number  order by cpd.createdate desc) rn

	into #Справочник_корректный_емэйл_по_номеру_договора
FROM #CustomerPersonalData cpd
join stg._collection.deals                      d   on d.IdCustomer=cpd.idcustomer
where analytics.[dbo].[validate_email](Email, 1) is  not null


drop table if exists #BlackPhoneList
select Phone, create_at into #BlackPhoneList from stg._1ccrm.BlackPhoneList


drop table if exists #dip_bfs
select mobile_fin, category, external_id into #dip_bfs from dwh_new.dbo.CRM_loyals_buffer_for_sales
--select * from #dip_bfs


drop table if exists #Справочник_корректный_емэйл_и_телефон_по_заявке

select 

cast('7'+МобильныйТелефон as varchar(100))  [Телефон 7],
ссылка,
cast(analytics.[dbo].[validate_email](ЭлектроннаяПочта, 1)  as varchar(100)) email

into #Справочник_корректный_емэйл_и_телефон_по_заявке
from #Документ_ЗаявкаНаЗаймПодПТС
where ISNUMERIC(МобильныйТелефон)=1 and len(МобильныйТелефон)=10




----------------------------------------------------------------------
--'Аннулированные ПТС без финального решения впоследствии'
----------------------------------------------------------------------
     
	 create nonclustered index t on #v_dm_Factor_Analysis
	 (Телефон, isInstallment, [Верификация КЦ])


  drop table if exists #annul_pts_bez_fin_resh
  select
  cast('7'+ltrim(rtrim(a.Телефон)) as varchar(100))  [Телефон 7],
  e.email  email
  into #annul_pts_bez_fin_resh
  from   #v_dm_Factor_Analysis a
outer apply (
select top 1  1 d 
from #v_dm_Factor_Analysis b
where a.Телефон=b.Телефон
and a.Номер<>b.Номер 
and b.[Верификация КЦ]>a.[Верификация КЦ] and b.isInstallment=0

and isnull(b.[Отказ Carmoney],b.[Заем выдан]) is not null ) x
left join #Справочник_корректный_емэйл_и_телефон_по_заявке e on e.Ссылка=a.[Ссылка заявка]
where [Отказ Carmoney] is null and [Заем выдан] is null  and Забраковано is null  and x.d is null and a.isInstallment=0

delete from #annul_pts_bez_fin_resh
where len([Телефон 7])<>11

  ;
with v as (select *, row_number() over(partition by [Телефон 7] order by (select 1) desc) rn from #annul_pts_bez_fin_resh)
delete from v where rn>1


  
  insert into #marketing_lists_stg
  select
        cast(getdate() as date) Дата
,       [Телефон 7]
,       nullif(email, '') email
,       cast(null as varchar(100))  external_id  
,       Тип = 'Аннулированные ПТС без финального решения впоследствии'
,       created = getdate()
from #annul_pts_bez_fin_resh


 
----------------------------------------------------------------------
--'Докреды и повторники кроме красных и ЧС'
----------------------------------------------------------------------

 drop table if exists #a


     
  drop table if exists #dip_but_red_and_bl
  select
  cast('7'+ltrim(rtrim(dip.mobile_fin)) as varchar(100))  [Телефон 7],
  #Справочник_корректный_емэйл_по_номеру_договора.email  email
  into #dip_but_red_and_bl
  from #dip_bfs dip
  left join #BlackPhoneList on #BlackPhoneList.Phone=dip.mobile_fin and cast(create_at as date)>=cast( getdate()-90 as date)
  left join #Справочник_корректный_емэйл_по_номеру_договора on #Справочник_корректный_емэйл_по_номеру_договора.Number=dip.external_id
  where #BlackPhoneList.Phone is null and category<>'Красный'
  
  delete from #dip_but_red_and_bl where len([Телефон 7])<>11

 -- select * from #Справочник_корректный_емэйл_по_номеру_договора

  ;
with v as (select *, row_number() over(partition by [Телефон 7] order by (select 1) desc) rn from #dip_but_red_and_bl)
delete from v where rn>1


  
  insert into #marketing_lists_stg
  select
        cast(getdate() as date) Дата
,       [Телефон 7]
,       nullif(email, '') email
,       cast(null as varchar(100))  external_id  
,       Тип = 'Докреды и повторники кроме красных и ЧС'
,       created = getdate()
from #dip_but_red_and_bl


 
 ----------------------------------------------------------------------
--'Текущие клиенты'
----------------------------------------------------------------------

 drop table if exists #a


     
  drop table if exists #f
  select [Id], 
  cast('7'+ltrim(rtrim([MobilePhone])) as varchar(100))  [Телефон 7],
  #Справочник_корректный_емэйл_по_айди_клиента.email
  into #f
  from #customers [customers]
  left join #Справочник_корректный_емэйл_по_айди_клиента on [customers].Id=#Справочник_корректный_емэйл_по_айди_клиента.[IdCustomer]
  where IdCollectingStage<>9 
  
  
  insert into #marketing_lists_stg
  select
        cast(getdate() as date) Дата
,       [Телефон 7]
,       nullif(email, '') email
,       cast(null as varchar(100))  external_id  
,       Тип = 'Текущие клиенты'
,       created = getdate()
from #f

 drop table if exists #f
 drop table if exists #a

----------------------------------------------------------------------
--'ЧС и отказы Carmoney'
----------------------------------------------------------------------


drop table if exists #a1


--забор данных из ЧС
select  '7'+cast(Phone as varchar(100))   [Телефон 7]   
,       cast(null as varchar(100))  email
into #a1

from #BlackPhoneList
where len(cast(Phone as varchar(100)))=10 

union all                      

select
  '7'+cast(Телефон as varchar(100))      [Телефон 7]
,cast(analytics.[dbo].[validate_email](ЭлектроннаяПочта, 1) as varchar(100))  email
from #v_dm_Factor_Analysis
where [Отказ Carmoney] >=getdate()-30 

delete from #a1
where [Телефон 7] is null  and email is null

   insert into #marketing_lists_stg
 select cast(getdate() as date) Дата
,       [Телефон 7]
,      nullif(email, '') email
,       cast(null as varchar(100))  external_id  
,       Тип = 'ЧС и отказы Carmoney'
,       created = getdate()
 --into Analytics.dbo.marketing_lists_black_list_and_carmoney_refuses
 from #a1

drop table if exists #t1


----------------------------------------------------------------------
--,       Тип = 'Предв. одобр. за все время'
----------------------------------------------------------------------

drop table if exists  #fa2, #final_for_clean2



drop table if exists #fa2
select номер, cast(Телефон as varchar(100)) Телефон, [Предварительное одобрение], [Отказ клиента], [Отказ Carmoney], [Заем выдан], ДатаЗаявкиПолная
into #fa2
from #v_dm_Factor_Analysis
where [Предварительное одобрение]>=dateadd(month, -4, getdate())



select a.Номер, a.[Предварительное одобрение] Дата, '7'+a.Телефон [Телефон 7], #Справочник_корректный_емэйл_по_номеру_заявки.email
into #final_for_clean2
from #fa2 a
left join #Справочник_корректный_емэйл_по_номеру_заявки on #Справочник_корректный_емэйл_по_номеру_заявки.Номер=a.Номер
left join #fa2 exclude_request on exclude_request.Телефон=a.Телефон and
(exclude_request.[Заем выдан] >=a.[Предварительное одобрение]
or exclude_request.[Отказ Carmoney] >=a.[Предварительное одобрение]
or exclude_request.[Отказ клиента]>=a.[Предварительное одобрение])  and a.Номер<>exclude_request.Номер
where a.[Предварительное одобрение] is not null 
and exclude_request.Номер is null 
and a.[Заем выдан] is null 
and a.[Отказ Carmoney] is null 
and a.[Отказ клиента] is null 


;
with v as (select *, row_number() over(partition by [Телефон 7] order by Дата desc) rn from #final_for_clean2)
delete from v where rn>1

  insert into #marketing_lists_stg
select cast(Дата as date) Дата
,       [Телефон 7]
,      nullif(email, '') email
,       Номер external_id  
,       Тип = 'Предв. одобр. за 4 месяца'
,       created = getdate()

from #final_for_clean2
;
drop table if exists #ЭлектроннаяПочта2, #fa2, #final_for_clean2

----------------------------------------------------------------------
--'Отказы клиента без займа впоследствии'
----------------------------------------------------------------------

;
with v as (
SELECT 


		 [Дата лида] Дата,
		cast('7'+dl.[Номер  телефона]  as varchar(100)) [Телефон 7]
  FROM #dm_lead dl left join #v_dm_Factor_Analysis fa on fa.Телефон=dl.[Номер  телефона] and fa.[Верификация кц] >=dl.[Дата лида] and fa.isinstallment=0
  where dl.[Признак профильный]=1 and dl.isinstallment=0 and fa.Номер is null and dl.[Номер  телефона] is not null
  and dl.[Дата лида]>=dateadd(month, -6, cast(getdate()-1 as date) )
  )

  insert into #marketing_lists_stg
  select cast(Дата as date) Дата
,       [Телефон 7]
,       cast(null as varchar(100))  email
,       cast(null as varchar(100))  external_id  
,       Тип = 'Профильные ПТС за 6 месяцев без заявки и возвратов'
,       created = getdate()
  
  from v
  
----------------------------------------------------------------------
--'Отказы клиента без займа впоследствии'
----------------------------------------------------------------------

;
with v as (
SELECT 


		 [Дата лида] Дата,
		cast('7'+[Номер  телефона]  as varchar(100)) [Телефон 7]
  FROM #dm_lead dl left join #v_dm_Factor_Analysis fa on fa.Телефон=dl.[Номер  телефона] and [Заем выдан]>=[Дата лида]
  where [Статус лида] like 'Отказ%' and fa.Номер is null and [Номер  телефона] is not null

  )

  insert into #marketing_lists_stg
  select cast(Дата as date) Дата
,       [Телефон 7]
,       cast(null as varchar(100))  email
,       cast(null as varchar(100))  external_id  
,       Тип = 'Отказы клиента без займа впоследствии'
,       created = getdate()
  
  from v

----------------------------------------------------------------------
--'Повторные клиенты зеленые желтые'
----------------------------------------------------------------------

	;


with v
as
(
	SELECT distinct [external_id]                                                            
	,               cast(dateadd(year, -2000, ДатаФактическогоЗакрытия )as date)              Дата
	,               emails.email                                               email
	,               cast( '7'+ТелефонМобильный as varchar(100)) [Телефон 7]




	FROM      [dwh_new].[dbo].povt_buffer                     bfs   
	left join #Справочник_корректный_емэйл_по_номеру_договора                                             emails on emails.number=bfs.[external_id]
	join [Stg].[_1cMFO].[Отчет_СписокКредитныхДоговоров] skd    on skd.НомерДоговора=bfs.external_id
	where category in
		(
		'Зеленый',
		'Желтый'--,
		)
		and type like '%Повторный%'
		and ТелефонМобильный  is not null  and ДатаФактическогоЗакрытия is not null
		--order by 2

)

  insert into #marketing_lists_stg

select  cast(Дата as date) Дата
,       [Телефон 7]
,       nullif(email, '') email
,       external_id       
,       Тип = 'Повторные клиенты зеленые желтые'
,       created = getdate()                                                                                                                                      

from v  

-----------------------------------------------------------------------------------------
--'Клиенты для рефинансирования'
-----------------------------------------------------------------------------------------
  ;

with v as (

SELECT 


		[Дата лида] [Дата],
		cast('7'+[Номер  телефона] as varchar(100)) [Телефон 7] 
  FROM #dm_lead
  where [Причина непрофильности]
  in
  (
  'Взял займ в другой компании',
  'Авто в залоге'--,
  ) 
  union all

  select 
  cast(ДатаЗаявкиПолная as datetime2)  [Дата]
  , cast('7'+Телефон as varchar(100)) [Телефон 7] 

  from #v_dm_Factor_Analysis fa
  where Одобрено <getdate()-10 and [Заем выдан] is null

  )
  
  insert into #marketing_lists_stg

  select 
  
         cast(Дата as date) Дата
  ,      [Телефон 7] 
  ,      cast(null as varchar(100)) email 
  ,      cast(null as varchar(100))  external_id 
,       Тип = 'Клиенты для рефинансирования'
,       created = getdate()                    
  from v
	;

  
-------------------------------------------------------------------------------------------
----'Докредитование 4 месяца'
-------------------------------------------------------------------------------------------
--
--with v
--as
--(
--	SELECT distinct [external_id]                                                            
--
--	,               emails.email                                               email
--	,               cast( '7'+isnull(sd.ТелефонМобильный , bfs.ТелефонМобильный )  as  varchar(100) ) [Телефон 7]
--	, dateadd(year, -2000,Дата ) Дата
--
--
--
--	FROM      [dwh_new].[dbo].docredy_buffer                     bfs   
--	left join #Справочник_корректный_емэйл_по_номеру_договора                                             emails on emails.number=bfs.[external_id]
--	join stg._1cCMR.Справочник_Договоры sd    on sd.Код=bfs.external_id
--	where category <>'Красный' and main_limit>0
--	
--		and (
--			bfs.ТелефонМобильный<>''
--			or email is not null)
--			and sd.Дата >=dateadd(year, 2000, dateadd(month, -4, getdate()))
--) 
--
--  insert into #marketing_lists_stg
--
--select Дата                                                                 
--,      [Телефон 7] 
--,      nullif(email, '') email
--,      external_id
--,       Тип = 'Докредитование 4 месяца'
--,       created = getdate()                    
---- into Analytics.dbo.marketing_lists_докредитование_4_месяца
--from v
--
--
-------------------------------------------------------------------------------------------
----'Недоезды 4 месяца'
-------------------------------------------------------------------------------------------
--
--
--
--
--drop table if exists #предводоб
--drop table if exists #кд
--drop table if exists #phones_an_emails_предводоб
--drop table if exists #phones_an_emails_кд
--drop table if exists #Документ_ЗаявкаНаЗаймПодПТС6
--
--select [Ссылка заявка] заявка, [Предварительное одобрение] Дата
--into #предводоб
--from #v_dm_Factor_Analysis  with(nolock)
--where  [Предварительное одобрение день]>=dateadd(month, -4, getdate() ) and Дубль=0 and [Контроль данных] is null
--
--
--
--select [Ссылка заявка] заявка
--into #кд
--from #v_dm_Factor_Analysis  with(nolock)
--where  [Контроль данных день]>=dateadd(month, -4, getdate() )
--
--
--;
--
--select  pa.Дата, [Телефон 7],  email  into #phones_an_emails_предводоб from #Справочник_корректный_емэйл_и_телефон_по_заявке v
--join #предводоб pa on pa.Заявка=v.ссылка;
--
--select  [Телефон 7],  email   into #phones_an_emails_кд from #Справочник_корректный_емэйл_и_телефон_по_заявке v
--join #кд pa on pa.Заявка=v.ссылка
--
--
--delete from #phones_an_emails_предводоб 
--where [Телефон 7] in (select [Телефон 7] from #phones_an_emails_кд where len([Телефон 7])>1) 
--or
--email in (select email from #phones_an_emails_кд where len(email)>1) 
--
--
--  insert into #marketing_lists_stg
--select Дата
--,      [Телефон 7]
--,      nullif(email, '') email
--,      cast(null  as varchar(100)) external_id
--,       Тип = 'Недоезды 4 месяца'
--,       created = getdate()    
--from #phones_an_emails_предводоб
--
--drop table if exists #предводоб
--drop table if exists #кд
--drop table if exists #phones_an_emails_предводоб
--drop table if exists #phones_an_emails_кд

-----------------------------------------------------------------------------------------
--'Одобрено но не выдано за все время'
-----------------------------------------------------------------------------------------




drop table if exists #одобренные
drop table if exists #выданные
drop table if exists #phones_an_emails_одобренные
drop table if exists #phones_an_emails_выданные

select [Ссылка заявка] заявка, [Предварительное одобрение] Дата
into #одобренные
from #v_dm_Factor_Analysis  with(nolock)
where  [Одобрено] >=dateadd(month, -4, getdate()) and Дубль=0 and [Заем выдан] is null


select [Ссылка заявка] заявка
into #выданные
from #v_dm_Factor_Analysis  with(nolock)
where  [Заем выдан] >=dateadd(month, -4, getdate())


;

select  pa.Дата, [Телефон 7], email  into #phones_an_emails_одобренные from #Справочник_корректный_емэйл_и_телефон_по_заявке v
join #одобренные pa on pa.Заявка=v.ссылка;

select  [Телефон 7], email   into #phones_an_emails_выданные from #Справочник_корректный_емэйл_и_телефон_по_заявке v
join #выданные pa on pa.Заявка=v.ссылка


delete from #phones_an_emails_одобренные 
where [Телефон 7] in (select [Телефон 7] from #phones_an_emails_выданные where len([Телефон 7])>1) 
or
email in (select email from #phones_an_emails_выданные where len(email)>1) 


  insert into #marketing_lists_stg
select Дата
,      [Телефон 7]
--,      [Телефон плюс 7]
,      nullif(email, '') email
,      cast(null  as varchar(100)) external_id
,       Тип = 'Одобрено но не выдано за 4 месяца'
,       created = getdate()

from #phones_an_emails_одобренные


drop table if exists #одобренные
drop table if exists #выданные
drop table if exists #phones_an_emails_одобренные
drop table if exists #phones_an_emails_выданные

-----------------------------------------------------------------------------------------
--'Непрофильные (кроме отказа от разговора)'
-----------------------------------------------------------------------------------------

  ;

with v as (

SELECT 


		[Дата лида] [Дата],
		cast('7'+[Номер  телефона] as varchar(100)) [Телефон 7] 
  FROM #dm_lead
  where [Признак непрофильный] = 1 
	and [Причина непрофильности] != 'Отказ от разговора'
	and [Дата лида] >= dateadd(d,-30, getdate())
  ) 
  
  
  insert into #marketing_lists_stg

  select 
  
         cast(Дата as date) Дата
  ,      [Телефон 7] 
  ,      null email 
  ,      cast(null as varchar(100))  external_id 
,       Тип = 'Непрофильные (кроме отказа от разговора)'
,       created = getdate()                    
  from v
	;

-----------------------------------------------------------------------------------------
--'Займы за прошлый месяц'
-----------------------------------------------------------------------------------------

drop table if exists #fa_займы_за_прошлый_месяц

select 

  Номер external_id
, [Заем выдан месяц] Дата
, cast( '7'+Телефон  as  varchar(100) ) [Телефон 7]
, cast(analytics.[dbo].[validate_email](ЭлектроннаяПочта, 1)  as varchar(100)) email
into #fa_займы_за_прошлый_месяц

from #v_dm_Factor_Analysis
where  [Заем выдан месяц]=dateadd(month, -1, cast(format(getdate(), 'yyyy-MM-01') as date))



  insert into #marketing_lists_stg
select Дата
,      [Телефон 7]
,      nullif(email, '') email
,      cast(null  as varchar(100)) external_id
,       Тип = 'Займы за прошлый месяц'
,       created = getdate()    

from #fa_займы_за_прошлый_месяц
drop table if exists #fa_займы_за_прошлый_месяц

--*/

--  insert into #marketing_lists_stg
--select getdate()
--,      '7'+tel
--,      null email
--,      cast(null  as varchar(100)) external_id
--,       Тип = 'Клиенты с авто CSV'
--,       created = getdate()    
--
--from Analytics.dbo.python_import_baza_23_03_2023 
----where tel not in
----(select Phone 
----from stg._1cCRM.BlackPhoneList
----where create_at>getdate()-90 or ReasonAdding_subject='Исключение номера телефона (бессрочно)'
----)




--insert into #marketing_lists_stg
--select getdate()
--,      CONTACT_APP_INFO_TXT  --уже с семеркой
--,      nullif(CONTACT_MAIL_INFO_TXT,'') email
--,      cast(null  as varchar(100)) external_id
--,       Тип = 'База клиентов НСПК'
--,       created = getdate()    
--
--from (
--
--select * from (select *, row_number() over(partition by contact_app_info_txt order by тип desc) rn from dbo.[База клиентов НСПК] ) x  where rn=1) x



--DROP table  [Банковские клиенты]
--create table  [Банковские клиенты]
--([Телефон без 7] nvarchar(10), [Тип]  nvarchar(100) )


--drop table if exists ##t11


--DECLARE @ReturnCode int, @ReturnMessage varchar(8000)
--EXEC Stg.dbo.ExecLoadExcel
--	@PathName = '\\10.196.41.14\DWHFiles\Analytics\AdHoc\',
--	@FileName = 'Базы банков.xlsx',
--	@SheetName = 'Лист1$',
--	@TableName = '##t11', --'files.TestFile1',
--	@isMoveFile = 0,
--	@ReturnCode = @ReturnCode OUTPUT,
--	@ReturnMessage = @ReturnMessage OUTPUT
--SELECT 'ReturnCode' = @ReturnCode, 'ReturnMessage' = @ReturnMessage
--insert into  [Банковские клиенты]
--select FORMAT(Мобильный, '0') , Тип from ##t11





--insert into #marketing_lists_stg
--select getdate()
--,      '7'+[Телефон без 7]  
--,      NULL email
--,      cast(null  as varchar(100)) external_id
--,       Тип = тИП
--,       created = getdate()    
--FROM [Банковские клиенты]


;


with v as (select *, ROW_NUMBER() over(partition by Тип, [Телефон 7], email order by email desc ) rn from #marketing_lists_stg )
delete from v where rn>1

begin tran
--drop table if exists analytics.dbo.marketing_lists
--create table         analytics.dbo.marketing_lists
--(
--[Дата] date not null
--,[Телефон 7] varchar(100)  not null
----,[Телефон плюс 7] varchar(100)  not null
--,[email] varchar(100)   null
--,[external_id] varchar(100)    null
--,[Тип] varchar(100)  not null
--,[created] datetime2 not null
--)
truncate table analytics.dbo.marketing_lists
insert into analytics.dbo.marketing_lists
select * from #marketing_lists_stg
commit tran


exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'AD438924-5958-476D-ABF4-ED2DF0C1BD75'

exec log_email 'Маркетинговые аудитории подготовлены'

end

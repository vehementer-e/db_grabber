
create PROC _collection.[create_report_pep]
as
begin

drop table if exists #t1,#t, #mindates

drop table if exists #c, #d, #cmr, #foragr ,#smsCommunications


select id, CrmCustomerId, EDOAgreement
	  into #c
--from [C2-VSR-SQL04].[collection_night00].dbo.customers
from stg._collection.customers



select id, Number
IsPEP,
dateadd(hour, 3, EngagementAgreementDate) EngagementAgreementDate,
IdCustomer, Number, HasEngagementAgreement, Date
into 

#d
from stg._collection.deals


drop table if exists #debtor_lk
 select id, pep_activity_log_id into #debtor_lk 
 from stg._lk.user_link
 	where user_link_type_id=1
 
 



drop table if exists #edo_crm
select  dwh_new.dbo.getGUIDFrom1C_IDRREF(Клиент) Клиент                                                                           
	,                      dateadd(year, -2000, min(case when ДатаПодписания='2001-01-01 00:00:00'  then null
	                                when ДатаПодписания<>'2001-01-01 00:00:00' then ДатаПодписания end ) )       ДатаПодписания
                                       
	
	into #edo_crm
	from stg._1cCRM.РегистрСведений_СогласияНаЭлектронноеВзаимодействие
	group by Клиент


		drop table if exists #contracts
		select c.id, c.user_id, code, case when len(u.username)=10 then u.username end username, 
		cast(nullif(ltrim(rtrim(Фамилия)), '')+
		nullif(ltrim(rtrim(Имя)), '')+
		nullif(ltrim(rtrim(Отчество)), '')+
		nullif(ltrim(rtrim(ПаспортСерия)), '')+
		nullif(ltrim(rtrim(ПаспортНомер)), '') as nvarchar(100)) ФИОпаспорт

		
		into #contracts
		from
		[Stg].[_LK].[contracts] c left join stg._LK.users u on u.id=c.user_id
		left join stg._1cCMR.Справочник_Договоры cmrd on cmrd.Код=c.code


drop table if exists #stg_pep_lk
select pep.source_sign, pep.created_at, pep.document_name, pep.client_id, pep.login, cast(nullif(ltrim(rtrim(pep.last_name)), '')+
		nullif(ltrim(rtrim(pep.first_name)), '')+
		nullif(ltrim(rtrim(pep.[patronymic])), '')+
		nullif(ltrim(rtrim(pep.passport_serial)), '')+
		nullif(ltrim(rtrim(pep.passport_number)), '') as nvarchar(100)) PassportFioLK

		
		 into #stg_pep_lk
from [Stg].[_LK].[pep_activity_log] pep
left join #debtor_lk debtors on debtors.pep_activity_log_id=pep.id
  where client_id <>'' and document_name in ( 'Соглашение об электронном взаимодействии', 'Соглашение о взаимодействии')
  --  RAISERROR('ШАГ 3 ок',0,0) WITH NOWAIT 


  CREATE CLUSTERED INDEX tg_pep_lk ON #contracts
(
	username ASC,
	ФИОпаспорт ASC,
		user_id ASC

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
 
 CREATE CLUSTERED INDEX tg_pep_lk ON #stg_pep_lk
(
	client_id ASC,
	PassportFioLK ASC,
		login ASC

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

  CREATE CLUSTERED INDEX tg_pep_lk ON #d
(
	number

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]




  drop table if exists 
	 #pep_activity_log
    select  
	

	 min(pep.created_at)   ДатаПодписания


	,pep.idcustomer, document_name
	  
	  
	 into --drop table if exists 
	 #pep_activity_log

  FROM (
  	select   pep.created_at, deals.idcustomer, document_name 
  FROM #stg_pep_lk pep 
   join #contracts contracts on contracts.user_id=pep.client_id /* or contracts.username=pep.loginor pep.PassportFioLK =contracts.ФИОпаспорт */ 
  join #d deals on deals.number=contracts.code
  where (source_sign='mp' and document_name= 'Соглашение о взаимодействии')
  union all
  select   pep.created_at, deals.idcustomer, document_name 
  FROM #stg_pep_lk pep 
   join #contracts contracts on  /*contracts.user_id=pep.client_id  or */  contracts.username=pep.login /* or pep.PassportFioLK =contracts.ФИОпаспорт */  
  join #d deals on deals.number=contracts.code
  where (source_sign='mp' and document_name= 'Соглашение о взаимодействии')
   union all
  select   pep.created_at, deals.idcustomer, document_name 
  FROM #stg_pep_lk pep 
   join #contracts contracts on  /*contracts.user_id=pep.client_id  or contracts.username=pep.login or  */pep.PassportFioLK =contracts.ФИОпаспорт
  join #d deals on deals.number=contracts.code
  where (source_sign='mp' and document_name= 'Соглашение о взаимодействии')
  ) pep
	group by pep.idcustomer, document_name

	insert into #pep_activity_log

	    select  
	 min(pep.created_at)   ДатаПодписания
	,pep.idcustomer, document_name
	from
	(
	
	
	select   pep.created_at, deals.idcustomer, document_name 
  FROM #stg_pep_lk pep 
   join #contracts contracts on contracts.user_id=pep.client_id /* or contracts.username=pep.loginor pep.PassportFioLK =contracts.ФИОпаспорт */ 
  join #d deals on deals.number=contracts.code
  where (document_name='Соглашение об электронном взаимодействии')
  union all
  select   pep.created_at, deals.idcustomer, document_name 
  FROM #stg_pep_lk pep 
   join #contracts contracts on  /*contracts.user_id=pep.client_id  or */  contracts.username=pep.login /* or pep.PassportFioLK =contracts.ФИОпаспорт */  
  join #d deals on deals.number=contracts.code
  where (document_name='Соглашение об электронном взаимодействии')
   union all
  select   pep.created_at, deals.idcustomer, document_name 
  FROM #stg_pep_lk pep 
   join #contracts contracts on  /*contracts.user_id=pep.client_id  or contracts.username=pep.login or  */pep.PassportFioLK =contracts.ФИОпаспорт
  join #d deals on deals.number=contracts.code
  where (document_name='Соглашение об электронном взаимодействии')
  ) pep

	group by pep.idcustomer, document_name
	

 drop table if exists #smsCommunications
select 
[id_1] sms_id
,CommunicationDateTime  sms_datetime
,CustomerId 
,case when Manager<>'Система' and Manager is not null and Manager<>'' then 1 else 0 end as OperatorCallDate

into #smsCommunications
from stg._collection.v_Communications c

where sms_flag=1
	and url_ending<>''




	drop table if exists #c_join_d
select c.id IdCustomer,
d.number,
c.[CrmCustomerId],
d.EngagementAgreementDate, 
d.HasEngagementAgreement, 
case when (count(d.HasEngagementAgreement) over (partition by c.id))>0 then case when d.HasEngagementAgreement=1  and d.EngagementAgreementDate is null then date end end  NotHavingEngagementAgreementDate,
c.[EDOAgreement],
#edo_crm.ДатаПодписания [EDOAgreement_Дата_Подписания],
pep_activity_log_EDO.ДатаПодписания  ДатаПодписанияЭлкетронногоЭДО,
pep_activity_log_UV.ДатаПодписания ДатаПодписанияЛК_В_МП,
x.sms_id sms_id_uv
into #c_join_d
from #c c join #d d on  c.id=d.IdCustomer
left join #edo_crm on #edo_crm.Клиент=c.[CrmCustomerId] and [EDOAgreement]=1
left join #pep_activity_log pep_activity_log_UV on pep_activity_log_UV.idcustomer=c.id and pep_activity_log_UV.document_name='Соглашение о взаимодействии' and d.EngagementAgreementDate is not null
left join #pep_activity_log pep_activity_log_EDO on pep_activity_log_EDO.idcustomer=c.id and pep_activity_log_EDO.document_name='Соглашение об электронном взаимодействии' and [EDOAgreement]=1 and #edo_crm.ДатаПодписания is not null
outer apply  (select top 1 * from #smsCommunications where #smsCommunications.CustomerId=c.id and #smsCommunications.sms_datetime between dateadd(day, -10, d.EngagementAgreementDate ) and d.EngagementAgreementDate    order by OperatorCallDate desc, sms_datetime desc ) x 

	drop table if exists #report_pep_details

select idcustomer, 

min(EngagementAgreementDate) EngagementAgreementDate, 
max(cast ( HasEngagementAgreement as int )) HasEngagementAgreement, 
min(NotHavingEngagementAgreementDate) NotHavingEngagementAgreementDate,
min(ДатаПодписанияЛК_В_МП) ДатаПодписанияЛК_В_МП,


max(sign([EDOAgreement])) [EDOAgreement], 
min([EDOAgreement_Дата_Подписания]) [EDOAgreement_Дата_Подписания], 
min(ДатаПодписанияЭлкетронногоЭДО) ДатаПодписанияЭлкетронногоЭДО,
max(sms_id_uv) sms_id_uv
into #report_pep_details
from #c_join_d
group by idcustomer


 --drop table if exists 	Analytics.dbo.report_pep_details
 --select * into Analytics.dbo.report_pep_details from #report_pep_details

 delete from Analytics.dbo.report_pep_details
 insert into Analytics.dbo.report_pep_details
 select * from #report_pep_details
-- select * from Analytics.dbo.report_pep_details
  
 
  drop table if exists #DialerClientContractStage
/*
--var 1
SELECT 
	  c.id idCustomer
	  ,CRMClientStage  StageName
      ,cast([created] as date) StageDate
	  ,row_number() over (partition by CrmCustomerId , cast([created] as date ) order by (select null)) rn
	  into #DialerClientContractStage
  FROM [dwh_new].[Dialer].[ClientContractStage] act
     join stg._Collection.customers c on c.CrmCustomerId=act.CRMClientGUID
 -- where cast(created as date)>=@start_date

   delete from #DialerClientContractStage where rn<>1
*/
--var 2 --DWH-2442
SELECT DISTINCT
	c.id AS idCustomer
	,act.Client_Stage AS StageName
	,act.call_dt AS StageDate
INTO #DialerClientContractStage
FROM Stg._loginom.Collection_Client_Stage_history AS act
	INNER JOIN Stg._Collection.customers AS c 
		ON c.CrmCustomerId = act.CRMClientGUID


   --drop table if exists report_collection_stages_by_customers_history
drop table if exists #t
select a.StageDate, a.idCustomer, a.StageName

  ,case when cast(EDOAgreement_Дата_Подписания  as date)<=StageDate then 1 else 0 end as [ПризнакЭДО_срм]
	  ,case when cast(EDOAgreement_Дата_Подписания  as date)<=StageDate and cast(ДатаПодписанияЭлкетронногоЭДО  as date) <= StageDate then 1 else 0 end as [ПризнакЭДО_срм_электронно]

	  ,case when cast(EDOAgreement_Дата_Подписания  as date)<=StageDate and (cast(ДатаПодписанияЭлкетронногоЭДО  as date) > StageDate or cast(ДатаПодписанияЭлкетронногоЭДО  as date) is null) then 1 else 0 end as [ПризнакЭДО_срм_не_электронно]
	  
	  ,case when cast(isnull(EngagementAgreementDate, NotHavingEngagementAgreementDate)  as date)<=StageDate then 1 else 0 end as [ПризнакУВ]
	  ,case when cast(isnull(EngagementAgreementDate, NotHavingEngagementAgreementDate)  as date)<=StageDate and cast(EngagementAgreementDate as date)<=StageDate then 1 else 0 end as [ПризнакУВ_электронно]
	  ,case when cast(isnull(EngagementAgreementDate, NotHavingEngagementAgreementDate)  as date)<=StageDate and cast(EngagementAgreementDate as date)<=StageDate and ДатаПодписанияЛК_В_МП <=StageDate
	  then 1 else 0 end as [ПризнакУВ_электронно_МП]

	  ,case when cast(isnull(EngagementAgreementDate, NotHavingEngagementAgreementDate)  as date)<=StageDate and cast(EngagementAgreementDate as date)<=StageDate then 1 else 0 end
	  -
	  case when cast(isnull(EngagementAgreementDate, NotHavingEngagementAgreementDate)  as date)<=StageDate and cast(EngagementAgreementDate as date)<=StageDate and ДатаПодписанияЛК_В_МП <=StageDate
	  then 1 else 0 end as [ПризнакУВ_электронно_десктоп]

	  ,case when cast(isnull(EngagementAgreementDate, NotHavingEngagementAgreementDate)  as date)<=StageDate and cast(NotHavingEngagementAgreementDate as date)<=StageDate then 1 else 0 end as [ПризнакУВ_не_электронно]

	  ,getdate() as created
into #t
from #DialerClientContractStage a
  left join Analytics.[dbo].[report_pep_details] b on a.[idCustomer]=b.idcustomer

  --drop table if exists Analytics.dbo.report_collection_stages_by_customers_history
  --select * into Analytics.dbo.report_collection_stages_by_customers_history from #t

  delete from Analytics.dbo.report_collection_stages_by_customers_history
  insert into Analytics.dbo.report_collection_stages_by_customers_history
  select * from #t


  
 drop table if exists #t2
  select StageDate, StageName
  
      ,sum([ПризнакЭДО_срм]					 ) [ПризнакЭДО_срм]					
      ,sum([ПризнакЭДО_срм_электронно]		 ) [ПризнакЭДО_срм_электронно]		
      ,sum([ПризнакЭДО_срм_не_электронно]	 ) [ПризнакЭДО_срм_не_электронно]
      ,sum([ПризнакУВ]						 ) [ПризнакУВ]						
      ,sum([ПризнакУВ_электронно]			 ) [ПризнакУВ_электронно]			
      ,sum([ПризнакУВ_электронно_МП]		 ) [ПризнакУВ_электронно_МП]		
      ,sum([ПризнакУВ_электронно_десктоп]	 ) [ПризнакУВ_электронно_десктоп]
      ,sum([ПризнакУВ_не_электронно]         ) [ПризнакУВ_не_электронно]      
      ,max([created]) Min_created
  ,count(idCustomer) as ЧислоКлиентов
  into #t2
  
  from  Analytics.dbo.report_collection_stages_by_customers_history
  group by StageDate, StageName

  delete from  Analytics.dbo.report_collection_stages_by_customers_history_agr 
  insert into  Analytics.dbo.report_collection_stages_by_customers_history_agr 
  select *  from #t2

 -- drop table if exists  Analytics.dbo.report_collection_stages_by_customers_history_agr 
 --select * into  Analytics.dbo.report_collection_stages_by_customers_history_agr from #t2
   
   drop table if exists  #t3

  select cast(sms.sms_datetime as date) Sms_date , StageName, sms.CustomerId , sms.OperatorCallDate Sms_by_manager, sms.sms_id, 
  x.*, row_number()over (partition by sms.customerId, 
  cast(sms.sms_datetime as date) order by case when x.idcustomer is null then 0 else 1 end desc, sms.OperatorCallDate desc) rn_sms
  ,getdate() as created
  into #t3
  from #smsCommunications sms 
  
  outer apply (select top 1 * from Analytics.dbo.report_pep_details where report_pep_details.sms_id_uv=sms.sms_id) x
  left join Analytics.dbo.report_collection_stages_by_customers_history ch on ch.idCustomer=sms.CustomerId and cast(sms.sms_datetime as date)=ch.StageDate
   
   
   --drop table if exists  Analytics.dbo.report_pep_sms_details
   delete from Analytics.dbo.report_pep_sms_details
   insert into  Analytics.dbo.report_pep_sms_details
   select *   from #t3


  end

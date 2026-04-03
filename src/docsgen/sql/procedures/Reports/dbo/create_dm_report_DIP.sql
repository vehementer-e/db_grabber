

CREATE   procedure [dbo].[create_dm_report_DIP]
as
begin


drop table if exists #NaumenProjects_DokrNPovt_prod
select projectuuid into #NaumenProjects_DokrNPovt_prod from [Stg].[_mds].[NaumenProjects_DokrNPovt_prod]



--------------- report_DIP_obzvonennost

drop table if exists #t01
  SELECT 
    cast(stuff(phonenumbers, 1,1,'') as varchar(20)) phonenumbers, 
	cast(count(distinct cast(attempt_start as date)) as int) [В скольких днях ему звонили],

	cast(getdate() as datetime) as created
  into #t01
  FROM [NaumenDbReport].[dbo].[mv_call_case] cc left join 
       [NaumenDbReport].[dbo].[detail_outbound_sessions] dos on dos.case_uuid=cc.uuid
  where projectuuid in
  (select projectuuid from #NaumenProjects_DokrNPovt_prod) 
  and attempt_result is not null and attempt_start>getdate()-90 
  group by 	phonenumbers



  begin tran
delete from dbo.dm_report_DIP_obzvonennost

insert into   dbo.dm_report_DIP_obzvonennost
select * from #t01
commit tran
  

----------- report_DIP_otkazniki30dneycrm

drop table if exists #t11

  SELECT cast([Телефон] as varchar(20)) [Телефон] , cast(getdate() as datetime) created
  into #t11
  FROM [Stg].[_1cCRM].[Документ_CRM_Заявка] dz
  where  Дата>dateadd(yy, 2000, getdate()-30) and  причинаОтказа in
(
0x80EC00155D01BF0711E53FFEA00966AE,
0x80EC00155D01BF0711E53FFE55E7841B,
0x814E00155D01BF0711E844B0C9FD93DA,
0x814700155D01BF0711E76178B69BF15F,
0x80EC00155D01BF0711E578028181C542,
0x814700155D01BF0711E761789C44FAA3,
0x814700155D01BF0711E76176EFE1EB48,
0xB81800155D03492D11E9D86C90A982B6,
0x80E700155D01BF0711E50B368B7A3816,
0x814700155D01BF0711E761787D464BF3,
0x815300155D01BF0711E8696F9F70BE67,
0x80EC00155D01BF0711E53FFEBD1CE207,
0x80EC00155D01BF0711E5464E99AC67BA,
0x815300155D01BF0711E8697012603C2E,
0x80EC00155D01BF0711E54A705C4F3CEC,
0x80EC00155D01BF0711E578A2B037BE3A,
0x815400155D01BF0711E8C3040DD0BC40)


  begin tran
delete from dbo.dm_report_DIP_otkazniki30dneycrm

insert into   dbo.dm_report_DIP_otkazniki30dneycrm
select * from #t11
commit tran
  

----------- report_DIP_naumen14days6comp

drop table if exists #t21
  
  SELECT distinct 
  cast(stuff(phonenumbers, 1,1,'') as varchar(20)) as phonenumber1 
  , getdate() as created
  into #t21
  FROM [NaumenDbReport].[dbo].[mv_call_case] cc join 
       [NaumenDbReport].[dbo].[detail_outbound_sessions] dos on dos.case_uuid=cc.uuid
  where projectuuid in 
  (
  select projectuuid from #NaumenProjects_DokrNPovt_prod
   ) and attempt_result is not null and cast([attempt_start] as date)>cast(getdate()-14 as date) and phonenumbers<>''



  begin tran
delete from dbo.dm_report_DIP_naumen14days6comp

insert into   dbo.dm_report_DIP_naumen14days6comp
select * from #t21
commit tran


----------- create_dm_report_DIP_factoranalysis14days

drop table if exists #t31
  
  SELECT distinct cast([Телефон] as varchar(20)) Телефон, getdate() as created
  into #t31
  FROM [dbo].[dm_Factor_Analysis_001]
  where [ДатаЗаявкиПолная]>getdate()-15 and ([Признак Отказ документов клиента]=1 or [ПризнакОтказано]=1) and [Телефон]<>''


  begin tran
delete from dbo.dm_report_DIP_factoranalysis14days

insert into   dbo.dm_report_DIP_factoranalysis14days
select * from #t31
commit tran


----------- create_dm_report_DIP_factoranalysis14days_fio

drop table if exists #t41
  
  SELECT distinct cast(ФИО as varchar(40)) ФИО, getdate() as created
  into #t41
  FROM [dbo].[dm_Factor_Analysis_001]
  where [ДатаЗаявкиПолная]>getdate()-15 and ([Признак Отказ документов клиента]=1 or [ПризнакОтказано]=1) and [Телефон]<>''


  begin tran
delete from dbo.dm_report_DIP_factoranalysis14days_fio

insert into dbo.dm_report_DIP_factoranalysis14days_fio
select * from #t41
commit tran


----------- create_dm_report_DIP_pep

drop table if exists #t51

  SELECT distinct
    cast('ПЭП' as varchar(20)) as [Pep]
    ,cast([НомерПаспорта] as varchar(20))  as [НомерПаспорта]
    ,cast([СерияПаспорта] as varchar(20))  as [СерияПаспорта]
	,getdate() as created
  into #t51
  FROM [Stg].[_1cCRM].[РегистрСведений_СогласияНаЭлектронноеВзаимодействие] a left join 
       [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] b on a.[Клиент]=b.[Партнер]
  where [СерияПаспорта] is not null and [НомерПаспорта] is not null and [СерияПаспорта] <>'' and [НомерПаспорта] <>''


  begin tran
delete from dbo.dm_report_DIP_pep

insert into dbo.dm_report_DIP_pep
select * from #t51
commit tran


----------- create_dm_report_DIP_naumen14days2comp

drop table if exists #t61

  SELECT distinct
  cast(stuff(phonenumbers, 1,1,'') as varchar(20)) as phonenumber1
  ,getdate() as created
  into #t61
  FROM [feodor].[dbo].[dm_calls_history]
  where [attempt_start]  >cast(getdate()-14 as date) and speaking_time>2 and phonenumbers<>''
  


 begin tran

delete from dbo.dm_report_DIP_naumen14days2comp

insert into dbo.dm_report_DIP_naumen14days2comp
select * from #t61

commit tran


if OBJECT_ID(N'[dbo].[dm_report_DIP_feodor_calls_30_days]') is null

begin
	CREATE TABLE [dbo].[dm_report_DIP_feodor_calls_30_days] 
	( Телефон   [nvarchar](20) NULL
	, [created] [datetime]     NULL )
end

drop table if exists #t71


select phonenumbers    Телефон
,      getdate()    as created
	into #t71
from Feodor.dbo.dm_calls_history with(index=[NonClusteredIndex_attempt_start])
where attempt_start>= cast(getdate()-30 as date) and login is not null



begin tran

delete from dbo.[dm_report_DIP_feodor_calls_30_days]

insert into dbo.[dm_report_DIP_feodor_calls_30_days]
select * from #t71

commit tran



end

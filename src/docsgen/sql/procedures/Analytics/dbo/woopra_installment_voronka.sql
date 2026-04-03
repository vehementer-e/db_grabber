CREATE   proc [dbo].[woopra_installment_voronka] as

begin


-- declare @start_date date = getdate()-100

 --select min([UF_REGISTERED_AT день]) from report_leads_full


drop table if exists #TMP_leads
CREATE TABLE #TMP_leads(
	[ID] [numeric](10, 0) NULL,
	UF_REGIONS_COMPOSITE [varchar](128) NULL,
	[UF_PHONE] [varchar](128) NULL,
	[UF_CLID] [nvarchar](72) NULL
)


-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = '20150101', @End_Registered = getdate()
--SELECT @End_Registered = getdate()
--SELECT @Begin_Registered = dateadd(DAY, -100, @End_Registered)

SELECT @Begin_Registered, @End_Registered

TRUNCATE TABLE #TMP_leads


EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message




drop table if exists #f1

SELECT  a.[crib_lead_id]
      ,a.[Событие]
      ,a.[campaign_medium]
      ,a.[campaign_source]
      ,a.[Дата]
      ,a.[People]
	  ,UF_CLID.id leadid
	  ,UF_CLID.[UF_PHONE]
	  ,UF_CLID.UF_REGIONS_COMPOSITE
	 -- ,reg_mp.username
	  into #f1
  FROM [Analytics].[dbo].[_openrowset_installment выгрузка из вупры] a 
   join #TMP_leads UF_CLID on UF_CLID.UF_CLID=a.[crib_lead_id] --and UF_REGISTERED_AT>='20211210'
  --left join #reg_mp reg_mp on reg_mp.username=b.[crib_lead_id]
--  exec generate_select_table_script '[Analytics].[dbo].[_openrowset_installment выгрузка из вупры]'




 --select * from #f1
 --order by 1

-- select * from #f1
-- where crib_lead_id is not null
-- --select * from #v_dm_Factor_Analysis
drop table if exists #v_dm_Factor_Analysis

 select * into #v_dm_Factor_Analysis from v_dm_Factor_Analysis
 where Телефон in (select UF_PHONE from #f1 where UF_PHONE is not null) and ДатаЗаявкиПолная between '20211210' and '20211225' and isInstallment=1  --and ДатаЗаявкиПолная>='20211210'

 ;with v as (select *, ROW_NUMBER() over(partition by Телефон order by [Заем выдан] desc,Одобрено desc,[Контроль данных] desc, [Предварительное одобрение] desc, ДатаЗаявкиПолная desc  ) rn1 from #v_dm_Factor_Analysis ) delete from v where rn1>1

 
drop table if exists #reg_mp

SELECT distinct
      u.username username
      into #reg_mp
  FROM [Stg].[_LK].[register_mp] r   join stg._lk.users u on u.id=r.user_id and u.username in (select UF_PHONE from #f1 where UF_PHONE is not null)


drop table if exists [#f_voronka]


 CREATE TABLE [dbo].[#f_voronka](      [crib_lead_id] [NVARCHAR](255)    , [Событие] [NVARCHAR](255)    , [Дата] date    , [campaign_medium] [NVARCHAR](255)    , [campaign_source] [NVARCHAR](255)    , [People] [FLOAT]    , [leadid] [NUMERIC]    , [uf_phone] [VARCHAR](128));


insert into [#f_voronka]
select 
[crib_lead_id] 
,[Событие] 
,[Дата] 
,[campaign_medium] 
,[campaign_source] 
,[People] 
,[leadid] 
,[uf_phone] 
from 
#f1 


insert into [#f_voronka]


select null [crib_lead_id],
       'Заявка' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where ДатаЗаявкиПолная is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'Заявка' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where ДатаЗаявкиПолная is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'Предварительное одобрение' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where [Предварительное одобрение] is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'Контроль данных' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where [Контроль данных] is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'Одобрено' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where Одобрено is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'Одобрено чекеры' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where [Одобрено чекеры] is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'call2 accept' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where [call2 accept] is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'заем выдан' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where [заем выдан] is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'Отказ Carmoney' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       телефон [uf_phone]
from #v_dm_Factor_Analysis
where [Отказ Carmoney] is not null

insert into [#f_voronka]

select null [crib_lead_id],
       'Признак регистрация в МП' [Событие],
       null [Дата],
       null [campaign_medium],
       null [campaign_source],
       null [People],
       null [leadid],
       username [uf_phone]
from #reg_mp



select isnull(uf_phone , [crib_lead_id]) client

, min(Дата) as Дата
, max([campaign_medium]) as [campaign_medium]
, max([campaign_source]) as [campaign_source]
, max(case when [uf_phone] is not null then 1 else 0 end) as [Лид ЛСРМ]
, max(case when [Событие] = 'i-1-click-na-sozdanie-lida' then 1 else 0 end) as [i-1-click-na-sozdanie-lida]
, max(case when [Событие] = 'i-3-zayavka-otpravlena' then 1 else 0 end) as [i-3-zayavka-otpravlena]
, max(case when [Событие] = 'i-2-smsconfirm' then 1 else 0 end) as [i-2-smsconfirm]
, max(case when [Событие] = 'i-1-lid-sozdan' then 1 else 0 end) as [i-1-lid-sozdan]
, max(case when [Событие] = 'i-3-click-otpravka-zayavki' then 1 else 0 end) as [i-3-click-otpravka-zayavki]
, max(case when [Событие] = 'Заявка' then 1 else 0 end) as [Заявка]
, max(case when [Событие] = 'Предварительное одобрение' then 1 else 0 end) as [Предварительное одобрение]
, case when max(case when [Событие] = 'Признак регистрация в МП' then 1 else 0 end)+max(case when [Событие] = 'Предварительное одобрение' then 1 else 0 end) = 2 then 1   else 0 end as [Признак регистрация в МП]
, max(case when [Событие] = 'Контроль данных' then 1 else 0 end) as [Контроль данных]
, max(case when [Событие] = 'Одобрено чекеры' then 1 else 0 end) as [Одобрено чекеры]
, max(case when [Событие] = 'call2 accept' then 1 else 0 end) as [call2 accept]
, max(case when [Событие] = 'Одобрено' then 1 else 0 end) as [Одобрено]
, max(case when [Событие] = 'заем выдан' then 1 else 0 end) as [заем выдан]
, max(case when [Событие] = 'Отказ Carmoney'  then 1 else 0 end) as [Отказ Carmoney]
, max(UF_REGIONS_COMPOSITE) as UF_REGIONS_COMPOSITE
from [#f_voronka] a
left join (select UF_PHONE UF_PHONE_region,  max(UF_REGIONS_COMPOSITE) UF_REGIONS_COMPOSITE from #f1 group by UF_PHONE ) reg on reg.UF_PHONE_region=a.uf_phone
group by  isnull(uf_phone , [crib_lead_id])
order by  isnull(uf_phone , [crib_lead_id])

select distinct ', max(case when [Событие] = '''+cast([Событие] as varchar(max))+''' then 1 else 0 end) as ['+[Событие]+']' 
from [#f_voronka]

 -- exec [dbo].[generate_select_table_script] '#f'
 -- exec [dbo].[generate_create_table_script] '#f1'

--drop table if exists #f1


end


-- =============================================
-- Author:		
-- Create date: 2019-10-17
-- Description:	
-- exec [dbo].[report_Factor_Analysis_001]   1

-- =============================================
CREATE   PROCEDURE [dbo].[report_Factor_Analysis_001]
	
	@recreate_table int= 0
	
AS

BEGIN

	--SET NOCOUNT ON;
	SET XACT_ABORT  ON;

	Declare @dtDateDegin datetime = '4019-01-01T00:00:00'
	Declare @dtDateDegin2000 datetime = '2019-01-01T00:00:00'
	Declare @dtDateReport datetime = GetDate()




drop table if exists #Документ_ЗаявкаНаЗаймПодПТС
select номер
,      Ссылка
,      Статус
,      Дата 
,      МобильныйТелефон
,      [СуммаРекомендуемая]
,      ОдобреннаяСуммаВерификаторами
,      Имя
,      НомерПаспорта
,      СуммаПервичная
,      Сумма
,      [СуммаВыданная]
,      СпособОформления
,      CRM_Автор
,      ПричинаОтказа 
,      Лид 
,      Докредитование 
,      ВидЗайма 
,      ВидЗаявки 
,      АдресПроживания 
,      КредитныйПродукт 
,      СпособВыдачиЗайма 
,      Фамилия 
,      Отчество 
,      Офис 
,      Партнер 
,      case when Инстолмент=1 then 1 else 0 end isInstallment
,      case when СмартИнстолмент=1 then 1 else 0 end isSmartInstallment
,      case when ПДЛ=1 then 1 else 0 end isPDL
,      РыночнаяОценкаСтоимости
,      ВариантПредложенияСтавки
,      case when ИспытательныйСрок=1 then 1 else 0 end [Испытательный Срок]
,     [СуммарныйМесячныйДоход]
,     СрокЛьготногоПериода




into #Документ_ЗаявкаНаЗаймПодПТС
from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
where Дата >= @dtDateDegin
and ссылка<>0x9D2EC3DD423AF06C4CA20B176BC7BD5B





--select a.НомерЗаявки, a.ДатаЗаявки, a.Офис, b.UF_STAT_CAMPAIGN,c.*, o.* 


drop table if exists #leadRef1_buffer
select * into #leadRef1_buffer from stg.[files].[leadRef1_buffer] [leadRef1_buffer]

drop table if exists #exc
select * into #exc from stg.files.channelrequestexceptions_buffer_stg

--select * from #exc

drop table if exists #Справочник_офисы
select Ссылка, Родитель, Наименование, Код , Партнер into #Справочник_офисы from stg._1cCRM.Справочник_Офисы

drop table if exists [#РегистрСведений_ИзмененияВидаЗаполненияВЗаявках]
select Заявка, Офис, ДатаИзменения into  [#РегистрСведений_ИзмененияВидаЗаполненияВЗаявках]
FROM [Stg].[_1cCRM].[РегистрСведений_ИзмененияВидаЗаполненияВЗаявках]

drop table if exists [#Справочник_Партнеры]
select Ссылка, Наименование into [#Справочник_Партнеры] 
from [Stg].[_1cCRM].[Справочник_Партнеры] a
join (select distinct Партнер from #Справочник_офисы ) b on a.Ссылка=b.Партнер

drop table if exists [#Движение заявки по точка]


;

	  with v as(
select a.Заявка, a.Офис [Офис при создании], o.Партнер [Партнер при создании], ozz_p.Наименование [Юрлицо при создании], o.Код [Номер точки при создании], ROW_NUMBER() over(partition by Заявка order by ДатаИзменения) rn 
, max(case when o.код = 3645 then 1 else 0 end)  over(partition by Заявка) [Признак переключение на точку рефинансирования]
from [#РегистрСведений_ИзмененияВидаЗаполненияВЗаявках] a
left join #Справочник_офисы o on a.Офис=o.Ссылка
left join [#Справочник_Партнеры] ozz_p on o.Партнер=ozz_p.Ссылка

)
select v.*, [TransitionsJSON] into [#Движение заявки по точка] 
from v
left join
(
select Заявка
, '['+STRING_AGG('{"p":"'+cast(o.код as nvarchar(max))+'" ,"d":"'+format(dateadd(year, -2000, ДатаИзменения), 'yyyy-MM-dd HH:mm:ss' )  +'"}', ',') within group(order by ДатаИзменения)+']' [TransitionsJSON]
  from [#РегистрСведений_ИзмененияВидаЗаполненияВЗаявках] a
left join #Справочник_офисы o on a.Офис=o.Ссылка
group by Заявка
) x on x.Заявка=v.Заявка
where rn=1

;



drop table if exists #R_t_lcrm;


--exec analytics.dbo.create_table '#R_t_lcrm'


CREATE TABLE [dbo].[#R_t_lcrm]
(
      [ID] [NUMERIC]
    , [UF_ACTUALIZE_AT] [DATETIME2](7)
    , [UF_UPDATED_AT] [DATETIME2](7)
    , [UF_ROW_ID] [VARCHAR](128)
    , [Канал от источника] [NVARCHAR](255)
    , [UF_SOURCE] [VARCHAR](128)
    , [UF_PARTNER_ID] [NVARCHAR](256)
    , [UF_LOGINOM_PRIORITY] [INT]
    , [UF_STAT_AD_TYPE] [VARCHAR](128)
    , [UF_STAT_CAMPAIGN] [VARCHAR](512)
    , [UF_TYPE] [VARCHAR](128)
    , [marketing_lead_id] [NVARCHAR](36)
    , [original_lead_id] [NVARCHAR](36)
);

  insert 

		into #R_t_lcrm

SELECT 
		  lcrm.ID
		, UF_ACTUALIZE_AT
		, UF_UPDATED_AT
		, UF_ROW_ID 
		,lcrm.[Канал от источника] [Канал от источника]
		--,isnull(b.[Канал от источника], lcrm.[Канал от источника]) [Канал от источника]
		
		--,[Группа каналов]
		,UF_SOURCE
		,[UF_PARTNER_ID]
		,[UF_LOGINOM_PRIORITY]
		,UF_STAT_AD_TYPE
		,UF_STAT_CAMPAIGN
		,UF_TYPE
		, cast(null as nvarchar(50)) lead_id
		, cast(null as nvarchar(50)) lead_id
from   [Stg].[_LCRM].lcrm_leads_full_channel_request lcrm  --(nolock) 
--left join ##t2 b on lcrm.ID=b.id
--where UF_ROW_ID is not null

insert into #R_t_lcrm
select null , 
r.created_at_time	   ,
lead.updated_at_time ,
r.number,  
mms_channel.name, 
source_account.name source_name	,
lead.partner_id	,
lead.mms_priority	,
v.stat_type  UF_STAT_AD_TYPE ,
v.STAT_CAMPAIGN  UF_STAT_CAMPAIGN ,
lead.type_code  UF_TYPE,
lead.id marketing_lead_id	,
r.original_lead_id 


from stg._lf.request  r
left join   stg._lf.[lead]	[lead]  on r.marketing_lead_id=lead.id
--left join stg._lf.status on status.id=lead.status_id
left join stg._lf.mms_channel on mms_channel.id=lead.mms_channel_id
--left join stg._lf.mms_channel_group on mms_channel_group.id=lead.mms_channel_group_id
left join stg._lf.source_account on source_account.id=lead.source_id
--left join stg._lf.entrypoint e on e.id=lead.id
--left join stg._lf.mms_decision d on d.lead_id=lead.id
--left join stg._lf.mms_decision_type  dt on dt.id=d.mms_decision_type_id 
--left join stg._lf.product_type pt on pt.id=lead.product_type_id
--left join stg._lf.region r on r.id=lead.region_id 
--left join stg._lf.mms_decline_reason  dc on dc.id=lead.mms_decline_reason_id 
left join stg._lf.referral_visit v on v.id=lead.visit_id
--left join stg._lf.referral_appmetrica_event  va on  va.id=v.appmetrica_event_id





;

	  with v as(
select ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn , *  from #R_t_lcrm
)
delete from v where rn>1



drop table if exists #analytics_mfo_channels

 SELECT [Номер]
--,[leadRef1_buffer].[Группа каналов]
--,b.[Канал от источника]
,[ПризнакОформленияНовойЗаявки]
,ROW_NUMBER() over(partition by [ПризнакОформленияНовойЗаявки] order by [Номер]) rn
into #analytics_mfo_channels
FROM [Stg].[_1cMFO].[Отчет_ВсеЗаявкиДляАналитика] a
left join #R_t_lcrm b on a.Номер=b.UF_ROW_ID
--where Дата<='40240425'
--left join #leadRef1_buffer leadRef1_buffer on leadRef1_buffer.[Канал от источника]=b.[Канал от источника] 

and isnumeric([ПризнакОформленияНовойЗаявки])=1 

--select * from 	 [Stg].[_1cMFO].[Отчет_ВсеЗаявкиДляАналитика] a
--select * from 	#analytics_mfo_channels
--order by 1 desc

--0x86F095057EE441374ED9630AAADAB049	ВводОператорамиFEDOR	Ввод операторами FEDOR
--0x8BA13AF32784DFCF47D0B66E1C0E387B	ОформлениеНаКлиентскомСайте	Оформление на клиентском сайте
--0xA38F9540D79F9A474EFA2DADFA09ADA0	ВводОператорамиСтороннегоКоллЦентра	Ввод операторами стороннего КЦ
--0xA4867DD77BFA558846A2BF34FB1CABA9	ВводОператорамиКоллЦентра	Ввод операторами КЦ
--0xA7329507D134CC744546A4BD7D428B6C	ОформлениеНаПартнерскомСайте	Оформление на партнерском сайте
--0xA79A95ADE4F2CF7742DF36CE7B806AA5	ОформлениеВМобильномПриложении	Оформление в мобильном приложении
--0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D	ВводОператорамиLCRM	Ввод операторами LCRM


drop table if exists #real_channel

select z.номер, способоформления, 
case

when [#Движение заявки по точка].[Юрлицо при создании]= 'Общество с ограниченной ответственностью "МодульПартнер"' then 'Модуль'
when [#Движение заявки по точка].[Юрлицо при создании]= 'АО Ингосстрах Банк' then 'Союз'
when способоформления = 0xA7329507D134CC744546A4BD7D428B6C then 'Оформление на партнерском сайте'
--when isnull(l.[Канал от источника] , '') in ('Сайт орган.трафик', 'Канал привлечения не определен - КЦ', 'Канал привлечения не определен - МП', 'Тест', 'Другое') and isnull(true_chanel.[Канал от источника] , '') not in  ('', 'Сайт орган.трафик', 'Канал привлечения не определен - КЦ', 'Канал привлечения не определен - МП', 'Тест', 'Другое') then true_chanel.[Канал от источника]
when isnull(l.[Канал от источника] , '')  in ('Тест', 'Другое') then  'Канал привлечения не определен - КЦ'
when l.[Канал от источника] is not null then l.[Канал от источника]
when способоформления in (0xA4867DD77BFA558846A2BF34FB1CABA9, 0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D, 0x86F095057EE441374ED9630AAADAB049, 0xA38F9540D79F9A474EFA2DADFA09ADA0, 0x00000000000000000000000000000000)  then 'Канал привлечения не определен - КЦ'
when способоформления in ( 0xA79A95ADE4F2CF7742DF36CE7B806AA5,0x8BA13AF32784DFCF47D0B66E1C0E387B)  then 'Канал привлечения не определен - МП' 
else 'Канал привлечения не определен - КЦ' end [Канал от источника]
, ROW_NUMBER() over(partition by z.номер order by id desc) rn
,l.[Канал от источника] [Канал от источника лид]
,l.id
,UF_SOURCE
,UF_STAT_CAMPAIGN
,UF_TYPE
,[UF_PARTNER_ID]
		,[UF_LOGINOM_PRIORITY]
, [Exceptions info] = 	case
when [#Движение заявки по точка].[Юрлицо при создании]= 'Общество с ограниченной ответственностью "МодульПартнер"' then ''
when [#Движение заявки по точка].[Юрлицо при создании]= 'АО Ингосстрах Банк' then ''
when способоформления = 0xA7329507D134CC744546A4BD7D428B6C then ''
--when isnull(l.[Канал от источника] , '') in ('Сайт орган.трафик', 'Канал привлечения не определен - КЦ', 'Канал привлечения не определен - МП', 'Тест', 'Другое') and isnull(true_chanel.[Канал от источника] , '') not in  ('', 'Сайт орган.трафик', 'Канал привлечения не определен - КЦ', 'Канал привлечения не определен - МП', 'Тест', 'Другое') then '/Канал(перезав.)/'
when isnull(l.[Канал от источника] , '')  in ('Тест', 'Другое') then  ''
when l.[Канал от источника] is not null then ''
when способоформления in (0xA4867DD77BFA558846A2BF34FB1CABA9, 0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D, 0x86F095057EE441374ED9630AAADAB049, 0xA38F9540D79F9A474EFA2DADFA09ADA0, 0x00000000000000000000000000000000)  then ''
when способоформления in ( 0xA79A95ADE4F2CF7742DF36CE7B806AA5,0x8BA13AF32784DFCF47D0B66E1C0E387B)  then '' 
else '' end    ,
marketing_lead_id,
original_lead_id
into #real_channel
from #Документ_ЗаявкаНаЗаймПодПТС z
left join #R_t_lcrm l on z.Номер=l.uf_row_id
--left join #analytics_mfo_channels true_chanel on true_chanel.ПризнакОформленияНовойЗаявки=z.Номер and true_chanel.rn=1
left join [#Движение заявки по точка]  on [#Движение заявки по точка].Заявка=z.Ссылка
delete from #real_channel where rn>1
 

drop table if exists #return_types
create table #return_types (external_id nvarchar(50), return_type nvarchar(50), ПриоритетИсточника smallint)
insert into #return_types
--select external_id, return_type return_type, 2 as ПриоритетИсточника  from [dwh_new].[dbo].[tmp_v_requests]
select external_id, return_type return_type, 2 as ПриоритетИсточника
	from dwh2.dbo.dm_return_type_old_data

insert into #return_types
select cast(number as nvarchar(20)) number, return_type, 1 as ПриоритетИсточника  from dwh_new.dbo.risk_apr_segment
where isnumeric(number)=1
insert into #return_types
select номер, 
case when Докредитование=0xB3603565B63EB9B14723A40BFBC73122 then N'Докредитование'  -- Докредитование
	 when Докредитование=0xA8424EE85197CF54453F1F80BDC849D5 then N'Параллельный' -- Параллельный заем
	 when [ВидЗайма]=0x974A656AFB7A557B48A6B58E3DECA593     then N'Первичный' -- Новый
	 when [ВидЗайма]=0xB201F1B23D6AB42947A9828895F164FE     then N'Повторный'
	 else N'' end return_type,
	 3 as ПриоритетИсточника
from #Документ_ЗаявкаНаЗаймПодПТС ВсеЗаявки
where isnumeric(номер)=1
;
with v  as (select *, row_number() over(partition by external_id order by (select ПриоритетИсточника)) rn from #return_types ) delete from v where rn>1


drop table if exists #requests_with_cp

select  a.Ссылка Ссылка -- a.*, b.Наименование 
into #requests_with_cp
from  stg._1ccrm.Документ_ЗаявкаНаЗаймПодПТС_ДопУслуги  a 
 join stg._1ccrm.Справочник_ДополнительныеУслуги b on a.ДопУслуга=b.ссылка and снижаетставку=1 and Включена=1


drop table if exists #loginom_sum_apr

select a.Ссылка, case when r_wcp.Ссылка is not null then z_s_kp.Сумма else z_bez_kp.Сумма end [Одобренная сумма Логином]
into #loginom_sum_apr
from 
#Документ_ЗаявкаНаЗаймПодПТС a
left join stg._1ccrm.Справочник_КредитныеПродукты b               on a.КредитныйПродукт=b.Ссылка
left join stg._1ccrm.РегистрСведений_ВариантыСуммЛогином z_bez_kp on z_bez_kp.Заявка=a.Ссылка and z_bez_kp.СнижаетСтавку=0 and b.КодДлительностиПродукта=z_bez_kp.Срок
left join stg._1ccrm.РегистрСведений_ВариантыСуммЛогином z_s_kp on z_s_kp.Заявка=a.Ссылка and z_s_kp.СнижаетСтавку=1and b.КодДлительностиПродукта=z_s_kp.Срок
left join #requests_with_cp r_wcp on r_wcp.Ссылка=a.Ссылка
where isnull(z_s_kp.Сумма , z_bez_kp.Сумма ) is not null


;
with v  as (select *, row_number() over(partition by Ссылка order by (select 1)) rn from #loginom_sum_apr ) delete from v where rn>1

drop table if exists #P2P 
--- получим все выданные займы по P2P
select number, dateadd(hour, 3, dateadd(year, 0, created_at)) as ДатаВыдачи, [sum_contract] 
into #P2P
from
 [Stg].[_p2p].[requests] r
  where r.[request_status_guid] in (
'de5722f1-9178-466a-88bc-1a1282728752'--	Погашен
,'81079828-9834-4614-9825-84b646938758'--	Заем выдан
);
 -- select * from #P2P

 
-- Общая временная таблица для учета переходов статусов заявок
drop table  if exists #R_t_source;

create table #R_t_source
(НомерЗаявки  nvarchar(100) null
,[Дата] datetime null
,[ДатаЗаявки] nvarchar(100) null
,[ВремяЗаявки] nvarchar(100) null
,[ТекущийСтатус] nvarchar(100) null
,[СпособОформления] nvarchar(100) null
,[Автор] nvarchar(100) null
,[ПричинаОтказа] nvarchar(800) null
,[Верификация КЦ] datetime null
,[Предварительное одобрение] datetime null 
,[Встреча назначена] datetime null
,[Одобрено] datetime null
,[Контроль данных] datetime null
,Call2 datetime null
,[Call2 accept] datetime null
,[Заем выдан] datetime null 
,[Заем выдан CRM] datetime null 
,[Верификация документов клиента] datetime null 
,[Одобрены документы клиента] datetime null 
,[Верификация документов] datetime null 
,[Договор зарегистрирован] datetime null 
,[Заем погашен] datetime null 
,[Заем аннулирован] datetime null 
,[Аннулировано] datetime null 
,[Отказ документов клиента] datetime null 
,[Отказано] datetime null 
,[Отказ клиента] datetime null 
,[Забраковано] datetime null 
,[Договор подписан] datetime null 
,[P2P] datetime null 
--,[LCRM_ID] nvarchar(250) null 
,[СуммаЗаявки] numeric(15) null
,[СуммаЗаявкиПервичная] numeric(15) null
,[СуммаЗаявкиОдобренная] numeric(15) null
,[СуммаЗаявкиВыданная] numeric(15) null
,[СуммаЗаявкиВыданнаяP2P] numeric(15) null
--,[КаналПривлеченияСтрокой] nvarchar(100) null
--,[Ссылка_ЛидКанал] binary(16) null
,[Телефон] nvarchar(100) null 
--,[Докредитование] binary(16) null
,[ВидЗаявки] binary(16) null
--,[ВидЗайма] binary(16) null
--,[ЗаявкиЛид] binary(16) null
,[ЗаявкиСсылка] binary(16) null
,[Офис] binary(16) null
,[Офис_CRM] binary(16) null
,[Партнер] binary(16) null
,[АдресПроживания] nvarchar(150) null
,[КредитныйПродукт] binary(16) null
,[СпособВыдачиЗайма] binary(16) null
--,[ДатаСозданияНаСайте] datetime null 
,[ФИО] nvarchar(150) null
,ПорядковыйНомерХорошегоСтатуса int null
,ПорядковыйНомерПлохогоСтатуса int null
,[Вид займа_дедупликация] nvarchar(50) null
,[Вид займа] nvarchar(max) null
,isInstallment smallint null
,isSmartInstallment smallint null
,[Испытательный Срок] smallint null
,[Канал от источника] nvarchar(255) null
,[РыночнаяОценкаСтоимости] numeric(15,0)
,[Exceptions info] nvarchar(255) null
,[Юрлицо при создании] nvarchar(150) null
,[Номер точки при создании] nvarchar(4) null
,[Признак Рефинансирование] smallint null
,TransitionsJSON nvarchar(max) null
,      ВариантПредложенияСтавки	 binary(16) null
, [СуммарныйМесячныйДоход] numeric(15) null
,isPDL smallint null
,СрокЛьготногоПериода smallint null
,source varchar(128)


);



-- with status_req as (
--select заявка                            
--,      Статус                            
--,      dateadd(year, -2000, min(Период )) Период
--from stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС 
--group by заявка
--,        Статус
-- )


 insert into #R_t_source
 select 
 z.Номер as НомерЗаявки
, dateadd(year, -2000, z.Дата ) as Дата
, convert(varchar, dateadd(year,-2000,z.Дата) , 104) [ДатаЗаявки] 
, convert(varchar, z.Дата , 108)  'ВремяЗаявки' 
, st.Наименование ТекущийСтатус
, so.[Представление] as СпособОформления
,  Users.Наименование as Автор
,  po.НаименованиеПолное as [ПричинаОтказа] 
			, sis.[Верификация КЦ] as 'Верификация КЦ'-- c1.период as 'Верификация КЦ'
			, sis.[Предварительное одобрение] as 'Предварительное одобрение'--c3.Период as 'Предварительное одобрение'
			, sis.[Встреча назначена] as 'Встреча назначена'--c4.Период as 'Встреча назначена'
			, sis.[Одобрено] as 'Одобрено'--c6.Период as 'Одобрено' 
			, sis.[Контроль данных] as 'Контроль данных'--c5.Период as 'Контроль данных' 
			, sis.Call2	Call2
			, sis.[Call2 accept]  [Call2 accept]
			, isnull(p2p.ДатаВыдачи, sis.[Заем выдан]) as 'Заем выдан' --isnull(p2p.ДатаВыдачи, c2.Период) as 'Заем выдан'
			, sis.[Заем выдан] 'Заем выдан CRM' --c2.Период as 'Заем выдан CRM'  -- чтобы понять, что выдачи в CRM не было и дата в CMR фиктивная
			, sis.[Верификация документов клиента] as 'Верификация документов клиента'--c7.Период as  'Верификация документов клиента'
			, sis.[Одобрены документы клиента] as 'Одобрены документы клиента'--c8.Период as  'Одобрены документы клиента'
			, sis.[Верификация документов] as 'Верификация документов'--c9.Период as  'Верификация документов'
			, sis.[Договор зарегистрирован] as 'Договор зарегистрирован'--c10.Период as 'Договор зарегистрирован'
			, sis.[Заем погашен] as 'Заем погашен'--c11.Период as 'Заем погашен'
			, sis.[Заем аннулирован] as 'Заем аннулирован'--c12.Период as 'Заем аннулирован'
			, sis.[Аннулировано] as 'Аннулировано'--c13.Период as 'Аннулировано'
			, sis.[Отказ документов клиента] as 'Отказ документов клиента'--c14.Период as 'Отказ документов клиента'
			, sis.[Отказано] as 'Отказано'--c15.Период as 'Отказано'
			, sis.[Отказ клиента] as 'Отказ клиента'--c16.Период as 'Отказ клиента'
			, sis.[Забраковано] as 'Забраковано'--c17.Период as 'Забраковано'
			, sis.[Договор подписан] as 'Договор подписан'--c18.Период as 'Договор подписан'
			, sis.[P2P] as 'P2P'--c19.Период as 'P2P'
     --       , cast(Лид.Метка_LeadId as nvarchar(250)) as [LCRM_ID]
            , z.Сумма as [СуммаЗаявки]
			, z.[СуммаПервичная] as [СуммаЗаявкиПервичная]
			, case when sis.[Одобрено] is not null then--case when c6.Период is not null then 
														case when lsa.[Одобренная сумма Логином] is not null then lsa.[Одобренная сумма Логином]
														     when ОдобреннаяСуммаВерификаторами=0 then iif(z.[СуммаРекомендуемая]>1000000,1000000,z.[СуммаРекомендуемая]) 
														     when ОдобреннаяСуммаВерификаторами>0 then iif(z.ОдобреннаяСуммаВерификаторами>1000000,1000000,z.ОдобреннаяСуммаВерификаторами) 
															 end
			       else 0 end
			
			
			as [СуммаЗаявкиОдобренная]
			, z.[СуммаВыданная] as [СуммаЗаявкиВыданная]
			, p2p.sum_contract as  [СуммаЗаявкиВыданнаяP2P]
			
--			, Лид.[КаналПривлеченияСтрокой] as  [КаналПривлеченияСтрокой]
--			, Лид.КаналПривлечения as [Ссылка_ЛидКанал]
			--, isnull(iif(len(z.МобильныйТелефон)<10,null,z.МобильныйТелефон) , Лид.Телефон) Телефон
			, isnull(try_cast(try_cast(exc_phone.Телефон as bigint) as nvarchar(10)),z.МобильныйТелефон)  Телефон
		--	, z.Докредитование  as Докредитование 
            , z.[ВидЗаявки]  as [ВидЗаявки]
      --      , z.[ВидЗайма]  as [ВидЗайма]
					--	, z.Лид ЗаявкиЛид
			, z.Ссылка ЗаявкиСсылка
			, z.Офис as [Офис]
			, z.Офис as [Офис_CRM]
			, z.Партнер as [Партнер]
			, z.[АдресПроживания] as [АдресПроживания]
, z.[КредитныйПродукт] as [КредитныйПродукт]
, z.[СпособВыдачиЗайма] as [СпособВыдачиЗайма]
--, Лид.[ДатаСозданияНаСайте] as [ДатаСозданияНаСайте]
, RTRIM(cast(z.Фамилия as varchar(20))) + ' ' + RTRIM(cast(z.Имя as varchar(20))) + ' ' + RTRIM(cast(z.Отчество as varchar(20))) as  [ФИО] 
,case 
when isnull(p2p.ДатаВыдачи, sis.[Заем выдан])  is not null then 10 --заем выдан
when sis.[договор подписан] is not null then 9 --договор подписан
when sis.[Договор зарегистрирован] is not null then 8 --Договор зарегистрирован
when sis.[Одобрено] is not null then 7 --Одобрено
when sis.[Верификация документов] is not null then 6 --Верификация документов
when sis.[Одобрены документы клиента] is not null then 5 --Одобрены документы клиента
when sis.[Верификация документов клиента] is not null then 4 --Верификация документов клиента
when sis.[Контроль данных] is not null then 3 --Контроль данных
when sis.[Предварительное одобрение] is not null then 2 --Предварительное одобрение
else 1 end as ПорядковыйНомерХорошегоСтатуса
 ,case 
when sis.[Отказано] is not null then 5 --Отказано
when sis.[ОТказ документов клиента] is not null then 4 --ОТказ документов клиента
when sis.[Отказ клиента] is not null then 3 --Отказ клиента
when sis.[Заем Аннулирован] is not null then 2 --ЗаемАннулирован
when sis.[Аннулировано] is not null then 1 --Аннулировано

else 6 end as ПорядковыйНомерПлохогоСтатуса
--,case 
--when isnull(p2p.ДатаВыдачи, c2.Период) is not null then 10 --заем выдан
--when c18.Период is not null then 9 --договор подписан
--when c10.Период is not null then 8 --Договор зарегистрирован
--when c6.Период is not null then 7 --Одобрено
--when c9.Период is not null then 6 --Верификация документов
--when c8.Период is not null then 5 --Одобрены документы клиента
--when c7.Период is not null then 4 --Верификация документов клиента
--when c5.Период is not null then 3 --Контроль данных
--when c3.Период is not null then 2 --Предварительное одобрение
--else 1 end as ПорядковыйНомерХорошегоСтатуса
-- ,case 
--when c15.Период is not null then 5 --Отказано
--when c14.Период is not null then 4 --ОТказ документов клиента
--when c16.Период is not null then 3 --Отказ клиента
--when c12.Период is not null then 2 --ЗаемАннулирован
--when c13.Период is not null then 1 --Аннулировано
--
--else 6 end as ПорядковыйНомерПлохогоСтатуса
,case when isnull(return_types.[return_type], 'Первичный') ='Первичный' then isnull(return_types.[return_type], 'Первичный') else 'Повторный' end as [Вид займа_дедупликация]
,isnull(return_types.[return_type], 'Первичный') as [Вид займа]
,z.isInstallment
,z.isSmartInstallment
,z.[Испытательный Срок]
,r_ch.[Канал от источника]
,nullif([РыночнаяОценкаСтоимости] , 0) [РыночнаяОценкаСтоимости]
, [Exceptions info] = r_ch.[Exceptions info]+case when exc_phone.телефон is not null then '/Изменен некорректный телефон/' else '' end
, ozz.[Юрлицо при создании]
, ozz.[Номер точки при создании]
, [Признак Рефинансирование] = case when z.Офис = 0xA2EE00505683924B11EA84B0C7D61A32 /* 3645 id точки рефинансирования*/ or ozz.[Признак переключение на точку рефинансирования]=1 then 1 else 0 end
, ozz.TransitionsJSON
, ВариантПредложенияСтавки
, z.[СуммарныйМесячныйДоход]
, z.isPDL
, z.[СрокЛьготногоПериода]
, r_ch.UF_SOURCE source
 from 
 #Документ_ЗаявкаНаЗаймПодПТС z
 left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] st with (nolock) on st.Ссылка = z.Статус
 left join [Stg].[_1cCRM].Перечисление_СпособыОформленияЗаявок so with (nolock) on so.ссылка = z.СпособОформления
 left join [Stg].[_1cCRM].[Справочник_Пользователи] Users on Users.Ссылка = z.[CRM_Автор]
 left join [Stg].[_1cCRM].[Справочник_CRM_ПричиныОтказов] po on po.Ссылка = z.ПричинаОтказа
 left join dwh2.[dm].[v_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия]	sis on sis.НомерЗаявки=z.Номер 
-- left join status_req C1  on z.ссылка=C1 .Заявка  and C1 .Статус=0xa81400155d94190011e80784923c60a2 -- Верификация КЦ
-- left join status_req C2  on z.ссылка=C2 .Заявка  and C2 .Статус=0xa81400155d94190011e80784923c6097 -- Заем выдан
-- left join status_req C3  on z.ссылка=C3 .Заявка  and C3 .Статус=0xa81400155d94190011e80784923c60a3 -- Предварительное одобрение
-- left join status_req C4  on z.ссылка=C4 .Заявка  and C4 .Статус=0x80E400155D64100111E7BC98DDDF0D76 -- Встреча назначена
-- left join status_req C5  on z.ссылка=C5 .Заявка  and C5 .Статус=0xA81400155D94190011E80784923C609A -- Контроль данных
-- left join status_req C6  on z.ссылка=C6 .Заявка  and C6 .Статус=0xA81400155D94190011E80784923C609B -- Одобрено
-- left join status_req C7  on z.ссылка=C7 .Заявка  and C7 .Статус=0xA81400155D94190011E80784923C6093 -- Верификация документов клиента
-- left join status_req C8  on z.ссылка=C8 .Заявка  and C8 .Статус=0xA81400155D94190011E80784923C609C -- Одобрены документы клиента
-- left join status_req C9  on z.ссылка=C9 .Заявка  and C9 .Статус=0xA81400155D94190011E80784923C6092 -- Верификация документов
-- left join status_req C10 on z.ссылка=C10.Заявка  and C10.Статус=0xA81400155D94190011E80784923C6094 -- Договор зарегистрирован
-- left join status_req C11 on z.ссылка=C11.Заявка  and C11.Статус=0xA81400155D94190011E80784923C6098 -- Заем погашен
-- left join status_req C12 on z.ссылка=C12.Заявка  and C12.Статус=0xA81400155D94190011E80784923C6096 -- Заем аннулирован
-- left join status_req C13 on z.ссылка=C13.Заявка  and C13.Статус=0xA81400155D94190011E80784923C6099 -- Аннулировано
-- left join status_req C14 on z.ссылка=C14.Заявка  and C14.Статус=0xA81400155D94190011E80784923C609D -- Отказ документов клиента
-- left join status_req C15 on z.ссылка=C15.Заявка  and C15.Статус=0xA81400155D94190011E80784923C609E -- Отказано
-- left join status_req C16 on z.ссылка=C16.Заявка  and C16.Статус=0x80E600155D64100111E85E62C3BC1512 -- Клиент передумал
-- left join status_req C17 on z.ссылка=C17.Заявка  and C17.Статус=0x80E400155D64100111E7BC9ADD36AB53 -- Забраковано
-- left join status_req C18 on z.ссылка=C18.Заявка  and C18.Статус=0xA81400155D94190011E80784923C6095 -- Договор подписан
-- left join status_req C19 on z.ссылка=C19.Заявка  and C19.Статус=0xB81B00155D4D1C4711EA28137B83B6DF -- P2P
 left join #P2P as p2p on p2p.number = z.Номер
-- left join [Stg].[_1cCRM].[Документ_CRM_Заявка] Лид with (nolock) on Лид.Ссылка = z.Лид
 left join #return_types return_types on return_types.external_id = z.Номер
 left join #loginom_sum_apr lsa on lsa.Ссылка = z.Ссылка
 left join #real_channel r_ch on r_ch.Номер=z.Номер
 left join [#Движение заявки по точка] ozz on ozz.Заявка =  z.ссылка
 left join #exc exc_phone on try_cast(try_cast( exc_phone.[Номер заявки] as bigint) as varchar(40)) =z.Номер
  --where c1.период is not null
  --where sis.[Верификация КЦ] is not null
  where sis.[Верификация КЦ] is not null  and ISNULL(sis.Отказано, sis.[Предварительное одобрение]) is not null



  --select * from   #R_t_source

   
 create clustered index ix on #R_t_source
 ( НомерЗаявки
 )

 drop table if exists #columns_updated
 
 drop table if exists #promocode
 select num_1c, try_cast(promo_code as nvarchar(10)) promo_code into #promocode from stg._LK.requests
 where  promo_code <>'' and try_cast(promo_code as nvarchar(10)) is not null and num_1c is not null

 select a.ЗаявкиСсылка,
 офис_to_be =
 case 
 when o4.Код is not null then o4.Ссылка --Excel dwhfiles
 when o5.Код is not null then o5.Ссылка --[офис на основании UF_STAT_CAMPAIGN по site3_installment_lk]
 when o3.Код is not null and a.Дата>='20220630' then  o3.Ссылка --Промокод
 when o2.Код is not null and a.Дата>='20220524' then  o2.Ссылка
 when o1.Код is not null and a.Дата>='20220524' then  o1.Ссылка
 when a.[Юрлицо при создании]= 'АО Ингосстрах Банк'  then  0xA2FB00505683924B11ED465F0E68F63E /*Банк АО "СОЮЗ" */
 when a.[Юрлицо при создании]= 'Общество с ограниченной ответственностью "МодульПартнер"'  then  0xA2FE00505683924B11EE0F5E16CA4D3B /*Банк АО "СОЮЗ" */
 else Офис_CRM 
 
 
 end,
 [Канал от источника_to_be] =  case 
 when lr.[Канал от источника] is not null then lr.[Канал от источника]	 --Excel dwhfiles

 when o5.Код  = '5387' and a.Дата>='20220630' then 'Союз'	   --[офис на основании UF_STAT_CAMPAIGN по site3_installment_lk]	  
 when o5.Код  = '5469' and a.Дата>='20220630' then 'Модуль'	 --[офис на основании UF_STAT_CAMPAIGN по site3_installment_lk]	  
 when o3.Код  = '5387' and a.Дата>='20220630' then 'Союз'	  --[офис на основании UF_STAT_CAMPAIGN по site3_installment_lk]	  
 when o3.Код  = '5469' and a.Дата>='20220630' then 'Модуль'	 --[офис на основании UF_STAT_CAMPAIGN по site3_installment_lk]	  
 when o3.Код is not null and a.Дата>='20220630' then 'Партнеры (лиды)'
 when c.Канал = 'Модуль' then 'Модуль'
 when c.Канал = 'Союз' then 'Союз'
 when o2.Код = '5469' then 'Модуль'
 when o2.Код = '5387' then 'Союз'
 else a.[Канал от источника] 
 
 end,
 e.Дубль,
 [Exceptions info] = 
 a.[Exceptions info] +
 case when c.Канал = 'Союз' then '/Изменен канал на Банки Союз(qr)/' else '' end +
 case when c.Канал = 'Модуль' then '/Изменен канал на Банки Модуль(qr)/' else '' end +
 case when o2.Код = '5469' then '/Изменен канал на Банки Модуль(qr)/' else '' end +
 case when o2.Код = '5387' then '/Изменен канал на Банки Союз(qr)/' else '' end +
 case when o4.Код is not null then '/Изменена точка(excel)/' else '' end +
 case when o5.Код is not null then '/Изменена точка(UF_STAT_CAMPAIGN по site3_installment_lk)/' else '' end +
 case when o3.Код  = '5469' and a.Дата>='20220630' then '/Изменена точка Банк Модуль(promocode)//Изменен канал Банк Модуль(promocode)/' else '' end +
 case when o3.Код  = '5387' and a.Дата>='20220630' then '/Изменена точка Банк Союз(promocode)//Изменен канал Банк Союз(promocode)/' else '' end +
 case when o3.Код is not null and a.Дата>='20220630' then '/Изменена точка(promocode)//Изменен канал(promocode)/' else '' end +
 case when o2.Код is not null and a.Дата>='20220524' then '/Изменена точка(qr)/' else '' end +
 case when o1.Код is not null and a.Дата>='20220524' then '/Изменена точка(qr)/' else '' end +
 case  when  a.[Юрлицо при создании]= 'АО Ингосстрах Банк' then '/Изменена точка(БАНК АО "СОЮЗ")/' else '' end +
 case when lr.[Канал от источника]  is not null then '/Канал(excel)/' else '' end +
 case when e.Дубль  is not null then '/Дубль(excel)/' else '' end 
 , a.НомерЗаявки Номер
 , a.[Вид займа]
 , a.[Заем выдан]
 , a.Телефон
 , a.Дата 
 , lr.[Канал от источника] [Канал от источника заданный вручную]
 , a.[ДатаЗаявки]
 , a.source
 , e.источник

 into #columns_updated

 from #R_t_source a
 left join #R_t_lcrm b on a.НомерЗаявки=b.UF_ROW_ID  and b.UF_STAT_CAMPAIGN is not null
 left join stg.files.[Связка номер точки utm метка_stg] c on try_cast(c.[Уникальный номер партнера] as nvarchar(100))= b.UF_STAT_CAMPAIGN
 left join #Справочник_офисы o1 on o1.Код = try_cast(c.[Номер точки] as nvarchar(100))	 and b.UF_STAT_AD_TYPE='partner'
 left join #Справочник_офисы o2 on o2.Код = try_cast(b.UF_STAT_CAMPAIGN as nvarchar(100)) and try_cast(b.UF_STAT_CAMPAIGN as int) >=200	    and b.UF_STAT_AD_TYPE='partner'
 left join #promocode r on r.num_1c=a.НомерЗаявки
 left join #Справочник_офисы o3 on o3.Код = r.promo_code
 left join #exc e on a.НомерЗаявки = try_cast(try_cast( e.[Номер заявки] as bigint) as varchar(40))  and ISNUMERIC(CAST( a.НомерЗаявки AS varchar))=1
 left join #leadRef1_buffer lr on lr.[Канал от источника]=e.[Канал от источника]
 left join #Справочник_офисы o4 on o4.Код = e.[Номер партнера]
 left join #Справочник_офисы o5 on o5.Код = try_cast(b.UF_STAT_CAMPAIGN as nvarchar(100)) 	and b.uf_type = 'site3_installment_lk'

 

 --select uf_type, max(UF_ACTUALIZE_AT) from 	#R_t_lcrm	 
 --group by 		uf_type
 --order by 2 desc
 --
 --
 --select * from 	  #R_t_lcrm
 --where uf_type  in (  'site3_installment_lk')		  
 --
 --
 --select * from 	  #R_t_lcrm
 --where uf_type  in ( 'partner' , 'partner_installment')
 --order by 2 desc



-- drop table if exists #find_souz_returns
--
--select 
--a.ЗаявкиСсылка
--
--into #find_souz_returns from #columns_updated a
--left join #columns_updated b
--on b.офис_to_be=0xA2FB00505683924B11ED465F0E68F63E 
--and b.[Канал от источника_to_be] = 'Союз' 
--and a.Дата between b.Дата and dateadd(day, 60, b.Дата)  
--and a.Телефон=b.Телефон and a.ЗаявкиСсылка<>b.ЗаявкиСсылка 
--where b.ЗаявкиСсылка is not null --and a.[Заем выдан] is not null  
--and  a.[вид займа]='Первичный' --and a.[Канал от источника_to_be] not in ( 'Партнеры (лиды)', )
--and  a.офис_to_be<>0xA2FB00505683924B11ED465F0E68F63E 
--  group by a.ЗаявкиСсылка
 --


drop table if exists #marketing_attribution

CREATE TABLE  [#marketing_attribution]
(
      [ЗаявкиСсылка] [BINARY](16)
    , [Канал от источника атрибуция] [VARCHAR](50)
    , source  [VARCHAR](128)
);

insert into [#marketing_attribution] ([ЗаявкиСсылка], [Канал от источника атрибуция] )

select 
a.ЗаявкиСсылка  
, 
case 
when max(case when b.[Канал от источника] = 'ПСБ' then 1 end)  is not null then 'ПСБ'
when max(case when b.[Канал от источника] = 'ВТБ' then 1 end)  is not null then 'ВТБ'
when max(case when b.[Канал от источника] = 'Газпром' then 1 end)  is not null then 'Газпром'
when max(case when b.[Канал от источника] = 'Союз' then 1 end)  is not null then 'Союз'
when max(case when b.[Канал от источника] = 'Точка' then 1 end)  is not null then 'Точка'
when max(case when b.[Канал от источника] = 'Модуль' then 1 end)  is not null then 'Модуль'
when max(case when b.[Канал от источника] = 'Билайн' then 1 end)  is not null then 'Билайн'
when max(case when b.[Канал от источника] = 'МТС' then 1 end)  is not null then 'МТС'
when max(case when b.[Канал от источника] = 'Мегафон' then 1 end)  is not null then 'Газпром'
end [Канал от источника атрибуция]


 from #columns_updated a
  
join analytics.dbo.marketing_attribution b
on a.Дата between b.dt and dateadd(day, 90, b.dt)  
and a.Телефон=b.phonenumber 
where  a.[вид займа]='Первичный' 
and isnull(a.[Канал от источника_to_be], '')  not in (
'Оформление на партнерском сайте'
,'Партнеры (лиды)'
,'Кросс-маркетинг'
,'Союз'
,'Газпром'
,'Билайн'
,'МТС'
,'Мегафон'
,'Точка'
,'Модуль'
,'ПСБ'
,'ВТБ'
)
and a.[Канал от источника заданный вручную] is null 
and cast(a.Дата as date)<'20240601'
group by a.ЗаявкиСсылка
 --

 insert into 	#marketing_attribution
  select   ЗаявкиСсылка,   [Канал от источника атрибуция]  , source
  from (
  select 
a.ЗаявкиСсылка  
, b.[Канал от источника]  [Канал от источника атрибуция]
, ROW_NUMBER() over(partition by a.ЗаявкиСсылка  order by b.dt desc )	rn
, b.source
from #columns_updated a

join analytics.dbo.marketing_attribution b
on a.Дата between b.dt and dateadd(day, 90, b.dt)  
and a.Телефон=b.phonenumber 
where  a.[вид займа]='Первичный' 
and isnull(a.[Канал от источника_to_be], '')  not in (
'Оформление на партнерском сайте'
,'Партнеры (лиды)'
,'Кросс-маркетинг'
,'Союз'
,'Газпром'
,'Билайн'
,'МТС'
,'Мегафон'
,'Точка'
,'Модуль'
,'ПСБ'
,'ВТБ'
)
and a.[Канал от источника заданный вручную] is null 
and isnull(a.source, '')  not in ('infoseti-deepapi-installment', 'infoseti-deepapi-pts')

and cast(a.Дата as date)>='20240601'
) x where rn=1
 
 --select * from #find_souz_returns

 drop table if exists #columns_updated_stg2
 ;

 with v as (
 select a.ЗаявкиСсылка
 , a.Дубль
 , офис_to_be = case 
 when b.[Канал от источника атрибуция]  ='Союз' then 0xA2FB00505683924B11ED465F0E68F63E 
 when b.[Канал от источника атрибуция]  ='Модуль' then 0xA2FE00505683924B11EE0F5E16CA4D3B 
 else a.офис_to_be end

 , [Канал от источника_to_be]= case when b.[Канал от источника атрибуция] is not null then b.[Канал от источника атрибуция] else a.[Канал от источника_to_be] end
 , [Exceptions info] = 
 
 case when b.ЗаявкиСсылка is not null then '/Атрибуция 90 дней/' else '' end +
case when  b.[Канал от источника атрибуция]  = 'Союз'   then '/Изменен офис на союз/' else '' end +
case when  b.[Канал от источника атрибуция]  = 'Модуль'   then '/Изменен офис на модуль/' else '' end +
 a.[Exceptions info]
 , a.Номер
 , a.дата
 , isnull( a.источник, b.source) источник
 from 
 #columns_updated a
 left join #marketing_attribution b on a.ЗаявкиСсылка=b.ЗаявкиСсылка
 )



 select z.ЗаявкиСсылка
 ,z.Дубль
 ,z.офис_to_be
 ,[Канал от источника_to_be] = 
 case 
when isnull(z.[Канал от источника_to_be] , '') in
('Сайт орган.трафик', 'Канал привлечения не определен - КЦ', 'Канал привлечения не определен - МП', 'Тест', 'Другое') 
and isnull(b.[Канал от источника_to_be] , '')  in  (
  'CPA целевой'
, 'CPA нецелевой'
, 'CPA полуцелевой'
, 'CPC Бренд'
, 'CPC Платный'
, 'Медийная реклама' 
, 'Триггеры LCRM'
, 'Внутренние триггеры'
, 'Эквифакс'
, 'НБКИ'
, 'ОКБ'


) then isnull(b.[Канал от источника_to_be] , '')
else z.[Канал от источника_to_be] end

 ,[Exceptions info] = z.[Exceptions info]+
case 
when isnull(z.[Канал от источника_to_be] , '') in
('Сайт орган.трафик', 'Канал привлечения не определен - КЦ', 'Канал привлечения не определен - МП', 'Тест', 'Другое') 
and isnull(b.[Канал от источника_to_be] , '')  in  (
  'CPA целевой'
, 'CPA нецелевой'
, 'CPA полуцелевой'
, 'CPC Бренд'
, 'CPC Платный'
, 'Медийная реклама' 
, 'Триггеры LCRM'
, 'Внутренние триггеры'
, 'Эквифакс'
, 'НБКИ'
, 'ОКБ'


) then '/Канал(перезав.)/'
else '' end

 ,z.источник
  

 into #columns_updated_stg2 
 from v z
left join #analytics_mfo_channels true_chanel on true_chanel.ПризнакОформленияНовойЗаявки=z.Номер and true_chanel.rn=1 	
left join v b on b.Номер = true_chanel.Номер   and b.Дата<='20240425'


--		-- select Дата , ДатаЗаявки,  case when ДатаЗаявки<='20240425' then 1 else 0 end from #columns_updated
-- select count(*)  from #columns_updated	where Дата<='20240425'
-- select top 100 *  from #columns_updated	where	 Дата<='20240425'
-- order by НОмер desc								
-- select top 100 *  from #columns_updated	where	 ДатаЗаявки<='20240425'
-- order by НОмер desc


--select * from stg.files.[Связка номер точки utm метка_stg] 
-- update a
--set a.Офис=o.Ссылка
--from
--#R_t_source a 
--join #R_t_lcrm b on a.НомерЗаявки=b.UF_ROW_ID and b.UF_STAT_AD_TYPE='partner' and b.UF_STAT_CAMPAIGN is not null
--join stg.files.[Связка номер точки utm метка_stg] c on try_cast(c.[Уникальный номер партнера] as nvarchar(100))= b.UF_STAT_CAMPAIGN
--join #Справочник_офисы o on o.Код = try_cast(c.[Номер точки] as nvarchar(100))
--where a.Дата>='20220524' --and 
--
----select @@ROWCOUNT
--
--update a
--set a.Офис=o.Ссылка
----select a.НомерЗаявки, a.ДатаЗаявки, a.Офис, b.UF_STAT_CAMPAIGN, o.*
--from
--#R_t_source a 
--join #R_t_lcrm b on a.НомерЗаявки=b.UF_ROW_ID and b.UF_STAT_AD_TYPE='partner' and b.UF_STAT_CAMPAIGN is not null
--join #Справочник_офисы o on o.Код = try_cast(b.UF_STAT_CAMPAIGN as nvarchar(100)) and try_cast(b.UF_STAT_CAMPAIGN as int) >=200
--where a.Дата>='20220524' --and 
--
----select @@ROWCOUNT
--
--
--
--update a
--set a.Офис=o.Ссылка,
--a.[Канал от источника]='Партнеры (лиды)'
----select a.НомерЗаявки, a.ДатаЗаявки, a.Офис, b.UF_STAT_CAMPAIGN, o.*
--from
--#R_t_source a 
--join stg._LK.requests r on r.num_1c=a.НомерЗаявки
--join #Справочник_офисы o on o.Код = r.promo_code
--where a.Дата>='20220630' --and 
----select @@ROWCOUNT
--
--
--
--update a
--set a.[Канал от источника] = b.[Канал от источника]
--from
--#R_t_source a 
--join #exc b on a.НомерЗаявки = b.[Номер заявки] and ISNUMERIC(CAST( a.НомерЗаявки AS varchar))=1
--join #leadRef1_buffer lr on lr.[Канал от источника]=b.[Канал от источника]
--
--
--update a
--set a.Офис = o.Ссылка
----select a.ЗаявкиСсылка, o.Ссылка
--from
--#R_t_source a 
--join #exc b on a.НомерЗаявки = b.[Номер заявки] and ISNUMERIC(CAST( a.НомерЗаявки AS varchar))=1
--join #Справочник_офисы o on o.Код = b.[Номер партнера]


--select * from #R_t_source a
--left join #columns_updated b on a.ЗаявкиСсылка=b.ЗаявкиСсылка
--where a.[Канал от источника]<>b.[Канал от источника_to_be]

drop table if exists #R_t_dubl;

create table #R_t_dubl
(
Номер  nvarchar(100) null
);
/*
With Дубли as
(
--drop table if exists #t
--Declare @dtDateDegin datetime = '4019-01-01T00:00:00'
--Declare @dtDateDegin2000 datetime = '2019-01-01T00:00:00'
--Declare @dtDateReport datetime = GetDate()
----------
--select * from (
		SELECT a0.Номер 'ЛевыйНомер', a2.Номер 'ПравыйНомер', a0.Дата 'ЛеваяДата', a2.Дата 'ПраваяДата', aStatus.Наименование 'ЛевыйСтатус', aStatusright.Наименование 'ПравыйСтатус', DATEDIFF(DAY,a0.Дата,a2.Дата) РазницаДней, a0.МобильныйТелефон 'ЛевыйМобильный', a2.МобильныйТелефон 'ПравыйМобильный'
         		,fa0.ПорядковыйНомерХорошегоСтатуса ПорЛевый
		,fa2.ПорядковыйНомерХорошегоСтатуса ПорПравый
		,fa0.ПорядковыйНомерПлохогоСтатуса ПорПлохойЛевый
		,fa2.ПорядковыйНомерПлохогоСтатуса ПорПлохойПравый
        , case 
		 when fa2.ПорядковыйНомерХорошегоСтатуса=10 and fa0.ПорядковыйНомерХорошегоСтатуса<>10 then 1 
		 when fa2.ПорядковыйНомерХорошегоСтатуса > fa0.ПорядковыйНомерХорошегоСтатуса then 1
		 when fa2.ПорядковыйНомерХорошегоСтатуса<>10 and fa2.ПорядковыйНомерХорошегоСтатуса = fa0.ПорядковыйНомерХорошегоСтатуса and fa2.ПорядковыйНомерПлохогоСтатуса>fa0.ПорядковыйНомерПлохогоСтатуса then 1

		 else 0 end
		 ДубльЛевый
		 -------------------------
		 -------------------------
		 -------------------------
		 , case 
		 when fa2.ПорядковыйНомерХорошегоСтатуса<>10 and fa0.ПорядковыйНомерХорошегоСтатуса=fa2.ПорядковыйНомерХорошегоСтатуса and fa2.ПорядковыйНомерПлохогоСтатуса=fa0.ПорядковыйНомерПлохогоСтатуса  then 1 

		 else 0  
		 end
		 ДубльЛевый2
         -------------------------
		 -------------------------
		 -------------------------
		 , case 
		 when fa0.ПорядковыйНомерХорошегоСтатуса=10 and fa2.ПорядковыйНомерХорошегоСтатуса<>10 then 1 
		 when fa0.ПорядковыйНомерХорошегоСтатуса > fa2.ПорядковыйНомерХорошегоСтатуса then 1
		 when fa0.ПорядковыйНомерХорошегоСтатуса<>10 and fa0.ПорядковыйНомерХорошегоСтатуса = fa2.ПорядковыйНомерХорошегоСтатуса and fa0.ПорядковыйНомерПлохогоСтатуса>fa2.ПорядковыйНомерПлохогоСтатуса then 1

		 

		 else 0 
		 end ДубльПравый
		 		 -------------------------
		 -------------------------
		 -------------------------
		 , 0 ДубльПравый2
	--	 into #t
		  from #Документ_ЗаявкаНаЗаймПодПТС a0 with (nolock)
		join   #Документ_ЗаявкаНаЗаймПодПТС  a2 with (nolock)
		on a0.Ссылка<>a2.Ссылка 
		and a0.МобильныйТелефон=a2.МобильныйТелефон 
		and  (a2.Дата between a0.Дата and DATEADD(DAY,8, cast(a0.Дата as date)) )
		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatus with (nolock) on aStatus.Ссылка = a0.Статус
		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatusright with (nolock) on aStatusright.Ссылка = a2.Статус
		left join #R_t_source fa0 on fa0.ЗаявкиСсылка=a0.Ссылка
		left join #R_t_source fa2 on fa2.ЗаявкиСсылка=a2.Ссылка
		

		where Len(a0.МобильныйТелефон) > 5
		AND ISNUMERIC(CAST( a0.Номер  AS varchar))=1
		AND ISNUMERIC(CAST( a2.Номер  AS varchar))=1
	--	and a0.Дата >= @dtDateDegin
		and case when fa2.[Вид займа_дедупликация]='Повторный' and fa0.[Вид займа_дедупликация]='Первичный' and fa2.[Верификация КЦ]>fa0.[Заем выдан] then 1 else 0 end<>1
		and fa0.[Верификация КЦ] is not null
		and fa2.[Верификация КЦ] is not null
			--and a0.МобильныйТелефон='9671202823'


		--	select * from #t
		--	where ЛевыйСтатус='Заем аннулирован' and ПравыйСтатус='Аннулировано'
		--
		--
		--
		--	select ЛевыйСтатус, ПравыйСтатус, count(*), count(case when ДубльЛевый+ДубльЛевый2+ДубльПравый+ДубльПравый2>0 then 1 end) from #t
		--	group by ЛевыйСтатус, ПравыйСтатус
		--	order by 3 desc

			
		union 
		SELECT a0.Номер 'ЛевыйНомер', a2.Номер 'ПравыйНомер', a0.Дата 'ЛеваяДата', a2.Дата 'ПраваяДата', aStatus.Наименование 'ЛевыйСтатус', aStatusright.Наименование 'ПравыйСтатус', DATEDIFF(DAY,a0.Дата,a2.Дата) РазницаДней, a0.МобильныйТелефон 'ЛевыйМобильный', a2.МобильныйТелефон 'ПравыйМобильный'
         		,fa0.ПорядковыйНомерХорошегоСтатуса ПорЛевый
		,fa2.ПорядковыйНомерХорошегоСтатуса ПорПравый
				,fa0.ПорядковыйНомерПлохогоСтатуса ПорПлохойЛевый
		,fa2.ПорядковыйНомерПлохогоСтатуса ПорПлохойПравый
       , case 
		 when fa2.ПорядковыйНомерХорошегоСтатуса=10 and fa0.ПорядковыйНомерХорошегоСтатуса<>10 then 1 
		 when fa2.ПорядковыйНомерХорошегоСтатуса > fa0.ПорядковыйНомерХорошегоСтатуса then 1
		 when fa2.ПорядковыйНомерХорошегоСтатуса<>10 and fa2.ПорядковыйНомерХорошегоСтатуса = fa0.ПорядковыйНомерХорошегоСтатуса and fa2.ПорядковыйНомерПлохогоСтатуса>fa0.ПорядковыйНомерПлохогоСтатуса then 1

		 else 0 end
		 ДубльЛевый
		 -------------------------
		 -------------------------
		 -------------------------
		 , case 
		 when fa2.ПорядковыйНомерХорошегоСтатуса<>10 and fa0.ПорядковыйНомерХорошегоСтатуса=fa2.ПорядковыйНомерХорошегоСтатуса and fa2.ПорядковыйНомерПлохогоСтатуса=fa0.ПорядковыйНомерПлохогоСтатуса  then 1 

		 else 0  
		 end
		 ДубльЛевый2
         -------------------------
		 -------------------------
		 -------------------------
		 , case 
		 when fa0.ПорядковыйНомерХорошегоСтатуса=10 and fa2.ПорядковыйНомерХорошегоСтатуса<>10 then 1 
		 when fa0.ПорядковыйНомерХорошегоСтатуса > fa2.ПорядковыйНомерХорошегоСтатуса then 1
		 when fa0.ПорядковыйНомерХорошегоСтатуса<>10 and fa0.ПорядковыйНомерХорошегоСтатуса = fa2.ПорядковыйНомерХорошегоСтатуса and fa0.ПорядковыйНомерПлохогоСтатуса>fa2.ПорядковыйНомерПлохогоСтатуса then 1

		 

		 else 0 
		 end ДубльПравый
		 		 -------------------------
		 -------------------------
		 -------------------------
		 , 0 ДубльПравый2

       from #Документ_ЗаявкаНаЗаймПодПТС a0 with (nolock)
		join   #Документ_ЗаявкаНаЗаймПодПТС  a2 with (nolock)
		on a0.Ссылка<>a2.Ссылка 
		and
		((a0.[Имя]=a2.[Имя] --and a0.Фамилия=a2.Фамилия
		and
		a0.[НомерПаспорта]=a2.[НомерПаспорта] ))

		
		and  (a2.Дата between a0.Дата and DATEADD(DAY,8, cast(a0.Дата as date)) )

		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatus with (nolock)
		on aStatus.Ссылка = a0.Статус
		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatusright with (nolock)
		on aStatusright.Ссылка = a2.Статус
				left join #R_t_source fa0 on fa0.ЗаявкиСсылка=a0.Ссылка
		left join #R_t_source fa2 on fa2.ЗаявкиСсылка=a2.Ссылка


		where Len(a0.МобильныйТелефон) > 5
		AND ISNUMERIC(CAST( a0.Номер  AS varchar))=1
		AND ISNUMERIC(CAST( a2.Номер  AS varchar))=1
		and case when fa2.[Вид займа_дедупликация]='Повторный' and fa0.[Вид займа_дедупликация]='Первичный' and fa2.[Верификация КЦ]>fa0.[Заем выдан] then 1 else 0 end<>1


		--and a0.Дата >= @dtDateDegin
				and fa0.[Верификация КЦ] is not null
		and fa2.[Верификация КЦ] is not null
			--and a0.МобильныйТелефон='9671202823'

		union 

		SELECT top 100000 a0.Номер 'ЛевыйНомер', a2.Номер 'ПравыйНомер', a0.Дата 'ЛеваяДата', a2.Дата 'ПраваяДата', aStatus.Наименование 'ЛевыйСтатус', aStatusright.Наименование 'ПравыйСтатус', DATEDIFF(DAY,a0.Дата,a2.Дата) РазницаДней, a0.МобильныйТелефон 'ЛевыйМобильный', a2.МобильныйТелефон 'ПравыйМобильный'
		         		,null ПорЛевый
		,null ПорПравый
				,null ПорПлохойЛевый
		,null ПорПлохойПравый
		, 1 ДубльЛевый
		, 1 ДубльЛевый2
		 , 1 ДубльПравый
		 , 0 ДубльПравый2
		  from #Документ_ЗаявкаНаЗаймПодПТС a0 with (nolock)
		join   #Документ_ЗаявкаНаЗаймПодПТС  a2 with (nolock)
		on a0.Ссылка=a2.Ссылка 
		and
		(
		a0.Фамилия like N'ТЕСТ%' or 
		a0.Отчество like N'ТЕСТ%' or 
		a0.Фамилия = N'ЗАЯВКА' or 
		a0.Фамилия = N'ПРОГОН' or 
		a0.Отчество = N'ПРОГОН' or 
		a0.Имя = N'ПРОГОН' or 
		a0.Фамилия = N'ХОТФИКС' or 
		a0.Отчество = N'ХОТФИКС' or 
		a0.Отчество = N'ЛКП' or 
		a0.Имя  like N'ТЕСТОВ%' or 
		a0.Имя  like N'ЗАЯВКА%' or 

		
		a0.Ссылка in (0x89B819CF89BA11B0498CE7348B8528E8,0xB6B5BFCA206C59C64C567A63FD66E5B3,0xA2D200155D4D095311E931153E055D5D,0xB1CF528ABEE1162748A4CE57EB2E7D54,0x99997DDEC60AD90C42C7EA27A559A274,0xBFEAC92E717E056A4A31ADD902FBFE52,0xA2D700155D4D153311E9F66FB6A0D21D)
		)
		and  (a2.Дата between a0.Дата and DATEADD(DAY,5, a0.Дата) )
		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatus with (nolock)
		on aStatus.Ссылка = a0.Статус
		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatusright with (nolock)
		on aStatusright.Ссылка = a2.Статус
		where -- a0.Дата >= @dtDateDegin
		--AND 
		ISNUMERIC(CAST( a0.Номер  AS varchar))=1
		)
--		x
--		where ЛевыйНомер in ('21011000068665') 
--		 or ПравыйНомер in ('21011000068665') 
----
--
--select дубль, [Вид займа],ФИО,ДатаЗаявкиПолная, [Текущий статус],Телефон, Номер, [Верификация КЦ],[Предварительное одобрение], [Контроль данных], [Верификация документов клиента], [Одобрены документы клиента], [Верификация документов], Одобрено, [Заем выдан] 
--from #tt_end
--where Телефон ='9190674234' or фио='ГАВРИЛОВА ЕКАТЕРИНА ЮРЬЕВНА'
--order by ДатаЗаявкиПолная
----SELECT * FROM Дубли
--
--19112400001383
--19113010000045
--19120610000052
--19120610000187
--20101600042881
--20102300045040

INSERT INTO #R_t_dubl(Номер)
SELECT Номер  FROM 
(

SELECT ЛевыйНомер 'Номер' , SUM(ДубльЛевый)+ SUM(ДубльЛевый2) 'Дубль'
FROM Дубли
GROUP BY ЛевыйНомер
HAVING SUM(ДубльЛевый)+ SUM(ДубльЛевый2) >0

UNION

SELECT ПравыйНомер 'Номер', SUM(ДубльПравый)+ SUM(ДубльПравый2) 'Дубль'
FROM Дубли
GROUP BY ПравыйНомер
HAVING SUM(ДубльПравый)+ SUM(ДубльПравый2) >0
) newa
where Дубль>0
GROUP BY Номер
*/

INSERT INTO #R_t_dubl(Номер)
SELECT number  FROM analytics.dbo.request with(Nolock) where isdubl <>0 and call1 is not null  


;with v  as (select *, row_number() over(partition by Номер order by (select null)) rn from #R_t_dubl ) delete from v where rn>1

drop table if exists #parent

SELECT number, parentGuid into #parent FROM analytics.dbo.request with(Nolock) where   call1 is not null  
and parentGuid is not null

;with v  as (select *, row_number() over(partition by number order by (select null)) rn from #parent ) delete from v where rn>1



---- Общая временная таблица для созданий номеров заявок дублей
--if OBJECT_ID('tempdb.dbo.#R_t_dubl_ClientGuid') is not null
--drop table dbo.#R_t_dubl_ClientGuid;
--
--create table #R_t_dubl_ClientGuid
--(
--Номер  nvarchar(100) null
--);
--
--With Дубли_ClientGuid as
--(
--		SELECT a0.Номер 'ЛевыйНомер', a2.Номер 'ПравыйНомер', a0.Дата 'ЛеваяДата', a2.Дата 'ПраваяДата', aStatus.Наименование 'ЛевыйСтатус', aStatusright.Наименование 'ПравыйСтатус', DATEDIFF(DAY,a0.Дата,a2.Дата) РазницаДней, a0.МобильныйТелефон 'ЛевыйМобильный', a2.МобильныйТелефон 'ПравыйМобильный'
--		, ROW_NUMBER() over(PARTITION BY a0.Номер order by a2.Дата asc) as ROWNUMORDER
--		, IIF(((
--		-- Заявка с которой сравниваем
--		 aStatus.Наименование=N'Аннулировано')
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatusright.Наименование=N'Заем погашен' or aStatusright.Наименование=N'Аннулировано' 
--		 or aStatusright.Наименование=N'Заем аннулирован' 
--		 or aStatusright.Наименование=N'Отказ документов клиента'  or aStatusright.Наименование=N'Отказано' or aStatusright.Наименование=N'Заем выдан' 
--		 -- под вопросом
--		 or aStatusright.Наименование=N'Проблемный' or aStatusright.Наименование=N'Просрочен' 
--		  or aStatusright.Наименование=N'Платеж опаздывает' or aStatusright.Наименование=N'Оценка качества' 
--		 ))
--		 or
--		 ((
--		-- Заявка с которой сравниваем
--		aStatus.Наименование=N'Заем аннулирован')
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatusright.Наименование=N'Заем погашен' or aStatusright.Наименование=N'Заем аннулирован' 
--		 or aStatusright.Наименование=N'Отказ документов клиента'  or aStatusright.Наименование=N'Отказано' or aStatusright.Наименование=N'Заем выдан' 
--		 -- под вопросом
--		 or aStatusright.Наименование=N'Проблемный' or aStatusright.Наименование=N'Просрочен' 
--		  or aStatusright.Наименование=N'Платеж опаздывает' or aStatusright.Наименование=N'Оценка качества' 
--		 ))		 
--		 , 1,0) ДубльЛевый
--		 , IIF((
--		-- Заявка с которой сравниваем
--		aStatus.Наименование=N'Отказано'  --or  aStatus.Наименование=N'Отказ документов клиента'
--		)
--		-- Проверяемая заявка имеет следующие статусы
--		 and ( aStatusright.Наименование=N'Отказано' --or  aStatusright.Наименование=N'Отказ документов клиента' 
--		 ), 1,0) ДубльЛевый2
--		 , IIF(((
--		-- Заявка с которой сравниваем
--		aStatusright.Наименование=N'Аннулировано')
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatus.Наименование=N'Заем погашен' 
--		 --or aStatus.Наименование=N'Аннулировано' or aStatus.Наименование=N'Заем аннулирован' 
--		 or aStatus.Наименование=N'Отказ документов клиента'  or aStatus.Наименование=N'Отказано' or aStatus.Наименование=N'Заем выдан' 
--		 or aStatus.Наименование=N'Проблемный' or aStatus.Наименование=N'Просрочен' 
--		  or aStatus.Наименование=N'Платеж опаздывает' or aStatus.Наименование=N'Оценка качества' 
--		 ))
--		 or
--		 ((
--		-- Заявка с которой сравниваем
--		aStatusright.Наименование=N'Заем аннулирован' )
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatus.Наименование=N'Заем погашен' 
--		--or aStatus.Наименование=N'Заем аннулирован' --or aStatus.Наименование=N'Заем аннулирован' 
--		 or aStatus.Наименование=N'Отказ документов клиента'  or aStatus.Наименование=N'Отказано' or aStatus.Наименование=N'Заем выдан' 
--		 or aStatus.Наименование=N'Проблемный' or aStatus.Наименование=N'Просрочен' 
--		  or aStatus.Наименование=N'Платеж опаздывает' or aStatus.Наименование=N'Оценка качества' 
--		 ))
--		 , 1,0) ДубльПравый
--		 , 0 ДубльПравый2
--		from #Документ_ЗаявкаНаЗаймПодПТС a0 with (nolock)
--		inner join [dwh_new].[staging].[CRMClient_reverse_references] ref0 with (nolock) -- ссылка на связки клиент заявка
--		on ref0.CRMRequestIDRREF=a0.Ссылка 
--		inner join   #Документ_ЗаявкаНаЗаймПодПТС  a2 with (nolock)
--		on a0.Ссылка<>a2.Ссылка 
--		and  
--		(a2.Дата between a0.Дата and DATEADD(DAY,8, cast(a0.Дата as date)))
--		inner join [dwh_new].[staging].[CRMClient_reverse_references] ref2 with (nolock) -- ссылка на связки клиент заявка
--		on ref2.CRMRequestIDRREF=a2.Ссылка  
--		and ref2.CRMClientGUID=ref0.CRMClientGUID  -- Совпадения клиентов 
--		right join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatus with (nolock)
--		on aStatus.Ссылка = a0.Статус
--		right join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatusright with (nolock)
--		on aStatusright.Ссылка = a2.Статус
--		where 
--		ISNUMERIC(CAST( a0.Номер  AS varchar))=1
--		and a0.Дата >= @dtDateDegin
--)
--
----SELECT * FROM Дубли
--
--INSERT INTO #R_t_dubl_ClientGuid(Номер)
--SELECT Номер  FROM 
--(
--
--SELECT ЛевыйНомер 'Номер' , SUM(ДубльЛевый)+ SUM(ДубльЛевый2) 'Дубль'
--FROM Дубли_ClientGuid
--GROUP BY ЛевыйНомер
--HAVING SUM(ДубльЛевый)+ SUM(ДубльЛевый2) >0
--
--UNION
--
--SELECT ПравыйНомер 'Номер', SUM(ДубльПравый)+ SUM(ДубльПравый2) 'Дубль'
--FROM Дубли_ClientGuid
--GROUP BY ПравыйНомер
--HAVING SUM(ДубльПравый)+ SUM(ДубльПравый2) >0
--) newa
--where Дубль>0
--GROUP BY Номер
--
--
--
---- по гуиду в один день
--
--
--
---- Общая временная таблица для созданий номеров заявок дублей
--if OBJECT_ID('tempdb.dbo.#R_t_dubl_ClientGuid2') is not null
--drop table dbo.#R_t_dubl_ClientGuid2;
--
--create table #R_t_dubl_ClientGuid2
--(
--Номер  nvarchar(100) null
--);
--
--With Дубли_ClientGuid2 as
--(
--		SELECT a0.Номер 'ЛевыйНомер', a2.Номер 'ПравыйНомер', a0.Дата 'ЛеваяДата', a2.Дата 'ПраваяДата', aStatus.Наименование 'ЛевыйСтатус', aStatusright.Наименование 'ПравыйСтатус', DATEDIFF(DAY,a0.Дата,a2.Дата) РазницаДней, a0.МобильныйТелефон 'ЛевыйМобильный', a2.МобильныйТелефон 'ПравыйМобильный'
--		, ROW_NUMBER() over(PARTITION BY a0.Номер order by a2.Дата asc) as ROWNUMORDER
--		, IIF(((
--		-- Заявка с которой сравниваем
--		 aStatus.Наименование=N'Аннулировано')
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatusright.Наименование=N'Заем погашен' or aStatusright.Наименование=N'Аннулировано' 
--		 or aStatusright.Наименование=N'Заем аннулирован' 
--		 or aStatusright.Наименование=N'Отказ документов клиента'  or aStatusright.Наименование=N'Отказано' or aStatusright.Наименование=N'Заем выдан' 
--		 -- под вопросом
--		 or aStatusright.Наименование=N'Проблемный' or aStatusright.Наименование=N'Просрочен' 
--		  or aStatusright.Наименование=N'Платеж опаздывает' or aStatusright.Наименование=N'Оценка качества' 
--		 ))
--		 or
--		 ((
--		-- Заявка с которой сравниваем
--		aStatus.Наименование=N'Заем аннулирован')
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatusright.Наименование=N'Заем погашен' or aStatusright.Наименование=N'Заем аннулирован' 
--		 or aStatusright.Наименование=N'Отказ документов клиента'  or aStatusright.Наименование=N'Отказано' or aStatusright.Наименование=N'Заем выдан' 
--		 -- под вопросом
--		 or aStatusright.Наименование=N'Проблемный' or aStatusright.Наименование=N'Просрочен' 
--		  or aStatusright.Наименование=N'Платеж опаздывает' or aStatusright.Наименование=N'Оценка качества' 
--		 ))		 
--		 , 1,0) ДубльЛевый
--		 , IIF((
--		-- Заявка с которой сравниваем
--		aStatus.Наименование=N'Отказано'  --or  aStatus.Наименование=N'Отказ документов клиента'
--		)
--		-- Проверяемая заявка имеет следующие статусы
--		 and ( aStatusright.Наименование=N'Отказано' --or  aStatusright.Наименование=N'Отказ документов клиента' 
--		 ), 1,0) ДубльЛевый2
--		 , IIF(((
--		-- Заявка с которой сравниваем
--		aStatusright.Наименование=N'Аннулировано')
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatus.Наименование=N'Заем погашен' 
--		 --or aStatus.Наименование=N'Аннулировано' or aStatus.Наименование=N'Заем аннулирован' 
--		 or aStatus.Наименование=N'Отказ документов клиента'  or aStatus.Наименование=N'Отказано' or aStatus.Наименование=N'Заем выдан' 
--		 or aStatus.Наименование=N'Проблемный' or aStatus.Наименование=N'Просрочен' 
--		  or aStatus.Наименование=N'Платеж опаздывает' or aStatus.Наименование=N'Оценка качества' 
--		 ))
--		 or
--		 ((
--		-- Заявка с которой сравниваем
--		aStatusright.Наименование=N'Заем аннулирован' )
--		-- Проверяемая заявка имеет следующие статусы
--		 and (aStatus.Наименование=N'Заем погашен' 
--		--or aStatus.Наименование=N'Заем аннулирован' --or aStatus.Наименование=N'Заем аннулирован' 
--		 or aStatus.Наименование=N'Отказ документов клиента'  or aStatus.Наименование=N'Отказано' or aStatus.Наименование=N'Заем выдан' 
--		 or aStatus.Наименование=N'Проблемный' or aStatus.Наименование=N'Просрочен' 
--		  or aStatus.Наименование=N'Платеж опаздывает' or aStatus.Наименование=N'Оценка качества' 
--		 ))
--		 , 1,0) ДубльПравый
--		 , 0 ДубльПравый2
--		from #Документ_ЗаявкаНаЗаймПодПТС a0 with (nolock)
--		inner join [dwh_new].[staging].[CRMClient_reverse_references] ref0 with (nolock) -- ссылка на связки клиент заявка
--		on ref0.CRMRequestIDRREF=a0.Ссылка 
--		inner join   #Документ_ЗаявкаНаЗаймПодПТС  a2 with (nolock)
--		on a0.Ссылка<>a2.Ссылка 
--		and  
--		(a2.Дата between a0.Дата and DATEADD(DAY,1, cast(a0.Дата as date)))
--		inner join [dwh_new].[staging].[CRMClient_reverse_references] ref2 with (nolock) -- ссылка на связки клиент заявка
--		on ref2.CRMRequestIDRREF=a2.Ссылка  
--		and ref2.CRMClientGUID=ref0.CRMClientGUID  -- Совпадения клиентов 
--		right join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatus with (nolock)
--		on aStatus.Ссылка = a0.Статус
--		right join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] aStatusright with (nolock)
--		on aStatusright.Ссылка = a2.Статус
--		where 
--		ISNUMERIC(CAST( a0.Номер  AS varchar))=1
--		and a0.Дата >= @dtDateDegin
--)
--
----SELECT * FROM Дубли
--
--INSERT INTO #R_t_dubl_ClientGuid2(Номер)
--SELECT Номер  FROM 
--(
--
--SELECT ЛевыйНомер 'Номер' , SUM(ДубльЛевый)+ SUM(ДубльЛевый2) 'Дубль'
--FROM Дубли_ClientGuid2
--GROUP BY ЛевыйНомер
--HAVING SUM(ДубльЛевый)+ SUM(ДубльЛевый2) >0
--
--UNION
--
--SELECT ПравыйНомер 'Номер', SUM(ДубльПравый)+ SUM(ДубльПравый2) 'Дубль'
--FROM Дубли_ClientGuid2
--GROUP BY ПравыйНомер
--HAVING SUM(ДубльПравый)+ SUM(ДубльПравый2) >0
--) newa
--where Дубль>0
--GROUP BY Номер




	--Declare @dtDateDegin datetime = '4019-01-01T00:00:00'
	--Declare @dtDateDegin2000 datetime = '2019-01-01T00:00:00'
	--Declare @dtDateReport datetime = GetDate()

	

--create table #R_t_lcrm
--(ID  numeric(15) null
--,UF_ACTUALIZE_AT datetime null
--,UF_UPDATED_AT datetime null   
--,UF_ROW_ID nvarchar(100) null
--,[Канал от источника]  nvarchar(100) null 
--,[Группа каналов]  nvarchar(100) null 
--,UF_SOURCE         nvarchar(128) null 
--,[UF_PARTNER_ID]        nvarchar(128) null 
--,[UF_LOGINOM_PRIORITY]        int null 
--);
--
--insert into #R_t_lcrm(
--		ID
--		, UF_ACTUALIZE_AT
--		, UF_UPDATED_AT
--		, UF_ROW_ID 
--		, [Канал от источника]
--		, [Группа каналов]
--		,UF_SOURCE
--,[UF_PARTNER_ID]
--		,[UF_LOGINOM_PRIORITY]
--		)







--select * from #leadRef1_buffer
--select * from #real_channel


--select [Канал от источника], count(*), count(distinct Номер) from #real_chanel
--group by [Канал от источника]
--order by [Канал от источника]
--
--select * from #real_channel rch left join #leadRef1_buffer l on rch.[Канал от источника]=l.[Канал от источника]
--order by [группа каналов]

--select * from #P2P




 --where z.Дата between @dtDateDegin and DATEADD(YY,2000,getDate())


 --select * from #R_t_source
 
--SELECT * FROM  #R_t_source as ВсеЗаявки

-- рассчитаем TTC
drop table if exists #ttc;

SELECT Выдачи.ЗаявкиСсылка as Ссылка, НомерЗаявки, FORMAT(Выдачи.Дата,'yyyy-MM') 'Период',
DATEDIFF(MINUTE,Выдачи.[Верификация КЦ],Выдачи.[Заем выдан]) 'РазницаВерификацияВыдача', 
ntile(4) OVER(PARTITION BY FORMAT(Выдачи.Дата,'yyyy-MM')  ORDER BY DATEDIFF(MINUTE,Выдачи.[Верификация КЦ],Выдачи.[Заем выдан]) ) AS medianTest2
into #ttc
FROM #R_t_source as Выдачи
where Выдачи.[Заем выдан] is not null



-- рассчитаем TTC

drop table if exists #categories_DIP
select Ссылка, category_docredy, category_povt  into #categories_DIP  from dbo.dm_request_dip_category
where isnull(category_docredy, category_povt) is not null




drop table if exists #dm_sales

select 
  код
, [SumKasko]        =                               nullif(cast(КАСКО                                                                                                                                                         as float) ,0)   
, [SumEnsur]        =                               nullif(cast([Страхование жизни]																																			  as float) ,0)
, [SumRat]          =                               nullif(cast(РАТ+		[РАТ 2.0]																																					  as float) ,0)
--, [SumPositiveMood] =                               nullif(cast(null																																						  as float) ,0)
, [SumHelpBusiness] =                               nullif(cast([Помощь бизнесу]																																			  as float) ,0)
, [SumTeleMedic]    =                               nullif(cast(телемедицина	+ isnull( [ЗАЩИТА ЗДОРОВЬЯ], 0)																																			  as float) ,0)
, [SumCushion]      =                               nullif(cast([Защита от потери работы]+[От потери работы. «Максимум»]+[От потери работы. «Стандарт»]																		  as float) ,0)
, [SumPharma]       =                               nullif(cast([Фарм страхование]	 + isnull( [ФАРМА-помощь], 0)																																			  as float) ,0)
, SumQuietLife      =                               nullif(cast([Спокойная жизнь]																																			  as float) ,0)
, SumRatJudical      =                               nullif(cast([РАТ Юр. услуги]	 																																			  as float) ,0)
--РАТ Юр. услуги	РАТ Юр. услуги_without_partner_bounty	РАТ Юр. услуги NET
, [SumKaskoCarmoney]        =                       nullif(cast(КАСКО_without_partner_bounty																																  as float) ,0)
, [SumEnsurCarmoney]        =                       nullif(cast([Страхование жизни_without_partner_bounty]																													  as float) ,0)
, [SumRatCarmoney]          =                       nullif(cast(РАТ_without_partner_bounty + 	[РАТ 2.0_without_partner_bounty]																																  as float) ,0)
--, [SumPositiveMoodCarmoney] =                       nullif(cast(null																																						  as float) ,0)
, [SumHelpBusinessCarmoney] =                       nullif(cast([Помощь бизнесу_without_partner_bounty]																														  as float) ,0)
, [SumTeleMedicCarmoney]    =                       nullif(cast(Телемедицина_without_partner_bounty	 + isnull( [ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty], 0)																														  as float) ,0)
, [SumCushionCarmoney]      =                       nullif(cast([Защита от потери работы_without_partner_bounty]+[От потери работы. «Максимум»_without_partner_bounty]+[От потери работы. «Стандарт»_without_partner_bounty]  as float) ,0)
, [SumPharmaCarmoney]       =                       nullif(cast([Фарм страхование_without_partner_bounty]	+ isnull( [ФАРМА-помощь_without_partner_bounty], 0)																													  as float) ,0)
, SumQuietLifeCarmoney      =                       nullif(cast([Спокойная жизнь_without_partner_bounty]																													  as float) ,0)
, SumRatJudicalCarmoney      =                       nullif(cast([РАТ Юр. услуги_without_partner_bounty]	 																										  as float) ,0)
, [SumKaskoCarmoneyNet]        =                    nullif(cast([КАСКО NET]																																					  as float) ,0)
, [SumEnsurCarmoneyNet]        =                    nullif(cast([Страхование жизни NET]																																		  as float) ,0)
, [SumRatCarmoneyNet]          =                    nullif(cast([РАТ NET]			+ 		[РАТ 2.0 NET]																																  as float) ,0)
--, [SumPositiveMoodCarmoneyNet] =                    nullif(cast(null																																						  as float) ,0)
, [SumHelpBusinessCarmoneyNet] =                    nullif(cast([Помощь бизнесу NET]																																		  as float) ,0)
, [SumTeleMedicCarmoneyNet]    =                    nullif(cast([Телемедицина NET]		 + isnull( [ЗАЩИТА ЗДОРОВЬЯ NET], 0)																																		  as float) ,0)
, [SumCushionCarmoneyNet]      =                    nullif(cast([Защита от потери работы NET]+[От потери работы. «Максимум» NET]+[От потери работы. «Стандарт» NET]															  as float) ,0)
, [SumPharmaCarmoneyNet]       =                    nullif(cast([Фарм страхование NET] + isnull( [ФАРМА-помощь NET], 0)																																		  as float) ,0)
, [SumQuietLifeCarmoneyNet]          =              nullif(cast([Спокойная жизнь NET]																																		  as float) ,0)
, [SumRatJudicalCarmoneyNet]          =              nullif(cast([РАТ Юр. услуги NET]	 																															  as float) ,0)
, [Автоспор]          =              nullif(cast( isnull( [Автоспор], 0)																																	  as float) ,0)
, [Автоспор carmoney]          =              nullif(cast( isnull( [Автоспор_without_partner_bounty], 0)																																	  as float) ,0)
, [Автоспор carmoney Net]          =              nullif(cast( isnull( [Автоспор NET], 0)																																	  as float) ,0)
into #dm_sales
from dbo.dm_Sales
 where ishistory=0


drop table if exists #d
select d.Код                                     
,      d.Ссылка                                  
,      d.Сумма СуммаВыдачи                                  
,      dateadd(year, -2000, vds.ДатаВыдачи) ДатаВыдачи                                  
,      dateadd(year, -2000, cast(d.Дата as date)) ДатаДоговора
,      СуммаДопПродуктов     
,      Срок     

into #d
from stg._1ccmr.[Справочник_Договоры]          d  
left join stg._1cCMR.Документ_ВыдачаДенежныхСредств vds on d.Ссылка=vds.Договор and vds.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F --Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
and vds.Проведен=1
and vds.ПометкаУдаления=0



drop table if exists #current_percent
; with r as (select pd.Договор 
                  , max(Период) max_p
               from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
               join #d d on  d.Ссылка=pd.Договор
              group by  pd.Договор--,Код
            )
    select pd.договор
		 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПроцСтавкаКредит
      into #current_percent
      from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
      join r on r.Договор=pd. Договор and r.max_p=pd.Период


drop table if exists #percent_14days
;with r as (select pd.Договор 
                  , max(Период) max_p
               from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
               join #d d on  d.Ссылка=pd.Договор and cast(dateadd(year, -2000, pd.Период) as date) between cast(d.ДатаДоговора as date) and dateadd(day, 13,cast( d.ДатаДоговора as date))
              group by  pd.Договор--,Код
            )
    select pd.договор
		 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПоследняяПроцСтавкаДо14Дней
      into #percent_14days
      from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
      join r on r.Договор=pd. Договор and r.max_p=pd.Период

--
--
--
--drop table if exists #dp
--select d.Ссылка
--,      dd.Сумма  Сумма
--,      
--       case when spdd.Код='000000001' then dd.Сумма*0.95 --Страхование жизни
--            when spdd.Код='000000002' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210531' then 0.75 --Рат
--                                                         when ДатаДоговора >= '20210601'  then 0.81 --Рат
--												    end
--            when spdd.Код='000000003' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210304' then 0.86 --Каско
--                                                         when ДатаДоговора >= '20210305' then 0.9                      --Каско
--												    end
--			when spdd.Код='000000004' then dd.Сумма*0.8 --От потери работы. «Максимум»
--			when spdd.Код='000000005' then dd.Сумма*0.75 --От потери работы. «Стандарт»
--			when spdd.Код='000000006' then dd.Сумма*0.73 --Помощь бизнесу
--			when spdd.Код='000000007' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210304' then 0.86 --Каско
--                                                         when ДатаДоговора >= '20210305' then 0.9                      --Каско
--												    end
--			when spdd.Код='000000008' then dd.Сумма*0.95 --Страхование жизни
--			when spdd.Код='000000009' then dd.Сумма*0.67 --Телемедицина
--			when spdd.Код='000000010' then dd.Сумма*case when ДатаДоговора between '20190101' and '20210322' then 0.4 --Защита от потери работы
--			                                             when ДатаДоговора between '20210323' and '20210531' then 0.75 --Защита от потери работы
--			                                             when ДатаДоговора between '20190601' and '20210630' then 0.67 --Защита от потери работы
--                                                         when ДатаДоговора >= '20210323' then 0.75                      --Защита от потери работы
--												    end
--			when spdd.Код='000000011' then dd.Сумма*case when ДатаДоговора >='20211119' then (1-0.625) else (1-0.5) end  --Фарм страхование
--			when spdd.Код='000000012' then dd.Сумма-1650  --спокойная жизнь
--
--		end as 
--		
--		СуммаCarmoney
--,      spdd.Наименование
--,      spdd.Код
--,      d.ДатаДоговора
--
--into #dp
--from      #d                                                      d   
--join      stg._1ccmr.[Справочник_Договоры_ДополнительныеПродукты] dd   on dd.ссылка=d.ссылка
--join  stg._1ccmr.[Справочник_ДополнительныеПродукты]          spdd on spdd.ссылка=dd.ДополнительныйПродукт and spdd.код not in ('000000013','000000014','000000015')

--select [Дата выдачи],* from stg._1ccmr.[Справочник_Договоры_ДополнительныеПродукты] a
--join  stg._1ccmr.[Справочник_ДополнительныеПродукты]    b on a.ДополнительныйПродукт=b.Ссылка and b.Код='000000014'
--join Analytics.dbo.mv_loans c on c.[Ссылка договор CMR]=a.Ссылка
--order by 1
--select * from #dp
--where ссылка=0xA2CC005056839FE911EBE3C9912A8E65
--	order by СуммаCarmoney ,1


	--select * from stg._1ccmr.[Справочник_ДополнительныеПродукты]
	--order by Код


	--select * from prodsql02.cmr.dbo.[Справочник_ДополнительныеПродукты]
	--order by Код
	drop table if exists #agr


	;

	with v as (
	select d.Код 
	, d.ДатаДоговора
	, d.ДатаВыдачи
	, d.Срок
	, d.СуммаВыдачи
	, current_percent.ПроцСтавкаКредит
	, percent_14days.ПоследняяПроцСтавкаДо14Дней
	, [SumKasko]                     [SumKasko]                                
	, [SumEnsur]                     [SumEnsur]                    
	, [SumRat]                       [SumRat]                      
	--, [SumPositiveMood]              [SumPositiveMood]             
	, [SumHelpBusiness]              [SumHelpBusiness]             
	, [SumTeleMedic]                 [SumTeleMedic]                
	, [SumCushion]                   [SumCushion]                  
	, [SumPharma]                    [SumPharma]                   
	, SumQuietLife                   SumQuietLife 
	, SumRatJudical                   SumRatJudical 
	
	, [SumKaskoCarmoney]             [SumKaskoCarmoney]            
	, [SumEnsurCarmoney]             [SumEnsurCarmoney]            
	, [SumRatCarmoney]               [SumRatCarmoney]              
	--, [SumPositiveMoodCarmoney]      [SumPositiveMoodCarmoney]     
	, [SumHelpBusinessCarmoney]      [SumHelpBusinessCarmoney]     
	, [SumTeleMedicCarmoney]         [SumTeleMedicCarmoney]        
	, [SumCushionCarmoney]           [SumCushionCarmoney]          
	, [SumPharmaCarmoney]            [SumPharmaCarmoney]           
	, SumQuietLifeCarmoney           SumQuietLifeCarmoney          
	, SumRatJudicalCarmoney          SumRatJudicalCarmoney           
	, [SumKaskoCarmoneyNet]          [SumKaskoCarmoneyNet]         
	, [SumEnsurCarmoneyNet]          [SumEnsurCarmoneyNet]         
	, [SumRatCarmoneyNet]            [SumRatCarmoneyNet]           
	--, [SumPositiveMoodCarmoneyNet]   [SumPositiveMoodCarmoneyNet]  
	, [SumHelpBusinessCarmoneyNet]   [SumHelpBusinessCarmoneyNet]  
	, [SumTeleMedicCarmoneyNet]      [SumTeleMedicCarmoneyNet]     
	, [SumCushionCarmoneyNet]        [SumCushionCarmoneyNet]       
	, [SumPharmaCarmoneyNet]         [SumPharmaCarmoneyNet]        
	, [SumQuietLifeCarmoneyNet]      [SumQuietLifeCarmoneyNet]     
	, SumRatJudicalCarmoneyNet          SumRatJudicalCarmoneyNet 
	, [Автоспор]          =    [Автоспор]   
	, [Автоспор carmoney]   = [Автоспор carmoney]      
	, [Автоспор carmoney Net] = [Автоспор carmoney Net]     

	--,cast( nullif(isnull([dp_000000007].Сумма, 0) + isnull([dp_000000003].Сумма , 0), 0)                                    as float) [SumKasko]
    --,cast( nullif(isnull([dp_000000001].Сумма, 0) + isnull([dp_000000008].Сумма , 0), 0)                                    as float) [SumEnsur]
    --,cast( [dp_000000002].Сумма                                                                                             as float) [SumRat]
    --,cast( null                                                                                                             as float) [SumPositiveMood]
    --,cast( [dp_000000006].Сумма                                                                                             as float) [SumHelpBusiness]
    --,cast( [dp_000000009].Сумма                                                                                             as float) [SumTeleMedic]
    --,cast( nullif(isnull([dp_000000004].Сумма, 0) + isnull([dp_000000005].Сумма , 0) + isnull([dp_000000010].Сумма , 0), 0) as float) [SumCushion]
    --,cast( [dp_000000011].Сумма                                                                                             as float) [SumPharma]
    --,cast( [dp_000000012].Сумма                                                                                             as float) [SumQuietLife]
	--
   ------------------------
   ------------------------
   ------------------------
    --,cast( nullif(isnull([dp_000000007].СуммаCarmoney, 0) + isnull([dp_000000003].СуммаCarmoney , 0), 0)                                            as float) [SumKaskoCarmoney]
    --,cast( nullif(isnull([dp_000000007].СуммаCarmoney, 0) + isnull([dp_000000003].СуммаCarmoney , 0), 0)                                            as float)*case when d.ДатаДоговора>='20210201' then 1 else (1-0.2/1.2) end - case when d.ДатаДоговора>='20210201' then cast( nullif(isnull([dp_000000007].Сумма, 0) + isnull([dp_000000003].Сумма , 0), 0) as float)-cast( nullif(isnull([dp_000000007].СуммаCarmoney, 0) + isnull([dp_000000003].СуммаCarmoney , 0), 0) as float) else 0 end*(1/6.0)  [SumKaskoCarmoneyNet]
    --,cast( nullif(isnull([dp_000000001].СуммаCarmoney, 0) + isnull([dp_000000008].СуммаCarmoney , 0), 0)                                            as float) [SumEnsurCarmoney]
    --,cast( nullif(isnull([dp_000000001].СуммаCarmoney, 0) + isnull([dp_000000008].СуммаCarmoney , 0), 0)                                            as float)*case when d.ДатаДоговора>='20210201' then 1 else (1-0.2/1.2) end - case when d.ДатаДоговора>='20210201' then cast( nullif(isnull([dp_000000001].Сумма, 0) + isnull([dp_000000008].Сумма , 0), 0) as float)-cast( nullif(isnull([dp_000000001].СуммаCarmoney, 0) + isnull([dp_000000008].СуммаCarmoney , 0), 0) as float) else 0 end*(1/6.0)  [SumEnsurCarmoneyNet]
    --,cast( [dp_000000002].СуммаCarmoney                                                                                                             as float) [SumRatCarmoney]
    --,cast( [dp_000000002].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumRatCarmoneyNet]
    --,cast( null                                                                                                                                     as float) [SumPositiveMoodCarmoney]
    --,cast( [dp_000000006].СуммаCarmoney                                                                                                             as float) [SumHelpBusinessCarmoney]
    --,cast( [dp_000000006].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumHelpBusinessCarmoneyNet]
    --,cast( [dp_000000009].СуммаCarmoney                                                                                                             as float) [SumTeleMedicCarmoney]
    --,cast( [dp_000000009].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumTeleMedicCarmoneyNet]
    --,cast( nullif(isnull([dp_000000004].СуммаCarmoney, 0) + isnull([dp_000000005].СуммаCarmoney , 0) + isnull([dp_000000010].СуммаCarmoney , 0), 0) as float) [SumCushionCarmoney]
    --,cast( nullif(isnull([dp_000000004].СуммаCarmoney, 0) + isnull([dp_000000005].СуммаCarmoney , 0) + isnull([dp_000000010].СуммаCarmoney , 0), 0) as float)*(1-0.2/1.2) [SumCushionCarmoneyNet]
    --,cast( [dp_000000011].СуммаCarmoney                                                                                                             as float) [SumPharmaCarmoney]
    --,cast( [dp_000000011].СуммаCarmoney                                                                                                             as float)*(1-0.2/1.2) [SumPharmaCarmoneyNet]
    --,cast( [dp_000000012].СуммаCarmoney                                                                                                             as float) [SumQuietLifeCarmoney]
    --,cast( [dp_000000012].СуммаCarmoney                                                                                                             as float)*case when d.ДатаДоговора>='20210201' then 1 else (1-0.2/1.2) end - case when d.ДатаДоговора>='20210201' then cast( [dp_000000012].Сумма as float)-cast( [dp_000000012].СуммаCarmoney as float) else 0 end*(1/6.0) [SumQuietLifeCarmoneyNet]

	
	from #d d
	--left join #dp [dp_000000001] on [dp_000000001].Ссылка=d.Ссылка and [dp_000000001].Код='000000001' --Страхование жизни
	--left join #dp [dp_000000002] on [dp_000000002].Ссылка=d.Ссылка and [dp_000000002].Код='000000002' --РАТ
	--left join #dp [dp_000000003] on [dp_000000003].Ссылка=d.Ссылка and [dp_000000003].Код='000000003' --КАСКО
	--left join #dp [dp_000000004] on [dp_000000004].Ссылка=d.Ссылка and [dp_000000004].Код='000000004' --От потери работы. «Максимум»
	--left join #dp [dp_000000005] on [dp_000000005].Ссылка=d.Ссылка and [dp_000000005].Код='000000005' --От потери работы. «Стандарт»
	--left join #dp [dp_000000006] on [dp_000000006].Ссылка=d.Ссылка and [dp_000000006].Код='000000006' --Помощь бизнесу
	--left join #dp [dp_000000007] on [dp_000000007].Ссылка=d.Ссылка and [dp_000000007].Код='000000007' --КАСКО
	--left join #dp [dp_000000008] on [dp_000000008].Ссылка=d.Ссылка and [dp_000000008].Код='000000008' --Страхование жизни
	--left join #dp [dp_000000009] on [dp_000000009].Ссылка=d.Ссылка and [dp_000000009].Код='000000009' --Телемедицина
	--left join #dp [dp_000000010] on [dp_000000010].Ссылка=d.Ссылка and [dp_000000010].Код='000000010' --Защита от потери работы
	--left join #dp [dp_000000011] on [dp_000000011].Ссылка=d.Ссылка and [dp_000000011].Код='000000011' --Фарм страхование
	--left join #dp [dp_000000012] on [dp_000000012].Ссылка=d.Ссылка and [dp_000000012].Код='000000012' --Спокойная жизнь
	left join #dm_sales dm_sales on dm_sales.Код=d.Код
	left join #current_percent current_percent on current_percent.Договор=d.Ссылка
	left join #percent_14days percent_14days on percent_14days.Договор=d.Ссылка

	)
	, v_v as (

	select v.Код
	, ДатаВыдачи
	, Срок
	, ДатаДоговора
	, СуммаВыдачи
	, cast(ПроцСтавкаКредит as float) ПроцСтавкаКредит
	, isnull(cast(ПоследняяПроцСтавкаДо14Дней as float), cast(ПроцСтавкаКредит as float)) ПоследняяПроцСтавкаДо14Дней
	, v.[SumKasko]
	, v.[SumEnsur]
	, v.[SumRat]
	--, v.[SumPositiveMood]
	, v.[SumHelpBusiness]
	, v.[SumTeleMedic]
	, v.[SumCushion]
	, v.[SumPharma]
	, v.SumQuietLife
	, v.SumRatJudical
	, v.[Автоспор]
	, case when v.[SumKasko]          is not null then 1 else 0 end as ПризнакКаско
	, case when v.[SumEnsur]		  is not null then 1 else 0 end as ПризнакСтрахованиеЖизни
	, case when v.[SumRat]			  is not null then 1 else 0 end as ПризнакРАТ
	, case when v.[SumHelpBusiness]	  is not null then 1 else 0 end as ПризнакПомощьБизнесу
	, case when v.[SumTeleMedic]	  is not null then 1 else 0 end as ПризнакТелемедицина
	, case when v.[SumCushion]		  is not null then 1 else 0 end as [Признак Защита от потери работы]
	, case when v.[SumPharma]		  is not null then 1 else 0 end as ПризнакФарма
	, case when v.[SumQuietLife]		  is not null then 1 else 0 end as ПризнакСпокойнаяЖизнь
	, case when v.SumRatJudical		  is not null then 1 else 0 end as ПризнакРАТЮруслуги
	, case when v.Автоспор		  is not null then 1 else 0 end as ПризнакАвтоспор

	, v.[SumKaskoCarmoney]
	, v.[SumEnsurCarmoney]
	, v.[SumRatCarmoney]
	--, v.[SumPositiveMoodCarmoney]
	, v.[SumHelpBusinessCarmoney]
	, v.[SumTeleMedicCarmoney]
	, v.[SumCushionCarmoney]
	, v.[SumPharmaCarmoney]
	, v.SumQuietLifeCarmoney
	, v.SumRatJudicalCarmoney
	, v.[Автоспор carmoney]

	, v.[SumKaskoCarmoneyNet]
	, v.[SumEnsurCarmoneyNet]
	, v.[SumRatCarmoneyNet]
	, v.[SumHelpBusinessCarmoneyNet]
	, v.[SumTeleMedicCarmoneyNet]
	, v.[SumCushionCarmoneyNet]
	, v.[SumPharmaCarmoneyNet]
	, v.SumQuietLifeCarmoneyNet
	, v.SumRatJudicalCarmoneyNet
	, v.[Автоспор carmoney Net]

	,
	  isnull(v.[SumKasko]            ,0)+
	  isnull(v.[SumEnsur]			 ,0)+
	  isnull(v.[SumRat]				 ,0)+
	--  isnull(v.[SumPositiveMood]	 ,0)+
	  isnull(v.[SumHelpBusiness]	 ,0)+
	  isnull(v.[SumTeleMedic]		 ,0)+
	  isnull(v.[SumCushion]			 ,0)+
	  isnull(v.SumPharma			 ,0)+
	  isnull(v.SumQuietLife			 ,0)+
	  isnull(v.SumRatJudical			 ,0) +
	  isnull(v.[Автоспор]			 ,0)
	   СуммаДопУслуг	
	,
	  isnull(v.[SumKaskoCarmoney]            ,0)+
	  isnull(v.[SumEnsurCarmoney]			 ,0)+
	  isnull(v.[SumRatCarmoney]				 ,0)+
	--  isnull(v.[SumPositiveMoodCarmoney]	 ,0)+
	  isnull(v.[SumHelpBusinessCarmoney]	 ,0)+
	  isnull(v.[SumTeleMedicCarmoney]		 ,0)+
	  isnull(v.[SumCushionCarmoney]			 ,0)+
	  isnull(v.SumPharmaCarmoney			 ,0)+
	  isnull(v.SumQuietLifeCarmoney			 ,0)+
	  isnull(v.SumRatJudicalCarmoney			 ,0)+
	  isnull(v.[Автоспор carmoney]			 ,0)
	   СуммаДопУслугCarmoney	,
	  isnull(v.[SumKaskoCarmoneyNet]            ,0)+
	  isnull(v.[SumEnsurCarmoneyNet]			 ,0)+
	  isnull(v.[SumRatCarmoneyNet]				 ,0)+
	  isnull(v.[SumHelpBusinessCarmoneyNet]	 ,0)+
	  isnull(v.[SumTeleMedicCarmoneyNet]		 ,0)+
	  isnull(v.[SumCushionCarmoneyNet]			 ,0)+
	  isnull(v.SumPharmaCarmoneyNet			 ,0)+
	  isnull(v.SumQuietLifeCarmoneyNet			 ,0)+
	  isnull(v.SumRatJudicalCarmoneyNet			 ,0)+
	  isnull(v.[Автоспор carmoney Net]			 ,0)
	   СуммаДопУслугCarmoneyNet
	, case when 
		nullif(
	--  isnull(v.[SumKasko]            ,0)+
	--  isnull(v.[SumEnsur]			 ,0)+
	  isnull(v.[SumRat]				 ,0)+
	  --isnull(v.[SumPositiveMood]	 ,0)+
	  isnull(v.[SumHelpBusiness]	 ,0)+
	  isnull(v.[SumTeleMedic]		 ,0)+
	  isnull(v.[SumCushion]			 ,0)+
	  isnull(v.SumPharma			 ,0)+
	--  isnull(v.SumQuietLife			 ,0)+
	  isnull(v.SumRatJudical			 ,0)+
	  isnull(v.[Автоспор]			 ,0)
	  , 0)>0 then 1 else 0 end as ПризнакКоробочныйПродукт
	, case when 
		nullif(
	  isnull(v.[SumKasko]            ,0)+
	  isnull(v.[SumEnsur]			 ,0)+
	  isnull(v.[SumRat]				 ,0)+
	 -- isnull(v.[SumPositiveMood]	 ,0)+
	  isnull(v.[SumHelpBusiness]	 ,0)+
	  isnull(v.[SumTeleMedic]		 ,0)+
	  isnull(v.[SumCushion]			 ,0)+
	  isnull(v.SumPharma			 ,0)+
	  isnull(v.SumQuietLife			 ,0)+
	  isnull(v.SumRatJudical			 ,0) +
	  isnull(v.автоспор			 ,0)
	  , 0)>0 then 1 else 0 end as ПризнакКП
	  , case when 
		nullif(
	  isnull(v.[SumKasko]            ,0)+
	  isnull(v.[SumEnsur]			 ,0)+
	  isnull(v.SumQuietLife			 ,0)
	  , 0)>0 then 1 else 0 end as ПризнакСтраховка
		
	from v
	)

	select * into #agr from v_v

  --расчет места создания 2



drop table if exists #dm_FillingTypeChangesInRequests
select [Номер заявки]
	  ,[Дата изменения]
	  ,[Статус]
	  ,[Вид заполнения]   into #dm_FillingTypeChangesInRequests 

FROM [dbo].[dm_FillingTypeChangesInRequests] s1





drop table if exists #v_dm_place_of_creation_2

	SELECT 
	f1.НомерЗаявки Номер  ,
	--,ДатаЗаявкиПолная,

	iif (f1.[Место cоздания]='ЛКК клиента' or s5.[Вид заполнения]='Заполняется в личном кабинете клиента' , 'ЛКК клиента' , 
	iif (f1.[Место cоздания]='Оформление в мобильном приложении' or s5.[Вид заполнения]='Заполняется в мобильном приложении' or 
	f1.[Место cоздания]='Оформление на клиентском сайте' ,'МП'
	,iif (f1.[Место cоздания]='Ввод операторами КЦ' or f1.[Место cоздания]='Ввод операторами LCRM' or f1.[Место cоздания]='Ввод операторами FEDOR' or f1.[Место cоздания]='Ввод операторами стороннего КЦ','КЦ'
	,iif (f1.[Место cоздания]='Оформление на партнерском сайте','Партнеры',f1.[Место cоздания])))) as 'Место_создания_2'

	into #v_dm_place_of_creation_2
	FROM
	(
	SELECT *
	FROM
	(
	SELECT 

		   a0.НомерЗаявки
		  ,a0.СпособОформления as 'Место cоздания'
		 -- ,ДатаЗаявкиПолная
      
	  FROM #R_t_source a0
  
 
	) as c1

	) as f1

	left join
	(
	SELECT
	 [Номер заявки]
	,[Вид заполнения]
	FROM
	(
	SELECT *
	,ROW_NUMBER () over (partition by [Номер заявки] order by [Дата изменения] DESC) as RN
	FROM
	(
	SELECT
	[Номер заявки]
	,iif (Статус='Контроль данных' or DATEDIFF (mi,dateadd(year,-2000,[Дата изменения]),[Контроль данных])>=0 or [Контроль данных] is null,1,null) 'Флаг'
	,[Вид заполнения]
	,[Дата изменения]
	,[Контроль данных]
	,DATEDIFF (mi,dateadd(year,-2000,[Дата изменения]),[Контроль данных]) RN1
	,Статус
	FROM #dm_FillingTypeChangesInRequests s1
	left join #R_t_source s2  
	on s1.[Номер заявки]=s2.НомерЗаявки
	) s3
	where Флаг=1
	) s4
	where RN = 1
	) 
	as s5
	on f1.НомерЗаявки=s5.[Номер заявки]


	drop table if exists #products

	   select НомерЗаявки
		, case
		when isPdl=1 then 'non-RBP'
		when isInstallment=1 then 'non-RBP'

			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 3' then 'RBP - 66'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 4' then 'RBP - 86'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 2' then 'RBP - 56'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 1' then 'RBP - 40'  
		  when ВариантПредложенияСтавки=  0xB83300505683CF4D11ED40333CBCED81 then 'RBP - 86' --Предложение21

		   when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95252 then 'RBP - 86' --Предложение13
		   when ВариантПредложенияСтавки=  0xB82D00505683CF4D11EC426681C6F03B then 'RBP - 66' --Предложение20
		   when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95253 then 'RBP - 56' --Предложение14
		   when ВариантПредложенияСтавки=  0xB81400155DFABA2A11E9F8551BC95254 then 'RBP - 40' --Предложение15
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBAEAE5ABFA6A0 then 'RBP - 40' --Предложение16
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A8 then 'RBP - 40' --Предложение17
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A7 then 'RBP - 40' --Предложение18
		   when ВариантПредложенияСтавки=  0xB82800505683CF4D11EBC4A9F0F286A9 then 'RBP - 56' --Предложение19
		  -- when gr.fin_gr=50 then 'RBP - 40' 												  --Июль 2020 запуск проекта
		   when [Вид займа]='Первичный' and fa.Дата >='20210604' then 'RBP - 86' --После 2021 4 июля все первичные RBP по умолчанию

		   else 'non-RBP' end RBP
	, case  

			
			when isPdl=1 and [Вид займа]='Первичный'  then 'Первичный займ: PDL'
			when isPdl=1 and [Вид займа]<>'Первичный' then 'Повторный займ: PDL'
			when isInstallment=1 and [Вид займа]='Первичный'  then 'Первичный займ: installment'
			when isInstallment=1 and [Вид займа]<>'Первичный' then 'Повторный займ: installment'


			when fa.[Испытательный Срок]=1 then 'Исп. срок'
			when ras.rbp_gr='NotRBP_PROBATION' then 'Исп. срок'
			when fa.[Признак Рефинансирование]=1 then 'Рефинансирование'

			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 3' then 'Первичные: RBP - 66'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 4' then 'Первичные: RBP - 86'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 2' then 'Первичные: RBP - 56'  
			when [Вид займа] ='Первичный' and [Верификация КЦ]>='20210101' and isInstallment=0 and   ras.rbp_gr='RBP 1' then 'Первичные: RBP - 40'  
			when [Вид займа]='Повторный' then 'Повторный займ'
			when [Вид займа] in ('Докредитование' ,'Параллельный')  then 'Докредитование'




			when ВариантПредложенияСтавки in (  0xB81400155DFABA2A11E9F8551BC95254, 0xB82800505683CF4D11EBAEAE5ABFA6A0, 0xB82800505683CF4D11EBC4A9F0F286A8, 0xB82800505683CF4D11EBC4A9F0F286A7) --or gr.fin_gr=50 
			then 'Первичные: RBP - 40'
			when [Вид займа]='Первичный' and ВариантПредложенияСтавки in ( 0xB81400155DFABA2A11E9F8551BC95252 , 0xB83300505683CF4D11ED40333CBCED81) then 'Первичные: RBP - 86'
			when [Вид займа]='Первичный' and ВариантПредложенияСтавки = 0xB82D00505683CF4D11EC426681C6F03B  then 'Первичные: RBP - 66'
			when [Вид займа]='Первичный' and ВариантПредложенияСтавки in (0xB81400155DFABA2A11E9F8551BC95253  , 0xB82800505683CF4D11EBC4A9F0F286A9) then 'Первичные: RBP - 56'
			when [Вид займа]='Первичный' and fa.Дата >='20210604' then 'Первичные: RBP - 86'
			when [Вид займа]='Первичный' then 'Первичные: non-RBP'
			when [Вид займа]='Повторный' then 'Повторный займ'
			when [Вид займа] in ('Докредитование' ,'Параллельный')  then 'Докредитование'
			end as product
			into #products
	   from #R_t_source	  fa
	   	left join dwh2.dbo.v_risk_apr_segment ras on ras.number=fa.НомерЗаявки




drop table if exists #tt_end

SELECT *, getdate() as 'Дата отчета'
into #tt_end
FROM
(
SELECT  --distinct --ВсеЗаявки.*
--ВсеЗаявки.ЗаявкиЛид,
			 ВсеЗаявки.ДатаЗаявки as [Дата]
			, ВсеЗаявки.ВремяЗаявки as [Время]
			, ВсеЗаявки.НомерЗаявки as [Номер]
			, ВсеЗаявки.ТекущийСтатус as [Текущий статус]
			--, isnull(exc.[Место cоздания], ВсеЗаявки.СпособОформления) as [Место cоздания]
			, ВсеЗаявки.СпособОформления as [Место cоздания]
			, poc2.Место_создания_2 as [Место создания 2]
			, ВсеЗаявки.Автор as [Автор]
			, ВсеЗаявки.причинаотказа as [Причина отказа]
			, cu.офис_to_be [офис ссылка]
			, a3_3.Наименование  as [РО_регион]
			, a3_2.Наименование as [РП]
			, a4.Наименование Юрлицо
			, ВсеЗаявки.АдресПроживания as [Регион]	 -- переделать на основании справочника 
			,  a3.Наименование as [Партнер]
			--, ЗаявкаМФО.[ЗаявкаТочка] as [Партнер]
			--, ЗаявкаМФО.[ЗаявкаТочкаКод] as [Номер партнера]
			, ВсеЗаявки.[Номер точки при создании]  as [Номер точки при создании]
			, ВсеЗаявки.[Юрлицо при создании]  as [Юрлицо при создании]
			, a3.Код  as [Номер партнера]
			, a3_crm.Код as [Номер партнера CRM]
		
			, ВсеЗаявки.АдресПроживания as [Регион проживания]



			, ВсеЗаявки.[Вид займа] as [Вид займа]
			, p.product product
			, p.RBP
			, case 
			when ВсеЗаявки.[Вид займа] in ('Докредитование', 'Параллельный') and isInstallment=0 and isPDL=0 then  isnull(c_dip.category_docredy , '') 
			when ВсеЗаявки.[Вид займа] in ('Повторный' ) and isInstallment=0 and isPDL=0 then  isnull(c_dip.category_povt , '') 
			end [Категория повторного клиента]
			, ВсеЗаявки.isInstallment as isInstallment
			, ВсеЗаявки.isSmartInstallment as isSmartInstallment
			, ВсеЗаявки.isPdl as isPdl
			, case when ВсеЗаявки.isInstallment =0 and ВсеЗаявки.isSmartInstallment=0 and ВсеЗаявки.isPdl=0 then 1 else 0 end as isPts
			, КредПродукт.НаименованиеПродуктаНаСайте as [Продукт]
			, ВсеЗаявки.[Признак Рефинансирование] 
			, КредПродукт.МаксСрок as [Срок займа]
			, ВсеЗаявки.[СрокЛьготногоПериода]	[СрокЛьготногоПериода]

				
			, ВсеЗаявки.[СуммаЗаявкиПервичная] as [Первичная сумма]
			, ВсеЗаявки.[СуммаЗаявкиОдобренная] as [Сумма одобренная]
			, ВсеЗаявки.РыночнаяОценкаСтоимости as [Стоимость ТС]
			-- 14.02.2020 добавляем данные из P2P сумму по выдаче  
			--20.02 2020 пишем сумму CMR, если есть статус выданного займа в  CRM. Иначе P2P
			, iif(ВсеЗаявки.[Заем выдан] is null, null,  iif([Заем выдан CRM] is null, cast(ВсеЗаявки.[СуммаЗаявкиВыданнаяP2P]  as numeric(15,0)),  cast(Договор.СуммаВыдачи  as numeric(15,0))))  as [Выданная сумма]
			
 --, agr.Срок Срок
, nullif(agr.ПроцСтавкаКредит, 0) [Процентная ставка]
			--, iif(ВсеЗаявки.[Заем выдан] is null, null, cast(Договор.Сумма as numeric(15,0))) as [Выданная сумма]
			, ВсеЗаявки.СуммаЗаявки as [Сумма заявки]
			--, ВсеЗаявки.[СуммаЗаявкиВыданная]
			, СпВыдачи.Представление as [Способ выдачи],
			agr.ПризнакКП [Признак Комиссионный Продукт],
			agr.ПризнакКоробочныйПродукт [Признак Коробочный Продукт],
agr.ПризнакСтраховка [Признак Страховка],
agr.СуммаДопУслугCarmoneyNet [Сумма Дополнительных Услуг Carmoney Net],
agr.СуммаДопУслугCarmoney [Сумма Дополнительных Услуг Carmoney],
agr.СуммаДопУслуг [Сумма Дополнительных Услуг],
agr.ПризнакКаско [Признак Каско],
agr.ПризнакСтрахованиеЖизни [Признак Страхование Жизни],
agr.ПризнакРАТ [Признак РАТ],
--agr.ПризнакПозитивНастр [],
agr.ПризнакПомощьБизнесу [Признак Помощь Бизнесу],
agr.ПризнакТелемедицина [Признак Телемедицина], 
agr.[Признак Защита от потери работы] [Признак Защита от потери работы],
agr.ПризнакФарма [Признак Фарма],
agr.ПризнакСпокойнаяЖизнь [Признак Спокойная Жизнь],
agr.ПризнакРАТЮруслуги [Признак РАТ Юруслуги],
agr.ПризнакАвтоспор [Признак Автоспор],
 
 
 agr.[SumKasko] [Сумма КАСКО],
 agr.[SumKaskoCarmoney] [Сумма КАСКО Carmoney],
 agr.[SumKaskoCarmoneyNet] [Сумма КАСКО Carmoney Net],
 agr.[SumEnsur] [Сумма страхование жизни],
 agr.[SumEnsurCarmoney] [Сумма страхование жизни Carmoney],
 agr.[SumEnsurCarmoneyNet] [Сумма страхование жизни Carmoney Net],
 agr.[SumRat] [Сумма РАТ],
 agr.[SumRatCarmoney] [Сумма РАТ Carmoney] ,
 agr.[SumRatCarmoneyNet] [Сумма РАТ Carmoney Net],
-- agr.[SumPositiveMood],
-- agr.[SumPositiveMoodCarmoney],
 --agr.[SumPositiveMoodCarmoneyNet],
 agr.[SumHelpBusiness] [Сумма Помощь бизнесу],
 agr.[SumHelpBusinessCarmoney] [Сумма Помощь бизнесу Carmoney],
 agr.[SumHelpBusinessCarmoneyNet] [Сумма Помощь бизнесу Carmoney Net],
 agr.[SumTeleMedic] [Сумма Телемедицина],
 agr.[SumTeleMedicCarmoney] [Сумма Телемедицина Carmoney],
 agr.[SumTeleMedicCarmoneyNet] [Сумма Телемедицина Carmoney Net],
 agr.[SumCushion] [Сумма Защита от потери работы],
 agr.[SumCushionCarmoney] [Сумма Защита от потери работы Carmoney],
 agr.[SumCushionCarmoneyNet] [Сумма Защита от потери работы Carmoney Net],
 agr.[SumPharma] [Сумма Фарма],
 agr.[SumPharmaCarmoney] [Сумма Фарма Carmoney],
 agr.[SumPharmaCarmoneyNet] [Сумма Фарма Carmoney Net],
 agr.SumQuietLife [Сумма Спокойная Жизнь],
 agr.SumQuietLifeCarmoney [Сумма Спокойная Жизнь Carmoney],
 agr.SumQuietLifeCarmoneyNet [Сумма Спокойная Жизнь Carmoney Net],
 agr.SumRatJudical [Сумма РАТ Юруслуги],
 agr.SumRatJudicalCarmoney [Сумма РАТ Юруслуги Carmoney],
 agr.SumRatJudicalCarmoneyNet [Сумма РАТ Юруслуги Carmoney Net]	 ,
 agr.Автоспор [Сумма Автоспор],
 agr.[Автоспор carmoney] [Сумма Автоспор carmoney],
 agr.[Автоспор carmoney Net] [Сумма Автоспор carmoney Net]
			, ВсеЗаявки.[Верификация КЦ]
			, ВсеЗаявки.[Предварительное одобрение]
			, ВсеЗаявки.[Встреча назначена]
			, ВсеЗаявки.[Контроль данных]
			, ВсеЗаявки.Call2
			, ВсеЗаявки.[Call2 accept]
			, ВсеЗаявки.[Верификация документов клиента]
			, ВсеЗаявки.[Одобрены документы клиента]
			, ВсеЗаявки.[Верификация документов]
			, ВсеЗаявки.Одобрено
			, ВсеЗаявки.[Договор зарегистрирован]
			, ВсеЗаявки.[Договор подписан]
			, ВсеЗаявки.[Заем выдан]
			, ВсеЗаявки.[Заем погашен]
			, ВсеЗаявки.[Заем аннулирован]
			, ВсеЗаявки.Аннулировано
			, ВсеЗаявки.[Отказ документов клиента]
			, ВсеЗаявки.Отказано
			, ВсеЗаявки.[Отказ клиента]
			, ВсеЗаявки.Забраковано
			

			, iif(ВсеЗаявки.[Верификация КЦ] is null, NULL,1) as ПризнакЗаявка
			--, iif(ВсеЗаявки.[Верификация КЦ] is null, NULL,1) as ПризнакВерификацииКЦ
			, iif(ВсеЗаявки.[Предварительное одобрение] is null, NULL,1) as ПризнакПредварительноеОдобрение
			, iif(ВсеЗаявки.[Встреча назначена] is null, NULL,1) as ПризнакВстречаНазначена
			, iif(ВсеЗаявки.[Контроль данных] is null, NULL,1) as ПризнакКонтрольДанных
			, iif((ВсеЗаявки.[Встреча назначена] is not null) and (ВсеЗаявки.[Контроль данных] is not null),1, NULL) as ПризнакКонтрольДанныхИзФактическихВстреч
			, iif(ВсеЗаявки.[Верификация документов клиента] is null, NULL,1) as ПризнакВерификацияДокументовКлиента
			, iif(ВсеЗаявки.[Одобрены документы клиента] is null, NULL,1) as ПризнакОдобреныДокументовКлиента
			, iif(ВсеЗаявки.[Верификация документов] is null, NULL,1) as ПризнакВерификацияДокументов
			, iif(ВсеЗаявки.[Одобрено] is null, NULL,1) as ПризнакОдобрено
			, iif(ВсеЗаявки.[Договор зарегистрирован] is null, NULL,1) as ПризнакДоговорЗарегистрирован
			, iif(ВсеЗаявки.[Договор подписан] is null, NULL,1) as ПризнакДоговорПодписан
			, iif(ВсеЗаявки.[Заем выдан] is null, NULL,1) as ПризнакЗайм
			, iif(ВсеЗаявки.[Отказано] is null, NULL,1) as ПризнакОтказано
			, iif(ВсеЗаявки.[Отказ клиента] is null, NULL,1) as ПризнакОтказКлиента		

			, iif(ВсеЗаявки.[Заем выдан] is null, NULL, (DATEDIFF(day,cast(ВсеЗаявки.[Дата] as date) , cast(ВсеЗаявки.[Заем выдан] as date)) ))  as ЛагЗаявкаЗаймДней
			, iif(ВсеЗаявки.[Заем выдан] is null, NULL, iif(cast(ВсеЗаявки.[Дата] as date)<>cast(ВсеЗаявки.[Заем выдан] as date),N'Не день в день',N'День в день')) as ЛагКрупноЗаявкаЗайм


			, case when cast(ВсеЗаявки.[Дата] as date)= cast(ВсеЗаявки.[Заем выдан] as date) and ВсеЗаявки.[Заем выдан] is not null  then 1 else NULL end as [ПризнакЗаймДеньВДень]
			, case when cast(ВсеЗаявки.[Дата] as date)<>cast(ВсеЗаявки.[Заем выдан] as date) and ВсеЗаявки.[Заем выдан] is not null  then 1 else NULL end as [ПризнакЗаймНеДеньВДень]
			
			, iif(ВсеЗаявки.[Контроль данных] is null or ВсеЗаявки.[Встреча назначена] is null, NULL,
				iif(DATEDIFF(day,cast(ВсеЗаявки.[Встреча назначена] as date), cast(ВсеЗаявки.[Контроль данных] as date))<=0, NULL, DATEDIFF(day,cast(ВсеЗаявки.[Встреча назначена] as date), cast(ВсеЗаявки.[Контроль данных] as date)))
				) as ЛагВстречаКонтрольДанныхВДнях
			, iif(ВсеЗаявки.[Контроль данных] is null or ВсеЗаявки.[Встреча назначена] is null, NULL,
				iif(DATEDIFF(day,cast(ВсеЗаявки.[Встреча назначена] as date), cast(ВсеЗаявки.[Контроль данных] as date)) is null, NULL, 
						iif(DATEDIFF(day,cast(ВсеЗаявки.[Встреча назначена] as date), cast(ВсеЗаявки.[Контроль данных] as date))=0,1,0)
					)
				) as ЛагВстречаКонтрольДанныхДеньВДеньДней
			, iif(ВсеЗаявки.[Контроль данных] is null or ВсеЗаявки.[Встреча назначена] is null, NULL,
			       iif(DATEDIFF(day,cast(ВсеЗаявки.[Встреча назначена] as date), cast(ВсеЗаявки.[Контроль данных] as date))>0,1,NULL)
			     ) as ЛагВстречаКонтрольДанныхНеДеньВДеньДней
			
			-- Зеленые
			, NULL НеПрошлиКД  -- Время от встреча назначена до КД
			-- КДраньшеВстречиИЛИБезВстречи
			, iif(ВсеЗаявки.[Контроль данных] is null, null, 
					iif(ВсеЗаявки.[Встреча назначена] is null and ВсеЗаявки.[Контроль данных] is not null , 1, 
					   iif(ВсеЗаявки.[Встреча назначена] > ВсеЗаявки.[Контроль данных],1, null)
					   )
			  )	as КДраньшеВстречиИЛИБезВстречи

			  -- КДБезНазначеннойВстречи
			  , iif(ВсеЗаявки.[Контроль данных] is null, null, 
					iif(ВсеЗаявки.[Встреча назначена] is null, 1, null)
					) as КДБезНазначеннойВстречи


			  -- Бежевый
			, iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(day,cast(ВсеЗаявки.[Одобрено] as date), cast(ВсеЗаявки.[Заем выдан]  as date))) as ЛагОдобреноЗаймДней
			, iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено]  is null , null, 
				iif(DATEDIFF(day,cast(ВсеЗаявки.[Одобрено] as date), cast(ВсеЗаявки.[Заем выдан]  as date))>0,NULL,1)) as ЛагОдобреноЗайм_День_в_день
			, iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено]  is null , null, 
				iif(DATEDIFF(day,cast(ВсеЗаявки.[Одобрено] as date), cast(ВсеЗаявки.[Заем выдан]  as date))>0,1,NULL)) as ЛагОдобреноЗайм_Не_День_в_день

			-- Оранжевый
			, iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Контроль данных] is null, null, 
				DATEDIFF(day,cast(ВсеЗаявки.[Контроль данных] as date), cast(ВсеЗаявки.[Заем выдан]  as date))) as ДИАПАЗОН_КД_ЗаймДней
			, iif(iif(ВсеЗаявки.[Встреча назначена] is null or ВсеЗаявки.[Контроль данных] is null, 0, 
					iif(
							iif((ВсеЗаявки.[Встреча назначена] is not null) and (ВсеЗаявки.[Контроль данных] is not null),1,0) =1
							and iif(ВсеЗаявки.[Одобрено] is null,0,1)=1
							,1,0
						)
				)<=0, NULL,1) as ОдобреноОтКД_со_встр

			, iif(iif(iif((ВсеЗаявки.[Встреча назначена] is null) and (ВсеЗаявки.[Контроль данных] is not null),1,0) =1
					and iif(ВсеЗаявки.[Одобрено] is null,0,1)=1
					,1,0
				)<=0,NULL,1) as ОдобреноОтКД_без_встр

			,iif(ВсеЗаявки.[Одобрено] is null , null,  
			    iif(ВсеЗаявки.[Одобрено] is not null and ВсеЗаявки.[Заем выдан] is null,1,0)
				)as ОдобреноНоЗаймНеВыдан

			,iif(ВсеЗаявки.[Одобрено] is null or ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Контроль данных] is null or ВсеЗаявки.[Встреча назначена] is null, null,   
					iif (
							iif(
									iif((ВсеЗаявки.[Встреча назначена] is not null) and (ВсеЗаявки.[Контроль данных] is not null),1,0) =1
									and iif(ВсеЗаявки.[Одобрено] is null,0,1)=1
									,1,0
								) = 1 and ВсеЗаявки.[Заем выдан] is not null,1,0
						 ) 			
				)as ЗаймОтОдобр_вст

			,iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Контроль данных] is null, null,   
			iif (
					iif(
							iif((ВсеЗаявки.[Встреча назначена] is null) and (ВсеЗаявки.[Контроль данных] is not null),1,0) =1
							and iif(ВсеЗаявки.[Одобрено] is null,0,1)=1
							,1,0
						) = 1 and ВсеЗаявки.[Заем выдан] is not null,1,0
					) 		
			  ) as ЗаймОтОдобр_без_вст


-- серый

			, iif(ВсеЗаявки.[Контроль данных] is null, null,
			     iif(ВсеЗаявки.[Встреча назначена] is null and ВсеЗаявки.[Контроль данных] is not null,N'КД без назначенной встречи',
					iif(ВсеЗаявки.[Встреча назначена]> ВсеЗаявки.[Контроль данных],N'КД раньше, чем Встреча назначена',
					 cast((DATEDIFF(minute,ВсеЗаявки.[Встреча назначена] , ВсеЗаявки.[Контроль данных] )) as nvarchar(18))
					 )
					)
			     ) as ВремяОтВстречаНазначенаДоКДМинут

			,  case when iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(minute,ВсеЗаявки.[Одобрено], ВсеЗаявки.[Заем выдан] ))<15 then N'до 15 мин'
					when iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(minute,ВсеЗаявки.[Одобрено], ВсеЗаявки.[Заем выдан] ))<30 then N'15-30 мин' 
					when iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(minute,ВсеЗаявки.[Одобрено], ВсеЗаявки.[Заем выдан] ))<60 then N'30 мин-1 час' 
					when iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(minute,ВсеЗаявки.[Одобрено], ВсеЗаявки.[Заем выдан] ))<180 then N'1-3 часа' 
					when iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(minute,ВсеЗаявки.[Одобрено], ВсеЗаявки.[Заем выдан] ))<420 then N'3-7 часов' 
					when iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(minute,ВсеЗаявки.[Одобрено], ВсеЗаявки.[Заем выдан] ))<600 then N'7-10 часов' 
					when iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null, null, 
				DATEDIFF(minute,ВсеЗаявки.[Одобрено], ВсеЗаявки.[Заем выдан] ))>=600 then N'более 10 часов' 
					when (ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Одобрено] is null) then N'Не выдано'
					else N'Не выдано'
				end
				as Диапазон5


			-- Время ВремяОтВерификацияКЦДоВыдачи
			, iif(ВсеЗаявки.[Заем выдан] is null or ВсеЗаявки.[Верификация КЦ] is null, null,
			     iif(ВсеЗаявки.[Верификация КЦ] is null and ВсеЗаявки.[Заем выдан] is not null, NULL,
					 DATEDIFF(hour,ВсеЗаявки.[Верификация КЦ] , ВсеЗаявки.[Заем выдан])
					 )
			     ) as ВремяОтВерификацияКЦДоВыдачиЧасы

		

			, DATEPART(ISO_WEEK, ВсеЗаявки.[Верификация КЦ]) НеделяЗаявки
			, DATEPART(ISO_WEEK, ВсеЗаявки.[Заем выдан]) НеделяЗайма

					   
		    , CHOOSE(month(ВсеЗаявки.[Заем выдан]), N'Январь', N'Февраль', N'Март', N'Апрель', N'Май', N'Июнь',N'Июль', N'Август', N'Сентябрь', N'Октябрь', N'Ноябрь', N'Декабрь') as 'МесяцВыдач'
  			, DATEPART(yy, ВсеЗаявки.[Заем выдан]) ГодВыдачи
			
	


			, CHOOSE(month(ВсеЗаявки.[Верификация КЦ]), N'Январь', N'Февраль', N'Март', N'Апрель', N'Май', N'Июнь',N'Июль', N'Август', N'Сентябрь', N'Октябрь', N'Ноябрь', N'Декабрь') as 'МесяцЗаявки'
	
			-- *********************************************
			, ВсеЗаявки.[Телефон]
			, TimeToCash.medianTest2 as TTC_number
			, iif( TimeToCash.medianTest2 is null, null, iif( TimeToCash.medianTest2=1, 'Самые быстрые', iif(TimeToCash.medianTest2=4, 'Самые медленные','Медиана' ))) as TTC
--
			, cast(ВсеЗаявки.Дата as datetime) as ДатаЗаявкиПолная -- перенести в конец
			, case when ВсеЗаявки.[Заем выдан] is not null then 0 
				   when cu.Дубль is not null then 	 cu.Дубль
				--   when exc.Дубль is not null then 	 exc.Дубль
			       when Дубль.Номер is not null then  1
				   
			  else 0 end Дубль -- перенести в конец
			
			, cast( null as int) Дубль_ClientGuid  -- перенести в конец
			--, iif(ВсеЗаявки.[Заем выдан] is not null, 0, iif(Дубль_ClientGuid.Номер is not null, 1,0)) Дубль_ClientGuid  -- перенести в конец

			, iif(ВсеЗаявки.Забраковано is null, NULL,1) as ПризнакЗабраковано
			, iif( ВсеЗаявки.[Отказ документов клиента] is null , NULL,1) as 'Признак Отказ документов клиента'
			, DATEPART(yy, ВсеЗаявки.Дата) ГодЗаявки
			, ВсеЗаявки.ФИО
			, ВсеЗаявки.[СуммарныйМесячныйДоход]

			--, iif(ВсеЗаявки.[Заем выдан] is not null, 0, iif(Дубль_ClientGuid2.Номер is not null, 1,0)) Дубль_ClientGuidОдинДень -- перенести в конец
			, cast( 0 as int) Дубль_ClientGuidОдинДень -- перенести в конец
							
			, ВсеЗаявки.P2P as P2P
			, iif(ВсеЗаявки.P2P is null, NULL,1) as ПризнакP2P	
			, ВсеЗаявки.ЗаявкиСсылка 'Ссылка заявка'
			, ВсеЗаявки.Партнер 'Ссылка клиент'
             ,L_C_R_M.id as [LCRM ID]
             ,L_C_R_M.original_lead_id as original_lead_id
             ,L_C_R_M.marketing_lead_id as marketing_lead_id

			, isnull(cu.источник,  L_C_R_M.Источник ) Источник
			, L_C_R_M.[Тип трафика] [Тип трафика]
			, L_C_R_M.[Вебмастер] [Вебмастер]
			, L_C_R_M.[Приоритет обзвона] [Приоритет обзвона]
			, L_C_R_M.[Кампания utm] [Кампания utm]
			,  L_C_R_M.[Канал от источника лид]   as [Канал от источника лид]
			,  l.[Канал от источника]   as [Канал от источника]
			,  l.[Группа каналов]           as [Группа каналов]	
			,case when cu.источник is not null then '/Источник(excel)/' else '' end +  cu.[Exceptions info] [Exceptions info]
			, ВсеЗаявки.TransitionsJSON
			, parent.parentGuid
FROM  #R_t_source as ВсеЗаявки
left join #agr agr on agr.Код=ВсеЗаявки.НомерЗаявки and ВсеЗаявки.[Заем выдан] is not null
left join #categories_DIP c_dip on c_dip.Ссылка=ВсеЗаявки.ЗаявкиСсылка
left join #columns_updated_stg2 cu on cu.ЗаявкиСсылка=ВсеЗаявки.ЗаявкиСсылка
left join #R_t_dubl Дубль on Дубль.Номер = ВсеЗаявки.НомерЗаявки
left join #products p on p.НомерЗаявки = ВсеЗаявки.НомерЗаявки
left join #v_dm_place_of_creation_2 poc2 on poc2.Номер = ВсеЗаявки.НомерЗаявки
left join 
(select    
		rch.номер,
		rch.id
		, rch.UF_STAT_CAMPAIGN   [Кампания utm]
		, rch.UF_SOURCE   Источник
		, rch.UF_PARTNER_ID   [Вебмастер]
		, rch.[UF_LOGINOM_PRIORITY]   [Приоритет обзвона]
		, rch.UF_TYPE [Тип трафика]
		, rch.[Канал от источника лид]
		, rch.marketing_lead_id
		, rch.original_lead_id
		
			FROM   #real_channel rch 
			
			) 
as L_C_R_M
on ВсеЗаявки.НомерЗаявки =  L_C_R_M.номер
left join #Справочник_офисы a3 on cu.офис_to_be=a3.Ссылка
left join #Справочник_офисы a3_crm on ВсеЗаявки.Офис_CRM=a3_crm.Ссылка
left join #Справочник_Партнеры a4 on a3.Партнер=a4.Ссылка
left join #Справочник_офисы a3_2 on a3_2.Ссылка = a3.Родитель
left join #Справочник_офисы a3_3 on a3_3.Ссылка = a3_2.Родитель
left join #d Договор on Договор.Код = ВсеЗаявки.НомерЗаявки  
left join #ttc as TimeToCash on TimeToCash.Ссылка = ВсеЗаявки.ЗаявкиСсылка
left join [Stg].[_1cMFO].[Справочник_ГП_КредитныеПродукты] КредПродукт on ВсеЗаявки.КредитныйПродукт = КредПродукт.Ссылка
left join [Stg].[_1cCRM].[Перечисление_СпособыВыдачиЗаймов] СпВыдачи  on ВсеЗаявки.СпособВыдачиЗайма = СпВыдачи.Ссылка
left join #leadRef1_buffer l on cu.[Канал от источника_to_be]=l.[Канал от источника]
left join #parent parent on parent.number=ВсеЗаявки.НомерЗаявки
where ВсеЗаявки.[Верификация КЦ] is not null AND ISNUMERIC(CAST( ВсеЗаявки.НомерЗаявки AS varchar))=1

) as a2
;
with v as(
select ROW_NUMBER() over(partition by Номер order by (select null)) rn , *  from #tt_end
)
delete from v where rn>1

--select * from #tt_end
--where источник like '%' + 'infos' + '%' and [Канал от источника лид] not like '%' + 'целе' + '%'

 


--select * from  #tt_end a   join [dm_Factor_Analysis_001] b on a.номер=b.номер
--and a.источник<> b.источник
--order by a.номер desc

--  CHECK IF INSERT WORKS
--	drop table if exists [#dm_Factor_Analysis_001_staging]
--	select top(0) * 
--	into 	[#dm_Factor_Analysis_001_staging]
--	from [dm_Factor_Analysis_001]
--	insert into   [#dm_Factor_Analysis_001_staging]
--	select * from  #tt_end

 

if @recreate_table = 1  

begin

	drop table if exists [dm_Factor_Analysis_001_staging]
	select top(0) * 
	into [dm_Factor_Analysis_001_staging]
	from #tt_end
	
	drop table if exists [dm_Factor_Analysis_001]
	select top(0) * 
	into [dm_Factor_Analysis_001]
	from #tt_end

end


drop table if exists dbo.dm_Factor_Analysis_001_to_del
select top(0) * 
into dm_Factor_Analysis_001_to_del
from [dm_Factor_Analysis_001]



if exists(select top(1) 1 from #tt_end)
begin
	--Отчистим таблицу - хотя после пред операции она и так будет пустая
	delete from dm_Factor_Analysis_001_staging with(tablockx)
	insert into [dbo].dm_Factor_Analysis_001_staging  with(tablockx)
	SELECT *
	from #tt_end

--	select * from  cte_fa _001

	begin tran
		alter table [dbo].[dm_Factor_Analysis_001]
			switch to dm_Factor_Analysis_001_to_del
		--delete from reports.[dbo].[dm_Factor_Analysis_001]
		alter table dm_Factor_Analysis_001_staging 
			switch  to [dm_Factor_Analysis_001]
	commit tran
end


END


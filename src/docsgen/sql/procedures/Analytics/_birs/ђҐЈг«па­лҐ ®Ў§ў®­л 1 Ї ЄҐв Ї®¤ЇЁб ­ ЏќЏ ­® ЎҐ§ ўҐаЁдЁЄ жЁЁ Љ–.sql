

CREATE   proc [_birs].[Регулярные обзвоны 1 пакет подписан ПЭП но без верификации КЦ]

@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin


--grant execute on dbo.getGUIDFrom1C_IDRREF to reportviewer

--declare @start_date date = getdate()
declare @start_date date = @start_date_ssrs
--declare @end_date date = getdate()
declare @end_date date = @end_date_ssrs
--
--select * from stg._1cCRM.Справочник_СобытияЗаявокНаЗаймПодПТС
--where наименование='1-й пакет подписан ПЭП'
----0xB81800155D03492D11E9F37A24CBB558

drop table if exists [#1-й пакет подписан ПЭП]
select Analytics.dbo.getGUIDFrom1C_IDRREF(Объект) заявка_guid, dateadd(year, -2000, min(Дата)) Дата
into [#1-й пакет подписан ПЭП]
from stg._1cCRM.РегистрСведений_ИсторияСобытийЗаявокНаЗаймПодПТС  a
where событие=0xB81800155D03492D11E9F37A24CBB558
and dateadd(year, -2000, cast(Дата as date)) between @start_date  and @end_date 
group by Объект

--select top 100 * from stg._1cCRM.РегистрСведений_ИсторияСобытийЗаявокНаЗаймПодПТС  a
--where событие=0xB81800155D03492D11E9F37A24CBB558
--order by 3 desc



--select * from Stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС
--where наименование='Верификация КЦ'
--0xA81400155D94190011E80784923C60A2

drop table if exists [#Верификация КЦ]
select Analytics.dbo.getGUIDFrom1C_IDRREF(заявка) заявка_guid, dateadd(year, -2000, min(Период)) Дата
into [#Верификация КЦ]
from stg.[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС]
where статус=0xA81400155D94190011E80784923C60A2
group by заявка

declare @last_update_actions datetime = (select max(Дата) from  [#1-й пакет подписан ПЭП]  a)
--select @last_update_actions
declare @last_update_status datetime = (select max(Дата) from  [#Верификация КЦ]  a)
--select @last_update_status



drop table if exists #Документ_ЗаявкаНаЗаймПодПТС
select Analytics.dbo.getGUIDFrom1C_IDRREF(ссылка) заявка_guid, Номер 
into #Документ_ЗаявкаНаЗаймПодПТС
from 
stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z

drop table if exists #lkr
select code, guid заявка_guid, client_first_name, num_1c , is_installment, id, client_id, client_mobile_phone, created_at into #lkr
from 
 stg._LK.requests a
 where
  cast( a.created_at as date) between  @start_date and @end_date 
--and c.Дата is null  and b.Дата is not null
and a.num_1c is null

drop table if exists #fa
select Телефон,  Отказано   , ДатаЗаявкиПолная , Аннулировано  , Одобрено , [Заем выдан]  , [Заем аннулирован] into #fa								
from reports.dbo.dm_Factor_Analysis_001  a								
								
create nonclustered index t on #fa								
(								
Телефон, ДатаЗаявкиПолная								
)								
		
drop table if exists #bl
select cast(Phone  as nvarchar(10)) UF_PHONE into #bl
from stg._1ccrm.BlackPhoneList

CREATE CLUSTERED INDEX T ON #lkr ( заявка_guid)
CREATE CLUSTERED INDEX T ON #Документ_ЗаявкаНаЗаймПодПТС ( заявка_guid)
CREATE CLUSTERED INDEX T ON [#Верификация КЦ] ( заявка_guid)
CREATE CLUSTERED INDEX T ON [#1-й пакет подписан ПЭП] ( заявка_guid)


select 
a.client_mobile_phone
, a.client_first_name
, a.num_1c
, b.Дата [1-й пакет подписан ПЭП]
, a.created_at
from 
#lkr a
join [#1-й пакет подписан ПЭП] b on  b.заявка_guid=a.заявка_guid
left join [#Верификация КЦ] c on c.заявка_guid=a.заявка_guid
left join #Документ_ЗаявкаНаЗаймПодПТС z on Z.заявка_guid=a.заявка_guid AND ISNUMERIC(Z.Номер) IS NOT NULL
left join #fa fa on  fa.ДатаЗаявкиПолная between dateadd(day, -5, a.created_at ) and  dateadd(day, 5, a.created_at ) and  a.client_mobile_phone=fa.Телефон and fa.Аннулировано is null and fa.[Заем аннулирован] is null and fa.Отказано is null							
left join #bl bl on bl.UF_PHONE=a.client_mobile_phone
where  c.Дата is null  AND Z.заявка_guid IS NULL
and fa.Телефон is null
and bl.UF_PHONE is null
and a.is_installment=0



end

CREATE   proc [dbo].[get_monitoring_letter_each_day] @debug int = 0
as 
--exec  [dbo].[get_monitoring_letter_each_day] 1
begin

if datepart(hour, getdate()) between 2 and 6
return

set nocount off;

drop table if exists ##monitoring_letter_each_day;
CREATE TABLE ##monitoring_letter_each_day(
	[Текст]   [nvarchar](max) NOT NULL,
	[send_to] [nvarchar](max) NOT NULL,
	[subject] [nvarchar](max) NOT NULL
)

--select * from ##monitoring_letter_each_day

insert into ##monitoring_letter_each_day
select *  from (select top 1 'Не готова V_loans' Текст from Analytics.dbo.v_loans where [Дата обновления записи по займу]<cast(getdate() as date) ) a1 
, 
(select 'p.ilin@techmoney.ru' [send_to], 'Не готова V_loans' [subject] ) a2 where Текст is not null




insert into ##monitoring_letter_each_day
select *  from (
select 'Не занесены выдачи - '+STRING_AGG(cast(a.Номер as nvarchar(max)), ',') Текст from reports.dbo.dm_report_pep3_loans_sales_info a
left join reports.ssrsRW.dm_report_pep3_sales b on a.Номер=b.external_id
where cast( a.ДатаВыдачи as date)=cast(getdate()-1 as date) and b.external_id is null

) a1 
, 
(select 'p.ilin@techmoney.ru; e.sorokina@carmoney.ru; l.mentgomeri@carmoney.ru; grishechkin@carmoney.ru; volchenkov@carmoney.ru' [send_to], 'Не занесены выдачи ПЭП3' [subject] ) a2 where Текст is not null




--Проверка подготовки основной витрины
insert into ##monitoring_letter_each_day
select *  from (select top 1 'Не готова MV_loans' Текст from Analytics.dbo.mv_loans where [Дата обновления записи по займу]<cast(getdate() as date) ) a1 
, 
(select 'p.ilin@techmoney.ru' [send_to], 'Не готова MV_loans' [subject] ) a2 where Текст is not null




--Проверка подготовки основной витрины
--insert into ##monitoring_letter_each_day
--select *  from (select top 1 'cityads - 3lDZYM' Текст from Feodor.dbo.dm_leads_history_cube_by_ДатаЛидаЛСРМ  where ДатаЛидаЛСРМ>getdate()-2 and uf_source='cityads' and [UF_PARTNER_ID аналитический]='3lDZYM') a1 
--, 
--(select 'p.ilin@techmoney.ru' [send_to],  'Появились лиды cityads - 3lDZYM' [subject] ) a2 where Текст is not null



----Проверка подготовки основной витрины
--insert into ##monitoring_letter_each_day
--select *  from (select top 1 'Не готова витрина КЭШ инстоллмент' Текст from Analytics.dbo.[Отчет входящий кэш инстоллмент по неделям] where created<cast(getdate() as date) and  datename(dw, getdate())='monday' ) a1 
--, 
--(select 'p.ilin@techmoney.ru' [send_to], 'Не готова витрина КЭШ инстоллмент' [subject] ) a2 where Текст is not null


if (select count(*) cnt from Analytics.dbo.[Отчет по входящим] where Дата=cast(getdate() - 1 as date ))= 0 
begin
insert into ##monitoring_letter_each_day
select *  from ( select 'Нет записей в таблице Analytics.dbo.[Отчет по входящим] за вчера'  Текст ) a1 
, 
(select 'p.ilin@techmoney.ru; a.danicheva@techmoney.ru' [send_to], 'Нет записей в таблице Analytics.dbo.[Отчет по входящим] за вчера' [subject] ) a2 where Текст is not null

end
-----------------------------------------
-----------------------------------------
--SELECT UF_ROW_ID, UF_UPDATED_AT
--into #UF_ROW_ID_rmq
--FROM [Stg].[RMQ].[ReceivedMessages_LCRM_LeadRows_byThread] with(nolock)
--where [UF_ROW_ID] is not null
--
--declare @rmq_err nvarchar(max) =  (
--select 'Нет заявок из очереди - '+isnull(STRING_AGG(cast(a.UF_ROW_ID as nvarchar(max)) , ','), 'ok') from #UF_ROW_ID_rmq a
--left join stg._LCRM.lcrm_leads_full_channel_request b on a.UF_ROW_ID=b.UF_ROW_ID
--where b.ID is null
--)
--
--
--if @rmq_err<>'Нет заявок из очереди - ok'
--
--begin
--
--insert into ##monitoring_letter_each_day
--select *  from ( select   @rmq_err  Текст ) a1 
--, 
--(select 'p.ilin@techmoney.ru' [send_to], 'Нет заявок из очереди' [subject] ) a2 where Текст is not null
--
--
--end

--declare @req_no_ch nvarchar(max) = (select STRING_AGG(cast( a.Номер+' '+[Место cоздания]+' от '+format(a.[Верификация КЦ], 'dd-MM-yyyy') as nvarchar(max)), '
--') within group(order by [Верификация КЦ] desc) from reports.dbo.dm_Factor_Analysis_001 a
--
--left join stg._LCRM.lcrm_leads_full_channel_request b with(nolock) on a.Номер=b.UF_ROW_ID
--where b.id is null and cast([Верификация КЦ] as date) between '20230401' and cast(getdate()-1 as date)	 )
--
--if @req_no_ch is not null
--exec log_email 	'Заявки без привязки для создания дефекта BP-1488', 'p.ilin@techmoney.ru', @req_no_ch



-----------------------------------------
-----------------------------------------

--drop table if exists #lcrm_def
--select Номер, [Заем выдан], телефон into #lcrm_def from reports.dbo.dm_Factor_Analysis_001 a
--left join stg._LCRM.lcrm_leads_full_channel_request b with(nolock) on a.Номер=b.UF_ROW_ID
--where b.id is null and [Заем выдан] <cast(getdate() as date)
--
--
--declare @numc_err nvarchar(max) = isnull('Займы без привязки к каналу в ДВХ:
--'+ (
--select STRING_AGG(cast( Номер+' от '+format([Заем выдан], 'dd-MM-yyyy') as nvarchar(max)), '
--') within group(order by [Заем выдан] desc) from #lcrm_def ), 'Все займы распределены по каналам')
--
--declare @numc_err_kotelevec nvarchar(max) = isnull('Займы без привязки к каналу в ДВХ:
--'+ (
--select STRING_AGG(cast( Номер+' от '+format([Заем выдан], 'dd-MM-yyyy')+' ('+телефон+')' as nvarchar(max)), '
--') within group(order by [Заем выдан] desc) from #lcrm_def ), 'Все займы распределены по каналам')


--if (select count(*) from #lcrm_def)>0
--
--begin
--
--insert into ##monitoring_letter_each_day
--select *  from ( select   @numc_err_kotelevec  Текст ) a1 
--, 
--(select 'p.ilin@techmoney.ru' [send_to], 'Займы без привязки к каналу в ДВХ' [subject] ) a2 where Текст is not null
--
--
--end
--
--declare @d_ch nvarchar(max) = 'Статистика по каналам актуальна на: ' +  format(isnull( (
--select dateadd(day, -1, cast( min( [Заем выдан]) as date))  from #lcrm_def) , getdate()-1 ), 'dd-MM-yyyy')
--insert into ##monitoring_letter_each_day
--select *  from ( select  @d_ch+'
--'+@numc_err  Текст ) a1 
--, 
--(select 'p.ilin@techmoney.ru; kuzina@carmoney.ru;  a.vdovin@carmoney.ru; blagoveschenskaya@carmoney.ru' [send_to], @d_ch [subject] ) a2 where Текст is not null





--if (select count(*) cnt 
--from reports.dbo.dm_Report_DIP_to_Naumen
--where [Дата среза]>getdate()-1
--)= 0 
--begin
--insert into ##monitoring_letter_each_day
--select *  from ( select 'Докреды и повторники не готовы'  Текст ) a1 
--, 
--(select 'p.ilin@techmoney.ru' [send_to], 'Докреды и повторники не готовы' [subject] ) a2 where Текст is not null

--end



--insert into ##monitoring_letter_each_day
--select * from (
--select Текст = string_agg(cast( 
--Номер+' партнеры перезвали на '
--+ ПризнакОформленияНовойЗаявки 
--+' из канала '+ [Группа каналов] 
--+' сумма '+ format( [Выданная сумма], '0') 
--+' дата выдачи '+ format( [Заем выдан] , 'dd.MMM.yyyy') as nvarchar(max))
--, char(13))
--
--from (
--select cast(a.Номер as nvarchar(max)) Номер, a.ПризнакОформленияНовойЗаявки, b.[Группа каналов], f.[Выданная сумма], f.[Заем выдан] from stg._1cMFO.Отчет_ВсеЗаявкиДляАналитика a
--join stg._LCRM.lcrm_leads_full_channel_request b on a.Номер=b.UF_ROW_ID
--join reports.dbo.dm_Factor_Analysis_001 f on f.Номер=a.ПризнакОформленияНовойЗаявки
--where b.[Группа каналов] not in ('Партнеры' , 'Органика') and f.[Место cоздания] like '%партнер%' 
--and f.[Заем выдан] is not null
--and cast(f.[Заем выдан]  as date) >= cast(getdate()-1 as date)
--) x
--) x
--, 
--(select 'p.ilin@techmoney.ru; a.vdovin@carmoney.ru; Semenov_V_S@carmoney.ru' [send_to], 'Перезаведенные партнерами заявки' [subject] ) a2 where Текст is not null



--if exists (
--
--select * from reports.dbo.dm_Factor_Analysis_001
--where Юрлицо='БАНК АО "СОЮЗ"'and Дубль=0
--)
--begin
--insert into ##monitoring_letter_each_day
--select *  from (select  'появились заявки БАНК АО "СОЮЗ"' Текст ) a1 
--, 
--(select 'p.ilin@techmoney.ru' [send_to], 'появились заявки БАНК АО "СОЮЗ"' [subject] ) a2 where Текст is not null
--end
--

----Тестовое письмо. Проверка доставки
--insert into ##monitoring_letter_each_day
--select *  from (select  'Тестовое письмо' Текст ) a1 
--, 
--(select 'p.ilin@techmoney.ru' [send_to], 'тест' [subject] ) a2 where Текст is not null

drop table if exists #to_send
select *, newid() id into #to_send from ##monitoring_letter_each_day
--where subject='Займы без привязки к каналу в ДВХ'

--select * from #to_send
--

declare @sql nvarchar(max) =
'
declare @Текст nvarchar(max) 
declare @send_to nvarchar(max) 
declare @subject nvarchar(max) 



' + (
select STRING_AGG( sql, ';')
from (
select cast('select @Текст = Текст, @send_to='+case when @debug=1 then '''P.Ilin@techmoney.ru''' else 'send_to' end +', @subject=subject from #to_send where id='''+cast(id as nvarchar(max))+''' exec log_email @subject, @send_to, @Текст ; 
' as nvarchar(max)) sql , * from #to_send
) x
)

--select @sql
exec (@sql)

--select top 100 * from log_emails_big
--order by 1 desc
  
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  if @debug=1
  return
  
drop table if exists #t1
select isnull(a.Number, '') Number_request, isnull(b.IdExternal,'') IdExternal_lead, b.Id Id_lead, a.Id Id_request, b.CreatedOn CreatedOn_lead, a.CreatedOn CreatedOnRequest
into #t1
from stg._fedor.core_ClientRequest a
full outer join stg._fedor.core_Lead b on a.IdLead=b.Id

--drop table if exists dbo.[лид - заявка федор]
--select *, GETDATE() dt into dbo.[лид - заявка федор]
--from #t1 
--select * from feodor.dbo.[лид - заявка федор] b

insert into feodor.dbo.[лид - заявка федор]
select  a.Number_request, a.IdExternal_lead, a.Id_lead, a.Id_request,  a.CreatedOn_lead, a.CreatedOnRequest, GETDATE() dt
from #t1 a
left join  feodor.dbo.[лид - заявка федор] b on
a.Number_request =  b.Number_request and
a.IdExternal_lead = b.IdExternal_lead
where b.IdExternal_lead is null and b.Number_request is null

;
return

select * from (
select *
, case when Id_request is not null then count(Id_lead) over(partition by Id_request ) end cnt_1
, case when Id_lead is not null then count(Id_request) over(partition by Id_lead ) end cnt_2

from feodor.dbo.[лид - заявка федор]
) x
where cnt_1>1 or cnt_2>1
order by CreatedOn_lead, CreatedOnRequest

end



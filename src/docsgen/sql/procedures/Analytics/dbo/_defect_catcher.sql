CREATE proc [dbo].[_defect_catcher] as

--delete from _defect where created='2025-04-09 10:01:10'

--select * from _defect order by created desc
 
BEGIN TRY 


SET LOCK_TIMEOUT 600000;

	 
	 

exec
sp_send_defect ' 
select  top 20 number,  productType, issued  created from request where issuedSum is null and issued <=getdate()-1
order by issued desc
'
, 'Отсутствует сумма выдачи по выдаче!!!'
 
,@to = 'p.ilin@smarthorizon.ru; a.buntova@smarthorizon.ru'
, @show_new = 1 	 


if datepart(hour, getdate())>=9 
begin
--create table _request_autocredit_call1_approved_log

drop table if exists ##_request_autocredit_call1_approved_log
select number, call1approved , phone, fio, status into ##_request_autocredit_call1_approved_log
from v_request where call1approved >='20260126' and producttype='Автокредит' and status='Предварительное одобрение' and   number not in (select * from _request_autocredit_call1_approved_log)


exec
sp_send_defect ' 

  select top 1000 number, getdate() created, call1approved call1approved , phone, fio, status   from ##_request_autocredit_call1_approved_log a
  order by call1approved desc  
'
, 'Предварительно одобрен Автокредит'
 
,@to = 'e.mashkova@carmoney.ru ; v.danilov@techmoney.ru ; a.plaksin@carmoney.ru ; semenov_v_s@carmoney.ru ; medvedev@smarthorizon.ru; ta.byvsheva@carmoney.ru'
 	 
	 insert  into _request_autocredit_call1_approved_log
select number
from ##_request_autocredit_call1_approved_log

--select number into _request_autocredit_call1_approved_log
--from ##_request_autocredit_call1_approved_log

end






exec
sp_send_defect ' select count(text) cnt, getdate() created from [оперативная витрина с выдачами и каналами агрегаты] having count(text)<>22'
, 'Проблема с сообщениями для бота'




	 

if datepart(hour, getdate())>=10 

 
exec
sp_send_defect ' 



  select top 10 call1approved created, a.number, a.guid, proposalLimitCHoise, status_crm  from request a
  join  v_request_crm b with(nolock) on a.link=b.link and b.status=''Предварительное одобрение''
  left join v_request_crm_status s with(nolock) on s.link = a.link and s.status=''Контроль данных''
  where proposalLimitCHoise is not null and proposalLimitChoiseCreated <= dateadd(hour, -1, getdate())  and checking is null and s.created is null
  order by call1approved desc  
'
, 'Не перешел на КД БИ!!'
, @show_new = 1
,@to = 'p.ilin@smarthorizon.ru; a.taov@smarthorizon.ru'
 	 



 
exec
sp_send_defect ' 


select top 20 a.declined created, a.number, a.fio, a.phone, a.declinereason, a.producttype, r.card_number from v_request a
left join stg._lk.requests r on a.number=r.num_1c
where a.declinereason = ''Автоматический отказ (Финцерт- карта)''
and isnull(a.source, '''') not in (''qr'', ''referal-mk'')
 order by 1 desc

'
, 'Финцерт- карта'
, 'rgkc@carmoney.ru'



 
--exec
--sp_send_defect ' 
--select top 10 created, number, [yandexMetricaLogLink],  origin,    _cardLinkedPTS, checking, call2, call2Approved, clientVerification, clientApproved, _carPhotoPTS,carVerificarion 
--from  request
--where productType=''pts'' and _cardLinkedPTS is not null and checking is null
--and created>=getdate()-1
--order by 1 desc

--'
--, 'Не встали на КД'


if datepart(minute, getdate())<9  

exec
sp_send_defect ' select TOP 20 a.[created] , isnull( b.source  , a.source) source , a.[STATUS] ,a.[eventName] ,a.[lead_id] ,a.[phone] ,a.[isApi2]  ,   a.[sendingStatus]  
FROM Analytics.dbo.[v_postback] a
left join v_lead2 b on a.lead_id=b.id
where a.sendingStatus<>''sent'' and a.created>= cast(getdate() as date)
and a.isApi2=0
 order by 1 desc

'
, 'Неотправленные постбэки'
, 'a.vdovin@carmoney.ru; i.bykina@carmoney.ru'

--exec
--sp_send_defect ' 

--select top 20 created, id, source, phone from v_lead2 where source like ''%psb%''
--and created>=getdate()-1
--order by 1 desc

--'
--, 'Поступил новый лид от ПСБ'
--, 'p.ilin@smarthorizon.ru; a.taov@smarthorizon.ru; k.peretyatko@carmoney.ru'


exec
sp_send_defect ' 

select top 20 created, productType, status_crm2, phone, [yandexMetricaLogLink] from request where source like ''%psb%''
and created>=getdate()-1 
and productType<>''BIG INST''
order by 1 desc

'
, 'Поступил новый черновик от ПСБ'
, 'a.taov@smarthorizon.ru'


exec
sp_send_defect ' 
select top 20 coalesce(issued, approved, carverificarion, clientverification , call2, checking, call1approved, call1, created ) created, productType, status_crm2, phone, [yandexMetricaLogLink] from request
where source like ''ecredit'' 
order by 1 desc

'
, 'Поступила заявка ECREDIT'
, 'k.peretyatko@carmoney.ru; v.semenov@carmoney.ru'


exec
sp_send_defect ' 
select  cast( format(getdate(), ''yyyy-MM-dd HH:00:00'')  as datetime) created ,max(call1) call1 from v_request
having max(call1) < cast(getdate() as date)
'
, 'Нет заявок Call1 в витрине с заявками'
, 'p.ilin@smarthorizon.ru'






exec
sp_send_defect ' 

select top 20 coalesce(issued, approved, carverificarion, clientverification , call2, checking, call1approved, call1, created ) created, productType, status_crm2, phone, [yandexMetricaLogLink] from request where source like ''%psb%''
and created>=''2025-10-08 15:30:00''
and productType=''BIG INST''
and checking is not null
and isdubl<>-1
order by 1 desc

'
, 'Поступила заявка BIG INSTALLMENT от ПСБ'
, 'a.taov@smarthorizon.ru'



--exec
--sp_send_defect ' 

--select top 20 created, productType, status_crm2, phone, [yandexMetricaLogLink] from request where source like ''%psb%''
--and created>=''2025-10-08 15:30:00''
--and productType=''BIG INST''
--and isdubl<>-1
--order by 1 desc

--'
--, 'Поступила заявка BIG INSTALLMENT от ПСБ'
--, 'a.taov@smarthorizon.ru; p.ilin@smarthorizon.ru'




exec
sp_send_defect ' 

select top 10000 coalesce(issued, approved, carverificarion, clientverification , call2, checking, call1approved, call1, created ) created, created requestCreated,  productType, number , status_crm2 СтатусЗаявки, phone, [yandexMetricaLogLink] from request where source = ''tpokupki-deepapi''
and created>=''2025-10-21 13:00:00''
 
and isdubl<>-1
order by 1 desc

'
, 'Поступила заявка tpokupki-deepapi'
, 'v.martemyanova@carmoney.ru;  e.mashkova@carmoney.ru; l.mentgomeri@carmoney.ru'
, 1





exec
sp_send_defect ' 
select top 10000 coalesce(issued, approved, carverificarion, clientverification , call2, checking, call1approved, call1, created ) created, created requestCreated,  productType, number, source , status_crm2 СтатусЗаявки, phone, [yandexMetricaLogLink] 
from request
where source <> ''psb-deepapi''
and productType=''BIG INST''
and created>=''2025-12-02 00:00:00''
and isdubl >= 0 
 
order by 1 desc

'
, 'Поступила заявка BI'
, 'v.martemyanova@carmoney.ru, e.mashkova@carmoney.ru, e.sheremeteva@smarthorizon.ru, d.anisimova@carmoney.ru'
, 1



--delete from _defect where defect = 'Поступила заявка tpokupki-deepapi'

--exec
--sp_send_defect ' 

--select top 20 created, phone, name from v_lead2 a
--join v_request_external  b 
--order by 1 desc 

--'
--, 'Поступил лид BIG INSTALLMENT от ПСБ'

while exists (
select top 1 * from jobs_running where job like '%calculateonlinedash%' )
waitfor delay '0:00:10'   
--select top 1 * from jobs  where Job_Name like '%calculateonlinedash%'



 
exec
sp_send_defect

--print 
' 

select top 100 
a.created
--, a.id
--, c.request_id
,json_value( d.payload, ''$[0].requestId'')  requestId
,json_value( d.payload, ''$[0].appId'') appId
, a.phone
, c.[lastName] Фамилия
, a.[status]
 , b.number [НомерЗаявки]
, b.productType 
, b.status_crm2 + case when b.cancelled is not null then '' (Аннулировано)'' else '''' end СтатусЗаявки 
, pr.cnt [Кол-во предложений]
--, b.limitChoise
from 
v_lead2 a with(nolock)
join v_request_external c with(nolock) on c.id=a.id and c.isBigInstallment=1
left join request b with(nolock) on b.leadId=a.id
left join stg._lf.v1_core_external_request_partner_params_to_return_permanent d with(nolock) on d.externalRequestId=c.request_id
left join (select link, count(*) cnt from v_request_loginom_sum2 group by link ) pr on pr.link=b.link
where a.source = ''psb-deepapi''
and isnull(a.channel, '''''''')<>''Тест''
--and a.created>=getdate()-1 
and a.created>=getdate()-8
 order by 1 desc



--select top 100 
--a.created
----, a.id
----, c.request_id
--,json_value( d.payload, ''$[0].requestId'')  requestId
--,json_value( d.payload, ''$[0].appId'') appId
--, a.phone
--, a.[status]
-- , b.number [НомерЗаявки]
--, b.productType 
--, b.status_crm2 + case when b.cancelled is not null then '' (Аннулировано)'' else '''' end СтатусЗаявки 
--, pr.cnt [Кол-во предложений]
----, b.limitChoise
--from 
--v_lead2 a with(nolock)
--join v_request_external c with(nolock) on c.id=a.id and c.isBigInstallment=1
--left join request b with(nolock) on b.leadId=a.id
--left join stg._lf.v1_core_external_request_partner_params_to_return_permanent d on d.externalRequestId=c.request_id
--left join (select link, count(*) cnt from v_request_loginom_sum2 group by link ) pr on pr.link=b.link
--where a.source like ''%psb%''
--and isnull(a.channel, '''''''')<>''Тест''
----and a.created>=getdate()-1 
--and a.created>=''2025-10-08 15:30:00''
-- order by 1 desc

'
, 'Поступил лид BIG INSTALLMENT от ПСБ'
, 'a.taov@smarthorizon.ru'



 
 



--select top 100  * from _defect
--order by 2 desc

--delete from _defect where defect = 'Поступил лид BIG INSTALLMENT от ПСБ'

--delete from _defect where defect = 'Поступил лид BIG INSTALLMENT от ПСБ'

if datepart(minute, getdate())<9  

exec
sp_send_defect ' select TOP 20 a.[created] ,  isnull( b.source  , a.source) source , a.[STATUS] ,a.[eventName] ,a.[lead_id] ,a.[phone] ,a.[isApi2]  ,   a.[sendingStatus]  
FROM Analytics.dbo.[v_postback] a
left join v_lead2 b on a.lead_id=b.id
where a.sendingStatus<>''sent'' and a.created>= cast(getdate() as date)
and a.isApi2=1
 order by 1 desc

'
, 'Неотправленные колбэки'
, 'a.vdovin@carmoney.ru; i.bykina@carmoney.ru'


if datepart(minute, getdate())<9  

exec
sp_send_defect ' 


select top 20 created, productType, channel, number, origin, status from v_fa where isnull(source, '''') =''''
and created<= dateadd(hour, -5, getdate()) 
and created >= getdate()-6
order by 1 desc

'
, 'Пустой источник по заявкам' 


if datepart(minute, getdate())<9  

exec
sp_send_defect ' 
select top 20 a.id, a.source, a.channel, a.created, b.channel channelFromSource, a.status from v_lead2 a
left join v_source b on a.source=b.source 
where (a.channel is null or a.channel<>b.channel ) and isnull( a.channel, '''') <>''Тест'' and a.status <> ''RECEIVED''
order by a.created desc
'
, 'Пустой источник по лидам' 




 



--select top 20 created, * from v_fa where isnull(source, '') =''
--order by 1 desc

--if datepart(minute, getdate())<9  

--exec
--sp_send_defect '
--select TOP 20 id, created, source, channel, ''
--'' col1 from _lead_request where source like ''%infos%''
--and  channel  not like ''%CPA%'' 
--and  channel  <>''Тест''
--and created>=getdate()-1
-- order by 2 desc

--'
--, 'Некорректный канал инфосети'

if datepart(minute, getdate())<9  

exec
sp_send_defect '
select top 20 a.id, a.created , b1.Created linkCreated, datediff(second, a.created , b1.Created ) slaSecond, a.source  from v_lead2   a
 join  v_Postback b1 on a.id=b1.lead_id and b1.isApi2=1
 where a.created>=cast(getdate()  as date) and datediff(second, a.created , b1.Created )> 60 

 order by 2 desc
'
, 'SLA link > 1 min'


if datepart(minute, getdate())<9  

exec
sp_send_defect '
select top 20 cast( format(getdate(), ''yyyy-MM-dd HH:00:00'') as datetime2(0)) created , a.source
, avg( case when cast(a.created as date)=cast(getdate()  as date) then datediff(second, a.created , b1.Created ) end )  slaSecondAvgToday
, avg( case when cast(a.created as date)=cast(getdate()-1  as date) then datediff(second, a.created , b1.Created ) end )  slaSecondAvgYesterday
, count( case when cast(a.created as date)=cast(getdate()-1  as date) then 1 end) cntYesterday
, count( case when cast(a.created as date)=cast(getdate()  as date) then 1 end) cntToday

from v_lead2   a
 join  v_Postback b1 on a.id=b1.lead_id and b1.isApi2=1
 where a.created>=cast(getdate()-1  as date) 
 group by a.source
 having  avg( case when cast(a.created as date)=cast(getdate()  as date) then datediff(second, a.created , b1.Created ) end )>=30

 order by 2 desc
'
, 'SLA link AVG > 30 seconds'

 

if datepart(hour, getdate())>10 
exec
sp_send_defect '

select cast(getdate() as date) created,  count(a.created) ВсегоЛидов ,  count(al.active) СПереходом, 100* count(al.active) /(count(a.created) +0.0) ПроцентПереходов from v_request_external  a
left join  stg._lk.auth_link  al on  ''https://login.carmoney.ru/client/v1/user/auth/''+al.hash+''/0'' = a.link_url and al.active=1
where cast(a.created as date)=cast(getdate()   as date) 
having 100* count(al.active) /(count(a.created) +0.0) <5 and  count(a.created) >100
'
, 'Конверсия в переход UNI_API < 5%'



 
END TRY
BEGIN CATCH
    DECLARE 
        @errorMessage NVARCHAR(4000),
        @errorSeverity INT,
        @errorState INT,
        @errorLine INT;

    -- Получаем данные об ошибке
    SELECT 
        @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE(),
        @errorLine = ERROR_LINE();

	set	@errorMessage =   CONCAT('Ошибка _defect_catcher на строке: ', @errorLine, ' — ', @errorMessage)

  ;


    -- Повторно выбрасываем ошибку с уточнением строки
    THROW 50000, @errorMessage, 1;
END CATCH;


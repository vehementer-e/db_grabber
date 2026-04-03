CREATE   proc [dbo].[sale_report_biginst_calling] 
as

--sp_create_job 'Analytics._sale_report_biginst_calling at 8 each hour', 'sale_report_biginst_calling', '1', '80000', '60'
-- EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._sale_report_biginst_calling at 8 each hour'
drop table if exists ##t1736723


SELECT  top 10000
    d.appId AS [AppId (от ПСБ)],
    a.number AS [Номер заявки],
    a.status AS [Статус заявки],
    c.created AS [Дата и время поступления лида],
    e.updated AS [Дата и время Коллбека в Банк],
    CASE 
        WHEN DATEDIFF(second, c.created, e.updated) <= 180 THEN 1 
        WHEN DATEDIFF(second, c.created, e.updated) > 180 THEN 0 
       
    END AS [Флаг (уложились в 3мин или нет до ответа в Банк)],
    FORMAT(DATEADD(second, DATEDIFF(second, c.created, e.updated), '0:00:00'), 'HH:mm:ss') AS [Время ответа от прихода лида до колбека в Банк],
    a.fio AS [ФИО клиента (полное)],
    a.phone AS [Номер телефона],
    c.partnerApplicationChannel AS [Канал (как приходит Web\Office\Mobile app)]
INTO ##t1736723
FROM    v_request a   
left join v_request_external c on c.id = a.marketing_lead_id
left join 

(select d.externalRequestId  
, max(json_value( d.payload, '$[0].appId')  ) appId
from stg._lf.v1_core_external_request_partner_params_to_return_permanent d 
group by d.externalRequestId ) d on d.externalRequestId=c.request_id

left join (
SELECT   JSON_VALUE(inc.value, '$.attributes.applicationNumber') number, min(updated) updated    
 FROM v_callback v
CROSS APPLY OPENJSON(v.payload, '$.included') AS inc
WHERE eventId = 'lf.event.8108.1.1'
  AND JSON_VALUE(inc.value, '$.type') = 'requestDatas'
  and isjson (inc.value) = 1
  and isjson (v.payload) = 1
  
  group by JSON_VALUE(inc.value, '$.attributes.applicationNumber')

  ) e on e.number= a.number
   where a.productSubType = 'Big Installment' 
   order by a.created desc



   
exec python 'sql_to_gmail("select * from ##t1736723 order by case when  [Дата и время поступления лида] is null then 1 end desc, [Дата и время поступления лида] desc", name = "отчет для продаж по БИ ПСБ", add_to="a.taov@smarthorizon.ru ; bezzalog-sale@carmoney.ru")' , 1


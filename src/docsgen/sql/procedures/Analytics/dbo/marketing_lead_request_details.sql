
CREATE     proc [dbo].[marketing_lead_request_details] 
@q  VARCHAR(MAX) 
as
 
 --DECLARE @q VARCHAR(MAX) = 'caranga - 20260101';

-- Переменные для хранения результата парсинга
DECLARE @sources VARCHAR(MAX);
DECLARE @date DATE;

-- Парсинг строки: извлечение списка источников и даты
SET @sources = LEFT(@q, CHARINDEX(' - ', @q) - 1); -- Убираем пробел перед ' - '
SET @date = CAST(RIGHT(@q, 8) AS DATE);



drop table if exists #s

SELECT trim(value) source into #s FROM STRING_SPLIT(@sources, ',')
-- Динамическое создание запроса
 
-- Вывод результата вместе с итоговым SQL

drop table if exists #l
SELECT a.id,  a.phone, a.status , a.source, a.partner_id, a.stat_term  into #l
FROM v_lead2 a with(nolock)
  JOIN #s s on s.source=a.source

WHERE   a.created between   @date and dateadd(month, 1, @date)   ;




-- Вывод результата вместе с итоговым SQL
SELECT a.id, b.number, a.source,a.partner_id partnerId,   a.phone, a.status, b.status_crm requestStatus, b.isPts, b.issued, b.issuedSum 
,a.stat_term   statTerm
,case when a.source like '%' + 'finuslugi' + '%'   then case when  b.declineStage not like  'Call' + '%' then 'Manual'
 else b.declineStage    end
end  addInfo
FROM #l a with(nolock)
LEFT JOIN request b with(nolock) ON a.id = b.leadId and b.call1 is not null
--left join v_lead v_lead  on v_lead.id=a.id

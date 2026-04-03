CREATE proc [dbo].[marketing_yandex_conversion] @mode nvarchar(max) = 'loan'
as


--alter table _request add yaConvCall1 datetime2(0)
--alter table _request_log add yaConvCall1 datetime2(0)

--alter table _request add yaConvIssued datetime2(0)
--alter table _request_log add yaConvIssued datetime2(0)


 if @mode='on_start'
 begin

 
update _request set _request.yaConvCall1 = call1 where yaConvCall1 is null and call1 is not null
update _request set _request.yaConvIssued = issued where yaConvIssued is null and issued is not null

 end

 if @mode='loan'
select --TOP 100
  re.yaConvCall1 create_date_time
,  lower( ANALYTICS.dbo.to_md5(lower(электроннаяпочта), 1) ) emails_md5
,  lower( ANALYTICS.dbo.to_md5('7'+телефон, 1)  ) phones_md5
, lower(re.guid ) id	 
, lower( re.leadId) client_uniq_id

--, case when [ссылка клиент]<>0 then lower( ANALYTICS.dbo.to_md5(ANALYTICS.dbo.getGUIDFrom1C_IDRREF([ссылка клиент]), 1)) end client_uniq_id
, cast([Выданная сумма] as bigint)  revenue
, v.client_yandex_id client_ids	
, case when re.yaConvIssued is not null and cast(re.issuedSum as bigint)  is not null then 'PAID' else 'IN_PROGRESS' end order_status

from dm_Factor_Analysis a
left join v_request_lf2 b on a.Номер=b.number
left join v_visit v  on v.id=b.visitId
join _request re on re.number=a.Номер and yaConvCall1 >= '20250301' and a.[Выданная сумма]>0 and re.phone <>'' and yaConvIssued  is not null
 ORDER BY 1 

 
 if @mode='request'
select --TOP 100
  re.yaConvCall1 create_date_time
,  lower( ANALYTICS.dbo.to_md5(lower(электроннаяпочта), 1) ) emails_md5
,  lower( ANALYTICS.dbo.to_md5('7'+телефон, 1)  ) phones_md5
, lower(re.guid ) id	 
, lower( re.leadId) client_uniq_id
--, case when [ссылка клиент]<>0 then lower( ANALYTICS.dbo.to_md5(ANALYTICS.dbo.getGUIDFrom1C_IDRREF([ссылка клиент]), 1)) end client_uniq_id
--, cast([Выданная сумма] as bigint)  revenue
, v.client_yandex_id client_ids	
, 'IN_PROGRESS'   order_status

from dm_Factor_Analysis a
left join v_request_lf2 b on a.Номер=b.number
left join v_visit v  on v.id=b.visitId
join _request re on re.number=a.Номер and yaConvCall1 >= '20250301'-- and a.[Выданная сумма]>0
and re.phone <>''-- and yaConvIssued  is not null
and re.producttype='PTS'
 ORDER BY 1 





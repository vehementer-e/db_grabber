CREATE proc [_birs].[Модуль банк клиенты]
as
begin


SELECT  id
	,uf_name
	into #t2
FROM stg._lcrm.lcrm_leads_full
WHERE uf_registered_at >= '20230601'
	AND uf_stat_campaign = '5469'
	AND uf_type = 'site3_installment_lk'

SELECT b.id
 
	,a.UF_PHONE
	,b.uf_name
	,a.UF_LOGINOM_STATUS
	,a.UF_LOGINOM_DECLINE
	,a.uf_registered_at
		,a.[ВРемяПервойПопытки]
	,a.[ВРемяПервогоДозвона]
	,a.[ЧислоПопыток]
	,a.attempt_result

	,статуслидафедор
	,причинанепрофильности
	,isinstallment
	into #t3
FROM #t2 b
LEFT JOIN feodor.dbo.dm_leads_history a ON a.id = b.id


select * from #t3

--order by id


end
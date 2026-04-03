create procedure risk.etl_repbi_quality_report_300725
as
BEGIN

BEGIN TRY
------------------------------------------Отчет для Quality------------------------------------------
DROP TABLE IF EXISTS #ClientIncomeAdditional_SRC;
SELECT 
number
,ClientIncomeAdditional
INTO #ClientIncomeAdditional_SRC
FROM [Stg].[_fedor].[core_ClientRequest]
WHERE ClientIncomeAdditional > 0 
AND CreatedOn >= dateadd(day, - day(getdate()) + 1, cast(getdate() AS DATE))
;
------------------------------------------Чекеры инстолмент
DROP TABLE IF EXISTS #repbi_quality_report_checkers_inst;
SELECT 
[Дата заведения заявки]
,[Время заведения]
,Branch_name as [Офис заведения заявки]
,f.[Номер заявки]
,[ФИО клиента]
,min(cast([Дата статуса] AS DATETIME)) OVER (PARTITION BY f.[Номер заявки]) as [Дата статуса]
,[ФИО сотрудника верификации/чекер] as [Назначенный чекер]
,sum([ВремяЗатрачено]) OVER (PARTITION BY f.[Номер заявки]) * 24 * 60 as [Затраченное время (мин сек)]
,CASE 
	WHEN a2.decision = 'Accept' THEN 'Одобрено' 
	WHEN a2.decision = 'Decline' THEN 'Отказано' 
	ELSE 'Аннулировано' 
	END [Решение на этапе]
,dem_fl
,dem_time
,dor_fl
,dor_time
,CASE 
	WHEN a2.decision = 'Accept' THEN 'Одобрено' 
	WHEN a2.decision = 'Decline' THEN 'Отказано' 
	ELSE 'Аннулировано' 
	END [Решение по клиенту]
,[Последний статус заявки] as [Статус по заявке]
,CASE 
	WHEN [UW_Result_14] = '100.0814.002' THEN 'НЕДОЗВОН' 
	WHEN [UW_Result_14] = '100.0814.014' THEN 'Отвечает 3-е лицо' 
	WHEN [UW_Result_14] = '100.0814.009' THEN 'Клиент дает противоречивую инф-ю' 
	WHEN [UW_Result_14] = '100.0814.015' THEN 'Клиент обратился за кредитом под влиянием 3х лиц' 
	WHEN [UW_Result_14] = '100.0814.001' THEN 'Клиент идентифицирован, моб тел принадлежит клиенту' 
	WHEN [UW_Result_14] = '100.0814.012' THEN 'НЕДОЗВОН (чат-2-деск ОК)' 
	WHEN [UW_Result_14] = '100.0814.003' THEN 'Клиенту не удобно разговаривать, просит перезвонить' 
	WHEN [UW_Result_14] = '100.0814.004' THEN 'Отказ клиента' 
	WHEN [UW_Result_14] = '100.0814.005' THEN 'Мобильный телефон клиента принадлежит 3-му лицу (близкому родственнику)' 
	WHEN [UW_Result_14] = '100.0814.006' THEN 'Идентификация не пройдена (не может назвать свое ФИО, дату рождения)' 
	WHEN [UW_Result_14] = '100.0814.007' THEN 'Отказ клиента, клиент не оформлял займ' 
	WHEN [UW_Result_14] = '100.0814.008' THEN 'Кредит для 3-х лиц' 
	WHEN [UW_Result_14] = '100.0814.010' THEN 'Клиент "Олень" (приведен 3-ми лицами)' 
	WHEN [UW_Result_14] = '100.0814.011' THEN 'Мобильный телефон клиента принадлежит 3-му лицу. Подозрение в мошенничестве' 
	WHEN [UW_Result_14] = '100.0814.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_14] = '100.0814.013' THEN 'Клиент пьян' 
	WHEN [UW_Result_14] IS NULL THEN 'Не назначалась проверка' 
	ELSE 'Другое' 
	END [Контактность клиента]
,CASE 
	WHEN [UW_Result_9] = '100.0809.003' THEN 'НЕДОЗВОН' 
	WHEN [UW_Result_9] IN ('100.0809.001', '100.0809.002', '100.0809.008', '100.0809.010') THEN 'Дозвон' 
	WHEN [UW_Result_9] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_9] = '100.0809.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_9] IN ('100.0809.004', '100.0809.005', '100.0809.006', '100.0809.007', '100.0809.009') THEN 'Не найден/не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Контур Фокуса]
,CASE 
	WHEN [UW_Result_11] = '100.0811.004' THEN 'НЕДОЗВОН' 
	WHEN [UW_Result_11] IN ('100.0811.001', '100.0811.002', '100.0811.003', '100.0811.009', '100.0811.010') THEN 'Дозвон' 
	WHEN [UW_Result_11] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_11] = '100.0811.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_11] IN ('100.0811.005', '100.0811.006', '100.0811.007', '100.0811.011', '100.0811.008') THEN 'Не найден/не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Интернет]
,CASE 
	WHEN [UW_Result_12] = '100.0812.004' THEN 'НЕДОЗВОН' 
	WHEN [UW_Result_12] IN ('100.0812.001', '100.0812.002', '100.0812.003', '100.0812.009', '100.0812.010') THEN 'Дозвон' 
	WHEN [UW_Result_12] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_12] = '100.0812.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_12] IN ('100.0812.005', '100.0812.011', '100.0812.006', '100.0812.007', '100.0812.008') THEN 'Не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Анкеты]				
,CASE 
	WHEN [UW_Result_3] = '100.0819.001' THEN 'Найден аккаунт: клиент идентифицирован по фото, нет негатива' 
	WHEN [UW_Result_3] = '100.0819.002' THEN 'Найден аккаунт: клиент идентифицирован без фото, нет негатива' 
	WHEN [UW_Result_3] = '100.0819.003' THEN 'Найден аккаунт: клиент идентифицирован, выявлен негатив'
	WHEN [UW_Result_3] = '100.0819.004' THEN 'Найдено несколько аккаунтов, клиент не идентифицирован'
	WHEN [UW_Result_3] = '100.0819.005' THEN 'Аккаунт не найден'
	WHEN [UW_Result_3] = '100.0819.006' THEN 'Проверка не проводилась'
	WHEN [UW_Result_3] = '100.0819.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_3_old] IN ('100.0803.001', '100.0803.002', '100.0803.003') THEN 'Найден аккаунт' 
	WHEN [UW_Result_3_old] = '100.0803.004' THEN 'Аккаунт не найден' 
	WHEN [UW_Result_3_old] = '100.0803.999' THEN 'Проверка не проводилась (системная)' 
	WHEN coalesce([UW_Result_3],[UW_Result_3_old]) IS NULL THEN 'Не назначалась проверка' 
	ELSE 'Другое' 
	END [СОЦ СЕТИ]
,CASE 
	WHEN ClientIncomeAdditional IS NOT NULL THEN 'Есть' 
	ELSE 'Нет' 
	END [Доп.доход (есть/нет)]
,CASE 
	WHEN [UW_Result_16] IN ('100.0816.001', '100.0816.002', '100.0816.003', '100.0816.004', '100.0816.005') THEN 'Требуется' 
	WHEN [UW_Result_16] = '100.0816.006' THEN 'Не требуется' 
	WHEN [UW_Result_16] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_16] = '100.0816.999' THEN 'Проверка не проводилась (системная)' 
	ELSE 'Другое' 
	END [Проверка Антифрод]
,CASE 
	WHEN [UW_Result_15] = '100.0815.001' THEN 'Негатив отсутствует' 
	WHEN [UW_Result_15] = '100.0815.002' THEN 'Инвалидность' 
	WHEN [UW_Result_15] = '100.0815.008' THEN 'Типаж БОМЖ, ЦЫГАНЕ' 
	WHEN [UW_Result_15] = '100.0815.009' THEN 'Подозрение в мошенничестве: геолокация' 
	WHEN [UW_Result_15] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_15] = '100.0815.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_15] IN ('100.0815.003', '100.0815.004') THEN 'Негатив по соц.сетям' 
	WHEN [UW_Result_15] IN ('100.0815.005', '100.0815.007', '100.0815.006', '100.0815.009', '100.0815.010', '100.0815.011') THEN 'Прочее' 
	ELSE 'Другое' 
	END [НЕГАТИВЫ]		
,case 
	when Result_1_206 = '100.0806.001' then 'Подтверждена принадлежность телефона клиенту'
	when Result_1_206 = '100.0806.002' then 'Данные о телефоне клиента отсутствуют'
	when Result_1_206 = '100.0806.003' then 'Телефон клиента зарегистрирован на иное лицо'
	when Result_1_206 = '100.0806.999' then 'Проверка не проводилась (системная)'
	when Result_1_206 is null then 'Не назначалась проверка' 
	else 'Другое' end [Проверка телефонов по базам - телефон клиента] --Проверка телефонов по базам - телефон клиента
	
INTO #repbi_quality_report_checkers_inst
FROM [reports].[dbo].dm_FedorVerificationRequests_without_coll AS f
LEFT JOIN (
	SELECT number ,Branch_name
	FROM [stg].[_loginom].[Originationlog]
	WHERE stage = 'Call 1'
	) a ON f.[Номер заявки] = a.Number
LEFT JOIN (
	SELECT number ,decision
	FROM [stg].[_loginom].[Originationlog]
	WHERE stage = 'Call 1.5'
	) a2 ON f.[Номер заявки] = a2.Number
LEFT JOIN (
	SELECT [Номер заявки],dem_fl = 1,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dem_time
	FROM [reports].[dbo].dm_FedorVerificationRequests_without_coll
	WHERE ProductType_Code = 'installment'
	AND Статус = 'Контроль данных' AND Задача = 'task:Отложена'
	) fv ON f.[Номер заявки] = fv.[Номер заявки]
LEFT JOIN (
	SELECT [Номер заявки],dor_fl = 1,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dor_time
	FROM [reports].[dbo].dm_FedorVerificationRequests_without_coll
	WHERE ProductType_Code = 'installment'
	AND Статус = 'Контроль данных' AND Задача = 'task:Требуется доработка'
	) fd ON f.[Номер заявки] = fd.[Номер заявки]
LEFT JOIN (
	SELECT 
	number
	,isnull(Result_1_203, Result_2_103) as [UW_Result_3_old] --СОЦ СЕТИ старые правила
	,Result_1_219 AS [UW_Result_3] --СОЦ СЕТИ
	,isnull(Result_1_209, Result_2_109) AS [UW_Result_9]
	,isnull(Result_1_207, Result_2_107) AS [UW_Result_7]
	,isnull(Result_1_216, Result_2_116) AS [UW_Result_16]
	,isnull(Result_1_215, Result_2_115) AS [UW_Result_15]
	,isnull(Result_1_214, Result_2_114) AS [UW_Result_14]
	,isnull(Result_1_213, Result_2_113) AS [UW_Result_13]
	,isnull(Result_1_211, Result_2_111) AS [UW_Result_11]
	,isnull(Result_1_212, Result_2_112) AS [UW_Result_12]
	,Result_1_206 --Проверка телефонов по базам - телефон клиента
	FROM [stg].[_loginom].[callcheckverif_log]
	WHERE stage = 'Call 1.5'
	) cc ON f.[Номер заявки] = cc.Number
LEFT JOIN #ClientIncomeAdditional_SRC cf 
	ON f.[Номер заявки] = cf.Number collate Cyrillic_General_CI_AS
WHERE f.ProductType_Code = 'installment'
AND Статус = 'Контроль данных' AND Задача = 'task:В работе' 
AND [Дата статуса] > dateadd(day, - day(getdate()) + 1, cast(getdate() AS DATE))
;
------------------------------------------Чекеры PDL
DROP TABLE IF EXISTS #repbi_quality_report_checkers_pdl;
WITH a
AS (
SELECT 
[Дата заведения заявки]
,[Время заведения]
,Branch_name [Офис заведения заявки]
,f.[Номер заявки]
,[ФИО клиента]
,min(cast([Дата статуса] AS DATETIME)) OVER (PARTITION BY f.[Номер заявки]) as [Дата статуса]
,[ФИО сотрудника верификации/чекер] as [Назначенный чекер]
,sum([ВремяЗатрачено]) OVER (PARTITION BY f.[Номер заявки]) * 24 * 60 as [Затраченное время (мин сек)]
,CASE 
	WHEN a2.decision = 'Accept' THEN 'Одобрено' 
	WHEN a2.decision = 'Decline' THEN 'Отказано' 
	ELSE 'Аннулировано' 
	END [Решение на этапе]
,CASE 
	WHEN a2.decision = 'Accept' THEN 'Одобрено' 
	WHEN a2.decision = 'Decline' THEN 'Отказано' 
	ELSE 'Аннулировано'
	END [Решение по клиенту]
,dem_fl
,dem_time
,dor_fl
,dor_time
,[Последний статус заявки] as [Статус по заявке]
,CASE 
	WHEN [Result_2_114] = '100.0814.002' THEN 'НЕДОЗВОН'
	WHEN [Result_2_114] = '100.0814.014' THEN 'Отвечает 3-е лицо' 
	WHEN [Result_2_114] = '100.0814.009' THEN 'Клиент дает противоречивую инф-ю' 
	WHEN [Result_2_114] = '100.0814.015' THEN 'Клиент обратился за кредитом под влиянием 3х лиц' 
	WHEN [Result_2_114] = '100.0814.001' THEN 'Клиент идентифицирован, моб тел принадлежит клиенту' 
	WHEN [Result_2_114] = '100.0814.012' THEN 'НЕДОЗВОН (чат-2-деск ОК)' 
	WHEN [Result_2_114] = '100.0814.003' THEN 'Клиенту не удобно разговаривать, просит перезвонить' 
	WHEN [Result_2_114] = '100.0814.004' THEN 'Отказ клиента' 
	WHEN [Result_2_114] = '100.0814.005' THEN 'Мобильный телефон клиента принадлежит 3-му лицу (близкому родственнику)' 
	WHEN [Result_2_114] = '100.0814.006' THEN 'Идентификация не пройдена (не может назвать свое ФИО, дату рождения)' 
	WHEN [Result_2_114] = '100.0814.007' THEN 'Отказ клиента, клиент не оформлял займ' 
	WHEN [Result_2_114] = '100.0814.008' THEN 'Кредит для 3-х лиц' 
	WHEN [Result_2_114] = '100.0814.010' THEN 'Клиент "Олень" (приведен 3-ми лицами)' 
	WHEN [Result_2_114] = '100.0814.011' THEN 'Мобильный телефон клиента принадлежит 3-му лицу. Подозрение в мошенничестве' 
	WHEN [Result_2_114] = '100.0814.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [Result_2_114] = '100.0814.013' THEN 'Клиент пьян' 
	WHEN [Result_2_114] IS NULL THEN 'Не назначалась проверка' 
	ELSE 'Другое' 
	END [Контактность клиента]
,CASE 
	WHEN [Result_2_109] = '100.0809.003' THEN 'НЕДОЗВОН' 
	WHEN [Result_2_109] IN ('100.0809.001', '100.0809.002', '100.0809.008', '100.0809.010') THEN 'Дозвон' 
	WHEN [Result_2_109] IS NULL THEN 'Не назначалась проверка' 
	WHEN [Result_2_109] = '100.0809.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [Result_2_109] IN ('100.0809.004', '100.0809.005', '100.0809.006', '100.0809.007', '100.0809.009') THEN 'Не найден/не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Контур Фокуса]
,CASE 
	WHEN [Result_2_111] = '100.0811.004' THEN 'НЕДОЗВОН' 
	WHEN [Result_2_111] IN ('100.0811.001', '100.0811.002', '100.0811.003', '100.0811.009', '100.0811.010') THEN 'Дозвон' 
	WHEN [Result_2_111] IS NULL THEN 'Не назначалась проверка' 
	WHEN [Result_2_111] = '100.0811.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [Result_2_111] IN ('100.0811.005', '100.0811.006', '100.0811.007', '100.0811.011', '100.0811.008') THEN 'Не найден/не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Интернет]
,CASE 
	WHEN [Result_2_112] = '100.0812.004' THEN 'НЕДОЗВОН' 
	WHEN [Result_2_112] IN ('100.0812.001', '100.0812.002', '100.0812.003', '100.0812.009', '100.0812.010') THEN 'Дозвон' 
	WHEN [Result_2_112] IS NULL THEN 'Не назначалась проверка' 
	WHEN [Result_2_112] = '100.0812.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [Result_2_112] IN ('100.0812.005', '100.0812.011', '100.0812.006', '100.0812.007', '100.0812.008') THEN 'Не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Анкеты]
,CASE 
	WHEN [Result_2_116] IN ('100.0816.001', '100.0816.002', '100.0816.003', '100.0816.004', '100.0816.005') THEN 'Требуется' 
	WHEN [Result_2_116] = '100.0816.006' THEN 'Не требуется' 
	WHEN [Result_2_116] IS NULL THEN 'Не назначалась проверка' 
	WHEN [Result_2_116] = '100.0816.999' THEN 'Проверка не проводилась (системная)' 
	ELSE 'Другое' 
	END [Проверка Антифрод]
,CASE 
	WHEN [Result_2_115] = '100.0815.001' THEN 'Негатив отсутствует' 
	WHEN [Result_2_115] = '100.0815.002' THEN 'Инвалидность' 
	WHEN [Result_2_115] = '100.0815.008' THEN 'Типаж БОМЖ, ЦЫГАНЕ' 
	WHEN [Result_2_115] = '100.0815.009' THEN 'Подозрение в мошенничестве: геолокация' 
	WHEN [Result_2_115] IS NULL THEN 'Не назначалась проверка' 
	WHEN [Result_2_115] = '100.0815.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [Result_2_115] IN ('100.0815.003', '100.0815.004') THEN 'Негатив по соц.сетям' 
	WHEN [Result_2_115] IN ('100.0815.005', '100.0815.007', '100.0815.006', '100.0815.009', '100.0815.010', '100.0815.011') THEN 'Прочее' 
	ELSE 'Другое' 
	END [НЕГАТИВЫ]
,CASE 
	WHEN result_1_219 = '100.0819.001' THEN 'Найден аккаунт: клиент идентифицирован по фото, нет негатива' 
	WHEN result_1_219 = '100.0819.002' THEN 'Найден аккаунт: клиент идентифицирован без фото, нет негатива' 
	WHEN result_1_219 = '100.0819.003' THEN 'Найден аккаунт: клиент идентифицирован, выявлен негатив'
	WHEN result_1_219 = '100.0819.004' THEN 'Найдено несколько аккаунтов, клиент не идентифицирован'
	WHEN result_1_219 = '100.0819.005' THEN 'Аккаунт не найден'
	WHEN result_1_219 = '100.0819.006' THEN 'Проверка не проводилась'
	WHEN result_1_219 = '100.0819.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_3_old] IN ('100.0803.001', '100.0803.002', '100.0803.003') THEN 'Найден аккаунт' 
	WHEN [UW_Result_3_old] = '100.0803.004' THEN 'Аккаунт не найден' 
	WHEN [UW_Result_3_old] = '100.0803.999' THEN 'Проверка не проводилась (системная)' 
	WHEN coalesce(result_1_219, [UW_Result_3_old]) IS NULL THEN 'Не назначалась проверка' 
	ELSE 'Другое' 
	END [СОЦ СЕТИ]
,case 
	when Result_1_206 = '100.0806.001' then 'Подтверждена принадлежность телефона клиенту'
	when Result_1_206 = '100.0806.002' then 'Данные о телефоне клиента отсутствуют'
	when Result_1_206 = '100.0806.003' then 'Телефон клиента зарегистрирован на иное лицо'
	when Result_1_206 = '100.0806.999' then 'Проверка не проводилась (системная)'
	when Result_1_206 is null then 'Не назначалась проверка'
	else 'Другое' 
	end [Проверка телефонов по базам - телефон клиента] --Проверка телефонов по базам - телефон клиента

FROM Reports.dbo.dm_FedorVerificationRequests_without_coll AS f WITH (NOLOCK)
LEFT JOIN (
	SELECT number ,Branch_name
	FROM [stg].[_loginom].[Originationlog] WITH (NOLOCK)
	WHERE stage = 'Call 1'
	) a ON f.[Номер заявки] = a.Number
LEFT JOIN (
	SELECT number ,decision
	FROM [stg].[_loginom].[Originationlog] WITH (NOLOCK)
	WHERE stage = 'Call 1.5'
	) a2 ON f.[Номер заявки] = a2.Number
LEFT JOIN (
	SELECT [Номер заявки] ,dem_fl = 1 ,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dem_time
	FROM Reports.dbo.dm_FedorVerificationRequests_without_coll WITH (NOLOCK)
	WHERE ProductType_Code = 'pdl'
	AND Статус = 'Контроль данных' 
	AND Задача = 'task:Отложена'
	) fv ON f.[Номер заявки] = fv.[Номер заявки]
LEFT JOIN (
	SELECT [Номер заявки] ,dor_fl = 1 ,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dor_time
	FROM Reports.dbo.dm_FedorVerificationRequests_without_coll WITH (NOLOCK)
	WHERE ProductType_Code = 'pdl'
	AND Статус = 'Контроль данных' 
	AND Задача = 'task:Требуется доработка'
	) fd ON f.[Номер заявки] = fd.[Номер заявки]
LEFT JOIN (
	SELECT 
	number
	,[UW_Result_14]
	,isnull(Result_1_203, Result_2_103) AS Result_2_103
	,isnull(Result_1_216, Result_2_116) AS [Result_2_116]
	,isnull(Result_1_215, Result_2_115) AS [Result_2_115]
	,isnull(Result_1_214, Result_2_114) AS [Result_2_114]
	,isnull(Result_1_213, Result_2_113) AS [Result_2_113]
	,isnull(Result_1_209, Result_2_109) AS [Result_2_109]
	,isnull(Result_1_211, Result_2_111) AS [Result_2_111]
	,isnull(Result_1_212, Result_2_112) AS [Result_2_112]
	,isnull(Result_1_207, Result_2_107) AS [Result_2_107]
	,result_1_219 --СОЦ СЕТИ
	,Result_1_206 --Проверка телефонов по базам - телефон клиента
	,isnull(Result_1_203, Result_2_103) as [UW_Result_3_old] --СОЦ СЕТИ старые правила
	FROM [stg].[_loginom].[callcheckverif_log]
	WHERE stage = 'Call 1.5'
	) c ON f.[Номер заявки] = c.Number
LEFT JOIN #ClientIncomeAdditional_SRC cf 
	ON f.[Номер заявки] = cf.Number collate Cyrillic_General_CI_AS
WHERE f.ProductType_Code = 'pdl'
AND Статус = 'Контроль данных' 
AND Задача = 'task:В работе' 
AND [Дата статуса] >= dateadd(day, - day(getdate()) + 1, cast(getdate() AS DATE))
)
SELECT 
DISTINCT [Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный чекер]
,[Затраченное время (мин сек)]
,[Решение на этапе]
,CASE WHEN dem_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Отложена'
,dem_time [Время в отложенных (мин сек)]
,CASE WHEN dor_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Доработка'
,dor_time [Время на доработке (мин сек)]
,[Решение по клиенту]
,[Статус по заявке]
,[Контактность клиента]
,[Контактность работодателя по телефонам из Контур Фокуса]
,[Контактность работодателя по телефонам из Интернет]
,[Контактность работодателя по телефонам из Анкеты]
,cast('Нет' AS VARCHAR(200)) AS [Доп доход (есть/нет)]
,[Проверка Антифрод]
,[НЕГАТИВЫ]
,[СОЦ СЕТИ]
,[Проверка телефонов по базам - телефон клиента]
INTO #repbi_quality_report_checkers_pdl
FROM a
ORDER BY [Номер заявки],[Дата статуса]
;
------------------------------------------чекеры ПТС
DROP TABLE IF EXISTS #repbi_quality_report_checkers_pts;
SELECT 
[Дата заведения заявки]
,[Время заведения]
,Branch_name as [Офис заведения заявки]
,f.[Номер заявки]
,[ФИО клиента]
,min(cast([Дата статуса] AS DATETIME)) OVER (PARTITION BY f.[Номер заявки]) as [Дата статуса]
,[ФИО сотрудника верификации/чекер] as [Назначенный чекер]
,sum([ВремяЗатрачено]) OVER (PARTITION BY f.[Номер заявки]) * 24 * 60 as [Затраченное время (мин сек)]
,CASE 
	WHEN a2.decision = 'Accept' THEN 'Одобрено' 
	WHEN a2.decision = 'Decline' THEN 'Отказано' 
	ELSE 'Аннулировано' 
	END [Решение на этапе]
,dem_fl
,dem_time
,dor_fl
,dor_time
,case 
	when Result_1_26 = '100.0126.001' then 'Данные из справки о доходе перенесены в Федор'
	when Result_1_26 = '100.0126.002' then 'Подозрение в мошенничестве'
	when Result_1_26 = '100.0126.999' then 'Проверка не проводилась (системная)'
	when Result_1_26 = '100.0126.001' then 'Данные из справки о доходе перенесены в Федор'
	when Result_1_26 is null then 'Не назначалась проверка'
	else 'Другое' 
	end [Проверка дохода]
,case 
	when coalesce(cta.ConfirmedIncomeComponent, cta2.ConfirmedIncomeComponent, cta4.ConfirmedIncomeComponent) like '%reference2NDFL%' 
	then 'Справка 2-НДФЛ'
	when coalesce(cta.ConfirmedIncomeComponent, cta2.ConfirmedIncomeComponent, cta4.ConfirmedIncomeComponent) like '%CertificateFormBank%' 
	then 'Справка по форме Кредитной  Организации/работодателя'
	when coalesce(cta.ConfirmedIncomeComponent, cta2.ConfirmedIncomeComponent, cta4.ConfirmedIncomeComponent) like '%externalBankStatementForSalary%' 
	then 'Банковская выписка по зарплатному счету (бумажный или электронный вид)'
	when coalesce(cta.ConfirmedIncomeComponent, cta2.ConfirmedIncomeComponent, cta4.ConfirmedIncomeComponent) like '%referencePfrSfr%' 
	then 'Справка из ПФР/СФР о размере установленной пенсии'
	when coalesce(cta.ConfirmedIncomeComponent, cta2.ConfirmedIncomeComponent, cta4.ConfirmedIncomeComponent) is null 
	then 'Не назначалась проверка'
	when coalesce(cta.ConfirmedIncomeComponent, cta2.ConfirmedIncomeComponent, cta4.ConfirmedIncomeComponent) = '' 
	then 'Не назначалась проверка'
	else 'Другое' 
	end [Тип документа о доходе]

INTO #repbi_quality_report_checkers_pts
FROM [reports].[dbo].[dm_FedorVerificationRequests] f
LEFT JOIN (
	SELECT number ,Branch_name
	FROM [stg].[_loginom].[Originationlog]
	WHERE stage = 'Call 1'
	) a ON f.[Номер заявки] = a.Number
LEFT JOIN (
	SELECT number ,decision
	FROM [stg].[_loginom].[Originationlog]
	WHERE stage = 'Call 1.5'
	) a2 ON f.[Номер заявки] = a2.Number
LEFT JOIN (
	SELECT [Номер заявки] ,dem_fl = 1,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dem_time
	FROM [reports].[dbo].[dm_FedorVerificationRequests]
	WHERE Статус = 'Контроль данных' 
	AND Задача = 'task:Отложена'
	) fv ON f.[Номер заявки] = fv.[Номер заявки]
LEFT JOIN (
	SELECT [Номер заявки] ,dor_fl = 1 ,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dor_time
	FROM [reports].[dbo].[dm_FedorVerificationRequests]
	WHERE Статус = 'Контроль данных' 
	AND Задача = 'task:Требуется доработка'
	) fd ON f.[Номер заявки] = fd.[Номер заявки]
LEFT JOIN (
SELECT 
	number
	,Result_1_26 --Проверка дохода
	FROM [stg].[_loginom].[callcheckverif_log]
	WHERE stage = 'Call 1.5'
	) cc ON f.[Номер заявки] = cc.Number
LEFT JOIN stg._loginom.calculated_term_and_amount cta
	on f.[Номер заявки] = cta.number
	and cta.stage = 'Call 2'
LEFT JOIN stg._loginom.calculated_term_and_amount cta2
	on f.[Номер заявки] = cta.number
	and cta2.stage = 'Call 2.2'
LEFT JOIN stg._loginom.calculated_term_and_amount cta4
	on f.[Номер заявки] = cta.number
	and cta2.stage = 'Call 4'
WHERE Статус = 'Контроль данных' 
AND Задача = 'task:В работе' 
AND [Дата статуса] > dateadd(day, - day(getdate()) + 1, cast(getdate() AS DATE))
;
------------------------------------------Верификаторы ПТС
DROP TABLE IF EXISTS #repbi_quality_report_verification_pts;
SELECT 
[Дата заведения заявки]
,[Время заведения]
,Branch_name as [Офис заведения заявки]
,f.[Номер заявки]
,[ФИО клиента]
,min(cast([Дата статуса] AS DATETIME)) OVER (PARTITION BY f.[Номер заявки]) as [Дата статуса]
,[ФИО сотрудника верификации/чекер] as [Назначенный верификатор]
,sum([ВремяЗатрачено]) OVER (PARTITION BY f.[Номер заявки]) * 24 * 60 as [Затраченное время (мин сек)]
,CASE 
	WHEN a2.decision = 'Accept' THEN 'Одобрено' 
	WHEN a2.decision = 'Decline' THEN 'Отказано' 
	ELSE 'Аннулировано' 
	END [Решение по клиенту]
,[Последний статус заявки] as [Статус по заявке]
,CASE 
	WHEN ([UW_Result_8] = '100.0208.001') THEN 'Клиент идентифицирован, моб тел принадлежит клиенту' 
	WHEN ([UW_Result_8] = '100.0208.999') THEN 'Проверка не проводилась (системная)' 
	WHEN ([UW_Result_8] = '100.0208.003') THEN 'Мобильный телефон клиента принадлежит 3-му лицу (близкому родственнику), заявку перзаводим' 
	WHEN ([UW_Result_8] = '100.0208.004') THEN 'Идентификация не пройдена (не может назвать свое ФИО, дату рождения)' 
	WHEN ([UW_Result_8] = '100.0208.005') THEN 'Отказ клиента, клиент не оформлял займ' 
	WHEN ([UW_Result_8] = '100.0208.006') THEN 'Кредит для 3-х лиц' 
	WHEN ([UW_Result_8] = '100.0208.008') THEN 'Клиент дает противоречивую инф-ю' 
	WHEN ([UW_Result_8] = '100.0208.009') THEN 'Клиент "Олень" (приведен 3-ми лицами)' 
	WHEN ([UW_Result_8] = '100.0208.010') THEN 'Клиент подтвердил, что обратился за кредитом под влиянием 3х лиц' 
	WHEN ([UW_Result_8] = '100.0208.002') THEN 'Мобильный телефон клиента принадлежит 3-му лицу. Подозрение в мошенничестве' 
	WHEN ([UW_Result_8] = '100.0208.011') THEN 'Клиент пьян' 
	WHEN ([UW_Result_8] = '100.0208.012') THEN 'Отвечает 3 лицо - представляется клиентом' 
	WHEN ([UW_Result_8] IS NULL) THEN 'Не назначалась проверка' 
	ELSE 'Другое' 
	END [Контактность клиента]
,CASE 
	WHEN [UW_Result_30] = '100.0230.003' THEN 'НЕДОЗВОН' 
	WHEN [UW_Result_30] IN ('100.0230.001', '100.0230.002', '100.0230.009', '100.0230.010') THEN 'Дозвон' 
	WHEN [UW_Result_30] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_30] = '100.0230.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_30] IN ('100.0230.004', '100.0230.005', '100.0230.006', '100.0230.007', '100.0230.008') THEN 'Не найден/не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Контур Фокуса]
,CASE 
	WHEN [UW_Result_32] = '100.0232.004' THEN 'НЕДОЗВОН' 
	WHEN [UW_Result_32] IN ('100.0232.001', '100.0232.002', '100.0232.003', '100.0232.010', '100.0232.011') THEN 'Дозвон' 
	WHEN [UW_Result_32] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_32] = '100.0232.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_32] IN ('100.0232.005', '100.0232.006', '100.0232.007', '100.0232.008', '100.0232.009') THEN 'Не найден/не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Интернет]
,CASE 
	WHEN [UW_Result_33] = '100.0233.004' THEN 'НЕДОЗВОН' 
	WHEN [UW_Result_33] IN ('100.0233.001', '100.0233.002', '100.0233.003', '100.0233.010', '100.0233.011') THEN 'Дозвон' 
	WHEN [UW_Result_33] IS NULL THEN 'Не назначалась проверка' WHEN [UW_Result_33] = '100.0233.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_33] IN ('100.0233.005', '100.0233.006', '100.0233.007', '100.0233.008', '100.0233.009') THEN 'Не найден/не требуется' 
	ELSE 'Другое' 
	END [Контактность работодателя по телефонам из Анкеты]
,case 
	when Result_2_40 = '100.0240.001' then 'Найден аккаунт: клиент идентифицирован по фото, нет негатива'
	when Result_2_40 = '100.0240.002' then 'Найден аккаунт: клиент идентифицирован без фото, нет негатива'
	when Result_2_40 = '100.0240.003' then 'Найден аккаунт: клиент идентифицирован, выявлен негатив'
	when Result_2_40 = '100.0240.004' then 'Найдено несколько аккаунтов, клиент не идентифицирован'
	when Result_2_40 = '100.0240.005' then 'Аккаунт не найден'
	when Result_2_40 = '100.0240.006' then 'Проверка не проводилась'
	when Result_2_40 = '100.0240.999' then 'Проверка не проводилась (системная)'
	when [UW_Result_3_old] IN ('100.0803.001', '100.0803.002', '100.0803.003') then 'Найден аккаунт' 
	when [UW_Result_3_old] = '100.0803.004' then 'Аккаунт не найден' 
	when [UW_Result_3_old] = '100.0803.999' then 'Проверка не проводилась (системная)' 
	when coalesce(Result_2_40, [UW_Result_3_old]) is null then 'Не назначалась проверка'
	else 'Другое' 
	end [СОЦ СЕТИ]
,CASE 
	WHEN ClientIncomeAdditional IS NOT NULL 
	THEN 'Есть' 
	ELSE 'Нет' 
	END [Доп.доход (есть/нет)]
,CASE 
	WHEN [UW_Result_22] IN ('100.0222.001', '100.0222.002', '100.0222.003', '100.0222.004', '100.0222.005') THEN 'Требуется' 
	WHEN [UW_Result_22] = '100.0222.006' THEN 'Не требуется' 
	WHEN [UW_Result_22] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_22] = '100.0222.999' THEN 'Проверка не проводилась (системная)' 
	ELSE 'Другое' 
	END [Проверка Антифрод]
,CASE 
	WHEN [UW_Result_13] = '100.0213.005' THEN 'Негатив отсутствует' 
	WHEN [UW_Result_13] = '100.0213.006' THEN 'Инвалидность' 
	WHEN [UW_Result_13] = '100.0213.013' THEN 'Типаж БОМЖ, ЦЫГАНЕ' 
	WHEN [UW_Result_13] = '100.0213.009' THEN 'Подозрение в мошенничестве: геолокация' 
	WHEN [UW_Result_13] IS NULL THEN 'Не назначалась проверка' 
	WHEN [UW_Result_13] = '100.0213.999' THEN 'Проверка не проводилась (системная)' 
	WHEN [UW_Result_13] IN ('100.0213.011', '100.0213.012') THEN 'Негатив по соц.сетям' 
	WHEN [UW_Result_13] IN ('100.0213.004', '100.0213.007', '100.0213.014', '100.0213.015', '100.0213.016') THEN 'Прочее' 
	ELSE 'Другое' 
	END [НЕГАТИВЫ]
,case 
	when [UW_Result_vchat] = '100.0234.001' then 'Все фото корректны, ВЧ не требуется'
	when [UW_Result_vchat] = '100.0234.002' then 'Успешно'
	when [UW_Result_vchat] = '100.0234.003' then 'Клиент не отвечает на звонки по ВЧ'
	when [UW_Result_vchat] = '100.0234.004' then 'Проблема с интернетом'
	when [UW_Result_vchat] = '100.0234.005' then 'Клиент не рядом с авто'
	when [UW_Result_vchat] = '100.0234.006' then 'Клиент отказался (негатив)'
	when [UW_Result_vchat] = '100.0234.007' then 'Клиент отказался (сделает самостоятельно)'
	when [UW_Result_vchat] = '100.0234.008' then 'Не удалось сделать фото'
	when [UW_Result_vchat] = '100.0234.009' then 'Проблемы с телефоном (разряжен; садится; не поддерживает видео)'
	when [UW_Result_vchat] = '100.0234.010' then 'Фото сделано, но низкого качества'
	when [UW_Result_vchat] = '100.0234.011' then 'Тех. проблема с сервисом'
	when [UW_Result_vchat] = '100.0234.012' then 'Нет всех фото, сделает самостоятельно'
	when [UW_Result_vchat] = '100.0234.999' then 'Проверка не проводилась (системная)'
	when [UW_Result_vchat] is null then 'Не назначалась проверка'
	else 'Другое' 
	end [Видеочат]
,case 
	when result_2_28 = '100.0228.001' then 'Подтверждена принадлежность телефона клиенту'
	when result_2_28 = '100.0228.002' then 'Данные о телефоне клиента отсутствуют'
	when result_2_28 = '100.0228.003' then 'Телефон клиента зарегистрирован на иное лицо'
	when result_2_28 = '100.0228.999' then 'Проверка не проводилась (системная)'
	when result_2_28 is null then 'Не назначалась проверка'
	else 'Другое' 
	end [Проверка телефонов по базам - телефон клиента]

,dem_fl
,dem_time
,dor_fl
,dor_time
INTO #repbi_quality_report_verification_pts
FROM [reports].[dbo].[dm_FedorVerificationRequests] f
LEFT JOIN (
	SELECT number
	,Branch_name
	FROM [stg].[_loginom].[Originationlog]
	WHERE stage = 'Call 2'
	) a ON f.[Номер заявки] = a.Number
LEFT JOIN (
	SELECT number
	,decision
	FROM [stg].[_loginom].[Originationlog]
	WHERE stage = 'Call 3'
	) a2 ON f.[Номер заявки] = a2.Number
LEFT JOIN (
	SELECT 
	number
	,Result_2_8 AS [UW_Result_8]
	,Result_2_11 AS [UW_Result_11]
	,Result_2_29 AS [UW_Result_29]
	,Result_2_30 AS [UW_Result_30]
	,Result_2_32 AS [UW_Result_32]
	,Result_2_33 AS [UW_Result_33]
	,Result_2_40 --[СОЦ СЕТИ]
	,Result_2_22 AS [UW_Result_22]
	,Result_2_13 AS [UW_Result_13]
	,coalesce(result_2_34, result_3_3) as [UW_Result_vchat]  --Видеочат
	,result_2_28 --Проверка телефонов по базам - телефон клиента
	,isnull(Result_1_203, Result_2_103) as [UW_Result_3_old] --СОЦ СЕТИ старые правила
	FROM [stg].[_loginom].[callcheckverif_log]
	WHERE stage in ('Call 3', 'Call 4')
	) c ON f.[Номер заявки] = c.Number
LEFT JOIN #ClientIncomeAdditional_SRC cf 
	ON f.[Номер заявки] = cf.Number collate Cyrillic_General_CI_AS
LEFT JOIN (
	SELECT [Номер заявки]
	,dem_fl = 1
	,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dem_time
	FROM [reports].[dbo].[dm_FedorVerificationRequests]
	WHERE (Статус = 'Верификация клиента' OR Статус = 'Верификация ТС') 
	AND Задача = 'task:Отложена'
	) fv ON f.[Номер заявки] = fv.[Номер заявки]
LEFT JOIN (
	SELECT [Номер заявки]
	,dor_fl = 1
	,sum([ВремяЗатрачено]) OVER (PARTITION BY [Номер заявки]) * 24 * 60 as dor_time
	FROM [reports].[dbo].[dm_FedorVerificationRequests]
	WHERE (Статус = 'Верификация клиента' OR Статус = 'Верификация ТС') 
	AND Задача = 'task:Требуется доработка'
	) fd ON f.[Номер заявки] = fd.[Номер заявки]
WHERE (Статус = 'Верификация клиента' OR Статус = 'Верификация ТС') 
AND Задача = 'task:В работе' 
AND [Дата статуса] > dateadd(day, - day(getdate()) + 1, cast(getdate() AS DATE))
;
-----------------------------------------------Итог Чекеры
drop table if exists #final_checkers;
-------INST
SELECT 
DISTINCT cast('INST' AS VARCHAR(100)) AS product
,[Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный чекер]
,[Затраченное время (мин сек)]
,[Решение на этапе]
,CASE WHEN dem_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Отложена'
,dem_time [Время в отложенных (мин сек)]
,CASE WHEN dor_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Доработка'
,dor_time [Время на доработке (мин сек)]
,[Решение по клиенту]
,[Статус по заявке]
,[Контактность клиента]
,[Контактность работодателя по телефонам из Контур Фокуса]
,[Контактность работодателя по телефонам из Интернет]
,[Контактность работодателя по телефонам из Анкеты]
,cast('Нет' AS VARCHAR(200)) AS [Доп доход (есть/нет)]
,[Проверка Антифрод]
,[НЕГАТИВЫ]
,[СОЦ СЕТИ]
,[Проверка телефонов по базам - телефон клиента]
,cast('' AS VARCHAR(100)) as [Проверка дохода]
,cast('' AS VARCHAR(100)) as [Тип документа о доходе]
,getdate() AS dt_dml
into #final_checkers
FROM #repbi_quality_report_checkers_inst
ORDER BY [Номер заявки],[Дата статуса]
;
-------PDL
INSERT INTO #final_checkers
SELECT 
DISTINCT cast('PDL' AS VARCHAR(100)) AS product
,[Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный чекер]
,[Затраченное время (мин сек)]
,[Решение на этапе]
,[Отложена]
,[Время в отложенных (мин сек)]
,[Доработка]
,[Время на доработке (мин сек)]
,[Решение по клиенту]
,[Статус по заявке]
,[Контактность клиента]
,[Контактность работодателя по телефонам из Контур Фокуса]
,[Контактность работодателя по телефонам из Интернет]
,[Контактность работодателя по телефонам из Анкеты]
,cast('Нет' AS VARCHAR(200)) AS [Доп доход (есть/нет)]
,[Проверка Антифрод]
,[НЕГАТИВЫ]
,[СОЦ СЕТИ]
,[Проверка телефонов по базам - телефон клиента]
,'' as [Проверка дохода]
,cast('' AS VARCHAR(100)) as [Тип документа о доходе]
,getdate() AS dt_dml
FROM #repbi_quality_report_checkers_pdl
ORDER BY [Номер заявки],[Дата статуса]
;
-------PTS
INSERT INTO #final_checkers
SELECT 
DISTINCT cast('PTS' AS VARCHAR(100)) AS product
,[Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный чекер]
,[Затраченное время (мин сек)]
,[Решение на этапе]
,CASE WHEN dem_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Отложена'
,dem_time [Время в отложенных (мин сек)]
,CASE WHEN dor_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Доработка'
,dor_time [Время на доработке (мин сек)]
,'' AS [Решение по клиенту]
,'' AS [Статус по заявке]
,'' AS [Контактность клиента]
,'' AS [Контактность работодателя по телефонам из Контур Фокуса]
,'' AS [Контактность работодателя по телефонам из Интернет]
,'' AS [Контактность работодателя по телефонам из Анкеты]
,'' AS [Доп доход (есть/нет)]
,'' AS [Проверка Антифрод]
,'' AS [НЕГАТИВЫ]
,'' AS [СОЦ СЕТИ]
,'' AS [Проверка телефонов по базам - телефон клиента]
,[Проверка дохода]
,[Тип документа о доходе]
,getdate() AS dt_dml
FROM #repbi_quality_report_checkers_pts
ORDER BY [Номер заявки],[Дата статуса]

;
---------------------------------------------------Итог Верификаторы 
drop table if exists #final_verification;
SELECT 
DISTINCT cast('PTS' AS VARCHAR(100)) AS product
,[Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный верификатор]
,[Затраченное время (мин сек)]
,[Решение по клиенту]
,[Статус по заявке]
,[Контактность клиента]
,[Контактность работодателя по телефонам из Контур Фокуса]
,[Контактность работодателя по телефонам из Интернет]
,[Контактность работодателя по телефонам из Анкеты]
,[Доп.доход (есть/нет)]
,[Проверка Антифрод]
,[НЕГАТИВЫ]
,[СОЦ СЕТИ]
,[Видеочат]
,[Проверка телефонов по базам - телефон клиента]
,CASE WHEN dem_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Отложена'
,dem_time [Время в отложенных (мин сек)]
,CASE WHEN dor_fl = 1 THEN 'Да' ELSE 'Нет' END AS 'Доработка'
,dor_time [Время на доработке (мин сек)]
,getdate() AS dt_dml
into #final_verification
FROM #repbi_quality_report_verification_pts
ORDER BY [Номер заявки],[Дата статуса]
;
-----------------------------------------------Внесение данных
if OBJECT_ID('risk.repbi_quality_report_checkers_newtemp') is null
begin
	select top(0) * into risk.repbi_quality_report_checkers_newtemp
	from #final_checkers
end;

if OBJECT_ID('risk.repbi_quality_report_verification_newtemp') is null
begin
	select top(0) * into risk.repbi_quality_report_verification_newtemp
	from #final_verification
end;

BEGIN TRANSACTION
truncate table risk.repbi_quality_report_checkers_newtemp;
insert into risk.repbi_quality_report_checkers_newtemp
select * from #final_checkers
;
truncate table risk.repbi_quality_report_verification_newtemp;
insert into risk.repbi_quality_report_verification_newtemp
select * from #final_verification
;
COMMIT TRANSACTION;

drop table if exists #ClientIncomeAdditional_SRC;
drop table if exists #repbi_quality_report_checkers_inst;
drop table if exists #repbi_quality_report_checkers_pdl;
drop table if exists #repbi_quality_report_checkers_pts;
drop table if exists #repbi_quality_report_verification_pts;
drop table if exists #final_checkers;
drop table if exists #final_verification;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END;
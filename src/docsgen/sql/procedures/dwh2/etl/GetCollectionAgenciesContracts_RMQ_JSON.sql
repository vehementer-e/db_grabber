-- exec [etl].[GetCollectionAgenciesContracts_RMQ_JSON] '89A38C7E-0901-11E8-A814-00155D941900'
CREATE PROCEDURE [etl].[GetCollectionAgenciesContracts_RMQ_JSON]
    @crmClientGuid UNIQUEIDENTIFIER = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
	declare @today date = getdate()
						
    ;WITH base AS (
        SELECT t1.* FROM (
		  SELECT
            ac.external_id,
            [ИНН КА]				= ca.inn,
            [Дата передачи в КА]	= ac.[st_date],
            [Дата отзыва]			= ac.[fact_end_date],
			ac.reestr,
            [Плановая дата отзыва]	= ac.[plan_end_date],
            ca.Name      AS CA_Name,
            ca.Phone     AS CA_Phone,
			ca.AgentName AS CA_AgentName,
            contract.GuidДоговораЗайма,		
            contract.ДатаДоговораЗайма,
            client.GuidКлиент,				 
            client.Наименование
			,GuidЗаявки =ДоговорЗайма_Заявка.[GuidЗаявки]
			,collectionAgencyId =  ca.Guid
			,collectionAgencyDetailsId =  ac.row_id
			,data_id  = CAST(ac.row_id AS VARCHAR(50))
			, FORMAT(ROUND(b.total_rest, 2), '0.00') AS total_rest
			, [Текущий статус] = (case 
						when isnull(ac.fact_end_date, ac.plan_end_date)
						> @today then 'Договор передан в КА' else 'Договор отозван из КА' end)
			, ROW_NUMBER() OVER (partition by ac.external_id order by ac.[st_date] desc) AS rn,
			CASE
				WHEN ac.fact_end_date IS NULL THEN ac.plan_end_date
				WHEN ac.fact_end_date <= ac.plan_end_date THEN ac.fact_end_date
				ELSE ac.plan_end_date
			END as end_date,
			rsi.last_sent,
			rsi.force_send,
			rsi.ac_rowversion as rsi_rowversion,
			ac.RowVersion as ac_rowversion
        FROM  dwh_new.[dbo].[agent_credits]       AS ac
        JOIN stg._Collection.CollectorAgencies   AS ca
            ON ac.agent_name = ca.AgentName
        JOIN dwh2.[hub].[ДоговорЗайма]          AS contract
            ON ac.external_id = contract.КодДоговораЗайма
        JOIN dwh2.[link].[v_Клиент_ДоговорЗайма] AS link
            ON contract.КодДоговораЗайма = link.КодДоговораЗайма
        JOIN dwh2.[hub].[Клиенты]               AS client
            ON link.GuidКлиент = client.GuidКлиент
		JOIN dwh2.[link].[v_ДоговорЗайма_Заявка]   ДоговорЗайма_Заявка on ДоговорЗайма_Заявка.[GuidДоговораЗайма] 
			= contract.GuidДоговораЗайма
		LEFT JOIN (select external_id,
                  cdate =d ,
				  isnull([Расчетный остаток всего], 0) as total_rest
           from  dwh2.[dbo].[dm_CMRStatBalance]
		   where d <= dateadd(dd,-1,@today)) b 
			on ac.external_id = b.external_id
			and ac.st_date = b.cdate
		LEFT JOIN dwh2.etl.rmq_sent_items AS rsi
                   ON rsi.item_id   = ac.row_id
                  AND rsi.item_type = 'agent_credits'
				--  and rsi.ac_rowversion = ac.RowVersion
        WHERE 1=1
			and (@crmClientGuid IS NULL OR client.GuidКлиент = @crmClientGuid)
			--AND
	  ) t1 
	  WHERE 1=1
	--	and t1.rn = 1 
		and
		(t1.last_sent IS NULL 
		OR t1.force_send = 1 
		or isnull(t1.rsi_rowversion, 0x00)<>t1.ac_rowversion
	--	or (@crmClientGuid IS NULL OR GuidКлиент = @crmClientGuid)
			
		)


    )

    SELECT
        JSON = CONCAT(
            '{"meta":',    m.meta_json,
            ',"data":',    d.data_json,
            ',"included":',incl.included_json,
            '}'
        )
    FROM base AS b

    -- Генерация meta
    CROSS APPLY (
        SELECT 
            message_guid     = b.data_id, --NEWID(),
            publish_unix     = FORMAT(DATEDIFF(SECOND, '1970-01-01', GETUTCDATE()),'0'),
            publisher_code   = 'dwh',
            contract_doc_url = 'https://wiki.carmoney.ru/x/',
            jsonapi_url      = 'https://wiki.carmoney.ru/x/'
    ) AS gen_meta

    -- Генерация data
	CROSS APPLY (
		SELECT top(1)
			id,
			code,
			[description]
		FROM stg.etl.[tvf_GetInteractionsEvents]('Обновление данных по передачи в коллекторское агентсво')
	) AS gen_event

    CROSS APPLY (
        SELECT 
            meta_json = (
                SELECT
                    guid      = gen_meta.message_guid,
                    time      = JSON_QUERY((SELECT publish = gen_meta.publish_unix    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
                    publisher = JSON_QUERY((SELECT code    = gen_meta.publisher_code  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
                    links     = JSON_QUERY((
                                   SELECT documentation = JSON_QUERY((
                                          SELECT contract = gen_meta.contract_doc_url,
                                                 jsonAPI   = gen_meta.jsonapi_url
                                          FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                                       ))
                                   FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                                 ))
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )
    ) AS m

    CROSS APPLY (
        SELECT
            data_json = (
                SELECT
                    'interactions' AS [type],
                    b.data_id      AS [id],
                    JSON_QUERY(
                        (SELECT FORMAT(GETDATE(),'dd-MM-yyyyTHH:mm:ss') AS [date]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS [attributes],

                    /* relationships */
                    JSON_QUERY(
                        (SELECT
                             /* event */
                             JSON_QUERY(
                                 (SELECT JSON_QUERY(
                                            (SELECT 'events' AS [type],
                                                    gen_event.id AS [id]
                                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                      ) AS [data]
                                  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                             ) AS [event],

                             /* contract */
                             JSON_QUERY(
                                 (SELECT JSON_QUERY(
                                            (SELECT 'contracts' AS [type],
                                                    b.GuidДоговораЗайма AS [id]
                                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                      ) AS [data]
                                  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                             ) AS [contract],

                             /* request */
                             JSON_QUERY(
                                 (SELECT JSON_QUERY(
                                            (SELECT 'requests' AS [type],
                                                    b.GuidЗаявки AS [id]
                                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                      ) AS [data]
                                  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                             ) AS [request],

                             /* client */
                             JSON_QUERY(
                                 (SELECT JSON_QUERY(
                                            (SELECT 'clients' AS [type],
                                                    b.GuidКлиент AS [id]
                                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                      ) AS [data]
                                  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                             ) AS [client],

                             /* collectionAgency */
                             JSON_QUERY(
                                 (SELECT JSON_QUERY(
                                            (SELECT 'collectionAgencies' AS [type],
                                                    b.collectionAgencyId AS [id]
                                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                      ) AS [data]
                                  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                             ) AS [collectionAgency],

                             /* collectionAgencyDetail */
                             JSON_QUERY(
                                 (SELECT JSON_QUERY(
                                            (SELECT 'collectionAgencyDetails' AS [type],
                                                    b.collectionAgencyDetailsId AS [id]
                                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                      ) AS [data]
                                  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                             ) AS [collectionAgencyDetail]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                    ) AS [relationships]
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )
    ) AS d

    -- Генерация included
    CROSS APPLY (
        SELECT
            included_json = (
                SELECT
                    inc.type, inc.id, 
					JSON_QUERY(inc.attributes) AS attributes
                FROM (VALUES
                    ('contracts',  b.GuidДоговораЗайма,
                      JSON_QUERY(
									(SELECT b.External_id AS [number]
										FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
									)
								)
					),
                    ('requests',  CAST(b.GuidЗаявки  AS VARCHAR(36)),
                      JSON_QUERY(
									(SELECT b.External_id AS [number]
										FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
									)
								)
					),
                    ('events', gen_event.id,
                      JSON_QUERY(
									(SELECT gen_event.code AS [code],
                                            gen_event.[description] AS [description]
										FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
									)
								)
					),
                    ('clients',  CAST(b.GuidКлиент AS VARCHAR(36)),
                      JSON_QUERY(
									(SELECT b.Наименование  AS [name]
										FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
									)
								)
					),
                    ('collectionAgencies',  
					  CAST(b.collectionAgencyId AS VARCHAR(36)),
                      JSON_QUERY(
									(SELECT b.CA_AgentName             AS [name],
                                            b.CA_Name             AS [fullName],
											b.[ИНН КА]            AS [inn],
                                            b.CA_Phone            AS [phone],
                                            b.external_id         AS [contract],
                                            FORMAT(b.ДатаДоговораЗайма, 'yyyy-MM-dd') AS [dateContract]
										FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
									)
					  )
					),
                    ('collectionAgencyDetails', 
					  CAST(b.collectionAgencyDetailsId  AS VARCHAR(36)),
                      JSON_QUERY(
									(SELECT 
											FORMAT(b.[Дата передачи в КА], 'yyyy-MM-dd')    AS [transferDate],
											FORMAT(b.[Дата отзыва], 'yyyy-MM-dd')          AS [returnDate],
											FORMAT(b.[Плановая дата отзыва], 'yyyy-MM-dd') AS [plannedReviewDate],
											b.reestr AS [registryNumber],
											b.total_rest AS [debtSum],
											b.[Текущий статус] as currentStatus
										FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
									)
					  )
					)
                ) AS inc(type, id, attributes)
                FOR JSON PATH
            )
    ) AS incl;
END

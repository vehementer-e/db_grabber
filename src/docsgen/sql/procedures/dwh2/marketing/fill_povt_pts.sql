-- =======================================================
-- Create: 31.08.2023. А.Никитин
-- Description:	DWH-2195 Заполнение таблицы marketing.povt_pts
-- =======================================================
CREATE PROC [marketing].[fill_povt_pts]
	@CMRClientGUID nvarchar(36) = null
AS
BEGIN
	BEGIN TRY
		IF NOT EXISTS(SELECT TOP(1) 1 FROM risk.povt_buffer)
		BEGIN
			;THROW 51000, 'Отсутствуют данные в risk.povt_buffer', 16
		END
        
		DROP TABLE IF EXISTS #t_povt_pts

		SELECT TOP(0)
			marketProposal_ID,
			cdate,
			dwh_created_at,
			RequestСсылка,
			RequestGUID,
			external_id,
			category,
			Type,
			main_limit,
			[Минимальный срок кредитования],
			[Ставка %],
			[Сумма платежа],
			[Рекомендуемая дата повторного обращения],
			fio,
			birth_date,
			vin,
			channel,
			doc_ser,
			doc_num,
			ТелефонМобильный,
			region_projivaniya,
			Berem_pts,
			Nalichie_pts,
			
			num_active_days,
			market_price,
			collateral_id,
			price_date,
			days,
			discount_price,
			limit_car,
			КлиентСсылка = cast(NULL AS binary(16)),
			CRMClientGUID,
			last_name,
			first_name,
			patronymic,
			market_proposal_category_id,
			market_proposal_category_name,
			market_proposal_category_code,
			market_proposal_type_id,
			market_proposal_type_name,
			market_proposal_type_code,
			phone,
			client_email,
			passportNotValid,
			lkUserId,
			phoneInBlackList,
			clientTimeZone,
			ТранспортноеСредствоGuid,
			ТранспортноеСредствоНаименование,
			МаркаGuid,
			МодельGuid,
			РегистрационныйНомер,
			ТранспортноеСредствоГод,
			МаркаПТС,
			МодельПТС,
			СерияПТС,
			НомерПТС,
			[lead_Id],
			[product_type_id],	
			[product_type_name],
			[product_type_code],
			[was_closed_ago],
			hasPEP,
			[hasCommissionProducts],
			lastRate,
			row_hash
		into #t_povt_pts
		from marketing.povt_pts
		
		--1 CRMClientGUID, RequestСсылка, RequestGUID, external_id, vin, 
		DROP TABLE IF EXISTS #t_Заявка

		SELECT DISTINCT
			КлиентСсылка = D.Партнер,
			RequestСсылка = D.Ссылка,
			RequestGUID = dbo.getGUIDFrom1C_IDRREF(D.Ссылка),
			R.external_id
			
		INTO #t_Заявка
		FROM risk.povt_buffer AS R
			INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS D
				ON D.Номер = R.external_id
		WHERE 1=1
		--	AND R.category NOT IN ('Красный')

		----2 CRMClientGUID, КлиентСсылка
		--DROP TABLE IF EXISTS #t_Client
		--CREATE TABLE #t_Client(
		--	CRMClientGUID varchar(36),
		--	КлиентСсылка binary(16)
		--)
		--INSERT #t_Client(CRMClientGUID, КлиентСсылка)
		--SELECT DISTINCT
		--	R.CRMClientGUID,
		--	R.КлиентСсылка
		--FROM #t_Заявка AS R

		--3 Транспортное Средство
		DROP TABLE IF EXISTS #t_ТранспортноеСредство

		--3.1
		SELECT 
			*
		INTO #t_ТранспортноеСредство
		from (
			select 
			vin = TS.ИдентификационныйНомер, --TS.ИдентификационныйНомер,
			ТранспортноеСредствоGuid = dbo.getGUIDFrom1C_IDRREF(TS.Ссылка),
			ТранспортноеСредствоНаименование = TS.Наименование,

			МаркаСсылка = TS.Марка,
			МаркаGuid = dbo.getGUIDFrom1C_IDRREF(TS.Марка),

			МодельСсылка = TS.Модель,
			МодельGuid = dbo.getGUIDFrom1C_IDRREF(TS.Модель),

			TS.РегистрационныйНомер,
			ТранспортноеСредствоГод = TS.Год,
			TS.МаркаПТС,
			TS.МодельПТС,
			TS.СерияПТС,
			TS.НомерПТС,
			nRow = Row_Number() over (partition by ИдентификационныйНомер order by Код)
		FROM  Stg._1cCRM.Справочник_ТранспортныеСредства AS TS 
		) t
		where  t.nRow = 1

	



		INSERT #t_povt_pts
		(
			marketProposal_ID,
			cdate,
			dwh_created_at,
			RequestСсылка,
			RequestGUID,
			external_id,
			category,
			Type,
			main_limit,
			[Минимальный срок кредитования],
			[Ставка %],
			[Сумма платежа],
			[Рекомендуемая дата повторного обращения],
			fio,
			birth_date,
			vin,
			channel,
			doc_ser,
			doc_num,
			ТелефонМобильный,
			region_projivaniya,
			Berem_pts,
			Nalichie_pts,
			
			num_active_days,
			market_price,
			collateral_id,
			price_date,
			days,
			discount_price,
			limit_car,
			КлиентСсылка,
			CRMClientGUID,
			last_name,
			first_name,
			patronymic,
			market_proposal_category_id,
			market_proposal_category_name,
			market_proposal_category_code,
			market_proposal_type_id,
			market_proposal_type_name,
			market_proposal_type_code,
			phone,
			client_email,
			passportNotValid,
			lkUserId,
			phoneInBlackList,
			clientTimeZone,
			ТранспортноеСредствоGuid,
			ТранспортноеСредствоНаименование,
			МаркаGuid,
			МодельGuid,
			РегистрационныйНомер,
			ТранспортноеСредствоГод,
			МаркаПТС,
			МодельПТС,
			СерияПТС,
			НомерПТС,
			[product_type_id],	
			[product_type_name],
			[product_type_code]	,
			[was_closed_ago],
			lastRate
		)
		SELECT 
			marketProposal_ID = cast(hashbytes('SHA2_256',concat(Заявка.RequestGUID, '|', TS.ТранспортноеСредствоGuid)) as uniqueidentifier),
			cdate = cast(getdate() as date),
			dwh_created_at = getdate(),
			Заявка.RequestСсылка,
			Заявка.RequestGUID,

			R.external_id,
			R.category,
			R.Type,
			R.main_limit,
			R.[Минимальный срок кредитования],
			R.[Ставка %],
			R.[Сумма платежа],
			R.[Рекомендуемая дата повторного обращения],
			R.fio,
			R.birth_date,
			R.vin,
			R.channel,
			R.doc_ser,
			R.doc_num,
			R.ТелефонМобильный,
			R.region_projivaniya,
			Berem_pts = R.Berem_pt,
			R.Nalichie_pts,
			R.num_active_days,
			R.market_price,
			R.collateral_id,
			R.price_date,
			R.days,
			R.discount_price,
			R.limit_car,
			КлиентСсылка = CRM_Клиент.Ссылка,
			R.CRMClientGUID,
			last_name = CMR_Клиент.Фамилия,
			first_name = CMR_Клиент.Имя,
			patronymic = CMR_Клиент.Отчество,

			market_proposal_category_id = isnull(dic_mp.Id, cast(null as uniqueidentifier )),
			market_proposal_category_name = dic_mp.Name,
			market_proposal_category_code = dic_mp.CodeName,

			market_proposal_type_id = isnull(dic_t.Id, cast(null as uniqueidentifier )), 
			market_proposal_type_name = dic_t.Наименование, 
			market_proposal_type_code = dic_t.Код,

			phone = R.ОсновнойТелефонКлиента,
			client_email = CRM_КонтактнаяИнформация_email.email,
			passportNotValid = 
			iif(nullif(TRIM(R.doc_ser),'') is null
				or nullif(TRIM(R.doc_num),'') is null
				,1, 0),

			lkUserId = cr.LKUserId,
			phoneInBlackList = 0,
			--FIO = concat(TRIM(t.[last_name]), ' ', TRIM(t.[first_name]), ' ',  TRIM(t.[patronymic])),
			clientTimeZone = br.CRM_ВремяПоГринвичу_GMT,

			TS.ТранспортноеСредствоGuid,
			TS.ТранспортноеСредствоНаименование,
			TS.МаркаGuid,
			TS.МодельGuid,
			TS.РегистрационныйНомер,
			TS.ТранспортноеСредствоГод,
			TS.МаркаПТС,
			TS.МодельПТС,
			TS.СерияПТС,
			TS.НомерПТС,
			[product_type_id]		= isnull(pt.Id, cast(null as uniqueidentifier )), 
			[product_type_name]		= pt.Name, 
			[product_type_code]		= pt.CodeName,
			r.[was_closed_ago],
			lastRate				= r.[last_int_rate]
		FROM
			risk.povt_buffer AS R
				--ON T.CRMClientGUID = R.CRMClientGUID
			inner join stg.dbo.v_1cMDS_ProductType  pt 
				on 1=1 
				and UPPER(pt.Name)  = 'Pts'
			--	AND isnull(T.vin, '') = isnull(R.vin, '')
			inner join #t_Заявка Заявка   
				on Заявка.external_id = r.external_id
			LEFT JOIN Stg._1cCMR.Справочник_Клиенты AS CMR_Клиент
				ON dbo.getGUIDFrom1C_IDRREF(CMR_Клиент.Ссылка) = R.CRMClientGUID
				
			LEFT JOIN Stg._1cCRM.Справочник_Партнеры AS CRM_Клиент 
				--ON CRM_Клиент.Ссылка = CMR_Клиент.Ссылка
				ON dbo.getGUIDFrom1C_IDRREF(CRM_Клиент.Ссылка) = R.CRMClientGUID
				--ON CRM_Клиент.Ссылка = Client.КлиентСсылка
			LEFT JOIN dbo.ClientReferences AS cr
				ON cr.CMRContractNumber = R.external_id

			--LEFT JOIN (
			--	select 
			--		Партнер = CRM_КонтактнаяИнформация.Ссылка 
			--		,НомерТелефонаБезКодов
			--		,nRow = Row_Number() over(partition by CRM_КонтактнаяИнформация.Ссылка order by ДатаЗаписи desc
			--			,НомерСтроки desc)
			--	from stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация CRM_КонтактнаяИнформация
			--			where CRM_КонтактнаяИнформация.CRM_ОсновнойДляСвязи = 0x01
			--			and CRM_КонтактнаяИнформация.Актуальный = 0x01
			--				and CRM_КонтактнаяИнформация.Тип = 0xA873CB4AD71D17B2459F9A70D4E2DA66
			--	) AS CRM_КонтактнаяИнформация 
			--		ON CRM_КонтактнаяИнформация.Партнер = CRM_Клиент.Ссылка
			--		AND CRM_КонтактнаяИнформация.nRow = 1

			LEFT JOIN Stg._1cCRM.Справочник_БизнесРегионы AS br      
				ON br.Ссылка = CRM_Клиент.РегионФактическогоПроживания

			LEFT JOIN Dictionary.categoryMarketProposal AS dic_mp
				ON dic_mp.Name = R.category

			LEFT JOIN Dictionary.typeCodeMarketProposal AS dic_t
				--ON dic_t.Наименование = 
				--	iif(isnull(T.vin, '') = '',
				--		'Повторный заём с новым залогом', 
				--		'Повторный заём с известным залогом'
				--	)
				ON dic_t.Код = 
					iif(isnull(R.vin, '') = '',
						'000000003', --Повторный заём с новым залогом', 
						'000000002' --Повторный заём с известным залогом
					)
			LEFT JOIN (
				SELECT 
					Партнер = CRM_КонтактнаяИнформация.Ссылка 
					,stg.dbo.[str_ValidateEmail](АдресЭП) email
					,nRow = Row_Number() over(partition by CRM_КонтактнаяИнформация.Ссылка order by ДатаЗаписи desc
						,НомерСтроки desc)
					from stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация CRM_КонтактнаяИнформация
					where CRM_КонтактнаяИнформация.Актуальный = 0x01
						and CRM_КонтактнаяИнформация.Тип = 0x82E6D573EE35D0904BF4D326A84A91D2
						and nullif(АдресЭП,'') is not null
				) AS CRM_КонтактнаяИнформация_email 
				ON CRM_КонтактнаяИнформация_email.Партнер = CRM_Клиент.Ссылка
				and CRM_КонтактнаяИнформация_email.nRow = 1
				and CRM_КонтактнаяИнформация_email.email is not null

			LEFT JOIN #t_ТранспортноеСредство AS TS
				ON TS.vin = R.vin
		WHERE 1=1
		--	AND R.category NOT IN ('Красный')

		--DWH-2320 Использовать персональные данные из CRM
		--Если таких данных нет, тогда уже использовать данные из родительской таблицы (risk.povt_buffer)
		UPDATE D
		SET doc_ser = replace(A.Серия, ' ', ''),
			doc_num = A.Номер,
			passportNotValid = 0
		FROM (
			SELECT 
				R.Физлицо_Ссылка,
				R.Серия,
				R.Номер,
				--R.ДатаВыдачи
				rn = row_number() OVER(PARTITION BY R.Физлицо_Ссылка ORDER BY R.ДатаВыдачи DESC)
			FROM (
					SELECT DISTINCT T.КлиентСсылка
					FROM #t_povt_pts AS T
				) AS S
				INNER JOIN Stg._1cCRM.РегистрСведений_ДокументыФизическихЛиц AS R
					ON S.КлиентСсылка = R.Физлицо_Ссылка
					AND R.Физлицо_ТипСсылки = 0x0000008B
					AND nullif(trim(R.Серия),'') IS NOT NULL
					AND nullif(trim(R.Номер),'') IS NOT NULL
			) AS A
			INNER JOIN #t_povt_pts AS D
				ON A.Физлицо_Ссылка = D.КлиентСсылка
				AND A.rn = 1
		--// DWH-2320


		--собираем клиентов у которых есть действующий ПЭП
		drop table if exists #tCRMClientGuid_HasPep
		create table #tCRMClientGuid_HasPep(CRMClientGuid nvarchar(36) primary key)
		insert into #tCRMClientGuid_HasPep
		Select distinct CRMClientGuid = [dbo].[getGUIDFrom1C_IDRREF](СогласияНаЭлектронноеВзаимодействие.Клиент)
		from stg.[_1cCRM].[РегистрСведений_СогласияНаЭлектронноеВзаимодействие] СогласияНаЭлектронноеВзаимодействие
		where  1=1
			and nullif(ДатаАннулирования, '2001-01-01 00:00:00') is null
			--и нет отзыва
			and not exists(select top(1) 1 from stg.[_1cCRM].[РегистрСведений_СогласияНаЭлектронноеВзаимодействие] отзыв_СогласияНаЭлектронноеВзаимодействие
			where отзыв_СогласияНаЭлектронноеВзаимодействие.Клиент = СогласияНаЭлектронноеВзаимодействие.Клиент
				and  nullif(ДатаАннулирования, '2001-01-01 00:00:00') is not null
			)
		update t
				set hasPEP = iif(hasPep.CRMClientGuid is not null, 1, 0)
		from #t_povt_pts t
		left join #tCRMClientGuid_HasPep hasPep
			on hasPep.CRMClientGuid = t.CRMClientGuid



		update  t
			set [hasCommissionProducts] = case
					when dm_sales.[КАСКО] >0 then 'КАСКО' --SumKasko
					when dm_sales.[Спокойная Жизнь] >0 then 'СЖ' --SumQuietLife
					when dm_sales.[страхование жизни] >0 then 'НС' --SumEnsur
					end
		from #t_povt_pts t
		inner join Reports.[dbo].[dm_Sales] dm_sales 
			on dm_sales.[Код] = t.external_id

		--Если номер в ЧС (внесен за последние 90 дней)
		DROP TABLE IF EXISTS #t_BlackPhoneList
		
		SELECT DISTINCT B.Phone
		INTO #t_BlackPhoneList
		from Stg._1cCRM.BlackPhoneList AS B
		WHERE B.create_at >= cast(getdate()-90 as date)
			OR B.ReasonAdding_subject = 'Исключение номера телефона (бессрочно)'
		UNION
		SELECT phone
		FROM (
			VALUES ('9099819898') --17.01.2022 Не звонить по этому номеру.
			,('9858845680') --20.06.2024 Не звонить по этому номеру. по согласование с Ю. Белявцевой
		) t(phone)

		--тел в черном списке
		UPDATE t
		SET phoneInBlackList = 1
		FROM #t_povt_pts AS t
		WHERE EXISTS(
				SELECT top(1) 1
				FROM #t_BlackPhoneList AS B
				WHERE B.Phone = t.phone
			)

		--паспорт в списке недествительных
		UPDATE t
		SET passportNotValid = 1
		FROM #t_povt_pts AS t
		WHERE EXISTS(
				SELECT top(1) 1
				FROM Stg._1CIntegration.РегистрСведений_НедействительныеПаспорта AS s
				WHERE s.Серия = t.doc_ser
					AND s.Номер = t.doc_num
			)
			or (doc_ser is null
			or doc_num is null)

		update  #t_povt_pts
			set [lead_Id] = 
				cast(hashbytes('SHA2_256',concat(marketProposal_ID
					, '|'
					, '|', last_name
					, '|', first_name
					, '|', patronymic
					, '|', phone
					)
					) as uniqueidentifier)

		--DWH-2755
		UPDATE M SET row_hash = 
			cast(hashbytes('SHA2_256', 
				concat(
					cast(M.main_limit AS varchar(12)), '|'
					,cast(M.[Ставка %] AS varchar(12)), '|'
					,cast(M.passportNotValid AS varchar(1)), '|'
					,M.last_name, '|'
					,M.first_name, '|'
					,M.patronymic, '|'
					,M.CRMClientGUID, '|'
					,M.RequestGUID, '|'
					,M.phone, '|'
					,M.market_proposal_category_id, '|'
					,M.market_proposal_type_id, '|'
					,M.ТранспортноеСредствоGuid, '|'
					,M.ТранспортноеСредствоНаименование, '|'
					,M.vin, '|'
					,cast(M.ТранспортноеСредствоГод AS varchar(12)), '|'
					,M.РегистрационныйНомер, '|'

					,M.МаркаGuid, '|'
					,M.МаркаПТС, '|'

					,M.МодельGuid, '|'
					,M.МодельПТС, '|'

					,M.СерияПТС, '|'
					,M.НомерПТС, '|'

					,M.lead_Id, '|'
					,M.product_type_id, '|'
			))
			as uniqueidentifier)
		from #t_povt_pts AS M

		BEGIN TRAN
			DELETE D
			FROM marketing.povt_pts AS D
			WHERE D.cdate = cast(getdate() as date)
				AND (D.CRMClientGUID = @CMRClientGUID OR @CMRClientGUID is null)
		
			INSERT marketing.povt_pts
			(
			    marketProposal_ID,
			    cdate,
			    dwh_created_at,
			    RequestСсылка,
			    RequestGUID,
			    external_id,
			    category,
			    Type,
			    main_limit,
			    [Минимальный срок кредитования],
			    [Ставка %],
			    [Сумма платежа],
			    [Рекомендуемая дата повторного обращения],
			    fio,
			    birth_date,
			    vin,
			    channel,
			    doc_ser,
			    doc_num,
			    ТелефонМобильный,
			    region_projivaniya,
			    Berem_pts,
			    Nalichie_pts,
			    num_active_days,
			    market_price,
			    collateral_id,
			    price_date,
			    days,
			    discount_price,
			    limit_car,
			    CRMClientGUID,
			    last_name,
			    first_name,
			    patronymic,
			    market_proposal_category_id,
			    market_proposal_category_name,
			    market_proposal_category_code,
			    market_proposal_type_id,
			    market_proposal_type_name,
			    market_proposal_type_code,
			    phone,
			    client_email,
			    passportNotValid,
			    lkUserId,
			    phoneInBlackList,
			    clientTimeZone,
			    ТранспортноеСредствоGuid,
			    ТранспортноеСредствоНаименование,
			    МаркаGuid,
			    МодельGuid,
			    РегистрационныйНомер,
			    ТранспортноеСредствоГод,
			    МаркаПТС,
			    МодельПТС,
			    СерияПТС,
			    НомерПТС,
				lead_Id,
				[product_type_id],	
				[product_type_name],
				[product_type_code],
				[was_closed_ago],
				hasPEP,
				[hasCommissionProducts],
				lastRate,
				row_hash
			)
			SELECT 
				D.marketProposal_ID,
				D.cdate,
				D.dwh_created_at,
				D.RequestСсылка,
				D.RequestGUID,
				D.external_id,
				D.category,
				D.Type,
				D.main_limit,
				D.[Минимальный срок кредитования],
				D.[Ставка %],
				D.[Сумма платежа],
				D.[Рекомендуемая дата повторного обращения],
				D.fio,
				D.birth_date,
				D.vin,
				D.channel,
				D.doc_ser,
				D.doc_num,
				D.ТелефонМобильный,
				D.region_projivaniya,
				D.Berem_pts,
				D.Nalichie_pts,
				D.num_active_days,
				D.market_price,
				D.collateral_id,
				D.price_date,
				D.days,
				D.discount_price,
				D.limit_car,
				D.CRMClientGUID,
				D.last_name,
				D.first_name,
				D.patronymic,
				D.market_proposal_category_id,
				D.market_proposal_category_name,
				D.market_proposal_category_code,
				D.market_proposal_type_id,
				D.market_proposal_type_name,
				D.market_proposal_type_code,
				D.phone,
				D.client_email,
				D.passportNotValid,
				D.lkUserId,
				D.phoneInBlackList,
				D.clientTimeZone,
				D.ТранспортноеСредствоGuid,
				D.ТранспортноеСредствоНаименование,
				D.МаркаGuid,
				D.МодельGuid,
				D.РегистрационныйНомер,
				D.ТранспортноеСредствоГод,
				D.МаркаПТС,
				D.МодельПТС,
				D.СерияПТС,
				D.НомерПТС,
				lead_Id,
				d.[product_type_id],	
				d.[product_type_name],
				d.[product_type_code],
				[was_closed_ago],
				hasPEP,
				[hasCommissionProducts],
				lastRate,
				row_hash
			FROM #t_povt_pts AS D

		COMMIT TRAN

	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end

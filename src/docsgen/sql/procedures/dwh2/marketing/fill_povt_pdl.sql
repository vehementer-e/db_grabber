CREATE PROC [marketing].[fill_povt_pdl]
	@CMRClientGUID nvarchar(36) = null
as
begin
	begin try
		if not exists(select top(1) 1 from risk.povt_pdl_buffer)
		begin 
			;throw 51000, 'Отсутвутют данные в risk.povt_pdl_buffer', 16
		end
		drop table if exists #t_povt_pdl
		--Если номер в ЧС (внесен за последние 90 дней)
		drop table if exists #BlackPhoneList
		
		select distinct 
			phone 
		into #BlackPhoneList
		from stg._1cCRM.BlackPhoneList
		where create_at>=cast(getdate()-90 as date) or ReasonAdding_subject='Исключение номера телефона (бессрочно)'
		union 
		select phone
			from (values 
			('9099819898')--17.01.2022 Не звонить по этому номеру.
			,('9858845680') --20.06.2024 Не звонить по этому номеру. по согласование с Ю. Белявцевой
		) t(phone)

		drop table if exists #has_marketing_docked_povt
		create table #has_marketing_docked_povt(CMRClientGUID varchar(36))
		insert into #has_marketing_docked_povt(CMRClientGUID)
		select distinct CRMClientGUID from risk.docredy_buffer
		where category not in('Красный')
		union
		select distinct CRMClientGUID from risk.povt_buffer
		where category not in('Красный')

		drop table if exists #has_inst_market_proposal
		create table #has_inst_market_proposal (CMRClientGUID varchar(36))
		insert into #has_inst_market_proposal
		select distinct CMRClientGUID  
		from [risk].povt_inst_buffer
		where category not in('Красный')



		select top(0) 
			[external_id], 
			КлиентСсылка = cast(NULL AS binary(16)),
			[CMRClientGUID], 
			[last_name], 
			[first_name], 
			[patronymic], 
			[birth_date], 
			[passport_series], 
			[passport_number], 
			[market_proposal_category_id],
			[market_proposal_category_name],
			[market_proposal_category_code], 
			[market_proposal_type_id],		
			[market_proposal_type_name],		
			[market_proposal_type_code],		
			approved_limit,
			[phone], 
			client_email,
			[passportNotValid], 
			lkUserId,
			phoneInBlackList,
			FIO,
			clientTimeZone,
			[naumenPriority],
			[cdate],
			[has_pts_market_proposal],
			[days_after_close],
			[factenddate],
			has_inst_market_proposal,
			marketProposal_ID,
			[product_type_id],
			[product_type_name],
			[product_type_code],
			[lead_Id],
			row_hash
		into #t_povt_pdl
		from marketing.povt_pdl

		create clustered index cix on #t_povt_pdl(CMRClientGUID)
		insert into #t_povt_pdl
		(
			[external_id], 
			КлиентСсылка,
			[CMRClientGUID], 
			[last_name], 
			[first_name], 
			[patronymic], 
			[birth_date], 
			[passport_series], 
			[passport_number], 
			[market_proposal_category_id],
			[market_proposal_category_name],
			[market_proposal_category_code], 
			[market_proposal_type_id],		
			[market_proposal_type_name],		
			[market_proposal_type_code],
			approved_limit,
			[phone], 
			client_email,
			[passportNotValid],
			lkUserId,
			phoneInBlackList,
			FIO,
			clientTimeZone,
			[naumenPriority],
			[cdate],
			[has_pts_market_proposal],
			[days_after_close],
			[factenddate],
			has_inst_market_proposal,
			marketProposal_ID,
			[product_type_id],
			[product_type_name],
			[product_type_code]
			
		)
		select distinct 
			[external_id], 
			КлиентСсылка = CRM_Клиент.Ссылка,
			[CMRClientGUID], 
			[last_name]		= TRIM(t.[last_name]), 
			[first_name]	= TRIM(t.[first_name]), 
			[patronymic]	= TRIM(t.[patronymic]), 
			[birth_date]	= t.birth_date, 
			[passport_series] = nullif(TRIM(t.[passport_series]),''), 
			[passport_number] = nullif(TRIM(t.[passport_number]),''), 
			[market_proposal_category_id]	= isnull(dic_mp.Id, cast(null as uniqueidentifier )),
			[market_proposal_category_name] = dic_mp.Name,
			[market_proposal_category_code] = dic_mp.CodeName,
			[market_proposal_type_id]		= isnull(dic_t.Id, cast(null as uniqueidentifier )), 
			[market_proposal_type_name]		= dic_t.Наименование, 
			[market_proposal_type_code]		= dic_t.Код,
			approved_limit = approved_limit,
			[phone] = coalesce(
			nullif(nullif(trim(CRM_КонтактнаяИнформация.НомерТелефонаБезКодов), ''),'0')
				, nullif(nullif(trim(CMR_Клиент.Телефон), ''),  '0')
				), 
			client_email = CRM_КонтактнаяИнформация_email.email,
			[passportNotValid] = 
			iif(nullif(TRIM(t.[passport_series]),'') is null
				or nullif(TRIM(t.[passport_number]),'') is null
				,1, 0), 
			lkUserId = cr.LKUserId,
			phoneInBlackList = 0,
			FIO = concat(TRIM(t.[last_name]), ' ', TRIM(t.[first_name]), ' ',  TRIM(t.[patronymic])),
			clientTimeZone  = br.CRM_ВремяПоГринвичу_GMT,
			[naumenPriority] =cast(approved_limit/1000 as int),
			[cdate]  = getdate(),
			[has_pts_market_proposal] = 0,
			[days_after_close],
			[factenddate],
			has_inst_market_proposal = 0,
			marketProposal_ID = cast(hashbytes('SHA2_256',concat(t.[CMRClientGUID], '|',pt.Id)) as uniqueidentifier),
			[product_type_id]		= isnull(pt.Id, cast(null as uniqueidentifier )), 
			[product_type_name]		= pt.Name, 
			[product_type_code]		= pt.CodeName
		from [risk].[povt_pdl_buffer] t
		INNER JOIN stg._1cCMR.Справочник_Клиенты CMR_Клиент 
			ON [dbo].[getGUIDFrom1C_IDRREF](CMR_Клиент.Ссылка) = t.[CMRClientGUID]
			
		inner join stg.dbo.v_1cMDS_ProductType  pt 
			on 1=1 
			and UPPER(pt.Name)  = 'PDL'
		LEFT JOIN  dbo.ClientReferences cr  
			on cr.CMRContractNumber=t.external_id
		LEFT JOIN Stg._1cCRM.Справочник_Партнеры CRM_Клиент 
			ON CRM_Клиент.Ссылка = CMR_Клиент.Ссылка
		left join (
		select 
			Партнер = CRM_КонтактнаяИнформация.Ссылка 
			,НомерТелефонаБезКодов
			,nRow = Row_Number() over(partition by CRM_КонтактнаяИнформация.Ссылка order by ДатаЗаписи desc
				,НомерСтроки desc)
		from stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация CRM_КонтактнаяИнформация
				where CRM_КонтактнаяИнформация.CRM_ОсновнойДляСвязи  =0x01
				and CRM_КонтактнаяИнформация.Актуальный = 0x01
					and CRM_КонтактнаяИнформация.Тип = 0xA873CB4AD71D17B2459F9A70D4E2DA66
					) CRM_КонтактнаяИнформация on CRM_КонтактнаяИнформация.Партнер=CRM_Клиент.Ссылка
				and CRM_КонтактнаяИнформация.nRow = 1
		left join stg._1cCRM.[Справочник_БизнесРегионы] br      
			on br.Ссылка = CRM_Клиент.РегионФактическогоПроживания	
		left join  [Dictionary].categoryMarketProposal dic_mp on
			dic_mp.Name = case   --если клиент не задат и категория Розовый значт Красный --DWH-2580
				when  @CMRClientGUID is not null  and t.category = 'Розовый' then 'Зеленый'
				when  @CMRClientGUID is null  and t.category = 'Розовый' then 'Красный'
				else t.category end
			--dic_mp.Name = case t.category
			--	when 'Розовый' then 'Зеленый'
			--	else t.category end
		left join [Dictionary].[typeCodeMarketProposal] dic_t on 
			dic_t.Наименование = 'Повторный заём PDL'
		
		left join (select 
			Партнер = CRM_КонтактнаяИнформация.Ссылка 
			,stg.dbo.[str_ValidateEmail](АдресЭП) email
			,nRow = Row_Number() over(partition by CRM_КонтактнаяИнформация.Ссылка order by ДатаЗаписи desc
				,НомерСтроки desc)
			from stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация CRM_КонтактнаяИнформация
			where CRM_КонтактнаяИнформация.Актуальный = 0x01
			and CRM_КонтактнаяИнформация.Тип = 0x82E6D573EE35D0904BF4D326A84A91D2
			and nullif(АдресЭП,'') is not null
		) CRM_КонтактнаяИнформация_email on 
			CRM_КонтактнаяИнформация_email.Партнер =  CRM_Клиент.Ссылка
			and CRM_КонтактнаяИнформация_email.nRow = 1
			and CRM_КонтактнаяИнформация_email.email is not null
		where (t.CMRClientGUID =  @CMRClientGUID or  @CMRClientGUID  is null)
		/*
		(lower(t.category) in ('зеленый','красный') and @CMRClientGUID is null
			)
			--либо определенный клиент и то у которого есть Розовое предложение - 3258
			or  ( t.CMRClientGUID =  @CMRClientGUID
					and lower(t.category) = ('розовый')
				)
				*/
		--DWH-2320 Использовать персональные данные из CRM
		--Если таких данных нет, тогда уже использовать данные из родительской таблицы (risk.povt_pdl_buffer)
		UPDATE D
		SET passport_series = nullif(replace(A.Серия, ' ', ''),''), 
			passport_number = nullif(replace(A.Номер, ' ', ''),''),
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
					FROM #t_povt_pdl AS T
				) AS S
				INNER JOIN Stg._1cCRM.РегистрСведений_ДокументыФизическихЛиц AS R
					ON S.КлиентСсылка = R.Физлицо_Ссылка
					AND R.Физлицо_ТипСсылки = 0x0000008B
					AND nullif(trim(R.Серия),'') IS NOT NULL
					AND nullif(trim(R.Номер),'') IS NOT NULL
			) AS A
			INNER JOIN #t_povt_pdl AS D
				ON A.Физлицо_Ссылка = D.КлиентСсылка
				AND A.rn = 1
		--// DWH-2320
		
		--тел в черном списке
		update t
			set phoneInBlackList = 1
		from #t_povt_pdl t
		where exists(select top(1) 1 from #BlackPhoneList BlackPhoneList where
			BlackPhoneList.Phone = t.[phone]
			)

		--паспорт в списке недествительных
		update t
			set [passportNotValid] = 1
		from #t_povt_pdl t
		where exists(select top(1) 1 from stg._1CIntegration.РегистрСведений_НедействительныеПаспорта s
		where s.Серия = t.[passport_series]
			and s.Номер = t.[passport_number])
			or ([passport_series] is null
			or [passport_number] is null)
		--
		update t
			set [has_pts_market_proposal] = 1
		from #t_povt_pdl t
			where exists(select top(1) 1 from #has_marketing_docked_povt s
			where s.CMRClientGUID = t.CMRClientGUID)
	
		update t
			set has_inst_market_proposal = 1
		from #t_povt_pdl t
				where exists(select top(1) 1 from #has_inst_market_proposal s
			where s.CMRClientGUID = t.CMRClientGUID)
	
		update  #t_povt_pdl
			set [lead_Id] = 
				cast(hashbytes('SHA2_256',concat(marketProposal_ID
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
					cast(M.approved_limit AS varchar(12)), '|'
					,cast(M.passportNotValid AS varchar(1)), '|'
					,M.last_name, '|'
					,M.first_name, '|'
					,M.patronymic, '|'
					,M.CMRClientGUID, '|'
			
					,M.phone, '|'
					,M.market_proposal_category_id, '|'
					,M.market_proposal_type_id, '|'
			
					,M.lead_Id, '|'
					,M.product_type_id, '|'
				))
			as uniqueidentifier)
		from #t_povt_pdl AS M

	begin tran
		delete from [marketing].[povt_pdl]
			where cdate = cast(getdate() as date)
			and (CMRClientGUID =  @CMRClientGUID or @CMRClientGUID is null)
		insert into [marketing].[povt_pdl]
		(
			[external_id], 
			[CMRClientGUID], 
			[last_name], 
			[first_name], 
			[patronymic], 
			[birth_date], 
			[passport_series], 
			[passport_number], 
			[market_proposal_category_id],
			[market_proposal_category_code], 
			[market_proposal_category_name],
			[market_proposal_type_id],
			[market_proposal_type_name], 
			[market_proposal_type_code], 
			[phone], 
			client_email,
			[passportNotValid], 
			[cdate], 
			approved_limit,
			lkUserId,
			phoneInBlackList,
			FIO,
			clientTimeZone,
			[naumenPriority],
			[has_pts_market_proposal],
			[days_after_close],
			[factenddate],
			has_inst_market_proposal,
			marketProposal_ID,
			[product_type_id],
			[product_type_name],
			[product_type_code],
			[lead_Id],
			row_hash
		)
		select 
			[external_id], 
			[CMRClientGUID], 
			[last_name], 
			[first_name], 
			[patronymic], 
			[birth_date], 
			[passport_series], 
			[passport_number], 
			[market_proposal_category_id],
			[market_proposal_category_code], 
			[market_proposal_category_name],
			[market_proposal_type_id],
			[market_proposal_type_name], 
			[market_proposal_type_code], 
			[phone], 
			client_email,
			[passportNotValid], 
			[cdate], 
			approved_limit,
			lkUserId,
			phoneInBlackList,
			FIO,
			clientTimeZone,
			[naumenPriority],
			[has_pts_market_proposal],
			[days_after_close],
			[factenddate],
			has_inst_market_proposal,
			marketProposal_ID,
			[product_type_id],
			[product_type_name],
			[product_type_code],
			[lead_Id],
			row_hash
		from #t_povt_pdl
	commit tran
	

	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end

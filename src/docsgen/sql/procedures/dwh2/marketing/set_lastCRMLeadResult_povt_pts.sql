
CREATE     procedure [marketing].[set_lastCRMLeadResult_povt_pts]
	@lastDay smallint = 360
as
begin

--Сбор данных по результатам звонков по маркетинговым предложениям повторники инстолмент
begin try
	declare @dateStartProject date ='2023-05-31' --дата старта проекта
	declare @projectIds table (project_id nvarchar(255))
			insert into @projectIds (project_id)
			select  project_id
			from (values
				('corebo00000000000mm1tts6og6rs2fk') --CRM Повторные			-- old
				,('corebo00000000000n25qgnvfnogtjf8') --Докреды 			-- old
				,('corebo00000000000n25qereimll7884') --CRM Докреды Перезвоны		-- old
				,('corebo00000000000mn2eg74l4nb9950') --CRM Повторные - Перезвоны	-- old
				
				,('corebo00000000000palme673n6njdhs') --CRM Повторные			-- old
				,('corebo00000000000pallp7sskqdpifo') --Докреды 			-- old
				,('corebo00000000000pallps4t1qi8prs') --CRM Докреды Перезвоны		-- old
				,('corebo00000000000palmf0r7gh7c2m8') --CRM Повторные - Перезвоны	-- old
			

				) t(project_id)
		drop table if exists #povt_ptsClientPhone
		create table  #povt_ptsClientPhone (client_number nvarchar(10) primary key)
		insert into #povt_ptsClientPhone
		select client_number = right(phone,10)
		from marketing.povt_pts t
		where t.phone is not null
		group by 	   right(phone,10)

	drop table if exists #tCRMResult
	;with cte_ТелефонныйЗвонок as (
	select  
		Session_id		= outbound_sessions.Session_id,
		case_uuid		= outbound_sessions.case_uuid,
		client_number	= right(outbound_sessions.client_number,10), 
				--when substring(outbound_sessions.client_number, 1, 1) = '8'  
				--	then substring(outbound_sessions.client_number, 2, len(outbound_sessions.client_number))
				--else outbound_sessions.client_number end,
		project_id		= outbound_sessions.project_id,
		attempt_start	= outbound_sessions.attempt_start,
		ЗаявкаНаЗаймПодПТС_Ссылка = 
		case 
			when Документ_CRM_Взаимодействие.Заявка_ТипСсылки = 0x000022C4
				then Документ_CRM_Взаимодействие.Заявка_Ссылка
		end,
		CRM_Заявка_Ссылка  = case 
			when Документ_CRM_Взаимодействие.Заявка_ТипСсылки = 0x000021F5 --Документ.ЗаявкаНаЗаймПодПТС
				then Документ_CRM_Взаимодействие.Заявка_Ссылка
		end
		,CRM_Взаимодействие_Комментарий = Документ_CRM_Взаимодействие.Комментарий
	
	from #povt_ptsClientPhone cp
		inner join reports.[dbo].[dm_report_DIP_detail_outbound_sessions] 
			outbound_sessions on right(outbound_sessions.client_number,10) = cp.client_number
		inner join stg.[_1cCRM].Документ_ТелефонныйЗвонок as ТелефонныйЗвонок
			on outbound_sessions.session_id  =  ТелефонныйЗвонок.Session_id
			and ТелефонныйЗвонок.ВзаимодействиеОснование_ТипСсылки = 0x000000BB
		inner JOIN stg.[_1cCRM].Документ_CRM_Взаимодействие Документ_CRM_Взаимодействие
			ON ТелефонныйЗвонок.ВзаимодействиеОснование_Ссылка = Документ_CRM_Взаимодействие.Ссылка
			
	where cast(outbound_sessions.attempt_start as date)>=dateadd(dd,-@lastDay, getdate())
	
		and 	exists(select top(1) 1 from @projectIds  t1 
						where t1.project_id = outbound_sessions.project_id)
	and speaking_time >0


	)

	select 
		Session_id,
		case_uuid,
		client_number,
		project_id,
		attempt_start,
		CRMЗаявка_Guid = [dbo].[getGUIDFrom1C_IDRREF](CRM_Заявка.Ссылка),
		CRMЗаявка_Дата = IIF(YEAR(CRM_Заявка.Дата)>3000, dateadd(year,-2000,CRM_Заявка.Дата), CRM_Заявка.Дата),
		CRMЗаявка_Номер =  CRM_Заявка.Номер,
		CRMЗаявка_СтатусНаименование = CRM_СостоянияЛидов.Наименование,
		CRMЗаявка_ПричиныОтказовНаименование = CRM_ПричиныОтказов.Наименование,
		CRMЗаявка = CRM_Заявка.Ссылка
	into #tCRMResult
	 from  cte_ТелефонныйЗвонок ТелефонныйЗвонок
	 INNER join stg._1cCRM.Документ_CRM_Заявка CRM_Заявка 	on 
		CRM_Заявка.Ссылка = ТелефонныйЗвонок.CRM_Заявка_Ссылка
	 left join stg._1cCRM.Справочник_CRM_СостоянияЛидов CRM_СостоянияЛидов on  
		CRM_СостоянияЛидов.Ссылка = CRM_Заявка.Статус
	 left join stg._1cCRM.Справочник_CRM_ПричиныОтказов CRM_ПричиныОтказов on 
		CRM_ПричиныОтказов.Ссылка = CRM_Заявка.ПричинаОтказа


		/*
	drop table if exists #tCrmЗаявкаНаЗаймПодПТС
	select 
		 ЗаявкаНаЗаймПодПТС_Guid				= [dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка)
		,ЗаявкаНаЗаймПодПТС_Номер				= ЗаявкаНаЗаймПодПТС.Номер
		,ЗаявкаНаЗаймПодПТС_Дата				= iif(year(ЗаявкаНаЗаймПодПТС.Дата)>3000, dateadd(year,-2000, ЗаявкаНаЗаймПодПТС.Дата), ЗаявкаНаЗаймПодПТС.Дата)
		,ЗаявкаНаЗаймПодПТС_ЛидGuid				= [dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Лид)
		,ЗаявкаНаЗаймПодПТС_МобильныйТелефон	= ЗаявкаНаЗаймПодПТС.МобильныйТелефон
		,СтатусыЗаявки_Наименование				= СтатусыЗаявки.Наименование
		,СтатусыЗаявки_Код						= СтатусыЗаявки.КодСтатуса
	into #tCrmЗаявкаНаЗаймПодПТС
	from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС ЗаявкаНаЗаймПодПТС
	left join stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС СтатусыЗаявки
		on СтатусыЗаявки.Ссылка = ЗаявкаНаЗаймПодПТС.Статус
	WHERE ЗаявкаНаЗаймПодПТС.Инстолмент = 0x01
	and exists(select top(1) 1 from #tCRMResult CRMResult 
		where cast(CRMResult.CRMЗаявка_Дата as date) = cast(iif(year(ЗаявкаНаЗаймПодПТС.Дата)>3000, dateadd(year,-2000, ЗаявкаНаЗаймПодПТС.Дата), ЗаявкаНаЗаймПодПТС.Дата) as date)
			and CRMResult.client_number = ЗаявкаНаЗаймПодПТС.МобильныйТелефон
			
			)

	drop table if exists #tLastЗаявкаНаЗаймПодПТС
	
	select 
		 t.ЗаявкаНаЗаймПодПТС_Guid				
		,t.ЗаявкаНаЗаймПодПТС_Номер				
		,t.ЗаявкаНаЗаймПодПТС_Дата				
		,t.ЗаявкаНаЗаймПодПТС_ЛидGuid					
		,t.ЗаявкаНаЗаймПодПТС_МобильныйТелефон	
		,ЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование = t.СтатусыЗаявки_Наименование				
		,ЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод = t.СтатусыЗаявки_Код						
	into #tLastЗаявкаНаЗаймПодПТС
	from  #tCrmЗаявкаНаЗаймПодПТС t
	inner join(
		select ЗаявкаНаЗаймПодПТС_МобильныйТелефон 
		,last_ЗаявкаНаЗаймПодПТС_Дата = max(ЗаявкаНаЗаймПодПТС_Дата)
		from #tCrmЗаявкаНаЗаймПодПТС
		group by ЗаявкаНаЗаймПодПТС_МобильныйТелефон
	) last_ЗаявкаНаЗаймПодПТС on 
		last_ЗаявкаНаЗаймПодПТС.ЗаявкаНаЗаймПодПТС_МобильныйТелефон = t.ЗаявкаНаЗаймПодПТС_МобильныйТелефон
		and last_ЗаявкаНаЗаймПодПТС.last_ЗаявкаНаЗаймПодПТС_Дата = t.ЗаявкаНаЗаймПодПТС_Дата
		*/
	drop table if exists #tLastCRMResult
	select 
		t.client_number,
		t.CRMЗаявка_Дата,
		t.CRMЗаявка_Guid,
		t.CRMЗаявка_Номер,
		t.CRMЗаявка_СтатусНаименование,
		t.CRMЗаявка_ПричиныОтказовНаименование,
		t.Session_id,
		t.case_uuid,
		t.project_id,
		t_last.totalIsCustomerRejection
		into #tLastCRMResult
	from #tCRMResult t
	inner join (
		select 
			client_number,
			last_CRMЗаявка_Дата = max(CRMЗаявка_Дата)
			,totalIsCustomerRejection = sum(iif(
				t.CRMЗаявка_СтатусНаименование in ('Отказ клиента'
					, 'Клиент передумал'), 1, 0))
		from #tCRMResult t
		group by client_number
	) t_last on t_last.client_number = t.client_number
		and t_last.last_CRMЗаявка_Дата = t.CRMЗаявка_Дата


		
	begin tran
		update pov
			set 
				lastCRMЗаявка_Guid							= crmresult.CRMЗаявка_Guid
				,lastCRMЗаявка_Номер						= crmresult.CRMЗаявка_Номер
				,lastCRMЗаявка_Дата							= crmresult.CRMЗаявка_Дата
				,lastCRMЗаявка_СтатусНаименование			= crmresult.CRMЗаявка_СтатусНаименование
				,lastCRMЗаявка_ПричиныОтказовНаименование	= crmresult.CRMЗаявка_ПричиныОтказовНаименование
				,totalIsCustomerRejection					= coalesce(crmresult.totalIsCustomerRejection, last_data.totalIsCustomerRejection, 0)
		from [marketing].[povt_pts] pov
		left join #tLastCRMResult crmresult
			on crmresult.client_number = pov.[phone]

		left join(
			select 
				t.phone
				,t.totalIsCustomerRejection 
				from (select phone, last_cdate = max(cdate)
			from marketing.[povt_pts]
			where cdate<cast(getdate() as date)
			group by phone) last_data
				inner join marketing.[povt_pts] t 
					on t.cdate = last_data.last_cdate
					and t.phone = last_data.phone
		) last_data on last_data.phone = pov.phone

		where pov.cdate =cast(getdate() as date)
	commit tran
	/*
	begin tran
		update t
			set  lastЗаявкаНаЗаймПодПТС_Guid						= crmresult.ЗаявкаНаЗаймПодПТС_Guid
				,lastЗаявкаНаЗаймПодПТС_Номер						= crmresult.ЗаявкаНаЗаймПодПТС_Номер
				,lastЗаявкаНаЗаймПодПТС_Дата						= crmresult.ЗаявкаНаЗаймПодПТС_Дата
				,lastЗаявкаНаЗаймПодПТС_Лид							= crmresult.ЗаявкаНаЗаймПодПТС_ЛидGuid	
				,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование	= crmresult.ЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
				,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод			= crmresult.ЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод
		from [marketing].[povt_pts] t
		left join #tLastЗаявкаНаЗаймПодПТС crmresult
			on crmresult.ЗаявкаНаЗаймПодПТС_МобильныйТелефон = t.[phone]
		where t.cdate =cast(getdate() as date)
	commit tran
	*/



end try
begin catch
	if @@TRANCOUNT>0
		ROLLBACK TRAN
	;throw
end catch
end

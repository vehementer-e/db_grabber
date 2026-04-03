

CREATE   procedure [marketing].[set_lastCRMLeadResult_povt_pdl]
as
begin
declare @lastDay tinyint = 30
--Сбор данных по результатам звонков по		маркетинговым предложениям повторники инстолмент
begin try
	declare @dateStartProject date ='2023-11-13' --дата старта проекта
	declare @projectIds table (project_id nvarchar(255))
			insert into @projectIds (project_id)
			select  project_id
			from (values
				('corebo00000000000oe3p1ashjvi3rho')--код проекта по повторникам инстолмент
				,('corebo00000000000oe3p4rec7ip91ks')--Перезвоны по повторникам
				) t(project_id)
		drop table if exists #povInstClientPhone
		create table  #povInstClientPhone (client_number nvarchar(20))
		insert into #povInstClientPhone
		select client_number = right(t.Phone,10)
		from marketing.povt_inst t
		where t.phone is not null
		group by 	    right(t.Phone,10)
		create clustered index cix on #povInstClientPhone(client_number)

	drop table if exists #tCRMResult
	;with cte_ТелефонныйЗвонок as (
	select  
		Session_id		= outbound_sessions.Session_id,
		case_uuid		= outbound_sessions.case_uuid,
		client_number	=  right(outbound_sessions.client_number,10),
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
	from #povInstClientPhone cp
		inner join reports.[dbo].[dm_report_DIP_detail_outbound_sessions] 
			outbound_sessions on right(outbound_sessions.client_number,10) = cp.client_number
		inner join stg.[_1cCRM].Документ_ТелефонныйЗвонок as ТелефонныйЗвонок
			on outbound_sessions.session_id  =  ТелефонныйЗвонок.Session_id
		
		inner JOIN stg.[_1cCRM].Документ_CRM_Взаимодействие Документ_CRM_Взаимодействие
			ON ТелефонныйЗвонок.ВзаимодействиеОснование_Ссылка = Документ_CRM_Взаимодействие.Ссылка
			and ТелефонныйЗвонок.ВзаимодействиеОснование_ТипСсылки = 0x000000BB
	where cast(outbound_sessions.attempt_start as date)>=dateadd(dd,-@lastDay, getdate())
	and cast(outbound_sessions.attempt_start as date)>=@dateStartProject
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



	drop table if exists #tCrmЗаявкаНаЗаймПодПТС
	select 
		 ЗаявкаНаЗаймПодПТС_Guid				= [dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка)
		,ЗаявкаНаЗаймПодПТС_Номер				= ЗаявкаНаЗаймПодПТС.Номер
		,ЗаявкаНаЗаймПодПТС_Дата				= iif(year(ЗаявкаНаЗаймПодПТС.Дата)>3000, dateadd(year,-2000, ЗаявкаНаЗаймПодПТС.Дата), ЗаявкаНаЗаймПодПТС.Дата)
		,ЗаявкаНаЗаймПодПТС_ЛидGuid				= [dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Лид)
		,ЗаявкаНаЗаймПодПТС_МобильныйТелефон	= right(ЗаявкаНаЗаймПодПТС.МобильныйТелефон,10)
		,СтатусыЗаявки_Наименование				= СтатусыЗаявки.Наименование
		,СтатусыЗаявки_Код						= СтатусыЗаявки.КодСтатуса
	into #tCrmЗаявкаНаЗаймПодПТС
	from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС ЗаявкаНаЗаймПодПТС
	left join stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС СтатусыЗаявки
		on СтатусыЗаявки.Ссылка = ЗаявкаНаЗаймПодПТС.Статус
	WHERE ЗаявкаНаЗаймПодПТС.Инстолмент = 0x01
	and exists(select top(1) 1 from #tCRMResult CRMResult 
		where cast(CRMResult.CRMЗаявка_Дата as date) = cast(iif(year(ЗаявкаНаЗаймПодПТС.Дата)>3000, dateadd(year,-2000, ЗаявкаНаЗаймПодПТС.Дата), ЗаявкаНаЗаймПодПТС.Дата) as date)
			and CRMResult.client_number = right(ЗаявкаНаЗаймПодПТС.МобильныйТелефон,10)
			
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
		t.project_id
		into #tLastCRMResult
	from #tCRMResult t
	inner join (
		select 
			client_number,
			last_CRMЗаявка_Дата = max(CRMЗаявка_Дата)
		from #tCRMResult
		group by client_number
	) t_last on t_last.client_number = t.client_number
		and t_last.last_CRMЗаявка_Дата = t.CRMЗаявка_Дата


		
	begin tran
		update pov
			set 
				lastCRMЗаявка_Guid  = crmresult.CRMЗаявка_Guid
				,lastCRMЗаявка_Номер =  crmresult.CRMЗаявка_Номер
				,lastCRMЗаявка_Дата =  crmresult.CRMЗаявка_Дата
				,lastCRMЗаявка_СтатусНаименование =  crmresult.CRMЗаявка_СтатусНаименование
				,lastCRMЗаявка_ПричиныОтказовНаименование =  crmresult.CRMЗаявка_ПричиныОтказовНаименование
		from [marketing].[povt_pdl] pov
		left join #tLastCRMResult crmresult
			on crmresult.client_number = pov.[phone]
		where pov.cdate =cast(getdate() as date)
	commit tran
	begin tran
		update pov
			set lastЗаявкаНаЗаймПодПТС_Guid							= crmresult.ЗаявкаНаЗаймПодПТС_Guid
				,lastЗаявкаНаЗаймПодПТС_Номер						= crmresult.ЗаявкаНаЗаймПодПТС_Номер
				,lastЗаявкаНаЗаймПодПТС_Дата						= crmresult.ЗаявкаНаЗаймПодПТС_Дата
				,lastЗаявкаНаЗаймПодПТС_Лид							= crmresult.ЗаявкаНаЗаймПодПТС_ЛидGuid	
				,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование	= crmresult.ЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
				,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод			= crmresult.ЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод
		from [marketing].[povt_pdl] pov
		left join #tLastЗаявкаНаЗаймПодПТС crmresult
			on crmresult.ЗаявкаНаЗаймПодПТС_МобильныйТелефон = pov.[phone]
		where pov.cdate =cast(getdate() as date)
	commit tran


end try
begin catch
	if @@TRANCOUNT>0
		ROLLBACK TRAN
	;throw
end catch
end

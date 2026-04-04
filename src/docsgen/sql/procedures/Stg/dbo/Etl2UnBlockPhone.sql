--Создание списка телефонов которые нельзя блокировать для черного списка
/*BP-831*/	
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[Etl2UnBlockPhone];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE procedure [dbo].[Etl2UnBlockPhone]
as
begin
	declare @t_channel table ( channel nvarchar(255) )
	insert into @t_channel
	select *
	from (
	values ( 'CPA целевой' )
	,      ( 'CPC'         )
	,      ( 'Органика'    )
	) t(channel)
	declare @t_RequestStatus table ( RequestStatus nvarchar(255) )
	insert into @t_RequestStatus
	select *
	from (
	values ( 'P2P'                                     )
	,      ( 'Верификация документов'                  )
	,      ( 'Верификация документов клиента'          )
	,      ( 'Верификация КЦ'                          )
	,      ( 'Встреча назначена'                       )
	,      ( 'Встреча назначена с ВМ'                  )
	,      ( 'Выполнение контроля данных'              )
	,      ( 'Действует'                               )
	,      ( 'Договор зарегистрирован'                 )
	,      ( 'Договор подписан'                        )
	,      ( 'Заем выдан'                              )
	,      ( 'Запрошена помощь'                        )
	,      ( 'Клиент зарегистрировался в МП'           )
	,      ( 'Клиент прикрепляет фото в МП'            )
	,      ( 'Контроль авторизации'                    )
	,      ( 'Контроль верификации документов'         )
	,      ( 'Контроль верификация документов клиента' )
	,      ( 'Контроль данных'                         )
	,      ( 'Контроль заполнения ЛКК'                 )
	,      ( 'Контроль одобрения документов клиента'   )
	,      ( 'Контроль подписания договора'            )
	,      ( 'Контроль получения ДС'                   )
	,      ( 'Контроль ПЭП'                            )
	,      ( 'Контроль фото ЛКК'                       )
	,      ( 'н/в Клиент зарегистрировался в МП'       )
	,      ( 'н/в Клиент прикрепляет фото в МП'        )
	,      ( 'Назначение встречи'                      )
	,      ( 'Назначение встречи c ВМ'                 )
	,      ( 'Одобрено'                                )
	,      ( 'Одобрены документы клиента'              )
	,      ( 'Ожидание контроля данных'                )
	,      ( 'Оценка качества'                         )
	,      ( 'Платеж опаздывает'                       )
	,      ( 'Предварительная'                         )
	,      ( 'Предварительное одобрение'               )
	,      ( 'Проблемный'                              )
	,      ( 'Проверка ПЭП и ПТС'                      )
	,      ( 'Просрочен'                               )
	,      ( 'Регистрация договора'                    )
	,      ( 'Черновик'                                )
	,      ( 'Черновик из ЛК'                          )
	) t(RequestStatus)
	drop table if exists #t_LEAD_PHONE
	
	select PhoneNumber = cast(TRIM(UF_PHONE) as nvarchar(255))  
	,      CreateAt =cast( max(UF_REGISTERED_AT) as datetime)
	into #t_LEAD_PHONE
	from _LCRM.lcrm_leads_full_channel_request  lcrm
	where exists(select top(1) 1 from @t_channel c where c.channel = lcrm.UF_LOGINOM_CHANNEL
	)
	and UF_REGISTERED_AT >=dateadd(dd,-1,getdate())
	group by cast(TRIM(UF_PHONE) as nvarchar(255))
	
	--	--убрали условие в рамках задачи BP-1531


	;with last_period
	as
	(
		SELECT sd.Договор  deal
		,      max(Период) mp
		FROM [_1cCMR].[РегистрСведений_СтатусыДоговоров] sd with(nolock)
		group by sd.Договор
	)
	select distinct d.Код                                     
	,               ТелефонМобильный= TRIM(d.ТелефонМобильный)
	,               СтатусДоговоров= st.Наименование          
	,               CreateAt = dateadd(year,-2000, d.Дата)    
		into #cmr_contract
	FROM [_1cCMR].[РегистрСведений_СтатусыДоговоров] sd with(nolock)
	join last_period                                       lp with(nolock) on lp.deal = sd.Договор
			and lp.mp = sd.Период
	join [_1cCMR].[Справочник_Договоры]              d with(nolock)  on d.Ссылка = sd.Договор
	join [_1cCMR].[Справочник_СтатусыДоговоров]      st with(nolock) on st.Ссылка = sd.Статус
	where st.Наименование not in ('Погашен','Продан', 'Аннулирован')
		and nullif(ТелефонМобильный, '') is not null
		
	select distinct НомерЗаявки = Номер                        
	,               МобильныйТелефон = TRIM(МобильныйТелефон)  
	,               СтатусыЗаявки = статус.Наименование        
	,               CreateAt = dateadd(year,-2000, заявка.Дата)
		into #crm_Requests
	from       _1cCRM.Документ_ЗаявкаНаЗаймПодПТС         заявка with(nolock)
	inner join _1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС статус with(nolock) on заявка.Статус = статус.Ссылка
	--Статусы заявок по которым можно звонить если тел. в черном списке
	where exists(select top(1) 1
		from @t_RequestStatus
		where RequestStatus = статус.Наименование)
		and nullif(МобильныйТелефон, '') is not null

	;with cte_last_crm_request
	as
	(
		select number                        
		,      publishTime = max(publishTime)
		from [_1cCRM].RMQ_CRM_Requests with(nolock)
		group by number
	)
	,     cte_rmq_crm_request
	as
	(
		select distinct crm.number                     
		,               mobilePhone = TRIM(mobilePhone)
		,               LastStatus= crm.[description]  
		,               CreateAt = crm.daterequest     
		from       cte_last_crm_request      LAST_datestuatusrequest
		inner join [_1cCRM].RMQ_CRM_Requests crm with(nolock)        ON crm.number = LAST_datestuatusrequest.number
				and crm.publishTime = LAST_datestuatusrequest.publishTime
		where crm.ReceiveDate > =dateadd(dd,-10, getdate())
			--Проверяем последний статус
			and exists(Select top(1) 1
			from @t_RequestStatus t
			where t.RequestStatus = [description])
			and nullif(mobilePhone, '') is not null
	)
	--Берем те заявки которые пришли из очереди, и которых еще нету в бд
	select cte.*
		into #rmq_crm_request
	from       (
	select number
	from cte_rmq_crm_request
	except
	select НомерЗаявки
	from #crm_Requests
	)                              t  
	inner join cte_rmq_crm_request cte on cte.number = t.number

	drop table if exists #t_marketig
	select mobile_fin = stuff(mobile_fin, 1,1,'')
	,      SourceSystem = 'DIP_to_Naumen'        
	,      CreateAt = [Дата среза]               
		into #t_marketig
	from Reports.dbo.dm_Report_DIP_to_Naumen
	where [Дата среза] = (select max([Дата среза])
		from Reports.dbo.dm_Report_DIP_to_Naumen )


	select *
		into #t_data
	from (
	select distinct TRIM(PhoneNumber) as PHONE
	,               'LEAD_PHONE'   as SourceSystem
	,               CreateAt      
	from #t_LEAD_PHONE
	union
	select distinct TRIM(ТелефонМобильный) as PHONE
	,               'cmr_contract'         as SourceSystem
	,               CreateAt              
	from #cmr_contract
	union
	select distinct TRIM(МобильныйТелефон) as PHONE
	,               'crm_Requests'        
	,               CreateAt              
	from #crm_Requests
	union
	select distinct TRIM(mobilePhone) as PHONE
	,               'rmq_crm_request'
	,               CreateAt         
	from #rmq_crm_request
	union
	select TRIM(mobile_fin) as PHONE
	,      SourceSystem          
	,      CreateAt              
	from #t_marketig
	) t
	where TRY_CAST(PHONE as bigint) is not null
	if OBJECT_ID('dbo.UnBlockPhone') is null
	begin
		select top(0) *
			into dbo.UnBlockPhone
		from #t_data
	end
	begin try
	begin tran
	delete from dbo.UnBlockPhone
	insert into dbo.UnBlockPhone
	select PHONE = TRIM(PHONE)
	,      SourceSystem       
	,      CreateAt           
	from #t_data
	commit tran


	end try
	begin catch
	if @@TRANCOUNT>0
		rollback tran
		;throw
	end catch
	/*
	--insert into [DWH-EX].[RestServices].dbo.UnBlockPhone ( PHONE, SourceSystem, CreateAt )
	declare @cmd nvarchar(max) = '
		truncate table [RestServices].dbo.UnBlockPhone_stg
	'
	print @cmd
	exec (@cmd) at [DWH-EX]
	insert into [DWH-EX].[RestServices].dbo.UnBlockPhone_stg
	select PHONE = TRIM(PHONE)
	,      SourceSystem
	,      CreateAt
	
	from #t_data s
	
	set @cmd = '
	begin try
	begin tran
		truncate table [RestServices].dbo.UnBlockPhone

		alter table [RestServices].dbo.UnBlockPhone_stg
			switch to [RestServices].dbo.UnBlockPhone
	commit tran
	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
	'
	print @cmd
	exec (@cmd) at [DWH-EX]
	*/

end

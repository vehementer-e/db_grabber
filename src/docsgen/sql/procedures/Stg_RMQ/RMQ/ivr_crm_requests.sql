--sELECT SUSER_NAME(), USER_NAME();  
CREATE   PROC [RMQ].[ivr_crm_requests]
	@FromHost				nvarchar(255) = null
  , @FromHostVirtualHost	nvarchar(100) = null
  , @FromExchange			nvarchar(255) = null
  , @FromQueue				nvarchar(255) = null
  , @FromQueueRoutingKey	nvarchar(100) = null
  , @ReceivedMessage		nvarchar(max)
  , @isDebug				int = 0
 WITH EXECUTE AS OWNER
as
BEGIN

SET XACT_ABORT ON
begin try
	SELECT @isDebug = isnull(@isDebug, 0)

	

	--test
	--select @mobilePhone, @hasContract, @hasRejection

	DROP TABLE IF EXISTS #t_request

	select 
		CRMRequestGUID  = cast(r.[guid] as nvarchar(64))
		,CRMRequestID = r.number
		,МобильныйТелефон = trim(right(replace(replace(replace(trim(r.mobilePhone),')',''),'(',''),'-',''),10))
		,[Caller] ='8'+ trim(right(replace(replace(replace(trim(r.mobilePhone),')',''),'(',''),'-',''),10))
		,fio = cast(concat(left(r.lastName,50),' ',left(r.firstName,50),' ',left(r.secondName,50) ) as nvarchar(150))
		,Cmclient = 
			case 
				when s.[description] in (
					'Договор подписан',
					'Заем выдан',
					'Заем погашен',
					'Контроль получения ДС',
					'Платеж опаздывает',
					'Проблемный',
					'Просрочен')
					then 1 
				else 0
			end
		--,s.*
		,CRMRequestDate = try_cast(r.[date] as datetime)

		,isActive = 
			CASE
				--DWH-1849
				--есть текущий статус Забраковано и он был установлен более 5 дней назад, 
				--а также в истории статусов не было "Верификация КЦ", ставим isActive = false
				WHEN s.[description] = 'Забраковано' --текущий статус Забраковано
					--AND datediff(DAY, br.status_date, cast(getdate() AS date)) > 5 --был установлен более 5 дней назад
					--AND vk.Ссылка IS NULL --не было "Верификация КЦ"
				THEN 0
				WHEN s.[description] NOT IN (
					'Аннулировано'
					,'Заем аннулирован'
					,'Заем выдан'
					,'Заем погашен'
					,'Оценка качества'
					,'Платеж опаздывает'
					,'Проблемный'
					,'Просрочен'
					,'ТС продано'
					,'Отказано'
					--,'Забраковано'
					,'Действует'
					)
				THEN 1
				ELSE 0
			END

		,CRMRequest_RowVersion = cast(null as binary(8))

		,hasContract = 0
		,hasRejection = 0

		,RequestType = isnull(
			CASE
				WHEN f.[description] = 'Заполняется в личном кабинете клиента' then 'LKK'
				WHEN f.[description] = 'Заполняется в мобильном приложении' then 'Mobile'
				WHEN f.[description] = 'Заполняется партнером' then 'Partner'
				ELSE 'Unknown'
			END,
			'Unknown')
		,CRMRequestsLastStatus = s.[description]

		,CRMClientGUID = cast(r.clientGuid as nvarchar(64))
		--,c.*

		,[Type] = 'CRM_Requests'
		,IVRDate = getdate()  
		,created = getdate() 
		,updated = getdate()
		,isHistory = 0
		,Legal = 0
		,ExecutionOrder = 0

		,productType = pt.code

		,requestLastStatusCode = s.code
		--,r.*
	into #t_request
	from 
		--заявка
		(
			select a.*
			from openjson(@ReceivedMessage, '$.data')
				with (
					type nvarchar(300) '$.type'
					,guid uniqueidentifier '$.data.guid'
					,number nvarchar(30) '$.data.number'
					,mobilePhone nvarchar(50) '$.data.mobilePhone'
					,lastName nvarchar(300) '$.data.lastName'
					,firstName nvarchar(300) '$.data.firstName'
					,secondName nvarchar(300) '$.data.secondName'
					,[date] nvarchar(50) '$.data.date'
					,clientGuid uniqueidentifier '$.data.client.guid'
				) as a
			where a.type = 'request'
		) as r
		--статус
		left join (
			select a.*
			from openjson(@ReceivedMessage, '$.data')
				with (
					type nvarchar(300) '$.type'
					,guid uniqueidentifier '$.data.guid'
					,description nvarchar(300) '$.data.description'
					,code nvarchar(300) '$.data.code'
				) as a
			where a.type = 'requestStatus'
		) as s on 1=1
		--fillView
		left join (
			select a.*
			from openjson(@ReceivedMessage, '$.data')
				with (
					type nvarchar(300) '$.type'
					,guid uniqueidentifier '$.data.guid'
					,description nvarchar(300) '$.data.description'
					,code nvarchar(300) '$.data.code'
				) as a
			where a.type = 'fillView'
		) as f on 1=1
		--client
		--left join (
		--	select a.*
		--	from openjson(@ReceivedMessage, '$.data')
		--		with (
		--			type nvarchar(300) '$.type'
		--			,guid uniqueidentifier '$.data.guid'
		--			,lastName nvarchar(300) '$.data.lastName'
		--			,firstName nvarchar(300) '$.data.firstName'
		--			,secondName nvarchar(300) '$.data.secondName'
		--		) as a
		--	where a.type = 'client'
		--) as c on 1=1
		--productType
		left join (
			select a.*
			from openjson(@ReceivedMessage, '$.data')
				with (
					type nvarchar(300) '$.type'
					,guid uniqueidentifier '$.data.guid'
					,[name] nvarchar(300) '$.data.name'
					,code nvarchar(300) '$.data.code'
				) as a
			where a.type = 'productType'
		) as pt on 1=1


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_request
		SELECT * INTO ##t_request FROM #t_request
	END

	INSERT RMQ.ReceivedMessages_ivr_crm_requests(
		guid_id,
		ReceiveDate,
		FromHost,
		FromHostVirtualHost,
		FromExchange,
		FromQueue,
		FromQueueRoutingKey,
		ReceivedMessage,
		isDeleted
	)
	VALUES (
		newid(),
		getdate(),
		@FromHost,
		@FromHostVirtualHost,
		@FromExchange,
		@FromQueue,
		@FromQueueRoutingKey,
		@ReceivedMessage,
		0
	)



	declare @cmd nvarchar(max) = '
	use stg
	EXECUTE AS LOGIN =''sa''
	DECLARE @t_request ivr.utt_ivr_data
	INSERT @t_request (
		[Caller]
		, МобильныйТелефон
		, [Cmclient]
		, [CRMClientGUID] 
		, [CRMRequestGUID]
		, [CRMRequestID]
		, [fio]
		, [RequestType]
		, [CRMRequestDate]
		, [isActive]
		, [hasContract]
		, [hasRejection]
		, [CRMRequestsLastStatus]
		, [CRMRequest_RowVersion]
		, Legal
		, ExecutionOrder
		, [Type]
		, [IVRDate] 
		, [created] 
		, [updated]
		, [isHistory]
		, productType
		, requestLastStatusCode
	)
	SELECT 
		[Caller]
		, МобильныйТелефон
		, [Cmclient]
		, [CRMClientGUID] 
		, [CRMRequestGUID]
		, [CRMRequestID]
		, [fio]
		, [RequestType]
		, [CRMRequestDate]
		, [isActive]
		, [hasContract]
		, [hasRejection]
		, [CRMRequestsLastStatus]
		, [CRMRequest_RowVersion]
		, Legal
		, ExecutionOrder
		, [Type]
		, [IVRDate] 
		, [created] 
		, [updated]
		, [isHistory]
		, productType
		, requestLastStatusCode
	FROM #t_request AS T
	
	EXEC Stg.ivr.[fill_ivr_requests_from_rmq]
		@t_request = @t_request
		,@isDebug = @isDebug
		'

	declare @ParmDefinition nvarchar(max) = '@isDebug bit'
	exec stg.sys.sp_executesql @cmd
		,@ParmDefinition
		,@isDebug = @isDebug




end try
begin catch
	if @@TRANCOUNT>1
		rollback tran;
	;throw
end catch
END


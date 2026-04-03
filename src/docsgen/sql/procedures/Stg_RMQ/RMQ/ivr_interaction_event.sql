create   PROC RMQ.ivr_interaction_event
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
		--,r.*
		,interactionEventGuid = cast(e.[guid] as nvarchar(36))
		,interactionEventCode = e.code
		,interactionEventName = e.[name]
	into #t_request
	from 
		--заявка
		(
			select a.*
			from openjson(@ReceivedMessage, '$.included')
				with (
					type nvarchar(300) '$.type'
					,guid uniqueidentifier '$.id'
					,number nvarchar(30) '$.attributes.number'
				) as a
			where a.type = 'requests'
		) as r
		--
		left join
		--events
		(
			select a.*
			from openjson(@ReceivedMessage, '$.included')
				with (
					type nvarchar(300) '$.type'
					,guid uniqueidentifier '$.id'
					,name nvarchar(30) '$.attributes.name'
					,code nvarchar(30) '$.attributes.code'
				) as a
			where a.type = 'events'
		) as e on 1=1



	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_request
		SELECT * INTO ##t_request FROM #t_request
	END

	INSERT RMQ.ReceivedMessages_ivr_interaction_event(
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
		CRMRequestGUID
		,CRMRequestID
		,interactionEventGuid
		,interactionEventCode
		,interactionEventName
	)
	SELECT 
		CRMRequestGUID
		,CRMRequestID
		,interactionEventGuid
		,interactionEventCode
		,interactionEventName
	FROM #t_request AS T
	
	EXEC Stg.ivr.fill_CRMRequest_from_ivr_interaction_event
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


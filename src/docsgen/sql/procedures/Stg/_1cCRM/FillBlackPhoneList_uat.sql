/*
DWH-1340
*/
-- Usage: запуск процедуры с параметрами
-- EXEC [_1cCRM].[FillBlackPhoneList_uat];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC [_1cCRM].[FillBlackPhoneList_uat]
as
begin
	set nocount on
	SET XACT_ABORT on
begin try

	--DWH-1630 Наведения порядка в разборе сообщений из RMQ Interaction
	--перенос кода из процедуры _1cCRM.RMQ_interaction_loader (замена таблицы _1cCRM.RMQ_Interaction на #t_RMQ_Interaction)
	drop table if exists #t_data_RMQ
	select
		ReceiveDate,
		guid_id as message_guid,
		ReceivedMessage
	into #t_data_RMQ
	from rmq.ReceivedMessages_CRM_Interaction_uat

	drop table if exists #t_data_RMQ_result
	select 
		ReceiveDate,
		message_guid = guid,
		[subject],	
		subjectGuid	,
		comment,		
		userName,	
		clientGuid,	
		client,
		attributes,
		create_at = date
	into #t_data_RMQ_result
	from #t_data_RMQ
	outer apply  OPENJSON(ReceivedMessage, '$.data')
		with (
				
			guid		nvarchar(36)	'$.guid', --
			[subject]	nvarchar(255)	'$.subject', --
			date		datetime		'$.date',
			subjectGuid	nvarchar(36)	'$.subjectGuid', -- //ИдентификаторТематикиCRM
			comment		nvarchar(255)	'$.comment',        --Комментарий
			userName	nvarchar(255) 	'$.userName',
			clientGuid	nvarchar(36) 	'$.clientGuid', -- возможно null - если потенциальный клиент
			client		nvarchar(255)	'$.client',		-- возможно значение "НЕИЗВЕСТНЫЙ" - если клиент не идентифицирован
			attributes	nvarchar(max)	'$.attributes' as JSON
			) l 
	where ISJSON (ReceivedMessage) = 1

	drop table if exists #t_RMQ_Interaction

	SELECT s.* 
	INTO #t_RMQ_Interaction
	FROM #t_data_RMQ_result AS s
	WHERE s.message_guid is not null

	/*
	DELETE rm 
	FROM rmq.ReceivedMessages_CRM_Interaction_uat AS rm
		inner join #t_data_RMQ AS drm 
			ON drm.message_guid = rm.guid_id
			*/
	--//end. перенос кода из процедуры _1cCRM.RMQ_interaction_loader
	----------------------------------------------------------------------------

	declare @max_dd datetime = '2000-01-01'

	--if OBJECT_ID('_1cCRM.BlackPhoneList') is not null
		--set @max_dd = (select isnull(max(create_at), '2000-01-01') from _1cCRM.BlackPhoneList)		

	drop table if exists #t_blackPhoneList
	select 
		ReasonAdding_subject = subject , 
		ReasonAdding_subjectGuid = subjectGuid  ,
		ReasonAdding_Comment =comment,
		Phone = iif([key] = 'Phone', [value], null),
		create_at
	into #t_blackPhoneList
	--DWH-1630
	--from _1cCRM.RMQ_Interaction
	from #t_RMQ_Interaction
		outer apply  OPENJSON(attributes, '$')
		WITH (
			[key]	nvarchar(36)	'$.key', --
			[value]	nvarchar(255)	'$.value' --
		)
	where charindex('phone', attributes)>0
		and ReceiveDate>=dateadd(dd,-1, getdate())
		and subjectGuid in (
		'8096f5d9-150c-11ea-b818-00155d03492d', --Исключение номера телефона (ЧС)
		'f16ec565-20fa-11ec-b81f-00505683679e', -- Исключение номера из базы обзвона	
		'0ac3e606-20fb-11ec-b81f-00505683679e', --Жалоба на звонки со стороны Компании
		'b35a8d8f-02b7-11ed-b828-00505683679e', -- Исключение номера из базы обзвона(бессрочно) BP-2265
		'87b022d0-0d78-11ed-b832-00505683cf4d'-- Исключение номера из базы обзвона(бессрочно) BP-2265
		) 

	
	if OBJECT_ID('_1cCRM.BlackPhoneList_uat') is null
	begin
		--drop table if exists _1cCRM.BlackPhoneList
		select top(0)
		*
		into _1cCRM.BlackPhoneList_uat
		from #t_blackPhoneList

	end
	if exists (select top(1) 1 from #t_blackPhoneList)
	begin
		insert into _1cCRM.BlackPhoneList_uat([ReasonAdding_subject], [ReasonAdding_subjectGuid], [ReasonAdding_Comment], [Phone], [create_at])

		select [ReasonAdding_subject], [ReasonAdding_subjectGuid], [ReasonAdding_Comment], [Phone], [create_at] from #t_blackPhoneList s
		where not exists(select top(1) 1 from _1cCRM.BlackPhoneList_uat t where t.Phone = s.Phone
			and t.ReasonAdding_subjectGuid = s.ReasonAdding_subjectGuid
			)
		and nullif(s.Phone, '') is not null

		update t
			set create_at = s.create_at
				,ReasonAdding_Comment=  s.ReasonAdding_Comment
		from #t_blackPhoneList s
		inner join _1cCRM.BlackPhoneList_uat t on  t.Phone = s.Phone
			and t.ReasonAdding_subjectGuid = s.ReasonAdding_subjectGuid
		where t.create_at != s.create_at
	end

END try
begin catch
	IF XACT_STATE() <>0
	begin
		ROLLBACK TRANSACTION;  
	end
	;THROW -- raise error to the client
end catch

END 

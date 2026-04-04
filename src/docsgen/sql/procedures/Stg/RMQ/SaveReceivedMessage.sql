
-- Usage: запуск процедуры с параметрами
-- EXEC [RMQ].[SaveReceivedMessage]
--      @FromHost = <value>,
--      @FromHostVirtualHost = <value>,
--      @FromExchange = <value>,
--      @FromQueue = <value>,
--      @FromQueueRoutingKey = <value>,
--      @ReceivedMessage = <value>,
--      @isDebug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROC [RMQ].[SaveReceivedMessage]
	@FromHost nvarchar(255)
  , @FromHostVirtualHost nvarchar(100)
  , @FromExchange  nvarchar(255)
  , @FromQueue nvarchar(255)
  , @FromQueueRoutingKey nvarchar(100)
  , @ReceivedMessage nvarchar(max)
  , @isDebug int = 0
as
BEGIN

SELECT @isDebug = isnull(@isDebug, 0)

DECLARE @ReceivedMessages_table varchar(255)
	, @sql nvarchar(max)
	, @param nvarchar(2048)
	, @ReceivedMessages_procedure varchar(255)
DECLARE @t_ReceivedMessage_config TABLE
(
  FromExchange  nvarchar(255),
  FromQueue nvarchar(255),
  FromQueueRoutingKey nvarchar(100),
  ReceivedMessages_table nvarchar(255),
  ReceivedMessages_procedure nvarchar(255)
  UNIQUE (FromExchange, FromQueue, FromQueueRoutingKey)
)

INSERT @t_ReceivedMessage_config(FromExchange, FromQueue, FromQueueRoutingKey, ReceivedMessages_table,  ReceivedMessages_procedure)
select FromExchange, FromQueue, FromQueueRoutingKey, ReceivedMessages_table,  ReceivedMessages_procedure from (VALUES 

--('LCRM.TackingLoginom.1.1','*','*','RMQ.ReceivedMessages_LCRM_TackingLoginom', null),
--('CRIB.InnResults.1.1','*','*','RMQ.ReceivedMessages_CRIB_InnResults', null),
('cmr.contracts.1','*','*','RMQ.ReceivedMessages_cmr_contracts', null),
--('LCRM.LoginomLeadResponse.1.1','*','*','RMQ.ReceivedMessages_LCRM_LoginomLeads', null),
('CRM.Interaction.0.1','*','*','RMQ.ReceivedMessages_CRM_Interaction', null),
('CRM.Requests.1.1','*','*','RMQ.ReceivedMessages_CRM_Requests', null),
--
('cmr.contractDebt.1','*','*','RMQ.ReceivedMessages_cmr_contractDebt', null),
--('CRIB.AdapterLegacyLead','*','*','RMQ.ReceivedMessages_CRIB_AdapterLegacyLead', null),
--('CRIB.ModelVisit','*','*','RMQ.ReceivedMessages_CRIB_ModelVisit', null),
--('LCRM.GOEST.Sync.LaunchControlTable','*','*','RMQ.ReceivedMessages_LCRM_GOEST_Sync_LaunchControlTable', null),
--('LCRM.LeadData.1.1','*','*','RMQ.ReceivedMessages_LCRM_LeadRows_newRows', 'RMQ.SaveReceivedMessage_LCRM_LeadRows'),
('interactions','dwh.interactions.inn','*','RMQ.ReceivedMessages_interactions_inn', null),
--('CRIB2','dwh.CRIB2','crib2.leads.dwh.outgoing.v1','RMQ.ReceivedMessages_LeadsFlow_newRows', 'RMQ.SaveReceivedMessage_LeadsFlow_LeadRows'),
('LF.EXTERNAL','dwh.LF','LF.leads.dwh.outgoing.v1','RMQ.ReceivedMessages_LeadsFlow_newRows', 'RMQ.SaveReceivedMessage_LeadsFlow_LeadRows'),
('LF.EXTERNAL','dwh.LF.Requests','LF.requests.dwh.outgoing.v1','RMQ.ReceivedMessages_LeadsFlow_Requests_newRows'
	, 'RMQ.SaveReceivedMessage_LeadsFlow_Requests'),
--('fedor.requests.2.1','dwh.ivr.requests','*','RMQ.ReceivedMessages_fedor_request', 'RMQ.SaveReceivedMessage_fedor_request'),
/* 
перехали в stgRmq
('fedor.requests.2.1','dwh.ivr.requests','*','RMQ.ReceivedMessages_ivr_fedor_request', 'RMQ.SaveReceivedMessage_ivr_fedor_request'),
('interactions','dwh.ivr.requests_event','*','RMQ.ReceivedMessages_ivr_interactions_event', 'RMQ.SaveReceivedMessage_ivr_interactions_event'),
*/
--default table
('*','*','*','RMQ.ReceivedMessages', null)

) t(FromExchange, FromQueue, FromQueueRoutingKey, ReceivedMessages_table,  ReceivedMessages_procedure)
--определение таблицы
SELECT @ReceivedMessages_table = A.ReceivedMessages_table
	,@ReceivedMessages_procedure = A.ReceivedMessages_procedure
FROM (
		SELECT 
			SortOrder = row_number() OVER(
					ORDER BY 
						len(T.FromExchange) DESC, 
						len(T.FromQueue) DESC, 
						len(T.FromQueueRoutingKey) DESC
					),
			T.FromExchange,
			T.FromQueue,
			T.FromQueueRoutingKey,
			T.ReceivedMessages_table,
			T.ReceivedMessages_procedure
		FROM @t_ReceivedMessage_config AS T
		WHERE 1=1
			AND (T.FromExchange = @FromExchange OR T.FromExchange = '*')
			AND (T.FromQueue = @FromQueue OR T.FromQueue = '*')
			AND (T.FromQueueRoutingKey = @FromQueueRoutingKey OR T.FromQueueRoutingKey = '*')
	) AS A
	WHERE A.SortOrder = 1

IF @isDebug = 1 BEGIN
	--SELECT * FROM @t_ReceivedMessage_config
	SELECT @ReceivedMessages_table, @ReceivedMessages_procedure 
END

IF @ReceivedMessages_table IS NOT NULL OR @ReceivedMessages_procedure is not null
BEGIN
	if @ReceivedMessages_procedure is not null
	select @sql	= concat('exec ', @ReceivedMessages_procedure
		, ' @FromHost =  @FromHost
		  , @FromHostVirtualHost = @FromHostVirtualHost
		  , @FromExchange  = @FromExchange
		  , @FromQueue = @FromQueue
		  , @FromQueueRoutingKey = @FromQueueRoutingKey
		  , @ReceivedMessage =@ReceivedMessage'
		)
		
	else if @ReceivedMessages_table is not null
	begin
		SELECT @sql = concat(
		'INSERT INTO ', @ReceivedMessages_table,
		'(guid_id,ReceiveDate,FromHost,FromHostVirtualHost,FromExchange,FromQueue,FromQueueRoutingKey,ReceivedMessage,isDeleted)',
		' VALUES (newid(),getdate(),@FromHost,@FromHostVirtualHost,@FromExchange,@FromQueue,@FromQueueRoutingKey,@ReceivedMessage,0)'
		)
	end
	else 
	begin
		;throw 51000, 'таблица или процедура для сохранения сообщений RMQ не определена', 16
	end
	SELECT @param = concat(N'@FromHost nvarchar(255),', ' @FromHostVirtualHost nvarchar(100), @FromExchange  nvarchar(255), @FromQueue nvarchar(255), ',
		'@FromQueueRoutingKey nvarchar(100), @ReceivedMessage nvarchar(max)')

	IF @isDebug = 1 BEGIN
		SELECT @sql, @param
	END
	SET LOCK_TIMEOUT 60000
	EXEC sp_executesql 
		@sql, 
		@param,
		@FromHost = @FromHost,
		@FromHostVirtualHost = @FromHostVirtualHost,
		@FromExchange = @FromExchange,
		@FromQueue = @FromQueue,
		@FromQueueRoutingKey = @FromQueueRoutingKey,
		@ReceivedMessage = @ReceivedMessage
	print @sql
END
	else
	begin
		;throw 51000, 'таблица или процеда для сохранения сообщений RMQ не определена', 16
	end

END


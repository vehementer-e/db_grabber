
-- Usage: запуск процедуры с параметрами
-- EXEC [RMQ].[VeLabInteractionResult_postloader];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   procedure [RMQ].[VeLabInteractionResult_postloader]
 as

 begin

 declare @dt datetime
/*
 select @dt= max(receiveDate) from dwh_new.Dialer.VeLabInteractionResults


 insert 
 into dwh_new.Dialer.VeLabInteractionResults

  SELECT
  ReceiveDate
, FromHost
, FromHostVirtualHost
, FromExchange
, FromQueue
, FromQueueRoutingKey
, HeaderPublishTime
, HeaderPublisher
, HeaderGuid
, bodytype
, bodydocUrl
, bodyversion
, date
, summPromise
, datePromise
, comment
, requestGuid
, clientPartnerGuid
, interactionResult
, project
, getdate() created
, getdate() updated
, 0 isHistory

  FROM [RMQ].[ReceivedMessages] m
 
 
 outer apply OpenJson(m.ReceivedMessage)

  with
  (
    HeaderPublishTime bigint '$.publishTime',
    HeaderPublisher nvarchar(100) '$.publisher',
	HeaderGuid nvarchar(64) '$.guid',
	Headerdata nvarchar(max) '$.data' as Json
  ) header
  outer apply openJson(header.HeaderData,'$')
  with (
   bodytype nvarchar(100) '$.type',
   bodydocUrl nvarchar(100) '$.docUrl',
   bodyversion nvarchar(100) '$.version',
   bodyData nvarchar(max) '$.data' as Json
  ) body
  outer apply openJson(body.bodyData,'$')
  with(
  date  nvarchar(100) '$.date',
summPromise nvarchar(100) '$.summPromise',
datePromise nvarchar(100) '$.datePromise',
comment nvarchar(300) '$.comment',
requestGuid nvarchar(64) '$.requestGuid',
clientPartnerGuid nvarchar(64) '$.clientPartnerGuid',
interactionResult nvarchar(2000) '$.interactionResult',
project nvarchar(100) '$.project'
  )
 where FromQueue='velab.dwh.CollectionInteractionResult'

 and ReceiveDate>@dt
   */
 end

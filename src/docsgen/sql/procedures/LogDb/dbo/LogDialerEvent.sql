-- ============================================= 
-- Author: Andrey Shubkin 
-- Create date: 16.04.2019 
-- Description: add message into log 
-- exec [LogDialerEvent] 'CallresultsLoader','Started','','' 
-- exec [LogDialerEvent] 'CallresultsLoader','Finished','650','Success|Failed','' 
-- ============================================= 
Create PROCEDURE [dbo].[LogDialerEvent]
       @eventName nvarchar(50) 
      ,@eventType nvarchar(50) 
      ,@message nvarchar(1024)='' 
      ,@EventStatus nvarchar(1024)='' 
      ,@description nvarchar(1024)='' 
AS 
BEGIN 
SET NOCOUNT ON; 
  


SET NOCOUNT ON; 

    insert into _log   (  
       [loggerName] 
      ,[logDateTime] 
      ,[logDate] 
      ,[logDtStarted] 
      ,[logDtEnded] 
      ,[logEventName] 
      ,[logEventType] 
      ,[logEventParams] 
      ,[logEventStatus] 
      ,[logEventDescription]) 
    select 
       'Dialerlog' 
       ,getdate() 
       ,getdate() 
       ,getdate() 
       ,getdate() 
       ,@eventName 
       ,@eventType 
       ,@message 
       ,@EventStatus 
       ,@description 






END 
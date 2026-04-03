/*
Логирование информации информации об ошибках в ETL SSIS Pakages
DWH-806
*/
--select top(10) * from _log order by id desc

CREATE   PROCEDURE dbo.LogETLSSISEvent
	  @loggerName nvarchar(50) = 'LogETLSSISEvent' 
	  ,@eventName nvarchar(50) 
      ,@eventType nvarchar(50) 
      ,@message nvarchar(1024)='' 
      ,@eventStatus nvarchar(1024)='' 
      ,@description nvarchar(1024)='' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
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
       @loggerName
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

CREATE  procedure  [etl].[base_etl_started]
as
begin

 set nocount on
 
 	exec [log].[LogAndSendMailToAdmin] 'base_etl started','Info','procedure started',''


end

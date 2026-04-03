
CREATE     PROCEDURE [dbo].[marketing_report_search_lead]
  @phone VARCHAR(40) = '9177882968'
AS
SELECT created,
	   channel,
	   channelGroup,
	   entrypoint,
	   source,
	   phone, 
	   id,
	   status
FROM analytics.dbo.v_lead2
WHERE phone = @phone;
--exec _birs.dev_lead_search

CREATE   procedure [Risk].[reportUpdateCollectionWeekly]
as
begin
	SET DEADLOCK_PRIORITY HIGH 
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications]
		'WEEKLY - START' /* добавить оповещение в канал risk-reports-notifications с сообщением: "WEEKLY - START" */
	exec RiskDWH.dbo.prc$update_rep_coll_weekly;
	
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications]
		'WEEKLY - Cape' /* добавить оповещение в канал risk-reports-notifications с сообщением: " WEEKLY - Cape" */
	exec RiskDWH.dbo.prc$update_rep_coll_cape;
	 
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications]
		'WEEKLY - KA'/* добавить оповещение в канал risk-reports-notifications с сообщением: " WEEKLY - KA" */
	exec RiskDWH.dbo.prc$rep_coll_agents_portf;
	 
	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications]
		'WEEKLY - FINISH'/* добавить оповещение в канал risk-reports-notifications с сообщением: " WEEKLY - FINISH" */

end
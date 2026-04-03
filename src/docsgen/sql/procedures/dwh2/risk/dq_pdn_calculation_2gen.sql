CREATE   procedure [risk].[dq_pdn_calculation_2gen] 
as
begin

	if exists (select top(1) * from risk.pdn_calculation_2gen where pdn is null)
	begin

	--Send message to Slack

	exec LogDb.[dbo].[SendToSlack_risk-reports-notifications]
			'В витрине PDN_calculation_gen2 есть данные c pdn is null' 

	--Send MailMessage

	EXEC msdb.dbo.sp_send_dbmail @recipients='risk_tech@carmoney.ru',
				@subject = 'Витрина PDN_calculation_gen2',  
				@body = 'В витрине PDN_calculation_gen2 есть данные c pdn is null'

	end
end
--exec dbo.monitoring_changed_dpd_to_0 @dayCheck = '2021-08-22'
--DWH-1300
create   procedure monitoring_changed_dpd_to_0
	@dayCheck date = null
as
begin
	set @dayCheck = isnull(@dayCheck, getdate())
	drop table if exists #t_StrategyDataMart_2day
	drop table if exists #result
	select StrategyDate, 
		external_id, dpd, last_pay_date = 
	iif(year(last_pay_date)>3000, 
		dateadd(year, -2000, last_pay_date)
		,last_pay_date)
		,plan_date = iif(year(plan_date)>3000, dateadd(year,- 2000, plan_date), plan_date)
		,collectionStage 
		,EndFreezing
		into #t_StrategyDataMart_2day
	from dwh_new.Dialer.StrategyDataMart2_CMR
	where StrategyDate >=cast(dateadd(dd, -1, @dayCheck) as date)
	-- in ('2021-08-21', '2021-08-22')
	--and external_id= 19051618330003



	delete from #t_StrategyDataMart_2day
	where collectionStage in ('Зарегистрирован','Внебаланс', 'Legal','Погашен', 'Аннулирован', 'Решение суда', 'Продан')
	delete from  #t_StrategyDataMart_2day
	where EndFreezing >= getdate()

	select 
		today.StrategyDate,
		today.external_id,
		today_dpd = today.dpd,
		today_collectionStage= today.collectionStage,
		today_last_pay_date = today.last_pay_date, 
		today_plan_date = today.plan_date,
		datediff_last_pay_date_and_plan_date = datediff(dd, isnull(today.last_pay_date, prevDate.last_pay_date), today.plan_date ),
		prevDay_dpd= prevDate.dpd,
		prevDay_last_pay_date = prevDate.last_pay_date, 
		prevDay_plan_date = prevDate.plan_date
	into #result
		from #t_StrategyDataMart_2day today
		inner join #t_StrategyDataMart_2day  prevDate 
			on prevDate.external_id = today.external_id
				and prevDate.StrategyDate< today.StrategyDate
				and prevDate.dpd>0
	where today.dpd=0
	and today.StrategyDate = '2021-08-22'/*cast(getdate() as date)*/
	and datediff(dd, isnull(today.last_pay_date, prevDate.last_pay_date), today.plan_date ) >30
	if exists(select top(1) 1 from #result)
	begin
		declare @cnt int = (Select count(1) from #result)
		declare @slack_message nvarchar(255)= CONCAT(':bangbang:', 'У ', @cnt, ' договоров изменился dpd -> 0, но отсутствует поступление денежных средств. Витрина -StrategyDataMart2_CMR. Детали отправлены почтой')
		select @slack_message
		declare @email_subject nvarchar(255)= 'По договорам изменился dpd -> 0, но отсутствует поступление денежных средств. Витрина -StrategyDataMart2_CMR'
		exec LogDb.dbo.SendToSlack_dwhNotification @slack_message
		
		declare @recipients nvarchar(255)= 'dwh112@carmoney.ru; 112@carmoney.ru; a.galyautdinova@carmoney.ru'
		--declare @recipients nvarchar(255)= 'dwh112@carmoney.ru; a.galyautdinova@carmoney.ru'
	
		declare @email_messageHtml nvarchar(max)
		SET @email_messageHtml =

			N'<H1>'+@email_subject+'</H1>' +
			N'<table border="1">' +
			N'<tr>
				<th>StrategyDate</th>
				<th>external_id</th>
				<th>today dpd</th>
				<th>today collectionStage</th>
				<th>today last_pay_date</th>
				<th>today plan_date</th>
				<th>datediff last_pay_date and plan_date</th>
				<th>prevDay dpd</th>
				<th>prevDay last_pay_date</th>
				<th>prevDay plan_date</th>
			</tr>' +
			CAST ( ( SELECT td = StrategyDate                  
			,               ''                                      
			,               td = external_id                     
			,               ''                                      
			,               td = today_dpd                         
			,               ''                                      
			,               td = today_collectionStage
			,				''   
			,               td = format(isnull(today_last_pay_date, prevDay_last_pay_date), 'yyyy-MM-dd')
			,               ''     
			,               td = format(today_plan_date, 'yyyy-MM-dd')
			,               ''     
			,               td = datediff_last_pay_date_and_plan_date
			,               ''     
			,               td = prevDay_dpd
			,               ''     
			,               td = format(prevDay_last_pay_date, 'yyyy-MM-dd')
			,               ''     
			,               td =  format(prevDay_plan_date, 'yyyy-MM-dd')
			,               ''     

			from #result
			FOR XML PATH('tr'), TYPE
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;

			select @email_messageHtml
		EXEC msdb.dbo.sp_send_dbmail  
					@profile_name = 'Default',  
					@recipients = @recipients,  
					@body = @email_messageHtml,  
					@body_format='HTML', 
					@subject = @email_subject
	end
end
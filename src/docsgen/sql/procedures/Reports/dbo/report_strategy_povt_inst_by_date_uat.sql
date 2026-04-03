
CREATE     procedure [dbo].[report_strategy_povt_inst_by_date_uat]
	@reportDate date = null
as 
	
set @reportDate = isnull(@reportDate, getdate())
select 
	[Клиент ФИО] = t.FIO
	,[Номер телефона] = t.phone
	,[ДатаОтправки последнего Пуш]= cast(last_date2SendPush as date)
	,[Пуш Profile] = pushProfile2Send
	,[количество дней после закрытия договора] = days_after_close
	
	,client_email 
	,[E-mail Profile]  = emailProfile2Send
	,[Дата последнего звонка] = lastNaumen_AttemptDate
	,[Статус последнего звонка (код Naumen)] = lastNaumen_AttemptResult
	,[Дозвон] = case[lastNaumen_IsPhoned] 
		when 1 then 'Да'
		when 0 then 'Нет'
		end
	
	,[GUID последнего лида] =[lastCRMЗаявка_Guid]
	,[Номер последнего лида] =lastCRMЗаявка_Номер
	,[Дата последнего лида] = lastCRMЗаявка_Дата
	,[Статус заявки] = [lastCRMЗаявка_СтатусНаименование]
	,[Статус заявки ПричиныОтказов] = lastCRMЗаявка_ПричиныОтказовНаименование
	,[GUID последней ЗаявкаНаЗаймПодПТС] = [lastЗаявкаНаЗаймПодПТС_Guid]
	,[Номер последней ЗаявкаНаЗаймПодПТС]= [lastЗаявкаНаЗаймПодПТС_Номер]
	,[Дата последней ЗаявкаНаЗаймПодПТС] = [lastЗаявкаНаЗаймПодПТС_Дата]
	,[СтатусыЗаявкиНаименование  последней ЗаявкаНаЗаймПодПТС]= [lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование]
	,[СтатусыЗаявкиКод последней ЗаявкаНаЗаймПодПТС] = [lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиКод]
	,[Дата закрытия договора] =  t.factenddate
	,[Дней после закрытия договора] = t.days_after_close
	,[Статус Стратегии] = case[interactionTypeCode] 
		when 'isNew' then 'Новый'
		when 'isCustomerRejection' then 'Отказ клиента'
		when 'isCustomerRejectionPush' then 'Отказ клиента но можно отправить Push'
		when 'isNotCall2Client' then 'Недозвон'
		when 'isNotActiveApplication'then 'Нет активной заявки'
		when 'isCompanyRejection' then 'Отказ компании'
		when 'isOtherCases'then 'Остальные'
		when '0_days_after_loan_repaid' then '0 дней с момента погашения договора'
		when '1_days_after_loan_repaid' then '1 дней с момента погашения договора'
		when '2_days_after_loan_repaid' then '2 дней с момента погашения договора'
		when '3_days_after_loan_repaid' then '3 дней с момента погашения договора'
		when '4_days_after_loan_repaid' then '4 дней с момента погашения договора'
		when '5_days_after_loan_repaid' then '5 дней с момента погашения договора'
		when '6_days_after_loan_repaid' then '6 дней с момента погашения договора'
		when '7_days_after_loan_repaid' then '7 дней с момента погашения договора'
		when '8_days_after_loan_repaid' then '8 дней с момента погашения договора'
		when '9_days_after_loan_repaid' then '9 дней с момента погашения договора'
		when '10_days_after_loan_repaid' then '10 дней с момента погашения договора'
		when '11_days_after_loan_repaid' then '11 дней с момента погашения договора'
		when '12_days_after_loan_repaid' then '12 дней с момента погашения договора'
		when 'has_pts_market_proposal' then 'Есть Птс маркетинговое предложение'
		when 'UNKNOWN' then 'Неопределённо'
		end
	,	phoneInBlackList = iif(t.phoneInBlackList = 1, 'Да', 'Нет')
	from dwh2.marketing.povt_inst_uat t
where cdate = @reportDate
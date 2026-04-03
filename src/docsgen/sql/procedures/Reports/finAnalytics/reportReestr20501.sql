





CREATE PROCEDURE [finAnalytics].[reportReestr20501]
		@startDate date, @endDate date
AS
BEGIN
	select 
		[Дата]=REPDATE
		,[Счет Дт]=Dt
		,[Счет Кт]=Kt
		,[Поступление, сумма в рублях]=inSumm
		,[Списание, сумма в рублях]=outSumm
		,[Контрагент]=Client
		,[Тип контрагента (ФЛ/ИП/ЮЛ)]=typeClient
		,[ИНН]=innClient
		,[Отправитель платежа]=senderPay
		,[Назначение платежа]=purPay
		,[Номер счета]=numAcc
		,[Наименование банка]=nameBank
		,[БИК]=bikBank
		,[Код операции по Указанию 4263-У]=codBank
		,[Регистратор]=Registar
		,[Номер документа]=numDoc
		,[Вид операции]=typeOperation
		,[Вх# номер]=inNumDoc
		,[Вх# дата]=inDateDoc
		,[Статья ДДС]=itemDDS
		,[Строка 845 формы]=dwh2.finAnalytics.findDDS20501(itemDDS,Dt,Kt,inSumm,outSumm,Client,purPay)
		,[Статья ДДС группа]=itemDDSgroup
		,[Вид движения (Банк России)]=typeMoveBR
		,[Вид движения (реклассификация)]=typeMove
		,[Номер платежного поручения]=numOrderPay
		,[Комментарий]=Comment
		,[Номер ЗРДС]=numZRDS
		,[Дата ЗРДС]=dateZRDS
		,[Нач затрат]=beginCost
		,[Статья расходов]=itemExp
		,[ЦФО]=CFO
		,[Статья доходов и расходов]=itemIncExp
		,[Общая сумма по документу]=allSumm
		,[Отчетный месяц]=REPMONTH
		,[created]=created
		,[reestr_inSumm]=reestr_InSumm
		,[reestr_outSumm]=reestr_OutSumm
		,[provod_inSumm]=provod_InSumm
		,[provod_outSumm]=provod_OutSumm
		,[chk_inSumm]=abs(reestr_InSumm-provod_InSumm)
		,[chk_outSumm]=abs(reestr_OutSumm-provod_OutSumm)
	from dwh2.[finAnalytics].Reestr20501
	where repmonth between @startDate and @endDate
	order by [REPDATE]

END

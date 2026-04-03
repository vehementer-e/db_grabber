create   PROC sat.fill_ДоговорЗайма_Collection_Deals
	@mode int = 1,
	@Id int = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.ДоговорЗайма_Collection_Deals
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ДоговорЗайма_Collection_Deals

	if OBJECT_ID ('sat.ДоговорЗайма_Collection_Deals') is not null
		and @mode = 1
		and @Id is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		set @rowVersion = isnull((select max(s.RowVersion) from sat.ДоговорЗайма_Collection_Deals as s), 0x0)
	end

	select distinct
		h.СсылкаДоговораЗайма,
		h.GuidДоговораЗайма,
		h.КодДоговораЗайма,

		D.CreateDate,
		D.CreatedBy,
		D.UpdateDate,
		D.UpdatedBy,

		D.Id,
		--Number (nvarchar(255),  NULL)	
		[Date] = cast(D.[Date] as date), --Дата договора
		[Sum] = cast(D.[Sum] as money), --Сумма займа
		D.Term, --Срок договора

		--ProductType (nvarchar(255), NULL)	--Тип продукта
		--StageId (int, NULL)	--Стадия коллектинга договора
		LastPaymentDate = cast(D.LastPaymentDate as date), --Дата последнего платежа
		LastPaymentSum = cast(D.LastPaymentSum as money), --Сумма последнего платежа
		CurrentAmountOwed = cast(D.CurrentAmountOwed as money), --Сумма задолженности на текущую дату

		DebtSum = cast(D.DebtSum as money), --Остаток долга
		D.CreditAgencyStatus, --Статус КА
		D.CreditAgencyName, --Наименование КА
		--IdStatus (int, NULL)	--Статус договора
		--IdCustomer (int, NULL)	--Клиент

		D.OverdueDays, --Количество дней просрочки
		D.PlaceOfContract, --Место заключения договора
		RequestDate = try_cast(D.RequestDate as date), --Дата заявки
		D.RequestNumber, --Номер заявки
		Phone = cast(D.Phone as nvarchar(2550)), --Номер телефона

		--CmrCustomerId (uniqueidentifier, NULL)	
		--CmrId (uniqueidentifier, NULL)	--Идентификатор договора в CMR

		D.InterestRate, --Процентная ставка
		--CmrRequestId (uniqueidentifier, NULL)	--Идентификатор заявки в cmr
		D.CmrPublishDate, --Дата публикации пакета в cmr
		OverdueStartDate = cast(D.OverdueStartDate as date), --Дата возник-я просрочки
		Fulldebt = cast(D.Fulldebt as money), --Полный долг
		DateOfChangePaymentDate = cast(D.DateOfChangePaymentDate as date), --Дата изменения даты платежа

		D.PreviousPaymentDay, --Предыдущий день платежа
		D.DateStageWasLastUpdated, --Дата последнего обновления стадии
		D.IsNeedPTS, --Признак ПТС
		D.CrmRequestDate, --Дата заявки в crm
		InterestRate1 = cast(D.InterestRate1 as nvarchar(500)), --Процентная ставка 1

		D.IsPEP, --Признак ПЭП
		EngagementAgreementDate = cast(D.EngagementAgreementDate as date), --Дата соглашения о взаимодействии
		CreditVacationDateBegin = cast(D.CreditVacationDateBegin as date), --Дата начала кредитных каникул
		CreditVacationDateEnd = cast(D.CreditVacationDateEnd as date), --Дата окончания кредитных каникул
		D.RiskSegmentId, --Идентификатор риск сегмента из логинома

		D.IsCreditVacation, --Признак наличия кредитных каникул
		NextPayment = cast(D.NextPayment as money), --Сумма к оплате на ближайшую плановую дату
		D.FirstPayment, --Первый ли платеж на данном договоре
		D.HasEngagementAgreement, --Соглашение о взимодействие подписано
		D.NeedStartProcessJudicialProceeding, --Необходимость запуска бизнес процесса СП

		D.IsSegmentVisible, --Учитывать наименование сегмента в карточке клиента
		SegmentName = cast(D.SegmentName as nvarchar(500)), --Наименование сегмента
		D.SegmentNumber, --Числовой код сегмента
		Fine = cast(D.Fine as money), --Пени
		OneDayLateDateMax = cast(D.OneDayLateDateMax as date), --Последнее значение по полю "Дата" из аналитическим показателей займа где кол-во дней просрочки=1

		OneDayLateDateMin = cast(D.OneDayLateDateMin as date), --Первое (самое ранее) значение по полю "Дата" из аналитическим показателей займа где кол-во дней просрочки=1
		[Percent] = cast(D.[Percent] as money), --Проценты
		StateFee = cast(D.StateFee as money), --Госпошлина
		D.AlternativeMatrixService, --Сервис по матрице альтернатив
		D.TermOfService, --Срок сервиса

		CreditVacationReason = cast(D.CreditVacationReason as nvarchar(4000)), --Причина предоставления кредитных каникул
		ControlDateArrivalOfValuesAtWithholding = cast(D.ControlDateArrivalOfValuesAtWithholding as date), --Контрольная дата поступления ДС по удержанию
		LastCommunicationsComment = cast(D.LastCommunicationsComment as nvarchar(4000)), --Комментарий последней коммуникации
		D.LastCommunicationsDate, --Дата последней коммуникации
		OfficeAddress = cast(D.OfficeAddress as nvarchar(4000)), --Адрес заключения договора

		D.IssueDate, --Дата выдачи кредита
		D.RepeatedCreditVacationRate, --% ставка повторных КК
		RepeatedCreditVacationRateStartDate = cast(D.RepeatedCreditVacationRateStartDate as date), --Дата начала повторных кредитных каникул
		D.CallingCreditHolidays, --Обзвон КК
		D.StateDate, --Дата последнего изменения статуса договора

		D.Probation, --Исп. срок
		CheckOutComment = cast(D.CheckOutComment as nvarchar(4000)), --Комментарий к выезду
		--D.Installment (bit, NULL)	--Инстоллмент
		D.IsFreeze, --Признак наличия заморозки
		D.LastCheckOutDate, --Дата последнего выезда

		Overpayment = cast(D.Overpayment as money), --Переплата
		--D.PledgeAgreementId (int, NULL)	--Идентификатор договора залога
		D.NeedToStartLegalProcess, --Признак необходимости запуска стадии Legal
		--D.SmartInstallment (bit, NULL)	--Смарт Инстолмент
		--ProductSubTypeId (int, NULL)	--Идентификатор подтипа продукта

		--ProductTypeId (int, NULL)	--Идентификатор типа продукта
		D.SegmentId, --Идентификатор сегмента договора
		D.IsClientPhotoLoaded, --Загружено фото клиента (без паспорта)
		D.IsPass23Loaded, --Загружено фото pass2_3

		D.RowVersion,

		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,

		Link_GuidCollection_DealStatus = try_cast(hashbytes('SHA2_256', cast(D.IdStatus as varchar(30))) AS uniqueidentifier)

	into #t_ДоговорЗайма_Collection_Deals
	--SELECT top 10 d.*
	FROM Stg._Collection.Deals AS D
		inner join hub.ДоговорЗайма as h
			on h.КодДоговораЗайма = D.Number
	where 1=1
		--and try_cast(C.CmrId AS uniqueidentifier) is not null
		and D.RowVersion >= @rowVersion
		and (D.Id = @Id or @Id is null)
		and (h.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (h.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_Collection_Deals
		SELECT * INTO ##t_ДоговорЗайма_Collection_Deals FROM #t_ДоговорЗайма_Collection_Deals
		--RETURN 0
	END


	if OBJECT_ID('sat.ДоговорЗайма_Collection_Deals') is null
	begin
		select top(0)
			СсылкаДоговораЗайма,
			GuidДоговораЗайма,
			КодДоговораЗайма,

			CreateDate,
			CreatedBy,
			UpdateDate,
			UpdatedBy,

			Id,
			[Date],
			[Sum],
			Term,
			LastPaymentDate,
			LastPaymentSum,
			CurrentAmountOwed,
			DebtSum,
			CreditAgencyStatus,
			CreditAgencyName,
			OverdueDays,
			PlaceOfContract,
			RequestDate,
			RequestNumber,
			Phone,
			InterestRate,
			CmrPublishDate,
			OverdueStartDate,
			Fulldebt,
			DateOfChangePaymentDate,
			PreviousPaymentDay,
			DateStageWasLastUpdated,
			IsNeedPTS,
			CrmRequestDate,
			InterestRate1,
			IsPEP,
			EngagementAgreementDate,
			CreditVacationDateBegin,
			CreditVacationDateEnd,
			RiskSegmentId,
			IsCreditVacation,
			NextPayment,
			FirstPayment,
			HasEngagementAgreement,
			NeedStartProcessJudicialProceeding,
			IsSegmentVisible,
			SegmentName,
			SegmentNumber,
			Fine,
			OneDayLateDateMax,
			OneDayLateDateMin,
			[Percent],
			StateFee,
			AlternativeMatrixService,
			TermOfService,
			CreditVacationReason,
			ControlDateArrivalOfValuesAtWithholding,
			LastCommunicationsComment,
			LastCommunicationsDate,
			OfficeAddress,
			IssueDate,
			RepeatedCreditVacationRate,
			RepeatedCreditVacationRateStartDate,
			CallingCreditHolidays,
			StateDate,
			Probation,
			CheckOutComment,
			IsFreeze,
			LastCheckOutDate,
			Overpayment,
			NeedToStartLegalProcess,
			SegmentId,
			IsClientPhotoLoaded,
			IsPass23Loaded,

			RowVersion,

            created_at,
            updated_at,
            spFillName
		into sat.ДоговорЗайма_Collection_Deals
		from #t_ДоговорЗайма_Collection_Deals

		alter table sat.ДоговорЗайма_Collection_Deals
			alter column КодДоговораЗайма nvarchar(14) not null

		ALTER TABLE sat.ДоговорЗайма_Collection_Deals
			ADD CONSTRAINT PK_ДоговорЗайма_Collection_Deals PRIMARY KEY CLUSTERED (КодДоговораЗайма)
	end

	--begin tran
	merge sat.ДоговорЗайма_Collection_Deals t
	using #t_ДоговорЗайма_Collection_Deals s
		on t.КодДоговораЗайма = s.КодДоговораЗайма
	when not matched then insert
	(
		СсылкаДоговораЗайма,
		GuidДоговораЗайма,
		КодДоговораЗайма,

		CreateDate,
		CreatedBy,
		UpdateDate,
		UpdatedBy,

		Id,
		[Date],
		[Sum],
		Term,
		LastPaymentDate,
		LastPaymentSum,
		CurrentAmountOwed,
		DebtSum,
		CreditAgencyStatus,
		CreditAgencyName,
		OverdueDays,
		PlaceOfContract,
		RequestDate,
		RequestNumber,
		Phone,
		InterestRate,
		CmrPublishDate,
		OverdueStartDate,
		Fulldebt,
		DateOfChangePaymentDate,
		PreviousPaymentDay,
		DateStageWasLastUpdated,
		IsNeedPTS,
		CrmRequestDate,
		InterestRate1,
		IsPEP,
		EngagementAgreementDate,
		CreditVacationDateBegin,
		CreditVacationDateEnd,
		RiskSegmentId,
		IsCreditVacation,
		NextPayment,
		FirstPayment,
		HasEngagementAgreement,
		NeedStartProcessJudicialProceeding,
		IsSegmentVisible,
		SegmentName,
		SegmentNumber,
		Fine,
		OneDayLateDateMax,
		OneDayLateDateMin,
		[Percent],
		StateFee,
		AlternativeMatrixService,
		TermOfService,
		CreditVacationReason,
		ControlDateArrivalOfValuesAtWithholding,
		LastCommunicationsComment,
		LastCommunicationsDate,
		OfficeAddress,
		IssueDate,
		RepeatedCreditVacationRate,
		RepeatedCreditVacationRateStartDate,
		CallingCreditHolidays,
		StateDate,
		Probation,
		CheckOutComment,
		IsFreeze,
		LastCheckOutDate,
		Overpayment,
		NeedToStartLegalProcess,
		SegmentId,
		IsClientPhotoLoaded,
		IsPass23Loaded,

		RowVersion,

        created_at,
        updated_at,
        spFillName
	) values
	(
		s.СсылкаДоговораЗайма,
		s.GuidДоговораЗайма,
		s.КодДоговораЗайма,

		s.CreateDate,
		s.CreatedBy,
		s.UpdateDate,
		s.UpdatedBy,

		s.Id,
		s.[Date],
		s.[Sum],
		s.Term,
		s.LastPaymentDate,
		s.LastPaymentSum,
		s.CurrentAmountOwed,
		s.DebtSum,
		s.CreditAgencyStatus,
		s.CreditAgencyName,
		s.OverdueDays,
		s.PlaceOfContract,
		s.RequestDate,
		s.RequestNumber,
		s.Phone,
		s.InterestRate,
		s.CmrPublishDate,
		s.OverdueStartDate,
		s.Fulldebt,
		s.DateOfChangePaymentDate,
		s.PreviousPaymentDay,
		s.DateStageWasLastUpdated,
		s.IsNeedPTS,
		s.CrmRequestDate,
		s.InterestRate1,
		s.IsPEP,
		s.EngagementAgreementDate,
		s.CreditVacationDateBegin,
		s.CreditVacationDateEnd,
		s.RiskSegmentId,
		s.IsCreditVacation,
		s.NextPayment,
		s.FirstPayment,
		s.HasEngagementAgreement,
		s.NeedStartProcessJudicialProceeding,
		s.IsSegmentVisible,
		s.SegmentName,
		s.SegmentNumber,
		s.Fine,
		s.OneDayLateDateMax,
		s.OneDayLateDateMin,
		s.[Percent],
		s.StateFee,
		s.AlternativeMatrixService,
		s.TermOfService,
		s.CreditVacationReason,
		s.ControlDateArrivalOfValuesAtWithholding,
		s.LastCommunicationsComment,
		s.LastCommunicationsDate,
		s.OfficeAddress,
		s.IssueDate,
		s.RepeatedCreditVacationRate,
		s.RepeatedCreditVacationRateStartDate,
		s.CallingCreditHolidays,
		s.StateDate,
		s.Probation,
		s.CheckOutComment,
		s.IsFreeze,
		s.LastCheckOutDate,
		s.Overpayment,
		s.NeedToStartLegalProcess,
		s.SegmentId,
		s.IsClientPhotoLoaded,
		s.IsPass23Loaded,

		s.RowVersion,

        s.created_at,
        s.updated_at,
        s.spFillName
	)
	when matched and (
		t.RowVersion != s.RowVersion
		or @mode = 0
		)
	then update SET
		t.СсылкаДоговораЗайма = s.СсылкаДоговораЗайма,
		t.GuidДоговораЗайма = s.GuidДоговораЗайма,
		--s.КодДоговораЗайма,

		t.CreateDate = s.CreateDate,
		t.CreatedBy = s.CreatedBy,
		t.UpdateDate = s.UpdateDate,
		t.UpdatedBy = s.UpdatedBy,

		t.Id = s.Id,
		t.[Date] = s.[Date],
		t.[Sum] = s.[Sum],
		t.Term = s.Term,
		t.LastPaymentDate = s.LastPaymentDate,
		t.LastPaymentSum = s.LastPaymentSum,
		t.CurrentAmountOwed = s.CurrentAmountOwed,
		t.DebtSum = s.DebtSum,
		t.CreditAgencyStatus = s.CreditAgencyStatus,
		t.CreditAgencyName = s.CreditAgencyName,
		t.OverdueDays = s.OverdueDays,
		t.PlaceOfContract = s.PlaceOfContract,
		t.RequestDate = s.RequestDate,
		t.RequestNumber = s.RequestNumber,
		t.Phone = s.Phone,
		t.InterestRate = s.InterestRate,
		t.CmrPublishDate = s.CmrPublishDate,
		t.OverdueStartDate = s.OverdueStartDate,
		t.Fulldebt = s.Fulldebt,
		t.DateOfChangePaymentDate = s.DateOfChangePaymentDate,
		t.PreviousPaymentDay = s.PreviousPaymentDay,
		t.DateStageWasLastUpdated = s.DateStageWasLastUpdated,
		t.IsNeedPTS = s.IsNeedPTS,
		t.CrmRequestDate = s.CrmRequestDate,
		t.InterestRate1 = s.InterestRate1,
		t.IsPEP = s.IsPEP,
		t.EngagementAgreementDate = s.EngagementAgreementDate,
		t.CreditVacationDateBegin = s.CreditVacationDateBegin,
		t.CreditVacationDateEnd = s.CreditVacationDateEnd,
		t.RiskSegmentId = s.RiskSegmentId,
		t.IsCreditVacation = s.IsCreditVacation,
		t.NextPayment = s.NextPayment,
		t.FirstPayment = s.FirstPayment,
		t.HasEngagementAgreement = s.HasEngagementAgreement,
		t.NeedStartProcessJudicialProceeding = s.NeedStartProcessJudicialProceeding,
		t.IsSegmentVisible = s.IsSegmentVisible,
		t.SegmentName = s.SegmentName,
		t.SegmentNumber = s.SegmentNumber,
		t.Fine = s.Fine,
		t.OneDayLateDateMax = s.OneDayLateDateMax,
		t.OneDayLateDateMin = s.OneDayLateDateMin,
		t.[Percent] = s.[Percent],
		t.StateFee = s.StateFee,
		t.AlternativeMatrixService = s.AlternativeMatrixService,
		t.TermOfService = s.TermOfService,
		t.CreditVacationReason = s.CreditVacationReason,
		t.ControlDateArrivalOfValuesAtWithholding = s.ControlDateArrivalOfValuesAtWithholding,
		t.LastCommunicationsComment = s.LastCommunicationsComment,
		t.LastCommunicationsDate = s.LastCommunicationsDate,
		t.OfficeAddress = s.OfficeAddress,
		t.IssueDate = s.IssueDate,
		t.RepeatedCreditVacationRate = s.RepeatedCreditVacationRate,
		t.RepeatedCreditVacationRateStartDate = s.RepeatedCreditVacationRateStartDate,
		t.CallingCreditHolidays = s.CallingCreditHolidays,
		t.StateDate = s.StateDate,
		t.Probation = s.Probation,
		t.CheckOutComment = s.CheckOutComment,
		t.IsFreeze = s.IsFreeze,
		t.LastCheckOutDate = s.LastCheckOutDate,
		t.Overpayment = s.Overpayment,
		t.NeedToStartLegalProcess = s.NeedToStartLegalProcess,
		t.SegmentId = s.SegmentId,
		t.IsClientPhotoLoaded = s.IsClientPhotoLoaded,
		t.IsPass23Loaded = s.IsPass23Loaded,

		t.RowVersion = s.RowVersion,

		t.updated_at = s.updated_at,
		t.spFillName = s.spFillName
		;
	--commit tran

	insert into link.ДоговорЗайма_stage(
		КодДоговораЗайма
		,ВерсияДанныхДоговораЗайма
		,LinkName	
		,LinkGuid			
		,TargetColName
	)
	select distinct 
		КодДоговораЗайма,
		ВерсияДанныхДоговораЗайма = RowVersion,
		LinkName,
		LinkGuid, 
		TargetColName
	from #t_ДоговорЗайма_Collection_Deals
		CROSS APPLY (
			VALUES 
				  (Link_GuidCollection_DealStatus, 'link.ДоговорЗайма_Collection_DealStatus', 'GuidCollection_DealStatus')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	EXEC link.fill_link_between_ДоговорЗайма_and_other
		@LinkName='link.ДоговорЗайма_Collection_DealStatus'

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

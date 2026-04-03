/*
exec sat.fill_Collection_JudicialClaims_Attribute
	@mode = 1
	,@Id = 1469
	--,@DealId = null
	,@isDebug = 1

exec sat.fill_Collection_JudicialClaims_Attribute
	@mode = 1
	--,@Id = 1469
	,@DealId = 9683
	,@isDebug = 1

exec sat.fill_Collection_JudicialClaims_Attribute
*/
create   PROC sat.fill_Collection_JudicialClaims_Attribute
	@mode int = 1
	,@Id int = null
	,@DealId int = null
	,@isDebug int = 0
as
begin
	--truncate table sat.Collection_JudicialClaims_Attribute
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	--declare @updated_at datetime = '1900-01-01'
	

	SELECT @mode = isnull(@mode, 1)

	if OBJECT_ID ('sat.Collection_JudicialClaims_Attribute') is not null
		AND @mode = 1
		and @Id is null
		and @DealId is null
	begin
		set @rowVersion = isnull((select max(RowVersion) from sat.Collection_JudicialClaims_Attribute), 0x0)
	end

	drop table if exists #t_Collection_JudicialClaims_Attribute

	select distinct
		GuidCollection_JudicialClaims = try_cast(hashbytes('SHA2_256', cast(t.Id as varchar(30))) AS uniqueidentifier),

		t.Id,

		t.UpdatedBy,
		t.CreatedBy,
		t.CreateDate,
		t.UpdateDate,

		ClaimInCourtDate = cast(t.ClaimInCourtDate as date), -- Дата иска в суд
		AmountRequirements = cast(t.AmountRequirements as money), --Сумма иска
		NumberCasesInCourt = cast(t.NumberCasesInCourt as nvarchar(500)), -- № дела в суде
		t.ViewOfCourtsDecision, -- Вид решения суда
		t.ResultOfCourtsDecision, --Решение суда

		JudgmentDate = cast(t.JudgmentDate as date), --Дата судебного решения
		AmountJudgment = cast(t.AmountJudgment as money), --Сумма по судебному решению
		ReceiptOfJudgmentDate = cast(t.ReceiptOfJudgmentDate as date), --Дата получения решения суда
		PrincipalDebtOnClaim = cast(t.PrincipalDebtOnClaim as money), --Основной долг по иску
		PercentageOnClaim = cast(t.PercentageOnClaim as money), --% по иску
		PenaltiesOnClaim = cast(t.PenaltiesOnClaim as money), --Неустойки по иску
		StateDutyOnClaim = cast(t.StateDutyOnClaim as money), --Госпошлина по иску

		PrincipalDebtOnJudgment = cast(t.PrincipalDebtOnJudgment as money), --Основной долг по судебному решению
		PercentageOnJudgment = cast(t.PercentageOnJudgment as money), --% по судебному решению
		PenaltiesOnJudgment = cast(t.PenaltiesOnJudgment as money), --Неустойки по судебному решению
		StateDutyOnJudgment = cast(t.StateDutyOnJudgment as money), --Госпошлина по судебному решению

		Comment = cast(t.Comment as nvarchar(4000)),

		AdoptionProductionDate = cast(t.AdoptionProductionDate as date), --Дата принятия к производству
		t.AppealResult, --Результат обжалования
		t.Appellant, --Аппелянт
		t.ClaimJPForm, --Форма требования
		ClaimRevocationDate = cast(t.ClaimRevocationDate as date), --Дата отзыва

		CourtClaimSendingDate = cast(t.CourtClaimSendingDate as date), --Дата отправки иска в суд
  		CourtDate = cast(t.CourtDate as date), --Дата заседания суда
		DebtClaimSendingDate = cast(t.DebtClaimSendingDate as date), --Дата отправки иска должнику
		EdgeEmergenceNotificationDate = cast(t.EdgeEmergenceNotificationDate as date), --Дата уведомления о возникновении залога
		t.FeedWay, --Способ подачи
		JudgmentEntryIntoForceDate = cast(t.JudgmentEntryIntoForceDate as date), --Дата вступления в силу решения суда

		t.ManualFeed, --Ручная подача
		t.MonitoringResult, --Результат мониторинга
		t.NextAction, --Дальнейшие действия

		OtherClaims = cast(t.OtherClaims as money), --Иные требования, руб.
		OtherClaimsJudgment = cast(t.OtherClaimsJudgment as money), --Иные требования, руб.

		OutgoingCourtClaimNumber = cast(t.OutgoingCourtClaimNumber as nvarchar(500)), --Исх. № иска в суд
		OutgoingDebtClaimNumber = cast(t.OutgoingDebtClaimNumber as nvarchar(500)), --Исх. № иска должнику
		PledgeNotificationNumber = cast(t.PledgeNotificationNumber as nvarchar(500)), --№ уведомления о возникновении залога
		RegistryDebtClaimNumber = cast(t.RegistryDebtClaimNumber as nvarchar(500)), --№ реестра отправки иска должнику
		ResultCourtsComment = cast(t.ResultCourtsComment as nvarchar(4000)), --Комментарий к решению суда

		TaxSendingDate = cast(t.TaxSendingDate as date), --Дата отправки в ИФНС
		t.DocumentGuid, --Идентификатор исходящего документа
		CourtClaimSendingRegistryNumber = cast(t.CourtClaimSendingRegistryNumber as nvarchar(500)), --№ реестра отправки иска в суд
		InterimMeasuresComment = cast(t.InterimMeasuresComment as nvarchar(4000)), --Комментарий к обеспечительным мерам

		OrderRequestSendingData = cast(t.OrderRequestSendingData as date), --Дата отправки заявления на выдачу ИЛ
		StateDutyPaymentRequestDate = cast(t.StateDutyPaymentRequestDate as date), --Дата заявки на оплату госпошлины
		StateDutyPaymentRequestNumber = cast(t.StateDutyPaymentRequestNumber as nvarchar(500)), --№ заявки на оплату госпошлины
		t.StateDutyPaymentRequestStatusId, --Статус заявки на оплату госпошлины
		InterimMeasuresDate = cast(t.InterimMeasuresDate as date), --Дата установления обеспечительных мер

		DateOfApplicationForReturnOfStateDuty = cast(t.DateOfApplicationForReturnOfStateDuty as date),  --Дата отправки заявления на возврат г/п
		t.IsNewOwner,  --Новый владелец
		NewOwnerFio = cast(t.NewOwnerFio as nvarchar(500)),  --ФИО нового владельца
		NewOwnerStateDuty = cast(t.NewOwnerStateDuty as money),  --Госпошлина по решению суда к новому собственнику
		t.GasJusticeApplicationStatus,  --Статус заявления в ГАС Правосудие

		DateOfApplicationForPaymentOfStateDuty = cast(t.DateOfApplicationForPaymentOfStateDuty as date),  --Дата заявки на оплату госпошлины
		DateOfChangeInStatusOfApplicationForPaymentOfStateDuty = cast(t.DateOfChangeInStatusOfApplicationForPaymentOfStateDuty as date),  --Дата изменения статуса заявки на оплату госпошлины
		t.BitrixStateDutyRequestId,  --Guid запроса в Битрикс по госпошлине
		OperativePartOfCourtDecision = cast(t.OperativePartOfCourtDecision as nvarchar(4000)),  --Резолютивная часть решения суда
		t.Decision,  --Результат рассмотрения (решение)

		CaseUid = cast(t.CaseUid as nvarchar(500)),  --Уникальный идентификатор дела
		NumberCasesMaterials = cast(t.NumberCasesMaterials as nvarchar(500)),  --Номер материалов по делу
		LastCaseMonitoringDate = cast(t.LastCaseMonitoringDate as date),  --Дата отправки запроса в СудРФ на результаты рассмотрения
		CaseDateSendByEmail = cast(t.CaseDateSendByEmail as date),  --Дата отправки заявления по эл. почте
		UmfoError = cast(t.UmfoError as nvarchar(500)),  --Ошибка УМФО при оплате госпошлины

		t.TypePercentDecision,  --% для погашения
		NotPaidStateDutyOnClaim = cast(t.NotPaidStateDutyOnClaim as money), --Не оплаченная госпошлина по иску

		t.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_Collection_JudicialClaims_Attribute
	FROM Stg._Collection.JudicialClaims AS t
		left join Stg._Collection.JudicialProceeding as jp
			on t.JudicialProceedingId = jp.Id
	where 1=1
		and t.RowVersion > @rowVersion
		and (t.Id = @Id or @Id is null)
		and (jp.DealId = @DealId or @DealId is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_JudicialClaims_Attribute
		SELECT * INTO ##t_Collection_JudicialClaims_Attribute FROM #t_Collection_JudicialClaims_Attribute
		--RETURN 0
	END

	if OBJECT_ID('sat.Collection_JudicialClaims_Attribute') is null
	begin
		select top(0)
            GuidCollection_JudicialClaims,
			Id,

			UpdatedBy,
			CreatedBy,
			CreateDate,
			UpdateDate,

			ClaimInCourtDate,
			AmountRequirements,
			NumberCasesInCourt,
			ViewOfCourtsDecision,
			ResultOfCourtsDecision,

			JudgmentDate,
			AmountJudgment,
			ReceiptOfJudgmentDate,
			PrincipalDebtOnClaim,
			PercentageOnClaim,
			PenaltiesOnClaim,
			StateDutyOnClaim,

			PrincipalDebtOnJudgment,
			PercentageOnJudgment,
			PenaltiesOnJudgment,
			StateDutyOnJudgment,

			Comment,

			AdoptionProductionDate,
			AppealResult,
			Appellant,
			ClaimJPForm,
			ClaimRevocationDate,

			CourtClaimSendingDate,
			CourtDate,

			DebtClaimSendingDate,
			EdgeEmergenceNotificationDate,
			FeedWay,

			JudgmentEntryIntoForceDate,

			ManualFeed,
			MonitoringResult,
			NextAction,
			OtherClaims,
			OtherClaimsJudgment,
			OutgoingCourtClaimNumber,
			OutgoingDebtClaimNumber,
			PledgeNotificationNumber,
			RegistryDebtClaimNumber,
			ResultCourtsComment,

			TaxSendingDate,

			DocumentGuid,
			CourtClaimSendingRegistryNumber,
			InterimMeasuresComment,
			OrderRequestSendingData,
			StateDutyPaymentRequestDate,
			StateDutyPaymentRequestNumber,
			StateDutyPaymentRequestStatusId,
			InterimMeasuresDate,

			DateOfApplicationForReturnOfStateDuty,
			IsNewOwner,
			NewOwnerFio,
			NewOwnerStateDuty,
			GasJusticeApplicationStatus,

			DateOfApplicationForPaymentOfStateDuty,
			DateOfChangeInStatusOfApplicationForPaymentOfStateDuty,
			BitrixStateDutyRequestId,
			OperativePartOfCourtDecision,
			Decision,

			CaseUid,
			NumberCasesMaterials,
			LastCaseMonitoringDate,
			CaseDateSendByEmail,
			UmfoError,

			TypePercentDecision,
			NotPaidStateDutyOnClaim,

			RowVersion,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.Collection_JudicialClaims_Attribute
		from #t_Collection_JudicialClaims_Attribute

		alter table sat.Collection_JudicialClaims_Attribute
			alter column GuidCollection_JudicialClaims uniqueidentifier not null

		ALTER TABLE sat.Collection_JudicialClaims_Attribute
			ADD CONSTRAINT PK_Collection_JudicialClaims_Attribute PRIMARY KEY CLUSTERED (GuidCollection_JudicialClaims)
	end
	
	--begin tran

		merge sat.Collection_JudicialClaims_Attribute t
		using #t_Collection_JudicialClaims_Attribute s
			on t.GuidCollection_JudicialClaims = s.GuidCollection_JudicialClaims
		when not matched then insert
		(
            GuidCollection_JudicialClaims,
			Id,

			UpdatedBy,
			CreatedBy,
			CreateDate,
			UpdateDate,

			ClaimInCourtDate,
			AmountRequirements,
			NumberCasesInCourt,
			ViewOfCourtsDecision,
			ResultOfCourtsDecision,

			JudgmentDate,
			AmountJudgment,
			ReceiptOfJudgmentDate,
			PrincipalDebtOnClaim,
			PercentageOnClaim,
			PenaltiesOnClaim,
			StateDutyOnClaim,

			PrincipalDebtOnJudgment,
			PercentageOnJudgment,
			PenaltiesOnJudgment,
			StateDutyOnJudgment,

			Comment,

			AdoptionProductionDate,
			AppealResult,
			Appellant,
			ClaimJPForm,
			ClaimRevocationDate,

			CourtClaimSendingDate,
			CourtDate,

			DebtClaimSendingDate,
			EdgeEmergenceNotificationDate,
			FeedWay,

			JudgmentEntryIntoForceDate,

			ManualFeed,
			MonitoringResult,
			NextAction,
			OtherClaims,
			OtherClaimsJudgment,
			OutgoingCourtClaimNumber,
			OutgoingDebtClaimNumber,
			PledgeNotificationNumber,
			RegistryDebtClaimNumber,
			ResultCourtsComment,

			TaxSendingDate,

			DocumentGuid,
			CourtClaimSendingRegistryNumber,
			InterimMeasuresComment,
			OrderRequestSendingData,
			StateDutyPaymentRequestDate,
			StateDutyPaymentRequestNumber,
			StateDutyPaymentRequestStatusId,
			InterimMeasuresDate,

			DateOfApplicationForReturnOfStateDuty,
			IsNewOwner,
			NewOwnerFio,
			NewOwnerStateDuty,
			GasJusticeApplicationStatus,

			DateOfApplicationForPaymentOfStateDuty,
			DateOfChangeInStatusOfApplicationForPaymentOfStateDuty,
			BitrixStateDutyRequestId,
			OperativePartOfCourtDecision,
			Decision,

			CaseUid,
			NumberCasesMaterials,
			LastCaseMonitoringDate,
			CaseDateSendByEmail,
			UmfoError,

			TypePercentDecision,
			NotPaidStateDutyOnClaim,

			RowVersion,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
            s.GuidCollection_JudicialClaims,
			s.Id,

			s.UpdatedBy,
			s.CreatedBy,
			s.CreateDate,
			s.UpdateDate,

			s.ClaimInCourtDate,
			s.AmountRequirements,
			s.NumberCasesInCourt,
			s.ViewOfCourtsDecision,
			s.ResultOfCourtsDecision,

			s.JudgmentDate,
			s.AmountJudgment,
			s.ReceiptOfJudgmentDate,
			s.PrincipalDebtOnClaim,
			s.PercentageOnClaim,
			s.PenaltiesOnClaim,
			s.StateDutyOnClaim,

			s.PrincipalDebtOnJudgment,
			s.PercentageOnJudgment,
			s.PenaltiesOnJudgment,
			s.StateDutyOnJudgment,

			s.Comment,

			s.AdoptionProductionDate,
			s.AppealResult,
			s.Appellant,
			s.ClaimJPForm,
			s.ClaimRevocationDate,

			s.CourtClaimSendingDate,
			s.CourtDate,

			s.DebtClaimSendingDate,
			s.EdgeEmergenceNotificationDate,
			s.FeedWay,

			s.JudgmentEntryIntoForceDate,

			s.ManualFeed,
			s.MonitoringResult,
			s.NextAction,
			s.OtherClaims,
			s.OtherClaimsJudgment,
			s.OutgoingCourtClaimNumber,
			s.OutgoingDebtClaimNumber,
			s.PledgeNotificationNumber,
			s.RegistryDebtClaimNumber,
			s.ResultCourtsComment,

			s.TaxSendingDate,

			s.DocumentGuid,
			s.CourtClaimSendingRegistryNumber,
			s.InterimMeasuresComment,
			s.OrderRequestSendingData,
			s.StateDutyPaymentRequestDate,
			s.StateDutyPaymentRequestNumber,
			s.StateDutyPaymentRequestStatusId,
			s.InterimMeasuresDate,

			s.DateOfApplicationForReturnOfStateDuty,
			s.IsNewOwner,
			s.NewOwnerFio,
			s.NewOwnerStateDuty,
			s.GasJusticeApplicationStatus,

			s.DateOfApplicationForPaymentOfStateDuty,
			s.DateOfChangeInStatusOfApplicationForPaymentOfStateDuty,
			s.BitrixStateDutyRequestId,
			s.OperativePartOfCourtDecision,
			s.Decision,

			s.CaseUid,
			s.NumberCasesMaterials,
			s.LastCaseMonitoringDate,
			s.CaseDateSendByEmail,
			s.UmfoError,

			s.TypePercentDecision,
			s.NotPaidStateDutyOnClaim,

			s.RowVersion,

            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (t.RowVersion <> s.RowVersion
				or @mode = 0
			)
		then update SET
			t.Id = s.Id,

			t.UpdatedBy = s.UpdatedBy,
			t.CreatedBy = s.CreatedBy,
			t.CreateDate = s.CreateDate,
			t.UpdateDate = s.UpdateDate,

			t.ClaimInCourtDate = s.ClaimInCourtDate,
			t.AmountRequirements = s.AmountRequirements,
			t.NumberCasesInCourt = s.NumberCasesInCourt,
			t.ViewOfCourtsDecision = s.ViewOfCourtsDecision,
			t.ResultOfCourtsDecision = s.ResultOfCourtsDecision,

			t.JudgmentDate = s.JudgmentDate,
			t.AmountJudgment = s.AmountJudgment,
			t.ReceiptOfJudgmentDate = s.ReceiptOfJudgmentDate,
			t.PrincipalDebtOnClaim = s.PrincipalDebtOnClaim,
			t.PercentageOnClaim = s.PercentageOnClaim,
			t.PenaltiesOnClaim = s.PenaltiesOnClaim,
			t.StateDutyOnClaim = s.StateDutyOnClaim,

			t.PrincipalDebtOnJudgment = s.PrincipalDebtOnJudgment,
			t.PercentageOnJudgment = s.PercentageOnJudgment,
			t.PenaltiesOnJudgment = s.PenaltiesOnJudgment,
			t.StateDutyOnJudgment = s.StateDutyOnJudgment,

			t.Comment = s.Comment,

			t.AdoptionProductionDate = s.AdoptionProductionDate,
			t.AppealResult = s.AppealResult,
			t.Appellant = s.Appellant,
			t.ClaimJPForm = s.ClaimJPForm,
			t.ClaimRevocationDate = s.ClaimRevocationDate,

			t.CourtClaimSendingDate = s.CourtClaimSendingDate,
			t.CourtDate = s.CourtDate,

			t.DebtClaimSendingDate = s.DebtClaimSendingDate,
			t.EdgeEmergenceNotificationDate = s.EdgeEmergenceNotificationDate,
			t.FeedWay = s.FeedWay,

			t.JudgmentEntryIntoForceDate = s.JudgmentEntryIntoForceDate,

			t.ManualFeed = s.ManualFeed,
			t.MonitoringResult = s.MonitoringResult,
			t.NextAction = s.NextAction,
			t.OtherClaims = s.OtherClaims,
			t.OtherClaimsJudgment = s.OtherClaimsJudgment,
			t.OutgoingCourtClaimNumber = s.OutgoingCourtClaimNumber,
			t.OutgoingDebtClaimNumber = s.OutgoingDebtClaimNumber,
			t.PledgeNotificationNumber = s.PledgeNotificationNumber,
			t.RegistryDebtClaimNumber = s.RegistryDebtClaimNumber,
			t.ResultCourtsComment = s.ResultCourtsComment,

			t.TaxSendingDate = s.TaxSendingDate,

			t.DocumentGuid = s.DocumentGuid,
			t.CourtClaimSendingRegistryNumber = s.CourtClaimSendingRegistryNumber,
			t.InterimMeasuresComment = s.InterimMeasuresComment,
			t.OrderRequestSendingData = s.OrderRequestSendingData,
			t.StateDutyPaymentRequestDate = s.StateDutyPaymentRequestDate,
			t.StateDutyPaymentRequestNumber = s.StateDutyPaymentRequestNumber,
			t.StateDutyPaymentRequestStatusId = s.StateDutyPaymentRequestStatusId,
			t.InterimMeasuresDate = s.InterimMeasuresDate,

			t.DateOfApplicationForReturnOfStateDuty = s.DateOfApplicationForReturnOfStateDuty,
			t.IsNewOwner = s.IsNewOwner,
			t.NewOwnerFio = s.NewOwnerFio,
			t.NewOwnerStateDuty = s.NewOwnerStateDuty,
			t.GasJusticeApplicationStatus = s.GasJusticeApplicationStatus,

			t.DateOfApplicationForPaymentOfStateDuty = s.DateOfApplicationForPaymentOfStateDuty,
			t.DateOfChangeInStatusOfApplicationForPaymentOfStateDuty = s.DateOfChangeInStatusOfApplicationForPaymentOfStateDuty,
			t.BitrixStateDutyRequestId = s.BitrixStateDutyRequestId,
			t.OperativePartOfCourtDecision = s.OperativePartOfCourtDecision,
			t.Decision = s.Decision,

			t.CaseUid = s.CaseUid,
			t.NumberCasesMaterials = s.NumberCasesMaterials,
			t.LastCaseMonitoringDate = s.LastCaseMonitoringDate,
			t.CaseDateSendByEmail = s.CaseDateSendByEmail,
			t.UmfoError = s.UmfoError,

			t.TypePercentDecision = s.TypePercentDecision,
			t.NotPaidStateDutyOnClaim = s.NotPaidStateDutyOnClaim,

			t.RowVersion = s.RowVersion,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
			;
	--commit tran

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

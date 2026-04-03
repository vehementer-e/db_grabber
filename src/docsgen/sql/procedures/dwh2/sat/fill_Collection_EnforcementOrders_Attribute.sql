/*
exec sat.fill_Collection_EnforcementOrders_Attribute
	@mode = 1
	,@Id = 1469
	--,@DealId = null
	,@isDebug = 1

exec sat.fill_Collection_EnforcementOrders_Attribute
	@mode = 1
	--,@Id = 1469
	,@DealId = 9683
	,@isDebug = 1

exec sat.fill_Collection_EnforcementOrders_Attribute
*/
create   PROC sat.fill_Collection_EnforcementOrders_Attribute
	@mode int = 1
	,@Id int = null
	,@DealId int = null
	,@isDebug int = 0
as
begin
	--truncate table sat.Collection_EnforcementOrders_Attribute
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	--declare @updated_at datetime = '1900-01-01'
	

	SELECT @mode = isnull(@mode, 1)

	if OBJECT_ID ('sat.Collection_EnforcementOrders_Attribute') is not null
		AND @mode = 1
		and @Id is null
		and @DealId is null
	begin
		set @rowVersion = isnull((select max(RowVersion) from sat.Collection_EnforcementOrders_Attribute), 0x0)
	end

	drop table if exists #t_Collection_EnforcementOrders_Attribute

	select distinct
		GuidCollection_EnforcementOrders = try_cast(hashbytes('SHA2_256', cast(t.Id as varchar(30))) AS uniqueidentifier),

		t.Id,

		t.UpdatedBy,
		t.CreatedBy,
		t.CreateDate,
		t.UpdateDate,

		ReceiptDate = cast(t.ReceiptDate as date), --Дата получения ИЛ
		Number = cast(t.Number as nvarchar(500)), --№ ИЛ
		Amount = cast(t.Amount as money), --Сумма ИЛ
		t.Accepted, --ИЛ принят

		Comment = cast(t.Comment as nvarchar(4000)), --Комментарий

		AcceptanceDate = cast(t.AcceptanceDate as date), --Дата принятия ИЛ в работу
		ReceiptInitCostCollateral = cast(t.ReceiptInitCostCollateral as money), --Начальная стоимость залога по ИЛ
		ReceiptReturnDate = cast(t.ReceiptReturnDate as date), --Дата возврата ИЛ на доработку
		[Date] = cast(t.[Date] as date), --Дата ИЛ
		ErrorCorrectionNumberDate = cast(t.ErrorCorrectionNumberDate as date), --Дата отправки заявления на исправление ошибок ИЛ
		ErrorCorrectionSubmissionRegistryNumber = cast(t.ErrorCorrectionSubmissionRegistryNumber as nvarchar(500)), --№ реестра отправки заявления на исправление ошибок ИЛ
		StartCorrectionNumber = cast(t.StartCorrectionNumber as nvarchar(500)), --Исх. № заявления на исправление ИЛ
		t.ClaimJPForm, --Форма требования
		t.InterimMeasures, --Обеспечительные меры
		InterimMeasuresComment = cast(t.InterimMeasuresComment as nvarchar(4000)), --Комментарий к обеспечительным мерам
		t.[Type], --Тип ИЛ
		NewOwner = cast(t.NewOwner as nvarchar(500)), --Новый собственник

		t.ReturnReason, --Причина возврата на доработку
		RemainingDebt = cast(t.RemainingDebt as money), --Остаток задолженности по ИЛ
		NewOwnerAddress = cast(t.NewOwnerAddress as nvarchar(4000)), --Адрес нового собственника
		NewOwnerBirthDate = cast(t.NewOwnerBirthDate as date), --Дата рождения нового собственника

		t.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_Collection_EnforcementOrders_Attribute
	FROM Stg._Collection.EnforcementOrders AS t
		left join Stg._Collection.JudicialClaims AS jc
			on t.JudicialClaimId = jc.Id
		left join Stg._Collection.JudicialProceeding as jp
			on jc.JudicialProceedingId = jp.Id
	where 1=1
		and t.RowVersion > @rowVersion
		and (t.Id = @Id or @Id is null)
		and (jp.DealId = @DealId or @DealId is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_EnforcementOrders_Attribute
		SELECT * INTO ##t_Collection_EnforcementOrders_Attribute FROM #t_Collection_EnforcementOrders_Attribute
		--RETURN 0
	END

	if OBJECT_ID('sat.Collection_EnforcementOrders_Attribute') is null
	begin
		select top(0)
            GuidCollection_EnforcementOrders,
			Id,

			UpdatedBy,
			CreatedBy,
			CreateDate,
			UpdateDate,

			ReceiptDate,
			Number,
			Amount,
			Accepted,

			Comment,

			AcceptanceDate,
			ReceiptInitCostCollateral,
			ReceiptReturnDate,
			[Date],
			ErrorCorrectionNumberDate,
			ErrorCorrectionSubmissionRegistryNumber,
			StartCorrectionNumber,
			ClaimJPForm,
			InterimMeasures,
			InterimMeasuresComment,
			[Type],
			NewOwner,

			ReturnReason,
			RemainingDebt,
			NewOwnerAddress,
			NewOwnerBirthDate,

			RowVersion,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.Collection_EnforcementOrders_Attribute
		from #t_Collection_EnforcementOrders_Attribute

		alter table sat.Collection_EnforcementOrders_Attribute
			alter column GuidCollection_EnforcementOrders uniqueidentifier not null

		ALTER TABLE sat.Collection_EnforcementOrders_Attribute
			ADD CONSTRAINT PK_Collection_EnforcementOrders_Attribute PRIMARY KEY CLUSTERED (GuidCollection_EnforcementOrders)
	end
	
	--begin tran

		merge sat.Collection_EnforcementOrders_Attribute t
		using #t_Collection_EnforcementOrders_Attribute s
			on t.GuidCollection_EnforcementOrders = s.GuidCollection_EnforcementOrders
		when not matched then insert
		(
            GuidCollection_EnforcementOrders,
			Id,

			UpdatedBy,
			CreatedBy,
			CreateDate,
			UpdateDate,

			ReceiptDate,
			Number,
			Amount,
			Accepted,

			Comment,

			AcceptanceDate,
			ReceiptInitCostCollateral,
			ReceiptReturnDate,
			[Date],
			ErrorCorrectionNumberDate,
			ErrorCorrectionSubmissionRegistryNumber,
			StartCorrectionNumber,
			ClaimJPForm,
			InterimMeasures,
			InterimMeasuresComment,
			[Type],
			NewOwner,

			ReturnReason,
			RemainingDebt,
			NewOwnerAddress,
			NewOwnerBirthDate,

			RowVersion,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
            s.GuidCollection_EnforcementOrders,
			s.Id,

			s.UpdatedBy,
			s.CreatedBy,
			s.CreateDate,
			s.UpdateDate,

			s.ReceiptDate,
			s.Number,
			s.Amount,
			s.Accepted,

			s.Comment,

			s.AcceptanceDate,
			s.ReceiptInitCostCollateral,
			s.ReceiptReturnDate,
			s.[Date],
			s.ErrorCorrectionNumberDate,
			s.ErrorCorrectionSubmissionRegistryNumber,
			s.StartCorrectionNumber,
			s.ClaimJPForm,
			s.InterimMeasures,
			s.InterimMeasuresComment,
			s.[Type],
			s.NewOwner,

			s.ReturnReason,
			s.RemainingDebt,
			s.NewOwnerAddress,
			s.NewOwnerBirthDate,

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

			t.ReceiptDate = s.ReceiptDate,
			t.Number = s.Number,
			t.Amount = s.Amount,
			t.Accepted = s.Accepted,

			t.Comment = s.Comment,

			t.AcceptanceDate = s.AcceptanceDate,
			t.ReceiptInitCostCollateral = s.ReceiptInitCostCollateral,
			t.ReceiptReturnDate = s.ReceiptReturnDate,
			t.[Date] = s.[Date],
			t.ErrorCorrectionNumberDate = s.ErrorCorrectionNumberDate,
			t.ErrorCorrectionSubmissionRegistryNumber = s.ErrorCorrectionSubmissionRegistryNumber,
			t.StartCorrectionNumber = s.StartCorrectionNumber,
			t.ClaimJPForm = s.ClaimJPForm,
			t.InterimMeasures = s.InterimMeasures,
			t.InterimMeasuresComment = s.InterimMeasuresComment,
			t.[Type] = s.[Type],
			t.NewOwner = s.NewOwner,

			t.ReturnReason = s.ReturnReason,
			t.RemainingDebt = s.RemainingDebt,
			t.NewOwnerAddress = s.NewOwnerAddress,
			t.NewOwnerBirthDate = s.NewOwnerBirthDate,

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

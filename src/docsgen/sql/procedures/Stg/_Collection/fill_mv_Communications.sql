-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 21.07.2025
-- Description:	Процедура для обнолвения таблицы stg._Collection.mv_Communications
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [_Collection].[fill_mv_Communications]
--      @dtFrom = null,
--      @dtTo = null,
--      @isDebug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE     PROCEDURE [_Collection].[fill_mv_Communications] 
	@dtFrom DATE = null,
	@dtTo DATE = null,
	@isDebug BIT = 0
AS
BEGIN
	-- 0. Составим дефолт значения
	DECLARE @today date = cast(getdate() as date)

	select 
		@dtTo = isnull(@dtTo,  DATEADD(day, 0, @today))
		,@dtFrom = isnull(@dtFrom,  dateadd(day, -10, @today))
	

	-- 1. Создадим пулл дат
	DROP TABLE IF EXISTS #t_dates;
	SELECT
		DATEADD(day, n.number, @dtFrom) AS WorkDate,
		cast(null as bit)  as result 
	INTO #t_dates
	FROM master..spt_values n
	WHERE n.type = 'P'
	  AND n.number BETWEEN 0 AND DATEDIFF(day, @dtFrom, @dtTo)
	-- 2. Объявление курсора
	DECLARE @d date;
	DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
	    SELECT WorkDate FROM #t_dates ORDER BY WorkDate;
	
	OPEN cur;
	FETCH NEXT FROM cur INTO @d;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    BEGIN TRY
			-- Подсчет хэш-значений 
	        DROP TABLE IF EXISTS #t_src;
	        SELECT  v.*,
	                HASHBYTES('SHA2_256',
	                          CONCAT_WS('|',
	                              v.id_1,
	                              v.CommunicationType,
	                              v.CommunicationDateTime,
								  v.Sum,
								  v.DebtSum,
								  v.PromiseSum,
								  v.ContactTypeId,
								  v.ContactPerson,
								  v.PhoneNumber,
								  v.CommunicationResultId,
								  v.CommunicationResult,
								  v.Manager,
								  v.EmployeeId,
								  v.EmployeeStage,
								  v.PaymentSystemId ,
								  v.IdDeal          ,
								  v.CommunicationTemplateId,
								  v.sessionId,
								  v.NaumenProjectId
	                          )
	                ) AS NewRowHash
	        INTO    #t_src
	        FROM    stg._Collection.v_Communications v
	        WHERE   v.CommunicationDate = @d;
	
	        IF NOT EXISTS (SELECT 1 FROM #t_src)
	        BEGIN
	            UPDATE #t_dates
				SET result = 1	 -- Если данных по дате нет - будем считать что шаг выполнен успешно
				WHERE WorkDate = @d
				COMMIT;
	            FETCH NEXT FROM cur INTO @d;
	            CONTINUE;
	        END
		    
			BEGIN TRAN;
			MERGE stg._Collection.mv_Communications			AS tgt
			USING #t_src									AS src
			ON	tgt.id_1 = src.id_1 AND
				isnull(tgt.EmployeeStage, '') =  isnull(src.EmployeeStage,'')
	        WHEN MATCHED
				and   isnull(tgt.RowHash, 0)!= src.NewRowHash		
			THEN -- обновляем при наличии совпадений по Хэш
		    UPDATE SET
		      tgt.CommunicationType				= src.CommunicationType,
			  tgt.id_1							= src.id_1,
		      tgt.CommunicationDate				= src.CommunicationDate,
		      tgt.CommunicationDateTime			= src.CommunicationDateTime,
			  tgt.id							= src.id,
			  tgt.number						= src.number,
			  tgt.UpdateDate					= src.UpdateDate,
		      tgt.Date							= src.Date,
			  tgt.sum							= src.Sum,
			  tgt.DebtSum						= src.DebtSum,
			  tgt.Fulldebt						= src.Fulldebt,
		      tgt.ContactPerson					= src.ContactPerson,
		      tgt.PhoneNumber					= src.PhoneNumber,
		      tgt.ContactTypeId					= src.ContactTypeId,
		      tgt.PromiseSum					= src.PromiseSum,
		      tgt.PromiseDate					= src.PromiseDate,
		      tgt.Manager						= src.Manager,
		      tgt.Commentary					= src.Commentary,
		      tgt.CustomerId					= src.CustomerId,
		      tgt.ContactPersonType				= src.ContactPersonType,
			  tgt.PersonType					= src.PersonType,
			  tgt.EmployeeId					= src.EmployeeId,
			  tgt.CallId						= src.CallId,
			  tgt.EndCallDt						= src.EndCallDt	,
			  tgt.CommunicationResultId			= src.CommunicationResultId,
			  tgt.CommunicationResult			= src.CommunicationResult,
			  tgt.PaymentPromiseId				= src.PaymentPromiseId,
			  tgt.fio							= src.fio,
			  tgt.CrmCustomerId					= src.CrmCustomerId,
			  tgt.EmployeeStage					= src.EmployeeStage,
			  tgt.Контакт						= src.Контакт,
			  tgt.CommunicationTemplate			= src.CommunicationTemplate	,
			  tgt.IsTemplateCommunication		= src.IsTemplateCommunication,
			  tgt.SMSWithUrl_flag				= src.SMSWithUrl_flag,
			  tgt.sms_flag						= src.sms_flag,
			  tgt.url_ending					= src.url_ending,
			  tgt.smsurl						= src.smsurl,
		      tgt.FollowingStep					= src.FollowingStep,
		      tgt.FollowingStepDt				= src.FollowingStepDt,
		      tgt.NonPaymentReason				= src.NonPaymentReason,
		      tgt.ExpectedPaymentDt				= src.ExpectedPaymentDt,
		      tgt.NextCallTime					= src.NextCallTime,
		      tgt.PaymentSystemId				= src.PaymentSystemId,
		      tgt.CommunicationCustomerTypeId	= src.CommunicationCustomerTypeId,
		      tgt.NaumenProjectId				= src.NaumenProjectId,
		      tgt.IdAnotherCustomerType			= src.IdAnotherCustomerType,
		      tgt.IdAnotherNonPaymentReason		= src.IdAnotherNonPaymentReason,
		      tgt.AdditionalInputField			= src.AdditionalInputField,
		      tgt.MessageSubject				= src.MessageSubject,
			  tgt.CommunicationTemplateId		= src.CommunicationTemplateId,
			  tgt.NaumenCaseUuid				= src.NaumenCaseUuid,
			  tgt.SessionId						= src.SessionId,
			  tgt.CommentaryShort				= src.CommentaryShort,
			  tgt.RowHash						= src.NewRowHash			 
		WHEN NOT MATCHED BY TARGET -- Добавляем новые записи при отсутствии
		THEN INSERT (
		       CommunicationType, id_1, CommunicationDate, CommunicationDateTime, Id, Number, UpdateDate, Date, Sum,
			   DebtSum, Fulldebt, ContactPerson, PhoneNumber, ContactTypeId, PromiseSum, PromiseDate, Manager,
			   Commentary, CustomerId, ContactPersonType, PersonType, IdDeal, EmployeeId, CallId, EndCallDt, 
			   CommunicationResultId, CommunicationResult, PaymentPromiseId, fio, CrmCustomerId, EmployeeStage, 
			   Контакт, CommunicationTemplate, IsTemplateCommunication, SMSWithUrl_flag, sms_flag, url_ending,
			   smsurl,FollowingStep, FollowingStepDt, NonPaymentReason, ExpectedPaymentDt, NextCallTime, PaymentSystemId,
			   CommunicationCustomerTypeId, NaumenProjectId, IdAnotherCustomerType, IdAnotherNonPaymentReason, AdditionalInputField,
			   MessageSubject, CommunicationTemplateId, NaumenCaseUuid, SessionId, CommentaryShort, RowHash
			   )
		     VALUES (
				src.CommunicationType,  src.id_1, src.CommunicationDate, src.CommunicationDateTime, src.Id,src.Number,
				src.UpdateDate,src.Date,src.Sum,src.DebtSum,src.Fulldebt,src.ContactPerson,src.PhoneNumber	,src.ContactTypeId,
				src.PromiseSum,src.PromiseDate,src.Manager,src.Commentary,src.CustomerId,src.ContactPersonType,src.PersonType,
				src.IdDeal,src.EmployeeId, src.CallId,src.EndCallDt,src.CommunicationResultId,src.CommunicationResult,src.PaymentPromiseId,
				src.fio, src.CrmCustomerId, src.EmployeeStage, src.Контакт, src.CommunicationTemplate, src.IsTemplateCommunication,
				src.SMSWithUrl_flag,src.sms_flag,src.url_ending,src.smsurl,src.FollowingStep,src.FollowingStepDt,src.NonPaymentReason,
				src.ExpectedPaymentDt,src.NextCallTime,src.PaymentSystemId,src.CommunicationCustomerTypeId,src.NaumenProjectId,
				src.IdAnotherCustomerType,src.IdAnotherNonPaymentReason,src.AdditionalInputField,src.MessageSubject,src.CommunicationTemplateId,
				src.NaumenCaseUuid,src.SessionId,src.CommentaryShort,src.NewRowHash);
			COMMIT;
			-- обновляем флаг у даты при успешном обновлении
			UPDATE #t_dates
				SET result = 1
			WHERE WorkDate = @d
			print concat_ws(' '
				, 'обновление mv_Communications за' 
				, @d
				, 'завершилось успешно')
	    END TRY
	    BEGIN CATCH
			IF XACT_STATE() <> 0 ROLLBACK;
			-- обновляем флаг у даты при не успешном обновлении
			UPDATE #t_dates
				SET result = 0
			WHERE WorkDate = @d
			-- выводим ошибку
	        DECLARE @msg nvarchar(2048) = concat_ws('', 
				'обновление mv_Communications за'
				, @d
				,'завершилось с ошибкой:'
				,ERROR_MESSAGE())
			
			;throw 50000, @msg, 16
	        
	    END CATCH;
	    FETCH NEXT FROM cur INTO @d;
	END
	
	CLOSE cur;
	DEALLOCATE cur;

	if @isDebug =  1
	begin
		select *
		from #t_dates
	end
END

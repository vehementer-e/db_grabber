-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-12-09
-- Description:	DWH-2863 Реализовать отчет по назначенным взаимодествиям
-- =============================================
/*
EXEC Reports.Risk.fill_dm_loginom_interaction
	--@days = 2,
	@mode = 1, -- 
	--@action_row_id = NULL, -- расчет по одному взаимодействию
	@isDebug = 1
*/
CREATE   PROC [Risk].[fill_dm_loginom_interaction]
	@days int = 5, --кол-во дней для пересчета
	@mode int = 1, -- 
	@action_row_id int = NULL, -- расчет по одному взаимодействию
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @call_date datetime2(7) = cast(dateadd(DAY, -@days, getdate()) AS date) --'2000-01-01'
	DECLARE @min_call_date date, @max_call_date date

	BEGIN TRY
		if OBJECT_ID ('Risk.dm_loginom_interaction') is not null
			AND @mode = 1
		begin
			SELECT @call_date = isnull(dateadd(DAY, -@days, max(D.call_date)), @call_date)
			from Risk.dm_loginom_interaction AS D
		end

		DROP TABLE IF EXISTS #t_Collection_ActionID_history
		CREATE TABLE #t_Collection_ActionID_history(
			row_id bigint,
			userName nvarchar (500),
			call_date date,
			call_date_time datetime,
			CRMClientGUID nvarchar (50),
			fio nvarchar (1024),
			external_id nvarchar (50),
			Stage nvarchar (50),
			ActionID nvarchar (50),
			packageName nvarchar (500),
			CommunicationTemplateId int,
			CommunicationType int,
			CommunicationTypeName nvarchar(255)
		)

		IF @action_row_id IS NOT NULL BEGIN
			INSERT #t_Collection_ActionID_history
			(
			    row_id,
			    userName,
			    call_date,
			    call_date_time,
			    CRMClientGUID,
			    fio,
			    external_id,
			    Stage,
			    ActionID,
			    packageName,
				CommunicationTemplateId,
				CommunicationType,
				CommunicationTypeName
			)
			SELECT 
				A.row_id,
				A.userName,
				call_date = cast(A.call_date AS date),
				call_date_time = A.call_date,
				A.CRMClientGUID,
				A.fio,
				A.external_id,
				A.Stage,
				A.ActionID,
				A.packageName,
				CommunicationTemplateId = CT.Id,
				CT.CommunicationType,
				CommunicationTypeName = T.Name
			FROM Stg._loginom.Collection_ActionID_history AS A
				LEFT JOIN Stg._collection.CommunicationTemplate AS CT
					ON CT.ExternalNumber = A.ActionID
				LEFT join stg._collection.CommunicationType AS T 
					ON T.Id = CT.CommunicationType
			WHERE A.row_id = @action_row_id
		END
		ELSE BEGIN
			INSERT #t_Collection_ActionID_history
			(
			    row_id,
			    userName,
			    call_date,
				call_date_time,
			    CRMClientGUID,
			    fio,
			    external_id,
			    Stage,
			    ActionID,
			    packageName,
				CommunicationTemplateId,
				CommunicationType,
				CommunicationTypeName
			)
			SELECT 
				A.row_id,
				A.userName,
				call_date = cast(A.call_date AS date),
				call_date_time = A.call_date,
				A.CRMClientGUID,
				A.fio,
				A.external_id,
				A.Stage,
				A.ActionID,
				A.packageName,
				CommunicationTemplateId = CT.Id,
				CT.CommunicationType,
				CommunicationTypeName = T.Name
			FROM Stg._loginom.Collection_ActionID_history AS A --(NOLOCK)
				LEFT JOIN Stg._collection.CommunicationTemplate AS CT --(NOLOCK)
					ON CT.ExternalNumber = A.ActionID
				LEFT join stg._collection.CommunicationType AS T 
					ON T.Id = CT.CommunicationType
			WHERE A.call_date >= @call_date
		END
		
		CREATE INDEX ix_row_id ON #t_Collection_ActionID_history(row_id)
		CREATE INDEX ix_external_id ON #t_Collection_ActionID_history(external_id)
		CREATE INDEX ix_call_date ON #t_Collection_ActionID_history(call_date, external_id, CommunicationTemplateId)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Collection_ActionID_history
			SELECT * INTO ##t_Collection_ActionID_history FROM #t_Collection_ActionID_history
		END

		SELECT @min_call_date = min(A.call_date), @max_call_date = max(A.call_date)
		FROM #t_Collection_ActionID_history AS A

		-- набрать данные из _Collection.Communications
		DROP TABLE IF EXISTS #t_Communications
		SELECT
			CommunicationId = C.Id,
			CommunicationDate = cast(C.Date AS date),
			CommunicationDateTime = C.Date,
			C.CommunicationType,
			C.PhoneNumber,
			C.IdDeal,
			C.CommunicationTemplateId,
			CommunicationCommentary = cast(C.Commentary AS nvarchar(1000)),
			CommunicationResultName = cast(C.CommunicationResultName AS nvarchar(1000)),
			C.CommunicationResultId,
			C.NaumenCaseUuid,
			C.SessionId,
			C.EmployeeId,
			C.NaumenProjectId,
			NaumenCampaignName = cast(NULL AS nvarchar(255)),
			ActionID = cast(NULL AS nvarchar(255))
		INTO #t_Communications
		FROM Stg._Collection.Communications AS C
			--WITH(INDEX=ix_Date_CommunicationType)
		WHERE @min_call_date <= C.Date AND C.Date < dateadd(DAY, 1, @max_call_date)
			--AND C.CommunicationTemplateId IS NOT NULL

		CREATE INDEX ix_IdDeal ON #t_Communications(IdDeal)
		CREATE INDEX ix_CommunicationId ON #t_Communications(CommunicationId)
		CREATE INDEX ix_Date ON #t_Communications(CommunicationDate, CommunicationTemplateId)
		CREATE INDEX ix_NaumenProjectId ON #t_Communications(NaumenProjectId)

		UPDATE C
		SET C.NaumenCampaignName = N.Name, --ActionID (не всегда  точное совпадение!)
			C.ActionID = N.Name
		FROM #t_Communications AS C
			INNER JOIN Stg._Collection.NaumenCampaigns AS N
				ON N.NaumenUuid = C.NaumenProjectId
				-- !! дубли в таблице _Collection.NaumenCampaigns
				-- WHERE NaumenUuid = 'corebo00000000000mnvpah31jdpe1a0'
				AND N.Name NOT IN (
					'Обзвон Pre-del',
					'VoicePredel-Test'
				)

		--таблица соответствия ActionID и NaumenCampaign.Name
		DROP TABLE IF EXISTS #t_ActionID_NaumenCampaignName

		--CREATE TABLE #t_ActionID_NaumenCampaignName(
		--	ActionID nvarchar(255),
		--	NaumenCampaignName nvarchar(255)
		--)
		--INSERT #t_ActionID_NaumenCampaignName(ActionID, NaumenCampaignName)
		--VALUES
		--	('HardCall', 'Hard'),
		--	('HardCall_IL', 'Hard inst'),
		--	('MiddleCall_IL', 'Middle inst'),
		--	('SoftCall', 'Soft'),
		--	('SoftCall_IL', 'Soft inst'),
		--	('SoftCall_Probation', 'Soft Испытательный срок'),
		--	('VoicePredel', 'Автоинформатор Pre-del'),
		--	('VoicePredel_IL', 'Автоинформатор PRE-DEL inst')

		CREATE TABLE #t_ActionID_NaumenCampaignName(
			NaumenUuid nvarchar (255) NOT NULL,
			NaumenCampaignName nvarchar(255) NOT NULL,
			ActionID nvarchar(255) NOT NULL
		)

		INSERT #t_ActionID_NaumenCampaignName(NaumenUuid, NaumenCampaignName, ActionID)
		VALUES
			('corebo00000000000mree84ea5ek4sik','Collection (Middle)','MiddleCall'),
			('corebo00000000000mkhaol8egu7qgqs','Collection PreLegal','PreLegalCall'),
			('corebo00000000000mjapldk2nhr2tts','Collection (Soft)','SoftCall'),
			('corebo00000000000mkhao6h43hspdvs','Collection ve-lab (hard)','HardCall'),
			('corebo00000000000n07n38gnjo3h3ec','Collection ve-lab (hard mobile)','HardCall'),
			('corebo00000000000n2g36bbf5c4aia4','Collection Исполнительное Производство','EnforcementCall'),
			('corebo00000000000nqctpqd53jto42k','Hard inst','HardCall_IL'),
			('corebo00000000000nqb9d7odg0jh9fo','Middle inst','MiddleCall_IL'),
			('corebo00000000000oma2h4h83aivpnk','Middle PDL','CALL_ID_PDL_02'),
			('corebo00000000000nqb966k40luc60c','Pre-del inst','PredelCall_IL'),
			('corebo00000000000nc154qd1nrklf4k','Pre-del Испытательный срок','PredelCall_Probation'),
			('corebo00000000000naua4d1ul0s0cms','Pre-del КК','PredelCall_kk'),

			--('corebo00000000000mokdmrhl5oqlgks','Pre-del Обзвон','PredelCallsales, PredelCall'),
			('corebo00000000000mokdmrhl5oqlgks','Pre-del Обзвон','PredelCall'),

			('corebo00000000000nljhe0e52mf93o8','PreLegal 90-360','SoftCall_Client'),
			('corebo00000000000nqb9fskghgq1n00','Pre-legal inst','PreLegalCall_IL'),
			('corebo00000000000oma2j0ntl5dqvvc','Prelegal PDL','CALL_ID_PDL_03'),
			('corebo00000000000nqb9ahih5hni524','Soft inst','SoftCall_IL'),
			('corebo00000000000naua66dsh4sclvg','Soft KK','SoftCall_kk'),
			('corebo00000000000oma2dhd059va8vk','Soft PDL','CALL_ID_PDL_01'),
			('corebo00000000000o5id6ajcj3q7rik','Soft smart-inst','SMART_INST_CALL_01'),
			('corebo00000000000nc8n954bno3l1bs','Soft Испытательный срок','SoftCall_Probation'),
			('corebo00000000000nvdd1klvg6g0ta8','Автоинформатор Hard','VoiceHard'),
			('corebo00000000000oma30r3dkqt1s2c','Автоинформатор PDL middle','IVR_ID_PDL_02'),
			('corebo00000000000oma32c7760gg7v8','Автоинформатор PDL prelegal DPD<90','IVR_ID_PDL_03'),
			('corebo00000000000oma341r3lib9pb0','Автоинформатор PDL prelegal DPD>90','IVR_ID_PDL_04'),
			('corebo00000000000oma2rvof3nfdrd8','Автоинформатор PDL soft','IVR_ID_PDL_01'),
			('corebo00000000000mnvpah31jdpe1a0','Автоинформатор PRE-DEL','VoicePredel'),
			('corebo00000000000nqdsjunhn8c1dvo','Автоинформатор PRE-DEL inst','VoicePredel_IL'),

			('corebo00000000000ngh75f6lmvnqf7g','Автоинформатор PreLegal 90-360','PreLegal90360'),
			('corebo00000000000o5io1nsl6tk8fr8','Автоинформатор smart-inst_DueDate','SMART_INST_IVR_02'),
			('corebo00000000000o5ini75f4fitk3o','Автоинформатор smart-inst_PreDel','SMART_INST_IVR_01'),
			('corebo00000000000o5io3b3l2f1gs4c','Автоинформатор smart-inst_Soft','SMART_INST_IVR_03'),
			('corebo00000000000mreggg442gi15ko','Автоинформатор Обзвон','VoicePredel'), -- ,'PreDelDialing'),
			('corebo00000000000nqdsns1f2bambjs','Автоинформатор Обзвон inst','VoicePredel_IL'), -- ,'PreDelDialing_IL'),

			('corebo00000000000mpe86st372cgv1s','СКИП','Skip')
			--35

		UPDATE C
		SET C.ActionID = X.ActionID
		FROM #t_Communications AS C
			INNER JOIN #t_ActionID_NaumenCampaignName AS X
				--ON X.NaumenCampaignName = C.NaumenCampaignName
				ON X.NaumenUuid = C.NaumenProjectId

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Communications
			SELECT * INTO ##t_Communications FROM #t_Communications
		END

		-- 1 loginom есть CommunicationTemplateId (sms, email, push)
		DROP TABLE IF EXISTS #t_Communications_text
		SELECT 
			AD.row_id,
			C.CommunicationId,
			C.CommunicationDate,
			C.CommunicationDateTime,
			C.CommunicationType,
			CommunicationTypeName = CT.Name,
			C.PhoneNumber,
			C.IdDeal,
			C.CommunicationTemplateId,
			C.CommunicationCommentary,
			C.CommunicationResultName,

			C.CommunicationResultId,
			CR_Name = CR.Name,
			CR_Naumen = CR.Naumen,

			D.Number,
			D.IdCustomer,
			CUS.CrmCustomerId,
			CustomerFIO = concat_ws(' ', CUS.LastName, CUS.Name, CUS.MiddleName),
			external_communication_id = coalesce(nullif(M.ExternalId, ''), cast(C.CommunicationId as nvarchar(36))),
			EmployeeName = nullif(trim(cast(concat_ws(' ', E.LastName, E.FirstName, E.MiddleName) AS nvarchar(255))),''),
			C.NaumenProjectId,
			C.NaumenCampaignName,
			C.ActionID
		INTO #t_Communications_text
		FROM #t_Communications AS C
			INNER JOIN Stg._Collection.Deals AS D
				ON D.Id = C.IdDeal
			INNER JOIN #t_Collection_ActionID_history AS AD
				ON AD.call_date = C.CommunicationDate
				AND AD.external_id = D.Number
				AND AD.CommunicationTemplateId = C.CommunicationTemplateId
			LEFT JOIN Stg._Collection.customers AS CUS
				ON CUS.Id = D.IdCustomer
			LEFT JOIN Stg._Collection.Message AS M
				ON M.CommunicationId = C.CommunicationId
			LEFT JOIN Stg._Collection.CommunicationResult AS CR
				ON CR.Id = C.CommunicationResultId
			LEFT JOIN Stg._Collection.communicationType AS CT
				ON CT.Id = C.CommunicationType
			LEFT JOIN Stg._Collection.Employee AS E
				ON E.Id = C.EmployeeId
		WHERE C.CommunicationTemplateId IS NOT NULL

		CREATE INDEX ix_CommunicationId ON #t_Communications_text(CommunicationId)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Communications_text
			SELECT * INTO ##t_Communications_text FROM #t_Communications_text
		END


		-- 2 loginom нет CommunicationTemplateId (call)
		DROP TABLE IF EXISTS #t_Action_date_deal
		SELECT DISTINCT
			A.call_date,
			A.external_id,
			A.ActionID,
			rn = row_number() OVER(
				PARTITION BY A.call_date, A.external_id
				ORDER BY A.ActionID
			)
		INTO #t_Action_date_deal
		FROM #t_Collection_ActionID_history AS A
		WHERE A.CommunicationTemplateId IS NULL
			AND (charindex('call', A.ActionID) > 0
				OR charindex('ivr', A.ActionID) > 0
				OR A.ActionID IN ('VoicePredel', 'VoicePredel_IL')
			)

		CREATE INDEX ix_call_date ON #t_Action_date_deal(call_date, external_id)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Action_date_deal
			SELECT * INTO ##t_Action_date_deal FROM #t_Action_date_deal
		END


		DROP TABLE IF EXISTS #t_Communications_no_text
		SELECT DISTINCT
			C.CommunicationId,
			C.CommunicationDate,
			C.CommunicationDateTime,
			C.CommunicationType,
			CommunicationTypeName = CT.Name,
			C.PhoneNumber,
			C.IdDeal,
			C.CommunicationTemplateId,
			C.CommunicationCommentary,
			C.CommunicationResultName,

			C.CommunicationResultId,
			CR_Name = CR.Name,
			CR_Naumen = CR.Naumen,

			D.Number,
			D.IdCustomer,
			CUS.CrmCustomerId,
			CustomerFIO = concat_ws(' ', CUS.LastName, CUS.Name, CUS.MiddleName),
			--external_communication_id = coalesce(nullif(M.ExternalId, ''), cast(C.CommunicationId as nvarchar(36)))
			C.NaumenCaseUuid,
			C.SessionId,
			EmployeeName = nullif(trim(cast(concat_ws(' ', E.LastName, E.FirstName, E.MiddleName) AS nvarchar(255))),''),
			C.NaumenProjectId,
			C.NaumenCampaignName,
			C.ActionID,
			rn1 = cast(NULL AS int),
			rn2 = cast(NULL AS int)
		INTO #t_Communications_no_text
		FROM #t_Communications AS C
			INNER JOIN Stg._Collection.Deals AS D
				ON D.Id = C.IdDeal
			INNER JOIN #t_Action_date_deal AS AD
				ON AD.call_date = C.CommunicationDate
				AND AD.external_id = D.Number
			INNER JOIN Stg._Collection.communicationType AS CT
				ON CT.Id = C.CommunicationType
				AND CT.Name IN (
					'Исходящий звонок',
					'Автоинформатор pre-del',
					'Автоинформатор Pre-legal'
				)
				--AND (
				--	((charindex('call', AD.ActionID) > 0 OR charindex('ivr', AD.ActionID) > 0)
				--	AND CT.Name IN ('Исходящий звонок'))
				--	OR 
				--	(AD.ActionID IN ('VoicePredel')
				--	AND CT.Name IN ('Автоинформатор pre-del'))
				--	OR 
				--	(AD.ActionID IN ('VoicePredel_IL')
				--	AND CT.Name IN ('Автоинформатор Pre-legal'))
				--)
			LEFT JOIN Stg._Collection.customers AS CUS
				ON CUS.Id = D.IdCustomer
			--LEFT JOIN Stg._Collection.Message AS M
			--	ON M.CommunicationId = C.CommunicationId
			LEFT JOIN Stg._collection.CommunicationResult AS CR
				ON CR.Id = C.CommunicationResultId
			LEFT JOIN Stg._Collection.Employee AS E
				ON E.Id = C.EmployeeId
		WHERE 1=1
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_Communications_text AS X
				WHERE X.CommunicationId = C.CommunicationId
			)

		CREATE INDEX ix_CommunicationId ON #t_Communications_no_text(CommunicationId)

		UPDATE T SET T.rn1 = A.rn
		FROM #t_Communications_no_text AS T
			INNER JOIN (
				SELECT 
					C.CommunicationId,
					rn = row_number() OVER(
						PARTITION BY C.CommunicationDate, C.Number
						ORDER BY C.CommunicationId
					)
				FROM #t_Communications_no_text AS C
			) AS A
			ON A.CommunicationId = T.CommunicationId

		--var 1
		/*
		UPDATE C SET rn2 = AD.rn
		FROM #t_Communications_no_text AS C
			LEFT JOIN #t_Action_date_deal AS AD
				ON AD.call_date = C.CommunicationDate
				AND AD.external_id = C.Number
				AND (
					((charindex('call', AD.ActionID) > 0 OR charindex('ivr', AD.ActionID) > 0)
					AND C.CommunicationTypeName IN ('Исходящий звонок'))
					OR 
					(AD.ActionID IN ('VoicePredel')
					AND C.CommunicationTypeName IN ('Автоинформатор pre-del'))
					OR 
					(AD.ActionID IN ('VoicePredel_IL')
					AND C.CommunicationTypeName IN ('Автоинформатор Pre-legal'))
				)
				AND C.rn1 = AD.rn
		*/

		DROP TABLE IF EXISTS #t_no_text_step1
		CREATE TABLE #t_no_text_step1(
			CommunicationDate date,
			Number nvarchar(255)
		)

		--var 2
		--дополнить еще логику для CALL. Необходимо смотреть на таблицу 
		--stg._Collection.NaumenCampaigns там есть поле Name = > ActionID
		--с таблицы NaumenCampaigns получаем NaumenUuid, который равен = Communications.NaumenProjectId
		--так более точно получится сопоставить данные со звонками
		UPDATE C SET rn2 = AD.rn
		OUTPUT Inserted.CommunicationDate, Inserted.Number 
		INTO #t_no_text_step1
		FROM #t_Communications_no_text AS C
			INNER JOIN #t_Action_date_deal AS AD
				ON AD.call_date = C.CommunicationDate
				AND AD.external_id = C.Number
				--AND (
				--	((charindex('call', AD.ActionID) > 0 OR charindex('ivr', AD.ActionID) > 0)
				--	AND C.CommunicationTypeName IN ('Исходящий звонок'))
				--	OR 
				--	(AD.ActionID IN ('VoicePredel')
				--	AND C.CommunicationTypeName IN ('Автоинформатор pre-del'))
				--	OR 
				--	(AD.ActionID IN ('VoicePredel_IL')
				--	AND C.CommunicationTypeName IN ('Автоинформатор Pre-legal'))
				--)
				AND AD.ActionID = C.ActionID --NaumenCampaignName
		
		CREATE INDEX ix1 ON #t_no_text_step1(CommunicationDate, Number)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_no_text_step1
			SELECT * INTO ##t_no_text_step1 FROM #t_no_text_step1
		END

		-- привязать оставшиеся звонки
		UPDATE C SET rn2 = AD.rn
		FROM #t_Communications_no_text AS C
			INNER JOIN #t_Action_date_deal AS AD
				ON AD.call_date = C.CommunicationDate
				AND AD.external_id = C.Number
				--AND (
				--	((charindex('call', AD.ActionID) > 0 OR charindex('ivr', AD.ActionID) > 0)
				--	AND C.CommunicationTypeName IN ('Исходящий звонок'))
				--	OR 
				--	(AD.ActionID IN ('VoicePredel')
				--	AND C.CommunicationTypeName IN ('Автоинформатор pre-del'))
				--	OR 
				--	(AD.ActionID IN ('VoicePredel_IL')
				--	AND C.CommunicationTypeName IN ('Автоинформатор Pre-legal'))
				--)
				AND C.rn1 = AD.rn
		WHERE C.rn2 IS NULL
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_no_text_step1 AS X
				WHERE X.CommunicationDate = C.CommunicationDate
					AND X.Number = C.Number
			)


		-- пока comment
		/*
		UPDATE T
		SET rn2 = A.max_rn2
		FROM #t_Communications_no_text AS T
			INNER JOIN (
					SELECT 
						C.CommunicationDate, 
						C.Number, 
						max_rn2 = max(C.rn2) 
					FROM #t_Communications_no_text AS C
					WHERE C.rn2 IS NOT NULL
					GROUP BY C.CommunicationDate, C.Number
			) AS A
				ON A.CommunicationDate = T.CommunicationDate
				AND A.Number = T.Number
				AND T.rn2 IS NULL
		*/

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Communications_no_text
			SELECT * INTO ##t_Communications_no_text FROM #t_Communications_no_text
		END


		-- 3 no loginom
		DROP TABLE IF EXISTS #t_Communications_no_loginom
		SELECT 
			--row_id = cast(NULL AS int),
			C.CommunicationId,
			C.CommunicationDate,
			C.CommunicationDateTime,
			C.CommunicationType,
			CommunicationTypeName = CT.Name,
			C.PhoneNumber,
			C.IdDeal,
			C.CommunicationTemplateId,
			C.CommunicationCommentary,
			C.CommunicationResultName,

			C.CommunicationResultId,
			CR_Name = CR.Name,
			CR_Naumen = CR.Naumen,

			D.Number,
			D.IdCustomer,
			CUS.CrmCustomerId,
			CustomerFIO = concat_ws(' ', CUS.LastName, CUS.Name, CUS.MiddleName),
			external_communication_id = coalesce(nullif(M.ExternalId, ''), cast(C.CommunicationId as nvarchar(36))),
			C.NaumenCaseUuid,
			C.SessionId,
			EmployeeName = nullif(trim(cast(concat_ws(' ', E.LastName, E.FirstName, E.MiddleName) AS nvarchar(255))),''),
			C.NaumenProjectId,
			C.NaumenCampaignName,
			C.ActionID
		INTO #t_Communications_no_loginom
		FROM #t_Communications AS C
			INNER JOIN Stg._Collection.Deals AS D
				ON D.Id = C.IdDeal
			LEFT JOIN Stg._Collection.customers AS CUS
				ON CUS.Id = D.IdCustomer
			LEFT JOIN Stg._Collection.Message AS M
				ON M.CommunicationId = C.CommunicationId
			LEFT JOIN Stg._Collection.CommunicationResult AS CR
				ON CR.Id = C.CommunicationResultId
			LEFT JOIN Stg._Collection.communicationType AS CT
				ON CT.Id = C.CommunicationType
			LEFT JOIN Stg._Collection.Employee AS E
				ON E.Id = C.EmployeeId
		WHERE 1=1
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_Communications_text AS X
				WHERE X.CommunicationId = C.CommunicationId
			)
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_Communications_no_text AS Y
				WHERE Y.CommunicationId = C.CommunicationId
			)


		CREATE INDEX ix_CommunicationId ON #t_Communications_no_loginom(CommunicationId)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Communications_no_loginom
			SELECT * INTO ##t_Communications_no_loginom FROM #t_Communications_no_loginom
		END



		DROP TABLE IF EXISTS #t_dm_loginom_interaction
		CREATE TABLE #t_dm_loginom_interaction
		(
			created_at datetime ,
			row_id bigint ,
			userName nvarchar (500) ,
			call_date date ,
			call_date_time datetime ,
			CRMClientGUID nvarchar (50) ,
			fio nvarchar (1024) ,
			external_id nvarchar (50) ,
			Stage nvarchar (50) ,
			ActionID nvarchar (50) ,
			packageName nvarchar (500) ,
			CommunicationTemplateId int ,
			CommunicationTemplateTheme nvarchar (1024) ,
			CommunicationTemplateName nvarchar (1024) ,
			Communication_count int ,
			CommunicationId int ,
			CommunicationDateTime datetime2 ,
			CommunicationType int,
			CommunicationTypeName nvarchar (255) ,
			PhoneNumber nvarchar (255) ,
			CommunicationCommentary nvarchar (1000) ,
			CommunicationResultName nvarchar (1000) ,
			CommunicationResultId int,
			CR_Name nvarchar (256) ,
			CR_Naumen nvarchar (256) ,
			CustomerFIO nvarchar (502) ,
			external_communication_id nvarchar (255) ,
			NaumenCaseUuid nvarchar (255) ,
			SessionId nvarchar (256),
			External_Stage nvarchar(50),
			ProductType nvarchar(50),
			EmployeeName nvarchar(255),
			NaumenProjectId nvarchar(255),
			NaumenCampaignName nvarchar(255),
			isContact int NOT NULL DEFAULT(0)
		)

		--1 loginom text
		INSERT #t_dm_loginom_interaction
		(
			created_at,
		    row_id,
		    userName,
		    call_date,
		    call_date_time,
		    CRMClientGUID,
		    fio,
		    external_id,
		    Stage,
		    ActionID,
		    packageName,
		    CommunicationTemplateId,
			CommunicationTemplateTheme,
			CommunicationTemplateName,
			Communication_count,
		    CommunicationId,
		    CommunicationDateTime,
			CommunicationType,
		    CommunicationTypeName,
		    PhoneNumber,
			CommunicationCommentary,
			CommunicationResultName,
			CommunicationResultId,
		    CR_Name,
		    CR_Naumen,
			CustomerFIO,
			external_communication_id,
			NaumenCaseUuid,
			SessionId,
			EmployeeName,
			NaumenProjectId,
			NaumenCampaignName
		)
		SELECT 
			created_at = getdate(),
			A.row_id,
			A.userName,
			A.call_date,
			A.call_date_time,
			A.CRMClientGUID,
			A.fio,
			A.external_id,
			A.Stage,
			A.ActionID,
			A.packageName,
			A.CommunicationTemplateId,
			CommunicationTemplateTheme = CT.Theme,
			CommunicationTemplateName = CT.TemplateName,
			--
			Communication_count = cast(iif(C.CommunicationId IS NOT NULL, 1, 0) AS int),
			--
			C.CommunicationId,
			--C.CommunicationDate,
			C.CommunicationDateTime,
			CommunicationType = isnull(C.CommunicationType, A.CommunicationType),
			CommunicationTypeName = isnull(C.CommunicationTypeName, A.CommunicationTypeName),
			C.PhoneNumber,
			--C.IdDeal,
			--C.CommunicationTemplateId,
			C.CommunicationCommentary,
			C.CommunicationResultName,
			C.CommunicationResultId,
			C.CR_Name,
			C.CR_Naumen,
			--Commentary = cast(NULL AS nvarchar(1000)),
			--C.Number,
			--C.IdCustomer,
			--C.CrmCustomerId,
			C.CustomerFIO,
			C.external_communication_id,
			NaumenCaseUuid = cast(NULL AS nvarchar(255)),
			SessionId = cast(NULL AS nvarchar(256)),
			C.EmployeeName,
			C.NaumenProjectId,
			C.NaumenCampaignName
		FROM #t_Collection_ActionID_history AS A
			LEFT JOIN #t_Communications_text AS C
				ON C.row_id = A.row_id
			LEFT JOIN Stg._Collection.CommunicationTemplate AS CT
				ON CT.Id = A.CommunicationTemplateId
		WHERE A.CommunicationTemplateId IS NOT NULL



		--2 loginom no text

		--определить группы коммуникаций и макс. по дате в каждой группе
		DROP TABLE IF EXISTS #t_Communications_no_text_group
		;WITH 
		Communication_group AS (
			SELECT 
				CM.CommunicationId,
				CM.CommunicationDate,
				CM.CommunicationType,
				CM.Number,
				CM.rn2,
				rn = row_number() OVER(
					PARTITION BY CM.CommunicationDate, CM.CommunicationType, CM.Number, CM.rn2
					ORDER BY CM.CommunicationDateTime DESC
					)
				FROM #t_Communications_no_text AS CM
			),
		Communication_cnt AS (
			SELECT 
				G.CommunicationDate,
				G.CommunicationType,
				G.Number,
				G.rn2,
				Communication_count = count(*)
			FROM Communication_group AS G
			GROUP BY 
				G.CommunicationDate,
				G.CommunicationType,
				G.Number,
				G.rn2
		)
		SELECT  
			M.CommunicationId,
			M.CommunicationDate,
			M.CommunicationType,
			M.Number,
			M.rn2,
			C.Communication_count
		INTO #t_Communications_no_text_group
		FROM Communication_group AS M
			INNER JOIN Communication_cnt AS C
				ON C.CommunicationDate = M.CommunicationDate
				AND C.CommunicationType = M.CommunicationType
				AND C.Number = M.Number
				AND C.rn2 = M.rn2
		WHERE M.rn = 1

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Communications_no_text_group
			SELECT * INTO ##t_Communications_no_text_group FROM #t_Communications_no_text_group
		END


		INSERT #t_dm_loginom_interaction
		(
			created_at,
		    row_id,
		    userName,
		    call_date,
		    call_date_time,
		    CRMClientGUID,
		    fio,
		    external_id,
		    Stage,
		    ActionID,
		    packageName,
		    CommunicationTemplateId,
			CommunicationTemplateTheme,
			CommunicationTemplateName,
			Communication_count,
		    CommunicationId,
		    CommunicationDateTime,
			CommunicationType,
		    CommunicationTypeName,
		    PhoneNumber,
			CommunicationCommentary,
			CommunicationResultName,
			CommunicationResultId,
		    CR_Name,
		    CR_Naumen,
			--Commentary,
			CustomerFIO,
			external_communication_id,
			NaumenCaseUuid,
			SessionId,
			EmployeeName,
			NaumenProjectId,
			NaumenCampaignName
		)
		SELECT 
			created_at = getdate(),
			A.row_id,
			A.userName,
			A.call_date,
			A.call_date_time,
			A.CRMClientGUID,
			A.fio,
			A.external_id,
			A.Stage,
			A.ActionID,
			A.packageName,
			--A.CommunicationTemplateId,
			C.CommunicationTemplateId,
			--CommunicationTemplateTheme = cast(NULL AS nvarchar(1024)),
			CommunicationTemplateTheme = CT.Theme,
			--CommunicationTemplateName = cast(NULL AS nvarchar(1024)),
			CommunicationTemplateName = CT.TemplateName,

			--Communication_count = cast(isnull(M.Communication_count, 0) AS int),
			Communication_count = cast(isnull(G.Communication_count, 0) AS int),

			C.CommunicationId,
			--C.CommunicationDate,
			C.CommunicationDateTime,
			CommunicationType = isnull(C.CommunicationType, A.CommunicationType),
			CommunicationTypeName = isnull(C.CommunicationTypeName, A.CommunicationTypeName),
			C.PhoneNumber,
			--C.IdDeal,
			--C.CommunicationTemplateId,
			C.CommunicationCommentary,
			C.CommunicationResultName,
			C.CommunicationResultId,
			C.CR_Name,
			C.CR_Naumen,
			--Commentary = cast(NULL AS nvarchar(1000)),
			--C.Number,
			--C.IdCustomer,
			--C.CrmCustomerId,
			C.CustomerFIO,
			external_communication_id = cast(NULL AS nvarchar(36)),
			C.NaumenCaseUuid,
			C.SessionId,
			C.EmployeeName,
			C.NaumenProjectId,
			C.NaumenCampaignName
		FROM #t_Collection_ActionID_history AS A
			LEFT JOIN (
				--привязываем CommunicationId к наименьшему подходящему row_id
				SELECT 
					G2.CommunicationId,
					G2.Communication_count,
					G2.rn2,
					row_id = min(A2.row_id) 
				FROM #t_Collection_ActionID_history AS A2
					INNER JOIN #t_Action_date_deal AS A3
						ON A3.ActionID = A2.ActionID
						AND A3.call_date = A2.call_date
						AND A3.external_id = A2.external_id
					LEFT JOIN #t_Communications_no_text_group AS G2
						ON A2.call_date = G2.CommunicationDate
						AND A2.external_id = G2.Number
						AND G2.rn2 = A3.rn
				GROUP BY G2.CommunicationId, G2.Communication_count, G2.rn2
			) AS G
				ON G.row_id = A.row_id
			LEFT JOIN #t_Communications_no_text AS C
				ON C.CommunicationId = G.CommunicationId
			LEFT JOIN Stg._Collection.CommunicationTemplate AS CT
				ON CT.Id = C.CommunicationTemplateId
		WHERE A.CommunicationTemplateId IS NULL


		--3 no loginom
		IF @action_row_id IS NULL BEGIN
			INSERT #t_dm_loginom_interaction
			(
				created_at,
				row_id,
				userName,
				call_date,
				call_date_time,
				CRMClientGUID,
				fio,
				external_id,
				Stage,
				ActionID,
				packageName,
				CommunicationTemplateId,
				CommunicationTemplateTheme,
				CommunicationTemplateName,
				Communication_count,
				CommunicationId,
				CommunicationDateTime,
				CommunicationType,
				CommunicationTypeName,
				PhoneNumber,
				CommunicationCommentary,
				CommunicationResultName,
				CommunicationResultId,
				CR_Name,
				CR_Naumen,
				--Commentary,
				CustomerFIO,
				external_communication_id,
				NaumenCaseUuid,
				SessionId,
				EmployeeName,
				NaumenProjectId,
				NaumenCampaignName
			)
			SELECT 
				created_at = getdate(),
				row_id = NULL,
				userName = NULL,
				call_date = C.CommunicationDate,
				call_date_time = NULL,
				CRMClientGUID = NULL,
				fio = C.CustomerFIO,
				external_id = C.Number,
				Stage = NULL,
				ActionID = NULL,
				packageName = NULL,
				C.CommunicationTemplateId,
				CommunicationTemplateTheme = CT.Theme,
				CommunicationTemplateName = CT.TemplateName,
				--
				Communication_count = cast(iif(C.CommunicationId IS NOT NULL, 1, 0) AS int),
				--
				C.CommunicationId,
				--C.CommunicationDate,
				C.CommunicationDateTime,
				C.CommunicationType,
				C.CommunicationTypeName,
				C.PhoneNumber,
				--C.IdDeal,
				--C.CommunicationTemplateId,
				C.CommunicationCommentary,
				C.CommunicationResultName,
				C.CommunicationResultId,
				C.CR_Name,
				C.CR_Naumen,
				--Commentary = cast(NULL AS nvarchar(1000)),
				--C.Number,
				--C.IdCustomer,
				--C.CrmCustomerId,
				C.CustomerFIO,
				C.external_communication_id,
				NaumenCaseUuid = cast(NULL AS nvarchar(255)),
				SessionId = cast(NULL AS nvarchar(256)),
				C.EmployeeName,
				C.NaumenProjectId,
				C.NaumenCampaignName
			FROM #t_Communications_no_loginom AS C
				LEFT JOIN Stg._Collection.CommunicationTemplate AS CT
					ON CT.Id = C.CommunicationTemplateId
		END

				
		DELETE I
		FROM #t_dm_loginom_interaction AS I
		WHERE I.CR_Name = 'Оплачено'

		UPDATE I
		SET CommunicationTypeName = 
			CASE 
				WHEN charindex('call', I.ActionID) > 0 OR charindex('ivr', I.ActionID) > 0
					THEN 'Исходящий звонок'
				WHEN charindex('SMS', I.ActionID) > 0
					THEN 'Смс'
				WHEN charindex('EMAIL', I.ActionID) > 0
					THEN 'E-mail'
				WHEN I.ActionID IN ('VoicePredel')
					THEN 'Автоинформатор pre-del'
				WHEN I.ActionID IN ('VoicePredel_IL')
					--THEN 'Автоинформатор Pre-legal'
					THEN 'Автоинформатор pre-del'
				ELSE NULL
			END
		FROM #t_dm_loginom_interaction AS I
		WHERE I.CommunicationTypeName IS NULL


		CREATE INDEX ix_row_id ON #t_dm_loginom_interaction(row_id)
		CREATE INDEX ix_CommunicationId ON #t_dm_loginom_interaction(CommunicationId)
		CREATE INDEX ix_external_id ON #t_dm_loginom_interaction(external_id, call_date)


		--стадия по договору на дату взаимодействия
		UPDATE I
		SET External_Stage = ES.External_Stage
		FROM #t_dm_loginom_interaction AS I
			INNER JOIN Stg._loginom.Collection_External_Stage_history AS ES
				ON ES.external_id = I.external_id
				AND ES.call_dt = I.call_date

		-- писать null если стадия не нашлась
		/*
		DROP TABLE IF EXISTS #t_External_Stage_IS_NULL

		SELECT I.external_id, I.call_date
		INTO #t_External_Stage_IS_NULL
		FROM #t_dm_loginom_interaction AS I
		WHERE I.External_Stage IS NULL

		IF EXISTS(SELECT TOP(1) 1 FROM #t_External_Stage_IS_NULL)
		BEGIN
			CREATE INDEX ix_external_id ON #t_External_Stage_IS_NULL(external_id, call_date)
		    
			UPDATE I
			SET External_Stage = S.External_Stage
			FROM (
					SELECT 
						N.external_id, 
						N.call_date,
						max_call_dt = max(ES.call_dt)
					FROM #t_External_Stage_IS_NULL AS N
						INNER JOIN Stg._loginom.Collection_External_Stage_history AS ES
							ON ES.external_id = N.external_id
							AND ES.call_dt < N.call_date
					GROUP BY
						N.external_id, 
						N.call_date
				) AS A
				INNER JOIN Stg._loginom.Collection_External_Stage_history AS S
					ON S.external_id = A.external_id
					AND S.call_dt = A.max_call_dt
				INNER JOIN #t_dm_loginom_interaction AS I
					ON I.external_id = A.external_id
					AND I.call_date = A.call_date
		END
		*/

		-- ТипПродукта
		UPDATE I
		SET ProductType = D.ТипПродукта
		FROM #t_dm_loginom_interaction AS I
			INNER JOIN dwh2.hub.ДоговорЗайма AS D
				ON D.КодДоговораЗайма = I.external_id


		--UPDATE D
		--SET	D.Commentary = cast(M.Commentary AS nvarchar(1000))
		--FROM #t_dm_loginom_interaction AS D
		--	INNER JOIN Stg._Collection.mv_Communications AS M
		--		ON M.id_1 = D.CommunicationId

		--isContact
		DROP TABLE IF EXISTS #t_CommunicationTypeCall_with_CommunicationResult_take230FZ

		select DISTINCT
			--id =  newid()
			CommunicationTypeId = ct.ID
			, CommunicationTypeName =ct.Name
			, CommunicationTypeDateFrom = acts.DateFrom
			, CommunicationResultId = cr.Id
			, CommunicationResultName = cr.Name
			, CommunicationResultDateFrom = arcts.DateFrom
		into #t_CommunicationTypeCall_with_CommunicationResult_take230FZ
		from stg._Collection.ContactTypeCounterSmds Contact_tc
			inner join stg._collection.CommunicationTypeCounterSmds AS Communication_tc
				ON Communication_tc.ContactTypeCounterId = Contact_tc.Id
			inner join stg._Collection.AccountingCommunicationTypeSpace AS acts
				ON acts.CommunicationTypeCounterSmdsId = Communication_tc.Id
			inner join stg._Collection.CommunicationType AS ct
				ON ct.Id = acts.CommunicationTypeId
			left join stg._Collection.CommunicationTypeCounterSmds AS Communication_tc_230fz
				on Communication_tc_230fz.Code = 'take230FZ'
			left join stg._Collection.AccountingResultCommunicationTypeSpace AS arcts
				on arcts.CommunicationTypeCounterSmdsId = Communication_tc_230fz.Id
			left join stg._Collection.CommunicationResult AS cr
				ON cr.Id =arcts.CommunicationResultId
		where Contact_tc.Code = 'calls'

		UPDATE D
		SET D.isContact = 1
		FROM #t_dm_loginom_interaction AS D
			INNER JOIN #t_CommunicationTypeCall_with_CommunicationResult_take230FZ AS X
				ON X.CommunicationTypeId = D.CommunicationType
				AND X.CommunicationResultId = D.CommunicationResultId

		--Мария Блинчевская: Можно VoicePredel_IL в "Автоинформатор pre-del" запарковать?
		UPDATE D
		SET CommunicationType = iif(D.CommunicationType IS NOT NULL, 7, NULL),
			CommunicationTypeName = 'Автоинформатор pre-del'
		FROM #t_dm_loginom_interaction AS D
		where D.ActionID = 'VoicePredel_IL'

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_dm_loginom_interaction
			SELECT * INTO ##t_dm_loginom_interaction FROM #t_dm_loginom_interaction
		END

		if OBJECT_ID('Risk.dm_loginom_interaction') is null
		BEGIN
			SELECT TOP 0 *
			INTO Risk.dm_loginom_interaction
			FROM #t_dm_loginom_interaction AS D

			CREATE INDEX ix_row_id
			ON Risk.dm_loginom_interaction(row_id)

			CREATE INDEX ix_call_date
			ON Risk.dm_loginom_interaction(call_date)
        END


		if exists(select top(1) 1 from #t_dm_loginom_interaction)
		BEGIN
			BEGIN TRAN
				DELETE D
				FROM Risk.dm_loginom_interaction D
					INNER JOIN #t_dm_loginom_interaction AS I
						ON I.row_id = D.row_id

				DELETE D
				FROM Risk.dm_loginom_interaction D
					INNER JOIN #t_dm_loginom_interaction AS I
						ON I.CommunicationId = D.CommunicationId

				INSERT Risk.dm_loginom_interaction
				(
					created_at,
					row_id,
					userName,
					call_date,
					call_date_time,
					CRMClientGUID,
					fio,
					external_id,
					Stage,
					ActionID,
					packageName,
					CommunicationTemplateId,
					CommunicationTemplateTheme,
					CommunicationTemplateName,
					Communication_count,
					CommunicationId,
					CommunicationDateTime,
					CommunicationType,
					CommunicationTypeName,
					PhoneNumber,
					CommunicationCommentary,
					CommunicationResultName,
					CommunicationResultId,
					CR_Name,
					CR_Naumen,
					CustomerFIO,
					external_communication_id,
					NaumenCaseUuid,
					SessionId,
					External_Stage,
					ProductType,
					EmployeeName,
					NaumenProjectId,
					NaumenCampaignName,
					isContact
				)
				SELECT 
					D.created_at,
					D.row_id,
					D.userName,
					D.call_date,
					D.call_date_time,
					D.CRMClientGUID,
					D.fio,
					D.external_id,
					D.Stage,
					D.ActionID,
					D.packageName,
					D.CommunicationTemplateId,
					D.CommunicationTemplateTheme,
					D.CommunicationTemplateName,
					D.Communication_count,
					D.CommunicationId,
					D.CommunicationDateTime,
					D.CommunicationType,
					D.CommunicationTypeName,
					D.PhoneNumber,
					D.CommunicationCommentary,
					D.CommunicationResultName,
					D.CommunicationResultId,
					D.CR_Name,
					D.CR_Naumen,
					D.CustomerFIO,
					D.external_communication_id,
					D.NaumenCaseUuid,
					D.SessionId,
					D.External_Stage,
					D.ProductType,
					D.EmployeeName,
					D.NaumenProjectId,
					D.NaumenCampaignName,
					D.isContact
				FROM #t_dm_loginom_interaction AS D


			COMMIT
		END

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END

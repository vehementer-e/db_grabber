-- ============================================= 
-- Author: А. Никитин
-- Create date: 25.10.2022
-- Description: DWH-1792 Общая витрина
-- ============================================= 
CREATE   PROC dm.Fill_Installment_SmartInstallment
	@ProcessGUID uniqueidentifier = NULL,
	@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	SET @ProcessGUID = isnull(@ProcessGUID, newid())

	IF @isDebug = 1 BEGIN
		SELECT @ProcessGUID                    
	END

	DECLARE @InsertRows int = 0, @DeleteRows int = 0, @TempRows int = 0
	DECLARE @StartDate datetime, @DurationSec int
	declare @error_description nvarchar(1024)
	--DECLARE @Max_Дата datetime, @Insert_Дата datetime
	DECLARE @Max_DWHInsertedDate datetime
	DECLARE @description nvarchar(1024), @message nvarchar(1024)

	BEGIN TRY
		SELECT @StartDate = getdate()

		DROP TABLE IF EXISTS #t_dm_Installment
		CREATE TABLE #t_dm_Installment
		(
		--DWHInsertedDate datetime, --Дата создания записи в dwh
		--ЗаявкаСсылка binary(16), --ИД заявки
		external_id nvarchar(30), --Номер заявки
		Тип_займа_итоговый nvarchar(50), --Тип беззалогового займа итоговый (Installment/SmartInstallment)
		Марка nvarchar(255), --Марка
		Модель nvarchar(255), --Модель
		IMEI nvarchar(50), --IMEI
		Наличие_установленного_ПО nvarchar(50), --Наличие установленного ПО
		Актуальный_статус_устройства nvarchar(50), --Актуальный статус устройства
		ОС nvarchar(255), --ОС
		Версия_ОС nvarchar(255), --Версия ОС
		Заполнена_короткая_анкета datetime, --Заполнена короткая анкета
		Подписание_1_го_пакета_документов datetime, --Подписание 1-го пакета документов
		Заполнена_информация_о_себе datetime, --Заполнена информация о себе
		Заполнена_информация_о_работе datetime, --Заполнена информация о работе
		Заполнена_информация_о_доходе datetime, --Заполнена информация о доходе
		Одобрение_на_Логиноме_на_Call1 datetime, --Одобрение на Логиноме на Call1
		Отказ_на_Логиноме_на_Call1 datetime, --Отказ на Логиноме на Call1
		Тип_беззалогового_займа_Call1 nvarchar(50), --Тип беззалогового займа Call1
		Клиент_прикрепляет_фото datetime, --Клиент прикрепляет фото
		Клиент_прикрепляет_фото_IMEI datetime, --Клиент прикрепляет фото IMEI
		IMEI_автоматически_распознан datetime, --IMEI автоматически распознан
		IMEI_автоматически_не_распознан datetime, --IMEI автоматически не распознан
		IMEI_распознан_после_ручной_проверки datetime, --IMEI распознан после ручной проверки
		Клиент_вводит_данные_банковской_карты datetime, --Клиент вводит данные банковской карты
		Контроль_данных datetime, --Контроль данных (Статус CRM)
		Одобрение_на_Логиноме_на_Call1_5 datetime, --Одобрение на Логиноме на Call1.5
		Отказ_на_Логиноме_на_Call1_5 datetime, --Отказ на Логиноме на Call1.5
		Тип_беззалогового_займа_Call1_5 nvarchar(50), --Тип беззалогового займа Call1.5
		Одобрение_на_Логиноме_на_Call2 datetime, --Одобрение на Логиноме на Call2
		Отказ_на_Логиноме_на_Call2 datetime, --Отказ на Логиноме на Call2
		Тип_беззалогового_займа_Call2 nvarchar(50), --Тип беззалогового займа Call2
		Одобрение_на_Логиноме_на_Call3 datetime, --Одобрение на Логиноме на Call3
		Отказ_на_Логиноме_на_Call3 datetime, --Отказ на Логиноме на Call3
		Тип_беззалогового_займа_Call3 nvarchar(50), --Тип беззалогового займа Call3
		Клиент_получает_одобрение datetime, --Клиент получает одобрение (Статус CRM)
		Клиент_выбирает_предложение datetime, --Клиент выбирает предложение
		Клиент_соглашается_на_установку_МДМ datetime, --Клиент соглашается на установку МДМ
		Клиент_подписывает_согласие_на_установку_ПЭП datetime, --Клиент подписывает согласие на установку ПЭП
		Отказ_Клиента_на_установку_ПО datetime, --Отказ (клиент не согласен на установку ПО)
		Клиент_запускает_установку_МДМ datetime, --Клиент запускает установку МДМ
		Клиент_завершил_установку_ПО_успешно datetime, --Клиент завершил процесс установки ПО (успешная установка)
		Клиент_завершил_установку_ПО_НЕ_успешно datetime, --Клиент завершил процесс установки ПО (не успешная установка)
		Клиент_начал_установку_ПО_повторно datetime, --Клиент начал установку ПО повторно
		Клиент_завершил_повторную_установку_ПО_успешно datetime, --Клиент завершил повторный процесс установки ПО (успешная установка)
		Клиент_завершил_повторную_установку_ПО_НЕ_успешно datetime, --Клиент завершил повторный процесс установки ПО (не успешная установка)
		Выдача_Инстолмента_при_неуспешной_установке datetime, --Выдача Инстолмента при неуспешной установке по нашей вине
		Окирпичивание_телефона datetime, --Окирпичивание телефона
		Аннулирование_заявки_при_отказе_от_установки_в_процессе_установки datetime, --Аннулирование заявки при отказе от установки в процессе установки
		Клиент_перешел_на_экран_выбора_предложения_повторно datetime, --Клиент перешел на экран выбора предложения повторно (сменились сутки)
		Подписание_2_го_пакета_документов datetime, --Клиент подписывает 2й пакет документов
		Клиент_получает_деньги datetime, --Клиент получает деньги (Статус CRM - Заем выдан) 
		Клиент_выходит_в_просрочку datetime, --Клиент выходит в просрочку
		Клиент_подписывает_согласие_на_взаимодействие_с_телефоном datetime, --Клиент подписывает согласие на взаимодействие с телефоном
		Клиент_не_подписывает_согласие_на_взаимодействие_с_телефоном bit --Клиент не подписывает согласие на взаимодействие с телефоном
		)

		SELECT @Max_DWHInsertedDate = isnull(max(I.DWHInsertedDate), '2000-01-01')
		FROM dm.Installment_SmartInstallment AS I

		--test
		--SELECT @Max_DWHInsertedDate = dateadd(DAY, -1, @Max_DWHInsertedDate)
		SELECT @Max_DWHInsertedDate = dateadd(HOUR, -1, @Max_DWHInsertedDate)

		DROP TABLE IF EXISTS #t_external_id
		CREATE TABLE #t_external_id
		(
			--ЗаявкаСсылка binary(16), --ИД заявки
			external_id nvarchar(30) PRIMARY KEY, --Номер заявки
			Тип_займа_итоговый nvarchar(50) --Тип беззалогового займа итоговый (Installment/SmartInstallment)
		)

		INSERT #t_external_id(external_id, Тип_займа_итоговый)
		SELECT DISTINCT 
			S.external_id, --Номер заявки
			Тип_займа_итоговый = 
				CASE 
					WHEN D.isSmartInstallment = 1 THEN 'SmartInstallment'
					WHEN D.isInstallment = 1 THEN 'Installment'
					ELSE NULL
				END
		FROM dm.ClientRequestStatus AS S
			INNER JOIN Stg._1Ccmr.Справочник_Договоры AS D
				ON S.external_id = D.Код
		WHERE S.DWHInsertedDate >= @Max_DWHInsertedDate 
			AND (D.isSmartInstallment = 1 OR D.isInstallment = 1)

		UNION

		SELECT DISTINCT	
			E.external_id, --Номер заявки
			Тип_займа_итоговый = 
				CASE 
					WHEN D.isSmartInstallment = 1 THEN 'SmartInstallment'
					WHEN D.isInstallment = 1 THEN 'Installment'
					ELSE NULL
				END
		FROM dm.ClientRequestEvent AS E
			INNER JOIN Stg._1Ccmr.Справочник_Договоры AS D
				ON E.external_id = D.Код
		WHERE E.DWHInsertedDate >= @Max_DWHInsertedDate 
			AND (D.isSmartInstallment = 1 OR D.isInstallment = 1)

		UNION

		SELECT DISTINCT	
			L.external_id, --Номер заявки
			Тип_займа_итоговый = 
				CASE 
					WHEN D.isSmartInstallment = 1 THEN 'SmartInstallment'
					WHEN D.isInstallment = 1 THEN 'Installment'
					ELSE NULL
				END
		FROM dm.LK_RequestEvent AS L
			INNER JOIN Stg._1Ccmr.Справочник_Договоры AS D
				ON L.external_id = D.Код
		WHERE L.DWHInsertedDate >= @Max_DWHInsertedDate 
			AND (D.isSmartInstallment = 1 OR D.isInstallment = 1)

		--dm.LK_Status_MP
		UNION

		SELECT DISTINCT	
			M.external_id, --Номер заявки
			Тип_займа_итоговый = 
				CASE 
					WHEN D.isSmartInstallment = 1 THEN 'SmartInstallment'
					WHEN D.isInstallment = 1 THEN 'Installment'
					ELSE NULL
				END
		FROM dm.LK_Status_MP AS M
			INNER JOIN Stg._1Ccmr.Справочник_Договоры AS D
				ON M.external_id = D.Код
		WHERE M.DWHInsertedDate >= @Max_DWHInsertedDate 
			AND (D.isSmartInstallment = 1 OR D.isInstallment = 1)

		--dm.LK_ContractDocument
		UNION
		SELECT DISTINCT	
			C.external_id, --Номер заявки
			Тип_займа_итоговый = 
				CASE 
					WHEN D.isSmartInstallment = 1 THEN 'SmartInstallment'
					WHEN D.isInstallment = 1 THEN 'Installment'
					ELSE NULL
				END
		FROM dm.LK_ContractDocument AS C
			INNER JOIN Stg._1Ccmr.Справочник_Договоры AS D
				ON C.external_id = D.Код
		WHERE C.DWHInsertedDate >= @Max_DWHInsertedDate 
			AND (D.isSmartInstallment = 1 OR D.isInstallment = 1)


		SELECT @TempRows = @@ROWCOUNT

		IF @TempRows > 0
		BEGIN
	
			--CREATE UNIQUE CLUSTERED INDEX clix_id ON #t_external_id(external_id) --, ЗаявкаСсылка)

			INSERT #t_dm_Installment(external_id, Тип_займа_итоговый)
			SELECT I.external_id, I.Тип_займа_итоговый
			FROM #t_external_id AS I

			CREATE CLUSTERED INDEX IX1 ON #t_dm_Installment(external_id)

			---------------------------------------------------
			-- заполнение полей из витрины Статус заявки
			---------------------------------------------------

			--Подписание 1-го пакета документов
			--UPDATE D
			--SET Подписание_1_го_пакета_документов = S.Период
			--FROM #t_dm_Installment AS D
			--	INNER JOIN dm.ClientRequestStatus AS S
			--		ON S.external_id = D.external_id
			--		AND S.НаименованиеСтатуса = 'Подписание 1-го пакета'


			--Заполнена_короткая_анкета
			UPDATE D
			SET Заполнена_короткая_анкета = S.Период
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestStatus AS S
					ON S.external_id = D.external_id
					AND S.НаименованиеСтатуса = 'Заполнение короткой анкеты'

			--Контроль_данных
			UPDATE D
			SET Контроль_данных = S.Период
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestStatus AS S
					ON S.external_id = D.external_id
					AND S.НаименованиеСтатуса = 'Контроль данных'

			--Клиент_получает_одобрение
			UPDATE D
			SET Клиент_получает_одобрение = S.Период
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestStatus AS S
					ON S.external_id = D.external_id
					AND S.НаименованиеСтатуса = 'Одобрено'

			--Клиент_получает_деньги
			UPDATE D
			SET Клиент_получает_деньги = S.Период
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestStatus AS S
					ON S.external_id = D.external_id
					AND S.НаименованиеСтатуса = 'Заем выдан'

			--Клиент_выходит_в_просрочку
			UPDATE D
			SET Клиент_выходит_в_просрочку = S.Период
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestStatus AS S
					ON S.external_id = D.external_id
					AND S.НаименованиеСтатуса = 'Просрочен'

			---------------------------------------------------
			-- заполнение полей из витрины События заявки
			---------------------------------------------------
			--Подписание_1_го_пакета_документов
			UPDATE D
			SET Подписание_1_го_пакета_документов = E.Дата
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestEvent AS E
					ON E.external_id = D.external_id
					AND E.НаименованиеСобытия = 'Подписание 1-го пакета'

			--Заполнена_информация_о_себе
			UPDATE D
			SET Заполнена_информация_о_себе = E.Дата
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestEvent AS E
					ON E.external_id = D.external_id
					AND E.НаименованиеСобытия = 'Клиент заполнил базовую личную информацию'

			--Заполнена_информация_о_работе
			UPDATE D
			SET Заполнена_информация_о_работе = E.Дата
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestEvent AS E
					ON E.external_id = D.external_id
					AND E.НаименованиеСобытия = 'Клиент заполнил информацию о работодателе'

			--Подписание_2_го_пакета_документов
			UPDATE D
			SET Подписание_2_го_пакета_документов = E.Дата
			FROM #t_dm_Installment AS D
				INNER JOIN dm.ClientRequestEvent AS E
					ON E.external_id = D.external_id
					AND E.НаименованиеСобытия = 'Подписание 2-го пакета'

			---------------------------------------------------
			-- заполнение полей из витрины dm.LK_RequestEvent - события в Личном кабинете Клиента
			---------------------------------------------------
			--Клиент вводит данные банковской карты
			--811 событие - Проверка карты прошла успешно
			UPDATE D
			SET Клиент_вводит_данные_банковской_карты = L.created_at -- L.updated_at
			FROM #t_dm_Installment AS D
				INNER JOIN dm.LK_RequestEvent AS L
					ON L.external_id = D.external_id
					AND L.event_code = 811

			--Клиент подписывает согласие на установку ПЭП
			--событие с кодом 104 - подписан  пакет документов 1.1
			UPDATE D
			SET Клиент_подписывает_согласие_на_установку_ПЭП = L.created_at -- L.updated_at
			FROM #t_dm_Installment AS D
				INNER JOIN dm.LK_RequestEvent AS L
					ON L.external_id = D.external_id
					AND L.event_code = 104

			--Клиент запускает установку МДМ
			--событие с кодом 699 - загрузка установщика мдм
			UPDATE D
			SET Клиент_запускает_установку_МДМ = L.created_at -- L.updated_at
			FROM #t_dm_Installment AS D
				INNER JOIN dm.LK_RequestEvent AS L
					ON L.external_id = D.external_id
					AND L.event_code = 699

			---------------------------------------------------
			-- заполнение полей из витрины dm.LK_Status_MP AS M
			---------------------------------------------------
			--Клиент перешел на экран выбора предложения повторно (сменились сутки)
			--Для Смарт инстолмент экран выбора предложения это статус - MDM_INSTALLED
			--для обычного инстолмент экран выбора предложения это статус - APPROVED
			--Если есть более >=2 статусов
			UPDATE D
			SET Клиент_перешел_на_экран_выбора_предложения_повторно = X.created_at
			FROM #t_dm_Installment AS D
				INNER JOIN (
					SELECT 
						T.external_id,
						M.created_at, -- M.updated_at,
						rn = row_number() OVER(PARTITION BY M.external_id ORDER BY M.created_at)
					FROM #t_dm_Installment AS T
						INNER JOIN dm.LK_Status_MP AS M
							ON M.external_id = T.external_id
							AND T.Тип_займа_итоговый = 'SmartInstallment'
							AND M.status_identifier = 'MDM_INSTALLED'
				) AS X
				ON X.external_id = D.external_id
				AND X.rn = 2

			--для обычного инстолмент экран выбора предложения это статус - APPROVED
			UPDATE D
			SET Клиент_перешел_на_экран_выбора_предложения_повторно = X.created_at
			FROM #t_dm_Installment AS D
				INNER JOIN (
					SELECT 
						T.external_id,
						M.created_at, -- M.updated_at,
						rn = row_number() OVER(PARTITION BY M.external_id ORDER BY M.created_at)
					FROM #t_dm_Installment AS T
						INNER JOIN dm.LK_Status_MP AS M
							ON M.external_id = T.external_id
							AND T.Тип_займа_итоговый = 'Installment'
							AND M.status_identifier = 'APPROVED'
				) AS X
				ON X.external_id = D.external_id
				AND X.rn = 2



			---------------------------------------------------
			-- заполнение полей из витрины dm.LK_ContractDocument
			---------------------------------------------------
			--Клиент подписывает 2й пакет документов
			--Подписание_2_го_пакета_документов datetime, --Клиент подписывает 2й пакет документов
			--type='device-impact'
			--искать записи у которым sms input_date is not null
			--package_doc=2 and sub_package=1
			--OR
			--package_doc=2 and sub_package=2
			UPDATE D
			SET Подписание_2_го_пакета_документов = L.sms_input_date
			FROM #t_dm_Installment AS D
				INNER JOIN dm.LK_ContractDocument AS L
					ON L.external_id = D.external_id
					AND L.doc_type = 'device-impact'
					AND L.package_doc = 2
					AND L.sub_package IN (1, 2)

			---------------------------------------------------
			BEGIN TRAN
				DELETE D
				FROM dm.Installment_SmartInstallment AS D
					INNER JOIN  #t_external_id AS I
						ON D.external_id = I.external_id

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dm.Installment_SmartInstallment
				(
				    DWHInsertedDate,
				    --ЗаявкаСсылка,
				    external_id,
				    Тип_займа_итоговый,
				    Марка,
				    Модель,
				    IMEI,
				    Наличие_установленного_ПО,
				    Актуальный_статус_устройства,
				    ОС,
				    Версия_ОС,
				    Заполнена_короткая_анкета,
				    Подписание_1_го_пакета_документов,
				    Заполнена_информация_о_себе,
				    Заполнена_информация_о_работе,
				    Заполнена_информация_о_доходе,
				    Одобрение_на_Логиноме_на_Call1,
				    Отказ_на_Логиноме_на_Call1,
				    Тип_беззалогового_займа_Call1,
				    Клиент_прикрепляет_фото,
				    Клиент_прикрепляет_фото_IMEI,
				    IMEI_автоматически_распознан,
				    IMEI_автоматически_не_распознан,
				    IMEI_распознан_после_ручной_проверки,
				    Клиент_вводит_данные_банковской_карты,
				    Контроль_данных,
				    Одобрение_на_Логиноме_на_Call1_5,
				    Отказ_на_Логиноме_на_Call1_5,
				    Тип_беззалогового_займа_Call1_5,
				    Одобрение_на_Логиноме_на_Call2,
				    Отказ_на_Логиноме_на_Call2,
				    Тип_беззалогового_займа_Call2,
				    Одобрение_на_Логиноме_на_Call3,
				    Отказ_на_Логиноме_на_Call3,
				    Тип_беззалогового_займа_Call3,
				    Клиент_получает_одобрение,
				    Клиент_выбирает_предложение,
				    Клиент_соглашается_на_установку_МДМ,
				    Клиент_подписывает_согласие_на_установку_ПЭП,
				    Отказ_Клиента_на_установку_ПО,
				    Клиент_запускает_установку_МДМ,
				    Клиент_завершил_установку_ПО_успешно,
				    Клиент_завершил_установку_ПО_НЕ_успешно,
				    Клиент_начал_установку_ПО_повторно,
				    Клиент_завершил_повторную_установку_ПО_успешно,
				    Клиент_завершил_повторную_установку_ПО_НЕ_успешно,
				    Выдача_Инстолмента_при_неуспешной_установке,
				    Окирпичивание_телефона,
				    Аннулирование_заявки_при_отказе_от_установки_в_процессе_установки,
				    Клиент_перешел_на_экран_выбора_предложения_повторно,
				    Подписание_2_го_пакета_документов,
				    Клиент_получает_деньги,
				    Клиент_выходит_в_просрочку,
				    Клиент_подписывает_согласие_на_взаимодействие_с_телефоном,
				    Клиент_не_подписывает_согласие_на_взаимодействие_с_телефоном
				)
				SELECT 
					DWHInsertedDate = getdate(),
					--D.ЗаявкаСсылка,
                    D.external_id,
                    D.Тип_займа_итоговый,
                    D.Марка,
                    D.Модель,
                    D.IMEI,
                    D.Наличие_установленного_ПО,
                    D.Актуальный_статус_устройства,
                    D.ОС,
                    D.Версия_ОС,
                    D.Заполнена_короткая_анкета,
                    D.Подписание_1_го_пакета_документов,
                    D.Заполнена_информация_о_себе,
                    D.Заполнена_информация_о_работе,
                    D.Заполнена_информация_о_доходе,
                    D.Одобрение_на_Логиноме_на_Call1,
                    D.Отказ_на_Логиноме_на_Call1,
                    D.Тип_беззалогового_займа_Call1,
                    D.Клиент_прикрепляет_фото,
                    D.Клиент_прикрепляет_фото_IMEI,
                    D.IMEI_автоматически_распознан,
                    D.IMEI_автоматически_не_распознан,
                    D.IMEI_распознан_после_ручной_проверки,
                    D.Клиент_вводит_данные_банковской_карты,
                    D.Контроль_данных,
                    D.Одобрение_на_Логиноме_на_Call1_5,
                    D.Отказ_на_Логиноме_на_Call1_5,
                    D.Тип_беззалогового_займа_Call1_5,
                    D.Одобрение_на_Логиноме_на_Call2,
                    D.Отказ_на_Логиноме_на_Call2,
                    D.Тип_беззалогового_займа_Call2,
                    D.Одобрение_на_Логиноме_на_Call3,
                    D.Отказ_на_Логиноме_на_Call3,
                    D.Тип_беззалогового_займа_Call3,
                    D.Клиент_получает_одобрение,
                    D.Клиент_выбирает_предложение,
                    D.Клиент_соглашается_на_установку_МДМ,
                    D.Клиент_подписывает_согласие_на_установку_ПЭП,
                    D.Отказ_Клиента_на_установку_ПО,
                    D.Клиент_запускает_установку_МДМ,
                    D.Клиент_завершил_установку_ПО_успешно,
                    D.Клиент_завершил_установку_ПО_НЕ_успешно,
                    D.Клиент_начал_установку_ПО_повторно,
                    D.Клиент_завершил_повторную_установку_ПО_успешно,
                    D.Клиент_завершил_повторную_установку_ПО_НЕ_успешно,
                    D.Выдача_Инстолмента_при_неуспешной_установке,
                    D.Окирпичивание_телефона,
                    D.Аннулирование_заявки_при_отказе_от_установки_в_процессе_установки,
                    D.Клиент_перешел_на_экран_выбора_предложения_повторно,
                    D.Подписание_2_го_пакета_документов,
                    D.Клиент_получает_деньги,
                    D.Клиент_выходит_в_просрочку,
                    D.Клиент_подписывает_согласие_на_взаимодействие_с_телефоном,
                    D.Клиент_не_подписывает_согласие_на_взаимодействие_с_телефоном 
				FROM #t_dm_Installment AS D

				SELECT @InsertRows = @@ROWCOUNT
			COMMIT
		END

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())


		IF @isDebug = 1 BEGIN
			SELECT concat('Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)
		END

		SELECT @message = concat(
			'Формирование витрины dm.Installment_SmartInstallment. ',
			'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
			'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
			'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
		)

		SELECT @description =
			(
			SELECT
				'DeleteRows' = @DeleteRows,
				'InsertRows' = @InsertRows,
				'DurationSec' = @DurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Fill_Installment_SmartInstallment',
			@eventType = 'Info',
			@message = @message,
			@description = @description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = concat(
			'Ошибка формирования витрины dm.Installment_SmartInstallment. ',
			'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
			'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
			'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
		)

		SELECT @description =
			(
			SELECT
				'DeleteRows' = @DeleteRows,
				'InsertRows' = @InsertRows,
				'DurationSec' = @DurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Error Fill_Installment_SmartInstallment',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END

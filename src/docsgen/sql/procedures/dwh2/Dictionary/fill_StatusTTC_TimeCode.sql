-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-01-29
-- Description:	DWH-2420 Пересоздания отчета ТТС верификации
-- заполнение справочника группировки статус+task по "типу времени" (Верификационное, Клиентское, Системное)
--  Dictionary.StatusTTC_TimeCode
-- =============================================
/*
exec Dictionary.fill_StatusTTC_TimeCode
--drop table Dictionary.StatusTTC_TimeCode
select *
from Dictionary.StatusTTC_TimeCode X
order by ProductType_Code, StatusTTS_Name
*/
CREATE   PROC Dictionary.fill_StatusTTC_TimeCode
	--@ProductType varchar(20) = 'installment',
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)

	BEGIN TRY

		DROP TABLE IF EXISTS #t_status_x_time
		CREATE TABLE #t_status_x_time
		(
			ProductType_Code varchar(30),
			RN int,
			StatusTTS_Name varchar(255), 
			Time_Code varchar(30)
		)

		INSERT #t_status_x_time
		(
		    ProductType_Code,
			RN,
		    StatusTTS_Name,
		    Time_Code
		)
		SELECT 
			t.ProductType_Code,
			t.RN,
			t.StatusTTS_Name,
			t.Time_Code
		FROM (
			VALUES
			--91
			('pts', NULL, 'Аннулировано',''),
			('pts', NULL, 'Аннулировано В работе',''),
			('pts', NULL, 'Аннулировано Выполнена',''),
			('pts', NULL, 'Аннулировано Доработка',''),
			('pts', NULL, 'Аннулировано Ждет Исполнителя',''),
			('pts', NULL, 'Аннулировано Ожидание',''),
			('pts', 10, 'Верификация Call 1.5','Sys'),
			('pts', NULL, 'Верификация Call 1.5 В работе',''),
			('pts', NULL, 'Верификация Call 1.5 Выполнена',''),
			('pts', NULL, 'Верификация Call 1.5 Ждет Исполнителя',''),
			('pts', NULL, 'Верификация Call 1.5 Ожидание',''),
			('pts', 12, 'Верификация Call 2','Sys'),
			('pts', NULL, 'Верификация Call 2 В работе',''),
			('pts', NULL, 'Верификация Call 2 Выполнена',''),
			('pts', NULL, 'Верификация Call 2 Ждет Исполнителя',''),
			('pts', NULL, 'Верификация Call 2 Ожидание',''),
			('pts', NULL, 'Верификация Call 2 Отложена',''),
			('pts', NULL, 'Верификация Call 2 Отменена',''),
			('pts', 18, 'Верификация Call 3','Sys'),
			('pts', NULL, 'Верификация Call 3 Ожидание',''),
			('pts', 24, 'Верификация Call 4','Sys'),
			('pts', NULL, 'Верификация Call 4 Выполнена',''),
			('pts', NULL, 'Верификация клиента',''),
			('pts', 14, 'Верификация клиента В работе','Ver'),
			('pts', 15, 'Верификация клиента Выполнена','Sys'),
			('pts', 16, 'Верификация клиента Доработка','Client'),
			('pts', NULL, 'Верификация клиента Ждет Исполнителя',''),
			('pts', 13, 'Верификация клиента Ожидание','Ver'),
			('pts', 17, 'Верификация клиента Отложена','Client'),
			('pts', NULL, 'Верификация клиента Отменена',''),
			('pts', 2, 'Верификация КЦ','Sys'),
			('pts', NULL, 'Верификация ТС',''),
			('pts', 23, 'Верификация ТС В работе','Ver'),
			('pts', NULL, 'Верификация ТС Выполнена',''),
			('pts', 21, 'Верификация ТС Доработка','Client'),
			('pts', NULL, 'Верификация ТС Ждет Исполнителя',''),
			('pts', 20, 'Верификация ТС Ожидание','Ver'),
			('pts', 22, 'Верификация ТС Отложена','Client'),
			('pts', NULL, 'Верификация ТС Отменена',''),
			('pts', 26, 'Договор зарегистрирован','Client'),
			('pts', NULL, 'Договор зарегистрирован В работе',''),
			('pts', NULL, 'Договор зарегистрирован Выполнена',''),
			('pts', NULL, 'Договор зарегистрирован Доработка',''),
			('pts', NULL, 'Договор зарегистрирован Ждет Исполнителя',''),
			('pts', NULL, 'Договор зарегистрирован Ожидание',''),
			('pts', 27, 'Договор подписан','Client'),
			('pts', NULL, 'Заем аннулирован',''),
			('pts', NULL, 'Заем аннулирован Ожидание',''),
			('pts', NULL, 'Заем выдан',''),
			('pts', NULL, 'Заем выдан Ожидание',''),
			('pts', NULL, 'Заем погашен',''),
			('pts', NULL, 'Заем погашен Ожидание',''),
			('pts', NULL, 'Заем погашен Отложена',''),
			('pts', NULL, 'Клиент передумал',''),
			('pts', NULL, 'Контроль данных',''),
			('pts', 8, 'Контроль данных В работе','Ver'),
			('pts', 9, 'Контроль данных Выполнена','Sys'),
			('pts', 7, 'Контроль данных Доработка','Client'),
			('pts', NULL, 'Контроль данных Ждет Исполнителя',''),
			('pts', 5, 'Контроль данных Ожидание','Ver'),
			('pts', 6, 'Контроль данных Отложена','Ver'),
			('pts', NULL, 'Контроль данных Отменена',''),
			('pts', 19, 'Одобрен клиент','Client'),
			('pts', NULL, 'Одобрен клиент В работе',''),
			('pts', NULL, 'Одобрен клиент Выполнена',''),
			('pts', NULL, 'Одобрен клиент Ждет Исполнителя',''),
			('pts', NULL, 'Одобрен клиент Ожидание',''),
			('pts', 25, 'Одобрено','Client'),
			('pts', NULL, 'Одобрено Ждет Исполнителя',''),
			('pts', NULL, 'Одобрено Ожидание',''),
			('pts', NULL, 'Одобрено Отменена',''),
			('pts', 3, 'Ожидание подписи документов EDO','Client'),
			('pts', NULL, 'Ожидание подписи документов EDO В работе',''),
			('pts', NULL, 'Ожидание подписи документов EDO Выполнена',''),
			('pts', NULL, 'Ожидание подписи документов EDO Ждет Исполнителя',''),
			('pts', NULL, 'Ожидание подписи документов EDO Ожидание',''),
			('pts', NULL, 'Ожидание подписи документов EDO Отменена',''),
			('pts', NULL, 'Отказано',''),
			('pts', NULL, 'Отказано Ожидание',''),
			('pts', NULL, 'Отказано Отложена',''),
			('pts', 11, 'Переподписание первого пакета','Client'),
			('pts', NULL, 'Переподписание первого пакета В работе',''),
			('pts', NULL, 'Переподписание первого пакета Выполнена',''),
			('pts', NULL, 'Переподписание первого пакета Ждет Исполнителя',''),
			('pts', NULL, 'Переподписание первого пакета Ожидание',''),
			('pts', 4, 'Предварительное одобрение','Client'),
			('pts', NULL, 'Предварительное одобрение В работе',''),
			('pts', NULL, 'Предварительное одобрение Выполнена',''),
			('pts', NULL, 'Предварительное одобрение Ждет Исполнителя',''),
			('pts', NULL, 'Предварительное одобрение Ожидание',''),
			('pts', 1, 'Черновик','Client'),
			---
			--46
			('installment', NULL, 'Аннулировано',''),
			('installment', 11, 'Верификация Call 1.5','Sys'),
			('installment', 5, 'Верификация Call 1_2','Sys'),
			('installment', 13, 'Верификация Call 2','Sys'),
			('installment', 18, 'Верификация Call 3','Sys'),
			('installment', NULL, 'Верификация Call 3 Выполнена',''),
			('installment', 21, 'Верификация Call 5','Sys'),
			('installment', NULL, 'Верификация клиента',''),
			('installment', 15, 'Верификация клиента В работе','Ver'),
			('installment', 17, 'Верификация клиента Выполнена','Sys'),
			('installment', NULL, 'Верификация клиента Ждет Исполнителя',''),
			('installment', 14, 'Верификация клиента Ожидание','Ver'),
			('installment', 16, 'Верификация клиента Отложена','Ver'),
			('installment', NULL, 'Верификация клиента Отменена',''),
			('installment', 2, 'Верификация КЦ','Sys'),
			('installment', 23, 'Договор зарегистрирован','Client'),
			('installment', 24, 'Договор подписан','Client'),
			('installment', NULL, 'Заем аннулирован',''),
			('installment', NULL, 'Заем выдан',''),
			('installment', NULL, 'Контроль данных',''),
			('installment', 9, 'Контроль данных В работе','Ver'),
			('installment', 10, 'Контроль данных Выполнена','Sys'),
			('installment', 8, 'Контроль данных Доработка','Client'),
			('installment', NULL, 'Контроль данных Ждет Исполнителя',''),
			('installment', 6, 'Контроль данных Ожидание','Ver'),
			('installment', 7, 'Контроль данных Отложена','Ver'),
			('installment', NULL, 'Контроль данных Отменена',''),
			('installment', 22, 'Одобрено','Client'),
			('installment', NULL, 'Ожидание перед КД',''),
			('installment', 3, 'Ожидание подписи документов EDO','Client'),
			('installment', NULL, 'Отказано',''),
			('installment', 12, 'Переподписание первого пакета','Client'),
			('installment', NULL, 'Переподписание первого пакета В работе',''),
			('installment', NULL, 'Переподписание первого пакета Выполнена',''),
			('installment', NULL, 'Переподписание первого пакета Ждет Исполнителя',''),
			('installment', NULL, 'Переподписание первого пакета Ожидание',''),
			('installment', NULL, 'Переподписание первого пакета Отложена',''),
			('installment', NULL, 'Переподписание первого пакета Отменена',''),
			('installment', 4, 'Предварительное одобрение','Sys'),
			('installment', NULL, 'Предварительное одобрение В работе',''),
			('installment', NULL, 'Предварительное одобрение Выполнена',''),
			('installment', NULL, 'Предварительное одобрение Ждет Исполнителя',''),
			('installment', NULL, 'Предварительное одобрение Ожидание',''),
			('installment', NULL, 'Предварительное одобрение Отменена',''),
			('installment', 20, 'Предодобр перед Call 5','Client'),
			('installment', 1, 'Черновик','Client'),
			---
			--48
			('pdl', NULL, 'Аннулировано',''),
			('pdl', 11, 'Верификация Call 1.5','Sys'),
			('pdl', NULL, 'Верификация Call 1_2 В работе',''),
			('pdl', NULL, 'Верификация Call 1_2 Выполнена',''),
			('pdl', NULL, 'Верификация Call 1_2 Ждет Исполнителя',''),
			('pdl', NULL, 'Верификация Call 1_2 Ожидание',''),
			('pdl', 5, 'Верификация Call 1_2','Sys'),
			('pdl', NULL, 'Верификация Call 2 В работе',''),
			('pdl', NULL, 'Верификация Call 2 Выполнена',''),
			('pdl', NULL, 'Верификация Call 2 Ждет Исполнителя',''),
			('pdl', NULL, 'Верификация Call 2 Ожидание',''),
			('pdl', 13, 'Верификация Call 2','Sys'),
			('pdl', 18, 'Верификация Call 3','Sys'),
			('pdl', 21, 'Верификация Call 5','Sys'),
			('pdl', 15, 'Верификация клиента В работе','Ver'),
			('pdl', 17, 'Верификация клиента Выполнена','Sys'),
			('pdl', NULL, 'Верификация клиента Ждет Исполнителя',''),
			('pdl', 14, 'Верификация клиента Ожидание','Ver'),
			('pdl', 16, 'Верификация клиента Отложена','Ver'),
			('pdl', NULL, 'Верификация клиента Отменена',''),
			('pdl', NULL, 'Верификация клиента',''),
			('pdl', 2, 'Верификация КЦ','Sys'),
			('pdl', 23, 'Договор зарегистрирован','Client'),
			('pdl', 24, 'Договор подписан','Client'),
			('pdl', NULL, 'Заем выдан',''),
			('pdl', 9, 'Контроль данных В работе','Ver'),
			('pdl', 10, 'Контроль данных Выполнена','Sys'),
			('pdl', 8, 'Контроль данных Доработка','Client'),
			('pdl', NULL, 'Контроль данных Ждет Исполнителя',''),
			('pdl', 6, 'Контроль данных Ожидание','Ver'),
			('pdl', 7, 'Контроль данных Отложена','Ver'),
			('pdl', NULL, 'Контроль данных Отменена',''),
			('pdl', NULL, 'Контроль данных',''),
			('pdl', 22, 'Одобрено','Client'),
			('pdl', NULL, 'Ожидание перед КД В работе',''),
			('pdl', NULL, 'Ожидание перед КД Выполнена',''),
			('pdl', NULL, 'Ожидание перед КД Ждет Исполнителя',''),
			('pdl', NULL, 'Ожидание перед КД Ожидание',''),
			('pdl', NULL, 'Ожидание перед КД',''),
			('pdl', 3, 'Ожидание подписи документов EDO','Client'),
			('pdl', NULL, 'Переподписание первого пакета В работе',''),
			('pdl', NULL, 'Переподписание первого пакета Выполнена',''),
			('pdl', NULL, 'Переподписание первого пакета Ждет Исполнителя',''),
			('pdl', NULL, 'Переподписание первого пакета Ожидание',''),
			('pdl', 12, 'Переподписание первого пакета','Client'),
			('pdl', 4, 'Предварительное одобрение','Sys'),
			('pdl', 20, 'Предодобр перед Call 5','Client'),
			('pdl', 1, 'Черновик','Client')
		) t(ProductType_Code, RN, StatusTTS_Name, Time_Code)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_status_x_time
			SELECT * INTO ##t_status_x_time FROM #t_status_x_time AS D
			--RETURN 0
		END


		if OBJECT_ID ('Dictionary.StatusTTC_TimeCode') IS NULL
		BEGIN
			SELECT TOP 0 * 
			INTO Dictionary.StatusTTC_TimeCode
			FROM #t_status_x_time

			CREATE INDEX IX_ProductType_Code_StatusTTS_Name ON Dictionary.StatusTTC_TimeCode(ProductType_Code, StatusTTS_Name)
		END
		

		BEGIN TRAN
			TRUNCATE TABLE Dictionary.StatusTTC_TimeCode

			INSERT Dictionary.StatusTTC_TimeCode(ProductType_Code, RN, StatusTTS_Name,  Time_Code)
			SELECT X.ProductType_Code, X.RN, X.StatusTTS_Name, X.Time_Code
			FROM #t_status_x_time AS X
		COMMIT

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END

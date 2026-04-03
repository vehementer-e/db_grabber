-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-01-29
-- Description:	DWH-2420 Пересоздания отчета ТТС верификации
-- заполнение справочника группировки статус+task по "типу времени" (Верификационное, Клиентское, Системное)
--  Dictionary.TTC_Indicator
-- =============================================
/*
exec Dictionary.fill_TTC_Indicator
--drop table Dictionary.TTC_Indicator
select *
from Dictionary.TTC_Indicator X
order by X.RN
*/
CREATE   PROC Dictionary.fill_TTC_Indicator
	--@ProductType varchar(20) = 'installment',
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)

	BEGIN TRY

		DROP TABLE IF EXISTS #t_TTC_Indicator
		CREATE TABLE #t_TTC_Indicator
		(
			RN int,
			Статус nvarchar(255),
			[Состояние заявки] nvarchar(255),
			Задача nvarchar(255), 
			[Статус следующий] nvarchar(255),
			[Состояние заявки следующая] nvarchar(255),
			[Задача следующая] nvarchar(255), 
			[ШагЗаявки_eq_ПоследнийШаг] int,
			Показатель nvarchar(255)
		)

		INSERT #t_TTC_Indicator
		(
		    RN,
		    Статус,
		    [Состояние заявки],
		    Задача,
		    [Статус следующий],
		    [Состояние заявки следующая],
		    [Задача следующая],
		    ШагЗаявки_eq_ПоследнийШаг,
		    Показатель
		)
		SELECT 
			t.RN,
			t.Статус,
			t.[Состояние заявки],
			t.Задача,
			t.[Статус следующий],
			t.[Состояние заявки следующая],
			t.[Задача следующая],
			t.ШагЗаявки_eq_ПоследнийШаг,
			t.Показатель
		FROM (
			VALUES
			--KD
			(1, 'Контроль данных', 'Отложена', 'task:Требуется доработка', NULL, NULL, NULL, NULL, 'ДоработкаКД'),
			(2, 'Контроль данных', NULL, NULL, NULL, 'Отложена', 'task:Требуется доработка', 1, 'ДоработкаКДПоследнийШаг'),
			(3, 'Контроль данных', 'Отложена', 'task:Отложена', NULL, NULL, NULL, NULL, 'ОтложенаКД'),
			(4, 'Контроль данных', NULL, NULL, NULL, 'Отложена', 'task:Отложена', 1, 'ОтложенаКДПоследнийШаг'),

			(5, 'Верификация Call 1.5', NULL, NULL, 'Отказано', NULL, NULL, NULL, 'ОтказаноКД'),
			(6, 'Верификация Call 1.5', NULL, NULL, 'Ожидание подписи документов EDO', NULL, NULL, NULL, 'ВК_КД'),
			(7, 'Контроль данных', NULL, 'task:Новая', NULL, NULL, NULL, NULL, 'НоваяКД'),
			(8, 'Контроль данных', NULL, 'task:В работе', NULL, NULL, NULL, NULL, 'В_работеКД'),

			--VK
			(9, 'Верификация клиента', 'Отложена', 'task:Требуется доработка', NULL, NULL, NULL, NULL, 'ДоработкаВК'),
			(10, 'Верификация клиента', NULL, NULL, NULL, 'Отложена', 'task:Требуется доработка', 1, 'ДоработкаВКПоследнийШаг'),
			(11, 'Верификация клиента', 'Отложена', 'task:Отложена', NULL, NULL, NULL, NULL, 'ОтложенаВК'),
			(12, 'Верификация клиента', NULL, NULL, NULL, 'Отложена', 'task:Отложена', 1, 'ОтложенаВКПоследнийШаг'),

			(13, 'Верификация Call 3', NULL, NULL, 'Отказано', NULL, NULL, NULL, 'ОтказаноВК'),
			(14, 'Верификация Call 1.5', NULL, NULL, 'Одобрен клиент', NULL, NULL, NULL, 'ВК_ВК'),
			(15, 'Верификация клиента', NULL, 'task:Новая', NULL, NULL, NULL, NULL, 'НоваяВК'),
			(16, 'Верификация клиента', NULL, 'task:В работе', NULL, NULL, NULL, NULL, 'В_работеВК'),

			--VTS
			(17, 'Верификация ТС', 'Отложена', 'task:Требуется доработка', NULL, NULL, NULL, NULL, 'ДоработкаВТС'),
			(18, 'Верификация ТС', NULL, NULL, NULL, 'Отложена', 'task:Требуется доработка', 1, 'ДоработкаВТСПоследнийШаг'),
			(19, 'Верификация ТС', 'Отложена', 'task:Отложена', NULL, NULL, NULL, NULL, 'ОтложенаВТС'),
			(20, 'Верификация ТС', NULL, NULL, NULL, 'Отложена', 'task:Отложена', 1, 'ОтложенаВТСПоследнийШаг'),

			--when [Статус следующий]='Отказано' and Статус in('Верификация Call 1.5') then 'ОтказаноВТС'					 
			--when [Статус следующий]='Ожидание подписи документов EDO' and Статус in('Верификация Call 1.5') then 'ВК_ВТС'
			(23, 'Верификация ТС', NULL, 'task:Новая', NULL, NULL, NULL, NULL, 'НоваяВТС'),
			(24, 'Верификация ТС', NULL, 'task:В работе', NULL, NULL, NULL, NULL, 'В_работеВТС')
		) t(
			--[Тип продукта], 
			RN,
			Статус, [Состояние заявки], Задача, 
			[Статус следующий], [Состояние заявки следующая], [Задача следующая], 
			[ШагЗаявки_eq_ПоследнийШаг],
			Показатель
		)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_TTC_Indicator
			SELECT * INTO ##t_TTC_Indicator FROM #t_TTC_Indicator AS D
			--RETURN 0
		END

		if OBJECT_ID ('Dictionary.TTC_Indicator') IS NULL
		BEGIN
			SELECT TOP 0 * 
			INTO Dictionary.TTC_Indicator
			FROM #t_TTC_Indicator
		END
		

		BEGIN TRAN
			TRUNCATE TABLE Dictionary.TTC_Indicator

			INSERT Dictionary.TTC_Indicator(
				RN,
				Статус,
				[Состояние заявки],
				Задача,
				[Статус следующий],
				[Состояние заявки следующая],
				[Задача следующая],
				ШагЗаявки_eq_ПоследнийШаг,
				Показатель
			)
			SELECT 
				X.RN,
				X.Статус,
				X.[Состояние заявки],
				X.Задача,
				X.[Статус следующий],
				X.[Состояние заявки следующая],
				X.[Задача следующая],
				X.ШагЗаявки_eq_ПоследнийШаг,
				X.Показатель
			FROM #t_TTC_Indicator AS X
		COMMIT

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END

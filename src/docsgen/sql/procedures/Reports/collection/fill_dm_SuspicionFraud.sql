/*
drop table if exists collection.dm_SuspicionFraud
exec dbo.fill_dm_SuspicionFraud
*/
-- =============================================
-- Author:		А.Никитин
-- Create date: 2023-12-09
-- Description:	DWH-2582 Подозрения на FRAUD
-- =============================================
/*
*/
CREATE   PROC [collection].[fill_dm_SuspicionFraud]
	--@days int=25, --кол-во дней для пересчета
	--@RequestNumber varchar(20) = NULL, -- расчет по одной заявке
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @calc_date date = cast(getdate() AS date)

	BEGIN TRY

		DROP TABLE IF EXISTS #t_dm_SuspicionFraud

		SELECT --TOP 100 
			created_at = getdate(),
			GuidДоговора = Договор.GuidДоговораЗайма, --
			НомерДоговора = Договор.КодДоговораЗайма, --B.external_id,
			СуммаУщерба = B.Сумма, --сумма ущерба = сумма займа из баланса
			СуммаПросрочки = B.overdue, --сумма просрочки из баланса
			ТипПродукта = Договор.ТипПродукта,
			ДатаДоговора = Договор.ДатаДоговораЗайма,
			ФИО = Клиент.ФИО,
			GuidКлиент = Клиент.GuidКлиент,
			--Клиент.СсылкаКлиент
			ДатаИсключенияСрокаДоговора = cast(NULL AS date),
			СтатусыСпейс				= cast(NULL AS varchar(8000)),
			photoHasSuspiciousAtribute	= cast(null AS bit),
			Широта						= cast(NULL AS varchar(255)),
			Долгота						= cast(NULL AS varchar(255))
		INTO #t_dm_SuspicionFraud
		FROM dwh2.dbo.dm_CMRStatBalance AS B
			INNER JOIN dwh2.hub.ДоговорЗайма AS Договор
				ON Договор.КодДоговораЗайма = B.external_id
			INNER JOIN dwh2.link.v_Клиент_ДоговорЗайма AS Клиент
				ON Клиент.КодДоговораЗайма = Договор.КодДоговораЗайма
		WHERE 1=1
			AND B.d = @calc_date
			--не было ни одного платежа - [сумма поступлений  нарастающим итогом] по договору 0.
			AND isnull(B.[сумма поступлений  нарастающим итогом], 0) = 0
			AND NOT EXISTS(
				--Договора, по которым закончился график платежей
				SELECT TOP(1) 1
				FROM dwh2.dm.CMRExpectedRepayments AS G
				WHERE 1=1
					AND G.Код = B.external_id
					AND G.ДатаПлатежа > @calc_date
				)

		--Из выборки исключаем договора у которых CustomerState => FRAUD" и "HARD FRAUD".
		DELETE A
		FROM #t_dm_SuspicionFraud AS A
			INNER JOIN Stg._Collection.Customers AS C
				ON C.CrmCustomerId = A.GuidКлиент
			INNER JOIN Stg._Collection.CustomerStatus AS CS
				ON CS.CustomerId = C.Id
				AND CS.IsActive = 1
			INNER JOIN Stg._Collection.CustomerState S
				ON S.Id = CS.CustomerStateId
		WHERE 1=1
			AND S.Name IN (
				--'Fraud неподтвержденный',
				'Fraud подтвержденный',
				'HardFraud'
			)

		--5. Дата исключения срока договора - крайняя дата по платежу. - > dwh2.dm.CMRExpectedRepayments
		UPDATE T
		SET T.ДатаИсключенияСрокаДоговора = M.max_ДатаПлатежа
		FROM #t_dm_SuspicionFraud AS T
			INNER JOIN (
				SELECT 
					C.НомерДоговора,
					max_ДатаПлатежа = max(G.ДатаПлатежа)
				FROM #t_dm_SuspicionFraud AS C
					INNER JOIN dwh2.dm.CMRExpectedRepayments AS G
						ON G.Код = C.НомерДоговора
				GROUP BY C.НомерДоговора
				) AS M
				ON M.НомерДоговора = T.НомерДоговора

		--6. Статусы - берем данным из Stg._Collection.[CustomerStatus] cs - > Stg._Collection.CustomerState,
		--статусы только у которых стоит флаг isActive = 1 и выводим через;
		UPDATE T
		SET T.СтатусыСпейс = cast(B.СтатусыСпейс AS varchar(8000))
		FROM #t_dm_SuspicionFraud AS T
			INNER JOIN (
				SELECT 
					A.GuidКлиент,
					СтатусыСпейс = string_agg(S.Name, ';')
				FROM #t_dm_SuspicionFraud AS A
					INNER JOIN Stg._Collection.Customers AS C
						ON C.CrmCustomerId = A.GuidКлиент
					INNER JOIN Stg._Collection.CustomerStatus AS CS
						ON CS.CustomerId = C.Id
						AND CS.IsActive = 1
					INNER JOIN Stg._Collection.CustomerState S
						ON S.Id = CS.CustomerStateId
				GROUP BY A.GuidКлиент
			) AS B
			ON B.GuidКлиент = T.GuidКлиент

		--DWH-2732 получить информацию из файла, по след атрибутам - 'Договор_номер', 'Заявка_Номер', lat, lon,suspicious
		drop table if exists #t_files_attributes
		;with cte_files as 
		(
			  SELECT distinct inner_fa._id
				FROM stg.[_fileservice].[Files_Attributes] inner_fa
				where exists(select top(1) 1 from #t_dm_SuspicionFraud sf
					where sf.НомерДоговора = inner_fa.[Attributes.v]
				)
				and inner_fa.[Attributes.k] in('Договор_номер', 'Заявка_Номер')
		)
		SELECT 
			external_id					= isnull([Договор_номер], [Заявка_Номер]),
			Широта						= max([lat]),
			Долгота						= max([lon]),
			photoHasSuspiciousAttribute = max(iif(lower([suspicious]) = 'true', 1,0))
		INTO #t_files_attributes
		FROM 
			(SELECT 
				fa._id,
				fa.[Attributes.k],
				fa.[Attributes.v]
			FROM stg.[_fileservice].[Files_Attributes] fa
			WHERE exists (select top(1) 1 from cte_files f where f._id =fa._id)
			) AS SourceData
		PIVOT
		(
			MAX([Attributes.v])
			FOR [Attributes.k] IN ([Договор_номер], [Заявка_Номер], [lat], [lon], [suspicious])
		) AS PivotTable
		where lower(suspicious) = 'true'
		group by isnull([Договор_номер], [Заявка_Номер])

		
		UPDATE t
		SET
			t.Широта = fa.Широта,
			t.Долгота = fa.Долгота,
			t.photoHasSuspiciousAtribute = fa.photoHasSuspiciousAttribute
		FROM #t_dm_SuspicionFraud t
		INNER JOIN #t_files_attributes fa
			ON t.НомерДоговора = fa.external_id
		WHERE fa.photoHasSuspiciousAttribute IS NOT NULL


		if OBJECT_ID('collection.dm_SuspicionFraud') is null
		BEGIN
			SELECT TOP 0 *
			INTO collection.dm_SuspicionFraud
			FROM #t_dm_SuspicionFraud AS D
        END

		if exists(select top(1) 1 from #t_dm_SuspicionFraud)
		BEGIN
			BEGIN TRAN
				TRUNCATE TABLE collection.dm_SuspicionFraud

				INSERT collection.dm_SuspicionFraud
				(
					[created_at], [GuidДоговора], [НомерДоговора], [СуммаУщерба], [СуммаПросрочки], [ТипПродукта], [ДатаДоговора], [ФИО], [GuidКлиент], [ДатаИсключенияСрокаДоговора], [СтатусыСпейс], [photoHasSuspiciousAtribute], [Широта], [Долгота]
				)
				SELECT 
					T.created_at,
					T.GuidДоговора,
					T.НомерДоговора,
					T.СуммаУщерба,
					T.СуммаПросрочки,
					T.ТипПродукта,
					T.ДатаДоговора,
					T.ФИО,
					T.GuidКлиент,
					T.ДатаИсключенияСрокаДоговора,
					T.СтатусыСпейс,
					T.photoHasSuspiciousAtribute,
					t.Широта,
					t.Долгота
				FROM #t_dm_SuspicionFraud AS T
			COMMIT
		END
		
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_dm_SuspicionFraud
			SELECT * INTO ##t_dm_SuspicionFraud FROM #t_dm_SuspicionFraud AS C
		END

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END

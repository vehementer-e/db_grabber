-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-05-31
-- Description:	DWH-2603 Реализовать отчет Документы подписанные ПЭП
-- =============================================
/*
EXEC collection.Report_DocumentsSignedPEP
*/
-- @changelog  =================================
-- Change Author:		Shubkin Aleksandr
-- Change date:			29.01.2025
-- Change Description: Замена источников данных:
--						stg.[_1cCMR].[Справочник_Договоры]
--						на
--						dwh2.[dm].[ДоговорЗайма]
-- =============================================
-- OLD PROC IS IN REPORTS.[dbo].[Report_DocumentsSignedPEP]
-- =============================================
CREATE PROCEDURE collection.[Report_DocumentsSignedPEP] 
	@buyers nvarchar(max) = null 
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DROP TABLE IF EXISTS #t_contracts_list
		SELECT
			 ДоговорНомер = dmdz.КодДоговораЗайма
		   , ДоговорДата  = dmdz.ДатаДоговораЗайма
		   , [ПродажаДоговоровДата] = dateadd(year,-2000, ПродажаДоговоров.Дата)
		INTO #t_contracts_list
		FROM dwh2.[dm].[ДоговорЗайма] dmdz
		INNER JOIN	stg.[_1cCMR].[Документ_ПродажаДоговоров_Договоры]	AS	ПродажаДоговоров_Договоры
			ON dmdz.СсылкаДоговораЗайма  = ПродажаДоговоров_Договоры.Договор
		INNER JOIN	stg.[_1cCMR].[Документ_ПродажаДоговоров]			AS ПродажаДоговоров
			ON ПродажаДоговоров.Ссылка =ПродажаДоговоров_Договоры.Ссылка
		INNER JOIN	stg._1cCMR.Справочник_Контрагенты  Контрагенты 
			ON Контрагенты.Ссылка = ПродажаДоговоров.Контрагент
		WHERE   1=1
			AND (CONCAT_WS(' - ',
					 Контрагенты.Наименование
					,dateadd(year,-2000, ПродажаДоговоров.Дата)
				) IN (select value from string_split(@buyers, ','))
			OR	@buyers is null)
		SELECT 
			T.created_at,
			T.GuidДоговораЗайма,
			T.НомерДоговора,
			ДатаДоговора = convert(varchar(19), T.ДатаДоговора, 120),
			T.ФИО,
			T.НомерТелефона,
			T.НазваниеДокумента,
			ДатаОтправкиСМС = convert(varchar(19), T.ДатаОтправкиСМС, 120),
			ДатаПодтверждения= convert(varchar(19), T.ДатаПодтверждения, 120),
			T.КодСМС,
			T.СгенерированнаяЭПклиента
		FROM dbo.dm_DocumentsSignedPEP AS T
		WHERE 1=1
			and НомерДоговора in  (select ДоговорНомер from #t_contracts_list)
		ORDER BY T.НомерДоговора
	END TRY
	BEGIN CATCH
			if @@TRANCOUNT>0
				ROLLBACK TRAN
			;throw 
	END CATCH
END

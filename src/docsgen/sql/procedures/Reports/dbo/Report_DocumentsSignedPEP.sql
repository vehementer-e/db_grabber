-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-05-31
-- Description:	DWH-2603 Реализовать отчет Документы подписанные ПЭП
-- =============================================
/*
EXEC dbo.Report_DocumentsSignedPEP
*/
CREATE PROC dbo.Report_DocumentsSignedPEP
	@buyers nvarchar(max) = null 
	--@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY
/*
	--SELECT @isDebug = isnull(@isDebug, 0)
	declare @dt_from date
	if @dtFrom is not null
		set @dt_from=@dtFrom
	else set @dt_from=format(getdate(),'yyyyMM01')

	declare @dt_to date
	if @dtTo is not null
		set @dt_to=dateadd(day,1,@dtTo)
	else set @dt_to=dateadd(day,1,cast(getdate() as date))
	*/
;with cte as 
(
	select 
		ДоговорНомер = Договор.Код
		,ДоговорДата = dateadd(year,-2000, Договор.Дата)
		,[ПродажаДоговоровДата] = dateadd(year,-2000, ПродажаДоговоров.Дата)
	from		stg.[_1cCMR].[Справочник_Договоры] Договор
	inner join	stg.[_1cCMR].[Документ_ПродажаДоговоров_Договоры] ПродажаДоговоров_Договоры
		on Договор.ССылка  = ПродажаДоговоров_Договоры.Договор
	inner join  stg.[_1cCMR].[Документ_ПродажаДоговоров]	ПродажаДоговоров
		on ПродажаДоговоров.Ссылка =ПродажаДоговоров_Договоры.Ссылка
	inner join  stg._1cCMR.Справочник_Контрагенты  Контрагенты 
		on Контрагенты.Ссылка = ПродажаДоговоров.Контрагент
	where 1=1
		--and ПродажаДоговоров.Контрагент = 0xB8158548A1C7AF7B11EF1E90680C3B0D --АО "ООО ПКО «Агентство ЮВС»"
		--and dateadd(year,-2000, ПродажаДоговоров.Дата) = '2024-05-30 10:00:00'
		----Договор.Код in (select [ID кредитного договора в банке (уник# значения)] from stg.files.[BP-4339 брс])
		
		
		-- 2024-07-09 Никитин
		and (CONCAT_WS(' - ', Контрагенты.Наименование  
,dateadd(year,-2000, ПродажаДоговоров.Дата)) in (select value from string_split(@buyers, ','))
		or  @buyers is null)
 
		--AND ПродажаДоговоров.Контрагент = 0xB819C20E1155A55311EF6084861E4F95 --'АО "Банк Русский Стандарт"'
		--AND dateadd(year,-2000, ПродажаДоговоров.Дата) = '2024-08-22 10:00:00'

	--order by ДоговорДата
	--select * from  stg._1cCMR.Справочник_Контрагенты

)
	SELECT 
		T.created_at,
		T.GuidДоговораЗайма,
		T.НомерДоговора,
		ДатаДоговора = convert(varchar(19), T.ДатаДоговора, 120),
		T.ФИО,
		T.НомерТелефона,
		T.НазваниеДокумента,
		--T.ДатаОтправкиСМС,
		ДатаОтправкиСМС = convert(varchar(19), T.ДатаОтправкиСМС, 120),
		--T.ДатаПодтверждения,
		ДатаПодтверждения= convert(varchar(19), T.ДатаПодтверждения, 120),
		T.КодСМС,
		T.СгенерированнаяЭПклиента
	FROM dbo.dm_DocumentsSignedPEP AS T
	WHERE 1=1
		--AND @dt_from <= T.ДатаДоговора AND T.ДатаДоговора <= @dt_to
		and НомерДоговора in  (select ДоговорНомер from cte)

	/*
	-- встреча 2025-08-06. Диана Сухинина Отчет по Цессии
	-- добавить договора, которых нет в dbo.dm_DocumentsSignedPEP
	union
	select distinct
		created_at = getdate(),
		d.GuidДоговораЗайма,
		НомерДоговора = D.КодДоговораЗайма,
		ДатаДоговора = D.ДатаДоговораЗайма,
		ФИО = cast(concat_ws(' '
			, D.Фамилия
			, D.Имя
			, D.Отчество) AS nvarchar(250)),
		НомерТелефона = Клиент_Телефон.НомерТелефонаБезКодов,
		НазваниеДокумента = null,
		ДатаОтправкиСМС = null,
		ДатаПодтверждения= null,
		КодСМС = null,
		СгенерированнаяЭПклиента = null
	from cte as c
		left join dbo.dm_DocumentsSignedPEP AS T
			on T.НомерДоговора = c.ДоговорНомер
		inner join dwh2.hub.ДоговорЗайма AS D
			ON D.КодДоговораЗайма = c.ДоговорНомер
		LEFT join dwh2.link.v_Клиент_ДоговорЗайма Клиент_ДоговорЗайма
			on Клиент_ДоговорЗайма.КодДоговораЗайма = d.КодДоговораЗайма
		LEFT join dwh2.sat.Клиент_Телефон Клиент_Телефон 
			on Клиент_Телефон.GuidКлиент = Клиент_ДоговорЗайма.GuidКлиент
			and Клиент_Телефон.nRow =1 
	where T.НомерДоговора is null --нет в dbo.dm_DocumentsSignedPEP
	*/

	ORDER BY T.НомерДоговора

END TRY
BEGIN CATCH
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
END CATCH


END
-- =============================================
-- Author:		А.Никитин
-- Create date: 2026-02-23
-- Description:	DWH-470 отчет для выгрузки в финцерт
-- =============================================
/*
exec Reports.fraud.Report_FinCERT
	@dtFrom = '2026-02-20'
	,@dtTo = '2026-02-21'
	--,@requestNumber = '26022324157274'
	,@isDebug = 1

exec Reports.fraud.Report_FinCERT
	@requestNumber = '26022324157274'
	,@isDebug = 1

*/
CREATE PROC fraud.Report_FinCERT
	--@Page nvarchar(100) = 'Detail'
	@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'
	,@requestNumber varchar(100) = NULL
	--,@bki_name varchar(1000) = NULL
	--,@entity_name varchar(1000) = NULL
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @dt_from date, @dt_to date

	IF @dtFrom is not NULL BEGIN
		SET @dt_from = @dtFrom
	END 
	ELSE BEGIN
		--SET @dt_from = cast(format(getdate(),'yyyyMM01') AS date)	         
		SET @dt_from = cast(dateadd(day, -1, getdate()) AS date)
	END

	IF @dtTo is not NULL BEGIN
		IF @dtTo > cast(getdate() AS date) BEGIN
			SELECT @dtTo = cast(getdate() AS date)
		END

		SET @dt_to = dateadd(day,1,@dtTo)
		--SET @dt_to = @dtTo
	END
	ELSE BEGIN
		SET @dt_to = dateadd(day,1,cast(getdate() as date))
		--SET @dt_to = cast(getdate() as date)
	END 

	drop table if exists #t_Заявка
	create table #t_Заявка
	(
		СсылкаЗаявки binary(16),
		НомерЗаявки nvarchar(255),
		GuidЗаявки uniqueidentifier,
		ДатаЗаявки datetime,
		[Серия Паспорта] nvarchar(255),
		[Номер Паспорта] nvarchar(255),
		[ФИО клиента] nvarchar(255),
		[Телефон клиента] nvarchar(255)
	)
	create clustered index cix on #t_Заявка(GuidЗаявки)

	if @requestNumber is not null begin
		insert #t_Заявка(СсылкаЗаявки, НомерЗаявки, GuidЗаявки, ДатаЗаявки, [Серия Паспорта], 
			[Номер Паспорта], [ФИО клиента], [Телефон клиента])
		select 
			r.СсылкаЗаявки,
			r.НомерЗаявки,
			r.GuidЗаявки,
			r.ДатаЗаявки,
			[Серия Паспорта] = replace(r.[Серия Паспорта],' ',''),
			[Номер Паспорта] = replace(r.[Номер Паспорта],' ',''),
			nullif(trim(r.ФИО), ''),
			[Телефон клиента] = concat('+7', r.НомераТелефоновБезСимволов)
		from dwh2.hub.Заявка as r
		where r.НомерЗаявки = @requestNumber
	end
	else begin
		insert #t_Заявка(СсылкаЗаявки, НомерЗаявки, GuidЗаявки, ДатаЗаявки, [Серия Паспорта],
			[Номер Паспорта], [ФИО клиента], [Телефон клиента])
		select 
			r.СсылкаЗаявки,
			r.НомерЗаявки,
			r.GuidЗаявки,
			r.ДатаЗаявки,
			[Серия Паспорта] = replace(r.[Серия Паспорта],' ',''),
			[Номер Паспорта] = replace(r.[Номер Паспорта],' ',''),
			nullif(trim(r.ФИО), ''),
			[Телефон клиента] = concat('+7', r.НомераТелефоновБезСимволов)
		from dwh2.hub.Заявка as r
		where @dt_from <= r.ДатаЗаявки and r.ДатаЗаявки < @dt_to
		and  nullif(НомерЗаявки,'') is not null
	end

	if @isDebug = 1 begin
		drop table if exists ##t_Заявка
		select * into ##t_Заявка from #t_Заявка
	end


	--определять номер банковского счета по логике:
	--если заявка не дошла до способа выдачи, 
	--то по умолчанию устанавливать номер счета и БИК МФО для выдачи по СБП
	drop table if exists #t_СчетаПлательщика

	select 
		MDS_СпособыВыдачи.КодСпособаВыдачи,
		НаименованиеСпособаВыдачи = MDS_СпособыВыдачи.Наименование,
		НомерСчетаПлательщика = БанковскиеСчета.НомерСчета,
		БИКбанкаПлательщика = Банки.КодЭлемента,
		ИННплательщика = cast('7730634468' as varchar(30)), --ООО МФК "КарМани"
		rn = row_number() over(partition by MDS_СпособыВыдачи.КодСпособаВыдачи order by getdate())
	into #t_СчетаПлательщика
	--select *
	from Stg._1cMDS.Справочник_СпособыВыдачи as MDS_СпособыВыдачи
		--в Справочник_ПривязкиБанковскихСчетов 
		--ищем запись по условиям:
		--1. тип привязки = 'СпособВыдачи'
		--2. действующая на нужную дату
		--	пока берем действующую на ДатаВыдачи 
		--	to do: на ДатуПлатежа из _1cCMR.Документ_ВыдачаДенежныхСредств_Платежи
		inner join (
			select 
				dt_from = dateadd(year, -2000, ПривБС.ДатаНачалаДействия),
				dt_to = 
					lag(dateadd(year, -2000, ПривБС.ДатаНачалаДействия), 1, '3000-01-01')
						over(
							partition by ПривБС.СпособВыдачи
							order by ПривБС.ДатаНачалаДействия
							),
				ПривБС.*
			from Stg._1cMDS.Справочник_ПривязкиБанковскихСчетов as ПривБС
			where ПривБС.ТипПривязкиСчета = (
					select ТипыПривязкиБС.Ссылка
					from Stg._1cMDS.Перечисление_ТипыПривязкиБанковскихСчетов as ТипыПривязкиБС
					where ТипыПривязкиБС.Имя = 'СпособВыдачи'
				)
		) as ПривязкиБС
			on ПривязкиБС.СпособВыдачи = MDS_СпособыВыдачи.Ссылка
			--and ПривязкиБС.dt_from <= v.ДатаВыдачи and v.ДатаВыдачи < ПривязкиБС.dt_to
			and ПривязкиБС.dt_from <= cast(getdate() as date) and cast(getdate() as date) < ПривязкиБС.dt_to

		inner join Stg._1cMDS.Справочник_БанковскиеСчета as БанковскиеСчета
			on БанковскиеСчета.Ссылка = ПривязкиБС.БанковскийСчет
		inner join Stg._1cMDS.Справочник_Банки as Банки
			on Банки.Ссылка = БанковскиеСчета.Банк
	where 1=1
		--and MDS_СпособыВыдачи.КодСпособаВыдачи = 'ЧерезECommPayСБП' --Через ECommPay СБП

	if @isDebug = 1 begin
		drop table if exists ##t_СчетаПлательщика
		select * into ##t_СчетаПлательщика from #t_СчетаПлательщика
	end



	drop table if exists #t_Report_FinCERT

	select
		--информация о заемщике
		Заявка.СсылкаЗаявки,
		[Номер заявки] = Заявка.НомерЗаявки,
		Заявка.GuidЗаявки,
		Заявка.[Серия Паспорта],
		Заявка.[Номер Паспорта],
		[Хеш паспорта] = 
		lower(
			convert(
				varchar(64), 
				hashbytes('SHA2_256', concat(Заявка.[Серия Паспорта],Заявка.[Номер Паспорта])),
				2
			)
		),
		[ИНН Клиента] = Клиент_ИНН.ИНН,
		--реквизиты плательщика
		[Способ реализации перевода в Заявке] = СпособВыдачиЗайма.Наименование,
		[Номер договора займа] = Договор_Заявка.КодДоговораЗайма,
		[Дата договора займа/Дата заведения заявки] = 
			format(
				cast(isnull(Договор.ДатаДоговораЗайма, Заявка.ДатаЗаявки) as date),
				'dd.MM.yyyy'
			),
		[Сумма операции] = isnull(isnull(ВыдачаДС.Платежи_СуммаПлатежа, ВыдачаДС.Выдача_Сумма), 0),
		Валюта = 'руб',
		[Дата операции] = 
			isnull(
				format(
					cast(isnull(ВыдачаДС.Платежи_ДатаПлатежа, ВыдачаДС.Выдача_Дата) as date),
					'dd.MM.yyyy'
				),
				'-'
			),
		[Время операции] = 
			isnull(
				--format(isnull(ВыдачаДС.Платежи_ДатаПлатежа, ВыдачаДС.Выдача_Дата),'hh:mm'),
				cast(cast(isnull(ВыдачаДС.Платежи_ДатаПлатежа, ВыдачаДС.Выдача_Дата) as time) as varchar(5)),
				'-'
			),

		--если заявка не дошла до способа выдачи, 
		--то по умолчанию устанавливать номер счета и БИК МФО для выдачи по СБП
		[Номер банковского счета МФО] = 
			case when ВыдачаДС.GuidВыдачаДенежныхСредств is not null 
				then ВыдачаДС.НомерСчетаПлательщика
				else СчетаПлательщика.НомерСчетаПлательщика 
			end,
		[БИК МФО] = 
			case when ВыдачаДС.GuidВыдачаДенежныхСредств is not null 
				then ВыдачаДС.БИКбанкаПлательщика
				else СчетаПлательщика.БИКбанкаПлательщика
			end,
		[ИНН МФО] = 
			case when ВыдачаДС.GuidВыдачаДенежныхСредств is not null 
				then ВыдачаДС.ИННплательщика
				else СчетаПлательщика.ИННплательщика
			end,

		--
		[Текущий статус Заявки] = Заявка_ТекущийСтатус.Наименование,
		[Текущий статус Договора] = Договор_ТекущийСтатус.ТекущийСтатусДоговора,
		[Была выдача] = case when ВыдачаДС.GuidВыдачаДенежныхСредств is not null then 'Да' else 'Нет' end,
		--реквизиты получателя
		[Способ реализации перевода] = isnull(ВыдачаДС.СпособВыдачи_Наименование, СпособВыдачиЗайма.Наименование),
		[Номер телефона получателя] = 
			case 
				when ВыдачаДС.СпособВыдачи_Код in ('ЧерезECommPayСБП') --Через ECommPay СБП
				then isnull('+'+ВыдачаДС.ЧерезECommPayСБП_Phone, '+78006009393')
				else null
			end,
		[СБП MID] = 
			case 
				when ВыдачаДС.СпособВыдачи_Код in ('ЧерезECommPayСБП') --Через ECommPay СБП
				then ВыдачаДС.БанкиСБП_ИдентификаторУчастникаСБП
				else null
			end,
		[Полный номер банковского счета заемщика] = ВыдачаДС.НаСчетДилера_НомерСчетаЗаемщика,
		[БИК банка банка заемщика] = ВыдачаДС.Банк_БИК,
		[Токен банковской карты] = ВыдачаДС.НаКартуЧерезТокен_IssuanceCardToken,
		[Uid кредита БКИ] = Договор.УникальныйИдентификаторОбъектаБКИ,
		[payment id] = ВыдачаДС.Платежи_ИдентификаторПлатежа,
		[operation id] = ВыдачаДС.Платежи_ИдентификаторПлатежнойСистемы,
		--DWH-554
		[ФИО клиента] = isnull(Клиент_Заявка.ФИО, Заявка.[ФИО клиента]),
		[Телефон МФО] = '8006009393',
		[Время заявки] = format(Заявка.ДатаЗаявки,'HH:mm'),
		[Номер счета МФО/БИК МФО] = concat(
			'[',
			--[Номер банковского счета МФО]
			case when ВыдачаДС.GuidВыдачаДенежныхСредств is not null 
				then ВыдачаДС.НомерСчетаПлательщика
				else СчетаПлательщика.НомерСчетаПлательщика 
			end,
			']:[',
			--[БИК МФО]
			case when ВыдачаДС.GuidВыдачаДенежныхСредств is not null 
				then ВыдачаДС.БИКбанкаПлательщика
				else СчетаПлательщика.БИКбанкаПлательщика
			end,
			']'
		),
		[Телефон клиента] = Заявка.[Телефон клиента]
	into #t_Report_FinCERT
	from #t_Заявка as Заявка
		left join dwh2.link.v_СпособВыдачиЗайма_Заявка AS СпособВыдачиЗайма
			on СпособВыдачиЗайма.GuidЗаявки = Заявка.GuidЗаявки
		left join #t_СчетаПлательщика as СчетаПлательщика
			on СчетаПлательщика.КодСпособаВыдачи = 'ЧерезECommPayСБП' --Через ECommPay СБП
			and СчетаПлательщика.rn = 1
		left join dwh2.link.v_ТекущийСтатус_Заявка AS Заявка_ТекущийСтатус
			ON Заявка_ТекущийСтатус.GuidЗаявки = Заявка.GuidЗаявки
		left join dwh2.link.v_Клиент_Заявка as Клиент_Заявка
			on Клиент_Заявка.GuidЗаявки = Заявка.GuidЗаявки
		left join dwh2.dm.v_Клиент_ИНН as Клиент_ИНН
			on Клиент_ИНН.GuidКлиент = Клиент_Заявка.GuidКлиент
		left join dwh2.link.ДоговорЗайма_Заявка as Договор_Заявка
			on Договор_Заявка.GuidЗаявки = Заявка.GuidЗаявки
		left join dwh2.hub.ДоговорЗайма as Договор
			on Договор.КодДоговораЗайма = Договор_Заявка.КодДоговораЗайма
		left join dwh2.sat.ДоговорЗайма_ТекущийСтатус as Договор_ТекущийСтатус
			on Договор_ТекущийСтатус.КодДоговораЗайма = Договор_Заявка.КодДоговораЗайма
		left join dwh2.dm.ВыдачаДенежныхСредств as ВыдачаДС
			on ВыдачаДС.КодДоговораЗайма = Договор_Заявка.КодДоговораЗайма
			and ВыдачаДС.Выдача_isDelete = 0
			and ВыдачаДС.Выдача_Проведен = 0x1
			and (
				(
					ВыдачаДС.СпособВыдачи_Код in ('ЧерезECommPayСБП')
					and ВыдачаДС.ЧерезECommPayСБП_PaymentAttempt_IsDeleted = 0
					and ВыдачаДС.ЧерезECommPayСБП_PaymentAttempt_IsActive = 1
					and ВыдачаДС.ЧерезECommPayСБП_IsDeleted = 0
				)
				or
				isnull(ВыдачаДС.СпособВыдачи_Код, '*') not in ('ЧерезECommPayСБП')
			)

	if @isDebug = 1 begin
		drop table if exists ##t_Report_FinCERT
		select * into ##t_Report_FinCERT from #t_Report_FinCERT
	end



	select
		GuidЗаявки,
		[Номер заявки],
		[Хеш паспорта],
		[ИНН Клиента],
		--реквизиты плательщика
		[Способ реализации перевода в Заявке],
		[Номер договора займа],
		[Дата договора займа/Дата заведения заявки],
		[Сумма операции],
		Валюта,
		[Дата операции],
		[Время операции],
		[Номер банковского счета МФО],
		[БИК МФО],
		[ИНН МФО],
		--
		[Текущий статус Заявки],
		[Текущий статус Договора],
		[Была выдача],
		--реквизиты получателя
		[Способ реализации перевода],
		[Номер телефона получателя],
		[СБП MID],
		[Полный номер банковского счета заемщика],
		[БИК банка банка заемщика],
		[Токен банковской карты],
		[Uid кредита БКИ],
		[payment id],
		[operation id],
		[ФИО клиента],
		[Телефон МФО],
		[Время заявки],
		[Номер счета МФО/БИК МФО],
		[Телефон клиента]
	from #t_Report_FinCERT as f
	where 1=1
		--test
		--and [Способ реализации перевода] is not null
		--and [Была выдача] = 'Да'
	order by [Номер заявки]

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'exec fraud.Report_FinCERT ',
		--'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	--SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'fraud.Report_FinCERT',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
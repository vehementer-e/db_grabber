/*
drop table if exists dbo.dm_DocumentsSignedPEP
truncate table dm_DocumentsSignedPEP
exec dbo.fill_dm_DocumentsSignedPEP
*/
-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-05-31
-- Description:	DWH-2603 Реализовать отчет Документы подписанные ПЭП
-- =============================================
/*
*/
CREATE PROC dbo.fill_dm_DocumentsSignedPEP
	@days int = 10, --кол-во дней для пересчета
	--@RequestNumber varchar(20) = NULL, -- расчет по одной заявке
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	declare @dateStart date = '2000-01-01'
	if OBJECT_ID('dbo.dm_DocumentsSignedPEP') is not null
		set @dateStart= dateadd(dd, -@days, isnull((select max(ДатаПодтверждения) from dbo.dm_DocumentsSignedPEP ),'2000-01-01'))

	BEGIN TRY

		DROP TABLE IF EXISTS #t_document_name
		CREATE TABLE #t_document_name(document_name nvarchar(250))
		INSERT #t_document_name(document_name)
		VALUES
			(N'График платежей предварительный ПЭП'),
			(N'График платежей предварительный ПЭП (Все Про100)'),
			--(N'График платежей предварительный ПЭП (ВсеПро100 Смарт)'),

			(N'Заявление-Анкета ПЭП финальное'),
			(N'Заявление-Анкета ПЭП финальное (Все Про100)'),
		--	(N'Заявление-Анкета ПЭП финальное (ВсеПро100 Смарт)'),

			(N'Индивидуальные условия ПЭП'),
			(N'Индивидуальные условия ПЭП (Все Про100)'),
			(N'Индивидуальные условия ПЭП (ВсеПро100 Смарт)'),

			(N'Согласие на запрос кредитной истории ПЭП'),

			(N'Согласие на обработку персональных данных общее ПЭП'),
			(N'Согласие на обработку персональных данных общее и Техмани ПЭП'),
			
			(N'Согласие на обработку персональных данных ПЭП (Все Про100)'),
			--(N'Согласие на обработку персональных данных ПЭП (ВсеПро100 Смарт)'),
			(N'Согласие на обработку персональных данных ПЭП (ВсеПро100)'),
			
			--2025-08-11 Новый тип документа!
			(N'Согласие на обработку персональных данных ООО МФК Кармани ПЭП'),

			(N'Согласие на передачу персональных данных третьим лицам (платежные системы и доп. услуги) ПЭП'),

			(N'Соглашение об электронном взаимодействии ПЭП'),
			(N'Соглашение об электронном взаимодействии ПЭП (Все Про100)'),
			--(N'Соглашение об электронном взаимодействии ПЭП (ВсеПро100 Смарт)'),
			(N'Соглашение об электронном взаимодействии ПЭП (ВсеПро100)')
		
		DROP TABLE IF EXISTS #t_dm_DocumentsSignedPEP
		
		select 
		t.*
		--Объединяем документы
		,nRow = ROW_NUMBER() OVER(partition by t.GuidДоговораЗайма
			,case 
			when НазваниеДокумента in (N'Соглашение об электронном взаимодействии ПЭП',
				N'Соглашение об электронном взаимодействии ПЭП (Все Про100)',
				N'Соглашение об электронном взаимодействии ПЭП (ВсеПро100)')
			then 'Соглашение об электронном взаимодействии ПЭП'
			when НазваниеДокумента  in (N'Согласие на обработку персональных данных общее ПЭП'
				, N'Согласие на обработку персональных данных общее и Техмани ПЭП')
			 then 'Согласие на обработку персональных данных общее ПЭП'

			when НазваниеДокумента in (
			   N'Согласие на обработку персональных данных ПЭП (Все Про100)'
				, N'Согласие на обработку персональных данных ПЭП (ВсеПро100)'
				) 
				then 'Согласие на обработку персональных данных ПЭП'
			
			else НазваниеДокумента end
		order by ДатаПодтверждения desc)
		,SourceSystem =  cast('LK' as nvarchar(255))
		INTO #t_dm_DocumentsSignedPEP
		from (
		SELECT --TOP 100 
			created_at = getdate(),
			D.GuidДоговораЗайма,
			НомерДоговора = cast(D.КодДоговораЗайма AS nvarchar(50)),
			ДатаДоговора = D.ДатаДоговораЗайма,
			ФИО = cast(concat_ws(' '
				, D.Фамилия
				, D.Имя
				, D.Отчество) AS nvarchar(250)),
			НомерТелефона = PEP.login,
            НазваниеДокумента = PEP.document_name,
			ДатаОтправкиСМС = PEP.sms_send_date,
			ДатаПодтверждения = PEP.sms_input_date,
			КодСМС = PEP.sms_code,
			СгенерированнаяЭПклиента = PEP.sms_id
			
			--берем документ который был подписан последней SMS
		FROM Stg._LK.pep_activity_log AS PEP
			INNER JOIN Stg._LK.requests AS R
				ON R.id = PEP.request_id
			INNER JOIN dwh2.hub.ДоговорЗайма AS D
				ON D.КодДоговораЗайма = R.num_1c
			INNER JOIN #t_document_name AS DN
				ON DN.document_name = PEP.document_name
		WHERE 1=1
			and PEP.sms_input = 1
			AND PEP.sms_input_date >=@dateStart
			) t
	delete from #t_dm_DocumentsSignedPEP
	where nRow>1
		--DROP TABLE IF EXISTS dbo.dm_DocumentsSignedPEP
		
		/*Собираем из это то что не взяли из LK*/ 	
		
		drop table if exists #t_ДополнительныеРеквизиты_Свойства
		select Ссылка, Заголовок 
		into #t_ДополнительныеРеквизиты_Свойства
			from stg._1cDCMNT.[ПланВидовХарактеристик_ДополнительныеРеквизитыИСведения]
		where Наименование in 
		(
			'Номер заявки (Заем)',
			'Договор залога номер (Заем)'
		)

	drop table if exists #t_ВнутренниеДокументы

	/*получаем индетификатор внутренего документа и как он связан с кодом договора или заявки*/	
	;with cte_ДополнительныеРеквизиты as (
	select ВнутренниеДокументы_Ссылка = ДополнительныеРеквизит.Ссылка
		, Реквизит = Свойства.Заголовок
		, Значение = case ДополнительныеРеквизит.Значение_Тип
				when 0x02 then iif(ДополнительныеРеквизит.Значение_Булево=0x01, '1', '0')
				when 0x03 then FORMAT(ДополнительныеРеквизит.Значение_Число, 'N')
				when 0x04 then FORMAT(dateadd(year,-2000, Значение_Дата), 'yyyy-MM-dd HH:mm:ss')
				when 0x05 then ДополнительныеРеквизит.Значение_Строка
			end
		from   stg._1Cdcmnt.Справочник_ВнутренниеДокументы_ДополнительныеРеквизиты	 ДополнительныеРеквизит
	inner join #t_ДополнительныеРеквизиты_Свойства Свойства 
		on Свойства.Ссылка  = ДополнительныеРеквизит.Свойство
	inner join stg._1Cdcmnt.Справочник_ВнутренниеДокументы  ВнутренниеДокументы
		on ВнутренниеДокументы.Ссылка= ДополнительныеРеквизит.Ссылка
		where  ВнутренниеДокументы.ДатаСоздания>=dateadd(year,2000, @dateStart)
	)	
	select 
		ВнутренниеДокументы_Ссылка
		,КодДоговораЗайма = D.КодДоговораЗайма
		,d.GuidДоговораЗайма
		,D.ДатаДоговораЗайма
		,ФИО = cast(concat_ws(' '
			, D.Фамилия
			, D.Имя
			, D.Отчество) AS nvarchar(250))
		,НомерТелефонаБезКодов = Клиент_Телефон.НомерТелефонаБезКодов
	into #t_ВнутренниеДокументы
	from (
		select ВнутренниеДокументы_Ссылка
			,[Номер заявки] = max(PVT.[Номер заявки])  
			,[Договор залога номер] = max([Договор залога номер])
		from cte_ДополнительныеРеквизиты t
	 	pivot ( 
			max(t.Значение)
			for Реквизит IN (
				[Номер заявки], 
				[Договор залога номер]
				)
		)
		 as PVT
		 group by ВнутренниеДокументы_Ссылка
	 ) t
	 inner join dwh2.hub.ДоговорЗайма AS D
		ON D.КодДоговораЗайма = isnull([Договор залога номер], [Номер заявки])
	 LEFT join dwh2.link.v_Клиент_ДоговорЗайма Клиент_ДоговорЗайма
		on Клиент_ДоговорЗайма.КодДоговораЗайма = d.КодДоговораЗайма
	 LEFT join dwh2.sat.Клиент_Телефон Клиент_Телефон
		on Клиент_Телефон.GuidКлиент = Клиент_ДоговорЗайма.GuidКлиент
			and Клиент_Телефон.nRow =1 

	
	drop table if exists #t_EDOResult
	insert into #t_dm_DocumentsSignedPEP
	(
		 [created_at]
		, [GuidДоговораЗайма]
		, [НомерДоговора]
		, [ДатаДоговора]
		, [ФИО]
		, [НомерТелефона]
		, [НазваниеДокумента]
		, [ДатаОтправкиСМС]
		, [ДатаПодтверждения]
		, [КодСМС]
		, [СгенерированнаяЭПклиента]
		, SourceSystem
)
	select distinct 
	  [created_at] = getdate()
	, [GuidДоговораЗайма]			= t.GuidДоговораЗайма
	, [НомерДоговора]				= t.КодДоговораЗайма
	, [ДатаДоговора]				= t.ДатаДоговораЗайма
	, [ФИО]							= t.[ФИО]
	, [НомерТелефона]				= t.НомерТелефонаБезКодов
	, [НазваниеДокумента]			= t.НазваниеДокумента
	, [ДатаОтправкиСМС]				= t.ДатаОтправкиСМС
	, [ДатаПодтверждения]			= t.ДатаПодтверждения
	, [КодСМС]						= t.КодСМС
	, [СгенерированнаяЭПклиента]	= t.СгенерированнаяЭПклиента
	, SourceSystem					= 'ЭДО'
	from (
	select 
		ВнутренниеДокумент.GuidДоговораЗайма
		,ВнутренниеДокумент.КодДоговораЗайма
		,ВнутренниеДокумент.ДатаДоговораЗайма
		,ВнутренниеДокумент.ФИО
		--,НомерТелефона = PEP.login,
		,НазваниеДокумента = ЖурналПЭП.НаименованиеДокумента
		,ДатаОтправкиСМС = iif(year(ЖурналПЭП.ДатаОтправкиСМС_Клиенту)>3000, dateadd(year,-2000, ЖурналПЭП.ДатаОтправкиСМС_Клиенту), null)
		,ДатаПодтверждения = iif(year(ЖурналПЭП.ДатаОтправкиСМС_Клиентом)>3000, dateadd(year,-2000, ЖурналПЭП.ДатаПодписания), null)
		,КодСМС = ЖурналПЭП.[СМС]
		,НомерТелефонаБезКодов
		,СгенерированнаяЭПклиента = ЖурналПЭП.ТреккерПодписи
		,nRow = ROW_NUMBER() over(partition by ЖурналПЭП.ОбъектПЭП, ЖурналПЭП.НаименованиеДокумента order by Период desc)
		from #t_ВнутренниеДокументы ВнутренниеДокумент
	inner join stg._1Cdcmnt.РегистрСведений_КМ_ЖурналПЭП_ВерсииФайлов ЖурналПЭП
			on ЖурналПЭП.ОбъектПЭП = ВнутренниеДокументы_Ссылка 
		inner join #t_document_name dn on dn.document_name =  ЖурналПЭП.НаименованиеДокумента
	) t
	where t.nRow = 1			
	and ДатаПодтверждения is not null
	and not exists(select top(1) 1 from #t_dm_DocumentsSignedPEP s where s.GuidДоговораЗайма =t.GuidДоговораЗайма
		and s.НазваниеДокумента = t.НазваниеДокумента
		)
	alter table #t_dm_DocumentsSignedPEP
	add hashCol as HASHBYTES('SHA2_256',CONCAT_WS('|'
		,GuidДоговораЗайма
		,НазваниеДокумента
		,НомерТелефона				
		,ДатаОтправкиСМС			
		,ДатаПодтверждения			
		,КодСМС						
		,СгенерированнаяЭПклиента	
			)			
		)
		
		if OBJECT_ID('dbo.dm_DocumentsSignedPEP') is null
		BEGIN
			--alter table dbo.dm_DocumentsSignedPEP
			--	add SourceSystem nvarchar(255)
				
			SELECT TOP 0 
				  [created_at]
				, [GuidДоговораЗайма]
				, [НомерДоговора]
				, [ДатаДоговора]
				, [ФИО]
				, [НомерТелефона]
				, [НазваниеДокумента]
				, [ДатаОтправкиСМС]
				, [ДатаПодтверждения]
				, [КодСМС]
				, [СгенерированнаяЭПклиента]
				, SourceSystem
			INTO dbo.dm_DocumentsSignedPEP
			FROM #t_dm_DocumentsSignedPEP AS D
        END

		if exists(select top(1) 1 from #t_dm_DocumentsSignedPEP)
		BEGIN
			BEGIN TRAN

			merge dbo.dm_DocumentsSignedPEP t
			using #t_dm_DocumentsSignedPEP s
			on s.GuidДоговораЗайма = t.GuidДоговораЗайма
				and s.НазваниеДокумента = t.НазваниеДокумента
				
			when not matched then insert
			(
				created_at,
				GuidДоговораЗайма,
				НомерДоговора,
				ДатаДоговора,
				ФИО,
				НомерТелефона,
				НазваниеДокумента,
				ДатаОтправкиСМС,
				ДатаПодтверждения,
				КодСМС,
				СгенерированнаяЭПклиента,
				SourceSystem
			)
			values(
				s.created_at,
				s.GuidДоговораЗайма,
				s.НомерДоговора,
				s.ДатаДоговора,
				s.ФИО,
				s.НомерТелефона,
				s.НазваниеДокумента,
				s.ДатаОтправкиСМС,
				s.ДатаПодтверждения,
				s.КодСМС,
				s.СгенерированнаяЭПклиента,
				s.SourceSystem
			) 
			when matched  and s.hashCol != t.hashCol
				then update
				set
					created_at					= s.created_at
					,НомерТелефона				= s.НомерТелефона
					,ДатаОтправкиСМС			= s.ДатаОтправкиСМС
					,ДатаПодтверждения			= s.ДатаПодтверждения
					,КодСМС						= s.КодСМС
					,СгенерированнаяЭПклиента	= s.СгенерированнаяЭПклиента
					,SourceSystem				= s.SourceSystem
				;
				--TRUNCATE TABLE dbo.dm_DocumentsSignedPEP
				/*
				DELETE PEP
				FROM dbo.dm_DocumentsSignedPEP AS PEP
				WHERE 1=1
					AND PEP.ДатаПодтверждения >= dateadd(DAY, -@days, cast(getdate() AS date))


				INSERT dbo.dm_DocumentsSignedPEP
				SELECT 
					T.created_at,
					T.GuidДоговораЗайма,
					T.НомерДоговора,
					T.ДатаДоговора,
					T.ФИО,
					T.НомерТелефона,
					T.НазваниеДокумента,
					T.ДатаОтправкиСМС,
					T.ДатаПодтверждения,
					T.КодСМС,
					T.СгенерированнаяЭПклиента
				FROM #t_dm_DocumentsSignedPEP AS T
				*/
			COMMIT
		END


		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_dm_DocumentsSignedPEP
			SELECT * INTO ##t_dm_DocumentsSignedPEP FROM #t_dm_DocumentsSignedPEP AS C
		END

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END


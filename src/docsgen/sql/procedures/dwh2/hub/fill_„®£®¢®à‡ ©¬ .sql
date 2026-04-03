
--[hub].[fill_ДоговорЗайма] @mode= 0, @isDebug =1
-- [hub].[fill_ДоговорЗайма] @DealNumber = '26022124151098', @mode =2, @isDebug= 1
/*
26011724020966
26011924026850
26012524048831
26013024071056
26020124077712
26020224079443
26020624095709
26020824102410
26011624018144
26011724021846
26012324040194
26012324041610
26012524049286
*/
--select * from ##t_ДоговорЗайма
CREATE PROC [hub].[fill_ДоговорЗайма]
	@mode int = 1 -- 0 - full, 1 - increment, 2 - from dbo.СписокДоговоровЗаймаДляПересчетаDataVault
	,@DealNumber nvarchar(30) = NULL
	,@isDebug int = 0
as
begin
	--truncate table hub.ДоговорЗайма
begin TRY

	declare @DealСсылка binary(16) = (select Ссылка from Stg._1cCMR.Справочник_Договоры Договор
			where Договор.Код = @DealNumber)
		set @DealСсылка = nullif(@DealСсылка, 0x)
	

	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
		,@rowVersion binary(8) = 0x0
		,@Заявка_ВерсияДанных binary(8) = 0x0
		,@lastContractDate date = '2000-01-01'
	drop table if exists #t_ДоговорЗайма
	if OBJECT_ID ('hub.ДоговорЗайма') is not NULL
		AND @mode = 1
	begin
		select @rowVersion  = isnull(max(ВерсияДанных), 0x0) 
		,@lastContractDate = isnull(max(ДатаДоговораЗайма), '2000-01-01')
		,@Заявка_ВерсияДанных = isnull(max(Заявка_ВерсияДанных),0x0)
		from hub.ДоговорЗайма
		select 
			@rowVersion -= 100
			,@Заявка_ВерсияДанных = -100
			,@lastContractDate = DATEADD(dd,-30, @lastContractDate)
	end
	if @isDebug =1 	select @DealNumber, @DealСсылка, @rowVersion, @lastContractDate

	/*Сбор информации по УникальныйИдентификаторДоговора в бки*/
	drop table if exists #t_УникальныйИдентификаторДоговора
	select ДоговорЗайма
	,УникальныйИдентификаторДоговора
	,rn=1
	into #t_УникальныйИдентификаторДоговора
		from (	SELECT
						T.ДоговорЗайма
						,УникальныйИдентификаторДоговора = cast(T.Значение_Строка AS varchar(100))
						,RN = row_number() OVER(PARTITION BY T.ДоговорЗайма ORDER BY T.Период DESC)
						,Период
					FROM Stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров AS T
						INNER JOIN Stg._1cCMR.Справочник_ВидыДополнительнойИнформацииДоговоры AS S
							ON S.Ссылка = T.ВидДополнительнойИнформации
							AND S.Наименование ='Уникальный идентификатор объекта БКИ'
					WHERE T.Значение_Строка IS NOT NULL
					and dateadd(year,-2000,Период)>= @lastContractDate
					and (T.ДоговорЗайма = @DealСсылка or @DealСсылка is null)

					) t
	where t.RN = 1

	union
	select ДоговорЗайма, УникальныйИдентификаторДоговора, rn=2 from (
	select ДоговорЗайма = Договор.Ссылка
	,УникальныйИдентификаторДоговора
	,RN = row_number() OVER(PARTITION BY Договор.Ссылка ORDER BY BKI2.ДатаСоздания DESC)
	  from Stg._1cIntegration.РегистрСведений_УникальныеИдентификаторыДоговоров AS BKI2
	  inner join Stg._1cCMR.Справочник_Договоры AS Договор
				ON Договор.Код = BKI2.ОбъектЗайма 
	where len(УникальныйИдентификаторДоговора) >0
	and (Договор.Ссылка = @DealСсылка or @DealСсылка is null)
	and dateadd(year,-2000,BKI2.ДатаСоздания)>= @lastContractDate
				) t
				where t.RN=1

	print concat_ws(' ','inserted into #t_УникальныйИдентификаторДоговора', @@ROWCOUNT)

	if @isDebug = 1
	begin
		DROP TABLE IF EXISTS ##t_УникальныйИдентификаторДоговора
		SELECT * INTO ##t_УникальныйИдентификаторДоговора FROM #t_УникальныйИдентификаторДоговора
		--RETURN 0
		print concat_ws(' ','inserted into ##t_УникальныйИдентификаторДоговора', @@ROWCOUNT)
	end
	create index cix on #t_УникальныйИдентификаторДоговора(ДоговорЗайма)
	delete t from  #t_УникальныйИдентификаторДоговора t
	where not exists(select top(1) 1 from Stg._1cCMR.Справочник_Договоры Договор
		where Договор.Ссылка =t.ДоговорЗайма
		and( Договор.ПометкаУдаления = 0x00
		and charindex('СДRC', Договор.Код) = 0 and charindex('СЗRC', Договор.Код) =0
		)
		
	 )
	 print concat_ws(' ','delete from #t_УникальныйИдентификаторДоговора', @@ROWCOUNT)
	 
	--удаляем дубликаты, т.к. из источника rn = 1 более верные
	;with cte as (
	select *, nrow = ROW_NUMBER() over(partition by ДоговорЗайма order by  rn) from #t_УникальныйИдентификаторДоговора
	)
	delete from cte
	where nrow>1
	print concat_ws(' ','delete dublicate from #t_УникальныйИдентификаторДоговора', @@ROWCOUNT)
	

	drop table if exists #t_СписокДоговоровЗаймаДляПересчетаDataVault
	create table #t_СписокДоговоровЗаймаДляПересчетаDataVault(
		КодДоговораЗайма nvarchar(30) not null
	)
	create unique index ix1 on #t_СписокДоговоровЗаймаДляПересчетаDataVault(КодДоговораЗайма)

	if @mode = 2 begin
		insert #t_СписокДоговоровЗаймаДляПересчетаDataVault(КодДоговораЗайма)
		select distinct i.КодДоговораЗайма
		from dbo.СписокДоговоровЗаймаДляПересчетаDataVault as i
		where i.КодДоговораЗайма is not null
	end

	
	drop table if exists #tChanges
	create table #tChanges
	(
		Ссылка	binary(16)
		,SourceChanges nvarchar(255)
		--,  Код nvarchar(255)
	)
	
	insert into #tChanges
	/*Выборка договоров у которых изменились какие либо данные*/
	select Ссылка, 'Изменился что то в договоре'
	from 
	(
		select Ссылка,  Код, ВерсияДанных
		from (SELECT Ссылка,  Код, ВерсияДанных, ПометкаУдаления
		,rn = ROW_NUMBER() over(partition by Договор.Код order by Договор.ПометкаУдаления asc--нужны не удаленные 
			, Договор.ВерсияДанных desc--последняя версия
			)
		FROM Stg._1cCMR.Справочник_Договоры Договор
		where charindex('СДRC', Договор.Код) = 0 AND charindex('СЗRC', Договор.Код) = 0
		and (Договор.Ссылка = @DealСсылка or @DealСсылка is null)
		) t
		where rn=1
		EXCEPT
		SELECT СсылкаДоговораЗайма, Код = КодДоговораЗайма, ВерсияДанных FROM dwh2.hub.ДоговорЗайма
	) t
	union
	--договора по которым изменился статус
	select Ссылка, 'Изменилась дата текущего статуса'
	from (
		select Ссылка = СсылкаДоговораЗайма, ДатаТекущегоСтатуса = cast(ТекущийСтатус.ДатаТекущегоСтатуса as date)
		from  sat.ДоговорЗайма_ТекущийСтатус AS ТекущийСтатус
		where ТекущийСтатус.ТекущийСтатусДоговора IN ('Погашен', 'Продан', 'Аннулирован')
		and (ТекущийСтатус.СсылкаДоговораЗайма = @DealСсылка or @DealСсылка is null)
		except
		select СсылкаДоговораЗайма, ДатаЗакрытияДоговора from dwh2.hub.ДоговорЗайма
		
		) t
	--договора по которым изменился УникальныйИдентификаторОбъектаБКИ
	union 
	select Ссылка, 'Изменился УникальныйИдентификаторОбъектаБКИ' from (
		 select Ссылка = ДоговорЗайма, УникальныйИдентификаторДоговора from #t_УникальныйИдентификаторДоговора
		 except
		 SELECT СсылкаДоговораЗайма,УникальныйИдентификаторОбъектаБКИ  FROM  dwh2.hub.ДоговорЗайма  
	) t
	
	union /*Выборка договора по параметру*/
	select Ссылка, 'выборка по договору'
	from Stg._1cCMR.Справочник_Договоры Договор
	where 1=1
	 and charindex('СДRC', Договор.Код) = 0 
	 AND charindex('СЗRC', Договор.Код) = 0
	 and Договор.Тестовый = 0x00
	and (Договор.Ссылка = @DealСсылка
		or @mode = 0)
	union

	--T_DWH-388
	--Выборка по списку договоров
	select Ссылка, 'Изменилась заявка'
	from (
		select Ссылка,  Код, Заявка_ВерсияДанных
		from (SELECT 
			Договор.Ссылка,  
			Договор.Код, 
			Договор.ВерсияДанных, 
			Договор.ПометкаУдаления,
			Заявка_ВерсияДанных = cmr_Заявка.ВерсияДанных

		,rn = ROW_NUMBER() over(partition by Договор.Код order by Договор.ПометкаУдаления asc--нужны не удаленные 
			,cmr_Заявка.ВерсияДанных desc, Договор.ВерсияДанных desc--последняя версия
			)
		FROM Stg._1cCMR.Справочник_Договоры Договор
		inner JOIN Stg._1cCMR.Справочник_Заявка AS cmr_Заявка
			on cmr_Заявка.Ссылка = Договор.Заявка
		where charindex('СДRC', Договор.Код) = 0 AND charindex('СЗRC', Договор.Код) = 0
		and (Договор.Ссылка = @DealСсылка or @DealСсылка is null)
		) t
		where rn=1
		EXCEPT
		SELECT СсылкаДоговораЗайма, Код = КодДоговораЗайма, Заявка_ВерсияДанных FROM dwh2.hub.ДоговорЗайма
		
		) t
	union 
	select Ссылка, 'выборка по списку договоров'
	from Stg._1cCMR.Справочник_Договоры Договор
		inner join #t_СписокДоговоровЗаймаДляПересчетаDataVault as i
			on i.КодДоговораЗайма = Договор.Код
	where 1=1
		and charindex('СДRC', Договор.Код) = 0 
		AND charindex('СЗRC', Договор.Код) = 0
		and Договор.Тестовый = 0x00
		and @mode = 2

	print concat_ws(' ','inserted into #tChanges', @@ROWCOUNT)
	if @isDebug = 1
	begin
		DROP TABLE IF EXISTS ##tChanges
		SELECT * INTO ##tChanges FROM #tChanges
		--RETURN 0
		print concat_ws(' ','inserted into ##tChanges', @@ROWCOUNT)
	end
	create clustered index cix on #tChanges(Ссылка)
	;with cte as (
		select *, nRow = ROW_NUMBER() over(partition by Ссылка order by (select 1)) from #tChanges
	)
	delete from cte 
	where nRow>1
	print concat_ws(' ','delete dublicate from #tChanges', @@ROWCOUNT)

	
	if not exists(select top(1) 1 from #tChanges ) and @mode = 1
	begin
		return
	end


	select 		СсылкаДоговораЗайма = Договор.Ссылка
		,GuidДоговораЗайма = cast([dbo].[getGUIDFrom1C_IDRREF](Договор.Ссылка) as uniqueidentifier)
		,КодДоговораЗайма = Договор.Код
		,isDelete = cast(Договор.ПометкаУдаления as bit)

		,ДатаДоговораЗайма					= iif(Договор.Дата>'2001-01-01', dateadd(year, -2000, Договор.Дата), null)
		,Фамилия							= nullif(trim(Договор.Фамилия),'')
		,Имя								= nullif(trim(Договор.Имя),'')
		,Отчество							= nullif(trim(Договор.Отчество),'')
		,ДатаРождения						= iif(Договор.ДатаРождения>'2001-01-01', dateadd(year, -2000, Договор.ДатаРождения), null)

		,Сумма								= cast(Договор.Сумма as money)
		,СуммаЗапрошенная					= cast(Договор.СуммаЗапрошенная AS money)
		,СуммаВыдачи						= cast(Договор.СуммаВыдачи AS money)

		,Срок								= cast(Договор.Срок AS int)
		,IsInstallment						= cast(Договор.IsInstallment as bit)
		,IsSmartInstallment					= cast(Договор.IsSmartInstallment AS bit)

		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,spFillName							= @spName
		,ВерсияДанных						= cast(Договор.ВерсияДанных AS binary(8))

		,УникальныйИдентификаторОбъектаБКИ = BKI.УникальныйИдентификаторДоговора --DWH-2596		
		/*
		Наименование
		------------
		Smart installment
		Installment
		Pdl
		Pts
		Pts31
		Installment promo
		Pdl promo
		*/
		,ТипПродукта = cast(
			CASE lower(cmr_ПодтипыПродуктов.ИдентификаторMDS)
				when 'pts'			then 'ПТС'
				when 'pts31'		then 'ПТС31'
				when 'installment'	then 'Инстоллмент'
				when 'smart-installment' THEN 'Смарт-инстоллмент'
				when 'pdl'			then 'PDL'
				else isnull(nullif(cmr_ПодтипыПродуктов.ИдентификаторMDS,''),'ПТС')
				END AS nvarchar(50))
		,ТипПродукта_Code			= lower(cmr_ТипыПродуктов.ИдентификаторMDS)
		,ТипПродукта_Наименование	= cmr_ТипыПродуктов.Наименование
		,ПодТипПродукта = cast(cmr_ПодтипыПродуктов.Наименование AS nvarchar(50))
		,ПодТипПродукта_Code = cast(cmr_ПодтипыПродуктов.ИдентификаторMDS AS nvarchar(50))
		,ДатаЗакрытияДоговора = isnull(ТекущийСтатус.ДатаТекущегоСтатуса, cast(NULL AS date))

		,ГруппаПродуктов_Code = hub_ГруппаПродуктов.ГруппаПродуктов_Code
		,ГруппаПродуктов_Наименование = hub_ГруппаПродуктов.ГруппаПродуктов_Наименование

		,Link_GuidЗаявка = cast(nullif([dbo].[getGUIDFrom1C_IDRREF](Договор.Заявка), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
		,Link_GuidКлиент = cast(nullif([dbo].[getGUIDFrom1C_IDRREF](Договор.Клиент), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
		,Link_GuidОфис = cast(nullif(dbo.getGUIDFrom1C_IDRREF(ЗаявкаНаЗаймПодПТС.Офис), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
		,rn = ROW_NUMBER() over(partition by Договор.Код order by Договор.ПометкаУдаления asc--нужны не удаленные 
			, Договор.ВерсияДанных desc--последняя версия
			)
		,Заявка_ВерсияДанных = cmr_Заявка.ВерсияДанных
		,НачальнаяПроцентнаяСтавка = Договор.ПроцентнаяСтавка
		,КредитныйПродукт_Наименование = КредитныеПродукты.Наименование
	into #t_ДоговорЗайма
	--SELECT *
	FROM Stg._1cCMR.Справочник_Договоры AS Договор
		inner join #tChanges M
			ON Договор.Ссылка = M.Ссылка
		
		--	AND Договор.ВерсияДанных = M.МаксВерсияДанных
		LEFT JOIN #t_УникальныйИдентификаторДоговора BKI 
			on BKI.ДоговорЗайма =  Договор.Ссылка
		LEFT JOIN Stg._1cCMR.Справочник_Заявка AS cmr_Заявка
			on cmr_Заявка.Ссылка = Договор.Заявка
		LEFT JOIN Stg._1cCMR.Справочник_ТипыПродуктов as cmr_ТипыПродуктов	
			on cmr_ТипыПродуктов.Ссылка = cmr_Заявка.ТипПродукта
		LEFT JOIN Stg._1cCMR.Справочник_ПодтипыПродуктов AS cmr_ПодтипыПродуктов
			on cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка	
		LEFT JOIN sat.ДоговорЗайма_ТекущийСтатус AS ТекущийСтатус
			ON ТекущийСтатус.КодДоговораЗайма = Договор.Код
			AND ТекущийСтатус.ТекущийСтатусДоговора IN ('Погашен', 'Продан', 'Аннулирован')
		--DWH-388
		left join hub.v_hub_ГруппаПродуктов as hub_ГруппаПродуктов
			on hub_ГруппаПродуктов.ПодтипПродуктd_Code = cmr_ПодтипыПродуктов.ИдентификаторMDS
		--DWH-533
		left join Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.Ссылка = Договор.Заявка
		--DWH-534
		left join Stg._1cCMR.Справочник_КредитныеПродукты as КредитныеПродукты
			on КредитныеПродукты.Ссылка = Договор.КредитныйПродукт
	WHERE 
		charindex('СДRC', Договор.Код) = 0 
		AND charindex('СЗRC', Договор.Код) = 0
		and Договор.Тестовый = 0x00
	--where Договор.ВерсияДанных >= @rowVersion 

	create clustered index cix on #t_ДоговорЗайма(КодДоговораЗайма)
	
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
		--RETURN 0
		print concat_ws(' ','inserted into ##t_ДоговорЗайма', @@ROWCOUNT)

	END
	--есть дубликаты по гуди договора, поэтому делаем по коду, и убираем дубликаты
	
	delete from #t_ДоговорЗайма
	where rn>1
	
	print concat_ws(' ','deleted dublicate from #t_ДоговорЗайма', @@ROWCOUNT)
	if OBJECT_ID('link.ДоговорЗайма_stage') is null
	begin
		CREATE TABLE link.ДоговорЗайма_stage
		(
			[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ДоговорЗайма_stage__Id] DEFAULT (newid()),
			КодДоговораЗайма nvarchar(14) NOT NULL,
			--GuidДоговораЗайма uniqueidentifier NOT NULL,
			ВерсияДанныхДоговораЗайма binary(8) NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_ДоговорЗайма_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.ДоговорЗайма_stage
		ADD CONSTRAINT PK__ДоговорЗайма_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.ДоговорЗайма_stage (LinkName) ON [PRIMARY]
	end

	insert into link.ДоговорЗайма_stage(
		КодДоговораЗайма
		--,GuidДоговораЗайма
		,ВерсияДанныхДоговораЗайма
		,LinkName	
		,LinkGuid			
		,TargetColName
	)
	select distinct 
		КодДоговораЗайма,
		--GuidДоговораЗайма,
		ВерсияДанныхДоговораЗайма = ВерсияДанных,
		LinkName,
		LinkGuid, 
		TargetColName
	from #t_ДоговорЗайма
		CROSS APPLY (
			VALUES 
				  (Link_GuidЗаявка, 'link.ДоговорЗайма_Заявка', 'GuidЗаявки')
				, (Link_GuidКлиент, 'link.Клиент_ДоговорЗайма', 'GuidКлиент')
				, (Link_GuidОфис, 'link.ДоговорЗайма_Офис', 'GuidОфис')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null
		print concat_ws(' ','inserted into ДоговорЗайма_stage', @@ROWCOUNT)
	--заполнение таблиц с линками
	BEGIN TRY
		EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_ДоговорЗайма_and_other'
	END TRY
	BEGIN CATCH
		--??
	END CATCH


	if OBJECT_ID('hub.ДоговорЗайма') is null
	begin
		select top(0)
			СсылкаДоговораЗайма,
            GuidДоговораЗайма,
            КодДоговораЗайма,
            isDelete,
            ДатаДоговораЗайма,
            Фамилия,
            Имя,
            Отчество,
            ДатаРождения,
            Сумма,
            СуммаЗапрошенная,
            СуммаВыдачи,
            Срок,
            IsInstallment,
            IsSmartInstallment,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных,
			УникальныйИдентификаторОбъектаБКИ
			ТипПродукта,
			ТипПродукта_Code,
			ТипПродукта_Наименование,
			ПодТипПродукта,
			ПодТипПродукта_Code,
			ДатаЗакрытияДоговора,
			ГруппаПродуктов_Code,
			ГруппаПродуктов_Наименование,
			Заявка_ВерсияДанных,
			НачальнаяПроцентнаяСтавка,
			КредитныйПродукт_Наименование
		into hub.ДоговорЗайма
		from #t_ДоговорЗайма

		alter table hub.ДоговорЗайма
			alter COLUMN GuidДоговораЗайма uniqueidentifier not null

		alter table hub.ДоговорЗайма
			alter COLUMN КодДоговораЗайма nvarchar(14) not null
			
		ALTER TABLE hub.ДоговорЗайма
			--ADD CONSTRAINT PK_ДоговорЗайма PRIMARY KEY CLUSTERED (GuidДоговораЗайма, КодДоговораЗайма)
			ADD CONSTRAINT PK__ДоговорЗайма PRIMARY KEY CLUSTERED (КодДоговораЗайма)
	end
		/*
		alter table hub.ДоговорЗайма
			add ТипПродукта_Code		nvarchar(255),
			ТипПродукта_Наименование nvarchar(255)

		alter table hub.ДоговорЗайма
			add ПодТипПродукта_Code nvarchar(255)
			*/
	begin tran

		--2026-01-31
		--удалять договора, которые были удалены в источнике
		delete h
		from hub.ДоговорЗайма as h
			left join Stg._1cCMR.Справочник_Договоры AS d
				on d.Код = h.КодДоговораЗайма
		where d.Код is null

		merge hub.ДоговорЗайма t
		using #t_ДоговорЗайма s
			--on t.GuidДоговораЗайма = s.GuidДоговораЗайма
			--AND t.КодДоговораЗайма = s.КодДоговораЗайма
			on t.КодДоговораЗайма = s.КодДоговораЗайма
		when not matched then insert
		(
			СсылкаДоговораЗайма,
            GuidДоговораЗайма,
            КодДоговораЗайма,
            isDelete,
            ДатаДоговораЗайма,
            Фамилия,
            Имя,
            Отчество,
            ДатаРождения,
            Сумма,
            СуммаЗапрошенная,
            СуммаВыдачи,
            Срок,
            IsInstallment,
            IsSmartInstallment,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных,
			УникальныйИдентификаторОбъектаБКИ,
			ТипПродукта,
			ТипПродукта_Code,
			ТипПродукта_Наименование,
			ПодТипПродукта,
			ПодТипПродукта_Code,
			ДатаЗакрытияДоговора,
			ГруппаПродуктов_Code,
			ГруппаПродуктов_Наименование,
			Заявка_ВерсияДанных,
			НачальнаяПроцентнаяСтавка,
			КредитныйПродукт_Наименование
		) values
		(
			s.СсылкаДоговораЗайма,
            s.GuidДоговораЗайма,
            s.КодДоговораЗайма,
            s.isDelete,
            s.ДатаДоговораЗайма,
            s.Фамилия,
            s.Имя,
            s.Отчество,
            s.ДатаРождения,
            s.Сумма,
            s.СуммаЗапрошенная,
            s.СуммаВыдачи,
            s.Срок,
            s.IsInstallment,
            s.IsSmartInstallment,
            s.created_at,
            s.updated_at,
            s.spFillName,
            s.ВерсияДанных,
			s.УникальныйИдентификаторОбъектаБКИ,
			s.ТипПродукта,
			s.ТипПродукта_Code,
			s.ТипПродукта_Наименование,
			s.ПодТипПродукта,
			s.ПодТипПродукта_Code,
			s.ДатаЗакрытияДоговора,
			s.ГруппаПродуктов_Code,
			s.ГруппаПродуктов_Наименование,
			s.Заявка_ВерсияДанных,
			s.НачальнаяПроцентнаяСтавка,
			s.КредитныйПродукт_Наименование
		)
		when matched and (t.ВерсияДанных <> s.ВерсияДанных 
			or isnull(t.ДатаЗакрытияДоговора,'1900-01-01') <> isnull(s.ДатаЗакрытияДоговора, '1900-01-01') 
			or isnull(t.УникальныйИдентификаторОбъектаБКИ, '-')<> isnull(s.УникальныйИдентификаторОбъектаБКИ, '-')
			or isnull(t.Заявка_ВерсияДанных,0x00)<>isnull(s.Заявка_ВерсияДанных,0x00)
			or isnull(t.ТипПродукта, '') <> isnull(s.ТипПродукта, '')
			OR @mode in (0, 2)
			OR @DealNumber IS NOT NULL)
		then update SET
			t.СсылкаДоговораЗайма = s.СсылкаДоговораЗайма,
			t.GuidДоговораЗайма = s.GuidДоговораЗайма,
            t.isDelete = s.isDelete,
            t.ДатаДоговораЗайма = s.ДатаДоговораЗайма,
            t.Фамилия = s.Фамилия,
            t.Имя = s.Имя,
            t.Отчество = s.Отчество,
            t.ДатаРождения = s.ДатаРождения,
            t.Сумма = s.Сумма,
            t.СуммаЗапрошенная = s.СуммаЗапрошенная,
            t.СуммаВыдачи = s.СуммаВыдачи,
            t.Срок = s.Срок,
            t.IsInstallment = s.IsInstallment,
            t.IsSmartInstallment = s.IsSmartInstallment,
            --t. = s.created_at,
            t.updated_at = s.updated_at,
            t.spFillName = s.spFillName,
            t.ВерсияДанных = s.ВерсияДанных,
			t.УникальныйИдентификаторОбъектаБКИ = isnull(s.УникальныйИдентификаторОбъектаБКИ,t.УникальныйИдентификаторОбъектаБКИ),
			t.ТипПродукта = s.ТипПродукта,
			t.ПодТипПродукта = s.ПодТипПродукта,
			t.ПодТипПродукта_Code = s.ПодТипПродукта_Code,
			t.ДатаЗакрытияДоговора = s.ДатаЗакрытияДоговора,
			t.ТипПродукта_Code			= s.ТипПродукта_Code,
			t.ТипПродукта_Наименование = s.ТипПродукта_Наименование,

			t.ГруппаПродуктов_Code = s.ГруппаПродуктов_Code,
			t.ГруппаПродуктов_Наименование = s.ГруппаПродуктов_Наименование,
			t.Заявка_ВерсияДанных = s.Заявка_ВерсияДанных,
			t.НачальнаяПроцентнаяСтавка = s.НачальнаяПроцентнаяСтавка,
			t.КредитныйПродукт_Наименование = s.КредитныйПродукт_Наименование
			;
	commit tran
	print concat_ws(' ','merged  hub.ДоговорЗайма', @@ROWCOUNT)

	if @mode = 2 begin
		delete i
		from dbo.СписокДоговоровЗаймаДляПересчетаDataVault as i
			inner join #t_СписокДоговоровЗаймаДляПересчетаDataVault as t
				on t.КодДоговораЗайма = i.КодДоговораЗайма
	end

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

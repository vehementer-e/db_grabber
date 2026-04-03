CREATE PROC hub.fill_Клиенты
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table hub.Клиенты
BEGIN TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_Клиенты
	if OBJECT_ID ('hub.Клиенты') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.Клиенты), 0x0)
	end

	select distinct
		GuidКлиент = cast([dbo].[getGUIDFrom1C_IDRREF](Партнеры.Ссылка) as uniqueidentifier),
		СсылкаКлиент = Партнеры.Ссылка,
		isDelete = cast(Партнеры.ПометкаУдаления as bit),
		GuidРодитель = cast([dbo].[getGUIDFrom1C_IDRREF](Партнеры.Родитель) as uniqueidentifier),
		isGroup = cast(Партнеры.ЭтоГруппа as bit), 
		Партнеры.Код,
		Партнеры.Наименование,
		Партнеры.НаименованиеПолное,
		ФизЛицо = cast(Партнеры.CRM_ФизЛицо as bit),
		ФИО = Партнеры.Наименование,
		Фамилия = Партнеры.CRM_Фамилия,
		Имя = Партнеры.CRM_Имя,
		Отчество = Партнеры.CRM_Отчество,
		--Партнеры.Пол,
		--Пол = ПолФизическогоЛица.Имя,
		Пол = dm.f_ЗаявкаНаЗаймПодПТС_Пол(cast(Партнеры.CRM_ФизЛицо as bit), ПолФизическогоЛица.Имя, Партнеры.CRM_Отчество),
		ДатаРождения = dateadd(YEAR, -2000, Партнеры.ДатаРождения),
		--ИНН = Партнеры.CRM_ИНН,
		КодПоОКПО = Партнеры.CRM_КодПоОКПО,
		КПП = Партнеры.CRM_КПП,
		ОГРН = Партнеры.CRM_ОГРН,

		--[БизнесРегион] [binary] (16) NULL,
		--[ОсновнойМенеджер] [binary] (16) NULL,
		--[ПрочиеОтношения] [binary] (1) NULL,
		--[Пол] [binary] (16) NULL,
		--[ДатаРождения] [datetime2] (0) NULL,
		--[ЮрФизЛицо] [binary] (16) NULL,
		--[CRM_Важность] [binary] (16) NULL,
		--[CRM_Госорганы] [binary] (1) NULL,
		--[CRM_ДатаРегистрацииКомпании] [datetime2] (0) NULL,
		--[CRM_Имя] [nvarchar] (50) COLLATE Cyrillic_General_CI_AS NULL,
		--[CRM_ИНН] [nvarchar] (12) COLLATE Cyrillic_General_CI_AS NULL,
		--[CRM_КодПоОКПО] [nvarchar] (10) COLLATE Cyrillic_General_CI_AS NULL,
		--[CRM_КПП] [nvarchar] (9) COLLATE Cyrillic_General_CI_AS NULL,
		--[CRM_НапоминатьОДнеРождения] [binary] (1) NULL,
		--[CRM_ОГРН] [nvarchar] (15) COLLATE Cyrillic_General_CI_AS NULL,
		--[CRM_ОсновнаяОтрасль] [binary] (16) NULL,
		--[CRM_ОсновноеКонтактноеЛицо] [binary] (16) NULL,
		--[CRM_ОтписалсяОтEmailРассылок] [binary] (1) NULL,
		--[CRM_Отчество] [nvarchar] (50) COLLATE Cyrillic_General_CI_AS NULL,
		--[CRM_Потенциал] [numeric] (15, 0) NULL,
		--[CRM_ПроцентЗаполненностиКИ] [numeric] (3, 0) NULL,
		--[CRM_ПроцентЗаполненностиПортрет] [numeric] (3, 0) NULL,
		--[CRM_СегментРынка] [binary] (16) NULL,
		--[CRM_СтатусРаботы] [binary] (16) NULL,
		--[CRM_ТипОтношенийПредставление] [nvarchar] (250) COLLATE Cyrillic_General_CI_AS NULL,
		--[CRM_УчаствуетВАнкетировании] [binary] (1) NULL,
		--[CRM_Учредитель] [binary] (1) NULL,
		--[CRM_Фамилия] [nvarchar] (50) COLLATE Cyrillic_General_CI_AS NULL,

		----[CRM_ФизЛицо] [binary] (1) NULL,

		--[CRM_Фотография] [binary] (16) NULL,
		--[CRM_ЧисленностьРабочихМест] [binary] (16) NULL,
		--[CRM_ЧисленностьСотрудников] [binary] (16) NULL,
		--[сфпCoMagicID] [nvarchar] (12) COLLATE Cyrillic_General_CI_AS NULL,
		--[сфпПользовательДляПереключенияЗвонков] [binary] (16) NULL,
		--[БанковскийСчетПоУмолчанию] [binary] (16) NULL,
		--[ДоговорПоУмолчанию] [binary] (16) NULL,
		--[удалитьCRM_ВидПартнера] [binary] (16) NULL,
		--[удалитьCRM_ТипОтношений] [binary] (16) NULL,
		--[НомерАБС] [numeric] (15, 0) NULL,
		--[Гражданство] [binary] (16) NULL,
		--[ПодписаниеДоговораПЭП] [binary] (1) NULL,
		--[РегионФактическогоПроживания] [binary] (16) NULL,
		--[Поставщик] [binary] (1) NULL,
		--[Клиент] [binary] (1) NULL,
		--[Конкурент] [binary] (1) NULL,
		--[Комментарий] [nvarchar] (max) COLLATE Cyrillic_General_CI_AS NULL,
		--[ДатаРегистрации] [datetime2] (0) NULL,
		--[СемейноеПоложение] [binary] (16) NULL,
		--[СобственникТС] [binary] (1) NULL,
		--[СогласиеНаОбработку] [binary] (1) NULL,
		--[ТипЗанятости] [binary] (16) NULL,
		--Партнеры.ОбластьДанныхОсновныеДанные,
		--Партнеры.DWHInsertedDate,
		--Партнеры.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(Партнеры.ВерсияДанных AS binary(8))
	into #t_Клиенты
	--SELECT *
	from Stg._1cCRM.Справочник_Партнеры AS Партнеры
		LEFT JOIN Stg._1cCRM.Перечисление_ПолФизическогоЛица AS ПолФизическогоЛица
			ON ПолФизическогоЛица.Ссылка = Партнеры.Пол
	where Партнеры.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.Клиенты') is null
	begin
		select top(0)
			GuidКлиент,
			СсылкаКлиент,
            isDelete,
            GuidРодитель,
            isGroup,
            Код,
            Наименование,
            НаименованиеПолное,
            ФизЛицо,
            ФИО,
            Фамилия,
            Имя,
            Отчество,
            Пол,
            ДатаРождения,
            --ИНН,
            КодПоОКПО,
            КПП,
            ОГРН,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into hub.Клиенты
		from #t_Клиенты

		alter table hub.Клиенты
			alter column GuidКлиент uniqueidentifier not null

		ALTER TABLE hub.Клиенты
			ADD CONSTRAINT PK_Клиенты PRIMARY KEY CLUSTERED (GuidКлиент)
	end
	
	--begin tran
		merge hub.Клиенты t
		using #t_Клиенты s
			on t.GuidКлиент = s.GuidКлиент
		when not matched then insert
		(
			GuidКлиент,
			СсылкаКлиент,
            isDelete,
            GuidРодитель,
            isGroup,
            Код,
            Наименование,
            НаименованиеПолное,
            ФизЛицо,
            ФИО,
            Фамилия,
            Имя,
            Отчество,
            Пол,
            ДатаРождения,
            --ИНН,
            КодПоОКПО,
            КПП,
            ОГРН,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.GuidКлиент,
			s.СсылкаКлиент,
            s.isDelete,
            s.GuidРодитель,
            s.isGroup,
            s.Код,
            s.Наименование,
            s.НаименованиеПолное,
            s.ФизЛицо,
            s.ФИО,
            s.Фамилия,
            s.Имя,
            s.Отчество,
            s.Пол,
            s.ДатаРождения,
            --s.ИНН,
            s.КодПоОКПО,
            s.КПП,
            s.ОГРН,
            s.created_at,
            s.updated_at,
            s.spFillName,
            s.ВерсияДанных
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
		then update SET
            t.isDelete = s.isDelete,
            t.GuidРодитель = s.GuidРодитель,
            t.isGroup = s.isGroup,
            t.Код = s.Код,
            t.Наименование = s.Наименование,
            t.НаименованиеПолное = s.НаименованиеПолное,
            t.ФизЛицо = s.ФизЛицо,
            t.ФИО = s.ФИО,
            t.Фамилия = s.Фамилия,
            t.Имя = s.Имя,
            t.Отчество = s.Отчество,
            t.Пол = s.Пол,
            t.ДатаРождения = s.ДатаРождения,
            --t.ИНН = s.ИНН,
            t.КодПоОКПО = s.КодПоОКПО,
            t.КПП = s.КПП,
            t.ОГРН = s.ОГРН,
            --s.created_at,
            t.updated_at = s.updated_at,
            t.spFillName = s.spFillName,
            t.ВерсияДанных = s.ВерсияДанных
			;
	--commit tran
	

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

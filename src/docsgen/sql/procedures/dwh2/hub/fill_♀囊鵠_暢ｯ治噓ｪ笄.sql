--exec hub.fill_БКИ_НФ_ТипОбъекта @mode = 0
--exec hub.fill_БКИ_НФ_ТипОбъекта @mode = 1
-- Заполняется в dwh2
create   PROC hub.fill_БКИ_НФ_ТипОбъекта
	@mode int = 1
as
begin
	--truncate table hub.БКИ_НФ_ТипОбъекта
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	--if OBJECT_ID ('hub.БКИ_НФ_ТипОбъекта') is not NULL
	--	AND @mode = 1
	--begin
	--	set @rowVersion = isnull((select max(ВерсияДанных) from hub.БКИ_НФ_ТипОбъекта), 0x0)
	--end

	drop table if exists #t_БКИ_НФ_ТипОбъекта
	CREATE TABLE #t_БКИ_НФ_ТипОбъекта
	(
		GuidБКИ_НФ_ТипОбъекта uniqueidentifier NOT NULL,
		isDelete bit NULL,
		Код nvarchar(30) NULL,
		Наименование nvarchar(500) NULL,
		created_at datetime NOT NULL,
		updated_at datetime NOT NULL,
		spFillName nvarchar(255) NULL
	)

	INSERT #t_БКИ_НФ_ТипОбъекта
	(
		GuidБКИ_НФ_ТипОбъекта,
		isDelete,
		Код,
		Наименование,
		created_at,
		updated_at,
		spFillName
	)
	select
		cast(hashbytes('SHA2_256', 'Заявка') AS uniqueidentifier),
		0,
		'Заявка',
		'Заявка',
		getdate(),
		getdate(),
		'IMPORT'
	union
	select
		cast(hashbytes('SHA2_256', 'ДоговорЗайма') AS uniqueidentifier),
		0,
		'ДоговорЗайма',
		'Договор займа',
		getdate(),
		getdate(),
		'IMPORT'
	union
	select
		cast(hashbytes('SHA2_256', 'Субъект') AS uniqueidentifier),
		0,
		'Субъект',
		'Субъект',
		getdate(),
		getdate(),
		'IMPORT'

	if OBJECT_ID('hub.БКИ_НФ_ТипОбъекта') is null
	begin
		/*
		CREATE TABLE hub.БКИ_НФ_ТипОбъекта
		(
			[GuidБКИ_НФ_ТипОбъекта] [uniqueidentifier] NOT NULL,
			[isDelete] [bit] NULL,
			[Код] [nvarchar](30) NULL,
			[Наименование] [nvarchar](500) NULL,
			[created_at] [datetime] NOT NULL,
			[updated_at] [datetime] NOT NULL,
			[spFillName] [nvarchar](255) NULL,
		 CONSTRAINT [PK_БКИ_НФ_ТипОбъекта] PRIMARY KEY CLUSTERED 
			(
				[GuidБКИ_НФ_ТипОбъекта] ASC
			) ON [PRIMARY]
		) ON [PRIMARY]
		*/

		select top(0)
			GuidБКИ_НФ_ТипОбъекта,
			isDelete,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName
		into hub.БКИ_НФ_ТипОбъекта
		from #t_БКИ_НФ_ТипОбъекта

		alter table hub.БКИ_НФ_ТипОбъекта
			alter column GuidБКИ_НФ_ТипОбъекта uniqueidentifier not null

		ALTER TABLE hub.БКИ_НФ_ТипОбъекта
			ADD CONSTRAINT PK_БКИ_НФ_ТипОбъекта PRIMARY KEY CLUSTERED (GuidБКИ_НФ_ТипОбъекта)
	end
	
	--begin tran
		merge hub.БКИ_НФ_ТипОбъекта t
		using #t_БКИ_НФ_ТипОбъекта s
			on t.GuidБКИ_НФ_ТипОбъекта = s.GuidБКИ_НФ_ТипОбъекта
		when not matched then insert
		(
			GuidБКИ_НФ_ТипОбъекта,
			isDelete,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidБКИ_НФ_ТипОбъекта,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched 
			--and t.ВерсияДанных !=s.ВерсияДанных OR @mode = 0
			and @mode = 0
		then update SET
			--t.ВерсияДанных = s.ВерсияДанных,
			t.isDelete = s.isDelete,
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			--t.created_at = s.created_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
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

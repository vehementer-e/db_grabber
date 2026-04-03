--exec [sat].[fill_Клиент_Email] @mode = 1
CREATE PROC [sat].[fill_Клиент_Email]
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table sat.Клиент_Email
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	,@maxDate datetime2(0) = '0001-01-01'
		

	drop table if exists #t_Клиент_Email

	if OBJECT_ID ('sat.Клиент_Email') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.Клиент_Email), 0x0)
		
		SELECT @maxDate = isnull(dateadd(dd,-2,max(ДатаЗаписи)),  @maxDate)
			,@rowVersion = isnull(max([Collection_RowVersion]), @rowVersion)
			FROM sat.Клиент_Email
	end
	print @maxDate
	print  @rowVersion
	drop table if exists #t_Клиент

	--SELECT DISTINCT 
	--	Клиенты.GuidКлиент,
	--	Клиенты.СсылкаКлиент
	--INTO #t_Клиент
	--FROM hub.Клиенты AS Клиенты
	--	INNER JOIN Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация AS Инф
	--		ON Инф.Ссылка = Клиенты.СсылкаКлиент
	--WHERE 1=1
	--	AND Инф.ДатаЗаписи >= dateadd(YEAR, 2000, @maxDate)
	--	AND Инф.Актуальный = 0x01
	--	AND Инф.Тип = 0x82E6D573EE35D0904BF4D326A84A91D2
	--	AND Stg.dbo.str_ValidateEmail(Инф.АдресЭП) IS NOT NULL
		----test
		----AND Клиенты.GuidКлиент IN ('13C9A42D-1D0C-4157-BBDE-7B1297280C2F', '46F5A8A9-DC71-11E9-B818-00155D03492D)')

	--UNION
	--SELECT DISTINCT 
	--	Клиенты.GuidКлиент,
	--	Клиенты.СсылкаКлиент
	--FROM hub.Клиенты AS Клиенты
	--	INNER JOIN Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация AS Инф
	--		ON Инф.Ссылка = Клиенты.СсылкаКлиент
	--WHERE 1=1
	--	AND Инф.ДатаЗаписи = '2001-01-01'
	--	AND Инф.Актуальный = 0x01
	--	AND Инф.Тип = 0x82E6D573EE35D0904BF4D326A84A91D2
	--	AND Stg.dbo.str_ValidateEmail(Инф.АдресЭП) IS NOT NULL
	/*найдем клиентов у которых нет email dd*/
	select 
		t.GuidКлиент,
		t.СсылкаКлиент,
		t.Email
	INTO #t_Клиент
	from (
		SELECT 
			Клиенты.GuidКлиент,
			Клиенты.СсылкаКлиент,
			email = Stg.dbo.str_ValidateEmail(Инф.АдресЭП)
		FROM hub.Клиенты AS Клиенты
			INNER JOIN Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация AS Инф
				ON Инф.Ссылка = Клиенты.СсылкаКлиент
		WHERE 1=1
			--AND Инф.ДатаЗаписи >= dateadd(YEAR, 2000, @maxDate)
			AND Инф.Актуальный = 0x01
			AND Инф.Тип = 0x82E6D573EE35D0904BF4D326A84A91D2
			AND Stg.dbo.str_ValidateEmail(Инф.АдресЭП) IS NOT NULL
		union
		select 
			t.GuidКлиент,
			t.СсылкаКлиент,
			email = Stg.dbo.str_ValidateEmail(cpd.Email)
		from hub.Клиенты t
		inner join stg._Collection.customers c 
			on GuidКлиент	 = c.CrmCustomerId
		inner join stg._Collection.CustomerPersonalData  cpd   on c.Id = cpd.IdCustomer
		where Stg.dbo.str_ValidateEmail(cpd.Email) IS NOT NULL
	) t
	EXCEPT 
	SELECT 
		Клиенты.GuidКлиент,
		Клиенты.СсылкаКлиент,
		E.Email
	FROM hub.Клиенты AS Клиенты
		INNER JOIN sat.Клиент_Email AS E
			ON E.GuidКлиент = Клиенты.GuidКлиент
	where @mode = 1


	;with cte_crm  as 
	(
		select 
			КонтИнф.GuidКлиент
			,КонтИнф.СсылкаКлиент
			,КонтИнф.Email
			,КонтИнф.ДатаЗаписи
			,nRow = Row_Number() OVER (
				PARTITION BY КонтИнф.СсылкаКлиент
				ORDER BY КонтИнф.ДатаЗаписи DESC, КонтИнф.НомерСтроки DESC
				)
			,ТаблицаИсточник = 'Справочник_Партнеры_КонтактнаяИнформация'
		FROM (
				SELECT 
					Инф2.GuidКлиент,
					Инф2.СсылкаКлиент,
					Инф2.Email,
					ДатаЗаписи = max(Инф2.ДатаЗаписи),
					НомерСтроки = max(Инф2.НомерСтроки)
				FROM (
						SELECT
							Клиент.GuidКлиент,
							Клиент.СсылкаКлиент,
							Email = Инф.АдресЭП,
							ДатаЗаписи = dateadd(YEAR, -2000, cast(Инф.ДатаЗаписи AS datetime2(0))),
							Инф.НомерСтроки
						FROM #t_Клиент AS Клиент
							INNER JOIN Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация AS Инф
								ON Инф.Ссылка = Клиент.СсылкаКлиент
						WHERE 1=1
							AND Инф.Актуальный = 0x01
							AND Инф.Тип = 0x82E6D573EE35D0904BF4D326A84A91D2
							AND Stg.dbo.str_ValidateEmail(Инф.АдресЭП) IS NOT NULL
					) AS Инф2
				WHERE 1=1
			--		AND nullif(Инф2.Email, '') IS NOT NULL
				GROUP BY 
					Инф2.GuidКлиент,
					Инф2.СсылкаКлиент,
					Инф2.Email
			) AS КонтИнф
		where 1=1
	)
	SELECT --TOP 10
		EmailИнф.GuidКлиент,
		EmailИнф.СсылкаКлиент,
		EmailИнф.Email,
		EmailИнф.ДатаЗаписи,
		nRow = nRow,
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,
		[ТаблицаИсточник] = ТаблицаИсточник,
		Collection_RowVersion = cast(null as binary(8))
	INTO #t_Клиент_Email
	FROM cte_crm AS EmailИнф
	WHERE 1=1
		--AND Email.nRow = 1
		--AND Email.nRow > 1

	insert into #t_Клиент_Email
	(
	 	GuidКлиент,
		СсылкаКлиент,
		Email,
		nRow,
		created_at,
		updated_at,
		spFillName,
		[ТаблицаИсточник],
		Collection_RowVersion
	)
		SELECT --TOP 10
		GuidКлиент = Клиент.GuidКлиент,
		СсылкаКлиент = Клиент.СсылкаКлиент,
		Email = cpd.Email,
		nRow = 1,
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,
		[ТаблицаИсточник] = 'stg._Collection.CustomerPersonalData',
		Collection_RowVersion = cpd.RowVersion
	from #t_Клиент AS Клиент
	inner join stg._Collection.customers c 
		on Клиент.GuidКлиент	 = c.CrmCustomerId
	inner join stg._Collection.CustomerPersonalData  cpd   on c.Id = cpd.IdCustomer
	where Stg.dbo.str_ValidateEmail(cpd.Email) IS NOT NULL
--	and cpd.RowVersion>=@rowVersion
	and not exists(select top(1) 1 from #t_Клиент_Email crm
	where crm.Email = cpd.Email
		and crm.GuidКлиент =Клиент.GuidКлиент
	)

	
	; with cte as 
	 (
		select nDublicate = ROW_NUMBER() over (partition by GuidКлиент, email order by ДатаЗаписи), *
		from #t_Клиент_Email e
	 )
	 delete from cte
	 where nDublicate>1

	if OBJECT_ID('sat.Клиент_Email') is null
	begin
		select top(0)
			GuidКлиент,
			СсылкаКлиент,
			Email,
			ДатаЗаписи,
			nRow,
			created_at,
			updated_at,
			spFillName
		into sat.Клиент_Email
		from #t_Клиент_Email

		alter table sat.Клиент_Email
			alter column GuidКлиент uniqueidentifier not null

		alter table sat.Клиент_Email
			alter column nRow int not null

		alter table sat.Клиент_Email
			alter column Email nvarchar(255) not null

		ALTER TABLE sat.Клиент_Email
			ADD CONSTRAINT PK_Клиент_Email PRIMARY KEY CLUSTERED (GuidКлиент, Email)
		/*
		alter table  sat.Клиент_Email
			add [ТаблицаИсточник] nvarchar(255),
				Collection_RowVersion
		*/
	end
	
	BEGIN TRAN
		-- обновить данные по всем EmailИнф выбранных клиентов
		--1. 
		if @mode = 0
		begin
			 truncate table sat.Клиент_Email
		end
		else
		DELETE T 
		FROM sat.Клиент_Email AS T
			INNER JOIN #t_Клиент_Email AS Клиент
				ON T.GuidКлиент = Клиент.GuidКлиент

		--2
		INSERT sat.Клиент_Email
		(
			GuidКлиент,
			СсылкаКлиент,
			Email,
			ДатаЗаписи,
			nRow,
			created_at,
			updated_at,
			spFillName,
			[ТаблицаИсточник],
			Collection_RowVersion
		)
		select 
			S.GuidКлиент,
			S.СсылкаКлиент,
			S.Email,
			S.ДатаЗаписи,
			S.nRow,
			S.created_at,
			S.updated_at,
			S.spFillName,
			s.[ТаблицаИсточник],
			s.Collection_RowVersion
		from #t_Клиент_Email AS S

	commit tran

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

CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_RBP
	@mode int = 1,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_RBP
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_RBP

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_RBP') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_RBP), 0x0)
		SELECT 
			@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(DAY, -1, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_RBP AS S
	end

	-- заявки, у которых мог поменяться RBP
	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(НомерЗаявки nvarchar(20))

	INSERT #t_Заявки(НомерЗаявки)
	SELECT Заявка.НомерЗаявки
	FROM hub.Заявка AS Заявка
	WHERE Заявка.updated_at >= @updated_at
		AND Заявка.НомерЗаявки IS NOT NULL

	INSERT #t_Заявки(НомерЗаявки)
	SELECT cast(risk_groups.number AS nvarchar(20))
	FROM Stg._loginom.Dm_risk_groups AS risk_groups
	WHERE risk_groups.created >= @updated_at

	INSERT #t_Заявки(НомерЗаявки)
	SELECT DISTINCT Заявка.НомерЗаявки
	FROM sat.ЗаявкаНаЗаймПодПТС_ВидЗайма AS ВидЗайма
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.GuidЗаявки = ВидЗайма.GuidЗаявки
	WHERE ВидЗайма.updated_at >= @updated_at
		AND Заявка.НомерЗаявки IS NOT NULL

	DROP TABLE IF EXISTS #t_Заявки_2
	CREATE TABLE #t_Заявки_2(НомерЗаявки nvarchar(20))
	INSERT #t_Заявки_2(НомерЗаявки)
	SELECT DISTINCT T.НомерЗаявки FROM #t_Заявки AS T

	CREATE INDEX IX1 ON #t_Заявки_2(НомерЗаявки)


	DROP TABLE IF EXISTS #t_RBP
	CREATE TABLE #t_RBP(
		--СсылкаЗаявки binary(16),
		НомерЗаявки nvarchar(20),
		--GuidЗаявки nvarchar(36),
		ДатаЗаявки datetime,
		isInstallment bit,
		ВариантыПредложенияСтавки_Код nvarchar(30),
		fin_gr int,
		ВидЗайма nvarchar(50)
	)

	INSERT #t_RBP
	(
	    НомерЗаявки,
		ДатаЗаявки,
	    isInstallment,
	    ВариантыПредложенияСтавки_Код,
	    fin_gr,
	    ВидЗайма
	)
	SELECT 
		Заявка.НомерЗаявки,
		Заявка.ДатаЗаявки,
		Заявка.isInstallment,
		ВариантыПредложенияСтавки.Код,
		fin_gr = cast(risk_groups.fin_gr AS int),
		ВидЗайма.ВидЗайма
	FROM #t_Заявки_2 AS T
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.НомерЗаявки = T.НомерЗаявки
		LEFT JOIN link.v_ВариантыПредложенияСтавки_Заявка AS ВариантыПредложенияСтавки
			ON ВариантыПредложенияСтавки.GuidЗаявки = Заявка.GuidЗаявки
		LEFT JOIN Stg._loginom.Dm_risk_groups AS risk_groups
			ON  Заявка.НомерЗаявки = cast(risk_groups.number AS nvarchar(20))
		LEFT JOIN sat.ЗаявкаНаЗаймПодПТС_ВидЗайма AS ВидЗайма
			ON ВидЗайма.GuidЗаявки = Заявка.GuidЗаявки

	CREATE INDEX IX1
	ON #t_RBP(НомерЗаявки)
	INCLUDE ([ДатаЗаявки],[isInstallment],[ВариантыПредложенияСтавки_Код],[fin_gr],[ВидЗайма])


	select distinct
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.GuidЗаявки,
		RBP = dm.f_ЗаявкаНаЗаймПодПТС_RBP(
			RBP.ДатаЗаявки,
			RBP.isInstallment,
			RBP.ВариантыПредложенияСтавки_Код,
			RBP.fin_gr,
			RBP.ВидЗайма
		),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных_CRM AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_RBP
	--SELECT *
	FROM #t_RBP AS RBP
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.НомерЗаявки = RBP.НомерЗаявки

	if @isDebug = 1 begin
		drop table if exists ##t_ЗаявкаНаЗаймПодПТС_RBP
		select * into ##t_ЗаявкаНаЗаймПодПТС_RBP from #t_ЗаявкаНаЗаймПодПТС_RBP

		drop table if exists ##t_RBP
		select * into ##t_RBP from #t_RBP
	end

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_RBP') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
            RBP,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_RBP
		from #t_ЗаявкаНаЗаймПодПТС_RBP

		alter table sat.ЗаявкаНаЗаймПодПТС_RBP
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_RBP
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_RBP PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_RBP t
		using #t_ЗаявкаНаЗаймПодПТС_RBP s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
            RBP,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
            s.RBP,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched 
			AND (isnull(t.RBP, '') != isnull(s.RBP, '')
				OR t.ВерсияДанных != s.ВерсияДанных
			)
		then update SET
			t.RBP = s.RBP,
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

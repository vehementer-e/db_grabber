CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_MFO
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_MFO
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_MFO

	if object_id('sat.ЗаявкаНаЗаймПодПТС_MFO') is not null
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_MFO), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(HOUR, -2, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_MFO AS S
	end

	-- заявки, у которых могли поменяться атрибуты MFO
	--DROP TABLE IF EXISTS #t_Заявки
	--CREATE TABLE #t_Заявки(
	--	НомерЗаявки nvarchar(20) 
	--)

	DROP TABLE IF EXISTS #t_mfoЗаявки
	CREATE TABLE #t_mfoЗаявки(
		Номер nvarchar(20) NOT NULL,
		Дата datetime,
		ПризнакОформленияНовойЗаявки nvarchar(20)
	)

	IF NOT EXISTS(
		SELECT TOP(1) 1 
		FROM Stg._1cmfo.Отчет_ВсеЗаявкиДляАналитика AS mfoЗаявки
		WHERE mfoЗаявки.DWHInsertedDate > @updated_at
	) 
	BEGIN
		RETURN 0
	END

	INSERT #t_mfoЗаявки
	(
	    Номер,
	    Дата,
	    ПризнакОформленияНовойЗаявки
	)
	SELECT DISTINCT
		mfoЗаявки.Номер,
		mfoЗаявки.Дата,
		mfoЗаявки.ПризнакОформленияНовойЗаявки
	--SELECT count(*) --167731
	FROM Stg._1cmfo.Отчет_ВсеЗаявкиДляАналитика AS mfoЗаявки
	WHERE 1=1
		AND nullif(trim(mfoЗаявки.Номер), '') IS NOT NULL
		AND nullif(trim(mfoЗаявки.ПризнакОформленияНовойЗаявки), '') IS NOT NULL

	CREATE INDEX ix1 ON #t_mfoЗаявки(Номер)
	CREATE INDEX ix2 ON #t_mfoЗаявки(ПризнакОформленияНовойЗаявки) INCLUDE(Дата, Номер)


	DROP TABLE IF EXISTS #t_mfoПерезаведены
	CREATE TABLE #t_mfoПерезаведены(
		НомерЗаявки nvarchar(20) NOT NULL,
        ПерезаведенаПослеЗаявки nvarchar(20),
        ПерезаведенаНаЗаявку nvarchar(20)
	)
	INSERT #t_mfoПерезаведены
	(
	    НомерЗаявки,
	    ПерезаведенаПослеЗаявки,
	    ПерезаведенаНаЗаявку
	)
	SELECT 
		НомерЗаявки = isnull(A.НомерЗаявки, B.НомерЗаявки),
        A.ПерезаведенаПослеЗаявки,
        B.ПерезаведенаНаЗаявку
	FROM
		(
			SELECT DISTINCT
				НомерЗаявки = mfoЗаявки.ПризнакОформленияНовойЗаявки,
				--найти самую первую заявку, у которой признак перехода на нашу заявку
				ПерезаведенаПослеЗаявки = first_value(mfoЗаявки.Номер)
					OVER(PARTITION BY mfoЗаявки.ПризнакОформленияНовойЗаявки ORDER BY mfoЗаявки.Дата, mfoЗаявки.Номер)
			FROM #t_mfoЗаявки AS mfoЗаявки
		) AS A
		FULL OUTER JOIN
		(
			SELECT DISTINCT
				НомерЗаявки = mfoЗаявки.Номер,
				--ПерезаведенаНаЗаявку = Признак оформления новой заявки
				ПерезаведенаНаЗаявку = mfoЗаявки.ПризнакОформленияНовойЗаявки
			FROM #t_mfoЗаявки AS mfoЗаявки
		) AS B
		ON B.НомерЗаявки = A.НомерЗаявки

	CREATE INDEX ix1 ON #t_mfoПерезаведены(НомерЗаявки)


	select distinct
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.GuidЗаявки,

		Перезаведены.ПерезаведенаПослеЗаявки,
		Перезаведены.ПерезаведенаНаЗаявку,

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_MFO
	--SELECT *
	FROM #t_mfoПерезаведены AS Перезаведены
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.НомерЗаявки = Перезаведены.НомерЗаявки
		--INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
		--	ON ЗаявкаНаЗаймПодПТС.Номер = Заявки.НомерЗаявки


	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_MFO') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			ПерезаведенаПослеЗаявки,
			ПерезаведенаНаЗаявку,
            created_at,
            updated_at,
            spFillName
		into sat.ЗаявкаНаЗаймПодПТС_MFO
		from #t_ЗаявкаНаЗаймПодПТС_MFO

		alter table sat.ЗаявкаНаЗаймПодПТС_MFO
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_MFO
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_MFO PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_MFO t
		using #t_ЗаявкаНаЗаймПодПТС_MFO s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			ПерезаведенаПослеЗаявки,
			ПерезаведенаНаЗаявку,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.ПерезаведенаПослеЗаявки,
			s.ПерезаведенаНаЗаявку,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (
				   isnull(t.ПерезаведенаПослеЗаявки, '') != isnull(s.ПерезаведенаПослеЗаявки, '')
				OR isnull(t.ПерезаведенаНаЗаявку, '') != isnull(s.ПерезаведенаНаЗаявку, '')
				--OR t.ВерсияДанных != s.ВерсияДанных
			)
		then update SET
            t.ПерезаведенаПослеЗаявки = s.ПерезаведенаПослеЗаявки,
            t.ПерезаведенаНаЗаявку = s.ПерезаведенаНаЗаявку,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
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

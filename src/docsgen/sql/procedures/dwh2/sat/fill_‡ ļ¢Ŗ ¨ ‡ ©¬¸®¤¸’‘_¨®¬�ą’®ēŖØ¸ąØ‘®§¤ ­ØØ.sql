CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании
	if object_id('sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании') is not null
	begin
		SELECT 
			@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = dateadd(DAY, -1, isnull(max(S.updated_at), '1900-01-01'))
		FROM sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(СсылкаЗаявки binary(16))

	--1 все заявки, по которым было изменение
	INSERT #t_Заявки(СсылкаЗаявки)
	SELECT DISTINCT A.Заявка
	FROM Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS A
	WHERE dateadd(YEAR, -2000, A.ДатаИзменения) > @updated_at


	SELECT DISTINCT
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.GuidЗаявки,
		C.НомерТочкиПриСоздании,
		C.ЮрлицоПриСоздании,
		C.ДвижениеПоТочкам,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных_CRM AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании
	--SELECT *
	FROM (
		SELECT 
			B.СсылкаЗаявки,
			B.НомерТочкиПриСоздании,
			B.ЮрлицоПриСоздании,
			ДвижениеПоТочкам = string_agg(B.НомерТочки, '/')
		FROM (
			SELECT 
				A.СсылкаЗаявки,
				A.НомерТочки,
				НомерТочкиПриСоздании = first_value(A.НомерТочки) OVER(PARTITION BY A.СсылкаЗаявки ORDER BY A.rn),
				ЮрлицоПриСоздании = first_value(A.Юрлицо) OVER(PARTITION BY A.СсылкаЗаявки ORDER BY A.rn)
			FROM (
				SELECT 
					СсылкаЗаявки = T.СсылкаЗаявки,
					НомерТочки = Офисы.Код,
					Юрлицо = Партнеры.Наименование,
					rn = row_number() OVER(PARTITION BY Изменения.Заявка ORDER BY Изменения.ДатаИзменения) 
				FROM #t_Заявки AS T
					INNER JOIN Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS Изменения
						ON Изменения.Заявка = T.СсылкаЗаявки
					INNER JOIN Stg._1cCRM.Справочник_Офисы AS Офисы
						ON Изменения.Офис = Офисы.Ссылка
					INNER JOIN Stg._1cCRM.Справочник_Партнеры AS Партнеры
						ON Офисы.Партнер = Партнеры.Ссылка
				--WHERE 1=1
				--test
				--	AND T.СсылкаЗаявки = 0x832900006B7518254464CEF4188DEA13
				) AS A
			) AS B
		GROUP BY B.СсылкаЗаявки, B.НомерТочкиПриСоздании, B.ЮрлицоПриСоздании 
		) AS C
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.СсылкаЗаявки = C.СсылкаЗаявки

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			НомерТочкиПриСоздании,
			ЮрлицоПриСоздании,
			ДвижениеПоТочкам,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании
		from #t_ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании

		alter table sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании t
		using #t_ЗаявкаНаЗаймПодПТС_НомерТочкиПриСоздании s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			НомерТочкиПриСоздании,
			ЮрлицоПриСоздании,
			ДвижениеПоТочкам,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.НомерТочкиПриСоздании,
			s.ЮрлицоПриСоздании,
			s.ДвижениеПоТочкам,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched 
			AND (isnull(t.НомерТочкиПриСоздании, '') != isnull(s.НомерТочкиПриСоздании, '')
				OR isnull(t.ЮрлицоПриСоздании, '') != isnull(s.ЮрлицоПриСоздании, '')
				OR isnull(t.ДвижениеПоТочкам, '') != isnull(s.ДвижениеПоТочкам, '')
				OR t.ВерсияДанных != s.ВерсияДанных
			)
		then update SET
			t.НомерТочкиПриСоздании = s.НомерТочкиПриСоздании,
			t.ЮрлицоПриСоздании = s.ЮрлицоПриСоздании,
			t.ДвижениеПоТочкам = s.ДвижениеПоТочкам,
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

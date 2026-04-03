CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ЗабираемПТС
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	DECLARE @maxDate datetime2(0) = '0001-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ЗабираемПТС
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС') is not null
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС), 0x0)
		SELECT @maxDate = isnull((SELECT max(ДатаЗаписи) FROM sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС), '0001-01-01')
	end

	IF @maxDate <> '0001-01-01'
	BEGIN
		SELECT @maxDate = dateadd(DAY, -3, @maxDate)
	END

	select distinct
		M.СсылкаЗаявки,
		M.GuidЗаявки,
		ДатаЗаписи = dateadd(YEAR, -2000, M.Период),
		ЗабираемПТС = cast(
			CASE R.ОставлятьПТСУКлиента
				WHEN 0x01 THEN 0
				ELSE 1
			END AS int),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ЗаявкаНаЗаймПодПТС_ЗабираемПТС
	FROM (
			SELECT 
				hub_Заявка.СсылкаЗаявки,
				hub_Заявка.GuidЗаявки,
				Период = max(ОставлятьПТС.Период)
			FROM hub.Заявка AS hub_Заявка
				INNER JOIN Stg._1cCRM.РегистрСведений_ОставлятьПТСУКлиентаПоЗаявке AS ОставлятьПТС
					ON ОставлятьПТС.Заявка = hub_Заявка.СсылкаЗаявки
			where 1=1
				AND ОставлятьПТС.Период >= dateadd(YEAR, 2000, @maxDate)
			GROUP BY
				hub_Заявка.СсылкаЗаявки,
				hub_Заявка.GuidЗаявки
		) M
		INNER JOIN Stg._1cCRM.РегистрСведений_ОставлятьПТСУКлиентаПоЗаявке AS R
			ON R.Заявка = M.СсылкаЗаявки
			AND R.Период = M.Период

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС') is null
	begin
		select top(0)
			СсылкаЗаявки,
			GuidЗаявки,
			ДатаЗаписи,
			ЗабираемПТС,
			created_at,
			updated_at,
			spFillName
		into sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС
		from #t_ЗаявкаНаЗаймПодПТС_ЗабираемПТС

		alter table sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ЗабираемПТС PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ЗабираемПТС t
		using #t_ЗаявкаНаЗаймПодПТС_ЗабираемПТС s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			ДатаЗаписи,
			ЗабираемПТС,
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.ДатаЗаписи,
			s.ЗабираемПТС,
            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched and (t.ДатаЗаписи <> s.ДатаЗаписи OR t.ЗабираемПТС <> s.ЗабираемПТС)
		then update SET
			t.ДатаЗаписи = s.ДатаЗаписи,
			t.ЗабираемПТС = s.ЗабираемПТС,
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

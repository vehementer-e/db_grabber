
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ЛидCRM
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ЛидCRM
begin TRY
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ЛидCRM
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ЛидCRM') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ЛидCRM), 0x0)
	end

	select distinct
		СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка,
		GuidЗаявки = cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) as uniqueidentifier),
		СсылкаНаЛидCRM = ЗаявкаНаЗаймПодПТС.Лид,
		GuidЛидCRM = cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Лид) as uniqueidentifier),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ЛидCRM
	--SELECT *
	FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
	where ЗаявкаНаЗаймПодПТС.ВерсияДанных >= @rowVersion

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_ЛидCRM
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_ЛидCRM FROM #t_ЗаявкаНаЗаймПодПТС_ЛидCRM
		--RETURN 0
	END

	;WITH dup AS (
		SELECT
			rn = row_number() OVER(PARTITION BY GuidЗаявки ORDER BY ВерсияДанных DESC),
			T.* 
		FROM #t_ЗаявкаНаЗаймПодПТС_ЛидCRM AS T
		)
	--SELECT * FROM dup WHERE dup.rn > 1
	DELETE dup
	WHERE dup.rn > 1

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ЛидCRM') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			СсылкаНаЛидCRM,
			GuidЛидCRM,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ЛидCRM
		from #t_ЗаявкаНаЗаймПодПТС_ЛидCRM

		alter table sat.ЗаявкаНаЗаймПодПТС_ЛидCRM
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ЛидCRM
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ЛидCRM PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ЛидCRM t
		using #t_ЗаявкаНаЗаймПодПТС_ЛидCRM s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			СсылкаНаЛидCRM,
			GuidЛидCRM,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.СсылкаНаЛидCRM,
			s.GuidЛидCRM,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных != s.ВерсияДанных
		then update SET
			t.СсылкаНаЛидCRM = s.СсылкаНаЛидCRM,
			t.GuidЛидCRM = s.GuidЛидCRM,
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


CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок), 0x0)
	end

	select distinct
		СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка,
		GuidЗаявки = cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) as uniqueidentifier),
		ПризнакИспытательныйСрок = cast(ЗаявкаНаЗаймПодПТС.ИспытательныйСрок AS bit),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок
	--SELECT *
	FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
	where ЗаявкаНаЗаймПодПТС.ВерсияДанных >= @rowVersion

	;WITH dup AS (
		SELECT
			rn = row_number() OVER(PARTITION BY GuidЗаявки ORDER BY ВерсияДанных DESC),
			T.* 
		FROM #t_ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок AS T
		)
	--SELECT * FROM dup WHERE dup.rn > 1
	DELETE dup
	WHERE dup.rn > 1

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
            ПризнакИспытательныйСрок,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок
		from #t_ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок

		alter table sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок t
		using #t_ЗаявкаНаЗаймПодПТС_ПризнакИспытательныйСрок s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
            ПризнакИспытательныйСрок,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
            s.ПризнакИспытательныйСрок,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных != s.ВерсияДанных
		then update SET
			t.ПризнакИспытательныйСрок = s.ПризнакИспытательныйСрок,
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

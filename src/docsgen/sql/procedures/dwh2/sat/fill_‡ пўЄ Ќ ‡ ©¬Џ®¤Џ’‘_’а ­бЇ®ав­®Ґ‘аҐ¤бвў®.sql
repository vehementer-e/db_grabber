CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ТранспортноеСредство
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ТранспортноеСредство
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство), 0x0)
	end

	select distinct
		hub_Заявка.СсылкаЗаявки,
		hub_Заявка.GuidЗаявки,
		СсылкаТранспортноеСредство = ТранспортныеСредства.Ссылка,
		GuidТранспортноеСредство = cast([dbo].[getGUIDFrom1C_IDRREF](ТранспортныеСредства.Ссылка) as uniqueidentifier),
		VIN = cast(ТранспортныеСредства.ИдентификационныйНомер AS nvarchar(30)),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(ТранспортныеСредства.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ТранспортноеСредство
	FROM hub.Заявка AS hub_Заявка
		INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.Ссылка = hub_Заявка.СсылкаЗаявки
		INNER JOIN Stg._1cCRM.Справочник_ТранспортныеСредства AS ТранспортныеСредства
			ON ТранспортныеСредства.Ссылка = ЗаявкаНаЗаймПодПТС.ТранспортноеСредство
	where ТранспортныеСредства.ВерсияДанных >= @rowVersion

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство') is null
	begin
		select top(0)
			СсылкаЗаявки,
			GuidЗаявки,
			СсылкаТранспортноеСредство,
			GuidТранспортноеСредство,
			VIN,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство
		from #t_ЗаявкаНаЗаймПодПТС_ТранспортноеСредство

		alter table sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ТранспортноеСредство PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ТранспортноеСредство t
		using #t_ЗаявкаНаЗаймПодПТС_ТранспортноеСредство s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			СсылкаТранспортноеСредство,
			GuidТранспортноеСредство,
			VIN,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.СсылкаТранспортноеСредство,
			s.GuidТранспортноеСредство,
			s.VIN,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных != s.ВерсияДанных
		then update SET
			t.СсылкаТранспортноеСредство = s.СсылкаТранспортноеСредство,
			t.GuidТранспортноеСредство = s.GuidТранспортноеСредство,
			t.VIN = s.VIN,
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

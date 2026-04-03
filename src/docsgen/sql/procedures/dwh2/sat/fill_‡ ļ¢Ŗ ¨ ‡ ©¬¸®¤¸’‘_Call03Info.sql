create   PROC sat.fill_ЗаявкаНаЗаймПодПТС_Call03Info
	@mode int = 1
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_Call03Info
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	--declare @updated_at datetime = '1900-01-01'
	declare @Id int = 0

	SELECT @mode = isnull(@mode, 1)

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_Call03Info

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_Call03Info') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_Call03Info), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			--@updated_at = isnull(dateadd(HOUR, -72, max(S.lk_updated_at)), '1900-01-01')
			@Id = isnull(max(S.Id), 0)
		FROM sat.ЗаявкаНаЗаймПодПТС_Call03Info AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(GuidЗаявки nvarchar(100)) -- uniqueidentifier)

	--1
	INSERT #t_Заявки(GuidЗаявки)
	SELECT distinct L.ClientRequestId
	FROM Stg._fedor.core_Call03Info AS L
	WHERE 1=1
		AND try_cast(nullif(L.ClientRequestId,'00000000-0000-0000-0000-000000000000') AS uniqueidentifier) IS NOT NULL
		and L.Id >= @Id

	CREATE INDEX IX1
	ON #t_Заявки(GuidЗаявки)

	select distinct
		СсылкаЗаявки = C.СсылкаЗаявки,
		GuidЗаявки = C.GuidЗаявки,

		C.Id,
		C.ReasonId,
		C.Desicion,
		C.NeedBki,
		C.IsDeleted,

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(LK_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_Call03Info
	FROM (
		SELECT 
			СсылкаЗаявки = Заявка.СсылкаЗаявки,
			GuidЗаявки = L.ClientRequestId,

			L.Id,
			L.ReasonId,
			Desicion = L.Desicion COLLATE Cyrillic_General_CI_AS, --SQL_Latin1_General_CP1_CI_AS
			L.NeedBki,
			L.IsDeleted,

			rn = row_number() OVER(
				PARTITION BY L.ClientRequestId
				ORDER BY Заявка.НомерЗаявки DESC, getdate()
			)
		FROM #t_Заявки AS T
			INNER JOIN Stg._fedor.core_Call03Info AS L
				ON L.ClientRequestId = T.GuidЗаявки
			INNER JOIN hub.Заявка AS Заявка
				ON Заявка.GuidЗаявки = T.GuidЗаявки
		) AS C
	WHERE C.rn = 1
	

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_Call03Info') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,

			Id,
			ReasonId,
			Desicion,
			NeedBki,
			IsDeleted,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_Call03Info
		from #t_ЗаявкаНаЗаймПодПТС_Call03Info

		alter table sat.ЗаявкаНаЗаймПодПТС_Call03Info
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_Call03Info
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_Call03Info PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_Call03Info t
		using #t_ЗаявкаНаЗаймПодПТС_Call03Info s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,

			Id,
			ReasonId,
			Desicion,
			NeedBki,
			IsDeleted,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,

			s.Id,
			s.ReasonId,
			s.Desicion,
			s.NeedBki,
			s.IsDeleted,

            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			--AND t.** != s.** -- ?
		then update SET
			t.Id = s.Id,
			t.ReasonId = s.ReasonId,
			t.Desicion = s.Desicion,
			t.NeedBki = s.NeedBki,
			t.IsDeleted = s.IsDeleted,

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

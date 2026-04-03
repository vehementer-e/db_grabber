--exec sat.fill_ДоговорЗайма_Collection_Alerts
create   PROC sat.fill_ДоговорЗайма_Collection_Alerts
	@mode int = 1,
	@Id int = null,
	@IdDeal int = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.ДоговорЗайма_Collection_Alerts
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ДоговорЗайма_Collection_Alerts

	if OBJECT_ID ('sat.ДоговорЗайма_Collection_Alerts') is not null
		and @mode = 1
		and @Id is null
		and @IdDeal is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		set @rowVersion = isnull((select max(s.RowVersion) from sat.ДоговорЗайма_Collection_Alerts as s), 0x0)
	end

	select 
		t.СсылкаДоговораЗайма,
		t.GuidДоговораЗайма,
		t.КодДоговораЗайма,

		t.Id,
		t.AlertName,
		t.IdDeal,
		t.UploadDate,

		t.RowVersion,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ДоговорЗайма_Collection_Alerts
	from (
		select distinct
			h.СсылкаДоговораЗайма,
			h.GuidДоговораЗайма,
			h.КодДоговораЗайма,

			a.Id,
			a.AlertName,
			a.IdDeal,
			a.UploadDate,

			a.RowVersion,
			rn = row_number() over(
				partition by h.КодДоговораЗайма, a.UploadDate
				order by a.RowVersion desc, getdate()
			)
		FROM Stg._Collection.Alerts AS a
			inner join Stg._Collection.Deals as d
				on d.Id = a.IdDeal
			inner join hub.ДоговорЗайма as h
				on h.КодДоговораЗайма = d.Number
		where 1=1
			--and try_cast(C.CmrId AS uniqueidentifier) is not null
			and a.UploadDate is not NULL
			and a.RowVersion >= @rowVersion --or (a.rowVersion is null and @mode = 0)
			and (a.Id = @Id or @Id is null)
			and (a.IdDeal = @IdDeal or @IdDeal is null)
			and (h.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
			and (h.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)
		) as t
		where t.rn = 1


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_Collection_Alerts
		SELECT * INTO ##t_ДоговорЗайма_Collection_Alerts FROM #t_ДоговорЗайма_Collection_Alerts
		--RETURN 0
	END


	if OBJECT_ID('sat.ДоговорЗайма_Collection_Alerts') is null
	begin
		select top(0)
			СсылкаДоговораЗайма,
			GuidДоговораЗайма,
			КодДоговораЗайма,

			Id,
			AlertName,
			IdDeal,
			UploadDate,

			RowVersion,

            created_at,
            updated_at,
            spFillName
		into sat.ДоговорЗайма_Collection_Alerts
		from #t_ДоговорЗайма_Collection_Alerts

		alter table sat.ДоговорЗайма_Collection_Alerts
			alter column КодДоговораЗайма nvarchar(14) not null

		alter table sat.ДоговорЗайма_Collection_Alerts
			alter column UploadDate datetime2(7) not null

		ALTER TABLE sat.ДоговорЗайма_Collection_Alerts
			ADD CONSTRAINT PK_ДоговорЗайма_Collection_Alerts 
			PRIMARY KEY CLUSTERED (КодДоговораЗайма, UploadDate)
	end

	--begin tran
	merge sat.ДоговорЗайма_Collection_Alerts t
	using #t_ДоговорЗайма_Collection_Alerts s
		on t.КодДоговораЗайма = s.КодДоговораЗайма
		and t.UploadDate = s.UploadDate
	when not matched then insert
	(
		СсылкаДоговораЗайма,
		GuidДоговораЗайма,
		КодДоговораЗайма,

		Id,
		AlertName,
		IdDeal,
		UploadDate,

		RowVersion,

        created_at,
        updated_at,
        spFillName
	) values
	(
		s.СсылкаДоговораЗайма,
		s.GuidДоговораЗайма,
		s.КодДоговораЗайма,

		s.Id,
		s.AlertName,
		s.IdDeal,
		s.UploadDate,

		s.RowVersion,

        s.created_at,
        s.updated_at,
        s.spFillName
	)
	when matched and (
		t.RowVersion != s.RowVersion
		or @mode = 0
		)
	then update SET
		t.СсылкаДоговораЗайма = s.СсылкаДоговораЗайма,
		t.GuidДоговораЗайма = s.GuidДоговораЗайма,
		--s.КодДоговораЗайма,

		t.Id = s.Id,
		t.AlertName = s.AlertName,
		t.IdDeal = s.IdDeal,
		t.UploadDate = s.UploadDate,

		t.RowVersion = s.RowVersion,

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

CREATE PROC [hub].[fill_CRM_ПричиныОтказов]
	@mode int = 1
as
begin
	--truncate table hub.CRM_ПричиныОтказов
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	select @mode = isnull(@mode, 1)

	drop table if exists #t_CRM_ПричиныОтказов

	if OBJECT_ID ('hub.CRM_ПричиныОтказов') is not null
		and @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.CRM_ПричиныОтказов), 0x0)
	end

	select distinct 
		GuidПричинаОтказа				= cast([dbo].[getGUIDFrom1C_IDRREF](CRM_ПричиныОтказов.Ссылка) as uniqueidentifier),
		isDelete = cast(CRM_ПричиныОтказов.ПометкаУдаления as bit),
		--CRM_ПричиныОтказов.ИмяПредопределенныхДанных,
        CRM_ПричиныОтказов.Код,
        CRM_ПричиныОтказов.Наименование,
        CRM_ПричиныОтказов.Кодификатор,
        CRM_ПричиныОтказов.НаименованиеПолное,
		--CRM_ПричиныОтказов.ОбластьДанныхОсновныеДанные,
		--CRM_ПричиныОтказов.DWHInsertedDate,
		--CRM_ПричиныОтказов.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		ВерсияДанных						= CRM_ПричиныОтказов.ВерсияДанных,
		loginom_Classification_level_1 = loginom_reason.[Classification level 1],
		loginom_row_ver = loginom_reason.row_ver
	into #t_CRM_ПричиныОтказов
	from Stg._1cCRM.Справочник_CRM_ПричиныОтказов AS CRM_ПричиныОтказов
		left join (
			select 
				r.reasonCode,
				r.[Classification level 1],
				r.row_ver,
				rn = row_number() over (
					partition by r.reasonCode
					order by r.row_ver desc
				)
			from Stg._loginom.Origination_dict_reason_codes as r
			where r.reasonCode is not null
				and r.[Classification level 1] is not null
		) as loginom_reason
		on loginom_reason.reasonCode = CRM_ПричиныОтказов.Кодификатор
		and loginom_reason.rn = 1
	where CRM_ПричиныОтказов.ВерсияДанных >= @rowVersion 



	if OBJECT_ID('hub.CRM_ПричиныОтказов') is null
	begin
	
		select top(0)
			GuidПричинаОтказа,
			isDelete,
			Код,
			Наименование,
			Кодификатор,
			НаименованиеПолное,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных,
			loginom_Classification_level_1,
		
			loginom_row_ver
		into hub.CRM_ПричиныОтказов
		from #t_CRM_ПричиныОтказов

		alter table hub.CRM_ПричиныОтказов
			alter column GuidПричинаОтказа uniqueidentifier not null

		ALTER TABLE hub.CRM_ПричиныОтказов
			ADD CONSTRAINT PK_CRM_ПричиныОтказов PRIMARY KEY CLUSTERED (GuidПричинаОтказа)
	end
	
	--begin tran
		
		
		merge hub.CRM_ПричиныОтказов t
		using #t_CRM_ПричиныОтказов s
			on t.GuidПричинаОтказа = s.GuidПричинаОтказа
		when not matched then insert
		(
			GuidПричинаОтказа,
			isDelete,
			Код,
			Наименование,
			Кодификатор,
			НаименованиеПолное,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных,
			loginom_Classification_level_1,
			loginom_row_ver
		) values
		(
			s.GuidПричинаОтказа,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.Кодификатор,
			s.НаименованиеПолное,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных,
			s.loginom_Classification_level_1,
			s.loginom_row_ver
		)
		when matched 
			and (
				t.ВерсияДанных <> s.ВерсияДанных
				or t.loginom_row_ver <> s.loginom_row_ver
				or @mode = 0
			)
		then update SET
			t.isDelete = s.isDelete,
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.Кодификатор = s.Кодификатор,
			t.НаименованиеПолное = s.НаименованиеПолное,
			t.updated_at = s.updated_at,
			t.ВерсияДанных = s.ВерсияДанных,
			t.loginom_Classification_level_1 = s.loginom_Classification_level_1,
			t.loginom_row_ver = s.loginom_row_ver
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

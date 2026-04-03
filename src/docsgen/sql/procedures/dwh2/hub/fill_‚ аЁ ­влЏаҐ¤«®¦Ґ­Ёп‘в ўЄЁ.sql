CREATE PROC hub.fill_ВариантыПредложенияСтавки
as
begin
	--truncate table hub.ВариантыПредложенияСтавки
begin try
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_ВариантыПредложенияСтавки
	if OBJECT_ID ('hub.ВариантыПредложенияСтавки') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.ВариантыПредложенияСтавки), 0x0)
	end

	select distinct 
		GuidВариантПредложенияСтавки				= cast([dbo].[getGUIDFrom1C_IDRREF](ВариантыПредложенияСтавки.Ссылка) as uniqueidentifier),
		isDelete = cast(ВариантыПредложенияСтавки.ПометкаУдаления as bit),
		--ВариантыПредложенияСтавки.ИмяПредопределенныхДанных,
		ВариантыПредложенияСтавки.Код,
		ВариантыПредложенияСтавки.Наименование,
		НеДоступенДляИзменения = cast(ВариантыПредложенияСтавки.НеДоступенДляИзменения as bit),
		--ВариантыПредложенияСтавки.ОбластьДанныхОсновныеДанные,
		--ВариантыПредложенияСтавки.DWHInsertedDate,
		--ВариантыПредложенияСтавки.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		ВерсияДанных = cast(ВариантыПредложенияСтавки.ВерсияДанных AS binary(8))
	into #t_ВариантыПредложенияСтавки
	--SELECT *
	from Stg._1cCRM.Справочник_ВариантыПредложенияСтавки AS ВариантыПредложенияСтавки
	where ВариантыПредложенияСтавки.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.ВариантыПредложенияСтавки') is null
	begin
	
		select top(0)
			GuidВариантПредложенияСтавки,
			isDelete,
			Код,
			Наименование,
			НеДоступенДляИзменения,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into hub.ВариантыПредложенияСтавки
		from #t_ВариантыПредложенияСтавки

		alter table hub.ВариантыПредложенияСтавки
			alter column GuidВариантПредложенияСтавки uniqueidentifier not null

		ALTER TABLE hub.ВариантыПредложенияСтавки
			ADD CONSTRAINT PK_ВариантыПредложенияСтавки PRIMARY KEY CLUSTERED (GuidВариантПредложенияСтавки)
	end
	
	--begin tran
		merge hub.ВариантыПредложенияСтавки t
		using #t_ВариантыПредложенияСтавки s
			on t.GuidВариантПредложенияСтавки = s.GuidВариантПредложенияСтавки
		when not matched then insert
		(
			GuidВариантПредложенияСтавки,
			isDelete,
			Код,
			Наименование,
			НеДоступенДляИзменения,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidВариантПредложенияСтавки,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.НеДоступенДляИзменения,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
		then update SET
			t.isDelete = s.isDelete,
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.НеДоступенДляИзменения = s.НеДоступенДляИзменения,
			t.updated_at = s.updated_at,
			t.ВерсияДанных = s.ВерсияДанных
			;
	--commit tran
	

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end

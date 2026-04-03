
create   procedure files.cession_exclusion_postloader
as
begin
	SET NOCOUNT ON
	SET XACT_ABORT ON

	begin try
	if not exists(select top(1) 1 from files.cession_exclusion_buffer)
		begin
			;throw 51000, 'в таблице files.cession_exclusion_buffer нет данных', 16
		end 
	begin tran
		truncate table [files].cession_exclusion
		insert into [files].[cession_exclusion]([№ договора], [created])
		select 
		[№ договора]
		,[created] = getdate()
		from (select 
			[№ договора] = cast(try_cast([№ договора] as decimal(20,0)) as nvarchar(20))
			
		from [files].[cession_exclusion_buffer]
		where [№ договора] is not null
		)t 
		where [№ договора] is not null
	commit tran
	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end
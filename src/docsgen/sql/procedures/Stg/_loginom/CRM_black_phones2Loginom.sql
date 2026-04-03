create   procedure _loginom.[CRM_black_phones2Loginom]
as
begin
begin try
drop table if exists #t_blackPhoneList
	select * 
	into #t_blackPhoneList
	from [dwh-ex].[RestServices].[dbo].[CRM_BlackPhoneList]

if exists (select top(1) 1 from #t_blackPhoneList)
begin 
	if OBJECT_ID('_loginom.CRM_BlackPhoneList') is null
	begin
		select top(0) * 
		into _loginom.CRM_BlackPhoneList
		from #t_blackPhoneList
	end

	begin tran 
		delete from _loginom.CRM_BlackPhoneList
		insert into _loginom.CRM_BlackPhoneList
		select * from #t_blackPhoneList
	commit tran
end
end try
begin catch
	if @@TRANCOUNT>0
		ROLLBACK TRAN
	;throw
end catch
end

-- Usage: запуск процедуры с параметрами
-- EXEC [_1cCRM].[FullBlackPhoneList_FROM_CRM] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create     procedure [_1cCRM].[FullBlackPhoneList_FROM_CRM]
as
begin

	drop table if exists #t_crm
	begin try
	select distinct Phone = ж.Номер                                               
	,      ИсточникДанных                                                
	,      create_at= dateadd(year,-2000, ДатаЗаписи)                    
	,      ReasonAdding_subjectGuid = dbo.getGUIDFrom1C_IDRREF(до.Ссылка)
	,      ReasonAdding_subject = Наименование                           
		into #t_crm
	from       _1cCRM.РегистрСведений_ЖурналДанныхЧерногоСписка ж 
	inner join _1cCRM.Справочник_ДеталиОбращений                до on ж.ДеталиОбращений = до.Ссылка

	if exists(select top(1) 1
		from #t_crm)
	begin
		begin tran
		delete from _1cCRM.BlackPhoneList

		insert into _1cCRM.BlackPhoneList ( ReasonAdding_subject, ReasonAdding_subjectGuid, Phone, create_at )
		select ReasonAdding_subject
		,      ReasonAdding_subjectGuid
		,      Phone
		,      create_at
		from #t_crm
		commit tran
	end
	end try
	begin catch
	IF @@TRANCOUNT>0
		rollback tran
	;throw
	end catch
end


--exec [dbo].[Create_dm_FillingTypeChangesInRequests]

CREATE   PROC [dbo].[Create_dm_FillingTypeChangesInRequests]
as
begin

set nocount on
 --return

	begin try
		DROP TABLE IF EXISTS #t_Result

		select 
			z.Номер as 'Номер заявки'
			, rs.[ДатаИзменения] as 'Дата изменения'
			, sz.Наименование as 'Статус'
			, offices.Наименование as 'Офис'
			, authors.Наименование as 'Автор'
			, vidz.[Наименование] as 'Вид заполнения'
		--into dbo.dm_FillingTypeChangesInRequests
		into #t_Result
		from stg._1cCRM.[РегистрСведений_ИзмененияВидаЗаполненияВЗаявках] as rs with (nolock)
		left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] as z with (nolock)
		on z.Ссылка=rs.Заявка
		left join [Stg].[_1cCRM].[Справочник_Офисы] as offices with (nolock)
		on rs.Офис = offices.Ссылка
		left join [Stg].[_1cCRM].[Справочник_Пользователи] as authors with (nolock)
		on rs.Автор = authors.Ссылка
		left join   [Stg].[_1cCRM].[Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС] vidz with (nolock)
		on vidz.[Ссылка] = rs.ВидЗаполнения
		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] as sz with (nolock)
		on sz.Ссылка=rs.Статус
  begin tran
		--truncate table dbo.dm_FillingTypeChangesInRequests_OLD
		--insert into     dbo.dm_FillingTypeChangesInRequests_OLD
		truncate table dbo.dm_FillingTypeChangesInRequests
		insert into     dbo.dm_FillingTypeChangesInRequests
		(
				[Номер заявки]
				, [Дата изменения]
				, [Статус]
				, [Офис]
				, [Автор]
				, [Вид заполнения]
		)
		select 
				[Номер заявки]
				, [Дата изменения]
				, [Статус]
				, [Офис]
				, [Автор]
				, [Вид заполнения]
		from #t_Result
 commit tran
 
 end try
 begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
 end catch
end

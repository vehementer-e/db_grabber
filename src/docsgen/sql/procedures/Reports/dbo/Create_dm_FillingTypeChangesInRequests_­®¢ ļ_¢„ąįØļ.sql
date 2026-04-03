
--exec [dbo].[Create_dm_FillingTypeChangesInRequests_NEW]

CREATE   PROC dbo.[Create_dm_FillingTypeChangesInRequests_новая_версия]
as
begin

set nocount on
 --return

begin try

	DROP TABLE IF EXISTS #t_Result

	SELECT TOP(0) *
	INTO #t_Result
	FROM dbo.dm_FillingTypeChangesInRequests_NEW

	/*
	--var 1 
		select 
			z.Номер as 'Номер заявки'
			, rs.[ДатаИзменения] as 'Дата изменения'
			, sz.Наименование as 'Статус'
			, offices.Наименование as 'Офис'
			, authors.Наименование as 'Автор'
			, vidz.[Наименование] as 'Вид заполнения'
		--into dbo.dm_FillingTypeChangesInRequests_NEW
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
	*/

	--var 2
	INSERT #t_Result
	SELECT
		R.НомерЗаявки as 'Номер заявки'
		, H.ДатаИзменения as 'Дата изменения'
		, S.Наименование as 'Статус'
		, O.Наименование as 'Офис'
		, U.Наименование as 'Автор'
		, V.Наименование as 'Вид заполнения'
	FROM dwh2.sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения AS H
		INNER JOIN dwh2.hub.Заявка AS R
			ON H.GuidЗаявки = R.GuidЗаявки
		LEFT JOIN dwh2.hub.ВидЗаполненияЗаявокНаЗаймПодПТС AS V
			ON V.GuidВидЗаполненияЗаявокНаЗаймПодПТС = H.GuidВидЗаполненияЗаявокНаЗаймПодПТС
		LEFT JOIN dwh2.hub.СтатусыЗаявокПодЗалогПТС AS S
			ON S.GuidСтатусЗаявкиПодЗалогПТС = H.GuidСтатусЗаявкиПодЗалогПТС
		LEFT JOIN dwh2.hub.Офисы AS O
			ON O.GuidОфис = H.GuidОфис
		LEFT JOIN dwh2.hub.Пользователи AS U
			ON U.GuidПользователь = H.GuidCRMАвтор

begin tran
	truncate table dbo.dm_FillingTypeChangesInRequests_NEW
	insert into dbo.dm_FillingTypeChangesInRequests_NEW
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

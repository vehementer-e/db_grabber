
--exec [dbo].[Create_dm_RequestsApproved]

CREATE PROC dbo.Create_dm_RequestsApproved
as
begin

set nocount on
 --return

/*
--var 1
truncate table  dbo.dm_RequestsApproved 
insert into     dbo.dm_RequestsApproved 

SELECT 
a2.*
--into dbo.dm_RequestsApproved 
FROM
(
select
cast(dateadd(year,-2000,z.Дата) as date) 'ДатаЗаявки' 
, cast(z.Дата as date)  'ВремяЗаявки'
,z.НомерЗаявки
,z.Фамилия + ' ' + z.Имя + ' ' + z.Отчество as 'ФИО_Клиента'
,st.Наименование as 'ТекущийСтатус'
,sp.[Представление] as 'МестоСоздания'
,z.Сумма
,spv.[Представление] as 'СпособВыдачи'
,a1.Наименование as 'Партнер'
FROM [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z with (nolock)
left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] st with (nolock)
on st.Ссылка = z.Статус
left join [Stg].[_1cCRM].Перечисление_СпособыОформленияЗаявок sp with (nolock)
on sp.ссылка = z.СпособОформления
left join [Stg].[_1cCRM].[Перечисление_СпособыВыдачиЗаймов] spv
on z.СпособВыдачиЗайма = spv.Ссылка
left join [Stg].[_1cCRM].[Справочник_Офисы] a1
on z.Офис=a1.Ссылка
) as a2
left join 
(
SELECT
[Номер заявки], [Вид заполнения]
FROM
(
SELECT *
FROM
(
SELECT
[Номер заявки]
,[Дата изменения]
,[Статус]
,[Офис]
,[Автор]
,[Вид заполнения]
,ROW_NUMBER () over (partition by [Номер заявки] order by [Дата изменения] DESC) as RN
FROM [dbo].[dm_FillingTypeChangesInRequests]
where [Статус] in 
('Предварительная'
,'Черновик'
,'Черновик из ЛК'
,'Клиент зарегистрировался в МП'
,'Контроль авторизации'
,'Контроль заполнения ЛКК'
,'Верификация КЦ'
,'Предварительное одобрение'
,'Клиент прикрепляет фото в МП'
,'Контроль фото ЛКК'
,'Ожидание контроля данных'
,'Контроль данных'
)
) as s1
where RN = 1
) as s2
) as s3
on a2.НомерЗаявки=s3.[Номер заявки]

where 
year (ДатаЗаявки) >= '2020'
and [ТекущийСтатус] in
('Договор зарегистрирован', 'Договор подписан', 'Контроль подписания договора', 'Контроль получения ДС')
and [Вид заполнения] = 'Заполняется в мобильном приложении'
order by ДатаЗаявки
*/

--var 2
DROP TABLE IF EXISTS #t_RequestsApproved

SELECT TOP(0) *
INTO #t_RequestsApproved
FROM dbo.dm_RequestsApproved


INSERT #t_RequestsApproved
SELECT 
	L.ДатаЗаявки,
	L.ВремяЗаявки,
	L.НомерЗаявки,
	L.ФИО_Клиента,
	L.ТекущийСтатус,
	L.МестоСоздания,
	L.Сумма,
	L.СпособВыдачи,
	L.Партнер
	--L.[Вид Заполнения],
	--L.RN
FROM (
	SELECT --TOP 100 
		ДатаЗаявки = cast(R.ДатаЗаявки AS date),
		ВремяЗаявки = cast(R.ДатаЗаявки AS time),
		R.НомерЗаявки,
		ФИО_Клиента = R.ФИО,
		ТекущийСтатус = R.СтатусЗаявки,
		R.МестоСоздания,
		Сумма = R.СуммаЗаявки,
		СпособВыдачи = R.СпособВыдачиЗайма,
		--R.ВидЗаполнения,
		[Вид Заполнения] = V.Наименование,
		Партнер = R.Офис, --,a1.Наименование as 'Партнер'
		RN = row_number() over (partition by R.НомерЗаявки order by H.ДатаИзменения DESC)
	FROM dwh2.dm.ЗаявкаНаЗаймПодПТС AS R
		INNER JOIN dwh2.sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения AS H
			ON H.GuidЗаявки = R.GuidЗаявки
		INNER JOIN dwh2.hub.СтатусыЗаявокПодЗалогПТС AS SZ
			ON SZ.GuidСтатусЗаявкиПодЗалогПТС = H.GuidСтатусЗаявкиПодЗалогПТС
			AND SZ.Наименование IN (
				'Предварительная'
				,'Черновик'
				,'Черновик из ЛК'
				,'Клиент зарегистрировался в МП'
				,'Контроль авторизации'
				,'Контроль заполнения ЛКК'
				,'Верификация КЦ'
				,'Предварительное одобрение'
				,'Клиент прикрепляет фото в МП'
				,'Контроль фото ЛКК'
				,'Ожидание контроля данных'
				,'Контроль данных'
			)
		INNER JOIN dwh2.hub.ВидЗаполненияЗаявокНаЗаймПодПТС AS V
			on V.GuidВидЗаполненияЗаявокНаЗаймПодПТС = H.GuidВидЗаполненияЗаявокНаЗаймПодПТС
	WHERE 1=1
		AND year(R.ДатаЗаявки) >= 2020
		AND R.СтатусЗаявки IN (
			'Договор зарегистрирован',
			'Договор подписан',
			'Контроль подписания договора',
			'Контроль получения ДС'
		)
		--AND R.ВидЗаполнения = 'Заполняется в мобильном приложении'
		--test
		--AND R.НомерЗаявки = '24101402597302'
	) AS L
WHERE 1=1
	AND L.RN = 1
	AND L.[Вид заполнения] = 'Заполняется в мобильном приложении'

BEGIN TRAN
	truncate table  dbo.dm_RequestsApproved
	insert dbo.dm_RequestsApproved
	SELECT * FROM #t_RequestsApproved AS R
COMMIT 

	

end

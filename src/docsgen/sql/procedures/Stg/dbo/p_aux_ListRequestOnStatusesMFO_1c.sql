
-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-05-07
-- Description:	 
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[p_aux_ListRequestOnStatusesMFO_1c];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[p_aux_ListRequestOnStatusesMFO_1c]
AS
BEGIN  --auxtab_ListRequestOnStatusesMFO_1c

	SET NOCOUNT ON;

	
if OBJECT_ID('[Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c]') is not null 
truncate table [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c];


---- Создание вспомогательной таблицы "Комментарии к заявке"
--create table [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c]
--(
--[Период] datetime not null
--,[Регистратор_ТипСсылки] binary(8) not null
--,[Регистратор_Ссылка] binary(16) not null
--,[Заявка] binary(16) not null--datetime not null
--,[ЗаявкаНомер] nvarchar(255) not null
--,[Исполнитель] binary(16) not null 
--,[ИсполнительНаим] nvarchar(255) null
--,[Статус] binary(16) null --binary(16) null
--,[СтатусНаим] nvarchar(255) null
--,[Причина] binary(16) null
--,[ПричинаНаим] nvarchar(255) null
--,[ПричинаОтказа] binary(16) null
--,[ПричинаОтказаНаим] nvarchar(255) null
--,[ПричинаОтказаКод] nvarchar(50) null
--,[Вид] binary(16) null
--);
insert into [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c]([Период] ,[Регистратор_ТипСсылки] ,[Регистратор_Ссылка] ,[Заявка] ,[ЗаявкаНомер] ,[Исполнитель]
																		  ,[ИсполнительНаим] ,[Статус] ,[СтатусНаим] ,[Причина] ,[ПричинаНаим] ,[ПричинаОтказа] 
																		  ,[ПричинаОтказаНаим] ,[ПричинаОтказаКод] ,[Вид])	

SELECT zl.[Период] AS [Период]
      ,zl.[Регистратор_ТипСсылки]
      ,zl.[Регистратор_Ссылка]
      ,zl.[Заявка]
	  ,z.[Номер] AS [ЗаявкаНомер]
      ,zl.[Исполнитель]
	  ,u.[Наименование] AS [ИсполнительНаим]
      ,zl.[Статус]
	  ,zs.[Наименование] AS [СтатусНаим]
      ,zl.[Причина]
	  ,zrs.[Имя] AS [ПричинаНаим]
      ,zl.[ПричинаОтказа] AS [ПричинаОтказа]
	  ,cof.[Наименование] AS [ПричинаОтказаНаим]
	  ,cof.[Кодификатор] AS [ПричинаОтказаКод]
	  ,cof.[Вид]

FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок] zl  WITH (NOLOCK) -- zayvka list
	LEFT JOIN [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] z WITH (NOLOCK) -- zayvka
	ON zl.[Заявка]=z.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_Пользователи] u WITH (NOLOCK) --user
	ON zl.[Исполнитель]=u.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_ГП_СтатусыЗаявок] zs with (nolock)
	ON zl.[Статус]=zs.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Перечисление_ГП_ПричиныСтатусаЗаявки] zrs with (nolock)
	ON zl.[Причина]=zrs.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_ПричиныОтказа] cof with (nolock) -- cause of failure
	ON zl.[ПричинаОтказа]=cof.[Ссылка]
 WHERE zl.[Период]>= dateadd(year,2000, dateadd(MONTH,datediff(MONTH,0,dateadd(month,-2,Getdate())),0))  -- zs.[Наименование]=N'Контроль данных'

	-- 02.03.2022. А.Никитин. добавил условие, т.к.
	-- джоб "Verification. Reports "ForControlOnData", daily at 8:20 and 21:20" падал с ошибкой
	-- Cannot insert the value NULL into column 'ЗаявкаНомер', table 'Stg.dbo.aux_ListRequestOnStatusesMFO_1c'; 
	AND z.[Номер] IS NOT NULL

  ORDER BY z.[Номер] asc

END

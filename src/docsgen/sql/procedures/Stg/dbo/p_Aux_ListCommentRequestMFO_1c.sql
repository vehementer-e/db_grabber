

-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-05-07
-- Description:	Таблица с комментариями о причинах отказа и аннулирования заявок на статусе "Контроль данных" по данным МФО 

-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[p_Aux_ListCommentRequestMFO_1c];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[p_Aux_ListCommentRequestMFO_1c]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if OBJECT_ID('[Stg].[dbo].[aux_ListCommentRequestMFO_1c]') is not null 
truncate table [Stg].[dbo].[aux_ListCommentRequestMFO_1c];


---- Создание вспомогательной таблицы "Комментарии к заявке"
--create table [Stg].[dbo].[aux_ListCommentRequestMFO_1c]
--(
--[Период] datetime not null
--,[Заявка] binary(16) not null
-- ,[ГУИДЗаписи]  nvarchar(255) not null
-- ,[ДатаЗаявки] nvarchar(255) not null--datetime not null
-- ,[Клиент] binary(16) not null
-- ,[Пользователь_Тип] binary(2) not null 
-- ,[Пользователь_Строка] nvarchar(255) null
-- ,[Пользователь_Ссылка] binary(16) null --binary(16) null
-- ,[Комментарий] nvarchar(255) null
-- ,[ПричинаОтказа] nvarchar(255) null
-- ,[ОбщийДоступ] binary(2) null
-- ,[Должность] binary(16) null
----,[МаркерКоллектинг] nvarchar(255) null
----,[ВнешнийID] nvarchar(255) null
--);
insert into [Stg].[dbo].[aux_ListCommentRequestMFO_1c]([Период] ,[Заявка] ,[ГУИДЗаписи] ,[ДатаЗаявки] ,[Клиент] ,[Пользователь_Тип]
																		  ,[Пользователь_Строка] ,[Пользователь_Ссылка] ,[Комментарий] ,[ПричинаОтказа]
																		  ,[ОбщийДоступ] ,[Должность])	
SELECT zc.[Период] ,zc.[Заявка] ,zc.[ГУИДЗаписи] ,zc.[ДатаЗаявки] ,zc.[Клиент] ,zc.[Пользователь_Тип] 
		,zc.[Пользователь_Строка] ,zc.[Пользователь_Ссылка] ,cast(zc.[Комментарий] as nvarchar(255)) as [Комментарий] ,zll.[ПричинаОтказа] ,zc.[ОбщийДоступ] ,zc.[Должность]
  FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_КомментарииЗаявок] zc with (nolock)
  left join (select [Заявка], r.[Наименование] as [ПричинаОтказа]
			 from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок_ИтогиСрезПоследних] zll0 with (nolock)
			 left join [prodsql02].[mfo].[dbo].[Справочник_ПричиныОтказа] r with (nolock)
				on zll0.[ПричинаОтказа]=r.[Ссылка]
			) zll
  on zc.[Заявка]=zll.[Заявка]
  where [ДатаЗаявки]>=dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0)
  order by [ДатаЗаявки] desc

END



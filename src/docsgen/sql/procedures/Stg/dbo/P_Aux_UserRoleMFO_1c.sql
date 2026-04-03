
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-05-20
-- Description:	Таблица Пользователь-Роль из МФО
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[P_Aux_UserRoleMFO_1c];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[P_Aux_UserRoleMFO_1c]
	-- Add the parameters for the stored procedure here

AS
BEGIN  --aux_UserRoleMFO_1c

	SET NOCOUNT ON;

    -- Insert statements for procedure here
--	SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>

if OBJECT_ID('[Stg].[dbo].[aux_UserRoleMFO_1c]') is not null 
truncate table [Stg].[dbo].[aux_UserRoleMFO_1c];

-- Создание вспомогательной таблицы "Пользователь Роль в МФО"
--create table [Stg].[dbo].[aux_UserRoleMFO_1c]
--(
--[Пользователь_Ссылка] binary(16) not null
--,[Пользователь_Наим]  nvarchar(255) not null
--,[Должность_Ссылка] binary(16) null
--,[Должность_Наим] nvarchar(255) null
--,[РольПользователя] nvarchar(50) null
--);
insert into [Stg].[dbo].[aux_UserRoleMFO_1c]([Пользователь_Ссылка] ,[Пользователь_Наим] ,[Должность_Ссылка] ,[Должность_Наим] ,[РольПользователя] ,[ДатаУвольнения])
select us.[Пользователь_Ссылка] ,us.[Пользователь_Наим] ,us.[Должность_Ссылка] ,us.[Должность_Наим]
		,case 
			when sum(s.[Администратор])>0 then N'Админ'
			when sum(s.[СотрудникСБ])>0 then N'СБ'
			when sum(s.[ПерсональныйМенеджер])>0 then N'ПМ'
			when sum(s.[Администратор])>0 and sum(s.[СотрудникСБ])=0 and sum(s.[ПерсональныйМенеджер])=0 then N'Админ'
			when us.[Должность_Ссылка] is null then N'Админ'
			else N'Ошибка'
		end as [РольПользователя]
					--		,s.[НазваниеРоли]
					--		,us.[ДатаРождения] ,us.[ДатаПриемаНаработу] 
		,us.[ДатаУвольнения]
from (
	  select u.[Ссылка] as [Пользователь_Ссылка] ,u.[Наименование] as [Пользователь_Наим] ,u.[Должность] as [Должность_Ссылка] ,dl.[Наименование] as [Должность_Наим] ,[ДатаУвольнения]
/*select */	  from [prodsql02].[mfo].[dbo].[Справочник_Пользователи] u  with (nolock)
	  left join [prodsql02].[mfo].[dbo].[Справочник_ДолжностиОрганизаций] dl with (nolock)
		on u.[Должность]=dl.[Ссылка]
	  ) us
left join (select d.[Ссылка] as [Должность_Ссылка] ,d.[Наименование] as [Наименование]
					,case 
						when dn.[НазваниеРоли]=N'СлужбаБезопасностиМФО' then 1 
						when dn.[НазваниеРоли]=N'НачальникСБМФО' then 1
						else 0 end as [СотрудникСБ]
						,case 
							when dn.[НазваниеРоли]=N'КонтактЦентрМФО' then 1 
							when dn.[НазваниеРоли]=N'КоллЦентрМФО' then 1
							when dn.[НазваниеРоли]=N'АвтоКредитМФО' then 1
						else 0 end as [ПерсональныйМенеджер]
						,case 
							when dn.[НазваниеРоли]=N'АдминистраторМФО' then 1 
						else 0 end as [Администратор]
						,dn.[НазваниеРоли] ,dn.[ПредставлениеРоли] ,d.[Наименование] as [Должность_Наим]
			from [prodsql02].[mfo].[dbo].[Справочник_ДолжностиОрганизаций] d with (nolock)
			left join [prodsql02].[mfo].[dbo].[Справочник_ДолжностиОрганизаций_НастройкиДоступа] dn with (nolock)
				on d.[Ссылка]=dn.[Ссылка] 
			where d.[ПометкаУдаления]=0x00) s
on us.[Должность_Ссылка]=s.[Должность_Ссылка]
group by us.[Пользователь_Ссылка] ,us.[Пользователь_Наим],us.[Должность_Ссылка],us.[Должность_Наим]	,us.[ДатаУвольнения]
 	
END

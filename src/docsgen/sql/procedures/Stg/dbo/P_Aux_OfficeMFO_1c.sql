-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-05-20
-- Description:	Таблица офисов из МФО
-- =============================================
CREATE PROCEDURE [dbo].[P_Aux_OfficeMFO_1c]
	-- Add the parameters for the stored procedure here

AS
BEGIN  --auxtab_TableOfficeMFO_1c

	SET NOCOUNT ON;

    -- Insert statements for procedure here
--	SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>

/*	
if OBJECT_ID('[dbo].[aux_OfficeMFO_1c]') is not null 
drop table [dbo].[aux_OfficeMFO_1c];


-- Создание вспомогательной таблицы "Комментарии к заявке"
create table [dbo].[aux_OfficeMFO_1c]
(
[Этаж] nvarchar(5) not null
,[ПроРодитель] binary(16) not null 
,[Родитель] binary(16) not null 
,[РодительКод] nvarchar(50) not null 
,[РодительНаим] nvarchar(255) null
,[ЭтажНиже] nvarchar(5) null
,[Подчиненный] binary(16) null 
,[ПодчКод] nvarchar(50) null 
,[ПодчНаим] nvarchar(255) null
);
*/
--DWH-1764
TRUNCATE TABLE [dbo].[aux_OfficeMFO_1c]

INSERT into [dbo].[aux_OfficeMFO_1c] ([Этаж] ,[ПроРодитель] ,[Родитель] ,[РодительКод] ,[РодительНаим]
																	,[ЭтажНиже] ,[Подчиненный] ,[ПодчКод] ,[ПодчНаим])

SELECT * 
FROM
(
SELECT distinct [Этаж_L1] as [Этаж] ,[Род_L1] as [ПроРодитель] ,[Ссылка_L1] as [Родитель] ,[Код_L1] as [РодительКод] ,[Наим_L1] as [РодительНаим]
				,[Этаж_L2] as [ЭтажНиже] ,[Ссылка_L2] as [Подчиненный] ,[Код_L2] as [ПодчКод] ,[Наим_L2] as [ПодчНаим]
  FROM [dbo].[OfficeStructure_1cMFO]
  WHERE not [Род_L1] is null or not [Ссылка_L2] is null

  union all

  SELECT distinct [Этаж_L2] ,[Род_L2] ,[Ссылка_L2] ,[Код_L2] ,[Наим_L2] ,[Этаж_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3]
   FROM [dbo].[OfficeStructure_1cMFO]
   where not [Род_L2] is null or not [Ссылка_L3] is null

  union all

  SELECT distinct [Этаж_L3] ,[Род_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3] ,[Этаж_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4]
   FROM [dbo].[OfficeStructure_1cMFO]
   where not [Род_L3] is null or not [Ссылка_L4] is null

  union all

  SELECT distinct [Этаж_L4] ,[Род_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4] ,[Этаж_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5]
   FROM [dbo].[OfficeStructure_1cMFO]
   where not [Род_L4] is null or not [Ссылка_L5] is null

  union all

  SELECT distinct [Этаж_L5] ,[Род_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5] ,[Этаж_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6]
   FROM [dbo].[OfficeStructure_1cMFO]
   where not [Род_L5] is null or not [Ссылка_L6] is null

  union all

  SELECT distinct [Этаж_L6] ,[Род_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6] ,[Этаж_L7] ,[Ссылка_L7] ,[Код_L7] ,[Наим_L7]
  FROM [dbo].[OfficeStructure_1cMFO]
  where not [Род_L6] is null or not [Ссылка_L7] is null
) a
WHERE a.[Подчиненный] is not null
  	
END

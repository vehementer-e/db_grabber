

-- =============================================
-- Author:		20.10.2020>
-- Description:	<Description,,>
--exec [files].[Refuses_CP_postloader]
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[Refuses_CP_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [files].[Refuses_CP_postloader]
as begin
DECLARE @mindate date
set nocount on




/**/
  -- предварительно скопируем в таблицу буфера

delete from [files].[refuses_CP_buffer]

INSERT INTO [files].[refuses_CP_buffer]
select  [Дата_договора]
      ,[Дата_расторжения]
      ,[Договор]
      ,[Код_продкута]
      ,[Продукт]
      ,[сумма_услуги]
      ,[сумма_коммиссии]
      ,[created]
FROM [files].[refuses_CP_buffer_stg] b



  select 0
  
end

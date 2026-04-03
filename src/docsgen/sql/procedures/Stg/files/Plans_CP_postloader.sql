


-- =============================================
-- Author:		20.10.2020>
-- Description:	<Description,,>
--exec [files].[Plans_CP_postloader]
-- =============================================
CREATE PROCEDURE [files].[Plans_CP_postloader]
as begin
DECLARE @mindate date
set nocount on





  -- предварительно скопируем в таблицу буфера

delete from [files].[plans_CP_buffer]

INSERT INTO [files].[plans_CP_buffer]
select  [Дата]
      ,[Продукт]
      ,[Метрика]
      ,[План]
      ,[created]
FROM [files].[plans_CP_buffer_stg] b

/**/

  select 0
  
end

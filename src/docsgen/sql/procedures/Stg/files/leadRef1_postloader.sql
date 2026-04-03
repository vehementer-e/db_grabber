
-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <19.03.2020>
-- Description:	<Description,,>
-- exec  [files].[leadRef1_postloader]
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[leadRef1_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [files].[leadRef1_postloader]
as begin
set nocount on



  
 
delete from [files].[leadRef1_buffer]

INSERT INTO [files].[leadRef1_buffer]
( [Канал от источника]
      ,[Группа каналов]
      ,[created])

select [Канал от источника]
      ,[Группа каналов]
      ,[created]
from [files].[leadRef1_buffer_stg] b
  select 0
end

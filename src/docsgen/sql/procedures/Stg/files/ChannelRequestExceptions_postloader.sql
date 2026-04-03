
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[ChannelRequestExceptions_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [files].[ChannelRequestExceptions_postloader]
as begin
set nocount on
 

 
delete from [files].[ChannelRequestExceptions_buffer]

INSERT INTO [files].[ChannelRequestExceptions_buffer]
( [Номер заявки]
      ,[Канал от источника]
      ,[РП]
      ,[РО_Регион]
      ,[Партнер]
      ,[Номер партнера]
      ,[Юрлицо]
      ,[Место cоздания]
      ,[created])

select [Номер заявки]
      ,[Канал от источника]
      ,[РП]
      ,[РО_Регион]
      ,[Партнер]
      ,[Номер партнера]
      ,[Юрлицо]
      ,[Место cоздания]
      ,[created] 
from [files].[ChannelRequestExceptions_buffer_stg] b

  select 0
 
end

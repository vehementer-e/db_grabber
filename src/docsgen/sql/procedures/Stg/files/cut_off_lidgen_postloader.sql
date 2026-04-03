
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--exec [files].[cut_off_lidgen_postloader]
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[cut_off_lidgen_postloader];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [files].[cut_off_lidgen_postloader]

as

begin

 

  set nocount on

 

 

delete from files.cut_off_lidgen_buffer

INSERT INTO [files].[cut_off_lidgen_buffer]
([Campaign] ,[Cutoff] ,[created])

select [Campaign] ,

 Cutoff,

[created] 
from files.cut_off_lidgen_buffer_stg b

delete from files.cut_off_lidgen

INSERT INTO [files].[cut_off_lidgen]
([Campaign] ,[Cutoff] ,[created])

select [Campaign] ,

cast( [Cutoff] as int) Cutoff,

[created] 
from files.cut_off_lidgen_buffer_stg b

select 0

end

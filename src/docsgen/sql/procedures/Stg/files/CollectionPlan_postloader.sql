
-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <20.03.2020>
-- Description:	<Description,,>
-- exec  [files].[CollectionPlan_postloader]
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[CollectionPlan_postloader];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [files].[CollectionPlan_postloader]
as begin
DECLARE @mindate date
set nocount on

/* -- 20.03.2020 уже был до этого закомментирован
--set @mindate = (select min([Дата]) from [files].[CollectionPlan_buffer]);

--delete from [dwh_new].[dbo].[sales_plan2] where [Date]>=@mindate;

--insert into [dwh_new].[dbo].[sales_plan2]([Date]
--      ,[plans_lead]
--      ,[plans_req]
--      ,[plans_num]
--      ,[plans])
--	  select [Дата]
--	  ,[Лиды Всего]
--	  ,[Заявки Всего]
--	  ,[Займы Всего]
--      ,[Объем Всего]
--  FROM [files].[CollectionPlan_buffer];
*/


/*
SELECT [Дата]
      ,[Бакет]
      ,[Сумма среднее]
      ,[Сумма план]
      ,[Сумма план успех]
      ,[created]
  FROM [FilesBuffer].[files].[CollectionPlan_buffer]

  SELECT [Дата]
      ,[Бакет]
      ,[Сумма среднее]
      ,[Сумма план]
      ,[Сумма план успех]
      ,[created]
  FROM [c2-vsr-dwh].[files].[CollectionPlan_buffer]
  */

  
 
delete from [files].[CollectionPlan_buffer]

INSERT INTO [files].[CollectionPlan_buffer]
([Дата]
      ,[Бакет]
      ,[Сумма среднее]
      ,[Сумма план]
      ,[Сумма план успех]
      ,[created])

select [Дата]
      ,[Бакет]
      ,[Сумма среднее]
      ,[Сумма план]
      ,[Сумма план успех]
      ,[created]
from [files].[CollectionPlan_buffer_stg] b


  select 0
  
end

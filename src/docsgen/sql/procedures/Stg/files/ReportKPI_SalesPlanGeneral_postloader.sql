



-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <22.03.2021>
-- Description:	<Description,,>
--exec [files].[ReportKPI_SalesPlanGeneral_postloader]
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[ReportKPI_SalesPlanGeneral_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [files].[ReportKPI_SalesPlanGeneral_postloader]
as begin
set nocount on



/**/
--files.ReportKPI_SalesPlanGeneral_buffer'


  -- предварительно скопируем в таблицу буфера

    delete from [files].[ReportKPI_SalesPlanGeneral_buffer]

INSERT INTO [files].[ReportKPI_SalesPlanGeneral_buffer]
([Название отчета]
      ,[Дата]
      ,[Период планирования]
      ,[Вид займа]
      ,[Канал от источника]
      ,[Продукт]
      ,[Параметр]
      ,[Значение]
      ,[created])

select [Название отчета]
      ,[Дата]
      ,[Период планирования]
      ,[Вид займа]
      ,[Канал от источника]
      ,[Продукт]
      ,[Параметр]
      ,[Значение]
      ,[created]
  FROM [files].[ReportKPI_SalesPlanGeneral_buffer_stg] b

  select 0
  
end

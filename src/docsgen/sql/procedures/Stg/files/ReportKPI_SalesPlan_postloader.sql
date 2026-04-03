


-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <20.01.2021>
-- Description:	<Description,,>
--exec [files].[ReportKPI_SalesPlan_postloader]
-- =============================================
CREATE PROCEDURE [files].[ReportKPI_SalesPlan_postloader]
as begin
set nocount on



/**/



  -- предварительно скопируем в таблицу буфера

    delete from [files].[ReportKPI_SalesPlan_buffer]

INSERT INTO [files].[ReportKPI_SalesPlan_buffer]
([Дата конец месяца]
      ,[Заявок]
      ,[Займов, шт]
      ,[Займов, руб]
      ,[КП шт]
      ,[КП, руб gross]
      ,[КП, руб net]
      ,[created])

select [Дата конец месяца]
      ,[Заявок]
      ,[Займов, шт]
      ,[Займов, руб]
      ,[КП шт]
      ,[КП, руб gross]
      ,[КП, руб net]
      ,[created]
  FROM [files].[ReportKPI_SalesPlan_buffer_stg] b

  select 0
  
end

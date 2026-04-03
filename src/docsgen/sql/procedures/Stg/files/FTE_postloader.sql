
-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <20.03.2020>
-- Description:	<Description,,>
-- exec  [files].[FTE_postloader]
-- =============================================
CREATE PROCEDURE [files].[FTE_postloader]
as
begin
  
  set nocount on

  --delete   
  --  from [files].[FTE_plan_fact]  
  --       inner join [files].[Sales_DailyPlans] p on p.Дата=b.Дата 


  -- модификация от 20.03.2020
  -- добавим копирование оригинальной табилицы


  -- предварительно скопируем в таблицу буфера

    delete from files.FTE_buffer

INSERT INTO files.FTE_buffer
([cdate]
      ,[Indicator]
      ,[Факт/План]
      ,[Value]
      ,[created])

select [cdate]
      ,[Indicator]
      ,[Факт/План]
      ,[Value]
      ,[created]
from files.FTE_buffer_stg b


  INSERT INTO [files].[FTE_plan_fact] ([Дата] ,[Indicator] ,[Факт/План] ,[Value] ,[created])

  select cdate as [Дата]
		,[Indicator]
		,[Факт/План]
		,round([Value],0,0) as [Value]
		,[created]
--into [files].[FTE_plan_fact]
from files.FTE_buffer_stg


    select 0
end

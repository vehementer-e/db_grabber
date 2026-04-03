-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <20.03.2020>
-- Description:	<Description,,>
-- exec  [files].[LoadContactCenterPlans]
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[LoadContactCenterPlans] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [files].[LoadContactCenterPlans]
as
begin
  
  set nocount on




  -- предварительно скопируем буфферную таблицу
  delete from [files].[ContactCenterPlans_buffer]

INSERT INTO [files].[ContactCenterPlans_buffer]
([Дата]
      ,[Займы руб]
      ,[Факт/План]
      ,[План КП]
      --,[F5]
      --,[F6]
	  ,[План КП аналитический по дням]
	  ,[Сумма займов инстоллмент план]
      ,[created])

select [Дата]
      ,[Займы руб]
      ,[Факт/План]
      ,[План КП]
      --,[F5]
      --,[F6]
	  ,[План КП аналитический по дням]
	  ,[Сумма займов инстоллмент план]
      ,[created]
from [files].[ContactCenterPlans_buffer_stg] b

-- далее код обработчика в главном инстансе

  delete p  
    from files.ContactCenterPlans_buffer_stg b  
         inner join [files].[CC_DailyPlans] p on p.Дата=b.Дата 


  INSERT INTO [files].[CC_DailyPlans]
           ([Дата]
           ,[Займы руб] ,[Факт/План] ,[План КП],[План КП аналитический по дням],[Сумма займов инстоллмент план],created )
  select [Дата] 
       , [Займы руб] ,[Факт/План] ,[План КП],[План КП аналитический по дням] ,[Сумма займов инстоллмент план] , created 
    from files.ContactCenterPlans_buffer_stg b
	--select * into [files].[CC_DailyPlans] from files.ContactCenterPlans_buffer
--	drop table [files].[CC_DailyPlans]

    select 0
end

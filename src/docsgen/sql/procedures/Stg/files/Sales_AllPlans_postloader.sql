
--exec files.LoadContactCenterPlans

-- Usage: запуск процедуры с параметрами
-- EXEC [files].[Sales_AllPlans_postloader];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE procedure [files].[Sales_AllPlans_postloader]
as
begin
  
  set nocount on

  delete p  
    from files.Sales_AllPlans_buffer b  
         inner join [files].[Sales_DailyPlans] p on p.Дата=b.Дата 


  INSERT INTO [files].[Sales_DailyPlans]
           ([Дата] ,[Группа] ,[Метрика] ,[Колво] ,[Сумма] ,[created])

  select [Дата]
		,[Группа]
		,[Метрика]
		,round([Количество],0,0) as [Колво]
		,round([Сумма],0,0) as [Сумма]
		,[created]
    from files.Sales_AllPlans_buffer b


    select 0
end





-- =============================================
-- Author:		
-- Create date: 2020-02-18
-- Description:	Бизнес-займы
--             exec [dbo].[report_Factor_Analysis_002]   

-- =============================================
CREATE PROCEDURE [dbo].[report_Factor_Analysis_002]
	
	-- Add the parameters for the stored procedure here
	-- @MonthNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



begin tran
truncate table [dbo].[dm_Factor_Analysis_002]
insert into [dbo].[dm_Factor_Analysis_002]  with(tablockx)
SELECT 
      -- [Дата]
	    convert(varchar, dateadd(year,-2000,Дата) , 104) 'Дата' 
	  , convert(varchar, Дата , 108)  'Время' 
      ,[НомерДоговора] Номер
      ,[Статус] 'Текущий статус'
	  ,NULL 'Место создания'
	  --,[ДатаSQL] 
      ,[РП]
	  ,NULL Регион
	  ,[ИсточникОбращения] as 'Партнер'
	  , [Партнер] 'Номер партнера'
	  , NULL 'Регион проживания'
	  , NULL 'Вид займа'
	  , 'Бизнес-займ' as 'Продукт'
	  ,[СрокЗайма]
	  , NULL as 'Первичная сумма'
	  , NULL as 'Сумма одобренная'
	  ,[СуммаЗайма] as 'Выданная сумма'
	  , NULL as 'Сумма заявки'
	  , NULL as 'Способ выдачи'
	  , [Контрагент] as 'Юрлицо'
      ,[Процент] as 'ПроцСтавкаКредит'
      ,[ДатаПогашения]
	  ,[ДатаЗаявки]
	  ,[Дата] [ДатаПолная]
      --,[Контрагент]
      --,[ДатаРождения]
      --,[ПолКлиента]
      --,[СемейноеПоложение]
      --,[ТелефонМобильный]
      --,[ДатаПродажиДоговора]
      
      
      --,[Марка]
      --,[Модель]
      --,[ГодВыпуска]
      --,[ЗаемПоПорядку]
      --,[ПризнакДоговора]
      
      
      
      --,[Договор]
      --,[ПричинаЗакрытия]
	  
--into [dbo].[dm_Factor_Analysis_002]
from [Stg].[_1cUMFO].[Отчет_Договоры_БЗ]


commit

END

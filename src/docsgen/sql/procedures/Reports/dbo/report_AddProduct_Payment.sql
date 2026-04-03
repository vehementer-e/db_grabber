-- exec [dbo].[report_dashboard_001_CC] 
CREATE  PROCEDURE [dbo].[report_AddProduct_Payment] 

@pageNo int
AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here

if @pageNo =1

select a.[ДоговорНомер] 
		,(rl.[Фамилия]+' '+rl.[Имя]+' '+rl.[Отчество]) as [ФИО] 
		,[ДатаВыдачи] ,[СуммаВыдачи] as [СуммаВыдачи] ,[СуммаДопУслуг] 
		,[ПризнакКаско] ,[ПризнакСтрахованиеЖизни] ,[ПризнакРАТ] 
		,a.[СпособВыдачиЗайма] 
		,[SumEnsur] ,[SumKasko] ,[SumRat]
		,[EnsurКод] ,[RatКод] ,[KaskoКод]
		,a.[ДопПродукт_IDПлатСистемы] as [ID_ПлатСистемы]
		,a.[ДопПродукт_ID_Операции] as [ID_Операции]
		,isnull(a.[ДопПродукт_СтатусСписанияСтраховки],N'Отсутствует') as [СтатусПлатежа]
		,case when a.[ДопПродукт_СтатусСписанияСтраховки]=N'DECLINED' then a.[КомментКСтатусуСписСтраховки] else N'' end as [Комментарий]

from [Stg].[dbo].[Agreement_InterestRate] a
left join dwh_new.[dbo].[mt_requests_loans_mfo] rl on a.[ДоговорНомер]=rl.[ДоговорНомер]
where [ДатаВыдачи] between dateadd(month,-1,dateadd(MONTH,datediff(MONTH,0,Getdate()),0)) and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0))
	  and [СуммаДопУслуг]>0
order by a.[ДоговорНомер] desc

if @pageNo =2
with t0 as
(
select (rl.[Фамилия]+' '+rl.[Имя]+' '+rl.[Отчество]) as [ФИО]
		,case
			when [ПризнакСтрахованиеЖизни]=1 then [EnsurКод]
			when [ПризнакКаско]=1 then [KaskoКод]
		end as [НомерДоговораСтрахования]		
		,case
			when [ПризнакСтрахованиеЖизни]=1 then N'Спокойствие-лайт'
			when [ПризнакКаско]=1 then N'Всё Включено(ФИНКАСКО+Спокойствие Лайт)'
		end as [НаименованиеПродукта]
		
		,[ДатаВыдачи] as [ДатаДоговора]
		,[СуммаВыдачи] as [СтраховаяСумма]
		,[СуммаДопУслуг] as [СтраховаяПремия]
		,[ПризнакКаско] ,[ПризнакСтрахованиеЖизни] ,[ПризнакРАТ] 
		,[EnsurКод] ,[RatКод] ,[KaskoКод]
from [Stg].[dbo].[Agreement_InterestRate] a
left join dwh_new.[dbo].[mt_requests_loans_mfo] rl on a.[ДоговорНомер]=rl.[ДоговорНомер]
where [ДатаВыдачи] between dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,Getdate()),0)) and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0))
	  and [СуммаДопУслуг]>0 and ([ПризнакСтрахованиеЖизни]=1 or [ПризнакКаско]=1)
)
select [ФИО] ,[НомерДоговораСтрахования] ,[НаименованиеПродукта]
		,[ДатаДоговора]	,[СтраховаяСумма] ,[СтраховаяПремия] 
from t0 where [ПризнакСтрахованиеЖизни]=1

union all

select [ФИО] ,[НомерДоговораСтрахования] ,[НаименованиеПродукта]
		,[ДатаДоговора]	,[СтраховаяСумма] ,[СтраховаяПремия] 
from t0 where [ПризнакКаско]=1

order by [ДатаДоговора] desc


END

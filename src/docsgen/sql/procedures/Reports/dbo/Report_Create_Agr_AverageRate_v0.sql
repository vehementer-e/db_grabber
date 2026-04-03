
--exec Proc_CreatTable_Agr_IntRate_v1
CREATE  PROCEDURE [dbo].[Report_Create_Agr_AverageRate_v0] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @GetDate2000 datetime

set @GetDate2000=dateadd(year,2000,getdate());

  --if OBJECT_ID('[dbo].[report_Agreement_InterestRate]') is not null 
  --drop table [dbo].[report_Agreement_InterestRate];

--truncate table [dbo].[report_Agreement_InterestRate];

--delete from [dbo].[report_Agreement_InterestRate] 
--where [ДатаВыдачи]>=dateadd(day,-10,dateadd(day,datediff(day,0,getdate()),0));

truncate table [dbo].[report_Agreement_AverageRate];

  --create table [dbo].[report_Agreement_AverageRate]
  --        (
  --         [Дата] date null
		--  ,[Время] time null
  --        ,[Сумма] decimal(15,2) null
		--  ,[СреднВзвешСтавка] decimal(15,2) null
  --         );
with t0 as
(
select [ДатаВыдачиПолн]
	  ,cast([ДатаВыдачиПолн] as date) as [Дата]
	  ,cast(dateadd(hour,datediff(hour,0,cast(dateadd(hour,1,[ДатаВыдачиПолн]) as time)),0) as time) as [Время]
	  ,datepart(hh,[ДатаВыдачиПолн]) as [Час]
      --,[КолвоЗаймов]
      ,[СуммаВыдачи]
	  ,sum([СуммаВыдачи]) over(partition by cast([ДатаВыдачиПолн] as date) order by [ДатаВыдачиПолн] asc) as [СуммаВыдачНакопДень]
      ,[ПроцСтавкаКредит]
      ,[СтавкаНаСумму]
	  ,sum([СтавкаНаСумму]) over(partition by cast([ДатаВыдачиПолн] as date) order by [ДатаВыдачиПолн] asc) as [СтавкаНаСуммуНакопДень]
      --,[СпособВыдачиЗайма]

from [dbo].[report_Agreement_InterestRate]
where [ДатаВыдачиПолн] between dateadd(day,-2,dateadd(day,datediff(day,0,getdate()),0)) and getdate()
--order by 1 desc
)
,	t_2d as
(
select [Дата] ,cast(dateadd(SECOND,-1,dateadd(day,datediff(day,0,[ДатаВыдачиПолн]),0)) as time) as [Время] 
	  ,[СуммаВыдачНакопДень] as [Сумма] 
	  ,case when [СуммаВыдачНакопДень] is null then 0 else [СтавкаНаСуммуНакопДень]/[СуммаВыдачНакопДень] end as [СреднВзвешСтавка]
from t0 where [ДатаВыдачиПолн]=(select max([ДатаВыдачиПолн]) from t0 where cast([ДатаВыдачиПолн] as date) = cast(dateadd(day,-2,dateadd(day,datediff(day,0,getdate()),0)) as date)) 
)
,	t_1d as
(
select [Дата] ,cast(dateadd(SECOND,-1,dateadd(day,datediff(day,0,dateadd(day,1,[ДатаВыдачиПолн])),0)) as time) as [Время] 
	  ,[СуммаВыдачНакопДень] as [Сумма] 
	  ,case when [СуммаВыдачНакопДень] is null then 0 else [СтавкаНаСуммуНакопДень]/[СуммаВыдачНакопДень] end as [СреднВзвешСтавка]
from t0 where [ДатаВыдачиПолн]=(select max([ДатаВыдачиПолн]) from t0 where cast([ДатаВыдачиПолн] as date) = cast(dateadd(day,-1,dateadd(day,datediff(day,0,getdate()),0)) as date))  
)
,	t_0d as
(
select [Дата] ,cast(getdate() as time) as [Время] 
	  ,[СуммаВыдачНакопДень] as [Сумма] 
	  ,case when [СуммаВыдачНакопДень] is null then 0 else [СтавкаНаСуммуНакопДень]/[СуммаВыдачНакопДень] end as [СреднВзвешСтавка]
from t0 where [ДатаВыдачиПолн]=(select max([ДатаВыдачиПолн]) from t0 where cast([ДатаВыдачиПолн] as date) = cast(getdate() as date)) 

union all
select r.[Дата] ,r.[Время] ,r.[Сумма] ,case when r.[Сумма] is null or r.[Сумма]=0 then 0 else r.[СреднВзвешСтавка]/r.[Сумма] end as [СреднВзвешСтавка]
from (
select distinct [Дата] ,[Время] ,max([СуммаВыдачНакопДень]) over (partition by [Час]) as [Сумма]  ,max([СтавкаНаСуммуНакопДень]) over (partition by [Час]) as [СреднВзвешСтавка]
from t0 where [Дата] = cast(getdate() as date) and  [Час]<= datepart(hh,dateadd(hour,-1,getdate()))
) r
)
,	t_res as
(
select * from t_0d
union all
select * from t_1d
union all
select * from t_2d
)

insert into [dbo].[report_Agreement_AverageRate] ([Дата] ,[Время] ,[Сумма] ,[СреднВзвешСтавка])

select * from t_res order by [Дата] desc, [Время] asc


END

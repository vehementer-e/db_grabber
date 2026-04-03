-- exec [dbo].[report_dashboard_001v2_CC_body] 
CREATE  PROCEDURE  [dbo].[report_RequestsOnStatuses] 
AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here

 --   select * from   [Stg].[files].[CC_DailyPlans] 

--if object_id('tempdb.dbo.#tt') is not null drop table #tt

declare @dt date

set @dt = cast(dateadd(day,datediff(day,0,dateadd(day,0,getdate())),0) as date);
 

select t.[Период_Исх] as [ДатаСтатуса]
      ,t.[ЗаявкаНомер_Исх] as [НомерЗаявки]
      --,[ЗаявкаДата_Исх]
	  ,z.[ФИО]
	  ,z.[ЗапрошеннаяСумма]
	  ,z.[СуммаЗаявки] as [Сумма]
      ,t.[ИсполнительНаим_След] as [Сотрудник]
      ,t.[СтатусНаим_Исх]
      --,[СтатусСсылка_Исх]
	  --,z.[Канал]
	  --,z.[Канал2]
	  ,z.[МестоСоздЗаявки] as [Канал]
      --,[ИсполнительСсылка_Исх]
      --,[ИсполнительНаим_Исх]
      --,[ПричинаСсылка_Исх]
      --,[ПричинаНаим_Исх]
      --,[ЗаявкаСсылка_След]
      --,[Период_След]
      --,[Период_След_2]
      --,[СтатусСсылка_След]
      ,t.[СтатусНаим_След]
      --,[ИсполнительСсылка_След]
	  ,t.[СостояниеЗаявки] as [Состояние] 
	  ,t.[СтатусДляСостояния] as [ОсновнойСтатус]

	   ,cast(t.[Период_След] as decimal(15,10)) - cast(t.[Период_Исх] as decimal(15,10)) as [ВремяЗатрачено]
	   ,convert(nvarchar,cast(cast(t.[Период_След] as decimal(15,10)) - cast(t.[Период_Исх] as decimal(15,10)) as datetime) ,8) as [Продолжительность]
	   ,t.[Период_След] as [ДатаИзменСтатуса]
 
from [dwh_new].[dbo].[mt_requests_transition_mfo]  t  with (nolock)
left join (select [ЗаявкаСсылка] ,([Фамилия]+' '+[Имя]+' '+[Отчество]) as [ФИО] ,[ПервичнаяСумма] as [ЗапрошеннаяСумма] ,[СуммаЗаявки] 
		   ,[ЗаявкаКаналМФО_ТочкаВх] as [Канал] ,[ЗаявкаКаналМФО_ТочкаВх] as [Канал2] ,[МестоСоздЗаявки]		   
		   from [dwh_new].[dbo].[mt_requests_loans_mfo] with (nolock)
		   --where cast([ЗаявкаДатаОперации] as date)>=@dt
		   ) z
on t.[ЗаявкаСсылка_Исх]=z.[ЗаявкаСсылка]
where t.[ЗаявкаНомер_Исх] in (select [ЗаявкаНомер_Исх] from [dwh_new].[dbo].[mt_requests_transition_mfo] where cast([Период_След] as date)>=@dt) 
	  and cast([Период_След] as date)>=@dt 
	  and z.[ФИО]<>N'ТЕСТ ТЕСТ ТЕСТОВИЧ'
	 
  order by [ЗаявкаНомер_Исх] desc

END



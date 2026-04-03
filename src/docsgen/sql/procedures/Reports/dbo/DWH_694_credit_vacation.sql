

--exec [dbo].[DWH_636_Uploading_data_BKI]
CREATE  PROCEDURE [dbo].[DWH_694_credit_vacation]
	-- Add the parameters for the stored procedure here

--@PageNo int
--, @dtFrom date 
--, @dtTo date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @dtFrom datetime
		,@dtFrom2000 datetime
		--,@first_dt datetime

--set @first_dt = dateadd(day, -1,(select min([Период]) from Stg.[_1cCMR].[РегистрСведений_СведенияОКредитныхКаникулах])
set @dtFrom = case 
				when datepart(dd,getdate()) =1 
					then (select dateadd(day ,-1 ,cast(dateadd(year ,-2000 ,cast(min([Период]) as datetime2)) as datetime))
						  from Stg.[_1cCMR].[РегистрСведений_СведенияОКредитныхКаникулах]) 
				else dateadd(day ,-30 ,getdate()) 
			  end;
set @dtFrom2000 = dateadd(year ,2000 ,@dtFrom)


--drop table dbo.[DWH_694_credit_vacation_cmr]
delete from dbo.[DWH_694_credit_vacation_cmr] where cast([Период] as date) >= cast(@dtFrom as date)

insert into dbo.[DWH_694_credit_vacation_cmr]

select 
	  cast(dateadd(year , -2000 ,cast(r.[Период] as datetime2)) as date) [Период]
   --   ,[Регистратор]
	  --,o.[Ссылка]
	  ,'Обращение на кредитные каникулы '+ o.[Номер] + ' от ' + convert(varchar(10) ,cast(dateadd(year , -2000 ,cast(o.[Дата] as datetime2)) as date),104) [Регистратор]
	  --,convert(varchar(10) ,cast(dateadd(year , -2000 ,cast(o.[Дата] as datetime2)) as date),104) [qw]
      --,[НомерСтроки]
      --,[Активность]
      --,[Договор]
	  ,d.[Код] [Договор]
      ,cast(dateadd(year , -2000 ,cast([ДатаОкончания] as datetime2)) as date) [ДатаОкончания]
      ,[КоличествоПериодов]
      ,cast(dateadd(year , -2000 ,cast([ДатаПоГрафику] as datetime2)) as date) [ДатаПоГрафику]
      ,r.[ПроцентнаяСтавка]
      ,r.[ПричинаПредоставленияКредитныхКаникул]

--into dbo.[DWH_694_credit_vacation_cmr]
from Stg.[_1cCMR].[РегистрСведений_СведенияОКредитныхКаникулах] r
left join Stg.[_1cCMR].[Справочник_Договоры] d on r.[Договор]=d.[Ссылка]
left join Stg.[_1cCMR].[Документ_ОбращениеКлиента] o on r.[Регистратор]=o.[Ссылка]
where cast([Период] as date) >= cast(@dtFrom2000 as date) 

/*
select 
	  cast(dateadd(year , -2000 ,cast(r.[Период] as datetime2)) as date) [Период]
      ,[Регистратор]
	  ,o.[Ссылка]
	  ,'Обращение на кредитные каникулы '+ o.[Номер] + ' от ' + convert(varchar(10) ,cast(dateadd(year , -2000 ,cast(o.[Дата] as datetime2)) as date),104) [Регистратор2]
	  --,convert(varchar(10) ,cast(dateadd(year , -2000 ,cast(o.[Дата] as datetime2)) as date),104) [qw]
      --,[НомерСтроки]
      --,[Активность]
      --,[Договор]
	  ,d.[Код] [Договор]
      ,cast(dateadd(year , -2000 ,cast([ДатаОкончания] as datetime2)) as date) [ДатаОкончания]
      ,[КоличествоПериодов]
      ,cast(dateadd(year , -2000 ,cast([ДатаПоГрафику] as datetime2)) as date) [ДатаПоГрафику]
      ,r.[ПроцентнаяСтавка]
      ,r.[ПричинаПредоставленияКредитныхКаникул]
from Stg.[_1cCMR].[РегистрСведений_СведенияОКредитныхКаникулах] r
left join Stg.[_1cCMR].[Справочник_Договоры] d on r.[Договор]=d.[Ссылка]
left join Stg.[_1cCMR].[Документ_ОбращениеНаИзменениеДатыПлатежа] o on r.[Регистратор]=o.[Ссылка]
where o.[Ссылка] is null
*/

 END

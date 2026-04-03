
-- =============================================
-- Author:		Anton Sabanin
-- Create date: 06.11.2020
-- Description:	dwh-757
-- exec [dbo].[Create_dm_DashboardJira_First_By_Parameters] ull, null
-- =============================================
CREATE   PROCEDURE [dbo].[Create_dm_DashboardJira_First_By_Parameters]
	 @BeginDate as date
	,@EndDate as date
	
AS
BEGIN
	

	SET NOCOUNT ON;
	--объявляем курсор
  
	--order by [Порядок]
  
   Declare @project NVARCHAR(1000)
		 , @report_column NVARCHAR(1000)
		 , @system_name NVARCHAR(1000)
		 , @report_name NVARCHAR(1000)
		 , @report_query NVARCHAR(1000)
		 , @system_tested NVARCHAR(1000)
		 , @report_query_order int

		 
-- определим начало и конец недели
 declare @rowcount bigint = 0
	   , @created_at datetime2  = getdate() -- дата формирования
	   , @b_week date
	   , @e_week date
	   , @url_project NVARCHAR(1000)
	   , @project_column NVARCHAR(1000)

declare 
      @url VARCHAR(MAX)
	, @OUTSTATUS VARCHAR(1000) 
    , @TOTAL VARCHAR(40)  = '0'
	, @OUTCREATED datetime2 
	, @url_api VARCHAR(MAX)
	, @url_end VARCHAR(MAX)

--set @OUTCREATED = @created_at

-- первый день недели
SET datefirst 1
Set @b_week = dateadd(dd,-datepart(dw,DATEFROMPARTS(year(@created_at),1,1))-6+datepart(iso_week,@created_at)*7,DATEFROMPARTS(year(@created_at),1,1)) 
Set @e_week = dateadd(dd,-datepart(dw,DATEFROMPARTS(year(@created_at),1,1))+datepart(iso_week,@created_at)*7,DATEFROMPARTS(year(@created_at),1,1)) 


if @BeginDate is not null 
begin
	Set @b_week = @BeginDate
end

if @EndDate is not null 
begin
	Set @e_week = @EndDate
end

 DECLARE my_cur CURSOR FOR 
     SELECT 
	   [Название_отчета]
      ,[Система]
      ,[Показатель]
      ,[Запрос]
      --,[Период_расчета]
      ,[Тестируемость]
      ,[Порядок]
     FROM [dbo].[dm_Jira_List_Report_Query]
	 where [Номер_отчета] = 1

   --открываем курсор
   OPEN my_cur
   --считываем данные первой строки в наши переменные
   FETCH NEXT FROM my_cur INTO @report_name, @system_name, @report_column, @report_query, @system_tested, @report_query_order
   --если данные в курсоре есть, то заходим в цикл
   --и крутимся там до тех пор, пока не закончатся строки в курсоре
   WHILE @@FETCH_STATUS = 0
   BEGIN

   -- формируем запросы
Set @project = @system_name
Set @project_column = @report_column
Set @url_api = N'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20'
--Set @url = @url_api + @system_name + '%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'

--Set @url = @url_api + 'DWH' + '%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'

Set @url = @report_query + '%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'

print @url




    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	    insert into dbo.dm_WebData_Jira_Answer
		select 
		  @report_name as 'Название отчета'
		, @system_name as 'Система'
		, @report_column as 'Показатель'
		, @report_query as 'Спецальный запрос'
		, @system_tested as 'Тестируемость'
		, @report_query_order as 'Порядок вывода'
		, @OUTSTATUS  as outstatus
		, @TOTAL as TOTAL
		, @created_at as created_at
		, @system_tested as Tested
		, @url as url_query
		--into dbo.dm_WebData_Jira_Answer


		--select * from dbo.dm_WebData_Jira_Answer
		--delete from dbo.dm_WebData_Jira_Answer
--считываем следующую строку курсора
        FETCH NEXT FROM my_cur INTO @report_name, @system_name, @report_column, @report_query, @system_tested, @report_query_order
   END
   
   --закрываем курсор
   CLOSE my_cur
   DEALLOCATE my_cur

 select '1' as row_n ,Система,  [Название отчета], Тестируемость, [Порядок вывода], [Всего дефектов], Подтвержденных, Закрытых from(
 select Система, [Название отчета], Тестируемость, [Порядок вывода], Показатель, cast(total as bigint) as total
 from dbo.dm_WebData_Jira_Answer where created_at = @created_at
 ) t

 pivot (sum(total) for Показатель in ([Всего дефектов],[Подтвержденных],[Закрытых])) as pvt 
  union all
 select '2' as row_n , 'Итого' as Система,  [Название отчета], min(Тестируемость) as Тестируемость, 500 as [Порядок вывода], sum([Всего дефектов]) as [Всего дефектов], Sum(Подтвержденных) as Подтвержденных, sum(Закрытых) as Закрытых from(
 select Система, [Название отчета], '-' as Тестируемость, Показатель, cast(total as bigint) as total
 from dbo.dm_WebData_Jira_Answer where created_at = @created_at 
 ) t
 pivot (sum(total) for Показатель in ([Всего дефектов],[Подтвержденных],[Закрытых])) as pvt
 Group by  [Название отчета]
 union all
 select '3' as row_n , 'Итого по тестируемым' as Система,  [Название отчета], Тестируемость, 1000 as [Порядок вывода], sum([Всего дефектов]) as [Всего дефектов], Sum(Подтвержденных) as Подтвержденных, sum(Закрытых) as Закрытых from(
 select Система, [Название отчета], Тестируемость, Показатель, cast(total as bigint) as total
 from dbo.dm_WebData_Jira_Answer where created_at = @created_at  and Тестируемость = N'Да'
 ) t
 pivot (sum(total) for Показатель in ([Всего дефектов],[Подтвержденных],[Закрытых])) as pvt
 Group by  [Название отчета], Тестируемость
 order by [Порядок вывода]

END

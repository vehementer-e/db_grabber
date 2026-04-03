
-- =============================================
-- Author:		Anton Sabanin
-- Create date: 11.12.2020
-- Description:	dwh-812
-- exec [dbo].[Create_dm_DashboardJira_First_By_Parameters_Sort_new] @BeginDate = '2020-01-01', @EndDate = '2020-02-29', @Filter1 = null, @Filter2 = null
-- =============================================
CREATE     PROCEDURE [dbo].[Create_dm_DashboardJira_First_By_Parameters_Sort_new]
	 @BeginDate as date
	,@EndDate as date
	,@Filter1 as int
	,@Filter2 as int
	
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

if @Filter1 is null
begin
	Set @Filter1 = 0
end

if @Filter2 is null
begin
	Set @Filter2 = 0
end

 DECLARE my_cur CURSOR local FOR 
     SELECT 
	   [Название_отчета]
      ,[Система]
      ,[Показатель]
      ,[Запрос]
      --,[Период_расчета]
      ,[Тестируемость]
      ,[Порядок]
     FROM [Reports].[dbo].[dm_Jira_List_Report_Query]
	 where [Номер_отчета] = 1
	-- and Система = 'UMFO'
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

Set @url = @report_query + '%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues,created,resolutiondate,priority,status'
	--+ '&fields=issues'

--print @url

if (@Filter2 = 0) 
begin
	Set @url = REPLACE(@url, '(PROD)', '(PROD,UAT,TEST,HF)')
end

if (@Filter2 = 1) 
begin
	Set @url = REPLACE(@url, '(PROD)', '(PROD)')
end

if (@Filter2 = 2) 
begin
	Set @url = REPLACE(@url, '(PROD)', '(UAT,TEST,HF)')
end


	exec [dwh-ex].bot.dbo.[Get_Jira_TotalRow]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT
    --exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

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
	
		
		
		
	
	if(@report_column like '%Всего дефектов%')
	begin
		--set @url = @url+ 
		declare @GuidResult uniqueidentifier
		exec [dwh-ex].bot.dbo.Get_Jira_TaskDetails  @url, @GuidResult out

		insert into dbo.dm_WebData_Jira_Answer
		select 
			@report_name as 'Название отчета'
			, @system_name as 'Система'
			,'Показатель' = priority_name
			--, @report_column as 'Показатель'
			, @report_query as 'Спецальный запрос'
			, @system_tested as 'Тестируемость'
			, @report_query_order as 'Порядок вывода'
			, @OUTSTATUS  as outstatus
			,avg(TotalBusinessDays) as TOTAL
			, @created_at as created_at
			, @system_tested as Tested
			, @url as url_query
		from [dwh-ex].bot.dbo.dm_WebData_Jira_TaskDetails
		where idResult = @GuidResult
		group by priority_name
	end
		--select * from dbo.dm_WebData_Jira_Answer
		--delete from dbo.dm_WebData_Jira_Answer
--считываем следующую строку курсора
        FETCH NEXT FROM my_cur INTO @report_name, @system_name, @report_column, @report_query, @system_tested, @report_query_order
   END
   
   --закрываем курсор
   CLOSE my_cur
   DEALLOCATE my_cur
   --select * from dbo.dm_WebData_Jira_Answer where created_at = @created_at

 select '1' as row_n ,
	Система,  
	[Название отчета], 
	Тестируемость, 
	[Порядок вывода], 
	[Всего дефектов], 
	Подтвержденных, 
	Закрытых 
	,Блокер = isnull([0 - Блокер] ,0)
	,Высокий = isnull([1 - Высокий],0)
	,Средний = isnull([2 - Средний],0)
	,Низкий = isnull([3 - Низкий] ,0)

	from(
 select Система, [Название отчета], Тестируемость, [Порядок вывода], Показатель, 
	cast(total as bigint) as total
 from dbo.dm_WebData_Jira_Answer where created_at = @created_at
 ) t

 pivot (sum(total) for Показатель in ([Всего дефектов],[Подтвержденных],[Закрытых]
,[0 - Блокер]
,[1 - Высокий]
,[2 - Средний]
,[3 - Низкий]
 
 )) as pvt 
 where case when @Filter1 = 0 then '1' else Тестируемость end  = case when @Filter1 = 0 then '1' when @Filter1 = 2 then 'Нет' else 'Да' end
 order by pvt.Подтвержденных desc
 
END

--USE [Reports]
--GO
--/****** Object:  StoredProcedure [dbo].[ReportDashboardJira_Efficiency_OT_Staff]    Script Date: 27.11.2020 15:07:05 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

---- =============================================
---- Author:		Anatoly Kotelevets
---- Create date: 06.11.2020
---- Description:	dwh-813
---- exec dbo.[ReportDashboardJira_Efficiency_OT_Staff]
---- =============================================
CREATE   PROCEDURE [dbo].[ReportDashboardJira_Efficiency_OT_Staff]
--declare 
	 @BeginDate date = '2020-10-01'
	 --(dateadd(qq, datediff(qq, 0, getdate()), 0))
	,@EndDate date  = '2020-12-31'
	
AS
BEGIN
	

	SET NOCOUNT ON;
	
  
	--order by [Порядок]
  
   Declare @project NVARCHAR(1000)
		 , @report_column NVARCHAR(1000)
		 , @system_name NVARCHAR(1000)
		 , @report_name NVARCHAR(1000) = 'Метрики эффективности сотрудников ОТ'
		 , @report_query NVARCHAR(1000)
		 , @report_period NVARCHAR(1000)
		 , @report_userDisplayName NVARCHAR(1000)
		 , @report_userDomainAccount NVARCHAR(1000)
		 
		 

		 
-- определим начало и конец недели
 declare @rowcount bigint = 0
	   , @created_at datetime2  = getdate() -- дата формирования
	   , @url_project NVARCHAR(1000)
	   , @project_column NVARCHAR(1000)

declare 
      @url VARCHAR(MAX)
	, @OUTSTATUS VARCHAR(1000) 
    , @TOTAL VARCHAR(40)  = '0'
	, @OUTCREATED datetime2 
	, @url_api VARCHAR(MAX) = N'https://jira.carmoney.ru/rest/api/2/'
	

--Сипоск сотрудников на 26-11-2020
/*
Жидков Александр Юрьевич
Волченков Кирилл Александрович
Бичевая Ксения Ивановна
Савин Геннадий Александрович
Полякова Елизавета Александровна
Пакина Елена Юрьевна
Прибылов Кирилл
Киселёв Александр Владимирович
*/
set @BeginDate=isnull(@BeginDate, dateadd(dd,-10, getdate()))

set @EndDate = isnull(@EndDate, getdate())


if object_id('tempdb..#t_result') is not null
	drop table #t_result 
create table  #t_result 
	(
	 Сотрудник nvarchar(1000),
	 Система nvarchar(1000),
	 Показатель nvarchar(1000),
	 [TotalRows] decimal(12,2),
	 [Спецальный запрос] nvarchar(1000),
	 url_query nvarchar(max)

	)

declare @users table (DisplayName VARCHAR(1000) , DomainAccount VARCHAR(1000) )
insert into @users

select LastName + ISNULL(' '+ SUBSTRING(FirstName, 1,1) + '.', '') as DisplayName, 
	DomainAccount
from 
(
	select LastName,
		FirstName,
		DisplayName,
		DomainAccount,
		Mail  from [dwh-ex].bot.dbo.vw_ActiveDirectoryUsers
	where Department ='Отдел тестирования'
	union
	select LastName,
		FirstName,
		DisplayName,
		DomainAccount,
		Mail
		from [dwh-ex].bot.dbo.vw_ActiveDirectoryUsers
	where DomainAccount = 'D.Akunc'


) t

if OBJECT_ID('tempdb..#t') is not null	
drop table  #t
	SELECT 
      [Система]
      ,[Показатель]
      ,[Запрос]
      ,[Период_расчета]
	 , s.DisplayName
	 , s.DomainAccount
  into #t
     FROM [dbo].[dm_Jira_List_Report_Query] t
	 left join @users s 
		on t.[Запрос] like '%{user}%'
	 where [Название_отчета] = 'Метрики эффективности сотрудников ОТ'--@report_name
	
	 and (
			   (s.DisplayName like '%Жидков А%'		and [Система] IN('FEDOR'))
			OR (s.DisplayName like '%Волченков К%'	and [Система] IN('EDO', 'UMFO'))
			OR (s.DisplayName like '%Акунц Д%'	and [Система] IN('EDO', 'UMFO'))
			OR (s.DisplayName like '%Бичевая К%'	and [Система] IN('"Mobile "'))
			OR (s.DisplayName like '%Прибылов К%'	and [Система] IN('CRM'))
			OR (s.DisplayName like '%Полякова Е%'	and [Система] IN('LKP2'))
			OR (s.DisplayName like '%Киселёв А%'	and [Система] IN('CMR', 'MFO'))
		OR DisplayName iS NULL
		)

	 order by [Порядок]
	 
 DECLARE my_cur CURSOR FOR  select * from #t
     

   OPEN my_cur
   --считываем данные первой строки в наши переменные
   FETCH NEXT FROM my_cur INTO
		@system_name, 
		@report_column, 
		@report_query, 
		@report_period,
		@report_userDisplayName,
		@report_userDomainAccount
	
   
   WHILE @@FETCH_STATUS = 0
   BEGIN

   -- формируем запросы
Set @project = @system_name
Set @project_column = @report_column

set @report_query = '?jql=' + @report_query
if CHARINDEX('{projectName}', @report_query) >0 and nullif(@project, '') is not null
	set @report_query =REPLACE(@report_query, '{projectName}', @project)
if charindex('{user}',@report_query) >0 and nullif(@report_userDomainAccount,'') is not null
	set @report_query =REPLACE(@report_query, '{user}', @report_userDomainAccount)


	
--'created >= {dateBegin} AND created <= {dateEnd}
if nullif(@report_period,'') is not null 
	and @BeginDate  is not null 
	and @EndDate is not null
begin

	if CHARINDEX('{dateBegin}', @report_period) >0
		set @report_period = REPLACE(@report_period, '{dateBegin}', format(@BeginDate,'yyyy-MM-dd') )
	if CHARINDEX('{dateEnd}', @report_period) >0  
		set @report_period = REPLACE(@report_period, '{dateEnd}', format(@EndDate,'yyyy-MM-dd') )
	set @report_query += ISNULL(' ' + @report_period, '')
end



 set @url = @url_api + 'search'
declare @url_query nvarchar(1024) =  @url + dbo.[UrlEncode](@report_query)
print @url_query

begin try
    exec [dwh-ex].bot.dbo.[Get_Jira_TotalRow]  
			@url_query, 
			@OUTSTATUS OUTPUT, 
			@TOTAL OUTPUT, 
			@OUTCREATED OUTPUT
	    insert into #t_result(Сотрудник, Система, Показатель, [TotalRows], [Спецальный запрос], url_query)
		select 
		 @report_userDisplayName as Сотрудник
		, @system_name as 'Система'
		, @report_column as 'Показатель'
		, cast(@TOTAL as decimal(12,2)) as TOTAL
		, @report_query as 'Спецальный запрос'
		, @url_query
		


end try
begin catch
	select @url_query, @@ERROR, @OUTSTATUS
end catch
		 
      FETCH NEXT FROM my_cur INTO
		@system_name, 
		@report_column, 
		@report_query, 
		@report_period,
		@report_userDisplayName,
		@report_userDomainAccount
   END
   
   --закрываем курсор
   CLOSE my_cur
   DEALLOCATE my_cur

/*
   Найденные дефекты на этапе тестирования, %

   
 */
 
 select 
 
	Сотрудник = max(Сотрудник) ,
	Система,  
--
	[Найденные дефекты на этапе тестирования] = ISNULL(SUM([Дефекты TEST]) / NULLIF(SUM([Дефекты All]),0),0),
	SUM([Дефекты TEST]) as [Дефекты TEST]  , 
	SUM([Дефекты All]) as [Дефекты All] , 
	SUM([Кол-во пропущенных блокирующих дефектов]) as [Кол-во пропущенных блокирующих дефектов],
	[Отклоненные дефекты] = ISNULL(SUM([кол-во отклоненных]) / NULLIF(SUM([кол-во заведенных]),0),0) ,
	SUM([кол-во отклоненных]) [кол-во отклоненных], 
	SUM([кол-во заведенных]) [кол-во заведенных]
	
	

 from #t_result  t
 pivot (sum(totalRows) for Показатель in ([Дефекты All], [Дефекты TEST], [кол-во заведенных], [кол-во отклоненных], [Кол-во пропущенных блокирующих дефектов])) pvt

 group by  Система
 Order by Сотрудник, Система 
 /*
 select * from #t_result
 where Система = 'MP'
 */

END

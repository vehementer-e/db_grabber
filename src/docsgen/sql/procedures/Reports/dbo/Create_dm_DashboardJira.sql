
-- =============================================
-- Author:		Anton Sabanin
-- Create date: 06.11.2020
-- Description:	dwh-757
-- exec [dbo].[Create_dm_DashboardJira]
-- =============================================
CREATE   PROCEDURE [dbo].[Create_dm_DashboardJira]
	
AS
BEGIN
	

	SET NOCOUNT ON;

-- определим начало и конец недели
 declare @rowcount bigint = 0
	   , @created_at datetime2  = getdate() -- дата формирования
	   , @b_week date
	   , @e_week date
	   , @url_project NVARCHAR(1000)
	   , @project NVARCHAR(1000)
	   , @project_column NVARCHAR(1000)

declare 
      @url VARCHAR(MAX)
	, @OUTSTATUS VARCHAR(1000) 
    , @TOTAL VARCHAR(40) 
	, @OUTCREATED datetime2 

--set @OUTCREATED = @created_at

-- первый день недели
SET datefirst 1
Set @b_week = dateadd(dd,-datepart(dw,DATEFROMPARTS(year(@created_at),1,1))-6+datepart(iso_week,@created_at)*7,DATEFROMPARTS(year(@created_at),1,1)) 
Set @e_week = dateadd(dd,-datepart(dw,DATEFROMPARTS(year(@created_at),1,1))+datepart(iso_week,@created_at)*7,DATEFROMPARTS(year(@created_at),1,1)) 

--select @b_week   , @e_week 

---===================== CMR =============================
-- формируем запросы
Set @project = N'CMR'
Set @project_column = N'Всего дефектов'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20CMR%20%20AND%20issuetype%20%20in%20(Defect,%20%22Defect%20(Sub-Task)%22)%20AND%20%D0%A1%D1%82%D0%B5%D0%BD%D0%B4%20in%20(PROD)%20AND%20%22%D0%A2%D0%B8%D0%BF%20%D0%B4%D0%B5%D1%84%D0%B5%D0%BA%D1%82%D0%B0%22%20=%20%D0%A4%D1%83%D0%BD%D0%BA%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query
		--into dbo.dm_WebData_Jira

		-- формируем запросы
Set @project = N'CMR'
Set @project_column = N'Подтвержденных'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20CMR%20%20AND%20issuetype%20%20in%20(Defect,%20%22Defect%20(Sub-Task)%22)%20AND%20%D0%A1%D1%82%D0%B5%D0%BD%D0%B4%20in%20(PROD)%20AND%20%22%D0%A2%D0%B8%D0%BF%20%D0%B4%D0%B5%D1%84%D0%B5%D0%BA%D1%82%D0%B0%22%20=%20%D0%A4%D1%83%D0%BD%D0%BA%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20AND%20status%20not%20in%20(%D0%9E%D1%82%D0%BA%D0%BB%D0%BE%D0%BD%D1%91%D0%BD)%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query

-- формируем запросы
Set @project = N'CMR'
Set @project_column = N'Закрытых'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20CMR%20%20AND%20issuetype%20%20in%20(Defect,%20%22Defect%20(Sub-Task)%22)%20AND%20%D0%A1%D1%82%D0%B5%D0%BD%D0%B4%20in%20(PROD)%20AND%20%22%D0%A2%D0%B8%D0%BF%20%D0%B4%D0%B5%D1%84%D0%B5%D0%BA%D1%82%D0%B0%22%20=%20%D0%A4%D1%83%D0%BD%D0%BA%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20AND%20status%20in%20(Closed)%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query

---===================== CRM =============================
-- формируем запросы
Set @project = N'CRM'
Set @project_column = N'Всего дефектов'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20CRM%20%20AND%20issuetype%20%20in%20(Defect,%20%22Defect%20(Sub-Task)%22)%20AND%20%D0%A1%D1%82%D0%B5%D0%BD%D0%B4%20in%20(PROD)%20AND%20%22%D0%A2%D0%B8%D0%BF%20%D0%B4%D0%B5%D1%84%D0%B5%D0%BA%D1%82%D0%B0%22%20=%20%D0%A4%D1%83%D0%BD%D0%BA%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query
		--into dbo.dm_WebData_Jira

		-- формируем запросы
Set @project = N'CRM'
Set @project_column = N'Подтвержденных'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20CRM%20%20AND%20issuetype%20%20in%20(Defect,%20%22Defect%20(Sub-Task)%22)%20AND%20%D0%A1%D1%82%D0%B5%D0%BD%D0%B4%20in%20(PROD)%20AND%20%22%D0%A2%D0%B8%D0%BF%20%D0%B4%D0%B5%D1%84%D0%B5%D0%BA%D1%82%D0%B0%22%20=%20%D0%A4%D1%83%D0%BD%D0%BA%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20AND%20status%20not%20in%20(%D0%9E%D1%82%D0%BA%D0%BB%D0%BE%D0%BD%D1%91%D0%BD)%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query

-- формируем запросы
Set @project = N'CRM'
Set @project_column = N'Закрытых'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20CRM%20%20AND%20issuetype%20%20in%20(Defect,%20%22Defect%20(Sub-Task)%22)%20AND%20%D0%A1%D1%82%D0%B5%D0%BD%D0%B4%20in%20(PROD)%20AND%20%22%D0%A2%D0%B8%D0%BF%20%D0%B4%D0%B5%D1%84%D0%B5%D0%BA%D1%82%D0%B0%22%20=%20%D0%A4%D1%83%D0%BD%D0%BA%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20AND%20status%20in%20(Closed)%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query

		
---===================== DWH =============================
-- формируем запросы
Set @project = N'DWH'
Set @project_column = N'Всего дефектов'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20DWH%20AND%20created%20>=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query
		--into dbo.dm_WebData_Jira

		-- формируем запросы
Set @project = N'DWH'
Set @project_column = N'Подтвержденных'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20DWH%20AND%20created%20>=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query

-- формируем запросы
Set @project = N'DWH'
Set @project_column = N'Закрытых'
Set @url = 'https://jira.carmoney.ru/rest/api/2/search?jql=project%20=%20DWH%20and%20status%20in%20(closed,%20done,%20resolved)%20AND%20created%20%3E=%20' + format(@b_week,'yyyy-MM-dd') + '%20AND%20created%20%3C=%20' + format(@e_week,'yyyy-MM-dd') + '&fields=issues'



    exec [dwh-ex].bot.dbo.[Get_Jira_URL]  @url, @OUTSTATUS OUTPUT, @TOTAL OUTPUT, @OUTCREATED OUTPUT

	--select  @OUTSTATUS  , @TOTAL 

	insert into dbo.dm_WebData_Jira
		select @project as 'Система', @project_column as project_column, @OUTSTATUS  as outstatus, @TOTAL as TOTAL,@created_at as created_at, 'Да' as Tested, @url as url_query


		--select * from dbo.dm_WebData_Jira where @created_at = created_at

select Система, [Всего дефектов], Подтвержденных, Закрытых from(
select Система, project_column, cast(total as bigint) as total
 from dbo.dm_WebData_Jira where created_at = @created_at
 ) t
 pivot (sum(total) for project_column in ([Всего дефектов],[Подтвержденных],[Закрытых])) as pvt

END

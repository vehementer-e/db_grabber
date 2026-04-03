
CREATE   PROC dbo.ReportsAndPermissions
	@ParentCatalog_list varchar(4000), -- Список родительских каталогов
	@ReportName nvarchar(1000) = NULL, -- строка для поиска по названию отчета - поле пустое(null), и работает по принципу like
	@PermissionGroup nvarchar(200) = NULL -- строка для поиска по группе доступа к отчету  - поле пустое(null), и работает по принципу like
--	@isDebug int = 0
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY
	--SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @ProcessGUID varchar(36) = NULL -- guid процесса
	DECLARE @eventType nvarchar(1024), @eventName nvarchar(1024)
	DECLARE @description nvarchar(1024), @message nvarchar(1024)
	DECLARE @url nvarchar(1000) = 'https://birs.carmoney.ru/reports/report'
	DECLARE @t_ParentCatalog table(ParentCatalog varchar(200) COLLATE Latin1_General_100_CI_AS_KS_WS)

	INSERT @t_ParentCatalog(ParentCatalog)
	select value COLLATE Latin1_General_100_CI_AS_KS_WS
	from string_split(@ParentCatalog_list,',')

	SELECT @ReportName = isnull(@ReportName, '')
	SELECT @PermissionGroup = isnull(@PermissionGroup, '')

	--SELECT @isDebug = isnull(@isDebug, 0)

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @eventType = 'info', @eventName = 'Reports.dbo.ReportsAndPermissions'

	DROP TABLE IF EXISTS #t_ReportsAndPermissions

	;with cte_Permissions as (
		--select u.UserName		as UserName
		--		,r.RoleName		as RoleName
		--		,pur.PolicyID
		--from [C2-VSR-BIRS].ReportServer.dbo.PolicyUserRole pur
		--join [C2-VSR-BIRS].ReportServer.dbo.Users u on u.UserID = pur.UserID
		--join [C2-VSR-BIRS].ReportServer.dbo.Roles r on r.RoleID = pur.RoleID

		--where 1=1
		----and RoleName= 'Browser'
		----and UserName like '%UG%'
		----and u.UserName not like '%develop%' 

		select 
			pur.PolicyID
			,u.UserName
			--,r.RoleName
			,string_agg(r.RoleName,', ') WITHIN GROUP (ORDER BY r.RoleName) as RoleName
		from [C2-VSR-BIRS].ReportServer.dbo.PolicyUserRole pur
			join [C2-VSR-BIRS].ReportServer.dbo.Users u on u.UserID = pur.UserID
			join [C2-VSR-BIRS].ReportServer.dbo.Roles r on r.RoleID = pur.RoleID
		where 1=1
			AND u.UserName NOT IN ('BUILTIN\Administrators')
		GROUP BY pur.PolicyID, u.UserName

	)
	, cte_Reports as (
	select   c.ItemID			AS 'guid отчета'
			,c.name				as 'Название отчета'
			,c.path				as 'Путь к отчету'
			,c2.name			as 'Каталог в котором он размещен'
			,st_spl.value		as 'Родительский каталог'
			,c.Type				as 'Тип отчета'
			,c.Description		AS 'Описание отчета'
			,c.CreationDate		AS 'Дата создания отчета'
			,u.UserName			AS 'Кто создал отчет'
			,cte_P.UserName     as 'Пользователь/группа'
			--,concat(cte_P.UserName, '(', cte_P.RoleName, ')') as 'Пользователь/группа'
			,cte_P.RoleName		AS 'Роль'
	from [C2-VSR-BIRS].ReportServer.dbo.[Catalog] AS c
		OUTER apply (select value 
				 from (select value
							, ROW_NUMBER() over (order by getdate() asc) as Nrow 
					   from string_split(c.Path,'/'))s
				 where Nrow = 2) AS st_spl 
		LEFT JOIN [C2-VSR-BIRS].ReportServer.dbo.[Catalog] AS c2
			ON c.ParentID = c2.ItemID
		LEFT JOIN cte_Permissions AS cte_P 
			ON cte_P.PolicyID = c.PolicyID 
			--and CHARINDEX(st_spl.value, cte_P.UserName)>0
		LEFT JOIN [C2-VSR-BIRS].ReportServer.dbo.Users AS u
			ON u.UserID = c.CreatedByID

	where 1=1
		AND c2.name	not in ('Data Sources', 'DevDepartment', 'Удаленные отчеты')
		AND nullif(c2.name,'') is not null
		AND c.Type not in (1)
		AND isnull(cte_P.UserName, '') not in ('CM\cmroot4', 'CM\cmroot9')
		--
		AND st_spl.value IN (SELECT T.ParentCatalog FROM @t_ParentCatalog AS T)
		AND c.Name LIKE '%'+@ReportName+'%'
		AND cte_P.UserName LIKE '%'+@PermissionGroup+'%'

		--test
		--AND c.ItemID = 'F8ED62B6-81F0-4A41-9CC3-62B06778DE83'
	)
	select 
		R.[guid отчета]
		,R.[Родительский каталог]
		,R.[Каталог в котором он размещен]
		,R.[Название отчета]
		,R.[Описание отчета]
		,R.[Путь к отчету]
		,case when R.[Тип отчета]	= 2 then 'SSRS'
			  when R.[Тип отчета]	=13 then 'PowerBI'
			  when R.[Тип отчета]	=14 then 'Excel'
			  else cast(R.[Тип отчета] AS varchar(50))
		 end as [Тип отчета]
		 --,WebUrl = concat(@url, R.[Путь к отчету])  ---  cast('' AS nvarchar(1024))
		 --,WebUrl = concat('<a href=''', @url, R.[Путь к отчету], '>', @url, R.[Путь к отчету], '</a>')
		 ,WebUrl = concat(@url, R.[Путь к отчету])
		 ,R.[Дата создания отчета]
		 ,R.[Кто создал отчет]
		--,[Основная группа] = case
		--	when 
		--		else null
		--	end 
		--,STRING_AGG(R.[Пользователь/группа],' ; ') as [Пользователь/группа]
		,R.[Пользователь/группа]
		,R.Роль
	INTO #t_ReportsAndPermissions
	from cte_Reports AS R
	group by 
		R.[guid отчета]
		,R.[Родительский каталог]
		,R.[Каталог в котором он размещен]
		,R.[Название отчета]
		,R.[Описание отчета]
		,R.[Путь к отчету]
		,R.[Тип отчета]
		,R.[Дата создания отчета]
		,R.[Кто создал отчет]
		,R.[Пользователь/группа]
		,R.Роль

	--IF @isDebug = 1 BEGIN
	--	DROP TABLE IF EXISTS ##t_ReportsAndPermissions
	--	SELECT * INTO ##t_ReportsAndPermissions FROM #t_ReportsAndPermissions
	--END


	SELECT 
		R.[guid отчета],
		R.[Родительский каталог],
		R.[Каталог в котором он размещен],
		R.[Название отчета],
		R.[Описание отчета],
		R.[Путь к отчету],
		R.[Тип отчета],
		R.WebUrl,
		R.[Дата создания отчета],
		R.[Кто создал отчет],
		R.[Пользователь/группа],
		R.Роль
	FROM #t_ReportsAndPermissions AS R
	ORDER BY 
		R.[Родительский каталог],
		R.[Каталог в котором он размещен],
		R.[Название отчета]

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')+char(13)+char(10)
		+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = 'EXEC dbo.ReportsAndPermissions'

	SELECT @eventType = 'error'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName ,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH

END





CREATE procedure [dbo].[create_dm_feodor_projects]
as
begin

--	drop table if exists #t1, #t2
--
--	  SELECT [Name] = [Name] collate  Cyrillic_General_CI_AS
--	  ,      [IdExternal]= [IdExternal]  collate  Cyrillic_General_CI_AS
--	  ,      [Id]= [Id]
--	  ,      [IsDeleted]= [IsDeleted] 
--	  ,      [SortOrder]= [SortOrder] 
--	  --	into #t1
--	   FROM [PRODSQL02].[Fedor.Core].[dictionary].[CallProject]
--	  where idexternal not in (
--	  'corebo00000000000mrv5f0vg30o4al4', -- входящая линия
--	  'corebo00000000000nbchkar1njd70ms' -- Пилот МТС Маркетолог
--
--	  )
--	----SELECT TOP (1000000) [ID]
--	----    ,[UF_LCRM_ID]
--	----    ,[UF_TYPE]
--	----    ,[UF_UPDATED_AT]
--	----FROM [Stg].[_LCRM].[carmoney_light_crm_launch_control]
--
----	 
----select *   from OPENQUERY(LCRM,'select c1.*      
----from  b_user_field_enum c1               
----join  (select id from b_user_field_enum   c2    
----where  c2.id> ''230''                               
----order by c2.id                         
----limit 100000) c2                    
----on c2.id=c1.id             
----')
----select * from #t1
--
--
--
--	/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
----SELECT TOP (1000) [ID]
----      ,[USER_FIELD_ID]
----      ,[VALUE]
----      ,[DEF]
----      ,[SORT]
----      ,[XML_ID]
----  FROM [Stg].[_LCRM].[b_user_field_enum]
----  order by 1 desc
----
--	select [Name]                                                                        
--	,      [IdExternal]                                                                  
--	,      [Id]                                                                          
--	,      [IsDeleted]                                                                   
--	,      [SortOrder]                                                                   
--	,      case when [Name] = N'Fedor TLS'                     then 'FEDOR TLS'
--	            when [Name] = N'Fedor Автоинформатор лидген'   then 'Fedor IVR'
--	            when [Name] = N'Триггеры'                      then 'FEDOR TRIGGERS'
--	            when [Name] = N'Пилот'                         then 'FEDOR PILOT'
--	            when [Name] = N'25%'                           then 'Отп. FEDOR PILOT 25'
--	            when [Name] = N'Fedor Автоинформатор лидген 2' then 'Fedor IVR 2Q'
--	            when [Name] = N'Целевой'                       then 'Отп. FEDOR TLS TOP'
--	            when [Name] = N'Пилот 2'                       then 'FEDOR PILOT 2' 
--	            when [Name] = N'РобоIVR Пилот'                       then 'Отп. FEDOR ROBO IVR' 
--	            when [Name] = N'Пилот QPM'                       then 'Отп. FEDOR PILOT QPM' 
--	            when [Name] = N'Sales ОКБ'                       then 'Отп. FEDOR PILOT SALES OKB' 
--	            when [Name] = N'Fedor Рефинансирование'                       then 'Отп. FEDOR REFINANCE IVR' 
--	            when [Name] = N'Fedor TLS МП Повторные'                       then 'Отп. FEDOR TLS МП повторные' 
--	            when [Name] = N'Fedor TLS МП Новые'                       then 'Отп. FEDOR TLS МП новые' 
--	            when [Name] = N'CPC'                       then 'Отп. FEDOR TLS CPC' 
--	            when [Name] = N'Элекснет'                       then 'Отп. ELEXTEN TERMINAL IVR' 
--	            when [Name] = N'IVR МФО'                       then 'Отп. МФО IVR' 
--	            when [Name] = N'Целевой перезвоны'                       then 'Отп. FEDOR TLS TOP' 
--	            when [Name] = N'СРС перезвоны'                       then 'Отп. FEDOR TLS CPC' 
--	            when [Name] = N'Лиды Installment'                       then 'Отп. FEDOR INSTALLMENT' 
--	
----	Отп. FEDOR PILOT QPM
----Отп. FEDOR ROBO IVR
--				
--				end as LaunchControlName
--
--	,      case when [Name] = N'Fedor TLS'                     then 217
--	            when [Name] = N'Fedor Автоинформатор лидген'   then 216
--	            when [Name] = N'Триггеры'                      then 218
--	            when [Name] = N'Пилот'                         then 219
--	            when [Name] = N'25%'                           then 222
--	            when [Name] = N'Fedor Автоинформатор лидген 2' then 223
--	            when [Name] = N'Целевой'                       then 224
--	            when [Name] = N'Пилот 2'                       then 225 
--	            when [Name] = N'РобоIVR Пилот'                       then 226
--	            when [Name] = N'Пилот QPM'                       then 227 
--	            when [Name] = N'Sales ОКБ'                       then 228
--	            when [Name] = N'Fedor Рефинансирование'                       then 229
--	            when [Name] = N'Fedor TLS МП Повторные'                       then 233
--	            when [Name] = N'Fedor TLS МП Новые'                       then 232
--	            when [Name] = N'CPC'                       then 234
--	            when [Name] = N'Элекснет'                       then 230
--	            when [Name] = N'IVR МФО'                       then 235
--	            when [Name] = N'Целевой перезвоны'                       then 224
--	            when [Name] = N'СРС перезвоны'                       then 234
--	            when [Name] = N'Лиды Installment'                       then 237
--
--
--
--					
--				end               as LaunchControlID
--	,      case when [Name] = N'Fedor TLS'                     then 0
--	            when [Name] = N'Fedor Автоинформатор лидген'   then 0
--	            when [Name] = N'Триггеры'                      then 0
--	            when [Name] = N'Пилот'                         then 0
--	            when [Name] = N'25%'                           then 0
--	            when [Name] = N'Fedor Автоинформатор лидген 2' then 0
--	            when [Name] = N'Целевой'                       then 0
--	            when [Name] = N'Пилот 2'                       then 0 
--	            when [Name] = N'РобоIVR Пилот'                       then 0
--	            when [Name] = N'Пилот QPM'                       then 0 
--	            when [Name] = N'Sales ОКБ'                       then 0
--	            when [Name] = N'Fedor Рефинансирование'                       then 0
--	            when [Name] = N'Fedor TLS МП Повторные'                       then 0
--	            when [Name] = N'Fedor TLS МП Новые'                       then 0
--	            when [Name] = N'CPC'                       then 0
--	            when [Name] = N'Элекснет'                       then 0
--	            when [Name] = N'IVR МФО'                       then 0
--	            when [Name] = N'Целевой перезвоны'                       then 1
--	            when [Name] = N'СРС перезвоны'                       then 1
--	            when [Name] = N'Лиды Installment'                       then 0
--
--
--
--					
--				end               as RecallProject
--		into #t2
--	from #t1
--
--	--select Name
--	--,      IdExternal
--	--,      Id
--	--,      IsDeleted
--	--,      SortOrder
--	--,      LaunchControlName
--	--,      LaunchControlID
--	--,      RecallProject from #t2 except
--	--select Name
--	--,      IdExternal
--	--,      Id
--	--,      IsDeleted
--	--,      SortOrder
--	--,      LaunchControlName
--	--,      LaunchControlID
--	--,      RecallProject from feodor.dbo.dm_feodor_projects
--	
--
--	--begin tran
--	--drop table if exists feodor.dbo.dm_feodor_projects
--	--select *, getdate() as created into feodor.dbo.dm_feodor_projects from #t2
--	--commit tran

drop table if exists #t2

SELECT    [Name]              = [Name]
      ,   [new_Name]        = [new_Name]
      ,   [IdExternal]        = [project_id]
      ,   [Id]                = [Code]
      ,   [IsDeleted]         =  0
      ,   [SortOrder]         =  0
      ,   [LaunchControlName] = [Launch_control_name]
      ,   [LaunchControlID]   = [Launch_control_id]
      ,   [RecallProject]     = [is_recall_project]
      ,   rn_IdExternal    = cast([rn_project_id] as int)--1
	  ,   created
	  into #t2
  FROM [Stg].[files].[naumenprojects_stg]
  --FROM ##t11
  where [is_feodor_tls]=1

  --select * from #t2


  
--DECLARE @ReturnCode int, @ReturnMessage varchar(8000)
--EXEC Stg.dbo.ExecLoadExcel
--	@PathName = '\\10.196.41.14\DWHFiles\NaumenProjects\',
--	@FileName = 'NaumenProjects.xlsx',
--	@SheetName = 'NaumenProjects$',
--	@TableName = '##t11', --'files.TestFile1',
--	@isMoveFile = 0,
--	@ReturnCode = @ReturnCode OUTPUT,
--	@ReturnMessage = @ReturnMessage OUTPUT
--SELECT 'ReturnCode' = @ReturnCode, 'ReturnMessage' = @ReturnMessage
--select * from ##t11




 -- select *   from OPENQUERY(LCRM,'select c1.*      
 -- from  b_user_field_enum c1               
 -- join  (select id from b_user_field_enum   c2    
 -- where  c2.id> ''210''                               
 -- order by c2.id                         
 -- limit 100000) c2                    
 -- on c2.id=c1.id             
 -- ')

--  select Name
--	,      IdExternal
--	,      Id
--	,      IsDeleted
--	,      SortOrder
--	,      LaunchControlName
--	,      LaunchControlID
--	,      RecallProject from #t2
--  
--  except
--  select Name
--	,      IdExternal
--	,      Id
--	,      IsDeleted
--	,      SortOrder
--	,      LaunchControlName
--	,      LaunchControlID
--	,      RecallProject from feodor.dbo.dm_feodor_projects
  --select *  FROM [PRODSQL02].[Fedor.Core].[dictionary].[CallProject]


 --select *  from feodor.dbo.dm_feodor_projects
 --select *  from #t2

	begin tran

	--drop table if exists feodor.dbo.dm_feodor_projects
	--select * into feodor.dbo.dm_feodor_projects from #t2

	delete from feodor.dbo.dm_feodor_projects where id in (select id from #t2)
	insert into feodor.dbo.dm_feodor_projects
	select * from #t2

	commit tran

	--select * from feodor.dbo.dm_feodor_projects

	--alter table feodor.dbo.dm_feodor_projects
	--drop column [is_recall_project]-- int  null
	
	--alter table feodor.dbo.dm_feodor_projects
	--add rn_IdExternal int  null

end


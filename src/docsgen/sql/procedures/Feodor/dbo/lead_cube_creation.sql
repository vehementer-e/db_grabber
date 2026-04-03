CREATE proc [dbo].[lead_cube_creation] @mode nvarchar(max) = 'update'
as 
begin

if @mode = 'get_date' 
begin
 

declare @start datetime = (select max(created) from Analytics.	 [dbo].jobh where command like '%lead%'	  and job_name='Analytics._etl_lead each 10 min at 6:00' and run_status='Succeeded')


 drop table if exists #days_to_Update1
select  cast(uf_registered_at as date) date into #days_to_Update1
from   feodor.dbo.[lead] with(nolock)
where  row_updated >=@start
	group by  cast(uf_registered_at as date)

	insert into  lead_cube_days_to_update
	select 	date, getdate() from 	#days_to_Update1 a
	left join  lead_cube_days_to_update b on a.date=b.[ДатаЛидаЛСРМ для обновления]
	where b. [ДатаЛидаЛСРМ для обновления] is null


	--select * from lead_cube_days_to_update
end



if @mode = 'update' 
begin


--exec [lead_cube_creation] 'get_date' 



drop table if exists #days_to_Update
select distinct  top 5  [ДатаЛидаЛСРМ для обновления] [ДатаЛидаЛСРМ для обновления] into #days_to_Update
from   feodor.dbo.[lead_cube_days_to_update]	
--select * from   feodor.dbo.[lead_cube_days_to_update]	
--union
--select getdate()								
--union
--select getdate()-1
--select * from   feodor.dbo.[lead_cube_days_to_update]		
--select * from   #days_to_Update
order by 1 desc


 
begin tran
DECLARE @Result_0 INT;
EXEC @Result_0 = sp_getapplock @Resource = 'MergeLock', @LockMode = 'Exclusive'--, @LockTimeout = 300000; -- 5 минут

IF @Result_0 >= 0
BEGIN
BEGIN TRY


drop table if exists #lead_cube
select --top 100
       cast(l.uf_registered_at as date) [ДатаЛидаЛСРМ]
      ,[UF_TYPE]
      ,uf_source
	  ,[UF_LOGINOM_PRIORITY]
	  ,[UF_LOGINOM_STATUS] 
	  ,[Канал от источника]
	  ,cast(null as nvarchar(36)) [ЛогинПоследнегоСотрудника]
      ,[Группа каналов]
      ,[CompanyNaumen]
	  ,count(id) ID
	  ,count(case when [CompanyNaumen]='Полная заявка' then getdate() else [creationdate] end) [creationdate]
	  ,count(case when [CompanyNaumen]='Полная заявка' then getdate() else ВремяПервойПопытки end) ВремяПервойПопытки
	  ,sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ЧислоПопыток]               end)    [ЧислоПопыток]
	  ,[ФлагРазблокированнаяСессия] = cast(null as int)-- sum(case when [CompanyNaumen]='Полная заявка' then  1 else [ФлагРазблокированнаяСессия] end) [ФлагРазблокированнаяСессия]
	  ,[ФлагДозвонПоЛиду]=   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then  1 else [ФлагДозвонПоЛиду]           end)   [ФлагДозвонПоЛиду]
	  ,[ФлагНедозвонПоЛиду]=   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагНедозвонПоЛиду]         end) [ФлагНедозвонПоЛиду]
	  ,[ПерезвонПоПоследнемуЗвонку]=   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then null else [ПерезвонПоПоследнемуЗвонку] end) [ПерезвонПоПоследнемуЗвонку]
	  ,[ФлагНепрофильный]=   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагНепрофильный]           end) [ФлагНепрофильный]
      ,[ФлагНовый]=   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагНовый]                  end) [ФлагНовый]
	  ,   sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ФлагПрофильныйИтог]         end) [ФлагПрофильныйИтог]
	  ,[ФлагПрофильный] =   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ФлагПрофильный]             end)    [ФлагПрофильный]
	  ,[ФлагОтправленВМП] =   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагОтправленВМП]           end) [ФлагОтправленВМП]
      ,[ФлагОтказКлиента] =   cast(null as int)--sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагОтказКлиента]           end) [ФлагОтказКлиента]
      ,[ФлагДумает] =  null--sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагДумает]                 end) [ФлагДумает]
      ,sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ФлагЗаявка]                 end) [ФлагЗаявка]
	  ,count([ПредварительноеОдобрение]                        ) [ПредварительноеОдобрение]
	  ,count([КонтрольДанных]) [КонтрольДанных]
	  ,count([Одобрено]) [Одобрено]
      ,count([ЗаемВыдан]) [ЗаемВыдан]
      ,sum([ВыданнаяСумма]) [ВыданнаяСумма]
	  , cast(null as bigint) /*sum(cast(datediff(minute, creationdate, [ВремяПервойПопытки]) as bigint))*/ DateDiff$creationdate$ВремяПервойПопытки
	  ,cast(null as bigint) DateDiff$uf_registered_at$QueueDecision
	  ,sum(cast(datediff(minute, [UF_REGISTERED_AT], creationdate) as bigint)) DateDiff$uf_registered_at$creationdate
	  ,count(case when cast([creationdate] as date) = cast([ВремяПервойПопытки] as date) or ( [Удален из обзвона]=1) then [creationdate] end) [creationdate_day_in_day]
	  ,count(case when cast([creationdate] as date) = cast([ВремяПервойПопытки] as date) then [creationdate] end) [ВремяПервойПопытки_day_in_day]
	  ,count(case when [ВремяПервойПопытки] <= dateadd(second, 120, creationdate) then [creationdate] end) [ВремяПервойПопытки_0min_to_2min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 120, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 300 , creationdate) then [creationdate] end) [ВремяПервойПопытки_2min_to_5min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 300, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 1800, creationdate) then [creationdate] end) [ВремяПервойПопытки_5min_to_30min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 1800, creationdate) then [creationdate] end) [ВремяПервойПопытки_30min_and_more]
	  ,try_cast( null as nvarchar(20)) /*login*/ as login
	  ,cast(creationdate as date) [creationdate день]
	  ,[is_inst_lead]
	  ,IsInstallment
	  ,[UF_PARTNER_ID аналитический]
	  ,[ПричинаНепрофильности]
	  ,case when ВремяПервогоДозвона is not null then 1 else 0 end [ФлагДозвонПоЛиду 1/0]
	  ,case when [ФлагЗаявка]=1 then 1 else 0 end [ФлагЗаявка 1/0]
	  ,[СтатусЛидаФедор]
	  ,case when [ФлагПрофильныйИтог] =1 then 1 else 0 end [Флаг профильный итог 1/0]
	  , IsPdl
	  ,[IsPts возврат]  
	  ,[UF_STAT_CAMPAIGN]
	  , is_work_time
	 ,entrypoint
	 ,credit_type
	 , case when ВремяПервойПопытки is not null then 1 else 0 end has_call --has_attempt
		 ,UF_LOGINOM_DECLINE decline
	 	 ,  cast(  null as int) /*datediff(day, last_nontarget_auto_answer_call 		, uf_registered_at)   */ last_nontarget_auto_answer_call_days
 ,  has_call_weighted_attribution
		 ,  is_abandoned
		 ,  is_autoanswer 
	 , cast(null as int) has_call2--rename has_call
	  ,sum([Флаг технический дозвон]) [Флаг технический дозвон]
	  ,sum([seconds_to_pay]) [seconds_to_pay]
      ,cast(null as int)/* count([Выданная сумма возврат]  )*/ [Заем выдан возврат]
      ,cast(null as int)/* sum([Выданная сумма возврат]  )  */ [Выданная сумма возврат]
	  , cast( null /*min(id) */ as nvarchar(36)) example_of_leadid
	  , sum(ttc_first_case)	   ttc_first_case_sum
	  , count(ttc_first_case)	   ttc_first_case_cnt
	  , cast(null as int)  last_verificationCC_pts_days		--   datediff(day, last_verificationCC_pts	, uf_registered_at)  last_verificationCC_pts_days	
	  , cast(null as int)  last_risk_decilne_pts_days  		--   datediff(day, last_risk_decilne_pts  	, uf_registered_at)  last_risk_decilne_pts_days  	
	  , cast(null as int)  last_risk_approve_pts_days  		--   datediff(day, last_risk_approve_pts  	, uf_registered_at)  last_risk_approve_pts_days  	
	  , cast(null as int)  last_verificationCC_bz_days 		--   datediff(day, last_verificationCC_bz 	, uf_registered_at)  last_verificationCC_bz_days 	
	  , cast(null as int)  last_risk_decilne_bz_days   		--   datediff(day, last_risk_decilne_bz   	, uf_registered_at)  last_risk_decilne_bz_days   	
	  , cast(null as int)  last_risk_approve_bz_days 			--   datediff(day, last_risk_approve_bz 		, uf_registered_at)  last_risk_approve_bz_days 		
	  ,sum(case when [CompanyNaumen]='Полная заявка' then  0 else ЧислоПопыток end) sum_num_of_attempts

	  ,getdate() as created_at
	  , case when cast(l.uf_registered_at as date) >=getdate()-1 then datepart(hour, l.uf_registered_at ) end hour
	  , l.isBigInstallment
	  , l.product
	  , l.productTypeExternal
	  into #lead_cube
	  FROM [Feodor].[dbo].lead  l with(nolock) --with(index=[NCL_idx_date_chanel_company])
--	  join #days_to_Update d on d.[ДатаЛидаЛСРМ для обновления]=cast(l.uf_registered_at as date)
	  
	-- where ДатаЛидаЛСРМ >= getdate()-1
	  group by 
	  cast(l.uf_registered_at as date)
      ,[UF_TYPE]
      ,uf_source
	  ,[UF_LOGINOM_PRIORITY]
	  ,[UF_LOGINOM_STATUS] 
	  ,[Канал от источника]
	  --,[ЛогинПоследнегоСотрудника]
	--  ,login
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,cast(creationdate as date) 
      ,[is_inst_lead]
      ,IsInstallment
      ,[UF_PARTNER_ID аналитический]
      ,[ПричинаНепрофильности]
      ,case when ВремяПервогоДозвона is not null then 1 else 0 end 
	  ,case when [ФлагЗаявка]=1 then 1 else 0 end 
	  ,[СтатусЛидаФедор]
	  ,case when [ФлагПрофильныйИтог] =1 then 1 else 0 end
	  , IsPdl
	  , [IsPts возврат]
	  ,[UF_STAT_CAMPAIGN]
	-- ,  datediff(day, last_verificationCC_pts	, uf_registered_at) 
	-- ,  datediff(day, last_risk_decilne_pts  	, uf_registered_at) 
	-- ,  datediff(day, last_risk_approve_pts  	, uf_registered_at) 
	-- ,  datediff(day, last_verificationCC_bz 	, uf_registered_at) 
	-- ,  datediff(day, last_risk_decilne_bz   	, uf_registered_at) 
	-- ,  datediff(day, last_risk_approve_bz 		, uf_registered_at) 
	 ,is_work_time
	 ,entrypoint
	 ,credit_type
	 , case when ВремяПервойПопытки is not null then 1 else 0 end
	 --	 ,  datediff(day, last_nontarget_auto_answer_call 		, uf_registered_at) 
		 , UF_LOGINOM_DECLINE
		 ,  has_call_weighted_attribution
		 ,  is_abandoned
		 ,  is_autoanswer 
	  , case when cast(l.uf_registered_at as date) >=getdate()-1 then datepart(hour, l.uf_registered_at ) end  
	  , l.isBigInstallment
	  , l.product
	  , l.productTypeExternal

--	 , case when ВремяПервогоДозвона is not null then 1 else 0 end-- has_call2--rename has_call




EXEC sp_releaseapplock @Resource = 'MergeLock';

COMMIT TRANSACTION;								    
END TRY
BEGIN CATCH
        -- Освобождение блокировки в случае ошибки
        EXEC sp_releaseapplock @Resource = 'MergeLock';
        exec analytics.dbo.log_email 'lead_creation error доступ к обновленным записям'
        -- Обработка ошибок
        ROLLBACK TRANSACTION;
        THROW;
END CATCH
END
ELSE
BEGIN
-- Не удалось получить блокировку, обработка ошибки
PRINT 'Не удалось получить блокировку';
 exec analytics.dbo.log_email 'lead_creation critical error доступ к обновленным записям'

ROLLBACK TRANSACTION;
END




	begin tran
	  delete a from   [dbo].[lead_cube]		 a join [#lead_cube] b on a.[ДатаЛидаЛСРМ]=b.[ДатаЛидаЛСРМ]
	 insert into  [dbo].[lead_cube]		   
	 
	SELECT 
               a.[ДатаЛидаЛСРМ] 
,   a.[UF_TYPE] 
,   a.[uf_source] 
,   a.[UF_LOGINOM_PRIORITY] 
,   a.[UF_LOGINOM_STATUS] 
,   a.[Канал от источника] 
,   a.[ЛогинПоследнегоСотрудника] 
,   a.[Группа каналов] 
,   a.[CompanyNaumen] 
,   a.[ID] 
,   a.[creationdate] 
,   a.[ВремяПервойПопытки] 
,   a.[ФлагРазблокированнаяСессия] 
,   a.[ФлагДозвонПоЛиду] 
,   a.[ФлагНедозвонПоЛиду] 
,   a.[ЧислоПопыток] 
,   a.[ПерезвонПоПоследнемуЗвонку] 
,   a.[ФлагНепрофильный] 
,   a.[ФлагНовый] 
,   a.[ФлагПрофильныйИтог] 
,   a.[ФлагПрофильный] 
,   a.[ФлагОтправленВМП] 
,   a.[ФлагОтказКлиента] 
,   a.[ФлагДумает] 
,   a.[ФлагЗаявка] 
,   a.[ПредварительноеОдобрение] 
,   a.[КонтрольДанных] 
,   a.[Одобрено] 
,   a.[ЗаемВыдан] 
,   a.[ВыданнаяСумма] 
,   a.[DateDiff$creationdate$ВремяПервойПопытки] 
,   a.[DateDiff$uf_registered_at$QueueDecision] 
,   a.[DateDiff$uf_registered_at$creationdate] 
,   a.[creationdate_day_in_day] 
,   a.[ВремяПервойПопытки_day_in_day] 
,   a.[ВремяПервойПопытки_0min_to_2min] 
,   a.[ВремяПервойПопытки_2min_to_5min] 
,   a.[ВремяПервойПопытки_5min_to_30min] 
,   a.[ВремяПервойПопытки_30min_and_more] 
,   a.[created_at] 
,   a.[login] 
,   a.[creationdate день] 
,   a.[is_inst_lead] 
,   a.[IsInstallment] 
,   a.[UF_PARTNER_ID аналитический] 
,   a.[ПричинаНепрофильности] 
,   a.[ФлагДозвонПоЛиду 1/0] 
,   a.[ФлагЗаявка 1/0] 
,   a.[СтатусЛидаФедор] 
,   a.[Флаг профильный итог 1/0] 
,   a.[Флаг технический дозвон] 
,   a.[isPdl] 
,   a.[seconds_to_pay] 
,   a.[IsPts возврат] 
,   a.[Заем выдан возврат] 
,   a.[Выданная сумма возврат] 
,   a.[example_of_leadid] 
,   a.[UF_STAT_CAMPAIGN] 
,   a.[ttc_first_case_sum] 
,   a.[ttc_first_case_cnt] 
,   a.[last_verificationCC_pts_days] 
,   a.[last_risk_decilne_pts_days] 
,   a.[last_risk_approve_pts_days] 
,   a.[last_verificationCC_bz_days] 
,   a.[last_risk_decilne_bz_days] 
,   a.[last_risk_approve_bz_days] 
,   a.[sum_num_of_attempts] 
,   a.[is_work_time] 
,   a.[entrypoint] 
,   a.[credit_type] 
,   a.[has_call] 
,   a.[last_nontarget_auto_answer_call_days] 
,   a.[DECLINE] 
,   a.[has_call_weighted_attribution] 
,   a.[is_abandoned] 
,   a.[is_autoanswer] 
,   a.[has_call2] 
,   a.hour 
, a.isBigInstallment
, a.product
, a.productTypeExternal

            FROM 

             #lead_cube a
	 commit tran

	  delete a from   [dbo].[lead_cube_days_to_update]		 a join [#lead_cube] b on a.[ДатаЛидаЛСРМ для обновления]=b.[ДатаЛидаЛСРМ]

	  exec analytics.dbo.sp_birs_update '2F620E6F-DCCE-4DFA-BC51-E9C84B9E9F0F'



	-- alter table [dbo].[lead_cube] alter column 	CompanyNaumen nvarchar(50) null
	-- alter table [dbo].[lead_cube] add ttc_first_case_sum bigint
	-- alter table [dbo].[lead_cube] add ttc_first_case_cnt bigint

	-- alter table [dbo].[lead_cube] add  last_verificationCC_pts_days	int
	-- alter table [dbo].[lead_cube] add  last_risk_decilne_pts_days  	int
	-- alter table [dbo].[lead_cube] add  last_risk_approve_pts_days  	int
	-- alter table [dbo].[lead_cube] add  last_verificationCC_bz_days 	int
	-- alter table [dbo].[lead_cube] add  last_risk_decilne_bz_days   	int
	-- alter table [dbo].[lead_cube] add  last_risk_approve_bz_days 	int
	-- alter table [dbo].[lead_cube] add  sum_num_of_attempts 	bigint
	-- alter table [dbo].[lead_cube] add  is_work_time 	int
	-- alter table [dbo].[lead_cube] add  entrypoint nvarchar(100)
	-- alter table [dbo].[lead_cube] add  	 credit_type nvarchar(100)
	-- alter table [dbo].[lead_cube] add  	 has_call smallint
	-- alter table [dbo].[lead_cube] add  last_nontarget_auto_answer_call_days 	int		 
	-- alter table [dbo].[lead_cube] add  	 DECLINE nvarchar(50)
	-- alter table [dbo].[lead_cube] add  	 has_call_weighted_attribution tinyint
	-- alter table [dbo].[lead_cube] add  	 is_abandoned				   tinyint
	-- alter table [dbo].[lead_cube] add  	 is_autoanswer 				   tinyint
	-- alter table [dbo].[lead_cube] add  	 has_attempt 				   tinyint
	-- alter table [dbo].[lead_cube] add  	 has_call2 				   tinyint
	-- alter table [dbo].[lead_cube] add  	 hour 				   tinyint
	-- alter table [dbo].[lead_cube] add  	 isBigInstallment 				   tinyint
	-- alter table [dbo].[lead_cube] add  	 product 				   varchar(255)
	-- alter table [dbo].[lead_cube] add  	 productTypeExternal 				   varchar(255)

 

	end
/*
	if @mode = 'select' 
	begin--begin

drop table if exists #companies_039893288932

	
select  Name, max(new_name) new_name  into #companies_039893288932  from feodor.dbo.dm_feodor_projects
where new_name is not null
group by Name	


--drop table if exists #companies_039893288932
--select * into #companies_039893288932 from Feodor.dbo.dm_feodor_projects
	;


;with l_stg as (		   
SELECT [ДатаЛидаЛСРМ]
      ,[UF_TYPE]
      ,[uf_source]
      ,[UF_LOGINOM_PRIORITY]
      ,[UF_LOGINOM_STATUS]
      ,[Канал от источника]
      ,[ЛогинПоследнегоСотрудника]
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,[ID]
      ,[creationdate]
      ,[ВремяПервойПопытки]
      ,[ФлагРазблокированнаяСессия]
      ,[ФлагДозвонПоЛиду]
      ,[ФлагНедозвонПоЛиду]
      ,[ЧислоПопыток]
      ,[ПерезвонПоПоследнемуЗвонку]
      ,[ФлагНепрофильный]
      ,[ФлагНовый]
      ,[ФлагПрофильныйИтог]
      ,[ФлагПрофильный]
      ,[ФлагОтправленВМП]
      ,[ФлагОтказКлиента]
      ,[ФлагДумает]
      ,[ФлагЗаявка]
      ,[ПредварительноеОдобрение]
      ,[КонтрольДанных]
      ,[Одобрено]
      ,[ЗаемВыдан]
      ,[ВыданнаяСумма]
      ,[DateDiff$creationdate$ВремяПервойПопытки]
      ,[DateDiff$uf_registered_at$QueueDecision]
      ,[DateDiff$uf_registered_at$creationdate]
      ,[creationdate_day_in_day]
      ,[ВремяПервойПопытки_day_in_day]
      ,[ВремяПервойПопытки_0min_to_2min]
      ,[ВремяПервойПопытки_2min_to_5min]
      ,[ВремяПервойПопытки_5min_to_30min]
      ,[ВремяПервойПопытки_30min_and_more]
      ,[created_at]
      ,[login]
      ,[creationdate день]
      ,[is_inst_lead]
      ,[IsInstallment]
      ,[UF_PARTNER_ID аналитический]
      ,[ПричинаНепрофильности]
      ,[ФлагДозвонПоЛиду 1/0]
      ,[ФлагЗаявка 1/0]
      ,[СтатусЛидаФедор]
      ,[Флаг профильный итог 1/0]
      ,[Флаг технический дозвон]
      ,[isPdl]
      ,[seconds_to_pay]
      ,[IsPts возврат]
      ,[Заем выдан возврат]
      ,[Выданная сумма возврат]
      ,null [example_of_leadid]
      ,[UF_STAT_CAMPAIGN]
      ,ttc_first_case_cnt
      ,ttc_first_case_sum
	  
	  ,   last_verificationCC_pts_days	
	  ,   last_risk_decilne_pts_days  	
	  ,   last_risk_approve_pts_days  	
	  ,   last_verificationCC_bz_days 	
	  ,   last_risk_decilne_bz_days   	
	  ,   last_risk_approve_bz_days 		
	  ,    sum_num_of_attempts
	  ,is_work_time
	 ,entrypoint
	 ,credit_type
	 , has_call
	 , has_call2
	 	 , last_nontarget_auto_answer_call_days
	 , decline	decline
	,   has_call_weighted_attribution	   has_call_weighted_attribution
	,   is_abandoned				  	   is_abandoned				  
	,   is_autoanswer 				  	   is_autoanswer 	
	, hour hour
  FROM feodor.dbo.lead_cube

)
, v_ as (
SELECT --top 100 
[ДатаЛидаЛСРМ]
     ,cast(dateadd(day, datediff(day, '1900-01-01', [ДатаЛидаЛСРМ]) / 7 * 7, '1900-01-01')      as date) [НеделяЛидаЛСРМ]
      ,cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,  [ДатаЛидаЛСРМ])  , 0) as date)  [МесяцЛидаЛСРМ]
      ,[UF_TYPE]
      ,[uf_source]
      ,[UF_LOGINOM_PRIORITY]
      ,[UF_LOGINOM_STATUS]
      ,[Канал от источника]
      ,[ЛогинПоследнегоСотрудника]
      ,[Группа каналов]
      ,isnull(b.new_Name,  a.[companynaumen] )    [companynaumen]
      ,[ID]
      ,[creationdate]
      ,[ВремяПервойПопытки]
      ,[ФлагРазблокированнаяСессия]
      ,[ФлагДозвонПоЛиду]
      ,[ФлагНедозвонПоЛиду]
      ,[ЧислоПопыток]
      ,[ПерезвонПоПоследнемуЗвонку]
      ,[ФлагНепрофильный]
      ,[ФлагНовый]
      ,[ФлагПрофильныйИтог]
      ,[ФлагПрофильный]
      ,[ФлагОтправленВМП]
      ,[ФлагОтказКлиента]
      ,[ФлагДумает]
      ,[ФлагЗаявка]
      ,[ПредварительноеОдобрение]
      ,[КонтрольДанных]
      ,[Одобрено]
      ,[ЗаемВыдан]
      ,[ВыданнаяСумма]
      ,[DateDiff$creationdate$ВремяПервойПопытки]
      ,[DateDiff$uf_registered_at$QueueDecision]
      ,[DateDiff$uf_registered_at$creationdate]
      ,[creationdate_day_in_day]
      ,[ВремяПервойПопытки_day_in_day]
      ,[ВремяПервойПопытки_0min_to_2min]
      ,[ВремяПервойПопытки_2min_to_5min]
      ,[ВремяПервойПопытки_5min_to_30min]
      ,[ВремяПервойПопытки_30min_and_more]
      ,[created_at]
      ,[login]
      ,[creationdate день]
      ,isPdl
      ,[is_inst_lead]
      ,[IsInstallment]
      ,[UF_PARTNER_ID аналитический]
      ,[ПричинаНепрофильности]
      ,[ФлагДозвонПоЛиду 1/0] [ФлагДозвонПоЛиду 1/0]
      ,[ФлагЗаявка 1/0] [ФлагЗаявка 1/0]
      ,[СтатусЛидаФедор] [СтатусЛидаФедор]
	  ,case 
when [ПричинаНепрофильности] = 'Авто в залоге' then 'Залог'
when [ПричинаНепрофильности] = 'Авто на юр лице' then 'Залог'
when [ПричинаНепрофильности] = 'Авто не в собственности не готов переоформить' then 'Залог'
when [ПричинаНепрофильности] = 'Авто не на ходу' then 'Залог'
when [ПричинаНепрофильности] = 'Большой платеж' then 'Продукт'
when [ПричинаНепрофильности] = 'В кредите (более 15%)' then 'Залог'
when [ПричинаНепрофильности] = 'Взял займ в другой компании' then 'Другое'
when [ПричинаНепрофильности] = 'Вина партнера' then 'Другое'
when [ПричинаНепрофильности] = 'Вне зоны присутсвия бизнеса' then 'Клиент'
when [ПричинаНепрофильности] = 'Высокий %' then 'Продукт'
when [ПричинаНепрофильности] = 'Далеко ехать к агенту' then 'Другое'
when [ПричинаНепрофильности] = 'Действующий клиент' then 'Другое'
when [ПричинаНепрофильности] = 'Деньги потребуются позднее' then 'Другое'
when [ПричинаНепрофильности] = 'Документы оформлены на разные фамилии' then 'Клиент'
when [ПричинаНепрофильности] = 'Другое + комментарий' then 'Другое'
when [ПричинаНепрофильности] = 'Другое' then 'Другое'
when [ПричинаНепрофильности] = 'Дубликат в замен утраченного  менее 45 дней' then 'Клиент'
when [ПричинаНепрофильности] = 'Дублирование заявок' then 'Другое'
when [ПричинаНепрофильности] = 'Есть активная заявка' then 'Другое'
when [ПричинаНепрофильности] = 'Задолженность ФССП' then 'Клиент'
when [ПричинаНепрофильности] = 'Ищет в банке' then 'Продукт'
when [ПричинаНепрофильности] = 'Ищет лизинг' then 'Продукт'
when [ПричинаНепрофильности] = 'Категория авто' then 'Залог'
when [ПричинаНепрофильности] = 'Мониторинг рынка' then 'Другое'
when [ПричинаНепрофильности] = 'Не оставлял заявку' then 'Другое'
when [ПричинаНепрофильности] = 'Не подходит авто по году выпуска' then 'Залог'
when [ПричинаНепрофильности] = 'Не подходит ни один способ оформления' then 'Продукт'
when [ПричинаНепрофильности] = 'Не подходит по возрасту' then 'Клиент'
when [ПричинаНепрофильности] = 'Не РФ, не зарегистрирвоано авто на территории РФ' then 'Залог'
when [ПричинаНепрофильности] = 'Не хочет оформляться в МФК' then 'Продукт'
when [ПричинаНепрофильности] = 'Не хочет под залог' then 'Продукт'
when [ПричинаНепрофильности] = 'Неактуально / не нужны деньги' then 'Другое'
when [ПричинаНепрофильности] = 'Необходима конкретная компания' then 'Другое'
when [ПричинаНепрофильности] = 'Нет авто' then 'Залог'
when [ПричинаНепрофильности] = 'Нет паспорта (перевыпуск, замена)' then 'Клиент'
when [ПричинаНепрофильности] = 'Нет прописки' then 'Клиент'
when [ПричинаНепрофильности] = 'Нет СТС' then 'Клиент'
when [ПричинаНепрофильности] = 'Неудобен платеж 2 раза в месяц' then 'Продукт'
when [ПричинаНепрофильности] = 'Нужен бОльший срок' then 'Продукт'
when [ПричинаНепрофильности] = 'Нужен трейд-ин' then 'Продукт'
when [ПричинаНепрофильности] = 'Нужна бОльшая сумма' then 'Продукт'
when [ПричинаНепрофильности] = 'Нужна меньшая сумма' then 'Продукт'
when [ПричинаНепрофильности] = 'Нужны наличные' then 'Продукт'
when [ПричинаНепрофильности] = 'Обратиться в офис сам' then 'Другое'
when [ПричинаНепрофильности] = 'Оставлял заявку давно' then 'Другое'
when [ПричинаНепрофильности] = 'Отказ о ПД' then 'Клиент'
when [ПричинаНепрофильности] = 'Отказ от разговора' then 'Другое'
when [ПричинаНепрофильности] = 'Отказ паспорта' then 'Клиент'
when [ПричинаНепрофильности] = 'Отказывается предоставлять данные по анкете' then 'Клиент'
when [ПричинаНепрофильности] = 'Планирует продать авто' then 'Залог'
when [ПричинаНепрофильности] = 'Плохие отзывы' then 'Продукт'
when [ПричинаНепрофильности] = 'Подумаю/Посоветуюсь' then 'Другое'
when [ПричинаНепрофильности] = 'Ранее был отказ' then 'Клиент'
when [ПричинаНепрофильности] = 'Сотрудничество/Реклама' then 'Другое'
when [ПричинаНепрофильности] = 'Тест' then 'Другое'
when [ПричинаНепрофильности] = 'Хочет сдать авто в лизинг' then 'Залог'
when [ПричинаНепрофильности] = 'Хочу дискретный график' then 'Продукт'
when [ПричинаНепрофильности] = 'Хочу под другой залог' then 'Продукт'
when [ПричинаНепрофильности] is null then 'Причина непрофильности не указана'
end [Причина непрофильности крупно]
, [Флаг профильный итог 1/0]
, [Выданная сумма возврат]
, seconds_to_pay
, example_of_leadid
, ttc_first_case_cnt
, ttc_first_case_sum
	  ,   last_verificationCC_pts_days	
	  ,   last_risk_decilne_pts_days  	
	  ,   last_risk_approve_pts_days  	
	  ,   last_verificationCC_bz_days 	
	  ,   last_risk_decilne_bz_days   	
	  ,   last_risk_approve_bz_days 		
	  ,    sum_num_of_attempts
	   ,is_work_time
	 ,entrypoint
	 ,credit_type
	 ,has_call
	 ,has_call2
	 	 , last_nontarget_auto_answer_call_days
	 , decline
	 
	 ,  has_call_weighted_attribution
	 ,  is_abandoned				  
	 ,  is_autoanswer 				  
	 ,  hour 				  

  FROM l_stg	a
    left join #companies_039893288932 b on a.CompanyNaumen=b.Name
--order by  


  )

	, fin_v_ as (
  select *,
  case 
  when [ФлагЗаявка 1/0]=1 then 'Заявка'
  when [СтатусЛидаФедор] is not null and  [Причина непрофильности крупно] is not null then [Причина непрофильности крупно]
  when [СтатусЛидаФедор] is not null and  [Причина непрофильности крупно] is null then 'Другое'
  when [ФлагДозвонПоЛиду 1/0] =1  then 'Другое'
  end [Статус дозвона]
  
  from v_

)
, v as (

SELECT --top 1000 
       [ДатаЛидаЛСРМ]
      ,[НеделяЛидаЛСРМ] [НеделяЛидаЛСРМ]
      ,[МесяцЛидаЛСРМ]
      ,[UF_TYPE]
      ,[uf_source]
      ,[UF_LOGINOM_PRIORITY]
      ,case when [creationdate день] is not null or CompanyNaumen='Полная заявка' then 'accepted' else  [UF_LOGINOM_STATUS] end  [UF_LOGINOM_STATUS]
      ,[Канал от источника]
    --  ,[ЛогинПоследнегоСотрудника]
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,[ID]
      ,[creationdate]
      ,[ВремяПервойПопытки]
   --   ,[ФлагРазблокированнаяСессия]
      ,[ФлагДозвонПоЛиду]
   --   ,[ФлагНедозвонПоЛиду]
   --   ,[ЧислоПопыток]
   --   ,[ПерезвонПоПоследнемуЗвонку]
      ,[ФлагНепрофильный]
   --   ,[ФлагНовый]
      ,[ФлагПрофильныйИтог]
   --   ,[ФлагПрофильный]
      ,[ФлагОтправленВМП]
   --   ,[ФлагОтказКлиента]
   --   ,[ФлагДумает]
      ,[ФлагЗаявка]
      ,[ПредварительноеОдобрение]
      ,[КонтрольДанных]
      ,[Одобрено]
      ,[ЗаемВыдан]
      ,[ВыданнаяСумма]
    --  ,[DateDiff$creationdate$ВремяПервойПопытки]
    --  ,[DateDiff$uf_registered_at$QueueDecision]
      ,[DateDiff$uf_registered_at$creationdate]
    --  ,[creationdate_day_in_day]
      ,[ВремяПервойПопытки_day_in_day]
    --  ,[ВремяПервойПопытки_0min_to_2min]
    --  ,[ВремяПервойПопытки_2min_to_5min]
    --  ,[ВремяПервойПопытки_5min_to_30min]
     -- ,[ВремяПервойПопытки_30min_and_more]
    --  ,[created_at]
    --  ,[login]
    --  ,[creationdate день]
      ,[is_inst_lead]
      ,[IsInstallment]
      ,[UF_PARTNER_ID аналитический]
      ,[ПричинаНепрофильности]
      ,[ФлагДозвонПоЛиду 1/0]
      ,[ФлагЗаявка 1/0]
      ,[СтатусЛидаФедор]
      ,[Причина непрофильности крупно]
      ,[Статус дозвона]
	  ,[Флаг профильный итог 1/0]
	  ,case when [СтатусЛидаФедор] in ('Непрофильный') then 1 else 0 end [Флаг непрофильный итог 1/0]
	  ,case when [СтатусЛидаФедор] in ('Новый', 'Думает') and [ФлагЗаявка 1/0]=0 then 1 else 0 end [Флаг остальные статусы федор 1/0]
      ,isPdl		  
	  , [Выданная сумма возврат]
      ,case when ДатаЛидаЛСРМ>='20230901' then seconds_to_pay*2.0/60.0 end [Расходы на связь]
	  ,cast(example_of_leadid as nvarchar(50))    example_of_leadid
	  , ttc_first_case_cnt
	  , ttc_first_case_sum
	  
	  ,   last_verificationCC_pts_days	
	  ,   last_risk_decilne_pts_days  	
	  ,   last_risk_approve_pts_days  	
	  ,   last_verificationCC_bz_days 	
	  ,   last_risk_decilne_bz_days   	
	  ,   last_risk_approve_bz_days 		
	  ,    sum_num_of_attempts
	   ,is_work_time
	 ,entrypoint
	 ,isnull(credit_type, '?') 	  credit_type
	 , case when has_call = 1 then 'Есть попытка' when  has_call = 0 then  'Нет попытки'	else '?'    end 	 has_call
	 , case when has_call2 = 1 then  'Есть дозвон' when  has_call = 0 then  'Нет дозвона'	else '?'    end 	 has_call2
	 , last_nontarget_auto_answer_call_days
	 , decline
	 ,  has_call_weighted_attribution
	 ,  is_abandoned				  
	 ,  is_autoanswer 				  
	 ,  hour
	 , NEWID() row_id


  FROM fin_v_ a
  --left join analytics.dbo.v_Calendar c on a.ДатаЛидаЛСРМ=c.Дата


  )

 --  exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'DA70CD30-F1A9-425C-99B9-F93B9099AEEA'

 select  top (select topN from feodor.dbo.lead_cube_report_topN with(nolock) )
 * from (
  select -- top 100 
  [ДатаЛидаЛСРМ]   [Отчетная дата]  , 'День'   [Тип отчетной даты]  , * from v
--  where [ДатаЛидаЛСРМ]>=getdate()-90 union all
--  select  --top 100
--  [НеделяЛидаЛСРМ] [Отчетная дата]  , 'Неделя' [Тип отчетной даты], * from v where [НеделяЛидаЛСРМ]>=dateadd(week, -12, cast(DATEADD(wk   , DATEDIFF(wk   , 0,  getdate()  ), 0) as date)) union all
--  select --top 100 
--  [МесяцЛидаЛСРМ]  [Отчетная дата]  , 'Месяц'  [Тип отчетной даты] , * from v where [МесяцЛидаЛСРМ]>=dateadd(month, -12, cast(format(getdate(), 'yyyy-01-01') as date))-- union all
-- --  select  [ДатаЛидаЛСРМ]   [Отчетная дата]  , 'День'   [Тип отчетной даты]  , * from v where [ДатаЛидаЛСРМ]>=getdate()-90 union all
-- -- select  [НеделяЛидаЛСРМ] [Отчетная дата]  , 'Неделя' [Тип отчетной даты], * from v where [НеделяЛидаЛСРМ]>=dateadd(week, -12, cast(DATEADD(wk   , DATEDIFF(wk   , 0,  getdate()  ), 0) as date)) union all
-- -- select  [МесяцЛидаЛСРМ]  [Отчетная дата]  , 'Месяц'  [Тип отчетной даты] , * from v where [МесяцЛидаЛСРМ]>=dateadd(month, -12, cast(format(getdate(), 'yyyy-01-01') as date))-- union all
 ) x 


	end--end

	*/

	if @mode = 'prod'
	begin
	drop table if exists lead_cube_report_topN 
	select 1000000000 topN  into lead_cube_report_topN 
	exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'DA70CD30-F1A9-425C-99B9-F93B9099AEEA'
    end


	
	if @mode = 'dev'
	begin
	drop table if exists lead_cube_report_topN 
	select 1000 topN  into lead_cube_report_topN 
	end

	--exec lead_cube_creation 'dev'
	--exec lead_cube_creation 'prod'


	--exec Analytics.dbo.birs 'лидам'
	end
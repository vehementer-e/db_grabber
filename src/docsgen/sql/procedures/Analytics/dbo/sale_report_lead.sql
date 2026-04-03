CREATE proc [dbo].[sale_report_lead] @mode  varchar(max) = 'select'
--exec [dbo].[kpi_report_lead] 
as 
--use feodor




	if @mode = 'prod'
	begin
	drop table if exists feodor.dbo.lead_cube_report_topN 
	select 1000000000 topN  into feodor.dbo.lead_cube_report_topN 
    end


	
	if @mode = 'dev'
	begin
	drop table if exists feodor.dbo.lead_cube_report_topN 
	select 1000 topN  into feodor.dbo.lead_cube_report_topN 
	end

	
	if @mode = 'rules' 
	begin
	  
	SELECT 
           a.[description] 
,   a.updated 
,   a.[component_id] 
, left( replace(replace(  a.[conditions] , ', ', ',
'), ';', N'
➕
') , 1000)+ case when len (
replace(replace(  a.[conditions] , ', ', ',
'), ';', N'
➕
')



)>1000 then N'
## ------------------------- ##
' + right(replace(replace(  a.[conditions] , ', ', ',
'), ';', N'
➕
') , 50) else '' end 
[conditions] 
,   a.[result] 
,   a.[fabricResult] 
,   a.[rule_order] 
,  replace(replace(  a.[conditions2] , ', ', ',
'), ';', N'
➕
') [conditions2] 
--,   a.[conditions2] 
,   a.[result2] 
,   a.[rule_order2] 
,   a.version 
, case when a.version =  (select max(version) from v_marketing_rule ) then 'Current versopn' else '' end is_last_version
 

        FROM 

        analytics.dbo.v_marketing_rule a
--where a.description in 
--('01 Определение решения по лиду' ,
--'02 Расчет маркетинг канала лида' ,
-- '03 Определение правила фильтрации' ,
-- '05 Внешнее обогащение' ,
-- '07 Определение приоритета' )
 --or left(description, 1)='1'
 order by 1


end
	
	if @mode = 'select' 
	begin
	  
	
	

	 
	 
	
	

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
	, product
	, isBigInstallment
	,  productTypeExternal  
	
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
	 , [Флаг технический дозвон] isTechCalled
	 	, product
	, isBigInstallment
	,  productTypeExternal  

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
	 ,  isTechCalled sumTechCalled
	 	, product
	, isBigInstallment
	-- , NEWID() row_id
	,  productTypeExternal  


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


	

	


	end


	--select top 100 * from v_lead2 where product = 'Big Installment Рыночный'
	--order by created desc

	/*
return

DECLARE @sql NVARCHAR(MAX) = (
    SELECT TOP 1 definition 
    FROM Feodor.sys.sql_modules
    WHERE object_id = 1782570430
);

DECLARE @StartIndex INT = CHARINDEX('begin--begin', @sql);
DECLARE @EndIndex INT = CHARINDEX('end--end', @sql);

IF @StartIndex > 0 AND @EndIndex > 0 AND @StartIndex < @EndIndex
BEGIN
    -- Извлекаем текст между "begin--begin" и "end--end"
    DECLARE @ExtractedText NVARCHAR(MAX) = SUBSTRING(
        @sql,
        @StartIndex + LEN('begin--begin'),  -- Старт после "begin--begin"
        @EndIndex - (@StartIndex + LEN('begin--begin'))  -- Длина до "end--end"
    );

    -- Выводим результат
    SELECT @sql = ' 
	
	'+ LTRIM(RTRIM(@ExtractedText)) 
END
ELSE
BEGIN
    SELECT 'No matching text found' AS ErrorMessage;
END;

select  (@sql)
*/ 
	CREATE   proc [dbo].[create_returns]

	as

begin



drop table if exists #fl
select 
[id] 
,[Дата лида] 
,[Статус лида] 
,[Кампания наумен] 
,[IsInstallment] 
,[Номер заявки] 
,[Дата заявки] 
,[Заем Выдан] 
,[Выданная Сумма] 

,[Телефон] 
,[Комментарий] 
,[Возврат] 
,[IsInstallment возврат] 
,[Заем выдан возврат] 
,[Выданная сумма возврат] 
into #fl
from 

analytics.dbo.v_feodor_leads

--select * from #fl
--where IsInstallment=1 and [Заем Выдан] is not null

--exec Analytics.dbo.generate_select_table_script 'analytics.dbo.v_feodor_leads'



DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	  [ID] numeric(10,0),
	  [Группа каналов] nvarchar(128),
	  [Канал от источника] nvarchar(128),
	  UF_REGISTERED_AT    datetime2,
	  UF_LOGINOM_PRIORITY  int,
	  UF_SOURCE  nvarchar(128)
)


DECLARE @start_id numeric(10, 0), @depth_id numeric(10, 0)
DECLARE @ID_Table_Name varchar(100) -- название таблицы со списком ID
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)


DROP TABLE IF EXISTS #ID_List
CREATE TABLE #ID_List(ID numeric(10, 0))
insert into #ID_List 
select id from #fl
--название таблицы со списком ID
SELECT @ID_Table_Name = '#ID_List'
--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'

TRUNCATE TABLE #TMP_leads

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ID_Table_Name = @ID_Table_Name, -- название таблицы со списком ID
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message









drop table if exists #rep_retu

select --top 1000


        cast(format( a.[Дата лида] , 'yyyy-MM-01') as date)                  [Месяц звонка]
,      [Дата лида]                                                          [Дата лида]
,      [IsInstallment]                                                          [IsInstallment]
,      Телефон                                                               Телефон
,      b.[Группа каналов]                                                   [Группа каналов]
,      b.[Канал от источника]                                               [Канал от источника]
,      a.[Номер заявки]                                                     [Номер заявки]
,      a.id                                                                 [ID LCRM]
,      UF_REGISTERED_AT                                                     UF_REGISTERED_AT
,      UF_LOGINOM_PRIORITY                                                         Приоритет
--,     Analytics.[dbo].[get_lead_project]( [id проекта naumen])            [CompanyNaumen]
,      [Кампания наумен]                                                          [CompanyNaumen]
,      UF_SOURCE                                                          Источник
,      case when a.[Заем Выдан] is not null then 1 else 0 end                                      [Признак Займ со звонка]
--,      Analytics.dbo.FullMonthsSeparation([Дата лида], a.[Заем выдан Возврат] )   [Через сколько полных мес вернулся]
,      a.[Возврат]                                                           [Возврат]
,      a.[Заем выдан Возврат]                                                    [Возврат дата]
,       cast(format( a.[Заем выдан Возврат] , 'yyyy-MM-01') as date)             [Возврат месяц]
,      a.[Выданная сумма Возврат]                                                [Выданная сумма возврат]
,      a.[Заем выдан]                                                     [Заем выдан со звонка]
,      a.[Выданная сумма]                                                 [Выданная cумма со звонка]
--,      case when ROW_NUMBER() over (partition by Телефон order by [Дата лида] )=1 then 1 else 0 end as                                   [Признак первый дозвон клиенту]                            
,      1 as Дозвон
,      getdate()                                                         [created]
into #rep_retu
from      #fl a
left join #TMP_leads  b on a.id=b.id



drop table if exists report_returns1

;


with v as (
select *
,      case when ROW_NUMBER() over (partition by Телефон order by [Дата лида] )=1 then 1 else 0 end as [Признак первый дозвон клиенту]                            
,      Analytics.dbo.FullMonthsSeparation([Дата лида], [Возврат дата] )   [Через сколько полных мес вернулся]



from #rep_retu 


)

SELECT [Месяц звонка]
      ,cast([Дата лида] as date) [Дата лида день]
      ,[IsInstallment] [IsInstallment]
      ,[Группа каналов]
      ,cast(UF_REGISTERED_AT as date) [UF_REGISTERED_AT день]
      ,cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, UF_REGISTERED_AT), 0) as date)  [UF_REGISTERED_AT месяц]
      ,[Канал от источника]
      ,analytics.dbo.get_channel([Группа каналов], [Канал от источника]) Канал

      ,[Приоритет]
      ,[CompanyNaumen]
      ,[Источник]
      ,[Признак Займ со звонка]
      ,[Через сколько полных мес вернулся]
      ,[Возврат]
      ,[Признак первый дозвон клиенту]
      ,[Возврат месяц]
      ,count([Возврат дата]) [Количество возвратов]
      ,sum([Выданная сумма возврат]) [Сумма возвратов]
      ,count([Заем выдан со звонка]) [Количество займов со звонка]
      ,sum([Выданная cумма со звонка]) [Сумма займов со звонка]

      ,sum([Дозвон]) [Количество дозвонов]
      ,min([created]) [created]
	  into report_returns1
  FROM v
  group by [Месяц звонка]
      ,cast([Дата лида] as date)
      ,[IsInstallment] 

      ,[Группа каналов]
      ,[Канал от источника]
      ,cast(UF_REGISTERED_AT as date)  
      ,cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, UF_REGISTERED_AT), 0) as date) 
      ,[Приоритет]
      ,[CompanyNaumen]
      ,[Источник]
      ,[Признак Займ со звонка]
      ,[Через сколько полных мес вернулся]
      ,[Возврат]
      ,[Признак первый дозвон клиенту]
      ,[Возврат месяц]



	--  select * into report_returns_backup from report_returns 1
	--
	--  drop table report_returns
	--
	--  create or alter view dbo.report_returns 
	--  as
	--  
	--
	--  select * from report_returns1






	--exec [Возвраты нецелевой траффик] 
return
--drop table if exists #lcrm;
--select 
--id,
--[UF_LOGINOM_DECLINE]
--into #lcrm
--
--from stg._LCRM.lcrm_tbl_short_w_channel a
--
--
--drop table if exists #lh;
--select 
--ДатаЛидаЛСРМ,
--UF_REGISTERED_AT,
--UF_LOGINOM_PRIORITY,
--UF_LOGINOM_STATUS,
--ВремяПервойПопытки,
--id,
--uf_phone,
--UF_SOURCE,
--[Группа каналов],
--attempt_result,
--ВремяПервогоДозвона,
-- [Канал от источника]
--, ПричинаНепрофильности
--, CompanyNaumen
--, ФлагПрофильныйИтог
--, Номер
--, ПредварительноеОдобрение
--, КонтрольДанных
--, ЗаемВыдан 
--, ВыданнаяСумма
--, [ЧислоПопыток]
--into #lh
--
--from Feodor.dbo.dm_leads_history a 
--
--
--	
--drop table if exists #dl
--
--select * into #dl from Feodor.dbo.dm_Lead	
--	
--	
--drop table if exists #dm_lead	
--	
--select [Дата лида]              = dateadd(hour, 3, [Дата лида])        	
--,      [ID LCRM]                = try_cast([ID LCRM] as numeric)         	
--,      projectuuid              = fp.IdExternal                        	
--,      [Номер заявки]           = [Номер заявки (договор)] 	
--,      Телефон                  = isnull(lh.uf_phone, [Номер  телефона] )	
--,      [Источник]               = lh.UF_SOURCE	
--,      [Приоритет]              = lh.UF_LOGINOM_PRIORITY	
--,      lh.[Группа каналов]	
--,      lh.[Канал от источника]	
--,      lh.CompanyNaumen	
--,      lh.UF_REGISTERED_AT	
--,      [Признак Займ со звонка] = case when lh.ЗаемВыдан is not null then 1 else 0 end  	
--,      [Выданная cумма со звонка] = lh.ВыданнаяСумма 	
--,      [Заем выдан со звонка] = lh.ЗаемВыдан 	
--	
--into #dm_lead	
--from      #dl   	
--join #lh lh  on lh.id=try_cast([ID LCRM] as numeric)	
--join feodor.dbo.[dm_feodor_projects] fp on fp.LaunchControlName=lh.CompanyNaumen and RecallProject=0	
--	
--	
--	drop table if exists  #fa
--	
--select 
--       Номер
--,      ДатаЗаявкиПолная
--,      [Верификация КЦ]
--,      [Предварительное одобрение]
--,      [Контроль данных]
--,      [Верификация документов клиента]
--,      [Верификация документов]
--,      Одобрено
--,      [Заем выдан]
--,      [Выданная сумма]
--,      телефон
--,      [Вид займа]
--,      [Место cоздания]
--
--into #fa
--from reports.dbo.dm_Factor_Analysis fa
--
----	select * from #fa
--
--	
--	
--drop table if exists #dm_lead_rn	
--select *                                                                   	
--,      ROW_NUMBER() over(partition by Телефон order by [Дата лида])         rn	
----,      lead([Дата лида], 1) over(partition by Телефон order by [Дата лида]) ДатаСледующегоДозвона	
--,      case when ROW_NUMBER() over(partition by Телефон order by [Дата лида]) =1  then 1 else 0 end                     [Признак первый дозвон клиенту]	
----,      case when ROW_NUMBER() over(partition by Телефон order by [Дата лида]) =1 and [Группа каналов]='Триггеры' then 1 else 0 end                     ПервоеАллоТриггеры	
----,      case when ROW_NUMBER() over(partition by Телефон, [Канал от источника]  order by [Дата лида] desc) =1 and [Канал от источника]='CPA нецелевой' then 1 else 0 end                     ПоследнееАллоПоНецелевому	
--into #dm_lead_rn	
--from #dm_lead	
--
--delete from #dm_lead_rn where [Признак первый дозвон клиенту]=0
--	
--
--	
--	delete from #fa where [Заем выдан] is  null
--
--	delete from #fa where Номер  in (select [Номер заявки]   from #dm_lead where [Номер заявки] is not null)
--	delete from #fa where Телефон not in  (select Телефон from #dm_lead where Телефон is not null) 
--	delete from #fa where [Вид займа]<>'Первичный'
--
--	;with v  as (select *, row_number() over(partition by Телефон order by [Заем выдан]) rn from #fa ) delete from v where rn>1
--	
--	drop table if exists  #t
--	
----select *
----from #fa
--select a.[Заем выдан]    
--,      1                  Займ
--,      a.Номер
--,      a.[Выданная сумма]
--,      x.[ID LCRM]        [ID источник возврата]
----,      t.[ID LCRM]        ВозвратОтПервогоАллоТриггеры
----,      y.[ID LCRM]        ВозвратОтХотяБыОдногоАллоНецелевой 
--into #t
--from        #fa                     a
--outer apply (select top 1 *
--	from #dm_lead_rn b
--	where a.Телефон=b.Телефон
--		and a.[Заем выдан]>=b.[Дата лида]
--		and [Признак первый дозвон клиенту]=1 ) x
----	outer apply (select top 1 * from #dm_lead_rn b where a.Телефон=b.Телефон and a.[Заем выдан]>=b.[Дата лида] and ПервоеАллоТриггеры=1 ) t
----	outer apply (select top 1 * from #dm_lead_rn b where a.Телефон=b.Телефон and a.[Заем выдан]>=b.[Дата лида] and [Канал от источника]='CPA нецелевой' order by b.[Дата лида]) y
--
--
----	drop proc returns_after_cpa_non_target
--
--
--	  ;
--	  
--drop table if exists #lead_report;
--
--with lh as (
--select a.*, l.UF_LOGINOM_DECLINE, null UF_PARTNER_ID , case when ROW_NUMBER() over (partition by a.uf_phone order by ВремяПервойПопытки) =1 and ВремяПервойПопытки is not null then 1 else 0 end rn_over_ВремяПервойПопытки 
--from #lh a
--left join #lcrm l on l.id=a.id
----left join #lcrm_full l_f on l_f.id=a.id
--
--)
--
--, a as (
--select 
--  a.UF_REGISTERED_AT
--, ДатаЛидаЛСРМ [Дата лида]
--, cast(format(a.UF_REGISTERED_AT, 'yyyy-MM-01') as date) [Месяц лида]
--, case when cast(a.UF_REGISTERED_AT as date)=cast(a.ВремяПервойПопытки as date) then 1 else 0 end [Признак обработан в 1 день]
--, case when a.ВремяПервойПопытки is not null  then 1 else 0 end [Признак обработан]
--, a.rn_over_ВремяПервойПопытки
--, a.ВремяПервойПопытки
--, a.ВремяПервогоДозвона
--, isnull(r.[Признак первый дозвон клиенту], 0) [Признак первый дозвон клиенту]
--, a.UF_SOURCE
--, a.ПричинаНепрофильности
--
--, a.UF_PARTNER_ID
--, a.UF_LOGINOM_DECLINE
--, UF_LOGINOM_PRIORITY
--
--, a.[ЧислоПопыток]
--, a.[Группа каналов]
--, a.[Канал от источника]
--, a.CompanyNaumen
--, a.ФлагПрофильныйИтог
--, a.Номер
--, a.ПредварительноеОдобрение
--, a.КонтрольДанных
--, a.ЗаемВыдан 
--, a.ВыданнаяСумма 
--, r.Возврат 
--, r.[Выданная сумма возврат] 
--from lh a
--left join Analytics.dbo.returns r on a.id=r.[ID LCRM]
--where  a.UF_REGISTERED_AT >='20200101'
--
--)
--
--
----select  top 100  * from a where [Признак первый дозвон клиенту] is null
--
--select 
--
--  [Месяц лида]
--, [Дата лида]
--, [Признак обработан в 1 день]
--, [Признак обработан]
--, rn_over_ВремяПервойПопытки 
----, UF_PARTNER_ID
--, UF_LOGINOM_DECLINE
--, UF_LOGINOM_PRIORITY
--, UF_SOURCE
--, ПричинаНепрофильности
--, [Группа каналов]
--, [Канал от источника]
--, [Признак первый дозвон клиенту]
--, CompanyNaumen
--, sum([ЧислоПопыток]) as [Количество попыток дозвониться]
--, count(*) as [Количество лидов]
--, count(ВремяПервойПопытки) as [Количество попыток]
--, count(ВремяПервогоДозвона) as [Количество успешных попыток]
--, count(case when ФлагПрофильныйИтог=1 then ВремяПервогоДозвона end) as [Количество профильных]
--, count(Номер) as [Количество заявок]
--, count(ПредварительноеОдобрение) as [Количество предв. одобр.]
--, count(КонтрольДанных) as [Количество КД]
--, count(ЗаемВыдан) as [Количество Займов]
--, sum(ВыданнаяСумма) as [Сумма Займов]
--, count(Возврат )[Количество возвратов]
--, sum([Выданная сумма возврат] ) [Сумма возвратов]
--into #lead_report
--from a
--group by
--  [Месяц лида]
--, [Дата лида]
--, [Признак обработан]
--, [Признак обработан в 1 день]
----, UF_PARTNER_ID
--, UF_LOGINOM_DECLINE
--, UF_LOGINOM_PRIORITY
--, rn_over_ВремяПервойПопытки
--, UF_SOURCE
--, ПричинаНепрофильности
--
--, [Группа каналов]
--, [Канал от источника]
--, [Признак первый дозвон клиенту]
--, CompanyNaumen
--
--
--drop table if exists Analytics.dbo.report_leads;
--select * into Analytics.dbo.report_leads from #lead_report


end




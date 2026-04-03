
CREATE   proc [dbo].[Создание витрины с лидами федор для рейтинга]

as
begin


drop table if exists #t2

SELECT 	
     
	  a.[id]
      ,a.[Телефон]	
	--  ,b.ФИО ФИО
      ,a.[Дата лида]	
	  , a.[Последний сотрудник] [Последний сотрудник]
      ,a.[Флаг отправлен в МП]	
      ,a.[Отправлен в МП дата]	
      ,a.[Статус лида]	
      ,a.[IsInstallment]	[Выбрал оформление Инстоллмент]
      ,a.[Номер заявки]	
      ,a.[Дата заявки]	
      ,a.[Верификация КЦ]	
      ,a.[Предварительное одобрение]	
      ,a.[Контроль данных]	
      ,a.[Одобрено]	
      ,a.[Заем Выдан]	
      ,a.[Выданная Сумма]	
      ,a.[Признак непрофильный]	
      ,a.[Признак профильный]	
	  into #t2
  FROM [Analytics].[dbo].[v_feodor_leads] a 	
  where [Дата лида]>='20211201'	

  

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	  [ID] numeric(10,0),

	  UF_TYPE  nvarchar(128),
	  UF_SOURCE  nvarchar(128),
	  UF_LOGINOM_PRIORITY  nvarchar(128)
)


DECLARE @start_id numeric(10, 0), @depth_id numeric(10, 0)
DECLARE @ID_Table_Name varchar(100) -- название таблицы со списком ID
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)


DROP TABLE IF EXISTS #ID_List
CREATE TABLE #ID_List(ID numeric(10, 0))
insert into #ID_List 
select id from #t2
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






 -- select * from stg._fedor.core_lead	
drop table if exists #t3

 select
	  a.[id]
      ,a.[Телефон]	
      ,a.[Дата лида]	
	  , a.[Последний сотрудник]
	  , [Последний сотрудник фио] = ltrim(rtrim(replace(core_user.LastName+' '+core_user.FirstName +' '+core_user.MiddleName, 'ё', 'е')))

      ,a.[Флаг отправлен в МП]	
      ,a.[Отправлен в МП дата]	
      ,a.[Статус лида]	
      ,Analytics.dbo.lcrm_is_inst_lead(uf_type, uf_source, UF_LOGINOM_PRIORITY)     [Траффик Инстоллмент]
      ,a.[Выбрал оформление Инстоллмент]
      ,a.[Номер заявки]	
      ,a.[Дата заявки]	
      ,a.[Верификация КЦ]	
      ,a.[Предварительное одобрение]	
      ,a.[Контроль данных]	
      ,a.[Одобрено]	
      ,a.[Заем Выдан]	
      ,a.[Выданная Сумма]	
      ,a.[Признак непрофильный]	
      ,a.[Признак профильный]	
	  into #t3
  FROM #t2 a 	
 left join  #TMP_leads l on l.id=a.id	
 left join  stg._fedor.core_user core_user on core_user.DomainLogin collate  Cyrillic_General_CI_AS       =a.[Последний сотрудник]


 drop table if exists   dbo.[Витрина с лидами федор для рейтинга]
 select * into dbo.[Витрина с лидами федор для рейтинга] from #t3
 --order by 3

 select * from  analytics.dbo.[Витрина с лидами федор для рейтинга]

 end
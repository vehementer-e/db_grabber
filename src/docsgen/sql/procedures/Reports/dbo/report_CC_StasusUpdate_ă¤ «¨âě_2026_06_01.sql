
    

-- exec     report_CC_StasusUpdate  '20190830'
    CREATE PROC dbo.report_CC_StasusUpdate  @dtime date='20190830'
    as


    begin

    set nocount on 

	--24.03.2020
	SET DATEFIRST 1;

    declare @dt date
    set @dt=@dtime
--
-- Справочник результатов взаимодействий
--
    if object_id('tempdb.dbo.#rv') is not null drop table #rv

    select Ссылка
         , ВерсияДанных
         , ПометкаУдаления
         , ИмяПредопределенныхДанных
         , Код=cast(Код as varchar(100))
         , Наименование=	cast(Наименование as varchar(1024))
         , Успешный
         , Collection
         , Seller
         , Сортировка
         , ОбластьДанныхОсновныеДанные
      into #rv
      from 
      ----[c1-vsr-sql04].crm.dbo.[Справочник_CM_РезультатыВзаимодействия] 
      stg._1cCRM.[Справочник_CM_РезультатыВзаимодействия] 

--
-- Аналитические показатели из CMR
--
      if object_id('tempdb.dbo.#cmr_p') is not null drop table #cmr_p

	/*      
      ;
      with cmr_p as ( 
	  --var 1
      --select dt=dateadd(year,-2000,cast(isnull(p.дата,cmr.период) as datetime))
      --     , код external_id
      --     , КоличествоПолныхДнейПросрочки dpd
      --     , ПросроченнаяЗадолженность dpd_sum
      --     , ДатаПоследнегоПлатежа last_payment_date
      --     , СуммаПоследнегоПлатежа last_payment_sum
      --     , d.Ссылка
      --  from stg._1cCMR.[РегистрСведений_АналитическиеПоказателиМФО] cmr
      --  left join stg._1cCMR.[Документ_Платеж] p on p.ссылка=cmr.Регистратор_Ссылка
      --  join [Stg].[_1cCMR].[Справочник_Договоры]  d on d.ссылка=cmr.Договор
      -- where cast(cmr.период as date)=--dateadd(day,-1,
      -- dateadd(year,2000,@dt)

		--var 2
		--DWH-2516
		SELECT dt = cast(isnull(dateadd(year,-2000,p.дата),cmr.период) as datetime)
			   , код external_id
			   , КоличествоПолныхДнейПросрочки dpd
			   , ПросроченнаяЗадолженность dpd_sum
			   , ДатаПоследнегоПлатежа last_payment_date
			   , СуммаПоследнегоПлатежа last_payment_sum
			   , d.Ссылка
		from Stg.dbo._1cАналитическиеПоказатели AS cmr 
			LEFT JOIN Stg._1cCMR.Документ_Платеж AS p on p.ссылка=cmr.Регистратор_Ссылка
			INNER JOIN Stg._1cCMR.Справочник_Договоры AS d on d.ссылка=cmr.Договор
		where cast(cmr.период as date) = @dt
        )
      , p as (
      select rn=row_number() over (partition by  external_id order by dt desc) 
           , dt
           , external_id
           , dpd
           , dpd_sum
           , last_payment_date
           , last_payment_sum
           , Ссылка
        from cmr_p
      )
        select dt
             , external_id
             , dpd
             , dpd_sum
             , last_payment_date
             , last_payment_sum
             , Ссылка
          into #cmr_p from p
         where rn=1
	*/

		--var 3
		--DWH-2516
		SELECT 
			dt = B.d
			, B.external_id
			, dpd = B.dpdMFO
			, dpd_sum = B.overdue
			, last_payment_date = S.ДатаПоследнегоПлатежа
			, last_payment_sum = isnull(L.[сумма поступлений], 0)
			, Ссылка = dwh2.dbo.get1CIDRREF_FromGUID(B.CMRContractsGUID)
		INTO #cmr_p
		FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
				--на конец дня
				OUTER APPLY (
					SELECT ДатаПоследнегоПлатежа = max(F.d)
					FROM dwh2.dbo.dm_CMRStatBalance AS F (NOLOCK)
					WHERE 1=1
						AND F.external_id = B.external_id
						and F.d <= B.d -- ! меньше или равно !
						AND F.[сумма поступлений] <> 0
					) AS S
				LEFT JOIN dwh2.dbo.dm_CMRStatBalance AS L (NOLOCK)
					ON L.external_id = B.external_id
					AND L.d = S.ДатаПоследнегоПлатежа
		WHERE B.d = @dt

--
-- Количество звонков "за все время"
--

      if object_id('tempdb.dbo.#calls_total') is not null drop table #calls_total

      select CRM_ClientTouch.Партнер
           , count(CRM_TelCall.ссылка) c
        into #calls_total
        from---- [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие]
        stg._1cCRM.[Документ_CRM_Взаимодействие]
        CRM_ClientTouch with (nolock)
             join 
             ----[c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия  
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия  
             dv  with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
            ---- [c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок]  
             stg._1cCRM.[Документ_ТелефонныйЗвонок]  
             CRM_TelCall with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
       group by CRM_ClientTouch.Партнер                                                


--
-- Количество звонков "сегодня"
--

    --select Партнер ,ссылка from  [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch   with (nolock)   where CRM_ClientTouch.Дата>=@dt4000 and CRM_ClientTouch.Дата<=dateadd(day,1,@dt4000)
      if object_id('tempdb.dbo.#calls_today') is not null drop table #calls_today

      select CRM_ClientTouch.Партнер
           , count(CRM_TelCall.ссылка) c
        into #calls_today
        from 
        (select Партнер ,ссылка from  
        ----[c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] 
        stg._1cCRM.[Документ_CRM_Взаимодействие] 
        CRM_ClientTouch   with (nolock)   where CRM_ClientTouch.Дата>=dateadd(year,2000,@dt) and CRM_ClientTouch.Дата<=dateadd(day,1,dateadd(year,2000,@dt))) CRM_ClientTouch
             join 
            ---- [c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия 
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия 
             dv   with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
            ---- [c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] 
             stg._1cCRM.[Документ_ТелефонныйЗвонок] 
             CRM_TelCall   with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
  
       group by CRM_ClientTouch.Партнер                                                
                                
--
-- Количество звонков "с начала недели"
--
set datefirst 1;

      if object_id('tempdb.dbo.#calls_this_week') is not null drop table #calls_this_week

      select CRM_ClientTouch.Партнер
           , count(CRM_TelCall.ссылка) c
        into #calls_this_week
        --from [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch  with (nolock)
        from (select Партнер ,ссылка from  
      ----  [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] 
        stg._1cCRM.[Документ_CRM_Взаимодействие] 
        CRM_ClientTouch   with (nolock)  where  CRM_ClientTouch.Дата between dateadd(day,-1*datepart(dw,getdate()),dateadd(year,2000,@dt)) and dateadd(day,1,dateadd(year,2000,@dt))) CRM_ClientTouch
             join 
             ----[c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия 
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия 
             dv  with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
             ----[c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] 
             stg._1cCRM.[Документ_ТелефонныйЗвонок] 
             CRM_TelCall   with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
       
       group by CRM_ClientTouch.Партнер                                                
                                
--
-- Количество звонков "с начала месяца"
--
set datefirst 1;

      if object_id('tempdb.dbo.#calls_this_month') is not null drop table #calls_this_month

      select CRM_ClientTouch.Партнер
           , count(CRM_TelCall.ссылка) c
        into  #calls_this_month
        --from [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch  with (nolock)
           from (select Партнер ,ссылка from  
           ----[c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] 
           stg._1cCRM.[Документ_CRM_Взаимодействие] 
           CRM_ClientTouch   with (nolock) where CRM_ClientTouch.Дата  between cast(format(dateadd(year,2000,@dt),'yyyyMM01') as date) and dateadd(day,1,dateadd(year,2000,@dt))) CRM_ClientTouch
             join 
            ---# [c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия 
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия 
             dv  with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
             ----[c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] 
             stg._1cCRM.[Документ_ТелефонныйЗвонок] 
             CRM_TelCall   with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
       
       group by CRM_ClientTouch.Партнер                                                
                                

--
-- количество звонков по теме "За все время"
--
      if object_id('tempdb.dbo.#callsByTopic') is not null drop table #callsByTopic
      
      select CRM_ClientTouch.Партнер
           , Содержание
           , count(*) c 
        into #callsByTopic
        from  
       ---- [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] 
        stg._1cCRM.[Документ_CRM_Взаимодействие] 
        CRM_ClientTouch  with (nolock)
             join 
             ----[c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия 
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия 
             dv  with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
             ----[c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] 
             stg._1cCRM.[Документ_ТелефонныйЗвонок] 
             CRM_TelCall  with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
             
       group by CRM_ClientTouch.Партнер, Содержание



--
-- количество звонков по теме "за сегодня"
--
      if object_id('tempdb.dbo.#callsByTopic_today') is not null drop table #callsByTopic_today
      
      select CRM_ClientTouch.Партнер
           , Содержание
           , count(*) c 
        into #callsByTopic_today
      --  from  [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch 
          from (select Партнер ,ссылка, Содержание from  
         ---- [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] 
          stg._1cCRM.[Документ_CRM_Взаимодействие] 
          CRM_ClientTouch   with (nolock)  where  CRM_ClientTouch.Дата>=dateadd(year,2000,@dt) and CRM_ClientTouch.Дата<=dateadd(day,1,dateadd(year,2000,@dt))) CRM_ClientTouch


             join 
             ----[c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия 
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия 
             dv  with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
             ----[c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] 
             stg._1cCRM.[Документ_ТелефонныйЗвонок] 
             CRM_TelCall  with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
       
       group by CRM_ClientTouch.Партнер, Содержание



--
-- количество звонков по теме "за эту неделю"
--
      if object_id('tempdb.dbo.#callsByTopic_this_week') is not null drop table #callsByTopic_this_week
      
      select CRM_ClientTouch.Партнер
           , Содержание
           , count(*) c 
        into #callsByTopic_this_week
      --  from  [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch   with (nolock)
                from (select Партнер ,ссылка, Содержание from  
               ---- [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] 
                stg._1cCRM.[Документ_CRM_Взаимодействие] 
                CRM_ClientTouch   with (nolock)   where CRM_ClientTouch.Дата between dateadd(day,-1*datepart(dw,getdate()),dateadd(year,2000,@dt)) and dateadd(day,1,dateadd(year,2000,@dt))) CRM_ClientTouch
             join 
           ----  [c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия 
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия 
             dv  with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
            ---- [c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] 
             stg._1cCRM.[Документ_ТелефонныйЗвонок] 
             
             CRM_TelCall  with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
       --where cast(CRM_ClientTouch.Дата as date) between dateadd(day,-1*datepart(dw,getdate()),dateadd(year,2000,@dt)) and dateadd(year,2000,@dt)
       group by CRM_ClientTouch.Партнер, Содержание


--
-- количество звонков по теме "c начала месяца"
--
      if object_id('tempdb.dbo.#callsByTopic_this_month') is not null drop table #callsByTopic_this_month
      
      select CRM_ClientTouch.Партнер
           , Содержание
           , count(*) c 
        into #callsByTopic_this_month
       -- from  [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch   with (nolock)
                from (select Партнер ,ссылка, Содержание from  
               ---- [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] 
                stg._1cCRM.[Документ_CRM_Взаимодействие] 
                CRM_ClientTouch   with (nolock)     where CRM_ClientTouch.Дата  between cast(format(dateadd(year,2000,@dt),'yyyyMM01') as date) and dateadd(day,1,dateadd(year,2000,@dt))) CRM_ClientTouch
             join 
          ----   [c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия 
             stg._1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия 
             
             dv   with (nolock) on  dv.взаимодействие=CRM_ClientTouch.ссылка
	           join 
           ----  [c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] 
             stg._1cCRM.[Документ_ТелефонныйЗвонок] 
             CRM_TelCall  with (nolock) on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
    
       group by CRM_ClientTouch.Партнер, Содержание






select r.НомерЗаявки
     , CRMClientGUID                = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(p.Ссылка)  as nvarchar(64))
     , pp.Имя --Пол
     , case when 
           datediff(day,format(dateadd(year ,-2000+datediff(year,dateadd(year,-2000,r.ДатаРождения),getdate())
                                             ,r.ДатаРождения),'yyyyMMdd')
                        ,getdate())
            <0 -- день рождения еще не наступил
            then datediff(year,dateadd(year,-2000,r.ДатаРождения),getdate())-1
            else datediff(year,dateadd(year,-2000,r.ДатаРождения),getdate())
        end age
     , r.АдресПроживания
     , [Канал оформления займа]= soz.Имя
     , [Наличие/отсутствие МП/ЛК – скачал клиент приложение или нет. Смотрим за весь период жизни клиента]=''
     , [Наличие/отсутствие страховки]= s1.Код 
     , [Должник/ не должник]=cmr_p.dpd_sum
     , [Тип страховки (в будущем)]=''
     , [Наличие/отсутствие входящих звонков всего]=(select sum(CRM_ClientTouch.c) from #calls_total CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер )
     , [Наличие/отсутствие входящих звонков сегодня]=(select sum(CRM_ClientTouch.c) from #calls_today CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер )
     , [Наличие/отсутствие входящих звонков текущая неделя]=(select sum(CRM_ClientTouch.c) from #calls_this_week CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер )
     , [Наличие/отсутствие входящих звонков с начала месяца]=(select sum(CRM_ClientTouch.c) from #calls_this_month CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер )
     , [Темы обращения в RARUS (входящие звонки) всего]=( select Содержание+ ' '+format(c,'0')+', ' from #callsByTopic CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер   for xml path('') )
     , [Темы обращения в RARUS (входящие звонки) сегодня]=( select Содержание+ ' '+format(c,'0')+', ' from #callsByTopic_today CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер   for xml path('') )
     , [Темы обращения в RARUS (входящие звонки) текущая неделя]=( select Содержание+ ' '+format(c,'0')+', ' from #callsByTopic_this_week CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер   for xml path('') )
     , [Темы обращения в RARUS (входящие звонки) с начала месяца]=( select Содержание+ ' '+format(c,'0')+', ' from #callsByTopic_this_month CRM_ClientTouch where p.Ссылка= CRM_ClientTouch.Партнер   for xml path('') )



 from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС r
 join stg._1cCRM.Перечисление_СпособыОформленияЗаявок  soz on soz.ссылка=r.СпособОформления
 join stg._1cCRM. Справочник_Партнеры p on r.Партнер=p.Ссылка
 left join Stg._1cCRM.[Перечисление_ПолФизическогоЛица] pp on p.пол=pp.ссылка
 join Stg.[_1cCMR].[Справочник_Договоры] sd on  r.Ссылка=sd.заявка
 left join [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1  on  s1.[Договор]=sd.ссылка
 join #cmr_p cmr_p on cmr_p.Ссылка=sd.Ссылка
 



















 --select * from  [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch 
 --   join [c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия dv on  dv.взаимодействие=CRM_ClientTouch.ссылка
	--  join [c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] CRM_TelCall on  CRM_TelCall.Ссылка=dv.Документ_Ссылка and Входящий=0x01
 

    
    
 -- SELECT 
  
 -- ContractNo                   = MFO_Contracts.Номер 
 --      , MFOContractGUID              = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(MFO_Contracts.Ссылка)  as nvarchar(100))
 --      , dt                           = DATEADD(YEAR,-2000,CRM_ClientTouch.дата)
 --      , Comment                      = CRM_ClientTouch.Комментарий


 --      , UserFIO                      = CRM_users.Наименование 
 --      , UserEmail                    = CRM_UserSettings.Значение_Строка
 --      , CRM_ClientFIO                = CRM_Clients.Наименование

 --      , CRM_ClientPassportSerial     = CRM_Requests.СерияПаспорта
 --      , CRM_ClientOassportNo         = CRM_Requests.НомерПаспорта

 --      , CRM_ClientPassportIssueDate  = CRM_Requests.ДатаВыдачи_Паспорта

 --      , CRM_ClientPassportIssueCode  = CRM_Requests.КодПодразделения_Паспорта

 --      , CRM_ClientPassportIssuePlace = CRM_Requests.КемВыдан_Паспорт
	--   , phoneNo					  = CRM_TelCall.АбонентКакСвязаться
 --      , CRM_ClientMobilePhone        = CRM_Requests.МобильныйТелефон

 --      , CRM_ClientContactPhone       = null--CRM_Requests.ТелефонКонтактныйОсновной
 --      , CMRContractGUID              = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CMR_Contracts.Ссылка)  as nvarchar(100))
 --   --   , CMRRequestGUID   = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CMR_Requests.Ссылка)  as nvarchar(100))
 --      , CRMRequestGUID               = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Ссылка)  as nvarchar(100))
 --      , CRMClientGUID                = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CRM_Clients.Ссылка)  as nvarchar(100))
 
 --     , cast(rv.Код as varchar(256)) crm_код
 --     -- , rv.Период
 --      , rv.Успешный crm_успешный
        
 --      , CRM_ClientTouch.Содержание
      
 --into  velab.crm_buffer

 --      --drop table 

 -- FROM  #rv  rv
 --       left join [c1-vsr-sql04].crm.[dbo].[Документ_CRM_Взаимодействие] CRM_ClientTouch on rv.Ссылка=CRM_ClientTouch.РезультатCollection
	--    left join [c1-vsr-sql04].crm.[dbo].РегистрСведений_CRM_ДокументыВзаимодействия dv on  dv.взаимодействие=CRM_ClientTouch.ссылка
	--    left join [c1-vsr-sql04].crm.[dbo].[Документ_ТелефонныйЗвонок] CRM_TelCall on  CRM_TelCall.Ссылка=dv.Документ_Ссылка
 --       left join [c1-vsr-sql04].crm.[dbo].[Документ_CM_ОбещаниеОплатить] oo on   oo.ВзаимодействиеОснование=CRM_ClientTouch.Ссылка
 --       left join [c1-vsr-sql04].crm.[dbo].Справочник_Пользователи CRM_users  on  CRM_ClientTouch.Автор =CRM_users.Ссылка
 --       left join [c1-vsr-sql04].crm.[dbo].[РегистрСведений_CRM_НастройкиПользователей] CRM_UserSettings on CRM_UserSettings.Пользователь=CRM_ClientTouch.Автор and Настройка=0xB81400155D4D107811E958A304CCCF4D


 --       left join  [c1-vsr-sql04].crm.dbo.[Справочник_Партнеры] CRM_Clients on CRM_Clients.Ссылка= CRM_ClientTouch.Партнер 
 --       left join [c1-vsr-sql04].crm.[dbo].Документ_ЗаявкаНаЗаймПодПТС CRM_Requests on  CRM_Clients.Ссылка=CRM_Requests.Партнер


end 

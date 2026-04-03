
/*
-- 
select * from dm.Collection_StrategyDataMart where strategyDate=@today and external_id='20012310000087'
*/
/*
 ALTER INDEX [cl_idx_number] ON stg.[_loginom].[Dm_risk_groups] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
 exec [dm].[fill_Collection_StrategyDataMart]  @isDebug = 1
 */	
-- dwh-375
-- dwh-398
-- dwh-481
-- dwh-509
-- dwh-520
-- dwh-521
-- dwh-522
-- dwh-551
-- select * from dm.Collection_StrategyDataMart m where StrategyDate=@today and kk_flag<>0

-- [dm].[fill_Collection_StrategyDataMart] @isLogger =  1, @isDebug = 1
create       PROC [dm].[fill_Collection_StrategyDataMart_удалить_2026_04_25]
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isLogger int = 0,
	@isDebug bit = 0
as 
begin
         set nocount on 
         --exec logdb.dbo.[LogDialerEvent] 'CreateAgreementListByStrategy_dataMart_CMR','Started','','' 
         --exec logdb.dbo.[LogAndSendMailToAdmin] 'CreateAgreementListByStrategy_dataMart_CMR','Info','procedure started',N''
SET DEADLOCK_PRIORITY HIGH  
SET XACT_ABORT ON
SET DATEFIRST 1
--set statistics io on 
--set statistics time on
declare @today date = getdate()
declare @yesterday date = dateadd(dd,-1, @today)


SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
SELECT @isLogger = isnull(@isLogger, 0)     

DECLARE @StartDate datetime = getdate()
	, @row_count int  =0 
DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
DECLARE @SendEmail int
DECLARE @eventMessageText nvarchar(max) -- большое сообщение для расширенного логирования

DECLARE @dateBegin_week date, @dateEnd_week date
DECLARE @dateBegin_month date, @dateEnd_month date
	
SELECT @eventName = 'dm.fill_Collection_StrategyDataMart', @eventType = 'info', @SendEmail = 0

	

begin try


--IF @isLogger = 1 BEGIN
--	DROP TABLE IF EXISTS ##TMP_AND_CallResults_new

--	SELECT * 
--	INTO ##TMP_AND_CallResults_new
--	FROM #t_ptp_result
--END


        -- последний статус по договору

   -- последний статус по договору
 drop table if exists #CmrStatuses
 
 ;
 with last_period as 
 (
 SELECT sd.Договор deal
      , max(Период) mp
   FROM [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров]     sd
  group by sd.Договор
 )
 select d.код external_id
      , st.Наименование LastStatus
	  --DWH-1965 Флаг активности договора
	  , isActive = 
		CASE 
			WHEN st.Код IN (
				--'000000001', --	Зарегистрирован	registered
				'000000002', --	Действует	valid
				--'000000003', --	Погашен	repaid
				'000000004', --	Legal	legal
				--'000000005', --	Аннулирован	cancelled
				'000000006', --	Решение суда	judgement
				'000000007', --	Приостановка начислений	delayCalculate
				--'000000008', --	Продан	soldOut
				'000000009', --	Проблемный	problem
				'000000010', --	Платеж опаздывает	latePayment
				'000000011', --	Просрочен	expired
				'000000012' --	Внебаланс	offBalance
			)
			THEN cast(1 AS bit)
			ELSE cast(0 AS bit)
		END
		,Дата = dateadd(year,-2000,sd.Период)
			
   into #CmrStatuses
   FROM [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров]     sd
   join last_period                                           lp on lp.deal    = sd.Договор and lp.mp  = sd.Период
   join [Stg].[_1cCMR].[Справочник_Договоры]                   d on  d.Ссылка  = sd.Договор       
   join [Stg].[_1cCMR].[Справочник_СтатусыДоговоров]          st on st.Ссылка  = sd.Статус
   
   create clustered index ix_external_id on #CmrStatuses(external_id)

   --DWH-1273
	select 
	external_id = d.код,
	ДатаПродажаДоговора = iif(year(детали.Дата)>3000, 
		dateadd(year, -2000, детали.Дата), детали.Дата)
   into #t_ПродажаДоговоров
   from 
		stg.[_1cCMR].[Документ_ПродажаДоговоров] детали
	join stg._1cCMR.Документ_ПродажаДоговоров_Договоры  Договора  on Договора.[Ссылка] = детали.Ссылка
		
	join [Stg].[_1cCMR].[Справочник_Договоры] d on  d.Ссылка  = Договора.[Договор]       
	where детали.ПометкаУдаления != 0x01
		and детали.Проведен  =0x01
	order by external_id

	create clustered index ix_external_id on #t_ПродажаДоговоров(external_id)
      /*
      drop table if exists #CmrStatuses
        
        SELECT distinct  d.код external_id
             , first_value(st.Наименование) over(partition by sd.Договор order by Период desc) lastStatus
          into #CmrStatuses
          FROM [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров]     sd
          join [Stg].[_1cCMR].[Справочник_Договоры]                  d     on d.Ссылка=sd.Договор       
          join [Stg].[_1cCMR].[Справочник_СтатусыДоговоров]          st    on st.Ссылка=sd.Статус
          where d.ПометкаУдаления <>0x01
        --select * from #cmrStatuses
        --select * from #CmrStatuses where external_id='19053119610001'
        */
        -- Аналитические показатели CMR

          drop table if exists #cmr_p
          ;
          with cmr_p as (

						/*
						--var 1		 
                         select dt=dateadd(year,-2000,cast(isnull(p.дата,cmr.период) as datetime))
                              , код external_id
                              , КоличествоПолныхДнейПросрочкиУМФО dpd
                              , ПросроченнаяЗадолженность dpd_sum
                              , last_payment_date = iif(
								year(ДатаПоследнегоПлатежа)>3000, 
								dateadd(year,-2000, ДатаПоследнегоПлатежа),
								null)
                              , СуммаПоследнегоПлатежа last_payment_sum
                           from stg.[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО]  cmr
                           left join stg.[_1cCMR].[Документ_Платеж]                        p on p.ссылка=cmr.Регистратор_Ссылка
                                join stg.[_1cCMR].Справочник_Договоры                      d on d.ссылка=cmr.Договор
                          where cast(cmr.период as date)>=dateadd(day,-1,dateadd(year,2000,@today))
                          and d.ПометкаУдаления <>0x01
						*/
						 
						--var 2 --DWH-2516
                         select dt = cast(isnull(dateadd(year,-2000,p.дата),cmr.период) as datetime)
                              , d.Код AS external_id
                              , cmr.КоличествоПолныхДнейПросрочкиУМФО AS dpd
                              , cmr.ПросроченнаяЗадолженность AS dpd_sum
                              , last_payment_date = cmr.ДатаПоследнегоПлатежа
                              , cmr.СуммаПоследнегоПлатежа AS last_payment_sum
                           from Stg.dbo._1cАналитическиеПоказатели AS cmr
                           left join stg.[_1cCMR].[Документ_Платеж]                        p on p.ссылка=cmr.Регистратор_Ссылка
                                join stg.[_1cCMR].Справочник_Договоры                      d on d.ссылка=cmr.Договор
                          where cast(cmr.период as date) >= dateadd(day,-1,@today)
                          and d.ПометкаУдаления <>0x01

                         )
         , p as (select rn=row_number() over (partition by  external_id order by dt desc) 
                      , dt
                      , external_id
                      , dpd
                      , dpd_sum
                      , last_payment_date
                      , last_payment_sum 
                   from cmr_p 
                 )
          select dt
               , external_id
               , dpd
               , dpd_sum
               , last_payment_date
               , last_payment_sum
            into #cmr_p 
            from p
           where rn=1


drop table if exists #Клиент_ИНН

select GuidКлиент
	,ИНН
	,ТаблицаИсточник
into #Клиент_ИНН
from dm.v_Клиент_ИНН

create clustered index cix on #Клиент_ИНН(GuidКлиент)


	/*Договора в КА*/

drop table if exists #t_agent_credits
select * 
into #t_agent_credits
from (select  
	external_id
	,agent_name	
	,st_date
	,end_date
	,nROw = row_number() over(partition by external_id order by st_date)
from dwh_new.dbo.v_agent_credits
where @today between st_date  and end_date
) t
where nRow = 1
create clustered index cix on #t_agent_credits	(external_id)
 --Количество отказов от оплаты с 91 дня просрочки

  drop table if exists #dm_CMRStatBalance_agg_value
SELECT
	B.external_id
	,max_dpd_begin = max(dpd_begin_day) --DWH-2869
    , max_dpd_last_90d  = max(iif(B.d >= dateadd(day,-90, @today), B.dpd_begin_day, 0)) --DWH-1562
	,totalPaymentsAmtL90D = 
	sum(iif(b.d between dateadd(dd,-90, getdate()) and @today, 	b.[сумма поступлений], 0)) --DWH-2563 (--платежи за последние 90 дней BP-4315)
	,endDate = min(b.ContractEndDate) --DWH-1965 endDate - дата когда договор стал не активным
	,maxDateWithdpd91=max(iif(b.dpd = 91, b.d, null))--дата когда dpd = 91
INTO #dm_CMRStatBalance_agg_value
FROM dbo.dm_CMRStatBalance AS B (NOLOCK)
GROUP BY B.external_id

create clustered index cxi on #dm_CMRStatBalance_agg_value(external_id)
drop table if exists #t0

  select  external_id= cast(d.Код as nvarchar(50))
       , CMRContractGUID= cast(dbo.getGUIDFrom1C_IDRREF(d.Ссылка)  as char(64))
       , CRMClientGUID =  cast(dbo.getGUIDFrom1C_IDRREF(d.Клиент)  as char(64))
       , fio= 
	   concat_ws(' ', 
		coalesce(
			 TRIM(p.CRM_Фамилия)
			,TRIM(d.фамилия)
			)
		,coalesce(
			TRIM(p.CRM_Имя)
			,TRIM(d.Имя)
			)
		,coalesce(
			TRIM(p.CRM_Отчество)
			,TRIM(d.Отчество)
			)
			)
		
	   , [last_name] =	coalesce(
			 TRIM(p.CRM_Фамилия)
			,TRIM(d.фамилия)
			)
	   , [first_name] = coalesce(
			TRIM(p.CRM_Имя)
			,TRIM(d.Имя)
			)
	   , [patronymic] = coalesce(
			TRIM(p.CRM_Отчество)
			,TRIM(d.Отчество)
			)
       , birth_date=
			coalesce (
				iif(year(p.ДатаРождения)>3000,  dateadd(year,-2000,p.ДатаРождения), null)
				,iif(year(d.ДатаРождения)>3000,  dateadd(year,-2000,d.ДатаРождения), null)
				,d.ДатаРождения
				)
       , credit_date=case when d.Дата>'30000101'  then dateadd(year,-2000,d.Дата) else d.Дата end
       , credit_amount=d.Сумма
       --, fraud_flag	=     (case when b.external_id is not null then 1 else 0 end) 
       , agent_flag	 = iif(ac.external_id is not null, 1,0)
       , ac.agent_name 
       , overdue_amount=bal.overdue
       , principal_rest=bal.[остаток од]
       , total_rest	=bal.[остаток всего]
       , dpd	=bal.dpd_begin_day                     
       , d.ТелефонМобильный	                      
	   , КредитныеПродукт=  кп.Наименование
	   , IsInstallment =isnull(d.IsInstallment, 0)
	   , IsSmartInstallment = isnull(d.IsSmartInstallment, 0)
		--iif(charindex('Installment', кп.Наименование) >0, 1, 0)
       , next_payment_amount = bal.[остаток всего] --DWH-1691
       , Product_type = case lower(cmr_ПодтипыПродуктов.ИдентификаторMDS)
			when 'pdl' then 'PDL'
			else    ГруппаПродуктов.ГруппаПродуктов_Наименование
			end
		--DWH-1805 Просроченные проценты (Начисленные на дату, но не уплаченные)
		,Overdue_Interest = 
			iif(isnull(bal.dpd, 0) > 0,
				bal.[Проценты начислено  нарастающим итогом] - bal.[Проценты уплачено  нарастающим итогом],
				0
			)
		,segment_code = Сегмент.ИмяСегмента
		,segment_name = Сегмент.Наименование
		,Client_inn   =  Клиент_ИНН.ИНН --
		,hasBeenInKa = iif(t_TotalInKA.TotalInKA>0,1, 0) --Договор ранее был в КА за любой период жизни договора BP-4315
		,total_payments  = bal.[сумма поступлений  нарастающим итогом]
		, Product_SubTypeName  = cmr_ПодтипыПродуктов.Наименование
		, Product_SubTypeCode  = cmr_ПодтипыПродуктов.ИдентификаторMDS

       into #t0
       from [Stg].[_1cCMR].[Справочник_Договоры] d 
	   left join stg.[_1cCMR].Справочник_КредитныеПродукты кп on кп.Ссылка = d.КредитныйПродукт

	   inner join [Stg].[_1cCMR].[Справочник_Заявка] cmr_Заявка
			on cmr_Заявка.Ссылка = d.Заявка
		left join [Stg].[_1cCMR].[Справочник_ПодтипыПродуктов] cmr_ПодтипыПродуктов
			on cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка	
		left join dwh2.hub.v_hub_ГруппаПродуктов   ГруппаПродуктов 
			on ГруппаПродуктов.ПодтипПродуктd_Code = cmr_ПодтипыПродуктов.ИдентификаторMDS

	--Данные в _1ccrm.Справочник_Партнеры более актуальные чем в договоре 
       left join stg._1ccrm.Справочник_Партнеры p on d.Клиент=p.Ссылка
    --   left join (select distinct external_id from fraudsters) b on d.Код = b.external_id
		left join #t_agent_credits	ac on ac.external_id = d.Код
	/*	  старый код, оставили для истории
       left join (select a.external_id,a.agent_name,b.agent_flag 
                    from dwh_new.dbo.v_agent_credits a
							      join (select external_id
                               , sign(sum(case when @yesterday >= start_date
											                  and @yesterday <= end_date then 1 else 0 end)) as agent_flag
                            from (select external_id
                                       , agent_name
                                       , cast([st_date] as date) as start_date
                                       , (case when end_date is null then @today else end_date end) as end_date
                                    from dwh_new.dbo.v_agent_credits a where a.agent_name<>'ACB'
                                  ) a
                            group by external_id
                           ) b on a.external_id = b.external_id and b.agent_flag = 1
                           and a.agent_name<>'ACB'
                    ) d1 on d.Код = --format(d1.external_id,'0')
                    d1.external_id	   */
        LEFT JOIN  dbo.dm_CMRStatBalance bal on bal.external_id=d.Код and bal.d=@today
		LEFT JOIN stg._1cCMR.Справочник_Сегменты Сегмент
			on Сегмент.Ссылка = nullif(cmr_Заявка.Сегмент, 0x)
		
		
		left join #Клиент_ИНН Клиент_ИНН  on Клиент_ИНН.GuidКлиент 
			= dbo.getGUIDFrom1C_IDRREF(d.Клиент)
		--BP-4315 --Договор ранее был в КА за любой период жизни договора
		left join (
			select DealNumber = External_id, TotalInKA = count(1)  
			from dwh_new.dbo.agent_credits -- 11/09/2025 правка - ранее было GearsToKAView - таблица не акутальная
			where reestr is not null
			group by External_id
		) t_TotalInKA on t_TotalInKA.DealNumber = d.Код
	  
	  where d.ПометкаУдаления <>0x01
		and not exists(select top(1) 1 from #CmrStatuses s
			where s.external_id =  cast(d.Код as nvarchar(50))	
				and s.LastStatus in('Зарегистрирован')
			)
	CREATE CLUSTERED INDEX clix_external_id ON #t0(external_id)	
	
	
	
	/*
-- DWH-817 
-- исключим все  обещания где они по факту оплата, исключаем недозвон для уменьшения выборки, 
-- исключаем отложенные обещания
	drop table if exists #com_call_res
	select distinct Number
	, PromiseSum=case when naumen<>'payed' then PromiseSum else null end
	, PromiseDate=case when naumen<>'payed' then PromiseDate else null end
	, Контакт,communicationType, CommunicationDate
	, CommunicationResult
	into #com_call_res
	from stg._Collection.mv_Communications com
	left join stg._Collection.[CommunicationResult] res on res.id=com.CommunicationResultId
	where isnull(CommentaryShort,'')<>'Недозвон Dialer'
	and isnull(CommunicationResultId,0) <> 93 --исключае отложенные обещания


*/
--Измнение алгоритма в рамках DWH-529
	drop table if exists #com_call_res_buf
	select distinct 
	 external_id = Number
	, PromiseSum
	, PromiseDate
	, communicationType
	, CommunicationDate
	, CommunicationResult
	, naumen
	into #com_call_res_buf
	from stg._Collection.mv_Communications com
	left join stg._Collection.[CommunicationResult] res on res.id=com.CommunicationResultId
	where isnull(CommentaryShort,'')<>'Недозвон Dialer'
	and  CommunicationResult in ('Отложенное обещание', 'Обещание оплатить')
	and number is not null

	create clustered index cix on #com_call_res_buf(external_id)

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #com_call_res', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END


   /*
-- находим последнее обещание по договору и сумму
drop table if exists #CallResults_new
;
with agr as  (
  select Number agrNo
       , [PTP Date] = max(isnull([PromiseDate],'19000101'))
  from #com_call_res
  group by Number
) 
,with_PTPDay as
(
select 
       agrNo=Number
     , [PTP Date]=a.[PTP Date]
     , PTP=max(PromiseSum)
  FROM #com_call_res r
  join agr a on a.agrNo=r.Number and cast(a.[PTP Date] as date)=cast(r.[PromiseDate] as date)
  group by Number,a.[PTP Date]
)
*/
drop table if exists #t_ptp_result
--Ранжирование, если в рамках дня были идинаковые коммуникации с разным результатом, то оложенное обещание берется крайним
;with cte_last_call_res as (
select *
   ,[PTP Date] = PromiseDate
   ,PTP=  PromiseSum
   ,nRow = Row_number() over (partition by external_id
	order by CommunicationDate desc, case CommunicationResult 
	when  'Отложенное обещание' then 999
	else 1	end
	) --
from #com_call_res_buf


)

-- находим последнее обещание по договору и сумму
select r.external_id
     , [PTP Date] = cast(isnull(ptp.[PTP Date],'19000101') as date)
     , PTP=isnull(ptp.PTP,0)
     --, [Num_RPC in Cur_date]=Cur_date.TotalRow
     --, [Num_RPC in (Cur_date-7;Cur_date)] =[Cur_date-7].TotalRow
     --, [Num_RPC in (Cur_date-30;Cur_date)] =[Cur_date-30].TotalRow
	 --, [Num_RPC <30] =[>30].TotalRow
     into #t_ptp_result
  FROM  #t0 r
  left join cte_last_call_res ptp on r.external_id=ptp.external_id
  and ptp.nRow =1 
  /*
  left join
  (
		select TotalRow = count(distinct id_1), r1.Number
			from stg._Collection.mv_Communications  r1 
			where Контакт='Да'  
				and cast([CommunicationDate] as date)=@today
		group by  r1.Number
  )  Cur_date on Cur_date.Number = r.Number 
  left join 
  (
	select TotalRow = count(distinct id_1) , r1.Number
		from  stg._Collection.mv_Communications  r1 
		where communicationType='Исходящий звонок'  
			and  CommunicationResult not in ('Оставлено сообщение 3-му лицу','Отказ от разговора 3-е лицо') 
			and Контакт='Да'  
			and cast([CommunicationDate]  as date) between dateadd (day,-7,@today) and @today
		group by  r1.Number
   ) [Cur_date-7]  on  [Cur_date-7].Number= r.Number 
   left join
   (
	select
		TotalRow = count(distinct id_1) , r1.Number
		from  stg._Collection.mv_Communications  r1 
			where  communicationType='Исходящий звонок'  
				and  CommunicationResult not in ('Оставлено сообщение 3-му лицу','Отказ от разговора 3-е лицо') 
				and Контакт='Да'   
				and cast([CommunicationDate]  as date) between dateadd (day,-30,@today) and @today
		group by  r1.Number
	) [Cur_date-30] on [Cur_date-30].Number = r.Number
	left join 
	(
		select TotalRow = count(distinct id_1), r1.Number
		from  stg._Collection.mv_Communications r1 
		where communicationType='Исходящий звонок'  
		and  CommunicationResult not in ('Оставлено сообщение 3-му лицу','Отказ от разговора 3-е лицо') 
		and Контакт='Да' 
		and cast([CommunicationDate]  as date)<dateadd (day,-30,@today)
		group by  r1.Number
	) [>30] on [>30].Number = r.Number

	*/
	create clustered index cix on #t_ptp_result(external_id)
SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #t_ptp_result', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END



	
	select 
		ПДН.GuidДоговораЗайма
		,external_id = ПДН.КодДоговораЗайма
		,PDN = cast(ПДН.PDN as money)
	into #t_ПДН
	from 
	(select 
		t.CMRContractGUID
		,Дата_с = min(Дата_с)

	from #t0 t
	inner join dwh2.[sat].[ДоговорЗайма_ПДН] ПДН
		on ПДН.КодДоговораЗайма = t.external_id
		and t.credit_date between ПДН.Дата_с and ПДН.Дата_ПО
		where Система = 'УМФО'
	group by CMRContractGUID
	)   t_ПДН
	inner join dwh2.[sat].[ДоговорЗайма_ПДН] ПДН
		on ПДН.GuidДоговораЗайма = t_ПДН.CMRContractGUID
		and ПДН.Дата_с = t_ПДН.Дата_с
	where Система = 'УМФО'
	create clustered index cix_ on #t_ПДН(external_id)


	delete from #t0 where charindex('тест',fio)>0
		--Договора исключили т.к. реальный клиенты с ФИО Тест*

		and external_id not in ('24050302025421' -- (ТЕСТОВ СТАНИСЛАВ ВИКТОРОВИЧ
			, '21121420161992' -- ТЕСТИК ДМИТРИЙ СЕРГЕЕВИЧ
			, '24030501836475'--ТЕСТОВА КСЕНИЯ ИГОРЕВНА
			)
	CREATE INDEX IX_CRMClientGUID ON #t0(CRMClientGUID)

	
  
	--IF @isLogger = 1 BEGIN
	--	DROP TABLE IF EXISTS Stg.tmp.TMP_AND_t0

	--	SELECT * 
	--	INTO Stg.tmp.TMP_AND_t0
	--	FROM #t0
	--END

  ---
  -- CRM
  ---
  drop table if exists #crm_info 
 

          SELECT 
                 НомерЗаявки                  =     Док.НомерЗаявки
               , [timeZoneGMT+]               =     br.CRM_ВремяПоГринвичу_GMT--чп.ОтклонениеОтМосковскогоВремени + 3 
               , РегионФактическогоПроживания =     br.Наименование
               , RegionRegistration           =     br1.Наименование
               , RegionRegistration_code      =     br1.КодРегиона
               , док.ЭлектроннаяПочта
			   , isSetSoftWare				  = iif(
							t.IsSmartInstallment = 1 and НаличиеУстановленногоПо.СтатусУстановкиПО = 'Установлено', 
								1, 0)
			   ,SoftWare_installed_date = iif(t.IsSmartInstallment = 1 
					and НаличиеУстановленногоПо.СтатусУстановкиПО = 'Установлено', 
								НаличиеУстановленногоПо.дата, null)
				,SoftWare_removed_date = iif(t.IsSmartInstallment = 1 
					and НаличиеУстановленногоПо.СтатусУстановкиПО = 'СнятоПоЗаявлениюКлиента', 
								НаличиеУстановленногоПо.дата, null)
            into #crm_info 
            FROM stg._1cCRM.[Документ_ЗаявкаНаЗаймПодПТС]     Док
			inner join #t0 t on Док.НомерЗаявки=t.external_id
            left join stg._1cCRM.[Справочник_Партнеры]    s       on s.Ссылка       = Док.Партнер
            left join stg._1cCRM.[Справочник_БизнесРегионы] br      on br.Ссылка      = s.РегионФактическогоПроживания
            left join stg._1cCRM.[Справочник_БизнесРегионы]  br1      on br1.Ссылка      = s.БизнесРегион
			
			left join (
				select 
	
					регистр.Заявка,
					 дата = dateadd(year,-2000, регистр.Период),
					СтатусУстановкиПО = set_app.Имя

				from 
				(
					select Период = max(Период), Заявка from stg._1cCrm.РегистрСведений_НаличиеУстановленногоПо
					group by Заявка
				) t_last
				inner join stg._1cCrm.РегистрСведений_НаличиеУстановленногоПо регистр 
					on регистр.Заявка = t_last.Заявка
					and регистр.Период = t_last.Период
				inner join stg._1cCRM.Перечисление_НаличиеУстановленногоПО set_app on set_app.Ссылка = регистр.СтатусУстановкиПО
			) НаличиеУстановленногоПо on НаличиеУстановленногоПо.Заявка = Док.Ссылка
			 
			 -- select * from stg._1cCRM.Перечисление_НаличиеУстановленногоПО
            where Док.НомерЗаявки<>'' 
		

      --exec logdb.dbo.[LogDialerEvent] 'CreateAgreementListByStrategy_dataMart_CMR','step CRM completed','','' 
      --exec logdb.dbo.[LogAndSendMailToAdmin] 'CreateAgreementListByStrategy_dataMart_CMR','Info','step CRM Completed',N''

--IF @isLogger = 1 BEGIN
--	DROP TABLE IF EXISTS ##TMP_AND_crm_info

--	SELECT * 
--	INTO ##TMP_AND_crm_info
--	FROM #crm_info
--END


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



drop table if exists #hist_91

;with clients as (
 
	--var 2 --DWH-2516
	SELECT DISTINCT
		B.external_id
		--, КоличествоПолныхДнейПросрочки = B.dpd
	FROM dbo.dm_CMRStatBalance AS B (NOLOCK)
	WHERE B.dpd_begin_day >= 91 --DWH-2926 изменили условие на >=91

)
select distinct  c.external_id
into #hist_91
from clients c
join #t0 t on t.external_id=c.external_id


--last_rpc_date	последняя дата контакта с клиентом   
  drop table if exists #last_rpc_date
   
  select CrmCustomerId
       , max(CommunicationDate) last_rpc_date
    into #last_rpc_date
    from Stg._collection.mv_Communications
   where Контакт='Да'

 group by CrmCustomerId

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #last_rpc_date', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END
 


--last_call_att_date	дата последней попытки звонка (контактные/ неконтактные)
drop table if exists #last_call_att_date
  select CrmCustomerId
       , max(CommunicationDate) last_call_att_date
  into #last_call_att_date
    from Stg._collection.mv_Communications
   --where Контакт='Да'

 group by CrmCustomerId



--  num att	кол-во попыток звонков (за всю историю, контактные и неконтактные попытки)


  if object_id('tempdb.dbo.#num_att') is not null 
  drop table if exists #num_att
  select CrmCustomerId
       , count(CommunicationDate) cnt
  into #num_att
    from Stg._collection.mv_Communications
   --where Контакт='Да'

 group by CrmCustomerId

 
--plan_date	дата планового платежа по графику (если график закончился - 31.12.3000)
--В рамках задачи DWH-1149 добавили 2 поля - 
	drop table if exists #t_ДанныеГрафикаПлатежей
	drop table if exists #plan_date
	select 
		d.Код,
		d.Ссылка as ДОГОВОР,

		g.Период,
		Регистратор = g.Регистратор_Ссылка,
		g.ДатаПлатежа,
		g.СуммаПлатежа,
		max(ДатаПлатежа) over(partition by d.Ссылка, g.Период) as end_date_payment_schedule
		
	into #t_ДанныеГрафикаПлатежей
	from stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей] g
           join stg._1cCMR.Справочник_Договоры d on g.Договор=d.Ссылка
	where  d.ПометкаУдаления <>0x01
           and g.СуммаПлатежа<>0.00

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #t_ДанныеГрафикаПлатежей', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END



   drop table if exists #plan_date

	--Берем последний график из Документ_ГрафикПлатежей, т.к. в РегистрСведений_ДанныеГрафикаПлатежей не всегда верная дата стоит, возможно без времени
;with cte_Документ_ГрафикПлатежей as 
(
	select s.Договор, s.Ссылка, s.Дата 
	From stg._1cCMR.Документ_ГрафикПлатежей s 
	inner join (select Договор, max(Дата) as dd from stg._1cCMR.Документ_ГрафикПлатежей t
	where exists(select top(1) 1 from #t_ДанныеГрафикаПлатежей tt where tt.ДОГОВОР = t.Договор
		and tt.Регистратор = t.Ссылка)
		group by Договор
	) t on s.Договор = t.Договор
		and s.Дата = t.dd
), max_registrator as (  select t.ДОГОВОР, t.Регистратор, max(s.Дата) Дата
	from #t_ДанныеГрафикаПлатежей t
	inner join cte_Документ_ГрафикПлатежей   s on s.Договор = t.Договор
		and s.Ссылка = t.Регистратор
group by  t.ДОГОВОР, t.Регистратор)    
       , next_payment_dates as (
                                 SELECT g.ДОГОВОР
                                      , min(g.ДатаПлатежа) mn_dt
                                      , g.Регистратор
                                   FROM #t_ДанныеГрафикаПлатежей g
                                   join max_registrator mr on mr.ДОГОВОР=g.ДОГОВОР and 
									g.Регистратор = mr.Регистратор
									--g.Период =mr.Период
                                  where ДатаПлатежа>=dateadd(year,2000,@today)
                                 
                               --   and Действует=0x01
                               group by g.ДОГОВОР, g.Регистратор
                                )
      , prev_payment_date as (
                                 SELECT g.ДОГОВОР
                                      , max(ДатаПлатежа) mn_dt
                                      , g.Регистратор
                                   FROM #t_ДанныеГрафикаПлатежей g
                                   join max_registrator mr on mr.ДОГОВОР=g.ДОГОВОР 
									and g.Регистратор = mr.Регистратор
								   --and g.Период =mr.Период
                                  where ДатаПлатежа<dateadd(year,2000,@today)
                                 
                               --   and Действует=0x01
                               group by g.ДОГОВОР, g.Регистратор
                                )
 select distinct
	g.код external_id
      , paymentDate = iif(year(g.ДатаПлатежа)>3000, dateadd(year,-2000, g.ДатаПлатежа), null)
	    , g.СуммаПлатежа paymentSum
      , g_prev.ДатаПлатежа prev_paymentDate
      , g_prev.СуммаПлатежа prev_paymentSum
	  , prev_график_платежей.change_date_plan_date as change_date_plan_date  --Если был график пред платежей, то берем дату текущего, иначе null /* дата изменения Даты платежа*/ 
	  , prev_график_платежей.СледующаяДатаПлатежа as old_plan_date /*старая Дата платежа, которая была в поле plan_date в дату изменения*/
	  , g.end_date_payment_schedule /*дата самого последнего платежа по графику) DWH-1155*/
   into #plan_date
   FROM max_registrator mr
	inner join 
	(
		select g.код,
			g.Договор,
			g.end_date_payment_schedule,
			g.Регистратор,
			min(iif(npd.ДОГОВОР is not null, g.ДатаПлатежа, null)) ДатаПлатежа,--Плановая дата платежа 
		    sum(iif(npd.ДОГОВОР is not null, g.СуммаПлатежа, null)) as СуммаПлатежа --Плановая сумма платежа

			from #t_ДанныеГрафикаПлатежей g
			left join next_payment_dates npd on npd.Договор=g.Договор
				and npd.mn_dt=g.ДатаПлатежа 

				and npd.Регистратор=g.Регистратор
			group by  g.код,
			g.Договор,
			g.Регистратор,
			g.end_date_payment_schedule
			
	) g on g.Договор = mr.Договор
		and g.Регистратор = mr.Регистратор
		

    left join  prev_payment_date ppd on ppd.ДОГОВОР=mr.ДОГОВОР
		
	left join #t_ДанныеГрафикаПлатежей g_prev on 
		g_prev.Договор=mr.Договор 
		and g_prev.Регистратор=ppd.Регистратор 
		and ppd.mn_dt=g_prev.ДатаПлатежа
	left join 
	(
		select 
		л.Договор,
		max(Дата) as change_date_plan_date,
		max(л.СледующаяДатаПлатежа) as СледующаяДатаПлатежа,
		max(л.НоваяДатаПлатежа) as НоваяДатаПлатежа
		from Stg.[_1cCMR].[Документ_ОбращениеКлиента] л
		where л.ПометкаУдаления <>0x01
		and л.ВидОперации = 0x9CB79B770BF013014F3165845D8CE72C 
		and СледующаяДатаПлатежа <> '2001-01-01 00:00:00'
	 	group by Договор
	)prev_график_платежей on prev_график_платежей.Договор = mr.ДОГОВОР

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #plan_date', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END

   --select * from #plan_date where external_id='18092124190002'
   --select * from #plan_date where external_id='19010813370001'
   

--first payment (0/1)	1 - первый платёж по графику (либо предстоящий для Pre del, либо просроченный для Soft), 0 - нет


  /*
dwh-398
Флаг "Первый Платеж"
/*DWH-1324 изменили логику в рамках задачи*/

*/
drop table if exists #paymentInfo
select 
	t0.external_id
	,first_payment_flag  = iif(@today > first_payment_date, 0, 1)
	,first_payment = iif(first_payment_date>@today, 1, 0)   
	,paymentPeriod
into #paymentInfo
from #t0  t0
inner join (select 
	external_id= Код 
	,first_payment_date = min(ДатаПлатежа) 
	,paymentPeriod = isnull(min(iif(ДатаПлатежа>getdate(), НомерПлатежа, null)), max(НомерПлатежа)) --плажный период, DWH-2625
	from dm.CMRExpectedRepayments
	group by Код 
)  f_p on f_p.external_id = t0.external_id
where 1=1




 -- if object_id('tempdb.dbo.#first_payment') is not null drop table #first_payment

 --select Number external_id
 --     , case when FirstPaymentDate> dateadd(year,2000,@today) then 1 else 0 end     first_payment
 --  into #first_payment
 --  from #first_payment_by_number

 

   drop table if exists #_pd
   select 
		external_id = dm.Number
		, fpd0 = dm.fpd0
        , spd0 = dm.spd0
        , tpd0 = dm.tpd0
		, fpd4	= dm.fpd4
		, fpd30 = dm.fpd30
		, fpd60 = dm.fpd60
   into #_pd
   from #t0 t
   inner join dbo.dm_OverdueIndicators dm
		on  dm.Number = t.external_id
	
 --/dwh-578

--телефонные номера для исключения - все 
/*
if object_id('tempdb.dbo.#allPhonesForExclude') is not null drop table #allPhonesForExclude
  select distinct right(Телефон,10) phone
    into #allPhonesForExclude
  --  select * 
    from stg.[files].[vphones4Exclude]-- where Телефон='9525691477'

  union  
  select phoneNumber 
    fromdm.vThirdPersonContact_ExcludePhones

    */
    /*
    select*
 from stg.dbo.dm_NotActualSpacePhones   where phonesOfClient_phone='9525691477'
      */
-- телефонные номера для исключения   кроме мобильного номера клиента
/*
if object_id('tempdb.dbo.#PhonesForExclude_exceptClientMobile') is not null drop table #PhonesForExclude_exceptClientMobile
select distinct right(Телефон,10) Телефон into #PhonesForExclude_exceptClientMobile from stg.[files].[vphones4Exclude]
*/

--select * from #allPhonesForExclude where phone='9525691477'





  /*
  
  dwh-398
  Флаг "Отзыв данных Работодателем"

  */
  drop table if exists #workPhoneNotActual
  ;with phones as 
  (
    select t.CRMClientGUID
         , ContactPhone
         , isOperative
      from #t0 t 
      join stg._collection.v_ClientPhones p on p.CRMClientGUID=t.CRMClientGUID 
     where ContactPhoneType='Телефон рабочий' --and isOperative=0
    )
  , cnt as 
    (
      select CRMClientGUID
           , cnt_isoperative=sum(cast(isOperative as int))
           , cnt_isNotOperative =count(case when isOperative=0 then 1 else 0 end)
        from phones
       group by CRMClientGUID
    )
    select CRMClientGUID into #workPhoneNotActual from cnt where cnt_isoperative=0

/*

dwh-398
Флаг "Наличие отказа от оплаты за последние 14 дней"

*/

  drop table if exists #reject_paymet_last14days

  select distinct CrmCustomerId
    into #reject_paymet_last14days
    from #t0 t 
    join stg._Collection.mv_Communications c on c.CrmCustomerId=t.CRMClientGUID
   where CommunicationDateTime>=dateadd(day,-14,@today) and CommunicationResult='Отказ от оплаты'


/*
dwh-398

Флаг "Наличие обещания за последние 14 дней"
*/

  drop table if exists #ptp_last14days

  select  distinct CrmCustomerId
    into #ptp_last14days
    from #t0 t 
    join stg._Collection.mv_Communications c on c.CrmCustomerId=t.CRMClientGUID
   where CommunicationDateTime>=dateadd(day,-14,@today) and CommunicationResult='Обещание оплатить'

--dwh-675

  drop table if exists #ptp_otl

  select CRMClientGUID,max(promisedate)  promisedate
  into #ptp_otl
    from #t0 t 
    join stg._Collection.mv_Communications c on c.CrmCustomerId=t.CRMClientGUID
   where CommunicationDateTime>='20200910' and CommunicationResult ='Отложенное обещание'
   group by CRMClientGUID




/*
dwh-398 Дата последней попытки дозвона должнику (моб тел клиента или домашний, но именно с клиентом)
select  distinct ContactPhoneType from stg._collection.v_ClientPhones p 
select distinct CommunicationType from stg._Collection.mv_Communications c 
select * from stg._Collection.mv_Communications c 
join stg._collection.v_ClientPhones p on c.PhoneNumber=p.

where CommunicationDate>=dateadd(day,-14,@today) and
PersonType='Клиент' and CommunicationType='Исходящий звонок'
*/
  drop table if exists #last_attempt_date_home_mob
  select CRMClientGUID
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_attempt_date_home_mob
    from stg._Collection.mv_Communications c 
    join stg._collection.v_ClientPhones p on c.PhoneNumber=p.ContactPhone

   where --CommunicationDate>=dateadd(day,-14,@today) and
         PersonType='Клиент' and CommunicationType='Исходящий звонок'
     and ContactPhoneType in ('Мобильный телефон','Телефон мобильный', 'Мобильный телефон дополнительный','мобильный','Домашний телефон','Телефон домашний')
group by CRMClientGUID

/*
dwh-398
Дата последней попытки дозвона работодателю

*/

drop table if exists #last_attempt_date_work
  select CRMClientGUID
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_attempt_date_work
    from stg._Collection.mv_Communications c 
    join stg._collection.v_ClientPhones p on c.PhoneNumber=p.ContactPhone

   where --CommunicationDate>=dateadd(day,-14,@today) and
         PersonType='Клиент' and CommunicationType='Исходящий звонок'
     and ContactPhoneType in  ('Телефон руководителя рабочий','Рабочий телефон','Телефон рабочий','Офис')
group by CRMClientGUID


/*
dwh-398
Дата последней попытки дозвона работодателю

*/

drop table if exists #last_contact_date_work
  select CRMClientGUID
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_contact_date_work
    from stg._Collection.mv_Communications c 
    join stg._collection.v_ClientPhones p on c.PhoneNumber=p.ContactPhone

   where PersonType='Клиент' and CommunicationType='Исходящий звонок'
     and ContactPhoneType in  ('Телефон руководителя рабочий','Рабочий телефон','Телефон рабочий','Офис') and Контакт='Да'
group by CRMClientGUID


/*
dwh-398
Дата последней попытки дозвона контактному лицу
*/

drop table if exists #last_attempt_date_thd
  select CrmCustomerId
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_attempt_date_thd
    from stg._Collection.mv_Communications c 
    
   where PersonType='Третье лицо' and CommunicationType='Исходящий звонок'
    
group by CrmCustomerId

/*
dwh-398
Дата последнего контакта с 3-им лицом
*/

drop table if exists #last_contact_thd
  select c.CrmCustomerId
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_contact_thd
    from stg._Collection.mv_Communications c 
  where PersonType='Третье лицо' and CommunicationType='Исходящий звонок' and Контакт='Да'
group by c.CrmCustomerId


/*
dwh 398
Дата последней попытки связать в мессенджере

Мессенджеры
*/

drop table if exists #last_attempt_messengers
  select c.CrmCustomerId
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_attempt_messengers
    from stg._Collection.mv_Communications c 
    

   where --CommunicationDate>=dateadd(day,-14,@today) and
          CommunicationType='Мессенджеры'
     
group by c.CrmCustomerId
/*
dwh-398
Дата последнего контакта в мессенджерах

*/

drop table if exists #last_contact_messengers
  select c.CrmCustomerId
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_contact_messengers
    from stg._Collection.mv_Communications c 
    

   where CommunicationType = 'Мессенджеры'
     and Контакт='Да'
group by c.CrmCustomerId




/*
dwh-398
Дата последнего контакта skip

*/

drop table if exists #last_contact_SKIP
  select c.CrmCustomerId
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_contact_SKIP
    from stg._Collection.mv_Communications c 
    

   where --CommunicationDate>=dateadd(day,-14,@today) and
         CommunicationType = 'SKIP'
    -- and Контакт='Да'
group by c.CrmCustomerId

/*
dwh-398
Дата последнего Выезд

*/

drop table if exists #last_contact_meet
  select c.CrmCustomerId
       , max(c.CommunicationDate) max_CommunicationDate
    into #last_contact_meet
    from stg._Collection.mv_Communications c 
    

   where --CommunicationDate>=dateadd(day,-14,@today) and
         CommunicationType = 'Выезд'
    -- and Контакт='Да'
group by c.CrmCustomerId




/*

select distinct external_id 
into #first_payment_flag
from #t0 where credit_date>=dateadd(day,-35,@today)
where credit_date>=dateadd(day,-35,@today)
*/


/*
dwh-398
Кол-во попыток дозвона за последние 5 дней (клиент)

*/
  drop table if exists #cnt_calltry_last5d
  select CrmCustomerId
       , count(distinct c.id_1) cnt
    into #cnt_calltry_last5d
    from stg._Collection.mv_Communications c 
   -- join stg._collection.v_ClientPhones p on c.PhoneNumber=p.ContactPhone

   where CommunicationDate>=dateadd(day,-5,@today) and
         PersonType='Клиент' and CommunicationType='Исходящий звонок'
     --and ContactPhoneType in ('Мобильный телефон','Телефон мобильный', 'Мобильный телефон дополнительный','мобильный','Домашний телефон','Телефон домашний')
group by CrmCustomerId


/*
dwh-398
Кол-во попыток дозвона за последние 3 дня (клиент)

*/
  drop table if exists #cnt_calltry_last3d
  select CrmCustomerId
       , count(distinct c.id_1) cnt
    into #cnt_calltry_last3d
    from stg._Collection.mv_Communications c 
   -- join stg._collection.v_ClientPhones p on c.PhoneNumber=p.ContactPhone

   where CommunicationDate>=dateadd(day,-3,@today) and
         PersonType='Клиент' and CommunicationType='Исходящий звонок'
     --and ContactPhoneType in ('Мобильный телефон','Телефон мобильный', 'Мобильный телефон дополнительный','мобильный','Домашний телефон','Телефон домашний')
group by CrmCustomerId

/*
dwh-398
Кол-во попыток дозвона за последние 3 дня (контактное лицо)


*/
  drop table if exists #cnt_calltry_last3d_cl
  select CrmCustomerId
, count(distinct c.id_1) cnt
    into #cnt_calltry_last3d_cl
    from stg._Collection.mv_Communications c 
   -- join stg._collection.v_ClientPhones p on c.PhoneNumber=p.ContactPhone

   where CommunicationDate>=dateadd(day,-3,@today) and
         PersonType='Третье лицо' and CommunicationType='Исходящий звонок'
     --and ContactPhoneType in ('Мобильный телефон','Телефон мобильный', 'Мобильный телефон дополнительный','мобильный','Домашний телефон','Телефон домашний')
group by CrmCustomerId


/*
dwh-398
Кол-во попыток дозвона за последние 3 дня рабочий номер


*/
  drop table if exists #cnt_calltry_last3d_work
  select CrmCustomerId
           , count(distinct c.id_1) cnt
    into #cnt_calltry_last3d_work
    from stg._Collection.mv_Communications c 
    join stg._collection.v_ClientPhones p on c.PhoneNumber=p.ContactPhone

   where CommunicationDate>=dateadd(day,-3,@today) and
         PersonType='Клиент' and CommunicationType='Исходящий звонок'
     and ContactPhoneType in ('Телефон руководителя рабочий','Рабочий телефон','Телефон рабочий','Офис')
group by CrmCustomerId


/*
dwh-398

Флаг "Наличие нарушенного обещания за последние 14 дней"


*/

  drop table if exists #broked_ptp_last_14days

  select distinct t.CRMClientGUID 
    into #broked_ptp_last_14days

    from reports.collection.dm_CollectionKPIByMonth o 
    join #t0 t on o.НомерДоговора=t.external_id
   where o.дата>=dateadd(day,-14,@today) and o.ДатаОбещания<@today and o.ptpDateBalance>0 and o.success_PTP_new =0

/*
dwh-398
Сумма оплаты с даты взятия обещания по текущую дату (или по дату обещания)
--DWH-192
*/
drop table if exists #ptp_payments
;With payments as (
  SELECT de.Код external_id
       , dateadd(year,-2000,cast(g.Дата as date)) dt
       , sum(g.Сумма) summ
    
    from stg.[_1cCMR].[документ_платеж] g
    join stg.[_1cCMR].Справочник_Договоры de on de.ссылка= g.Договор
	where exists(select top(1) 1 from #t0 t where t.external_id = de.Код)
   group by de.Код,dateadd(year,-2000,cast(g.Дата as date))
)
, ptp as (
 select t.external_id
        ,ДатаВзятияОбещания =  max(ДатаВзятияОбещания)
        ,ДатаОбещания = cast(max(o.ДатаОбещания) as date)
 from ( select external_id = НомерДоговора
    , max(o.дата) ДатаВзятияОбещания
    from 
	reports.collection.dm_CollectionKPIByMonth o  
	where exists(select top(1) 1 from #t0 t where t.external_id = t.external_id)
   group by  НомерДоговора
   ) t
   inner join  reports.collection.dm_CollectionKPIByMonth o  
            on t.external_id = o.НомерДоговора
            and t.ДатаВзятияОбещания= o.дата
    group by external_id
)

select 
    ptp.external_id
    ,СуммаПлатежейМеждуДатойОбещанияИТекущейДатой=sum(summ)
    ,СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания = sum(
        iif(r1.dt between  ptp.ДатаВзятияОбещания and ptp.ДатаОбещания, summ, 0) )
into #ptp_payments
from ptp join  payments r1 on r1.external_id=ptp.external_id and r1.dt>= ptp.ДатаВзятияОбещания

group by ptp.external_id

--ORDER by 1

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #ptp_payments', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END

 --select * from #ptp_payments

/*
dwh-398
Дата последнего прослушанного сообщения (IVR)
переписали логику согласно - BP-1187
*/
  drop table if exists #last_heared_message_date
  create table #last_heared_message_date(
	RequestID nvarchar(21)
	,lastDate datetime
	)
	create clustered index cix_RequestID on #last_heared_message_date(RequestID)
	
	insert into 	#last_heared_message_date
	(
		RequestID
		, lastDate
	)
   select RequestID = Number, lastDate = max(CommunicationDateTime) from  [Stg].[_Collection].[mv_Communications] c
	where  CommunicationDateTime>=dateadd(mm,-6, @today)
	and CommunicationResult = 'Сообщение прослушано полностью (проинформирован)'
	and exists(select top(1) 1 from NaumenDbReport.dbo.mv_outcoming_call_project cp
	where cp.uuid = c.NaumenProjectId
	and cp.title like '%Collection Автоинформатор %')
	group by 	Number
 
		  /*
  select RequestID,max(connected) lastDate

    into #last_heared_message_date
    from naumenDBReport.dbo.mv_heared_messages 
   where message_is_heard='yes'
   group by RequestID
   			*/
   --
   ALTER INDEX [cl_idx_number] ON stg.[_loginom].[Dm_risk_groups] 
	REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
   drop table if exists #rsk
   select *into #rsk  from stg._loginom.v_Dm_risk_groups rsk

--   select * from #t0
   delete from #t0 
   where fio='Шмыков Николай Николаевич' -- исключен из обзвона 01-11-2019
or external_id like '\_%' escape '\'
or external_id like '0%'



-- dwh-481
/*
--Отключили в рамках -DWH-1957 
drop table if exists #EnforcementOrders
SELECT 
  c.CrmCustomerId,
	Deals.number,
	Accepted=isnull([EnforcementOrders].Accepted,0)
  into #EnforcementOrders
  FROM
  (select JudicialClaimId, Accepted from (
select 
      JudicialClaimId, Accepted
      ,rn=row_number() over (partition by JudicialClaimId order by Accepted /* isnull(Updatedate,'19000101') */desc) 
      FROM [Stg].[_Collection].[EnforcementOrders]  
      ) q where rn=1
      )
EnforcementOrders
left join [Stg].[_Collection].JudicialClaims On JudicialClaims.id = [EnforcementOrders].JudicialClaimId
  left join [Stg].[_Collection].JudicialProceeding on JudicialProceeding.Id = JudicialClaims.JudicialProceedingId
  left join [Stg].[_Collection].Deals on Deals.Id = JudicialProceeding.DealId
  left join [Stg].[_Collection].customers c on c.id=deals.IdCustomer
 */

--select distinct * from #EnforcementOrders where accepted=1


--  dwh-520  
-- + все платежи после предыдущей плановой даты, если DPD был 0 в дату PlanDate + 1  
drop table if exists #paymentsAfterPlanDate
drop table if exists #paymentsAfterPlanDate_документ_платеж
;
with dpd0 as(
  select pd.external_id
   --    , pd.paymentDate
   --    , pd.paymentSum
   --    , dateadd(day,1,dateadd(year,-2000,cast(pd.paymentDate  as date)))
       , pd.prev_paymentDate
   --    , b.dpd
 
 from #plan_date pd 
 --join dbo.dm_CMRStatBalance b on 
	--b.external_id=pd.external_id 
	--and b.d=dateadd(day,1,dateadd(year,-2000,cast(pd.prev_paymentDate  as date)))
 --Берем из #cmr_p т.к там более верные данны по dpd
 inner join #cmr_p cmr on cmr.external_id = pd.external_id
	and cast(cmr.dt as date) = dateadd(day,1,dateadd(year,-2000,cast(pd.prev_paymentDate  as date)))
	and cmr.dpd = 0
	
 --where b.dpd =0
 )
 ,
  remote_query as (
  SELECT de.Код external_id
     -- , dateadd(year,-2000,cast(g.Дата as date)) dt
       , g.Сумма 
	   ,g.Ссылка as документ_платеж

    from stg.[_1Ccmr].[документ_платеж] g
    join stg.[_1Ccmr].Справочник_Договоры de on de.ссылка= g.Договор

    join dpd0 on dpd0 .external_id=de.код
    where cast(g.Дата as date) > cast(prev_paymentDate as date)
   --,dateadd(year,-2000,cast(g.Дата as date))
)
select *
	into #paymentsAfterPlanDate_документ_платеж
from remote_query

select external_id, sum(Сумма) as summ 
into #paymentsAfterPlanDate
from #paymentsAfterPlanDate_документ_платеж
group by external_id


--Платежи за последние 5 дней
  drop table if exists #payments5days
;with cte_payments5days as (
  SELECT  d.код  external_id
        , g.Сумма 
	   , g.Ссылка as документ_платеж
    from stg.[_1cCMR].[документ_платеж] g
    join stg.[_1cCMR].Справочник_Договоры d on g.Договор=d.Ссылка
   where dateadd(year,-2000,g.Дата)>=dateadd(day,-5,@today)
)
select external_id, sum(t.Сумма) as summ
into #payments5days
from cte_payments5days t
--DWH-1115 исключаем платежи которые были сделаны все платежи после предыдущей плановой даты
where not exists(select top(1) 1 from #paymentsAfterPlanDate_документ_платеж s where s.документ_платеж = t.документ_платеж
	and s.external_id = t.external_id)
group by external_id

--DWH-1106
--DWH-1238
   drop table if exists #t_Freezing
drop table if exists #t_Freezing_prod

;with cte_Реструктуризация as (
	select 
		Замороза_Начало = cast(dateadd(year,-2000, Реструктуризация.Дата) as date), 
		Регистратор_Ссылка = Реструктуризация.Регистратор_Ссылка,
		Договор_Ссылка = Реструктуризация.Договор

	from (select 
		Договор,
		ВидРеструктуризации,
		
		Статус,
		Дата = max(Дата)
		
		from stg.[_1cCMR].[РегистрСведений_Реструктуризация] р
			where Активность = 0x01
			and Заявление != 0x00000000000000000000000000000000
			and ВидРеструктуризации =  0xA2CC005056839FE911EBAEEEA6BD272F --Заморозка 1.0
		group by 
		Договор,
		ВидРеструктуризации,
		Статус
		
		) last_Реструктуризация
	inner join 	stg.[_1cCMR].[РегистрСведений_Реструктуризация] Реструктуризация 
		on Реструктуризация.Договор = last_Реструктуризация.Договор
		and Реструктуризация.ВидРеструктуризации = last_Реструктуризация.ВидРеструктуризации
		and Реструктуризация.Статус = last_Реструктуризация.Статус
		and Реструктуризация.Дата = last_Реструктуризация.Дата
		and Реструктуризация.Договор not in (0xA2C6005056839FE911EA6BF3E2A122E7) --fio - СБТ ЛКП ТЕСТ -
)
select
	*	
into #t_Freezing_prod
from cte_Реструктуризация
--where Договор_Ссылка = 0xB81B00155D4D086C11EA6B6BF3F3EF61




select DISTINCT 
	external_id = Договор.Код,
	prod.Замороза_Начало,
	ДанныеГрафикаПлатежей.Замороза_Окончание,
	totalPaymentAfterFreezing = 0
	--prod.Договор_Ссылка,
	--Регистратор,
	--ГрафикПлатежей.*
into #t_Freezing
	from #t_Freezing_prod prod
inner join stg._1cCMR.Справочник_Договоры Договор 
	on Договор.ССылка  =prod.Договор_Ссылка
 left join stg.[_1cCMR].[Документ_ГрафикПлатежей]	ГрафикПлатежей
	on ГрафикПлатежей.Договор = prod.Договор_Ссылка
	and cast(dateadd(year, -2000, ГрафикПлатежей.Дата) as date) = prod.Замороза_Начало
	and ГрафикПлатежей.ПометкаУдаления = 0x00
	and ГрафикПлатежей.Проведен =0x01
	
left join
(
	select Договор_Ссылка = Договор, 
		Регистратор = Регистратор_Ссылка,  
		Замороза_Окончание = 
		cast(dateadd(year,-2000, max(ДатаПлатежа)) as date)
		from  stg.[_1cCMR].РегистрСведений_ДанныеГрафикаПлатежей
		where Действует = 0x01
		and СуммаПлатежа = 0.00
		group by Договор, Регистратор_Ссылка
) ДанныеГрафикаПлатежей on ДанныеГрафикаПлатежей.Договор_Ссылка = prod.Договор_Ссылка
	and ДанныеГрафикаПлатежей.Регистратор =  ГрафикПлатежей.Ссылка
	
--DWH-1271
	
	
;with cte_totalPaymentAfterFreezing as (
select f.external_id, 
	totalPaymentAfterFreezing = sum(iif([основной долг уплачено]>0, 1, 0))
	from #t_Freezing f
--Cмотрим платежи после разморозки
inner join  dbo.dm_CMRStatBalance sb  on f.external_id  = sb.external_id
	and sb.d>=f.Замороза_Окончание
	and sb.dpd =0 
	--Уплата была в день платежа
	and exists(select top(1) 1 from dm.CMRExpectedRepayments er 
	where er.Код = sb.external_id
	and er.ДатаПлатежа = sb.d
	and isnull(sb.[основной долг уплачено],0)>0
	)
where f.Замороза_Окончание <=getdate()
--исключаем тех у кого были просрочки в теч. 6 меся. после окончания заморозки
	and not exists(select top(1) 1 from dbo.dm_CMRStatBalance sb1
	where sb1.external_id = sb.external_id
		and sb1.d between f.Замороза_Окончание and dateadd(mm, 6,  f.Замороза_Окончание)
		and sb1.dpd>0
		)
group by f.external_id
	--having sum(iif([основной долг уплачено]>0, 1, 0))<=6

)
update  t
	set totalPaymentAfterFreezing = isnull(iif(paf.totalPaymentAfterFreezing>6, 6, paf.totalPaymentAfterFreezing), 0)
from #t_Freezing t
	left join cte_totalPaymentAfterFreezing paf on paf.external_id = t.external_id
	



--dwh-551
 
  drop table if exists #heared_messages
  create table #heared_messages
  (
	RequestID nvarchar(20)
	,date datetime
  )
  /*
  select RequestID
       , connected Date
    into #heared_messages
    from naumenDBReport.dbo.mv_heared_messages 
   where message_is_heard='yes'
     and connected>dateadd(day,-30,@today)
	 */
  drop table if exists #communications_last30d
  select * 
    into #communications_last30d
    from stg._Collection.mv_Communications 
   where CommunicationDateTime>=dateadd(day,-30,@today) 
	and Контакт='Да' and Manager<>'Система'

  drop table if exists #NUM_RPC_all_30d
  ;
  with clients as (
                   select cast(CrmCustomerId as nvarchar(64)) CRMClientGUID,count(distinct cast(CrmCustomerId as nvarchar(64))+format(CommunicationDateTime,'yyyyMMddhhmmss') ) cnt   from #communications_last30d  group by CrmCustomerId
                   union all
                   select CRMClientGUID , count(distinct CRMClientGUID+format(date,'yyyyMMddhhmmss') ) from #heared_messages hm 
					join dwh_new.staging.CRMClient_references r 
					on hm.RequestID=r.CRMRequestNumber group by CRMClientGUID
                  )
  select CRMClientGUID
       , sum(cnt ) cnt
    into #NUM_RPC_all_30d
    from clients
   group by CRMClientGUID



  drop table if exists #NUM_RPC_all_14d
  ;
  with clients as (
                   select cast(CrmCustomerId as nvarchar(64)) CRMClientGUID,count(distinct cast(CrmCustomerId as nvarchar(64))+format(CommunicationDateTime,'yyyyMMddhhmmss') ) cnt   from #communications_last30d  where CommunicationDateTime >=dateadd(day,-14,@today) group by CrmCustomerId
                   union all
                   select CRMClientGUID , count(distinct CRMClientGUID+format(date,'yyyyMMddhhmmss') ) from #heared_messages hm join dwh_new.staging.CRMClient_references r on hm.RequestID=r.CRMRequestNumber  where DATE >=dateadd(day,-14,@today) group by CRMClientGUID
                  )
  select CRMClientGUID
       , sum(cnt ) cnt
    into #NUM_RPC_all_14d
    from clients
   group by CRMClientGUID




  drop table if exists #NUM_RPC_all_7d
  ;
  with clients as (
                   select cast(CrmCustomerId as nvarchar(64)) CRMClientGUID,count(distinct cast(CrmCustomerId as nvarchar(64))+format(CommunicationDateTime,'yyyyMMddhhmmss') ) cnt   from #communications_last30d  where CommunicationDateTime >=dateadd(day,-7,@today) group by CrmCustomerId
                   union all
                   select CRMClientGUID , count(distinct CRMClientGUID+format(date,'yyyyMMddhhmmss') ) from #heared_messages hm join dwh_new.staging.CRMClient_references r on hm.RequestID=r.CRMRequestNumber  where DATE >=dateadd(day,-7,@today) group by CRMClientGUID
                  )
  select CRMClientGUID
       , sum(cnt ) cnt
    into #NUM_RPC_all_7d
    from clients
   group by CRMClientGUID


-- dwh-548
  drop table if exists #space_Customer
  select c.crmcustomerID CrmClientGUID
       , r.region
       , r.actualregion
       , c.EDOAgreement
	   , c.ThirdPersonInteractionAgreementSignedDate
	   , c.ThirdPartiesInteractionAgreementSignedDate
	   , c.MobileDeviceImpactConsentSignedDate
	   , CustomerObligations = case cb.CustomerObligations
			when 1 then 'Прекращены'
			when 2 then 'Не прекращены'
			end
    into #space_Customer
    from Stg._Collection.customers c
		LEFT JOIN Stg._Collection.registration r on c.id=r.Idcustomer
		left join stg._Collection.CustomerBankruptcy cb on cb.CustomerId = c.id

-- /dwh-548
   
   drop table if exists #dealFlags
   select Number
        , HasEngagementAgreement  
     into #dealFlags
     from stg._collection.deals
     where HasEngagementAgreement is not null
	 
drop table if exists #customerStatuses

select CrmCustomerId
	, cst.name
	, denyCall
	, DenyCollectors                 
	, HardFraud_DenyCollectors       
	, cst.[Order]

  into  #customerStatuses
  
  from  Stg._Collection.[CustomerStatus] cs 
       join Stg._Collection.Customers c on c.Id = cs.CustomerId  
       join Stg._Collection.CustomerState cst on cs.CustomerStateId=cst.Id 
  where cs.IsActive=1


--#customerStatuses
--IF @isLogger = 1 BEGIN
--	DROP TABLE IF EXISTS ##TMP_AND_customerStatuses

--	SELECT * 
--	INTO ##TMP_AND_customerStatuses
--	FROM #customerStatuses
--END

--DWH-1691
DROP TABLE IF EXISTS #t_customer_status
--SELECT ST.CrmCustomerId, customer_status = string_agg(ST.name, ',')
--INTO #t_customer_status
--FROM #customerStatuses AS ST
--GROUP BY ST.CrmCustomerId

SELECT DISTINCT
	ST.CrmCustomerId,
	customer_status = first_value(ST.name) OVER(PARTITION BY ST.CrmCustomerId ORDER BY ST.[Order])
INTO #t_customer_status
FROM #customerStatuses AS ST




--select distinct name from #customerStatuses where name='RepresentativeInteraction230FZ'
--select * from #customerStatuses
--select * from  Stg._Collection.[CustomerStatus] cs 
--select * from  Stg._Collection.[CustomerState] cs 
--select * from Stg._Collection.CustomerStatusTypes
--select * from Stg._Collection.Customers c 
drop table if exists #groupedCustomerStatuses
select CrmCustomerId 
      , hospital_flag                               = SIGN(sum(case when name in ('Клиент в больнице (230-ФЗ)')                                              then 1 else 0           end)             )
      , disabled_person_flag                        = SIGN(sum(case when name in ('Инвалид 1 группы (230 ФЗ)')                                               then 1 else 0           end)             )
      , death_flag                                  = SIGN(sum(case when name in ('Смерть подтвержденная')                                                   then 1 else 0           end)             )
      , bankrupt                                    = cast(SIGN(sum(case when name in ('Банкрот подтверждённый','Банкрот неподтверждённый')                  then 1 else 0           end)             ) as nchar(1))
      , UnconfirmedDeath_flag                       = SIGN(sum(case when name in ('Смерть неподтвержденная')                                                 then 1 else 0           end)             )
      , BankruptConfirmed                           = cast(SIGN(sum(case when name in ('Банкрот подтверждённый')                                             then 1 else 0           end)             ) as nchar(1))
      , BankruptUnconfirmed                         = cast(SIGN(sum(case when name in ('Банкрот неподтверждённый')                                           then 1 else 0           end)             ) as nchar(1))
      , FailureInteraction230FZ_flag                = SIGN(SUM(case when name in ('Отказ от взаимодействия по 230 ФЗ')                                       then 1 else 0           end)             )
      , FailureInteractionWith3person230FZ_flag     = SIGN(SUM(case when name in ('Отказ от взаимодействия с 3-ми лицами (230-ФЗ)')                          then 1 else 0           end)             )
      , FeedbackConsentDataTransfer3person230FZ     = SIGN(SUM(case when name in ('Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)')    then 1 else 0           end)             )
      , FRAUD_flag                                  = SIGN(SUM(case when name in ('FRAUD')                                                                   then 1 else 0           end)             )
      , LackConsentPDProcessing_flag                = SIGN(SUM(case when name in ('Отсутствие согласия на обработку ПД')                                     then 1 else 0           end)             )
      , RejectProcessingPersonalData152FZ_flag      = SIGN(SUM(case when name in ('Отказ от обработки ПД (152-ФЗ)')                                          then 1 else 0           end)             )
      , RepresentativeInteraction230FZ_flag         = SIGN(SUM(case when name in ('Взаимодействие через представителя (230-ФЗ)')                             then 1 else 0           end)             )
      , Complaint_flag                              = SIGN(SUM(case when name in ('Жалоба')                                                                  then 1 else 0           end)             )
      , alco_flag                                   = cast (SIGN(SUM(case when name in ('Алкоголик/наркоман/игроман')                                        then 1 else 0           end)             ) as nchar(1))
      , fraud_denyCall                              = SIGN(SUM(case when name in ('FRAUD')                                                                   then CAST(isnull(denyCall,0) AS INT) end))
      , fail230_DenyCall                            = SIGN(SUM(case when name in ('Отказ от взаимодействия по 230 ФЗ')                                       then CAST(isnull(DenyCall,0) AS INT) end))
      , complaint_DenyCall                          = SIGN(SUM(case when name in ('Жалоба')                                                                  then CAST(isnull(DenyCall,0) AS INT) end))
      , jail_flag                                   = SIGN(SUM(case when name in ('Клиент в тюрьме')                                                         then 1 else 0           end))
      , space_ka_flag                               = SIGN(SUM(case when name in ('КА')                                                                      then 1 else 0           end))
      , FraudUnConfirmed                            = SIGN(SUM(case when name in ('Fraud неподтвержденный')                                                  then 1 else 0           end))
      , FraudConfirmed                              = SIGN(SUM(case when name in ('Fraud подтвержденный')                                                    then 1 else 0           end))
      , HardFraud                                   = SIGN(SUM(case when name in ('HardFraud')                                                               then 1 else 0           end))
      , DenyCollectors                              = SIGN(SUM(case when DenyCollectors is not null                                                          then 1 else 0           end))
      , FraudConfirmed_DenyCollectors               = SIGN(SUM(case when DenyCollectors is not null                                           then 1 else 0           end))
      , HardFraud_DenyCollectors                    = SIGN(SUM(case when HardFraud_DenyCollectors is not null                                                then 1 else 0           end))
      , bv_flag                                     = SIGN(SUM(case when name in ('БВ')                                                                      then 1 else 0           end))
	  , BankruptCompleted							= SIGN(SUM(case when name in ('Банкротство завершено')                                                 then 1 else 0           end))
   into #groupedCustomerStatuses
   from #customerStatuses
  group by CrmCustomerId 

  -- SELECT * FROM #groupedCustomerStatuses
   --SELEcT sIGN(-10)
 
 /*
 --dwh-609 Безнадежное взыскание
 -- убрано в результате dwh-627
 drop table if exists #bv
     SELECT Number,CrmCustomerId
     into #bv
  FROM stg._collection.[Pilot] p
  join stg._collection.deals d on d.id=p.DealId
  join stg._collection.customers c on c.id=d.idcustomer
  where p.name='БВ'
  --select * from #bv
  
  */
  
--dwh-586

  drop table if exists #AlternativeMatrixService 
  
  select max(c.date) as date--DWH-1144
       , d.Number 
    into #AlternativeMatrixService 
    from Stg._collection.Communications  c
    join Stg._collection.Deals d on d.id=c.IdDeal
   where c.AlternativeMatrixService is not null
   group by d.Number
--/dwh-586

--dwh-617

/*
  drop table if exists #kk0

  select startDate=dateadd(year,-2000,o.ДатаПоГрафикуКредитныхКаникул)
       , endDate=dateadd(year,-2000,ДатаОкончанияКредитныхКаникул)
       , d.Код Number 
    into #kk0
    from Stg.[_1cCMR].[Документ_ОбращениеКлиента] o
    join Stg.[_1cCMR].Справочник_Договоры d on o.Договор=d.ссылка
   where НоваяДатаПлатежа='2001-01-01 00:00:00' 
	and Проведен=0x01
	and o.ВидОперации = 0xB7DCDAEEBB3606B645BABE3167B3379A --КредитныеКаникулы
  
  
  drop table if exists #kk_old

  select * 
    into #kk_old
    from #kk0 
   where StartDate<@today and endDate>@today
   order by number desc

   */
--/dwh-617


-- dwh-648
-- флаг отзыва из ka
/* --решение в рамках  DWH-1959
drop table if exists #space_ka_deals
select DealNumber,KaReturnDt 
into #space_ka_deals
from stg._collection.[GearsToKAView]
*/



  drop table if exists #reject_paymet_count91

  select count( distinct cast(CrmCustomerId as nvarchar(36))+format(CommunicationDateTime,'yyyymmddHHiiss')) cnt
  ,CrmCustomerId
  into  #reject_paymet_count91
    from #t0 t 
    
    join #dm_CMRStatBalance_agg_value m on t.external_id=m.external_id
		and m.maxDateWithdpd91 is null
    join stg._Collection.mv_Communications c on c.CrmCustomerId=t.CRMClientGUID
   where CommunicationDateTime>=m.maxDateWithdpd91 and CommunicationResult='Отказ от оплаты'
   group by CrmCustomerId
--/dwh-648

--dwh-736
  drop table if exists #reject_paymet_last_date

  select c.CrmCustomerId
       , CommunicationDateTime=max(CommunicationDateTime) 
    into #reject_paymet_last_date
    from  stg._Collection.mv_Communications c 
   where CommunicationResult='Отказ от оплаты'
   group by CrmCustomerId


--/dwh-736




--dwh-644
drop table if exists #SkipStatus
;with ch as (
SELECT objectId,max(changedate) ChangeDate
FROM stg._collection.[CustomerHistory] ch

WHERE Metadata = 'CollectingStage'
AND (NewValue = '11' OR OldValue = '11')
group by objectId
)
select CrmCustomerId,ch.ChangeDate 
into #SkipStatus
FROM stg._collection.[CustomerHistory] ch
join ch ch_max on ch_max.objectId=ch.objectId and ch_max.ChangeDate=ch.ChangeDate
join stg._collection.Customers c on c.id=ch.objectId
where NewValue = '11'



--/dwh-644

/*

dwh-661
Флаг "Наличие отказа от оплаты за последние 30 дней"

*/

  drop table if exists #reject_paymet_last30days

  select distinct CrmCustomerId
    into #reject_paymet_last30days
    from #t0 t 
    join stg._Collection.mv_Communications c on c.CrmCustomerId=t.CRMClientGUID
   where CommunicationDateTime>=dateadd(day,-30,@today) and CommunicationResult='Отказ от оплаты'
--/dwh-611

--dwh-657
--set statistics time on
--set statistics io on
--clnt_contact_last_all -дата последнего удачного контакта с Клиентом хотя бы по одному из всех каналов связи 
 drop table if exists #communications_lastSuccessContactDate
  select c.CrmCustomerId
          ,max(CommunicationDate) lastSuccessContactDate
    into #communications_lastSuccessContactDate
    from stg._Collection.mv_Communications  c
   where Контакт='Да' and Manager<>'Система' and PersonType='Клиент'
   group by c.CrmCustomerId

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #communications_lastSuccessContactDate', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END

   --2- thd_contact_last_all - дата последнего удачного контакта с 3-им лицом хотя бы по одному из всех каналов связи 
    drop table if exists #communications_lastSuccessContactDate3
  select c.CrmCustomerId
          ,max(CommunicationDate) lastSuccessContactDate
    into #communications_lastSuccessContactDate3
    from stg._Collection.mv_Communications  c
   where Контакт='Да' and Manager<>'Система' and PersonType='Третье лицо'
   group by c.CrmCustomerId  

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #communications_lastSuccessContactDate3', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END

   --3- start_buсket_date - дата начала текущего бакета просрочки
   drop table if exists #bucketStartDate
   ;
   with currentBucket as (
   select external_id
        , bucket
     from dbo.dm_CMRStatBalance with(nolock)
    where d=@today 
      and dpd>0
     )
    select b.external_id
        , max(d) start_buсket_date  
     into #bucketStartDate
     from dbo.dm_CMRStatBalance b with(nolock)
     join currentBucket on currentBucket.external_id=b.external_id and b.bucket<>currentBucket.bucket
     
     group by b.external_id

--4- Skip_contact_add - дата, когда был найден последний контакт на стадии Skip
    drop table if exists #skipContactLastFoundDate

  SELECT [CustomerId]
       , CrmCustomerId
       , max(CreatedOn) maxCreatedOn
  into #skipContactLastFoundDate
  FROM [Stg].[_Collection].[SkipContact] sc join stg.[_Collection].[SkipCommunicationResult] scr on scr.Id=sc.SkipCommunicationResultId
  join [Stg].[_Collection].customers c on c.id=sc.CustomerId
  where scr.[IsSuccessfulResult]=1
  group by CustomerId,CrmCustomerId
  order by CustomerId


  --5 cnt_day_fail  - счетчик который считает дни когда все попытки связаться с Клиентом и 3-им лицом по всем каналам связи не успешны. Если хоть одна попытка за день удачная, счетчик сбрасывается

  drop table if exists #communicationsCount
  select CrmCustomerId
       , CommunicationDate
       , sum(case when Контакт='Да' then 1 else 0 end) SuccessContactNum 
       , sum(case when Контакт='Да' then 0 else 1 end) failContactNum 
    into #communicationsCount
    from stg._Collection.mv_Communications  c
   where (Manager<>'Система' 
	or c.Commentary = 'Недозвон Dialer'--DWH-73
	)
	and CrmCustomerId is not NULL
   group by  CrmCustomerId
       , CommunicationDate
order by  CrmCustomerId
       , CommunicationDate

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #communicationsCount', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END

/*DWH-882*/
drop table if exists #last_send_download_app_email_sent

select Number, max(CommunicationDateTime) as last_send_download_app_email_sent
	into #last_send_download_app_email_sent
	from stg._Collection.mv_Communications t
	where exists (
		  select top(1) 1 from stg._collection.CommunicationTemplate ct where ct.id = t.CommunicationTemplateId
		  and ct.ExternalNumber = 'EMAIL_ID_DOWNLOAD_APP'
	)
and Number is not NULL
   group by  Number

       drop table if exists #cnt_day_fail_table


;with  successContacts as (
select CrmCustomerId,/*min(communicationDate) minSuccesscommunicationDate ,*/max(communicationDate) maxSUccesscommunicationDate
from #communicationsCount src
where SuccessContactNum>0
group by CrmCustomerId

)
,failContacts as (
select CrmCustomerId,/*min(communicationDate) minFailcommunicationDate ,*/max(communicationDate) maxFailcommunicationDate
from #communicationsCount src
where failContactNum>0
group by CrmCustomerId

),
res as (
  select SuccessContacts.CrmCustomerId
       , maxSUccesscommunicationDate
       , maxFailcommunicationDate
       
    from SuccessContacts join failContacts on successContacts.CrmCustomerId=failContacts.CrmCustomerId
   where maxSUccesscommunicationDate<maxFailcommunicationDate
)
,res1 as ( select c.* , maxSUccesscommunicationDate
       , maxFailcommunicationDate
       ,case when c.communicationDate>maxSUccesscommunicationDate and c.communicationDate<=maxFailcommunicationDate then 1 else 0 end flag
       from #communicationsCount c 
join res on c.CrmCustomerId=res.CrmCustomerId
where c.failContactNum>0
)

 select crmcustomerId
       , cnt_day_fail=count(*)--(select count(distinct CommunicationDate) from #communicationsCount c where c.failContactNum>0  and c.CrmCustomerId=res.CrmCustomerId and  c.communicationDate>res.maxSUccesscommunicationDate and c.communicationDate<=res.maxFailcommunicationDate)
    into #cnt_day_fail_table
    from res1 where flag=1
    group by crmcustomerId

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #cnt_day_fail_table', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END

-- время работы 5:18
--
--/dwh-657

-- dwh-684
  drop table if exists #emails

  select c.CrmCustomerId
       , email =isnull(trim(cpd.email),'')
    into #emails
    from stg._collection.CustomerPersonalData cpd (NOLOCK)
    join stg._Collection.customers c (NOLOCK) ON cpd.IdCustomer=c.id


-- /dwh-684



--dwh-758
/*
- Дата начала и окончания по первым Кредитным Каникулам (KK)
 - Флаг Повторные КК - принимает значениe 1/0
 - Обзвон КК - брать из спейса - появится на бою ориентировочно после релиза 04.11
Если флаг Повторные каникулы = 1, то заполнить поля:
 - Дата начала повторных КК
 - Дата окончания повторных КК
- ams_value - класть значение поля «Сервис по матрице альтернатив» из спейса
*/
/*
  drop table if exists #ams_value
  select Number
       , alternativeMatrixService = case when alternativeMatrixService=1 then 'Сдвиг даты платежа'
                                         when alternativeMatrixService=2 then 'Снижение процентной ставки до 40%'
                                         when alternativeMatrixService=3 then 'Снижение процентной ставки на 10%'
                                         when alternativeMatrixService=4 then 'Реализация авто'
                                         when alternativeMatrixService=5 then 'Кредитные каникулы'
                                         when alternativeMatrixService=6 then 'Автоломбард'
                                         when alternativeMatrixService=7 then 'Рефинансирование'
                                         when alternativeMatrixService=8 then 'Повторные КК'
										 when alternativeMatrixService=9 then 'Заморозка 1.0' --DWH-1144
                                    else format (alternativeMatrixService,'0')
                                    end

into #ams_value from Stg._collection.Deals where alternativeMatrixService is not null

  drop table if exists #kk_758

  select startDate=dateadd(year,-2000,o.ДатаПоГрафикуКредитныхКаникул)
       , endDate=dateadd(year,-2000,ДатаОкончанияКредитныхКаникул)
       , d.Код Number
       , o.ПометкаУдаления
       , case when o.ПометкаУдаления =0x00 then dateadd(year,-2000,ДатаОкончанияКредитныхКаникул) else null end endDate_lastKK
    into #kk_758
    --Select *
    from Stg.[_1cCMR].[Документ_ОбращениеКлиента] o
    join Stg.[_1cCMR].Справочник_Договоры d on o.Договор=d.ссылка
   where НоваяДатаПлатежа='2001-01-01 00:00:00' --and Проведен=0x01 
   --DWH-1227 внесли измениня согласно
   and o.ВидОперации = 0xB7DCDAEEBB3606B645BABE3167B3379A --КредитныеКаникулы
	and o.ПометкаУдаления = 0x00 
	and o.Проведен = 0x01
   
  order by  договор
  */

  --select * from #kk_758    order by Number,startDate, endDate

  /*
  drop table if exists #kk_758_1
  select number
       , min(startDate) startDate_1stKK
       , min(endDate)  endDate_1stKK
       , povt_KK=case when min(endDate)<>max(endDate) then 1 else 0 end
       , max(endDate_lastKK) endDate_lastKK
  into #kk_758_1
  from #kk_758 
  group by number
  order by Number
  
  

  drop table if exists #CallingCreditHolidays_0
  select d.number,max(cast(c.date as date)) communicationDate 
  into #CallingCreditHolidays_0
  from Stg._collection.communications c
  join Stg._collection.deals d on c.iddeal=d.id
  where 
  c.date>'20201104' -- дата релиза
  and c.[CallingCreditHolidays] is not null
  group by d.number
 
SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #CallingCreditHolidays_0', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END

  drop table if exists #CallingCreditHolidays
  
  select d.number, cast(c.date as date) communicationDate  
   ,CallingCreditHolidays= case when c.CallingCreditHolidays=1 then 'Будет платить по графику' 
                                when c.CallingCreditHolidays=2 then 'Не будет платить по графику' 
                                when c.CallingCreditHolidays=3 then 'Сложности в оплате по графику' 
                                else format(c.CallingCreditHolidays,'0')
                           end

  
  
  into #CallingCreditHolidays
  from Stg._collection.communications c
  join Stg._collection.deals d on c.iddeal=d.id
  join #CallingCreditHolidays_0 ch on ch.number=d.number and cast(c.date as date)=ch.communicationDate
  where 
  c.date>'20201104' -- дата релиза
  and c.[CallingCreditHolidays] is not null

   */
  -- dwh-1275
 -- найдем все отказы с датой просрочки на текущий день менее 88 дней
   drop table if exists #reject_payment_1_88_days
   /*
  select t.external_id
		, c.CommunicationDateTime
		, min(dpd) min_dpd
    into #reject_payment_1_88_days
    from #t0 t 
		join stg._Collection.mv_Communications c on c.CrmCustomerId=t.CRMClientGUID
			and t.external_id = c.Number --еще и по договору
	--Тут по прежднему смотрим на срез комуникаций за последние 88 дней.
	--DWH-1363
	where   CommunicationDateTime>=dateadd(day,-88,@today) 
			and CommunicationResult='Отказ от оплаты'
			and  t.dpd between 1 and 88
			
	group by t.external_id, c.CommunicationDateTime 
	*/


	select t.external_id
		, c.CommunicationDateTime
		, min(dpd) min_dpd
    into #reject_payment_1_88_days
    from 
	(
		--Определяем дату возникновения просрочки 1день
	select t.external_id
		,t.dpd
		,date_dpd_1 = dateadd(dd, -dpd+1, @today)
		,CRMClientGUID
		from  #t0 t
		where t.dpd between 1 and 88
	)  t 
		join stg._Collection.mv_Communications c on c.CrmCustomerId=t.CRMClientGUID
			and t.external_id = c.Number --еще и по договору
			and c.CommunicationResult='Отказ от оплаты'
			--Тут по прежднему смотрим на срез комуникаций за последние 88 дней.
			and c.CommunicationDateTime>=dateadd(day,-88,@today) 
			--берем все коммуникации после наступления пророчки
		and c.CommunicationDateTime >= date_dpd_1  --DWH-1644
	group by t.external_id, c.CommunicationDateTime 


	--DWH-1864 поле flg_Refused_to_pay_at_PreLegal_2+ : 2+ отказа от оплаты на стадии Prelegal
	--flg_Refused_to_pay_at_PreLegal_2+
	DROP TABLE IF EXISTS #t_Refused_to_pay_at_PreLegal
	DROP TABLE IF EXISTS #t_Refused_to_pay_at_PreLegal_2

	--все отказы от оплаты за время просрочки
	SELECT DISTINCT 
		c.CrmCustomerId,
		c.CommunicationDateTime
	INTO #t_Refused_to_pay_at_PreLegal
	FROM #t0 AS t
		INNER JOIN Stg._Collection.mv_Communications AS c
			ON c.CrmCustomerId = t.CRMClientGUID
	WHERE 1=1
		AND 60 < t.dpd AND t.dpd <= 90 -- сегодня более, чем 60 день просрочки и не более, чем 90-й
		AND c.CommunicationResult = 'Отказ от оплаты'
		AND c.CommunicationDateTime >= dateadd(DAY, - t.dpd + 1, @today)

	--более 2-х отказов от оплаты за время просрочки
	SELECT R.CrmCustomerId
	INTO #t_Refused_to_pay_at_PreLegal_2
	FROM #t_Refused_to_pay_at_PreLegal AS R
	GROUP BY R.CrmCustomerId
	HAVING count(*) >= 2

	--IF @isLogger = 1 BEGIN
	--	DROP TABLE IF EXISTS ##t_Refused_to_pay_at_PreLegal
	--	DROP TABLE IF EXISTS ##t_Refused_to_pay_at_PreLegal_2

	--	SELECT * INTO ##t_Refused_to_pay_at_PreLegal FROM #t_Refused_to_pay_at_PreLegal
	--	SELECT * INTO ##t_Refused_to_pay_at_PreLegal_2 FROM #t_Refused_to_pay_at_PreLegal_2
	--END
	--//DWH-1864




	--DWH-1867 Добавить поле в витрину стратегии Клиент не Контакт flg_Non_Contact
	--1 все коммуникации за время просрочки
	DROP TABLE IF EXISTS #t_Communications_delay
	select 
		c.CrmCustomerId,
		c.CommunicationDateTime,
		c.CommunicationType,
		c.PersonType,
		flg_Non_Contact = convert(int, 0)
	into #t_Communications_delay
	from #t0 AS t 
		INNER JOIN Stg._Collection.mv_Communications AS c
			ON c.CrmCustomerId = t.CRMClientGUID
	WHERE 1=1
		AND 0 < t.dpd
		AND c.CommunicationDateTime >= dateadd(DAY, - t.dpd + 1, @today)

	CREATE CLUSTERED INDEX IX0 ON #t_Communications_delay(CrmCustomerId)

	--CREATE INDEX IX1 ON #t_Communications_delay(CommunicationType, PersonType)

	-- 2. отметить коммуникации, подходящие по условию
	UPDATE D
	SET D.flg_Non_Contact = 1
	FROM #t_Communications_delay AS D
	WHERE 1=1
		AND (
			--Тип коммуникации "Исходящий звонок" и Тип контакта "Нет контакта"
			(D.CommunicationType = 'Исходящий звонок' AND D.PersonType = 'Нет контакта')
			--Тип коммуникации "Мессенджер" и Тип контакта "Нет контакта"
			OR (D.CommunicationType = 'Мессенджеры' AND D.PersonType = 'Нет контакта')
			--Тип коммуникации "Входящий звонок" Тип контакта - все значения отличные от "Клиент" и "Третье лицо"
			OR (D.CommunicationType = 'Входящий звонок' AND D.PersonType NOT IN ('Клиент', 'Третье лицо'))
		)

	-- 3. выбрать Клиентов, у которых были только коммуникации, подходящие по условию
	DROP TABLE IF EXISTS #t_Non_Contact

	SELECT D.CrmCustomerId
	INTO #t_Non_Contact
	FROM #t_Communications_delay AS D
	GROUP BY D.CrmCustomerId
	HAVING min(D.flg_Non_Contact) = 1

	--IF @isLogger = 1 BEGIN
	--	DROP TABLE IF EXISTS Stg.tmp.TMP_AND_Non_Contact

	--	SELECT * 
	--	INTO Stg.tmp.TMP_AND_Non_Contact
	--	FROM #t_Non_Contact
	--END
	--//DWH-1867


	--определим что дата звонка была после наступления срока просрочки
   drop table if exists #reject_payment_1_88_days_group
   select 
		t.external_id
		,Count(1) as reject_payment_dpd_1_88_count 
   into #reject_payment_1_88_days_group
   from (
   select   
			external_id
			,CommunicationDate = cast(CommunicationDateTime as date) 
			--,lastCommunicationDate = max(cast(CommunicationDateTime as date) ) over (partition by external_id)
			, reject_payment_dpd_1_88   = iif(cast(dateadd(day,-min_dpd, Getdate()) as date) <= cast(CommunicationDateTime as date),1,0) 
   from #reject_payment_1_88_days t
   ) t
   where reject_payment_dpd_1_88 = 1
     --Берем комуникации только за последние 30 дней
	 --DWH-1363
	 and CommunicationDate>=dateadd(day,-30, getdate())
   --Если после отказа клиент внес платеж по договору, то вне зависимости от размера суммы платежа, значение счетчика обнулить.
	--Не учитываем договоры по которым был платеж после коммуникации
	and not exists(select top(1) 1 from #cmr_p p
	where p.external_id = t.external_id
		and p.last_payment_date >=CommunicationDate
		--and dateadd(year,-2000, p.last_payment_date) >=CommunicationDate
		and p.last_payment_sum > 0)
		/*
  and not exists (select top(1) 1 from dbo.dm_CMRStatBalance sb 
		where sb.external_id = t.external_id
		and sb.d>=CommunicationDate
		and isnull([сумма поступлений],0 ) >0
		)
	*/
   group by t.external_id
   /*
drop table if exists #kk_dwh758
  select kk.number
       , startDate_1stKK
       , endDate_1stKK
       , povt_KK
       ,  CallingCreditHolidays
       , endDate_lastKK
       , ams_value= alternativeMatrixService
    into #kk_dwh758
    from #kk_758_1 kk
    left join #ams_value              v on kk.number=v.number
    left join #CallingCreditHolidays ch on ch.number=kk.number

	*/
    --select * from #kk_dwh758 where number='19011625080002'

--dwh-835

drop table if exists #deals_probation
--select  d.number,d.Probation into #deals_probation
-- from Stg._collection.deals d
--Изменили логику формирования #deals_probation  согласно DWH-1501


select distinct
	Договор = д.Ссылка,
	external_id = д.Код,
	Probation = iif(параметрыДоговора.ИспытательныйСрок = 0x01, 1, 0)
	into #deals_probation
from stg._1cCMR.Справочник_Договоры д
left join (
	select 
	гп.Договор
	,гп.Ссылка
	,nRow =  row_number() over(partition by гп.Договор, cast(гп.Дата as date) order by гп.Дата desc)
	from (select 
		Договор,
		Дата = max(Дата) 
	from sTG.[_1Ccmr].Документ_ГрафикПлатежей гп 
	where ПометкаУдаления != 0x01
	and Проведен = 0x01
	and Основание_Ссылка !=0x
	group by Договор
	) last_Документ_ГрафикПлатежей 
	left join sTG.[_1Ccmr].Документ_ГрафикПлатежей гп 
		on гп.Договор = last_Документ_ГрафикПлатежей.Договор
		and гп.Дата = last_Документ_ГрафикПлатежей.Дата
		and гп.ПометкаУдаления != 0x01
		and гп.Проведен = 0x01
		and гп.Основание_Ссылка !=0x
) гп on гп.Договор = д.Ссылка
	and гп.nRow = 1
left join STG.[_1Ccmr].[РегистрСведений_ПараметрыДоговора] параметрыДоговора
		on ПараметрыДоговора.Договор = д.Ссылка
		and ПараметрыДоговора.Регистратор_Ссылка = гп.Ссылка
		and ПараметрыДоговора.Регистратор_ТипСсылки = 0x0000005E
		and ПараметрыДоговора.ИспытательныйСрок = 0x01
			


	
 

 --DWH-1373
 drop table if exists #WorkFlow_Клиент
 drop table if exists #t_WorkFlow_FICO3_score
 select FICO3_score,  д.Код as external_id  , stage_date, Клиент 
 into #WorkFlow_Клиент
 from stg._loginom.WorkFlow
 inner join stg._1cCMR.Справочник_Договоры д on д.Код = cast(number as nvarchar(100))
 where FICO3_score is not null


 select 
	n.external_id,
	Клиент_Guid = [dbo].[getGUIDFrom1C_IDRREF](w.Клиент), 
	FICO3_score = max(FICO3_score)
	into #t_WorkFlow_FICO3_score
	from (select stage_date = max(stage_date), Клиент  from #WorkFlow_Клиент
 group by Клиент
 ) t
 inner join #WorkFlow_Клиент w on w.Клиент = t.Клиент
	and w.stage_date = t.stage_date
 inner join (select distinct external_id, Клиент  from #WorkFlow_Клиент ) n
 on n.Клиент = w.Клиент
 group by n.external_id,
	w.Клиент


	--DWH-1566

drop table if exists #ReasonforFullIndebtedness
select 
	дсд.ДоговорЗайма,
	external_id = д.Код,
	Период = dateadd(year, -2000, Период),
	ПричиныВыставленияПолнойЗадолженностиКод = пвпз.Код,
	ПричиныВыставленияПолнойЗадолженности = пвпз.Наименование
into #ReasonforFullIndebtedness
from stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров дсд
inner join stg._1cCMR.Справочник_Договоры д on д.Ссылка = дсд.ДоговорЗайма
inner join stg._1cCMR.Справочник_ПричиныВыставленияПолнойЗадолженности пвпз
	on пвпз.Ссылка = дсд.Значение_Ссылка
		and дсд.Значение_ТипСсылки = 0x00001800
	--DWH-2097
drop table if exists #Reasons2StoppingAccruals
select 
	дсд.ДоговорЗайма,
	external_id = д.Код,
	Период = dateadd(year, -2000, Период),
	ПричиныОстановкиНачислений = пон.Наименование
into #Reasons2StoppingAccruals
from stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров дсд
inner join stg._1cCMR.Справочник_Договоры д on д.Ссылка = дсд.ДоговорЗайма
inner join stg._1cCMR.Справочник_ПричиныОстановкиНачислений пон
	on пон.Ссылка = дсд.Значение_Ссылка
		and дсд.Значение_ТипСсылки = 0x000019FD
		
		
--
drop table if exists #t_Collection_Deals
select 
	external_id = d.Number
	,d.NeedToStartLegalProcess
	,OpenTask_IP_cnt	= isnull(task_ip.OpenTask_IP_cnt,0)
	,OpenTask_Legal_cnt = isnull(task_Legal.OpenTask_Legal_cnt,0)
	into #t_Collection_Deals
from stg._Collection.Deals d
--кол. открытых задач на ИП
left join (
	select 
		ta.DealId 
		,OpenTask_IP_cnt  = count(distinct ta.Id) 
	from stg._Collection.TaskAction ta 
where ta.ActualDateOfDecision is null 
and exists(select top(1) 1 
	from stg._Collection.StrategyActionTask sat 
	inner join stg._Collection.CollectingStage cs on cs.Id = sat.CollectingStageId 
where cs.Name in ('ИП')
	and sat.Id = ta.StrategyActionTaskId
	)
	group by ta.DealId 
) task_ip on task_ip.DealId = d.Id
--кол. открытых задач на СП
left join (
	select 
		ta.DealId 
		,OpenTask_Legal_cnt  = count(distinct ta.Id) 
	from stg._Collection.TaskAction ta 
where ta.ActualDateOfDecision is null 
and exists(select top(1) 1 
	from stg._Collection.StrategyActionTask sat 
	inner join stg._Collection.CollectingStage cs on cs.Id = sat.CollectingStageId 
where cs.Name in ('Legal')
	and sat.Id = ta.StrategyActionTaskId
	)
	group by ta.DealId 
) task_Legal on task_Legal.DealId = d.Id

create clustered index ix on #t_Collection_Deals(external_id)





--DWH-1811
drop table if exists #t_Collection_device_status
select 
	external_id = d.Number, 
	device_status_desc =  case mb.Status
		when 0 then 'Не выбрано'
		when 1 then 'Зарегистрировано'
		when 2 then 'Активно'
		when 3 then 'Заблокировано'
		end,
	device_status =  case mb.Status
		when 0 then 'None'
		when 1 then 'Registered'
		when 2 then 'Active'
		when 3 then 'Locked'
		end,
	device_status_date = isnull(mb.UpdateDate, mb.CreateDate)
into #t_Collection_device_status
from stg._Collection.Deals d
inner join stg._Collection.MobileDevices mb on mb.DealId = d.Id
create clustered index ix on #t_Collection_device_status(external_id)


--DWH-1747
drop table if exists #t_JudicialClaims
SELECT   
		Deal.Number AS external_id
		,TotalAmountRequirements = sum(isnull(jc.AmountRequirements,0)) --Сумма иска
		--,ClaimInCourtDate = max(cast(jc.ClaimInCourtDate as date))--Дата подачи иска в суд убрали в рамках  DWH-2561
		,CourtClaimSendingDate  = max(cast(jc.CourtClaimSendingDate as date))--Дата отправки иска в суд --DWH-2561
into #t_JudicialClaims
FROM            Stg._Collection.Deals AS Deal 
	inner join stg._Collection.customers c on c.Id = Deal.IdCustomer
	inner JOIN Stg._Collection.JudicialProceeding AS jp ON jp.DealId  = Deal.Id
	inner JOIN Stg._Collection.JudicialClaims AS jc ON jc.JudicialProceedingId  = jp.Id
--where jc.AmountRequirements>0 -- убрали в рамках  DWH-2561
group by Deal.Number


--DWH-1863 поле "Отказ от реализации авто" flg_Refused_to_sell_car
--В поле CustomerWantsToImplementCar должен стоять признак "Нет", 
--тогда данному клиенту проставляется флаг flg_Refused_to_sell_car = 1, 0 - все прочие

--DWH-1901 поле "Согласие на реализацию авто" flg_Agreed_to_sell_car 
--В поле CustomerWantsToImplementCar (Клиент согласился реализовать автомобиль) должен стоять признак "Да",
--тогда данному клиенту проставляется флаг flg_Agreed_to_sell_car = 1, 0 - все прочие

DROP TABLE IF EXISTS #t_Agreed_Refused_to_sell_car

SELECT 
	Deal.Number,
	CustomerWantsToImplementCar = max(convert(int, ipr.CustomerWantsToImplementCar))
INTO #t_Agreed_Refused_to_sell_car
FROM Stg._collection.ImplementationProcess AS ipr
	INNER JOIN Stg._Collection.DealPledgeItem AS dpi
		ON dpi.PledgeItemId = ipr.PledgeItemId
	INNER JOIN Stg._Collection.Deals AS Deal
		ON dpi.DealId = Deal.Id
WHERE ipr.CustomerWantsToImplementCar IN (0, 1)
GROUP BY Deal.Number




--КК_SVO
--
drop table if exists #t_КК
create table #t_КК(
	external_id		nvarchar(30),
	flg_KK_SVO_ever	bit,
	flg_KK_SVO	    bit,
	kk_flag			bit,
	startDate_1stKK	date,
	endDate_lastKK	date
)
insert into #t_КК(
	external_id		
	,flg_KK_SVO_ever	
	,flg_KK_SVO	    
	,kk_flag	
	,startDate_1stKK	
	,endDate_lastKK	
)
SELECT 
	external_id = R.number,
	--у клиента были КК Военные кредитные каникулы
	flg_KK_SVO_ever = max(iif(reason_credit_vacation = 'Военные кредитные каникулы', 1, 0))
	--У клиента имеются кредитные каникулы ( КК) с типом : Военные кредитные каникулы на сегодня.
	,flg_KK_SVO = max(
	case reason_credit_vacation when 'Военные кредитные каникулы'
	then 
	iif(@today between R.period_start and isnull(R.period_end, @today), 1, 0)
	else 0 end)
	,kk_flag = max(iif(@today between R.period_start and isnull(R.period_end, @today), 1, 0)
	)
	,startDate_1stKK = min( R.period_start)
	,endDate_lastKK  = max(R.period_end)
from dbo.dm_restructurings AS R
where operation_type = 'Кредитные каникулы'
	and isApproved = 1
group by R.number


create clustered index cix on #t_КК(external_id)

 drop table if exists #t01
 select  
	t.external_id,
    t.CMRContractGUID,
    t.CRMClientGUID,
    t.fio,
	t.last_name,
	t.first_name,
	t.patronymic,
    t.birth_date,
    t.credit_date,
    t.credit_amount,
    t.agent_flag,
    t.agent_name,
    t.overdue_amount,
    t.principal_rest,
    t.total_rest,
    t.dpd,
    t.ТелефонМобильный,
    t.КредитныеПродукт,
    t.IsInstallment,
    t.next_payment_amount
      , gcs.hospital_flag                           
      , gcs.disabled_person_flag                    
      , gcs.death_flag                              
      , gcs.bankrupt                                
      , gcs.UnconfirmedDeath_flag                   
      , gcs.BankruptConfirmed                       
      , gcs.BankruptUnconfirmed                     
      , gcs.FailureInteraction230FZ_flag            
      , gcs.FailureInteractionWith3person230FZ_flag 
      , gcs.FeedbackConsentDataTransfer3person230FZ 
      , gcs.FRAUD_flag                              
      , gcs.LackConsentPDProcessing_flag            
      , gcs.RejectProcessingPersonalData152FZ_flag  
      , gcs.RepresentativeInteraction230FZ_flag     
      , gcs.Complaint_flag 
      , gcs.alco_flag 
      , gcs.fraud_denyCall                          
      , gcs.fail230_DenyCall                        
      , gcs.complaint_DenyCall                      
      , ptp_last14days                             = case  when ptp_last14days.CrmCustomerId is not null then '1' else '0' end 
      , broked_ptp_last_14days                     = case  when broked_ptp_last_14days.CRMClientGUID is not null then '1' else '0' end 
      , EnforcementOrders_flag                     = null /* case when isnull(eo.Accepted,0)=0 then 0  else eo.Accepted end*/ --DWH-1957 отключили в рамках этой задачи
      , NUM_RPC_all_7d                             = isnull(NUM_RPC_all_7d    .cnt,0)
      , NUM_RPC_all_14d                            = isnull(NUM_RPC_all_14d   .cnt,0)
      , NUM_RPC_all_30d                            = isnull(NUM_RPC_all_30d   .cnt,0)
     
      , cf.Region       
      , cf.ActualRegion
	  , cf.ThirdPersonInteractionAgreementSignedDate
	   ,cf.ThirdPartiesInteractionAgreementSignedDate   
      
      , fpd                                        = _pd.fpd0
      , spd                                        = _pd.spd0
      , tpd                                        = _pd.tpd0
      , bv_flag                                    = gcs.bv_flag --case when  bv.CrmCustomerId is not null then '1' else '0' end  
      , Last5DaysPayments                          = isnull(p5.summ,0)
       , FPD60                                      = _pd.fpd60
       , FPD30                                      = _pd.fpd30
       , FPD4                                       = _pd.fpd4
       , applicationScore                           = rsk.[group]
       , papd_sum                                   = isnull(papd.summ,0)
       , EDOAgreement                               = isnull(cf.EDOAgreement,'0')
       , HasEngagementAgreement                     = isnull(df.HasEngagementAgreement,'0')
       , jail_flag                                  = isnull(gcs.jail_flag,'0')
       , ams_flag                                   = case when ams.number is null then 0 else 1 end
       , ams_date                                   = ams.date
       
       , gcs.space_ka_flag                              
       , FraudUnConfirmed 
       , FraudConfirmed   
       , HardFraud
       , DenyCollectors                 
       , FraudConfirmed_DenyCollectors  
       , HardFraud_DenyCollectors       
       , space_ka_return_flag                       = null /*case when skd.KaReturnDt is not null then 1 else 0 end*/ --Решение в рамках DWH-1959
       , rpc91                                      = rpc91.cnt
       , SkipEnterDate                              = sc_st.ChangeDate

       , clnt_contact_last_all                      = clscd.lastSuccessContactDate
       , thd_contact_last_all                       = lscd3.lastSuccessContactDate
       , start_buсket_date                          = bsd.start_buсket_date
       , cnt_day_fail                               = cdft.cnt_day_fail
       , Skip_contact_add                           = sclfd.maxCreatedOn
       , clnt_email_flg=case when isnull(trim(e.email),'')<>'' then 1 else 0 end
       , reject_paymet_last_date					= rpld.CommunicationDateTime
      
       , ptp_otl_PromiseDate = ptp_otl.promisedate 
       , deals_probation.probation
	   , BankruptCompleted							= cast(isnull(gcs.BankruptCompleted,0) as bit)
	   , Product_type								= t.Product_type
	   , MobileDeviceImpactConsentSignedDate		= cf.MobileDeviceImpactConsentSignedDate
	   , t.Overdue_Interest
	   --DWH-1863 отказ от реализации авто
	   --В поле CustomerWantsToImplementCar должен стоять признак "Нет"
	   , flg_Refused_to_sell_car = cast(iif(isnull(sell_car.CustomerWantsToImplementCar, -1) = 0, 1, 0) as bit)
	   --DWH-1901 согласие на реализацию авто
	   --В поле CustomerWantsToImplementCar должен стоять признак "Да"
	   , flg_Agreed_to_sell_car = cast(iif(isnull(sell_car.CustomerWantsToImplementCar, -1) = 1, 1, 0) as bit)
	   , cf.CustomerObligations-- DWH-2094 значение параметра "Обязательства клиента"
	   , t.segment_code 
	   , t.segment_name 
	   , t.Client_inn --инн клиента DWH-2512
	   , t.hasBeenInKa --Договор ранее был в КА за любой период жизни договора
	   , bal_agg_value.totalPaymentsAmtL90D --Сумма платежей за последние 90 дней 
	   , t.total_payments
	   , bal_agg_value.max_dpd_begin
	   , bal_agg_value.max_dpd_last_90d
	   , contract_end = bal_agg_value.endDate
	   , pdn.PDN --пдн на дату заведения --BP-624
	   ,t.Product_SubTypeName
	   ,t.Product_SubTypeCode
 into #t01
 from #t0 t
 left join #_pd _pd on _pd.external_id = t.external_id
 left join #space_Customer cf on cf.CrmClientGUID=t.CRMClientGUID

 left join #NUM_RPC_all_7d NUM_RPC_all_7d on   NUM_RPC_all_7d .CRMClientGUID=t.CRMClientGUID
 left join #NUM_RPC_all_14d NUM_RPC_all_14d on NUM_RPC_all_14d.CRMClientGUID=t.CRMClientGUID
 left join #NUM_RPC_all_30d NUM_RPC_all_30d on NUM_RPC_all_30d.CRMClientGUID=t.CRMClientGUID
 --left join #EnforcementOrders eo on eo.Number=t.external_id
 left join #broked_ptp_last_14days broked_ptp_last_14days on broked_ptp_last_14days.CRMClientGUID=t.CRMClientGUID
 left join #ptp_last14days  ptp_last14days on ptp_last14days.CrmCustomerId=t.CRMClientGUID
 
 left join #groupedCustomerStatuses gcs on gcs.CrmCustomerId=t.CRMClientGUID
 --left join #bv bv on bv.CrmCustomerId=t.CRMClientGUID
 left join #payments5days p5 on p5.external_id=t.external_id
 
 left join #rsk rsk on rsk.external_id=t.external_id
 left join #paymentsAfterPlanDate papd on papd.external_id=t.external_id
 left join #dealFlags df on df.number=t.external_id
 left join #AlternativeMatrixService ams on ams.Number=t.external_id
 
 --left join #space_ka_deals skd on skd.DealNumber=t.external_id --решение в рамках DWH-1959
 left join #reject_paymet_count91 rpc91 on rpc91.CrmCustomerId=t.CRMClientGUID
 left join #SkipStatus sc_st on sc_st.CrmCustomerId=t.CRMClientGUID
 
 left join #communications_lastSuccessContactDate clscd on clscd.CrmCustomerId=t.CRMClientGUID
 left join #communications_lastSuccessContactDate3 lscd3 on lscd3.CrmCustomerId=t.CRMClientGUID
 left join #bucketStartDate bsd on bsd.external_id=t.external_id
 left join #skipContactLastFoundDate sclfd on sclfd.CrmCustomerId=t.CRMClientGUID
 left join #cnt_day_fail_table cdft on cdft.CrmCustomerId=t.CRMClientGUID
 left join #emails e on e.CrmCustomerId=t.CRMClientGUID  
 left join #reject_paymet_last_date rpld on rpld.CrmCustomerId=t.CRMClientGUID
 
 
 left join #ptp_otl ptp_otl on ptp_otl.CRMClientGUID=t.CRMClientGUID
 left join #deals_probation deals_probation on deals_probation.external_id=t.external_id
 LEFT JOIN #t_Agreed_Refused_to_sell_car AS sell_car ON sell_car.Number = t.external_id
 left join #dm_CMRStatBalance_agg_value bal_agg_value
	on bal_agg_value.external_id = t.external_id
 left join #t_ПДН pdn on  pdn.external_id =  t.external_id
 --select * from #t01 t
 --left join #customerStatuses cs on cs.CrmCustomerId=t.crmClientGUID
 --where bankrupt<>0

      --exec logdb.dbo.[LogDialerEvent] 'CreateAgreementListByStrategy_dataMart_CMR','temporary tables ready','','' 
      --exec logdb.dbo.[LogAndSendMailToAdmin] 'CreateAgreementListByStrategy_dataMart_CMR','Info','temporary tables ready',N''


DROP TABLE IF EXISTS #t_IVR_0

SELECT DISTINCT
	D.external_id,
	--дата воздействия IVR
	IVR_status_date = c.CommunicationDateTime,
	--факт доставки воздействия . варианты 1\0. 1 - прослушано до контрольной точки , 0 - непрослушено
	IVR_status = 
			CASE 
				WHEN c.CommunicationResultId in (29) THEN 1 --Сообщение прослушано полностью (проинформирован)
				WHEN c.CommunicationResultId in (30) THEN 0 --Сообщение прослушано не полностью
				ELSE 0
			END
INTO #t_IVR_0
FROM  
	(
	SELECT DISTINCT
		t.external_id
		,CRMClientGUID
	FROM #t0 AS t
	) AS D 
	INNER JOIN stg._Collection.mv_Communications AS C
		ON C.Number = D.external_id --по договору
		AND C.CommunicationType IN ('Автоинформатор pre-del')
		--29	Сообщение прослушано полностью (проинформирован)
		--30	Сообщение прослушано не полностью
		AND C.CommunicationResultId in (29,30)
		--За вчера
		AND cast(C.CommunicationDateTime AS date) = dateadd(DAY, -1, @today)

DROP TABLE IF EXISTS #t_IVR

SELECT 
	C.external_id,
	C.IVR_status_date, --дата воздействия IVR
	C.IVR_status --факт доставки воздействия . варианты 1\0. 1 - прослушано до контрольной точки , 0 - непрослушено
INTO #t_IVR
FROM ( 
	SELECT 
		T.external_id,
		max_IVR_status_date = max(T.IVR_status_date)
	FROM #t_IVR_0 AS T
	GROUP BY T.external_id
	) AS A
	INNER JOIN #t_IVR_0 AS C
		ON C.external_id = A.external_id
		AND C.IVR_status_date = A.max_IVR_status_date


drop table if exists #t_RPC_text
--DWH-2792

select
	contractGuid
	,RPC_text_d = sum(iif( cast(communication_createAt as date) =  @yesterday, 1, 0))
	,RPC_text_w = sum(iif( cast(communication_createAt as date)  between @dateBegin_week and @dateEnd_week, 1, 0))
	,RPC_text_m  = sum(iif( cast(communication_createAt as date)  between @dateBegin_month and @today, 1, 0))
into #t_RPC_text
from (
SELECT date_dpd_1 = min(iif(t.dpd > 0, dateadd(DAY, - t.dpd + 1, @today), cast(NULL AS date)))
			,CMRContractGUID
		from #t0 AS t
		where 1=1
		and dpd>0 --DWH-178
		group by CMRContractGUID
		) t
inner join dm.[230Fz_communication_text] ct
	on ct.contractGuid = t.CMRContractGUID
where ct.communication_createAt between
	dateadd(dd,-6, @dateBegin_month) /*если начало месяца выпало на вс, то надо считать с пн, и чтобы не вычислять понедельник отнимаем 6 дней*/
and cast(@today as datetime)
	AND ct.communication_createAt >= isnull(date_dpd_1, '1900-01-01')
	--and ct.method_code in ('sms', 'email', 'push') -- временно на время теста

group by ct.contractGuid
drop table if exists #t_RPC_call
--DWH-2872
select
	contractGuid
	,RPC_call_d = sum(iif( cast(communicationDate as date) =  @yesterday, 1, 0))
	,RPC_call_w = sum(iif( cast(communicationDate as date)  between @dateBegin_week and @dateEnd_week, 1, 0))
	,RPC_call_m  = sum(iif( cast(communicationDate as date)  between @dateBegin_month and @today, 1, 0))
	into #t_RPC_call
from (
SELECT date_dpd_1 = min(iif(t.dpd > 0, dateadd(DAY, - t.dpd + 1, @today), cast(NULL AS date)))
			,CMRContractGUID
		from #t0 AS t
		where 1=1
		and dpd>0 --DWH-178
		group by CMRContractGUID
		) t
inner join dm.[230Fz_communication_call] ct
	on ct.contractGuid = t.CMRContractGUID
where ct.communicationDate between 	dateadd(dd,-6, @dateBegin_month) /*если начало месяца выпало на вс, то надо считать с пн, и чтобы не вычислять понедельник отнимаем 6 дней*/
and cast(@today as datetime)
	AND ct.communicationDate >= isnull(date_dpd_1, '1900-01-01')

group by ct.contractGuid



--Rollback_fl - за последние 42 дня, по договору был откат минимум на 1 бакет 
--и сумма платежа >= регулярного ежемесячного платежа по графику ( 1 - да , 0 - нет)	 
--пока только переход по бакетам
DROP TABLE IF EXISTS #t_bucket_rollback
;WITH Bucket AS (
	SELECT 
		B.external_id,
		--B.d,
		--B.bucket,
		bucket_number = isnull(try_convert(int, substring(B.bucket, 2, 1)), 0),
		next_bucket_number = lead(isnull(try_convert(int, substring(B.bucket, 2, 1)), 0), 1, NULL) 
			OVER(PARTITION BY B.external_id ORDER BY B.d)
		--B.*
	FROM dbo.dm_CMRStatBalance AS B
	WHERE 1=1
		AND B.d >= dateadd(DAY, -42, @today)
)
SELECT DISTINCT K.external_id
INTO #t_bucket_rollback
FROM Bucket AS K
WHERE K.next_bucket_number < K.bucket_number

--num_of_missed_payments - Количество пропущенных регулярных платежей по договору	 
DROP TABLE IF EXISTS #t_num_of_missed_payments

SELECT B.external_id, num_of_missed_payments = count(1)
INTO #t_num_of_missed_payments
FROM #t0 AS t
	INNER JOIN dbo.dm_CMRStatBalance AS B (NOLOCK)
		ON t.external_id = B.external_id
WHERE 1=1
	AND B.d < @today -- сегодня не учитывать
	--AND isnull(B.[основной долг начислено],0) + isnull(B.[Проценты начислено],0) > 0
	AND isnull(B.[основной долг начислено],0) > 0

	AND isnull(B.[основной долг начислено],0) + isnull(B.[Проценты начислено],0)
		>
		isnull(B.[основной долг уплачено],0) + isnull(B.[Проценты уплачено],0)
GROUP BY B.external_id
--// DWH-1691

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #t_num_of_missed_payments', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END


--DWH-1866 flg_Rollback_on_bucket_for_last_3m
--Во время нахождения договора в просрочке (1<dpd<=90)
--был осуществлен откат на бакет назад как минимум один раз за последние 3 месяца.
DROP TABLE IF EXISTS #t_Rollback_on_bucket_for_last_3m
;WITH Bucket AS (
	SELECT 
		B.external_id,
		--B.d,
		--B.bucket,
		bucket_number = isnull(try_convert(int, substring(B.bucket, 2, 1)), 0),
		next_bucket_number = lead(isnull(try_convert(int, substring(B.bucket, 2, 1)), 0), 1, NULL) 
			OVER(PARTITION BY B.external_id ORDER BY B.d)
		--B.*
	FROM dbo.dm_CMRStatBalance AS B
	WHERE 1=1
		AND B.d >= dateadd(DAY, -90, @today)
		AND 0 < B.dpd AND B.dpd <= 90
)
SELECT DISTINCT K.external_id
INTO #t_Rollback_on_bucket_for_last_3m
FROM Bucket AS K
WHERE K.next_bucket_number < K.bucket_number

--IF @isLogger = 1 BEGIN
--	DROP TABLE IF EXISTS ##t_Rollback_on_bucket_for_last_3m
--	SELECT * INTO ##t_Rollback_on_bucket_for_last_3m FROM #t_Rollback_on_bucket_for_last_3m
--END
--// DWH-1866


--//DWH-1965 

SELECT @row_count = @@ROWCOUNT
IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT #t_Contract_Date', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END
--DWH-1896 признак наличия активного на дату заявления на ПДП

create table #t_active_Pdp (
	external_id nvarchar(21),
	ApplicationDate datetime
)
insert into #t_active_Pdp(external_id, ApplicationDate)
select 
		Договор_Номер = ДоговорНаЗайм.Номер
	,	датаЗаявление = dateadd(year,-2000,	заялениеДП.Дата)
	--,	НомерЗаявление =  заялениеДП.Номер			
	--,	ДатаПересчета = dateadd(year,-2000, iif(заялениеДП.ДатаПересчета>='4000-01-01', заялениеДП.ДатаПересчета, null))
	--,	ДатаОперации =dateadd(year,-2000, iif(заялениеДП.ДатаОперации>='4000-01-01', заялениеДП.ДатаОперации, null))
	--,	ДатаПДП = dateadd(year,-2000, iif(заялениеДП.ДатаПДП>='4000-01-01', заялениеДП.ДатаПДП, null))
	--,	СуммаПДП = заялениеДП.СуммаПДП
	--,	СтатусЗаяления = статусыЗаявления.Наименование			
	--,	ВидДП =  ВидыЧДП.Наименование		
	from stg._1cCRM.Документ_ЗаявлениеНаДосрочноеПогашение заялениеДП
inner join stg._1cCRM.Справочник_ВидыЧДП ВидыЧДП	
	on  ВидыЧДП.ССЫлка = заялениеДП.ВидЧДП
inner join stg._1cCRM.Справочник_СтатусыЗаявленийНаДосрочноеПогашение статусыЗаявления
	on статусыЗаявления.ССЫлка = заялениеДП.Статус
inner join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС 
	ДоговорНаЗайм on ДоговорНаЗайм.ССЫлка  =заялениеДП.Договор
where заялениеДП.ПометкаУдаления = 0x00
	and (ВидыЧДП.Наименование = 'ПДП')
	and  статусыЗаявления.Наименование in ('Ожидает списания')
	
	create clustered index cix on #t_active_Pdp(external_id)
	--DWH-1896 признак ПДП день в день по клиенту
	create table #t_Ppd_same_day(
		external_id nvarchar(21)
		)
	insert into #t_Ppd_same_day(external_id)
	select distinct
		external_id = д.Код
	from stg._1cCMR.Справочник_Договоры д 
	inner join 
	(
		
		select дсд.ДоговорЗайма
			,ДатаЗаписи
			,nRow = Row_number() over(partition by дсд.ДоговорЗайма order by дсд.ДатаЗаписи desc)
			,Значение_Булево
			from 
		 stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров дсд 
		inner join stg.[_1cCMR].[Справочник_ВидыДополнительнойИнформацииДоговоры] вдид
			on вдид.Ссылка = дсд.ВидДополнительнойИнформации
			and Наименование = 'Погашение день в день'
	
	) дсд on дсд.ДоговорЗайма = д.Ссылка
		and nRow = 1 --берем последнее св-во договора
		and Значение_Булево = 0x01 --при условие что он true
	create clustered index cix_external_id on #t_Ppd_same_day(external_id)
	--договора у которых через 30 полных дней будет достигнут лимит 1.3х --BP-3780
	create table #t_30d_until_accrualSuspension
	(
			external_id nvarchar(21)
			,flg_30d_until_accrualSuspension bit
			,date_30d_until_accrualSuspension datetime
	)
	insert into #t_30d_until_accrualSuspension(
		external_id
		,flg_30d_until_accrualSuspension
		,date_30d_until_accrualSuspension
	)
	select distinct
		external_id = д.Код
		,flg_30d_until_accrualSuspension = iif(дсд.Значение_Булево=0x01, 1, 0)
		,date_30d_until_accrualSuspension = dateadd(year,-2000, дсд.Период )
	from stg._1cCMR.Справочник_Договоры д 
	inner join(
		select 
			ДоговорЗайма
			,ВидДополнительнойИнформации
			,Период = max(Период)
			from stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров дсд 
				where дсд.ВидДополнительнойИнформации = 0xAE0608B887C008C74DA240F296130391 --Прогнозное превышение начислений через 30 дней
				--exists(Select top(1) 1 from stg.[_1cCMR].[Справочник_ВидыДополнительнойИнформацииДоговоры] вдид
				--where Наименование = 'Прогнозное превышение начислений через 30 дней'
				--and  вдид.Ссылка = дсд.ВидДополнительнойИнформации
				--)
			and Значение_Тип = 0x02 --Булево
			group by ДоговорЗайма
			,ВидДополнительнойИнформации
	) t_last
		on t_last.ДоговорЗайма = д.Ссылка
	inner join stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров дсд
		on дсд.ДоговорЗайма = t_last.ДоговорЗайма
		and дсд.ВидДополнительнойИнформации = t_last.ВидДополнительнойИнформации
		and дсд.Период = t_last.Период
		and дсд.Значение_Тип = 0x02 --Булево

	create clustered index cix_external_id on #t_30d_until_accrualSuspension(external_id)

	drop table if exists #PDLПролонгации
	select
		external_id = Код, 

	Renewal_number = sum(
	case ВидДвижения
			when 1 then Пролонгаций  
			when 0 then  0
		end ) 
	,Renewal_startdate = cast(dateadd(year,-2000, max(
		iif(ВидДвижения  = 1, pdl.Период, null)
		)) as date)
	,Renewal_enddate = cast(
		dateadd(year, -2000,
			max(парам_договора.ДатаОкончания)) as date)
		into #PDLПролонгации
		from 
	
		stg._1cCMR.Справочник_Договоры д 
		
		inner join stg._1cCMR.РегистрНакопления_PDLПролонгации pdl
			on pdl.Договор = д.ССЫлка  
		left join stg._1cCMR.РегистрСведений_ПараметрыДоговора	 парам_договора
			on парам_договора.Договор= д.ССЫлка
				and парам_договора.Регистратор_Ссылка = pdl.Регистратор_Ссылка
					and парам_договора.Регистратор_ТипСсылки = 0x0000005E
					and парам_договора.Период = pdl.Период 
					and pdl.ВидДвижения = 1
	where 1=1
		and exists(select top(1) 1 from stg._1cCMR.Справочник_ТипыПродуктов тип_продукта 
			where тип_продукта.Ссылка = д.ТипПродукта 
				and Наименование = 'Pdl')
	and dateadd(year,-2000, pdl.Период)< getdate()
	group by Код


	create clustered index cix on #PDLПролонгации(external_id)
	
   drop table if exists #t_last_sending_action
   --DWH-2474; DWH-2613
select 
CrmCustomerId
,last_date_sending_sms_IL_30duntilaccrSuspension  = max([SMS_ID_IL_30d_until_accrualSuspension]	)
,last_date_sending_mail_IL_30duntilaccrSuspension = max([EMAIL_ID_IL_30d_until_accrualSuspension])
,lastDateEmailPdl11				=	 max([EMAIL_ID_PDL_11])
,lastDateSmsPdl03				=	 max(SMS_ID_PDL_03)
into #t_last_sending_action
from (select 
	CrmCustomerId,
	ExternalNumber,
	CommunicationDate = max(CommunicationDate)
 from 
stg._collection.mv_Communications  c
inner join stg._collection.CommunicationTemplate   ct
	on c.CommunicationTemplateId = ct.Id
	and ExternalNumber in 
	('SMS_ID_IL_30d_until_accrualSuspension'
		,'EMAIL_ID_IL_30d_until_accrualSuspension'
		,'EMAIL_ID_PDL_11'
		,'SMS_ID_PDL_03'

	)

group by CrmCustomerId,
	ExternalNumber
	) t
	pivot (
		max(CommunicationDate) for ExternalNumber in ( 
			[SMS_ID_IL_30d_until_accrualSuspension], 
			[EMAIL_ID_IL_30d_until_accrualSuspension],
			[EMAIL_ID_PDL_11],
			[SMS_ID_PDL_03]

			)
	) pvt
group by CrmCustomerId	

create clustered index cix on #t_last_sending_action(CrmCustomerId)


	--BP-4315
	drop table if exists #t_AutoStatusValue
	select 
	
		c.CrmCustomerId
		,asv.autoSubStatusId 
		,autoSubStatusName = aus.Name
		,aus.autoStatusId
		,autoStatusName =  AutoStatus.Name
	into #t_AutoStatusValue
	from (
	--возможны дубликаты поэтому берем max(Id)
	select CustomerId, Id = max(Id) from stg._Collection.AutoStatusValue  asv
	where asv.IsActive = 1
	group by CustomerId
	) last_asv 
	inner join stg._Collection.AutoStatusValue  asv 
		on asv.Id = last_asv.Id
		and asv.CustomerId = last_asv.CustomerId
	inner join stg._Collection.AutoSubStatus  aus on aus.Id = asv.AutoSubStatusId
	inner join stg._Collection.AutoStatus AutoStatus on AutoStatus.Id = aus.AutoStatusId
	inner join stg._Collection.customers c on c.Id = asv.CustomerId


	--BP-4347 собираем информацию когда логином назначил стадию по договору 'Продан', 'Closed'
	drop table if exists  #t_loginom_Closed_date
	create table #t_loginom_Closed_date
	(
		external_id nvarchar(21),
		loginom_Closed_date date
	)
	insert into #t_loginom_Closed_date(external_id, loginom_Closed_date )
	select
	 ce.external_id
	,loginom_Closed_date = min([call_dt]) 

	from stg.[_loginom].[Collection_External_Stage_history] ce
		with(index = [ix_external_id_CRMContractGuid_call_dt])
	--where exists(select top(1) 1 from #t_Contract_Date t where t.external_id = ce.external_id)
	where External_Stage  in('Продан', 'Closed', 'Writeoff')
	group by ce.external_id
	create clustered index cix on #t_loginom_Closed_date(external_id)

	drop table if exists #t_lk_user
	select CRMClientGUID = external_guid
		,hasMobileApplicationEver = max(iif(fcm.last_fcm is not null, 1,0))
		into #t_lk_user
	from stg._lk.users u
	left join (
		select 
			user_id
			,last_fcm = max(id)
		from stg._lk.fcm fcm
		group by user_id
	
	) fcm on fcm.user_id = u.id
	where  nullif(u.external_guid, '') is not null
	group by external_guid
	create clustered index cix on #t_lk_user(CRMClientGUID)


	
	select top(0) 
		*	
	into #t_result
	from dm.Collection_StrategyDataMart

	insert into   #t_result
	 (
		[StrategyDate], 
		[fio], 
		[external_id], 
		[timeZoneGMT+], 
		[dpd], 
		[birth_date], 
		[principal_rest], 
		[overdue_amount], 
		[PTPDate], 
		[PTP], 
		[agent_flag], 
		[pay], 
		[last_pay_date], 
		[bankrupt], 
		[CRMClientGUID], 
		[death_flag], 
		[disabled_person_flag], 
		[hospital_flag], 
		[last_pay_amount_5d], 
		[last_rpc_date], 
		[last_call_att_date], 
		[num att], 
		[plan_date], 
		[plan_sum], 
		[first payment], 
		[collectionStage], 
		[currentDebt], 
		[UnconfirmedDeath_flag], 
		[Complaint_flag], 
		[FailureInteraction230FZ_flag], 
		[FailureInteractionWith3person230FZ_flag],
		[FeedbackConsentDataTransfer3person230FZ],
		[FRAUD_flag],
		[LackConsentPDProcessing_flag],
		[RejectProcessingPersonalData152FZ_flag],
		[RepresentativeInteraction230FZ_flag],
		[fraud_denyCall],
		[fail230_DenyCall],
		[complaint_DenyCall],
		[guid],
		[alco_flag],
		[maxDPDMore91_flag],
		[FPD60],
		[FPD30],
		[FPD4],
		[applicationScore],
		[overdue_398],
		[СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания],
		[СуммаПлатежейМеждуДатойОбещанияИТекущейДатой],
		[first_payment_flag],
		[last_attempt_date_home_mob],
		[last_attempt_date_thd],
		[last_attempt_date_work],
		[last_attempt_messengers],
		[last_contact_thd],
		[last_contact_date_work],
		[last_heared_message_date],
		[cnt_calltry_last5d],
		[cnt_calltry_last3d],
		[cnt_calltry_last3d_cl],
		[cnt_calltry_last3d_work],
		[last_contact_messengers],
		[last_contact_SKIP],
		[last_contact_meet],
		[workPhoneNotActual],
		[reject_paymet_last14days],
		[ptp_last14days],
		[broked_ptp_last_14days],
		[moscow_and_mo_flag],
		[EnforcementOrders_flag],
		[NUM_RPC_all_7d],
		[NUM_RPC_all_14d],
		[NUM_RPC_all_30d],
		[BankruptConfirmed],
		[BankruptUnconfirmed],
		[Region],
		[RegionActual],
		[FPD],
		[SPD],
		[TPD],
		[bv_flag],
		[EDOAgreement],
		[HasEngagementAgreement],
		[jail_flag],
		[ams_flag],
		[ams_date],
		[kk_flag],
		[space_ka_flag],
		[FraudUnConfirmed],
		[FraudConfirmed],
		[HardFraud],
		[DenyCollectors],
		[FraudConfirmed_DenyCollectors],
		[HardFraud_DenyCollectors],
		[space_ka_return_flag],
		[rpc91],
		[SkipEnterDate],
		[reject_paymet_last30days],
		[clnt_contact_last_all],
		[thd_contact_last_all],
		[start_buсket_date],
		[cnt_day_fail],
		[Skip_contact_add],
		[email],
		[clnt_email_flg],
		[reject_paymet_last_date],
		[startDate_1stKK],
		[endDate_1stKK],
		[povt_KK],
		[CallingCreditHolidays],
		[endDate_lastKK],
		[ams_value],
		[ptp_otl_PromiseDate],
		[probation],
		[RegionRegistration],
		[RegionRegistration_code]
		,download_app_email_sent_date
		,HasFreezing
	--	,change_date_plan_date	
	--	,old_plan_date			
		,end_date_payment_schedule
		,StartFreezing
		,EndFreezing	
		, reject_payment_dpd_1_88_count
		, date_of_Selling
		, totalPaymentAfterFreezing
		, clnt_FICO_score
		, IsInstallment
		, max_dpd_last_90d
		, full_early_repmt_rsn
		, BankruptCompleted
		, NeedToStartLegalProcess 
		--DWH-1691
		, RPC_text_d --Количество контактов с клиентом из категории 'Текстовые сообщения' за день. --колл. тексовых коммуникаци с клиентом за пред день DWH-2792
		, RPC_other_d --Количество контактов с клиентом из категории 'Иные воздействия' за день.
		, RPC_text_w --Количество контактов с клиентом из категории 'Текстовые сообщения' за неделю. --колл. тексовых коммуникаци с клиентом с начала недил DWH-2792
		, RPC_other_w --Количество контактов с клиентом из категории 'Иные воздействия' за неделю.
		, RPC_text_m --Количество контактов с клиентом из категории 'Текстовые сообщения' за месяц.  --колл. тексовых коммуникаци с клиентом с начала месяца DWH-2792    
		, RPC_other_m --Количество контактов с клиентом из категории 'Иные воздействия' за месяц
		-- При возникновении просрочки, счётчик должен обнуляться.
		, Region_fact -- Регион фактического проживания
		, customer_status --Статус клиента (Банкрот, смерть, FRAUD, отказ от взаимодействия 230-ФЗ и тд)
		, next_payment_amount --Начисленная задолженность на дату \ нарастающим итогом (вкл. штрафы)
		, customer_acceptance_to_3rd_party_communicaton --1/0 От клиента получено(1)  согласие на взаимодействие с 3ми лицами
		, customer_rejection_of_further_interactions --отказ клиента от дальнейших взамодействий
		, IVR_status_date --дата воздействия IVR
		, IVR_status --факт доставки воздействия . варианты 1\0. 1 - прослушано до контрольной точки , 0 - непрослушено
		, Rollback_fl --за последние 42 дня, по договору был откат минимум на 1 бакет
		, num_of_missed_payments --Количество пропущенных регулярных платежей по договору	 
		, SoftWare_fl	--флаг установки ПО
		, SoftWare_installed_date --дата установки по
		, SoftWare_removed_date --дата удаления ПО
		, Product_type --Наименование типа продукта
		, Product_name --Наименование продукта из справочника CMR. больший уровень детализации (напр. PTC31)
		, Active_PTP --наличие действующего обещания об оплате ( 1 - имеется \ 0 - отсутсвует)
		, customer_acceptance_to_frequent_interactions --согласия на учащенное взаимодействие
		,device_status_desc	-- статус устройства описание
		,device_status -- статус устройства 
		,device_status_date --дата статуса устройства
		,customer_acceptance_to_other_interactions --DWH-1809 согласие на иные воздействия "Согласие на иные воздействия" = Согласие на воздействие на устройство
		,Overdue_Interest --DWH-1805 Просроченные проценты (Начисленные на дату, но не уплаченные)
		,Litigation_fl--DWH-1747 признак подачи в суд
		,Start_date --DWH-1865 Дата старта договора
		,flg_Refused_to_sell_car --DWH-1863 поле "отказ от реализации авто"
		,flg_Refused_to_pay_at_PreLegal_2plus --DWH-1864 поле 2+ отказа от оплаты на стадии Prelegal
		,flg_Rollback_on_bucket_for_last_3m --DWH-1866 был осуществлен откат на бакет назад как минимум один раз за последние 3 месяца.
		,flg_Non_Contact --DWH-1867 Добавить поле в витрину стратегии Клиент не Контакт flg_Non_Contac
		,flg_Agreed_to_sell_car --DWH-1901 поле "согласие на реализацию авто"
		,flg_KK_SVO	--DWH-1923  У клиента имеются кредитные каникулы ( КК) с типом : Военные кредитные каникулы на сегодня.
		,isActive --DWH-1965 Флаг активности договора
		,endDate --DWH-1965 Дата когда договор стал не активным
		,flg_KK_SVO_ever --DWH-1997 Военные кредитные каникулы были хоть раз во время срока жизни договора
		,flg_active_Pdp --DWH-1896 признак наличия активного на дату заявления на ПДП
		,flg_Ppd_same_day --DWH-1896 признак отсутсвия ПДП день в день по клиенту
		--,ClaimInCourtDate --Дата подачи иска в суд DWH-2103
		,CustomerObligations --DWH-2094 Обязательства клиента
		,OpenTask_IP_cnt	-- DWH-2094 кол. открытых задач на стадии ИП--
		,OpenTask_Legal_cnt	-- DWH-2094 кол. открытых задач на стадии СП/Legal--		
		,last_name		--Фамилия	--DWH-2124
		,first_name		--Имя		--DWH-2124
		,patronymic		--Отчество	--DWH-2124
		,reason_for_accruals_suspension	--причина приостановки начислений DWH-2097
		,segment_code --сегмент - DWH-2150
		,segment_name --сегмент - DWH-2150
		,flg_30d_until_accrualSuspension --через 30 полных дней будет достигнут лимит 1.3х BP-3780
		,date_30d_until_accrualSuspension
		,Renewal_number			--Номер пролонгации по договору ( 1-2-3-4-5 ) --DWH-2300
		,Renewal_startdate		--Дата начала текущей пролонгации --DWH-2300
		,Renewal_enddate		--Планируемая дата окончания текущей пролонгации --DWH-2300
		,last_date_sending_sms_IL_30duntilaccrSuspension	--дата отправки коммуникации с определенным типом --DWH-2474
		,last_date_sending_mail_IL_30duntilaccrSuspension	--дата отправки коммуникации с определенным типом --DWH-2474
		,client_inn	--инн клиента DWH-2512
		,CourtClaimSendingDate -- Дата отправки иска в суд ---DWH-2561
		,autoStatusId		--ИД статуса Авто				BP-4315
		,autoStatusName		--Название статуса Авто			BP-4315
		,autoSubStatusId	--ИД под-статуса Авто			BP-4315
		,autoSubStatusName	--Название под-статуса Авто		BP-4315
		,hasBeenInKa --Договор ранее был в КА за любой период жизни договора
		,totalPaymentsAmtL90D --Сумма платежей за последние 90 дней
		,loginom_Closed_date --Дата закрытия договора логиномом
		,lastDateEmailPdl11 ---дата отправки коммуникации с определенным типом DWH-2613
		,lastDateSmsPdl03   ---дата отправки коммуникации с определенным типом DWH-2613
		,paymentPeriod		--платежный период --DWH-2625
		,total_payments		--cумма поступлений  нарастающим итогом DWH-2776 
		,hasMobileApplicationEver	--DWH-2852
		,max_dpd_ever		--DWH-2869
		,RPC_calls_d	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за день.
		,RPC_calls_w	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за неделя.
		,RPC_calls_m	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за месяц.
	    ,PDN --BP-624 
		,Product_SubTypeName  
		,Product_SubTypeCode  
	)

	  select distinct @today StrategyDate
		  , fio                                   = isnull(t.fio,'')
		  , t.external_id                           
		  , [timeZoneGMT+]                        = c.[timeZoneGMT+]
		  , dpd                                   = isnull(cmr_p.dpd,0)
		  , birth_date                            = t.birth_date
		  , principal_rest                        = isnull(t.principal_rest,0.0)
		  , overdue_amount                        = case when cmr_p.dpd_sum is not null then cmr_p.dpd_sum
														 else 
															   case when cmr_p.dpd_sum is null and t.overdue_amount is not null then t.overdue_amount else 0 end
													 end
		  , PTPDate                               = isnull(ptp_result.[PTP Date],'19000101')
		  , PTP                                   = try_cast(isnull(ptp_result.PTP,'0') as float)
		  , agent_flag=isnull(t.agent_flag,0)
		  , pay=cmr_p.last_payment_sum
		  , last_pay_date=cmr_p.last_payment_date
		  , --case when b.CrmCustomerId is not null then '1' else '0' end   
			bankrupt
		  , t.CRMClientGUID
		  , death_flag           --=case when confD.CrmCustomerId is not null then 1 else 0 end
		  , disabled_person_flag --=case when disP.CrmCustomerId is not null then 1 else 0 end
		  , hospital_flag        --=case when clientH.CrmCustomerId is not null then 1 else 0 end
	--  Сумма платежей за последние 5 дней
   
		   , last_pay_amount_5d  = Last5DaysPayments+isnull((-1.0*[balance_day-6].overdue),0)
								   --dwh 520
								   +isnull(papd_sum,0)

	--Дата последнего контакта с должником (RPC Date)
			, last_rpc_date = lrd.last_rpc_date
			, last_call_att_date=lcad.last_call_att_date
			, [num att]= case when isnull(na.cnt,'-1')='-1' then 0 else na.cnt end

    
			, plan_date=--dateadd(year,-2000,pd.paymentDate)
						pd.paymentDate
			, plan_sum=pd.paymentSum
			, [first payment]=[pi].first_payment
			, collectionStage=cmr_st.lastStatus--case when cmr_st.lastStatus='Погашен' then  cmr_st.lastStatus else isnull(cast(r.CollectionStage as nvarchar(100)),cmr_st.lastStatus) end
		   , currentDebt=cmr_p.dpd_sum
       
		   ,UnconfirmedDeath_flag                       --=case when unconfD.CrmCustomerId               is not null then 1 else 0 end
		   ,Complaint_flag                              --=case when complaint.CrmCustomerId             is not null then 1 else 0 end
		   ,FailureInteraction230FZ_flag                --=case when fail230.CrmCustomerId               is not null then 1 else 0 end
		   ,FailureInteractionWith3person230FZ_flag     --=case when fail3th230.CrmCustomerId            is not null then 1 else 0 end
		   ,FeedbackConsentDataTransfer3person230FZ     --=case when feedB.CrmCustomerId                 is not null then 1 else 0 end
		   ,FRAUD_flag                                  --=case when fraud.CrmCustomerId                 is not null then 1 else 0 end
		   ,LackConsentPDProcessing_flag                --=case when lcp.CrmCustomerId                   is not null then 1 else 0 end
		   ,RejectProcessingPersonalData152FZ_flag      --=case when rp230.CrmCustomerId                 is not null then 1 else 0 end
		   ,RepresentativeInteraction230FZ_flag         --=case when ri230.CrmCustomerId                 is not null then 1 else 0 end
		   ,fraud_denyCall                              --=isnull(fraud.denyCall    ,0)
		   ,fail230_DenyCall                            --=isnull(fail230.DenyCall  ,0)
		   ,complaint_DenyCall                          --=isnull(complaint.DenyCall,0)
		   , [guid]                            = CMRContractGUID---DBO.getGUIDFrom1C_IDRREF(C.Ссылка)

		   --dwh-398
		   --Флаг "Алкоголик / Наркоман / Игроман / В тюрьме"
		   , alco_flag                                  --= case  when alco_flag.CrmCustomerId is not null then '1' else '0' end 
		   --Флаг "Максимальная просрочка >= 91"
		   , maxDPDMore91_flag                          = case  when h91.external_id is not null then '1' else '0' end 
		   , FPD60                                      = fpd60
		   , FPD30                                      = fpd30
		   , FPD4                                       = fpd4
		   , applicationScore                           --= rsk.[group]
	-- dwh-398 Сумма переплаты на дату (остаток на счетах!) есть в DWH (если отрицательная, то умножаем на -1; если положительная, то указываем 0)
		   , overdue_398=case when overdue_amount<0 then -1*overdue_amount else 0.0 end
	-- dwh 398 Сумма оплаты с даты взятия обещания по текущую дату (или по дату обещания)
		   , ptp_p.СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания
		   , ptp_p.СуммаПлатежейМеждуДатойОбещанияИТекущейДатой
	-- dwh 398 Флаг "Первый Платеж"
		   , first_payment_flag                         = isnull([pi].first_payment_flag,0) /*case  when first_payment_flag.external_id is not null then '1' else '0' end */
	-- dwh 398 Дата последней попытки дозвона должнику (моб тел клиента или домашний, но именно с клиентом)
		   , last_attempt_date_home_mob                 = last_attempt_date_home_mob.max_CommunicationDate
	-- dwh 398       Дата последней попытки дозвона контактному лицу
		   , last_attempt_date_thd                      =last_attempt_date_thd.max_CommunicationDate
	-- dwh 398 Дата последней попытки дозвона работодателю
		   , last_attempt_date_work                     = last_attempt_date_work.max_CommunicationDate
	-- dwh 398 Дата последней попытки связать в мессенджере
		   , last_attempt_messengers                    = last_attempt_messengers.max_CommunicationDate
	-- dwh 398  Дата последнего контакта с 3-им лицом
		   , last_contact_thd                           = last_contact_thd.max_CommunicationDate
	-- dwh 398  Дата последнего контакта с работодателем
		   , last_contact_date_work                     = last_contact_date_work.max_CommunicationDate
	-- dwh 398 Дата последнего прослушанного сообщения (IVR)
		   , last_heared_message_date                   = last_heared_message_date .lastDate
	-- dwh 398 Кол-во попыток дозвона за последние 5 дней (клиент)
		   , cnt_calltry_last5d                         = case when isnull(cnt_calltry_last5d.cnt,'-1')='-1' then 0 else cnt_calltry_last5d.cnt end
	-- dwh 398 Кол-во попыток дозвона за последние 3 дня (клиент)
		   , cnt_calltry_last3d                         = case when isnull(cnt_calltry_last3d.cnt,'-1')='-1' then 0 else cnt_calltry_last3d.cnt end
	-- dwh 398 Кол-во попыток дозвона за последние 3 дня (контактное лицо)
		   , cnt_calltry_last3d_cl                      = case when isnull(cnt_calltry_last3d_cl.cnt,'-1')='-1' then 0 else cnt_calltry_last3d_cl.cnt end
	-- dwh 398 Кол-во попыток дозвона за последние 3 дня (работодатель)
		   , cnt_calltry_last3d_work                    = case when isnull(cnt_calltry_last3d_work.cnt,'-1')='-1' then 0 else cnt_calltry_last3d_work.cnt end
	-- dwh 398 Дата последнего контакта в мессенджерах
		   , last_contact_messengers                    =last_contact_messengers.max_CommunicationDate
	-- dwh 398 Дата последнего Skiptracing'a
		   , last_contact_SKIP                          = last_contact_SKIP .max_CommunicationDate
	-- dwh 398 Дата последнего выезда
		   , last_contact_meet                          = last_contact_meet.max_CommunicationDate
	-- dwh 398 Флаг "Отзыв данных Работодателем"
		   , workPhoneNotActual                         = case  when wf_n.CRMClientGUID is not null then '1' else '0' end 
	-- dwh 398 Флаг "Наличие отказа от оплаты за последние 14 дней"
		   , reject_paymet_last14days                   = case  when r14.CrmCustomerId is not null then '1' else '0' end 
	-- dwh 398 Флаг "Наличие обещания за последние 14 дней"
		   , ptp_last14days                             --= case  when ptp_last14days.CrmCustomerId is not null then '1' else '0' end 
	-- dwh 398 Флаг "Наличие нарушенного обещания за последние 14 дней"
		   , broked_ptp_last_14days                     --= case  when broked_ptp_last_14days.CRMClientGUID is not null then '1' else '0' end 
	--dwh 398  Флаг "Москва и МО"
		   , moscow_and_mo_flag                         = case when isnull(c.РегионФактическогоПроживания,'') in ('Московская обл','Москва') then '1' else '0' end 
		   , EnforcementOrders_flag                     --= case when isnull(eo.Accepted,0)=0 then 0  else eo.Accepted end
	--dwh-551
		   , NUM_RPC_all_7d                             --= isnull(NUM_RPC_all_7d    .cnt,0)
		   , NUM_RPC_all_14d                            --= isnull(NUM_RPC_all_14d   .cnt,0)
		   , NUM_RPC_all_30d                            --= isnull(NUM_RPC_all_30d   .cnt,0)
	--dwh-537
		   , BankruptConfirmed                          --= case  when BankruptConfirmed.CrmCustomerId is not null then '1' else '0' end 
		   , BankruptUnconfirmed                        --= case  when BankruptUnConfirmed.CrmCustomerId is not null then '1' else '0' end 
	--dwh-548
		   , Region       --reg.Region
		   , ActualRegion --reg.ActualRegion
	--dwh-578
		   , fpd                                       -- = case when _pd.fpd is not null then '1'  else '0' end
		   , spd                                       -- = case when _pd.spd is not null then '1'  else '0' end
		   , tpd                                       -- = case when _pd.tpd is not null then '1'  else '0' end
		   , bv_flag 
		   , EDOAgreement           
		   , HasEngagementAgreement
		   , jail_flag
		   , ams_flag 
		   , ams_date 
		   , kk_flag			= isnull(kk.kk_flag, 0)
		   , space_ka_flag
		   , FraudUnConfirmed 
		   , FraudConfirmed   
		   , HardFraud 
		   , DenyCollectors                 
		   , FraudConfirmed_DenyCollectors  
		   , HardFraud_DenyCollectors 
		   , space_ka_return_flag
		   , rpc91
		   , SkipEnterDate
		   , reject_paymet_last30days                   = case  when r30.CrmCustomerId is not null then '1' else '0' end 
		   , clnt_contact_last_all 
		   , thd_contact_last_all  
		   , start_buсket_date     
		   , cnt_day_fail          
		   , Skip_contact_add      
		   , email=c.ЭлектроннаяПочта
		   , clnt_email_flg
		   , reject_paymet_last_date
		   , startDate_1stKK		= kk.startDate_1stKK
		   , endDate_1stKK			= null
		   , povt_KK				= null
		   , CallingCreditHolidays	= null
		   , endDate_lastKK			= kk.endDate_lastKK
		   , ams_value				= null
		   , ptp_otl_PromiseDate
		   , probation
		   ,  RegionRegistration     
		   ,  RegionRegistration_code
		   , download_app_email_sent_date = last_send_download_app_email_sent.last_send_download_app_email_sent
		   , HasFreezing = iif(f.external_id is not null, 1, 0)
	   
		 --  , change_date_plan_date	= dateadd(year,-2000,pd.change_date_plan_date)  --DWH-1149
		 --  , old_plan_date			 = dateadd(year,-2000,pd.old_plan_date)  --DWH-1149
		   , end_date_payment_schedule = dateadd(year, -2000, pd.end_date_payment_schedule) --DWH-1155
		   , StartFreezing = f.Замороза_Начало	--DWH-1238
		   , EndFreezing = EOMONTH(f.Замороза_Окончание) --пишим последний день месяца	--DWH-1238
		   , reject_payment_dpd_1_88_count = rj88.reject_payment_dpd_1_88_count --DWH-1275
		   , date_of_Selling = пд.ДатаПродажаДоговора
		   , f.totalPaymentAfterFreezing
		   , clnt_FICO_score = fic03.FICO3_score 
		   --DWH-1413
		   , IsInstallment = isnull(t.IsInstallment,0)
		   , max_dpd_last_90d  = isnull(t.max_dpd_last_90d,0)
		   , full_early_repmt_rsn = rfi.ПричиныВыставленияПолнойЗадолженности
		   --DWH-1680
		   , BankruptCompleted = t.BankruptCompleted
		   , NeedToStartLegalProcess  = cast(isnull(Collection_Deal.NeedToStartLegalProcess,0)  as bit)
			
			, RPC_text_d =isnull(t_RPC_text.RPC_text_d,0) --Количество контактов с клиентом из категории 'Текстовые сообщения' за день.
			, RPC_other_d = 0 --Количество контактов с клиентом из категории 'Иные воздействия' за день.
			, RPC_text_w = isnull(t_RPC_text.RPC_text_w, 0) --Количество контактов с клиентом из категории 'Текстовые сообщения' за неделю.
			, RPC_other_w = 0 --Количество контактов с клиентом из категории 'Иные воздействия' за неделю.
			, RPC_text_m = isnull(t_RPC_text.RPC_text_m, 0) --Количество контактов с клиентом из категории 'Текстовые сообщения' за месяц.
			, RPC_other_m = 0 --Количество контактов с клиентом из категории 'Иные воздействия' за месяц
			, Region_fact = c.РегионФактическогоПроживания -- Регион фактического проживания
			, customer_status = convert(nvarchar(1024), CS.customer_status) --Статус клиента (Банкрот, смерть, FRAUD, отказ от взаимодействия 230-ФЗ и тд)
			, next_payment_amount = t.next_payment_amount --Начисленная задолженность на дату \ нарастающим итогом (вкл. штрафы)
			/* DWH-2485
			1- от клиента получено согласие на взаимодействие с 3ми лицами 
				customers.ThirdPartiesInteractionAgreementSignedDate   
				and FailureInteractionWith3person230FZ_flag is null
			0- от клиента НЕ получено согласие на  взаимодействие с 3ми лицами \ OR получен отказ \ OR др. 
				FailureInteractionWith3person230FZ_flag - Отказ от взаимодействия с 3-ми лицами (230-ФЗ)
			*/
			, customer_acceptance_to_3rd_party_communicaton = iif(
				t.ThirdPartiesInteractionAgreementSignedDate   is not null
				and isnull(FailureInteractionWith3person230FZ_flag,0) !=1
				, 1, 0) 
			/*
			Отказ клиента от дальнейших взамодействий - DWH-2485
				--Отказ от взаимодействия по 230 ФЗ
			*/
			, customer_rejection_of_further_interactions = iif(
				FailureInteraction230FZ_flag  = 1  --
				,1, 0)
			, IVR_status_date = IVR.IVR_status_date --дата воздействия IVR
			, IVR_status = IVR.IVR_status --факт доставки воздействия . варианты 1\0. 1 - прослушано до контрольной точки , 0 - непрослушено
			, Rollback_fl = iif(BRL.external_id IS NOT NULL, 1, 0) --за последние 42 дня, по договору был откат минимум на 1 бакет
			, MP.num_of_missed_payments --Количество пропущенных регулярных платежей по договору	 
			, SoftWare_fl = isnull(c.isSetSoftWare,0)
			, SoftWare_installed_date = c.SoftWare_installed_date
			, SoftWare_removed_date = c.SoftWare_removed_date
			, Product_type = t.Product_type --Наименование типа продукта
			, Product_name = t.КредитныеПродукт --Наименование продукта из справочника CMR. больший уровень детализации (напр. PTC31)
			--наличие действующего обещания об оплате ( 1 - имеется \ 0 - отсутсвует)
			--Изменение логики в рамках - DWH-2531, учитывать отложенное обещание
			, Active_PTP = 
					case 
						--дата действующего обещания об оплате 
						when ptp_result.[PTP Date]> =@today then 1
						when t.ptp_otl_PromiseDate > =@today then 1 -- дата отложенного обещания
						else 0 end
			, customer_acceptance_to_frequent_interactions = t.HasEngagementAgreement 
			, ds.device_status_desc
			, ds.device_status
			, ds.device_status_date
			--DWH-1809 согласие на иные воздействия "Согласие на иные воздействия" = Согласие на воздействие на устройство
			, customer_acceptance_to_other_interactions = iif(t.MobileDeviceImpactConsentSignedDate is not null, 1, 0)
			, t.Overdue_Interest --DWH-1805 Просроченные проценты (Начисленные на дату, но не уплаченные)
			, Litigation_fl      = iif(jc.TotalAmountRequirements>0, 1, 0) --DWH-1747 если сумма искать >0 считаем что подали в суд
			, Start_date = t.credit_date --DWH-1865 Дата старта договора
			, t.flg_Refused_to_sell_car --DWH-1863 поле "Отказ от реализации авто"

			--DWH-1864 поле "2+ отказа от оплаты на стадии Prelegal"
			, flg_Refused_to_pay_at_PreLegal_2plus = iif(rtp2.CrmCustomerId IS NOT NULL, 1, 0)
			--DWH-1866 был осуществлен откат на бакет назад как минимум один раз за последние 3 месяца.
			, flg_Rollback_on_bucket_for_last_3m = iif(rbl3.external_id IS NOT NULL, 1, 0)
			--DWH-1867 Добавить поле в витрину стратегии Клиент не Контакт flg_Non_Contact
			, flg_Non_Contact = iif(ncnt.CrmCustomerId IS NOT NULL, 1, 0)
			, t.flg_Agreed_to_sell_car --DWH-1901 поле "Согласие на реализацию авто"
			, flg_KK_SVO = isnull(kk.flg_KK_SVO, 0) --DWH-1923  У клиента имеются кредитные каникулы ( КК) с типом : Военные кредитные каникулы на сегодня.
			, isActive = cmr_st.isActive --DWH-1965 Флаг активности договора
			, endDate = case cmr_st.LastStatus
				when 'Аннулирован' then cmr_st.Дата
				else  t.contract_end end --DWH-1965 Дата когда договор стал не активным
			, flg_KK_SVO_ever = isnull(kk.flg_KK_SVO_ever, 0) --DWH-1997 Военные кредитные каникулы были хоть раз во время срока жизни договора
			, flg_active_Pdp = iif(active_Pdp.external_id is not null, 1, 0) --DWH-1896 признак наличия активного на дату заявления на ПДП
			, flg_Ppd_same_day = iif(Ppd_same_day.external_id is not null, 1, 0)  --DWH-1896 признак наличие ПДП день в день по клиенту
			--, jc.ClaimInCourtDate --DWH-2094 Дата подачи иска в суд
			, t.CustomerObligations --DWH-2094 Обязательства клиента
			, OpenTask_IP_cnt		= isnull(Collection_Deal.OpenTask_IP_cnt,0)		-- DWH-2094 кол. открытых задач на стадии ИП
			, OpenTask_Legal_cnt	= isnull(Collection_Deal.OpenTask_Legal_cnt,0)	-- DWH-2094 кол. открытых задач на стадии СП/Legal
			, t.last_name
			, t.first_name
			, t.patronymic
			, reason_for_accruals_suspension = rsa.ПричиныОстановкиНачислений --DWH-2097 причина приостановки начислений
			, t.segment_code --сегмент - DWH-2150
			, t.segment_name --сегмент - DWH-2150
			, flg_30d_until_accrualSuspension = isnull([30d_until_accrualSuspension].flg_30d_until_accrualSuspension,0) --через 30 полных дней будет достигнут лимит 1.3х BP-3780
			, date_30d_until_accrualSuspension = [30d_until_accrualSuspension].date_30d_until_accrualSuspension
			, Renewal_number		 = PDLПролонгации.Renewal_number	--Номер пролонгации по договору ( 1-2-3-4-5 ) --DWH-2300
			, Renewal_startdate	 = PDLПролонгации.Renewal_startdate	--Дата начала текущей пролонгации --DWH-2300
			, Renewal_enddate	 = PDLПролонгации.Renewal_enddate	--Планируемая дата окончания текущей пролонгации --DWH-2300
			, last_date_sending_sms_IL_30duntilaccrSuspension	= last_sending_action.last_date_sending_sms_IL_30duntilaccrSuspension
			, last_date_sending_mail_IL_30duntilaccrSuspension	= last_sending_action.last_date_sending_mail_IL_30duntilaccrSuspension
			, t.Client_inn --DWH-2512 инн клиента
			, jc.CourtClaimSendingDate  --DWH-2561 --Дата отправки иска в суд
			, asv.autoStatusId		--ИД статуса Авто				BP-4315
			, asv.autoStatusName	--Название статуса Авто			BP-4315
			, asv.autoSubStatusId	--ИД под-статуса Авто			BP-4315
			, asv.autoSubStatusName	--Название под-статуса Авто		BP-4315
			, t.hasBeenInKa --Договор ранее был в КА за любой период жизни договора
			, t.totalPaymentsAmtL90D --Сумма платежей за последние 90 дней
			, lcd.loginom_Closed_date --дата закрытия логиномом договора
			, lastDateEmailPdl11	= last_sending_action.lastDateEmailPdl11	--дата отправки коммуникации с определенным типом DWH-2613
			, lastDateSmsPdl03		= last_sending_action.lastDateSmsPdl03	--дата отправки коммуникации с определенным типом DWH-2613
			, paymentPeriod			= [pi].paymentPeriod  --DWH-2625 -- платежный период
			, total_payments		= t.total_payments	  --DWH-2776 --cумма поступлений  нарастающим итогом
			,hasMobileApplicationEver = isnull(lk_user.hasMobileApplicationEver,0) --DWH-2852
			,max_dpd_ever		= t.max_dpd_begin --DWH-2869
			,RPC_calls_d		= isnull(rpc_call.RPC_call_d,0) --DWH-2872
			,RPC_calls_w		= isnull(rpc_call.RPC_call_w,0) --DWH-2872
			,RPC_calls_m		= isnull(rpc_call.RPC_call_m,0) --DWH-2872
			,t.PDN--BP-624
			,t.Product_SubTypeName  
		    ,t.Product_SubTypeCode  
	--select distinct * 
	--into dm.Collection_StrategyDataMart
	 from #t01 t
  
	  left join #crm_info c on c.НомерЗаявки=t.external_id
  
	  left join #cmr_p cmr_p on cmr_p.external_id=t.external_id

	  left join #t_ptp_result ptp_result on ptp_result.external_id=t.external_id
	  left join #hist_91 h91 on h91.external_id=t.external_id
 
	  left join #last_rpc_date lrd on lrd.CrmCustomerId=t.CRMClientGUID
	  left join #last_call_att_date lcad on lcad.CrmCustomerId=t.CRMClientGUID
	  left join #num_att na on na.CrmCustomerId=t.CRMClientGUID
	  left join #plan_date pd on pd.external_id=t.external_id
	  left join #paymentInfo [pi] on [pi].external_id=t.external_id
	  --left join #rs r on r.external_id=t.external_id
  
	  left join #cmrStatuses cmr_st on cmr_st.external_id=t.external_id
	  left join #workPhoneNotActual wf_n on wf_n.CRMClientGUID=t.CRMClientGUID
	  left join #reject_paymet_last14days r14 on r14.CrmCustomerId=t.CRMClientGUID
	  left join #reject_paymet_last30days r30 on r30.CrmCustomerId=t.CRMClientGUID
	--left join #ptp_last14days  ptp_last14days on ptp_last14days.CrmCustomerId=t.CRMClientGUID

	left join #last_attempt_date_home_mob last_attempt_date_home_mob  on last_attempt_date_home_mob .CRMClientGUID=t.CRMClientGUID
	left join #last_attempt_date_work last_attempt_date_work on last_attempt_date_work.CRMClientGUID=t.CRMClientGUID
	left join #last_attempt_messengers last_attempt_messengers on last_attempt_messengers.CrmCustomerId=t.CRMClientGUID
	left join #last_contact_SKIP last_contact_SKIP  on last_contact_SKIP .CrmCustomerId=t.CRMClientGUID
	left join #last_contact_meet last_contact_meet on last_contact_meet.CrmCustomerId=t.CRMClientGUID

	left join #cnt_calltry_last5d cnt_calltry_last5d on cnt_calltry_last5d.CrmCustomerId=t.CRMClientGUID
	left join #cnt_calltry_last3d     cnt_calltry_last3d on cnt_calltry_last3d.CrmCustomerId=t.CRMClientGUID
	left join #cnt_calltry_last3d_cl  cnt_calltry_last3d_cl   on cnt_calltry_last3d_cl.CrmCustomerId=t.CRMClientGUID
	left join #cnt_calltry_last3d_work cnt_calltry_last3d_work on cnt_calltry_last3d_work.CrmCustomerId=t.crmClientGUID

	--left join #broked_ptp_last_14days broked_ptp_last_14days on broked_ptp_last_14days.CRMClientGUID=t.CRMClientGUID

	left join #ptp_payments ptp_p on ptp_p.external_id=t.external_id
	left join #last_heared_message_date last_heared_message_date on last_heared_message_date .RequestID=t.external_id
	left join #last_attempt_date_thd last_attempt_date_thd on last_attempt_date_thd.CrmCustomerId=t.CRMClientGUID
	left join #last_contact_thd last_contact_thd on last_contact_thd.CrmCustomerId=t.CRMClientGUID
	left join #last_contact_date_work  last_contact_date_work on last_contact_date_work.CRMClientGUID=t.CRMClientGUID
	left join #last_contact_messengers last_contact_messengers on last_contact_messengers.CrmCustomerId=t.CRMClientGUID

	--left join #rsk rsk on rsk.external_id=t.external_id

	--dwh-481
	--left join #EnforcementOrders eo on eo.Number=t.external_id
	left join dbo.dm_CMRStatBalance [balance_day-6] on [balance_day-6].d=dateadd(day,-6,@today) and [balance_day-6].external_id=t.external_id
	left join #last_send_download_app_email_sent last_send_download_app_email_sent on last_send_download_app_email_sent.Number = t.external_id
	left join #t_Freezing f on f.external_id=t.external_id
	--dwh-1275
	left join #reject_payment_1_88_days_group rj88 on rj88 .external_id = t.external_id
	--DWH-1273
	left join #t_ПродажаДоговоров пд on пд.external_id = t.external_id
	--
	left join #t_WorkFlow_FICO3_score fic03 on fic03.external_id = t.external_id
	
	--DWH-1566
	left join #ReasonforFullIndebtedness rfi on rfi.external_id = t.external_id
	left join #t_Collection_Deals Collection_Deal on Collection_Deal.external_id = t.external_id
	--DWH-1691
	LEFT JOIN #t_customer_status AS CS on CS.CrmCustomerId = t.CRMClientGUID
	LEFT JOIN #t_IVR AS IVR ON IVR.external_id = t.external_id
	LEFT JOIN #t_bucket_rollback AS BRL ON BRL.external_id = t.external_id
	LEFT JOIN #t_num_of_missed_payments AS MP ON MP.external_id = t.external_id
	left join #t_Collection_device_status ds on ds.external_id = t.external_id
	left join #t_JudicialClaims  jc on jc.external_id = t.external_id
	LEFT JOIN #t_Refused_to_pay_at_PreLegal_2 AS rtp2 ON rtp2.CrmCustomerId = t.CRMClientGUID
	LEFT JOIN #t_Rollback_on_bucket_for_last_3m AS rbl3 ON rbl3.external_id = t.external_id
	LEFT JOIN #t_Non_Contact AS ncnt ON ncnt.CrmCustomerId = t.CRMClientGUID AND t.dpd > 0
	left join #t_КК kk on kk.external_id = t.external_id
	
	left join #t_active_Pdp as active_Pdp on active_Pdp.external_id = t.external_id
	left join #t_Ppd_same_day as Ppd_same_day  on Ppd_same_day.external_id  = t.external_id
	left join #Reasons2StoppingAccruals rsa on rsa.external_id = t.external_id --DWH-2097 причины почему начисления были остановлены
	left join #t_30d_until_accrualSuspension [30d_until_accrualSuspension] 	on 
		[30d_until_accrualSuspension].external_id = t.external_id
	left join #PDLПролонгации PDLПролонгации on 
		PDLПролонгации.external_id = t.external_id
		--DWH-2474; DWH-2613
	left join #t_last_sending_action last_sending_action on 
		last_sending_action.CrmCustomerId = t.CRMClientGUID
		--BP-4315
	left join #t_AutoStatusValue asv on asv.CrmCustomerId = t.CRMClientGUID
		--BP-4347 дата закрытия договор 
	left join #t_loginom_Closed_date lcd on lcd.external_id = t.external_id
	left join #t_RPC_text t_RPC_text on t_RPC_text.contractGuid
		= t.CMRContractGUID
	left join #t_lk_user lk_user on lk_user.CRMClientGUID = t.CRMClientGUID 
	left join #t_RPC_call rpc_call  on rpc_call.contractGuid = t.CMRContractGUID

begin		
begin tran
  delete from dm.Collection_StrategyDataMart
	where strategydate=@today
	--alter table dm.Collection_StrategyDataMart
	--	add PDN money 
	/*
	alter table	dm.Collection_StrategyDataMart
		add  Product_SubTypeName  nvarchar(512)
		,Product_SubTypeCode   nvarchar(255)
	)
	*/
  insert into dm.Collection_StrategyDataMart with(tablockX)
	   (
		[StrategyDate], 
		[fio], 
		[external_id], 
		[timeZoneGMT+], 
		[dpd], 
		[birth_date], 
		[principal_rest], 
		[overdue_amount], 
		[PTPDate], 
		[PTP], 
		[agent_flag], 
		[pay], 
		[last_pay_date], 
		[bankrupt], 
		[CRMClientGUID], 
		[death_flag], 
		[disabled_person_flag], 
		[hospital_flag], 
		[last_pay_amount_5d], 
		[last_rpc_date], 
		[last_call_att_date], 
		[num att], 
		[plan_date], 
		[plan_sum], 
		[first payment], 
		[collectionStage], 
		[currentDebt], 
		[UnconfirmedDeath_flag], 
		[Complaint_flag], 
		[FailureInteraction230FZ_flag], 
		[FailureInteractionWith3person230FZ_flag],
		[FeedbackConsentDataTransfer3person230FZ],
		[FRAUD_flag],
		[LackConsentPDProcessing_flag],
		[RejectProcessingPersonalData152FZ_flag],
		[RepresentativeInteraction230FZ_flag],
		[fraud_denyCall],
		[fail230_DenyCall],
		[complaint_DenyCall],
		[guid],
		[alco_flag],
		[maxDPDMore91_flag],
		[FPD60],
		[FPD30],
		[FPD4],
		[applicationScore],
		[overdue_398],
		[СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания],
		[СуммаПлатежейМеждуДатойОбещанияИТекущейДатой],
		[first_payment_flag],
		[last_attempt_date_home_mob],
		[last_attempt_date_thd],
		[last_attempt_date_work],
		[last_attempt_messengers],
		[last_contact_thd],
		[last_contact_date_work],
		[last_heared_message_date],
		[cnt_calltry_last5d],
		[cnt_calltry_last3d],
		[cnt_calltry_last3d_cl],
		[cnt_calltry_last3d_work],
		[last_contact_messengers],
		[last_contact_SKIP],
		[last_contact_meet],
		[workPhoneNotActual],
		[reject_paymet_last14days],
		[ptp_last14days],
		[broked_ptp_last_14days],
		[moscow_and_mo_flag],
		[EnforcementOrders_flag],
		[NUM_RPC_all_7d],
		[NUM_RPC_all_14d],
		[NUM_RPC_all_30d],
		[BankruptConfirmed],
		[BankruptUnconfirmed],
		[Region],
		[RegionActual],
		[FPD],
		[SPD],
		[TPD],
		[bv_flag],
		[EDOAgreement],
		[HasEngagementAgreement],
		[jail_flag],
		[ams_flag],
		[ams_date],
		[kk_flag],
		[space_ka_flag],
		[FraudUnConfirmed],
		[FraudConfirmed],
		[HardFraud],
		[DenyCollectors],
		[FraudConfirmed_DenyCollectors],
		[HardFraud_DenyCollectors],
		[space_ka_return_flag],
		[rpc91],
		[SkipEnterDate],
		[reject_paymet_last30days],
		[clnt_contact_last_all],
		[thd_contact_last_all],
		[start_buсket_date],
		[cnt_day_fail],
		[Skip_contact_add],
		[email],
		[clnt_email_flg],
		[reject_paymet_last_date],
		[startDate_1stKK],
		[endDate_1stKK],
		[povt_KK],
		[CallingCreditHolidays],
		[endDate_lastKK],
		[ams_value],
		[ptp_otl_PromiseDate],
		[probation],
		[RegionRegistration],
		[RegionRegistration_code]
		,download_app_email_sent_date
		,HasFreezing
		,change_date_plan_date	
		,old_plan_date			
		,end_date_payment_schedule
		,StartFreezing
		,EndFreezing	
		, reject_payment_dpd_1_88_count
		, date_of_Selling
		, totalPaymentAfterFreezing
		, clnt_FICO_score
		, IsInstallment
		, max_dpd_last_90d
		, full_early_repmt_rsn
		, BankruptCompleted
		, NeedToStartLegalProcess 
		--DWH-1691
		
		, RPC_text_d --Количество контактов с клиентом из категории 'Текстовые сообщения' за день.
		, RPC_other_d --Количество контактов с клиентом из категории 'Иные воздействия' за день.
		, RPC_text_w --Количество контактов с клиентом из категории 'Текстовые сообщения' за неделю.
		, RPC_other_w --Количество контактов с клиентом из категории 'Иные воздействия' за неделю.
		, RPC_text_m --Количество контактов с клиентом из категории 'Текстовые сообщения' за месяц.
		, RPC_other_m --Количество контактов с клиентом из категории 'Иные воздействия' за месяц
		-- При возникновении просрочки, счётчик должен обнуляться.
		, Region_fact -- Регион фактического проживания
		, customer_status --Статус клиента (Банкрот, смерть, FRAUD, отказ от взаимодействия 230-ФЗ и тд)
		, next_payment_amount --Начисленная задолженность на дату \ нарастающим итогом (вкл. штрафы)
		, customer_acceptance_to_3rd_party_communicaton --1/0 От клиента получено(1)  согласие на взаимодействие с 3ми лицами
		, customer_rejection_of_further_interactions --отказ клиента от дальнейших взамодействий
		, IVR_status_date --дата воздействия IVR
		, IVR_status --факт доставки воздействия . варианты 1\0. 1 - прослушано до контрольной точки , 0 - непрослушено
		, Rollback_fl --за последние 42 дня, по договору был откат минимум на 1 бакет
		, num_of_missed_payments --Количество пропущенных регулярных платежей по договору	 
		, SoftWare_fl	--флаг установки ПО
		, SoftWare_installed_date --дата установки по
		, SoftWare_removed_date --дата удаления ПО
		, Product_type --Наименование типа продукта
		, Product_name --Наименование продукта из справочника CMR. больший уровень детализации (напр. PTC31)
		, Active_PTP --наличие действующего обещания об оплате ( 1 - имеется \ 0 - отсутсвует)
		, customer_acceptance_to_frequent_interactions --согласия на учащенное взаимодействие
		,device_status_desc	-- статус устройства описание
		,device_status -- статус устройства 
		,device_status_date --дата статуса устройства
		,customer_acceptance_to_other_interactions --DWH-1809 согласие на иные воздействия "Согласие на иные воздействия" = Согласие на воздействие на устройство
		,Overdue_Interest --DWH-1805 Просроченные проценты (Начисленные на дату, но не уплаченные)
		,Litigation_fl--DWH-1747 признак подачи в суд
		,Start_date --DWH-1865 Дата старта договора
		,flg_Refused_to_sell_car --DWH-1863 поле "отказ от реализации авто"
		,flg_Refused_to_pay_at_PreLegal_2plus --DWH-1864 поле 2+ отказа от оплаты на стадии Prelegal
		,flg_Rollback_on_bucket_for_last_3m --DWH-1866 был осуществлен откат на бакет назад как минимум один раз за последние 3 месяца.
		,flg_Non_Contact --DWH-1867 Добавить поле в витрину стратегии Клиент не Контакт flg_Non_Contac
		,flg_Agreed_to_sell_car --DWH-1901 поле "согласие на реализацию авто"
		,flg_KK_SVO	--DWH-1923  У клиента имеются кредитные каникулы ( КК) с типом : Военные кредитные каникулы на сегодня.
		,isActive --DWH-1965 Флаг активности договора
		,endDate --DWH-1965 Дата когда договор стал не активным
		,flg_KK_SVO_ever --DWH-1997 Военные кредитные каникулы были хоть раз во время срока жизни договора
		,flg_active_Pdp --DWH-1896 признак наличия активного на дату заявления на ПДП
		,flg_Ppd_same_day --DWH-1896 признак отсутсвия ПДП день в день по клиенту
		--,ClaimInCourtDate --Дата подачи иска в суд DWH-2103
		,CustomerObligations --DWH-2094 Обязательства клиента
		,OpenTask_IP_cnt	-- DWH-2094 кол. открытых задач на стадии ИП--
		,OpenTask_Legal_cnt	-- DWH-2094 кол. открытых задач на стадии СП/Legal--		
		,last_name		--Фамилия	--DWH-2124
		,first_name		--Имя		--DWH-2124
		,patronymic		--Отчество	--DWH-2124
		,reason_for_accruals_suspension	--причина приостановки начислений DWH-2097
		,segment_code --сегмент - DWH-2150
		,segment_name --сегмент - DWH-2150
		,flg_30d_until_accrualSuspension --через 30 полных дней будет достигнут лимит 1.3х BP-3780
		
		
		,Renewal_number			--Номер пролонгации по договору ( 1-2-3-4-5 ) --DWH-2300
		,Renewal_startdate		--Дата начала текущей пролонгации --DWH-2300
		,Renewal_enddate		--Планируемая дата окончания текущей пролонгации --DWH-2300
		,date_30d_until_accrualSuspension
		,last_date_sending_sms_IL_30duntilaccrSuspension	--дата отправки коммуникации с определенным типом --DWH-2474
		,last_date_sending_mail_IL_30duntilaccrSuspension	--дата отправки коммуникации с определенным типом --DWH-2474
		,client_inn	--инн клиента DWH-2512
		,CourtClaimSendingDate -- Дата отправки иска в суд ---DWH-2561
		,autoStatusId		--ИД статуса Авто				BP-4315
		,autoStatusName		--Название статуса Авто			BP-4315
		,autoSubStatusId	--ИД под-статуса Авто			BP-4315
		,autoSubStatusName	--Название под-статуса Авто		BP-4315
		,hasBeenInKa --Договор ранее был в КА за любой период жизни договора
		,totalPaymentsAmtL90D --Сумма платежей за последние 90 дней
		,loginom_Closed_date --Дата закрытия договора логиномом
		,lastDateEmailPdl11 ---дата отправки коммуникации с определенным типом DWH-2613
		,lastDateSmsPdl03   ---дата отправки коммуникации с определенным типом DWH-2613
		,paymentPeriod		--платежный период --DWH-2625
		,total_payments		--cумма поступлений  нарастающим итогом DWH-2776 
		,hasMobileApplicationEver --было скачено мобильное приложение DWH-2852
		,max_dpd_ever --DWH-2869
		,RPC_calls_d	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за день.
		,RPC_calls_w	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за неделя.
		,RPC_calls_m	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за месяц.
		,PDN--BP-624
		,Product_SubTypeName  
		,Product_SubTypeCode  
	)

	select 
		[StrategyDate], 
		[fio], 
		[external_id], 
		[timeZoneGMT+], 
		[dpd], 
		[birth_date], 
		[principal_rest], 
		[overdue_amount], 
		[PTPDate], 
		[PTP], 
		[agent_flag], 
		[pay], 
		[last_pay_date], 
		[bankrupt], 
		[CRMClientGUID], 
		[death_flag], 
		[disabled_person_flag], 
		[hospital_flag], 
		[last_pay_amount_5d], 
		[last_rpc_date], 
		[last_call_att_date], 
		[num att], 
		[plan_date], 
		[plan_sum], 
		[first payment], 
		[collectionStage], 
		[currentDebt], 
		[UnconfirmedDeath_flag], 
		[Complaint_flag], 
		[FailureInteraction230FZ_flag], 
		[FailureInteractionWith3person230FZ_flag],
		[FeedbackConsentDataTransfer3person230FZ],
		[FRAUD_flag],
		[LackConsentPDProcessing_flag],
		[RejectProcessingPersonalData152FZ_flag],
		[RepresentativeInteraction230FZ_flag],
		[fraud_denyCall],
		[fail230_DenyCall],
		[complaint_DenyCall],
		[guid],
		[alco_flag],
		[maxDPDMore91_flag],
		[FPD60],
		[FPD30],
		[FPD4],
		[applicationScore],
		[overdue_398],
		[СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания],
		[СуммаПлатежейМеждуДатойОбещанияИТекущейДатой],
		[first_payment_flag],
		[last_attempt_date_home_mob],
		[last_attempt_date_thd],
		[last_attempt_date_work],
		[last_attempt_messengers],
		[last_contact_thd],
		[last_contact_date_work],
		[last_heared_message_date],
		[cnt_calltry_last5d],
		[cnt_calltry_last3d],
		[cnt_calltry_last3d_cl],
		[cnt_calltry_last3d_work],
		[last_contact_messengers],
		[last_contact_SKIP],
		[last_contact_meet],
		[workPhoneNotActual],
		[reject_paymet_last14days],
		[ptp_last14days],
		[broked_ptp_last_14days],
		[moscow_and_mo_flag],
		[EnforcementOrders_flag],
		[NUM_RPC_all_7d],
		[NUM_RPC_all_14d],
		[NUM_RPC_all_30d],
		[BankruptConfirmed],
		[BankruptUnconfirmed],
		[Region],
		[RegionActual],
		[FPD],
		[SPD],
		[TPD],
		[bv_flag],
		[EDOAgreement],
		[HasEngagementAgreement],
		[jail_flag],
		[ams_flag],
		[ams_date],
		[kk_flag],
		[space_ka_flag],
		[FraudUnConfirmed],
		[FraudConfirmed],
		[HardFraud],
		[DenyCollectors],
		[FraudConfirmed_DenyCollectors],
		[HardFraud_DenyCollectors],
		[space_ka_return_flag],
		[rpc91],
		[SkipEnterDate],
		[reject_paymet_last30days],
		[clnt_contact_last_all],
		[thd_contact_last_all],
		[start_buсket_date],
		[cnt_day_fail],
		[Skip_contact_add],
		[email],
		[clnt_email_flg],
		[reject_paymet_last_date],
		[startDate_1stKK],
		[endDate_1stKK],
		[povt_KK],
		[CallingCreditHolidays],
		[endDate_lastKK],
		[ams_value],
		[ptp_otl_PromiseDate],
		[probation],
		[RegionRegistration],
		[RegionRegistration_code]
		,download_app_email_sent_date
		,HasFreezing
		,change_date_plan_date	
		,old_plan_date			
		,end_date_payment_schedule
		,StartFreezing
		,EndFreezing	
		, reject_payment_dpd_1_88_count
		, date_of_Selling
		, totalPaymentAfterFreezing
		, clnt_FICO_score
		, IsInstallment
		, max_dpd_last_90d
		, full_early_repmt_rsn
		, BankruptCompleted
		, NeedToStartLegalProcess 
		--DWH-1691
		, RPC_text_d --Количество контактов с клиентом из категории 'Текстовые сообщения' за день.
		, RPC_other_d --Количество контактов с клиентом из категории 'Иные воздействия' за день.
		, RPC_text_w --Количество контактов с клиентом из категории 'Текстовые сообщения' за неделю.
		, RPC_other_w --Количество контактов с клиентом из категории 'Иные воздействия' за неделю.
		, RPC_text_m --Количество контактов с клиентом из категории 'Текстовые сообщения' за месяц.
		, RPC_other_m --Количество контактов с клиентом из категории 'Иные воздействия' за месяц
		-- При возникновении просрочки, счётчик должен обнуляться.
		, Region_fact -- Регион фактического проживания
		, customer_status --Статус клиента (Банкрот, смерть, FRAUD, отказ от взаимодействия 230-ФЗ и тд)
		, next_payment_amount --Начисленная задолженность на дату \ нарастающим итогом (вкл. штрафы)
		, customer_acceptance_to_3rd_party_communicaton --1/0 От клиента получено(1)  согласие на взаимодействие с 3ми лицами
		, customer_rejection_of_further_interactions --отказ клиента от дальнейших взамодействий
		, IVR_status_date --дата воздействия IVR
		, IVR_status --факт доставки воздействия . варианты 1\0. 1 - прослушано до контрольной точки , 0 - непрослушено
		, Rollback_fl --за последние 42 дня, по договору был откат минимум на 1 бакет
		, num_of_missed_payments --Количество пропущенных регулярных платежей по договору	 
		, SoftWare_fl	--флаг установки ПО
		, SoftWare_installed_date --дата установки по
		, SoftWare_removed_date --дата удаления ПО
		, Product_type --Наименование типа продукта
		, Product_name --Наименование продукта из справочника CMR. больший уровень детализации (напр. PTC31)
		, Active_PTP --наличие действующего обещания об оплате ( 1 - имеется \ 0 - отсутсвует)
		, customer_acceptance_to_frequent_interactions --согласия на учащенное взаимодействие
		,device_status_desc	-- статус устройства описание
		,device_status -- статус устройства 
		,device_status_date --дата статуса устройства
		,customer_acceptance_to_other_interactions --DWH-1809 согласие на иные воздействия "Согласие на иные воздействия" = Согласие на воздействие на устройство
		,Overdue_Interest --DWH-1805 Просроченные проценты (Начисленные на дату, но не уплаченные)
		,Litigation_fl--DWH-1747 признак подачи в суд
		,Start_date --DWH-1865 Дата старта договора
		,flg_Refused_to_sell_car --DWH-1863 поле "отказ от реализации авто"
		,flg_Refused_to_pay_at_PreLegal_2plus --DWH-1864 поле 2+ отказа от оплаты на стадии Prelegal
		,flg_Rollback_on_bucket_for_last_3m --DWH-1866 был осуществлен откат на бакет назад как минимум один раз за последние 3 месяца.
		,flg_Non_Contact --DWH-1867 Добавить поле в витрину стратегии Клиент не Контакт flg_Non_Contac
		,flg_Agreed_to_sell_car --DWH-1901 поле "согласие на реализацию авто"
		,flg_KK_SVO	--DWH-1923  У клиента имеются кредитные каникулы ( КК) с типом : Военные кредитные каникулы на сегодня.
		,isActive --DWH-1965 Флаг активности договора
		,endDate --DWH-1965 Дата когда договор стал не активным
		,flg_KK_SVO_ever --DWH-1997 Военные кредитные каникулы были хоть раз во время срока жизни договора
		,flg_active_Pdp --DWH-1896 признак наличия активного на дату заявления на ПДП
		,flg_Ppd_same_day --DWH-1896 признак отсутсвия ПДП день в день по клиенту
		--,ClaimInCourtDate --Дата подачи иска в суд DWH-2103
		,CustomerObligations --DWH-2094 Обязательства клиента
		,OpenTask_IP_cnt	-- DWH-2094 кол. открытых задач на стадии ИП--
		,OpenTask_Legal_cnt	-- DWH-2094 кол. открытых задач на стадии СП/Legal--		
		,last_name		--Фамилия	--DWH-2124
		,first_name		--Имя		--DWH-2124
		,patronymic		--Отчество	--DWH-2124
		,reason_for_accruals_suspension	--причина приостановки начислений DWH-2097
		,segment_code --сегмент - DWH-2150
		,segment_name --сегмент - DWH-2150
		,flg_30d_until_accrualSuspension --через 30 полных дней будет достигнут лимит 1.3х BP-3780
		
		
		,Renewal_number			--Номер пролонгации по договору ( 1-2-3-4-5 ) --DWH-2300
		,Renewal_startdate		--Дата начала текущей пролонгации --DWH-2300
		,Renewal_enddate		--Планируемая дата окончания текущей пролонгации --DWH-2300
		,date_30d_until_accrualSuspension
		,last_date_sending_sms_IL_30duntilaccrSuspension	--дата отправки коммуникации с определенным типом --DWH-2474
		,last_date_sending_mail_IL_30duntilaccrSuspension	--дата отправки коммуникации с определенным типом --DWH-2474
		,client_inn	--инн клиента DWH-2512
		,CourtClaimSendingDate -- Дата отправки иска в суд ---DWH-2561
		,autoStatusId		--ИД статуса Авто				BP-4315
		,autoStatusName		--Название статуса Авто			BP-4315
		,autoSubStatusId	--ИД под-статуса Авто			BP-4315
		,autoSubStatusName	--Название под-статуса Авто		BP-4315
		,hasBeenInKa --Договор ранее был в КА за любой период жизни договора
		,totalPaymentsAmtL90D --Сумма платежей за последние 90 дней
		,loginom_Closed_date --Дата закрытия договора логиномом
		,lastDateEmailPdl11 ---дата отправки коммуникации с определенным типом DWH-2613
		,lastDateSmsPdl03   ---дата отправки коммуникации с определенным типом DWH-2613
		,paymentPeriod		--платежный период --DWH-2625
		,total_payments		--cумма поступлений  нарастающим итогом DWH-2776 
		,hasMobileApplicationEver --было скачено мобильное приложение DWH-2852
		,max_dpd_ever --DWH-2869
		,RPC_calls_d	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за день.
		,RPC_calls_w	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за неделя.
		,RPC_calls_m	--DWH-2872 Количество контактов с клиентом из категории 'Звонки' за месяц.
		,PDN--BP-624
		,Product_SubTypeName  
		,Product_SubTypeCode  
	from #t_result
		
SELECT @row_count = @@ROWCOUNT
	 update m set m.last_pay_amount_5d=0
    from dm.Collection_StrategyDataMart m 
		where StrategyDate=@today 
		and m.last_pay_amount_5d<0
	
	 if @isDebug = 1
	 begin
		rollback tran
	end
	else
	begin
		commit tran
	end
end
/*
UNION all

select 
	StrategyDate=@today
	, fio='Тестов новых заявок'
	, external_id='20041410000199'
	, [timeZoneGMT+]                                     =null
	, dpd=0                                             
	, birth_date                                         =null
	, principal_rest                                     =null
	, overdue_amount                                     =null
	, PTPDate                                            =null
	, PTP                                                =null
	, [Num_RPC in Cur_date]                              =null
	, [Num_RPC in (Cur_date-7;Cur_date)]                 =null
	, [Num_RPC in (Cur_date-30;Cur_date)]                =null
	, agent_flag                                         =null
	, pay                                                =null
	, last_pay_date                                      =null
	, bankrupt                                           =null
	, CRMClientGUID                                      =upper('760953bf-7e90-11ea-b820-005056837805')
	, death_flag                                         =null
	, disabled_person_flag                               =null
	, hospital_flag                                      =null
	, [Num_SMS in Cur_date]                              =null
	, [Num_SMS in (Cur_date-7; Cur_date)]                =null
	, [Num_SMS in (Cur_date-30; Cur_date)]               =null
	, last_pay_amount_5d                                 =null
	, last_rpc_date                                      =null
	, last_call_att_date                                 =null
	, [num att]                                          =null
	, plan_date                                          =null
	, plan_sum                                           =null
	, [first payment]                                    =null
	, collectionStage									='Действует'
	, currentDebt                                        =null
	, UnconfirmedDeath_flag                              =null
	, Complaint_flag                                     =null
	, FailureInteraction230FZ_flag                       =null
	, FailureInteractionWith3person230FZ_flag            =null
	, FeedbackConsentDataTransfer3person230FZ            =null
	, FRAUD_flag                                         =null
	, LackConsentPDProcessing_flag                       =null
	, RejectProcessingPersonalData152FZ_flag             =null
	, RepresentativeInteraction230FZ_flag                =null
	, fraud_denyCall                                     =null
	, fail230_DenyCall                                   =null
	, complaint_DenyCall                                 =null
	, guid                                               =null
	, alco_flag                                          =null
	, maxDPDMore91_flag                                  =null
	, FPD60                                              =null
	, FPD30                                              =null
	, FPD4                                               =null
	, applicationScore                                   =null
	, overdue_398                                        =null
	, СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания=null
	, СуммаПлатежейМеждуДатойОбещанияИТекущейДатой       =null
	, first_payment_flag                                 =null
	, last_attempt_date_home_mob                         =null
	, last_attempt_date_thd                              =null
	, last_attempt_date_work                             =null
	, last_attempt_messengers                            =null
	, last_contact_thd                                   =null
	, last_contact_date_work                             =null
	, last_heared_message_date                           =null
	, cnt_calltry_last5d                                 =null
	, cnt_calltry_last3d                                 =null
	, cnt_calltry_last3d_cl                              =null
	, cnt_calltry_last3d_work                            =null
	, last_contact_messengers                            =null
	, last_contact_SKIP                                  =null
	, last_contact_meet                                  =null
	, workPhoneNotActual                                 =null
	, reject_paymet_last14days                           =null
	, ptp_last14days                                     =null
	, broked_ptp_last_14days                             =null
	, moscow_and_mo_flag                                 =null
	, EnforcementOrders_flag                             =null
	, NUM_RPC_all_7d                                     =null
	, NUM_RPC_all_14d                                    =null
	, NUM_RPC_all_30d                                    =null
	, BankruptConfirmed                                  =null
	, BankruptUnconfirmed                                =null
	, Region                                             =null
	, RegionActual                                       =null
	, FPD                                                =null
	, SPD                                                =null
	, TPD                                                =null
	, bv_flag                                            =null
	, EDOAgreement                                       =null
	, HasEngagementAgreement                             =null
	, jail_flag                                          =null
	, ams_flag                                           =null
	, ams_date                                           =null
	, kk_flag                                            =null
	, space_ka_flag                                      =null
	, FraudUnConfirmed                                   =null
	, FraudConfirmed                                     =null
	, HardFraud                                          =null
	, DenyCollectors                                     =null
	, FraudConfirmed_DenyCollectors                      =null
	, HardFraud_DenyCollectors                           =null
	, space_ka_return_flag                               =null
	, rpc91                                              =null
	, SkipEnterDate                                      =null
	, reject_paymet_last30days                           =null
	, clnt_contact_last_all                              =null
	, thd_contact_last_all                               =null
	, start_buсket_date                                  =null
	, cnt_day_fail                                       =null
	, Skip_contact_add                                   =null
	, email                                              =null
	, clnt_email_flg                                     =null
	, reject_paymet_last_date                            =null
	, startDate_1stKK                                    =null
	, endDate_1stKK                                      =null
	, povt_KK                                            =null
	, CallingCreditHolidays                              =null
	, endDate_lastKK                                     =null
	, ams_value                                          =null
	, ptp_otl_PromiseDate                               = null
	, probation											= null
	, RegionRegistration								= null  
    , RegionRegistration_code							= null
	, download_app_email_sent_date						= null 
	, HasFreezing										= 0 
	, change_date_plan_date								= null
	, old_plan_date										= null
	, end_date_payment_schedule							= null
	, StartFreezing									= null 
	, EndFreezing										= null 
	, reject_payment_dpd_1_88_count					= null
	, date_of_Selling								= null
	, totalPaymentAfterFreezing						= null
	, clnt_FICO_score								= null
	, IsInstallment									= 0
	, max_dpd_last_90d								= 0 
	, full_early_repmt_rsn							= null
	, BankruptCompleted								= 0
	, NeedToStartLegalProcess						= 0
	, RPC_calls_d									= NULL
	, RPC_text_d									= NULL
	, RPC_other_d									= NULL
	, RPC_calls_w									= NULL
	, RPC_text_w									= NULL
	, RPC_other_w									= NULL
	, RPC_calls_m									= NULL
	, RPC_text_m									= NULL
	, RPC_other_m									= NULL
	, Region_fact									= NULL
	, customer_status								= NULL
	, next_payment_amount							= NULL
	, customer_acceptance_to_3rd_party_communicaton = 0 
	, customer_rejection_of_further_interactions	= 0
	, IVR_status_date								= NULL
	, IVR_status									= NULL
	, Rollback_fl									= NULL
	, num_of_missed_payments						= NULL
	, SoftWare_fl									= 0
	, SoftWare_installed_date						= null
	, SoftWare_removed_date							= null
	, Product_type									= NULL
	, Product_name									= NULL
	, Active_PTP									= 0
	, customer_acceptance_to_frequent_interactions	= 0 
	, device_status_desc							= null
	, device_status									= null
	, device_status_date							= null
	, customer_acceptance_to_other_interactions		= 0
	, Overdue_Interest								= 0
	, Litigation_fl									= 0
	, Start_date									= NULL
	, flg_Refused_to_sell_car						= 0
	, flg_Refused_to_pay_at_PreLegal_2plus			= 0
	, flg_Rollback_on_bucket_for_last_3m			= 0
	, flg_Non_Contact								= 0
	, flg_Agreed_to_sell_car						= 0
	, flg_KK_SVO									= 0
	, isActive										= 0
	, endDate										= NULL
	, flg_KK_SVO_ever								= 0
	, flg_active_Pdp								= 0 
	, flg_Ppd_same_day								= 0 
	--, ClaimInCourtDate								= null
	, CustomerObligations							= null
	, OpenTask_IP_cnt								= null
	, OpenTask_Legal_cnt							= null
	, last_name										= 'Тестов'  
	, first_name									= 'новых'
	, patronymic									= 'заявок'	
	, reason_for_accruals_suspension				= null
	, segment_code									= null
	, segment_name									= null
	, flg_30d_until_accrualSuspension				= 0
	, date_30d_until_accrualSuspension				= null 
	, Renewal_number								= 0
	, Renewal_startdate								= null
	, Renewal_enddate								= null
	, last_date_sending_sms_IL_30duntilaccrSuspension	= null
	, last_date_sending_mail_IL_30duntilaccrSuspension	= null
	, client_inn										= null
	, CourtClaimSendingDate							= null
	,  autoStatusId									= null
	,  autoStatusName								= null
	,  autoSubStatusId								= null
	,  autoSubStatusName							= null
	,  hasBeenInKa									= 0 
	,  totalPaymentsAmtL90D						= 0 
	,  loginom_Closed_date						= null
*/

IF @isLogger = 1 BEGIN
	SELECT @message = concat('INSERT dm.Collection_StrategyDataMart', ', ', convert(varchar(10), @row_count), ', ', convert(varchar(10), datediff(SECOND, @StartDate, getdate())))
	EXEC LogDb.dbo.LogAndSendMailToAdmin @eventName = @eventName, @eventType = @eventType, @message = @message, @SendEmail = @SendEmail, @ProcessGUID = @ProcessGUID
	SELECT @StartDate = getdate(), @row_count = 0
END


	/*
    declare @rowCount nvarchar(32)
    set @rowCount=cast((select count(*)  from dm.Collection_StrategyDataMart where StrategyDate=@today
    ) as nvarchar(32))
	*/
    
   

    --exec logdb.dbo.[LogDialerEvent] 'CreateAgreementListByStrategy_dataMart_CMR','Finished',@rowcount,'Success','' 
    --exec logdb.dbo.[LogAndSendMailToAdmin] 'CreateAgreementListByStrategy_dataMart_CMR','Info','procedure finished',@rowcount

   
end try
begin catch
	if @@Trancount>0
		rollback tran
	;throw
end catch
 end

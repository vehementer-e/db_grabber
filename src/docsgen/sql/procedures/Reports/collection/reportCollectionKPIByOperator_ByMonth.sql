
--exec [collection].[reportCollectionKPIByOperator_ByMonth] 2025,06

CREATE     PROC [collection].[reportCollectionKPIByOperator_ByMonth]
	@year int 
  ,@month int
as
begin 
begin try
/*  
declare 
  @year int=2021
  ,@month int=12
 */

set nocount on
declare @dt_startMonth date = datefromparts(@year,@month, 1)

declare @dt_endMonth date = eomonth(@dt_startMonth)
declare @max_PtpDate date = @dt_endMonth
/*Собрали коммуникации у которы есть дата обещания*/
   drop table if exists #callresults
   select 
		aa.CommunicationDateTime dt
		, employee  = case 
			when aa.Manager ='Викторовна Чупахина Ольга' then 'Чупахина Ольга Викторовна'  
			when aa.Manager='Зайцева Фаина  Николаевна' then 'Зайцева Фаина Николаевна'
		  else aa.Manager 
		  end 
		, ptpDate = cast(aa.PromiseDate as date)
		, ptpSum = try_cast(isnull(aa.PromiseSum,0) as money) 
		, ContactSuccess = aa.Контакт 
		, external_id = aa.Number 
		-- 2021_02_03 исправление ошибки контакта в мастер системе
		, FIO = isnull(aa.fio, aa.Fio_new) 
		, bucketDate  = aa.CommunicationDate 
      --, convert(varchar,aa.CommunicationDate,104) [Дата портфеля] 
		--, aa.CommunicationDate [Дата портфеля(date)]
		, communicationType = aa.CommunicationType 
		, interactionResult = aa.CommunicationResult 
		, aa.PersonType
		into #callresults
	from
	(
	  select  com.*, 
		
		Fio_new = concat_ws(' ', LastName, Name, MiddleName)
		,  rn = ROW_NUMBER() over(partition by Number, CommunicationDate, PhoneNumber, Manager order by com.updateDate desc)  
  
	  from stg._Collection.mv_Communications com
	  left join [Stg].[_Collection].[Customers]  cust on com.CustomerId = cust.id

	  where cast(CommunicationDateTime as date) between @dt_startMonth and @dt_endMonth
	  --CommunicationDateTime >= '2020-02-27T00:00:00' and  CommunicationDateTime <'2020-02-28T00:00:00'
	   and Manager is not null
	   and not (CommunicationResult ='Оплачено' and Manager ='Система')
	   and Контакт='Да'
	  and PromiseDate is not null
	  --and Manager like 'Чупахина%'
	  ) aa
	  where  aa.rn = 1 --т.к в таблице есть дубликаты
	 create clustered index ix on #callresults(external_id, bucketDate)
	  /*дата крайнего обещания, т.к. дальше нужно оренитроваться на него*/
	 set @max_PtpDate = isnull((select max(ptpDate) from #callresults), @dt_endMonth)
	if @max_PtpDate<=cast(getdate() as date)
	begin
		set @max_PtpDate = @dt_endMonth
	end
	drop table if exists #deals


	select 
		external_id = d.КодДоговораЗайма
		,ссылка = d.СсылкаДоговораЗайма
		,[Тип Продукта] = d.ТипПродукта_Наименование
			--case d.ТипПродукта when 
			-- 'ПТС' then 'ПТС'
			-- else d.ТипПродукта
			-- end
		,d.IsInstallment
		-- @changelog | Shubkin A.A. | 26.11.25 Добавил [ТипПродукта_Code] и 	ТипПродукта_Наименование
		, d.ТипПродукта_Code
		,ContractStartDate = cast(d.ДатаДоговораЗайма as date)
	into #deals
	from dwh2.hub.ДоговорЗайма d
	where exists(select top(1) 1 from 	  #CallResults cr where  d.КодДоговораЗайма=cr.external_id  )
	create clustered index cix on #deals(external_id)
 
     /*
	 Стадии по договору, вопрос только почему из v_ClientContractStage_simple а не из другой таблицы
	 */    
	 drop table if exists #rs
	
	--DWH-2442
/*
стация по договору, на дату коммункации
*/
	select de.external_id
       , dt = ccs.created
       , ccs.CMRContractStage CollectionStage 
	  into #rs
	  from Stg._loginom.v_ClientContractStage_simple AS ccs
	  ---left join dwh_new.staging.CRMClient_references r on r.CMRContractGUID=ccs.CMRContractGUID
	  join #deals de on de.external_id= ccs.CMRContractNumber  ---   r.CMRContractNumber
	 where ccs.ishistory=0 
		and ccs.created between @dt_startMonth and @dt_endMonth /*подумать над оптимизацией*/
	 create clustered index cix on #rs(external_id)

 
--
--  max_dpd
--

  drop table if exists #CMR_MAXDPD
  
  /*найдем maxDPD
  А нужен ли он всегда MAX?*/
	--var 2
	--DWH-2516
	select 
		 B.external_id
		, max(B.dpd_begin_day) AS max_dpd
	INTO #CMR_MAXDPD
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
		INNER JOIN #deals AS de 
			ON b.external_id = de.external_id
	WHERE B.d <= @dt_endMonth
	GROUP BY B.external_id
	create clustered index cix on #CMR_MAXDPD(external_id)

  	/*собрали договора по которым были платежи их их дату и сумму*/
	drop table if exists #t_paymentInfo
	SELECT	f.external_id
		,ДатаПоследнегоПлатежа = f.d
		,f.[сумма поступлений]
		
		into #t_paymentInfo
		FROM dwh2.dbo.dm_CMRStatBalance AS F (NOLOCK)
		WHERE 1=1
			AND F.[сумма поступлений] <> 0
			and exists(Select top(1) 1 from #deals d where d.external_id = f.external_id)
			and f.d<@max_PtpDate
	create index ix	 on #t_paymentInfo(external_id, ДатаПоследнегоПлатежа) include([сумма поступлений])
	
  
--
-- Аналитические показатели
--
  drop table if exists #ap


	--DWH-2516
	--var 2
	select 
		dt=B.d
	    , d=B.d
		, dpdDate = iif(isnull(B.dpd,0) = 0
			, '2001-01-01'
			, dateadd(DAY, -B.dpd, B.d))
       , dpd = isnull(B.dpd, 0)
       , bucket    = case 
					when isnull(B.dpd,0) = 0 then '(0)'
					else  buketName_end_Day.bucketName end
        , bucketNo = isnull(buketName_end_Day.bucketNo,0)
		, dpdDateMFO = 
			iif(isnull(B.dpdMFO,0) = 0, '2001-01-01'
				, dateadd(DAY, -B.dpdMFO, B.d))
       , dpdMFO=isnull(B.dpdMFO, 0)
       , overdue_amount=B.overdue
       , LastPaymentDate = isnull(last_paymentInfo_EndDay.ДатаПоследнегоПлатежа, '2001-01-01')
       , LastPaymentSum = isnull(last_paymentInfo_EndDay.[сумма поступлений], 0)
       , external_id=de.external_id
       , max_dpd=max_dpd.max_dpd
		
		--DWH-2516. на начало дня
		, dpdDate_begin_day = iif(isnull(B.dpd_begin_day,0) = 0
			, '2001-01-01', dateadd(DAY, -B.dpd_begin_day, B.d))
       , dpd_begin_day = isnull(B.dpd_begin_day, 0)
       , bucket_begin_day    = case
					when isnull(B.dpd_begin_day,0) = 0 then '(0)'
					else  buketName_begin_day.bucketName end
        , bucketNo_begin_day = isnull(buketName_begin_day.bucketNo,0)

		, dpdDateMFO_begin_day = iif(isnull(B.dpdMFO_begin_day,0) = 0, '2001-01-01'
			, dateadd(DAY, -B.dpdMFO_begin_day, B.d))
		, dpdMFO_begin_day = isnull(B.dpdMFO_begin_day, 0)

       , overdue_amount_begin_day = B.overdue_begin_day
       , LastPaymentDate_begin_day = isnull(last_paymentInfo_BeginDay.ДатаПоследнегоПлатежа, '2001-01-01')
       , LastPaymentSum_begin_day = isnull(last_paymentInfo_BeginDay.[сумма поступлений], 0)
	   , total_rest = b.[Расчетный остаток всего] -- полная сумма задолжности
       , principal_rest = b.[остаток од]
	into #ap
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
		INNER JOIN #deals AS de on de.external_id = b.external_id

		LEFT join #CMR_MAXDPD max_dpd on max_dpd.external_id=de.external_id
		left join dwh2.[dbo].[tvf_GetBucketName](null) buketName_end_Day
			on  b.dpd  between buketName_end_Day.dpdMin and buketName_end_Day.dpdMax
		left join dwh2.[dbo].[tvf_GetBucketName](null) buketName_begin_day
			on B.dpd_begin_day between buketName_begin_day.dpdMin and buketName_begin_day.dpdMax
		
		--на конец дня
		OUTER APPLY (select 
			s.*
		from (
			select 
			[pi].*
			,nRow= ROW_NUMBER() over(PARTITION by [pi].external_id order by [pi].ДатаПоследнегоПлатежа desc)
			from #t_paymentInfo [pi]
			where  [pi].external_id = B.external_id
			and [pi].ДатаПоследнегоПлатежа <= b.d  -- ! строго меньше или равно !
			) s
			where s.nRow = 1
		) last_paymentInfo_EndDay
		--на начало дня
		OUTER APPLY (select 
		s.*
		from (select 
				[pi].*
				,nRow= ROW_NUMBER() over(PARTITION by [pi].external_id order by [pi].ДатаПоследнегоПлатежа desc)
				from #t_paymentInfo [pi]
				where  [pi].external_id = B.external_id
				and [pi].ДатаПоследнегоПлатежа < B.d -- ! строго меньше !
			) s
			where s.nRow = 1
		) last_paymentInfo_BeginDay
		

	where B.d between dateadd(day,-1,@dt_startMonth)   --для перехлеста, нужно ниже
	
	and @max_PtpDate /*считаем до даты последнего ptp*/

	create clustered index cix on #ap(external_id, d)

	drop table if exists #payments
 
	SELECT de.external_id
		, dateadd(year,-2000,cast(g.Дата as date)) dt
		, sum(g.Сумма) summ
		, sum(g.СуммаОплатыДопПродуктов) as [Сумма за доп продукты из платежа]
		, IIF (sum(g.СуммаОплатыДопПродуктов) = 2000 or sum(g.СуммаОплатыДопПродуктов) = 7000, 2000, NULL) as [Платеж за СМС информирование]
		, IIF (sum(g.СуммаОплатыДопПродуктов) = 5000 or sum(g.СуммаОплатыДопПродуктов) = 7000, 5000, NULL) as [Платеж за досрочное снятие с залога]
	into #payments
	from Stg._1cCMR.[документ_платеж] g
	join #deals de on de.ссылка= g.Договор
	where cast(g.Дата as date) between 
	dateadd(year,2000,@dt_startMonth) and dateadd(year,2000,@max_PtpDate)  /*считаем до даты последнего ptp*/
	group by de.external_id,dateadd(year,-2000,cast(g.Дата as date))


--
-- сотрудники  и обещания
--

drop table if exists #res
	;with cte as (	
	--var 2 --DWH-2516
     select a.dt --дата время коммуникации
          , a.employee --сотрудника
          , a.ptpDate --дата обещания
          , a.ptpSum --сумма обещания
          , a.ContactSuccess --контакт всегда да
          , a.external_id --номер договора
          , a.FIO --фио клиента
          , a.bucketDate  --дата время коммуникации ???
          
          , a.communicationType --тип коммуникации
          ,	a.interactionResult --результат коммуникации
		  --показатели на дату коммуникации
          , ap.dpdDate -- дата возниковения просрочки на конец дня
		  , dpdDate_at_begin_of_day		= ap.dpdDate_begin_day--дата возниковения просрочки на начало дня			
          , ap.dpd											--dpd на конеец дня
		  , dpd_at_begin_of_day			= ap.dpd_begin_day	--dpd на начало дня 							
          , ap.dpdDateMFO	--
		  , dpdDateMFO_at_begin_of_day	= ap.dpdDateMFO_begin_day						
          , ap.dpdMFO
		  , dpdMFO_at_begin_of_day		= ap.dpdMFO_begin_day							
          , ap.overdue_amount				--Сумма для полного погашения задолженности 
		  , overdue_amount_at_begin_of_day = ap.overdue_amount_begin_day--переплата/задолжности на начало дня		 
          , ap.LastPaymentDate --дата последнего платаже
    	  , LastPaymentDate_at_begin_of_day = ap.LastPaymentDate_begin_day--дата последнего платаже на начало дня
          , ap.LastPaymentSum --сумма последнего платаже
		  , LastPaymentSum_at_begin_of_day = ap.LastPaymentSum_begin_day--сумма последнего платаже на начало дня
-- на дату обещания
  
		  , ptpDate_overdue_end_of_day                = ap_ptp.overdue_amount --на дату когда dpd =0 или дату ptp
          , callDate_bucket_begin_of_day              = isnull(ap.bucket_begin_day  ,'(0)')
          , callDate_bucket_end_of_day                = isnull(ap.bucket          ,'(0)')
          , ptpDate_bucket_at_end_of_day              = isnull(ap_ptp.bucket      ,'(0)')
          , callDate_bucketNo_begin_of_day            = isnull(ap.bucketNo_begin_day      ,0)
          , callDate_bucketNo_end_of_day              = isnull(ap.bucketNo       ,0)
          , ptpDate_bucketNo_at_end_of_day            = isnull(ap_ptp.bucketNo   ,0)
			
		  , ap.max_dpd	--максимальный dpd
          , rs.CollectionStage --стадия
		  , a.PersonType -- тип кондата
		  , d.ContractStartDate
		  , d.IsInstallment -- инстолмен?
		  , d.[Тип Продукта] 
		  -- @changelog | Shubkin A.A. | 26.11.25 Добавил [ТипПродукта_Code] и 	ТипПродукта_Наименование
		  , d.[ТипПродукта_Code]
		  , ap.total_rest -- полная сумма задолжности
          , ap.principal_rest 
		  , bestBucket_Day = best_bucket.bucketDay --дата когда перешли в лучший бакет
		  , bestBucket_No  = best_bucket.bucketNo   --номер лучшего бакета
		  , bestBucket	   = best_bucket.bucket	--лучший бакет
       from #CallResults a  
	   inner join #deals  d on d.external_id = a.external_id
       /*состояние баланса на дату коммуникации*/
	   left join #ap ap on ap.external_id=a.external_id 
			and ap.d=a.bucketDate /*на дату коммуникации*/
	   /*стадия на дату коммуникации*/
       left join #rs rs on rs.external_id=a.external_id and rs.dt=a.bucketDate 
		/*получиили дату когда по договору была dpd =0 при условии что был 0 между датой коммуникации и датей обещания*/
		outer apply (
					select
						G.external_id,
						d = min(G.d)
					from #ap AS G
					where G.external_id = a.external_id
						and G.d between a.bucketDate and a.ptpDate
						and G.dpd = 0
					group by G.external_id
				) AS t
		/*состояние баланса на дату когда dpd =0, если небыл то на ptpDate*/
		LEFT JOIN #ap AS ap_ptp
			ON ap_ptp.external_id=a.external_id 
			AND ap_ptp.d = isnull(t.d, a.ptpDate)
		/*получиили дату когда по договору в лучший бакет по сравнению с тем что был на момент даты взятия обещания*/
		outer apply 
		(
			select distinct --иначе дубли
				external_id
				,bucketNo = min(min_bucket.bucketNo) over(partition by external_id)
				,bucketDay = FIRST_VALUE(min_bucket.d) over(partition by external_id order by min_bucket.bucketNo)
				,bucket = FIRST_VALUE(min_bucket.bucket) over(partition by external_id order by min_bucket.bucketNo)
			from #ap min_bucket
			where min_bucket.external_id = a.external_id 
			and min_bucket.d between a.bucketDate and a.ptpDate
			and (min_bucket.bucketNo<ap.bucketNo_begin_day --бакет меньше бакета на дату взятия обещания1
				or (min_bucket.bucketNo = 0 and ap.bucketNo_begin_day = 0 ) --либо оба 0
				)
			--
			--group by external_id
			
		) best_bucket
		)

		select distinct 
		  Сотрудник=  t.employee
         ,Бакет = callDate_bucket_begin_of_day
		, CollectionStage=isnull(CollectionStage ,'-')
        , overdue_amount_end_of_day= isnull(t.overdue_amount,0)    --Сумма для полного погашения задолженности
        , dt = cast(dt as date) 
        , t.FIO
        , t.ptpDate
        , t.ptpSum
        , t.external_id
        , t.dpdDate
        , t.dpdDate_at_begin_of_day
        , t.dpd
        , t.dpd_at_begin_of_day
        , t.dpdDateMFO
        , t.dpdDateMFO_at_begin_of_day
        , t.dpdMFO
        , t.dpdMFO_at_begin_of_day
        , t.overdue_amount overdue_amount_at_end_of_day
        , t.overdue_amount_at_begin_of_day
        , t.LastPaymentDate
        , t.LastPaymentDate_at_begin_of_day
        , t.LastPaymentSum
        , t.LastPaymentSum_at_begin_of_day
		, t.PersonType
		, [Исходный бакет]		= callDate_bucket_begin_of_day
        , [Конечный бакет]		= ptpDate_bucket_at_end_of_day
		, [Исходный бакет номер]= callDate_bucketNo_begin_of_day
        , [Конечный бакет номер]= ptpDate_bucketNo_at_end_of_day
		, ptpDate_overdue_end_of_day
		, CommunicationType
		, CommunicationDateTime =dt
		, ContractStartDate
		, t.IsInstallment
		-- @changelog | Shubkin A.A. | 26.11.25 Добавил [ТипПродукта_Code] и 	ТипПродукта_Наименование
		, t.[Тип Продукта]
		, t.ТипПродукта_Code
		, total_rest
		, principal_rest
		, bestBucket_Day 
		, bestBucket_No  
		, bestBucket
		into #res
		from cte t
	
--select * from #res order by dt


 drop table if exists #report
;
with result as (
  select дата							= r.dt
       , Сотрудник						= r.Сотрудник
       , Бакет							= isnull(r.Бакет,'-')
       , Стадия							= r.CollectionStage
       , Клиент							= r.Fio
       , НомерДоговора					= r.external_id
       , ДатаОбещания					= r.ptpDate
       , СуммаОбещания					= r.ptpSum
	   , ДнейПросрочкиНаНачалоДня		= r.dpd_at_begin_of_day
       , ДнейПросрочкиНаКонецДня		= r.dpd
       , ДатаВозникновенияПросрочкиНаНачалоДня = case when r.dpdDate_at_begin_of_day>'20010101' then dpdDate_at_begin_of_day else null end
       , ДатаВозникновенияПросрочкиНаКонецДня = case when r.dpdDate>'20010101' then r.dpdDate else null end
       , ДнейПросрочкиНаНачалоДняМФО     = dpdMFO_at_begin_of_day
       , ДнейПросрочкиНаКонецДняМФО      = r.dpdMFO
       , ДатаВозникновенияПросрочкиНаНачалоДняМФО	= case when r.dpdDateMFO_at_begin_of_day>'20010101' then dpdDateMFO_at_begin_of_day else null end
       , ДатаВозникновенияПросрочкиНаКонецДняМФО	= case when r.dpdDateMFO>'20010101' then r.dpdDateMFO else null end
       , ПросроченнаяЗадолжностьНаНачалоДня			= overdue_amount_at_begin_of_day
	   , ПросроченнаяЗадолжностьНаКонецДня			= overdue_amount_at_end_of_day
	   , ДатаПоследнегоПлатежаНаНачалоДня			= case when r.LastPaymentDate_at_begin_of_day>'20010101' then LastPaymentDate_at_begin_of_day else null end 
       , ДатаПоследнегоПлатежаНаКонецДня			= case when r.LastPaymentDate>'20010101' then r.LastPaymentDate else null end 
       , СуммаПоследнегоПлатежаНаНачалоДня			= LastPaymentSum_at_begin_of_day
	   , СуммаПоследнегоПлатежаНаКонецДня			= r.LastPaymentSum
       , ОбщаяЗадолностьНаКонецДняСегодня			= r.total_rest
	   , ОбщаяЗадолностьНаКонецДняВчера				= b1.total_rest
       , ЗадолжностьОсновнойДолгСегодня				= r.principal_rest
	   , ЗадолжностьОсновнойДолгВчера				= b1.principal_rest
       , СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания = payments.СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания
	   , [Платеж за СМС информирование]				= t_Addpayments.[Платеж за СМС информирование]
	   , [Платеж за досрочное снятие с залога]		= t_Addpayments.[Платеж за досрочное снятие с залога]
       , ptpDateBalance								= r.ptpDate_overdue_end_of_day --try_cast(isnull(b.overdue,0) as float)
	   , r.PersonType
	   , r.[Исходный бакет]
	   , r.[Конечный бакет]
	   , r.[Исходный бакет номер]
	   , r.[Конечный бакет номер]
	  
     , r.CommunicationType
     , r.CommunicationDateTime
	 , r.ContractStartDate
	 , r.IsInstallment
	 -- @changelog | Shubkin A.A. | 26.11.25 Добавил [ТипПродукта_Code] и 	ТипПродукта_Наименование
	 , r.[Тип Продукта]
	 , r.ТипПродукта_Code
	 , [День лучшего бакета]= bestBucket_Day 
	 , [№Лучший бакет ]		= bestBucket_No  
	 , [Лучший бакет]		= bestBucket
    from #res r
    left join #ap p on r.external_id=p.external_id and p.d=r.dt
    left join #payments pay on pay.external_id=r.external_id and pay.dt=r.dt
    outer apply
	(
		select external_id
			,СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания = sum(summ)
		from #payments t
		where external_id=  r.external_id
			and t.dt between r.dt and r.ptpDate
		group by t.external_id
	) payments 
	left join 
	(
		select  external_id
		,[Платеж за СМС информирование] = sum([Платеж за СМС информирование])
		,[Платеж за досрочное снятие с залога] = sum([Платеж за досрочное снятие с залога])
		from #payments t
		group by external_id
	) t_Addpayments on t_Addpayments.external_id = r.external_id

	left join #ap b1 on b1.external_id=r.external_id and b1.d=dateadd(day,-1,try_cast(r.dt as date))
  ), ptp as (
  select r.*
	     , success_PTP= case when ДатаОбещания is not null 
                            and isnull(СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания,0)>=СуммаОбещания--*0.95 
                            and ptpDateBalance<=0---isnull(СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания,0)<=0 
                            then 1 else 0 
                            end

       , succes_partial_ptp= case when ДатаОбещания is not null 
			and  isnull(СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания,0)>=СуммаОбещания*0.95 
                                   and ptpDateBalance>0 
                                  then 1 
								  else 0 
							  end
     , success_PTP_new= case when ДатаОбещания is not null 
                            and isnull(СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания,0)>=СуммаОбещания--*0.95 
                            then 1 else 0 
                            end
	 , succes_partial_ptp_new = case when ДатаОбещания is not null 
		and  isnull(СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания,0)>=СуммаОбещания*0.95 
                                  then 1 
								  else 0 
							  end

   
   from result r
   )

   select p.* 
        ,ptpSum_if_success_PTP_new          = case when success_PTP_new=1 then СуммаОбещания else 0.0 end
        ,ptpSum_if_succes_partial_ptp_new   = case when  succes_partial_ptp_new=1 then СуммаОбещания else 0.0 end
		,[ДатаВыполненияОбещания] = t.dt
		
   into #report 
   from ptp p
   outer apply (select dt = min(dt)
   from (
		select dt, external_id, sum(summ) over(partition by external_id 
		order by dt rows between unbounded preceding and current row) TotalSumPaymentOnDay
		from #payments pay
		where cast(dt as date) between cast(p.дата as  date) and cast(ДатаОбещания as date)
		and pay.external_id = p.НомерДоговора
		and p. success_PTP_new=1
   ) t where 1=1
	and TotalSumPaymentOnDay>= СуммаОбещания
	
   ) t
	
   -- посчитаем сохраненый баланс, если сумма платежа больше или равна сумме обещания
	 -- новая методика расчета 
	 -- если есть переход в лучший бакет (или остался в текущем) и есть оплата, то считаем сумму по остатку ОД на дату обещания (посчитается в будующем периоде)

	  -- 01/04/2020 учтем новый бакет Predel

	 ------  -- 13.04.2020 если договор закрыт на дату обещания, то должны смотреть сохраненный баланс на дату перехода в другой бакет

	 ------  -- если договор на дату совещания не существует, то смотрим последный существующий баланс , в случае наличия перехода на даты выполенния обещания в другую дату
	   
	 ------  -- делаем добавочную связку в виде таблицы
	 ------  -- 1. номер договора
	 ------  -- 2. Дата обещания (когда должен выоплнить)
	 ------  -- 3. Дата взятия обещания ( от какой даты смотрим)
	 ------  -- 4. Дата погашения обещания (найдем все договора, которые погашены в месяце)
	 ------  -- 5. Даота перехода в новый бакет (не нужно, так как погасили)
	 ------  -- Алгоритм. 1 ищем все погашенные договора в месяце
	 ------  --           2 для них находим ОД на дату перехода из бакета в бакет с понижением ( на начало дня!!!!)
		--------          3 так как может совпасть с датой погашения, то должны найти ОД на вчерашний день или на начало дня
		-------- упрощаем задачу. Находим дату перехода в новый бакет
		-------------------------------------------------------------------------------------
		-- обратная задача. для всех у кого есть переход в новый бакет и ищем дату перехода
		-- для даты перехода находим ОД на день и на предыдущий день
		-- переход должен быть между датами обещания и датой взятия обещания
		-- ==> надо найти все переходы из бакета в бакет
---таблица для инстл и птс

		/*  24/07/2025
			для расчета сохраненного баланаса необходимо проверить
			1. что обещание выполнено success_PTP_new = 1
			2. Важно был переход в баке ниже  bestBucket_No<[Исходный бакет номер]
			3.
		*/
	 -- 13.04.2020 добавим дату 
	 drop table if exists #tУчетСохраненогоБаланса
	;with УчетСохраненогоБаланса as (	 	 
		Select r.НомерДоговора
		, ПризнакУчетаСохраненогоБаланса = iif(((r.[Исходный бакет номер]>r.[№Лучший бакет ]) 
												 or (r.[Исходный бакет номер] =0 and r.[№Лучший бакет ]=0)
												 )
												 and r.success_PTP_new=1  ,1,0) 
	  , [Сумма сохраненного баланса] =(case
											when ((r.[Исходный бакет номер]>r.[№Лучший бакет ]) 
												 or (r.[Исходный бакет номер] =0 and r.[№Лучший бакет ]=0)) 
												 and r.success_PTP_new=1      
												
												then iif(b_best.[остаток од] > 0, b_best.[остаток од] 
													/*
														если остаток ОД=0 договора закрылся
														хотя верно смотреть на дату закрытия договора, а не остаток ОД
														, то надо брать данные на вчера
													*/
													,b_before.[остаток од]
													)
											
												else 0 
											end)
	  ,r.ДатаОбещания
	  from  #report	r
	  left join dwh2.dbo.dm_CMRStatBalance AS b_best
		  on  r.НомерДоговора=b_best.external_id  and b_best.d = r.[День лучшего бакета]
	  left join dwh2.dbo.dm_CMRStatBalance b_before
		 on r.НомерДоговора=b_before.external_id and b_before.d = dateadd(dd,-1,[День лучшего бакета])
	  where r.ДатаОбещания is not null --and b.Период = '2020-03-04'
	)
	select 
		*
	into #tУчетСохраненогоБаланса
	from УчетСохраненогоБаланса
	where ПризнакУчетаСохраненогоБаланса in(1)
	create clustered index ix on #report (НомерДоговора,ДатаОбещания) 

delete from [collection].dm_CollectionKPIByMonth
	where дата between @dt_startMonth and @dt_endMonth

/*
alter table dbo.dm_CollectionKPIByMonth
	add  IsInstallment  binary
	*/
insert into [collection].dm_CollectionKPIByMonth
(
[Year], [Month], [дата], [Сотрудник], [Бакет], [Стадия], [Клиент], [НомерДоговора], [ДатаОбещания], [СуммаОбещания], [ДнейПросрочкиНаНачалоДня], [ДнейПросрочкиНаКонецДня], [ДатаВозникновенияПросрочкиНаНачалоДня], [ДатаВозникновенияПросрочкиНаКонецДня], 
[ДнейПросрочкиНаНачалоДняМФО], [ДнейПросрочкиНаКонецДняМФО], [ДатаВозникновенияПросрочкиНаНачалоДняМФО], [ДатаВозникновенияПросрочкиНаКонецДняМФО], [ПросроченнаяЗадолжностьНаНачалоДня], [ПросроченнаяЗадолжностьНаКонецДня], 
[ДатаПоследнегоПлатежаНаНачалоДня], [ДатаПоследнегоПлатежаНаКонецДня], [СуммаПоследнегоПлатежаНаНачалоДня], [СуммаПоследнегоПлатежаНаКонецДня], [ОбщаяЗадолностьНаКонецДняСегодня], [ОбщаяЗадолностьНаКонецДняВчера], [ЗадолжностьОсновнойДолгСегодня], [ЗадолжностьОсновнойДолгВчера], 
[СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания], [ptpDateBalance], [PersonType], [Исходный бакет], [Конечный бакет], [Сумма сохраненного баланса], [success_PTP], [success_PTP_new], [succes_partial_ptp],[Платеж за СМС информирование]  ,
[Платеж за досрочное снятие с залога] , [created], [succes_partial_ptp_new], [CommunicationType], [CommunicationDatetime], [ptpSum_if_success_PTP_new], [ptpSum_if_succes_partial_ptp_new], [ptp] , ContractStartDate, [Дата выполнения обещания], IsInstallment
,[Тип Продукта], ТипПродукта_Code--добавил тип продукта
)
 select distinct 
	   year(r.дата)
	  ,MONTH(r.дата)
      ,r.дата
	  ,r.[Сотрудник]
      ,r.[Бакет]
      ,r.[Стадия]
      ,r.[Клиент]
      ,r.[НомерДоговора]
      ,r.[ДатаОбещания]
      ,r.[СуммаОбещания]
      ,r.[ДнейПросрочкиНаНачалоДня]
      ,r.[ДнейПросрочкиНаКонецДня]
      ,r.[ДатаВозникновенияПросрочкиНаНачалоДня]
      ,r.[ДатаВозникновенияПросрочкиНаКонецДня]
      ,r.[ДнейПросрочкиНаНачалоДняМФО]
      ,r.[ДнейПросрочкиНаКонецДняМФО]
      ,r.[ДатаВозникновенияПросрочкиНаНачалоДняМФО]
      ,r.[ДатаВозникновенияПросрочкиНаКонецДняМФО]
      ,r.[ПросроченнаяЗадолжностьНаНачалоДня]
      ,r.[ПросроченнаяЗадолжностьНаКонецДня]
      ,r.[ДатаПоследнегоПлатежаНаНачалоДня]
      ,r.[ДатаПоследнегоПлатежаНаКонецДня]
      ,r.[СуммаПоследнегоПлатежаНаНачалоДня]
      ,r.[СуммаПоследнегоПлатежаНаКонецДня]
      ,r.[ОбщаяЗадолностьНаКонецДняСегодня]
      ,r.[ОбщаяЗадолностьНаКонецДняВчера]
      ,r.[ЗадолжностьОсновнойДолгСегодня]
      ,r.[ЗадолжностьОсновнойДолгВчера]
      ,r.[СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания]
	  ,r.[ptpDateBalance]
      ,r.[PersonType]
      ,r.[Исходный бакет]
      ,r.[Конечный бакет]
	  ,[Сумма сохраненного баланса] = isnull(УчетСохраненогоБаланса.[Сумма сохраненного баланса],0) --=case when success_ptp=1        then ЗадолжностьОсновнойДолгВчера else 0 end
      ,r.[success_PTP]
	  ,r.[success_PTP_new]
      ,r.[succes_partial_ptp] 
	  ,r.[Платеж за СМС информирование]
	  ,r.[Платеж за досрочное снятие с залога]
	   ,created=getdate()
      ,iif([success_PTP_new] = 1,0,[succes_partial_ptp_new] ) as [succes_partial_ptp_new] 
      ,CommunicationType
      ,CommunicationDateTime
      ,ptpSum_if_success_PTP_new       
      ,ptpSum_if_succes_partial_ptp_new
      ,ptp =1
	  ,ContractStartDate
	  ,[ДатаВыполненияОбещания]
	  ,r.IsInstallment
-- @changelog | Shubkin A.A. | 26.11.25 Добавил [ТипПродукта_Code] и 	ТипПродукта_Наименование
	  , r.[Тип Продукта] --добавил тип продукта
	  , r.ТипПродукта_Code
   from #report	r
   left join  #tУчетСохраненогоБаланса УчетСохраненогоБаланса on  r.НомерДоговора=УчетСохраненогоБаланса.НомерДоговора  
	and r.ДатаОбещания=УчетСохраненогоБаланса.ДатаОбещания

  
 
	  drop table if exists #summary_balance

 -- для сводного отчета 
 select 
	[year] 
	,[MONTH]
	,[Сотрудник]
	, sum(isnull([Сумма сохраненного баланса],0))  'Сумма сохраненного баланса'
	, [Исходный бакет номер],[Исходный бакет номер]-[Конечный бакет номер] 'разница'
	, IsInstallment
	-- predel добавили
    , iif([Исходный бакет номер]=0 and [Конечный бакет номер] = 0, 1,0)  '0-0'
	, iif([Исходный бакет номер]=1 and [Конечный бакет номер] = 0, 1,0)  '1-0'
	, iif([Исходный бакет номер]=2 and [Конечный бакет номер] = 0, 1,0)  '2-0'
	, iif([Исходный бакет номер]=2 and [Конечный бакет номер] = 1, 1,0)  '2-1'
	, iif([Исходный бакет номер]=3 and [Конечный бакет номер] = 0, 1,0)  '3-0'
	, iif([Исходный бакет номер]=3 and [Конечный бакет номер] = 1, 1,0)  '3-1'
	, iif([Исходный бакет номер]=3 and [Конечный бакет номер] = 2, 1,0)  '3-2'
	,[Тип Продукта]--добавил тип продукта
	, ТипПродукта_Code
	into #summary_balance
from (
	SELECT 
		 [year] = year(дата)
		,[MONTH] = MONTH(дата)
		, [Сотрудник]
		, isnull([Сумма сохраненного баланса],0) 'Сумма сохраненного баланса' 
		,[Исходный бакет номер]
		,[Конечный бакет номер]
		, IsInstallment
		-- @changelog | Shubkin A.A. | 26.11.25 Добавил [ТипПродукта_Code] и 	ТипПродукта_Наименование
		,[Тип Продукта]--добавил тип продукта
		, ТипПродукта_Code
    from #report	r
    left join  #tУчетСохраненогоБаланса УчетСохраненогоБаланса 
		on  r.НомерДоговора=УчетСохраненогоБаланса.НомерДоговора  
		and r.ДатаОбещания=УчетСохраненогоБаланса.ДатаОбещания
	where r.success_PTP_new=1  -- 06_04_2020
  --dwh-680
  --and  дата between @dt_startMonth and @dt_endMonth
  
  --/dwh-680
   ) s1
-- 02|04where ([Исходный бакет номер]-[Конечный бакет номер] <> 0) and ([Исходный бакет номер]-[Конечный бакет номер] <=3) 
where (([Исходный бакет номер]-[Конечный бакет номер] <> 0) or ([Исходный бакет номер]=0 and [Конечный бакет номер] = 0) ) and ([Исходный бакет номер]-[Конечный бакет номер] <=3) 
group by [year] 
	,[MONTH]
	,[Сотрудник]
	, [Исходный бакет номер]
	,[Исходный бакет номер]
	,[Конечный бакет номер]
	, IsInstallment
	-- заменит группировку по типу продукта на тип продукта code?
	,[Тип Продукта]--добавил тип продукта
	, ТипПродукта_Code






delete from [collection].dm_CollectionKPIByMonth_ByEmployee_Summary
	where month=@month and year=@year
insert into [collection].dm_CollectionKPIByMonth_ByEmployee_Summary
(
 [Year]
		,  [Month]
		, [Сотрудник]
		-- predel
		, [0-0]
		, [1-0]
		, [2-0]
		, [2-1]
		, [3-0]
		, [3-1]
		, [3-2]
		, IsInstallment
		, [Тип Продукта]--добавил тип продукта
		, ТипПродукта_Code
)
select DISTINCT 
		a1.[Year]
		, a1.[Month]
		, a1.[Сотрудник]
		-- predel
		, (isnull(a8.[Сумма сохраненного баланса],0)) '0-0'
		, (isnull(a2.[Сумма сохраненного баланса],0)) '1-0'
		, (isnull(a3.[Сумма сохраненного баланса],0)) '2-0'
		, (isnull(a4.[Сумма сохраненного баланса],0)) '2-1'
		, (isnull(a5.[Сумма сохраненного баланса],0)) '3-0'
		, (isnull(a6.[Сумма сохраненного баланса],0)) '3-1'
		, (isnull(a7.[Сумма сохраненного баланса],0)) '3-2'
		, a1.IsInstallment
		, a1.[Тип Продукта]--добавил тип продукта
		, a1.ТипПродукта_Code 
from #summary_balance a1
left join (select [Сумма сохраненного баланса], Сотрудник, IsInstallment, [Тип Продукта], ТипПродукта_Code from #summary_balance where [1-0]=1) a2 
	on a1.Сотрудник =a2.Сотрудник 
	and a1.IsInstallment = a2.IsInstallment
	-- вторичные услвия тоже на Тип продукта code?
	and a1.ТипПродукта_Code  = a2.ТипПродукта_Code 
left join (select [Сумма сохраненного баланса], Сотрудник, IsInstallment,[Тип Продукта], ТипПродукта_Code  from #summary_balance where [2-0]=1) a3 
	on a1.Сотрудник =a3.Сотрудник 
	and a1.IsInstallment = a3.IsInstallment
	and a1.ТипПродукта_Code  = a3.ТипПродукта_Code 
left join (select [Сумма сохраненного баланса], Сотрудник, IsInstallment,[Тип Продукта], ТипПродукта_Code  from #summary_balance where [2-1]=1) a4 
	on a1.Сотрудник =a4.Сотрудник 
	and a1.IsInstallment = a4.IsInstallment
	and a1.ТипПродукта_Code  = a4.ТипПродукта_Code 
left join (select [Сумма сохраненного баланса], Сотрудник, IsInstallment,[Тип Продукта], ТипПродукта_Code  from #summary_balance where [3-0]=1) a5 
	on a1.Сотрудник =a5.Сотрудник 
	and a1.IsInstallment = a5.IsInstallment
	and a1.ТипПродукта_Code  = a5.ТипПродукта_Code 
left join (select [Сумма сохраненного баланса], Сотрудник, IsInstallment,[Тип Продукта], ТипПродукта_Code  from #summary_balance where [3-1]=1) a6 
	on a1.Сотрудник =a6.Сотрудник 
	and a1.IsInstallment = a6.IsInstallment
	and a1.ТипПродукта_Code  = a6.ТипПродукта_Code 
left join (select [Сумма сохраненного баланса], Сотрудник, IsInstallment,[Тип Продукта], ТипПродукта_Code  from #summary_balance where [3-2]=1) a7 
	on a1.Сотрудник =a7.Сотрудник 
	and a1.IsInstallment = a7.IsInstallment
	and a1.ТипПродукта_Code  = a7.ТипПродукта_Code 
left join (select [Сумма сохраненного баланса], Сотрудник, IsInstallment,[Тип Продукта], ТипПродукта_Code  from #summary_balance where [0-0]=1) a8 
	on a1.Сотрудник =a8.Сотрудник 
	and a1.IsInstallment = a8.IsInstallment
	and a1.ТипПродукта_Code  = a8.ТипПродукта_Code 

delete from [collection].dm_CollectionKPIByMonth_ByEmployee
	where month=@month and year=@year
 ;
 with  employers as
(
 SELECT distinct  
	fio = CONCAT_WS(' '
		, LastName
		, FirstName
		, MiddleName )
      , s.name  department
   FROM stg._Collection.[Employee] e
   join stg._Collection.EmployeeCollectingStage ECS ON ECS. EmployeeId=E.ID
   join stg._Collection.[CollectingStage] s on eCS.CollectingStageId=s.id
 )
   insert into [collection].dm_CollectionKPIByMonth_ByEmployee
   (
		[Year]
		, [Month]
		, [department]
		, [employee]
		, [Бакет]
		, [Стадия]
		, [PersonType]
		, [ptpCount]
		, [СуммаОбещания]
		, [sumOfSuccessPTP]
		, [SuccessPTPPercent]
		, [SumOfCompletetPromises]
		, [sumOfprincipalRest]
		, [IsInstallment]
		, [Тип Продукта]
		-- @changelog | Shubkin A.A. | 26.11.25 Добавил [ТипПродукта_Code] и 	ТипПродукта_Наименование
		, ТипПродукта_Code
   )
  select 
	year(дата)
	,month(дата)
       , department =  isnull(e.department,'нет отдела')
       , Сотрудник employee
       , Бакет
       , Стадия
	   , '-' PersonType
       , count(*) ptpCount
       , sum(try_cast(СуммаОбещания as float)) СуммаОбещания
       , sumOfSuccessPTP = sum(success_PTP_new+succes_partial_ptp_new)
       , SuccessPTPPercent = cast(
                                  case when isnull(count(*),0)<>0 then cast( sum(success_PTP_new+succes_partial_ptp_new) as float)/count(*) end*100.0 
                                  as decimal(38,2)
                                  )
       , SumOfCompletetPromises =sum (case when (success_PTP_new=1 or succes_partial_ptp_new=1 ) then try_cast(СуммаОбещания as float) else 0.0 end)
       , sumOfprincipalRest =sum(case when success_PTP_new=1 then  ЗадолжностьОсновнойДолгВчера else 0.0 end )
	   , r.IsInstallment
	   , r.[Тип Продукта]
	   , r.ТипПродукта_Code
   -- into dbo.dm_CollectionKPIByMonth_ByEmployee
    from #report r
    left join employers e on e.fio=r.Сотрудник
   where ДатаОбещания is not null and СуммаОбещания>0
     --and not (ОбщаяЗадолностьНаКонецДняСегодня=0 and ПросроченнаяЗадолжностьНаКонецДня=0 and СуммаОбещания>0)
   group by 
   	year(дата)
	,month(дата)
	,isnull(e.department,'нет отдела')
          , Сотрудник
          , Бакет
          , Стадия
		  , r.IsInstallment
		  , r.[Тип Продукта]
		  , r.ТипПродукта_Code
		  -- группировка по  ТипПродукта_Code?
		 -- 06/04/2020 , PersonType

		 /* */
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
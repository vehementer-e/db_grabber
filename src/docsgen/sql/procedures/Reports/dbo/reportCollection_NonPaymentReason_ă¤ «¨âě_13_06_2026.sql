
--exec [dbo].[reportCollection_NonPaymentReason] 2020,3
-- 07/04/2020 формитуем витрину по дням для формирования на стороне отчета
-- создаем дополнительно новую витрину dbo.dm_CollectionNonPaymentReasonDetail
-- =======================================================
-- Modify: 7.02.2022. А.Никитин
-- Description:	DWH-1492 Доработка отчета по причинам неплатежа
-- =======================================================
CREATE          procedure [dbo].[reportCollection_NonPaymentReason]
  @year int
  ,@month int
as 

begin 
/*
declare 
  @year int=2020
  ,@month int=4
 */ 

 if (@month is null) set @month = Month(GetDate())
 if (@year is null) set @year = Year(GetDate())

 
set nocount on

--DWH-1492. 2022-02-07. А.Никитин. -- последний день текущего месяца
--declare 
--@dt date=dateadd(day,-1,cast(format(dateadd(month,1,
--         cast(
--		 format(@year,'0')+format(@month,'00')+'01'
--              as date)
--),'yyyyMM01') as date) ) -- последний день текущего месяца
declare @dt date = dateadd(day, -1, dateadd(month, 1, datefromparts(@year, @month, 1)))
declare @BeginDate date =  datefromparts(@year, @month, 1)
declare @EndDate date = EOMONTH(@BeginDate)


--select cast(format(@dt,'yyyyMM01') as date), dateadd(day,1,@dt)

   --where g.Дата>=dateadd(year,2000,cast(format(@dt,'yyyyMM01') as date)) and g.Дата<dateadd(day,1,dateadd(year,2000,@dt))


--execute as login='sa'

--DWH-1492. 2022-02-07. А.Никитин. Комментарю, т.к. таблица #t не используется
--drop table if exists #t
--select * into #t from  
--OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL;Trusted_Connection=yes;', 'select * from collection.[dbo].[AnotherNonPaymentReason] ')

----select distinct     CommunicationType from stg._collection.V_Communications c where CommunicationDate>'20200101'
----select distinct     PersonType from stg._collection.V_Communications c where CommunicationDate>'20200101'
----select distinct     ContactPhoneType from stg._collection.v_ClientPhones-- c where CommunicationDate>'20200101'
----ContactPhoneType
--select * from #t --where trim(name) <>''
--order by 1


--DWH-1492. 2022-02-07. А.Никитин. Использование локальных таблиц из DWH вместо линка на таблицы из collection
--drop table if exists #dict_NonPaymentReason
--select * into #dict_NonPaymentReason from  
--OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL;Trusted_Connection=yes;', 'select * from collection.[dbo].[NonPaymentReason] ')

--select * from #dict_NonPaymentReason

--select * from #dict_NonPaymentReason 
--select 


----c.* from stg._collection.v_Communications c where CommunicationDate>='20200326'
----order by 4 desc

----select cr.*,c.* from stg._collection.Communications c 
----join stg._collection.CommunicationResult cr on c.CommunicationResultId=cr.id
----order by c.date desc



----select t.name,iddeal,customerid, from stg._collection.CommunicationResult


drop table if exists #pr
  select --t.name
  --, 
  --NonPaymentReason=case when NonPaymentReason= 0 then 'Диагноз: коронавирус' 
  --                      when NonPaymentReason= 1 then 'Банкротство'
  --                      when NonPaymentReason= 2 then 'Больничный'
  --                      when NonPaymentReason= 3 then 'Задержка заработной платы'
  --                      when NonPaymentReason= 4 then 'Не успел оплатить'
  --                      when NonPaymentReason= 5 then 'Отказ от взаимодействия'
  --                      when NonPaymentReason= 6 then 'Претензия'
  --                      when NonPaymentReason= 7 then 'Тех. сбой при оплате'
  --                      when NonPaymentReason= 8 then 'Увольнение'
  --                      when NonPaymentReason= 9 then 'Другое'
  --end
  isnull(npr.Name, 'Причина не указана') as NonPaymentReason
       , d.Number
--,iddeal
--,customerid
       , cu.CrmCustomerId
       , cast(c.date as date) date
--,cu.*

--,* 
into #pr
from stg._collection.Communications c 
--left join #t t on t.id=c.IdAnotherNonPaymentReason
join stg._collection.Customers cu on cu.id=c.customerid
join stg._collection.deals d on d.id=c.IdDeal
--DWH-1492. 2022-02-07. А.Никитин. Использование локальных таблиц из DWH вместо линка на таблицы из collection
--left join #dict_NonPaymentReason npr on npr.id =c.NonPaymentReasonId
left join Stg._collection.NonPaymentReason npr on npr.id =c.NonPaymentReasonId
where --IdAnotherNonPaymentReason is not NULL and 

--DWH-1492. 2022-02-07. А.Никитин. меняю '20200101' на начало месяца, за который заполняется витрина
--c.date>'20200101'
cast(c.date as date) between @BeginDate and @EndDate


--order by c.date desc
/*
drop table if exists #st
select 
	dateadd(day,-1,cast(logdatetime as date)) dt,
	h.CRMClientGUID,
	Client_Stage 
	into #st from 
	
	dwh_new.Dialer.Client_Stage_history h
--DWH-1492. 2022-02-07. А.Никитин. меняю '20200101' на начало месяца, за который заполняется витрина
--where cast(logdatetime as date)>'20200101'
where cast(logdatetime as date) 
	between dateadd(dd,-1, @BeginDate) and dateadd(dd,1,@EndDate)


insert into #st 
SELECT cast(getdate() as date) as dt    
      , [CrmCustomerId]  as CRMClientGUID
	  , cst.Name as Client_Stage
  FROM [Stg].[_Collection].[customers] c
  left join [Stg].[_Collection].[collectingStage] cst
  on c.IdCollectingStage = cst.id
 
 */
 --замена 2х запросов на историю данных из логинома.
 select 
	dt = cast(call_date as date)
	,CRMClientGUID
	,Client_Stage
 into #st
 from stg._loginom.Collection_Client_Stage_history
 where cast(call_date as date) 
	between dateadd(dd,-1, @BeginDate) and dateadd(dd,1,@EndDate)

drop table if exists #pr1
;
with p as (

  select  NonPaymentReason
       , Soft	            = case when Client_Stage='Soft' then CRMClientGUID end
       , Middle	          = case when Client_Stage='Middle' then CRMClientGUID end
       , Prelegal         = case when Client_Stage='Prelegal' then CRMClientGUID end
       , Predelinquency   = case when Client_Stage='Predelinquency' then CRMClientGUID end
       , Legal            = case when Client_Stage='Legal' then CRMClientGUID end
       , [Current]        = case when Client_Stage='Current' then CRMClientGUID end
       , date
 from #pr p 
	left join #st st 
	on p.CrmCustomerId=st.CRMClientGUID and p.date=st.dt
 -- 483
 where 1=1
	--DWH-1492. 2022-02-07. А.Никитин. not in вместо in
	and NonPaymentReason not in ('Причина не указана')
	--and NonPaymentReason in ('Задержка з/п',
	--						'Не успел оплатить',
	--						'Тех. Сбой при оплате',
	--						'Увольнение',
	--						'В отъезде',
	--						'Возникли дополнительные расходы',
	--						'Брал займ не для себя',
	--						'Забыл оплатить',
	--						'Большая кредитная нагрузка',
	--						'Поручил оплату 3-му лицу',
	--						'Командировка',
	--						'Украли деньги',
	--						'Неудобная дата платежа',
	--						'Не согласен с платежом',
	--						'Увеличились расходы',
	--						'Заблокирована карта/счет',
	--						'Декрет',
	--						'Отказался назвать причину',
	--						'Коронавирус: не хочет платить (указ президента)',
	--						'Коронавирус: самоизоляция',
	--						'Коронавирус: находится на карантине',
	--						'Коронавирус: лишился работы',
	--						'Коронавирус: снижение дохода более чем на 30%',
	--						'Коронавирус: не может выехать из другой страны',
	--						'Pre-del',
	--						'Коронавирус: поставлен диагноз',
	--						'Тех. Сбой при оплате в МП/ЛК',
	--						'Тех. Сбой при оплате внешний'
	--						)

 )
 select date
      
      , NonPaymentReason
      , [Current]             = count(distinct [Current])
      , Predelinquency        = count(distinct Predelinquency)
      , Soft                  = count(distinct soft)
      , Middle                = count(distinct Middle)
      , Prelegal              = count(distinct Prelegal)
      , Legal                 = count(distinct Legal)
   into #pr1
   from p
  group by  date, NonPaymentReason



  --- новый вариант с детализацией
  drop table if exists #pr2
;
with p2 as (

  select  NonPaymentReason, Client_Stage, CRMClientGUID
       --, Soft	            = case when Client_Stage='Soft' then CRMClientGUID end
       --, Middle	          = case when Client_Stage='Middle' then CRMClientGUID end
       --, Prelegal         = case when Client_Stage='Prelegal' then CRMClientGUID end
       --, Predelinquency   = case when Client_Stage='Predelinquency' then CRMClientGUID end
       --, Legal            = case when Client_Stage='Legal' then CRMClientGUID end
       --, [Current]        = case when Client_Stage='Current' then CRMClientGUID end
       , date
 from #pr p 
	left join #st st on p.CrmCustomerId=st.CRMClientGUID 
	and p.date=st.dt
 where 1=1 
	--DWH-1492. 2022-02-07. А.Никитин. not in вместо in
	and NonPaymentReason not in ('Причина не указана')
	--and NonPaymentReason in ('Задержка з/п',
	--						'Не успел оплатить',
	--						'Тех. Сбой при оплате',
	--						'Увольнение',
	--						'В отъезде',
	--						'Возникли дополнительные расходы',
	--						'Брал займ не для себя',
	--						'Забыл оплатить',
	--						'Большая кредитная нагрузка',
	--						'Поручил оплату 3-му лицу',
	--						'Командировка',
	--						'Украли деньги',
	--						'Неудобная дата платежа',
	--						'Не согласен с платежом',
	--						'Увеличились расходы',
	--						'Заблокирована карта/счет',
	--						'Декрет',
	--						'Отказался назвать причину',
	--						'Коронавирус: не хочет платить (указ президента)',
	--						'Коронавирус: самоизоляция',
	--						'Коронавирус: находится на карантине',
	--						'Коронавирус: лишился работы',
	--						'Коронавирус: снижение дохода более чем на 30%',
	--						'Коронавирус: не может выехать из другой страны',
	--						'Pre-del',
	--						'Коронавирус: поставлен диагноз',
	--						'Тех. Сбой при оплате в МП/ЛК',
	--						'Тех. Сбой при оплате внешний'
	--						)
 )
 select date , NonPaymentReason, Client_Stage , count(distinct [CRMClientGUID]) as cnt

   into #pr2
   from p2
  group by  date, NonPaymentReason, Client_Stage

  	  delete from  dbo.dm_CollectionNonPaymentReasonDetail where dt_year = @year and dt_month = @month
      insert into dbo.dm_CollectionNonPaymentReasonDetail
      select    
		@year  as dt_year
		, @month as dt_month
		, NonPaymentReason
		, Client_Stage
		, cnt
		, date
	  --into dbo.dm_CollectionNonPaymentReasonDetail
      from #pr2
   --   --where date>='20200401' and date<'20200501'
	  where 
		year(date) = @year 
		and month(date) = @month
   

  --SELECT * FROM #pr2


      --select  NonPaymentReason
      --, [Current]             =  sum([Current]       )
      --, Predelinquency        =  sum(Predelinquency  )
      --, Soft                  =  sum(Soft            )
      --, Middle                =  sum(Middle          )
      --, Prelegal              =  sum(Prelegal        )
      --, Legal                 =  sum(Legal           )
      --from #pr1
      --where date>='20200101' and date<'20200201'
      --group by NonPaymentReason
      
      
      --select  NonPaymentReason
      --, [Current]             =  sum([Current]       )
      --, Predelinquency        =  sum(Predelinquency  )
      --, Soft                  =  sum(Soft            )
      --, Middle                =  sum(Middle          )
      --, Prelegal              =  sum(Prelegal        )
      --, Legal                 =  sum(Legal           )
      --from #pr1
      --where date>='20200201' and date<'20200301'
      --group by  NonPaymentReason
      
      
      --select  NonPaymentReason
      --, [Current]             =  sum([Current]       )
      --, Predelinquency        =  sum(Predelinquency  )
      --, Soft                  =  sum(Soft            )
      --, Middle                =  sum(Middle          )
      --, Prelegal              =  sum(Prelegal        )
      --, Legal                 =  sum(Legal           )
      --from #pr1
      --where date>='20200301' and date<'20200401'
      --group by  NonPaymentReason

	  delete from  dbo.dm_CollectionNonPaymentReason where dt_year = @year and dt_month = @month
      insert into dbo.dm_CollectionNonPaymentReason
      select    
	   @year  as dt_year
      , @month as dt_month
	  , NonPaymentReason
      , [Current]             =  sum([Current]       )
      , Predelinquency        =  sum(Predelinquency  )
      , Soft                  =  sum(Soft            )
      , Middle                =  sum(Middle          )
      , Prelegal              =  sum(Prelegal        )
      , Legal                 =  sum(Legal           )
	  , AllStage = sum([Current]) + sum(Predelinquency) + sum(Soft) + sum(Middle) + sum(Prelegal) +  sum(Legal)
	  --into dbo.dm_NonPaymentReason
      from #pr1
      --where date>='20200401' and date<'20200501'
	  where year(date) = @year 
		and month(date) = @month
	  --date>=cast(format(@dt,'yyyyMM01') as date) and date<dateadd(day,1,@dt)
      group by  NonPaymentReason


	   --- новый вариант с детализацией
  drop table if exists #pr3
;
with p2 as (

  select  NonPaymentReason, Client_Stage, CRMClientGUID
       --, Soft	            = case when Client_Stage='Soft' then CRMClientGUID end
       --, Middle	          = case when Client_Stage='Middle' then CRMClientGUID end
       --, Prelegal         = case when Client_Stage='Prelegal' then CRMClientGUID end
       --, Predelinquency   = case when Client_Stage='Predelinquency' then CRMClientGUID end
       --, Legal            = case when Client_Stage='Legal' then CRMClientGUID end
       --, [Current]        = case when Client_Stage='Current' then CRMClientGUID end
       , date
 from #pr p left join #st st on p.CrmCustomerId=st.CRMClientGUID and p.date=st.dt
 where 1=1
	--DWH-1492. 2022-02-07. А.Никитин. not in вместо in
	and NonPaymentReason not in ('Причина не указана')
	--and NonPaymentReason in ('Задержка з/п',
	--						'Не успел оплатить',
	--						'Тех. Сбой при оплате',
	--						'Увольнение',
	--						'В отъезде',
	--						'Возникли дополнительные расходы',
	--						'Брал займ не для себя',
	--						'Забыл оплатить',
	--						'Большая кредитная нагрузка',
	--						'Поручил оплату 3-му лицу',
	--						'Командировка',
	--						'Украли деньги',
	--						'Неудобная дата платежа',
	--						'Не согласен с платежом',
	--						'Увеличились расходы',
	--						'Заблокирована карта/счет',
	--						'Декрет',
	--						'Отказался назвать причину',
	--						'Коронавирус: не хочет платить (указ президента)',
	--						'Коронавирус: самоизоляция',
	--						'Коронавирус: находится на карантине',
	--						'Коронавирус: лишился работы',
	--						'Коронавирус: снижение дохода более чем на 30%',
	--						'Коронавирус: не может выехать из другой страны',
	--						'Pre-del',
	--						'Коронавирус: поставлен диагноз',
	--						'Тех. Сбой при оплате в МП/ЛК',
	--						'Тех. Сбой при оплате внешний'
	--						)
 )
 select distinct date , NonPaymentReason, Client_Stage ,  p2.[CRMClientGUID] , clients.CRMClientFIO
   into #pr3
   from p2 p2
   left join dwh_new.staging.CRMClient_references clients
   on clients.CRMClientGUID = p2.CRMClientGUID
  --group by  date, NonPaymentReason, Client_Stage

  	  delete from  dbo.dm_CollectionNonPaymentReasonFullDetail where dt_year = @year and dt_month = @month
      insert into dbo.dm_CollectionNonPaymentReasonFullDetail
      select    
		@year  as dt_year
		, @month as dt_month
		, NonPaymentReason
		, Client_Stage
		, [CRMClientGUID] 
		, CRMClientFIO
		, date
		, Format(DateFromParts(@year, @month,1),'yyyy-MM') as Период
	  --into dbo.dm_CollectionNonPaymentReasonFullDetail
      from #pr3
   --   --where date>='20200401' and date<'20200501'
	  where year(date) = @year 
		and month(date) = @month

	  --date>=cast(format(@dt,'yyyyMM01') as date) and date<dateadd(day,1,@dt)

end

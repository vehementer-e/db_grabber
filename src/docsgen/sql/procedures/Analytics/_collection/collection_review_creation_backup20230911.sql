
create      proc  [_collection].[collection_review_creation_backup20230911]
@mode nvarchar(max) = ''
, @zero_rows int = 1
as

begin


if @mode='Динамика получения ИЛ'
begin


--drop table if exists [_collection_динамика_ИЛ]
;

with v as (
select cast(format(isnull( isnull([Дата ИЛ] , [Дата получения ИЛ]), [Дата принятия ИЛ в работу] ), 'yyyy-MM-01' ) as date) [Месяц ИЛ]
, * from _collection.deals_view

)


select [Месяц ИЛ] [Месяц ИЛ]
, count(*) [Листов]
, count(case when [Тип ИЛ]<>'Обеспечительные меры' then 1 end) [Листов кроме Обеспечительные меры]
, count(case when [Тип ИЛ]<>'Обеспечительные меры' then [Дата возбуждения ИП] end) [Возбуждено ИП кроме Обеспечительные меры]
, count(case when [Тип ИЛ]='Обеспечительные меры' then 1 end) [Листов Обеспечительные меры]

, sum([Сумма ИЛ, руб.])/1000000 [Сумма по листам млн]


from v
 where [Месяц ИЛ] between  dateadd(month, -14, getdate()) and dateadd(month, 0, getdate())
 and 1=@zero_rows
 group by [Месяц ИЛ]
 order by [Месяц ИЛ]
 -- where [d Месяц] between  dateadd(month, -12, getdate()) and dateadd(month, -1, getdate())


 end
 



if @mode='Динамика решений суда'
begin

												   
;

with v as (
select cast(format([Иск дата получения решения] , 'yyyy-MM-01' ) as date) [Месяц решения суда]
, cast(format(isnull( isnull([Дата ИЛ] , [Дата получения ИЛ]), [Дата принятия ИЛ в работу] ), 'yyyy-MM-01' ) as date) [Месяц ИЛ]
, * from _collection.deals_view

)


select [Месяц решения суда] [Месяц решения суда]
, count(DISTINCT Код) [Решений суда]
, count(DISTINCT case when [Тип ИЛ]<>'Обеспечительные меры' then Код end) [Листов кроме Обеспечительные меры]


from v
 where [Месяц решения суда] between  dateadd(month, -14, getdate()) and dateadd(month, -0	, getdate()) --and [Тип ИЛ]<>'Обеспечительные меры'
 and 1=@zero_rows

 group by [Месяц решения суда]
 order by [Месяц решения суда]
 -- where [d Месяц] between  dateadd(month, -12, getdate()) and dateadd(month, -1, getdate())


 end
 

if @mode='Статус после ареста'
begin
drop table if exists #t1


select
case when   [Результат вторых торгов]=1 then 'Вторые торги не состоялись - в процессе принятия на баланс'    
  when   [Фактическая дата первых торгов] is not null and [Результат первых торгов]=1 and [Фактическая дата вторых торгов] is null and [Плановая дата вторых торгов] is null then 'Торги 1 не состоялись Торги 2 не назначены'  
  when   [Фактическая дата первых торгов] is not null and [Результат первых торгов]=1  then 'Торги 1 не состоялись ожидаем результата торгов 2'  
  when   [Фактическая дата первых торгов] is not null and [Результат первых торгов] is null then 'Ожидаем результата торгов 1'  
  when [Фактическая дата вторых торгов]<getdate()-1 and [Результат вторых торгов] is null then 'Не проставлен результат вторых торгов'
  when [Фактическая дата первых торгов]<getdate()-1 and [Результат первых торгов] is null then 'Не проставлен результат первых торгов'
  when   [Фактическая дата первых торгов] is null and [Фактическая дата вторых торгов] is null and [Статус после ареста]='Оценка/переоценка'  then 'Оценка/переоценка'  
  when   [Фактическая дата первых торгов] is null and [Фактическая дата вторых торгов] is null then 'Нет даты торгов'  
  else 'Статус неизвестен'
  end [Статус ареста]
  , *
  into #t1
from _collection.deals_view
where [Дата ареста авто] is not null and [Дата принятия на баланс] is null and [Дата погашения] is null 
and isnull([Результат первых торгов], 1)<>0
and isnull([Результат вторых торгов], 1)<>0
and isnull(БВ, '')<>'Да'
and isnull([Бакнрот], '')<>'Да'
and [HardFraud дата] is null
 

 ;
 with v as(
select *, ROW_NUMBER() over(partition by vin, [id клиента] order by case when isnull([Статус ареста], 'Нет даты торгов'  )='Нет даты торгов'   then 1 else 0 end ) rn from #t1

)

select * from v
where rn=1

 end

 
if @mode='Клиенты для контроля'
begin


select *, 'https://collection.cm.carmoney.ru/customers/'+cast(CustomerId as nvarchar(20)) [Ссылка клиент] from (

select CustomerId, 'Одновременно подтвержденный и неподтвержденный банкрот' Тип from [_collection].[CustomerStatus_view]
where CustomerState=('Банкрот подтверждённый' ) and IsActive=1 
intersect 
select CustomerId, 'Одновременно подтвержденный и неподтвержденный банкрот' Тип from [_collection].[CustomerStatus_view]
where CustomerState=('Банкрот неподтверждённый' ) and IsActive=1 

union all

select CustomerId, 'Отсутствует дата решения для подтвержденного банкротства' Тип from [_collection].[CustomerStatus_view]
where CustomerState=('Банкрот подтверждённый' ) and IsActive=1 and DateResultOfCourtsDecisionBankrupt is null

union all


select CustomerId, 'Отсутствует дата решения для неподтвержденного банкротства' Тип from [_collection].[CustomerStatus_view]
where CustomerState=('Банкрот неподтверждённый' ) and IsActive=1 and BankruptcyFilingDate is null

union all


select CustomerId, 'Отсутствует дата смерти' Тип from [_collection].[CustomerStatus_view]
where CustomerState='Смерть подтвержденная' and IsActive=1 and date is null

union all


select distinct [id клиента], 'Торги состоялись или принят на баланс но нет статуса БВ' Тип from _collection.deals_view
where ([Результат первых торгов]=0 or [Результат вторых торгов]=0 or [Дата принятия на баланс] is not null )and  isnull(БВ, '')='Нет' and [Дата погашения] is null

union all


select distinct [id клиента], 'Есть дата иска. сумма платежей больше суммы по судебному решению. Но нет статуса БВ' Тип from _collection.deals_view
where [Дата иска] is not null and [Сумма платежей после даты иска]>=[Сумма по судебному решению] and  isnull(БВ, '')='Нет' and [Дата погашения] is null

union all


select distinct [id клиента], 'Есть результат торгов но нет даты торгов' Тип from _collection.deals_view
where ([Фактическая дата первых торгов] is null and [Результат первых торгов] in ('1', '0') ) or
        ([Фактическая дата вторых торгов] is null and [Результат вторых торгов] in ('1', '0') )-- or
		
union all


select distinct [id клиента], 'нет даты СП' Тип from  _collection.deals_view
  where [СП дата] is null and 
  (
  [Дата иска] is not null or 
  [Иск дата решения] is not null or 
  [Иск дата получения решения] is not null or 
  [Дата ИЛ] is not null or 
  [Дата получения ИЛ] is not null or 
  [Дата принятия ИЛ в работу] is not null or 
  [Дата возбуждения ИП] is not null or 
  [Дата ареста авто] is not null )--or 		
union all


select distinct [id клиента], 'нет даты иска' Тип from  _collection.deals_view
  where [Дата иска] is null and 
  (
 -- [Дата иска] is not null or 
  [Иск дата решения] is not null or 
  [Иск дата получения решения] is not null or 
  [Дата ИЛ] is not null or 
  [Дата получения ИЛ] is not null or 
  [Дата принятия ИЛ в работу] is not null or 
  [Дата возбуждения ИП] is not null or 
  [Дата ареста авто] is not null )--or 

union all


select distinct [id клиента], 'нет даты ИЛ' Тип from  _collection.deals_view
  where [Дата ИЛ] is null and 
  (

  [Дата получения ИЛ] is not null or 
  [Дата принятия ИЛ в работу] is not null  
  )
union all


select distinct [id клиента], 'нет даты получения ИЛ' Тип from  _collection.deals_view
  where [Дата получения ИЛ]  is null and 
  (

  [Дата ИЛ] is not null or 
  [Дата принятия ИЛ в работу] is not null  

  )

  
union all


select distinct [id клиента], 'нет даты принятия ИЛ в работу' Тип from  _collection.deals_view
  where [Дата принятия ИЛ в работу]  is null and 
  (

  [Дата ИЛ] is not null or 
  [Дата получения ИЛ] is not null  

  )
) x


end



if @mode='Портфель ИЛ Inhouse/KA'
begin



  drop table if exists #ils
  select код, min( case when [Тип ИЛ]<>'Обеспечительные меры' then isnull( isnull([Дата ИЛ] , [Дата получения ИЛ]), [Дата принятия ИЛ в работу] ) end) [Дата ИЛ учет] into #ils from
  _collection.deals_view
  group by код
  having min( case when [Тип ИЛ]<>'Обеспечительные меры' then isnull( isnull([Дата ИЛ] , [Дата получения ИЛ]), [Дата принятия ИЛ в работу] ) end) is not null
--
--   select код, [Дата ИЛ учет] from
--
-- #ils
-- except
--
-- select код, [Дата ИЛ учет] from
-- #collection1
-- where [Дата ИЛ учет] is not null
-- select * from _collection
-- where Код='21031100087057'
--
-- 19071100000159
--    drop table if exists #ka
--
--    select a.External_id, a.st_date, isnull(a.fact_end_date,'4444-01-01') fact_end_date, a.agent_name into #ka
--from dwh_new.dbo.agent_credits a


--    drop table if exists #ka
--
--    select a.External_id, a.st_date, isnull(a.fact_end_date,'4444-01-01') fact_end_date, a.agent_name into #ka
--from dwh_new.dbo.agent_credits a



    drop table if exists #ka

    select a.External_id, a.st_date
	, 
	
	
	case 
	
	when  lead(st_date) over(partition by External_id order by st_date) is  null and a.fact_end_date is not null then a.fact_end_date
	when  lead(st_date) over(partition by External_id order by st_date) is  null and a.fact_end_date is  null then '4444-01-01'
	when  lead(st_date) over(partition by External_id order by st_date) is not null and ( lead(st_date) over(partition by External_id order by st_date) < a.fact_end_date or  a.fact_end_date is  null)  then dateadd(day, -1 , lead(st_date) over(partition by External_id order by st_date))
	when  lead(st_date) over(partition by External_id order by st_date) is not null and lead(st_date) over(partition by External_id order by st_date) >= a.fact_end_date then a.fact_end_date
	end
	
	
	fact_end_date, a.agent_name into #ka
from dwh_new.dbo.agent_credits a


--
--
--select * from (
--select *, lead(st_date) over(partition by External_id order by st_date) ll from #ka
--) x
--where External_id='1604302340001'
--where st_date>fact_end_date


  drop table if exists #t2

  ;
--  with v as (
--  select a.External_id, a.st_date, isnull(a.fact_end_date,'4444-01-01') fact_end_date, a.agent_name
--from dwh_new.dbo.agent_credits a
--
--  )
--
--  select a.d,a.[d Месяц], a.Клиент, a.Код, a.[остаток од], a.[Дата закрытия], b.[Первая дата ИЛ], case when v.agent_name is not null then 'КА' else 'Кармани' end [КА / Кармани], [сумма поступлений]
--  into #t2
--  from v_balance a
--  join #ils b on a.Код=b.Код and a.d >= b.[Первая дата ИЛ] 
--  left join v on v.External_id=a.Код and a.d between st_date and fact_end_date
--
--  drop table if exists #t3
--
--  select [d Месяц],[КА / Кармани], sum(case when d=[d Месяц] then [остаток од] end)/1000000.0 [остаток од млн] , sum([сумма поступлений])/1000000.0 [сумма поступлений млн]
--  --into #t3
--  from #t2
--  where [d Месяц] between  dateadd(month, -12, getdate()) and dateadd(month, -1, getdate())
--  group by [d Месяц],[КА / Кармани]

  with v as (
  select a.External_id, a.st_date, isnull(a.fact_end_date,'4444-01-01') fact_end_date, a.agent_name
from #ka  a

  )
  , v1 as (
  select a.d,a.[d Месяц], a.Клиент, a.Код, a.[остаток од], a.[Дата закрытия], b.[Дата ИЛ учет], case when v.agent_name is not null then 'KA' else 'Carmoney' end [КА / Кармани], [сумма поступлений]
 -- into #t2
  from v_balance a
  join #ils b on a.Код=b.Код and a.d >= b.[Дата ИЛ учет] 
  left join v on v.External_id=a.Код and a.d between st_date and fact_end_date
  )
 -- select * from (
 -- select *, count(*) over(partition by Код, d ) cnt from v1
 -- ) x where cnt>1
 -- order by cnt desc
 -- drop table if exists #t3

  select [d Месяц]--,[КА / Кармани]
  , [KA остаток од млн]        =  sum(case when [КА / Кармани]= 'KA' and d=[d Месяц] then [остаток од] end)/1000000.0       
  , [KA сумма поступлений млн] =  sum(case when [КА / Кармани]= 'KA'                 then [сумма поступлений] end)/1000000.0

  , [Carmoney остаток од млн]        =  sum(case when [КА / Кармани]= 'Carmoney' and d=[d Месяц] then [остаток од] end)/1000000.0       
  , [Carmoney сумма поступлений млн] =  sum(case when [КА / Кармани]= 'Carmoney'                 then [сумма поступлений] end)/1000000.0
  
  , [Total остаток од млн]        =  sum(case when 1=1 and d=[d Месяц] then [остаток од] end)/1000000.0       
  , [Total сумма поступлений млн] =  sum(case when 1=1                 then [сумма поступлений] end)/1000000.0
  --into #t3
  from v1
  where [d Месяц] between  dateadd(month, -14, getdate()) and dateadd(month, -0, getdate())
 and 1=@zero_rows
  
  group by [d Месяц]--,[КА / Кармани]






end

if @mode='Банкроты'
begin


	drop table if exists #Банкроты
	
  select x.CRMClientGUID
  , case when [Признак банкрот подтвержденный]=1 then [Дата банкрот неподтвержденный]  
         when [Признак банкрот подтвержденный]=0 and [Признак банкрот неподтвержденный]=1 then [Дата банкрот неподтвержденный] end [Дата банкрот неподтвержденный] 
  , case when [Признак банкрот подтвержденный]=1 then [Дата банкрот подтвержденный] end [Дата банкрот подтвержденный] 
  , case when [Признак банкрот подтвержденный]=1 or  [Признак банкрот неподтвержденный] =1 then [Дата заявления] end [Дата заявления] 
  
  into #Банкроты
  from (
  select CRMClientGUID CRMClientGUID
  ,min(case when customerstate in ('Банкрот неподтверждённый' ) then BankruptcyFilingDate end ) [Дата банкрот неподтвержденный]
  ,min(case when customerstate in ('Банкрот подтверждённый' ) then DateResultOfCourtsDecisionBankrupt end )   [Дата банкрот подтвержденный]
  ,min(case when customerstate in ('Банкрот подтверждённый', 'Банкрот неподтверждённый' ) then isnull(BankruptConfirmed_BankruptcyFilingDate , BankruptcyFilingDate) end )   [Дата заявления]
  ,min(case when customerstate in ('Банкрот неподтверждённый' ) then  case when BankruptcyFilingDate is not null then cast(IsActive as int)  end end ) [Признак банкрот неподтвержденный]
  ,min(case when customerstate in ('Банкрот подтверждённый' )   then case when DateResultOfCourtsDecisionBankrupt is not null then cast(IsActive as int) end  end ) [Признак банкрот подтвержденный]

    FROM [_collection].[CustomerStatus_view] a
 	join mv_loans b on a.[CustomerId]=b.[id клиента Спейс]
	group by CRMClientGUID
	) x



		--drop table if exists [dbo].[_collection_отчет_Банкроты]

	---select *
	---  FROM [Analytics].[dbo].[_collection_CustomerStatus] a
	---  where customerstate in ('Банкрот неподтверждённый' ) and IsActive=1

	    select  [Дата выдачи месяц]
	    ,       [Дата банкрот подтвержденный]
	    ,       [Дата банкрот неподтвержденный]
		,       datediff(month, [Дата выдачи месяц],  cast(format(b.[Дата банкрот подтвержденный]	, 'yyyy-MM-01')  as date)) Месяцев
	    ,       ROW_NUMBER() over(partition by a.CRMClientGUID order by [Дата выдачи] desc) rn_desc
	    ,       ROW_NUMBER() over(partition by a.CRMClientGUID order by [Дата выдачи] ) rn 
	    ,      case when first_value(isInstallment) over(partition by a.CRMClientGUID order by [Дата выдачи] desc ) = 1 then 'Инст' else 'ПТС' end [Продукт последнего выданного займа] 
		,       cast(format(b.[Дата заявления]	, 'yyyy-MM-01')  as date) [Дата заявления месяц]
		,       cast(format(b.[Дата банкрот подтвержденный]	, 'yyyy-MM-01')  as date)     [Дата банкрот подтвержденный месяц]
		,       cast(format(b.[Дата банкрот неподтвержденный]	, 'yyyy-MM-01')  as date) [Дата банкрот неподтвержденный месяц]
		,       код
		,       a.CRMClientGUID
		,       r.Region
		--into [dbo].[_collection_отчет_Банкроты]
	from mv_loans a

	left join #Банкроты b on a.CRMClientGUID=b.CRMClientGUID
	left join  [Stg].[_Collection].[registration] r on r.IdCustomer=a.[id клиента Спейс]
		where 1=1
 and 1=@zero_rows





end

if @mode='Портфель умерших клиентов'
begin



drop table if exists #bunkruptcy_confirmed
--select distinct CustomerState   from _collection_CustomerStatus
select distinct CustomerId into #bunkruptcy_confirmed from  [_collection].[CustomerStatus_view]
where CustomerState ='Банкрот подтверждённый' and IsActive=1


	drop table if exists #t1
	
  select x.[CustomerId]
  , [Дата смерти]
  , [Дата статуса Смерть подтвержденная]
  into #смерть
  from (
  select [CustomerId] [CustomerId]
  , min(Date) [Дата смерти]
  , max(isnull(UpdateDate,createdate) ) [Дата статуса Смерть подтвержденная]
    FROM [_collection].[CustomerStatus_view]
	where CustomerState='Смерть подтвержденная' and IsActive=1
	group by [CustomerId]
	) x


	drop table if exists #_collection_отчет_Умершие_воронка_по_клиенту



	;
with v as(
	select b.[Дата смерти]
	, case when c.CustomerId is not null then 'Банакрот' else 'Не банакрот' end [Признак банкрот]
	, case when max( a.[dpd начало дня]) over(partition by [id клиента])>0   then 'Просрочка' else 'Без просрочки' end [Признак просрочка]
	, case 
	when b.[Дата смерти] is null then null
	when a.[Фактическая дата вторых торгов] is not null and ( [Дата принятия на баланс] is not null or [Дата платежа после вторых торгов] is not null) then '08) Есть дата торгов и оплата либо баланс'
	when a.[Фактическая дата первых торгов] is not null and ( [Дата принятия на баланс] is not null or [Дата платежа после первых торгов] is not null) then '08) Есть дата торгов и оплата либо баланс'
	when a.[Фактическая дата вторых торгов] is not null and ( [Дата принятия на баланс] is null or [Дата платежа после вторых торгов] is null) then '07) Есть дата торгов но нет оплаты либо баланса'
	when a.[Фактическая дата первых торгов] is not null and ( [Дата принятия на баланс] is null or [Дата платежа после первых торгов] is null) then '07) Есть дата торгов но нет оплаты либо баланса'
	when a.[Дата ареста авто] is not null and ( [Фактическая дата первых торгов] is null or [Фактическая дата вторых торгов] is null) then '06) Есть арест но нет торгов'
	when a.[Дата возбуждения ИП] is not null and (  a.[Дата ареста авто]  is null) then '05) Есть дата возбуждения ИП но нет ареста'
	when (a.[Дата ИЛ] is not null or [Дата получения ИЛ] is not null) and isnull([Тип ИЛ], '')<>'Обеспечительные меры' and (   a.[Дата возбуждения ИП]  is null) then '04) Есть дата ИЛ кроме ОМ но нет возбуждения ИП'
	when [Иск дата решения] is not null and (  a.[Дата ИЛ] is  null or [Дата получения ИЛ] is  null or isnull([Тип ИЛ], '')='Обеспечительные меры')  then '03) Есть дата решения но нет даты получения ИЛ или нет даты Листа'
	when [Дата иска] is not null and [Иск дата решения] is null then '02) Есть дата иска но нет даты решения'
	when [Дата иска] is null then '01) Нет даты иска'
	end [Статус судебной работы]
	,a.*
	from _collection.deals_view  a 
	LEFT join #смерть b on a.[id клиента]=b.CustomerId and b.[Дата смерти] is not null
	left join #bunkruptcy_confirmed c on c.CustomerId=a.[id клиента]
	where [Дата погашения] is null
	)
	, v_rn as (
	select ROW_NUMBER() over(partition by [id клиента] order by [Статус судебной работы] desc) rn,* from v
	
	)
	select case when a.[Дата смерти] is not null then 'Мертвый' else 'Живой' end [Признак смерть], b.[Открытых займов] ,b.[Остаток ОД на сегодня по клиенту] ,b.[Статус судебной работы по договорам] ,a.* 
	
	--into #_collection_отчет_Умершие_воронка_по_клиенту 
	from v_rn a
	left join
	(
	select [id клиента], STRING_AGG(cast(код+' - '+[Статус судебной работы] as nvarchar(max)) , '/') [Статус судебной работы по договорам], sum(case when rn_Договор=1 then [Остаток ОД на сегодня] end ) [Остаток ОД на сегодня по клиенту]
	, count(case when rn_Договор=1 then 1 end ) [Открытых займов]
	from v_rn
	group by [id клиента]
	) b on a.[id клиента]=b.[id клиента]

	where a.rn=1
	
 and 1=@zero_rows

--	drop table if exists [dbo].[_collection_отчет_Умершие_воронка_по_клиенту]
--	select * into [dbo].[_collection_отчет_Умершие_воронка_по_клиенту]
--	from #_collection_отчет_Умершие_воронка_по_клиенту


end
if @mode='Портфель умерших клиентов динамика'
begin


	drop table if exists #смерть1
	
  select x.[CustomerId]
  , [Дата смерти]
  , [Дата статуса Смерть подтвержденная]
  into #смерть1
  from (
  select [CustomerId] [CustomerId]
  , min(Date) [Дата смерти]
  , max(isnull(UpdateDate,createdate) ) [Дата статуса Смерть подтвержденная]
    FROM [_collection].[CustomerStatus_view]
	where CustomerState='Смерть подтвержденная' and IsActive=1
	group by [CustomerId]
	) x



	select [d Месяц]
	, count(distinct [id клиента]) [Умерших клиентов]
	, count(distinct case when [сумма поступлений]>0 then [id клиента] end) [Умерших клиентов с платежом]
	, count(distinct case when [сумма поступлений]>0 then [id клиента] end)/  (0.0+count(distinct [id клиента])) [% Платило от умерших]
	 
	, sum([сумма поступлений])/1000000.0 [сумма поступлений по умершим]
	--, sum(case when [Появился в портфеле в середине месяца]=1 then [остаток од] end )/1000000.0 [Портфель ОД умерших]
	, sum(case when d=[d Месяц] then [остаток од] end )/1000000.0 [Портфель ОД умерших]
	--, sum([сумма поступлений])/ sum(case when [Появился в портфеле в середине месяца]=1 then [остаток од] end )  [Доля поступлений от ОД]
	, sum([сумма поступлений])/ sum(case when d=[d Месяц] then [остаток од] end )  [Доля поступлений от ОД]
	--into  [dbo].[_collection_отчет_Умершие_Портфель]
	from (

	select a.Код, b.[Дата смерти], c.Клиент, a.[id клиента], c.[сумма поступлений], c.d, c.[d Месяц], c.[остаток од]
	, case 
	when min(d) over(partition by  c.[d Месяц],  a.Код) <>  c.[d Месяц] then
	
			case when min(d) over(partition by  c.[d Месяц],  a.Код)=d then 1 end 
	when min(d) over(partition by  c.[d Месяц],  a.Код) =  c.[d Месяц] then
			case when[d Месяц]=d then 1 end 
			
			end
			[Появился в портфеле в середине месяца]
	from _collection.deals_view  a 
	join #смерть1 b on a.[id клиента]=b.CustomerId and b.[Дата смерти] is not null
	join v_balance c on c.d>=b.[Дата смерти] and a.Код=c.Код
	where a.rn_Договор=1
	)x
	where 1=1
 and 1=@zero_rows

	group by [d Месяц]
	order by [d Месяц]

end


if @mode='Рабочий портфель'
begin
drop table if exists #Рабочий
drop table if exists #collection1 

	
	select 
	min(case when [Тип ИЛ]<>'Обеспечительные меры' then [БВ Дата окончания ИП] end ) over(partition by Код)  [БВ Дата окончания ИП]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then isnull( isnull([Дата ИЛ] , [Дата получения ИЛ]), [Дата принятия ИЛ в работу] ) end ) over(partition by Код)  [Дата ИЛ учет]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then [Дата ареста авто] end ) over(partition by Код)  [Дата ареста авто]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then [Фактическая дата первых торгов] end ) over(partition by Код)  [Фактическая дата первых торгов]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then [Фактическая дата вторых торгов] end ) over(partition by Код)  [Фактическая дата вторых торгов]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then [Дата платежа после состоявшихся торгов] end ) over(partition by Код)  [Дата платежа после состоявшихся торгов]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then [Дата состоявшихся торгов] end ) over(partition by Код)  [Дата состоявшихся торгов]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then [Дата принятия на баланс] end ) over(partition by Код)  [Дата принятия на баланс]
	, min(case when [Тип ИЛ]<>'Обеспечительные меры' then [Дата возбуждения ИП] end ) over(partition by Код)  [Дата возбуждения ИП]
	--, min(  ) over(partition by Код)  [Дата ИЛ учет]
	--, [Дата принятия на баланс]
	, Код
--	, [Дата состоявшихся торгов] [Дата состоявшихся торгов]
	, [Основание БВ по договору]
	, [БВ наличие соглашения]
	, [Смерть дата] [Смерть дата]
	--, [Fraud дата] [Fraud дата]
	--, [Дата платежа после состоявшихся торгов] [Дата платежа после состоявшихся торгов]
	--, [Фактическая дата вторых торгов] [Фактическая дата вторых торгов]
	--, [Фактическая дата первых торгов] [Фактическая дата первых торгов]
	----, [БВ Дата окончания ИП] [БВ Дата окончания ИП]
	--, [Банкрот подтвержденный дата] [Банкрот подтвержденный дата]
	--, [Дата возбуждения ИП] [Дата возбуждения ИП]
	--, [Дата ареста авто] [Дата ареста авто]
	
	into 
	#collection1
	from _collection.deals_view
	
	--where rn_Договор=1


	--select * from _collection
	--where [Дата получения ИЛ]<=[Дата принятия ИЛ в работу]
	;

	with v as (select *, ROW_NUMBER() over(partition by код order by (select 1)) rn from #collection1 ) 
	delete from v where rn>1 or [Дата ИЛ учет] is null
	;

	with b as (
	select a.Код
	, a.[остаток од]
	, a.[сумма поступлений]
	, a.[d Месяц]
	, a.d
	, v.[Дата принятия на баланс] 
	, v.[БВ наличие соглашения] 
	, v.[Дата состоявшихся торгов]
	, v.[Основание БВ по договору]
	, 
	case 
	when a.d>=v.[БВ Дата окончания ИП]  then 'Безнадежное взыскание' 
	--when a.d>=v.[Смерть дата]  then 'Безнадежное взыскание' 
	--when a.d>=v.[Банкрот подтвержденный дата]  then 'Безнадежное взыскание' 
	--when a.d>=v.[Fraud дата]  then 'Безнадежное взыскание' 
	else 'Рабочий портфель'
	end [Тип портфеля]
	, case when a.d>=[Дата возбуждения ИП] then 1 else 0 end [ИП]
	, case when a.d>=[Дата ареста авто] then 1 else 0 end [Арест]
	, case when a.d>=[Фактическая дата первых торгов]  or a.d >= [Фактическая дата вторых торгов] then 1 else 0 end [Торги]
	, case when a.d>=[Дата принятия на баланс] or a.d>=[Дата платежа после состоявшихся торгов]  then 1 else 0 end [Баланс/поступили ДС]

	from v_balance a  join #collection1 v on a.Код=v.Код and a.d>=v.[Дата ИЛ учет] --and v.rn_Договор=1
	 )

	select [d Месяц], [Тип портфеля]
	, sum([сумма поступлений])/1000000.0 [сумма поступлений млн]
	, sum(case when d=[d Месяц] then [остаток од] end)/1000000.0 [остаток од млн]
	, sum(case when d=[d Месяц] then 1 end) Договоров
	, sum(case when d=[d Месяц] then [ИП] end) [ИП]
	, sum(case when d=[d Месяц] then [Арест] end) [Арест]
	, sum(case when d=[d Месяц] then [Торги] end) [Торги]
	, sum(case when d=[d Месяц] then [Баланс/поступили ДС] end) [Баланс/поступили ДС]
	, sum(case when d=[d Месяц] then [БВ Баланс] end) [БВ Баланс]
	, sum(case when d=[d Месяц] then [БВ Допсоглашение] end) [БВ Допсоглашение]
	, sum(case when d=[d Месяц] then [БВ ТС с торгов] end) [БВ ТС с торгов]
	, sum(case when d=[d Месяц] then [БВ 47 статья] end) [БВ 47 статья]
	into #Рабочий
	from
	 (
	 select * ,  
	 case when [Тип портфеля]='Безнадежное взыскание' and d >= [Дата принятия на баланс]   then  1 else 0 end [БВ Баланс]
	 , case when [Тип портфеля]='Безнадежное взыскание' and [БВ наличие соглашения] =1 then  1 else 0 end [БВ Допсоглашение]
	 , case when [Тип портфеля]='Безнадежное взыскание' and d>=[Дата состоявшихся торгов]   then  1 else 0 end [БВ ТС с торгов]
	 , case when [Тип портфеля]='Безнадежное взыскание' and [Основание БВ по договору] like '%47%' then  1 else 0 end [БВ 47 статья]

 
 
	 from b
	 ) x
	 group by [d Месяц], [Тип портфеля]


	 select * from #Рабочий
	 where ([d Месяц]>=dateadd(year,-1, cast( format(getdate(), 'yyyy-01-01' )  as date) ) ) or ( [d Месяц]=  cast( format([d Месяц], 'yyyy-01-01' )  as date) and year(getdate()) - year([d Месяц])<=5 )
	 
	
 and 1=@zero_rows

end


if @mode='СП детализация'
begin


  select *, getdate() created from _collection.deals_view where [id сп] is not null

end



  end
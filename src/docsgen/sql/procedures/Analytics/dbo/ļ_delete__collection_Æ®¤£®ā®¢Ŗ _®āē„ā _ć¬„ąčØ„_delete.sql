CREATE proc  [dbo].[_collection_подготовка_отчета_умершие]
as

begin

--select * 
--  FROM [Analytics].[dbo].[_collection_CustomerStatus]
--	where CustomerState='Смерть подтвержденная'


drop table if exists #bunkruptcy_confirmed
--select distinct CustomerState   from _collection_CustomerStatus
select distinct CustomerId into #bunkruptcy_confirmed from _collection_CustomerStatus
where CustomerState ='Банкрот подтверждённый' and IsActive=1


	drop table if exists #t1
	
  select x.[CustomerId]
  , [Дата смерти]
  , [Дата статуса Смерть подтвержденная]
  into #t1
  from (
  select [CustomerId] [CustomerId]
  , min(Date) [Дата смерти]
  , max(isnull(UpdateDate,createdate) ) [Дата статуса Смерть подтвержденная]
    FROM [Analytics].[dbo].[_collection_CustomerStatus]
	where CustomerState='Смерть подтвержденная' and IsActive=1
	group by [CustomerId]
	) x


	drop table if exists #_collection_отчет_Умершие_воронка_по_клиенту



	;
with v as(
	select b.[Дата смерти]
	, case when c.CustomerId is not null then 1 else 0 end [Признак банкрот]
	, case 
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
	from dbo._collection  a 
	join #t1 b on a.[id клиента]=b.CustomerId and b.[Дата смерти] is not null
	left join #bunkruptcy_confirmed c on c.CustomerId=a.[id клиента]
	where [Дата погашения] is null
	)
	, v_rn as (
	select ROW_NUMBER() over(partition by [id клиента] order by [Статус судебной работы] desc) rn,* from v
	
	)
	select b.[Открытых займов] ,b.[Остаток ОД на сегодня по клиенту] ,b.[Статус судебной работы по договорам] ,a.* into #_collection_отчет_Умершие_воронка_по_клиенту from v_rn a
	left join
	(
	select [id клиента], STRING_AGG(cast(код+' - '+[Статус судебной работы] as nvarchar(max)) , '/') [Статус судебной работы по договорам], sum(case when rn_Договор=1 then [Остаток ОД на сегодня] end ) [Остаток ОД на сегодня по клиенту]
	, count(case when rn_Договор=1 then 1 end ) [Открытых займов]
	from v_rn
	group by [id клиента]
	) b on a.[id клиента]=b.[id клиента]

	where a.rn=1

	drop table if exists [dbo].[_collection_отчет_Умершие_воронка_по_клиенту]
	select * into [dbo].[_collection_отчет_Умершие_воронка_по_клиенту]
	from #_collection_отчет_Умершие_воронка_по_клиенту

	--orer by 3

	drop table if exists [dbo].[_collection_отчет_Умершие_Портфель]


	select [d Месяц]
	, count(distinct [id клиента]) [Умерших клиентов]
	, count(distinct case when [сумма поступлений]>0 then [id клиента] end) [Умерших клиентов с платежом]
	, count(distinct case when [сумма поступлений]>0 then [id клиента] end)/  (0.0+count(distinct [id клиента])) [% Платило от умерших]
	 
	, sum([сумма поступлений])/1000000.0 [сумма поступлений по умершим]
	, sum(case when [Появился в портфеле в середине месяца]=1 then [остаток од] end )/1000000.0 [Портфель ОД умерших]
	, sum([сумма поступлений])/ sum(case when [Появился в портфеле в середине месяца]=1 then [остаток од] end )  [Доля поступлений от ОД]
	into  [dbo].[_collection_отчет_Умершие_Портфель]
	from (

	select a.Код, b.[Дата смерти], c.Клиент, a.[id клиента], c.[сумма поступлений], c.d, c.[d Месяц], c.[остаток од]
	, case 
	when min(d) over(partition by  c.[d Месяц],  a.Код) <>  c.[d Месяц] then
	
			case when min(d) over(partition by  c.[d Месяц],  a.Код)=d then 1 end 
	when min(d) over(partition by  c.[d Месяц],  a.Код) =  c.[d Месяц] then
			case when[d Месяц]=d then 1 end 
			
			end
			[Появился в портфеле в середине месяца]
	from dbo._collection  a 
	join #t1 b on a.[id клиента]=b.CustomerId and b.[Дата смерти] is not null
	join v_balance c on c.d>=b.[Дата смерти] and a.Код=c.Код
	where a.rn_Договор=1
	)x
	group by [d Месяц]
	order by [d Месяц]
	
	--order by b.[Дата смерти], a.Код, c.d


	select * from (
select *, lag([остаток од]) over(partition by Код order by d )  [остаток од before] from (
		select a.Код, b.[Дата смерти], c.Клиент, a.[id клиента], c.[сумма поступлений], c.d, c.[d Месяц], c.[остаток од]
	, case 
	when min(d) over(partition by  c.[d Месяц],  a.Код) <>  c.[d Месяц] then
	
			case when min(d) over(partition by  c.[d Месяц],  a.Код)=d then 1 end 
	when min(d) over(partition by  c.[d Месяц],  a.Код) =  c.[d Месяц] then
			case when[d Месяц]=d then 1 end 
			
			end
			[Появился в портфеле в середине месяца]
	from dbo._collection  a 
	join #t1 b on a.[id клиента]=b.CustomerId and b.[Дата смерти] is not null
	join v_balance c on c.d>=b.[Дата смерти] and a.Код=c.Код
	) x  
	) xx
	where xx.[остаток од before]<>xx.[остаток од]
	order by d 

	return

--	drop table if exists #shest_smert
--
--
--
--select '1701084010001'd  into  #shest_smert  union all
--select '1706302150001' d union all
--select '18032415700001' d union all
--select '18100507360003' d union all
--select '19020723040001' d union all
--select '1710122600001' d union all
--select '1707278360002' d union all
--select '1710122600001' d union all
--select '18051024600001' d union all
--select '18051518450003' d union all
--select '1705135810001' d union all
--select '19012629660001' d union all
--select '19011414970001' d union all
--select '18051803100003' d union all
--select '1707078500001' d union all
--select '1701084010001' d union all
--select '1708236170001' d union all
--select '17110913960001' d union all
--select '19012223670001' d union all
--select '19032427740001' d union all
--select '18091110260002' d union all
--select '18120610260001' d union all
--select '19071000000009' d union all
--select '1704045340002' d union all
--select '19041907450001' d union all
--select '19070300000137' d union all
--select '17091414280002' d union all
--select '19051526890001' d union all
--select '1703294590002' d union all
--select '19032328460001' d union all
--select '19071800000063' d union all
--select '19053031900001' d union all
--select '18102522160001' d union all
--select '19032421920001' d union all
--select '18061823710005' d union all
--select '19062600000099' d union all
--select '19021625010001' d union all
--select '17100610340001' d union all
--select '19072800000075' d union all
--select '18041420340002' d union all
--select '19090200000206' d union all
--select '1712113760001' d union all
--select '18091927210001' d union all
--select '19052715460001' d union all
--select '19112200001178' d union all
--select '19122610000197' d union all
--select '19081500000141' d union all
--select '19121010000104' d union all
--select '17122713470002' d union all
--select '20011000006673' d union all
--select '17121415400001' d union all
--select '17121115400001' d union all
--select '19082000000140' d union all
--select '20022500012570' d union all
--select '19090900000052' d union all
--select '19112210000172' d union all
--select '20020610000240' d union all
--select '18122923220002' d union all
--select '20022600012884' d union all
--select '19031120090002' d union all
--select '1612204350002' d union all
--select '18062023710001' d union all
--select '18052923710001' d union all
--select '19052425060003' d union all
--select '18100228080001' d union all
--select '19053016350003' d union all
--select '19110910000183' d union all
--select '17111718620001' d union all
--select '18090725970005' d union all
--select '18092522160001' d union all
--select '1705076870001' d union all
--select '1709234300002' d union all
--select '1709134560001' d union all
--select '20022000011947' d union all
--select '19101400000364' d union all
--select '19042905100011' d union all
--select '19090100000083' d union all
--select '19122600005429' d union all
--select '19032523840001' d union all
--select '20011600007189' d union all
--select '19072600000236' d union all
--select '20060510000089' d union all
--select '1710294570002' d union all
--select '19061800000291' d union all
--select '18122805440002' d union all
--select '18071805440001' d union all
--select '20021400011083' d union all
--select '20103100047225' d union all
--select '18062912720001' d union all
--select '19120200002481' d union all
--select '' d union all
--select '19112110000179' d union all
--select '18120402600001' d union all
--select '19081500000135' d union all
--select '19070800000180' d union all
--select '20111000050123' d union all
--select '19053016350003' d union all
--select '19110910000183' d union all
--select '19111110000261' d union all
--select '19041109590001' d union all
--select '18061809590002' d union all
--select '20113000056577' d union all
--select '19072900000156' d union all
--select '20091900034857' d union all
--select '20011010000023' d union all
--select '19071100000060' d union all
--select '19082200000280' d union all
--select '19111110000100' d union all
--select '18072009600003' d union all
--select '20122900066566' d union all
--select '21030300084886' d union all
--select '21062300116683' d union all
--select '18070906330003' d union all
--select '21050100102625' d union all
--select '21042100099610' d union all
--select '21041200096890' d union all
--select '20013110000097' d union all
--select '19082900000223' d union all
--select '20012210000015' d union all
--select '20030410000127' d union all
--select '21070100118466' d union all
--select '21041200096669' d union all
--select '21082400131067' d union all
--select '21052500108878' d union all
--select '19040628130001' d union all
--select '1712085900001' d union all
--select '19060530400001' d union all
--select '21011200069220' d union all
--select '21063000118179' d union all
--select '21041500097874' d union all
--select '21092000137574' d union all
--select '21082500131486' d union all
--select '21051800106907' d union all
--select '20020310000109' d union all
--select '20051300020950' d union all
--select '19041210260002' d union all
--select '18111802820001' d union all
--select '19081900000235' d union all
--select '21092600139201' d union all
--select '20042810000041' d union all
--select '21032600091616' d union all
--select '21061600114631' d union all
--select '21011100069007' d union all
--select '19122700005579' d union all
--select '20020200009500' d union all
--select '20032300016393' d union all
--select '18121027100001' d union all
--select '21093000140267' d union all
--select '22041600343592' d union all
--select '21011900071230' d union all
--select '19122510000238' d union all
--select '19073000000260' d union all
--select '22042100350788' d union all
--select '1705144560001' d union all
--select '21091800137290' d union all
--select '20022710000164' d union all
--select '21011100068906' d union all
--select '21082100130455' d union all
--select '21072900125064' d union all
--select '22022400270959' d union all
--select '20031900015778' d union all
--select '19052425060003' d union all
--select '20090100030418' d union all
--select '21111100151033' d union all
--select '22060100406360' d union all
--select '21101800144884' d union all
--select '21060800112717' d union all
--select '21033000092797' d union all
--select '21062800117679' d union all
--select '1611183860001' d union all
--select '22072400461518' d union all
--select '21113000155638' d union all
--select '21030400085135' d union all
--select '22081500488029' d union all
--select '21080500126671' d union all
--select '21042800101793' d union all
--select '22082600501117' d union all
--select '21111700152322' d union all
--select '21122600177336' d union all
--select '22100700542008' d union all
--select '22082600500715' d union all
--select '19062300000033' d union all
--select '21042700101568' d union all
--select '21052700109559' d --union all
--
--
--select a.*, l.код, d.Number, cs.date, cs.CustomerId  from #shest_smert a
--left join mv_loans l on l.код=a.d
--left join stg._Collection.Deals d on d.Number=a.d
--left join   [Analytics].[dbo].[_collection_CustomerStatus] cs on cs.CustomerId=d.IdCustomer
--	and CustomerState='Смерть подтвержденная' and IsActive=1
--	order by cs.CustomerId 

	drop table if exists #t2

	select a.[Дата выдачи месяц], a.[Дата выдачи день], a.код, a.isInstallment
	, b.[Дата смерти]
	, b1.[остаток од] [остаток од на дату смерти]
	, b2.[остаток од] [остаток од на сегодня]
	into #t2
	from mv_loans a
	left join #t1 b on a.[id клиента Спейс]=b.CustomerId
	left join v_balance b1 on b1.Код=a.код and cast(b.[Дата смерти] as date)=b1.d
	left join v_balance b2 on b2.Код=a.код and cast(getdate() as date)=b2.d  and cast(b.[Дата смерти] as date) is not null
	order by 2


	drop table if exists [dbo].[_collection_отчет_Умершие]
	select * into [dbo].[_collection_отчет_Умершие]
	from #t2

	
	drop table if exists #t3

	select a.ДеньПлатежа, a.Код, c.[Дата смерти], a.Сумма 
	into #t3
	from mv_repayments a
	join mv_loans b on a.Код=b.код
	join #t1 c on b.[id клиента Спейс]=c.[CustomerId] and a.Дата>=c.[Дата смерти]

	
	drop table if exists [dbo].[_collection_отчет_Умершие_платежи]
	select * into [dbo].[_collection_отчет_Умершие_платежи]
	from #t3


	drop table if exists #t4

    select b.[Дата смерти], b.[Дата статуса Смерть подтвержденная], l.[Дата погашения] , case when bankr.CustomerId is not null then 1 else 0 end as [Банкрот],a.*
	into #t4
	from [dbo].[_collection_deal_isk_sp_il_ip] a
	join #t1 b on a.[IdCustomer]=b.[CustomerId] --and b.[Дата смерти] is not null
	left join #bunkruptcy_confirmed bankr on bankr.CustomerId = a.IdCustomer
	join mv_loans l on l.код=a.Number --and (l.[Дата погашения] is null or l.[Дата погашения]<b.[Дата смерти])
	
	drop table if exists [dbo].[_collection_отчет_Умершие_воронка]
	select * into [dbo].[_collection_отчет_Умершие_воронка]
	from #t4

--select * from #t4
--where Банкрот=0

	end
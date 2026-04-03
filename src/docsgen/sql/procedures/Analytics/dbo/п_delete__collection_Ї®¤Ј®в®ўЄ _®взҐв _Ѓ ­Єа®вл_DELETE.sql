CREATE proc  [dbo].[_collection_подготовка_отчета_Банкроты]
as

begin



	drop table if exists #t1
	
  select x.CRMClientGUID
  , case when [Признак банкрот подтвержденный]=1 then [Дата банкрот неподтвержденный]  
         when [Признак банкрот подтвержденный]=0 and [Признак банкрот неподтвержденный]=1 then [Дата банкрот неподтвержденный] end [Дата банкрот неподтвержденный] 
  , case when [Признак банкрот подтвержденный]=1 then [Дата банкрот подтвержденный] end [Дата банкрот подтвержденный] 
  , case when [Признак банкрот подтвержденный]=1 or  [Признак банкрот неподтвержденный] =1 then [Дата заявления] end [Дата заявления] 
  
  into #t1
  from (
  select CRMClientGUID CRMClientGUID
  ,min(case when customerstate in ('Банкрот неподтверждённый' ) then BankruptcyFilingDate end ) [Дата банкрот неподтвержденный]
  ,min(case when customerstate in ('Банкрот подтверждённый' ) then DateResultOfCourtsDecisionBankrupt end )   [Дата банкрот подтвержденный]
  ,min(case when customerstate in ('Банкрот подтверждённый', 'Банкрот неподтверждённый' ) then isnull(BankruptConfirmed_BankruptcyFilingDate , BankruptcyFilingDate) end )   [Дата заявления]
  ,min(case when customerstate in ('Банкрот неподтверждённый' ) then  case when BankruptcyFilingDate is not null then cast(IsActive as int)  end end ) [Признак банкрот неподтвержденный]
  ,min(case when customerstate in ('Банкрот подтверждённый' )   then case when DateResultOfCourtsDecisionBankrupt is not null then cast(IsActive as int) end  end ) [Признак банкрот подтвержденный]

    FROM [Analytics].[dbo].[_collection_CustomerStatus] a
 	join mv_loans b on a.[CustomerId]=b.[id клиента Спейс]
	group by CRMClientGUID
	) x



		drop table if exists [dbo].[_collection_отчет_Банкроты]

	---select *
	---  FROM [Analytics].[dbo].[_collection_CustomerStatus] a
	---  where customerstate in ('Банкрот неподтверждённый' ) and IsActive=1

	    select  [Дата выдачи месяц]
	    ,       [Дата банкрот подтвержденный]
	    ,       [Дата банкрот неподтвержденный]
		,       datediff(month, [Дата выдачи месяц],  cast(format(b.[Дата банкрот подтвержденный]	, 'yyyy-MM-01')  as date)) Месяцев
	    ,       ROW_NUMBER() over(partition by a.CRMClientGUID order by [Дата выдачи] desc) rn_desc
	    ,       ROW_NUMBER() over(partition by a.CRMClientGUID order by [Дата выдачи] ) rn 
		,       cast(format(b.[Дата заявления]	, 'yyyy-MM-01')  as date) [Дата заявления месяц]
		,       cast(format(b.[Дата банкрот подтвержденный]	, 'yyyy-MM-01')  as date)     [Дата банкрот подтвержденный месяц]
		,       cast(format(b.[Дата банкрот неподтвержденный]	, 'yyyy-MM-01')  as date) [Дата банкрот неподтвержденный месяц]
		,       код
		,       a.CRMClientGUID
		,       r.Region
		into [dbo].[_collection_отчет_Банкроты]
	from mv_loans a
	left join #t1 b on a.CRMClientGUID=b.CRMClientGUID
	left join  [Stg].[_Collection].[registration] r on r.IdCustomer=a.[id клиента Спейс]




	return


	--select [Дата выдачи месяц], [Дата банкрот подтвержденный]
	--,dbo.FullMonthsSeparation( [Дата выдачи месяц],  cast(format(b.[Дата банкрот подтвержденный]	, 'yyyy-MM-01')  as date)) Мес
	--,datediff(month, [Дата выдачи месяц],  cast(format(b.[Дата банкрот подтвержденный]	, 'yyyy-MM-01')  as date)) МесДиф
	--
	--, ROW_NUMBER() over(partition by [id клиента Спейс] order by [Дата выдачи месяц] desc) rn
	--from mv_loans a
	--join #t1 b on a.[id клиента Спейс]=b.CustomerId and [Дата банкрот подтвержденный] is not null
	--where [Вид займа]='Первичный'

	--select * from #t1
	--where [Дата банкрот подтвержденный]
	--

	--select * from 
	--[Analytics].[dbo].[_collection_CustomerStatus] a
	--where  customerstate = 'Банкрот подтверждённый'  and IsActive=1 and DateResultOfCourtsDecisionBankrupt is null
	--
	--
	--
	--select * from 
	--[Analytics].[dbo].[_collection_CustomerStatus] a
	--where  customerstate = 'Банкрот неподтверждённый'  and IsActive=1 and BankruptcyFilingDate is null

	--drop table if exists #t2
	--
	--
	--
	--
	--select a.[Дата выдачи месяц], a.[Дата выдачи день]
	--, a.код
	--,  a.[Вид займа] 
	--, a.isInstallment
	--, a.CRMClientGUID
	--, b.[Дата банкрот неподтвержденный]
	--, b.[Дата банкрот подтвержденный]
	--, cast(format(b.[Дата банкрот неподтвержденный] , 'yyyy-MM-01') as date) [Дата банкрот неподтвержденный месяц]
	--, cast(format(b.[Дата банкрот подтвержденный]	, 'yyyy-MM-01')  as date)  [Дата банкрот подтвержденный месяц]
	--, datediff(month, a.[Дата выдачи месяц],b.[Дата банкрот подтвержденный] ) [Месяцев до подтвержденного банкротства]
	----, b1.[остаток од] [остаток од на дату подтверждения банкротства]
	--, r.Region [Регион регистрации]
	--into #t2
	--from mv_loans a
	--left join #t1 b on a.CRMClientGUID=b.CRMClientGUID
	--left join  [Stg].[_Collection].[registration] r on r.IdCustomer=a.[id клиента Спейс]
	--left join ( v_balance b1 on b1.Код=a.код and cast(b.[Дата банкрот подтвержденный] as date)=b1.d
	--where a.[Вид займа]='Первичный'
	--order by 2

	drop table if exists #t3
	select    b.CRMClientGUID,  sum([остаток од]) [остаток од] into #t3
	from v_balance a join #t2 b on a.Код=b.код and a.d=cast(b.[Дата банкрот подтвержденный] as date)
	group by   b.CRMClientGUID


	drop table if exists #t3_today
	select    b.CRMClientGUID,  sum([остаток од]) [остаток од] into #t3_today
	from v_balance a join #t2 b on a.Код=b.код and a.d=cast(getdate() as date) and cast(b.[Дата банкрот подтвержденный] as date) is not null
	group by   b.CRMClientGUID

	drop table if exists #t4
	select a.*
	, b.[остаток од] [остаток од на дату подтверждения банкротства]
	, b_1.[остаток од] [остаток од на сегодня]
	
	into #t4
	from #t2 a
	left join #t3 b on a.CRMClientGUID=b.CRMClientGUID
	left join #t3_today b_1 on a.CRMClientGUID=b_1.CRMClientGUID
	where a.[Вид займа]='Первичный'

	drop table if exists [dbo].[_collection_отчет_Банкроты]
	select * into [dbo].[_collection_отчет_Банкроты]
	from #t4


	select * from #t4
where [остаток од на дату подтверждения банкротства]>0 and [Дата банкрот подтвержденный] is null
	end
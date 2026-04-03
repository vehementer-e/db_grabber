

CREATE PROCEDURE [finAnalytics].[reportNMA_NU]
	@repmonth date
AS
BEGIN
	
	--declare @repmonth date=dateadd(month,-1,eomonth(getdate()))
	--set @repmonth='2025-08-31'	
	--declare @repmonth date='2025-11-30'	
	
	

	--declare @repmonth date='2026-01-31'
	drop table if exists #NMA
	select
		*
	into #NMA
	from [dwh2].[finAnalytics].[NMAOS]
	--[dwh2].[finAnalytics].[NMAOStmp]
	
	--костыль чтобы выровнится с таблицой расчета аммортизации НУ с бухгалтерией по НМА 60901810000000000006 
	delete #NMA where repdate='2025-01-31' and account='60901810000000000006'
	update #NMA
	set 
	repdate=iif(repdate='2024-10-31','2025-01-31',repdate)
	--,accumAmo_NU=iif(repdate='2024-10-31',15252983.7025,accumAmo_NU)
	,dateBeginAmo_NU='2020-01-09'
	where account='60901810000000000006'
	-------------------

	--формируем таблицу аммортизационных отчислений в месяц по НМА удаляем нулевые
	drop table if exists #summAmoMonth_NU
	select
		distinct
		account
		,summAmoMonth_NU=first_value(summAmoMonth_NU)over(partition by account,year(repdate) order by repdate desc)
	into #summAmoMonth_NU
	from #NMA
	where summAmoMonth_NU>0
	and year(repdate)=year(@repmonth)

	declare @predRepYear date =datefromparts(year(@repmonth)-1,'12','31') --предыдущий год отчетному
	
	--таблица месяцов оставшихся до конца года
	declare @i date=@repmonth 
	drop table if exists #dopMonth
	create table #dopMonth (repmonth date)
	while @i<datefromparts(year(@repmonth),'12','31')
		begin 
			set @i=eomonth(dateadd(month,1,@i))
			insert into #dopMonth (repmonth)
				values (@i)

		end

	--таблица НМА у которых остаток по счету 60901 равен 60903 на начало года
	;with cte_noTargetAccount as (
	--declare @repmonth date='2025-11-30'
	select
	 repMonth=eomonth(a.repMonth)
	 ,account=a.accNum
	from dwh2.finAnalytics.osv_monthly a
	inner join dwh2.finAnalytics.osv_monthly b on a.subconto1UID=b.subconto1UID and a.repMonth=b.repMonth
	--substring(a.accNum,7,20)=substring(b.accNum,7,20) and a.repMonth=b.repMonth
					and b.acc2order='60903'
	where a.acc2order='60901'
	and b.repMonth is not null
	and eomonth(a.repmonth)<@repmonth
	and (month(a.repmonth)=12 and  day(a.repMonth)=1)
	and isnull(a.restOUT_NU,0)=abs(isnull(b.restOUT_NU,0))

	)

	select 
	      l1.[Месяц]
		  ,l1.[Номер]
		  ,l1.[Счет]
		  ,l1.[НМА]
		  ,l1.[Первоначальная стоимость]
		  ,l1.[Дата ввода в эксплуатацию]
		  ,l1.[СПИ]
		  ,l1.[Амортизации (месяц)]
		  ,l1.[Сумма амортизации (месяц)]
		  ,l1.[Норма амортизации]
		  --------
		  ,l1.[Кол-во месяцев начислений в текущем году]
		  ,l1.[Сумма в текущем году]
		  ---------
		  ,l1.[Кол-во месяцев начислений на начало года]
		  ,l1.[Накопленная амортизация на начало года]
		  ,l1.[Остаточная стоимость на начало года]
		  -------
		  ,l1.[Кол-во месяцев начислений осталось]
												
		  ---------
		  ,l1.[Кол-во месяцев начислений на конец года]
		  ,l1.[Накопленная амортизация на конец года]
		  ,l1.[Остаточная стоимость на конец года]
		  ,l1.[Комментарий]
		
	from (
	select 
		  [Месяц]=a.repdate
		  ,a.account	
		  ,[Счет]=concat('60901-',iif(a.n_account=245245,245,a.n_account))
		  ,[Номер]=iif(a.n_account=245245,245,a.n_account)--костыль
		  ,[НМА]=a.nameAccount
		  ,[Первоначальная стоимость]=a.firstPrice_NU
		  ,[Дата ввода в эксплуатацию]=a.dateBeginAmo_NU
		  ,[СПИ]=a.spiMonth_NU
		  ,[Амортизации (месяц)]=a.firstPrice_NU/a.spiMonth_NU
		  --b.summAmoMonth_NU/*first_value(a.[summAmoMonth_NU])over(partition by a.account,year(a.repdate) order by a.repdate desc)*/
		  ,[Сумма амортизации (месяц)]=a.[summAmoMonth_NU]
		  ,[Норма амортизации]=a.normAmo_NU
		  --------
		  ,[Кол-во месяцев начислений в текущем году]=count(nullif(a.summAmoMonth_NU,0)) over(partition by a.account,year(a.repdate))
		  ,[Сумма в текущем году]=sum(a.summAmoMonth_NU) over(partition by a.account,year(a.repdate))
		  ---------
		  ,[Кол-во месяцев начислений на начало года]=iif(a.dateBeginAmo_NU>@predRepYear,0, datediff(month,a.dateBeginAmo_NU,datefromparts(year(a.repdate)-1,'12','31')))
		  ,[Накопленная амортизация на начало года]=first_value(a.accumAmo_NU-a.summAmoMonth_NU) over(partition by a.account,year(a.repdate) order by a.repdate)
		  ,[Остаточная стоимость на начало года]=first_value(a.resPrice_NU+a.summAmoMonth_NU) over(partition by a.account,year(a.repdate) order by a.repdate)
		  -------
		  ,[Кол-во месяцев начислений осталось]=a.spiMonth_NU
													-count(nullif(a.summAmoMonth_NU,0)) over(partition by a.account,year(a.repdate))
													-iif(a.dateBeginAmo_NU>@predRepYear,0, datediff(month,a.dateBeginAmo_NU,datefromparts(year(a.repdate)-1,'12','31')))
		  ---------
		  ,[Кол-во месяцев начислений на конец года]=count(nullif(a.summAmoMonth_NU,0)) over(partition by a.account,year(a.repdate))
													+iif(a.dateBeginAmo_NU>@predRepYear,0, datediff(month,a.dateBeginAmo_NU,datefromparts(year(a.repdate)-1,'12','31')))
												
		  ,[Накопленная амортизация на конец года]=	sum(a.summAmoMonth_NU) over(partition by a.account,year(a.repdate))
													+first_value(a.accumAmo_NU-a.summAmoMonth_NU) over(partition by a.account,year(a.repdate) order by a.repdate)
		  ,[Остаточная стоимость на конец года]=a.firstPrice_NU
												-sum(a.summAmoMonth_NU) over(partition by a.account,year(a.repdate))
												-first_value(a.accumAmo_NU-a.summAmoMonth_NU) over(partition by a.account,year(a.repdate) order by a.repdate)
		  ,[Комментарий]=a.comment
      
	  from /*[dwh2].[finAnalytics].[NMAOS]*/ #NMA a
	  left join #summAmoMonth_NU b on a.account=b.account
	  where a.typeRes='НМА' 
		and 
		(a.firstPrice_NU>100000.00 -- ограничение по стоимости начальной НМА
			or
			a.n_Account in --исключения
			('1','4','30','34','45','46','48','49','50','53','54','55','57','60','61','62','64','79','85','87','88','89','98','103'
			,'111','112','117','128','129','130','131','132','133','134','135','136','137','147','148','149','150','151','152','153'
			,'154','155','156','157','158','159','160','168','170','175','176','181','182','183','184','185','186','187','188','189'
			,'190','196','199','245','253','198',
			'245245')--костыль
		)
		and a.repdate<=@repmonth --данные только на отчетную дату
		and a.n_Account!=245--костыль
		) l1
	left join cte_noTargetAccount b on l1.Account=b.account --исключаем НМА у которых на начало года стоимость равна накоплению амортизации (прошла аммортизация)
	where year(l1.Месяц)=year(@repmonth)--выбирем только данные по месяцам в отчетном годе
	and b.account is null --исключаем по которым прошла амортизация 
	and [Остаточная стоимость на начало года]!=0
	union all
	select 
		[Месяц]=repmonth
		,[Номер]=9999
		,[Счет]=''
		,[НМА]=''
		,[Первоначальная стоимость]=null
		,[Дата ввода в эксплуатацию]=null
		,[СПИ]=null
		,[Амортизации (месяц)]=null
		,[Сумма амортизации (месяц)]=null
		,[Норма амортизации]=null
		,[Кол-во месяцев начислений в текущем году]=null
		,[Сумма в текущем году]=null
		,[Кол-во месяцев начислений на начало года]=null
		,[Накопленная амортизация на начало года]=null
		,[Остаточная стоимость на начало года]=null
	    ,[Кол-во месяцев начислений осталось]=null
		,[Кол-во месяцев начислений на конец года]=null
		,[Накопленная амортизация на конец года]=null
		,[Остаточная стоимость на конец года]=null
		,[Комментарий]=''
	from #dopMonth
	order by l1.Номер,l1.Месяц	
END

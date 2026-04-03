


CREATE PROCEDURE [finAnalytics].[reportNMA_BU]
	@repmonth date
AS
BEGIN
	/*по НМА 60901810000000000248 нестандартное построение амортизационных отчислений
		1. Не берем во внимание первоначальную стоимость равную 14800000 
		2. Амортизационные отчисления формируем 2025 году по каждой доработке отдельно
		3. Амортизационные отчисления формируем 2026 году также ведем отдельно
		4. Амортизационные отчисления в послед года уже по общему правилу
	*/
	--declare @repmonth date='2026-02-28'
	declare @startYear int =2025
	
	drop table if exists #NMA
	select
		*
	into #NMA
	from [dwh2].[finAnalytics].[NMAOS]
	where (agent like '%ГОРИЗОНТ%')
	and typeRes='НМА'


	--признак измениея первоначальной стоимости
	drop table if exists #chgFirstPrice
	create table #chgFirstPrice (id int identity(1,1),dat date,ch varchar(20),firstPrice float,chgFirstPrice nvarchar(5),totalFirstPrice float)
	;with tmp_chgFirstPrice as(
	select
		dat=iif (first_value(dat) over(partition by ch order by dat)=dat,dateadd(day,1,dat),dat)
		,ch
		,firstPrice
		,chgFirstPrice=iif (first_value(dat) over(partition by ch order by dat)!=dat
								or ch='60901810000000000248' --дополнительное усмловия из ТЗ
								,'Да','Нет')
		,totalFirstPrice=sum(firstPrice)over(partition by ch order by dat)

	from dwh2.finAnalytics.spr_NMA_changeFirstPrice
	--доп условия из ТЗ
	where not (ch='60901810000000000248' and firstPrice=14800000)
	)
	insert into #chgFirstPrice(dat,ch,firstPrice,chgFirstPrice,totalFirstPrice)
	
		select 
			dat
			,ch
			,firstPrice
			,chgFirstPrice
			,totalFirstPrice
		from (
			select 
				*
				,rn=row_number()over(partition by ch order by dat desc)
			from tmp_chgFirstPrice
			where year(dat)<=@startYear-1
			)l1
		where l1.rn=1
		union all
			select 
			dat
			,ch
			,firstPrice
			,chgFirstPrice
			,totalFirstPrice
		from tmp_chgFirstPrice
		where year(dat)>@startYear-1
	
	-- хард код данные по измененным параметрам НМА по ТЗ для отчета

	drop table if exists #changeParamAmoNma
	create table #changeParamAmoNma (dat date,ch varchar(20),spi int, firstPrice float,chgFirstPrice nvarchar(5),totalFirstPrice float)
	insert into #changeParamAmoNma (dat,ch,spi,firstPrice,chgFirstPrice,totalFirstPrice)
		values 
			('2024-10-01','60901810000000000228',3288,10200000.00,'Да',10200000.00),
			('2024-10-01','60901810000000000226',3288,3000000.00,'Да',3000000.00),
			('2024-10-01','60901810000000000231',3318,10800000.00,'Да',10800000.00),
			('2024-12-27','60901810000000000235',3261,10000000.00,'Да',10000000.00)
	merge #chgFirstPrice as trg
	using #changeParamAmoNma as src
		on trg.ch=src.ch
		when matched then update set trg.dat=src.dat
									 ,trg.firstPrice=src.firstPrice
									 ,trg.chgFirstPrice=src.chgFirstPrice
									 ,trg.totalFirstPrice=src.totalFirstPrice;	
	merge #NMA as trg
	using #changeParamAmoNma as src
		on trg.account=src.ch
		when matched then update set trg.spiDay_Bu=src.spi;
								
  	drop table if exists #workNMA
	--таблица НМА у которых остаток по счету 60901 равен 60903 на начало года
	;with cte_noTargetAccount as (

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
		 id_account=chg.id
		 ,repmonth=a.repdate
		 ,account=a.account
		 ,n_account=a.n_account
		 ,chgFirstPrice=chg.chgFirstPrice
		 ,nameAccount=a.nameAccount
		 ,dateInBal=chg.dat
		 ,dateEndAmo_BU=a.dateEndAmo_BU
		 ,firstPrice=chg.firstPrice
		 ,totalFirstPrice=chg.totalFirstPrice
		 ,spiDay=a.spiDay_BU
	into #workNMA
	from #chgFirstPrice chg
	left join #NMA a on chg.ch=a.Account
	left join cte_noTargetAccount b on a.Account=b.account --исключаем НМА у которых на начало года стоимость равна накоплению амортизации (прошла аммортизация)
	where year(a.repdate)>=@startYear
		and	a.repdate<=@repmonth --данные только на отчетную дату
		and resPrice_BU!=0
		and b.account is null

	drop table if exists #amo
	select
		*
		,countAllDay=sum(l2.countDayForAmoMonth)over(partition by l2.n_account order by l2.dateInBal,l2.repmonth)
		,amoInMonth=iif(l2.account='60901810000000000248' and year(l2.repmonth)<=@startYear+1
						,l2.FirstPrice/l2.ostSpiDay*day(l2.repmonth)--допусловие по ТЗ
						,l2.totalFirstPrice/l2.ostSpiDay*l2.countDayForAmoMonth) --стандартное услояие ТЗ
	into #amo
	from ( 
		select
			*
			,countDayForAmoMonth=iif(l1.dateInBal=isnull(lead(l1.dateInBal)over (partition by l1.n_account order by l1.dateInBal,l1.repmonth),l1.dateInBal)
						,l1.countDay
						,l1.countDay-isnull(lead(l1.countDay)over (partition by l1.n_account order by l1.dateInBal,l1.repmonth),0)
						)
		from (
			select
			 *
			--расчет кол-во дней спи  
			,ostSpiDay=datediff(day,dateInBal,dateEndAmo_BU)+2
			--флаг отвечает за - отражения или нет по аммортизации за месяц для НМА и ее доработок
			,k=iif(year(repmonth)=year(dateInBal)--
						,1
						,iif (dateInBal=first_value(dateInBal)over(partition by n_account order by dateInBal desc)
							
								--условия для сохрание начисление аморт в новом году только последнего измениния цены
									,1
								
									,iif (dateInBal=first_value(dateInBal)over(partition by n_account order by dateInBal)
											and year(repmonth)=@startYear
										,1
										--допусловие по ТЗ
										,iif(account='60901810000000000248' and year(repmonth)=@startYear+1
											,1
											,0)
										  )
							  )
				   )
			,countDay=iif(year(dateInBal)=year(repmonth) and month(dateInBal)=month(repmonth)
									,day(repmonth)-day(dateInBal)+1 --кол-во дней аммортизации в первый месяц 
									,day(repmonth)-- кол-во дней аммортизации в последующие месяцы
						)
			from #workNMA
			where repmonth>=dateInBal) l1
		where l1.k=1
			/*and n_account=259*/) l2

	--declare @startYear int=2025

	select
		id=a.id_account
		,[Счет]=concat('60901-',a.n_account)
		,[Признак доработки]=a.chgFirstPrice
		,[Наименование НМА]=a.nameAccount
		,[Дата принятия на баланс доработки]=a.dateInBal
		,[Дата списания НМА]=a.dateEndAmo_BU
		,[Стоймость НМА в КМ]=a.firstPrice
	/* ,correct=iif(dateInBal=isnull(first_value(dateInBal)over (partition by n_account order by dateInBal,repmonth),dateInBal)
				--допусловие по ТЗ
				or (account='60901810000000000248' and year(repmonth)<=@startYear+1)
				,0
				,(select sum(b.amoInMonth) from #amo b where b.repmonth<a.dateInBal )/ostSpiDay*countDayForAmoMonth 
				)*/
		,[Месяц]=a.repmonth
		,[Амортизация в месяц]=a.amoInMonth-iif(a.dateInBal=isnull(first_value(a.dateInBal)over (partition by a.n_account order by a.dateInBal,a.repmonth),a.dateInBal)
										--допусловие по ТЗ
										or (a.account='60901810000000000248' and year(a.repmonth)<=@startYear+1)
										,0
										,(select sum(b.amoInMonth) from #amo b where b.repmonth<a.dateInBal and b.n_account=a.n_account)/ostSpiDay*countDayForAmoMonth 
									)

	from #amo a
	
	
END



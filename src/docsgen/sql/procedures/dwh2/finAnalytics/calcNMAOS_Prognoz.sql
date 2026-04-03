
CREATE PROC [finAnalytics].[calcNMAOS_Prognoz] 
		@repmonth date
	
AS
BEGIN
	--declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--declare @subjectHeader  nvarchar(250) ='Прогноз НМА и ОС', @subject nvarchar(250)
	--declare @msgHeader nvarchar(max)=concat('Построен прогноз по НМА и ОС: ',FORMAT(getdate(), 'MMMM yyyy', 'ru-RU' ),char(10))
	--declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	--declare @message nvarchar(max)=''

--declare  @repmonth date ='2025-08-31'
declare @predRepYear date =datefromparts(year(@repmonth)-1,'12','31')
declare @maxDate date =(select eomonth(max(isnull(dateEndAmo_BU,'1900-01-01'))) from dwh2.finAnalytics.NMAOS)
--таблица список НМА или ОС со списком дата всег сделаных погашений 
drop table if exists #listNmaOS
select 
	a.repdate
	 ,a.typeRes
	,a.Account
	,a.n_Account
	,a.nameAccount
	,a.amAccount
	,a.n_AmAccount
	,a.nameAmAccount
	,a.dateBeginAmo_BU
	,a.spiDay_BU
	,a.dateEndAmo_BU
	,a.firstPrice_BU
	,a.agent
	,a.comment
	,a.spiMonth_NU
into #listNmaOS 
from dwh2.finAnalytics.NMAOS a
--исключаем в соответвии с остатками
inner join (select accNum,repmonth from OSV_MONTHLY where acc2order in ('60401','60901')and eomonth(repMonth)=@repmonth) b on a.Account=b.accNum
where dateBeginAmo_BU<=@repmonth and repdate<=@repmonth	

--формируем шапку НМА или ОС дополняем полями Осталочь дней расчет, Аммортизация за 1 день, Контроль
--declare  @repmonth date ='2025-11-30'
--	declare @predRepYear date =datefromparts(year(@repmonth)-1,'12','31')
drop table if exists #Shapka
select 
		[ОС, НМА]=l1.[ОС, НМА]
		,[Счет учета перв.ст]=l1.[Счет учета перв.ст]
		,[Номер счета]=l1.[Номер счета]
		,[Название счета учета перв.ст]=l1.[Название счета учета перв.ст]
		,[Счет учета накопл.аморт]=l1.[Счет учета накопл.аморт]
		,[Номер счета Ам]=l1.[Номер счета Ам]
		,[Название счета учета накопл.аморт]=l1.[Название счета учета накопл.аморт]
		,[Дата начала амортизации]=l1.[Дата начала амортизации]
		,[СПИ, дней (БУ)]=l1.[СПИ, дней (БУ)]
		,[Дата окончания амортизации]=l1.[Дата окончания амортизации]
		,[Контрагент]=l1.[Контрагент]
		,[Комментарий]=l1.[Комментарий]
		,[СПИ, месяцев (НУ)]=l1.[СПИ, месяцев (НУ)]
		,[Первоначальная стоимость на начало года]=l1.[Первоначальная стоимость на начало года]
		,[Накопленная амортизация на начало года]=l1.[Накопленная амортизация на начало года]
		,[Остаточная стоимость на начало года]=l1.[Остаточная стоимость на начало года]
		,[Первоначальная стоимость на дату]=l1.[Первоначальная стоимость на дату]
		,[Амортизация за период]=l1.[Амортизация за период]
		,[Накопленная амортизация на дату]=l1.[Накопленная амортизация на дату]
		,[Остаточная стоимость на дату]=l1.[Остаточная стоимость на дату]
		,[Оставшийся срок, дней, на дату]=l1.[Оставшийся срок, дней, на дату]
		,[Контроль]=l1.[Амортизация за 1 день]*day(@repmonth)-l1.[Амортизация за период]
		,[Амортизация за 1 день]=l1.[Амортизация за 1 день]
		,[Оставшийся срок, дн. Расчетный]=iif([Остаточная стоимость на дату]!=0--[Остаточная стоимость на начало года]!=0
												,round([СПИ, дней (БУ)]
												+day(@repmonth)
												- isnull([Накопленная амортизация на дату]/nullif([Амортизация за 1 день],0),0)
												,0)
											 ,0)
	into #Shapka
from (
	--declare  @repmonth date ='2025-09-30'
	--declare @predRepYear date =datefromparts(year(@repmonth)-1,'12','31')
	select
		distinct
		 [ОС, НМА]=ls.typeRes
		,[Счет учета перв.ст]=ls.Account
		,[Номер счета]=ls.n_Account
		,[Название счета учета перв.ст]=ls.nameAccount
		,[Счет учета накопл.аморт]=ls.amAccount
		,[Номер счета Ам]=ls.n_AmAccount
		,[Название счета учета накопл.аморт]=ls.nameAmAccount
		,[Дата начала амортизации]=ls.dateBeginAmo_BU
		,[СПИ, дней (БУ)]=ls.spiDay_BU
		,[Дата окончания амортизации]=ls.dateEndAmo_BU
		,[Контрагент]=ls.agent
		,[Комментарий]=ls.comment
		,[СПИ, месяцев (НУ)]=ls.spiMonth_NU
		,[Первоначальная стоимость на начало года]=ls.firstPrice_BU
		,[Накопленная амортизация на начало года]=isnull(a.accumAmo_BU,0)
		,[Остаточная стоимость на начало года]=isnull(a.resPrice_BU,0)
		,[Первоначальная стоимость на дату]=isnull(ls.firstPrice_BU,0) --!!!первоначальная стоимость не измена поэтому можем взять стоимость на начло года
		,[Амортизация за период]=isnull(b.summAmoMonth_BU,0)
		,[Накопленная амортизация на дату]=isnull(b.accumAmo_BU,0)
		,[Остаточная стоимость на дату]=isnull(b.resPrice_BU,0)
		,[Оставшийся срок, дней, на дату]=iif(datediff(day,@repmonth,ls.dateEndAmo_BU)<0,0,datediff(day,@repmonth,ls.dateEndAmo_BU))
		,[Контроль]=isnull(round(b.firstPrice_BU/nullif(ls.spiDay_BU,0)*day(@repmonth)-b.summAmoMonth,0),0)
		,[Амортизация за 1 день]=iif (isnull(round(b.firstPrice_BU/nullif(ls.spiDay_BU,0)*day(@repmonth)-b.summAmoMonth,0),0)=0--если контроль не равен нулю то другой способ расчета 
									,isnull(b.firstPrice_BU/nullif(ls.spiDay_BU,0),0)
									,isnull(b.summAmoMonth/day(@repmonth),0)
									)
		,b.summAmoMonth
		,b.summAmoMonth_BU
	from #listNmaOS ls
	left join (select * from  dwh2.finAnalytics.NMAOS where repdate=@predRepYear) a on ls.account=a.account 
	left join 
			(select
				--для НМА которые приняты в том же месяце что и отчетный и у которых закончился период амортизации
				--summAmoMonth=iif(summAmoMonth_BU!=0,summAmoMonth_BU,firstPrice_BU/spiDay_BU*day(@repmonth))
				summAmoMonth=iif(eomonth(dateBeginAmo_BU)=@repmonth or eomonth(dateEndAmo_BU)<@repmonth ,firstPrice_BU/spiDay_BU*day(@repmonth),summAmoMonth_BU)
				,*
			from dwh2.finAnalytics.NMAOS) b on ls.Account=b.Account and b.repdate=@repmonth
	--29 01 26
	where ls.repdate=@repmonth
	)l1
--select * from #Shapka	
--select * from #60901810000000000006
---------
--формируем таблицу счетов и дат окончания сроков амортизации с учетом расчетного кол-во оставшихся дней
drop table if exists #spNamOs_dateCalcEndAmo
select
	distinct 
	account=a.account
	,dateCalcEndAmo=dateadd(day,b.[Оставшийся срок, дн. Расчетный],@repmonth)
into #spNamOs_dateCalcEndAmo
from #listNmaOS a
left join #Shapka b on a.account=b.[Счет учета перв.ст] 
------------
--таблица дат будующих погашений амортизации для всех НМА и ОС до конца всего срока аммортизации начиная с отчетной даты  @repmonth

drop table if exists #list_dateAmo
create table #list_dateAmo (account varchar(20),amoDate date,countDay int)
declare @i date =@repmonth
while @i<@maxDate
	begin 
		set @i = eomonth(dateadd(month,1,@i))
		insert into #list_dateAmo (account,amoDate,countDay)
				select 
					account=account

					,amoDate=@i
					,ostCountDay=day(@i)
				from #spNamOs_dateCalcEndAmo
				where eomonth(dateCalcEndAmo)>=@i
	end

--таблица содержит будующий график погашения амортизации и нарастающий итог количества дней с отчетной даты  @repmonth
drop table if exists #amoDate
create table #amoDate(account varchar(20),amoDate date,amoCountDay int)
insert into #amoDate (account,amoDate,amoCountDay)

	select 
		a.account
		--300126 1701
		,isnull(b.amoDate,eomonth(dateadd(month,1,@repmonth)))
		,sum(isnull(b.countDay,0))over(partition by b.account order by b.amoDate rows unbounded preceding)
	from #spNamOs_dateCalcEndAmo a
	left join #list_dateAmo b on a.Account=b.account

	order by a.account


-----


 --begin try	
 -- begin tran 
	--truncate table dwh2.finAnalytics.NMAOS_Prognoz
	---insert into dwh2.finAnalytics.NMAOS_Prognoz (repdate, typeRes, Account, n_Account, nameAccount, amAccount, n_AmAccount, nameAmAccount, dateBeginAmo
	--											, spiDay, dateEndAmo, agent, commet, spiMonthNu, firstPriceBeginYear, accumAmoBeginYear, resPriceBeginYear
	--											, firstPriceDate, summAmo_Date, accumAmo_Date, resPrice_Date
	--											, countDayOst_Date, countDayOst_Date_Calc, summAmo_Day, summAmo_Month, check1, check2)

--declare  @repmonth date ='2025-08-31'
--drop table if exists #tt
	select 
			l2.[Отчетный месяц]
			,l2.[ОС, НМА]
			,l2.[Счет учета перв.ст]
			,l2.[Номер счета]
			,l2.[Название счета учета перв.ст]
			,l2.[Счет учета накопл.аморт]
			,l2.[Номер счета Ам]
			,l2.[Название счета учета накопл.аморт]
			,l2.[Дата начала амортизации]
			,l2.[СПИ, дней (БУ)]
			,l2.[Дата окончания амортизации]
			,l2.[Контрагент]
			,l2.[Комментарий]
			,l2.[СПИ, месяцев (НУ)]
			,l2.[Первоначальная стоимость на начало года]
			,l2.[Накопленная амортизация на начало года]
			,l2.[Остаточная стоимость на начало года]
			,l2.[Первоначальная стоимость на дату]
			,l2.[Амортизация за период]
			,l2.[Накопленная амортизация на дату]
			,l2.[Остаточная стоимость на дату]
			,l2.[Оставшийся срок, дней, на дату]
			,l2.[Оставшийся срок, дн. Расчетный]
			,l2.[Амортизация за 1 день]
			,l2.[Амортизация за месяц]
			,l2.[Контроль]
			--ставим ноль если начисления аммортизации уже закончились
			,[Контроль остаточной стоимости]=iif (l2.[Оставшийся срок, дн. Расчетный]!=0
						,round(l2.[Остаточная стоимость на дату]-sum(isnull(l2.[Амортизация за месяц],0)) over (partition by l2.[Название счета учета перв.ст]),0)
						,0)
	--into #tt
	
	from (
	--	declare  @repmonth date ='2025-08-31'
		select 
			[Отчетный месяц]=l1.amoDate
			,l1.[ОС, НМА]
			,l1.[Счет учета перв.ст]
			,l1.[Номер счета]
			,l1.[Название счета учета перв.ст]
			,l1.[Счет учета накопл.аморт]
			,l1.[Номер счета Ам]
			,l1.[Название счета учета накопл.аморт]
			,l1.[Дата начала амортизации]
			,l1.[СПИ, дней (БУ)]
			,l1.[Дата окончания амортизации]
			,l1.[Контрагент]
			,l1.[Комментарий]
			,l1.[СПИ, месяцев (НУ)]
			,l1.[Первоначальная стоимость на начало года]
			,l1.[Накопленная амортизация на начало года]
			,l1.[Остаточная стоимость на начало года]
			,l1.[Первоначальная стоимость на дату]
			,l1.[Амортизация за период]
			,l1.[Накопленная амортизация на дату]
			,l1.[Остаточная стоимость на дату]
			,l1.[Оставшийся срок, дней, на дату]
			,l1.[Оставшийся срок, дн. Расчетный]
			,l1.[Амортизация за 1 день]
			,[Амортизация за месяц]=case 
									
									--when l1.tmpAmoMonth>0 then l1.tmpAmoMonth
									--when l1.tmpAmoMonth=0 then 
									--	iif (isnull(lag(l1.tmpAmoMonth)over(partition by l1.account order by l1.amoDate),1)!=0
									--		,l1.[Остаточная стоимость на дату]-sum(isnull(l1.tmpAmoMonth,0)) over (partition by l1.account order by l1.amoDate rows unbounded preceding )
										
									--		,0)
									--else 0 end
									when flag=0 then 0
									when flag=-1 then l1.[Остаточная стоимость на дату]-sum(isnull(l1.tmpAmoMonth,0)) over (partition by l1.account order by l1.amoDate rows unbounded preceding )
									when flag=1 then l1.[Амортизация за 1 день]*day(l1.amoDate)
									else 0 end

		

			,[Контроль]= l1.[Амортизация за 1 день]*day(@repmonth)-l1.[Амортизация за период]
			,[осталось дней]=l1.[Оставшийся срок, дн. Расчетный]-l1.amoCountDay
			,[амо]=tmpAmoMonth
			,narItog=sum(isnull(l1.tmpAmoMonth,0)) over (partition by l1.account order by l1.amoDate rows unbounded preceding )
			,ost=l1.[Остаточная стоимость на дату]-sum(isnull(l1.tmpAmoMonth,0)) over (partition by l1.account order by l1.amoDate rows unbounded preceding )
			--,lag(l1.tmpAmoMonth)over(partition by l1.account order by l1.amoDate)
		from (
			select
				b.*
				,tmpAmoMonth=
					iif(b.[Оставшийся срок, дн. Расчетный]-a.amoCountDay<0,-1,
						iif(b.[Оставшийся срок, дн. Расчетный]-a.amoCountDay<day(amoDate)
						   ,0
						   ,b.[Амортизация за 1 день]*day(amoDate)
						   )
						)
				,flag=iif(b.[Оставшийся срок, дн. Расчетный]-a.amoCountDay<0
							,0
							,iif(b.[Оставшийся срок, дн. Расчетный]-a.amoCountDay<day(amoDate)
							,-1
							,1)
						)
				,a.account
				,a.amoDate
				,a.amoCountDay
			from #amoDate a
			left join #Shapka b on a.account=b.[Счет учета перв.ст]
			--where account='60901810000000000229'
			)l1 

		)l2

 --commit tran

	
	--set @subject=concat('OK! ',@subjectHeader) 
	--set @message=''
	--set @message=concat(@msgHeader,@message,@msgFloor)
	--exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
 -- end try 

 -- begin catch
 --   ROLLBACK TRANSACTION
	--set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	--set @subject='Ошибка! '
	--set @message=concat(@msgHeader,@message)
	--exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
 --  ;throw 51000 
	--		,@message
	--		,1;    
 -- end catch

 
END
--select * from #tt
--where [Счет учета перв.ст]='60901810000000000030'

--select * from #amoDate where account='60901810000000000030'

--select * from #Shapka where [Счет учета перв.ст]='60901810000000000072'
--select * from #amoDate where account='60901810000000000072'

--60901810000000000074
--60901810000000000216
--60901810000000000253

--select * from #tt where [Контроль остаточной стоимости]!=0
--and [ОС, НМА]='НМА'
--order by [Счет учета перв.ст],[Отчетный месяц]

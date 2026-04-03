





/*
--При вызове процедуры данные в результирующей таблице dwh2].[finAnalytics].[NMAOS] обновляются полностью !!!

--код состоит из 3 шагов . данные по НМА и ОС вносятся в общую таблицу
--0. это общий блок собирает информацию по проводкам для НМА и ОС
	--формируем общую таблицу всех проводок по ТЗ
	--формируем таблицу списаных НМА и ОС (в выходной таблице поле dateOut если не null то списан)
	--формируем таблицу принятия на баланс по всем НМА по всем измениям первоначальной стоимсоти (требуется для НМА НУ) 
		и сохраняем в справочнике измения перовначальной стоимости spr_NMA_changeFirstPrice
	--формируем таблицу суммы всех значений первоначальной стоимости по НМА
	--формируем таблицу по котрагентам поставщикам НМА на основании проводок
	--формируем таблицу по ежемесячным отчислениям амортизации на основании проводок
	--фомируем корректную таблицу остатков по счетам НМА и ОС (есть проблема в ошибки подразделения branch)

--1. наполнение таблицы данными по НМА 
	--формируем таблицу расчетных показателей аммортизации в месяц для НМА НУ с учетом возможных измений первоначальной цены (требуется для НМА НУ) 
	--наполняем основную таблицу по НМА 
	
--2. наполнение таблицы данными ОС
	--формируем таблицу корректных данных по параметрам амортизации ОС
	--формируем корректную таблицу принятых на баланс ОС (имеются дубли строк)
	--вносим данные по ОС в таблицу 

--3. хард код подблок дополняем данные по определеным НМА и ОС (справочно) с расчетом ежемесячных отчислений по аммортизации
	--хардкод по номеру 245
*/
CREATE PROCEDURE [finAnalytics].[addNMAOS] 
    
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	declare @maxMonthOsv date =(select eomonth(max(repMonth)) from dwh2.finAnalytics.OSV_MONTHLY) --максимальная дата по остаткам 
	declare @minMonthOsv date =(select eomonth(min(repMonth)) from dwh2.finAnalytics.OSV_MONTHLY) --минимальная дата по остаткам 
	
	declare @subjectHeader  nvarchar(250) ='НМА и ОС', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Обновление данных по НМА и ОС: ',FORMAT(@maxMonthOsv , 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''


	

 begin try	
  begin tran 
	--0
-- выбираем проводки из бнфо по НМА и ОС
	drop table if exists #bnfo
	create table #bnfo (dat date, dateProvodki date ,chKt varchar(20),chDt varchar(20), summ float,dt varchar(5),kt varchar(5),linkChKt binary(16),linkChDt binary(16),linkAgent binary(16))
	insert into #bnfo (dat,dateProvodki,chKt,chDt,summ,dt,kt,linkChKt,linkChDt,linkAgent) 
	select
		dat =eomonth(cast(dateadd(year,-2000,a.период) as date))
		,dateProvodki=cast(dateadd(year,-2000,a.период) as date)
		,chKt=chKt.Код
		,chDt=chDt.Код
		,summ=a.Сумма
		,dt=b.Код
		,kt=c.Код 
		,linkChKt=a.СчетАналитическогоУчетаКт
		,linkChDt=a.СчетАналитическогоУчетаДт
		,linkAgent=СубконтоCt1_Ссылка
	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0x00
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0x00
	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета chKt on a.СчетАналитическогоУчетаКт=chKt.Ссылка and chKt.ПометкаУдаления=0x00
	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета chDt on a.СчетАналитическогоУчетаДт=chDt.Ссылка and chDt.ПометкаУдаления=0x00
	where ((b.Код ='71802'and c.Код ='60903') --НМА
		   or
		   (b.Код ='71802'and c.Код ='60414')--ОС
		   or
		   (b.Код ='60901' and c.Код ='60906') or (b.Код ='60906' and c.Код in ('60312','60311'))--Контрагенты
		   or 
		   (b.Код ='61209' and c.Код in('60901','60401')) --списание НМА и ОС
		   )
		   and a.Активность=0x01

-- формируем таблицу списаных НМА и ОС
	drop table if exists #outBalance
	select
		distinct
		dat
		,ch=chKt
	into #outBalance
	from #bnfo
	where (dt ='61209' and kt in('60901','60401'))


--формируем таблицу принятия на баланс по всем НМА по всем измениям первоначальной стоимсоти

	drop table if exists #balDiffPrice
	select
		l1.dat
		,l1.dateProvodki
		,l1.linkChDt
		,l1.ch
		,l1.summ
		,diff=sum(l1.diff)over (partition by ch order by dat)
	into  #balDiffPrice
	from ( 
		select
			dat=dat
			,dateProvodki=dateProvodki
			,linkChDt=linkChDt
			,ch=chDt
			,summ=summ
			--если первоначальная стоимость изменилась то фиксируем через сколько месяцев
			,diff=isnull(datediff(month,lag(dat)over(partition by chDt order by dat),dat),0)
	
		from #bnfo
		where (dt ='60901' and kt ='60906')
		)l1
	order by l1.dat
	--сохраняем данные в spr_NMA_changeFirstPrice
	truncate table dwh2.finAnalytics.spr_NMA_changeFirstPrice
	insert into dwh2.finAnalytics.spr_NMA_changeFirstPrice (ch,dat,firstPrice)
		select
			ch
			,dateProvodki
			,summ
		from #balDiffPrice
	---

--формируем таблицу итоговую по первоначальную стоимост по всем НМА и ОС
drop table if exists #balance
		select
			l2.linkCh
			,l2.ch
			,l2.summ
			,l2.dat1
			,l2.dat2
			,firstPriceBU=l2.itog
			,firstPriceNU=l2.itogNU
			,lastChange
		into #balance
		from 
			(select
				l1.linkCh
				,l1.ch
				,l1.summ
				,l1.dat1
				,dat2=iif(l1.dat2=l1.dat1,cast('9999-01-01' as date),l1.dat2)
				,l1.itog
				,l1.itogNU
				,l1.lastChange
			from (
				select
					--формируем интервалы действи первичной стоимотси и сумму итог в этом интревале
					linkCh=linkChKt
					,ch=chDt
					,summ
					,dat1=dat
					,dat2=first_value(dat)over(partition by chDt  order by dat desc rows between 1 preceding and current row )
					--формируем нарастающее изменение первоначальной стоимости (например при модернизации)
					,itog=sum(summ)over(partition by chDt  order by dat rows unbounded preceding)
					--формируем изменение первоначальной стоимости для НУ
					,itogNU=sum(summ)over(partition by chDt)
					--для измений цены несколько раз в один месяц делаем ранжирование для выборки последнего измения в этом месяца (значение 1 аккутуальное изменение цены в месяце)
					,lastChange=row_number()over(partition by chDt,dat order by dateProvodki desc)
				from #bnfo
				where (dt ='60901' and kt ='60906')
				)l1
			)l2	
			where l2.lastChange=1


--определение на основании проводок контрагентов для НМА
-- выбор проводок по по ссылке на 20 значный счет НМА 
	drop table if exists #agent
	select
		ch=l1.ch
		,agent=string_agg(l1.agent,', ')
	into #agent
	from (
			select
				ch=b.ch
				,agent=c.Наименование
				,rn=row_number()over(partition by b.ch,c.Наименование order by a.dat desc)
			from #bnfo a 
			inner join #balance b on a.linkChDt=b.linkCh
			left join stg._1cUMFO.Справочник_Контрагенты c on a.linkAgent=c.Ссылка
			where (dt ='60906' and kt in ('60312','60311'))
			)l1
	where rn=1
	group by l1.ch

--определяем по проводкам ежемесячные отчисления по амортизации для НМА и ОС 
drop table if exists #NMAOS
select
	dat=dat 
	,ch=chKt
	,summ=sum(summ)
into #NMAOS
from #bnfo
where (dt ='71802'and kt='60903') or (dt ='71802'and kt ='60414')
group by dat,chKt

--корректная таблица остатков НМА 
drop table if exists #mainOsvMonth
select 
	acc2order=acc2order
	,accNum=accNum
	,repmonth=repmonth
	,restOUT_BU=sum(isnull(restOUT_BU,0))
	,restOUT_NU=sum(isnull(restOUT_NU,0))
	into #mainOsvMonth
from dwh2.finAnalytics.osv_monthly 
where acc2order in ('60901','60903','60401','60414')
group by repMonth,acc2order,accNum


-----------------------------------------------------------------------------------

---


--формируем таблицу расчетных показателей аммортизации в месяц для НМА НУ
drop table if exists #amoMontn_NU --#tmp_amoMontn_NU
select
 a.*
 ,spiMont_NU=isnull(k.spiNU,b.СрокПолезногоИспользованияНУ)-a.diff
 ,summAmoMonth_NU=sum(isnull(summ/nullif((isnull(k.spiNU,b.СрокПолезногоИспользованияНУ)-a.diff),0),0))over (partition by a.ch order by a.dat)
 ,spiNU=isnull(k.spiNU,b.СрокПолезногоИспользованияНУ)
  into #amoMontn_NU--#tmp_amoMontn_NU
from #balDiffPrice a
left join stg._1cUMFO.Документ_ПринятиеКУчетуНМА b on a.linkChDt=b.СчетУчета_Ссылка and b.ПометкаУдаления=0x00 and b.Проведен=0x01
left join (select * from dwh2.finAnalytics.spr_NMA_InfoNotInUMFO where addOrchange=1) k on a.ch=k.account

--select * from #tmp_amoMontn_NU where ch='60901810000000000226'
--select * from #amoMontn_NU where ch='60901810000000000226'
--select * from #mainOsvMonth where accNum='60901810000000000239'

--select * from #NMAOS
--order by ch
--select
--*
--from #amoMontn_NU where ch='60901810000000000239' and dat >'2024-03-31'

-- блок добавлен для корректировки данных под рабочий алгоритм расчета амортизации в месяц при изменении начальной цены
--т.к. ручной расчет прошлых периодов имеет некорретный расчет
--drop table if exists #amoMontn_NU
--select
--	  l2.dat
--	 ,l2.linkChDt
--	 ,l2.ch
--	 ,l2.summ
--	 ,l2.spiMont_NU
--	 ,summAmoMonth_NU=sum(isnull(l2.summ/nullif(l2.spiMont_NU,0),0))over(partition by l2.ch order by l2.dat)
-- into #amoMontn_NU
--from (
--	select 
--	 dat=lastdate
--	 ,linkChDt
--	 ,ch
--	 ,summ=sum(summ)
--	 ,spiMont_NU=spiNu
--	from (
--		select
--		 *
--		,lastdate=datefromparts(year(dat),'01','01')--max(dat)over(partition by ch )
--		from #tmp_amoMontn_NU
--		where year(dat)<2025
--		) l1
--	group by  lastdate,linkChDt,ch,spiNU
--	union all
--	select 
--	 dat
--	 ,linkChDt
--	 ,ch
--	 ,summ
--	 ,spiMont_NU
--	from #tmp_amoMontn_NU
--	where year(dat)>=2025 
--	)l2
--order by l2.ch


----очищаем таблицу dwh2.finAnalytics.NMAOS
truncate table dwh2.finAnalytics.NMAOS
--вносим данные по НМА в таблицу 
insert into dwh2.finAnalytics.NMAOS (repdate,typeRes,Account,n_Account,nameAccount,amAccount,n_AmAccount,nameAmAccount
									 ,agent,comment
									 ,firstPrice_BU,spiDay_BU,dateBeginAmo_BU,dateEndAmo_BU,spiMonth_BU,accumAmo_BU,resPrice_BU,summAmoMonth_BU
									 ,firstPrice_NU,dateBeginAmo_NU,dateEndAmo_NU,spiMonth_NU,accumAmo_NU,resPrice_NU,summAmoMonth_NU,normAmo_NU
									 ,dateOut)

--declare @minMonthOsv date =(select eomonth(min(repMonth)) from dwh2.finAnalytics.OSV_MONTHLY) --минимальная дата по остаткам 
--select @minMonthOsv
select
		l1.repdate
		,l1.typeRes
		,l1.account
		,l1.n_Account
		,l1.nameAccount
		,l1.amAccount
		,l1.n_AmAccount
		,l1.nameAmAccount
		,l1.agent
		,l1.comment
		----БУ
		,l1.firstPrice_BU
		,l1.spiDay_BU
		,l1.dateBeginAmo_BU
		,l1.dateEndAmo_BU
		,l1.spiMonth_BU
		,l1.accumAmo_BU
		,l1.resPrice_BU
		,l1.summAmoMonth_BU
		----НУ
		,l1.firstPrice_NU
		,l1.dateBeginAmo_NU
		,l1.dateEndAmo_NU
		,l1.spiMonth_NU
		--,accumAmo_NU=iif(l1.repdate<=eomonth(l1.dateEndAmo_NU)
		--						,iif (year(dateadd(month,1,l1.dateBeginAmo_NU))<2025
		--							,datediff(month,l1.dateBeginAmo_NU,repdate) *l1.summAmoMonth_NU
		--							,sum(isnull(l1.summAmoMonth_NU,0)) over(partition by l1.account order by l1.repdate)
		--							--добавляем накопленную аммортизацию по которой нет инфы в остатках
		--								+iif(l1.dateBeginAmo_NU< @minMonthOsv, (datediff(month,l1.dateBeginAmo_NU, @minMonthOsv)-1) *l1.summAmoMonth_NU,0)
		--							)
		--						,l1.firstPrice_NU
								
		--						)
		--,resPrice_NU=iif(l1.repdate<=eomonth(l1.dateEndAmo_NU)
		--						,iif (year(dateadd(month,1,l1.dateBeginAmo_NU))<2025
		--							,l1.firstPrice_NU-datediff(month,l1.dateBeginAmo_NU,repdate) *l1.summAmoMonth_NU
		--							,l1.firstPrice_NU
		--								-sum(isnull(l1.summAmoMonth_NU,0)) over(partition by l1.account order by l1.repdate)
		--								--добавляем накопленную аммортизацию по которой нет инфы в остатках
		--								-iif(l1.dateBeginAmo_NU< @minMonthOsv, (datediff(month,l1.dateBeginAmo_NU, @minMonthOsv)-1) *l1.summAmoMonth_NU,0)
										
		--							)
		--						,0
		--						)
		
		,accumAmo_NU=iif(l1.repdate<=eomonth(l1.dateEndAmo_NU)
								,sum(l1.summAmoMonth_NU) over(partition by l1.account order by l1.repdate)
								--datediff(month,l1.dateBeginAmo_NU,repdate) *l1.summAmoMonth_NU
								--добавляем накопленную аммортизацию по которой нет инфы в остатках
								+iif(eomonth(l1.dateBeginAmo_NU)< @minMonthOsv, (datediff(month,l1.dateBeginAmo_NU, @minMonthOsv)-1) *l1.summAmoMonth_NU,0)
								,l1.firstPrice_NU
								
								)
		,resPrice_NU=iif(l1.repdate<=eomonth(l1.dateEndAmo_NU)
								,l1.firstPrice_NU-sum(l1.summAmoMonth_NU) over(partition by l1.account order by l1.repdate)
								--добавляем накопленную аммортизацию по которой нет инфы в остатках
								-iif(eomonth(l1.dateBeginAmo_NU)< @minMonthOsv, (datediff(month,l1.dateBeginAmo_NU,@minMonthOsv)-1) *l1.summAmoMonth_NU,0)
								--datediff(month,l1.dateBeginAmo_NU,repdate) *l1.summAmoMonth_NU
								,0
								)
		,l1.summAmoMonth_NU
		,l1.normAmo_NU
		--,l1.firstMonthAmo
		,l1.dateOut
		
from (
	select 
		 repdate=eomonth(osv1.repMonth)
		,typeRes='НМА'
		,account=fch.Код
		,n_Account=convert(int,substring(fch.Код,8,20))
		,nameAccount=fch.Наименование
		,amAccount=ach.Код
		,n_AmAccount=convert(int,substring(ach.Код,8,20))
		,nameAmAccount=ach.Наименование
		
		,agent=g.agent
		,comment=a.Комментарий
		--БУ
		,firstPrice_BU=isnull(bal.firstPriceBU,a.СтоимостьБУ)	
		,spiDay_BU=isnull(p.spiDay, 
						iif(a.СЗДСрокПолезногоИспользованияВДнях!=0 and a.СЗДСрокПолезногоИспользованияВДнях is not null
							,a.СЗДСрокПолезногоИспользованияВДнях
							,isnull(datediff(day,cast(a.Дата as date),dateadd(month,a.СрокПолезногоИспользованияБУ,cast(a.Дата as date))),0)
							) 
					)
		
		,dateBeginAmo_BU=isnull(p.dat,dateadd(year,-2000,cast(a.Дата as date)))
		,dateEndAmo_BU=isnull(dateadd(day,p.spiDay,p.dat), 
								iif(a.СЗДСрокПолезногоИспользованияВДнях!=0 and a.СЗДСрокПолезногоИспользованияВДнях is not null
								,dateadd(year,-2000,dateadd(day,a.СЗДСрокПолезногоИспользованияВДнях-1,cast(a.Дата as date)))
								,isnull(dateadd(year,-2000,dateadd(month,a.СрокПолезногоИспользованияБУ,cast(a.Дата as date))),'2001-01-01')
								) 

							)
		,spiMonth_BU=isnull(p.spiBu,a.СрокПолезногоИспользованияНУ)
		,accumAmo_BU=abs(isnull(osv2.restOUT_BU,0))
		,resPrice_BU=isnull(osv1.restOUT_BU,0)+isnull(osv2.restOUT_BU,0)
		,summAmoMonth_BU=isnull(n.summ,0)
		----НУ
		,firstPrice_NU=isnull(bal.firstPriceNU,a.СтоимостьБУ)
		,dateBeginAmo_NU=dateadd(year,-2000,cast(a.Дата as date))
		,dateEndAmo_NU=dateadd(month,isnull(k.spiNU,a.СрокПолезногоИспользованияНУ),dateadd(year,-2000,cast(a.Дата as date)))
		,spiMonth_NU=isnull(k.spiNU,a.СрокПолезногоИспользованияНУ)
		,summAmoMonth_NU=iif (eomonth(osv1.repMonth)<=eomonth(dateadd(month,isnull(k.spiNU,a.СрокПолезногоИспользованияНУ),dateadd(year,-2000,cast(a.Дата as date))))
					and datediff(month,dateadd(year,-2000,cast(a.Дата as date)),osv1.repMonth)>0--следующий месяц
					,iif(datediff(year
										,(select top(1) dat from #amoMontn_NU where ch=fch.Код order by dat desc)--выбираем последнее изменение первичной стоимости
										,(osv1.repMonth)
								 )>0 --с нового года начинаем считать по правилу аморт в месяц=первоночальная стоимость на начало этого года/ спи месяце НУ
						,(select top(1) summAmoMonth_NU from #amoMontn_NU where ch=fch.Код	and dat<eomonth(osv1.repMonth)order by dat desc)
						---isnull(bal.firstPriceNU,a.СтоимостьБУ)/nullif(isnull(k.spiNU,a.СрокПолезногоИспользованияНУ),0)
						-- вариант перерасчета амортизации в случаи если в течении года изменилась первоначальная стоимость
						,(select top(1) summAmoMonth_NU from #amoMontn_NU where ch=fch.Код	and dat<eomonth(osv1.repMonth)order by dat desc)
					    )	
					,0)
		,normAmo_NU=isnull(1.0/isnull(k.spiNU,nullif(a.СрокПолезногоИспользованияНУ,0)) *100,0)
		,dateOut=outBalance.dat
		--первый месяц амортизации - это следующий месяц после постановки на учет
		--,firstMonthAmo=dateadd(month,1,min(n.dat)over(partition by n.ch order by n.dat))
		

	from stg._1cUMFO.Документ_ПринятиеКУчетуНМА a
	left join stg._1cUMFO.РегистрСведений_ПервоначальныеСведенияНМАБухгалтерскийУчет b on a.Ссылка=b.Регистратор_Ссылка
	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета fch on a.СчетУчета_Ссылка=fch.Ссылка and fch.ПометкаУдаления=0x00
	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета ach on a.СчетНачисленияАмортизации_Ссылка=ach.Ссылка and ach.ПометкаУдаления=0x00
	left join #Agent g on fch.Код=g.ch 
	left join #mainOsvMonth osv1 on fch.Код=osv1.accNum --Первоначальная стоимость
						and osv1.acc2order='60901'
	left join #mainOsvMonth osv2 on ach.Код=osv2.accNum and osv1.repMonth=osv2.repMonth --Накопленная амортизация на дату
						and osv2.acc2order='60903'
	left join #NMAOS n on ach.Код=n.ch and eomonth(osv1.repMonth)=n.dat --проводки
	left join dwh2.finAnalytics.spr_NMA_changeParamAmo p on ach.Код=p.ch --изменение параметров некоторых НМА
	left join #balance bal on fch.Код=bal.ch and eomonth(osv1.repMonth)>=bal.dat1 and eomonth(osv1.repMonth)<bal.dat2
	left join (select * from dwh2.finAnalytics.spr_NMA_InfoNotInUMFO where addOrchange=1) k on fch.Код=k.account
	left join #outBalance outBalance on fch.Код=outBalance.ch
	where a.ПометкаУдаления=0x00 and a.Проведен=0x01
		and osv1.repmonth is not null
	--and bal.ch='60901810000000000248'
	--order by repdate
	)l1
order by l1.repdate --l1.dateBeginAmo_BU

----select 
----*
----from #NMAOS
----where ch='60903810000000000247'
----select 
----*
----from #balance
--where ch='60901810000000000248'

--------------------------------------------------------
--2
--подготовка параметров аммортизации для ОС, выбираем только последние по времени изменные параметры
--по ОС account 60401810000000000024  нет параметров аммортизации
drop table if exists #paramAmoOS 
select
	linkOS=l1.linkOS
	,link=l1.link
	,dat=l1.dat
	,spi=l1.spi
into #paramAmoOS 
from (
	select
	 rn=row_number() over (partition by ОсновноеСредство order by Период desc)
	 ,rnD=row_number() over (partition by Регистратор_Ссылка order by Период desc)
	 ,linkOS=ОсновноеСредство 
	 ,link=Регистратор_Ссылка
	 ,dat=dateadd(year,-2000,cast(Период as date))
	 ,spi=БНФОСрокИспользованияДляВычисленияАмортизацииВДнях
	from stg._1cUMFO.РегистрСведений_ПараметрыАмортизацииОСБухгалтерскийУчет 
	where Активность=0x01
	) l1
where rn=1 and  rnD in (1,2)--2 нашел когда пакетно одним документом приняли 2шт ОС 
								--'60401810000000000024' и '60401810000000000023'
--формируем корректную таблицу принятых на баланс ОС (имеются дубли строк)
drop table if exists #accountOS 
select 
 link=l1.Ссылка
 ,linkFch=l1.БНФОСчетУчета
 ,linkAch=l1.БНФОСчетНачисленияАмортизации
 ,linkOS=l1.ОсновноеСредство
 ,spiMonth_BU=l1.spiMonth_BU
 into #accountOS 
from (
	select
		 rn=row_number()over(partition by b.БНФОСчетУчета order by b.БНФОСчетУчета)
		,a.Ссылка
		,b.БНФОСчетУчета
		,b.БНФОСчетНачисленияАмортизации
		,b.ОсновноеСредство
		,spiMonth_BU=isnull(a.СрокПолезногоИспользованияНУ,0)
	from stg._1cUMFO.Документ_ПринятиеКУчетуОС a
		left join stg._1cUMFO.Документ_ПринятиеКУчетуОС_ОС b on a.Ссылка=b.Ссылка
		where b.БНФОСчетУчета is not null and convert(int ,b.БНФОСчетУчета)!=0
		and (a.ПометкаУдаления=0x00 and (a.Проведен=0x01 
										--номенклатура ОС не проведена но числится на остатках
										--'60401810000000000001'
										or a.Ссылка=0x80FF00155D01C00511E7A2CBA24DEB8C
										))
	)l1
where l1.rn=1
--вносим данные по ОС в таблицу 
insert into dwh2.finAnalytics.NMAOS (repdate,typeRes,Account,n_Account,nameAccount,amAccount,n_AmAccount,nameAmAccount
									 ,agent,comment
									 ,firstPrice_BU,spiDay_BU,dateBeginAmo_BU,dateEndAmo_BU,spiMonth_BU,accumAmo_BU,resPrice_BU,summAmoMonth_BU
									 ,firstPrice_NU,dateBeginAmo_NU,dateEndAmo_NU,spiMonth_NU,accumAmo_NU,resPrice_NU,summAmoMonth_NU,normAmo_NU
									 ,dateOut)
select 
	repdate=eomonth(osv1.repMonth)
	,typeRes='ОС'
	,account=fch.Код
	,n_account=convert(int,substring(fch.Код,8,20))
	,nameAccount=fch.Наименование
	,amAccount=ach.Код
	,n_AmAccont=convert(int,substring(fch.Код,8,20))
	,nameAmAccount=ach.Наименование
	,agent=''
	,comment=''
	,firsPrice_BU=isnull(osv1.restOUT_BU,0)
	,spiDay_BU=am.spi
	,dateBeginAmo_BU=am.dat
	,dateEndAmo_BU=dateadd(day,am.spi ,am.dat)
	,spiMonth_BU=isnull(a.spiMonth_BU,0)
	,accumAmo_BU=isnull(abs(osv2.restOUT_BU),0)
	,resPrice_BU=isnull(osv1.restOUT_BU+osv2.restOUT_BU,0)
	,summAmoMonth_BU=isnull(r.summ,0)
	,firstPrice_NU=0.0
	,dateBeginAmo_NU=null
	,dateEndAmo_NU=null
	,spiMonth_NU=0
	,accumAmo_NU=0.0
	,resPrice_NU=0.0
	,summAmoMonth_NU=0.0
	,normAmo_NU=0.0
	,dateOut=outBalance.dat
from #accountOS a
left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета fch on a.linkFch=fch.Ссылка and fch.ПометкаУдаления=0x00
left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета ach on a.linkAch=ach.Ссылка and ach.ПометкаУдаления=0x00
left join #paramAmoOS am on a.linkOS=am.linkOS 
left join #mainOsvMonth osv1 on fch.Код=osv1.accNum --Первоначальная стоимость
					and osv1.acc2order='60401' 
left join #mainOsvMonth osv2 on ach.Код=osv2.accNum and osv1.repMonth=osv2.repMonth --Накопленная амортизация на дату
					and osv2.acc2order='60414'
left join #NMAOS r on ach.Код=r.ch and eomonth(osv1.repMonth)=r.dat
left join #outBalance outBalance on fch.Код=outBalance.ch



----------------------------------------------------
--3
	
	-- формируем таблицу справочных НМА и ОС
	drop table if exists #paramAmoSpr
	create table #paramAmoSpr  (n int,ch varchar(20),chAmo varchar(20),dat date, spiBU int, spiDay int, firstPrice float, spiNU int,typeres nvarchar(10)) 
	  insert into #paramAmoSpr (n,ch,chAmo,dat,spiBu,spiDay,firstPrice,spiNU,typeres)
		select 
			n=row_number()over(order by account)
			,ch=account
			,chAmo=accountAmo
			,dat=beginDate
			,spiBU
			,spiDay
			,firstPrice
			,spiNU
			,typeres
		from dwh2.finAnalytics.spr_NMA_InfoNotInUMFO where addOrchange=0

	--удаляем в основной таблицы записи связанные с этими данными
	delete from dwh2.finAnalytics.NMAOS
	from dwh2.finAnalytics.NMAOS as a 
	inner join #paramAmoSpr b on a.amAccount=b.chAmo

	--select * from dwh2.finAnalytics.NMAOS
	--order by Account
	--where amAccount='60903810000000000045'
	--select * from #paramAmoSpr

	
	--формируем таблицу ручного расчета начислений по амортизации по месяцам в период с даты постуления НМА по макимальный период в данных по остаткам по счетам
	drop table if exists #NMAOSSpr
	create table #NMAOSSpr (dat date,ch varchar(20),chAmo varchar(20),summ float,summAmoNakop float, summNU float)

	declare @id int = (select count(*) from #paramAmoSpr ), @countMonthAmo int ,@j int 
	declare @beginDate date , @endDate date, @iDate date, @ch varchar(20),@chAmo varchar(20)
	declare @summDay float, @spiDay int,@summAmoNakop float=0, @firstPrice float,@summNU float 
		
	--@maxMonthOsv  --максимальная дата по остаткам 

	while @id>0 
		begin
			set @countMonthAmo = (select spiBu from #paramAmoSpr where n=@id)
			set @spiDay= (select spiDay from #paramAmoSpr where n=@id)
			set @firstPrice= (select firstPrice from #paramAmoSpr where n=@id)
			set @beginDate=(select dat from #paramAmoSpr where n=@id) --дата начала эксплуатации
			
			set @iDate=eomonth(@beginDate)--первый месяц аморт
			set @endDate=dateadd(month,@countMonthAmo,@iDate)--последний месяц аморт
			set @chAmo=(select chAmo from #paramAmoSpr where n=@id)
			set @ch=(select ch from #paramAmoSpr where n=@id)
			set @summDay=(select firstPrice/@spiDay from #paramAmoSpr where n=@id)--амортиз в день
			set @summNU=(select firstPrice/spiNU from #paramAmoSpr where n=@id)--амортиз в день НУ
			while @iDate<dateadd(month,1,@maxMonthOsv) and @iDate<=@maxMonthOsv--@endDate 
				begin
					
					set @summAmoNakop=@summAmoNakop+iif(@iDate!=@endDate 
														,iif(eomonth(@beginDate)=@iDate,datediff(day,@beginDate,@iDate)+1,day(@iDate))*@summDay
														,0
														)
					--если аммортизация закончилась то накопленая амортизация равна первичной стоимости
					set @summAmoNakop=iif(@iDate>@endDate,@firstPrice,@summAmoNakop)
					insert into #NMAOSSpr (dat,ch,chAmo,summ,summAmoNakop,summNU )
						values (
							@iDate
							,@ch
							,@chAmo
							--(если тот же месяц то считаем кол-во дней в остатке, иначе кол-во дней в месяце)и умножам на аморт в день
							,iif(@iDate>=@endDate
								,@firstPrice-@summAmoNakop --если послед месяц "="то сумма амо в месяц равна остатку/">" -месяц после окончания амортизации то сумма амо в меяц 0
								,iif(eomonth(@beginDate)=@iDate,datediff(day,@beginDate,@iDate)+1,day(@iDate))*@summDay
								)
							--,@j*@summDay
							,iif(@iDate!=@endDate,@summAmoNakop,@firstPrice) -- если последний месяц то накопленая амо равна начальной цене
							,@summNU
							)
						
					set @iDate =eomonth(dateadd(month,1,@iDate)) --начисленеи в месяц постановки на учет
				end
				set @summAmoNakop=0.0
			set @id-=1	
		
		end

	--вносим данные по НМА 
	insert into dwh2.finAnalytics.NMAOS (repdate,typeRes,Account,n_Account,nameAccount,amAccount,n_AmAccount,nameAmAccount
									 ,agent,comment
									 ,firstPrice_BU,spiDay_BU,dateBeginAmo_BU,dateEndAmo_BU,spiMonth_BU,accumAmo_BU,resPrice_BU,summAmoMonth_BU
									 ,firstPrice_NU,dateBeginAmo_NU,dateEndAmo_NU,spiMonth_NU,accumAmo_NU,resPrice_NU,summAmoMonth_NU,normAmo_NU
									 ,dateOut)
	select 
		repdate=b.dat
		,typeRes=a.typeres 
		,account=fch.Код 
		,n_account=convert(int,substring(fch.Код,8,20))
		,nameAccount=fch.Наименование
		,amoAccount=ach.Код 
		,n_amAccount=convert(int,substring(ach.Код,8,20))
		,nameAmAccount=ach.Наименование 
		,agent=g.agent
		,comment='справочно'
		--БУ
		,firstPrice_BU=a.firstPrice
		,spiDay_BU=a.spiDay
		,dateBeginAmo_BU=a.dat
		,dateEndAmo_BU=dateadd(day,a.spiDay,a.dat)
		,spiMonth_BU=a.spiBU
		,accumAmo_BU=b.summAmoNakop--sum(b.summ) over (partition by b.ch order by b.dat rows unbounded preceding)
		,resPrice_BU=isnull(a.firstPrice,0)-b.summAmoNakop--sum(b.summ) over (partition by b.ch order by b.dat rows unbounded preceding)
		,summAmoMonth_BU=isnull(b.summ,0)
		--НУ
		,firstPrice_NU=a.firstPrice
		,dateBeginAmo_NU=a.dat
		,dateEndAmo_NU=eomonth(dateadd(month,a.spiNU,a.dat))
		,spiMonth_NU=a.spiNU
		,accumAmo_NU=sum(iif(eomonth(a.dat)=b.dat,0,isnull(b.summNU,0))) over (partition by b.ch order by b.dat rows unbounded preceding)
		,resPrice_NU=isnull(a.firstPrice,0)-sum(iif(eomonth(a.dat)=b.dat,0,isnull(b.summNU,0))) over (partition by b.ch order by b.dat rows unbounded preceding)
		,summAmoMonth_NU=iif(eomonth(a.dat)=b.dat,0,isnull(b.summNU,0))
		,normAmo_NU=isnull(1.00/nullif(a.spiNU,0)*100,0) --в таблице справочника дополнений spiBU должно быть равно spiNu
		,dateOut=outBalance.dat
	from  #paramAmoSpr  a
	left join #NMAOSSpr b on a.ch=b.ch
	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета fch on a.ch=fch.Код and fch.ПометкаУдаления=0x00
	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета ach on a.chAmo=ach.Код and ach.ПометкаУдаления=0x00
	left join #Agent g on fch.Код=g.ch 
	left join #outBalance outBalance on fch.Код=outBalance.ch
	order by account,repdate
	--- хардкод по номеру 245 полное списание сделали раньше чем СПИ 
 insert into [dwh2].[finAnalytics].[NMAOS] (repdate,typeRes,Account,n_Account,nameAccount,amAccount,n_AmAccount,nameAmAccount,agent,comment
											,firstPrice_BU,spiDay_BU,dateBeginAmo_BU,dateEndAmo_BU,spiMonth_BU,accumAmo_BU,resPrice_BU,summAmoMonth_BU
											,firstPrice_NU,dateBeginAmo_NU,dateEndAmo_NU,spiMonth_NU,accumAmo_NU,resPrice_NU,summAmoMonth_NU,normAmo_NU)

 SELECT [repdate]
      ,[typeRes]
      ,[Account]
      ,[n_Account]=245245
      ,[nameAccount]
      ,[amAccount]
      ,[n_AmAccount]
      ,[nameAmAccount]
      ,[agent]
      ,[comment]
      ,[firstPrice_BU]
      ,[spiDay_BU]
      ,[dateBeginAmo_BU]
      ,[dateEndAmo_BU]
      ,[spiMonth_BU]
      ,[accumAmo_BU]
      ,[resPrice_BU]
      ,[summAmoMonth_BU]
      ,[firstPrice_NU]
      ,[dateBeginAmo_NU]
      ,[dateEndAmo_NU]
      ,[spiMonth_NU]=9
      ,[accumAmo_NU]
      ,[resPrice_NU]
      ,[summAmoMonth_NU]=iif(repdate='2025-07-31',25666.666,229.166666666667)
      ,[normAmo_NU]=229.166666666667
  FROM [dwh2].[finAnalytics].[NMAOS]
  where account='60901810000000000245'
  and repdate<='2025-07-31'	

  commit tran

	
	set @subject=concat('OK! ',@subjectHeader) 
	set @message=''
	set @message=concat(@msgHeader,@message,@msgFloor)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp ='1' --'1,101'
	
	--declare @repmonth date = (select  max(eomonth(repdate)) as dd from dwh2.finAnalytics.NmaOS)

	--exec finAnalytics.calcNMAOS_Prognoz	@repmonth
	
	--делаем запись реестре отчетов
	---/Определение наличия данных/
    declare @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repdate) from [dwh2].[finAnalytics].[NMAOS]) as varchar)

    ---/Фиксация времени расчета/
    update dwh2.[finAnalytics].[reportReglament]
    set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
    where [reportUID] in (53)

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

 end try 

 begin catch
 ----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    ROLLBACK TRANSACTION
	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
   ;throw 51000 
			,@message
			,1;    
  end catch

END



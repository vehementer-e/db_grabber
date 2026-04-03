
CREATE PROCEDURE [finAnalytics].[calcMicrozaimRR]
	@rrDate date
	,@RRpoga float out
AS
BEGIN
	--declare @rrDate date='2025-01-31', @RRpoga float

	declare @startDate date =dateadd(month,-37,@rrDate), @endDate date = dateadd(day,-day(@rrDate),@rrDate) --дата конца периода расчета долей(пересчет только по месячно) 
	declare @minDate date =(select min(repdate) from dwh2.finAnalytics.repMicrozaim)--минимальная дата внутри таблицы
	
	if DATEDIFF ( day, @minDate , @rrDate )>=365 -- если период меньше года от минимальной даты из таблицы тогда расчет не ведем и @@RR=0 
		begin
			set @startDate=iif(@minDate>@startDate,@minDate,@startDate) --если минимальная дата больше принимаем началом даты расчета долей ее
			-- расчитываем коэффиенты среднего значения для выходных и рабочих дней	
			drop table IF EXISTS #predRR

			create table #predRR (dayT int, typeDay int,noKfRR float)--,countrow int)
			insert into #predRR
				-- расчитываем коэффицент RR без учета поправки
				select
					dayT=l2.dayT
					,typeDay=l2.typeDay
					,noKfRR=l2.avgkfWorkDay+l2.avgkfHoleDay
					--,iif(count(l2.dayT)over (partition by l2.dayT)=1,iif(l2.typeDay=0,1,0),null)
				from(
				-- расчитываем коэффиенты(доли) среднего значения для выходных и рабочих дней
					select 
						repdate=l1.repdate
						,dayT=day(l1.repdate)
						,typeDay=l1.typeDay
						,avgkfWorkDay=avg(l1.kfWorkDay) over (partition by day(l1.repdate), typeDay)
						,avgkfHoleDay=avg(l1.kfHoleDay) over (partition by day(l1.repdate),typeDay)
						,rn=ROW_NUMBER()over (partition by day(l1.repdate),typeDay order by day(l1.repdate))
					from (
			--			declare @rrDate date='2025-08-07'

			--declare @startDate date =dateadd(month,-37,@rrDate), @endDate date = dateadd(day,-1,@rrDate)
						select 
				-- расчитываем коэффиенты(доли) для каждого дня в заданном периоде - чистое погащшение/суммы чистых погашений в месяц
							 repdate = a.repdate
							,typeDay=k.isRussiaDayOff
							,kfWorkDay=abs(iif(k.isRussiaDayOff=0,(a.pogashenia-a.banRez)/sum(a.pogashenia-a.banRez)over (partition by a.repmonth),0))
							,kfHoleDay=abs(iif(k.isRussiaDayOff=1,(a.pogashenia-a.banRez)/sum(a.pogashenia-a.banRez) over (partition by a.repmonth),0))
						from dwh2.finAnalytics.repMicrozaim a
						left join dwh2.Dictionary.calendar k on a.repdate=k.dt
						where dt between @startDate and @endDate
							)l1
					)l2 where l2.rn=1
		--select * from #predRR
			drop table IF EXISTS #RR
			create table #RR (
					repdate date 
					,noKfRR float
					,sum_noKfRR float
					,yesKfRR float
					,sum_yesKfRR float
					,dev float
					,pogaClear float
					,rr	float
					,repmonth date
					)
			insert into #RR
				select 
						--расчитываем RR погашения 
						repdate=l1.dat
						,noKfRR=round(l1.noKfRR,4)
						,sum_noKfRR=round(sum(l1.noKfRR) over(partition by l1.repmonth),4)
						,yesKfRR=round(l1.yesKfRR,4)
						,sum_yesKfRR=round(sum(l1.yesKfRR) over(partition by l1.repmonth),4)
						,dev=round(l1.dev,4)
						,poga=it.pogashenia-it.banRez
						,rr	= case 
								when day(l1.dat)<>1 
									then
										round(
										sum(it.pogashenia-it.banRez) over (partition by l1.repmonth order by l1.dat rows between unbounded preceding and 1 preceding)
			    						/sum(l1.yesKfRR) over (partition by l1.repmonth order by l1.dat rows between unbounded preceding and 1 preceding)
										,0)
								   else 
										round((it.pogashenia-it.banRez)/l1.yesKfRR,0)
								   end
						,repmonth =datefromparts(year(l1.dat),month(l1.dat),1)
				from ( 
					-- привязываем таблицу коэффициентов к датам календаря и вычисляем коэффицент RR с учетом поправки
					select 	
						dat=a.dt
						,noKfRR=b.noKfRR
						,yesKfRR=noKfRR+(1-sum(b.noKfRR) over (partition by a.id_yearmonth)) /day(EOMONTH(a.dt))  
						,dev=1-(sum(b.noKfRR) over (partition by a.id_yearmonth))
						,typeDay=b.typeDay
						,repmonth=a.id_yearmonth
					from dwh2.Dictionary.calendar a
					left join #predRR b on day(a.DT)=b.dayT and a.isRussiaDayOff=b.typeDay
					where dt between @startDate and eomonth(@rrDate)
					) l1
				left join dwh2.finAnalytics.repMicrozaim it on l1.dat=it.repdate
				
				set @RRpoga =(select rr from #RR where repdate=@rrDate)--dateadd(day,-1,@rrDate))
			end
				else 
 				set @RRpoga=0


	
end
  
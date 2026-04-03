


CREATE PROCEDURE [finAnalytics].[reportCashIn_PogaSvodExp]
	@repmonth date

AS
BEGIN
 
  drop table if exists #bucket
	create table #bucket (
		id int
		,bucket_name varchar(20)
		,beginDay int
		,endDay int)
	insert into #bucket
		values
		  (1,'0',0,0)
		 ,(2,'1-3',1,3)
		 ,(3,'4-30',4,30)
		 ,(4,'31-60',31,60)
		 ,(5,'61-90',61,90)
		 ,(6,'91-120',91,120)
		 ,(7,'121-150',121,150)
		 ,(8,'151-180',151,180)
		 ,(9,'181-210',181,210)
		 ,(10,'211-240',211,240)
		 ,(11,'241-270',241,270)
		 ,(12,'271-300',271,300)
		 ,(13,'301-330',301,330)
		 ,(14,'331-360',331,360)
		 ,(15,'360+',361,999999)
	declare @countBuck int =(select count(*) from #bucket)

	declare @i int=1, @j int =1
	--создаем таблицу бакетов в разрезе по дням отчетного месяца 
	declare @datTab table (dat date, bucket varchar(20),id int)
	while @i<=day(@repmonth)
		begin 
			while @j<=@countBuck+1
				begin
					insert into @datTab (dat,bucket,id) values (
							DATEFROMPARTS(year(@repmonth),month(@repmonth),@i)
							,isnull((select bucket_name from #bucket where id=@j),'Итоги')
							,@j)
					set @j+=1
				end
			set @i+=1
			set @j=1
		end

	select 
		[Дата]=d.dat
		,[Бакет]=d.bucket
		,[Поступлений всего]=isnull(b.allSummIn,0)
		,[Погашение ОД]=isnull(b.allOD,0)
		,[Погашение %%]=isnull(b.allPRC,0)
		,[Погашение Пени, Штрафы, Госпошлины]=isnull(b.allPeni,0)+isnull(b.allGP,0)
		--,[Погашение Госпошлины]=isnull(b.allGP,0)
		,[Погашение ВСЕГО]=isnull(b.Itog,0)

		,[Погашение ОД ПП]=isnull(b.allOD_pp,0)
		,[Погашение %% ПП]=isnull(b.allPRC_pp,0)
		,[Погашение Пени, Штрафы,Госпошлины ПП]=isnull(b.allPeni_pp,0)+isnull(b.allGP_pp,0)
		--,[Погашение Госпошлины ПП]=isnull(b.allGP_pp,0)
		,[Погашение ВСЕГО ПП]=isnull(b.Itog_pp,0)
		--выводи по ТЗ справочно поэтому только нужна строка по итогам за день 
		,[Погашение ОД ПДП]=iif(d.bucket='Итоги', isnull(b.allOD_pdp,0),0.0)
		,[Погашение %% ПДП]=iif(d.bucket='Итоги',isnull(b.allPRC_pdp,0),0.0)
		,[Погашение Пени, Штрафы, Госпошлины ПДП]=iif(d.bucket='Итоги',isnull(b.allPeni_pdp,0),0.0)+iif(d.bucket='Итоги',isnull(b.allGP_pdp,0),0.0)
		--,[Погашение Госпошлины ПДП]=iif(d.bucket='Итоги',isnull(b.allGP_pdp,0),0.0)
		,[Погашение ВСЕГО ПДП]=iif(d.bucket='Итоги',isnull(b.Itog_pdp,0),0.0)
--		,[Погашение ВСЕГО ПДП]=iif(d.bucket='Итоги',isnull(b.Itog_pdp,0),0.0)
		--
	from @datTab d
	 left join (
				--declare @repmonth date='2025-08-31'
				select 
					repdate
					,bucketBeginDay=iif(grouping(bucketBeginDay)=0,bucketBeginDay,'Итоги')
					,allSummIn=sum(summIn)
					,allOD=sum(summOD)
					,allPRC=sum(summPRC)
					,allPeni=sum(summPeni)
					,allGP=sum(summGP)
					,Itog=sum(summOD)+sum(summPRC)+sum(summPeni)+sum(summGP)
					
					,allOD_pp=sum(iif(pp=1,summOD,0))
					,allPRC_pp=sum(iif(pp=1,summPRC,0))
					,allPeni_pp=sum(iif(pp=1,summPeni,0))
					,allGP_pp=sum(iif(pp=1,summGP,0))
					,Itog_pp=sum(iif(pp=1,summOD,0))+sum(iif(pp=1,summPRC,0))+sum(iif(pp=1,summPeni,0))+sum(iif(pp=1,summGP,0))
					
					,allOD_pdp=sum(iif(pdp=1,summOD,0))
					,allPRC_pdp=sum(iif(pdp=1,summPRC,0))
					,allPeni_pdp=sum(iif(pdp=1,summPeni,0))
					,allGP_pdp=sum(iif(pdp=1,summGP,0))
					,Itog_pdp=sum(iif(pdp=1,summOD,0))+sum(iif(pdp=1,summPRC,0))+sum(iif(pdp=1,summPeni,0))+sum(iif(pdp=1,summGP,0))
			   from dwh2.finAnalytics.CashIn
			   where eomonth(REPDATE)=@repmonth
			   --month(repdate)=month(@repmonth)
			   group by rollup (
					repdate
					,bucketBeginDay
					)
			) b
				on  d.dat=b.repdate and d.bucket=b.bucketBeginDay
			order by d.dat, d.id
	

	
END

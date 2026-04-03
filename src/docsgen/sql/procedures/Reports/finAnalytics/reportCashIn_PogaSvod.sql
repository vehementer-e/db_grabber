



CREATE PROCEDURE [finAnalytics].[reportCashIn_PogaSvod]
	@repmonth date

AS
BEGIN
 --declare @repmonth date='2025-08-31'
 drop table if exists #bucket
	create table #bucket (
		id int
		,bucket_name varchar(20)
		,beginDay int
		,endDay int)
	insert into #bucket
		values
		  (1,'0',0,0)
		 ,(2,'1-90',1,90)
		 ,(3,'90+',91,999999)
--	select * from #bucket
	declare @countBuck int =(select count(*) from #bucket)

	declare @i int=1, @j int =1
	--создаем таблицу бакетов в разрезе по дням отчетного месяца 
	declare @datTab table (dat date, bucket varchar(20),beginday int, endday int, id int)
	while @i<=day(@repmonth)
		begin 
			while @j<=@countBuck+1
				begin
					insert into @datTab (dat,bucket,beginday,endday,id) values (
							DATEFROMPARTS(year(@repmonth),month(@repmonth),@i)
							,isnull((select bucket_name from #bucket where id=@j),'Итоги')
							,(select beginday from #bucket where id=@j)
							,(select endday from #bucket where id=@j)
							,@j)
					set @j+=1
				end
			set @i+=1
			set @j=1
		end
--select * from @datTab 
	select 
		[Дата]=d.dat
		,[Бакет]=d.bucket
		,[Поступлений всего]=isnull(b.allSummIn,0)
		,[Погашение ОД]=isnull(b.allOD,0)
		,[Погашение %%]=isnull(b.allPRC,0)
		,[Погашение Пени, Штрафы, Госпошлины]=isnull(b.allPeni,0)+isnull(b.allGP,0)
		--,[Погашение Госпошлины]=isnull(b.allGP,0)
		,[Погашение ВСЕГО]=isnull(b.Itog,0)

	--	,[Сальдо начальное]=iif(d.bucket='Итоги',lag(b.saldoAcc)over(partition by d.bucket order by d.dat),0)
	--	,[Сальдо конечное]=iif(d.bucket='Итоги',b.saldoAcc,0)

		,[Погашение ОД ПП]=isnull(b.allOD_pp,0)
		,[Погашение %% ПП]=isnull(b.allPRC_pp,0)
		,[Погашение Пени, Штрафы, Госпошлины ПП]=isnull(b.allPeni_pp,0)+isnull(b.allGP_pp,0)
		--,[Погашение Госпошлины ПП]=isnull(b.allGP_pp,0)
		,[Погашение ВСЕГО ПП]=isnull(b.Itog_pp,0)
		--выводи по ТЗ справочно поэтому только нужна строка по итогам за день 
		,[Погашение ОД ПДП]=iif(d.bucket='Итоги', isnull(b.allOD_pdp,0),0.0)
		,[Погашение %% ПДП]=iif(d.bucket='Итоги',isnull(b.allPRC_pdp,0),0.0)
		,[Погашение Пени, Штрафы, Госпошлины ПДП]=iif(d.bucket='Итоги',isnull(b.allPeni_pdp,0),0.0)+iif(d.bucket='Итоги',isnull(b.allGP_pdp,0),0.0)
		--,[Погашение Госпошлины ПДП]=iif(d.bucket='Итоги',isnull(b.allGP_pdp,0),0.0)
		,[Погашение ВСЕГО ПДП]=iif(d.bucket='Итоги',isnull(b.Itog_pdp,0),0.0)
		--
	from @datTab d
	 left join (
				--declare @repmonth date='2025-08-31'
			select
			--	saldoAcc=iif(b2.bucket='Итоги',sum(b2.allSaldo)over (partition by b2.bucket order by b2.repdate rows between UNBOUNDED PRECEDING and current row),b2.allSaldo)
				*
				from (
			--	declare @repmonth date='2025-08-31'
				select 
					repdate=b1.repdate
					,bucket=iif(grouping(b1.bucket)=0,b1.bucket,'Итоги')
				--	,allSaldo=sum(b1.saldo)
					--,allSummIn_Ces=sum(b1.summIn_Ces)
					,allSummIn=sum(b1.summIn)
					,allOD=sum(b1.summOD)
					,allPRC=sum(b1.summPRC)
					,allPeni=sum(b1.summPeni)
					,allGP=sum(b1.summGP)
					,Itog=sum(b1.summOD)+sum(b1.summPRC)+sum(b1.summPeni)+sum(b1.summGP)
					
					,allOD_pp=sum(iif(b1.pp=1,b1.summOD,0))
					,allPRC_pp=sum(iif(b1.pp=1,b1.summPRC,0))
					,allPeni_pp=sum(iif(b1.pp=1,b1.summPeni,0))
					,allGP_pp=sum(iif(b1.pp=1,b1.summGP,0))
					,Itog_pp=sum(iif(b1.pp=1,b1.summOD,0))+sum(iif(b1.pp=1,b1.summPRC,0))+sum(iif(b1.pp=1,b1.summPeni,0))+sum(iif(b1.pp=1,b1.summGP,0))
					
					,allOD_pdp=sum(iif(b1.pdp=1,b1.summOD,0))
					,allPRC_pdp=sum(iif(b1.pdp=1,b1.summPRC,0))
					,allPeni_pdp=sum(iif(b1.pdp=1,b1.summPeni,0))
					,allGP_pdp=sum(iif(b1.pdp=1,b1.summGP,0))
					,Itog_pdp=sum(iif(b1.pdp=1,b1.summOD,0))+sum(iif(b1.pdp=1,b1.summPRC,0))+sum(iif(b1.pdp=1,b1.summPeni,0))+sum(iif(b1.pdp=1,b1.summGP,0))
			   from 
					(select 
						bucket=(select bucket_name from #bucket where dpdBeginDay between beginday and endday)
						,*
		--				,saldo=(summIn-summCes)-summOD-summPRC-summPeni-summGP-summDop
					from dwh2.finAnalytics.CashIn) b1

			   where eomonth(b1.repdate)=@repmonth
			   --month(b1.repdate)=month(@repmonth)
			   group by rollup (
					b1.repdate
					,b1.bucket
					)
				)b2 where b2.repdate is not null
			) b

				on  d.dat=b.repdate and d.bucket=b.bucket
			order by d.dat, d.id



END

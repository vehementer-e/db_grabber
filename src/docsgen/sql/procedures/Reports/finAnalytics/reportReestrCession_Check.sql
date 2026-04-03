





CREATE PROCEDURE [finAnalytics].[reportReestrCession_Check]
		@startDate date, @endDate date
AS
BEGIN
	;with cte_reg as (
			select
				[Дата Цессии]=repdate
				,[Кол-во договоров]=count(*)  
			from dwh2.finAnalytics.ReestrCession
			where repdate between @startDate and @endDate 
			group by repdate

			),
		cte_bnfo as(
			select
			[Дата Цессии]=l1.dat
			,[Кол-во договоров]=count(*)
			from (
				select 
					dat=dateadd(year,-2000,cast(a.Период as date))
					,numdog=d.Номер
				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов d on a.СубконтоDt2_Ссылка=d.Ссылка and d.ПометкаУдаления=0
				left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов mem on a.СубконтоDt3_Ссылка=mem.Ссылка 
				where a.Активность=0x01
					and (b.Код='61217' and c.Код in ('48801','48802','60323'))
					and upper(mem.Имя)=upper('ПередачаПравТребований')
					and dateadd(year,-2000,cast(a.Период as date)) between @startDate and @endDate 
				group by  dateadd(year,-2000,cast(a.Период as date)),d.Номер
				)l1
			group by l1.dat
		)

	select 
		[Дата Цессии]=reg.[Дата Цессии]
		,[Реестр Кол-во договоров]=reg.[Кол-во договоров]
		,[БНФО Кол-во договоров]=bnfo.[Кол-во договоров]
		,flag=iif(isnull(reg.[Кол-во договоров],0)!=isnull(bnfo.[Кол-во договоров],0),1,0)
	from cte_reg reg
	left join cte_bnfo bnfo on reg.[Дата Цессии]=bnfo.[Дата Цессии]
	order by reg.[Дата Цессии]
	
END

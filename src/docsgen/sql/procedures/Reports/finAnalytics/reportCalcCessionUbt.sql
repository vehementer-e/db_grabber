
CREATE PROCEDURE [finAnalytics].[reportCalcCessionUbt]
	@repYear int
AS
BEGIN
	declare @maxprc float = 150.00
	declare @countDayYear int =datepart (dayofyear, datefromparts(@repYear,'12','31'))
	;with #ReestrCession as
		(
		select
		 [Дата договора цессии]=a.dogCesionaryDate
		  ,[Номер договора цессии]=dogCesionary
		  ,[Наименование цессионария]=Cesionary
		  ,[ИНН цессионария]=c.ИНН
		  ,[Факт дата выбытия]=repdate
		  ,[Номер договора займа]=a.dogClient
		  ,[ФИО клиента]=Client
		  ,[Общая сумма по договору цессии]=ZadolgAll
		  ,[Доход от уступки требования]=viruchka
		  ,[Убыток БУ]=ZadolgAll-viruchka
		  ,[Дата выдачи займа]=dogClientDate
		  ,[Дата окончания договора]=nz.endDate
		  ,[Дней с даты уступки до даты окончания договора]=datediff(day,repdate,nz.endDate)
		  ,[Сумма предельного убытка в НУ]=''

		  ,[Корректировка регистра(не учитывается)]= ''

		  ,[Ключевая ставка ЦБ]=(select top(1) Процент from stg.[_1cUMFO].[РегистрСведений_АЭ_ЗначенияВидовПроцентныхСтавок] 
									where dateadd(year,-2000,cast(Период as date))<=a.dogCesionaryDate order by Период desc)
		  ,[Максимальное значение %% ставки рефинанс.ЦБ]=@maxprc
		  ,[Предельная  %% ставка]=(@maxprc*(select top(1) Процент from stg.[_1cUMFO].[РегистрСведений_АЭ_ЗначенияВидовПроцентныхСтавок] 
									where dateadd(year,-2000,cast(Период as date))<=a.dogCesionaryDate order by Период desc))/100
	
		from [dwh2].[finAnalytics].[ReestrCession] a
		left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов d on a.dogCesionaryNum=d.Номер and a.dogCesionaryDate=dateadd(year,-2000,cast(d.Дата as date))
		left join stg._1cUMFO.Справочник_Контрагенты c on d.Владелец=c.Ссылка
		left join 
			(
			select 
				l1.dogClient
				,l1.endDate
			from (
				select 
					rn=row_number()over(partition by a.ДоговорКонтрагента order by a.Период desc)
					,dogClient=c.Номер
					,endDate=dateadd(year,-2000,cast(a.ДатаОкончания as date))
				from  stg._1cUMFO.РегистрСведений_АЭ_ЗаймыПредоставленные a
				left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов c on a.ДоговорКонтрагента=c.Ссылка
				where a.Активность=0x01
				) l1
			where l1.rn=1
			) nz on  a.dogClient=nz.dogClient
		where year(a.dogCesionaryDate)=@repYear
		and nz.endDate>a.dogCesionaryDate
		--костыль. РегистрСведений_АЭ_ЗаймыПредоставленные присутвует информация о допсоглашении, однако , согласно данным 1С, допосоглашения все удалены 
		--Договор 25053123390403 от 31.05.2025г
		and nz.dogClient!= '25053123390403'
	)
	select 
		  [Дата договора цессии]
		  ,[Номер договора цессии]
		  ,[Наименование цессионария]
		  ,[ИНН цессионария]
		  ,[Факт дата выбытия]
		  ,[Номер договора займа]
		  ,[ФИО клиента]
		  ,[Общая сумма по договору цессии]
		  ,[Доход от уступки требования]
		  ,[Убыток БУ]
		  ,[Дата выдачи займа]
		  ,[Дата окончания договора]
		  ,[Дней с даты уступки до даты окончания договора]
		  ,[Сумма предельного убытка в НУ]=([Доход от уступки требования]*[Дней с даты уступки до даты окончания договора]*[Предельная  %% ставка]/@countDayYear)/100
		  ,[Корректировка регистра(не учитывается)]=
				iif((([Доход от уступки требования]*[Дней с даты уступки до даты окончания договора]*[Предельная  %% ставка]/@countDayYear))/100-[Убыток БУ]<0
					,(([Доход от уступки требования]*[Дней с даты уступки до даты окончания договора]*[Предельная  %% ставка]/@countDayYear))/100-[Убыток БУ]
					,0)

		  ,[Ключевая ставка ЦБ]
		  ,[Максимальное значение %% ставки рефинанс.ЦБ]
		  ,[Предельная  %% ставка]
	from #ReestrCession
	order by [Дата договора цессии]

END

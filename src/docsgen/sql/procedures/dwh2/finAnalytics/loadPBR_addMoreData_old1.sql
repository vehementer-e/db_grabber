

CREATE   PROCEDURE [finAnalytics].[loadPBR_addMoreData]
		@nameData varchar(20),
		@repmonth date
--@nameData переменная может пренимать значения 'monthly' или 'weekly'

AS
BEGIN
	set @nameData =trim(@nameData)
	declare @procStr nvarchar(300) = null
	
	if @nameData='monthly' 
	begin

	--Обновление данных из заявок источник Петра Ильина
	merge into dwh2.[finAnalytics].[PBR_MONTHLY] t1
	using(
	select
	[dogNum] = b.Номер
	--,[isnew] = case when b.isnew = 1 then 'Новый'
	--					when b.isnew = 0 then 'Повторный'
	--					else '-'
	--					end
	,[isnew] = b.returnType
	,[finChannelGroup] = b.finChannelGroup
	,[finChannel] = b.finChannel
	,[finBusinessLine] = b.finBusinessLine
	,[prodFirst] = null
	,[productType] = b.productType
	,[RN] = ROW_NUMBER() over (Partition by b.Номер order by b.Номер)
	from [Analytics].dbo.[v_fa] b
	) t2 on (t1.dogNum=t2.dogNum and t1.repmonth = @repmonth and t2.rn=1)
	when matched then update
	set t1.isnew = t2.isnew
		,t1.finChannelGroup = t2.finChannelGroup
		,t1.finChannel = t2.finChannel
		,t1.finBusinessLine = t2.finBusinessLine
		--,t1.prodFirst = t2.prodFirst
		,t1.productType = t2.productType;

	--Обновление данных Первичный продукт источник Толя
	merge into dwh2.[finAnalytics].[PBR_MONTHLY] t1
	using(
	select
		l1.client
		,l1.dogNum
		,l1.prod
		,l1.subprod
		,l1.dogDate
		,l1.dogCloseDate
		,dogRN =  ROW_NUMBER() over (Partition by l1.client order by l1.dogDate)
		from(
		select 
			dogNum = cldog.КодДоговораЗайма
			,prod = case 
							when dog.ТипПродукта in ('ПТС31') then 'ПТС'
							when dog.ТипПродукта in ('Смарт-инстоллмент','Инстоллмент') then 'Installment'
							when dog.ПодТипПродукта in ('ПТС (Автокред)') then 'Автокредит'
							when dog.ПодТипПродукта in ('ПТС Займ для Самозанятых') then 'ПТС для Самозанятых'
							else dog.ТипПродукта
							end
			,subprod = dog.ПодТипПродукта
			,dogDate = dog.ДатаДоговораЗайма--cast(dog.ДатаДоговораЗайма as date)
			,dogCloseDate = cast(dog.ДатаЗакрытияДоговора as date)
			,cldog.GuidКлиент
			,[client] = concat(
						cl.Наименование
						,' '
						,format(cl.ДатаРождения,'dd.MM.yyyy')
						)
		from dwh2.link.Клиент_ДоговорЗайма cldog
		inner join dwh2.hub.ДоговорЗайма dog on dog.КодДоговораЗайма = cldog.КодДоговораЗайма
		inner join dwh2.hub.Клиенты cl on cl.GuidКлиент = cldog.GuidКлиент
		where dog.isDelete = 0
		) l1
	) t2 on (t1.client=t2.client and t1.repmonth = @repmonth and t2.dogRN = 1)
	when matched then update
	set t1.prodFirst = t2.prod;

	/*Расчет среднедневного остатка для Фондирования*/
		declare @repmonthTmp date = dateadd(year,2000,@repmonth)
		declare @repMonthDays int = day(eomonth(@repmonth))

		declare @dateFromTmp date = dateadd(day,-1,@repmonthTmp)
		declare @dateFrom datetime = cast(@dateFromTmp as datetime)

		declare @dateToTmp date = dateadd(day,-1,eomonth(@repmonthTmp))
		declare @dateTo datetime = cast(@dateToTmp as datetime)

		--select @dateFrom, @dateTo
		merge into dwh2.finAnalytics.pbr_monthly t1
		using(
		select
		b.dayRestAVG
		,a.dogNum

		from dwh2.finAnalytics.pbr_monthly a
		left join (
		select
		dogNum = l1.НомерДоговора
		,dayRestAVG = sum(l1.ОстатокОДвсего) / @repMonthDays
		from(
		select
		ДатаОтчета = dateadd(year,-2000,ДатаОтчета)
		,НомерДоговора
		,ОстатокОДвсего = ОстатокОДвсего
		from stg.[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]
		where ДатаОтчета between @dateFrom and @dateTo
		--order by НомерДоговора,ДатаОтчета
		) l1
		group by l1.НомерДоговора
		) b on a.dogNum = b.dogNum

		where a.repmonth = @repmonth
		) t2 on (t1.repmonth = @repmonth and t1.dogNum = t2.dogNum)
		when matched then update
		set t1.[dayRestAVG] = isnull(t2.dayRestAVG,0);

	--/*Данные по RBP старый вариант*/
	--merge into dwh2.[finAnalytics].[PBR_MONTHLY] t1
	--using(
	--select
	--number	
	--,rbp_gr
	--from(
	--select 
	--number	
	--,rbp_gr	
	--,client_type
	--,rn = ROW_NUMBER() over (Partition by number order by number)
	--from dwh2.[dbo].[v_risk_apr_segment]
	--where rbp_gr is not null
	--) l1
	--where l1.rn =1
	--) t2 on ( t1.dogNum = t2.number and t1.[RBP_GROUP] is null) 
	--when matched then update
	--set t1.[RBP_GROUP] = t2.rbp_gr;

	/*Данные по RBP новый вариант*/
	merge into dwh2.[finAnalytics].[PBR_MONTHLY] t1
	using(
		 select
		 [НомерЗаявки]
		 ,RBP_GR
		 from(
		 select 
		 [НомерЗаявки]
		 ,RBP_GR
		 ,rn = row_Number() over (Partition by [НомерЗаявки] order by created_at)
		  from dwh2.dm.ЗаявкаНаЗаймПодПТС
		  where [НомерЗаявки] is not null
		  and RBP_GR is not null
		  ) l1
		  where l1.rn =1
	) t2 on ( t1.dogNum = t2.[НомерЗаявки] and t1.[RBP_GROUP] is null) 
	when matched then update
	set t1.[RBP_GROUP] = t2.RBP_GR;


	end
		
			
	if @nameData='weekly' 
	begin

	--Обновление данных из заявок источник Петра Ильина
	merge into dwh2.[finAnalytics].[PBR_weekly] t1
	using(
	select
	[dogNum] = b.Номер
	--,[isnew] = case when b.isnew = 1 then 'Новый'
	--					when b.isnew = 0 then 'Повторный'
	--					else '-'
	--					end
	,[isnew] = b.returnType
	,[finChannelGroup] = b.finChannelGroup
	,[finChannel] = b.finChannel
	,[finBusinessLine] = b.finBusinessLine
	,[prodFirst] = null
	,[productType] = b.productType
	,[RN] = ROW_NUMBER() over (Partition by b.Номер order by b.Номер)
	from [Analytics].dbo.[v_fa] b
	) t2 on (t1.dogNum=t2.dogNum and t1.repdate = @repmonth and t2.rn=1)
	when matched then update
	set t1.isnew = t2.isnew
		,t1.finChannelGroup = t2.finChannelGroup
		,t1.finChannel = t2.finChannel
		,t1.finBusinessLine = t2.finBusinessLine
		,t1.prodFirst = t2.prodFirst
		,t1.productType = t2.productType;

	--Обновление данных Первичный продукт источник Толя
	merge into dwh2.[finAnalytics].[PBR_weekly] t1
	using(
	select
		l1.client
		,l1.dogNum
		,l1.prod
		,l1.subprod
		,l1.dogDate
		,l1.dogCloseDate
		,dogRN =  ROW_NUMBER() over (Partition by l1.client order by l1.dogDate)
		from(
		select 
			dogNum = cldog.КодДоговораЗайма
			,prod = case 
							when dog.ТипПродукта in ('ПТС31') then 'ПТС'
							when dog.ТипПродукта in ('Смарт-инстоллмент','Инстоллмент') then 'Installment'
							when dog.ПодТипПродукта in ('ПТС (Автокред)') then 'Автокредит'
							when dog.ПодТипПродукта in ('ПТС Займ для Самозанятых') then 'ПТС для Самозанятых'
							else dog.ТипПродукта
							end
			,subprod = dog.ПодТипПродукта
			,dogDate = dog.ДатаДоговораЗайма--cast(dog.ДатаДоговораЗайма as date)
			,dogCloseDate = cast(dog.ДатаЗакрытияДоговора as date)
			,cldog.GuidКлиент
			,[client] = concat(
						cl.Наименование
						,' '
						,format(cl.ДатаРождения,'dd.MM.yyyy')
						)
		from dwh2.link.Клиент_ДоговорЗайма cldog
		inner join dwh2.hub.ДоговорЗайма dog on dog.КодДоговораЗайма = cldog.КодДоговораЗайма
		inner join dwh2.hub.Клиенты cl on cl.GuidКлиент = cldog.GuidКлиент
		where dog.isDelete = 0
		) l1
	) t2 on (t1.client=t2.client and t1.repdate = @repmonth and t2.dogRN = 1)
	when matched then update
	set t1.prodFirst = t2.prod;

	--/*Обновление данных по RBP старый вариант*/
	--merge into dwh2.[finAnalytics].[PBR_WEEKLY] t1
	--using(
	--select
	--number	
	--,rbp_gr
	--from(
	--select 
	--number	
	--,rbp_gr	
	--,client_type
	--,rn = ROW_NUMBER() over (Partition by number order by number)
	--from dwh2.[dbo].[v_risk_apr_segment]
	--where rbp_gr is not null
	--) l1
	--where l1.rn =1
	--) t2 on ( t1.dogNum = t2.number and t1.[RBP_GROUP] is null) 
	--when matched then update
	--set t1.[RBP_GROUP] = t2.rbp_gr;

	/*Данные по RBP новый вариант*/
	merge into dwh2.[finAnalytics].PBR_WEEKLY t1
	using(
		 select
		 [НомерЗаявки]
		 ,RBP_GR
		 from(
		 select 
		 [НомерЗаявки]
		 ,RBP_GR
		 ,rn = row_Number() over (Partition by [НомерЗаявки] order by created_at)
		  from dwh2.dm.ЗаявкаНаЗаймПодПТС
		  where [НомерЗаявки] is not null
		  and RBP_GR is not null
		  ) l1
		  where l1.rn =1
	) t2 on ( t1.dogNum = t2.[НомерЗаявки] and t1.[RBP_GROUP] is null) 
	when matched then update
	set t1.[RBP_GROUP] = t2.RBP_GR;

	end	

END

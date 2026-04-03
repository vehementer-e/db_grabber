
CREATE PROCEDURE [finAnalytics].[calcRep840_1]
	@repmonth date,
	@calcSelector int --выбор подраздела для расчета

AS
BEGIN

	declare @clientList table(
	client nvarchar(300) not null,
	restAll float not null,
	rowNum int not null
	)

	if @calcSelector = 1 --Расчте подраздела 4
	begin

	delete from @clientList
	insert into @clientList
	select top(5)
	[client]
	,[restAll] 
	,rn = ROW_NUMBER() over (order by [restAll] desc)
	from(
	select
	[client] = a.client
	,[restAll] = sum(isnull(a.restOD,0) + isnull(a.restPRC,0)) 
	from dwh2.finAnalytics.DEPO_MONTHLY a
	where repmonth = @repmonth
	group by a.client
	) l1
	order by restAll desc

	--select * from @clientList
	delete from dwh2.[finAnalytics].[rep840_1_4] where REPMONTH=@repmonth

	insert into dwh2.[finAnalytics].[rep840_1_4]

	select
	[repmonth] = a.repmonth
	,[client] = case when cl.АЭ_ПолноеНаименование = '' then cl.НаименованиеПолное else cl.АЭ_ПолноеНаименование end
	,[INN] = a.INN
	,[OGRN] = cl.РегистрационныйНомер
	,[dogNum] = a.dogNum
	,[restAll] = isnull(a.restOD,0) + isnull(a.restPRC,0)
	,[StavkaRepDate] = a.StavkaRepDate
	,[rn] = b.rowNum
	from dwh2.finAnalytics.DEPO_MONTHLY a
	inner join @clientList b on a.client=b.client
	left join (
	select 
	b.ИНН
	,b.РегистрационныйНомер
	,b.НаименованиеПолное
	,b.АЭ_ПолноеНаименование
	,rn = ROW_NUMBER() over (partition by b.ИНН order by b.ИНН)
	from  stg._1cUMFO.Справочник_Контрагенты b 
	where b.РегистрационныйНомер is not null
	) cl on a.INN=cl.ИНН  and cl.rn=1

	where repmonth = @repmonth
	order by b.rowNum

	end

	if @calcSelector = 2 --Расчте подраздела 6
	begin

	delete from @clientList
	insert into @clientList
	select top(5)
	[client]
	,[restAll] 
	,rn = ROW_NUMBER() over (order by [restAll] desc)
	from(
	select
	[client] = a.client
	,[restAll] = sum(isnull(a.[zadolgOD],0) + isnull(a.[zadolgPrc],0)+ isnull(a.[penyaSum],0)) 
	from dwh2.[finAnalytics].[PBR_MONTHLY] a
	where repmonth = @repmonth
	group by a.client
	) l1
	order by restAll desc

	--select * from @clientList

	delete from dwh2.[finAnalytics].[rep840_1_6] where REPMONTH=@repmonth

	insert into dwh2.[finAnalytics].[rep840_1_6]

	select
	[repmonth] = a.repmonth
	,[client] = case when cl.АЭ_ПолноеНаименование = '' then cl.НаименованиеПолное else cl.АЭ_ПолноеНаименование end
	,[INN] = a.INN
	,[OGRN] = cl.РегистрационныйНомер
	,[dogNum] = a.dogNum
	,[restOD] = isnull(a.[zadolgOD],0)
	,[restPRC] = isnull(a.[zadolgPrc],0)
	,[restPenya] = isnull(a.[penyaSum],0)
	,[rn] = b.rowNum
	from dwh2.[finAnalytics].[PBR_MONTHLY] a
	inner join @clientList b on a.client=b.client
	left join (
	select 
	b.ИНН
	,b.РегистрационныйНомер
	,b.НаименованиеПолное
	,b.АЭ_ПолноеНаименование
	,rn = ROW_NUMBER() over (partition by b.ИНН order by b.ИНН)
	from  stg._1cUMFO.Справочник_Контрагенты b 
	where b.РегистрационныйНомер is not null
	) cl on a.INN=cl.ИНН  and cl.rn=1

	where repmonth = @repmonth
	order by b.rowNum


	end

END

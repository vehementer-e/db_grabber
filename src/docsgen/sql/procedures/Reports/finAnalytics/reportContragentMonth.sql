



CREATE PROCEDURE [finAnalytics].[reportContragentMonth]
	
AS
BEGIN
	declare @repyear int=year(getdate())
	drop table if exists #reestr
	select
		*
	into #reestr
	from [dwh2].[finAnalytics].[Reestr20501]
	where year(repdate) in (@repyear,@repyear-1)

	drop table if exists #contragent
	create table #contragent (innClient nvarchar(12),client nvarchar(500))
	insert into #contragent (innClient,client)
		select
			l1.innClient
		,trim(l1.Client)
		from (
		select
			innClient
			,Client
			,rn=row_number()over(partition by innClient order by year(repdate) desc)
		from #reestr
		where 
			typeclient in ('ИП','ЮЛ')
			and innClient is not null 
			and Client is not null
			and substring(trim(Client),1,3)!='УФК')l1
		where l1.rn=1
		union all
		select
			innClient
		,trim(Client)
		from #reestr
		where 
		typeclient in ('ИП','ЮЛ')
		and innClient is not null 
		and Client is not null
		and substring(trim(Client),1,3)='УФК'
	
	drop table if exists #previsionYearInn
	select
		distinct
		a.innClient
	into #previsionYearInn
	from #contragent a
	left join #reestr b on a.innClient=b.innClient
	where year(repdate)=@repyear-1
--declare @repyear int=year(getdate())
select
	[Отчетный месяц]=format(dateadd(day,1,eomonth(b.repdate,-1)),'MMMM yyyy','Ru-ru')
	--[Отчетная дата]=dateadd(day,1,eomonth(b.repdate,-1))
	,[Номер месяца]=month(b.repdate)
	,Контрагент=a.client
	,ИНН=a.innClient
	,flag=iif(c.innClient is null,1,0)
from #contragent a
left join #reestr b on a.innClient=b.innClient
left join #previsionYearInn c on a.innClient=c.innClient
where year(b.repdate)=@repyear
group by 
	 a.client
	,a.innClient
	,dateadd(day,1,eomonth(b.repdate,-1))
	,month(b.repdate)
	,iif(c.innClient is null,1,0)	

END

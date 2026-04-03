


CREATE PROCEDURE [finAnalytics].[reportContragent]
	
AS
BEGIN
	declare @repyear int=year(getdate())
	drop table if exists #reestr
	select
		*
	into #reestr
	from [dwh2].[finAnalytics].[Reestr20501]
	where year(repdate) in (@repyear,@repyear-1)
	----


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
	
	drop table if exists #svod
	select 
		innClient=a.innClient
		,client=a.client
		,repyear=year(b.repdate)
		,outSumm=sum(b.outSumm)
	into #svod
	from #contragent a
	left join #reestr b on a.innClient=b.innClient
	group by a.innClient,a.client,year(b.repdate)
	
select 
	Год=s.repyear
	,Дата=b.repdate
	,Контрагент=a.client
	,ИНН=a.innClient
	,Списание=b.outSumm
	,[Назначение платежа]=b.purPay
	,[Вид платежа]=b.typeOperation
	,[Общее списание за год]=s.outSumm
from #contragent a 
left join #reestr b on a.innClient=b.innClient
left join #svod s on a.innClient=s.innClient and year(b.repdate)=s.repyear and a.client=s.client

END

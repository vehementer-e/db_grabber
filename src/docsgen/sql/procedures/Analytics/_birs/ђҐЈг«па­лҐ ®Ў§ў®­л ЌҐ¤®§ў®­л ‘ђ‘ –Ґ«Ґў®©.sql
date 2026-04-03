
CREATE   proc [_birs].[Регулярные обзвоны Недозвоны СРС Целевой]

@datefrom date = null	,
@dateto date = null

as

begin


declare @datefrom_ date = @datefrom
declare @dateto_ date = @dateto
	

--declare @datefrom_ date = getdate()-30 declare @dateto_ date = getdate()-1
	
	
drop table if exists #leads	
	
	
select cast(ID as varchar(36)) ID ,
case
when [Канал от источника] = 'CPA целевой' then  'CPA целевой'
when [Группа каналов] = 'CPC' then   'CPC'
when [Группа каналов] = 'Органика' then   'Органика'
end 'Канал'
, uf_regions_composite
, uf_registered_at
, is_inst_lead
into #leads	
from [Feodor].[dbo].[dm_leads_history_light] --(nolock)	
where ДатаЛидаЛСРМ between @datefrom_ 	and  isnull(@dateto_, getdate()-1)
	  	and   [Канал от источника] 	  in
	(
 'CPA целевой'
,'CPC Бренд'
,'CPC Платный'
,'Медийная реклама'
, 'Сайт орган.трафик'
, 'Канал привлечения не определен - КЦ'
, 'Канал привлечения не определен - МП'



)

	and is_inst_lead = 0
	and uuid is not null


--	select * from stg.files.leadref1_buffer		  where [Группа каналов]='Органика'


insert into #leads 	
	
select ID,
case
when [Канал от источника] = 'CPA целевой' then  'CPA целевой'
when [Группа каналов] = 'CPC' then   'CPC'
when [Группа каналов] = 'Органика' then   'Органика'
end 'Канал'
, uf_regions_composite
, uf_registered_at
, is_inst_lead		   
from [Feodor].[dbo].lead --(nolock)	
where cast(uf_registered_at as date) between @datefrom_ 	and  isnull(@dateto_, getdate()-1)
	  	and   [Канал от источника] 	  in
	(
 'CPA целевой'
,'CPC Бренд'
,'CPC Платный'
,'Медийная реклама'
, 'Сайт орган.трафик'
, 'Канал привлечения не определен - КЦ'
, 'Канал привлечения не определен - МП'



)


	and is_inst_lead = 0
	and uuid is not null



	

--declare @datefrom_ date = getdate()-1 declare @dateto_ date = getdate()-1


drop table if exists #t	
	
SELECT 	
	c.attempt_start, 
	c.login,
	c.phonenumbers,
	c.timezone,
	c.title,
	cast(c.lcrm_id as nvarchar(36))  lcrm_id,
	f.*
into #t	
FROM [Feodor].[dbo].[dm_calls_history] c (nolock)	
join #leads  f (nolock) on c.lcrm_id = f.ID	  and isnumeric(f.id)=1
WHERE  c.attempt_start >= @datefrom_	
	

insert into #t
SELECT 	
	c.attempt_start, 
	c.login,
	c.phonenumbers,
	c.timezone,
	c.title,
	c.lead_id,
	f.*
--into #t	
FROM [Feodor].[dbo].[dm_calls_history_lf] c (nolock)	
join #leads  f (nolock) on c.lead_id = f.ID	
WHERE  c.attempt_start >= @datefrom_	
	


drop table if exists #fa	
	
select	
	'8' + Телефон 'Телефон',
	ДатаЗаявкиПолная
into #fa	
from Reports.dbo.dm_Factor_Analysis_001 	
where ДатаЗаявкиПолная >=  @datefrom_		

   
																			
drop table if exists #bl
select cast('8'+phone  as nvarchar(11)) phone into #bl from stg.[_1cCRM].[BlackPhoneList]


	
drop table if exists #t1	
select *
into #t1	

from (	
SELECT row_number() over (partition BY phonenumbers order by attempt_start desc) Попытка,	
	t.*	 
	
FROM #t t 
) x  	
left join #fa fa on x.phonenumbers = fa.Телефон	  and fa.ДатаЗаявкиПолная>  x.attempt_start
where fa.Телефон is null
and x.phonenumbers not in (select *  from #bl)		
and x.login is null and x.Попытка=1
	

	
select  
right(a.phonenumbers, 10)  phonenumbers,	
a.uf_registered_at,	
a.attempt_start,	
a.timezone,	
a.title,
a.lcrm_id,
a.uf_regions_composite,
a.Канал,
b.capital,
a.is_inst_lead
--into #t2
from #t1 a
left join v_gmt b on a.uf_regions_composite=b.region
where 1=0

 --exec create_table '#t2'


end
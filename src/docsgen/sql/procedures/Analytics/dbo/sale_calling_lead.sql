
CREATE     proc [dbo].[sale_calling_lead]

@datefrom date = null	,
@dateto date = null     ,
@channel nvarchar(max) =  null  


as
 

declare @datefrom_ date = @datefrom
declare @dateto_ date = @dateto
	


--declare @datefrom_ date = getdate()-30 declare @dateto_ date = getdate()-1 declare @channel  nvarchar(max) =  'CPC платный'
	
	

drop table if exists #c

SELECT trim(value) channel into #c FROM STRING_SPLIT(@channel, ',') 
drop table if exists #leads	
	 
	
select a.ID
, a.channel  
, a.uf_regions_composite
, a.created
, a.source	
, a.[Результат коммуникации]
, a.uuid
, a.decline
, a.status
, a.phone

 into   #leads 	
from v_lead2 a
join #c c on a.channel=c.channel
where cast(created as date) between @datefrom_ 	and  isnull(@dateto_, getdate()-1)
--and uuid is not null
 


	

--declare @datefrom_ date = getdate()-1 declare @dateto_ date = getdate()-1


drop table if exists #t	
 
SELECT 	
	c.created callCreated, 
	c.login,
	--c.phone,
	c.timezone,
	c.title,
	f.ID lead_id,
	c.attempt_result , 
	
	f.*

into #t	
FROM #leads f	
left join     v_lead_call c (nolock)  on c.lead_id = f.ID	
 and c.created >= @datefrom_	
	


drop table if exists #fa	
	
select	
	phone,
	created
into #fa	
from v_fa
where created >=  @datefrom_		

   
																			
drop table if exists #bl
select   phone into #bl from v_blacklist
group by phone


	
drop table if exists #t1	
select x.*
into #t1	

from (	
SELECT 
	t.*	 
	, row_number() over (partition BY phone  order by callCreated desc) rnLatCall
FROM #t t 
) x  	
left join #fa fa on x.phone = fa.phone	  and fa.created>x.created
where fa.phone is null
and x.phone not in (select *  from #bl)		
and x.rnLatCall=1
	

	
select  
phone   ,	
a.created,	
a.callCreated,	
a.timezone,	
a.title,
a.lead_id,
a.uf_regions_composite,
a.channel,
a.source,
b.capital, 
case
when a.uuid  is  null then 'Нет кейса' + isnull(' ('+status + isnull(' '+ decline, '')+')', ' (UNKNOWN_STATUS)' )
when a.login is  null then 'Недозвон'
else a.attempt_result end attempt_result_naumen ,
[Результат коммуникации] attemp_result_feodor 
--into #t2
from #t1 a
left join v_gmt b on a.uf_regions_composite=b.region

 
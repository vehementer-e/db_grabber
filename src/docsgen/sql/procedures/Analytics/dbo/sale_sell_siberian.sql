 CREATE            proc [dbo].[sale_sell_siberian] as
 
--exec sp_create_job 'Analytics._![Продажа трафика Сибиряк]]! Daily at 09:58' , '[sale_sell_siberian]', '1' , '100000'

drop table if exists #fa

select number
 ,      productType
,      phone  
,      declined
,      region  
,      link

 ,      created
,      cancelled
,      approved
,      issued
, firstSum
, returnType
, source
, carBrand, carModel, carYear, call1approved, channel
, fio fio
   into #fa
from _request a

where created>=getdate()-60 or issued is not null

create nonclustered index t on #fa
(
phone, created, number
)

drop table if exists #t1
select a. number 
,      a.firstSum
,      phone
,      returnType
,      channelGroup
,      source 
,      declined
,      region 
,     cast( a.productType as varchar(255)) productType
, cast('Отказано' as varchar(255)) status
--, isnull( carBrand, '') + isnull(' '+carModel, '')+isnull(' '+try_cast(carYear  as  varchar(10)), '0') carInfo
 , fio  fio
 , created as requestCreated
	into #t1
from      #fa                                                                  a
left join channel b on a.channel=b.channel

where declined >= cast(getdate()-1 as date) 
and call1approved is null
--and Дубль=1								
--and isInstallment=0								
and a.productType in ('PTS')
and returnType = 'Первичный'								
and b.channelGroup <> 'Партнеры'								
and  a.source       not in (								
'devtek'								
,'gidfinance-installment'								
,'bankiru-installment'								
,'bankiru-installment-ref'								
,'gidfinance'								
,'leadcraft-installment-ref'								
,'leadcraft-ref'								
,'unicom24r'								
,'unicom24'								
,'unicom24-installment-ref'								
,'sravniru'								
,'sravniru-installment-ref'	
, 'avtolombard-credit'
,'avtolombard-credit-ref'

,'psb-ref'
,'vtb-ref'
,'infoseti-deepapi-pts' 
,'infoseti-deepapi-installment' 
,'infoseti'
,'psb-deepapi'
)	
--and region in (
-- 'Москва'
--,'Московская обл'
--,'Приморский край'
--,'Воронежская обл'
--,'Свердловская обл'
--,'Иркутская обл'
--,'Татарстан Респ'
--,'Нижегородская обл'
--,'Ростовская обл'
--,'Ленинградская обл'
--,'Санкт-Петербург'
--,'Самарская обл'


--)
and a.source not like '%bankiru%'
and  a.source  not in (select [Источник трафика] from source_block_sell where [Источник трафика] is not null)
 and declined>='2025-10-05 00:00:00'

drop table if exists #lead
select id, phone, created, decline status into #lead from v_lead2 a

where  created>=cast(getdate()-1 as date)  	
and decline = 'Отказ preCall1'
and created>='2025-10-05 00:00:00'
and source       not in (								
'devtek'								
,'gidfinance-installment'								
,'bankiru-installment'								
,'bankiru-installment-ref'								
,'gidfinance'								
,'leadcraft-installment-ref'								
,'leadcraft-ref'								
,'unicom24r'								
,'unicom24'								
,'unicom24-installment-ref'								
,'sravniru'								
,'sravniru-installment-ref'	
, 'avtolombard-credit'
,'avtolombard-credit-ref'

,'psb-ref'
,'vtb-ref'
,'infoseti-deepapi-pts' 
,'infoseti-deepapi-installment' 
,'infoseti'
,'psb-deepapi'
)	
and  a.source  not in (select [Источник трафика] from source_block_sell where [Источник трафика] is not null)
and a.is_inst_lead=0
  

  --insert into #lead
  --select id , phone, created, ПричинаНепрофильности status from v_lead2

  --where source =  'infoseti-deepapi-pts'  and created>=cast(getdate()-1 as date)  	
  --and ПричинаНепрофильности in (
  --'Неактуально / не нужны деньги',
  --'Нужна бОльшая сумма',
  --'Нет авто',
  --'Ищет в банке',
  --'Вне зоны присутсвия бизнеса' )
  --and created>='2025-06-27 13:50:00'
  --and 1=0
   

  drop table if exists #lead2 
  select a.id , b.sum , a.phone, b.productType, a.created, a.status   into #lead2 from #lead a 
  join v_request_external b on a.id=b.id



   
 insert into #t1 ([number], firstSum, [phone], declined, [productType] , status, requestCreated )
 select id, isnull( sum, 100000)sum  , phone, created,isnull(productType, ''),   status, created  from #lead2
 





drop table if exists #for_sale
								
;								
								
with v as (								
select a.phone, a.firstSum   ,a.region  , --a.Марка, a.Модель, a.ГодВыпуска, 
a.number,  a.declined, ROW_NUMBER() over(partition by a.phone order by a.declined) rn
, a.productType
, a.status
--, a.carInfo
, a.fio
, a.requestCreated
from #t1 a								
left join #fa x on x.created between dateadd(day, -8, a.declined ) and  dateadd(day, 8, a.declined ) and a.number<>x.number and  a.phone=x.phone and x.cancelled is null  and x.declined is null  and x.approved is null 								
left join #fa x1 on a.phone=x1.phone and  x1.issued is not null 							
left join #fa x2 on a.phone=x2.phone and  x2.approved >=dateadd(day, -30 , a.declined)  							
left join  mv_loans b on a.phone=b.[Основной телефон клиента CRM]								
left join  mv_loans b1 on a.phone=b1.[Телефон договор CMR]			
 left join  sale_sell_siberian_log p on p.phone=a.phone and p.created>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.number is  null and								
x2.number is  null and								
x1.number is  null 	
 and	 p.phone is  null 							
								
)								
select cast( newid() as  varchar(36)) sellId ,phone,  getdate() as created ,  number, firstSum, productType, status, region, fio, requestCreated   into #for_sale from v where rn=1								
order by declined				

 
 --select  --     [sellId]  --   , [phone]   --   , [created]   --   , [number]   --   , [firstSum]   --   , [productType]  --   , [status]   --   , [region]   --   , [fio]   
	--, requestCreated
	--into sale_sell_siberian_log 
	--from #for_sale
	--  where 1=0
	   



if not exists (select * from #for_sale) return

insert into sale_sell_siberian_log (sellId, phone, created, number, region, firstSum, productType , status ,    fio,  requestCreated  )
select sellId, phone, created, number, region, firstSum, productType, status,    fio, requestCreated from  #for_sale



declare @text varchar(max) = ( select string_agg( isnull(phone, '') + ' ' + isnull( format(requestCreated , 'yyyy-MM-dd') , '?'), '
' ) from #for_sale )
exec log_email 'Продажа трафика Сибиряк', 'p.ilin@smarthorizon.ru; a.vdovin@carmoney.ru', @text
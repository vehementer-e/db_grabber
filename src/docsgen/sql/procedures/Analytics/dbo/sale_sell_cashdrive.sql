 CREATE            proc [dbo].[sale_sell_cashdrive] as
 

 --if exists (select * from sale_sell_infoseti_log where sold is   null)
 --begin
 --exec log_email 'exists sale_sell_infoseti_log where sold is   null'
 --return

 --end

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
, isnull( carBrand, '') + isnull(' '+carModel, '')+isnull(' '+try_cast(carYear  as  varchar(10)), '0') carInfo
 , fio  fio
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


)	 and region in (
 'Москва'
,'Московская обл'
,'Приморский край'
,'Воронежская обл'
,'Свердловская обл'
,'Иркутская обл'
,'Татарстан Респ'
,'Нижегородская обл'
,'Ростовская обл'
,'Ленинградская обл'
,'Санкт-Петербург'
,'Самарская обл'


)
and a.source not like '%bankiru%'
and  a.source  not in (select [Источник трафика] from source_block_sell where [Источник трафика] is not null)

				
  and declined>='2025-09-16 11:00:00'

--  drop table if exists #lead
--  select id, phone, created, decline status into #lead from v_lead2 a
  
--  where source =  'infoseti-deepapi-pts'  and created>=cast(getdate()-1 as date)  	
--  and decline = 'Отказ preCall1'
--  and created>='2025-06-26 19:00:00'
  

--  insert into #lead
--  select id , phone, created, ПричинаНепрофильности status from v_lead2

--  where source =  'infoseti-deepapi-pts'  and created>=cast(getdate()-1 as date)  	
--  and ПричинаНепрофильности in (
--  'Неактуально / не нужны деньги',
--  'Нужна бОльшая сумма',
--  'Нет авто',
--  'Ищет в банке',
--  'Вне зоны присутсвия бизнеса' )
--  and created>='2025-06-27 13:50:00'
   

--  drop table if exists #lead2 
--  select a.id , b.sum , a.phone, b.productType, a.created, a.status   into #lead2 from #lead a 
--  join v_request_external b on a.id=b.id






--insert into #t1 ([number], [loanAmount], [phone], [Отказано], [productType], addressResidentialRegion, status)
--select id, isnull( sum, 100000)sum  , phone, created,isnull(productType, ''), '', status  from #lead2
 





drop table if exists #for_sale
								
;								
								
with v as (								
select a.phone, a.firstSum   ,a.region  , --a.Марка, a.Модель, a.ГодВыпуска, 
a.number,  a.declined, ROW_NUMBER() over(partition by a.phone order by a.declined) rn
, a.productType
, a.status
, a.carInfo
, a.fio
from #t1 a								
left join #fa x on x.created between dateadd(day, -8, a.declined ) and  dateadd(day, 8, a.declined ) and a.number<>x.number and  a.phone=x.phone and x.cancelled is null  and x.declined is null  and x.approved is null 								
left join #fa x1 on a.phone=x1.phone and  x1.issued is not null 							
left join #fa x2 on a.phone=x2.phone and  x2.approved >=dateadd(day, -30 , a.declined)  							
left join  mv_loans b on a.phone=b.[Основной телефон клиента CRM]								
left join  mv_loans b1 on a.phone=b1.[Телефон договор CMR]			
 left join  sale_sell_cashdrive_log p on p.phone=a.phone and p.created>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.number is  null and								
x2.number is  null and								
x1.number is  null 	
 and	 p.phone is  null 							
								
)								
select cast( newid() as  varchar(36)) sellId ,phone,  getdate() as created ,  number, firstSum, productType, status, region, fio, carInfo  into #for_sale from v where rn=1								
order by declined				


--update sale_sell_infoseti_log set status='Отказано' where isnumeric(number)=1
--update sale_sell_infoseti_log set status='Отказ preCall1' where isnumeric(number)=0 and status is null

--delete from #for_sale

--insert into #for_sale (sellId, phone, created, number, addressResidentialRegion, loanAmount, productType )
--select 'test', '9999999999', getdate(), 'test', 'Москва', 100000, 'pts'

--select sellId, phone, created, number, region, firstSum, productType, status, carInfo into sale_sell_cashdrive_log from  #for_sale




if not exists (select * from #for_sale) return

insert into sale_sell_cashdrive_log (sellId, phone, created, number, region, firstSum, productType , status , carInfo, fio  )
select sellId, phone, created, number, region, firstSum, productType, status, carInfo, fio from  #for_sale
--delete from sale_sell_cashdrive_log where sellid='test1'
 
--insert into sale_sell_cashdrive_log (sellId, phone, created, number, region, firstSum, productType , status , carInfo , fio  )
-- select 'test1', '9999999999', getdate(), 'test', 'Москва', 10, 'pts', '', 'bmw', 'ТЕСТ ТЕСТ ТЕСТ'
   

   --select ISJSON(solddesc) from sale_sell_cashdrive_log

exec python  'sale_sell_cashdrive()' , 1

--alter table sale_sell_cashdrive_log add sold datetime2(0)
--alter table sale_sell_cashdrive_log add   soldDesc nvarchar(max)
--alter table sale_sell_cashdrive_log add   fio varchar(255)
--	  , 
--drop table sale_sell_infoseti_log
-- CREATE TABLE sale_sell_infoseti_log
--(


--		sellId [VARCHAR](36)
--     , [phone] [NVARCHAR](100)
--    , [created] [DATETIME]
--    , [number] [NVARCHAR](100)
--    , [addressResidentialRegion] [NVARCHAR](150)
--    , [loanAmount] [NUMERIC]
--    , [productType] [VARCHAR](4)
--	, sold datetime2(0)
--	, soldDesc nvarchar(max)

--);
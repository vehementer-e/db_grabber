 CREATE          proc [dbo].[sale_sell_infoseti] as
 

 --if exists (select * from sale_sell_infoseti_log where sold is   null)
 --begin
 --exec log_email 'exists sale_sell_infoseti_log where sold is   null'
 --return

 --end

drop table if exists #fa

select number
,      [Первичная сумма] loanAmount
,      productType
,      phone
,      [Вид займа]
,      [Группа каналов]
,      Источник
,      Отказано
,      region addressResidentialRegion
,      [Ссылка заявка]
,      isInstallment
,      Дубль
,      created
,      Аннулировано
,      Одобрено
,      [Заем выдан]
,      [Заем аннулирован] into #fa
from v_fa a

where [Верификация КЦ]>=getdate()-60 or [Заем выдан] is not null

create nonclustered index t on #fa
(
phone, created, number
)

drop table if exists #t1
select a. number 
,      loanAmount
,      phone
,      [Вид займа]
,      [Группа каналов]
,      Источник
--,      z.Марка
--,      z.Модель
,      Отказано
,      addressResidentialRegion
--,      z.ГодВыпуска
,     cast( a.productType as varchar(255)) productType
, cast('Отказано' as varchar(255)) status
	into #t1
from      #fa                                                                  a
--left join (
--	select a.Ссылка                              
--	,      b.Наименование                         Марка
--	,      c.Наименование                         Модель
--	,      year(dateadd(year, -2000, ГодВыпуска)) ГодВыпуска
--	from      stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС  a
--	left join stg._1cCRM.Справочник_МаркиАвтомобилей  b on a.МаркаМашины=b.Ссылка
--	left join stg._1cCRM.Справочник_МоделиАвтомобилей c on a.Модель=c.ссылка ) z on z.Ссылка=a.[Ссылка заявка]
left join (select a.number from v_request_lk a join stg._lk.pep_activity_log b on a.id=b.request_id and b.document_name =  'Согласие на получение рекламных сообщений ПЭП' 
and b.document_status=1 group by a.number) b on a.number=b.number
where Отказано >= cast(getdate()-1 as date)  							
--and Дубль=1								
--and isInstallment=0								
and a.productType in ('PTS' , 'INST', 'PDL')
and [Вид займа] = 'Первичный'								
and [Группа каналов] <> 'Партнеры'								
and isnull(Источник, '')   in (								

 'infoseti-deepapi-pts' 
,'infoseti-deepapi-installment' 

)						
--and [Регион проживания]
--in
--('Москва г'
--,'Московская обл'
--,'Санкт-Петербург г'
--,'Ленинградская обл'
--)
--select distinct [Регион проживания] from   #t1
				
  and Отказано>='2025-06-03 17:00:00'

  drop table if exists #lead
  select id, phone, created, decline status into #lead from v_lead2 a
  
  where source =  'infoseti-deepapi-pts'  and created>=cast(getdate()-1 as date)  	
  and decline = 'Отказ preCall1'
  and created>='2025-06-26 19:00:00'
  

  insert into #lead
  select id , phone, created, ПричинаНепрофильности status from v_lead2

  where source =  'infoseti-deepapi-pts'  and created>=cast(getdate()-1 as date)  	
  and ПричинаНепрофильности in (
  'Неактуально / не нужны деньги',
  'Нужна бОльшая сумма',
  'Нет авто',
  'Ищет в банке',
  'Вне зоны присутсвия бизнеса' )
  and created>='2025-06-27 13:50:00'
   

  drop table if exists #lead2 
  select a.id , b.sum , a.phone, b.productType, a.created, a.status   into #lead2 from #lead a 
  join v_request_external b on a.id=b.id






insert into #t1 ([number], [loanAmount], [phone], [Отказано], [productType], addressResidentialRegion, status)
select id, isnull( sum, 100000)sum  , phone, created,isnull(productType, ''), '', status  from #lead2
 





drop table if exists #for_sale
								
;								
								
with v as (								
select a.phone, a.loanAmount   ,a.addressResidentialRegion addressResidentialRegion, --a.Марка, a.Модель, a.ГодВыпуска, 
a.number,  a.Отказано, ROW_NUMBER() over(partition by a.phone order by a.Отказано) rn
, a.productType
, a.status
from #t1 a								
left join #fa x on x.created between dateadd(day, -8, a.Отказано ) and  dateadd(day, 8, a.Отказано ) and a.number<>x.number and  a.phone=x.phone and x.Аннулировано is null and x.[Заем аннулирован] is null and x.Отказано is null  								
left join #fa x1 on a.phone=x1.phone and  x1.[Заем выдан] is not null 							
left join #fa x2 on a.phone=x2.phone and  x2.Одобрено >=dateadd(day, -30 , a.Отказано)  							
left join  mv_loans b on a.phone=b.[Основной телефон клиента CRM]								
left join  mv_loans b1 on a.phone=b1.[Телефон договор CMR]			
 left join  sale_sell_infoseti_log p on p.phone=a.phone and p.created>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.number is  null and								
x2.number is  null and								
x1.number is  null 	
 and	 p.phone is  null 							
								
)								
select cast( newid() as  varchar(36)) sellId ,phone,  getdate() as created ,  number, addressResidentialRegion, loanAmount, productType, status  into #for_sale from v where rn=1								
order by Отказано				


--update sale_sell_infoseti_log set status='Отказано' where isnumeric(number)=1
--update sale_sell_infoseti_log set status='Отказ preCall1' where isnumeric(number)=0 and status is null

--delete from #for_sale

--insert into #for_sale (sellId, phone, created, number, addressResidentialRegion, loanAmount, productType )
--select 'test', '9999999999', getdate(), 'test', 'Москва', 100000, 'pts'


if not exists (select * from #for_sale) return

insert into sale_sell_infoseti_log (sellId, phone, created, number, addressResidentialRegion, loanAmount, productType , status )
select sellId, phone, created, number, addressResidentialRegion, loanAmount, productType, status from  #for_sale

  --alter table sale_sell_infoseti_log add status varchar(100)


--declare @command nvarchar(max) = 'sale_sell_infoseti('+ ( select '['+ string_agg(''''+sellId + '''' , ',' ) +']' from #for_sale )+')'
--select @command

exec python  'sale_sell_infoseti()' , 1


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
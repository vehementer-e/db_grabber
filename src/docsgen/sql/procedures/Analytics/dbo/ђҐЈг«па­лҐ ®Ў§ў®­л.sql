CREATE proc [dbo].[Регулярные обзвоны]
as
begin

declare @start_date  date = getdate() -30
declare @end_date    date = getdate() -1 
						  
drop TABLE  if exists [#odobreno_ne_vidano_pts]CREATE TABLE [#odobreno_ne_vidano_pts](      [Номер] [NVARCHAR](100)    , [ФИО] [NVARCHAR](150)    , [текущийСтатус] [NVARCHAR](50)    , [Вид займа] [NVARCHAR](100)    , [Телефон] [NVARCHAR](100)    , [GMT партнера] [NVARCHAR](10)    , [Дата_Одобрения] [DATEtime2]    , [Сумма одобренная] [NUMERIC]    , [Место_создания_2] [NVARCHAR](100)    , capital [NVARCHAR](100)    , РегионПроживания [NVARCHAR](100))
insert into [#odobreno_ne_vidano_pts]
exec [_birs].[Регулярные обзвоны Одобренные но не выданные]  @start_date , 	@end_date 

drop TABLE  if exists [#odobreno_ne_vidano_inst]
CREATE TABLE [dbo].[#odobreno_ne_vidano_inst](      [Телефон] [NVARCHAR](100)    , [Вид займа]		  [NVARCHAR](100)    , [Текущий статус]  [NVARCHAR](50)    , [Регион Проживания] [NVARCHAR](100)    , capital [NVARCHAR](100)    , gmt [NVARCHAR](100)    , [Номер] [NVARCHAR](100)    , [ФИО] [NVARCHAR](150)    , [timezone] [VARCHAR](9)    , [Одобрено] [SMALLDATETIME]);
insert into [#odobreno_ne_vidano_inst]
exec [_birs].[Регулярные обзвоны одобрено но не выдано Беззалог]    @start_date , 	@end_date 




drop table if exists [#nedoezdi]

CREATE TABLE  [#nedoezdi](      [Номер] [NVARCHAR](100)    , [ФИО] [NVARCHAR](150)    , [текущийСтатус] [NVARCHAR](100)    , [Вид займа] [NVARCHAR](MAX)    , [Телефон] [NVARCHAR](100)    , [Регион проживания] [VARCHAR](100)    , capital [VARCHAR](100)    , [GMT партнера] [VARCHAR](9)    , [Дата_Предварительного_Одобрения] [DATETIME]    , [Первичная сумма] [NUMERIC]    , [Место_создания_2] [NVARCHAR](100)    , [Партнер] [NVARCHAR](150)    , [ТочкаМаилян] [INT]    , [isInstallment] [INT]);


insert into [#nedoezdi]
exec [_birs].[Регулярные обзвоны Предодобренные без КД]   @start_date , 	@end_date 	


drop table if exists [#zastrjali]

CREATE TABLE  [#zastrjali](      [Номер] [NVARCHAR](100)    , [ФИО] [NVARCHAR](150)    , [Вид займа] [NVARCHAR](MAX)    , [текущийСтатус] [NVARCHAR](100)    , [Телефон] [NVARCHAR](100)    , [GMT партнера] [VARCHAR](9)    , [Дата_КД] [DATETIME]    , [Первичная сумма] [NUMERIC]    , [Место_создания_2] [NVARCHAR](100)    , [Регион проживания] [NVARCHAR](100)    , [isPts] [INT]    , [capital] [VARCHAR](100));


insert into [#zastrjali]
exec [_birs].[Регулярные обзвоны Застрявшие после КД]   @start_date , 	@end_date 



		 
drop table if exists [#nedozvoni]

CREATE TABLE  [#nedozvoni](      [phonenumbers] [NVARCHAR](4000)    , [uf_registered_at] [DATETIME2](7)    , [attempt_start] [DATETIME2](7)    , [timezone] [NVARCHAR](32)    , [title] [NVARCHAR](255)    , [lcrm_id]  nvarchar(36)      , [uf_regions_composite] [VARCHAR](128)    , [Канал] [VARCHAR](11)    , [capital] [VARCHAR](24)    , is_inst_lead int);


insert into [#nedozvoni]
exec [_birs].[Регулярные обзвоны Недозвоны СРС Целевой]   @start_date , 	@end_date 

 
drop table if exists #cc_lead
create table #cc_lead
(
row_id uniqueidentifier      ,
created  datetime2           ,
lead_created  datetime2      ,
lead_id numeric(15,0)        ,
lead_source nvarchar(100)    ,
lead_partner_name nvarchar(100)        ,
lead_phone nvarchar(10)       ,
lead_name nvarchar(150)      ,	 
lead_region nvarchar(100)     ,
lead_capital nvarchar(100)    ,
lead_GMT nvarchar(10)         ,
trigger_name   nvarchar(100)  ,
trigger_dt  datetime2        ,
number_1c nvarchar(20)       ,
lcrm_id  nvarchar(36)        ,
request_status nvarchar(50) ,
return_type nvarchar(150)    ,

)
 
insert into #cc_lead

select 
 row_id              = NEWID()
,created             = getdate()
,lead_created        = null
,lead_id             = null
,lead_source         = 'cc_nedozvoni_po_lidam_pts' 
,lead_partner_name   = case when [Канал]='Органика' then 'organics_'when [Канал]='CPC' then 'CPC_' else 'CPAcelevoy_' end+format(datediff(day,  [uf_registered_at], getdate()), '00')
,lead_phone          =  [phonenumbers]
,lead_name           =  try_cast(left(title  , 150) as nvarchar(150))
,lead_region         = 	[uf_regions_composite]
,lead_capital        = 	 capital
,lead_GMT            = 	 [timezone]
,trigger_name        = 	'cc_nedozvoni_po_lidam_pts'
,trigger_dt          = 	[uf_registered_at]
,number_1c           = 	null
,lcrm_id             = 	[lcrm_id]
,request_status      = 	null
,return_type         = 	null
 
from [#nedozvoni]
where is_inst_lead=0	-- and Канал<> 'Органика'
--and 1=0

 









insert into #cc_lead

select 
 row_id              = NEWID()
,created             = getdate()
,lead_created        = null
,lead_id             = null
,lead_source         = 'cc_odobreno_ne_vidano_pts' 
,lead_partner_name   = case when [Вид займа]='Первичный' then 'new_' else 'repeated_' end+format(datediff(day,  [Дата_Одобрения], getdate()), '00')
,lead_phone          =  [Телефон]
,lead_name           =  [ФИО]  
,lead_region         = 	РегионПроживания
,lead_capital        = 	 capital
,lead_GMT            = 	 [GMT партнера]
,trigger_name        = 	'cc_odobreno_ne_vidano_pts'
,trigger_dt          = 	Дата_Одобрения
,number_1c           = 	Номер
,lcrm_id             = 	null
,request_status      = 	текущийСтатус
,return_type         = 	[Вид займа]
 
from [#odobreno_ne_vidano_pts] 


insert into #cc_lead

select 
 row_id              = NEWID()
,created             = getdate()
,lead_created        = null
,lead_id             = null
,lead_source         = 'cc_odobreno_ne_vidano_inst' 
,lead_partner_name   = case when [Вид займа]='Первичный' then 'new_' else 'repeated_' end+format(datediff(day,  Одобрено, getdate()), '00')
,lead_phone          =  [Телефон]
,lead_name           =  [ФИО]
,lead_region         = 	[Регион Проживания]
,lead_capital        = 	 capital
,lead_GMT            = 	 gmt
,trigger_name        = 	'cc_odobreno_ne_vidano_inst'
,trigger_dt          = 	Одобрено
,number_1c           = 	Номер
,lcrm_id             = 	null
,request_status      = 	[Текущий статус]
,return_type         = 	[Вид займа]
 
from [#odobreno_ne_vidano_inst] 



insert into #cc_lead

select 
 row_id              = NEWID()
,created             = getdate()
,lead_created        = null
,lead_id             = null
,lead_source         = 'cc_nedoezdi'+ case when isInstallment=1 then  '_inst' else '_pts'  end
,lead_partner_name   = case when [Вид займа]='Первичный' then 'new_' else 'repeated_' end+format(datediff(day,  [Дата_Предварительного_Одобрения], getdate()), '00')
,lead_phone          =  [Телефон]
,lead_name           =  [ФИО]
,lead_region         = 	 [Регион проживания]
,lead_capital        = 	 capital
,lead_GMT            = 	 [GMT партнера]
,trigger_name        = 'cc_nedoezdi'+ case when isInstallment=1 then  '_inst' else '_pts'  end
,trigger_dt          = 	Дата_Предварительного_Одобрения
,number_1c           = 	Номер
,lcrm_id             = 	null
,request_status      = 	текущийСтатус
,return_type         = 	[Вид займа]
 
from [#nedoezdi] 
					 
insert into #cc_lead

select 
 row_id              = NEWID()
,created             = getdate()
,lead_created        = null
,lead_id             = null
,lead_source         = 'cc_zastrjali_posle_kd'+ case when isPts=0 then  '_inst' else '_pts'  end
,lead_partner_name   = case when [Вид займа]='Первичный' then 'new_' else 'repeated_' end+ format(datediff(day,  Дата_КД, getdate()), '00')
,lead_phone          =  [Телефон]
,lead_name           =  [ФИО]
,lead_region         = 	[Регион проживания]
,lead_capital        = 	capital
,lead_GMT            = 	[GMT партнера]
,trigger_name        = 'cc_zastrjali_posle_kd'+ case when isPts=0  then  '_inst' else '_pts'  end
,trigger_dt          = 	Дата_КД
,number_1c           = 	Номер
,lcrm_id             = 	null
,request_status      = 	текущийСтатус
,return_type         = 	[Вид займа]
 
from [#zastrjali] 





drop table if exists #case
select  
 phonenumbers phonenumbers	     
into #case
from openquery(naumen,'      
SELECT   
cc.phonenumbers      
 FROM report_db.public.mv_call_case cc
where cc.creationdate>=CURRENT_DATE-1   ')  


drop table if exists #dos
select
 client_number           client_number 	 
into #dos
from openquery(naumen,'      
SELECT 
dos.client_number 	   
FROM  report_db.public.detail_outbound_sessions dos 
where dos.attempt_start>=CURRENT_DATE-1   ')  


drop table if exists #phones_to_exclude

			select '8'+value phonenumbers into #phones_to_exclude from #case
 cross apply string_split( phonenumbers, ',')
 where len(value)=10
 union 
 
			select  value  from #case
 cross apply string_split( phonenumbers, ',')
 where len(value)=11
 union
 select * from #dos
 union
 select   client_number from reports.dbo.dm_report_DIP_detail_outbound_sessions where login is not null and attempt_start>=getdate()-30

--	select uf_phone into #cc_old from Feodor.dbo.dm_leads_history
--	where uf_source like 'cc_%' and ДатаЛидаЛСРМ>='20240322'
--
--	insert into   #phones_to_exclude
--	select '8'+uf_phone from 	#cc_old
--


--delete from dbo.cc_lead
insert into dbo.cc_lead
select  top 500  
x.row_id            
	   ,x.created           
	   ,x.lead_created      
	   ,x.lead_id           
	   ,x.lead_source       
	   ,x.lead_partner_name 
	   ,x.lead_phone        
	   ,x.lead_name         
	   ,x.lead_region       
	   ,x.lead_capital      
	   ,x.lead_GMT          
	   ,x.trigger_name      
	   ,x.trigger_dt        
	   ,x.number_1c         
	   ,x.lcrm_id           
	   ,x.request_status    
	   ,x.return_type       

from (
select a.*
, row_number() over(partition by a.lead_phone order by a.trigger_dt desc) rn
, count(*) over(partition by a.lead_phone ) cnt
--, case when RAND(CHECKSUM(NEWID()))<=1/20.0 then 1 else 0 end	to_sell
, case when datediff(day, getdate()-30, a.trigger_dt)<=1 then 1 else   datediff(day, getdate()-30, a.trigger_dt) end num
, case when RAND(CHECKSUM(NEWID()))<= (100.0- case when datediff(day, getdate()-30, a.trigger_dt)<=3 then 0 else   3*datediff(day, getdate()-30, a.trigger_dt) end )/100.0  then 1 else 0 end	to_sell			    

from #cc_lead	 a
left join #phones_to_exclude c on '8'+a.lead_phone=c.phonenumbers 
left join v_request b on a.lead_phone=b.Телефон 
					  and b.Отказано is null and b.[Аннулировано] is null 
					  and b.[Заем выдан] is null
					  and b.[Заем аннулирован] is null
					  and b.[Верификация кц] >=getdate()-30		 
left join v_request b1 on a.lead_phone=b1.Телефон 
					  and b1.ДатаЗаявки >=cast(getdate()-1 as date)
left join  dbo.cc_lead b2 on a.lead_phone=b2.lead_phone and b2.created>=cast(getdate()-30 as date)

where b.ДатаЗаявки is null 
and b1.ДатаЗаявки is null 
and c.phonenumbers is null
and b2.row_id is null
--order by a.trigger_dt 


) x 

where 	x.to_sell =1	   and
x.rn=1	 
order by x.trigger_dt 


--select * from  cc_lead
----delete from  cc_lead  where created>='20240605'
--order by 2 desc

--select lead_source, lead_partner_name, count(*) cnt from cc_lead
--delete from cc_lead
--where created>='20240528'
--group by 			 lead_source, lead_partner_name
--order by 	 lead_source, lead_partner_name



exec exec_python 'create_lead_cc()', 1


--select * from  #cc_leads
--select * from   dbo.cc_lead
--order by lead_phone
--select distinct lead_source from   dbo.cc_lead
--order by lead_phone
--
--
 
--
--select * from v_request
--where  Телефон ='9248730418'

--	exec create_job 'Analytics. Регулярные обзвоны в 11', 'exec dbo.[Регулярные обзвоны]', '1', '110000'

--drop table if exists cc_lead 
--create table  cc_lead 
--(
--row_id uniqueidentifier      ,
--created  datetime2           ,
--lead_created  datetime2      ,
--lead_id numeric(15,0)        ,
--lead_source nvarchar(100)    ,
--lead_partner_name nvarchar(100)        ,
--lead_phone nvarchar(10)       ,
--lead_name nvarchar(150)      ,	 
--lead_region nvarchar(100)     ,
--lead_capital nvarchar(100)    ,
--lead_GMT nvarchar(10)         ,
--trigger_name   nvarchar(100)  ,
--trigger_dt  datetime2        ,
--number_1c nvarchar(20)       ,
--lcrm_id  nvarchar(20)        ,
--request_status nvarchar(50) ,
--return_type nvarchar(150)    ,
--
--)

end
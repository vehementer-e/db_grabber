CREATE   proc [dbo].[Продажа трафика avtolombard-credit]
@mode nvarchar(max) =  'update' 
as
begin


  if @mode = 'update'  
begin

	 drop table if exists #non_core_leads
	  
  select [Дата лида], a.Телефон,[Причина непрофильности], id, IsInstallment into #non_core_leads from v_feodor_leads a
  where   [Статус лида]='Непрофильный'	 and [Дата лида]>=  cast(getdate()-6 as date)
  and isnull([Причина непрофильности] , 'NULL') in 
  (
 'Отказ паспорта'
,'Ранее был отказ'
,'Нет паспорта (перевыпуск, замена)'
,'Авто не в собственности не готов переоформить'
,'NULL'
,'Другое + комментарий'
,'Нет прописки'
,'Не подходит авто по году выпуска'
,'Нет авто'
,'Отказ от разговора'
,'Вне зоны присутсвия бизнеса'
,'Не оставлял заявку'
,'Не подходит по возрасту'
,'Не РФ, не зарегистрирвоано авто на территории РФ'
,'Сотрудничество/Реклама'
,'Авто на юр лице'
,'В кредите (более 15%)'
,'Авто в залоге'
,'Задолженность ФССП'
,'Авто не на ходу'
,'Категория авто'
,'Нет СТС'
--,'Тест'
,'Дубликат в замен утраченного  менее 45 дней'
)


drop table if exists #t1

;

select 
  newid()	 row_id
, getdate() as created
, cast(null as datetime2) as sold
, a.[ID] 
, a.[PhoneNumber] 
, a.[UF_REGISTERED_AT] 
, a.[UF_SOURCE] 
, o.Номер
, isnull( o.Отказано, leads.[Дата лида] ) Отказано
,  isnull( o.[Причина отказа] , leads.[Причина непрофильности] )   [Причина отказа]
, isnull(o.isinstallment, leads.isinstallment) 	isinstallment
, o.[Вид займа] 
, isnull(o.[Регион проживания], reg_lead.region) [Регион проживания]
, isnull(reg.capital,  reg_lead.capital)  [Город]


 into #t1
from [Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref] a

left join reports.dbo.dm_factor_analysis_001 o on a.PhoneNumber=o.Телефон 
and o.Отказано >=a.UF_REGISTERED_AT 
--and o.isinstallment=0	
and o.[Вид займа] = 'Первичный'	
and o.[Группа каналов] <> 'Партнеры'

left join #non_core_leads leads on leads.id=a.id   
and o.Номер is null

left join reports.dbo.dm_factor_analysis_001 exclude1 on   a.PhoneNumber = exclude1.Телефон 
and exclude1.Аннулировано is null 
and exclude1.[Заем аннулирован] is null 
and exclude1.Отказано is null 
and exclude1.Одобрено is null	

left join reports.dbo.dm_factor_analysis_001 exclude2 on   a.PhoneNumber = exclude2.Телефон and exclude2.[Заем выдан] is not null
left join reports.dbo.dm_factor_analysis_001 exclude3 on   a.PhoneNumber = exclude3.Телефон and exclude3.Одобрено >=getdate()-30


left join Analytics.dbo.mv_loans с on a.PhoneNumber =с.[Основной телефон клиента CRM]								
left join Analytics.dbo.mv_loans с1 on a.PhoneNumber =с1.[Телефон договор CMR]	
left join dbo.[Продажа трафика avtolombard-credit_log] d on d.phonenumber=a.PhoneNumber and d.[created] >= cast(getdate()-6 as date)
left join v_gmt reg on reg.region=o.[Регион проживания]
left join v_gmt reg_lead on reg_lead.region=a.UF_REGIONS_COMPOSITE	and reg.region is null
where a.UF_REGISTERED_AT>=cast(getdate()-6 as date)

and exclude1.Номер 			              is null  
and exclude2.Номер 						  is null
and exclude3.Номер 						  is null
and с.[Основной телефон клиента CRM]  is null
and с.[Телефон договор CMR]			  is null
and d.phonenumber  is null
and  isnull( o.Отказано, leads.[Дата лида] ) is not null

--select * from #t1 


--order by 3



;

 with v as (
	  select 
    *
,   ROW_NUMBER() over(partition by phonenumber order by Отказано ) rn
from 

#t1 a
)

delete from v where rn>1



--drop table if exists dbo.[Продажа трафика avtolombard-credit_log]
--select  top  0
--    a.[row_id] 
--,   a.[created] 
--,   a.[sold] 
--,   a.[ID] 
--,   a.[PhoneNumber] 
--,   a.[UF_REGISTERED_AT] 
--,   a.[UF_SOURCE] 
--,   a.[Номер] 
--,   a.[Отказано] 
--,   a.[Причина отказа] 
--,   a.[isinstallment] 
--,   a.[Вид займа] 
-- into dbo.[Продажа трафика avtolombard-credit_log]
--from #t1  a
--delete from dbo.[Продажа трафика avtolombard-credit_log]

insert into dbo.[Продажа трафика avtolombard-credit_log]
select 
    a.[row_id] 
,   a.[created] 
,   a.[sold] 
,   a.[ID] 
,   a.[PhoneNumber] 
,   a.[UF_REGISTERED_AT] 
,   a.[UF_SOURCE] 
,   a.[Номер] 
,   a.[Отказано] 
,   a.[Причина отказа] 
,   a.[isinstallment] 
,   a.[Вид займа] 
,   null [partner_lead_id]
,   a.[Регион проживания] [Регион]
,   a.[Город] [Город]
 --into dbo.[Продажа трафика avtolombard-credit]
from #t1  a


--alter table dbo.[Продажа трафика avtolombard-credit_log]
--add   [partner_lead_id] nvarchar(100)		   
--alter table dbo.[Продажа трафика avtolombard-credit_log]
--add   [Регион] nvarchar(100)	     
--alter table dbo.[Продажа трафика avtolombard-credit_log]
--add   [Город] nvarchar(100)

--update a 
--
--set [sold]= null
--from   dbo.[Продажа трафика avtolombard-credit]a

--exec select_table '#t1'


end
if @mode = 'select'

begin


drop table if exists #stg

select top 1 row_id,  phonenumber, created, isnull([Город], 'Москва') [Город]  into #stg from dbo.[Продажа трафика avtolombard-credit_log]
where sold is null and created>=cast(getdate()-1  as date)

if @@ROWCOUNT=0 return

update a set a.sold = '1999-01-01'   from dbo.[Продажа трафика avtolombard-credit_log] a join #stg b on a.row_id=b.row_id

select * from #stg for json auto

end

--with v as ( select   *   from dbo.[Продажа трафика avtolombard-credit_log]) update a set a.sold=null from v a  where created>=cast(getdate()   as date)	and sold='2000-01-01 00:00:00.0000000'
--with v as ( select   *   from dbo.[Продажа трафика avtolombard-credit_log]) update a set a.sold=null from v a  where created>=cast(getdate()   as date)	and sold='1999-01-01 00:00:00.0000000'
	
--select * from dbo.[Продажа трафика avtolombard-credit_log]  
--order by 2


--exec create_table 'analytics.dbo.[Продажа трафика avtolombard-credit_log] '

end
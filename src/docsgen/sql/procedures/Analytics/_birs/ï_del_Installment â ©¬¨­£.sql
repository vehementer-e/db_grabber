
CREATE   proc [_birs].[Installment тайминг]   @mode nvarchar(max) = 'select'	  , @recreate int =0
--exec [_birs].[Installment тайминг]    'update'	  ,  1
as
begin

if @mode = 'update'
begin


if 1=0
begin
select * into dbo.LK_requests_origin from openquery(lkprod, 'select * from requests_origin')
--select * from _v_information_schema_dwh where db='stg' and table_schema='_lk'  and table_name='requests'

drop table if exists 	 #ispdl

select   dateadd(year, -2000, Период) Период,  объект_ссылка, case ЗначениеРеквизитаПослеПредставление when 'Да' then 1 else 0 end ispdl  

--, case when row_number() over(partition by объект_ссылка order by Период)=1 then 1 else 0 end as isInitalProduct 
  into #ispdl
from stg._1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов
where  Реквизит='ПДЛ'

drop table if exists 	 initial_products
select *, case when row_number() over(partition by объект_ссылка order by Период)=1 then 1 else 0 end as isInitalProduct into initial_products from #ispdl



end


drop table if exists #prolongation

select d.Код, count(*) prolongations_cnt into #prolongation from stg._1ccmr.[РегистрНакопления_PDLПролонгации]   a join stg._1cCMR.Справочник_Договоры d on a.Договор=d.Ссылка
where ВидДвижения=1
group by d.Код


drop table if exists #requests_lk

select r.id	  id				 
,      r.full_created_at	 created_at
,      r.num_1c	   num_1c
,      is_installment  is_installment
, 	   b.name_1c	origin_name_1c
, r.client_mobile_phone 	client_mobile_phone
, r.lcrm_id
--, green.[Наличие зеленого предложения]	[Наличие зеленого предложения]
, r.summ	
--, case
--when r.is_installment=1 and z.isinstallment=0 then 'PDL'
--else 'INST' end [product_type]	 	
, case	
product_types_id
when 1 then 'PTS'
when 2 then 'INST'
when 3 then 'PDL'
end [product_type]
, case 
when initial.ispdl =1 then 'PDL_initial'
when initial.ispdl =0 then 'INST_initial'
end [product_type_initial]	 ,
pr.prolongations_cnt

into #requests_lk	--select top 100 * 
from stg._lk.requests r
left join stg._LK.requests_origin b	   on r.requests_origin_id=b.id
left join dwh2.[dm].[v_ЗаявкаНаЗаймПодПТС] z on z.lk_request_id=r.id
left join (
select * from initial_products
where isinitalproduct=1 ) initial on initial.объект_ссылка=z.СсылкаЗаявки
 left join #prolongation pr on pr.Код=z.КодДоговораЗайма
 

--left join #green green	   on r.id=green.id
where is_installment=1	  or  product_types_id in (2,3)
and r.created_at>='20230511'
--order by 	 id desc

--select top 100  * from stg._lk.requests r
--where is_installment=1
--		order by id desc

--select * from dbo.LK_requests_origin
 
drop table if exists #inst_status	 
 select * into #inst_status from (
select  lk_id= 68 ,  status_order = 1, source = 'lk'   union  
select  lk_id= 69 ,  status_order = 1, source = 'lk'   union  
select  lk_id= 70 ,  status_order = 2, source = 'lk'   union  
select  lk_id= 70 ,  status_order = 3, source = 'lk'   union  
select  lk_id= 71 ,  status_order = 2, source = 'lk' union  
select  lk_id= 72 ,  status_order = 3, source = 'lk' union  
select  lk_id= 73 ,  status_order = 4, source = 'lk' union  
select  lk_id= 73  ,  status_order = 4.5, source = 'lk' union  

select  lk_id= 74 ,  status_order = 5, source = 'lk' union  
select  lk_id= 75 ,  status_order = 6, source = 'lk' union  
select   lk_id= 76 ,  status_order = 7, source = 'lk' union  
select   lk_id= 77 ,  status_order = 8, source = 'lk' union  
select   lk_id= 78 ,  status_order = 9, source = 'lk'    
																																			
union 

select  lk_id= 90  ,  status_order = 1, source = 'lk'   union  
select  lk_id= 91  ,  status_order = 1, source = 'lk'   union  
select  lk_id= 92  ,  status_order = 2, source = 'lk'   union  
select  lk_id= 92  ,  status_order = 3, source = 'lk'   union  
select  lk_id= 93  ,  status_order = 2, source = 'lk' union  
select  lk_id= 94  ,  status_order = 3, source = 'lk' union  
select  lk_id= 95  ,  status_order = 4, source = 'lk' union  
select  lk_id= 95  ,  status_order = 4.5, source = 'lk' union  
select  lk_id= 96  ,  status_order = 5, source = 'lk' union  
select  lk_id= 97  ,  status_order = 6, source = 'lk' union  
select  lk_id= 98  ,   status_order = 7, source = 'lk' union  
select  lk_id= 99  ,  status_order = 8, source = 'lk' union  
select  lk_id= 100 ,    status_order = 9, source = 'lk' --union 
	 )
	 x



		 







--select a.*, e.name from #inst_status a
--left join stg._lk.events e on e.id=a.lk_id
--order by status_order
--  
--
--  select id, name, created_at from  stg._lk.events
--  order by 1

drop table if exists #t2

select e.name status,e.id, r.num_1c, re.created_at Дата, r.id request_id, s.status_order  into #t2 from stg._LK.events	  e
join Stg._LK.requests_events re on re.event_id=e.id
join #requests_lk r  on r.id=re.request_id
 join  #inst_status   s on s.lk_id=e.id
--where r.is_installment=1

drop table if exists  #t2_
					 
select 
    a.[status] 
,   a.[id] 
,   a.[num_1c] 
,   a.[Дата] 
,   a.[request_id] 
,   a.[status_order] 
,   0 is_fake
into #t2_
from 

#t2 a
union all
select a.[status] 
,   a.[id] 
,   a.[num_1c] 
,   a.[Дата] 
,   a.[request_id] 
,   a.[status_order] 
,   1 is_fake
  from (
select 
     null [status] 
,   null [id] 
,   a.[num_1c] 
,   dateadd(second, -b.[status_order],  a.[Дата] ) 	 [Дата]
,   a.[request_id] 
,     b.[status_order] [status_order] 
,   1 is_fake
, row_number() over(partition by a.[request_id] ,  b.[status_order]  order by  dateadd(second, -b.[status_order],  a.[Дата] )  ) rn
from 

#t2 a 
join 	(select distinct [status_order] from  #inst_status) b on a.[status_order]>b.[status_order]
left join 	 #t2 c on a.[request_id]=c.[request_id] and b.[status_order]=c.[status_order]
where c.[request_id] is  null
) a
where rn=1

--select * from #t2_				
--where request_id = 1607487
--order 					by  Дата

drop table if exists #t3

select *, 'lk' t  into  #t3 
from #t2_
		   

--drop table if exists _birs.[Installment тайминг детализация]
--select * into _birs.[Installment тайминг детализация] from #t3
delete from _birs.[Installment тайминг детализация]
insert into _birs.[Installment тайминг детализация]
select * from #t3
  
drop table if exists #t4

--select * from stg._lk.events

select request_id request_id_status ,
 max(case when status_order=1 then a.Дата end)   [Анкета],
 max(case when status_order=2 then a.Дата end)   [Паспорт],
 max(case when status_order=3 then a.Дата end)   [Фотографии],
 max(case when status_order=4 /*and b.[Предварительное одобрение] is not null*/ then a.Дата end)   [Подписание первого пакета],
 max(case when status_order=4.5 and b.[Верификация КЦ] is not null  then a.Дата end)           [Call 1],
 max(case when status_order=5 and b.[Предварительное одобрение] is not null then a.Дата end)   [О работе и доходе],
 max(case when status_order=6 and b.[Предварительное одобрение] is not null then a.Дата end)   [Добавление карты],
 max(case when status_order=7 and b.[Предварительное одобрение] is not null then a.Дата end)   [Одобрение],
 max(case when status_order=8 and b.[Предварительное одобрение] is not null then a.Дата end)   [Выбор предложения],
 max(case when status_order=9 and b.[Предварительное одобрение] is not null then a.Дата end)   [Подписание договора],
 max(case when status like '%ЛКК%' then 'ЛКК,' else '' end) +
 max(case when status like '%МП%' then 'МП,' else '' end) [lkk_or_mp]  ,
 max(case when id in ( 91, 69, 70, 92 ) then 1 else 0 end) [is_repeated_lk]  ,
 case when max(is_fake)=1  then 1 else 0 end  is_fake  ,
 max(status_order) [current_status]
into #t4	  -- select *   
from #t3   a
left join reports.dbo.dm_factor_analysis_001 b on b.Номер=a.num_1c

group by  request_id
--order by 	 



drop table if exists #loans
select [Заем выдан]  ,   [Заем погашен],    Телефон, Номер, isInstallment into #loans from mv_dm_Factor_Analysis
where [Заем выдан] is not null
insert into 	 #loans
select [Дата выдачи], [Дата погашения], [Телефон договор CMR], [Номер заявки], isInstallment from mv_loans	 where [Номер заявки] not in (
	  select Номер from #loans
)

	 --  select * from #loans


drop table if exists 	  #inst_an
  select  a.id, 
  b.Номер,
  b.[Договор подписан] [Договор подписан], 
  b.[Заем выдан] [Выдача денег], 
  b.[Выданная сумма] [Выданная сумма], 
  isnull(nullif(b.[Первичная сумма], 0), a.summ) [Запрошенная сумма],
 -- isnull( b.[Вид займа] ,
 -- case 
 -- when  cnt_dcr>0 then 'Докредитование'
 -- when  cnt_povt>0 then 'Повторный'
 -- else 'Первичный' end  ) [Вид займа]
 --																	 ,
  
  case 
  when  cnt_dcr>0  then 'Докредитование'
  when  cnt_povt>0 then 'Повторный'
  else 'Первичный' end   [Вид займа]
 
 ,b.[Верификация кц] [Верификация кц]
 ,b.[Предварительное одобрение] [Предварительное одобрение]
 ,b.[Контроль данных] [Контроль данных]
 ,b.Одобрено Одобрено
 ,b.Отказано Отказано
 , b.[Процентная ставка]
 , b.[Срок займа]
 , b.[Заем погашен]


  into #inst_an 	 --select top 100 *
  
  from #requests_lk a

  outer apply (select count(*) cnt_povt from #loans b where isinstallment=1 and (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.client_mobile_phone=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.created_at  	 )  [povt_tel]
  outer apply (select count(*) cnt_dcr from #loans  b where isinstallment=1 and (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.client_mobile_phone=b.Телефон) and b.[Заем выдан]<=a.created_at and isnull(b.[Заем погашен], GETDATE() ) > a.created_at  )    [docr_tel]	 
  left join --select top 100 * from
  reports.dbo.dm_factor_analysis_001 b on b.Номер=a.num_1c

  drop table if exists #oper

select Сотрудник Оператор
into #oper
from analytics.dbo.employees 
where Направление = 'Installment' 



drop table if exists #odobr 

select n.НомерЗаявки 

into #odobr 
from
v_dm_Все_коммуникации_На_основе_отчета_из_crm n
join  Reports.dbo.dm_Factor_Analysis_001 fa on n.НомерЗаявки=fa.Номер and Одобрено is not null --and isInstallment=1
join #oper o on n.ФИО_оператора  =  o.Оператор
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and [ДатаВремяВзаимодействия] between @datefrom and @dateto
and [ДатаВремяВзаимодействия] >=Одобрено and [ДатаВремяВзаимодействия]<=isnull([Заем выдан], dateadd(day, 10, Одобрено))
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]
		  group by n.НомерЗаявки 




 drop table if exists #next_loans
 select Номер, next_product, [Кол-во закрытых займов в рамках продукта] into #next_loans from return_types
 where --next_product is not null
 --and 
 isinstallment=1


   --select * from LK_requests_origin
drop table if exists #t5
select a.id                                 
,      cast(a.created_at                          as date)	created_at_date
,      a.created_at    
,      c.[Верификация кц]    
,      c.[Предварительное одобрение]
,      c.[Контроль данных]
,      c.Одобрено
,      c.[Договор подписан]
,      c.[Выдача денег]
,      c.[Запрошенная сумма]    
,      c.[Выданная сумма]
,      c.[Процентная ставка]
,      c.[Срок займа]
,      c.[Заем погашен]
,      c.Отказано
,      a.num_1c                             
,      a.is_installment                     
,      a.prolongations_cnt                     
,      a.[product_type]                     
,      a.[product_type_initial]                     
,      a.origin_name_1c                     
--,      a.[Наличие зеленого предложения]                     
,      a.lcrm_id                     
,      a.client_mobile_phone
--,      dbo.to_md5( a.client_mobile_phone, 1) client_mobile_phone_md5
,     '' client_mobile_phone_md5
,     isnull(  b.[Анкета] , case when a.origin_name_1c = 'ЛККлиента' then a.created_at end)	 [Анкета] --на ЛКК этот шаг обычно уже пройден
,     b.[Паспорт]
,     b.[Фотографии]
,     b.[Подписание первого пакета]
,     b.[Call 1]
,     b.[О работе и доходе]
,     b.[Добавление карты]
,     b.[Одобрение]
,     b.[Выбор предложения]
,     b.[Подписание договора]
,     b.[current_status]
,     b.[lkk_or_mp]
,     b.[is_repeated_lk]
,     b.is_fake	  has_fake_status
,     b.request_id_status
,     c.[Вид займа]   
,  	  case when c.Одобрено is not null then case when d.НомерЗаявки is not null then 1 else 0 end end	 [Признак ручное доведение на TU]
,     e.[Маркетинговые расходы]
,     nl.next_product [Повторный займ] 
,     nl.[Кол-во закрытых займов в рамках продукта] [Кол-во закрытых займов в рамках продукта] 
, 	  c_next.[Выданная сумма]  [Повторный займ сумма]
, 	  e_next.[Маркетинговые расходы]  [Повторный займ Маркетинговые расходы]
 
into #T5
from      #requests_lk a
left join #t4          b on a.id = b.request_id_status
left join #inst_an     c on a.id = c.id
left join #odobr d on d.НомерЗаявки=a.num_1c
left join #next_loans nl on nl.Номер=a.num_1c

left join (select Номер НомерСтЗ, [Маркетинговые расходы] from  [v_Отчет стоимость займа опер] ) e on a.num_1c=e.НомерСтЗ

left join #inst_an     c_next on nl.next_product = c_next.Номер
left join (select Номер НомерСтЗ2, [Маркетинговые расходы] from  [v_Отчет стоимость займа опер] ) e_next on c_next.Номер=e_next.НомерСтЗ2


--order by created_at desc


drop table if exists  #doubles
													  
select a.id, case when a.[Выдача денег] is not null then 0 when max( b.id) is not null then 1 else 0 end [Дубль]
into #doubles
from #T5 a
 left join #T5 b
on cast(a.created_at as date)= cast(b.created_at as date)
 and a.client_mobile_phone_md5=b.client_mobile_phone_md5
 and ( b.[current_status]>a.current_status or ( b.[current_status]=a.current_status  and b.created_at>a.created_at) )
 group by  a.id	 , a.[Выдача денег] 
	--order by 
--order by 


drop table if exists #t6

	   select   
	   a.[id] 
,      a.created_at_date 
,      a.lcrm_id 
,      a.[created_at] 
,      a.[Вид займа] 
,      a.[Кол-во закрытых займов в рамках продукта] 
,      a.[Верификация кц]    
,      a.[Предварительное одобрение]    
,      a.[Контроль данных]    
,      a.Одобрено    
,      a.[Договор подписан]    
,      a.[Выдача денег] 					  	   
,      a.[Запрошенная сумма] 
,      a.[Выданная сумма] 
,      a.[Процентная ставка]
,      a.[Срок займа]
,      a.[Заем погашен]
,      a.Отказано    
,      case when a.Отказано    is not null then 1  end [Признак Отказано]
,      a.[is_installment] 
,      a.prolongations_cnt 
,      a.[product_type] 
,      a.[product_type_initial] 
,      a.[num_1c] 
,      a.[origin_name_1c] 
--,     -- a.[Наличие зеленого предложения] 
,      a.client_mobile_phone 
,      a.[client_mobile_phone_md5] 
,      a.[request_id_status] 
,      datediff(second, [created_at] , [Договор подписан] ) /86400.0 [created_at - Договор подписан]
,      datediff(second, [Договор подписан] ,  [Выдача денег]) /86400.0 [Договор подписан - Выдача денег]
,      datediff(second, [created_at] , [Анкета] ) /86400.0 [created_at - Анкета]
,      a.[Анкета] 
,      datediff(second, [Анкета] , Паспорт ) /86400.0 [Анкета - Паспорт]
,      a.Паспорт 
,      datediff(second, Паспорт , Фотографии )/86400.0  [Паспорт - Фотографии]
,      a.Фотографии 
,      datediff(second, Фотографии , [Подписание первого пакета] )/86400.0  [Фотографии - Подписание первого пакета]
,      a.[Подписание первого пакета] 
,      datediff(second, [Подписание первого пакета] , [О работе и доходе] )/86400.0  [Подписание первого пакета - О работе и доходе]
,      datediff(second, [Подписание первого пакета] , [Верификация кц] )/86400.0  [Подписание первого пакета - ВКЦ]
,      datediff(second, [Подписание первого пакета] , [Предварительное одобрение] )/86400.0  [Подписание первого пакета - Предварительное одобрение]
,      datediff(second, [Верификация кц] , [Предварительное одобрение] )/86400.0  [ВКЦ - Предварительное одобрение]
,      a.[Call 1]
,      a.[О работе и доходе] 
,      datediff(second, [О работе и доходе] , [Добавление карты] )/86400.0  [О работе и доходе - Добавление карты]	   
,      a.[Добавление карты] 
,      datediff(second, [Добавление карты] , Одобрение ) /86400.0 [Добавление карты - Одобрение]	   
,      a.Одобрение 
,      datediff(second, Одобрение , [Выбор предложения] )/86400.0  [Одобрение - Выбор предложения]	   
,      a.[Выбор предложения] 
,      datediff(second, [Выбор предложения] , [Подписание договора] )/86400.0  [Выбор предложения - Подписание договора]	   
,      a.[Подписание договора] 
,      datediff(second, [Подписание договора] , [Выдача денег] )/86400.0  [Подписание договора - Выдача денег]	   
,      case when a.[Выдача денег] is not null then 1 end [Выдача]					  
,      a.[lkk_or_mp] 
,      a.[is_repeated_lk] 
,      a.has_fake_status 
,      a.[current_status] 
,      b.Дубль
,      case when [Предварительное одобрение] is not null then 1 end  [Признак Предварительное одобрение]
,      case  when [Верификация КЦ] is null  then 1
	   	  else 0 end [Признак застрял]
,      getdate() created
,     [Признак ручное доведение на TU]
,     [Маркетинговые расходы]
,     [Повторный займ] 
, 	  [Повторный займ сумма]
, 	  [Повторный займ Маркетинговые расходы]
      into #t6
      from #T5	a
	  left join #doubles b on a.id=b.id
 	
--	drop table if exists _birs.[Installment тайминг таблица]
--	select * into _birs.[Installment тайминг таблица] from #t6

		--select * from #t6
	--	select * from _birs.[Installment тайминг таблица]

	
	
	if @recreate = 1
	begin
	drop table if exists _birs.[Installment тайминг таблица]
	select * into _birs.[Installment тайминг таблица] from #t6

declare @sql nvarchar(max)
select @sql = (
 
SELECT string_agg(  'DROP TABLE  if exists  ' + LEFT([name], CHARINDEX('_', [name]) -1) ,  ';')
FROM tempdb.sys.objects
WHERE [name] LIKE '#%'
and  [name] not LIKE '##%'
AND CHARINDEX('_', [name]) > 0
AND [type] = 'U'
AND NOT object_id('tempdb..' + [name]) IS NULL )
 exec (@sql )



		 




	 exec [_birs].[Installment воронка создание] 'update' , @recreate

	return

	end


 --drop table if exists _birs.[Installment тайминг таблица]
 --select * into _birs.[Installment тайминг таблица] from #t6
--
delete from _birs.[Installment тайминг таблица]
insert into _birs.[Installment тайминг таблица]
select * from #t6
--select * from _birs.[Installment тайминг таблица]
--select [Признак застрял], count([Верификация КЦ]) cnt from _birs.[Installment тайминг таблица]
--group by [Признак застрял]
----order by 
--
--
--
--select * from _birs.[Installment тайминг таблица]
--
return
end


if @mode = 'select'
begin
--exec _birs.[Installment тайминг] 'update'
		
--		SELECT [UF_REGISTERED_AT день]
--	,[Группа каналов]
--	,[Канал от источника]
--	,UF_TYPE
--	,case when UF_TYPE='api' then 'api' else 'не api' end [Признак api]
--	,UF_LOGINOM_STATUs
--	,[Признак профильный лид]
--	,[Признак обработан лид]
--	,[Признак дозвон]
--	,[Количество лидов]
--	,[Номер CRM]
--	,b.*
--FROM report_leads_full a
--
--
--left join _birs.[Installment тайминг таблица] b on a.[Номер CRM]  = b.num_1c
--where [UF_REGISTERED_AT день]>='20230701'							and a.[isinstallment crm]=1
--
--return

SELECT a.*
FROM _birs.[Installment тайминг таблица] a
-- join mv_dm_Factor_Analysis b on a.num_1c=b.Номер and b.[Предварительное одобрение] is not null

end

if @mode = 'details'
begin
--exec _birs.[Installment тайминг] 'update'
		 
SELECT a.*
FROM _birs.[Installment тайминг детализация] a

end



		 /*
select a.name,a.created_at, a.id, a.t, a.num_1c, case when r.is_installment=1 then 'Инст' else 'ПТС' end product from #t3	a 
join (select distinct id from #t3 where name = 'Одобрено' and  created_at>=getdate()-30) b on a.id=b.id
join stg._lk.requests r on a.id=r.id
--where a.created_at>=getdate()-30
order by a.id,	a.created_at

	   ;
	   with st as (
select 'Инстолмент ЛКК: Переход с Анкеты на Паспорт ? Открытие Паспорта'   status
union all select 'Верификация Call 2'
union all select 'Инстолмент ЛКК: Переход с Фото клиента и документов на Подписание первого пакета ? Открытие Подписания первого пакета'
union all select 'Инстолмент ЛКК: Переход с Подписание первого пакета на О работе и доходе ? Открытие О работе и доходе'
union all select 'Инстолмент ЛКК: Переход с О работе и доходе на Выбор способ выдачи ? Открытие Выбора способ выдачи'
union all select 'Инстолмент ЛКК: Переход с Выбор способ выдачи  на Ожидание одобрения ? Открытие Ожидания одобрения'
union all select 'Верификация Call 3'
union all select 'Инстолмент ЛКК: Переход с Ожидания одобрения на Выбор предложения ? Открытие Выбора предложения' 
union all select 'Инстолмент ЛКК: Переход с Выбора предложения на Подписание договора ? Открытие Подписания договора'
union all select 'Подписан 2 пакет документов'
union all select 'Заем выдан'
	)
	select * from st	 a
	left join #t3 b on a.status=b.name
	where b.name is  null
;
with v as (
																					  
select id
, min(case when name in ( 'Регистрация в МП' ) then created_at end ) [Регистрация в МП]
, min(case when name in ( 'Переход в МП с шага 1 на 2 шаг', 'Клиент выбрал параметры продукта' ) then created_at end ) [Клиент выбрал параметры продукта]
, min(case when name in (  'Переход в МП с шага 2 на 2.5 шаг (ПЭП)', 'Клиент заполнил базовую личную информацию' ) then created_at end ) [Клиент заполнил базовую личную информацию]

--, min(case when name = 'Подписан 1 пакет документов' then created_at end ) [Подписан 1 пакет документов]
, min(case when name = '1-й пакет подписан ПЭП' then created_at end ) [1-й пакет подписан ПЭП]
, min(case when name = 'Отправлена предварительная заявка' then created_at end ) [Отправлена предварительная заявка]
, min(case when name = 'Клиент заполнил информацию по авто' then created_at end ) [Клиент заполнил информацию по авто]
, min(case when name = 'Верификация КЦ' then created_at end ) [Верификация КЦ]
, min(case when name =  'Предварительное одобрение' then created_at end ) [Предварительное одобрение]
, min(case when name =  'Клиент сделал фото паспорта и селфи' then created_at end ) [Клиент сделал фото паспорта и селфи]
, min(case when name =  'Отправлены файлы сканы документов' then created_at end ) [Отправлены файлы сканы документов]
, min(case when name =  'Контроль данных' then created_at end ) [Контроль данных]
, min(case when name =  'Верификация Call 1.5' then created_at end ) [Верификация Call 1.5]
, min(case when name =  'Верификация Call 2' then created_at end ) [Верификация Call 2]
, min(case when name =  'Верификация клиента' then created_at end ) [Верификация клиента]
, min(case when name =  'Клиент сделал фото авто' then created_at end ) [Клиент сделал фото авто]
, min(case when name =  'Верификация ТС' then created_at end ) [Верификация ТС]
, min(case when name =  'Одобрено' then created_at end ) [Одобрено]
, min(case when name =  'Проверка карты прошла успешно' then created_at end ) [Проверка карты прошла успешно]
, min(case when name =  'Подписание 2-го пакета (анкета)' then created_at end ) [Подписание 2-го пакета (анкета)]
, min(case when name =  'Подписание 2-го пакета (прочее)' then created_at end ) [Подписание 2-го пакета (прочее)]
, min(case when name =  'Подписан 2 пакет документов' then created_at end ) [Подписан 2 пакет документов]

from #t3								 r
group by 						 id
)

select b.[Место cоздания]
, b.Место_создания_2 
, a.* 

from  
v 	   a
left join stg._LK.requests r on a.id=r.id
left join reports.dbo.dm_Factor_Analysis b on a.id=b.request_id
where Место_создания_2='МП'
order by r.created_at 

*/

end
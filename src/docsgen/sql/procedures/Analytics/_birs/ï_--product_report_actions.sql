
CREATE   proc [_birs].[product_report_actions]   @mode nvarchar(max) = 'select'	  , @recreate int =0
--exec [_birs].[product_report_actions]    'update'	  ,  1		 exec [_birs].[product_report_actions]    'select'	  ,  1  exec [_birs].[product_report]    'update'	  ,  1
as
begin

if @mode = 'update'
begin


				 

drop table if exists #prolongation

select d.Код, count(*) prolongations_cnt, min(dateadd(year, -2000, a.Период)) first_prolongation_dt into #prolongation from stg._1ccmr.[РегистрНакопления_PDLПролонгации]   a join stg._1cCMR.Справочник_Договоры d on a.Договор=d.Ссылка
where ВидДвижения=1
group by d.Код

--select * from 	#prolongation


drop table if exists #auto_apr
								  
select distinct a.[Номер заявки] number into #auto_apr from [Отчет Время статусов верификации] a


where [Время Затрачено В работе]=0		  and  a.Статус='Верификация клиента'
--order by a.Номер desc
drop table if exists #requests_crm

select number, СрокЛьготногоПериода into #requests_crm  from v_request_crm where СрокЛьготногоПериода>0 


drop table if exists #requests_lk

select r.id	  id				 
,      r.full_created_at	 created_at
,      r.num_1c	   number
,      is_installment  is_installment
, 	   b.name_1c	origin_name_1c
, isnull ( z.Телефон,  r.client_mobile_phone   ) 	client_mobile_phone
, r.lcrm_id
--, green.[Наличие зеленого предложения]	[Наличие зеленого предложения]
, r.summ	

, case	
product_types_id
when 1 then 'PTS'
when 2 then 'INST'
when 3 then 'PDL'
end [product_type]
, case  z.ТипПродуктаПервоначальный  when 'Installment' then 'INST' else  z.ТипПродуктаПервоначальный end  +'_initial'	  [product_type_initial]	 
, pr.prolongations_cnt	
, pr.first_prolongation_dt
, z.feodor_request_id
, ispts = case when is_installment=1	  or  product_types_id in (2,3)	  then 0 else 1 end 
, r.client_total_monthly_income
 
,z.СтатусЗаявки
,z.term_days 
, rcrm.СрокЛьготногоПериода free_term_days
, case when ispdl=1 then dateadd(day, term_days,   z.[Заем выдан]) end closed_date_plan
, case when Одобрено is not null and   pr1.number is not null then 1 when   Одобрено is not null then 0 end is_automatic_approve
, [Верификация документов клиента]
into #requests_lk	--select top 100 * 
from stg._lk.requests r
left join stg._LK.requests_origin b	   on r.requests_origin_id=b.id
left join v_request z on z.lk_request_id=r.id
--left join (
--select * from initial_products
--where isinitalproduct=1 ) initial on initial.объект_ссылка=z.СсылкаЗаявки
 left join #prolongation pr on pr.Код=z.КодДоговораЗайма
 left join #auto_apr pr1 on pr1.number=z.НомерЗаявки
 left join #requests_crm rcrm on rcrm.number=r.num_1c
 		--	  select distinct ТипПродуктаПервоначальный  from v_request

--left join #green green	   on r.id=green.id
where   r.created_at>='20230101'
 
 
drop table if exists #status	 
 select * into #status from (
select is_pts=0,  lk_id= 68 ,  status_order = 1, source = 'lk'   union  	
select is_pts=0,  lk_id= 69 ,  status_order = 1, source = 'lk'   union  	
select is_pts=0,  lk_id= 70 ,  status_order = 2, source = 'lk'   union  	
select is_pts=0,  lk_id= 70 ,  status_order = 3, source = 'lk'   union  
select is_pts=0,  lk_id= 71 ,  status_order = 2, source = 'lk' union  
select is_pts=0,  lk_id= 72 ,  status_order = 3, source = 'lk' union  
select is_pts=0,  lk_id= 73 ,  status_order = 4, source = 'lk' union  
select is_pts=0,  lk_id= 73  ,  status_order = 4.5, source = 'lk' union  

select is_pts=0,  lk_id= 74 ,  status_order = 5, source = 'lk' union  
select is_pts=0,  lk_id= 75 ,  status_order = 6, source = 'lk' union  
select is_pts=0,  lk_id= 416 ,  status_order = 6, source = 'lk' union  
select is_pts=0,  lk_id= 417 ,  status_order = 6, source = 'lk' union  
select is_pts=0,   lk_id= 76 ,  status_order = 7, source = 'lk' union  
select is_pts=0,   lk_id= 77 ,  status_order = 8, source = 'lk' union  
select is_pts=0,   lk_id= 78 ,  status_order = 9, source = 'lk'    
																																			
union 

select  is_pts=0, lk_id= 90  ,  status_order = 1, source = 'lk'   union  	 
select  is_pts=0, lk_id= 91  ,  status_order = 1, source = 'lk'   union  	 
select  is_pts=0, lk_id= 92  ,  status_order = 2, source = 'lk'   union  	 
select  is_pts=0, lk_id= 92  ,  status_order = 3, source = 'lk'   union  	 
select  is_pts=0, lk_id= 93  ,  status_order = 2, source = 'lk' union  
select  is_pts=0, lk_id= 94  ,  status_order = 3, source = 'lk' union  
select  is_pts=0, lk_id= 95  ,  status_order = 4, source = 'lk' union  
select  is_pts=0, lk_id= 95  ,  status_order = 4.5, source = 'lk' union  
select  is_pts=0, lk_id= 96  ,  status_order = 5, source = 'lk' union  
select  is_pts=0, lk_id= 97  ,  status_order = 6, source = 'lk' union  
select  is_pts=0, lk_id= 98  ,   status_order = 7, source = 'lk' union  
select  is_pts=0, lk_id= 99  ,  status_order = 8, source = 'lk' union  
select  is_pts=0, lk_id= 100 ,    status_order = 9, source = 'lk' union 


--select  is_pts=1, lk_id= 79	     ,  status_order = 1  , source = 'lk' union  
--select  is_pts=1, lk_id= 80	     ,  status_order = 2  , source = 'lk' union  
--select  is_pts=1, lk_id= 81	     ,  status_order = 3  , source = 'lk' union  
select  is_pts=1, lk_id= 79	  ,  status_order =1	, source = 'lk' union  				--([Переход на калькулятор ПТС]) 510 - "Переход в МП с основного калькулятора на калькулятор ПТС - Именование новое ""ПТС МП: Переход с Настройки займа на Выбор условий"" - Открытие В 
select  is_pts=1, lk_id= 80	  ,  status_order =2	, source = 'lk' union  				--([Переход на Анкету ПТС]) 515 - ПТС МП: Переход с калькулятор на Анкету - Открытие Анкеты
select  is_pts=1, lk_id= 442	  ,  status_order =2	, source = 'lk' union  			--([Переход на Анкету ПТС]) 915 - ПТС ЛКК: Переход с калькулятор на Анкету - Открытие Анкеты
select  is_pts=1, lk_id= 81	  ,  status_order =3	, source = 'lk' union  				--([Открытие слота 2-3 стр паспорта ПТС])  520 - ПТС МП: Переход с Анкеты на Фото паспорта - Открытие Фото паспорта
select  is_pts=1, lk_id= 438	  ,  status_order =3	, source = 'lk' union  			--([Открытие слота 2-3 стр паспорта ПТС])  920 - ПТС ЛКК: Переход с Анкеты на Фото паспорта - Открытие Фото паспорта
select  is_pts=1, lk_id= 376	  ,  status_order =4	, source = 'lk' union  			--([Загрузка 2-3 стр паспорта ПТС])	5010 -passport_2_3 - загружено
select  is_pts=1, lk_id= 82	  ,  status_order =5	, source = 'lk' union  				--([Переход на 1 пакет ПТС]) 525 - ПТС МП: Переход с Фото паспорта на Подписание первого пакета - Открытие Подписания первого пакета
select  is_pts=1, lk_id= 441	  ,  status_order =5	, source = 'lk' union  			--([Переход на 1 пакет ПТС]) 925 - ПТС ЛКК: Переход с Фото паспорта на Подписание первого пакета - Открытие Подписания первого пакета
select  is_pts=1, lk_id= 1	  ,  status_order =6	, source = 'lk' union  				--([Подписание 1 пакета ПТС]) 101 - Подписан 1 пакет документов
select  is_pts=1, lk_id= 315	  ,  status_order =6	, source = 'lk' union  			--([Подписание 1 пакета ПТС]) 2804 - Подписан 1й пакет документов
select  is_pts=1, lk_id= 83	  ,  status_order =7	, source = 'lk' union  				--([Переход на экран Фото паспорта ПТС]) 530 - ПТС МП: Переход с Подписание первого пакета на Фото паспорта и клиента - Открытие Фото паспорта и клиента
select  is_pts=1, lk_id= 432	  ,  status_order =7	, source = 'lk' union  			--([Переход на экран Фото паспорта ПТС]) 930 - ПТС ЛКК: Переход с Подписание первого пакета на Фото паспорта и клиента - Открытие Фото паспорта и клиента
select  is_pts=1, lk_id= 84	  ,  status_order =8	, source = 'lk' union  				--([Переход на экран с дополнительной информацией ПТС])	535 - ПТС МП: Переход с Фото паспорта и клиента на Дополнительную информацию - Открытие Дополнительную информацию
select  is_pts=1, lk_id= 444	  ,  status_order =8	, source = 'lk' union  			--([Переход на экран с дополнительной информацией ПТС])	935 - ПТС ЛКК: Переход с Фото паспорта и клиента на Дополнительную информацию - Открытие Дополнительную информацию
select  is_pts=1, lk_id= 85	  ,  status_order =9	, source = 'lk' union  				--([Переход на экран с фото документов авто ПТС]) 540 - ПТС МП: Переход с Дополнительной информации на Фото документов авто - Открытие Фото документов авто
select  is_pts=1, lk_id= 434	  ,  status_order =9	, source = 'lk' union  			--([Переход на экран с фото документов авто ПТС]) 940 - ПТС ЛКК: Переход с Дополнительной информации на Фото документов авто - Открытие Фото документов авто
select  is_pts=1, lk_id= 86	  ,  status_order =10	, source = 'lk' union  				--([Переход на экран Способ выдачи ПТС]) 545 - ПТС МП: Переход с Фото документов авто на Выбор способ выдачи - Открытие Выбор способ выдачи
select  is_pts=1, lk_id= 431	  ,  status_order =10	, source = 'lk' union  			--([Переход на экран Способ выдачи ПТС]) 945 - ПТС ЛКК: Переход с Фото документов авто на Выбор способ выдачи - Открытие Выбор способ выдачи
select  is_pts=1, lk_id= 17	  ,  status_order =11	, source = 'lk' union  				--([Карта привязана ПТС]) 811 - Проверка карты прошла успешно
select  is_pts=1, lk_id= 87	  ,  status_order =12	, source = 'lk' union  				--([Переход на фото авто ПТС]) 550 - ПТС МП: Переход с Выбора способа выдачи на Фото автомобиля - Открытие Фото автомобиля
select  is_pts=1, lk_id= 435	  ,  status_order =12	, source = 'lk' union  			--([Переход на фото авто ПТС]) 950 - ПТС ЛКК: Переход с Выбора способа выдачи на Фото автомобиля - Открытие Фото автомобиля
--select  is_pts=1, lk_id= 6	  ,  status_order =13	, source = 'lk' union  
select  is_pts=1, lk_id= 8	  ,  status_order =13	, source = 'lk' union  				 --([Финальное одобрение ПТС]) 712 - Отправлены файлы фотографии авто
select  is_pts=1, lk_id= 89	  ,  status_order =14	, source = 'lk' union  				 --([Переход на фото авто ПТС])	560 - ПТС МП: Переход с Ожидания одобрения на Подписание договора - Открытие Подписание договора
select  is_pts=1, lk_id= 428	  ,  status_order =14	, source = 'lk' union  			 --([Переход на второй пакет ПТС]) 960 - ПТС ЛКК: Переход с Ожидания одобрения на Подписание договора - Открытие Подписание договора
select  is_pts=1, lk_id= 2	  ,  status_order =15	, source = 'lk' union  				 --([Подписание второго пакета ПТС]) 102 - Подписан 2 пакет документов
select  is_pts=1, lk_id= 361	  ,  status_order =15	, source = 'lk' --union    		 --([Подписание второго пакета ПТС]) 2814 - Подписан 2й пакет документов
			) x

						--	select * from #status  a
						--	left join stg._lk.events e on a.lk_id=e.id
						--	where is_pts=1
						--							 order by 3
						--    select id, name, created_at from  stg._lk.events
						--    order by 1


--select a.*, e.name from #inst_status a
--left join stg._lk.events e on e.id=a.lk_id
--order by status_order
--  
--
--  select id, name, created_at from  stg._lk.events
--  order by 1

drop table if exists #t2

select e.name status,e.id, r.number , re.created_at Дата, r.id request_id, s.status_order, r.ispts  into #t2 from stg._LK.events	  e
join Stg._LK.requests_events re on re.event_id=e.id
join #requests_lk r  on r.id=re.request_id
 join  #status   s on s.lk_id=e.id and r.ispts=s.is_pts
--where r.is_installment=1

drop table if exists  #t2_
					 
select 
    a.[status] 
,   a.[id] 
,   a.number 
,   a.[Дата] 
,   a.[request_id] 
,   a.ispts 
,   a.[status_order] 
,   0 is_fake
into #t2_
from 

#t2 a
union all
select a.[status] 
,   a.[id] 
,   a.number 
,   a.[Дата] 
,   a.[request_id] 
,   a.ispts
,   a.[status_order] 
,   1 is_fake
  from (
select 
     null [status] 
,   null [id] 
,   a.number 
,   dateadd(second, -b.[status_order],  a.[Дата] ) 	 [Дата]
,   a.[request_id] 
,   a.ispts 
,     b.[status_order] [status_order] 
,   1 is_fake
, row_number() over(partition by a.[request_id] ,  b.[status_order]  order by  dateadd(second, -b.[status_order],  a.[Дата] )  ) rn
from 

#t2 a 
join 	(select distinct [status_order], is_pts from  #status) b on a.[status_order]>b.[status_order] and a.ispts=b.is_pts
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
		   

		   if @recreate=1 begin

drop table if exists _birs.[product_report_status_details]
select * into _birs.[product_report_status_details] from #t3
end


delete from _birs.[product_report_status_details]
--<?query --

--select top 100 * from _birs.[product_report_status_details]
insert into _birs.[product_report_status_details]
select * from #t3
  
drop table if exists #t4

--select * from stg._lk.events

select request_id request_id_status ,
 min(case when a.ispts=0 and status_order=1 then a.Дата end)   [Анкета],
 min(case when a.ispts=0 and status_order=2 then a.Дата end)   [Паспорт],
 min(case when a.ispts=0 and status_order=3 then a.Дата end)   [Фотографии],
 min(case when a.ispts=0 and status_order=4 /*and b.[Предварительное одобрение] is not null*/ then a.Дата end)   [Подписание первого пакета],
 min(case when a.ispts=0 and status_order=4.5 and b.[Верификация КЦ] is not null  then a.Дата end)           [Call 1],
 min(case when a.ispts=0 and status_order=5 and b.[Предварительное одобрение] is not null then a.Дата end)   [О работе и доходе],
 min(case when a.ispts=0 and status_order=6 and b.[Предварительное одобрение] is not null then a.Дата end)   [Добавление карты],
 min(case when a.ispts=0 and status_order=7 and b.[Предварительное одобрение] is not null then a.Дата end)   [Одобрение],
 min(case when a.ispts=0 and status_order=8 and b.[Предварительное одобрение] is not null then a.Дата end)   [Выбор предложения],
 min(case when a.ispts=0 and status_order=9 and b.[Предварительное одобрение] is not null then a.Дата end)   [Подписание договора],
 max(case when status like '%ЛКК%' then 'ЛКК,' else '' end) +
 max(case when status like '%МП%' then 'МП,' else '' end) [lkk_or_mp]  ,
 max(case when id in ( 91, 69, 70, 92 ) then 1 else 0 end) [is_repeated_lk]  ,
 case when max(is_fake)=1  then 1 else 0 end  is_fake  
 , isnull(max(status_order),max(case when b.[Заем выдан] is not null then 999 else 0 end)) [current_status]									 
 
 ,min(case when a.ispts=1 and status_order= 1	then a.Дата end)                               [Переход на калькулятор ПТС]
 ,min(case when a.ispts=1 and status_order= 2	then a.Дата end)                               [Переход на Анкету ПТС]
 ,min(case when a.ispts=1 and status_order= 3	then a.Дата end)                               [Открытие слота 2-3 стр паспорта ПТС]
 ,min(case when a.ispts=1 and status_order= 4	then a.Дата end)                               [Загрузка 2-3 стр паспорта ПТС]
 ,min(case when a.ispts=1 and status_order= 5	then a.Дата end)                               [Переход на 1 пакет ПТС]
 ,min(case when a.ispts=1 and status_order= 6	then a.Дата end)                               [Подписание 1 пакета ПТС]
 --,max(case when a.ispts=1 and status_order= 6	then a.Дата end)                               [Подписание 1 пакета ПТС]
 ,min(case when a.ispts=1 and status_order= 7	then a.Дата end)                               [Переход на экран Фото паспорта ПТС]
 ,min(case when a.ispts=1 and status_order= 8	then a.Дата end)                               [Переход на экран с дополнительной информацией ПТС]
 ,min(case when a.ispts=1 and status_order= 9	then a.Дата end)                               [Переход на экран с фото документов авто ПТС]
 ,min(case when a.ispts=1 and status_order= 10	then a.Дата end)                               [Переход на экран Способ выдачи ПТС]
 ,min(case when a.ispts=1 and status_order= 11	then a.Дата end)                               [Карта привязана ПТС]
 ,min(case when a.ispts=1 and status_order= 12	then a.Дата end)                               [Переход на фото авто ПТС]
 ,min(case when a.ispts=1 and status_order= 13	then a.Дата end)                               [Отправлена полная заявка ПТС]
 ,min(case when a.ispts=1 and status_order= 13 and b.Одобрено is not null	then a.Дата end)   [Финальное одобрение ПТС]
 ,min(case when a.ispts=1 and status_order= 14 and b.Одобрено is not null	then a.Дата end)   [Переход на второй пакет ПТС]
 ,min(case when a.ispts=1 and status_order= 15 and b.Одобрено is not null	then a.Дата end)   [Подписание второго пакета ПТС]

into #t4	  -- select *   
from #t3   a
left join reports.dbo.dm_factor_analysis_001 b on b.Номер=a.number

group by  request_id
--order by 	 



drop table if exists #loans
select [Заем выдан]  ,   [Заем погашен],    Телефон, Номер, isPts, ispdl,  case when ispdl=1 then 'pdl' when isInstallment=1 then 'inst' when isPts=1 then 'pts' end product_type  into #loans from mv_dm_Factor_Analysis
where [Заем выдан] is not null
insert into 	 #loans
select [Дата выдачи], [Дата погашения], [Телефон договор CMR], [Номер заявки], 1-isInstallment isPts, 0 , 'pts' from mv_loans	 where [Номер заявки] not in (
	  select Номер from #loans
)

	 --  select * from #loans


drop table if exists 	  #inst_an
  select  a.id, 
  b.number number,
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
  when  docr_tel.cnt_dcr>0  then 'Докредитование'
  when  povt_tel.cnt_povt>0 then 'Повторный'
  else 'Первичный' end   [Вид займа]
 
 ,b.[Верификация кц] [Верификация кц]
 ,b.[Предварительное одобрение] [Предварительное одобрение]
 ,b.[Контроль данных] [Контроль данных]
 ,b.Одобрено Одобрено
 ,b.Отказано Отказано
 , case 
 when  b.Аннулировано <b.[Заем аннулирован] then   b.Аннулировано  
 when  b.[Заем аннулирован] <b.Аннулировано then   b.[Заем аннулирован]  
 else isnull(  b.[Заем аннулирован] , b.Аннулировано) end 
 
 
 Аннулировано
 , b.[Процентная ставка]
 , b.[Срок займа]
 , b.[Заем погашен]
 , b.Дубль Дубль_8_дней
 , [Лояльность]        = isnull(povt_tel.cnt_povt,0)+1
 , [Тип первого займа] = case first_loan.ispdl when 1 then 'pdl' when 0 then 'inst' end
 , isnull( b.loan_type3 ,
  case 
  when  [docr_tel_any_product].cnt_dcr>0  then 'Докредитование'
  when  [povt_tel_any_product].cnt_povt>0 then 'Повторный'
  else 'Первичный' end   )  [Вид займа любой продукт] 
 
 
 
 

  into #inst_an 	 --select top 100 *
  
  from #requests_lk a

  outer apply (select count(*) cnt_povt from #loans b where a.ispts=b.isPts and (a.client_mobile_phone=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.created_at  	 )  [povt_tel]
  outer apply (select count(*) cnt_dcr from #loans  b where a.ispts=b.isPts and ( a.client_mobile_phone=b.Телефон) and b.[Заем выдан]<=a.created_at and isnull(b.[Заем погашен], GETDATE() ) > a.created_at  )    [docr_tel]	 
  
  outer apply (select count(*) cnt_povt from #loans b where ( a.client_mobile_phone=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.created_at  	 )  [povt_tel_any_product]
  outer apply (select count(*) cnt_dcr from #loans  b where  (a.client_mobile_phone=b.Телефон) and b.[Заем выдан]<=a.created_at and isnull(b.[Заем погашен], GETDATE() ) > a.created_at  )    [docr_tel_any_product]	 

  outer apply (select top 1 ispdl   from #loans  b where a.ispts=b.isPts 
  and ( a.client_mobile_phone=b.Телефон) and b.[Заем выдан]<=a.created_at and isnull(b.[Заем погашен], GETDATE() ) <= a.created_at order by b.[Заем выдан]  )    first_loan	
  outer apply (select top 1 product_type   from #loans  b where a.ispts=b.isPts 
  and ( a.client_mobile_phone=b.Телефон) and b.[Заем выдан]<=a.created_at and isnull(b.[Заем погашен], GETDATE() ) <= a.created_at order by b.[Заем выдан]  )    first_loan_any_product	 
  left join --select top 100 * from
  v_fa b on b.number=a.number


  


  drop table if exists #oper

select Сотрудник Оператор
into #oper
from analytics.dbo.employees 
--where Направление = 'Installment' 



drop table if exists #odobr 

select n.НомерЗаявки 

into #odobr 
from
v_communication_crm n
join  Reports.dbo.dm_Factor_Analysis_001 fa on n.НомерЗаявки=fa.Номер and Одобрено is not null --and isInstallment=1
join #oper o on n.ФИО_оператора  =  o.Оператор
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and [ДатаВремяВзаимодействия] between @datefrom and @dateto
and [ДатаВремяВзаимодействия] >=Одобрено and [ДатаВремяВзаимодействия]<=isnull([Заем выдан], dateadd(day, 10, Одобрено))
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]
		  group by n.НомерЗаявки 




 drop table if exists #next_loans
 drop table if exists #costs
 select Номер  , [Маркетинговые расходы] into #costs  from  [v_Отчет стоимость займа опер]


 select Номер, next_product, [Кол-во закрытых займов в рамках продукта] into #next_loans from return_types
-- where --next_product is not null
 --and 
-- isinstallment=1
 drop table if exists #next_loans2

select nl.*  , c_next. [Выданная сумма] , [Маркетинговые расходы]

	into #next_loans2

from #next_loans nl 
left join #inst_an     c_next on nl.next_product = c_next.number
left join (select Номер НомерСтЗ2, [Маркетинговые расходы] from  #costs ) e_next on c_next.number=e_next.НомерСтЗ2
				   

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
,      c.Аннулировано
,      c.Дубль_8_дней  [Дубль_8_дней факторный анализ]
,      a.number     number                         
,      a.is_installment                     
,      a.ispts                     
,      a.prolongations_cnt                     
,      a.first_prolongation_dt                     
,      a.[product_type]                     
,      a.[product_type_initial]                     
,      a.client_total_monthly_income                     
,      a.is_automatic_approve                     
,      a.[Верификация документов клиента]                     
,      a.СтатусЗаявки                             
,      a.closed_date_plan                             
,      a.term_days                             
,      a.free_term_days                             
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
,   isnull( cast(  b.[current_status] as float), 	case when c.[Выдача денег] is not null then 999.0 when c.[Верификация кц] is not null then 0.7  when a.number is not null then 0.5 else 0.0 end)  	[current_status]
,     b.[lkk_or_mp]
,     b.[is_repeated_lk]
,     b.is_fake	  has_fake_status
,     b.request_id_status

, b.[Переход на калькулятор ПТС]
, b.[Переход на Анкету ПТС]
, b.[Открытие слота 2-3 стр паспорта ПТС]
, b.[Загрузка 2-3 стр паспорта ПТС]
, b.[Переход на 1 пакет ПТС]
, b.[Подписание 1 пакета ПТС]
--, b.[Подписание 1 пакета ПТС]
, b.[Переход на экран Фото паспорта ПТС]
, b.[Переход на экран с дополнительной информацией ПТС]
, b.[Переход на экран с фото документов авто ПТС]
, b.[Переход на экран Способ выдачи ПТС]
, b.[Карта привязана ПТС]
, b.[Переход на фото авто ПТС]
, b.[Отправлена полная заявка ПТС]
, b.[Финальное одобрение ПТС]
, b.[Переход на второй пакет ПТС]
, b.[Подписание второго пакета ПТС]

,     c.[Вид займа]   
,  	  case when c.Одобрено is not null then case when d.НомерЗаявки is not null then 1 else 0 end end	 [Признак ручное доведение на TU]
,     e.[Маркетинговые расходы]
,     nl.next_product [Повторный займ] 
,     nl.[Кол-во закрытых займов в рамках продукта] [Кол-во закрытых займов в рамках продукта] 
, 	  nl.[Выданная сумма]  [Повторный займ сумма]
, 	  nl.[Маркетинговые расходы]  [Повторный займ Маркетинговые расходы]
 , c.[Лояльность]       
  , c. [Тип первого займа]
  , c.[Вид займа любой продукт]
into #T5
from      #requests_lk a
left join #t4          b on a.id = b.request_id_status
left join #inst_an     c on a.id = c.id
left join #odobr d on d.НомерЗаявки=a.number
left join (select Номер НомерСтЗ, [Маркетинговые расходы] from  #costs ) e on a.number=e.НомерСтЗ

left join #next_loans2 nl on nl.Номер=a.number
 


drop table if exists  #doubles
													  
select a.id, case when a.[Выдача денег] is not null then 0 when max( b.id) is not null then 1 else 0 end [Дубль]
into #doubles
from #T5 a
 left join #T5 b
on cast(a.created_at as date)= cast(b.created_at as date)
 and a.client_mobile_phone=b.client_mobile_phone
 and ( b.[current_status]>a.current_status or ( b.[current_status]=a.current_status  and b.created_at>a.created_at) )
 group by  a.id	 , a.[Выдача денег] 
	--order by 
--order by 

drop table if exists #uprid

select a.id 
--, max(a.ДатаЗаявки				 ) ДатаЗаявки
--, max(a.ТипКредитногоПродукта	 ) ТипПРодукта
, min(case when cast(code as bigint) = 2402 then dateadd(hour, 3, b.CreatedOn) end ) Запрос
, min(case when cast(code as bigint) = 2403 then dateadd(hour, 3, b.CreatedOn) end ) Есть
, min(case when cast(code as bigint) = 2701 then dateadd(hour, 3, b.CreatedOn) end ) Есть_ГИБДД
, min(case when cast(code as bigint) = 2703 then dateadd(hour, 3, b.CreatedOn) end ) Есть_ФНС
, min(case when cast(code as bigint) in ( 2703 , 2701)  then dateadd(hour, 3, b.CreatedOn) end ) Есть_ФНС_ГИБДД
, min(case when cast(code as bigint) = 2404 then dateadd(hour, 3, b.CreatedOn) end ) Нет
 
 into #uprid

from  #requests_lk a
left join Stg._fedor.core_ClientRequestExternalEventHistory b on a.feodor_request_id=b.ClientRequestId 
left join Stg._fedor.dictionary_ClientRequestExternalEvent c on c.Id=b.ClientRequestExternalEventId
  where a.ispts=0
group by a.id
--having  max(a.ТипКредитногоПродукта	 ) <>'PTS'
--order by 2 desc
--order by 1 desc


drop table if exists #next_request

select a.id,  x.number next_request_product , x.[Верификация кц] next_request_product_dt
, x1.number next_request_other_product_after_annul
, x1.[Верификация кц] next_request_other_product_after_annul_dt
into #next_request from #T5 a
outer apply (select top 1 number, [Верификация кц] from   #T5 b where a.client_mobile_phone=b.client_mobile_phone and a.ispts=b.ispts and b.[Верификация кц]>a.[Заем погашен] order by b.[Верификация кц] )  x
outer apply (select top 1 number, [Верификация кц] from   #T5 b where a.client_mobile_phone=b.client_mobile_phone and a.ispts<>b.ispts and b.[Верификация кц]>a.Аннулировано order by b.[Верификация кц] )  x1




drop table if exists #t6

	   select   
	   a.[id] 
,      a.created_at_date 
,      a.lcrm_id 
,      a.[created_at] 
,      a.[Вид займа] 
,      a.[Вид займа любой продукт]
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
,      a.ispts 
,      a.prolongations_cnt 
,      a.first_prolongation_dt 
,      a.[product_type] 
,      a.[product_type_initial] 
,      a.client_total_monthly_income 
,      a.is_automatic_approve 
,      a.[Верификация документов клиента] 
,      a.СтатусЗаявки 
,      a.closed_date_plan                             
,      a.term_days                     
,      a.free_term_days                     
,      a.number 
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
, a.[Переход на калькулятор ПТС]
,      datediff(second, [Переход на калькулятор ПТС] , [Переход на Анкету ПТС] )/86400.0  [Переход на калькулятор ПТС - Переход на Анкету ПТС]	   
, a.[Переход на Анкету ПТС]	
, datediff(second, a.[Переход на Анкету ПТС], a.[Открытие слота 2-3 стр паспорта ПТС])/86400.0 [Переход на Анкету ПТС - Открытие слота 2-3 стр паспорта ПТС]
, a.[Открытие слота 2-3 стр паспорта ПТС]	
, datediff(second, a.[Открытие слота 2-3 стр паспорта ПТС], a.[Загрузка 2-3 стр паспорта ПТС])/86400.0 [Открытие слота 2-3 стр паспорта ПТС - Загрузка 2-3 стр паспорта ПТС]
, a.[Загрузка 2-3 стр паспорта ПТС]	
, datediff(second, a.[Загрузка 2-3 стр паспорта ПТС], a.[Переход на 1 пакет ПТС])/86400.0 [Загрузка 2-3 стр паспорта ПТС - Переход на 1 пакет ПТС]
, a.[Переход на 1 пакет ПТС]	
, datediff(second, a.[Переход на 1 пакет ПТС], a.[Подписание 1 пакета ПТС])/86400.0 [Переход на 1 пакет ПТС - Подписание 1 пакета ПТС]
, a.[Подписание 1 пакета ПТС]	
, datediff(second, a.[Подписание 1 пакета ПТС], a.[Переход на экран Фото паспорта ПТС])/86400.0 [Подписание 1 пакета ПТС - Переход на экран Фото паспорта ПТС]
, a.[Переход на экран Фото паспорта ПТС]	
, datediff(second, a.[Переход на экран Фото паспорта ПТС], a.[Переход на экран с дополнительной информацией ПТС])/86400.0 [Переход на экран Фото паспорта ПТС - Переход на экран с дополнительной информацией ПТС]
, a.[Переход на экран с дополнительной информацией ПТС]	
, datediff(second, a.[Переход на экран с дополнительной информацией ПТС], a.[Переход на экран с фото документов авто ПТС])/86400.0 [Переход на экран с дополнительной информацией ПТС - Переход на экран с фото документов авто ПТС]
, a.[Переход на экран с фото документов авто ПТС]	
, datediff(second, a.[Переход на экран с фото документов авто ПТС], a.[Переход на экран Способ выдачи ПТС])/86400.0 [Переход на экран с фото документов авто ПТС - Переход на экран Способ выдачи ПТС]
, a.[Переход на экран Способ выдачи ПТС]	
, datediff(second, a.[Переход на экран Способ выдачи ПТС], a.[Карта привязана ПТС])/86400.0 [Переход на экран Способ выдачи ПТС - Карта привязана ПТС]
, a.[Карта привязана ПТС]	
, datediff(second, a.[Карта привязана ПТС], a.[Переход на фото авто ПТС])/86400.0 [Карта привязана ПТС - Переход на фото авто ПТС]
, a.[Переход на фото авто ПТС]	
, datediff(second, a.[Переход на фото авто ПТС], a.[Отправлена полная заявка ПТС])/86400.0 [Переход на фото авто ПТС - Отправлена полная заявка ПТС]
, a.[Отправлена полная заявка ПТС]	
, datediff(second, a.[Отправлена полная заявка ПТС], a.[Финальное одобрение ПТС])/86400.0 [Отправлена полная заявка ПТС - Финальное одобрение ПТС]
, a.[Финальное одобрение ПТС]	
, datediff(second, a.[Финальное одобрение ПТС], a.[Переход на второй пакет ПТС])/86400.0 [Финальное одобрение ПТС - Переход на второй пакет ПТС]
, a.[Переход на второй пакет ПТС]	
, datediff(second, a.[Переход на второй пакет ПТС], a.[Подписание второго пакета ПТС])/86400.0 [Переход на второй пакет ПТС - Подписание второго пакета ПТС]
, a.[Подписание второго пакета ПТС]	
, datediff(second, a.[Подписание второго пакета ПТС], a.[Выдача денег])/86400.0 [Подписание второго пакета ПТС - Выдача денег]




,      b.Дубль
,      a.[Дубль_8_дней факторный анализ]
,      case when [Предварительное одобрение] is not null then 1 end  [Признак Предварительное одобрение]
,      case  when [Верификация КЦ] is null  then 1
	   	  else 0 end [Признак застрял]
,      getdate() created
,     [Признак ручное доведение на TU]
,     [Маркетинговые расходы]
,     [Повторный займ] 
, 	  [Повторный займ сумма]
, 	  [Повторный займ Маркетинговые расходы]

, uprid.Запрос УПРИД_запрос
,  uprid.Есть    УПРИД_Есть
,  case when  uprid.Есть_ФНС>=  uprid.Есть_ГИБДД then  uprid.Есть_ФНС else   uprid.Есть_ГИБДД end    УПРИД_ГИБДД_ФНС_Есть
,  uprid.Есть_ФНС    УПРИД_ФНС_Есть
,  uprid.Есть_ГИБДД    УПРИД_ГИБДД_Есть
--,    uprid.Есть  УПРИД_Есть2
, uprid.Нет  УПРИД_Нет

, next_request_product_dt 
, case when next_request_product_dt <=dateadd(day, 90, a.[Заем погашен]) then 1 else 0 end [Заявка 90 дней после закрытия]
, next_request_other_product_after_annul  
, next_request_other_product_after_annul_dt  
, CASE
        WHEN ispts = 1 THEN
            CASE
                WHEN [Выдача денег] IS NOT NULL THEN 'Выдача денег'
                WHEN [Подписание второго пакета ПТС] IS NOT NULL THEN 'Подписание второго пакета ПТС'
                WHEN [Переход на второй пакет ПТС] IS NOT NULL THEN 'Переход на второй пакет ПТС'
                WHEN [Финальное одобрение ПТС] IS NOT NULL THEN 'Финальное одобрение ПТС'
                WHEN [Отправлена полная заявка ПТС] IS NOT NULL THEN 'Отправлена полная заявка ПТС'
                WHEN [Переход на фото авто ПТС] IS NOT NULL THEN 'Переход на фото авто ПТС'
                WHEN [Карта привязана ПТС] IS NOT NULL THEN 'Карта привязана ПТС'
                WHEN [Переход на экран Способ выдачи ПТС] IS NOT NULL THEN 'Переход на экран Способ выдачи ПТС'
                WHEN [Переход на экран с фото документов авто ПТС] IS NOT NULL THEN 'Переход на экран с фото документов авто ПТС'
                WHEN [Переход на экран с дополнительной информацией ПТС] IS NOT NULL THEN 'Переход на экран с дополнительной информацией ПТС'
                WHEN [Переход на экран Фото паспорта ПТС] IS NOT NULL THEN 'Переход на экран Фото паспорта ПТС'
                WHEN [Подписание 1 пакета ПТС] IS NOT NULL THEN 'Подписание 1 пакета ПТС'
                WHEN [Переход на 1 пакет ПТС] IS NOT NULL THEN 'Переход на 1 пакет ПТС'
                WHEN [Загрузка 2-3 стр паспорта ПТС] IS NOT NULL THEN 'Загрузка 2-3 стр паспорта ПТС'
                WHEN [Открытие слота 2-3 стр паспорта ПТС] IS NOT NULL THEN 'Открытие слота 2-3 стр паспорта ПТС'
                WHEN [Переход на Анкету ПТС] IS NOT NULL THEN 'Переход на Анкету ПТС'
                WHEN [Переход на калькулятор ПТС] IS NOT NULL THEN 'Переход на калькулятор ПТС'
                ELSE NULL
            END
        ELSE
            CASE
                WHEN [Выдача денег] IS NOT NULL THEN 'Выдача денег'
                WHEN [Подписание договора] IS NOT NULL THEN 'Подписание договора'
                WHEN [Выбор предложения] IS NOT NULL THEN 'Выбор предложения'
                WHEN [Одобрение] IS NOT NULL THEN 'Одобрение'
                WHEN [Добавление карты] IS NOT NULL THEN 'Добавление карты'
                WHEN [О работе и доходе] IS NOT NULL THEN 'О работе и доходе'
                WHEN [Call 1] IS NOT NULL THEN 'Call 1'
                WHEN [Подписание первого пакета] IS NOT NULL THEN 'Подписание первого пакета'
                WHEN [Фотографии] IS NOT NULL THEN 'Фотографии'
                WHEN [Паспорт] IS NOT NULL THEN 'Паспорт'
                WHEN [Анкета] IS NOT NULL THEN 'Анкета'
                ELSE NULL
            END
    END AS final_step   
	 , [Лояльность]       
 , [Тип первого займа]


      into #t6
      from #T5	a
	  left join #doubles b on a.id=b.id
	  left join #uprid uprid on uprid.id=a.id
	  left join #next_request next_request on next_request.id=a.id
 	
	
--	; with v as (
--select id , УПРИД_запрос,    УПРИД_Есть ,  УПРИД_ГИБДД_ФНС_Есть ,  УПРИД_ГИБДД_Есть ,    УПРИД_ФНС_Есть ,  УПРИД_Нет, Фотографии
--, datediff(second, УПРИД_запрос ,   УПРИД_Есть  ) 	  dif_request_respond
--, datediff(second, Фотографии , УПРИД_ГИБДД_Есть )   dif_photo_status_ГИБДД
--, datediff(second, Фотографии , УПРИД_ФНС_Есть )   dif_photo_status_ФНСС
--, datediff(second, Фотографии , УПРИД_ГИБДД_ФНС_Есть )   dif_photo_status_ГИБДД_ФНСС
--, 1 as row
--, case when [Подписание первого пакета] is not null then 1 end conv
--
--from #t6
--where Фотографии >=getdate()-30 and [Вид займа]='Первичный'	and Дубль=0	 and ispts=0 and Фотографии is not null
--)
--	  SELECT 
--        type,
--        MAX(CASE WHEN rn = ROUND(total_count * 0.25, 0) THEN value END) AS Percentile_25,
--        MAX(CASE WHEN rn = ROUND(total_count * 0.50, 0) THEN value END) AS Percentile_50,
--        MAX(CASE WHEN rn = ROUND(total_count * 0.75, 0) THEN value END) AS Percentile_75,
--        MAX(CASE WHEN rn = ROUND(total_count * 0.95, 0) THEN value END) AS Percentile_95,
--        MAX(CASE WHEN rn = ROUND(total_count * 0.98, 0) THEN value END) AS Percentile_98,
--        MAX(CASE WHEN rn = ROUND(total_count * 0.99, 0) THEN value END) AS Percentile_99,
--        MAX(value) AS Percentile_100		,
--		count(case when value<=30 then 1 end )/(0.0+ 
--		count(  1   )	 ) perc_30
--    FROM     (
--	select * ,
--	
--        ROW_NUMBER() OVER (PARTITION BY type ORDER BY value) AS rn,
--        COUNT(*) OVER (PARTITION BY type) AS total_count
--	from (
--select id,row,conv, dif_photo_status_ГИБДД_ФНСС value, '3) ГИБДД/ФНСС (более позднее)'  type from v  union all
--select id,row,conv, dif_photo_status_ФНСС, '2) ФНСС есть'  type from v  union all
--select id,row,conv, dif_photo_status_ГИБДД, '1) ГИБДД есть'  type from v  union all
--select id,row,conv, dif_request_respond, '4) Событие Уприд есть'  type from v  
--) x		where value is not null
--) x
-- 
--GROUP BY type;
	
--?>
 	
--	drop table if exists _birs.[Installment тайминг таблица]
--	select * into _birs.[Installment тайминг таблица] from #t6

		--select * from #t6
	--	select * from _birs.[Installment тайминг таблица]

 
	
	if @recreate = 1
	begin
	drop table if exists _birs.[product_report_request]
	select * into _birs.[product_report_request] from #t6

	return
	exec [droptmp]




	 exec [_birs].[product_report] 'update' , @recreate

	return

	end																			   
 --alter table  _birs.[product_report_request]	  add   [Лояльность]       	 int
   
 
 --alter table  _birs.[product_report_request]	  add [Тип первого займа] nvarchar(100)
 --alter table  _birs.[product_report_request]	  add final_step nvarchar(100)
 --alter table  _birs.[product_report_request]	  drop  column [Переход на второй пакет ПТС - Выдача денег]  
 --alter table  _birs.[product_report_request]	  add [Подписание второго пакета ПТС - Выдача денег] bigint
 --alter table  _birs.[product_report_request]	   drop  column  [Подписание второго пакета ПТС - Выдача денег]  
 --alter table  _birs.[product_report_conversions]	   add [Подписание второго пакета ПТС - Выдача денег] bigint
 --alter table  _birs.[product_report_all_actions]	   add  is_automatic_approve int
 --alter table  _birs.[product_report_all_actions]	   add  [Верификация документов клиента] datetime2(0)
 --drop table if exists _birs.[Installment тайминг таблица]
 --select * into _birs.[Installment тайминг таблица] from #t6
--
delete from _birs.[product_report_request]
insert into _birs.[product_report_request]
select * from #t6
--select * from _birs.[Installment тайминг таблица]
--select [Признак застрял], count([Верификация КЦ]) cnt from _birs.[Installment тайминг таблица]
--group by [Признак застрял]
----order by 
--
 
--
return
end


if @mode = 'select'
begin
		    

SELECT a.*
FROM _birs.[product_report_request] a															    

end

if @mode = 'details'
begin
--exec _birs.[Installment тайминг] 'update'
		 
SELECT a.*
FROM _birs.[product_report_request] a

end



end
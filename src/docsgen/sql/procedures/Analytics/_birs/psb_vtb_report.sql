/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/

CREATE   proc [_birs].[psb_vtb_report]

@mode nvarchar(max) = 'select' 
as 
begin



 if @mode = 'select'
 begin


 drop table if exists #lead2
 select a.* into #lead2 from v_lead2 a
 join 	   [Analytics].[dbo].[lead_psb_vtb]    b on a.id=b.id	 


 drop table if exists #t3


 ;
 with v1 as (

   select *
, case when Отказано is not null then '' else  isnull( nullif(replace(replace(a.[Причина отказа] , 'CC.Не подходит под требования  - ', '')  , 'CC.Отказ со стороны клиента - ' , ''), ''), 'Не указано') end   [Причина отказа2]
   
   from v_FA	a

 )
 , v as (

SELECT            Дата= isnull(isnull(isnull(a.[created], c.ДатаЗаявки)  , cl.load_date) , v.created)                         
,                 телефон= isnull(a.[phone], c.телефон)                                 
,                 [source]=  isnull(isnull( isnull(a.[source], c.источник)       , case when   cl.source is not null then  cl.source end)     , v.source)                      
,                 [id]= isnull(isnull(a.[id], c.НомерЗаявки)  , v.id+ '(visit_id)')
,                 [client_id]=    v.[client_id] 
,                 Продукт         =  isnull(	case when c.isPts=1 then 'ПТС' when c.isPts=0 then 'Беззалог'  when b.IsInstallment=0 then 'ПТС' when b.IsInstallment=1 then  'Беззалог' end                        , 'ПТС' ) 
, 				  sms = try_cast( cl.cnt_clients as bigint) 
,				  визит = case when  v.[client_id] 	 is not null then 1 end
,                 лид = case when a.id is not null then 1 end 
,                 [Дозвон без автоответчиков] = case when b.ВремяПервогоДозвона is not null  and b.[Результат коммуникации]<>'Автоответчик' then 1 end                  
,                 ФлагПрофильныйИтог          = b.ФлагПрофильныйИтог                                        
,                 СтатусЛидаФедор             = b.СтатусЛидаФедор                                           
,                 ПричинаНепрофильности       = b.ПричинаНепрофильности                                     
,                 [Результат коммуникации]    = b.[Результат коммуникации]                                  
,                 status                      = b.status                                                    
,                 CompanyNaumen               = b.CompanyNaumen                                             
,                 uuid                        = b.uuid                                                      
,                 ВремяПервойПопытки          = b.ВремяПервойПопытки                                        
,                 ВремяПервогоДозвона         = b.ВремяПервогоДозвона                                       
,                 ДатаЗаявки                  = c.ДатаЗаявки                                                         
,                 НомерЗаявки                 = c.НомерЗаявки                                                         
,                 isPts                       = d.isPts                                                     

,                 ПризнакЗаявка = d.ПризнакЗаявка                                             
,                 Дубль           = d.Дубль                                                     
,                 [Причина отказа] = [Причина отказа2]                       
,                 [Признак предварительного одобрения] = case when [Предварительное одобрение] is not null then 1  end 
,                 [Признак КД] = case when [Контроль данных] is not null then 1	  end           
,                 [Признак КД застрял] = case when [Контроль данных] is not null and d.Отказано is null  and d.Одобрено  is null  then 1	  end           
,                 [ПО застрял причина] = case when [Предварительное одобрение] is not null and d.[Контроль данных] is null   then isnull([Причина отказа2], '')	  end   
,                 [КД застрял причина]= case when [Контроль данных] is not null and d.Отказано is null  and d.Одобрено  is null  then isnull([Причина отказа2], '')	  end      
,                 [Одобрено застрял причина]= case when  d.[Одобрено] is  not null and d.[Заем выдан] is null   then isnull([Причина отказа2], '')	  end                          
,                 [Признак одобрено]= case when d.[Одобрено] is not null then 1		  end                                                          
,                 [Признак выдано]= case when d.[Заем выдан] is not null then 1   end                                                            
,                 [Выданная сумма]=  d.[Выданная сумма]                                            	                                           
,                 [Признак отказано]= case when [Отказано] is not null then 1			  end     
, [Где застрял] = case
when d.[Заем выдан] is not null   then null
when d.[Заем выдан] is null and d.Одобрено is not null then 'Невыданные'   
when d.[Контроль данных] is not null and d.Одобрено is null and d.Отказано is null then 'Застрявшие'    
when d.[Контроль данных] is   null and d.[Предварительное одобрение] is not null then 'Недоезды'   end
, d.[Срок займа]
, d.[Первичная сумма]
, d.[Сумма одобренная]
, case 
when d.Call2 is not null and  d.[Call2 accept] is null then 'Отказ Call2'
when d.Отказано>=d.[Контроль данных] then 'Отказ после КД'
when d.Отказано  is not null and  d.[Верификация КЦ] is not null and d.[Контроль данных]  is null then 'Отказ Call1'
when d.Отказано  is not null   then 'Отказ'	  end [На каком шаге отказ]

, d.[Заем выдан]


FROM            [Analytics].[dbo].[lead_psb_vtb]    a
 join      #lead2                           b on a.id=b.id
full outer join [Analytics].[dbo].[request_psb_vtb] c on 1=0
left join       v1                                d on d.Номер=c.НомерЗаявки
full outer join (

select CONVERT(DATE, load_date, 104)  load_date , cnt_clients, 'psb-ref' source from  _gsheets.[dic_клики_ПСБ] cl where CONVERT(DATE, load_date, 104) is not null union all
select CONVERT(DATE, load_date, 104)  load_date , cnt_clients, 'vtb-ref' source from  _gsheets.[dic_СМС_ВТБ] cl where CONVERT(DATE, load_date, 104) is not null 



)  cl on 1=0

full outer join [Analytics].[dbo].[visit_psb_vtb] v on 1=0

		 
)		 

select 
b.Месяц  Месяц,
b.Неделя as Неделя  
,   a.[Дата] 
,   a.[телефон] 
,   a.[source] 
,   a.[id] 
,   a.[Продукт] 

,   a.sms 
,   a.визит 
,   a.client_id 
,   a.лид 
,   a.[Дозвон без автоответчиков] 
,   a.[ФлагПрофильныйИтог] 
,   a.[СтатусЛидаФедор] 
,   a.[ПричинаНепрофильности] 
,   a.[Результат коммуникации] 
,   a.[status] 
,   a.[CompanyNaumen] 
,   a.[uuid] 
,   a.[ВремяПервойПопытки] 
,   a.[ВремяПервогоДозвона] 
,   a.[ДатаЗаявки] 
,   a.[Заем выдан] 
,   a.[НомерЗаявки] 
,   a.[isPts] 
,   a.[ПризнакЗаявка] 
,   a.[Дубль] 
,   replace(replace(a.[Причина отказа] , 'CC.Не подходит под требования  - ', '')  , 'CC.Отказ со стороны клиента - ' , '')  [Причина отказа]
,   a.[Признак предварительного одобрения] 
,   a.[Признак КД] 
,   a.[Признак КД застрял] 
,   a.[ПО застрял причина] 
,   a.[КД застрял причина] 
,   a.[Одобрено застрял причина] 
,   a.[Признак одобрено] 
,   a.[Признак выдано] 
,   a.[Выданная сумма] 
,   a.[Признак отказано]   
,   a.[Где застрял] 
,   a.[Срок займа]
,   a.[Первичная сумма]
,   a.[Сумма одобренная]
,   a.[На каком шаге отказ]

into #t3
from v	 a
left join v_Calendar b on cast(a.Дата as date)=b.Дата
--order by 3	 ,        1
	    
			    

				select 
				
    a.[Дата] 
,   a.[source] 
,   a.[телефон] 
,   a.[id] 
,   a.[Где застрял]   
,   a.[Срок займа]
,   a.[Первичная сумма]
,   a.[Сумма одобренная]
,   a.[Выданная сумма] 
,   a.[На каком шаге отказ]
,   a.[ДатаЗаявки] 
,   a.[Заем выдан] 
,   a.[НомерЗаявки] 
,   a.[ПризнакЗаявка] 
,   a.[Дубль] 
,   replace(replace(a.[Причина отказа] , 'CC.Не подходит под требования  - ', '')  , 'CC.Отказ со стороны клиента - ' , '')  [Причина отказа]
,   a.[Признак предварительного одобрения] 
,   a.[Признак КД] 
,   a.[Признак КД застрял] 
,   a.[ПО застрял причина] 
,   a.[КД застрял причина] 
,   a.[Одобрено застрял причина] 
,   a.[Признак одобрено] 
,   a.[Признак выдано] 
,   a.[Признак отказано]   

,   a.Продукт 
,   a.[isPts] 
,   a.sms 
,   a.визит 
,   a.client_id 
,   case when dubl_visit.id is null    and визит=1 then 1 end  [Визит уникальный] 
,    dubl_visit.Дата   ДатаСледующегоВизита
,   a.лид 
,   case when ROW_NUMBER() over(partition by [телефон] , лид, source order by a.[Дата] ) = 1 and лид=1 then 1 end  [Лид уникальный] 

,   a.[Дозвон без автоответчиков] 
,   a.[ФлагПрофильныйИтог] 
,   a.[СтатусЛидаФедор] 
,   a.[ПричинаНепрофильности] 
,   a.[Результат коммуникации] 
,   a.[status] 
,   a.[CompanyNaumen] 
,   a.[uuid] 
,   a.[ВремяПервойПопытки] 
,   a.[ВремяПервогоДозвона] 


,   a. Неделя 
,   a. Месяц 


from  #t3	  a
outer apply (select top 1 b.Дата, b.id id  from 	  #t3	  b	  where a.client_id=b.client_id and  b.Дата	 between a.Дата		 and  dateadd(day, 30, b.Дата ) and b.Дата<>a.Дата and a.source=b.source  order by b.Дата ) dubl_visit
 --where source = 'vtb-ref'
 --order by 1

end





end
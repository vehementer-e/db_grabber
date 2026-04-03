
create proc dbo.[Подготовка отчета воронка продаж по часам birs]
as
begin

drop table if exists #t1
;with v as (

select 'По дате заявки'                 as type
,      cast( [верификация кц] as date)  as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      Место_создания_2                
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]                    
,      [Выданная сумма]                
,      Отказано                        
,      Телефон 
,      isInstallment                       
,      case when case when [заем выдан] is not null then 1 else ROW_NUMBER() over(partition by Телефон,       cast( [верификация кц] as date) order by              [заем выдан] desc,    Одобрено desc,   [Верификация документов] desc, [Верификация документов клиента] desc, [Контроль данных] desc, [Предварительное одобрение] desc, [верификация кц] desc) end =1 then 'Уникальная в рамках дня' else 'Дубль' end [Признак Уникальности]
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]

,[Сумма одобренная]

from reports.dbo.dm_Factor_Analysis-- with(nolock)
where [верификация кц]>=cast(getdate()-14 as date)
union all
select 'По дате КД'                     as type
,      cast( [Контроль данных] as date) as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      Место_создания_2                
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]                    
,      [Выданная сумма]                
,      Отказано                
,      Телефон     
,      isInstallment                 
,      case when case when [заем выдан] is not null then 1 else ROW_NUMBER() over(partition by Телефон,       cast( [Контроль данных] as date) order by              [заем выдан] desc,    Одобрено desc,   [Верификация документов] desc, [Верификация документов клиента] desc, [Контроль данных] desc) end =1 then 'Уникальная в рамках дня' else 'Дубль' end 
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]

,[Сумма одобренная]

from reports.dbo.dm_Factor_Analysis-- with(nolock)
where [Контроль данных]>=cast(getdate()-14 as date)
union all
select 'По дате Займа'                     as type
,      cast( [Заем выдан] as date) as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      Место_создания_2                
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]                    
,      [Выданная сумма]                
,      Отказано                
,      Телефон 
,      isInstallment                     
,      'Уникальная в рамках дня' 
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]

,[Сумма одобренная]

from reports.dbo.dm_Factor_Analysis --with(nolock)
where [Заем выдан]>=cast(getdate()-14 as date)
union all
select 'По дате Одобрения'                     as type
,      cast( Одобрено as date) as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      Место_создания_2                
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]                    
,      [Выданная сумма]                
,      Отказано                
,      Телефон 
,      isInstallment                     
,      case when case when [заем выдан] is not null then 1 else ROW_NUMBER() over(partition by Телефон,       cast( Одобрено as date) order by              [заем выдан] desc,    Одобрено desc) end =1 then 'Уникальная в рамках дня' else 'Дубль' end 
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]
,[Сумма одобренная]

from reports.dbo.dm_Factor_Analysis --with(nolock)
where Одобрено>=cast(getdate()-14 as date)
)

select * into #t1 from v

select type_2 = 'Канал' , Разбивка = Канал ,* from #t1 union all
select type_2 = 'Продукт' , Разбивка = product ,* from #t1 union all
select type_2 = 'Место cоздания' , Разбивка = [Место cоздания] ,* from #t1 union all
select type_2 = 'Вид займа' , Разбивка = [Вид займа] ,* from #t1 
end
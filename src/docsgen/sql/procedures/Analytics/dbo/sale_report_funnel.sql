
CREATE proc [dbo].[sale_report_funnel]
@mode nvarchar(max) = 'update'
as
 
  
  if @mode ='details'
  begin


 select код, max(Сумма)  Сумма into #Сумма from reports.dbo.dm_sales group by код

drop table if exists #t1
;with cte_fa

as
(

select       a.[Дата] 
,   a.[Время] 
,   a.[Номер] 
,   a.[Текущий статус] 
,   a.[Место cоздания] 
,   a.[Место создания 2] 
,   a.[Партнер] 
,   a.[Вид займа] 
,   a.[product] 
,   a.[RBP] 
,   a.[isInstallment] 
,   a.[isSmartInstallment] 
,   a.[isPdl] 
,   a.[isPts] 
,   a.[Продукт] 
,   a.[Первичная сумма] 
,   a.[Сумма одобренная] 
,   a.[Выданная сумма] 
,   a.[Сумма заявки] 
,   a.[Верификация КЦ] 
,   a.[Предварительное одобрение] 
,   a.[Встреча назначена] 
--,   a.[Контроль данных] 
, isnull( isnull(  a.[Контроль данных] , a.[Верификация документов клиента]), Одобрено)[Контроль данных]

, isnull(    a.[Верификация документов клиента] , a.[Одобрено] ) [Верификация документов клиента]
, isnull(    a.[Одобрены документы клиента] , a.[Одобрено] ) [Одобрены документы клиента]
--,   a.[Одобрены документы клиента] 
,   a.[Верификация документов] 
,   a.[Одобрено] 
,   a.[Договор зарегистрирован] 
,   a.[Договор подписан] 
,   a.[Заем выдан] 
,   a.[Заем погашен] 
,   a.[Заем аннулирован] 
,   a.[Аннулировано] 
,   a.[Отказ документов клиента] 
,   a.[Отказано] 
,   a.[Отказ клиента] 
,   a.[Забраковано] 
,   a.[Телефон] 
,   a.[ДатаЗаявкиПолная] 
,   a.[ФИО] 
,   a.[Канал от источника] 
,   a.[Группа каналов] 
,   a.[Дата отчета] 
, case when [заем выдан] is not null then b.Сумма else a.[Выданная сумма] end  [Выданная сумма2]
,case
when ТипПродукта ='Big Installment Рыночный' then 'BIG INST MARKET'                      
when ТипПродукта ='Big Installment' then 'BIG INST'                      
when ТипПродукта ='Автокредит' then 'AUTOCREDIT'                      
when ТипПродукта ='PDL' then 'PDL'                      
when ТипПродукта ='ВсёПро100' then 'INST'                      
when ТипПродукта ='ПТС' then 'PTS'                      
when Продукт ='PDL' then 'PDL'                      
when isPts =1 then 'PTS'                      
when isPDL =1 then 'PDL'                      
when isInstallment =1 then 'INST'   end [Тип продукта2] 
, parentDesc
, a.источник
--select distinct [ТипПродукта]
from analytics._birs.[factor_analysis_light]  a
--from  reports.dbo.dm_Factor_Analysis_001  a
left join #Сумма b on a.Номер=b.код
where isnull(Партнер, '')<> 'Партнер №0200 Москва'		
and фио   not like 'Тестовая%'
and фио   not like 'Тест %'


)
,
v as (

select 'По дате заявки'                 as type
,      Номер
,      cast( [верификация кц] as date)  as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      [Место создания 2] Место_создания_2                
         
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]                    
,      [Выданная сумма2] [Выданная сумма]                
,      Отказано                        
--,      Телефон 
,     [Тип продукта2] [Тип продукта]                    
,      case when case when [заем выдан] is not null then 1 else ROW_NUMBER() over(partition by Телефон,       cast( [верификация кц] as date) order by              [заем выдан] desc,    Одобрено desc,   [Верификация документов] desc, [Верификация документов клиента] desc, [Контроль данных] desc, [Предварительное одобрение] desc, [верификация кц] desc) end =1 then 'Уникальная в рамках дня' else 'Дубль' end [Признак Уникальности]
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]

,[Сумма одобренная]
, parentDesc
, источник

from  cte_fa -- with(nolock)
where [верификация кц]>=cast(getdate()-14 as date)
union all
select 'По дате КД'                     as type
,      Номер
,      cast( [Контроль данных] as date) as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      [Место создания 2] Место_создания_2                
             
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]      
,      [Выданная сумма2] [Выданная сумма]                
             
,      Отказано                
--,      Телефон 
,     [Тип продукта2] [Тип продукта] 
,      case when case when [заем выдан] is not null then 1 else ROW_NUMBER() over(partition by Телефон,       cast( [Контроль данных] as date) order by              [заем выдан] desc,    Одобрено desc,   [Верификация документов] desc, [Верификация документов клиента] desc, [Контроль данных] desc) end =1 then 'Уникальная в рамках дня' else 'Дубль' end 
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]

,[Сумма одобренная]
, parentDesc
, источник

from  cte_fa -- with(nolock)
where [Контроль данных]>=cast(getdate()-14 as date)
union all
select 'По дате Займа'                     as type
,      Номер
,      cast( [Заем выдан] as date) as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      [Место создания 2] Место_создания_2                
             
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]         
,      [Выданная сумма2] [Выданная сумма]                
          
,      Отказано                
--,      Телефон 

,     [Тип продукта2] [Тип продукта] 
,      'Уникальная в рамках дня' 
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]

,[Сумма одобренная]
, parentDesc
, источник

from  cte_fa  --with(nolock)
where [Заем выдан]>=cast(getdate()-14 as date)
union all
select 'По дате Одобрения'                     as type
,      Номер
,      cast( Одобрено as date) as ОтчетнаяДата
,      [Место cоздания]                
,      [Вид займа]                
,      [Место создания 2] Место_создания_2                
            
,      [верификация кц]                
,      [Предварительное одобрение]     
,      [Контроль данных]               
,      [Верификация документов клиента]
,      [Верификация документов]        
,      Одобрено                        
,      [заем выдан]                    

,      [Выданная сумма2] [Выданная сумма]                
                         
,      Отказано                
--,      Телефон 	
,    [Тип продукта2] [Тип продукта]                     
,      case when case when [заем выдан] is not null then 1 else ROW_NUMBER() over(partition by Телефон,       cast( Одобрено as date) order by              [заем выдан] desc,    Одобрено desc) end =1 then 'Уникальная в рамках дня' else 'Дубль' end 
, [Первичная сумма]
, product
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end [Канал]
,[Сумма одобренная]
, parentDesc
, источник

from  cte_fa  --with(nolock)
where Одобрено>=cast(getdate()-14 as date) and ФИО not like '%Тестовая%'
)

select * into #t1 from v

select type_2 = 'Канал' , Разбивка = Канал ,* from #t1 union all
select type_2 = 'Продукт' , Разбивка = product ,* from #t1 union all
select type_2 = 'Место cоздания' , Разбивка = [Место cоздания] ,* from #t1 union all
select type_2 = 'Вид займа' , Разбивка = [Вид займа] ,* from #t1 

   end

   if @mode = 'hours'
   begin

   select *, (select case when max([Верификация кц])>  max([КОнтроль данных]) then datepart(hour, max([КОнтроль данных])) else datepart(hour, max([Верификация кц])) end from _birs.[factor_analysis_light] ) ch  from (
   --select *, (select case when max([Верификация кц])>  max([КОнтроль данных]) then datepart(hour, max([КОнтроль данных])) else datepart(hour, max([Верификация кц])) end from Reports.dbo.dm_Factor_Analysis_001) ch  from (
select 1 h union all
select 2  union all
select 3  union all
select 4  union all
select 5  union all
select 6  union all
select 7  union all
select 8  union all
select 9  union all
select 10 union all
select 11 union all
select 12 union all
select 13 union all
select 14 union all
select 15 union all
select 16 union all
select 17 union all
select 18 union all
select 19 union all
select 20 union all
select 21 union all
select 22 union all
select 23 union all
select 24 union all
select 25)
x

end

   if @mode = 'update'

   begin
	exec  _request_old_light_creation 1


	exec sp_birs_update '4BE7F034-B627-4577-ADE4-8EB0844CE7AD'

   end


   if @mode = 'dates'
   begin
   	   
select *, getdate() as created from (
select cast(getdate()-14 as date) d union all
select cast(getdate()-13 as date) d union all
select cast(getdate()-12 as date) d union all
select cast(getdate()-11 as date) d union all
select cast(getdate()-10 as date) d union all
select cast(getdate()-9 as date) d union all
select cast(getdate()-8 as date) union all
select cast(getdate()-7 as date) union all
select cast(getdate()-6 as date) union all
select cast(getdate()-5 as date) union all
select cast(getdate()-4 as date) union all
select cast(getdate()-3 as date) union all
select cast(getdate()-2 as date) union all
select cast(getdate()-1 as date) union all
select cast(getdate()-0 as date) --union all
) x
   end
 
  

--exec  [dbo].[reportRequestStatuses]

CREATE   procedure [dbo].[reportRequestStatuses]
as
set nocount on
if object_id('tempdb.dbo.#tt') is not null drop table #tt
 
CREATE TABLE #tt(
	[External_id] [nvarchar](28)  NULL,
	[Черновик из ЛК] [int] NULL,

	[Клиент прикрепляет фото в МП] [int] NULL,
	[Клиент зарегистрировался в МП] [int] NULL,
	[Просрочен] [int] NULL,
	[Платеж опаздывает] [int] NULL,
	[Проблемный] [int] NULL,
	[ТС продано] [int] NULL,
	[Черновик] [int] NULL,
	[Предварительная] [int] NULL,
	[Верификация КЦ] [int] NULL,
	[Предварительное одобрение] [int] NULL,
	[Контроль авторизации] [int] NULL,
	[Контроль ПЭП] [int] NULL,
	[Контроль заполнения ЛКК] [int] NULL,
	[Контроль фото ЛКК] [int] NULL,
	[Назначение встречи] [int] NULL,
	[Встреча назначена] [int] NULL,
	[Ожидание контроля данных] [int] NULL,
	[Контроль данных] [int] NULL,
	[Выполнение контроля данных] [int] NULL,
	[Верификация документов клиента] [int] NULL,
	[Контроль верификация документов клиента] [int] NULL,
	[Одобрены документы клиента] [int] NULL,
	[Контроль одобрения документов клиента] [int] NULL,
	[Верификация документов] [int] NULL,
	[Контроль верификации документов] [int] NULL,
	[Одобрено] [int] NULL,
	[Договор зарегистрирован] [int] NULL,
	[Контроль подписания договора] [int] NULL,
	[Проверка ПЭП и ПТС] [int] NULL,
	[Договор подписан] [int] NULL,
	[Контроль получения ДС] [int] NULL,
	[Заем выдан] [int] NULL,
	[Оценка качества] [int] NULL,
	[Заем погашен] [int] NULL,
	[Заем аннулирован] [int] NULL,
	[Аннулировано] [int] NULL,
	[Отказ документов клиента] [int] NULL,
	[Отказано] [int] NULL,
	[Отказ клиента] [int] NULL,
	[Клиент передумал] [int] NULL,
	[Забраковано] [int] NULL
) 

-- заявки
if object_id('tempdb.dbo.#r') is not null drop table #r
select requestSource=soz.[Представление]
     , r.*  into #r 
  from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС --[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Документ_ЗаявкаНаЗаймПодПТС]
r left join stg._1cCRM.Перечисление_СпособыОформленияЗаявок--[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Перечисление_СпособыОформленияЗаявок]  
   soz on soz.ссылка=r.СпособОформления
 where cast(дата as date)>dateadd(day,-5,dateadd(year,2000,cast(getdate() as date)      )   )


 --select * from #r where номер= '19111300000043'
--select * from    stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС  where номер= '19111500000305'
 /*
SELECT * 
FROM  [c1-vsr-sql04].crm.[dbo].РегистрСведений_СтатусыЗаявокНаЗаймПодПТС s --[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] s
      join  [c1-vsr-sql04].crm.[dbo].Документ_ЗаявкаНаЗаймПодПТС--[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Документ_ЗаявкаНаЗаймПодПТС] 
      r  on r.Ссылка=s.Заявка 
         join  [c1-vsr-sql04].crm.[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС]--[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС] 
      st on st.Ссылка=r. Статус
      join   [c1-vsr-sql04].crm.[dbo].[Справочник_Офисы] o on o.ссылка=r.Офис
  left join  [c1-vsr-sql04].crm.[dbo].Справочник_Пользователи p on p.ссылка=r.CRM_Автор




       where номер= '19111510000045'


   */
 -- последний статус
 if object_id('tempdb.dbo.#last_status') is not null drop table #last_status
 select 
               distinct 
                case when r.НомерЗаявки <>'' then r.НомерЗаявки else concat(r.Фамилия,' ',r.Имя,' ',r.Отчество,' ',r.СерияПаспорта,' ',r.НомерПаспорта) end   external_id
              , statusName =first_value(st.Наименование) over (partition by  r.НомерЗаявки order by Период desc)
--              ,*
   into   #last_status
 FROM  Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС s --[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] s
      join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС--[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Документ_ЗаявкаНаЗаймПодПТС] 
      r  on r.Ссылка=s.Заявка --and cast(Период as date)=cast(Дата as date)
      join Stg._1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС]--[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС] 
      st on st.Ссылка=s. Статус -- select * from [C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС] 
 
where Период>dateadd(day,-5,dateadd(year,2000,cast(getdate() as date)      )   )
--and r.НомерЗаявки <>''
		--and not r.НомерЗаявки  in (N'19112300001265' ,N'19112500001443')		-- временная заглушка


--select * from #last_status where external_id='19081500000255'  order by 1




-- статусы заявок
if object_id('tempdb.dbo.#t') is not null drop table #t

;
with todayRequests as (

select distinct  External_id= case when r.НомерЗаявки <>'' then r.НомерЗаявки else concat(r.Фамилия,' ',r.Имя,' ',r.Отчество,' ',r.СерияПаспорта,' ',r.НомерПаспорта) end 

     , StatusCode =st.КодСтатуса
     , statusName =st.Наименование
   
     , dt         =first_value(dateadd(year,-2000,Период)) over(partition by r.НомерЗаявки, st.КодСтатуса, st.Наименование order by Период desc)
     
  FROM stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС--[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] 
      s
      join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС --[C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Документ_ЗаявкаНаЗаймПодПТС] 
      r  on r.Ссылка=s.Заявка and cast(Период as date)=cast(Дата as date)
      join Stg._1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС]-- select * from [C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС] select * from Stg._1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС]
      st on st.Ссылка=s. Статус -- select * from [C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС] 
      
where Период>dateadd(day,-5,dateadd(year,2000,cast(getdate() as date)      )   )
and r.НомерЗаявки <>''
and st.Наименование in ('Черновик из ЛК',
'Клиент прикрепляет фото в МП',
'Клиент зарегистрировался в МП',
'Просрочен',
'Платеж опаздывает',
'Проблемный',
'ТС продано',
'Черновик',
'Предварительная',
'Верификация КЦ',
'Предварительное одобрение',
'Контроль авторизации',
'Контроль ПЭП',
'Контроль заполнения ЛКК',
'Контроль фото ЛКК',
'Назначение встречи',
'Встреча назначена',
'Ожидание контроля данных',
'Контроль данных',
'Выполнение контроля данных',
'Верификация документов клиента',
'Контроль верификация документов клиента',
'Одобрены документы клиента',
'Контроль одобрения документов клиента',
'Верификация документов',
'Контроль верификации документов',
'Одобрено',
'Договор зарегистрирован',
'Контроль подписания договора',
'Проверка ПЭП и ПТС',
'Договор подписан',
'Контроль получения ДС',
'Заем выдан',
'Оценка качества',
'Заем погашен',
'Заем аннулирован',
'Аннулировано',
'Отказ документов клиента',
'Отказано',
'Отказ клиента',
'Клиент передумал',
'Забраковано'



)


		--and not r.НомерЗаявки  in (N'19112300001265' ,N'19112500001443')
)

/*
select * from [C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС]
order by     ПорядокСледованияСтатусов

select [Представление],* from [C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Документ_ЗаявкаНаЗаймПодПТС] r 

      ,[Представление]
  FROM [CRM_NIGHT01].[dbo].[Перечисление_СпособыОформленияЗаявок]

*/

select External_id 
     , StatusCode 
     , statusName 
     
     , dt  
     ,isnull(lead(dt) over(partition by external_id order by dt   )  ,cast(getdate() as datetime)) prev_dt
        ,lead(dt) over(partition by external_id order by dt   )  
         
         
        next_dt
    ,datediff(second,dt,isnull(lead(dt) over(partition by external_id order by dt   )  ,cast(getdate() as datetime))) duration
         ,datediff(second,dt,  lead(dt) over(partition by external_id order by dt   ) ) duration1
     into #t
from todayRequests
--where not External_id in (N'19112300001265' ,N'19112500001443')			-- временная заглушка 
order by 1,4

--select * from #t where external_id='19081300000127' order by dt


/*
select  External_id 
     , StatusCode 
     , statusName 
     , dt  
     , prev_dt
     , duration
from #t
  */
  /*
if object_id('tempdb.dbo.#n') is not null drop table #n
select distinct  ПорядокСледованияСтатусов,Наименование StatusName,КодСтатуса into #n  from Stg._1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС]--  [C1-VSR-SQL05].[CRM_NIGHT01].[dbo].[Справочник_СтатусыЗаявокПодЗалогПТС]
order by ПорядокСледованияСтатусов
*/
declare @s nvarchar(2048)=N''
select @s=N'
"Черновик из ЛК",
  "Клиент прикрепляет фото в МП",
	"Клиент зарегистрировался в МП",
	"Просрочен",
	"Платеж опаздывает",
	"Проблемный",
	"ТС продано",
	"Черновик",
	"Предварительная",
	"Верификация КЦ",
	"Предварительное одобрение",
	"Контроль авторизации",
	"Контроль ПЭП",
	"Контроль заполнения ЛКК",
	"Контроль фото ЛКК",
	"Назначение встречи",
	"Встреча назначена",
	"Ожидание контроля данных",
	"Контроль данных",
	"Выполнение контроля данных",
	"Верификация документов клиента",
	"Контроль верификация документов клиента",
	"Одобрены документы клиента",
	"Контроль одобрения документов клиента",
	"Верификация документов",
	"Контроль верификации документов",
	"Одобрено",
	"Договор зарегистрирован",
	"Контроль подписания договора",
	"Проверка ПЭП и ПТС",
	"Договор подписан",
	"Контроль получения ДС",
	"Заем выдан",
	"Оценка качества",
	"Заем погашен",
	"Заем аннулирован",
	"Аннулировано",
	"Отказ документов клиента",
	"Отказано",
	"Отказ клиента",
	"Клиент передумал",
	"Забраковано"
  '



                    --[Статус заявки]= 'Статус заявки',

declare @tsql nvarchar(4000)=N''


set @tsql='insert into #tt
select External_id , '+@s+'    
from 
(   select  External_id ,statusName ,duration  from #t


)      t
pivot (
sum(duration)
 for   statusName in ('+@s+')
)   as pvt

'

--select @tsql
exec (@tsql)






  select 
  
  r.requestSource
  ,st.Наименование
  ,o.Код КодОфиса
  , employee=p.Наименование
  , дата=dateadd(year,-2000,r.Дата)
  , фамилия +' '+ имя +' '+ отчество fio
       , Номер

       , Сумма
       , СуммаВыданная
  --     , СуммаПервичная
       --, СуммаРекомендуемая
       
      
       
  ,tt.[Черновик из ЛК]
	
	,tt.[Клиент прикрепляет фото в МП]
	,tt.[Клиент зарегистрировался в МП]
	,tt.[Просрочен]
	,tt.[Платеж опаздывает]
	,tt.[Проблемный]
	,tt.[ТС продано]
	,tt.[Черновик]
	,tt.[Предварительная]
	,tt.[Верификация КЦ]
	,tt.[Предварительное одобрение]
	,tt.[Контроль авторизации]
	,tt.[Контроль ПЭП]
	,tt.[Контроль заполнения ЛКК]
	,tt.[Контроль фото ЛКК]
	,tt.[Назначение встречи]
	,tt.[Встреча назначена]
	,tt.[Ожидание контроля данных]
	,tt.[Контроль данных]
	,tt.[Выполнение контроля данных] 
	,tt.[Верификация документов клиента]
	,tt.[Контроль верификация документов клиента]
	,tt.[Одобрены документы клиента] [int]
	,tt.[Контроль одобрения документов клиента]
	,tt.[Верификация документов]
	,tt.[Контроль верификации документов]
	,tt.[Одобрено]
	,tt.[Договор зарегистрирован]
	,tt.[Контроль подписания договора]
	,tt.[Проверка ПЭП и ПТС]
	,tt.[Договор подписан]
	,tt.[Контроль получения ДС]
	,tt.[Заем выдан]
	,tt.[Оценка качества]
	,tt.[Заем погашен]
	,tt.[Заем аннулирован]
	,tt.[Аннулировано]
	,tt.[Отказ документов клиента]
	,tt.[Отказано]
	,tt.[Отказ клиента]
	,tt.[Клиент передумал]
	,tt.[Забраковано]
  ,lastStatusName=l.statusName
       
       
         from #tt tt 
join #r r on r.номерзаявки =tt.External_id
left join Stg._1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС]  st on st.Ссылка=r. Статус
left join   Stg._1cCRM.[Справочник_Офисы] o on o.ссылка=r.Офис     
left join  Stg._1cCRM.Справочник_Пользователи p on p.ссылка=r.CRM_Автор
left join #last_status l on l.external_id  =tt.External_id

--where not tt.External_id in (N'19112300001265' ,N'19112500001443')		-- временная заглушка

order by dateadd(year,-2000,r.Дата)

/*

select * from #tt tt
join #r r on r.номерзаявки =tt.External_id
left join #last_status l on l.external_id  =tt.External_id

where [Верификация КЦ]>=120 and l.statusName='Верификация КЦ'

*/
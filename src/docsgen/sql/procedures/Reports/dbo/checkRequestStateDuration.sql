--exec reports.dbo.checkRequestStateDuration

CREATE PROC [dbo].[checkRequestStateDuration]
as
begin


set nocount on


--exec reports.dbo.checkRequestStateDurationByName  600,'Контроль данных','Выполнение контроля данных','E.Mogilevskaya@carmoney.ru; shubkin_a_n@carmoney.ru','Заявки в статусе "Верификация КД" больше 10 минут','Контроль данных','Выполнение контроля данных'
--exec reports.dbo.checkRequestStateDurationByName1 1200,'Верификация документов клиента','E.Mogilevskaya@carmoney.ru; shubkin_a_n@carmoney.ru','Заявки в статусе "Верификация ВДК" больше 20 минут','Верификация документов клиента'
--exec reports.dbo.checkRequestStateDurationByName1 600,'Верификация документов','E.Mogilevskaya@carmoney.ru; shubkin_a_n@carmoney.ru','Заявки в статусе "Верификация ВД" больше 10 минут','Верификация документов'
-- в статусе "предварительное одобрение" больше 5 минут и   не из мобилки


if cast(getdate() as time)<='22:00'
		and cast(getdate() as time)>='07:00'
		/*
  exec reports.dbo.checkRequestStateDurationByNameAndNotSource 1200,'Предварительное одобрение','2nd-line-monitoring@carmoney.ru; rgkc@carmoney.ru; 
																	Demkina_A_M@carmoney.ru;  
																	teplyakov@carmoney.ru; korolev@carmoney.ru; bityugin@carmoney.ru; 
																	dwh112@carmoney.ru; D.Polozov@carmoney.ru'
																	,'Заявки в статусе "Предварительное одобрение" больше 20 минут'
																	,'Предварительное одобрение','8999'

*/

if object_id('tempdb.dbo.#t1') is not null drop table #t1
CREATE TABLE #t1(
 
    requestSource [nvarchar](128)  NULL
  ,  RequestStatus [nvarchar](128)  NULL
  , КодОфиса int
  , Employee [nvarchar](512)  NULL
  , дата datetime
  , fio [nvarchar](512)  NULL
  , Номер  [nvarchar](128)  NULL

  , Сумма float
  , СуммаВыданная float
	--[External_id] [nvarchar](28)  NULL,
  ,
	[Черновик из ЛК] [int] NULL,
	[Проверка ПЭП и ПТС] [int] NULL,
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
	[Забраковано] [int] NULL,
  lastStatusName [nvarchar](128)  NULL
)

insert into #t1 
exec  [dbo].[reportRequestStatuses]


--select * from #t1 where Номер='20030300013501'


if not isnull((select count(*) 
				from #t1 
				where [Верификация КЦ]>=120 
				and lastStatusName='Верификация КЦ'
				and not [Номер] in (N'19112300001265' ,N'19112500001443')		-- временная заглушка
			   ),0)=0 
begin
select 
       [Источник заявки]=requestSource
     , дата
     , Номер
     , Сумма
     , [В статусе "Верификация КЦ", с]=[Верификация КЦ]
     , [Последний статус]=lastStatusName
from #t1
where [Верификация КЦ]>=120 and lastStatusName='Верификация КЦ'
		--and not [Номер] in (N'19112300001265' ,N'19112500001443')		-- временная заглушка
order by дата




DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
SET @tableHTML =  
    N'<H1>Заявки в статусе  "Верификация КЦ" больше 2 минут</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Источник заявки</th><th>дата</th>' +  
    N'<th>Номер</th><th>Сумма</th><th>В статусе "Верификация КЦ", с</th>' +  
    N'<th>Последний статус</th></tr>' +  
    CAST ( ( SELECT td = requestSource,       '',  
                    td = дата, '',  
                    td = Номер, '',  
                    td =  format(Сумма,'0'), '',  
                    td = [Верификация КЦ], '',  
                    td = lastStatusName 
              from #t1
where [Верификация КЦ]>=120 and lastStatusName='Верификация КЦ'
order by дата
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML


EXEC msdb.dbo.sp_send_dbmail 
	@recipients='osis_szd@carmoney.ru; dwh112@carmoney.ru; ',  --По согласование с А. Петровым 02.09.2024
    @profile_name = 'Default',  
    @subject = 'Заявки в статусе "Верификация КЦ" больше 2 минут',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  
end



--exec reports.dbo.checkRequestStateDurationByName   120,'Верификация КЦ','Gustyakov_B_V@carmoney.ru; E.Tigunov@carmoney.ru;V.Shadzhe@carmoney.ru;  a.baykov@carmoney.ru; prometov@carmoney.ru; ilina_e_v@carmoney.ru; shubkin_a_n@carmoney.ru; kurdin@carmoney.ru ;Vasilev@carmoney.ru; Krivotulov@carmoney.ru','Заявки в статусе "Верификация КЦ" больше 2 минут','Верификация КЦ'

drop table if exists #fedor_requests
select requestSource='Fedor'
      , дата=ch.createdon
      , Номер=cr.number
      , Сумма=SumContract
      , [Верификация КЦ]=abs(datediff(second,ch.createdOn,dateadd(hour,-3,getdate())))
      , lastStatusName= last_crs.name
   into #fedor_requests
	--DWH-1447 Анализ процедуры Reports.dbo.checkRequestStateDuration
	--from prodsql02.[Fedor.Core].[core].[ClientRequestHistory]   ch
	--join prodsql02.[Fedor.Core].[core].clientrequest cr on cr.id=ch.IdClientRequest
	--join prodsql02.[Fedor.Core].dictionary.[ClientRequestStatus] crs on crs.id=ch.IdClientRequestStatus
	--join prodsql02.[Fedor.Core].dictionary.[ClientRequestStatus] last_crs on last_crs.id=cr.IdStatus
	FROM Stg._fedor.core_ClientRequestHistory AS ch
	join Stg._fedor.core_clientrequest AS cr on cr.id=ch.IdClientRequest
	join Stg._fedor.dictionary_ClientRequestStatus AS crs on crs.id=ch.IdClientRequestStatus
	join Stg._fedor.dictionary_ClientRequestStatus AS last_crs on last_crs.id=cr.IdStatus
  where ch.createdOn>=dateadd(day,-5,cast(getdate() as date))
    and crs.name='Верификация КЦ' and last_crs.name=crs.name
    and abs(datediff(second,ch.createdOn,dateadd(hour,-3,getdate())))>120
  

  --select * from #fedor_requests where номер='20030300013501'
  
  /* 
  --Отключили рассылку в рамках задачи DWH-1130 20-05-2021
if not isnull((select count(*) 
				from #fedor_requests 
				where [Верификация КЦ]>=120 and lastStatusName='Верификация КЦ' 
						and not [Номер] in (N'19112300001265' ,N'19112500001443')		-- временная заглушка
			   ),0)=0 
begin   
  
SET @tableHTML =  
    N'<H1>Заявки FEDOR  в статусе  "Верификация КЦ" больше 2 минут</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Источник заявки</th><th>дата</th>' +  
    N'<th>Номер</th><th>Сумма</th><th>В статусе "Верификация КЦ", с</th>' +  
    N'<th>Последний статус</th></tr>' +  
    CAST ( ( SELECT td = requestSource,       '',  
                    td = дата, '',  
                    td = Номер, '',  
                    td =  format(Сумма,'0'), '',  
                    td = [Верификация КЦ], '',  
                    td = lastStatusName 
              from #fedor_requests
where [Верификация КЦ]>=120 and lastStatusName='Верификация КЦ' 
order by дата
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML


EXEC msdb.dbo.sp_send_dbmail @recipients='Gustyakov_B_V@carmoney.ru; 
										 prometov@carmoney.ru; ilina_e_v@carmoney.ru; 
											shubkin_a_n@carmoney.ru; Vasilev@carmoney.ru
											;D.Polozov@carmoney.ru',  --; Krivotulov@carmoney.ru
    @profile_name = 'Default',  
    @subject = 'Заявки FEDOR в статусе "Верификация КЦ" больше 2 минут',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  

end
*/

-- заявка из таблицы заявок CRM у которой в регистре есть статус предварительное одобрение
drop table if exists #req_1

select r.Номер, st.наименование, дата=dateadd(year,-2000,s.Период) 
into #req_1

from 
--DWH-1447 Анализ процедуры Reports.dbo.checkRequestStateDuration

Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS s
      join Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS r on r.Ссылка=s.Заявка and cast(Период as date)=cast(Дата as date)
      join Stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS st on st.Ссылка=s. Статус 
where r.Номер in (

                  
                  select distinct r.Номер/*,s.НАименование*/ from Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS r
                  left join Stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS s on r.Статус=s.ССылка
                  where r.Дата>dateadd(day,5,cast(getdate() as date))
                  and s.НАименование='Предварительное одобрение'
                  )

and st.наименование = 'Встреча назначена'
and abs(datediff(minute,dateadd(year,-2000,s.Период),cast(getdate() as date)))>10



if not isnull((select count(*) 
				from #req_1
				
			   ),0)=0 
begin   
  
SET @tableHTML =  
    N'<H1>заявка из таблицы заявок CRM в статусе предварительное одобрение,  у которой в регистре есть статус встреча назначена</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Номер</th><th>Наименование</th>' +  
    N'<th>Дата</th></tr>' +  
    CAST ( ( SELECT td = Номер, '',  
                    td =  Наименование, '',  
                    td = Дата
              from #req_1
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML

if cast(getdate() as time)<='22:00'
		and cast(getdate() as time)>='11:00'

EXEC msdb.dbo.sp_send_dbmail @recipients='dwh112@carmoney.ru; 2nd-line-monitoring@carmoney.ru;   korolev@carmoney.ru;',
    @profile_name = 'Default',  
    @subject = 'заявка из таблицы заявок CRM в статусе предварительное одобрение,  у которой в регистре есть статус встреча назначена',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  

end



drop table if exists #req_2

select rn=row_number() over (order by s.Период), r.Номер
, st.наименование статусВРеестре, st1.наименование СтатусВЗаявке, дата=dateadd(year,-2000,s.Период) 
into #req_2


from   [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС AS r 
left join [C3-VSR-SQL02].crm.dbo.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS s on r.Ссылка=s.Заявка --and cast(Период as date)=cast(r.Дата as date)
left join [C3-VSR-SQL02].crm.dbo.Справочник_СтатусыЗаявокПодЗалогПТС AS st on st.Ссылка=s. Статус 
left join [C3-VSR-SQL02].crm.dbo.Справочник_СтатусыЗаявокПодЗалогПТС AS st1 on st1.Ссылка=r. Статус 
--4where r.Номер='19082000000176'
where  1=1
and r.Номер not in (
	'22020700236097',
	'22020700236436',
	'01710169910001',
	'19080800000205',
	'18060702150001', 
	'19111510000160',
	'01609122580002',
	'21012300072506',
	'20081000027971', 
	'20101500042580',
	'19100400000108',
	'22031100295475', -- 2022-08-01. А.Никитин по обращению @E.Panina (Екатерина Панина)
	'19092300000092', -- 2022-08-03. А.Никитин по обращению: Максим Пшеничников @M.Pshenichnikov 12:49
	'22110700567854', -- 2023-04-06. А.Котелевец  по обращению: Екатерина Панина @E.Panina 15:29
	'21021700080239' -- 2024-01-10. А.Никитин по обращению: Роман Алехин @r.alehin 2024-01-10 12:09
	)

and st.наименование like '%погашен%'
and cast(Период as date)>='40191217'
and cast(Период as date)<dateadd(year,2000,dateadd(minute,-20,getdate()))
and  st1.наименование not like '%погашен%'
order by s.Период

if not isnull((select count(*) 
				from #req_2
				
			   ),0)=0 
begin   
  
SET @tableHTML =  
    N'<H1>Заявки из в регистре "заем погашен", в таблице заявок любой другой статус</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>N</th><th>Номер</th><th>статусВРеестре</th><th>СтатусВЗаявке</th>' +  
    N'<th>Дата</th></tr>' +  
    CAST ( ( SELECT td = rn, '',  td = Номер, '',  
                    td =  статусВРеестре, '',  
                    td =  СтатусВЗаявке, '',  
                    td = Дата
              from #req_2
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML

if cast(getdate() as time)<='22:00'
		and cast(getdate() as time)>='11:00'

EXEC msdb.dbo.sp_send_dbmail @recipients='dwh112@carmoney.ru; 112@carmoney.ru; korolev@carmoney.ru',
    @profile_name = 'Default',  
    @subject = 'Заявки из в регистре "заем погашен", в таблице заявок любой другой статус',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  

end



-- убрано из рассылки 2021-05-13 
/*

drop table if exists #fedor_requests1

SELECT r.Id
     , Номер=r.number
     , lastStatusName= last_crs.name
     ,     дата=dateadd(hour,3,ch.CreatedOn)
       into #fedor_requests1
  FROM prodsql02.[Fedor.Core].[core].[ClientRequest] as r
  join prodsql02.[Fedor.Core].[core].[TaskAndClientRequest] as tr
  on tr.IdClientRequest = r.Id
  join prodsql02.[Fedor.Core].[core].[Task] as t
  on t.Id = tr.IdTask
    join prodsql02.[Fedor.Core].dictionary.[ClientRequestStatus] last_crs on last_crs.id=r.IdStatus
      join prodsql02.[Fedor.Core].[core].[ClientRequestHistory]   ch on r.id=ch.IdClientRequest and ch.IdClientRequestStatus=last_crs.id
  where t.IdStatus in(1, 2)
  and ch.createdOn>=dateadd(day,-5,cast(getdate() as date))
 -- and  last_crs.name='Контроль данных'
 /*
select distinct 
        дата=dateadd(hour,3,ch.CreatedOn)
      , Номер=cr.number
      
    
      , lastStatusName= last_crs.name
      
   into #fedor_requests1
   from prodsql02.[Fedor.Core].[core].clientrequest cr 
   join prodsql02.[Fedor.Core].dictionary.[ClientRequestStatus] last_crs on last_crs.id=cr.IdStatus
   join prodsql02.[Fedor.Core].[core].[ClientRequestHistory]   ch on cr.id=ch.IdClientRequest and ch.IdClientRequestStatus=last_crs.id
   join prodsql02.[Fedor.Core].dictionary.[ClientRequestStatus] crs on crs.id=ch.IdClientRequestStatus

  where ch.createdOn>=dateadd(day,-5,cast(getdate() as date))
  and  last_crs.name='Контроль данных'
  --and cr.number='20030300013501'
  --order by 1,3
    --and crs.name='Верификация КЦ' and last_crs.name=crs.name
    --and abs(datediff(second,ch.createdOn,dateadd(hour,-3,getdate())))>120
  */

if not isnull((select count(*) 
				from #fedor_requests1 
		),0)=0 
begin   
  
SET @tableHTML =  
    N'<H1>Заявки FEDOR пришли в статус  "Контроль данных" </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>дата</th>' +  
    N'<th>Номер</th>' +  
    N'<th>Последний статус</th></tr>' +  
    CAST ( ( SELECT 
                    td = дата, '',  
                    td = Номер, '',  
                  
                    td = lastStatusName 
              from #fedor_requests1

order by дата
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML

--E.Mogilevskaya@carmoney.ru; sedova@carmoney.ru; 
EXEC msdb.dbo.sp_send_dbmail @recipients='prometov@carmoney.ru; pribilov@carmoney.ru ;
										  korolev@carmoney.ru; 
										 shubkin_a_n@carmoney.ru
										 ;D.Polozov@carmoney.ru',  --; Krivotulov@carmoney.ru
    @profile_name = 'Default',  
    @subject = 'Заявки FEDOR в статусе "Контроль данных" ',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  

end

*/


--dwh-539

/* --cмотреть процедуру - monitoring_crm_references_with_zero_du
 -- последний статус
  if object_id('tempdb.dbo.#last_status') is not null drop table #last_status
 
  select distinct case when r.НомерЗаявки <>'' then r.НомерЗаявки else concat(r.Фамилия,' ',r.Имя,' ',r.Отчество,' ',r.СерияПаспорта,' ',r.НомерПаспорта) end   external_id
       , statusName =first_value(st.Наименование) over (partition by  r.НомерЗаявки order by Период desc)
    into #last_status
	--DWH-1447 Анализ процедуры Reports.dbo.checkRequestStateDuration
    --FROM [prodsql01].crm.dbo.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС s 
    --join [prodsql01].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС r  on r.Ссылка=s.Заявка --and cast(Период as date)=cast(Дата as date)
    --join [prodsql01].crm.dbo.[Справочник_СтатусыЗаявокПодЗалогПТС] st on st.Ссылка=s. Статус 
    FROM [C3-VSR-SQL02].crm.dbo.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS s 
    join[C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС AS r  on r.Ссылка=s.Заявка --and cast(Период as date)=cast(Дата as date)
    join[C3-VSR-SQL02].crm.dbo.Справочник_СтатусыЗаявокПодЗалогПТС AS st on st.Ссылка=s. Статус 
   where Период>dateadd(day,-5,dateadd(year,2000,cast(getdate() as date)      )   )

   drop table if exists #du
  select r.Номер
       , sdu.Наименование ДопУслуга
      -- , du.Включена
       , du.СуммаДопУслуги
       , ls.statusName СтатусЗаявки 
       into #du
	--DWH-1447 Анализ процедуры Reports.dbo.checkRequestStateDuration
    --from [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС_ДопУслуги du
    --join [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС r on du. ссылка=r.ссылка
    --join [C3-VSR-SQL02].[crm].[dbo].[Справочник_ДополнительныеУслуги] sdu on sdu.ссылка= du.ДопУслуга
    from [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС_ДопУслуги AS du
    join [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС AS r on du. ссылка=r.ссылка
    join [C3-VSR-SQL02].crm.dbo.Справочник_ДополнительныеУслуги AS sdu on sdu.ссылка= du.ДопУслуга
    join (select * 
            from #last_status 
           where statusName not in ('P2P','Аннулировано','Заем аннулирован','Заем выдан','Заем погашен','Отказ документов клиента','Отказано','Платеж опаздывает','Проблемный','Просрочен','ТС продано'
                 ,'Клиент передумал','Забраковано','Черновик', 'Заполнение анкеты птс')
         ) ls on ls.external_id=r.Номер
   where СуммаДопУслуги=0 and Включена=0x01
   and r.Номер not in ('23120401499379') --по согласованию И.Морозовой

   select * from #du
   
   declare @tableHTML1 nvarchar(max)
   
   if not isnull((select count(*) 
				from #du
		),0)=0 
begin 

  
SET @tableHTML1 =  
    N'<H1>Заявки CRM с нулевыми сммами допуслуг </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Номер</th>' +  
    N'<th>ДопУслуга</th>' +  
    N'<th>Сумма ДопУслуги</th>' +  
    N'<th>Последний статус</th></tr>' +  
    CAST ( ( SELECT 
                    td = Номер, '',  
                    td = ДопУслуга, '',  
                  
                    td = СуммаДопУслуги, '',  
                  
                    td = СтатусЗаявки 
              from #du

order by Номер
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML1


EXEC msdb.dbo.sp_send_dbmail @recipients='dwh112@carmoney.ru; ',
--; Krivotulov@carmoney.ru
    @profile_name = 'Default',  
    @subject = 'Заявки CRM с нулевыми сммами допуслуг  ',  
    @body = @tableHTML1,  
    @body_format = 'HTML' ;  

end
*/


end




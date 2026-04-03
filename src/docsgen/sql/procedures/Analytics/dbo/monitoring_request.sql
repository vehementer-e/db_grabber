 
CREATE     proc monitoring_request
@mode nvarchar(max) = 'update'	  ,
@recreate int = 0 
as  
--exec monitoring_request 'update' , 1
if @mode ='marketing_attribution_visualisation'

begin
select -- top 1006
    a.[ДатаЗаявки] 
,   a.[НомерЗаявки] 
,   a.[ТипКредитногоПродукта] 
,   a.[МестоСоздания] 	+ isnull( ' '+ a.[ТипКредитногоПродукта] , '') 	 [МестоСоздания]
,   a.[Телефон] 
,   a.[marketing_status] 
,   a.[type] 
,   a.[entrypoint] 
,   a.[original_lead_idd] 
,   a.[lead_id] 
,   a.[source_name] 
,   a.[Источник] 
,   a.[leads_info] 
,   a.[visits_info] 
,   a.[минут С визита] 
,   a.[stat_source] 
,   a.[channel_name] 
,   a.[Exceptions info] 
,   a.[Заем выдан] 
,   a.[ДатаЛида] 
,   a.[Номер] 

from 
 marketing_attribution_visualisation a

 end

if @mode ='select'

  
 select  * from 	_birs.request_health_log


if @mode ='update'
begin
 --exec [dbo].[Время статусов верификации]




drop table if exists #t1
select Дата into #t1 from v_Calendar  a
where Дата between getdate()-15 and getdate()

drop table if exists #t2

select a.*, dateadd(minute, -m.min , dateadd(second, h*60*60-1, cast(Дата as datetime) )) dt into #t2 from #t1 a
cross join (
select 1 h union all
select 2 union all
select 3 union all
select 4 union all
select 5 union all
select 6 union all
select 7 union all
select 8 union all
select 9 union all
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
select 24-- union all
) t
cross join (
select 0 min  union all
select 5 h union all
select 10 h union all
select 15 h union all
select 20 union all
select 25 union all
select 30 union all
select 35 union all
select 40 union all
select 45 union all
select 50 union all
select 55 --union all
) m


drop table if exists #fa

select 
  a.[Верификация КЦ] [Верификация КЦ]
, a.product
, a.Отказано Отказано
, a.[Предварительное одобрение] [Предварительное одобрение]
, a.[контроль данных] [контроль данных]
, a.call2	call2
, a.[call2 accept] [call2 accept]
, a.Одобрено Одобрено
, b.[Договор подписан] [Договор подписан]
 ,a.Аннулировано Аннулировано
, isnull(a.[заем выдан], ds.[ДатаВыдачи] ) [заем выдан]
, a.[заем аннулирован] [заем аннулирован]
, a.[Отказ клиента] [Отказ клиента]
, a.Забраковано Забраковано
, a.Номер
, b.СтатусЗаявки
, b.lk_request_id
, a.[Вид займа]
, a.[Признак Забраковано] [Признак Забраковано]
, a.[сумма заявки]
, a.[сумма одобренная]
, a.[первичная сумма]
,case 
when a.isPts = 1 then 'ПТС '


else 'Беззалог ' end  + a.[Место cоздания]	[Место cоздания]
, c1.[Дата первой доработки]   [Контроль данных Дата первой доработки]
, c3.[Дата статуса]            [Верификация клиента]
, c3.[Дата первой доработки]   [Верификация клиента Дата первой доработки]
, c2.[Дата статуса]            [Верификация ТС]
, c2.[Дата первой доработки]   [Верификация ТС Дата первой доработки]
, a.isPts


into #fa 
from mv_dm_factor_analysis a
left join v_request b  on a.Номер=b.НомерЗаявки
left join reports.dbo.dm_SaLES DS ON DS.кОД=A.Номер
left join [Отчет Время статусов верификации] c1 on c1.Номер=a.[Номер] And c1.[Статус]='Контроль данных'
left join [Отчет Время статусов верификации] c2 on c2.Номер=a.[Номер] And c2.[Статус]='Верификация ТС'
left join [Отчет Время статусов верификации] c3 on c3.Номер=a.[Номер] And c3.[Статус]='Верификация клиента'
where a.ФИО <>''	 and  a.[Верификация КЦ]>=dateadd(day, -15, getdate())	and a.Дубль=0

select a.*
,isnull( b.[Добавление карты], [Переход на экран Способ выдачи ПТС]) [Добавление карты]
,isnull( b.[Карта привязана ПТС], [Одобрение]) [Карта привязана]
	 into #fa1
from 	#fa a
left join _birs.product_report_request b on a.Номер=b.number

		  
	
--select  b.request_id
--, min(case when  b.event_id in (86, 431, 97, 76) then    b.created_at end) dt
--, min(case when  b.event_id in (77, 98) then    b.created_at end) dt


--  into #t1 from  stg._lk.requests_events b  
-- group by 	 b.request_id	  
		   
--		   exec _birs.product_report_actions	 'update'
--exec _birs.[request_health] 'update'  , 1


drop table if exists #t3

select *, case when cast(dt as date)=cast([Верификация КЦ] as date) then 1 else 0 end [От сегодня] into  #t3 from (
select '1) Предварительное одобрение' [Воронка] , b.[Верификация КЦ] Дата,[первичная сумма] сумма ,a.dt, b.*  from #t2  a
 join #fa1 b on 
b.[Верификация КЦ]<=a.dt 
and (b.[Предварительное одобрение] is null or b.[Предварительное одобрение]>=a.dt )
and ( b.Отказано is null or b.Отказано>=a.dt )
and ( b.Забраковано is null or b.Забраковано>=a.dt )
and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
union all
--select 'Доезд' [Воронка],[первичная сумма] сумма, a.dt, b.*  from #t2  a
-- join #fa b on 
--b.[Предварительное одобрение]<=a.dt 
--and (b.[контроль данных] is null or b.[контроль данных]>=a.dt )
--and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
--union all
select  '2) КД' [Воронка] , b.[контроль данных] Дата,[первичная сумма] сумма, a.dt, b.*  from #t2  a
 join #fa1 b on 
b.[контроль данных]<=a.dt 
and (b.Отказано is null or b.Отказано>=a.dt )
and (b.Одобрено is null or b.Одобрено>=a.dt )
and (b.Забраковано is null or b.Забраковано>=a.dt )
and (b.[Контроль данных Дата первой доработки] is null or b.[Контроль данных Дата первой доработки]>=a.dt )
and (b.call2 is null or b.call2>=a.dt )
and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
and ( b.[заем аннулирован] is null or b.[заем аннулирован]>=a.dt )
union all									 
select  '4) ВДК' [Воронка] , b.[Верификация клиента] Дата,[первичная сумма] сумма, a.dt, b.*  from #t2  a
 join #fa1 b on 
b.[Верификация клиента]<=a.dt 
and (b.Забраковано is null or b.Забраковано>=a.dt )
and (b.Отказано is null or b.Отказано>=a.dt )
and (b.[Верификация клиента Дата первой доработки] is null or b.[Верификация клиента Дата первой доработки]>=a.dt )
and (b.[Верификация ТС] is null or b.[Верификация ТС]>=a.dt )
and (b.Одобрено is null or b.Одобрено>=a.dt )
and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
and ( b.[заем аннулирован] is null or b.[заем аннулирован]>=a.dt )	
union all									 
select  '5) ВД' [Воронка] , b.[Верификация ТС] Дата,[первичная сумма] сумма, a.dt, b.*  from #t2  a
 join #fa1 b on 
b.[Верификация ТС]<=a.dt 
and (b.Забраковано is null or b.Забраковано>=a.dt )
and (b.Отказано is null or b.Отказано>=a.dt )
and (b.[Верификация ТС Дата первой доработки] is null or b.[Верификация ТС Дата первой доработки]>=a.dt )
and (b.Одобрено is null or b.Одобрено>=a.dt )
and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
and ( b.[заем аннулирован] is null or b.[заем аннулирован]>=a.dt )
union all
--select 'Выдача'  [Воронка],[сумма одобренная] сумма, a.dt, b.* from #t2  a
-- join #fa b on 
--b.Одобрено<=a.dt 
--and (b.[заем выдан] is null or b.[заем выдан]>=a.dt )
--and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
--and ( b.[заем аннулирован] is null or b.[заем аннулирован]>=a.dt )
--	 
--union all
select '6) Договор подписан'  [Воронка] , b.[Договор подписан] Дата,[сумма одобренная] сумма, a.dt, b.* from #t2  a
 join #fa1 b on 
b.[Договор подписан]<=a.dt 
and (b.[заем выдан] is null or b.[заем выдан]>=a.dt )
and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
and ( b.[заем аннулирован] is null or b.[заем аннулирован]>=a.dt )

   
union all
select '3) call2'  [Воронка] , b.call2 Дата ,[первичная сумма] сумма, a.dt, b.* from #t2  a
 join #fa1 b on 
b.call2<=a.dt 
and (b.Отказано is null or b.Отказано>=a.dt )
and (b.[call2 accept] is null or b.[call2 accept]>=a.dt )
and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
and ( b.[заем аннулирован] is null or b.[заем аннулирован]>=a.dt )
 
 	  union all
select '4) Экран карта'  [Воронка] , b.[Добавление карты] Дата ,[первичная сумма] сумма, a.dt, b.* from #t2  a
 join #fa1 b on 
b.call2<=a.dt 
and (b.Отказано is null or b.Отказано>=a.dt )		   
and (b.Одобрено is null or b.Одобрено>=a.dt )		   
and (b.[Карта привязана] is null or b.[Карта привязана]>=a.dt )		   
and ( b.Аннулировано is null or b.Аннулировано>=a.dt )
and ( b.[заем аннулирован] is null or b.[заем аннулирован]>=a.dt )

  )x
 
where dt<getdate()	   and x.[Верификация КЦ]>=dateadd(day, -10, dt)
--and 

order by 1 desc , 2 desc, 3 desc

if @recreate=1
begin
drop table if exists _birs.request_health_log
 select * into 	_birs.request_health_log
 from #t3
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '3CDD36A0-D1AF-42A6-B433-8A97D6B021D2'
 return
 end




 delete from   _birs.request_health_log
insert into 	_birs.request_health_log
 select * from #t3
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '3CDD36A0-D1AF-42A6-B433-8A97D6B021D2'

end

if @mode ='update lead'
begin

drop table if exists #tt1
						   

CREATE TABLE [dbo].	#tt1
(
      [НомерЗаявки] [NVARCHAR](14)
    , [ДатаЗаявки] [DATETIME2](0)
    , [МестоСоздания] [VARCHAR](100)
    , [Заем выдан] [DATETIME2](0)
    , [isPts] [BIT]
	, lead_id nvarchar(36)
);

insert into  #tt1

select [НомерЗаявки], [ДатаЗаявки], [МестоСоздания]   [МестоСоздания], [Заем выдан], [isPts], null  from v_request
where 	[ДатаЗаявки]>=getdate()-30


insert into  #tt1

select isnull(num_1c, id) num_1c, created, origin,  null, case product when 'pts' then 1 else 0   end, a.lead_id  from v_request_lk	a
	 left join 	#tt1  b on a.num_1c=b.[НомерЗаявки]
where  a.created>= getdate()-30	 and b.[НомерЗаявки] is null

 
insert into  #tt1

select number  , created, [Processing_Type]+' (feodor)',  null,  null , null from v_request_feodor	a
	 left join 	#tt1  b on a.number=b.[НомерЗаявки]
where  a.created>= getdate()-30	 and b.[НомерЗаявки] is null



drop table if exists #tt2
select number, marketing_lead_id, original_lead_id, source into #tt2 from stg._lf.request


select --top 100 
               [НомерЗаявки], 
               [ДатаЗаявки], 
			   [МестоСоздания], 
			   [Заем выдан],
			   case when [isPts]=1 then 'ПТС' else 'Беззалог' end  [Птс/Беззалог], 
			   marketing_lead_id+case when t2.number is null then ' нет в LF' else '' end marketing_lead_id, 
			   isnull(original_lead_id, t1.lead_id) original_lead_id,
			   t3.source [Источник],
			   t3.channel [Канал]	 ,
			   t3.created original_Lead_created


from #tt1 t1
left join #tt2 t2 on t1.НомерЗаявки=t2.number
left join v_lead2 t3 on t2.marketing_lead_id=t3.id
left join v_lead2 original_lead on  original_lead.id	  = isnull(original_lead_id, t1.lead_id)

end

if @mode ='update draft'
begin

drop table if exists #ttt1
select id, created_at, requests_origin_id, case	
product_types_id
when 1 then 'PTS'
when 2 then 'INST'
when 3 then 'PDL'
end [product_type]  into #ttt1 from stg._lk.requests
 where cast(created_at as date) >= getdate()-30
 

drop table if exists #ttt2
select lk_request_id into #ttt2 from v_request
 where cast(ДатаЗаявки as date) >= getdate()-30
 

select         t1.id,
               t1.[product_type],
               t1.created_at,
			   t3.name_1c [Место создания]
from #ttt1 t1 
left join #ttt2 t2 on t1.id=t2.lk_request_id
left join analytics.dbo.LK_requests_origin t3 on t1.requests_origin_id = t3.id
where t2.lk_request_id is null
--and cast(t1.created_at as date) >= getdate()-30


end
 

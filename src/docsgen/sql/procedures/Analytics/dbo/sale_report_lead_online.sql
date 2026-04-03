
CREATE proc [dbo].[sale_report_lead_online] @mode nvarchar(max) = 'update'
as 

if @mode = 'Request1'

begin

SELECT   [crd_d]
        ,[end_t]
		,[Группа каналов]
		,[Канал от источника]
		,[is_inst_lead]   
		,[IsInstallment]     
		,[CompanyNaumen]     
		,[Поступило лидов]      
		,[Обработано лидов]     
		,[Дозвонились]     
		,[Лидов Feodor]      
		,[Профильных лидов Feodor]      
		,[Создано заявок]
		,UF_SOURCE   UF_SOURCE 
		,[UF_PARTNER_ID аналитический] [UF_PARTNER_ID аналитический]
		,isPdl  
FROM [Feodor].[dbo].dm_leads_history_by_hours 
where crd_d>getdate()-14 

--union all  
--
--SELECT   [crd_d]     
--        ,[end_t]      
--		,[Группа каналов]      
--		,[Канал от источника]      
--		,[is_inst_lead]      
--		,[IsInstallment]      
--		,[CompanyNaumen]     
--		,[Поступило лидов]     
--		,[Обработано лидов]      
--		,[Дозвонились]      
--		,[Лидов Feodor]      
--		,[Профильных лидов Feodor]      
--		,[Создано заявок]
--		,UF_SOURCE   UF_SOURCE 
--		,[UF_PARTNER_ID аналитический] [UF_PARTNER_ID аналитический]
--		,isPdl
--FROM [Feodor].[dbo].[dm_leads_history_by_hours] 
--where crd_d<getdate()-3

end



if @mode = 'Request2'

begin

select * ,h_join = case when h is null then ch else h end  
from (select isnull(cast( cast(h as time(0)) as nvarchar(max)), 'Последний срез') h_text,* 
    ,(select max(end_t) h_last from Feodor.dbo.dm_leads_history_by_hours 
      where crd_d = (select max(crd_d) from  Feodor.dbo.dm_leads_history_by_hours)) ch  
	  from (select cast('00:00:00' as time(0)) h 
	  union all select cast('01:00:00' as time)
	  union all select cast('02:00:00' as time)
	  union all select cast('03:00:00' as time)
	  union all select cast('04:00:00' as time)
	  union all select cast('05:00:00' as time)
	  union all select cast('06:00:00' as time)
	  union all select cast('07:00:00' as time)
	  union all select cast('08:00:00' as time)
	  union all select cast('09:00:00' as time)
	  union all select cast('10:00:00' as time)
	  union all select cast('11:00:00' as time)
	  union all select cast('12:00:00' as time)
	  union all select cast('13:00:00' as time)
	  union all select cast('14:00:00' as time)
	  union all select cast('15:00:00' as time)
	  union all select cast('16:00:00' as time)
	  union all select cast('17:00:00' as time)
	  union all select cast('18:00:00' as time)
	  union all select cast('19:00:00' as time)
	  union all select cast('20:00:00' as time)
	  union all select cast('21:00:00' as time)
	  union all select cast('22:00:00' as time)
	  union all select cast('23:00:00' as time) 
	  union all select cast('23:59:59' as time) 
	  union all select null)x)x

end



if @mode = 'Request3'

begin

select cast('00:00:00' as time) h 
union all  select cast('01:00:00' as time)  
union all  select cast('02:00:00' as time)  
union all  select cast('03:00:00' as time)  
union all  select cast('04:00:00' as time)  
union all  select cast('05:00:00' as time)  
union all  select cast('06:00:00' as time)  
union all  select cast('07:00:00' as time)  
union all  select cast('08:00:00' as time)  
union all  select cast('09:00:00' as time)  
union all  select cast('10:00:00' as time)  
union all  select cast('11:00:00' as time)  
union all  select cast('12:00:00' as time)  
union all  select cast('13:00:00' as time)  
union all  select cast('14:00:00' as time)  
union all  select cast('15:00:00' as time)  
union all  select cast('16:00:00' as time)  
union all  select cast('17:00:00' as time)  
union all  select cast('18:00:00' as time)  
union all  select cast('19:00:00' as time)  
union all  select cast('20:00:00' as time)  
union all  select cast('21:00:00' as time)  
union all  select cast('22:00:00' as time)  
union all  select cast('23:00:00' as time) 
union all  select cast('23:59:59' as time)

end
 



 if @mode = 'update'

 begin

 	  drop table if exists #hours_of_day

select cast('00:00:00' as time) h into #hours_of_day union all
select cast('01:00:00' as time)	union all
select cast('02:00:00' as time)	union all
select cast('03:00:00' as time)	union all
select cast('04:00:00' as time)	union all
select cast('05:00:00' as time)	union all
select cast('06:00:00' as time)	union all
select cast('07:00:00' as time)	union all
select cast('08:00:00' as time)	union all
select cast('09:00:00' as time)	union all
select cast('10:00:00' as time)	union all
select cast('11:00:00' as time)	union all
select cast('12:00:00' as time)	union all
select cast('13:00:00' as time)	union all
select cast('14:00:00' as time)	union all
select cast('15:00:00' as time)	union all
select cast('16:00:00' as time)	union all
select cast('17:00:00' as time)	union all
select cast('18:00:00' as time)	union all
select cast('19:00:00' as time)	union all
select cast('20:00:00' as time)	union all
select cast('21:00:00' as time)	union all
select cast('22:00:00' as time)	union all
select cast('23:00:00' as time) union all
select cast('23:59:59' as time)


	  drop table if exists #dates_calendar

 select дата  d into #dates_calendar from Analytics.dbo.v_Calendar
 where дата between getdate()-14 and cast(getdate()  as date)
 ;
 drop table if exists #rez
  
 ;
 with v as (

 select [creationdate] 
 ,CompanyNaumen
 ,[Канал от источника]
 ,[Группа каналов]
 , is_inst_lead
 , IsInstallment
 , [FedorДатаЛида] [Дата лида]
 , [ДатаЗаявкиПолная] [Дата Заявки]
 ,[СтатусЛидаФедор] [Статус лида]
 ,[ФлагОтправленВМП]  [Отправлен в МП]
 , id 
 , source uf_source
 , [uf_partner_id аналитический]
 ,  [ВремяПервойПопытки]
 , [ВремяПервогоДозвона]
 , isPdl
  from v_lead2

 )

 select crd_d,  end_t, [Группа каналов], [Канал от источника]
 , is_inst_lead
 ,IsInstallment
 ,CompanyNaumen
 , count(creationdate) [Поступило лидов]
 , COUNT(ВремяПервойПопытки) [Обработано лидов]
 , COUNT(ВремяПервогоДозвона) [Дозвонились]
 , COUNT(FedorДатаЛида) [Лидов Feodor]
 , COUNT(FedorДатаПрофильногоЛида) [Профильных лидов Feodor]
 , COUNT([Дата Заявки]) [Создано заявок]
 , uf_source
 , [uf_partner_id аналитический]
 , isPdl

 into #rez 
 
 from (
 select  cast(c.creationdate as date) crd_d
 
 ,  id
 ,  creationdate
 , case when cast(ВремяПервойПопытки        as date)= cast(c.creationdate as date) and cast(ВремяПервойПопытки          as time)<=b.h then ВремяПервойПопытки       end  ВремяПервойПопытки         
 , case when cast(ВремяПервогоДозвона		as date)= cast(c.creationdate as date) and cast(ВремяПервогоДозвона		    as time)<=b.h then ВремяПервогоДозвона		end  ВремяПервогоДозвона		
  ,case when cast([Дата лида]				as date)= cast(c.creationdate as date) and cast([Дата лида]				as time)<=b.h then [Дата лида]			end FedorДатаЛида				
  ,case when cast([Дата лида]				as date)= cast(c.creationdate as date) and cast([Дата лида]				as time)<=b.h and  ([Статус лида] in ('Отправлен в ЛКК','Отправлен в МП', 'Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/) or [Отправлен в МП]=1) then [Дата лида]			end FedorДатаПрофильногоЛида				
 , case when cast([Дата Заявки]			as date)= cast(c.creationdate as date) and cast([Дата Заявки] 			as time)<=b.h then [Дата Заявки]			end  [Дата Заявки]			


 , b.h  end_t
 , [Группа каналов]
 , [Канал от источника]
 , CompanyNaumen
 , is_inst_lead
 , IsInstallment
 , uf_source
 , [uf_partner_id аналитический]
 , isPdl
 from #hours_of_day  b 
 cross join #dates_calendar  d
 left join  v--#lh
 c --with(nolock) 
 on cast(c.creationdate as date)= cast(d.d as date) and cast( c.creationdate as time) < b.h
   where --cast(c.creationdate as date)>=cast(getdate()-2 as date) and
 --and [Канал от источника]<>'cpa нецелевой'
 --order by a.h, b.h, c.creationdate
   cast(d.d  as datetime) + cast(b.h  as datetime)<getdate()

-- and id=525324345
) x
group by crd_d,  end_t, [Группа каналов], [Канал от источника], is_inst_lead,IsInstallment ,CompanyNaumen, [uf_partner_id аналитический], uf_source	  , isPdl
order by crd_d,  end_t, [Группа каналов], [Канал от источника], is_inst_lead,IsInstallment ,CompanyNaumen, [uf_partner_id аналитический], uf_source	  , isPdl
 --order by a.h, b.h, c.creationdate

begin tran
 



delete a from  feodor.dbo.dm_leads_history_by_hours a
left join #rez b on a.crd_d=b.crd_d
where b.crd_d is not null or a.crd_d<getdate()-14
 
INSERT feodor.dbo.dm_leads_history_by_hours
(
    crd_d,
    end_t,
    [Группа каналов],
    [Канал от источника],
    is_inst_lead,
    IsInstallment,
    CompanyNaumen,
    [Поступило лидов],
    [Обработано лидов],
    Дозвонились,
    [Лидов Feodor],
    [Профильных лидов Feodor],
    [Создано заявок]
	,
	uf_source
	,	[uf_partner_id аналитический]
	,	isPdl
)
SELECT 
	crd_d,
    end_t,
    [Группа каналов],
    [Канал от источника],
    is_inst_lead,
    IsInstallment,
    CompanyNaumen,
    [Поступило лидов],
    [Обработано лидов],
    Дозвонились,
    [Лидов Feodor],
    [Профильных лидов Feodor],
    [Создано заявок] ,
	uf_source,
	[uf_partner_id аналитический]					,
	isPdl
--INTO feodor.dbo.dm_leads_history_by_hours
from #rez




commit tran


exec [sp_birs_update] '1441C0DE-8643-4128-AD6C-7902CCF32505'
	 



end
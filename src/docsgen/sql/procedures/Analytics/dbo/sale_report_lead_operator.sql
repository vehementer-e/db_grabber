CREATE   proc  [dbo].[sale_report_lead_operator]
@datefrom date,
@dateto date
as
begin
 --exec [_birs].[lead_operator_stat] '20240501' , '20240503'
--declare @datefrom date =  getdate()-1 declare @dateto date =  getdate()


drop table if exists #zayvki

   select fa.Номер,
	fa.[Место создания] [Место cоздания],
	fa.[Верификация КЦ],
	fa.[Предварительное одобрение],
	fa.[Контроль данных],
	fa.Одобрено,
	fa.[Заем выдан],
	fa.[Заем аннулирован],
	fa.[Отказ документов клиента],
	fa.[Отказ клиента],
	fa.Отказано,
	fa.[LCRM ID],
productType	,
original_lead_id
into #zayvki
from v_fa fa
 
where ДатаЗаявкиПолная >= @datefrom


drop table if exists #zayvki_lf

   select fa.Номер,
	fa.[Место cоздания],
	fa.[Верификация КЦ],
	fa.[Предварительное одобрение],
	fa.[Контроль данных],
	fa.Одобрено,
	fa.[Заем выдан],
	fa.[Заем аннулирован],
	fa.[Отказ документов клиента],
	fa.[Отказ клиента],
	fa.Отказано,
	isnull(r.original_lead_id,  fa.[LCRM ID]) 	 [LCRM ID], 
productType  productType
into #zayvki_lf
from  #zayvki fa
left join stg._lf.request r on r.number=fa.Номер
 
--where ДатаЗаявкиПолная >= @datefrom



		--exec select_table 'Reports.dbo.dm_Factor_Analysis_001'
--declare @datefrom date = '20221225'

drop table if exists #leads2

select  lead_id id,	
	[Дата лида]	,
	[Статус лида],
	[Причина непрофильности],
	[Последний сотрудник],
	[Результат коммуникации] ,
	Комментарий
into #leads2
from  Analytics.dbo.v_feodor_leads f --(nolock) 	
where cast([Дата лида] as date) between @datefrom and @dateto	   and id is  null
--where [Дата лида] >= @datefrom

-- insert into #leads2
--select  id,	
--	[Дата лида]	,
--	[Статус лида],
--	[Причина непрофильности],
--	[Последний сотрудник],
--	[Результат коммуникации] ,
--	Комментарий
 
--from  Analytics.dbo.v_feodor_leads f --(nolock) 	
--where cast([Дата лида] as date) between @datefrom and @dateto	   and id is not  null
----where [Дата лида] >= @datefrom


 drop table if exists #leads

 
drop table if exists #u
select distinct DomainLogin collate  Cyrillic_General_CI_AS DomainLogin , u.lastName +' '+u.firstname+' '+u.middlename  collate  Cyrillic_General_CI_AS title into #u from [Stg].[_fedor].[core_user] u


--select  l.id,	
--	f.ДатаЛидаЛСРМ,
--	f.UF_PHONE,
--	l.[Статус лида] СтатусЛидаФедор,
--	f.[Группа каналов],
--	f.[Канал от источника],
--	f.projecttitle,
--	u.title  title,			  -- l.[Последний сотрудник]
--	f.UF_RC_REJECT_CM,
--	l.[Причина непрофильности] ПричинаНепрофильности,
--	f.is_inst_lead,
--	f.UF_SOURCE,
--	[Дата лида] ВремяПервогоДозвона	,
--	  l.[Результат коммуникации],
--	l.Комментарий
--into #leads
--from [Feodor].[dbo].[dm_leads_history]  f	
--join #leads2 l on f.id=l.id	 and  isnumeric(l.id)=1
--left join #u  u on u.domainlogin      =l.[Последний сотрудник] 
--					--select * from stg.[_fedor].[core_user]   				 
--					--select * from  NaumenDbReport.dbo.mv_employee   			
--					where 1=0

drop table if exists #leads

CREATE TABLE  #leads
(
      [id] [NVARCHAR](64)
    , [ДатаЛидаЛСРМ] [DATE]
    , [UF_PHONE] [NVARCHAR](36)
    , [СтатусЛидаФедор] [NVARCHAR](255)
    , [Группа каналов] [NVARCHAR](255)
    , [Канал от источника] [NVARCHAR](255)
    , [projecttitle] [NVARCHAR](4000)
    , [title] [NVARCHAR](767)
    , [UF_RC_REJECT_CM] [NVARCHAR](244)
    , [ПричинаНепрофильности] [NVARCHAR](255)
    , [is_inst_lead] [TINYINT]
    , [UF_SOURCE] [NVARCHAR](128)
    , [ВремяПервогоДозвона] [DATETIME]
    , [Результат коммуникации] [NVARCHAR](255)
    , [Комментарий] [NVARCHAR](MAX)
);

					
insert into #leads

select  l.id,	
	f.ДатаЛидаЛСРМ,
	f.UF_PHONE,
	l.[Статус лида] СтатусЛидаФедор,
	f.[Группа каналов],
	f.[Канал от источника],
	f.projecttitle,
	u.title  title,			  -- l.[Последний сотрудник]
	f.UF_RC_REJECT_CM,
	l.[Причина непрофильности] ПричинаНепрофильности,
	f.is_inst_lead,
	f.UF_SOURCE,
	[Дата лида] ВремяПервогоДозвона	,
	  l.[Результат коммуникации],
	l.Комментарий
from [Feodor].[dbo].lead  f	 with(nolock)
join #leads2 l on f.id=l.id	 and  isnumeric(l.id)=0
left join #u  u on u.domainlogin      =l.[Последний сотрудник] 
					--select * from stg.[_fedor].[core_user]   				 
					--select * from  NaumenDbReport.dbo.mv_employee   





drop table if exists #que

select distinct cast([id lcrm] as nvarchar(36)) collate Cyrillic_General_CI_AS id, answer
into #que			 --select top 100 *
from [Feodor].[dbo].[dm_LeadAndSurvey] q
--join #leads l on l.id = cast(q.[id lcrm] as numeric(10)) 
where  Question = 'Installment Продолжить оформление под installment?' --and ISNUMERIC([id lcrm]) = 1
and  cast([Дата лида] as date) between @datefrom and @dateto
			
			


drop table if exists #que2

select distinct cast([id lcrm] as nvarchar(36)) collate Cyrillic_General_CI_AS id, answer
into #que2			 --select top 100 *
from [Feodor].[dbo].[dm_LeadAndSurvey] q
--join #leads l on l.id = cast(q.[id lcrm] as numeric(10)) 
where  Question = 'BigInstallmentGPB Хочешь завести заявку?' --and ISNUMERIC([id lcrm]) = 1
and  cast([Дата лида] as date) between @datefrom and @dateto
							

--select * from #que
--order by 2

SELECT f.id,	
	ДатаЛидаЛСРМ,
	UF_PHONE,
	СтатусЛидаФедор,
	[Результат коммуникации],
	f.[Группа каналов],
	f.[Канал от источника],
	projecttitle,
	title,
	UF_RC_REJECT_CM,
	ПричинаНепрофильности,
	fa.Номер,
	fa.[Место cоздания],
	fa.[Верификация КЦ],
	fa.[Предварительное одобрение],
	fa.[Контроль данных],
	fa.Одобрено,
	fa.[Заем выдан],
	fa.[Заем аннулирован],
	fa.[Отказ документов клиента],
	fa.[Отказ клиента],
	fa.Отказано,
	f.is_inst_lead,
	f.UF_SOURCE,
fa.producttype,
f.ВремяПервогоДозвона,
case
	when left(q.answer, 3) = 'PDL' then 'PDL'
	when left(q.answer, 11) = 'installment' then 'Inst'
	when q.answer = 'Да' then 'Inst'
	when q.answer = 'Нет' then '0'
	when q.answer = 'Оформление не продолжаем' then '0'
	else 'Вопрос отсутствует'
end 'Признак переход на инст'		  ,
	Комментарий,
	q2.answer [Ветка BIG INST]


  FROM #leads f	
  left join #zayvki_lf fa on fa.[lcrm id] = f.id	
  left join #que q on q.id = f.ID
  left join #que2 q2 on q2.id = f.ID

  end
-- =============================================
-- Modified: 12.03.2022. А.Никитин
-- Description:	DWH-1590. Отказ от Stg._LCRM.lcrm_tbl_short_w_channel, Stg.dbo.lcrm_tbl_full_w_chanals2
-- =============================================
CREATE PROC [dbo].[create_dm_leads_history_online_current_day]
as
begin
declare @await_job int	=0 

if not exists (
select  top 1 1 d, * from analytics.dbo.jobh
where job_id='1B076C1B-19C3-43D1-98BD-D7AC527EA558' and is_today_run=1 and is_succeeded	=1	and datepart(hour, Finish_DateAndTime)>=6
--exec analytics.dbo.Запросы 	 '1B076C1B-19C3-43D1-98BD-D7AC527EA558'
   )	  and not	exists (select top 1 1 d from analytics.dbo.[v_Запущенные джобы] where job_name='temp analytics job 2')

begin
set @await_job=1
EXEC msdb.dbo.sp_start_job 'temp analytics job 2'

end





--select getdate() dt, cast('test' as nvarchar(max)) text into [create_dm_leads_history_online_current_day_logging]


declare @start_dt datetime = getdate()



drop table if exists #t1_cc
select uuid uuid
,projectuuid projectuuid
,phonenumbers phonenumbers
,projecttitle projecttitle
,creationdate creationdate
,timezone timezone
--,attempt_start attempt_start
--,session_id session_id
--,login login

into #t1_cc
from openquery(naumen,'      
SELECT 
 cc.uuid    
,cc.projectuuid     
,cc.phonenumbers     
,cc.projecttitle     
,cc.creationdate    
,cc.timezone    
--,dos.attempt_start
--,dos.session_id
--,dos.login


FROM report_db.public.mv_call_case cc
--left join report_db.public.detail_outbound_sessions dos on cc.uuid=dos.case_uuid

where cc.creationdate>=CURRENT_DATE-1 ')  


drop table if exists #t1_dos
select

 case_uuid           case_uuid 
,attempt_start		 attempt_start
,session_id			 session_id
,login				 login
,attempt_end				 attempt_end
,attempt_result				 attempt_result



into #t1_dos
from openquery(naumen,'      
SELECT 
 dos.case_uuid 
,dos.attempt_start
,dos.attempt_result
,dos.attempt_end
,dos.session_id
,dos.login


FROM  report_db.public.detail_outbound_sessions dos 

where dos.attempt_start>=CURRENT_DATE-1 ')  


drop table if exists #t1

SELECT 
 cc.uuid    
,cc.projectuuid     
,cc.phonenumbers     
,cc.projecttitle     
,cc.creationdate    
,cc.timezone    
,dos.attempt_start
,dos.attempt_result
,dos.attempt_end
,dos.session_id
,dos.login
into #t1

FROM #t1_cc cc
left join #t1_dos dos on cc.uuid=dos.case_uuid



--drop table if exists #t1
--select uuid uuid
--,projectuuid projectuuid
--,phonenumbers phonenumbers
--,projecttitle projecttitle
--,creationdate creationdate
--,attempt_start attempt_start
--,session_id session_id
--,login login
--
--into #t1
--from openquery(naumen,'      
--SELECT 
-- cc.uuid    
--,cc.projectuuid     
--,cc.phonenumbers     
--,cc.projecttitle     
--,cc.creationdate    
--,dos.attempt_start
--,dos.session_id
--,dos.login
--
--
--FROM report_db.public.mv_call_case cc
--left join report_db.public.detail_outbound_sessions dos on cc.uuid=dos.case_uuid
--
--where cc.creationdate>=CURRENT_DATE ')  
--


;   
 declare @call_case_and_sessions datetime = getdate()


drop table if exists #t2
select owneruuid owneruuid
,      jsondata  jsondata 
into #t2
from openquery(naumen,'      
SELECT 
 cc.owneruuid    
,cast(jsondata as varchar(2048)) as jsondata

FROM report_db.public.mv_custom_form cc

where cc.creationdate>=CURRENT_DATE-1 ')



 declare @custom_form datetime = getdate()


drop table if exists #l
select id         id
,      idexternal idexternal
,      phone    collate  Cyrillic_General_CI_AS  phone
,      createdon  createdon
,      idStatus   idStatus into #l
from [PRODSQL02].[Fedor.Core].[core].[Lead]
where dateadd(hour, 3, createdon)>=cast(getdate()-1 as date)




drop table if exists #inst_product
SELECT   a.idLead idLead		 , max(case when
[key] in (
 'PDL Цель займа'
,'PDL Сколько Вам полных лет?'
,'PDL Хочешь завести заявку?'
,'PDL Выбор места оформления заявки'
)	then 1
when [key] = 'Installment Продолжить оформление под installment?' and left(value, 3)='pdl' then 1 else 0 end 

)	isPdl
into #inst_product 
  FROM [PRODSQL02].[Fedor.Core].[core].[LeadAndSurvey] a join #l l on a.idLead=l.id 
--and dateadd(hour, 3, l.createdon)>=cast(getdate() as date)
   outer apply  OPENJSON([SurveyData], '$')
   where isJSON([SurveyData])=1 and [key] in  (
 'Installment Цель займа'
,'PDL Цель займа'
,'Installment Продолжить оформление под installment?'
,'Installment Даете согласие на обработку персональных данных?'
,'Installment Оформляем заявку с кл по телефону?'
,'Installment Сколько Вам полных лет?'
,'PDL Сколько Вам полных лет?'
,'Installment Хочешь завести заявку?'
,'PDL Хочешь завести заявку?'
,'PDL Выбор места оформления заявки'
)

group by idLead




drop table if exists #lc
select [IdLead] [IdLead]
,      IdLeadCommunicationResult IdLeadCommunicationResult

into #lc
from [PRODSQL02].[Fedor.Core].[core].[LeadCommunication]
where dateadd(hour, 3, createdon)>=cast(getdate()-1 as date)


--select * from stg._fedor.core_LeadCommunication
--exec Analytics.dbo.generate_select_table_script 'stg._fedor.core_LeadCommunication'

drop table if exists #toMP
select [IdLead], max(case when IdLeadCommunicationResult=11 then 1 else 0 end) [istoMP] into #toMP from #lc group by [IdLead]
--
--drop table if exists #zay
--
--select Номер, cast(Инстолмент  as int)   Инстолмент into #zay
--from stg.[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] 
--
 declare @leads datetime = getdate()

drop table if exists #r
select number  collate  Cyrillic_General_CI_AS   number
,      ClientPhoneMobile collate  Cyrillic_General_CI_AS   ClientPhoneMobile
,      idlead   idlead
,      dateadd(hour, 3, createdon) createdon
,      case when cr.type in (2,4, 5) then 1 else 0  end isInstallment
,      case when cr.type in (  5) then 1 else 0  end isPdl

into #r
from [PRODSQL02].[Fedor.Core].[core].[ClientRequest] cr
-- join #zay b on try_cast(cr.number as bigint)=try_cast(b.Номер as bigint) --and dateadd(year, -2000, b.Дата)>='20221123'

where  dateadd(hour, 3, createdon)>=cast(getdate()-1 as date)

delete a from 	 #r a
left join Analytics.dbo.v_request b on a.number=b.НомерЗаявки
where isnull(b.[Предварительное одобрение] , b.Отказано) is null

--insert into   #r
--
--select 	 НомерЗаявки, Телефон, original, ДатаЗаявки , 1-ispts , ispdl from 
--
--Analytics.dbo.v_request	 a
--left join 
--Analytics.dbo.v_request_lf	 b	  on a.НомерЗаявки=b.number
--where  a.ДатаЗаявки	>=cast(getdate()-1 as date)	 and  isnull(a.[Предварительное одобрение] , a.Отказано) is not null 



 declare @requests datetime = getdate()
 --select * from #r
 --order by 1


 drop table if exists #l_r
select l.id, isnull(r.number, x.number) number--, x.number [Заявка]

into #l_r

from #l  l
left join #r r on l.id=r.idlead
outer apply (
select top 1 
* 
from #r b 
where 
l.Phone=b.ClientPhoneMobile 
and b.CreatedOn between dateadd(hour, 3, l.CreatedOn) and  dateadd(day, 1,  dateadd(hour, 3, l.CreatedOn) )
and l.IdStatus=9
and r.number is null
and 1=0
order by r.CreatedOn

) x
 

 



drop table if exists #s
select id   id
,      name name 
into #s
from [PRODSQL02].[Fedor.Core].[dictionary].[LeadStatus]

 declare @lead_status datetime = getdate()

 



-- select * from #t2

drop table if exists #lcrm_id_case;

with v as (select owneruuid, isnull( isnull(lcrm_id, lead_id) , crm.original_lead_id) lcrm_id, ROW_NUMBER() over(partition by owneruuid order by (select null)) rn from #t2	 a
left join Analytics.dbo.lead_case_crm crm on crm.uuid=a.owneruuid	  and crm.case_after_call1 =0
outer   apply openjson(jsondata,'$.group001')
          with(
          lcrm_id   nvarchar(50)        '$.lcrm_id'	 ,
          lead_id   nvarchar(36)        '$.lead_id'	  

          )  q
)


select * into #lcrm_id_case from #t1
join  v on #t1.uuid=v.owneruuid and v.rn=1 and v.lcrm_id is not null

 declare @json datetime = getdate()

drop table if exists  #ch_today

 select 
 	   f.uuid,	
	f.creationdate creationdate,	
	f.phonenumbers,	
	--f.statetitle,	
	f.projectuuid,	
	f.projecttitle,	
	f.lcrm_id,	
--	f.speaking_time,	
	f.attempt_result,	
	f.attempt_start,		   
	f.session_id,
	f.login	  ,
	f.timezone	  
	,f.attempt_end
	into #ch_today
  from 
  #lcrm_id_case	 f
  where isnumeric(f.lcrm_id)=1



  --drop table if exists dm_calls_history_current_day
  --select * into dm_calls_history_current_day from #ch_today
  delete from dm_calls_history_current_day    
  insert into dm_calls_history_current_day
  select * from #ch_today

if not exists  (select * from Analytics.dbo.[v_Запущенные джобы] where job_name='Analytics._birs TTC звонки'  )
exec msdb.dbo.sp_start_job	  'Analytics._birs TTC звонки'



  --select * from 	  dm_calls_history_current_day
  --order by 8
  


--select * from  #lcrm_id_case left join stg._LCRM.lcrm_tbl_short_w_channel st on try_cast(#lcrm_id_case.lcrm_id as numeric)=st.ID 




drop table if exists #Lead


select   
       [ID лида Fedor]                         =  l.[Id]
     , [ID LCRM]	                             =  l.[IdExternal]  collate  Cyrillic_General_CI_AS
     , [Номер заявки (договор)]                =  r.Number         collate  Cyrillic_General_CI_AS
     , [Дата лида]                             =	dateadd(hour, 3, l.[CreatedOn])
     , [Дата Заявки]                             =	 r.[CreatedOn]
     , [Месяц лида]	                           =  month(l.[CreatedOn])
     , [Статус лида]	                         =  s.[Name]                collate  Cyrillic_General_CI_AS
     , [Номер  телефона]                       =	l.[Phone]    collate  Cyrillic_General_CI_AS
	 , [Отправлен в МП]                       = case when l.idStatus = 10 or isnull(toMP.istoMP, 0) =1 then 1 else 0 end
	 , isInstallment                        = case when r.isInstallment is not null then r.isInstallment 
	                                                 when inst_product.idLead is not null then 1
													 else 0 end	 
	 , isPdl                      = case when r.isPdl =1 then 1
	                                                 when inst_product.isPdl=1 then 1
													 else 0 end
   , case when toMP.IdLead is not null then 1 end has_call
	 into #lead
  
 from #l l
      left join  #l_r  l_r on l_r.id=l.id
      left join  #r  r on r.number=l_r.number
      left join #s   s on s.id=l.idStatus
      left join #toMP   toMP on toMP.IdLead=l.id
      left join #inst_product   inst_product on inst_product.idLead=l.id


insert into #Lead
select a.[ID лида Fedor]                
,      a.[ID LCRM]                      
,      a.[Номер заявки (договор)]       
,    dateadd(hour, 3,   a.[Дата лида]) [Дата лида]
,      a.[Дата заявки]                  
,      a.[Месяц лида]                   
,      a.[Статус лида]                  
,      a.[Номер  телефона]              
,      a.[Флаг отправлен в МП]          
,      a.IsInstallment                  
,      a.isPdl      
, case when [id проекта naumen] is not null then 1 end 
from Feodor.dbo.dm_Lead a
--left join #lead b on a.[ID LCRM]=b.[ID LCRM]

where a.[Дата лида]>=cast(getdate()-1 as date)


;with v  as (select *, row_number() over(partition by [ID LCRM] order by [Номер заявки (договор)] desc, [Дата лида] desc ) rn from #Lead ) delete from v where rn>1


	  create clustered index i_id_lcrm on #lcrm_id_case (lcrm_id)

drop table if exists #lcrm_id_case_windowed

--declare @start_dt datetime = getdate()

	  ;
	--  with lcrm_id_case_windowed as (

      select lcrm_id lcrm_id
	     , projectuuid projectuuid
	     , phonenumbers phonenumbers
		 , projecttitle projecttitle
		 , min(creationdate) over(partition by lcrm_id)  creationdate
		 , min(attempt_start) over(partition by lcrm_id)  ВремяПервойПопытки
		 , min(case when login is not null then attempt_start end) over(partition by lcrm_id)  ВремяПервогоДозвона
		 , case when count(attempt_start) over(partition by lcrm_id) > 0 then 1 else 0 end ФлагЛидОбраблотан
		 , count(attempt_start) over(partition by lcrm_id) ЧислоПопыток
		 , count(case when login is not null then attempt_start end) over(partition by lcrm_id) ЧислоДозвонов
	  ,sign(count(case when [login] is not null then attempt_start end) over (partition by lcrm_id))  [ФлагДозвонПоЛиду]
		 , row_number() over(partition by lcrm_id order by creationdate) rn
		 , uuid
		 , session_id
	  into #lcrm_id_case_windowed
	  from #lcrm_id_case
	--  )--,
	   
CREATE INDEX ix_lcrm_id ON #lcrm_id_case_windowed(lcrm_id)



	    drop table if exists #loginom

		

  create table #loginom
  (
  
Phone	nvarchar(1000)
,call_date	datetime
,Channel_source	nvarchar(1000)
,Channel_group	nvarchar(1000)
,LCRM_ID	nvarchar(50)
,[UF_SOURCE]	nvarchar(500)
,[UF_TYPE]	nvarchar(500)
,[UF_PARTNER_ID]	nvarchar(500)

  )

--DWH-2249 Заменить использование данных с phone_check_24h на phone_check
/*
  insert into #loginom
SELECT 
      [Phone] [Phone]
   ,call_date call_date
      ,case  when [Channel_source] ='Другое' then 'Канал привлечения не определен - КЦ' else [Channel_source] end  [Channel_source] 
      ,case  when [Channel_group]  ='Другое' then 'Органика'                            else [Channel_group]  end  [Channel_group]  
	  ,try_cast([LCRM_ID] as nvarchar(50)) [LCRM_ID]
	  ,[UF_SOURCE]
	  ,[UF_TYPE]
	  ,[UF_PARTNER_ID]
	 -- into #loginom
	-- select * 
  FROM [Stg].[_loginom].[phone_check_24h]
--  where Decision='Accept' and (try_cast(long_form as nvarchar)<>'1' or try_cast(long_form as nvarchar) is null)
*/


INSERT INTO #loginom
SELECT 
	P.[Phone] [Phone]
	,P.call_date call_date
	,case  
		WHEN P.[Channel_source] ='Другое' then 'Канал привлечения не определен - КЦ' 
		ELSE P.[Channel_source] 
	 END  [Channel_source] 
	,CASE
		WHEN P.[Channel_group] = 'Другое' then 'Органика'
		ELSE [Channel_group]  
	 END [Channel_group]
	,try_cast(P.[LCRM_ID] as nvarchar(50)) [LCRM_ID]
	,P.[UF_SOURCE]
	,P.[UF_TYPE]
	,P.[UF_PARTNER_ID]
FROM #lcrm_id_case_windowed AS n
	INNER JOIN Stg._loginom.phone_check AS P
		ON n.lcrm_id = P.LCRM_ID	   and isnumeric(n.lcrm_id)	=1
 where 1=0

INSERT INTO #loginom   
SELECT 
	P1.[Phone] [Phone]
	,  p1.created_at_time  call_date
	,case  
		WHEN ch.name ='Другое' then 'Канал привлечения не определен - КЦ' 
		ELSE  ch.name 								 
	 END  [Channel_source] 
	,CASE
		WHEN gr.name = 'Другое' then 'Органика'
		ELSE  gr.name       
	 END [Channel_group]
	,n.lcrm_id [LCRM_ID]
	, s.source 	[UF_SOURCE]
	, P1.type_code		 	[UF_TYPE]
	, P1.[PARTNER_ID]	 	 [UF_PARTNER_ID]
FROM #lcrm_id_case_windowed AS n														 
	 JOIN Stg._lf.lead AS P1 on p1.id=n.lcrm_id		--and isnumeric(n.lcrm_id)=0
	left join stg._LF.mms_channel ch	on ch.id=P1.mms_channel_id
	left join stg._LF.mms_channel_group  gr on gr.id=P1.mms_channel_group_id
	left join analytics.dbo.v_source s on s.id=p1.source_id




--  
--  ;
-- with  log_ch
-- as
-- (
-- select phone, #loginom.Channel_group, #loginom.Channel_source , ROW_NUMBER() over(partition by [Phone] order by call_date desc) rn from #loginom
-- )
-- delete from log_ch where rn>1
--  
--   ;
  
  --select * from #lcrm_id_case_windowed
  --where 
  



delete from #lcrm_id_case_windowed where rn>1	  
--declare @start_dt datetime = getdate()

drop table if exists #final

	  select 
	  n.lcrm_id,
	  n.projectuuid,
	  n.projecttitle,
	  n.creationdate,
	  n.ВремяПервойПопытки,
	  n.ВремяПервогоДозвона,
	  n.ФлагЛидОбраблотан,
	  n.ЧислоПопыток,
	  n.ЧислоДозвонов,
	  n.ФлагДозвонПоЛиду
      ,fp.LaunchControlName CompanyNaumen

	  , l.[ID LCRM]
	  , l.[ID лида Fedor]
	  , l.[Дата Заявки]
	  , l.[Дата лида]
	  , l.[Номер  телефона]
	  , l.[Номер заявки (договор)]
	  , l.[Статус лида]
	  , l.[Отправлен в МП]

      --DWH-1590.
	  --, 
	  --isnull(isnull(isnull( st.[Канал от источника] ,ft.[Канал от источника]) , #loginom.Channel_source) , case when projectuuid in ('corebo00000000000mqpsrh9u28s16g8', 'corebo00000000000n35ltu7n0jje82k', 'corebo00000000000n8i9hcja56hji2o', 'corebo00000000000nhc39ilthenudg4') then 'CPA нецелевой' else 'unknown' end ) [Канал от источника], 
	  --isnull(isnull(isnull( st.[Группа каналов]    ,ft.[Группа каналов]) , #loginom.Channel_group) , case when projectuuid in ('corebo00000000000mqpsrh9u28s16g8', 'corebo00000000000n35ltu7n0jje82k', 'corebo00000000000n8i9hcja56hji2o', 'corebo00000000000nhc39ilthenudg4') then 'CPA' else 'unknown' end ) [Группа каналов]
	  --, isnull(st.UF_REGISTERED_AT , ft.UF_REGISTERED_AT ) UF_REGISTERED_AT
	  , [Канал от источника] = 
		isnull(
			isnull(C.[Канал от источника], #loginom.Channel_source), 
			--CASE 
			--	WHEN projectuuid in ('corebo00000000000mqpsrh9u28s16g8', 'corebo00000000000n35ltu7n0jje82k', 'corebo00000000000n8i9hcja56hji2o', 'corebo00000000000nhc39ilthenudg4') 
			--		THEN 'CPA нецелевой' 
			--	ELSE 
				--'Канал привлечения не определен - КЦ' )
				'unknown' )
			--END 
		--)
	  ,  [Группа каналов] = 
		isnull(
			isnull(C.[Группа каналов], #loginom.Channel_group), 
		--	CASE 
		--		WHEN projectuuid in ('corebo00000000000mqpsrh9u28s16g8', 'corebo00000000000n35ltu7n0jje82k', 'corebo00000000000n8i9hcja56hji2o', 'corebo00000000000nhc39ilthenudg4') 
		--			THEN 'CPA' 
		--		ELSE
		--'Органика' 
		'unknown' 
		--	END 
		)
	  , isnull(C.UF_REGISTERED_AT, #loginom.call_date)	  UF_REGISTERED_AT

	  , getdate() as created
	  , @start_dt as start_date
	  ,isnull(isInstallment, Analytics.dbo.[lcrm_is_inst_lead](isnull(c.UF_TYPE,  #loginom.UF_TYPE), isnull(c.UF_SOURCE,  #loginom.UF_SOURCE), null )) isInstallment
	  ,isnull(c.UF_SOURCE,  #loginom.UF_SOURCE) UF_SOURCE
	  ,isnull(c.UF_TYPE,  #loginom.UF_TYPE) UF_TYPE
	  , Analytics.dbo.[lcrm_is_inst_lead](isnull(c.UF_TYPE,  #loginom.UF_TYPE), isnull(c.UF_SOURCE,  #loginom.UF_SOURCE), null ) is_inst_lead
	  , [UF_PARTNER_ID аналитический] = case when Analytics.[dbo].[lcrm_признак_корректного_заполнения_вебмастера](isnull(c.UF_SOURCE,  #loginom.UF_SOURCE), getdate())=1 then [UF_PARTNER_ID] end 
 ,case when [Статус лида] in ('Отправлен в ЛКК','Отправлен в МП','Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/)  or [Отправлен в МП]=1 then 1 end as Профильный
 , isnull(l.isPdl, 0) isPdl
 , n.uuid
 , l.has_call
 ,  case when n.session_id is not null then 1 end [has_attempt]
	  into #final
	  from 
	  #lcrm_id_case_windowed n 
	  left join #lead l on n.lcrm_id= l.[ID LCRM] 

      --DWH-1590.
	  --left join stg._LCRM.lcrm_tbl_short_w_channel st on n.lcrm_id=st.ID
	  --left join stg.dbo.lcrm_tbl_full_w_chanals2 ft on n.lcrm_id=ft.ID
	  LEFT JOIN Stg._LCRM.lcrm_leads_full_calculated AS C with(nolock)
		ON try_cast(n.lcrm_id as numeric)= C.ID

	  left join Feodor.dbo.dm_feodor_projects fp on fp.IdExternal=n.projectuuid
	  --left join #login#loginomom on stuff(#loginom.Phone, 1,1,'')=stuff(n.phonenumbers, 1,1,'') 
	  left join #loginom on #loginom.LCRM_ID=n.lcrm_id
	  where --n.rn=1 and 
	  creationdate<=cast(format(@start_dt, 'yyyy-MM-dd HH:00:00') as datetime)
	--order by ФлагДозвонПоЛиду, [ID лида Fedor]
	--and isnumeric(n.lcrm_id )=1
	


	 declare @tmp_tables datetime = getdate()


	 --select * from stg.files.leadref1_buffer_stg
	 --select * from #final
	 --order by creationdate

	-- select * from #lcrm_id_case n
	-- 	  left join stg.dbo.lcrm_tbl_full_w_chanals2 ft on n.lcrm_id=ft.ID
	--	  	  left join stg._LCRM.lcrm_tbl_short_w_channel st on n.lcrm_id=st.ID

	
	;

	with v as (
	select *, row_number() over(partition by lcrm_id order by (select 1) )  rn
	from 
	#final
	)
	delete from v where rn>1

	drop table if exists #lead_insert
	select 
	   [lcrm_id]
      ,[projectuuid]
      ,[projecttitle]
      ,[creationdate]
      ,case when [ВремяПервойПопытки] is null then [Дата лида] else [ВремяПервойПопытки] end [ВремяПервойПопытки]
      ,case when [ВремяПервогоДозвона] is null then [Дата лида] else [ВремяПервогоДозвона] end [ВремяПервогоДозвона]
      ,case when [ВремяПервогоДозвона] is null then case when [Дата лида] is not null then 1 end else [ФлагЛидОбраблотан] end [ФлагЛидОбраблотан]
      ,case when [ЧислоПопыток]=0 and [Дата лида] is not null then 1 else [ЧислоПопыток] end [ЧислоПопыток] 
      ,case when [ЧислоДозвонов]=0 and [Дата лида] is not null then 1 else [ЧислоДозвонов] end [ЧислоДозвонов] 
      ,case when [ВремяПервогоДозвона] is null then case when [Дата лида] is not null then 1 else 0 end else [ФлагДозвонПоЛиду] end [ФлагДозвонПоЛиду]
	  ,first_value(CompanyNaumen) over(partition by [lcrm_id] order by isnull([ВремяПервойПопытки], getdate()+1), [creationdate]  )	 CompanyNaumen
      ,[ID лида Fedor]
      ,[ID LCRM]
      ,[Номер заявки (договор)]
      ,[Дата лида]
      ,[Дата Заявки]
      ,[Статус лида]
      ,[Номер  телефона]
      ,[Группа каналов]
      ,[Канал от источника]
      ,[UF_REGISTERED_AT]
      ,[created]
      ,start_date
      ,[Отправлен в МП]
	  ,isInstallment
	  ,is_inst_lead
	  ,[UF_PARTNER_ID аналитический]
	  , UF_SOURCE
	  , Профильный
	  , UF_TYPE
	  , isPdl
	  , uuid
	  , [has_attempt]
	  , has_call
	  into #lead_insert
	  FROM #final  

	drop table if exists #lead_agr_insert


	 select  [Группа каналов], [Канал от источника], [CompanyNaumen], cast(creationdate as date) ДатаЛидаНАУМЕН,
  count([creationdate]) as ЧислоЛидов,
  count([ВремяПервойПопытки]) as ОбработаноЛидов,
  count([ВремяПервогоДозвона]) as ЛидовСДозвоном,
  sum([ЧислоПопыток]) as СовершеноЗвонков,
  sum([ЧислоДозвонов]) as СовершеноДозвонов,
  count(case when [Статус лида] in ('Непрофильный') then 1 end) as НепрофильныхКлиентов,
  count(case when [Отправлен в МП]=1 then 1 end) as ОтправленоВМП,
  count(case when [Статус лида] in ('Отказ клиента с РСВ', 'Отказ клиента без РСВ') then 1 end) as ОтказовКлиента,
  count(case when [Статус лида] in ('Новый') then 1 end) as СтатусовНовый,
  count(case when [Статус лида] in ('Профильный') then 1 end) as СтатусовПрофильный,
  count(case when [Статус лида] in ('Отправлен в МП','Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/)  or [Отправлен в МП]=1 then 1 end) as ВсегоПрофильных,
  count(case when [Статус лида] in ('Думает')  then 1 end) as СтатусовДумает,
  count(case when [Номер заявки (договор)] is not null  then 1 end) as СозданоЗаявок,
  sum(cast(datediff(minute, creationdate, [ВремяПервойПопытки]) as bigint)) DateDiff$creationdate$ВремяПервойПопытки
  	  ,count(case when [ВремяПервойПопытки] <= dateadd(second, 120, creationdate) then [creationdate] end) [ВремяПервойПопытки_0min_to_2min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 120, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 300 , creationdate) then [creationdate] end) [ВремяПервойПопытки_2min_to_5min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 300, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 1800, creationdate) then [creationdate] end) [ВремяПервойПопытки_5min_to_30min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 1800, creationdate) then [creationdate] end) [ВремяПервойПопытки_30min_and_more]
,
  min(created) as created,
  min(start_date) as start_date
  into #lead_agr_insert
    FROM #lead_insert
	group by [Группа каналов], [CompanyNaumen], cast(creationdate as date) , [Канал от источника]



	
	begin tran
	--drop table if exists feodor.dbo.dm_leads_history_online_current_day
	--DWH-1764
	delete a from dbo.dm_leads_history_online_current_day a join  #final b on a.lcrm_id=b.lcrm_id
	--alter table 
	--feodor.dbo.dm_leads_history_online_current_day
	--add [UF_PARTNER_ID аналитический] nvarchar(500)
	--alter table 
	--feodor.dbo.dm_leads_history_online_current_day
	--add [UF_SOURCE] nvarchar(500)
	--alter table 
	--feodor.dbo.dm_leads_history_online_current_day
	--add Профильный int					 
	--alter table 
	--feodor.dbo.dm_leads_history_online_current_day
	--add uf_type nvarchar(500)
	--alter table 
	--feodor.dbo.dm_leads_history_online_current_day
	--add uuid nvarchar(60)	
	
	--alter table 
	--feodor.dbo.dm_leads_history_online_current_day
	--add [has_attempt] tinyint
	
	--alter table 
	--feodor.dbo.dm_leads_history_online_current_day
	--add [has_call] tinyint




	INSERT feodor.dbo.dm_leads_history_online_current_day
	(
	    lcrm_id,
	    projectuuid,
	    projecttitle,
	    creationdate,
	    ВремяПервойПопытки,
	    ВремяПервогоДозвона,
	    ФлагЛидОбраблотан,
	    ЧислоПопыток,
	    ЧислоДозвонов,
	    ФлагДозвонПоЛиду,
	    CompanyNaumen,
	    [ID лида Fedor],
	    [ID LCRM],
	    [Номер заявки (договор)],
	    [Дата лида],
	    [Дата Заявки],
	    [Статус лида],
	    [Номер  телефона],
	    [Группа каналов],
	    [Канал от источника],
	    UF_REGISTERED_AT,
	    created,
	    start_date,
	    [Отправлен в МП],
	    isInstallment,
	    is_inst_lead,
	    [UF_PARTNER_ID аналитический],
	    UF_SOURCE					  ,
	    Профильный					  ,
	    UF_TYPE		   ,
	    isPdl,
	    uuid	  
	  , [has_attempt]
	  , has_call
	)
  select * from
  #lead_insert



	commit tran

	begin tran
	--drop table if exists feodor.[dbo].[dm_leads_history_online_current_day_cube_by_ДатаЛидаЛСРМ]
	--DWH-1764
	delete a from   dbo.dm_leads_history_online_current_day_cube_by_ДатаЛидаЛСРМ a	join #lead_agr_insert b on a.ДатаЛидаНАУМЕН=b.ДатаЛидаНАУМЕН

  INSERT dbo.dm_leads_history_online_current_day_cube_by_ДатаЛидаЛСРМ
  (
      [Группа каналов],
      [Канал от источника],
      CompanyNaumen,
      ДатаЛидаНАУМЕН,
      ЧислоЛидов,
      ОбработаноЛидов,
      ЛидовСДозвоном,
      СовершеноЗвонков,
      СовершеноДозвонов,
      НепрофильныхКлиентов,
      ОтправленоВМП,
      ОтказовКлиента,
      СтатусовНовый,
      СтатусовПрофильный,
      ВсегоПрофильных,
      СтатусовДумает,
      СозданоЗаявок,
      [DateDiff$creationdate$ВремяПервойПопытки],
      ВремяПервойПопытки_0min_to_2min,
      ВремяПервойПопытки_2min_to_5min,
      ВремяПервойПопытки_5min_to_30min,
      ВремяПервойПопытки_30min_and_more,
      created,
      start_date
  )
  select * from
  #lead_agr_insert
 
	commit tran


	--alter table feodor.dbo.dm_leads_history_online_current_day 
	--add [Отправлен в МП] bit 
	
	--alter table feodor.dbo.dm_leads_history_online_current_day 
	--add isPdl tinyint


 declare @end_dt datetime = getdate()

-- drop table if exists feodor.[dbo].[dm_leads_history_online_current_day_monitoring]
insert into feodor.[dbo].[dm_leads_history_online_current_day_monitoring]

select @start_dt               start_dt
,      @call_case_and_sessions call_case_and_sessions
,      @custom_form            custom_form
,      @leads                  leads
,      @requests               requests
,      @lead_status            lead_status
,      @json                   json
,      @tmp_tables             tmp_tables
,      @end_dt                 end_dt
--into feodor.[dbo].[dm_leads_history_online_current_day_monitoring]
--select * from feodor.[dbo].[dm_leads_history_online_current_day_monitoring] order by 1
--
--
--drop table if exists #groups, #lh_byHour
--select * into #groups from 
--(
--select cast(getdate() as date) d
--) dates,
--(
--SELECT [Канал от источника]
--,      [Группа каналов]
--FROM [Stg].[files].[leadRef1_buffer]
--) ch,
--(
--SELECT distinct [LaunchControlName] 
--FROM [Feodor].[dbo].[dm_feodor_projects] 
--) lc,
--(
--select cast('01:00:00' as time) h union all
--select cast('02:00:00' as time)	union all
--select cast('03:00:00' as time)	union all
--select cast('04:00:00' as time)	union all
--select cast('05:00:00' as time)	union all
--select cast('06:00:00' as time)	union all
--select cast('07:00:00' as time)	union all
--select cast('08:00:00' as time)	union all
--select cast('09:00:00' as time)	union all
--select cast('10:00:00' as time)	union all
--select cast('11:00:00' as time)	union all
--select cast('12:00:00' as time)	union all
--select cast('13:00:00' as time)	union all
--select cast('14:00:00' as time)	union all
--select cast('15:00:00' as time)	union all
--select cast('16:00:00' as time)	union all
--select cast('17:00:00' as time)	union all
--select cast('18:00:00' as time)	union all
--select cast('19:00:00' as time)	union all
--select cast('20:00:00' as time)	union all
--select cast('21:00:00' as time)	union all
--select cast('22:00:00' as time)	union all
--select cast('23:00:00' as time)
--) hours
--
--
--
--
--
--select #groups.d 
--      ,#groups.h		
--      ,#groups.[LaunchControlName]		
--      ,#groups.[Канал от источника]		
--      ,#groups.[Группа каналов]		
--	  ,count(case when lh.creationdate between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) ПоступилоЛидов
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and lh.creationdate between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) ПоступилоЛидов_После9
--	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ОбработаноЛидов
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ОбработаноЛидов_После9
--	  ,count(case when ВремяПервогоДозвона between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ДозвонилисьДоЛидов
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервогоДозвона between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ДозвонилисьДоЛидов_После9
--	  ,count(case when lh.[Дата лида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЛидовФедор
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and lh.[Дата лида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЛидовФедор_После9
--	  ,count(case when lh.[Дата лида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [Статус лида] in ('Отправлен в МП', 'Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка', 'Думает')  then 1 end end) as СозданоПрофильныхЛидовФедор
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and lh.[Дата лида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [Статус лида] in ('Отправлен в МП','Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка', 'Думает')  then 1 end end) as СозданоПрофильныхЛидовФедор_После9
--	  ,count(case when lh.[Дата Заявки] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЗаявокCRM
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and lh.[Дата Заявки] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЗаявокCRM_После9
--	  ,sum(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then cast(datediff(minute, creationdate, [ВремяПервойПопытки]) as bigint) end) as DateDiff$creationdate$ВремяПервойПопытки
--	  ,sum(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then cast(datediff(minute, creationdate, [ВремяПервойПопытки]) as bigint) end) as DateDiff$creationdate$ВремяПервойПопытки_После9
--	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] <= dateadd(second, 120, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_0min_to_2min]
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] <= dateadd(second, 120, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_0min_to_2min_После9]
--	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 120, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 300 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_2min_to_5min]
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 120, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 300 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_2min_to_5min_После9]
--	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 300, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 1800 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_5min_to_30min]
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 300, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 1800 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_5min_to_30min_После9]
--	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 1800, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_30min_and_more]
--	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 1800, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_30min_and_more_После9]
--	  ,getdate() as created
--	  into #lh_byHour
--	  from #groups
--		 
--left join feodor.[dbo].[dm_leads_history_online_current_day] lh on
--                                       cast(lh.creationdate as date)=#groups.d
--									   and #groups.[LaunchControlName]  = lh.companynaumen
--									   and #groups.[Канал от источника] = lh.[Канал от источника]
--									   and #groups.[Группа каналов]     = lh.[Группа каналов]
--  where cast(#groups.d  as datetime) + cast(#groups.h  as datetime)<getdate()
--	
--									   
--group by 	#groups.d 
--      ,#groups.h		
--      ,#groups.[LaunchControlName]		
--      ,#groups.[Канал от источника]		
--      ,#groups.[Группа каналов]		
--	  order by 	#groups.d 
--      ,#groups.h		
--      ,#groups.[LaunchControlName]		
--      ,#groups.[Канал от источника]		
--      ,#groups.[Группа каналов]		
--
--
--	  begin tran
--	  delete from        feodor.[dbo].[dm_leads_history_online_current_day_running_value_by_hour] where d in (select distinct d from #lh_byHour)
--	  insert into        feodor.[dbo].[dm_leads_history_online_current_day_running_value_by_hour]
--	  select * from #lh_byHour
--	  commit tran
--
--	  begin tran
--	  delete from [dbo].[dm_leads_history_online_current_day_status_of_report]
--	  insert into [dbo].[dm_leads_history_online_current_day_status_of_report]
--	  select 1
--	  commit tran
--	 
--	 exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '1FD052A5-5D53-455A-9838-08D83CCAF005'

	 


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
 where дата between getdate()-3  and getdate()


 drop table if exists #rez
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
 ,[UF_PARTNER_ID аналитический]
 ,UF_SOURCE
 ,isPdl
 
 into #rez from (
 select  cast(c.creationdate as date) crd_d
 ,b.h end_t
 ,  [ID LCRM] 
 ,  creationdate
 , case when cast(ВремяПервойПопытки        as date)= cast(c.creationdate as date) and cast(ВремяПервойПопытки          as time)<=b.h then ВремяПервойПопытки       end  ВремяПервойПопытки         
 , case when cast(ВремяПервогоДозвона		as date)= cast(c.creationdate as date) and cast(ВремяПервогоДозвона		    as time)<=b.h then ВремяПервогоДозвона		end  ВремяПервогоДозвона		
  ,case when cast([Дата лида]				as date)= cast(c.creationdate as date) and cast([Дата лида]				as time)<=b.h then [Дата лида]			end FedorДатаЛида				
  ,case when cast([Дата лида]				as date)= cast(c.creationdate as date) and cast([Дата лида]				as time)<=b.h and  ([Статус лида] in ('Отправлен в ЛКК','Отправлен в МП', 'Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/) or [Отправлен в МП]=1) then [Дата лида]			end FedorДатаПрофильногоЛида				
 , case when cast([Дата Заявки]			as date)= cast(c.creationdate as date) and cast([Дата Заявки] 			as time)<=b.h then [Дата Заявки]			end  [Дата Заявки]			

 , [Группа каналов]
 , [Канал от источника]
 , CompanyNaumen
 , is_inst_lead
 , IsInstallment
 , [UF_PARTNER_ID аналитический]
 , UF_SOURCE
 , isPdl
 
 from #hours_of_day  b 
 cross join #dates_calendar  d
 left join  feodor.[dbo].[dm_leads_history_online_current_day]--#lh
 c with(nolock) on cast(c.creationdate as date)= cast(d.d as date) and cast( c.creationdate as time) < b.h	  and isnull(c.projecttitle , '') not in ('CRM Повторные', 'CRM Повторники Инст'  )
   where --cast(c.creationdate as date)>=cast(getdate()-2 as date) and
 --and [Канал от источника]<>'cpa нецелевой'
 --order by a.h, b.h, c.creationdate
   cast(d.d  as datetime) + cast(b.h  as datetime)<getdate()

-- and id=525324345
) x
 
group by crd_d,  end_t, [Группа каналов], [Канал от источника], is_inst_lead,IsInstallment, CompanyNaumen, [UF_PARTNER_ID аналитический], UF_SOURCE	, isPdl
order by crd_d,  end_t, [Группа каналов], [Канал от источника], is_inst_lead,IsInstallment, CompanyNaumen, [UF_PARTNER_ID аналитический], UF_SOURCE	, isPdl
 --order by a.h, b.h, c.creationdate

 --alter table feodor.dbo.dm_leads_history_online_current_day_by_hours
 --add [UF_PARTNER_ID аналитический] nvarchar(500)
 
 --alter table feodor.dbo.dm_leads_history_online_current_day_by_hours
 --add UF_SOURCE nvarchar(500)

 --alter table feodor.dbo.dm_leads_history_online_current_day_by_hours
 --add isPdl tinyint

 begin tran
 
--drop table if exists feodor.dbo.dm_leads_history_online_current_day_by_hours
--DWH-1764
--TRUNCATE TABLE dbo.dm_leads_history_online_current_day_by_hours
delete a from dbo.dm_leads_history_online_current_day_by_hours a join #rez   b on a.crd_d=b.crd_d 

INSERT feodor.dbo.dm_leads_history_online_current_day_by_hours
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
    [Создано заявок],
    [UF_PARTNER_ID аналитический],
	uf_source					 ,
	 isPdl
)
select 
	crd_d,
    end_t,
    [Группа каналов],
    [Канал от источника],
    is_inst_lead,
    isInstallment,
    CompanyNaumen,
    [Поступило лидов],
    [Обработано лидов],
    Дозвонились,
    [Лидов Feodor],
    [Профильных лидов Feodor],
    [Создано заявок],
    [UF_PARTNER_ID аналитический],
	uf_source					 ,
	isPdl
--INTO feodor.dbo.dm_leads_history_online_current_day_by_hours
from #rez

commit tran

--if @await_job=1 begin
--
--while exists (select top 1 1 d from analytics.dbo.[v_Запущенные джобы] where job_name='temp analytics job 2')
--begin
--waitfor delay '00:00:30'
--end
--
--end

	
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '1441C0DE-8643-4128-AD6C-7902CCF32505'



  return
										    
insert into Feodor.dbo.lead_for_update
select a.lcrm_id, 'case', getdate() from Feodor.dbo.dm_leads_history_online_current_day  a
left join
Feodor.dbo.lead_tbl b on  a.lcrm_id  =b.id

left join
Feodor.dbo.lead_for_update c on  a.lcrm_id =c.id
where
c.id is null and  b.creationdate is null	and a.creationdate>='20240427'



insert into Feodor.dbo.lead_for_update
select a.lcrm_id, 'call', getdate() from Feodor.dbo.dm_leads_history_online_current_day  a
left join
Feodor.dbo.lead_tbl b on  a.lcrm_id  =b.id

left join
Feodor.dbo.lead_for_update c on  a.lcrm_id =c.id
where
c.id is null and  b.ВремяПервойПопытки is null and  a.ВремяПервойПопытки is not null	and a.creationdate>='20240427'





--insert into Feodor.dbo.dm_leads_history_ids_to_update
--select try_cast(a.lcrm_id as numeric) from Feodor.dbo.dm_leads_history_online_current_day  a
--left join
--Feodor.dbo.dm_leads_history b on try_cast(a.lcrm_id as numeric)=b.id
--
--left join
--Feodor.dbo.dm_leads_history_ids_to_update c on try_cast(a.lcrm_id as numeric)=c.id
--where
--c.id is null and  b.creationdate is null		and isnumeric(a.lcrm_id)=1


	end

	

--	drop table if exists ##table_before
--select * into ##table_before from #t1

CREATE   procedure [dbo].[Create_dm_Lead]
as
begin
--return

--exec create_dm_leads_history_update_log
--select min([Дата лида]) from Feodor.dbo.dm_Lead

  declare @start_creating datetime = getdate()

 declare @max_dt_lead datetime =  (select max([Дата лида]) from Feodor.dbo.dm_Lead)
 declare @long_update int = case when cast(@max_dt_lead as date)<>cast(@start_creating as date) then 1 else 0 end 
 declare @start_dt datetime = case when @long_update=1 then  dateadd(day, -100, @start_creating) else dateadd(day, -10, @start_creating) end 
 --declare @start_dt datetime = case when @long_update=1 then '20191026' else dateadd(day, -10, @start_creating) end 

--set nocount on


--select * into #l from [PRODSQL02].[Fedor.Core].[core].[Lead] 
drop table if exists #l
--CREATE TABLE [dbo].[#l]
--(
--      [id] [UNIQUEIDENTIFIER]
--    , [IdExternal] [NVARCHAR](64)
--    , [IdStatus] [INT]
--    , [CreatedOn] [DATETIME2](7)
--    , [Phone] [NVARCHAR](12)
--);
--
 --insert into #l
select id, IdExternal, IdStatus, CreatedOn , dateadd(hour, 3,  CreatedOn) CreatedOnMSK , Phone  collate  Cyrillic_General_CI_AS Phone
into #l
from stg._fedor.core_Lead where  CreatedOn>=@start_dt

  insert 
into #l

select try_cast(original_lead_id as uniqueidentifier), original_lead_id, case when Результат='Забраковано' then 5 else 3 end , dateadd(hour, -3,  attempt_start)  attempt_start, attempt_start, phone   
from Analytics.dbo.lead_call_crm a

where Результат Is not null	and   attempt_start	>=@start_dt	 and   original_lead_id is not null		 and call_after_call1 =0
and 1=0
--order by 1

--select * from #l
									    

drop table if exists #lc
--select * into #lc from [PRODSQL02].[Fedor.Core].[core].[LeadCommunication]
select lc.id, lc.Comment, dateadd(hour, 3, lc.CreatedOn) CreatedOn , lc.idlead , lc.IdLeadRejectReason , lc.IdLeadCommunicationResult, lc.IdOwner, l.IdExternal, l.Phone, l.CreatedOn  leadCreatedOn , l.CreatedOnMSK leadCreatedOnMSK into #lc from stg._fedor.core_LeadCommunication  lc
join #l  l on lc.IdLead=l.id

insert into #lc
select original_lead_id	  id
,      Результат	   Comment
,      attempt_start	CreatedOn
,      original_lead_id	   idlead
,      case when Результат='Забраковано' then -1 else 0 end	  IdLeadRejectReason
,      case when Результат='Забраковано' then 3  else 0  end  IdLeadCommunicationResult
,     isnull(b.id , NEWID()) IdOwner
,      original_lead_id	   IdExternal
,      phone	Phone
,      dateadd(hour, -3, attempt_start  ) CreatedOn
,      attempt_start   leadCreatedOnMSK
from Analytics.dbo.lead_call_crm	a
left join   stg._fedor.core_user b on 'cm\'+a.login collate Cyrillic_General_CI_AS = b.domainlogin		   collate Cyrillic_General_CI_AS


where Результат is not null
	and original_lead_id is not null
	and attempt_start	>=@start_dt
	and call_after_call1=0
	and 1=0

	;with v  as (select *, row_number() over(partition by idlead, CreatedOn order by IdOwner desc ) rn from #lc ) delete from v where rn>1

drop table if exists #r
--select * into #r from [PRODSQL02].[Fedor.Core].[core].[ClientRequest]
select  cr.feodor_lead_id   idlead, cr.НомерЗаявки collate  Cyrillic_General_CI_AS number  
 , 1-isPts [IsInstallment]  , cr.ДатаЗаявки CreatedOn, cr.Телефон ClientPhoneMobile  
 , isPdl [IsPdl]
into #r    --select top 100 * 
from Analytics.dbo.v_request cr-- where number='23113021485981'		   
where isnull(cr.Отказано, cr.[Предварительное одобрение])  is not null

--=insert into  #r
--=select  lf.original   idlead, cr.НомерЗаявки collate  Cyrillic_General_CI_AS number  
--= , 1-isPts [IsInstallment]  , cr.ДатаЗаявки CreatedOn, cr.Телефон ClientPhoneMobile  
--= , isPdl [IsPdl]
--=  --select top 100 * 
--=from Analytics.dbo.v_request cr-- where number='23113021485981'
--=left join Analytics.dbo.v_request_lf lf on lf.number=cr.НомерЗаявки
--=where isnull(cr.Отказано, cr.[Предварительное одобрение])  is not null








--insert into  #r
--select * from  Analytics.dbo.lead_case_crm
--left join  Analytics.dbo.lead_case_crm
--left join stg.[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] b on try_cast(cr.number as bigint)=try_cast(b.Номер as bigint) and dateadd(year, -2000, b.Дата)>='20221123'

--select top 1000 * from [PRODSQL02].[fedor.core].dictionary.ProductType				
--select top 10000 * from analytics.dbo.columns_linked where is_feodor=1
--and table_name like '%type%'
--order by 4

	 --  select top 1000 * from [PRODSQL02].[fedor.core].dictionary.ProductType


--join #l  l on cr.IdLead=l.id
 --where dateadd(hour, 3, cr.CreatedOn)  >=@start_dt
--
--update dm_lead
--set [Дата заявки]=dateadd(hour, 3, [Дата заявки]) from dm_lead

drop table if exists #fa
--select * into #r from [PRODSQL02].[Fedor.Core].[core].[ClientRequest]
select Номер, [Верификация КЦ] , [Предварительное одобрение] , [Контроль данных]  , Одобрено, [Заем выдан], [Выданная сумма] into #fa from reports.dbo.dm_Factor_Analysis_001 fa
--join #r  r on r.number=fa.Номер
where ДатаЗаявкиПолная>=@start_dt

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


--select * from #l_r
--where id='593EECAB-6F6B-40AA-B565-6BB1C7FAC204'
 
--
--select * from #l_r l
--left join #r r on l.id=r.idlead
--where r.number is null and l.number is not null


drop table if exists #u
select id, DomainLogin collate  Cyrillic_General_CI_AS DomainLogin  into #u from [Stg].[_fedor].[core_user]

drop table if exists #s
select * into #s from [Stg].[_fedor].[dictionary_LeadStatus]

drop table if exists #lrr
select id, name into #lrr from [Stg].[_fedor].[dictionary_LeadRejectReason] 
--=insert into  #lrr
--=select -1, 'Забраковано CRM'
 


drop table if exists #lc_dist_id
select Id into #lc_dist_id from #lc group by Id
--select * from #s
--select * from #lc_dist_id

--SELECT [Id]
--      ,[Name]
--      ,[IdExternal]
--      ,[OrderNum]
--      ,[IsDeleted]
--      ,[SortOrder]
--  FROM [PRODSQL02].[Fedor.Core].[dictionary].[LeadCommunicationResult]
--GO



--	 select * from 
--stg._fedor.core_LeadCommunicationCall a 

drop table if exists #NaumenProjectId
select a.id
, max(a.NaumenProjectId)  collate Cyrillic_General_CI_AS NaumenProjectId
, max(a.NaumenCallId)  collate Cyrillic_General_CI_AS NaumenCallId
into #NaumenProjectId
from
--Feodor.dbo.dm_Lead				select * from 
stg._fedor.core_LeadCommunicationCall a 
join #lc_dist_id  lc_dist_id on lc_dist_id.id=a.id

group by a.id

--=insert into #NaumenProjectId
--=select original_lead_id, project_id  project_id , session_id  from Analytics.dbo.lead_call_crm
--=where Результат is not null	 and original_lead_id is  not null
--group by original_lead_id
--order by 
--select len(id) from #NaumenProjectId
--select len(original_lead_id) from Analytics.dbo.lead_call_crm


drop table if exists #inst_lead
select [ID лида Fedor], isPdl into #inst_lead from feodor.dbo.v_dm_LeadAndSurvey_installment_lids

-- insert into 	#inst_lead
--select original_lead_id  ,max(case when project_title like '%pdl%'	then 1 else 0 end) isPdl from  Analytics.dbo.lead_call_crm
--where Результат is not null and original_lead_id is  not null	and 
--(
--project_title like '%pdl%'	  or
--project_title like '%inst%'	  )
--group by original_lead_id


;with v  as (select *, row_number() over(partition by [ID лида Fedor] order by  isPdl desc) rn from #inst_lead ) delete from v where rn>1



--order by 

--create view dbo.dm_LeadAndSurvey_installment_lids as
--
--select [ID лида Fedor]
--
--from feodor.dbo.dm_LeadAndSurvey
--where Question in (
--'Installment Цель займа'
--,'Installment Продолжить оформление под installment?'
--,'Installment Даете согласие на обработку персональных данных?'
----,'Продукт Installment'
--,'Installment Оформляем заявку с кл по телефону?'
--,'Installment Сколько Вам полных лет?'
--,'Installment Хочешь завести заявку?'
--)
--group by [ID лида Fedor]

drop table if exists #fp
select * into #fp from Feodor.dbo.dm_feodor_project2
 
 --dm_feodor_project2

--select * from #fp

drop table if exists #dictionary_LeadCommunicationResult

select id , Name into #dictionary_LeadCommunicationResult from stg._fedor.dictionary_LeadCommunicationResult

 

   delete a from 	dbo.dm_lead_communication  a 											   
   where leadCreatedOn>= @start_dt
 insert into dbo.dm_lead_communication 
--drop table    dbo.dm_lead_communication 
select idlead, lrr.name LeadRejectReason 
		,lc.Comment CommentsLead
	   , npid.NaumenProjectId NaumenProjectId 
	   , IdLeadCommunicationResult IdLeadCommunicationResult
	   , DomainLogin DomainLogin
	   , LaunchControlName LaunchControlName
	  , lc.CreatedOn
	  , lcr.Name   CommunicationResult
	, lc.IdExternal
	, lc.Phone
	, lc.leadCreatedOn
	, lc.leadCreatedOnMSK
	, npid.NaumenCallId	  NaumenCallId
	  --	into dbo.dm_lead_communication 
	   from
      
      #lc lc

      left join  #dictionary_LeadCommunicationResult  lcr on lcr.id=lc.IdLeadCommunicationResult
      left join  #lrr  lrr on lrr.id=lc.IdLeadRejectReason
      left join  #NaumenProjectId  npid on npid.id=lc.Id
      left join  #fp  fp on fp.IdExternal=npid.NaumenProjectId and fp.[rn_IdExternal]=1
      left join  #u  u on u.id=lc.IdOwner



drop table if exists #Lead

select distinct  
       [ID лида Fedor]                         =  l.[Id]
     , [ID LCRM]	                           =  l.[IdExternal]  collate  Cyrillic_General_CI_AS
     , [Номер заявки (договор)]                =  r.Number         
	 , [IsInstallment]                         =  case when   [IsInstallment] is not null then [IsInstallment]
	                                                   when il.[ID лида Fedor] is not null then 1
													   else 0 end         
	 , [IsPdl]                         =  case when   r.[IsPdl] =1 then 1
	                                                   when il.[IsPdl] =1 then 1
													   else 0 end
     , [Дата лида]                             =	l.[CreatedOn]
     , [Месяц лида]	                           =  month(l.[CreatedOn])
     , [Статус лида]	                       =  s.[Name]                collate  Cyrillic_General_CI_AS
     , [Флаг уникальности лида]                =  1	--все уникальны
     , [Флаг дозвона]	                       =  1 --ко всем был дозвон, см. п.6
     , [Флаг недозвона]                        =  0 --	таких нет, см. п.6
     , [Флаг потерянного]                      =  0 --	таких нет, см. п.6
     , [Флаг профильности]                     =  case when l.idStatus=6 then 1 else 0 end
     , [Интервал времени реакции]              =  null	--нет таких данных
     , [Причина непрофильности по коммуникации]	               =  lc.[name]        collate  Cyrillic_General_CI_AS
     , [Сотрудник начала работы]               =  null--	нет таких данных
     , [Сотрудник окончания работы]            =  null--	нет таких данных
     , [Номер  телефона]                       =	l.[Phone]   
	 , [Комментарий по коммуникации]                           =	lc.[CommentsLead]    collate  Cyrillic_General_CI_AS
	 , lc.commentsdate
	 , lc.IdLeadCommunicationResult
	 , [id проекта naumen]                     = lc.NaumenProjectId
	 , [Флаг отправлен в МП]                   = case when  l.idStatus=10 or lc.IdLeadCommunicationResult=11 then 1 else 0 end
	 , [Дата заявки]                           = r.CreatedOn
	 , [Верификация КЦ]                           = [Верификация КЦ]
      ,[Предварительное одобрение]             = [Предварительное одобрение]
      ,[Контроль данных]                       = [Контроль данных]
      ,[Одобрено]                              = [Одобрено]
      ,[Заем Выдан]                            = [Заем Выдан]
      ,[Выданная Сумма]                        = [Выданная Сумма]
      ,DomainLogin                        = DomainLogin
	  ,[Кампания наумен]                    = LaunchControlName
	  ,[Дата коммуникации]                             =     lc.CreatedOn
	  ,[Результат коммуникации]                             =     lc.NameLeadCommunicationResult
	 into #lead
  
 from #l l
      left join  #l_r  l_r on l_r.id=l.id
      left join  #r  r on r.number=l_r.number
      left join #s   s on s.id=l.idStatus
      left join #inst_lead   il on il.[ID лида Fedor]=l.id
      left join #fa   fa on fa.Номер=r.number
      
      left join 
      (select idlead, lrr.name name,
	   lc.Comment CommentsLead, lc.createdOn commentsdate , npid.NaumenProjectId NaumenProjectId 
	   , IdLeadCommunicationResult IdLeadCommunicationResult
	   , DomainLogin DomainLogin
	   , LaunchControlName LaunchControlName
	  , lc.CreatedOn
	  , lcr.Name  NameLeadCommunicationResult
	   from
      
      #lc lc

      left join  #dictionary_LeadCommunicationResult  lcr on lcr.id=lc.IdLeadCommunicationResult
      left join  #lrr  lrr on lrr.id=lc.IdLeadRejectReason
      left join  #NaumenProjectId  npid on npid.id=lc.Id
      left join  #fp  fp on fp.IdExternal=npid.NaumenProjectId and fp.[rn_IdExternal]=1
      left join  #u  u on u.id=lc.IdOwner
	  --where isnull(IdLeadCommunicationResult, 1)>0

       ) lc on lc.idlead=l.id

	   create nonclustered index t on #lead
	   ([ID LCRM])


	--   select * from #l 
	--   where Id=IdExternal
	--
	--   select * from #lead
	--   where [ID лида Fedor]=[ID LCRM]
	--   order by 6

drop table if exists #leadwithrn

	 select *,
	   ROW_NUMBER () over(partition by [ID LCRM] 
	                      order by case when [Номер заявки (договор)] is not null then 1 else 0 end desc, 
								   [Заем Выдан]                 desc ,
								   [Одобрено]                   desc ,
								   [Контроль данных]            desc ,
								   [Предварительное одобрение]  desc ,
						           [Верификация КЦ]             desc ,
								   case when [Причина непрофильности] is not null then 1 else 0 end desc,
								   [Дата лида] desc	   ,
								   case when [Статус лида]<>'Новый' then 1 else 0 end desc, 
								   [Номер заявки (договор)] desc, 
								   [Дата коммуникации] 	 desc

								   ) as perv
	   into #leadwithrn
	   from (
	   select
	--   distinct
	    [ID лида Fedor]                         
	   ,[ID LCRM]	                           
	   ,[Номер заявки (договор)]                
	   ,[Дата лида]                             
	   ,[Месяц лида]	                           
	   ,case when [Номер заявки (договор)] is not null then 'Заявка' else  [Статус лида]	  end                     [Статус лида]
	   ,[Флаг уникальности лида]                
	   ,[Флаг дозвона]	                       
	   ,[Флаг недозвона]                        
	   ,[Флаг потерянного]                      
	   ,[Флаг профильности]                     
	   ,[Интервал времени реакции]              
	   ,case when [Номер заявки (договор)] is not null then null else FIRST_VALUE([Причина непрофильности по коммуникации]) over(partition by [ID LCRM] order by 
	   case when [Причина непрофильности по коммуникации] is null then 0 else 1 end desc, commentsdate desc) end  [Причина непрофильности]
	   ,[Сотрудник начала работы]               
	   ,[Сотрудник окончания работы]            
	   ,[Номер  телефона]                       
	   ,FIRST_VALUE([Комментарий по коммуникации]) over(partition by [ID LCRM] order by 
	   case when [Комментарий по коммуникации] is null then 0 else 1 end desc, commentsdate desc)  [Комментарий]
	  ,FIRST_VALUE([id проекта naumen]) over(partition by [ID LCRM] order by case when [id проекта naumen] is not null then 1 end desc,  [Дата коммуникации] ) [id проекта naumen]

	   --,max([id проекта naumen]) over (partition by [ID LCRM]) [id проекта naumen]
	   ,[IsInstallment]                
	   ,[IsPdl]                
	   ,max([Флаг отправлен в МП]) over (partition by [ID LCRM]) [Флаг отправлен в МП]
	   ,min(case when IdLeadCommunicationResult=11 then commentsdate end) over (partition by [ID LCRM]) [Отправлен в МП дата]
	 , [Дата заявки]                           = [Дата заявки]
	 , [Верификация КЦ]                           = [Верификация КЦ]
      ,[Предварительное одобрение]             = [Предварительное одобрение]
      ,[Контроль данных]                       = [Контроль данных]
      ,[Одобрено]                              = [Одобрено]
      ,[Заем Выдан]                            = [Заем Выдан]
      ,[Выданная Сумма]                        = [Выданная Сумма]
	  ,FIRST_VALUE(DomainLogin) over(partition by [ID LCRM] order by case when DomainLogin is not null then 1 else 0 end desc, commentsdate desc) [Последний сотрудник]
	  ,FIRST_VALUE([Кампания наумен]) over(partition by [ID LCRM] order by case when [Кампания наумен] is not null then 1 end desc, [Дата коммуникации] ) [Кампания наумен]
	   , [Результат коммуникации]
	   , [Дата коммуникации]
	   from #lead
	   
	   ) as leadwithrn 

	   delete from #leadwithrn
	   where perv>1

	 --  select * from #leadwithrn 

	
	   begin 
	   begin tran

delete from dm_Lead                                                                where [Дата лида]>=@start_dt
delete a from dm_Lead   a join      #leadwithrn b on a.[ID LCRM]=b.[ID LCRM]
insert into dm_Lead

select 

	    [ID лида Fedor]              
	   ,[ID LCRM]	                 
	   ,[Номер заявки (договор)]     
	   ,[Дата лида]                  
	   ,[Месяц лида]	             
	   ,[Статус лида]	             
	   ,[Флаг уникальности лида]     
	   ,[Флаг дозвона]	             
	   ,[Флаг недозвона]             
	   ,[Флаг потерянного]           
	   ,[Флаг профильности]          
	   ,[Интервал времени реакции]   
	   ,[Причина непрофильности]
	   ,[Сотрудник начала работы]              
	   ,[Сотрудник окончания работы]           
	   ,[Номер  телефона]             
	   ,[Комментарий]
	   ,[id проекта naumen]
	   ,[Дата обновления отчета] = getdate()
	   ,[IsInstallment]
	   ,[Флаг отправлен в МП]
	   ,[Отправлен в МП дата]
	   , [Дата заявки]                           = [Дата заявки]
	   , [Верификация КЦ]                           = [Верификация КЦ]
      ,[Предварительное одобрение]             = [Предварительное одобрение]
      ,[Контроль данных]                       = [Контроль данных]
      ,[Одобрено]                              = [Одобрено]
      ,[Заем Выдан]                            = [Заем Выдан]
      ,[Выданная Сумма]                        = [Выданная Сумма]
      ,[Последний сотрудник]                        = [Последний сотрудник]
      ,[Кампания наумен]                        = [Кампания наумен]
      , [Результат коммуникации] = [Результат коммуникации]
      , [IsPdl] = [IsPdl]

from #leadwithrn --where perv=1
--order by 4
commit tran
--select 1
end


--select * from [PRODSQL02].[Fedor.Core].[core].[LeadCommunication] 

--alter table dm_Lead
--add  [id проекта naumen] nvarchar(32) null

--alter table dm_Lead
--add  [Дата обновления отчета] datetime null

--alter table dm_Lead
--add  [IsInstallment] bit null

--alter table dm_Lead
--add  [Флаг отправлен в МП] bit null

--alter table dm_Lead
--add  [Отправлен в МП дата] datetime null

--alter table dm_Lead
--add  [Дата заявки] datetime null

--alter table dm_Lead
--add  [Дата заявки] datetime null
--[Выданная Сумма]
--[Заем Выдан]
--[Одобрено]
--[Контроль данных]
--[Предварительное одобрение]

--select * from #leadwithrn
--where [id lcrm]='1509880209'


--alter table dm_Lead
--add  [Последний сотрудник] nvarchar(255)

--alter table dm_Lead
--add  [Кампания наумен] nvarchar(255)

--alter table dm_Lead
--add  [Результат коммуникации] nvarchar(255)


--alter table dm_Lead
--add  [IsPdl] tinyint null

end

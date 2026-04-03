
-- select * from dbo.dm_collectionAgreementOfInteractionFrequency where date>='20200415'
CREATE   PROCEDURE [dbo].[create_dm_collectionAgreementOfInteractionFrequency]
as
begin
--dwh-491
set nocount on

  declare @DateFrom date    = '20120101'
  declare @DateTo date      = cast(getdate() as date)
  
/*  select CRMClientGUID from  dbo.dm_CMRStatBalance_2 b
  left join dwh_new.staging.CRMClient_references r on r.CMRContractNumber=b.external_id
  */

     
   drop table if exists #pep
   
   ;
  with w as (
  
  select d.Код Number
       , right(replace(replace(replace(replace(d.ТелефонМобильный,' ',''),'-',''),'(',''),')',''),10) MobilePhone
  --     , d.Фамилия
  --     , d.Имя
  --     , d.Отчество
       , case when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 and cast(dateadd(year,-2000,d.Дата) as date) >= '2019-08-11' then N'Да' 
			        else N'' 
		     end as [ПЭП2_3пакет]
  	   , case
			   when o.[Код]=N'8999' then N'ПЭП1'
			   when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 then N'ПЭП2'	--pep.[ПЭП2]=1 then N'ПЭП2'
			   when o.[Наименование] like '%Партнер №%' then N'Партнер'
			   when pep.[ВМ]=1 then N'ВМ'
		     end as [СпособОформленияЗайма]
    from stg._1ccmr.Справочник_Договоры d 
         left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o  with (nolock) on d.[Точка]=o.[Ссылка]
         left join [Stg].[_1cDCMNT].[ПЭП_Заявка_Сборка] pep with (nolock) on d.Код=pep.[ЗаявкаНомер]
  )
  select Number
       , MobilePhone
    into #pep 
    from w where ПЭП2_3пакет<>'' or [СпособОформленияЗайма] like '%ПЭП%'

  drop table if exists #contracts0
  
  select d
       , external_id
       , dpd 
       , CRMClientGUID
       , case when dpd>0 then 1 else 0 end ContractInDept
       , right(replace(replace(replace(replace(d.ТелефонМобильный,' ',''),'-',''),'(',''),')',''),10) MobilePhone
        , d.Фамилия
        , d.Имя
        , d.Отчество
          , case when p.number is not null then 1 else 0 end pep
    into #contracts0
    from dbo.dm_CMRStatBalance_2 b 
    left join dwh_new.staging.CRMClient_references r on r.CMRContractNumber=b.external_id
    left join stg._1ccmr.Справочник_Договоры d on b.external_id=d.Код
    left join #pep p on p.Number=b.external_id
   where d >=@DateFrom and d<dateadd(day,1,@DateTo)
   

    drop table if exists #clients
  
  select d
       , CRMClientGUID
     --  , ClientHAvePepNow = case when max(pep) over (partition by CRMClientGUID)>0 then 1 else 0 end
       , case when max(dpd)>0 then 1 else 0 end ClientInDept
       , case when max(pep)>0 then 1 else 0 end ClientHavePep
       , case when max(pep)>0 and max(dpd)>0  then 1 else 0 end ClientHavePepAndInDept
    into #clients
    from #contracts0
    group by d , CRMClientGUID

 



drop table if exists #contracts
;with c as (
select   c0.d date
       , c0.external_id number
       , c0.dpd 
       , c0.CRMClientGUID
       , c0.ContractInDept
       , c0.MobilePhone
       , c0.Фамилия
       , c0.Имя
       , c0.Отчество
        ,rn=row_number() over(partition by  c0.CRMClientGUID order by d desc )
     

from #contracts0 c0
)
select * into #contracts
from c where rn=1


drop table if exists #res
select 
d, c.CRMClientGUID, ClientInDept, ClientHavePep,ClientHavePepAndInDept, MobilePhone, Фамилия, Имя, Отчество
 ,ClientHAvePepNow = case when max(ClientHavePep) over (partition by d.CRMClientGUID)>0 then 1 else 0 end
into #res
from #clients c left join #contracts d on c.CRMClientGUID=d.CRMClientGUID 
--order by 2,1



/*
select * from #contracts0 where CRMClientGUID='1B350A97-0859-11E8-A814-00155D941900'
select * from #contracts where CRMClientGUID='1B350A97-0859-11E8-A814-00155D941900'
select * from #clients c left join #contracts d on c.CRMClientGUID=d.CRMClientGUID and d.date=c.d  where c.CRMClientGUID='1B350A97-0859-11E8-A814-00155D941900'
select   c0.d date
       , c0.external_id number
       , c0.dpd 
       , c0.CRMClientGUID
       , c0.ContractInDept
       , c0.MobilePhone
       , c0.Фамилия
       , c0.Имя
       , c0.Отчество
        ,rn=row_number() over(partition by  c0.CRMClientGUID order by d desc )
     

from #contracts0 c0
where CRMClientGUID='1B350A97-0859-11E8-A814-00155D941900'
order by d desc
*/
--left join #clients c on c0.d=c.d and c0.CRMClientGUID=c.CRMClientGUID




    drop table if exists #smsCommunications
     select  CommunicationDateTime, Number,CrmCustomerId CRMCustomerGUID ,sms_flag, url_ending, smsurl ,CommunicationTemplate
     into #smsCommunications
     from stg._collection.v_Communications where sms_flag=1 and url_ending<>''




drop table if exists #clicks
select cast(CommunicationDateTime as date) date, 
 CRMCustomerGUID, sms_flag, c.url_ending, smsurl--, CommunicationTemplate
 ,sum(clicks) clicks_10_days
 ,total_clicks
into #clicks
from   #smsCommunications c 
left join 
          (select *,total_clicks=sum(clicks) over(partition by url_ending) from stg.dbo.SMSUrlClicksByDate) 
          
          
          s on c.url_ending=s.url_ending and s.date>=cast(c.CommunicationDateTime as date) and s.date<dateadd(day,10,cast(c.CommunicationDateTime as date))
where c.url_ending<>''
group by cast(CommunicationDateTime as date) , total_clicks,
 CRMCustomerGUID, sms_flag, c.url_ending, smsurl--, CommunicationTemplate




 drop table if exists #mp_signs
 ;
 with mp as (
  SELECT pag.client_id
       , username 
       , pag.updated_at signDate
    
    FROM stg._lk.users u
    join stg._lk.pep_activity_log pag on pag.client_id = u.id
   where pag.document_guid = '40fe07a2-3925-44df-9859-1f2fbd5429b1'
   group by pag.client_id,username,pag.updated_at 
   )
   ,mp0 as(
   select *
   ,rn=row_number() over (partition by  username order by signDate desc)
   
   from mp
   )

   select * 
   into #mp_signs 
   from mp0
   where rn=1



   

--drop table if exists dm_collectionAgreementOfInteractionFrequency

--DWH-1764 
TRUNCATE TABLE [dbo].[dm_collectionAgreementOfInteractionFrequency]

INSERT [dbo].[dm_collectionAgreementOfInteractionFrequency]
(
    [date],
    [CRMClientGUID],
    [ClientInDept],
    [ClientHavePep],
    [ClientHavePepAndInDept],
    [MobilePhone],
    [Фамилия],
    [Имя],
    [Отчество],
    [sms_flag],
    [url_ending],
    [smsurl],
    [clicks_10_days],
    [total_clicks],
    [signDate],
    [signed],
    [ClientHAvePepNow]
)
   select d date
        , CRMClientGUID
        , ClientInDept
        , ClientHavePep
        , ClientHavePepAndInDept
        , MobilePhone
        , Фамилия
        , Имя
        , Отчество
        , sms_flag
        , url_ending
        , smsurl
        , clicks_10_days
        , total_clicks
        , signDate
        , signed =case when signDate is not null then 1 else 0 end
        , ClientHAvePepNow
        --into dbo.dm_collectionAgreementOfInteractionFrequency
   from #res r 
    left join #clicks c on r.CRMClientGUID=c.CRMCustomerGUID and r.d=c.date
    left join #mp_signs s on s.username=r.MobilePhone and cast(s.signDate as date)=r.d
  -- order by 2,1


   /*
   --drop table if exists dm_collectionAgreementOfInteractionFrequency
begin tran
  delete from dbo.dm_collectionAgreementOfInteractionFrequency
  insert into dbo.dm_collectionAgreementOfInteractionFrequency
  select d Date
       , external_id Number
       , dpd
       , CRMClientGUID
       , clicks =isnull(clicks,0)
       , case when dpd>0 then CRMClientGUID  end Просрочка
       , case when dpd>0 then 1 else 0 end isDpd
       , case when Код is not null then CRMClientGUID  end ПодписаноПЭП
       , case when Код is not null then 1 else 0 end isPepSigned
       , case when Код is not null and dpd>0 then CRMClientGUID  end ДоговоровВПросрочкеПодписаноПЭП
       , case when Код is not null and dpd>0 then 1 else 0  end isPepSignedDpd
       , case when s.number is not null then CRMClientGUID  end ОтправленоSMS
       , case when s.number is not null then 1 else 0  end isSendedSMS
       , isnull(s.clicks,0) КоличествоПереходов
       , case when mp.username is null then null else CRMClientGUID end Подписано
       , case when mp.username is null then 0 else 1 end isAgreementSigned
       , created=getdate()
       , updated=getdate()
    --into dm_collectionAgreementOfInteractionFrequency
    from #contracts c 
    left join #pep p on p.Number=c.external_id
    left join #Clicks s on s.number=c.external_id and cast(s.Date as date)=c.d
    left join #mp_signs mp on mp.username=c. and cast(mp.signDate as date)=c.d
commit tran
*/
    --select * from dm_collectionAgreementOfInteractionFrequency
--  select d
--       , count(*) [Договоров]
--       , sum(case when dpd>0 then 1 else 0 end) [ДоговоровВПросрочке]
--       , sum(case when Код is not null then 1 else 0 end) ПодписаноПЭП
--       , sum(case when Код is not null and dpd>0 then 1 else 0 end) ДоговоровВПросрочкеПодписаноПЭП
--       , sum(case when s.number is not null then 1 else 0 end) ОтправленоSMS
--       , sum(isnull(s.clicks,0)) КоличествоПереходов
--       , sum(case when mp.username is null then 0 else 1 end) КоличествоПодписей
--    from #contracts c 
--    left join #pep p on p.Код=c.external_id
--    left join #smsClicks s on s.number=c.external_id and cast(s.Date as date)=c.d
--    left join #mp_signs mp on mp.username=s.PhoneNumber

--group by d
--order by d

end

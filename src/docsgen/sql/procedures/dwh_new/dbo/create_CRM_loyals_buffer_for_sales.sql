-- =============================================
-- Author:		Petr Ilin
-- Create date: 28.05.2020
-- Description:	скрипт для формирования итогового списка предложений для маркетинга
-- =============================================


CREATE PROCEDURE [dbo].[create_CRM_loyals_buffer_for_sales]

as begin 

  declare @now_t datetime = getdate()
  drop table if exists #t1
  
  select  [external_id]
      ,[category]
	  ,case 
			   when category = 'Зеленый' then 1 
               when category = 'Желтый' then 2 
			   when category = 'Синий' then 3 
               when category = 'Оранжевый' then 4 
               when category = 'Красный' then 5 end as НомерЦвета
      ,[Type]
      ,[main_limit]
      ,[fio]
      ,rr.CRMClientFIO
      ,[Паспорт серия]
      , [Паспорт номер]
      , case when case when ТелефонМобильный is null or ТелефонМобильный='' then null else rr.МобильныйТелефон end not in ('',null) then 
            case when ТелефонМобильный is null or ТелефонМобильный='' then null else rr.МобильныйТелефон end else ТелефонМобильный end as mobile_fin
      ,[region_projivaniya]
      ,[Berem_pt]
      ,[Nalichie_pts]
	  ,@now_t as created
    ,r.CRMClientGuid
	,p.birth_date

into #t1
 from dwh_new.dbo.povt_buffer p
 left join dwh_new.[staging].[CRMClient_references] r on r.MFOContractNumber=p.external_id
 left join dwh_new.[staging].[CRMClients_references] rr on rr.CRMClientIDRREF=r.CRMClientIDRREF
union
select  
       [external_id]
      ,[category]
	  ,case 
			   when category = 'Зеленый' then 1 
               when category = 'Желтый' then 2 
			   when category = 'Синий' then 3 
               when category = 'Оранжевый' then 4 
               when category = 'Красный' then 5 end as НомерЦвета
      ,[Type]
      ,[main_limit]
      ,[fio]
      ,rr.CRMClientFIO
      ,[Паспорт серия]
      ,[Паспорт номер]
      , case when case when ТелефонМобильный is null or ТелефонМобильный='' then null else rr.МобильныйТелефон end not in ('',null) then 
            case when ТелефонМобильный is null or ТелефонМобильный='' then null else rr.МобильныйТелефон end else ТелефонМобильный end as mobile_fin
      ,[region_projivaniya]
      ,[Berem_pts] as [Berem_pt]
      ,[Nalichie_pts]
	  	  ,@now_t as created
        ,r.CRMClientGuid
		,p.birth_date
 from dwh_new.dbo.docredy_buffer  p
 left join dwh_new.[staging].[CRMClient_references] r on r.MFOContractNumber=p.external_id
 left join dwh_new.[staging].[CRMClients_references] rr on rr.CRMClientIDRREF=r.CRMClientIDRREF

 


 begin tran
delete from  dwh_new.dbo.CRM_loyals_buffer_for_sales
 insert into dwh_new.dbo.CRM_loyals_buffer_for_sales
 select * from #t1
 commit tran
end

--alter table dwh_new.dbo.CRM_loyals_buffer_for_sales add CRMClientGuid nvarchar(36)
--alter table dwh_new.dbo.CRM_loyals_buffer_for_sales add birth_date date


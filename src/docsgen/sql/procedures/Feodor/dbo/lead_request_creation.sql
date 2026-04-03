CREATE   proc 

 --declare  @satrt_date date = getdate()	-10		exec lead_request_creation	@satrt_date 

[dbo].[lead_request_creation]
@satrt_date date = null

	as
	 

   --declare  @satrt_date date = getdate()	-10
   
       -- declare  @satrt_date date = '20240425'
		 	

 --drop table if exists #fa_tmp
 --select ДатаЗаявкиПолная, [Заем выдан], Номер, Телефон, [Вид займа], [Предварительное одобрение], Одобрено, [Контроль данных], [Выданная сумма], [LCRM ID], case when  [Место cоздания] in ( 'Ввод операторами LCRM', 'ЛКК клиента')  then 1 else 0 end [is_lcrm], 1-isPts IsInstallment, isPdl, original_lead_id into #fa_tmp 
 
 --from [Reports].[dbo].[dm_Factor_Analysis_001]
 --where ДатаЗаявкиПолная>=@satrt_date   

		 


 drop table if exists #fa_tmp
 select ДатаЗаявки ДатаЗаявкиПолная, [Заем выдан], НомерЗаявки Номер, Телефон, [Видзайма] [Вид займа], [Предварительное одобрение], Одобрено, [Контроль данных], ВыданнаяСумма [Выданная сумма], LcrmID [LCRM ID], case when  МестоСоздания in ( 'Ввод операторами LCRM', 'ЛКК клиента')  then 1 else 0 end [is_lcrm], 1-isPts IsInstallment, isPdl, isnull(a. original_lead_id , b.originalLeadId) original_lead_id into #fa_tmp 
 
 from analytics.dbo.v_request a
 left join analytics.dbo.v_request_lf2 b on a.number = b.number
 where ДатаЗаявки>=@satrt_date	   and [Верификация КЦ] is not null
 
 

 drop table if exists #dm_Lead_tmp
 CREATE TABLE  #dm_Lead_tmp
(
      [Дата лида] [DATETIME2](7)
    , [Номер  телефона] [NVARCHAR](12)
    , [Номер заявки (договор)] [NVARCHAR](255)
    , [Причина непрофильности] [NVARCHAR](255)
    , [Статус лида] [NVARCHAR](255)
    , [ID LCRM] [NVARCHAR](64)
    , [ID лида Fedor] [UNIQUEIDENTIFIER]
    , [id проекта naumen] [NVARCHAR](32)
    , [Флаг отправлен в МП] [BIT]
    , [IsInstallment] [BIT]
    , [isPdl] [TINYINT]
    , [Дата заявки] [DATETIME]
    , [Результат коммуникации] [NVARCHAR](255)
);

  insert into  #dm_Lead_tmp

 select [Дата лида]
 , [Номер  телефона], [Номер заявки (договор)], [Причина непрофильности],[Статус лида], [ID LCRM], [ID лида Fedor] 
 , [id проекта naumen]
 , [Флаг отправлен в МП]
 , IsInstallment
 , isPdl
 , [Дата заявки] 
 , [Результат коммуникации]

 
 from Feodor.dbo.dm_Lead
  where [id проекта naumen] is not null	and dateadd(hour, 3, [Дата лида])>=@satrt_date


 drop table if exists #clean

   select [ID LCRM] into #clean
  from Feodor.dbo.dm_Lead
  where [id проекта naumen] is not null	and dateadd(hour, 3, [Дата лида])>=dateadd(day, -10, @satrt_date) 

  insert into  #dm_Lead_tmp
 
 
 
 select dateadd(hour, -3, ДатаЗаявкиПолная) [Дата лида]
 , Телефон [Номер  телефона]
 , Номер [Номер заявки (договор)]
 , null [Причина непрофильности]
 , 'Заявка' [Статус лида]
 , original_lead_id [ID LCRM]
 ,  null [ID лида Fedor] 
 , 'Полная заявка' [id проекта naumen]
 , null
 , a.IsInstallment
 , a.isPdl
 , a.ДатаЗаявкиПолная 
 , null [Результат коммуникации]
				    
 
 from #fa_tmp  a
 left join 	#clean b on a.original_lead_id=b.[ID LCRM]	 
 where b.[ID LCRM] is null	and a.original_lead_id is not null--	and   a.ДатаЗаявкиПолная  >='20240425' 

 ;with v  as (select *, row_number() over(partition by [ID LCRM] order by [Дата лида] desc) rn from #dm_Lead_tmp )
 delete from v where rn>1
 -- select * from v where rn>1
 




drop table if exists  [#dm_feodor_projects]
select IdExternal, RecallProject, LaunchControlName, LaunchControlID , rn_IdExternal into [#dm_feodor_projects]

from  [Feodor].[dbo].[dm_feodor_projects]


drop table if exists #forw
  select 
       feodor.[ID LCRM] id
    --  ,cast(null as varchar(512) ) [UF_NAME]
 
      --,isnull(fp_id.[LaunchControlName], isnull(isnull(isnull(fp.[LaunchControlName], fp_ref.LaunchControlName), fp_f.LaunchControlName)  ,isnull(enum.VALUE ,case when UF_LOGINOM_STATUS='accepted' or lcun.UF_LCRM_ID is not null or ch.lcrm_id is not null or fl.[ID LCRM] is not null then 'Не определен' else 'Non-Feodor' end))) [CompanyNaumen]
	  , [CompanyNaumen] = case 
	  when fp_f.LaunchControlName is not null then fp_f.LaunchControlName
	  when feodor.[id проекта naumen] ='Полная заявка' then 'Полная заявка'	  end 
 ,feodor.[ID лида Fedor] [FedorID]
 ,feodor.[ID LCRM] [FedorLCRMID]
 ,dateadd(hour, 3, feodor.[Дата лида]) [FedorДатаЛида]
 ,feodor.[Номер заявки (договор)] [FeodorReq]
 ,feodor.[Статус лида] [СтатусЛидаФедор]
 ,feodor.[Причина непрофильности] [ПричинаНепрофильности]
    ,case when [Статус лида] in ('Отказ клиента с РСВ', 'Отказ клиента без РСВ')  then 1 end as [ФлагОтказКлиента]
   ,case when [Статус лида] in ('Отправлен в ЛКК','Отправлен в МП','Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/) then 1 end as [ФлагПрофильныйИтог]
  ,case when   [Номер заявки (договор)]  is not null  then 1 end as [ФлагЗаявка]
 ,  isnull(feodor.[Дата заявки], fa.ДатаЗаявкиПолная)  ДатаЗаявкиПолная
  
 ,   fa.[Вид займа]   [ВидЗайма]
 , fa.[Предварительное одобрение]  [ПредварительноеОдобрение]
 ,   fa.[Контроль данных]    [КонтрольДанных]
 ,   fa.Одобрено   Одобрено
 ,   fa.[Заем выдан]   [ЗаемВыдан]
 ,  fa.[Выданная сумма]    [ВыданнаяСумма]
 ,feodor.IsInstallment IsInstallment
 , [Результат коммуникации]  
 
 ,isnull( feodor.isPdl , 0) IsPdl
  into #forw
  from #dm_Lead_tmp feodor
  left join [#dm_feodor_projects] fp_f on fp_f.[IdExternal]=feodor.[id проекта naumen]  and  fp_f.[rn_IdExternal]=1
left join  #fa_tmp fa on feodor.[Номер заявки (договор)]=fa.Номер --and fa_lcrm.Номер is null


--exec analytics.dbo.select_table '#forw'

drop table if exists #changed


select a.id into #changed from #forw	a  
left join lead b with(nolock) on a.id=b.id
where b.id is null

declare @a [carm\p.ilin].leadtype 

insert into  @a
  select  id from 	#changed
  if exists(select top 1 * from #changed where id is not null)
exec lead_creation 		@a, null

 
 --select top 1 * from lead

 
begin tran
DECLARE @Result INT;
EXEC @Result = sp_getapplock @Resource = 'MergeLock', @LockMode = 'Exclusive'--, @LockTimeout = 300000; -- 5 минут


IF @Result >= 0
BEGIN
    BEGIN TRY
 ;

	    MERGE feodor.dbo.[lead] AS target
    USING (
select 
    a.[id] 
,   a.[CompanyNaumen] 
,   a.[FedorID] 
,   a.[FedorLCRMID] 
,   a.[FedorДатаЛида] 
,   a.[FeodorReq] 
,   a.[СтатусЛидаФедор] 
,   a.[ПричинаНепрофильности] 
,   a.[ФлагОтказКлиента] 
,   a.[ФлагПрофильныйИтог] 
,   a.[ФлагЗаявка] 
,   a.[ДатаЗаявкиПолная] 
,   a.[ВидЗайма] 
,   a.[ПредварительноеОдобрение] 
,   a.[КонтрольДанных] 
,   a.[Одобрено] 
,   a.[ЗаемВыдан] 
,   a.[ВыданнаяСумма] 
,   a.[IsInstallment] 
,   a.[Результат коммуникации] 
,   a.[IsPdl] 
, HASHBYTES('SHA2_256',  
  '|'+isnull( cast(a.[FedorID] 	                			 as varchar(1000)), '')		
+ '|'+isnull( cast(a.[FedorLCRMID] 			     as varchar(1000)), '')		
+ '|'+isnull( cast(a.[FedorДатаЛида] 		    	 as varchar(1000))	, '')	
+ '|'+isnull( cast(a.[FeodorReq] 			    	 as varchar(1000))	, '')	
+ '|'+isnull( cast(a.[СтатусЛидаФедор] 		     as varchar(1000)), '')		
+ '|'+isnull( cast(a.[ПричинаНепрофильности] 		 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ФлагОтказКлиента] 			 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ФлагПрофильныйИтог] 		 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ФлагЗаявка] 				 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ДатаЗаявкиПолная] 			 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ВидЗайма] 					 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ПредварительноеОдобрение] 	 as varchar(1000)), '') 	
+ '|'+isnull( cast(a.[КонтрольДанных] 			 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[Одобрено] 					 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ЗаемВыдан] 					 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[ВыданнаяСумма] 				 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[IsInstallment] 				 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[Результат коммуникации] 	 as varchar(1000)), '')	
+ '|'+isnull( cast(a.[IsPdl] 						 as varchar(1000))			, '')	)	 hash_request

from 

#forw a	    ) AS source
    ON target.ID = source.ID	 and source.hash_request<> isnull(target.hash_request, '')
    WHEN MATCHED THEN
        UPDATE SET
    target.[CompanyNaumen] 				= case when target.[CompanyNaumen] is null then source.[CompanyNaumen] 	else target.[CompanyNaumen] end 			
,   target.[FedorID] 					= source.[FedorID] 					
,   target.[FedorLCRMID] 				= source.[FedorLCRMID] 				
,   target.[FedorДатаЛида] 				= source.[FedorДатаЛида] 				
,   target.[FeodorReq] 					= source.[FeodorReq] 					
,   target.[СтатусЛидаФедор] 			= source.[СтатусЛидаФедор] 			
,   target.[ПричинаНепрофильности] 		= source.[ПричинаНепрофильности] 		
,   target.[ФлагОтказКлиента] 			= source.[ФлагОтказКлиента] 			
,   target.[ФлагПрофильныйИтог] 		= source.[ФлагПрофильныйИтог] 		
,   target.[ФлагЗаявка] 				= source.[ФлагЗаявка] 				
,   target.[ДатаЗаявкиПолная] 			= source.[ДатаЗаявкиПолная] 			
,   target.[ВидЗайма] 					= source.[ВидЗайма] 					
,   target.[ПредварительноеОдобрение] 	= source.[ПредварительноеОдобрение] 	
,   target.[КонтрольДанных] 			= source.[КонтрольДанных] 			
,   target.[Одобрено] 					= source.[Одобрено] 					
,   target.[ЗаемВыдан] 					= source.[ЗаемВыдан] 					
,   target.[ВыданнаяСумма] 				= source.[ВыданнаяСумма] 				
,   target.[IsInstallment] 				= source.[IsInstallment] 				
,   target.[Результат коммуникации] 	= source.[Результат коммуникации] 	
,   target.[IsPdl] 						= source.[IsPdl] 						
,   target.row_updated 						= getdate()					
,   target.hash_request 						= source.hash_request			
 
  ;
 
  declare @rc bigint = @@ROWCOUNT
		select @rc, 'updated rows lead creation'


		EXEC sp_releaseapplock @Resource = 'MergeLock';

        COMMIT TRANSACTION;
      --  exec analytics.dbo.log_email 'lead_creation ok'

	    END TRY
    BEGIN CATCH
        -- Освобождение блокировки в случае ошибки
        EXEC sp_releaseapplock @Resource = 'MergeLock';
        exec analytics.dbo.log_email 'lead_creation error transaction'
        -- Обработка ошибок
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
ELSE
BEGIN
    -- Не удалось получить блокировку, обработка ошибки
    PRINT 'Не удалось получить блокировку';
     exec analytics.dbo.log_email 'lead_creation critical error Не удалось получить блокировку'

    ROLLBACK TRANSACTION;
END

  
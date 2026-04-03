Create   PROCEDURE [dbo].[reportDifference_FIO_BirthD_MFO_CMR] 
AS
BEGIN
	SET NOCOUNT ON;


declare @GetDate2000 datetime

set @GetDate2000=dateadd(year,2000,getdate());

with	t0_crm as (select [Заявка] ,dr.[Номер] as [НомерCRM] ,dr.[ДатаРождения] as [ДР_Клиент_CRM]
			   from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] s with (nolock)
			   left join  [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] dr  with (nolock) on s.[Заявка]=dr.[Ссылка]
			   where s.[Статус]=0xA81400155D94190011E80784923C6097 and dr.[ПометкаУдаления]=0x00) -- Заем выдан

,	t0_mfo as (select [Ссылка] ,[Номер] as [НомерMFO] ,[ДатаРождения] as [ДР_Клиент_МФО] from [Stg].[_1cMFO].[Документ_ГП_Заявка])

,	t1 as (select distinct [Заявка] 
						   ,[НомерCRM] ,[НомерMFO] 
						   ,[CMRContractNumber] ,[MFOContractNumber] ,case when [CMRContractNumber]=[MFOContractNumber] then 0 else 1 end as [DifferentNumber]
						   ,[CRMClientGUID] 
						   ,[CRMClientFIO] ,[MFORequestFIO] ,case when [CRMClientFIO]=[MFORequestFIO] then 0 else 1 end as [DifferentFIO]

						   ,cast((dateadd(year,-2000,cast([ДР_Клиент_CRM] as datetime2))) as date) as [ДР_Клиент_CRM] 
						   ,cast((dateadd(year,-2000,cast([ДР_Клиент_МФО] as datetime2))) as date) as [ДР_Клиент_МФО]
						   ,case when [ДР_Клиент_CRM]=[ДР_Клиент_МФО] then 0 else 1 end as [Different_ДР]
		   from t0_crm 
		   left join [dwh_new].[staging].[CRMClient_references] r with (nolock) on [Заявка]=r.[CMRRequestIDRREF]
		   left join t0_mfo on r.[MFORequestIDRREF]=t0_mfo.Ссылка)

select * from t1 where ([DifferentNumber]=1 or [DifferentFIO]=1 or [Different_ДР]=1) and not ([НомерCRM] is null or [НомерMFO] is null) order by [НомерCRM] desc

END

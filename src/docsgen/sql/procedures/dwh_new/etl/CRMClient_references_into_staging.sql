

CREATE procedure [etl].[CRMClient_references_into_staging]
as



declare @i int
   
begin try
	if object_id('staging.CRMClient_references') is not null 
		truncate table staging.CRMClient_references

	insert into  staging.CRMClient_references
	SELECT MFO_Contracts.Номер	MFOContractNumber
	   , MFO_Contracts.Дата		MFOContractDateTime
	   , MFOContractFIO=ltrim(rtrim(MFO_Contracts.Фамилия))+' '+ltrim(rtrim(MFO_Contracts.Имя))+' '+ltrim(rtrim(MFO_Contracts.Отчество))

	   , MFO_Requests.Номер     MFORequestNumber
       , MFO_Requests.Дата	    MFORequestDateTime
	   ,  MFORequestFIO=ltrim(rtrim(MFO_Requests.Фамилия))+' '+ltrim(rtrim(MFO_Requests.Имя))+' '+ltrim(rtrim(MFO_Requests.Отчество))
      

       , CRM_Requests.Номер		CRMRequestNumber
       , CRM_Requests.Дата		CRMRequestDateTime
     
	   , CRM_Clients.ссылка		CRMClientIDRREF
       , CRMClientGUID    = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CRM_Clients.Ссылка)  as nvarchar(64))
       , CRMClientFIO=CRM_Clients.Наименование
   
   
       , CMR_Contracts.Код CMRContractNumber
       , CMR_Contracts.Дата CMRContractDateTime
	   , CMRContractFIO=ltrim(rtrim(CMR_Contracts.Фамилия))+' '+ltrim(rtrim(CMR_Contracts.Имя))+' '+ltrim(rtrim(CMR_Contracts.Отчество))
	   

	   , CMR_Requests.Код CMRRequestNumber
	   , CMR_Requests.Дата	CMRRequestDateTime
	   , CMRRequestFIO=ltrim(rtrim(CMR_Requests.Фамилия))+' '+ltrim(rtrim(CMR_Requests.Имя))+' '+ltrim(rtrim(CMR_Requests.Отчество))
	   


	   , MFOContractIDRREF = MFO_Contracts.ссылка
	   , MFOContractGUID    = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(MFO_Contracts.ссылка)  as nvarchar(64))
       
       , MFORequestIDRREF = MFO_Requests.ссылка
       , MFORequestGUID    = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(MFO_Requests.ссылка)  as nvarchar(64))
     
       , CRMRequestIDRREF = CRM_Requests.ссылка
       , CRMRequestGUID    = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CRM_Requests.ссылка)  as nvarchar(64))

       , CMRContractIDRREF=CMR_Contracts.ссылка
       , CMRContractGUID  = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CMR_Contracts.Ссылка)  as nvarchar(64))

	   , CMRRequestIDRREF = CMR_Requests.ссылка
	   , CMRRequestGUID   = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CMR_Requests.Ссылка)  as nvarchar(64))

  FROM stg._1cMFO. [Документ_ГП_Договор] MFO_Contracts
       left join stg._1cMFO.[Документ_ГП_Заявка] MFO_Requests on MFO_Requests.Ссылка=MFO_Contracts.Заявка
	     left join stg._1cMFO.Справочник_Контрагенты MFO_Clients on MFO_Clients.ССылка=MFO_Contracts.Контрагент
       
	     left join 
       ----[c1-vsr-sql04].crm.[dbo].Документ_ЗаявкаНаЗаймПодПТС 
       stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС 
       CRM_Requests on CRM_Requests.Ссылка=MFO_Requests.Ссылка--CMR_Contracts.заявка
       left join 
       ----[c1-vsr-sql04].crm.dbo.[Справочник_Партнеры] 
       stg._1cCRM.[Справочник_Партнеры] 
       CRM_Clients on  CRM_Clients.Ссылка=CRM_Requests.Партнер
       
	     left join stg._1cCMR.[Справочник_Договоры] CMR_Contracts on  CMR_Contracts.ссылка= MFO_Contracts.ссылка
       left join stg._1cCMR.[Справочник_Заявка] CMR_Requests on CMR_Contracts.Заявка =CMR_Requests.Ссылка
      
end try

begin catch
           
	;THROW

end catch







       /*

	   select * from [c1-vsr-sql05].[MFO_NIGHT00].[dbo].[Документ_ГП_Заявка] MFO_Requests


	    select * from [c1-vsr-sql05].[MFO_NIGHT00].[dbo].[Документ_ГП_Договор] MFO_Contracts

		select * from [c1-vsr-sql05].CRM_NIGHT00.dbo.[Справочник_Партнеры] CRM_Clients


		select * from  [C1-VSR-SQL05].[CMR_NIGHT00].[dbo].[Справочник_Договоры] 
		select * from [C1-VSR-SQL05].[CMR_NIGHT00].[dbo].[Справочник_Заявка]


		*/
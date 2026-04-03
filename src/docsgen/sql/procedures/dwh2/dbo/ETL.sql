-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 2020-07-29
-- Description:	Main etl process dwh 2.0
-- =============================================
CREATE   PROCEDURE [dbo].[ETL]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    
	--drop table if exists dbo.ClientReferences 
	TRUNCATE TABLE dbo.ClientReferences --DWH-1764
  
  --select * into dbo.ClientReferences from cubes.v_ClientReferences 

  -- 629 задача
  --select * into dbo.ClientReferences from cubes.v_ClientReferences
  --DWH-1764
  INSERT dbo.ClientReferences
  (
      MFOContractNumber,
      MFOContractDateTime,
      MFOContractFIO,
      MFORequestNumber,
      MFORequestDateTime,
      MFORequestFIO,
      CRMRequestNumber,
      CRMRequestDateTime,
      CRMClientIDRREF,
      CRMClientGUID,
      CRMClientFIO,
      CMRContractNumber,
      CMRContractDateTime,
      CMRContractFIO,
      CMRRequestNumber,
      CMRRequestDateTime,
      CMRRequestFIO,
      MFOContractIDRREF,
      MFOContractGUID,
      MFORequestIDRREF,
      MFORequestGUID,
      CRMRequestIDRREF,
      CRMRequestGUID,
      CMRContractIDRREF,
      CMRContractGUID,
      CMRRequestIDRREF,
      CMRRequestGUID,
      CRM_Фамилия,
      CRM_Имя,
      CRM_Отчество,
      LKContractID,
      LKRequestID,
      LKUserId
  )
  select 
	MFOContractNumber,
    MFOContractDateTime,
    MFOContractFIO,
    MFORequestNumber,
    MFORequestDateTime,
    MFORequestFIO,
    CRMRequestNumber,
    CRMRequestDateTime,
    CRMClientIDRREF,
    CRMClientGUID,
    CRMClientFIO,
    CMRContractNumber,
    CMRContractDateTime,
    CMRContractFIO,
    CMRRequestNumber,
    CMRRequestDateTime,
    CMRRequestFIO,
    MFOContractIDRREF,
    MFOContractGUID,
    MFORequestIDRREF,
    MFORequestGUID,
    CRMRequestIDRREF,
    CRMRequestGUID,
    CMRContractIDRREF,
    CMRContractGUID,
    CMRRequestIDRREF,
    CMRRequestGUID,
    CRM_Фамилия,
    CRM_Имя,
    CRM_Отчество,
    LKContractID,
    LKRequestID,
    LKUserId
  --INTO dbo.ClientReferences
  FROM cubes.v_ClientReferences

END 

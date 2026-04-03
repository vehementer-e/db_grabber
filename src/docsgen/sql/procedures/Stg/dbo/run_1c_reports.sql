-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[run_1c_reports];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[run_1c_reports]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

exec dbo.OfficeStructureMFO_1C
EXEC [dbo].[P_Aux_OfficeMFO_1c]
EXEC [dbo].[P_Aux_OfficesOfPartnersMFO_1c]
EXEC [dbo].[P_Aux_UserRoleMFO_1c]

--exec  [dbo].[P_Aux_RequestTransitionOnStatuses]

--EXEC [dbo].[P_Aux_RequestMFO_1c]
--EXEC [dbo].[P_Aux_LoanMFO_1c]
--exec  [dbo].[P_Aux_PaymentReceiptCMR_1c]
--exec  [dbo].[P_Aux_CreditPortfMFO_1c]


--exec  [dbo].[P_Aux_VerificationRepMFO_1c] 
--exec  [dbo].[P_Aux_ApprovalTakeRateMFO_1c] 


--EXEC [dbo].[P_Main_LoanRequestMFO_1c]
--exec  [dbo].[P_Main_KPIMFO_1c]
--exec  [dbo].[P_Main_CollectingPaymentReceiptCMR_1c]
--exec dbo.P_Main_VerificationRepMFO_1c



--exec  [dbo].[P_Aux_Region_RequestLoan_PovolzhMFO_1c] 
--exec  [dbo].[P_Aux_Region_RequestLoan_UralMFO_1c]
--exec  [dbo].[P_Aux_Region_RequestLoan_SouthernMFO_1c]  
--exec  [dbo].[P_Aux_Region_RequestLoan_PovolzhMFO_1c] 
--exec  [dbo].[P_Aux_Region_RequestLoan_NorthWestMFO_1c] 
--exec  [dbo].[P_Aux_Region_RequestLoan_CentrMFO_1c]


END

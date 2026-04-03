





-- =============================================
-- Author:		Orlov A.
-- Create date: 2019-07-03
-- Description:	<Description,,>
-- =============================================
CREATE    PROCEDURE [bki].main_bki
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


exec bki.tmp_xml
exec [bki].[Main_parser]
exec [bki].normalization


end



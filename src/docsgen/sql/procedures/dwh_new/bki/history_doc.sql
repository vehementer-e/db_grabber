
CREATE PROCEDURE [bki].[history_doc]
	-- Add the parameters for the stored procedure here
	@idoc int, @doc xml, @response_date datetime,  @external_id nvarchar(20), @flag_correct int, @rn int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

--history_doc
SELECT    *  ,@external_id external_id ,@flag_correct flag_correct, @rn rn, @response_date response_date
FROM       OPENXML (@idoc, '/bki_response/response/title_part/private/history_title/doc',2)
with (doctype int,
	  docno nvarchar(100),
	  docdate varchar(10),
	  docplace nvarchar(500))

END

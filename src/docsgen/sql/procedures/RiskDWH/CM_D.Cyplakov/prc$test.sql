CREATE procedure [CM\D.Cyplakov].[prc$test]
as

SET NOCOUNT ON
SET XACT_ABORT ON

declare @src_name nvarchar(100);

set @src_name = 'TEST_PRC';

begin try

	exec RiskDWH.[CM\D.Cyplakov].prc$set_debug_info @src = @src_name ,@info = 'START';


	begin transaction;
	
	insert into RiskDWH.[CM\D.Cyplakov].test_tbl
	select 123;

	commit transaction;

	exec RiskDWH.[CM\D.Cyplakov].prc$set_debug_info @src = @src_name ,@info = 'FINISH';

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.[CM\D.Cyplakov].prc$set_debug_info @src = @src_name ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
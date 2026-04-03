create   proc [dbo].[message]
@text nvarchar(max) = 'message'
as
begin


set  @text = format( getdate(), 'yyyy-MM-dd HH:mm:ss') + ' '+@text
;
RAISERROR(@text,0,0) WITH NOWAIT





end
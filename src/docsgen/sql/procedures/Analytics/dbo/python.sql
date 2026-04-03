 CREATE proc [dbo].[python]  		    @command  nvarchar(max) = null ,  @wait int =0, @result nvarchar(max) = null output
as exec [exec_python]  @command ,  @wait , @result  output
 

--exec [dbo].[CheckExistScoreForDokredy]

CREATE   procedure  [dbo].[CheckExistScoreForDokredy]
as
begin
	

	declare @error_description nvarchar(4000)=N''
	declare @text nvarchar(max)=N''

	Declare @tsql nvarchar(max)
	Declare @dt_created date 
	Declare @isActual int 

	set @text='Маркетинговые предложения. Проверяем готовность витрины скоринга CheckExistScoreForDokredy' +format(getdate(),'dd.MM.yyyy HH:mm:ss')
	EXEC [LogDb].dbo.SendToSlack_dwhNotification  @text
	exec [log].[LogAndSendMailToAdmin] 'trying CheckExistScoreForDokredy','Info','procedure started',N''
begin try

	
	Set @tsql = 'select @isActual = iif(isnull(max(created_at),''1990-01-01'')=cast(GetDate() as date),1,0) from dwh_new.[dbo].for_scoring with(nolock) '
	

	EXEC sp_executesql 
		@tsql, 
		N'@isActual INT OUTPUT',
		@isActual = @isActual OUTPUT; 
	if (@isActual=0)
	begin 
		RAISERROR ('Данные не актуальны', 16, 1)
	end
	else
	select 'ok'

	set @text=':heavy_check_mark: Маркетинговые предложения. Данные для витрины скоринга актуальны.' +format(getdate(),'dd.MM.yyyy HH:mm:ss')
	EXEC logdb.dbo.SendToSlack_dwhNotification  @text

	exec [log].[LogAndSendMailToAdmin] 'Маркетинговые предложения. Проверка витрины скоринга CheckExistScoreForDokredy завершена','Info','procedure finished',N''

end try
begin catch

	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

	set @text=':exclamation: Маркетинговые предложения. Данные витрины скоринга CheckExistScoreForDokredy не актуальны. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		EXEC  [LogDb].dbo.SendToSlack_dwhNotification  @text

	exec [log].[LogAndSendMailToAdmin] 'Маркетинговые предложения. Данные витрины скоринга CheckExistScoreForDokredy не актуальны','Error','Error',@error_description
	-- выходим с исключением
	;throw 51000, @error_description, 1

end catch

end --while



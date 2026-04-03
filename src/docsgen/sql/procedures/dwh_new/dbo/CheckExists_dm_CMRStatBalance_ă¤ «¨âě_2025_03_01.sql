
CREATE   PROC dbo.CheckExists_dm_CMRStatBalance
as
begin
	declare @error_description nvarchar(4000)=N''
	declare @text nvarchar(max)=N''
	DECLARE @isOk int
	DECLARE @t_result table
	(
		StartTime datetime,
		EndTime datetime,
		durationTime time,
		TotalActiveContractOnToday bigint,
		TotalRowOnTodayInCMRStatBalance bigint,
		AllTotalRowInCMRStatBalance bigint,
		isOk int,
		JsonResult varchar(max)
	)

	set @text='Проверяем готовность витрины dm_CMRStatBalance. ' + format(getdate(),'dd.MM.yyyy HH:mm:ss')
	EXEC [LogDb].dbo.SendToSlack_dwhNotification  @text
	exec [log].[LogAndSendMailToAdmin] 'trying CheckExists_dm_CMRStatBalance','Info','procedure started',N''
BEGIN try

	INSERT @t_result
	(
		StartTime,
		EndTime,
		durationTime,
		TotalActiveContractOnToday,
		TotalRowOnTodayInCMRStatBalance,
		AllTotalRowInCMRStatBalance,
		isOk,
		JsonResult
	)
	EXEC LogDb.dbo.Monitoring_dm_CMRStatBalance

	SELECT @isOk = R.isOk FROM @t_result AS R

	IF (isnull(@isOk, 0) = 0)
	BEGIN
		RAISERROR ('Данные витрины dm_CMRStatBalance не актуальны', 16, 1)
	END
	ELSE BEGIN
		SELECT 'ok'
	END

	set @text=':heavy_check_mark: Данные витрины dm_CMRStatBalance актуальны. ' +format(getdate(),'dd.MM.yyyy HH:mm:ss')
	EXEC logdb.dbo.SendToSlack_dwhNotification  @text
	exec [log].[LogAndSendMailToAdmin] 'Проверка витрины dm_CMRStatBalance завершена','Info','procedure finished',N''
end try
begin catch

	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

	set @text=':exclamation: Данные витрины dm_CMRStatBalance не актуальны. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
	EXEC  [LogDb].dbo.SendToSlack_dwhNotification  @text
	EXEC [log].[LogAndSendMailToAdmin] 'Данные витрины dm_CMRStatBalance не актуальны','Error','Error',@error_description

	-- выходим с исключением
	;throw 51000, @error_description, 1

end catch

end




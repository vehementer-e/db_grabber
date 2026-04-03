




CREATE   PROCEDURE [finAnalytics].[loadPA_step4] 
		@repmonth date,
		@reservInserted int out
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = 'ПА. Процедура добавления Резервов'
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
	declare @emailList varchar(255)=''

   begin try
   begin tran  

   set @reservInserted = 0

	/*Этап 4. Добавление резервов*/
	delete from dwh2.[finAnalytics].[PA_Reserv] where repmonth = @repmonth
	insert into dwh2.[finAnalytics].[PA_Reserv]
	([repmonth], [dogNum], [reservOD_NU], [reservPRC_NU], [reservOther_NU], [reservOD_BU], [reservPRC_BU], [reservPenya_BU])

	select
	[repmonth]
	, [dogNum]
	, [reservOD_NU] = a.reservOD
	, [reservPRC_NU] = a.reservPRC
	, [reservOther_NU] = a.reservProchSumNU

	, [reservOD_BU] = a.reservBUODSum
	, [reservPRC_BU] = a.reservBUpPrcSum
	, [reservPenya_BU] = a.reservBUPenyaSum
	from dwh2.finAnalytics.PBR_MONTHLY a
	where a.REPMONTH = @repmonth
	and (
			a.reservOD !=0
		or  a.reservPRC != 0
		or  a.reservProchSumNU != 0
		or  a.reservBUODSum != 0
		or  a.reservBUpPrcSum != 0
		or  a.reservBUPenyaSum != 0
		)

	set @reservInserted = @@ROWCOUNT

   commit tran
   end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END





CREATE   PROCEDURE [finAnalytics].[loadPA_step3] 
		@repmonth date,
		@restsInserted int out
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = 'ПА. Процедура добавления остатков'
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
	declare @emailList varchar(255)=''

   begin try
   begin tran  

   set @restsInserted = 0

	/*Этап 3. Добавление остатков*/
	delete from dwh2.[finAnalytics].[PA_Rests] where repmonth = @repmonth
	insert into dwh2.[finAnalytics].[PA_Rests]
	([repmonth], [dogNum], [restOD_OUT], [restPRC_OUT], [restPenya_OUT], [restGP_OUT], [restsODAVG])

	select
	[repmonth]
	, [dogNum]
	, [restOD_OUT] = a.zadolgOD
	, [restPRC_OUT] = a.zadolgPrc
	, [restPenya_OUT] = a.penyaSum
	, [restGP_OUT] = a.gosposhlSum
	, [restsODAVG] = a.dayRestAVG
	from dwh2.finAnalytics.PBR_MONTHLY a
	where a.REPMONTH = @repmonth
	and (
			a.zadolgOD !=0
		or  a.zadolgPrc != 0
		or  a.penyaSum != 0
		or  a.gosposhlSum != 0
		or  a.reservOD != 0
		or  a.dayRestAVG != 0
		)

	set @restsInserted = @@ROWCOUNT

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

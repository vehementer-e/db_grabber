


CREATE   PROCEDURE [finAnalytics].[loadPA_step1] 
		@repmonth date,
		@dogInserted int out
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = 'ПА. Процедура обновления списка договоров'
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
	declare @emailList varchar(255)=''

   begin try
   begin tran  

   set @dogInserted = 0

	/*Этап 1. Добавление договоров*/
	merge into dwh2.[finAnalytics].[PA_DOG] t1
	using
	(
	select
	[Договор] = pbr.dogNum
	,[Договор GIUD CMR] = cmr.Ссылка

	from(
	select
	distinct 
	dogNum
	from dwh2.finAnalytics.PBR_MONTHLY a
	where a.REPMONTH = @repmonth
	) pbr
	left join stg._1cCMR.Справочник_Договоры cmr on pbr.dogNum=cmr.Код

	where cmr.Ссылка is not null
	) t2 on (t1.[dogNum] = t2.[Договор])
	when not matched then insert
	([dogNum], [dogGIUD_CMR])
	values
	(t2.[Договор],t2.[Договор GIUD CMR]);

	set @dogInserted = @@ROWCOUNT

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

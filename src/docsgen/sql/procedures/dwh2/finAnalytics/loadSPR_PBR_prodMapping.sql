





CREATE PROCEDURE [finAnalytics].[loadSPR_PBR_prodMapping] 
    
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = 'Выполнение процедуры загрузки справочника маппинга продуктов для ПБР'
       
    begin try

    delete from dwh2.[finAnalytics].[SPR_PBR_prodMapping]

  begin tran  
    
    INSERT INTO [finAnalytics].[SPR_PBR_prodMapping]
	(
	[Вид займа], [Группа каналов], [Канал (определяется по источнику заявки)], [Направление], [Продукт от первичного], [Продукт Финансы], [Продукт], [created]
	 )
     
	select
		[Вид займа]
		,[Группа каналов]
		,[Канал (определяется по источнику заявки)]
		,[Направление]
		,[Продукт от первичного]
		,[Продукт Финансы]
		,[Продукт]
		,created

	from stg.[files].[SPR_PBR_prodMapping]
	--where [Продукт] is not null

	
    commit tran

	
	--Запуск проверки маппинга Проудкта для планов
	declare @repmonth date
	set @repmonth = (select max(repmonth) from dwh2.[finAnalytics].[PBR_MONTHLY])

	declare @errorMapping int = 0
	EXEC [finAnalytics].[loadPBR_productMappingCheck] @repmonth, 'monthly', @errorMapping output
	--if @errorMapping = 1 throw 51000 , 'Ошибка проверки поля Дата выдачи', 1
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    --DECLARE @maxDateRest NVARCHAR(30)
    --set @maxDateRest = cast((select max(repmonth) from finAnalytics.SPR_Arenda) as varchar)
    

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Справочника маппинга продуктов для ПБР.'
                ,char(10)
                ,char(13)
                ,'Время начала выполнения: '
                ,@procStartTime
                ,char(10)
                ,char(13)
                ,'Время окончания выполнения: '
                ,@procEndTime
                ,char(10)
                ,char(13)
                ,'Время выполнения: '
                ,@timeDuration
                --,char(10)
                --,char(13)
                --,'Максимальная отчетная дата: '
                --,@maxDateRest
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,34))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	--финиш
     exec dwh2.finAnalytics.sys_log @sp_name,1, @sp_name

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	--кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem

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

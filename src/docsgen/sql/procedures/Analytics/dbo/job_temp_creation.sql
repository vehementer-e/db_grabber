CREATE   PROC dbo.job_temp_creation
   
AS
BEGIN 

 --exec dbo.job_temp_creation


    DECLARE @plan_start DATETIME2 = dateadd(second, 10, getdate())  
	
    -- Основная команда для выполнения
    DECLARE @command NVARCHAR(MAX) = 
        --========================
        'SELECT 1 d';
        --======================== 

    DECLARE @name_job NVARCHAR(MAX) = REPLACE(REPLACE(REPLACE(
        --========================
        '#Analytics. created: ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + ' run_at: ' + FORMAT(@plan_start, 'yyyy-MM-dd HH:mm:ss') + '|| _______________ || '+'@'+left(@command , '10')
        --========================
        ,'''', '' ),char(10), '&' ),char(13), '&' );
    
    -- Остановка и удаление предыдущих заданий с таким же именем (если необходимо)
    -- EXEC msdb.dbo.sp_stop_job @job_name = @name_job;
    --EXEC msdb.dbo.sp_delete_job @job_name = @name_job;




	    DECLARE @sql NVARCHAR(MAX);
    -- Добавляем логику задержки, если @plan_start не NULL
    IF @plan_start IS NOT NULL
    BEGIN
        DECLARE @current_time DATETIME2 = GETDATE();
        
        -- Если текущее время меньше запланированного, ждем до @plan_start
        IF @current_time < @plan_start
        BEGIN
            DECLARE @wait_time INT = DATEDIFF(SECOND, @current_time, @plan_start);
            SET @sql = 'WAITFOR DELAY ''' + CONVERT(VARCHAR(12), @wait_time / 3600) + ':' +
                                            RIGHT('0' + CONVERT(VARCHAR(2), (@wait_time % 3600) / 60), 2) + ':' +
                                            RIGHT('0' + CONVERT(VARCHAR(2), @wait_time % 60), 2) + ''';' + CHAR(13) + @command;
        END
        ELSE
        BEGIN
            SET @sql = @command; -- Если текущее время уже больше или равно запланированному, выполняем команду сразу
        END
    END
    ELSE
    BEGIN
        SET @sql = @command; -- Если планируемое время не указано, выполняем команду сразу
    END

    -- Формируем финальный SQL для выполнения
    SET @sql = @sql + '
'+
	'
	if  exists (select top 1 * from msdb.dbo.sysjobs where  name = ''' + @name_job + ''' ) begin
	select 1 --EXEC msdb.dbo.sp_delete_job @job_name = ''' + @name_job + ''' 
	end else EXEC log_email ''' + @name_job + ' был удален ранее??'' '+
	'
	if 1=1 or not exists (select top 1 * from msdb.dbo.sysjobs where  name = ''' + @name_job + ''' )
	begin
	EXEC log_email ''' + @name_job + ' ready'', DEFAULT, ''' + REPLACE(REPLACE(@command, '''', '$'), '-', '_') + ''' 
	end else begin EXEC log_email ''job_temp_creation fatal error'' end' 
	;
	select @sql
    -- Создаем и запускаем задание
    EXEC analytics.dbo.sp_create_job @name_job, @sql, '0';
    EXEC msdb.dbo.sp_start_job @name_job;

    -- Для отладки можно добавить вывод команды остановки джоба
    SELECT 'EXEC msdb.dbo.sp_stop_job @job_name = ''' + @name_job + '''';
END;
 



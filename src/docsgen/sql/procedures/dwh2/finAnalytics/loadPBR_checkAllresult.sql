
CREATE PROCEDURE [finAnalytics].[loadPBR_checkAllresult]
	@repmonth date
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = 'Процедура проверки месячного ПБР при загрузке'
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	declare @dateText varchar(50)=FORMAT(@repmonth, 'MMMM yyyy', 'ru-RU' ) 
	declare @subject varchar(100)
	declare @message  varchar(max)

	declare @i int= (select count(*) from #errorCount)
	
	if @i<>0
		begin
			set @message = concat('В таблице ПБР осуществлены следующие проверки:'
							,char(10)
							,char(13)
							,char(10)
							,char(13))
			while @i>0
				begin
					set @message=concat(@message,(select concat(checkName,' = ',errCount)
												from #errorCount where errNum=@i),char(10),char(13))
					set @i=@i-1
				end
		end
	
	DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Выполнение процедуры проверки ПБР за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
                ,@message
				)
	declare @emailList varchar(255)=''
   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,21))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @sp_name;
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

END

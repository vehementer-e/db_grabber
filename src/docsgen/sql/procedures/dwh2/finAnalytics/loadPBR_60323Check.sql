

CREATE PROC [finAnalytics].[loadPBR_60323Check] 
			@repmonth date

AS
BEGIN
	declare @rests60323Date date = (select max(repmonth) from finAnalytics.rests60323)
    if (@rests60323Date < @repmonth or @rests60323Date is null)
    begin
		declare @body_text2 nvarchar(MAX) = CONCAT(
                                                    'В реестре остатков 60323 максимальная дата: '
                                                    , FORMAT( eoMONTH(@rests60323Date), 'MMMM yyyy', 'ru-RU' )
                                                    ,char(10)
                                                    ,char(13)
                                                    ,'При загрузке ПБР не будут учтены корректировки даты выхода на просрочку.'
                                                    ,char(10)
                                                    ,char(13)
                                                    ,'Для корректной загрузки необходимо актуальный реестр выложить в сетевую папку и перевыгрузить ПБР.'
                                                    )
        declare @subject2  nvarchar(200)  = CONCAT('Нет данных в реестре остатков 60323 на дату загрузки ПБР: ',FORMAT( eoMONTH(@repmonth), 'MMMM yyyy', 'ru-RU' ))
		declare @emailList varchar(255)=''
		--настройка адресатов рассылки
		set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,4))
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @body_text2
			,@body_format = 'TEXT'
			,@subject = @subject2;
     end

END

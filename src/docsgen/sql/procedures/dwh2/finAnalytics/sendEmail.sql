
CREATE PROC [finAnalytics].[sendEmail]
		@subject nvarchar(255) --тема письма
		,@message nvarchar(max)-- тело письма
		,@strRcp nvarchar(50) --получатели
		,@reportUID int=0 -- номер отчета
AS
BEGIN
	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	if @reportUID>0 
		begin	
			declare @dat date =GETDATE()
			select * from dwh2.Dictionary.calendar
			declare @numDay int=(select id_day_of_month from dwh2.Dictionary.calendar where dt=@dat)
			declare @typeday int =(select iif((id_weekday not in(6,7) and isRussiaDayOff=0),0,1) from dwh2.Dictionary.calendar where dt=@dat)
			declare @interCalc int =(select interCalcDayNum from dwh2.finAnalytics.reportReglament where reportUID=@reportUID)
	
			if (@numDay<=@interCalc or @typeday=1)
				begin
				set @strRcp=replace(@strRcp,',22','')	
				set @strRcp=replace(@strRcp,'22,','')
				set @strRcp=replace(@strRcp,'22','')
				end
		end
		if len(@strRcp)>0
			begin
				set @emailList = (select STRING_AGG(email,';')
								  from finAnalytics.emailList 
								  where emailUID in (select * from string_split(@strRcp,','))
								)

				EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
						,@recipients =@emailList
						,@copy_recipients =''
						,@body =@message
						,@body_format = 'TEXT'
						,@subject =@subject;
			end

END

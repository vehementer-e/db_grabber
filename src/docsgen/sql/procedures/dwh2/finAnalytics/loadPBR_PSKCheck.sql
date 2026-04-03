



CREATE PROC [finAnalytics].[loadPBR_PSKCheck] 
				@repmonth date
				,@nameData varchar(20)
				,@errorState int output

AS
BEGIN

	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	set @errorState = 0

	set @nameData =trim(@nameData)
	drop table if Exists #Data
	create table #Data
			(
			[Номер договора] nvarchar(255)
			,[Дата Выдачи] nvarchar(255)
			,[ПСК для РВПЗ] float
			)

	declare @isEmptyPSK varchar(max) = null
	
	if @nameData='monthly'
	begin
		insert into #Data
					select 
						a.[Номер договора]
						,a.[Дата выдачи]
						,a.[ПСК для РВПЗ]
					from stg.[files].[pbr_monthly] a
					where [Признак заемщика] = 'ФЛ'
					and upper([Номенклатурная группа]) not like upper('%Самозанятых%')
					and (a.[ПСК для РВПЗ] is null or a.[ПСК для РВПЗ]=0)
					and convert(date,a.[Дата выдачи],104) <= EOMONTH(@repmonth)
					and a.Состояние != 'Закрыт'


	end



	if @nameData='weekly'
	begin

		insert into #Data
					select 
						a.[Номер договора]
						,a.[Дата выдачи]
						,a.[ПСК для РВПЗ]
					from stg.[files].[pbr_weekly] a
					where [Признак заемщика] = 'ФЛ'
					and upper([Номенклатурная группа]) not like upper('%Самозанятых%')
					and (a.[ПСК для РВПЗ] is null or a.[ПСК для РВПЗ]=0)
					and convert(date,a.[Дата выдачи],104) <= @repmonth
					and a.Состояние != 'Закрыт'
	end
			
	 
	 set @isEmptyPSK =
			(
			select isnull(STRING_AGG([Номер договора],'; '),'-')
			from #Data
			)


	 if @isEmptyPSK !='-'
		begin
			set @errorState = 1

			declare @body_text3 nvarchar(MAX) = CONCAT
				('В ПБР найдены договора ФЛ с пустым значением ПСК для РВПЗ: '
                 ,'Отчетный месяц: '
				 ,FORMAT( @repmonth, 'MMMM yyyy', 'ru-RU' )
                 ,char(10)
                 ,char(13)
                 ,'Договора: '
				 ,@isEmptyPSK
				 ,char(10)
                 ,char(13)
				 ,'Загрузка не остановлена.'
                )

			declare @subject3  nvarchar(200)  = CONCAT('В ПБР найдены договора с пустым ПСК для РВПЗ за ',FORMAT( @repmonth, 'MMMM yyyy', 'ru-RU' ))
			declare @emailList varchar(255)=''
			set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,5,31))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = @emailList
				,@copy_recipients = ''
				,@body = @body_text3
				,@body_format = 'TEXT'
				,@subject = @subject3;
     end
	 --финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

end




CREATE PROC [finAnalytics].[loadPBR_saleDateCheck] 
				@repDate date
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
	drop table if Exists #DataEmptySaleDate
	create table #DataEmptySaleDate
			(
			[Номер договора] nvarchar(255)
			,[Дата Выдачи] date
			,[Дата договора] date
			)

	drop table if Exists #DataFullSaleDate
	create table #DataFullSaleDate
			(
			[Номер договора] nvarchar(255)
			,[Дата Выдачи] date
			,[Дата договора] date
			)

	declare @isEmptySaleDate varchar(max) = null
	declare @isFullSaleDate varchar(max) = null
	
	if @nameData='monthly'
	begin
		
		----если поле "Дата Выдачи" пустое и "Дата договора" меньше отчетной даты в пределах 10 дней (включительно) и "Остаток ОД" = 0 - 
		----такие записи не загружаются в DWH.
		--delete from stg.[files].[pbr_monthly]
		--where [Дата выдачи] is null
		--	and datediff(day,CONVERT (date, [Дата договора], 104),@repDate) <=10
		--	and [Задолженность ОД] = 0 

		--если поле "Дата Выдачи" пустое и "Дата договора" меньше отчетной даты в пределах 10 дней (включительно) и "Остаток ОД" > 0 - 
		--загрузка прерывается, рассылается сообщение.

		insert into #DataEmptySaleDate 
					select 
						a.[Номер договора]
						,a.[Дата выдачи]
						,a.[Дата договора]
					from stg.[files].[pbr_monthly] a
					where 
						[Дата выдачи] is null
						and datediff(day,CONVERT (date, [Дата договора],104),@repDate) <=10
						and [Задолженность ОД] > 0 

		----если поле "Дата Выдачи" не пустое и "Дата договора" больше отчетной даты и "Остаток ОД" = 0 - 
		----такие записи не загружаются в DWH.
		--delete from stg.[files].[pbr_monthly]
		--where [Дата выдачи] is not null
		--	and CONVERT (date, [Дата договора],104) > @repDate

		--если поле "Дата Выдачи" не пустое и "Дата договора" больше отчетной даты и "Остаток ОД" > 0 - 
		--загрузка прерывается, рассылается сообщение.
		insert into #DataFullSaleDate 
					select 
						a.[Номер договора]
						,a.[Дата выдачи]
						,a.[Дата договора]
					from stg.[files].[pbr_monthly] a
					where 
						[Дата выдачи] is not null
						and CONVERT (date, [Дата договора], 104) > @repDate
						and [Задолженность ОД] > 0 

	end



	if @nameData='weekly'
	begin
		----если поле "Дата Выдачи" пустое и "Дата договора" меньше отчетной даты в пределах 10 дней (включительно) и "Остаток ОД" = 0 - 
		----такие записи не загружаются в DWH.
		--delete from stg.[files].[pbr_weekly]
		--where [Дата выдачи] is null
		--	and datediff(day,CONVERT (date, [Дата договора], 104),@repDate) <=10
		--	and [Задолженность ОД] = 0 

		--если поле "Дата Выдачи" пустое и "Дата договора" меньше отчетной даты в пределах 10 дней (включительно) и "Остаток ОД" > 0 - 
		--загрузка прерывается, рассылается сообщение.

		insert into #DataEmptySaleDate 
					select 
						a.[Номер договора]
						,a.[Дата выдачи]
						,a.[Дата договора]
					from stg.[files].[pbr_weekly] a
					where 
						[Дата выдачи] is null
						and datediff(day,CONVERT (date, [Дата договора],104),@repDate) <=10
						and [Задолженность ОД] > 0 

		----если поле "Дата Выдачи" не пустое и "Дата договора" больше отчетной даты и "Остаток ОД" = 0 - 
		----такие записи не загружаются в DWH.
		--delete from stg.[files].[pbr_weekly]
		--where [Дата выдачи] is not null
		--	and CONVERT (date, [Дата договора],104) > @repDate

		--если поле "Дата Выдачи" не пустое и "Дата договора" больше отчетной даты и "Остаток ОД" > 0 - 
		--загрузка прерывается, рассылается сообщение.
		insert into #DataFullSaleDate 
					select 
						a.[Номер договора]
						,a.[Дата выдачи]
						,a.[Дата договора]
					from stg.[files].[pbr_weekly] a
					where 
						[Дата выдачи] is not null
						and CONVERT (date, [Дата договора], 104) > @repDate
						and [Задолженность ОД] > 0 
	end
			
	 
	 set @isEmptySaleDate =
			(
			select isnull(STRING_AGG([Номер договора],'; '),'-')
			from #DataEmptySaleDate
			)

	set @isFullSaleDate = 
			(
			select isnull(STRING_AGG([Номер договора],'; '),'-')
			from #DataFullSaleDate
			)

	 if (@isEmptySaleDate!='-' or @isFullSaleDate!='-')
		begin
			set @errorState = 1

			declare @body_text3 nvarchar(MAX) = CONCAT
				('В ПБР найдены не корректные договора: '
                 ,'Отчетный месяц: '
				 ,FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' )
                 ,char(10)
                 ,char(13)
                 ,'Дата выдачи пустая + Дата договора меньше 10 дней + Остаток ОД больше 0: '
				 ,@isEmptySaleDate
                 ,char(10)
                 ,char(13)
                 ,'Дата выдачи НЕ пустая + Дата выдачи больше отчетного периода + Остаток ОД больше 0: '
				 ,@isFullSaleDate
				 ,char(10)
                 ,char(13)
				 ,'Загрузка остановлена!'
                )

			declare @subject3  nvarchar(200)  = CONCAT('В ПБР найдены не корректные договора за ',FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' ))
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

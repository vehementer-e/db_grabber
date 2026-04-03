



CREATE PROC [finAnalytics].[loadPBR_closeDateCheck] 
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
	drop table if Exists #DataCession
	create table #DataCession
			(
			[Номер договора] nvarchar(255)
			,[Признак цессии] nvarchar(5)
			,[Дата закрытия] nvarchar(50)
			,[Состояние] nvarchar(50)
			,[rowNum] int
			)

	drop table if Exists #DataTypeClose
	create table #DataTypeClose
			(
			[Номер договора] nvarchar(255)
			,[Способ закрытия обязательства] nvarchar(255)
			,[Дата закрытия] nvarchar(50)
			,[Состояние] nvarchar(50)
			,[rowNum] int
			)

	declare @isCession varchar(max) = null
	declare @isTypeClose varchar(max) = null
	
	if @nameData='monthly'
	begin
		
		--Если поле "Цессия (проданные займы)" равно "Да", то поле "Состояние" должно быть "закрыт" 
		--и поле "Дата закрыт" не пусто (содержат дату). Иначе - ошибка
		--Т.е. если [Цессия (проданные займы)] = Да и [Дата закрыт] = Пусто, то проверяем регистр цессий, 
		--есть ли по этому договору возврат. Если возврат есть, то в перечень ошибок не выводим, если нет возврата, то выводим.
		insert into #DataCession 
					select 
						a.[Номер договора]
						,a.[Цессия (проданные займы)]
						,isnull(a.[Дата закрыт],'Пусто')
						,a.[Состояние]
						,[rowNum] = ROW_NUMBER() over (Order by a.[Дата договора])
					from stg.[files].[pbr_monthly] a  --select * from stg.[files].[pbr_monthly]
					left join dwh2.[finAnalytics].[ReestrCession] b on a.[Номер договора] = b.numDogBack
					where 
						upper(a.[Цессия (проданные займы)]) = 'ДА'
						and (
							Upper(a.[Состояние]) != upper('Закрыт')
							or
							a.[Дата закрыт] is null
							)
						and b.numDogBack is null
						

		--Если поле "Способ закрытия обязательства" не пусто, то поле "Состояние" должно быть "закрыт" 
		--и поле "Дата закрыт" не пусто (содержат дату). Иначе - ошибка
		--Т.е. если [Цессия (проданные займы)] = Да и [Дата закрыт] = Пусто, то проверяем регистр цессий, 
		--есть ли по этому договору возврат. Если возврат есть, то в перечень ошибок не выводим, если нет возврата, то выводим.
		insert into #DataTypeClose
					select 
						a.[Номер договора]
						,a.[Способ закрытия обязательств]
						,isnull(a.[Дата закрыт],'Пусто')
						,a.[Состояние]
						,[rowNum] = ROW_NUMBER() over (Order by a.[Дата договора])
					from stg.[files].[pbr_monthly] a
					left join dwh2.[finAnalytics].[ReestrCession] b on a.[Номер договора] = b.numDogBack
					where 
						a.[Способ закрытия обязательств] is not null
						and (
							Upper(a.[Состояние]) != upper('Закрыт')
							or
							a.[Дата закрыт] is null
							)
						and b.numDogBack is null
						

	end

	declare @tekRow int = 1
	declare @MaxRow int = (select count(*) from #DataCession)
	
	if @MaxRow >0 
	begin

		set @isCession = concat(
												'Цессия заполнена, но Состояние или Дата закрытия не корректны:'
												,char(10),char(13)
												,char(10),char(13)
												,'[Номер договора]........[Цессия (проданные займы)]....[Дата закрыт]...........[Состояние]'
												,char(10),char(13)
												)

		while @tekRow<=@MaxRow
		begin
			set @isCession =concat(
									@isCession
									,(select string_agg(
												concat(
													a.[Номер договора]
													,'............'
													,A.[Признак цессии]
													,'...........................................'
													,a.[Дата закрытия]
													,'...........................'
													,a.Состояние
													)
									,'-')
									from #DataCession a
									where [rowNum]=@tekRow)
									,char(10),char(13)
									)
		set @tekRow=@tekRow+1
		end
	end


	set @tekRow = 1
	set @MaxRow = (select count(*) from #DataTypeClose)
	
	if @MaxRow >0 
	begin

		set @isTypeClose = concat(
												'Способ закрытия не пусто, но Состояние или Дата закрытия не корректны:'
												,char(10),char(13)
												,char(10),char(13)
												,'[Номер договора]........[Способ закрытия]........[Дата закрыт].....[Состояние]'
												,char(10),char(13)
												)

		while @tekRow<=@MaxRow
		begin
			set @isTypeClose =concat(
									@isTypeClose
									,(select string_agg(
												concat(
													a.[Номер договора]
													,'............'
													,A.[Способ закрытия обязательства]
													,'.......'
													,a.[Дата закрытия]
													,'................'
													,a.Состояние
													)
									,'-')
									from #DataTypeClose a
									where [rowNum]=@tekRow)
									,char(10),char(13)
									)
		set @tekRow=@tekRow+1
		end
	end

	declare @emailList varchar(255)=''

	if (@isCession is not null or @isTypeClose is not null)
		begin
			set @errorState = 1

			declare @body_text3 nvarchar(MAX) = CONCAT
				('В ПБР найдены не корректные данные: '
                 ,'Отчетный месяц: '
				 ,FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' )
                 ,char(10)
                 ,char(13)
				 ,char(10)
                 ,char(13)
				 ,char(10)
                 ,char(13)
                 ,@isCession
                 ,char(10)
                 ,char(13)
				 ,@isTypeClose
				 ,char(10)
                 ,char(13)
				 ,'Загрузка не остановлена!'
                )

			declare @subject3  nvarchar(200)  = CONCAT('В ПБР найдены не корректные данные за ',FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' ))
			
			set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,4,31))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = @emailList
				,@copy_recipients = ''
				,@body = @body_text3
				,@body_format = 'TEXT'
				,@subject = @subject3;
     end
	 else
	 begin

			declare @subject2  nvarchar(200)  = CONCAT('Проверка ПБР. Корректность данных Закрытия договоров за ',FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' ))
			
			set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = @emailList
				,@copy_recipients = ''
				,@body = 'Ошибок не выявлено.'
				,@body_format = 'TEXT'
				,@subject = @subject2;

	 end

	 --финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

end

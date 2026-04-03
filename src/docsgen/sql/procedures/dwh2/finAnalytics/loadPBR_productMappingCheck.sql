




CREATE PROC [finAnalytics].[loadPBR_productMappingCheck] 
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
	drop table if Exists #DataMapping
	create table #DataMapping
			(
			[Вид займа] nvarchar(50)
			,[Группа каналов] nvarchar(100)
			,[Канал (определяется по источнику заявки)] nvarchar(100)
			,[Направление] nvarchar(100)
			,[Продукт от первичного] nvarchar(100)
			,[Продукт Финансы] nvarchar(100)
			,[rowNum] int
			)

	declare @isMappingError varchar(max) = null
	
	if @nameData='monthly'
	begin
		
		insert into #DataMapping
					select
					l2.*
					,[rn] = ROW_NUMBER() over (order by [Продукт Финансы])
					from(
					select
					distinct
					[Вид займа] = l1.[Вид займа]
					,[Группа каналов] = l1.[Группа каналов]
					,[Канал (определяется по источнику заявки)] = l1.[Канал (определяется по источнику заявки)]
					,[Направление] = l1.[Направление]
					,[Продукт от первичного] = l1.[Продукт от первичного]
					,[Продукт Финансы] = l1.[Продукт Финансы]
					--,[rowNum] = ROW_NUMBER() over --(order by [Продукт Финансы])
					--,[Продукт для Планов] = 'Нет маппинга'
					from (
					select
					[Клиент] = a.Client
					,[Договор] = a.dogNum

					,[Вид займа] = a.isnew
					,[Группа каналов] = a.finChannelGroup
					,[Канал (определяется по источнику заявки)] = a.finChannel
					,[Направление] = a.finBusinessLine
					,[Продукт от первичного] = a.prodFirst
					,[Продукт Финансы] = a.productType
					,[Продукт для Планов] = map.Продукт

					from dwh2.finAnalytics.PBR_MONTHLY a
					left join dwh2.[finAnalytics].[SPR_PBR_prodMapping] map on 
								isnull(map.[Вид займа],'-') = isnull(a.isnew,'-')
								and isnull(map.[Группа каналов],'-') = isnull(a.finChannelGroup,'-')
								and isnull(map.[Канал (определяется по источнику заявки)],'-') = isnull(a.finChannel,'-')
								and isnull(map.[Направление],'-') = isnull(a.finBusinessLine,'-')
								and isnull(map.[Продукт от первичного],'-') = isnull(a.prodFirst,'-')
								and isnull(map.[Продукт Финансы],'-') = isnull(a.productType,'-')

					where 1=1
					and repmonth = @repDate
					and a.isZaemshik = 'ФЛ'
					and a.saleDate >= '2025-01-01'
					) l1
					where l1.[Продукт для Планов] is null
					) l2
	end

	declare @tekRow int = 1
	declare @MaxRow int = (select count(*) from #DataMapping)
	
	if @MaxRow >0 
	begin

		set @isMappingError = concat(
												'В ПБР есть кейсы, не найденные в справочнике Маппинга "Продукта для планов": '
												,char(10),char(13)
												,char(10),char(13)
												,'[Вид займа]........[Группа каналов]....[Канал].....[Направление].....[Продукт от первичного]..[Продукт Финансы]'
												,char(10),char(13)
												)

		while @tekRow<=@MaxRow
		begin
			set @isMappingError =concat(
									@isMappingError
									,(select string_agg(
												concat(
													a.[Вид займа]
													,'........'
													,A.[Группа каналов]
													,'.................'
													,a.[Канал (определяется по источнику заявки)]
													,'.....'
													,a.[Направление]
													,'.....'
													,a.[Продукт от первичного]
													,'..'
													,a.[Продукт Финансы]
													)
									,'-')
									from #DataMapping a
									where [rowNum]=@tekRow)
									,char(10),char(13)
									)
		set @tekRow=@tekRow+1
		end
	end

	declare @emailList varchar(255)=''

	if @isMappingError is not null
		begin
			set @errorState = 1

			declare @body_text3 nvarchar(MAX) = CONCAT
				('Ошибка Маппинга "Продукта для планов": '
                 ,'Отчетный месяц: '
				 ,FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' )
                 ,char(10)
                 ,char(13)
				 ,char(10)
                 ,char(13)
				 ,char(10)
                 ,char(13)
                 ,@isMappingError
				 ,char(10)
                 ,char(13)
				 ,'Загрузка не остановлена!'
                )

			declare @subject3  nvarchar(200)  = CONCAT('В ПБР найдены кейсы, отсутсвующие в справочнике маппинга продуктов, за ',FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' ))
			
			set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,34))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = @emailList
				,@copy_recipients = ''
				,@body = @body_text3
				,@body_format = 'TEXT'
				,@subject = @subject3;
     end
	 else
	 begin

			declare @subject2  nvarchar(200)  = CONCAT('Проверка ПБР. Корректность Маппинга продуктов за ',FORMAT( @repDate, 'MMMM yyyy', 'ru-RU' ))
			
			set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,34))
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

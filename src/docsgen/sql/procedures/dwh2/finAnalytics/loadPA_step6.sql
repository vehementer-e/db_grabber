





CREATE   PROCEDURE [finAnalytics].[loadPA_step6] 
		@repmonth date,
		@dopParamInserted int out
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = 'ПА. Процедура добавления доп параметров Договоров'
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
	declare @emailList varchar(255)=''

   begin try
   begin tran  

   set @dopParamInserted = 0

	/*Этап 6. Добавление доп параметров*/
	drop table if exists #rep
		CREATE TABLE #rep(
			[dogNum] [nvarchar](50) NOT NULL,
			[isnew] [nvarchar](100) NULL,
			[finChannelGroup] [nvarchar](100) NULL,
			[finChannel] [nvarchar](100) NULL,
			[finBusinessLine] [nvarchar](100) NULL,
			[productType] [nvarchar](100) NULL,
			[prodFirst] [nvarchar](100) NULL,
			[RBP_GR] [nvarchar](100) NULL
		)

		merge into #rep t1
		using(
			select
			[dogNum] = b.Номер
			,[isnew] = b.returnType
			,[finChannelGroup] = b.finChannelGroup
			,[finChannel] = b.finChannel
			,[finBusinessLine] = b.finBusinessLine
			,[productType] = b.productType
			,[RN] = ROW_NUMBER() over (Partition by b.Номер order by b.Номер)
			from [Analytics].dbo.[v_fa] b
			inner join dwh2.[finAnalytics].[PA_DOG] a on a.[dogNum] = b.Номер
		) t2 on (t1.dogNum=t2.dogNum and t2.rn=1)
		when not matched then insert
		([dogNum],[isnew],[finChannelGroup],[finChannel],[finBusinessLine],[productType])
		values
		(t2.[dogNum],t2.isnew,t2.finChannelGroup,t2.finChannel,t2.finBusinessLine,t2.productType);

		merge into #rep t1
		using(
			select distinct
				l1.dogNum
				,l1.prod
				--,l1.subprod
				,dogRN =  ROW_NUMBER() over (Partition by l1.client order by l1.dogDate)
				from(
				select 
					dogNum = cldog.КодДоговораЗайма
					--,prod = case 
					--				when dog.ТипПродукта in ('ПТС31') then 'ПТС'
					--				when dog.ТипПродукта in ('Смарт-инстоллмент','Инстоллмент') then 'Installment'
					--				when dog.ПодТипПродукта in ('ПТС (Автокред)') then 'Автокредит'
					--				when dog.ПодТипПродукта in ('ПТС Займ для Самозанятых') then 'ПТС для Самозанятых'
					--				else dog.ТипПродукта
					--				end
					,prod = dwh2.[finAnalytics].[nomenk2prod](dog.ПодТипПродукта)
					,subprod = dog.ПодТипПродукта
					,dogDate = dog.ДатаДоговораЗайма--cast(dog.ДатаДоговораЗайма as date)
		--			,dogCloseDate = cast(dog.ДатаЗакрытияДоговора as date)
					,cldog.GuidКлиент
					,[client] = concat(
								cl.Наименование
								,' '
								,format(cl.ДатаРождения,'dd.MM.yyyy')
								)
				from dwh2.link.Клиент_ДоговорЗайма cldog
				inner join dwh2.hub.ДоговорЗайма dog on dog.КодДоговораЗайма = cldog.КодДоговораЗайма
				inner join dwh2.hub.Клиенты cl on cl.GuidКлиент = cldog.GuidКлиент
				inner join dwh2.[finAnalytics].[PA_DOG] a on a.[dogNum] = cldog.КодДоговораЗайма
				where dog.isDelete = 0
				) l1
				where l1.prod is not null
		) t2 on (t1.[dogNum]=t2.[dogNum] and t2.dogRN = 1)
		when matched then update
		set t1.[prodFirst] = t2.prod
		when not matched then insert
		([dogNum],[prodFirst])
		values
		(t2.[dogNum],t2.prod);


		merge into #rep t1
		using(
				 select
				 [НомерЗаявки]
				 ,RBP_GR
				 from(
				 select 
				 [НомерЗаявки]
				 ,RBP_GR
				 ,rn = row_Number() over (Partition by [НомерЗаявки] order by created_at)
				  from dwh2.dm.ЗаявкаНаЗаймПодПТС
				  inner join dwh2.[finAnalytics].[PA_DOG] a on a.[dogNum] = [НомерЗаявки]
				  where [НомерЗаявки] is not null
				  and RBP_GR is not null
				  ) l1
				  where l1.rn =1
			) t2 on ( t1.dogNum = t2.[НомерЗаявки]) 
		when matched then update
		set t1.[RBP_GR] = t2.RBP_GR
		when not matched then insert
		([dogNum],[RBP_GR])
		values
		(t2.[НомерЗаявки],t2.RBP_GR);
	
	merge into dwh2.[finAnalytics].[PA_ParamDop] t1
	using(
	select 
	[dogNum]
	,[isnew] = max([isnew])
	,[finChannelGroup] = max([finChannelGroup])
	,[finChannel] = max([finChannel])
	,[finBusinessLine] = max([finBusinessLine])
	,[productType] = max([productType])
	,[prodFirst] = max([prodFirst])
	,[RBP_GR] = max([RBP_GR])
	from #rep
	group by [dogNum]
	) t2 on (t1.[dogNum] = t2.[dogNum])
	when not matched then insert
	([dogNum], [isnew], [finChannelGroup], [finChannel], [finBusinessLine], [productType], [prodFirst], [RBP_GR])
	values
	(t2.[dogNum], t2.[isnew], t2.[finChannelGroup], t2.[finChannel], t2.[finBusinessLine], t2.[productType], t2.[prodFirst], t2.[RBP_GR]);


	set @dopParamInserted = @@ROWCOUNT

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

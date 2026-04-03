--проверка "Залог обеспечен автотранспортным средством"
--Цель - выявлять НЕпостановку на внебалансовый учет залога ТС.
--Проверять, что поле Продукт заполнено (не пусто) по всем займам под залог ПТС и Автокредитам 
--Продукт определять по номенклатурной группе в ПБР

--При возврате пустой выборки сообщать группе 1 "Проверка "Наличие залога поручительства" нет ошибок.

--При возврате не пустой выборки сообщать группе 1,2,31 "Проверка "Наличие залога поручительства" есть ошибки" + приложить список из скрипта.

CREATE PROC [finAnalytics].[checkPTSAutocredit] 
	@repmonth date
	,@errorCount int output
AS
BEGIN
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc
	
	declare @dateText varchar(50)=FORMAT(@repmonth, 'MMMM yyyy', 'ru-RU' ) 
	declare @sbjHeader varchar(250) =concat( 'Проверка поля "Наличие залога поручительства" в ПБР за " '
											,@dateText)
	declare @subject varchar(250)
	-- переменные для формирования текста сообщения
	declare @msgHeader varchar(max)=concat('Результат проверки поля "Наличие залога поручительства" в ПБР за " '
											,@dateText,char(10),char(13))
	declare @msgFloor varchar(max) =concat('Отработала процедура: ',@sp_name)
	declare @message varchar(max)

	declare @countRow int =0
	declare @resultTab table (
			numDog varchar (510)
			,groupName varchar(510) 
			,isDogPoruch nvarchar(510)
			,id int)
	insert into @resultTab
		select
			[Номер договора] = a.[Номер договора]
			,[Продукт] = b.[groupName]
			,[Наличие залога поручительства] = a.[Наличие залога поручительства]
			--,[Дата выдачи] = a.[Дата выдачи]
			,id=row_number() over(order by a.[Номер договора])
		from  stg.[files].[PBR_MONTHLY] a
		left join dwh2.finanalytics.nomenkGroup b on a.[Номенклатурная группа]=b.[UMFONames]
		where 1=1
		  	and b.[groupName] in ('ПТС','Автокредит')
			and a.[Наличие залога поручительства] is null
			--Добавлен отбор только выданных до отчетной даты кредитов
			and convert(date,a.[Дата выдачи],104) <= EOMONTH(@repmonth)
	set @countRow=(select count(*) from	@resultTab)
	set @errorCount =(select count(*) from	@resultTab)

	if @countRow <>0
		begin
			declare @i int=0
			set @message =concat(@msgHeader,char(10))
			while @i<=@countRow
				begin
					set @message =concat(@message
										,(select concat(numDog,'--',groupName)
										 from @resultTab
										 where id=@i)
										,char(10),char(13))
					set @i=@i+1
				end
			set @subject=concat('Ошибка!',@sbjHeader)	
			set @message=concat(@message,@msgFloor)
			exec finAnalytics.sendEmail @subject ,@message,@strRcp ='1,2,31,4'
	    end   
	else 
		begin
			set @subject=concat('OK!',@sbjHeader)
			set @message=concat(@msgHeader,' ошибок не найдено',char(10),char(13))
			set @message=concat(@message,@msgFloor)
			exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
		end
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

END

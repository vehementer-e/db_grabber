CREATE PROCEDURE [finAnalytics].[checkZaim]
	@tableName varchar(20)
	,@repmonth date
	,@errorCount int output
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

	declare @dateText varchar(50)=FORMAT(@repmonth, 'MMMM yyyy', 'ru-RU' ) 
	declare @subject varchar(100)
	-- переменные для формирования текста сообщения
	declare @text varchar(20) = 'месячного'
	if @tableName='weekly'
		set @text='недельного'
 
	
	declare @sbjHeader varchar(100)= concat('Проверка таблицы ',@text,' ПБР за ',@dateText)
	declare @msgHeader varchar(max)=concat('Результат проверки ',@text,' ПБР за ',@dateText, ':',char(10))
		
	declare @message varchar(max)
	declare @msgFloor varchar(255)=concat('Отработала процедура: ',@sp_name) 
	
	declare @result table (
			numDog varchar(255)
			,nomenkGroup varchar(510)
			,dogStatus varchar(510)
			,id int
			)
	declare @i int=0
	
	if @tableName='weekly'
		insert into @result 
			select 
				l1.[Номер договора]
				,isnull(l1.[Номенклатурная группа],'Пусто')
				,l1.[Состояние]
				,id=row_number() over(order by l1.[Номер договора])
			from
			(select [Номер договора],[Номенклатурная группа],[Состояние]
			from stg.[files].[PBR_weekly]
			where ([Способ выдачи займа] is null or [Способ выдачи займа]='')
			) l1
	
	if @tableName='monthly'
		insert into @result 
			select 
				l1.[Номер договора]
				,isnull(l1.[Номенклатурная группа],'Пусто')
				,l1.[Состояние]
				,id=row_number() over(order by l1.[Номер договора])
			from
			(select [Номер договора],[Номенклатурная группа],[Состояние]
			from stg.[files].[PBR_monthly]
			where ([Способ выдачи займа] is null or [Способ выдачи займа]='')
			) l1
	set @i =(select count(*) from @result)
	set @errorCount =(select count(*) from @result)

	if @i<>0
		begin
			set @subject = concat('Внимание! ',@sbjHeader)
			set @message = concat(@msgHeader, 'В таблице ПБР'
							,' есть пустые записи в столбце [Способ выдачи займа]',char(10)
							,'по следующим договорам:',char(10))
			while @i>0
				begin
					set @message=concat(@message,(select concat(numDog,'   ',nomenkGroup,'   ',dogStatus)
												from @result where id=@i),char(10),char(13))
					set @i=@i-1
				end
			set @message=concat(@message,@msgFloor)
			exec finAnalytics.sendEmail @subject = @subject,@message =@message,@strRcp ='1,2,31,5,6,4'
		end

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc
END

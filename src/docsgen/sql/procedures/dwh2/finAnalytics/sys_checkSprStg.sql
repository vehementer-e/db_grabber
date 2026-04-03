
/*Процедура проверки таблиц STG используемых проверяемой 
	процедурой @procName(входной параметр) на соответствие справочнику полей STG ФинДепа 
	по полям и типам данных. Справочник STG ФинДепа - SYS_SPR_stgSchema
Входной параметр @procName: имя хранимой процедуры со схемой данных, без символов "[]"! 
Используемые базы данных:
	dwh2, stg
Используемые таблицы данных:
	SYS_SPR_stgSchema - таблица на основе которой осуществляютс проверка
	SYS_SPR_stg - таблица справочник таблиц STG
	SYS_SPR_stgprc - таблица справочник соответсвия таблиц STG и хранимых процедур/отчетов ФинДеп

Проверка1. Если в используемых таблицах STG в процедуре @procName 
	появляется новое поле - поле добавляется в справочник SYS_SPR_stgSchema 
Проверка2. Если в используемых таблицах STG в процедуре @procName 
	изменяется тип данных поля - изменяется тип данных этого поля в справочнике SYS_SPR_stgSchema
Важно!:для использование данной хранимой процедуры необходимо наличичие актуализировать 
			информацию о используемых таблицах STG по проверяемой процедуре @procName:
			* в справочнике SYS_SPR_stg 
			* в справочнике SYS_SPR_stgprc 
Блок рассылки. При проверке процедуре @procName: 
				* если есть изменения в связанных процедурах STG,то отправляются сообщения
					с описаниями этих измений на почту по eamilUID =1
				* если нет изменений ни в одной из связанных таблиц STG, отправляется сообщение OK 

			*/

CREATE PROC [finAnalytics].[sys_checkSprStg]
	@procName nvarchar(255) 
AS
BEGIN
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	declare @sbjHeader varchar(20) = 'STG проверка таблиц: '
	declare @subject varchar(100)
	-- переменные для формирования текста сообщения
	declare @msgHeader varchar(max)=concat('Результат проверки используемых процедурой: ['
										,@procName,'] столбцов таблиц схемы "STG"',char(10))
	declare @msgFloor varchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message varchar(max)
	--проверям присутвие @procName в справочнике SYS_SPR_stgprc если нет -сообщение 
	if (select count(*) from SYS_SPR_stgprc a  where a.prc=@procName) =0
		begin
			set @subject = concat('Внимание! ',@sbjHeader,@procName,' отсутвует информация')
			set @message = concat(@msgHeader, 'В таблице SYS_SPR_stgprc отсутвует запись по этой процедуре/отчету')
			exec finAnalytics.sendEmail @subject = @subject,@message =@message,@strRcp = '1'
			goto ext
		end
		
	-- переменную выбираются все таблицы связанные с этой процедурой  
	declare @tableStg table
			(
			stgname nvarchar(255)
			,stgshema nvarchar(20)
			,number int 
			)
	--переменная таблица накопления ошибок
	declare @errorTable table (name nvarchar(100))
	
	--в табличную переменую @tableStg вносятся данные о всех таблицах STG которые связанны с 
	--с хранимой процедурой @procName
	insert into @tableStg 
				select 
					tStg.stgname
					,tStg.stgshema 
					,number=row_number() over( order by tStg.stgshema desc)
				from SYS_SPR_stgprc as tProc
				inner join SYS_SPR_stg as tStg on tProc.stg_id=tStg.stg_id
				where tProc.prc=@procName
	
	--временная таблица для сохранения результат выборки структуры таблиц STG
	drop table if exists #Schm 
	create table #Schm(
			table_name nvarchar(50)
			,column_name nvarchar(100)
			,data_type nvarchar(20)
			)
	--временная таблица для сохранения результата проверки присутвия наименование столбцов
	drop table if exists #checkSchm 
	create table #checkSchm(
			table_name nvarchar(50)
			,column_name nvarchar(100)
			,data_type nvarchar(20)
			,number int
			,old_type nvarchar(20) default ''
			)

	--переменная отвечает за за главный цикл программы для перебора всех связанных с этой процедурой
	--таблиц STG
	declare @i int = (select count(*) from @tableStg)
	--set @i=2--заглушка
	--переменная сохраняет кол-во выявленных несоответствий имен столбцов в справочнике 
	--SYS_SPR_stgShema и проверяемой таблице STG 
	declare @checkColumn_name int = 0
	
	--переменная сохраняет кол-во выявленных несоответствий типов данных в справочнике 
	--SYS_SPR_stgShema и проверяемой таблице STG 
	declare @checkData_type int = 0
	
	--переменная отвечает за цикл формирования тела сообщения рассылки программы
	declare @j int = 0
	
	--переменная будет хранит текущую схему
	declare @currentSchm nvarchar(255)
	--переменная будет хранит текущую таблицу
	declare @currentTable nvarchar(255)
			
	while @i>0
		begin
			-- инициализируем переменные перед началом очередной итерации
			set @checkColumn_name = 0
			set @checkData_type = 0
			set @j=0
			-- очищаем временные таблицы перед началом очередной итерации
			truncate table #checkSchm
			truncate table #Schm
			---
			--- в переменным присваиваем текущие на итерации имена схемы и таблицы
			set @currentSchm =(select stgshema from @tableStg where number=@i)
			set @currentTable=(select stgname from @tableStg where number=@i)
			insert into #Schm		
				select
					table_name
					,column_name
					,data_type
				from stg.[INFORMATION_SCHEMA].columns with (nolock)
				where
				Table_schema=@currentSchm 	and Table_name=@currentTable

			-- Проверка 1
			-- проверям справочник схемы таблиц SYS_SPR_stgSchema на присутвие
			-- проверяем по полю table_name(название таблицы) и column_name(название столбцов)
			-- если есть расхождение -добавляем новые столбцы в SYS_SPR_stgSchema
			-- далее отправляем сообщение
			--finAnalytics].[SYS_SPR_stgSchema](
			
			insert into #checkSchm
			select 
				Schm.table_name
				,Schm.column_name
				,Schm.data_type
				,number=row_number() over(order by Schm.column_name)
				,''
			from #Schm as Schm
			left join SYS_SPR_stgSchema as sysSchm on Schm.table_name=sysSchm.table_name 
														and Schm.column_name=sysSchm.column_name
			where sysSchm.table_name is null
			-- сохраняем в переменную кол-во найденых новых столбцов
			select 	@checkColumn_name=count(*) from #checkSchm				

		   if @checkColumn_name<>0		
		   -- добавляем новые строки в таблицу SYS_SPR_stgSchema
			insert into SYS_SPR_stgSchema
				(table_name,column_name,data_type,dateCreate)
				select 
					table_name
					,column_name
					,data_type
					,getdate()
				from #checkSchm
		-- отправляем сообщения
			if @checkColumn_name<>0
				begin
					--добавляет тип ошибки в errorTable
					insert into @errorTable select 'column'
					set @message =concat(
									@msgHeader
									,'В таблице [',@currentSchm,'.',@currentTable
									, '] есть новые столбцы:'
									,char(10)
									)

					while @j<=@checkColumn_name
						begin
							set @message =concat(
												@message
												,(select string_agg(concat(column_name,'.....',data_type)
																	,';')
												  from #checkSchm
												  where number=@j)
												,char(10),char(13)
												)
							set @j=@j+1
							end
					set @subject =concat('Внимание! ',@sbjHeader,@procName,' Есть новые столбцы')	
					exec finAnalytics.sendEmail @subject = @subject,@message =@message,@strRcp = '1'					
				end
	
			set @message =''
			
			-- Проверка 2
			-- проверям справочник схемы таблиц SYS_SPR_stgSchema на соответвие типа столбцов
			-- проверяем table_name(название таблицы) и column_name(название столбцов) и data_type(тип данных в столбцах)
			-- если есть расхождение -редактируем тип столбцов(data_type) в таблице SYS_SPR_stgSchema
			-- далее отправляем сообщение об изменении типа
			set @j=0
			truncate table #checkSchm
			
			insert into #checkSchm
			select 
				Schm.table_name
				,Schm.column_name
				,Schm.data_type
				,number=row_number() over(order by Schm.column_name)
				,''
			from #Schm as Schm
			left join SYS_SPR_stgSchema as sysSchm on Schm.table_name=sysSchm.table_name 
													  and Schm.column_name=sysSchm.column_name
													  and Schm.data_type=sysSchm.data_type
			where sysSchm.table_name is null
			-- сохраняем в переменную кол-во найденых столбцов с иземенным типом данных
			select 	@checkData_type=count(*) from #checkSchm				
		
			if @checkData_type<>0
				--добавляет тип ошибки в errorTable
				insert into @errorTable select 'type'
				-- заполняем столбец old_type  #checkSchm прошлыми значениями data_type
				begin
					update #checkSchm
					set	#checkSchm.old_type=B.data_type
					from #checkSchm as A
					inner join SYS_SPR_stgSchema as B on A.table_name=B.table_name 
													and A.column_name=B.column_name
				-- изменеия таблицы SYS_SPR_stgSchema
				-- изменеяем строки в столбце тип данных (data_type) на новый тип данных
					update SYS_SPR_stgSchema
					set	SYS_SPR_stgSchema.data_type=B.data_type
					from SYS_SPR_stgSchema as A
					inner join #checkSchm as B on A.table_name=B.table_name 
													and A.column_name=B.column_name
				end
			--select * from #checkSchm
			if @checkData_type<>0
				begin
					set @message =concat(
						@msgHeader
						,'В таблице [',@currentSchm,'.',@currentTable
						, '] изменился тип данных столбцов:'
						,char(10)
						)
					while @j<=@checkData_type
						begin
							set @message =concat(
												@message
												,(select string_agg(concat(column_name,'[',old_type,']>>>',data_type)
																	,';')
												  from #checkSchm
												  where number=@j)
												,char(10),char(13)
												)
						set @j=@j+1
						end
				 set @subject=concat('Внимание! ',@sbjHeader,@procName,' Изменился тип данных столбцов')	
				 exec finAnalytics.sendEmail @subject =@subject,@message =@message,@strRcp = '1'					
				 end
		set @message =''
		set @i=@i-1
	end
	if (select count(*) from @errorTable)=0 
		begin
			set @subject =concat('OK! ',@sbjHeader,@procName)	
			set @message='Расхождений в структуре не найдено'
			set @message = concat(@msgHeader,@message,@msgFloor)
			exec finAnalytics.sendEmail @subject = @subject,@message =@message,@strRcp = '1'
		end
ext:
---select @checkColumn_name as 'Найдено новых столбцов'
---select @checkData_type as 'Найдено столбцов с измененым типом данных'
END





CREATE PROC [finAnalytics].[add_Sys_checkSprStg]
		@shema nvarchar(200)--схема размещения таблицы
		,@table nvarchar(200) --название таблицы
		,@prc nvarchar(200)-- название процедуры
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	declare @subjectHeader  nvarchar(250) ='Новая таблица в проверке', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Добавление новой таблицы в проверку ',getdate(),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
 begin try	
  begin tran 
	declare @check varchar(5), @id int 
	-- проверка наличия таблицы в схеме 
	set @check =iif( exists (select * from stg.[INFORMATION_SCHEMA].columns with (nolock)
			where Table_schema=@shema and 	table_name=@table),1,0) 

	if @check =1
		begin
			-- определям структуру таблицы и добавлем записи структуры этой таблицы в SYS_SPR_stgSchema 	
			insert into dwh2.finAnalytics.SYS_SPR_stgSchema (table_name,column_name,data_type,dateCreate)
			select
				table_name=table_name
				,column_name=column_name
				,data_type=data_type
				,dateCreate=cast(getdate() as date)
			from stg.[INFORMATION_SCHEMA].columns with (nolock)
			where Table_schema=@shema and 	table_name=@table	
			-- добавлем запись об этой таблице  в SYS_SPR_stg
			insert into dwh2.finAnalytics.SYS_SPR_stg (stgname,stgshema)
			values (@table,@shema)
			set @id=(select max(stg_id) from dwh2.finAnalytics.SYS_SPR_stg )
			-- добавлем запись по процедуре в таблицу SYS_SPR_stgprc
			insert into dwh2.finAnalytics.SYS_SPR_stgprc (stg_id,prc)
			values (@id,@prc)
	
			set @subject=concat('',@subjectHeader) 
			set @message=concat('Таблица: ',@table,char(10),'Процедура: ',@prc,char(10),'Ок!')
			set @message=concat(@msgHeader,@message,@msgFloor)
			exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
		end
	 else 
		begin
			set @subject='Ошибка!'
			set @message=concat('Таблица: ',@table,' в схеме: ',@shema,' - не найдена')
			set @message=concat(@msgHeader,@message,@msgFloor)
			exec finAnalytics.sendEmail @subject,@message ,@strRcp = '1'
		end 
	commit tran
	end try 

 begin catch
    ROLLBACK TRANSACTION
	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
   ;throw 51000 
			,@message
			,1;    
  end catch
END

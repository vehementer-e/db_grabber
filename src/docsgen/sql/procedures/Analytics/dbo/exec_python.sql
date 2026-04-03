CREATE   proc [dbo].[exec_python]
		    @command  nvarchar(max) = null ,  @wait int =0, @result nvarchar(max) = null output
as

 begin

	declare @datebegin datetime =  getdate() 
	declare @datecur datetime =  getdate() 

	if @command IS NOT NULL

	begin

declare @id uniqueidentifier = newid()
	insert into 	dbo.[python_commands] (id, command, created)
    values	(@id, @command, GETDATE())

	if @wait=1 begin

	while exists(  select top 1 * from python_commands where id=@id and endTime is null   )
	begin
	set @datecur = getdate()

	if  @datecur>dateadd(hour, 1, @datebegin ) 
	begin
	 RAISERROR ('PYTHON ВЫПОЛНЯЕТ КОМАНДУ БОЛЬШЕ ЧАСА', -- Message text.
               16, -- Severity.
               1 -- State.
               );
	
	return 
	end
	waitfor delay  '00:00:05'
	 end


	 waitfor delay  '00:00:05'
		 
		 IF not exists(  select top 1 * from python_commands where id=@id and endTime is not null AND STATUS='ok')
		 begin
		 declare @err    Nvarchar(max) =  (select top 1  command +'

'+isnull( exc_traceback, 'PYTHON ERROR') from python_commands where id=@id ) 
--RAISERROR (@err    , -- Message text.
--               16, -- Severity.
--               1 -- State.
--               );

; THROW 50000, @err, 1

			   end
	 END



	 END

 --select command_output from python_commands where id=@id 
	set @result   = (select command_output from python_commands where id=@id)



--drop table if exists dbo.[python_commands]
--SELECT NEWID() id
--,cast('execute_sql("exec log_email ''Привет из PYTHON''")' AS NVARCHAR(max)) command
--,getdate() created
--,cast(null AS datetime) startTime
--,cast(null AS datetime) endTime
--,cast(null AS NVARCHAR(max)) command_output
--,cast(null AS NVARCHAR(max)) exc_traceback
--,cast(null AS NVARCHAR(max)) status
--into dbo.[python_commands]
--
--
--with v as ( select top  (4) * from python_commands_view
--order by len(command) desc
--)
--select * from v
--delete   from v


	end

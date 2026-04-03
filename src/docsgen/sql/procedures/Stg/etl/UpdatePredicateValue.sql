-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[UpdatePredicateValue] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [etl].[UpdatePredicateValue]
	@TableName nvarchar(max),
	@DataBaseName nvarchar(max) = 'STG',
	@ProcessGUID nvarchar(36) =  null
as
declare @error_msg nvarchar(255) 
declare @sp_name nvarchar(255)  = OBJECT_NAME(@@PROCID)
declare @tableFullName nvarchar(255)  = Concat(ISNULL(@DataBaseName, 'STG'), '.', @TableName)
begin try
	--select format(isnull((select max(isnull(updated_at, created_at)) from _LK.contracts), '2000-01-01') ,'yyyy-MM-dd HH:mm:ss')
	
	if not exists(select top(1) 1 from etl.PredicateValue where TableName =  @tableFullName)
	begin 
		set @error_msg  = Concat('Таблица ', @tableFullName, ' не найдена')
		;throw 51000, @error_msg, 16
	end
	declare @value nvarchar(255) 
	declare @sqlCommandGet nvarchar(max)
	declare @ColumnName nvarchar(255) 
	select top(1) @sqlCommandGet = concat('select @value = 
	', case 
		when ValueType in ('datetime') then concat('format(max(', ColumnName, ')', ',''yyyy-MM-dd HH:mm:ss''', ')')
		else concat('cast(max(', ColumnName, ')', ' as ',  ValueType, ')') 
		end
		 ,' from ', TableName)
		,@ColumnName = ColumnName
	from etl.PredicateValue where TableName = @tableFullName
	
	print @sqlCommandGet 
	begin tran

	EXECUTE sp_executesql 
		@sqlCommandGet, N'@value nvarchar(255) out', 
		@value =@value out
	print @value
	if @value is not null
	begin
		update etl.PredicateValue 
			set Value = @value
			,updated_at = getdate()
			,ProcessGUID = @ProcessGUID
			where TableName = @tableFullName
	end
	else
	begin
		set @error_msg  = concat('Значение для поля ', lower(@tableFullName), '.', UPPER(@ColumnName), 
		 ' не установлено т.к не определено')
		;throw 51001, @error_msg, 16
	end
		
		
	commit tran
	--declare @message nvarchar(max) = concat('Значение для поля ', lower(@tableFullName), '.', UPPER(@ColumnName), 
	--	 ' установлено значение ', @value)
	--exec LogDb.dbo.SendToSlack_DwhAdminNotofications @message
	
end try
begin catch
	iF @@TRANCOUNT>0
		ROLLBACK TRAN
	set @error_msg = Concat('Ошибка обработки таблицы - ', lower(@tableFullName), '.', UPPER(@ColumnName) , '; процедура ', @sp_name, '; msg',  ERROR_MESSAGE())
	if ERROR_NUMBER() in (51000, 51001)
	begin		
		exec LogDb.dbo.SendToSlack_DwhAlerts @error_msg
	end
	else
	begin
		exec LogDb.dbo.SendToSlack_DwhAlarm @error_msg;
	end
end catch
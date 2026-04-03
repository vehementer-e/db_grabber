--
/*
select distinct linkName, [TargetColName] from link.ЗаявкаНаЗаймПодПТС_stage

update link.ЗаявкаНаЗаймПодПТС_stage
	set TargetColName = 'GuidВидЗаполненияЗаявокНаЗаймПодПТС'
where linkName ='link.ВидЗаполненияЗаявокНаЗаймПодПТС_Заявка'
 select * from link.ЗаявкаНаЗаймПодПТС_stage
 where [GuidЗаявки]='edeedec1-b281-463a-95e4-605ec88d82d0'
 and LinkGuid = '1a30753c-6385-11e8-a2b7-00155d941906'
 select * from link.ВидЗаполненияЗаявокНаЗаймПодПТС_Заявка 
 where  [GuidЗаявки]='edeedec1-b281-463a-95e4-605ec88d82d0'

/*
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.CRMАвтор_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.ВариантыПредложенияСтавки_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.ВидЗаполненияЗаявокНаЗаймПодПТС_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.КредитныйПродукт_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.МаркиАвтомобилей_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.МоделиАвтомобилей_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.Клиент_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.ПричиныОтказов_Заявка'
exec link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other 'link.ТекущийСтатус_Заявка'
*/
*/
--


CREATE PROC link.fill_link_between_ЗаявкаНаЗаймПодПТС_and_other
	 @LinkName nvarchar(255)
as
begin
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @tableName nvarchar(255) = @LinkName
	declare @msg_error nvarchar(255)
	if OBJECT_ID(@tableName) is null
	begin
		set @msg_error = concat('таблица ', @tableName, ' не найдена')
		;throw 51000, @msg_error, 16
	end

	drop table if exists #t_2Insert
	select top(0)
		Id					
		,GuidЗаявки			
		,ВерсияДанныхЗаявки  
		,LinkGuid			
		,TargetColName
		,created_at
	into #t_2Insert
	from  link.ЗаявкаНаЗаймПодПТС_stage
	insert into #t_2Insert
	(
		Id					
		,GuidЗаявки			
		,ВерсияДанныхЗаявки  
		,LinkGuid
		,TargetColName
		,created_at
	)
	select 
		Id					
		,GuidЗаявки			
		,ВерсияДанныхЗаявки  
		,LinkGuid	
		,TargetColName
		,created_at
	from link.ЗаявкаНаЗаймПодПТС_stage
	where LinkName = @LinkName
	
	
	if exists(Select top(1) 1 from #t_2Insert)
	begin
		declare @TargetColName nvarchar(255) =( select top(1) trim(TargetColName) from #t_2Insert)
		if nullif(@TargetColName,'') is null
		begin
			set @msg_error = 'Название колонки для связи не определено'
			;throw 51000, @msg_error, 16
		end
		declare @cmd_merge nvarchar(max) =
			concat('merge ', @tableName, ' t '
			,char(10) + char(13)
			,' using (
			select 
				GuidЗаявки,
				LinkGuid,
				[created_at]  = getdate(),
				updated_at = getdate()
			from (
					select distinct
						GuidЗаявки,
						LinkGuid,
						nRow = ROW_NUMBER() over(partition by GuidЗаявки order by created_at desc)
					from #t_2Insert
					) s
				where s.nRow = 1
			) s
			on	s.[GuidЗаявки] =  t.[GuidЗаявки]
			when not matched then insert (
				[GuidЗаявки]
				,', @TargetColName, '
				,created_at
				,updated_at)
			values
			(
				s.GuidЗаявки,
				s.LinkGuid
				,s.created_at
				,s.updated_at
			)
			when matched and t.' , @TargetColName, '<> s.LinkGuid
				then update 
				set ', @TargetColName, ' = s.LinkGuid
					,updated_at = getdate()
			;')
		print @cmd_merge
		begin tran
			exec (@cmd_merge)
		commit tran

		delete t from link.ЗаявкаНаЗаймПодПТС_stage t
		where exists(select top(1) 1 from #t_2Insert s where s.Id = t.Id)
	end
end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch
end

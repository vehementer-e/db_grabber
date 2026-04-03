--exec hub.fill_Collection_collectingStage
CREATE   PROC hub.fill_Collection_collectingStage
	--@mode int = 1
as
begin
	--truncate table hub.Collection_collectingStage
begin TRY
	--SELECT @mode = isnull(@mode, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)

	drop table if exists #t_Collection_collectingStage

	select distinct 
		GuidCollection_collectingStage = try_cast(hashbytes('SHA2_256', cast(Collection_collectingStage.Id as varchar(30))) AS uniqueidentifier),
		Collection_collectingStage.Id,
		Collection_collectingStage.Name,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_Collection_collectingStage
	from Stg._Collection.collectingStage AS Collection_collectingStage

	if OBJECT_ID('hub.Collection_collectingStage') is null
	begin
		select top(0)
			GuidCollection_collectingStage,
			Id,
			Name,
			created_at,
			updated_at,
			spFillName
		into hub.Collection_collectingStage
		from #t_Collection_collectingStage

		alter table hub.Collection_collectingStage
			alter column GuidCollection_collectingStage uniqueidentifier not null

		ALTER TABLE hub.Collection_collectingStage
			ADD CONSTRAINT PK_Collection_collectingStage PRIMARY KEY CLUSTERED (GuidCollection_collectingStage)
	end
	
	--begin tran
		merge hub.Collection_collectingStage t
		using #t_Collection_collectingStage s
			on t.GuidCollection_collectingStage = s.GuidCollection_collectingStage
		when not matched then insert
		(
			GuidCollection_collectingStage,
			Id,
			Name,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidCollection_collectingStage,
			s.Id,
			s.Name,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched 
			--and t.ВерсияДанных !=s.ВерсияДанных
			--OR @mode = 0
		then update SET
			t.Id = s.Id,
			t.Name = s.Name,
			--t.created_at = s.created_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			;
	--commit tran

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

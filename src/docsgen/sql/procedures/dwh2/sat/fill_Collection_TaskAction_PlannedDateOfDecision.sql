/*
exec sat.fill_Collection_TaskAction_PlannedDateOfDecision
	@mode = 1
	,@Id = 1469
	--,@DealId = null
	,@isDebug = 1

exec sat.fill_Collection_TaskAction_PlannedDateOfDecision
	@mode = 1
	--,@Id = 1469
	,@DealId = 9683
	,@isDebug = 1

exec sat.fill_Collection_TaskAction_PlannedDateOfDecision
*/
create   PROC sat.fill_Collection_TaskAction_PlannedDateOfDecision
	@mode int = 1
	,@Id int = null
	,@DealId int = null
	,@isDebug int = 0
as
begin
	--truncate table sat.Collection_TaskAction_PlannedDateOfDecision
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	--declare @updated_at datetime = '1900-01-01'
	

	SELECT @mode = isnull(@mode, 1)

	if OBJECT_ID ('sat.Collection_TaskAction_PlannedDateOfDecision') is not null
		AND @mode = 1
		and @Id is null
		and @DealId is null
	begin
		set @rowVersion = isnull((select max(RowVersion) from sat.Collection_TaskAction_PlannedDateOfDecision), 0x0)
	end

	drop table if exists #t_Collection_TaskAction_PlannedDateOfDecision

	select distinct
		GuidCollection_TaskAction = try_cast(hashbytes('SHA2_256', cast(t.Id as varchar(30))) AS uniqueidentifier),

		t.Id,
		t.PlannedDateOfDecision,

		t.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_Collection_TaskAction_PlannedDateOfDecision
	FROM Stg._Collection.TaskAction AS t
	where 1=1
		and t.RowVersion > @rowVersion
		and (t.Id = @Id or @Id is null)
		and (t.DealId = @DealId or @DealId is null)
		and t.PlannedDateOfDecision is not null

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_TaskAction_PlannedDateOfDecision
		SELECT * INTO ##t_Collection_TaskAction_PlannedDateOfDecision FROM #t_Collection_TaskAction_PlannedDateOfDecision
		--RETURN 0
	END

	if OBJECT_ID('sat.Collection_TaskAction_PlannedDateOfDecision') is null
	begin
		select top(0)
            GuidCollection_TaskAction,
			Id,
			PlannedDateOfDecision,
			RowVersion,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.Collection_TaskAction_PlannedDateOfDecision
		from #t_Collection_TaskAction_PlannedDateOfDecision

		alter table sat.Collection_TaskAction_PlannedDateOfDecision
			alter column GuidCollection_TaskAction uniqueidentifier not null

		ALTER TABLE sat.Collection_TaskAction_PlannedDateOfDecision
			ADD CONSTRAINT PK_Collection_TaskAction_PlannedDateOfDecision PRIMARY KEY CLUSTERED (GuidCollection_TaskAction)
	end
	
	--begin tran

		merge sat.Collection_TaskAction_PlannedDateOfDecision t
		using #t_Collection_TaskAction_PlannedDateOfDecision s
			on t.GuidCollection_TaskAction = s.GuidCollection_TaskAction
		when not matched then insert
		(
            GuidCollection_TaskAction,
			Id,
			PlannedDateOfDecision,
			RowVersion,

            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
            s.GuidCollection_TaskAction,
			s.Id,
			s.PlannedDateOfDecision,
			s.RowVersion,

            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND t.RowVersion <> s.RowVersion
		then update SET
			t.Id = s.Id,
			t.PlannedDateOfDecision = s.PlannedDateOfDecision,
			t.RowVersion = s.RowVersion,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
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

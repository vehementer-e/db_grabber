-- =============================================
-- Author:		А.Никитин
-- Create date: 2025-07-27
-- Description:	
-- =============================================
/*
EXEC Reports.collection.Report_СудебноеПроизводство
	@Page = 'Detail'
	,@dtFrom = '2024-11-01'
	,@dtTo = '2024-12-10'

*/
create   PROC collection.Report_СудебноеПроизводство
	@Page nvarchar(100) = 'Detail'
	,@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @dt_from date, @dt_to date

	IF @dtFrom is not NULL BEGIN
		SET @dt_from = @dtFrom
	END 
	ELSE BEGIN
		--SET @dt_from = cast(format(getdate(),'yyyyMM01') AS date)	         
		SET @dt_from = cast(dateadd(DAY, -1, getdate()) AS date)
	END

	IF @dtTo is not NULL BEGIN
		IF @dtTo > cast(getdate() AS date) BEGIN
			SELECT @dtTo = cast(getdate() AS date)
		END

		SET @dt_to = dateadd(day,1,@dtTo)
		--SET @dt_to = @dtTo
	END
	ELSE BEGIN
		--SET @dt_to = dateadd(day,1,cast(getdate() as date))
		SET @dt_to = cast(getdate() as date)
	END 

	DROP TABLE IF EXISTS #t_Collection_СудебноеПроизводство

	SELECT d.* 
	into #t_Collection_СудебноеПроизводство
	from dwh2.dm.Collection_СудебноеПроизводство as d
	where 1=1
		and d.[Дата принятия к производству] between @dt_from AND @dt_to

	
	DROP TABLE IF EXISTS #t_Detail

	-- последний ИЛ - по MaxEnforcementOrdersId

	select t.*
	into #t_Detail
	from (
			select 
				d.*,
				rn = row_number() over(
					partition by GuidCollection_TaskAction, GuidCollection_JudicialProceeding
					order by d.EnforcementOrdersId desc
				)
			from #t_Collection_СудебноеПроизводство as d
		) as t
	where t.rn = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Detail
		SELECT * INTO ##t_Detail FROM #t_Detail
	END

	IF @Page = 'Detail' BEGIN
		SELECT top 20000 D.*
		FROM #t_Detail AS D
		--ORDER BY D.BKI_NAME, D.INSERT_DAY

		RETURN 0
	END
	--// 'Detail'


END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC Risk.Report_dashboard_BKI_NEW ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Risk.Report_dashboard_BKI_NEW',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
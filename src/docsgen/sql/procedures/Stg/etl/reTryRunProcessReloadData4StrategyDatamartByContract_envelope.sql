--перезапуск заданий на по ReloadData4StrategyDatamartByContract за сегодня
/*
	update etl.ReloadData4Contract
		set StatusCode = 'New'
	where ProcessGUID = 'DC95838A-5DED-45CC-AAC7-FD62DA8E3B04'
	etl.reTryRunProcessReloadData4StrategyDatamartByContract_envelope @processGUID = '1DC95838A-5DED-45CC-AAC7-FD62DA8E3B04'

select *
	from etl.ReloadData4Contract
		where cast(CreatedAt as date) = cast(getdate() as date)
		and  ProcessType = 'ReloadData4StrategyDatamartByContract'
			and StatusCode IN ('Error', 'New')
			
*/

-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[reTryRunProcessReloadData4StrategyDatamartByContract_envelope]
--      @processGUID = null,
--      @whaitCompleted = 1,
--      @timeOut = 40,
--      @reTryCount = 10;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC [etl].[reTryRunProcessReloadData4StrategyDatamartByContract_envelope]
	@processGUID nvarchar(36) = null
	,@whaitCompleted bit = 1
	,@timeOut smallint = 40
	,@reTryCount smallint = 10
as
begin


	set @processGUID = nullif(@processGUID,'')
	begin try
		select top(1) @processGUID = processGUID from etl.ReloadData4Contract
		where ProcessType in('ReloadData4StrategyDatamartByContract')
			and StatusCode IN ('Error', 'New')
			and cast(CreatedAt as date) = cast(getdate() as date)
			and (processGUID = @processGUID or @processGUID is null)
			and isnull(reTryCount,0) < @reTryCount
			--and (StatusCode = 'Error' or (StatusCode in ('New') and cast(CreatedAt as time) < '05:30'))
			--and isnull(StatusDesc,'') not like '%нет доступного маретингового предложения%'
			
		order by CreatedAt desc
		print @processGUID

		if @processGUID is not null
		begin
			exec [etl].[reTryRunProcessContractUpdate] @processGUID
		end
		declare @StartTime datetime = getdate()
		while 1=1 and @whaitCompleted = 1 and @processGUID is not null
		begin
			
			if datediff(minute,  @StartTime, getdate()) >= @timeOut
			begin
				--вышли по timeOut
				declare @errorMsg  nvarchar(255)= concat('Превышен timeOut(',@timeOut, ' минут) ожидания выполнения операции для процесса ', @processGUID)
				;throw 51000, @errorMsg, 16
				break;
			end
			WAITFOR DELAY '00:00:15'
			if exists(select top(1) 1 from etl.ReloadData4Contract
				where processGUID = @processGUID
				and UPPER(StatusCode) in (Upper('NEW'), Upper('InProgress'))
				)
			begin
				continue;
			end
			else 
				break;
		end
		
	end try
	begin catch
		if @@TRANCOUNT>0
		rollback tran
	;throw
	end catch
end

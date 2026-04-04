--перезапуск заданий на по contractFullRepayment за сегодня
--[etl].[reTryRunProcessContractFullRepayment_envelope] @processGUID = '17F70DDA-207F-43C4-88B4-CB0413852298'
-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[reTryRunProcessContractFullRepayment_envelope]
--      @processGUID = null,
--      @whaitCompleted = 1,
--      @timeOut = 10,
--      @reTryCount = 10;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE     procedure [etl].[reTryRunProcessContractFullRepayment_envelope]
	@processGUID nvarchar(36) = null
	,@whaitCompleted bit = 1
	,@timeOut smallint = 10
	,@reTryCount smallint = 10
as
begin

	set @processGUID = nullif(@processGUID,'')
	begin try
		select top(1) @processGUID = processGUID from etl.ReloadData4Contract
		where (processGUID = @processGUID or @processGUID is null)
			and isnull(reTryCount,0) <@reTryCount
			and ProcessType = 'contractFullRepayment'
			and (StatusCode = 'Error' or (StatusCode in ('New') and cast(CreatedAt as time) < '10:00'))
			and isnull(StatusDesc,'') not like '%нет доступного маретингового предложения%'
			and cast(CreatedAt as date) = cast(getdate() as date)
			and (cast(getdate() as date) !='2025-01-31') --31/01 сбой
		order by CreatedAt desc
		print @processGUID

		if @processGUID is not null
		begin
			exec [etl].[reTryRunProcessContractUpdate] @processGUID
		end
		declare @StartTime datetime = getdate()
		while 1=1 and @whaitCompleted = 1 and @processGUID is not null
		begin
			
			if datediff(minute,  @StartTime, getdate()) >= 10
			begin
				--вышли по timeOut
				declare @errorMsg  nvarchar(255)= concat('Превышен timeOut(',@timeOut, 'минуте) ожидания выполнения операции для процесса ', @processGUID)
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

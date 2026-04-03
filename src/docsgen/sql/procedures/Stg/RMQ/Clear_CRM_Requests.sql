-- Usage: запуск процедуры с параметрами
-- EXEC [RMQ].[Clear_CRM_Requests] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE procedure [RMQ].[Clear_CRM_Requests]
	@dd int =10
as
begin
	declare @Total int =0,
		@i int=1;

		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages_CRM_Requests
			WHERE 
			[ReceiveDate] < =cast(dateadd(dd, -@dd, getdate()) as date) 
			--order by 1 --desc

			select @i=@@ROWCOUNT

			SET @Total = @Total + @i
	while @i>0
	begin
		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages_CRM_Requests
			WHERE 
			[ReceiveDate] < =cast(dateadd(dd, -@dd, getdate()) as date)
			--order by 1 --desc

			select @i=@@ROWCOUNT

			SET @Total = @Total + @i
	end
end

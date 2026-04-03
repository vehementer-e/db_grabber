CREATE procedure Rmq.Clear_ReceivedMessages
	@dd int =10
as
begin
	declare @Total int =0,
		@i int=1;

		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages
			WHERE 
			[ReceiveDate] < =dateadd(dd, -@dd, dateadd(day,1-day(getdate()),getdate())) 
			--order by 1 --desc

			select @i=@@ROWCOUNT

			SET @Total = @Total + @i
	while @i>0
	begin
		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages
			WHERE 
			[ReceiveDate] < =dateadd(dd, -@dd, dateadd(day,1-day(getdate()),getdate())) 
			--order by 1 --desc

			select @i=@@ROWCOUNT

			SET @Total = @Total + @i
	end
end

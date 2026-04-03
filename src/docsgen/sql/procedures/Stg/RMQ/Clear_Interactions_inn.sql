
CREATE PROC [RMQ].[Clear_Interactions_inn]
	@dd int = 3
as
begin
	declare @Total int =0,
		@i int=1;

		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages_interactions_inn
			WHERE 
				([ReceiveDate] < =cast(dateadd(dd, -@dd, getdate()) as date) and [isDeleted]  =1
				)			--order by 1 --desc
				or [ReceiveDate] < =cast(dateadd(dd, -@dd*10, getdate()) as date) --или записи старше 30дней

			select @i=@@ROWCOUNT
			
			SET @Total = @Total + @i
	while @i>0
	begin
		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages_interactions_inn
			WHERE 
			([ReceiveDate] < =cast(dateadd(dd, -@dd, getdate()) as date) and [isDeleted]  =1 )
				or [ReceiveDate] < =cast(dateadd(dd, -@dd*10, getdate()) as date) --или записи старше 30дней
			--order by 1 --desc

			select @i=@@ROWCOUNT

			SET @Total = @Total + @i
	end
end

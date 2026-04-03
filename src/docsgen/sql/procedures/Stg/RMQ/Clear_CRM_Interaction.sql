CREATE   procedure [RMQ].[Clear_CRM_Interaction]   
	@dd int =10
as
begin
	declare @Total int =0,
		@i int=1;

		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages_CRM_Interaction   
			WHERE 
			[ReceiveDate] < =cast(dateadd(dd, -@dd, getdate()) as date)
			--order by 1 --desc

			select @i=@@ROWCOUNT
			
			SET @Total = @Total + @i
	while @i>0
	begin
		DELETE top (50000) 
			--select top (50000)  *
			FROM RMQ.ReceivedMessages_CRM_Interaction   
			WHERE 
			[ReceiveDate] < =cast(dateadd(dd, -@dd, getdate()) as date)
			--order by 1 --desc

			select @i=@@ROWCOUNT

			SET @Total = @Total + @i
	end
end

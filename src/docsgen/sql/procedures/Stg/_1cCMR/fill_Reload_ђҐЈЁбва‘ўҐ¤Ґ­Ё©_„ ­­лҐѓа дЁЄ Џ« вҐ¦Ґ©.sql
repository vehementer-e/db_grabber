-- Usage: запуск процедуры с параметрами
-- EXEC [_1cCMR].[fill_Reload_РегистрСведений_ДанныеГрафикаПлатежей];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   procedure [_1cCMR].[fill_Reload_РегистрСведений_ДанныеГрафикаПлатежей]
as 
begin
	drop table if exists #t
	select  distinct 
		ReceiveDate,
		FromHost,
		FromHostVirtualHost,
		FromExchange,
		FromQueueRoutingKey,
		FromQueue,
		guid_id,
		guid,
		id
	
	into #t
	from (

	select top(30)
		ReceiveDate,
		FromHost,
		FromHostVirtualHost,
		FromExchange,
		FromQueue,
		FromQueueRoutingKey,
		ReceivedMessage,
		guid_id


		from   [RMQ].[ReceivedMessages_cmr_contracts] rm with(nolock)
  
	where ReceiveDate>= cast(getdate() as date)
	and FromExchange = 'cmr.contracts.1'
	and ISJSON(ReceivedMessage) >0 
--	and isDeleted = 0
	) t
	outer apply OPENJSON (ReceivedMessage, N'$.data')
	with
	(
		guid nvarchar(36) N'$.guid',
		id bigint			'$.id'

	)  json_data
	if exists(select top(1) 1 from #t)
	begin
		set xact_abort on
		begin tran
			delete from _1cCMR.Reload_РегистрСведений_ДанныеГрафикаПлатежей
			insert into _1cCMR.Reload_РегистрСведений_ДанныеГрафикаПлатежей(guid, id, InsertedDt)
			select distinct guid, id, getdate() as InsertedDt from #t
	
		
		--update rm 
		--	set isDeleted = 1
		delete rm
		from #t t
		inner join  [RMQ].[ReceivedMessages_cmr_contracts] rm with(rowlock) 
			 on t.guid_id = rm.guid_id
		

		commit tran

	end
end
 

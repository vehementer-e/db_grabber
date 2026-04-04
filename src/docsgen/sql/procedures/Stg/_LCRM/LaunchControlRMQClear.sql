--new 27.07.2020
--exec [_LCRM].[LaunchControlRMQClear]
-- Usage: запуск процедуры с параметрами
-- EXEC [_LCRM].[LaunchControlRMQClear];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE  procedure [_LCRM].[LaunchControlRMQClear]
as

begin


set nocount on 

DECLARE  @strcount varchar(1024);

-- Удалим все данные из очереди, кроме последних 7-ми дней до 23:00 (время создания backup базы MySQL)
-- так как данные получаем в виде бэкапа таблицы LCRM MySQL
-- дополнительные дни на случай ошибки создания backup MySQL

exec [LogDb].[dbo].[LogAndSendMailToAdmin] 'c2-vsr-dwh Clear RMQ dwh.LCRM.GOEST.Sync.LaunchControlTable
 LCRM data','Info','Procedure to clear RMQ LCRM  launch control data started', 'Procedure to clear RMQ LCRM launch control data started'


declare @Total int =0,
		@i int=1;


DELETE top (50000) 
			--SELECT count(*)
			--FROM [RMQ].[ReceivedMessages]   
			FROM RMQ.ReceivedMessages_LCRM_GOEST_Sync_LaunchControlTable with(readpast)
			WHERE [ReceiveDate] < dateadd(day,-3,cast(getdate() as date))
			select @i=@@ROWCOUNT 
while @i>0
	begin
		begin tran

			DELETE top (50000) 
			--SELECT count(*)
			--FROM [RMQ].[ReceivedMessages]   
			FROM RMQ.ReceivedMessages_LCRM_GOEST_Sync_LaunchControlTable
			WHERE FromQueue ='dwh.LCRM.GOEST.Sync.LaunchControlTable'  and [ReceiveDate] < dateadd(hour, 23, cast(dateadd(day,-3,cast(getdate() as date)) as datetime2))

			select @i=@@ROWCOUNT

			SET @Total = @Total + @i

		commit tran 
		--
		WAITFOR DELAY '00:00:01'; 
	end

SET @strcount = 'Clear RMQ LCRM launch control old data. Rows deleted: ' + cast(@Total as varchar)




--delete  FROM [RMQ].[ReceivedMessages]
--where  FromQueue='velab.dwh.CollectionInteractionResult'


--SELECT @strcount
exec [LogDb].[dbo].[LogAndSendMailToAdmin] 'c2-vsr-dwh Clear RMQ dwh.LCRM.GOEST.Sync.LaunchControlTableLCRM data','Info','Procedure to clear RMQ launch control data finished',  @strcount

end






CREATE PROCEDURE [finAnalytics].[PBI_PDN_buckets]

	
AS
BEGIN

drop table if exists #sprPDNBucket
create table #sprPDNBucket(
	--[sprName] nvarchar(100) not null,
	[buckID] int not null,
	[buckName] nvarchar(100) not null
	--[startNum] float not null,
	--[endNum] float not null
)

--Insert into #sprPDNBucket values ('Основной',1,'в т.ч. ПДН <=50%',0,0.5)
--Insert into #sprPDNBucket values ('Основной',2,'в т.ч. ПДН >50% и <=80%',0.5,0.8)
--Insert into #sprPDNBucket values ('Основной',3,'в т.ч. ПДН >80%',0.8,999999999999)
--Insert into #sprPDNBucket values ('Основной',4,'в т.ч. без ПДН (до 10 тыс.руб.)',-1,0)

Insert into #sprPDNBucket values (1,'ПДН <=50%')
Insert into #sprPDNBucket values (2,'ПДН >50% и <=80%')
Insert into #sprPDNBucket values (3,'ПДН >80%')
--Insert into #sprPDNBucket values (4,'без ПДН (до 10 тыс.руб.)')
Insert into #sprPDNBucket values (4,'без ПДН (до10 тыс.рублей и НТ)')
Insert into #sprPDNBucket values (5,'без ПДН (Самозанятые)')


select
*
from #sprPDNBucket

END

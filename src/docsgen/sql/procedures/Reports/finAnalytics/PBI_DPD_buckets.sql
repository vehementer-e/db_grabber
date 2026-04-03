





CREATE PROCEDURE [finAnalytics].[PBI_DPD_buckets]

	
AS
BEGIN

drop table if exists #sprDPDBucket
create table #sprDPDBucket(
	[sprName] nvarchar(100) not null,
	[buckID] int not null,
	[buckName] nvarchar(100) not null,
	[startNum] int not null,
	[endNum] int not null
)

Insert into #sprDPDBucket values ('Основной',1,'в т.ч. непросроченные',-1,0)
Insert into #sprDPDBucket values ('Основной',2,'в т.ч. 1-90 дней',0,90)
Insert into #sprDPDBucket values ('Основной',3,'в т.ч. 90+',90,9999999)

select
*
from #sprDPDBucket

END

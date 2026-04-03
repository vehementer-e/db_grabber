-- Usage: запуск процедуры с параметрами
-- EXEC _LCRM.CSV_ChangeList @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROC _LCRM.CSV_ChangeList
as
begin

if OBJECT_ID('_lcrm.dm_CSV_Change_list') is not null
begin
	drop index if exists [nci_id] ON [_LCRM].[dm_CSV_Change_list]
	truncate table _lcrm.dm_CSV_Change_list
end
if OBJECT_ID('_lcrm.dm_CSV_Change_list') is null
begin
	create table _lcrm.dm_CSV_Change_list(ID bigint, UF_UPDATED_AT datetime , UF_REGISTERED_AT datetime)
end
	--вставка данных diff backup
	insert into _lcrm.dm_CSV_Change_list(id, UF_UPDATED_AT, UF_REGISTERED_AT)
	
	select ID, UF_UPDATED_AT, UF_REGISTERED_AT 
	from _lcrm.lcrm_leads_full_csv_today
	except
	select ID, UF_UPDATED_AT, UF_REGISTERED_AT
	from _lcrm.lcrm_leads_full_csv_ago
--догрузка данных которых у нас нету
	drop table if exists #t1
	select id  into #t1 
	from _LCRM.lcrm_leads_full_csv_today	  with(nolock)
	except
	select id from _LCRM.lcrm_leads_full	   with(nolock)
	--select id from _LCRM.lcrm_leads_full_calculated with(nolock)
	
	if exists (select top(1) 1 from #t1)
	begin
		insert into _lcrm.dm_CSV_Change_list(id, UF_UPDATED_AT, UF_REGISTERED_AT)
		select ID, UF_UPDATED_AT, UF_REGISTERED_AT from _LCRM.lcrm_leads_full_csv_today s
		where exists(select top(1) 1 from #t1 t where t.ID  = s.id)
	end


-- check index enable
if not exists(select top(1) 1 from sys.indexes
	where object_id =  OBJECT_ID('_lcrm.dm_CSV_Change_list') 
	and name ='nci_id')
begin 

	
CREATE NONCLUSTERED INDEX [nci_id] ON [_LCRM].[dm_CSV_Change_list]
(
	[ID] ASC,
	[UF_REGISTERED_AT] ASC
)
	

end




-- не будем обновлять все что старше 14 дней, если пришло более 40млн записей
-- защита от ошибок выгрузки
/*
if exists(select count(*) from _lcrm.dm_CSV_Change_list having  count(*) >40000000)
begin
delete  
--select count(*)
from _lcrm.dm_CSV_Change_list where UF_UPDATED_AT < dateadd(day,-14, getdate())
end
*/
--select count(*) from _lcrm.dm_CSV_Change_list where UF_UPDATED_AT < dateadd(day,-14, getdate())
--select count(*) from _lcrm.dm_CSV_Change_list where UF_UPDATED_AT > dateadd(day,-14, getdate())



end

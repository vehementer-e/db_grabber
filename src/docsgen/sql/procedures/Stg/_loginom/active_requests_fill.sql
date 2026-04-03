--DWH-1138
-- Usage: запуск процедуры с параметрами
-- EXEC [_loginom].[active_requests_fill] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE     procedure [_loginom].[active_requests_fill] 
as 
begin
SET XACT_ABORT ON;

drop table if exists #t_Data



SELECT 	
	number = cr.Number COLLATE  Cyrillic_General_CI_AS
	,isnull(null, -1) as PersonId -- номер клиента (аналогично person_id в strategy_datamart)
	,fio = TRIM(CONCAT(ClientLastName, ' ', ClientFirstName, ' ', ClientMiddleName)) COLLATE  Cyrillic_General_CI_AS 
	,cast(ClientBirthDay as date) birth_date
	,passport_number = TRIM(CONCAT(ClientPassportSerial, ' ', ClientPassportNumber)) COLLATE  Cyrillic_General_CI_AS  
	,Vin = Vin COLLATE  Cyrillic_General_CI_AS 
	,current_status = crs.Name  COLLATE  Cyrillic_General_CI_AS  
	,crh.CreatedOn status_date

into #t_Data
	FROM   [_fedor].[core_ClientRequest] cr
	outer apply 
	(
		select top(1) crh.Id,
			crh.CreatedOn,
			crh.IdClientRequestStatus from [_fedor].[core_ClientRequestHistory]  crh
		where IdClientRequest = cr.Id
		and crh.IsDeleted = 0
		order by  CreatedOn desc
	) crh
	inner join _fedor.dictionary_ClientRequestStatus crs on crs.id = crh.IdClientRequestStatus
		and crs.Id not in (
		1,--'Черновик'
		5,--'Отказано'
		10,--'Договор подписан'
		11,--'Заем аннулирован'
		12,--Заем выдан
		13, --'Заем погашен'
		14,--'Аннулированно'
		23--	Клиент передумал
	)
	--left join dwh_new.dbo.persons p
	--	on  isnull(p.first_name, '') = isnull(cr.ClientFirstName, '') Collate Cyrillic_General_CI_AS
	--	and isnull(p.last_name, '') = isnull(cr.ClientLastName, '') Collate Cyrillic_General_CI_AS
	--	and isnull(p.middle_name, '') = isnull(cr.ClientMiddleName, '') Collate Cyrillic_General_CI_AS
	--	and isnull(p.birth_date, '1900-01-01') = isnull(cast(cr.ClientBirthDay as date), '1900-01-01')
	--	and isnull(p.passport_number, '0') = isnull(TRIM(CONCAT(ClientPassportSerial, ' ', ClientPassportNumber)), '')  Collate Cyrillic_General_CI_AS
	
	begin tran
	if OBJECT_ID('_loginom.active_requests') is null
	begin
		select top(0)
			number, 
			[PersonId], 
			fio, 
			birth_date, 
			passport_number, 
			[Vin], 
			current_status, 
			status_date,
			getdate() as InsertedDate
		into _loginom.active_requests
		from #t_Data
	end 
		truncate table _loginom.active_requests
		insert into _loginom.active_requests(
			number, 
			[PersonId], 
			fio, 
			birth_date, 
			passport_number, 
			[Vin], 
			current_status, 
			status_date,
			InsertedDate
		)
		select 
			number, 
			[PersonId], 
			fio, 
			birth_date, 
			passport_number, 
			[Vin], 
			current_status, 
			status_date,
			getdate() as InsertedDate
		from #t_Data

	commit tran
end

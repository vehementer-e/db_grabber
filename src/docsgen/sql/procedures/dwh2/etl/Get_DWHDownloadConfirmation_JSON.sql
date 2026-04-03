	--exec  [etl].[Get_DWHDownloadConfirmation_JSON] @isDebug = 1 
CREATE   procedure  [etl].[Get_DWHDownloadConfirmation_JSON]
	@ContractIds nvarchar(max) = null
	,@env  nvarchar(255)= 'uat'
	,@isDebug int = 0
WITH EXECUTE AS OWNER
as
begin
	set nocount ON
begin try
	set @ContractIds = isnull(nullif(@ContractIds,''), replace(stg.[etl].[GetContractList2Load](), '''', ''))
	set @isDebug = isnull(@isDebug, 0)
	if @isDebug = 1
		select @ContractIds
	drop table if exists #t_data
	select distinct 
		УИДДанных
	into #t_data
	from stg._1cCMR.РегистрСведений_ПодготовленныеДанныеДляDWH
	where ЗагруженоВ_DWH = 0x00
	and Договор in (select dbo.get1CIDRREF_FromGUID(trim(value)) from string_split(@ContractIds, ','))
	if @isDebug = 1
		select  *from #t_data
	declare @type nvarchar(255) = 'DWHDownloadConfirmation'


	select json = (
			SELECT
				m.meta
				,'data.id'							= t.id
				,'data.type'						= @type
				,'data.attributes.date'				= cast(GETUTCDATE() as datetime2(0))
			FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
			)
		from (
			SELECT 
				communication_id = newid()
				,id = УИДДанных
			FROM #t_data AS D
			) AS t
		OUTER APPLY
			(
					select meta = JSON_QUERY((select 
						'guid'							= cast(t.communication_id as nvarchar(36))
						,'time.publish'					=  DATEDIFF(s, '1970-01-01 00:00:00', getdate())
						,'publisher.code'				= 'DWH'
						,'links.documentation.contract' = 'https://wiki.carmoney.ru/x/qMcuB'
						,'links.documentation.jsonAPI'	= 'https://wiki.carmoney.ru/x/tUo6Ag'
						FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES 
					))
			) AS M
	
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
CREATE   procedure [ivr].[fill_ProductAndCompanyMapping]
as
begin try
drop table if exists #ProductAndCompanyMapping
select * 
into #ProductAndCompanyMapping
from 
(
select productCode = ИдентификаторMDS, 'psb' companyCode from stg._1cCMR.Справочник_ТипыПродуктов
where ИдентификаторMDS in ('bigInstallment')
and nullif(ИдентификаторMDS,'') is not null
union
select ИдентификаторMDS, 'carmoney' from stg._1cCMR.Справочник_ТипыПродуктов
where ИдентификаторMDS not in ('bigInstallment')
and nullif(ИдентификаторMDS,'') is not null
) t
select * from #ProductAndCompanyMapping

if OBJECT_ID('ivr.ProductAndCompanyMapping') is null
begin
	select top(0)
	*
	into ivr.ProductAndCompanyMapping
	from #ProductAndCompanyMapping
end
begin tran
	truncate table ivr.ProductAndCompanyMapping
	insert into ivr.ProductAndCompanyMapping(productCode, companyCode)
	select productCode, companyCode
	from #ProductAndCompanyMapping
commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	
	;throw
end catch
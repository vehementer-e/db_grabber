create proc [dbo].[качество данных]
as
begin

select 1
--select cast(Период as date) d, count(*) cnt into #stg from [Stg].[_1cCRM].[РегистрСведений_ИсторияИзмененияДопУслугВЗаявках] group by  cast(Период as date)
--select cast(Период as date) d, count(*) cnt into #prod from prodsql01.crm.dbo.[РегистрСведений_ИсторияИзмененияДопУслугВЗаявках]  group by  cast(Период as date)
--
--select * from #stg except 
--select * from #prod-- except 


end
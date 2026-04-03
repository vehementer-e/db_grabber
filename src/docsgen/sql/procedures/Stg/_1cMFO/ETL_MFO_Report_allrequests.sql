

create   procedure _1cMFO.ETL_MFO_Report_allrequests
as
begin
set nocount on

drop table if exists #t

delete from stg._1cmfo.[Отчет_ВсеЗаявкиДляАналитика]

select * into #t from prodsql02.mfo.dbo.[Отчет_ВсеЗаявкиДляАналитика]

insert into stg._1cmfo.[Отчет_ВсеЗаявкиДляАналитика]
  select *  from #t

end
--DWH-1064
CREATE     proc [dbo].[create_dm_report_pep3_loans_SB_info]
as
begin



drop table if exists #t1

select 



       pep3_sales.Номер
      ,pep3_sales.[Фамилия]
      ,pep3_sales.[Имя]
      ,pep3_sales.[Отчество]
      ,pep3_sales.ДатаВыдачи
      ,pep3_sales.ДатаПогашения
      ,pep3_sales.СуммаВыданная
      ,pep3_sales.[Паспорт]
      ,pep3_sales.[МобильныйТелефон]

	  ,mfo.АдресПроживания
	  ,isnull(format(cmr.ДатаВходаВПросрочку, 'yyyy-MM-dd'), 'Просрочки нет') ДатаВходаВПросрочку
	  ,cmr.ПросрочкаНаСегодня
	  ,getdate() as created
	into #t1
from      dbo.dm_report_pep3_loans_sales_info pep3_sales
left join stg._1cMFO.Документ_ГП_Договор              mfo       on mfo.Номер=pep3_sales.Номер
left join (
	select external_id                                          
	,      min(case when dpd>0 then d end)                          ДатаВходаВПросрочку
	,      min(case when d=cast(getdate() as date) then dpd end) as ПросрочкаНаСегодня
	from dbo.dm_CMRStatBalance_2 cmr
	group by external_id
	)                                                
	                                                  cmr        on cmr.external_id=pep3_sales.Номер


if   OBJECT_ID(N'[dbo].[dm_report_pep3_loans_SB_info]') is null
begin
													  
CREATE TABLE [dbo].[dm_report_pep3_loans_SB_info](
	[Номер] [nchar](14)  NULL,
	[Фамилия] [nvarchar](150)  NULL,
	[Имя] [nvarchar](150)  NULL,
	[Отчество] [nvarchar](150)  NULL,
	[ДатаВыдачи] [datetime2](0) NULL,
	[ДатаПогашения] [datetime2](0) NULL,
	[СуммаВыданная] [numeric](15, 0)  NULL,
	[Паспорт] [nvarchar](12)  NULL,
	[МобильныйТелефон] [nvarchar](16)  NULL,
	[АдресПроживания] [ntext] NULL,
	[ДатаВходаВПросрочку] [nvarchar](4000)  NULL,
	[ПросрочкаНаСегодня] [numeric](10, 0) NULL,
	[created] [datetime]  NULL
) 

end

												

begin tran
delete from dbo.dm_report_pep3_loans_SB_info
insert into dbo.dm_report_pep3_loans_SB_info
select * from #t1


commit tran



end

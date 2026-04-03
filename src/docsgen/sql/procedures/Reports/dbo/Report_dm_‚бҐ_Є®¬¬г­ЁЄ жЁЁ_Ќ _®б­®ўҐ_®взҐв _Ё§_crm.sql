--Процедура для отчета в рамках BP-1768
--
--exec dbo.[Report_dm_Все_коммуникации_На_основе_отчета_из_crm] '2021-11-17', '2021-11-18'
CREATE PROC dbo.Report_dm_Все_коммуникации_На_основе_отчета_из_crm
	@dateBegin date,
	@dateEnd date
as
begin
	select * 
	from dbo.dm_Все_коммуникации_На_основе_отчета_из_crm
	where ДатаВзаимодействия between @dateBegin and @dateEnd
	order by ДатаВзаимодействия , ВремяВзаимодействия
end
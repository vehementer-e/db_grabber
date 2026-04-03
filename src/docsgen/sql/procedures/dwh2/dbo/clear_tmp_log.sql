create   PROC dbo.clear_tmp_log
as
begin

	delete l
	from tmp.log_link_ЗаявкаНаЗаймПодПТС_change as l
	where l.log_date < dateadd(month,-1,getdate())

	delete l
	from tmp.log_link_ВыдачаДенежныхСредств_change as l
	where l.log_date < dateadd(month,-1,getdate())

	delete l
	from tmp.log_link_ДоговорЗайма_change as l
	where l.log_date < dateadd(month,-1,getdate())

end



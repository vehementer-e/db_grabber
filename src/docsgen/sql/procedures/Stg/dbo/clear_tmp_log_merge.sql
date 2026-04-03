-- exec dbo.clear_tmp_log_merge
create   PROC dbo.clear_tmp_log_merge
as
begin

delete l
from tmp.log_merge_Документ_ВыдачаДенежныхСредств as l
where l.log_date < dateadd(month,-1,getdate())

delete l
from tmp.log_merge_РегистрНакопления_АктивныеАкции as l
where l.log_date < dateadd(month,-1,getdate())

delete l
from tmp.log_merge_РегистрСведений_ИсторияИзмененияРеквизитовОбъектов as l
where l.log_date < dateadd(month,-1,getdate())

delete l
from tmp.log_merge_РегистрСведений_СтатусыДоговоров as l
where l.log_date < dateadd(month,-1,getdate())

delete l
from tmp.log_merge_РегистрСведений_СтатусыЗаявокНаЗаймПодПТС as l
where l.log_date < dateadd(month,-1,getdate())

end



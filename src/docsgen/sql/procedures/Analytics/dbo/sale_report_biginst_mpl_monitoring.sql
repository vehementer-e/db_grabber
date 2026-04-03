
CREATE   proc [dbo].[sale_report_biginst_mpl_monitoring] @mode nvarchar(max) = 'update'
as



--sp_create_job 'Analytics._sale_report_biginst_mpl_monitoring each 3 min 7:00', 'sale_report_biginst_mpl_monitoring', '1', '70000', '3'

--sp_create_job 'Analytics._sale_report_biginst_mpl_monitoring each monday at 10', 'exec sale_report_biginst_mpl_monitoring ''report''', '1', '100000'


declare @html nvarchar(max)



if @mode = 'update'

begin

--create TABLE [dbo].sale_report_biginst_mpl_monitoring_log 
--(
--      [number] [NVARCHAR](14)
--    , [declinereason] [NVARCHAR](150)
--    , [declined] [DATETIME2](0)
--    , [fio] [NVARCHAR](452)
--    , [phone] [NVARCHAR](16)
--    , [source] [VARCHAR](255)
--    , [producttype] [NVARCHAR](100)
--    , [created] [DATETIME]
--);


drop table if exists #t1

select number, declinereason, declined, fio, phone, source, producttype, getdate() created into #t1 from v_request 
where number not in  (select number from sale_report_biginst_mpl_monitoring_log where number is not null)


and  producttype = 'Big Installment Рыночный'  and declinereason ='Автоматический отказ (по МПЛ)'
and ПризнакТестоваяЗаявка=0 and declined is not null

if not exists (select top 1 * from #t1 )

return

 

--declare @html nvarchar(max)


exec sp_html 'select   a.[number] НомерЗаявки
, a.[declinereason] ПричинаОтказа
, a.[declined] Отказано
, a.[fio] ФИО
, a.[phone] Телефон
, a.[source] Источник
, a.[producttype] ТипПродукта
   from #t1 a',  'order by Отказано desc' , @html output 


exec notify_html 'Новый отказ по долговой нагрузке', 'p.ilin@smarthorizon.ru; rgkc@carmoney.ru; e.sheremeteva@smarthorizon.ru',   @html

insert into sale_report_biginst_mpl_monitoring_log
select * from #t1

end

if @mode = 'report'
 begin


--declare @html nvarchar(max)

  
 declare @subj nvarchar(max) = 'отчет по отказам по догловой нагрузке с  '+ format(getdate()-7, 'dd/MM/yyyy') + ' по ' + format(getdate()-1, 'dd/MM/yyyy')

 select  @subj

 
exec sp_html ' select a.number НомерЗаявки
 , a.fio ФИО
 , a.declined [Отказано]
 , a.created [Дата отправки письма с отказом]
 , b.number [Номер повторной заявки]
 , b.created [Дата повторной заявки]
 , b.status [Статус повторной заявки]
   
 
 from sale_report_biginst_mpl_monitoring_log  a
 left join v_request b on a.phone=b.phone and b.created>=a.declined and b.created <= dateadd(day, 5, a.declined )
 join calendar_view c on cast(a.created as date) = c.date
 where c.week = (select week from calendar_view where date = cast(getdate()-1 as date) )
 --order by a.declined desc
 
 
 ',  'order by [Дата отправки письма с отказом] desc' , @html output 

--exec notify_html @subj, default,   @html

exec notify_html @subj, 'p.ilin@smarthorizon.ru; rgkc@carmoney.ru; e.sheremeteva@smarthorizon.ru',   @html



 end 
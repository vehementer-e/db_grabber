--На 2-й рабочий день проверять появление новых счетов 7-го раздела (7%) в справочнике аналитический счетов 
--УМФО и при наличие новых (открытых за предыдущий месяц)
--отправлять сообщение Хасаншин, Свидетелева, отчетность регуляторная и отчетность (Москвичева, Кабрис, Белецкая).

CREATE PROC [finAnalytics].[checkNewAcc] 

AS
BEGIN
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	declare @subject nvarchar(255) = CONCAT (
					'Выполнение процедуры: Проверка появления новых счетов '
					,@sp_name
					)

	declare @monthStartTmp datetime=datefromparts(year(dateadd(month,-1,getdate())),month(dateadd(month,-1,getdate())),1)
	--перменная отвечает за начало месяца
	declare @monthStart datetime=dateadd(year,2000,@monthStartTmp )

	declare @monthEndTmp datetime = dateadd(day,1,eomonth(@monthStart))
	--перменная отвечает за конец месяца
	declare @monthEnd datetime= dateadd(second,-1,@monthEndTmp)

	declare @countRow int =  null -- переменная для подсчета найденых новых счетов
	set @countRow =
			(
			select
				count(*)
			from 
				(
				select 
					Код
					,Наименование
					,ДатаОткрытия
				from stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета
				where ДатаОткрытия between @monthStart and @monthEnd
					and SUBSTRING(Код,1,1)='7'
				) l1
			)
	if @countRow <>0
		begin
			declare @msg_good nvarchar(max)=CONCAT (
						'Коллеги, при проверке, в справочнике аналитический счетов УМФО, найдены новые счета 7-го раздела'
						,char(10)
						,'Кол-во найденных счетов :'
						,@countRow
						,char(10)
						,'Подробная информация :'
						,(select link from finAnalytics.SYS_SPR_linkReport where repName='Отчет по новым счетам'))
		exec finAnalytics.sendEmail @subject = 'Выполнение процедуры: Проверка появления новых счетов',@message = @msg_good,@strRcp = '1,21,31,5'
	    end   
	else 
		exec finAnalytics.sendEmail @subject = @subject,@message = 'Новых счетов не найдено',@strRcp = '1'
END

--На 2-й рабочий день проверять появление новых (за предыдущий месяц) масок проводок, 
--начиная с 01.06.2025. За база взять проводки с 01.01.2024 по 31.05.2025. 
--При появлении новых масок записать их в базу
--и отправлять сообщение Хасаншин, Свидетелева, отчетность регуляторная и отчетность (Москвичева, Кабрис, Белецкая).
--Маска, номер и дату документа, назначение (комментарий и т.п.)


CREATE PROC [finAnalytics].[checkNewEntries]
		@flag int
AS
BEGIN
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	declare @subject nvarchar(255) = CONCAT (
					'Выполнение процедуры: Проверка появление новых масок проводок'
					,@sp_name
					)
	
	declare @repmonth date =datefromparts(year(dateadd(month,-1,getdate())),month(dateadd(month,-1,getdate())),1)

	--перменная отвечает за начало месяца
	declare @repmonthStart date = dateadd(year,2000,@repmonth)
	--перменная отвечает за конец месяца
	declare @repmonthEnd date = eomonth(dateadd(year,2000,@repmonth));

	declare @countRow int =  null; -- переменная для подсчета найденых новых масок
	declare @resultTable table(
		ДТ varchar(5)
		,КТ varchar(5)
		,Дата date
		,НомерМемориальногоОрдера varchar(50)
		,Содержание varchar(max)
		,ТипПроверки nvarchar(100)
		)
	 insert into @resultTable (ДТ,КТ,Дата,НомерМемориальногоОрдера,Содержание, ТипПроверки)
	----
	
	    select
			ДТ=l2.ДТ
			,КТ=l2.КТ
			,Дата=l2.Дата
			,НомерМемориальногоОрдера=l2.НомерМемориальногоОрдера
			,Содержание=l2.Содержание
			,ТипПроверки=l2.ТипПроверки
		from(
			select
				l1.ДТ
				,l1.КТ
				,l1.Дата
				,l1.НомерМемориальногоОрдера
				,l1.Содержание
				,ТипПроверки=iif(@flag=0,'Проверка в начале месяца','Проверка после закрытия месяца')
			from
				(
				select 
					[ДТ] = dt.Код
					,[КТ] = kt.Код

					,[Дата] = cast(dateadd(year,-2000,a.Период) as date)
					,НомерМемориальногоОрдера
					,Содержание
					,[rn] = ROW_NUMBER() over (Partition by dt.Код,kt.Код order by a.Период desc)

				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a

				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0

				where cast(Период as date) between @repmonthStart and @repmonthEnd
				and Активность = 0x01
				) l1

			where l1.rn in (1)
			) l2
			left join dwh2.finAnalytics.spr_DTKT as DTKT on DTKT.ДТ = l2.ДТ and DTKT.КТ = l2.КТ -- and DTKT.ТипПроверки=l2.ТипПроверки 
			where DTKT.ДТ is null 
	----
set @countRow = (select count(*) from @resultTable)
	if @countRow <>0
		begin
			--добавление новых строк в таблицу справочник 
			insert into dwh2.finAnalytics.spr_DTKT
						([ДТ], [КТ], [Дата], [НомерМемориальногоОрдера], [Содержание],[repmonth],[ТипПроверки])
						select [ДТ], [КТ], [Дата], [НомерМемориальногоОрдера], [Содержание],@repmonth,[ТипПроверки] from @resultTable
			declare @msg_good nvarchar(max)=CONCAT (
						'Коллеги, при проверке, проводок УМФО, найдены новые маски '
						,iif(@flag=0,'Проверка в начале месяца','Проверка после закрытия месяца')
						,char(10)
						,'Кол-во найденных масок :'
						,@countRow
						,char(10)
						,'Подробная информация :'
						,(select link from finAnalytics.SYS_SPR_linkReport where repName='Отчет по новым счетам'))
		-- отправка сообщения 
		exec finAnalytics.sendEmail @subject = 'Выполнение процедуры: Проверка появление новых масок проводок',@message = @msg_good,@strRcp ='1,21,31,5'
		end   
	else
		exec finAnalytics.sendEmail @subject = @subject,@message = 'Новых масок не найдено',@strRcp = '1'
END

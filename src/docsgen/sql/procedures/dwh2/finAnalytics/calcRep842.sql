



CREATE PROC [finAnalytics].[calcRep842] 
    @repmonth date
AS
BEGIN
	
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для отчета 842'
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

  begin try
	
	/*Темповая таблица ОСВ за месяц*/
		drop Table if exists #osv
		select
		*
		into #osv
		from dwh2.finAnalytics.OSV_MONTHLY a
		where a.repMonth = @repmonth
		CREATE INDEX index1 ON #osv ([acc2order]);


		/*Основной массив значений*/
		drop table if exists #rep

		select
		repmonth = @repmonth
		,Razdel	
		,RowNum	
		,sub2Acc	
		,aplicator	
		,rowName	
		,pokazatel	
		,sub2AccName	
		,isActive
		,restOut = isnull(
						  case when sub2Acc = '60328' then abs(osv.restOUT_BU)
						  else osv.restOUT_BU	
						  end
						  ,0)
		--,osv.restOUT_NU

		into #rep

		from dwh2.[finAnalytics].[SPR_rep842] a --select * from dwh2.[finAnalytics].[SPR_rep842]
		left join (
		select
		acc2order
		,restOUT_BU = sum(restOUT_BU)
		--,restOUT_NU = sum(restOUT_NU)
		from #osv
		group by 
		acc2order
		) osv on a.sub2Acc = osv.acc2order

		--where a.sub2AccName='-48810'

		/*Дополнительные не стандартные расчеты*/


		--1.17
		merge into #rep t1
		using(
		select
		restOUT_BU = sum(restOUT_BU)
		from #osv a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		where acc2order='47423'
		and upper(cl2.Наименование) = UPPER('Платежные системы')
		) t2 on (t1.razdel = 1 and t1.rowNum = 180)
		when matched
		then update
		set t1.restOut = t2.restOUT_BU;


		--1.18
		merge into #rep t1
		using(
		select
		restOUT_BU = sum(restOUT_BU)
		from #osv a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		where acc2order='47425'
		and upper(cl2.Наименование) = UPPER('Платежные системы')
		) t2 on (t1.razdel = 1 and t1.rowNum = 190)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT_BU,0);


		--1
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		where a.rowName in ('1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9','1.10',
							 '1.11','1.12','1.13','1.14','1.15','1.16','1.17','1.18','1.19')
		) t2 on (t1.razdel = 1 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);


		--4.169
		merge into #rep t1
		using(
		select
		restOut = sum(penyaSum) + sum(gosposhlSum)
		from dwh2.finAnalytics.PBR_MONTHLY a
		where a.REPMONTH = @repmonth
		) t2 on (t1.razdel = 4 and t1.rowNum = 1700)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT,0);


		--4.334
		merge into #rep t1
		using(
		select
		restOut = sum(reservBUPenyaSum) *-1
		from dwh2.finAnalytics.PBR_MONTHLY a
		where a.REPMONTH = @repmonth
		) t2 on (t1.razdel = 4 and t1.rowNum = 3350)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT,0);


		--5
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		where a.rowName in ('5.1','5.2')
		) t2 on (t1.razdel = 5 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--9
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		where a.razdel = 9 and rowNum > 10
		) t2 on (t1.razdel = 9 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--10
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 10 and rowNum > 10
		) t2 on (t1.razdel = 10 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--11
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 11 and rowNum > 10
		) t2 on (t1.razdel = 11 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--12
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 12 and rowNum > 10
		) t2 on (t1.razdel = 12 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--13
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 13 and rowNum > 10
		) t2 on (t1.razdel = 13 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--14.26.1
		merge into #rep t1
		using(
		select
		restOUT_BU = sum(restOUT_BU)
		from #osv a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		where acc2order='47423'
		and upper(cl2.Наименование) = UPPER('Платежные системы')
		) t2 on (t1.razdel = 14 and t1.rowNum = 280)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT_BU,0);

		--14.26
		merge into #rep t1
		using(
		select
		restOUT_BU = sum(restOUT_BU)
		from #osv a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		where acc2order='47423'
		and (upper(cl2.Наименование) != UPPER('Платежные системы') or cl2.Наименование is null)
		) t2 on (t1.razdel = 14 and t1.rowNum = 270)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT_BU,0);


		--14.33.1
		merge into #rep t1
		using(
		select
		restOut = sum(penyaSum) + sum(gosposhlSum)
		from dwh2.finAnalytics.PBR_MONTHLY a
		where a.REPMONTH = @repmonth
		) t2 on (t1.razdel = 14 and t1.rowNum = 360)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT,0);

		--14.33
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from(
		select
			restOut = sum(restOUT_BU)
			from #osv
			where acc2order = '60323'
			group by 
			acc2order
		
			union all
		
			select
			restOut *-1
			from #rep
			where rowname in ('14.33.1')
		) l1	
		) t2 on (t1.razdel = 14 and t1.rowNum = 350)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT,0);

		--14.49
		merge into #rep t1
		using(
		select
		restOUT_BU = sum(restOUT_BU)
		from #osv a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		where acc2order='47425'
		and (upper(cl2.Наименование) != UPPER('Платежные системы') or cl2.Наименование is null)
		) t2 on (t1.razdel = 14 and t1.rowNum = 520)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT_BU,0);


		--14.51.2
		merge into #rep t1
		using(
		select
		restOut = sum(reservBUPenyaSum)
		from dwh2.finAnalytics.PBR_MONTHLY a
		where a.REPMONTH = @repmonth
		) t2 on (t1.razdel = 14 and t1.rowNum = 560)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT,0);

		update #rep set restOut = restout * -1 where rowName = '14.51.1'

		--14.51
		merge into #rep t1
		using(
		select
		restOut = sum(case when rowName = '14.51.2' then restOut * -1 else restout end) *-1
		from #rep
		where Razdel = 14 and rowName in ('14.51.1','14.51.2')
		) t2 on (t1.razdel = 14 and t1.rowNum = 540)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT,0);

		--14
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		--сумма строк с номером 14.1-14.26, 14.27-14.33, 14.34-14.51, 14.52 (см. по столбцу "номер строки")
		where a.rowName in ('14.1','14.2','14.3','14.4','14.5','14.6','14.7','14.8','14.9','14.10'
							,'14.11','14.12','14.13','14.14','14.15','14.16','14.17','14.18','14.19','14.20'
							,'14.21','14.22','14.23','14.24','14.25','14.26','14.27','14.28','14.29','14.30'
							,'14.31','14.32','14.33','14.34','14.35','14.36','14.37','14.38','14.39','14.40'
							,'14.41','14.42','14.43','14.44','14.45','14.46','14.47','14.48','14.49','14.50'
							,'14.51','14.52')
		) t2 on (t1.razdel = 14 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--4.248 -- после раздела 14
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from(
		select
			restOut = sum(restOUT_BU)
			from #osv
			where acc2order = '47425'
			group by 
			acc2order
		
			union all
		
			select
			restOut *-1
			from #rep
			where rowname in ('1.18','14.49')
		) l1	
		) t2 on (t1.razdel = 4 and t1.rowNum = 2490)
		when matched
		then update
		set t1.restOut = isnull(t2.restOUT,0);

		--4
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		where a.razdel = 4 and rowNum > 10
		) t2 on (t1.razdel = 4 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--15
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		--сумма строк с номерами 1, 4, 5, 9, 10, 11, 12, 13, 14 (см. по столбцу "номер строки")
		where a.rowName in ('1','4','5','9','10','11','12','13','14')
		) t2 on (t1.razdel = 15 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		update #rep set restOut = restout * -1 where razdel=17

		--update #rep set restOut = restout * -1 where rowName = '17.3'
		--update #rep set restOut = restout * -1 where rowName = '17.4'
		--update #rep set restOut = restout * -1 where rowName = '17.51'
		--update #rep set restOut = restout * -1 where rowName = '17.55'
		--update #rep set restOut = restout * -1 where rowName = '17.56'
		--update #rep set restOut = restout * -1 where rowName = '17.68'
		--update #rep set restOut = restout * -1 where rowName = '17.70'
		--update #rep set restOut = restout * -1 where rowName = '17.76'
		--update #rep set restOut = restout * -1 where rowName = '17.80'
		--update #rep set restOut = restout * -1 where rowName = '17.92'

		--17
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 17 and rowNum > 10
		) t2 on (t1.razdel = 17 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--19
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 19 and rowNum > 10
		) t2 on (t1.razdel = 19 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		update #rep set restOut = restout * -1 where rowName = '20.1'

		--20
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 20 and rowNum > 10
		) t2 on (t1.razdel = 20 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--21
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 21 and rowNum > 10
		) t2 on (t1.razdel = 21 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		update #rep set restOut = restout * -1 where razdel=22

		--22
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)
		from #rep a
		where a.razdel = 22 and rowNum > 10
		) t2 on (t1.razdel = 22 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);


		--23
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		--сумма строк с номерами 17, 19, 20, 21, 22(см. по столбцу "номер строки")
		where a.rowName in ('17','19','20','21','22')
		) t2 on (t1.razdel = 23 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		update #rep set restOut = restout * -1 where razdel=24
		update #rep set restOut = restout * -1 where razdel=25

		--28
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		where razdel = 28 and rowNum > 10
		) t2 on (t1.razdel = 28 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		update #rep set restOut = restout * -1 where razdel=29

		--29
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		where razdel = 29 and rowNum > 10
		) t2 on (t1.razdel = 29 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--30
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		--сумма строк с номерами 24, 25, 29 (см. по столбцу "номер строки")
		where a.rowName in ('24','25','29')
		) t2 on (t1.razdel = 30 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--31
		merge into #rep t1
		using(
		select
		restOut = sum(restOut)

		from #rep a
		--сумма строк с номерами 23, 30 (см. по столбцу "номер строки")
		where a.rowName in ('23','30')
		) t2 on (t1.razdel = 31 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		--32
		merge into #rep t1
		using(
		select
		restOut = sum(case when a.rowName in ('23','30') then restOut*-1 else restOut end)

		from #rep a
		--разность строк с номерами 15, 23, 30 (см. по столбцу "номер строки")
		where a.rowName in ('15','23','30')
		) t2 on (t1.razdel = 32 and t1.rowNum = 10)
		when matched
		then update
		set t1.restOut = isnull(t2.restOut,0);

		delete from dwh2.finAnalytics.rep842 where repmonth = @repmonth

		insert into dwh2.finAnalytics.rep842
		select
		*
		from #rep

	declare @monthForSPOD date = datefromParts(year(@repmonth),12,1)
	/*Расчет СПОД*/
	EXEC [finAnalytics].[calcRepPL842_SPODFact] @monthForSPOD
    
	declare @maxDateRest date = (select max(repmonth) from dwh2.finAnalytics.rep842)

	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 45

	declare @repLink  nvarchar(max) = (select link from dwh2.[finAnalytics].[SYS_SPR_linkReport] where repName ='Отчет 842')
	
	DECLARE @msg_calcAll NVARCHAR(2048) = CONCAT (
				'Расчет данных для отчета 842'
                ,char(10)
                ,char(13)
				,'за отчетный месяц: '
				,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
				,char(10)
                ,char(13)
				,'Ссылка на отчет: '
				,@repLink
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_calcAll
			,@body_format = 'TEXT'
			,@subject = @subject;

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета 842 '
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients =''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END

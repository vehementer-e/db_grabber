





CREATE PROC [finAnalytics].[calcRepPublic_17_3] 
    @repmonth date
AS
BEGIN

	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc
	
    begin try
	

	    declare	@repmonthPrev date = dateFromParts(year(@repmonth)-1,12,1)
--select @repmonth,@repmonthPrev


	drop table if exists #OSV
	create table #OSV (
		[repmonthType] int not null,
		[acc2order] nvarchar(10) not null,
		[groupFinRec] nvarchar(500) null,
		[restOUT_BU] float not null,
		[restIN_BU] float not null
	)

	insert into #OSV
	select
	[repmonthType] = case when a.repmonth = @repmonth then 1 else 0 end
	,a.acc2order
	,g.Наименование
	,[restOUT_BU] = abs(sum(isnull(a.restOUT_BU,0)))
	,[restIN_BU] = abs(sum(isnull(a.restIN_BU,0)))

	from dwh2.finAnalytics.OSV_MONTHLY a
	left join stg.[_1cUMFO].[Справочник_ДоговорыКонтрагентов] d on a.subconto2UID = d.ссылка
	left join stg.[_1cUMFO].[Справочник_БНФОГруппыФинансовогоУчетаРасчетов] g on d.БНФОГруппаФинансовогоУчета=g.ссылка

	where a.repmonth in (@repmonth,@repmonthPrev)
	group by a.acc2order,g.Наименование,case when a.repmonth = @repmonth then 1 else 0 end


/*Проводки*/
	declare @dateFrom datetime = dateadd(year,2000,dateFromParts(year(@repmonth),1,1))
	declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@repmonth)))
	declare @dateTo datetime = dateadd(second,-1,@dateToTmp)


	DROP TABLE IF EXISTS #prov

	SELECT 

	[Дата операции] = cast(dateadd(year,-2000,a.Период) as date)
	,[СчетДтКод] = Dt.Код
	,[СчетКтКод] = Kt.Код
	,[Сумма БУ] = abs(isnull(a.Сумма,0))
	,[Содержание] = a.Содержание
	,[Договор] = case 
					when dogDT.Номер is not null then dogDT.Номер
					when dogKT.Номер is not null then dogKT.Номер
				else '-' end
	,[ГруппаФинУчета] = isnull(gDT.Наименование,gKT.Наименование)
	into #prov 
	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
	left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dogDT on a.СубконтоDt2_Ссылка=dogDT.Ссылка
	left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dogKT on a.СубконтоCt2_Ссылка=dogKT.Ссылка
	left join stg.[_1cUMFO].[Справочник_БНФОГруппыФинансовогоУчетаРасчетов] gDT on dogDT.БНФОГруппаФинансовогоУчета=gDT.ссылка
	left join stg.[_1cUMFO].[Справочник_БНФОГруппыФинансовогоУчетаРасчетов] gKT on dogKT.БНФОГруппаФинансовогоУчета=gKT.ссылка

	where a.Период between @dateFrom and @dateTo
	and a.Активность=01
	and ( 
			--Дт 71702 Кт 47425
			(Dt.Код = '71702' and Kt.Код = '47425')
			--Дт 47425 Кт 71701
			or
			(Dt.Код = '47425' and Kt.Код = '71701')
			--Дт 71702 Кт 60324
			or
			(Dt.Код = '71702' and Kt.Код = '60324')
			--Дт 60324 Кт 71701
			or
			(Dt.Код = '60324' and Kt.Код = '71701')
			--Дт 47425 Кт 47423
			or
			(Dt.Код = '47425' and Kt.Код = '47423')
			--Дт 60324 Кт 60312
			or
			(Dt.Код = '60324' and Kt.Код = '60312')
			--Дт 60324 Кт 60323
			or
			(Dt.Код = '60324' and Kt.Код = '60323')
		)

	drop table if exists #rep
	create table #rep(
		repmonth date not null,
		[RowNum] [int] NOT NULL,
		[Razdel] [nvarchar](10) NULL,
		[RowName] [nvarchar](10) NULL,
		[Pokazatel] [nvarchar](255) NULL,
		[Acc2] [nvarchar](max) NULL,
		[Aplicator] [int] NULL,
		[isBold] [int] NULL,
		[sumAmountCol3] float null,
		[sumAmountCol4] float null,
		[sumAmountCol5] float null,
		[sumAmountCol6] float null,
		[sumAmountCol7] float null,
		[sumAmountCol8] float null,
		[sumAmountCol9] float null,
		[sumAmountItog] float null
		
	)


/*Заполнение скелета*/
insert into #rep
select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = 0
		, [sumAmountCol4] = 0
		, [sumAmountCol5] = 0
		, [sumAmountCol6] = 0
		, [sumAmountCol7] = 0
		, [sumAmountCol8] = 0
		, [sumAmountCol9] = 0
		, [sumAmountItog] = 0
		from dwh2.[finAnalytics].[SPR_repPublicPL_17_3] a



	--p 1.1
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='47425'
		and [repmonthType] = 0
		) t2 on (t1.RowName='1.1')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];


	--p 1.2
		merge into #rep t1
		using(
		select
		[sumAmountCol7] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='60324'
		and upper([groupFinRec]) = upper('60311,60312_Расчеты с поставщиками и подрядчиками')
		and [repmonthType] = 0
		) t2 on (t1.RowName='1.2')
		when matched then update
		set t1.[sumAmountCol7] = t2.[sumAmountCol7] * t1.[Aplicator];


--p 1.3
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='60324'
		and upper([groupFinRec]) = upper('60322,60323_Расчеты с прочими дебиторами и кредиторами')
		and [repmonthType] = 0
		) t2 on (t1.RowName='1.3')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];


--p 1.4
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='60324'
		and upper([groupFinRec]) = upper('60324_Резервы под обесценение')
		and [repmonthType] = 0
		) t2 on (t1.RowName='1.4')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 2.1
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '71702' and СчетКтКод = '47425'
		) t2 on (t1.RowName='2.1')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 2.2
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '47425' and СчетКтКод = '71701'
		) t2 on (t1.RowName='2.2')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 2.3
		merge into #rep t1
		using(
		select
		[sumAmountCol7] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '71702' and СчетКтКод = '60324'
		and upper(ГруппаФинУчета) = upper('60311,60312_Расчеты с поставщиками и подрядчиками')
		) t2 on (t1.RowName='2.3')
		when matched then update
		set t1.[sumAmountCol7] = t2.[sumAmountCol7] * t1.[Aplicator];

--p 2.4
		merge into #rep t1
		using(
		select
		[sumAmountCol7] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '60324' and СчетКтКод = '71701'
		and upper(ГруппаФинУчета) = upper('60311,60312_Расчеты с поставщиками и подрядчиками')
		) t2 on (t1.RowName='2.4')
		when matched then update
		set t1.[sumAmountCol7] = t2.[sumAmountCol7] * t1.[Aplicator];

--p 2.5
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '71702' and СчетКтКод = '60324'
		and upper(ГруппаФинУчета) = upper('60322,60323_Расчеты с прочими дебиторами и кредиторами')
		) t2 on (t1.RowName='2.5')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 2.6
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '60324' and СчетКтКод = '71701'
		and upper(ГруппаФинУчета) = upper('60322,60323_Расчеты с прочими дебиторами и кредиторами')
		) t2 on (t1.RowName='2.6')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 2.7
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '71702' and СчетКтКод = '60324'
		and upper(ГруппаФинУчета) = upper('60324_Резервы под обесценение')
		) t2 on (t1.RowName='2.7')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 2.8
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '60324' and СчетКтКод = '71701'
		and upper(ГруппаФинУчета) = upper('60324_Резервы под обесценение')
		) t2 on (t1.RowName='2.8')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 3.1
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '47425' and СчетКтКод = '47423'
		--and upper(ГруппаФинУчета) = upper('60324_Резервы под обесценение')
		) t2 on (t1.RowName='3.1')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 3.2
		merge into #rep t1
		using(
		select
		[sumAmountCol7] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '60324' and СчетКтКод = '60312'
		--and upper(ГруппаФинУчета) = upper('60324_Резервы под обесценение')
		) t2 on (t1.RowName='3.2')
		when matched then update
		set t1.[sumAmountCol7] = t2.[sumAmountCol7] * t1.[Aplicator];

--p 3.3
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '60324' and СчетКтКод = '60323'
		and upper(ГруппаФинУчета) = upper('60322,60323_Расчеты с прочими дебиторами и кредиторами')
		) t2 on (t1.RowName='3.3')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

--p 3.4
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull([Сумма БУ],0) as float)),0)
		from #prov --select * from #prov
		where СчетДтКод = '60324' and СчетКтКод = '60324'
		and upper(ГруппаФинУчета) = upper('60324_Резервы под обесценение')
		) t2 on (t1.RowName='3.4')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];


--p 5.1
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='47425'
		and [repmonthType] = 1
		) t2 on (t1.RowName='5.1')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];


--p 5.2
		merge into #rep t1
		using(
		select
		[sumAmountCol7] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='60324'
		and upper([groupFinRec]) = upper('60311,60312_Расчеты с поставщиками и подрядчиками')
		and [repmonthType] = 1
		) t2 on (t1.RowName='5.2')
		when matched then update
		set t1.[sumAmountCol7] = t2.[sumAmountCol7] * t1.[Aplicator];


--p 5.3
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='60324'
		and upper([groupFinRec]) = upper('60322,60323_Расчеты с прочими дебиторами и кредиторами')
		and [repmonthType] = 1
		) t2 on (t1.RowName='5.3')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];


--p 5.4
		merge into #rep t1
		using(
		select
		[sumAmountCol9] = isnull(sum(cast(isnull(restOUT_BU,0) as float)),0)
		from #OSV  --select * from #OSV 
		where acc2order='60324'
		and upper([groupFinRec]) = upper('60324_Резервы под обесценение')
		and [repmonthType] = 1
		) t2 on (t1.RowName='5.4')
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9] * t1.[Aplicator];

/*Расчет итогов по строкам*/

		merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		,[sumAmountCol5] = sum([sumAmountCol5])
		,[sumAmountCol6] = sum([sumAmountCol6])
		,[sumAmountCol7] = sum([sumAmountCol7])
		,[sumAmountCol8] = sum([sumAmountCol8])
		,[sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where razdel = 1
		) t2 on (t1.rowName = '1')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8],
			t1.[sumAmountCol9] = t2.[sumAmountCol9];
	
	merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		,[sumAmountCol5] = sum([sumAmountCol5])
		,[sumAmountCol6] = sum([sumAmountCol6])
		,[sumAmountCol7] = sum([sumAmountCol7])
		,[sumAmountCol8] = sum([sumAmountCol8])
		,[sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where razdel = 2
		) t2 on (t1.rowName = '2')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8],
			t1.[sumAmountCol9] = t2.[sumAmountCol9];

	merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		,[sumAmountCol5] = sum([sumAmountCol5])
		,[sumAmountCol6] = sum([sumAmountCol6])
		,[sumAmountCol7] = sum([sumAmountCol7])
		,[sumAmountCol8] = sum([sumAmountCol8])
		,[sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where razdel = 3
		) t2 on (t1.rowName = '3')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8],
			t1.[sumAmountCol9] = t2.[sumAmountCol9];


	merge into #rep t1
		using(
		select
		[sumAmountCol3] = sum([sumAmountCol3])
		,[sumAmountCol4] = sum([sumAmountCol4])
		,[sumAmountCol5] = sum([sumAmountCol5])
		,[sumAmountCol6] = sum([sumAmountCol6])
		,[sumAmountCol7] = sum([sumAmountCol7])
		,[sumAmountCol8] = sum([sumAmountCol8])
		,[sumAmountCol9] = sum([sumAmountCol9])
		from #rep
		where razdel = 5
		) t2 on (t1.rowName = '5')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3],
			t1.[sumAmountCol4] = t2.[sumAmountCol4],
			t1.[sumAmountCol5] = t2.[sumAmountCol5],
			t1.[sumAmountCol6] = t2.[sumAmountCol6],
			t1.[sumAmountCol7] = t2.[sumAmountCol7],
			t1.[sumAmountCol8] = t2.[sumAmountCol8],
			t1.[sumAmountCol9] = t2.[sumAmountCol9];

/*Расчет итогов по столбцам*/
		merge into #rep t1
		using(
		select
		[sumAmountItog] = [sumAmountCol3]
						+ [sumAmountCol4]
						+ [sumAmountCol5]
						+ [sumAmountCol6]
						+ [sumAmountCol7]
						+ [sumAmountCol8]
						+ [sumAmountCol9]
		,rowName
		from #rep
		where rowName in ('1','2','3','4','5')
		) t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountItog] = t2.[sumAmountItog];

		delete from dwh2.[finAnalytics].[repPublicPL_17_3] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_17_3]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Aplicator], [isBold], [sumAmountCol3], [sumAmountCol4], [sumAmountCol5], [sumAmountCol6], [sumAmountCol7], [sumAmountCol8], [sumAmountCol9], [sumAmountItog])
		select * from #rep

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 17.3'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 17.3 для Публикуемой'
	declare @emailList nvarchar(200)
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

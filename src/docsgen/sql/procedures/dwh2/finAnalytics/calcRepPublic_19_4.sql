






CREATE PROC [finAnalytics].[calcRepPublic_19_4] 
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
	

drop table if exists #OSV
		create table #OSV (
			[acc2order] nvarchar(10) not null,
			[restOUT_BUTek] float not null,
			[restOUT_BUPrev] float not null,
			[clType] nvarchar(300) null
		)

		insert into #OSV
		
		/*тут - Перечисление.ЮридическоеФизическоеЛицо - признак ЮЛ или ФЛ. 
		Если ИП, то АЭ_ИндивидуальныйПредприниматель = истина, а если КО, 
		то да, АЭ_ВидКонтрагента = ЗНАЧЕНИЕ(Перечисление.АЭ_ВидыЮридическихЛиц.КредитнаяОрганизация)*/

		--select
		--acc2order
		--,[clType] 
		--,[restOUT_BUTek] = sum([restOUT_BUTek])
		--,[restOUT_BUPrev] = sum([restOUT_BUPrev])
		--from(
		select
		acc2order
		,[restOUT_BUTek] = case when a.repMonth = @repmonth then abs(sum(isnull(restOUT_BU,0))) else 0 end
		,[restOUT_BUPrev] = case when a.repMonth = @repmonth then 0 else abs(sum(isnull(restOUT_BU,0))) end
		,[clType] = case 
						when cl.АЭ_ИндивидуальныйПредприниматель = 0x01 then 'ИП'
						when upper(clspr.Представление) in	( 
															upper('Кредитная организация'),
															upper('Финансовая организация, находящаяся в федеральной собственности')
															) then 'КО'
						when upper(b.Имя) = upper('ФизическоеЛицо') then 'ФЛ'
						when upper(b.Имя) = upper('ЮридическоеЛицо') then 'ЮЛ'
						else '-'
						end
		from dwh2.finAnalytics.OSV_MONTHLY a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg.[_1cUMFO].[Перечисление_АЭ_ВидыЮридическихЛиц] clspr on cl.АЭ_ВидКонтрагента = clspr.Ссылка
		left join [Stg].[_1cUMFO].[Перечисление_ЮридическоеФизическоеЛицо] b on cl.ЮридическоеФизическоеЛицо = b.Ссылка
		where repmonth in (@repmonth,DATEFROMPARTS(year(@repmonth)-1,12,1))
		
		group by 
		a.repMonth
		,acc2order
		,case 
						when cl.АЭ_ИндивидуальныйПредприниматель = 0x01 then 'ИП'
						when upper(clspr.Представление) in	( 
															upper('Кредитная организация'),
															upper('Финансовая организация, находящаяся в федеральной собственности')
															) then 'КО'
						when upper(b.Имя) = upper('ФизическоеЛицо') then 'ФЛ'
						when upper(b.Имя) = upper('ЮридическоеЛицо') then 'ЮЛ'
						else '-'
						end
		--)l1
		--group by 
		--acc2order
		--,[clType] 
		--order by 2,1

		--select * from #OSV where acc2order = '20501'

		drop table if exists #prov
		create table #prov(
			sumAmount float not null
		)

		declare @repdateFrom date = datefromParts(year(@repmonth),1,1)
		declare @repdateTo date = eomonth(@repmonth)

		declare @dateFrom datetime = dateadd(year,2000,@repdateFrom)
		declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@repdateTo)))
		declare @dateTo datetime = dateadd(second,-1,@dateToTmp)

		insert into #prov

		select
		sumAmount = isnull(sum(isnull(Сумма,0)),0)
		from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
		where a.Период between @dateFrom and @dateTo
		and a.Активность=01
		--сумма Дт 60807 Кт 60806
		and (Kt.Код ='60806' and Dt.Код ='60807')


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
			[sumAmountCol10] float null
		)

		/*Данные из ОСВ без допусловий*/
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
		, [sumAmountCol3] = cast(isnull(osv.restOUT_BUPrev * a.[Aplicator],0) as float)
		, [sumAmountCol4] = 0
		, [sumAmountCol5] = 0
		, [sumAmountCol6] = 0
		, [sumAmountCol7] = 0
		, [sumAmountCol8] = 0
		, [sumAmountCol9] = 0
		, [sumAmountCol10] = cast(isnull(osv.restOUT_BUTek * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_19_4] a
		
		left join (
		select
		osv.acc2order
		,[restOUT_BUTek] = sum(isnull([restOUT_BUTek],0))
		,[restOUT_BUPrev] = sum(isnull([restOUT_BUPrev],0))
		from #OSV osv
		group by
		osv.acc2order
		) osv on a.[Acc2] = osv.acc2order


		/*Данные из ОСВ КО*/
		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]  = a.[RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(osv.restOUT_BUPrev * a.[Aplicator],0) as float)
		, [sumAmountCol4] = 0
		, [sumAmountCol5] = 0
		, [sumAmountCol6] = 0
		, [sumAmountCol7] = 0
		, [sumAmountCol8] = 0
		, [sumAmountCol9] = 0
		, [sumAmountCol10] = cast(isnull(osv.restOUT_BUTek * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_19_4] a
		left join 
		(
		select
		[RowName] = case
						when osv.acc2order = '20503' then '1.1'
						when osv.acc2order = '20504' then '1.2'
						when osv.acc2order = '43108' then '1.3'
						when osv.acc2order = '43109' then '1.4'
						when osv.acc2order = '43118' then '1.5'
						when osv.acc2order = '43119' then '1.6'
						when osv.acc2order = '43120' then '1.7'
						when osv.acc2order = '43708' then '1.8'
						when osv.acc2order = '43709' then '1.9'
						when osv.acc2order = '43718' then '1.10'
						when osv.acc2order = '43719' then '1.11'
						when osv.acc2order = '43720' then '1.12'
						when osv.acc2order = '43721' then '1.13'
					end
		,[restOUT_BUTek] = sum(isnull([restOUT_BUTek],0))
		,[restOUT_BUPrev] = sum(isnull([restOUT_BUPrev],0))
		from #OSV osv
		where osv.acc2order in ('20503','20504','43108','43109','43118','43119','43120','43708','43709','43718','43719','43720','43721')
		and osv.[clType] = 'КО'
		group by
		case
						when osv.acc2order = '20503' then '1.1'
						when osv.acc2order = '20504' then '1.2'
						when osv.acc2order = '43108' then '1.3'
						when osv.acc2order = '43109' then '1.4'
						when osv.acc2order = '43118' then '1.5'
						when osv.acc2order = '43119' then '1.6'
						when osv.acc2order = '43120' then '1.7'
						when osv.acc2order = '43708' then '1.8'
						when osv.acc2order = '43709' then '1.9'
						when osv.acc2order = '43718' then '1.10'
						when osv.acc2order = '43719' then '1.11'
						when osv.acc2order = '43720' then '1.12'
						when osv.acc2order = '43721' then '1.13'
					end
		) osv on a.[RowName] = osv.rowName
		where a.Razdel = 1

		)t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

		/*Данные из ОСВ ЮЛ*/
		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]  = a.[RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(osv.restOUT_BUPrev * a.[Aplicator],0) as float)
		, [sumAmountCol4] = 0
		, [sumAmountCol5] = 0
		, [sumAmountCol6] = 0
		, [sumAmountCol7] = 0
		, [sumAmountCol8] = 0
		, [sumAmountCol9] = 0
		, [sumAmountCol10] = cast(isnull(osv.restOUT_BUTek * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_19_4] a
		left join 
		(
		select
		[RowName] = case
						when osv.acc2order = '42708' then '2.1'
						when osv.acc2order = '42709' then '2.2'

						when osv.acc2order = '42720' then '2.5'
						when osv.acc2order = '42721' then '2.6'
						when osv.acc2order = '42808' then '2.7'
						when osv.acc2order = '42809' then '2.8'
						when osv.acc2order = '42818' then '2.9'
						when osv.acc2order = '42819' then '2.10'
						when osv.acc2order = '42820' then '2.11'
						when osv.acc2order = '42821' then '2.12'
						when osv.acc2order = '42908' then '2.13'
						when osv.acc2order = '42909' then '2.14'

						when osv.acc2order = '42920' then '2.17'
						when osv.acc2order = '42921' then '2.18'
						when osv.acc2order = '43008' then '2.19'
						when osv.acc2order = '43009' then '2.20'

						when osv.acc2order = '43020' then '2.23'
						when osv.acc2order = '43021' then '2.24'
						when osv.acc2order = '43108' then '2.25'
						when osv.acc2order = '43109' then '2.26'
						when osv.acc2order = '43118' then '2.27'
						when osv.acc2order = '43119' then '2.28'
						when osv.acc2order = '43120' then '2.29'
						when osv.acc2order = '43121' then '2.30'
						when osv.acc2order = '43208' then '2.31'
						when osv.acc2order = '43209' then '2.32'
						
						when osv.acc2order = '43220' then '2.35'
						when osv.acc2order = '43221' then '2.36'
						when osv.acc2order = '43308' then '2.37'
						when osv.acc2order = '43309' then '2.38'

						when osv.acc2order = '43320' then '2.41'
						when osv.acc2order = '43321' then '2.42'
						when osv.acc2order = '43408' then '2.43'
						when osv.acc2order = '43409' then '2.44'

						when osv.acc2order = '43420' then '2.47'
						when osv.acc2order = '43421' then '2.48'
						when osv.acc2order = '43508' then '2.49'
						when osv.acc2order = '43509' then '2.50'

						when osv.acc2order = '43520' then '2.53'
						when osv.acc2order = '43521' then '2.54'
						when osv.acc2order = '43608' then '2.55'
						when osv.acc2order = '43609' then '2.56'

						when osv.acc2order = '43620' then '2.59'
						when osv.acc2order = '43621' then '2.60'
						when osv.acc2order = '43808' then '2.61'
						when osv.acc2order = '43809' then '2.62'

						when osv.acc2order = '43820' then '2.64'
						when osv.acc2order = '43821' then '2.65'
						when osv.acc2order = '43908' then '2.66'
						when osv.acc2order = '43909' then '2.67'

						when osv.acc2order = '43920' then '2.70'
						when osv.acc2order = '43921' then '2.71'
						when osv.acc2order = '44008' then '2.72'
						when osv.acc2order = '44009' then '2.73'

						when osv.acc2order = '44020' then '2.76'
						when osv.acc2order = '44021' then '2.77'

					end
		,[restOUT_BUTek] = sum(isnull([restOUT_BUTek],0))
		,[restOUT_BUPrev] = sum(isnull([restOUT_BUPrev],0))
		from #OSV osv
		where osv.acc2order in ('42708','42709','42720','42721','42808','42809','42818','42819','42820','42821','42908','42909'
							   ,'42920','42921','43008','43009','43020','43021','43108','43109','43118','43119','43120','43121'
							   ,'43208','43209','43220','43221','43308','43309','43320','43321','43408','43409','43420','43421'
							   ,'43508','43509','43520','43521','43608','43609','43620','43621','43808','43809','43820','43821'
							   ,'43908','43909','43920','43921','44008','44009','44020','44021')
		and osv.[clType] = 'ЮЛ'
		group by
		case
						when osv.acc2order = '42708' then '2.1'
						when osv.acc2order = '42709' then '2.2'

						when osv.acc2order = '42720' then '2.5'
						when osv.acc2order = '42721' then '2.6'
						when osv.acc2order = '42808' then '2.7'
						when osv.acc2order = '42809' then '2.8'
						when osv.acc2order = '42818' then '2.9'
						when osv.acc2order = '42819' then '2.10'
						when osv.acc2order = '42820' then '2.11'
						when osv.acc2order = '42821' then '2.12'
						when osv.acc2order = '42908' then '2.13'
						when osv.acc2order = '42909' then '2.14'

						when osv.acc2order = '42920' then '2.17'
						when osv.acc2order = '42921' then '2.18'
						when osv.acc2order = '43008' then '2.19'
						when osv.acc2order = '43009' then '2.20'

						when osv.acc2order = '43020' then '2.23'
						when osv.acc2order = '43021' then '2.24'
						when osv.acc2order = '43108' then '2.25'
						when osv.acc2order = '43109' then '2.26'
						when osv.acc2order = '43118' then '2.27'
						when osv.acc2order = '43119' then '2.28'
						when osv.acc2order = '43120' then '2.29'
						when osv.acc2order = '43121' then '2.30'
						when osv.acc2order = '43208' then '2.31'
						when osv.acc2order = '43209' then '2.32'
						
						when osv.acc2order = '43220' then '2.35'
						when osv.acc2order = '43221' then '2.36'
						when osv.acc2order = '43308' then '2.37'
						when osv.acc2order = '43309' then '2.38'

						when osv.acc2order = '43320' then '2.41'
						when osv.acc2order = '43321' then '2.42'
						when osv.acc2order = '43408' then '2.43'
						when osv.acc2order = '43409' then '2.44'

						when osv.acc2order = '43420' then '2.47'
						when osv.acc2order = '43421' then '2.48'
						when osv.acc2order = '43508' then '2.49'
						when osv.acc2order = '43509' then '2.50'

						when osv.acc2order = '43520' then '2.53'
						when osv.acc2order = '43521' then '2.54'
						when osv.acc2order = '43608' then '2.55'
						when osv.acc2order = '43609' then '2.56'

						when osv.acc2order = '43620' then '2.59'
						when osv.acc2order = '43621' then '2.60'
						when osv.acc2order = '43808' then '2.61'
						when osv.acc2order = '43809' then '2.62'

						when osv.acc2order = '43820' then '2.64'
						when osv.acc2order = '43821' then '2.65'
						when osv.acc2order = '43908' then '2.66'
						when osv.acc2order = '43909' then '2.67'

						when osv.acc2order = '43920' then '2.70'
						when osv.acc2order = '43921' then '2.71'
						when osv.acc2order = '44008' then '2.72'
						when osv.acc2order = '44009' then '2.73'

						when osv.acc2order = '44020' then '2.76'
						when osv.acc2order = '44021' then '2.77'
					end
		) osv on a.[RowName] = osv.rowName
		where a.Razdel = 2
		)t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];


		/*Данные из ОСВ ФЛ*/
		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]  = a.[RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(osv.restOUT_BUPrev * a.[Aplicator],0) as float)
		, [sumAmountCol4] = 0
		, [sumAmountCol5] = 0
		, [sumAmountCol6] = 0
		, [sumAmountCol7] = 0
		, [sumAmountCol8] = 0
		, [sumAmountCol9] = 0
		, [sumAmountCol10] = cast(isnull(osv.restOUT_BUTek * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_19_4] a
		left join 
		(
		select
		[RowName] = case
						when osv.acc2order = '42316' then '3.1'
						when osv.acc2order = '42317' then '3.2'
						
						when osv.acc2order = '42320' then '3.5'
						when osv.acc2order = '42321' then '3.6'
						when osv.acc2order = '42616' then '3.7'
						when osv.acc2order = '42617' then '3.8'
						when osv.acc2order = '42618' then '3.9'
						
						when osv.acc2order = '42620' then '3.11'
						when osv.acc2order = '42621' then '3.12'
					end
		,[restOUT_BUTek] = sum(isnull([restOUT_BUTek],0))
		,[restOUT_BUPrev] = sum(isnull([restOUT_BUPrev],0))
		from #OSV osv
		where osv.acc2order in ('42316','42317','42320','42321','42616','42617','42618','42620','42621')
		and osv.[clType] = 'ФЛ'
		group by
		case
						when osv.acc2order = '42316' then '3.1'
						when osv.acc2order = '42317' then '3.2'
						
						when osv.acc2order = '42320' then '3.5'
						when osv.acc2order = '42321' then '3.6'
						when osv.acc2order = '42616' then '3.7'
						when osv.acc2order = '42617' then '3.8'
						when osv.acc2order = '42618' then '3.9'
						
						when osv.acc2order = '42620' then '3.11'
						when osv.acc2order = '42621' then '3.12'
					end
		) osv on a.[RowName] = osv.rowName
		where a.Razdel = 3
		)t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

		/*Данные из ОСВ ИП*/
		merge into #rep t1
		using(
		select
		repmonth = @repmonth
		, [RowNum]
		, [Razdel]
		, [RowName]  = a.[RowName]
		, [Pokazatel]
		, [Acc2]
		, [Aplicator]
		, [isBold]
		, [sumAmountCol3] = cast(isnull(osv.restOUT_BUPrev * a.[Aplicator],0) as float)
		, [sumAmountCol4] = 0
		, [sumAmountCol5] = 0
		, [sumAmountCol6] = 0
		, [sumAmountCol7] = 0
		, [sumAmountCol8] = 0
		, [sumAmountCol9] = 0
		, [sumAmountCol10] = cast(isnull(osv.restOUT_BUTek * a.[Aplicator],0) as float)
		from dwh2.[finAnalytics].[SPR_repPublicPL_19_4] a
		left join 
		(
		select
		[RowName] = case
						when osv.acc2order = '42316' then '4.1'
						when osv.acc2order = '42317' then '4.2'
						when osv.acc2order = '42318' then '4.3'
						when osv.acc2order = '42319' then '4.4'
						when osv.acc2order = '42320' then '4.5'
						when osv.acc2order = '42321' then '4.6'
						when osv.acc2order = '42616' then '4.7'
						when osv.acc2order = '42617' then '4.8'
						when osv.acc2order = '42618' then '4.9'
						when osv.acc2order = '42619' then '4.10'
						when osv.acc2order = '42620' then '4.11'
						when osv.acc2order = '42621' then '4.12'
					end
		,[restOUT_BUTek] = sum(isnull([restOUT_BUTek],0))
		,[restOUT_BUPrev] = sum(isnull([restOUT_BUPrev],0))
		from #OSV osv
		where osv.acc2order in ('42316','42317','42318','42319','42320','42321','42616','42617','42618','42619','42620','42621')
		and osv.[clType] = 'ИП'
		group by
		case
						when osv.acc2order = '42316' then '4.1'
						when osv.acc2order = '42317' then '4.2'
						when osv.acc2order = '42318' then '4.3'
						when osv.acc2order = '42319' then '4.4'
						when osv.acc2order = '42320' then '4.5'
						when osv.acc2order = '42321' then '4.6'
						when osv.acc2order = '42616' then '4.7'
						when osv.acc2order = '42617' then '4.8'
						when osv.acc2order = '42618' then '4.9'
						when osv.acc2order = '42619' then '4.10'
						when osv.acc2order = '42620' then '4.11'
						when osv.acc2order = '42621' then '4.12'
					end
		) osv on a.[RowName] = osv.rowName
		where a.Razdel = 4
		)t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

		/*Данные из проводок*/
		merge into #rep t1
		using(
		select
		sumAmount
		from #prov
		) t2 on (t1.rowName = '5.1')
		when matched then update
		set t1.[sumAmountCol7] = t2.[sumAmount];

		/*Расчет итогов по столбцу 9*/
		merge into #rep t1
		using(
		select
		rowName
		,[sumAmountCol9] = [sumAmountCol5] 
		    				+ [sumAmountCol6]
			    			+ [sumAmountCol7]
				    		+ [sumAmountCol8]
		from #rep
		where rowName not in ('1','2','3','4','5','6','7','8')
		) t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountCol9] = t2.[sumAmountCol9];

		/*Расчет итогов по столбцу 4*/
		merge into #rep t1
		using(
		select
		rowName
		,[sumAmountCol4] = [sumAmountCol10] 
		    				- [sumAmountCol3]
			    			- [sumAmountCol9]
		from #rep
		where rowName not in ('1','2','3','4','5','6','7','8')
		) t2 on (t1.rowName = t2.rowName)
		when matched then update
		set t1.[sumAmountCol4] = t2.[sumAmountCol4];

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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 1
		) t2 on (t1.rowName = '1')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];


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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 2
		) t2 on (t1.rowName = '2')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 3
		) t2 on (t1.rowName = '3')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 4
		) t2 on (t1.rowName = '4')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 5
		) t2 on (t1.rowName = '5')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 6
		) t2 on (t1.rowName = '6')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 7
		) t2 on (t1.rowName = '7')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];

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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where razdel = 8
		) t2 on (t1.rowName = '8')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];


		
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
		,[sumAmountCol10] = sum([sumAmountCol10])
		from #rep
		where rowName in ('1','2','3','4','5','6','7','8')
		) t2 on (t1.rowName = '9')
		when matched then update
		set t1.[sumAmountCol3] = t2.[sumAmountCol3]
			,t1.[sumAmountCol4] = t2.[sumAmountCol4]
			,t1.[sumAmountCol5] = t2.[sumAmountCol5]
			,t1.[sumAmountCol6] = t2.[sumAmountCol6]
			,t1.[sumAmountCol7] = t2.[sumAmountCol7]
			,t1.[sumAmountCol8] = t2.[sumAmountCol8]
			,t1.[sumAmountCol9] = t2.[sumAmountCol9]
			,t1.[sumAmountCol10] = t2.[sumAmountCol10];



		delete from dwh2.[finAnalytics].[repPublicPL_19_4] where repmonth = @repmonth

		insert into dwh2.[finAnalytics].[repPublicPL_19_4]
		([repmonth], [RowNum], [Razdel], [RowName], [Pokazatel], [Acc2], [Aplicator], [isBold], [sumAmountCol3], [sumAmountCol4], [sumAmountCol5], [sumAmountCol6], [sumAmountCol7], [sumAmountCol8], [sumAmountCol9], [sumAmountCol10])

		select * from #rep order by rowNum

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для публикуемой отчетности Таблица 19.4'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета 19.4 для Публикуемой'
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

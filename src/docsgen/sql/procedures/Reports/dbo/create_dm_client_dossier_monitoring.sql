--Создание витрины - мониторинг клиентское досье bp-980 - базовая витрина
CREATE   procedure [dbo].[create_dm_client_dossier_monitoring]
	@reCreateTable bit = 0
as
begin try
	--declare @reCreateTable bit = 0
   --Получаем список печатных форм из ЛКП
	drop table if exists #t_lk_request_filed
	select 
		external_id,
		partner_id,
		partnerName=  isnull(partnerName, 'N/A'),
		partnerFullName =  TRIM(concat(partnerName, ' ', pointName)),
		pointName,
		point_id,
		fullFileName,
		FormName = TRIM(SUBSTRING(fullFileName, 0, charindex('.', fullFileName))),
		fileId,
		status_client_files
		into #t_lk_request_filed
	from (
	select distinct 
		external_id = r.num_1c,
		partner_id = isnull(poi.partner_id, -1),
		partnerName = isnull(par.Name, 'N/A'),
		point_id = isnull(r.point_id, -1),
		pointName = isnull(poi.Name, 'N/A'),
		fullFileName = cast(f.name as nvarchar(255)),
		fileId = f.Id,
		status_client_files = case r.status_client_files
			when 0 then 'Ожидание сканов'
			when 1 then 'Отправлен на проверку'
			when 2 then 'Требуется корректировка'
			when 3 then 'Принят'
			else 'N/A'
			end
		
	from stg._lk.requests r
		inner join stg.[_LK].[request_file] rf on rf.request_id = r.Id
			and charindex('doc_pack_', rf.file_bind )>0
		inner join stg._lk.[file] f on f.id = rf.file_id
		left join stg._lk.points poi on poi.id = r.point_id
		left join stg._lk.partners par on par.id = poi.partner_id
	where r.pep_state_before_sign  = 0
		and isnull(r.[is_installment],0) = 0
	) t
	
	--Наименование печатных форм берем из ЛКП -- 
	drop table if exists #t_formName
	select distinct 
		FormName = case FormName 
			when 'анкета' then 'заявление-анкета '
			when 'Анкета Приложение' then 'приложение к заявлению анкете'
			when 'Индивидуальные условия по договору' then 'индивидуальные условия договора микрозайма'
			when 'ДОУ КАСКО' then 'ДОУ по КАСКО'
			else FormName
		end 
		,OrignalFormName = FormName
	into #t_formName
	from #t_lk_request_filed
	where FormName in 
	( 
		'анкета',
		'Анкета Приложение',
		'согласие на обработку персональных данных',
		'Индивидуальные условия по договору',
		'график платежей',
		'договор залога ТС',
		'ДОУ по Финансовая защита',
		'ДОУ КАСКО'
	)

	--select distinct FormName from #t_lk_request_filed
	--where FormName like '% КАСКО%'
	/*
		договор страхования(полис) телемедицина
		договор страхования (полис) от потери работы
		заявление о включении в список застрахованных+программа страхования финансовая защита	
		заявление о включении в список застрахованных+программа страхования КАСКО
	*/
	 
 --заявление-анкета 	
 --приложение к заявлению анкете	
 --договор залога ТС	
 --договор страхования(полис) телемедицина	
 --договор страхования (полис) от потери работы	
 --ДОУ по Финансовая защита	
 --заявление о включении в список застрахованных+программа страхования финансовая защита	
 --ДОУ по КАСКО	
 --заявление о включении в список застрахованных+программа страхования КАСКО
	drop table if exists #t_Сведения
	select Ссылка, Заголовок 
	into #t_Сведения
		--select  *
		from stg._1cDCMNT.[ПланВидовХарактеристик_ДополнительныеРеквизитыИСведения]
		--where Наименование like 'ФИО%'
	where Наименование in 
	(
		'Номер заявки (Заем)', 
		'Дата заявки (Заем)', 
	--	'Наименование партнера (Заем)', 
		'Дата договора основания (Заем)',
		'Дата договора микрозайма (Заем)',
		'installment (Заем)', 
		'Кредитный продукт (Заем)'
	)
	--select * from #t_Сведения
	--select * from _1cDCMNT.[ПланВидовХарактеристик_ДополнительныеРеквизитыИСведения]
	--where Заголовок like '%Дата дог%'
	--Собираем реквезиты по документам
drop table if exists #t_ДополнительныеРеквизиты
;with cte_ДополнительныеРеквизиты as (
	select 
		ВнутренниеДокументы_Ссылка = ДополнительныеРеквизит.Ссылка,
		Реквизит = Сведения.Заголовок,
		Значение_Тип = ДополнительныеРеквизит.Значение_Тип,
		Значение_Булево  = iif(ДополнительныеРеквизит.Значение_Тип =0x02,  ДополнительныеРеквизит.Значение_Булево, null),
		Значение_Строка  = iif(ДополнительныеРеквизит.Значение_Тип =0x05, ДополнительныеРеквизит.Значение_Строка, null),
		Значение_Число = iif(ДополнительныеРеквизит.Значение_Тип =0x03, ДополнительныеРеквизит.Значение_Число, null),
		Значение_Дата =  iif(ДополнительныеРеквизит.Значение_Тип =0x04, dateadd(year,-2000, Значение_Дата), null),

		Значение = case ДополнительныеРеквизит.Значение_Тип
			when 0x02 then iif(ДополнительныеРеквизит.Значение_Булево=0x01, '1', '0')
			when 0x03 then FORMAT(ДополнительныеРеквизит.Значение_Число, 'N')
			when 0x04 then FORMAT(dateadd(year,-2000, Значение_Дата), 'yyyy-MM-dd HH:mm:ss')
			when 0x05 then ДополнительныеРеквизит.Значение_Строка
		end
		
	from stg._1cDCMNT.Справочник_ВнутренниеДокументы_ДополнительныеРеквизиты ДополнительныеРеквизит
		inner join  #t_Сведения Сведения on  Сведения.Ссылка = ДополнительныеРеквизит.Свойство
	

), cte_ДополнительныеРеквизиты_PVT as 
(
	select ВнутренниеДокументы_Ссылка
		,[Номер заявки] = max(PVT.[Номер заявки])  
		,[Дата заявки] = max(pvt.[Дата заявки])
	--	,[Наименование партнера] = max(pvt.[Наименование партнера])
		,[Дата договора микрозайма] = max([Дата договора микрозайма])
		,[Дата договора основания]	= max([Дата договора основания])
		,[installment]				= max([installment])
		,[Кредитный продукт]		= max([Кредитный продукт])

		from cte_ДополнительныеРеквизиты t
	pivot ( 
		max(t.Значение)
		for Реквизит IN (
			[Номер заявки], 
			[Дата заявки], 
			--[Наименование партнера], 
			[Дата договора микрозайма], 
			[Дата договора основания],
			[installment],
			[Кредитный продукт]

			)
	)
	 as PVT
	 group by ВнутренниеДокументы_Ссылка
)

select * 
into #t_ДополнительныеРеквизиты
from cte_ДополнительныеРеквизиты_PVT t
where exists (select top(1) 1 from #t_lk_request_filed r where r.external_id =  t.[Номер заявки])
and isnull(installment,0) = 0


drop table if exists #t_ЗадачаИсполнителя
select 
	документ.ВнутренниеДокументы_Ссылка,
	документ.[Номер заявки],
	Задача_Исполнителя_Ссылка = задача_Исполнителя.Ссылка,
	Задача_Дата = nullif(dateadd(year,-2000, задача_Исполнителя.Дата), '0001-01-01 00:00:00'),
	Задача_ДатаНачала = nullif(dateadd(year,-2000, задача_Исполнителя.ДатаНачала),'0001-01-01 00:00:00'),
	Задача_ДатаИсполнения = nullif(dateadd(year,-2000, задача_Исполнителя.ДатаИсполнения), '0001-01-01 00:00:00'),
	Задача_ДатаПринятияКИсполнению = nullif(dateadd(year,-2000, задача_Исполнителя.ДатаПринятияКИсполнению), '0001-01-01 00:00:00'),
	ПринятаКИсполнению = cast(iif(ПринятаКИсполнению= 0x01, 1,0) as bit),
	Задача_РезультатВыполнения = задача_Исполнителя.РезультатВыполнения

	into #t_ЗадачаИсполнителя
	from #t_ДополнительныеРеквизиты  документ
	inner join stg._1cDCMNT.Задача_ЗадачаИсполнителя_Предметы задачаИсполнителя_Предметы
		on задачаИсполнителя_Предметы.Предмет_Ссылка = ВнутренниеДокументы_Ссылка
		and задачаИсполнителя_Предметы.Предмет_ТипСсылки = 0x00000048
	inner join	stg._1cDCMNT.Задача_ЗадачаИсполнителя задача_Исполнителя on задачаИсполнителя_Предметы.Ссылка = задача_Исполнителя.Ссылка
	
	

drop table if exists #lkp_request_result
;with cte_lkp_request_filed as 
(
select external_id, 
	rf.status_client_files,
	rf.partnerName,
	rf.pointName,
	rf.partnerFullName,
	rf.partner_id,
	rf.point_id,
	rf.fileId, 
	fn.FormName 
	from #t_lk_request_filed rf
	inner join #t_formName fn  on fn.OrignalFormName = rf.FormName
), cte_lkp_request_filed_pvt as (
	select 
		external_id
		,status_client_files
		,partnerName
		,pointName
		,partnerFullName
		,point_id
		,partner_id
		,[заявление-анкета] = MAX(iif([заявление-анкета] is not null, 'Да', 'Нет'))
		,[приложение к заявлению анкете] = MAX(iif([приложение к заявлению анкете] is not null, 'Да', 'Нет'))
		,[Согласие на обработку персональных данных] = MAX(iif([Согласие на обработку персональных данных] is not null, 'Да', 'Нет'))
		,[индивидуальные условия договора микрозайма] = MAX(iif([индивидуальные условия договора микрозайма] is not null, 'Да', 'Нет'))
		,[График платежей]  = MAX(iif([График платежей] is not null, 'Да', 'Нет'))
		,[Договор залога ТС] = MAX(iif([Договор залога ТС] is not null, 'Да', 'Нет')) 
		,[ДОУ по Финансовая защита] =  MAX(iif([ДОУ по Финансовая защита] is not null, 'Да', 'Нет')) 
		,[ДОУ по КАСКО] =  MAX(iif([ДОУ по КАСКО] is not null, 'Да', 'Нет')) 
	from cte_lkp_request_filed
	pivot (
		max(fileId)
		for FormName IN (
			 [заявление-анкета],
			 [приложение к заявлению анкете],
			 [Согласие на обработку персональных данных],
			 [индивидуальные условия договора микрозайма],
			 [График платежей], 
			 [Договор залога ТС], 
			 [ДОУ по Финансовая защита], 
			 [ДОУ по КАСКО]
			) 
	) pvt
	group by external_id,
	status_client_files,
	partnerName,
	pointName,
	partnerFullName,
	point_id,
	partner_id
)
select *
into #lkp_request_result
from cte_lkp_request_filed_pvt


create clustered index ix_external_id on #lkp_request_result (external_id)
--select * from #lkp_request_result
create clustered index ix_Ссылка on #t_ДополнительныеРеквизиты(ВнутренниеДокументы_Ссылка)

drop table if exists #t_Result
select distinct
	--Контрагент_Ссылка = Контрагент.Ссылка, 
	lkp_rr.partner_id,
	lkp_rr.partnerName,
	lkp_rr.point_id,
	lkp_rr.pointName,
	[Место оформление (партнер)] = lkp_rr.partnerFullName,
	--[Место оформление (партнер)] = ДополнительныеРеквизиты.[Наименование партнера],  --Место оформление (партнер)
	ДополнительныеРеквизиты.[Номер заявки],
	[ФИО клиента] =  Контрагент.НаименованиеПолное, --ФИО
	[Дата оформления] = COALESCE(ДополнительныеРеквизиты.[Дата договора микрозайма], ДополнительныеРеквизиты.[Дата заявки]), --Дата оформления
	[Кредитный продукт],
	[Статус размещения документов] = lkp_rr.status_client_files,
	[Дата отправки на проверку в архив] = задача.Задача_ДатаНачала,
	[Наличие замечаний от архива] =cast(null as nvarchar(255)),
	[Дата отправки замечаний агенту от архива] =cast(null as datetime),
	[Комментарии от архива] =  cast(null as nvarchar(1024)),
	[Дата получения доработаных документов] = cast(null as datetime),

	lkp_rr.[заявление-анкета],
	lkp_rr.[приложение к заявлению анкете],
	lkp_rr.[Согласие на обработку персональных данных],
	lkp_rr.[индивидуальные условия договора микрозайма],
	lkp_rr.[График платежей], 
	lkp_rr.[Договор залога ТС], 
	lkp_rr.[ДОУ по Финансовая защита], 
	lkp_rr.[ДОУ по КАСКО]
	into #t_Result
	from #lkp_request_result lkp_rr 
	inner join #t_ДополнительныеРеквизиты  ДополнительныеРеквизиты on ДополнительныеРеквизиты.[Номер заявки] = lkp_rr.external_id
	inner join stg._1Cdcmnt.Справочник_ВнутренниеДокументы ВнутренниеДокумент  on ДополнительныеРеквизиты.ВнутренниеДокументы_Ссылка= ВнутренниеДокумент.Ссылка
		and ВнутренниеДокумент.ПометкаУдаления = 0x00
	inner join stg._1Cdcmnt.Справочник_Контрагенты  Контрагент on Контрагент.Ссылка = ВнутренниеДокумент.Контрагент
	left join #t_ЗадачаИсполнителя задача on задача.ВнутренниеДокументы_Ссылка = ВнутренниеДокумент.Ссылка
order by [Дата оформления] desc




	if @reCreateTable = 1
	begin
		drop table if exists dbo.dm_client_dossier_monitoring
	end
	if OBJECT_ID('dbo.dm_client_dossier_monitoring') is null
	begin
		select top(0) 
		* 
		into dbo.dm_client_dossier_monitoring
		from #t_Result
	end
	delete from  dbo.dm_client_dossier_monitoring
	insert into dbo.dm_client_dossier_monitoring
	select * from #t_Result

end try
begin catch
	if @@TRANCOUNT>0 
		rollback tran
	;throw
end catch

	
	
	

	


	



/*
with cte as (
select count(1)  over(partition by number) cnt, * from dm_restructurings
where operation_type = 'Кредитные каникулы'
)
select * from cte
where cnt>1


order by 
select * from dbo.dm_restructurings
where operation_type is null
select * from stg._1cCMR.Документ_ОбращениеКлиента ок
inner join stg._1cCmr.Перечисление_ВидыОперацийОбращениеКлиента воок on воок.Ссылка = ок.ВидОперации
where Договор = 0xA2CE00155D4D1B0C11E8FC5EC3A16534
select * from dbo.dm_restructurings
where  reason_credit_vacation= 'Пролонгация PDL'
order by number
select * from dbo.dm_restructurings
where  reason_credit_vacation= 'Пролонгация PDL'
and 

*/

CREATE       procedure [dbo].[create_dm_restructurings]
as
begin
	
begin try	

	drop table if exists #t_data
	create table #t_data
	(
		Договор							binary(16),
		КодДоговора						varchar(100),
		
		ОбращениеКлиента				binary(16)		null,
		ДатаОбращениеКлиента			datetime			,
		ДатаСтарта						date				,
		ДатаОкончания					date			null,
		НомерОбращенияКлиента			nvarchar(1024)  null,
		reason_credit_vacation			nvarchar(1024)  null,
		ВидОперации						nvarchar(1024)  null,
		ВидРеструктуризации				nvarchar(1024)  null,
		ДатаУдаления					date			null,
		ПометкаУдаления					bit				null,
		Проведен						bit				null,
		СрокКредитныхКаникул			smallint		null,
		НоваяДатаОкончанияДоговора		date			null,
		ДатаСозданияОбращения			datetime		null
	)
	insert into #t_data
	select distinct
		Договор							= д.Ссылка,
		КодДоговора						= д.Код,
		ОбращениеКлиента				= ок.Ссылка,
		ДатаОбращениеКлиента			= dateadd(year,-2000, ок.Дата),
		ДатаСтарта						= 
		nullif(case
			when воок.Представление = 'Кредитные каникулы' then dateadd(year,-2000, ок.Дата)
			when вр.Наименование = 'Заморозка 1.0' then dateadd(year,-2000, р.Дата)
			else  dateadd(year,-2000, ок.Дата)
			end
		, '0001-01-01 00:00:00'),
		ДатаОкончания	= 
		nullif(case
			when воок.Представление = 'Кредитные каникулы' then dateadd(year, -2000, ок.ДатаОкончанияКредитныхКаникул)
			when вр.Наименование = 'Заморозка 1.0' then Последний0платеж
			
			end
		, '0001-01-01 00:00:00'),
		НомерОбращенияКлиента			= ок.Номер,
		reason_credit_vacation			= 		
		coalesce(
			 nullif(ок.ПричинаПредоставленияКредитныхКаникул, '')
			,nullif(ок.Комментарий, '')
			,case воок.Представление 
				when 'Реструктуризация' then 'Пролонгация' --По согласованию с А.Кузнецовым 
				end
			--,nullif(воок.Имя, '')
			),
		ВидОперации						= 
			--По согласование с Кузнецовы А 01.01.2022
			case when charindex('Военные кредитные каникулы', ок.ПричинаПредоставленияКредитныхКаникул)>0 then 'Кредитные каникулы'
			else воок.Представление end,
		ВидРеструктуризации				= вр.Наименование,
		ДатаУдаления = DATEADD(year,-2000,иио.Период),
	
		ок.ПометкаУдаления ,
		ок.Проведен,
		ок.СрокКредитныхКаникул,
		НоваяДатаОкончанияДоговора = iif(year(ПараметрыДоговора.ДатаОкончания)>3000, dateadd(year,-2000,
			ПараметрыДоговора.ДатаОкончания), null)
		,ДатаСозданияОбращения =  iif(year(ок.ДатаСоздания)>3000, dateadd(year,-2000, ок.ДатаСоздания), null)
	from stg._1cCMR.Справочник_Договоры д
		inner join stg._1cCMR.Документ_ОбращениеКлиента ок on ок.Договор = д.Ссылка
			--нет отката обращения по заявлению
			and not exists(select top(1) 1 from stg._1cCmr.РегистрСведений_Реструктуризация откат
				inner join stg._1cCmr.[Перечисление_СтатусыРеструктуризации] ср on ср.Ссылка = откат.Статус
			where откат.Договор = ок.Договор 
			and  откат.Заявление = ок.Ссылка
			and ср.Имя = 'Откат'
			)
			-- и само обращение не откат
			and not exists(select top(1) 1 from stg._1cCmr.РегистрСведений_Реструктуризация откат
				inner join stg._1cCmr.[Перечисление_СтатусыРеструктуризации] ср on ср.Ссылка = откат.Статус
			where откат.Договор = ок.Договор 
			and  откат.Регистратор_Ссылка = ок.Ссылка
			 and Регистратор_ТипСсылки = 0x0000126C--Документ_ОбращениеКлиента
			and ср.Имя = 'Откат'
			)
		inner join stg._1cCmr.Перечисление_ВидыОперацийОбращениеКлиента воок on воок.Ссылка = ок.ВидОперации
			
		left join stg._1cCmr.РегистрСведений_Реструктуризация р on р.Договор = ок.Договор 
			--and р.Заявление = ок.Ссылка
			and	 р.Регистратор_Ссылка = ок.Ссылка
				and Регистратор_ТипСсылки = 0x0000126C--Документ_ОбращениеКлиента
			
		left join  stg._1cCmr.Справочник_ВидыРеструктуризаций вр on вр.Ссылка =  isnull(р.ВидРеструктуризации , ок.ВидРеструктуризации)

		--left join stg._1cCmr.[Перечисление_СтатусыРеструктуризации] ср on ср.Ссылка = р.Статус
		left join 
		(
			select Период = max (Период), Объект_Ссылка 
			from stg._1cCMR.РегистрСведений_ИсторияИзмененияОбъектов
			where Объект_ТипСсылки = 	0x0000126C
			group by Объект_Ссылка
		) иио on иио.Объект_Ссылка = ок.Ссылка
			and ок.ПометкаУдаления = 0x01
		
		--Дату окончания заморозки берем через последний платеж с суммой  =0 

		left join
		(
			select Договор_Ссылка = Договор, 
				Регистратор_Ссылка,  
				Период,
				Последний0платеж = 
					cast(dateadd(year,-2000, max(ДатаПлатежа)) as date)
			from  stg._1cCMR.РегистрСведений_ДанныеГрафикаПлатежей
			where Действует = 0x01
			and СуммаПлатежа = 0.00
			group by Договор, Регистратор_Ссылка, Период
		) ДанныеГрафикаПлатежей on ДанныеГрафикаПлатежей.Договор_Ссылка = ок.Договор
		--and ДанныеГрафикаПлатежей.Регистратор =  
		--Более верно всеже соединять через Регистратор, чем через дату.
			and cast(ДанныеГрафикаПлатежей.Период as date) =  cast(р.Дата as date)
			and вр.Наименование = 'Заморозка 1.0'

		left join stg._1cCMR.РегистрСведений_ПараметрыДоговора  ПараметрыДоговора
			on ПараметрыДоговора.Договор = ок.Договор
			and (ПараметрыДоговора.Регистратор_Ссылка  = ок.График
				or (ок.График = 0x
					and cast(ПараметрыДоговора.Период as date) = cast(ок.Дата as date)
					)
					)

		where д.ПометкаУдаления =0x
		----PDLПролонгации считаем отдельно
		and not exists(select top(1) 1 from stg.[_1cCMR].[РегистрНакопления_PDLПролонгации]  PDLПролонгации
			where PDLПролонгации.Договор  = ок.Договор
			and PDLПролонгации.Регистратор_Ссылка = ок.График) 
		and isnull(вр.Наименование,'') not in ('Пролонгация PDL', 'ПролонгацияPDL')
		--and д.КОд = '18121012690001'
		and воок.Представление not in ('Смена даты платежа')
		and ((ок.ПометкаУдаления = 0x0 and ок.Проведен =0x01) or 
		--Если КК смотри что были другие
			(воок.Представление = 'Кредитные каникулы'
			and exists(Select top(1) 1 from stg._1cCMR.Документ_ОбращениеКлиента ок_другие
			where ок_другие.ПометкаУдаления = 0x0 and ок_другие.Проведен =0x01
			and ок_другие.Договор = д.Ссылка
			and ок_другие.ВидОперации = 0xB7DCDAEEBB3606B645BABE3167B3379A --КК
			and ок_другие.Ссылка!=ок.Ссылка
				))
			)

	
	insert into #t_data (
			 Договор							
			,КодДоговора						
	
			,ДатаСтарта			
			,ВидОперации						
			,ВидРеструктуризации	
			,reason_credit_vacation
			,НоваяДатаОкончанияДоговора
			,Проведен

	
	)
		select договор= д.Ссылка,
		договорКод = д.Код,
		ДатаСтарта = dateadd(year,-2000, доа.Период),
		ВидОперации = 'Акция Реструктуризация',
		ВидРеструктуризации = а.Наименование,
		reason_credit_vacation =  а.Наименование, --Наименование акции
		НоваяДатаОкончанияДоговора = iif(year(ПараметрыДоговора.ДатаОкончания)>3000, dateadd(year,-2000,
			ПараметрыДоговора.ДатаОкончания), null),
		Проведен = 1
	from stg._1cCmr.Справочник_договоры д

	inner join stg._1cCmr.РегистрНакопления_ДанныеОтработанныхАкций доа on доа.Договор = д.Ссылка
	inner join stg._1cCmr.[Справочник_Акции] а on а.ССылка = доа.Акция
	left join stg._1cCMR.РегистрСведений_ПараметрыДоговора  ПараметрыДоговора
			on ПараметрыДоговора.Договор = д.Ссылка
			and cast(ПараметрыДоговора.Период as date) = cast(доа.Период as date)

	
	where д.ПометкаУдаления =0x
		and а.Наименование = 'Оферта 20% + новый график'
	
	insert into #t_data (
			 Договор							
			,КодДоговора	
			,ДатаОбращениеКлиента
			,ДатаСтарта		
			,ДатаОкончания
			,ВидОперации						
			,ВидРеструктуризации	
			,reason_credit_vacation
			,НоваяДатаОкончанияДоговора
			,Проведен
			,ДатаСозданияОбращения
			,НомерОбращенияКлиента			
	
	)


	select
		 Договор				= д.Ссылка				
		,КодДоговора			= д.Код	
		,ДатаОбращениеКлиента	= dateadd(year,-2000, ок.Дата)
		,ДатаСтарта				= dateadd(year,-2000, PDLПролонгации.Период)
		,ДатаОкончания			= dateadd(year,-2000, парам_договора.ДатаОкончания)
		,ВидОперации			= 'Реструктуризация'
		,ВидРеструктуризации	=  null
		,reason_credit_vacation = 'Пролонгация PDL'
		,НоваяДатаОкончанияДоговора = iif(year(парам_договора.ДатаОкончания)>3000, dateadd(year,-2000,
			парам_договора.ДатаОкончания), null)
		,Проведен = 1
		,ДатаСозданияОбращения = iif(year(ок.ДатаСоздания)>3000, dateadd(year,-2000, ок.ДатаСоздания), null)
		,НомерОбращенияКлиента = ок.Номер
	from stg._1cCmr.Справочник_договоры д
	inner join stg.[_1cCMR].[РегистрНакопления_PDLПролонгации] PDLПролонгации
		on PDLПролонгации.Договор = д.Ссылка
	inner join stg._1cCMR.РегистрСведений_ПараметрыДоговора	 парам_договора
			on парам_договора.Договор= PDLПролонгации.Договор
				and парам_договора.Регистратор_Ссылка = PDLПролонгации.Регистратор_Ссылка
					and парам_договора.Регистратор_ТипСсылки = 0x0000005E
					and парам_договора.Период = PDLПролонгации.Период 
	left join stg._1cCMR.Документ_ОбращениеКлиента ок on ок.Договор = PDLПролонгации.Договор
			and ок.График = PDLПролонгации.Регистратор_Ссылка 
				
			and ок.Проведен = 0x01
			and ок.ПометкаУдаления = 0x0
	where PDLПролонгации.ВидДвижения = 1

	--для КК типа Военные кредитные каникулы проставляем  ДатаОкончания = ДатаСтарта - 1 от следующего заявления
	;with cte as
	(
		select *
			,newДатаОкончания = 
			lead(dateadd(dd, -1, ДатаСтарта), 1, null) over(partition by КодДоговора order by НомерОбращенияКлиента)
		from #t_data
	where ВидОперации = 'Кредитные каникулы'
		and reason_credit_vacation ='Военные кредитные каникулы'
	)
	update cte
		set ДатаОкончания = newДатаОкончания
	where ДатаОкончания is null

	--удаляем те записи у которых ДатаОкончания одинаковы
	;with cte as (
		select 
			nRow = ROW_NUMBER() over(partition by 
			КодДоговора, ДатаОкончания order by НомерОбращенияКлиента desc) 
			,*
		from #t_data
	where ВидОперации = 'Кредитные каникулы'
		
	)
	--Если было более 2х обращений с одной датой окончания, оставляем только последние
	delete from cte
	where nRow>1

	;with  cte_to_update as(
	select * 

		,Correct_ДатаСтарта = lag(dateadd(dd, 1, ДатаОкончания), 1, ДатаСтарта) over(partition by КодДоговора order by  ДатаОкончания)
	from #t_data
	where ВидОперации = 'Кредитные каникулы'
	)
	--Проставляем дату старта ДатаОкончания+ 1
	update t
		set ДатаСтарта =Correct_ДатаСтарта  from cte_to_update t
	where Correct_ДатаСтарта !=  ДатаСтарта

	--найдем те договора у которых были проводки после проведенной записи
	;with cte_last as (
		select ДатаОкончания = min(ДатаОкончания), КодДоговора from #t_data
		where ВидОперации = 'Кредитные каникулы'
		and Проведен = 1
		and ПометкаУдаления = 0
		group by КодДоговора
	)
	--удаляем те периоды, которые были уже после проведенных КК и отмечены как удалены.
	, cte_to_del as (
		select d.* from #t_data d
		where ВидОперации = 'Кредитные каникулы'
			and ПометкаУдаления = 1
			and exists(select top(1) 1from cte_last cte
			where cte.КодДоговора = d.КодДоговора
			and d.ДатаОкончания > cte.ДатаОкончания)
	)
	delete from  cte_to_del


	;with cte_kk as 
	(
		select nRow = ROW_NUMBER() over(partition by Договор order by ДатаОкончания), 
		cnt = Count(1)  over(partition by Договор),
		dd_diff = datediff(dd, ДатаСтарта, ДатаОкончания),
		* from #t_data
		where ВидОперации = 'Кредитные каникулы'
		
	)
	, cte_short_kk as 
	(
		select
		new_ДатаСтарта = case
			--если это не последняя строка и пред меньше 30 дней то берем дату начала этого периода
			when nRow <=cnt and lag(dd_diff, 1, dd_diff)over(partition by Договор order by nRow)<30 then  lag(ДатаСтарта, 1, null)over(partition by Договор order by nRow)
			--если это последняя строка и интевал меньше 30 дней, то берем дату начала пред периода
			when nRow =cnt and dd_diff<30  then lag(ДатаСтарта, 1, null)over(partition by Договор order by nRow)
		end 
		, *
		from cte_kk 
		where cnt>1
		--and КодДоговора = '18011616280001'
	) 
	update cte_short_kk
		set ДатаСтарта = new_ДатаСтарта
	where new_ДатаСтарта is not null
	
	--Удаляем одинаковые периоды.
	;with cte_to_del as (
		select 
			toDel = iif(ДатаСтарта = lag(ДатаСтарта, 1, null) over(partition by Договор order by ДатаОкончания desc), 1, 0)
			,* 
		from #t_data
		where  ВидОперации = 'Кредитные каникулы'
	)
	delete from cte_to_del
	where toDel = 1




	if exists (select top(1) 1 from #t_data)
	begin
		
		--drop table dbo.dm_restructurings
		if OBJECT_ID('dbo.dm_restructurings') is null
		begin
			select top(0) 
			Договор,
			number = КодДоговора,
			dateClientRequest = ДатаОбращениеКлиента,
			operation_type = case ВидОперации
					when 'Акция Реструктуризация' then 'Другое'
					when 'Реструктуризация' then case 
						when charindex('Кредитные каникулы', ВидРеструктуризации) >0 then  'Кредитные каникулы'
						when charindex('Заморозка', ВидРеструктуризации) >0 then ВидРеструктуризации
						else ВидОперации
						end
					else ВидОперации end,
			period_start = ДатаСтарта,
			period_end = ДатаОкончания,
			reason_credit_vacation = reason_credit_vacation,
			credit_holiday_period = СрокКредитныхКаникул,
			--date_deleted = ДатаУдаления,
			[new_date_end_contract] = НоваяДатаОкончанияДоговора,
			create_at = getdate(),
			isApproved = cast(iif(Проведен=0x01, 1, 0) as bit),
			dateCreatedRequest = ДатаСозданияОбращения,
			RequestNumber = НомерОбращенияКлиента
			into dbo.dm_restructurings
			from #t_data
		end
		begin tran
			delete from dbo.dm_restructurings where 1=1
	
		
			insert into dbo.dm_restructurings
			(
				[Договор]
				, [number]
				, dateClientRequest
				, [operation_type]
				, [period_start]
				, [period_end]
				, [reason_credit_vacation]
				, credit_holiday_period
				, [new_date_end_contract]
				, [create_at]
				, isApproved
				, dateCreatedRequest
				, requestNumber
			)
			select distinct 
				Договор
				,number = КодДоговора --номер договора
				/*
				operation_type = case ВидОперации
				when 'Акция Реструктуризация' then 'Другое'
				when 'Реструктуризация' then iif(charindex('Заморозка', ВидРеструктуризации) >0, ВидРеструктуризации, 'Другое')
				else ВидОперации end,
				*/
				,dateClientRequest = ДатаОбращениеКлиента
				,operation_type = case ВидОперации
					when 'Акция Реструктуризация' then 'Другое'
					when 'Реструктуризация' then case 
						when charindex('Кредитные каникулы', ВидРеструктуризации) >0 then  'Кредитные каникулы'
						when charindex('Заморозка', ВидРеструктуризации) >0 then ВидРеструктуризации
						else ВидОперации
						end
					else ВидОперации end, --тип: кредитные каникулы, заморозка, реструктуризация (изменение первоначальных условий договора, например, снижение ставки)
				period_start = ДатаСтарта, --дата начала
				period_end = 
				case 
					when ДатаОкончания is not null then ДатаОкончания
					when СрокКредитныхКаникул>0 and ДатаОкончания is null
						then dateadd(mm, СрокКредитныхКаникул, ДатаСтарта)
					end, --дата окончания (для типа "реструктуризация" - null)
					--
				reason_credit_vacation = 
				--Если число, то пишем null
				iif(ISNUMERIC(reason_credit_vacation) = 1, null, reason_credit_vacation), --причина предоставления кредитных каникул 
				--date_deleted = ДатаУдаления,
				credit_holiday_period = СрокКредитныхКаникул,
				[new_date_end_contract] = НоваяДатаОкончанияДоговора,
				create_at = getdate(),
				isApproved = cast(iif(Проведен=0x01, 1, 0) as bit)
				,dateCreatedRequest = ДатаСозданияОбращения
				,RequestNumber = НомерОбращенияКлиента
			from #t_data
			order by number
		commit tran
		
	end
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end

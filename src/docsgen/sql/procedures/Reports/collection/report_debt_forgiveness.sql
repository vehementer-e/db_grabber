CREATE procedure [collection].[report_debt_forgiveness]
as
begin

	declare @dt_from date;
	set @dt_from = '2020-07-01';


drop table if exists #Типпродукта ;
	
select 
	external_id = d.Код,
	--d.ссылка, 
	[Тип Продукта] = 
					CASE lower(cmr_ТипыПродуктов.ИдентификаторMDS)
						when 'pts'			then 'ПТС'
						when 'installment'	then 'Инстоллмент'
						when 'pdl'			then 'PDL'
						else 'ПТС' end 
into #Типпродукта
from 
STG.[_1Ccmr].Справочник_Договоры AS d
		
		left join [Stg].[_1cCMR].[Справочник_типыПродуктов] cmr_ТипыПродуктов
			on d.ТипПродукта = cmr_ТипыПродуктов.ссылка	
			;

drop table if exists #base_claimant_id;


drop table if exists #base_reservice
	-- сбор сумм переобслуживания
	
		select   --dc.ДатаСписанияБезнадежнойЗадолженности,

		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)), -1)) dt_st_month
				--dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date))) dt_st_month		
				,dc.[НомерДоговора] number_deal
				,'Переобслуживание' 'type_wtiteoff_old'
				,'Переобслуживание' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = coalesce((dc.[СуммаСписанияПроцениты] + dc.[СуммаСписанияПени]),0)
				,sum_remission = coalesce(0,0)
		into #base_reservice
		from		
				(		
					select 
							*		
							,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
					where 1 = 1		
							and [ПричинаЗакрытияНаименование] = 'Дисконтный калькулятор'
				)																									dc
		left join 
				(
					select --ДатаСписанияБезнадежнойЗадолженности,
							[ДатаОтчета]
							,[НомерДоговора]
							,[ПричинаЗакрытияНаименование]
							,[СуммаПрощенияОсновнойДолг]
							,[СуммаПрощенияПроценты]
							,[СуммаПрощенияПени]
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]
					where 1 = 1		
							and [ПричинаЗакрытияНаименование] in
												('Оферта 20% + новый график'
												,'Согласно Приказа №112 от 11.04.2019 "О проведении Акции "Прощение процентов"')
				)																									ofer on ofer.[НомерДоговора] = dc.[НомерДоговора]
																															and dateadd(dd,1,ofer.[ДатаОтчета])
																																= dc.[ДатаОтчета]
		where 1=1
				and dc.rn = 1
				and coalesce((dc.[СуммаСписанияПроцениты] + dc.[СуммаСписанияПени]),0) > 0
	
	drop table if exists #base_remission
	-- сбор сумм переобслуживания и прощения по дисконтному 
	
		select  --dc.ДатаСписанияБезнадежнойЗадолженности,
		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)), -1)) dt_st_month
				--dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date))) dt_st_month		
				,dc.[НомерДоговора] number_deal
				,'Прощение 233' 'type_wtiteoff_old'
				,'Прощение 233' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = coalesce(0,0)
				,sum_remission = case when ofer.[ПричинаЗакрытияНаименование] is not null -- списание %% в витрине указывается накопительно, поэтому в тех случаях, где мы ранее проводили списание %% по акциям отличным от дисконтного калькулятора, там прощенные %% учитывать не нужно
									  then coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]),0) - 
										   coalesce((ofer.[СуммаПрощенияОсновнойДолг] + ofer.[СуммаПрощенияПроценты] + ofer.[СуммаПрощенияПени]),0)
									  else coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]),0)
									  end
		into #base_remission 
		from		
				(		
					select 
							*		
							,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
					where 1 = 1		
							and [ПричинаЗакрытияНаименование] = 'Дисконтный калькулятор'
				)																									dc
		left join 
				(
					select --ДатаСписанияБезнадежнойЗадолженности,
							[ДатаОтчета]
							,[НомерДоговора]
							,[ПричинаЗакрытияНаименование]
							,[СуммаПрощенияОсновнойДолг]
							,[СуммаПрощенияПроценты]
							,[СуммаПрощенияПени]
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]
					where 1 = 1		
							and [ПричинаЗакрытияНаименование] in
												('Оферта 20% + новый график'
												,'Согласно Приказа №112 от 11.04.2019 "О проведении Акции "Прощение процентов"')
				)																									ofer on ofer.[НомерДоговора] = dc.[НомерДоговора]
																															and dateadd(dd,1,ofer.[ДатаОтчета])
																																= dc.[ДатаОтчета]
		where 1=1
				and dc.rn = 1
				and (case when ofer.[ПричинаЗакрытияНаименование] is not null
						then coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]),0) - 
							coalesce((ofer.[СуммаПрощенияОсновнойДолг] + ofer.[СуммаПрощенияПроценты] + ofer.[СуммаПрощенияПени]),0)
						else coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]),0)
						end) > 0
	
	drop table if exists #base_remission_200 
	-- сбор сумм прощения долга менее 200 руб
	
		select-- w200.ДатаСписанияБезнадежнойЗадолженности,
		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(w200.[ДатаОтчета] as date)), -1)) dt_st_month
		
		         --dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(w200.[ДатаОтчета] as date))) dt_st_month		
				,w200.[НомерДоговора] number_deal
				,'Списание сумм "Дарение"' 'type_wtiteoff_old'
				,'Списание сумм до 200 руб' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(w200.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = coalesce(0,0)
				,sum_remission = coalesce((w200.[СуммаПрощенияОсновнойДолг] + w200.[СуммаПрощенияПроценты] + w200.[СуммаПрощенияПени]),0)
		into #base_remission_200
		from		
		(		
			select *		
					,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
			from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
			where 1 = 1		
					and [ПричинаЗакрытияНаименование] = 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"'
		)w200		
		where w200.rn = 1
				and (w200.[СуммаПрощенияОсновнойДолг] + w200.[СуммаПрощенияПроценты] + w200.[СуммаПрощенияПени]) <= 200 -- удаление 1% некорректных записей (сумма списание > 200 руб)
	
	drop table if exists #base_remission_12
	-- сбор сумм прощения долга по приказу № 12
	
		select-- w233.ДатаСписанияБезнадежнойЗадолженности,
		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date)), -1)) dt_st_month
		      
			  --dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date))) dt_st_month		
				,w233.[НомерДоговора] number_deal
				,'Прощение 233' 'type_wtiteoff_old'
				,'Списание по приказу # 12' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = coalesce(0,0)
				,sum_remission = coalesce((w233.[СуммаПрощенияОсновнойДолг] + w233.[СуммаПрощенияПроценты] + w233.[СуммаПрощенияПени]),0)
		into #base_remission_12
		from		
		(		
			select *		
					,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
			from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
			where 1 = 1		
					and [ПричинаЗакрытияНаименование] = 'Согласно Приказа №12 от 28.01.2019 о реализации пилотного проекта "Клиентский калькулятор"'
		)w233		
		where w233.rn = 1
	
	drop table if exists #base_offer
	-- сбор сумм прощения по реструктуризации
	
		select --base.ДатаСписанияБезнадежнойЗадолженности,
		         dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(base.[ДатаОтчета] as date)), -1)) dt_st_month

				--dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(base.[ДатаОтчета] as date))) dt_st_month		
				,base.[НомерДоговора] number_deal
				,'Оферта 20% + новый график' 'type_wtiteoff_old'
				,'Оферта 20% + новый график' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(base.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = 0
				,sum_remission = coalesce((base.[СуммаПрощенияОсновнойДолг] + base.[СуммаПрощенияПроценты] + base.[СуммаПрощенияПени]),0)
		into #base_offer
		from
				(
					select 
							*		
							,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
					where 1 = 1
							and [ПричинаЗакрытияНаименование] = 'Оферта 20% + новый график'
				)base
		where 1=1
				and base.rn = 1
	
	
	drop table if exists #dpd_history 
	-- сбор срока просрочки
	
		select 	t04.*
		into #dpd_history
		from
		(select cast(dateadd(yy,-2000,t01.Период) as date) [Период]
				,t01.КоличествоПолныхДнейПросрочкиУМФО
				,ROW_NUMBER() over (partition by cast(t01.[Период] as date),t01.[Договор] order by t01.[Период] desc) aa -- убираю дубли записей из-за появления платежей
				,t02.[Код] external_id
		from stg._1cCMR.РегистрСведений_АналитическиеПоказателиМФО t01
		left join stg._1cCMR.Справочник_Договоры t02 on t01.[Договор]  = t02.[Ссылка]
		where cast(dateadd(yy,-2000,t01.Период) as date) >= dateadd(MM,-1,@dt_from))t04
		where t04.aa = 1
	
	
	drop table if exists #CollectingStage_history 
	-- сбор стадий просрочки по спейсу
	
		 select t03.Number
				,t02.ChangeDate Date_CollectingStage
				,t04.Name Name_CollectingStage
	 		 into #CollectingStage_history 
			 from
			(select t01.[ObjectId]
					,ROW_NUMBER() over (partition by t01.[ObjectId] order by t01.[ChangeDate] desc) aa
					,cast(t01.[ChangeDate] as date) ChangeDate
					,t01.[OldValue]
		  from stg._collection.[DealHistory] t01
		  where t01.[Field] = 'Стадия коллектинга договора'
				and cast(t01.[ChangeDate] as date) >= dateadd(MM,-1,@dt_from))t02
		  join [Stg].[_Collection].[Deals] t03 on t03.id = t02.[ObjectId]
		  join [Stg].[_Collection].[CollectingStage] t04 on t04.[Id] = t02.[OldValue]
		  where aa = 1
	
	drop table if exists #reportStage_history
	-- сбор стадий просрочки по терминалогии рисков
	
		select distinct t2.r_month
						,t1.external_id
						,t1.stage
						,t1.agent_name
		into #reportStage_history
		from risk.dm_ReportCollectionPlanIspHard t1

		join (select  dateadd(day,- datepart(day, t01.rep_dt) + 1, convert(date, t01.rep_dt)) r_month
						,t01.external_id
						,max(t01.rep_dt) rep_dt
						,max(t01.r_day) r_day
			 from risk.dm_ReportCollectionPlanIspHard t01
			 where dateadd(day,- datepart(day, t01.rep_dt) + 1, convert(date, t01.rep_dt)) >= @dt_from
			 group by dateadd(day,- datepart(day, t01.rep_dt) + 1, convert(date, t01.rep_dt))
						,t01.external_id)t2 on t2.external_id = t1.external_id
											and t2.rep_dt = t1.rep_dt
											and t2.r_day = t1.r_day
	
	drop table if exists #deals_kk
	-- база договоров когда-либо бывших на КК
	
		select number
				,1 flag_kk
		into #deals_kk
		from DWH2.dbo.dm_restructurings--devdb.dbo.say_log_peredachi_kk
		group by number	
	




	select brr.number_deal 'номер договора'
			,concat(c.[LastName],' ',c.[Name],' ',c.[MiddleName]) as 'фио клиента'
			,brr.dt_wtiteoff 'дата операции списания'
			,brr.dt_st_month 'месяц операции списания'
			,cast(coalesce(dh.КоличествоПолныхДнейПросрочкиУМФО,0) as int) 'срок просрочки на дату списания'
			,dwh2.[collection].bucket_dpd(cast(coalesce(dh.КоличествоПолныхДнейПросрочкиУМФО,0) as int)) 'бакет просрочки на дату списания'
			,csh.Name_CollectingStage 'стадия коллектинга на дату списания'
			--,rsh.stage
			,case when rsh.stage = 'Hard' then 'Хард'
				  when rsh.stage = 'Агент' then 'КА'
				  when rsh.stage = 'ИП' then 'ИП'
				  else '0-90' end 'подразделение коллектинга на дату списания'
			,coalesce(rsh.agent_name,'CarMoney') 'наименование агента на дату списания'
			,coalesce(kk.flag_kk,0) 'флаг отношения к КК'
			,brr.type_wtiteoff_old 'тип операции списания'
			,cast(brr.sum_reservice+brr.sum_remission as int) 'сумма списания'
			,'финансовый результат от списания' = cast((brr.sum_reservice * -1) + coalesce(pz.ОстатокРезерв,0) + (brr.sum_remission * -1) + (brr.sum_remission * -1 * 0.2) as int)
			,pr.[Тип Продукта]
			,c.[Id]
			--,cast(brr.ДатаСписанияБезнадежнойЗадолженности as date ) [ДатаСписанияБезнадежнойЗадолженности]
			--cast(dateadd(yy,-2000,t01.Период) as date)
	into #base_claimant_id
	from 
	(
	select *
	from #base_reservice
	union all
	select *
	from #base_remission
	union all
	select *
	from #base_remission_200
	union all
	select *
	from #base_remission_12
	union all
	select *
	from #base_offer
	)																					brr
	left join [Stg].[_Collection].[Deals]												d on d.[Number] = brr.number_deal
	left join [Stg].[_Collection].[customers]											c on c.[Id] = d.[IdCustomer]
	left join #dpd_history																dh on dh.external_id = brr.number_deal
																							and dh.[Период] = dateadd(dd,-1,dt_wtiteoff)
	left join #CollectingStage_history													csh on csh.[Number] = brr.number_deal
	left join #reportStage_history														rsh on rsh.external_id = brr.number_deal
																							and rsh.r_month = brr.dt_st_month
	left join #deals_kk																	kk on kk.number = brr.number_deal
	left join [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		pz on pz.НомерДоговора = brr.number_deal
																							and pz.ОтчетнаяДата = convert(date, dateadd(dd,-1,brr.dt_wtiteoff))

   left join #Типпродукта pr on pr.external_id=d.[Number]
	where 1 = 1
			and brr.dt_st_month >= '2020-01-01'
			and (brr.sum_reservice + brr.sum_remission) > 0


;





drop table if exists #base_claimant_id_fin;
	select ObjectId
			,coalesce(NewValue,0) ClaimantId
			,case when NewValue is null then OldValue else NewValue end ClaimantId_new
			,dt_rt dt_st
			,lead(dateadd(dd,-1,dt_rt),1,cast(getdate() as date)) over (partition by ObjectId order by ChangeDate) dt_end
	into #base_claimant_id_fin
	from (SELECT [ChangeDate]
					,cast([ChangeDate] as date) dt_rt
					,[OldValue]
					,[NewValue]
					,[ObjectId]
					,ROW_NUMBER() over (partition by [ObjectId], cast([ChangeDate] as date) order by [ChangeDate] desc) rn
			FROM [Stg].[_Collection].[CustomerHistory]
			where 1 = 1
					and field = 'Ответственный взыскатель')aaa
	where 1 = 1
			and rn = 1
	;
	

	drop table if exists #employee;
	select Id,concat(LastName,' ',FirstName,' ',MiddleName) FIO,Position
	into #employee
	from stg._Collection.Employee
	--where id =11
	drop table if exists #range_claimant_employee;
	select bc.*,em.*--,d.number,d.id
	into	#range_claimant_employee
	from #base_claimant_id_fin bc left join #employee em on bc.ClaimantId_new=em.id


	select 
	external_id	= b.[номер договора]
	,fio_customer = b.[фио клиента]
	,date_wtiteoff	=	b.[дата операции списания]
	,report_month	= b.[месяц операции списания]
	,dpd		= b.[срок просрочки на дату списания]
	,bucket	= b.[бакет просрочки на дату списания]
	,CollectingStage_from_space	= b.[стадия коллектинга на дату списания]
	,stage		=	b.[подразделение коллектинга на дату списания]
	,agent_name	= b.[наименование агента на дату списания]
	,flag_kk	= b.[флаг отношения к КК]
	,[имя акции]	 = b.[тип операции списания]
	,summ_wtiteoff 	 = b.[сумма списания]
	,sum_finrez 		= b.[финансовый результат от списания]
	,[Тип Продукта]	= b.[Тип Продукта]
	,[Ответственный  сотрудгик] = r.FIO
from #base_claimant_id b
left join #range_claimant_employee r on b.id=r.ObjectId and b.[дата операции списания] between dt_st and 	dt_end
end

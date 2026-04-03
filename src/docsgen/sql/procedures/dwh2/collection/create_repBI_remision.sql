  
 
CREATE PROC [collection].[create_repBI_remision] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try


 
	
	
	
	declare @dt_from date;
	set @dt_from = '2020-07-01';



	
	begin transaction



    delete from [collection].[repBI_remision];









	with 
	base_reservice as
	-- сбор сумм переобслуживания
	(
		select   --dc.ДатаСписанияБезнадежнойЗадолженности,

		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)), -1)) dt_st_month
				--[collection].dt_st_month(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date))) dt_st_month		
				,dc.[НомерДоговора] number_deal
				,'Переобслуживание' 'type_wtiteoff_old'
				,'Переобслуживание' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = coalesce((dc.[СуммаСписанияПроцениты] + dc.[СуммаСписанияПени]),0)
				,sum_remission = coalesce(0,0)
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
	)
	,
	base_remission as
	-- сбор сумм переобслуживания и прощения по дисконтному 
	(
		select  --dc.ДатаСписанияБезнадежнойЗадолженности,
		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)), -1)) dt_st_month
				--[collection].dt_st_month(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date))) dt_st_month		
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
	)
	,
	base_remission_200 as
	-- сбор сумм прощения долга менее 200 руб
	(
		select-- w200.ДатаСписанияБезнадежнойЗадолженности,
		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(w200.[ДатаОтчета] as date)), -1)) dt_st_month
		
		         --[collection].dt_st_month(dateadd(yy,-2000,cast(w200.[ДатаОтчета] as date))) dt_st_month		
				,w200.[НомерДоговора] number_deal
				,'Списание сумм "Дарение"' 'type_wtiteoff_old'
				,'Списание сумм до 200 руб' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(w200.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = coalesce(0,0)
				,sum_remission = coalesce((w200.[СуммаПрощенияОсновнойДолг] + w200.[СуммаПрощенияПроценты] + w200.[СуммаПрощенияПени]),0)
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
	)
	,
	base_remission_12 as
	-- сбор сумм прощения долга по приказу № 12
	(
		select-- w233.ДатаСписанияБезнадежнойЗадолженности,
		dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date)), -1)) dt_st_month
		      
			  --[collection].dt_st_month(dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date))) dt_st_month		
				,w233.[НомерДоговора] number_deal
				,'Прощение 233' 'type_wtiteoff_old'
				,'Списание по приказу # 12' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = coalesce(0,0)
				,sum_remission = coalesce((w233.[СуммаПрощенияОсновнойДолг] + w233.[СуммаПрощенияПроценты] + w233.[СуммаПрощенияПени]),0)
		from		
		(		
			select *		
					,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
			from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
			where 1 = 1		
					and [ПричинаЗакрытияНаименование] = 'Согласно Приказа №12 от 28.01.2019 о реализации пилотного проекта "Клиентский калькулятор"'
		)w233		
		where w233.rn = 1
	)
	,
	base_offer as 
	-- сбор сумм прощения по реструктуризации
	(
		select --base.ДатаСписанияБезнадежнойЗадолженности,
		         dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(base.[ДатаОтчета] as date)), -1)) dt_st_month

				--[collection].dt_st_month(dateadd(yy,-2000,cast(base.[ДатаОтчета] as date))) dt_st_month		
				,base.[НомерДоговора] number_deal
				,'Оферта 20% + новый график' 'type_wtiteoff_old'
				,'Оферта 20% + новый график' 'type_wtiteoff_new'
				,dateadd(yy,-2000,cast(base.[ДатаОтчета] as date)) 'dt_wtiteoff'
				,sum_reservice = 0
				,sum_remission = coalesce((base.[СуммаПрощенияОсновнойДолг] + base.[СуммаПрощенияПроценты] + base.[СуммаПрощенияПени]),0)
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
	)
	,
	dpd_history as 
	-- сбор срока просрочки
	(
		/*
		--var 1
		select 	t04.*
		from
		(select cast(dateadd(yy,-2000,t01.Период) as date) [Период]
				,t01.КоличествоПолныхДнейПросрочкиУМФО
				,ROW_NUMBER() over (partition by cast(t01.[Период] as date),t01.[Договор] order by t01.[Период] desc) aa -- убираю дубли записей из-за появления платежей
				,t02.[Код] external_id
		from stg._1cCMR.РегистрСведений_АналитическиеПоказателиМФО t01
		left join stg._1cCMR.Справочник_Договоры t02 on t01.[Договор]  = t02.[Ссылка]
		where cast(dateadd(yy,-2000,t01.Период) as date) >= dateadd(MM,-1,@dt_from))t04
		where t04.aa = 1
		*/

		--var 2 --DWH-2516
		SELECT 
			B.d AS [Период]
			,B.dpd AS КоличествоПолныхДнейПросрочкиУМФО
			,B.external_id
		FROM dbo.dm_CMRStatBalance AS B (NOLOCK)
		WHERE B.d >= dateadd(MM, -1, @dt_from)

	)
	,
	CollectingStage_history as
	-- сбор стадий просрочки по спейсу
	(
		 select t03.Number
				,t02.ChangeDate Date_CollectingStage
				,t04.Name Name_CollectingStage
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
	)
	,
	reportStage_history as
	-- сбор стадий просрочки по терминалогии рисков
	(
		select distinct t2.r_month
						,t1.external_id
						,t1.stage
						,t1.agent_name
		from reports.risk.dm_ReportCollectionPlanIspHard t1

		join (select  dateadd(day,- datepart(day, t01.rep_dt) + 1, convert(date, t01.rep_dt)) r_month
						,t01.external_id
						,max(t01.rep_dt) rep_dt
						,max(t01.r_day) r_day
			 from reports.risk.dm_ReportCollectionPlanIspHard t01
			 where dateadd(day,- datepart(day, t01.rep_dt) + 1, convert(date, t01.rep_dt)) >= @dt_from
			 group by dateadd(day,- datepart(day, t01.rep_dt) + 1, convert(date, t01.rep_dt))
						,t01.external_id)t2 on t2.external_id = t1.external_id
											and t2.rep_dt = t1.rep_dt
											and t2.r_day = t1.r_day
	)
	,
	deals_kk as
	-- база договоров когда-либо бывших на КК
	(
		select number
				,1 flag_kk
		from dbo.dm_restructurings--devdb.dbo.say_log_peredachi_kk
		group by number	
	)
	,
	/*percentbefore as  (



	select [НомерДоговора],--cast(СтавкаПоДоговору as int),
	cast(СтавкаПоДоговору as float)[Percentbefore]

	from
	(
					select [НомерДоговора],СтавкаПоДоговору, --case
					--when ПричинаЗакрытияНаименование is null then СтавкаПоДоговору
					ROW_NUMBER() over (partition by НомерДоговора  order by ДатаОтчета )	rn
					--,ROW_NUMBER() over (partition by НомерДоговора  order by ДатаОтчета desc ) rnd
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]	

							--where [НомерДоговора]='23042600889217' --and ДатаОтчета>'4024-02-01'   and ПричинаЗакрытияНаименование =''
							)t
							where rn=1 
							),*/
percentnow as  (



	select [НомерДоговора],--cast(СтавкаПоДоговору as int),
	cast(СтавкаПоДоговору as float)[Percentnow]
	,max_p
	,min_p

	from
	(
					select [НомерДоговора],СтавкаПоДоговору, --case
					--when ПричинаЗакрытияНаименование is null then СтавкаПоДоговору
					--ROW_NUMBER() over (partition by НомерДоговора  order by ДатаОтчета )	rn
					ROW_NUMBER() over (partition by НомерДоговора  order by ДатаОтчета desc ) rnd
					,max(СтавкаПоДоговору) over (partition by НомерДоговора) max_p
					,min(СтавкаПоДоговору) over (partition by НомерДоговора) min_p
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]	

							--where [НомерДоговора]='18030720070002' --and ДатаОтчета>'4024-02-01'   and ПричинаЗакрытияНаименование =''
							)t
							where  rnd = 1
							)

 


 	insert [collection].[repBI_remision] (


[номер договора]
      ,[фио клиента]
      ,[дата операции списания]
      ,[месяц операции списания]
      ,[срок просрочки на дату списания]
      ,[бакет просрочки на дату списания]
      ,[стадия коллектинга на дату списания]
      ,[подразделение коллектинга на дату списания]
      ,[наименование агента на дату списания]
      ,[флаг отношения к КК]
      ,[тип операции списания]
      ,[сумма списания]
      ,[финансовый результат от списания]
      ,[СтавкаПоДоговору]
      ,[max_p]
      ,[min_p]



	)




	select brr.number_deal 'номер договора'
			--,c.[LastName]+' '+c.[Name]+' '+c.[MiddleName] as 'фио клиента'
			,concat(c.[LastName],' ', c.[Name],' ', c.[MiddleName])  'фио клиента'
			,brr.dt_wtiteoff 'дата операции списания'
			,brr.dt_st_month 'месяц операции списания'
			,cast(coalesce(dh.КоличествоПолныхДнейПросрочкиУМФО,0) as int) 'срок просрочки на дату списания'
			,[collection].bucket_dpd(cast(coalesce(dh.КоличествоПолныхДнейПросрочкиУМФО,0) as int)) 'бакет просрочки на дату списания'
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
			,cast(pz.СтавкаПоДоговору as float) СтавкаПоДоговору
			,cast(max_p as float) max_p
	        ,cast(min_p as float) min_p


			
			--,cast(brr.ДатаСписанияБезнадежнойЗадолженности as date ) [ДатаСписанияБезнадежнойЗадолженности]
			--cast(dateadd(yy,-2000,t01.Период) as date)
	--into #aaa
	from 
	(
	select *
	from base_reservice
	union all
	select *
	from base_remission
	union all
	select *
	from base_remission_200
	union all
	select *
	from base_remission_12
	union all
	select *
	from base_offer
	)																					brr
	left join [Stg].[_Collection].[Deals]												d on d.[Number] = brr.number_deal
	left join [Stg].[_Collection].[customers]											c on c.[Id] = d.[IdCustomer]
	left join dpd_history																dh on dh.external_id = brr.number_deal
																							and dh.[Период] = dateadd(dd,-1,dt_wtiteoff)
	left join CollectingStage_history													csh on csh.[Number] = brr.number_deal
	left join reportStage_history														rsh on rsh.external_id = brr.number_deal
																							and rsh.r_month = brr.dt_st_month
	left join deals_kk																	kk on kk.number = brr.number_deal
	left join [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		pz on pz.НомерДоговора = brr.number_deal
																							and pz.ОтчетнаяДата = convert(date, dateadd(dd,-1,brr.dt_wtiteoff))

 -- left join percentbefore b on b.[НомерДоговора]=brr.[number_deal]
  left join percentnow n on n.[НомерДоговора]=brr.[number_deal]
	where 1 = 1
			and brr.dt_st_month >= '2020-01-01'
			and (brr.sum_reservice + brr.sum_remission) > 0


;




commit transaction 

  EXEC [collection].set_debug_info @sp_name
			,'Finish';		
			
	end try
begin catch
	SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
/* отправка на почту уведомления есть требуется доп уведомление об ошибке.*/
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch
END

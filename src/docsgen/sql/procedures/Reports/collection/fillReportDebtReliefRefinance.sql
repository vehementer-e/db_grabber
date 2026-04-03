
-- exec [collection].[fillReportDebtReliefRefinance]
CREATE     PROCEDURE [collection].[fillReportDebtReliefRefinance]
	@dt_from DATE = '2020-07-01'
AS
BEGIN
begin try

		drop table if exists #Типпродукта ;
			
		
		
			create table #t_base
			(
				dt_st_month			date
				,number_deal		nvarchar(255)
				,type_wtiteoff_old	nvarchar(255)
				,type_wtiteoff_new 	nvarchar(255)
				,dt_wtiteoff		date
				,sum_reservice		money
				,sum_remission		money
				,[сумма списания] AS isnull(sum_reservice,0) + isnull(sum_remission,0)  PERSISTED
				
			)
			
			create clustered index cix on #t_base(number_deal, dt_wtiteoff)
			create index ix on #t_base(dt_st_month,  [сумма списания])
			insert into #t_base(
			dt_st_month			
			,number_deal		
			,type_wtiteoff_old	
			,type_wtiteoff_new 	
			,dt_wtiteoff		
			,sum_reservice		
			,sum_remission		
			)

			select   --dc.ДатаСписанияБезнадежнойЗадолженности,
			dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)), -1)) dt_st_month
					--dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date))) dt_st_month		
					,dc.[НомерДоговора] number_deal
					,'Переобслуживание' 'type_wtiteoff_old'
					,'Переобслуживание' 'type_wtiteoff_new'
					,dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)) 'dt_wtiteoff'
					,sum_reservice = coalesce((dc.[СуммаСписанияПроцениты] + dc.[СуммаСписанияПени]),0)
					,sum_remission = coalesce(0,0)
			from		
					(		
						select 
								[ДатаОтчета],
								[НомерДоговора],
								[СуммаСписанияПроцениты],
								[СуммаСписанияПени]
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
			-- сбор сумм переобслуживания и прощения по дисконтному 
			
			 insert into #t_base(
				dt_st_month			
				,number_deal		
				,type_wtiteoff_old	
				,type_wtiteoff_new 	
				,dt_wtiteoff		
				,sum_reservice		
				,sum_remission		
				)

				select  --dc.ДатаСписанияБезнадежнойЗадолженности,
				dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)), -1)) dt_st_month
						--dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date))) dt_st_month		
						,dc.[НомерДоговора] number_deal
						,'Прощение 233' 'type_wtiteoff_old'
						,'Прощение 233' 'type_wtiteoff_new'
						,dateadd(yy,-2000,cast(dc.[ДатаОтчета] as date)) 'dt_wtiteoff'
						,sum_reservice = coalesce(0,0)
						,sum_remission = case when ofer.[ПричинаЗакрытияНаименование] is not null -- списание %% в витрине указывается накопительно, поэтому в тех случаях, где мы ранее проводили списание %% по акциям отличным от дисконтного калькулятора, там прощенные %% учитывать не нужно
											  then coalesce((dc.[СуммаПрощенияОсновнойДолг] 
													+ dc.[СуммаПрощенияПроценты] 
													+ dc.[СуммаПрощенияПени]),0) - 
												   coalesce((ofer.[СуммаПрощенияОсновнойДолг] 
														+ ofer.[СуммаПрощенияПроценты] 
														+ ofer.[СуммаПрощенияПени]),0)
											  else coalesce((dc.[СуммаПрощенияОсновнойДолг] 
												+ dc.[СуммаПрощенияПроценты] 
												+ dc.[СуммаПрощенияПени]),0)
											  end
				from		
						(		
							select 
									[ДатаОтчета]
									,[НомерДоговора]
									,[ПричинаЗакрытияНаименование]
									,[СуммаПрощенияОсновнойДолг]
									,[СуммаПрощенияПроценты]
									,[СуммаПрощенияПени]
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
		

			 insert into #t_base(
					dt_st_month			
					,number_deal		
					,type_wtiteoff_old	
					,type_wtiteoff_new 	
					,dt_wtiteoff		
					,sum_reservice		
					,sum_remission		
					)
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
			from		
				(		
					select [НомерДоговора], [ДатаОтчета], [СуммаПрощенияОсновнойДолг], 	[СуммаПрощенияПроценты]	, [СуммаПрощенияПени]
							,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
					from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
					where 1 = 1		
							and [ПричинаЗакрытияНаименование] = 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"'
				)w200		
				where w200.rn = 1
						and (w200.[СуммаПрощенияОсновнойДолг] + w200.[СуммаПрощенияПроценты] + w200.[СуммаПрощенияПени]) <= 200 -- удаление 1% некорректных записей (сумма списание > 200 руб)
				-- сбор сумм прощения долга по приказу № 12
			 insert into #t_base(
		
					dt_st_month			
					,number_deal		
					,type_wtiteoff_old	
					,type_wtiteoff_new 	
					,dt_wtiteoff		
					,sum_reservice		
					,sum_remission	
					
					)
				select-- w233.ДатаСписанияБезнадежнойЗадолженности,
				dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date)), -1)) dt_st_month
					  
					  --dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date))) dt_st_month		
						,w233.[НомерДоговора] number_deal
						,'Прощение 233' 'type_wtiteoff_old'
						,'Списание по приказу # 12' 'type_wtiteoff_new'
						,dateadd(yy,-2000,cast(w233.[ДатаОтчета] as date)) 'dt_wtiteoff'
						,sum_reservice = coalesce(0,0)
						,sum_remission = coalesce((w233.[СуммаПрощенияОсновнойДолг] + w233.[СуммаПрощенияПроценты] + w233.[СуммаПрощенияПени]),0)
			
				from		
				(		
					select [НомерДоговора]
						, [ДатаОтчета]
						,[СуммаПрощенияОсновнойДолг]
						,[СуммаПрощенияПроценты]
						,[СуммаПрощенияПени]
							,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
					from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
					where 1 = 1		
							and [ПричинаЗакрытияНаименование] = 'Согласно Приказа №12 от 28.01.2019 о реализации пилотного проекта "Клиентский калькулятор"'
				)w233		
				where w233.rn = 1
			
			-- сбор сумм прощения по реструктуризации
			 insert into #t_base(
				dt_st_month			
				,number_deal		
				,type_wtiteoff_old	
				,type_wtiteoff_new 	
				,dt_wtiteoff		
				,sum_reservice		
				,sum_remission		
				)
				select --base.ДатаСписанияБезнадежнойЗадолженности,
						 dateadd(dd,1, EOMONTH(dateadd(yy,-2000,cast(base.[ДатаОтчета] as date)), -1)) dt_st_month

						--dwh2.[collection].dt_st_month(dateadd(yy,-2000,cast(base.[ДатаОтчета] as date))) dt_st_month		
						,base.[НомерДоговора] number_deal
						,'Оферта 20% + новый график' 'type_wtiteoff_old'
						,'Оферта 20% + новый график' 'type_wtiteoff_new'
						,dateadd(yy,-2000,cast(base.[ДатаОтчета] as date)) 'dt_wtiteoff'
						,sum_reservice = 0
						,sum_remission = coalesce((base.[СуммаПрощенияОсновнойДолг] + base.[СуммаПрощенияПроценты] + base.[СуммаПрощенияПени]),0)
				from
						(
							select [НомерДоговора], [ДатаОтчета], [СуммаПрощенияОсновнойДолг], 	 [СуммаПрощенияПроценты], 	[СуммаПрощенияПени]
										
									,ROW_NUMBER() over (partition by [НомерДоговора] order by [ДатаОтчета]) rn
							from 
									[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		
							where 1 = 1
									and [ПричинаЗакрытияНаименование] = 'Оферта 20% + новый график'
						)base
				where 1=1
						and base.rn = 1
			 drop table if exists #t_dpd_history 
			 /*
			-- сбор срока просрочки
			select 	 [Период] = b.d
					,b.external_id
					,b.dpd
			into  #t_dpd_history
			from  dwh2.dbo.dm_CMRStatBalance b
			where 	d>=	dateadd(MM,-1,@dt_from)
			create clustered index cix on #t_dpd_history( external_id, [Период])
					 */

			
			drop table if exists #t_CollectingStage_history 
			-- сбор стадий просрочки по спейсу
			
			select t03.Number
				,t02.ChangeDate Date_CollectingStage
				,t04.Name Name_CollectingStage
			into #t_CollectingStage_history
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
			
			drop table if exists #t_reportStage_history 
			-- сбор стадий просрочки по терминалогии рисков
			
			 select distinct t2.r_month
								,t1.external_id
								,t1.stage
								,t1.agent_name
				into #t_reportStage_history
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
			 create clustered index cix on #t_reportStage_history(external_id, 	r_month)
			 drop table if exists #t_deals_kk 
			-- база договоров когда-либо бывших на КК
			
			select   number as external_id
						,1 flag_kk
				into #t_deals_kk
				from DWH2.dbo.dm_restructurings --devdb.dbo.say_log_peredachi_kk
				group by number	
			create clustered index cix on  #t_deals_kk (external_id)

			select ДоговорЗайма.КодДоговораЗайма 'номер договора'
					,concat_ws(' '
						,ДоговорЗайма.Фамилия
						,ДоговорЗайма.Имя
						,ДоговорЗайма.Отчество) as 'фио клиента'
					,bbr.dt_wtiteoff 'дата операции списания'
					,bbr.dt_st_month 'месяц операции списания'
					,cast(coalesce(dh.dpd,0) as int) 'срок просрочки на дату списания'
					,dwh2.[collection].bucket_dpd(dh.dpd) 'бакет просрочки на дату списания'
					,csh.Name_CollectingStage 'стадия коллектинга на дату списания'
					--,rsh.stage
					,case when lcesh.External_Stage = 'Hard' then 'Хард'
						  when lcesh.External_Stage = 'Агент' then 'КА'
						  when lcesh.External_Stage = 'ИП' then 'ИП'
						  else '0-90' end 'подразделение коллектинга на дату списания'
					,coalesce(rsh.agent_name,'CarMoney') 'наименование агента на дату списания'
					,coalesce(kk.flag_kk,0) 'флаг отношения к КК'
					,bbr.type_wtiteoff_old 'тип операции списания'
					,[сумма списания] 'сумма списания'
					,'финансовый результат от списания' = cast((bbr.sum_reservice * -1) 
						+ coalesce(pz.ОстатокРезерв,0) 
						+ (bbr.sum_remission * -1) 
						+ (bbr.sum_remission * -1 * 0.2) as int)
					,[Тип Продукта] = ДоговорЗайма.ТипПродукта_Наименование
					,IdCustomer = d.[IdCustomer]
					--,cast(brr.ДатаСписанияБезнадежнойЗадолженности as date ) [ДатаСписанияБезнадежнойЗадолженности]
					--cast(dateadd(yy,-2000,t01.Период) as date)
					,ТипПродукта_Code = ДоговорЗайма.ТипПродукта_Code
			into #base_claimant_id
			from 	dwh2.hub.ДоговорЗайма 	  ДоговорЗайма
			inner join #t_base																	bbr	on 	 bbr.number_deal = 	ДоговорЗайма.КодДоговораЗайма
			left join [Stg].[_Collection].[Deals]												d on d.[Number] = ДоговорЗайма.КодДоговораЗайма
			left join dwh2.dbo.dm_CMRStatBalance 												dh on dh.external_id = ДоговорЗайма.КодДоговораЗайма
																									and dh.d = dateadd(dd,-1,dt_wtiteoff)
			left join #t_CollectingStage_history												csh on csh.[Number] = ДоговорЗайма.КодДоговораЗайма
			left join #t_reportStage_history													rsh on rsh.external_id = ДоговорЗайма.КодДоговораЗайма
																									and rsh.r_month = bbr.dt_st_month
			left join #t_deals_kk																kk on kk.external_id = ДоговорЗайма.КодДоговораЗайма
			left join [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]		pz on pz.НомерДоговора =ДоговорЗайма.КодДоговораЗайма
																									and pz.ОтчетнаяДата = dateadd(dd,-1,bbr.dt_wtiteoff)
			left join stg._loginom.Collection_External_Stage_history							lcesh on lcesh.external_id = ДоговорЗайма.КодДоговораЗайма
																									and lcesh.call_dt = bbr.dt_wtiteoff
		 --  left join #Типпродукта pr on pr.external_id=d.[Number]
			where 1 = 1
					and bbr.dt_st_month >= @dt_from
					and [сумма списания] > 0


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
			select Id,concat_ws(' '
				,LastName
				,FirstName
				,MiddleName) FIO,Position
			into #employee
			from stg._Collection.Employee
			--where id =11
			drop table if exists #range_claimant_employee;
			select bc.*,em.FIO, em.Position--,d.number,d.id
			into	#range_claimant_employee
			from #base_claimant_id_fin bc left join #employee em on bc.ClaimantId_new=em.id


			select b.*,r.FIO
			into #result_reportDebtReliefRefinance
		from #base_claimant_id b
		left join #range_claimant_employee r on b.IdCustomer=r.ObjectId 
			and b.[дата операции списания] between dt_st and 	dt_end

		--drop table collection.reportDebtReliefRefinance;
		if OBJECT_ID('collection.reportDebtReliefRefinance') is null
		begin
			select top(0)
				*
			into collection.reportDebtReliefRefinance
			from #result_reportDebtReliefRefinance
			CREATE NONCLUSTERED INDEX IX_reportDebtReliefRefinance_nomer_dogovora 
			ON collection.reportDebtReliefRefinance ([номер договора]);
		end

		begin tran
			delete t from collection.reportDebtReliefRefinance t
			--where [request_creation_date]>=@lastDay
			
			insert into collection.reportDebtReliefRefinance(
				 [номер договора]
					, [фио клиента]
					, [дата операции списания]
					, [месяц операции списания]
					, [срок просрочки на дату списания]
					, [бакет просрочки на дату списания]
					, [стадия коллектинга на дату списания]
					, [подразделение коллектинга на дату списания]
					, [наименование агента на дату списания]
					, [флаг отношения к КК]
					, [тип операции списания]
					, [сумма списания]
					, [финансовый результат от списания]
					, [Тип Продукта]
					, 	IdCustomer
					, [FIO]
					,ТипПродукта_Code
					)
			--	([Id], [request_number], [request_creation_date], [request_status], [request_client_name], [task_status], [task_stage_time], [next_task_stage_time], [next_task_status], [task_status_owner], [check_list_item_id], [check_list_item_name], [check_list_item_status])
			select 
 				 [номер договора]
					, [фио клиента]
					, [дата операции списания]
					, [месяц операции списания]
					, [срок просрочки на дату списания]
					, [бакет просрочки на дату списания]
					, [стадия коллектинга на дату списания]
					, [подразделение коллектинга на дату списания]
					, [наименование агента на дату списания]
					, [флаг отношения к КК]
					, [тип операции списания]
					, [сумма списания]
					, [финансовый результат от списания]
					, [Тип Продукта]
					, IdCustomer
					, [FIO]
					,ТипПродукта_Code 
			from #result_reportDebtReliefRefinance			
		commit tran


end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch

END;

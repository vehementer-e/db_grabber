
/*Отчет_по_прощению_переобслуживанию_долга Пищаев С.*/
--exec [risk].[etl_repbi_coll_debt_reservice_forgiveness_weekly_report];
CREATE PROCEDURE  [collection].[etl_repbi_coll_debt_reservice_forgiveness_weekly_report]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC [collection].set_debug_info @sp_name
			,'1';

		DECLARE @dt_from DATE;

		SET @dt_from = '2020-07-01';

		DROP TABLE

		IF EXISTS #disc_calc_base;
			SELECT *
			INTO #disc_calc_base
			FROM [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]
			WHERE 1 = 1
				AND [ПричинаЗакрытияНаименование] IN ('Дисконтный калькулятор', 'Оферта 20% + новый график', 'Согласно Приказа №112 от 11.04.2019 "О проведении Акции "Прощение процентов"', 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"', 'Согласно Приказа №12 от 28.01.2019 о реализации пилотного проекта "Клиентский калькулятор"');

		EXEC [collection].set_debug_info @sp_name
			,'2';

		DROP TABLE

		IF EXISTS #disc_calc_base_stg_rn;
			SELECT a.*
				,ROW_NUMBER() OVER (
					PARTITION BY a.[НомерДоговора] ORDER BY [ДатаОтчета]
					) rn
			INTO #disc_calc_base_stg_rn
			FROM #disc_calc_base a;

		EXEC [collection].set_debug_info @sp_name
			,'3';

		DROP TABLE

		IF EXISTS #disc_calc_base_rn;
			SELECT *
			INTO #disc_calc_base_rn
			FROM #disc_calc_base_stg_rn
			WHERE rn = 1;

		EXEC [collection].set_debug_info @sp_name
			,'4';

		DROP TABLE

		IF EXISTS #base;
			WITH base_reservice
			AS
				-- сбор сумм переобслуживания
				(
				SELECT DATEADD(month, DATEDIFF(month, 0, dateadd(yy, - 2000, cast(dc.[ДатаОтчета] AS DATE))), 0) dt_st_month
					,dc.[НомерДоговора] number_deal
					,'Переобслуживание' 'type_wtiteoff_old'
					,'Переобслуживание' 'type_wtiteoff_new'
					,dateadd(yy, - 2000, cast(dc.[ДатаОтчета] AS DATE)) 'dt_wtiteoff'
					,sum_reservice = coalesce((dc.[СуммаСписанияПроцениты] + dc.[СуммаСписанияПени]), 0)
					,sum_remission = coalesce(0, 0)
				FROM (
					SELECT *
					FROM #disc_calc_base_rn
					WHERE 1 = 1
						AND [ПричинаЗакрытияНаименование] = 'Дисконтный калькулятор'
					) dc
				LEFT JOIN (
					SELECT [ДатаОтчета]
						,[НомерДоговора]
						,[ПричинаЗакрытияНаименование]
						,[СуммаПрощенияОсновнойДолг]
						,[СуммаПрощенияПроценты]
						,[СуммаПрощенияПени]
					FROM #disc_calc_base_rn
					WHERE 1 = 1
						AND [ПричинаЗакрытияНаименование] IN ('Оферта 20% + новый график', 'Согласно Приказа №112 от 11.04.2019 "О проведении Акции "Прощение процентов"')
					) ofer ON ofer.[НомерДоговора] = dc.[НомерДоговора]
					AND dateadd(dd, 1, ofer.[ДатаОтчета]) = dc.[ДатаОтчета]
				WHERE 1 = 1
					AND dc.rn = 1
					AND coalesce((dc.[СуммаСписанияПроцениты] + dc.[СуммаСписанияПени]), 0) > 0
				)
				,base_remission
			AS
				-- сбор сумм переобслуживания и прощения по дисконтному 
				(
				/**/ SELECT DATEADD(month, DATEDIFF(month, 0, dateadd(yy, - 2000, cast(dc.[ДатаОтчета] AS DATE))), 0) dt_st_month
					,dc.[НомерДоговора] number_deal
					,'Прощение 233' 'type_wtiteoff_old'
					,'Прощение 233' 'type_wtiteoff_new'
					,dateadd(yy, - 2000, cast(dc.[ДатаОтчета] AS DATE)) 'dt_wtiteoff'
					,sum_reservice = coalesce(0, 0)
					,sum_remission = CASE 
						WHEN ofer.[ПричинаЗакрытияНаименование] IS NOT NULL -- списание %% в витрине указывается накопительно, поэтому в тех случаях, где мы ранее проводили списание %% по акциям отличным от дисконтного калькулятора, там прощенные %% учитывать не нужно
							THEN coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]), 0) - coalesce((ofer.[СуммаПрощенияОсновнойДолг] + ofer.[СуммаПрощенияПроценты] + ofer.[СуммаПрощенияПени]), 0)
						ELSE coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]), 0)
						END
				FROM (
					SELECT *
					FROM #disc_calc_base_rn
					WHERE 1 = 1
						AND [ПричинаЗакрытияНаименование] = 'Дисконтный калькулятор'
					) dc
				LEFT JOIN (
					SELECT [ДатаОтчета]
						,[НомерДоговора]
						,[ПричинаЗакрытияНаименование]
						,[СуммаПрощенияОсновнойДолг]
						,[СуммаПрощенияПроценты]
						,[СуммаПрощенияПени]
					FROM #disc_calc_base_rn
					WHERE 1 = 1
						AND [ПричинаЗакрытияНаименование] IN ('Оферта 20% + новый график', 'Согласно Приказа №112 от 11.04.2019 "О проведении Акции "Прощение процентов"')
					) ofer ON ofer.[НомерДоговора] = dc.[НомерДоговора]
					AND dateadd(dd, 1, ofer.[ДатаОтчета]) = dc.[ДатаОтчета]
				WHERE 1 = 1
					AND dc.rn = 1
					AND (
						CASE 
							WHEN ofer.[ПричинаЗакрытияНаименование] IS NOT NULL
								THEN coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]), 0) - coalesce((ofer.[СуммаПрощенияОсновнойДолг] + ofer.[СуммаПрощенияПроценты] + ofer.[СуммаПрощенияПени]), 0)
							ELSE coalesce((dc.[СуммаПрощенияОсновнойДолг] + dc.[СуммаПрощенияПроценты] + dc.[СуммаПрощенияПени]), 0)
							END
						) > 0
				)
				,base_remission_200
			AS
				-- сбор сумм прощения долга менее 200 руб
				(
				SELECT DATEADD(month, DATEDIFF(month, 0, dateadd(yy, - 2000, cast(w200.[ДатаОтчета] AS DATE))), 0) dt_st_month
					,w200.[НомерДоговора] number_deal
					,'Списание сумм "Дарение"' 'type_wtiteoff_old'
					,'Списание сумм до 200 руб' 'type_wtiteoff_new'
					,dateadd(yy, - 2000, cast(w200.[ДатаОтчета] AS DATE)) 'dt_wtiteoff'
					,sum_reservice = coalesce(0, 0)
					,sum_remission = coalesce((w200.[СуммаПрощенияОсновнойДолг] + w200.[СуммаПрощенияПроценты] + w200.[СуммаПрощенияПени]), 0)
				FROM (
					SELECT *
					FROM #disc_calc_base_rn
					WHERE 1 = 1
						AND [ПричинаЗакрытияНаименование] = 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"'
					) w200
				WHERE w200.rn = 1
					AND (w200.[СуммаПрощенияОсновнойДолг] + w200.[СуммаПрощенияПроценты] + w200.[СуммаПрощенияПени]) <= 200 -- удаление 1% некорректных записей (сумма списание > 200 руб)
				)
				,base_remission_12
			AS
				-- сбор сумм прощения долга по приказу № 12
				(
				SELECT DATEADD(month, DATEDIFF(month, 0, dateadd(yy, - 2000, cast(w233.[ДатаОтчета] AS DATE))), 0) dt_st_month
					,w233.[НомерДоговора] number_deal
					,'Прощение 233' 'type_wtiteoff_old'
					,'Списание по приказу # 12' 'type_wtiteoff_new'
					,dateadd(yy, - 2000, cast(w233.[ДатаОтчета] AS DATE)) 'dt_wtiteoff'
					,sum_reservice = coalesce(0, 0)
					,sum_remission = coalesce((w233.[СуммаПрощенияОсновнойДолг] + w233.[СуммаПрощенияПроценты] + w233.[СуммаПрощенияПени]), 0)
				FROM (
					SELECT *
					FROM #disc_calc_base_rn
					WHERE 1 = 1
						AND [ПричинаЗакрытияНаименование] = 'Согласно Приказа №12 от 28.01.2019 о реализации пилотного проекта "Клиентский калькулятор"'
					) w233
				WHERE w233.rn = 1
				)
				,base_offer
			AS
				-- сбор сумм прощения по реструктуризации
				(
				SELECT DATEADD(month, DATEDIFF(month, 0, dateadd(yy, - 2000, cast(base.[ДатаОтчета] AS DATE))), 0) dt_st_month
					,base.[НомерДоговора] number_deal
					,'Оферта 20% + новый график' 'type_wtiteoff_old'
					,'Оферта 20% + новый график' 'type_wtiteoff_new'
					,dateadd(yy, - 2000, cast(base.[ДатаОтчета] AS DATE)) 'dt_wtiteoff'
					,sum_reservice = 0
					,sum_remission = coalesce((base.[СуммаПрощенияОсновнойДолг] + base.[СуммаПрощенияПроценты] + base.[СуммаПрощенияПени]), 0)
				FROM (
					SELECT *
					FROM #disc_calc_base_rn
					WHERE 1 = 1
						AND [ПричинаЗакрытияНаименование] = 'Оферта 20% + новый график'
					) base
				WHERE 1 = 1
					AND base.rn = 1
				)
			SELECT *
			INTO #base
			FROM base_reservice
			
			UNION ALL
			
			SELECT *
			FROM base_remission
			
			UNION ALL
			
			SELECT *
			FROM base_remission_200
			
			UNION ALL
			
			SELECT *
			FROM base_remission_12
			
			UNION ALL
			
			SELECT *
			FROM base_offer;

		EXEC [collection].set_debug_info @sp_name
			,'5';


 DROP TABLE

		IF EXISTS #percentnow;



	select [НомерДоговора],--cast(СтавкаПоДоговору as int),
	cast(СтавкаПоДоговору as float)[Percentnow]
	,max_p
	,min_p
	into #percentnow
	from
	(
					select [НомерДоговора],СтавкаПоДоговору, --case
					--when ПричинаЗакрытияНаименование is null then СтавкаПоДоговору
					--ROW_NUMBER() over (partition by НомерДоговора  order by ДатаОтчета )	rn
					ROW_NUMBER() over (partition by НомерДоговора  order by ОтчетнаяДата desc ) rnd
					,max(СтавкаПоДоговору) over (partition by НомерДоговора) max_p
					,min(СтавкаПоДоговору) over (partition by НомерДоговора) min_p
					from 
							[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]	

							--where [НомерДоговора]='18030720070002' --and ДатаОтчета>'4024-02-01'   and ПричинаЗакрытияНаименование =''
							)t
							where  rnd = 1
							






		DROP TABLE

		IF EXISTS #CollectingStage_history;
			-- сбор стадий просрочки по спейсу
			SELECT t03.Number
				,t02.ChangeDate Date_CollectingStage
				,t04.Name Name_CollectingStage INTO #CollectingStage_history
			FROM (
				SELECT t01.[ObjectId]
					,ROW_NUMBER() OVER (
						PARTITION BY t01.[ObjectId] ORDER BY t01.[ChangeDate] DESC
						) aa
					,cast(t01.[ChangeDate] AS DATE) ChangeDate
					,t01.[OldValue]
				FROM stg._collection.[DealHistory] t01
				WHERE t01.[Field] = 'Стадия коллектинга договора'
					AND cast(t01.[ChangeDate] AS DATE) >= dateadd(MM, - 1, @dt_from)
				) t02
			JOIN [Stg].[_Collection].[Deals] t03 ON t03.id = t02.[ObjectId]
			JOIN [Stg].[_Collection].[CollectingStage] t04 ON t04.[Id] = t02.[OldValue]
			WHERE aa = 1;

        EXEC [collection].set_debug_info @sp_name
			,'6';
		
		DROP TABLE

		IF EXISTS #reportStage_history;
			-- сбор стадий просрочки по терминалогии рисков
			SELECT DISTINCT t2.r_month
				,t1.external_id
				,t1.stage
				,t1.agent_name
			INTO #reportStage_history
			FROM reports.risk.dm_ReportCollectionPlanIspHard t1
			JOIN (
				SELECT dateadd(day, - datepart(day, t01.rep_dt) + 1, convert(DATE, t01.rep_dt)) r_month
					,t01.external_id
					,max(t01.rep_dt) rep_dt
					,max(t01.r_day) r_day
				FROM reports.risk.dm_ReportCollectionPlanIspHard t01
				WHERE dateadd(day, - datepart(day, t01.rep_dt) + 1, convert(DATE, t01.rep_dt)) >= @dt_from
				GROUP BY dateadd(day, - datepart(day, t01.rep_dt) + 1, convert(DATE, t01.rep_dt))
					,t01.external_id
				) t2 ON t2.external_id = t1.external_id
				AND t2.rep_dt = t1.rep_dt
				AND t2.r_day = t1.r_day;


		EXEC [collection].set_debug_info @sp_name
			,'7';

		TRUNCATE TABLE [collection].repbi_coll_debt_reservice_forgiveness_weekly_report;

		WITH deals_kk
		AS
			-- база договоров когда-либо бывших на КК
			(
			SELECT number
				,1 flag_kk
			FROM devdb.dbo.say_log_peredachi_kk
			GROUP BY number
			)
		INSERT INTO [collection].repbi_coll_debt_reservice_forgiveness_weekly_report
		SELECT brr.number_deal 'номер договора'
			,c.[LastName] + ' ' + c.[Name] + ' ' + c.[MiddleName] AS 'фио клиента'
			,brr.dt_wtiteoff 'дата операции списания'
			,brr.dt_st_month 'месяц операции списания'
			,cast(coalesce(dh.dpd_coll, 0) AS INT) 'срок просрочки на дату списания'
			,collection.bucket_dpd(cast(coalesce(dh.dpd_coll, 0) AS INT)) 'бакет просрочки на дату списания'
			,csh.Name_CollectingStage 'стадия коллектинга на дату списания'
			,CASE 
				WHEN rsh.stage = 'Hard'
					THEN 'Хард'
				WHEN rsh.stage = 'Агент'
					THEN 'КА'
				WHEN rsh.stage = 'ИП'
					THEN 'ИП'
				ELSE '0-90'
				END 'подразделение коллектинга на дату списания'
			,coalesce(rsh.agent_name, 'CarMoney') 'наименование агента на дату списания'
			,coalesce(kk.flag_kk, 0) 'флаг отношения к КК'
			,brr.type_wtiteoff_old 'тип операции списания'
			,brr.sum_reservice + brr.sum_remission 'сумма списания'
			,'финансовый результат от списания' = (brr.sum_reservice * - 1) + coalesce(pz.ОстатокРезерв, 0) + (brr.sum_remission * - 1) + (brr.sum_remission * - 1 * 0.2)
			,cast(pz.СтавкаПоДоговору as float) СтавкаПоДоговору
			,cast(max_p as float) max_p
	        ,cast(min_p as float) min_p
		FROM 
			#base brr
			LEFT JOIN 
			[Stg].[_Collection].[Deals] d ON d.[Number] = brr.number_deal
			LEFT JOIN 
			[Stg].[_Collection].[customers] c ON c.[Id] = d.[IdCustomer]
			LEFT JOIN 
			[dwh2].[dbo].[dm_CMRStatBalance] dh ON dh.external_id = brr.number_deal
													AND dh.[d] = dateadd(dd, - 1, dt_wtiteoff)
			LEFT JOIN 
			#CollectingStage_history csh ON csh.[Number] = brr.number_deal
			LEFT JOIN 
			#reportStage_history rsh ON rsh.external_id = brr.number_deal
										AND rsh.r_month = brr.dt_st_month
			LEFT JOIN 
			deals_kk kk ON kk.number = brr.number_deal
			LEFT JOIN 
			[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных] pz ON pz.НомерДоговора = brr.number_deal
																					AND pz.ОтчетнаяДата = convert(date, dateadd(dd, - 1, brr.dt_wtiteoff))


       left join #percentnow n on n.[НомерДоговора]=brr.[number_deal]
		WHERE 1 = 1
			AND brr.dt_st_month >= '2020-01-01'
			AND (brr.sum_reservice + brr.sum_remission) > 0;

		EXEC [collection].set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @recipients = 's.pischaev@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;

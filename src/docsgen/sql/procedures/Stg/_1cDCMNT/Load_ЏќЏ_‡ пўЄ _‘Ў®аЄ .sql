-- Usage: запуск процедуры с параметрами
-- EXEC _1cDCMNT.Load_ПЭП_Заявка_Сборка @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROC _1cDCMNT.Load_ПЭП_Заявка_Сборка
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	begin TRY
		if OBJECT_ID('tempdb..#tResult') is not null
			drop table #tResult


		;with
			t_PlanVidoHaracteristik as (select [Ссылка] ,[ПометкаУдаления] ,[Наименование] ,[ТипЗначения] ,[Виден] ,[ВладелецДополнительныхЗначений]
												,[ДополнительныеЗначенияИспользуются] ,[ДополнительныеЗначенияСВесом] ,[Доступен]
												,[Заголовок] ,[ЗаголовокФормыВыбораЗначения] ,[ЗаголовокФормыЗначения] ,[ЗаполнятьОбязательно] 
												,[Комментарий] ,[МногострочноеПолеВвода] ,[НаборСвойств] ,[Подсказка]
												,[УдалитьСклоненияПредмета] ,[ФорматСвойства] ,[ЭтоДополнительноеСведение] ,[УникальныйКодДляПоля]
										from  [_1cDCMNT].[ПланВидовХарактеристик_ДополнительныеРеквизитыИСведения] with (nolock))

		--,	t_tntDocDopRec as (select r.[_Reference72_IDRRef] as [Ссылка] ,r.[_KeyField] as [КлючЗаписи] ,r.[_LineNo1999] as [НомерСтроки] 
		--							 ,r.[_Fld2000RRef] as [Свойство] ,pl.[Наименование] as [СвойствоНаим]
		--							 ,r.[_Fld2001_TYPE] as [Значение_Тип] ,r.[_Fld2001_L] as [Значение_Булево]  ,r.[_Fld2001_N] as [Значение_Строка] ,r.[_Fld2001_T] as [Значение_Дата]
		--							 ,r.[_Fld2001_S] as [Значение_Число] ,r.[_Fld2001_RTRef] as [Значение_ТипСсылки] ,r.[_Fld2001_RRRef] as [Значение_Ссылка] ,r.[_Fld2002] as [ТекстоваяСтрока] 

		--					   from [_1cDCMNT].[_Reference72_VT1998X1] r with (nolock)
		--					   left join t_PlanVidoHaracteristik pl on r.[_Fld2000RRef]=pl.[Ссылка])
		,t_tntDocDopRec as (
			SELECT 
				r.Ссылка
				,r.КлючЗаписи
				,r.НомерСтроки
				,r.Свойство
				,pl.[Наименование] as [СвойствоНаим]
				,r.Значение_Тип
				,r.Значение_Булево
				,r.Значение_Строка
				,r.Значение_Дата
				,r.Значение_Число
				,r.Значение_ТипСсылки
				,r.Значение_Ссылка
				,r.ТекстоваяСтрока
			from _1cDCMNT.Справочник_ВнутренниеДокументы_ДополнительныеРеквизиты AS r with (nolock)
				LEFT join t_PlanVidoHaracteristik AS pl
					ON r.Свойство = pl.[Ссылка]
		)

		,	t_NumberRequest as (
				SELECT 
					[Ссылка],

					-- была ошибка: перепутаны [Значение_Строка] и [Значение_Число]
					--[Значение_Число] as [ЗаявкаНомер] 
					Значение_Строка as ЗаявкаНомер 
				FROM t_tntDocDopRec 
				WHERE [Свойство]=0xB81200155D4D085911E94655C54A9EA2
			) --Свойство Номер заявки

		--,	t_internalDoc as (select [_IDRRef] as [Ссылка] ,[_Code] as [Код] ,[_Description] as [Наименование] ,n.[ЗаявкаНомер]
		--							,case when [_Fld1974]<>N'' then [_Fld1945] else [_Fld1946] end as [ДатаРегистрСоздан] -- используется как условие для отбора документов

		--							,dr2.[Свойство] ,dr2.[СвойствоНаим] ,dr2.[Значение_Дата] ,dr2.[Значение_Строка] ,dr2.[Значение_Число] ,dr2.[ТекстоваяСтрока]

		--					  from [_1cDCMNT].[_Reference72X1] d with (nolock)
		--					  left join t_NumberRequest n on d.[_IDRRef]=n.[Ссылка]
		--					  left join t_tntDocDopRec dr2 on d.[_IDRRef]=dr2.[Ссылка] 
		--					  where [_Marked]=0x00
		--							and [_Fld1939RRef]=0xB81000155D03490F11E92E0C08F4645B)	--Вид внутреннего документа "Займ"

		,t_internalDoc as (
			SELECT 
				d.Ссылка,
				d.Код,
				d.Наименование,
				n.[ЗаявкаНомер]
				,case 
					WHEN d.РегистрационныйНомер <> N'' 
					THEN d.ДатаРегистрации
					ELSE d.ДатаСоздания
				END as [ДатаРегистрСоздан] -- используется как условие для отбора документов

				,dr2.[Свойство],
				dr2.[СвойствоНаим],
				dr2.[Значение_Дата],
				dr2.[Значение_Строка],
				dr2.[Значение_Число],
				dr2.[ТекстоваяСтрока]

			from _1cDCMNT.Справочник_ВнутренниеДокументы AS d with (nolock)
				LEFT join t_NumberRequest AS n on d.Ссылка = n.Ссылка
				LEFT join t_tntDocDopRec AS dr2 on d.Ссылка = dr2.Ссылка
			where d.ПометкаУдаления=0x00
			and d.ВидДокумента = 0xB81000155D03490F11E92E0C08F4645B
		)	--Вид внутреннего документа "Займ"


		select [Ссылка] --,[Код] 
				,[Наименование] ,[ЗаявкаНомер] --,[ДатаРегистрСоздан] 

				--,sum(case when [Свойство]=0xB80F00155D03492511E97CC88CD0CAF8 and [Значение_Строка]>0 then 1 else 0 end) as [ПЭП2]
				--,sum(case when [Свойство]=0xB80F00155D03492511E9822380CC419F and [Значение_Строка]>0 then 1 else 0 end) as [ТребуетсяПТС] 		
				--,sum(case when [Свойство]=0xB80F00155D03492511E9822380CC419F and [Значение_Строка]=0 then 1 else 0 end) as [ТребуетсяПТС_0]	
				--,sum(case when [Свойство]=0xB81000155D4D107C11E99397A464A4DE and [Значение_Строка]>0 then 1 else 0 end) as [ПодписанПЭПМП1] 
				--,sum(case when [Свойство]=0xB81200155D4D085911E945A6F6FF3088 and [Значение_Строка]>0 then 1 else 0 end) as [ВМ]  
				--,sum(case when [Свойство]=0xB80F00155D03492511E97CC88CD0CAF8 and [Значение_Строка]=0 then 1 else 0 end) as [ПЭП_0] 

				-- была ошибка: перепутаны [Значение_Строка] и [Значение_Число]
				,sum(case when [Свойство]=0xB80F00155D03492511E97CC88CD0CAF8 and [Значение_Число]>0 then 1 else 0 end) as [ПЭП2]
				,sum(case when [Свойство]=0xB80F00155D03492511E9822380CC419F and [Значение_Число]>0 then 1 else 0 end) as [ТребуетсяПТС] 		
				,sum(case when [Свойство]=0xB80F00155D03492511E9822380CC419F and [Значение_Число]=0 then 1 else 0 end) as [ТребуетсяПТС_0]	
				,sum(case when [Свойство]=0xB81000155D4D107C11E99397A464A4DE and [Значение_Число]>0 then 1 else 0 end) as [ПодписанПЭПМП1] 
				,sum(case when [Свойство]=0xB81200155D4D085911E945A6F6FF3088 and [Значение_Число]>0 then 1 else 0 end) as [ВМ]  
				,sum(case when [Свойство]=0xB80F00155D03492511E97CC88CD0CAF8 and [Значение_Число]=0 then 1 else 0 end) as [ПЭП_0] 

				,sum(case when [Свойство]=0xB80F00155D03492511E97CC8A7128BC7 and cast([Значение_Дата] as date)>='4019-01-01' then 1 else 0 end) as [ДатаПодписанияПЭП]


		into #tResult
		from t_internalDoc 

		group by [Ссылка] --,[Код] 
				,[Наименование] ,[ЗаявкаНомер] --,[ДатаРегистрСоздан] 
							

		if exists(select top(1) 1 from #tResult)
		begin
		truncate table  [_1cDCMNT].[ПЭП_Заявка_Сборка];

		insert into [_1cDCMNT].[ПЭП_Заявка_Сборка]([Ссылка] ,[Наименование] ,[ЗаявкаНомер] 
														,[ПЭП2] ,[ТребуетсяПТС] ,[ТребуетсяПТС_0] ,[ПодписанПЭПМП1] ,[ВМ] ,[ПЭП_0] ,[ДатаПодписанияПЭП] 
														)
												
		select [Ссылка] ,[Наименование] ,[ЗаявкаНомер] 
														,[ПЭП2] ,[ТребуетсяПТС] ,[ТребуетсяПТС_0] ,[ПодписанПЭПМП1] ,[ВМ] ,[ПЭП_0] ,[ДатаПодписанияПЭП] 
		
		from #tResult

		end
	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END

-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-05-07
-- Description:	Отчет о займах и действующих процентных ставках по данным МФО 

-- =============================================

CREATE PROCEDURE [dbo].[Report_CalcMailyan_mfo]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

with MainTable as
(
SELECT distinct [Этаж_L1] as [Этаж],[Род_L1] as [ПроРодитель],[Ссылка_L1] as [Родитель],[Код_L1] as [РодительКод],[Наим_L1] as [РодительНаим]
				,[Этаж_L2] as [ЭтажНиже],[Ссылка_L2] as [Подчиненный],[Код_L2] as [ПодчКод],[Наим_L2] as [ПодчНаим]
FROM [Stg].[dbo].[OfficeStructure_1cMFO]
WHERE not [Род_L1] is null or not [Ссылка_L2] is null

  union all

SELECT distinct [Этаж_L2] ,[Род_L2] ,[Ссылка_L2] ,[Код_L2] ,[Наим_L2] ,[Этаж_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3]
    FROM [Stg].[dbo].[OfficeStructure_1cMFO]
    where not [Род_L2] is null or not [Ссылка_L3] is null

  union all

SELECT distinct [Этаж_L3] ,[Род_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3] ,[Этаж_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4]
  FROM [Stg].[dbo].[OfficeStructure_1cMFO]
  where not [Род_L3] is null or not [Ссылка_L4] is null

    union all

SELECT distinct [Этаж_L4] ,[Род_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4] ,[Этаж_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5]
  FROM [Stg].[dbo].[OfficeStructure_1cMFO]
  where not [Род_L4] is null or not [Ссылка_L5] is null

    union all

SELECT distinct [Этаж_L5] ,[Род_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5] ,[Этаж_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6]
  FROM [Stg].[dbo].[OfficeStructure_1cMFO]
  where not [Род_L5] is null or not [Ссылка_L6] is null

    union all

SELECT distinct [Этаж_L6] ,[Род_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6] ,[Этаж_L7] ,[Ссылка_L7] ,[Код_L7] ,[Наим_L7]
  FROM [Stg].[dbo].[OfficeStructure_1cMFO]
  where not [Род_L6] is null or not [Ссылка_L7] is null
)

    -- Insert statements for procedure here
SELECT 
--      cast(dateadd(year,-2000,zl.[Период]) as datetime2) as [Период]
	  z.[Номер] as [ЗаявкаНомер]
	  ,(N'Заявка №' + z.[Номер]+N' от '+convert(varchar(10),dateadd(year,-2000,z.[Дата]),110)) as [Заявка] --convert(varchar(10),dateadd(year,-2000,z.[Дата]),110)
	  ,cast(dateadd(year,-2000,z.[Дата]) as smalldatetime) as [ЗаявкаДата]
--      ,zl.[Статус] as [СтатусСсылка]
	  ,zs.[Наименование] as [ТекСтатусЗаявки]
	  ,cast(dv.[ДатаВыдачиЗайма] as date) as [ДатаВыдачи]
	  ,d.[Номер] as [ДоговорНомер]
	  ,isnull(d.[Сумма],0) as [СуммаВыдачи]
--	  ,tv.[ТочкаВхода] as [ТочкаВхода]
	  ,rek.[Наименование] as [ТочкаВходаЗаявки]
	  ,o.[Код]  as [ДоговорТочкаКод]
	  ,o.[Наименование] as [ДоговорТочкаНаим]
	  ,cl.[Наименование] as [АгентПартнер]
--	  ,zl.[Заявка] as [ЗаявкаСсылка]
--	  ,kp.[ТекущаяСсуда]
--	  ,d.[ПроцентнаяСтавка]
	  ,case when d.[ПроцентнаяСтавка]<>0 then d.[ПроцентнаяСтавка] else kp.[ТекущаяСсуда] end as  [ПроцСтавкаКредита]
	  ,case when d.[СуммаДополнительныхУслуг]<>0 then 1 else 0 end as [ЕстьДопПродукт]
	  ,isnull(d.[СуммаДополнительныхУслуг],0) as [СуммаДопПродукта]
	  ,tvk.[Имя] as [ТочкаВхКл]
	  ,tv2k.[Имя] as [ТочкаВхПовторКл]
	  ,case 
			when tvk.[Имя]=N'ПовторныйЗайм' then 
												case 
													when not tv2k.[Имя] is null then 
																					case 
																						when tv2k.[Имя]=N'Другое' then  N'Прочее'
																						when tv2k.[Имя]=N'ЛКПартнера' then  N'Партнер'
																						else tv2k.[Имя] 
																					end
													else rek.[Наименование] 
												end
			when tvk.[Имя] is null then rek.[Наименование] 
			else 
				case 
					when tvk.[Имя]=N'Другое' then  N'Прочее'
					when tvk.[Имя]=N'ЛКПартнера' then  N'Партнер'
					else tvk.[Имя] 
				end 
	  end as [КаналМФО_ТочкаВх]

	  ,case when not tch.[РО_Регион] is null then tch.[РО_Регион] else N'Микрофинансирование' end as [Ро_Регион]
	  ,ms.[Имя] as [МестоСоздЗаявки]
	  ,svz.[Имя] as [СпособВыдачиЗайма]
	  ,bs.[СуммаСписания] as [СуммаВозвратаДС_Безакцепт]

FROM [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[РегистрСведений_ГП_СписокЗаявок_ИтогиСрезПоследних] zl
	
	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Документ_ГП_Заявка] z -- zayvka
		ON zl.[Заявка]=z.[Ссылка]

	left join (
				select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион],mt0.[ПодчНаим] as [Точка],mt0.[Подчиненный] as [ТочкаСсылка] 
				from MainTable mt0
					left join(select * from MainTable) mt1
					on mt0.[ПроРодитель]=mt1.[Подчиненный]
				where mt0.[ПодчНаим] like N'Партнер%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр'
				) tch -- Точка-РП-РО
		ON z.[Точка]=tch.[ТочкаСсылка]

  	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Перечисление_СпособыВыдачиЗаймов] svz --y
		on z.[СпособВыдачиЗайма]=svz.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Перечисление_ВидыДокредитования] dkr --y
		on z.[Докредитование]=dkr.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Перечисление_ГП_МестаСозданияЗаявки] ms --y
		on z.[МестоСозданияЗаявки]=ms.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[РегистрСведений_ТочкиВходаЗаявок] tv
		ON z.[ПредварительнаяЗаявка]=tv.[ПредварительнаяЗаявка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Документ_ГП_Договор] d
		ON z.[Ссылка]=d.[Заявка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Справочник_ГП_СтатусыЗаявок] zs
		ON zl.[Статус]=zs.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Справочник_НастройкиПринадлежностиКРекламнымКомпаниям] rek
		ON tv.[ТочкаВхода]=rek.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Перечисление_ТочкиВходаКлиентов] tvk
		ON d.[ТочкаВходаКлиента]=tvk.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Перечисление_ТочкиВходаКлиентов] tv2k
		ON d.[ТочкаВходаПовторногоКлиента]=tv2k.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Справочник_ГП_КредитныеПродукты] kp
		ON d.[КредитныйПродукт]=kp.[Ссылка]

	left join (SELECT max(cast(dateadd(year,-2000,[Период]) as datetime2)) as [ДатаВыдачиЗайма],[Заявка]
			   FROM [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[РегистрСведений_ГП_СписокЗаявок]
			   WHERE [Статус]=0xA398265179685AF34EED1A6B6349A87B -- Статус заем выдан
			   GROUP BY [Заявка]
				) dv
		ON z.[Ссылка]=dv.[Заявка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Справочник_ГП_Офисы] o
		ON d.[Точка]=o.[Ссылка]

	left join [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Справочник_Контрагенты] cl
		ON o.[Партнер]=cl.[Ссылка]

	left join (select [Договор] ,sum([СуммаСписания]) as [СуммаСписания]
			   from [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[Документ_БезакцептноеСписание]
			   where [ПометкаУдаления]=0x00
			   group by [Договор]) bs
		on d.[Ссылка]=bs.[Договор]

  where cast(dateadd(year,-2000,z.[Дата]) as datetime2)  >= dateadd(month,-1,dateadd(MONTH,datediff(MONTH,0,Getdate()),0))--dateadd(week,-2,dateadd(month,datediff(month,0,GetDate()),0)) 
		and cast(dateadd(year,-2000,z.[Дата]) as datetime2)<dateadd(day,datediff(day,0,GetDate()),0) 
		and z.[ПометкаУдаления]=0x00 --and Month(z.[Дата])=Month(@DateReport)
  order by z.[Дата] asc
END


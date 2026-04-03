



-- =============================================
-- Author:		
-- Create date: 2019-07-29
-- Description:	
--             exec [dbo].[reportdashboard02_CC_v3]   1

-- =============================================
CREATE PROC dbo.reportdashboard02_CC_v3
	
	-- Add the parameters for the stored procedure here
@PageNo int 

	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Время для учета формата 4К
declare @GetDate2000 datetime
set @GetDate2000=dateadd(year,2000,getdate());

-- Время для БД Наумен
declare @GetDateReal2000 datetime
set @GetDateReal2000=getdate();

--SET @GetDate2000 = CAST('4019-08-30T15:30:59.000' as datetime);

--set @GetDateReal2000 = CAST('2019-08-30T15:30:59.000' as datetime);

--DWH-1567
DECLARE @Partition_ID int, @Partition_7_ID int
SELECT @Partition_ID = Stg.$PARTITION.pfn_range_right_date_part_lcrm_leads_full(@GetDateReal2000)
SELECT @Partition_7_ID = Stg.$PARTITION.pfn_range_right_date_part_lcrm_leads_full(dateadd(day,-7,@GetDateReal2000))


-- Общая временная таблица для учета переходов статусов заявок
if OBJECT_ID('tempdb.dbo.#t_source') is not null
drop table dbo.#t_source;

create table #t_source
(НомерЗаявки  nvarchar(100) null,
[ПериодУчета] date not null
,[ПериодУчетаЗайм] date not null
,[ПериодУчетаСтатус] date not null
,[ДатаЗаявки] datetime null
,[ДатаСтатуса] datetime null
,[ДатаСтатусаСлед] datetime null 
,[СтатусНаим_Исх] nvarchar(100) null 
,[СтатусНаим_След] nvarchar(100) null 
,[СуммаЗаявки] numeric(15) null
,[Колво] numeric (15) null
,[КолвоДеньВДень] numeric (15) null
,[КолвоДеньВДеньЗайм] numeric (15) null
,[СуммаДеньВДень]  numeric (15) null
,[СуммаДеньВДеньЗайм] numeric (15) null
,[ЗаявкаСсылка_Исх] binary(16) null
,[ВыезднойМенеджер] nvarchar(5) null
,[АгентНаим] nvarchar(255) null
,[ПричинаОтказаНаим] nvarchar(255) null
,[СпособОформления] nvarchar(255) null
,[ТочкаВМ] nvarchar(255) null
,[ПЭП] nvarchar(255) null
,[СуммаЗайм] numeric(15) null
,[ЗаймКолво] numeric (15) null
,[ЗаймКолвоДеньВДень] numeric (15) null
,[ЗаймКолвоДеньВДеньЗайм] numeric (15) null
,[ЗаймСуммаДеньВДень]  numeric (15) null
,[ЗаймСуммаДеньВДеньЗайм] numeric (15) null
);


-- Временная таблица по структуре офисов
if OBJECT_ID('tempdb.dbo.#OfficeStructure_1cMFO') is not null
drop table dbo.#OfficeStructure_1cMFO

create table #OfficeStructure_1cMFO
(
[id_num] int IDENTITY(1,1)
,[Этаж_L1] nvarchar(2) not null
,[Род_L1] binary(16) null
,[Ссылка_L1] binary(16) null
,[Код_L1] nvarchar(50) null
,[Наим_L1] nvarchar(255) null
,[Этаж_L2] nvarchar(2) null
,[Род_L2] binary(16) null
,[Ссылка_L2] binary(16) null
,[Код_L2] nvarchar(50) null
,[Наим_L2] nvarchar(255) null
,[Этаж_L3] nvarchar(2) null
,[Род_L3] binary(16) null
,[Ссылка_L3] binary(16) null
,[Код_L3] nvarchar(50) null
,[Наим_L3] nvarchar(255) null
,[Этаж_L4] nvarchar(2) null
,[Род_L4] binary(16) null
,[Ссылка_L4] binary(16) null
,[Код_L4] nvarchar(50) null
,[Наим_L4] nvarchar(255) null
,[Этаж_L5] nvarchar(2) null
,[Род_L5] binary(16) null
,[Ссылка_L5] binary(16) null
,[Код_L5] nvarchar(50) null
,[Наим_L5] nvarchar(255) null
,[Этаж_L6] nvarchar(2) null
,[Род_L6] binary(16) null
,[Ссылка_L6] binary(16) null
,[Код_L6] nvarchar(50) null
,[Наим_L6] nvarchar(255) null
,[Этаж_L7] nvarchar(2) null
,[Род_L7] binary(16) null
,[Ссылка_L7] binary(16) null
,[Код_L7] nvarchar(50) null
,[Наим_L7] nvarchar(255) null
);

insert into #OfficeStructure_1cMFO(
									[Этаж_L1] ,[Род_L1] ,[Ссылка_L1] ,[Код_L1] ,[Наим_L1]
									,[Этаж_L2] ,[Род_L2] ,[Ссылка_L2] ,[Код_L2] ,[Наим_L2] 
									,[Этаж_L3] ,[Род_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3] 
									,[Этаж_L4] ,[Род_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4] 
									,[Этаж_L5] ,[Род_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5] 
									,[Этаж_L6] ,[Род_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6] 
									,[Этаж_L7] ,[Род_L7] ,[Ссылка_L7] ,[Код_L7] ,[Наим_L7]
									)
SELECT 
      'L1' as [Этаж_1] ,o1.[Родитель] as [Род_L1] ,o1.[Ссылка] as [Ссылка_L1] ,o1.[Код] as [Код_L1] ,o1.[Наименование] as [Наим_L1] -- 1-й уровень
	  ,oo2.[Этаж_L2] ,oo2.[Родитель] as [Род_L2] ,oo2.[Ссылка] as [Ссылка_L2] ,oo2.[Код] as [Код_L2] ,oo2.[Наименование] as [Наим_L2] -- 2-й уровень
	  ,oo2.[Этаж_L3] ,oo2.[Род_L3] ,oo2.[Ссылка_L3] ,oo2.[Код_L3] ,oo2.[Наим_L3] -- 3-й уровень
	  ,oo2.[Этаж_L4] ,oo2.[Род_L4] ,oo2.[Ссылка_L4] ,oo2.[Код_L4] ,oo2.[Наим_L4] -- 4-й уровень
	  ,oo2.[Этаж_L5] ,oo2.[Род_L5] ,oo2.[Ссылка_L5] ,oo2.[Код_L5] ,oo2.[Наим_L5] -- 5-й уровень
	  ,oo2.[Этаж_L6] ,oo2.[Род_L6] ,oo2.[Ссылка_L6] ,oo2.[Код_L6] ,oo2.[Наим_L6] -- 6-й уровень
	  ,oo2.[Этаж_L7] ,oo2.[Род_L7] ,oo2.[Ссылка_L7] ,oo2.[Код_L7] ,oo2.[Наим_L7] -- 7-й уровень

FROM [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) o1 
	left join (
			select 'L2' as [Этаж_L2], o2.[Ссылка], o2.[Родитель], o2.[Код], o2.[Наименование]
				   ,oo3.[Этаж_L3],oo3.[Ссылка] as [Ссылка_L3],oo3.[Родитель] as [Род_L3], oo3.[Код] as [Код_L3],oo3.[Наименование] as [Наим_L3]
				   ,oo3.[Этаж_L4],oo3.[Ссылка_L4],oo3.[Род_L4], oo3.[Код_L4],oo3.[Наим_L4]	
				   ,oo3.[Этаж_L5],oo3.[Ссылка_L5],oo3.[Род_L5], oo3.[Код_L5],oo3.[Наим_L5]	
				   ,oo3.[Этаж_L6],oo3.[Ссылка_L6],oo3.[Род_L6], oo3.[Код_L6],oo3.[Наим_L6]	
				   ,oo3.[Этаж_L7],oo3.[Ссылка_L7],oo3.[Род_L7], oo3.[Код_L7],oo3.[Наим_L7]	
			from [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) o2
			left join (
						select 'L3' as [Этаж_L3],o3.[Ссылка], o3.[Родитель], o3.[Код], o3.[Наименование]
							   ,oo4.[Этаж_L4],oo4.[Ссылка] as [Ссылка_L4],oo4.[Родитель] as [Род_L4], oo4.[Код] as [Код_L4],oo4.[Наименование] as [Наим_L4]
							   ,oo4.[Этаж_L5],oo4.[Ссылка_L5],oo4.[Род_L5], oo4.[Код_L5],oo4.[Наим_L5]
							   ,oo4.[Этаж_L6],oo4.[Ссылка_L6],oo4.[Род_L6], oo4.[Код_L6],oo4.[Наим_L6]
							   ,oo4.[Этаж_L7],oo4.[Ссылка_L7],oo4.[Род_L7], oo4.[Код_L7],oo4.[Наим_L7]
						from [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) o3
						left join (
									select 'L4' as [Этаж_L4],o4.[Ссылка], o4.[Родитель], o4.[Код], o4.[Наименование]
										   ,oo5.[Этаж_L5],oo5.[Ссылка] as [Ссылка_L5],oo5.[Родитель] as [Род_L5], oo5.[Код] as [Код_L5],oo5.[Наименование] as [Наим_L5]
										   ,oo5.[Этаж_L6],oo5.[Ссылка_L6],oo5.[Род_L6], oo5.[Код_L6],oo5.[Наим_L6]
										   ,oo5.[Этаж_L7],oo5.[Ссылка_L7],oo5.[Род_L7], oo5.[Код_L7],oo5.[Наим_L7]
									from [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) o4
									left join (
												select 'L5' as [Этаж_L5],o5.[Ссылка], o5.[Родитель], o5.[Код], o5.[Наименование]
													   ,oo6.[Этаж_L6],oo6.[Ссылка] as [Ссылка_L6],oo6.[Родитель] as [Род_L6], oo6.[Код] as [Код_L6],oo6.[Наименование] as [Наим_L6]
													   ,oo6.[Этаж_L7],oo6.[Ссылка_L7],oo6.[Род_L7], oo6.[Код_L7],oo6.[Наим_L7]
												from [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) o5
												left join (
															select 'L6' as [Этаж_L6],o6.[Ссылка], o6.[Родитель], o6.[Код], o6.[Наименование]
																	,oo7.[Этаж_L7],oo7.[Ссылка] as [Ссылка_L7],oo7.[Родитель] as [Род_L7], oo7.[Код] as [Код_L7],oo7.[Наименование] as [Наим_L7]
															from [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) o6
															left join (
																		select 'L7' as [Этаж_L7],o7.[Ссылка], o7.[Родитель], o7.[Код], o7.[Наименование]
																		from [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) o7
																		) oo7
															on o6.[Ссылка]=oo7.[Родитель]
															) oo6
												on o5.[Ссылка]=oo6.[Родитель]
												) oo5
									on o4.[Ссылка]=oo5.[Родитель]
									) oo4
						on o3.[Ссылка]=oo4.[Родитель]
						) oo3
			on o2.[Ссылка]=oo3.[Родитель]
			) oo2
	on o1.[Ссылка]=oo2.[Родитель]
WHERE o1.[Родитель]=0x00000000000000000000000000000000



-- Продолжение	
if OBJECT_ID('tempdb.dbo.#auxtab_TableOfficeMFO_1c') is not null
drop table dbo.#auxtab_TableOfficeMFO_1c;


create table #auxtab_TableOfficeMFO_1c
(
[Этаж] nvarchar(5) not null
,[ПроРодитель] binary(16) not null 
,[Родитель] binary(16) not null 
,[РодительКод] nvarchar(50) not null 
,[РодительНаим] nvarchar(255) null
,[ЭтажНиже] nvarchar(5) null
,[Подчиненный] binary(16) null 
,[ПодчКод] nvarchar(50) null 
,[ПодчНаим] nvarchar(255) null
);

insert into #auxtab_TableOfficeMFO_1c ([Этаж] ,[ПроРодитель] ,[Родитель] ,[РодительКод] ,[РодительНаим]
																	,[ЭтажНиже] ,[Подчиненный] ,[ПодчКод] ,[ПодчНаим])
SELECT * 
FROM
(
SELECT distinct [Этаж_L1] as [Этаж] ,[Род_L1] as [ПроРодитель] ,[Ссылка_L1] as [Родитель] ,[Код_L1] as [РодительКод] ,[Наим_L1] as [РодительНаим]
				,[Этаж_L2] as [ЭтажНиже] ,[Ссылка_L2] as [Подчиненный] ,[Код_L2] as [ПодчКод] ,[Наим_L2] as [ПодчНаим]
  FROM #OfficeStructure_1cMFO
  WHERE not [Род_L1] is null or not [Ссылка_L2] is null

  union all

  SELECT distinct [Этаж_L2] ,[Род_L2] ,[Ссылка_L2] ,[Код_L2] ,[Наим_L2] ,[Этаж_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3]
   FROM #OfficeStructure_1cMFO
   where not [Род_L2] is null or not [Ссылка_L3] is null

  union all

  SELECT distinct [Этаж_L3] ,[Род_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3] ,[Этаж_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4]
   FROM #OfficeStructure_1cMFO
   where not [Род_L3] is null or not [Ссылка_L4] is null

  union all

  SELECT distinct [Этаж_L4] ,[Род_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4] ,[Этаж_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5]
   FROM #OfficeStructure_1cMFO
   where not [Род_L4] is null or not [Ссылка_L5] is null

  union all

  SELECT distinct [Этаж_L5] ,[Род_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5] ,[Этаж_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6]
   FROM #OfficeStructure_1cMFO
   where not [Род_L5] is null or not [Ссылка_L6] is null

  union all

  SELECT distinct [Этаж_L6] ,[Род_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6] ,[Этаж_L7] ,[Ссылка_L7] ,[Код_L7] ,[Наим_L7]
  FROM #OfficeStructure_1cMFO
  where not [Род_L6] is null or not [Ссылка_L7] is null
) a
WHERE a.[Подчиненный] is not null

-- Продолжение
-- auxtab_OfficesOfPartnersMFO_1c
if OBJECT_ID('tempdb.dbo.#auxtab_OfficesOfPartnersMFO_1c') is not null
drop table dbo.#auxtab_OfficesOfPartnersMFO_1c;

create table #auxtab_OfficesOfPartnersMFO_1c
(
[РО_Регион] nvarchar(255) null
,[РП_Регион] nvarchar(255) null
,[ТочкаКод] nvarchar(255) null
,[Точка] nvarchar(255) not null
,[ТочкаСсылка] binary(16)
,[ДатаСоздания] date null
,[ДатаЗакрытия] date null
,[ВыезднойМенеджер] nvarchar(5) null
,[Агент] nvarchar(255) null
,[АгентСсылка] binary(16) null
);

insert into #auxtab_OfficesOfPartnersMFO_1c ([РО_Регион] ,[РП_Регион] ,[ТочкаКод] ,[Точка] ,[ТочкаСсылка] ,[ДатаСоздания] ,[ДатаЗакрытия] ,[ВыезднойМенеджер]
																		,[Агент] ,[АгентСсылка] 
																		)

select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион]
	  ,mt0.[ПодчКод] as [ТочкаКод],mt0.[ПодчНаим] as [Точка]
	  ,mt0.[Подчиненный] as [ТочкаСсылка] 
	  ,case when ofc.[ДатаСоздания]='2001-01-01 00:00:00.000' then null else cast(dateadd(year,-2000,cast(ofc.[ДатаСоздания] as datetime2)) as date) end as [ДатаСоздания]
	  ,case when ofc.[ДатаЗакрытия]='2001-01-01 00:00:00.000' then null else cast(dateadd(year,-2000,cast(ofc.[ДатаЗакрытия] as datetime2)) as date) end as [ДатаЗакрытия]
	  ,case when ofc.[ВыезднойМенеджер]=0x01 then N'Да' end as [ВыезднойМенеджер]
	  ,ofc.[Агент] ,ofc.[АгентСсылка]
from #auxtab_TableOfficeMFO_1c mt0
	left join (select * from #auxtab_TableOfficeMFO_1c) mt1
		on mt0.[ПроРодитель]=mt1.[Подчиненный]
	left join (select ofc0.[Ссылка] ,ofc1.[Наименование] as [Агент] ,ofc1.[Ссылка] as [АгентСсылка] ,ofc0.[ДатаСоздания] ,ofc0.[ДатаЗакрытия] ,ofc0.[ВыезднойМенеджер]
			   from [Stg].[_1cMFO].[Справочник_ГП_Офисы] (nolock) ofc0
				left join [Stg].[_1cMFO].[Справочник_Контрагенты]  (nolock) ofc1
					on ofc0.[Партнер]=ofc1.[Ссылка]
			  ) ofc
		on mt0.[Подчиненный]=ofc.[Ссылка]
where mt0.[ПодчНаим] like N'%Партнер%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр' or mt0.[ПодчНаим] like N'%ВМ%'
order by ofc.[ДатаСоздания] desc




-- [aux_ExitManager]
-- Создаем таблицу и заполняем данными
if OBJECT_ID('tempdb.dbo.#aux_ExitManager') is not null
drop table dbo.#aux_ExitManager;

CREATE TABLE #aux_ExitManager(
	[КодТочки] [nvarchar](255) NULL,
	[Точка] [nvarchar](255) NULL
) ON [PRIMARY]

INSERT  #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2939', N'Партнер № 2939 Архангельск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2956', N'Партнер № 2956 Астрахань')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2951', N'Партнер № 2951 Барнаул')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2368', N'Партнер № 2368 Белгород')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'1586', N'Партнер № 1586 Брянск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2948', N'Партнер № 2948 Владимир')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2320', N'Партнер № 2320 Вологда')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2919', N'Партнер № 2919 Воронеж')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2931', N'Партнер № 2931 Екатеринбург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2318', N'Партнер № 2318 Иваново')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2963', N'Партнер № 2963 Ижевск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2929', N'Партнер № 2929 Йошкар-Ола')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2920', N'Партнер № 2920 Казань')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2965', N'Партнер № 2965 Калининград')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2326', N'Партнер № 2326 Калуга')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2952', N'Партнер № 2952 Кемерово')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2947', N'Партнер № 2947 Киров')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2720', N'Партнер № 2720 Кострома')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2942', N'Партнер № 2942 Краснодар')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2932', N'Партнер № 2932 Красноярск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2944', N'Партнер № 2944 Курган')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2369', N'Партнер № 2369 Курск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2930', N'Партнер № 2930 Липецк')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2966', N'Партнер № 2966 Набережные Челны')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2309', N'Партнер № 2309 Нижний Новгород')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2953', N'Партнер № 2953 Новокузнецк')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2954', N'Партнер № 2954 Новосибирск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2946', N'Партнер № 2946 Омск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2921', N'Партнер № 2921 Оренбург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2937', N'Партнер № 2937 Пенза')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2933', N'Партнер № 2933 Пермь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2958', N'Партнер № 2958 Петрозаводск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'1570', N'Партнер № 1570 Ростов-на-Дону')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2328', N'Партнер № 2328 Рязань')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'203', N'Партнёр № 203 Смоленск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2329', N'Партнер № 2329 Смоленск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2367', N'Партнёр № 2367 Воронеж')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2949', N'Партнер № 2949 Саранск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2957', N'Партнер № 2957 Саратов')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'203', N'Партнер № 203 Смоленск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2940', N'Партнер № 2940 Сочи')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2941', N'Партнер № 2941 Ставрополь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2934', N'Партнер № 2934 Сургут')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2938', N'Партнер № 2938 Тамбов')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2964', N'Партнер № 2964 Тверь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2935', N'Партнер № 2935 Тольятти')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2955', N'Партнер № 2955 Томск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'205', N'Партнер № 205 Тула')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2943', N'Партнер № 2943 Тюмень')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2936', N'Партнер № 2936 Ульяновск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2962', N'Партнер № 2962 Уфа')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2950', N'Партнер № 2950 Чебоксары')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2945', N'Партнер № 2945 Челябинск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2317', N'Партнер № 2317 Череповец')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2322', N'Партнер № 2322 Ярославль')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2971', N'Партнер № 2971 Самара')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2970', N'Партнер № 2970 Тольятти')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2972', N'Партнер № 2972 Белгород')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2976', N'Партнер № 2976 Орел')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2977', N'Партнер № 2977 Краснодар')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2986', N'Партнер № 2986 Cочи')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2978', N'Партнер № 2978 Екатеринбург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2979', N'Партнер № 2979 Cтаврополь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2980', N'Партнер № 2980 Липецк')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3052', N'Партнер № 3052 Волгоград')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3053', N'Партнер № 3053 Самара')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2805', N'Партнер № 2805 Екатеринбург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3091', N'Партнер № 3091 Кемерово')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3092', N'Партнер № 3092 Кострома')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3093', N'Партнер № 3093 Петрозаводск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3094', N'Партнер № 3094 Рязань')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3095', N'Партнер № 3095 Смоленск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3096', N'Партнер № 3096 Пермь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3097', N'Партнер № 3097 Сургут')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3098', N'Партнер № 3098 Тюмень')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3099', N'Партнер № 3099 Уфа')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3100', N'Партнер № 3100 Череповец')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3101', N'Партнер № 3101 Ярославль')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3105', N'Партнер № 3105 Санкт-Петербург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2979', N'Партнер №2979 Ставрополь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3052', N'Партнер № 3052 Волгоград')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3053', N'Партнер № 3053 Самара')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3086', N'Партнер № 3086 Вологда')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3087', N'Партнер № 3087 Воронеж')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3088', N'Партнер № 3088 Иваново')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3089', N'Партнер № 3089 Казань')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3090', N'Партнер № 3090 Калининград')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3091', N'Партнер № 3091 Кемерово')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'510', N'Партнер № 510 Москва')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2929', N'Партнёр № 2929 Йошкар-ола')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2930', N'Партнёр № 2930 Липецк')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2959', N'Партнер № 2959 Санкт-Петербург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2960', N'Партнер № 2960 Санкт-Петербург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2416', N'Партнер № 2416 Липецк')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2319', N'Партнер № 2319 Тверь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2961', N'Партнер № 2961 Санкт-Петербург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2991', N'Партнёр № 2991 Орел')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3128', N'Партнер № 3128 Ставпрополь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3130', N'Партнер № 3130 Ростов-на-Дону')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3131', N'Партнер № 3131 Волгоград')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3153', N'Партнер № 3153 Краснодар')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3154', N'Партнер № 3154 Самара')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3156', N'Партнёр № 3156 Архангельск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3157', N'Партнёр № 3157 Калининград')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3158', N'Партнёр № 3158 Петрозаводск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3161', N'Партнёр № 3161 Казань')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3163', N'Партнёр № 3163 Сочи')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3164', N'Партнёр № 3164 Курск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3165', N'Партнёр № 3165 Белгород')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3166', N'Партнёр № 3166 Саратов')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3167', N'Партнёр № 3167 Набережные челны')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3170', N'Партнёр № 3170 Красноярск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3171', N'Партнёр № 3171 Нижний Тагил')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2319', N'Партнёр № 2319 Тверь')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3173', N'Партнёр № 3173 Омск')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3175', N'Партнёр № 3175 Тюмень')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3223', N'Партнер № 3223 Екатеринбург')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'3175', N'Партнер № 3175 Тюмень')
INSERT #aux_ExitManager ([КодТочки], [Точка]) VALUES (N'2206', N'Партнер № 2206 Москва');

with TableSource as
(
select zs.[Период] as [Период]
      ,zs.[Заявка] as [ЗаявкаСсылка]
	  ,z.[Номер] as [ЗаявкаНомер]
	  ,z.[Дата] as [ЗаявкаДата]
      ,zs.[Статус] as [СтатусСсылка]
	  ,st.[Наименование] as [СтатусНаим]
	  --,cr.[Наименование] as [ПричинаНаим] 
from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС]  (nolock) zs
	left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС]  (nolock)z
	on  zs.[Заявка]=z.[Ссылка]
	left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС]  (nolock) st
	on  zs.[Статус]=st.[Ссылка]
	--left join [Stg].[_1cCRM].[Справочник_CRM_ПричиныОтказов] cr
	--on zs.[ПричинаОтказа]=cr.[Ссылка]
where z.[Дата]>=dateadd(day,-14,dateadd(day,datediff(day,0,@GetDate2000),0)) and z.[Дата]<=@GetDate2000
	  and zs.[Статус]<>0xA81400155D94190011E80784923C60A7 
)
-- Предварительные
,	TablePreliminary as
(
select 
	ts1.[ЗаявкаСсылка] as [ЗаявкаСсылка_Исх]
	,ts1.[Период] as [Период_Исх]
	,ts1.[ЗаявкаНомер] as [ЗаявкаНомер_Исх]
	,ts1.[ЗаявкаДата] as [ЗаявкаДата_Исх]
	,ts1.[СтатусСсылка] as [СтатусСсылка_Исх]
	,ts1.[СтатусНаим] as [СтатусНаим_Исх]
	--,ts1.[ПричинаСсылка] as [ПричинаСсылка_Исх]
	--,ts1.[ПричинаНаим] as [ПричинаНаим_Исх]
	,ts2.[ЗаявкаСсылка] as [ЗаявкаСсылка_След]
	,ts2.[Период] as [Период_След]
	,min(ts2.[Период]) over(partition by ts1.[ЗаявкаСсылка], ts1.[Период] order by ts1.[Период]) as [Период_След_2]
	,ts2.[ЗаявкаДата] as [ЗаявкаДата_След]	
	,ts2.[СтатусСсылка] as [СтатусСсылка_След]	
	,ts2.[СтатусНаим] as [СтатусНаим_След]	
	--,ts2.[ПричинаСсылка] as [ПричинаСсылка_След]
	--,ts2.[ПричинаНаим] as [ПричинаНаим_След]
	,row_number() over(partition by ts1.[ЗаявкаСсылка] ,ts1.[СтатусСсылка] ,ts2.[СтатусСсылка] order by ts1.[Период] desc) as [rank_Status]
  from TableSource ts1
	left join TableSource ts2
	on ts1.[ЗаявкаСсылка]=ts2.[ЗаявкаСсылка] --and ts1.[ДатаЗаписиСтатуса]<ts2.[ДатаЗаписиСтатуса] 
		and ts1.[Период]<ts2.[Период]
  where ts2.[СтатусСсылка] <>0xA81400155D94190011E80784923C60A7 -- черновик
  
  --not in (0xB81500155D4D107811E9978BEDF95571	-- черновик из ЛК
		--													  ,0xA81400155D94190011E80784923C60A7 	-- черновик
		--													  ,0x80E400155D64100111E7BC9ADD36AB53 	-- забраковано
		--													  ,0xB81200155D36C90711E8FD799AF2C865  -- создан из заявки на займ
		--													  ) 
--		and ts2.[СтатусСсылка] is not null
 -- 
)


insert into #t_source(НомерЗаявки,[ПериодУчета] ,[ПериодУчетаЗайм] ,[ПериодУчетаСтатус] ,[ДатаЗаявки] ,[ДатаСтатуса] ,[ДатаСтатусаСлед] ,[СтатусНаим_Исх] ,[СтатусНаим_След] 
					  ,[СуммаЗаявки] ,[Колво] ,[КолвоДеньВДень] ,[КолвоДеньВДеньЗайм] ,[СуммаДеньВДень]  ,[СуммаДеньВДеньЗайм] ,[ЗаявкаСсылка_Исх] 
					  ,[ВыезднойМенеджер] ,[АгентНаим] ,[ПричинаОтказаНаим] ,[СпособОформления] ,[ТочкаВМ], [ПЭП])

select distinct z.Номер, /**/ cast(z.[Дата] as date) as [ПериодУчета] 
	   ,cast(rs.[Период_След] as date) as [ПериодУчетаЗайм]
	   ,cast(rs.[Период_Исх] as date) as [ПериодУчетаСтатус]
	   ,z.[Дата] as [ДатаЗаявки] 
	   ,rs.[Период_Исх] as [ДатаСтатуса] 
	   ,rs.[Период_След] as [ДатаСтатусаСлед] 
	   ,rs.[СтатусНаим_Исх] ,rs.[СтатусНаим_След]  
	   ,z.[Сумма] as [СуммаЗаявки] ,1 as [Колво] 
	   ,case when cast(z.[Дата] as date)=cast(rs.[Период_Исх] as date) then 1 else 0 end as [КолвоДеньВДень]
	   ,case when cast(z.[Дата] as date)=cast(rs.[Период_След] as date) then 1 else 0 end as [КолвоДеньВДеньЗайм]
	   ,case when cast(z.[Дата] as date)=cast(rs.[Период_Исх] as date) then z.[Сумма] else 0 end as [СуммаДеньВДень] 
	   ,case when cast(z.[Дата] as date)=cast(rs.[Период_След] as date) then z.[Сумма] else 0 end as [СуммаДеньВДеньЗайм]
	   ,rs.[ЗаявкаСсылка_Исх] 
	  ,o2.[ВыезднойМенеджер]
	  ,o2.[Агент] as [АгентНаим]
	  ,rc.[Наименование] as [ПричинаОтказаНаим]
	  ,coz.[Представление] as [СпособОформления] --N'Ввод операторами КЦ'    N'Оформление на партнерском сайте'
	  --,case when  tvm.[КодТочки] is null then null else N'ТочкаВМ_КонтактЦентр' end as [ТочкаВМ]
	  --,o2.[Точка] 
	  --,o2.[ТочкаКод]
	  --,tvm.[КодТочки]
	  , IIF (tvm.[КодТочки] is not null and not (o2.[Агент]='ИП Маилян Мгер Станиславович' and coz.[Представление]=N'Оформление на партнерском сайте'), 1,null) as [ТочкаВМ]
	  ,o1.[Код] as [ПЭП]

from (select *
	  from TablePreliminary
	  where [Период_След]=[Период_След_2] 
			and [Период_Исх]<>[Период_След]
			and  [СтатусСсылка_Исх]<>[СтатусСсылка_След]-- [СтатусНаим_Исх]<>[СтатусНаим_След]
			and [Период_След] is not null
			and [rank_Status]=1 ) rs
left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z
	on  rs.[ЗаявкаСсылка_Исх]=z.[Ссылка]
left join [Stg].[_1cCRM].[Справочник_Офисы]  (nolock) o1
	on z.[Офис]=o1.[Ссылка]
left join  #auxtab_OfficesOfPartnersMFO_1c  (nolock) o2
	on o1.[Код]=o2.[ТочкаКод]
left join [Stg].[_1cCRM].[Справочник_CRM_ПричиныОтказов]  (nolock) rc
	on z.[ПричинаОтказа]=rc.[Ссылка]
left join [Stg].[_1cCRM].[Перечисление_СпособыОформленияЗаявок]  (nolock) coz
on z.[СпособОформления]=coz.[Ссылка]
left join #aux_ExitManager tvm
on o2.[ТочкаКод]=tvm.[КодТочки]

/* Временная таблица для 2 */
if OBJECT_ID('tempdb.dbo.#MadeAppointment') is not null
drop table dbo.#MadeAppointment;

CREATE TABLE #MadeAppointment(

	[ДатаВстречи]  datetime2 null,
	[ЗаявкаСсылка] binary(16) null	
);

insert into #MadeAppointment([ДатаВстречи], [ЗаявкаСсылка])
	select max(m.[Дата]) as [ДатаВстречи] ,z.[Ссылка] as [ЗаявкаСсылка]
	from [Stg].[_1cCRM].[Документ_CRM_Мероприятие]  (nolock) m
		left join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие]  (nolock) v
		on  m.[ВзаимодействиеОснование]=v.[Ссылка]  
		left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС]  (nolock) z
		on  v.[Заявка_Ссылка]=z.[Ссылка] 
	where m.[ПометкаУдаления]=0x00 
		  and not z.[Ссылка] is null 
		  and cast(m.[Дата] as date)>=cast(@GetDate2000 as date)
	group by z.[Ссылка]

/* Временная таблица для 4 */
-- ==================================
--declare @GetDate2000 datetime

--set @GetDate2000=dateadd(year,2000,getdate());

--SET @GetDate2000 = CAST('4019-07-15T23:59:59.000' as datetime);

/* 15.08.2019
if OBJECT_ID('tempdb.dbo.#t_RequstAsLids') is not null
drop table dbo.#t_RequstAsLids;

CREATE TABLE #t_RequstAsLids(

[Документ] nvarchar(255) null,
[ДокСсылка] binary(16) null,
	[Дата]  datetime2 null,
	[Номер]  numeric (15) null, 
	[Телефон] numeric (15) null, 
	[ПериодУчета] datetime2 null,
	[rank_L]   numeric (15) null
	
);


insert into #t_RequstAsLids([Документ] ,[ДокСсылка] ,[Дата] ,[Номер] ,[Телефон] , [ПериодУчета], [rank_L] )
--with	t_RequstAsLids as
--(
select * 
from (select distinct N'Лид' as [Документ] ,[Ссылка] as [ДокСсылка] ,[Дата] ,[Номер] ,[Телефон] ,cast([Дата] as date) as [ПериодУчета] 
					  ,rank() over(partition by [Телефон]  ,cast([Дата] as date) order by [Дата] desc) as [rank_L]
	  from [Stg].[_1cCRM].[Документ_CRM_Заявка] 
	  where [ПометкаУдаления]=0x00 and not [Статус] in (0x80E400155D64100111E7F7BA3547760F -- забраковано
														,0xA81400155D94190011E80784923C6084 -- черновик
														,0xB81200155D36C90711E8FD799AF2C865) -- создан из заявки на займ
			and ([Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
				or [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
	  ) rl
where rl.[rank_L]=1
--)
--	Лиды с вх.звонками


if OBJECT_ID('tempdb.dbo.#TableLidsSource') is not null
drop table dbo.#TableLidsSource;

CREATE TABLE #TableLidsSource(

[Документ] nvarchar(255) null,
[ДокСсылка] binary(16) null,
	[Дата]  datetime2 null,
	[Номер]  nvarchar(100) null, 
	[Телефон] nvarchar (100) null, 
	[ПериодУчета] datetime2 null
	
);




if object_id('tempdb.dbo.#c1') is not null drop table #c1


 select distinct case when isnumeric(c0.[АбонентКакСвязаться])=1 then format(cast(c0.[АбонентКакСвязаться] as decimal(38,0)),'0') else  cast(c0.[АбонентКакСвязаться] as nvarchar(100))end [АбонентКакСвязаться] 
 into #c1
												  from #t_RequstAsLids z0
												  left join [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] c0


												  on case when isnumeric(z0.[Телефон])=1 then format(cast(z0.[Телефон] as decimal(38,0)),'0') else cast(z0.[Телефон]  as nvarchar(100)) end
                                                    =
                          case when isnumeric(c0.[АбонентКакСвязаться])=1 then format(cast(c0.[АбонентКакСвязаться] as decimal(38,0)),'0') else  cast(c0.[АбонентКакСвязаться] as nvarchar(100))end
												 
                          where
                           (z0.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
														or z0.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)



--select * from #c1

insert into #TableLidsSource([Документ] 
,[ДокСсылка] 
,[Дата] 
,[Номер] 
,[Телефон] 
, [ПериодУчета] 
)


--,	TableLidsSource as
--(

select distinct [Документ] ,[ДокСсылка] ,[Дата] ,[Номер] ,format([Телефон],'0') ,[ПериодУчета] 
from #t_RequstAsLids

union all



  select distinct N'ВхЗвонок' as [Документ]
              , try_cast(c.[Ссылка] as binary(16)) as [ДокСсылка] 
              , try_cast(c.[Дата]  as datetime2) [Дата]
              , case when isnumeric(c.[Номер] )=1 then  format(cast(c.[Номер] as decimal(38,0)) ,'0') else cast(c.[Номер] as nvarchar(100)) end[Номер]
              , case when isnumeric(c.[АбонентКакСвязаться])=1  then  format(cast(c.[АбонентКакСвязаться] as  decimal(38,0)),'0') else cast(c.[АбонентКакСвязаться]  as nvarchar(100)) end as [Телефон] 
              , try_cast(c.[Дата] as date) as [ПериодУчета] 
--              into #t
    from [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] c
   where [Входящий]=0x01 and [ПометкаУдаления]=0x00 
		
    and (c.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
				or c.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
        
		and not case when isnumeric(c.[АбонентКакСвязаться])=1 then format(cast(c.[АбонентКакСвязаться] as decimal(38,0)),'0') else  cast(c.[АбонентКакСвязаться] as nvarchar(100))end
											
    
    in (select distinct   c1.[АбонентКакСвязаться] from  #c1 c1 where  c1.[АбонентКакСвязаться] is not null)
-- )
--select * from #t


if OBJECT_ID('tempdb.dbo.#Request_cnt') is not null
drop table dbo.#Request_cnt;

CREATE TABLE #Request_cnt(

[Документ] nvarchar(255) null,
[ДокСсылка] binary(16) null,
	[Дата]  datetime2 null,
	[Номер]  nvarchar(255) null, 
	[ЗаявкаНомер] nvarchar(255) null, 
	[Статус] binary(16) null,
	[СтатусНаим]  nvarchar(255) null,
	[Лид] binary(16) null,
	[ВхЗвонок] binary(16) null,
	[ПериодУчета] datetime2 null,
	[ПериодУчетаЛид] datetime2 null,
	[НачальнаяЗаявка]  binary(16) null,
	[Партнер]  binary(16) null
	
);


insert into #Request_cnt([Документ] ,[ДокСсылка] ,[Дата] ,[Номер] ,[ЗаявкаНомер],[Статус], [СтатусНаим]  , [Лид] , [ВхЗвонок], [ПериодУчета],[ПериодУчетаЛид], [НачальнаяЗаявка], [Партнер] )
--,	Request_cnt as
--(
select distinct  N'Заявка' as [Документ] ,z.[Ссылка] as [ДокСсылка] ,z.[Дата] ,z.[Номер] ,z.[НомерЗаявки] as [ЗаявкаНомер] ,tz0.[Статус] ,sz.[Наименование] as [СтатусНаим] 
		,case 
			when not ld.[ДокСсылка] is null then ld.[ДокСсылка]
			else cll.[Ссылка]				
		end as [Лид]
		--,ld.[ДокСсылка] as [ЛидСсылка] 
		,cll.[Ссылка] as [ВхЗвонок] ,cast(z.[Дата] as date) as [ПериодУчета] ,ld.[ПериодУчета] as [ПериодУчетаЛид] ,z.[НачальнаяЗаявка] ,z.[Партнер] 
from [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z
	left join (select * from (select [Период] ,[Заявка] ,[Статус] ,rank() over(partition by [Заявка] order by [Период] desc) as [rank] 
							  from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС]) tz1
						where tz1.[rank]=1 and not [Статус] in (0xB81500155D4D107811E9978BEDF95571	-- черновик из ЛК
															  ,0xA81400155D94190011E80784923C60A7 	-- черновик
															  ,0x80E400155D64100111E7BC9ADD36AB53 	-- забраковано
															  ,0xB81200155D36C90711E8FD799AF2C865) -- создан из заявки на займ
			   ) tz0											  
	on z.[Ссылка]=tz0.[Заявка]
	left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] sz
	on tz0.[Статус]=sz.[Ссылка]
	left join (select * from [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] where [Входящий]=0x01) cll
	on z.[МобильныйТелефон]=cll.[АбонентКакСвязаться] and cast(z.[Дата] as date)=cast(cll.[Дата] as date)
	left join (select distinct * from #TableLidsSource) ld
	on z.[МобильныйТелефон]=ld.[Телефон] and cast(z.[Дата] as date)=cast(ld.[Дата] as date)
where z.[ПометкаУдаления]=0x00 and not tz0.[Статус] is null
	  and (z.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
	   or z.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
-- order by z.[Дата] asc 
--)

-- Конец комментирования временных таблиц 4
*/

/*
[t1_Таблица]
		,[t1_Колво] ,[t1_КолвоДеньВДень] ,[t1_Колво_7] ,[t1_КолвоДеньВДень_7] 
		,[t1_СуммаЗаявки] ,[t1_СуммаДеньВДень] ,[t1_СуммаЗаявки_7] ,[t1_СуммаДеньВДень_7] 
		,[t1_СрЧекТек] ,[t1_СрЧекДеньВДень] ,[t1_СрЧекТек_7] ,[t1_СрЧекДеньВДень_7]
*/


if OBJECT_ID('tempdb.dbo.#t1') is not null
drop table dbo.#t1;

CREATE TABLE #t1(

	[t1_Таблица]  nvarchar(255) NULL,
	[t1_Колво] numeric (15) null,
	[t1_КолвоДеньВДень] numeric (15) null,
	[t1_Колво_7] numeric (15) null,
	[t1_КолвоДеньВДень_7] numeric (15) null,
	[t1_СуммаЗаявки] numeric (15) null,
	[t1_СуммаДеньВДень] numeric (15) null,
	[t1_СуммаЗаявки_7] numeric (15) null,
	[t1_СуммаДеньВДень_7] numeric (15) null,
	[t1_СуммаЗаявки_MP] numeric (15) null, -- добавили МП
	[t1_СуммаДеньВДень_MP] numeric (15) null,
	[t1_СуммаЗаявки_7_MP] numeric (15) null,
	[t1_СуммаДеньВДень_7_MP] numeric (15) null,
	[t1_СуммаЗаявки_NE_MP] numeric (15) null, -- добавили Не МП
	[t1_СуммаДеньВДень_NE_MP] numeric (15) null,
	[t1_СуммаЗаявки_7_NE_MP] numeric (15) null,
	[t1_СуммаДеньВДень_7_NE_MP] numeric (15) null,
	[t1_СрЧекТек] numeric (15) null,
	[t1_СрЧекДеньВДень] numeric (15) null,
	[t1_СрЧекТек_7] numeric (15) null,
	[t1_СрЧекДеньВДень_7] numeric (15) null
	
);


with table_1 as		-- Таблица по выданным займам
(

SELECT N'table_1' as [Таблица] , N'Заем выдан' as [Показатель],
      dateadd(year,2000,cast(z.ДатаВыдачиПолн as date)) as [ПериодУчета], 
	  sum(z.[СуммаВыдачи]) as [СуммаЗаявки]
	  ,sum(1)  as [Колво] 
	  ,sum(case when dateadd(year,2000,cast(z.ДатаВыдачиПолн as date))=cast(rs.[ДатаЗаявки] as date) then 1 else 0 end) as [КолвоДеньВДень]
	  ,sum(case when dateadd(year,2000,cast(z.ДатаВыдачиПолн as date))=cast(rs.[ДатаЗаявки] as date) then z.[СуммаВыдачи] else 0 end) as [СуммаДеньВДень]	   
from  [dbo].[report_Agreement_InterestRate] z (nolock)
inner join [Stg].[_1cMFO].[Документ_ГП_Договор] rs (nolock)
on z.ДоговорНомер = rs.Номер
where z.ДатаВыдачиПолн between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and dateadd(day,-7,@GetDateReal2000)
		or 
		z.ДатаВыдачиПолн between dateadd(day,0,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and @GetDateReal2000
group by cast(z.ДатаВыдачиПолн as date) 

)
,
 table_1_mp as		-- Таблица по выданным займам МП
(

SELECT N'table_1' as [Таблица] , N'Заем выдан МП' as [Показатель],
      dateadd(year,2000,cast(z.ДатаВыдачиПолн as date)) as [ПериодУчета], 
	  sum(z.[СуммаВыдачи]) as [СуммаЗаявки]
	  ,sum(1)  as [Колво] 
	  ,sum(case when dateadd(year,2000,cast(z.ДатаВыдачиПолн as date))=cast(rs.[ДатаЗаявки] as date) then 1 else 0 end) as [КолвоДеньВДень]
	  ,sum(case when dateadd(year,2000,cast(z.ДатаВыдачиПолн as date))=cast(rs.[ДатаЗаявки] as date) then z.[СуммаВыдачи] else 0 end) as [СуммаДеньВДень]	   
from  [dbo].[report_Agreement_InterestRate] z (nolock)
inner join [Stg].[_1cMFO].[Документ_ГП_Договор] rs (nolock)
on z.ДоговорНомер = rs.Номер
where (z.ДатаВыдачиПолн between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and dateadd(day,-7,@GetDateReal2000)
		or 
		z.ДатаВыдачиПолн between dateadd(day,0,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and @GetDateReal2000)
		and МестоСоздЗаявки = N'МобильноеПриложение'
group by cast(z.ДатаВыдачиПолн as date) 

)
, table_1_ne_mp as		-- Таблица по выданным займам не МП
(

SELECT N'table_1' as [Таблица] , N'Заем выдан не МП' as [Показатель],
      dateadd(year,2000,cast(z.ДатаВыдачиПолн as date)) as [ПериодУчета], 
	  sum(z.[СуммаВыдачи]) as [СуммаЗаявки]
	  ,sum(1)  as [Колво] 
	  ,sum(case when dateadd(year,2000,cast(z.ДатаВыдачиПолн as date))=cast(rs.[ДатаЗаявки] as date) then 1 else 0 end) as [КолвоДеньВДень]
	  ,sum(case when dateadd(year,2000,cast(z.ДатаВыдачиПолн as date))=cast(rs.[ДатаЗаявки] as date) then z.[СуммаВыдачи] else 0 end) as [СуммаДеньВДень]	   
from  [dbo].[report_Agreement_InterestRate] z (nolock)
inner join [Stg].[_1cMFO].[Документ_ГП_Договор] rs (nolock)
on z.ДоговорНомер = rs.Номер
where (z.ДатаВыдачиПолн between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and dateadd(day,-7,@GetDateReal2000)
		or 
		z.ДатаВыдачиПолн between dateadd(day,0,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and @GetDateReal2000)
		and МестоСоздЗаявки <> N'МобильноеПриложение'
group by cast(z.ДатаВыдачиПолн as date) 

)

insert into #t1 ([t1_Таблица]
		,[t1_Колво] ,[t1_КолвоДеньВДень] ,[t1_Колво_7] ,[t1_КолвоДеньВДень_7] 
		,[t1_СуммаЗаявки] ,[t1_СуммаДеньВДень] ,[t1_СуммаЗаявки_7] ,[t1_СуммаДеньВДень_7]		
		,[t1_СрЧекТек] ,[t1_СрЧекДеньВДень] ,[t1_СрЧекТек_7] ,[t1_СрЧекДеньВДень_7]
		,[t1_СуммаЗаявки_MP] ,[t1_СуммаДеньВДень_MP] ,[t1_СуммаЗаявки_7_MP] ,[t1_СуммаДеньВДень_7_MP]		
		,[t1_СуммаЗаявки_NE_MP] ,[t1_СуммаДеньВДень_NE_MP] ,[t1_СуммаЗаявки_7_NE_MP] ,[t1_СуммаДеньВДень_7_NE_MP] )
select case when a1.[Таблица] is null then a0.[Таблица] else a1.[Таблица] end as  [Таблица]
		,[Колво] ,[КолвоДеньВДень] ,[Колво_7] ,[КолвоДеньВДень_7] 
		,[СуммаЗаявки] ,[СуммаДеньВДень] ,[СуммаЗаявки_7] ,[СуммаДеньВДень_7] 
		,[СрЧекТек] ,[СрЧекДеньВДень] ,[СрЧекТек_7] ,[СрЧекДеньВДень_7]
		,[СуммаЗаявки_MP] ,[СуммаДеньВДень_MP] ,[СуммаЗаявки_7_MP] ,[СуммаДеньВДень_7_MP] 
		,[СуммаЗаявки_NE_MP] ,[СуммаДеньВДень_NE_MP] ,[СуммаЗаявки_7_NE_MP] ,[СуммаДеньВДень_7_NE_MP] 
from (select [Таблица] ,[Колво] ,[КолвоДеньВДень] 
			,[СуммаЗаявки] ,[СуммаДеньВДень] 
			,case when isnull([Колво],0)=0 then 0 else cast([СуммаЗаявки]/[Колво] as numeric(15)) end as [СрЧекТек] 
			,case when isnull([КолвоДеньВДень],0)=0 then 0 else cast([СуммаДеньВДень]/[КолвоДеньВДень] as numeric(15)) end as [СрЧекДеньВДень] 
	  from table_1 where [ПериодУчета]=cast(@GetDate2000 as date) ) a0
left join (select [Таблица] ,[Колво] as [Колво_7] ,[КолвоДеньВДень] as [КолвоДеньВДень_7] 
				,[СуммаЗаявки] as [СуммаЗаявки_7] ,[СуммаДеньВДень] as [СуммаДеньВДень_7]
				,case when isnull([Колво],0)=0 then 0 else cast([СуммаЗаявки]/[Колво] as numeric(15)) end as [СрЧекТек_7] 
				,case when isnull([КолвоДеньВДень],0)=0 then 0 else cast([СуммаДеньВДень]/[КолвоДеньВДень] as numeric(15)) end as [СрЧекДеньВДень_7]
		   from table_1 where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date) ) a1
		   on a0.[Таблица]=a1.[Таблица]
left join (select [Таблица] --,[Колво] as [Колво_7] ,[КолвоДеньВДень] as [КолвоДеньВДень_7] 
				,[СуммаЗаявки] as [СуммаЗаявки_MP] ,[СуммаДеньВДень] as [СуммаДеньВДень_MP]
				--,case when isnull([Колво],0)=0 then 0 else cast([СуммаЗаявки]/[Колво] as numeric(15)) end as [СрЧекТек_7] 
				--,case when isnull([КолвоДеньВДень],0)=0 then 0 else cast([СуммаДеньВДень]/[КолвоДеньВДень] as numeric(15)) end as [СрЧекДеньВДень_7]
		   from table_1_mp where [ПериодУчета]=cast(@GetDate2000 as date) ) a3
		   on a0.[Таблица]=a3.[Таблица]
left join (select [Таблица] --,[Колво] as [Колво_7] ,[КолвоДеньВДень] as [КолвоДеньВДень_7] 
				,[СуммаЗаявки] as [СуммаЗаявки_7_MP] ,[СуммаДеньВДень] as [СуммаДеньВДень_7_MP]
				--,case when isnull([Колво],0)=0 then 0 else cast([СуммаЗаявки]/[Колво] as numeric(15)) end as [СрЧекТек_7] 
				--,case when isnull([КолвоДеньВДень],0)=0 then 0 else cast([СуммаДеньВДень]/[КолвоДеньВДень] as numeric(15)) end as [СрЧекДеньВДень_7]
		   from table_1_mp where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date) ) a4
		   on a0.[Таблица]=a4.[Таблица]
left join (select [Таблица] --,[Колво] as [Колво_7] ,[КолвоДеньВДень] as [КолвоДеньВДень_7] 
				,[СуммаЗаявки] as [СуммаЗаявки_NE_MP] ,[СуммаДеньВДень] as [СуммаДеньВДень_NE_MP]
				--,case when isnull([Колво],0)=0 then 0 else cast([СуммаЗаявки]/[Колво] as numeric(15)) end as [СрЧекТек_7] 
				--,case when isnull([КолвоДеньВДень],0)=0 then 0 else cast([СуммаДеньВДень]/[КолвоДеньВДень] as numeric(15)) end as [СрЧекДеньВДень_7]
		   from table_1_ne_mp where [ПериодУчета]=cast(@GetDate2000 as date) ) a5
		   on a0.[Таблица]=a5.[Таблица]
left join (select [Таблица] --,[Колво] as [Колво_7] ,[КолвоДеньВДень] as [КолвоДеньВДень_7] 
				,[СуммаЗаявки] as [СуммаЗаявки_7_NE_MP] ,[СуммаДеньВДень] as [СуммаДеньВДень_7_NE_MP]
				--,case when isnull([Колво],0)=0 then 0 else cast([СуммаЗаявки]/[Колво] as numeric(15)) end as [СрЧекТек_7] 
				--,case when isnull([КолвоДеньВДень],0)=0 then 0 else cast([СуммаДеньВДень]/[КолвоДеньВДень] as numeric(15)) end as [СрЧекДеньВДень_7]
		   from table_1_ne_mp where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date) ) a6
		   on a0.[Таблица]=a6.[Таблица]

if OBJECT_ID('tempdb.dbo.#t2') is not null
drop table dbo.#t2;

CREATE TABLE #t2(

	[t2_Таблица]  nvarchar(255) NULL,
	[t2_Колво0] numeric (15) null ,
	[t2_Колво1] numeric (15) null ,
	[t2_Колво2] numeric (15) null ,
	[t2_Колво3] numeric (15) null ,
	[t2_Колво4] numeric (15) null ,	
	[t2_Колво5] numeric (15) null ,
	[t2_Колво0_2] numeric (15) null ,
	[t2_Колво1_2] numeric (15) null ,
	[t2_Колво2_2] numeric (15) null ,
	[t2_Колво3_2] numeric (15) null ,
	[t2_Колво4_2] numeric (15) null ,
	[t2_Колво5_2] numeric (15) null
	
);

with 
--MadeAppointment as	
--(
----select max(dateadd(year,-2000,m.[Дата])) as [ДатаВстречи] ,z.[Ссылка] as [ЗаявкаСсылка]

--select max(m.[Дата]) as [ДатаВстречи] ,z.[Ссылка] as [ЗаявкаСсылка]

--from [Stg].[_1cCRM].[Документ_CRM_Мероприятие] m
--	left join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие] v
--	on  m.[ВзаимодействиеОснование]=v.[Ссылка]  
--	left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z
--	on  v.[Заявка_Ссылка]=z.[Ссылка] 
--where m.[ПометкаУдаления]=0x00 
--	  and not z.[Ссылка] is null 
--	  and cast(m.[Дата] as date)>=cast(@GetDate2000 as date)
--group by z.[Ссылка]
--)
--		Количество встреч
--,
	table_2 as
(
-- должны считать только заявки у которых последняя НАЗНАЧЕННАЯ встреча больше последней КД или у заявки есть  НАЗНАЧЕННАЯ встреча и нет КД.

--SELECT N'table_2' as [Таблица] ,N'Кол-во назначенных встреч всего' as [Показатель] ,cast([ДатаВстречи] as date) as [ДатаВстречи] ,count(*) as [Колво]
--FROM
--(
SELECT N'table_2' as [Таблица] ,N'Кол-во назначенных встреч всего' as [Показатель], a2.ДатаВстречи [ДатаВстречи], isnull(a2.Колво,0)+ isnull(a1.Колво,0) as [Колво] FROM
(
select N'table_2' as [Таблица] ,N'Кол-во назначенных встреч всего' as [Показатель] ,cast([ДатаВстречи] as date) as [ДатаВстречи] ,count(*) as [Колво]
from 
(select distinct [ДатаВстречи], ЗаявкаСсылка, [ДатаСтатуса]  from #MadeAppointment  ZADACHA
left join (SELECT * FROM #t_source  where СтатусНаим_Исх=N'Контроль данных') ZAYAVKA
on ZADACHA.ЗаявкаСсылка = ZAYAVKA.ЗаявкаСсылка_Исх
and (ZADACHA.ДатаВстречи < ZAYAVKA.[ДатаСтатуса]  --or ZAYAVKA.[ДатаСтатуса] is null
)) VSEGO
WHERE VSEGO.[ДатаСтатуса] is not null 
group by cast([ДатаВстречи] as date)
) a1
right join
(
-- плюс выведем данные по тем у кого нет вообще КД
select N'table_2' as [Таблица] ,N'Кол-во назначенных встреч всего 2' as [Показатель] ,cast([ДатаВстречи] as date) as [ДатаВстречи] ,count(*) as [Колво]
from  (select distinct [ДатаВстречи], ЗаявкаСсылка  from #MadeAppointment  
			Where ЗаявкаСсылка not in (SELECT distinct ЗаявкаСсылка_Исх from #t_source where СтатусНаим_Исх=N'Контроль данных' )) a3 
group by cast([ДатаВстречи] as date)
) a2
on a1.Таблица = a2.Таблица and a1.ДатаВстречи=a2.ДатаВстречи


-- в работе
union all

select N'table_2' as [Таблица] ,N'Кол-во встреч в работе' as [Показатель] ,cast([ДатаВстречи] as date) as [ДатаВстречи] ,count(*) as [Колво] 
from #MadeAppointment 
where not [ЗаявкаСсылка] in (select [ЗаявкаСсылка_Исх] 
								from #t_source
								where [СтатусНаим_Исх]=N'Встреча назначена' 
									and [ЗаявкаСсылка_Исх] in (select distinct [ЗаявкаСсылка] from #MadeAppointment))
group by cast([ДатаВстречи] as date)
)

--select * from table_2 
--		Количество встреч (2)
,	table_2_2 as
(
select t20.[Таблица] ,t20.[Показатель]
	   ,t21.[Колво] as [Колво0] ,t22.[Колво] as [Колво1] ,t23.[Колво] as [Колво2] ,t24.[Колво] as [Колво3] ,t25.[Колво] as [Колво4] ,t26.[Колво] as [Колво5]

from (select distinct [Таблица] ,[Показатель] from table_2) t20

left join (select [Таблица] ,[Показатель] ,[Колво] from table_2 where [ДатаВстречи]=cast(@GetDate2000 as date)) t21
	on t20.[Таблица]=t21.[Таблица] and t20.[Показатель]=t21.[Показатель]
left join (select [Таблица] ,[Показатель] ,[Колво] from table_2 where [ДатаВстречи]=cast(dateadd(day,1,@GetDate2000) as date)) t22
	on t20.[Таблица]=t22.[Таблица] and t20.[Показатель]=t22.[Показатель]
left join (select [Таблица] ,[Показатель] ,[Колво] from table_2 where [ДатаВстречи]=cast(dateadd(day,2,@GetDate2000) as date)) t23
	on t20.[Таблица]=t23.[Таблица] and t20.[Показатель]=t23.[Показатель]
left join (select [Таблица] ,[Показатель] ,[Колво] from table_2 where [ДатаВстречи]=cast(dateadd(day,3,@GetDate2000) as date)) t24
	on t20.[Таблица]=t24.[Таблица] and t20.[Показатель]=t24.[Показатель]
left join (select [Таблица] ,[Показатель] ,[Колво] from table_2 where [ДатаВстречи]=cast(dateadd(day,4,@GetDate2000) as date)) t25
	on t20.[Таблица]=t25.[Таблица] and t20.[Показатель]=t25.[Показатель]
left join (select [Таблица] ,[Показатель] ,[Колво] from table_2 where [ДатаВстречи]=cast(dateadd(day,5,@GetDate2000) as date)) t26
	on t20.[Таблица]=t26.[Таблица] and t20.[Показатель]=t26.[Показатель]
)

insert into #t2([t2_Таблица]  ,[t2_Колво0] ,[t2_Колво1] ,[t2_Колво2] ,[t2_Колво3] ,[t2_Колво4] ,[t2_Колво5]
	   ,[t2_Колво0_2] ,[t2_Колво1_2] ,[t2_Колво2_2] ,[t2_Колво3_2] ,[t2_Колво4_2] ,[t2_Колво5_2])

select t20.[Таблица]
	   ,t20.[Колво0] ,t20.[Колво1] ,t20.[Колво2] ,t20.[Колво3] ,t20.[Колво4] ,t20.[Колво5]
	   ,t21.[Колво0] as [Колво0_2] ,t21.[Колво1] as [Колво1_2] ,t21.[Колво2] as [Колво2_2] ,t21.[Колво3] as [Колво3_2] ,t21.[Колво4] as [Колво4_2] ,t21.[Колво5] as [Колво5_2]
from (select * from table_2_2 where [Показатель]=N'Кол-во назначенных встреч всего') t20
left join (select * from table_2_2 where [Показатель]=N'Кол-во встреч в работе') t21
	on t20.[Таблица]=t21.[Таблица]
--end


/*
	   [t3_Колво1_0] ,[t3_СуммаЗаявки1_0]
	   ,[t3_Колво1_1] ,[t3_СуммаЗаявки1_1]
	   ,[t3_Колво1_2] ,[t3_СуммаЗаявки1_2]
	   ,[t3_Колво1_3] ,[t3_СуммаЗаявки1_3]
	   ,[t3_Колво1_4] ,[t3_СуммаЗаявки1_4]
	   ,[t3_Колво1_5] ,[t3_СуммаЗаявки1_5]

	  ,[t3_Колво2_0] ,[t3_СуммаЗаявки2_0]
	  ,[t3_Колво2_1] ,[t3_СуммаЗаявки2_1]
	  ,[t3_Колво2_2] ,[t3_СуммаЗаявки2_2]
	  ,[t3_Колво2_3] ,[t3_СуммаЗаявки2_3]
	  ,[t3_Колво2_4] ,[t3_СуммаЗаявки2_4]
	  ,[t3_Колво2_5] ,[t3_СуммаЗаявки2_5]

*/
if OBJECT_ID('tempdb.dbo.#t3') is not null
drop table dbo.#t3;

CREATE TABLE #t3(

	--[t3_Таблица] nvarchar(255) NULL,
		[t3_Колво1_0] numeric (15) null,
		[t3_СуммаЗаявки1_0] numeric (15) null,
		[t3_Колво1_1] numeric (15) null,
		[t3_СуммаЗаявки1_1]	numeric (15) null,
		[t3_Колво1_2] numeric (15) null,
		[t3_СуммаЗаявки1_2]	numeric (15) null,
		[t3_Колво1_3] numeric (15) null,
		[t3_СуммаЗаявки1_3]	numeric (15) null,
		[t3_Колво1_4] numeric (15) null,
		[t3_СуммаЗаявки1_4]	numeric (15) null,
		[t3_Колво1_5] numeric (15) null,
		[t3_СуммаЗаявки1_5]	 numeric (15) null,
		-- добавили по задаче DWH-234
				[t3_Колво1_6] numeric (15) null,
				[t3_СуммаЗаявки1_6]	 numeric (15) null,
				[t3_Колво1_7] numeric (15) null,
				[t3_СуммаЗаявки1_7]	 numeric (15) null,
		[t3_Колво2_0] numeric (15) null,
		[t3_СуммаЗаявки2_0]	 numeric (15) null,
		[t3_Колво2_1] numeric (15) null,
		[t3_СуммаЗаявки2_1]	 numeric (15) null,
		[t3_Колво2_2] numeric (15) null,
		[t3_СуммаЗаявки2_2]	 numeric (15) null,
		[t3_Колво2_3] numeric (15) null,
		[t3_СуммаЗаявки2_3]	 numeric (15) null,
		[t3_Колво2_4] numeric (15) null,
		[t3_СуммаЗаявки2_4]	 numeric (15) null,
		[t3_Колво2_5] numeric (15) null,
		[t3_СуммаЗаявки2_5] numeric (15) null,
		-- добавили по задаче DWH-234
				[t3_Колво2_6] numeric (15) null,
				[t3_СуммаЗаявки2_6] numeric (15) null,
				[t3_Колво2_7] numeric (15) null,
				[t3_СуммаЗаявки2_7] numeric (15) null
	
);


-- заменили 3 на 5
--if @PageNo=5	-- ТРЕТЬЯ таблица
--begin
;with
-- Таблица по статусам
--	tablet as		
--(
--select N'table_3_table_5' as [Таблица] ,[СтатусНаим_Исх] as [Показатель]
--	  ,[ПериодУчетаСтатус] as [ПериодУчета] ,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
--	  ,[Колво] ,[СуммаЗаявки] ,[КолвоДеньВДень] ,[СуммаДеньВДень]
--from #t_source
--where [СтатусНаим_Исх] in (N'Предварительное одобрение' ,N'Встреча назначена' ,N'Контроль данных' ,N'Верификация документов клиента' 
--							,N'Одобрены документы клиента' ,N'Верификация документов' ,N'Одобрено' ,N'Договор подписан')
--)
	tablet as		
(
select N'table_3_table_5' as [Таблица] ,[СтатусНаим_След] as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] ,[ДатаЗаявки] ,[ДатаСтатусаСлед] as [ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,[Колво] ,[СуммаЗаявки] ,[КолвоДеньВДеньЗайм] as [КолвоДеньВДень]  ,[СуммаДеньВДеньЗайм] as [СуммаДеньВДень] 
from #t_source
where [СтатусНаим_След] in (N'Предварительное одобрение' ,N'Встреча назначена' ,N'Контроль данных' ,N'Верификация документов клиента' 
							,N'Одобрены документы клиента' ,N'Верификация документов' ,N'Одобрено' ,N'Договор подписан')
)

-- Таблица по статусам(2)
/*,	tablet_2 as		
(
select [Таблица] ,[Показатель] ,[ПериодУчета] ,sum([Колво]) as [Колво] ,sum([СуммаЗаявки]) as [СуммаЗаявки] ,sum([КолвоДеньВДень]) as [КолвоДеньВДень] ,sum([СуммаДеньВДень]) as [СуммаДеньВДень]
from tablet
group by [Таблица] ,[Показатель] ,[ПериодУчета]
)
*/
,      tablet_2 as         
(
select [Таблица] ,[Показатель] ,[ПериодУчета] ,sum([Колво]) as [Колво] ,sum([СуммаЗаявки]) as [СуммаЗаявки] ,sum([КолвоДеньВДень]) as [КолвоДеньВДень] ,sum([СуммаДеньВДень]) as [СуммаДеньВДень]
from tablet
-- так как поле ДатаСтатуса тождественно ПериодУчета, но с форматом содержащим время
where CAST([ДатаСтатуса] as time)<=CAST(@GetDate2000 as time)
group by [Таблица] ,[Показатель] ,[ПериодУчета]
)


--		Таблица по статусу Одобрено
,	tablet_approved as
(
select a0.[Таблица] ,a0.[Показатель] 
	   ,a1.[Колво] as [Колво1_0] ,a1.[СуммаЗаявки] as [СуммаЗаявки1_0]
	   ,a2.[Колво] as [Колво1_1] ,a2.[СуммаЗаявки] as [СуммаЗаявки1_1]
	   ,a3.[Колво] as [Колво1_2] ,a3.[СуммаЗаявки] as [СуммаЗаявки1_2]
	   ,a4.[Колво] as [Колво1_3] ,a4.[СуммаЗаявки] as [СуммаЗаявки1_3]
	   ,a5.[Колво] as [Колво1_4] ,a5.[СуммаЗаявки] as [СуммаЗаявки1_4]
	   ,a6.[Колво] as [Колво1_5] ,a6.[СуммаЗаявки] as [СуммаЗаявки1_5]
	   	   ,a7.[Колво] as [Колво1_6] ,a7.[СуммаЗаявки] as [СуммаЗаявки1_6]
		   	   ,a8.[Колво] as [Колво1_7] ,a8.[СуммаЗаявки] as [СуммаЗаявки1_7]


from (select distinct [Таблица] ,[Показатель] from tablet where [Показатель] = N'Одобрено') a0

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(@GetDate2000 as date)) a1
on a0.[Таблица]=a1.[Таблица] and a0.[Показатель]=a1.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(dateadd(day,-1,@GetDate2000) as date)) a2
on a0.[Таблица]=a2.[Таблица] and a0.[Показатель]=a2.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(dateadd(day,-2,@GetDate2000) as date)) a3
on a0.[Таблица]=a3.[Таблица] and a0.[Показатель]=a3.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(dateadd(day,-3,@GetDate2000) as date)) a4
on a0.[Таблица]=a4.[Таблица] and a0.[Показатель]=a4.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(dateadd(day,-4,@GetDate2000) as date)) a5
on a0.[Таблица]=a5.[Таблица] and a0.[Показатель]=a5.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(dateadd(day,-5,@GetDate2000) as date)) a6	
on a0.[Таблица]=a6.[Таблица] and a0.[Показатель]=a6.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(dateadd(day,-6,@GetDate2000) as date)) a7	
on a0.[Таблица]=a7.[Таблица] and a0.[Показатель]=a7.[Показатель]


left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Одобрено' and [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) a8	
on a0.[Таблица]=a8.[Таблица] and a0.[Показатель]=a8.[Показатель]

)
--		Таблица по статусу Договор подписан
,	tablet_AgreementSigned as
(
select a0.[Таблица] ,a0.[Показатель] 
	   ,a1.[Колво] as [Колво2_0] ,a1.[СуммаЗаявки] as [СуммаЗаявки2_0]
	   ,a2.[Колво] as [Колво2_1] ,a2.[СуммаЗаявки] as [СуммаЗаявки2_1]
	   ,a3.[Колво] as [Колво2_2] ,a3.[СуммаЗаявки] as [СуммаЗаявки2_2]
	   ,a4.[Колво] as [Колво2_3] ,a4.[СуммаЗаявки] as [СуммаЗаявки2_3]
	   ,a5.[Колво] as [Колво2_4] ,a5.[СуммаЗаявки] as [СуммаЗаявки2_4]
	   ,a6.[Колво] as [Колво2_5] ,a6.[СуммаЗаявки] as [СуммаЗаявки2_5]
		   ,a7.[Колво] as [Колво2_6] ,a7.[СуммаЗаявки] as [СуммаЗаявки2_6]
	   	   ,a8.[Колво] as [Колво2_7] ,a8.[СуммаЗаявки] as [СуммаЗаявки2_7]


from (select distinct [Таблица] ,[Показатель] from tablet where [Показатель] = N'Договор подписан') a0

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(@GetDate2000 as date)) a1
on a0.[Таблица]=a1.[Таблица] and a0.[Показатель]=a1.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(dateadd(day,-1,@GetDate2000) as date)) a2
on a0.[Таблица]=a2.[Таблица] and a0.[Показатель]=a2.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(dateadd(day,-2,@GetDate2000) as date)) a3
on a0.[Таблица]=a3.[Таблица] and a0.[Показатель]=a3.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(dateadd(day,-3,@GetDate2000) as date)) a4
on a0.[Таблица]=a4.[Таблица] and a0.[Показатель]=a4.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(dateadd(day,-4,@GetDate2000) as date)) a5
on a0.[Таблица]=a5.[Таблица] and a0.[Показатель]=a5.[Показатель]

left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(dateadd(day,-5,@GetDate2000) as date)) a6	
on a0.[Таблица]=a6.[Таблица] and a0.[Показатель]=a6.[Показатель]


left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(dateadd(day,-6,@GetDate2000) as date)) a7	
on a0.[Таблица]=a7.[Таблица] and a0.[Показатель]=a7.[Показатель]


left join (select [Таблица] ,[Показатель] ,[Колво] ,[СуммаЗаявки] from tablet_2 where [Показатель] = N'Договор подписан' and [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) a8	
on a0.[Таблица]=a8.[Таблица] and a0.[Показатель]=a8.[Показатель]

)

insert into #t3 ([t3_Колво1_0] ,[t3_СуммаЗаявки1_0]
	   ,[t3_Колво1_1] ,[t3_СуммаЗаявки1_1]
	   ,[t3_Колво1_2] ,[t3_СуммаЗаявки1_2]
	   ,[t3_Колво1_3] ,[t3_СуммаЗаявки1_3]
	   ,[t3_Колво1_4] ,[t3_СуммаЗаявки1_4]
	   ,[t3_Колво1_5] ,[t3_СуммаЗаявки1_5]
	   -- добавили по задаче DWH-234
			,[t3_Колво1_6] ,[t3_СуммаЗаявки1_6]
			,[t3_Колво1_7] ,[t3_СуммаЗаявки1_7]

	  ,[t3_Колво2_0] ,[t3_СуммаЗаявки2_0]
	  ,[t3_Колво2_1] ,[t3_СуммаЗаявки2_1]
	  ,[t3_Колво2_2] ,[t3_СуммаЗаявки2_2]
	  ,[t3_Колво2_3] ,[t3_СуммаЗаявки2_3]
	  ,[t3_Колво2_4] ,[t3_СуммаЗаявки2_4]
	  ,[t3_Колво2_5] ,[t3_СуммаЗаявки2_5]

	  -- добавили по задаче DWH-234
			,[t3_Колво2_6] ,[t3_СуммаЗаявки2_6]
			,[t3_Колво2_7] ,[t3_СуммаЗаявки2_7]
	  )

select -- заявка статус Одобрено
	   [Колво1_0] ,[СуммаЗаявки1_0]
	   ,[Колво1_1] ,[СуммаЗаявки1_1]
	   ,[Колво1_2] ,[СуммаЗаявки1_2]
	   ,[Колво1_3] ,[СуммаЗаявки1_3]
	   ,[Колво1_4] ,[СуммаЗаявки1_4]
	   ,[Колво1_5] ,[СуммаЗаявки1_5]
	   --
	   	   ,[Колво1_6] ,[СуммаЗаявки1_6]
		   ,[Колво1_7] ,[СуммаЗаявки1_7]

	  -- заявка статус Договор подписан
	  ,[Колво2_0] ,[СуммаЗаявки2_0]
	  ,[Колво2_1] ,[СуммаЗаявки2_1]
	  ,[Колво2_2] ,[СуммаЗаявки2_2]
	  ,[Колво2_3] ,[СуммаЗаявки2_3]
	  ,[Колво2_4] ,[СуммаЗаявки2_4]
	  ,[Колво2_5] ,[СуммаЗаявки2_5]

	  --
	  	  ,[Колво2_6] ,[СуммаЗаявки2_6]
		  ,[Колво2_7] ,[СуммаЗаявки2_7]

from tablet_approved t30
left join tablet_AgreementSigned t32
on t30.[Таблица]=t32.[Таблица]
--end


/*
[t4_Таблица] ,[t4_Колво]  ,[t4_КолвоДеньВДень] ,[t4_Колво_7] 
		,[t4_Колво_ВхЗв] ,[t4_КолвоДеньВДень_ВхЗв] ,[t4_Колво_7_ВхЗв]
		,[t4_Колво_Лид] ,[t4_КолвоДеньВДень_Лид] ,[t4_Колво_7_Лид] 
		,[t4_Колво_Заявка] ,[t4_КолвоДеньВДень_Заявка] ,[t4_Колво_7_Заявка] 
*/

-- необходимо вынести запросы к mfo на верхний уровень


if OBJECT_ID('tempdb.dbo.#t4') is not null
drop table dbo.#t4;

CREATE TABLE #t4(

	[t4_Таблица] nvarchar(255) NULL,-- Количество лидов (итого), шт
	[t4_Колво]  numeric (15) null,
	[t4_КолвоДеньВДень] numeric (15) null,
	[t4_Колво_7] 	numeric (15) null,
	[t4_Колво_ВхЗв] numeric (15) null, -- Входящие звонки, шт
	[t4_КолвоДеньВДень_ВхЗв] numeric (15) null,
	[t4_Колво_7_ВхЗв]	numeric (15) null,
	[t4_Колво_Лид] numeric (15) null,  -- Лиды, шт
	[t4_КолвоДеньВДень_Лид] numeric (15) null,
	[t4_Колво_7_Лид]	numeric (15) null,
	[t4_Колво_Лид_1] numeric (15) null,  -- Лиды наш КЦ, шт
	[t4_КолвоДеньВДень_Лид_1] numeric (15) null,
	[t4_Колво_7_Лид_1]	numeric (15) null,
	[t4_Колво_Лид_2] numeric (15) null,  -- Лиды, дошедшие в КЦ, шт
	[t4_КолвоДеньВДень_Лид_2] numeric (15) null,
	[t4_Колво_7_Лид_2]	numeric (15) null,
	[t4_Колво_Лид_3] numeric (15) null,  -- Уникальные лиды в КЦ
	[t4_КолвоДеньВДень_Лид_3] numeric (15) null,
	[t4_Колво_7_Лид_3]	numeric (15) null,
	[t4_Колво_ВРаботу] numeric (15) null,  -- Принято в работу (есть исх. звонок), шт
	[t4_КолвоДеньВДень_ВРаботу] numeric (15) null,
	[t4_Колво_7_ВРаботу]	numeric (15) null,
	[t4_Колво_Дозвон] numeric (15) null,  -- Дозвон, %
	[t4_КолвоДеньВДень_Дозвон] numeric (15) null,
	[t4_Колво_7_Дозвон]	numeric (15) null,
	[t4_Колво_Профильность] numeric (15) null,  -- Профильность лидов, %
	[t4_КолвоДеньВДень_Профильность] numeric (15) null,
	[t4_Колво_7_Профильность]	numeric (15) null,
	[t4_Колво_Заявка] numeric (15) null, -- Количество заявок (итого), шт
	[t4_КолвоДеньВДень_Заявка] numeric (15) null,
	[t4_Колво_7_Заявка] numeric (15) null,
	[t4_Колво_Заявка_1] numeric (15) null,
	[t4_КолвоДеньВДень_Заявка_1] numeric (15) null,
	[t4_Колво_7_Заявка_1] numeric (15) null,
	[t4_Колво_Заявка_2] numeric (15) null,
	[t4_КолвоДеньВДень_Заявка_2] numeric (15) null,
	[t4_Колво_7_Заявка_2] numeric (15) null,
	[t4_Колво_Заявка_3] numeric (15) null,
	[t4_КолвоДеньВДень_Заявка_3] numeric (15) null,
	[t4_Колво_7_Заявка_3] numeric (15) null,
	[t4_Колво_Заявка_4] numeric (15) null,
	[t4_КолвоДеньВДень_Заявка_4] numeric (15) null,
	[t4_Колво_7_Заявка_4] numeric (15) null,
	[t4_Колво_Заявка_5] numeric (15) null,
	[t4_КолвоДеньВДень_Заявка_5] numeric (15) null,
	[t4_Колво_7_Заявка_5] numeric (15) null,
	[t4_Колво_Заявка_6] numeric (15) null,
	[t4_КолвоДеньВДень_Заявка_6] numeric (15) null,
	[t4_Колво_7_Заявка_6] numeric (15) null
);


if OBJECT_ID('tempdb.dbo.#zvon') is not null
drop table dbo.#zvon;
--select * from #zvon
SELECT * 
INTO   #zvon
FROM
(
SELECT 
z.СпособОформления 'КаналОформления', z.Дата Дата, z.Номер Номер, 1 as Колво, z.ПричинаОтказа
--*
from [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС]  (nolock) z
left join (select * from (select [Период] ,[Заявка] ,[Статус] ,rank() over(partition by [Заявка] order by [Период] desc) as [rank] 
							  from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] (nolock))   tz1
						where tz1.[rank]=1 and not [Статус] in (0xB81500155D4D107811E9978BEDF95571	-- черновик из ЛК
															  ,0xA81400155D94190011E80784923C60A7 	-- черновик
															  ,0x80E400155D64100111E7BC9ADD36AB53 	-- забраковано
															  ,0xB81200155D36C90711E8FD799AF2C865  -- создан из заявки на займ
															  )  
															  and [Статус]  is not null
			   ) tz0	
			   on z.[Ссылка]=tz0.[Заявка]	
			   where z.[ПометкаУдаления]=0x00 
			   and 
			    tz0.[Статус]  is not null -- вернули 29 11 2019
	  and 
	  (z.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
	   or z.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)

 )  as s

 
;With Таблица_строка_7 as
(
select s71.[таблица] ,s71.[колво_заявка] ,s71.[колводеньвдень_заявка] ,s73.[колво_7_заявка] 
from (
select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво) as [колво_заявка] ,sum(колво)  as [колводеньвдень_заявка]
		   from  #zvon where дата between dateadd(day,0,dateadd(day,datediff(day,0,@getdate2000),0)) and @getdate2000 ) s71

left join (select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво)  as [колво_7_заявка]
			  from  #zvon where дата between dateadd(day,-7,dateadd(day,datediff(day,0,@getdate2000),0)) and dateadd(day,-7,@getdate2000)) s73
on  s71.[таблица]=s73.[таблица]
)
,
Таблица_строка_7_1 as --Ввод операторами КЦ
(
select s71.[таблица] ,s71.[колво_заявка] ,s71.[колводеньвдень_заявка] ,s73.[колво_7_заявка] 
from (
select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво) as [колво_заявка] ,sum(колво)  as [колводеньвдень_заявка]
		   from  #zvon where дата between dateadd(day,0,dateadd(day,datediff(day,0,@getdate2000),0)) and @getdate2000 
			and КаналОформления=0xA4867DD77BFA558846A2BF34FB1CABA9) s71

left join (select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво)  as [колво_7_заявка]
			  from  #zvon where дата between dateadd(day,-7,dateadd(day,datediff(day,0,@getdate2000),0)) and dateadd(day,-7,@getdate2000)
			  and КаналОформления=0xA4867DD77BFA558846A2BF34FB1CABA9) s73
on  s71.[таблица]=s73.[таблица]
)
,
Таблица_строка_7_2 as  -- Оформление (все другие) было до 29 11 2019 --Ввод операторами стороннего КЦ 0xA38F9540D79F9A474EFA2DADFA09ADA0
(
select s71.[таблица] ,s71.[колво_заявка] ,s71.[колводеньвдень_заявка] ,s73.[колво_7_заявка] 
from (
select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво) as [колво_заявка] ,sum(колво)  as [колводеньвдень_заявка]
		   from  #zvon where дата between dateadd(day,0,dateadd(day,datediff(day,0,@getdate2000),0)) and @getdate2000 
			and КаналОформления not in (0xA4867DD77BFA558846A2BF34FB1CABA9, 0xA7329507D134CC744546A4BD7D428B6C, 0xA79A95ADE4F2CF7742DF36CE7B806AA5, 0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D)) s71

left join (select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво)  as [колво_7_заявка]
			  from  #zvon where дата between dateadd(day,-7,dateadd(day,datediff(day,0,@getdate2000),0)) and dateadd(day,-7,@getdate2000)
			  and КаналОформления not in (0xA4867DD77BFA558846A2BF34FB1CABA9, 0xA7329507D134CC744546A4BD7D428B6C, 0xA79A95ADE4F2CF7742DF36CE7B806AA5, 0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D)) s73
on  s71.[таблица]=s73.[таблица]

-- 0xA4867DD77BFA558846A2BF34FB1CABA9, 0xA7329507D134CC744546A4BD7D428B6C, 0xA79A95ADE4F2CF7742DF36CE7B806AA5, 0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D
)
,
Таблица_строка_7_3 as --Ввод операторами LCRM
(
select s71.[таблица] ,s71.[колво_заявка] ,s71.[колводеньвдень_заявка] ,s73.[колво_7_заявка] 
from (
select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво) as [колво_заявка] ,sum(колво)  as [колводеньвдень_заявка]
		   from  #zvon where дата between dateadd(day,0,dateadd(day,datediff(day,0,@getdate2000),0)) and @getdate2000 
			and КаналОформления=0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D) s71

left join (select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво)  as [колво_7_заявка]
			  from  #zvon where дата between dateadd(day,-7,dateadd(day,datediff(day,0,@getdate2000),0)) and dateadd(day,-7,@getdate2000)
			  and КаналОформления=0xA9FA14A31AD2AE1C4A64AA35FF4DAD1D) s73
on  s71.[таблица]=s73.[таблица]
)
,
Таблица_строка_7_4 as --Оформление на клиентском сайте	0x8BA13AF32784DFCF47D0B66E1C0E387B
(
select s71.[таблица] ,s71.[колво_заявка] ,s71.[колводеньвдень_заявка] ,s73.[колво_7_заявка] 
from (
select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво) as [колво_заявка] ,sum(колво)  as [колводеньвдень_заявка]
		   from  #zvon where дата between dateadd(day,0,dateadd(day,datediff(day,0,@getdate2000),0)) and @getdate2000 
			and КаналОформления=0x8BA13AF32784DFCF47D0B66E1C0E387B) s71

left join (select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво)  as [колво_7_заявка]
			  from  #zvon where дата between dateadd(day,-7,dateadd(day,datediff(day,0,@getdate2000),0)) and dateadd(day,-7,@getdate2000)
			  and КаналОформления=0x8BA13AF32784DFCF47D0B66E1C0E387B) s73
on  s71.[таблица]=s73.[таблица]
)
,
Таблица_строка_7_5 as --Оформление на партнерском сайте	0xA7329507D134CC744546A4BD7D428B6C
(
select s71.[таблица] ,s71.[колво_заявка] ,s71.[колводеньвдень_заявка] ,s73.[колво_7_заявка] 
from (
select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво) as [колво_заявка] ,sum(колво)  as [колводеньвдень_заявка]
		   from  #zvon where дата between dateadd(day,0,dateadd(day,datediff(day,0,@getdate2000),0)) and @getdate2000 
			and КаналОформления=0xA7329507D134CC744546A4BD7D428B6C) s71

left join (select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво)  as [колво_7_заявка]
			  from  #zvon where дата between dateadd(day,-7,dateadd(day,datediff(day,0,@getdate2000),0)) and dateadd(day,-7,@getdate2000)
			  and КаналОформления=0xA7329507D134CC744546A4BD7D428B6C) s73
on  s71.[таблица]=s73.[таблица]
)
,
Таблица_строка_7_6 as --Оформление в мобильном приложении	0xA79A95ADE4F2CF7742DF36CE7B806AA5
(
select s71.[таблица] ,s71.[колво_заявка] ,s71.[колводеньвдень_заявка] ,s73.[колво_7_заявка] 
from (
select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво) as [колво_заявка] ,sum(колво)  as [колводеньвдень_заявка]
		   from  #zvon where дата between dateadd(day,0,dateadd(day,datediff(day,0,@getdate2000),0)) and @getdate2000 
			and КаналОформления=0xA79A95ADE4F2CF7742DF36CE7B806AA5) s71

left join (select N'table_4' as [таблица], N'колво_заявок_шт' as [показатель] ,sum(колво)  as [колво_7_заявка]
			  from  #zvon where дата between dateadd(day,-7,dateadd(day,datediff(day,0,@getdate2000),0)) and dateadd(day,-7,@getdate2000)
			  and КаналОформления=0xA79A95ADE4F2CF7742DF36CE7B806AA5) s73
on  s71.[таблица]=s73.[таблица]
)
,	str_2 as
(
------ колво вх.звонков
SELECT a1.[Таблица],  [КолвоДеньВДень] Колво_ВхЗв ,[Колво] КолвоДеньВДень_ВхЗв  , [Колво_7] Колво_7_ВхЗв from
(SELECT N'table_4' as [Таблица], COUNT(*)  as [КолвоДеньВДень] ,COUNT(*) as[Колво] 
 FROM [NaumenDbReport].[dbo].[call_legs]  (nolock)
  where
 leg_id = 1 and [incoming] =1
 and [created] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and @GetDateReal2000
) a1
 left join 
 (
 SELECT N'table_4' as [Таблица], COUNT(*)  as [Колво_7]
 FROM [NaumenDbReport].[dbo].[call_legs]  (nolock)
  where
 leg_id = 1 and [incoming] =1
  and [created] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and dateadd(day,-7,@GetDateReal2000)
 ) a2
on  a1.[Таблица]=a2.[Таблица]								

)
,
Таблица_Лиды_LCRM as
(
------ колво лидов
SELECT a1.[Таблица],  [КолвоДеньВДень] [t4_Колво_Лид] ,[Колво] [t4_КолвоДеньВДень_Лид]  , [Колво_7] [t4_Колво_7_Лид] from
(
--DWH-1567. Отказ от использования таблицы lcrm_leads_full_channel
--SELECT N'table_4' as [Таблица], COUNT(*)  as [КолвоДеньВДень] ,COUNT(*) as[Колво] 
-- FROM [dwh_new].[staging].[lcrm_tbl_full]  (nolock)
--  where [UF_ACTUALIZE_AT] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and @GetDateReal2000  
--    and UF_PRIORITY = 0
SELECT N'table_4' as [Таблица], count(*) as [КолвоДеньВДень], count(*) AS [Колво] 
FROM Stg._LCRM.lcrm_leads_full AS F (nolock)
WHERE F.UF_ACTUALIZE_AT BETWEEN dateadd(day,0,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and @GetDateReal2000  
    AND F.UF_PRIORITY = 0
	AND Stg.$PARTITION.pfn_range_right_date_part_lcrm_leads_full(F.UF_REGISTERED_AT) = @Partition_ID
) a1
 left join 
 (
--DWH-1567. Отказ от использования таблицы lcrm_leads_full_channel
 --SELECT N'table_4' as [Таблица], COUNT(*)  as [Колво_7]
 --FROM [dwh_new].[staging].[lcrm_tbl_full]  (nolock)
 -- where [UF_ACTUALIZE_AT] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and dateadd(day,-7,@GetDateReal2000)
 -- and UF_PRIORITY = 0
SELECT N'table_4' as [Таблица], count(*) as [Колво_7]
FROM Stg._LCRM.lcrm_leads_full AS F (nolock)
where F.UF_ACTUALIZE_AT BETWEEN dateadd(day,-7,dateadd(day,datediff(day,0,@GetDateReal2000),0)) and dateadd(day,-7,@GetDateReal2000)
    AND F.UF_PRIORITY = 0
	AND Stg.$PARTITION.pfn_range_right_date_part_lcrm_leads_full(F.UF_REGISTERED_AT) = @Partition_7_ID
 ) a2
on  a1.[Таблица]=a2.[Таблица]	
)
,
t_RequstAsLids as -- необходимо для последующего ограничения по лидам LCRM
(
select * 
from (select distinct N'Лид' as [Документ] ,[Ссылка] as [ДокСсылка] ,[Дата] ,[Номер] ,[Телефон] ,cast([Дата] as date) as [ПериодУчета] 
					--  ,row_number() over(partition by [Телефон]  ,cast([Дата] as date) order by [Дата] desc) as [rank_L]
					  --,1 as [rank_L]
					  ,Номер as НомерЛида , [Статус] as Состояние, ПричинаОтказа as ПричинаОтказа

	  from [Stg].[_1cCRM].[Документ_CRM_Заявка]  
	  where  
	 -- Номер <>'' -- Есть идентификатор LCRM
	  --[ПометкаУдаления]=0x00 
	  --
			--and 
			([Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
				or [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
				
				--and not [Статус] in (0x80E400155D64100111E7F7BA3547760F -- забраковано
				--					,0xA81400155D94190011E80784923C6086 -- повтор			--									
				--					) 
	  ) rl
--	  left join (SELECT Лид as Lid1, Состояние , row_number() over(partition by [Лид] order by [Период] desc) as [rank_Lid]  from [Stg].[_1cCRM].[РегистрСведений_ИсторияСтатусовЛидов] ) statuslids
--	  on statuslids.Lid1=rl.ДокСсылка
	  --on  rl.[ДокСсылка] = a2.Лид
--where --rl.[rank_L]=1 and
--[rank_Lid] = 1 or [rank_Lid] is null
),
Таблица_Лиды_наш_КЦ as -- Теперь Лиды CRM
(
------ колво лидов
SELECT a1.[Таблица],  [Колво] [t4_Колво_Лид_1] ,[КолвоДеньВДень] [t4_КолвоДеньВДень_Лид_1]  , [Колво_7] [t4_Колво_7_Лид_1] from
(SELECT N'table_4' as [Таблица], COUNT(*)  as [КолвоДеньВДень] ,COUNT(*) as[Колво] 
 FROM t_RequstAsLids
  where [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
) a1
 left join 
 (
 SELECT N'table_4' as [Таблица], COUNT(*)  as [Колво_7]
 FROM t_RequstAsLids
  where [Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
 ) a2
on  a1.[Таблица]=a2.[Таблица]	
),
Таблица_Лиды_Дошедшие as
(
------ колво лидов
SELECT a1.[Таблица], [Колво]  [t4_Колво_Лид_2] , [КолвоДеньВДень][t4_КолвоДеньВДень_Лид_2]  , [Колво_7] [t4_Колво_7_Лид_2] from
(SELECT N'table_4' as [Таблица], COUNT(*)  as [КолвоДеньВДень] ,COUNT(*) as[Колво] 
 FROM t_RequstAsLids
  where [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
) a1
 left join 
 (
 SELECT N'table_4' as [Таблица], COUNT(*)  as [Колво_7]
 FROM t_RequstAsLids
  where [Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
 ) a2
on  a1.[Таблица]=a2.[Таблица]	
)
,
Таблица_Уникальные_Лиды as -- статусы лида
(
------ колво лидов
SELECT a1.[Таблица],  [Колво] [t4_Колво_Лид_3] ,[КолвоДеньВДень] [t4_КолвоДеньВДень_Лид_3]  , [Колво_7] [t4_Колво_7_Лид_3] from
(SELECT N'table_4' as [Таблица], COUNT(*)  as [КолвоДеньВДень] ,COUNT(*) as[Колво] 
 FROM t_RequstAsLids
  where [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
  	  and  
	  [ДокСсылка] not in
	  (SELECT [ДокСсылка] FROM t_RequstAsLids 
	    where 
		--[Состояние]  in (0x80E400155D64100111E7F7BA3547760F -- забраковано
		--				 ,0xA81400155D94190011E80784923C6086 -- повтор
		--				)
		--and

		--ПричинаОтказа=0x80EC00155D01BF0711E51F0AA56DA5EE

		[Состояние]=0xA81400155D94190011E80784923C6086 -- повтор
		or
		(	
			
			[Состояние]=0x80E400155D64100111E7F7BA3547760F -- забраковано
			and
			ПричинаОтказа=0x80EC00155D01BF0711E51F0AA56DA5EE
		)
	 )

) a1
 left join 
 (
 SELECT N'table_4' as [Таблица], COUNT(*)  as [Колво_7]
 FROM t_RequstAsLids
  where [Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
      and  
	  [ДокСсылка] not in
	  (SELECT [ДокСсылка] FROM t_RequstAsLids 
	    where 
		--[Состояние]  in (0x80E400155D64100111E7F7BA3547760F -- забраковано
		--				 ,0xA81400155D94190011E80784923C6086 -- повтор
		--				)
		--and

		--ПричинаОтказа=0x80EC00155D01BF0711E51F0AA56DA5EE

		[Состояние]=0xA81400155D94190011E80784923C6086 -- повтор
		or
		(	
			
			[Состояние]=0x80E400155D64100111E7F7BA3547760F -- забраковано
			and
			ПричинаОтказа=0x80EC00155D01BF0711E51F0AA56DA5EE
		)
	 )
 ) a2
on  a1.[Таблица]=a2.[Таблица]	
)
,
ВРаботу as
(
------ колво лидов
SELECT a1.[Таблица],  [КолвоДеньВДень] [t4_КолвоДеньВДень_ВРаботу] ,[Колво] [t4_Колво_ВРаботу]  , [Колво_7] [t4_Колво_7_ВРаботу] from
(SELECT N'table_4' as [Таблица], COUNT(c.[АбонентКакСвязаться])  as [КолвоДеньВДень] --,COUNT(*) as[Колво] 
 FROM t_RequstAsLids lids
 left join (SELECT DISTINCT [АбонентКакСвязаться] FROM [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок]  (nolock)
 WHERE [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
 and [Входящий]=0x00 and [ПометкаУдаления]=0x00) c
 on c.[АбонентКакСвязаться]=lids.[Телефон]
where 
  lids.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
    	  and  
	  [ДокСсылка] not in
	  (SELECT [ДокСсылка] FROM t_RequstAsLids 
	    where 
		[Состояние]=0xA81400155D94190011E80784923C6086 -- повтор
		or
		(	
			
			[Состояние]=0x80E400155D64100111E7F7BA3547760F -- забраковано
			and
			ПричинаОтказа=0x80EC00155D01BF0711E51F0AA56DA5EE
		)
	 )
) a1
left join -- Здесь нужен обратный порядок от звонков 
(SELECT N'table_4' as [Таблица] ,COUNT(c.[АбонентКакСвязаться]) as[Колво] 
 FROM t_RequstAsLids lids
 left join (SELECT DISTINCT [АбонентКакСвязаться] FROM [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок]  (nolock)
 WHERE [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
 and [Входящий]=0x00 and [ПометкаУдаления]=0x00) c
 on c.[АбонентКакСвязаться]=lids.[Телефон]
where 
  lids.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
    	  and  
	  [ДокСсылка] not in
	  (SELECT [ДокСсылка] FROM t_RequstAsLids 
	    where 
		[Состояние]=0xA81400155D94190011E80784923C6086 -- повтор
		or
		(	
			
			[Состояние]=0x80E400155D64100111E7F7BA3547760F -- забраковано
			and
			ПричинаОтказа=0x80EC00155D01BF0711E51F0AA56DA5EE
		)
	 )
) a3
on  a1.[Таблица]=a3.[Таблица]	
 left join 
 (
 SELECT N'table_4' as [Таблица], COUNT([АбонентКакСвязаться])  as [Колво_7]
 FROM t_RequstAsLids lids
 left join (SELECT DISTINCT [АбонентКакСвязаться] FROM [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок]  (nolock)
 WHERE [Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
 and [Входящий]=0x00 and [ПометкаУдаления]=0x00) c
 on c.[АбонентКакСвязаться]=lids.[Телефон]
where lids.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
    	  and  
	  [ДокСсылка] not in
	  (SELECT [ДокСсылка] FROM t_RequstAsLids 
	    where 
		[Состояние]=0xA81400155D94190011E80784923C6086 -- повтор
		or
		(	
			
			[Состояние]=0x80E400155D64100111E7F7BA3547760F -- забраковано
			and
			ПричинаОтказа=0x80EC00155D01BF0711E51F0AA56DA5EE
		)
	 )
 ) a2
on  a1.[Таблица]=a2.[Таблица]	
)
,
ДозвонЛиды as
(
SELECT distinct Номер, Дата
FROM (
SELECT  Лиды.Номер Номер , Лиды.Дата Дата
--,  Взаимодействие.Результат ,  Взаимодействие.ДокументОснование_ТипСсылки , Взаимодействие.[ДокументОснование_Тип], Взаимодействие.[ВидВзаимодействия], ВидВзаимодействия.Наименование,ВидВзаимодействия.Описание, Задача.Выполнена, Лиды.ПометкаУдаления, Лиды.Статус
FROM [Stg].[_1cCRM].[Документ_CRM_Заявка] Лиды
inner join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие] Взаимодействие
on Лиды.Ссылка = Взаимодействие.Заявка_Ссылка
inner join [Stg].[_1cCRM].[Справочник_CRM_ВидыВзаимодействий] ВидВзаимодействия
on Взаимодействие.[ВидВзаимодействия] = ВидВзаимодействия.Ссылка
inner join [Stg].[_1cCRM].[Задача_ЗадачаИсполнителя] Задача
on Взаимодействие.Задача=Задача.Ссылка
WHERE 
Взаимодействие.Результат not like N'%недостающих%' 
and Взаимодействие.Результат not like N'%переадресована%' 
and ВидВзаимодействия.Направление=0x976C421A3319176B4DFCEB6D6B76EAD7
and  Задача.Выполнена = 0x01
and Лиды.ПометкаУдаления<>0x01
and Взаимодействие.ПометкаУдаления<>0x01
and Лиды.Статус<>0xB81200155D36C90711E8FD799AF2C865
and Взаимодействие.ДокументОснование_ТипСсылки=0x00000014
--and Лиды.Номер  like '%367071'

and (Лиды.Дата between  dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
or Лиды.Дата between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000))
--between @GetDate2000 and @GetDate2000_2
--order by Лиды.Дата desc
) a2
--order by Номер
)
--select * from ДозвонЛиды
,
Дозвон as
(
------ колво лидов
SELECT a1.[Таблица],  [КолвоДеньВДень] [t4_КолвоДеньВДень_Дозвон] ,[Колво] [t4_Колво_Дозвон]  , [Колво_7] [t4_Колво_7_Дозвон] from
	(SELECT N'table_4' as [Таблица], COUNT(Номер)  as [КолвоДеньВДень] ,COUNT(*) as[Колво] 
	 FROM ДозвонЛиды dozvonlids 
	 WHERE [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000
 
	) a1
	left join -- Здесь нужен обратный порядок от звонков 
	(SELECT N'table_4' as [Таблица] ,COUNT(Номер) as [Колво_7] 
	 FROM ДозвонЛиды dozvonlids  
	 WHERE [Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
	) a3
	on  a1.[Таблица]=a3.[Таблица]	
 
)

insert into #t4 ([t4_Таблица] 
       ,[t4_Колво]  ,[t4_КолвоДеньВДень] ,[t4_Колво_7] 
		,[t4_Колво_ВхЗв] ,[t4_КолвоДеньВДень_ВхЗв] ,[t4_Колво_7_ВхЗв]
		,[t4_Колво_Лид] ,[t4_КолвоДеньВДень_Лид] ,[t4_Колво_7_Лид] 

		, [t4_Колво_Лид_1],[t4_КолвоДеньВДень_Лид_1] ,[t4_Колво_7_Лид_1] 
		, [t4_Колво_Лид_2],[t4_КолвоДеньВДень_Лид_2] ,[t4_Колво_7_Лид_2] 
		, [t4_Колво_Лид_3],[t4_КолвоДеньВДень_Лид_3] ,[t4_Колво_7_Лид_3] 

		, [t4_Колво_ВРаботу] , [t4_КолвоДеньВДень_ВРаботу] , [t4_Колво_7_ВРаботу]
		, [t4_Колво_Дозвон] , [t4_КолвоДеньВДень_Дозвон] , [t4_Колво_7_Дозвон]
		,[t4_Колво_Заявка] ,[t4_КолвоДеньВДень_Заявка] ,[t4_Колво_7_Заявка],
		[t4_Колво_Заявка_1], [t4_КолвоДеньВДень_Заявка_1],	[t4_Колво_7_Заявка_1],
		[t4_Колво_Заявка_2], [t4_КолвоДеньВДень_Заявка_2],[t4_Колво_7_Заявка_2]
		,[t4_Колво_Заявка_3]	,[t4_КолвоДеньВДень_Заявка_3]	,[t4_Колво_7_Заявка_3]
		,[t4_Колво_Заявка_4]	,[t4_КолвоДеньВДень_Заявка_4]	,[t4_Колво_7_Заявка_4]
		,[t4_Колво_Заявка_5]	,[t4_КолвоДеньВДень_Заявка_5]	,[t4_Колво_7_Заявка_5]
		,[t4_Колво_Заявка_6]	,[t4_КолвоДеньВДень_Заявка_6]	,[t4_Колво_7_Заявка_6])
SELECT main.таблица
/*, ВходящиеЗвонкиНаумен.Колво_ВхЗв + Лиды.[t4_Колво_Лид]  as [t4_Колво] 
, ВходящиеЗвонкиНаумен.КолвоДеньВДень_ВхЗв + Лиды.[t4_КолвоДеньВДень_Лид] as [t4_КолвоДеньВДень]
, ВходящиеЗвонкиНаумен.Колво_7_ВхЗв + Лиды.[t4_Колво_7_Лид] as [t4_Колво_7]
		,ВходящиеЗвонкиНаумен.Колво_ВхЗв as [Колво_ВхЗв] ,ВходящиеЗвонкиНаумен.КолвоДеньВДень_ВхЗв as [КолвоДеньВДень_ВхЗв] ,ВходящиеЗвонкиНаумен.Колво_7_ВхЗв as [Колво_7_ВхЗв]
		,Лиды.[t4_Колво_Лид] as [t4_Колво_Лид] ,Лиды.[t4_КолвоДеньВДень_Лид] as [t4_КолвоДеньВДень_Лид] ,Лиды.[t4_Колво_7_Лид] as [t4_Колво_7_Лид] 
		*/
		,1 as [t4_Колво] ,1 as [t4_КолвоДеньВДень], 1  as [t4_Колво_7]
		,1 as [Колво_ВхЗв] ,1 as [КолвоДеньВДень_ВхЗв] ,1 as [Колво_7_ВхЗв]
		,1as [t4_Колво_Лид] ,1 as [t4_КолвоДеньВДень_Лид] ,1 as [t4_Колво_7_Лид]

		,Лиды_1.t4_Колво_Лид_1 [t4_Колво_Лид_1], Лиды_1.[t4_КолвоДеньВДень_Лид_1] [t4_КолвоДеньВДень_Лид_1] , Лиды_1.[t4_Колво_7_Лид_1]  [t4_Колво_7_Лид_1] 
		,Лиды_2.[t4_Колво_Лид_2] [t4_Колво_Лид_2], Лиды_2.[t4_КолвоДеньВДень_Лид_2] [t4_КолвоДеньВДень_Лид_2] , Лиды_2.[t4_Колво_7_Лид_2]  [t4_Колво_7_Лид_2] 
		,ЛидыУникальные.[t4_Колво_Лид_3] [t4_Колво_Лид_3], ЛидыУникальные.[t4_КолвоДеньВДень_Лид_3] [t4_КолвоДеньВДень_Лид_3] , ЛидыУникальные.[t4_Колво_7_Лид_3] [t4_Колво_7_Лид_3] 

		,ВРаботуЛиды.[t4_Колво_ВРаботу] [t4_Колво_ВРаботу] ,ВРаботуЛиды.[t4_КолвоДеньВДень_ВРаботу] [t4_КолвоДеньВДень_ВРаботу] ,ВРаботуЛиды.[t4_Колво_7_ВРаботу] [t4_Колво_7_ВРаботу]
		,ДозвонЛД.t4_Колво_Дозвон [t4_Колво_Дозвон] ,ДозвонЛД.t4_КолвоДеньВДень_Дозвон [t4_КолвоДеньВДень_Дозвон] ,ДозвонЛД.t4_Колво_7_Дозвон [t4_Колво_7_Дозвон]
		, main.колво_заявка as [Колво_Заявка] , main.колводеньвдень_заявка as [КолвоДеньВДень_Заявка] , main.колво_7_заявка as [Колво_7_Заявка] 
		, KC.колво_заявка [t4_Колво_Заявка_1], KC.колводеньвдень_заявка [t4_КолвоДеньВДень_Заявка_1],	KC.колво_7_заявка [t4_Колво_7_Заявка_1]

		, SKC.колво_заявка	[t4_Колво_Заявка_2], SKC.колводеньвдень_заявка [t4_КолвоДеньВДень_Заявка_2], SKC.колво_7_заявка [t4_Колво_7_Заявка_2]

		, LCRM.колво_заявка [t4_Колво_Заявка_3]	, LCRM.колводеньвдень_заявка [t4_КолвоДеньВДень_Заявка_3]	, LCRM.колво_7_заявка [t4_Колво_7_Заявка_3]
		, KS.колво_заявка [t4_Колво_Заявка_4]	, KS.колводеньвдень_заявка [t4_КолвоДеньВДень_Заявка_4]	, KS.колво_7_заявка [t4_Колво_7_Заявка_4]
		, PS.колво_заявка [t4_Колво_Заявка_5]	, PS.колводеньвдень_заявка [t4_КолвоДеньВДень_Заявка_5]	, PS.колво_7_заявка [t4_Колво_7_Заявка_5]
		, MP.колво_заявка [t4_Колво_Заявка_6]	, MP.колводеньвдень_заявка [t4_КолвоДеньВДень_Заявка_6]	, MP.колво_7_заявка [t4_Колво_7_Заявка_6]
FROM Таблица_строка_7 as main

--left join Таблица_Лиды_LCRM Лиды on main.таблица = Лиды.таблица
left join Таблица_Лиды_наш_КЦ Лиды_1 on main.таблица = Лиды_1.таблица
left join Таблица_Лиды_Дошедшие Лиды_2 on main.таблица = Лиды_2.таблица
left join Таблица_Уникальные_Лиды ЛидыУникальные on main.таблица = ЛидыУникальные.таблица
left join ВРаботу ВРаботуЛиды on main.таблица = ВРаботуЛиды.таблица
left join Дозвон ДозвонЛД on main.таблица = ДозвонЛД.таблица
left join Таблица_строка_7_1 KC on main.таблица = KC.таблица
left join Таблица_строка_7_2 SKC on main.таблица = SKC.таблица
left join Таблица_строка_7_3 LCRM on main.таблица = LCRM.таблица
left join Таблица_строка_7_4 KS on main.таблица = KS.таблица
left join Таблица_строка_7_5 PS on main.таблица = PS.таблица
left join Таблица_строка_7_6 MP on main.таблица = MP.таблица
left join str_2 ВходящиеЗвонкиНаумен on main.таблица = ВходящиеЗвонкиНаумен.таблица


-- заменили 4 на 5
--if @PageNo=5
--begin
--;with	
--t_RequstAsLids as
--(
--select * 
--from (select distinct N'Лид' as [Документ] ,[Ссылка] as [ДокСсылка] ,[Дата] ,[Номер] ,[Телефон] ,cast([Дата] as date) as [ПериодУчета] 
--					  ,rank() over(partition by [Телефон]  ,cast([Дата] as date) order by [Дата] desc) as [rank_L]
--	  from [Stg].[_1cCRM].[Документ_CRM_Заявка] 
--	  where [ПометкаУдаления]=0x00 and not [Статус] in (0x80E400155D64100111E7F7BA3547760F -- забраковано
--														,0xA81400155D94190011E80784923C6084 -- черновик
--														,0xB81200155D36C90711E8FD799AF2C865) -- создан из заявки на займ
--			and ([Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
--				or [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
--	  ) rl
--where rl.[rank_L]=1
--)
----	Лиды с вх.звонками

--,	TableLidsSource as
--(
--select distinct [Документ] ,[ДокСсылка] ,[Дата] ,[Номер] ,[Телефон] ,[ПериодУчета] 
--from t_RequstAsLids

--union all

--select distinct N'ВхЗвонок' as [Документ], c.[Ссылка] as [ДокСсылка] ,c.[Дата] ,c.[Номер] ,c.[АбонентКакСвязаться] as [Телефон] ,cast(c.[Дата] as date) as [ПериодУчета] 
--from [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] c
--where [Входящий]=0x01 and [ПометкаУдаления]=0x00 
--		and (c.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
--				or c.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
--		and not c.[АбонентКакСвязаться] in (select distinct c1.[АбонентКакСвязаться]
--											from (select distinct z0.[Телефон] ,c0.[АбонентКакСвязаться] 
--												  from t_RequstAsLids z0
--												  left join [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] c0
--												  on z0.[Телефон]=c0.[АбонентКакСвязаться]
--												  where (z0.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
--														or z0.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
--												  ) c1
--											where not c1.[АбонентКакСвязаться] is null)
-- )
--,	Request_cnt as
--(
--select distinct  N'Заявка' as [Документ] ,z.[Ссылка] as [ДокСсылка] ,z.[Дата] ,z.[Номер] ,z.[НомерЗаявки] as [ЗаявкаНомер] ,tz0.[Статус] ,sz.[Наименование] as [СтатусНаим] 
--		,case 
--			when not ld.[ДокСсылка] is null then ld.[ДокСсылка]
--			else cll.[Ссылка]				
--		end as [Лид]
--		--,ld.[ДокСсылка] as [ЛидСсылка] 
--		,cll.[Ссылка] as [ВхЗвонок] ,cast(z.[Дата] as date) as [ПериодУчета] ,ld.[ПериодУчета] as [ПериодУчетаЛид] ,z.[НачальнаяЗаявка] ,z.[Партнер] 
--from [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z
--	left join (select * from (select [Период] ,[Заявка] ,[Статус] ,rank() over(partition by [Заявка] order by [Период] desc) as [rank] 
--							  from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС]) tz1
--						where tz1.[rank]=1 and not [Статус] in (0xB81500155D4D107811E9978BEDF95571	-- черновик из ЛК
--															  ,0xA81400155D94190011E80784923C60A7 	-- черновик
--															  ,0x80E400155D64100111E7BC9ADD36AB53 	-- забраковано
--															  ,0xB81200155D36C90711E8FD799AF2C865) -- создан из заявки на займ
--			   ) tz0											  
--	on z.[Ссылка]=tz0.[Заявка]
--	left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] sz
--	on tz0.[Статус]=sz.[Ссылка]
--	left join (select * from [Stg].[_1cCRM].[Документ_ТелефонныйЗвонок] where [Входящий]=0x01) cll
--	on z.[МобильныйТелефон]=cll.[АбонентКакСвязаться] and cast(z.[Дата] as date)=cast(cll.[Дата] as date)
--	left join (select distinct * from TableLidsSource) ld
--	on z.[МобильныйТелефон]=ld.[Телефон] and cast(z.[Дата] as date)=cast(ld.[Дата] as date)
--where z.[ПометкаУдаления]=0x00 and not tz0.[Статус] is null
--	  and (z.[Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
--	   or z.[Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
---- order by z.[Дата] asc 
--)
-------- ВЫВОДИМ СТРОКИ
----,	
--str_1 as
--(
-------- колво всего вх.звонков и лидов
--select s11.[Таблица] ,s11.[КолвоДеньВДень] ,s11.[Колво] ,s13.[Колво_7]
--from (select N'table_4' as [Таблица], N'Колво_лидов_шт_Всего' as [Показатель] ,count([ДокСсылка]) as [Колво] ,count([ДокСсылка]) as [КолвоДеньВДень] ,[ПериодУчета] 
--	  from #TableLidsSource 
--	  where [ПериодУчета]=cast(@GetDate2000 as date) group by [ПериодУчета]) s11
--left join (select N'table_4' as [Таблица], N'Колво_лидов_шт_Всего' as [Показатель] ,count([ДокСсылка]) as [Колво_7] ,[ПериодУчета] 
--			from #TableLidsSource where [ПериодУчета] = cast(dateadd(day,-7,@GetDate2000) as date)
--			group by [ПериодУчета]) s13
--on  s11.[Таблица]=s13.[Таблица]

--)
----select * from str_1
--,	str_2 as
--(
-------- колво вх.звонков
--select s21.[Таблица] ,s21.[Колво_ВхЗв] ,s21.[КолвоДеньВДень_ВхЗв] ,s23.[Колво_7_ВхЗв]
--from (select N'table_4' as [Таблица], N'Колво_лидов_шт_ВхЗвонки' as [Показатель] ,count([ДокСсылка]) as [Колво_ВхЗв] ,count([ДокСсылка]) as [КолвоДеньВДень_ВхЗв] ,[ПериодУчета] 
--		   from #TableLidsSource where [Документ]=N'ВхЗвонок' and [ПериодУчета]=cast(@GetDate2000 as date) group by [ПериодУчета]) s21

--left join (select N'table_4' as [Таблица], N'Колво_лидов_шт_ВхЗвонки' as [Показатель] ,count([ДокСсылка]) as [Колво_7_ВхЗв] ,[ПериодУчета] 
--			from #TableLidsSource where [Документ]=N'ВхЗвонок' and [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date) group by [ПериодУчета]) s23
--on  s21.[Таблица]=s23.[Таблица]
--)
----select * from str_2
--,	str_3 as
--(
-------- колво лидов
--select s31.[Таблица] ,s31.[Колво_Лид] ,s31.[КолвоДеньВДень_Лид] ,s33.[Колво_7_Лид]
--from (select N'table_4' as [Таблица], N'Колво_лидов_шт_Лиды' as [Показатель] ,count([ДокСсылка]) as [Колво_Лид] ,count([ДокСсылка]) as [КолвоДеньВДень_Лид] ,[ПериодУчета] 
--		   from #TableLidsSource where [Документ]=N'Лид' and [ПериодУчета]=cast(@GetDate2000 as date) group by [ПериодУчета]) s31

--left join (select N'table_4' as [Таблица], N'Колво_лидов_шт_Лиды' as [Показатель] ,count([ДокСсылка]) as [Колво_7_Лид] ,[ПериодУчета] 
--			from #TableLidsSource where [Документ]=N'Лид' and [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date) group by [ПериодУчета]) s33
--on  s31.[Таблица]=s33.[Таблица]
--)

--,	str_7 as
--(
-------- колво заявки ПТС
--select s71.[Таблица] ,s71.[Колво_Заявка] ,s72.[КолвоДеньВДень_Заявка] ,s73.[Колво_7_Заявка]

--from (select N'table_4' as [Таблица], N'Колво_Заявок_шт' as [Показатель] ,count([ДокСсылка]) as [Колво_Заявка] ,[ПериодУчета] 
--		   from #Request_cnt where [Документ]=N'Заявка' and [ПериодУчета]=cast(@GetDate2000 as date) group by [ПериодУчета]) s71

--left join (select N'table_4' as [Таблица], N'Колво_Заявок_шт' as [Показатель] ,count([ДокСсылка]) as [КолвоДеньВДень_Заявка] ,[ПериодУчета] 
--			from #Request_cnt where [Документ]=N'Заявка' and [ПериодУчета]=[ПериодУчетаЛИД] 
--								and [Дата] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000 
--			group by [ПериодУчета]) s72
--on  s71.[Таблица]=s72.[Таблица]
--left join (select N'table_4' as [Таблица], N'Колво_Заявок_шт' as [Показатель] ,count([ДокСсылка]) as [Колво_7_Заявка] ,[ПериодУчета] 
--			from #Request_cnt where [Документ]=N'Заявка' and [ПериодУчета]=[ПериодУчетаЛИД] and [Дата] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)  
--			group by [ПериодУчета]) s73
--on  s71.[Таблица]=s73.[Таблица]
--)
-- select * from str_7
--,	res as
--(

--insert into #t4 ([t4_Таблица] ,[t4_Колво]  ,[t4_КолвоДеньВДень] ,[t4_Колво_7] 
--		,[t4_Колво_ВхЗв] ,[t4_КолвоДеньВДень_ВхЗв] ,[t4_Колво_7_ВхЗв]
--		,[t4_Колво_Лид] ,[t4_КолвоДеньВДень_Лид] ,[t4_Колво_7_Лид] 
--		,[t4_Колво_Заявка] ,[t4_КолвоДеньВДень_Заявка] ,[t4_Колво_7_Заявка] )
--select str_1.[Таблица] ,isnull(str_1.[Колво],0) as [Колво]  ,isnull(str_1.[КолвоДеньВДень],0) as [КолвоДеньВДень] ,isnull(str_1.[Колво_7],0) as [Колво_7] 
--		,isnull(str_2.[Колво_ВхЗв],0) as [Колво_ВхЗв] ,isnull(str_2.[КолвоДеньВДень_ВхЗв],0) as [КолвоДеньВДень_ВхЗв] ,isnull(str_2.[Колво_7_ВхЗв],0) as [Колво_7_ВхЗв]
--		,isnull(str_3.[Колво_Лид],0) as [Колво_Лид] ,isnull(str_3.[КолвоДеньВДень_Лид],0) as [КолвоДеньВДень_Лид] ,isnull(str_3.[Колво_7_Лид],0) as [Колво_7_Лид] 
--		,isnull(str_7.[Колво_Заявка],0) as [Колво_Заявка] ,isnull(str_7.[КолвоДеньВДень_Заявка],0) as [КолвоДеньВДень_Заявка] ,isnull(str_7.[Колво_7_Заявка],0) as [Колво_7_Заявка] 
--from str_1
--left join str_2 on str_1.[Таблица]=str_2.[Таблица]
--left join str_3 on str_1.[Таблица]=str_3.[Таблица]
--left join str_7 on str_1.[Таблица]=str_7.[Таблица]
--)
--select * from res
--end



/*
[Таблица] ,[КолвоПО] ,[КолвоДеньВДеньПО] ,[КолвоДеньВДень7ПО]
		,[КолвоКД] ,[КолвоДеньВДеньКД] ,[КолвоДеньВДень7КД]
		,[КолвоВН] ,[КолвоДеньВДеньВН] ,[КолвоДеньВДень7ВН]
		,[КолвоВНПарт] ,[КолвоДеньВДеньВНПарт] ,[КолвоДеньВДень7ВНПарт]
		,[КолвоВНВМ] ,[КолвоДеньВДеньВНВМ] ,[КолвоДеньВДень7ВНВМ]
		,[КолвоВДК] ,[КолвоДеньВДеньВДК] ,[КолвоДеньВДень7ВДК]
		,[КолвоОДК] ,[КолвоДеньВДеньОДК] ,[КолвоДеньВДень7ОДК] 
		,[КолвоВД] ,[КолвоДеньВДеньВД] ,[КолвоДеньВДень7ВД]
		,[КолвоОд] ,[КолвоДеньВДеньОд] ,[КолвоДеньВДень7Од]
		,[КолвоДП] ,[КолвоДеньВДеньДП] ,[КолвоДеньВДень7ДП]
		,[КолвоЗВ] ,[КолвоДеньВДеньЗВ] ,[КолвоДеньВДень7ЗВ] 
		*/

if OBJECT_ID('tempdb.dbo.#t5') is not null
drop table dbo.#t5;

CREATE TABLE #t5(

	[t5_Таблица] nvarchar(255) NULL,
	[t5_КолвоПО] numeric (15) null,
	[t5_КолвоДеньВДеньПО] numeric (15) null,
	[t5_КолвоДеньВДень7ПО] numeric (15) null,
	[t5_КолвоКД] numeric (15) null,
	[t5_КолвоДеньВДеньКД] numeric (15) null,
	[t5_КолвоДеньВДень7КД] numeric (15) null,
	[t5_КолвоКД_2] numeric (15) null,
	[t5_КолвоДеньВДеньКД_2] numeric (15) null,
	[t5_КолвоДеньВДень7КД_2] numeric (15) null,
	[t5_КолвоВН] numeric (15) null,
	[t5_КолвоДеньВДеньВН] numeric (15) null,
	[t5_КолвоДеньВДень7ВН] numeric (15) null,
	[t5_КолвоВНПарт] numeric (15) null,
	[t5_КолвоДеньВДеньВНПарт] numeric (15) null,
	[t5_КолвоДеньВДень7ВНПарт]	numeric (15) null,
	[t5_КолвоВНВМ] numeric (15) null,
	[t5_КолвоДеньВДеньВНВМ] numeric (15) null,
	[t5_КолвоДеньВДень7ВНВМ]numeric (15) null,
	[t5_КолвоВДК] numeric (15) null,
	[t5_КолвоДеньВДеньВДК] numeric (15) null,
	[t5_КолвоДеньВДень7ВДК] numeric (15) null,
	[t5_КолвоОДК] numeric (15) null,
	[t5_КолвоДеньВДеньОДК] numeric (15) null,
	[t5_КолвоДеньВДень7ОДК] numeric (15) null,
	[t5_КолвоВД] numeric (15) null,
	[t5_КолвоДеньВДеньВД] numeric (15) null,
	[t5_КолвоДеньВДень7ВД]	numeric (15) null,
	[t5_КолвоОд] numeric (15) null,
	[t5_КолвоДеньВДеньОд] numeric (15) null,
	[t5_КолвоДеньВДень7Од]	numeric (15) null,
	[t5_КолвоДП] numeric (15) null,
	[t5_КолвоДеньВДеньДП] numeric (15) null,
	[t5_КолвоДеньВДень7ДП]	numeric (15) null,
	[t5_КолвоЗВ] numeric (15) null,
	[t5_КолвоДеньВДеньЗВ] numeric (15) null,
	[t5_КолвоДеньВДень7ЗВ] numeric (15) null
);

--if @PageNo=5	-- ПЯТАЯ И ШЕСТАЯ таблица
--begin
with
-- Таблица по статусам
	tablet as		
(
select N'table_3_table_5' as [Таблица] ,[СтатусНаим_След] as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum([Колво]) as [Колво] ,sum([СуммаЗаявки]) as [СуммаЗаявки] ,sum([КолвоДеньВДеньЗайм]) as [КолвоДеньВДень] ,sum([СуммаДеньВДеньЗайм]) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] in (N'Предварительное одобрение' ,N'Встреча назначена' , /*N'Контроль данных' ,*/N'Верификация документов клиента' 
							,N'Одобрены документы клиента' ,N'Верификация документов' ,N'Одобрено' ,N'Договор подписан')
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
and [СпособОформления]<>N'Оформление в мобильном приложении'
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)
-- встреча назначена на партнера
,	tablet_meet as		
(
select N'table_3_table_5' as [Таблица] ,N'ВстречаПарт' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Встреча назначена'
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]<>N'Оформление в мобильном приложении'
and [ТочкаВМ] is null
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)

-- Таблица по выданным займам
,	table_1 as
(
select	[СтатусНаим_След] as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] 
	  ,sum([Колво]) as [Колво] ,sum([СуммаЗаявки]) as [СуммаЗаявки]
	  ,sum([КолвоДеньВДеньЗайм]) as [КолвоДеньВДень] ,sum([СуммаДеньВДеньЗайм]) as [СуммаДеньВДень]

from #t_source
where [СтатусНаим_След]=N'Заем выдан' --and cast([ДатаЗаявки] as date)=cast(getdate() as date) an
	  and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ДатаСтатусаСлед] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
and [СпособОформления]<>N'Оформление в мобильном приложении'

and НомерЗаявки in (Select ДоговорНомер from  [dbo].[report_Agreement_InterestRate])
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)


-- добавим условие по статусу контроль данных
-- Требование ТЗ: заявок, получавших статус «контроль данных» в заданном временной срезе (из тех, которые были в статусе «Встреча назначена»).
,	tablet_controldata as		
(
select N'table_3_table_5' as [Таблица] ,N'Контроль данных' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Контроль данных' --- Это для долей and [СтатусНаим_Исх] =N'Встреча назначена'
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]<>N'Оформление в мобильном приложении'
--and [ТочкаВМ] is null
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)
-- добавим условие по статусу контроль данных
-- Требование ТЗ: заявок, получавших статус «контроль данных» в заданном временной срезе (из тех, которые были в статусе «Встреча назначена»).
-- Теперь и для долей
,	tablet_controldata_dolya as		
(
select N'table_3_table_5' as [Таблица] ,N'Контроль данных Доля' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Контроль данных' and [СтатусНаим_Исх] =N'Встреча назначена'
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]<>N'Оформление в мобильном приложении'
--and [ТочкаВМ] is null
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)



----	Таблица итоговая по статусам
,	table_1_end2 as
(
select N'table5' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table5' as [Таблица] ,N'Заем выдан' as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from table_1 where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from table_1 where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table5' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_meet where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_meet where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table5' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table5' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata_dolya where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata_dolya where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]
)

insert into #t5 ([t5_Таблица] ,[t5_КолвоПО] ,[t5_КолвоДеньВДеньПО] ,[t5_КолвоДеньВДень7ПО]
		,[t5_КолвоКД] ,[t5_КолвоДеньВДеньКД] ,[t5_КолвоДеньВДень7КД]
		,[t5_КолвоКД_2] ,[t5_КолвоДеньВДеньКД_2] ,[t5_КолвоДеньВДень7КД_2]
		,[t5_КолвоВН] ,[t5_КолвоДеньВДеньВН] ,[t5_КолвоДеньВДень7ВН]
		,[t5_КолвоВНПарт] ,[t5_КолвоДеньВДеньВНПарт] ,[t5_КолвоДеньВДень7ВНПарт]
		,[t5_КолвоВНВМ] ,[t5_КолвоДеньВДеньВНВМ] ,[t5_КолвоДеньВДень7ВНВМ]
		,[t5_КолвоВДК] ,[t5_КолвоДеньВДеньВДК] ,[t5_КолвоДеньВДень7ВДК]
		,[t5_КолвоОДК] ,[t5_КолвоДеньВДеньОДК] ,[t5_КолвоДеньВДень7ОДК] 
		,[t5_КолвоВД] ,[t5_КолвоДеньВДеньВД] ,[t5_КолвоДеньВДень7ВД]
		,[t5_КолвоОд] ,[t5_КолвоДеньВДеньОд] ,[t5_КолвоДеньВДень7Од]
		,[t5_КолвоДП] ,[t5_КолвоДеньВДеньДП] ,[t5_КолвоДеньВДень7ДП]
		,[t5_КолвоЗВ] ,[t5_КолвоДеньВДеньЗВ] ,[t5_КолвоДеньВДень7ЗВ] )

select  a11.[Таблица] ,[КолвоПО] ,[КолвоДеньВДеньПО] ,[КолвоДеньВДень7ПО]
		,[КолвоКД] ,[КолвоДеньВДеньКД] ,[КолвоДеньВДень7КД]
		,[КолвоКД_2] ,[КолвоДеньВДеньКД_2] ,[КолвоДеньВДень7КД_2]
		,[КолвоВН] ,[КолвоДеньВДеньВН] ,[КолвоДеньВДень7ВН]
		,[КолвоВНПарт] ,[КолвоДеньВДеньВНПарт] ,[КолвоДеньВДень7ВНПарт]
		,[КолвоВН]-[КолвоВНПарт] as [КолвоВНВМ] ,[КолвоДеньВДеньВН] - [КолвоДеньВДеньВНПарт] as [КолвоДеньВДеньВНВМ] ,[КолвоДеньВДень7ВН]-[КолвоДеньВДень7ВНПарт] as [КолвоДеньВДень7ВНВМ]
		,[КолвоВДК] ,[КолвоДеньВДеньВДК] ,[КолвоДеньВДень7ВДК]
		,[КолвоОДК] ,[КолвоДеньВДеньОДК] ,[КолвоДеньВДень7ОДК] 
		,[КолвоВД] ,[КолвоДеньВДеньВД] ,[КолвоДеньВДень7ВД]
		,[КолвоОд] ,[КолвоДеньВДеньОд] ,[КолвоДеньВДень7Од]
		,[КолвоДП] ,[КолвоДеньВДеньДП] ,[КолвоДеньВДень7ДП]
		,[КолвоЗВ] ,[КолвоДеньВДеньЗВ] ,[КолвоДеньВДень7ЗВ] 

from (select distinct [Таблица] from table_1_end2) a11
left join (select [Таблица] ,[Колво] as [КолвоПО] ,[КолвоДеньВДень] as [КолвоДеньВДеньПО] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ПО] 
	  from table_1_end2
	  where [Показатель] = N'Предварительное одобрение') po
on a11.[Таблица]=po.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВН] ,[КолвоДеньВДень] as [КолвоДеньВДеньВН] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВН] 
			from table_1_end2 
			where [Показатель] = N'Встреча назначена') vn
on a11.[Таблица]=vn.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВНПарт] ,[КолвоДеньВДень] as [КолвоДеньВДеньВНПарт] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВНПарт] 
			from table_1_end2 
			where [Показатель] = N'ВстречаПарт') vnPr
on a11.[Таблица]=vn.[Таблица]

left join (select [Таблица] ,[Колво] as [КолвоКД], [КолвоДеньВДень] as [КолвоДеньВДеньКД] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7КД] 
			from table_1_end2 
			where [Показатель] = N'Контроль данных') kd
on a11.[Таблица]=kd.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоКД_2], [КолвоДеньВДень] as [КолвоДеньВДеньКД_2] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7КД_2] 
			from table_1_end2 
			where [Показатель] = N'Контроль данных Доля') kd_d
on a11.[Таблица]=kd_d.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВДК], [КолвоДеньВДень] as [КолвоДеньВДеньВДК] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВДК] 
			from table_1_end2 
			where [Показатель] = N'Верификация документов клиента') vdk
on a11.[Таблица]=vdk.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоОДК], [КолвоДеньВДень] as [КолвоДеньВДеньОДК] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ОДК] 
			from table_1_end2 
			where [Показатель] = N'Одобрены документы клиента') odk
on a11.[Таблица]=odk.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВД], [КолвоДеньВДень] as [КолвоДеньВДеньВД] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВД] 
			from table_1_end2 
			where [Показатель] = N'Верификация документов') vd
on a11.[Таблица]=vd.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоОд], [КолвоДеньВДень] as [КолвоДеньВДеньОд] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7Од] 
			from table_1_end2 
			where [Показатель] = N'Одобрено') od
on a11.[Таблица]=od.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоДП], [КолвоДеньВДень] as [КолвоДеньВДеньДП] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ДП] 
			from table_1_end2 
			where [Показатель] = N'Договор подписан') dp
on a11.[Таблица]=dp.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоЗВ], [КолвоДеньВДень] as [КолвоДеньВДеньЗВ] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ЗВ] 
			from table_1_end2 
			where [Показатель] = N'Заем выдан') zv
on a11.[Таблица]=zv.[Таблица]


--==========================================================
/*                создаем таблицу 5.1                     */
--==========================================================

if OBJECT_ID('tempdb.dbo.#t51') is not null
drop table dbo.#t51;

CREATE TABLE #t51(

	[t51_Таблица] nvarchar(255) NULL,
	[t51_КолвоПО] numeric (15) null,
	[t51_КолвоДеньВДеньПО] numeric (15) null,
	[t51_КолвоДеньВДень7ПО] numeric (15) null,
	[t51_КолвоКД] numeric (15) null,
	[t51_КолвоДеньВДеньКД] numeric (15) null,
	[t51_КолвоДеньВДень7КД] numeric (15) null,
	[t51_КолвоВН] numeric (15) null,
	[t51_КолвоДеньВДеньВН] numeric (15) null,
	[t51_КолвоДеньВДень7ВН] numeric (15) null,
	[t51_КолвоВНПарт] numeric (15) null,
	[t51_КолвоДеньВДеньВНПарт] numeric (15) null,
	[t51_КолвоДеньВДень7ВНПарт]	numeric (15) null,
	[t51_КолвоВНВМ] numeric (15) null,
	[t51_КолвоДеньВДеньВНВМ] numeric (15) null,
	[t51_КолвоДеньВДень7ВНВМ]numeric (15) null,
	[t51_КолвоВДК] numeric (15) null,
	[t51_КолвоДеньВДеньВДК] numeric (15) null,
	[t51_КолвоДеньВДень7ВДК] numeric (15) null,
	[t51_КолвоОДК] numeric (15) null,
	[t51_КолвоДеньВДеньОДК] numeric (15) null,
	[t51_КолвоДеньВДень7ОДК] numeric (15) null,
	[t51_КолвоВД] numeric (15) null,
	[t51_КолвоДеньВДеньВД] numeric (15) null,
	[t51_КолвоДеньВДень7ВД]	numeric (15) null,
	[t51_КолвоОд] numeric (15) null,
	[t51_КолвоДеньВДеньОд] numeric (15) null,
	[t51_КолвоДеньВДень7Од]	numeric (15) null,
	[t51_КолвоДП] numeric (15) null,
	[t51_КолвоДеньВДеньДП] numeric (15) null,
	[t51_КолвоДеньВДень7ДП]	numeric (15) null,
	[t51_КолвоДП_ПЭП] numeric (15) null,
	[t51_КолвоДеньВДеньДП_ПЭП] numeric (15) null,
	[t51_КолвоДеньВДень7ДП_ПЭП] numeric (15) null,
	[t51_КолвоДП_НЕ_ПЭП] numeric (15) null,
	[t51_КолвоДеньВДеньДП_НЕ_ПЭП] numeric (15) null,
	[t51_КолвоДеньВДень7ДП_НЕ_ПЭП] numeric (15) null,
	[t51_КолвоЗВ] numeric (15) null,
	[t51_КолвоДеньВДеньЗВ] numeric (15) null,
	[t51_КолвоДеньВДень7ЗВ] numeric (15) null
);

--if @PageNo=51	-- ПЯТАЯ.ОДИН И ШЕСТАЯ таблица
--begin
with
-- Таблица по статусам
	tablet as		
(
select N'table_3_table_51' as [Таблица] ,[СтатусНаим_След] as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum([Колво]) as [Колво] ,sum([СуммаЗаявки]) as [СуммаЗаявки] ,sum([КолвоДеньВДеньЗайм]) as [КолвоДеньВДень] ,sum([СуммаДеньВДеньЗайм]) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] in (N'Предварительное одобрение' ,/*N'Встреча назначена' , */ N'Контроль данных' ,N'Верификация документов клиента' 
							,N'Одобрены документы клиента' ,N'Верификация документов' ,N'Одобрено' ,N'Договор подписан')
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
and [СпособОформления]=N'Оформление в мобильном приложении'
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)



		-- Таблица по выданным займам
,	table_1 as
(
select	[СтатусНаим_След] as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] 
	  ,sum([Колво]) as [Колво] ,sum([СуммаЗаявки]) as [СуммаЗаявки]
	  ,sum([КолвоДеньВДеньЗайм]) as [КолвоДеньВДень] ,sum([СуммаДеньВДеньЗайм]) as [СуммаДеньВДень]

from #t_source
where [СтатусНаим_След]=N'Заем выдан' --and cast([ДатаЗаявки] as date)=cast(getdate() as date) an
	  and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ДатаСтатусаСлед] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
and [СпособОформления]=N'Оформление в мобильном приложении'
and НомерЗаявки in (Select ДоговорНомер from  [dbo].[report_Agreement_InterestRate])
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)

-- встреча назначена на партнера
-- для таблицы 5.1 дополнительное условие: + колво заявок по которым не назначено встреч, но они перешли в статус "Контроль данных"
,	tablet_meet_partner as		
(
select N'table_3_table_51' as [Таблица] ,N'ВстречаПарт' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Встреча назначена'
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]=N'Оформление в мобильном приложении'
and [ТочкаВМ] is null
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)
-- добавим условие по статусу контроль данных
-- колво заявок по которым не назначено встреч, но они перешли в статус "Контроль данных"
,	tablet_controldata_no_meet_partner as		
(
select N'table_3_table_51' as [Таблица] ,N'Контроль данных без назначения встречи Партнер' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Контроль данных' and [СтатусНаим_Исх] <>N'Встреча назначена'
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]=N'Оформление в мобильном приложении'
and [ТочкаВМ] is null
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)
,	

-- встреча назначена на Выездного менеджера
 tablet_meet_vm as		
(
select N'table_3_table_51' as [Таблица] ,N'ВстречаВыезднойМенеджер' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Встреча назначена'
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]=N'Оформление в мобильном приложении'
and [ТочкаВМ] is not null
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)
-- Встречи не назначено, но перешли в контроль данных
,	tablet_controldata_no_meet_vm as		
(

select N'table_3_table_51' as [Таблица] ,N'Контроль данных без ВНВМ' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Контроль данных' and [СтатусНаим_Исх] <>N'Встреча назначена'
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]=N'Оформление в мобильном приложении'
and [ТочкаВМ] is not null
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)
-- ПЭП
,	tablet_dp_pep as		
(
select N'table_3_table_51' as [Таблица] ,N'Договор подписан ПЭП' as [Показатель]
	  ,[ПериодУчетаЗайм] as [ПериодУчета] --,[ДатаЗаявки] ,[ДатаСтатуса] --,[СтатусНаим_Исх] 
	  ,sum(isnull([Колво],0)) as [Колво] ,sum(isnull([СуммаЗаявки],0)) as [СуммаЗаявки] ,sum(isnull([КолвоДеньВДеньЗайм],0)) as [КолвоДеньВДень] ,sum(isnull([СуммаДеньВДеньЗайм],0)) as [СуммаДеньВДень]
from #t_source
where [СтатусНаим_След] =N'Договор подписан' 
		and ([ДатаСтатусаСлед] between dateadd(day,-7,dateadd(day,datediff(day,0,@GetDate2000),0)) and dateadd(day,-7,@GetDate2000)
								or [ПериодУчетаЗайм] between dateadd(day,0,dateadd(day,datediff(day,0,@GetDate2000),0)) and @GetDate2000)
		--and [ВыезднойМенеджер] is Null
and [СпособОформления]=N'Оформление в мобильном приложении'
and [ПЭП] = '8999'
group by [СтатусНаим_След] ,[ПериодУчетаЗайм]
)

----		Таблица итоговая по статусам
,	table_1_end2 as
(
select N'table51' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table51' as [Таблица] ,N'Заем выдан' as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from table_1 where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from table_1 where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table51' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_meet_partner where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_meet_partner where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table51' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_meet_vm where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_meet_vm where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table51' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata_no_meet_partner where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata_no_meet_partner where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table51' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata_no_meet_vm where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_controldata_no_meet_vm where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

union all

select N'table51' as [Таблица] ,t1t.[Показатель] as [Показатель] ,t1t.[Колво] , t1t.[КолвоДеньВДень] ,t2t.[КолвоДеньВДень] as [КолвоДеньВДень_7]
from (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_dp_pep where [ПериодУчета]=cast(@GetDate2000 as date)) t1t
left join (select [Показатель] ,[ПериодУчета] ,[Колво] ,[КолвоДеньВДень] from tablet_dp_pep where [ПериодУчета]=cast(dateadd(day,-7,@GetDate2000) as date)) t2t
on t1t.[Показатель]=t2t.[Показатель]

)



insert into #t51 ([t51_Таблица] 
        ,[t51_КолвоПО] ,[t51_КолвоДеньВДеньПО] ,[t51_КолвоДеньВДень7ПО]
		,[t51_КолвоКД] ,[t51_КолвоДеньВДеньКД] ,[t51_КолвоДеньВДень7КД]
		,[t51_КолвоВН] ,[t51_КолвоДеньВДеньВН] ,[t51_КолвоДеньВДень7ВН]  -- Встреча назначена

		,[t51_КолвоВНПарт] ,[t51_КолвоДеньВДеньВНПарт] ,[t51_КолвоДеньВДень7ВНПарт] -- Встреча назначена + Встреча не назначен, а сразу контроль данных

		,[t51_КолвоВНВМ] ,[t51_КолвоДеньВДеньВНВМ] ,[t51_КолвоДеньВДень7ВНВМ] -- Аналогично партнер
		,[t51_КолвоВДК] ,[t51_КолвоДеньВДеньВДК] ,[t51_КолвоДеньВДень7ВДК]
		,[t51_КолвоОДК] ,[t51_КолвоДеньВДеньОДК] ,[t51_КолвоДеньВДень7ОДК] 
		,[t51_КолвоВД] ,[t51_КолвоДеньВДеньВД] ,[t51_КолвоДеньВДень7ВД]
		,[t51_КолвоОд] ,[t51_КолвоДеньВДеньОд] ,[t51_КолвоДеньВДень7Од]
		,[t51_КолвоДП] ,[t51_КолвоДеньВДеньДП] ,[t51_КолвоДеньВДень7ДП]
		,[t51_КолвоДП_ПЭП] ,[t51_КолвоДеньВДеньДП_ПЭП] ,[t51_КолвоДеньВДень7ДП_ПЭП]
		,[t51_КолвоДП_НЕ_ПЭП] ,[t51_КолвоДеньВДеньДП_НЕ_ПЭП] ,[t51_КолвоДеньВДень7ДП_НЕ_ПЭП]
		,[t51_КолвоЗВ] ,[t51_КолвоДеньВДеньЗВ] ,[t51_КолвоДеньВДень7ЗВ] )

select  a11.[Таблица] 
		,[КолвоПО] ,[КолвоДеньВДеньПО] ,[КолвоДеньВДень7ПО]
		,[КолвоКД] ,[КолвоДеньВДеньКД] ,[КолвоДеньВДень7КД]

		-- Встреча назначена
		,[КолвоВНПарт] + [КолвоКДбезВНПарт] + isnull([КолвоВНВМ],0) + isnull([КолвоКДбезВНВМ],0) [КолвоВН] ,
		[КолвоДеньВДеньВНПарт] + [КолвоДеньВДеньКДбезВНПарт] + isnull([КолвоДеньВДеньВНВМ],0) + isnull([КолвоДеньВДеньКДбезВНВМ],0) [КолвоДеньВДеньВН] ,
		[КолвоДеньВДень7ВНПарт] + [КолвоДеньВДень7КДбезВНПарт] + isnull([КолвоДеньВДень7ВНВМ],0) + isnull([КолвоДеньВДень7КДбезВНВМ],0) [КолвоДеньВДень7ВН]

		
		-- Встреча назначена + КД без ВН (Партнер)
		
		,[КолвоВНПарт] + [КолвоКДбезВНПарт] as [КолвоВНПарт] ,
		[КолвоДеньВДеньВНПарт] + [КолвоДеньВДеньКДбезВНПарт] as [КолвоДеньВДеньВНПарт] ,
		[КолвоДеньВДень7ВНПарт] + [КолвоДеньВДень7КДбезВНПарт]  as [КолвоДеньВДень7ВНПарт]


		-- Встреча назначена + КД без ВН (Выезной менеджер)
		,[КолвоВНВМ] + [КолвоКДбезВНВМ] as [КолвоВНВМ] ,
		[КолвоДеньВДеньВНВМ] + [КолвоДеньВДеньКДбезВНВМ] as [КолвоДеньВДеньВНВМ] ,
		[КолвоДеньВДень7ВНВМ] + [КолвоДеньВДень7КДбезВНВМ] as [КолвоДеньВДень7ВНВМ]

		,[КолвоВДК] ,[КолвоДеньВДеньВДК] ,[КолвоДеньВДень7ВДК]
		,[КолвоОДК] ,[КолвоДеньВДеньОДК] ,[КолвоДеньВДень7ОДК] 
		,[КолвоВД] ,[КолвоДеньВДеньВД] ,[КолвоДеньВДень7ВД]
		,[КолвоОд] ,[КолвоДеньВДеньОд] ,[КолвоДеньВДень7Од]
		,[КолвоДП] ,[КолвоДеньВДеньДП] ,[КолвоДеньВДень7ДП]
		,[КолвоДП_ПЭП] ,[КолвоДеньВДеньДП_ПЭП] ,[КолвоДеньВДень7ДП_ПЭП]
		,[КолвоДП] -[КолвоДП_ПЭП] as [t51_КолвоДП_НЕ_ПЭП] , [КолвоДеньВДеньДП] - [КолвоДеньВДеньДП_ПЭП] as [t51_КолвоДеньВДеньДП_НЕ_ПЭП] , [КолвоДеньВДень7ДП] -  [КолвоДеньВДень7ДП_ПЭП] as [t51_КолвоДеньВДень7ДП_НЕ_ПЭП]
		,[КолвоЗВ] ,[КолвоДеньВДеньЗВ] ,[КолвоДеньВДень7ЗВ] 

from (select distinct [Таблица] from table_1_end2) a11
left join (select [Таблица] ,[Колво] as [КолвоПО] ,[КолвоДеньВДень] as [КолвоДеньВДеньПО] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ПО] 
	  from table_1_end2
	  where [Показатель] = N'Предварительное одобрение') po
on a11.[Таблица]=po.[Таблица]
--left join (select [Таблица] ,[Колво] as [КолвоВН] ,[КолвоДеньВДень] as [КолвоДеньВДеньВН] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВН] 
--			from table_1_end2 
--			where [Показатель] = N'Встреча назначена') vn
--on a11.[Таблица]=vn.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВНПарт] ,[КолвоДеньВДень] as [КолвоДеньВДеньВНПарт] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВНПарт] 
			from table_1_end2 
			where [Показатель] = N'ВстречаПарт') vnPr
on a11.[Таблица]=vnPr.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоКДбезВНПарт] ,[КолвоДеньВДень] as [КолвоДеньВДеньКДбезВНПарт] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7КДбезВНПарт] 
			from table_1_end2 
			where [Показатель] = N'Контроль данных без назначения встречи Партнер') KDwoVNPartner
on a11.[Таблица]=KDwoVNPartner.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВНВМ] ,[КолвоДеньВДень] as [КолвоДеньВДеньВНВМ] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВНВМ] 
			from table_1_end2 
			where [Показатель] = N'ВстречаВыезднойМенеджер') vnVM
on a11.[Таблица]=vnVM.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоКДбезВНВМ] ,[КолвоДеньВДень] as [КолвоДеньВДеньКДбезВНВМ] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7КДбезВНВМ] 
			from table_1_end2 
			where [Показатель] = N'Контроль данных без ВНВМ') KDwoVNVM
on a11.[Таблица]=KDwoVNVM.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоКД], [КолвоДеньВДень] as [КолвоДеньВДеньКД] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7КД] 
			from table_1_end2 
			where [Показатель] = N'Контроль данных') kd
on a11.[Таблица]=kd.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВДК], [КолвоДеньВДень] as [КолвоДеньВДеньВДК] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВДК] 
			from table_1_end2 
			where [Показатель] = N'Верификация документов клиента') vdk
on a11.[Таблица]=vdk.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоОДК], [КолвоДеньВДень] as [КолвоДеньВДеньОДК] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ОДК] 
			from table_1_end2 
			where [Показатель] = N'Одобрены документы клиента') odk
on a11.[Таблица]=odk.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоВД], [КолвоДеньВДень] as [КолвоДеньВДеньВД] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ВД] 
			from table_1_end2 
			where [Показатель] = N'Верификация документов') vd
on a11.[Таблица]=vd.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоОд], [КолвоДеньВДень] as [КолвоДеньВДеньОд] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7Од] 
			from table_1_end2 
			where [Показатель] = N'Одобрено') od
on a11.[Таблица]=od.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоДП], [КолвоДеньВДень] as [КолвоДеньВДеньДП] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ДП] 
			from table_1_end2 
			where [Показатель] = N'Договор подписан') dp
on a11.[Таблица]=dp.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоДП_ПЭП], [КолвоДеньВДень] as [КолвоДеньВДеньДП_ПЭП] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ДП_ПЭП] 
			from table_1_end2 
			where [Показатель] = N'Договор подписан ПЭП') dp_pep
on a11.[Таблица]=dp_pep.[Таблица]
left join (select [Таблица] ,[Колво] as [КолвоЗВ], [КолвоДеньВДень] as [КолвоДеньВДеньЗВ] ,[КолвоДеньВДень_7] as [КолвоДеньВДень7ЗВ] 
			from table_1_end2 
			where [Показатель] = N'Заем выдан') zv
on a11.[Таблица]=zv.[Таблица]



/*
Select * from #t1
Select * from #t2
Select * from #t3
Select * from #t4
Select * from #t5
Select * from #t51
Select * from #t_source
*/


-- обновляем данные
delete from [dbo].[dm_dashboard_ConmmonTable]



--insert into [dbo].[dm_dashboard_ConmmonTable] ([ДатаОбновления] , id, [t1_Таблица]
--		,[t1_Колво] ,[t1_КолвоДеньВДень] ,[t1_Колво_7] ,[t1_КолвоДеньВДень_7] 
--		,[t1_СуммаЗаявки] ,[t1_СуммаДеньВДень] ,[t1_СуммаЗаявки_7] ,[t1_СуммаДеньВДень_7] 
--		,[t1_СрЧекТек] ,[t1_СрЧекДеньВДень] ,[t1_СрЧекТек_7] ,[t1_СрЧекДеньВДень_7]) select GETDATE() as [ДатаОбновления], 1 as id, table_1.[t1_Таблица]
--		,table_1.[t1_Колво] ,table_1.[t1_КолвоДеньВДень] ,table_1.[t1_Колво_7] ,table_1.[t1_КолвоДеньВДень_7] 
--		,table_1.[t1_СуммаЗаявки] ,table_1.[t1_СуммаДеньВДень] ,table_1.[t1_СуммаЗаявки_7] ,table_1.[t1_СуммаДеньВДень_7] 
--		,table_1.[t1_СрЧекТек] ,table_1.[t1_СрЧекДеньВДень] ,table_1.[t1_СрЧекТек_7] ,table_1.[t1_СрЧекДеньВДень_7] from #t1 as table_1


insert into [dbo].[dm_dashboard_ConmmonTable] ([ДатаОбновления] , id) select GETDATE() as [ДатаОбновления], 1 as id


update [dbo].[dm_dashboard_ConmmonTable] 
SET 
[t1_Таблица]= table_1.[t1_Таблица],
[t1_Колво] =table_1.[t1_Колво],
[t1_КолвоДеньВДень]= table_1.[t1_КолвоДеньВДень],
[t1_Колво_7] =table_1.[t1_Колво_7],
[t1_КолвоДеньВДень_7] =table_1.[t1_КолвоДеньВДень_7],

[t1_СуммаЗаявки] =table_1.[t1_СуммаЗаявки],
[t1_СуммаДеньВДень] =table_1.[t1_СуммаДеньВДень],
[t1_СуммаЗаявки_7] =table_1.[t1_СуммаЗаявки_7],
[t1_СуммаДеньВДень_7] =table_1.[t1_СуммаДеньВДень_7] ,

[t1_СуммаЗаявки_MP] =table_1.[t1_СуммаЗаявки_MP],
[t1_СуммаДеньВДень_MP] =table_1.[t1_СуммаДеньВДень_MP],
[t1_СуммаЗаявки_7_MP] =table_1.[t1_СуммаЗаявки_7_MP],
[t1_СуммаДеньВДень_7_MP] =table_1.[t1_СуммаДеньВДень_7_MP] ,

[t1_СуммаЗаявки_NE_MP] =table_1.[t1_СуммаЗаявки_NE_MP],
[t1_СуммаДеньВДень_NE_MP] =table_1.[t1_СуммаДеньВДень_NE_MP],
[t1_СуммаЗаявки_7_NE_MP] =table_1.[t1_СуммаЗаявки_7_NE_MP],
[t1_СуммаДеньВДень_7_NE_MP] =table_1.[t1_СуммаДеньВДень_7_NE_MP] ,

[t1_СрЧекТек] =table_1.[t1_СрЧекТек],
[t1_СрЧекДеньВДень] = table_1.[t1_СрЧекДеньВДень],
[t1_СрЧекТек_7]= table_1.[t1_СрЧекТек_7],
[t1_СрЧекДеньВДень_7]= table_1.[t1_СрЧекДеньВДень_7]
from #t1 as table_1
where id = 1 


update [dbo].[dm_dashboard_ConmmonTable] 
SET [t2_Таблица] = t2.[t2_Таблица],
[t2_Колво0]  = t2.[t2_Колво0] ,
[t2_Колво1]  = t2.[t2_Колво1] ,
[t2_Колво2]  = t2.[t2_Колво2] ,
[t2_Колво3]  = t2.[t2_Колво3] ,
[t2_Колво4]  = t2.[t2_Колво4] ,
[t2_Колво5]  = t2.[t2_Колво5] ,
[t2_Колво0_2]  = t2.[t2_Колво0_2] ,
[t2_Колво1_2]  = t2.[t2_Колво1_2] ,
[t2_Колво2_2]  = t2.[t2_Колво2_2] ,
[t2_Колво3_2]  = t2.[t2_Колво3_2] ,
[t2_Колво4_2]  = t2.[t2_Колво4_2] ,
[t2_Колво5_2] =t2.[t2_Колво5_2]

from #t2 as t2 
where id = 1 

update [dbo].[dm_dashboard_ConmmonTable] 
SET 
   [t3_Колво1_0] =     t3.[t3_Колво1_0], 
   [t3_СуммаЗаявки1_0] =    t3.[t3_СуммаЗаявки1_0],
   [t3_Колво1_1] =     t3.[t3_Колво1_1], 
   [t3_СуммаЗаявки1_1] =    t3.[t3_СуммаЗаявки1_1],
   [t3_Колво1_2] =     t3.[t3_Колво1_2], 
   [t3_СуммаЗаявки1_2] =    t3.[t3_СуммаЗаявки1_2],
   [t3_Колво1_3] =     t3.[t3_Колво1_3], 
   [t3_СуммаЗаявки1_3] =    t3.[t3_СуммаЗаявки1_3],
   [t3_Колво1_4] =     t3.[t3_Колво1_4], 
   [t3_СуммаЗаявки1_4] =    t3.[t3_СуммаЗаявки1_4],
   [t3_Колво1_5] =     t3.[t3_Колво1_5], 
   [t3_СуммаЗаявки1_5] =    t3.[t3_СуммаЗаявки1_5],
   --
		[t3_Колво1_6] =     t3.[t3_Колво1_6], 
		[t3_СуммаЗаявки1_6] =    t3.[t3_СуммаЗаявки1_6],
		[t3_Колво1_7] =     t3.[t3_Колво1_7], 
		[t3_СуммаЗаявки1_7] =    t3.[t3_СуммаЗаявки1_7],
  [t3_Колво2_0] =    t3.[t3_Колво2_0], 
  [t3_СуммаЗаявки2_0] =   t3.[t3_СуммаЗаявки2_0],
  [t3_Колво2_1] =    t3.[t3_Колво2_1], 
  [t3_СуммаЗаявки2_1] =   t3.[t3_СуммаЗаявки2_1],
  [t3_Колво2_2] =    t3.[t3_Колво2_2], 
  [t3_СуммаЗаявки2_2] =   t3.[t3_СуммаЗаявки2_2],
  [t3_Колво2_3] =    t3.[t3_Колво2_3], 
  [t3_СуммаЗаявки2_3] =   t3.[t3_СуммаЗаявки2_3],
  [t3_Колво2_4] =    t3.[t3_Колво2_4], 
  [t3_СуммаЗаявки2_4] =   t3.[t3_СуммаЗаявки2_4],
  [t3_Колво2_5] =    t3.[t3_Колво2_5], 
  [t3_СуммаЗаявки2_5] =   t3.[t3_СуммаЗаявки2_5],
  --
		[t3_Колво2_6] =    t3.[t3_Колво2_6], 
		[t3_СуммаЗаявки2_6] =   t3.[t3_СуммаЗаявки2_6],
		[t3_Колво2_7] =    t3.[t3_Колво2_7], 
		[t3_СуммаЗаявки2_7] =   t3.[t3_СуммаЗаявки2_7]

from #t3 as t3
where id = 1 




update [dbo].[dm_dashboard_ConmmonTable] 
SET 
[t4_Таблица] =  t4.[t4_Таблица], 
[t4_Колво] =   t4.[t4_Колво],  
[t4_КолвоДеньВДень] =  t4.[t4_КолвоДеньВДень], 
[t4_Колво_7] =  t4.[t4_Колво_7], 
[t4_Колво_ВхЗв] =  t4.[t4_Колво_ВхЗв], 
[t4_КолвоДеньВДень_ВхЗв] =  t4.[t4_КолвоДеньВДень_ВхЗв], 
[t4_Колво_7_ВхЗв] = t4.[t4_Колво_7_ВхЗв],
[t4_Колво_Лид] =  t4.[t4_Колво_Лид], 
[t4_КолвоДеньВДень_Лид] =  t4.[t4_КолвоДеньВДень_Лид], 
[t4_Колво_7_Лид] =  t4.[t4_Колво_7_Лид], 
[t4_Колво_Заявка] = t4.[t4_Колво_Заявка],
[t4_КолвоДеньВДень_Заявка] =  t4.[t4_КолвоДеньВДень_Заявка], 
[t4_Колво_7_Заявка] = t4.[t4_Колво_7_Заявка],

[t4_Колво_Заявка_1]= t4.[t4_Колво_Заявка_1],


[t4_КолвоДеньВДень_Заявка_1]= t4.[t4_КолвоДеньВДень_Заявка_1],
[t4_Колво_7_Заявка_1]= t4.[t4_Колво_7_Заявка_1],
[t4_Колво_Лид_1]= t4.[t4_Колво_Лид_1],
[t4_КолвоДеньВДень_Лид_1]= t4.[t4_КолвоДеньВДень_Лид_1] ,
[t4_Колво_7_Лид_1] = t4.[t4_Колво_7_Лид_1]		, 
[t4_Колво_Лид_2]= t4.[t4_Колво_Лид_2],
[t4_КолвоДеньВДень_Лид_2]= t4.[t4_КолвоДеньВДень_Лид_2] ,
[t4_Колво_7_Лид_2]= t4.[t4_Колво_7_Лид_2], 
[t4_Колво_Лид_3]= t4.[t4_Колво_Лид_3],
[t4_КолвоДеньВДень_Лид_3]= t4.[t4_КолвоДеньВДень_Лид_3] ,
[t4_Колво_7_Лид_3] = t4.[t4_Колво_7_Лид_3],
[t4_Колво_ВРаботу] = t4.[t4_Колво_ВРаботу],
[t4_КолвоДеньВДень_ВРаботу] = t4.[t4_КолвоДеньВДень_ВРаботу],
[t4_Колво_7_ВРаботу]= t4.[t4_Колво_7_ВРаботу],
[t4_Колво_Дозвон] = t4.[t4_Колво_Дозвон],
[t4_КолвоДеньВДень_Дозвон]= t4.[t4_КолвоДеньВДень_Дозвон],
[t4_Колво_7_Дозвон]= t4.[t4_Колво_7_Дозвон],		



[t4_Колво_Заявка_2]= t4.[t4_Колво_Заявка_2],
[t4_КолвоДеньВДень_Заявка_2]= t4.[t4_КолвоДеньВДень_Заявка_2],
[t4_Колво_7_Заявка_2]= t4.[t4_Колво_7_Заявка_2],
[t4_Колво_Заявка_3]= t4.[t4_Колво_Заявка_3]	,
[t4_КолвоДеньВДень_Заявка_3]= t4.[t4_КолвоДеньВДень_Заявка_3]	,
[t4_Колво_7_Заявка_3]= t4.[t4_Колво_7_Заявка_3],
[t4_Колво_Заявка_4]= t4.[t4_Колво_Заявка_4]	,
[t4_КолвоДеньВДень_Заявка_4]= t4.[t4_КолвоДеньВДень_Заявка_4]	,
[t4_Колво_7_Заявка_4]= t4.[t4_Колво_7_Заявка_4]		,
[t4_Колво_Заявка_5]= t4.[t4_Колво_Заявка_5]			,
[t4_КолвоДеньВДень_Заявка_5]= t4.[t4_КолвоДеньВДень_Заявка_5]	,
[t4_Колво_7_Заявка_5]= t4.[t4_Колво_7_Заявка_5]		,
[t4_Колво_Заявка_6]= t4.[t4_Колво_Заявка_6]	,
[t4_КолвоДеньВДень_Заявка_6]= t4.[t4_КолвоДеньВДень_Заявка_6]	,
[t4_Колво_7_Заявка_6]= t4.[t4_Колво_7_Заявка_6]

from #t4 as t4
where id = 1 


update [dbo].[dm_dashboard_ConmmonTable] 
SET 
[t5_Таблица] =  t5.[t5_Таблица], 
[t5_КолвоПО] =  t5.[t5_КолвоПО], 
[t5_КолвоДеньВДеньПО] =  t5.[t5_КолвоДеньВДеньПО], 
[t5_КолвоДеньВДень7ПО] = t5.[t5_КолвоДеньВДень7ПО],
[t5_КолвоКД] =  t5.[t5_КолвоКД], 
[t5_КолвоДеньВДеньКД] =  t5.[t5_КолвоДеньВДеньКД], 
[t5_КолвоДеньВДень7КД] = t5.[t5_КолвоДеньВДень7КД],
[t5_КолвоКД_2] =  t5.[t5_КолвоКД_2], 
[t5_КолвоДеньВДеньКД_2] =  t5.[t5_КолвоДеньВДеньКД_2], 
[t5_КолвоДеньВДень7КД_2] = t5.[t5_КолвоДеньВДень7КД_2],
[t5_КолвоВН] =  t5.[t5_КолвоВН], 
[t5_КолвоДеньВДеньВН] =  t5.[t5_КолвоДеньВДеньВН], 
[t5_КолвоДеньВДень7ВН] = t5.[t5_КолвоДеньВДень7ВН],
[t5_КолвоВНПарт] =  t5.[t5_КолвоВНПарт], 
[t5_КолвоДеньВДеньВНПарт] =  t5.[t5_КолвоДеньВДеньВНПарт], 
[t5_КолвоДеньВДень7ВНПарт] = t5.[t5_КолвоДеньВДень7ВНПарт],
[t5_КолвоВНВМ] =  t5.[t5_КолвоВНВМ], 
[t5_КолвоДеньВДеньВНВМ] =  t5.[t5_КолвоДеньВДеньВНВМ], 
[t5_КолвоДеньВДень7ВНВМ] = t5.[t5_КолвоДеньВДень7ВНВМ],
[t5_КолвоВДК] =  t5.[t5_КолвоВДК], 
[t5_КолвоДеньВДеньВДК] =  t5.[t5_КолвоДеньВДеньВДК], 
[t5_КолвоДеньВДень7ВДК] = t5.[t5_КолвоДеньВДень7ВДК],
[t5_КолвоОДК] =  t5.[t5_КолвоОДК], 
[t5_КолвоДеньВДеньОДК] =  t5.[t5_КолвоДеньВДеньОДК], 
[t5_КолвоДеньВДень7ОДК] =  t5.[t5_КолвоДеньВДень7ОДК], 
[t5_КолвоВД] =  t5.[t5_КолвоВД], 
[t5_КолвоДеньВДеньВД] =  t5.[t5_КолвоДеньВДеньВД], 
[t5_КолвоДеньВДень7ВД] = t5.[t5_КолвоДеньВДень7ВД],
[t5_КолвоОд] =  t5.[t5_КолвоОд], 
[t5_КолвоДеньВДеньОд] =  t5.[t5_КолвоДеньВДеньОд], 
[t5_КолвоДеньВДень7Од] = t5.[t5_КолвоДеньВДень7Од],
[t5_КолвоДП] =  t5.[t5_КолвоДП], 
[t5_КолвоДеньВДеньДП] =  t5.[t5_КолвоДеньВДеньДП], 
[t5_КолвоДеньВДень7ДП] = t5.[t5_КолвоДеньВДень7ДП],
[t5_КолвоЗВ] =  t5.[t5_КолвоЗВ], 
[t5_КолвоДеньВДеньЗВ] =  t5.[t5_КолвоДеньВДеньЗВ], 
[t5_КолвоДеньВДень7ЗВ] = t5.[t5_КолвоДеньВДень7ЗВ]

from #t5 as t5
where id = 1 


update [dbo].[dm_dashboard_ConmmonTable] 
SET 
[t51_Таблица] = t51.[t51_Таблица],
[t51_КолвоПО] = t51.[t51_КолвоПО],
[t51_КолвоДеньВДеньПО] = t51.[t51_КолвоДеньВДеньПО],
[t51_КолвоДеньВДень7ПО] = t51.[t51_КолвоДеньВДень7ПО],
[t51_КолвоКД] = t51.[t51_КолвоКД],
[t51_КолвоДеньВДеньКД] = t51.[t51_КолвоДеньВДеньКД],
[t51_КолвоДеньВДень7КД] = t51.[t51_КолвоДеньВДень7КД],
[t51_КолвоВН] = t51.[t51_КолвоВН],
[t51_КолвоДеньВДеньВН] = t51.[t51_КолвоДеньВДеньВН],
[t51_КолвоДеньВДень7ВН] = t51.[t51_КолвоДеньВДень7ВН],
[t51_КолвоВНПарт] = t51.[t51_КолвоВНПарт],
[t51_КолвоДеньВДеньВНПарт] = t51.[t51_КолвоДеньВДеньВНПарт],
[t51_КолвоДеньВДень7ВНПарт] = t51.[t51_КолвоДеньВДень7ВНПарт],
[t51_КолвоВНВМ] = t51.[t51_КолвоВНВМ],
[t51_КолвоДеньВДеньВНВМ] = t51.[t51_КолвоДеньВДеньВНВМ],
[t51_КолвоДеньВДень7ВНВМ] = t51.[t51_КолвоДеньВДень7ВНВМ],
[t51_КолвоВДК] = t51.[t51_КолвоВДК],
[t51_КолвоДеньВДеньВДК] = t51.[t51_КолвоДеньВДеньВДК],
[t51_КолвоДеньВДень7ВДК] = t51.[t51_КолвоДеньВДень7ВДК],
[t51_КолвоОДК] = t51.[t51_КолвоОДК],
[t51_КолвоДеньВДеньОДК] = t51.[t51_КолвоДеньВДеньОДК],
[t51_КолвоДеньВДень7ОДК] = t51.[t51_КолвоДеньВДень7ОДК],
[t51_КолвоВД] = t51.[t51_КолвоВД],
[t51_КолвоДеньВДеньВД] = t51.[t51_КолвоДеньВДеньВД],
[t51_КолвоДеньВДень7ВД] = t51.[t51_КолвоДеньВДень7ВД],
[t51_КолвоОд] = t51.[t51_КолвоОд],
[t51_КолвоДеньВДеньОд] = t51.[t51_КолвоДеньВДеньОд],
[t51_КолвоДеньВДень7Од] = t51.[t51_КолвоДеньВДень7Од],
[t51_КолвоДП] = t51.[t51_КолвоДП],
[t51_КолвоДеньВДеньДП] = t51.[t51_КолвоДеньВДеньДП],
[t51_КолвоДеньВДень7ДП] = t51.[t51_КолвоДеньВДень7ДП],
[t51_КолвоДП_ПЭП] = t51.[t51_КолвоДП_ПЭП],
[t51_КолвоДеньВДеньДП_ПЭП] = t51.[t51_КолвоДеньВДеньДП_ПЭП],
[t51_КолвоДеньВДень7ДП_ПЭП] = t51.[t51_КолвоДеньВДень7ДП_ПЭП],
[t51_КолвоДП_НЕ_ПЭП] = t51.[t51_КолвоДП_НЕ_ПЭП],
[t51_КолвоДеньВДеньДП_НЕ_ПЭП] = t51.[t51_КолвоДеньВДеньДП_НЕ_ПЭП],
[t51_КолвоДеньВДень7ДП_НЕ_ПЭП] = t51.[t51_КолвоДеньВДень7ДП_НЕ_ПЭП],
[t51_КолвоЗВ] = t51.[t51_КолвоЗВ],
[t51_КолвоДеньВДеньЗВ] = t51.[t51_КолвоДеньВДеньЗВ],
[t51_КолвоДеньВДень7ЗВ] = t51.[t51_КолвоДеньВДень7ЗВ]


from #t51 as t51
where id = 1 


END

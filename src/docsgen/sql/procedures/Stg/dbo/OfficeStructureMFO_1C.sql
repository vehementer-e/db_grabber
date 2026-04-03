-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-05-20
-- Description:	Таблица Административная структура компании с учетом иерархии
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[OfficeStructureMFO_1C] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [dbo].[OfficeStructureMFO_1C]


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


if OBJECT_ID('[dbo].[OfficeStructure_1cMFO]') is not null 
truncate table [dbo].[OfficeStructure_1cMFO];

--create table [dbo].[OfficeStructure_1cMFO]
--(
--[id_num] int IDENTITY(1,1)
--,[Этаж_L1] nvarchar(2) not null
--,[Род_L1] binary(16) null
--,[Ссылка_L1] binary(16) null
--,[Код_L1] nvarchar(50) null
--,[Наим_L1] nvarchar(255) null
--,[Этаж_L2] nvarchar(2) null
--,[Род_L2] binary(16) null
--,[Ссылка_L2] binary(16) null
--,[Код_L2] nvarchar(50) null
--,[Наим_L2] nvarchar(255) null
--,[Этаж_L3] nvarchar(2) null
--,[Род_L3] binary(16) null
--,[Ссылка_L3] binary(16) null
--,[Код_L3] nvarchar(50) null
--,[Наим_L3] nvarchar(255) null
--,[Этаж_L4] nvarchar(2) null
--,[Род_L4] binary(16) null
--,[Ссылка_L4] binary(16) null
--,[Код_L4] nvarchar(50) null
--,[Наим_L4] nvarchar(255) null
--,[Этаж_L5] nvarchar(2) null
--,[Род_L5] binary(16) null
--,[Ссылка_L5] binary(16) null
--,[Код_L5] nvarchar(50) null
--,[Наим_L5] nvarchar(255) null
--,[Этаж_L6] nvarchar(2) null
--,[Род_L6] binary(16) null
--,[Ссылка_L6] binary(16) null
--,[Код_L6] nvarchar(50) null
--,[Наим_L6] nvarchar(255) null
--,[Этаж_L7] nvarchar(2) null
--,[Род_L7] binary(16) null
--,[Ссылка_L7] binary(16) null
--,[Код_L7] nvarchar(50) null
--,[Наим_L7] nvarchar(255) null
--);


with gp_office as (select * from [_1cMFO].[Справочник_ГП_Офисы] with (nolock))	-- [prodsql02].[mfo].[dbo].[Справочник_ГП_Офисы]

insert into [dbo].[OfficeStructure_1cMFO]([Этаж_L1] ,[Род_L1] ,[Ссылка_L1] ,[Код_L1] ,[Наим_L1]
												,[Этаж_L2] ,[Род_L2] ,[Ссылка_L2] ,[Код_L2] ,[Наим_L2] 
												,[Этаж_L3] ,[Род_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3] 
												,[Этаж_L4] ,[Род_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4] 
												,[Этаж_L5] ,[Род_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5] 
												,[Этаж_L6] ,[Род_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6] 
												,[Этаж_L7] ,[Род_L7] ,[Ссылка_L7] ,[Код_L7] ,[Наим_L7])
SELECT 
      'L1' as [Этаж_1] ,o1.[Родитель] as [Род_L1] ,o1.[Ссылка] as [Ссылка_L1] ,o1.[Код] as [Код_L1] ,o1.[Наименование] as [Наим_L1] -- 1-й уровень
	  ,oo2.[Этаж_L2] ,oo2.[Родитель] as [Род_L2] ,oo2.[Ссылка] as [Ссылка_L2] ,oo2.[Код] as [Код_L2] ,oo2.[Наименование] as [Наим_L2] -- 2-й уровень
	  ,oo2.[Этаж_L3] ,oo2.[Род_L3] ,oo2.[Ссылка_L3] ,oo2.[Код_L3] ,oo2.[Наим_L3] -- 3-й уровень
	  ,oo2.[Этаж_L4] ,oo2.[Род_L4] ,oo2.[Ссылка_L4] ,oo2.[Код_L4] ,oo2.[Наим_L4] -- 4-й уровень
	  ,oo2.[Этаж_L5] ,oo2.[Род_L5] ,oo2.[Ссылка_L5] ,oo2.[Код_L5] ,oo2.[Наим_L5] -- 5-й уровень
	  ,oo2.[Этаж_L6] ,oo2.[Род_L6] ,oo2.[Ссылка_L6] ,oo2.[Код_L6] ,oo2.[Наим_L6] -- 6-й уровень
	  ,oo2.[Этаж_L7] ,oo2.[Род_L7] ,oo2.[Ссылка_L7] ,oo2.[Код_L7] ,oo2.[Наим_L7] -- 7-й уровень

FROM gp_office o1
	left join (
			select 'L2' as [Этаж_L2], o2.[Ссылка], o2.[Родитель], o2.[Код], o2.[Наименование]
				   ,oo3.[Этаж_L3],oo3.[Ссылка] as [Ссылка_L3],oo3.[Родитель] as [Род_L3], oo3.[Код] as [Код_L3],oo3.[Наименование] as [Наим_L3]
				   ,oo3.[Этаж_L4],oo3.[Ссылка_L4],oo3.[Род_L4], oo3.[Код_L4],oo3.[Наим_L4]	
				   ,oo3.[Этаж_L5],oo3.[Ссылка_L5],oo3.[Род_L5], oo3.[Код_L5],oo3.[Наим_L5]	
				   ,oo3.[Этаж_L6],oo3.[Ссылка_L6],oo3.[Род_L6], oo3.[Код_L6],oo3.[Наим_L6]	
				   ,oo3.[Этаж_L7],oo3.[Ссылка_L7],oo3.[Род_L7], oo3.[Код_L7],oo3.[Наим_L7]	
			from gp_office o2
			left join (
						select 'L3' as [Этаж_L3],o3.[Ссылка], o3.[Родитель], o3.[Код], o3.[Наименование]
							   ,oo4.[Этаж_L4],oo4.[Ссылка] as [Ссылка_L4],oo4.[Родитель] as [Род_L4], oo4.[Код] as [Код_L4],oo4.[Наименование] as [Наим_L4]
							   ,oo4.[Этаж_L5],oo4.[Ссылка_L5],oo4.[Род_L5], oo4.[Код_L5],oo4.[Наим_L5]
							   ,oo4.[Этаж_L6],oo4.[Ссылка_L6],oo4.[Род_L6], oo4.[Код_L6],oo4.[Наим_L6]
							   ,oo4.[Этаж_L7],oo4.[Ссылка_L7],oo4.[Род_L7], oo4.[Код_L7],oo4.[Наим_L7]
						from gp_office o3
						left join (
									select 'L4' as [Этаж_L4],o4.[Ссылка], o4.[Родитель], o4.[Код], o4.[Наименование]
										   ,oo5.[Этаж_L5],oo5.[Ссылка] as [Ссылка_L5],oo5.[Родитель] as [Род_L5], oo5.[Код] as [Код_L5],oo5.[Наименование] as [Наим_L5]
										   ,oo5.[Этаж_L6],oo5.[Ссылка_L6],oo5.[Род_L6], oo5.[Код_L6],oo5.[Наим_L6]
										   ,oo5.[Этаж_L7],oo5.[Ссылка_L7],oo5.[Род_L7], oo5.[Код_L7],oo5.[Наим_L7]
									from gp_office o4
									left join (
												select 'L5' as [Этаж_L5],o5.[Ссылка], o5.[Родитель], o5.[Код], o5.[Наименование]
													   ,oo6.[Этаж_L6],oo6.[Ссылка] as [Ссылка_L6],oo6.[Родитель] as [Род_L6], oo6.[Код] as [Код_L6],oo6.[Наименование] as [Наим_L6]
													   ,oo6.[Этаж_L7],oo6.[Ссылка_L7],oo6.[Род_L7], oo6.[Код_L7],oo6.[Наим_L7]
												from gp_office o5
												left join (
															select 'L6' as [Этаж_L6],o6.[Ссылка], o6.[Родитель], o6.[Код], o6.[Наименование]
																	,oo7.[Этаж_L7],oo7.[Ссылка] as [Ссылка_L7],oo7.[Родитель] as [Род_L7], oo7.[Код] as [Код_L7],oo7.[Наименование] as [Наим_L7]
															from gp_office o6
															left join (
																		select 'L7' as [Этаж_L7],o7.[Ссылка], o7.[Родитель], o7.[Код], o7.[Наименование]
																		from gp_office o7
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

END

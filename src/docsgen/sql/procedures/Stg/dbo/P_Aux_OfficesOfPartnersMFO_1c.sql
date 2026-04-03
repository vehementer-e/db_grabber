-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-05-22
-- Description:	Таблица Офисы партнеров
-- =============================================

CREATE PROCEDURE [dbo].[P_Aux_OfficesOfPartnersMFO_1c] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--	declare	@DateReport datetime2
--	set @DateReport=@ForDate
/*
if OBJECT_ID('[Stg].[dbo].[aux_OfficesOfPartnersMFO_1c]') is not null
drop table [Stg].[dbo].[aux_OfficesOfPartnersMFO_1c];

create table [Stg].[dbo].[aux_OfficesOfPartnersMFO_1c]
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
*/
--DWH-1764
TRUNCATE TABLE [Stg].[dbo].[aux_OfficesOfPartnersMFO_1c]

insert into [Stg].[dbo].[aux_OfficesOfPartnersMFO_1c] ([РО_Регион] ,[РП_Регион] ,[ТочкаКод] ,[Точка] ,[ТочкаСсылка] ,[ДатаСоздания] ,[ДатаЗакрытия] ,[ВыезднойМенеджер]
																		,[Агент] ,[АгентСсылка] 
																		)

select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион]
	  ,mt0.[ПодчКод] as [ТочкаКод],mt0.[ПодчНаим] as [Точка]
	  ,mt0.[Подчиненный] as [ТочкаСсылка] 
	  ,case when ofc.[ДатаСоздания]='2001-01-01 00:00:00.000' then null else cast(dateadd(year,-2000,ofc.[ДатаСоздания]) as date) end as [ДатаСоздания]
	  ,case when ofc.[ДатаЗакрытия]='2001-01-01 00:00:00.000' then null else cast(dateadd(year,-2000,ofc.[ДатаЗакрытия]) as date) end as [ДатаЗакрытия]
	  ,case when ofc.[ВыезднойМенеджер]=0x01 then N'Да' end as [ВыезднойМенеджер]
	  ,ofc.[Агент] ,ofc.[АгентСсылка]
from [Stg].[dbo].[aux_OfficeMFO_1c] mt0
	left join (select * from [Stg].[dbo].[aux_OfficeMFO_1c]) mt1
		on mt0.[ПроРодитель]=mt1.[Подчиненный]
	left join (select ofc0.[Ссылка] ,ofc1.[Наименование] as [Агент] ,ofc1.[Ссылка] as [АгентСсылка] ,ofc0.[ДатаСоздания] ,ofc0.[ДатаЗакрытия] ,ofc0.[ВыезднойМенеджер]
			   from [C2-VSR-SQL04].[MFO_NIGHT00].[dbo].[Справочник_ГП_Офисы] ofc0
				left join [C2-VSR-SQL04].[MFO_NIGHT00].[dbo].[Справочник_Контрагенты] ofc1
					on ofc0.[Партнер]=ofc1.[Ссылка]
			  ) ofc
		on mt0.[Подчиненный]=ofc.[Ссылка]
where mt0.[ПодчНаим] like N'%Партнер%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр' or mt0.[ПодчНаим] like N'%ВМ%'
order by ofc.[ДатаСоздания] desc
END

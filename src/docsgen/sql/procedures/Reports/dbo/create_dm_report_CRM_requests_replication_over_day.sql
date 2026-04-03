-- =============================================
-- Author:		A. Kotelevets / P.Ilin
-- Create date: 06-11-2020
-- Description:	DWH-761
-- exec create_dm_report_CRM_requests_replication_over_day
-- =============================================
CREATE   proc 
[dbo].[create_dm_report_CRM_requests_replication_over_day]

as
begin


IF object_id('dbo.[dm_report_CRM_requests_replication_over_day]') is null
    CREATE TABLE dbo.[dm_report_CRM_requests_replication_over_day](
	[replication_created] [datetime] NULL,
	[номер] [nchar](14) NOT NULL,
	[дата] [datetime2](0) NULL,
	[Вид займа] [nvarchar](14) NOT NULL,
	[Место cоздания] [varchar](33) NULL,
	[Предварительное одобрение] [datetime2](0) NULL,
	[Верификация КЦ] [datetime2](0) NULL,
	[Встреча назначена] [datetime2](0) NULL,
	[Контроль данных] [datetime2](0) NULL
)
ELSE
    PRINT '1'
IF NOT EXISTS(SELECT top(1) 1 FROM sys.indexes WHERE name = 'replication_created_clustered_index' 
		AND object_id = OBJECT_ID('dbo.[dm_report_CRM_requests_replication_over_day]'))
    BEGIN
       CREATE CLUSTERED INDEX [replication_created_clustered_index] ON dbo.[dm_report_CRM_requests_replication_over_day]
(
	[replication_created] DESC
)
end
;


declare @now_t datetime = getdate()

drop table if exists #Документ_ЗаявкаНаЗаймПодПТС
select ссылка
,      dateadd(year,-2000,дата) Дата
,      номер
,      докредитование
,      видзайма
,      СпособОформления
, @now_t as replication_created

	into #Документ_ЗаявкаНаЗаймПодПТС

from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС --with(nolock)

where Дата>=dateadd(year, 2000, cast(@now_t as date))


delete from #Документ_ЗаявкаНаЗаймПодПТС
where isnumeric(Номер)=0


drop table if exists #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
select Заявка
,      Статус
,      Период
	into #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
from stg._1cCRM.[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] st-- with(nolock)
--from [prodsql01].crm.dbo.[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] st with(nolock)
where Период>=dateadd(year, 2000, cast(@now_t as date))

;
drop table if exists #for_insert
;

with  st_zv as (
select [Заявка]                          [Заявка]
,      Статус   Статус                         
,      min(dateadd(year, -2000, Период)) Период

from #РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
group by [Заявка]
,        Статус
)


select 
	ВсеЗаявки.replication_created,
	ВсеЗаявки.номер,
	ВсеЗаявки.дата,
	
	iif(ВсеЗаявки.Докредитование=0xA8424EE85197CF54453F1F80BDC849D5 , N'Докредитование', -- Докредитование
	iif(ВсеЗаявки.Докредитование=0xA8424EE85197CF54453F1F80BDC849D5 , N'Параллельный'  , -- Параллельный заем
	iif(ВсеЗаявки.[ВидЗайма]    =0x974A656AFB7A557B48A6B58E3DECA593 , N'Первичный'     , -- Новый
	iif(ВсеЗаявки.[ВидЗайма]    =0xB201F1B23D6AB42947A9828895F164FE , N'Повторный'     , N'')
	)
	)
	)                            [Вид займа],
	способ.представление [Место cоздания]
	,st_zv_5 .Период [Верификация КЦ]
	,st_zv_6 .Период [Предварительное одобрение]
	,st_zv_12.Период [Встреча назначена]
	,st_zv_14.Период [Контроль данных]
into #for_insert
from      #Документ_ЗаявкаНаЗаймПодПТС      ВсеЗаявки

left join [Stg].[_1cCRM].Перечисление_СпособыОформленияЗаявок способ-- with (nolock)
on способ.ссылка = ВсеЗаявки.СпособОформления
left join st_zv as st_zv_6  on st_zv_6 .заявка=ВсеЗаявки.ссылка and st_zv_6 .Статус=0xA81400155D94190011E80784923C60A3--	Предварительное одобрение
left join st_zv as st_zv_5  on st_zv_5 .заявка=ВсеЗаявки.ссылка and st_zv_5 .Статус=0xA81400155D94190011E80784923C60A2--	Верификация КЦ
left join st_zv as st_zv_12 on st_zv_12.заявка=ВсеЗаявки.ссылка and st_zv_12.Статус=0x80E400155D64100111E7BC98DDDF0D76--	Встреча назначена
left join st_zv as st_zv_14 on st_zv_14.заявка=ВсеЗаявки.ссылка and st_zv_14.Статус=0xA81400155D94190011E80784923C609A--	Контроль данных



--select * from #for_insert


--insert into devdb.dbo.[dm_report_CRM_requests_replication_over_day]
insert into dbo.[dm_report_CRM_requests_replication_over_day]
SELECT [replication_created]
      ,[номер]
      ,[дата]
      ,[Вид займа]
      ,[Место cоздания]
      ,[Предварительное одобрение]
      ,[Верификация КЦ]
      ,[Встреча назначена]
      ,[Контроль данных]
  FROM #for_insert

  

  end

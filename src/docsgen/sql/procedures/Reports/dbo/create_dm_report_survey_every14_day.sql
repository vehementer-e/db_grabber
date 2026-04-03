-- =============================================
-- Author:		P.Ilin
-- Create date: 
-- Description:	Создание рассылки для опроса
-- =============================================
CREATE    proc [dbo].[create_dm_report_survey_every14_day]

as
begin


IF object_id('dbo.[dm_report_survey_every14_day_sended]') is null
begin

    CREATE TABLE dbo.[dm_report_survey_every14_day_sended](
	ТелефонИспользованныйДляОпроса nvarchar(255) NULL,
	НомерЗаявкиИсточникТелефона nvarchar(255) NULL,
	created datetime NULL
)
--------https://docs.google.com/spreadsheets/d/16FJv3Vj_gKmVYtESFapQph7F1Rtnax7UM2Rntg8oCRE/edit?usp=sharing
--------после создания процедуры необходимо вручную создать таблицу dbo.[dm_report_survey_every14_day_sended] и вставить туда данные из гугл таблицы

end


IF object_id('dbo.[dm_report_survey_every14_day_to_send]') is null
begin

CREATE TABLE dbo.dm_report_survey_every14_day_to_send(
	[номер] [nvarchar](100) NULL,
	[телефон] [nvarchar](255) NULL,
	[отказ клиента] [datetime] NULL,
	[заем аннулирован] [datetime] NULL,
	[аннулировано] [datetime] NULL,
	created [datetime] NULL,
) 




end



declare @t datetime = getdate()


drop table if exists #t1

select номер                                                         
,      дубль                                                         
,      телефон                                                       
,      [отказ клиента]                                               
,      [заем аннулирован]                                            
,      аннулировано                                                  
	into #t1
from dbo.dm_factor_analysis_001
where (
		   [отказ клиента]    between cast(@t-14 as date) and cast(@t-1 as date)
		or [заем аннулирован] between cast(@t-14 as date) and cast(@t-1 as date)
		or аннулировано       between cast(@t-14 as date) and cast(@t-1 as date)
	)
	and отказано is null
	and [отказ документов клиента] is null
	and Дубль <> 1
	and телефон not

	in (select телефон
	from dbo.dm_factor_analysis_001
	where ДатаЗаявкиПолная>getdate()-5
		and (
			Отказано is not null
			or [Отказ документов клиента] is not null
			or [Заем выдан] is not null));


with v as 
( select a.*, row_number() over(partition by Телефон order by (select null)) rn  from #t1 a
)

delete v from v left join dbo.[dm_report_survey_every14_day_sended] sended on v.Телефон=sended.ТелефонИспользованныйДляОпроса

where v.rn<>1 or ТелефонИспользованныйДляОпроса is not null







begin tran

delete from dbo.[dm_report_survey_every14_day_to_send]

insert into dbo.[dm_report_survey_every14_day_to_send]
select номер
,      телефон
,      [отказ клиента]
,      [заем аннулирован]
,      аннулировано
, @t as created
from #t1

insert into dbo.dm_report_survey_every14_day_sended
select телефон ТелефонИспользованныйДляОпроса, номер НомерЗаявкиИсточникТелефона, @t created
from #t1
commit tran

  end

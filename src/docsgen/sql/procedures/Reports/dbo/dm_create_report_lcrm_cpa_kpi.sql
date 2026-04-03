-- =============================================
-- Author:		Petr Ilin
-- Create date: 20022020
-- Description:	CPA LCRM KPI
-- =============================================
-- Modified: 11.03.2022. А.Никитин
-- Description:	DWH-1590. Отказ от lcrm_tbl_short_w_channel
-- =============================================
CREATE PROCEDURE dbo.dm_create_report_lcrm_cpa_kpi
as 
begin
set XACT_ABORT ON
--Текущая дата
declare @now_dt datetime
set @now_dt = getdate()

--Текущий день
declare @now_date datetime
set @now_date = cast(@now_dt as date)

--Начало текущего месяца
declare @start_t_month datetime
set @start_t_month = dateadd(day,1-day(@now_date),@now_date)


--Начало последнего месяца
declare @start_t_1_month datetime
set @start_t_1_month = dateadd(mm, -1, @start_t_month)

--Начало предпоследнего месяца
declare @start_t_2_month datetime
set @start_t_2_month = dateadd(mm, -2, @start_t_month)


drop table if exists #lcrm_t_2
CREATE TABLE #lcrm_t_2(
	[ID] numeric(10, 0),
	[UF_REGISTERED_AT] datetime2(7),
	[UF_ACTUALIZE_AT] datetime2(7),
	[UF_ISSUED_AT] datetime2(7),
	[UF_SUM_LOAN] float,
	[UF_SOURCE] varchar(128),
	[UF_ROW_ID] varchar(128),
	[UF_REGIONS_COMPOSITE] nvarchar(128),
	[UF_TYPE] varchar(128),
	[UF_TARGET] int,
	[Канал от источника] nvarchar(255),
	[Группа каналов] nvarchar(255),
	[UF_SUM_ACCEPTED] float,
	[UF_LOGINOM_STATUS] varchar(128)
)

--DWH-1590. Комментарю старый код
/*
drop table if exists #ft
drop table if exists #st

select ft.id,
ft.[uf_registered_at]
,ft.UF_ACTUALIZE_AT
,ft.[uf_issued_at]
,ft.[Uf_sum_loan]
,ft.[uf_source]
,ft.[uf_row_id]
,ft.[UF_REGIONS_COMPOSITE]
,ft.[uf_type]
,ft.[uf_target]
,ft.[Канал от источника]
,ft.[Группа каналов]
,ft.UF_SUM_ACCEPTED
into #ft
from [Stg].[dbo].[lcrm_tbl_full_w_chanals2] ft with(nolock)
where 
ft.UF_REGISTERED_AT>=@start_t_2_month 
or 
ft.UF_ROW_ID is not null
--or 
--ft.UF_ACTUALIZE_AT>=@start_t_2_month 
--or 
--ft.[uf_issued_at]>=@start_t_2_month


select st.id,
st.uf_loginom_status 
into #st
from [Stg].[_LCRM].[lcrm_tbl_short_w_channel] st with(nolock)
join #ft ft on ft.id=st.id


select ft.id,
ft.[uf_registered_at]
,ft.UF_ACTUALIZE_AT
,ft.[uf_issued_at]
,ft.[Uf_sum_loan]
,ft.[uf_source]
,ft.[uf_row_id]
,ft.[UF_REGIONS_COMPOSITE]
,ft.[uf_type]
,ft.[uf_target]
,ft.[Канал от источника]
,ft.[Группа каналов]
,ft.UF_SUM_ACCEPTED
, st.UF_LOGINOM_STATUS
into #lcrm_t_2
from #ft ft with(nolock)
 join #st st with(nolock)
on ft.ID=st.ID
*/

--DWH-1590. Отказ от [Stg].[_LCRM].[lcrm_tbl_short_w_channel], [Stg].[dbo].[lcrm_tbl_full_w_chanals2]
DROP TABLE IF EXISTS #ID_List
CREATE TABLE #ID_List(ID numeric(10, 0))

--заполнить таблицу ID в соответствии с логикой
/*
where 
UF_REGISTERED_AT>=@start_t_2_month 
or 
UF_ROW_ID is not null
*/
INSERT #ID_List(ID)
SELECT C.ID
FROM Stg._LCRM.lcrm_leads_full_calculated AS C (nolock)
WHERE C.UF_REGISTERED_AT_date >= @start_t_2_month
UNION
SELECT R.ID 
FROM Stg._LCRM.lcrm_leads_full_channel_request AS R

DECLARE @ID_Table_Name varchar(100) 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

SELECT @ID_Table_Name = '#ID_List' --название таблицы со списком ID
SELECT @Return_Table_Name = '#lcrm_t_2' --название таблицы, которая будет заполнена

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ID_Table_Name = @ID_Table_Name, -- название таблицы со списком ID
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение
--// end DWH-1590.


drop table if exists #table1
select 
[Канал от источника]
, [UF_SOURCE]
, COUNT(CASE WHEN CONVERT(DATE, [UF_REGISTERED_AT]) = CONVERT(DATE, GETDATE()) THEN [UF_REGISTERED_AT] END) AS [t]
, COUNT(CASE WHEN CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [t-1]
, COUNT(CASE WHEN CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -2, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [t-2]
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

, COUNT(CASE WHEN CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -3, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [t-3]
, COUNT(CASE WHEN CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -4, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [t-4]
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

,getdate() as created
into #table1

from #lcrm_t_2
where 
[Канал от источника] in ('CPA нецелевой'
                        ,'CPA полуцелевой'
                        ,'CPA целевой'
						)

group by 
[Канал от источника]
, [UF_SOURCE]

order by 
[Канал от источника] 
, [UF_SOURCE] 

begin tran
delete from dbo.dm_report_lcrm_cpa_kpi_1
insert into  dbo.dm_report_lcrm_cpa_kpi_1
select * from #table1
commit tran

		
---------------------------------------------Таблица 2
drop table if exists #table2


select 
[Канал от источника]
, [UF_SOURCE]
, COUNT(CASE WHEN CONVERT(DATE, [UF_ACTUALIZE_AT]) = CONVERT(DATE, GETDATE()) and [UF_ROW_ID] is not null THEN [UF_ACTUALIZE_AT] END) AS [t]
, COUNT(CASE WHEN CONVERT(DATE, [UF_ACTUALIZE_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) and [UF_ROW_ID] is not null THEN [UF_ACTUALIZE_AT] END) AS [t-1]
, COUNT(CASE WHEN CONVERT(DATE, [UF_ACTUALIZE_AT]) = DATEADD(DAY, -2, CONVERT(DATE,  GETDATE())) and [UF_ROW_ID] is not null THEN [UF_ACTUALIZE_AT] END) AS [t-2]
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

, COUNT(CASE WHEN CONVERT(DATE, [UF_ACTUALIZE_AT]) = DATEADD(DAY, -3, CONVERT(DATE,  GETDATE())) and [UF_ROW_ID] is not null THEN [UF_ACTUALIZE_AT] END) AS [t-3]
, COUNT(CASE WHEN CONVERT(DATE, [UF_ACTUALIZE_AT]) = DATEADD(DAY, -4, CONVERT(DATE,  GETDATE())) and [UF_ROW_ID] is not null THEN [UF_ACTUALIZE_AT] END) AS [t-4]
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

,getdate() as created

into #table2
from #lcrm_t_2 (nolock)
where 
[Канал от источника] in ('CPA нецелевой'
                        ,'CPA полуцелевой'
                        ,'CPA целевой'
						)

group by
[Канал от источника]
, [UF_SOURCE]
order by
[Канал от источника]
, [UF_SOURCE]

begin tran
delete from dbo.dm_report_lcrm_cpa_kpi_2
insert into dbo.dm_report_lcrm_cpa_kpi_2
select * from #table2
commit tran
---------------------------------------------Таблица 3
drop table if exists #table3

select 
[Канал от источника]
, [UF_SOURCE]
, count(case when [UF_ISSUED_AT]>=cast(dateadd(day,1-day(getdate()),getdate()) as date) then [UF_ISSUED_AT] end) as [Текущий месяц_Займы]
, isnull(sum(case when [UF_ISSUED_AT]>=cast(dateadd(day,1-day(getdate()),getdate()) as date) then UF_SUM_ACCEPTED end),0) as [Текущий месяц_Объемы]
, count(case when [UF_ISSUED_AT]>=cast(dateadd(month, datediff(month, 0, getdate())-1, 0) as date) and [UF_ISSUED_AT]<cast(dateadd(day,1-day(getdate()),getdate()) as date) then [UF_ISSUED_AT] end) as [Прошлый месяц_Займы]
, isnull(sum(case when [UF_ISSUED_AT]>=cast(dateadd(month, datediff(month, 0, getdate())-1, 0) as date) and [UF_ISSUED_AT]<cast(dateadd(day,1-day(getdate()),getdate()) as date) then UF_SUM_ACCEPTED end),0) as [Прошлый месяц_Объемы]
, count(case when [UF_ISSUED_AT]>=cast(dateadd(month, datediff(month, 0, getdate())-2, 0) as date) and [UF_ISSUED_AT]<cast(dateadd(month, datediff(month, 0, getdate())-1, 0) as date) then [UF_ISSUED_AT] end) as [Позапрошлый месяц_Займы]
, isnull(sum(case when [UF_ISSUED_AT]>=cast(dateadd(month, datediff(month, 0, getdate())-2, 0) as date) and [UF_ISSUED_AT]<cast(dateadd(month, datediff(month, 0, getdate())-1, 0) as date) then UF_SUM_ACCEPTED end),0) as [Позапрошлый месяц_Объемы]
,getdate() as created

into #table3
from
#lcrm_t_2 (nolock)

where 
[Канал от источника] in ('CPA нецелевой'
                        ,'CPA полуцелевой'
                        ,'CPA целевой'
						)

group by
[Канал от источника]
, [UF_SOURCE]
order by
[Канал от источника]
, [UF_SOURCE]

begin tran
delete from dbo.dm_report_lcrm_cpa_kpi_3
insert into dbo.dm_report_lcrm_cpa_kpi_3
select * from #table3
commit tran

---------------------------------------------Таблица 5
drop table if exists #table5


select 
LD.[Канал от источника]
, LD.[UF_SOURCE]

, COUNT(CASE WHEN [VALUE]= 'depr. - mfo (lcrm_cc)' and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [depr. - mfo (lcrm_cc)_Вчера]
, COUNT(CASE WHEN [VALUE]= 'FEDOR IVR' and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [FEDOR IVR_Вчера]
, COUNT(CASE WHEN [VALUE]= 'FEDOR PILOT' and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [FEDOR PILOT_Вчера]
, COUNT(CASE WHEN [VALUE]= 'FEDOR TLS' and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [FEDOR TLS_Вчера]
, COUNT(CASE WHEN [VALUE]= 'FEDOR TRIGGERS' and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [FEDOR TRIGGERS_Вчера]
, COUNT(CASE WHEN [VALUE]= 'Отп. в никуда (VoidCC)' and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [Отп. в никуда (VoidCC)_Вчера]
, COUNT(CASE WHEN [VALUE]= 'Отп. FEDOR PILOT 25' and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [Отп. FEDOR PILOT 25_Вчера]
, COUNT(CASE WHEN [VALUE] is NULL and CONVERT(DATE, [UF_REGISTERED_AT]) = DATEADD(DAY, -1, CONVERT(DATE,  GETDATE())) THEN [UF_REGISTERED_AT] END) AS [Не обнаружено_Вчера]
,getdate() as created

into #table5

from
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--Стало после 27 апреля 2019 года

  #lcrm_t_2 LD left join
 [dbo].[dm_LCMR_LaunchControl_Unique] lc with(nolock) on lc.UF_LCRM_ID=ld.id
  left  join [Stg].[_LCRM].[b_user_field_enum] t_lc with(nolock) on lc.UF_TYPE=t_lc.id
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--Было до 27 апреля 2019 года

  /*
(
SELECT 
      distinct 
	   lc.[UF_LCRM_ID]
      ,lc.[UF_TYPE]
      ,lc.[UF_UPDATED_AT]
	  ,t_lc.VALUE

  FROM [Stg].[_LCRM].[carmoney_light_crm_launch_control] lc with(nolock)
  left  join [Stg].[_LCRM].[b_user_field_enum] t_lc with(nolock) on lc.UF_TYPE=t_lc.id
  where [UF_TYPE] in (
  '107',
  '205',
  '216',
  '217',
  '218',
  '219'
  )
  ) KC
  
  on LD.[ID]=KC.[UF_LCRM_ID]
  */

where 
[Канал от источника] in ('CPA нецелевой', 'CPA полуцелевой', 'CPA целевой')

group by 
[Канал от источника]
, [UF_SOURCE]

order by 
[Канал от источника] 
, [UF_SOURCE] 


begin tran
	if OBJECT_ID('dbo.dm_report_lcrm_cpa_kpi_5') is null
		select top(0) * into dbo.dm_report_lcrm_cpa_kpi_5 from #table5

	delete from dbo.dm_report_lcrm_cpa_kpi_5
	insert into dbo.dm_report_lcrm_cpa_kpi_5
	select * from #table5
commit tran


---------------------------------------------Таблица 6
drop table if exists #table6


select 
[Канал от источника]
, [UF_SOURCE]
, count(case when [UF_LOGINOM_STATUS]='accepted' and convert(date,[UF_REGISTERED_AT])=convert(date,getdate()) then [UF_REGISTERED_AT] end) as [accepted]
, count(case when [UF_LOGINOM_STATUS]='declined' and convert(date,[UF_REGISTERED_AT])=convert(date,getdate()) then [UF_REGISTERED_AT] end) as [declined]
, count(case when [UF_LOGINOM_STATUS]='error' and convert(date,[UF_REGISTERED_AT])=convert(date,getdate()) then [UF_REGISTERED_AT] end) as [error]
, count(case when [UF_LOGINOM_STATUS]='not_available' and convert(date,[UF_REGISTERED_AT])=convert(date,getdate()) then [UF_REGISTERED_AT] end) as [not_available]
, count(case when [UF_LOGINOM_STATUS]='unknown' and convert(date,[UF_REGISTERED_AT])=convert(date,getdate()) then [UF_REGISTERED_AT] end) as [unknown]
,getdate() as created


into #table6

from #lcrm_t_2
where 
[Канал от источника] in ('CPA нецелевой'
                        ,'CPA полуцелевой'
                        ,'CPA целевой'
						)

group by 
[Канал от источника]
, [UF_SOURCE]

order by 
[Канал от источника] 
, [UF_SOURCE] 
begin tran
delete from dbo.dm_report_lcrm_cpa_kpi_6
insert into dbo.dm_report_lcrm_cpa_kpi_6
select * from #table6
commit tran


drop table if exists #table4
select @start_t_month as [Период t]
,getdate() as created
      , lidg.* 
---	,*
	  , case 
	          when uf_source='mezentsevis' then [Число займов из М,МО t-2]*25000+0.03*[Сумма займов <=200000 не из М,МО t-2]+0.04*[Сумма займов >200000 не из М,МО t-2] 
	          when uf_source='creditors24' then [Число займов из М,МО t-2]*25000+0.03*[Сумма займов не из М,МО t-2]
	          when uf_source='creditors24_msk' then [Число займов из М,МО t-2]*25000+0.03*[Сумма займов не из М,МО t-2]
	          when uf_source='kokoc' then 
			                              case when [Число заявок t-2] <=299 then [Число заявок t-2]*800
			                                   when [Число заявок t-2] <=399 then [Число заявок t-2]*900
			                                   when [Число заявок t-2] > 399 then [Число заявок t-2]*1000 end 
	          when uf_source='justlombard' then 
			                                    case when [Конверсия лид - выдача t-2] <0.01 then 
												                                                   case when [Число заявок t-2] <=3000 then [Число заявок t-2]*1000
												                                                        when [Число заявок t-2] <=4000 then [Число заявок t-2]*1000
												                                                        when [Число заявок t-2] <=5000 then [Число заявок t-2]*1300
												                                                        when [Число заявок t-2] > 5000 then [Число заявок t-2]*1500 end
			                                         when [Конверсия лид - выдача t-2] >=0.01 then 
												                                                   case when [Число заявок t-2] <=3000 then [Число заявок t-2]*1000
												                                                        when [Число заявок t-2] <=4000 then [Число заявок t-2]*1300
												                                                        when [Число заявок t-2] <=5000 then [Число заявок t-2]*1500
												                                                        when [Число заявок t-2] > 5000 then [Число заявок t-2]*1700 end
																										                                                                end
	          when uf_source in (
			                      'leadgid2'
								 ,'bankiros_ru'
								 ,'bankiros_ru_2'
								 ,'cityads'
								 ,'mastertarget'
								 ,'filkos'
								 ,'liknot'
								 ,'vbr'
								 ,'odobrimru'
								 ,'zaym-me'
								 ,'leadssu'
								 ,'teleport'
								 )            then [Число заявок с api t-2]*450+[Число заявок без api t-2]*700

	          when uf_source='dengipodzalog' then 
			                                       case when [Средний чек t-2] <=200000 then [Сумма займов t-2]*0.015
			                                            when [Средний чек t-2] <=250000 then [Сумма займов t-2]*0.02
			                                            when [Средний чек t-2] > 250000 then [Сумма займов t-2]*0.025 end 

	          when uf_source in (
			                      'pod-pts' 
								 ,'ipvasiliev'
								 ,'zayaffka'
								 )            then 0.03*[Сумма займов t-2]

	          when uf_source='sodeistvie' then 
			                                   case when [Число заявок t-2] <=99 then [Число заявок t-2]*450
			                                        when [Число заявок t-2] > 99 then [Число заявок t-2]*700 end 

	          when uf_source='bankiru' then [Число заявок t-2]*540

	          when uf_source='sravniru' then [Число лидов с uf_target=1 и uf_loginom_status='accepted' t-2]*360

	          when uf_source='avtolombard-credit' then 
			                                           case when [Сумма займов t-2] <16000000 then [Сумма займов t-2]*0.03
			                                                when [Сумма займов t-2] <19000000 then [Сумма займов t-2]*0.035
			                                                when [Сумма займов t-2] <22000000 then [Сумма займов t-2]*0.04
			                                                when [Сумма займов t-2] <25000000 then [Сумма займов t-2]*0.045
			                                                when [Сумма займов t-2] <28000000 then [Сумма займов t-2]*0.05
			                                                when [Сумма займов t-2] <31000000 then [Сумма займов t-2]*0.055
			                                                when [Сумма займов t-2]>=31000000 then [Сумма займов t-2]*0.06 end

	          when uf_source='marketpull' then [Число заявок t-2]*700

	          when uf_source in (
			                      'avtolombard24ru'
								 ,'avtolombardsru' 
								 )                then 
			                                           case when sum(case when uf_source in ('avtolombard24ru', 'avtolombardsru') then [Сумма займов t-2] end) over() <12000000 then [Сумма займов t-2]*0.03
			                                                when sum(case when uf_source in ('avtolombard24ru', 'avtolombardsru') then [Сумма займов t-2] end) over()>=12000000 then [Сумма займов t-2]*0.04 end

	          when uf_source='el-polis' then [Число займов t-2]*10000

			  end as [Сумма выплат t-2]

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

	  , case 
	          when uf_source='mezentsevis' then [Число займов из М,МО t-1]*25000+0.03*[Сумма займов <=200000 не из М,МО t-1]+0.04*[Сумма займов >200000 не из М,МО t-1] 
	          when uf_source='creditors24' then [Число займов из М,МО t-1]*25000+0.03*[Сумма займов не из М,МО t-1]
	          when uf_source='creditors24_msk' then [Число займов из М,МО t-1]*25000+0.03*[Сумма займов не из М,МО t-1]
	          when uf_source='kokoc' then 
			                              case when [Число заявок t-1] <=299 then [Число заявок t-1]*800
			                                   when [Число заявок t-1] <=399 then [Число заявок t-1]*900
			                                   when [Число заявок t-1] > 399 then [Число заявок t-1]*1000 end 
	          when uf_source='justlombard' then 
			                                    case when [Конверсия лид - выдача t-1] <0.01 then 
												                                                   case when [Число заявок t-1] <=3000 then [Число заявок t-1]*1000
												                                                        when [Число заявок t-1] <=4000 then [Число заявок t-1]*1000
												                                                        when [Число заявок t-1] <=5000 then [Число заявок t-1]*1300
												                                                        when [Число заявок t-1] > 5000 then [Число заявок t-1]*1500 end
			                                         when [Конверсия лид - выдача t-1] >=0.01 then 
												                                                   case when [Число заявок t-1] <=3000 then [Число заявок t-1]*1000
												                                                        when [Число заявок t-1] <=4000 then [Число заявок t-1]*1300
												                                                        when [Число заявок t-1] <=5000 then [Число заявок t-1]*1500
												                                                        when [Число заявок t-1] > 5000 then [Число заявок t-1]*1700 end
																										                                                                end
	          when uf_source in (
			                      'leadgid2'
								 ,'bankiros_ru'
								 ,'bankiros_ru_2'
								 ,'cityads'
								 ,'mastertarget'
								 ,'filkos'
								 ,'liknot'
								 ,'vbr'
								 ,'odobrimru'
								 ,'zaym-me'
								 ,'leadssu'
								 ,'teleport'
								 )            then [Число заявок с api t-1]*450+[Число заявок без api t-1]*700

	          when uf_source='dengipodzalog' then 
			                                       case when [Средний чек t-1] <=200000 then [Сумма займов t-1]*0.015
			                                            when [Средний чек t-1] <=250000 then [Сумма займов t-1]*0.02
			                                            when [Средний чек t-1] > 250000 then [Сумма займов t-1]*0.025 end 

	          when uf_source in (
			                      'pod-pts' 
								 ,'ipvasiliev'
								 ,'zayaffka'
								 )            then 0.03*[Сумма займов t-1]

	          when uf_source='sodeistvie' then 
			                                   case when [Число заявок t-1] <=99 then [Число заявок t-1]*450
			                                        when [Число заявок t-1] > 99 then [Число заявок t-1]*700 end 

	          when uf_source='bankiru' then [Число заявок t-1]*540

	          when uf_source='sravniru' then [Число лидов с uf_target=1 и uf_loginom_status='accepted' t-1]*360

	          when uf_source='avtolombard-credit' then 
			                                           case when [Сумма займов t-1] <16000000 then [Сумма займов t-1]*0.03
			                                                when [Сумма займов t-1] <19000000 then [Сумма займов t-1]*0.035
			                                                when [Сумма займов t-1] <22000000 then [Сумма займов t-1]*0.04
			                                                when [Сумма займов t-1] <25000000 then [Сумма займов t-1]*0.045
			                                                when [Сумма займов t-1] <28000000 then [Сумма займов t-1]*0.05
			                                                when [Сумма займов t-1] <31000000 then [Сумма займов t-1]*0.055
			                                                when [Сумма займов t-1]>=31000000 then [Сумма займов t-1]*0.06 end

	          when uf_source='marketpull' then [Число заявок t-1]*700

	          when uf_source in (
			                      'avtolombard24ru'
								 ,'avtolombardsru' 
								 )                then 
			                                           case when sum(case when uf_source in ('avtolombard24ru', 'avtolombardsru') then [Сумма займов t-1] end) over() <12000000 then [Сумма займов t-1]*0.03
			                                                when sum(case when uf_source in ('avtolombard24ru', 'avtolombardsru') then [Сумма займов t-1] end) over()>=12000000 then [Сумма займов t-1]*0.04 end

	          when uf_source='el-polis' then [Число займов t-1]*10000

			  end as [Сумма выплат t-1]



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

	  , case 
	          when uf_source='mezentsevis' then [Число займов из М,МО t]*25000+0.03*[Сумма займов <=200000 не из М,МО t]+0.04*[Сумма займов >200000 не из М,МО t] 
	          when uf_source='creditors24' then [Число займов из М,МО t]*25000+0.03*[Сумма займов не из М,МО t]
	          when uf_source='creditors24_msk' then [Число займов из М,МО t]*25000+0.03*[Сумма займов не из М,МО t]
	          when uf_source='kokoc' then 
			                              case when [Число заявок t] <=299 then [Число заявок t]*800
			                                   when [Число заявок t] <=399 then [Число заявок t]*900
			                                   when [Число заявок t] > 399 then [Число заявок t]*1000 end 
	          when uf_source='justlombard' then 
			                                    case when [Конверсия лид - выдача t] <0.01 then 
												                                                   case when [Число заявок t] <=3000 then [Число заявок t]*1000
												                                                        when [Число заявок t] <=4000 then [Число заявок t]*1000
												                                                        when [Число заявок t] <=5000 then [Число заявок t]*1300
												                                                        when [Число заявок t] > 5000 then [Число заявок t]*1500 end
			                                         when [Конверсия лид - выдача t-1] >=0.01 then 
												                                                   case when [Число заявок t] <=3000 then [Число заявок t]*1000
												                                                        when [Число заявок t] <=4000 then [Число заявок t]*1300
												                                                        when [Число заявок t] <=5000 then [Число заявок t]*1500
												                                                        when [Число заявок t] > 5000 then [Число заявок t]*1700 end
																										                                                                end
	          when uf_source in (
			                      'leadgid2'
								 ,'bankiros_ru'
								 ,'bankiros_ru_2'
								 ,'cityads'
								 ,'mastertarget'
								 ,'filkos'
								 ,'liknot'
								 ,'vbr'
								 ,'odobrimru'
								 ,'zaym-me'
								 ,'leadssu'
								 ,'teleport'
								 )            then [Число заявок с api t]*450+[Число заявок без api t]*700

	          when uf_source='dengipodzalog' then 
			                                       case when [Средний чек t] <=200000 then [Сумма займов t]*0.015
			                                            when [Средний чек t] <=250000 then [Сумма займов t]*0.02
			                                            when [Средний чек t] > 250000 then [Сумма займов t]*0.025 end 

	          when uf_source in (
			                      'pod-pts' 
								 ,'ipvasiliev'
								 ,'zayaffka'
								 )            then 0.03*[Сумма займов t]

	          when uf_source='sodeistvie' then 
			                                   case when [Число заявок t] <=99 then [Число заявок t]*450
			                                        when [Число заявок t] > 99 then [Число заявок t]*700 end 

	          when uf_source='bankiru' then [Число заявок t]*540

	          when uf_source='sravniru' then [Число лидов с uf_target=1 и uf_loginom_status='accepted' t]*360

	          when uf_source='avtolombard-credit' then 
			                                           case when [Сумма займов t] <16000000 then [Сумма займов t]*0.03
			                                                when [Сумма займов t] <19000000 then [Сумма займов t]*0.035
			                                                when [Сумма займов t] <22000000 then [Сумма займов t]*0.04
			                                                when [Сумма займов t] <25000000 then [Сумма займов t]*0.045
			                                                when [Сумма займов t] <28000000 then [Сумма займов t]*0.05
			                                                when [Сумма займов t] <31000000 then [Сумма займов t]*0.055
			                                                when [Сумма займов t]>=31000000 then [Сумма займов t]*0.06 end

	          when uf_source='marketpull' then [Число заявок t]*700

	          when uf_source in (
			                      'avtolombard24ru'
								 ,'avtolombardsru' 
								 )                then 
			                                           case when sum(case when uf_source in ('avtolombard24ru', 'avtolombardsru') then [Сумма займов t] end) over() <12000000 then [Сумма займов t]*0.03
			                                                when sum(case when uf_source in ('avtolombard24ru', 'avtolombardsru') then [Сумма займов t] end) over()>=12000000 then [Сумма займов t]*0.04 end

	          when uf_source='el-polis' then [Число займов t]*10000

			  end as [Сумма выплат t]
			  ,
			  [Число займов t-2]
			  ,
			  [Число займов t-1]
			  ,
			  [Число займов t]
			  into #table4
from (
          select 'mezentsevis' as uf_source
union all select 'creditors24'
union all select 'creditors24_msk'
union all select 'kokoc'
union all select 'justlombard'
union all select 'leadgid2'
union all select 'dengipodzalog'
union all select 'bankiros_ru'
union all select 'bankiros_ru_2'
union all select 'cityads'
union all select 'mastertarget'
union all select 'filkos'
union all select 'liknot'
union all select 'vbr'
union all select 'odobrimru'
union all select 'zaym-me'
union all select 'leadssu'
union all select 'teleport'
union all select 'pod-pts'
union all select 'sodeistvie'
union all select 'ipvasiliev'
union all select 'bankiru'
union all select 'sravniru'
union all select 'avtolombard-credit'
union all select 'marketpull'
union all select 'avtolombard24ru'
union all select 'avtolombardsru'
union all select 'zayaffka'
union all select 'el-polis') lidg
outer apply
(select 
         isnull(sum(case when UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end),0) as [Сумма займов t-2]
        ,isnull(count(case when UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end),0) as [Число займов t-2]
        ,isnull(sum(case when UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end),0) as [Сумма займов t-1]
        ,isnull(count(case when UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end),0) as [Число займов t-1]
        ,isnull(sum(case when UF_ISSUED_AT>=@start_t_month  then UF_SUM_ACCEPTED end),0) as [Сумма займов t]
        ,isnull(count(case when UF_ISSUED_AT>=@start_t_month then UF_SUM_ACCEPTED end),0) as [Число займов t]


        ,isnull(count(case when uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_2_month and UF_ACTUALIZE_AT<@start_t_1_month then uf_row_id end),0) as [Число заявок t-2]
        ,isnull(count(case when uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_1_month and UF_ACTUALIZE_AT<@start_t_month then uf_row_id end),0) as [Число заявок t-1]
        ,isnull(count(case when uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_month then uf_row_id end),0) as [Число заявок t]

        ,isnull(count(case when uf_registered_at>=@start_t_2_month and uf_registered_at<@start_t_1_month then id end),0) as [Число лидов t-2]
        ,isnull(count(case when uf_registered_at>=@start_t_1_month and uf_registered_at<@start_t_month then id end),0) as [Число лидов t-1]
        ,isnull(count(case when uf_registered_at>=@start_t_month then id end),0) as [Число лидов t]

        ,isnull(count(case when UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end)
        /nullif(cast(count(case when uf_registered_at>=@start_t_2_month and uf_registered_at<@start_t_1_month then id end) as float)  ,0),0) as [Конверсия лид - выдача t-2]
        ,isnull(count(case when UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end)
        /nullif(cast(count(case when uf_registered_at>=@start_t_1_month and uf_registered_at<@start_t_month then id end) as float)  ,0),0) as [Конверсия лид - выдача t-1]
        ,isnull(count(case when UF_ISSUED_AT>=@start_t_month then UF_SUM_ACCEPTED end)
        /nullif(cast(count(case when uf_registered_at>=@start_t_month then id end) as float) ,0),0) as [Конверсия лид - выдача t]

        ,isnull(count(case when uf_type like '%api%' and uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_2_month and UF_ACTUALIZE_AT<@start_t_1_month then uf_row_id end),0) as [Число заявок с api t-2]
        ,isnull(count(case when uf_type like '%api%' and uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_1_month and UF_ACTUALIZE_AT<@start_t_month then uf_row_id end),0) as [Число заявок с api t-1]
        ,isnull(count(case when uf_type like '%api%' and uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_month then uf_row_id end),0) as [Число заявок с api t]		

        ,isnull(count(case when uf_type not like '%api%' and uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_2_month and UF_ACTUALIZE_AT<@start_t_1_month then uf_row_id end),0) as [Число заявок без api t-2]
        ,isnull(count(case when uf_type not like '%api%' and uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_1_month and UF_ACTUALIZE_AT<@start_t_month then uf_row_id end),0) as [Число заявок без api t-1]
        ,isnull(count(case when uf_type not like '%api%' and uf_row_id is not null and UF_ACTUALIZE_AT>=@start_t_month then uf_row_id end),0) as [Число заявок без api t]		

        ,isnull(count(case when uf_target=1 and uf_loginom_status='accepted' and uf_registered_at>=@start_t_2_month and uf_registered_at<@start_t_1_month then id end),0) as [Число лидов с uf_target=1 и uf_loginom_status='accepted' t-2]
        ,isnull(count(case when uf_target=1 and uf_loginom_status='accepted' and uf_registered_at>=@start_t_1_month and uf_registered_at<@start_t_month then id end),0) as [Число лидов с uf_target=1 и uf_loginom_status='accepted' t-1]
        ,isnull(count(case when uf_target=1 and uf_loginom_status='accepted' and uf_registered_at>=@start_t_month then id end),0) as [Число лидов с uf_target=1 и uf_loginom_status='accepted' t]

		
        ,isnull(sum(case when UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end)
        /nullif(cast(count(case when UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end) as float)  ,0),0) as [Средний чек t-2]
        ,isnull(sum(case when UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end)
        /nullif(cast(count(case when UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end) as float)  ,0),0) as [Средний чек t-1]
        ,isnull(sum(case when UF_ISSUED_AT>=@start_t_month  then UF_SUM_ACCEPTED end)
        /nullif(cast(count(case when UF_ISSUED_AT>=@start_t_month then UF_SUM_ACCEPTED end) as float) ,0),0) as [Средний чек t]

        ,isnull(count(case when UF_REGIONS_COMPOSITE like '%моск%' and UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end),0) as [Число займов из М,МО t-2]
        ,isnull(count(case when UF_REGIONS_COMPOSITE like '%моск%' and UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end),0) as [Число займов из М,МО t-1]
        ,isnull(count(case when UF_REGIONS_COMPOSITE like '%моск%' and UF_ISSUED_AT>=@start_t_month then UF_SUM_ACCEPTED end),0) as [Число займов из М,МО t]

		,isnull(sum(case when UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end),0) as [Сумма займов не из М,МО t-2]
        ,isnull(sum(case when UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end),0) as [Сумма займов не из М,МО t-1]
        ,isnull(sum(case when UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_month then UF_SUM_ACCEPTED end),0) as [Сумма займов не из М,МО t]

		,isnull(sum(case when UF_SUM_ACCEPTED<=200000 and UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end),0) as [Сумма займов <=200000 не из М,МО t-2]
        ,isnull(sum(case when UF_SUM_ACCEPTED<=200000 and UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end),0) as [Сумма займов <=200000 не из М,МО t-1]
        ,isnull(sum(case when UF_SUM_ACCEPTED<=200000 and UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_month then UF_SUM_ACCEPTED end),0) as [Сумма займов <=200000 не из М,МО t]

        ,isnull(sum(case when UF_SUM_ACCEPTED>200000 and UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_2_month and UF_ISSUED_AT<@start_t_1_month then UF_SUM_ACCEPTED end),0) as [Сумма займов >200000 не из М,МО t-2]
        ,isnull(sum(case when UF_SUM_ACCEPTED>200000 and UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_1_month and UF_ISSUED_AT<@start_t_month then UF_SUM_ACCEPTED end),0) as [Сумма займов >200000 не из М,МО t-1]
        ,isnull(sum(case when UF_SUM_ACCEPTED>200000 and UF_REGIONS_COMPOSITE not like '%моск%' and UF_ISSUED_AT>=@start_t_month then UF_SUM_ACCEPTED end),0) as [Сумма займов >200000 не из М,МО t]


from #lcrm_t_2 lcrm_outer
where lcrm_outer.uf_source=lidg.uf_source) x

begin tran
delete from dbo.dm_report_lcrm_cpa_costs
insert into dbo.dm_report_lcrm_cpa_costs
select * from #table4
commit tran


end


--exec Proc_CreatTable_Agr_IntRate_v1
CREATE  PROCEDURE [dbo].[reportVerification_RequestReasonReject] 
	-- Add the parameters for the stored procedure here


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT distinct appl_date [дата]
,dec_datetime дата_отказа
   , [external_id] [номер заявки]
,[return_type][тип]

,[UW_VDC] [сотрудник]
   ,reject_reason
,[last_name] [Фамилия]
,[first_name] [имя]
,[middle_name] [отчество]
, [group]

FROM [dbo].[dm_MainData] a
left join (
select number, [group] from(
select  number, [group], row_number() over (partition by number order by stage_date desc ) rn
from 
	--[LoginomDB].[dbo].WorkFlow
	stg._loginom.WorkFlow --Переписали в рамках задачи DWH-1140
) a 
where rn=1)  b on cast(a.external_id as nvarchar(70)) = cast(b.Number as nvarchar(70))
left join (
select distinct request_id,app_datetime,dec_datetime from (
select request_id, case when status = 8 then cast(stage_time as date)end app_datetime,
case when status in(12,14) then cast(stage_time as date) end dec_datetime
from dwh_new.dbo.requests_history) a
where app_datetime is not null or dec_datetime is not null) s  on s.request_id=a.request_id

where month(appl_date) = (case 
						 when day(CURRENT_TIMESTAMP) = 1  then month(CURRENT_TIMESTAMP)-1
						 else month(CURRENT_TIMESTAMP)
						 end)
						 and  year(appl_date)=year(CURRENT_TIMESTAMP)
						 and reject_reason not like 'NaN'

/*
----- '2020-04-01'
where month(appl_date) = month(CURRENT_TIMESTAMP)  and  year(appl_date)=year(CURRENT_TIMESTAMP)
and reject_reason not like 'NaN'
*/

/*
----- '2020-02-26'
SELECT appl_date [дата]
		, [external_id] [номер заявки]
		, [return_type][тип]

		, [UW_VDC] [сотрудник]
		, reject_reason
		, [last_name] [Фамилия]
		, [first_name] [имя]
		, [middle_name] [отчество]
		, [group]

FROM [dbo].[dm_MainData] a
left join (
select number, [group] from(
select  number, [group], row_number() over (partition by number order by stage_date desc ) rn
from [LoginomDB].[dbo].WorkFlow) a 
where rn=1)  b on cast(a.external_id as nvarchar(70)) = cast(b.Number as nvarchar(70))

where month(appl_date)=month(CURRENT_TIMESTAMP) and  year(appl_date)=year(CURRENT_TIMESTAMP)
and reject_reason not like 'NaN'
*/

/*

----- '2020-02-12'
SELECT	appl_date [дата]
		, [external_id] [номер заявки]
		,[return_type][тип]

		,[UW_VDC] [сотрудник]
		,reject_reason
		,[last_name] [Фамилия]
		,[first_name] [имя]
		,[middle_name] [отчество]

FROM [dbo].[dm_MainData]

where month(appl_date)=month(CURRENT_TIMESTAMP) and  year(appl_date)=year(CURRENT_TIMESTAMP)
--where month(appl_date)=datepart(mm ,dateadd(month,-1,getdate())) and  year(appl_date)=datepart(yyyy ,dateadd(month,-1,getdate()))
		and reject_reason not like 'NaN'
order by 1 desc
*/
/*
-- '2020-01-24'
SELECT appl_date [дата]
   , [external_id] [номер заявки]
,[return_type][тип]

,[UW_VDC] [сотрудник]
   ,reject_reason
,[last_name] [Фамилия]
,[first_name] [имя]
,[middle_name] [отчество]
 

FROM [dbo].[dm_MainData]
where appl_date>=dateadd(DAY,-7,cast(CURRENT_TIMESTAMP as date))
and reject_reason not like 'NaN'
*/
 
 END


--exec Proc_CreatTable_Agr_IntRate_v1
CREATE  PROCEDURE [dbo].[reportCollection_AmountsDueByTerm]	-- Суммы задолженности и количество договоров по сроку
	-- Add the parameters for the stored procedure here

@PageNo int
--, @dtFrom date 
--, @dtTo date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
if @PageNo=1

with t1 as 
(
select [external_id]
      ,[cdate]

      ,[default_date]
      --,[default_date_year]
      --,[default_date_month]
	  ,case
			when [days_from_default] is null or [days_from_default]=0  then 1
			when [days_from_default] between 1 and 30 then 2
			when [days_from_default] between 31 and 60 then 3
			when [days_from_default] between 61 and 90 then 4
			when [days_from_default] between 91 and 360 then 5
			when [days_from_default] > 360 then 6
	  end as [Строка]
	  ,case
			when [days_from_default] is null or [days_from_default]=0  then N'0'
			when [days_from_default] between 1 and 30 then N'1-30'
			when [days_from_default] between 31 and 60 then N'31-60'
			when [days_from_default] between 61 and 90 then N'61-90'
			when [days_from_default] between 91 and 360 then N'91-360'
			when [days_from_default] > 360 then N'360+'
	  end as [Бакет]
      ,[days_from_default]
      ,[amount]


      ,[principal_acc_run]
      ,[principal_cnl_run]
	  ,isnull([principal_acc_run],0)-isnull([principal_cnl_run],0) as curr_debt
      --,[percents_acc_run]
      --,[percents_cnl_run]
      --,[fines_acc_run]
      --,[fines_cnl_run]
      --,[overpayments_cnl_run]
      --,[otherpayments_cnl_run]

      ,[principal_rest]
      ,[percents_rest]
      ,[fines_rest]
      --,[other_payments_rest]
      --,[total_rest]
	  ,(isnull([principal_acc_run],0)-isnull([principal_cnl_run],0)+isnull([percents_rest],0)+isnull([fines_rest],0)) as [result_debt]
      --,[principal_rest_wo]
      --,[percents_rest_wo]
      --,[fines_rest_wo]
      --,[total_rest_wo]

      --,[overdue_days]
      --,[overdue]
	  ,case
			when [overdue_days_p] = 0 then 1
			when [overdue_days_p] between 1 and 30  then 2
			when [overdue_days_p] between 31 and 60 then 3
			when [overdue_days_p] between 61 and 90 then 4
			when [overdue_days_p] between 91 and 360 then 5
			when [overdue_days_p] > 360 then 6
	  end as [Строка_2]
	  ,case
			when [overdue_days_p] = 0 then N'0'
			when [overdue_days_p] between 1 and 30 then N'1-30'
			when [overdue_days_p] between 31 and 60 then N'31-60'
			when [overdue_days_p] between 61 and 90 then N'61-90'
			when [overdue_days_p] between 91 and 360 then N'91-360'
			when [overdue_days_p] > 360 then N'360+'
	  end as [Бакет_2]
      ,[overdue_days_p]
	  ,bd.[name] as [НазваниеБакета]

      --,[bucket_id]
      --,[overdue_days_flowrate]
      ,[active_credit]
      --,[end_date]

      --,[real_paymen_amount]
      --,[total_CF]
      ,[is_hard]
      --,[writeoff_status]
from [dwh_new].[dbo].[stat_v_balance2] b 	
left join [dwh_new].[dbo].[bucket_days] bd on b.[overdue_days_p] between [min_days] and [max_days]
where [cdate]= cast(getdate() as date) --cast(dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) as date)		-- cast(getdate() as date) 
		and [active_credit]=1 --and 
)
,	t2 as 
(
select cast(getdate() as date) as [Дата] ,[Строка_2] as [Строка] ,[Бакет_2] as [Бакет] 
		,count(distinct [external_id]) as [Колво_договоров] 
		,cast(sum([principal_rest]) as numeric(15,2)) as [СуммаБаланса]
		,cast(sum(curr_debt) as numeric(15,2)) as [СуммаПросрЗадолж]
		,cast(sum([percents_rest]) as numeric(15,2)) as [СуммаПросрПроц]
		,cast(sum([fines_rest]) as numeric(15,2)) as [Сумма пеней]
		,cast(sum([result_debt]) as numeric(15,2)) as [ИтоговаяСуммаПроср]
from t1
where not [external_id] is null or [external_id]<>N''
group by [Бакет_2] ,[Строка_2]
)
select * from t2 -- where [Бакет_0] is null
order by 2


if @PageNo=2

with t1 as 
(
select [external_id]
      ,[cdate]

      ,[default_date]
      --,[default_date_year]
      --,[default_date_month]
	  ,case
			when [days_from_default] is null or [days_from_default]=0  then 1
			when [days_from_default] between 1 and 30 then 2
			when [days_from_default] between 31 and 60 then 3
			when [days_from_default] between 61 and 90 then 4
			when [days_from_default] between 91 and 360 then 5
			when [days_from_default] > 360 then 6
	  end as [Строка]
	  ,case
			when [days_from_default] is null or [days_from_default]=0  then N'0'
			when [days_from_default] between 1 and 30 then N'1-30'
			when [days_from_default] between 31 and 60 then N'31-60'
			when [days_from_default] between 61 and 90 then N'61-90'
			when [days_from_default] between 91 and 360 then N'91-360'
			when [days_from_default] > 360 then N'360+'
	  end as [Бакет]
      ,[days_from_default]
      ,[amount]


      ,[principal_acc_run]
      ,[principal_cnl_run]
	  ,isnull([principal_acc_run],0)-isnull([principal_cnl_run],0) as curr_debt
      --,[percents_acc_run]
      --,[percents_cnl_run]
      --,[fines_acc_run]
      --,[fines_cnl_run]
      --,[overpayments_cnl_run]
      --,[otherpayments_cnl_run]

      ,[principal_rest]
      ,[percents_rest]
      ,[fines_rest]
      --,[other_payments_rest]
      --,[total_rest]
	  ,(isnull([principal_acc_run],0)-isnull([principal_cnl_run],0)+isnull([percents_rest],0)+isnull([fines_rest],0)) as [result_debt]
      --,[principal_rest_wo]
      --,[percents_rest_wo]
      --,[fines_rest_wo]
      --,[total_rest_wo]

      --,[overdue_days]
      --,[overdue]
	  ,case
			when [overdue_days_p] = 0 then 1
			when [overdue_days_p] between 1 and 30  then 2
			when [overdue_days_p] between 31 and 60 then 3
			when [overdue_days_p] between 61 and 90 then 4
			when [overdue_days_p] between 91 and 360 then 5
			when [overdue_days_p] > 360 then 6
	  end as [Строка_2]
	  ,case
			when [overdue_days_p] = 0 then N'0'
			when [overdue_days_p] between 1 and 30 then N'1-30'
			when [overdue_days_p] between 31 and 60 then N'31-60'
			when [overdue_days_p] between 61 and 90 then N'61-90'
			when [overdue_days_p] between 91 and 360 then N'91-360'
			when [overdue_days_p] > 360 then N'360+'
	  end as [Бакет_2]
      ,[overdue_days_p]
	  ,bd.[name] as [НазваниеБакета]

      --,[bucket_id]
      --,[overdue_days_flowrate]
      ,[active_credit]
      --,[end_date]

      --,[real_paymen_amount]
      --,[total_CF]
      ,[is_hard]
      --,[writeoff_status]
from [dwh_new].[dbo].[stat_v_balance2] b 	
left join [dwh_new].[dbo].[bucket_days] bd on b.[overdue_days_p] between [min_days] and [max_days]
where [cdate] = cast(getdate() as date) --cast(dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) as date)		-- cast(getdate() as date) 
		and [active_credit]=1 --and 
)

,	t2 as 
(
select cast(getdate() as date) as [Дата] 
		,[external_id] as [Строка]
		,[Бакет_2] as [Бакет]
		,count(distinct [external_id]) as [Колво_договоров] 
		,cast(sum([principal_rest]) as numeric(15,2)) as [СуммаБаланса]
		,cast(sum(curr_debt) as numeric(15,2)) as [СуммаПросрЗадолж]
		,cast(sum([percents_rest]) as numeric(15,2)) as [СуммаПросрПроц]
		,cast(sum([fines_rest]) as numeric(15,2)) as [Сумма пеней]
		,cast(sum([result_debt]) as numeric(15,2)) as [ИтоговаяСуммаПроср]

from t1
where not [external_id] is null or [external_id]<>N''
group by [Бакет_2] ,[external_id]
)

select * from t2 -- where [Бакет_0] is null
order by 1

 
 END
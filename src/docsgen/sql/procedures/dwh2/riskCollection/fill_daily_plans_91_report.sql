CREATE procedure [riskCollection].[fill_daily_plans_91_report] as 
begin

if (select max(rep_dt_month) from riskCollection.daily_plans_91) < DATEFROMPARTS(year(getdate()),month(getdate()),1)

begin
	truncate table riskcollection.daily_plans_91_report;
	insert into riskcollection.daily_plans_91_report
	select 
	rep_dt_month ,	type1 ,	case when type2 is null then '' else type2 end type2,	bucket , План, product
	from riskCollection.daily_plans_91
	where rep_dt_month >= dateadd(mm,-13,DATEFROMPARTS(year(getdate()), month(getdate()), 1));

	insert into riskcollection.daily_plans_91_report 
	select 
	DATEFROMPARTS(year(getdate()),month(getdate()),1) as rep_dt_month ,	type1 , case when type2 is null then '' else type2 end type2
	,bucket , План, product
	from dwh2.riskCollection.daily_plans_91
	where rep_dt_month = (select max(rep_dt_month) from riskCollection.daily_plans_91)
	and rep_dt_month >= dateadd(mm,-13,DATEFROMPARTS(year(getdate()), month(getdate()), 1));
end

else 
	begin
	truncate table riskcollection.daily_plans_91_report;
	insert into riskcollection.daily_plans_91_report
	select 
	rep_dt_month,	type1,	case when type2 is null then '' else type2 end type2,bucket, План, product
	from riskCollection.daily_plans_91
	where rep_dt_month >= dateadd(mm,-13,DATEFROMPARTS(year(getdate()), month(getdate()), 1));
end

end
-- exec [collection].[fillDpd91PtsInstallmentPdl];
-- select * from [collection].[Dpd91PtsInstallmentPdl]
CREATE PROCEDURE [collection].[fillDpd91PtsInstallmentPdl]
AS
BEGIN
declare @dtTo date = '2021-01-01'
	,@dtFrom date  = getdate()

begin try
	drop table if exists #d_dpd91;
	select
		external_id,
		[Тип Продукта] as product_type,
		dateadd(dd,1, EOMONTH(min(d), -1)) as d,
		min(d) as dpd91_entry_date
	 into #d_dpd91
	 from dwh2.[dbo].[dm_CMRStatBalance] t
	where t.d between @dtTo and @dtFrom
	and dpd = '91' 
	group by 
		external_id, [Тип Продукта];

	drop table if exists #last_dt;
	select 
		dpd91.product_type,
		dateadd(dd,1, EOMONTH(min(dpd91.d), -1))	as min_dpd91_dt,
		format(t.d, 'yyyy-MM')						as [месяц поступление др],
		sum(isnull(t.[сумма поступлений],0))		as [сумма поступлений]
	into #last_dt
	from 
		dwh2.dbo.dm_CMRStatBalance t
		inner join 
		#d_dpd91 dpd91 on dpd91.external_id = t.external_id
						and t.d >= dpd91.dpd91_entry_date
	group by 
		dpd91.product_type,
		format(dpd91.d, 'yyyy-MM'), 
		format(t.d, 'yyyy-MM')
	order by 
		1,2,3;

	drop table if exists #od_dpd91;
	select
		t.[Тип Продукта] as product_type,
		dateadd(dd,1, EOMONTH(min(d), -1)) as d,
		--t.external_id, t.d, [сумма поступлений], t.[Тип Продукта], dpd, [dpd day-1],
		sum(isnull(t.[остаток од],0)) as [остаток од]
		--isnull(t.[остаток од],0) as [остаток од]
		into #od_dpd91
	from 
		dwh2.[dbo].[dm_CMRStatBalance] t
	where 
		t.d between @dtTo and @dtFrom
		and 
		dpd = 91 
	group by  
		t.[Тип Продукта], format(t.d, 'yyyy-MM')
	order by 
		1,2;


	drop table if exists #final_table;
	select 
		t.product_type,
		t.min_dpd91_dt,
		t.[месяц поступление др],
		t.[сумма поступлений],
		od.[остаток од],
		sum_pay_cumulatively = coalesce(sum(t.[сумма поступлений]) over (partition by t.product_type, t.min_dpd91_dt order by t.[месяц поступление др] 
												 rows between unbounded preceding and current row) ,0),
		Процент = ((coalesce(sum(t.[сумма поступлений]) over (partition by t.product_type, t.min_dpd91_dt order by t.[месяц поступление др] 
												 rows between unbounded preceding and current row) ,0))/ [остаток од] *100),
		[Номер месяца] = coalesce(count(t.[сумма поступлений]) over (partition by t.product_type, t.min_dpd91_dt order by t.[месяц поступление др] 
												 rows between unbounded preceding and current row) ,0) 
	into #final_table											 
	from 
		#last_dt t 
		left join  
		#od_dpd91 od on t.product_type = od.product_type and  t.min_dpd91_dt = od.d
	order by 
		1,2,3;

	drop table if exists #result_Dpd91PtsInstallmentPdl;
	select 
		t.*
		,od.[остаток од] as rest_debt_body
	into #result_Dpd91PtsInstallmentPdl
	from 
		#final_table t 
		left join  
		#od_dpd91 od on t.product_type = od.product_type and t.min_dpd91_dt = od.d and t.[Номер месяца]='1'
	order by 
		1,2,3;
--select * from #result_Dpd91PtsInstallmentPdl;
		--drop table collection.Dpd91PtsInstallmentPdl;
		if OBJECT_ID('collection.Dpd91PtsInstallmentPdl') is null
		begin
			select top(0) *
			into collection.Dpd91PtsInstallmentPdl
			from #result_Dpd91PtsInstallmentPdl
			CREATE NONCLUSTERED INDEX IX_Dpd91PtsInstallmentPdl_min_dpd91_dt
			ON collection.Dpd91PtsInstallmentPdl (min_dpd91_dt);
		end

		begin tran
			delete t from collection.Dpd91PtsInstallmentPdl t;
			insert into collection.Dpd91PtsInstallmentPdl
			select
				*
			from #result_Dpd91PtsInstallmentPdl			
		commit tran

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
		
END;
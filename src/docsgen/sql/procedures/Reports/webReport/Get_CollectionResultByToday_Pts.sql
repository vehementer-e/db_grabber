
CREATE     procedure [webReport].[Get_CollectionResultByToday_Pts]
	WITH EXECUTE AS 'dbo'
as
begin
SET NOCOUNT ON;
begin try
	select 
	dataOnDateTime = ДатаОбновления
	,metricName	
		
	,value = cast(value as int)
	,[Order] = case MetricName
		when '1-30' then 1
		when '31-60' then 2
		when '61-90' then 3
		when 'Итого 1-90' then 4
		when 'Hard 0-90' then 5
		when '91-360' then 6
		when '361+' then 7
		when 'Итого 91+' then 8
		when 'Итого 1+' then 9
		end
	from 
	(select 
		ДатаОбновления =cast(ДатаОбновления as smalldatetime),
		[1-30] =	cast(t2_1_3 as money) --1-30 [Sum(t2_1_3)]
		,[31-60] = cast(t2_2_3 as money) --[Sum(t2_2_3)]
		,[61-90] = cast(t2_3_3 as money)-- [Sum(t2_3_3)]
		,[Hard 0-90] = cast(t2_3a_3 as money) --[Sum(t2_3a_3)]
		,[91-360] = cast(t2_4_3 as money) --	[Sum(t2_4_3)]
		,[361+ ] = cast(t2_5_3 as money) -- [Sum(t2_5_3)]
		,[Итого 1-90]=  cast(t2_6_3 as money) --[Sum(t2_6_3)]
		,[Итого 91+] = cast(t2_7_3 as money) --[Sum(t2_7_3)]
		,[Итого 1+] = cast(t2_8_3 as money) --[Sum(t2_8_3)]

	from dbo.dm_dashboard_Collection_v02_new_save_balance
	) t
	UNPIVOT   
		(Value FOR MetricName 
			IN   ([1-30], [31-60], [61-90], [Hard 0-90],[91-360],[361+ ],[Итого 1-90],[Итого 91+], [Итого 1+]   )) 
			as unpvt
	order by [Order]
end try
begin catch
	;throw
end catch
end
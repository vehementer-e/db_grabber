CREATE     proc [_birs].[leads_online_report] @mode nvarchar(max) = ''
as
begin

if @mode = 'Request1'

begin

SELECT   [crd_d]
        ,[end_t]
		,[Группа каналов]
		,[Канал от источника]
		,[is_inst_lead]   
		,[IsInstallment]     
		,[CompanyNaumen]     
		,[Поступило лидов]      
		,[Обработано лидов]     
		,[Дозвонились]     
		,[Лидов Feodor]      
		,[Профильных лидов Feodor]      
		,[Создано заявок]
		,UF_SOURCE   UF_SOURCE 
		,[UF_PARTNER_ID аналитический] [UF_PARTNER_ID аналитический]
		,isPdl  
FROM [Feodor].[dbo].[dm_leads_history_online_current_day_by_hours] 
where crd_d>getdate()-14  

--union all  
--
--SELECT   [crd_d]     
--        ,[end_t]      
--		,[Группа каналов]      
--		,[Канал от источника]      
--		,[is_inst_lead]      
--		,[IsInstallment]      
--		,[CompanyNaumen]     
--		,[Поступило лидов]     
--		,[Обработано лидов]      
--		,[Дозвонились]      
--		,[Лидов Feodor]      
--		,[Профильных лидов Feodor]      
--		,[Создано заявок]
--		,UF_SOURCE   UF_SOURCE 
--		,[UF_PARTNER_ID аналитический] [UF_PARTNER_ID аналитический]
--		,isPdl
--FROM [Feodor].[dbo].[dm_leads_history_by_hours] 
--where crd_d<getdate()-3

end



if @mode = 'Request2'

begin

select * ,h_join = case when h is null then ch else h end  
from (select isnull(cast( cast(h as time(0)) as nvarchar(max)), 'Последний срез') h_text,* 
    ,(select max(end_t) h_last from Feodor.dbo.dm_leads_history_online_current_day_by_hours 
      where crd_d = (select max(crd_d) from  Feodor.dbo.dm_leads_history_online_current_day_by_hours)) ch  
	  from (select cast('00:00:00' as time(0)) h 
	  union all select cast('01:00:00' as time)
	  union all select cast('02:00:00' as time)
	  union all select cast('03:00:00' as time)
	  union all select cast('04:00:00' as time)
	  union all select cast('05:00:00' as time)
	  union all select cast('06:00:00' as time)
	  union all select cast('07:00:00' as time)
	  union all select cast('08:00:00' as time)
	  union all select cast('09:00:00' as time)
	  union all select cast('10:00:00' as time)
	  union all select cast('11:00:00' as time)
	  union all select cast('12:00:00' as time)
	  union all select cast('13:00:00' as time)
	  union all select cast('14:00:00' as time)
	  union all select cast('15:00:00' as time)
	  union all select cast('16:00:00' as time)
	  union all select cast('17:00:00' as time)
	  union all select cast('18:00:00' as time)
	  union all select cast('19:00:00' as time)
	  union all select cast('20:00:00' as time)
	  union all select cast('21:00:00' as time)
	  union all select cast('22:00:00' as time)
	  union all select cast('23:00:00' as time) 
	  union all select cast('23:59:59' as time) 
	  union all select null)x)x

end



if @mode = 'Request3'

begin

select cast('00:00:00' as time) h 
union all  select cast('01:00:00' as time)  
union all  select cast('02:00:00' as time)  
union all  select cast('03:00:00' as time)  
union all  select cast('04:00:00' as time)  
union all  select cast('05:00:00' as time)  
union all  select cast('06:00:00' as time)  
union all  select cast('07:00:00' as time)  
union all  select cast('08:00:00' as time)  
union all  select cast('09:00:00' as time)  
union all  select cast('10:00:00' as time)  
union all  select cast('11:00:00' as time)  
union all  select cast('12:00:00' as time)  
union all  select cast('13:00:00' as time)  
union all  select cast('14:00:00' as time)  
union all  select cast('15:00:00' as time)  
union all  select cast('16:00:00' as time)  
union all  select cast('17:00:00' as time)  
union all  select cast('18:00:00' as time)  
union all  select cast('19:00:00' as time)  
union all  select cast('20:00:00' as time)  
union all  select cast('21:00:00' as time)  
union all  select cast('22:00:00' as time)  
union all  select cast('23:00:00' as time) 
union all  select cast('23:59:59' as time)

end

end
CREATE   proc [_birs].[organic_sources]

as
begin



drop table if exists #ret											

select Возврат, [Дата лида], [Выданная сумма возврат], [Заем выдан возврат], id into #ret from v_feodor_leads											
where Возврат is not null											
											
											
	
											
drop table if exists #fa											
											
select 											
       Номер											
	   , case when [Вид займа]='Параллельный' then 'Докредитование' else [Вид займа] end [Вид займа]										
	   , [Канал от источника]										
	   , [Верификация КЦ]										
	   										
	   ,cast(format( [Заем выдан], 'yyyy-MM-01') as date)  [Заем выдан месяц]										
	   , [Место cоздания]										
	   , [Выданная сумма]										
	   , [Заем выдан]										
	   , 1-isPts isInstallment										
	   , ДатаЗаявкиПолная										
	   , Телефон										
	   , dwh_new.dbo.getGUIDFrom1C_IDRREF([Ссылка клиент] ) [guid клиента] 		
	   ,[Категория повторного клиента]
	   into #fa										
from reports.dbo.dm_factor_analysis_001											
where [Группа каналов]='Органика' and [Заем выдан] is not null											
	
										
--exec select_table 'reports.dbo.dm_factor_analysis_001'
 

											
select a.Номер,											
a.[Заем выдан],											
cast(format(a.[Заем выдан], 'yyyy-MM-01') as date)  [Заем выдан месяц],											
 a.[Место cоздания],											
lh.[Канал от источника] [Канал от источника лида с возвратом],											
lh.uf_source [uf_source лида с возвратом],											
lh.id	[id лида с возвратом] ,

 case when datediff(day, r.[Дата лида], a.[Заем выдан] ) <=90 then 'Возврат через 0 - 90 дней' 
      when datediff(day, r.[Дата лида], a.[Заем выдан] ) >90 then 'Возврат через 91+ день'     end [Период возврата]
,lr.UF_TYPE	 
,lr.UF_SOURCE	  
,a.[Вид займа] 										
,a.[Выданная сумма] 										
,a.isInstallment 										
, isnull( case 											
											
when [Вид займа]='Первичный' then											
                                         case 											
										      when r.Возврат is not null then 'Возврат'	
										      when a.[Место cоздания] = 'Оформление в мобильном приложении' then 'МП'	
										      when a.[Место cоздания] = 'ЛКК клиента' then 'ЛКК'	
										      when a.[Место cоздания] = 'Ввод операторами LCRM' then 'Сайт'	
										      when lr.uf_source = 'lkk-event' then  'ЛКК'
										      when lr.uf_source = 'mobile-app-event' then  'МП'
										      when lr.uf_type = 'mobile_register' then  'МП'
										      when lr.uf_type = 'registry_mobile_app' then  'МП'
										      when a.[Канал от источника] = 'Сайт орган.трафик' then 'Сайт'	
											  else 'КЦ (остальные)'
									     end		
											
											
when [Вид займа]='Повторный' then											
                                        [Категория повторного клиента]											
											
when [Вид займа]='Докредитование' then											
                                        [Категория повторного клиента]										
											
										 end , '') [Источник органики]	
, [Вид займа]											
, GETDATE() created											
from #fa											
a																				
left join #ret r on r.Возврат=a.Номер											
left join feodor.dbo.dm_leads_history lh on lh.id=r.id									
left join stg._LCRM.lcrm_leads_full_channel_request lr on lr.UF_ROW_ID=a.Номер											
where a.[Заем выдан]>='20230101' -- and a.[Заем выдан]<='20230728' --and isInstallment=0		
--and a.[Вид займа]='Первичный'
--order by  [Источник органики]	, 	   UF_TYPE, 	 a.[Заем выдан] desc



end
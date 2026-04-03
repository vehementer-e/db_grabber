CREATE proc [_birs].[ttc_ssrs]

   @start_date_ssrs  	date
 , @end_date_ssrs 	  date
 ,  @work_hours_ssrs	int
as
begin




declare @start_date date  = cast(@start_date_ssrs as date)
declare @end_date date =    cast(@end_date_ssrs as date)
declare @work_hours int =   @work_hours_ssrs

--declare @work_hours int = 1	  declare @start_date date  = cast(getdate()-30 as date)  declare @end_date date = cast(getdate() as date)
--
--
--


drop table if exists #t1
select cast([Заем выдан] as date) [Заем выдан день], [Группа каналов], [Выданная сумма], [Канал от источника] [Канал от источника], Номер Номер , [Вид займа] ,   original_lead_id  into #t1 from v_fa
  where isPts=1	   and [Заем выдан] is not null
drop table if exists #t2

  select a.Номер, b.CompanyNaumen into #t2 from #t1 a
  join v_lead2 b on a.original_lead_id=b.id and b.CompanyNaumen in ('CRM Движок черновик', 'CRM Зависшие клиенты')	  and ФлагДозвонПоЛиду=1

--
  drop table if exists #fa

  select [Заем выдан день] [Заем выдан день]
  , case when [Группа каналов] ='CPC' then 1 else 0 end is_cpc
  , case when [Канал от источника] ='CPA целевой' then 1 else 0 end is_cpa_target
  , case when [Канал от источника] ='Триггеры' then 1 else 0 end is_triggers
  , case when [Вид займа] <>'Первичный' then 1 else 0 end is_repeated
  , case when b.CompanyNaumen ='CRM Движок черновик' then 1 else 0 end [is_CRM Движок черновик]
  , case when b.CompanyNaumen ='CRM Зависшие клиенты' then 1 else 0 end [is_CRM Зависшие клиенты]
  , sum([Выданная сумма]) [Выданная сумма]
  , count([Выданная сумма]) [Выданно займов]
  into #fa
  from #t1 a
  left join  #t2 b on a.Номер=b.Номер
 
   group by 
 [Заем выдан день]
  , case when [Группа каналов] ='CPC' then 1 else 0 end 
  , case when [Канал от источника] ='CPA целевой' then 1 else 0 end 
  , case when [Канал от источника] ='Триггеры' then 1 else 0 end 
  , case when [Вид займа] <>'Первичный' then 1 else 0 end 
  
  , case when b.CompanyNaumen ='CRM Движок черновик' then 1 else 0 end  
  , case when b.CompanyNaumen ='CRM Зависшие клиенты' then 1 else 0 end  

  ;



  with ttc as (




SELECT [Date]
      ,[Month]
      ,[Week]
      ,[projecttitle]
      ,case when @work_hours = 0 then [SumTime]                  else [SumTimeРабочееВремя]              end [SumTime]             
      ,case when @work_hours = 0 then [CountTime]                else [CountTimeРабочееВремя]			end	[CountTime]           
      ,case when @work_hours = 0 then [ПоступилоЛидов]           else [ПоступилоЛидовРабочееВремя]		end	[ПоступилоЛидов]      
      ,case when @work_hours = 0 then [ОбработаноДеньВДень]      else [ОбработаноДеньВДеньРабочееВремя]	end	[ОбработаноДеньВДень] 
      ,case when @work_hours = 0 then [Обработано]               else [ОбработаноРабочееВремя]			end	[Обработано]          
      ,case when @work_hours = 0 then [Дозвон]                   else [ДозвонРабочееВремя]				end	[Дозвон]              
      ,case when @work_hours = 0 then [ПотеряныхЗвонков]         else [ПотеряныхЗвонковРабочееВремя]		end	[ПотеряныхЗвонков]    
      ,case when @work_hours = 0 then Соединений         else СоединенийРабочееВремя		end	Соединений    
      ,case when @work_hours = 0 then [first_call_success]         else [first_call_success_work_time]		end	[first_call_success]    
      ,[created]
	  , SumTimeНеРабочееВремя	   [SumTime_НеРабочееВремя]
	  , CountTimeНеРабочееВремя	   [CountTime_НеРабочееВремя]
--      ,[projectuuid]
													-- select top 100 *
  FROM [Analytics].[dbo].[report_TTC_on_projects2]

  ) 
   select a.*,  x.[Выданно займов]  [Выданно займов] ,   x.[Выданная сумма]  [Выданная сумма]	   , b.[Приоритет]

  FROM ttc a
  outer apply (select  isnull(sum([Выданная сумма]), 0) [Выданная сумма], isnull(sum([Выданно займов]), 0) [Выданно займов]
 from #fa b where b.[Заем выдан день]=a.Date and
  case 
  when a.projecttitle='CPC' then b.is_cpc
  when a.projecttitle='Целевой' then b.is_cpa_target
  when a.projecttitle='Триггеры' then b.is_triggers
  when a.projecttitle='Докреды и повторники' then b.is_repeated
  when a.projecttitle='Движок черновик' then b.[is_CRM Движок черновик]
  when a.projecttitle='Зависшие клиенты' then b.[is_CRM Зависшие клиенты]
  end = 1

  )x 
 left join (select [Название проекта для отчета] Проект, max([Приоритет]) [Приоритет] from   _gsheets.[v_dic_Проекты TTC] group by [Название проекта для отчета]) b on a.projecttitle=b.Проект
 where Date between @start_date and @end_date


 end
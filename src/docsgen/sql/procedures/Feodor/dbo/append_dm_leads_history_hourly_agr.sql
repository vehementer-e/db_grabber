
CREATE     procedure  [dbo].[append_dm_leads_history_hourly_agr]
as 
begin

return

drop table if exists #t1

select 
       cast(format(getdate(), 'yyyy-MM-dd HH:00:00') as smalldatetime) СрезОтчета
	  ,GETDATE() as ТочноеВремяСозданияСреза
	  ,cast(getdate() as date) ДеньСрезаОтчета
	  ,[CompanyNaumen] 
	  ,count(id) id
	  ,count(ВремяПервойПопытки) ВремяПервойПопытки
	  ,sum([ФлагРазблокированнаяСессия]) [ФлагРазблокированнаяСессия]
	  ,sum([ФлагДозвонПоЛиду]) [ФлагДозвонПоЛиду]
	  ,sum([ФлагНедозвонПоЛиду]) [ФлагНедозвонПоЛиду]
	  ,sum([ЧислоПопыток]) [ЧислоПопыток]
	  ,sum([ПерезвонПоПоследнемуЗвонку]) [ПерезвонПоПоследнемуЗвонку]
	  ,sum([ФлагНепрофильный]) [ФлагНепрофильный]
      ,sum([ФлагНовый]) [ФлагНовый]
	  ,sum([ФлагПрофильныйИтог]) [ФлагПрофильныйИтог]
	  ,sum([ФлагПрофильный]) [ФлагПрофильный]
	  ,sum([ФлагОтправленВМП]) [ФлагОтправленВМП]
      ,sum([ФлагОтказКлиента]) [ФлагОтказКлиента]
      ,sum([ФлагДумает]) [ФлагДумает]
      ,sum([ФлагЗаявка]) [ФлагЗаявка]
	  ,count([ПредварительноеОдобрение]) [ПредварительноеОдобрение]
	  ,count([КонтрольДанных]) [КонтрольДанных]
	  ,count([Одобрено]) [Одобрено]
      ,count([ЗаемВыдан]) [ЗаемВыдан]
      ,sum([ВыданнаяСумма]) [ВыданнаяСумма]
	 into #t1
	    FROM Feodor.[dbo].[dm_leads_history] l
where [ДатаЛидаЛСРМ]=cast(getdate() as date)
group by 
	  [CompanyNaumen]

begin tran
insert into feodor.dbo.dm_leads_history_hourly_agr
select * from #t1


commit tran


drop table if exists #dates, #hours, #groups, #t2

drop table if exists #ch, #lc


declare @start_date date = getdate()-10
--declare @start_date date = '2019-09-20'
declare @delete_from date = @start_date


select @start_date d into #dates
set @start_date = dateadd(day, 1, @start_date)
while @start_date<=cast(getdate()-1 as date)
begin
insert into #dates
select @start_date
set @start_date = dateadd(day, 1, @start_date)

end

SELECT   [Канал от источника]
      ,[Группа каналов]
	  into #ch
  FROM [Stg].[files].[leadRef1_buffer]


  SELECT distinct [LaunchControlName] into #lc
FROM [Feodor].[dbo].[dm_feodor_projects]
union
select 'Не определен'












select cast('01:00:00' as time) h into #hours union all
select cast('02:00:00' as time)	union all
select cast('03:00:00' as time)	union all
select cast('04:00:00' as time)	union all
select cast('05:00:00' as time)	union all
select cast('06:00:00' as time)	union all
select cast('07:00:00' as time)	union all
select cast('08:00:00' as time)	union all
select cast('09:00:00' as time)	union all
select cast('10:00:00' as time)	union all
select cast('11:00:00' as time)	union all
select cast('12:00:00' as time)	union all
select cast('13:00:00' as time)	union all
select cast('14:00:00' as time)	union all
select cast('15:00:00' as time)	union all
select cast('16:00:00' as time)	union all
select cast('17:00:00' as time)	union all
select cast('18:00:00' as time)	union all
select cast('19:00:00' as time)	union all
select cast('20:00:00' as time)	union all
select cast('21:00:00' as time)	union all
select cast('22:00:00' as time)	union all
select cast('23:00:00' as time)


select * into #groups from #ch, #lc, #dates, #hours


select #groups.d 
      ,#groups.h		
      ,#groups.[LaunchControlName]		
      ,#groups.[Канал от источника]		
      ,#groups.[Группа каналов]		
	  ,count(case when  lh.creationdate between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) ПоступилоЛидов
	  ,count(case when datepart(HH, lh.creationdate)>=9 and lh.creationdate between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) ПоступилоЛидов_После9
	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ОбработаноЛидов
	  ,count(case when  datepart(HH, lh.creationdate)>=9  and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ОбработаноЛидов_После9
	  ,count(case when ВремяПервогоДозвона between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ДозвонилисьДоЛидов
	  ,count(case when datepart(HH, lh.creationdate)>=9  and ВремяПервогоДозвона between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ДозвонилисьДоЛидов_После9
	  ,count(case when lh.[FedorДатаЛида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЛидовФедор
	  ,count(case when datepart(HH, lh.creationdate)>=9  and lh.[FedorДатаЛида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЛидовФедор_После9
	  ,count(case when lh.[FedorДатаЛида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when ФлагПрофильныйИтог =1  then 1 end end) as СозданоПрофильныхЛидовФедор
	  ,count(case when datepart(HH, lh.creationdate)>=9  and lh.[FedorДатаЛида] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when ФлагПрофильныйИтог =1  then 1 end end) as СозданоПрофильныхЛидовФедор_После9
	  ,count(case when lh.ДатаЗаявкиПолная between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЗаявокCRM
	  ,count(case when datepart(HH, lh.creationdate)>=9  and lh.ДатаЗаявкиПолная between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as СозданоЗаявокCRM_После9
	  ,count(case when lh.[ПредварительноеОдобрение] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ПредварительноОдобреноCRM
	  ,count(case when lh.[КонтрольДанных] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as КонтрольДанныхCRM
	  ,count(case when lh.Одобрено between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ОдобреноCRM
	  ,count(case when lh.[ЗаемВыдан] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then 1 end) as ЗаемВыданCRM
	  ,sum(case when lh.[ЗаемВыдан] between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then lh.[ВыданнаяСумма] end) as СуммаВыдачиCRM
	  ,sum(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then cast(datediff(minute, creationdate, [ВремяПервойПопытки]) as bigint) end) as DateDiff$creationdate$ВремяПервойПопытки
	  ,sum(case when  datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then cast(datediff(minute, creationdate, [ВремяПервойПопытки]) as bigint) end) as DateDiff$creationdate$ВремяПервойПопытки_После9
	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] <= dateadd(second, 120, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_0min_to_2min]
	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] <= dateadd(second, 120, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_0min_to_2min_После9]
	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 120, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 300 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_2min_to_5min]
	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 120, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 300 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_2min_to_5min_После9]
	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 300, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 1800 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_5min_to_30min]
	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 300, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 1800 , creationdate) then [creationdate] end end) as [ВремяПервойПопытки_5min_to_30min_После9]
	  ,count(case when ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 1800, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_30min_and_more]
	  ,count(case when datepart(HH, lh.creationdate)>=9 and ВремяПервойПопытки between cast(#groups.d  as datetime) and  cast(#groups.d  as datetime) + cast(#groups.h  as datetime) then case when [ВремяПервойПопытки] > dateadd(second, 1800, creationdate) then [creationdate] end end) as [ВремяПервойПопытки_30min_and_more_После9]
	  ,getdate() as created
	  into #t2
	  from #groups
		 
left join feodor.dbo.dm_leads_history lh-- with(nolock)
on 
										cast(lh.creationdate as date) =#groups.d and
                                      
									    #groups.[LaunchControlName]  = lh.companynaumen
									   and #groups.[Канал от источника] = lh.[Канал от источника]
									   and #groups.[Группа каналов]     = lh.[Группа каналов]
  where cast(#groups.d  as datetime) + cast(#groups.h  as datetime)<getdate()
									   
group by 	#groups.d 
      ,#groups.h		
      ,#groups.[LaunchControlName]		
      ,#groups.[Канал от источника]		
      ,#groups.[Группа каналов]		
	  order by 	#groups.d 
      ,#groups.h		
      ,#groups.[LaunchControlName]		
      ,#groups.[Канал от источника]		
      ,#groups.[Группа каналов]		


	  begin tran
--	  drop table if exists feodor.dbo.dm_leads_history_running_value_by_hour
--	  select * into feodor.dbo.dm_leads_history_running_value_by_hour
--	  from #t2
	  
--	  CREATE CLUSTERED INDEX [ClusteredIndex-hour-and-date] ON [dbo].[dm_leads_history_running_value_by_hour]
--(
--	[d] ASC,
--	[h] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

	  
	  delete from feodor.dbo.dm_leads_history_running_value_by_hour where d>=@delete_from
	  insert into feodor.dbo.dm_leads_history_running_value_by_hour

	  select *
	  from #t2
	  commit tran

	  

 



end
CREATE     proc [_birs].[leads_feodor_ssrs]

@start_date date = null,
@end_date date = null

as
begin

SET CONCAT_NULL_YIELDS_NULL OFF;

declare @sql nvarchar(max) = '

set datefirst 1;
select 
       [Канал от источника]
      ,[Группа каналов]
,[UF_LOGINOM_PRIORITY]
,is_inst_lead
,case when ispdl=1 then -1 else isInstallment end 	 isInstallment
	  ,[CompanyNaumen]
,case when len(uf_source)=0 then  char(63) else uf_source end uf_source
, case when len(uf_source)=0 then  char(63) else uf_source end+char(160)+char(45)+char(160)+cast([UF_LOGINOM_PRIORITY] as varchar(10)) [source UF_LOGINOM_PRIORITY]

	  , ДатаЛидаЛСРМ Дата
	  ,cast(DATEADD(DD, 1 - DATEPART(DW, cast(ДатаЛидаЛСРМ as date) ), cast(ДатаЛидаЛСРМ as date) ) as date) as Неделя
, cast(dateadd(day, -datepart(day,ДатаЛидаЛСРМ)+1, ДатаЛидаЛСРМ) as date) Месяц
	  ,sum(id) ID
	  ,sum(ВремяПервойПопытки) ВремяПервойПопытки

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
	  ,sum([ПредварительноеОдобрение]) [ПредварительноеОдобрение]
	  ,sum([КонтрольДанных]) [КонтрольДанных]
	  ,sum([Одобрено]) [Одобрено]
      ,sum([ЗаемВыдан]) [ЗаемВыдан]
      ,sum([ВыданнаяСумма]) [ВыданнаяСумма]
	  ,sum(ВремяПервойПопытки_day_in_day) ВремяПервойПопытки_day_in_day
	  ,sum([ВремяПервойПопытки_0min_to_2min]) ВремяПервойПопытки_0min_to_2min
	  ,sum([ВремяПервойПопытки_2min_to_5min]) ВремяПервойПопытки_2min_to_5min
	  ,sum([ВремяПервойПопытки_5min_to_30min]) ВремяПервойПопытки_5min_to_30min
	  ,sum([ВремяПервойПопытки_30min_and_more]) ВремяПервойПопытки_30min_and_more

	    FROM [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] l
where [ДатаЛидаЛСРМ]>=cast('''+cast(cast(@start_date as date) as varchar)+''' as date) and [ДатаЛидаЛСРМ]<=cast('''+cast(cast(@end_date as date) as varchar)+''' as date)
group by 
       [Канал от источника]

,is_inst_lead
,case when ispdl=1 then -1 else isInstallment end 	  
,[UF_LOGINOM_PRIORITY]
      ,[Группа каналов]
	  ,[CompanyNaumen]
,ДатаЛидаЛСРМ 
,case when len(uf_source)=0 then  char(63) else uf_source end

union all

select 
       [Канал от источника]
      ,[Группа каналов]
,[UF_LOGINOM_PRIORITY]
,is_inst_lead
,case when ispdl=1 then -1 else isInstallment end 	 isInstallment
	  ,[CompanyNaumen]
,case when len(uf_source)=0 then  char(63) else uf_source end uf_source
, case when len(uf_source)=0 then  char(63) else uf_source end+char(160)+char(45)+char(160)+cast([UF_LOGINOM_PRIORITY] as varchar(10)) [source UF_LOGINOM_PRIORITY]

	  , ДатаЛидаЛСРМ Дата
	  ,cast(DATEADD(DD, 1 - DATEPART(DW, cast(ДатаЛидаЛСРМ as date) ), cast(ДатаЛидаЛСРМ as date) ) as date) as Неделя
, cast(dateadd(day, -datepart(day,ДатаЛидаЛСРМ)+1, ДатаЛидаЛСРМ) as date) Месяц
	  ,sum(id) ID
	  ,sum(ВремяПервойПопытки) ВремяПервойПопытки

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
	  ,sum([ПредварительноеОдобрение]) [ПредварительноеОдобрение]
	  ,sum([КонтрольДанных]) [КонтрольДанных]
	  ,sum([Одобрено]) [Одобрено]
      ,sum([ЗаемВыдан]) [ЗаемВыдан]
      ,sum([ВыданнаяСумма]) [ВыданнаяСумма]
	  ,sum(ВремяПервойПопытки_day_in_day) ВремяПервойПопытки_day_in_day
	  ,sum([ВремяПервойПопытки_0min_to_2min]) ВремяПервойПопытки_0min_to_2min
	  ,sum([ВремяПервойПопытки_2min_to_5min]) ВремяПервойПопытки_2min_to_5min
	  ,sum([ВремяПервойПопытки_5min_to_30min]) ВремяПервойПопытки_5min_to_30min
	  ,sum([ВремяПервойПопытки_30min_and_more]) ВремяПервойПопытки_30min_and_more

	    FROM [Feodor].[dbo].[lead_cube] l
where [ДатаЛидаЛСРМ]>=cast('''+cast(cast(@start_date as date) as varchar)+''' as date) and [ДатаЛидаЛСРМ]<=cast('''+cast(cast(@end_date as date) as varchar)+''' as date)
group by 
       [Канал от источника]

,is_inst_lead
,case when ispdl=1 then -1 else isInstallment end 	  
,[UF_LOGINOM_PRIORITY]
      ,[Группа каналов]
	  ,[CompanyNaumen]
,ДатаЛидаЛСРМ 
,case when len(uf_source)=0 then  char(63) else uf_source end

'

	  exec(@sql)

end
 create proc _birs.leads_and_returns_statistics_creation
 as begin





--"Выгрузка данных по трафику для оценки качества по вебам, со звонков и нет (аналогично тому как делал раньше) за 6-12 мес в дополнении к той табличке, которую смотрели: 
--Были ли лиды между лидом по нецелевому с ""алло"" и выдачей глубиной 30 дней другие лиды с ""алло"" 
--Глубина уникальности лида в рамках периода по бакетам с шагом неделя до месяца
--Какую часть лидов можно обогащать данными Спектрума из расчета 1,52 за запрос"


declare @start_date date = '20221101'
declare @data_start_date date = dateadd(day, -32, @start_date)



drop table if exists #t1				
select  IsInstallment, is_inst_lead,  id, UF_SOURCE,[UF_partner_id аналитический],ДатаЛидаЛСРМ
,  CompanyNaumen, [Группа каналов], [Канал от источника],creationdate
, UF_REGISTERED_AT
, UF_PHONE
, ВремяПервойПопытки
, ВремяПоследнейПопытки
,ВремяПервогоДозвона
, Номер
, ВыданнаяСумма 
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end канал

into #t1 from Feodor.dbo.dm_leads_history				
where   ДатаЛидаЛСРМ >=@data_start_date 

--select top 100  * from #t1

				

drop table if exists #allo			

select lcrm_id,   attempt_start, right(phonenumbers, 10) phonenumber into #allo   from Feodor.dbo.dm_calls_history a
where attempt_start	>=@data_start_date   and   login is not null	  



--select top 100  * from #секунды



drop table if exists #секунды				

select lcrm_id,   datediff(second, connected, attempt_end) секунды into #секунды   from Feodor.dbo.dm_calls_history a
where attempt_start	>=@data_start_date  and   datediff(second, connected, attempt_end)>0
				
--drop table if exists #r				
--select id, Возврат, [Выданная сумма возврат] into #r  from v_feodor_leads
--where Возврат is not null
 


drop table if exists #r1				
select id, Номер Возврат, [Выданная сумма] [Выданная сумма возврат] into #r1  from returns_references
where id is not null

 drop table if exists #r2				
select id, Номер Возврат, [Выданная сумма] [Выданная сумма возврат], ДатаЗаявкиПолная ДатаЗаявкиПолная into #r2  from returns_references2
where id is not null

                                             drop table if exists #repeat_7
select a.id, max(case when  t.id  is not null then 1 else 0 end )  repeat_7 
                                                             into #repeat_7	 from #t1 a	 left join  #t1 t  on t .uf_phone=a.uf_phone and t .ВремяПервойПопытки is not null and 
								t .UF_REGISTERED_AT between dateadd(day, -7,  a.UF_REGISTERED_AT ) and dateadd(second, -1, a.UF_REGISTERED_AT) where a.ВремяПервойПопытки is not null group by a.id

                                             drop table if exists #repeat_14
select a.id, max(case when  t.id  is not null then 1 else 0 end )  repeat_14 
                                                             into #repeat_14	 from #t1 a	 left join  #t1 t  on t .uf_phone=a.uf_phone and t .ВремяПервойПопытки is not null and 
								t .UF_REGISTERED_AT between dateadd(day, -14,  a.UF_REGISTERED_AT ) and dateadd(second, -1, a.UF_REGISTERED_AT) where a.ВремяПервойПопытки is not null group by a.id

                                             drop table if exists #repeat_21
select a.id, max(case when  t.id  is not null then 1 else 0 end )  repeat_21 
                                                             into #repeat_21	 from #t1 a	 left join  #t1 t  on t .uf_phone=a.uf_phone and t .ВремяПервойПопытки is not null and 
								t .UF_REGISTERED_AT between dateadd(day, -21,  a.UF_REGISTERED_AT ) and dateadd(second, -1, a.UF_REGISTERED_AT) where a.ВремяПервойПопытки is not null group by a.id

                                             drop table if exists #repeat_30
select a.id, max(case when  t.id  is not null then 1 else 0 end )  repeat_30 
                                                             into #repeat_30	 from #t1 a	 left join  #t1 t  on t .uf_phone=a.uf_phone and t .ВремяПервойПопытки is not null and 
								t .UF_REGISTERED_AT between dateadd(day, -30,  a.UF_REGISTERED_AT ) and dateadd(second, -1, a.UF_REGISTERED_AT) where a.ВремяПервойПопытки is not null group by a.id




--алло
--, max(case when allo.attempt_start is not null  then 1 else 0 end) [алло]
--, max(case when  allo_lead.uf_source =a.uf_source then 1 else 0 end) [алло тот же лидген]
--left join  #r2 b on a.id=b.id
--left join #алло allo on allo.phonenumber=a.uf_phone and allo.attempt_start between a.[ВремяПоследнейПопытки] and  b.ДатаЗаявкиПолная 



drop table if exists #allo_by_returns
select a.id
, max(case when allo.attempt_start is not null  then 1 else 0 end)        [алло между лидом и возвратом]
, max(case when allo_before.attempt_start is not null  then 1 else 0 end) [алло до лида с возвратом]
, max(case when  allo_lead.uf_source =a.uf_source then 1 else 0 end)      [алло тот же лидген]
 into #allo_by_returns	
 from #t1 a	 
 join  #r2 b on a.id=b.id
 left join #allo allo on allo.phonenumber=a.uf_phone and allo.attempt_start between a.[ВремяПоследнейПопытки] and  b.ДатаЗаявкиПолная  and allo.lcrm_id<>a.id
 left join #t1 allo_lead on allo_lead.id=allo.lcrm_id
 left join #allo allo_before on allo_before.phonenumber=a.uf_phone and allo_before.attempt_start between dateadd(day, -30 , a.uf_registered_at) and  a.[ВремяПервойПопытки] 	and allo_before.lcrm_id<>a.id

group by a.id





--select * from  #r2


--select * from  #r  except
--select * from  #r1 
--order by 2 desc


drop table if exists #секунды2			

select lcrm_id id, count(*) cnt_секунды, sum(секунды) секунды into #секунды2 from #секунды	
group by lcrm_id
				
select   				
  IsInstallment				
, is_inst_lead				
, UF_SOURCE				
, ДатаЛидаЛСРМ				
, CompanyNaumen				
, канал				
, [Группа каналов]				
, [Канал от источника]				
, [UF_partner_id аналитический]		
, allo_by_returns.[алло между лидом и возвратом]
, allo_by_returns.[алло до лида с возвратом]
, allo_by_returns.[алло тот же лидген]

,r_7 .repeat_7 
,r_14.repeat_14
,r_21.repeat_21
,r_30.repeat_30


, count(*                    ) [Всего лидов]				
, count(creationdate         ) [Загружено]				
, count(ВремяПервойПопытки	 ) [Обработано]			
, count(ВремяПервогоДозвона	 ) [Дозвон]			
, count(Номер				 ) [Заявок]
, count(ВыданнаяСумма		 ) [Займов со звонка]		
, sum(ВыданнаяСумма		     ) [Сумма Займов со звонка]		
, count(b2.[Выданная сумма возврат]		 )         [Займов возвраты]		
, sum(b2.[Выданная сумма возврат]		     ) [Сумма Займов возвраты]			
, count(b1.[Выданная сумма возврат]		 )         [Займов возвраты_OLD_METODOLOGY]		
, sum(b1.[Выданная сумма возврат]		     ) [Сумма Займов возвраты_OLD_METODOLOGY]		
, sum(секунды		     ) секунды		
, sum(cnt_секунды		     ) cnt_секунды		
into #t2				
from #t1 a				
--left join #r b on a.id=b.id		
left join #r1 b1 on a.id=b1.id		
left join #r2 b2 on a.id=b2.id		
left join #секунды2 c on c.id=a.id

left join #repeat_7  r_7  on r_7 .id=a.id
left join #repeat_14 r_14 on r_14.id=a.id
left join #repeat_21 r_21 on r_21.id=a.id
left join #repeat_30 r_30 on r_30.id=a.id
left join #allo_by_returns  allo_by_returns on allo_by_returns.id=a.id

where 	ДатаЛидаЛСРМ>= @start_date



group by 				

				
IsInstallment				
, is_inst_lead				
, UF_SOURCE				
,ДатаЛидаЛСРМ				
,  CompanyNaumen				
,канал				
, [Группа каналов]				
, [Канал от источника]				
, [UF_partner_id аналитический]		
, allo_by_returns.[алло между лидом и возвратом]
, allo_by_returns.[алло до лида с возвратом]
, allo_by_returns.[алло тот же лидген]

,r_7 .repeat_7 
,r_14.repeat_14
,r_21.repeat_21
,r_30.repeat_30
		

		select * from #t2


drop table if exists _birs.[leads_and_returns_statistics]
				
select * into  _birs.[leads_and_returns_statistics] from #t2		

--
--select * from 	  ##t2
--


end
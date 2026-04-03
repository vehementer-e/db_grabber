



-- =============================================
-- Author:		Petr Ilin
-- Create date: 04032020
-- Description:	Docredi i povtorniki v2.0
-- DWH-884
-- =============================================

CREATE       procedure  [dbo].[create_report_docr_i_povt2]
as 
begin

--24.03.2020
	SET DATEFIRST 1;

	drop table if exists #docrcases, #dist_cdates, #docrsessions, #fa, #dip_union,  #dip_union_gr_by_cdate_mobile, #clndr, #clndr_matching_dip_exports, #docrsessions_gr_by_phone_dt, #v_first_obzvon, #rg
;


select external_id
,      [group] fin_gr
into #rg
from [Stg].[dbo].[Dm_risk_groups_retro]
union


select cast(number as varchar(20)) external_id
,      fin_gr
from [Stg]._loginom.Dm_risk_groups

;





		   select '8'+ТелефонМобильный mobile, category, cdate, 'Докреды' as type , main_limit, external_id into #dip_union
		   from dwh_new.[dbo].[docredy_history]
		   union all
		   select '8'+ТелефонМобильный mobile, category, cdate, 'Повторники' as type , main_limit , external_id
		   from dwh_new.[dbo].povt_history

		   

		   
--уникальная связка срез от рисков - телефонный номер


		--   select cdate, mobile, max(main_limit) main_limit, 
		--   CHOOSE(
		--   min(case
		--			when [category]='Зеленый' then 1
		--			when [category]='Желтый' then 2
		--			when [category]='Синий' then 3
		--			when [category]='Оранжевый' then 4
		--			when [category]='Красный' then 5
		--		end
		-- ), 'Зеленый', 'Желтый', 'Синий', 'Оранжевый', 'Красный') [category], min(type)  type
		-- into #dip_union_gr_by_cdate_mobile1
		-- from #dip_union
		-- group by cdate, mobile


		 	   select cdate, mobile, max(main_limit) over(partition by cdate, mobile) main_limit, 
		   CHOOSE(
		   min(case
					when [category]='Зеленый' then 1
					when [category]='Желтый' then 2
					when [category]='Синий' then 3
					when [category]='Оранжевый' then 4
					when [category]='Красный' then 5
				end
		 )  over(partition by cdate, mobile), 'Зеленый', 'Желтый', 'Синий', 'Оранжевый', 'Красный')   [category], min(type)  over(partition by cdate, mobile)  type,
		 FIRST_VALUE(fin_gr) over (partition by  mobile order by case when fin_gr is not null then 1 else 0 end desc, dip.external_id desc) fin_gr,
		 ROW_NUMBER()  over(partition by cdate, mobile order by (select null)) rn 
		 into #dip_union_gr_by_cdate_mobile
		 from #dip_union dip left join #rg rg on rg.external_id=dip.external_id
	--	 group by cdate, mobile

		 delete from #dip_union_gr_by_cdate_mobile where rn>1

		 --составление календаря
		 declare @start_date date = '20190606'
		 create table #clndr
		 (dt date)
		 while @start_date<=getdate()+365
		 begin
		 insert into
		 #clndr
		 values (@start_date)
		 set @start_date = dateadd(day, 1, @start_date)
		 end


		 --для каждого дня года со старта докредов и повторников определяем ближайший срез от рисков
select distinct cdate into #dist_cdates  from #dip_union ;
select dt, (select top 1 cast(cdate as date) from #dist_cdates where cdate<=dt order by cdate desc) cdate into #clndr_matching_dip_exports from #clndr

--drop table if exists #fa
select '8'+Телефон Телефон, 
       Номер, 
	   [Вид займа], 
	   ДатаЗаявкиПолная, 
	   [Верификация КЦ], 
	   [Предварительное одобрение], 
	   [Контроль данных],  
	   [Верификация документов клиента], 
	   [Верификация документов], 
	   Одобрено, 
	   Отказано, 
	   [Отказ документов клиента], 
	   [Заем выдан],
	   [Выданная сумма],
	   creationd= cdate
	   into #fa
	   from reports.dbo.dm_Factor_Analysis_001
	   left join #clndr_matching_dip_exports on cast(ДатаЗаявкиПолная as date)=dt
where [Вид займа]<>'Первичный' and Дубль<>1;
 
 --оставляем уникальную связку телефон - срез от рисков
 with fa_v as
 (
 select *, ROW_NUMBER() over (partition by Телефон, creationd  order by 	   
       [Заем выдан] desc,
	   	    Одобрено desc, 
				   [Верификация документов] desc, 
				   	   [Верификация документов клиента] desc, 
					   	   [Контроль данных] desc,  
						   	   [Предварительное одобрение] desc, 
							   	   [Верификация КЦ] desc ) rn
								   from #fa
 )
 delete from fa_v where rn>1

 --смотрим на все звонки по кейсам докердов и повторников
		   drop table if exists #docr_cases_sessions
		   select  cc.creationdate, 
		           creationd= #clndr_matching_dip_exports.cdate,
		           cc.projectuuid, 
				   cc.projecttitle, 
				   cc.uuid, 
				   cc.phonenumbers,
				   dos.attempt_start,
				   dos.attempt_result,
				   dos.login
				   into #docr_cases_sessions
				 from  [Reports].[dbo].[dm_report_DIP_mv_call_case] cc 
				 left join [Reports].[dbo].[dm_report_DIP_detail_outbound_sessions] dos on dos.case_uuid=cc.uuid
				 left join  #clndr_matching_dip_exports on #clndr_matching_dip_exports.dt=cast(cc.creationdate as date)
				  ;


				  --определяем дату первого прозвона по каждом клиенту + дату первого дозвона за все время работы докердов и повторников

		   select min(creationd) first_creationd, min(case when login is not null then creationd end) first_creationd_w_login , phonenumbers
		   into #v_first_obzvon
		   from #docr_cases_sessions
		   group by phonenumbers
		   --оставляем уникальную связку загруженный кейс в рамках среза от рисков + телефонный номер
		   select 
		   v.creationd, 


		   v.phonenumbers
		   , max(uuid) uuid
		   , max(login) login
		   , min(creationdate) creationdate
		   , max(projecttitle) projecttitle
		   , max(attempt_start) max_attempt_start 
		   , min(attempt_start) min_attempt_start 
		   , count(attempt_start) count_attempt_start 
		   
		   into #docrsessions_gr_by_phone_dt
		   from #docr_cases_sessions v
		   group by  v.creationd, v.phonenumbers


		   --составляем воронку от рисковых баз до выдачи
		   --номер телефона и срез от рисков как ключ
		 --  drop table if exists  dwh_new.[dbo].[report_docr_i_povt2]
		 --select 

		 --dip.cdate,
		 --dip.mobile,
		 --dip.main_limit,
		 --dip.fin_gr,
		 --dip.[category],
		 --dip.type,
		 --dip_naumen.creationd case_cdate,

		 --dip_naumen.uuid uuid,
		 --dip_naumen.login login,
		 --dip_naumen.creationdate creationdate,
		 --dip_naumen.projecttitle projecttitle,
		 --dip_naumen.min_attempt_start min_attempt_start,
		 --dip_naumen.max_attempt_start max_attempt_start,
		 --dip_naumen.count_attempt_start count_attempt_start,
		 --fa.Номер,
		 --fa.[Вид займа],
		 --fa.ДатаЗаявкиПолная,
	  --   fa.[Верификация КЦ], 
	  --   fa.[Предварительное одобрение], 
	  --   fa.[Контроль данных],  
	  --   fa.[Верификация документов клиента], 
	  --   fa.[Верификация документов], 
	  --   fa.Одобрено, 
	  --   fa.[Отказ документов клиента], 
	  --   fa.Отказано, 
	  --   fa.[Заем выдан],
	  --   fa.[Выданная сумма],
	  --   fa.creationd ДатаЗаявкиПолная_cdate,
		 --case 
		 --when fa.Номер is not null and dip_naumen.login is null then 1
		 --when fa.Номер is not null and dip_naumen.login is not null then 0 end as [Self_motivated],
   --      case when dip_naumen.creationd=v_first_obzvon.first_creationd then 1 else 0 end as [First_time_try],
		 --case when dip_naumen.creationd=v_first_obzvon.first_creationd_w_login then 1 else 0 end as [First_time_successful_try],
		 --GETDATE() as created

		 --into dwh_new.[dbo].[report_docr_i_povt2]
		 --from 
		 ----drop table
		 --#dip_union_gr_by_cdate_mobile dip
		 --left join
		 --#docrsessions_gr_by_phone_dt dip_naumen on dip.mobile=dip_naumen.phonenumbers  and dip.cdate=dip_naumen.creationd
		 --left join
		 --#fa fa on fa.creationd=dip.cdate and fa.Телефон=dip.mobile
		 --left join 
		 --#v_first_obzvon  v_first_obzvon on v_first_obzvon.phonenumbers=dip_naumen.phonenumbers


		delete from dwh_new.[dbo].[report_docr_i_povt2]
		insert into dwh_new.[dbo].[report_docr_i_povt2]
	
		 select 
	
		 dip.cdate,
		 dip.mobile,
		 dip.main_limit,
		 dip.fin_gr,
		 dip.[category],
		 dip.type,
		 dip_naumen.creationd case_cdate,
	
		 dip_naumen.uuid uuid,
		 dip_naumen.login login,
		 dip_naumen.creationdate creationdate,
		 dip_naumen.projecttitle projecttitle,
		 dip_naumen.min_attempt_start min_attempt_start,
		 dip_naumen.max_attempt_start max_attempt_start,
		 dip_naumen.count_attempt_start count_attempt_start,
		 fa.Номер,
		 fa.[Вид займа],
		 fa.ДатаЗаявкиПолная,
	     fa.[Верификация КЦ], 
	     fa.[Предварительное одобрение], 
	     fa.[Контроль данных],  
	     fa.[Верификация документов клиента], 
	     fa.[Верификация документов], 
	     fa.Одобрено, 
	     fa.[Отказ документов клиента], 
	     fa.Отказано, 
	     fa.[Заем выдан],
	     fa.[Выданная сумма],
	     fa.creationd ДатаЗаявкиПолная_cdate,
		 case 
		 when fa.Номер is not null and dip_naumen.login is null then 1
		 when fa.Номер is not null and dip_naumen.login is not null then 0 end as [Self_motivated],
         case when dip_naumen.creationd=v_first_obzvon.first_creationd then 1 else 0 end as [First_time_try],
		 case when dip_naumen.creationd=v_first_obzvon.first_creationd_w_login then 1 else 0 end as [First_time_successful_try],
		 GETDATE() as created
	
		 
		 from 
		 --drop table
		 #dip_union_gr_by_cdate_mobile dip
		 left join
		 #docrsessions_gr_by_phone_dt dip_naumen on dip.mobile=dip_naumen.phonenumbers  and dip.cdate=dip_naumen.creationd
		 left join
		 #fa fa on fa.creationd=dip.cdate and fa.Телефон=dip.mobile
		 left join 
		 #v_first_obzvon  v_first_obzvon on v_first_obzvon.phonenumbers=dip_naumen.phonenumbers



		 --агрегируем данные
          drop table if exists  #t1

			   select 
			   
			   [cdate], 
			   fin_gr, 
			   [category],
               [type],
			   [projecttitle]
			  ,[Self_motivated]
			  ,[First_time_try]
			  ,[First_time_successful_try]
			  ,sum([First_time_try]) [sum_First_time_try]
			  ,sum([First_time_successful_try]) [sum_First_time_successful_try]
			  ,count(creationdate) count_creationdate
			  ,count(min_attempt_start) count_attempt_start
			  ,count(login) count_login
			  ,count(case when [First_time_try] = 1 then creationdate end) count_First_time_try_creationdate
			  ,count(case when [First_time_successful_try] = 1 then login end) count_First_time_successful_try_login
			  ,count(Номер) count_Номер
			  ,count(ДатаЗаявкиПолная) count_ДатаЗаявкиПолная
			  ,count([Верификация КЦ]) [count_Верификация_КЦ]
			  ,count([Предварительное одобрение]) [count_Предварительное_одобрение]
			  ,count([Контроль данных]) [count_Контроль_данных]
			  ,count([Верификация документов клиента]) [count_Верификация_документов_клиента]
			  ,count([Верификация документов]) [count_Верификация_документов]
			  ,count([Отказ документов клиента]) [count_Отказ_документов_клиента]
			  ,count(Отказано) [count_Отказано]
			  ,count([Одобрено]) [count_Одобрено]
			  ,count([Заем выдан]) [count_Заем_выдан]
			  ,sum([Выданная сумма]) [sum_Выданная_сумма]
			  , getdate() as created
			  into  #t1
			  FROM dwh_new.[dbo].[report_docr_i_povt2]
			  group by
			  			   [cdate], 
			   fin_gr, 
			   [category],
               [type],
			   [projecttitle]
			  ,[Self_motivated]
			  ,[First_time_try]
			  ,[First_time_successful_try]






			  begin tran
     --               drop table if exists  dwh_new.[dbo].[report_docr_i_povt2_agr]

			  --		select *	  into  dwh_new.[dbo].[report_docr_i_povt2_agr]
					--from #t1

					delete from dwh_new.[dbo].[report_docr_i_povt2_agr]
					insert into dwh_new.[dbo].[report_docr_i_povt2_agr]
					select *	  
					from #t1


				commit tran












end
 

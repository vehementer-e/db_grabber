






-- =============================================
-- Author:		Artem Orlov
-- Create date: 24.04.2019 -- Updated 2021_08_04
-- Description:	скрипт для докредитования
-- exec dbo.dokredy
-- =============================================


CREATE   PROCEDURE [dbo].[dokredy] as begin 

 --drop table dbo.docredy_buffer
  if object_id('dbo.docredy_buffer') is not null truncate table dbo.docredy_buffer;/*!!!!!*/


/*1.Считаем для итоговой таблицы скоринги*/
drop table  IF EXISTS #scores;
  select distinct person_id2, FICO3_score_fin,scoring, has_bureau, request_date  as score_date 
  into #scores
from (
select a.external_id, request_date,new_status, concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id2, s.FICO3_score,fs.scoring, has_bureau
,ROW_NUMBER() over (partition by concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) order by  request_date desc ) rn,
ss.FICO3_score FICO3_score2
, case when request_date<'20191115' and ss.FICO3_score is null then s.FICO3_score 
	   when request_date>'20191115' then s.FICO3_score 
	   else ss.FICO3_score end FICO3_score_fin
							         from tmp_v_requests a 
                                     join persons p on p.id=a.person_id
									 left join (select  Number, FICO3_score from (
		                            select distinct a.*, ROW_NUMBER() OVER(PARTITION BY number ORDER BY right(stage,1) DESC) as ROW 
								          from stg._loginom.score a --переписали в рамках задачи DWH-1140 03/06/2021
										  
										  ) aa
								            where  ROW = 1
																		   ) s on cast(s.Number as nvarchar(50))= cast(a.external_id as nvarchar(50)) 
									left join [dbo].[FICO3_scores_1511] ss on ss.external_id=a.external_id collate Cyrillic_General_CI_AS
									 left join dwh_new.[dbo].for_scoring fs on fs.external_id = a.external_id) a
									where   rn=1

						
/*2.Считаем лимит и коэфициент*/
drop table  IF EXISTS #limit_col;
select a.collateral_id, num_closed,
       a.rest,discount_price,
       b.limit as price, market_price,
       b.limit - a.rest as limit, koeff, price_date, score, score_date,has_bureau,scoring 
into #limit_col
from  (select m.collateral_id, d.discount_price, d.price_date, sum(povt) over (partition by m.collateral_id) num_closed, d.market_price,
             
			 case when year(getdate()) - col.[year] > 15 /*12/02/21  20*/ /*year < 2000*/ and povt>=1  then 0.6*d.discount_price
	                  when year(getdate()) - col.[year] > 15 /*12/02/21  20*/ /*year < 2000*/ and povt=0 then 0.55*d.discount_price
	           --       when povt>=1 and ((score>440 and (scoring<=30  and has_bureau=1)) or (score>600 and (has_bureau=0 or (scoring<=95 and has_bureau=1))) or 
					       --(score =0 and (scoring<=30 and has_bureau=1) ))   then 0.85*d.discount_price
	           --       when povt>=1 and (score<=440 or ((scoring>=96 and has_bureau=1)) or (score<=600 and (scoring>=31 and has_bureau=1)) or 
					       --(has_bureau=0 and ( score=0)  )) then 0.7*d.discount_price
	           --       when povt=0 and ((score>440 and (scoring<=30 and has_bureau=1)) or (score>600 and (has_bureau=0 or (scoring<=95 and has_bureau=1))) or 
					       --(score =0 and (scoring<=30 and has_bureau=1) )) then 0.75*d.discount_price 
						   /*12/02/21*/
						   when povt >= 1 then 0.85*d.discount_price
						   when povt = 0 then 0.75*d.discount_price
						    ELSE 0.55*d.discount_price end as limit,

              case when year(getdate()) - col.[year] > 15 /*12/02/21  20*/ /*year < 2000*/ and povt>=1  then 0.6
	                   when year(getdate()) - col.[year] > 15 /*12/02/21  20*/ /*year < 2000*/ and povt=0 then 0.55
	       --            when povt>=1 and ((score>440 and (scoring<=30  and has_bureau=1)) or (score>600 and (has_bureau=0 or (scoring<=95 and has_bureau=1))) or 
					   --(score =0 and (scoring<=30 and has_bureau=1) ))   then 0.85
	       --            when povt>=1 and (score<=440 or ((scoring>=96 and has_bureau=1)) or (score<=600 and (scoring>=31 and has_bureau=1)) or 
					   --(has_bureau=0 and ( score=0)  )) then 0.7
	       --            when povt=0 and ((score>440 and (scoring<=30 and has_bureau=1)) or (score>600 and (has_bureau=0 or (scoring<=95 and has_bureau=1))) or 
					   --(score =0 and (scoring<=30 and has_bureau=1) ))   then 0.75
					   /*12/02/21*/
					   when povt >= 1 then 0.85 
					   when povt = 0 then 0.75
	                   ELSE 0.55 end as koeff, 

		     score, score_date, has_bureau, scoring,
			 /*12/02/21*/
			 ROW_NUMBER() over (partition by m.collateral_id order by score_date desc) as rown

                         from (select a.person_id2, povt, isnull(FICO3_score_fin,0) score,score_date, scoring, has_bureau  from (						
										select person_id2, 
						              sum(case when [status] = 1 then 1 else 0 end) as povt 
							   from (select a.*, concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id2,  
                                 row_number() over (partition by a.external_id order by a.credit_date desc) as rn
							         from tmp_v_credits a 
                                     join persons p on p.id=a.person_id) c
							   where c.rn = 1
                               group by person_id2) a 
							   left join #scores s on s.person_id2=a.person_id2) a
                         join (
                                 select distinct concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id,  collateral_id from tmp_v_credits c
                                    join persons p on p.id=c.person_id) m on m.person_id=a.person_id2 
                         join GetCollateralsMarketPrice(dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date))) d on d.collateral_id  = m.collateral_id
						 join collaterals col on col.id=m.collateral_id                         
						 ) b     


				   join (select c.collateral_id, sum(b.principal_rest) as rest
				         from (select a.external_id,
						              isnull(a.principal_rest,0) as principal_rest,
									  row_number() over (partition by a.external_id order by isnull(a.principal_rest,0) desc) as rn
						       from stat_v_balance2 a
							   where cdate = dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date))) b
				         join (select a.*,
						              row_number() over (partition by a.external_id order by a.credit_date desc) as rn
							   from tmp_v_credits a) c on b.external_id = c.external_id and c.rn = 1
                         where b.rn = 1
						 group by collateral_id) a  on b.collateral_id=a.collateral_id
				where b.rown = 1


        --Приводим к формату ФИО и ДР
		drop table  IF EXISTS #main;
		select distinct concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id,  collateral_id 
        into #main
        from tmp_v_credits c
        join persons p on p.id=c.person_id

		/*3.Остатки ОД по клиенту или клиенту+авто*/
	--11/02/21 остаток долга по связке (клиент + залог)
	drop table if exists #rest_col_pers;
			 select c.person_id,
					c.collateral_id,
					sum(b.principal_rest) as pers_col_rest
					into #rest_col_pers
				from (select a.external_id,
							isnull(a.principal_rest,0) as principal_rest,
							row_number() over (partition by a.external_id order by isnull(a.principal_rest,0) desc) as rn
					from stat_v_balance2 a
					where cdate = dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date))) b
				join (select concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) person_id, a.external_id,
							row_number() over (partition by a.external_id order by a.credit_date desc) as rn,
							a.collateral_id
					from tmp_v_credits a
					join persons p on p.id=a.person_id) c on b.external_id = c.external_id and c.rn = 1
				where b.rn = 1
				group by c.person_id, c.collateral_id;

	  --11/02/21 остаток долга по клиенту
	  	drop table if exists #rest_pers;
			 select c.person_id,
					sum(b.principal_rest) as pers_rest
					into #rest_pers
				from (select a.external_id,
							isnull(a.principal_rest,0) as principal_rest,
							row_number() over (partition by a.external_id order by isnull(a.principal_rest,0) desc) as rn
					from stat_v_balance2 a
					where cdate = dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date))) b
				join (select concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) person_id, a.external_id,
							row_number() over (partition by a.external_id order by a.credit_date desc) as rn
					from tmp_v_credits a
					join persons p on p.id=a.person_id) c on b.external_id = c.external_id and c.rn = 1
				where b.rn = 1
				group by c.person_id;		

/*4.Считаем срок пользования кредитом*/
drop table  IF EXISTS #days_by_person;
     select person_id, sum(num_active_days) num_active_days into #days_by_person
					from(
					select person_id, vnutri_new, datediff(dd,st_date,end_date) as num_active_days
					from (
					select person_id, vnutri_new, min(st_date) as st_date, max(end_date) as end_date
					from (
					select external_id, person_id, st_date, end_date, rn, (case when rn = 1 then vnutri_2 else vnutri end) as vnutri_new
					from (
					select external_id,
						st_date,
						end_date,
						person_id,
						last_st_date,
						last_end_date,
						rn,
						max(rn) over (partition by a.person_id) as max_rn,
						min(last_st_date) over (partition by a.person_id) as min_st_date,
						(case when st_date >=  last_st_date and st_date <= last_end_date then 1 else 0 end) as vnutri,
						(case when end_date >= lead_st_date and end_date <= lead_end_date then 1 else 0 end) as vnutri_2
					from (
					select a.external_id,
						cast(credit_date as date) as st_date,
						(case when b.end_date is null then cast(getdate() as date) else b.end_date end) as end_date,
						concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) person_id,
						lag(cast(credit_date as date)) over (partition by a.person_id order by cast(credit_date as date)) as last_st_date,
						lag(cast(end_date as date))    over (partition by a.person_id order by cast(credit_date as date)) as last_end_date,
						lead(cast(credit_date as date)) over (partition by a.person_id order by cast(credit_date as date)) as lead_st_date,
						lead(cast(end_date as date))    over (partition by a.person_id order by cast(credit_date as date)) as lead_end_date,
						row_number() over (partition by a.person_id order by cast(credit_date as date)) as rn
					from tmp_v_credits a
					left join (select a.external_id,
										b.end_date,
										row_number() over (partition by a.external_id order by a.credit_date) as rn
								from tmp_v_credits a
								left join (select distinct request_id,
													person_id,
													cast(stage_time as date) end_date
											from requests_history rh
											join (select id, person_id from requests) r on r.id = rh.request_id
											where status = 16) b on a.request_id = b.request_id) b on a.external_id = b.external_id
								join persons p on person_id=p.id
					) a) a) a
					group by person_id, vnutri_new) a) A
					group by person_id;

/*5.Считаем портфельные поля*/
drop table if exists #portfel;
             select distinct 
						 b.external_id,
                         c.collateral_id,
						 concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id,
						 max(b.overdue_days_p)                                      as max_dpd,
						 max(c.start_date)                                          as start_date,
						 max(rh.end_date)                                           as end_date,
						 sign(sum(case when rh.end_date is null then 1 else 0 end)) as not_end,
						 max(datediff(d,rh.end_date,CURRENT_TIMESTAMP))             as was_closed_ago,
                         max( case when rh.end_date is null then datediff(d,c.start_date,dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date))) else  datediff(d,c.start_date,rh.end_date) end ) days
                         into #portfel
                  from (select a.*,
				               row_number() over (partition by a.external_id, a.cdate order by isnull(a.principal_rest,0) desc) as rn
						from stat_v_balance2 a) b
				  join (select a.*,
				               row_number() over (partition by a.external_id order by a.credit_date desc) as rn
						from tmp_v_credits a) c on b.external_id = c.external_id and c.rn = 1
				  left join (select request_id,
				                    end_date
	                         from (select distinct request_id,
							              collateral_id,
										  cast(stage_time as date) end_date,
										  row_number() over (partition by request_id order by cast(stage_time as date)) as rn
								   from requests_history rh
								   join (select id, collateral_id from requests) r on r.id = rh.request_id
								   where status = 16) a
							 where rn = 1) rh on rh.request_id = b.request_id 
                  join persons p on p.id=c.person_id
                  where b.rn = 1
				  group by  b.external_id,c.collateral_id,concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) ;

  
/*6.Считаем хорошие визы*/
drop table if exists #good_visa;
     select collateral_id, 1 as flag_good  
     into #good_visa from(
            select collateral_id, external_id from 
                (select  
                collateral_id, 
                c.external_id, 
                ROW_NUMBER() OVER (partition by collateral_id  order by start_date desc ) as rn
                from tmp_v_credits C JOIN persons p on c.person_id=p.id ) 
                a where rn=1) b
            JOIN (
                    select [номер] as external_id, 
                    sign(sum(case when cast([ГП_представлениекритериевриска] as varchar(2000))  like '%101%'    
                                or cast([ГП_представлениекритериевриска] as varchar(2000))  like '%102.1%'  
                                or cast([ГП_представлениекритериевриска] as varchar(2000))  like '%102.2%'  
                                or cast([ГП_представлениекритериевриска] as varchar(2000))  like '%102.3%'  
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.1.2%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.1.4%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.1.6%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.2.1%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.2.2%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.3.1%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.4.1%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.4.2%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) like '%103.1.1%' 
                                or cast([ГП_представлениекритериевриска] as varchar(2000)) is null then 1          
                            else 0 end)) as flag_good 
                    from Stg._1cMFO.[Документ_ГП_Заявка] 
                    group by [номер]
            ) a on a.external_id=b.external_id
 
 
 /*7.Приводим поля регион,паспорт в нужный формат*/
 drop table if exists #regions; 
	  select a.external_id,
	                    a.pos,
						a.rp,
						a.channel,
						b.doc_ser,
						b.doc_num,
						b.ТелефонМобильный,
						isnull(rtrim(replace(replace(replace(replace(replace(replace(replace(ltrim(rtrim(b.region)),',','.'),'.',''),' область',''),' Республика',''),' Респ',''),' обл',''),' г','')), 'Nan') as region_projivaniya
                        into #regions
                 from (select a.external_id,
				              cast(c.credit_date as date) as credit_date,
				              c.amount                    as credit_amount,
	                          isnull(b.name, 'Nan')       as pos,
	                          isnull(d.name, 'Nan')       as channel,
							  isnull((case when b.name = 'Мобильное приложение'   then 'Мобильное приложение'
	                                       when b.name = 'Личный кабинет клиента' then 'Личный кабинет клиента' else b.regional_office end), 'Nan') as rp,
	                          row_number() over (partition by a.external_id order by a.request_date) as rn
                       from tmp_v_requests a
                       join points_of_sale b on a.point_of_sale = b.id
					   join chanels        d on a.chanel        = d.id
					   join tmp_v_credits  c on a.external_id   = c.external_id) a
		         left join (select external_id, doc_ser, doc_num, [ТелефонМобильный],
	                               (case when external_id in ('18111508950001') then 'Кировская обл.'
                                         when external_id in ('18011013840001','18051623260001') then 'Калужская обл.'
                                         when external_id in ('18011615200001','18050516640001') then 'Марий Эл Респ.'
                                         when external_id in ('18022204570003','151001840003','18110225860002','151001840003') then 'Москва г.'
                                         when external_id in ('18102727610001') then 'Новгородская обл.'
                                         when external_id in ('1705128770001','17120918970002') then 'Саратовская обл.'
                                         when external_id in ('17082314160001','17121915700002') then 'Ростовская обл.'
                                         when external_id in ('150713490001','150604490003') then 'Смоленская обл.'
                                         when external_id in ('150421600006','140925600009') then 'Воронежская обл.'
                                         when external_id in ('1601121000004') then 'Рязанская обл.'
                                         when external_id in ('160115840007','160202470002','151115690005','151103470007','151021910001','150228690007','150109490001','150129440007','141117440005') then 'Nan'
			                             when (region = '' or region = 'Новофедоровское п,') then 'Nan'
								         when region = 'Нижнегородская область,' then 'Нижегородская обл.'
								         when region = 'Чувашская - Чувашия Респ,' then 'Чувашская Республика - Чувашия'
								         when region = 'город Белорецк,' then 'Башкортостан Респ.'
								         when region = 'ул. трудовой славы,' then 'Краснодарский край'
			                             else region end) as region
                            from (select a.Номер as external_id,
										 b.[СерияПаспорта] as doc_ser,
										 b.[НомерПаспорта] as doc_num,
										 (case when a.ТелефонМобильный = ''                then 'Nan' else a.ТелефонМобильный end)                as [ТелефонМобильный],
					                     b.АдресПроживания  as adress_projivaniya,
					                     b.АдресРегистрации as adress_registracii,
	   			                         ltrim(rtrim(substring(substring(substring(b.АдресПроживания,8,200),charindex(',',substring(b.АдресПроживания,8,40))+1,200),1,charindex(',',substring(substring(b.АдресПроживания,8,200),charindex(',',substring(b.АдресПроживания,8,200))+1,200))))) as region,
	   			                         row_number() over (partition by a.Номер order by a.Номер) as rn
			                      from Stg._1cMFO.[Документ_ГП_Договор]     a
							      left join Stg._1cMFO.[Документ_ГП_Заявка]  b on b.ссылка = a.Заявка) a
					        where rn = 1) b on a.external_id = b.external_id
		         where a.rn = 1;
            
--Из потфельных данных см 5. тащим агрегированные поля
			drop table if exists #dpd_now;
                  select person_id,
	                    max(max_dpd) as max_dpd_now
				  into #dpd_now 
				  from #portfel
                  where not_end = 1
                  group by person_id;

				  drop table if exists #days_of_creds;
                  select person_id,
	                    min(days) as dod
				 into #days_of_creds
				 from #portfel
                 where not_end = 1
                 group by person_id;

				 drop table if exists #dpd_all;
                 select person_id,
	                    max(max_dpd) as max_dpd_all
                 into #dpd_all 
				 from #portfel
                 group by person_id;

  --Ниже собираются таблицы с флагами - не завершен, текущая просрочка  
	drop table if exists #not_end;
        select sign(sum(case when rh.end_date is null then 1 else 0 end)) as not_end,	 collateral_id
		into #not_end 
								from ( select c.person_id,c.collateral_id,  end_date from tmp_v_requests C
								left join (select r.collateral_id, concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id,
                                 end_date from tmp_v_requests C
								left join (
										select request_id,end_date from (
										select request_id,status,stage_time end_date, ROW_NUMBER() over (PARTITION by request_id order by stage_time desc) rn
										from requests_history )a 
										where rn=1 and status=16) a on a.request_id=c.id
										join tmp_v_credits r on r.request_id=c.id
                                        join persons p on p.id=r.person_id) a on a.collateral_id=c.collateral_id)  rh 
                                        GROUP by collateral_id;


--дата окончания договора     
  drop table if exists #cred_end_date;
select d.Код as external_id,
	   cast(dateadd(year,-2000,max(sd.Период)) as date) as end_date
into #cred_end_date
from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
inner join stg._1ccmr.Справочник_Договоры d on d.Ссылка=sd.договор
inner join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
where ssd.Наименование='Погашен'
group by d.Код;

--максимальная текущая просрочка --15/01/21 - изменен ключ на PERSON_ID (был collateral_id)
drop table if exists #dpd_tek
select	concat(rtrim(ltrim(p.last_name)),' ',rtrim(ltrim(p.first_name)),' ',rtrim(ltrim(p.middle_name)), ' ', isnull(p.birth_date,'19000101')) as person_id,
		max(
		case 
		--если нет договоров в stat_v_balance
		when a.external_id is null then 0
		--для закрытых dpd=0
		when ed.end_date <= dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date)) then 0
		else overdue_days end
			) as overdue_days 
	into #dpd_tek
	from dwh_new.dbo.persons p 	
    inner join dwh_new.dbo.tmp_v_credits c 
	on p.id = c.person_id
	left join dwh_new.dbo.stat_v_balance2 a		
	on c.external_id = a.external_id
	and a.cdate = dateadd(dd,-1,cast(CURRENT_TIMESTAMP as date))
	left join #cred_end_date ed
	on a.external_id = ed.external_id
	
    GROUP by concat(rtrim(ltrim(p.last_name)),' ',rtrim(ltrim(p.first_name)),' ',rtrim(ltrim(p.middle_name)), ' ', isnull(p.birth_date,'19000101'))
	;

     --таблица person с фио в нужном формате
	 drop table if exists #pers;
         select distinct person_id2, fio, birth_date  
		 into  #pers from (
            select *, 
            concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) person_id2, 
            concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name))) fio from persons P) a;
    

--оплатили более 70% от тела долга
drop table if exists #desc;
SELECT distinct external_id INTO #desc FROM v_balance_cmr WHERE total_rest/amount <=0.3 ;


--25/09/2020: новые переменные: 
--MAX_DELTA_ACTIVE - максимальная дельта по лимитом и выданной суммой
--MAX_DPD_DA - максимальное кол-во дней просрочки


--отбраем заявки с решением на Call2 после 07.07.2020
drop table if exists #stg1_limit_kdisk;
select 
cast(a.Number as nvarchar(100)) as external_id, 
a.Call_date,
a.Credit_limit,
a.k_disk
into #stg1_limit_kdisk
from stg._loginom.Originationlog a
where cast(a.Call_date as date) between cast('2020-07-07' as date) and cast(getdate() as date)--dateadd(dd,-1,cast(getdate() as date))
and a.Stage = 'Call 2'
;

--выбираем последнее решение
drop table if exists #stg2_limit_kdisk;
select b.external_id, 
b.k_disk, 
iif(b.Credit_limit < 0, 0, b.Credit_limit) as Credit_limit
into #stg2_limit_kdisk
from #stg1_limit_kdisk b
inner join (
	select a.external_id, max(a.Call_date) AS mx_call_date
	from #stg1_limit_kdisk a
	group by a.external_id
) aa
on aa.external_id = b.external_id
and aa.mx_call_date = b.Call_date;


--дата окончания договора
drop table if exists #request_hist
select a.request_id, max(cast(a.stage_time as date)) as end_date
into #request_hist
from dwh_new.dbo.requests_history a
inner join dwh_new.dbo.requests b
on a.request_id = b.id
inner join dwh_new.dbo.persons c
on b.person_id = c.id
where a.[status] = 16
group by a.request_id;


--промежуточная таблица 1 - обогащаем лимитом, суммой выдачи и др.
drop table if exists #stg1_delta_limit_amount;

select a.external_id, 
c.request_id,
c.person_id,
concat(rtrim(ltrim(p.last_name)),' ',rtrim(ltrim(p.first_name)),' ',rtrim(ltrim(p.middle_name)), ' ', isnull(p.birth_date,'19000101')) as person_id2,
c.collateral_id,
a.Credit_limit as CreditLimit, 
a.k_disk, 
b.РыночнаяСтоимостьАвтоНаМоментОценки as CarMarketPrice,

case when a.Credit_limit is null 
then b.РыночнаяСтоимостьАвтоНаМоментОценки * a.k_disk
when a.k_disk is null or b.РыночнаяСтоимостьАвтоНаМоментОценки is null 
then a.Credit_limit
when a.Credit_limit <= b.РыночнаяСтоимостьАвтоНаМоментОценки * a.k_disk
then a.Credit_limit
else b.РыночнаяСтоимостьАвтоНаМоментОценки * a.k_disk
end as max_limit,

c.amount as loan_amount,
c.[start_date] as loan_start_date,
rh.end_date as loan_end_date,

case when rh.end_date is not null
then DATEDIFF(dd, c.[start_date], rh.end_date) 
else datediff(dd,c.[start_date], dateadd(dd,-1,cast(getdate() as date)))
end as dod_da

into #stg1_delta_limit_amount

from #stg2_limit_kdisk a
inner join dwh_new.dbo.tmp_v_credits c
on a.external_id = c.external_id
inner join dwh_new.dbo.persons p
on c.person_id = p.id
inner join dwh_new.dbo.collaterals clt
on c.collateral_id = clt.id
left join stg._1cMFO.Документ_ГП_Заявка b
on a.external_id = b.Номер
left join #request_hist rh
on c.request_id = rh.request_id

where c.[start_date] < cast(getdate() as date);




--максимальный DPD
drop table if exists #stg_max_dpd;
select a.external_id, max(a.overdue_days_p) as max_dpd
into #stg_max_dpd
from dwh_new.dbo.stat_v_balance2 a
inner join #stg1_delta_limit_amount b
on a.external_id = b.external_id
group by a.external_id;



--промежуточная таблица 2 - считаем дельту и добавляем максимальный DPD
drop table if exists #stg2_delta_limit_amount;

select a.external_id, 
a.person_id,
a.person_id2,
a.request_id,
a.collateral_id,
a.CreditLimit,
a.CarMarketPrice,
a.k_disk,
a.max_limit,
a.loan_amount,
a.loan_start_date,
a.max_limit - a.loan_amount as delta,
a.loan_end_date,
a.dod_da,
b.max_dpd as max_dpd_da

into #stg2_delta_limit_amount

from #stg1_delta_limit_amount a
left join #stg_max_dpd b
on a.external_id = b.external_id
;


--итоговая таблица с новыми полями MAX_DELTA_ACTIVE и MAX_DPD_DA
drop table if exists #delta_limit_amount ;
select a.person_id2, 
max(a.delta) as max_delta_active,
max(a.max_dpd_da) as max_dpd_da
into #delta_limit_amount 
from #stg2_delta_limit_amount a
where a.loan_end_date is null
and a.dod_da < 70
group by a.person_id2
;


--15/01/2021 формируем реестр исп.срока из Space
--формируем реестр подоговорный исп.срока из Space
drop table if exists #isp_srok_cred;
select 
a.Number as external_id,
concat(rtrim(ltrim(p.last_name)),' ',
	   rtrim(ltrim(p.first_name)),' ',
	   rtrim(ltrim(p.middle_name)), ' ', 
	   isnull(p.birth_date,'19000101')) as person_id,
cast(b.[start_date] as date) as dt_open

into #isp_srok_cred
from stg._Collection.Deals a
inner join dwh_new.dbo.tmp_v_credits b
on a.Number = b.external_id
inner join dwh_new.dbo.persons p
on b.person_id = p.id
where a.Probation = 1
;

--перечень клиентов по ключу ФИО+Дата рождения с исп.сроком, выдача была не позднее последних 180 дней
drop table if exists #isp_srok_clients;
select a.person_id,
sign(sum( case when DATEDIFF(dd,a.dt_open, cast(getdate() as date)) < 180 then 1 else 0 end )) as flag_ispsrok
into #isp_srok_clients
from #isp_srok_cred a
group by a.person_id
;

--10/02/2021 - кредитные каникулы
----собираем даты кредитных каникул из Space и ЦМР
drop table if exists #kk_base;

with kk_space as (
select a.Number as external_id, 
isnull(cast(a.CreditVacationDateBegin as date), cast(b.Период as date)) as dt_from, 
cast(a.CreditVacationDateEnd	  as date) as dt_to

from stg._Collection.Deals a
left join Reports.dbo.DWH_694_credit_vacation_cmr b
on a.Number = b.Договор
where 1=1
and a.CreditVacationDateEnd is not null
), base as (
select k.external_id, k.dt_from, k.dt_to
from kk_space k
	union all
select c.Договор as external_id, c.Период as dt_from, c.ДатаОкончания as dt_to
from Reports.dbo.DWH_694_credit_vacation_cmr c
where not exists (select 1 from kk_space kk
				where c.Договор = kk.external_id)
)
select 
concat(rtrim(ltrim(p.last_name)),' ',rtrim(ltrim(p.first_name)),' ',rtrim(ltrim(p.middle_name)), ' ', isnull(p.birth_date,'19000101')) as person_id,
b.external_id,
b.dt_from,
case when rh.end_date < b.dt_to and rh.end_date is not null then rh.end_date
else b.dt_to end as dt_to

into #kk_base
from base b
inner join dwh_new.dbo.tmp_v_credits t
on b.external_id = t.external_id
inner join dwh_new.dbo.persons p
on t.person_id = p.id
left join #request_hist rh
on t.request_id = rh.request_id

;

----кол-во дней с последних каникул, если < 0, значит, действуют на сегодня
drop table if exists #for_kk_flag;
select a.person_id, 
min(DATEDIFF(dd,dt_to, cast(getdate() as date))) as days_from_last_cred_hol
into #for_kk_flag
from #kk_base a
group by a.person_id
;



--16/08/2021 - перечень клиентов с договорами цессии (прощения и пр), которые маркируются красным цветом
drop table if exists #cession;
with base as (
select m.person_id, m.collateral_id, a.external_id, r.doc_num, r.doc_ser,
iif(z1.external_id is not null, 1, 0) as flag1,
iif(z2.external_id is not null, 1, 0) as flag2,
iif(z3.external_id is not null, 1, 0) as flag3

from #main m
left join (select collateral_id, external_id, person_id from 
	(select  
	concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id, collateral_id,
	c.external_id, 
	ROW_NUMBER() OVER (partition by concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')),collateral_id  
					   order by start_date desc, isnull(ed.end_date,cast('4444-01-01' as date)) desc, c.external_id desc ) as rn
	from tmp_v_credits C 
	JOIN persons p on c.person_id=p.id
	left join #cred_end_date ed
	on c.external_id = ed.external_id
	)	  
 a where rn=1) a 
on a.person_id=m.person_id and a.collateral_id=m.collateral_id
left join #regions r
on a.external_id = r.external_id

--по ФИО+ДР
left join RiskDWH.dbo.det_crm_redzone z1
on m.person_id = concat(rtrim(ltrim(z1.last_name)),' ',rtrim(ltrim(z1.first_name)),' ',rtrim(ltrim(z1.patronymic)), ' ', isnull(z1.birth_date,'19000101'))
--по паспорту
left join RiskDWH.dbo.det_crm_redzone z2
on r.doc_ser = z2.passport_series
and r.doc_num = z2.passport_num
--по номеру договора
left join RiskDWH.dbo.det_crm_redzone z3
on a.external_id = z3.external_id
)

select distinct b.person_id
into #cession
from base b
where b.flag1 + b.flag2 + b.flag3 > 0
;



--17/08/2021 - отказы по предыдущим заявкам на уровне клиента

drop table if exists #client_declines;
with base as (
select m.person_id, m.collateral_id, a.external_id, r.doc_num, r.doc_ser,
iif(d1.fio_bd is not null, 1, 0) as flag1,
iif(d2.passport_number is not null, 1, 0) as flag2

from #main m
left join (select collateral_id, external_id, person_id from 
	(select  
	concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id, collateral_id,
	c.external_id, 
	ROW_NUMBER() OVER (partition by concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')),collateral_id  
					   order by start_date desc, isnull(ed.end_date,cast('4444-01-01' as date)) desc, c.external_id desc ) as rn
	from tmp_v_credits C 
	JOIN persons p on c.person_id=p.id
	left join #cred_end_date ed
	on c.external_id = ed.external_id
	)	  
 a where rn=1) a 
on a.person_id=m.person_id and a.collateral_id=m.collateral_id
left join #regions r
on a.external_id = r.external_id

--по ФИО+ДР
left join dwh_new.dbo.docr_povt_fio_db_red_decline d1
on a.person_id = d1.fio_bd
and d1.cdate = cast(getdate() as date)
--по паспорту
left join dwh_new.dbo.docr_povt_passport_red_decline d2
on r.doc_ser = d2.passport_series
and r.doc_num = d2.passport_number
and d2.cdate = cast(getdate() as date)
)

select distinct b.person_id
into #client_declines
from base b
where b.flag1 + b.flag2 > 0
;





--01/12/2021 - Факт подачи иска в суд
-- дата подачи иска в суд или дата решения суда (судебное производтсво)
drop table if exists #isk_sp_space
SELECT DISTINCT
		Deal.Number AS external_id,		
		pd.LastName,
		pd.FirstName,
		pd.MiddleName,
		cast(pd.BirthdayDt as date) as birth_dt,
		concat(rtrim(ltrim(pd.LastName)),' ',rtrim(ltrim(pd.FirstName)),' ',rtrim(ltrim(pd.MiddleName)), ' ', isnull(cast(pd.BirthdayDt as date),'19000101')) as person_id,
		pd.Series as passport_series,
		pd.Number as passport_number
		-- СП
		--, min(jc.CourtClaimSendingDate) as CourtClaimSendingDate
		--, jc.ReceiptOfJudgmentDate 'Дата решения суда' 
		--, jc.ResultOfCourtsDecision 'Решение суда'
		--, jc.AmountJudgment 'Сумма по решению суда' 
into #isk_sp_space
FROM Stg._Collection.Deals AS Deal
LEFT JOIN Stg._Collection.JudicialProceeding AS jp 
ON Deal.Id = jp.DealId 
LEFT JOIN Stg._Collection.JudicialClaims AS jc 
ON jp.Id = jc.JudicialProceedingId 
left join stg._collection.customerpersonaldata as pd
on deal.idcustomer = pd.idcustomer
inner join stg._Collection.customers c 
on c.Id = Deal.IdCustomer
where (isnull(jc.CourtClaimSendingDate, jc.ReceiptOfJudgmentDate)  is not null	
or ISNULL(c.ClaimantExecutiveProceedingId, c.ClaimantLegalId) is not null
)
;


drop table if exists #client_court_decisions;
with base as (
select m.person_id, m.collateral_id, a.external_id, r.doc_num, r.doc_ser,
iif(i.person_id is not null, 1, 0) as flag1,
iif(ii.passport_series is not null, 1, 0) as flag2,
iif(iii.external_id is not null, 1, 0) as flag3

from #main m
left join (select collateral_id, external_id, person_id from 
	(select  
	concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id, collateral_id,
	c.external_id, 
	ROW_NUMBER() OVER (partition by concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')),collateral_id  
					   order by start_date desc, isnull(ed.end_date,cast('4444-01-01' as date)) desc, c.external_id desc ) as rn
	from tmp_v_credits C 
	JOIN persons p on c.person_id=p.id
	left join #cred_end_date ed
	on c.external_id = ed.external_id
	)	  
 a where rn=1) a 
on a.person_id=m.person_id and a.collateral_id=m.collateral_id
left join #regions r
on a.external_id = r.external_id

--по ФИО+ДР
left join #isk_sp_space i 
on m.person_id = i.person_id
--по паспорту
left join #isk_sp_space ii
on r.doc_ser = ii.passport_series
and r.doc_num = ii.passport_number
--по номеру договора
left join #isk_sp_space iii
on a.external_id = iii.external_id
)

select distinct b.person_id
into #client_court_decisions
from base b
where b.flag1 + b.flag2 + b.flag3 > 0
;


--01/12/2021 - Инстолменты - исключаются из CRM-предложений

--Статусы договоров из ЦМР
drop table if exists #cred_CMR_status;
select b.Код as external_id, 
b.Клиент as client_cmr_id,
b.IsInstallment,
dateadd(yy,-2000,a.Период) as dt_status,  
c.Наименование as cred_status,
ROW_NUMBER() over (partition by b.Код order by a.Период desc) as rown
into #cred_CMR_status
from stg._1cCMR.РегистрСведений_СтатусыДоговоров a
inner join stg._1cCMR.Справочник_Договоры b
on a.Договор = b.Ссылка
inner join stg._1cCMR.Справочник_СтатусыДоговоров c
on a.Статус = c.Ссылка
;

--Активные договора
drop table if exists #active_cred;
select a.external_id, isnull(a.IsInstallment,0) as flag_installment,
b.Фамилия as last_name,
b.Имя as first_name,
b.Отчество as middle_name,
dateadd(yy,-2000,cast(b.ДатаРождения as date)) as birth_dt,
concat(rtrim(ltrim(b.Фамилия)),' ',rtrim(ltrim(b.Имя)),' ',rtrim(ltrim(b.Отчество)), ' ',isnull(dateadd(yy,-2000,cast(b.ДатаРождения as date)),'19000101')) as person_id,
case when c.Series <> '' then c.Series else b.ПаспортСерия end as passport_series,
case when c.Number <> '' then c.Number else b.ПаспортНомер end as passport_number
into #active_cred
from #cred_CMR_status a 
left join stg._1cCMR.Справочник_Клиенты b
on a.client_cmr_id = b.Ссылка
left join stg._Collection.Deals d
on a.external_id = d.Number
left join stg._Collection.CustomerPersonalData c
on d.IdCustomer = c.IdCustomer
where a.rown = 1
and a.cred_status not in ('Аннулирован','Внебаланс','Зарегистрирован','Продан','Погашен')
;


--Текущие Инстолменты
drop table if exists #client_installment;

with base as (
select m.person_id, m.collateral_id, a.external_id, r.doc_num, r.doc_ser,
iif(i.person_id is not null, 1, 0) as flag1,
iif(ii.passport_series is not null, 1, 0) as flag2,
iif(iii.external_id is not null, 1, 0) as flag3

from #main m
left join (select collateral_id, external_id, person_id from 
	(select  
	concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id, collateral_id,
	c.external_id, 
	ROW_NUMBER() OVER (partition by concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')),collateral_id  
					   order by start_date desc, isnull(ed.end_date,cast('4444-01-01' as date)) desc, c.external_id desc ) as rn
	from tmp_v_credits C 
	JOIN persons p on c.person_id=p.id
	left join #cred_end_date ed
	on c.external_id = ed.external_id
	)	  
 a where rn=1) a 
on a.person_id=m.person_id and a.collateral_id=m.collateral_id
left join #regions r
on a.external_id = r.external_id

--по ФИО+ДР
left join #active_cred i 
on m.person_id = i.person_id
and i.flag_installment = 1
--по паспорту
left join #active_cred ii
on r.doc_ser = ii.passport_series
and r.doc_num = ii.passport_number
and ii.flag_installment = 1
--по номеру договора
left join #active_cred iii
on a.external_id = iii.external_id
and iii.flag_installment = 1
)
select distinct b.person_id
into #client_installment
from base b
where b.flag1 + b.flag2 + b.flag3 > 0
;


--вспомогательная таблица для исключения из базы клиентов, у которых активные договора только инстолменты
drop table if exists #for_elimination;
select a.person_id, min(case when a.flag_installment = 1 then 1 else 0 end) as flag_cli_installment
into #for_elimination
from #active_cred a
group by a.person_id
;





--удаляем временные таблицы, которые дальше не используются
drop table #stg_max_dpd;
drop table #stg1_delta_limit_amount;
drop table #stg1_limit_kdisk;
drop table #stg2_delta_limit_amount;
drop table #stg2_limit_kdisk;
drop table #request_hist;
drop table #isk_sp_space;
drop table #active_cred;
drop table #cred_CMR_status;



/*9.Записываем в финальную таблицу*/
insert   into  dwh_new.dbo.docredy_buffer ([external_id]
      ,[category]
      ,[Type]
      ,[main_limit]
      ,[Минимальный срок кредитования]
      ,[Ставка %]
      ,[Сумма платежа]
      ,[Рекомендуемая дата повторного обращения]
      ,[fio]
      ,[birth_date]
      ,[Auto]
      ,[vin]
      ,[pos]
      ,[rp]
      ,[channel]
      ,[doc_ser]
      ,[doc_num]
      ,[ТелефонМобильный]
      ,[region_projivaniya]
      ,[Berem_pts]
      ,[Nalichie_pts]
      ,[not_end]
      ,[flag_good]
      ,[max_dpd_all]
      ,[max_dpd_now]
      ,[overdue_days]
      ,[dod]
      ,[num_active_days]
      ,[market_price]
      ,[collateral_id]
      ,[price_date]
      ,[discount_price]
      ,[col_rest]
      ,[pers_rest]
      ,[koeff]
      ,[num_closed]
      ,[limit_car]
      ,[limit_client]
      ,[red_visa]
      ,[red_dod]
      ,[red_dpd]
      ,[red_limit]
      ,[is_red]
      ,[is_green]
      ,[is_yellow]
      ,[score_date]
      ,[score]
	  ,has_bureau
	  ,scoring
	  , [group]
	  ,guid
	  ,max_delta_active
	  ,max_dpd_da
	  ,red_car
	  ,red_chd
	  )

/*8.Собираем витрину*/
select a.external_id,
case 
	when is_red = 1										then 'Красный'
	when is_orange * (1-is_red) = 1						then 'Оранжевый'
	when is_green * (1-is_red) * (1-is_orange) = 1		then 'Зеленый'
	when (1-is_red) * (1-is_orange) * (1-is_green) = 1	then 'Желтый' 
end as category,  
		  'Докредитование' as Type,
		   case 
		   when is_red=1 then 0 
		   --01/12/2021 оранжевый
		   when is_orange = 1 and limit <= max_delta_active then FLOOR(limit/1000.0)*1000
		   when is_orange = 1 and max_delta_active <= limit then FLOOR(max_delta_active/1000.0) * 1000		   
		   else convert(int,limit/1000)*1000 
		   end  as main_limit,

		   NULL as [Минимальный срок кредитования], 
		   NULL as [Ставка %],
		   NULL as [Сумма платежа],
		   NULL as [Рекомендуемая дата повторного обращения],
		   fio,
		   birth_date, 
		   Auto,
		   vin,
		   pos,
		   rp,
		   channel,
		   doc_ser,
		   doc_num,
		   ТелефонМобильный,
		   region_projivaniya, 
		   'Не брать ПТС' Berem_pts,
		   'ПТС  в компании' as Nalichie_pts,
		   not_end, 
		   flag_good,
		   max_dpd_all, 
		   max_dpd_now,
		   overdue_days,
		   dod,  
		   num_active_days, 
		   market_price,
		   collateral_id, 
		   price_date,		   
		   discount_price,
		   col_rest,
		   pers_rest,
		   koeff, 
		   num_closed,
		   discount_price*koeff-col_rest as limit_car, 
		   1000000-pers_rest as limit_client,
		   red_visa, 
		   red_dod,
		   red_dpd,
		   red_limit, 
		   is_red, 
		   --зеленая зона - условия зеленой + НЕ красная + НЕ оранжевая
		   is_green * (1 - is_red) * (1 - is_orange) as is_green,
		   --желтая зона - НЕ красная + НЕ зеленая + НЕ оранжевая
		   (1 - is_red) * (1 - is_orange) * (1 - is_green) as is_yellow,
		   score_date,
		   score,
		   has_bureau, 
		   scoring,
		   NULL [group], 
		   NULL guid, 
		   max_delta_active, 
		   max_dpd_da,
		   red_car, --10/02/2021
		   red_chd --10/02/2021

 /*Здесь прописываются условия */
from(
       select distinct a.external_id, fio, birth_date, concat(c.brand, ' ', c.model,' ', c.year ) as Auto, c.vin, not_end,score_date, has_bureau,scoring,
						gv.flag_good,max_dpd_all, max_dpd_now,overdue_days,dod,
						--для main_limit выбираем наименьший из лимитов по машине или по клиенту
						round(iif(1000000-rprs.pers_rest<lc.discount_price*lc.koeff-lc.rest, 
										1000000-rprs.pers_rest, 
										lc.discount_price*lc.koeff-lc.rest) 
						,-3) as limit,  
						dbp.num_active_days, 
						lc.market_price,
						dla.max_delta_active, 
						dla.max_dpd_da,

							/*Флаги красной зоны*/
							
							--1.Доступная сумма кредита менее 50 000 рублей						   
							case when (1000000 - isnull(rprs.pers_rest,0) < 50000) then 1 else 0 end as red_limit, --10/02/21

							--2.Текущая просрочка в компании 5 и более дней							
							case 
							when (overdue_days>=5) then 1 
							when crt.person_id is not null then 1 ---01/12/2021 - подан иск в суд
							else 0 
							end as red_dpd, 

							--3.У клиента есть активный кредитный договор со сроком обслуживания менее 70 дней
						   
							case when ( 
								( 
								/*(dod < 35) or 10/02/21*/ 
								/*(dod < 70 and (dla.max_delta_active < 50000 or dla.max_dpd_da > 0) )  15/06/2021*/
								/*(dod < 70)*/ --04/08/2021
								(dod < 70 and (dla.max_delta_active < 50000 or dla.max_dpd_da > 0) ) 
								) 							
							----15/01/21 - в течение последних 180 дней была выдача по продукту "испытательный срок"
							or isnull(isrk.flag_ispsrok,0) = 1							
							)
							then 1 
							else 0 end as red_dod,


							--4. У клиента есть активный кредитный договор со сроком обслуживания от 70 до 99 дней и клиент отнесен к высокой категории риска 
							-----согласно последней верификации
							case when ((gv.flag_good=0 or gv.flag_good is null) and dod>69 and dod<100) then 1
							----17/08/2021 у клиента были отказные заявки
							when cli_dec.person_id is not null then 1 
							----01/12/2021 у клиента есть выданные инстолменты
							when inst.person_id is not null then 1 
							else 0 end as red_visa, 

							----10/02/2021
							--5. У клиента есть договор, по которому действуют кредитные каникулы или каникулы закончились менее 70 дней назад
							case when isnull(kk.days_from_last_cred_hol,100000) < 70 then 1 else 0 end as red_chd,

							--6. Условие на машину (стоимость - долг) и возраст
							case when (
									(/*res.limit*/lc.discount_price*lc.koeff-rcp.pers_col_rest < 50000 and lc.discount_price*lc.koeff-rcp.pers_col_rest <> 0)
									--или посчитать отдельно
									or year(getdate()) - iif(c.[year] between 1900 and year(getdate()), c.[year], null) > 20 
									)
							then 1 
							----17/08/2021 по авто были отказные заявки
							when auto_dec.vin is not null then 1 
							else 0 end as red_car,
                       
							/*КРАСНАЯ ЗОНА*/
							--Если попал под 1-6 мы его устанавливаем в красный (продублировать условия из red_***) + добавляем условие по исторической просрочке 180 дней
							case when (
								1000000 - isnull(rprs.pers_rest,0) < 50000 --red_limit	from 10/02/21				
							or overdue_days>=5 --red_dpd
							or crt.person_id is not null --01/12/2021 - подан иск в суд
							or (/*(dod < 35) or*/ 
							/*(dod < 70 and (dla.max_delta_active < 50000 or dla.max_dpd_da > 0) ) 15/06/2021 */
							/*(dod < 70)*/ --04/08/2021
							(dod < 70 and (dla.max_delta_active < 50000 or dla.max_dpd_da > 0) )
							) --red_dod
							or isnull(isrk.flag_ispsrok,0) = 1 --red_dod 15/01/21
							or ((gv.flag_good=0 or gv.flag_good is null)and dod>69 and dod<100  ) --red_visa
							or isnull(kk.days_from_last_cred_hol,100000) < 70 --red_chd 10/02/21
							or (/*res.limit*/ lc.discount_price*lc.koeff-rcp.pers_col_rest < 50000 and lc.discount_price*lc.koeff-rcp.pers_col_rest <> 0) --red_car 10/02/21
							or year(getdate()) - iif(c.[year] between 1900 and year(getdate()), c.[year], null) > 20 --red_car 10/02/21
							or max_dpd_now>=180 	
							or ces.person_id is not null --16/08/2021 - цессированные
							or cli_dec.person_id is not null --17/08/2021 - отказные заявки клиента
							or auto_dec.vin is not null --17/08/2021 - отказные завки машины
							or inst.person_id is not null --01/12/2021 у клиента есть выданные инстолменты
							) then 1 
							else 0 end as  is_red, 

							/*ОРАНЖЕВАЯ ЗОНА*/ --10/02/21
							case when dod < 35 
							--and dla.max_delta_active >= 50000 --01/12/2021
							and case 
								when 1000000-rprs.pers_rest <= lc.discount_price*lc.koeff-lc.rest and 1000000-rprs.pers_rest <= dla.max_delta_active
								then 1000000-rprs.pers_rest
								when lc.discount_price*lc.koeff-lc.rest <= 1000000-rprs.pers_rest and lc.discount_price*lc.koeff-lc.rest <= dla.max_delta_active
								then lc.discount_price*lc.koeff-lc.rest
								when dla.max_delta_active <= 1000000-rprs.pers_rest and dla.max_delta_active <= lc.discount_price*lc.koeff-lc.rest
								then dla.max_delta_active end >= 50000
							and dla.max_dpd_da = 0
							then 1 else 0 end as is_orange,				
                 
							/*ЗЕЛЕНАЯ ЗОНА*/						  
							case when (
							--1.Выполняется условие: по всем договорам клиента в компании не было просрочек свыше 9 дней И 
							--	самый последний  из активных договоров клиента оформлен 130 и более  дней назад
								(dod>129 and max_dpd_now<5 and overdue_days=0 and max_dpd_all<10 )
							
							--2.Выполняется условие: по всем договорам клиента в компании не было просрочек свыше 13 дней И
							--самый последний  из активных договоров клиента оформлен от 100 до 129 дней назад И
							--совокупный период обслуживания кредитных договоров клиента в компании составляет 280 дней и более 
							or	(dod>99 and dod<130 and max_dpd_now<5 and overdue_days=0 and max_dpd_all<14 and num_active_days >279 ) 								
							) then 1 else 0 end as is_green,						   

						m.collateral_id, price_date,discount_price,lc.rest as col_rest,rprs.pers_rest,koeff, num_closed, 
						lc.discount_price*lc.koeff-lc.rest as limit_car, 
						1000000-rprs.pers_rest as limit_client,score, 
						ROW_NUMBER() over (partition by c.vin order by m.person_id desc) rn
from #main m 
left join #not_end  ne on m.collateral_id=ne.collateral_id
left join #days_by_person dbp on dbp.person_id=m.person_id
left join #dpd_all da on da.person_id=m.person_id
left join collaterals c on m.collateral_id=c.id
join #dpd_now dn on dn.person_id=m.person_id
left join #days_of_creds doc on doc.person_id=m.person_id
left join #good_visa gv on gv.collateral_id=m.collateral_id
left join #dpd_tek dt on dt.person_id = m.person_id
left join #limit_col lc on lc.collateral_id=m.collateral_id
left join #pers pp on pp.person_id2=m.person_id
left join (select collateral_id, external_id, person_id from 
	(select  
	concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')) as person_id, collateral_id,
	c.external_id, 
	ROW_NUMBER() OVER (partition by concat(rtrim(ltrim(last_name)),' ',rtrim(ltrim(first_name)),' ',rtrim(ltrim(middle_name)), ' ', isnull(birth_date,'19000101')),collateral_id  
					   order by start_date desc, isnull(ed.end_date,cast('4444-01-01' as date)) desc, c.external_id desc ) as rn
	from tmp_v_credits C 
	JOIN persons p on c.person_id=p.id
	left join #cred_end_date ed
	on c.external_id = ed.external_id
	)	  
 a where rn=1) a 
on a.person_id=m.person_id and a.collateral_id=m.collateral_id

left join #delta_limit_amount dla
on m.person_id = dla.person_id2

left join #isp_srok_clients isrk
on m.person_id = isrk.person_id

left join #rest_col_pers rcp
on m.person_id = rcp.person_id
and m.collateral_id = rcp.collateral_id

left join #rest_pers rprs
on m.person_id = rprs.person_id

left join #for_kk_flag kk
on m.person_id = kk.person_id

--16/08/2021 - цессированные - красная зона
left join #cession ces
on m.person_id = ces.person_id

--17/08/2021 - отказы по предыдущим заявкам на уровне клиента
left join #client_declines cli_dec
on m.person_id = cli_dec.person_id

--17/08/2021 - отказы по предыдущим заявкам на уровне машины
left join dwh_new.dbo.docr_povt_vin_red_decline auto_dec
on c.vin = auto_dec.vin
and auto_dec.cdate = cast(getdate() as date)

--01/12/2021 - подан иск в суд
left join #client_court_decisions crt
on m.person_id = crt.person_id

--01/12/2021 - есть договор Инстолмента
left join #client_installment inst
on m.person_id = inst.person_id

where not_end=1
and rprs.pers_rest > 0
and lc.discount_price*lc.koeff-lc.rest is not null
--01/12/2021 -- исключение из базы записей по клиентам, у которых из активных договоров только договора типа Installment
and not exists (select 1 from #for_elimination elim where m.person_id = elim.person_id and elim.flag_cli_installment = 1)

) A 
left join #desc ddd on A.external_id = ddd.external_id
join #regions re on re.external_id=a.external_id 
where rn=1
--and pers_rest>0 
and pos is not null 
--and limit_car is not null
;

--Кузнецов/Ставничая 28/04/2022 клиент сменила ФИО -> превышение лимита
update dwh_new.[dbo].[docredy_buffer] 
set fio='СЕВОСТЬЯНОВА ИРИНА ВИТАЛЬЕВНА'
where external_id = '20082810000055';

--Кузнецов/Ставничая 06/06/2022--убрали Кузнецов/Ставничая 16/06/2022
--update dwh_new.[dbo].[docredy_buffer]
--set category='Красный';


--Кузнецов/Ставничая 16/06/2022
update dwh_new.[dbo].[docredy_buffer]
set category='Красный'
where category<>'Зеленый';

delete from  dbo.docredy_history where  cdate=cast(getdate() as date)
--select * into  [dbo].[docredy_history_backup20190617] from  [dbo].[docredy_history]



INSERT INTO [dbo].[docredy_history]
           ([cdate]
           ,[external_id]
           ,[category]
           ,[Type]
           ,[main_limit]
           ,[Минимальный срок кредитования]
           ,[Ставка %]
           ,[Сумма платежа]
           ,[Рекомендуемая дата повторного обращения]
           ,[fio]
           ,[birth_date]
           ,[Auto]
           ,[vin]
           ,[pos]
           ,[rp]
           ,[channel]
           ,[doc_ser]
           ,[doc_num]
           ,[ТелефонМобильный]
           ,[region_projivaniya]
           ,[Berem_pts]
           ,[Nalichie_pts]
           ,[not_end]
           ,[flag_good]
           ,[max_dpd_all]
           ,[max_dpd_now]
           ,[overdue_days]
           ,[dod]
           ,[num_active_days]
           ,[market_price] 
           ,[collateral_id]
           ,[price_date]
           ,[discount_price]
           ,[col_rest]
           ,[pers_rest]
           ,[koeff]
           ,[num_closed]
           ,[limit_car]
           ,[limit_client],red_visa, red_dod,red_dpd,red_limit, is_red, is_green,is_yellow		   ,score
		   ,score_date
		   ,has_bureau
		   ,scoring
		   ,[group]
		   ,guid
		   ,max_delta_active
		   ,max_dpd_da
		   ,red_car
		   ,red_chd
		   )

  select  cdate=cast(getdate() as date)
       , [external_id]
           ,[category]
           ,[Type]
           ,[main_limit]
           ,[Минимальный срок кредитования]
           ,[Ставка %]
           ,[Сумма платежа]
           ,[Рекомендуемая дата повторного обращения]
           ,[fio]
           ,[birth_date]
           ,[Auto]
           ,[vin]
           ,[pos]
           ,[rp]
           ,[channel]
           ,[doc_ser]
           ,[doc_num]
           ,[ТелефонМобильный]
           ,[region_projivaniya]
           ,[Berem_pts]
           ,[Nalichie_pts]
           ,[not_end]
           ,[flag_good]
           ,[max_dpd_all]
           ,[max_dpd_now]
           ,[overdue_days]
           ,[dod]
           ,[num_active_days]
           ,[market_price]
           ,[collateral_id]
           ,[price_date]
           ,[discount_price]
           ,[col_rest]
           ,[pers_rest]
           ,[koeff]
           ,[num_closed]
           ,[limit_car]
           ,[limit_client],red_visa, red_dod,red_dpd,red_limit, is_red, is_green,is_yellow		   ,score
		   ,score_date
		   ,has_bureau
		   ,scoring
		   ,[group]
		   , guid
		   , max_delta_active
		   , max_dpd_da
		   , red_car
		   , red_chd
       
  from dbo.docredy_buffer

end


--select * from dbo.docredy_buffer

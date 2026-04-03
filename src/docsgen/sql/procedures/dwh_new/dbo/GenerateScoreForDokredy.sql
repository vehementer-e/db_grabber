

CREATE   procedure  [dbo].[GenerateScoreForDokredy]
as
	exec [log].[LogAndSendMailToAdmin] 'GenerateScoreForDokredy','Info','procedure started',N''
  drop table if exists dwh_new.dbo.for_scoring

drop table  IF EXISTS   #SCR_Application3
drop table  IF EXISTS   #eqv_credits3
drop table  IF EXISTS   #SCR_EQUIF3
drop table  IF EXISTS   #SCR_NBKI3
drop table  IF EXISTS   #SCR_NBKI_INQUIRIES3
drop table  IF EXISTS   #SCR_FSSP3
drop table  IF EXISTS   #FOR_SCORING3
drop table  IF EXISTS   #SCR_GIBDD3

--select * from #For_scoring
--select * from [Reports].[dbo].[dm_Maindata]


/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!APPLICATION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
SELECT a.person_id, --a.external_id, 
ROW_NUMBER() OVER(PARTITION BY a.person_id ORDER BY a.external_id) as number_loan,
        case when c.gender = 'Мужской' then 1 --'MALE' 
		      when c.gender = 'Женский' then 2 --'FEMALE' 
			  else 0 -- NULL  
			  end as gender, oper, mobile_phone,
		
		case when c.family_status = 'женат/замужем' then 'Married' 
		     when c.family_status = 'холост/не замужем' then 'Single'
		     when c.family_status = 'разведен(а)' then 'Divorced'
			 when c.family_status = 'вдовец/вдова' then 'Widow'
			 when c.family_status = 'гражданский брак' then 'Civil_marriage' else NULL end as family_status,
	    
		case when a.return_type = 'Первичный' then 'New' 
		     when a.return_type = 'Повторный' then 'Repeated'
			 when a.return_type = 'Параллельный' then 'Parallel'
			 when a.return_type = 'Докредитование' then 'Docred' else NULL end as return_type,



		case when income >= 10000 then income else NULL end as income,datediff(year,birth_date,b.appl_date) as age,
		case when cl.Год <2004 then 1 --'old' 
			 when cl.Год <2011 then 1 --'<2011' 
			 when cl.Год <2017 then 3--'<2017'
			 else 2 --'new' 
			 end as age_car, 

			 case when a.point_of_sale in (694,	1784,	808,	1219,	2147,	2219,	287,	1603,	1769,	338,	809,	360,	254,	806,	810,	1605,	2289,	2362,	2782,	198,	1566,	1908,	2050,	2167,	2311,	521,	155,	156,	344,	380,	393,	2115,	703,	2340,	121,	459,	2309,	889,	1757,	1899,	1628,	1615,	761,	262,	423,	787,	922,	1910,	2303,	1673,	1876,	364,	1168,	1480,	2312,	295,	408,	868,	1623,	1998,	390,	666,	402,	253,	263,	1733,	722,	179,	241,	792,	271,	603,	2069,	1429,	139,	279,	398,	486,	2106,	16,	528,	1789,	32,	2113,	9,	608) 
			 then 1 --'Bad_group' 
				  when a.point_of_sale in (975,	100,	208,	278,	745,	2212,	481,	1798,	519,	291,	410,	2313,	297,	583,	1967,	2094,	2168,	234,	1944,	856,	294,	273,	710,	1459,	1503,	1676,	1808,	1879,	123,	290,	378,	288,	632,	2251,	332,	693,	778,	1327,	1939,	1834,	2305,	453,	645,	95,	232,	720,	1483,	1793,	289,	752,	2164,	248,	916,	1686,	1768,	1993,	2068,	177,	452,	541,	558,	2028,	2320,	904,	905) 
				  then 2 -- 'Mid_group'
				  when a.point_of_sale in (786,	895,	1840,	2304,	113,	363,	1942,	2111,	2452,	597,	926,	1716,	1739,	1833,	2350,	2361,	359,	518,	1107,	1375,	1743,	2302,	431,	261,	537,	794,	1818,	2052,	543,	737,	888,	735,	2416,	1053,	780,	1897,	2381,	173,	314,	899,	1500,	2084,	345,	1617,	559,	2200,	1839,	225,	10,	22,	25,	154,	159,	176,	180,	190,	211,	222,	249,	296,	323,	354,	394,	429,	479,	540,	607,	759,	779,	890,	1037,	1328,	1338,	1406,	1561,	1581,	1598,	1663,	1713,	1762,	1766,	1809,	1854,	1868,	1994,	2016,	2047,	2062,	2085,	2333,	2423,	2553,	2574,	2654)
				  then 3 -- 'Good_group' 
				  else 0 --'Other' 
				  end point_of_sale_group,
				case when datediff(year,birth_date,b.appl_date)<=29 and  datediff(year,birth_date,b.appl_date)>=21 then 1 --'Bad_group'
					 when datediff(year,birth_date,b.appl_date)<=41 and  datediff(year,birth_date,b.appl_date)>=30 then 2 --'Mid_group'
					 when datediff(year,birth_date,b.appl_date)<=65 and  datediff(year,birth_date,b.appl_date)>=42 then 3 --'Good_group'
					 else 0 -- 'Other' 
					 end as age_group,

					 birth_date,

				case when oper in ('989',	'988',	'985',	'938',	'900',	'965',	'950',	'932',	'982',	'937',	'960',	'981',	'952',	'928',	'919',	'962',	'929',	'909',	'999',	'927')
				then 1 --'Bad_group'
					 when oper in ('915',	'910',	'961',	'925',	'963',	'951',	'977',	'987',	'906',	'912',	'905',	'918',	'904',	'953',	'980') 
					 then 2 -- 'Mid_group'
					 when oper in ('917',	'908',	'964',	'967',	'916',	'922',	'920',	'902',	'996',	'921',	'930',	'911',	'913',	'903',	'926',	'968',	'931') 
					 then 3 -- 'Good_group' 
					 else 0 --'Other' 
					 end as oper_group,

					 			


         a.accepted_amount,--equifax_score, 
		 b.*,
--		FSSP_amt,
		 --max_dpd_6month,
		a.point_of_sale,  --FPD_30_Matured, HR90@6_Matured, dpd_60_ever,
		--D.*, 
		E.house_index
INTO #SCR_Application3	
-----!!------
FROM  tmp_v_requests  a   
LEFT JOIN (
            select distinct a.id,b.name as gender,c.name as family_status, SUBSTRING(mobile_phone,1,3) as oper, mobile_phone,birth_date 
            from persons a
            left join gender b 
            on a.gender = b.id 
            left join family_status c 
            on a.family_status = c.id
			--16/10/2020 datsyplakov - исключаем запись с id = -1 (пустая), чтобы не было ошибки по конвертации NaN в integer
			where a.id <> -1
			) as C
 ON a.person_id = C.id
 LEFT JOIN (
             select distinct external_id, appl_date, --return_type,
							--accepted_amount,
							equifax_score, 
							financed, 
							--is_app,  
							is_rej, reject_reason,reject_category,--is_ann,
--		                     FSSP_amt,
							  fpd30, HR90@6, 
							  max_dpd_6month, 
							  channel, 
							  --channel_attr, group_attr, 
							  --point_of_sale, 
							  region_sale, region_reg, generation, 
							 case when datediff(day,appl_date,GETDATE()-1) > 61 then 1 else 0 end as FPD_30_Matured,
							 case when datediff(month,appl_date,GETDATE()-1) >= 6 then 1 else 0 end as HR90@6_Matured, 
							 case when max_dpd_6month > 60 then 1 else 0 end as dpd_60_ever
             from [Reports].[dbo].[dm_Maindata]
			 --where new_status ='11.Заём выдан'
			 ) b
ON a.external_id = b.external_id
left join  stg._1cMFO.Документ_ГП_Заявка cl on cl.номер=a.external_id

LEFT JOIN (
           SELECT A.* FROM (
                            SELECT person_id, 
							vale as house_index, 
							created,
							ROW_NUMBER() OVER(PARTITION BY person_id ORDER BY created) as rn  
							
							FROM (
                                   select distinct rr.person_id,  
								                   created,
	                                               bk.value vale,
                                                   ROW_NUMBER() OVER(PARTITION BY address_text,rr.person_id ORDER BY (SELECT NULL) DESC) as rn 
                                   from addresses rr 
                                   cross apply string_split(address_text,',') bk
								   ) as A
                             WHERE rn = 2 and LEN(vale) = 6) as A
                       WHERE rn = 1
			) as E

ON a.person_id = E.person_id;
--where cast(request_date as date) >= '2019-06-01' and cast(request_date as date) <= '2019-08-31'
--and return_type = '';


/******!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EQUIFAX!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ******/

drop table if exists #SCR_EQUIF3;
drop table if exists #eqv_credits3;
with pat as (select distinct c_i,v, response_date response_date_pat from bki.eqv_additional
where flag_correct=1 and n=831)

SELECT  [cred_id]
      ,[cred_first_load]
      ,[cred_owner]
      ,[cred_partner_type]
      ,[cred_person_num]
      ,[cred_ratio]
      ,[cred_sum]
      ,[cred_currency]
      ,[cred_date]
      ,[cred_enddate]
      ,[cred_sum_payout]
      ,[cred_date_payout]
      ,[cred_sum_debt]
      ,[cred_sum_limit]
      ,[delay5]
      ,[delay30]
      ,[delay60]
      ,[delay90]
      ,[delay_more]
      ,[cred_sum_overdue]
      ,[cred_day_overdue]
      ,[cred_max_overdue]
      ,[cred_prolong]
      ,[cred_collateral]
      ,[cred_update]
      ,[cred_type]
      ,[cred_active] 
      ,[cred_active_date]
      ,[cred_sum_type]
      ,[cred_full_cost]
      ,[external_id]
      ,[flag_correct]
      ,[rn]
      ,[response_date]
	  ,v into #eqv_credits3 
  FROM [dwh_new].[bki].[eqv_credits]
  join pat on c_i=cred_id and response_date_pat=response_date
  where flag_correct=1;
  --drop table #SCR_EQUIF
  
with opdateNum_equi as (select max(cred_date) modt, external_id external_id_equi from #eqv_credits3 group by external_id) 
SELECT A.*
INTO #SCR_EQUIF3
FROM (
SELECT external_id as equif_external_id, 
       min(openedDt) as first_open_equif,  max(openedDt) as last_open_equif, max(lastPaymtDt) as lastPaymtDt_equif, max(reportingDt) as last_reportingDt_equif, 
       count(*) as cnt_total_equif, sum(closed) as cnt_closed_equif, 
	   sum(curr_overd) as cnt_curr_overd_equif, 
	   sum(active) as cnt_active_equif,sum(sold) as cnt_sold_equif,
	   max(depth_ch) as depth_ch_equif, max(creditLimit) max_limit,avg(creditLimit) avg_limit, 
	   max(cred_full_cost) max_cost,avg(cred_full_cost) avg_cost, 
	   case when sum(amtPastDue)>0 then 1 else 0 end total_curr_overd_group,
	   sum(case when  cred_type in (4,14)	then amtPastDue else NULL end) as cc_overdue,
	   sum(case when  cred_type in (4,14)	then cred_sum_debt else NULL end) as cc_debt,
	   sum(case when  cred_type in (4,14)   then [cred_sum_limit] else NULL end) as cc_limit2,
	   
	   case when max(case when cred_type in (5, 18)						 then creditLimit else NULL end)<= 175000 then 1 -- '<=10000'
			when max(case when cred_type in (5, 18)						 then creditLimit else NULL end)<= 370000 then 2 --'10000<x<=50000'
			when max(case when cred_type in (5, 18)						 then creditLimit else NULL end)<= 700000 then 3 --'50000<x<=150000'
			when max(case when cred_type in (5, 18)						 then creditLimit else NULL end)> 700000 then 4 --'150000<x<=500000'
			else 0 --'Other' 
			end max_limit_potreb_equif_group,
	   case when avg(creditLimit)<= 10000 then 1 --'<=10000'
			when avg(creditLimit)<= 50000 then 2 --'10000<x<=50000'
			when avg(creditLimit)<= 200000 then 3 --'50000<x<=200000'
			when avg(creditLimit)<= 500000 then 4 --'200000<x<=500000'
			when avg(creditLimit)<= 1000000 then 5-- '500000<x<=1000000' 
			when avg(creditLimit)> 1000000 then 6 --'x>1000000' 
			else 0 --'Other' 
			end avg_limit_group,
		case when max(depth_ch)<=3 then	  1 --'<=3'
			 when max(depth_ch)<=10 then  2 --'3<x<=10'
			 when max(depth_ch)<=36 then  3 --'10<x<=36'
			 when max(depth_ch)<=120 then 4 --'36<x<=120'
			 when max(depth_ch)<=130 then 5 --'130<x<=130'
			 when max(depth_ch)>130 then  6 --'>130' 
			 else  0 --'Other'
			 end as depth_ch_equif_group,



       avg(case when cred_type = 1								 then creditLimit else NULL end) as avg_limit_autocr_equif,
	   max(case when cred_type = 1								 then creditLimit else NULL end) as max_limit_autocr_equif,  
	   max(case when cred_type in (4,14)						 then creditLimit else NULL end) as max_limit_cc_equif,	   
	   avg(case when cred_type in (4,14)						 then creditLimit else NULL end) as avg_limit_cc_equif,	  
	   max(case when cred_type in (5, 18)						 then creditLimit else NULL end) as max_limit_potreb_equif,  
	   avg(case when cred_type in (5, 18)						 then creditLimit else NULL end) as avg_limit_potreb_equif, 
	   max(case when cred_type in (19,20) and creditLimit>30000  then creditLimit else NULL end) as max_limit_big_mfo_equif, 
	   avg(case when cred_type in (19,20) and creditLimit>30000  then creditLimit else NULL end) as avg_limit_big_mfo_equif,
	   max(case when cred_type in (19,20) and creditLimit<=30000 then creditLimit else NULL end) as max_limit_pdl_equif,	   
	   avg(case when cred_type in (19,20) and creditLimit<=30000 then creditLimit else NULL end) as avg_limit_pdl_equif,	  
	   min(case when cred_type = 1								 then cred_full_cost else NULL end) as min_cost_autocr_equif, 
	   avg(case when cred_type = 1								  then cred_full_cost else NULL end) as avg_cost_autocr_equif, 
	   min(case when cred_type in (4,14)						 then cred_full_cost else NULL end) as min_cost_cc_equif,	    
	   avg(case when cred_type in (4,14)						  then cred_full_cost else NULL end) as avg_cost_cc_equif,	 
	   min(case when cred_type in (5, 18)						 then cred_full_cost else NULL end) as min_cost_potreb_equif, 
	   avg(case when cred_type in (5, 18)						  then cred_full_cost else NULL end) as avg_cost_potreb_equif, 
	   min(case when cred_type in (19,20) and creditLimit>30000  then cred_full_cost else NULL end) as min_cost_big_mf_equif,
	   avg(case when cred_type in (19,20) and creditLimit>30000  then cred_full_cost else NULL end) as avg_cost_big_mfo_equif,
	   min(case when cred_type in (19,20) and creditLimit<=30000 then cred_full_cost else NULL end) as min_cost_pdl_equif,	
	   avg(case when cred_type in (19,20) and creditLimit<=30000 then cred_full_cost else NULL end) as avg_cost_pdl_equif,
	   max(case when cred_type = 1								 then cred_max_overdue else NULL end) as max_maxOverdue_autocr_equif, 
	   avg(case when cred_type = 1								  then cred_max_overdue else NULL end) as avg_maxOverdue_autocr_equif, 
	   max(case when cred_type in (4,14)						 then cred_max_overdue else NULL end) as max_maxOverdue_cc_equif,	    
	   avg(case when cred_type in (4,14)						  then cred_max_overdue else NULL end) as avg_maxOverdue_cc_equif,	 
	   max(case when cred_type in (5, 18)						 then cred_max_overdue else NULL end) as max_maxOverdue_potreb_equif, 
	   avg(case when cred_type in (5, 18)						  then cred_max_overdue else NULL end) as avg_maxOverdue_potreb_equif, 
	   max(case when cred_type in (19,20) and creditLimit>30000  then cred_max_overdue else NULL end) as max_maxOverdue_big_mfo_equif,
	   avg(case when cred_type in (19,20) and creditLimit>30000  then cred_max_overdue else NULL end) as avg_maxOverdue_big_mfo_equif,
	   max(case when cred_type in (19,20) and creditLimit<=30000 then cred_max_overdue else NULL end) as max_maxOverdue_pdl_equif,	
	   avg(case when cred_type in (19,20) and creditLimit<=30000 then cred_max_overdue else NULL end) as avg_maxOverdue_pdl_equif,		 
	   sum(bankruptcy) as cnt_bankruptcy_equif, sum(beznadezh) as cnt_beznadezh_equif, 
	   sum(case when cred_type in (19,20) then cred_prolong else NULL end) as cnt_mfo_prolong_equif,
       sum(autocr) as cnt_auto_equif, sum(cc) as cnt_cc_equif, sum(potreb) as cnt_potreb_equif, 
	   sum(big_mfo) as cnt_big_mfo_equif, sum(pdl) as cnt_pdl_equif,
	   sum(autocr_closed) as cnt_autocr_closed_equif, sum(autocr_overd) as cnt_autocr_overd_equif, 
	   sum(autocr_active) as cnt_autocr_active_equif, sum(autocr_sold) as cnt_autocr_sold_equif,  
	   sum(autocr_bankruptcy) as cnt_autocr_bankruptcy_equif, 
	   sum(cc_closed) as cnt_cc_closed_equif, sum(cc_overd) as cnt_cc_overd_equif, 
	   sum(cc_active) as cnt_cc_active_equif,							
	   sum(cc_sold) as cnt_cc_sold_equif,  
	   sum(cc_bankruptcy) as cnt_cc_bankruptcy_equif,
	   sum(potreb_closed) as cnt_potreb_closed_equif, 
	   sum(potreb_overd) as cnt_potreb_overd_equif, sum(potreb_active) as cnt_potreb_active_equif, 
	   sum(potreb_sold) as cnt_potreb_sold_equif,  sum(potreb_bankruptcy) as cnt_potreb_bankruptcy_equif,
	   sum(big_mfo_closed) as cnt_big_mfo_closed_equif, sum(big_mfo_overd) as cnt_big_mfo_overd_equif, 
	   sum(big_mfo_active) as cnt_big_mfo_active_equif,	sum(big_mfo_sold) as cnt_big_mfo_sold_equif,  
	   sum(big_mfo_bankruptcy) as cnt_big_mfo_bankruptcy_equif, sum(pdl_closed) as cnt_pdl_closed_equif, 
	   sum(pdl_overd) as cnt_pdl_overd_equif, sum(pdl_active) as cnt_pdl_active_equif, sum(pdl_sold) as cnt_pdl_sold_equif,  
	   sum(pdl_bankruptcy) as cnt_pdl_bankruptcy_equif, sum(amtPastDue) as total_curr_overd_equif, sum(active_limit) as sum_limit_active_equif, 
	   sum(no_overdue) as Cnt_no_overdue_loans_equif, sum(dpd_5) as Cnt_dpd_5_loans_equif,sum(dpd_30) as cnt_dpd_30_loans_equif,
	   sum(dpd_60) as cnt_dpd_60_loans_equif, sum(dpd_90) as cnt_dpd_90_loans_equif,sum([dpd_120+]) as cnt_dpd_120_loans_equif,
	   sum(dpd_90_autocr) as cnt_dpd_90_autocr_equif, sum(dpd_90_cc) as cnt_dpd_90_cc_equif, sum(dpd_90_potreb) as cnt_dpd_90_potreb_equif,
	   sum(dpd_90_big_mfo) as cnt_dpd_90_big_mfo_equif, sum(dpd_90_pdl) as cnt_dpd_90_pdl_equif,
	   sum(dpd_120_autocr) as cnt_dpd_120_autocr_equif, sum(dpd_120_cc) as cnt_dpd_120_cc_equif, sum(dpd_120_potreb) as cnt_dpd_120_potreb_equif,
	   sum(dpd_120_big_mfo) as cnt_dpd_120_big_mfo_equif, sum(dpd_120_pdl) as cnt_dpd_120_pdl_equif,
	   sum(cnt_no_overdue) as cnt_no_overdue_paym_equif, sum(cnt_dpd_5) as cnt_dpd_5_paym_equif_equif,sum(cnt_dpd_30) as cnt_dpd_30_paym_equif,
	   sum(cnt_dpd_60) as cnt_dpd_60_paym_equif, sum(cnt_dpd_90) as cnt_dpd_equif_90_paym_equif, sum([cnt_dpd_120+]) as cnt_dpd_120_paym_equif,
	   case when sum( bad_many_mfo)>3 then 1 else 0 end bad_many_mfo_equif, case when sum( bad_many_notmfo)>3 then 1 else 0 end bad_many_notmfo_equif,
	   case when datediff(year,max(openedDt),min(response_date))>4 or datediff(month,min(openedDt),min(response_date))<3 then 1 else 0 end as length_ch_equif,


	   case when sum(curr_overd_equi) > 0 then 1 else 0 end  isDecl1_equi,
	   case when sum(beznadezh) > 0 then 1 else 0 end isDecl2_equi,
	   --case when max(date_after_last5_equi) < max(openedDt) then 0 else 1 end isDecl3_equi,
	   case when sum(dpd60_curr_equi) >= 2 or sum( dpd30_curr_equi) >= 4 then 1 else 0 end isDecl4_equi
	   
FROM ( 
       select 
	          external_id, cred_date openedDt,cred_type acctType, cred_sum creditLimit, cred_sum_overdue amtPastDue,  response_date response_date, 
	          cred_update reportingDt, cred_date_payout lastPaymtDt,delay30 numDays30,delay60 numDays60, delay90 numDays90,v paymtPat, cred_prolong,
			  cred_full_cost, cred_type, cred_max_overdue,cred_sum_debt,[cred_sum_limit],
			  case when  v like '%B%' then 1 else 0 end as beznadezh,
			  case when  v like '%S%' then 1 else 0 end as prodan,    
              case when  v like '%W%' then 1 else 0 end as collection,    
			  (len(v) - LEN(REPLACE(v, '0', '')))  as cnt_no_overdue,

			  case when (len(v) - LEN(REPLACE(v, '0', '')))  > 0 then 1 else 0 end as no_overdue,
			  (len(v) - LEN(REPLACE(v, '1', '')))  as cnt_dpd_5,
			  case when v like '%1%' then 1 else 0 end as dpd_5,
			  (len(v) - LEN(REPLACE(v, '2', ''))) as cnt_dpd_30,
			  case when  v like '%2%' then 1 else 0 end as dpd_30,
			  (len(v) - LEN(REPLACE(v, '3', ''))) as cnt_dpd_60,
			  case when v like '%3%' then 1 else 0 end as dpd_60,
			  (len(v) - LEN(REPLACE(v, '4', ''))) as cnt_dpd_90,
			  case when  v like '%4%' then 1 else 0 end as dpd_90,
			  (len(v) - LEN(replace(replace(replace(replace(REPLACE(v, '5', ''),'6',''), '7',''), '8',''),'9',''))) as [cnt_dpd_120+],
			  case when v like '%5%' or  v like '%6%' or  v like '%7%' or  v like '%8%' or v  like '%9%' then 1 else 0 end as [dpd_120+],
			  (len(v) - LEN(REPLACE(v, '-', ''))) as cnt_hren,
			  case when v like '%-%' then 1 else 0 end as hren,
  
              case when v like '%4%' and cred_type = 1							  then 1 else 0 end as dpd_90_autocr,
			  case when v like '%4%' and cred_type in (4,14)					  then 1 else 0 end as dpd_90_cc,
			  case when v like '%4%' and cred_type in (5, 18)					  then 1 else 0 end as dpd_90_potreb,
			  case when v like '%4%' and cred_type in (19,20) and cred_sum>50000  then 1 else 0 end as dpd_90_big_mfo,
			  case when v like '%4%' and cred_type in (19,20) and cred_sum<=50000 then 1 else 0 end as dpd_90_pdl,

			  case when v like '%5%' and cred_type = 1							  then 1 else 0 end as dpd_120_autocr,
			  case when v like '%5%' and cred_type in (4,14)					  then 1 else 0 end as dpd_120_cc,
			  case when v like '%5%' and cred_type in (5, 18)					  then 1 else 0 end as dpd_120_potreb,
			  case when v like '%5%' and cred_type in (19,20) and cred_sum>50000  then 1 else 0 end as dpd_120_big_mfo,
			  case when v like '%5%' and cred_type in (19,20) and cred_sum<=50000 then 1 else 0 end as dpd_120_pdl,

	          case when cred_type = 1		                     then 1 else 0 end as autocr,
			  case when cred_type in (4,14)                      then 1 else 0 end as cc,
			  case when cred_type in (5, 18)                     then 1 else 0 end as potreb,
			  case when cred_type in (19,20) and cred_sum>50000  then 1 else 0 end as big_mfo,
			  case when cred_type in (19,20) and cred_sum<=50000 then 1 else 0 end as pdl,

			  case when cred_active = 1 and cred_sum_overdue<=1000                                   then 1 else 0 end as active, 
			  case when cred_active in (1,10,11,12,13,14,15,16,17,18,19,3) and cred_sum_overdue>1000 then 1 else 0 end as curr_overd,
			  case when cred_active in (0,20,8,4)                                                    then 1 else 0 end as closed, 
			  case when cred_active in (2,5)														 then 1 else 0 end as sold, 
			  case when cred_active in (9)															 then 1 else 0 end as bankruptcy,  


			  case when cred_type = 1		  and cred_active in (0,20,8,4)                      then 1 else 0 end as autocr_closed,
			  case when cred_type in (4,14)   and cred_active in (0,20,8,4)                      then 1 else 0 end as cc_closed,
			  case when cred_type in (5, 18)  and cred_active in (0,20,8,4)                      then 1 else 0 end as potreb_closed,
			  case when cred_type in (19,20)  and cred_sum<=50000  and cred_active in (0,20,8,4) then 1 else 0 end as pdl_closed,
			  case when cred_type in (19,20)  and cred_sum>50000   and cred_active in (0,20,8,4) then 1 else 0 end as big_mfo_closed,

			  case when cred_type = 1		 and						cred_active in (1,10,11,12,13,14,15,16,17,18,19,3) and cred_sum_overdue>1000 then 1 else 0 end as autocr_overd,
			  case when cred_type in (4,14)  and						cred_active in (1,10,11,12,13,14,15,16,17,18,19,3) and cred_sum_overdue>1000 then 1 else 0 end as cc_overd,
			  case when cred_type in (5, 18) and						cred_active in (1,10,11,12,13,14,15,16,17,18,19,3) and cred_sum_overdue>1000 then 1 else 0 end as potreb_overd,
			  case when cred_type in (19,20) and cred_sum<=50000   and  cred_active in (1,10,11,12,13,14,15,16,17,18,19,3) and cred_sum_overdue>1000 then 1 else 0 end as pdl_overd,
			  case when cred_type in (19,20) and cred_sum>50000    and  cred_active in (1,10,11,12,13,14,15,16,17,18,19,3) and cred_sum_overdue>1000 then 1 else 0 end as big_mfo_overd,

			  case when cred_type = 1							  and cred_active = 1 and cred_sum_overdue<=1000    then 1 else 0 end as autocr_active,
			  case when cred_type in (4,14)						  and cred_active = 1 and cred_sum_overdue<=1000    then 1 else 0 end as cc_active,
			  case when cred_type in (5, 18)					  and cred_active = 1 and cred_sum_overdue<=1000    then 1 else 0 end as potreb_active,
			  case when cred_type in (19,20) and cred_sum<=50000  and cred_active = 1 and cred_sum_overdue<=1000    then 1 else 0 end as pdl_active,
			  case when cred_type in (19,20) and cred_sum>50000   and cred_active = 1 and cred_sum_overdue<=1000    then 1 else 0 end as big_mfo_active,

			  case when cred_type = 1		 and cred_active in (2,5) then 1 else 0 end as autocr_sold,
			  case when cred_type in (4,14)  and cred_active in (2,5) then 1 else 0 end as cc_sold,
			  case when cred_type in (5, 18) and cred_active in (2,5) then 1 else 0 end as potreb_sold,
			  case when cred_type in (19,20) and cred_sum<=50000  and cred_active in (2,5) then 1 else 0 end as pdl_sold,
			  case when cred_type in (19,20) and cred_sum>50000   and cred_active in (2,5) then 1 else 0 end as big_mfo_sold,

			  case when cred_type = 1		 and cred_active in (9) then 1 else 0 end as autocr_bankruptcy,
			  case when cred_type in (4,14)  and cred_active in (9) then 1 else 0 end as cc_bankruptcy,
			  case when cred_type in (5, 18) and cred_active in (9) then 1 else 0 end as potreb_bankruptcy,
			  case when cred_type in (19,20) and cred_sum<=50000  and cred_active in (9) then 1 else 0 end as pdl_bankruptcy,
			  case when cred_type in (19,20) and cred_sum>50000   and cred_active in (9) then 1 else 0 end as big_mfo_bankruptcy,


			  case when cred_active = 1 and cred_currency in ( 'RUB', 'RUR') then [cred_sum_limit]
			       when cred_active = 1 and cred_currency = 'USD' then [cred_sum_limit] * 65
			       when cred_active = 1 and cred_currency = 'EUR' then [cred_sum_limit] * 72 else 0 end as active_limit, 

			  max(DATEDIFF(MONTH,cred_date,response_date)) over (partition by external_id) depth_ch,

		 
			  case when cred_sum_overdue>= 1000 and cred_type in (19,20)	 then 1 else 0 end as bad_many_mfo,
			  case when cred_sum_overdue>= 5000 and cred_type not in (19,20) then 1 else 0 end as bad_many_notmfo,


			case when cred_active in (1,10,11,12,13,14,15,16,17,18,19,3) 
			--and (LEFT(v,1) = '5' or LEFT(v,1) = '6'  or LEFT(v,1) = '7' or LEFT(v,1) = '8' or LEFT(v,1) = '9') 
			and cred_day_overdue > 90
			and cred_sum_overdue>1000 then 1 else 0 end curr_overd_equi,
			case when LEFT(v,1) = '2' then 1 else 0 end dpd30_curr_equi,
			case when LEFT(v,1) = '3' then 1 else 0 end dpd60_curr_equi
			,case when cred_active in (0,20,8,4) and cred_date = modt and (v like '%6%' or v like '%7%' or v like '%8%' or v like '%9%') then 1 else 0 end as isLastClosedCreditOverd


       from #eqv_credits3 e left join opdateNum_equi oe on e.external_id=oe.external_id_equi
       where  flag_correct = 1 
	   
	   --and external_id = '19093000000173'

	   ) as a
	   where datediff(year,openedDt, response_date)<5
        group by external_id

) AS A 

--select top 100 * from #eqv_credits3

/******!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!NBKI!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ******/

 drop table if exists #SCR_NBKI3;
with opdateNum as (select external_id, max(openedDt) modt from bki.n_accountreply where  flag_correct = 1 group by external_id) 
SELECT external_id as nbki_external_id, min(openedDt) as first_open_nbki,  max(openedDt) as last_open, max(lastPaymtDt) as lastPaymtDt, max(reportingDt) as last_reportingDt, 
       count(*) as cnt_total, sum(closed) as cnt_closed, sum(curr_overd) as cnt_curr_overd, sum(active) as cnt_active,
	   sum(beznadezh) as cnt_beznadezh, sum(pay_by_zalog) as cnt_pay_by_zalog, 
       sum(autocr) as cnt_auto, sum(cc) as cnt_cc, sum(potreb) as cnt_potreb, sum(mfo) as cnt_mfo,
	   sum(autocr_closed) as cnt_autocr_closed, sum(autocr_overd) as cnt_autocr_overd, sum(autocr_active) as cnt_autocr_active,
	   sum(cc_closed) as cnt_cc_closed, sum(cc_overd) as cnt_cc_overd, sum(cc_active) as cnt_cc_active,
	   sum(potreb_closed) as cnt_potreb_closed, sum(potreb_overd) as cnt_potreb_overd, sum(potreb_active) as cnt_potreb_active,
	   sum(mfo_closed) as cnt_mfo_closed, sum(mfo_overd) as cnt_mfo_overd, sum(mfo_active) as cnt_mfo_active,
	   sum(amtPastDue) as total_curr_overd, sum(active_limit) as sum_limit_active, sum(active_paid) as sum_active_paid, sum(total_paid) as sum_total_paid,
	   sum(no_overdue) as Cnt_no_overdue_loans, sum(dpd_5) as Cnt_dpd_5_loans,sum(dpd_30) as cnt_dpd_30_loans,
	   sum(dpd_60) as cnt_dpd_60_loans,sum(dpd_90) as cnt_dpd_90_loans,sum(dpd_120) as cnt_dpd_120_loans,
	   sum(dpd_90_autocr) as cnt_dpd_90_autocr, sum(dpd_90_cc) as cnt_dpd_90_cc, sum(dpd_90_potreb) as cnt_dpd_90_potreb,sum(dpd_90_mfo) as cnt_dpd_90_mfo,
	   sum(dpd_120_autocr) as cnt_dpd_120_autocr, sum(dpd_120_cc) as cnt_dpd_120_cc, sum(dpd_120_potreb) as cnt_dpd_120_potreb,sum(dpd_120_mfo) as cnt_dpd_120_mfo,
	   sum(cnt_no_overdue) as cnt_no_overdue_paym, sum(cnt_dpd_5) as cnt_dpd_5_paym,sum(cnt_dpd_30) as cnt_dpd_30_paym,
	   sum(cnt_dpd_60) as cnt_dpd_60_paym,sum(cnt_dpd_90) as cnt_dpd_90_paym,sum(cnt_dpd_120) as cnt_dpd_120_paym,
	   max(bad_mfo) bad_mfo, max(bad_notmfo) bad_notmfo, max(beznadezh_loan) beznadezh_loan,
	   case when sum( bad_many_mfo)>3 then 1 else 0 end bad_many_mfo, case when sum( bad_many_notmfo)>3 then 1 else 0 end bad_many_notmfo,
	   case when datediff(year,max(openedDt),min(response_date))>4 or datediff(month,min(openedDt),min(response_date))<3 then 1 else 0 end as length_ch,
	   		case	 when sum(active_paid)<=100000 then 1 --'50000<x<=100000'
			 when sum(active_paid)<=200000 then 2 --'100000<x<=200000'
			 when sum(active_paid)<=500000 then 3 --'200000<x<=500000'
			 when sum(active_paid)<=1000000 then 4 --'500000<x<=1000000'
			 when sum(active_paid)>1000000 then 5 --'>1000000' 
			 else 0 --'Other'
			 end sum_active_paid_group,

		case when (sum(cnt_no_overdue) + sum(cnt_dpd_5)  + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			        else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5)  + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end as dolya_NoDPD_pmt_0, 

		case  when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			           else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue)+ sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end as dolya_NoDPD_pmt,

			 case when case when  external_id is null then 2 
						 when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			             else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end <=0.44 then 1 
            when case when  external_id is null then 2 
						 when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			             else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end > 0.44 
						 and case when  external_id is null then 2 
						 when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			             else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end <= 0.71 then 2 
			when case when  external_id is null then 2 
						 when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			             else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end > 0.71 
						 and case when  external_id is null then 2 
						 when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			             else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end <= 0.87 then 3 
			when case when  external_id is null then 2 
						 when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			             else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end > 0.87 
						 and case when  external_id is null then 2 
						 when (sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) = 0  then 0 
			             else cast(sum(cnt_no_overdue) as float)/cast((sum(cnt_no_overdue) + sum(cnt_dpd_5) + sum(cnt_dpd_30) + sum(cnt_dpd_60) + sum(cnt_dpd_90)) as float) end < 2 then 4 else 0 end as dolya_NoDPD_pmt_group,

		
		case when sum(curr_overd_nbki) >= 1 then 1 else 0 end  isDecl1_nbki,
		case when sum(beznadezh) > 0 then 1 else 0 end isDecl2_nbki,
		case when sum(isLastClosedCreditOverd) > 0 then 1 else 0 end isDecl3_nbki,
		case when sum(dpd30_curr_nbki) >= 4 OR  sum(dpd60_curr_nbki) >= 2 then 1 else 0 end isDecl4_nbki

INTO #SCR_NBKI3
FROM ( 
       select 
	          b.external_id,openedDt,acctType,creditLimit, curBalanceAmt, amtPastDue, accountRating, response_date, 
	          reportingDt,lastPaymtDt,numDays30,numDays60,numDays90,paymtPat,
			  case when paymtPat like '%9%' or  paymtPat like '%5***5***5***5***5***5***5%'  then 1 else 0 end as beznadezh,
			  case when paymtPat like '%8%' then 1 else 0 end as pay_by_zalog,    
			  CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '1', '')) as INT) as cnt_no_overdue,
			  case when CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '1', '')) as INT) > 0 then 1 else 0 end as no_overdue,
			  CAST(len(paymtPat) - LEN(REPLACE(paymtPat, 'A', '')) as INT) as cnt_dpd_5,
			  case when CAST(len(paymtPat) - LEN(REPLACE(paymtPat, 'A', '')) as INT) > 0 then 1 else 0 end as dpd_5,
			  CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '2', '')) as INT) as cnt_dpd_30,
			  case when CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '2', '')) as INT) > 0 then 1 else 0 end as dpd_30,
			  CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '3', '')) as INT) as cnt_dpd_60,
			  case when CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '3', '')) as INT) > 0 then 1 else 0 end as dpd_60,
			  CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '4', '')) as INT) as cnt_dpd_90,
			  case when CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '4', '')) as INT) > 0 then 1 else 0 end as dpd_90,
			  CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '5', '')) as INT) as cnt_dpd_120,
			  case when CAST(len(paymtPat) - LEN(REPLACE(paymtPat, '5', '')) as INT) > 0 then 1 else 0 end as dpd_120,
			  CAST(len(paymtPat) - LEN(REPLACE(paymtPat, 'X', '')) as INT) as cnt_hren,
			  case when CAST(len(paymtPat) - LEN(REPLACE(paymtPat, 'X', '')) as INT) > 0 then 1 else 0 end as hren,
  
              case when paymtPat like '%4%' and accttype = 1 then 1 else 0 end as dpd_90_autocr,
			  case when paymtPat like '%4%' and accttype = 7 then 1 else 0 end as dpd_90_cc,
			  case when paymtPat like '%4%' and accttype = 9 then 1 else 0 end as dpd_90_potreb,
			  case when paymtPat like '%4%' and accttype = 16 then 1 else 0 end as dpd_90_mfo,

			  case when paymtPat like '%5%' and accttype = 1 then 1 else 0 end as dpd_120_autocr,
			  case when paymtPat like '%5%' and accttype = 7 then 1 else 0 end as dpd_120_cc,
			  case when paymtPat like '%5%' and accttype = 9 then 1 else 0 end as dpd_120_potreb,
			  case when paymtPat like '%5%' and accttype = 16 then 1 else 0 end as dpd_120_mfo,

	          case when accttype = 1 then 1 else 0 end as autocr,
			  case when accttype = 7 then 1 else 0 end as cc,
			  case when accttype = 9 then 1 else 0 end as potreb,
			  case when accttype = 16 then 1 else 0 end as mfo,

			  case when accountRating = 13 then 1 else 0 end as closed, 
			  case when accountRating = 52 then 1 else 0 end as curr_overd,

			  
			  case when accountRating = 0 then 1 else 0 end as active, 

			  case when accttype = 1 and accountRating = 13 then 1 else 0 end as autocr_closed,
			  case when accttype = 7 and accountRating = 13 then 1 else 0 end as cc_closed,
			  case when accttype = 9 and accountRating = 13 then 1 else 0 end as potreb_closed,
			  case when accttype = 16 and accountRating = 13 then 1 else 0 end as mfo_closed,

			  case when accttype = 1 and accountRating = 52 then 1 else 0 end as autocr_overd,
			  case when accttype = 7 and accountRating = 52 then 1 else 0 end as cc_overd,
			  case when accttype = 9 and accountRating = 52 then 1 else 0 end as potreb_overd,
			  case when accttype = 16 and accountRating = 52 then 1 else 0 end as mfo_overd,

			  case when accttype = 1 and accountRating = 0 then 1 else 0 end as autocr_active,
			  case when accttype = 7 and accountRating = 0 then 1 else 0 end as cc_active,
			  case when accttype = 9 and accountRating = 0 then 1 else 0 end as potreb_active,
			  case when accttype = 16 and accountRating = 0 then 1 else 0 end as mfo_active,

			  case when accountRating in (0,52) and currencyCode in ( 'RUB', 'RUR') then creditLimit
			       when accountRating in (0,52) and currencyCode = 'USD' then creditLimit * 65
			       when accountRating in (0,52) and currencyCode = 'EUR' then creditLimit * 72 else 0 end as active_limit, 

			  case when accountRating in (0,52) and currencyCode = 'RUB' then curBalanceAMt
			       when accountRating in (0,52) and currencyCode = 'USD' then curBalanceAMt * 65
			       when accountRating in (0,52) and currencyCode = 'EUR' then curBalanceAMt * 72 else 0 end as active_paid,

			  case when currencyCode in ( 'RUB', 'RUR') then curBalanceAMt
			       when currencyCode = 'USD' then curBalanceAMt * 65
			       when currencyCode = 'EUR' then curBalanceAMt * 72 else 0 end as total_paid,


			  case when amtpastdue>=1000 and (paymtPat like '%4%'
										  or paymtPat like '%5%'
--										  or paymtPat like '%7%'
										  or paymtPat like '%8%'
										  or paymtPat like '%9%') and acctType=16 then 1 else 0 end as 	bad_mfo,

			  case when amtpastdue>=5000 and (paymtPat like '%4%'
										  or paymtPat like '%5%'
--										  or paymtPat like '%7%'
										  or paymtPat like '%8%'
										  or paymtPat like '%9%') and acctType in (1,7,9,17,18) then 1 else 0 end as 	bad_notmfo,	

			  case when ( paymtPat like '%8%' or paymtPat like '%9%'
						or paymtPat like '%5***5***5%') 
						and accountRating in(0,52,61) 	
						and DATEDIFF(month,	reportingDt,response_date)<12	then 1 else 0 end as beznadezh_loan,
			 
			  case when amtPastDue>= 1000 and acctType=16 then 1 else 0 end as bad_many_mfo,
			  case when amtPastDue>= 5000 and acctType != 16 then 1 else 0 end as bad_many_notmfo,
--			  into #SCR_NBKI2

			  case when accountRating = 52 and (left(paymtPat,1) = '5' or  left(paymtPat,1) = '4') and amtPastDue >= 1000 then 1 else 0 end as curr_overd_nbki,
			  case when accountRating = 52 and LEFT(paymtPat,1) = '2' then 1 else 0 end dpd30_curr_nbki,
			  case when accountRating = 52 and LEFT(paymtPat,1) = '3' then 1 else 0 end dpd60_curr_nbki,
			  --case when accountRating = 52 and charindex('5', paymtPat) <> 0 then dateadd(month, -(charindex('5', paymtPat)+1), response_date) else NULL end as date_after_last5_nbki
			  case when accountRating = 13 and  openedDt = modt and
			  --row_number() over (order by openedDt) = (select max(rn) from (select row_number() over (order by openedDt) as rn from bki.n_accountreply) trn) and
			  paymtPat like '%5%' then 1 else 0 end as isLastClosedCreditOverd


       from bki.n_accountreply b
	   left join 
	   --(select max(openedDt) over (partition by external_id order by openedDT) modt, external_id from bki.n_accountreply where  flag_correct = 1) opdateNum on opdateNum.external_id = b.external_id
	   opdateNum on opdateNum.external_id = b.external_id
       where  flag_correct = 1 

	   ) as a
        group by external_id


drop table if exists #SCR_NBKI_DIFF;
with	 SCR_NBKI_WP as (select s.*, person_id nbki2_person_id, row_number() over (partition by person_id order by s.nbki_external_id) rn
-- into #SCR_NBKI_FQ
from #SCR_NBKI3 s left join tmp_v_requests r on s.nbki_external_id collate Cyrillic_General_CI_AS=r.external_id collate Cyrillic_General_CI_AS),
		 SCR_NBKI2 as (select s.*,
							  snf.total_curr_overd as f_total_curr_overd,
							  snf.sum_active_paid as f_sum_active_paid,
							  snf.cnt_total as f_cnt_total , 
							  snf.cnt_closed as f_cnt_closed,
							  snf.cnt_dpd_5_paym as f_cnt_dpd_5_paym,
							  snf.dolya_NoDPD_pmt_0 as f_dolya_NoDPD_pmt_0 from  SCR_NBKI_WP s left join (select * from SCR_NBKI_WP where rn = 1) as snf on snf.nbki2_person_id=s.nbki2_person_id)
select *,  
total_curr_overd - f_total_curr_overd as diff_total_curr_overd,
abs(total_curr_overd - f_total_curr_overd) as abs_diff_total_curr_overd,
case when total_curr_overd - f_total_curr_overd > -634274 and total_curr_overd - f_total_curr_overd <= 0 then 1
	 when total_curr_overd - f_total_curr_overd > 0 and total_curr_overd - f_total_curr_overd <= 1076845 then 2
	 else 3 end diff_total_curr_overd_group,

sum_active_paid - f_sum_active_paid as diff_sum_active_paid,
abs(sum_active_paid - f_sum_active_paid) as abs_diff_sum_active_paid,
case when sum_active_paid - f_sum_active_paid > -19131472 and sum_active_paid - f_sum_active_paid <= 0 then 1
	 when sum_active_paid - f_sum_active_paid > 0 and sum_active_paid - f_sum_active_paid <= 1330 then 2
	 when sum_active_paid - f_sum_active_paid > 1330 and sum_active_paid - f_sum_active_paid <= 70637 then 3
	 when sum_active_paid - f_sum_active_paid > 70637 and sum_active_paid - f_sum_active_paid <= 243186 then 4
	 when sum_active_paid - f_sum_active_paid > 243186 and sum_active_paid - f_sum_active_paid <= 8729505 then 5
	 else 0 end diff_sum_active_paid_group,

dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 as diff_dolya_NoDPD_pmt_0,
abs(dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0) as abs_diff_dolya_NoDPD_pmt_0,
case when dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 > -19131472 and dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 <= 0 then 1
	 when dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 > 0 and dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 <= 1330 then 2
	 when dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 > 1330 and dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 <= 70637 then 3
	 when dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 > 70637 and dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 <= 243186 then 4
	 when dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 > 243186 and dolya_NoDPD_pmt_0 - f_dolya_NoDPD_pmt_0 <= 8729505 then 5
	 else 0 end diff_dolya_NoDPD_pmt_0_group,

cnt_dpd_5_paym - f_cnt_dpd_5_paym as diff_cnt_dpd_5_paym,
case when cnt_dpd_5_paym - f_cnt_dpd_5_paym > -23 and cnt_dpd_5_paym - f_cnt_dpd_5_paym <= 1 then 1
	 when cnt_dpd_5_paym - f_cnt_dpd_5_paym > 1 and cnt_dpd_5_paym - f_cnt_dpd_5_paym <= 4 then 2
	 when cnt_dpd_5_paym - f_cnt_dpd_5_paym > 4 and cnt_dpd_5_paym - f_cnt_dpd_5_paym <= 83 then 3
	 else 0 end diff_cnt_dpd_5_paym_group,

cnt_total - f_cnt_total as diff_cnt_total
--cnt_closed - f_cnt_closed as diff_cnt_closed

INTO #SCR_NBKI_DIFF
from  SCR_NBKI2



--select * from #SCR_NBKI_DIFF

--select * from #for_scoring3





/******!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!INQUIRIES NBKI!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!******/

SELECT external_id as inq_nbki_external_id, sum(total_inq_7days) as total_inq_7days, sum(mfo_inq_7days) as  mfo_inq_7days,
                    sum(total_inq_14days) as total_inq_14days, sum(mfo_inq_14days) as  mfo_inq_14days, 
					sum(total_inq_21days) as total_inq_21days, sum(mfo_inq_21days) as  mfo_inq_21days,
					sum(total_inq_30days) as total_inq_30days, sum(mfo_inq_30days) as  mfo_inq_30days, 
					sum(total_inq_180days) as total_inq_180days, sum(auto_inq_180days) as  auto_inq_180days,  sum(cc_inq_180days) as cc_inq_180days, 
					sum(potreb_inq_180days) as potreb_inq_180days, sum(mfo_inq_180days) as  mfo_inq_180days,  sum(looking_inq_180days) as looking_inq_180days, 
					sum(total_inq_moreover) as total_inq_moreyear, sum(auto_inq_moreyear) as  auto_inq_moreyear,  sum(cc_inq_moreyear) as cc_inq_moreyear, 
					sum(potreb_inq_180days) as potreb_inq_moreyear, sum(mfo_inq_180days) as  mfo_inq_moreyear,  sum(looking_inq_180days) as looking_inq_moreyear,
					case when sum(total_inq_moreover)<=2  then 1 --'<=2'
						 when sum(total_inq_moreover)<=19 then 2 --'2<x<=19'
						 when sum(total_inq_moreover)<=29 then 3 --'19<x<=29'
						 when sum(total_inq_moreover)<=39 then 4 --'39<x<=39'
						 when sum(total_inq_moreover)<=54 then 5 --'39<x<=54'
						 when sum(total_inq_moreover)>54  then 6 --'54<' 
						 else 0 --'Other' 
						 end as total_inq_moreyear_group

INTO #SCR_NBKI_INQUIRIES3
FROM  (
	   select external_id, InquiryPeriod,inqPurposeText,
	          case when inquiryPeriod = 'последние 7 дней' then 1 else 0 end as total_inq_7days, 
			  case when inquiryPeriod = 'последние 7 дней' and inqPurpose = 16 then 1 else 0 end as mfo_inq_7days,
			  case when inquiryPeriod = 'последние 14 дней' then 1 else 0 end as total_inq_14days, 
			  case when inquiryPeriod = 'последние 14 дней' and inqPurpose = 16 then 1 else 0 end as mfo_inq_14days,
			  case when inquiryPeriod = 'последние 21 дней' then 1 else 0 end as total_inq_21days, 
			  case when inquiryPeriod = 'последние 21 дней' and inqPurpose = 16 then 1 else 0 end as mfo_inq_21days,
			  case when inquiryPeriod = 'последние 30 дней' then 1 else 0 end as total_inq_30days, 
		      case when inquiryPeriod = 'последние 30 дней' and inqPurpose = 16 then 1 else 0 end as mfo_inq_30days,
		      case when inquiryPeriod = 'последние 180 дней' then 1 else 0 end as total_inq_180days, 
			  case when inquiryPeriod = 'последние 180 дней' and inqPurpose = 1 then 1 else 0 end as auto_inq_180days, 
			  case when inquiryPeriod = 'последние 180 дней' and inqPurpose = 7 then 1 else 0 end as cc_inq_180days,
			  case when inquiryPeriod = 'последние 180 дней' and inqPurpose = 9 then 1 else 0 end as potreb_inq_180days,
			  case when inquiryPeriod = 'последние 180 дней' and inqPurpose = 16 then 1 else 0 end as mfo_inq_180days,
			  case when inquiryPeriod = 'последние 180 дней' and inqPurpose = 50 then 1 else 0 end as looking_inq_180days,
			  case when inquiryPeriod = 'более 1 года' then 1 else 0 end as total_inq_moreover, 
			  case when inquiryPeriod = 'более 1 года' and inqPurpose = 1 then 1 else 0 end as auto_inq_moreyear, 
			  case when inquiryPeriod = 'более 1 года' and inqPurpose = 7 then 1 else 0 end as cc_inq_moreyear,
			  case when inquiryPeriod = 'более 1 года' and inqPurpose = 9 then 1 else 0 end as potreb_inq_moreyear,
			  case when inquiryPeriod = 'более 1 года' and inqPurpose = 16 then 1 else 0 end as mfo_inq_moreeyear,
			  case when inquiryPeriod = 'более 1 года' and inqPurpose = 50 then 1 else 0 end as looking_inq_moreyear,

			  case when inqPurpose = 1 then inqAmount else 0 end as inqAmount_auto, 
			  case when inqPurpose = 7 then inqAmount else 0 end as inqAmount_cc, 
			  case when inqPurpose = 9 then inqAmount else 0 end as inqAmount_potreb, 
			  case when inqPurpose = 16 then inqAmount else 0 end as inqAmount_mfo,
			  case when inqPurpose = 50 then inqAmount else 0 end as inqAmount_looking  
	   from bki.n_InquiryReply where  flag_correct = 1 
) as A
GROUP BY external_id






  /******!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! CarMoney_CH !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!******/


drop table if exists #tmp_balance
 select b.*, a.pogashen, a.person_id
into #tmp_balance
from stat_v_balance2 b
join (
select r.id request_id, a.stage_time pogashen, person_id from tmp_v_requests r 
left join (
select request_id, stage_time from requests_history
where  status=16) a on a.request_id=r.id) a on a.request_id=b.request_id
left join tmp_v_credits t on b.credit_id=t.id
where (cdate<=pogashen or pogashen is null)


drop table if exists #tmp_balance_
select t.*, c.id tb_request_id, c.request_date tb_request_date --,return_type
into #tmp_balance_
from #tmp_balance t full join tmp_v_requests c on t.person_id = c.person_id
where cdate < cast(c.request_date as date) --and c.id > t.credit_id


drop table if exists #tmp_balance3
select person_id, b.credit_id, tb_request_id, tb_request_date,
max(CreditDays)  max_CreditDays,
avg(overpayments_cnl) avg_overpayment,
max(overpayments_cnl) max_overpayment,
max(principal_wo+percents_wo+fines_wo+otherpayments_wo)  write_off,
avg(fines_cnl) avg_fines,
max(fines_cnl) max_fines,
max(end_date) end_date
into #tmp_balance3
from #tmp_balance_ b
group by person_id, b.credit_id, tb_request_id, tb_request_date




---------------------------------------------------- selection INTO #tmp_ch_own2 -----------------------------------------------------
drop table if exists #tmp_ch_own2;




drop table if exists #tmpb_aggr5
--with tmpb_aggr as  ( select tb_credit_date, person_id,
 select tb_request_date, person_id,
sum(case when end_date is null then 1 else 0 end) active,
sum(case when end_date is not null then 1 else 0 end) closed, max(avg_overpayment) max_avg_overpayment,

avg(max_overpayment) avg_max_overpayment , max(max_overpayment) max_max_overpayment,
avg(avg_fines) avg_avg_fines, max(avg_fines) max_avg_fines,
avg(max_fines) avg_max_fines, max(max_fines) max_max_fines,
max(write_off) max_wo  
INTO #tmpb_aggr5
from  #tmp_balance3 b group by tb_request_date, person_id


IF EXISTS (SELECT name FROM sys.indexes  
            WHERE name = N'idx7')   
    DROP INDEX idx7 ON #help;



drop table if exists #tmp_ch_own3
	
	select   r.person_id, tb_request_date, r.external_id,
'----interesting----' as [----interesting----],
sum(case when return_type = 'Докредитование' then 1 else 0 end) dokreds,
sum(case when return_type = 'Параллельный' then 1 else 0 end) parall,
sum(case when return_type = 'Повторный' then 1 else 0 end) povt,
max_avg_overpayment, max_max_overpayment, max_avg_fines, max_max_fines, max_wo,  active, closed

into #tmp_ch_own3
 from  				tmp_v_requests r 

   join #tmpb_aggr5 b on  r.request_date = tb_request_date and b.person_id=r.person_id
   group by r.person_id, tb_request_date, r.external_id, max_avg_overpayment, max_max_overpayment, max_avg_fines, max_max_fines, max_wo ,  active, closed


/******!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!MERGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!******/

 drop table if exists #FOR_SCORING3;

select '---Application block---' as stg1, a.*, 
       '---Equifax block---' as stg2, b.*,
	   case when depth_ch_equif > 31 and depth_ch_equif <= 72 then 1
			when depth_ch_equif is NULL or (depth_ch_equif >= 0 and depth_ch_equif <= 31) then 2
			when depth_ch_equif > 135 then 3
			else 4 end depth_ch_equif_group_pd,
	   case when max_limit_potreb_equif is NULL or (max_limit_potreb_equif >= 0 and max_limit_potreb_equif <= 175000) then 1
			when  max_limit_potreb_equif > 175000 and max_limit_potreb_equif <= 370000 then 2
			when max_limit_potreb_equif > 370000 and max_limit_potreb_equif <= 700000 then 3
			when max_limit_potreb_equif > 700000 then 4 end max_limit_potreb_equif_group_pd,
		case when sum_active_paid >= 0 and sum_active_paid <= 250000 then 1
			when sum_active_paid > 250000 and sum_active_paid <= 610000 then 3
			when sum_active_paid > 610000 and sum_active_paid <= 1500000 then 4
			when sum_active_paid is NULL then 2
			when sum_active_paid > 1500000 then 5 end sum_active_paid_group_pd,
		case when cnt_no_overdue_paym_equif > 0 and cnt_no_overdue_paym_equif <= 34 then 1
			when cnt_no_overdue_paym_equif > 34 then 3
			else 2 end cnt_no_overdue_paym_equif_gr,
		log_max_limit_potreb_equif = iif(
			isnull(max_limit_potreb_equif,0)<=0, 0, 
			LOG(max_limit_potreb_equif+1)
			), --LOG(max_limit_potreb_equif+1)
		log_avg_limit_pdl_equif = iif(
			isnull(avg_limit_pdl_equif,0)<=0, 0, 
			LOG(avg_limit_pdl_equif+1)), --LOG(avg_limit_pdl_equif+1),
		
		log_total_curr_overd = iif(
			isnull(total_curr_overd,0)<=0, 
			0, 
			LOG(total_curr_overd+1)), --LOG(total_curr_overd+1)
		log_total_curr_overd_equif = iif(
			isnull(total_curr_overd_equif,0)<=0, 
			0, 
			LOG(total_curr_overd_equif+1)), -- as log_total_curr_overd_equif,
		log_max_maxOverdue_potreb_equif = iif(
			isnull(max_maxOverdue_potreb_equif,0)<=0, 
			0, 
			LOG(max_maxOverdue_potreb_equif+1)), --LOG(max_maxOverdue_potreb_equif+1)  as ,
		log_sum_limit_active_equif = iif(
			isnull(sum_limit_active_equif,0)<=0, 
			0, 
			LOG(sum_limit_active_equif+1)),-- LOG(sum_limit_active_equif+1)
		
		log_cnt_no_overdue_paym_equif = iif(
			isnull(cnt_no_overdue_paym_equif,0)<=0, 
			0, 
			LOG(cnt_no_overdue_paym_equif+1)),  --LOG(cnt_no_overdue_paym_equif+1)
		
		log_sum_total_paid = iif(isnull(sum_total_paid,0)<=0, 0, LOG(sum_total_paid+1)) , --LOG(sum_total_paid+1)
		log_auto_inq_moreyear = iif(isnull(auto_inq_moreyear,0)<=0, 0, LOG(auto_inq_moreyear+1)), --LOG(auto_inq_moreyear+1)
		
		log_total_inq_moreyear = iif(isnull(total_inq_moreyear,0)<=0, 0, LOG(total_inq_moreyear+1)), --LOG(total_inq_moreyear+1)
		log_dolya_NoDPD_pmt = iif(isnull(dolya_NoDPD_pmt,0)<=0, 0, LOG(dolya_NoDPD_pmt+1)), -- LOG(dolya_NoDPD_pmt+1)
		log_abs_diff_total_curr_overd = iif(isnull(abs_diff_total_curr_overd,0)<=0, 0, LOG(abs_diff_total_curr_overd+1)), -- LOG(abs_diff_total_curr_overd+1
		log_max_avg_overpayment = iif(isnull(max_avg_overpayment,0)<=0, 0, LOG(max_avg_overpayment+1)), --LOG(max_avg_overpayment+1)
		log_sum_active_paid = iif(isnull(sum_active_paid,0)<=0, 0, LOG(sum_active_paid+1)), -- LOG(sum_active_paid+1)
		log_depth_ch_equif = iif(isnull(depth_ch_equif,0)<=0, 0, LOG(depth_ch_equif+1)), -- LOG(depth_ch_equif+1)
		log_abs_diff_sum_active_paid = iif(isnull(abs_diff_sum_active_paid,0)<=0, 0, LOG(abs_diff_sum_active_paid+1)), --LOG(abs_diff_sum_active_paid+1)
			
		log_max_limit =iif(isnull(max_limit,0)<=0, 0, LOG(max_limit+1)), -- LOG(max_limit+1)
		log_max_avg_fines = iif(isnull(max_avg_fines,0)<=0, 0, LOG(max_avg_fines+1)) , -- LOG(max_avg_fines+1)
		log_max_limit_cc_equif = iif(isnull(max_limit_cc_equif,0 )<=0, 0, LOG(max_limit_cc_equif+1)), -- LOG(max_limit_cc_equif+1)
		log_age = iif(isnull(age,0)<=0,0, LOG(age+1)), -- LOG(age+1),
        
          '---NBKI block---' as stg3, c.*, 
	case when (abs_diff_sum_active_paid >= 0 and abs_diff_sum_active_paid <= 102000) or (abs_diff_sum_active_paid is NULL) then 1
		when abs_diff_sum_active_paid > 102000 and abs_diff_sum_active_paid <=  300000 then 2
	else 3 end abs_diff_sum_active_paid_group,
	case when abs_diff_total_curr_overd = 0 then 3
		when abs_diff_total_curr_overd is NULL then 2
	else 1 end abs_diff_total_curr_overd_group,
	case when dolya_NoDPD_pmt = 2 or (dolya_NoDPD_pmt >= 0 and dolya_NoDPD_pmt <= 0.8) then 1
		when dolya_NoDPD_pmt > 0.8 and dolya_NoDPD_pmt <= 0.9 then 2
		when  dolya_NoDPD_pmt > 0.9 and dolya_NoDPD_pmt <= 0.98 then 3
	when dolya_NoDPD_pmt > 0.98 and dolya_NoDPD_pmt <= 1 then 3 end dolya_NoDPD_pmt_group_pd,
          '---NBKI Inquiry block---' as stg4, d.*,
		  case when equif_external_id is not null or nbki_external_id is not null then 1 else 0 end as has_bureau,
	
		case when max_avg_overpayment is NULL then 1
	when max_avg_overpayment >= 0 and max_avg_overpayment <= 1800 then 2
	when max_avg_overpayment > 83000 then 3
	when  max_avg_overpayment > 22000 and max_avg_overpayment <= 83000 then 4
	when  max_avg_overpayment > 1800 and max_avg_overpayment <= 22000 then 5
	end max_avg_overpayment_group
	
INTO #FOR_SCORING3
from #SCR_Application3 a   
left join #SCR_EQUIF3 b on a.external_id collate Cyrillic_General_CI_AS =  b.equif_external_id
left join #SCR_NBKI_DIFF c on a.external_id collate Cyrillic_General_CI_AS  = c.nbki_external_id
left join #SCR_NBKI_INQUIRIES3 d on a.external_id collate Cyrillic_General_CI_AS  = d.inq_nbki_external_id
left join (select external_id, id from tmp_v_requests) f on a.external_id = f.external_id
left join  #tmp_ch_own3 t on t.person_id = a.person_id AND a.external_id =  t.external_id;





drop table if exists #FOR_SCORING4;

with score_table as ( select  fs.external_id, fs.appl_date, fs.has_bureau
,(sc.log_total_curr_overd * (case when fs.log_total_curr_overd is not null then fs.log_total_curr_overd else 0.0 end)) log_total_curr_overd
,(sc.log_max_maxOverdue_potreb_equif * (case when fs.log_max_maxOverdue_potreb_equif is not null then      fs.log_max_maxOverdue_potreb_equif  else 8.125258137911842 end )) log_max_maxOverdue_potreb_equif 
,(sc.log_dolya_NoDPD_pmt			    * (case when fs.log_dolya_NoDPD_pmt			    is not null then      fs.log_dolya_NoDPD_pmt				 else 0.6504664494450647  end)) log_dolya_NoDPD_pmt			
,(sc.log_auto_inq_moreyear		    * ( case when fs.log_auto_inq_moreyear		    is not null then      fs.log_auto_inq_moreyear		 else 0.6931471805599453  end            )) log_auto_inq_moreyear		 
,(sc.max_avg_overpayment_group	    * ( case when fs.max_avg_overpayment_group	    is not null then      fs.max_avg_overpayment_group	 else 4.0				  end            )) max_avg_overpayment_group	 
,(sc.depth_ch_equif_group_pd		    * (case when  fs.depth_ch_equif_group_pd		    is not null then  fs.depth_ch_equif_group_pd			 else 3.0				  end  )) depth_ch_equif_group_pd		
,(sc.age_car						    * (case when  fs.age_car						    is not null then  fs.age_car							 else 3.0				  end   )) age_car						
,(sc.abs_diff_sum_active_paid_group  * ( case when fs.abs_diff_sum_active_paid_group  is not null then     fs.abs_diff_sum_active_paid_group	 else 1.0				  end      )) abs_diff_sum_active_paid_group	 
,(sc.log_sum_total_paid			    * (case when  fs.log_sum_total_paid			   is not null then       fs.log_sum_total_paid				 else 14.19093217972386	  end     	 )) log_sum_total_paid	
,intercept	

,fs.log_total_curr_overd			  log_total_curr_overd_g 
,fs.log_max_maxOverdue_potreb_equif log_max_maxOverdue_potreb_equif_g 
,fs.log_dolya_NoDPD_pmt			  log_dolya_NoDPD_pmt_g			 
,fs.log_auto_inq_moreyear		      log_auto_inq_moreyear_g		    
,fs.max_avg_overpayment_group	      max_avg_overpayment_group_g	    
,fs.depth_ch_equif_group_pd		  depth_ch_equif_group_pd_g		 
,fs.age_car						  age_car_g						 
,fs.abs_diff_sum_active_paid_group  abs_diff_sum_active_paid_group_g  
,fs.log_sum_total_paid			  log_sum_total_paid_g			      
,intercept	 intercept_g	

from  [dbo].[scor_coeffs_pd] sc, #FOR_SCORING3 fs
--where filter_b_pd = 1	
	)
	select st.*,
	(1 / (1+ exp(-(log_total_curr_overd+
log_max_maxOverdue_potreb_equif   	+
log_dolya_NoDPD_pmt					+
log_auto_inq_moreyear				+
max_avg_overpayment_group			+
depth_ch_equif_group_pd				+
age_car								+
abs_diff_sum_active_paid_group		+
log_sum_total_paid+
intercept)))) as scr,
	round( 	(1 / (1+ exp(-(log_total_curr_overd+
log_max_maxOverdue_potreb_equif   	+
log_dolya_NoDPD_pmt					+
log_auto_inq_moreyear				+
max_avg_overpayment_group			+
depth_ch_equif_group_pd				+
age_car								+
abs_diff_sum_active_paid_group		+
log_sum_total_paid+
intercept)))) * 1000,0)  as scoring,
-- 27_08_2000 для исключения неактульных данных для докредов
cast(GetDate() as date) as created_at
	into dwh_new.dbo.for_scoring
	from score_table st
  exec [log].[LogAndSendMailToAdmin] 'GenerateScoreForDokredy','Info','procedure finished',N''
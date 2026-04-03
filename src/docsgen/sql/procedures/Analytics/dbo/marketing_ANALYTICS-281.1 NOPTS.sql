CREATE proc dbo.[marketing_ANALYTICS-281.1 NOPTS]

as
--exec sp_create_job 'Analytics.marketing_ANALYTICS-281.1 NOPTS at 8',  'exec dbo.[marketing_ANALYTICS-281.1 NOPTS]', '1', '80000'
--exec sp_create_job 'Analytics.marketing_ANALYTICS-281.2 NOPTS at 8',  'exec dbo.[marketing_ANALYTICS-281.2 NOPTS]', '1', '80000'
drop table if exists #v_email
select phone, email, created into #v_email from v_email
--where 1=0



drop table if exists #bl
select phone, created, rn into #bl from v_blacklist
--where 1=0



drop table if exists #client_category
select phone, main_limit, category, rn_product, ispts , cdate into #client_category from v_client_category
--where 1=0

drop table if exists #mv_loans
select * into #mv_loans from mv_loans
--where 1=0

drop table if exists #v_fa
select number number 
,  phone phone
, closed closed
, created дата_заявки --,call1, cast( call1  as date) call1_date

, isPts isPts, is_approved   is_approved  , issued  issued  , declined   declined  ,istest  isDubl  ,
a.status,  a.approvedSum, isnull( a.loan_type3,  a.ВидЗаймаВРамкахПродукта )  loan_type3
into #v_fa from v_request a
--where 1=0


 drop table if exists #closed
 drop table if exists #closed_0
 drop table if exists #request



----------------------------------------
----------------------------------------
----------------------------------------

 


select * into #request  from (
select
  a.number
, a.дата_заявки  
, a.issued 
, b.[client_first_name] [client_first_name] 
, b.phone 
, e.email
, e.created email_created
, a.status
, a.closed
, a.approvedSum
, a.loan_type3
, a.is_approved
, bl.created blacklist

,row_number() over( partition by a.number order by e.created desc ) rn  


from



#v_fa a 
left join v_request_lk b on a.number=b.number
left join #v_email e on e.phone=a.phone
left join #bl bl on bl.phone=a.phone --and bl.rn=1
left join #v_fa c on c.phone=a.phone and c.issued>=a.дата_заявки


where a.loan_type3<>'Докредитование' and a.isPts=0
and cast(a.дата_заявки as date)=cast(getdate()-1 as date)
and a.issued is null
and a.declined is null
and a.isDubl=0
and c.number is null
and bl.phone is null
) x
where rn=1
 



drop table if exists #cnt_bz
select client_id, count(closed) cnt_bz  into #cnt_bz from v_loans 
where ispts=0 and closed is not null
group by 
client_id --order by


drop table if exists #closed_0


select * into #closed_0 from (
select a.number
, a.[Дата заявки]   дата_заявки
, a.issued  
, a.Имя [client_first_name] 
, a.client_phone
, e.email
, e.created email_created
, 'closed' status


, a.closed
--, a.approvedSum
, a.loan_type2
 
, bl.created blacklist

,row_number() over( partition by a.number order by e.created desc ) rn  
, cnt_bz  .cnt_bz [Закрыто беззалогов]

from



#mv_loans a  
left join #v_email e on e.phone=a.client_phone
left join #bl bl on bl.phone=a.phone --and bl.rn=1
left join #v_fa c on c.phone=a.client_phone and c.issued>=a.closed
left join #v_fa c1 on c1.phone=a.phone and c1.issued>=a.closed
join #cnt_bz cnt_bz  on cnt_bz .client_id=a.client_id

where  cast(a.closed as date) between  getdate()-5 and getdate()-1  and a.ispts=0
and bl.created is null
and c.number is null
and c1.number is null
) x
where rn=1

 



 drop table if exists #closed

select 

  a.*


, b.main_limit
, b.cdate
, b.category 
, c.dpd_begin_day
into #closed
from #closed_0 a 
join #client_category b on a.client_phone = b.phone and b.ispts=0 and b.rn_product=1 and b.category='Зеленый'
left join v_balance c on c.number=a.number and c.date = cast(a.closed as date)
; 


----------------------
----------------------
drop table if exists ##marketing_segments_1
--exec sp_select_table '#closed'
--exec sp_select_table '#request'
 select  a. group_name
 , case
 when a.group_name ='Не выданные' and вид_займа = 'Первичный' and одобрен_зеленый=1 then '1.3) НК/Одобрен Беззалог'
 when a.group_name ='Не выданные' and вид_займа <> 'Первичный' and одобрен_зеленый=1 then '1.4) ПК/Одобрен Беззалог'
 when a.group_name ='Не выданные' and вид_займа = 'Первичный' and одобрен_зеленый=0 then '1.1) НК/Без одобрения Беззалог'
 when a.group_name ='Не выданные' and вид_займа <> 'Первичный' and одобрен_зеленый=0 then '1.2) ПК/Без одобрения Беззалог'
 when a.group_name ='Закрытые не вернувшиеся'  then '1.5) Займ закрыт (вчера  и + 3 дня) Беззалог'
 end segment_name
  ,       a.[number] 
,   a.  дата_заявки
,   a.  выдан
,   a.имя 
,   a.[phone] 
,   a.[email] 

--,   a.  статус
,   a.  закрыт
,   a.  вид_займа
,   a.  сумма_лимит
,   a.  одобрен_зеленый
--,   a.   чс
--, null [Закрыто беззалогов]
--, null [просрочка]
into ##marketing_segments_1
 
 from (
select * 
,row_number() over ( partition by phone order by group_num desc, дата_заявки desc ) rn  

from (

SELECT 
         
 1 as group_num
   ,    'Не выданные'    group_name

   ,       a.[number] 
,   a.дата_заявки  
,   a.issued выдан
,   a.[client_first_name] имя
,   a.[phone] 
,   a.[email] 

,   a.[status] статус
,   a.[closed] закрыт
,   a.[loan_type3] вид_займа
,   a.[approvedSum] сумма_лимит
,   a.[is_approved] одобрен_зеленый
,   a.[blacklist]  чс
, null [Закрыто беззалогов]
, null [просрочка]
 

        FROM 

        #request a
		union all
SELECT 
 2 as group_num
   ,    'Закрытые не вернувшиеся'    group_name
   ,         a.[number] 
,   a.дата_заявки 
,   a.issued выдан
,   a.[client_first_name] 
,   a.[client_phone] 
,   a.[email] 

,   a.[status] 
,   a.[closed] 
,   a.[loan_type2] 
,   a.[main_limit] 
,   1 is_approved
,   a.[blacklist] 
 
,   a.[Закрыто беззалогов] 
 
,   a.[dpd_begin_day] 

        FROM 

        #closed a


		) x 
		) a 
		where a.rn=1
		--order by 1

		--select a.segment_name, cOUNT(*) phone, count(email) email from ##marketing_segments_chern a
		--group by a.segment_name
		----order by


	
		 

exec exec_python 'sql_to_gmail("""


select * from ##marketing_segments_1
order by segment_name, закрыт desc , дата_заявки

 
""", name = "ANALYTICS-281.1 БЕЗЗАЛОГ", add_to="e.rykova@smarthorizon.ru",  include_sql = False) ' , 1


 

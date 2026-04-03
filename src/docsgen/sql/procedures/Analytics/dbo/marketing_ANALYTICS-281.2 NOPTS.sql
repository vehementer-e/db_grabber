
CREATE proc dbo.[marketing_ANALYTICS-281.2 NOPTS]

as

drop table if exists #t1
select a.id,    '2.1) Повторные ДР Беззалог' segment , a.phone,   a.birthday 
, a.Имя 
 
--,count( distinct case when l.closed is not null and l.ispts=0 then l.number end) [Закрыто беззалогов]
 into #t1
from v_clients a 
 join v_client_category b on a.id=b.ClientGUID and b.category='Зеленый' and b.rn_product=1 and b.ispts=0
 left join mv_loans l on l.client_id=a.id 
 left join v_email email on email.phone=a.phone
where month( a.birthday)=month(getdate())  
group by  a.id ,  a.birthday ,  a.phone 
, a.Имя
 
having 
count( distinct case when l.closed is not null and l.ispts=0 then l.number end) >0 and 
count( distinct case when l.closed is  null  then l.number end)=0   

--order by

 union all


select a.number,     '2.2) Новые активные заявки ДР Беззалог' segment,   a.phone, a.birthday, a.Имя    from  v_request a
left join  v_request b on a.phone=b.phone and  isnull(isnull(b.issued, b.cancelled), b.declined)  >=a.created 
 
where a.issued is null and a.cancelled is null and a.declined is null and a.isPts=0 and b.created is null
 and month( a.birthday)=month(getdate())
 and a.loan_type='Первичный'
 and   a.created>=getdate()-30



drop table if exists ##marketing_segments_2

 select segment , id, Имя, phone, email, birthday
 into ##marketing_segments_2
 from (
select a.*, b.email  
,row_number() over( partition by a.phone order by segment , b.created desc ) rn  from #t1 a
left join v_email b on a.phone=b.phone
) x where rn=1
--order by 1



exec exec_python 'sql_to_gmail("""


select * from ##marketing_segments_2
order by  segment

 
""", name = "ANALYTICS-281.2 БЕЗЗАЛОГ", add_to="e.rykova@smarthorizon.ru",  include_sql = False) ' , 1


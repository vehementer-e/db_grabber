
-- exec Create_dm_CollectionCalls
CREATE   procedure [dbo].[Create_dm_CollectionCalls]
as

begin

set nocount on

drop table if exists #space

SELECT
  res.Date
 ,NaumenCaseUuid
 ,SessionId

,res.CommunicationType
,res.ContactPerson
,res.PhoneNumber
,res.PromiseSum
,res.PromiseDate
,res.Manager
,res.Commentary
,res.CommunicationTemplate

,d.Number
,d.Date cred_date
,d.Sum
,d.Term
,d.ProductType
,d.LastPaymentDate
,d.LastPaymentSum
,d.CurrentAmountOwed
,d.DebtSum
,d.PlaceOfContract
,d.RequestDate
,d.Fulldebt

,ct.Name contact_type

,t.Name pers_type

, r.name result

,e.NaumenUserLogin

into #space


 from	  [Stg].[_Collection].[Communications]		res 
left join [Stg].[_Collection].[Deals]				d  on res.IdDeal=d.id
left join [Stg].[_Collection].[ContactType]			ct on ct.id		=res.ContactTypeId
left join [Stg].[_Collection].[ContactPersonType]	t  on t.id		=res.ContactPersonType
left join [Stg].[_Collection].[CommunicationResult] r  on r.id		=res.CommunicationResultId
left join [Stg].[_Collection].[Employee]			e  on e.id		=res.EmployeeId
where (promisesum>=0 or promisesum is null) and r.name  is not null and d.Date is not null
and d.Date >=cast(dateadd(day,1-day(getdate()),getdate()) as date)
and res.Date>=cast(dateadd(day,1-day(getdate()),getdate()) as date)





select cast(dateadd(day,1-day(getdate()),getdate()) as date)







begin tran

delete from dbo.DM_CollectionCalls
where [month]>=cast(dateadd(day,1-day(getdate()),getdate()) as date)


insert into dbo.DM_CollectionCalls


select getdate() updated_at, cast(dateadd(day,1-day(date_comm2),date_comm2) as date) as Month, month(cast(dateadd(day,1-day(date_comm2),date_comm2) as date)) month_num,  
year(cast(dateadd(day,1-day(date_comm2),date_comm2) as date)) year_num,
person_id, overdue_days, date_comm2, avg(1) as cnt,


sign(sum(case when call=1   then 1 else 0 end	)	)														phone_att_flag,
																													  
sign(sum(case when call_con=1 and pers_type='Клиент' then 1 else 0 end	)		)							phone_rpc_flag,
sign(sum(case when call_con=1 and pers_type='Третье лицо' then 1 else 0 end	)	)							phone_tpc_flag,
sign(sum(case when call_con=1   then 1 else 0 end	)							)							phone_con_flag,

sign(sum(case when call_con=1 and communicationtype=1 then 1 else 0 end	)		)							phone_out_con_flag,
sign(sum(case when call_con=1 and communicationtype=2 then 1 else 0 end	)		)							phone_inc_con_flag,
																														
sign(sum(case when call_con=1 and communicationtype=1 and pers_type='Клиент'		 then 1 else 0 end)	)	phone_out_rpc_flag,
sign(sum(case when call_con=1 and communicationtype=1 and pers_type='Третье лицо' then 1 else 0 end	)	)	phone_out_tpc_flag,
																												  		
sign(sum(case when call_con=1 and communicationtype=2 and pers_type='Клиент'		 then 1 else 0 end)	)	phone_inc_rpc_flag,
sign(sum(case when call_con=1 and communicationtype=2 and pers_type='Третье лицо' then 1 else 0 end	)	)	phone_inc_tpc_flag,

sign(sum(case when IVR_full=1 then 1 else 0 end	))			IVR_full_flag,
sign(sum(case when IVR_part=1 then 1 else 0 end	))			IVR_part_flag,

sign(sum(case when communicationtype=3 then 1 else 0 end	)	)		visit_flag,



sign(sum(case when communicationtype=10 and call_con = 1 and pers_type='Клиент' then 1 else 0 end	)	)	message_rpc_flag,
sign(sum(case when communicationtype=10 and call_con = 1 and pers_type='Третье лицо' then 1 else 0 end)	)	message_tpc_flag,
sign(sum(case when communicationtype=10 and call_con = 1   then 1 else 0 end	)						)	message_con_flag,

sign(sum(case when communicationtype=10  then 1 else 0 end	)		)message_att_flag,

sign(sum(case when promise=1  then 1 else 0 end	)	)	PTP_flag,

max(cnt_phonenum) cnt_phonenum



 from (
select a.external_id, PromiseSum,pers_type,person_id,
cast(a.date as date) date_comm,
cdate date_comm2
,communicationtype,
case when overdue_days<4 then '1_3'
	 when overdue_days<31 then '4_30'
	 when overdue_days<61 then '31_60'
	 when overdue_days<91 then '61_90'
	 when overdue_days<181 then '91_180'
	 when overdue_days<361 then '181_360'
	 else '361+' end overdue_days,
 cnt_phonenum
, a.end_date
, a.PromiseDate
, phonenumber
,case when result in ('Автоответчик',
				'Временно недоступен',
				'Жалоба',
				'Занято',
				'Консультация',
				'Не берет трубку',
				'Неправильный номер',
				'Несуществующий номер',
				'Нет ответа',
				'Номер не принадлежит клиенту',
				'Обещание оплатить',
				'Обрыв связи',
				'Оставлено сообщение 3-му лицу',
				'Отказ от оплаты',
				'Отказ от разговора 1-е лицо',
				'Отказ от разговора 3-е лицо',
				'Отклонен/Cброс',
				'Просит перезвонить',
				'Смерть неподвержденная',
				'Смерть подтвержденная',
				'Сообщение прослушано полностью (проинформирован)',
				'Сообщение прослушано не полностью') 	then 1 else 0 end  as communication
,case when result in ('Автоответчик',
				'Временно недоступен',
				'Жалоба',
				'Занято',
				'Консультация',
				'Не берет трубку',
				'Неправильный номер',
				'Несуществующий номер',
				'Нет ответа',
				'Номер не принадлежит клиенту',
				'Обещание оплатить',
				'Обрыв связи',
				'Оставлено сообщение 3-му лицу',
				'Отказ от оплаты',
				'Отказ от разговора 1-е лицо',
				'Отказ от разговора 3-е лицо',
				'Отклонен/Cброс',
				'Просит перезвонить',
				'Смерть неподвержденная',
				'Смерть подтвержденная')	then 1 else 0 end  as call
,case when result in (
                           'Жалоба',
                           'Консультация',
                           'Обещание оплатить',
                           'Оставлено сообщение 3-му лицу',
                           'Отказ от оплаты',
                           'Отказ от разговора 1-е лицо',
                           'Отказ от разговора 3-е лицо',
                           'Смерть неподвержденная',
                           'Смерть подтвержденная') then 1 else 0 end  as call_con
,case when result in (
				'Сообщение прослушано полностью (проинформирован)') 	then 1 else 0 end  as IVR_full
,case when result in (
				'Сообщение прослушано не полностью') 	then 1 else 0 end  as IVR_part
				

	,case when  CommunicationType = 5
	then 1 else 0 end  as sms


,case when result in (
				'Обещание оплатить'
				) 
	then 1 else 0 end  as promise


from (

(select b.external_id,person_id, s.*, b.total_rest, overdue_days, cdate, end_date
from dwh_new.dbo.stat_v_balance2 b
left join #space s  on s.number=b.external_id and cast(s.date as date)=b.cdate
left join dwh_new.dbo.tmp_v_credits c on b.credit_id=c.id


where overdue_days_p>0) ) a
left join (select number, count(distinct phonenumber) cnt_phonenum from #space s
	group by number
) p on p.number=a.number

left join dwh_new.dbo.persons pe on pe.id=a.person_id
where (a.date>=cast(dateadd(day,1-day(getdate()),getdate()) as date) or a.date is null )) a
where date_comm2>=cast(dateadd(day,1-day(getdate()),getdate()) as date) and date_comm2<CURRENT_TIMESTAMP
group by person_id,overdue_days, date_comm2
order by 1

commit tran


end

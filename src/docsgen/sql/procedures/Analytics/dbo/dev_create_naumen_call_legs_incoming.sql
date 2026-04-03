
CREATE     proc --exec
 [dbo].[create_naumen_call_legs_incoming]
 as
begin

drop table if exists #t2
select session_id into #t2 from NaumenDbReport.dbo.call_legs cl
where src_abonent is null



drop table if exists #t1
select cl.* into #t1 from NaumenDbReport.dbo.call_legs cl
join #t2 x on cl.session_id=x.session_id



drop table if exists Analytics.dbo.naumen_call_legs_incoming
select * into Analytics.dbo.naumen_call_legs_incoming from #t1



CREATE NONCLUSTERED INDEX [idx_leg_id_session_id] ON [dbo].[naumen_call_legs_incoming]
(
	created ASC,
	[leg_id] ASC,
	[session_id] ASC
)
INCLUDE([connected],[ended]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

;



with v as (

select session_id, leg_id, src_id, src_abonent, src_abonent_type, dst_id, dst_abonent, dst_abonent_type, incoming, intrusion, created
,  connected
,  ended
,  ended_by
,  is_first_leg = case when leg_id=1 then 1 else 0 end
,  is_second_leg = case when leg_id=2 then 1 else 0 end
,  [is_transfer_to_line_by_operator] = case when b.line_num is not null then 1 else 0 end
,  [is_transfer_to_id_by_operator] = case when b.line_num is null and src_abonent_type='sp' and dst_abonent_type='ss'  then 1 else 0 end
--,  [is_naumen_connection_to_id] = case when src_abonent_type='ss' and dst_abonent_type in ('IVR', 'SP') and incoming=0 then 1 else 0 end
,  [is_transfer_to_line_by_server]   = case when b1.line_num is not null then 1 else 0 end
,  [is_prod_call_to_other_number] = case when src_id = 'prod' and len(dst_id)=11 then 1 else 0 end 
,  [is_operator_succ_conn] = case when dst_id=dst_abonent and dst_abonent_type='SP'  and connected is not null then 1 else 0 end  
,  [is_operator_fail_conn] = case when dst_id=dst_abonent and dst_abonent_type='SP'  and connected is  null then 1 else 0 end  

--,  [is_id_succ_conn] = case when dst_abonent is null and src_abonent_type='ss'  and src_id<>'prod' and connected is not null then 1 else 0 end   
,  [is_id_fail_conn] = case when dst_abonent is null and src_abonent_type='ss'  and src_id<>'prod' and connected is null then 1 else 0 end  
--,  [is_callback] = case when src_id = '6001' then 1 else 0 end

,  [is_intrusion] = [intrusion]
,  [transfer_to_line_by_operator] = b.line_num
,  [transfer_to_line_who_initiated] = case when b.line_num is not null then src_abonent end
,  [transfer_to_line_by_server]   = b1.line_num
,  [is_transfer_to_6009] = case when dst_id='6009' then 1 else 0  end 
,  [is_dst_id='6010'] = case when dst_id='6010' then 1 else 0  end 
,  count(*) over(partition by session_id) cnt_over
from Analytics.dbo.naumen_call_legs_incoming a
left join Analytics.dbo.naumen_lines b on a.dst_id=b.line_num and incoming=1
left join Analytics.dbo.naumen_lines b1 on a.dst_id=b1.line_num and incoming=0
where created>=cast(getdate()-120 as date)

)
select * from (
select *,
check_sum = is_first_leg
+is_second_leg
+[is_transfer_to_line_by_operator]
+[is_transfer_to_id_by_operator]
--+[is_naumen_connection_to_id]
+[is_transfer_to_line_by_server]
+[is_prod_call_to_other_number]
+[is_operator_succ_conn]
+[is_operator_fail_conn] 
+is_id_fail_conn
+[is_intrusion] 
+[is_dst_id='6010'] 
+is_transfer_to_6009 

from v 
) x
where check_sum<>1
--order by session_id, leg_id
--order by check_sum--session_id, leg_id
--node_0_domain_0_nauss_0_1634156504_9124318	6	9119
--node_0_domain_0_nauss_0_1634156504_1178543	6	9011
--node_2_domain_0_nauss_2_1635279126_6630199	6	9184
--node_0_domain_1_nauss_0_1634156504_967963	3	79155212413
--node_0_domain_2_nauss_0_1634156504_3876707	10	9412
--node_2_domain_2_nauss_2_1635279126_7355798	12	9293
--node_0_domain_0_nauss_0_1634156504_1833413	9	9229
--node_2_domain_2_nauss_2_1635279126_7355798	10	9293
--node_0_domain_2_nauss_0_1634156504_3483295	12	9011
--node_0_domain_0_nauss_0_1634156504_9412935	10	9097
--node_0_domain_2_nauss_0_1634156504_6207965	6	9021
--node_2_domain_1_nauss_2_1634156509_4210614	6	9008
--node_0_domain_1_nauss_0_1634156504_944949	7	9402
--node_0_domain_1_nauss_0_1634156504_944949	5	9402
--node_0_domain_0_nauss_0_1634156504_1739557	3	79675073495
--node_0_domain_1_nauss_0_1634156504_944949	5	9402
--node_0_domain_1_nauss_0_1634156504_944949	5	9402
--node_0_domain_1_nauss_0_1634156504_944949	5	9402
--node_0_domain_1_nauss_0_1634156504_944949	7	9402
--node_0_domain_1_nauss_0_1634156504_944949	7	9402
--node_0_domain_1_nauss_0_1634156504_944949	7	9402
--node_2_domain_2_nauss_2_1634156509_1296089	6	9008
--node_2_domain_1_nauss_2_1634156509_2666940	6	9021
--node_2_domain_3_nauss_2_1634156509_4188760	6	9184
--node_2_domain_0_nauss_2_1635279126_6109257	14	9008
--node_0_domain_0_nauss_0_1634156504_1685566	3	9870412575
--node_2_domain_0_nauss_2_1635279126_6109257	12	9402
--node_0_domain_2_nauss_0_1634156504_3609134	6	9184
--node_0_domain_2_nauss_0_1634156504_3250653	6	9184
--node_2_domain_0_nauss_2_1634156509_1914180	6	9021
--node_0_domain_1_nauss_0_1634156504_2195558	6	9229
--node_2_domain_3_nauss_2_1634156509_3724792	6	9008
--node_2_domain_2_nauss_2_1635279126_69479	6	9184
--node_0_domain_2_nauss_0_1634156504_1223288	6	9021
--node_0_domain_0_nauss_0_1634156504_3207787	6	9021
--node_0_domain_2_nauss_0_1634156504_3226246	6	9021
--node_2_domain_2_nauss_2_1634156509_4258500	9	9021
--node_2_domain_3_nauss_2_1635279126_2543511	10	9402
--node_0_domain_2_nauss_0_1634156504_3203264	6	9243
--node_2_domain_3_nauss_2_1635279126_3534326	6	9184
--node_2_domain_1_nauss_2_1634156509_3987924	6	9071


--where cnt_over>=3 and [is_operator_succ_conn]=1
--order by session_id, leg_id

--, transfers_by_server as (
--select session_id, leg_id, transfer_to_line_by_server, who = 'server'  from v a 
--where transfer_to_line_by_server is not null
--)
--,  transfers_by_operator as (
--select session_id, leg_id, transfer_to_line_by_operator, who = transfer_to_line_who_initiated  from v a 
--where transfer_to_line_by_operator is not null
--)
--, sessions_unique as
--(
--select session_id, src_id from v
--where leg_id=1
--
--)
--
--,
--all_transfers as (
--select * from  transfers_by_operator union all
--
--select * from  transfers_by_server
--)
--
--select * from all_transfers
--
--
--select  * from report_naumen_lines
--where line_6001 is not null



;
---check
with v as (
select session_id, leg_id, src_id, src_abonent, src_abonent_type, dst_id, dst_abonent, dst_abonent_type, incoming, intrusion, created
,  connected
,  ended
,  ended_by
,  is_first_leg = case when leg_id=1 then 1 else 0 end
,  is_second_leg = case when leg_id=2 then 1 else 0 end
,  [is_transfer_to_line_by_operator] = case when b.line_num is not null then 1 else 0 end
,  [is_transfer_to_id_by_operator] = case when b.line_num is null and src_abonent_type='sp' and dst_abonent_type='ss'  then 1 else 0 end
,  [is_transfer_to_line_by_server]   = case when b1.line_num is not null then 1 else 0 end
,  [is_prod_call_to_other_number] = case when src_id = 'prod' and len(dst_id)=11 then 1 else 0 end 
,  [is_operator_succ_conn] = case when dst_id=dst_abonent and dst_abonent_type='SP'  and connected is not null then 1 else 0 end  
,  [is_operator_fail_conn] = case when dst_id=dst_abonent and dst_abonent_type='SP'  and connected is  null then 1 else 0 end  
--,  [is_id_succ_conn] = case when dst_abonent is null and src_abonent_type='ss'  and src_id<>'prod' and connected is not null then 1 else 0 end   
,  [is_id_fail_conn] = case when dst_abonent is null and src_abonent_type='ss'  and src_id<>'prod' and connected is null then 1 else 0 end  
--,  [is_callback] = case when src_id = '6001' then 1 else 0 end
,  [is_intrusion] = [intrusion]
,  [transfer_to_line_by_operator] = b.line_num
,  [transfer_to_line_who_initiated] = case when b.line_num is not null then src_abonent end
,  [transfer_to_line_by_server]   = b1.line_num
,  [is_transfer_to_6009] = case when dst_id='6009' then 1 else 0  end 
,  count(*) over(partition by session_id) cnt_over
from Analytics.dbo.naumen_call_legs_incoming a
left join Analytics.dbo.naumen_lines b on a.dst_id=b.line_num and incoming=1
left join Analytics.dbo.naumen_lines b1 on a.dst_id=b1.line_num and incoming=0
where created>=cast(getdate()-120 as date)
and session_id='node_0_domain_0_nauss_0_1626726195_2019560'
----where session_id='node_0_domain_1_nauss_0_1634156504_8598797' 
--
----node_0_domain_0_nauss_0_1634156504_11243950
----node_2_domain_0_nauss_2_1635279126_8904156
----node_2_domain_0_nauss_2_1635279126_8946943
----node_2_domain_3_nauss_2_1635279126_9004117
--order by created, leg_id
)

select * from naumen_call_legs_incoming where session_id in (
select distinct session_id from (
select * from (
select 
check_sum = is_first_leg
+is_second_leg
+[is_transfer_to_line_by_operator]
+[is_transfer_to_id_by_operator]
+[is_transfer_to_line_by_server]
+[is_prod_call_to_other_number]
+[is_operator_succ_conn]
+[is_operator_fail_conn] 
+is_id_fail_conn
--+[is_callback] 
+[is_intrusion] 
+is_transfer_to_6009 
,
*
from v 
)
x
where dst_id='6010'--??????
) x
)
order by session_id, leg_id

;



with v as (

select session_id, leg_id, src_id, src_abonent, src_abonent_type, dst_id, dst_abonent, dst_abonent_type, incoming, intrusion, created
,  connected
,  ended
,  ended_by
,  is_first_leg = case when leg_id=1 then 1 else 0 end
,  is_second_leg = case when leg_id=2 then 1 else 0 end
,  [is_transfer_to_line_by_operator] = case when b.line_num is not null then 1 else 0 end
,  [is_transfer_to_id_by_operator] = case when b.line_num is null and src_abonent_type='sp' and dst_abonent_type='ss'  then 1 else 0 end
,  [is_transfer_to_line_by_server]   = case when b1.line_num is not null then 1 else 0 end
,  [is_prod_call_to_other_number] = case when src_id = 'prod' and len(dst_id)=11 then 1 else 0 end 
,  [is_operator_succ_conn] = case when dst_id=dst_abonent and dst_abonent_type='SP'  and connected is not null then 1 else 0 end  
,  [is_operator_fail_conn] = case when dst_id=dst_abonent and dst_abonent_type='SP'  and connected is  null then 1 else 0 end  
,  [is_id_fail_conn] = case when dst_abonent is null and src_abonent_type='ss'  and src_id<>'prod' and connected is null then 1 else 0 end  
,  [is_intrusion] = [intrusion]
,  [transfer_to_line_by_operator] = b.line_num
,  [transfer_to_line_who_initiated] = case when b.line_num is not null then src_abonent end
,  [transfer_to_line_by_server]   = b1.line_num
,  [is_transfer_to_6009] = case when dst_id='6009' then 1 else 0  end 
,  [is_dst_id='6010'] = case when dst_id='6010' then 1 else 0  end 
,  count(*) over(partition by session_id) cnt_over
from Analytics.dbo.naumen_call_legs_incoming a
left join Analytics.dbo.naumen_lines b on a.dst_id=b.line_num and incoming=1
left join Analytics.dbo.naumen_lines b1 on a.dst_id=b1.line_num and incoming=0
where created>=cast(getdate()-2 as date)

)
, transfers_by_server as (
select session_id, leg_id, transfer_to_line_by_server, who = 'server'  from v a 
where transfer_to_line_by_server is not null
)
,  transfers_by_operator as (
select session_id, leg_id, transfer_to_line_by_operator, who = transfer_to_line_who_initiated  from v a 
where transfer_to_line_by_operator is not null
)
, sessions_unique as
(
select session_id, src_id from v
where leg_id=1

)

,
all_transfers as (
select * from  transfers_by_operator union all

select * from  transfers_by_server
)

select * from all_transfers




  select * from v_naumen_call_legs_incoming a 
  left join v_naumen_call_legs_incoming b on a.session_id=b.session_id and b.leg_id+1=a.leg_id
  left join v_naumen_call_legs_incoming b1 on a.session_id=b1.session_id and b1.leg_id-1=a.leg_id
  where  a.transfer_to_line_by_server='6002' and a.created>=cast(getdate()-2 as date)
  order by a.[session_id], a.leg_id


end


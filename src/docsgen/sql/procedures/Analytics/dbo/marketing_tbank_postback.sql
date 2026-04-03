CREATE proc marketing_tbank_postback
as


--sp_create_job 'Analytics._marketing_tbank_postback at 11', 'marketing_tbank_postback', '1', '110000'


drop table if exists #t1


select  a.created, a.phone,issued, a.fiobirthday, a.number, a.leadId, d.source leadSource, d1.source originalSource , b.postbackSource, b.entryPoint postbackentryPoint , b.eventName , b.sendingStatus
, rf.BkiId collate Cyrillic_General_CI_AS BkiId
, rf.sumContract 
, rf.[СontractAnnuityPayment]
, rf.[СontractPercent]
, isnull(a.term , rf.[ClientLoanTerm] ) [ClientLoanTerm]
into #t1
from request a

left join
(select b.*, c.source postbackSource, c.entryPoint  from 
v_postback b
left join v_lead2 c on c.id = b.lead_id ) 
 b on a.leadId=b.lead_id  and b.eventName='request.status.changed' and b.postbackSource = 'tpokupki-deepapi'
 left join v_lead2 d on d.id= a.leadId
 left join v_lead2 d1 on d1.id= a.originalLeadId
 left join stg._fedor.core_ClientRequest rf on rf.id = a.guid
where a.source = 'tpokupki-deepapi'
and issued <=cast(getdate() as date)
--and rf.bkiId = '4eb0d513-580d-125a-8059-43312871cd4f-f'
order by 1 desc




drop table if exists #lead
select b.phone, b.id, b.created into #lead 
from v_lead2 b 
  join v_postback c on c.lead_id=b.id and c.api2Accepted is not null
where 
 b.entrypoint = 'UNI_API' and b.source='tpokupki-deepapi'  

drop table if exists #lead2
select a.*, b.fioBirthday into #lead2 from #lead a left join v_request_external b on a.id= b.id 

drop table if exists #t2

select a.*, x.id, cast(null as nvarchar(max)) as responseResult, getdate() rowCreated, newid() rowId , cast(null as datetime2(0)) sendingStarted, x.created leadCreated  into #t2 from #t1 a
outer apply (select top 1 * from #lead2 b where ( a.phone = b.phone or a.fiobirthday = b.fioBirthday  )and b.created<a.issued   order by b.created desc ) x

 



;
with v as (

select *, row_number() over(partition by number order by  case when sendingStatus = 'sent' then 1 else 0 end desc ) rn from #t2 
)
 delete from v where rn>1

  
;
--drop table if exists marketing_tbank_postback_log
--delete from marketing_tbank_postback_log

--insert into marketing_tbank_postback_log  select top 10 * from #t2 order by issued desc

 --select * into marketing_tbank_postback_log 
 --from #t2

 --alter table marketing_tbank_postback_log add leadCreated datetime2(0)

insert into marketing_tbank_postback_log 
select * from #t2 where number not in (select number from marketing_tbank_postback_log where number is not null )
 and issued>=getdate()-30


 select * from marketing_tbank_postback_log
 order by rowCreated desc

 ;

 declare @number varchar(100)
 declare @command varchar(max)
 declare @result varchar(max)
 declare @stop int =0

 ;
 while @stop=0
 begin
set @number = ( select top 1 number from marketing_tbank_postback_log where sendingStarted is null and id is not null and isnull(sendingStatus, '') <> 'sent' )

if @number is null return

update marketing_tbank_postback_log set sendingStarted = getdate() where number=@number


set @command = (select  'declare @res varchar(max)
exec python ''result = send_tbank_postback(lead_id="'+id+'" , amountStr="'+format([sumContract], '0')+'", rateStr="'+format([СontractPercent], '0.00')+'", termStr="'+format([ClientLoanTerm], '0')+'", monthPaymentStr="'+format([СontractAnnuityPayment], '0')+'", bkiId="'+[BkiId]+'")  '' , 1, @res output
update marketing_tbank_postback_log set responseResult = @res where number='''+number+'''' from marketing_tbank_postback_log
where number=@number)

if @command is null return
 
 print (@command)
 exec (@command)
  
  waitfor delay '0:00:05'

end

 

--select *, count(*) over (partition by number ) cnt from #t2 a 
--where sendingStatus <> 'sent'
-- order by cnt desc, number



--select * from v_lead2 where phone = '9108131719'
--order by created


--select * from v_postback where lead_id = 'E8CE8B97-CF9F-4EEC-97A9-030F66F6304E'


--select * from #t1


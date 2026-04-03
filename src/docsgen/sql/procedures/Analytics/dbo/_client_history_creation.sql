CREATE proc [dbo].[_client_history_creation] @date0 date = null, @date1 date = null
as





declare @date date =  isnull( @date0,  cast(getdate()-3 as date))--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
declare @dateto date =  isnull( @date1, cast(getdate() as date))--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
--declare @date date =  '20240101' declare @dateTo date =  getdate()
--ТелефонМобильный
--9632302596
--select     top 100      *from dwh2.marketing.docredy_pts where cdate = cast(getdate() as date)

drop table if exists #t249098248923898923
select  top 0    cdate date,   iSNULL( CRMClientGUID, external_id)  clientId, isnull( phone , ТелефонМобильный) phone ,  category,  type  , ispts= 1 ,   main_limit limit ,   fio , birth_date
 into #t249098248923898923
from dwh2.marketing.docredy_pts  
where cdate between @date and @dateTo


insert into #t249098248923898923

select      cdate date,   iSNULL( CRMClientGUID, external_id)  clientId, isnull( phone , ТелефонМобильный) phone ,  category,  type  , ispts= 1 ,   main_limit limit ,   fio , birth_date
 
from dwh2.marketing.docredy_pts  
where cdate between @date and @dateTo



insert into #t249098248923898923

select      cdate date,   iSNULL( CRMClientGUID, external_id)  clientId, isnull( phone , ТелефонМобильный) phone ,  category,  type  , ispts= 1 ,   main_limit limit ,   fio , birth_date
 
from dwh2.marketing.povt_pts 

where cdate between @date and @dateTo

insert into #t249098248923898923


select      cdate date,   iSNULL( CMRClientGUID, external_id)  clientId, phone  phone , market_proposal_category_name  category, product_type_name type  , ispts= 0 ,   approved_limit limit ,   fio , birth_date
 
from dwh2.marketing.povt_pdl 
where cdate between @date and @dateTo


insert into #t249098248923898923


select      cdate date,   iSNULL( CMRClientGUID, external_id)  clientId, phone  phone , market_proposal_category_name  category, product_type_name type  , ispts= 0 ,   approved_limit limit ,   fio , birth_date
 from dwh2.marketing.povt_inst 
where cdate between @date and @dateTo



drop table if exists #t328782782378
drop table if exists #t31781788123
drop table if exists #t32878278327822378

update a set a.clientId = b.clientId  from #t249098248923898923 a join _request b on a.clientId=b.number and b.issued is not null and b.clientId is not null
and isnumeric(a.clientId)=1



drop table if exists #t31781788123

select a.clientId, a.date, b.ispts, b.number, cast( b.issued   as date)  issued,  cast( b.closed   as date)  closed, case when b.closed>=a.date or b.closed is null then b.number  end numberActive

, case when b.closed<a.date  then b.number  end numberClosed


into #t31781788123 from #t249098248923898923 a
left join _request b on a.clientId=b.clientId and b.issued<a.date
group by   a.clientId, a.date, b.ispts, b.number, case when b.closed>=a.date or b.closed is null then b.number  end
, case when b.closed<a.date  then b.number  end  
, cast( b.issued   as date)   ,  cast( b.closed   as date)

drop table if exists #t328782782378
select a.clientId, a.date
, count(case when a.ispts=1 then number end  )       ptsIssued
, count(case when a.ispts=1 then numberActive end  ) ptsActive
, count(case when a.ispts=1 then numberClosed end  ) ptsCLosed
, count(case when a.ispts=0 then number end  )       bezzalogIssued
, count(case when a.ispts=0 then numberActive end  ) bezzalogActive
, count(case when a.ispts=0 then numberClosed end  ) bezzalogCLosed
, count(number)                                      totalIssued
, count(numberActive)                                totalActive
, count(numberClosed)                                totalCLosed
, min(a.issued)                                      issuedFirst
, max(a.issued)                                      issuedLast
, max(case when a.closed <a.date then a.closed end  ) closedLast
into #t328782782378
from #t31781788123 a
group by a.clientId, a.date

drop table if exists #t2337321782
select a.clientId, a.date
,  max(case when a.isPts=1  then b.dpdBeginDay end ) ptsMaxDpd 
,  max(case when a.isPts=0  then b.dpdBeginDay end ) bezzalogMaxDpd 
into #t2337321782
from #t31781788123 a
left join v_balance b on a.number=b.number and b.d<=a.date
group by a.clientId, a.date

--select * from #t2337321782


drop table if exists #t32878278327822378
select a.*
, b.ptsIssued
, b.ptsActive
, b.ptsCLosed
, b.bezzalogIssued
, b.bezzalogActive
, b.bezzalogCLosed
, b.totalIssued
, b.totalActive
, b.totalCLosed
, b1.ptsMaxDpd 
, b1.bezzalogMaxDpd 
 ,  b.issuedFirst
 ,  b.issuedLast
 ,  b.closedLast


into #t32878278327822378
from #t249098248923898923 a
left join #t328782782378 b on a.clientId=b.clientId and a.date=b.date
left join #t2337321782 b1 on a.clientId=b1.clientId and a.date=b1.date


delete a from _client_history a join #t32878278327822378 b on a.date=b.date --and a.clientid=b.clientid and a.type=b.type

insert into _client_history

select * from #t32878278327822378



--select *   
--from dwh2.marketing.povt_pts where cdate = '2024-11-26'
--and crmclientguid is null

--alter table _client_history add ptsIssued     smallint
--alter table _client_history add ptsActive	  smallint
--alter table _client_history add ptsCLosed	  smallint
--alter table _client_history add bezzalogIssued	  smallint
--alter table _client_history add bezzalogActive	  smallint
--alter table _client_history add bezzalogCLosed	  smallint
--alter table _client_history add totalIssued	  smallint
--alter table _client_history add totalActive	  smallint
--alter table _client_history add totalCLosed	  smallint
--alter table _client_history add ptsMaxDpd	  smallint
--alter table _client_history add bezzalogMaxDpd	  smallint

--alter table _client_history add issuedFirst  date
--alter table _client_history add issuedLast   date
--alter table _client_history add closedLast	 date


--update a set a.clientId = b.clientId  from _client_history a join _request b on a.clientId=b.number and b.issued is not null and b.clientId is not null
--and isnumeric(a.clientId)=1





--select top 100 * from _client_history
--order by 1 --desc


----exec sp_selectTable '_client_history'
--go

--alter view client_history as 
--select  
--date
--, clientId
--, phone 
-- , category  
--, Type
--, ispts
--, limit
--, fio
--, birth_date
--, case when  Type  = 'Докредитование' then  'Докредитование' else   'Повторный'   end returnType
--, case when  Type  = 'Докредитование' then 1 else 0 end isDokred
--from 
--_client_history
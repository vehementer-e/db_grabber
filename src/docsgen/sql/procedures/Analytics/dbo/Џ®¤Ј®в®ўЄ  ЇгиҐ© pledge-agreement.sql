
CREATE   proc 
--exec
[dbo].[Подготовка пушей pledge-agreement]
as
begin

drop table if exists #t1

select 
	external_id = lk_c.code
	,doc_type = lk_ult.type 
	,doc_type_name = lk_ult.full_description
	,doc_name = lk_cd.name
	,doc_created_time = dateadd(hh, 3, lk_ul.created_at)
	
	,sms_send_date = dateadd(hh, 3,lk_pep_log.sms_send_date)
	,sms_input_date =  dateadd(hh, 3, lk_pep_log.sms_input_date)
	,is_signed = iif( lk_pep_log.sms_input_date is not null, 1, 0)
	--2020-04-16 07:42:47.000
 into #t1
from stg._LK.contracts lk_c
	inner join stg._LK.contract_documents	lk_cd 
		on lk_cd.contract_id =  lk_c.id
	inner join stg._LK.user_link_contract	lk_lc 
		on lk_lc.contract_documents_id = lk_cd.id
	inner join stg._lk.user_link			lk_ul
		on lk_ul.id = lk_lc.user_link_id
	
	inner join stg._lk.user_link_types lk_ult 
	  on lk_ul.user_link_type_id =lk_ult.id
		--and lk_ul.active = 1
 
	left join stg._LK.pep_activity_log lk_pep_log on lk_pep_log .id = lk_ul.pep_activity_log_id
		

WHERE 1=1
	and lk_ult.type = 'pledge-agreement'
	AND lk_cd.is_pep = 1


	drop table if exists #mv_loans

	select код, CRMClientGUID, isnull(isnull([Основной телефон клиента CRM] , [Телефон клиента Спейс]), [Телефон договор CMR]) [Основной телефон клиента CRM] , cs.Name  [Стадия договора Спейс] into #mv_loans
	from mv_loans a
	join stg._Collection.Deals d on a.Код=d.Number
	left join stg._Collection.collectingStage cs on cs.id=d.StageId

	drop table if exists #b
	
	select a.код, a.bucket, d, [is_dpd] , [is_dpd начало дня], [Дата закрытия] into #b from v_balance a
	--left join stg._1cCMR.Справочник_Договоры d on d.Код=a.Код
	where d=cast(getdate() as date)

	drop table if exists #client_with_predel_or_dpd
	select distinct CRMClientGUID into #client_with_predel_or_dpd from #mv_loans a
	left join #b b on a.код=b.Код
	where  is_dpd>0 --or b.d is null or b.[Дата закрытия] is not null
	--order by [Стадия договора Спейс]

drop table if exists #final


select  right([Основной телефон клиента CRM], 10)  [Основной телефон клиента CRM], max(l.CRMClientGUID) CRMClientGUID,STRING_AGG(cast(l.код as nvarchar(max)), '/') код
into #final
from #t1 a
join #mv_loans l on a.external_id=l.код
left join #b b on b.Код=l.код
left join #client_with_predel_or_dpd c on l.CRMClientGUID=c.CRMClientGUID
where sms_input_date is null and c.CRMClientGUID is null and  isnull([Стадия договора Спейс] , '')<>'Closed'
group by right([Основной телефон клиента CRM], 10)
--group by  [Стадия договора Спейс], is_dpd
--order by  [Стадия договора Спейс], is_dpd

drop table if exists #topN
select top 1000 f.*, getdate() dt, cast(getdate() as date) d into #topN
from #final f
 left join dbo.[пуши pledge-agreement история] a on f.[Основной телефон клиента CRM]=a.[Основной телефон клиента CRM]
 left join dbo.[пуши pledge-agreement история] b on f.CRMClientGUID=b.CRMClientGUID
 where a.[Основной телефон клиента CRM] is null and b.CRMClientGUID is null

if (select count(*) from #topN)<150
begin
declare @countcl  nvarchar(200) =  'Недостаточно клиентов для отправки пушей - ' + isnull(cast( (select count(*) from #topN) as nvarchar(10) ), '0')
exec log_email @countcl, 'p.ilin@techmoney.ru; v.plotnikov@techmoney.ru; e.pimenova@techmoney.ru'
return

end

 --select 1 d

--drop table if exists dbo.[пуши pledge-agreement история]
--select top 0 * into dbo.[пуши pledge-agreement история]
--from #topN


--drop table if exists dbo.[пуши pledge-agreement буфер]
--select top 0 * into dbo.[пуши pledge-agreement буфер]
--from #topN

begin tran
--delete from dbo.[пуши pledge-agreement история]
insert into dbo.[пуши pledge-agreement история]
select * from #topN
--select * from dbo.[пуши pledge-agreement история]

delete from dbo.[пуши pledge-agreement буфер]
insert into dbo.[пуши pledge-agreement буфер]
select * from #topN

commit tran

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '9FEBD2E9-D198-41E7-A596-20A65831C4FC'

--order by sms_send_date, sms_input_date

	end
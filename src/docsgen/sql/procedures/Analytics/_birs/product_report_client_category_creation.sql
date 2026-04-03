
CREATE   proc [_birs].[product_report_client_category_creation]
as
begin

	   drop table if exists 		#loans



  select код код, CRMClientGUID CRMClientGUID, [Дата погашения]		  [Дата погашения]

  into #loans from mv_loans where isInstallment=1





	   drop table if exists 		#t1

select   CMRClientGUID, cast(format(cdate, 'yyyy-MM-01') as date) month,  phone, cdate, market_proposal_category_name, external_id, product_type_name, approved_limit  into #t1 from dwh2.marketing.povt_pdl   -- where  market_proposal_category_name='Зеленый'
union all select   CMRClientGUID,cast(format(cdate, 'yyyy-MM-01') as date) month,  phone, cdate, market_proposal_category_name, external_id, product_type_name, approved_limit   from dwh2.marketing.povt_inst -- where    market_proposal_category_name='Зеленый'

 
	   drop table if exists 		#t3

	select a.*, b.[Дата погашения] last_closed into #t3 from #t1  	a
	  join   #loans b on  a.CMRClientGUID=b.CRMClientGUID   and b.[Дата погашения]<=a.cdate  
  --where b.код is not null
  --select * from #t4
  drop table if exists  #t5

   ;
with v as (select *, ROW_NUMBER() over(partition by phone, cdate order by last_closed desc, case when market_proposal_category_name='Зеленый' then 1 end desc , approved_limit desc ) rn from  #t3) 
SELECT * INTO   #t5 FROM  V

where rn=1

  drop table if exists  #t6

select *
, ROW_NUMBER() over(partition by 	month, phone order by cdate) rn_month 

into #t6  from (

select *,case when isnull( lag(market_proposal_category_name) over(partition by month, phone order by cdate), 'Красный')='Красный' and  market_proposal_category_name='Зеленый' then 1 end is_change_to_green    from #t5 

) x where is_change_to_green=1		and phone is not null




--drop table if exists _birs.client_category
--select * into  _birs.product_report_client_category from 	   _birs.client_category
 

 truncate table _birs.product_report_client_category  
	insert into  _birs.product_report_client_category
select *  from 	   #t6 

 end

CREATE proc _lead_client @days int = 30
 
 as
 --declare @days  bigint = datediff(day, '20100101', getdate()) 
declare @date date = cast(getdate()-@days  as date)   


drop table if exists #loans
select issued, closed, phone ,   number, ispts, ispdl, clientId into #loans 	  
from request 
where issued is not null	
 
 
drop table if exists #leadClient 

  select a.id, a.created, a.phone  , b.clientId  , b.issued
  into #leadClient
  from lead_Request a 
  join #loans b on a.phone=b.phone and b.issued<=a.created
  where a.requestguid is null and a.created >=@date
   
;with v  as (select *, row_number() over(partition by id  order by  issued desc) rn from #leadClient ) delete from v where rn>1



 

drop table if exists #leadClient2 

  select a.*   
 
 ,lastClosed = [povt_tel_any_product].previous_closed_dt
					
 , loyalty        = isnull([povt_tel_any_product].cnt_povt,0)+1
 , loyaltyPts        = isnull([povt_tel_any_product].cnt_povtPts,0)+1
 , loyaltyBezzalog        = isnull([povt_tel_any_product].cnt_povtBezzalog,0)+1
 , loanOrder  =  isnull(loan_any_product.cnt,0)+1
 , firstLoanProductType =  case when first_loan_any_product.isPdl =1  then 'pdl'  when first_loan_any_product.isPts =1  then 'pts ' when first_loan_any_product.isPdl =0 then 'inst' end    --case first_loan.isPdl when '1' then 'pdl' when '0' then 'inst' end
  , returnType =   
  case 
  when  [docr_tel_any_product].cnt_docrPts>0 and [docr_tel_any_product].cnt_docrBezzalog>0   then 'Докредитование ПТС Беззалог'
  when  [docr_tel_any_product].cnt_docrPts>0  then 'Докредитование ПТС'
  when  [docr_tel_any_product].cnt_docrBezzalog>0  then 'Докредитование Беззалог'
  
  when  [povt_tel_any_product].cnt_povtPts>0  and [povt_tel_any_product].cnt_povtBezzalog>0   then 'Повторный ПТС Беззалог'  
  when  [povt_tel_any_product].cnt_povtPts>0 then 'Повторный ПТС'  
  when  [povt_tel_any_product].cnt_povtBezzalog>0 then 'Повторный Беззалог'  
  end     into #leadClient2
  from #leadClient	a 
 outer apply (select count(*) cnt_povt  , count(case when ispts=1 then 1 end )cnt_povtPts   , count(case when ispts=0 then 1 end )cnt_povtBezzalog , max(closed) previous_closed_dt 
   from #loans b where    a.clientid=b.clientid and isnull(b.closed, GETDATE() ) <= a.created  	 )  [povt_tel_any_product]

 outer apply (select top 1 isPdl, ispts   from #loans b where     a.clientid=b.clientid and isnull(b.issued, GETDATE() ) <= a.created  order by b.issued	 )  first_loan_any_product
  outer apply (select  count(* )cnt    from #loans b where     a.clientid=b.clientid and isnull(b.issued, GETDATE() ) <= a.created  	 )  loan_any_product
  outer apply (select count(*) cnt_docr   , count(case when ispts=1 then 1 end )cnt_docrPts   , count(case when ispts=0 then 1 end )cnt_docrBezzalog   from #loans b where   a.clientid=b.clientid and b.issued<=a.created and isnull(b.closed, GETDATE() ) > a.created  )    [docr_tel_any_product]	 



  ;
drop table if exists #reqCLientHistPts
;
  with v as ( 
  select  * ,case  left(returnType, charindex(' ', returnType) - 1) when 'Докредитование' then 1 else 0 end isDokred   from #leadClient2 
  )

		select a.id, b.category, b.limit,   b.date, b.type, datediff(day, b.date,  a.created  ) dif into #reqCLientHistPts from  v a 
		join  client_history b on a.clientId=b.clientId
		and b.date between cast(  dateadd(day, -10,   a.created  )  as date)  and  cast(  a.created    as date)
		and 1=b.ispts 
		and a.isDokred=b.isDokred

		;with v  as (select *, row_number() over(partition by id order by dif , limit desc) rn from #reqCLientHistPts ) delete from v where rn>1
	
	  ;
drop table if exists #reqCLientHistBezzalog
;
 
  with v as ( 
  select  * ,case  left(returnType, charindex(' ', returnType) - 1) when 'Докредитование' then 1 else 0 end isDokred   from #leadClient2 
  )

		select a.id, b.category, b.limit,   b.date, b.type, datediff(day, b.date,  a.created  ) dif into #reqCLientHistBezzalog from  v a 
		join  client_history b on a.clientId=b.clientId
		and b.date between cast(  dateadd(day, -10,   a.created  )  as date)  and  cast(  a.created    as date)
		and 0=b.ispts 
		and a.isDokred=b.isDokred

		;with v  as (select *, row_number() over(partition by id order by dif , limit desc) rn from #reqCLientHistBezzalog ) delete from v where rn>1
	

	
drop table if exists #leadCLientDpd

select a.id
, max(case when  b.ispts=1 then c.dpdBeginDay end   ) clientMaxDpdPts
, max(case when   b.ispts=0 then c.dpdBeginDay end  ) clientMaxDpdBezzalog
into #leadCLientDpd
from  #leadClient2 a  
join _request b on a.clientId=b.clientId 
join v_balance c on c.number=b.number and  c.date<cast(   a.created   as date) 
group by  a.id



--select * from #leadCLientDpd

drop table if exists #leadClient3

select a.*, a1.category clientCategoryPts , a1.limit clientLimitPts , a2.category clientCategoryBezzalog , a2.limit clientLimitBezzalog , a3.clientMaxDpdPts , a3.clientMaxDpdBezzalog  into #leadClient3 from #leadClient2 a
left join #reqCLientHistPts a1          on a1.id=a.id 
left join #reqCLientHistBezzalog a2		on a2.id=a.id
left join #leadCLientDpd a3             on a3.id=a.id



--select * from #reqCLientDpd


--select * from dwh where table_name='_request' and column_name like '%' + 'category' + '%'  

--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN returnType nvarchar(50)
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN returnType nvarchar(50)
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN returnTypeByProduct nvarchar(50)
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN returnTypeByProduct nvarchar(50)


 --select * from #leadClient2
 --select * from #leadClient3
 --select * from lead_client

 --drop table if exists  lead_client 
 --select * into lead_client from #leadClient3
 delete a from lead_client a join #leadClient3 b on a.id=b.id
 insert into lead_client
 select * from #leadClient3

  

 --select * from lead_client
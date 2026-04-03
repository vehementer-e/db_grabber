-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl   process_requests 
--
--  etl.base_etl_process_requests  '2021-01-01','2021-03-29 20:03:08.000'
/*

def req(stg_tbl, tbl, start_date, end_date, commit_after, **kwargs):
    ms = MsSqlHook(mssql_conn_id ='new_dwh')
    r= Request(ms,  stg_tbl, tbl, start_date, end_date, commit_after )
    r.insert()


	{'stg_tbl': 'staging.v_requests', 'tbl': 'requests', 'start_date': '2019-02-24', 'end_date': '2019-03-05', 'commit_after': 100}


	
[2019-03-04 05:08:11,625] {{logging_mixin.py:95}} INFO - [2019-03-04 05:08:11,625] {{base_processing.py:49}} ERROR - IntegrityError with :
insert into requests(external_id, request_date, accepted_amount, initial_amount, product, term, point_of_sale, prelending, chanel
, income, LCRM_ID, external_link, method_of_issuing, market_price, valuation_price, person_id, collateral_id, request_date_num, created, updated, is_active ) 
values ('19022310450001', '2019-02-23 04:10:59', 80000.0, 80000.0, 44, 24.0, 25, 1, 2, 60000.0, '511472', 0xb81300155d36c90711e93707e0eaceca00000000000000000000000000000000, 
3, 300000.0, 225000.0, 1062697, 379695, '20190223', '2019-03-04 05:08:11', NULL, 1) 
(pyodbc.IntegrityError) ('23000', "[23000] [FreeTDS][SQL Server]Violation of UNIQUE KEY constraint 'idx_unq_requests'. Cannot insert duplicate key in object 'dbo.requests'. The duplicate key value is (0xb81300155d36c90711e93707e0eaceca00000000000000000000000000000000, Feb 23 2019  4:10AM). (2627) (SQLExecDirectW)") [SQL: "insert into requests(external_id, request_date, accepted_amount, initial_amount, product, term, point_of_sale, prelending, chanel, income, LCRM_ID, external_link, method_of_issuing, market_price, valuation_price, person_id, collateral_id, request_date_num, created, updated, is_active ) values ('19022310450001', '2019-02-23 04:10:59', 80000.0, 80000.0, 44, 24.0, 25, 1, 2, 60000.0, '511472', 0xb81300155d36c90711e93707e0eaceca00000000000000000000000000000000, 3, 300000.0, 225000.0, 1062697, 379695, '20190223', '2019-03-04 05:08:11', NULL, 1) "]
updating row...

update requests set external_id = '19022310450001', request_date = '2019-02-23 04:10:59', accepted_amount = 80000.0,
 initial_amount = 80000.0, product = 44, term = 24.0, point_of_sale = 25, prelending = 1, chanel = 2, income = 60000.0, LCRM_ID = '511472'
 , external_link = 0xb81300155d36c90711e93707e0eaceca00000000000000000000000000000000, method_of_issuing = 3, 
 market_price = 300000.0, valuation_price = 225000.0, collateral_id = 379695, request_date_num = '20190223', updated = '2019-03-04 05:08:11', is_active = 1 where id = 766128 
INFO - ['external_id', 'request_date', 'accepted_amount', 'initial_amount', 'product', 'term', 'point_of_sale', 'prelending', 'passport_number', 'vin',
 'chanel', 'income', 'LCRM_ID', 'external_link', 'method_of_issuing', 'market_price', 'valuation_price']



*/
-- =============================================
CREATE procedure   [etl].[base_etl_process_requests] 
@start_date datetime,
@end_date datetime
as
begin
	
	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024)=CONCAT('@start_date = ', FORMAT(@start_date, 'yyyy-MM-dd HH:mm:ss')
		,' ', '@end_date = ',  FORMAT(@end_date, 'yyyy-MM-dd HH:mm:ss')
		)

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
begin try
    
--select * from staging.v_requests


---declare @start_date datetime='20160301'
--declare @end_date datetime='20200614'


	declare @updatedRows int=0
	declare @insertedRows int=0
	declare @result nvarchar(max)=''

--staging.v_requests
if object_id ('tempdb.dbo.#v_requests') is not null drop table #v_requests



	
	/*
	
  
  select * from staging.v_requests

  where   cast(request_date  as date) between @start_date  and @end_date 

  select  request_date_num     = format([request_date],'yyyyMMdd') from   DWH_NEW.staging.v_requests
  order by 1
  */
--select * from dbo.points_of_sale


;
with max_request_date as 
	(
	 select external_link
	      , request_date = max([request_date])
	   from staging.v_requests
	  where   cast(request_date  as date) between @start_date  and @end_date 
	  group by external_link
	)


	select person_id			= isnull(p.id,-1)
		 , collateral_id		= isnull(c.id,-1)
		 , [request_date]       = v.[request_date]
         , [initial_amount]     = cast([initial_amount]  as float)
		 , [accepted_amount]    = cast([accepted_amount] as float)
         , [product]            = pr.id
         , [term]
         , [point_of_sale]      = ps.id
         , [prelending]         = pl.id
         , [income]             = cast([income]  as float)
         , [chanel]             = ch.id
	     , [external_id]        = v.[external_id]
         , [LCRM_ID]
         , created              = getdate()
         , updated              = null
         , is_active            = 1
         , request_date_num     = format(v.[request_date],'yyyyMMdd')
         , [external_link]      = v.[external_link]
         , reg_address_id       = null
         , res_address_id       = null
         , [method_of_issuing]  = moi.id
         , [recommend_price]    = cast(v.[recommend_price] as float)
         , [market_price]       = cast(v.[market_price] as float)
         , [valuation_price]    = cast([valuation_price] as float)
		 , [risk_criteria]      = v.risk_criteria
     , risk_visa            = v.risk_visa
		 
      into #v_requests
	  from  staging.v_requests v
      join		max_request_date m on m.request_date=v.request_date and m.external_link=v.external_link
	  left join dbo.persons  p			on	v.[passport_number]		=	p.[passport_number]
	  left join dbo.collaterals  c		on	v.vin					=	c.vin
	  left join products pr				on	lower(v.product)        =	lower(pr.name)
      left join  dbo.points_of_sale ps       on  lower(v.point_of_sale)  =   lower(ps.name)
      left join prelending pl           on  lower(v.prelending)     =   lower(pl.name)
      left join chanels ch              on  lower(v.chanel)         =   lower(ch.name)
      left join methods_of_issuing moi  on  lower(v.method_of_issuing)  = lower(moi.name)

	 
	 ;
  update r 
		set 
            external_id     = v.external_id
          , request_date    = v.request_date
          , accepted_amount = v.accepted_amount
          , initial_amount  = v.initial_amount
          , product = v.product
          , term = v.term
          , point_of_sale = v.point_of_sale
          , prelending = v.prelending
          , chanel = v.chanel
          , income = v.income
          , LCRM_ID = v.LCRM_ID
          , method_of_issuing = v.method_of_issuing
          ,[recommend_price]=v.[recommend_price]
          , market_price = v.market_price
          , valuation_price = v.valuation_price 
          
          , collateral_id = v.collateral_id
          , request_date_num = v.request_date_num
          , updated = getdate()
          , is_active = 1 
		  , risk_criteria     = v.risk_criteria
		  , risk_visa            = v.risk_visa
		  , person_id  = iif(isnull(v.person_id,1) != -1, v.person_id, r.person_id) --Исправил в рамках задачи DWH-756 необходиом обновлять person_id если ранее его не проставили.
 --  select * 
	  from	#v_requests v
			inner join dbo.requests r on v.external_link=r.external_link
            --where r.external_link=0xA2D200155D4D095311E9383F6C433D9900000000000000000000000000000000

set @updatedRows=@@ROWCOUNT		
		



	 ;with for_insert  as(
	select	v.* 
	  from	#v_requests v
			left join dbo.requests r  on v.external_link=r.external_link
	 where  r.id is null --and v.external_link not in (select distinct external_link from dbo.requests r  )
	 )


     insert into dbo.requests (
            external_id
          , request_date
          , accepted_amount
          , initial_amount
          , product
          , term
          , point_of_sale
          , prelending
          , chanel
          , income
          , LCRM_ID
          , external_link
          , method_of_issuing
          , recommend_price
          , market_price
          , valuation_price
          , person_id
          , collateral_id
          , request_date_num
          , created
          , updated
          , is_active 
		  , risk_criteria
      , risk_visa           ) 

          select 

                      external_id
          , request_date
          , accepted_amount
          , initial_amount
          , product
          , term
          , point_of_sale
          , prelending
          , chanel
          , income
          , LCRM_ID
          , external_link
          , method_of_issuing
          , recommend_price
          , market_price
          , valuation_price
          , isnull(person_id,-1)
          , collateral_id
          , request_date_num
          , getdate()
          , null
          , 1
		  , risk_criteria
      , risk_visa            
          from for_insert

set @insertedRows=@@ROWCOUNT


 set @result=N' Results:<br /><br />'
  
set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'
+'Updated: '+format(@updatedRows,'0')

select @result



exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
end try
begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

    exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Error','Error',@error_description
	;throw 51000, @error_description, 1
end catch
end






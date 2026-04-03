-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl   process_credits 
--
--  etl.base_etl_process_credits  '20190407','20190411'
/*

def cred(stg_tbl, tbl, start_date, end_date, commit_after, **kwargs):
    ms = MsSqlHook(mssql_conn_id ='new_dwh')
    r= Credit(ms,  stg_tbl, tbl, start_date, end_date, commit_after )
    r.insert()


	{'stg_tbl': 'staging.v_credits', 'tbl': 'credits', 'start_date': '2019-02-24', 'end_date': '2019-03-05', 'commit_after': 100}

    insert into credits(external_link, external_id, credit_date, amount, term, product, prelending, person_id, request_id, collateral_id, created, updated, is_active ) values (0xb81300155d36c90711e93b68392d8d9500000000000000000000000000000000, '19022829250001', '2019-03-01 17:37:35', 100000.0, 60.0, 46, 1, 1069346, 773880, 384276, '2019-03-04 05:12:18', NULL, 1) 
(pyodbc.IntegrityError) ('23000', "[23000] [FreeTDS][SQL Server]Violation of UNIQUE KEY constraint 'idx_unique_credits'. Cannot insert duplicate key in object 'dbo.credits'. The duplicate key value is (0xb81300155d36c90711e93b68392d8d9500000000000000000000000000000000, Mar  1 2019  5:37PM). (2627) (SQLExecDirectW)") [SQL: "insert into credits(external_link, external_id, credit_date, amount, term, product, prelending, person_id, request_id, collateral_id, created, updated, is_active ) values (0xb81300155d36c90711e93b68392d8d9500000000000000000000000000000000, '19022829250001', '2019-03-01 17:37:35', 100000.0, 60.0, 46, 1, 1069346, 773880, 384276, '2019-03-04 05:12:18', NULL, 1) "]
updating row...

update credits set external_link = 0xb81300155d36c90711e93b68392d8d9500000000000000000000000000000000, external_id = '19022829250001', credit_date = '2019-03-01 17:37:35', amount = 100000.0, term = 60.0, product = 46, prelending = 1, request_id = 773880, collateral_id = 384276, updated = '2019-03-04 05:12:19', is_active = 1 where id = 171660 



*/
-- =============================================
CREATE procedure   [etl].[base_etl_process_credits] 
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
/*
declare @start_date datetime='20190401'
declare @end_date datetime='20190411'
*/

	declare @updatedRows int=0
	declare @insertedRows int=0
	declare @result nvarchar(max)=''



/*
select top 10 * from staging.v_credits   
where cast(credit_date  as date) between @start_date  and @end_date 

order by 1

select top 10 * from dbo.credits
*/

if object_id ('tempdb.dbo.#v_credits') is not null drop table #v_credits

;
with max_request_date as 
	(
	 select external_link
	      , credit_date = max([credit_date])
	   from staging.v_credits
	  where   cast(credit_date  as date) between @start_date  and @end_date 
    and external_link<>0x0000000000000000000000000000000000000000000000000000000000000000
	  group by external_link
	)
--select  * from max_request_date

	select person_id			= p.id
		 , collateral_id		= isnull(c.id,-1)
         , [request_id]         = rq.id
		 , [credit_date]        = v.[credit_date]
         , [product]            = pr.id
         , [amount]             = cast([amount]  as float)
         , [term]               = v.[term]
         , [prelending]         = pl.id
	     , [external_id]        = v.[external_id]
         , created              = getdate()
         , updated              = null
         , is_active            = 1
         , [external_link]      = v.[external_link]
		 , insurance_value      = isnull(v.insurance_value, 0)
      into #v_credits
	  from  staging.v_credits v
      join		max_request_date m on m.credit_date=v.credit_date and m.external_link=v.external_link
	  left join dbo.persons  p			on	v.[passport_number]		=	p.[passport_number]
	  left join dbo.collaterals  c		on	v.vin					=	c.vin
	  left join products pr				on	lower(v.product)        =	lower(pr.name)
      left join dbo.requests rq         on  rq.external_link        =   v.external_link
      left join prelending pl           on  lower(v.prelending)     =   lower(pl.name)
     /* 

      select * from  staging.v_credits v where external_link=0x0000000000000000000000000000000000000000000000000000000000000000

	 --select * from #v_credits
   select * 
	  from	#v_credits v
			inner join dbo.credits cr on v.external_link=cr.external_link 
      where v.external_link<>0x0000000000000000000000000000000000000000000000000000000000000000
      order by v.external_id

         select v.external_id,count(*) 
	  from	#v_credits v
			inner join dbo.credits cr on v.external_link=cr.external_link 
      where v.external_link<>0x0000000000000000000000000000000000000000000000000000000000000000
      group  by v.external_id
      having count(*) >1
      order by v.external_id


         select v.external_id,credit_date,count(*) 
	  from	dbo.credits v
		--	inner join dbo.credits cr on v.external_link=cr.external_link 
      where v.external_link<>0x0000000000000000000000000000000000000000000000000000000000000000
      group  by v.external_id
      having count(*) >1
      order by v.external_id
*/

	 ;
  update cr 
		set 


            external_id     = v.external_id
          , credit_date     = v.credit_date
          , amount          = v.amount
          , term            = v.term
          , product         = v.product
          , prelending      = v.prelending
          , request_id      = v.request_id
          , collateral_id = v.collateral_id
          , updated = getdate()
          , is_active = 1 
		  , insurance_value = v.insurance_value
		  , person_id = iif(isnull(v.person_id,1) != -1, v.person_id, cr.person_id)
 --  select * 
	  from	#v_credits v
			inner join dbo.credits cr on v.external_link=cr.external_link and cr.credit_date=v.credit_date
            --where r.external_link=0xA2D200155D4D095311E9383F6C433D9900000000000000000000000000000000
            where v.external_link<>0x0000000000000000000000000000000000000000000000000000000000000000
set @updatedRows=@@ROWCOUNT		
		



	 ;with for_insert  as(
	select	distinct
		   v.person_id	
		 , v.collateral_id	
         , v.[request_id] 
		 , v.[credit_date]
         , v.[product]  
         , v.[amount] 
         , v.[term]       
         , v.[prelending]  
	     , v.[external_id]  
         , v.created 
         , v.updated 
         , v.is_active 
         , v.[external_link] 
		 , v.insurance_value  
	  from	#v_credits v
			left join dbo.credits cr  on v.external_link=cr.external_link and cr.credit_date=v.credit_date
	 where  cr.id is null
	 )

 insert into credits(
                      external_link
                    , external_id
                    , credit_date
                    , amount
                    , term
                    , product
                    , prelending
                    , person_id
                    , request_id
                    , collateral_id
                    , created
                    , updated
                    , is_active
					, insurance_value 
                     ) 
     
          select 
          external_link
                    , external_id
                    , credit_date
                    , amount
                    , term
                    , product
                    , prelending
                    , person_id
                    , request_id
                    , collateral_id
                    
          , getdate()
          , null
          , 1
		  , insurance_value 
          from for_insert

set @insertedRows=@@ROWCOUNT


 set @result=N' Results:<br /><br />'
  
set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'
+'Updated: '+format(@updatedRows,'0')

select @result


-- дедубликация
;with cte as (
                select rn=row_number() over(partition by external_id  order by created desc )
                     , * 
                  from dwh_new.dbo.credits a
                 where external_id in (
                                        select external_id 
                                          from (
                                                select a.external_id, count(*) c 
                                                  from dwh_new.dbo.credits a
                                                 group by a.external_id
                                                having count(*)>1
                                               )q
                                        )

)

delete from cte where rn>1



exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
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






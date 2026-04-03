-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 04-03-2019
-- Description:	airflow etl  process_collaterals
--
--  etl.base_etl_process_collaterals '20190220','20190305'
/*
{'stg_tbl': 'staging.collaterals', 'tbl': 'collaterals', 'nrows': 100, 'commit_after': 100, 'start_date': '2019-02-23', 'end_date': '2019-03-04'}

select * from {}  where vin !='' and (brand is not null and model is not null) and request_date between '{}' and '{}'""".format(stg_tbl, start_date, end_date)

insert into collaterals(external_id, brand, model, vehicle_type, year, pts, market_price, vin, discount, external_link, created, person_id ) values ('19022525680001', 'RENAULT', 'LOGAN', 'B', 2012, '77НН 596798', NULL, 'X7LLSRB1HCH558961', NULL, 0xb81300155d36c90711e938b45b3ffd5900000000000000000000000000000000, '2019-03-04 05:06:32', 1061898) 
 (2601, b"Cannot insert duplicate key row in object 'dbo.collaterals' with unique index 'idx_collaterals_vin'. The duplicate key value is (X7LLSRB1HCH558961).DB-Lib error message 20018, severity 14:\nGeneral SQL Server error: Check messages from the SQL Server\n") 
updating row



*/
-- =============================================
CREATE procedure   [etl].[base_etl_process_collaterals]
@start_date datetime,
@end_date datetime
as
begin
	
	SET NOCOUNT ON;
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024)=CONCAT('@start_date = ', FORMAT(@start_date, 'yyyy-MM-dd HH:mm:ss')
		,' ', '@end_date = ',  FORMAT(@end_date, 'yyyy-MM-dd HH:mm:ss')
		)

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
	--log
	begin try
	
    
--select * from staging.collaterals

/*
declare @start_date datetime='20190415'
declare @end_date datetime='20190425'
*/

	declare @updatedRows int=0
	declare @insertedRows int=0
	declare @result nvarchar(max)=''

	/*
select * from staging.collaterals  where --vin !='' and (brand is not null and model is not null) and    cast(request_date  as date) between @start_date  and @end_date 
vin='XTA219210H0059609'
*/
if object_id ('tempdb.dbo.#v_collaterals') is not null drop table #v_collaterals



	
	/*
	drop table dwh_new_dev.dbo.collaterals 
	select * into dwh_new_dev.dbo.collaterals  from dwh_new.dbo.collaterals where created<'20190301'
	select top 10 * from staging.collaterals  where vin !='' and (brand is not null and model is not null)
	select top 10 * from dwh_new_dev.dbo.collaterals 
	*/
;
with max_request_date as 
	(
	 select vin
	      , request_date = max([request_date])
	   from staging.collaterals
	  where vin !='' and (brand is not null and model is not null) 
	  and [market_price] > 0 --DWH-891
	  and   cast(request_date  as date) between @start_date  and @end_date 
	  group by vin
	)

	select person_id=p.id
		 , [brand]
		 , [model]
		 , [year]
		 , [pts]
		 , vin=v.[vin]
  --   , rn=row_number() over( partition by v.vin order by (select null))
		 , [market_price]
		 , discount=cast(rtrim(ltrim(replace([liquidity],'%','')))as float)/100.0
		 , [vehicle_type]
		 , v.[external_id]
         , v.[request_date]
         , created=getdate()
         , updated=null
         , is_active =1
         , v.external_link-- = tmp.external_link.map(lambda x:'0x' + binascii.hexlify(x).decode('ascii'))
		 
      into #v_collaterals
	  from  staging.collaterals v
			join		max_request_date m on m.request_date=v.request_date and m.vin=v.vin
			left join persons p on p. passport_number = v.passport_number
      
			/*
	 select vin,count(*) from  staging.collaterals v
   group by vin
   having count(*)>1
   */

	 ;

	-- select * from dbo.collaterals



  update p 
		set 
		   person_id=coalesce(v.person_id, p.person_id, -1)
		 , [brand]=v.brand
		 , [model]		=v.model
		 , [year]		=v.[year]
		 , [pts]		=v.pts
		 , [vin]		=v.vin
		 , [market_price]=v.market_price
		 , discount =v.discount
		 , vehicle_type	=v.[vehicle_type]
		 , [external_id]   =v. [external_id]
         , external_link =v.external_link

 --  select * 
	  from	#v_collaterals v
			inner join dbo.collaterals p on v.vin=p.vin
			--where request_date>iif(p.created<isnull(p.updated,'1900-01-01'),p.updated,p.created)
		
set @updatedRows=@@ROWCOUNT		
		



	 ;with for_insert  as(
	select	v.* 
   , rn1=row_number() over( partition by v.vin order by (select null))
	  from	#v_collaterals v
			left join dbo.collaterals p on v.vin=p.vin
	 where  p.id is null
	 )
   /*select vin,count(*)  from for_insert
   group by vin having count(*) >1*/
  /* select *  from for_insert
   where vin='XTA219210H0059609'*/

	 insert into dbo.collaterals  -- select * from dbo.collaterals 
	 (
	 
	    person_id
		 , [brand]
		 , [model]
		 , [year]
		 , [pts]
		 , [vin]
		 , [market_price]
		 , discount
		 , vehicle_type	
		 , [external_id]
		   , created
           , updated
           , is_active
         , external_link

	 )
	 
	 
	  select coalesce( person_id, -1) as person_id
		 , [brand]
		 , [model]
		 , [year]
		 , [pts]
		 , [vin]
		 , [market_price]
		 , discount
		 , vehicle_type	
		 , [external_id]
		   , getdate()--created
           , null--updated
           , 1
         , external_link
	   from for_insert where rn1=1

set @insertedRows=@@ROWCOUNT


/*		

drop table dbo.persons

select * into dbo.persons from dwh_new.dbo.persons d where d.created<'20190304'
*/




 set @result=N' Results:<br /><br />'
  
set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'
+'Updated: '+format(@updatedRows,'0')



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






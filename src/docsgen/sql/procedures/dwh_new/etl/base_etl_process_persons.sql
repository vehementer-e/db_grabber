-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 28-02-2019
-- Description:	airflow etl  check_dicts_for_persons 
--
--  etl.base_etl_process_persons '20190220','20190305'
--etl.base_etl_process_persons '20201001','20201005'
/*
{'stg_tbl': 'staging.v_persons', 'tbl': 'persons', 'nrows': 100, 'commit_after': 100, 'start_date': '2019-02-23', 'end_date': '2019-03-04'}
*/
-- =============================================
CREATE   procedure   [etl].[base_etl_process_persons]
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
	
    declare 		@start_date date = '20190820',
		@end_date date = '20190905'
    */
    
	declare @updatedRows int=0
	declare @insertedRows int=0
	declare @result nvarchar(max)=''

-- выборка из v_persons , последняя по времени request_date запись

if object_id ('tempdb.dbo.#v_persons') is not null drop table #v_persons
;
with max_request_date as 
	(
	 select passport_number
	      , request_date = max([request_date])
	   from staging.v_persons
	  where cast(request_date  as date) between @start_date  and @end_date 
	  group by passport_number
	)

	select   [first_name]       =trim([first_name]  )
         , [middle_name]      =trim([middle_name] )
         , [last_name]        =trim([last_name]   )
         , [birth_date]
   	     , gender=g.id
         , v.[passport_number]
      	 , family_status_id=f.id
	     , education_id=e.id
         , [mobile_phone]
         , [external_id]
       , v.[request_date]
         , created=getdate()
         , updated=null
         , is_active =1
         , external_link-- = tmp.external_link.map(lambda x:'0x' + binascii.hexlify(x).decode('ascii'))
		 
      into #v_persons
	  from staging.v_persons v
			join		max_request_date m on m.request_date=v.request_date and m.passport_number=v.passport_number
			left join	gender g on g.name=case when isnull(v.gender,'')<>'Неизвестно' then v.gender else 'Нет данных' end
			left join   education e on e.name=v.education
			left join   family_status f on f.name=v.family_status
	 
	 
	 ;
with d as (
   select passport_number,rn=row_number() over (partition by passport_number order by (select null)) 
   from #v_persons 
   )
   delete 
  -- select * 
   from d where rn>1




  update p 
		set 
		[first_name]		= trim( v . [first_name])
		,[middle_name]		= trim(v . [middle_name])
		,[last_name]		= trim(v . [last_name]  )
		,[birth_date]		= v . [birth_date]
		,[gender]			= v . [gender]
		,[passport_number]	= v . [passport_number]
		,[family_status]	= v . [family_status_id]
		,[education]		= v . [education_id]
		,[mobile_phone]		= v . [mobile_phone]
		,[external_id]		= v . [external_id]
		--,[created]			= v . [created]
		,[updated]			= getdate()
		,[is_active]		= v . [is_active]
		,[external_link]	= v . [external_link]



 --  select * 
	  from	#v_persons v
			inner join dbo.persons p on v.passport_number=p.passport_number 
		--DWH-1083 Обновлять данные если они расходятся
		and (isnull (v.[first_name],'')!=isnull(p.first_name,'')
           OR	isnull (v. [middle_name],'')!= isnull (p.middle_name,'') 
           OR	v. [last_name]!=p.last_name
           OR  isnull (v. [birth_date],'19000101')!= isnull (p.birth_date,'19000101')
		   )
	
			--where request_date>iif(p.created<isnull(p.updated,'1900-01-01'),p.updated,p.created)
		
set @updatedRows=@@ROWCOUNT		
		



	 ;with for_insert  as(
	select	v.* 
	  from	#v_persons v
			left join dbo.persons p on v.passport_number=p.passport_number 
    /*  and isnull (v.[first_name],'')=isnull(p.first_name,'')
           and  isnull (v. [middle_name],'')= isnull (p.middle_name,'') 
           and v. [last_name]=p.last_name
           and  isnull (v. [birth_date],'19000101')= isnull (p.birth_date,'19000101')
	 */  where  p.id is null
	 )
	 insert into dbo.persons 
	 (
	 
	   [first_name]
      ,[middle_name]
      ,[last_name]
      ,[birth_date]
      ,[gender]
      ,[passport_number]
      ,[family_status]
      ,[education]
      ,[mobile_phone]
      ,[external_id]
      ,[created]
      ,[updated]
      ,[is_active]
      ,[external_link]
      ,[lead_id]
	 )
	 
	 
	  select   trim([first_name]  )
           , trim([middle_name] )
           , trim([last_name]   )
           , [birth_date]
   	       , gender
           , [passport_number]
      	   , family_status_id
	         , education_id
           , [mobile_phone]
           , [external_id]
           , created
           , updated
           , is_active
           , external_link-- = tmp.external_link.map(lambda x:'0x' + binascii.hexlify(x).decode('ascii'))
	       , null
	   from for_insert

set @insertedRows=@@ROWCOUNT


/*		

drop table dbo.persons

select * into dbo.persons from dwh_new.dbo.persons d where d.created<'20190304'
*/




 set @result=N' Results:<br /><br />'
  
set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'
+'Updated: '+format(@updatedRows,'0')



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






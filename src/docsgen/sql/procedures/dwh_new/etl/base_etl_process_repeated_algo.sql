

/*
замена процедуры etl  process_repeated_algo 
текущий статус - есть расхождения между phyton скриптом и 
exec [etl].[base_etl_process_repeated_algo]

*/

CREATE procedure [etl].[base_etl_process_repeated_algo]
as
begin
	set nocount on;
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      ''

	begin try

	drop table if exists #data

	;
	with first_credits
	as
	(
		select distinct person_id        
		,               min(request_date) request_date
		from (
		select *                                                               
		,      row_number() over (partition by person_id order by request_date) rn
		from tmp_v_requests
		where status in (11, 16)
		) as f
		where rn >=1
		group by person_id
		having count(1)>=1
	)
	,    ended
	as
	(
		select distinct request_id              
		,               person_id               
		,               cast(stage_time as date) end_date
		from requests_history rh
		join (select id
			,        person_id
			from requests)    r  on r.id = rh.request_id
		where status =16
	)

	select id                                               
	,      person_id                                        
	,      collateral_id                                    
	,      request_date=cast(request_date as date)          
	,      end_date=cast(end_date as date)                  
	,      rn                                               
	,      status                                           
	,      credit=case when status in ('11','16') then 1
	                                              else 0 end
		into #data
	from (
	select r.*                                                                 
	,      row_number() over (partition by r.person_id order by r.request_date) rn
	,      e.end_date                                                          
	from      tmp_v_requests r 
	join      first_credits  fc on fc.person_id =r.person_id
			and fc.request_date <= r.request_date
	left join ended          e  on e.request_id = r.id
	where status is not null
	) as f
	where olap_duplicate_algo !=1 --and id=19077
	order by person_id
	,        rn

	update #data
	set end_date = '20990101'
	where end_date is null
      /*
select max(rn) from #data
select * from #data where rn>20
*/


/*
select * from tmp_v_requests
r
join persons p on r.person_id=p.id
 where person_id in(select distinct person_id from #data where rn>20)

 */
 /*
select 

  returnType= 
                                    case when d1.end_date>d2.request_date and d1.credit=1 and d1.collateral_id<>d2.collateral_ID and d2.collateral_ID <>-1
                                         then 'parallel'
                                    else
                                         case when d1.end_date>d2.request_date and d1.credit=1 and d1.request_date<d2.request_date and (d1.collateral_id=d2.collateral_ID  or d2.collateral_ID=-1)
                                              then 'dokred'
                                              else 
                                                    case when d1.end_date<d2.end_date and d1.end_date<>'20990101'  and  d1.request_date<d2.request_date and d1.end_date<=d2.request_date  and d1.credit=1
                                                         then 'repeated'
                                                    end
                                         end
                                    end
                                    
,d2.*,d1.* from #data d2 
join #data d1 on d1.person_id=d2.person_id and d2.rn>1
where d1.rn=1 --and d2.request_date>'20190412'
and d1.person_id=262952
order by d2.person_id,d2.request_date
*/

/*
select * from tmp_v_requests       where status in (11, 16)
order by person_id,request_date

select * from statuses

*/
	--  select * from #data
  /*
if object_id('tempdb.dbo.#t1') is not null drop table #t1
    select * into #t1 from #data where rn=1
    */

	drop table if exists #t2

	select *
		into #t2
	from #data

	where rn>1
	--and  person_id=246921 --241646
	order by person_id
	,        rn

	drop table if exists #t3

	select *
		into #t3
	from #data
	where status in ('11','16')


	drop table if exists #tmp_t3

	select *
		into #tmp_t3
	from #data
	where 1=0

	--   select * from #t2
	create clustered index ix on #DATA(person_id, request_date)
	drop table if exists #res

	create table #res ( id            int
	,                   person_id     int
	,                   collateral_id int
	,                   request_date  date
	,                   end_date      date
	,                   rn            int
	,                   status        int
	,                   credit        int
	,                   parallel      int
	,                   docred        int
	,                   repeated      int
	,                   return_type   nvarchar(50)
	,                   [priority]    int )

	--select * from #t2
	DECLARE @ID INT
	DECLARE @PERSON_ID INT
	DECLARE @collateral_ID INT
	declare @request_date date
	declare @end_date date
	,       @rn       int
	,       @status   int
	,       @credit   int

	--while (select count(*) from #t2)>0

	declare cur_t2 cursor for select ID
	,                                PERSON_ID
	,                                request_date
	,                                collateral_ID
	,                                end_date
	,                                rn
	,                                status
	,                                credit
	FROM #T2
	order by person_id
	,        rn

	OPEN cur_t2
	FETCH NEXT FROM cur_t2
	INTO
	@ID,
	@PERSON_ID,
	@request_date,
	@collateral_ID,
	@end_date,
	@rn,
	@status,
	@credit

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--        SELECT TOP 1 @ID=ID,@PERSON_ID=PERSON_ID,@request_date =request_date,@collateral_ID =collateral_ID,@end_date=end_date,@rn=rn,@status=status,@credit=credit  FROM #T2 order by person_id,rn
		--SELECT @ID,@PERSON_ID,@request_date,@collateral_ID,@end_date,(select count(*) from #t2)
		-- select * from #t2 where id=@id
		truncate table #tmp_t3
		insert into #tmp_t3
		SELECT *
		FROM #DATA d
		WHERE d.person_id=@PERSON_ID
			and d.credit=1
			and request_date<=@request_date
		order by person_id
		,        rn
		--select * from #tmp_t3
		insert into #res
		SELECT @id                                                                                                                                       
		,      @PERSON_ID                                                                                                                                
		,      @collateral_ID                                                                                                                            
		,      @request_date                                                                                                                             
		,      @end_date                                                                                                                                 
		,      rn                                                                                                                                        
		,      @status                                                                                                                                   
		,      @credit                                                                                                                                   
		,      parallel=iif(end_date>@request_date and credit=1 and collateral_id<>@collateral_ID and @collateral_ID <>-1,1,0)                           
		,      docred=iif(end_date>@request_date and credit=1 and request_date<@request_date and (collateral_id=@collateral_ID or @collateral_ID=-1),1,0)
		,      repeated=iif(end_date<@end_date and end_date<>'20990101' and request_date<@request_date and end_date<=@request_date and credit=1,1,0)     
		,      returnType=
		case when end_date>@request_date
			and credit=1
			and collateral_id<>@collateral_ID
			and @collateral_ID <>-1 then 'parallel'
		                            else case when end_date>@request_date
				and credit=1
				and request_date<@request_date
				and (
					collateral_id=@collateral_ID
					or @collateral_ID=-1)     then 'dokred'
			                                  else case when end_date<@end_date
					and end_date<>'20990101'
					and request_date<@request_date
					and end_date<=@request_date
					and credit=1 then 'repeated' end end end                                                                                             
		,      0                                                                                                                                         
		FROM #tmp_T3
		-- select * from #res


		FETCH NEXT FROM cur_t2
		INTO
		@ID,
		@PERSON_ID,
		@request_date,
		@collateral_ID,
		@end_date,
		@rn,
		@status,
		@credit
	end


	delete from #res
	where return_type is null

	-- select * from #res

	update #res
	set priority = 1
	where return_type in ('parallel','dokred')

	--delete from #res where rn<>1





	--drop table #p
/*****************************************************сравнения
--select * from #res
select 
--distinct person_id  into #p 
*
from 
(

        select r.*
             , rr.id rrid
             , rr.return_type rr_return_type
             , rr.[priority] rrpriority 
          from 
        
        (

        select rn1=row_number() over (partition by id order by priority desc,rn )
        ,
        r.* from #res r --order by person_id,request_date
        ) r

        join returned rr on rr.id=r.id
         where r.rn1=1

         )q

         where (q.rr_return_type<>q.return_type
         or q.priority<>q.rrpriority)

order by 3,5


select 

  returnType= 
                                    case when d1.end_date>d2.request_date and d1.credit=1 and d1.collateral_id<>d2.collateral_ID and d2.collateral_ID <>-1
                                         then 'parallel'
                                    else
                                         case when d1.end_date>d2.request_date and d1.credit=1 and d1.request_date<d2.request_date and (d1.collateral_id=d2.collateral_ID  or d2.collateral_ID=-1)
                                              then 'dokred'
                                              else 
                                                    case when d1.end_date<d2.end_date and d1.end_date<>'20990101'  and  d1.request_date<d2.request_date and d1.end_date<=d2.request_date  and d1.credit=1
                                                         then 'repeated'
                                                    end
                                         end
                                    end
                                    
,d2.*,d1.* from #data d2 
join #data d1 on d1.person_id=d2.person_id and d2.rn>1
where d1.rn=1 --and d2.request_date>'20190412'
and d1.person_id in (select person_id from #p)
order by d2.person_id,d2.request_date

*/








	--insert into #res select * from #res
	--select distinct priority from #res where return_type in ('parallel','dokred')
	-- разница между таблицей returned и получившейся выборкой
	--select * from #res where person_id=241646--id=215271
/*

select * from 
(
select * from (
                select *,rn=row_number() over (partition by id order by priority desc ) from #res 
            )q
            where rn=1
            )q

            join   [dwh_new].[dbo].[returned] r
 on  r.id=q.id and r.return_type<>q.return_type
            where q.rn=1 



            */
	drop table if exists #RES1

	select r.*
		INTO #RES1
	from ( select rn1=row_number() over (partition by id order by priority desc,rn )
	,             r.*                                                               
	from #res r --order by person_id,request_date
	) r
	where r.rn1=1

	--    select * FROM [dwh_new].[dbo].[returned]
	--SELECT * INTO [dwh_new].[dbo].[returned_BACKUP_LAST_AIRFLOW_ETL]  FROM [dwh_new].[dbo].[returned]
	--update
	UPDATE R
	SET R.RETurn_type = res.return_type
	,   r.[priority] =  res.[priority]
	--select distinct res.*,r.*
	from #res1                      res
	join [dwh_new].[dbo].[returned] r   on r.id=res.id
			and (
				r.return_type<>res.return_type
				OR r.priority<>res.priority)

	--insert


	declare @idx_num int
	set @idx_num=(select max([index])
	from [dwh_new].[dbo].[returned])

	;
	with for_insert
	as
	(
		select distinct res.id
		,               res.return_type
		,               res.[priority]
		from      #res                       res
		left join [dwh_new].[dbo].[returned] r   on r.id=res.id
		where r.id is null
	)
	insert into [dwh_new].[dbo].[returned]
	select rn=@idx_num+ROW_NUMBER() over ( order by (select null))
	,      for_insert.*                                           
	,      1                                                      
	from for_insert



	-- удаляем дубли

	;
	with doubles
	as
	(
		select *                                                                                                 
		,      rowN=row_number() over(partition by id/*,	return_type,	priority,	rn*/ order by (priority))

		from [dwh_new].[dbo].[returned]

	)

	-- select *
	delete from [dwh_new].[dbo].[returned]
	where [index] in (select [index]
		from doubles
		where rowN>1)

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	,                                      ''

	end try
	begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+ cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+ cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
	+char(10)+char(13)+' ErrorState: '+ cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
	+char(10)+char(13)+' Error_line: '+ cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Error'
	,                                      'Error'
	,                                      @error_description
	;throw 51000, @error_description, 1
	end catch

end
/*
select * from #data where --id=771775
         person_id=246572

  
         select * from [dwh_new].[dbo].[returned] where id in (select id from #data where --id=19077
        person_id=246572)
        */

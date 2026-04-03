
/*
замена процедуры etl  process_repeated_algo 
текущий статус - есть расхождения между phyton скриптом и 
*/

create procedure etl_process_repeated_algo
as
begin

    if object_id('tempdb.dbo.#data') is not null drop table #data

    ;
    
    with first_credits as (
    select distinct person_id
         , min(request_date) request_date   
      from (
            select *
                 , row_number() over (partition by person_id order by request_date)  rn 
              from tmp_v_requests
             where status in (11, 16)
            ) as f
     where rn >=1 
     group by person_id
    having count(1)>=1 
    ),
    
    ended as (
    select distinct request_id
         , person_id
         , cast(stage_time as date) end_date 
      from requests_history rh
           join (select id, person_id from requests) r on r.id = rh.request_id
     where status =16
    )

    select id
         , person_id
         , collateral_id
         , request_date=cast(request_date as date)
         , end_date=cast(end_date as date)
         , rn
         , status 
         , credit=case when status in ('11','16') then 1 else 0 end
      into #data
      from (
            select r.*
                 , row_number() over (partition by r.person_id order by r.request_date) rn 
                 , e.end_date
              from tmp_v_requests r
                   join first_credits fc on fc.person_id =r.person_id and fc.request_date <= r.request_date
                   left join ended e on e.request_id = r.id
             where status is not null
            ) as f 
      where olap_duplicate_algo !=1 --and id=19077
      order by person_id , rn

     update #data 
        set end_date='20990101' 
      where end_date is null



  --  select * from #data
  /*
if object_id('tempdb.dbo.#t1') is not null drop table #t1
    select * into #t1 from #data where rn=1
    */
    if object_id('tempdb.dbo.#t2') is not null 
       drop table #t2

    select * 
           into #t2 
      from #data 
     where rn>1
 --and  person_id=246572
     order by person_id , rn
    
    if object_id('tempdb.dbo.#t3') is not null 
       drop table #t3
    
    select * 
           into #t3 
      from #data 
     where status in ('11','16')


    if object_id('tempdb.dbo.#tmp_t3') is not null 
       drop table #tmp_t3
    
    select * 
           into #tmp_t3 
      from #data 
     where 1=0



    if object_id('tempdb.dbo.#res') is not null 
       drop table #res
    
    create table #res (
           id int
         , return_type nvarchar(50)
         , [priority] int
    )

--select * from #t2
    DECLARE @ID INT
    DECLARE @PERSON_ID INT
    DECLARE @collateral_ID INT
    declare @request_date date
    declare @end_date date

    while (select count(*) from #t2)>0 
        begin
            SELECT TOP 1 @ID=ID,@PERSON_ID=PERSON_ID,@request_date =request_date,@collateral_ID =collateral_ID,@end_date=end_date  FROM #T2
            --    SELECT @ID,@PERSON_ID,@request_date,@collateral_ID,@end_date,(select count(*) from #t2)
            --  select * from #t2 where id=@id
            truncate table #tmp_t3
            insert into #tmp_t3
                   SELECT * 
                     FROM #DATA d 
                    WHERE  d.person_id=@PERSON_ID and d.credit=1 and request_date<=@request_date
                    order by person_id , rn
            -- select * from #tmp_t3
            insert into #res
                   SELECT @id
                        , --TOP 1 @ID=ID,@PERSON_ID=PERSON_ID,@request_date =request_date 
                          returnType= 
                                    case when end_date>@request_date and credit=1 and collateral_id<>@collateral_ID and @collateral_ID <>-1
                                         then 'parallel'
                                    else
                                         case when end_date>@request_date and credit=1 and request_date<@request_date and (collateral_id=@collateral_ID  or @collateral_ID=-1)
                                              then 'dokred'
                                              else 
                                                    case when end_date<@end_date and end_date<>'20990101'  and  request_date<@request_date and end_date<=@request_date  and credit=1
                                                         then 'repeated'
                                                    end
                                         end
                                    end
                      , 0
                   FROM #tmp_T3
       --     select * from #res
        DELETE FROM #T2 WHERE @ID=ID
        end

        delete from #res where return_type is null
        update #res set priority=1 where return_type in ('parallel','dokred')

        --insert into #res select * from #res
        --select distinct priority from #res where return_type in ('parallel','dokred')
-- разница между таблицей returned и получившейся выборкой

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


/*
select * from #data where --id=771775
         person_id=246572

  
         select * from [dwh_new].[dbo].[returned] where id in (select id from #data where --id=19077
        person_id=246572)
        */
end
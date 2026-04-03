

--exec [dbo].[Create_dm_cases_history]

CREATE     procedure  [dbo].[Create_dm_cases_history]
as 
begin
 --return

  set nocount on

    drop table if exists #t1

    drop table if exists #t2 

	select * 
into #t1

FROM [Feodor].[dbo].[dm_calls_history] nau-- with (nolock) 

where attempt_result is not null 
and creationdate>cast(getdate()-20 as date)

	  select * 
	  into #t2 from 
	  (
	  select login as login_emp, title as [ФИО работника] from [NaumenDbReport].[dbo].[mv_employee] with (nolock) 
	  ) naumen_calls


  begin tran

   
  delete from  feodor.dbo.dm_cases_history   where creationdate>cast(getdate()-20 as date)
  insert into  feodor.dbo.dm_cases_history --with (tablockx)
  select * 

from

(SELECT 
       [uuid]
      ,[creationdate]
      ,[phonenumbers]
      ,[statetitle]
      ,[projecttitle]
      ,[projectuuid]
      ,[title]
     
      ,[lcrm_id]
      ,[attempt_start]
      ,[attempt_end]
      ,[attempt_result]
      ,[attempt_number]
	  ,[login]
	  ,[ФИО работника]
	  ,first_value([login]) OVER (PARTITION BY uuid order by case when [login] is null then 1 else 0 end, attempt_start desc) AS [Логин последнего работника в рамках кейса]
	  ,first_value([ФИО работника]) OVER (PARTITION BY uuid order by case when [ФИО работника] is null then 1 else 0 end, attempt_start desc) AS [ФИО последнего работника в рамках кейса]
	  ,
	  case when 
			  (case when (sum(
	                          case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse')
			    			  then 1 else 0 end
	                          ) 
                              OVER(partition by uuid))
			  >0 then 1 else 0 end
			  )
	  =1


	  then (first_value([attempt_start]) OVER (PARTITION BY uuid order by case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse') then 1 else 0 end desc, 
																		  attempt_start desc
								              )
	  ) 
	  else null end as [Время последнего технического дозвона в рамках кейса]
	  	  ,
	  case when 
			  (case when (sum(
	                          case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse')
			    			  then 1 else 0 end
	                          ) 
                              OVER(partition by uuid))
			  >0 then 1 else 0 end
			  )
	  =1


	  then (first_value([attempt_start]) OVER (PARTITION BY uuid order by case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse') then 1 else 0 end desc, 
																		  attempt_start
								              )
	  ) 
	  else null end as [Время первого технического дозвона в рамках кейса]
	  , 
	  max(attempt_start) over(partition by uuid) as [Время последнего звонка в рамках кейса]
	  	  ,
	  min(attempt_start) over(partition by uuid) as [Время первого звонка в рамках кейса]
	  ,
	  case when (sum(
	                 case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse') then 1 else 0 end
	                 ) OVER(partition by uuid))
	  >0 then 1 else 0 end as [Флаг был технический дозвон в рамках кейса]
	  ,
	  case when (sum(
	                 case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse') then 1 else 0 end
	                 ) OVER(partition by uuid))
	  =0 then 1 else 0 end as [Флаг не было технического дозвона в рамках кейса]
	  , 
	  case when (sum(
	                 case when [speaking_time]
					 >2 then 1 else 0 end
	                 ) OVER(partition by uuid))
	  >0 then 1 else 0 end as [Флаг был дозвон >2 сек в рамках кейса]
	  , 
	  case when (sum(
	                 case when [speaking_time]
					 >2 then 1 else 0 end
	                 ) OVER(partition by uuid))
	  =0 then 1 else 0 end as [Флаг не было дозвона >2 сек в рамках кейса]
	  ,
	  sum(
	      case when attempt_result not in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse')
		  then 1 else 0 end
	      ) OVER(partition by uuid) as [Число недозвонов в рамках кейса]
	  ,
	  sum(
	      case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse')
	      then 1 else 0 end
	      ) OVER(partition by uuid) as [Число дозвонов в рамках кейса]

	  ,
	  case when attempt_result not in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse') 
	  then 1 else 0 end  as [Флаг технический недозвон по последнему звонку в рамках кейса]
	  
	  ,
	  case when attempt_result in ('connected' 
	                              ,'nonTarget'
	                              ,'wrongPhoneOwner' 
	                              ,'Thinking'
	                              ,'Consent'
	                              ,'Consultation'
	                              ,'MP'
	                              ,'complaint'
	                              ,'refuseClient'
	                              ,'recallRequest'
								  ,'clientrefuse')
	  then 1 else 0 end  as [Флаг технический дозвон по последнему звонку в рамках кейса]
	  ,
	  case when [speaking_time]>2 
	  then 1 else 0 end as [Флаг дозвон >2 сек по последнему звонку в рамках кейса]
	  ,
	  	  case when [projecttitle]='Fedor Автоинформатор лидген' 
	  then
	  case when (sum(
	  case when unblocked_time is not null then  1 else 0 end
	  ) over(partition by uuid))>0 then 1 else 0 end
	  else
	  null
	  end as [Флаг нажатие 1 в рамках кейса]	  
	  ,
	  
	  case when [projecttitle]='Fedor Автоинформатор лидген' 
	  then
	  case when unblocked_time is not null then  1 else 0 end
	  else
	  null
	  end as [Флаг нажатие 1 по последнему звонку в рамках кейса]
	  ,
	  count(session_id) over(partition by uuid) as [Число звонков в рамках кейса]

      FROM #t1 nau
	  left join 
	  #t2 imena 
      on nau.[login]=imena.[login_emp]


	  ) naumen_calls
	  where [attempt_start]=[Время последнего звонка в рамках кейса]
  commit tran

end
 

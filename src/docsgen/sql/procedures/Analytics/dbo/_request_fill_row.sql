
--EXEC msdb.dbo.sp_start_job @job_name =  '_request_fill_row '
--EXEC msdb.dbo.sp_delete_job @job_name =  '_request_fill_row'
--exec sp_create_job 'Analytics._request_fill_row full manual', 'exec _request_fill_row exec log_email ''ready''', '0' 
--EXEC msdb.dbo.sp_stop_job @job_name =  'Analytics._request_fill_row full manual'
--EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._request_fill_row full manual'
--exec запросы 'Analytics._request_fill_row full manual'
CREATE     proc [dbo].[_request_fill_row] @days int = null as --exec _request_fill_row 

BEGIN TRY 


declare @full_upd  bigint = 0
--select * into #t3267723 from _request where 1=0 
--drop table if exists _request select   *    into _request from #t3267723 
--create clustered index i1 on _request (  id )
--drop table if exists  _request_log  select *    into _request_log from #t3267723 
--return
--declare @days  int  declare @full_upd  bigint = 0
	--declare @days  int =10 declare @full_upd  bigint = 0
	--declare @days  int =30 declare @full_upd  bigint = 0
	if @days = -1
	begin
	 
	--drop table if exists _request_log
	--select * into _request_log from _request
	-- exec msdb.dbo.sp_start_job  @job_name= 'Analytics._request_product 7:00 each 5 min', @step_name = 'Analytics._request_product 7:00 each 5 min'
	drop table if exists #log
	select a.* into #log from _request a 

	left join _request_log b on a.guid=b.guid and a.rowUpdated=b.rowUpdated
	where b.guid is null


	insert into _request_log
	select * from #log
	return
	end

	if @days is null begin set @days=datediff(day, '20110101' , getdate()) set @full_upd = 1 end 

 
	declare @date date = cast(getdate()-@days as date)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
 
	--drop table if exists #ids
	--select id  into #ids from v_request_lk where 1=0
 
 
	--insert into #ids 
	--select id  from v_request_lk   
	--where created>= @date


	--insert into #ids 
	--select -abs(checksum(l.number) ) from mv_loans l
	--where issued>= @date


	--;with v  as (select *, row_number() over(partition by id order by (select null)) rn from #ids ) delete from v where rn>1

	
	--/* 
	



--				select * from stg._lk.events where name like '%доход%'
--status	code	requestCreated	eventId
--942 - ПТС ЛКК Открытие экрана подтверждения дохода	942	2025-07-01 11:04:22	669
--5050 - Документ подтверждающий доход загружен	5050	2025-07-01 11:04:22	688
--690 942 - ПТС ЛКК Открытие экрана подтверждения дохода
--669 542 - ПТС МП Открытие экрана подтверждения дохода

				--select * from stg._lk.events where id=83
		--		select * from #status
				 
-- SELECT 
--    a.[row_id] 
--,   a.[eventName] 
--,   a.status_crm 
--,   a.[islkk] 
--,   a.[isPtsEvent] 
--,   a.[eventId_lk] 
--,   a.[eventOrder] 
--,   a.[source] 
--,   e.name event_lk   FROM     #status a  left join stg._lk.events e on a.eventId_lk=e.id 	
--order by 1


			-- select * from  stg._lk.events where id=6

	drop table if exists #prolongation

	select number number , count(*) prolongationCnt, min(date) prolongationFirstDate into #prolongation from v_loan_prolongation  
	group by number

	--select * from 	#prolongation


	--drop table if exists #auto_apr
								  
	--select distinct a.[Номер заявки] number into #auto_apr from [Отчет Время статусов верификации] a


	--where [Время Затрачено В работе]=0		  and  a.Статус='Верификация клиента'
	--order by a.Номер desc
	drop table if exists #requests_crm
	select number, СрокЛьготногоПериода freeTermDays, nullif(СуммарныйМесячныйДоход, 0) monthlyIncome, nullif(электроннаяпочта, '') email into #requests_crm  from v_request_crm where created >=dateadd(day, -100, @date )

	;with v  as (select *, row_number() over(partition by number order by (select null)) rn from #requests_crm  ) delete from v where rn>1

	 drop table if exists #v_fa
 
	 select number, issued, closed,approved, ispts, ispdl , isInstallment isInst, phone, returnType3, issuedSum , cast( interestRate  as float) interestRate ,  isDubl  isDubl
	 , addProductSumNet
	 
	 
	 into #v_fa from v_fa  a--select_ta
	 where call1 >=@date 
   
   

	 drop table if exists #v_request
	 select number number 
  
	, case  z.ТипПродуктаПервоначальный when 'ПТС' then 'PTS' when 'Installment' then 'INST' when 'ВсёПро100' then 'INST'  else  z.ТипПродуктаПервоначальный end    productTypeInitial	 
    	  , productSubType
	 , z.guid guid
	 , z.created created
	 , z.Телефон phone
	--, z.feodor_request_Id  feodorId
   
	, z.СтатусЗаявки status_crm
	, z.term_days  termDays
 
	,  z.ispts   ispts 
	,  z.ispdl   ispdl 
	,  z.isInstallment   isInst 
	,  z.needBki 
	,  z.call03
	,  z.call03approved
	,  z.call1 call1
	,  z.call1approved call1approved
	,  z.checking checking
	, z.call15
	, z.call15approved
	,  z.Call2 call2
	,  z.[Call2 accept] call2approved
	,  z.[Верификация документов клиента] clientVerification
	, z.call3
	, z.call3approved
	,  z.[Одобрены документы клиента] clientApproved
	,  z.carVerification carVerificarion
	, z.call4
	, z.call4approved
	, z.call5
	, z.call5approved
	,  z.approved approved
	,  z.ContractSigned contractSigned
	,  z.issued   issued
	,  z.approvedSum approvedSum
	,  z.firstSum  firstSum
	,  z.requestSum  requestSum
	,  z.issuedSum issuedSum
	,  z.term term
	,  z.closed closed 
	,  z.declined declined 
	,  z.cancelled  cancelled  
	,  z.rejected  rejected  
	,  z.client_id  clientId
	,   z.fio fio 
	, z.firstName
	, z.lastName
	, z.patronymic
	,   z.birthday  birthday  
	,   z.lk_request_id lk_requestId
	,   loanNumber loanNumber
 , z.fioBirthday fioBirthday

 , z.passportSerialNumber  passportSerialNumber

 , z.carBrand
 , z.carModel
 , z.carYear
 , z.vin
 , z.declineReason
 , z.link
 , z.region
 , z.regionRegistration
 , z.productNameCrm
 , z.interestRateRecommended
 , z.age 
 , z.employmentType
 , z.isTakePts 
 , z.payMethod
  

	 into #v_request from v_request z
	 where created>= @date
  

	 update a set a.lk_requestid   = b.id from #v_request a join v_request_lk b on a.guid=b.guid and a.lk_requestid is null
	 --update a set a.feodorId   = b.id from #v_request a join v_request_feodor b on a.number=b.number and a.feodorId is null
	 --update a set a.feodorId   = b.id from #v_request a join v_request_feodor b on a.guid=b.IdExternal and a.feodorId is null

	 

	  --select * from #v_request where number='140315540002  '
	 delete from  #v_request where guid is null
 
	drop table if exists #loans
 



	select  
	  isnull( nullif( a.fioBirthday, '   0001.01.01') ,  b.fioBirthday)  fioBirthday
	 , isnull(  nullif( a.passportSerialNumber , '')  ,  b.passportSerialNumber)  passportSerialNumber
	 , client_phone  clientPhone
	 , a.client_id clientId
	, isnull(  b.issued  , a. issued )   issued 
	, isnull( isnull(  b.closed  , a. closed ) , GETDATE() ) closedIsnullNow

	,  sum      , isnull(  b.closed  , a. closed )  closed  , a.phone  
	, isnull( b.call1 , dateadd(second, -1,  isnull(  b.issued  , a. issued )  )) call1
	, b.created
	, a.number loanNumber,  a.isPts, a.ispdl ,  case when a.ispdl=1 then 'PDL' when a.isInstallment=1 then 'INST' when a.isPts=1 then 'PTS' end productType   
	, isnull( b.rbp, 'NotRBP') rbp
	, cast(a.[ПСК текущая] as float) pskRate
	, cast(a.[Текущая процентная ставка] as float) interestRate
	, cast(a.[Размер платежа первоначальный] as numeric(15,2) ) firstSchedulePay
	, cast( a.[Стоимость ТС] as bigint) carPrice
 	into #loans 
	
	from mv_loans	a 
	left join v_request b on a.number=b.loanNumber


	
	--select * from #loans

	  update a set a.issued = dateadd(second, 2,  created ) , a. call1 =  dateadd(second, 1,  created ) from #loans a where issued < created and cast( issued  as date)  = cast(created  as date) 
	  update a set a.closed = dateadd(second, 1,  issued ) from #loans a where closed < issued and cast( issued  as date)  = cast(closed  as date) 
	  update a set a.created = dateadd(second, -1,  call1 ) from #loans a where call1 < created --and cast( issued  as date)  = cast(closed  as date) 

	

	drop table if exists #pay_method
	 
select * into #pay_method 
from (
 select a.guid, a.payMethod, a.sbpBank paySbpBank , a.created  , row_number() over(partition by guid order by created desc ) rnDelete  from v_request_feodor_payment a
 ) 
 x where rnDelete=1

	drop table if exists #requests_lk

	select z.guid	  guid
	, z.lk_requestId id
	,    z.created created 
	,    isnull(  isnull( z.number 	, l.loanNumber )  , r.num_1c ) number
	,    case when  z.isInst is not null then  z.isInst else  case when l.isPts=1 then 0 when l.isPts=0 and l.ispdl=0 then 1 end end  isInst
	, 	  isnull( b.name_1c, 'CMR')	origin
	, isnull ( isnull ( nullif( z.phone , ''), nullif( r.client_mobile_phone , '')  ) , nullif( l.phone, '') ) 	phone
	--, r.lcrm_id leadId_lcrm

	,    case	
	when product_types_id  in (7,8) then 'BIG INST'
	when product_types_id = 5 then 'AUTOCREDIT'
	when l.productType = 'PTS' then  'PTS'
	when l.productType = 'PDL' then  'PDL'
	when l.productType = 'INST' then  'INST'
	when z.ispts = 1 then 'PTS'
	when z.ispdl = 1 then 'PDL'
	when z.ispdl = 0 and z.ispts=0 then 'INST'
	when product_types_id = 1 then 'PTS'
	when product_types_id = 2 then 'INST'
	when product_types_id = 3 then 'PDL'
 
	end   [productType]
		,    case	
	when product_types_id  in (7,8) then 'BIG INST'
	when product_types_id = 5 then 'AUTOCREDIT'
	when l.productType = 'PTS' then  'PTS'
	when l.productType = 'PDL' then  'NO PLEDGE'
	when l.productType = 'INST' then  'NO PLEDGE'
	when z.ispts = 1 then 'PTS'
	when z.ispdl = 1 then 'NO PLEDGE'
	when z.ispdl = 0 and z.ispts=0 then 'NO PLEDGE'
	when product_types_id = 1 then 'PTS'
	when product_types_id = 2 then 'NO PLEDGE'
	when product_types_id = 3 then 'NO PLEDGE'
 
	end   [productType2]
	, productTypeInitial
	, [productSubType] 
	, pr.prolongationCnt	  
	, pr.prolongationFirstDate  
	--, z.feodorId feodorId
	, ispts = case when z.isInst=1	or z.isPdl=1  or  product_types_id in (2,3,7 ,8)	  then 0 else 1 end 
	, monthlyIncome =  case when try_cast(isnull(  rcrm.monthlyIncome , nullif( r.client_total_monthly_income,0) )  as int)>100 then try_cast(isnull(  rcrm.monthlyIncome , nullif( r.client_total_monthly_income,0) )  as int) end 
	,z.status_crm
	,z.termDays   
	, rcrm.freeTermDays  freeTermDays
	, cast( case when  z.termDays is not null then dateadd(day, z.termDays,   z.issued) else dateadd(month, z.term, z.issued)  end as date) closedPlanDate
	--, case when z.approved is not null and   pr1.number is not null then 1 when   z.approved is not null then 0 end isAutomaticApprove

	, z.needBki                                         needBki        
	,   z.call03			   call03
	,   z.call03approved	   call03approved


	,isnull( l.call1, z.call1 )   call1
	, z.call1approved
	, z.checking
	, z.call15
	, z.call15approved



	, z.call2
	, z.call2Approved
	, z.clientVerification
	, z.call3
	, z.call3approved

	, z.clientApproved
	, z.carVerificarion
	, call4
	, call4approved
	, call5
	, call5approved




	, z.approved
	, z.ContractSigned
	,isnull( l.issued, z.issued ) issued
	, isnull( z.firstSum , r.summ	 ) firstSum
	, isnull( z.requestSum , r.summ	 ) requestSum
	, isnull( z.approvedSum , l.sum) approvedSum 
	, z.issuedSum
	, z.term
	,isnull( l.closed,  z.closed)  closed
	, z.rejected 
	, z.declined
	, z.cancelled
	, #v_fa.isDubl
	, #v_fa.addProductSumNet
	, isnull( l.interestRate,  #v_fa.interestRate) interestRate
	, l.firstSchedulePay
	, z.interestRateRecommended interestRateRecommended
	, isnull(z.clientId , l.clientId) clientId
	,  isnull(l.fioBirthday , z.fioBirthday ) fioBirthday
	, z.fio fio
	, z.lastName
	, z.firstName
	, z.patronymic

	,  isnull(l.passportSerialNumber , z.passportSerialNumber ) passportSerialNumber	

, z.carBrand
, z.carModel
, z.carYear
, l.carPrice
, z.vin
, z.declineReason
, r.request_source_guid parentGuid
, r.code code
, z.link
, z.region
, z.regionRegistration
, l.pskRate
, z.productNameCrm
, z.loanNumber
, r.auto_reg_number carRegNumber
, z.age
, cast( z.employmentType          as varchar(255)) employmentType
, cast( r.[client_workplace_name] as varchar(255)) employmentPlace
, cast( r.[client_work_position]  as varchar(255)) employmentPosition
, z.isTakePts
, cast( f.workplaceVerifiedIncome   as int)  workplaceVerifiedIncome   
, cast( f.rosstatIncome				as int) 	rosstatIncome				
, cast( f.bkiIncome					as int) 	bkiIncome					
, cast( f.bkiExpense				as int) 	bkiExpense				
,f.firstLimitChoice            collate Cyrillic_General_CI_AS firstLimitChoice
,f.secondLimitChoice           collate Cyrillic_General_CI_AS secondLimitChoice
,f.finalLimitChoice            collate Cyrillic_General_CI_AS finalLimitChoice
, isnull(rcrm.email , nullif(r.client_email ,'') ) email
, isnull(z.payMethod ,pm.payMethod ) payMethod 
, pm.paySbpBank
, #v_fa.returnType3

	into #requests_lk	--select top 100 * 
	from #v_request z 
	left join stg._lk.requests r  on z.guid=r.guid
	left join stg._LK.requests_origin b	   on r.requests_origin_id=b.id
	 left join #prolongation pr on pr.number=z.loanNumber
	 --left join #auto_apr pr1 on pr1.number=z.number 
 
	 left join #requests_crm rcrm on rcrm.number=z.number

	 left join #v_fa on #v_fa.number=z.number
	 left join #loans l on l.loannumber=z.loanNumber  
	 left join stg._fedor.core_ClientRequest f on f.id   =z.guid 
	 --where isnull( r.id , - abs(checksum(l.loanNumber) ) ) in (select id from #ids)
	 left join #pay_method pm on pm.guid=z.guid


	  --update _request set _request.monthlyIncome = b.monthlyIncome from _request join #requests_lk b on _request.guid=b.guid  and isnull(_request.monthlyIncome, 0)<> isnull(b.monthlyIncome, 0)

	;with v  as (select *, row_number() over(partition by guid order by (select null)) rn from #requests_lk ) delete from v where rn>1

	
	  update a set a.issued = dateadd(second, 2,  created ) , a. call1 =  dateadd(second, 1,  created ) from #requests_lk a where issued < created and cast( issued  as date)  = cast(created  as date) 
	  update a set a.closed = dateadd(second, 1,  issued ) from #requests_lk a where closed < issued and cast( issued  as date)  = cast(closed  as date) 
	  update a set a.created = dateadd(second, -1,  call1 ) from #requests_lk a where call1 < created --and cast( issued  as date)  = cast(closed  as date) 
	  update a set a.call1 = dateadd(second, -1,  issued ) from #requests_lk a where issued is not null and call1 is null

	  --select * from  #requests_lk where  issued<call1
	  --select * from  #requests_lk where  issued is not null and call1 is null
	 

			drop table if exists #request_client 
			select guid,    b.clientId  , cast( 2.0 as float) priority , b.issued into #request_client from  #requests_lk a
			 join #loans b on (b.fioBirthday=a.fioBirthday ) and b.issued<= isnull(a.call1, a.created )
			union all
			select guid,    b.clientId  , cast( 1.5 as float) priority , b.issued from  #requests_lk a
			 join #loans b on (b.passportSerialNumber=a.passportSerialNumber ) and b.issued<= isnull(a.call1, a.created )
			union all
			select guid, b.clientId  , 4 priority , b.issued  from  #requests_lk a
			 join #loans b on ( a.phone=b.phone)and b.issued<= isnull(a.call1, a.created )
			union all
			select guid, b.clientId  , 3 , b.issued from  #requests_lk a
			 join #loans b on ( a.phone=b.clientPhone ) and b.issued<= isnull(a.call1, a.created )
			union all
			select guid, a.clientId , 1 priority, b.issued   from  #requests_lk a join #loans b on b.clientId=a.clientId and b.issued<= isnull(a.call1, a.created )
			where a.clientId is not null

			drop table if exists #request_client_rn
			--select * from #request_client
			;with v  as (select *, row_number() over(partition by guid order by priority, issued desc ) rn from #request_client )
			select * into  #request_client_rn from v where rn=1
 

	 drop table if exists #request_event_feodor

	select a.guid 

	, min(case when cast(c.code as bigint) = 2402             then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end ) _uprid
	, min(case when cast(c.code as bigint) = 2403             then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end ) _upridYes
	, min(case when cast(c.code as bigint) = 2701             then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end ) _upridGibddYes
	, min(case when cast(c.code as bigint) = 2703             then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end ) _upridFnsYes
	, min(case when cast(c.code as bigint) in ( 2703 , 2701)  then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end ) _upridFnsGibddYes
	, min(case when cast(c.code as bigint) = 2404             then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end ) upridNo
	, min(case when cast(c.code as bigint) = 2750             then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end )  _2750 
	, min(case when cast(c.code as bigint) = 2751             then dateadd(hour, 3, cast( b.CreatedOn as datetime2(0)) ) end )  _2751 
 
	 into #request_event_feodor

	from  #requests_lk a
	left join Stg._fedor.core_ClientRequestExternalEventHistory b on a.guid=b.ClientRequestId 
	left join Stg._fedor.dictionary_ClientRequestExternalEvent c on c.Id=b.ClientRequestExternalEventId
	--  where a.ispts=0
	group by a.guid

 

 --select * from #request_event_feodor
 --select * from Stg._fedor.dictionary_ClientRequestExternalEvent where  cast(code as bigint) = 2751
 --select * from  Stg._fedor.core_ClientRequestExternalEventHistory  where  ClientRequestExternalEventId='0B4FCD8A-801B-4BDC-A3F0-D81FBDE6B617'
 --select feodor_requestId from  #requests_lk

	 drop table if exists #requests_lk2

	 select a.number,  a.id, a.ispts, a.created , a.issued, a.approved, a.call1approved, a.call03, a.call03approved, a.call1, a.phone , a.returnType3 
	 , isnull( a.call1 ,a.created    ) call1IsnullCreated
	, c.clientId 
	, a.cancelled
	, a.declined
	, a.guid
	, a.loanNumber
	, a.link
	, a.checking
	, a.clientApproved
	, a.productType2
 
	 into #requests_lk2  
 
	 from #requests_lk a 
	 --left join #v_fa b on a.number=b.number
	 left join #request_client_rn c on c.guid=a.guid



	 drop table if exists #status	 
	 select  * into #status from (
	select null  row_id, productType2 = 'NO PLEDGE' , null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=0,  eventId_lk= 358 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'PTS'       , null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 358 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'NO PLEDGE' , null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=0,  eventId_lk= 19 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'PTS'       , null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 19 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'NO PLEDGE' , null                        status_crm, 'Перезапрос 1 пак' eventName , NULL  islkk , isPtsEvent=0,  eventId_lk= 3 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'PTS'       , null                        status_crm, 'Перезапрос 1 пак' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 3 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'PTS'       , null                        status_crm, 'Запрошены доработки по подтверждению дохода' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 682 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'PTS'       , null                        status_crm, 'Пауза в охлаждение' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 718 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, productType2 = 'NO PLEDGE' , null                        status_crm, 'Пауза в охлаждение' eventName , NULL  islkk , isPtsEvent=0,  eventId_lk= 718 ,  eventOrder = null, source = 'lk'   union  	
 	
	
	select 1  row_id , productType2 = 'NO PLEDGE' , null                        status_crm, 'Анкета' eventName , 1  islkk , isPtsEvent=0,  eventId_lk= 68 ,  eventOrder = 1, source = 'lk'   union  	
	select 2  row_id , productType2 = 'NO PLEDGE' , null                        status_crm, 'Анкета' eventName, 1  islkk , is_pts=0,  lk_id= 69 ,  status_order = 1, source = 'lk'   union  	
	--select 3  row_id , productType2 = 'NO PLEDGE' , null                        status_crm, 'Паспорт' eventName, 1  islkk , is_pts=0,  lk_id= 70 ,  status_order = 2, source = 'lk'   union  	
	select 4  row_id , productType2 = 'NO PLEDGE' , null                        status_crm, 'Фотографии' eventName, 1  islkk , is_pts=0,  lk_id= 70 ,  status_order = 3, source = 'lk'   union  
	select 5  row_id , productType2 = 'NO PLEDGE' , null                        status_crm, 'Паспорт' eventName, 1  islkk , is_pts=0,  lk_id= 71 ,  status_order = 2, source = 'lk' union  
	select 6  row_id , productType2 = 'NO PLEDGE' , null                        status_crm, 'Фотографии' eventName, 1  islkk , is_pts=0,  lk_id= 72 ,  status_order = 3, source = 'lk' union  
	select 7  row_id , productType2 = 'NO PLEDGE' , null                        status_crm, 'Переход на 1 пакет' eventName, 1  islkk , is_pts=0,  lk_id= 73 ,  status_order = 4, source = 'lk' union  
	select 8  row_id , productType2 = 'NO PLEDGE' , 'Верификация КЦ'            status_crm, 'Call1' eventName, 1  islkk , is_pts=0,  lk_id= null  ,  status_order = 4.5, source = 'lk' union  
	select 9  row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'О работе и доходе' eventName, 1  islkk , is_pts=0,  lk_id= 74 ,  status_order = 5, source = 'lk' union  
	select 9  row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'О работе и доходе' eventName, 1  islkk , is_pts=0,  lk_id= 329 ,  status_order = 5, source = 'lk' union  
	select 10 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 1  islkk , is_pts=0,  lk_id= 75 ,  status_order = 6, source = 'lk' union  
	select 11 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 1  islkk , is_pts=0,  lk_id= 416 ,  status_order = 6, source = 'lk' union  
	select 12 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 0  islkk , is_pts=0,  lk_id= 417 ,  status_order = 6, source = 'lk' union  
	select 13 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'Ожидание одобрения' eventName, 1  islkk , is_pts=0,   lk_id= 76 ,  status_order = 7, source = 'lk' union  
	select 14 row_id , productType2 = 'NO PLEDGE' , 'Одобрено'                  status_crm, 'Выбор предложения' eventName, 1  islkk , is_pts=0,   lk_id= 77 ,  status_order = 8, source = 'lk' union  
	select 15 row_id , productType2 = 'NO PLEDGE' , 'Одобрено'                  status_crm, 'Подписание договора' eventName, 1  islkk , is_pts=0,   lk_id= 78 ,  status_order = 9, source = 'lk'  union  
	select 16 row_id , productType2 = 'NO PLEDGE' ,  null                       status_crm, 'Анкета' eventName, 0  islkk , is_pts=0, lk_id= 90  ,  status_order = 1, source = 'lk'   union  	 
	select 17 row_id , productType2 = 'NO PLEDGE' ,  null                       status_crm, 'Анкета' eventName, 0  islkk , is_pts=0, lk_id= 91  ,  status_order = 1, source = 'lk'   union  	 
	--select 18 row_id , productType2 = 'NO PLEDGE' ,  null                       status_crm, 'Паспорт' eventName, 0  islkk , is_pts=0, lk_id= 92  ,  status_order = 2, source = 'lk'   union  	 
	select 19 row_id , productType2 = 'NO PLEDGE' ,  null                       status_crm, 'Фотографии' eventName, 0  islkk , is_pts=0, lk_id= 92  ,  status_order = 3, source = 'lk'   union  	 
	select 20 row_id , productType2 = 'NO PLEDGE' ,  null                       status_crm, 'Паспорт' eventName, 0  islkk , is_pts=0, lk_id= 93  ,  status_order = 2, source = 'lk' union  
	select 21 row_id , productType2 = 'NO PLEDGE' ,  null                       status_crm, 'Фотографии' eventName, 0  islkk , is_pts=0, lk_id= 94  ,  status_order = 3, source = 'lk' union  
	select 22 row_id , productType2 = 'NO PLEDGE' ,  null                       status_crm, 'Переход на 1 пакет' eventName, 0  islkk , is_pts=0, lk_id= 95  ,  status_order = 4, source = 'lk' union  
	select 23 row_id , productType2 = 'NO PLEDGE' , 'Верификация КЦ'            status_crm, 'Call1' eventName, 0  islkk , is_pts=0, lk_id= 1  ,  status_order = 4.5, source = 'lk' union  
	select 23 row_id , productType2 = 'NO PLEDGE' , 'Верификация КЦ'            status_crm, 'Call1' eventName, 0  islkk , is_pts=0, lk_id= 315  ,  status_order = 4.5, source = 'lk' union  
	select 24 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'О работе и доходе' eventName, 0  islkk , is_pts=0, lk_id= 96  ,  status_order = 5, source = 'lk' union  
	select 24 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'О работе и доходе' eventName, 0  islkk , is_pts=0, lk_id= 378  ,  status_order = 5, source = 'lk' union  
	select 25 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 0  islkk , is_pts=0, lk_id= 97  ,  status_order = 6, source = 'lk' union  
	select 26 row_id , productType2 = 'NO PLEDGE' , 'Предварительоне одобрение' status_crm, 'Ожидание одобрения' eventName, 0  islkk , is_pts=0, lk_id= 98  ,   status_order = 7, source = 'lk' union  
	select 27 row_id , productType2 = 'NO PLEDGE' , 'Одобрено'                  status_crm, 'Выбор предложения' eventName, 0  islkk , is_pts=0, lk_id= 99  ,  status_order = 8, source = 'lk' union  
	select 28 row_id , productType2 = 'NO PLEDGE' , 'Одобрено'                  status_crm, 'Подписание договора' eventName, 0  islkk , is_pts=0, lk_id= 100 ,    status_order = 9, source = 'lk' union 
	select 29 row_id , productType2 = 'NO PLEDGE' , 'Заем выдан' as status_crm,   'Заем выдан' eventName, null  islkk,is_pts=0, lk_id= null	  ,  status_order =16	, source = 'lk' union



	select 30 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на калькулятор ПТС' eventName, 0  islkk,   is_pts=1, lk_id= 79	  ,  status_order =1	, source = 'lk' union  
	select 31 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на Анкету ПТС' eventName, 0  islkk, is_pts=1, lk_id= 80	  ,  status_order =2	, source = 'lk' union  			
	select 32 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на Анкету ПТС' eventName, 1  islkk, is_pts=1, lk_id= 442	  ,  status_order =2	, source = 'lk' union  			
	select 32 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на Анкету ПТС' eventName, 1  islkk, is_pts=1, lk_id= 512	  ,  status_order =2	, source = 'lk' union  
	select 57 row_id , productType2 = 'PTS', null       as status_crm,   'Дозапрос данных до Call1' eventName, null  islkk, is_pts=1, lk_id= null	  ,  status_order =2.5	, source = 'lk' union  			
	select 33 row_id , productType2 = 'PTS', null       as status_crm,   'Открытие слота 2-3 стр паспорта ПТС' eventName, 0  islkk, is_pts=1, lk_id= 81	  ,  status_order =3	, source = 'lk' union  
	select 34 row_id , productType2 = 'PTS', null       as status_crm,   'Открытие слота 2-3 стр паспорта ПТС'eventName, 1  islkk, is_pts=1, lk_id= 438	  ,  status_order =3	, source = 'lk' union  
	select 35 row_id , productType2 = 'PTS', null       as status_crm,   'Загрузил 2-3 стр паспорта ПТС' eventName, null  islkk, is_pts=1, lk_id= 376	  ,  status_order =4	, source = 'lk' union  		
	select 36 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на 1 пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 82	  ,  status_order =5	, source = 'lk' union  				   
	select 37 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на 1 пакет ПТС' eventName, 1  islkk,is_pts=1, lk_id= 441	  ,  status_order =5	, source = 'lk' union  			       
	select 38 row_id , productType2 = 'PTS', null       as status_crm,   'Подписал 1 пакет ПТС' eventName, null  islkk,is_pts=1, lk_id= 1	  ,  status_order =6	, source = 'lk' union  				
	select 39 row_id , productType2 = 'PTS', null       as status_crm,   'Подписал 1 пакет ПТС' eventName, null  islkk,is_pts=1, lk_id= 315	  ,  status_order =6	, source = 'lk' union  			   
	select 40 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран Фото паспорта клиента ПТС' eventName, 0  islkk,is_pts=1, lk_id= 83	  ,  status_order =7	, source = 'lk' union  		
	select 41 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран Фото паспорта клиента ПТС' eventName, 1  islkk,is_pts=1, lk_id= 432	  ,  status_order =7	, source = 'lk' union  		
	select 42 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран с дополнительной информацией ПТС' eventName, 0  islkk,is_pts=1, lk_id= 84	  ,  status_order =8	, source = 'lk' union  		
	select 43 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран с дополнительной информацией ПТС' eventName, 1  islkk,is_pts=1, lk_id= 444	  ,  status_order =8	, source = 'lk' union  		
	select 44 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран с фото документов авто' eventName, 0  islkk,is_pts=1, lk_id= 85	  ,  status_order =9	, source = 'lk' union  	 
	select 45 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран с фото документов авто' eventName, 1  islkk,is_pts=1, lk_id= 434	  ,  status_order =9	, source = 'lk' union         	
	select 61 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран выбор оффера (доход)' eventName, 1  islkk,is_pts=1, lk_id= 690	  ,  status_order =9.3	, source = 'lk' union         
	select 62 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран выбор оффера (доход)' eventName, 1  islkk,is_pts=1, lk_id= 669	  ,  status_order =9.3	, source = 'lk' union         	
	select 58 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран подтверждения дохода' eventName, 1  islkk,is_pts=1, lk_id= 861	  ,  status_order =9.5	, source = 'lk' union         
	select 59 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран подтверждения дохода' eventName, 0  islkk,is_pts=1, lk_id=  847	  ,  status_order =9.5	, source = 'lk' union         	
	select 61 row_id , productType2 = 'PTS', null       as status_crm,   'Документ подтверждающий доход загружен' eventName, 0  islkk,is_pts=1, lk_id= 688	  ,  status_order =9.6	, source = 'lk' union         
	select 46 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран Способ выдачи ПТС' eventName, 0  islkk,is_pts=1, lk_id= 86	  ,  status_order =10	, source = 'lk' union  		 
	select 47 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран Способ выдачи ПТС' eventName, 1  islkk,is_pts=1, lk_id= 431	  ,  status_order =10	, source = 'lk' union  		 
	select 47 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран Способ выдачи ПТС' eventName, null  islkk,is_pts=1, lk_id= 867	  ,  status_order =10	, source = 'lk' union  		 
	select 47 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на экран Способ выдачи ПТС' eventName, null  islkk,is_pts=1, lk_id= 843	  ,  status_order =10	, source = 'lk' union  		 

	
	select 48 row_id , productType2 = 'PTS', null       as status_crm,   'Карта привязана ПТС' eventName, null  islkk,is_pts=1, lk_id= 17	  ,  status_order =11	, source = 'lk' union  				     
	select 49 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на фото авто ПТС' eventName, 0  islkk,is_pts=1, lk_id= 87	  ,  status_order =12	, source = 'lk' union  			     
	select 50 row_id , productType2 = 'PTS', null       as status_crm,   'Переход на фото авто ПТС' eventName, 1  islkk,is_pts=1, lk_id= 435	  ,  status_order =12	, source = 'lk' union  			     
	select 51 row_id , productType2 = 'PTS', null       as status_crm,   'Отправлена полная заявка ПТС' eventName, null  islkk,is_pts=1, lk_id= 8	  ,  status_order =12.5	, source = 'lk' union  				     
	select 51 row_id , productType2 = 'PTS', 'Одобрено' as status_crm,   'Финально одобрен ПТС' eventName, 0  islkk,is_pts=1, lk_id= 8	  ,  status_order =13	, source = 'lk' union  				     
	select 52 row_id , productType2 = 'PTS', 'Одобрено' as status_crm,   'Переход на второй пакет ПТС' eventName, null  islkk,is_pts=1, lk_id= 856	  ,  status_order =14	, source = 'lk' union  			     
	select 52 row_id , productType2 = 'PTS', 'Одобрено' as status_crm,   'Переход на второй пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 89	  ,  status_order =14	, source = 'lk' union  			     
	select 53 row_id , productType2 = 'PTS', 'Одобрено' as status_crm,   'Переход на второй пакет ПТС' eventName, 1  islkk, is_pts=1, lk_id= 428	  ,  status_order =14	, source = 'lk' union
	select 60 row_id , productType2 = 'PTS', 'Одобрено' as status_crm,   'Подписал второй пакет ПТС (анкета)' eventName, 0  islkk,is_pts=1, lk_id= null	  ,  status_order =14.5	, source = 'lk' union  		     	
	select 54 row_id , productType2 = 'PTS', 'Одобрено' as status_crm,   'Подписал второй пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 2	  ,  status_order =15	, source = 'lk' union  		     
	select 55 row_id , productType2 = 'PTS', 'Одобрено' as status_crm,   'Подписал второй пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 361	  ,  status_order =15	, source = 'lk' union    	     
	select 56 row_id , productType2 = 'PTS', 'Заем выдан' as status_crm, 'Заем выдан' eventName, null  islkk,is_pts=1, lk_id= null	  ,  status_order =16	, source = 'lk'  union

	
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Переход на анкету' eventName, 0  islkk,is_pts=0, lk_id= 68	  ,  status_order =1	, source = 'lk' union  		  
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Переход на анкету' eventName, 0  islkk,is_pts=0, lk_id= 69	  ,  status_order =1	, source = 'lk' union  		  
	
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Call03' eventName, 0  islkk,is_pts=0, lk_id= null	  ,  status_order =1.3	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Call03 одобрено' eventName, 0  islkk,is_pts=0, lk_id= null	  ,  status_order =1.5	, source = 'lk' union  		     
	
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Переход на фото паспорта' eventName, 0  islkk,is_pts=0, lk_id= 1037	  ,  status_order =2	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Переход на 1 пакет' eventName, 0  islkk,is_pts=0, lk_id= 1035	  ,  status_order =3	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Подписал 1 пакет' eventName, 0  islkk,is_pts=0, lk_id= 1	  ,  status_order =3.5	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Переход на ожидание предварительного одобрения' eventName, 0  islkk,is_pts=0, lk_id= 1035	  ,  status_order =4	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Переход на экран выбор оффера' eventName, 0  islkk,is_pts=0, lk_id= 1044	  ,  status_order =5	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Переход на экран с подтверждением дохожа' eventName, 0  islkk,is_pts=0, lk_id= 1045	  ,  status_order =6	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', '' as status_crm,   'Документ подтверждающий доход загружен' eventName, 0  islkk,is_pts=0, lk_id= 688	  ,  status_order =7	, source = 'lk' union  		     
	select 63 row_id , productType2 = 'BIG INST', 'Контроль данных' as status_crm,   'Переход на калькулятор' eventName, 0  islkk,is_pts=0, lk_id= 771	  ,  status_order =8	, source = 'lk' union  		     
	select 64 row_id , productType2 = 'BIG INST', 'Контроль данных' as status_crm,   'Переход на способ выдачи' eventName, 0  islkk,is_pts=0, lk_id= 774	  ,  status_order =9	, source = 'lk' union    	     
    select 65 row_id , productType2 = 'BIG INST', 'Контроль данных' as status_crm,   'Переход на способ выдачи' eventName, 0  islkk,is_pts=0, lk_id= 781	  ,  status_order =9	, source = 'lk' union    	     
	select 66 row_id , productType2 = 'BIG INST', 'Контроль данных' as status_crm,   'Переход на экран с таймером' eventName, null  islkk,is_pts=0, lk_id= 782	  ,  status_order =10	, source = 'lk'  union
	select 67 row_id , productType2 = 'BIG INST', 'Контроль данных'        as status_crm,   'Вышел с экрана с таймером' eventName, null  islkk,is_pts=0, lk_id= 789	  ,  status_order =11	, source = 'lk'  union
	select 69 row_id , productType2 = 'BIG INST', 'Одобрено' as status_crm,   'Подписал второй пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 2	  ,  status_order =15	, source = 'lk' union  		     
	select 70 row_id , productType2 = 'BIG INST', 'Одобрено' as status_crm,   'Подписал второй пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 361	  ,  status_order =15	, source = 'lk' union    	     
	select 71 row_id , productType2 = 'BIG INST', 'Заем выдан' as status_crm, 'Заем выдан' eventName, null  islkk,is_pts=1, lk_id= null	  ,  status_order =16	, source = 'lk' 


				) x



	drop table if exists #t2

	select s.eventName eventName ,e.id eventId, r.number , cast( re.created_at as datetime2(0)) created, r.id id, s.eventOrder  , r.ispts isPts, s.islkk isLkk , r.guid, 0 isFake , r.productType2 into #t2 from stg._LK.events	  e
	join Stg._LK.requests_events re on re.event_id=e.id
	join #requests_lk2 r  on r.id=re.request_id
	 join  #status   s on s.eventId_lk=e.id and r.productType2=s.productType2
	 where  r.created >='20250301'

	 --re.created_at >=@date
	 --and re.created_at >='20250301'

	
	insert into #t2
select s.eventName eventName, e.id eventId,  r.number number, dateadd(year, -2000, b.[Дата])  created ,  r.id, s.eventOrder, r.ispts, s.islkk, r.guid , 0 isFake , r.productType2
 
 from  
[Stg].[_1cCRM].[РегистрСведений_ИсторияСобытийЗаявокНаЗаймПодПТС]  b  
join [Stg].[_1cCRM].[Справочник_СобытияЗаявокНаЗаймПодПТС]  c on c.[Ссылка]=b.[Событие]
 join stg._lk.events e on e.code = c.[КодЛК]
 join #requests_lk2 r on r.link =b.Объект
	 join  #status   s on s.eventId_lk=e.id and r.productType2=s.productType2 -- and r.ispts=s.isPtsEvent
	 where      r.created <'20250301'
	 --dateadd(year, -2000, b.[Дата])     >=@date
	 --and dateadd(year, -2000, b.[Дата]) <'20250301'


	 --select * from #t2 
	 --where eventOrder=16

	 insert into #t2
	 select s.eventName, null id, a.number, a.issued , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake , a.productType2  from #requests_lk2 a join #status s on a.productType2=s.productType2 and s.eventOrder=16 and a.issued is not null

	 
	 insert into #t2
	 select s.eventName, null id, a.number, t.created , a.id, s.eventOrder , a.ispts, s.islkk, a.guid  , 0 isFake, a.productType2
	 from #requests_lk2 a 
	 join #status s on a.productType2='PTS' and s.eventOrder =2.5  and s.productType2='PTS'--and s.isPtsEvent=1 -- and a.call1 is not null
	 join v_request_crm_status t on a.link=t.link and t.status='Дозапрос данных до call 1'
	 --where  r.created >=@date

	
	 insert into #t2
	 select s.eventName, null id, a.number, a.created , a.requestId, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake, r.productType2  from v_request_crm_event a 
	 join #status s on 
	 s.eventOrder=14.5  and  a.event = 'Подписание 2-го пакета (анкета)'
	 join #requests_lk2 r on r.link = a.link and r.productType2='PTS' and s.productType2='PTS'
	 	 --where  r.created >=@date
 
	 
	 
	 --СИнхронизация ивентов по беззалогу со статусом заявки. Подписание 1 пакета должно сопровождаться наступлением статуса Call1. Статус Call1 должно означать что Event подписание 1 пакета все же был
	
	 delete a from #t2 a join #requests_lk2 b on a.guid=b.guid and a.eventOrder >=4.5 and a.productType2 ='NO PLEDGE' and b.Call1 is null
	 
	 insert into #t2
	 select s.eventName, null id, a.number, a.call1 , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake , a.productType2  
	 from #requests_lk2 a join #status s on  s.eventOrder =4.5  and a.call1  is not null  and s.productType2='NO PLEDGE' and a.productType2 ='NO PLEDGE'
	 left join #t2 t on a.guid=t.guid and t.eventOrder=4.5 
	 where t.guid is null

	 



	 --select * from #t2 
	 --where eventOrder=6

	 --select * from _request where 

	 
	 insert into #t2
	 select s.eventName, null id, a.number, a.call1 , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake, a.productType2 from #requests_lk2 a join #status s on   s.eventId_lk =1  and a.call1 is not null  and s.productType2='pts' and a.productType2 ='pts' --and s.isPtsEvent=1
	 left join #t2 t on a.guid=t.guid and t.eventOrder=6 
	 where t.guid is null


	 	 
	 insert into #t2
	 select s.eventName, null id, a.number, a.checking , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 1 isFake, a.productType2 from #requests_lk2 a join #status s on   s.eventId_lk =17  and a.checking is not null  and s.productType2='pts' and a.productType2 ='pts' -- and s.isPtsEvent=1
	 left join #t2 t on a.guid=t.guid and t.eventOrder=11 
	 where t.guid is null

	 insert into #t2
	 select s.eventName, null id, a.number, a.call03 , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 1 isFake , a.productType2  from #requests_lk2 a join #status s on  s.eventOrder =2.5  and a.call03  is not null  and a.created>='20250701' and s.productType2='pts' and a.productType2 ='pts'
	 left join #t2 t on a.guid=t.guid and t.eventOrder=2.5 
	 where t.guid is null



	 delete a from #t2 a join #requests_lk2 b on a.guid=b.guid and a.eventOrder >=13 and a.productType2 ='PTS' and b.approved is null

	 update a set a.created= b.approved from #t2 a  join #requests_lk2 b on a.guid=b.guid and a.eventOrder =13 and a.productType2 ='PTS'  and b.approved is not null



	  insert into #t2
	 select s.eventName, null id, a.number, a.approved , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake, a.productType2 from #requests_lk2 a join #status s on   s.eventOrder =13  and a.approved is not null  and s.productType2='pts' and a.productType2 ='pts' -- and s.isPtsEvent=1
	 left join #t2 t on a.guid=t.guid and t.eventOrder=13 
	 where t.guid is null




	 delete a from #t2 a join #requests_lk2 b on a.guid=b.guid and a.eventOrder >=7 and a.productType2 ='PTS' and b.call1approved is null

	 delete a from #t2 a join #requests_lk2 b on a.guid=b.guid and a.eventOrder >=4 and a.productType2 ='BIG INST' and b.call1approved is null



	 insert into #t2
	 select s.eventName, null id, a.number, a.call03 , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake , a.productType2  from #requests_lk2 a join #status s on  s.eventOrder =1.3  and a.call03  is not null  and s.productType2='big inst' and a.productType2 ='big inst'
 
 	 insert into #t2
	 select s.eventName, null id, a.number, a.call03approved , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake , a.productType2  from #requests_lk2 a join #status s on  s.eventOrder =1.5  and a.call03approved  is not null  and s.productType2='big inst' and a.productType2 ='big inst'
 
     
    
	 delete a from #t2 a join #requests_lk2 b on a.guid=b.guid and a.eventOrder >=2 and a.productType2 ='BIG INST' and b.call03  is not null and b.call03approved is null




	 delete a from #t2 a join #requests_lk2 b on a.guid=b.guid and a.eventOrder >=3.5 and a.productType2 ='BIG INST' and b.Call1 is null
	 
	 insert into #t2
	 select s.eventName, null id, a.number, a.call1 , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 0 isFake , a.productType2  
	 from #requests_lk2 a join #status s on  s.eventOrder =3.5  and a.call1  is not null  and s.productType2='BIG INST' and a.productType2 ='BIG INST'
	 left join #t2 t on a.guid=t.guid and t.eventOrder=3.5 
	 where t.guid is null


	 
	 -- insert into #t2
	 --select s.eventName, null id, a.number, a.call1 , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 1 isFake , a.productType2  from #requests_lk2 a join #status s on  s.eventOrder <=4  and a.call1  is not null    and s.productType2='big inst' and a.productType2 ='big inst'
	 --left join #t2 t on a.guid=t.guid and t.eventOrder=s.eventOrder
	 --where t.guid is null


  

	  insert into #t2
	 select s.eventName, null id, a.number, a.checking , a.id, s.eventOrder , a.ispts, s.islkk, a.guid , 1 isFake , a.productType2  from #requests_lk2 a join #status s on  s.eventOrder <=7  and a.checking  is not null    and s.productType2='big inst' and a.productType2 ='big inst'
	 left join #t2 t on a.guid=t.guid and t.eventOrder=s.eventOrder
	 where t.guid is null
	 
	 delete a from #t2 a join #requests_lk2 b on a.guid=b.guid and a.eventOrder >=15 and a.productType2 ='BIG INST' and b.approved is null


	 delete a from #t2 a 
	 left join #t2 b on a.guid=b.guid and b.eventName='Перезапрос 1 пак' and b.created<= a.created
	 where a.eventName  = 'Переподписан 1 пак' and b.guid is null


	 
	 delete a from #t2 a 
	 left join #t2 b on a.guid=b.guid and b.eventOrder  = 9.5-- and b.created<= a.created
	 where a.eventOrder  = 9.6 and b.guid is null and a.productType2='PTS'




	drop table if exists  #t2_



					 
	select 
		a.eventName 
	,   a.eventId 
	,   a.number 
	,   a.created 
	,   a.id 
	,   a.ispts 
	,   a.eventOrder 
	,   isFake
	,   isLkk isLkk
	, guid
	,productType2
	into #t2_
	from 

	#t2 a
	union all
	select a.eventName 
	,   a.eventId 
	,   a.number 
	,   a.created 
	,   a.id 
	,   a.ispts
	,   a.eventOrder 
	,   1 isFake
	,   null isLkk
	, guid
	, productType2
	  from (
	select 
		 null eventName 
	,   null eventId 
	,   a.number 
	,   dateadd(second,-a.eventOrder+ b.eventOrder,  a.created ) 	 created
	,   a.id 
	,   a.ispts 
	,     b.eventOrder eventOrder 
	,   1 is_fake
	, row_number() over(partition by a.guid ,  b.eventOrder  order by a.eventOrder, a.created  ) rn
	, a.guid
	, a.productType2
	from 

	#t2 a 
	join 	(select distinct eventOrder eventOrder,  productType2 from  #status) b on b.eventOrder <  a.eventOrder  and a.productType2=b.productType2
	left join 	 #t2 c on a.guid=c.guid and b.eventOrder=c.eventOrder
	where c.id is  null -- and a.isFake=0
	) a
	where rn=1

update a set a.eventName = b.eventName from #t2_ a join #status b on a.eventOrder=b.eventOrder and a.productType2=b.productType2 and a.eventName is null


;with v  as (select *, row_number() over(partition by guid, eventOrder  order by created, eventId  ) rn from #t2_ ) delete from v where rn>1 and eventOrder is not null

--select * from #t2_
--where eventOrder is null

--create index t on _request_event (id)


--drop table if exists _request_event 


--alter table _request_event add productType2 varchar(15)

if OBJECT_ID('_request_event') is null
 select eventName 
	,    eventId 
	,    eventOrder 
	,    ispts
	,  cast(  created  as datetime2(0)) created
	,    number 
	,    id 
	,    isFake
	,    isLkk
	, guid
	, productType2
	into _request_event  from #t2_ where 1=0

	if @full_upd = 0 begin

 --select  eventName 
	--,    eventId 
	--,    eventOrder 
	--,    ispts
	--,    created 
	--,    number 
	--,    id 
	--,    isFake
	--,    isLkk
	--into #t2__
	--from #t2_ except 

	--select eventName 
	--,    eventId 
	--,    eventOrder 
	--,    ispts
	--,    created 
	--,    number 
	--,    id 
	--,    isFake 
	--,    isLkk 
	--from _request_event 
delete a from  _request_event a join #t2_ on a.guid=#t2_.guid


insert into _request_event
select eventName 
	,    eventId 
	,    eventOrder 
	,    ispts
	,    created 
	,    number 
	,    id 
	,    isFake 
	,    isLkk 
	, guid
	, productType2

	from #t2_
	end
	if @full_upd = 1 begin
	truncate table _request_event
	insert into _request_event
	select eventName 
	,    eventId 
	,    eventOrder 
	,    ispts
	,    created 
	,    number 
	,    id 
	,    isFake 
	,    isLkk 
	,    guid
	,    productType2

	from #t2_ end


	 
  
	drop table if exists #t4

	--select * from stg._lk.events

	select aa.guid  guid 
	,  max(case when eventName like '%ЛКК%' then 'ЛКК,' else '' end) +
	 max(case when eventName like '%МП%' then 'МП,' else '' end) +   
	 max(case when a.id in ( 91, 69, 70, 92 ) then 'repeated,' else '' end) +   
	  string_agg( case when isFake=1 then '-' else '' end+ cast(eventOrder as nvarchar(100)   )   , ', ') within  group (order  by eventOrder,  a.created ) eventDesc  
	 , isnull(cast(max(eventOrder) as float),cast(max(case when aa.issued is not null then 999 else 0 end) as float)) eventLast									 
 
	, min(case when a.productType2='NO PLEDGE' and eventOrder=1 then a.created end)   _profile 
	, min(case when a.productType2='NO PLEDGE' and eventOrder=2 then a.created end)   _passport  
	, min(case when a.productType2='NO PLEDGE' and eventOrder=3 then a.created end)   _photos 
	, min(case when a.productType2='NO PLEDGE' and eventOrder=4 then a.created end)   _pack1 
	, min(case when a.productType2='NO PLEDGE' and eventOrder=4.5 and aa.call1 is not null         then a.created end)  _call1 -- [Call 1],
	, min(case when a.productType2='NO PLEDGE' and eventOrder=5 and aa.[call1Approved] is not null then a.created end)  _workAndIncome -- [О работе и доходе],
	, min(case when a.productType2='NO PLEDGE' and eventOrder=6 and aa.[call1Approved] is not null then a.created end)  _cardLinked -- [Добавление карты],
	, min(case when a.productType2='NO PLEDGE' and eventOrder=7 and aa.[call1Approved] is not null then a.created end)  _approvalWaiting -- [Одобрение],
	, min(case when a.productType2='NO PLEDGE' and eventOrder=8 and aa.[call1Approved] is not null and aa.approved is not null then a.created end)  _offerSelection -- [Выбор предложения],
	, min(case when a.productType2='NO PLEDGE' and eventOrder=9 and aa.[call1Approved] is not null and aa.approved is not null then a.created end)  _contractSigning -- [Подписание договора],
	 ,min(case when a.productType2='PTS' and eventOrder= 1	then a.created end)                                   _calculatorPts
	 ,min(case when a.productType2='PTS' and eventOrder= 2	then a.created end)        _profilePts
	 ,min(case when a.productType2='PTS' and eventOrder= 2.5	then a.created end)    _subQueryInfoPts
	 ,min(case when a.productType2='PTS' and ( call03approved is not null  or aa.created<'20250701')  and  eventOrder= 3	then a.created end)                                   _docPhotoPts
	 ,min(case when a.productType2='PTS' and ( call03approved is not null  or aa.created<'20250701')  and eventOrder= 4	    then a.created end) _docPhotoLoadedPts
	 ,min(case when a.productType2='PTS' and ( call03approved is not null  or aa.created<'20250701')  and eventOrder= 5	    then a.created end) _pack1Pts
	 ,min(case when a.productType2='PTS' and ( call03approved is not null  or aa.created<'20250701')  and  eventOrder= 6	then a.created end) _Pack1SignedPts
	 ,min(case when a.productType2='PTS' and eventOrder= 7	    and aa.call1Approved is not null   then a.created end)                                   _clientAndDocPhoto2Pts
	 ,min(case when a.productType2='PTS' and eventOrder= 8	    and aa.call1Approved is not null   then a.created end)                                   _additionalInfoPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 9	    and aa.call1Approved is not null   then a.created end)                                   _carDocPhotoPTS	
	 ,min(case when a.productType2='PTS' and eventOrder= 9.3	    and aa.call1Approved is not null   then a.created end)                               _incomeOfferSelectionPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 9.5	    and aa.call1Approved is not null   then a.created end)                               _proofOfIncomePTS
	 ,min(case when a.productType2='PTS' and eventOrder= 9.6	    and aa.call1Approved is not null   then a.created end)                               _proofOfIncomeLoadedPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 10	and aa.call1Approved is not null   then a.created end)                               _payMethodPts
	 ,min(case when a.productType2='PTS' and eventOrder= 11	and aa.checking is not null   then a.created end)                               _cardLinkedPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 12	and aa.clientApproved is not null   then a.created end)                               _CarPhotoPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 12.5	and aa.clientApproved is not null   then a.created end)                               _fullRequestPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 13 and aa.approved is not null	then a.created end)   _ApprovalPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 14 and aa.approved is not null	then a.created end)   _pack2PTS
	 ,min(case when a.productType2='PTS' and eventOrder= 14.5 and aa.approved is not null	then a.created end)   _pack2ProfileSignedPTS
	 ,min(case when a.productType2='PTS' and eventOrder= 15 and aa.approved is not null	then a.created end)   _pack2SignedPTS


	 ,min(case when a.productType2='BIG INST' and eventOrder= 1  	then a.created end)   _profileBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 1.3  	then a.created end)   _call03BI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 1.5  	then a.created end)   _call03approvedBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 2  	then a.created end)   _photoBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 3  	then a.created end)   _pack1BI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 3.5  	then a.created end)   _call1BI

	 ,min(case when a.productType2='BIG INST' and eventOrder= 4  	then a.created end)   _preApprovalWaitingBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 5  	then a.created end)   _incomeOfferSelectionBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 6  	then a.created end)   _proofOfIncomeBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 7  	then a.created end)   _proofOfIncomeLoadedBI


	 ,min(case when a.productType2='BIG INST' and eventOrder= 8  	then a.created end)   _calculatorBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 9  	then a.created end)   _payMetodBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 10  	then a.created end)   _timerBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 11  	then a.created end)   _timerOutBI
	 ,min(case when a.productType2='BIG INST' and eventOrder= 15  	then a.created end)   _pack2SignedBI




    , max(case when a.eventId in ( 3 ) then a.created  end)       _pack1resigning 
    , max(case when a.eventId in ( 19, 358 ) then a.created  end) _pack1resigned
    , max(case when a.eventId in ( 682 ) then a.created  end) _refinementProofOfIncome
    , max(case when a.eventId in ( 718 ) then a.created  end) paused
	 
	into #t4	  -- select *   
	from #requests_lk2 aa 
	left join #t2_   a on aa.guid=a.guid
	 	group by  aa.guid
 


	drop table if exists #eventLast
	select a.guid guid, min(b.created ) eventLastCreated, min(b.EventName ) Event  into #eventLast from #t4 a
	join #t2_ b on a.guid=b.guid and a.eventLast=b.eventOrder
	group by  a.guid



	 
drop table if exists #requestTriggerTmp

select a.requestId, a.step, a.field , a.event, a.result, a.comment,  a.created, a.isError, b.guid into #requestTriggerTmp from    v_request_field a 
--left join v_request r on a.id=r.lk_request_id
join #requests_lk2 b on a.requestId = b.id


--select top 100 * from requestTrigger


;with v  as (select *, row_number() over(partition by guid, isnull(cast( eventOrder aS FLOAT) , cast( -eventId aS FLOAT)) order by created, eventId  ) rn from #t2 where isFake=0  ) --delete from v where rn>1


--select top 100 * from #requestTriggerTmp
insert into #requestTriggerTmp 
select   id, format(eventOrder, '00') , N'' , eventName, 'Id='+  format(eventId, '0') , '', created, -1 , guid    from v where rn=1



insert into #requestTriggerTmp 
select   b.id, '' , N'' , event, '(MP)'  , '', a.created,  -2  , b.guid
--select *   
from Analytics.dbo.[appmetrica_action_stg] a
join #requests_lk2 b on a.phone=b.phone and a.created between b.created and isnull(isnull(isnull(b.cancelled, b.issued), b.declined), dateadd(day, 8, b.created  ))




--select * from #requestTriggerTmp
--where id=3431541
--order by created


create nonclustered index index_1 on #requestTriggerTmp
(
guid, created
)


drop table if exists #field 



select 
    a.guid guid,

    nullif(count(distinct case when rt.event = 'Загрузка фото' and rt.result = 'true' and rt.field like 'pts%' 
         and rt.created between a.[_carDocPhotoPTS] and isnull(a.[_payMethodPts], getdate()) then rt.field end), 0) [_carDocPhotoPTScntPts],

    nullif(count(distinct case when rt.event = 'Загрузка фото' and rt.result = 'true' and rt.field like 'sts%' 
         and rt.created between a.[_carDocPhotoPTS] and isnull(a.[_payMethodPts], getdate()) then rt.field end), 0) [_carDocPhotoPTScntSts],

    nullif(count(distinct case when rt.event = 'Уход из фокуса' and rt.result <> '' and rt.comment = '' and rt.field = 'Фамилия' 
         and rt.created between a._profilePts and isnull(a._docPhotoPts, getdate()) then rt.created end), 0) [_profilePTScntSurname],

    case when count(distinct case when rt.event = 'Уход из фокуса' and rt.result <> '' and rt.comment = '' 
         and rt.field in (
            'Фамилия','Имя','Отчество','Дата рождения',
            'Паспорт - Серия паспорта','Паспорт - Номер паспорта','Паспорт - Дата выдачи',
            'Паспорт - Код подразделения','Паспорт - Кем выдан',
            'Место рождения (как в паспорте)','Регион регистрации',
            'Суммарный доход в мес.','Платежи по кредитам в месяц'
         ) 
         and rt.created between a._profilePts and isnull(a._docPhotoPts, getdate()) then rt.field end) = 13 then 1 end [_profilePTSpersonal],

    case when count(distinct case when rt.event = 'Уход из фокуса' and rt.result <> '' and rt.comment = '' 
         and rt.field in ('Марка','Год выпуска','Модель') 
         and rt.created between a._profilePts and isnull(a._docPhotoPts, getdate()) then rt.field end) = 3 then 1 end [_profilePTScar],

    nullif(count(distinct case when rt.event = 'Уход из фокуса' and rt.result <> '' and rt.comment = '' and rt.field = 'Марка' 
         and rt.created between a._profilePts and isnull(a._docPhotoPts, getdate()) then rt.created end), 0) [_profilePTScntCarBrand],

    nullif(count(distinct case when rt.event = 'Загрузка фото' and rt.result = 'true' 
         and rt.created between a._docPhotoPts and isnull(a._docPhotoLoadedPts, getdate()) then rt.created end), 0) [_docPhotoPtsCnt],

    min(l.Event) Event,
    min(l.eventLastCreated) eventLastCreated,

    nullif(count(distinct case when rt.event = 'Переход на экран' and rt.field = 'step ' 
         and rt.created >= l.eventLastCreated then rt.created end), 0) [_lastEventRedirectCnt],

    nullif(count(distinct case when rt.event = 'Загрузка фото' and rt.result = 'true' 
         and rt.created between a._photos and isnull(a._pack1, getdate()) then rt.field end), 0) [_photosCnt],

    nullif(count(distinct case when rt.event = 'Открытие фото' 
         and rt.created between a._photos and isnull(a._pack1, getdate()) then rt.field end), 0) _photosOpenedCnt,

    case when count(distinct case when rt.event = 'Загрузка фото' and rt.result = 'true' 
         and rt.field in ('autdash','autlefr','autrifr','autlebc','autribc','autself') 
         and rt.created between a._carPhotoPTS and isnull(a._fullRequestPTS, getdate()) then rt.field end) = 6 then 1 end [_carPhotoPTScarClient],

    case when count(distinct case when rt.event = 'Загрузка фото' and rt.result = 'true' 
         and rt.field = 'autvin3' 
         and rt.created between a._carPhotoPTS and isnull(a._fullRequestPTS, getdate()) then rt.field end) = 1 then 1 end [_carPhotoPTSvin]

into #field

from #t4 a
left join #requestTriggerTmp rt on rt.isError >= 0 and a.guid = rt.guid
left join #eventLast l on l.guid = a.guid

group by a.guid

/*


select a.guid guid 
, nullif(count(distinct case when  b3.field like 'pts%' then b3.field  end )  ,  0) [_carDocPhotoPTScntPts] 
, nullif(count(distinct case when  b3.field like 'sts%' then b3.field  end )  ,  0) [_carDocPhotoPTScntSts] 
, nullif(count(distinct  b4.created    )  ,  0)    [_profilePTScntSurname] 
, case when  count(distinct b4personal. field)=13 then 1 end   [_profilePTSpersonal] 
, case when  count(distinct b4car. field)=3 then 1 end         [_profilePTScar] 

, nullif(count(distinct  b5.created    )  ,  0)    [_profilePTScntCarBrand] 
, nullif(count(distinct  b6.created    )  ,  0)    [_docPhotoPtsCnt] 

, min(l.Event  ) Event   
,  min(l.eventLastCreated) eventLastCreated
, nullif(count(distinct  tr.created   )  ,  0)    [_lastEventRedirectCnt] 
,   nullif(count(distinct  b7.field    )  ,  0)    [_photosCnt] 

,   nullif(count(distinct  b8.field    )  ,  0)    _photosOpenedCnt 
 
, case when  count(distinct b9all. field)=6 then 1 end   [_carPhotoPTScarClient] 
, case when  count(distinct b9vin. field)=1 then 1 end   [_carPhotoPTSvin] 

 
into #field

from #t4  a
 left join #requestTriggerTmp b3 on b3.isError>=0 and  a.guid=b3.guid and b3.created between   a.[_carDocPhotoPTS]        and  isnull(a.[_payMethodPts]      ,gETDATE())and b3.result='true' and  b3.event='Загрузка фото' --and 
left join #requestTriggerTmp b4 on  b4.isError>=0 and   a.guid=b4.guid and b4.created between   a._profilePts        and  isnull(a._docPhotoPts      ,gETDATE())and b4.result<>'' and  b4.event='Уход из фокуса' and b4.comment = '' and b4.field = 'Фамилия'  --and 
left join #requestTriggerTmp b4personal on  b4personal.isError>=0 and   a.guid=b4personal.guid and b4personal.created between   a._profilePts        and  isnull(a._docPhotoPts      ,gETDATE())and b4personal.result<>'' and  b4personal.event='Уход из фокуса' and b4personal.comment = '' and b4personal.field in
( 'Фамилия'
, 'Имя'
, 'Отчество'
, 'Дата рождения'
, 'Паспорт - Серия паспорта'
, 'Паспорт - Номер паспорта'
, 'Паспорт - Дата выдачи'
, 'Паспорт - Код подразделения'
, 'Паспорт - Кем выдан'
, 'Место рождения (как в паспорте)'
, 'Регион регистрации'
, 'Суммарный доход в мес.'
, 'Платежи по кредитам в месяц'
)  --and 
left join #requestTriggerTmp b4car on  b4car.isError>=0 and   a.guid=b4car.guid and b4car.created between   a._profilePts        and  isnull(a._docPhotoPts      ,gETDATE())and b4car.result<>'' and  b4car.event='Уход из фокуса' and b4car.comment = '' and b4car.field in
( 'Марка'
, 'Год выпуска'
, 'Модель' 
)  --and 
 

left join #requestTriggerTmp b5 on  b5.isError>=0 and a.guid=b5.guid and b5.created between   a._profilePts        and  isnull(a._docPhotoPts      ,gETDATE())and b5.result<>'' and  b5.event='Уход из фокуса' and b5.comment = '' and b5.field = 'Марка'    --and 
left join #requestTriggerTmp b6 on  b6.isError>=0 and a.guid=b6.guid and b6.created between   a._docPhotoPts        and  isnull(a._docPhotoLoadedPts      ,gETDATE()) and b6.result='true' and  b6.event='Загрузка фото' --and 
left join #eventLast   l on l.guid = a.guid
left join #requestTriggerTmp tr on tr.isError>=0 and  a.guid=tr.guid and tr.created >=   l.eventLastCreated  and tr.event='Переход на экран' and tr.field='step '

 left join #requestTriggerTmp b7 on b7.isError>=0 and  a.guid=b7.guid and b7.created between   a._photos        and  isnull(a._pack1      ,gETDATE())and b7.result='true' and  b7.event='Загрузка фото' --and 
 left join #requestTriggerTmp b8 on b7.isError>=0 and  a.guid=b8.guid and b8.created between   a._photos        and  isnull(a._pack1      ,gETDATE()) and  b8.event='Открытие фото' --and 
 left join #requestTriggerTmp b9all on  b9all.isError>=0 and   a.guid=b9all.guid and b9all.created between   a._carPhotoPTS        and  isnull(a._fullRequestPTS      ,gETDATE())and b9all.result='true' and  b9all.event='Загрузка фото' and  b9all.field in
( 'autdash'
, 'autlefr'
, 'autrifr'
, 'autlebc'
, 'autribc'
, 'autself'


)  --and 

 left join #requestTriggerTmp b9vin on  b9vin.isError>=0 and   a.guid=b9vin.guid and b9vin.created between   a._carPhotoPTS        and  isnull(a._fullRequestPTS      ,gETDATE())and b9vin.result='true' and  b9vin.event='Загрузка фото' and  b9vin.field in
( 'autvin3'


)  --and 


   group by  a.guid

   */
   ;

 --     with a as (
 --  select a.id, nullif(count(distinct  b.field    )  ,  0)    _photosOpenedCnt   from _request a join v_request_field b on a.id=b.request_id and b.created between   a._photos       
 --  and  isnull(a._pack1      ,gETDATE())  and  b.event='Открытие фото' 
 --  group by a.id
 --  ) 
 --update request set   request._photosOpenedCnt = b._photosOpenedCnt  from _request request join a b  on request.id=b.id 




 --  with a as (
 --  select a.id, nullif(count(distinct  b.field    )  ,  0)    [_photosCnt]   from _request a join v_request_field b on a.id=b.request_id and b.created between   a._photos       
 --  and  isnull(a._pack1      ,gETDATE())and b.result='true' and  b.event='Загрузка фото' 
 --  group by a.id
 --  ) 
 --update request set   request._photosCnt = b._photosCnt  from _request request join a b  on request.id=b.id 



 --  select * from #field
 --  where _photosCnt is not null


 drop table if exists #eventLastTriggerDesc


 
;with v  as (select *,  datediff(minute, created,  lead(created) over(partition by guid    order by created ,iserror, step, field, event,  result ) ) dif from #requestTriggerTmp  ) --delete from v where rn>1
, requestTriggerCte as ( select *, case 
     when dif >=2*60*24 then N'
📅📅'  when dif >=60*24 then N'
📅' when   dif >=60*12  then N'
🌓' when   dif >=60  then N'
⌛'when   dif >=5  then N'
⏱'  when event = 'Заем выдан' then N'💲' when dif is null then  N'👋' else '' end addText from v )
--select * from v_

   select a.guid
   
    , STRING_AGG('$ '+  format( tr.created, 'dd HH:mm:ss') + case when   tr.created=a.eventLastCreated then N' 💔' else ' ' end  +case when tr.isError=1 then N'🚨' when tr.isError=-1 then N'📥' else '' end+case when tr.field<>'step' then ' '+ cast( tr.field  as nvarchar(max)) else '' end  +' '+ tr.event 
 + case 
 when tr.field='step' then cast( ' '+tr.step as nvarchar(max)) else '' end
 
 + ' ' + isnull(tr.result, '') + case when tr.comment<>'' then ' ('+tr.comment+')' else '' end +case when tr.addText<> '' then addText else '' end , '
' ) within group(order by tr.created, iserror, step, field, tr. event,  result,  addText) [eventLastTriggerDesc] 
into #eventLastTriggerDesc
from #field a
left join  requestTriggerCte tr on a.guid=tr.guid  and  (tr.created >=   a.eventLastCreated   or tr.isError=-1)
--select * from v_request_field
   group by  a.guid

   --select * from #eventLastTriggerDesc a
   --where [eventLastTriggerDesc]  like '%' + '(MP)' + '%'

   --select * from #t2 where id=3431541
   --order by created

   --select * from #t2_ where id=3431541
   --order by created

   --select * from v_request_lk_event where requestid=3431541
   --order by created


/*
 --order by 2
 drop table if exists #eventLastTriggerDesc
--select id,  dbo.RemoveDuplicateLines(a.[eventLastTriggerDesc]) [eventLastTriggerDesc] into #eventLastTriggerDesc from #field  a
;
WITH SplitData AS (
    -- Разбиваем данные на строки
    SELECT 
        a.id,
        value = LTRIM(RTRIM(REPLACE(REPLACE(v.value, CHAR(13), ''), CHAR(9), ''))), -- Чистим строки от пробелов, табуляций и возвратов каретки
        row_num = ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY (SELECT NULL)) -- Порядок строк внутри группы ID
    FROM #field a
    CROSS APPLY STRING_SPLIT(a.[eventLastTriggerDesc], CHAR(10)) v -- Разбиваем строки на элементы
    WHERE LTRIM(RTRIM(v.value)) LIKE '$%' -- Оставляем только строки, начинающиеся с $
),
UniqueData AS (
    -- Убираем дубли и сохраняем порядок
    SELECT 
        id,
        value,
        MIN(row_num) AS min_row_num -- Сохраняем порядок первой уникальной строки
    FROM SplitData
    GROUP BY id, value -- Группируем по ID и значению
)
-- Собираем строки обратно в один текст с учетом порядка
SELECT 
    id,
    STRING_AGG(value, CHAR(10)) WITHIN GROUP (ORDER BY min_row_num) AS [eventLastTriggerDesc]
INTO #eventLastTriggerDesc -- Сохраняем результат в новую временную таблицу
FROM UniqueData
GROUP BY id;
*/

-- select * from #field
  --select lEN([eventLastTriggerDesc]) from #eventLastTriggerDesc

 --select * from v_request_field
 --where result<>'' and  event='Уход из фокуса' and field = 'Фамилия'


 --select * from #field
-- select a.*, b3.* from _request a 
--left join v_request_field b3 on a.id=b3.request_id and b3.created between   a._profilePts        and  isnull(a._docPhotoPts      ,gETDATE())--and b3.result='true' and  b3.event='Загрузка фото' --and 
--where a._profilePts is not null and a.created >= getdate() - 1 --and a.number='24100802573599'
--order by a.created desc, b3.created


	--drop  index index_1 on #loans

	create nonclustered index index_1 on #loans
	(
	 clientid, issued, closedIsnullNow, ispts
	)

  
	drop table if exists 	  #inst_an3

	select a.guid, a.number   
	, CONVERT( varchar(20), b.issued , 120) +cast(case when b.ispts=1 then 1 when   b.ispts=0 and b.ispdl=0 then 2 when b.ispdl=1 then 3 else 1 end as nvarchar(1)) 
	[issued&product]
	, a.call1IsNullCreated  
	, b.closedIsnullNow
	, a.ispts
	, b.ispts loan_ispts
	, b.loanNumber
	, a.returnType3 returnType3
	, b.clientid
	, b.issued loanIssued
	, b.rbp rbpLoan
	, b.closed
	, b.interestRate
	 into #inst_an3
	from #requests_lk2 a 
	 left join  #loans b on a.clientid=b.clientid and b.issued<=a.call1IsNullCreated 
	 and isnull( try_cast( a.number as bigint) , '-1') <>isnull(try_cast(  b.loanNumber  as bigint)  , '-2')
	 and isnull( a.number                      , '-1') <>isnull(  b.loanNumber   					 , '-2')
	 and isnull( a.loanNumber                  , '-1') <>isnull(b.loanNumber						 , '-2')
	 

; 

drop table if exists #firstLoan
;with v  as (select *, row_number() over(partition by   guid order by loanIssued) rn from #inst_an3 where loanIssued is not null  ) select * into #firstLoan  from v where rn=1


drop table if exists #lastCLosedLoan
;with v  as (select *, row_number() over(partition by   guid order by closed desc, loanIssued desc) rn from #inst_an3 where loanIssued is not null and
closed is not null ) select * into #lastCLosedLoan  from v where rn=1


drop table if exists #lastLoan
;with v  as (select *, row_number() over(partition by   guid order by loanIssued desc) rn from #inst_an3 where loanIssued is not null  ) select * into #lastLoan  from v where rn=1


----select * from #firstLoan
--update a set a.firstLoanRbp = b.rbpLoan, a.firstLoanNumber = b.loanNumber from _request a join #firstLoan  b on b.id=a.id

	 --select * from #inst_an3 where number='01609053120002'
	 --select * from #inst_an3
	 --select * from #inst_an2
 


 if @full_upd =1
 begin
 drop table if exists   _request_log_inst_an3
 select * into _request_log_inst_an3 from #inst_an3
 end


 create clustered index t on #inst_an3 (guid)


	drop table if exists 	  #inst_an2
	  select   
	  b.guid guid, 
	  max(b.number) number,   
	  case 
	  when  count( case when b.loan_ispts=b.ispts and b.closedIsnullNow>=b.call1IsNullCreated then b.loanNumber end ) >0  then 'Докредитование'
	  when  count( case when b.loan_ispts=b.ispts and b.closedIsnullNow<=b.call1IsNullCreated then b.loanNumber end )>0 then 'Повторный'
	  else 'Первичный' end   returnTypeByProduct
  
	 , loyalty        = isnull( count(distinct case when  b.closedIsnullNow<=b.call1IsNullCreated then b.loanNumber end ),0)+1
	 , loyaltyPts        = isnull( count(distinct case when 1=b.loan_ispts and b.closedIsnullNow<=b.call1IsNullCreated then b.loanNumber end ),0)+1
	 , loyaltyBezzalog        = isnull( count(distinct case when 0=b.loan_ispts and b.closedIsnullNow<=b.call1IsNullCreated then b.loanNumber end ),0)+1
	 , firstLoanProductType = case right( min( b.[issued&product]) , 1) when 3 then 'pdl' when 1  then  'pts' when  2 then  'inst' end
	 , firstLoanIssued =   min( b.loanIssued)

	 , isnull( max( b.returnType3) ,
	  case 
	 when   count( case when  b.closedIsnullNow>=b.call1IsNullCreated then b.number end ) >0  then 'Докредитование'
	  when  count( case when  b.closedIsnullNow<=b.call1IsNullCreated then b.number end )>0 then 'Повторный'
	  else 'Первичный' end   )  returnType
  
	  , max( b.clientId) clientId
	  , loanOrder = isnull( count(distinct  b.loanNumber   ) , 0)+1
 

	  into #inst_an2 	 --select top 100 *
  
	  from #inst_an3 b  
   
	 group by b.guid    

	 
 



	 drop table if exists #next_loans
	 drop table if exists #costs
	 select number  number, marketingCost   marketingCosts into #costs  from  v_request_cost

	  
	drop table if exists #t5
	select 
	 a.guid                                 
	,a.id                                 
	,      cast(a.created                          as date)	date
	,      a.created    
	,      a.needBki        
	,      a.call03
	,      a.call03approved
	,      a.call1                       
	,      a.call1Approved	    
	,      a.checking			    
	,      a.call2			    
	,      a.call2Approved			    
	,      a.clientVerification                     
	,      a.clientApproved                     
	,      a.carVerificarion                     
	,      a.approved						    
	,      a.ContractSigned 			    
	,      a.issued				    
	,      a.firstSum        	        
	,      a.requestSum        	        
 	        
	,      a.approvedSum
	,      a.issuedSum				    
	,      a.term					    
	,      a.closed					    
	,      a.declined						    
	,      a.cancelled					    
	,      a.rejected					    
	,      a.status_crm
	,      a.number                               
	,      a.isInst                  
	,      a.isPts                     
	,      a.prolongationCnt                     
	,      a.prolongationFirstDate                     
	,      a.productType            
	, a.[productSubType]
	,      a.[productTypeInitial]                     
	,      a.monthlyIncome                     
	--,      a.isAutomaticApprove                     
	,      a.closedPlanDate                             
	,      a.termDays
	,      a.freeTermDays 
	,      a.origin                     
	--,      a.[Наличие зеленого предложения]                                          
	,      a.phone
	,     isnull(  b._profile , case when a.origin = 'ЛККлиента' and a.ispts=0 then a.created end)	 _profile --на ЛКК этот шаг обычно уже пройден
	,     b._passport
	,     b._photos 
	,     b._pack1
	,     b._call1
	,     b._workAndIncome
	,     b._cardLinked
	,     b._approvalWaiting
	,     b._offerSelection
	,     b._contractSigning
	,   isnull( cast(  b.eventLast as float), 	case when a.issued is not null then 999.0 when a.call1 is not null then 0.7  when a.number is not null then 0.5 else 0.0 end)  	eventLast
	,     b.eventDesc 
 
	, b._calculatorPts
	, b._profilePts
	, b._subQueryInfoPts
	, b._docPhotoPts
	, b._docPhotoLoadedPts
	, b._pack1Pts
	, b._pack1SignedPts _pack1SignedPts
	, b._clientAndDocPhoto2Pts _clientAndDocPhoto2Pts
	, b._additionalInfoPTS  _additionalInfoPTS 
	, b._carDocPhotoPTS
	, b._incomeOfferSelectionPTS
	,b._proofOfIncomePTS
	, b._proofOfIncomeLoadedPTS
	, b._payMethodPts
	, b._cardLinkedPTS
	, b._carPhotoPTS _carPhotoPTS
	, b._fullRequestPTS _fullRequestPTS
	, b._ApprovalPTS 
	, b._pack2PTS
	, b._pack2ProfileSignedPTS
	, b._pack2SignedPTS



	,  _profileBI
	,  _photoBI
	,   _call03BI         
	,  _call03approvedBI 
	,  _pack1BI
	,  _preApprovalWaitingBI
	,  _incomeOfferSelectionBI
	,  _proofOfIncomeBI
	,  _proofOfIncomeLoadedBI

	, b. _calculatorBI
	, b. _payMetodBI
	, b. _timerBI
	, b. _timerOutBI
	, b. _pack2SignedBI




	,     c.returnType  
	--,  	  case when a.approved is not null then case when d.number is not null then 1 else 0 end end	 isTakeUpManual
	,     e.marketingCosts marketingCosts
	 , c.loanOrder       
	 , c.loyalty       
	 , c.loyaltyPts
	 , c.loyaltyBezzalog
	  , c. firstLoanIssued
	  , c. firstLoanProductType
	  , c.returnTypeByProduct 
	  , a.interestRate
	  , a.interestRateRecommended
	  , a.isDubl
	  , isnull( c.clientId, a.clientId) clientId
	  , CASE
			WHEN a.productType2 = 'PTS' THEN
				CASE
					WHEN issued IS NOT NULL THEN 'Выдача денег'
					WHEN _pack2SignedPTS IS NOT NULL THEN 'Подписал второй пакет ПТС'
					WHEN _pack2ProfileSignedPTS IS NOT NULL THEN 'Подписал второй пакет (анкета) ПТС'
 
					WHEN _pack2PTS IS NOT NULL THEN 'Переход на второй пакет ПТС'
					WHEN _ApprovalPTS IS NOT NULL THEN 'Финально одобрен ПТС'
					WHEN _fullRequestPTS IS NOT NULL THEN 'Отправлена полная заявка ПТС'
					WHEN _CarPhotoPTS IS NOT NULL THEN 'Перешел на фото авто ПТС'
					WHEN _cardLinkedPTS IS NOT NULL THEN 'Карта привязана ПТС'
					WHEN _payMethodPts IS NOT NULL THEN 'Переход на экран Способ выдачи ПТС'
					 
					WHEN _proofOfIncomeLoadedPTS IS NOT NULL THEN 'Загрузил документ подтверждающий доход'

					WHEN _proofOfIncomePTS IS NOT NULL THEN 'Переход на экран подтверждение дохода ПТС'
					WHEN _incomeOfferSelectionPTS IS NOT NULL THEN 'Переход на экран выбор оффера (доход) ПТС'					 
					WHEN _carDocPhotoPTS IS NOT NULL THEN 'Переход на экран с фото документов авто ПТС'
					WHEN _additionalInfoPTS IS NOT NULL THEN 'Переход на экран с дополнительной информацией ПТС'
					WHEN _clientAndDocPhoto2Pts IS NOT NULL THEN 'Переход на экран Фото паспорта ПТС'
					WHEN _Pack1SignedPts IS NOT NULL THEN 'Подписал 1 пакет ПТС'
					WHEN _pack1Pts IS NOT NULL THEN 'Переход на 1 пакет ПТС'
					WHEN _docPhotoLoadedPts IS NOT NULL THEN 'Загрузил 2-3 стр паспорта ПТС'
					WHEN _docPhotoPts IS NOT NULL THEN 'Открытие слота 2-3 стр паспорта ПТС'
					WHEN _subQueryInfoPts IS NOT NULL THEN 'Дозапрос данных до Call1'
 					WHEN _profilePts IS NOT NULL THEN 'Переход на Анкету ПТС'
					WHEN _calculatorPts IS NOT NULL THEN 'Переход на калькулятор ПТС'
					ELSE NULL
				END
			when a.producttype2='NO PLEDGE' then
				CASE
					WHEN issued IS NOT NULL THEN 'Выдача денег'
					WHEN _contractSigning IS NOT NULL THEN 'Подписание договора'
					WHEN _offerSelection IS NOT NULL THEN 'Выбор предложения'
					WHEN _approvalWaiting IS NOT NULL THEN 'Одобрение'
					WHEN _cardLinked IS NOT NULL THEN 'Добавление карты'
					WHEN _workAndIncome IS NOT NULL THEN 'О работе и доходе'
					WHEN _call1 IS NOT NULL THEN 'Call1'
					WHEN _pack1 IS NOT NULL THEN 'Подписание первого пакета'
					WHEN _photos IS NOT NULL THEN 'Фотографии'
					WHEN _passport IS NOT NULL THEN 'Паспорт'
					WHEN _profile IS NOT NULL THEN 'Анкета'
					ELSE NULL
				END

			when a.producttype2='BIG INST' then
				CASE
					WHEN issued IS NOT NULL THEN 'Выдача денег'
					WHEN _pack2SignedBI IS NOT NULL THEN 'Подписал второй пакет БИ'
					WHEN _timerOutBI IS NOT NULL THEN 'Вышел с экрана с таймером БИ'
					WHEN _timerBI IS NOT NULL THEN 'Перешел на экран с таймером БИ'
					WHEN _payMetodBI IS NOT NULL THEN 'Перешел на способ выдачи БИ'
					WHEN _calculatorBI IS NOT NULL THEN 'Перешел на калькулятор БИ'
					WHEN _proofOfIncomeLoadedBI IS NOT NULL THEN   'Документ подтверждающий доход загружен БИ'
					WHEN _proofOfIncomeBI IS NOT NULL THEN  'Переход на экран с подтверждением дохожа БИ' 
					WHEN _incomeOfferSelectionBI IS NOT NULL THEN  'Переход на экран выбор оффера БИ'
					WHEN _preApprovalWaitingBI IS NOT NULL THEN   'Переход на ожидание предварительного одобрения БИ' 
					WHEN _call1BI IS NOT NULL THEN  'Call1 БИ'
					WHEN _pack1BI IS NOT NULL THEN  'Переход на 1 пакет БИ'
					WHEN _photoBI IS NOT NULL THEN  'Переход на фото паспорта БИ'
					WHEN _call03approvedBI IS NOT NULL THEN 'Call03 одобрено БИ'
					WHEN _call03BI IS NOT NULL THEN 'Call03 БИ'
					WHEN _profileBI IS NOT NULL THEN 'Переход на анкету БИ'

 		 
					ELSE NULL
				END



		END AS event   ,
		fioBirthday ,
 		a.carBrand , 
		a.carModel , 
		a.carYear, 
		a.VIN , 
		a.parentGuid

		, b. _pack1resigning 
		, b. _pack1resigned
		, b._refinementProofOfIncome
		, a.code  
		, a.declineReason  
		, a.link  
		, a.region  
		, a.pskRate  
		, a.productNameCrm 
		, a.loanNumber loanNumber
		, b.paused
	into #T5
	from      #requests_lk a
	left join #t4          b on a.guid = b.guid
	left join #inst_an2     c on a.guid = c.guid
	--left join #odobr d on d.number=a.number
	left join (select number number2, marketingCosts from  #costs ) e on a.number=e.number2

	--left join #next_loans2 nl on nl.Номер=a.number
 

 --select top 0 link into #t1 from v_request 
 --select top 0 max(len( code ))  into #t3 from v_request_lk
 --select   max(len( code ))   from v_request_lk


	drop table if exists #next_request

	select a.guid,  x.number next_request_product , x.call1 next_request_product_dt
	, x1.number next_request_other_product_after_annul
	, x1.call1 next_request_other_product_after_annul_dt
	into #next_request from #T5 a
	outer apply (select top 1 number, call1 from   #T5 b where a.clientId=b.clientId and a.ispts=b.ispts and b.call1>a.closed order by b.call1 )  x
	outer apply (select top 1 number, call1 from   #T5 b where a.clientId=b.clientId and a.ispts<>b.ispts and b.call1>a.cancelled order by b.call1 )  x1




	 
	drop table if exists #loan_overdue

	select 
	          lo.fpd0   fpd0
	        , lo.fpd4	fpd4
	        , lo.fpd7	fpd7
	        , lo.fpd10	fpd10
	        , lo.fpd15	fpd15
	        , lo.fpd30	fpd30
	        , lo.fpd60	fpd60
	        , lo.statusContract loanStatus
	        , number loanNumber
	
	into #loan_overdue 
	from v_loan_overdue lo



	drop table if exists #os 

	  SELECT request_id id, case 
	  when [service_info] like 'android%' then 'Android'
	  when [service_info] like 'ios%' then 'iOS'
	  end  os
		 into #os
	  FROM [Stg].[_LK].[request_mp]
	  where service_info is not null




	drop table if exists #t6

		   select   
		   a.guid
	,      a.number 
	,      a.origin 
	,      a.productTypeInitial
	,      a.productType
	, a.[productSubType]
	--,      a.isDubl  
	,      a.status_crm
	,      a.created 
	,      a.phone 
	,      a.declined    
	,      a.cancelled    
	,      a.rejected    
	,      a.returnType
	,      a.needBki        
	,     coalesce(  a.call03            , case when a.created <='20250701' then  a._docPhotoPts   end   , a.call1        ) call03  
	,     coalesce(  a.call03approved	 ,  case when a.created <='20250701' then  a._docPhotoPts   end  	, a.call1	)  call03approved
	,      a.call1    
	,      a.call1approved    
	,      a.checking    
	,      r.call15
	,      r.call15approved 

	,      a.call2    
	,      a.call2Approved    
	,      a.clientVerification 
	,      r.call3
	,      r.call3approved
	,      a.clientApproved    
	,      a.carVerificarion  
	,      r.call4
	,      r.call4approved 
	,      r.call5
	,      r.call5approved 



	,      a.approved    
	,      a.contractSigned    
	,      a.issued 					  	   
	,      a.closed
	,   cast(   a.firstSum     as float) 	 [firstSum]
	,   cast(   a.requestSum    as float) 	 [requestSum]
	,   cast(   a.approvedSum   as float) 	 [approvedSum]
	,   cast(   a.issuedSum 	   as float) [issuedSum]
	,      a.interestRate
	,      a.interestRateRecommended
	, r.firstSchedulePay

	,      a.isPts
	,      a.isInst 
	,      a.term
	,      a.termDays
	,      a.freeTermDays
	,     a.marketingCosts  
	,      a.prolongationCnt 
	,      a.prolongationFirstDate 
	,      a.monthlyIncome 
	 ,      a.closedPlanDate 



	--, isnull( f.event, '$'+ a.event) event
	,    a.event event
	, eventLastCreated eventLastCreated
	,      a.eventLast
	,      a.eventDesc  
	,      a._profile
	,      a._passport
	,      a._photos
	,      a._pack1 
	,      a._call1
	,      a._workAndIncome 
	,      a._cardLinked 
	,      a._approvalWaiting
	,      a._offerSelection
	,      a._contractSigning 
	, a._calculatorPts
	, a._profilePts	
	, a._subQueryInfoPts
	, a._docPhotoPts	
	, a._docPhotoLoadedPts	
	, a._pack1Pts	
	, a._pack1SignedPts	  
	, a._clientAndDocPhoto2Pts	
	, a._additionalInfoPTS	
	, a._carDocPhotoPTS	
	, a._incomeOfferSelectionPTS
	, a._proofOfIncomePTS
, a._proofOfIncomeLoadedPTS
	, a._payMethodPts	
	, a._cardLinkedPTS	
	, a._carPhotoPTS	  
	, a._fullRequestPTS	
	, a._approvalPTS  	
	, a._pack2PTS	
	, a._pack2ProfileSignedPTS
	, a._pack2SignedPTS	 



    , a. _profileBI

	 , a._call03BI
	 , a._call03approvedBI
	, a. _photoBI
	, a. _pack1BI
	, a. _preApprovalWaitingBI
	, a. _incomeOfferSelectionBI
	, a. _proofOfIncomeBI
	, a. _proofOfIncomeLoadedBI
	, a. _calculatorBI
	, a. _payMetodBI
	, a. _timerBI
	, a. _timerOutBI
	, a. _pack2SignedBI



	--,     isTakeUpManual
	, uprid._uprid
	, uprid._upridYes
	, uprid._2750 _2750
	, uprid._2751  _2751

	, next_request_product_dt closedRequestByProduct 
	, case when next_request_product_dt <=dateadd(day, 90, a.closed) then 1 else 0 end closedHasRequestByProduct90d
	, next_request_other_product_after_annul  RequestAfterCancelled 
	, next_request_other_product_after_annul_dt  RequestAfterCancelledDt 
		 ,   loanOrder   
		 ,   loyalty   
		 ,   loyaltyPts  
		 ,   loyaltyBezzalog    
	 ,   firstLoanIssued
	 ,   firstLoanProductType
--	 , case when a.closed is not null then  isnull(dpd_closed.closedDpdBeginDay , 0) end closedDpdBeginDay
--	 ,    isnull(dpd_closed.DpdBeginDay, 0)   DpdBeginDay
--	 ,    isnull(dpd_closed.DpdMaxBeginDay, 0)   DpdMaxBeginDay
	,      a.returnTypeByProduct
	 , a. clientId
--, r.feodorId
	,     a.[id] 
--	, '' 
--	--case 
--	--when b.user_agent like 'ios%' then 'ios' 
--	--when b.user_agent like 'Android%' then 'android' 
--	-- when ub.browser_name is not null then  ub.browser_name
--	--end 
--	browser
--	,   -- CASE 
--		--	WHEN b.[user_Agent] LIKE 'Android%' 
--		--		 AND CHARINDEX(',', b.[user_Agent]) > CHARINDEX('Android', b.[user_Agent]) + LEN('Android')
--		--	THEN LTRIM(SUBSTRING(
--		--		b.[user_Agent], 
--		--		CHARINDEX('Android', b.[user_Agent]) + LEN('Android'), 
--		--		CHARINDEX(',', b.[user_Agent]) - CHARINDEX('Android', b.[user_Agent]) - LEN('Android')
--		--	))
--		--	WHEN b.[user_Agent] LIKE 'IOS%' 
--		--		 AND CHARINDEX(',', b.[user_Agent]) > CHARINDEX('IOS', b.[user_Agent]) + LEN('IOS')
--		--	THEN LTRIM(SUBSTRING(
--		--		b.[user_Agent], 
--		--		CHARINDEX('IOS', b.[user_Agent]) + LEN('IOS'), 
--		--		CHARINDEX(',', b.[user_Agent]) - CHARINDEX('IOS', b.[user_Agent]) - LEN('IOS')
--		--	))
--		--	ELSE ub.browser_version
--		--END AS 
--		
--		'' browserVersion
, f._carDocPhotoPTScntPts
, f._carDocPhotoPTScntSts


, f.[_profilePTSpersonal] 
, f.[_profilePTScar] 
, f. [_carPhotoPTScarClient] 
, f. [_carPhotoPTSvin] 


, f. [_profilePTScntSurname] 
, f. [_profilePTScntCarBrand] 
, a.fioBirthday
,r.fio
, r.lastName
, r.firstName
, r.patronymic

, f.[_docPhotoPtsCnt]
, f._photosOpenedCnt
, f.[_photosCnt]
, f.[_lastEventRedirectCnt]
, r.passportSerialNumber
,	a.carBrand , 
		a.carModel , 
		a.carYear, 
		a.VIN, 
		a.parentGuid, 
 try_cast(left( isnull(try_cast( a.number as nvarchar(4000) ), 'guid='+ try_cast(a.guid as nvarchar(4000) ))+' '+isnull('('+ try_cast(a.productType +'-'+ a.origin as nvarchar(4000) ) +')', '(Null)') +'
'+ isnull(replace( f1.[eventLastTriggerDesc], 'https' , '') , ''), 4000) as nvarchar(4000))+case when a.code  is not null then N'

https://metrika.yandex.ru/stat/visor?&filter=%28ym%3Apv%3AURL%3D%40%2527%2F'+a.code+'%2527%29&id=35789815' else '' end  [eventLastTriggerDesc] 

,_pack1resigning 
, _pack1resigned
, _refinementProofOfIncome
, fl.rbpLoan firstLoanRbp
, fl.loanNumber firstLoanNumber
, lcl.loanNumber lastClosedLoanNumber
, lcl.interestRate lastClosedInterestRate
, lcl.loanIssued lastClosedIssued
, lcl.closed lastClosed
, ll.loanNumber  lastLoanNumber
, ll.interestRate  lastInterestRate
, ll.loanIssued  lastIssued
, a.declineReason
, a.code
, a.link
, gmt.region
, r.regionRegistration
,a.pskRate
,a.productNameCrm
,a.loanNumber
, r.carRegNumber
, r.age
, r.carPrice
 ,lo. [fpd0]       
 ,lo. [fpd4]       
 ,lo. [fpd7]       
 ,lo. [fpd10]      
 ,lo. [fpd15]      
 ,lo. [fpd30]      
 , lo.fpd60
 ,lo. [loanStatus] 
 
, r.employmentType
, r.employmentPlace
, r.employmentPosition
, r.isTakePts

, r.workplaceVerifiedIncome
, r.rosstatIncome
, r.bkiIncome
, r.bkiExpense
, r.firstLimitChoice       
, r.secondLimitChoice      
, r.finalLimitChoice       
, r.email
, r.addProductSumNet 
, a.paused
, r.payMethod
, r.paySbpBank
, os.os


		  into #t6
		  from #T5	a
		  left join #request_event_feodor uprid on uprid.guid=a.guid
		  left join #next_request next_request on next_request.guid=a.guid
		--	left join stg._lk.[request_pep] b on a.id=b.request_id
		--	left join userAgent_browser ub on ub.useragent=b.user_agent
			left join #field f  on f.guid=a.guid
			left join #eventLastTriggerDesc f1  on f1.guid=a.guid
	left join #firstLoan     fl on a.guid = fl.guid
	left join #lastCLosedLoan     lcl on a.guid = lcl.guid
	left join #lastLoan     ll on a.guid = ll.guid
	left join v_gmt gmt on gmt.region=a.region
	left join #requests_lk r on r.guid=a.guid
	left join #loan_overdue lo on lo.loanNumber=a.loanNumber
	left join #os os on os.id=a.id


--select top 0 workplaceVerifiedIncome
--, rosstatIncome
--, bkiIncome
--, bkiExpense
--, firstLimitChoice       
--, secondLimitChoice      
--, finalLimitChoice     into #which_column_type   
--from stg._fedor.core_ClientRequest

			--select * from #t6

--some magic
--update a set a._calculatorPts = call1 , a. _profilePts = call1 from #t6 a where ispts=1 and call1 is not null and _calculatorPts is null and _profilePts is null 
 


 

	  ;with v  as (select *, row_number() over(partition by guid order by id desc) rn from #t6   ) delete from v where rn>1

  
	drop table if exists #t7_changed
	select * into #t7_changed from #t6 where 1=0
  






--select * from #t7


 
  --alter table Analytics.dbo._request alter column firstSum    float
  --alter table Analytics.dbo._request alter column approvedSum float
  --alter table Analytics.dbo._request alter column issuedSum   float
  --alter table Analytics.dbo._request alter column requestSum   float
 
  --alter table Analytics.dbo._request_log alter column firstSum    float
  --alter table Analytics.dbo._request_log alter column approvedSum float
  --alter table Analytics.dbo._request_log alter column issuedSum   float
  --alter table Analytics.dbo._request_log alter column requestSum   float

--exec sp_select_except '#t7_changed', '_request', 'guid', '#t6'

--select * from #t7
--order by 1
--select * from #t7_changed
--order by 1



    INSERT INTO #t7_changed ([guid], [number], [origin], [productTypeInitial], [productType] , [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum],requestSum, [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast],eventLastCreated, [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], _pack2ProfileSignedPTS,  [_pack2SignedPTS],   [_uprid], [_upridYes], _2750, [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], loanOrder, [loyalty], [loyaltyPts], [loyaltyBezzalog], firstLoanIssued, [firstLoanProductType],  [returnTypeByProduct], [clientId], [id]
	--, [browser], [browserVersion]
	, [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts], [_profilePTScntSurname], [_profilePTScntCarBrand], fioBirthday, [_docPhotoPtsCnt], passportSerialNumber, carBrand, carModel, carYear, parentGuid, eventLastTriggerDesc,_pack1resigning 
, _pack1resigned
, firstLoanRbp
, firstLoanNumber
, lastClosedLoanNumber
, lastClosedInterestRate
, lastInterestRate
, lastLoanNumber
, declineReason
, [_lastEventRedirectCnt]
, link
, code
, region
, regionRegistration
,  [pskRate] 
,  productNameCrm 
,  loanNumber 
,  interestRateRecommended
, lastIssued
, lastClosedIssued
, lastClosed
, carRegNumber
--, feodorId
, [_photosCnt]
, _photosOpenedCnt
, firstSchedulePay
, age
, carPrice
, [fpd0]       
, [fpd4]       
, [fpd7]       
, [fpd10]      
, [fpd15]      
, [fpd30]     
, fpd60
, [loanStatus] 
, employmentType
, employmentPlace
, employmentPosition
, _subQueryInfoPts
, _proofOfIncomePTS

, _incomeOfferSelectionPTS
	,      needBki        
	,      call03
	,      call03approved
	, _proofOfIncomeLoadedPTS
	, _refinementProofOfIncome
	
,[_profilePTSpersonal] 
,[_profilePTScar] 
, [_carPhotoPTScarClient] 
, [_carPhotoPTSvin] 
, [productSubType]
, isTakePts
, workplaceVerifiedIncome
, rosstatIncome
, bkiIncome
, bkiExpense
, firstLimitChoice       
, secondLimitChoice      
, finalLimitChoice     
, fio
, email
, lastName
, firstName
, patronymic
, addProductSumNet
, paused
, call15
, call15approved

, call3
, call3approved
, call4
, call4approved

, call5
, call5approved
, payMethod
,paySbpBank
, os
    ,  _profileBI
	, _call03BI
	, _call03approvedBI
	,  _photoBI
	,  _pack1BI
	,  _preApprovalWaitingBI
	,  _incomeOfferSelectionBI
	,  _proofOfIncomeBI
	,  _proofOfIncomeLoadedBI
	,  _calculatorBI
	,  _payMetodBI
	,  _timerBI
	,  _timerOutBI
	,  _pack2SignedBI
	, VIN



---1
)
    SELECT [guid], [number], [origin], [productTypeInitial], [productType],   [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], requestSum, [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], eventLastCreated, [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], _pack2ProfileSignedPTS,  [_pack2SignedPTS],    [_uprid], [_upridYes], _2750, [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], loanOrder, [loyalty], [loyaltyPts], [loyaltyBezzalog], firstLoanIssued, [firstLoanProductType],   [returnTypeByProduct], [clientId], [id]
	--, [browser], [browserVersion]
	, [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts], [_profilePTScntSurname], [_profilePTScntCarBrand], fioBirthday, [_docPhotoPtsCnt], passportSerialNumber, carBrand, carModel, carYear, parentGuid, eventLastTriggerDesc,_pack1resigning 
, _pack1resigned
, firstLoanRbp
, firstLoanNumber
,   lastClosedLoanNumber, lastClosedInterestRate, lastInterestRate
 ,   lastLoanNumber
, declineReason
, [_lastEventRedirectCnt]

, link
, code
, region	
, regionRegistration
, [pskRate] 
, productNameCrm 
, loanNumber 
, interestRateRecommended 
, lastIssued
, lastClosedIssued
, lastClosed
, carRegNumber
--, feodorId
, [_photosCnt]
, _photosOpenedCnt
, firstSchedulePay
, age
, carPrice
, [fpd0]       
, [fpd4]       
, [fpd7]       
, [fpd10]      
, [fpd15]      
, [fpd30]      
, fpd60
, [loanStatus] 
, employmentType
, employmentPlace
, employmentPosition
, _subQueryInfoPts
, _proofOfIncomePTS
, _incomeOfferSelectionPTS
,      needBki        
,      call03
,      call03approved
, _proofOfIncomeLoadedPTS
, _refinementProofOfIncome
,[_profilePTSpersonal] 
,[_profilePTScar] 
, [_carPhotoPTScarClient] 
, [_carPhotoPTSvin] 
, [productSubType]
, isTakePts
, workplaceVerifiedIncome
, rosstatIncome
, bkiIncome
, bkiExpense
, firstLimitChoice       
, secondLimitChoice      
, finalLimitChoice  
, fio
, email

, lastName
, firstName
, patronymic
, addProductSumNet
, paused
, call15
, call15approved

, call3
, call3approved
, call4
, call4approved

, call5
, call5approved
, payMethod
,paySbpBank
, os
    , _profileBI
	
	, _call03BI
	, _call03approvedBI
	, _photoBI
	, _pack1BI
	, _preApprovalWaitingBI
	, _incomeOfferSelectionBI
	, _proofOfIncomeBI
	, _proofOfIncomeLoadedBI
	,  _calculatorBI
	,  _payMetodBI
	,  _timerBI
	,  _timerOutBI
	,  _pack2SignedBI
	, vin
---1

    FROM  #t6
    EXCEPT
    SELECT [guid], [number], [origin], [productTypeInitial], [productType],  [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], requestSum, [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], eventLastCreated, [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS],  _pack2ProfileSignedPTS,  [_pack2SignedPTS],    [_uprid], [_upridYes], _2750, [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], loanOrder, [loyalty], [loyaltyPts], [loyaltyBezzalog], firstLoanIssued, [firstLoanProductType],  [returnTypeByProduct], [clientId], [id]
	--, [browser], [browserVersion]
	, [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts], [_profilePTScntSurname], [_profilePTScntCarBrand], fioBirthday, [_docPhotoPtsCnt], passportSerialNumber, carBrand, carModel, carYear, parentGuid, eventLastTriggerDesc,_pack1resigning 
, _pack1resigned
, firstLoanRbp
, firstLoanNumber
,  lastClosedLoanNumber, lastClosedInterestRate, lastInterestRate
  , lastLoanNumber
, declineReason
, [_lastEventRedirectCnt]

, link
, code
, region
, regionRegistration
, [pskRate] 
, productNameCrm 
, loanNumber 
, interestRateRecommended 
, lastIssued
, lastClosedIssued
, lastClosed

,carRegNumber
--, feodorId
, [_photosCnt]
, _photosOpenedCnt
, firstSchedulePay
, age
, carPrice
, [fpd0]       
, [fpd4]       
, [fpd7]       
, [fpd10]      
, [fpd15]      
, [fpd30]   
, fpd60
, [loanStatus] 
, employmentType
, employmentPlace
, employmentPosition
, _subQueryInfoPts
,_proofOfIncomePTS
, _incomeOfferSelectionPTS
	,      needBki        
	,      call03
	,      call03approved
	, _proofOfIncomeLoadedPTS
	, _refinementProofOfIncome
	,[_profilePTSpersonal] 
,[_profilePTScar] 
, [_carPhotoPTScarClient] 
, [_carPhotoPTSvin] 
, [productSubType]
, isTakePts
, workplaceVerifiedIncome
, rosstatIncome
, bkiIncome
, bkiExpense
, firstLimitChoice       
, secondLimitChoice      
, finalLimitChoice  
, fio
, email

, lastName
, firstName
, patronymic
, addProductSumNet
, paused
, call15
, call15approved

, call3
, call3approved
, call4
, call4approved

, call5
, call5approved
, payMethod
,paySbpBank
, os
    ,   _profileBI
	
	, _call03BI
	, _call03approvedBI
	,   _photoBI
	,   _pack1BI
	,   _preApprovalWaitingBI
	,   _incomeOfferSelectionBI
	,   _proofOfIncomeBI
	,   _proofOfIncomeLoadedBI
	,  _calculatorBI
	,  _payMetodBI
	,  _timerBI
	,  _timerOutBI
	,  _pack2SignedBI
	,  vin
---1

    FROM _request
    WHERE _request.guid IN (
        SELECT guid
        FROM   #t6
    );
  


   drop table if exists   _request_log_t6
 select * into _request_log_t6 from #t6

 

 drop table if exists   _request_log_request
 select * into _request_log_request  
 
  FROM _request
    WHERE _request.guid IN (
        SELECT guid
        FROM   #t6
    ); 

	
   drop table if exists   _request_log_t7_changed
 select * into _request_log_t7_changed from #t7_changed


   
;
 
if 1=0 
begin

--select 'MERGE _request AS a  USING (SELECT * FROM #t7_changed ) AS b      ON a.guid = b.guid  WHEN MATCHED THEN  UPDATE SET 
--a.[row_updated] = getdate()  ' union all
--select * from (
--select top 1000 case when column_name = 'row_updated' then '' else ',' end + 'a.['+column_name+'] = '+case 
--when column_name like 'row_' + '%' then 'getdate() '
--when column_name not in ('') then 'b.['+column_name+']'
-- else 'case when a.['+column_name+'] is not null then a.['+column_name+'] else  b.['+column_name+']  end ' end  t
--from dwh where  table_name='_request' and column_name <>'row_created' and column_name 
--in (select column_name from dwh where db='tempdb' and table_name like '%' + '#t7_changed'  + '%' ) order by ordinal_position )  x union all
----select * from #t7_changed
--select ' WHEN NOT MATCHED BY TARGET THEN INSERT (' union all
--select '  row_created' union all
--select '  ,row_updated' union all
--select * from (
--select top 1000 ',['+column_name+'] ' t from dwh where  table_name='_request'  and  column_name 
--in (select column_name from dwh where db='tempdb' and table_name like '%' + '#t7_changed'  + '%' ) order by ordinal_position )  x  union all
--select '  )         VALUES ( ' union all
--select '  getdate()' union all
--select '  ,getdate()' union all
----select ' ,b.['+column_name+'] ' from dwh where  table_name='_request' union all
--select * from (
--select top 1000 ','	 +case when column_name like 'row_' + '%' then 'getdate() ' else 'b.['+column_name+'] ' end t  from dwh where  table_name='_request'  and column_name 
--in (select column_name from dwh where db='tempdb' and table_name like '%' + '#t7_changed'  + '%' ) order by ordinal_position   ) x union all 
--select '  )'-- union all
 declare @r288282 date 
 end 

 --ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN _lastEventRedirectCnt  int
-- select * from dwh where table_name='_request' and DATA_TYPE='tinyint'

;

MERGE _request AS a  USING (SELECT * FROM #t7_changed ) AS b      ON a.guid = b.guid  WHEN MATCHED THEN  UPDATE SET 
a.[rowUpdated] = getdate()  
,a.[guid] = b.[guid]
,a.[number] = b.[number]
,a.[origin] = b.[origin]
,a.[productTypeInitial] = b.[productTypeInitial]
,a.[productType] = b.[productType] 
,a.[status_crm] = b.[status_crm]
,a.[created] = b.[created]
,a.[phone] = b.[phone]
,a.[declined] = b.[declined]
,a.[cancelled] = b.[cancelled]
,a.[rejected] = b.[rejected]
,a.[returnType] = b.[returnType]
,      a.needBki          	= b.needBki       
,      a.call03				= b.call03			
,      a.call03approved		= b.call03approved
,a.[call1] = b.[call1]
,a.[call1approved] = b.[call1approved]
,a.[checking] = b.[checking]
,a.[call2] = b.[call2]
,a.[call2Approved] = b.[call2Approved]
,a.[clientVerification] = b.[clientVerification]
,a.[clientApproved] = b.[clientApproved]
,a.[carVerificarion] = b.[carVerificarion]
,a.[approved] = b.[approved]
,a.[contractSigned] = b.[contractSigned]
,a.[issued] = b.[issued]
,a.[closed] = b.[closed]
,a.[firstSum] = b.[firstSum]
,a.requestSum = b.requestSum
,a.[approvedSum] = b.[approvedSum]
,a.[issuedSum] = b.[issuedSum]
,a.[interestRate] = b.[interestRate]
,a.firstSchedulePay = b.firstSchedulePay

,a.[isPts] = b.[isPts]
,a.[isInst] = b.[isInst]
,a.[term] = b.[term]
,a.[termDays] = b.[termDays]
,a.[freeTermDays] = b.[freeTermDays]
,a.[marketingCosts] = b.[marketingCosts]
,a.[prolongationCnt] = b.[prolongationCnt]
,a.[prolongationFirstDate] = b.[prolongationFirstDate]
,a.[monthlyIncome] = b.[monthlyIncome]
,a.[closedPlanDate] = b.[closedPlanDate]
,a.[event] = b.[event]
,a.[eventLast] = b.[eventLast]
,a.eventLastCreated = b.eventLastCreated
,a.[eventDesc] = b.[eventDesc]
,a.[_profile] = b.[_profile]
,a.[_passport] = b.[_passport]
,a.[_photos] = b.[_photos]
,a.[_pack1] = b.[_pack1]
,a.[_call1] = b.[_call1]
,a.[_workAndIncome] = b.[_workAndIncome]
,a.[_cardLinked] = b.[_cardLinked]
,a.[_approvalWaiting] = b.[_approvalWaiting]
,a.[_offerSelection] = b.[_offerSelection]
,a.[_contractSigning] = b.[_contractSigning]
,a.[_calculatorPts] = b.[_calculatorPts]
,a.[_profilePts] = b.[_profilePts]
, a._subQueryInfoPts = b._subQueryInfoPts
,a.[_docPhotoPts] = b.[_docPhotoPts]
,a.[_docPhotoLoadedPts] = b.[_docPhotoLoadedPts]
,a.[_pack1Pts] = b.[_pack1Pts]
,a.[_pack1SignedPts] = b.[_pack1SignedPts]
,a.[_clientAndDocPhoto2Pts] = b.[_clientAndDocPhoto2Pts]
,a.[_additionalInfoPTS] = b.[_additionalInfoPTS]
,a.[_carDocPhotoPTS] = b.[_carDocPhotoPTS]
, a._incomeOfferSelectionPTS = b._incomeOfferSelectionPTS
, a._proofOfIncomePTS = b._proofOfIncomePTS
, a._proofOfIncomeLoadedPTS = b._proofOfIncomeLoadedPTS
,a.[_payMethodPts] = b.[_payMethodPts]
,a.[_cardLinkedPTS] = b.[_cardLinkedPTS]
,a.[_carPhotoPTS] = b.[_carPhotoPTS]
,a.[_fullRequestPTS] = b.[_fullRequestPTS]
,a.[_approvalPTS] = b.[_approvalPTS]
,a.[_pack2PTS] = b.[_pack2PTS]
, a._pack2ProfileSignedPTS = b._pack2ProfileSignedPTS
,a.[_pack2SignedPTS] = b.[_pack2SignedPTS]
,a.[_uprid] = b.[_uprid]
,a.[_upridYes] = b.[_upridYes]
,a._2750 = b._2750
,a.[_2751] = b.[_2751]
,a.[closedRequestByProduct] = b.[closedRequestByProduct]
,a.[closedHasRequestByProduct90d] = b.[closedHasRequestByProduct90d]
,a.[RequestAfterCancelled] = b.[RequestAfterCancelled]
,a.[RequestAfterCancelledDt] = b.[RequestAfterCancelledDt]
,a.loanOrder = b.loanOrder
,a.[loyalty] = b.[loyalty]
,a.[loyaltyPts] = b.[loyaltyPts]
,a.[loyaltyBezzalog] = b.[loyaltyBezzalog]
,a. firstLoanIssued  = b.firstLoanIssued
,a.[firstLoanProductType] = b.[firstLoanProductType]
--,a.[closedDpdBeginDay] = b.[closedDpdBeginDay]
--,a.[DpdBeginDay] = b.[DpdBeginDay]
--,a.[DpdMaxBeginDay] = b.[DpdMaxBeginDay]
,a.[returnTypeByProduct] = b.[returnTypeByProduct]
,a.[clientId] = b.[clientId]
,a.[id] = b.[id]
--,a.[browser] = b.[browser]
--,a.[browserVersion] = b.[browserVersion]
,a.[_carDocPhotoPTScntPts] = b.[_carDocPhotoPTScntPts]
,a.[_carDocPhotoPTScntSts] = b.[_carDocPhotoPTScntSts]
,a.[_profilePTScntSurname] = b.[_profilePTScntSurname]
,a.[_profilePTScntCarBrand] = b.[_profilePTScntCarBrand]
,a.fioBirthday = b.fioBirthday
, a.fio = b.fio
, a.age = b.age
,a.[_docPhotoPtsCnt] = b.[_docPhotoPtsCnt]
, a._photosOpenedCnt =b._photosOpenedCnt
, a.[_photosCnt] = b.[_photosCnt]
,a.passportSerialNumber = b.passportSerialNumber
,a.carBrand = b.carBrand
,a.carModel = b.carModel
,a.carYear = b.carYear
, a.carPrice = b.carPrice
,a.parentGuid = b.parentGuid
,a.eventLastTriggerDesc = b.eventLastTriggerDesc
,a._pack1resigning = b._pack1resigning
,a._pack1resigned = b._pack1resigned
, a._refinementProofOfIncome= b._refinementProofOfIncome
,a.firstLoanRbp = b.firstLoanRbp
,a.firstLoanNumber = b.firstLoanNumber
 , a.lastClosedLoanNumber = b. lastClosedLoanNumber
 , a.lastClosedInterestRate = b. lastClosedInterestRate
 , a.lastInterestRate = b. lastInterestRate
 , a.lastLoanNumber = b.lastLoanNumber



,a.declineReason = b.declineReason
,a.[_lastEventRedirectCnt] = b.[_lastEventRedirectCnt]
,a.link = b.link
,a.code = b.code
,a.region = b.region
, a.regionRegistration=b.regionRegistration
,a.[pskRate]  = b.[pskRate] 
,a.productNameCrm  = b.productNameCrm 
,a.loanNumber= b.loanNumber 
,a.interestRateRecommended= b.interestRateRecommended

,a. lastIssued		  = b.lastIssued
,a. lastClosedIssued  = b.lastClosedIssued 
,a. lastClosed  = b.lastClosed 
, a.carRegNumber=b.carRegNumber
--, a.feodorId = b.feodorId

, a.[fpd0]        = b.[fpd0]       
, a.[fpd4]        = b.[fpd4]       
, a.[fpd7]        = b.[fpd7]       
, a.[fpd10]       = b.[fpd10]      
, a.[fpd15]       = b.[fpd15]      
, a.[fpd30]       = b.[fpd30]      
, a.[fpd60]       = b.[fpd60]      

, a.[loanStatus]  = b.[loanStatus] 
  
,a.employmentType     = b.employmentType    
,a.employmentPlace	  = b.employmentPlace	 
,a.employmentPosition  = b.employmentPosition 
,a.[_profilePTSpersonal]         = b.[_profilePTSpersonal]      
,a.[_profilePTScar] 			 = b.[_profilePTScar] 		
,a. [_carPhotoPTScarClient] 	 = b. [_carPhotoPTScarClient] 
,a. [_carPhotoPTSvin] 			 = b. [_carPhotoPTSvin] 	
, a.[productSubType]=b.[productSubType]
, a.isTakePts = b.isTakePts

, a.workplaceVerifiedIncome   = b.workplaceVerifiedIncome 
, a.rosstatIncome			  = b.rosstatIncome			
, a.bkiIncome				  = b.bkiIncome				
, a.bkiExpense				  = b.bkiExpense				
, a.firstLimitChoice       	  = b.firstLimitChoice       	
, a.secondLimitChoice      	  = b.secondLimitChoice      	
, a.finalLimitChoice  		  = b.finalLimitChoice  		
, a.email = b.email

, a.lastName    = b.lastName    
, a.firstName	= b.firstName
, a.patronymic	= b.patronymic
, a.addProductSumNet = b.addProductSumNet
, a.paused = b.paused
, a.call15             = b.call15
, a.call15approved     = b.call15approved
, a.call3			   = b.call3
, a.call3approved	   = b.call3approved
, a.call4			   = b.call4
, a.call4approved	   = b.call4approved
, a.call5			   = b.call5
, a.call5approved	   = b.call5approved
, a.payMethod = b.payMethod
, a.paySbpBank = b.paySbpBank
, a.os=b.os
    , a. _profileBI                   = b.  _profileBI            
	
	, a._call03BI          = b._call03BI         
	, a._call03approvedBI  = b._call03approvedBI 
	, a. _photoBI					  = b.  _photoBI					
	, a. _pack1BI					  = b.  _pack1BI					
	, a. _preApprovalWaitingBI		  = b.  _preApprovalWaitingBI		
	, a. _incomeOfferSelectionBI	  = b.  _incomeOfferSelectionBI	
	, a. _proofOfIncomeBI			  = b.  _proofOfIncomeBI			
	, a. _proofOfIncomeLoadedBI		  = b.  _proofOfIncomeLoadedBI		


	, a. _calculatorBI  = b. _calculatorBI
	, a. _payMetodBI	= b. _payMetodBI
	, a. _timerBI		= b. _timerBI
	, a. _timerOutBI	= b. _timerOutBI
	, a. _pack2SignedBI	= b. _pack2SignedBI
	, a.vin = b.vin

 ---1

 WHEN NOT MATCHED BY TARGET THEN INSERT (
  rowCreated
  ,rowUpdated
,[guid] 
,[number] 
,[origin] 
,[productTypeInitial] 
,[productType]  
,[status_crm] 
,[created] 
,[phone] 
,[declined] 
,[cancelled] 
,[rejected] 
,[returnType] 
,     needBki         
,     call03		 
,     call03approved 

,[call1] 
,[call1approved] 
,[checking] 
,[call2] 
,[call2Approved] 
,[clientVerification] 
,[clientApproved] 
,[carVerificarion] 
,[approved] 
,[contractSigned] 
,[issued] 
,[closed] 
,[firstSum] 
,requestSum 
,[approvedSum] 
,[issuedSum] 
,[interestRate] 
, firstSchedulePay

,[isPts] 
,[isInst] 
,[term] 
,[termDays] 
,[freeTermDays] 
,[marketingCosts] 
,[prolongationCnt] 
,[prolongationFirstDate] 
,[monthlyIncome] 
,[closedPlanDate] 
,[event] 
,[eventLast] 
,eventLastCreated 
,[eventDesc] 
,[_profile] 
,[_passport] 
,[_photos] 
,[_pack1] 
,[_call1] 
,[_workAndIncome] 
,[_cardLinked] 
,[_approvalWaiting] 
,[_offerSelection] 
,[_contractSigning] 
,[_calculatorPts] 
,[_profilePts] 
, _subQueryInfoPts
,[_docPhotoPts] 
,[_docPhotoLoadedPts] 
,[_pack1Pts] 
,[_pack1SignedPts] 
,[_clientAndDocPhoto2Pts] 
,[_additionalInfoPTS] 
,[_carDocPhotoPTS] 
, _incomeOfferSelectionPTS
, _proofOfIncomePTS
, _proofOfIncomeLoadedPTS
,[_payMethodPts] 
,[_cardLinkedPTS] 
,[_carPhotoPTS] 
,[_fullRequestPTS] 
,[_approvalPTS] 
,[_pack2PTS] 
, _pack2ProfileSignedPTS
,[_pack2SignedPTS] 
,[_uprid] 
,[_upridYes] 
,_2750 
,[_2751] 
,[closedRequestByProduct] 
,[closedHasRequestByProduct90d] 
,[RequestAfterCancelled] 
,[RequestAfterCancelledDt] 
,loanOrder 
,[loyalty] 
,[loyaltyPts] 
,[loyaltyBezzalog]  
,firstLoanIssued 
,[firstLoanProductType] 
--,[closedDpdBeginDay] 
--,[DpdBeginDay] 
--,[DpdMaxBeginDay] 
,[returnTypeByProduct] 
,[clientId] 
,[id] 
--,[browser] 
--,[browserVersion] 
,[_carDocPhotoPTScntPts] 
,[_carDocPhotoPTScntSts] 
,[_profilePTScntSurname] 
,[_profilePTScntCarBrand] 
,fioBirthday 
, fio
, age
,[_docPhotoPtsCnt] 
, _photosOpenedCnt
, [_photosCnt]
,passportSerialNumber 
,carBrand 
,carModel 
,carYear 
,parentGuid 
,eventLastTriggerDesc 
,_pack1resigning 
, _pack1resigned
, _refinementProofOfIncome
, firstLoanRbp
, firstLoanNumber
 , lastClosedLoanNumber
 , lastClosedInterestRate
 , lastInterestRate
 , lastLoanNumber


, declineReason
, [_lastEventRedirectCnt]
, link
, code
, region
, regionRegistration
, [pskRate] 
, productNameCrm 
, loanNumber 
, interestRateRecommended 

, lastIssued
, lastClosedIssued
, lastClosed
, carRegNumber
--, feodorId
, carPrice
,  [fpd0]       
,  [fpd4]       
,  [fpd7]       
,  [fpd10]      
,  [fpd15]      
,  [fpd30]      
,  [fpd60]      
,  [loanStatus] 
 
, employmentType    
, employmentPlace	 
, employmentPosition 

, [_profilePTSpersonal]      
, [_profilePTScar] 		
,  [_carPhotoPTScarClient] 
,  [_carPhotoPTSvin] 	
, [productSubType]
, isTakePts
,workplaceVerifiedIncome 
,rosstatIncome			
,bkiIncome				
,bkiExpense				
,firstLimitChoice       	
,secondLimitChoice      	
,finalLimitChoice  		

, email
, lastName    
, firstName
, patronymic
, addProductSumNet
, paused
, call15
, call15approved
, call3
, call3approved
, call4
, call4approved
, call5
, call5approved
, payMethod
, paySbpBank
, os
,  _profileBI       
,   _call03BI         
	,  _call03approvedBI 
,  _photoBI				
,  _pack1BI				
,  _preApprovalWaitingBI	
,  _incomeOfferSelectionBI
,  _proofOfIncomeBI		
,  _proofOfIncomeLoadedBI	
 ,  _calculatorBI
 ,  _payMetodBI
 ,  _timerBI
 ,  _timerOutBI
 ,  _pack2SignedBI

 , vin



---1

 


  )         VALUES ( 
  getdate()
  ,getdate()
,b.[guid] 
,b.[number] 
,b.[origin] 
,b.[productTypeInitial] 
,b.[productType]  
,b.[status_crm] 
,b.[created] 
,b.[phone] 
,b.[declined] 
,b.[cancelled] 
,b.[rejected] 
,b.[returnType] 

,    b. needBki         
,    b. call03		 
,    b. call03approved 



,b.[call1] 
,b.[call1approved] 
,b.[checking] 
,b.[call2] 
,b.[call2Approved] 
,b.[clientVerification] 
,b.[clientApproved] 
,b.[carVerificarion] 
,b.[approved] 
,b.[contractSigned] 
,b.[issued] 
,b.[closed] 
,b.[firstSum] 
,b.requestSum 
,b.[approvedSum] 
,b.[issuedSum] 
,b.[interestRate] 
, b.firstSchedulePay

,b.[isPts] 
,b.[isInst] 
,b.[term] 
,b.[termDays] 
,b.[freeTermDays] 
,b.[marketingCosts] 
,b.[prolongationCnt] 
,b.[prolongationFirstDate] 
,b.[monthlyIncome] 
,b.[closedPlanDate] 
,b.[event] 
,b.[eventLast] 
,b.eventLastCreated 
,b.[eventDesc] 
,b.[_profile] 
,b.[_passport] 
,b.[_photos] 
,b.[_pack1] 
,b.[_call1] 
,b.[_workAndIncome] 
,b.[_cardLinked] 
,b.[_approvalWaiting] 
,b.[_offerSelection] 
,b.[_contractSigning] 
,b.[_calculatorPts] 
,b.[_profilePts] 
, b._subQueryInfoPts
,b.[_docPhotoPts] 
,b.[_docPhotoLoadedPts] 
,b.[_pack1Pts] 
,b.[_pack1SignedPts] 
,b.[_clientAndDocPhoto2Pts] 
,b.[_additionalInfoPTS] 
,b.[_carDocPhotoPTS] 
, b._incomeOfferSelectionPTS
, b._proofOfIncomePTS
, b._proofOfIncomeLoadedPTS
,b.[_payMethodPts] 
,b.[_cardLinkedPTS] 
,b.[_carPhotoPTS] 
,b.[_fullRequestPTS] 
,b.[_approvalPTS] 
,b.[_pack2PTS] 
, b._pack2ProfileSignedPTS
,b.[_pack2SignedPTS] 
,b.[_uprid] 
,b.[_upridYes] 
,b._2750 
,b.[_2751] 
,b.[closedRequestByProduct] 
,b.[closedHasRequestByProduct90d] 
,b.[RequestAfterCancelled] 
,b.[RequestAfterCancelledDt] 
,b.loanOrder 
,b.[loyalty] 
,b.[loyaltyPts] 
,b.[loyaltyBezzalog] 
,b.firstLoanIssued 
,b.[firstLoanProductType] 
--,b.[closedDpdBeginDay] 
--,b.[DpdBeginDay] 
--,b.[DpdMaxBeginDay] 
,b.[returnTypeByProduct] 
,b.[clientId] 
,b.[id] 
--,b.[browser] 
--,b.[browserVersion] 
,b.[_carDocPhotoPTScntPts] 
,b.[_carDocPhotoPTScntSts] 
,b.[_profilePTScntSurname] 
,b.[_profilePTScntCarBrand] 
,b.fioBirthday 
, fio
, b.age
,b.[_docPhotoPtsCnt] 
,b._photosOpenedCnt
, b.[_photosCnt]
,b.passportSerialNumber 
,b.carBrand 
,b.carModel 
,b.carYear 
,b.parentGuid 
,b.eventLastTriggerDesc 
,b._pack1resigning 
,b. _pack1resigned
, b._refinementProofOfIncome
,b. firstLoanRbp
,b. firstLoanNumber
 , b.lastClosedLoanNumber
 , b.lastClosedInterestRate
 , b.lastInterestRate
 , b.lastLoanNumber



,b. declineReason
,b. [_lastEventRedirectCnt] 
, b.link
, b.code
, b.region
, b.regionRegistration
, b.[pskRate] 
, b.productNameCrm 
, b.loanNumber 
, b.interestRateRecommended 

, b.lastIssued
, b.lastClosedIssued
, b.lastClosed
, b.carRegNumber
--, b.feodorId
, b.carPrice
, b.[fpd0]       
, b.[fpd4]       
, b.[fpd7]       
, b.[fpd10]      
, b.[fpd15]      
, b.[fpd30]      
, b.[fpd60]      
, b.[loanStatus] 
 
, b.employmentType    
, b.employmentPlace	 
, b.employmentPosition 

,  b.[_profilePTSpersonal]      
,  b.[_profilePTScar] 		
,  b. [_carPhotoPTScarClient] 
,  b. [_carPhotoPTSvin] 	
, b.[productSubType]
, b.isTakePts
,b.workplaceVerifiedIncome 
,b.rosstatIncome			
,b.bkiIncome				
,b.bkiExpense				
,b.firstLimitChoice       	
,b.secondLimitChoice      	
,b.finalLimitChoice  		
, b.email

, b.lastName    
, b.firstName
, b.patronymic
, b.addProductSumNet
, b.paused
, b.call15
, b.call15approved
, b.call3
, b.call3approved
, b.call4
, b.call4approved
, b.call5
, b.call5approved
, b.payMethod
, b.paySbpBank
, b.os
, b. _profileBI  
,   _call03BI         
	,  _call03approvedBI 
, b. _photoBI				
, b. _pack1BI				
, b. _preApprovalWaitingBI	
, b. _incomeOfferSelectionBI
, b. _proofOfIncomeBI		
, b. _proofOfIncomeLoadedBI	

 , b. _calculatorBI
 , b. _payMetodBI
 , b. _timerBI
 , b. _timerOutBI
 , b. _pack2SignedBI

 , b.vin



  )
;

		declare @rc bigint = @@ROWCOUNT
		 
		 select @rc, 'updated'
 

 exec _request_fill_row -1

 exec _request_dubl 
 
EXEC Analytics.dbo.sp_birs_update 'd76c7807-bc72-426f-8926-f81db4a3fe19' 

  

--delete a  from _request a left join  v_request b on a.guid = b.guid  
--where b.guid is null


END TRY
BEGIN CATCH
    DECLARE 
        @errorMessage NVARCHAR(4000),
        @errorSeverity INT,
        @errorState INT,
        @errorLine INT;

    -- Получаем данные об ошибке
    SELECT 
        @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE(),
        @errorLine = ERROR_LINE();

	set	@errorMessage =   CONCAT('Ошибка на строке: ', @errorLine, ' — ', @errorMessage)


    -- Или вернуть через SELECT, если нужно в DataFrame
    SELECT 
        ErrorLine = @errorLine,
        ErrorMessage = @errorMessage;

    -- Повторно выбрасываем ошибку с уточнением строки
    THROW 50000, @errorMessage, 1;
END CATCH;





 return
   
  /*
 
  _subQueryInfoPts

  _proofOfIncomePTS

  _pack2ProfileSignedPTS


  _incomeOfferSelectionPTS


  
,     needBki         
,     call03		 
,     call03approved 

_proofOfIncomeLoadedPTS
  _refinementProofOfIncome

  
,a.[_profilePTSpersonal]         = b.[_profilePTSpersonal]      
,a.[_profilePTScar] 			 = b.[_profilePTScar] 		
,a. [_carPhotosPTScarClient] 	 = b. [_carPhotosPTScarClient] 
,a. [_carPhotosPTSvin] 			 = b. [_carPhotosPTSvin] 	

[productSubType]

isTakePts

 workplaceVerifiedIncome 
 rosstatIncome			
 bkiIncome				
 bkiExpense				
 firstLimitChoice       	
 secondLimitChoice      	
 finalLimitChoice  		
 regionRegistration
 fio
 email
 lastName    
 firstName
 patronymic
 addProductSumNet
 paused

 call15
 call15approved
 call3
 call3approved
 call4
 call4approved
 call5
 call5approved
 payMethod
 os

  _calculatorBI
  _payMetodBI
  _timerBI
  _timerOutBI
  _pack2SignedBI
  
    , a. _profileBI
	, a. _photoBI
	, a. _pack1BI
	, a. _preApprovalWaitingBI
	, a. _incomeOfferSelectionBI
	, a. _proofOfIncomeBI
	, a. _proofOfIncomeLoadedBI

	,   _call03BI         
	,  _call03approvedBI 

	, vin
	,paySbpBank

	

 declare @lastIssued    varchar(max) =   '[paySbpBank] varchar(50) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[vin] varchar(30) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

	
 declare @lastIssued    varchar(max) =   '[_call03BI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 set @lastIssued     =   '[_call03approvedBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

	
 declare @lastIssued    varchar(max) =   '[_profileBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[_photoBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[_pack1BI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[_preApprovalWaitingBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[_incomeOfferSelectionBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[_proofOfIncomeBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[_proofOfIncomeLoadedBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


----------
  
 declare @lastIssued    varchar(max) =   '[_calculatorBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
  
 declare @lastIssued    varchar(max) =   '[_payMetodBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


  
 declare @lastIssued    varchar(max) =   '[_timerBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


  
 declare @lastIssued    varchar(max) =   '[_timerOutBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


  
 declare @lastIssued    varchar(max) =   '[_pack2SignedBI] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )




 declare @lastIssued    varchar(max) =   '[os] varchar(50) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 

 declare @lastIssued    varchar(max) =   '[payMethod] varchar(150) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 
 declare @lastIssued    varchar(max) =   '[call15] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[call15approved] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[call3] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  
 declare @lastIssued    varchar(max) =   '[call3approved] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 
 
 declare @lastIssued    varchar(max) =   '[call4] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[call4approved] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 
 declare @lastIssued    varchar(max) =   '[call5] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
 declare @lastIssued    varchar(max) =   '[call5approved] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



 declare @lastIssued    varchar(max) =   '[paused] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[addProductSumNet] float '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



 declare @lastIssued    varchar(max) =   '[lastName] varchar(255) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  

 declare @lastIssued    varchar(max) =   '[firstName] varchar(255) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  

 declare @lastIssued    varchar(max) =   '[patronymic] varchar(255) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  

 
 declare @lastIssued    varchar(max) =   '[email] varchar(255) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  

 
 declare @lastIssued    varchar(max) =   '[fio] varchar(255) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  

 
 declare @lastIssued    varchar(max) =   '[regionRegistration] varchar(50) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  
 declare @lastIssued    varchar(max) =   '[workplaceVerifiedIncome] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  
 declare @lastIssued    varchar(max) =   '[rosstatIncome] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[bkiIncome] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[bkiExpense] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[firstLimitChoice] varchar(50) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		  

 declare @lastIssued    varchar(max) =   '[secondLimitChoice] varchar(50) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



 declare @lastIssued    varchar(max) =   '[finalLimitChoice] varchar(50) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
		   


 declare @lastIssued    varchar(max) =   '[isTakePts] Tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[productSubType] varchar(100) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[_profilePTSpersonal] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[_profilePTScar] tinyint'
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[_carPhotosPTScarClient] tinyint'
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[_carPhotosPTSvin] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[_refinementProofOfIncome] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[_proofOfIncomeLoadedPTS] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[needBki] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[call03] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[call03approved] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

		   
EXEC sp_rename 'Analytics.dbo._request.call03Accepted', 'call03approved'
EXEC sp_rename 'Analytics.dbo._request_log.call03Accepted', 'call03approved'
 
 

  
 declare @lastIssued    varchar(max) =   '[_incomeOfferSelectionPTS] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

  
 declare @lastIssued    varchar(max) =   '[_pack2ProfileSignedPTS] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


  update _request set _request._proofOfIncomePTS = dateadd(second, -1, _payMethodPts ) from _request 
  where productType='PTS'  and [_payMethodPts] <'20250701'
  
  
 declare @lastIssued    varchar(max) =   '[_proofOfIncomePTS] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



 declare @lastIssued    varchar(max) =   '[_subQueryInfoPts] datetime2(0) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[employmentPlace] varchar(255)  '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[employmentPosition] varchar(255)  '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )




 declare @lastIssued    varchar(max) =   '[fpd0] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =    '[fpd4] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =    '[fpd7] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =    '[fpd10] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[fpd15] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =    '[fpd30] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

		  
 declare @lastIssued    varchar(max) =    '[fpd60] int '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[loanStatus] varchar(25) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )






  
 declare @lastIssued    varchar(max) =   '[abPhotoUprid] varchar(255) '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



 declare @lastIssued    varchar(max) =   '[carPrice] bigint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
  


 declare @lastIssued    varchar(max) =   '[age] tinyint '
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )
  
 declare @lastIssued    varchar(max) =   '[firstSchedulePay] numeric(15,2)'
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )

 declare @lastIssued    varchar(max) =   '[cessionSum] numeric(15,2)'
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )


 declare @lastIssued    varchar(max) =   '[_photosOpenedCnt] tinyint'
 exec ( 'alter table _request add '+@lastIssued+' 
		  alter table _request_log add '+@lastIssued )



alter table _request add lastClosed datetime2(0) 
		  alter table _request_log add lastClosed datetime2(0)

		  */
--alter table _request add lastClosedIssued datetime2(0) 
--		  alter table _request_log add lastClosedIssued datetime2(0)
--alter table _request add lastIssued datetime2(0) 
--		  alter table _request_log add lastIssued datetime2(0)

 update request set 
 --  request.carBrand = b.carBrand 
 --,request.carModel = b.carModel 
 --,request.carYear = b.carYear 
 --,
 request.declineReason = b.declineReason 
 
 
 from _request request join v_request b  on request.guid=b.guid 
 

 update request set   request.link = b.link, request.age=b.age  from _request request join v_request b  on request.guid=b.guid 
 update request set   request.productNameCrm = b.productNameCrm  from _request request join v_request b  on request.guid=b.guid 
 update request set   request.pskRate = b.[ПСК текущая], request.firstSchedulePay = b.[Размер платежа первоначальный]  from _request request join mv_loans b  on request.number=b.[Номер заявки] 
 update request set   request.interestRateRecommended = b.interestRateRecommended  from _request request join v_request b  on request.guid=b.guid 
 update request set   request.region = gmt.region  from _request request join v_request b  on request.guid=b.guid 
 left join v_gmt gmt on gmt.region = b.region

 update request set   request.feodorId = b.feodor_request_id  from _request request join v_request b  on request.guid=b.guid 
 update request set   request.carPrice = b.[Стоимость ТС]  from _request request join mv_loans b  on request.number=b.[Номер заявки] 


 update request set  
 request.fpd0 = b.fpd0
 , request.fpd4 = b.fpd4
 , request.fpd7 = b.fpd7
 , request.fpd10 = b.fpd10
 , request.fpd15 = b.fpd15
 , request.fpd30 = b.fpd30
 , request.loanStatus = b.statusContract


 from _request request join v_loan_overdue b  on request.loannumber=b.number


  update request set  
 request.fpd60 = b.fpd60
  

 from _request request join v_loan_overdue b  on request.loannumber=b.number


 
 update request set  
  request.employmentPlace	  =  [client_workplace_name]
, request.employmentPosition   =  [client_work_position]


 from _request request join v_request_lk b  on request.guid=b.guid


 update request set   request.number = b.number  from _request request join v_request b  on request.guid=b.guid 
 where request.number <> b.number 

 update request set   request.productSubType = b.productSubType  from _request request join v_request b  on request.guid=b.guid 
 update request set   request.isTakePts = b.isTakePts  from _request request join v_request b  on request.guid=b.guid 


  
 update request set   
   request.workplaceVerifiedIncome  = b.workplaceVerifiedIncome
 , request.rosstatIncome		 = b. rosstatIncome		
 , request.bkiIncome			 = b. bkiIncome			
 , request.bkiExpense			 = b. bkiExpense			
 , request.firstLimitChoice    = b. firstLimitChoice  	
 , request.secondLimitChoice   = b. secondLimitChoice 	
 , request.finalLimitChoice  	 = b. finalLimitChoice  
 
   from _request request join stg._fedor.core_ClientRequest b  on request.guid= cast(b.id as varchar(36)) --collate Cyrillic_General_CI_AS 


    update request set   request.regionRegistration = b.regionRegistration  from _request request join v_request b  on request.guid=b.guid 


 update request set   request.fio = b.fio  from _request request join v_request b  on request.guid=b.guid 


 update a set   a.email =   isnull(  nullif(c.электроннаяпочта , ''), nullif(b.client_email, '') ) from _request a 
 left join v_request_lk b on a.id=b.id 
 left join v_request_crm c on a.link=c.link 
 where  isnull(  nullif(c.электроннаяпочта , ''), nullif(b.client_email, '') ) is not null
 
 
 update request set   request.lastName = b.lastName  from _request request join v_request b  on request.guid=b.guid 
 update request set   request.firstName = b.firstName  from _request request join v_request b  on request.guid=b.guid 
 update request set   request.patronymic = b.patronymic  from _request request join v_request b  on request.guid=b.guid 


 update request set   request.addproductsumnet = b.addproductsumnet  from _request request join v_fa b  on request.number=b.number
 where  b.addproductsumnet is not null

 
 update request set   request.paused = b.created  from _request request join v_request_lk_event  b  on request.id=b.requestId and b.eventId=718
 


 update request set   request.lastName = b.lastName  from _request request join v_request b  on request.guid=b.guid 

  update request set  

  request.call15          = b. call15         , 
  request.call15approved  = b.call15approved  , 
  request.call3			  = b.call3			  , 
  request.call3approved	  = b.call3approved	  , 
  request.call4			  = b.call4			  , 
  request.call4approved	  = b.call4approved	  , 
  request.call5			  = b.call5			  , 
  request.call5approved	  = b.call5approved	 from _request request 
   join v_request b  on request.guid=b.guid 


 update request set   request.payMethod = b.payMethod  from _request request join v_request b  on request.guid=b.guid 

 update request set   request.os = b.os  from _request request join #os b  on request.id=b.id


 update request set   request.vin = b.vin  from _request request join v_request b  on request.guid=b.guid 


 update request set   request.payMethod = b.payMethod, request.paySbpBank = b.paySbpBank  from _request request join #pay_method b  on request.guid=b.guid 


 
 --select * from _request where number='18121490330002'
 --select * from v_request where number='18121490330002'
 --select * from v_request where loannumber='18121490330002'
 --select * from mv_loans where number='18121490330002'


 --select * from v_loan_overdue a
 --left join request b on a.number =b.loannumber
 --where b.guid is null

 --select count(*) from v_loan_overdue
 --  172966
 --select max(len(declineReason)) from v_request

 --select * from #inst_an3
 --where number='1706227190001'

 --select * from _request --where number='17111214360005'
 --select returnType, clientId from _request where number='17111214360005'
 --select returnType, clientId from v_request where number='17111214360005'
 --select * from _request where clientid='C15896CF-08A4-11E8-A814-00155D941900'
 ----select * from #t7 



--alter table _request add _carDocPhotoPTScntPts tinyint
--alter table _request_log add  _carDocPhotoPTScntPts tinyint
--alter table _request add _carDocPhotoPTScntSts tinyint
--alter table _request_log add  _carDocPhotoPTScntSts tinyint
 
--alter table _request add [_profilePTScntSurname] tinyint
--alter table _request_log add  [_profilePTScntSurname] tinyint
--alter table _request add [_profilePTScntCarBrand] tinyint
--alter table _request_log add  [_profilePTScntCarBrand] tinyint
--alter table _request add [firstLoanIssued] datetime2(0)
--alter table _request_log add  [firstLoanIssued] datetime2(0)


--alter table _request add [fioBirthday] nvarchar(50)
--alter table _request_log add  [fioBirthday] nvarchar(50)



--alter table _request add [_docPhotoPtsCnt] tinyint
--alter table _request_log add  [_docPhotoPtsCnt] tinyint


--alter table _request add _2750 datetime2(0)
--alter table _request_log add  _2750  datetime2(0)



--alter table _request add passportSerialNumber nvarchar(10)
--alter table _request_log add  passportSerialNumber   nvarchar(10)

--alter table _request add carBrand nvarchar(50)
--alter table _request_log add carBrand nvarchar(50)

--alter table _request add [carModel] nvarchar(50)
--alter table _request_log add [carModel] nvarchar(50)

--alter table _request add [carYear]  [INT]
--alter table _request_log add [carYear] [INT]

--alter table _request add [eventLastTriggerDesc] nvarchar(4000)
--alter table _request_log add [eventLastTriggerDesc] nvarchar(4000)

--alter table _request add [requestSum] int
--alter table _request_log add [requestSum] int

--alter table _request add [eventLastCreated] datetime2(0)
--alter table _request_log add [eventLastCreated] datetime2(0) 


--alter table _request add [loanOrder] tinyint
--alter table _request_log add [loanOrder] tinyint


--alter table _request add [_pack1resigning] datetime2(0)
--alter table _request_log add [_pack1resigning] datetime2(0)

--alter table _request add [_pack1resigned] datetime2(0)
--alter table _request_log add [_pack1resigned] datetime2(0)
--alter table _request drop column [declineReason] 
--alter table _request_log drop column [declineReason]
--alter table _request add [declineReason] nvarchar(128)
--alter table _request_log add [declineReason] nvarchar(128)

--alter table _request add [region] varchar(200)
--alter table _request_log add [region] varchar(200)




--alter table _request add [_lastEventRedirectCnt] tinyint
--alter table _request_log add  [_lastEventRedirectCnt] tinyint


--alter table _request add [link] binary(16)
--alter table _request_log add  [link] binary(16)

--alter table _request drop column [region] 
--alter table _request_log drop column [region]
--alter table _request add [code] varchar(32)
--alter table _request_log add  [code] varchar(32)

--alter table _request add [productNameCrm] varchar(250)
--alter table _request_log add  [productNameCrm] varchar(250)

--alter table _request add [pskRate] float
--alter table _request_log add  [pskRate] float


--alter table _request add [loanNumber] nvarchar(14)
--alter table _request_log add  [loanNumber] nvarchar(14)


--alter table _request_log drop column         lastClosedLoanNumber nvarchar(14)
--alter table _request drop column         lastClosedLoanNumber nvarchar(14)
--alter table _request_log add         lastClosedLoanNumber nvarchar(14)
--alter table _request_log add     lastLoanNumber nvarchar(14)


--alter table _request add         lastClosedLoanNumber nvarchar(14)
--alter table _request add     lastLoanNumber nvarchar(14)

--alter table _request add         interestRateRecommended float 
--alter table _request_log add     interestRateRecommended float


--alter table _request     add    lastClosedInterestRate float 
--alter table _request_log add    lastClosedInterestRate float


--alter table _request     add    lastInterestRate float 
--alter table _request_log add    lastInterestRate float


 --alter table _request add carRegNumber nvarchar(20) 
	--	  alter table _request_log add carRegNumber nvarchar(20)


	--alter table _request add productTypeExternal nvarchar(30) 
	--	  alter table _request_log add productTypeExternal nvarchar(30)

	--alter table _request add feodorId varchar(36) 
	--alter table _request_log add feodorId varchar(36)

--return



--exec msdb.dbo.sp_stop_job  @job_name= 'Analytics._request_product 7:00 each 5 min'--STOP 
--delete from  _request
--drop table if exists _request select top 0   getdate() row_created, getdate() row_updated ,  *    into _request from #t7_changed create clustered index i1 on _request (  guid ) create nonclustered index i2 on _request (  number)
--drop table if exists _request_log select  top 0  getdate() row_created, getdate() row_updated ,  *    into _request_log from #t7_changed create clustered index i1 on _request_log (  guid ) create nonclustered index i2 on _request_log (  number)

  --;with v  as (select *, row_number() over(partition by id  order by number desc) rn from #t6 where id is not null) delete from v where rn>1


 --тут ноль update a set a.[Переход на калькулятор ПТС] = [Верификация кц] , a. [Переход на Анкету ПТС] = [Верификация кц] from _birs.[product_report_request] a where ispts=1 and [Верификация кц] is not null and [Переход на калькулятор ПТС] is null --and [Переход на Анкету ПТС] is null 
  --а тут почему-то не ноль??? update a set a.[Переход на калькулятор ПТС] = [Верификация кц] , a. [Переход на Анкету ПТС] = [Верификация кц] from _birs.[product_report_request] a where ispts=1 and [Верификация кц] is not null and [Переход на Анкету ПТС] is null --and [Переход на Анкету ПТС] is null 
  --update a set a.[Переход на калькулятор ПТС] = [Верификация кц]  from #t6 a where ispts=1 and [Верификация кц] is not null and [Переход на калькулятор ПТС] is null and [Переход на Анкету ПТС] is null 
  --update a set a.[Переход на калькулятор ПТС] = [Верификация кц]  from #t6 a where ispts=1 and [Верификация кц] is not null and [Переход на калькулятор ПТС] is null 


 --exec exec_python 'parse_UserAgents()', 1 

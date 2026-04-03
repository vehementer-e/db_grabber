create   proc _request_product @days int = null as --exec _request_product 
declare @full_upd  bigint = 0
--select * into #t3267723 from _request where 1=0 
--drop table if exists _request select   *    into _request from #t3267723 
--create clustered index i1 on _request (  id )
--drop table if exists  _request_log  select *    into _request_log from #t3267723 
--return
--declare @days  int  declare @full_upd  bigint = 0
	--declare @days  int =10 declare @full_upd  bigint = 0
	if @days = -1
	begin
	--drop table if exists _request_log
	--select * into _request_log from _request
	-- exec msdb.dbo.sp_start_job  @job_name= 'Analytics._request_product 7:00 each 5 min', @step_name = 'Analytics._request_product 7:00 each 5 min'
	drop table if exists #log
	select a.* into #log from _request a 

	left join _request_log b on a.guid=b.guid and a.row_updated=b.row_updated
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
	drop table if exists #status	 
	 select  * into #status from (
	select null row_id, null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=0,  eventId_lk= 358 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 358 ,  eventOrder = null, source = 'lk'   union  	
	select null row_id, null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=0,  eventId_lk= 19 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, null                        status_crm, 'Переподписан 1 пак' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 19 ,  eventOrder = null, source = 'lk'   union  	
	select null row_id, null                        status_crm, 'Перезапрос 1 пак' eventName , NULL  islkk , isPtsEvent=0,  eventId_lk= 3 ,  eventOrder = null, source = 'lk'   union  	
	select null  row_id, null                        status_crm, 'Перезапрос 1 пак' eventName , NULL  islkk , isPtsEvent=1,  eventId_lk= 3 ,  eventOrder = null, source = 'lk'   union  	
 	select 1  row_id, null                        status_crm, 'Анкета' eventName , 1  islkk , isPtsEvent=0,  eventId_lk= 68 ,  eventOrder = 1, source = 'lk'   union  	
	select 2  row_id, null                        status_crm, 'Анкета' eventName, 1  islkk , is_pts=0,  lk_id= 69 ,  status_order = 1, source = 'lk'   union  	
	select 3  row_id, null                        status_crm, 'Паспорт' eventName, 1  islkk , is_pts=0,  lk_id= 70 ,  status_order = 2, source = 'lk'   union  	
	select 4  row_id, null                        status_crm, 'Фотографии' eventName, 1  islkk , is_pts=0,  lk_id= 70 ,  status_order = 3, source = 'lk'   union  
	select 5  row_id, null                        status_crm, 'Паспорт' eventName, 1  islkk , is_pts=0,  lk_id= 71 ,  status_order = 2, source = 'lk' union  
	select 6  row_id, null                        status_crm, 'Фотографии' eventName, 1  islkk , is_pts=0,  lk_id= 72 ,  status_order = 3, source = 'lk' union  
	select 7  row_id, null                        status_crm, 'Подписание первого пакета' eventName, 1  islkk , is_pts=0,  lk_id= 73 ,  status_order = 4, source = 'lk' union  
	select 8  row_id, 'Верификация КЦ'            status_crm, 'Call1' eventName, 1  islkk , is_pts=0,  lk_id= 73  ,  status_order = 4.5, source = 'lk' union  
	select 9  row_id, 'Предварительоне одобрение' status_crm, 'О работе и доходе' eventName, 1  islkk , is_pts=0,  lk_id= 74 ,  status_order = 5, source = 'lk' union  
	select 10 row_id, 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 1  islkk , is_pts=0,  lk_id= 75 ,  status_order = 6, source = 'lk' union  
	select 11 row_id, 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 1  islkk , is_pts=0,  lk_id= 416 ,  status_order = 6, source = 'lk' union  
	select 12 row_id, 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 0  islkk , is_pts=0,  lk_id= 417 ,  status_order = 6, source = 'lk' union  
	select 13 row_id, 'Предварительоне одобрение' status_crm, 'Ожидание одобрения' eventName, 1  islkk , is_pts=0,   lk_id= 76 ,  status_order = 7, source = 'lk' union  
	select 14 row_id, 'Одобрено'                  status_crm, 'Выбор предложения' eventName, 1  islkk , is_pts=0,   lk_id= 77 ,  status_order = 8, source = 'lk' union  
	select 15 row_id, 'Одобрено'                  status_crm, 'Подписание договора' eventName, 1  islkk , is_pts=0,   lk_id= 78 ,  status_order = 9, source = 'lk'  union  
	select 16 row_id,  null                       status_crm, 'Анкета' eventName, 0  islkk , is_pts=0, lk_id= 90  ,  status_order = 1, source = 'lk'   union  	 
	select 17 row_id,  null                       status_crm, 'Анкета' eventName, 0  islkk , is_pts=0, lk_id= 91  ,  status_order = 1, source = 'lk'   union  	 
	select 18 row_id,  null                       status_crm, 'Паспорт' eventName, 0  islkk , is_pts=0, lk_id= 92  ,  status_order = 2, source = 'lk'   union  	 
	select 19 row_id,  null                       status_crm, 'Фотографии' eventName, 0  islkk , is_pts=0, lk_id= 92  ,  status_order = 3, source = 'lk'   union  	 
	select 20 row_id,  null                       status_crm, 'Паспорт' eventName, 0  islkk , is_pts=0, lk_id= 93  ,  status_order = 2, source = 'lk' union  
	select 21 row_id,  null                       status_crm, 'Фотографии' eventName, 0  islkk , is_pts=0, lk_id= 94  ,  status_order = 3, source = 'lk' union  
	select 22 row_id,  null                       status_crm, 'Подписание первого пакета' eventName, 0  islkk , is_pts=0, lk_id= 95  ,  status_order = 4, source = 'lk' union  
	select 23 row_id, 'Верификация КЦ'            status_crm, 'Call1' eventName, 0  islkk , is_pts=0, lk_id= 95  ,  status_order = 4.5, source = 'lk' union  
	select 24 row_id, 'Предварительоне одобрение' status_crm, 'О работе и доходе' eventName, 0  islkk , is_pts=0, lk_id= 96  ,  status_order = 5, source = 'lk' union  
	select 25 row_id, 'Предварительоне одобрение' status_crm, 'Способ выдачи' eventName, 0  islkk , is_pts=0, lk_id= 97  ,  status_order = 6, source = 'lk' union  
	select 26 row_id, 'Предварительоне одобрение' status_crm, 'Ожидание одобрения' eventName, 0  islkk , is_pts=0, lk_id= 98  ,   status_order = 7, source = 'lk' union  
	select 27 row_id, 'Одобрено'                  status_crm, 'Выбор предложения' eventName, 0  islkk , is_pts=0, lk_id= 99  ,  status_order = 8, source = 'lk' union  
	select 28 row_id, 'Одобрено'                  status_crm, 'Подписание договора' eventName, 0  islkk , is_pts=0, lk_id= 100 ,    status_order = 9, source = 'lk' union 
	select 29 row_id, 'Заем выдан' as status_crm,   'Заем выдан' eventName, null  islkk,is_pts=0, lk_id= null	  ,  status_order =16	, source = 'lk' union



	select 30 row_id, null       as status_crm,   'Переход на калькулятор ПТС' eventName, 0  islkk,   is_pts=1, lk_id= 79	  ,  status_order =1	, source = 'lk' union  
	select 31 row_id, null       as status_crm,   'Переход на Анкету ПТС' eventName, 0  islkk, is_pts=1, lk_id= 80	  ,  status_order =2	, source = 'lk' union  			
	select 32 row_id, null       as status_crm,   'Переход на Анкету ПТС' eventName, 1  islkk, is_pts=1, lk_id= 442	  ,  status_order =2	, source = 'lk' union  			
	select 32 row_id, null       as status_crm,   'Переход на Анкету ПТС' eventName, 1  islkk, is_pts=1, lk_id= 512	  ,  status_order =2	, source = 'lk' union  			
	select 33 row_id, null       as status_crm,   'Открытие слота 2-3 стр паспорта ПТС' eventName, 0  islkk, is_pts=1, lk_id= 81	  ,  status_order =3	, source = 'lk' union  
	select 34 row_id, null       as status_crm,   'Открытие слота 2-3 стр паспорта ПТС'eventName, 1  islkk, is_pts=1, lk_id= 438	  ,  status_order =3	, source = 'lk' union  
	select 35 row_id, null       as status_crm,   'Загрузка 2-3 стр паспорта ПТС' eventName, null  islkk, is_pts=1, lk_id= 376	  ,  status_order =4	, source = 'lk' union  		
	select 36 row_id, null       as status_crm,   'Переход на 1 пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 82	  ,  status_order =5	, source = 'lk' union  				   
	select 37 row_id, null       as status_crm,   'Переход на 1 пакет ПТС' eventName, 1  islkk,is_pts=1, lk_id= 441	  ,  status_order =5	, source = 'lk' union  			       
	select 38 row_id, null       as status_crm,   'Подписание 1 пакета ПТС' eventName, null  islkk,is_pts=1, lk_id= 1	  ,  status_order =6	, source = 'lk' union  				
	select 39 row_id, null       as status_crm,   'Подписание 1 пакета ПТС' eventName, null  islkk,is_pts=1, lk_id= 315	  ,  status_order =6	, source = 'lk' union  			   
	select 40 row_id, null       as status_crm,   'Переход на экран Фото паспорта клиента ПТС' eventName, 0  islkk,is_pts=1, lk_id= 83	  ,  status_order =7	, source = 'lk' union  		
	select 41 row_id, null       as status_crm,   'Переход на экран Фото паспорта клиента ПТС' eventName, 1  islkk,is_pts=1, lk_id= 432	  ,  status_order =7	, source = 'lk' union  		
	select 42 row_id, null       as status_crm,   'Переход на экран с дополнительной информацией ПТС' eventName, 0  islkk,is_pts=1, lk_id= 84	  ,  status_order =8	, source = 'lk' union  		
	select 43 row_id, null       as status_crm,   'Переход на экран с дополнительной информацией ПТС' eventName, 1  islkk,is_pts=1, lk_id= 444	  ,  status_order =8	, source = 'lk' union  		
	select 44 row_id, null       as status_crm,   'Переход на экран с фото документов авто' eventName, 0  islkk,is_pts=1, lk_id= 85	  ,  status_order =9	, source = 'lk' union  	 
	select 45 row_id, null       as status_crm,   'Переход на экран с фото документов авто' eventName, 1  islkk,is_pts=1, lk_id= 434	  ,  status_order =9	, source = 'lk' union         
	select 46 row_id, null       as status_crm,   'Переход на экран Способ выдачи ПТС' eventName, 0  islkk,is_pts=1, lk_id= 86	  ,  status_order =10	, source = 'lk' union  		 
	select 47 row_id, null       as status_crm,   'Переход на экран Способ выдачи ПТС' eventName, 1  islkk,is_pts=1, lk_id= 431	  ,  status_order =10	, source = 'lk' union  		 
	select 48 row_id, null       as status_crm,   'Карта привязана ПТС' eventName, null  islkk,is_pts=1, lk_id= 17	  ,  status_order =11	, source = 'lk' union  				     
	select 49 row_id, null       as status_crm,   'Переход на фото авто ПТС' eventName, 0  islkk,is_pts=1, lk_id= 87	  ,  status_order =12	, source = 'lk' union  			     
	select 50 row_id, null       as status_crm,   'Переход на фото авто ПТС' eventName, 1  islkk,is_pts=1, lk_id= 435	  ,  status_order =12	, source = 'lk' union  			     
	select 51 row_id, null       as status_crm,   'Отправлена полная заявка ПТС' eventName, null  islkk,is_pts=1, lk_id= 8	  ,  status_order =12.5	, source = 'lk' union  				     
	select 51 row_id, 'Одобрено' as status_crm,   'Финально одобрен ПТС' eventName, 0  islkk,is_pts=1, lk_id= 8	  ,  status_order =13	, source = 'lk' union  				     
	select 52 row_id, 'Одобрено' as status_crm,   'Переход на второй пакет ПТС' eventName, 0  islkk,is_pts=1, lk_id= 89	  ,  status_order =14	, source = 'lk' union  			     
	select 53 row_id, 'Одобрено' as status_crm,   'Переход на второй пакет ПТС' eventName, 1  islkk, is_pts=1, lk_id= 428	  ,  status_order =14	, source = 'lk' union  		     
	select 54 row_id, 'Одобрено' as status_crm,   'Подписание второго пакета ПТС' eventName, 0  islkk,is_pts=1, lk_id= 2	  ,  status_order =15	, source = 'lk' union  		     
	select 55 row_id, 'Одобрено' as status_crm,   'Подписание второго пакета ПТС' eventName, 0  islkk,is_pts=1, lk_id= 361	  ,  status_order =15	, source = 'lk' union    	     
	select 56 row_id, 'Заем выдан' as status_crm, 'Заем выдан' eventName, null  islkk,is_pts=1, lk_id= null	  ,  status_order =16	, source = 'lk' 
				) x

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

	select number number , count(*) prolongationCnt, min(date) prolongationFirstDate into #prolongation from v_prolongation  
	group by number

	--select * from 	#prolongation


	--drop table if exists #auto_apr
								  
	--select distinct a.[Номер заявки] number into #auto_apr from [Отчет Время статусов верификации] a


	--where [Время Затрачено В работе]=0		  and  a.Статус='Верификация клиента'
	--order by a.Номер desc
	drop table if exists #requests_crm
	select number, СрокЛьготногоПериода freeTermDays into #requests_crm  from v_request_crm where СрокЛьготногоПериода>0  and created >=dateadd(day, -100, @date )

	;with v  as (select *, row_number() over(partition by number order by (select null)) rn from #requests_crm  ) delete from v where rn>1

	 drop table if exists #v_fa
 
	 select number, issued, closed,approved, ispts, ispdl , isInstallment isInst, phone, returnType3, issuedSum ,  interestRate  interestRate ,  isDubl  isDubl into #v_fa from v_fa  a--select_ta
	 where call1 >=@date 
   


	 drop table if exists #v_request
	 select number number 
  
	, case  z.ТипПродуктаПервоначальный  when 'Installment' then 'INST' else  z.ТипПродуктаПервоначальный end  +'_initial'	  productTypeInitial	 
    	  
	 , z.guid guid
	 , z.created created
	 , z.Телефон phone
	, z.feodor_request_Id  feodor_requestId
   
	, z.СтатусЗаявки status_crm
	, z.term_days  termDays
 
	,  z.ispts   ispts 
	,  z.ispdl   ispdl 
	,  z.isInstallment   isInst 
	,  z.call1approved call1approved
	,  z.call1 call1
	,  z.checking checking
	,  z.Call2 call2
	,  z.[Call2 accept] call2Approved
	,  z.[Верификация документов клиента] clientVerification
	,  z.[Одобрены документы клиента] clientApproved
	,  z.[Верификация документов] carVerificarion
	,  z.approved approved
	,  z.ContractSigned ContractSigned
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
	,   z.birthday  birthday  
	,   z.lk_request_id lk_requestId
	,   КодДоговораЗайма loanNumber
 , z.fioBirthday fioBirthday
 , z.passportSerialNumber  passportSerialNumber

 , z.carBrand
 , z.carModel
 , z.carYear
 , z.declineReason


	 into #v_request from v_request z
	 where created>= @date
  

	 update a set a.lk_requestid   = b.id from #v_request a join v_request_lk b on a.number=b.number and a.lk_requestid is null
	 update a set a.feodor_requestId   = b.id from #v_request a join v_request_feodor b on a.number=b.number and a.feodor_requestId is null
	 update a set a.feodor_requestId   = b.id from #v_request a join v_request_feodor b on a.guid=b.IdExternal and a.feodor_requestId is null

	 

	  --select * from #v_request where number='140315540002  '
	 delete from  #v_request where guid is null
 
	drop table if exists #loans
	--select issued [Заем выдан]  ,  issuedSum сумма  ,  closed [Заем погашен],  phone  Телефон, number  , isPts, ispdl,  case when ispdl=1 then 'pdl' when isInstallment=1 then 'inst' when isPts=1 then 'pts' end product_type  into #loans from #v_fa
	--where issued is not null
	--insert into 	 #loans
	select  
	  isnull( nullif( a.fioBirthday, '   0001.01.01') ,  b.fioBirthday)  fioBirthday
	 , isnull(  nullif( a.passportSerialNumber , '')  ,  b.passportSerialNumber)  passportSerialNumber
	 , client_phone  clientPhone
	 , client_id clientId
	, isnull(  b.issued  , a. issued )   issued 
	, isnull( isnull(  b.closed  , a. closed ) , GETDATE() ) closedIsnullNow

	,  sum      , isnull(  b.closed  , a. closed )  closed  , a.phone  
	, isnull( b.call1 , dateadd(second, -1,  isnull(  b.issued  , a. issued )  )) call1
	, b.created
	, a.number loanNumber,  a.isPts, a.ispdl ,  case when a.ispdl=1 then 'PDL' when a.isInstallment=1 then 'INST' when a.isPts=1 then 'PTS' end productType   
	, isnull( b.rbp, 'NotRBP') rbp
	into #loans 
	
	from mv_loans	a 
	left join _request b on a.number=try_cast(try_cast(  b.number  as bigint) as nvarchar(30))


	
	--select * from #loans

	  update a set a.issued = dateadd(second, 2,  created ) , a. call1 =  dateadd(second, 1,  created ) from #loans a where issued < created and cast( issued  as date)  = cast(created  as date) 
	  update a set a.closed = dateadd(second, 1,  issued ) from #loans a where closed < issued and cast( issued  as date)  = cast(closed  as date) 
	  update a set a.created = dateadd(second, -1,  call1 ) from #loans a where call1 < created --and cast( issued  as date)  = cast(closed  as date) 

	--where [Номер заявки] not in (
	--	  select number from #loans
	--)

	--update a set a.[Заем погашен]=b.closed from #loans a join mv_loans b on a.number=b.number and a.[Заем погашен] is null and b.closed is not null

	drop table if exists #requests_lk

	select z.guid	  guid
	, z.lk_requestId id
	,    z.created created 
	,    isnull(  isnull(r.num_1c	, z.number)  , l.loanNumber) number
	,    case when  z.isInst is not null then  z.isInst else  case when l.isPts=1 then 0 when l.isPts=0 and l.ispdl=0 then 1 end end  isInst
	, 	  isnull( b.name_1c, 'CMR')	origin
	, isnull ( isnull ( nullif( z.phone , ''), nullif( r.client_mobile_phone , '')  ) , nullif( l.phone, '') ) 	phone
	--, r.lcrm_id leadId_lcrm

	, isnull(l.productType,  case	
	when z.ispts = 1 then 'PTS'
	when z.ispdl = 1 then 'PDL'
	when z.ispdl = 0 and z.ispts=0 then 'INST'
	when product_types_id = 1 then 'PTS'
	when product_types_id = 2 then 'INST'
	when product_types_id = 3 then 'PDL'
 
	end ) [productType]
	, productTypeInitial
	, pr.prolongationCnt	  
	, pr.prolongationFirstDate  
	, z.feodor_requestId
	, ispts = case when z.isInst=1	or z.isPdl=1  or  product_types_id in (2,3)	  then 0 else 1 end 
	, r.client_total_monthly_income monthlyIncome
 
	,z.status_crm
	,z.termDays   
	, rcrm.freeTermDays  freeTermDays
	, case when z.ispdl=1 then dateadd(day, z.termDays,   z.issued) end closedPlanDate
	--, case when z.approved is not null and   pr1.number is not null then 1 when   z.approved is not null then 0 end isAutomaticApprove

	,isnull( l.call1, z.call1 )   call1
	, z.call1approved
	, z.checking
	, z.call2
	, z.call2Approved
	, z.clientVerification
	, z.clientApproved
	, z.carVerificarion
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
	, #v_fa.interestRate
	, isnull(z.clientId , l.clientId) clientId
	,  isnull(l.fioBirthday , z.fioBirthday ) fioBirthday	
	,  isnull(l.passportSerialNumber , z.passportSerialNumber ) passportSerialNumber	

, z.carBrand
, z.carModel
, z.carYear
, z.declineReason
, r.request_source_guid parentGuid
, r.code code

	into #requests_lk	--select top 100 * 
	from #v_request z 
	left join stg._lk.requests r  on z.lk_requestid=r.id  
	left join stg._LK.requests_origin b	   on r.requests_origin_id=b.id
	 left join #prolongation pr on pr.number=z.loanNumber
	 --left join #auto_apr pr1 on pr1.number=z.number 
 
	 left join #requests_crm rcrm on rcrm.number=r.num_1c

	 left join #v_fa on #v_fa.number=r.num_1c
	 left join #loans l on l.loannumber=z.loanNumber  
	 --where isnull( r.id , - abs(checksum(l.loanNumber) ) ) in (select id from #ids)


	;with v  as (select *, row_number() over(partition by guid order by (select null)) rn from #requests_lk ) delete from v where rn>1

	
	  update a set a.issued = dateadd(second, 2,  created ) , a. call1 =  dateadd(second, 1,  created ) from #requests_lk a where issued < created and cast( issued  as date)  = cast(created  as date) 
	  update a set a.closed = dateadd(second, 1,  issued ) from #requests_lk a where closed < issued and cast( issued  as date)  = cast(closed  as date) 
	  update a set a.created = dateadd(second, -1,  call1 ) from #requests_lk a where call1 < created --and cast( issued  as date)  = cast(closed  as date) 
	  update a set a.call1 = dateadd(second, -1,  issued ) from #requests_lk a where issued is not null and call1 is null

	  --select * from  #requests_lk where  issued<call1
	  --select * from  #requests_lk where  issued is not null and call1 is null
	 

			drop table if exists #request_client 
			select id,    b.clientId  , cast( 2.0 as float) priority into #request_client from  #requests_lk a
			 join #loans b on (b.fioBirthday=a.fioBirthday ) and b.issued<= isnull(a.call1, a.created )
			union all
			select id,    b.clientId  , cast( 1.5 as float) priority  from  #requests_lk a
			 join #loans b on (b.passportSerialNumber=a.passportSerialNumber ) and b.issued<= isnull(a.call1, a.created )
			union all
			select id, b.clientId  , 4 priority   from  #requests_lk a
			 join #loans b on ( a.phone=b.phone)and b.issued<= isnull(a.call1, a.created )
			union all
			select id, b.clientId  , 3  from  #requests_lk a
			 join #loans b on ( a.phone=b.clientPhone ) and b.issued<= isnull(a.call1, a.created )
			union all
			select id, a.clientId , 1 priority   from  #requests_lk a join #loans b on b.clientId=a.clientId and b.issued<= isnull(a.call1, a.created )
			where a.clientId is not null

			drop table if exists #request_client_rn
			--select * from #request_client
			;with v  as (select *, row_number() over(partition by id order by priority ) rn from #request_client )
			select * into  #request_client_rn from v where rn=1
 

	 drop table if exists #request_event_feodor

	select a.id 
	--, max(a.ДатаЗаявки				 ) ДатаЗаявки
	--, max(a.ТипКредитногоПродукта	 ) ТипПРодукта
	, min(case when cast(c.code as bigint) = 2402 then dateadd(hour, 3, b.CreatedOn) end ) _uprid
	, min(case when cast(c.code as bigint) = 2403 then dateadd(hour, 3, b.CreatedOn) end ) _upridYes
	, min(case when cast(c.code as bigint) = 2701 then dateadd(hour, 3, b.CreatedOn) end ) _upridGibddYes
	, min(case when cast(c.code as bigint) = 2703 then dateadd(hour, 3, b.CreatedOn) end ) _upridFnsYes
	, min(case when cast(c.code as bigint) in ( 2703 , 2701)  then dateadd(hour, 3, b.CreatedOn) end ) _upridFnsGibddYes
	, min(case when cast(c.code as bigint) = 2404 then dateadd(hour, 3, b.CreatedOn) end ) upridNo
	, min(case when cast(c.code as bigint) = 2750 then dateadd(hour, 3, b.CreatedOn) end )  _2750 
	, min(case when cast(c.code as bigint) = 2751 then dateadd(hour, 3, b.CreatedOn) end )  _2751 
 
	 into #request_event_feodor

	from  #requests_lk a
	left join Stg._fedor.core_ClientRequestExternalEventHistory b on a.feodor_requestId=b.ClientRequestId 
	left join Stg._fedor.dictionary_ClientRequestExternalEvent c on c.Id=b.ClientRequestExternalEventId
	--  where a.ispts=0
	group by a.id

 

 --select * from #request_event_feodor
 --select * from Stg._fedor.dictionary_ClientRequestExternalEvent where  cast(code as bigint) = 2751
 --select * from  Stg._fedor.core_ClientRequestExternalEventHistory  where  ClientRequestExternalEventId='0B4FCD8A-801B-4BDC-A3F0-D81FBDE6B617'
 --select feodor_requestId from  #requests_lk

	 drop table if exists #requests_lk2

	 select a.number,  a.id, a.ispts, a.created , a.issued, a.approved, a.call1approved, a.call1, a.phone , b.returnType3 
	 , isnull( a.call1 ,a.created    ) call1IsnullCreated
	, c.clientId 
 
	 into #requests_lk2  
 
	 from #requests_lk a 
	 left join #v_fa b on a.number=b.number
	 left join #request_client_rn c on c.id=a.id



	drop table if exists #t2

	select s.eventName eventName ,e.id eventId, r.number , re.created_at created, r.id id, s.eventOrder  , r.ispts isPts, s.islkk isLkk  into #t2 from stg._LK.events	  e
	join Stg._LK.requests_events re on re.event_id=e.id
	join #requests_lk2 r  on r.id=re.request_id
	 join  #status   s on s.eventId_lk=e.id and r.ispts=s.isPtsEvent
	 where re.created_at >=@date
	 insert into #t2
	 select s.eventName, null id, a.number, a.issued , a.id, s.eventOrder , a.ispts, s.islkk from #requests_lk2 a join #status s on a.ispts=s.isPtsEvent and s.eventOrder=16 and a.issued is not null


	 delete a from #t2 a join #requests_lk2 b on a.id=b.id and a.eventOrder >=13 and a.isPts=1 and b.approved is null

	 --where r.is_installment=1


	 --select *
	 --from #t2 a
	 --where eventId=512
	 --left join  #t2 b on b.eventOrder= 

	drop table if exists  #t2_



					 
	select 
		a.eventName 
	,   a.eventId 
	,   a.number 
	,   a.created 
	,   a.id 
	,   a.ispts 
	,   a.eventOrder 
	,   0 isFake
	,   isLkk isLkk
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
	, row_number() over(partition by a.id ,  b.eventOrder  order by  dateadd(second, -b.eventOrder,  a.created )  ) rn
	from 

	#t2 a 
	join 	(select distinct eventOrder eventOrder,  isPtsEvent from  #status) b on a.eventOrder>b.eventOrder and a.ispts=b.isPtsEvent
	left join 	 #t2 c on a.id=c.id and b.eventOrder=c.eventOrder
	where c.id is  null
	) a
	where rn=1

update a set a.eventName = b.eventName from #t2_ a join #status b on a.eventOrder=b.eventOrder and a.isPts=b.isPtsEvent and a.eventName is null


;with v  as (select *, row_number() over(partition by id, eventOrder  order by created  ) rn from #t2_ ) delete from v where rn>1 and eventOrder is not null

--select * from #t2_
--where eventOrder is null

--create index t on _request_event (id)


--drop table if exists _request_event 
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
delete a from  _request_event a join #t2_ on a.id=#t2_.id


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
	from #t2_ end



	--select * from #t2 where id=3431541

--select * from dwh where table_name= '_request_event'
--ALTER TABLE Analytics.dbo.[_request_event] ALTER COLUMN created datetime2(0)	--select * from #t2_				

	--where request_id = 1607487
	--order 					by  Дата

	--drop table if exists #t3

	--select *, 'lk' t  into  #t3 
	--from #t2_
		   

	--		   if @recreate=1 begin

	--drop table if exists _birs.[product_report_status_details]
	--select *, 'lk' t  into _birs.[product_report_status_details] from #t2_
	--end


	--delete from _birs.[product_report_status_details]
	--<?query --

	--select top 100 * from _birs.[product_report_status_details]
	--insert into _birs.[product_report_status_details]
	--select *, 'lk' t  from #t2_
  
	drop table if exists #t4

	--select * from stg._lk.events

	select aa.id  id 
	,  max(case when eventName like '%ЛКК%' then 'ЛКК,' else '' end) +
	 max(case when eventName like '%МП%' then 'МП,' else '' end) +   
	 max(case when a.id in ( 91, 69, 70, 92 ) then 'repeated,' else '' end) +   
	  string_agg( case when isFake=1 then '-' else '' end+ cast(eventOrder as nvarchar(100)   )   , ', ') within  group (order  by eventOrder,  a.created ) eventDesc  
	 , isnull(cast(max(eventOrder) as float),cast(max(case when aa.issued is not null then 999 else 0 end) as float)) eventLast									 
 
	, min(case when a.ispts=0 and eventOrder=1 then a.created end)   _profile 
	, min(case when a.ispts=0 and eventOrder=2 then a.created end)   _passport  
	, min(case when a.ispts=0 and eventOrder=3 then a.created end)   _photos 
	, min(case when a.ispts=0 and eventOrder=4 then a.created end)   _pack1 
	, min(case when a.ispts=0 and eventOrder=4.5 and aa.call1 is not null         then a.created end)  _call1 -- [Call 1],
	, min(case when a.ispts=0 and eventOrder=5 and aa.[call1Approved] is not null then a.created end)  _workAndIncome -- [О работе и доходе],
	, min(case when a.ispts=0 and eventOrder=6 and aa.[call1Approved] is not null then a.created end)  _cardLinked -- [Добавление карты],
	, min(case when a.ispts=0 and eventOrder=7 and aa.[call1Approved] is not null then a.created end)  _approvalWaiting -- [Одобрение],
	, min(case when a.ispts=0 and eventOrder=8 and aa.[call1Approved] is not null and aa.approved is not null then a.created end)  _offerSelection -- [Выбор предложения],
	, min(case when a.ispts=0 and eventOrder=9 and aa.[call1Approved] is not null and aa.approved is not null then a.created end)  _contractSigning -- [Подписание договора],

	 ,min(case when a.ispts=1 and eventOrder= 1	then a.created end)                                   _calculatorPts
	 ,min(case when a.ispts=1 and eventOrder= 2	then a.created end)                                   _profilePts
	 ,min(case when a.ispts=1 and eventOrder= 3	then a.created end)                                   _docPhotoPts
	 ,min(case when a.ispts=1 and eventOrder= 4	then a.created end)                                   _docPhotoLoadedPts
	 ,min(case when a.ispts=1 and eventOrder= 5	then a.created end)                                   _pack1Pts
	 ,min(case when a.ispts=1 and eventOrder= 6	then a.created end)                                   _Pack1SignedPts
	 ,min(case when a.ispts=1 and eventOrder= 7	then a.created end)                                   _clientAndDocPhoto2Pts
	 ,min(case when a.ispts=1 and eventOrder= 8	then a.created end)                                   _additionalInfoPTS
	 ,min(case when a.ispts=1 and eventOrder= 9	then a.created end)                                   _carDocPhotoPTS
	 ,min(case when a.ispts=1 and eventOrder= 10	then a.created end)                               _payMethodPts
	 ,min(case when a.ispts=1 and eventOrder= 11	then a.created end)                               _cardLinkedPTS
	 ,min(case when a.ispts=1 and eventOrder= 12	then a.created end)                               _CarPhotoPTS
	 ,min(case when a.ispts=1 and eventOrder= 12.5	then a.created end)                               _fullRequestPTS
	 ,min(case when a.ispts=1 and eventOrder= 13 and aa.approved is not null	then a.created end)   _ApprovalPTS
	 ,min(case when a.ispts=1 and eventOrder= 14 and aa.approved is not null	then a.created end)   _pack2PTS
	 ,min(case when a.ispts=1 and eventOrder= 15 and aa.approved is not null	then a.created end)   _pack2SignedPTS
    , min(case when a.eventId in ( 3 ) then a.created  end)       _pack1resigning 
    , min(case when a.eventId in ( 19, 358 ) then a.created  end) _pack1resigned
	into #t4	  -- select *   
	from #requests_lk2 aa 
	left join #t2_   a on aa.id=a.id
	--left join #v_fa b on b.number=a.number

	--select * from #t4
	--where

	group by  aa.id
	--order by 	 


	--select * from #t4



	drop table if exists #eventLast
	select a.id id, min(b.created ) eventLastCreated, min(b.EventName ) Event  into #eventLast from #t4 a
	join #t2_ b on a.id=b.id and a.eventLast=b.eventOrder
	group by  a.id





--	select a.id, a.number, a.created, a.origin, a.[_carDocPhotoPTS],a.[_payMethodPts],  a.returnType, a.eventDesc, a.eventLast, a.event , b.* from _request a
--left join v_request_field b on a.id=b.request_id and b.created between   a.[_carDocPhotoPTS] and  a.[_payMethodPts] --and 
--where [_carDocPhotoPTS] is not null and  a.[_carDocPhotoPTS] is not null
--order by a.created desc,  b.created


drop table if exists #requestTriggerTmp

select a.* into #requestTriggerTmp from    requestTrigger a 
join #requests_lk2 b on a.id=b.id


--select top 100 * from requestTrigger


;with v  as (select *, row_number() over(partition by id, isnull(cast( eventOrder aS FLOAT) , cast( -eventId aS FLOAT)) order by created  ) rn from #t2  ) --delete from v where rn>1

--select top 100 * from #requestTriggerTmp
insert into #requestTriggerTmp 
select   id, format(eventOrder, '00') , N'' , eventName, 'Id='+  format(eventId, '0') , '', created, -1     from v where rn=1

--select * from #requestTriggerTmp
--where id=3431541
--order by created


create nonclustered index index_1 on #requestTriggerTmp
(
id, created
)



drop table if exists #field 

select a.id id 
, nullif(count(distinct case when  b3.field like 'pts%' then b3.field  end )  ,  0) [_carDocPhotoPTScntPts] 
, nullif(count(distinct case when  b3.field like 'sts%' then b3.field  end )  ,  0) [_carDocPhotoPTScntSts] 
, nullif(count(distinct  b4.created    )  ,  0)    [_profilePTScntSurname] 
, nullif(count(distinct  b5.created    )  ,  0)    [_profilePTScntCarBrand] 
, nullif(count(distinct  b6.created    )  ,  0)    [_docPhotoPtsCnt] 

, min(l.Event  ) Event   
,  min(l.eventLastCreated) eventLastCreated
 
into #field

from #t4  a
 left join #requestTriggerTmp b3 on b3.isError>=0 and  a.id=b3.id and b3.created between   a.[_carDocPhotoPTS]        and  isnull(a.[_payMethodPts]      ,gETDATE())and b3.result='true' and  b3.event='Загрузка фото' --and 
left join #requestTriggerTmp b4 on  b4.isError>=0 and   a.id=b4.id and b4.created between   a._profilePts        and  isnull(a._docPhotoPts      ,gETDATE())and b4.result<>'' and  b4.event='Уход из фокуса' and b4.comment = '' and b4.field = 'Фамилия'  --and 
left join #requestTriggerTmp b5 on  b5.isError>=0 and a.id=b5.id and b5.created between   a._profilePts        and  isnull(a._docPhotoPts      ,gETDATE())and b5.result<>'' and  b5.event='Уход из фокуса' and b5.comment = '' and b5.field = 'Марка'    --and 
left join #requestTriggerTmp b6 on  b6.isError>=0 and a.id=b6.id and b6.created between   a._docPhotoPts        and  isnull(a._docPhotoLoadedPts      ,gETDATE()) and b6.result='true' and  b6.event='Загрузка фото' --and 
left join #eventLast   l on l.id = a.id
--left join #requestTriggerTmp tr on a.id=tr.id --and tr.created >= dateadd(minute, -5,  l.eventLastCreated )

   group by  a.id
 drop table if exists #eventLastTriggerDesc


 
;with v  as (select *,  datediff(minute, created,  lead(created) over(partition by id    order by created  ) ) dif from #requestTriggerTmp  ) --delete from v where rn>1
, requestTriggerCte as ( select *, case 
     when dif >=2*60*24 then N'
📅📅'  when dif >=60*24 then N'
📅' when   dif >=60*12  then N'
🌓' when   dif >=60  then N'
⌛'when   dif >=5  then N'
⏱'  when event = 'Заем выдан' then N'💲' when dif is null then  N'👋' else '' end addText from v )
--select * from v_

   select a.id
   
    , STRING_AGG('$ '+  format( tr.created, 'dd HH:mm:ss') + case when   tr.created=a.eventLastCreated then N' 💔' else ' ' end  +case when tr.isError=1 then N'🚨' when tr.isError=-1 then N'📥' else '' end+case when tr.field<>'step' then ' '+ cast( tr.field  as nvarchar(max)) else '' end  +' '+ tr.event 
 + case 
 when tr.field='step' then cast( ' '+tr.step as nvarchar(max)) else '' end
 
 + ' ' + isnull(tr.result, '') + case when tr.comment<>'' then ' ('+tr.comment+')' else '' end +case when tr.addText<> '' then addText else '' end , '
' ) within group(order by tr.created, iserror, step) [eventLastTriggerDesc] 
into #eventLastTriggerDesc
from #field a
left join  requestTriggerCte tr on a.id=tr.id  and  (tr.created >=   a.eventLastCreated   or tr.isError=-1)
--select * from v_request_field
   group by  a.id

   --select * from #eventLastTriggerDesc a
   --where a.id=3431541

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

	select a.id, a.number   
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
	 into #inst_an3
	from #requests_lk2 a 
	 left join  #loans b on a.clientid=b.clientid and b.issued<=a.call1IsNullCreated 
	 and try_cast( a.number as bigint)<>try_cast(  b.loanNumber  as bigint)
	 and  a.number  <>  b.loanNumber   

; 

drop table if exists #firstLoan
;with v  as (select *, row_number() over(partition by   id order by loanIssued) rn from #inst_an3 where loanIssued is not null  ) select * into #firstLoan  from v where rn=1


----select * from #firstLoan
--update a set a.firstLoanRbp = b.rbpLoan, a.firstLoanNumber = b.loanNumber from _request a join #firstLoan  b on b.id=a.id

	 --select * from #inst_an3 where number='01609053120002'
	 --select * from #inst_an3
	 --select * from #inst_an2
 
	drop table if exists 	  #inst_an2
	  select   
	  b.id, 
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
   
	 group by b.id   

	 
 



	 drop table if exists #next_loans
	 drop table if exists #costs
	 select number  number, marketingCosts   marketingCosts into #costs  from  v_request_costs

	  
	drop table if exists #t5
	select 
	 a.guid                                 
	,a.id                                 
	,      cast(a.created                          as date)	date
	,      a.created    
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
	, b._docPhotoPts
	, b._docPhotoLoadedPts
	, b._pack1Pts
	, b._pack1SignedPts _pack1SignedPts
	, b._clientAndDocPhoto2Pts _clientAndDocPhoto2Pts
	, b._additionalInfoPTS  _additionalInfoPTS 
	, b._carDocPhotoPTS
	, b._payMethodPts
	, b._cardLinkedPTS
	, b._carPhotoPTS _carPhotoPTS
	, b._fullRequestPTS _fullRequestPTS
	, b._ApprovalPTS 
	, b._pack2PTS
	, b._pack2SignedPTS

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
	  , a.isDubl
	  , isnull( c.clientId, a.clientId) clientId
	  , CASE
			WHEN a.ispts = 1 THEN
				CASE
					WHEN issued IS NOT NULL THEN 'Выдача денег'
					WHEN _pack2SignedPTS IS NOT NULL THEN 'Подписание второго пакета ПТС'
					WHEN _pack2PTS IS NOT NULL THEN 'Переход на второй пакет ПТС'
					WHEN _ApprovalPTS IS NOT NULL THEN 'Финальное одобрение ПТС'
					WHEN _fullRequestPTS IS NOT NULL THEN 'Отправлена полная заявка ПТС'
					WHEN _CarPhotoPTS IS NOT NULL THEN 'Переход на фото авто ПТС'
					WHEN _cardLinkedPTS IS NOT NULL THEN 'Карта привязана ПТС'
					WHEN _payMethodPts IS NOT NULL THEN 'Переход на экран Способ выдачи ПТС'
					WHEN _carDocPhotoPTS IS NOT NULL THEN 'Переход на экран с фото документов авто ПТС'
					WHEN _additionalInfoPTS IS NOT NULL THEN 'Переход на экран с дополнительной информацией ПТС'
					WHEN _clientAndDocPhoto2Pts IS NOT NULL THEN 'Переход на экран Фото паспорта ПТС'
					WHEN _Pack1SignedPts IS NOT NULL THEN 'Подписание 1 пакета ПТС'
					WHEN _pack1Pts IS NOT NULL THEN 'Переход на 1 пакет ПТС'
					WHEN _docPhotoLoadedPts IS NOT NULL THEN 'Загрузка 2-3 стр паспорта ПТС'
					WHEN _docPhotoPts IS NOT NULL THEN 'Открытие слота 2-3 стр паспорта ПТС'
					WHEN _profilePts IS NOT NULL THEN 'Переход на Анкету ПТС'
					WHEN _calculatorPts IS NOT NULL THEN 'Переход на калькулятор ПТС'
					ELSE NULL
				END
			ELSE
				CASE
					WHEN issued IS NOT NULL THEN 'Выдача денег'
					WHEN _contractSigning IS NOT NULL THEN 'Подписание договора'
					WHEN _offerSelection IS NOT NULL THEN 'Выбор предложения'
					WHEN _approvalWaiting IS NOT NULL THEN 'Одобрение'
					WHEN _cardLinked IS NOT NULL THEN 'Добавление карты'
					WHEN _workAndIncome IS NOT NULL THEN 'О работе и доходе'
					WHEN _call1 IS NOT NULL THEN 'Call 1'
					WHEN _pack1 IS NOT NULL THEN 'Подписание первого пакета'
					WHEN _photos IS NOT NULL THEN 'Фотографии'
					WHEN _passport IS NOT NULL THEN 'Паспорт'
					WHEN _profile IS NOT NULL THEN 'Анкета'
					ELSE NULL
				END
		END AS event   ,
		fioBirthday ,
		passportSerialNumber,
		a.carBrand , 
		a.carModel , 
		a.carYear, 
		a.parentGuid

		, b. _pack1resigning 
		, b. _pack1resigned
		, a.code  
		, a.declineReason  
	into #T5
	from      #requests_lk a
	left join #t4          b on a.id = b.id
	left join #inst_an2     c on a.id = c.id
	--left join #odobr d on d.number=a.number
	left join (select number number2, marketingCosts from  #costs ) e on a.number=e.number2

	--left join #next_loans2 nl on nl.Номер=a.number
 

 


	drop table if exists #next_request

	select a.guid,  x.number next_request_product , x.call1 next_request_product_dt
	, x1.number next_request_other_product_after_annul
	, x1.call1 next_request_other_product_after_annul_dt
	into #next_request from #T5 a
	outer apply (select top 1 number, call1 from   #T5 b where a.clientId=b.clientId and a.ispts=b.ispts and b.call1>a.closed order by b.call1 )  x
	outer apply (select top 1 number, call1 from   #T5 b where a.clientId=b.clientId and a.ispts<>b.ispts and b.call1>a.cancelled order by b.call1 )  x1




	--drop table if exists #dpd_closed
	--select number number
	--, max(case when date=cast( getdate() as date)  then dpd_begin_day end ) DpdBeginDay  

	--, max(case when date=closed then dpd_begin_day end ) closedDpdBeginDay  
 
	--, max(   dpd_begin_day   ) DpdMaxBeginDay  
 

	--into #dpd_closed from v_balance a --where date=closed
	--group by number


	drop table if exists #t6

		   select   
		   a.guid
	,      a.number 
	,      a.origin 
	,      a.productTypeInitial
	,      a.productType
	--,      a.isDubl  
	,      a.status_crm
	,      a.created 
	,      a.phone 
	,      a.declined    
	,      a.cancelled    
	,      a.rejected    
	,      a.returnType
	,      a.call1    
	,      a.call1approved    
	,      a.checking    
	,      a.call2    
	,      a.call2Approved    
	,      a.clientVerification    
	,      a.clientApproved    
	,      a.carVerificarion    
	,      a.approved    
	,      a.contractSigned    
	,      a.issued 					  	   
	,      a.closed
	,      a.firstSum 
	,      a.requestSum 
	,      a.approvedSum 
	,      a.issuedSum 
	,      a.interestRate
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



	, isnull( f.event, '$'+ a.event) event
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
	, a._docPhotoPts	
	, a._docPhotoLoadedPts	
	, a._pack1Pts	
	, a._pack1SignedPts	  
	, a._clientAndDocPhoto2Pts	
	, a._additionalInfoPTS	
	, a._carDocPhotoPTS	
	, a._payMethodPts	
	, a._cardLinkedPTS	
	, a._carPhotoPTS	  
	, a._fullRequestPTS	
	, a._approvalPTS  	
	, a._pack2PTS	
	, a._pack2SignedPTS	 
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

	,     a.[id] 
	, case 
	when b.user_agent like 'ios%' then 'ios' 
	when b.user_agent like 'Android%' then 'android' 
	 when ub.browser_name is not null then  ub.browser_name
	end browser
	, CASE 
			WHEN b.[user_Agent] LIKE 'Android%' 
				 AND CHARINDEX(',', b.[user_Agent]) > CHARINDEX('Android', b.[user_Agent]) + LEN('Android')
			THEN LTRIM(SUBSTRING(
				b.[user_Agent], 
				CHARINDEX('Android', b.[user_Agent]) + LEN('Android'), 
				CHARINDEX(',', b.[user_Agent]) - CHARINDEX('Android', b.[user_Agent]) - LEN('Android')
			))
			WHEN b.[user_Agent] LIKE 'IOS%' 
				 AND CHARINDEX(',', b.[user_Agent]) > CHARINDEX('IOS', b.[user_Agent]) + LEN('IOS')
			THEN LTRIM(SUBSTRING(
				b.[user_Agent], 
				CHARINDEX('IOS', b.[user_Agent]) + LEN('IOS'), 
				CHARINDEX(',', b.[user_Agent]) - CHARINDEX('IOS', b.[user_Agent]) - LEN('IOS')
			))
			ELSE ub.browser_version
		END AS browserVersion
, f._carDocPhotoPTScntPts
, f._carDocPhotoPTScntSts

, f. [_profilePTScntSurname] 
, f. [_profilePTScntCarBrand] 
, a.fioBirthday
, [_docPhotoPtsCnt]
, passportSerialNumber
,	a.carBrand , 
		a.carModel , 
		a.carYear, 
		a.parentGuid, 
 try_cast(left( isnull(try_cast( a.number as nvarchar(4000) ), 'guid='+ try_cast(a.guid as nvarchar(4000) ))+' '+isnull('('+ try_cast(a.productType +'-'+ a.origin as nvarchar(4000) ) +')', '(Null)') +'
'+ isnull(f1.[eventLastTriggerDesc] , ''), 4000) as nvarchar(4000))+case when a.code  is not null then N'

https://metrika.yandex.ru/stat/visor?&filter=%28ym%3Apv%3AURL%3D%40%2527%2F'+a.code+'%2527%29&id=35789815' else '' end  [eventLastTriggerDesc] 

,_pack1resigning 
, _pack1resigned
, fl.rbpLoan firstLoanRbp
, fl.loanNumber firstLoanNumber
, a.declineReason
		  into #t6
		  from #T5	a
		 -- left join #doubles b on a.id=b.id
		  left join #request_event_feodor uprid on uprid.id=a.id
		  left join #next_request next_request on next_request.guid=a.guid
	--	  left join #dpd_closed  dpd_closed on dpd_closed.number=a.number
			left join stg._lk.[request_pep] b on a.id=b.request_id
			left join userAgent_browser ub on ub.useragent=b.user_agent
			left join #field f  on f.id=a.id
			left join #eventLastTriggerDesc f1  on f1.id=a.id
	left join #firstLoan     fl on a.id = fl.id


			--select * from #t6

--some magic
	  update a set a._calculatorPts = call1 , a. _profilePts = call1 from #t6 a where ispts=1 and call1 is not null and _calculatorPts is null and _profilePts is null 
 


 

	  ;with v  as (select *, row_number() over(partition by guid order by id desc) rn from #t6   ) delete from v where rn>1

  
	drop table if exists #t7_changed
	select * into #t7_changed from #t6 where 1=0
  
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



 


--select * from #t7





--exec sp_select_except '#t7_changed', '_request', 'guid', '#t6'

--select * from #t7
--order by 1
--select * from #t7_changed
--order by 1



    INSERT INTO #t7_changed ([guid], [number], [origin], [productTypeInitial], [productType] , [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum],requestSum, [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast],eventLastCreated, [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS],   [_uprid], [_upridYes], _2750, [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], loanOrder, [loyalty], [loyaltyPts], [loyaltyBezzalog], firstLoanIssued, [firstLoanProductType],  [returnTypeByProduct], [clientId], [id], [browser], [browserVersion], [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts], [_profilePTScntSurname], [_profilePTScntCarBrand], fioBirthday, [_docPhotoPtsCnt], passportSerialNumber, carBrand, carModel, carYear, parentGuid, eventLastTriggerDesc,_pack1resigning 
, _pack1resigned
, firstLoanRbp
, firstLoanNumber
, declineReason
)
    SELECT [guid], [number], [origin], [productTypeInitial], [productType],   [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], requestSum, [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], eventLastCreated, [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS],    [_uprid], [_upridYes], _2750, [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], loanOrder, [loyalty], [loyaltyPts], [loyaltyBezzalog], firstLoanIssued, [firstLoanProductType],   [returnTypeByProduct], [clientId], [id], [browser], [browserVersion], [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts], [_profilePTScntSurname], [_profilePTScntCarBrand], fioBirthday, [_docPhotoPtsCnt], passportSerialNumber, carBrand, carModel, carYear, parentGuid, eventLastTriggerDesc,_pack1resigning 
, _pack1resigned
, firstLoanRbp
, firstLoanNumber
, declineReason

    FROM  #t6
    EXCEPT
    SELECT [guid], [number], [origin], [productTypeInitial], [productType],  [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], requestSum, [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], eventLastCreated, [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS],    [_uprid], [_upridYes], _2750, [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], loanOrder, [loyalty], [loyaltyPts], [loyaltyBezzalog], firstLoanIssued, [firstLoanProductType],  [returnTypeByProduct], [clientId], [id], [browser], [browserVersion], [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts], [_profilePTScntSurname], [_profilePTScntCarBrand], fioBirthday, [_docPhotoPtsCnt], passportSerialNumber, carBrand, carModel, carYear, parentGuid, eventLastTriggerDesc,_pack1resigning 
, _pack1resigned
, firstLoanRbp
, firstLoanNumber
, declineReason

    FROM _request
    WHERE _request.guid IN (
        SELECT guid
        FROM   #t6
    );
  
    --INSERT INTO #t7_changed ([guid], [number], [origin], [productTypeInitial], [productType], [isDubl], [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS], [isTakeUpManual], [_uprid], [_upridYes], [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], [loyalty], [loyaltyPts], [loyaltyBezzalog], [firstLoanProductType], [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [returnTypeByProduct], [clientId], [id], [browser], [browserVersion], [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts])
    --SELECT [guid], [number], [origin], [productTypeInitial], [productType], [isDubl], [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS], [isTakeUpManual], [_uprid], [_upridYes], [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], [loyalty], [loyaltyPts], [loyaltyBezzalog], [firstLoanProductType], [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [returnTypeByProduct], [clientId], [id], [browser], [browserVersion], [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts]
    --FROM  #t6
    --EXCEPT
    --SELECT [guid], [number], [origin], [productTypeInitial], [productType], [isDubl], [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS], [isTakeUpManual], [_uprid], [_upridYes], [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], [loyalty], [loyaltyPts], [loyaltyBezzalog], [firstLoanProductType], [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [returnTypeByProduct], [clientId], [id], [browser], [browserVersion], [_carDocPhotoPTScntPts], [_carDocPhotoPTScntSts]
    --FROM _request
    --WHERE _request.guid IN (
    --    SELECT guid
    --    FROM   #t6
    --);
 
   
    --INSERT INTO #t7_changed ([guid], [number], [origin], [productTypeInitial], [productType], [isDubl], [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS], [isTakeUpManual], [_uprid], [_upridYes], [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], [loyalty], [loyaltyPts], [loyaltyBezzalog], [firstLoanProductType], [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [returnTypeByProduct], [clientId], [id], [browser], [browserVersion])
    --SELECT [guid], [number], [origin], [productTypeInitial], [productType], [isDubl], [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS], [isTakeUpManual], [_uprid], [_upridYes], [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], [loyalty], [loyaltyPts], [loyaltyBezzalog], [firstLoanProductType], [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [returnTypeByProduct], [clientId], [id], [browser], [browserVersion]
    --FROM  #t6
    --EXCEPT
    --SELECT [guid], [number], [origin], [productTypeInitial], [productType], [isDubl], [status_crm], [created], [phone], [declined], [cancelled], [rejected], [returnType], [call1], [call1approved], [checking], [call2], [call2Approved], [clientVerification], [clientApproved], [carVerificarion], [approved], [contractSigned], [issued], [closed], [firstSum], [approvedSum], [issuedSum], [interestRate], [isPts], [isInst], [term], [termDays], [freeTermDays], [marketingCosts], [prolongationCnt], [prolongationFirstDate], [monthlyIncome], [closedPlanDate], [event], [eventLast], [eventDesc], [_profile], [_passport], [_photos], [_pack1], [_call1], [_workAndIncome], [_cardLinked], [_approvalWaiting], [_offerSelection], [_contractSigning], [_calculatorPts], [_profilePts], [_docPhotoPts], [_docPhotoLoadedPts], [_pack1Pts], [_pack1SignedPts], [_clientAndDocPhoto2Pts], [_additionalInfoPTS], [_carDocPhotoPTS], [_payMethodPts], [_cardLinkedPTS], [_carPhotoPTS], [_fullRequestPTS], [_approvalPTS], [_pack2PTS], [_pack2SignedPTS], [isTakeUpManual], [_uprid], [_upridYes], [_2751], [closedRequestByProduct], [closedHasRequestByProduct90d], [RequestAfterCancelled], [RequestAfterCancelledDt], [loyalty], [loyaltyPts], [loyaltyBezzalog], [firstLoanProductType], [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [returnTypeByProduct], [clientId], [id], [browser], [browserVersion]
    --FROM _request
    --WHERE _request.guid IN (
    --    SELECT guid
    --    FROM   #t6
    --);

--	if (select count(*) from _request)=0 
--begin
--insert into _request select  getdate() row_created, getdate() row_updated ,  *  from #t7 
--select 'reload - ok'
--return

--end


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

--return
;
 
if 1=0 
begin

select 'MERGE _request AS a  USING (SELECT * FROM #t7_changed ) AS b      ON a.guid = b.guid  WHEN MATCHED THEN  UPDATE SET 
a.[row_updated] = getdate()  ' union all
select * from (
select top 1000 case when column_name = 'row_updated' then '' else ',' end + 'a.['+column_name+'] = '+case 
when column_name like 'row_' + '%' then 'getdate() '
when column_name not in ('') then 'b.['+column_name+']'
 else 'case when a.['+column_name+'] is not null then a.['+column_name+'] else  b.['+column_name+']  end ' end  t
from dwh where  table_name='_request' and column_name <>'row_created' and column_name 
in (select column_name from dwh where db='tempdb' and table_name like '%' + '#t7_changed'  + '%' ) order by ordinal_position )  x union all
--select * from #t7_changed
select ' WHEN NOT MATCHED BY TARGET THEN INSERT (' union all
select '  row_created' union all
select '  ,row_updated' union all
select * from (
select top 1000 ',['+column_name+'] ' t from dwh where  table_name='_request'  and  column_name 
in (select column_name from dwh where db='tempdb' and table_name like '%' + '#t7_changed'  + '%' ) order by ordinal_position )  x  union all
select '  )         VALUES ( ' union all
select '  getdate()' union all
select '  ,getdate()' union all
--select ' ,b.['+column_name+'] ' from dwh where  table_name='_request' union all
select * from (
select top 1000 ','	 +case when column_name like 'row_' + '%' then 'getdate() ' else 'b.['+column_name+'] ' end t  from dwh where  table_name='_request'  and column_name 
in (select column_name from dwh where db='tempdb' and table_name like '%' + '#t7_changed'  + '%' ) order by ordinal_position   ) x union all 
select '  )'-- union all
 
 end 
;

MERGE _request AS a  USING (SELECT * FROM #t7_changed ) AS b      ON a.guid = b.guid  WHEN MATCHED THEN  UPDATE SET 
a.[row_updated] = getdate()  
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
,a.[_docPhotoPts] = b.[_docPhotoPts]
,a.[_docPhotoLoadedPts] = b.[_docPhotoLoadedPts]
,a.[_pack1Pts] = b.[_pack1Pts]
,a.[_pack1SignedPts] = b.[_pack1SignedPts]
,a.[_clientAndDocPhoto2Pts] = b.[_clientAndDocPhoto2Pts]
,a.[_additionalInfoPTS] = b.[_additionalInfoPTS]
,a.[_carDocPhotoPTS] = b.[_carDocPhotoPTS]
,a.[_payMethodPts] = b.[_payMethodPts]
,a.[_cardLinkedPTS] = b.[_cardLinkedPTS]
,a.[_carPhotoPTS] = b.[_carPhotoPTS]
,a.[_fullRequestPTS] = b.[_fullRequestPTS]
,a.[_approvalPTS] = b.[_approvalPTS]
,a.[_pack2PTS] = b.[_pack2PTS]
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
,a.[browser] = b.[browser]
,a.[browserVersion] = b.[browserVersion]
,a.[_carDocPhotoPTScntPts] = b.[_carDocPhotoPTScntPts]
,a.[_carDocPhotoPTScntSts] = b.[_carDocPhotoPTScntSts]
,a.[_profilePTScntSurname] = b.[_profilePTScntSurname]
,a.[_profilePTScntCarBrand] = b.[_profilePTScntCarBrand]
,a.fioBirthday = b.fioBirthday
,a.[_docPhotoPtsCnt] = b.[_docPhotoPtsCnt]
,a.passportSerialNumber = b.passportSerialNumber
,a.carBrand = b.carBrand
,a.carModel = b.carModel
,a.carYear = b.carYear
,a.parentGuid = b.parentGuid
,a.eventLastTriggerDesc = b.eventLastTriggerDesc
,a._pack1resigning = b._pack1resigning
,a._pack1resigned = b._pack1resigned
,a.firstLoanRbp = b.firstLoanRbp
,a.firstLoanNumber = b.firstLoanNumber
,a.declineReason = b.declineReason
 
 
 WHEN NOT MATCHED BY TARGET THEN INSERT (
  row_created
  ,row_updated
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
,[_docPhotoPts] 
,[_docPhotoLoadedPts] 
,[_pack1Pts] 
,[_pack1SignedPts] 
,[_clientAndDocPhoto2Pts] 
,[_additionalInfoPTS] 
,[_carDocPhotoPTS] 
,[_payMethodPts] 
,[_cardLinkedPTS] 
,[_carPhotoPTS] 
,[_fullRequestPTS] 
,[_approvalPTS] 
,[_pack2PTS] 
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
,[browser] 
,[browserVersion] 
,[_carDocPhotoPTScntPts] 
,[_carDocPhotoPTScntSts] 
,[_profilePTScntSurname] 
,[_profilePTScntCarBrand] 
,fioBirthday 
,[_docPhotoPtsCnt] 
,passportSerialNumber 
,carBrand 
,carModel 
,carYear 
,parentGuid 
,eventLastTriggerDesc 
,_pack1resigning 
, _pack1resigned
, firstLoanRbp
, firstLoanNumber
, declineReason
 


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
,b.[_docPhotoPts] 
,b.[_docPhotoLoadedPts] 
,b.[_pack1Pts] 
,b.[_pack1SignedPts] 
,b.[_clientAndDocPhoto2Pts] 
,b.[_additionalInfoPTS] 
,b.[_carDocPhotoPTS] 
,b.[_payMethodPts] 
,b.[_cardLinkedPTS] 
,b.[_carPhotoPTS] 
,b.[_fullRequestPTS] 
,b.[_approvalPTS] 
,b.[_pack2PTS] 
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
,b.[browser] 
,b.[browserVersion] 
,b.[_carDocPhotoPTScntPts] 
,b.[_carDocPhotoPTScntSts] 
,b.[_profilePTScntSurname] 
,b.[_profilePTScntCarBrand] 
,b.fioBirthday 
,b.[_docPhotoPtsCnt] 
,b.passportSerialNumber 
,b.carBrand 
,b.carModel 
,b.carYear 
,b.parentGuid 
,b.eventLastTriggerDesc 
,b._pack1resigning 
,b. _pack1resigned
,b. firstLoanRbp
,b. firstLoanNumber
,b. declineReason
  )
;

		declare @rc bigint = @@ROWCOUNT
		 
		 select @rc, 'updated'
 

 exec _request_dubl 



 return

 

 update request set 
 --  request.carBrand = b.carBrand 
 --,request.carModel = b.carModel 
 --,request.carYear = b.carYear 
 --,
 request.declineReason = b.declineReason 
 
 
 from _request request join v_request b  on request.guid=b.guid 

 --select max(len(declineReason)) from v_request

 --select * from #inst_an3
 --where number='1706227190001'

 --select * from _request --where number='17111214360005'
 --select returnType, clientId from _request where number='17111214360005'
 --select returnType, clientId from v_request where number='17111214360005'
 --select * from _request where clientid='C15896CF-08A4-11E8-A814-00155D941900'
 ----select * from #t7 


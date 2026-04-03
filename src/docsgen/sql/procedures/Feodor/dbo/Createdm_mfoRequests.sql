
--select * from  feodor.dbo.dm_mfoRequests
/*

select ClientRequestId
from 
feodor.dbo.dm_mfoRequests
group by ClientRequestId
having count(*)>1

*/
CREATE procedure [dbo].[Createdm_mfoRequests]
as
begin
	/* dwh-420*/
	set nocount on

	--внесли изменения в рамках bp_1592
	--внесли изменения в рамках BP-1632

	Declare @days int =-3

	if cast(getdate() as time)<='09:00'
		and cast(getdate() as time)>='07:05'
	begin
		set @days = -365
	end

	declare @d date = dateadd(year,2000,dateadd(dd, @days,cast(getdate() as date)))
	drop table if exists #mfo_statuses
	drop table if exists #mfo_request_statuses
	drop table if exists #t_result
	drop table if exists #t_contracts
	;with cte_заявка_последний_статус
	as
	(
		SELECT [Заявка]     
		,      max( Период ) Период
		FROM [Stg].[_1cMFO].[РегистрСведений_ГП_СписокЗаявок]
		group by [Заявка]
	)
	select s.Заявка       
	,      s.Статус       
	,      sp.Наименование статусНаименование
	,	   cte.Период
		into #mfo_request_statuses
	FROM cte_заявка_последний_статус                      cte
	join [Stg].[_1cMFO].[РегистрСведений_ГП_СписокЗаявок] s   on s.Заявка=cte.Заявка
			and s.Период=cte.Период
	join Stg.[_1cMFO].[Справочник_ГП_СтатусыЗаявок]       sp  on s.Статус=sp.Ссылка
	--	where s.Период > @d
	create clustered index ix on #mfo_request_statuses (Заявка)

	;with cte_договор_последний_статус
	as
	(
		select Договор             
		,      Период = max(Период)
		from stg.[_1cMFO].[РегистрСведений_ГП_СписокДоговоров]
		group by Договор
	)
	select s.Договор      
	,      Договор.Заявка 
	,      s.Статус       
	,      sp.Наименование статусНаименование
	,	   cte.Период
		into #t_contracts
	from       cte_договор_последний_статус                      cte    
	inner join stg.[_1cMFO].[РегистрСведений_ГП_СписокДоговоров] s       on s.Договор = cte.Договор
			and s.Период = cte.Период
	join       Stg.[_1cMFO].[Справочник_ГП_СтатусыДоговоров]     sp      on s.Статус=sp.Ссылка
	inner join stg.[_1cMFO].[Документ_ГП_Договор]                Договор on Договор.Ссылка = s.Договор
	--	where sp.Наименование = 'Продан'
	where cte.Период >@d

	create clustered index ix on #t_contracts (Заявка)




	select ClientRequestId = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(r.Ссылка) as uniqueidentifier)                                                                                                                                                                                    
	,      ClientRequestNumber = Номер                                                                                                                                                                                                                                               
	--, дата
	,      ClientRequestCreatedOn = case when Дата>'38010101' then DATEADD(YEAR,-2000,Дата)
	                                                          else Дата end                                                                                                                                                                                                          
	,      ClientRequestExternalStatusId = cast(iif(
			contracts.статусНаименование = 'Продан', '257706EB-4FC1-444C-8154-D1B56C2453CF', --bp-1592
	dwh_new.dbo.getGUIDFrom1C_IDRREF(s.Статус)) as uniqueidentifier)                                                                                                                                                                                                                 
	,      ClientRequestExternalStatusName = iif(
	nullif(contracts.Договор, 0x00000000000000000000000000000000) is not null
	,concat('Статус договора - ', contracts.статусНаименование)
	,concat('Статус заявки - ', s.статусНаименование)
	)       
	,	   ClientRequestDateStatusChanges = COALESCE(
		 iif(year(contracts.Период)>3000, dateadd(year, -2000, contracts.Период), null)
		 ,iif(year(s.Период)>3000,  dateadd(year, -2000,s.Период), s.Период))
	,      ClientId = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(КонтрагентКлиент) as uniqueidentifier)                                                                                                                                                                                   
	,      ClientName = CONCAT(trim(r.фамилия),' ',trim (r.Имя),' ',trim(r.отчество))                                                                                                                                                                                                
	,      ClientBirthDay = case when r.ДатаРождения>'38010101'
		and r.ДатаРождения<'41010101' then dateadd(year,-2000,r.ДатаРождения)
	                                  else r.ДатаРождения end                                                                                                                                                                                                                        
	,      ClientContactPersonName = ФИОКонтактногоЛица                                                                                                                                                                                                                              
	,      ClientPassport = concat(TRIM(replace(СерияПаспорта,'-','')),' ',TRIM(replace(НомерПаспорта,'-','')))                                                                                                                                                                      
	,      VIN = VIN                                                                                                                                                                                                                                                                 
	,      ClientAddressRegistration = r.АдресРегистрации                                                                                                                                                                                                                            
	,      ClientAddressRegistrationPostalCode = case when try_cast( SUBSTRING(r.АдресРегистрации, CHARINDEX(',',r.АдресРегистрации)+1,6) as int) is not null then SUBSTRING(r.АдресРегистрации, CHARINDEX(',',r.АдресРегистрации)+1,6)
	                                                                                                                                                          else '' end                                                                                                            
	,      ClientAddressRegistrationStreet = case when len(trim(cast(r.АдресРегистрации as nvarchar(1024))))>1
		and CHARINDEX(',' ,r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации)+1)+1)+1)+1)+1)+1) >0 then SUBSTRING(r.АдресРегистрации,
		CHARINDEX(',' ,r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации)+1)+1)+1)+1)+1)+1,
		CHARINDEX(',' ,r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации)+1)+1)+1)+1)+1)+1)
		-CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации,CHARINDEX(',',r.АдресРегистрации)+1)+1)+1)+1)+1)

		-1
		)
	                                                                                                                                                                                                                                                                      else '' end

	,      ClientAddressStay = r.АдресПроживания                                                                                                                                                                                                                                     
	,      ClientAddressStayPostalCode = case when try_cast( SUBSTRING(r.АдресПроживания, CHARINDEX(',',r.АдресПроживания)+1,6) as int) is not null then SUBSTRING(r.АдресПроживания, CHARINDEX(',',r.АдресПроживания)+1,6)
	                                                                                                                                                else '' end                                                                                                                      


	,      ClientAddressStayStreet = case when len(trim(cast(r.АдресПроживания as nvarchar(1024))))>1
		and CHARINDEX(',' ,r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания)+1)+1)+1)+1)+1)+1) >0 then SUBSTRING(r.АдресПроживания,
		CHARINDEX(',' ,r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания)+1)+1)+1)+1)+1)+1,
		CHARINDEX(',' ,r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания)+1)+1)+1)+1)+1)+1)
		-CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания,CHARINDEX(',',r.АдресПроживания)+1)+1)+1)+1)+1)

		-1
		)
	                                                                                                                                                                                                                                                               else '' end       
	,      ClientWorkplaceAddress = АдресРаботы                                                                                                                                                                                                                                      

	,      ClientWorkplaceAddressPostalCode = case when try_cast(SUBSTRING(replace(cast(АдресРаботы as nvarchar(1024)),', ',','), CHARINDEX(',',replace(cast(АдресРаботы as nvarchar(1024)),', ',','))+1,6) as int) is not null then SUBSTRING(replace(cast(АдресРаботы as nvarchar(1024)),', ',','), CHARINDEX(',',replace(cast(АдресРаботы as nvarchar(1024)),', ',','))+1,6)
	                                                                                                                                                                                                                            else '' end                                          
	--, ClientWorkplaceAddressPostalCode1     =  case when try_cast(SUBSTRING(АдресРаботы, CHARINDEX(',',АдресРаботы)+1,CHARINDEX(',',АдресРаботы,CHARINDEX(',',АдресРаботы)+1)-CHARINDEX(',',АдресРаботы)) as int) is not null then SUBSTRING(АдресРаботы, CHARINDEX(',',АдресРаботы)+1,CHARINDEX(',',АдресРаботы,CHARINDEX(',',АдресРаботы)+1)-CHARINDEX(',',АдресРаботы)) else '' end
	--,CHARINDEX(',',АдресРаботы)+1
	--,CHARINDEX(',',АдресРаботы,CHARINDEX(',',АдресРаботы)+1)-CHARINDEX(',',АдресРаботы)
	,      ClientWorkplaceAddressStreet = case when len(trim(cast(r.АдресРаботы as nvarchar(1024))))>1
		and CHARINDEX(',' ,r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы)+1)+1)+1)+1)+1)+1)>0 then SUBSTRING(r.АдресРаботы,
		CHARINDEX(',' ,r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы)+1)+1)+1)+1)+1)+1,
		CHARINDEX(',' ,r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы)+1)+1)+1)+1)+1)+1)
		-CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы,CHARINDEX(',',r.АдресРаботы)+1)+1)+1)+1)+1)

		-1
		)
	                                                                                                                                                                                                                                  else '' end                                    
	,      ClientPhoneHome = Trim(replace(replace(replace(ТелефонАдресаПроживания,'-',''),'(',''),')',''))                                                                                                                                                                           
	,      ClientPhoneMobile = Trim(replace(replace(replace(ТелефонМобильный ,'-',''),'(',''),')',''))                                                                                                                                                                               
	,      ClientContactPersonPhone = Trim(replace(replace(replace(КЛТелМобильный ,'-',''),'(',''),')',''))                                                                                                                                                                          
	,      ClientWorkPlacePhone = Trim(replace(replace(replace(ТелРабочийРуководителя ,'-',''),'(',''),')',''))                                                                                                                                                                      
	,      ThirdPersonName = concat(TRIM(ФамилияСупруги),' ',TRIM(ИмяСупруги),' ',TRIM(ОтчествоСупруги))                                                                                                                                                                             
	,      AuthorName = m.Наименование                                                                                                                                                                                                                                               
	,      AuthorAddressRegistration = m.АдресРегистрации                                                                                                                                                                                                                            

	,      AuthorAddressRegistrationPostalCode = case when try_cast( SUBSTRING(m.АдресРегистрации, CHARINDEX(',',m.АдресРегистрации)+1,6) as int) is not null then SUBSTRING(m.АдресРегистрации, CHARINDEX(',',m.АдресРегистрации)+1,6)
	                                                                                                                                                          else '' end                                                                                                            
	,      AuthorAddressRegistrationStreet = case when len(trim(cast(m.АдресРегистрации as nvarchar(1024))))>1
		and CHARINDEX(',' ,m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации)+1)+1)+1)+1)+1)+1)>0 then SUBSTRING(m.АдресРегистрации,
		CHARINDEX(',' ,m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации)+1)+1)+1)+1)+1)+1,
		CHARINDEX(',' ,m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации)+1)+1)+1)+1)+1)+1)
		-CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации,CHARINDEX(',',m.АдресРегистрации)+1)+1)+1)+1)+1)

		-1
		)
			ELSE '' end
	,      AuthorAddressStay = m.АдресПроживания --2022-08-22 А.Никитин. исправление ошибки. было m.АдресРегистрации
	,      AuthorAddressStayPostalCode = SUBSTRING(m.АдресПроживания, CHARINDEX(',',m.АдресПроживания)+1,6)                                                                                                                                                                          
	,      AuthorAddressStayStreet = case when len(trim(cast(m.АдресПроживания as nvarchar(1024))))>1 then SUBSTRING(m.АдресПроживания,
		CHARINDEX(',' ,m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания)+1)+1)+1)+1)+1)+1,
		CHARINDEX(',' ,m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания)+1)+1)+1)+1)+1)+1)
		-CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания,CHARINDEX(',',m.АдресПроживания)+1)+1)+1)+1)+1)

		-1
		)
	                                                                                                  else '' end                                                                                                                                                                    
	,      AuthorPassport = concat(trim(replace(СерияДокумента,'-','')),' ',trim(replace(НомерДокумента,'-','')),' ')                                                                                                                                                                
	,      AuthorPhone = Trim(replace(replace(replace(m.[МобильныйТелефон],'-',''),'(',''),')',''))                                                                                                                                                                                  
		--into feodor.dbo.dm_mfoRequests
		into #t_result
	from      stg._1cmfo.Документ_ГП_Заявка            r        
	join      #mfo_request_statuses                    s         on s.Заявка=r.Ссылка
	left join [Stg].[_1cMFO].[Справочник_Пользователи] m         on m.Ссылка=r.Менеджер
	left join #t_contracts                             contracts on contracts.Заявка = r.Ссылка
	where 1=1
		and (
			 s.Период>@d
			--r.дата>@d
			or contracts.Период>@d)


	create clustered index ix on #t_result(ClientRequestId)
	begin tran
	delete t
	from       feodor.dbo.dm_mfoRequests t
	inner join #t_result                 r on r.ClientRequestId = t.ClientRequestId
	--alter table feodor.dbo.dm_mfoRequests add ClientRequestExternalStatusName nvarchar(255)
	--alter table  feodor.dbo.dm_mfoRequests add ClientRequestDateStatusChanges datetime

	--ClientRequestCreatedOn>dateadd(year,-1,cast(getdate() as date))
	insert into feodor.dbo.dm_mfoRequests ( [ClientRequestId], [ClientRequestNumber], [ClientRequestCreatedOn], [ClientRequestExternalStatusId], [ClientId], [ClientName], [ClientBirthDay], [ClientContactPersonName], [ClientPassport], [VIN], [ClientAddressRegistration], [ClientAddressRegistrationPostalCode], [ClientAddressRegistrationStreet], [ClientAddressStay], [ClientAddressStayPostalCode], [ClientAddressStayStreet], [ClientWorkplaceAddress], [ClientWorkplaceAddressPostalCode], [ClientWorkplaceAddressStreet], [ClientPhoneHome], [ClientPhoneMobile], [ClientContactPersonPhone], [ClientWorkPlacePhone], [ThirdPersonName], [AuthorName], [AuthorAddressRegistration], [AuthorAddressRegistrationPostalCode], [AuthorAddressRegistrationStreet], [AuthorAddressStay], [AuthorAddressStayPostalCode], [AuthorAddressStayStreet], [AuthorPassport], [AuthorPhone], ClientRequestExternalStatusName, ClientRequestDateStatusChanges)
	select [ClientRequestId]
	,      [ClientRequestNumber]
	,      [ClientRequestCreatedOn]
	,      [ClientRequestExternalStatusId]
	,      [ClientId]
	,      [ClientName]
	,      [ClientBirthDay]
	,      [ClientContactPersonName]
	,      [ClientPassport]
	,      [VIN]
	,      [ClientAddressRegistration]
	,      [ClientAddressRegistrationPostalCode]
	,      [ClientAddressRegistrationStreet]
	,      [ClientAddressStay]
	,      [ClientAddressStayPostalCode]
	,      [ClientAddressStayStreet]
	,      [ClientWorkplaceAddress]
	,      [ClientWorkplaceAddressPostalCode]
	,      [ClientWorkplaceAddressStreet]
	,      [ClientPhoneHome]
	,      [ClientPhoneMobile]
	,      [ClientContactPersonPhone]
	,      [ClientWorkPlacePhone]
	,      [ThirdPersonName]
	,      [AuthorName]
	,      [AuthorAddressRegistration]
	,      [AuthorAddressRegistrationPostalCode]
	,      [AuthorAddressRegistrationStreet]
	,      [AuthorAddressStay]
	,      [AuthorAddressStayPostalCode]
	,      [AuthorAddressStayStreet]
	,      [AuthorPassport]
	,      [AuthorPhone]
	,      ClientRequestExternalStatusName
	,	   ClientRequestDateStatusChanges
	from #t_result
	commit tran
	if cast(getdate() as time)<='09:00'
		and cast(getdate() as time)>='07:00'

		ALTER INDEX [Cl_Indx_ClientRequestId_ClientName_ClientBirthDay] ON [dbo].[dm_mfoRequests] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)



end


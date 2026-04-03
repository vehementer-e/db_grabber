

--exec  dialer.CreateClientContractStageFromLoginom
-- select * from dialer.ClientContractStage where cast(created as date)=cast(getdate() as date) and ishistory=0
-- select * from dialer.ClientContractStage_json  where cast(created as date)=cast(getdate() as date) and ishistory=0

CREATE PROC Dialer.CreateClientContractStageFromLoginom
as

  set nocount on


  update  dialer.ClientContractStage set isHistory=1, updated=getdate() where cast(created as date)=cast(getdate() as date) and ishistory=0


  /*
  --var 1
  insert  into dialer.ClientContractStage
  select 
 distinct
   CRMClientGUID=c.CRMClientGUID
  , CRMClientStage=c.Client_Stage
  , CMRContractGUID=r.CMRContractGUID
  , CMRContractStage=d.External_Stage
  , created=getdate()
  , updated=getdate()
  , isHistory=0
  --into dialer.ClientContractStage
   from   STG._loginom.Client_Stage c
  join STG._loginom.External_Stage d 
	on d.CRMClientGUID= c.CRMClientGUID
		and c.report_date = d.report_date
  join dwh_new.staging.CRMClient_references r on r.CMRRequestNumber=d.external_id
  */

  /*
	--DWH-2442 Изменить источник формирования для таблицы с инфо по стадиям договора (в рамках стратегии Коллекшн)
	--var 2
	insert into dialer.ClientContractStage
	select distinct
		CRMClientGUID=c.CRMClientGUID
		, CRMClientStage=c.Client_Stage
		, CMRContractGUID=r.CMRContractGUID
		, CMRContractStage=d.External_Stage
		, created=getdate()
		, updated=getdate()
		, isHistory=0
		--into dialer.ClientContractStage
	from Stg._loginom.Client_Stage AS c
	--join STG._loginom.External_Stage d 
		INNER JOIN Stg._loginom.v_Collection_External_Stage_lastDay AS d
			ON d.CRMClientGUID= c.CRMClientGUID
			AND c.report_date = d.report_date
		JOIN dwh_new.staging.CRMClient_references AS r
			ON r.CMRRequestNumber=d.external_id
	*/

	/*
	--var 3
	--DWH-2442 Изменить источник формирования для таблицы с инфо по стадиям договора (в рамках стратегии Коллекшн)
	--DWH-2441 Изменить источник формирования для таблицы с инфо по стадиям клиента (в рамках стратегии Коллекшн)
	insert into dialer.ClientContractStage
	(
	    CRMClientGUID,
	    CRMClientStage,
	    CMRContractGUID,
	    CMRContractStage,
	    created,
	    updated,
	    isHistory
	)
	select distinct
		CRMClientGUID=c.CRMClientGUID
		, CRMClientStage=c.Client_Stage
		, CMRContractGUID=r.CMRContractGUID
		, CMRContractStage=d.External_Stage
		, created=getdate()
		, updated=getdate()
		, isHistory=0
	from Stg._loginom.v_Collection_Client_Stage_lastDay AS c
		INNER JOIN Stg._loginom.v_Collection_External_Stage_lastDay AS d
			ON d.CRMClientGUID= c.CRMClientGUID
			AND c.report_date = d.report_date
		INNER JOIN dwh_new.staging.CRMClient_references AS r
			ON r.CMRRequestNumber=d.external_id
	*/

	/*
	--var 4
	--DWH-2442 Изменить источник формирования для таблицы с инфо по стадиям договора (в рамках стратегии Коллекшн)
	--DWH-2441 Изменить источник формирования для таблицы с инфо по стадиям клиента (в рамках стратегии Коллекшн)
	--Замена dwh_new.staging.CRMClient_references на табл. Stg
	insert into dialer.ClientContractStage
	(
	    CRMClientGUID,
	    CRMClientStage,
	    CMRContractGUID,
	    CMRContractStage,
	    created,
	    updated,
	    isHistory
	)
	select distinct
		CRMClientGUID=c.CRMClientGUID
		, CRMClientStage=c.Client_Stage
		, CMRContractGUID = cast(Stg.dbo.getGUIDFrom1C_IDRREF(CMR_Contracts.Ссылка) as nvarchar(64)) --r.CMRContractGUID
		, CMRContractStage=d.External_Stage
		, created=getdate()
		, updated=getdate()
		, isHistory=0
	from Stg._loginom.v_Collection_Client_Stage_lastDay AS c
		INNER JOIN Stg._loginom.v_Collection_External_Stage_lastDay AS d
			ON d.CRMClientGUID= c.CRMClientGUID
			AND c.report_date = d.report_date
		INNER JOIN Stg._1cCMR.Справочник_Заявка AS CMR_Requests
			ON CMR_Requests.Код = d.external_id
		INNER JOIN Stg._1cCMR.Справочник_Договоры AS CMR_Contracts
			ON CMR_Contracts.Заявка = CMR_Requests.Ссылка
	*/

	--var 5
	--DWH-2442 Изменить источник формирования для таблицы с инфо по стадиям договора (в рамках стратегии Коллекшн)
	--DWH-2441 Изменить источник формирования для таблицы с инфо по стадиям клиента (в рамках стратегии Коллекшн)
	--Замена dwh_new.staging.CRMClient_references на табл. Stg
	--убрать join Stg._1cCMR.Справочник_Заявка !
	insert into dialer.ClientContractStage
	(
	    CRMClientGUID,
	    CRMClientStage,
	    CMRContractGUID,
	    CMRContractStage,
	    created,
	    updated,
	    isHistory
	)
	select distinct
		CRMClientGUID=c.CRMClientGUID
		, CRMClientStage=c.Client_Stage
		, CMRContractGUID = isnull(
				d.CRMContractGuid, 
				cast(Stg.dbo.getGUIDFrom1C_IDRREF(CMR_Contracts.Ссылка) as nvarchar(64))
			)
		, CMRContractStage=d.External_Stage
		, created=getdate()
		, updated=getdate()
		, isHistory=0
	from Stg._loginom.v_Collection_Client_Stage_lastDay AS c
		INNER JOIN Stg._loginom.v_Collection_External_Stage_lastDay AS d
			ON d.CRMClientGUID= c.CRMClientGUID
			AND c.report_date = d.report_date
		LEFT JOIN Stg._1cCMR.Справочник_Договоры AS CMR_Contracts
			ON CMR_Contracts.Код = d.external_id
	--ORDER BY CRMClientGUID, CMRContractGUID


  /*
  
  if object_id('tempdb.dbo.#t') is not null drop table #t
  select * into #t from dialer.ClientContractStage where cast(created as date)=cast(getdate() as date) and ishistory=0

--
/*
update #t
set CRMClientStage='Legal' where CRMClientGUID='77E57409-1216-11E8-814E-00155D01BF07'
--
drop table if exists #prelegal21
SELECT  [logdatetime]
      ,[CRMClientGUID]
      ,[fio]
      ,[birth_date]
      ,[Client_Stage]
	  into #prelegal21
  FROM [dwh_new].[Dialer].[Client_Stage_history] h
 where logdatetime>'20191122'
  and logdatetime<'20191123'
  and client_stage in('Prelegal')--,'Prelegal','Hard')
 
drop table if exists #prelegal22
  SELECT distinct CRMClientGUID,first_value(Client_Stage) over (partition by CRMClientGUID order by logdatetime desc)
  Client_Stage
  ,first_value(logdatetime) over (partition by CRMClientGUID order by logdatetime desc) logdatetime
  into #prelegal22   
  FROM [dwh_new].[Dialer].[Client_Stage_history]
  where logdatetime>'20191123'
  and client_stage not in('Prelegal','Legal')

 
  
update #t
set CRMClientStage='Prelegal' where CRMClientGUID in
(
select  distinct t21.CRMClientGUID 
  from #prelegal21 t21  join #prelegal22 t22
  on t21.CRMClientGUID=t22.CRMClientGUID
)
*/

--
 
  update dialer.ClientContractStage_json   set isHistory=1, updated=getdate() where cast(created as date)=cast(getdate() as date) and ishistory=0
 
  ;
  with s1 as(

  select distinct '{"CRMClientGUID":"'+CRMClientGUID +'","CRMClientStage":"'+CRMClientStage+'","ContractStage":' client_head
  ,(
  
  select  
    '{"CMRContractGUID":"'+isnull(CMRContractGUID,'')+'",'
  + '"CMRContractStage":"'+isnull(CMRContractStage,'')+'"}'+', '
  from #t t1 where  t.CRMClientGUID=t1.CRMClientGUID for xml path ('')

  ) [contract]
  
  from #t t
  
  )

  
 



insert  into dialer.ClientContractStage_json
  select client_head+'['+substring([contract],1,len([contract])-1)+']'+ '}' packet
   , created=getdate()
  , updated=getdate()
  , isHistory=0
--  into dialer.ClientContractStage_json
  from s1


  
  

  */

  
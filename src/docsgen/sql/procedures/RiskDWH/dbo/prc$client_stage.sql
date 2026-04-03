



 CREATE PROC [dbo].[prc$client_stage] 
 as
SET NOCOUNT ON
SET XACT_ABORT ON 

declare 
@srcname nvarchar(100);
set @srcname = 'UPDATE_CLIENT_STAGE';

--26-06-2020 - v2: статус по договорам, а не клиентам (наименование поля старое - CMRClientStage)

begin try

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = 'START';

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = '#stg1';

	--05/04/2021 - для оптимизации времени выполнения вынес в 2 временные таблицы
	drop table if exists #stg1;
	/*
	--OLD
	select a.*, cast(a.created as date) as rdt
	into #stg1
	from [dwh_new].[Dialer].[ClientContractStage] a
	where cast(a.created as date) >= cast(dateadd(dd, -10, getdate()) as date)
	;
	--7 sec
	*/
	--DWH-2442 
	--во view _loginom.v_ClientContractStage_simple:
	--1. поле created имеет тип date
	--2. уже есть поле CMRContractNumber
	select a.*, a.created as rdt
	into #stg1
	from Stg._loginom.v_ClientContractStage_simple AS a
	where a.created >= cast(dateadd(dd, -10, getdate()) as date)


	select * from #stg1

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = '#stg2';


	drop table if exists #stg2;
	select a.CRMClientGUID, a.CMRContractGUID, a.CMRContractNumber
	into #stg2
	from dwh_new.staging.CRMClient_references a
	where a.CMRContractNumber is not null
	and a.CRMClientGUID is not null;
	--2 sec


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = 'indexes for #';



	--17/08/2021 - индексы для оптимизации
	create clustered index cli_stages_stg1_idx1 on #stg1 (CRMClientGUID,CMRContractGUID) 
	create index cli_stages_stg1_idx2 on #stg1 (rdt)
	create index cli_stages_stg1_idx3 on #stg1 (created) 
	create clustered index cli_stages_stg2_idx1 on #stg2 (CRMClientGUID,CMRContractGUID) 
	create index cli_stages_stg2_idx2 on #stg2 (CMRContractNumber)


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = '#for_insert';



	--17/08/2021 - таблица для INSERT отдельным шагом
	drop table if exists #for_insert;
	with base as (
		select 	s.CMRContractStage as CRMClientStage,
		--s.CRMClientStage as cli_stg,
							   s.CMRContractNumber,
							   created,
							   rdt,
							  row_number()
								 over (
								   partition by s.CMRContractNumber, rdt
								   order by created desc) rn
						  from #stg1 s
							   inner join #stg2 r
									  on s.CRMClientGUID = r.CRMClientGUID
									  and s.CMRContractGUID = r.CMRContractGUID						
						 )	

		select  CRMClientStage,				
				CMRContractNumber as external_id,
				rdt as cdate,
				created 
		into #for_insert
		
		from base 
		where rn = 1;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = 'delete-insert stg_client_stage';


	 begin transaction

		 delete from dbo.stg_client_stage
		 where cdate >= cast(dateadd(dd, -10, getdate()) as date)
		 ;
		 
		
		insert into dbo.stg_client_stage				 

		select  CRMClientStage,				
				external_id,
				cdate,
				created 

		from #for_insert
		

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = 'FIX';


	--19/10/2020 Костыль для CDATE = 16.10.2020
	
	begin transaction 

	insert into dbo.stg_client_stage
	select a.CRMClientStage, a.external_id, a.cdate, a.created
	from dbo.fix_client_stage_161020 a
	where not exists (select 1 from dbo.stg_client_stage b
	where a.external_id = b.external_id
	and a.cdate = b.cdate)

	commit transaction;

	--01/03/2021 Костыль, чтобы засчитать платежи в 0-90 Hard
	begin transaction 

	merge into RiskDWH.dbo.stg_client_stage dst
	using (
		select * from (values 
			('19041729280001',cast('2021-02-22' as date),'Legal'),
			('19041729280001',cast('2021-02-23' as date),'Legal'),
			('19041729280001',cast('2021-02-24' as date),'Legal'),
			('19092000000186',cast('2021-02-27' as date),'Legal'),
			--06/04/2021 - стадия СБ, чтобы засчитать за 0-90 хард, Legal и Hard соответственно
			('20011510000235',cast('2021-03-23' as date),'Legal'),
			('20022610000215',cast('2021-03-19' as date),'Hard')
		) a (external_id, cdate, stg)
	) src
	on (dst.external_id = src.external_id and dst.cdate = src.cdate)
	when matched then update set
	 dst.CRMClientStage = src.stg
	 ;

	commit transaction;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = 'FINISH';	

end try

begin catch

if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

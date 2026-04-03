CREATE procedure [riskCollection].[create_collection_judicial_datamart] as
begin
--exec [riskCollection].[create_collection_judicial_datamart]

declare @msg nvarchar(255),
@subject nvarchar(255);
set @subject = 'Warning - ошибка выполнения процедуры'

BEGIN TRY
-----------------------------------------банкроты подтверждены решением
drop table if exists #bankrupt;
select DateResultOfCourtsDecisionBankrupt = max(
	case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
		else case when CourtDecisionDate is not null then CourtDecisionDate
		else case when CreateDate is not null then CreateDate
		else UpdateDate
		end
		end
	end)
,CustomerId
into #bankrupt
from Stg._Collection.CustomerStatus
where CustomerStateId = 16
and isActive = 1
group by CustomerId
;
-----------------------------------------КК
drop table if exists #kk;
select distinct number
,min(period_start) over (partition by number) as [Дата начала каникул]
,max(period_end) over (partition by number) as [Дата окончания каникул]
into #kk
from dbo.dm_restructurings
;
-----------------------------------------Отправки в КА (нужна последняя)
drop table if exists #ka;
select 
Deals.number
,cast(cat.TransferDate as date) as st_date
,cast(cat.ReturnDate as date) as end_date
,ags.AgentName as agent_name
,row_number() over (partition by Deals.number order by cat.TransferDate desc) as rn
into #ka
from stg._collection.CollectingAgencyTransfer cat
left join Stg._Collection.Deals Deals
	on Deals.id = cat.DealId
left join stg._Collection.CollectorAgencies ags
	on cat.CollectorAgencyId = ags.Id
-----------------------------------------Продукт
drop table if exists #stg_product;
select 
a.Код as external_id
,case 
	when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) like ('%installment%') then 'Installment'
	when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) like ('%pdl%') then 'Pdl'
	when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'pts' then 'PTS'
	when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'pts31' then 'PTS'
	when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'installment' then 'Installment'
	when lower(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'smart-installment' then 'Installment'
	else 'PTS' end product
into #stg_product
from stg._1cCMR.Справочник_Договоры a
left join Stg._1cCMR.Справочник_Заявка cmr_Заявка 
	on cmr_Заявка.Ссылка = a.Заявка
left join stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов 
	on cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка;
-----------------------------------------Свод
drop table if exists #final;
select
cast(getdate() as date) as [Дата отчета]
,Deal.Number AS external_id
,concat_ws(' ', c.lastname, c.name, c.middlename) as [ФИО клиента]

,dm.dpd_p_coll
,dm.external_stage
,dm.claimant_ip_fio as [КураторИП]
,dm.claimant_fio as [Ответственный взыскатель]
,coalesce(dm.kk_status,0) as [Флаг КК]
,case when dm.agent_name is not null then 1 else 0 end [Флаг КА]

,stg_product.product

,cast(jp.SubmissionClaimDate as date) as [Дата отправки требования]
,cast(jc.CourtClaimSendingDate as date) as [Дата отправки иска в суд]
,cast(jc.JudgmentDate AS date) as [Дата судебного решения]
,cast(jc.ReceiptOfJudgmentDate AS DATE) AS [Дата получения решения суд]
,cast(jc.AdoptionProductionDate AS DATE) AS [Дата принятия к производству]

,coalesce (eo.Number, 'Не указан') as [ИЛ номер]
,case 
	when eo.Type = 1 then 'Обеспечительные меры'
	when eo.Type = 2 then 'Денежное требование'
	when eo.Type = 3 then 'Обращение взыскания'
	when eo.Type = 4 then 'Взыскание и обращение взыскания'
	else 'Не указан' 
	end [ИЛ тип]
,case when (lower(eo.Number) like '%сп%' or lower(eo.Number) like '%/%') and lower(eo.Number) not like '%#%'
	then '02.судебный приказ'
	else '01.исполнительный лист'
	end 'Судебный документ тип'
,eo.Amount as [ИЛ сумма]
,cast(eo.Date as date) as [ИЛ дата создания судом]
,cast(eo.ReceiptDate as date) as [ИЛ дата получения Carmoney]--when eo.Number is not null then coalesce(cast(eo.ReceiptDate AS DATE), cast(epe.ExcitationDate AS DATE))
,cast(eo.ReceiptReturnDate as date) as [Дата возврата ИЛ на доработку]
,cast(eo.AcceptanceDate as date) as [ИЛ дата принятия в работу ИП]

,cast(epe.ErrorCorrectionNumberDate as date) as [Заявление в ФССП о ИП дата отправки]
,cast(epe.ExcitationDate as date) as [ИП дата возбуждения]

,cast(epmbt.ArestCarDate as date) as [Арест дата]

,case
	when epmst.SecondTradingResult is not null
	then cast(epmst.SecondTradesDate as date)
	else null 
	end [Торги вторые дата]

,cast(epmi.AdoptionBalanceDate as date) as [Принятие на баланс дата]
,case
	when epmi.SaleCarDate is not null and epmi.amountsalecar is not null
	then 1 
	else 0 
	end [Залог реализован с торгов]

,case when ds.Name = 'Погашен' and Deal.lastpaymentdate is not null
	then cast(Deal.lastpaymentdate as date)
	else 
	null 
	end [ПДП дата]

,cast(bankrupt.DateResultOfCourtsDecisionBankrupt as date) as [Дата банкротства подверждено решением]

,kk.[Дата начала каникул]
,kk.[Дата окончания каникул]

,ka.agent_name as [Наименование КА]
,ka.st_date  as [Дата текущей передачи в КА]
,ka.end_date as [Дата текущего отзыва из КА]

,case when (Deal.StageId = 9 and Deal.DebtSum = 0) or Deal.fulldebt <= 0 then '08.договор закрыт'
	when bankrupt.DateResultOfCourtsDecisionBankrupt is not null then '07.банкрот'
	when epmi.AdoptionBalanceDate is not null then '06.принят на баланс актив'
	when epmst.SecondTradingResult is not null then '05.торги проведены'
	when epmbt.ArestCarDate is not null then '04.арест актива произведен'
	when epe.ExcitationDate is not null then '03.возбуждено ИП в ФССП'
	when eo.AcceptanceDate is not null and eo.Accepted = 1 then '02.ИЛ принят в работу СП'
	else '01.ИЛ получен из суда'
	end [Статус для конверсии]

,reg.РегионРегистрации as [Регион постоянной регистрации]

,fssp.name as [РОСП наименование]
,concat_ws(', ',fssp.NameRegion,fssp.TypeRegion,fssp.TypeLocation,fssp.NameLocation,fssp.NameCity,fssp.TypeCity
	,fssp.NameStreet,fssp.TypeStreet,fssp.NumberHouse) as [РОСП адрес]

,case 
	when cast(epe.ExcitationDate as date) < cast(eo.ReceiptDate as date) then 0
	when cast(epe.ExcitationDate as date) is not null then 1
	when ds.Name = 'Погашен' and Deal.lastpaymentdate is not null and cast(Deal.lastpaymentdate as date)
	<= dateadd(dd,30,cast(eo.ReceiptDate as date)) then 0
	when cast(bankrupt.DateResultOfCourtsDecisionBankrupt as date) <= dateadd(dd,30,cast(eo.ReceiptDate as date)) then 0
	when cast(eo.ReceiptReturnDate as date) <= dateadd(dd,30,cast(eo.ReceiptDate as date)) then 0
	when kk.[дата окончания каникул] is not null and dateadd(dd,30,kk.[дата окончания каникул]) >= cast(getdate() as date) then 0
	else 1 
	end [Флаг_1 ИЛ доступен для ИП]

,case 
	when cast(epmbt.ArestCarDate as date) < cast(eo.ReceiptDate as date) then 0
	when cast(epmbt.ArestCarDate as date) is not null then 1
	when ds.Name = 'Погашен' and deal.lastpaymentdate is not null and cast(deal.lastpaymentdate as date)
	<= dateadd(dd,120,cast(eo.ReceiptDate as date)) then 0
	when cast(bankrupt.DateResultOfCourtsDecisionBankrupt as date) <= dateadd(dd,120,cast(eo.ReceiptDate as date)) then 0
	when cast(eo.ReceiptReturnDate as date) <= dateadd(dd,120,cast(eo.ReceiptDate as date)) then 0
	when kk.[дата окончания каникул] is not null and dateadd(dd,120,kk.[дата окончания каникул]) >= cast(getdate() as date) then 0
	else 1 
	end [Флаг_1 ИЛ доступен для ареста]

,case 
	when cast(coalesce(eo.ReceiptDate, '1900-01-01') as date) > 
	(case when ds.Name = 'Погашен' and Deal.lastpaymentdate is not null then cast(Deal.lastpaymentdate as date) else '2099-01-01' end)
	then 1 
	else 0 
	end [Флаг получение листа после ПДП]

,case 
	when cast(coalesce(eo.ReceiptDate, '1900-01-01') as date) > cast(coalesce(bankrupt.DateResultOfCourtsDecisionBankrupt, '2099-01-01') as date)
	then 1 
	else 0 
	end [Флаг поступление листа после банкротства клиента]

,case 
	when cast(coalesce(epmbt.ArestCarDate, '2099-01-01') as date) <= cast(coalesce(epe.ExcitationDate, '1900-01-01') as date)
	then 1 
	else 0 
	end [Флаг Залог арестован на момент возбуждения ИП]

,case 
	when cast(eo.AcceptanceDate as date) < cast(eo.ReceiptDate as date) then 0
	when (case when ds.Name = 'Погашен' and Deal.lastpaymentdate is not null
					then cast(Deal.lastpaymentdate as date)
					else null end) <= cast(eo.ReceiptDate as date) 
	then 0
	when cast(bankrupt.DateResultOfCourtsDecisionBankrupt as date) <= cast(eo.ReceiptDate as date) then 0
	when coalesce(cast(eo.ReceiptReturnDate as date),'2000-01-01') >= cast(eo.ReceiptDate as date) then 0
	else 1 
	end [Флаг_1_ИЛ поступил в ИП]

into #final
from Stg._Collection.Deals Deal
left join Stg._Collection.customers c
	on c.Id = Deal.IdCustomer
left join riskCollection.collection_datamart dm
	on Deal.Number = dm.external_id and dm.d = cast(getdate() as date)
left join #stg_product stg_product
	on Deal.number = stg_product.external_id
join Stg._Collection.JudicialProceeding jp --простой джойн, чтобы выводить только тех клиентов, по еоторым есть судебная работа
	on Deal.Id = jp.DealId
left join Stg._Collection.JudicialClaims jc
	on jp.Id = jc.JudicialProceedingId
left join Stg._Collection.EnforcementOrders eo
	on jc.Id = eo.JudicialClaimId
left join Stg._Collection.EnforcementProceeding ep
	on eo.Id = ep.EnforcementOrderId
left join Stg._Collection.EnforcementProceedingExcitation as epe
	on epe.EnforcementProceedingId = ep.Id
--left join Stg._Collection.EnforcementProceedingSPI as SPI 
--	on SPI.EnforcementProceedingId = ep.Id 
--left join Stg._Collection.collectingStage AS cst_deals 
--	ON Deal.StageId = cst_deals.Id 
--left join Stg._Collection.collectingStage AS cst_client 
--	ON c.IdCollectingStage = cst_client.Id 
--left join Stg._Collection.CustomerPersonalData AS cpd 
--	ON cpd.IdCustomer = c.Id 
--left join [Stg].[_Collection].[DadataCleanFIO] AS dcfio 
--	ON dcfio.Surname = c.LastName AND dcfio.Name = c.Name AND dcfio.Patronymic = c.MiddleName 
--left join [Stg].[_Collection].Courts AS court 
--	ON court.Id = jp.CourtId 
left join Stg._Collection.DepartamentFSSP fssp
	on epe.DepartamentFSSPId = fssp.Id
left join Stg._Collection.EnforcementProceedingMonitoring monitoring
	on ep.Id = monitoring.EnforcementProceedingId
left join Stg._Collection.EnforcementProceedingMonitoringBeforeTrades epmbt
	on epmbt.EnforcementProceedingMonitoringId = monitoring.Id
--left join Stg._Collection.EnforcementProceedingMonitoringFirstTrades epmft
--	on epmft.EnforcementProceedingMonitoringId = monitoring.Id
left join Stg._Collection.EnforcementProceedingMonitoringSecondTrades epmst
	on epmst.EnforcementProceedingMonitoringId = monitoring.Id
left join Stg._Collection.EnforcementProceedingMonitoringImplementation epmi
	on epmi.EnforcementProceedingMonitoringId = monitoring.Id
--left join [Stg].[_Collection].DealPledgeItem AS dpi 
--	ON dpi.DealId = Deal.Id 
--LEFT JOIN [Stg].[_Collection].[PledgeItem] AS pl 
--	ON pl.Id = dpi.PledgeItemId 
left join dm.Клиент_РегионРегистрации_SCD2 reg
	on c.crmcustomerid = reg.guidклиент
left join Stg._Collection.DealStatus ds 
	on Deal.idstatus = ds.id
left join #ka ka
	on ka.number = deal.Number 
	and ka.rn = 1
left join #bankrupt bankrupt
	on bankrupt.CustomerId = c.Id
--left join [Stg].[_Collection].[HopelessCollection] hc 
--	on hc.DealId = Deal.id
--left join stg.[_Collection].Employee empIP 
--	on c.[ClaimantExecutiveProceedingId]  = empIP.id
--left join stg.[_Collection].StatusAfterArrest saa 
--	on monitoring.statusafterarrestid = saa.id 
left join #kk kk
	on kk.[number] = Deal.Number
;
----------------------------------внесение данных
if OBJECT_ID('riskcollection.collection_judicial_datamart') is null
begin
	select top(0) * into riskcollection.collection_judicial_datamart
	from #final
end;

BEGIN TRANSACTION
	truncate table riskcollection.collection_judicial_datamart;

	insert into riskcollection.collection_judicial_datamart
	select * from #final;
COMMIT TRANSACTION;

drop table if exists #bankrupt;
drop table if exists #kk;
drop table if exists #ka;
drop table if exists #stg_product;
drop table if exists #final;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'riskcollection@carmoney.ru'
			--,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
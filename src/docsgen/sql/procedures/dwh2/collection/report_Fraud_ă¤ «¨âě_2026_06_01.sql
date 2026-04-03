

-- =============================================
-- Author:		Anton Sabanin
-- Create date: 10.12.2020
-- Description:	dwh-738
-- exec [dbo].[report_Fraud] null,null
-- =============================================
create   PROCEDURE [collection].[report_Fraud]
	@BeginDate date,
	@EndDate date
AS
BEGIN
	

	SET NOCOUNT ON;

	-- первый день недели
	SET datefirst 1

	-- declare 	@BeginDate date,@EndDate date

	if @BeginDate is  null 
	begin
		Set @BeginDate = dateadd(day,-2365, Getdate())
	end

	if @EndDate is  null 
	begin
		Set @EndDate = Getdate()
	end
  

  --select @BeginDate, @EndDate

 

  drop table if exists #main_t
    select n.*, a.DateOfSendingApplicationToOVD --, pay.Сумма 
	into #main_t
	from --,' --- ', f.*, ' --- ', a.*,
  (
  select id, number,ФИО

  , sum(isnull([Fraud подтвержденный признак],0)) as [Fraud подтвержденный признак]
  , sum(isnull([Fraud неподтвержденный признак],0)) as [Fraud неподтвержденный признак]
  , sum(isnull([HardFraud признак],0)) as [HardFraud признак]
  ,sum(isnull([FakeDocuments],0)) as [FakeDocuments]
  ,    sum(isnull([InaccurateInformation],0)) as [InaccurateInformation]
  ,    sum(isnull([PlaceOfWorkNotConfirmed],0)) as [PlaceOfWorkNotConfirmed]
  ,    sum(isnull([PledgedBy3persons],0)) as [PledgedBy3persons]
  ,    sum(isnull([RealizationTransport],0)) as [RealizationTransport]
 -- ,    sum(isnull([RegistrationResult],0)) as [RegistrationResult]
 -- ,    sum(isnull([ResultApplicationReviewInOVDId],0)) as [ResultApplicationReviewInOVDId]
  ,    sum(isnull([Wanted],0)) as [Wanted]
  ,    sum(isnull([RepresentativeAddress],0)) as [RepresentativeAddress]
  ,    sum(isnull([RepresentativeFIO],0)) as [RepresentativeFIO]
  ,    sum(isnull([RepresentativePhone],0)) as [RepresentativePhone]
  ,    sum(isnull([DenyCollectors],0)) as [DenyCollectors]
  ,    sum(isnull([HardFraud_DenyCollectors],0)) as [HardFraud_DenyCollectors]
  ,    sum(isnull([IsSetRealUserOfTheLoan],0)) as [IsSetRealUserOfTheLoan]
 -- ,    sum(isnull([NameOfIdentifiedBorrower],0)) as [NameOfIdentifiedBorrower]
  
  ,ActivationDate
  from
  (
  select c.id, d.number, c.LastName + ' ' + c.Name + ' ' + isnull(c.MiddleName,'') as 'ФИО'
  , cst.Name , cs.ActivationDate --, cs.*
  , 'Fraud подтвержденный признак' = case cst.Name when 'Fraud подтвержденный' then 1 else 0 end 
  , 'Fraud неподтвержденный признак' = case cst.Name when 'Fraud неподтвержденный' then 1 else 0 end 
  , 'HardFraud признак' = case cst.Name when 'HardFraud' then 1 else 0 end 
  , 'FakeDocuments' = iif( isnull(FakeDocuments,0)=0 ,0,1)
  , 'InaccurateInformation' = iif(  isnull(InaccurateInformation,0)=0 ,0,1)
  , 'PlaceOfWorkNotConfirmed' = iif(  isnull(PlaceOfWorkNotConfirmed ,0)=0,0,1)
  , 'PledgedBy3persons' = iif(  isnull(PledgedBy3persons ,0)=0,0,1)
  , 'RealizationTransport' = iif(  isnull(RealizationTransport ,0)=0,0,1)
 -- , 'RegistrationResult' = iif(  isnull(RegistrationResult ,0)=0,0,1)
 -- , 'ResultApplicationReviewInOVDId' = iif(  isnull(ResultApplicationReviewInOVDId ,0)=0,0,1)
  , 'Wanted' = iif(  isnull(Wanted ,0)=0,0,1)
  , 'RepresentativeAddress' = iif(  isnull(RepresentativeAddress ,0)=0,0,1)
  , 'RepresentativeFIO' = iif(  isnull(RepresentativeFIO ,0)=0,0,1)
  , 'RepresentativePhone' = iif(  isnull(RepresentativePhone ,0)=0,0,1)
  , 'DenyCollectors' = iif(  isnull(DenyCollectors ,0)=0,0,1)
  , 'HardFraud_DenyCollectors' = iif(  isnull(HardFraud_DenyCollectors ,0)=0,0,1)
  , 'IsSetRealUserOfTheLoan' = iif(  isnull(IsSetRealUserOfTheLoan ,0)=0,0,1)
 -- , 'NameOfIdentifiedBorrower' = iif(  isnull(NameOfIdentifiedBorrower ,0)=0,0,1)
  --into devdb.dbo.t3_1

 -- , *
    from  Stg._Collection.[CustomerStatus] cs 
       join Stg._Collection.Customers c on c.Id = cs.CustomerId  
       join Stg._Collection.CustomerState cst on cs.CustomerStateId=cst.Id 
	   left join stg._Collection.Deals d on d.IdCustomer = c.id
  where cs.IsActive=1  
  and (cst.name = 'Fraud подтвержденный' or cst.name = 'Fraud неподтвержденный' or cst.name = 'HardFraud')
  and ActivationDate  between @BeginDate and @EndDate
  --and c.id = 33714
  ) m
  group by m.id, m.Number,m.ФИО, ActivationDate
  )n 
  left join Stg._Collection.[PreInvestigationChecks] f on f.CustomerId = n.id
left join Stg._Collection.[FraudAdditionalTableData] a on f.FraudAdditionalTableDataId
= a.id
--left join #payment  pay on pay.external_id = n.number


 drop table if exists  #payment
  select Sum(Сумма) as Сумма, external_id 
  into #payment  
  from reports.dbo.dm_Collection_IP_Payment p
  join #main_t m on p.external_id = m.Number
  where p.Дата >= dateadd(year,2000,isnull(m.DateOfSendingApplicationToOVD,'2301-01-01')) and
  p.Дата <= dateadd(year,2000, @EndDate)
  group by external_id

  --select * from #payment

  select *
  , st = REVERSE(STUFF(REVERSE( 
  + iif(m.DenyCollectors > 0 or m.HardFraud_DenyCollectors >0 ,'Запрет на работу коллекторов, ','') 
  + iif(m.FakeDocuments > 0 ,'Поддельные документы (ПД), ','') 
  + iif(m.InaccurateInformation > 0 ,'Недостоверные сведения (НС), ','') 
  + iif(m.PlaceOfWorkNotConfirmed > 0 ,'Место работы не подтверждено (МР), ','') 
  + iif(m.PledgedBy3persons > 0 ,'В залоге у 3-х лиц, ','') 
  + iif(m.RealizationTransport > 0 ,'Реализация ТС клиентом (РТС), ','') 
  + iif(m.Wanted > 0 ,'Розыск, ','') 
  --+ iif(m.RealizationTransport > 0 ,'Реализация ТС клиентом (РТС), ','') 
  ),1,2,''))
  

  from #main_t   m
  left join #payment p on p.external_id = m.Number

END

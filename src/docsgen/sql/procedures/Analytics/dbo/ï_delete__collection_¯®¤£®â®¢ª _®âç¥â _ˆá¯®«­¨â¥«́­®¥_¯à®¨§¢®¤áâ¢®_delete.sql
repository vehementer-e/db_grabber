CREATE    proc [dbo].[_collection_подготовка_отчета_Исполнительное_производство]
as
begin

drop table if exists #fraud_confirmed
select distinct CustomerId into #fraud_confirmed from _collection_CustomerStatus
where CustomerState ='Fraud подтвержденный' and IsActive=1


drop table if exists #HardFraud
select distinct CustomerId into #HardFraud from _collection_CustomerStatus
where CustomerState ='HardFraud' and IsActive=1

drop table if exists #v_repayments
select код, Сумма, дата into #v_repayments from v_repayments

create nonclustered index t on #v_repayments
(
дата, код
)


drop table if exists #monitoring

;

with  monitoring as
(
select 
		  monitoring.id
		, bt.ArestCarDate 
		, monitoring.EnforcementProceedingId 
		, bt.CarStoragePlace
		, ft.ReevaluationDate
		, ft.FirstTradesDate 
		, ft.FirstTradesDatePlanned 
		, ft.FirstTradingResult 
		, st.SecondTradesDatePlanned 
		, st.SecondTradingResult 
		, st.SecondTradesDate 
		, im.DecisionDepositToBalance 
		, im.AdoptionBalanceDate 
		, im.AmountDepositToBalance
		, im.OfferAdoptionBalanceDate
		, monitoring.StatusAfterArrestId
		
		
FROM [Stg].[_Collection].[EnforcementProceedingMonitoring] monitoring 
left join [Stg].[_Collection].EnforcementProceedingMonitoringBeforeTrades bt on bt.EnforcementProceedingMonitoringId = monitoring.Id
left join [Stg].[_Collection].[EnforcementProceedingMonitoringFirstTrades] ft on ft.EnforcementProceedingMonitoringId = monitoring.Id
left join [Stg].[_Collection].[EnforcementProceedingMonitoringSecondTrades] st on st.EnforcementProceedingMonitoringId = monitoring.Id
left join [Stg].[_Collection].[EnforcementProceedingMonitoringImplementation] im on im.EnforcementProceedingMonitoringId = monitoring.Id
)
select *
into #monitoring
from monitoring;
;


with v as (

select *, ROW_NUMBER() over(partition by EnforcementProceedingId order by ArestCarDate desc) rn from #monitoring

)
delete from v where rn>1


drop table if exists #t1


--select * from #monitoring
--where EnforcementProceedingId=5

SELECT --TOP (1000) 
       a.[№ договора]
      ,a.[ФИО]
      ,a.[Дата рождения]
      ,a.[Место рождения]
      ,a.[Серия паспорта]
      ,a.[№ паспорта]
      ,a.[Дата выдачи]
      ,a.[Адрес постоянной регистрации]
      ,a.[Адрес фактического места жительства]
      ,a.[Марка, модель]
      ,a.[Модель]
      ,a.[Год выпуска]
      ,a.[VIN]
      ,a.[Гос. номер]
      ,a.[Наименование суда]
      ,a.[№ ИЛ]
      ,a.[Дата ИЛ]
      ,a.[ДатаПринятияИЛ]
      ,a.[датаПринятияИЛСоставная]
	  ,case when a.[датаПринятияИЛСоставная] is not null then 1 else 0 end [Есть дата принятия ИЛ составная]
      ,a.[Тип ИЛ]
      ,a.[Сумма ИЛ, руб.]
      ,a.[ИЛ принят]
      ,a.[Наименование отдела ФССП]
      ,a.[Дата возбуждения ИП]
      ,a.[№ дела в ФССП]
      ,a.[ФИО пристава]
      ,a.[Наименование работодателя]
      ,a.[ИНН работодателя]
      ,a.[Дата последнего заявления на удержание]
      ,a.[Дата постановления на удержание]
      ,a.[Дата ареста авто]
      ,a.[Место хранения авто]
      ,a.[Дата переоценки]
      ,MONITORING.FirstTradesDate [Фактическая дата первых торгов]
      ,a.[Плановая дата первых торгов]
      ,a.[Результат первых торгов]
      ,a.[Плановая дата вторых торгов]
      ,MONITORING.SecondTradesDate [Фактическая дата вторых торгов]
      ,a.[Результат вторых торгов]
	  ,isnull(MONITORING.SecondTradesDate , MONITORING.FirstTradesDate) [Дата торгов]
	  ,case when a.[Результат вторых торгов]=1 or a.[Результат первых торгов]=1 then 1 else 0 end [Результат торгов]
      ,a.[ Решение о принятии на баланс]
      ,a.[Дата принятия на баланс]
	  ,case when a.[Дата принятия на баланс] is not null then 1 else 0 end [Есть Дата принятия на баланс]
	  ,case when isnull(MONITORING.SecondTradesDate , MONITORING.FirstTradesDate) is not null then 1 else 0 end [Есть Дата торгов]
	  ,x.Сумма [Сумма поступлений после ареста]
      ,a.[Дата окончания]
      ,a.[Основания окончания ИП]
      ,a.[Статус договора]
      ,a.[Погашен]
      ,a.[Состояние в КА]
      ,a.[Наименование КА есть]
      ,a.[Наименование КА]
      ,a.[Бакнрот] [Банкрот]
      ,a.[Бакнрот не подтвержденный] [Банкрот не подтвержденный]
      ,a.[Вступпление решения суда в силу]
      ,a.[Сумма платежей за месяц]
      ,a.[Сумма последнего платежа в день]
      ,a.[Дата последнего платежа в месяце]
      ,a.[Сумма последнего платежа]
      ,a.[Дата последнего платежа]
      ,a.[Дата договора]
      ,a.[address_fssp]
      ,a.[БВ]
      ,a.[БВ по договору]
      ,a.[Основание БВ по договору]
      ,a.[БВ наличие соглашения]
      ,a.[Дата ПДП]
      ,a.[Сумма ПДП]
      ,a.[DPD на Дата ПДП]
      ,a.[Ответственный взыскатель последний]
      ,a.[Дата последнего взыскателя]
      ,a.[Сумма принятия на баланс]
      ,a.[Отправлено в РОСП]
      ,a.[КураторИП]
      ,a.[Дата предложения о принятии на баланс]
      ,a.[Решение о принятии на баланс текст]
      ,a.[Наличие ИД]
      ,a.[Получатель ПФР]
      ,a.[Заявление на удержание]
      ,a.[Номер дела в суде СП]
      ,a.[Комментарий]
      ,a.[Долг погашен по ИД]
      ,a.[Принят на баланс]
      ,a.[Телефон]
      ,a.[Дополнительно]
      ,a.[Стадия коллектинга]
      ,a.[Статус после ареста]
      ,a.[Дата запроса дубликата]
      ,a.[Дата получения дубликата]
      ,a.[Дата заявления на дубликат]
      ,a.[Дата доставки заявления]
      ,a.[Дата заявления на розыск]
      ,a.[Рузультата рассмотрения заявления]
      ,a.[Результат доставки]
      ,a.[Номер исходящего]
      ,a.[Номер исходящего ШПИ отправки заявления]
      ,a.[Причина отказа]
      ,a.[Дата последнего запрета]
      ,a.[Результат заявления на розыск]
      ,a.[Дата постановления на РД]
      ,a.[Дата ответа на запрос]
      ,a.[Результат выходной]
      ,a.[Дата репрезентации]
      ,a.[Дата резолюции]
      ,a.[Регион ФССП]
      ,a.[Регион суда]
      ,a.[Адрес суда]
      ,a.[Арест машины по договору]
      ,a.[Новый собственник]
      ,a.[id Договор ИП]
      ,EP.ID [id ИспПроиз ИП]
      ,a.[id Иск ИП]
      ,a.[id ИЛ ИП]
	  ,b.[остаток од] [остаток од на сегодня]
	  ,b1.[остаток од] [остаток од на дату принятия ИЛ]
	  ,b2.[остаток од] [остаток од на дату возбуждения ИП]
	  ,case when f.CustomerId is not null then 1 else 0 end as FRAUD_confirmed
	  ,case when hf.CustomerId is not null then 1 else 0 end as HardFraud
	  into #t1
  FROM [Reports].[dbo].[dm_EnforcementProceeding_SP_IP] a
  left join analytics.dbo.v_balance b on a.[№ договора]=b.Код and b.d=cast(getdate() as date)
  left join analytics.dbo.v_balance b1 on a.[№ договора]=b1.Код and b1.d=a.датаПринятияИЛ
  left join analytics.dbo.v_balance b2 on a.[№ договора]=b2.Код and b2.d=a.[Дата возбуждения ИП]
  left join stg._collection.deals d on d.number=a.[№ договора]
  left join #fraud_confirmed f on f.customerid=d.idcustomer
  left join #HardFraud hf on hf.customerid=d.idcustomer
  outer apply (select sum(Сумма) Сумма  from #v_repayments p where p.Дата>a.[Дата ареста авто] and p.Код=a.[№ договора] )x
  LEFT JOIN Stg._Collection.EnforcementProceeding EP ON EP.EnforcementOrderId=A.[id ИЛ ИП]
  LEFT JOIN #monitoring MONITORING ON EP.EnforcementOrderId=MONITORING.EnforcementProceedingId
  
  drop table if exists #t
  select *
  , ROW_NUMBER() over(partition by [№ договора], [Тип ИЛ] order by case when [ДатаПринятияИЛ] is not null then 0 else 1 end, [ДатаПринятияИЛ],  case when [датаПринятияИЛСоставная] is not null then 0 else 1 end,  [датаПринятияИЛСоставная]) [Порядковый номер ИЛ по типу ИЛ] 
  , count(*) over(partition by [№ договора], [Тип ИЛ] ) [Количество ИЛ по типу ИЛ] 
  into #t  from #t1

  drop table if exists dbo._collection_Исполнительно_производство 
  select * into dbo._collection_Исполнительно_производство  from #t


  --select * from dbo._collection_Исполнительно_производство  
  --where [Дата ареста авто] is not null
  end
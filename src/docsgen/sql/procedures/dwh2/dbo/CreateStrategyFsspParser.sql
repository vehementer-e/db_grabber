
 CREATE   procedure CreateStrategyFsspParser as
--dwh-673

 delete from  dbo.StrategyFsspParser
 insert into  dbo.StrategyFsspParser
 (сreate_date, external_id, fio, fio_new_holder, signal, Order_number, request_date)

select create_date=getdate(),
external_id=deals.number,
fio=concat(customers.LastName,' ',customers.Name,' ',customers.MiddleName),
fio_new_holder =''
,signal='36'
,Order_number=EnforcementOrders.Number
,request_date=null
FROM stg._collection.[TaskAction]
left join stg._collection.EnforcementOrders on EnforcementOrders.id = TaskAction.EnforcementOrderId
left join stg._collection.deals on deals.id = TaskAction.DealId
left join stg._collection.customers on customers.id = Deals.IdCustomer

where StrategyActionTaskId = 36

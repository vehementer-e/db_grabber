-- Usage: запуск процедуры с параметрами
-- EXEC files.CourtOrders_payments_postloader @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create     procedure files.CourtOrders_payments_postloader
as begin
set nocount on


--select * into  files.CourtOrders_Payments from files.CourtOrders_Payments_buffer

if (select count(*) from files.CourtOrders_Payments_buffer)>0
begin

   delete from files.CourtOrders_Payments
   insert into files.CourtOrders_Payments([dl]
      ,[ФИО клиента]
      ,[Дата платежа]
      ,[СУММА ПЛАТЕЖА ]
      ,[СТАТУС ]
      ,[КУРАТОР ИСПОЛ ПРОИЗВОДСТВА]
      ,[created]
)
    select [dl]
      ,[ФИО клиента]
      ,[Дата платежа]
      ,[СУММА ПЛАТЕЖА ]
      ,[СТАТУС ]
      ,[КУРАТОР ИСПОЛ ПРОИЗВОДСТВА]
      ,[created]
  from files.CourtOrders_Payments_buffer
end

  select 0
  
end

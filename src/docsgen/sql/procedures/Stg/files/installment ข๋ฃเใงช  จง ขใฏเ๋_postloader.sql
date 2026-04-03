CREATE PROCEDURE files.[installment выгрузка из вупры_postloader] as begin 
 begin tran 
  truncate table files.[installment выгрузка из вупры] 
 insert into   files.[installment выгрузка из вупры] (
 [timestamp] ,
 [pid] ,
 [action] ,
 [Timestamp1] ,
 [crib_lead_id] ,
 [Action Name] ,
 [Campaign Medium] ,
 [Campaign Source] ,
 [created] ) 
 select 
 [timestamp] ,
 [pid] ,
 [action] ,
 [Timestamp1] ,
 [crib_lead_id] ,
 [Action Name] ,
 [Campaign Medium] ,
 [Campaign Source] ,
 [created]  from files.[installment выгрузка из вупры_stg] 
 commit tran  
 end 
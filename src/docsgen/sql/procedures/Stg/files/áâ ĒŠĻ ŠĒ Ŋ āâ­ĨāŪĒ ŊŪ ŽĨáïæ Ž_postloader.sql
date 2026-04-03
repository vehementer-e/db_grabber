CREATE PROCEDURE files.[ставки кв партнеров по месяцам_postloader] as begin 
 begin tran 
  truncate table files.[ставки кв партнеров по месяцам] 
 insert into   files.[ставки кв партнеров по месяцам] (
 [Месяц] ,
 [Партнер] ,
 [Юр лицо] ,
 [Процент вознаграждения] ,
 [created] ) 
 select 
 [Месяц] ,
 [Партнер] ,
 [Юр лицо] ,
 [Процент вознаграждения] ,
 [created]  from files.[ставки кв партнеров по месяцам_stg] 
 commit tran  
 end 
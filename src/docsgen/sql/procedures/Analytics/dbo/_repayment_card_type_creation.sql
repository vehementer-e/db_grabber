CREATE proc 	[dbo].[_repayment_card_type_creation]
as 
drop table if exists  #ttt2	
;	
with pay_payment as (	
SELECT [id]	
      	
  FROM [Stg].[_LK].[pay_payment]	
  --order by created_at desc	
  )	
  ,	
  Документ_Платеж as (	
select --top 100000 	
	
Дата ДатаДокумент_Платеж , Ссылка	
, TransactionID 	
, replace(НомерПлатежа, ' ', '') НомерПлатежа	
	
from stg._1cCMR.Документ_Платеж	
	

	
       )	
	  ,
  pay as (	
	
SELECT [id]	
      ,[payment]	
      ,[card_type]	
     	
  FROM [Stg].[_LK].[pay_cloud]	
 -- order by id desc	
  where --payment=380190 and 	
  action='pay   ' and status='Completed'	
  union all	
  	
SELECT [id]	
      ,[payment]	
      ,[card_type]	
   FROM [Stg].[_LK].[pay_ecomm]	
 --order by 1 desc	
  where --payment=380190 and 	
  action='pay   ' and status='Completed'	
  )	
 
	
     	
	
	
select  a.ссылка, pay.card_type cardType into #ttt2 from Документ_Платеж a	
--join Analytics.dbo.v_repayments b on a.Ссылка=b.ссылка and b.Дата >='20220501'	
--left join pay_payment pay_payment on try_cast(pay_payment.id as bigint)=try_cast(a.НомерПлатежа as bigint)	
left join pay on  pay.payment =   try_cast(a.НомерПлатежа as bigint)	 --pay.payment=pay_payment.id	
 
;	
	
with v as (	
select *, ROW_NUMBER() over(partition by ссылка order by (select 1)) rn from #ttt2 )	
delete from v where rn>1	
	
;	
	
--select * from ##ttt2	

--drop table if exists repayments_card_type
--select * into repayments_card_type from ##ttt2
delete from repayments_card_type
insert into repayments_card_type
select * from #ttt2

 
  
CREATE proc [dbo].[pay_report] @mode nvarchar(max) = 'repayments_select' as 
--exec _birs.[Pay_Gateway] 'repayments_select'


--	 exec _mv 'mv_repayments', 1
if @mode='repayments_update'
begin

	  drop table if exists #_birs_mv_report_repayments

;
with t2  as (

SELECT-- top (select * from _birs_top_N a)
a.Сумма 
,a.IsInstallment 
,  case when ПлатежнаяСистема='Киви' then 'Contact' else ПлатежнаяСистема end    ПлатежнаяСистема
, case when ПлатежнаяСистема in ( 'ECommPay' , 'Cloud payments') then 'Онлайн' else 'Офлайн' end [Онлайн офлайн]
, producttype2 [Продукт]
,Прибыль
,ПрибыльБезНДС
,[Прибыль модель оплаты 1]
,[Прибыль модель оплаты 2]
,[Прибыль модель оплаты 3]
,[Прибыль расчетная екомм]
,[Прибыль расчетная екомм без ндс]
,created
,ДеньПлатежа
,dpdbeginday
--,  b.Квартал Квартал
--,  b.Месяц [Месяц]
--,  b.Год [Год платежа]
--,  b.[Полугодие] [Полугодие]
, case 
when Сумма<=10000 then '0) 0..10]'
when Сумма<=25000 then '1) 10..25]'
when Сумма<=50000 then '2) 25..50]'
when Сумма<=75000 then '3) 50..75]'
when Сумма<=100000 then '4) 75..100]'
else '5) 100+' end [Сумма бакет]
--when Сумма<=100000 then '3) 100000)+' end [Сумма бакет]
--into #t2
from ##mv_repayments a --
	  )			   
--	  от 0 до 10 тыс - кол-во платежей
--от 10 до 25 - кол-во платежей
--от 25 до 50 кол-во платежей
--от 50 до 75 тыс - кол-во платежей
--от 75 до 100 тыс - кол-во платежей
--от 100 - кол-во платежей
, t as (
select a.* 
,  b.Квартал Квартал
,  b.Месяц [Месяц]
,  b.Год [Год платежа]
,  b.[Полугодие] [Полугодие]
from t2  a join v_Calendar b on a.ДеньПлатежа=b.Дата 
--SELECT top (select * from _birs_top_N a)
--a.* 
--, case when ПлатежнаяСистема in ( 'ECommPay' , 'Cloud payments') then 'Онлайн' else 'Офлайн' end [Онлайн офлайн]
--, case when IsInstallment=1 then 'Инст' else 'ПТС' end [Продукт]
--
--,  b.Квартал Квартал
--,  b.Месяц [Месяц]
--,  b.Год [Год платежа]
--,  b.[Полугодие] [Полугодие]
--, case 
--when Сумма<=10000 then '1) 0..10000]'
--when Сумма<=100000 then '2) 10000..100000]'
--else '3) 100000)+' end [Сумма бакет]
----when Сумма<=100000 then '3) 100000)+' end [Сумма бакет]
--from mv_repayments a join v_Calendar b on a.ДеньПлатежа=b.Дата 
----where b.Дата>='20210701'

)

, v as (

select case when ПлатежнаяСистема='Киви' then 'Contact' else ПлатежнаяСистема end    ПлатежнаяСистема, ДеньПлатежа, Месяц, Квартал 
, Полугодие
, [Год платежа]
, [Онлайн офлайн]
, [Продукт]
, dpdbeginday
, [Сумма бакет]
, created									     =max( created)
, Количество									     =count( Сумма                         )
, Сумма									             =sum( Сумма                         )
, Прибыль									         =sum( Прибыль                         )
, ПрибыльБезНДС								         =sum( ПрибыльБезНДС				   )
, [Прибыль модель оплаты 1]					         =sum( [Прибыль модель оплаты 1]	   )
, [Прибыль модель оплаты 2]					         =sum( [Прибыль модель оплаты 2]	   )
, [Прибыль модель оплаты 3]					         =sum( [Прибыль модель оплаты 3]	   )
--, [Прибыль модель оплаты 3 2% инст]					 =sum( case when IsInstallment=1 and [Прибыль модель оплаты 2]>0 then  case when Сумма*0.02<100 then 100 else Сумма*0.02 end-case when (Сумма+case when Сумма*0.02<100 then 100 else Сумма*0.02 end)*0.0037 < 35 then 35 else (Сумма+case when Сумма*0.02<100 then 100 else Сумма*0.02 end)*0.0037 end 
--else [Прибыль модель оплаты 2] end
--	   )
	   
--, 
--[Прибыль модель оплаты 3 3% инст]					 =sum( case when IsInstallment=1 and [Прибыль модель оплаты 2]>0 then  case when Сумма*0.03<100 then 100 else Сумма*0.03 end-case when (Сумма+case when Сумма*0.03<100 then 100 else Сумма*0.03 end)*0.0037 < 35 then 35 else (Сумма+case when Сумма*0.03<100 then 100 else Сумма*0.03 end)*0.0037 end 
--else [Прибыль модель оплаты 2] end
--	   )	   
--, [Прибыль модель оплаты 3 5% инст]					                 =sum( case when IsInstallment=1 and [Прибыль модель оплаты 2]>0 then  case when Сумма*0.05<100 then 100 else Сумма*0.05 end-case when (Сумма+case when Сумма*0.05<100 then 100 else Сумма*0.05 end)*0.0037 < 35 then 35 else (Сумма+case when Сумма*0.05<100 then 100 else Сумма*0.05 end)*0.0037 end 
--else [Прибыль модель оплаты 2] end
--	   ), 
,[Прибыль модель оплаты 3 5% инст 20-80]					 =sum( case when IsInstallment=1 and [Прибыль модель оплаты 2]>0 then  case when Сумма*0.05<100 then 100 else Сумма*0.05 end-case when (Сумма+case when Сумма*0.05<100 then 100 else Сумма*0.05 end)*0.0020 < 35 then 35 else (Сумма+case when Сумма*0.05<100 then 100 else Сумма*0.05 end)*0.0020 end 
else [Прибыль модель оплаты 2] end
	   )
, [Прибыль расчетная екомм]					         =sum( [Прибыль расчетная екомм]) 
, [Прибыль расчетная екомм без ндс]					         =sum( [Прибыль расчетная екомм без ндс]) 
, [netProfit]  =sum( case when ПлатежнаяСистема='EcommPay'  then [Прибыль расчетная екомм без ндс]  else ПрибыльБезНДС end  )  
	    

from t
group by  case when ПлатежнаяСистема='Киви' then 'Contact' else ПлатежнаяСистема end   , ДеньПлатежа 
					 
, IsInstallment
, dpdbeginday
, [Год платежа]
, Квартал
, Полугодие
, Месяц
, [Онлайн офлайн]
, [Продукт]
, [Сумма бакет]

)
, d as (
 select [Год платежа]  [Отчетная дата]  , 'Год'      [Тип отчетной даты]  , * from v union all
 --select Полугодие   [Отчетная дата]  , 'Полугодие'      [Тип отчетной даты]  , * from v union all
 select Месяц                                          [Отчетная дата]  , 'Месяц'    [Тип отчетной даты]  , * from v union all
 select ДеньПлатежа                                          [Отчетная дата]  , 'День'    [Тип отчетной даты]  , * from v union all
 select Квартал                                        [Отчетная дата]  , 'Квартал'  [Тип отчетной даты]  , * from v 

)


,
with_x as (
select Измерения_x = 'Платежная система + продукт' ,Измерение_x1 = ПлатежнаяСистема, Измерение_x2 = Продукт, * from d union all
select Измерения_x = 'Продукт' ,Измерение_x1 = Продукт, Измерение_x2 = null, * from d  union all
select Измерения_x = 'Бакет сумма платежа' ,Измерение_x1 = [Сумма бакет], Измерение_x2 = null, * from d  union all
select Измерения_x = 'Продукт (только Ecommpay)' ,Измерение_x1 = Продукт, Измерение_x2 = null, * from d where d.ПлатежнаяСистема='EcommPay'  union all
select Измерения_x = 'Онлайн/Офлайн' ,Измерение_x1 = [Онлайн офлайн], Измерение_x2 = null, * from d
)


select --top 10000000000
*
into #_birs_mv_report_repayments	    

from (
select Измерения_y = 'Дата Продукт' ,Измерение_y1 =  format([Отчетная дата] , 'yyyy-MM-dd') , Измерение_y2 = Продукт , * from with_x union all
select Измерения_y = 'Дата Бакет сумма платежа' ,Измерение_y1 =   format([Отчетная дата] , 'yyyy-MM-dd')  , Измерение_y2 = [Сумма бакет], * from with_x-- union all
) x
--where [Тип отчетной даты]='Месяц'
--order by [Отчетная дата], [Тип отчетной даты]

   --Начало блока обработки ошибок
   BEGIN TRY

           drop table if exists _birs_mv_report_repayments
		   select top 0 *  into _birs_mv_report_repayments
		   from	 #_birs_mv_report_repayments

        --Инструкции, в которых могут возникнуть ошибки
		begin tran




       			 truncate table _birs_mv_report_repayments
       			 insert into _birs_mv_report_repayments
				 select   *	 from	 #_birs_mv_report_repayments
			--	 select 1/0
				  commit tran
   END TRY
   --Начало блока CATCH
   BEGIN CATCH
        --Действия, которые будут выполняться в случае возникновения ошибки
			rollback tran
	begin tran


        SELECT ERROR_NUMBER() AS [Номер ошибки],
                   ERROR_MESSAGE() AS [Описание ошибки]
  		   drop table if exists _birs_mv_report_repayments
		   select *  into _birs_mv_report_repayments
		   from	 #_birs_mv_report_repayments
				  commit tran
  
   END CATCH



	    


end

if @mode='repayments_select'
begin
select *, 1 as rn from _birs_mv_report_repayments
--select * from (select *, ROW_NUMBER() over(partition by Измерения_x,Измерение_x1 ,Измерение_x2, Месяц, Полугодие , [Онлайн офлайн], [Онлайн офлайн] , Измерение_y1 , Измерение_y2, Измерения_y order by Количество ) as rn from _birs_mv_report_repayments) x where rn=1
end

if @mode='load_fin_data'
begin
	 
drop table if exists #fin_data1, #fin_data2, #fin_data3


select МесяцПлатежа, Сумма, case when ПлатежнаяСистема in ( 'Contact', 'QIWI') then 'Киви' else ПлатежнаяСистема end ПлатежнаяСистема  into #fin_data1 from v_repayments
where МесяцПлатежа>='20200101'

--select * from stg.files.[расходы и доходы от пш_stg]
;
with b
as
(

SELECT 
       [Месяц]                         [Месяц]
      ,[Cloud payments выдачи]		  [Cloud payments выдачи]
      ,[Cloud payments погашения]	  [Cloud payments погашения]
      ,[КИВИ БАНК (АО) выдачи]		  [КИВИ БАНК (АО) выдачи]
      ,[КИВИ БАНК (АО) погашения]	  [КИВИ БАНК (АО) погашения]
      ,[БРС выдачи]					  [БРС выдачи]
      ,[БРС погашения]				  [БРС погашения]
      ,[ECommPay выдачи]			  [ECommPay выдачи]
      ,[ECommPay погашения]			  [ECommPay погашения]
	  ,[СБП выдачи]                   [СБП выдачи]
      ,[created]					  [created]
  FROM [Stg].[files].[расходы и доходы от пш_stg]
  )

select a.*
,
perc 
= 
case 
when a.ПлатежнаяСистема = 'Cloud payments' then [Cloud payments погашения]/Сумма 
when a.ПлатежнаяСистема = 'Киви' then [КИВИ БАНК (АО) погашения]/Сумма 
when a.ПлатежнаяСистема = 'ECommPay' then [ECommPay погашения]/Сумма 


end
into #fin_data2
from (
select МесяцПлатежа,ПлатежнаяСистема, sum(Сумма) Сумма
from #fin_data1 a
where МесяцПлатежа>='20200101'
group by  МесяцПлатежа,ПлатежнаяСистема
) a 
join  b on a.МесяцПлатежа=b.Месяц
order by  МесяцПлатежа,ПлатежнаяСистема






select c.Месяц ,a.ПлатежнаяСистема, a.perc
into #fin_data3
from #fin_data2 a
join v_Calendar c on c.Дата>a.МесяцПлатежа

where МесяцПлатежа = (
select max(МесяцПлатежа) from #fin_data2 )
and c.Дата=c.Месяц
union all
select МесяцПлатежа, ПлатежнаяСистема, perc from #fin_data2
order by 2, 1

--drop table if exists dbo.repayments_rates
--select *, GETDATE() as created into  dbo.repayments_rates
--from #T3


--drop table if exists _____
--select * into _____ from ########
delete from dbo.repayments_rates
insert into dbo.repayments_rates
select *, GETDATE() as created  from #fin_data3

end

if @mode='fin_data'
begin

SELECT *
  FROM [Stg].[files].[расходы и доходы от пш_stg]
 



  end

  if @mode='repayments'
begin

SELECT 	ДеньПлатежа, Сумма,IsInstallment, ПлатежнаяСистема, [Прибыль расчетная екомм без НДС], ПрибыльБезНДС, productType
FROM mv_repayments
where ДеньПлатежа>='20221101'
 



  end


  if @mode='payments'
begin

SELECT  cast( [Дата] as date)   [Дата]
      ,cast( [Дата выдачи] as date)  [Дата выдачи]
     -- ,[Дата выдачи месяц]
      ,[Платежная система]
      ,[Код]
      ,[Сумма]
      ,[Способ выдачи]
    --  ,[ссылка]
      ,[Комиссия]
     -- ,[created]
      ,[isInstallment]
	  , producttype productType
  FROM [Analytics].[dbo].[v_payments]
where [Дата выдачи]>='20221101'
 



  end

 

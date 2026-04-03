
--exec [dbo].[reportCollection_KA_paymentKA_dwh142] 
create  PROCEDURE [collection].[reportCollection_KA_paymentKA_dwh142] 

	-- Add the parameters for the stored procedure here

@PageNo int
--, @dtFrom date 
--, @dtTo date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Создаем структуру для отчета соединяем календарь с найденными коллекторскими агенствами
drop table if exists #calendar
select cast(created as date) dt
	   ,k.[Наименование КА]
into #calendar
from dwh_new.dbo.calendar
cross join (select distinct [Наименование КА] from [Stg].[_Collection].[dwh_ka_buffer]) k
where cast(created as date) between '20190101' and dateadd(day ,1 ,cast(getdate() as date))
-- select * from #calendar where dt >='20200901'
--select * from stg._Collection.[Payment]


-- создаем временную таблицу с ка и переданными договорами
drop table if exists #dwh_ka_buffer
select [external_id]
      ,[Наименование КА]
      ,[Тип взыскания]
      ,[ИНН КА]
      ,[Количество размещений]
      ,[Текущий Wash]
      ,[Текущий статус]
      ,[№ реестра передачи]
      ,[Дата передачи в КА]
	  ,lead([Дата передачи в КА]) over(partition by [external_id] order by [Дата передачи в КА]) [След.дата передачи в КА]
	  ,case 
		when lead([Дата передачи в КА]) over(partition by [external_id] order by [Дата передачи в КА]) is null 
			then cast(getdate() as date) 
		else lead([Дата передачи в КА]) over(partition by [external_id] order by [Дата передачи в КА])
	  end [След.дата передачи в КА_2]
      ,[Дата отзыва]
      ,[Плановая дата отзыва]
      ,[Сумма долга, переданная в КА]
into #dwh_ka_buffer
from [Stg].[_Collection].[dwh_ka_buffer]

-- 
drop table if exists #ka_loans
select distinct [external_id] ,[Наименование КА] ,[Дата передачи в КА] ,[№ реестра передачи]
into #ka_loans
from #dwh_ka_buffer


-- объединяем календарь с информацией по ка
drop table if exists #calendar_ka
select c.[dt]  
	  ,c.[Наименование КА]
	  ,k.[external_id]      
      ,k.[Тип взыскания]
      ,k.[ИНН КА]
      ,k.[Количество размещений]
      ,k.[Текущий Wash]
      ,k.[Текущий статус]
      ,k.[№ реестра передачи]
      ,k.[Дата передачи в КА]
	  ,k.[След.дата передачи в КА]
	  ,k.[След.дата передачи в КА_2] [След.дата передачи в КА_2/тек.дата]
      ,k.[Дата отзыва]
      ,k.[Плановая дата отзыва]
      ,k.[Сумма долга, переданная в КА] 
into #calendar_ka
from #calendar c
left join #dwh_ka_buffer k on cast(c.dt as date)=cast(k.[Дата передачи в КА] as date) and c.[Наименование КА]=k.[Наименование КА]
--order by 1 desc
-- select * from #calendar_ka where dt > '20200901'


drop table if exists #res_tbl_1
select dt
      --,[external_id]
	  ,[Наименование КА]
      --,[Тип взыскания]
      --,[ИНН КА]
      --,[Количество размещений]
      --,[Текущий Wash]
      --,[Текущий статус]
      ,[№ реестра передачи]
      ,[Дата передачи в КА]
	  --,[След.дата передачи в КА_2/тек.дата]
      --,[Дата отзыва]
      --,[Плановая дата отзыва]
	  ,count(distinct [external_id]) [Кол-во договоров, переданных в КА]
      ,cast(sum([Сумма долга, переданная в КА]) as numeric(37,2)) [Сумма долга, переданная в КА] 

into #res_tbl_1
from #calendar_ka
group by dt ,[Наименование КА] ,[№ реестра передачи] ,[Дата передачи в КА] --,[След.дата передачи в КА_2/тек.дата]
 order by 1 desc


/*
drop table if exists #calendar_ka
select c.dt ,k.*
into #calendar_ka
from #calendar c
cross join #dwh_ka_buffer k
--select * from #calendar_ka where dt >= [Дата передачи в КА]
*/

drop table if exists #min_dt_dwh_ka_buffer
select  min([Дата передачи в КА]) min_dt 
		,external_id 
into #min_dt_dwh_ka_buffer 
from #dwh_ka_buffer 
group by external_id


drop table if exists #dm_CMRStatBalance_2
select  --* 
		d
		,b.external_id
		,[Сумма]
		,[остаток од]
		,[остаток всего]
		,[сумма поступлений]
		,[сумма поступлений  нарастающим итогом]
		,dpd [дней просрочки]
		,[dpd day-1] [дней просрочки вчера]
into #dm_CMRStatBalance_2 
-- select *
from reports.[dbo].[dm_CMRStatBalance_2] b
join #min_dt_dwh_ka_buffer m on b.external_id=m.external_id and b.d >= m.min_dt
--where external_id in (select distinct external_id from #dwh_ka_buffer)

drop table if exists #ka_loans_payment
select b.d [Дата поступления ДС] ,b.external_id ,k.[Наименование КА] ,k.[Дата передачи в КА] ,k.[№ реестра передачи] ,b.[сумма поступлений] 
into #ka_loans_payment

from #ka_loans k
left join (select d ,external_id ,[сумма поступлений] from #dm_CMRStatBalance_2 where [сумма поступлений] is not null) b
	on k.external_id=b.external_id
where b.[сумма поступлений] is not null

/*
select * from #dm_CMRStatBalance_2  where external_id in ('18061023380001' ,'19040824120002') and d >= '20200717' order by 1 desc
 select d	,external_id ,[сумма поступлений] from reports.[dbo].[dm_CMRStatBalance_2] where external_id in ('18061023380001' ,'19040824120002') and d >= '20200717' order by 1 desc
 */

drop table if exists #Deals
select	distinct
		Id
		,Number external_id
		,(c.[Фамилия]+' '+c.[Имя]+' '+c.[Отчество]) fio_client
into #Deals
-- select *
from Stg._Collection.Deals d
left join [Stg].[_1cCMR].[Справочник_Договоры] c on d.Number=c.[Код]
where number in (select distinct external_id from #dwh_ka_buffer)

drop table if exists #external_id_fio
select [Код] external_id ,([Фамилия]+' '+[Имя]+' '+[Отчество]) fio_client 
into #external_id_fio
from [Stg].[_1cCMR].[Справочник_Договоры]


drop table if exists #Payment
select c.external_id /*,c.fio_client*/ ,p.* ,m.min_dt ,1 qty_pay
into #Payment
from stg._Collection.[Payment] p
join #Deals c on p.Id=c.Id
left join #min_dt_dwh_ka_buffer m on c.external_id=m.external_id and cast(p.PaymentDt as date) >= m.min_dt
--where cast(p.PaymentDt as date) >= m.min_dt
-- select * from stg._Collection.[Payment] p left join #Deals c on p.Id=c.Id where c.external_id in ('18061023380001' ,'19040824120002')


drop table if exists #calendar_ka_pay
select dt
      ,case when k.[external_id] is null then klp.external_id else k.[external_id] end [external_id]
	  ,k.[Наименование КА]
      ,case when k.[№ реестра передачи] is null then klp.[№ реестра передачи] else k.[№ реестра передачи] end [№ реестра передачи]
      ,case when k.[Дата передачи в КА] is null then klp.[Дата передачи в КА] else k.[Дата передачи в КА] end [Дата передачи в КА]
	  --,[След.дата передачи в КА]
	  --,[След.дата передачи в КА_2/тек.дата]
      ,[Сумма долга, переданная в КА] 
	  --,fio_client [ФИО клиента] 
	  ,klp.[Дата поступления ДС] [Дата платежа] /*PaymentDt [Дата платежа]*/
	  ,klp.[сумма поступлений] [Сумма платежа] /*Amount [Сумма платежа]*/
/*	  ,b.[сумма поступлений] [Сумма платежа ЦМР]*/

into #calendar_ka_pay
--select *
from #calendar_ka k --where dt >=' 20200901'/*external_id in ('18061023380001' ,'19040824120002')  --is not null*/
/*left join (select external_id /*,fio_client*/ ,cast(PaymentDt as date) PaymentDt ,Amount from #Payment) p 
	on k.external_id = p.external_id and (p.PaymentDt between [Дата передачи в КА] and [След.дата передачи в КА_2/тек.дата])*/
/* left join #external_id_fio f 
	on k.external_id =f.external_id */
left join #ka_loans_payment klp
	on k.dt = klp.[Дата поступления ДС] and k.[Наименование КА] = klp.[Наименование КА]

/*
left join (select min(d) d ,external_id ,sum([сумма поступлений]) [сумма поступлений] 
		   from #dm_CMRStatBalance_2
		   --where external_id in ('18061023380001' ,'19040824120002') 
		   group by external_id 
		   --order by 1 desc
		  ) b
	on k.external_id = b.external_id and k.dt=b.d
*/
--where k.external_id is not null
order by 8 ,1 desc

-- select * from #calendar_ka_pay where external_id in ('18061023380001' ,'19040824120002')


drop table if exists #calendar_ka_pay_balance
select c.* ,f.fio_client [ФИО клиента] ,b.[остаток од] ,b.[остаток всего] ,b.[сумма поступлений] [сумма поступлений ЦМР] ,b.[дней просрочки] ,b.[дней просрочки вчера]
into #calendar_ka_pay_balance
from #calendar_ka_pay c
left join (select * from #dm_CMRStatBalance_2) b on c.dt=b.d and c.external_id=b.external_id
left join #external_id_fio f on c.external_id =f.external_id
order by 1 desc

-- select * from #calendar_ka_pay_balance where external_id in ('18061023380001' ,'19040824120002')


drop table if exists #res_tbl_2
select dt
	   ,[ФИО клиента]
	   ,external_id [Номер договора]
	   ,[Сумма долга, переданная в КА] [Задолженность, переданная в КА]
	   ,[остаток всего] [Сумма баланса по договору]
	   ,[Наименование КА]
	   ,[Сумма платежа] [Сумма платежа] /*[Сумма платежа]*/
	   ,[Дата платежа]
	   ,([дней просрочки вчера]+1) [Количество дней задолженности на дату оплаты]
	   ,[№ реестра передачи] [№ реестра передачи в работу КА]
	   ,[Дата передачи в КА]
	   --,[След.дата передачи в КА_2/тек.дата]
into #res_tbl_2
from #calendar_ka_pay_balance
order by 1 desc ,3 desc

-- select * from #res_tbl_2 where [Номер договора] in ('18061023380001' ,'19040824120002')

 if @PageNo=1

 select t1.* ,t2.[Количество платежей] ,t2.[Сумма платежей]
 from (select * 
	   from #res_tbl_1 
	   where [Кол-во договоров, переданных в КА] <> 0/* and [Наименование КА]='ООО «Поволжский центр урегулирования убытков»'
			and [№ реестра передачи] is not null
	   --order by  1 desc ,3 desc*/
	   ) t1 --where dt=cast(@dtFrom as date) and dt=cast(@dtFrom as date)
 left join 
 (
 select /*[Дата платежа] dt
	   ,*/[Наименование КА]
	   ,[№ реестра передачи в работу КА] [№ реестра передачи]
	   ,count(*/*[Сумма платежа]*/) [Количество платежей]
	   ,sum([Сумма платежа]) [Сумма платежей]
	   ,[Дата передачи в КА]
	   --,[След.дата передачи в КА_2/тек.дата]
--select *	   
 from #res_tbl_2
 where [Дата платежа] is not null /*and [Наименование КА]='ООО «Поволжский центр урегулирования убытков»'*/
 group by /*[Дата платежа] ,*/[Наименование КА] ,[№ реестра передачи в работу КА] ,[Дата передачи в КА] --,[След.дата передачи в КА_2/тек.дата]
 --order by 5 desc ,2 desc
 ) t2
 on /*t1.dt>=t2.dt and t2.dt */t1.[Дата передачи в КА] = t2.[Дата передачи в КА] 
		and t1.[Наименование КА]=t2.[Наименование КА] and t1.[№ реестра передачи]=t2.[№ реестра передачи]
--where t1.[Наименование КА]='ООО «Поволжский центр урегулирования убытков»'
order by 1 desc

-- if @PageNo=12



 if @PageNo=2

  select *
 from #res_tbl_2

 END





/*

*/
CREATE PROCEDURE [finAnalytics].[addDAPP_region] 
    
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	declare @subjectHeader  nvarchar(250) ='ДАПП Регион', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Обновление данных в ДАПП Регион: ',FORMAT(getdate(), 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
	

 begin try	
  begin tran 
	truncate table dwh2.finAnalytics.DAPP_region
	--drop table if exists #regionDAPP
	--select 
	--	reg=region
	--	,repyear=year(dateBalance)

	--into #regionDAPP
	--from
	--	dwh2.finAnalytics.DAPP
	--where region is not null and year(dateBalance) is not null 
	--group by region,year(dateBalance)
	drop table if exists #regionDAPP
	select
		distinct
		l1.reg
		,l1.repyear
	into #regionDAPP
	from (
		select 
			reg=region
			,repyear=year(dateBalance)
		from
			dwh2.finAnalytics.DAPP
		where region is not null and year(dateBalance) is not null
		group by region,year(dateBalance)
		union all
		select 
			reg=region
			,repyear=year(dateSale)
		from
			dwh2.finAnalytics.DAPP
		where region is not null and year(dateSale) is not null
		group by region,year(dateSale)
		)l1
	insert into dwh2.finAnalytics.DAPP_region
	select
		repyear=l1.repyear
		,region=l1.reg
		,summSpisZalog_datePogaZalog=l1.r1  --[Сумма погашения за счет залога]
		,summPriceBalance_dateBalance=l1.r2 --[Сумма авто принятых на баланс]
		,summPriceBalance_dateSale=l1.r3 --[Балансовая цена реализованных авто]
		,summPriceSale_dateSale=l1.r4 --[сумма оплаты]
		,summNDS_dateSale=l1.r5 --[НДС]
		,countAutoIn_dateBalance=l1.r6 --[количество поступивших машин]
		,countSaleAuto_dateSale=l1.r7 --[количество реализованных машин]
	from(
		select 
			reg=reg
			,repyear=eomonth(datefromparts(repyear,1,1))
			--r1 /*[сумма погашения за счет залога]сумма по "списание задолженности (ОД и %) на авто", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2*/
			,r1=(select sum(isnull(summSpisZadolODPRC,0)) from dwh2.finAnalytics.DAPP where year(datePogaZalog)=repyear and region=reg)
	
			--r2 /*[сумма авто принятых на баланс]сумма по "цене принятия на баланс", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
			,r2=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where year(dateBalance) =repyear and region=reg),0)
	
			--r3 /*[балансовая стоимость реализованных авто]сумма по "цене принятия на баланс", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2*/
			,r3=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where year(dateSale) =repyear and region=reg),0)
	
			--r4 /*[сумма оплаты]сумма по ""цена продажи(расчеты с покупателем)у которых ""дата продажи"" больше или равна Дате1 и меньше или равна Дате2"*/
			,r4=isnull((select sum(isnull(priceSale,0)) from dwh2.finAnalytics.DAPP where year(dateSale) =repyear and region=reg),0)
	
			--r5 /*[НДС]сумма по "НДС", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2*/
			,r5=isnull((select sum(isnull(NDS,0)) from dwh2.finAnalytics.DAPP where year(dateSale) =repyear and region=reg)	,0)
	
			--r6 /*[количество поступивших машин]количество записей, у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
			,r6=isnull((select count(*) from dwh2.finAnalytics.DAPP where year(dateBalance) =repyear and region=reg),0)
	
			--r7 /*[количество реализованных машин]количество записей, у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2*/
			,r7=isnull((select count(*) from dwh2.finAnalytics.DAPP where year(dateSale) =repyear and region=reg),0)
		from #regionDAPP )l1

  commit tran

	
	--set @subject=concat('OK! ',@subjectHeader) 
	--set @message=''
	--set @message=concat(@msgHeader,@message,@msgFloor)
	--exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

 end try 

 begin catch
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    ROLLBACK TRANSACTION
	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
   ;throw 51000 
			,@message
			,1;    
  end catch

END



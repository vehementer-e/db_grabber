
CREATE PROC [finAnalytics].[loadRepMicrozaimData_Produkt] 
    @historyDaysCount int   ---Параметр кол-ва последних дней для пересчета, если -1  считает всю историю
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

	declare @subjectHeader  nvarchar(250) ='Микрозаймы RR выдачи ', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Обновление данных по продуктам: ',FORMAT(getdate(), 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
       
begin try

    --declare @historyDaysCount int =-1
  declare @startDate date = dateadd(day,-@historyDaysCount,getdate())
  begin tran  
    --Заполнение временной таблицы дат всем диапазоном
    if @historyDaysCount = -1
		begin 
			truncate table dwh2.finAnalytics.repMicrozaim_Produkt
			set @startDate='2025-01-01'
		end
    else 
		--Очистка таблицы результата по выбранному перечню дат
			delete from dwh2.finAnalytics.repMicrozaim_Produkt
					where repdate >= @startDate
	--Заполнение 
	insert into dwh2.finAnalytics.repMicrozaim_Produkt (repdate, produkt, produktInSales)---PRC, produktInSalesRR)
		select
			repdate=micro.repdate
			,produkt=isnull(dwh2.finAnalytics.nomenk2prod (nomgroup.Наименование),'Продукт не определен')
			,produktInSales=sum(a.Сумма)
		from dwh2.finAnalytics.repMicrozaim micro
		left join stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a on micro.repdate=dateadd(year,-2000,cast(a.Период as date))
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0x00
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0x00
		left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog on a.СубконтоDt2_Ссылка=dog.Ссылка
		left join stg._1cUMFO.Справочник_НоменклатурныеГруппы nomgroup on dog.АЭ_НоменклатурнаяГруппа=nomgroup.Ссылка
		where a.Активность=0x01
			and b.Код in ('48801','48701','49401')	
			and micro.repdate>=@startDate
		group by micro.repdate,micro.sales,micro.salesRR,[finAnalytics].[nomenk2prod] (nomgroup.Наименование)


		
 commit tran	
	
	set @subject=concat('OK! ',@subjectHeader) 
	set @message=concat('Данные обновлены ',iif( @historyDaysCount=-1 ,'полностью',concat('за период ',@historyDaysCount)))
	set @message=concat(@msgHeader,@message,@msgFloor)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
	
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

end try
 begin catch
    ROLLBACK TRANSACTION

	----кэтч
   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem


	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
   ;throw 51000 
			,@message
			,1;    
  end catch
END

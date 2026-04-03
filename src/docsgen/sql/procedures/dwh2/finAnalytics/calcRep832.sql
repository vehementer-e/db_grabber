


CREATE PROC [finAnalytics].[calcRep832] 
    @repmonth date
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = 'Выполнение процедуры расчета данных по форме 832'
       
    begin try

	declare @qName nvarchar(30)  
declare @repmonthFrom date
declare @repmonthTo date

set @qName = (
select distinct
Year_Quartal_Name
from dwh2.Dictionary.calendar dd
where dd.Month_Value = @repmonth
)

set @repmonthFrom = (
select 
min(Month_Value)
from dwh2.Dictionary.calendar dd
where Year_Quartal_Name = @qName
)

set @repmonthTo = @repmonth--(
--select 
--max(Month_Value)
--from dwh2.Dictionary.calendar dd
--where Year_Quartal_Name = @qName
--)

drop table if exists #rep
create table #rep(
	qName nvarchar(30) not null,
	repmonth date not null,
	rowNum int not null,
	dogCode nvarchar(300) not null,
	PDNInterval nvarchar(30) null,
	srokInterval float null,
	sumInterval float null,
	allZaim float null,
	allZaimpayBack float null,
	sumAllZaim float null,
	sumAllZaimpayBack float null,
	zaimPDN int null,
	sumZaimPDN float null
)

insert into #rep
select
qName	
,repmonth	
,rowNum	
,dogCode	
,PDNInterval	
,srokInterval = sum(l2.srokInterval)
,sumInterval = sum(l2.sumInterval)
,allZaim = sum(l2.allZaim)
,allZaimpayBack = sum(l2.allZaimpayBack)
,sumAllZaim = sum(l2.sumAllZaim)
,sumAllZaimpayBack = sum(l2.sumAllZaimpayBack)
,zaimPDN = sum(l2.zaimPDN)
,sumZaimPDN = sum(l2.sumZaimPDN)

from(
select
qName = l1.qName
,repmonth = l1.repmonth
,rowNum = case 
			when dogCode = '1 - Иные потребительские кредиты (займы)' and PDNInterval = '(50; 80]' then 1
			when dogCode = '1 - Иные потребительские кредиты (займы)' and PDNInterval = 'более 80' then 2

			when dogCode = '2 - Потребительские кредиты (займы) на приобретение автотранспортного средства под залог автотранспортного средства' and PDNInterval = '(50; 80]' then 3
			when dogCode = '2 - Потребительские кредиты (займы) на приобретение автотранспортного средства под залог автотранспортного средства' and PDNInterval = 'более 80' then 4

			when dogCode = '3 - Потребительские кредиты (займы) по залог автотранспортного средства' and PDNInterval = '(50; 80]' then 5
			when dogCode = '3 - Потребительские кредиты (займы) по залог автотранспортного средства' and PDNInterval = 'более 80' then 6
		else 0 end
,dogCode = l1.dogCode
,PDNInterval = l1.PDNInterval
,srokInterval = 0
,sumInterval = 0
,allZaim = 0
,allZaimpayBack = 0
,sumAllZaim = 0
,sumAllZaimpayBack = 0
,zaimPDN = isnull(l1.dogCount,0)
,sumZaimPDN = isnull(l1.dogSum,0)
,allPotreb = null
,sumAllPotreb = null
,PDNOnRepDate = l1.PDNOnRepDate
from(
select
qName = @qName
,repmonth = @repmonthTo
,dogNum = a.dogNum
,isZaemshik = a.isZaemshik
,dogStatus = a.dogStatus
,isDogPoruch = a.isDogPoruch
,dogCode = case 
				when upper(a.isDogPoruch) in (upper('Залог самоходных машин'))
					or a.isDogPoruch is null then '1 - Иные потребительские кредиты (займы)'
				when upper(a.isDogPoruch) in (upper('Залог Автомототранспортного средства'))
					and upper(a.nomenkGroup) = upper('Автокредит') then '2 - Потребительские кредиты (займы) на приобретение автотранспортного средства под залог автотранспортного средства'
				when upper(a.isDogPoruch) in (upper('Залог Автомототранспортного средства'))
					and upper(a.nomenkGroup) not in (upper('Автокредит'),upper('ПТС Займ для Самозанятых')) then '3 - Потребительские кредиты (займы) по залог автотранспортного средства'
				else '0'
			end
,PDNOnRepDate = a.PDNOnRepDate
,PDNInterval = case
				when a.PDNOnRepDate <= 0.5 then 'до 50'
				when a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8 then '(50; 80]'
				when a.PDNOnRepDate > 0.8 then 'более 80'
				else '-'
				end
,nomenkGroup = a.nomenkGroup
,dogCount = 1
,dogSum = a.dogSum
from dwh2.finAnalytics.PBR_MONTHLY a
where a.repmonth = @repmonthTo
and upper(isZaemshik) = 'ФЛ'
and upper(dogStatus) in (upper('Действует'),upper('Закрыт'))
and a.saleDate between @repmonthFrom and EOMONTH(@repmonthTo)
) l1
) l2

where rowNum >0

group by
qName	
,repmonth	
,rowNum	
,dogCode	
,PDNInterval	

order by rowNum	

--select * from #rep
	

    begin tran  
    
	delete from dwh2.[finAnalytics].[rep832] where [qName] = @qName

	insert into dwh2.[finAnalytics].[rep832]
	select
	*
	from #rep
	

	commit tran
    
	
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from dwh2.[finAnalytics].[rep832]) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 47

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры расчета данных для ф832 за '
				,@qName
                ,char(10)
                ,char(13)
                ,'Время начала выполнения: '
                ,@procStartTime
                ,char(10)
                ,char(13)
                ,'Время окончания выполнения: '
                ,@procEndTime
                ,char(10)
                ,char(13)
                ,'Время выполнения: '
                ,@timeDuration
                ,char(10)
                ,char(13)
                ,'Максимальная отчетная дата: '
                ,@maxDateRest
				,char(10)
                ,char(13)
				,'Ссылка на отчет:'
				,(SELECT [link] FROM [dwh2].[finAnalytics].[SYS_SPR_linkReport] where upper(repName) = upper('Отчет 832'))
				)
	
	declare @emailList varchar(255)=''
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,5))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc


    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	 ----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END

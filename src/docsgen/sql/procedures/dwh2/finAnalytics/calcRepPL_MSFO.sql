


CREATE PROC [finAnalytics].[calcRepPL_MSFO] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для PL для публикуемой. МСФО.'
    declare @emailList varchar(255)=''
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	begin try
	begin tran  
	
	Declare @months table(
	months date not null
	)
insert into @months
select distinct
Month_Value
from dwh2.[Dictionary].[calendar]
where Month_Value = @repmonth

--select * from @months

drop table if exists #rep_form
CREATE table #rep_form(
	rowNum int not null,
	rowName nvarchar(255) not Null,
	rowNameToMerge int null
)

INSERT INTO #rep_form VALUES (1,'Процентные доходы','1')
INSERT INTO #rep_form VALUES (2,'Процентные расходы','2')
INSERT INTO #rep_form VALUES (3,'Чистый процентный доход до формирования оценочных резервов под ожидаемые кредитные убытки по финансовым активам','')
INSERT INTO #rep_form VALUES (4,'Формирование оценочных резервов под ожидаемые кредитные убытки по финансовым активам','4')
INSERT INTO #rep_form VALUES (5,'Чистые процентные доходы','')
INSERT INTO #rep_form VALUES (6,'Общехозяйственные и административные расходы','13')
INSERT INTO #rep_form VALUES (7,'Прочие доходы','15')
INSERT INTO #rep_form VALUES (8,'Прочие расходы','')
INSERT INTO #rep_form VALUES (9,'Прибыль до налогообложения','')
INSERT INTO #rep_form VALUES (10,'Расход по текущему налогу на прибыль','20')
INSERT INTO #rep_form VALUES (11,'Расход по отложенному налогу на прибыль','21')
INSERT INTO #rep_form VALUES (12,'Чистая совокупная прибыль','23')
INSERT INTO #rep_form VALUES (13,'Контроль','')


drop table if exists #rep
create table #rep(
repmonth date not null
,rowNum	int not null
,rowNameToMerge nvarchar(30) null
,pokazatel  nvarchar(255) null
,amountMonth float null
)

insert into #rep

select
b.MONTHS
,a.rowNum
,a.rowNameToMerge
,a.rowName
--,a.pokazatel
,0
from #rep_form a, @months b

/*Заполнение из Summary*/
merge into #rep t1
using(
select
repmonth	
,rowName	
,amountMonth	

from dwh2.finAnalytics.repPLf843_summary
where repmonth = @repmonth
and rowName in ('1','2','4','13','15','20','21')
) t2 on (t1.rowNameToMerge = t2.rowName and t1.repmonth = t2.repmonth)
when matched then update
set t1.amountMonth = t2.amountMonth;

/*Заполнение из Summary несколько строк в одну*/
merge into #rep t1
using(
select
repmonth	
,amountMonth = sum(amountMonth)

from dwh2.finAnalytics.repPLf843_summary
where repmonth = @repmonth
and rowName in ('10','14','16')
group by repmonth	
) t2 on (t1.rowNum = 8 and t1.repmonth = t2.repmonth)
when matched then update
set t1.amountMonth = t2.amountMonth;

/*Расчет итоговых строк*/
merge into #rep t1
using(
select
repmonth	
,amountMonth = sum(amountMonth)
from #rep
where rowNum in (1,2)
group by repmonth	
) t2 on (t1.rowNum = 3 and t1.repmonth = t2.repmonth)
when matched then update
set t1.amountMonth = t2.amountMonth;

merge into #rep t1
using(
select
repmonth	
,amountMonth = sum(amountMonth)
from #rep
where rowNum in (3,4)
group by repmonth	
) t2 on (t1.rowNum = 5 and t1.repmonth = t2.repmonth)
when matched then update
set t1.amountMonth = t2.amountMonth;

merge into #rep t1
using(
select
repmonth	
,amountMonth = sum(amountMonth)
from #rep
where rowNum in (5,6,7,8)
group by repmonth	
) t2 on (t1.rowNum = 9 and t1.repmonth = t2.repmonth)
when matched then update
set t1.amountMonth = t2.amountMonth;

merge into #rep t1
using(
select
repmonth	
,amountMonth = sum(amountMonth)
from #rep
where rowNum in (9,10,11)
group by repmonth	
) t2 on (t1.rowNum = 12 and t1.repmonth = t2.repmonth)
when matched then update
set t1.amountMonth = t2.amountMonth;

/*Контроль*/
merge into #rep t1
using(
select
a.repmonth	
,a.rowNum
--,a.amountMonth
--,b.amountMonth
,amountDiff = a.amountMonth - b.amountMonth
from #rep a
left join (
select
repmonth	
,amountMonth
from dwh2.finAnalytics.repPLf843_summary
where repmonth = @repmonth
and rowName in ('23')
) b on a.repmonth = b.repmonth
where a.rowNum = 12
) t2 on (t1.rowNum = 13 and t1.repmonth = t2.repmonth)
when matched then update
set t1.amountMonth = t2.amountDiff;

	
/*Очистка таблицы от старых данных за отчетный месяц*/
delete from dwh2.[finAnalytics].[repPL_MSFO] where repmonth = @repmonth

/*Добавление новых данных за отчетный месяц*/
INSERT INTO dwh2.[finAnalytics].[repPL_MSFO]
([repmonth], [rowNum], [rowNameToMerge], [pokazatel], [amountMonth])
select 
[repmonth], [rowNum], [rowNameToMerge], [pokazatel], [amountMonth]
from #rep

	commit tran

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    
	DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета PL для публикуемой  '
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients =''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END

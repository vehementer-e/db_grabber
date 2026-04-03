

CREATE PROC [finAnalytics].[calcRepPL843_summary] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для PL для публикуемой. Summary.'
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
	
	declare @repmonthPrev date = dateadd(month,-1,@repmonth)

drop table if exists #rep
create table #rep(
	[repmonth] date not null
	, [rowNum] int not null
	, [rowName] nvarchar(30) null
	, [pokazatel] nvarchar(255) null
	, amounPrev float null
	, amounTek float null
	, amounMonth float null
)

insert into #rep
select
[repmonth] = @repmonth
, [rowNum]
, [rowName]
, [pokazatel]
, amounPrev = 0.0
, amounTek = 0.0
, amounMonth = 0.0

from dwh2.[finAnalytics].[SPR_repPLsummary]

/*Часть 1 из ф843 часть 1*/
merge into #rep t1
using(
SELECT a.[rowNum]
      ,a.[rowName]
      ,a.[pokazatel]
	  ,amounTek = isnull(r1.sumAmount,0)
	  ,amounPrev = isnull(r0.sumAmount,0)
	  ,amounMonth = case when month(@repmonth) = 1 then isnull(r1.sumAmount,0)
						 when month(@repmonth) > 1 then isnull(r1.sumAmount,0) - isnull(r0.sumAmount,0)
						 else null end
FROM [dwh2].[finAnalytics].[SPR_repPLsummary] a
left join [dwh2].[finAnalytics].[repPLf843] r1 on a.rowName = r1.rowName and r1.repmonth = @repmonth 
left join [dwh2].[finAnalytics].[repPLf843] r0 on a.rowName = r0.rowName and r0.repmonth = @repmonthPrev 
where a.rowName in ('1','2','3','4','13','15','16','17','10','14','18','19','20','21','23')
) t2 on (t1.rowName = t2.RowName)
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;


/*Часть 2 из ф843 часть 2*/
merge into #rep t1
using(
select
amounTek = sum(isnull(amounTek,0))
,amounPrev = sum(isnull(amounPrev,0))
,amounMonth = case when month(@repmonth) = 1 then sum(isnull(amounTek,0))
				   when month(@repmonth) > 1 then sum(isnull(amounTek,0)) - sum(isnull(amounPrev,0))
				   else null end
from(
SELECT 
amounTek = case when repmonth = @repmonth then amount else 0 end
,amounPrev = case when repmonth < @repmonth then amount else 0 end
,amounMonth = 0
from [dwh2].[finAnalytics].[repPLf843_part2] 
where repmonth between dateadd(month,-1,@repmonth) and @repmonth
and pokazatel = 'Амортизация ОС и НМА'
) l1
) t2 on (t1.rowName = '62')
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;

merge into #rep t1
using(
select
amounTek = sum(isnull(amounTek,0))
,amounPrev = sum(isnull(amounPrev,0))
,amounMonth = case when month(@repmonth) = 1 then sum(isnull(amounTek,0))
				   when month(@repmonth) > 1 then sum(isnull(amounTek,0)) - sum(isnull(amounPrev,0))
				   else null end
from(
SELECT 
amounTek = case when repmonth = @repmonth 
				then case when pokazatel = 'Резервы по пене и госпошлине (мошенники)' then amount *-1 else amount end
				else 0 end
,amounPrev = case when repmonth < @repmonth 
				then case when pokazatel = 'Резервы по пене и госпошлине (мошенники)' then amount *-1 else amount end
				else 0 end
,amounMonth = 0
from [dwh2].[finAnalytics].[repPLf843_part2] 
where repmonth between dateadd(month,-1,@repmonth) and @repmonth
and pokazatel in ('Резервы по пене и госпошлине, всего','Резервы по пене и госпошлине (мошенники)')
) l1
) t2 on (t1.rowName = '63')
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;


/*Часть 3 из ф843 часть 3*/
merge into #rep t1
using(
SELECT a.[rowNum]
      ,a.[rowName]
      ,a.[pokazatel]
	  ,amounTek = isnull(r1.Amount,0)
	  ,amounPrev = isnull(r0.Amount,0)
	  ,amounMonth = case when month(@repmonth) = 1 then isnull(r1.Amount,0)
						 when month(@repmonth) > 1 then isnull(r1.Amount,0) - isnull(r0.Amount,0)
						 else null end
FROM [dwh2].[finAnalytics].[SPR_repPLsummary] a
left join [dwh2].[finAnalytics].[repPLf843_part3] r1 on a.rowName = r1.pokazatel and r1.repmonth = @repmonth 
left join [dwh2].[finAnalytics].[repPLf843_part3] r0 on a.rowName = r0.pokazatel and r0.repmonth = @repmonthPrev 
where a.rowName in ('2.39.1','2.39.2','2.39.3','2.39.4','2.39.5')
) t2 on (t1.rowName = t2.RowName)
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;


/*Часть 4 Итоги по строкам*/
merge into #rep t1
using(
select 
		amounTek = sum(isnull(amounTek,0))
	  ,amounPrev = sum(isnull(amounPrev,0))
	  ,amounMonth = sum(isnull(amounMonth,0))
from #rep
where rowName in ('1','15')
) t2 on (t1.rowNum = 1)
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;

merge into #rep t1
using(
select 
		amounTek = sum(isnull(amounTek,0))
	  ,amounPrev = sum(isnull(amounPrev,0))
	  ,amounMonth = sum(isnull(amounMonth,0))
from #rep
where rowName in ('3','4')
) t2 on (t1.rowNum = 6)
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;

merge into #rep t1
using(
select 
		amounTek = sum(
						case when rowName != '23' then isnull(amounTek,0) *-1 else isnull(amounTek,0) end
						)
	  ,amounPrev = sum(
						case when rowName != '23' then isnull(amounPrev,0) *-1 else isnull(amounPrev,0) end
						)
	  ,amounMonth = sum(
						case when rowName != '23' then isnull(amounMonth,0) *-1 else isnull(amounMonth,0) end
						)
from #rep
where rowName in ('23','63','19','62','2','4')
) t2 on (t1.rowNum = 13)
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;

merge into #rep t1
using(
select 
		amounTek = sum(
						case when rowName = '62' then isnull(amounTek,0) *-1 else isnull(amounTek,0) end
						)
	  ,amounPrev = sum(
						case when rowName = '62' then isnull(amounPrev,0) *-1 else isnull(amounPrev,0) end
						)
	  ,amounMonth = sum(
						case when rowName = '62' then isnull(amounMonth,0) *-1 else isnull(amounMonth,0) end
						)
from #rep
where rowName in ('3','13','62','15','16')
) t2 on (t1.rowNum = 14)
when matched then update
set t1.amounTek = t2.amounTek
,t1.amounPrev = t2.amounPrev
,t1.amounMonth = t2.amounMonth;

--select * from #rep
	
/*Очистка таблицы от старых данных за отчетный месяц*/
delete from dwh2.[finAnalytics].[repPLf843_summary] where repmonth = @repmonth

/*Добавление новых данных за отчетный месяц*/
INSERT INTO dwh2.[finAnalytics].[repPLf843_summary]
([repmonth], [rowNum], [rowName], [pokazatel], [amountPrev], [amountTek], [amountMonth], [created])
select 
[repmonth], [rowNum], [rowName], [pokazatel], amounPrev, amounTek, amounMonth, getdate()
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

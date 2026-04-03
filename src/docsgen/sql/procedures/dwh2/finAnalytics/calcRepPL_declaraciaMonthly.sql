



CREATE PROC [finAnalytics].[calcRepPL_declaraciaMonthly] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для PL для публикуемой. Месячная декларация'
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

	/*Формирование скелета отчета*/
drop table if exists #rep
create table #rep(
	repmonth date not null,
	rowNum int not null,
	rowName nvarchar(10) not null,
	pokazatel nvarchar(255) null,
	sprCode nvarchar(10) null,
	stavka float null,
	isItog int not null,
	sumAmount float not null
)

insert into #rep 
select
repmonth = @repmonth
,rowNum	
,rowName
,pokazatel	
,sprCode = case when upper(pokazatel)= upper('к уплате') 
				then concat(
							cast(b.stavka * 100 as nvarchar)
							,'%'
							)
				else a.sprCode
				end
,stavka = b.stavka
,isItog
,sumAmount = 0.0

from dwh2.[finAnalytics].[SPR_repPL_declaraciaMonthly] a
left join dwh2.[finAnalytics].[SPR_repPL_NP] b on @repmonth between b.dateFrom and b.dateTo

--select * from #rep

/*Заполнение данными*/

--p1
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.isDeclaracCalc = 'ДР'
) t2 on (t1.rowName = '1' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p2
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.isDeclaracCalc = 'ДВ'
) t2 on (t1.rowName = '2' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p3
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.isDeclaracCalc = 'ДХ'
) t2 on (t1.rowName = '3' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p4
merge into #rep t1
Using(
select
sumAmount = sum(sumAmount)
from #rep a
where a.rowName in ('1','2','3')
) t2 on (t1.rowName = '4' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;


--p6
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.isDeclaracCalc = 'РР'
) t2 on (t1.rowName = '6' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p7
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.isDeclaracCalc = 'РВ'
) t2 on (t1.rowName = '7' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p8
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.isDeclaracCalc = 'РХ'
) t2 on (t1.rowName = '8' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p9
merge into #rep t1
Using(
select
sumAmount = sum(sumAmount)
from #rep a
where a.rowName in ('6','7','8')
) t2 on (t1.rowName = '9' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p11
merge into #rep t1
Using(
select
sumAmount = sum(sumAmount)
from #rep a
where a.rowName in ('4','9')
) t2 on (t1.rowName = '11' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p13
merge into #rep t1
Using(
select
sumAmount = sum(sumAmount)
from #rep a
where a.rowName in ('11','12')
) t2 on (t1.rowName = '13' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p14
merge into #rep t1
Using(
select
sumAmount = round(sumAmount * a.stavka,2)
from #rep a
where a.rowName in ('13')
) t2 on (t1.rowName = '14' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p16
merge into #rep t1
Using(
select
sumAmount = /*case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end*/
			sum(isnull(sumKT_BU,0))
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.accnum = '60323810010000000000'
) t2 on (t1.rowName = '16' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;


--p16.1
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(
												isnull(sumKT_NU,0) - isnull(sumKT_BU,0)
												)
											else
												sum(
												isnull(sumKT_NU,0) - isnull(sumKT_BU,0)
												-
												(isnull(sumDT_NU,0) - isnull(sumDT_BU,0))
												)
											end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.accnum = '71501810003240700000'
) t2 on (t1.rowName = '16.1' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p15
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('16','16.1')
) t2 on (t1.rowName = '15' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p18
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(
												isnull(sumKT_NU,0) - isnull(sumKT_BU,0)
												)
											else
												sum(
												isnull(sumKT_NU,0) - isnull(sumKT_BU,0)
												-
												(isnull(sumDT_NU,0) - isnull(sumDT_BU,0))
												)
											end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.[acc2order] = '71201'
) t2 on (t1.rowName = '18' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p17
merge into #rep t1
Using(
select
sumAmount = isnull(sumAmount ,0)
from #rep a
where a.rowName in ('18')
) t2 on (t1.rowName = '17' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p20
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('17','15')
) t2 on (t1.rowName = '20' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p23
merge into #rep t1
Using(
select
sumAmount = sum(isnull([Сумма корректировки],0))
from dwh2.[finAnalytics].[SPR_PL_OS_NMA] a
where a.repmonth = @repmonth and a.Показатель = 'Амортизация ОС(мебель и офисное оборудование)'
) t2 on (t1.rowName = '23' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p24
merge into #rep t1
Using(
select
sumAmount = sum(isnull([Сумма корректировки],0))
from dwh2.[finAnalytics].[SPR_PL_OS_NMA] a
where a.repmonth = @repmonth and a.Показатель = 'Амортизация НМА'
) t2 on (t1.rowName = '24' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p25
merge into #rep t1
Using(
select
sumAmount = /*case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end*/
			sum(isnull(sumDT_BU,0)) *-1
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.accnum = '60305810000000000002'
) t2 on (t1.rowName = '25' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p26
merge into #rep t1
Using(
select
sumAmount = /*case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end*/
			sum(isnull(sumDT_BU,0))  *-1
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.accnum in ('60335810000000000010','60335810000000000014')
) t2 on (t1.rowName = '26' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p27 часть 1
merge into #rep t1
Using(
select
sumAmount = /*case when month(@repmonth) = 1 then sum(isnull(restOUT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumKT_BU,0) - isnull(sumDT_BU,0))
				 else 0 end*/
			sum(isnull(sumDT_BU,0))  *-1
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.accnum in ('60323810010000000000')
) t2 on (t1.rowName = '27' and t2.sumAmount is not null and t1.pokazatel = 'Судебные и арбитражные издержки')
when matched then update
set t1.sumAmount = t2.sumAmount;

--p27 часть 2 Только Сентябрь 2025
merge into #rep t1
Using(
select
sumAmount = case when @repmonth='2025-09-01' then 1819583 else 0 end
) t2 on (t1.rowName = '27' and t2.sumAmount is not null and t1.pokazatel = 'Корректировка по РКО прошлых лет')
when matched then update
set t1.sumAmount = t2.sumAmount;

--p22
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('23','24','25','26','27')
) t2 on (t1.rowName = '22' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p29
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(isnull(sumDT_NU,0) - isnull(sumDT_BU,0)) *-1
				 when month(@repmonth) > 1 then sum(isnull(sumDT_NU,0) - isnull(sumDT_BU,0) - isnull(sumKT_NU,0) - isnull(sumKT_BU,0)) *-1
				 else 0 end
from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.[acc2order] = '71202'
) t2 on (t1.rowName = '29' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;


--p30
if @repmonth < '2026-01-01'
merge into #rep t1
Using(
select
sumAmount = case when month(@repmonth) = 1 then sum(
												isnull(sumdT_NU,0) - isnull(sumdT_BU,0)
												) * -1
											else
												sum(
												isnull(sumdT_NU,0) - isnull(sumdT_BU,0)
												-
												(isnull(sumkT_NU,0) - isnull(sumkT_BU,0))
												) *-1
											end

from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.accNum = '71502810004140700000'
) t2 on (t1.rowName = '30' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

else

merge into #rep t1
Using(
select
sumAmount = sumAmount + isnull(cu.corrRegistr,0)
from(
select
sumAmount = case when month(@repmonth) = 1 then sum(
												isnull(sumdT_NU,0) - isnull(sumdT_BU,0)
												) * -1
											else
												sum(
												isnull(sumdT_NU,0) - isnull(sumdT_BU,0)
												-
												(isnull(sumkT_NU,0) - isnull(sumkT_BU,0))
												) *-1
											end

from dwh2.[finAnalytics].[SPR_PL_ACC] a
left join dwh2.[finAnalytics].[repPLAccRests] b on a.ID = b.accUID and b.repmonth = @repmonth
where a.accNum = '71502810004140700000'
) l1
left join [dwh2].[finAnalytics].[CessionUbt] cu on dateDogCession = @repmonth
) t2 on (t1.rowName = '30' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p28
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('29','30')
) t2 on (t1.rowName = '28' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p32
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0)) * -1
from #rep a
where a.rowName in ('25')
) t2 on (t1.rowName = '32' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p33
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0)) * -1
from #rep a
where a.rowName in ('26')
) t2 on (t1.rowName = '33' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p31
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('32','33')
) t2 on (t1.rowName = '31' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p34
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('22','28','31')
) t2 on (t1.rowName = '34' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p36
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('20','34')
) t2 on (t1.rowName = '36' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p38
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('36','37')
) t2 on (t1.rowName = '38' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p39
merge into #rep t1
Using(
select
sumAmount = round(sumAmount * a.stavka,2)
from #rep a
where a.rowName in ('38')
) t2 on (t1.rowName = '39' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p40
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('1','15')
) t2 on (t1.rowName = '40' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p41
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('2','17')
) t2 on (t1.rowName = '41' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p43
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('40','41')
) t2 on (t1.rowName = '43' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p45
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('6','22')
) t2 on (t1.rowName = '45' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p46
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('7','28')
) t2 on (t1.rowName = '46' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p48
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('45','46')
) t2 on (t1.rowName = '48' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p50
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('43','48')
) t2 on (t1.rowName = '50' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p52
merge into #rep t1
Using(
select
sumAmount = sum(isnull(sumAmount ,0))
from #rep a
where a.rowName in ('50','51')
) t2 on (t1.rowName = '52' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

--p53
merge into #rep t1
Using(
select
sumAmount = round(sumAmount * a.stavka,2)
from #rep a
where a.rowName in ('52')
) t2 on (t1.rowName = '53' and t2.sumAmount is not null)
when matched then update
set t1.sumAmount = t2.sumAmount;

	
	/*Очистка таблицы от старых данных за отчетный месяц*/
	delete from dwh2.[finAnalytics].[repPLDeclaraciaMonthly] where repmonth = @repmonth

	/*Добавление новых данных за отчетный месяц*/
	INSERT INTO dwh2.[finAnalytics].[repPLDeclaraciaMonthly]
	([repmonth], [rowNum], [pokazatel], [sprCode], [stavka], [isItog], [sumAmount], [rowName])
	select
	repmonth	
	,rowNum
	,pokazatel	
	,sprCode	
	,stavka	
	,isItog	
	,sumAmount
	,rowName	
	from #rep
    
	commit tran
    
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

	end try
    
    begin catch

    
	DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета PL для публикуемой '
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

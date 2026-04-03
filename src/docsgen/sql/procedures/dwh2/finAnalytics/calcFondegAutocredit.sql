
-- exec  [finAnalytics].[calcFondegAutocredit]

CREATE PROC [finAnalytics].[calcFondegAutocredit] 
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

    declare @repdate date
--	declare @repdateTmp date

set @repdate = (select max([ОтчетнаяДата]) from stg.[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных])

begin try
begin tran

drop table if exists #rep
create table #rep(
	[Дата оформления договора] date null
	,[Номер договора] nvarchar(100) null
	,[Сумма по договору] float null
	,[Финансовый  продукт] nvarchar(200) null
	,[ФИО контрагента] nvarchar(300) null
	,[Остаток ОД] float null
	--ЗаймUID
	,[Дата выдачи 48801] date null
	,[Сумма выдачи 48801] float null
	--,[Проверка выдачи шаг 1] nvarchar(10) null
	--,[Номер договора 20501] nvarchar(100) null
	--,[Дата выдачи 20501] date null
	--,[Сумма выдачи 20501] float null
	--,[Проверка выдачи шаг 2] nvarchar(10) null
	--,[rowNum] int null
)

insert into #rep
([Дата оформления договора],[Номер договора],[Сумма по договору],[Финансовый  продукт],[ФИО контрагента],[Остаток ОД]/*,[rowNum]*/)

select --distinct
*
from(
select --distinct
[Дата оформления договора] = cast(dateadd(year,-2000,a.[ДатаДоговора]) as date)
,[Номер договора] = a.[НомерДоговора]
,[Сумма по договору] = a.[СуммаЗайма]
,[Финансовый  продукт] = a.Продукт
,[ФИО контрагента] = a.[НаименованиеЗаемщика]
,[Остаток ОД] = a.ОстатокОДвсего
--,[rowNum] = ROW_NUMBER() over (order by a.[ДатаДоговора])
--,[ЗаймUID] = a.Займ
--,rn = ROW_NUMBER() over (Partition by a.[НомерДоговора] order by b.DWHInsertedDate)

from stg.[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных] a

where ОтчетнаяДата = @repdate--convert(date, dateadd(year, -2000, @repdate))
) l1

where upper(l1.[Финансовый  продукт]) like upper('%АВТОКРЕДИТ%')
and l1.[Дата оформления договора] >= dateadd(day,-40,@repdate)


declare @repDateFromTmp date = (select min([Дата оформления договора]) from #rep)
declare @repDateFrom dateTime = dateadd(year,2000,@repDateFromTmp)

--select @repDateFrom
/* подтягиваем инфу по 48801*/

merge into #rep t1
using(
select
[Дата выдачи] = cast(dateadd(Year,-2000,a.Период) as date)
,[Сумма] = a.[Сумма]
,[Номер договора ДТ] = crdt.Номер
,[Номер договора КТ] = crkt.Номер
,[Дата договора ДТ] = cast(dateadd(Year,-2000,crdt.Дата) as date)

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка

where a.Период >= @repDateFrom
and dt.Код = '48801' and kt.Код = '47422'
) t2 on (t1.[Номер договора] = t2.[Номер договора ДТ])
when matched then update
set t1.[Дата выдачи 48801] = t2.[Дата выдачи]
	,t1.[Сумма выдачи 48801] = t2.[Сумма]
	--,t1.[Номер договора 20501] = t2.[Номер договора КТ];
	;

/*
/* подтягиваем инфу по 47422*/

merge into #rep t1
using(
select
[Дата выдачи] = cast(dateadd(Year,-2000,a.Период) as date)
,[Сумма] = a.[Сумма]
,[Номер договора ДТ] = crdt.Номер

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка

where a.Период >= @repDateFrom
and dt.Код = '47422' and kt.Код = '20501'
) t2 on (t1.[Номер договора 20501]  = t2.[Номер договора ДТ] 
			and t1.[Сумма по договору] = t2.[Сумма]
			and t1.[Дата выдачи 48801] = t2.[Дата выдачи]
		)
when matched then update
set t1.[Дата выдачи 20501] = t2.[Дата выдачи]
	,t1.[Сумма выдачи 20501] = t2.[Сумма];
*/

/*Основная выборка*/
drop table if exists #rep_out
select distinct
[Дата оформления договора]
,[Номер договора]
,[Сумма по договору]
,[Финансовый  продукт]
,[ФИО контрагента]
,[Остаток ОД]
,[Дата выдачи 48801]
,[rowNum] = ROW_NUMBER() over (order by [Дата оформления договора])

into #rep_out from #rep
--where [Номер договора]='25071603516400'
where [Дата выдачи 48801] is null
/*Дата договора минус отчетная более 5 дней отдельной строкой*/

--select * from #rep_out

declare @tekRow int = 1
declare @MaxRow int = (select count(*) from #rep_out)
declare @dogSum float = (select sum([Сумма по договору]) from #rep_out)
declare @message nvarchar(max) = concat(
						'Общий список договоров:'
						,char(10),char(13)
						,char(10),char(13)
						,'[Дата договора]....[Номер договора]....[Сумма по договору].....[Финансовый  продукт]......................................[ФИО контрагента]'
						,char(10),char(13)
						)

while @tekRow<=@MaxRow
	begin
		set @message =concat(
								@message
                                ,(select string_agg(
											concat(
												[Дата оформления договора] 
												,'............'
												,[Номер договора]
												,'.....'
												,str([Сумма по договору])
												,'...........................'
												,[Финансовый  продукт]
												,'..........'
												,[ФИО контрагента]	
												)
                                ,'-')
                                from #rep_out
                                where [rowNum]=@tekRow)
                                ,char(10),char(13)
                             )
set @tekRow=@tekRow+1
end

set @message = concat(
						@message
						,'-----------------------------------------------------------'
						,char(10),char(13)
						,'Итого сумма договоров: '
						,FORMAT(@dogSum,'N0', 'ru-RU' )
						,char(10),char(13)
						,char(10),char(13)
						)

drop table if exists #rep_out2
select 
[Дата оформления договора]
,[Номер договора]
,[Сумма по договору]
,[Финансовый  продукт]
,[ФИО контрагента]
,[Остаток ОД]
,[Дата выдачи 48801]
,[rowNum] = ROW_NUMBER() over (order by [Дата оформления договора])

into #rep_out2 from #rep_out
/*Дата договора минус отчетная более 5 дней отдельной строкой*/
where DATEDIFF(day,[Дата оформления договора],@repdate) > 5

--select DATEDIFF(day,[Дата оформления договора],@repdateTmp) from #rep_out


set @tekRow = 1
set @MaxRow = (select count(*) from #rep_out2)
set @message = concat(
						char(10),char(13)
						,@message
						,'Список договоров с датой оформления более 5 дней назад:'
						,char(10),char(13)
						,char(10),char(13)
						,'[Дата договора]....[Номер договора]....[Сумма по договору].....[Финансовый  продукт]......................................[ФИО контрагента]'
						,char(10),char(13)
						)

while @tekRow<=@MaxRow
	begin
		set @message =concat(
								@message
                                ,(select string_agg(
											concat(
												[Дата оформления договора] 
												,'............'
												,[Номер договора]
												,'.....'
												,str([Сумма по договору])
												,'...........................'
												,[Финансовый  продукт]
												,'..........'
												,[ФИО контрагента]	
												)
                                ,'-')
                                from #rep_out2
                                where [rowNum]=@tekRow)
                                ,char(10),char(13)
                             )
set @tekRow=@tekRow+1
end

--select * from #rep_out2

	

commit tran

declare @emailList nvarchar(max)
declare @subject  nvarchar(max) = concat('Не выданные Автокредиты на дату: ',FORMAT( @repdate, 'dd.MM.yyyy', 'ru-RU' ))
set @emailList = (select STRING_AGG(email,';') from dwh2.finAnalytics.emailList where emailUID in (1,21,32))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList--'d.detkin@smarthorizon.ru'--@emailList
			,@copy_recipients = ''
			,@body = @message
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

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch

END

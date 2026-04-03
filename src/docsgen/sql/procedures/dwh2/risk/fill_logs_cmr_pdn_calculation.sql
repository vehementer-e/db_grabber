
CREATE procedure [risk].[fill_logs_cmr_pdn_calculation]

as 

begin

DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	EXEC risk.set_debug_info @sp_name
		,'START';

	BEGIN TRY


drop table if exists #tmp_table;

select  a.number, dateadd(year,-2000, v.Период) as startdate, a.Дата, a.Данные, a.rn
, case when [Данные] like '%sum%' then cast(JSON_VALUE([Данные], '$.sum') as bigint) end as 'sum'
, case when [Данные] like '%Ветка%' then cast(JSON_VALUE([Данные], '$."Ветка"') as nvarchar(100)) end as 'Ветка'
, case when [Данные] like '%bki_income%' then cast(JSON_VALUE([Данные], '$.bki_income') as float) end as 'bki_income'
, case when [Данные] like '%application_income%' then cast(JSON_VALUE([Данные], '$.application_income') as float) end as 'application_income'
, case when [Данные] like '%income_amount%' then cast(JSON_VALUE([Данные], '$.income_amount') as float) end as 'income_amount'
, case when [Данные] like '%rosstat_income%' then cast(JSON_VALUE([Данные], '$.rosstat_income') as float) end as 'rosstat_income'
, substring((case when [Данные] like '%region%' then cast(JSON_VALUE([Данные], '$.region') as nvarchar(100)) end),13,100) as 'region'
, case when [Данные] like '%avg_income%' then cast(JSON_VALUE([Данные], '$.avg_income') as float) end as 'avg_income'
, case when [Данные] like '%credit_exp%' then cast(JSON_VALUE([Данные], '$.credit_exp') as float) end as 'credit_exp'
, case when [Данные] like '%bki_exp_amount%' then cast(JSON_VALUE([Данные], '$.bki_exp_amount') as float) end as 'bki_exp'
, case when [Данные] like '%exp_amount%' then cast(JSON_VALUE([Данные], '$.exp_amount') as float) end as 'exp_amount'
, case when [Данные] like '%pdn%' then cast(JSON_VALUE([Данные], '$.pdn') as float) end as 'pdn_logs'
, case when d.needbki = 0 then 'без БКИ' else '' end as [с БКИ/нет]
into #tmp_table
from (select Заявка.Код as number, ПДН.Код, Дата = dateadd(year,-2000, ПДН.Дата) ,ПДН.Данные, row_number () over (partition by Заявка.Код order by dateadd(year,-2000, ПДН.Дата) desc) rn
	from stg._1cCMR.Справочник_ЛогированиеПроцессаРасчетаПДН ПДН with(nolock)
	inner join stg._1cCMR.Справочник_Заявка Заявка on Заявка.Ссылка =ПДН.Заявка 
	where 1=1 and Данные > ''
	)a --логи расчета
left join (select  needbki,number, row_number () over (partition by number order by call_date desc) rn
	from [stg].[_loginom].[originationlog] with (nolock) where stage = 'Call 2') d on a.number = d.number and d.rn=1 --признак с БКИ/нет
left join (select d.[Код], ssd.Наименование, Период, row_number () over (partition by  d.[Код] order by Период) rn
	from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
	left join stg._1cCMR.Справочник_Договоры d on sd.Договор = d.Ссылка
	LEFT JOIN stg._1cCMR.Справочник_СтатусыДоговоров ssd ON ssd.Ссылка = sd.Статус
	where  ssd.Наименование = 'Действует') v on v.Код = a.number --флаг выдачи
left join  dwh2.sat.ДоговорЗайма_ПДН p with(nolock) on a.number = p.КодДоговораЗайма and year(p.Дата_по) = '2999' and p.Система = 'CMR'
where 1=1
and v.Наименование = 'Действует'
and v.rn=1
--and dateadd(year,-2000, v.Период) >= dateadd(month,-2,(select max(startdate)from dwh2.risk.logs_cmr_pdn_calculation)) --Отсекаем для инкремента
;

drop table if exists #tmp_table2;
select distinct a.number, b.[sum]
into #tmp_table2
from #tmp_table a
left join (select number, startdate, first_value([sum]) over (partition by number order by Дата desc) as 'sum' from #tmp_table where [sum] is not null) b on a.number=b.number
;

drop table if exists #tmp_table3;
select  a.number, a.[sum], c.[bki_income], row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table3
from #tmp_table2 a
left join (select number, startdate, first_value([bki_income]) over (partition by number order by Дата desc) as 'bki_income' from #tmp_table where [bki_income] is not null) c on a.number=c.number
;

drop table if exists #tmp_table4;
select  a.number, a.[sum], a.[bki_income], d.[application_income], row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table4
from #tmp_table3 a
left join (select number, startdate, first_value([application_income]) over (partition by number order by Дата desc) as 'application_income' from #tmp_table where [application_income] is not null) d on a.number=d.number
where a.rn=1
;

drop table if exists #tmp_table5;
select  a.number, a.[sum], a.[bki_income], a.[application_income], e.[income_amount]
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table5
from #tmp_table4 a
left join (select number, startdate, first_value([income_amount]) over (partition by number order by Дата desc) as 'income_amount' from #tmp_table where [income_amount] is not null) e on a.number=e.number
where a.rn=1
;

drop table if exists #tmp_table6;
select  a.number, a.[sum], a.[bki_income], a.[application_income], a.[income_amount], f.[rosstat_income]
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table6
from #tmp_table5 a
left join (select number, startdate, first_value([rosstat_income]) over (partition by number order by Дата desc) as 'rosstat_income' from #tmp_table where [rosstat_income] is not null) f on a.number=f.number
where a.rn=1
;

drop table if exists #tmp_table7;
select  a.number, a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], g.[avg_income]
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table7
from #tmp_table6 a
left join (select number, startdate, first_value([avg_income]) over (partition by number order by Дата desc) as 'avg_income' from #tmp_table where [avg_income] is not null) g on a.number=g.number
where a.rn=1
;

drop table if exists #tmp_table8;
select  a.number, a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[avg_income], h.[credit_exp]
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table8
from #tmp_table7 a
left join (select number, startdate, first_value([credit_exp]) over (partition by number order by Дата desc) as 'credit_exp' from #tmp_table where [credit_exp] is not null) h on a.number=h.number
where a.rn=1
;

drop table if exists #tmp_table9;
select  a.number, a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[avg_income], a.[credit_exp], i.bki_exp
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table9
from #tmp_table8 a
left join (select number, startdate, first_value([bki_exp]) over (partition by number order by Дата desc) as 'bki_exp' from #tmp_table where [bki_exp] is not null) i on a.number=i.number
where a.rn=1
;

drop table if exists #tmp_table10;
select  a.number, a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[avg_income], a.[credit_exp], a.bki_exp, j.exp_amount
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table10
from #tmp_table9 a
left join (select number, startdate, first_value([exp_amount]) over (partition by number order by Дата desc) as 'exp_amount' from #tmp_table where [exp_amount] is not null) j on a.number=j.number
where a.rn=1
;

drop table if exists #tmp_table11;
select  a.number, a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[avg_income], a.[credit_exp], a.bki_exp, a.exp_amount, k.pdn_logs 
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table11
from #tmp_table10 a
left join (select number, startdate, first_value([pdn_logs]) over (partition by number order by Дата desc) as 'pdn_logs' from #tmp_table where [pdn_logs] is not null) k on a.number=k.number
where a.rn=1
;

drop table if exists #tmp_table12;
select  a.number, l.[Ветка], a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[avg_income], a.[credit_exp], a.bki_exp, a.exp_amount, a.pdn_logs
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table12
from #tmp_table11 a
left join (select number, startdate, first_value([Ветка]) over (partition by number order by Дата desc) as 'Ветка' from #tmp_table where [Ветка] is not null) l on a.number=l.number
where a.rn=1
;

drop table if exists #tmp_table13;
select  a.number, m.startdate, m.[с БКИ/нет]
--, case when a.number in ('25072103528240','25071803520883','25071303508663','25070823497060','25070323483435','25063023475400') then 'без БКИ' else m.[с БКИ/нет] end as [с БКИ/нет]  --Сделки, по которым не пришел флаг
, a.[Ветка], a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[avg_income], a.[credit_exp], a.bki_exp, a.exp_amount, a.pdn_logs
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table13
from #tmp_table12 a
left join #tmp_table m on a.number=m.number
where a.rn=1
;

drop table if exists #tmp_table14;
select  a.number, a.startdate, a.[с БКИ/нет], a.[Ветка], a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[avg_income], a.[credit_exp], a.bki_exp, a.exp_amount, a.pdn_logs, n.[region]
, row_number () over (partition by a.number order by a.[sum]) rn
into #tmp_table14
from #tmp_table13 a
left join (select number, startdate, first_value([region]) over (partition by number order by Дата desc) as 'region' from #tmp_table where [region] is not null) n on a.number=n.number
where a.rn=1
;

drop table if exists #final;
select a.number, a.startdate, a.[с БКИ/нет], a.[Ветка], a.[sum], a.[bki_income], a.[application_income], a.[income_amount], a.[rosstat_income], a.[region], a.[avg_income], a.[credit_exp], a.bki_exp, a.exp_amount, a.pdn_logs, [InsertedDate] = SYSDATETIME()
into 
#final
from #tmp_table14 a
where a.rn=1
;

--Для полной перезаливки таблицы
--/*
drop table if exists dwh2.risk.logs_cmr_pdn_calculation;
select *
into dwh2.risk.logs_cmr_pdn_calculation
from #final;
--*/

--Инкремент
/*
merge into dwh2.risk.logs_cmr_pdn_calculation calc
using #final src
on (calc.number=src.number)
when not matched
then insert (number, startdate, [с БКИ/нет], [Ветка], [sum], [bki_income], [application_income], [income_amount], [rosstat_income], [region], [avg_income], [credit_exp], bki_exp, exp_amount, pdn_logs, [InsertedDate]
) values
(src.number, src.startdate, src.[с БКИ/нет], src.[Ветка], src.[sum], src.[bki_income], src.[application_income], src.[income_amount], src.[rosstat_income], src.[region], src.[avg_income], src.[credit_exp], src.bki_exp, src.exp_amount, src.pdn_logs, src.[InsertedDate]
)
;
*/

drop table if exists #tmp_table;
drop table if exists #tmp_table2;
drop table if exists #tmp_table3;
drop table if exists #tmp_table4;
drop table if exists #tmp_table5;
drop table if exists #tmp_table6;
drop table if exists #tmp_table7;
drop table if exists #tmp_table8;
drop table if exists #tmp_table9;
drop table if exists #tmp_table10;
drop table if exists #tmp_table11;
drop table if exists #tmp_table12;
drop table if exists #tmp_table13;
drop table if exists #tmp_table14;
drop table if exists #final;

		EXEC risk.set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'Никита Кириченко <n.kirichenko@smarthorizon.ru>;Александр Голицын <a.golicyn@carmoney.ru>'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END

--------------------------------------------------------------------------------


/*
select count(*)
from dwh2.risk.logs_cmr_pdn_calculation

select top 10 *
from dwh2.risk.logs_cmr_pdn_calculation
order by startdate desc

select top 100 number, startdate, [с БКИ/нет], [avg_income], [credit_exp], [bki_exp], [exp_amount]
,round(((credit_exp + case when [с БКИ/нет] = 'без БКИ' then exp_amount else bki_exp end)/avg_income), 3) as pdn_calc, pdn_logs
fromdwh2.risk.logs_cmr_pdn_calculation
where round(((credit_exp + case when [с БКИ/нет] = 'без БКИ' then exp_amount else bki_exp end)/avg_income), 3) <> pdn_logs
order by startdate desc


select * from  #tmp_table
where number = '25070103477054'
order by Дата desc


select d.[Код], ssd.Наименование, Период from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
	left join stg._1cCMR.Справочник_Договоры d on sd.Договор = d.Ссылка
	LEFT JOIN stg._1cCMR.Справочник_СтатусыДоговоров ssd ON ssd.Ссылка = sd.Статус
	where  1=1
	--and ssd.Наименование = 'Действует'
	and  d.[Код] = '24083102401009'
	order by Период desc


select top 100 b.*
from dwh2.sat.ДоговорЗайма_ПДН b with(nolock) 
where 1=1
--and b.Система = 'CMR'
and КодДоговораЗайма = '25070103477054'
--in ('25071323509932')
order by created_at desc

select *
from dwh2.risk.credits as cr with(nolock)
where 1=1
and external_id = '24083102401009'


select *
from dwh2.risk.pdn_calculation_2gen
where number ='25070103477054'


select top 100 a.*, p.PDN, p.Система
from dwh2.risk.logs_cmr_pdn_calculation a
left join  dwh2.sat.ДоговорЗайма_ПДН p with(nolock) on a.number = p.КодДоговораЗайма and year(p.Дата_по) = '2999' and p.Система = 'УМФО'
where a.pdn_logs <> p.PDN 
order by startdate desc

*/




























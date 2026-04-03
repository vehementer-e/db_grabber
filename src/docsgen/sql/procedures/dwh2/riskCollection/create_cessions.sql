CREATE procedure [riskCollection].[create_cessions] as 
begin
--exec [riskCollection].[create_cessions]
declare @msg nvarchar(255),
@subject nvarchar(255);
set @subject = 'Warning - ошибка выполнения процедуры'

BEGIN TRY
------------------------------------Цессии
drop table if exists #ces
select 
cast(dateadd(yy,-2000,c1.[Дата]) as date) as dt
,dogs.НомерДоговора
,c2.ДнейПросрочки
,case 
	when c2.ДнейПросрочки between 91 and 360 then '(5)_91_360'
	when c2.ДнейПросрочки between 361 and 1000 then '(6)_361_1000'
	when c2.ДнейПросрочки > 1000 then '(7)_1000+'
	end bucket
,cast(c2.ЗадолженностьОсновнойДолг as float) as ЗадолженностьОсновнойДолг
,cast(c2.ЗадолженностьПроценты as float) as ЗадолженностьПроценты
,cast(c2.ЗадолженностьКомиссии as float) as ЗадолженностьКомиссии
,cast(c2.ЗадолженностьШтрафы as float) as ЗадолженностьШтрафы
,cast(c2.ЗадолженностьПени as float) as ЗадолженностьПени
,cast(c2.ЗадолженностьПрочиеДоходы as float) as ЗадолженностьПрочиеДоходы
,cast(c2.ЗадолженностьШтрафыПениПрочиеДоходы as float) as ЗадолженностьШтрафыПениПрочиеДоходы
,cast(c2.ЗадолженностьОбщая as float) as ЗадолженностьОбщая
,cast(c2.ЗадолженностьОсновнойДолг as float) 
	+ cast(c2.ЗадолженностьПроценты as float) 
	+ cast(c2.ЗадолженностьПрочиеДоходыПоСуду as float)
	+ cast(c2.ЗадолженностьПениПоСуду as float) as TD
,cast(c2.ПроцентЗадолженность as float) as ПроцентЗадолженность
,cast(c2.Сумма as float) as Сумма
,cast(c2.СуммаШтрафыПениПрочиеДоходы as float) as СуммаШтрафыПениПрочиеДоходы
,cast(c2.ЗадолженностьШтрафыПоСуду as float) as ЗадолженностьШтрафыПоСуду
,cast(c2.ЗадолженностьПениПоСуду as float) as ЗадолженностьПениПоСуду
,cast(c2.ЗадолженностьПрочиеДоходыПоСуду as float) as ЗадолженностьПрочиеДоходыПоСуду
,cdm.[Тип продукта]
into #ces
from [Stg].[_1cUMFO].[Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного] c1
left join [Stg].[_1cUMFO].[Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного_Займы] c2 
	on c1.Ссылка = c2.Ссылка
left join [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] dogs
	on c2.Займ = dogs.Ссылка
left join [riskCollection].[collection_datamart] cdm 
	on cdm.external_id = dogs.НомерДоговора 
	and cast(cdm.d as date) = cast(dateadd(yy,-2000,c1.[Дата]) as date)
where dateadd(yy,-2000,c1.[Дата]) >= '20240101'
;
------------------------------------Резервы
drop table if exists #res_BU
select 
cast(dateadd(yy,-2000,t.[Дата]) as date) as dt
,t2.НомерДоговора as external_id
,t1.[РезервОстатокОДПо]
,t1.[РезервОстатокПроцентыПо]
,t1.[РезервОстатокПениПо]
,t1.[РезервОстатокОДПо] + t1.[РезервОстатокПроцентыПо] +  t1.[РезервОстатокПениПо] as SUM_RES
into #res_BU
from [Stg].[_1cUMFO].[Документ_СЗД_ФормированиеРезервовБУ] t
left join [Stg].[_1cUMFO].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] t1 
	on t.Ссылка = t1.Ссылка
left join [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] t2 
	on t1.Займ = t2.Ссылка
where cast(dateadd(yy,-2000,t.[Дата]) as date) >='20240101'
;
------------------------------------обратный выкуп
drop table if exists #backbuy
select 
d.Код
,pd.[ПометкаУдаления]
,dateadd(yy,-2000,pd.[Дата]) as dt
into #backbuy
from [Stg].[_1cCMR].[Документ_ПродажаДоговоров] pd
left join [Stg].[_1cCMR].[Документ_ПродажаДоговоров_Договоры] pdd 
	on pd.Ссылка = pdd.Ссылка 
left join [Stg].[_1cCMR].[Справочник_Договоры] d 
	on pdd.Договор = d.Ссылка
;
------------------------------------тотал
drop table if exists #total
select 
c.dt
,year(c.dt) as year
,month(c.dt) as month
,dateadd(DAY,-DAY(dateadd(MONTH,0,c.dt)),c.dt) as 'Конец месяца'
,rb.dt as dt_reserve
,c.НомерДоговора as external_id
,[Тип продукта]
,[Сумма]
,cast(TD as float) as TD
,cast(SUM_RES as float) as SUM_RES
,case 
	when [Тип продукта] in ('Инстоллмент','PDL','Installment','Big Installment') then 'Беззалог'
	when [Тип продукта] in ('ПТС','ПТС31') then 'ПТС'
	else 'wtf'
	end Product_type
,c.ДнейПросрочки
,c.bucket
,ROW_NUMBER() over (partition by c.НомерДоговора order by c.dt) as rn 
,case 
	when bb.ПометкаУдаления = 0x01 then 1 else 0
	end [Обратный выкуп]
,c.ЗадолженностьОсновнойДолг as [остаток ОД]
into #total
from #ces c 
left join #res_BU rb 
	on c.НомерДоговора = rb.[external_id] 
	and dateadd(DAY,-DAY(dateadd(MONTH,0,c.dt)),c.dt) = rb.dt
left join #backbuy bb 
	on bb.Код = c.НомерДоговора
	and cast(bb.dt as date) = cast(c.dt as date)
where c.НомерДоговора is not null
;
------------------------------------Ввод данных
if OBJECT_ID('riskcollection.cessions') is null
begin
	select 
	top(0) dt	
	,year	
	,month	
	,[Конец месяца]
	,dt_reserve	
	,external_id	
	,[Тип продукта]
	,Сумма	
	,TD	
	,SUM_RES	
	,Product_type	
	,ДнейПросрочки	
	,bucket
	,[Обратный выкуп]
	,[остаток ОД]
	into riskcollection.cessions
	from #total
end;

BEGIN TRANSACTION
	truncate table riskcollection.cessions;
	insert into riskcollection.cessions
	select 
	dt	
	,year	
	,month	
	,[Конец месяца]
	,dt_reserve	
	,external_id	
	,[Тип продукта]
	,Сумма	
	,TD	
	,SUM_RES	
	,Product_type	
	,ДнейПросрочки	
	,bucket
	,[Обратный выкуп]
	,[остаток ОД]
	from #total
	where rn = 1;
COMMIT TRANSACTION;

drop table if exists #ces;
drop table if exists #res_BU;
drop table if exists #backbuy;
drop table if exists #total;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'riskcollection@carmoney.ru'
			--,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
END CATCH

END;






CREATE PROCEDURE [finAnalytics].[reestrCBQCheck3]
    @repMonth date,
    @dsSelector int
AS
BEGIN

drop table if Exists #checkPool
create table #checkPool(
 colNum  varchar(10) not null,
 colName varchar(300) not null
)

INSERT INTO #checkPool values ('8','ИНН заемщика')
INSERT INTO #checkPool values ('12','Онлайн / оффлайн')
INSERT INTO #checkPool values ('15','Субъект МСП на последнюю отчетную дату')
INSERT INTO #checkPool values ('16','Субъект МСП на дату заключения договора')
INSERT INTO #checkPool values ('17','Территория выдачи')
INSERT INTO #checkPool values ('45','Заем обеспечен залогом автомототранспортного средства')
INSERT INTO #checkPool values ('46','Заем обеспечен иным залогом')
INSERT INTO #checkPool values ('47','Вид иного залога')
INSERT INTO #checkPool values ('59','Заемщик признан банкротом или находится в процессе ликвидации')
INSERT INTO #checkPool values ('64','Признак реструктуризации / рефинансирования')
INSERT INTO #checkPool values ('78','ПДН на последний месяц квартала')
INSERT INTO #checkPool values ('79','ПДН на момент выдачи кредита (займа), %')
INSERT INTO #checkPool values ('102','Длительность просроченной задолженности')
INSERT INTO #checkPool values ('103','Длительность просроченной задолженности')
INSERT INTO #checkPool values ('104','Длительность просроченной задолженности')

INSERT INTO #checkPool values ('30','Объем денежных средств, предоставленных по договору займа за квартал, руб.')
INSERT INTO #checkPool values ('93','Задолженность (включая просроченную) по основному долгу, руб.')
INSERT INTO #checkPool values ('94','Задолженность (включая просроченную) по основному долгу, руб.')
INSERT INTO #checkPool values ('95','Задолженность (включая просроченную) по основному долгу, руб.')
INSERT INTO #checkPool values ('96','Задолженность (включая просроченную) по процентам и иным платежам, руб.')
INSERT INTO #checkPool values ('97','Задолженность (включая просроченную) по процентам и иным платежам, руб.')
INSERT INTO #checkPool values ('98','Задолженность (включая просроченную) по процентам и иным платежам, руб.')
INSERT INTO #checkPool values ('112','Сформированный РВПЗ (суммарно по ОД, процентам и иным платежам)')
INSERT INTO #checkPool values ('113','Сформированный РВПЗ (суммарно по ОД, процентам и иным платежам)')
INSERT INTO #checkPool values ('114','Сформированный РВПЗ (суммарно по ОД, процентам и иным платежам)')
INSERT INTO #checkPool values ('115','Размер резерва под обесценение на дату, руб.')

INSERT INTO #checkPool values ('106','Объем средств, направленных на погашение задолженности по основному долгу')
INSERT INTO #checkPool values ('107','Объем средств, направленных на погашение задолженности по основному долгу')
INSERT INTO #checkPool values ('108','Объем средств, направленных на погашение задолженности по основному долгу')

INSERT INTO #checkPool values ('109','Объем средств, направленных на погашение задолженности по процентам и иным платежам')
INSERT INTO #checkPool values ('110','Объем средств, направленных на погашение задолженности по процентам и иным платежам')
INSERT INTO #checkPool values ('111','Объем средств, направленных на погашение задолженности по процентам и иным платежам')

INSERT INTO #checkPool values ('81','Включение займа в категории А1 - А6')


-----------Отчет сводный
if @dsSelector = 1

begin
select 
 [Номер графы проверки] = cast(colNum as int)
 ,[Наименование графы проверки] = colName
 ,[Кол-во ошибок] = isnull(b.errorCount,0)
from #checkPool a
left join (
select 
[Номер проверяемого столбца]
,errorCount = count(*)
from dwh2.[finAnalytics].[reest_CB_Q_check3]
where [Месяц начала квартала] = dateadd(month,-2,@repMonth)
and [Месяц конца квартала] = @repMonth
group by [Номер проверяемого столбца]
) b on a.colNum = b.[Номер проверяемого столбца]
and a.colNum != 81

order by cast(colNum as int)
end

-----------Отчет детализированный
if @dsSelector = 2

select 
 [Месяц начала квартала]
 , [Месяц конца квартала]
 , [ФИО / Наименование заемщика]
 , [Паспортные данные заемщика]
 , [Дата рождения заемщика]
 , [Номер договора займа]
 , [Дата закрыт]
 , [Номер проверяемого столбца]
 , [Название проверяемого столбца]
 , [Значение проверяемого столбца]
 , [Значение контрольное]
 , [Результат проверки]
 , [Примечание]
 , [Примечание2]
from dwh2.[finAnalytics].[reest_CB_Q_check3]
where [Месяц начала квартала] = dateadd(month,-2,@repMonth)
	and [Месяц конца квартала] = @repMonth
	and [Номер проверяемого столбца] != 81
END







CREATE PROCEDURE [finAnalytics].[repDogCount]
	@repmonthFrom date
	,@repmonthTo date
	,@repNum int

AS
BEGIN

/*Создание структуры выходной таблицы*/
DROP TABLE IF EXISTS #scelet
CREATE TABLE #scelet (
	rowNum int not null,
	rowName nvarchar(100) not null
)

INSERT INTO #scelet VALUES (1,'ИТОГО (шт), в т.ч.')
INSERT INTO #scelet VALUES (2,'без просрочки')
INSERT INTO #scelet VALUES (3,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (4,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (5,'в т.ч. просрочка 360+ дней')
INSERT INTO #scelet VALUES (6,'ПТС (шт), в т.ч.')
INSERT INTO #scelet VALUES (7,'без просрочки')
INSERT INTO #scelet VALUES (8,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (9,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (10,'в т.ч. просрочка 360+ дней')

INSERT INTO #scelet VALUES (11,'Автокредит (шт), в т.ч.')
INSERT INTO #scelet VALUES (12,'без просрочки')
INSERT INTO #scelet VALUES (13,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (14,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (15,'в т.ч. просрочка 360+ дней')

INSERT INTO #scelet VALUES (16,'Инстолмент (шт), в т.ч.')
INSERT INTO #scelet VALUES (17,'без просрочки')
INSERT INTO #scelet VALUES (18,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (19,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (20,'в т.ч. просрочка 360+ дней')

INSERT INTO #scelet VALUES (21,'Бизнес займы (шт), в т.ч.')
INSERT INTO #scelet VALUES (22,'без просрочки')
INSERT INTO #scelet VALUES (23,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (24,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (25,'в т.ч. просрочка 360+ дней')

INSERT INTO #scelet VALUES (26,'PDL (шт), в т.ч.')
INSERT INTO #scelet VALUES (27,'без просрочки')
INSERT INTO #scelet VALUES (28,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (29,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (30,'в т.ч. просрочка 360+ дней')

INSERT INTO #scelet VALUES (31,'Big Installment (шт), в т.ч.')
INSERT INTO #scelet VALUES (32,'без просрочки')
INSERT INTO #scelet VALUES (33,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (34,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (35,'в т.ч. просрочка 360+ дней')

INSERT INTO #scelet VALUES (36,'Займы (шт), в т.ч.')
INSERT INTO #scelet VALUES (37,'без просрочки')
INSERT INTO #scelet VALUES (38,'просрочка 1-90 дней')
INSERT INTO #scelet VALUES (39,'просрочка 90+ дней')
INSERT INTO #scelet VALUES (40,'в т.ч. просрочка 360+ дней')
INSERT INTO #scelet VALUES (41,'Проверка разбивки по продуктам')

/*Вариант запуска для расчета кол-ва договоров*/
if @repNum=1
begin

/*Собираем данные для расчета*/
DROP TABLE IF EXISTS #PBR
select
a.REPMONTH
,a.Client
,a.dogNum
,a.prosDaysTotal
,dogBucket = case when a.prosDaysTotal = 0 OR a.prosDaysTotal is null then 'без просрочки'
				  when a.prosDaysTotal between 1 and 90 then 'просрочка 1-90 дней'
				  when a.prosDaysTotal > 90 then 'просрочка 90+ дней'
			 end
,dogBucketDop = case when a.prosDaysTotal > 360 then 'в т.ч. просрочка 360+ дней' end
,a.nomenkGroup
,nomenkGr = /*case when upper(a.nomenkGroup) like upper('%ПТС31')
                      or upper(a.nomenkGroup) like upper('%Основной%')
					  or upper(a.nomenkGroup) like upper('%Рефинансирование%')
					then 'ПТС'
					
					when upper(a.nomenkGroup) like upper('%installment%')
					then 'Инстолмент'

					when upper(a.nomenkGroup) like upper('%Бизнес-займ%')
					then 'Бизнес займы'

					when upper(a.nomenkGroup) like upper('%pdl%')
					then 'PDL'

					when upper(a.nomenkGroup) like upper('%Автокредит%')
					then 'Автокредит'

					when a.nomenkGroup is null and upper(a.isZaemshik)='ЮЛ'
					then 'Займы'
				end*/
				case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'ПТС' then 'ПТС'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Installment' then 'Инстолмент'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Бизнес-займ' then 'Бизнес займы'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'PDL' then 'PDL'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Автокредит' then 'Автокредит'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Big Installment' then 'Big Installment'
					 when a.nomenkGroup is null and upper(a.isZaemshik)='ЮЛ' then 'Займы'
				end


,a.dogStatus
,a.saleDate
,a.zadolgOD
,a.zadolgPrc
,a.penyaSum
,a.gosposhlSum
--в расчет включены все договора со статусом "Действует"  с  датой выдачи не позже отчетной
,isMethod1 = case when upper(a.dogStatus) = upper('Действует') and a.saleDate <= EOMONTH(a.repmonth) then 1 else 0 end
--в расчет включены все договора, у которых есть остатки задолженности по ОД, %% или пеням 
,isMethod2 = case when (isnull(a.zadolgOD,0) + isnull(a.zadolgPrc,0) + isnull(a.penyaSum,0)) !=0 then 1 else 0 end
--в расчет включены все договора, у которых есть остатки задолженности по ОД, %%,  пеням или ГП
,isMethod3 = case when (isnull(a.zadolgOD,0) + isnull(a.zadolgPrc,0) + isnull(a.penyaSum,0) + isnull(a.gosposhlSum,0)) !=0 then 1 else 0 end
INTO #PBR
from dwh2.finAnalytics.PBR_MONTHLY a
where a.repmonth between @repmonthFrom and @repmonthTo
--and (a.zadolgOD + a.zadolgPrc + a.penyaSum + a.gosposhlSum) != 0

--select top 100 * from #pbr

/*Создаем выходную таблицу*/
DROP TABLE IF EXISTS #rep
CREATE TABLE #rep(
repmonth date not null,
rowNum int not null,
rowName varchar(100) null,
nomenkGroup varchar(100) null,
isGR int not null,
dogAmountMethod1 int null,
dogAmountMethod2 int null,
dogAmountMethod3 int null
)

/*Заполняем выходную таблицу пустыми значениями*/
insert INTO #rep 
select 
b.repmonth
,a.rowNum
,a.rowName
,nomenkGroup = null
,isGR = case when a.rowNum in (1,6,11,16,21,26,31,36,41) then 1 else 0 end
,dogAmountMethod1 = 0
,dogAmountMethod2 = 0
,dogAmountMethod3 = 0
from #scelet a
left join (select distinct repmonth from #PBR) b on 1=1

/*Подсчет кол-ва договоров*/

--p1
merge INTO #rep t1
using(
Select
repmonth 
,rowNum = 1
, rowName = 'ИТОГО (шт), в т.ч.'
, nomenkGroup = 'ИТОГО'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
group by repmonth 
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--select * from #rep

--p2
merge INTO #rep t1 using(

Select
repmonth 
,rowNum = 2
, rowName = 'без просрочки'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки'
group by repmonth 
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p3
merge INTO #rep t1 using(

Select
repmonth 
,rowNum = 3
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
group by repmonth 
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p4
merge INTO #rep t1 using(

Select
repmonth 
,rowNum = 4
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p5
merge INTO #rep t1 using(

Select
repmonth 
,rowNum = 5
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

---------- ПТС
--p6
merge INTO #rep t1 using(

Select
repmonth 
,rowNum = 6
, rowName = 'ПТС (шт), в т.ч.'
, nomenkGroup = 'ПТС'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p7
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 7
, rowName = 'без просрочки'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки' and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p8
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 8
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p9
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 9
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
					and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p10
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 10
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;


----Автокредит
--p11
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 11
, rowName = 'Автокредит (шт), в т.ч.'
, nomenkGroup = 'Автокредит'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p12
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 12
, rowName = 'без просрочки'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p13
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 13
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p14
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 14
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p15
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 15
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;


----Инстолмент
--p16
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 16
, rowName = 'Инстолмент (шт), в т.ч.'
, nomenkGroup = 'Инстолмент'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p17
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 17
, rowName = 'без просрочки'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p18
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 18
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p19
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 19
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p20
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 20
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

-----Бизнес займы
--p21
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 21
, rowName = 'Бизнес займы (шт), в т.ч.'
, nomenkGroup = 'Бизнес займы'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p22
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 22
, rowName = 'без просрочки'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;


--p23
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 23
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p24
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 24
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p25
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 25
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;


----PDL
--p26
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 26
, rowName = 'PDL (шт), в т.ч.'
, nomenkGroup = 'PDL'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p27
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 27
, rowName = 'без просрочки'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p28
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 28
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p29
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 29
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p30
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 30
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

----Big Installment
--p31
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 31
, rowName = 'Big Installment (шт), в т.ч.'
, nomenkGroup = 'Big Installment'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p32
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 32
, rowName = 'без просрочки'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p33
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 33
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p34
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 34
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p35
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 35
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

-----Займы
--p36
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 36
, rowName = 'Займы (шт), в т.ч.'
, nomenkGroup = 'Займы'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p37
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 37
, rowName = 'без просрочки'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='без просрочки'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p38
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 38
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p39
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 39
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p40
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 40
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #pbr
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;


--p41
merge INTO #rep t1 using(

Select
repmonth
,rowNum = 41
, rowName = 'Проверка разбивки по продуктам'
, nomenkGroup = ''
, isGR = 1
,dogAmountMethod1 = isnull(SUM(case when rowNum != 1 then dogAmountMethod1*-1 else dogAmountMethod1 end),0)
,dogAmountMethod2 = isnull(SUM(case when rowNum != 1 then dogAmountMethod2*-1 else dogAmountMethod2 end),0)
,dogAmountMethod3 = isnull(SUM(case when rowNum != 1 then dogAmountMethod3*-1 else dogAmountMethod3 end),0)
from #rep
where rowNum in (1,6,11,16,21,26,31,36)
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

select * from #rep --where repmonth = @repmonth
end


if @repNum=2
begin

/*Собираем данные для расчета*/
DROP TABLE IF EXISTS #PBRCl
select
l1.repmonth
,Client = l1.Client
,nomenkGr = l1.nomenkGr
,dogCount = COUNT(*)
,isMethod1 = case when SUM(l1.isMethod1) >0 then 1 else 0 end
,isMethod2 = case when SUM(l1.isMethod2) >0 then 1 else 0 end
,isMethod3 = case when SUM(l1.isMethod3) >0 then 1 else 0 end
,maxPros = MAX(isnull(l1.prosDaysTotal,0))
,dogBucket = case when MAX(isnull(l1.prosDaysTotal,0)) = 0 then 'без просрочки'
				  when MAX(isnull(l1.prosDaysTotal,0)) between 1 and 90 then 'просрочка 1-90 дней'
				  when MAX(isnull(l1.prosDaysTotal,0)) > 90 then 'просрочка 90+ дней'
			 end
,dogBucketDop = case when MAX(isnull(l1.prosDaysTotal,0)) > 360 then 'в т.ч. просрочка 360+ дней' end

INTO #PBRCl
from(

select
a.REPMONTH
,Client = a.ClientID--a.Client
,a.dogNum
,a.prosDaysTotal
,nomenkGr = /*case when upper(a.nomenkGroup) like upper('%ПТС31')
                      or upper(a.nomenkGroup) like upper('%Основной%')
					  or upper(a.nomenkGroup) like upper('%Рефинансирование%')
					then 'ПТС'
					
					when upper(a.nomenkGroup) like upper('%installment%')
					then 'Инстолмент'

					when upper(a.nomenkGroup) like upper('%Бизнес-займ%')
					then 'Бизнес займы'

					when upper(a.nomenkGroup) like upper('%pdl%')
					then 'PDL'

					when upper(a.nomenkGroup) like upper('%Автокредит%')
					then 'Автокредит'

					when a.nomenkGroup is null and upper(a.isZaemshik)='ЮЛ'
					then 'Займы'
				end*/
				case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'ПТС' then 'ПТС'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Installment' then 'Инстолмент'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Бизнес-займ' then 'Бизнес займы'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'PDL' then 'PDL'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Автокредит' then 'Автокредит'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Big Installment' then 'Big Installment'
					 when a.nomenkGroup is null and upper(a.isZaemshik)='ЮЛ' then 'Займы'
				end

,a.dogStatus
,a.saleDate
,a.zadolgOD
,a.zadolgPrc
,a.penyaSum
,a.gosposhlSum
--в расчет включены все договора со статусом "Действует"  с  датой выдачи не позже отчетной
,isMethod1 = case when upper(a.dogStatus) = upper('Действует') and a.saleDate <= EOMONTH(a.repmonth) then 1 else 0 end
--в расчет включены все договора, у которых есть остатки задолженности по ОД, %% или пеням 
,isMethod2 = case when (isnull(a.zadolgOD,0) + isnull(a.zadolgPrc,0) + isnull(a.penyaSum,0)) !=0 then 1 else 0 end
--в расчет включены все договора, у которых есть остатки задолженности по ОД, %%,  пеням или ГП
,isMethod3 = case when (isnull(a.zadolgOD,0) + isnull(a.zadolgPrc,0) + isnull(a.penyaSum,0) + isnull(a.gosposhlSum,0)) !=0 then 1 else 0 end

from dwh2.finAnalytics.PBR_MONTHLY a
where a.repmonth between @repmonthFrom and @repmonthTo
--and (a.zadolgOD + a.zadolgPrc + a.penyaSum + a.gosposhlSum) != 0

) l1

group by 
l1.Client
,l1.nomenkGr
,l1.REPMONTH
--select * from #PBRCl where client='БП0026827'

/*Создаем выходную таблицу*/
DROP TABLE IF EXISTS #repCl
CREATE TABLE #repCl(
repmonth date not null,
rowNum int not null,
rowName varchar(100) null,
nomenkGroup varchar(100) null,
isGR int not null,
dogAmountMethod1 int null,
dogAmountMethod2 int null,
dogAmountMethod3 int null
)

/*Заполняем выходную таблицу пустыми значениями*/
insert INTO #repCl 
select 
b.repmonth
,a.rowNum
,a.rowName
,nomenkGroup = null
,isGR = case when a.rowNum in (1,6,11,16,21,26,31,36,41) then 1 else 0 end
,dogAmountMethod1 = 0
,dogAmountMethod2 = 0
,dogAmountMethod3 = 0
from #scelet a
left join (select distinct repmonth from #PBRCl) b on 1=1

/*Подсчет кол-ва клиентов*/

--p1
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 1
, rowName = 'ИТОГО (клиентов), в т.ч.'
, nomenkGroup = 'ИТОГО'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p2
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 2
, rowName = 'без просрочки'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p3
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 3
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p4
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 4
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p5
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 5
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'ИТОГО'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

----ПТС
--p6
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 6
, rowName = 'ПТС (Клиентов), в т.ч.'
, nomenkGroup = 'ПТС'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p7
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 7
, rowName = 'без просрочки'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
					and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p8
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 8
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p9
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 9
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
					and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p10
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 10
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'ПТС'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='ПТС'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

----Автокредит
--p11
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 11
, rowName = 'Автокредит (Клиентов), в т.ч.'
, nomenkGroup = 'Автокредит'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p12
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 12
, rowName = 'без просрочки'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p13
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 13
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p14
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 14
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p15
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 15
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Автокредит'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Автокредит'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

----Инстолмент
--p16
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 16
, rowName = 'Инстолмент (Клиентов), в т.ч.'
, nomenkGroup = 'Инстолмент'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p17
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 17
, rowName = 'без просрочки'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p18
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 18
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p19
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 19
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p20
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 20
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Инстолмент'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Инстолмент'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;


-----Бизнес займы
--p21
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 21
, rowName = 'Бизнес займы (Клиентов), в т.ч.'
, nomenkGroup = 'Бизнес займы'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p22
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 22
, rowName = 'без просрочки'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p23
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 23
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p24
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 24
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p25
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 25
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Бизнес займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Бизнес займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

----PDL
--p26
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 26
, rowName = 'PDL (Клиентов), в т.ч.'
, nomenkGroup = 'PDL'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p27
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 27
, rowName = 'без просрочки'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p28
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 28
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p29
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 29
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p30
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 30
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'PDL'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='PDL'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

----Big Installment
--p31
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 31
, rowName = 'Big Installment (Клиентов), в т.ч.'
, nomenkGroup = 'Big Installment'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p32
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 32
, rowName = 'без просрочки'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p33
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 33
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p34
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 34
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p35
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 35
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Big Installment'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Big Installment'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;


-----Займы
--p36
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 36
, rowName = 'Займы (Клиентов), в т.ч.'
, nomenkGroup = 'Займы'
, isGR = 1
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p37
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 37
, rowName = 'без просрочки'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='без просрочки'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p38
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 38
, rowName = 'просрочка 1-90 дней'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 1-90 дней'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p39
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 39
, rowName = 'просрочка 90+ дней'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucket='просрочка 90+ дней'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p40
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 40
, rowName = 'в т.ч. просрочка 360+ дней'
, nomenkGroup = 'Займы'
, isGR = 0
,dogAmountMethod1 = isnull(SUM(isMethod1),0)
,dogAmountMethod2 = isnull(SUM(isMethod2),0)
,dogAmountMethod3 = isnull(SUM(isMethod3),0)
from #PBRCl
where dogBucketDop='в т.ч. просрочка 360+ дней'
					and nomenkGr='Займы'
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

--p41
merge INTO #repCl t1 using(

Select
repmonth
,rowNum = 41
, rowName = 'Проверка разбивки по продуктам'
, nomenkGroup = ''
, isGR = 1
,dogAmountMethod1 = isnull(SUM(case when rowNum != 1 then dogAmountMethod1*-1 else dogAmountMethod1 end),0)
,dogAmountMethod2 = isnull(SUM(case when rowNum != 1 then dogAmountMethod2*-1 else dogAmountMethod2 end),0)
,dogAmountMethod3 = isnull(SUM(case when rowNum != 1 then dogAmountMethod3*-1 else dogAmountMethod3 end),0)
from #repCl
where rowNum in (1,6,11,16,21,26,31,36)
group by repmonth
) t2 on (t1.rownum=t2.rownum and t1.repmonth=t2.repmonth)
when matched then update
	set t1.dogAmountMethod1 = t2.dogAmountMethod1
	,t1.dogAmountMethod2 = t2.dogAmountMethod2
	,t1.dogAmountMethod3 = t2.dogAmountMethod3;

select * from #repCl --where repmonth = @repmonth
end

if @repNum = 3
begin
DROP TABLE IF EXISTS #PBRCheck
select
a.REPMONTH
,a.Client
,a.dogNum
,a.prosDaysTotal
,dogBucket = case when a.prosDaysTotal = 0 OR a.prosDaysTotal is null then 'без просрочки'
				  when a.prosDaysTotal between 1 and 90 then 'просрочка 1-90 дней'
				  when a.prosDaysTotal > 90 then 'просрочка 90+ дней'
			 end
,dogBucketDop = case when a.prosDaysTotal > 360 then 'в т.ч. просрочка 360+ дней' end
,a.nomenkGroup
,nomenkGr = /*case when upper(a.nomenkGroup) like upper('%ПТС31')
                      or upper(a.nomenkGroup) like upper('%Основной%')
					  or upper(a.nomenkGroup) like upper('%Рефинансирование%')
					then 'ПТС'
					
					when upper(a.nomenkGroup) like upper('%installment%')
					then 'Инстолмент'

					when upper(a.nomenkGroup) like upper('%Бизнес-займ%')
					then 'Бизнес займы'

					when upper(a.nomenkGroup) like upper('%pdl%')
					then 'PDL'

					when upper(a.nomenkGroup) like upper('%Автокредит%')
					then 'Автокредит'

					when a.nomenkGroup is null and upper(a.isZaemshik)='ЮЛ'
					then 'Займы'
				end*/
				case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'ПТС' then 'ПТС'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Installment' then 'Инстолмент'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Бизнес-займ' then 'Бизнес займы'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'PDL' then 'PDL'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Автокредит' then 'Автокредит'
					 when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) = 'Big Installment' then 'Big Installment'
					 when a.nomenkGroup is null and upper(a.isZaemshik)='ЮЛ' then 'Займы'
				end

,a.dogStatus
,a.saleDate
,a.zadolgOD
,a.zadolgPrc
,a.penyaSum
,a.gosposhlSum
--в расчет включены все договора со статусом "Действует"  с  датой выдачи не позже отчетной
,isMethod1 = case when upper(a.dogStatus) = upper('Действует') and a.saleDate <= EOMONTH(a.repmonth) then 1 else 0 end
--в расчет включены все договора, у которых есть остатки задолженности по ОД, %% или пеням 
,isMethod2 = case when (isnull(a.zadolgOD,0) + isnull(a.zadolgPrc,0) + isnull(a.penyaSum,0)) !=0 then 1 else 0 end
--в расчет включены все договора, у которых есть остатки задолженности по ОД, %%,  пеням или ГП
,isMethod3 = case when (isnull(a.zadolgOD,0) + isnull(a.zadolgPrc,0) + isnull(a.penyaSum,0) + isnull(a.gosposhlSum,0)) !=0 then 1 else 0 end
INTO #PBRCheck
from dwh2.finAnalytics.PBR_MONTHLY a
where a.repmonth between @repmonthFrom and @repmonthTo

select * from #PBRCheck
where nomenkGr is null and dogStatus = 'Действует'

end

END

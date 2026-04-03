

CREATE procedure [finAnalytics].[calcRep840FirstLevel_4sub_v1]
	@dataLevel int,
    @prosCategory int,
    @repmonth date,
    @repdate date,
    @rownum int,
    @rowName varchar(30),
    @rowPokazatel varchar(500)
AS
BEGIN

declare @dataLevelText varchar(max)
/*
@dataLevel:
1 - Сумма по полю "Основной долг"(12)
2 - Сумма по полю "Основной долг"(23)
3 - Сумма по полю "Проценты начисленные"(13) и полю "Пени"(14)
4 - Сумма по полю "Проценты начисленные"(24) и полю "Пени"(25)
*/
if @dataLevel=1 set @dataLevelText = 'Сумма по полю "Основной долг"(12)'
if @dataLevel=2 set @dataLevelText = 'Сумма по полю "Основной долг"(23)'
if @dataLevel=3 set @dataLevelText = 'Сумма по полю "Проценты начисленные"(13) и полю "Пени"(14)'
if @dataLevel=4 set @dataLevelText = 'Сумма по полю "Проценты начисленные"(24) и полю "Пени"(25)'

declare @prosCategoryText varchar(max)
/*
@prosCategory:
1 -"Итого дней просрочки"(18) равно "0"
2 - "Итого дней просрочки"(18) больше или равно 1 и меньше или равно 7
3 - "Итого дней просрочки"(18) больше или равно 8 и меньше или равно 30
4 - "Итого дней просрочки"(18) больше или равно 31 и меньше или равно 60
5 - "Итого дней просрочки"(18) больше или равно 61 и меньше или равно 90
6 - "Итого дней просрочки"(18) больше или равно 91 и меньше или равно 120
7 - "Итого дней просрочки"(18) больше или равно 121 и меньше или равно 180
8 - "Итого дней просрочки"(18) больше или равно 181 и меньше или равно 270
9 - "Итого дней просрочки"(18) больше или равно 271 и меньше или равно 360
10 - "Итого дней просрочки"(18) больше или равно 361
*/
if @prosCategory = 1 set @prosCategoryText = 'Итого дней просрочки"(18) равно "0"'
if @prosCategory = 2 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 1 и меньше или равно 7'
if @prosCategory = 3 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 8 и меньше или равно 30'
if @prosCategory = 4 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 31 и меньше или равно 60'
if @prosCategory = 5 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 61 и меньше или равно 90'
if @prosCategory = 6 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 91 и меньше или равно 120'
if @prosCategory = 7 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 121 и меньше или равно 180'
if @prosCategory = 8 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 181 и меньше или равно 270'
if @prosCategory = 9 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 271 и меньше или равно 360'
if @prosCategory = 10 set @prosCategoryText = 'Итого дней просрочки"(18) больше или равно 361'

insert into finAnalytics.rep840_firstLevel_4
(REPMONTH, REPDATE, rownum, col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12, col13, col14, col15, col16, col17, col18, comment)


select
@repmonth
,@repdate
,[rownum] = l2.rownum
,[col1] = l2.col1
,[col2] = l2.col2
,[col3] = sum(l2.col3)
,[col4] = sum(l2.col4)
,[col5] = sum(l2.col5)
,[col6] = sum(l2.col6)
,[col7] = sum(l2.col7)
,[col8] = sum(l2.col8)
,[col9] = sum(l2.col9)
,[col10] = sum(l2.col10)
,[col11] = sum(l2.col11)
,[col12] = sum(l2.col12)
,[col13] = sum(l2.col13)
,[col14] = sum(l2.col14)
,[col15] = sum(l2.col15)
,[col16] = sum(l2.col16)
,[col17] = sum(l2.col17)
,[col18] = CASE when @dataLevel in (1,3) then 'сумма'
                when @dataLevel in (2,4) then 'РВПЗ'
                else '-'
           end
,[comment] = concat('Берем из отчета "Резервы НУ" строки, где ',@prosCategoryText,' ',@dataLevelText)
from(
select
[rownum] =@rownum
,[col1]=@rowName
,[col2] = @rowPokazatel
,[col3] = case when l1.[Код столбца]=3 then l1.Значение else 0 end
,[col4] = case when l1.[Код столбца]=4 then l1.Значение else 0 end
,[col5] = case when l1.[Код столбца]=5 then l1.Значение else 0 end
,[col6] = case when l1.[Код столбца]=6 then l1.Значение else 0 end
,[col7] = case when l1.[Код столбца]=7 then l1.Значение else 0 end
,[col8] = case when l1.[Код столбца]=8 then l1.Значение else 0 end
,[col9] = case when l1.[Код столбца]=9 then l1.Значение else 0 end
,[col10] = case when l1.[Код столбца]=10 then l1.Значение else 0 end
,[col11] = case when l1.[Код столбца]=11 then l1.Значение else 0 end
,[col12] = case when l1.[Код столбца]=12 then l1.Значение else 0 end
,[col13] = case when l1.[Код столбца]=13 then l1.Значение else 0 end
,[col14] = case when l1.[Код столбца]=14 then l1.Значение else 0 end
,[col15] = case when l1.[Код столбца]=15 then l1.Значение else 0 end
,[col16] = case when l1.[Код столбца]=16 then l1.Значение else 0 end
,[col17] = case when l1.[Код столбца]=17 then l1.Значение else 0 end

from(

select
[Код столбца] = '3'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
where upper(a.clientType)=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))=upper('PDL')
and upper(a.zaymGroup)=upper('Займ физическому лицу необеспеченный')
and a.PROScategoy=@prosCategory

union all

--4.1.1.4
select
[Код столбца] = '4'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
where upper(a.clientType)=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
and upper(a.zaymGroup)=upper('Займ физическому лицу обеспеченный')
and a.PROScategoy=@prosCategory

union all

--4.1.1.5
select
[Код столбца] = '5'
,[Значение] = 0

union all

--4.1.1.6
select
[Код столбца] = '6'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
where upper(a.clientType)=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
and upper(a.zaymGroup)=upper('Займ физическому лицу необеспеченный')
and a.PROScategoy=@prosCategory

union all

--4.1.1.7
select
[Код столбца] = '7'
,[Значение] = 0

union all

--4.1.1.8
select
[Код столбца] = '8'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
left join finAnalytics.PBR_MONTHLY kp on kp.repmonth=@repmonth /*and kp.repdate=@repdate*/ and a.dogNum=kp.dogNum
where upper(a.clientType)!=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
and upper(a.zaymGroup)  in (
                        upper('Займ индивидуальному предпринимателю обеспеченный') 
                        ,
                        upper('Займ субъекту малого и среднего предпринимательства обеспеченный')
                        )
and a.PROScategoy=@prosCategory
and upper(kp.isMSPbyRepDate) = upper('Да')

union all

--4.1.1.9
select
[Код столбца] = '9'
,[Значение] = 0

union all

--4.1.1.10
select
[Код столбца] = '10'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
left join finAnalytics.PBR_MONTHLY kp on kp.repmonth=@repmonth /*and kp.repdate=@repdate*/ and a.dogNum=kp.dogNum
where upper(a.clientType)!=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
and upper(a.zaymGroup)=upper('Займ субъекту малого и среднего предпринимательства необеспеченный')
and a.PROScategoy=@prosCategory
and upper(kp.isMSPbyRepDate) = upper('Да')

union all

--4.1.1.11
select
[Код столбца] = '11'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
left join finAnalytics.PBR_MONTHLY kp on kp.repmonth=@repmonth /*and kp.repdate=@repdate*/ and a.dogNum=kp.dogNum
where upper(a.clientType)!=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
--and upper(a.zaymGroup)=upper('Займ субъекту малого и среднего предпринимательства обеспеченный') -- ошибка в ТЗ
and upper(a.zaymGroup) in (
                            upper('Займ индивидуальному предпринимателю обеспеченный'),
                            upper('Займ юридическому лицу обеспеченный')
                           ) 
and a.PROScategoy=@prosCategory
and upper(kp.isMSPbyRepDate) != upper('Да')

union all

--4.1.1.12
select
[Код столбца] = '12'
,[Значение] = 0

union all

--4.1.1.13
select
[Код столбца] = '13'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
left join finAnalytics.PBR_MONTHLY kp on kp.repmonth=@repmonth /*and kp.repdate=@repdate*/ and a.dogNum=kp.dogNum
where upper(a.clientType)!=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
and (upper(a.zaymGroup)=upper('Займ субъекту малого и среднего предпринимательства необеспеченный')
    or
    upper(a.zaymGroup)=upper('Займ индивидуальному предпринимателю необеспеченный')
    )
and a.PROScategoy=@prosCategory
and upper(kp.isMSPbyRepDate) != upper('Да')

union all

--4.1.1.14
select
[Код столбца] = '14'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
where upper(a.clientType)=upper('ФЛ')
and upper(isnull(a.nomenklGroup,''))=upper('PDL')
and (
    upper(a.zaymGroup)=upper('Займ реструктурированный /рефинсированный необеспеченный')
    or
    upper(a.zaymGroup)=upper('Займ реструктурированный физическому лицу краткосрочный')
    )
and a.PROScategoy=@prosCategory

union all

--4.1.1.15
select
[Код столбца] = '15'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
where 1=1
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
and upper(a.zaymGroup)=upper('Займ реструктурированный /рефинсированный обеспеченный')
and a.PROScategoy=@prosCategory

union all

--4.1.1.16
select
[Код столбца] = '16'
,[Значение] = 0

union all

--4.1.1.17
select
[Код столбца] = '17'
,[Значение] = case when @dataLevel=1 then round(cast(isnull(a.restOD,0) as money),3)
                   when @dataLevel=2 then round(cast(isnull(a.sumOD,0) as money),3)
                   when @dataLevel=3 then round(cast(isnull(a.restPRC,0) + isnull(a.restPenia,0) as money),3)
                   when @dataLevel=4 then round(cast(isnull(a.sumPRC,0) + isnull(a.sumPenia,0) as money),3)
            end
from #RESERV a
where 1=1
and upper(isnull(a.nomenklGroup,''))!=upper('PDL')
and upper(a.zaymGroup)=upper('Займ реструктурированный /рефинсированный необеспеченный')
and a.PROScategoy=@prosCategory

) l1
) l2

group by
l2.rownum,l2.col1,l2.col2


END

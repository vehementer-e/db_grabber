

CREATE PROCEDURE [finAnalytics].[calcRep840_v2]
	@repmonth date,
    @repdate date
AS
BEGIN

BEGIN TRY

delete from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate

insert into finAnalytics.rep840
(REPMONTH, REPDATE, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.1
select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.1'
,pokazatel = 'Сумма задолженности по основному долгу по выданным микрозаймам на конец отчетного периода, тысяч рублей, в том числе выданным следующим субъектам:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.1.1, 2.1.2, 2.1.3'
,1
,1
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.1.1', '2.1.2', '2.1.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.1.%'

--2.2
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.2'
,pokazatel = 'Сумма задолженности по процентным доходам по выданным микрозаймам на конец отчетного периода, тысяч рублей, в том числе выданным следующим субъектам:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.2.1, 2.2.2, 2.2.3'
,1
,13
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.2.1', '2.2.2', '2.2.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.2.%'

--2.3
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.3'
,pokazatel = 'Количество действующих договоров микрозайма на конец отчетного периода, штук, в том числе заключенных со следующими субъектами:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.3.1, 2.3.2, 2.3.3'
,0
,25
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.3.1', '2.3.2', '2.3.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,0
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.3.%'

--2.4
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.4'
,pokazatel = 'Количество заемщиков по договорам микрозайма, действующим на конец отчетного периода, в том числе:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.4.1, 2.4.2, 2.4.3'
,0
,37
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.4.1', '2.4.2', '2.4.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,0
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.4.%'

--2.5
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.5'
,pokazatel = 'Количество договоров микрозайма, заключенных за отчетный период, штук, в том числе со следующими субъектами:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.5.1, 2.5.2, 2.5.3'
,0
,49
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.5.1', '2.5.2', '2.5.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,0
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.5.%'

--2.6
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.6'
,pokazatel = 'Сумма микрозаймов, выданных за отчетный период следующим субъектам, тысяч рублей:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.6.1, 2.6.2, 2.6.3'
,1
,61
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.6.1', '2.6.2', '2.6.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.6.%'

--2.7
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.7'

--2.7.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.7.1'

--2.8
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.8'

--2.8.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.8.1'

--2.9
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.9'

--2.9.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.9.1'


--2.10
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.10'

--2.10.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.10.1'




--2.11
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.11'
,pokazatel = 'Сумма задолженности по основному долгу по выданным онлайн-микрозаймам на конец отчетного периода, тысяч рублей, в том числе:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.11.1, 2.11.2, 2.11.3'
,1
,1
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.11.1', '2.11.2', '2.11.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.11.%'

--2.12
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.12'
,pokazatel = 'Сумма задолженности по процентным доходам по выданным онлайн-микрозаймам на конец отчетного периода, тысяч рублей, в том числе:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.12.1, 2.12.2, 2.12.3'
,1
,11
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.12.1', '2.12.2', '2.12.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.12.%'

--2.13
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.13'
,pokazatel = 'Количество действующих договоров онлайн-микрозайма на конец отчетного периода, штук, в том числе заключенных со следующими субъектами:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.13.1, 2.13.2, 2.13.3'
,0
,21
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.13.1', '2.13.2', '2.13.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,0
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.13.%'

--2.14
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.14'
,pokazatel = 'Количество заемщиков по договорам онлайн-микрозайма, действующим на конец отчетного периода, единиц, в том числе:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.14.1, 2.14.2, 2.14.3'
,0
,31
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.14.1', '2.14.2', '2.14.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,0
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.14.%'

--2.15
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.15'
,pokazatel = 'Количество заключенных за отчетный период договоров онлайн-микрозайма, штук, в том числе со следующими субъектами:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.15.1, 2.15.2, 2.15.3'
,0
,41
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.15.1', '2.15.2', '2.15.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,0
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.15.%'

--2.16
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,punkt = '2.16'
,pokazatel = 'Сумма выданных за отчетный период онлайн-микрозаймов, тысяч рублей, в том числе следующим субъектам:'
,amount = sum(isnull(cast (a.[value] as money),0))
,comment = 'сумма п.п. 2.16.1, 2.16.2, 2.16.3'
,1
,51
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt in ('2.16.1', '2.16.2', '2.16.3')
group by 
a.REPMONTH
,a.REPDATE
,a.razdel

union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt like '2.16.%'

--2.17
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.17'

--2.17.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.17.1'

--2.18
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.18'

--2.18.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.18.1'

--2.19
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.19'

--2.19.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.19.1'

--2.20
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.20'

--2.20.1
union all

select
a.REPMONTH
,a.REPDATE
,a.razdel
,a.punkt
,a.pokazatel
,a.value
,a.comment
,1
,a.rownum
from finAnalytics.rep840_firstLevel a
where a.REPMONTH=@repmonth
and a.REPDATE=@repdate
and a.punkt = '2.20.1'

	end try

	BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  

END

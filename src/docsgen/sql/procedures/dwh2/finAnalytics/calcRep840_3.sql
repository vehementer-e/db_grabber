


CREATE PROCEDURE [finAnalytics].[calcRep840_3]
	@repmonth date
AS
BEGIN

delete from finAnalytics.rep840_3 where REPMONTH = @repmonth

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1'
, pokazatel = 'Норматив достаточности собственных средств микрофинансовой компании, процентов'
, value = (
			select
			valResult = isnull(round(l1.val3_5 / (l1.val3_5_1 + l1.valA) * 100,2),0)
			from(
			select
			val3_5 = a.value
			,val3_5_1 = b.val3_5_1
			,valA = c.valA
			from finAnalytics.rep840_3_detail a

			left join (
			select
			val3_5_1 = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.5.1.1','3.5.1.2','3.5.1.3','3.5.1.4','3.5.1.5','3.5.1.6','3.5.1.7')
			and pokazatel='ИТОГО по Пункту'
			) b on 1=1

			left join (
			select
			valA = sum(case when substring(groupName,1,2) in ('А1') then a.value * -1 else a.value end)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and substring(groupName,1,1) in ('А')
			and pokazatel='ИТОГО по Пункту'
			) c on 1=1

			where REPMONTH = @repmonth
			and punkt in ('3.5')
			and pokazatel='ИТОГО по Пункту'
			) l1
)
, comment = '3.5/(3.5.1+А2+A3+A4+A5-A1)*100 (округлить до 2-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 1


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, pokazatel = 'значение показателя A1, тысяч рублей'
, value = (
			select
valResult = isnull(round(SUM(a.value),3),0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.1')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.1 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 2


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.2'
, pokazatel = 'значение показателя А2, тысяч рублей'
, value = (
			select
valResult = isnull(round(SUM(a.value),3),0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.2')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.2 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 3


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, pokazatel = 'значение показателя АЗ, тысяч рублей'
, value = (
			select
valResult = isnull(round(SUM(a.value),3),0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.3')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.3 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 4


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, pokazatel = 'значение показателя А4, тысяч рублей'
, value = (
			select
valResult = isnull(round(SUM(a.value),3),0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.4')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.4 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 5

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.5'
, pokazatel = 'значение показателя А5, тысяч рублей'
, value = (
			select
valResult = isnull(round(SUM(a.value),3),0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.5')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.5 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 6

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.6'
, pokazatel = 'значение показателя А6, тысяч рублей'
, value = (
			select
valResult = isnull(round(SUM(a.value),3),0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.6')
and pokazatel!='ИТОГО по Пункту'

)
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 7


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.7'
, pokazatel = 'РВПЗ по займам, включаемым в расчет показателя А1'
, value = (
			select
valResult = isnull(round(SUM(a.value),3) * -1,0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.7')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.7 детализации (округлить до 3-го знака после запятой) Инвертируем знак'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 8


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.8'
, pokazatel = 'РВПЗ по займам, включаемым в расчет показателя А2'
, value = (
			select
valResult = isnull(round(SUM(a.value),3) * -1,0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.8')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.8 детализации (округлить до 3-го знака после запятой) Инвертируем знак'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 9

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.9'
, pokazatel = 'РВПЗ по займам, включаемым в расчет показателя А3'
, value = (
			select
valResult = isnull(round(SUM(a.value),3) * -1,0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.9')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.9 детализации (округлить до 3-го знака после запятой) Инвертируем знак'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 10


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.10'
, pokazatel = 'РВПЗ по займам, включаемым в расчет показателя А4'
, value = (
			select
valResult = isnull(round(SUM(a.value),3) * -1,0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.10')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.10 детализации (округлить до 3-го знака после запятой) Инвертируем знак'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 11


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.11'
, pokazatel = 'РВПЗ по займам, включаемым в расчет показателя А5'
, value = (
			select
valResult = isnull(round(SUM(a.value),3) * -1,0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.11')
and pokazatel!='ИТОГО по Пункту'

)
, comment = 'сумма строк 3.1.11 детализации (округлить до 3-го знака после запятой) Инвертируем знак'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 12


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.1.12'
, pokazatel = 'РВПЗ по займам, включаемым в расчет показателя А6'
, value = (
			select
valResult = isnull(round(SUM(a.value),3) * -1,0)
from finAnalytics.rep840_3_detail a
where REPMONTH = @repmonth
and punkt in ('3.1.12')
and pokazatel!='ИТОГО по Пункту'

)
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 13


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2'
, pokazatel = 'Норматив ликвидности микрофинансовой компании, процентов'
, value = (
			select
			valResult = isnull(round(b.val3_2_1 / a.val3_2_4 * 100,2),0)
			from(
			select
			val3_2_4 = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.2.4')
			and pokazatel!='ИТОГО по Пункту'
			) a
			left join (
			select
			val3_2_1 = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and (
				(punkt ='3.2.1.1' and BS in ('48501','48801','49401'))
				or
				(punkt ='3.2.2' and BS in ('48510','48810','49410'))
				or punkt in ('3.2.1.2','3.2.1.3','3.2.1.4','3.2.1.5','3.2.1.6')
				)
			and pokazatel!='ИТОГО по Пункту'
			) b on 1=1

			

)
, comment = '3.2.1/3.2.4*100 (округлить до 2-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 14



insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.1'
, pokazatel = 'ликвидные активы, тысяч рублей, в том числе:'
, value = (
			
			select
			val3_2_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and (
				(punkt ='3.2.1.1' and BS in ('48501','48801','49401'))
				or
				(punkt ='3.2.2' and BS in ('48510','48810','49410'))
				or punkt in ('3.2.1.2','3.2.1.3','3.2.1.4','3.2.1.5','3.2.1.6')
				)
			
			and pokazatel!='ИТОГО по Пункту'
			
)
, comment = 'сумма строк 3.2.1.1-3.2.1.6'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 15


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.1.1'
, pokazatel = 'средства, предоставленные по договорам займа (микрозайма), за вычетом резервов на возможные потери по займам'
, value = (
			
			select
			val3_2_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and (
				(punkt ='3.2.1.1' and BS in ('48501','48801','49401'))
				or
				(punkt ='3.2.2' and BS in ('48510','48810','49410'))
				)
			and pokazatel!='ИТОГО по Пункту'
			
)
, comment = 'сумма строк (3.2.1.1 (48501, 48801, 49401)-3.2.2 (48510, 48810, 49410) детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 16


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.1.2'
, pokazatel = 'приобретенные права требования по договорам займа (микрозайма), за вычетом резервов на возможные потери по займам'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 17



insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.1.3'
, pokazatel = 'денежные средства и денежные эквиваленты'
, value = (
			
			select
			val3_2_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt ='3.2.1.3'
			and pokazatel!='ИТОГО по Пункту'
			
)
, comment = 'сумма строк 3.2.1.3 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 18



insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.1.4'
, pokazatel = 'прочие предоставленные средства'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 19


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.1.5'
, pokazatel = 'дебиторская задолженность'
, value = (
			
			select
			val3_2_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt ='3.2.1.6'
			and pokazatel!='ИТОГО по Пункту'
			
)
, comment = 'сумма строк 3.2.1.6 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 20


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, pokazatel = 'иные финансовые активы, принимаемые для расчета показателя'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 21


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.2'
, pokazatel = 'величина резервов на возможные потери по займам, рассчитанных по указанным в строке 3.2.1.1 настоящего раздела требованиям, тысяч рублей'
, value = (
			
			select
			val3_2_1 = isnull(round(sum(a.value),3)*-1,0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt ='3.2.2'
			and pokazatel!='ИТОГО по Пункту'
			
)
, comment = 'сумма строк 3.2.2 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 22


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.3'
, pokazatel = 'величина резервов на возможные потери по займам, рассчитанных по указанным в строке 3.2.1.2 настоящего раздела требованиям, тысяч рублей'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 23


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, pokazatel = 'сумма обязательств микрофинансовой компании, срок исполнения по которым не превышает 90 календарных дней, для расчета норматива ликвидности микрофинансовой компании, тысяч рублей'
, value = (
			
			select
			val3_2_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt ='3.2.4'
			and pokazatel!='ИТОГО по Пункту'
			
)
, comment = 'сумма строк 3.2.4 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 24





insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.3.1'
, pokazatel = 'сумма требований микрофинансовой компании к одному заемщику (группе связанных заемщиков), возникших по обязательствам заемщика (заемщиков, входящих в группу связанных заемщиков) перед микрофинансовой компанией и перед третьими лицами по договорам кредита и займа, вследствие которых у микрофинансовой компании возникают требования в отношении указанного заемщика (заемщиков, входящих в группу связанных заемщиков), за вычетом величины резервов на возможные потери по займам, тысяч рублей'
, value = (
			select
			val3_3_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.3.1','3.3.2')
			and pokazatel!='ИТОГО по Пункту'
)
, comment = 'сумма строк 3.3.1 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 26


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.3.2'
, pokazatel = 'величина резервов на возможные потери по займам, рассчитанных по указанным в строке 3.3.1 настоящего раздела требованиям, тысяч рублей'
, value = (
			select
			val3_3_1 = abs(isnull(round(sum(a.value),3),0))
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.3.2')
			and pokazatel!='ИТОГО по Пункту'
			)
, comment = 'Сумма строк 3.3.2/1000 детализации (округлить до 3-го знака после запятой) - абсолютное значение'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 27


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.4'
, pokazatel = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией), процентов'
, value = (
			select
			valResult = isnull(round(l1.val3_4_1 / l1.val3_5 * 100,2),0)
			from(
			select
			val3_5 = a.value
			,val3_4_1 = b.val3_4_1
			from finAnalytics.rep840_3_detail a

			left join (
			select
			val3_4_1 = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.4.1')
			and pokazatel!='ИТОГО по Пункту'
			) b on 1=1

			where REPMONTH = @repmonth
			and punkt in ('3.5')
			and pokazatel='ИТОГО по Пункту'
			) l1
)
, comment = '3.4.1/3.5*100 (округлить до 2-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 28



insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.4.1'
, pokazatel = 'сумма требований микрофинансовой компании к связанному с микрофинансовой компанией лицу (группе лиц, связанных с микрофинансовой компанией), возникших по обязательствам 
связанного с микрофинансовой компанией лица (группы лиц, связанных с микрофинансовой компанией) перед микрофинансовой компанией и перед третьими лицами, вследствие которых у '
--микрофинансовой компании возникают требования в отношении указанного лица (группы лиц, связанных с микрофинансовой компанией), за вычетом величины резервов на возможные потери '
--по займам, тысяч рублей'
, value = (
			select
			val3_5_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.4.1')
			--and pokazatel='ИТОГО по Пункту'
		  )
, comment = 'сумма строк 3.4.1/1000 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 29


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.4.2'
, pokazatel = 'величина резервов на возможные потери по займам, рассчитанных по указанным в строке 3.4.1 настоящего раздела требованиям, тысяч рублей'
, value = (
			select
			val3_5_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.4.2')
			--and pokazatel='ИТОГО по Пункту'
		  )
, comment = 'сумма строк 3.4.2/1000 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 30


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5'
, pokazatel = 'Собственные средства (капитал), рассчитанные в соответствии с Указанием Банка России N 5253-У, тысяч рублей'
, value = (
			select
			valResult = isnull(round((l1.val3_5_1 - l1.val3_5_2),2),0)
			from(
			select
			val3_5_2 = a.value
			,val3_5_1 = b.val3_5_1
			from finAnalytics.rep840_3_detail a

			left join (
			select
			val3_5_1 = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.5.1.1','3.5.1.2','3.5.1.3','3.5.1.4','3.5.1.5','3.5.1.6','3.5.1.7')
			and pokazatel='ИТОГО по Пункту'
			) b on 1=1

			
			where REPMONTH = @repmonth
			and punkt in ('3.5.2')
			and pokazatel='ИТОГО по Пункту'
			) l1
)
, comment = '3.5.1-3.5.2 (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 31

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.3'
, pokazatel = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков, процентов'
, value = (
			select
			valResult = isnull(round(l1.val3_3_1 / l1.val3_5 * 100,2),0)
			from(
			select
			val3_5 = a.value
			,val3_3_1 = b.val3_3_1
			from finAnalytics.rep840_3/*_detail*/ a

			left join (
			select
			val3_3_1 = sum(a.value)
			from finAnalytics.rep840_3/*_detail*/ a
			where REPMONTH = @repmonth
			and punkt in ('3.3.1')
			--and pokazatel!='ИТОГО по Пункту'
			) b on 1=1

			where REPMONTH = @repmonth
			and punkt in ('3.5')
			--and pokazatel='ИТОГО по Пункту'
			) l1
)
, comment = '3.3.1/3.5*100 (округлить до 2-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 25

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1'
, pokazatel = 'финансовые активы, в том числе:'
, value = (
			select
			val3_5_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.5.1.1','3.5.1.2','3.5.1.3','3.5.1.4','3.5.1.5','3.5.1.6','3.5.1.7')
			and pokazatel='ИТОГО по Пункту'
)
, comment = '3.5.1-3.5.2 (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 32



insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, pokazatel = 'требования по договорам микрозайма по основному долгу, начисленным процентам, иным платежам в пользу микрофинансовой компании, а также по неустойке (штрафу, пене) в сумме, присужденной судом или признанной заемщиком, за вычетом величины резервов на возможные потери по займам'
, value = (
			select
			val3_5_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.5.1.1')
			and pokazatel='ИТОГО по Пункту'
)
, comment = 'сумма строк 3.5.1.1 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 33


insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, pokazatel = 'требования по договорам займа по основному долгу, начисленным процентам, иным платежам в пользу микрофинансовой компании, а также по неустойке (штрафу, пене) в сумме, присужденной судом или признанной заемщиком, (за исключением договоров микрозайма) за вычетом величины резервов на возможные потери по займам'
, value = (
			select
			val3_5_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.5.1.2')
			and pokazatel='ИТОГО по Пункту'
)
, comment = 'сумма строк 3.5.1.2/1000 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 34

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.3'
, pokazatel = 'денежные средства, размещенные по договорам банковского вклада (депозита), заключенным с кредитными организациями'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 35

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.4'
, pokazatel = 'государственные ценные бумаги Российской Федерации'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 36

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.5'
, pokazatel = 'облигации российских эмитентов'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 37

insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.6'
, pokazatel = 'акции российских эмитентов'
, value = 0
, comment = '-'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 38



insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.7'
, pokazatel = 'денежные средства и их эквиваленты'
, value = (
			select
			val3_5_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.5.1.7')
			and pokazatel='ИТОГО по Пункту'
)
, comment = 'сумма строк 3.5.1.7 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 39



insert into finAnalytics.rep840_3 
(REPMONTH, punkt, pokazatel, value, comment, checkMethod1, chekResult1, checkMethod2, chekResult2, checkMethod3, chekResult3, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, pokazatel = 'обязательства микрофинансовой компании'
, value = (
			select
			val3_5_1 = isnull(round(sum(a.value),3),0)
			from finAnalytics.rep840_3_detail a
			where REPMONTH = @repmonth
			and punkt in ('3.5.2')
			and pokazatel='ИТОГО по Пункту'
)
, comment = 'сумма строк 3.5.2 детализации (округлить до 3-го знака после запятой)'
, checkMethod1 = null
, chekResult1 = null
, checkMethod2 = null
, chekResult2 = null
, checkMethod3 = null
, chekResult3 = null
, rownum = 40

END

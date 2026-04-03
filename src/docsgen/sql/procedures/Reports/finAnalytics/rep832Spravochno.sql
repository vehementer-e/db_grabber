



CREATE PROCEDURE [finAnalytics].[rep832Spravochno]
	@qName NVarchar(50)
	
AS
BEGIN

declare @repmonth date 
declare @repmonthFrom date
declare @repmonthTo date

set @repmonth = (select max(repmonth) from dwh2.finAnalytics.rep832 where qName = @qName)

set @repmonthFrom = (

select 
min(Month_Value)
from dwh2.Dictionary.calendar dd
where Year_Quartal_Name = @qName
)

set @repmonthTo = @repmonth

select
dogCount = sum(l1.dogCount)
,dogSum = sum(l1.dogSum)
from(
select
dogNum = a.dogNum
,dogCode = case 
				when upper(a.isDogPoruch) in (upper('Залог самоходных машин'))
					or a.isDogPoruch is null then '1 - Иные потребительские кредиты (займы)'
				when upper(a.isDogPoruch) in (upper('Залог Автомототранспортного средства'))
					and upper(a.nomenkGroup) = upper('Автокредит') then '2 - Потребительские кредиты (займы) на приобретение автотранспортного средства под залог автотранспортного средства'
				when upper(a.isDogPoruch) in (upper('Залог Автомототранспортного средства'))
					and upper(a.nomenkGroup) not in (upper('Автокредит'),upper('ПТС Займ для Самозанятых')) then '3 - Потребительские кредиты (займы) по залог автотранспортного средства'
				else '0'
			end
,dogCount = 1
,dogSum = a.dogSum
from dwh2.finAnalytics.PBR_MONTHLY a
where a.repmonth = @repmonth
and upper(isZaemshik) = 'ФЛ'
and upper(dogStatus) in (upper('Действует'),upper('Закрыт'))
and a.saleDate between @repmonthFrom and EOMONTH(@repmonthTo)
) l1
where l1.dogCode = '1 - Иные потребительские кредиты (займы)'

select
@repmonthFrom ,EOMONTH(@repmonthTo)

END

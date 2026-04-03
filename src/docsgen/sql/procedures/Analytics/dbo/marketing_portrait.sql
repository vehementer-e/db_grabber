CREATE proc [dbo].[marketing_portrait]   @dateFrom date =  null , @dateTo date =  null 
as

drop table if exists #t1

 
select number, gender, carYear, age, region, employmentType,employmentPosition, reportDateLoan, cast(DATEADD(qq   , DATEDIFF(qq   , 0, reportDateLoan), 0) as date) reportQuaterLoan, isloan 
, case 
when age <= 24 then  '21-24'
when age <= 34 then  '25-34'
when age <= 44 then  '35-44'
when age <= 54 then  '45-54'
when age <= 100 then '55-65'
end ageBucket 
, monthlyIncome
, case
when monthlyIncome <= 50000  then '1) до     50000'
when monthlyIncome <= 70000  then '2) 50000- 70000'
when monthlyIncome <= 100000 then '3) 70000- 100000'
when monthlyIncome <= 120000 then '4) 100000-120000'
when monthlyIncome <= 150000 then '5) 120000-150000'
when monthlyIncome <= 170000 then '6) 150000-170000'
when monthlyIncome <= 200000 then '7) 170000-200000'
when monthlyIncome >  200000 then '8) более  200000' 
end monthlyIncomeBucket ,
-  caryear + yEAR( reportDateLoan) carAge
into #t1
from v_request
where  ispts=1 and  cast(DATEADD(qq   , DATEDIFF(qq   , 0, reportDateLoan), 0) as date) between @dateFrom and @dateTo

and call1 is not null
and isnew=1
 ;

 

 select * from #t1
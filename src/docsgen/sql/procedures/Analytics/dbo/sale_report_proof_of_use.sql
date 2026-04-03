CREATE proc   [dbo].[sale_report_proof_of_use] @mode varchar(max)

as

if @mode= 'report'
exec python 'sql2gs("exec sale_report_proof_of_use ''select''", "1-aXXDM3Wy4eHsEGgPu8lF5hZOc3DXMmUm0XX0qoMdXI", sheet_name = "отчет")' , 1



if @mode= 'select'


 

with v as(


  select   a.Ссылка link
  , max( b.КМ_Договор ) requestLink
  , cast( max(case when Свойство = 0xB80F00155D03492511E986B9BC8786EF then dateadd(year, -2000, Значение_Дата)  end )  as date) [дата предоставления документа]
  , max(case when Свойство = 0xB385DA089286DF9C11F0AB2B5A05B491 then  Значение_Число end ) [сумма подтверждения]
  
  
  from stg.[_1cDCMNT]. [Справочник_ВходящиеДокументы_ДополнительныеРеквизиты] a
  left join [Stg].[_1cDCMNT].[Справочник_ВходящиеДокументы] b  on a.Ссылка =b.Ссылка
  group by a.Ссылка
  having count(case when  Значение_Ссылка=0xB38493122D034F4311F092DE93304DA0 and Свойство= 0xB80F00155D03492511E986B2EA8374F1 then 1 end)>0
 and  max(case when Свойство = 0xB385DA089286DF9C11F0AB2B5A05B491 then  Значение_Число end ) >0


) 

select [дата выдачи] =  min(a.issuedDate)
, [номер договора] =   a.number  
, [статус договора] = min(a.status_crm)
, [ФИО клиента] =  min( a.fio )
, phone = min(  a.phone)

, [email] = min(  a.email)
, [сумма выдачи (без КП)] =  cast(min( a.issuedSumClean ) as int)
, [признак подтверждения ЦИ] = case when sum(b.[сумма подтверждения]) >=  min( a.issuedSumClean ) then 1 else 0 end
, [сумма подтверждения ЦИ] =  cast(  isnull( sum(b.[сумма подтверждения]) ,0) as int)
, [дата подтверждения ЦИ на 100%] =  min (case when sumCumul >=a.issuedSumClean then  b.date end)
, [сколько осталось подтвердить] =  cast( case when  min( a.issuedSumClean )  -  isnull( sum(b.[сумма подтверждения]) ,0) > 0 then   min( a.issuedSumClean )  -  isnull( sum(b.[сумма подтверждения]) ,0) else 0 end as int)
, [сколько полных месяцев действует договор] = cast(dbo.FullMonthsSeparation(min(a.issuedDate) , getdate()) as int)


from request a
left join (
--select *, sum(isnull([сумма подтверждения], 0) ) over(partition by [номер договора] order by convert( date, [дата предоставления документа] , 104 ) ) sumCumul
--, convert( date, [дата предоставления документа] , 104 ) date

--from 

--_request_proof_of_use_gs


select *, sum(isnull([сумма подтверждения], 0) ) over(partition by requestLink order by   [дата предоставления документа]  ) sumCumul
, [дата предоставления документа] date

from 

v





)b on a.link = b.requestLink

where (productSubType like '%самозан%' or isSelfEmployedManual = 1)
and issued is not null
group by a.number  
order by min(issued)
  

 										

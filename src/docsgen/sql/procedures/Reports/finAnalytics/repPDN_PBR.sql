
CREATE PROCEDURE [finAnalytics].[repPDN_PBR]
    @REP_MONTH date
AS
BEGIN
	DROP TABLE IF EXISTS [finAnalytics].#ID_LIST

Create table [finAnalytics].#ID_LIST(
    [ID] bigint NOT NULL
    )

insert into #ID_LIST
select
a.ID
from dwh2.finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@REP_MONTH --and a.REPDATE=@REP_DATE


DROP TABLE IF EXISTS [finAnalytics].#rep_result
--DROP TABLE [finAnalytics].#rep_result

Create table [finAnalytics].#rep_result(
    [ProductByNGroup] int NOT NULL,
    [L] int NOT NULL,
    [iBRPT] int NOT NULL,
    [KK] int NOT NULL,
    [KKSVO] int NOT NULL,
    [iDPD] int NOT NULL,
    [iDI] int NOT NULL,
    [isA2] int NOT NULL,
    [AccODNum] nvarchar(10) NOT NULL,
    [isZaemshik] nvarchar(10) NOT NULL,
    [client] nvarchar(500) NULL,
    [dogNum] nvarchar(20) NOT NULL,
    [saleDate] date NOT NULL,
    [IssueSum] float NOT NULL,
    [PDNOnRepDate] float NOT NULL,
    [prosDaysTotal] int NOT NULL,
    [isMicroziam] int NOT NULL,
    [restOD] float NOT NULL,
    [restPRC] float NOT NULL,
    [nomenkGroup] nvarchar(50) NOT NULL,
    [reservBUODSum] float NOT NULL,
    [reservBUpPrcSum] float NOT NULL,
    [reservOD] float NOT NULL,
    [reservPRC] float NOT NULL,
    [isBunkrupt] nvarchar(10) NOT NULL,
    [restPenia] float NOT NULL,
    [reservProch] float NOT NULL,
    [dogPeriodDays] int null
    )
-------------------------------------------------------------------

insert into #rep_result

select
[ProductByNGroup] = case when l1.isMicroziam=0 then 9 
                         when l1.isMicroziam=1 and upper(l1.isZaemshik)='ФЛ' then 
                            case when upper(l1.nomenkGroup) in (upper('Installment'), upper('PromoInstallment')) then 1 
                                 when upper(l1.nomenkGroup) =upper('SmartInstallment') then 2
                                 when upper(l1.nomenkGroup) =upper('PDL') then 5
                            else 0
                            end
                         else 7 end
,[L] =case when l1.isMicroziam=0 then 9 else l1.L end
,[iBRPT] =case when l1.isMicroziam=0 then 3 else l1.iBRPT end
,[KK] = case when l1.isMicroziam=0 then 3 else case when l1.KK=1 and l1.iBRPT=1 then 2 else l1.KK end end
,[KKSVO] = case when l1.isMicroziam=0 then 3 else case when l1.KK_SVO=1 and l1.iBRPT=1 then 2 else l1.KK_SVO end end
,[iDPD] = case when l1.isMicroziam=0 then 26 else l1.iDPD end
,[iDI] = case when l1.isMicroziam=0 then 9 
              when l1.saleDate <= cast('2022-02-28' as date) then 1
              when l1.saleDate between cast('2022-03-01' as date) and cast('2022-09-30' as date) then 2
              when l1.saleDate between cast('2022-10-01' as date) and cast('2022-10-31' as date) then 3
              when l1.saleDate >= cast('2022-11-01' as date) then 4
              else 0 
        end
,[isA2] = case when l1.dogPeriodDays <=30 and l1.dogSum<=30000 then 1 else 0 end
,l1.AccODNum
,l1.isZaemshik
,l1.client
,l1.dogNum
,l1.saleDate
,[IssueSum] = 0--case when cast(l1.saleDate as date)=@REP_DATE then l1.dogSum else 0 end
,l1.PDNOnRepDate
,l1.prosDaysTotal
,l1.isMicroziam
,l1.restOD
,l1.restPRC
,[nomenkGroup] = isnull(l1.nomenkGroup,'-')
,l1.reservBUODSum
,l1.reservBUpPrcSum
,l1.reservOD
,l1.reservPRC
,l1.isBunkrupt
,l1.restPenia
,l1.reservProch
,l1.dogPeriodDays
from(
select
[isMicroziam] = case when substring(a.AccODNum,1,5) in ('48701', '48801', '49001', '49401') then 1 else 0 end
,[L] = case when a.PDNOnRepDate=0 then case when a.dogSum < 10000 and a.isZaemshik='ФЛ' then 3 ELSE 0 END
            when a.PDNOnRepDate!=0 then case when a.PDNOnRepDate >0 and a.PDNOnRepDate <=0.5 then 0 
                                             when a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <=0.8 then 1 
                                             when a.PDNOnRepDate > 0.8 then 2 
                                             ELSE 0 end 
       END
,[iBRPT] = case when bnkrupt.[Заемщик] is not null and bnkrupt.[Исключить] = 0 then 1
                     when bnkrupt.[Заемщик] is null and upper(a.isBankrupt) = upper('Да') then 1
                     else 0 end
,[KK] = case when kk.dogNum is not null then 1 else 0 end
,[KK_SVO] = case when kksvo.dogNum is not null then 1 else 0 end
,[iDPD] = case when (a.prosDaysTotal is null or a.prosDaysTotal=0) then 0
               when a.prosDaysTotal between 1 and 30 then 1
               when a.prosDaysTotal between 31 and 60 then 2
               when a.prosDaysTotal between 61 and 90 then 3
               when a.prosDaysTotal between 91 and 120 then 4
               when a.prosDaysTotal between 121 and 150 then 5
               when a.prosDaysTotal between 151 and 180 then 6
               when a.prosDaysTotal between 181 and 210 then 7
               when a.prosDaysTotal between 211 and 240 then 8
               when a.prosDaysTotal between 241 and 270 then 9
               when a.prosDaysTotal between 271 and 300 then 10
               when a.prosDaysTotal between 301 and 330 then 11
               when a.prosDaysTotal between 331 and 360 then 12
               when a.prosDaysTotal between 361 and 390 then 13
               when a.prosDaysTotal between 391 and 420 then 14
               when a.prosDaysTotal between 421 and 450 then 15
               when a.prosDaysTotal between 451 and 480 then 16
               when a.prosDaysTotal between 481 and 510 then 17
               when a.prosDaysTotal between 511 and 540 then 18
               when a.prosDaysTotal between 541 and 570 then 19
               when a.prosDaysTotal between 571 and 600 then 20
               when a.prosDaysTotal between 601 and 630 then 21
               when a.prosDaysTotal between 631 and 660 then 22
               when a.prosDaysTotal between 661 and 690 then 23
               when a.prosDaysTotal between 691 and 720 then 24
               when a.prosDaysTotal >=721 then 25
               else 0 end

,[AccODNum]= substring(a.AccODNum,1,5) 
,[isZaemshik] = a.isZaemshik
,[dogSum] = a.dogSum
,[PDNOnRepDate] = a.PDNOnRepDate
,[client] = a.client
,[dogNum] = a.dogNum
,[saleDate] = a.saleDate
,[prosDaysTotal] = a.prosDaysTotal
,[restOD] = a.zadolgOD
,[restPRC] = a.zadolgPrc
,[nomenkGroup] = a.nomenkGroup
,[reservBUODSum] = a.reservBUODSum
,[reservBUpPrcSum] = a.reservBUpPrcSum
,[reservOD] = a.reservOD
,[reservPRC] = a.reservPRC
,[isBunkrupt] =  a.isBankrupt
,[restPenia] = a.penyaSum
,[reservProch] = a.reservProchSumNU
,[dogPeriodDays] = a.dogPeriodDays
from dwh2.finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.id=b.ID

----Привязываем банкротов
left join (
select --top 1

[Дата] = cast(dateadd(year,-2000,a.Дата) as date)
,[Заемщик] = b.Наименование
---Признак исключения для проброски в ПБР
,[Исключить] = case when a.Номер in ('00БП-0266','00БП-0302','00БП-0496','00БП-0637','00БП-0733') then 1 else 0 end
---Считаем дубли и берем максимальное по дате в кореляции с отчетной датой
,ROW_NUMBER() over (Partition by b.Наименование order by a.Дата desc) rn

from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
where 1=1
and a.ПометкаУдаления =  0x00
and a.Проведен=0x01
and cast(dateadd(year,-2000,a.Дата) as date) <=EOMONTH(@REP_MONTH)
) bnkrupt on a.Client=bnkrupt.[Заемщик] and bnkrupt.rn=1 --bnkrupt.[Дата]<=eomonth(a.repmonth)


-------Привязываем КК обычные
left join (
SELECT 
      [dogNum]
      ,[KKBegDate]
      --,[vacationType]
      ,ROW_NUMBER() over (partition by [dogNum] order by [KKBegDate] desc) rn
  FROM [dwh2].[finAnalytics].[CredVacation]
  where 1=1
  --and upper(isnull([vacationType],'')) != upper('КК СВО')
  and [KKBegDate]<=EOMONTH(@REP_MONTH)
) kk on a.dogNum=kk.dogNum and kk.rn=1

-------Привязываем КК СВО
left join (
SELECT 
      [dogNum]
      ,[KKBegDate]
      --,[vacationType]
      ,ROW_NUMBER() over (partition by [dogNum] order by [KKBegDate] desc) rn
  FROM [dwh2].[finAnalytics].[CredVacation]
  where upper(isnull([vacationType],'')) = upper('КК СВО')
  and [KKBegDate]<=EOMONTH(@REP_MONTH)
) kksvo on a.dogNum=kksvo.dogNum and kksvo.rn=1


) l1



-----------Первый блок
select
[blockName] = 'Показатели старые'
,[razdelName] = 'Выдано, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,[amount2] = 0 
from(
select
[groupName] = case when L in (0,3)  then 'в т.ч. ПДН <=50%'
                   when L in (1,2)  then 'в т.ч. ПДН >50%'
              end
,[groupSort] = case when L in (0,3)  then 1
                   when L in (1,2)  then 2
              end
,[amount] = cast(IssueSum/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Показатели старые'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L in (0,3)  then 'в т.ч. ПДН <=50%'
                   when L in (1,2)  then 'в т.ч. ПДН >50%'
              end
,[groupSort] = case when L in (0,3)  then 1
                   when L in (1,2)  then 2
              end
,[amount] = cast((restOD+restPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Показатели старые'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L in (0,3)  then 'в т.ч. ПДН <=50%'
                   when L in (1,2)  then 'в т.ч. ПДН >50%'
              end
,[groupSort] = case when L in (0,3)  then 1
                   when L in (1,2)  then 2
              end
,[amount] = cast(restOD/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Показатели старые'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L in (0,3)  then 'в т.ч. ПДН <=50%'
                   when L in (1,2)  then 'в т.ч. ПДН >50%'
              end
,[groupSort] = case when L in (0,3)  then 1
                   when L in (1,2)  then 2
              end
,[amount] = cast(restPRC/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Показатели старые'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L in (0,3)  then 'в т.ч. ПДН <=50%'
                   when L in (1,2)  then 'в т.ч. ПДН >50%'
              end
,[groupSort] = case when L in (0,3)  then 1
                   when L in (1,2)  then 2
              end
,[amount] = cast((reservBUODSum+reservBUpPrcSum) /1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Показатели старые'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L in (0,3)  then 'в т.ч. ПДН <=50%'
                   when L in (1,2)  then 'в т.ч. ПДН >50%'
              end
,[groupSort] = case when L in (0,3)  then 1
                   when L in (1,2)  then 2
              end
,[amount] = cast((reservOD+reservPRC) /1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all
-----------Показатели новые блок
select
[blockName] = 'Показатели новые'
,[razdelName] = 'Выдано, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast(IssueSum/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Показатели новые'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Показатели новые'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Показатели новые'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Показатели новые'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Показатели новые'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all
-----------Инстолмент
select
[blockName] = 'Инстолмент'
,[razdelName] = 'Выдано, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast(IssueSum/1000000 as money)
from #rep_result
where ProductByNGroup in (1,2)
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Инстолмент'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC)/1000000 as money)
from #rep_result
where ProductByNGroup in (1,2)
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Инстолмент'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
where ProductByNGroup in (1,2)
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Инстолмент'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where ProductByNGroup in (1,2)
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Инстолмент'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
from #rep_result
where ProductByNGroup in (1,2)
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Инстолмент'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC)/1000000 as money)
from #rep_result
where ProductByNGroup in (1,2)
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all
-----------PDL
select
[blockName] = 'PDL'
,[razdelName] = 'Выдано, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast(IssueSum/1000000 as money)
from #rep_result
where ProductByNGroup =5
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'PDL'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC)/1000000 as money)
from #rep_result
where ProductByNGroup =5
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'PDL'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
where ProductByNGroup =5
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'PDL'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where ProductByNGroup =5
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'PDL'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
from #rep_result
where ProductByNGroup =5
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'PDL'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC)/1000000 as money)
from #rep_result
where ProductByNGroup =5
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

-----------КК
select
[blockName] = 'KK'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 1
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KK =0 then 'в т.ч. не КК'
                   when KK =1 then 'в т.ч. КК'
                   when KK =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KK =0 then 1
                    when KK =1 then 2
                    when KK =2 then 3
              end
,[amount] = cast((restOD+restPRC)/1000000 as money)
,[amountBnkrpt] = sum( case when KK=2 then cast((restOD+restPRC)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 2
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KK =0 then 'в т.ч. не КК'
                   when KK =1 then 'в т.ч. КК'
                   when KK =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KK =0 then 1
                    when KK =1 then 2
                    when KK =2 then 3
              end
,[amount] = cast((restOD)/1000000 as money)
,[amountBnkrpt] = sum( case when KK=2 then cast((restOD)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 3
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KK =0 then 'в т.ч. не КК'
                   when KK =1 then 'в т.ч. КК'
                   when KK =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KK =0 then 1
                    when KK =1 then 2
                    when KK =2 then 3
              end
,[amount] = cast((restPRC)/1000000 as money)
,[amountBnkrpt] = sum( case when KK=2 then cast((restPRC)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 4
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KK =0 then 'в т.ч. не КК'
                   when KK =1 then 'в т.ч. КК'
                   when KK =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KK =0 then 1
                    when KK =1 then 2
                    when KK =2 then 3
              end
,[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
,[amountBnkrpt] = sum( case when KK=2 then cast((reservBUODSum+reservBUpPrcSum)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 5
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KK =0 then 'в т.ч. не КК'
                   when KK =1 then 'в т.ч. КК'
                   when KK =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KK =0 then 1
                    when KK =1 then 2
                    when KK =2 then 3
              end
,[amount] = cast((reservOD+reservPRC)/1000000 as money)
,[amountBnkrpt] = sum( case when KK=2 then cast((reservOD+reservPRC)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

-----------КК СВО
select
[blockName] = 'KK СВО'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 1
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                   when KKSVO =1 then 'в т.ч. КК'
                   when KKSVO =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KKSVO =0 then 1
                    when KKSVO =1 then 2
                    when KKSVO =2 then 3
              end
,[amount] = cast((restOD+restPRC)/1000000 as money)
,[amountBnkrpt] = sum( case when KKSVO=2 then cast((restOD+restPRC)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK СВО'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 2
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                   when KKSVO =1 then 'в т.ч. КК'
                   when KKSVO =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KKSVO =0 then 1
                    when KKSVO =1 then 2
                    when KKSVO =2 then 3
              end
,[amount] = cast((restOD)/1000000 as money)
,[amountBnkrpt] = sum( case when KKSVO=2 then cast((restOD)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK СВО'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 3
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                   when KKSVO =1 then 'в т.ч. КК'
                   when KKSVO =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KKSVO =0 then 1
                    when KKSVO =1 then 2
                    when KKSVO =2 then 3
              end
,[amount] = cast((restPRC)/1000000 as money)
,[amountBnkrpt] = sum( case when KKSVO=2 then cast((restPRC)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK СВО'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 4
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                   when KKSVO =1 then 'в т.ч. КК'
                   when KKSVO =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KKSVO =0 then 1
                    when KKSVO =1 then 2
                    when KKSVO =2 then 3
              end
,[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
,[amountBnkrpt] = sum( case when KKSVO=2 then cast((reservBUODSum+reservBUpPrcSum)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'KK СВО'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount]) + max(l1.amountBnkrpt) else sum(l1.[amount]) end
,[orderNum] = 5
,[groupSort] = l1.groupSort
,[amount2] = sum(l1.[amount])
from(
select
[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                   when KKSVO =1 then 'в т.ч. КК'
                   when KKSVO =2 then 'из них КК-банкроты'
              end
,[groupSort] = case when KKSVO =0 then 1
                    when KKSVO =1 then 2
                    when KKSVO =2 then 3
              end
,[amount] = cast((reservOD+reservPRC)/1000000 as money)
,[amountBnkrpt] = sum( case when KKSVO=2 then cast((reservOD+reservPRC)/1000000 as money) else 0 end) over ()
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all
----------------DPD
select
[blockName] = 'DPD'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                   when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                   when iDPD between 4 and 25 then 'в т.ч. 90+'
              end
,[groupSort] = case when iDPD =0 then 1
                   when iDPD in (1,2,3) then 2
                   when iDPD between 4 and 25 then 3
              end
,[amount] = cast((restOD+restPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'DPD'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                   when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                   when iDPD between 4 and 25 then 'в т.ч. 90+'
              end
,[groupSort] = case when iDPD =0 then 1
                   when iDPD in (1,2,3) then 2
                   when iDPD between 4 and 25 then 3
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'DPD'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                   when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                   when iDPD between 4 and 25 then 'в т.ч. 90+'
              end
,[groupSort] = case when iDPD =0 then 1
                   when iDPD in (1,2,3) then 2
                   when iDPD between 4 and 25 then 3
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'DPD'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                   when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                   when iDPD between 4 and 25 then 'в т.ч. 90+'
              end
,[groupSort] = case when iDPD =0 then 1
                   when iDPD in (1,2,3) then 2
                   when iDPD between 4 and 25 then 3
              end
,[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'DPD'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                   when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                   when iDPD between 4 and 25 then 'в т.ч. 90+'
              end
,[groupSort] = case when iDPD =0 then 1
                   when iDPD in (1,2,3) then 2
                   when iDPD between 4 and 25 then 3
              end
,[amount] = cast((reservOD+reservPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all
-----------Банкроты
select
[blockName] = 'БАНКРОТЫ'
,[razdelName] = 'Выдано, млн руб.'
,[groupName] = 'Выдано, млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = 1
,0
from(
select
[amount] = cast((IssueSum)/1000000 as money)
from #rep_result
where iBRPT=1
) l1

union all

select
[blockName] = 'БАНКРОТЫ'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = 'Портфель (ОД+%%), млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = 1
,0
from(
select
[amount] = cast((restOD+restPRC)/1000000 as money)
from #rep_result
where iBRPT=1
) l1

union all

select
[blockName] = 'БАНКРОТЫ'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = 'Портфель (ОД), млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = 1
,0
from(
select
[amount] = cast((restOD)/1000000 as money)
from #rep_result
where iBRPT=1
) l1

union all

select
[blockName] = 'БАНКРОТЫ'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = 'Портфель (%%), млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = 1
,0
from(
select
[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where iBRPT=1
) l1

union all

select
[blockName] = 'БАНКРОТЫ'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = 'Резерв БУ, млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = 1
,0
from(
select
[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
from #rep_result
where iBRPT=1
) l1

union all

select
[blockName] = 'БАНКРОТЫ'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = 'Резерв НУ, млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = 1
,0
from(
select
[amount] = cast((reservOD+reservPRC)/1000000 as money)
from #rep_result
where iBRPT=1
) l1


union all
-----------Займы
select
[blockName] = 'ЗАЙМЫ'
,[razdelName] = 'Выдано, млн руб.'
,[groupName] = 'Выдано, млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = 1
,0
from(
select
[amount] = cast((IssueSum)/1000000 as money)
from #rep_result
where ProductByNGroup=9
) l1


union all

select
[blockName] = 'ЗАЙМЫ'
,[razdelName] = 'Портфель (ОД+%%), млн руб.'
,[groupName] = 'Портфель (ОД+%%), млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = 1
,0
from(
select
[amount] = cast((restOD+restPRC)/1000000 as money)
from #rep_result
where ProductByNGroup=9
) l1

union all

select
[blockName] = 'ЗАЙМЫ'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = 'Портфель (ОД), млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = 1
,0
from(
select
[amount] = cast((restOD)/1000000 as money)
from #rep_result
where ProductByNGroup=9
) l1

union all

select
[blockName] = 'ЗАЙМЫ'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = 'Портфель (%%), млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = 1
,0
from(
select
[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where ProductByNGroup=9
) l1

union all

select
[blockName] = 'ЗАЙМЫ'
,[razdelName] = 'Резерв БУ, млн руб.'
,[groupName] = 'Резерв БУ, млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = 1
,0
from(
select
[amount] = cast((reservBUODSum+reservBUpPrcSum)/1000000 as money)
from #rep_result
where ProductByNGroup=9
) l1

union all

select
[blockName] = 'ЗАЙМЫ'
,[razdelName] = 'Резерв НУ, млн руб.'
,[groupName] = 'Резерв НУ, млн руб.'
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = 1
,0
from(
select
[amount] = cast((reservOD+reservPRC)/1000000 as money)
from #rep_result
where ProductByNGroup=9
) l1

union all
-----------ВЫДАЧИ ВСЕ
select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Требования, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC+restPenia)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Прочие требования, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPenia)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Резерв, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC+reservProch)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Резерв ОД, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Резерв %%, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 7
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservPRC)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): ВСЕ выдачи'
,[razdelName] = 'Резерв проч., млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 8
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservProch)/1000000 as money)
from #rep_result
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all
-----------ВЫДАЧИ 1
select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Требования, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC+restPenia)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null 
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Прочие требования, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPenia)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Резерв, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC+reservProch)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Резерв ОД, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Резерв %%, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 7
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservPRC)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по 28.02.2022'
,[razdelName] = 'Резерв проч., млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 8
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservProch)/1000000 as money)
from #rep_result
where iDI = 1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all
-----------ВЫДАЧИ 2
select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Требования, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC+restPenia)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null 
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Прочие требования, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPenia)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Резерв, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC+reservProch)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Резерв ОД, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Резерв %%, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 7
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservPRC)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): по с 01.03.2022 по 30.09.2022'
,[razdelName] = 'Резерв проч., млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 8
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservProch)/1000000 as money)
from #rep_result
where iDI = 2
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all
-----------ВЫДАЧИ 3
select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Требования, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC+restPenia)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null 
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Прочие требования, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPenia)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Резерв, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC+reservProch)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Резерв ОД, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Резерв %%, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 7
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservPRC)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.10.2022 по 31.10.2022'
,[razdelName] = 'Резерв проч., млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 8
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservProch)/1000000 as money)
from #rep_result
where iDI = 3
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all
-----------ВЫДАЧИ 4
select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Требования, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC+restPenia)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null 
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Прочие требования, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPenia)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Резерв, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC+reservProch)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Резерв ОД, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Резерв %%, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 7
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservPRC)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): с 01.11.2022'
,[razdelName] = 'Резерв проч., млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 8
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservProch)/1000000 as money)
from #rep_result
where iDI = 4
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all
-----------ВЫДАЧИ A2
select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Требования, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 1
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD+restPRC+restPenia)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null 
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Портфель (ОД), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 2
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restOD)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Портфель (%%), млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 3
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPRC)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Прочие требования, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 4
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((restPenia)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Резерв, всего, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 5
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD+reservPRC+reservProch)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Резерв ОД, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 6
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservOD)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort


union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Резерв %%, млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 7
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservPRC)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

union all

select
[blockName] = 'Портфели в разрезе ПДН и периодов выдачи (для НМФК1): А2'
,[razdelName] = 'Резерв проч., млн руб.'
,[groupName] = l1.[groupName]
,[amount] = sum(l1.[amount])
,[orderNum] = 8
,[groupSort] = l1.groupSort
,0
from(
select
[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                   when L =1 then 'в т.ч. ПДН >50% и <=80%'
                   when L =2 then 'в т.ч. ПДН >80%'
                   when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
              end
,[groupSort] = case when L =0 then 1
                   when L =1 then 2
                   when L =2 then 3
                   when L =3 then 4
              end
,[amount] = cast((reservProch)/1000000 as money)
from #rep_result
where isA2=1
) l1
where l1.[groupName] is not null
group by l1.[groupName],l1.groupSort

END

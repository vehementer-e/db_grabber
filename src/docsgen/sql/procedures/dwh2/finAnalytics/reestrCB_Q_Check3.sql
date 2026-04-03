
CREATE PROCEDURE [finAnalytics].[reestrCB_Q_Check3]
    @repMonth date
AS
BEGIN

declare @monthFrom date = dateadd(month,-2,@repMonth)
declare @month2 date = dateadd(month,-1,@repMonth)
declare @monthTo date = @repMonth

Drop Table if Exists #reestr
select
*
into #reestr
from dwh2.finAnalytics.reest_CB_Q a
where (a.monthFrom = @monthFrom and a.monthTo = @monthTo)



delete from dwh2.finAnalytics.reest_CB_Q_check3 where [Месяц начала квартала] = @monthFrom and  [Месяц конца квартала] = @monthTo

----Часть 3 - Внутренние контроли

--p8
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '8'
,[Название проверяемого столбца] = 'ИНН заемщика'
,[Значение проверяемого столбца] = a.clientINN
,[Значение контрольное] = cl.INN
,[Результат проверки] = case when isnull(a.clientINN,'-') != isnull(cl.INN,'-') then 'Ошибка' else 'Ok' end
,[Примечание] = null
,[Примечание2] = null
from #reestr a
left join dwh2.finAnalytics.credClients cl on a.dogNum =cl.dogNum
) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')


--p12

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '12'
,[Название проверяемого столбца] = 'Онлайн / оффлайн'
,[Значение проверяемого столбца] = a.isOnline
,[Значение контрольное] = b.saleType
,[Результат проверки] = case when upper(isnull(a.isOnline,'-')) != upper(isnull(b.saleType,'-')) then 'Ошибка' else 'Ok' end
,[Примечание] = null
,[Примечание2] = null
from #reestr a
left join (
select
b.dogNum
,saleType = case when b.saleType='Дистанционный' then 'Оффлайн' else b.saleType end
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
) b on a.dogNum=b.dogNum and b.rn=1
) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p15

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '15'
,[Название проверяемого столбца] = 'Субъект МСП на последнюю отчетную дату'
,[Значение проверяемого столбца] = a.isMSPRepDate
,[Значение контрольное] = b.isMSPbyRepDate
,[Результат проверки] = case when upper(isnull(a.isMSPRepDate,'Нет')) != upper(isnull(b.isMSPbyRepDate,'Нет')) then 'Ошибка' else 'Ok' end
,[Примечание] = null
,[Примечание2] = null
from #reestr a
left join (
select
b.dogNum
,[isMSPbyRepDate]
,[isMSPbyDogDate]
,[isZaemshik]
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from PBR_MONTHLY b
where b.[isZaemshik] != 'ФЛ' and b.REPMONTH = @repMonth
) b on a.[dogNum]=b.dogNum and b.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p16

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '16'
,[Название проверяемого столбца] = 'Субъект МСП на дату заключения договора'
,[Значение проверяемого столбца] = a.isMSPDogDate
,[Значение контрольное] = b.isMSPbyDogDate
,[Результат проверки] = case when upper(isnull(a.isMSPDogDate,'Нет')) != upper(isnull(b.isMSPbyDogDate,'Нет')) then 'Ошибка' else 'Ok' end
,[Примечание] = null
,[Примечание2] = null

from #reestr a
left join (
select
b.dogNum
,[isMSPbyRepDate]
,[isMSPbyDogDate]
,[isZaemshik]
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from PBR_MONTHLY b
where b.[isZaemshik] != 'ФЛ'
) b on a.[dogNum]=b.dogNum and b.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p17

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '17'
,[Название проверяемого столбца] = 'Территория выдачи'
,[Значение проверяемого столбца] = a.saleRegion
,[Значение контрольное] = case when pbr.saleType = 'Онлайн' then isnull(cl.regionReg,'-') else isnull(pbr.salesRegion,'-')/*isnull(b.region,'-')*/ end
,[Результат проверки] = case when 
							case when replace(a.saleRegion,' г','')='Саха (Якутия) Респ' then 'Саха /Якутия/ Респ' 
								 when replace(a.saleRegion,' г','')='Кемеровская область - Кузбасс обл' then 'Кемеровская обл' 
							else replace(a.saleRegion,' г','') end
						!= 
						case when pbr.saleType = 'Онлайн' then isnull(replace(cl.regionReg,' г',''),'-') else isnull(replace(pbr.salesRegion,' г',''),'-')/*isnull(b.region,'-')*/ end
						and case when pbr.saleType = 'Онлайн' then isnull(replace(cl.regionReg,' г',''),'-') else isnull(replace(pbr.salesRegion,' г',''),'-')/*isnull(b.region,'-')*/ end != '-' 
						then 'Ошибка' else 'Ok' end
,[Примечание] = pbr.saleType
,[Примечание2] = a.clientRegionReg
from #reestr a
left join dwh2.finAnalytics.credClients cl on a.dogNum=cl.dogNum
left join (
select
a.dogNum
,saleType = case when a.saleType='Дистанционный' then 'Оффлайн' else a.saleType end
,a.branch
,a.salesRegion
,rn = ROW_NUMBER() over (partition by a.dogNum order by a.repmonth desc)
from dwh2.finAnalytics.PBR_MONTHLY a
--where a.dogNum='23052520949750'
) pbr on a.dogNum=pbr.dogNum and pbr.rn=1

where pbr.saleType = 'Онлайн'

--left join (
--SELECT 
--distinct
--[branch]
--,[region]
--  FROM [dwh2].[finAnalytics].[CB_branchAddress]
--) b on pbr.branch=b.branch

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p78

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание] ,[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '78'
,[Название проверяемого столбца] = 'ПДН на последний месяц квартала'
,[Значение проверяемого столбца] = case when upper(a.PDN3)=upper('не рассчитывался') then 0 else cast(replace(isnull(a.PDN3,0),',','.') as float) end
,[Значение контрольное] = isnull(b.[PDNOnRepDate],0)*100
,[Результат проверки] = case when (
							case when upper(a.PDN3)=upper('не рассчитывался') then 0 
							else round(cast(replace(isnull(a.PDN3,0),',','.') as float),1) 
							end) 
							!= 
							round(isnull(b.[PDNOnRepDate],0)*100,1) 
						then 'Ошибка' else 'Ok' end
,[Примечание] = null
,[Примечание2] = null
from #reestr a
left join dwh2.finAnalytics.credClients cl on a.dogNum=cl.dogNum
left join dwh2.[finAnalytics].[PBR_MONTHLY] b on b.repmonth = @monthTo  and a.dogNum=b.dogNum

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p79

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '79'
,[Название проверяемого столбца] = 'ПДН на момент выдачи кредита (займа), %'
,[Значение проверяемого столбца] = case when upper(a.PDNSaleDate)=upper('не рассчитывался') then 0 else cast(replace(isnull(a.PDNSaleDate,0),',','.') as float) end
,[Значение контрольное] = isnull(b.[PDNOnSaleDate],0)*100
,[Результат проверки] = case when (case when upper(a.PDNSaleDate)=upper('не рассчитывался') then 0 
						else round(cast(replace(isnull(a.PDNSaleDate,0),',','.') as float),1) end) 
						!= round(isnull(b.[PDNOnSaleDate],0)*100,1) 
						then 'Ошибка' else 'Ok' end
,[Примечание] = null
,[Примечание2] = null

from #reestr a
left join dwh2.finAnalytics.credClients cl on a.dogNum=cl.dogNum
left join dwh2.[finAnalytics].[PBR_MONTHLY] b on b.repmonth = @monthTo  and a.dogNum=b.dogNum

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p45

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '45'
,[Название проверяемого столбца] = 'Заем обеспечен залогом автомототранспортного средства'
,[Значение проверяемого столбца] = a.isObespechAuto
,[Значение контрольное] = case 
                    when pbr.[isDogPoruch]='Залог Автомототранспортного средства' and (pbr.[isObespechZaym] is null or pbr.[isObespechZaym]='Нет') then 'да'
                    when pbr.[isDogPoruch]='Залог Автомототранспортного средства' and pbr.[isObespechZaym]='Да' and pbr.dogStatus = 'Действует' then 'да и соответствует'
					when pbr.[isDogPoruch]='Залог Автомототранспортного средства' and pbr.[isObespechZaym]='Да' and pbr.dogStatus = 'Закрыт' then 'да'
                    else null end
,[Результат проверки] = case when isnull(a.isObespechAuto,'-') 
						!= case 
                    when pbr.[isDogPoruch]='Залог Автомототранспортного средства' and (pbr.[isObespechZaym] is null or pbr.[isObespechZaym]='Нет') then 'да'
                    when pbr.[isDogPoruch]='Залог Автомототранспортного средства' and pbr.[isObespechZaym]='Да' and pbr.dogStatus = 'Действует' then 'да и соответствует'
					when pbr.[isDogPoruch]='Залог Автомототранспортного средства' and pbr.[isObespechZaym]='Да' and pbr.dogStatus = 'Закрыт' then 'да'
                    else null end
						then 'Ошибка' else 'Ok' end
, [Примечание] = concat('ПБР признак обеспечвенности: ',pbr.[isObespechZaym])
,[Примечание2] = pbr.dogStatus

from #reestr a
left join (
select
b.dogNum
,b.isObespechZaym
,b.isDogPoruch
,b.dogStatus
,b.CloseDate
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth <=@monthTo
) pbr on a.dogNum=pbr.dogNum and pbr.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p46

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
,[Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '46'
,[Название проверяемого столбца] = 'Заем обеспечен иным залогом '
,[Значение проверяемого столбца] = a.isObespechOther
,[Значение контрольное] = case 
                    when pbr.[isDogPoruch]='Залог самоходных машин' and pbr.[isObespechZaym]='Да' then 'соответствует'
                    else '-' end
,[Результат проверки] = case when isnull(a.isObespechOther,'-') 
						!=  case 
                    when pbr.[isDogPoruch]='Залог самоходных машин' and pbr.[isObespechZaym]='Да' then 'соответствует'
                    else '-' end
						then 'Ошибка' else 'Ok' end
, [Примечание] = concat('ПБР признак обеспечвенности: ',pbr.[isObespechZaym])
,[Примечание2] = null

from #reestr a
left join (
select
b.dogNum
,b.isObespechZaym
,b.isDogPoruch
,b.dogStatus
,b.CloseDate
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from PBR_MONTHLY b
Where b.repmonth <=@monthTo
) pbr on a.[dogNum]=pbr.dogNum and pbr.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p47

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '47'
,[Название проверяемого столбца] = 'Вид иного залога'
,[Значение проверяемого столбца] = a.obespechOtherType
,[Значение контрольное] = case 
                    when pbr.[isDogPoruch]='Залог самоходных машин' and pbr.[isObespechZaym]='Да' then 'самоходная машина'
                    else '-' end
,[Результат проверки] = case when isnull(a.obespechOtherType,'-') 
						!=  case 
                    when pbr.[isDogPoruch]='Залог самоходных машин' and pbr.[isObespechZaym]='Да' then 'самоходная машина'
                    else '-' end
						then 'Ошибка' else 'Ok' end
, [Примечание] = concat('ПБР признак обеспечвенности: ',pbr.[isObespechZaym])
,[Примечание2] = null

from #reestr a
left join (
select
b.dogNum
,b.isObespechZaym
,b.isDogPoruch
,b.dogStatus
,b.CloseDate
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from PBR_MONTHLY b
Where b.repmonth <= @monthTo
) pbr on a.[dogNum]=pbr.dogNum and pbr.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p59

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '59'
,[Название проверяемого столбца] = 'Заемщик признан банкротом или находится в процессе ликвидации'
,[Значение проверяемого столбца] = a.isCredBankrot
,[Значение контрольное] = bnkrupt.Дата
,[Результат проверки] = case when isnull(a.isCredBankrot,cast(getdate() as date)) 
								!= isnull(bnkrupt.Дата,cast(getdate() as date))
						then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (
select
client
,dogNum
,rn = ROW_NUMBER() over (Partition by dogNum order by repmonth desc)
from dwh2.finAnalytics.PBR_MONTHLY
) b on a.dogNum=b.dogNum and b.rn=1


left join (
        select --top 1

        [Дата] = cast(dateadd(year,-2000,a.Дата) as date)
        ,[Заемщик] = b.Наименование
        ---Признак исключения для проброски в ПБР
        ,[Исключить] = case when a.Номер in ('00БП-0266','00БП-0302','00БП-0496','00БП-0637','00БП-0733') then 1 else 0 end
		,[ДатаРешения] = dateadd(year,-2000,a.ДатаРешения)

        ---Считаем дубли и берем максимальное по дате в кореляции с отчетной датой
        ,ROW_NUMBER() over (Partition by b.Наименование order by a.Дата desc) rn
		
		--select * from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a

        from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
        left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
        where 1=1
        and a.ПометкаУдаления =  0x00
        and a.Проведен=0x01
        and cast(dateadd(year,-2000,a.Дата) as date) <=EOMONTH(@monthTo)
        ) bnkrupt on b.Client=bnkrupt.[Заемщик] and bnkrupt.rn=1 and bnkrupt.Исключить=0


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p64

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '64'
,[Название проверяемого столбца] = 'Признак реструктуризации / рефинансирования'
,[Значение проверяемого столбца] = a.isCredRestrukt
,[Значение контрольное] = pbr.[isRestruk]
,[Результат проверки] = case when a.isCredRestrukt is not null and upper(pbr.[isRestruk]) = upper('Нет') then 'Ошибка' 
							 when a.isCredRestrukt is null and upper(pbr.[isRestruk]) = upper('Да') then 'Ошибка' 
								else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (
select
b.dogNum
,b.isObespechZaym
,b.isDogPoruch
,b.dogStatus
,b.CloseDate
,b.isRestruk
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth <=@monthTo
) pbr on a.dogNum=pbr.dogNum and pbr.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p102

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '102'
,[Название проверяемого столбца] = 'Длительность просроченной задолженности'
,[Значение проверяемого столбца] = isnull(a.prosDays1,0)
,[Значение контрольное] = isnull(nu.[102],0)
,[Результат проверки] = case when isnull(a.prosDays1,0)
							!=
							 isnull(nu.[102],0)
							 and nu.[Rest102] >0
							 then 'Ошибка' else 'Ok' end
, [Примечание] =concat('Остатки ОД+%%+Пеня: ', nu.[Rest102])
,[Примечание2] = null

from #reestr a
left join (
select
l1.dogNum
,[102] = MAX(l1.[102])
,[103] = MAX(l1.[103])
,[104] = MAX(l1.[104])

,[Rest102] = MAX(l1.[Rest102])
,[Rest103] = MAX(l1.[Rest103])
,[Rest104] = MAX(l1.[Rest104])

from(
select 
dogNum
,[102] = case when REPMONTH=@monthFrom then allPros else null end
,[103] = case when REPMONTH=dateadd(MONth,1,@monthFrom) then allPros else null end
,[104] = case when REPMONTH=@monthTo then allPros else null end

,[Rest102] = case when REPMONTH=@monthFrom then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end
,[Rest103] = case when REPMONTH=dateadd(MONth,1,@monthFrom) then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end
,[Rest104] = case when REPMONTH=@monthTo then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end

from dwh2.finAnalytics.Reserv_NU rnu 
where rnu.REPMONTH between @monthFrom and @monthTo
) l1
group by l1.dogNum
) nu on a.dogNum=nu.dogNum

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p103

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '103'
,[Название проверяемого столбца] = 'Длительность просроченной задолженности'
,[Значение проверяемого столбца] = isnull(a.prosDays2,0)
,[Значение контрольное] = isnull(nu.[103],0)
,[Результат проверки] = case when isnull(a.prosDays2,0)
							!=
							 isnull(nu.[103],0)
							 and nu.[Rest103] >0
							 then 'Ошибка' else 'Ok' end
, [Примечание] =concat('Остатки ОД+%%+Пеня: ', nu.[Rest103])
,[Примечание2] = null 

from #reestr a
left join (
select
l1.dogNum
,[102] = MAX(l1.[102])
,[103] = MAX(l1.[103])
,[104] = MAX(l1.[104])

,[Rest102] = MAX(l1.[Rest102])
,[Rest103] = MAX(l1.[Rest103])
,[Rest104] = MAX(l1.[Rest104])

from(
select 
dogNum
,[102] = case when REPMONTH=@monthFrom then allPros else null end
,[103] = case when REPMONTH=dateadd(MONth,1,@monthFrom) then allPros else null end
,[104] = case when REPMONTH=@monthTo then allPros else null end

,[Rest102] = case when REPMONTH=@monthFrom then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end
,[Rest103] = case when REPMONTH=dateadd(MONth,1,@monthFrom) then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end
,[Rest104] = case when REPMONTH=@monthTo then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end

from dwh2.finAnalytics.Reserv_NU rnu 
where rnu.REPMONTH between @monthFrom and @monthTo
) l1
group by l1.dogNum
) nu on a.dogNum=nu.dogNum

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p104

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '104'
,[Название проверяемого столбца] = 'Длительность просроченной задолженности'
,[Значение проверяемого столбца] = isnull(a.prosDays3,0)
,[Значение контрольное] = isnull(nu.[104],0)
,[Результат проверки] = case when isnull(a.prosDays3,0)
							!=
							 isnull(nu.[104],0)
							 and nu.[Rest104] >0
							 then 'Ошибка' else 'Ok' end
, [Примечание] =concat('Остатки ОД+%%+Пеня: ', nu.[Rest104])
,[Примечание2] = null

from #reestr a
left join (
select
l1.dogNum
,[102] = MAX(l1.[102])
,[103] = MAX(l1.[103])
,[104] = MAX(l1.[104])

,[Rest102] = MAX(l1.[Rest102])
,[Rest103] = MAX(l1.[Rest103])
,[Rest104] = MAX(l1.[Rest104])

from(
select 
dogNum
,[102] = case when REPMONTH=@monthFrom then allPros else null end
,[103] = case when REPMONTH=dateadd(MONth,1,@monthFrom) then allPros else null end
,[104] = case when REPMONTH=@monthTo then allPros else null end

,[Rest102] = case when REPMONTH=@monthFrom then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end
,[Rest103] = case when REPMONTH=dateadd(MONth,1,@monthFrom) then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end
,[Rest104] = case when REPMONTH=@monthTo then ISNULL(restOD,0)+ISNULL(restPRC,0)+ISNULL(restPenia,0) else 0 end

from dwh2.finAnalytics.Reserv_NU rnu 
where rnu.REPMONTH between @monthFrom and @monthTo
) l1
group by l1.dogNum
) nu on a.dogNum=nu.dogNum

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')


--p30

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '30'
,[Название проверяемого столбца] = 'Объем денежных средств, предоставленных по договору займа за квартал, руб.'
,[Значение проверяемого столбца] = a.dogSumQ
,[Значение контрольное] = pbr.dogSum
,[Результат проверки] = case when isnull(a.dogSumQ,0) != isnull(pbr.dogSum,0) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (
select
l1.dogNum
,[dogSum] = sum([dogSum])
from(
select
b.dogNum
,[dogSum] = isnull(b.[dogSum],0)
,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth between @monthFrom and @monthTo
and b.saleDate between @monthFrom and EOMONTH(@monthTo)
) l1
where l1.rn=1
group by l1.dogNum

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1

where a.dogSale between @monthFrom and EOMONTH(@monthTo)

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p93
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '93'
,[Название проверяемого столбца] = 'Задолженность (включая просроченную) по основному долгу, руб.'
,[Значение проверяемого столбца] = a.restOD1
,[Значение контрольное] = pbr.zadolgOD
,[Результат проверки] = case when isnull(a.restOD1,0) != isnull(pbr.zadolgOD,0) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[zadolgOD] = isnull(b.[zadolgOD],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =@monthFrom

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p94

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '94'
,[Название проверяемого столбца] = 'Задолженность (включая просроченную) по основному долгу, руб.'
,[Значение проверяемого столбца] = a.restOD2
,[Значение контрольное] = pbr.zadolgOD
,[Результат проверки] = case when isnull(a.restOD2,0) != isnull(pbr.zadolgOD,0) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[zadolgOD] = isnull(b.[zadolgOD],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =dateadd(month,-1,@repMonth)

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')


--p95

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '95'
,[Название проверяемого столбца] = 'Задолженность (включая просроченную) по основному долгу, руб.'
,[Значение проверяемого столбца] = a.restOD3
,[Значение контрольное] = pbr.zadolgOD
,[Результат проверки] = case when isnull(a.restOD3,0) != isnull(pbr.zadolgOD,0) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[zadolgOD] = isnull(b.[zadolgOD],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =@monthTo

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1

) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p96

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '96'
,[Название проверяемого столбца] = 'Задолженность (включая просроченную) по процентам и иным платежам, руб.'
,[Значение проверяемого столбца] = a.restPRC1
,[Значение контрольное] = pbr.zadolgPrc
,[Результат проверки] = case when cast(isnull(a.restPRC1,0) as money) != cast(isnull(pbr.zadolgPrc,0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[zadolgPrc] = isnull(b.[zadolgPrc],0) + isnull(b.[penyaSum],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =@monthFrom

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p97

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '97'
,[Название проверяемого столбца] = 'Задолженность (включая просроченную) по процентам и иным платежам, руб.'
,[Значение проверяемого столбца] = a.restPRC2
,[Значение контрольное] = pbr.zadolgPrc
,[Результат проверки] = case when cast(isnull(a.restPRC2,0) as money) != cast(isnull(pbr.zadolgPrc,0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[zadolgPrc] = isnull(b.[zadolgPrc],0) + isnull(b.[penyaSum],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =dateadd(month,-1,@repMonth)

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p98

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '98'
,[Название проверяемого столбца] = 'Задолженность (включая просроченную) по процентам и иным платежам, руб.'
,[Значение проверяемого столбца] = a.restPRC3
,[Значение контрольное] = pbr.zadolgPrc
,[Результат проверки] = case when cast(isnull(a.restPRC3,0) as money) != cast(isnull(pbr.zadolgPrc,0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[zadolgPrc] = isnull(b.[zadolgPrc],0) + isnull(b.[penyaSum],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =@monthTo

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p112

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '112'
,[Название проверяемого столбца] = 'Сформированный РВПЗ (суммарно по ОД, процентам и иным платежам)'
,[Значение проверяемого столбца] = a.reservOD1
,[Значение контрольное] = pbr.reservOD
,[Результат проверки] = case when cast(isnull(a.reservOD1,0) as money) != cast(isnull(pbr.reservOD,0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[reservOD] = isnull(b.[reservOD],0) + isnull(b.[reservPRC],0) + isnull(b.[reservProchSumNU],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =@monthFrom

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p113

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '113'
,[Название проверяемого столбца] = 'Сформированный РВПЗ (суммарно по ОД, процентам и иным платежам)'
,[Значение проверяемого столбца] = a.reservOD2
,[Значение контрольное] = pbr.reservOD
,[Результат проверки] = case when cast(isnull(a.reservOD2,0) as money) != cast(isnull(pbr.reservOD,0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[reservOD] = isnull(b.[reservOD],0) + isnull(b.[reservPRC],0) + isnull(b.[reservProchSumNU],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth =dateadd(month,-1,@repMonth)

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p114

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '114'
,[Название проверяемого столбца] = 'Сформированный РВПЗ (суммарно по ОД, процентам и иным платежам)'
,[Значение проверяемого столбца] = a.reservOD3
,[Значение контрольное] = pbr.reservOD
,[Результат проверки] = case when cast(isnull(a.reservOD3,0) as money) != cast(isnull(pbr.reservOD,0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[reservOD] = isnull(b.[reservOD],0) + isnull(b.[reservPRC],0) + isnull(b.[reservProchSumNU],0)
--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth = @monthTo

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')

--p115

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '115'
,[Название проверяемого столбца] = 'Размер резерва под обесценение на дату, руб.'
,[Значение проверяемого столбца] = a.reservPriseLess
,[Значение контрольное] = pbr.reserv
,[Результат проверки] = case when abs(round(isnull(a.reservPriseLess,0),0) - round(isnull(pbr.reserv,0),0)) >10 then 'Ошибка' else 'Ok' end
,[Примечание] = null
,[Примечание2] = null

from #reestr a
left join (

select
b.dogNum
,[reserv] = case when isnull(b.[penyaSum],0) + isnull(b.[gosposhlSum],0) = 0
				then isnull(b.[reservBUODSum],0) + isnull(b.[reservBUpPrcSum],0)
				else  isnull(b.[reservBUODSum],0) 
					+ isnull(b.[reservBUpPrcSum],0) 
					+ (
						isnull(b.[penyaSum],0)
						* [reservBUPenyaSum] 
						/ (
							isnull(b.[penyaSum],0) 
							+ isnull(b.[gosposhlSum],0)
							)
							)
				end

--,rn = ROW_NUMBER() over (Partition by b.dogNum order by b.repmonth desc)
from finAnalytics.PBR_MONTHLY b
Where b.repmonth = @monthTo

) pbr on a.dogNum=pbr.dogNum --and pbr.rn=1


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')


--p106

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '106'
,[Название проверяемого столбца] = 'Объем средств, направленных на погашение задолженности по основному долгу'
,[Значение проверяемого столбца] = a.credPayOD1
,[Значение контрольное] = prov.[Сумма БУ]
,[Результат проверки] = case when cast(isnull(a.credPayOD1,0) as money) != cast(isnull(prov.[Сумма БУ],0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null--'Не учтен п 2.38.2 ф840'
,[Примечание2] = null

from #reestr a
left join (

SELECT 
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = sum(a.Сумма) --v2


from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
--left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
(Kt.Код in ('48801','48701','49401') and Dt.Код='47422')
or
(Dt.Код in ('20501','47422') and Kt.Код in ('48501'))
or
(Kt.Код in ('48801','48701','49401') and substring(Dt.Код,1,3) ='612'
and a.СубконтоDt3_Ссылка in (
0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание с Января 2025
) 
)
)--v2

group by crkt.Номер
) prov on a.dogNum=prov.[Номер договора КТ]


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')



--p107

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '107'
,[Название проверяемого столбца] = 'Объем средств, направленных на погашение задолженности по основному долгу'
,[Значение проверяемого столбца] = a.credPayOD2
,[Значение контрольное] = prov.[Сумма БУ]
,[Результат проверки] = case when cast(isnull(a.credPayOD2,0) as money) != cast(isnull(prov.[Сумма БУ],0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null --'Не учтен п 2.38.2 ф840'
,[Примечание2] = null

from #reestr a
left join (

SELECT 
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = sum(a.Сумма) --v2


from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
--left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,dateadd(month,-1,@repMonth)) and dateadd(year,2000,EOMONTH(dateadd(month,-1,@repMonth)))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
(Kt.Код in ('48801','48701','49401') and Dt.Код='47422')
or
(Dt.Код in ('20501','47422') and Kt.Код in ('48501'))
or
(Kt.Код in ('48801','48701','49401') and substring(Dt.Код,1,3) ='612'
and a.СубконтоDt3_Ссылка in (
0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание с Января 2025
) 
)
)--v2

group by crkt.Номер
) prov on a.dogNum=prov.[Номер договора КТ]


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')


--p108

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '108'
,[Название проверяемого столбца] = 'Объем средств, направленных на погашение задолженности по основному долгу'
,[Значение проверяемого столбца] = a.credPayOD3
,[Значение контрольное] = prov.[Сумма БУ]
,[Результат проверки] = case when cast(isnull(a.credPayOD3,0) as money) != cast(isnull(prov.[Сумма БУ],0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null--'Не учтен п 2.38.2 ф840'
,[Примечание2] = null

from #reestr a
left join (

SELECT 
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = sum(a.Сумма) --v2


from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
--left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
(Kt.Код in ('48801','48701','49401') and Dt.Код='47422')
or
(Dt.Код in ('20501','47422') and Kt.Код in ('48501'))
or
(Kt.Код in ('48801','48701','49401') and substring(Dt.Код,1,3) ='612'
and a.СубконтоDt3_Ссылка in (
0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание с Января 2025
) 
)
)--v2

group by crkt.Номер
) prov on a.dogNum=prov.[Номер договора КТ]


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')



--p109

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '109'
,[Название проверяемого столбца] = 'Объем средств, направленных на погашение задолженности по процентам и иным платежам'
,[Значение проверяемого столбца] = a.credPayPRC1
,[Значение контрольное] = prov.[Сумма БУ]
,[Результат проверки] = case when cast(isnull(a.credPayPRC1,0) as money) != cast(isnull(prov.[Сумма БУ],0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null--'Не учтен п 2.38.2 ф840'
,[Примечание2] = null

from #reestr a
left join (

/*select
[Номер договора КТ]
,[Сумма БУ]  = sum([Сумма БУ] )
from(
SELECT 
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
	(Dt.Код in ('20501','47422') and Kt.Код in ('48501'))
	or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    )
	or
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
    )
    )
	)

	union all



SELECT 
[Номер договора КТ] = isnull(crdt.Номер,spKTp.НомерДоговора)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
--left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and ((
	(Kt.Код in ('60323') and Dt.Код ='47422')
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    ))
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени
								/*
								not in (
                                0xA2EB0050568397CF11EDB7B4A7CAC846 --Госпошлина
                                ,0xA3000050568397CF11EEC6735BC498A2 --Проценты
                                ,0xA3040050568397CF11EF3A45E64722DE --Проценты
                                ,0xA3040050568397CF11EF543103C0F623 --Мошенники
                                )
								*/
								)
     --v2
	 or
    (Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
) l2

group by l2.[Номер договора КТ]*/


select
[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
--2.8 + 2.18
select
[Пункт] = '2.8+2.18'
,[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
    )
	or
	
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) --Полное списание
	and sposobKT.Имя in ('Посреднический','Прямой')
    )
    )
) l1

group by [Номер договора КТ] 

union all

--2.9+2.19
select
'2.9+2.19'
,[Номер договора КТ]
,sum([Сумма БУ])
from(

SELECT 
[Номер договора КТ] = isnull(isnull(crkt.Номер,crdt.Номер),dog.Номер)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dog on a.СубконтоCt2_Ссылка=dog.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
/*
and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
    )
) l1

group by [Номер договора КТ]

union all

--2.38.3
select
'2.38.3'
,[Номер договора КТ]
,sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = a.Сумма
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and Kt.Код in ('48502') and Dt.Код in ('48509')
	--[СчетДтКод] in ('48509') and [СчетКтКод] in ('48502')
    
	
) l1
group by [Номер договора КТ]
) l2

group by [Номер договора КТ]


) prov on a.dogNum=prov.[Номер договора КТ]


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')


--p110

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '110'
,[Название проверяемого столбца] = 'Объем средств, направленных на погашение задолженности по процентам и иным платежам'
,[Значение проверяемого столбца] = a.credPayPRC2
,[Значение контрольное] = prov.[Сумма БУ]
,[Результат проверки] = case when cast(isnull(a.credPayPRC2,0) as money) != cast(isnull(prov.[Сумма БУ],0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null--'Не учтен п 2.38.2 ф840'
,[Примечание2] = null

from #reestr a
left join (
/*
select
[Номер договора КТ]
,[Сумма БУ]  = sum([Сумма БУ] )
from(
SELECT 
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,dateadd(month,-1,@repMonth)) and dateadd(year,2000,EOMONTH(dateadd(month,-1,@repMonth)))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
	(Dt.Код in ('20501','47422') and Kt.Код in ('48501'))
	or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    )
	or
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
    )
    )
	)

	union all



SELECT 
[Номер договора КТ] = isnull(crdt.Номер,spKTp.НомерДоговора)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
--left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,dateadd(month,-1,@repMonth)) and dateadd(year,2000,EOMONTH(dateadd(month,-1,@repMonth)))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and ((
	(Kt.Код in ('60323') and Dt.Код ='47422')
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    ))
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени
								/*
								not in (
                                0xA2EB0050568397CF11EDB7B4A7CAC846 --Госпошлина
                                ,0xA3000050568397CF11EEC6735BC498A2 --Проценты
                                ,0xA3040050568397CF11EF3A45E64722DE --Проценты
                                ,0xA3040050568397CF11EF543103C0F623 --Мошенники
                                )
								*/
								)
     --v2
	 or
    (Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
) l2

group by l2.[Номер договора КТ]
*/
select
[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
--2.8 + 2.18
select
[Пункт] = '2.8+2.18'
,[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
--where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
where cast(a.Период as date) between dateadd(year,2000,dateadd(month,-1,@repMonth)) and dateadd(year,2000,EOMONTH(dateadd(month,-1,@repMonth)))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
    )
	or
	
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) --Полное списание
	and sposobKT.Имя in ('Посреднический','Прямой')
    )
    )
) l1

group by [Номер договора КТ] 

union all

--2.9+2.19
select
'2.9+2.19'
,[Номер договора КТ]
,sum([Сумма БУ])
from(

SELECT 
[Номер договора КТ] = isnull(isnull(crkt.Номер,crdt.Номер),dog.Номер)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dog on a.СубконтоCt2_Ссылка=dog.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
--where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
where cast(a.Период as date) between dateadd(year,2000,dateadd(month,-1,@repMonth)) and dateadd(year,2000,EOMONTH(dateadd(month,-1,@repMonth)))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
/*
and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
    )
) l1

group by [Номер договора КТ]

union all

--2.38.3
select
'2.38.3'
,[Номер договора КТ]
,sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = a.Сумма
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
--where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
where cast(a.Период as date) between dateadd(year,2000,dateadd(month,-1,@repMonth)) and dateadd(year,2000,EOMONTH(dateadd(month,-1,@repMonth)))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and Kt.Код in ('48502') and Dt.Код in ('48509')
	--[СчетДтКод] in ('48509') and [СчетКтКод] in ('48502')
    
	
) l1
group by [Номер договора КТ]
) l2

group by [Номер договора КТ]
) prov on a.dogNum=prov.[Номер договора КТ]


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')


--p111

INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки] , [Примечание],[Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное]
,[Результат проверки]
, [Примечание]
,[Примечание2]

from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = a.client
,[Паспортные данные заемщика] = a.clientPass
,[Дата рождения заемщика] = a.clientBirthDate
,[Номер договора займа] = a.dogNum
,[Дата закрыт] = a.dogCloseDate
,[Номер проверяемого столбца] = '111'
,[Название проверяемого столбца] = 'Объем средств, направленных на погашение задолженности по процентам и иным платежам'
,[Значение проверяемого столбца] = a.credPayPRC3
,[Значение контрольное] = prov.[Сумма БУ]
,[Результат проверки] = case when cast(isnull(a.credPayPRC3,0) as money) != cast(isnull(prov.[Сумма БУ],0) as money) then 'Ошибка' else 'Ok' end
, [Примечание] = null--'Не учтен п 2.38.2 ф840'
,[Примечание2] = null

from #reestr a
left join (
/*
select
[Номер договора КТ]
,[Сумма БУ]  = sum([Сумма БУ] )
from(
SELECT 
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
	(Dt.Код in ('20501','47422') and Kt.Код in ('48501'))
	or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    )
	or
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
    )
    )
	)

	union all



SELECT 
[Номер договора КТ] = isnull(crdt.Номер,spKTp.НомерДоговора)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
--left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка

where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and ((
	(Kt.Код in ('60323') and Dt.Код ='47422')
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    ))
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени
								/*
								not in (
                                0xA2EB0050568397CF11EDB7B4A7CAC846 --Госпошлина
                                ,0xA3000050568397CF11EEC6735BC498A2 --Проценты
                                ,0xA3040050568397CF11EF3A45E64722DE --Проценты
                                ,0xA3040050568397CF11EF543103C0F623 --Мошенники
                                )
								*/
								)
     --v2
	 or
    (Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
) l2

group by l2.[Номер договора КТ]
*/
select
[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
--2.8 + 2.18
select
[Пункт] = '2.8+2.18'
,[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
--where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
    )
	or
	
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) --Полное списание
	and sposobKT.Имя in ('Посреднический','Прямой')
    )
    )
) l1

group by [Номер договора КТ] 

union all

--2.9+2.19
select
'2.9+2.19'
,[Номер договора КТ]
,sum([Сумма БУ])
from(

SELECT 
[Номер договора КТ] = isnull(isnull(crkt.Номер,crdt.Номер),dog.Номер)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dog on a.СубконтоCt2_Ссылка=dog.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
--where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
/*
and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
    )
) l1

group by [Номер договора КТ]

union all

--2.38.3
select
'2.38.3'
,[Номер договора КТ]
,sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = a.Сумма
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
--where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and Kt.Код in ('48502') and Dt.Код in ('48509')
	--[СчетДтКод] in ('48509') and [СчетКтКод] in ('48502')
    
	
) l1
group by [Номер договора КТ]
) l2

group by [Номер договора КТ]
) prov on a.dogNum=prov.[Номер договора КТ]


) l1

where 1=1
and upper(l1.[Результат проверки]) = upper('Ошибка')



Drop Table if Exists #AReestr
select
aCategory
,SumBU = sum(SumBU)

into #AReestr

from(
select
aCategory = case 
			when aCategory like 'А1%' then 'А1'
			when aCategory like 'А2%' then 'А2'
			when aCategory like 'А3%' then 'А3'
			when aCategory like 'А4%' then 'А4'
			when aCategory like 'А5%' then 'А5'
			when aCategory like 'А6%' then 'А6'
		else '-' end
,SumBU = isnull(restOD1,0) + isnull(restPRC1,0)
from #reestr
union all
select
aCategory = case 
			when aCategory like '%_А1' then 'А1'
			when aCategory like '%_А2' then 'А2'
			when aCategory like '%_А3' then 'А3'
			when aCategory like '%_А4' then 'А4'
			when aCategory like '%_А5' then 'А5'
			when aCategory like '%_А6' then 'А6'
		else '-' end
,SumBU = isnull(restOD1,0) + isnull(restPRC1,0)
from #reestr
) l1
where l1.aCategory != '-'
group by l1.aCategory


Drop Table if Exists #A840
select
punkt
,groupName
,sumBU = sum(sumBU )

into #A840

from(
select
punkt
,groupName = case 
				when punkt='3.1.1' then 'А1'
				when punkt='3.1.2' then 'А2'
				when punkt='3.1.3' then 'А3'
				when punkt='3.1.4' then 'А4'
				when punkt='3.1.5' then 'А5'
				when punkt='3.1.6' then 'А6'
				else '-' end

,sumBU = isnull(value,0)
from dwh2.finAnalytics.rep840_3_detail a
where a.REPMONTH=@monthFrom
and punkt in ('3.1.1','3.1.2','3.1.3','3.1.4','3.1.5')
and pokazatel != 'ИТОГО по Пункту'
and value >0
) l1

group by 
punkt
,groupName

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A1'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А1' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А1')
,[Результат проверки] = null
,[Примечание] = 'Месяц 1'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'


--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A2'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А2' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А2')
,[Результат проверки] = null
,[Примечание] = 'Месяц 1'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'



--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A3'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А3' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А3')
,[Результат проверки] = null
,[Примечание] = 'Месяц 1'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'


--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A4'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А4' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А4')
,[Результат проверки] = null
,[Примечание] = 'Месяц 1'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'


--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A5'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А5' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А5')
,[Результат проверки] = null
,[Примечание] = 'Месяц 1'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'


truncate table #AReestr
INSERT into #AReestr
select
aCategory
,SumBU = sum(SumBU)
from(
select
aCategory = case 
			when aCategory like 'А1%' then 'А1'
			when aCategory like 'А2%' then 'А2'
			when aCategory like 'А3%' then 'А3'
			when aCategory like 'А4%' then 'А4'
			when aCategory like 'А5%' then 'А5'
			when aCategory like 'А6%' then 'А6'
		else '-' end
,SumBU = isnull(restOD2,0) + isnull(restPRC2,0)
from #reestr
union all
select
aCategory = case 
			when aCategory like '%_А1' then 'А1'
			when aCategory like '%_А2' then 'А2'
			when aCategory like '%_А3' then 'А3'
			when aCategory like '%_А4' then 'А4'
			when aCategory like '%_А5' then 'А5'
			when aCategory like '%_А6' then 'А6'
		else '-' end
,SumBU = isnull(restOD2,0) + isnull(restPRC2,0)
from #reestr
) l1
where l1.aCategory != '-'
group by l1.aCategory


TRUNCATE TABLE #A840
INSERT into #A840
select
punkt
,groupName
,sumBU = sum(sumBU )

from(
select
punkt
,groupName = case 
				when punkt='3.1.1' then 'А1'
				when punkt='3.1.2' then 'А2'
				when punkt='3.1.3' then 'А3'
				when punkt='3.1.4' then 'А4'
				when punkt='3.1.5' then 'А5'
				when punkt='3.1.6' then 'А6'
				else '-' end

,sumBU = isnull(value,0)
from dwh2.finAnalytics.rep840_3_detail a
where a.REPMONTH=@month2
and punkt in ('3.1.1','3.1.2','3.1.3','3.1.4','3.1.5')
and pokazatel != 'ИТОГО по Пункту'
and value >0
) l1

group by 
punkt
,groupName



--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A1'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А1' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А1')
,[Результат проверки] = null
,[Примечание] = 'Месяц 2'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A2'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А2' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А2')
,[Результат проверки] = null
,[Примечание] = 'Месяц 2'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A3'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А3' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А3')
,[Результат проверки] = null
,[Примечание] = 'Месяц 2'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A4'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А4' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А4')
,[Результат проверки] = null
,[Примечание] = 'Месяц 2'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A5'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А5' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А5')
,[Результат проверки] = null
,[Примечание] = 'Месяц 2'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

TRUNCATE TABLE #AReestr
INSERT into #AReestr
select
aCategory
,SumBU = sum(SumBU)

from(
select
aCategory = case 
			when aCategory like 'А1%' then 'А1'
			when aCategory like 'А2%' then 'А2'
			when aCategory like 'А3%' then 'А3'
			when aCategory like 'А4%' then 'А4'
			when aCategory like 'А5%' then 'А5'
			when aCategory like 'А6%' then 'А6'
		else '-' end
,SumBU = isnull(restOD3,0) + isnull(restPRC3,0)
from #reestr
union all
select
aCategory = case 
			when aCategory like '%_А1' then 'А1'
			when aCategory like '%_А2' then 'А2'
			when aCategory like '%_А3' then 'А3'
			when aCategory like '%_А4' then 'А4'
			when aCategory like '%_А5' then 'А5'
			when aCategory like '%_А6' then 'А6'
		else '-' end
,SumBU = isnull(restOD3,0) + isnull(restPRC3,0)
from #reestr
) l1
where l1.aCategory != '-'
group by l1.aCategory


TRUNCATE TABLE #A840
INSERT into #A840
select
punkt
,groupName
,sumBU = sum(sumBU )

from(
select
punkt
,groupName = case 
				when punkt='3.1.1' then 'А1'
				when punkt='3.1.2' then 'А2'
				when punkt='3.1.3' then 'А3'
				when punkt='3.1.4' then 'А4'
				when punkt='3.1.5' then 'А5'
				when punkt='3.1.6' then 'А6'
				else '-' end

,sumBU = isnull(value,0)
from dwh2.finAnalytics.rep840_3_detail a
where a.REPMONTH=@monthTo
and punkt in ('3.1.1','3.1.2','3.1.3','3.1.4','3.1.5','3.1.6')
and pokazatel != 'ИТОГО по Пункту'
and value >0
) l1

group by 
punkt
,groupName



--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A1'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А1' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А1')
,[Результат проверки] = null
,[Примечание] = 'Месяц 3'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A2'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А2' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А2')
,[Результат проверки] = null
,[Примечание] = 'Месяц 3'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A3'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А3' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А3')
,[Результат проверки] = null
,[Примечание] = 'Месяц 3'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'

--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A4'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А4' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А4')
,[Результат проверки] = null
,[Примечание] = 'Месяц 3'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'


--p81
INSERT INTO dwh2.finAnalytics.reest_CB_Q_check3
([Месяц начала квартала], [Месяц конца квартала], [ФИО / Наименование заемщика], 
[Паспортные данные заемщика], [Дата рождения заемщика], [Номер договора займа], 
[Дата закрыт], [Номер проверяемого столбца], [Название проверяемого столбца], 
[Значение проверяемого столбца], [Значение контрольное], [Результат проверки], [Примечание], [Примечание2])

select

[Месяц начала квартала]
, [Месяц конца квартала]
,[ФИО / Наименование заемщика]
,[Паспортные данные заемщика]
,[Дата рождения заемщика]
,[Номер договора займа]
,[Дата закрыт]
,[Номер проверяемого столбца]
,[Название проверяемого столбца]
,[Значение проверяемого столбца]
,[Значение контрольное] 
,[Результат проверки]= case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end 
,[Примечание]
, [Примечание2]
from(
select
[Месяц начала квартала] = @monthFrom
, [Месяц конца квартала] = @monthTo
,[ФИО / Наименование заемщика] = '-'
,[Паспортные данные заемщика] = '-'
,[Дата рождения заемщика] = null
,[Номер договора займа] = '-'
,[Дата закрыт] = null
,[Номер проверяемого столбца] = '81'
,[Название проверяемого столбца] = 'A5'
,[Значение проверяемого столбца] = (select str(round(SumBU,0)) from #AReestr where aCategory = 'А5' )
,[Значение контрольное] = (select str(round(sumBU,0)) from #A840 where groupName = 'А5')
,[Результат проверки] = null
,[Примечание] = 'Месяц 3'
,[Примечание2] = null
) l1

where 1=1
and case when round([Значение проверяемого столбца],0) != round([Значение контрольное],0) then 'Ошибка' else 'Ok' end = 'Ошибка'
END


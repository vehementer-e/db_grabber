


CREATE PROCEDURE [finAnalytics].[reestrMSP]

AS
BEGIN

/*Вывести всех клиентов ЮЛ,ИП из кредитного портфеля*/
--select distinct 
--a.Client
--,a.isZaemshik
--,a.INN
--,reestrInDate = convert( date,b.reestrInDate,104)
--,reestrOutDate = convert(date,b.reestrOutDate,104)
--,loadDate = b.loadDate--convert(date,b.loadDate,104)
--,category = b.category
--,case when b.inn is null then 'Новый ИНН' else 'Есть у нас' end isNew
--from dwh2.finAnalytics.PBR_MONTHLY a
--left join dwh2.finAnalytics.MSP_reestr b on a.INN=b.INN
--where a.isZaemshik in ('ИП','ЮЛ')
--and a.INN is not null
--order by a.isZaemshik,a.INN
  
select
l1.Client
,l1.isZaemshik
,l1.INN
,reestrInDate = convert( date,b.reestrInDate,104)
,reestrOutDate = convert(date,b.reestrOutDate,104)
,loadDate = b.loadDate--convert(date,b.loadDate,104)
,category = b.category
,case when b.inn is null then 'Новый ИНН' else 'Есть у нас' end isNew
from(
select
a.Client
,a.isZaemshik
,a.INN
,rn = row_Number() over (Partition by a.INN order by a.repmonth)
from dwh2.finAnalytics.PBR_MONTHLY a
where a.isZaemshik in ('ИП','ЮЛ')
and a.INN is not null
) l1
left join dwh2.finAnalytics.MSP_reestr b on l1.INN=b.INN

where l1.rn=1

END

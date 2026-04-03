

CREATE proc dbo.inn_check_repr_creation as



drop table if exists ##ipSamoz
/*

select top 1000 inn from  inn_active_20250204 where  (NPDStatus =-2 ) 
--and  (ipStatus  is null or ipjson is null)
and inn is not null group by inn order by  1  



select * from inn_active_20250204
where inn is not null
order by npdstatus

select * from inn_active_20250204
where inn = '161103258276'
order by npdstatus


drop table if exists inn_active_20250204
select *  into inn_active_20250204 from (
select distinct a.[CRMClientGUID] clientId, b.inn
, cAST(null as nvarchar(max)) npdStatus
, cAST(null as nvarchar(max)) ipStatus
, cAST(null as nvarchar(max)) ipJson
, max([Текущая просрочка]) over(partition by [CRMClientGUID] )  dpd
, getdate() created
from mv_loans a 
left join v_client_inn b on a.crmclientguid=b.clientId
where  a.closed is  null 
) x where dpd <= 0 -- and b.инн is null
order by 2, 1*/





drop table if exists #t1, ##ipSamoz; 
WITH ParsedData AS (
    SELECT 
       a.*,
        ip.value AS ipData
    FROM inn_check a
    outer APPLY OPENJSON(TRY_CAST(REPLACE(REPLACE(ipJson, '''', '"'), 'None', 'null') AS NVARCHAR(MAX)), '$.ip') AS ip
)
SELECT
   *,
    JSON_VALUE(ipData, '$.ogrn') AS ogrn,
    JSON_VALUE(ipData, '$.inn') AS ipInn,
    JSON_VALUE(ipData, '$.okved') AS okved,
    JSON_VALUE(ipData, '$.okved_name') AS okvedName,
    JSON_VALUE(ipData, '$.name') AS ipName,
    JSON_VALUE(ipData, '$.status') AS ipCurrentState
	into #t1
FROM ParsedData
order by npdstatus
;
with ip as (

select inn
, count(case when ipInn is not null  then 1 end)  IpCnt 
, count(case when ipInn is not null and ipCurrentState is null then 1 end) activeIpCnt 
, string_agg(okvedName +isnull(' ('+ipCurrentState +')', '') , '
') okveds
from #t1
group by inn
)


select a.inn, a.proccessed,

case when npdstatus=1 then 'Самозанятый' else '' end [САМОЗАНЯТЫЙ?],
case 
when activeIpCnt>0 then 'Активный ИП'
when IpCnt>0 then 'ИП (прекратило действие)'
else '' end [ИП?]
, a.ipStatus
, a.npdStatus
, a.ipJson
, v.activeIpCnt
,  v.IpCnt
, v.okveds [ИП описание]
--,   c.[Основной телефон клиента CRM]  phone
--,gmt.gmt часовойПояс
--,   c.[Фамилия] 
--,   c.[Имя] 
--,   c.[Отчество]
--,   c.[Дата рождения]
--,   re1.age [Возраст на дату заявки]
--,   c.[пол]
--,re.region регион
--,re1.employmentPosition занятость
--,re1.employmentType типЗанятости
--,re.monthlyIncome Доход
----,   c.  phone
--,   c.[Выдано ПТС шт]
--,   c.[Выдано инст шт] [Выдано беззалог шт]
--,re.issued [дата последней выдачи]
--,   c.[Дата внесения в ЧС]

into ##ipSamoz
from inn_check a
left join ip v on a.inn=v.inn
left join v_clients c on  c.GUID=a.clientId
left join _request re on re.clientId=c.GUID and re.issued is not null
left join v_request re1 on re1.guid=re.guid
left join v_gmt gmt on gmt.region=re.region
	 where a.inn is not null --and c.[Дата внесения в ЧС] is null and (IpCnt>0 or npdstatus = 1)
	 
	 ;with v  as (select *, row_number() over(partition by inn order by (select 1) desc) rn from ##ipSamoz ) delete from v where rn>1


	 drop table if exists inn_check_repr
	 select * into inn_check_repr from ##ipSamoz


	 --exec python 'sql_to_gmail(sql="select * from ##ipSamoz ", name="ИП И САМОЗАНЯТЫЕ В ОБЗВОН", add_to = "",  is_csv=False, subject="Analytics.Reporting", include_sql=False)'

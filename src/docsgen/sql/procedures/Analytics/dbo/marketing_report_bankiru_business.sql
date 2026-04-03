CREATE proc dbo.marketing_report_bankiru_business
as


exec _etl_gs 'business'


exec python 'sql_to_gmail("""
select convert(date,  a.[Дата], 104)  Дата
, a.[Номер]
, a.[Источник]
, a.[/ ссылка] 
, a.[Результат]
 from marketing_business_lead a
 where   a.[Источник] = ''bankiru-bz''
 order by 1 desc
""", name = "ЛИДЫ БИЗНЕС ЗАЙМ", add_to="p.ilin@smarthorizon.ru; a.vdovin@carmoney.ru; m.kozlov@banki.ru; reports@banki.ru; lapikova@banki.ru; e.ovchinnikova@banki.ru", subject= "BANKIRU - PSB FINANCE" )', 1


 --sp_create_job 'Analytics._marketing_report_bankiru_business at 10' , 'marketing_report_bankiru_business', '1', '100000'
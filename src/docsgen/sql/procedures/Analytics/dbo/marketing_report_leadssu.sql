CREATE proc [dbo].[marketing_report_leadssu]
as

 

exec python 'sql_to_gmail("""
select a.call1 ДатаПолнойЗаявки,  a.source Источник, a.number НомерЗаявки, a.status_crm СтатусЗаявки, b.statTerm АйдиКлика, a.productType Продукт from request a
left join v_request_lf2 b on a.number=b.number
where a.source = ''leadssu-big-installment'' and a.producttype = ''big inst'' and a.call1 is not null
order by 1 desc 


""", name = "ЛИДЫ leadssu-big-installment", add_to="p.ilin@smarthorizon.ru; a.vdovin@carmoney.ru; riskina@leads.su; agurova@leads.su", subject= "LEADSSU - PSB FINANCE" )', 1


 --sp_create_job 'Analytics._marketing_report_leadssu at 10' , 'marketing_report_leadssu', '1', '100000'


 
  
create   proc  marketing_report_marketplace

as



exec _etl_gs 'marketplace'


exec python 'sql2gs("""select b.Маркетплейсы, b.Группа, a.issuedMonth, cast( sum(issuedSum) as bigint)   issuedSum from request a
join marketing_source_marketplace b on a.source=b.Маркетплейсы 
where issuedSum>0
group by b.Маркетплейсы, b.Группа, a.issuedMonth""", "1jxSOx5gN2-q0oCk_hfrSKsS03c1xqZqiPcSH7_Hi7Es", sheet_name = "dwh")', 1


-- sp_create_job 'Analytics._marketing_report_marketplace at 9', 'marketing_report_marketplace', '1', '90000'

create   proc sale_report_employment as

exec python 'sql2gs("""

select number, employmentPosition, employmentPlace, employmentType, status_crm2 from request
where issued>=''20250701'' order by issued desc""", "10i49HVK0pv9T5p3X80sVCbidejYUZNF-zVjOTR3VN18", sheet_name = "Данные")', 1



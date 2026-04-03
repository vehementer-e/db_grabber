
create proc dbo.marketing_request_gs as
exec python 'sql2gs("""
select number		, RBP	, returnType		, SOURCE, created , call1 , issued , issuedSum	, 	phone	, fioBirthday, productType
from request
where call1>=''20250301'' and ispts=1 --and istest=1
order by call1 desc
 

""", "1hnXA8B1KCTye3c50C1gpaZodnwu4ecPZ5DSRmlkK-pY", sheet_name= "заявки ПТС")', 1

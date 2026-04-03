
CREATE proc sale_report_partner_autocredit
as


exec python 'sql2gs("""select number,	issued, isnull( cast(	dpdbeginday as varchar), '''') dpdbeginday ,	cast(issuedSum as int)  issuedSum, isnull(format(	closed , ''yyyy-MM-dd''), '''') closed 
,	carBrand,	carModel,	carYear,	age
from request where producttype=''autocredit'' and issued is not null
order by 2""", "1xPylVeN-98IDtnF355W2hnCugzYm95B1nia2QHFX25U",  sheet_name = "data"  )', 1


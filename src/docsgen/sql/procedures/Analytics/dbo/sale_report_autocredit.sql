CREATE   proc [dbo].[sale_report_autocredit] as 
 



select number
, status_crm2
, b.date
, b.week
, b.month

, created
, call1
, call1approved
, checking
, case when call2 is not null or declined is not null then checking end checkingNotStacked
, call2
, call2Approved
, clientVerification
, case when carVerificarion is not null or declined is not null then clientVerification end clientVerificationNotStacked
, carVerificarion
, case when approved is not null or declined is not null then carVerificarion end carVerificarionVerificationNotStacked

, approved
, contractSigned
, issued

, case 
 		when	issued																													   is not null then 14
 	    when 	contractSigned																											   is not null then 13
 		when	approved																												   is not null then 12
 		when	case when approved is not null or declined is not null then carVerificarion end  	                                       is not null then 11
 		when	carVerificarion																											   is not null then 10
 		when	case when carVerificarion is not null or declined is not null then clientVerification end  	                               is not null then 9
 		when	clientVerification																										   is not null then 8
 		when	call2Approved																											   is not null then 7
 		when	call2																													   is not null then 6
 		when	case when call2 is not null or declined is not null then checking end  								                       is not null then 5
 		when	checking																												   is not null then 4
  		when	call1approved																											   is not null then 3
		when	call1																													   is not null then 2
        when    created                                                                                                                    is not null then 1
 end statusNumber
 
 

, issuedSum
, a.source
from request a
left join calendar_view b on cast( isnull(a.call1, a.created) as date) = b.date
where producttype='autocredit'  --and declined is null and approved is null
and created>='20250501'
and isdubl=0
order by 2 desc, 1